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


if __name__ == "__main__":
    unittest.main()
