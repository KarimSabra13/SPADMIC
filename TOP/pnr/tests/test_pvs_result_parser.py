#!/usr/bin/env python3

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
PARSER = REPO / "TOP" / "pnr" / "scripts" / "parse_pvs_handoff_result.py"


class PvsResultParserTest(unittest.TestCase):
    def run_parser(
        self,
        mode: str,
        content: str,
        tool_rc: int = 0,
        extra_files: dict[str, str] | None = None,
    ):
        temporary = tempfile.TemporaryDirectory()
        root = Path(temporary.name)
        (root / "result.txt").write_text(content)
        for name, value in (extra_files or {}).items():
            (root / name).write_text(value)
        status = root / "status.rpt"
        result = subprocess.run(
            ["python3", str(PARSER), "--mode", mode, "--run-dir", str(root), "--status", str(status), "--tool-rc", str(tool_rc)],
            text=True,
            capture_output=True,
        )
        text = status.read_text()
        temporary.cleanup()
        return result.returncode, text

    def test_zero_drc_is_pass(self) -> None:
        rc, status = self.run_parser("drc", "Total DRC Results : 0 (0)\n")
        self.assertEqual(rc, 0)
        self.assertIn("PVS_DRC_STATUS=PASS", status)
        self.assertIn("DRC_TOTAL_PRIMARY=0", status)

    def test_nonzero_pvs_summary_is_explicit_drc_failure(self) -> None:
        rc, status = self.run_parser(
            "drc",
            "*** PVS HDRC SUMMARY\nTotal DRC Results : 4 (4)\n",
        )
        self.assertEqual(rc, 8)
        self.assertIn("PVS_DRC_STATUS=FAIL", status)
        self.assertIn("Total DRC Results=4(4)", status)
        self.assertIn("DRC_TOTAL_MATCH_COUNT=1", status)

    def test_missing_drc_summary_is_diagnostic_unknown(self) -> None:
        rc, status = self.run_parser("drc", "PVS completed normally\n")
        self.assertEqual(rc, 8)
        self.assertIn("PVS_DRC_STATUS=UNKNOWN", status)
        self.assertIn("NO_REPORT_LEVEL_DRC_TOTAL_IN_RUN_DIR", status)
        self.assertIn("RESULT_EVIDENCE_INVENTORY=", status)

    def test_conflicting_drc_summaries_are_not_accepted(self) -> None:
        rc, status = self.run_parser(
            "drc",
            "Total DRC Results : 0 (0)\n",
            extra_files={"other.sum": "Total DRC Results : 4 (4)\n"},
        )
        self.assertEqual(rc, 8)
        self.assertIn("PVS_DRC_STATUS=UNKNOWN", status)
        self.assertIn("CONFLICTING_REPORT_LEVEL_DRC_TOTALS_IN_RUN_DIR", status)

    def test_lvs_return_code_alone_is_unknown(self) -> None:
        rc, status = self.run_parser("lvs", "PVS completed normally\n")
        self.assertEqual(rc, 8)
        self.assertIn("PVS_LVS_STATUS=UNKNOWN", status)

    def test_explicit_lvs_match_is_match(self) -> None:
        rc, status = self.run_parser("lvs", "Run Result : MATCH\n")
        self.assertEqual(rc, 0)
        self.assertIn("PVS_LVS_STATUS=MATCH", status)


if __name__ == "__main__":
    unittest.main()
