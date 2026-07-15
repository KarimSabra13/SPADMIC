#!/usr/bin/env python3

from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
TRIAL = (
    REPO
    / "TOP"
    / "pnr"
    / "scripts"
    / "run_innovus_ooc_min_area_second_pass_trial.tcl"
)
NETS = ("n_9677", "n_9693", "n_9696", "n_9697", "n_9706", "n_9721")


class TxPacketMinAreaSecondPassTclTest(unittest.TestCase):
    def test_two_iteration_zero_drc_path_writes_complete_status(self) -> None:
        tclsh = shutil.which("tclsh")
        if not tclsh:
            self.skipTest("tclsh is unavailable")

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            trial_root = root / "trial"
            checkpoint = root / "checkpoint.enc"
            analysis = root / "step17.rpt"
            harness = root / "harness.tcl"
            checkpoint.write_text("fixture\n")
            analysis.write_text(
                "STATUS=PASS\n"
                "RESULT=BLOCKERS_CLASSIFIED\n"
                "PHYSICAL_CANDIDATE_STATUS=PG_AND_REGULAR_CLOSED_FINAL_REPAIR_REQUIRED\n"
                "FINAL_DRC_STATUS=FAIL\n"
                "REGULAR_CONNECTIVITY_STATUS=PASS\n"
                "PG_CONNECTIVITY_STATUS=PASS\n"
                "PG_PROBLEM_COUNT=0\n"
                "MIN_AREA_REPAIR_EFFECT=REDUCED_10_TO_6\n"
                "MIN_AREA_PRE_MARKER_COUNT=10\n"
                "MIN_AREA_POST_MARKER_COUNT=6\n"
                "MIN_AREA_FINAL_MARKER_COUNT=6\n"
                f"MIN_AREA_FINAL_NETS={' '.join(NETS)}\n"
                "ANTENNA_FINAL_MARKER_COUNT=177\n"
                "STREAM_PIN_TARGET_STATUS=CANONICAL_TARGETS_PRESERVED\n"
                "STREAM_PIN_COMMAND_MAPPING_DECISION="
                "REMOVE_NEGATIVE_COMPENSATION_KEEP_CANONICAL_CENTERS\n"
                "PVS_DECISION=DO_NOT_RUN\n"
            )
            harness.write_text(
                "set ::marker_count 6\n"
                "set ::repair_iteration 0\n"
                f"set ::fixture_nets {{{' '.join(NETS)}}}\n"
                "proc restoreDesign {checkpoint top} { return }\n"
                "proc redirect {args} {\n"
                "    set path [lindex $args 1]\n"
                "    set body [lindex $args 2]\n"
                "    set ::capture_fh [open $path w]\n"
                "    set rc [catch {uplevel 1 $body} err options]\n"
                "    close $::capture_fh\n"
                "    unset ::capture_fh\n"
                "    if {$rc} { return -options $options $err }\n"
                "}\n"
                "proc verify_drc {} {\n"
                "    puts $::capture_fh \"Verification Complete : $::marker_count Viols.\"\n"
                "}\n"
                "proc verifyConnectivity {args} {\n"
                "    puts $::capture_fh {Verification Complete : 0 Viols.  0 Wrngs.}\n"
                "}\n"
                "proc dbGet {query} {\n"
                "    if {$query eq {top.markers}} {\n"
                "        set markers [list]\n"
                "        for {set idx 1} {$idx <= 177} {incr idx} { lappend markers a$idx }\n"
                "        for {set idx 1} {$idx <= $::marker_count} {incr idx} { lappend markers m$idx }\n"
                "        return $markers\n"
                "    }\n"
                "    if {[regexp {^a[0-9]+[.](.+)$} $query -> field]} {\n"
                "        switch -- $field {\n"
                "            box { return {0.0 0.0 0.1 0.1} }\n"
                "            layer.name { return MET1 }\n"
                "            type { return Antenna }\n"
                "            subType { return ProcessAntenna }\n"
                "            message { return {Antenna fixture marker} }\n"
                "        }\n"
                "    }\n"
                "    if {[regexp {^m([0-9]+)[.](.+)$} $query -> number field]} {\n"
                "        set net [lindex $::fixture_nets [expr {$number - 1}]]\n"
                "        set llx [expr {100.0 + $number}]\n"
                "        set lly [expr {200.0 + $number}]\n"
                "        switch -- $field {\n"
                "            box { return [list $llx $lly [expr {$llx + 0.38}] [expr {$lly + 0.28}]] }\n"
                "            layer.name { return MET1 }\n"
                "            type { return Geometry }\n"
                "            subType { return Minimal_Area }\n"
                "            message { return \"Regular Wire of Net $net Actual: 0.10640000 Required: 0.20200000 Type: Minimum Area\" }\n"
                "        }\n"
                "    }\n"
                "    error \"unsupported dbGet query: $query\"\n"
                "}\n"
                "proc setNanoRouteMode {args} { return }\n"
                "proc deselectAll {} { return }\n"
                "proc selectNet {net} { return }\n"
                "proc editDelete {args} { return }\n"
                "proc globalDetailRoute {args} { return }\n"
                "proc detailRoute {args} { return }\n"
                "proc ecoRoute {args} {\n"
                "    incr ::repair_iteration\n"
                "    if {$::repair_iteration == 1} { set ::marker_count 3 } else { set ::marker_count 0 }\n"
                "}\n"
                f"source {{{TRIAL}}}\n"
            )
            env = os.environ.copy()
            env.update(
                {
                    "SPADMIC_MIN_AREA_TRIAL_CHECKPOINT": str(checkpoint),
                    "SPADMIC_MIN_AREA_TRIAL_ROOT": str(trial_root),
                    "SPADMIC_MIN_AREA_TRIAL_TOP": "spadmic_tx_packet_core",
                    "SPADMIC_MIN_AREA_TRIAL_ANALYSIS": str(analysis),
                    "SPADMIC_MIN_AREA_TRIAL_ITERATION_LIMIT": "3",
                }
            )
            result = subprocess.run(
                [tclsh, str(harness)],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                env=env,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stdout)
            status = (
                trial_root / "reports" / "min_area_second_pass_trial_status.rpt"
            ).read_text()
            commands = (
                trial_root / "reports" / "min_area_second_pass_trial_commands.rpt"
            ).read_text()
            self.assertIn("STATUS=PASS", status)
            self.assertIn("RESULT=ITERATIVE_MIN_AREA_REPAIR_VALIDATED", status)
            self.assertIn("ITERATION_COUNT=2", status)
            self.assertIn("DRC_COUNT_SEQUENCE=6 3 0", status)
            self.assertIn("FINAL_DRC_VIOLATION_COUNT=0", status)
            self.assertIn("FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT=0", status)
            self.assertIn("FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=0", status)
            self.assertIn("FINAL_EXCLUDED_ANTENNA_MARKER_COUNT=177", status)
            self.assertIn("COMMAND_FAIL_COUNT=0", commands)


if __name__ == "__main__":
    unittest.main()
