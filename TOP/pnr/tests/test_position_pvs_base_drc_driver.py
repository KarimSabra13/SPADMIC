#!/usr/bin/env python3
"""Regression checks for the Position foreground base PVS DRC driver."""

from __future__ import annotations

import subprocess
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
DRIVER = REPO / "TOP" / "ci" / "server_run_position_core_pvs_base_drc.sh"


class PositionPvsBaseDrcDriverTests(unittest.TestCase):
    def test_driver_runs_exactly_one_foreground_base_pvs_transaction(self) -> None:
        text = DRIVER.read_text()
        self.assertIn("set +e", text)
        self.assertNotIn("set -e", text)
        self.assertNotIn("nohup", text)
        self.assertNotIn("tail -f", text)
        self.assertNotIn("watch ", text)
        self.assertNotIn("--dry-run", text)
        self.assertEqual(text.count("run_pvs_drc_handoff.sh"), 1)
        self.assertIn("--variant base", text)
        self.assertIn("--allow-cross-block-control-scaffold", text)
        self.assertIn("PVS_WRAPPER_RC=${PIPESTATUS[0]}", text)

    def test_driver_binds_successful_r11_and_exact_layout(self) -> None:
        text = DRIVER.read_text()
        for token in (
            "14207ead8ba6f3da501e3bb85a2773c71fa4a1e9847e07c5867b54e4a9b9a563",
            "8abf15ea7cbf229dfd8bd3e86c9c9b7f539e9ca65dae49e09f07e1c43386103e",
            "7626c421c936bfec8d9b6839f8ccf178023b64b862b4e92ff6f04a106e9151e0",
            "ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1",
            "STRICT_DRY_RUN_PREFLIGHT_STATUS=PASS",
            "BASE_DRY_RUN_RC=0",
            "DENSITY_DRY_RUN_RC=0",
            "RUN_AUDIT_GATE_RC=0",
            "UNDEFINE=DENSITY|OCCURRENCES=1",
            "DEFINE=DENSITY|OCCURRENCES=1",
        ):
            self.assertIn(token, text)

    def test_driver_accepts_only_attributable_zero_or_nonzero_results(self) -> None:
        text = DRIVER.read_text()
        for token in (
            'PVS_WRAPPER_RC" = "0',
            'PVS_WRAPPER_RC" = "8',
            'PVS_TOOL_RC" = "0',
            'PVS_BASE_DRC_STATUS" = "PASS',
            'PVS_BASE_DRC_STATUS" = "FAIL',
            "Total DRC Results=$DRC_TOTAL_PRIMARY($DRC_TOTAL_EXPANDED)",
            "ATTRIBUTABLE_ZERO_RESULTS",
            "ATTRIBUTABLE_NONZERO_RESULTS",
            "PVS_BASE_DRC_INFRASTRUCTURE_OR_RESULT_CLASSIFICATION_FAILED",
        ):
            self.assertIn(token, text)

    def test_nonzero_result_is_analyzed_without_rerunning_pvs(self) -> None:
        text = DRIVER.read_text()
        self.assertEqual(text.count("analyze_pvs_drc_run.py"), 1)
        for token in (
            "--expected-primary",
            "--expected-expanded",
            "RESULT_COUNT_RECONCILIATION=PASS",
            "ASCII_ERROR_GEOMETRY_RECONCILIATION=PASS",
            "PVS_BASE_DRC_NONZERO_RULE_DEBT_CLASSIFIED",
            "STOP_AND_REVIEW_BASE_RULE_ANALYSIS_FAILURE",
        ):
            self.assertIn(token, text)

    def test_gate_separation_and_aggressive_next_step_are_explicit(self) -> None:
        text = DRIVER.read_text()
        for token in (
            "PVS_BASE_DRC_STATUS=$PVS_BASE_DRC_STATUS",
            "PVS_DENSITY_DRC_STATUS=NOT_RUN",
            "PVS_LVS_STATUS=NOT_RUN",
            "BLOCK_PROMOTION_AUTHORIZED=NO",
            "SIGNOFF_READY=NO",
            "NEXT_GATE=FOREGROUND_DENSITY_PVS_DRC",
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
