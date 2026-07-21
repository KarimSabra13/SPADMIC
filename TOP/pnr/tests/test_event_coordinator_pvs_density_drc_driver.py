#!/usr/bin/env python3
"""Regression checks for the Event foreground density PVS DRC driver."""

from __future__ import annotations

import hashlib
import subprocess
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
DRIVER = REPO / "TOP" / "ci" / "server_run_event_coordinator_pvs_density_drc.sh"
SNAPSHOT = (
    REPO
    / "TOP"
    / "docs"
    / "server_snapshots"
    / "pvs_drc"
    / "event_base_drc_20260721_110404"
)


class EventCoordinatorPvsDensityDrcDriverTests(unittest.TestCase):
    def test_driver_runs_exactly_one_foreground_density_transaction(self) -> None:
        text = DRIVER.read_text()
        self.assertIn("set +e", text)
        self.assertNotIn("set -e", text)
        self.assertNotIn("nohup", text)
        self.assertNotIn("tail -f", text)
        self.assertNotIn("watch ", text)
        self.assertNotIn("--dry-run", text)
        self.assertNotIn("run_pvs_lvs_handoff.sh", text)
        self.assertEqual(text.count("run_pvs_drc_handoff.sh"), 1)
        self.assertIn("--variant density", text)
        self.assertIn("--allow-cross-block-control-scaffold", text)
        self.assertIn("PVS_WRAPPER_RC=${PIPESTATUS[0]}", text)

    def test_driver_binds_successful_base_result_and_exact_layout(self) -> None:
        text = DRIVER.read_text()
        for token in (
            "616f4c450b41eb0ed626a4cb73b6e78cf8076f6b0671d0d058200e8bb47688ea",
            "b829aedce7251ed8a390efd14694659f6dae1add311a2c4a5d7d0f5c55cda11a",
            "837538f219dacc9521f02bc58b3e2e5e587f859b4e70b69a1ca4a3e5fe7b6857",
            "EXPECTED_BASE_DRC_ROOT=/sim/ksabra/SPADMIC_work/diagnostics/"
            "event_pvs_drc_base_execution_20260721_110404",
            "EXPECTED_BASE_EXECUTION_HEAD="
            "e0325d688a73b261742dc70097b1059aba8e035b",
            "RESULT=EVENT_PVS_BASE_DRC_ZERO_RESULTS_RECORDED",
            "OUTCOME_CLASS=ATTRIBUTABLE_ZERO_RESULTS",
            "PVS_BASE_DRC_STATUS=PASS",
            "RULE_ANALYSIS_STATUS=NOT_APPLICABLE_ZERO_RESULTS",
            "NEXT_GATE=REVIEW_EVENT_BASE_DRC_AND_PREPARE_DENSITY_EXECUTION",
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
                SNAPSHOT / "status" / "event_pvs_drc_base_execution_status.rpt"
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
            "PVS_REPLAY_AUTHORIZED=DENSITY_ONLY",
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
            "EVENT_PVS_DENSITY_DRC_INFRASTRUCTURE_OR_RESULT_CLASSIFICATION_FAILED",
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
            "EVENT_PVS_DENSITY_DRC_NONZERO_RULE_DEBT_CLASSIFIED",
            "STOP_AND_REVIEW_EVENT_DENSITY_RULE_ANALYSIS_FAILURE",
        ):
            self.assertIn(token, text)

    def test_density_and_lvs_gates_remain_separate(self) -> None:
        text = DRIVER.read_text()
        for token in (
            "PVS_BASE_DRC_STATUS=$PVS_BASE_DRC_STATUS",
            "PVS_DENSITY_DRC_STATUS=$PVS_DENSITY_DRC_STATUS",
            "EVENT_PVS_BASE_DRC_STATUS=$PVS_BASE_DRC_STATUS",
            "EVENT_PVS_DENSITY_DRC_STATUS=$PVS_DENSITY_DRC_STATUS",
            "EVENT_PVS_LVS_EXECUTION_AUTHORIZED=NO",
            "EVENT_PVS_LVS_STATUS=NOT_RUN",
            "ASSEMBLY_PHASE=p02_event_control",
            "ASSEMBLY_INSERTION_AUTHORIZED=NO",
            "ASSEMBLY_BLOCKED_BY=p00_tx,p01_position",
            "FULL_TOP_PNR_AUTHORIZED=NO",
            "BLOCK_PROMOTION_AUTHORIZED=NO",
            "SIGNOFF_READY=NO",
            "NEXT_GATE=REVIEW_EVENT_DENSITY_DRC_AND_PREPARE_EXACT_GDS_LVS",
        ):
            self.assertIn(token, text)

    def test_foundry_rule_and_stream_mapping_are_hash_pinned(self) -> None:
        text = DRIVER.read_text()
        for token in (
            "DRC_RULE_FILE=/data/pdk/xfab/xh018/cadence/v10_1/pvs/"
            "v10_1_1/PVS/xh018_DRC.rul",
            "EXPECTED_DRC_RULE_SHA="
            "0b1ce563da515dd50d17a5e16baa2a2addc10354aa06ab5e1a111b01ed039cb6",
            "STREAM_MAP_FILE=/data/pdk/xfab/xh018/cadence/v10_1/PDK/"
            "IC61/v10_1_1/TECH_XH018_HD_1131/pnr_streamout.map",
            "EXPECTED_STREAM_MAP_SHA="
            "4d7b850f74ef193b6bc7b15b1e52fd38ba61cc4a6e1b283c4201343a20ad233d",
            '"$DRC_RULE_FILE|$EXPECTED_DRC_RULE_SHA"',
            '"$STREAM_MAP_FILE|$EXPECTED_STREAM_MAP_SHA"',
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
