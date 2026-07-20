#!/usr/bin/env python3
"""Regression checks for the Position foreground density PVS DRC driver."""

from __future__ import annotations

import hashlib
import subprocess
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
DRIVER = REPO / "TOP" / "ci" / "server_run_position_core_pvs_density_drc.sh"
SNAPSHOT = (
    REPO
    / "TOP"
    / "docs"
    / "server_snapshots"
    / "pvs_drc"
    / "position_base_drc_20260720_115921"
)


class PositionPvsDensityDrcDriverTests(unittest.TestCase):
    def test_driver_runs_exactly_one_foreground_density_transaction(self) -> None:
        text = DRIVER.read_text()
        self.assertIn("set +e", text)
        self.assertNotIn("set -e", text)
        self.assertNotIn("nohup", text)
        self.assertNotIn("tail -f", text)
        self.assertNotIn("watch ", text)
        self.assertNotIn("--dry-run", text)
        self.assertEqual(text.count("run_pvs_drc_handoff.sh"), 1)
        self.assertIn("--variant density", text)
        self.assertIn("--allow-cross-block-control-scaffold", text)
        self.assertIn("PVS_WRAPPER_RC=${PIPESTATUS[0]}", text)

    def test_driver_binds_successful_base_result_and_exact_layout(self) -> None:
        text = DRIVER.read_text()
        for token in (
            "dd6ddf67f0c6750109eaa1f9e9915bb3cd25b1c201de43167f26dd620ee8dc00",
            "7d34c9135caf7fccd5d53e803794bb87a53b461bbdfabfb6f9752595c59129c4",
            "ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1",
            "RESULT=PVS_BASE_DRC_ZERO_RESULTS_RECORDED",
            "OUTCOME_CLASS=ATTRIBUTABLE_ZERO_RESULTS",
            "PVS_BASE_DRC_STATUS=PASS",
            "RULE_ANALYSIS_STATUS=NOT_APPLICABLE_ZERO_RESULTS",
            "NEXT_GATE=FOREGROUND_DENSITY_PVS_DRC",
        ):
            self.assertIn(token, text)

    def test_pinned_base_hashes_match_checked_in_snapshot(self) -> None:
        assignments = {}
        for line in DRIVER.read_text().splitlines():
            if line.startswith("EXPECTED_BASE_") and "=" in line:
                key, value = line.split("=", 1)
                assignments[key] = value

        paths = {
            "EXPECTED_BASE_EXECUTION_STATUS_SHA": (
                SNAPSHOT / "status" / "position_pvs_drc_base_execution_status.rpt"
            ),
            "EXPECTED_BASE_RUN_STATUS_SHA": SNAPSHOT / "reports" / "pvs_drc_status.rpt",
            "EXPECTED_BASE_REPLAY_SHA": (
                SNAPSHOT / "reports" / "replay_contract_status.rpt"
            ),
            "EXPECTED_BASE_ISOLATION_SHA": (
                SNAPSHOT / "reports" / "output_isolation.rpt"
            ),
            "EXPECTED_BASE_DEFINES_SHA": (
                SNAPSHOT / "reports" / "preprocessor_defines.rpt"
            ),
            "EXPECTED_BASE_REFERENCES_SHA": (
                SNAPSHOT / "reports" / "external_references.rpt"
            ),
        }
        for key, path in paths.items():
            self.assertTrue(path.is_file(), path)
            actual = hashlib.sha256(path.read_bytes()).hexdigest()
            self.assertEqual(assignments.get(key), actual, key)

    def test_density_selector_and_run_evidence_are_audited(self) -> None:
        text = DRIVER.read_text()
        for token in (
            "PVS_DRC_VARIANT=DENSITY",
            "DEFINE=DENSITY|OCCURRENCES=1",
            '"#DEFINE DENSITY"',
            '"#UNDEFINE POPPING"',
            '"#UNDEFINE PIMIDE"',
            '"#UNDEFINE DUMMY_FILL"',
            '"#DEFINE VAR_ANT_RATIO"',
            "EXECUTION_DIRECTORY_STATUS=PASS",
            "OUTPUT_ISOLATION_STATUS=PASS",
            "RUN_MANIFEST_RC",
        ):
            self.assertIn(token, text)

    def test_only_attributable_zero_or_nonzero_results_are_accepted(self) -> None:
        text = DRIVER.read_text()
        for token in (
            'PVS_WRAPPER_RC" = "0',
            'PVS_WRAPPER_RC" = "8',
            'PVS_TOOL_RC" = "0',
            'PVS_DENSITY_DRC_STATUS" = "PASS',
            'PVS_DENSITY_DRC_STATUS" = "FAIL',
            "Total DRC Results=$DRC_TOTAL_PRIMARY($DRC_TOTAL_EXPANDED)",
            "ATTRIBUTABLE_ZERO_RESULTS",
            "ATTRIBUTABLE_NONZERO_RESULTS",
            "PVS_DENSITY_DRC_INFRASTRUCTURE_OR_RESULT_CLASSIFICATION_FAILED",
        ):
            self.assertIn(token, text)

    def test_nonzero_density_result_is_classified_in_same_transaction(self) -> None:
        text = DRIVER.read_text()
        self.assertEqual(text.count("analyze_pvs_drc_run.py"), 1)
        for token in (
            "--expected-variant density",
            "RESULT_COUNT_RECONCILIATION=PASS",
            "ASCII_ERROR_GEOMETRY_RECONCILIATION=PASS",
            "DENSITY_STATE=DEFINED",
            "PVS_DENSITY_DRC_NONZERO_RULE_DEBT_CLASSIFIED",
            "STOP_AND_REVIEW_DENSITY_RULE_ANALYSIS_FAILURE",
        ):
            self.assertIn(token, text)

    def test_density_and_lvs_gates_remain_separate(self) -> None:
        text = DRIVER.read_text()
        for token in (
            "PVS_BASE_DRC_STATUS=PASS",
            "PVS_DENSITY_DRC_STATUS=$PVS_DENSITY_DRC_STATUS",
            "PVS_LVS_STATUS=NOT_RUN",
            "BLOCK_PROMOTION_AUTHORIZED=NO",
            "SIGNOFF_READY=NO",
            "NEXT_GATE=FOREGROUND_EXACT_GDS_PVS_LVS",
        ):
            self.assertIn(token, text)

    def test_shell_syntax(self) -> None:
        result = subprocess.run(
            ["bash", "-n", str(DRIVER)],
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
