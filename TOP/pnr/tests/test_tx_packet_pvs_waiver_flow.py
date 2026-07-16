#!/usr/bin/env python3

from __future__ import annotations

import re
import subprocess
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
DRIVER = REPO / "TOP" / "ci" / "server_run_tx_packet_pvs_waiver.sh"
WRAPPER = REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_min_area_waiver_export.sh"
TCL = REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_min_area_waiver_export.tcl"
DOC = (
    REPO
    / "TOP"
    / "docs"
    / "38_TX_PACKET_CORE_PROVISIONAL_DRC_WAIVER_AND_PVS_LVS_EXECUTION.md"
)


class TxPacketPvsWaiverFlowTest(unittest.TestCase):
    def test_driver_is_interactive_safe_and_one_gate_at_a_time(self) -> None:
        text = DRIVER.read_text()
        self.assertIn("set +e", text)
        self.assertNotRegex(text, re.compile(r"^\s*set\s+-e", re.MULTILINE))
        self.assertNotRegex(text, re.compile(r"^\s*exit(?:\s|$)", re.MULTILINE))
        self.assertIn("ONE_OPERATOR_COMMAND_PER_GATE_NO_AUTO_ADVANCE", text)
        for subcommand in (
            "init",
            "waiver-export",
            "stage",
            "pvs-drc-base",
            "pvs-lvs",
            "summary",
            "status",
        ):
            self.assertIn(f"  {subcommand})", text)
        result = subprocess.run(
            ["bash", str(DRIVER), "status"],
            env={
                "PATH": "/usr/bin:/bin",
                "SPADMIC_TX_PACKET_PVS_WAIVER_ACTIVE_ENV": (
                    "/tmp/spadmic_missing_pvs_waiver_active.env"
                ),
            },
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("provisional PVS active session is missing", result.stdout)

    def test_lvs_is_independent_of_pvs_drc_but_requires_staging(self) -> None:
        text = DRIVER.read_text()
        start = text.index("pvs_lvs()")
        end = text.index("summary_report()", start)
        lvs = text[start:end]
        self.assertIn("require_step_pass 02_stage_handoff", lvs)
        self.assertNotIn("require_step_pass 03_pvs_drc_base", lvs)
        self.assertIn("PVS_DRC_PREREQUISITE=NOT_REQUIRED", lvs)
        self.assertIn("LVS_ACCEPTANCE=EXPLICIT_REPORT_LEVEL_MATCH_ONLY", lvs)
        self.assertIn('raw_status" == "MATCH"', lvs)

    def test_pvs_drc_is_never_converted_to_pass_by_the_waiver(self) -> None:
        text = DRIVER.read_text()
        self.assertIn("PVS_DRC_WAIVER=NO", text)
        self.assertNotIn("PVS_DRC_WAIVER=YES", text)
        self.assertIn("PVS_BASE_DRC_NONZERO_RECORDED_LVS_STILL_AUTHORIZED", text)
        self.assertIn('raw_evidence" == *"Total DRC Results="*', text)
        self.assertIn("FINAL_SIGNOFF_READY=NO", text)
        self.assertIn("BLOCK_PROMOTION_AUTHORIZED=NO", text)

    def test_export_replays_only_the_validated_six_base_edits(self) -> None:
        text = TCL.read_text()
        self.assertEqual(text.count("restoreDesign $checkpoint $top"), 1)
        for command in (
            "719.88 158.76 719.32",
            "210.28 201.88 209.72",
            "663.32 192.92 662.76",
            "1666.28 201.88 1666.84",
            "1792.84 212.52 1792.28",
            "1827.00 212.52 1827.56",
        ):
            self.assertIn(command, text)
        self.assertIn("PATCH_ATTEMPTED_COUNT", text)
        self.assertIn("$patch_attempted_count != 6", text)
        self.assertIn("$command_pass_count != 24", text)
        self.assertNotIn('set label "CHAIN_', text)
        self.assertNotIn('set label "VIA_SIDE_', text)

    def test_export_requires_exact_four_marker_identity_before_streamout(self) -> None:
        text = TCL.read_text()
        for marker in (
            "n_9696 {719.38 158.68 720.07 158.91}",
            "n_9693 {209.78 201.73 210.47 201.96}",
            "n_9697 {662.82 192.77 663.51 193.00}",
            "n_9677 {1666.09 201.73 1666.78 201.96}",
        ):
            self.assertIn(marker, text)
        self.assertIn("EXACT_FOUR_MARKER_WAIVER_STATE_NOT_REPRODUCED", text)
        self.assertIn("WAIVER_MARKER_COUNT=4", text)
        self.assertIn("PVS_DRC_WAIVER=NO", text)
        self.assertIn("saveDesign $checkpoint_out", text)
        self.assertIn("saveNetlist -includePowerGround", text)
        self.assertIn("streamOut", text)
        self.assertIn("-mapFile $stream_map -merge [list $stdcell_gds]", text)

    def test_marker_area_parser_does_not_execute_regex_character_classes(self) -> None:
        text = TCL.read_text()
        prefix = text.split("set command_pass_count 0", 1)[0]
        probe = (
            prefix
            + "\n"
            + "set rows [list [list n_9696 marker "
            + "{719.69 158.62 720.07 158.90} "
            + "{Regular Wire of Net n_9696 Actual: 0.10640000 "
            + "Required: 0.20200000}]]\n"
            + "set boxes [list [list n_9696 "
            + "{719.69 158.62 720.07 158.90}]]\n"
            + "puts \"VALID=[mw_validate_rows $rows $boxes 0.10640000]\"\n"
        )
        result = subprocess.run(
            ["tclsh"],
            input=probe,
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("VALID=1", result.stdout)
        self.assertNotIn('\"Actual:[[:space:]]', text)

    def test_wrapper_requires_mapped_merged_gds_audit(self) -> None:
        text = WRAPPER.read_text()
        self.assertIn("audit_innovus_gds_export.py", text)
        self.assertIn("--required-merge", text)
        self.assertIn("READY_FOR_PROVISIONAL_PVS_DRC_LVS", text)
        self.assertIn("LVS_DIAGNOSTIC_ONLY=YES", text)
        self.assertIn("FINAL_SIGNOFF_READY=NO", text)
        result = subprocess.run(
            ["bash", "-n", str(WRAPPER)],
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_documentation_preserves_the_debt_and_retirement_contract(self) -> None:
        text = DOC.read_text()
        for net in ("n_9677", "n_9693", "n_9696", "n_9697"):
            self.assertIn(net, text)
        self.assertIn("PVS_DRC_WAIVER=NO", text)
        self.assertIn("FINAL_SIGNOFF_READY=NO", text)
        self.assertIn("LVS_ACCEPTANCE=EXPLICIT_REPORT_LEVEL_MATCH_ONLY", text)
        self.assertIn("PVS_LVS_STATUS=MATCH", text)
        self.assertIn(
            "STEP28_NORMALIZED_VIA_SIDE_TRIAL="
            "SKIPPED_BY_OPERATOR_TEMPORARY_WAIVER_DECISION",
            text,
        )
        self.assertIn("Rerun PVS LVS against the repaired package", text)
        self.assertIn("Do not blanket-waive all MET1 minimum-area results", text)


if __name__ == "__main__":
    unittest.main()
