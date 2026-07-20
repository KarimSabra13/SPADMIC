#!/usr/bin/env python3
"""Regression checks for the Position exact-GDS PVS LVS driver."""

from __future__ import annotations

import csv
import hashlib
import subprocess
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
DRIVER = REPO / "TOP" / "ci" / "server_run_position_core_pvs_lvs.sh"
LVS_WRAPPER = REPO / "TOP" / "pnr" / "scripts" / "run_pvs_lvs_handoff.sh"
SCAFFOLD_AUDIT = (
    REPO / "TOP" / "pnr" / "scripts" / "audit_pvs_lvs_control_scaffold.py"
)
SNAPSHOT = (
    REPO
    / "TOP"
    / "docs"
    / "server_snapshots"
    / "pvs_drc"
    / "position_density_drc_20260720_133314"
)


class PositionPvsLvsDriverTests(unittest.TestCase):
    def test_driver_runs_one_foreground_exact_gds_lvs_transaction(self) -> None:
        text = DRIVER.read_text()
        self.assertIn("set +e", text)
        self.assertNotIn("set -e", text)
        self.assertNotIn("nohup", text)
        self.assertNotIn("tail -f", text)
        self.assertNotIn("watch ", text)
        self.assertNotIn("--dry-run", text)
        self.assertEqual(text.count("run_pvs_lvs_handoff.sh"), 1)
        self.assertIn("--allow-cross-block-control-scaffold", text)
        self.assertIn('SPADMIC_CADENCE_PVS_BIN="$PVS_BIN"', text)
        self.assertIn("PVS_WRAPPER_RC=${PIPESTATUS[0]}", text)

    def test_driver_pins_and_semantically_audits_observed_server_scaffold(self) -> None:
        text = DRIVER.read_text()
        for token in (
            "TEMPLATE_BASELINE_ID=SERVER_OBSERVED_20260720_141229",
            "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
            "43d19579b0569863b1c5fcc317206cc5f3f70611b22f9bdea932d757ff902dfe",
            "74a297facf6422635df2c58d79aa8b8ae46ca0b8232380471a88a182d8400ab6",
            "ed8c1a13ab8ec90af3f367b4d408e5f9c767f1e99736e31f02c54be9fa91abbc",
            "8e53876734717f4c0857f1310d08e3a4c8fb18aeaa7694800b7d0cdcd511c5e6",
            "dfe5394bd98c828e868a7a3f18acda2f56f993ba58dcf8343f097858f77b0c27",
            "audit_pvs_lvs_control_scaffold.py",
            "TEMPLATE_CONTROL_SOURCE_MUTATION_AUTHORIZED=NO",
            "TEMPLATE_IDENTITY_GATE_RC",
            "TEMPLATE_SEMANTIC_GATE_RC",
            'TEMPLATE_GDS="$(kv_field "$TEMPLATE_AUDIT" TEMPLATE_GDS)"',
            'TEMPLATE_SOURCE="$(kv_field "$TEMPLATE_AUDIT" TEMPLATE_SOURCE)"',
            'TEMPLATE_LAYOUT_TOP="$(kv_field "$TEMPLATE_AUDIT" TEMPLATE_LAYOUT_TOP)"',
            'TEMPLATE_SOURCE_TOP="$(kv_field "$TEMPLATE_AUDIT" TEMPLATE_SOURCE_TOP)"',
        ):
            self.assertIn(token, text)
        self.assertEqual(text.count("audit_pvs_lvs_control_scaffold.py"), 1)
        self.assertIn('if [ "$TEMPLATE_SOURCE" != "$PACKAGE_SOURCE" ]; then', text)
        self.assertIn('if [ "$TEMPLATE_GDS" != "$PACKAGE_GDS" ]; then', text)
        for stale_digest in (
            "24a96996d39f98e12c1b1bbc7dc7af74ff2ba5b1152dd0afe462b7ffb3cf2687",
            "449148fe96167a6d0787861c3575a6f31f4c9598e972ee8a7026e9fb3383dc85",
            "7fc5ffd6115ee9ab9aa78a3964f01a43941a0926e2c1d1c53c5b7ede3f25767d",
            "8c0c4e925cf7e595be64685bf01e5bc3e9059ea655a4da0980e67d04dfc113a9",
        ):
            self.assertNotIn(stale_digest, text)

    def test_driver_binds_density_debt_and_all_exact_lvs_inputs(self) -> None:
        text = DRIVER.read_text()
        for token in (
            "8ec65bc2a36c6ea51bb163e3bce796d8288f4dee25a4b4c27670a3309ef66686",
            "ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1",
            "a5e81c21e633ae1b55d8da5c8e971997f890d9cee42dff2f6cf9f9f43cad9ffb",
            "5ff10b0b31003da9bb6db59eba7d52c82435e3ab68b2ba0a1956e4d9fbaef8cf",
            "PVS_DENSITY_DRC_NONZERO_RULE_DEBT_CLASSIFIED",
            "DENSITY_SEMANTIC_GATE_RC",
            "R1M1",
            "R1M2",
            "R1M3",
            "R1MT",
            "EXTENT area ... 30.0%",
        ):
            self.assertIn(token, text)

    def test_density_snapshot_hashes_and_whole_extent_rules_are_pinned(self) -> None:
        expected = {
            "status/position_pvs_drc_density_execution_status.rpt": (
                "8ec65bc2a36c6ea51bb163e3bce796d8288f4dee25a4b4c27670a3309ef66686"
            ),
            "reports/pvs_drc_status.rpt": (
                "9b6a1ec7fa75111a393a6a63f7af44cc66f1c7ef6334506d24cd35880c8ce90e"
            ),
            "reports/replay_contract_status.rpt": (
                "81dd3cc0ed5231179242b4a9af59672ec3eb23e0b6748ac25dc7b1b9f8346115"
            ),
            "reports/output_isolation.rpt": (
                "9ea0552d672fe970d7bd521a5ca1bf652f308e2686be1c1c683f5bfe09e310a4"
            ),
            "reports/preprocessor_defines.rpt": (
                "6fb64ded8ddc233d1189d0da3cb6e3857ea998dc4ae6c59b7e4db972f89b6e3c"
            ),
            "reports/external_references.rpt": (
                "44f77c9f4bcf74665edd21bbd41fd315183156791124c2b898724e173092250a"
            ),
            "reports/pvs_drc_analysis_status.rpt": (
                "a6d6e3b7359f49dac74f71d58c62f82269c6e682df7f503b55745a4448b09717"
            ),
            "reports/pvs_drc_rule_inventory.tsv": (
                "d3fa48ffaeb2e94069c9a132188ca08dd25377bc31d5299fe418da2ee6f229f1"
            ),
        }
        driver = DRIVER.read_text()
        for relative, digest in expected.items():
            actual = hashlib.sha256((SNAPSHOT / relative).read_bytes()).hexdigest()
            self.assertEqual(actual, digest, relative)
            self.assertIn(digest, driver)

        inventory = SNAPSHOT / "reports" / "pvs_drc_rule_inventory.tsv"
        with inventory.open(newline="") as handle:
            rows = list(csv.DictReader(handle, delimiter="\t"))
        self.assertEqual(
            {row["rule"]: row["layer_or_object"] for row in rows},
            {"R1M1": "MET1", "R1M2": "MET2", "R1M3": "MET3", "R1MT": "METTP"},
        )
        self.assertTrue(
            all(
                row["aggregate_bbox_um"]
                == "0.000000 0.000000 951.440000 659.680000"
                for row in rows
            )
        )

    def test_driver_accepts_only_explicit_match_or_mismatch(self) -> None:
        text = DRIVER.read_text()
        for token in (
            'PVS_WRAPPER_RC" = "0',
            'PVS_WRAPPER_RC" = "8',
            'PVS_TOOL_RC" = "0',
            'PVS_LVS_STATUS" = "MATCH',
            'PVS_LVS_STATUS" = "MISMATCH',
            "LVS_NEGATIVE_MATCH_COUNT",
            "LVS_POSITIVE_MATCH_COUNT",
            "ATTRIBUTABLE_MATCH",
            "ATTRIBUTABLE_MISMATCH",
            "PVS_EXACT_GDS_LVS_INFRASTRUCTURE_OR_RESULT_CLASSIFICATION_FAILED",
        ):
            self.assertIn(token, text)

    def test_driver_audits_run_local_svdb_added_to_optional_scaffold(self) -> None:
        text = DRIVER.read_text()
        for token in (
            '"$RUN_ISOLATION|SVDB_DIRECTORY=$RUN_DIR/svdb"',
            '"$RUN_ISOLATION|SVDB_ACTION=ADDED_MISSING"',
            '"$RUN_ISOLATION|SVDB_REWRITE_COUNT=0"',
        ):
            self.assertIn(token, text)
        self.assertNotIn('"$RUN_ISOLATION|SVDB_REWRITE_COUNT=1"', text)

    def test_gate_separation_and_aggressive_next_step_are_explicit(self) -> None:
        text = DRIVER.read_text()
        for token in (
            "PVS_BASE_DRC_STATUS=PASS",
            "PVS_DENSITY_DRC_STATUS=FAIL",
            "PVS_DENSITY_DRC_PRIMARY_RESULTS=4",
            "DENSITY_DEBT_CLASS=OOC_WHOLE_EXTENT_MINIMUM_COVERAGE",
            "DENSITY_DISPOSITION_STATUS=REVIEW_REQUIRED_FOR_ASSEMBLED_FILL_OR_FORMAL_WAIVER",
            "BLOCK_PROMOTION_AUTHORIZED=NO",
            "SIGNOFF_READY=NO",
            "NEXT_GATE=START_EVENT_OOC_AND_REVIEW_POSITION_DENSITY_DISPOSITION",
        ):
            self.assertIn(token, text)

    def test_lvs_wrapper_records_cross_block_and_input_identity(self) -> None:
        text = LVS_WRAPPER.read_text()
        for token in (
            "--allow-cross-block-control-scaffold",
            "CROSS_BLOCK_CONTROL_SCAFFOLD_AUTHORIZED=",
            "LAYOUT_TOP=",
            "SOURCE_TOP=",
            "STDCELL_CDL=",
            "STDCELL_CDL_SHA256=",
        ):
            self.assertIn(token, text)

    def test_lvs_wrapper_does_not_infer_cdl_from_gui_preset(self) -> None:
        text = LVS_WRAPPER.read_text()
        self.assertIn("[--template-cdl FILE]", text)
        self.assertIn('if [[ -n "$TEMPLATE_CDL" ]]; then', text)
        self.assertIn('ARGS+=(--expected-cdl "$CDL")', text)
        self.assertNotIn(
            'for value in "$TEMPLATE_GDS" "$TEMPLATE_SOURCE" '
            '"$TEMPLATE_LAYOUT_TOP" "$TEMPLATE_SOURCE_TOP" "$TEMPLATE_CDL"',
            text,
        )

    def test_scaffold_audit_is_executable_python(self) -> None:
        self.assertTrue(SCAFFOLD_AUDIT.is_file())
        self.assertTrue(SCAFFOLD_AUDIT.stat().st_mode & 0o111)
        result = subprocess.run(
            ["python3", "-m", "py_compile", str(SCAFFOLD_AUDIT)],
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_shell_syntax(self) -> None:
        for script in (DRIVER, LVS_WRAPPER):
            result = subprocess.run(
                ["bash", "-n", str(script)],
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
