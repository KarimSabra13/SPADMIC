#!/usr/bin/env python3
"""Regression checks for the exact-GDS Event PVS LVS execution gate."""

from __future__ import annotations

import csv
import hashlib
import subprocess
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
DRIVER = REPO / "TOP" / "ci" / "server_run_event_coordinator_pvs_lvs.sh"
LVS_WRAPPER = REPO / "TOP" / "pnr" / "scripts" / "run_pvs_lvs_handoff.sh"
SNAPSHOT = (
    REPO
    / "TOP"
    / "docs"
    / "server_snapshots"
    / "pvs_drc"
    / "event_density_drc_20260721_112300"
)


class EventCoordinatorPvsLvsDriverTests(unittest.TestCase):
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

    def test_driver_binds_accepted_density_run_and_exact_lvs_inputs(self) -> None:
        text = DRIVER.read_text()
        for token in (
            "event_pvs_drc_density_execution_20260721_112300",
            "66ea5eb65de37387a023a77fc4239f1dfab6c6cf",
            "837538f219dacc9521f02bc58b3e2e5e587f859b4e70b69a1ca4a3e5fe7b6857",
            "f9ec957b23b1a229c7c2ff19309fb7463dfc5cac7e570ad1ca68ad8b08089b27",
            "5ff10b0b31003da9bb6db59eba7d52c82435e3ab68b2ba0a1956e4d9fbaef8cf",
            "EVENT_PVS_DENSITY_DRC_NONZERO_RULE_DEBT_CLASSIFIED",
            "DENSITY_MANIFEST_RC",
            "DENSITY_SEMANTIC_GATE_RC",
            "spadmic_event_coordinator",
        ):
            self.assertIn(token, text)

    def test_observed_density_snapshot_hashes_are_pinned(self) -> None:
        expected = {
            "status/event_pvs_drc_density_execution_status.rpt": (
                "d7a65bd2b5bef0123120923a7f4104018d14cee6eaf5008d414769413f2759f8"
            ),
            "reports/pvs_drc_status.rpt": (
                "cc4310414f05a394216bcda16f92f884b15e0b980102007386368b362af7f21f"
            ),
            "reports/preprocessor_defines.rpt": (
                "6fb64ded8ddc233d1189d0da3cb6e3857ea998dc4ae6c59b7e4db972f89b6e3c"
            ),
            "reports/pvs_drc_analysis_status.rpt": (
                "5a7a929c4600740f4877947c4badef4f6d3469bf458ac81eebe41c42199b3f6e"
            ),
            "reports/pvs_drc_rule_inventory.tsv": (
                "f27a027627ede5447ea1ae2a2ac5ef7b811bc4a5a5610865a43d0b33dc46b65b"
            ),
        }
        driver = DRIVER.read_text()
        for relative, digest in expected.items():
            actual = hashlib.sha256((SNAPSHOT / relative).read_bytes()).hexdigest()
            self.assertEqual(actual, digest, relative)
            self.assertIn(digest, driver)

    def test_density_debt_is_four_whole_extent_rules(self) -> None:
        inventory = SNAPSHOT / "reports" / "pvs_drc_rule_inventory.tsv"
        with inventory.open(newline="") as handle:
            rows = list(csv.DictReader(handle, delimiter="\t"))
        self.assertEqual(
            {row["rule"]: row["layer_or_object"] for row in rows},
            {"R1M1": "MET1", "R1M2": "MET2", "R1M3": "MET3", "R1MT": "METTP"},
        )
        self.assertTrue(all(row["category"] == "DENSITY" for row in rows))
        self.assertTrue(
            all(
                row["aggregate_bbox_um"]
                == "0.000000 0.000000 237.360000 219.520000"
                for row in rows
            )
        )
        driver = DRIVER.read_text()
        for token in ("R1M1", "R1M2", "R1M3", "R1MT", "EXTENT area ... 30.0%"):
            self.assertIn(token, driver)

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
            "EVENT_PVS_EXACT_GDS_LVS_INFRASTRUCTURE_OR_RESULT_CLASSIFICATION_FAILED",
        ):
            self.assertIn(token, text)

    def test_run_audit_uses_valid_svdb_normalization_and_directives(self) -> None:
        text = DRIVER.read_text()
        for token in (
            '"$RUN_ISOLATION|SVDB_DIRECTORY=$RUN_DIR/svdb"',
            '"$RUN_ISOLATION|SVDB_ACTION=ADDED_MISSING"',
            '"$RUN_ISOLATION|SVDB_REWRITE_COUNT=0"',
            "audit_pvs_lvs_run_control.py",
            "RUN_CONTROL_AUDIT_RC",
        ):
            self.assertIn(token, text)
        self.assertNotIn('"$RUN_ISOLATION|SVDB_REWRITE_COUNT=1"', text)

    def test_independent_gates_and_next_decisions_are_explicit(self) -> None:
        text = DRIVER.read_text()
        for token in (
            "PVS_BASE_DRC_STATUS=PASS",
            "PVS_DENSITY_DRC_STATUS=FAIL",
            "DENSITY_DEBT_CLASS=OOC_WHOLE_EXTENT_MINIMUM_COVERAGE",
            "DENSITY_DISPOSITION_STATUS=REVIEW_REQUIRED_FOR_ASSEMBLED_FILL_OR_FORMAL_WAIVER",
            "EVENT_PVS_LVS_STATUS=",
            "ASSEMBLY_INSERTION_AUTHORIZED=NO",
            "ASSEMBLY_BLOCKED_BY=p00_tx,p01_position",
            "FULL_TOP_PNR_AUTHORIZED=NO",
            "BLOCK_PROMOTION_AUTHORIZED=NO",
            "SIGNOFF_READY=NO",
            "NEXT_GATE=REVIEW_EVENT_EXACT_GDS_LVS_MATCH_AND_DENSITY_DISPOSITION",
            "NEXT_GATE=CLASSIFY_EVENT_EXACT_GDS_LVS_MISMATCH_NO_RERUN",
        ):
            self.assertIn(token, text)

    def test_shell_syntax_and_executable_mode(self) -> None:
        self.assertTrue(DRIVER.stat().st_mode & 0o111)
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
