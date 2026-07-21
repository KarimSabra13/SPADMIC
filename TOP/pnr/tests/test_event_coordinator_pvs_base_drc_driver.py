#!/usr/bin/env python3
"""Regression checks for the Event foreground base PVS DRC driver."""

from __future__ import annotations

import hashlib
import subprocess
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
DRIVER = REPO / "TOP" / "ci" / "server_run_event_coordinator_pvs_base_drc.sh"
SNAPSHOT = (
    REPO
    / "TOP"
    / "docs"
    / "server_snapshots"
    / "pvs_drc"
    / "event_strict_preflight_20260721_104756"
)


class EventPvsBaseDrcDriverTests(unittest.TestCase):
    def test_driver_runs_exactly_one_foreground_base_transaction(self) -> None:
        text = DRIVER.read_text()
        self.assertIn("set +e", text)
        self.assertNotIn("set -e", text)
        self.assertNotIn("nohup", text)
        self.assertNotIn("tail -f", text)
        self.assertNotIn("watch ", text)
        self.assertNotIn("--dry-run", text)
        self.assertNotIn("--variant density", text)
        self.assertEqual(text.count("run_pvs_drc_handoff.sh"), 1)
        self.assertIn("--variant base", text)
        self.assertIn("--allow-cross-block-control-scaffold", text)
        self.assertIn("PVS_WRAPPER_RC=${PIPESTATUS[0]}", text)

    def test_driver_binds_the_accepted_event_preflight(self) -> None:
        text = DRIVER.read_text()
        for token in (
            "9223b07d86273d6e66c11c49691a8d1a2219bfd3",
            "e1769914c88a29744ed55d03360a334e4574f209ed0902fb65ba1f2d39d5aba8",
            "1f5a952271218d029b204216454e8c780314f27c4f0c6cd8cc7457e002461206",
            "fd7b36de4f3bfb0c4d1062c89bc8ada92a8f4c9471a3e318a6e38c68e62f91e1",
            "e67620e9c76681c18bb35918a7ed68a1614466d12c54e895f9a71d5e413d39b7",
            "21dcfba72ddfb989a350d43f5d3a0ea490383c2d940cfb3876664b31f5ba5dc0",
            "837538f219dacc9521f02bc58b3e2e5e587f859b4e70b69a1ca4a3e5fe7b6857",
            "0b1ce563da515dd50d17a5e16baa2a2addc10354aa06ab5e1a111b01ed039cb6",
            "4d7b850f74ef193b6bc7b15b1e52fd38ba61cc4a6e1b283c4201343a20ad233d",
            "EVENT_STRICT_DRY_RUN_PREFLIGHT_STATUS=PASS",
            "EVENT_PVS_BASE_DRC_EXECUTION_AUTHORIZED=YES",
            "EVENT_PVS_DENSITY_DRC_EXECUTION_AUTHORIZED=NO",
            "PVS_REPLAY_AUTHORIZED=BASE_ONLY",
            "PAD_REACHABLE_GEOMETRY_ELEMENT_COUNT=0",
            "PIMIDE_REACHABLE_GEOMETRY_ELEMENT_COUNT=0",
            "NOPIM_REACHABLE_GEOMETRY_ELEMENT_COUNT=0",
            "UNDEFINE=DENSITY|OCCURRENCES=1",
            "DEFINE=DENSITY|OCCURRENCES=1",
        ):
            self.assertIn(token, text)

    def test_pinned_hashes_match_the_tracked_source_reports(self) -> None:
        bindings = {
            "e1769914c88a29744ed55d03360a334e4574f209ed0902fb65ba1f2d39d5aba8":
                SNAPSHOT / "status" / "event_pvs_drc_strict_preflight_status.rpt",
            "1f5a952271218d029b204216454e8c780314f27c4f0c6cd8cc7457e002461206":
                SNAPSHOT / "reports" / "base_pvs_drc_status.rpt",
            "fd7b36de4f3bfb0c4d1062c89bc8ada92a8f4c9471a3e318a6e38c68e62f91e1":
                SNAPSHOT / "reports" / "density_pvs_drc_status.rpt",
            "510ce1284530920fbd75445d143e792f0803eaec05f9894e00af336f662dc466":
                SNAPSHOT / "reports" / "base_replay_contract_status.rpt",
            "1f8ef07f31201a170d0f770d26596c031821f4c72d58b3ab4517b90f4f837dfa":
                SNAPSHOT / "reports" / "base_preprocessor_defines.rpt",
            "6fb64ded8ddc233d1189d0da3cb6e3857ea998dc4ae6c59b7e4db972f89b6e3c":
                SNAPSHOT / "reports" / "density_preprocessor_defines.rpt",
            "db7cc5a21531fb7a61ff8aff8c1f22b9f9bea9d55043b92c1c9c21b9f3285658":
                SNAPSHOT / "reports" / "base_external_references.rpt",
            "e67620e9c76681c18bb35918a7ed68a1614466d12c54e895f9a71d5e413d39b7":
                SNAPSHOT / "reports" / "gds_layer_applicability_collector_status.rpt",
            "21dcfba72ddfb989a350d43f5d3a0ea490383c2d940cfb3876664b31f5ba5dc0":
                SNAPSHOT / "reports" / "event_option_policy_contract.rpt",
        }
        driver = DRIVER.read_text()
        for expected, path in bindings.items():
            self.assertIn(expected, driver)
            self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), expected)

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
            "EVENT_PVS_BASE_DRC_INFRASTRUCTURE_OR_RESULT_CLASSIFICATION_FAILED",
        ):
            self.assertIn(token, text)

    def test_nonzero_result_is_reconciled_without_a_pvs_rerun(self) -> None:
        text = DRIVER.read_text()
        self.assertEqual(text.count("analyze_pvs_drc_run.py"), 1)
        for token in (
            "--expected-primary",
            "--expected-expanded",
            "RESULT_COUNT_RECONCILIATION=PASS",
            "ASCII_ERROR_GEOMETRY_RECONCILIATION=PASS",
            "EVENT_PVS_BASE_DRC_NONZERO_RULE_DEBT_CLASSIFIED",
            "STOP_AND_REVIEW_EVENT_BASE_RULE_ANALYSIS_FAILURE",
        ):
            self.assertIn(token, text)

    def test_later_gates_remain_separate(self) -> None:
        text = DRIVER.read_text()
        for token in (
            "EVENT_PVS_BASE_DRC_STATUS=$PVS_BASE_DRC_STATUS",
            "EVENT_PVS_DENSITY_DRC_STATUS=NOT_RUN",
            "EVENT_PVS_LVS_STATUS=NOT_RUN",
            "ASSEMBLY_INSERTION_AUTHORIZED=NO",
            "ASSEMBLY_BLOCKED_BY=p00_tx,p01_position",
            "FULL_TOP_PNR_AUTHORIZED=NO",
            "BLOCK_PROMOTION_AUTHORIZED=NO",
            "SIGNOFF_READY=NO",
            "NEXT_GATE=REVIEW_EVENT_BASE_DRC_AND_PREPARE_DENSITY_EXECUTION",
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
