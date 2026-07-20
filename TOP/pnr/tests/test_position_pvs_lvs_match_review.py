#!/usr/bin/env python3
"""Regression checks for read-only acceptance of the Position LVS match."""

from __future__ import annotations

import hashlib
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
EXECUTION_DRIVER = REPO / "TOP" / "ci" / "server_run_position_core_pvs_lvs.sh"
REVIEW_DRIVER = REPO / "TOP" / "ci" / "server_review_position_core_pvs_lvs_match.sh"
RUN_CONTROL_AUDITOR = REPO / "TOP" / "pnr" / "scripts" / "audit_pvs_lvs_run_control.py"
SNAPSHOT = (
    REPO
    / "TOP"
    / "docs"
    / "server_snapshots"
    / "pvs_lvs"
    / "position_lvs_match_20260720_155406_audit_stop"
)
REVIEW_STOP_SNAPSHOT = (
    REPO
    / "TOP"
    / "docs"
    / "server_snapshots"
    / "pvs_lvs"
    / "position_lvs_match_review_20260720_161519_failed"
)


class PositionPvsLvsMatchReviewTests(unittest.TestCase):
    def test_future_execution_driver_accepts_added_missing_svdb(self) -> None:
        text = EXECUTION_DRIVER.read_text()
        for token in (
            '"$RUN_ISOLATION|SVDB_DIRECTORY=$RUN_DIR/svdb"',
            '"$RUN_ISOLATION|SVDB_ACTION=ADDED_MISSING"',
            '"$RUN_ISOLATION|SVDB_REWRITE_COUNT=0"',
        ):
            self.assertIn(token, text)
        self.assertNotIn('"$RUN_ISOLATION|SVDB_REWRITE_COUNT=1"', text)

    def test_review_is_read_only_and_never_launches_pvs(self) -> None:
        text = REVIEW_DRIVER.read_text()
        self.assertIn("set +e", text)
        self.assertNotIn("set -e", text)
        self.assertNotIn("run_pvs_lvs_handoff.sh", text)
        self.assertNotIn("nohup", text)
        self.assertNotIn("tail -f", text)
        self.assertNotIn("watch ", text)
        self.assertIn('echo "SOURCE_PVS_EXECUTED=YES"', text)
        self.assertIn('echo "PVS_EXECUTED=NO"', text)
        self.assertIn('echo "PVS_RERUN_AUTHORIZED=NO"', text)

    def test_review_requires_exact_match_and_all_identity_gates(self) -> None:
        text = REVIEW_DRIVER.read_text()
        for token in (
            "position_pvs_lvs_execution_20260720_155406",
            "position_exact_gds_lvs_20260720_155406",
            "PVS_LVS_STATUS=MATCH",
            "LVS_NEGATIVE_MATCH_COUNT=0",
            "LVS_POSITIVE_MATCH_COUNT=3",
            "SOURCE_DIAGNOSTIC_MANIFEST_RC",
            "RUN_COPY_IDENTITY_GATE_RC",
            "RUN_MANIFEST_RC",
            "RUN_MATCH_GATE_RC",
            "RUN_REPLAY_GATE_RC",
            "RUN_ISOLATION_GATE_RC",
            "RUN_REFERENCE_GATE_RC",
            "RUN_CONTROL_GATE_RC",
            "REVIEW_RUN_AUDIT_GATE_RC",
            "PACKAGE_SHA_MANIFEST_RC",
            "ATTRIBUTABLE_MATCH",
        ):
            self.assertIn(token, text)

    def test_review_uses_directive_aware_control_audit(self) -> None:
        text = REVIEW_DRIVER.read_text()
        self.assertIn("audit_pvs_lvs_run_control.py", text)
        self.assertIn("--expected-svdb", text)
        self.assertNotIn('grep -Foc "$PACKAGE_GDS"', text)
        self.assertNotIn('grep -Foc "$RUN_DIR/svdb"', text)

    def test_control_audit_ignores_incidental_path_occurrences(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            gds = root / "canonical.gds"
            source = root / "canonical.lvs.pg.v"
            cdl = root / "xh018_D_CELLS_JIHD.cdl"
            svdb = root / "svdb"
            control = root / "pvslvsctl"
            control.write_text(
                f'layout_path "{gds}";\n'
                f'schematic_path "{source}" verilog;\n'
                f'schematic_path "{cdl}" spice;\n'
                f'mask_svdb_dir "{svdb}";\n'
                f'metadata_path "{gds}";\n'
                f'// Retired source: {source}\n'
            )
            result = subprocess.run(
                [
                    "python3",
                    str(RUN_CONTROL_AUDITOR),
                    "--control",
                    str(control),
                    "--expected-gds",
                    str(gds),
                    "--expected-source",
                    str(source),
                    "--expected-cdl",
                    str(cdl),
                    "--expected-svdb",
                    str(svdb),
                ],
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("STATUS=PASS", result.stdout)
            self.assertIn("LAYOUT_PATH_COUNT=1", result.stdout)
            self.assertIn("SVDB_DIRECTORY_COUNT=1", result.stdout)

    def test_control_audit_rejects_wrong_executable_path(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            gds = root / "canonical.gds"
            source = root / "canonical.lvs.pg.v"
            cdl = root / "xh018_D_CELLS_JIHD.cdl"
            svdb = root / "svdb"
            control = root / "pvslvsctl"
            control.write_text(
                f'layout_path "{root / "wrong.gds"}";\n'
                f'schematic_path "{source}" verilog;\n'
                f'schematic_path "{cdl}" spice;\n'
                f'mask_svdb_dir "{svdb}";\n'
            )
            result = subprocess.run(
                [
                    "python3",
                    str(RUN_CONTROL_AUDITOR),
                    "--control",
                    str(control),
                    "--expected-gds",
                    str(gds),
                    "--expected-source",
                    str(source),
                    "--expected-cdl",
                    str(cdl),
                    "--expected-svdb",
                    str(svdb),
                ],
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(result.returncode, 1)
            self.assertIn("STATUS=FAIL", result.stdout)
            self.assertIn("ERROR=layout_path_values=", result.stdout)

    def test_review_preserves_gate_separation_and_advances_event(self) -> None:
        text = REVIEW_DRIVER.read_text()
        for token in (
            "SOURCE_TRANSACTION_STATUS=FAIL",
            "SOURCE_RUN_AUDIT_GATE_RC=1",
            "SOURCE_RECORDED_PVS_LVS_STATUS=MATCH",
            "STALE_SVDB_REWRITE_COUNT_EXPECTATION",
            "SVDB_ADDED_MISSING_IS_VALID_NORMALIZATION",
            "EXECUTABLE_DIRECTIVE_AUDIT_REPLACES_UNSCOPED_LITERAL_COUNTS",
            "PVS_BASE_DRC_STATUS=PASS",
            "PVS_DENSITY_DRC_STATUS=FAIL",
            "DENSITY_DEBT_CLASS=OOC_WHOLE_EXTENT_MINIMUM_COVERAGE",
            "BLOCK_PROMOTION_AUTHORIZED=NO",
            "SIGNOFF_READY=NO",
            "EVENT_OOC_START_AUTHORIZED=",
            "NEXT_GATE=START_EVENT_OOC_AND_REVIEW_POSITION_DENSITY_DISPOSITION",
        ):
            self.assertIn(token, text)

    def test_snapshot_hashes_are_pinned_by_the_reviewer(self) -> None:
        expected = {
            "status/position_pvs_lvs_execution_status.rpt": (
                "529c30731f77d464da5fff07f8570dfa53fe637fd8ec257ac751ec325a2a4544"
            ),
            "reports/pvs_lvs_status.rpt": (
                "7756b045218d54aba74e85c600268ddcf78829f400412993d39d1e7986187a1a"
            ),
            "reports/replay_contract_status.rpt": (
                "3dab32d283b9b20e949496ee36f783f4f0a18ec149a4bce3004d1f6927bf1460"
            ),
            "reports/output_isolation.rpt": (
                "441678b170db01abbd1befc5f3d8efca7a102a7dabdc62bf483526bd16ce1c6f"
            ),
            "reports/external_references.rpt": (
                "7ffe3059f34f7fed735ed33726a146aacbb346de5f246d7761809ffb91616ac5"
            ),
            "reports/template_replacements.rpt": (
                "9406f7eb5900188000b54da345b0b3de3d0542616add9554c972903e4ac3bbba"
            ),
        }
        driver = REVIEW_DRIVER.read_text()
        for relative, digest in expected.items():
            actual = hashlib.sha256((SNAPSHOT / relative).read_bytes()).hexdigest()
            self.assertEqual(actual, digest, relative)
            self.assertIn(digest, driver)

    def test_snapshot_records_match_and_only_stale_audit_failure(self) -> None:
        status = (SNAPSHOT / "status" / "position_pvs_lvs_execution_status.rpt").read_text()
        raw = (SNAPSHOT / "reports" / "pvs_lvs_status.rpt").read_text()
        isolation = (SNAPSHOT / "reports" / "output_isolation.rpt").read_text()
        failure = (SNAPSHOT / "reports" / "audit_failure.rpt").read_text()
        for token in (
            "PVS_WRAPPER_RC=0",
            "PVS_TOOL_RC=0",
            "PVS_LVS_STATUS=MATCH",
            "LVS_NEGATIVE_MATCH_COUNT=0",
            "LVS_POSITIVE_MATCH_COUNT=3",
            "RUN_AUDIT_GATE_RC=1",
        ):
            self.assertIn(token, status)
        self.assertIn("PVS_LVS_STATUS=MATCH", raw)
        self.assertIn("SVDB_ACTION=ADDED_MISSING", isolation)
        self.assertIn("SVDB_REWRITE_COUNT=0", isolation)
        self.assertIn("CLASSIFICATION=POST_RUN_AUDIT_POLICY_DEFECT", failure)
        self.assertIn("PVS_RERUN_REQUIRED=NO", failure)

    def test_review_stop_snapshot_preserves_exact_uncertainty(self) -> None:
        status = (
            REVIEW_STOP_SNAPSHOT
            / "status"
            / "position_pvs_lvs_match_review_status.rpt"
        ).read_text()
        failure = (
            REVIEW_STOP_SNAPSHOT / "reports" / "control_gate_failure.rpt"
        ).read_text()
        for token in (
            "RUN_MATCH_GATE_RC=0",
            "RUN_REPLAY_GATE_RC=0",
            "RUN_ISOLATION_GATE_RC=0",
            "RUN_REFERENCE_GATE_RC=0",
            "RUN_CONTROL_GATE_RC=1",
            "PVS_EXECUTED=NO",
            "EVENT_OOC_START_AUTHORIZED=NO",
        ):
            self.assertIn(token, status)
        self.assertIn("FAILED_SUBCHECK=UNKNOWN_NOT_EMITTED_BY_SOURCE_REVIEW", failure)
        self.assertIn("PVS_RERUN_REQUIRED=NO", failure)

    def test_shell_syntax_and_executable_mode(self) -> None:
        self.assertTrue(REVIEW_DRIVER.stat().st_mode & 0o111)
        self.assertTrue(RUN_CONTROL_AUDITOR.stat().st_mode & 0o111)
        for script in (EXECUTION_DRIVER, REVIEW_DRIVER):
            result = subprocess.run(
                ["bash", "-n", str(script)],
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
