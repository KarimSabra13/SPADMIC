#!/usr/bin/env python3

from __future__ import annotations

import os
import re
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
DRIVER = REPO / "TOP" / "ci" / "server_run_tx_packet_canonical_phase2.sh"


class TxPacketCanonicalPhase2DriverTest(unittest.TestCase):
    def test_driver_is_staged_and_interactive_shell_safe(self) -> None:
        text = DRIVER.read_text()
        self.assertIn("set +e", text)
        self.assertNotRegex(text, re.compile(r"^\s*set\s+-e", re.MULTILINE))
        self.assertNotRegex(text, re.compile(r"^\s*exit(?:\s|$)", re.MULTILINE))
        self.assertIn("ONE_OPERATOR_COMMAND_PER_GATE_NO_AUTO_ADVANCE", text)
        for subcommand in (
            "init",
            "sync",
            "preflight",
            "innovus",
            "innovus-report",
            "diagnose",
            "pg-probe",
            "pg-analyze",
            "pg-help",
            "pg-via-trial",
            "package",
            "status",
        ):
            self.assertIn(f"  {subcommand})", text)

    def test_driver_runs_only_packet_innovus_with_explicit_policies(self) -> None:
        text = DRIVER.read_text()
        self.assertIn("run_innovus_ooc_harden_block.sh", text)
        self.assertIn("SPADMIC_OOC_ROUTE_PROFILE=met1_effort", text)
        self.assertIn("SPADMIC_OOC_SIGNAL_TOP_LAYER=MET3", text)
        self.assertIn("SPADMIC_OOC_ENABLE_PG_SROUTE=1", text)
        self.assertIn("SPADMIC_OOC_CORE_WIDTH_UM=2046.969", text)
        self.assertIn("SPADMIC_OOC_CORE_HEIGHT_UM=346.486", text)
        self.assertIn("SPADMIC_OOC_PLACE_MAX_DENSITY=0.64", text)
        self.assertIn("SPADMIC_OOC_SIGNAL_BOTTOM_LAYER_IDX=1", text)
        self.assertIn("SPADMIC_OOC_SIGNAL_TOP_LAYER_IDX=3", text)
        self.assertIn("SPADMIC_OOC_ENABLE_MIN_AREA_REPAIR=1", text)
        self.assertIn("SPADMIC_OOC_ENABLE_ANTENNA_REPAIR=0", text)
        self.assertIn("SPADMIC_OOC_FILLER_ADD_FILLERS_WITH_DRC=0", text)
        self.assertIn("SPADMIC_OOC_REQUIRE_DRC_SAFE_FILLER=1", text)
        self.assertIn("SPADMIC_TX_ALLOW_ANTENNA_DEFERRED=1", text)
        self.assertIn("variable core_width_um {2046.969}", text)
        self.assertIn("variable core_height_um {346.486}", text)
        self.assertIn("DEFER_MANUAL_REPAIR_FINAL_HANDOFF_BLOCKED", text)
        self.assertNotIn("run_pvs", text)
        self.assertIn("PVS_POLICY=NOT_RUN_IN_THIS_PHASE", text)

    def test_driver_requires_measured_timing_and_canonical_gate_results(self) -> None:
        text = DRIVER.read_text()
        self.assertIn("SETUP_WNS_NS", text)
        self.assertIn("SETUP_VIOLATING_PATH_COUNT", text)
        self.assertIn("HOLD_WNS_NS", text)
        self.assertIn("HOLD_VIOLATING_PATH_COUNT", text)
        self.assertIn("POST_REPAIR_TIMING_REQUIRED", text)
        self.assertIn("ANTENNA_MILESTONE_ACCEPTED", text)
        self.assertIn("READY_FOR_PVS_CANDIDATE", text)
        self.assertIn("--exclude='reports/06_package_details.rpt'", text)
        self.assertIn("READ_ONLY_EXISTING_ARTIFACTS_NO_DESIGN_MODIFICATION", (
            REPO / "TOP" / "pnr" / "scripts" / "analyze_tx_packet_ooc_failure.py"
        ).read_text())
        self.assertIn("DESIGN_MODIFICATION", text)
        self.assertIn('kv_field "$report" DIAGNOSIS_STATUS', text)

    def test_pg_probe_is_fresh_process_restore_only_and_supports_packet_checkpoint(self) -> None:
        wrapper = (
            REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_pg_probe.sh"
        ).read_text()
        probe = (
            REPO / "TOP" / "pnr" / "scripts" / "probe_innovus_ooc_pg_connectivity.tcl"
        ).read_text()
        self.assertIn("05_postroute_export.enc.dat", wrapper)
        self.assertIn('SPADMIC_PG_PROBE_TOP="$top"', wrapper)
        self.assertIn("POLICY=READ_ONLY_RESTORE_AND_REPORT", wrapper)
        self.assertIn("restoreDesign $checkpoint $top", probe)
        self.assertIn("DESIGN_MODIFICATION NOT_RUN", probe)
        self.assertNotIn("add_shape", probe)
        self.assertNotIn("sroute", probe)

    def test_pg_repair_isolated_trial_is_fail_closed(self) -> None:
        driver = DRIVER.read_text()
        wrapper = (
            REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_pg_via_trial.sh"
        ).read_text()
        trial = (
            REPO / "TOP" / "pnr" / "scripts" / "run_innovus_ooc_pg_via_trial.tcl"
        ).read_text()
        command_help = (
            REPO / "TOP" / "pnr" / "scripts" / "capture_innovus_pg_command_help.tcl"
        ).read_text()
        self.assertIn("require_step_pass 05_pg_probe", driver)
        self.assertIn("require_step_pass 06_pg_analyze", driver)
        self.assertIn("require_step_pass 07_pg_help", driver)
        self.assertIn("SOURCE_ARTIFACT_HEAD=$TX2_EXPECTED_HEAD", driver)
        self.assertIn("REPORT_DRIVER_HEAD=", driver)
        self.assertIn("READY_FOR_ONE_ISOLATED_TRIAL", driver)
        self.assertIn("editPowerVia", command_help)
        self.assertIn("setViaGenMode", command_help)
        self.assertIn('grep -Fq "setViaGenMode -area_only 1"', driver)
        self.assertIn('grep -Fq -- "-exclude_stack_vias"', driver)
        self.assertIn("ONE_FRESH_PROCESS_ONE_RESTORE_IN_MEMORY_TRIAL", wrapper)
        self.assertIn("restoreDesign $checkpoint $top", trial)
        self.assertIn("editPowerVia -add_vias 1", trial)
        self.assertIn("setViaGenMode -area_only 1", trial)
        self.assertIn("-bottom_layer MET1 -top_layer METTP -exclude_stack_vias 0", trial)
        self.assertIn("Problem\\(s\\)", trial)
        self.assertIn("return CONFLICT", trial)
        self.assertIn("string is integer -strict $post_special_count", trial)
        self.assertIn("POST_SPECIAL_CONNECTIVITY_VIOLATION_COUNT", trial)
        self.assertIn("POST_REGULAR_CONNECTIVITY_VIOLATION_COUNT", trial)
        self.assertIn("POST_DRC_VIOLATION_COUNT", trial)
        for forbidden in ("saveDesign", "defOut", "streamOut", "saveNetlist"):
            self.assertNotIn(forbidden, trial)

    def test_init_inherits_an_accepted_phase1_gate(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            work_root = root / "work"
            phase1 = work_root / "diagnostics" / "phase1"
            genus_block = work_root / "genus" / "genus_unit" / "tx_packet_core"
            (phase1 / "reports").mkdir(parents=True)
            genus_block.mkdir(parents=True)
            (phase1 / "reports" / "07_genus_gate.rpt").write_text(
                "STATUS=PASS\n"
                "RESULT=READY_FOR_PACKET_INNOVUS_FEASIBILITY\n"
                f"BLOCK_ROOT={genus_block}\n"
                "ERROR_COUNT=0\n"
                "INNOVUS_FEASIBILITY_READY=YES\n"
                "SIGNOFF_READY=NO\n"
                "MMMC_STATUS=NOT_RUN_TYPICAL_ONLY\n"
            )
            active_env = root / "phase2_active.env"
            env = os.environ.copy()
            env.update(
                {
                    "SPADMIC_WORK_ROOT": str(work_root),
                    "SPADMIC_TX_PACKET_PHASE2_ACTIVE_ENV": str(active_env),
                    "SPADMIC_TX_REPO": str(REPO),
                }
            )
            result = subprocess.run(
                ["bash", str(DRIVER), "init", "deadbeef", str(phase1)],
                cwd=REPO,
                env=env,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout)
            self.assertTrue(active_env.is_file())
            active_text = active_env.read_text()
            self.assertIn("TX2_EXPECTED_HEAD=deadbeef", active_text)
            self.assertIn("TX2_GENUS_RUN=genus_unit", active_text)
            self.assertIn(f"TX2_PHASE1_ROOT={phase1}", active_text)

            sessions = list((work_root / "diagnostics").glob("tx_packet_canonical_phase2_*"))
            self.assertEqual(len(sessions), 1)
            session = sessions[0]
            objective = (session / "00_objective_and_policy.rpt").read_text()
            self.assertIn("PG_POLICY=EXPLICIT_EXACT_METTP_STRIPES_COREPIN_SROUTE", objective)
            self.assertIn("PVS_POLICY=NOT_RUN_IN_THIS_PHASE", objective)
            status = (session / "status" / "00_init.rpt").read_text()
            self.assertIn("STATUS=PASS", status)
            self.assertIn("RESULT=SESSION_INITIALIZED", status)


if __name__ == "__main__":
    unittest.main()
