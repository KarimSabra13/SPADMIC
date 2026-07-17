#!/usr/bin/env python3

from __future__ import annotations

import re
import subprocess
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
DRIVER = REPO / "TOP" / "ci" / "server_review_position_core_pvs_drc_seed.sh"


class PositionPvsSeedReviewDriverTest(unittest.TestCase):
    def test_driver_is_interactive_safe_and_never_launches_pvs(self) -> None:
        text = DRIVER.read_text()
        self.assertIn("set +e", text)
        self.assertNotRegex(text, re.compile(r"^\s*set\s+-e", re.MULTILINE))
        self.assertNotRegex(text, re.compile(r"^\s*exit(?:\s|$)", re.MULTILINE))
        self.assertNotIn("run_pvs_drc_handoff.sh", text)
        self.assertNotIn("replay_pvs_handoff_template.py", text)
        self.assertIn('echo "PVS_EXECUTED=NO"', text)
        self.assertIn('echo "PVS_REPLAY_AUTHORIZED=NO"', text)

    def test_techlib_contract_accepts_tabs_or_spaces(self) -> None:
        text = DRIVER.read_text()
        pattern = (
            "^[[:space:]]*techLib[[:space:]]+"
            '\"TECH_XH018_HD\"[[:space:]]*$'
        )
        self.assertIn(pattern, text)
        self.assertNotIn('pipo1.setup|techLib    \\"TECH_XH018_HD\\"', text)

        for separator in ("\t", "    "):
            result = subprocess.run(
                ["grep", "-Eq", pattern],
                input=f'techLib{separator}"TECH_XH018_HD"\n',
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)

    def test_non_density_preprocessor_controls_require_review(self) -> None:
        text = DRIVER.read_text()
        self.assertIn("NON_DENSITY_PREPROCESSOR_DIRECTIVE_COUNT", text)
        self.assertIn("PREPROCESSOR_DIRECTIVE_REVIEW_STATUS", text)
        self.assertIn("POSITION_PVS_DRC_SEED_PREPROCESSOR_MANUAL_REVIEW", text)
        self.assertIn("STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO", text)

    def test_driver_has_valid_bash_syntax(self) -> None:
        result = subprocess.run(
            ["bash", "-n", str(DRIVER)],
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
