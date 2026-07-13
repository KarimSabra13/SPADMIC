#!/usr/bin/env python3

from __future__ import annotations

import os
import re
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
DRIVER = REPO / "TOP" / "ci" / "server_run_tx_packet_canonical_phase1.sh"


class TxPacketCanonicalPhase1DriverTest(unittest.TestCase):
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
            "xcelium-focus",
            "xcelium-full",
            "xcelium-report",
            "genus",
            "genus-report",
            "package",
            "status",
        ):
            self.assertIn(f"  {subcommand})", text)

    def test_driver_keeps_innovus_and_pvs_out_of_phase1(self) -> None:
        text = DRIVER.read_text()
        self.assertNotIn("run_innovus", text)
        self.assertNotIn("run_pvs", text)
        self.assertIn("PHYSICAL_GATES=INNOVUS_AND_PVS_NOT_RUN_IN_THIS_PHASE", text)
        self.assertIn("CLOSURE_STATUS=REVIEW_REQUIRED_NOT_INFERRED_FROM_TOOL_RC", text)

    def test_report_filters_distinguish_real_failures_from_test_vocabulary(self) -> None:
        text = DRIVER.read_text()
        self.assertIn("05_xcelium_failure_markers.rpt", text)
        self.assertIn("'^(FAIL|MISSING)[[:space:]]'", text)
        self.assertIn("UVM_(ERROR|FATAL)", text)
        self.assertNotIn("'FAIL|MISSING|ERROR|FATAL|\\*E,'", text)
        self.assertIn("===== COMPLETE CLOCK REPORT =====", text)
        self.assertIn("===== TIMING INTENT CATEGORIES =====", text)
        self.assertIn("===== COMPLETE QOR REPORT =====", text)
        self.assertIn("===== COMPLETE WARNING CLASSIFICATION =====", text)
        self.assertIn("validate_tx_packet_genus_ooc.py", text)
        self.assertIn("GENUS_REVIEW_AND_FEASIBILITY_GATE_COMPLETE", text)
        self.assertIn("--exclude='reports/08_package_details.rpt'", text)

    def test_init_creates_auditable_session_without_server_tools(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            work_root = root / "work"
            active_env = root / "active.env"
            env = os.environ.copy()
            env.update(
                {
                    "SPADMIC_WORK_ROOT": str(work_root),
                    "SPADMIC_TX_PACKET_ACTIVE_ENV": str(active_env),
                    "SPADMIC_TX_REPO": str(REPO),
                }
            )
            result = subprocess.run(
                ["bash", str(DRIVER), "init", "deadbeef"],
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
            self.assertIn("TX_EXPECTED_HEAD=deadbeef", active_text)

            sessions = list((work_root / "diagnostics").glob("tx_packet_canonical_phase1_*"))
            self.assertEqual(len(sessions), 1)
            session = sessions[0]
            objective = (session / "00_objective_and_policy.rpt").read_text()
            self.assertIn("CURRENT_SCOPE=P03_SERVER_GATE_1_RTL_AND_GENUS", objective)
            self.assertIn("FINAL_HANDOFF_READY=NO", objective)
            status = (session / "status" / "00_init.rpt").read_text()
            self.assertIn("STATUS=PASS", status)
            self.assertIn("RESULT=SESSION_INITIALIZED", status)

    def test_xcelium_report_ignores_pass_vocabulary_but_keeps_tool_errors(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            work_root = root / "work"
            session = work_root / "diagnostics" / "session"
            run_id = "xcelium_test"
            run_root = work_root / "xcelium" / run_id
            (session / "logs").mkdir(parents=True)
            (session / "reports").mkdir()
            (session / "status").mkdir()
            (session / "packages").mkdir()
            (run_root / "logs").mkdir(parents=True)
            (run_root / "test_summary.txt").write_text("PASS tb_example\nPASS=1\nFAIL=0\nMISSING=0\n")
            tail = run_root / "logs" / "tb_example.tail"
            tail.write_text(
                "errors: 0, warnings: 2\n"
                "[PASS] unsupported request reports error\n"
                "tb_example: 10 pass / 0 fail\n"
            )

            active_env = root / "active.env"
            active_env.write_text(
                f"export TX_REPO={REPO}\n"
                f"export TX_WORK_ROOT={work_root}\n"
                "export TX_EXPECTED_HEAD=deadbeef\n"
                "export TX_SESSION_ID=session\n"
                f"export TX_SESSION_ROOT={session}\n"
                f"export TX_XCELIUM_RUN={run_id}\n"
                "export TX_GENUS_RUN=genus_test\n"
            )
            env = os.environ.copy()
            env.update(
                {
                    "SPADMIC_WORK_ROOT": str(work_root),
                    "SPADMIC_TX_PACKET_ACTIVE_ENV": str(active_env),
                }
            )

            first = subprocess.run(
                ["bash", str(DRIVER), "xcelium-report"],
                cwd=REPO,
                env=env,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(first.returncode, 0, first.stdout)
            self.assertIn("FAILURE_MARKER_COUNT=0", first.stdout)
            self.assertIn("===== FAILURE MARKERS =====\nNONE", first.stdout)

            tail.write_text(tail.read_text() + "xmelab: *E,CUVMUR: unresolved module\n")
            second = subprocess.run(
                ["bash", str(DRIVER), "xcelium-report"],
                cwd=REPO,
                env=env,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(second.returncode, 0, second.stdout)
            self.assertIn("FAILURE_MARKER_COUNT=1", second.stdout)
            self.assertIn("*E,CUVMUR", second.stdout)


if __name__ == "__main__":
    unittest.main()
