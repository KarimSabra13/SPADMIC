#!/usr/bin/env python3
"""Regression checks for the accepted Event exact-GDS LVS evidence."""

from __future__ import annotations

import hashlib
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
SNAPSHOT = (
    REPO
    / "TOP"
    / "docs"
    / "server_snapshots"
    / "pvs_lvs"
    / "event_lvs_match_20260721_121034"
)


def fields(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for line in path.read_text().splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            result[key] = value
    return result


class EventCoordinatorPvsLvsAcceptanceTests(unittest.TestCase):
    def test_tracked_reports_match_pinned_hashes(self) -> None:
        expected = {
            "status/event_pvs_lvs_execution_status.rpt": (
                "16ccb4478f69fde944fb25de469807cba4284e6e9da3fec0bdd196fc72256b68"
            ),
            "reports/pvs_lvs_status.rpt": (
                "b8c68a74363bf3352ffadad4bfbe73440dbcb0eb075ad8587c503fdb99ac5c94"
            ),
            "reports/replay_contract_status.rpt": (
                "c3f430b7100c7d0df6f438f7c86750b7f291276e06720e59ee25084d8ea37dba"
            ),
            "reports/output_isolation.rpt": (
                "bf58c7e67118d7a8785bfe6cd2f98a94ee48cf12c1f2ebc550fbde2a118d9765"
            ),
            "reports/run_control_audit.rpt": (
                "b2cc68c74217e8401f8261c9ce59f03990d2a48cfb87006b63cbd6d473f6e229"
            ),
        }
        manifest = (SNAPSHOT / "manifests" / "tracked_report_hashes.rpt").read_text()
        for relative, digest in expected.items():
            actual = hashlib.sha256((SNAPSHOT / relative).read_bytes()).hexdigest()
            self.assertEqual(actual, digest, relative)
            self.assertIn(f"{digest}  {relative}", manifest)
        self.assertIn("HASH_COUNT=5", manifest)

    def test_execution_status_accepts_only_the_exact_attributable_match(self) -> None:
        status = fields(
            SNAPSHOT / "status" / "event_pvs_lvs_execution_status.rpt"
        )
        expected = {
            "STATUS": "PASS",
            "RESULT": "EVENT_PVS_EXACT_GDS_LVS_MATCH_RECORDED",
            "EXPECTED_HEAD": "624ae1e2967eb66a63e3b33139c66f483e14886f",
            "ACTUAL_HEAD": "624ae1e2967eb66a63e3b33139c66f483e14886f",
            "TRACKED_DIFF_RC": "0",
            "STAGED_DIFF_RC": "0",
            "OUTCOME_CLASS": "ATTRIBUTABLE_MATCH",
            "PVS_WRAPPER_RC": "0",
            "PVS_TOOL_RC": "0",
            "PVS_LVS_STATUS": "MATCH",
            "LVS_NEGATIVE_MATCH_COUNT": "0",
            "LVS_POSITIVE_MATCH_COUNT": "3",
            "REPLAY_CONTRACT_STATUS": "PASS",
            "OUTPUT_ISOLATION_STATUS": "PASS",
            "RUN_CONTROL_AUDIT_RC": "0",
            "RUN_AUDIT_GATE_RC": "0",
            "RUN_MANIFEST_RC": "0",
            "SOURCE_POST_RECHECK_RC": "0",
            "PACKAGE_POST_EXECUTION_SHA_MANIFEST_RC": "0",
        }
        for key, value in expected.items():
            self.assertEqual(status[key], value, key)

    def test_exact_gds_source_cdl_and_tops_are_consistent(self) -> None:
        status = fields(
            SNAPSHOT / "status" / "event_pvs_lvs_execution_status.rpt"
        )
        raw = fields(SNAPSHOT / "reports" / "pvs_lvs_status.rpt")
        replay = fields(SNAPSHOT / "reports" / "replay_contract_status.rpt")
        self.assertEqual(status["PACKAGE_GDS_SHA256"], raw["GDS_SHA256"])
        self.assertEqual(
            status["CANONICAL_LVS_SOURCE_SHA256"], raw["LVS_SOURCE_SHA256"]
        )
        self.assertEqual(status["STDCELL_CDL_SHA256"], raw["STDCELL_CDL_SHA256"])
        self.assertEqual(status["LAYOUT_TOP"], replay["LAYOUT_TOP"])
        self.assertEqual(status["SOURCE_TOP"], replay["SOURCE_TOP"])
        self.assertEqual(status["PACKAGE_GDS"], replay["GDS"])
        self.assertEqual(status["CANONICAL_LVS_SOURCE"], replay["SOURCE"])
        self.assertEqual(status["STDCELL_CDL"], replay["CDL"])

    def test_run_control_and_output_isolation_are_run_local(self) -> None:
        status = fields(
            SNAPSHOT / "status" / "event_pvs_lvs_execution_status.rpt"
        )
        audit = fields(SNAPSHOT / "reports" / "run_control_audit.rpt")
        isolation = fields(SNAPSHOT / "reports" / "output_isolation.rpt")
        self.assertEqual(audit["STATUS"], "PASS")
        self.assertEqual(audit["LAYOUT_PATH_COUNT"], "1")
        self.assertEqual(audit["SCHEMATIC_VERILOG_PATH_COUNT"], "1")
        self.assertEqual(audit["SCHEMATIC_SPICE_PATH_COUNT"], "1")
        self.assertEqual(audit["SVDB_DIRECTORY_COUNT"], "1")
        self.assertEqual(audit["ERROR_COUNT"], "0")
        self.assertEqual(isolation["STATUS"], "PASS")
        self.assertEqual(isolation["RUN_DIR"], status["RUN_DIR"])
        self.assertEqual(isolation["SVDB_ACTION"], "ADDED_MISSING")
        self.assertEqual(isolation["SVDB_REWRITE_COUNT"], "0")
        self.assertEqual(audit["SVDB_DIRECTORY"], f'{status["RUN_DIR"]}/svdb')

    def test_lvs_acceptance_does_not_flatten_density_or_assembly_gates(self) -> None:
        status = fields(
            SNAPSHOT / "status" / "event_pvs_lvs_execution_status.rpt"
        )
        expected = {
            "PVS_BASE_DRC_STATUS": "PASS",
            "PVS_DENSITY_DRC_STATUS": "FAIL",
            "PVS_DENSITY_DRC_PRIMARY_RESULTS": "4",
            "PVS_DENSITY_DRC_EXPANDED_RESULTS": "4",
            "DENSITY_DEBT_CLASS": "OOC_WHOLE_EXTENT_MINIMUM_COVERAGE",
            "PVS_EXECUTED": "YES",
            "EVENT_PVS_LVS_STATUS": "MATCH",
            "ASSEMBLY_INSERTION_AUTHORIZED": "NO",
            "ASSEMBLY_BLOCKED_BY": "p00_tx,p01_position",
            "FULL_TOP_PNR_AUTHORIZED": "NO",
            "BLOCK_PROMOTION_AUTHORIZED": "NO",
            "SIGNOFF_READY": "NO",
        }
        for key, value in expected.items():
            self.assertEqual(status[key], value, key)

    def test_server_manifest_check_was_complete(self) -> None:
        manifest = fields(
            SNAPSHOT / "manifests" / "diagnostic_manifest_check.rpt"
        )
        self.assertEqual(manifest["CHECKED_FILE_COUNT"], "23")
        self.assertEqual(manifest["ALL_RECORDED_FILES_STATUS"], "OK")
        self.assertEqual(manifest["DIAGNOSTIC_MANIFEST_RC"], "0")


if __name__ == "__main__":
    unittest.main()
