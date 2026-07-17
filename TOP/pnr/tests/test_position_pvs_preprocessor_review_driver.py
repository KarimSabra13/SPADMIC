#!/usr/bin/env python3

from __future__ import annotations

import re
import subprocess
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
DRIVER = (
    REPO / "TOP" / "ci" / "server_review_position_core_pvs_drc_preprocessor.sh"
)


class PositionPvsPreprocessorReviewDriverTest(unittest.TestCase):
    def test_driver_is_read_only_and_never_launches_pvs(self) -> None:
        text = DRIVER.read_text()
        self.assertIn("set +e", text)
        self.assertNotRegex(text, re.compile(r"^\s*set\s+-e", re.MULTILINE))
        self.assertNotRegex(text, re.compile(r"^\s*exit(?:\s|$)", re.MULTILINE))
        self.assertNotIn("run_pvs_drc_handoff.sh", text)
        self.assertNotIn("replay_pvs_handoff_template.py", text)
        self.assertIn('echo "PVS_TEMPLATE_CREATED=NO"', text)
        self.assertIn('echo "PVS_EXECUTED=NO"', text)

    def test_driver_pins_corrected_review_evidence(self) -> None:
        text = DRIVER.read_text()
        self.assertIn(
            "9b9c443505bd9cfdacd59de17ba2ac5dc0dd21d4980bd3afea3c5eb8c5415925",
            text,
        )
        self.assertIn(
            "a25d7ca23a36e30d1e060c1dc568af43cb303ef5659c2c2a8037392ac39a9bec",
            text,
        )
        self.assertIn(
            "14f9d02f743dde4b855678df9eccb21d6ebf6c5b71d239d16ea5d238092f947e",
            text,
        )
        self.assertIn("PRIMARY_EXECUTABLE_CONTRACT_STATUS=PASS", text)

    def test_driver_classifies_all_five_directives_fail_closed(self) -> None:
        text = DRIVER.read_text()
        for symbol in (
            "DENSITY",
            "POPPING",
            "PIMIDE",
            "DUMMY_FILL",
            "VAR_ANT_RATIO",
        ):
            self.assertIn(symbol, text)
        self.assertIn("MATRIX_CANDIDATE_COUNT", text)
        self.assertIn("PREPROCESSOR_SEMANTIC_REVIEW_STATUS=REVIEW_REQUIRED", text)
        self.assertIn("STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO", text)
        self.assertIn("RETURN_PVTECH_AND_DIRECTIVE_MATRIX_FOR_MANUAL_REVIEW", text)

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
