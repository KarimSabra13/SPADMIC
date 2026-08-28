#!/usr/bin/env python3
"""Unit tests for the one-command free-trial PVS ECO contract."""

from __future__ import annotations

import hashlib
import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "validate_mptdc_free_pvs_eco_commands.py"


class EcoCommandValidatorTest(unittest.TestCase):
    def run_case(self, text: str) -> tuple[subprocess.CompletedProcess[str], str, str]:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            source = root / "commands.tcl"
            normalized = root / "normalized.tcl"
            report = root / "report.rpt"
            source.write_text(text)
            digest = hashlib.sha256(source.read_bytes()).hexdigest()
            result = subprocess.run(
                [
                    "python3",
                    str(SCRIPT),
                    "--commands-file",
                    str(source),
                    "--expected-sha256",
                    digest,
                    "--normalized-out",
                    str(normalized),
                    "--report",
                    str(report),
                ],
                check=False,
                capture_output=True,
                text=True,
            )
            normalized_text = normalized.read_text() if normalized.exists() else ""
            report_text = report.read_text() if report.exists() else ""
            return result, normalized_text, report_text

    def test_exact_selected_net_command_passes(self) -> None:
        command = "mptdc_ckpt_route_selected_nets {u_core/net_1 bus[3]}\n"
        result, normalized, report = self.run_case(command)
        self.assertEqual(result.returncode, 0)
        self.assertEqual(normalized, command)
        self.assertIn("COMMAND_CONTRACT_STATUS=PASS", report)
        self.assertIn("TARGET_NET_COUNT=2", report)

    def test_arbitrary_tcl_is_rejected(self) -> None:
        result, normalized, report = self.run_case("deleteFiller\n")
        self.assertEqual(result.returncode, 1)
        self.assertEqual(normalized, "")
        self.assertIn("COMMAND_CONTRACT_STATUS=FAIL", report)

    def test_multiple_route_commands_are_rejected(self) -> None:
        text = (
            "mptdc_ckpt_route_selected_nets {net_a}\n"
            "mptdc_ckpt_route_selected_nets_detail_only {net_b}\n"
        )
        result, normalized, report = self.run_case(text)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(normalized, "")
        self.assertIn("expected exactly one routing helper command", report)

    def test_hash_mismatch_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            source = root / "commands.tcl"
            source.write_text("mptdc_ckpt_route_selected_nets {net_a}\n")
            result = subprocess.run(
                [
                    "python3",
                    str(SCRIPT),
                    "--commands-file",
                    str(source),
                    "--expected-sha256",
                    "0" * 64,
                    "--normalized-out",
                    str(root / "normalized.tcl"),
                    "--report",
                    str(root / "report.rpt"),
                ],
                check=False,
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 1)
            self.assertIn("command hash mismatch", (root / "report.rpt").read_text())


if __name__ == "__main__":
    unittest.main()
