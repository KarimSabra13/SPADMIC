#!/usr/bin/env python3

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
PARSER = REPO / "TOP" / "pnr" / "scripts" / "parse_pvs_handoff_result.py"


class PvsResultParserTest(unittest.TestCase):
    def run_parser(self, mode: str, content: str, tool_rc: int = 0):
        temporary = tempfile.TemporaryDirectory()
        root = Path(temporary.name)
        (root / "result.txt").write_text(content)
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
