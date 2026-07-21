#!/usr/bin/env python3
"""Regression checks for the Event base+density strict dry-run driver."""

from __future__ import annotations

import re
import subprocess
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
DRIVER = REPO / "TOP" / "ci" / "server_preflight_event_coordinator_pvs_drc.sh"
HANDOFF = REPO / "TOP" / "pnr" / "scripts" / "run_pvs_drc_handoff.sh"
SNAPSHOT = (
    REPO
    / "TOP"
    / "docs"
    / "server_snapshots"
    / "handoff"
    / "event_coordinator_20260720_173527"
)


class EventCoordinatorPvsStrictPreflightTests(unittest.TestCase):
    def test_driver_is_interactive_safe_and_never_executes_pvs(self) -> None:
        text = DRIVER.read_text()
        self.assertIn("set +e", text)
        self.assertNotRegex(text, re.compile(r"^\s*set\s+-e", re.MULTILINE))
        self.assertNotRegex(text, re.compile(r"^\s*exit(?:\s|$)", re.MULTILINE))
        self.assertNotIn("nohup", text)
        self.assertNotIn("tail -f", text)
        self.assertNotIn("watch ", text)
        self.assertNotIn("bash ./run.pvs", text)
        self.assertNotIn("pvs.stdout.log\" 2>&1", text)
        self.assertEqual(text.count("bash TOP/pnr/scripts/run_pvs_drc_handoff.sh"), 2)
        self.assertEqual(text.count("--dry-run"), 2)

    def test_driver_binds_exact_staging_package_and_physical_artifacts(self) -> None:
        text = DRIVER.read_text()
        for token in (
            "event_handoff_staging_20260721_101249",
            "innovus_ooc_harden_event_coordinator_20260720_173527",
            "0fff3d2afb447f746c69ea946450ff6f5cdd7400",
            "EVENT_IMMUTABLE_HANDOFF_STAGING_STATUS=PASS",
            "OUTCOME_CLASS=ATTRIBUTABLE_CANDIDATE_PACKAGE",
            "837538f219dacc9521f02bc58b3e2e5e587f859b4e70b69a1ca4a3e5fe7b6857",
            "56345986a887317f0374984b1ea8b3442ea482aeec0572614e9fd2c0b6732a14",
            "f9d6a927c7cecad40916cac67b8142f6fb6c6b013e3d57ab779889fd0ab21a68",
            "0ecc571317f6beaa13c7f006ac3ecc4f1ff2a72b9655a176c0fa21e3c0a07398",
            "f9ec957b23b1a229c7c2ff19309fb7463dfc5cac7e570ad1ca68ad8b08089b27",
            "5ff10b0b31003da9bb6db59eba7d52c82435e3ab68b2ba0a1956e4d9fbaef8cf",
        ):
            self.assertIn(token, text)

    def test_driver_proves_exact_event_gds_selector_applicability(self) -> None:
        text = DRIVER.read_text()
        for token in (
            "collect_position_pvs_gds_layer_applicability.py",
            "--subject-label event",
            "--top-structure \"$EVENT_TOP\"",
            "0b1ce563da515dd50d17a5e16baa2a2addc10354aa06ab5e1a111b01ed039cb6",
            "4d7b850f74ef193b6bc7b15b1e52fd38ba61cc4a6e1b283c4201343a20ad233d",
            "PAD_REACHABLE_GEOMETRY_ELEMENT_COUNT=0",
            "PIMIDE_REACHABLE_GEOMETRY_ELEMENT_COUNT=0",
            "NOPIM_REACHABLE_GEOMETRY_ELEMENT_COUNT=0",
            "PIMIDE_EVENT_APPLICABILITY_STATUS=NOT_APPLICABLE_NO_REACHABLE_PAD_OR_PIMIDE_GEOMETRY",
            "STRICT_DRY_RUN_PREFLIGHT_RECOMMENDATION=READY_FOR_MANUAL_AUTHORIZATION",
        ):
            self.assertIn(token, text)

    def test_driver_materializes_and_audits_both_variants(self) -> None:
        text = DRIVER.read_text()
        for token in (
            "--variant base",
            "--variant density",
            "--allow-cross-block-control-scaffold",
            "#UNDEFINE DENSITY",
            "#DEFINE DENSITY",
            "#UNDEFINE POPPING",
            "#UNDEFINE PIMIDE",
            "#UNDEFINE DUMMY_FILL",
            "#DEFINE VAR_ANT_RATIO",
            "PVS_DRC_STATUS=DRY_RUN_READY",
            "CROSS_BLOCK_CONTROL_SCAFFOLD_AUTHORIZED=YES",
            "VARIANT_DIFFERENCE_POLICY=DENSITY_SELECTOR_ONLY",
        ):
            self.assertIn(token, text)

    def test_pass_authorizes_only_base_execution_and_not_assembly(self) -> None:
        text = DRIVER.read_text()
        for token in (
            "EVENT_STRICT_DRY_RUN_PREFLIGHT_STATUS=$PREFLIGHT_STATUS",
            "EVENT_PVS_BASE_DRC_EXECUTION_AUTHORIZED=$BASE_EXECUTION_AUTHORIZED",
            "EVENT_PVS_DENSITY_DRC_EXECUTION_AUTHORIZED=NO",
            "PVS_REPLAY_AUTHORIZED=$PVS_REPLAY_AUTHORIZATION",
            "PVS_REPLAY_AUTHORIZATION=BASE_ONLY",
            "PVS_EXECUTED=NO",
            "EVENT_PVS_BASE_DRC_STATUS=NOT_RUN",
            "EVENT_PVS_DENSITY_DRC_STATUS=NOT_RUN",
            "EVENT_PVS_LVS_STATUS=NOT_RUN",
            "ASSEMBLY_INSERTION_AUTHORIZED=NO",
            "ASSEMBLY_BLOCKED_BY=p00_tx,p01_position",
            "FULL_TOP_PNR_AUTHORIZED=NO",
            "BLOCK_PROMOTION_AUTHORIZED=NO",
            "SIGNOFF_READY=NO",
            "NEXT_GATE=RUN_EVENT_PVS_BASE_DRC_ON_EXACT_STAGED_GDS",
        ):
            self.assertIn(token, text)

    def test_snapshot_preserves_staging_boundary(self) -> None:
        status = (SNAPSHOT / "status" / "event_handoff_staging_status.rpt").read_text()
        qualification = (SNAPSHOT / "status" / "qualification.rpt").read_text()
        source = (SNAPSHOT / "reports" / "lvs_source_preparation_summary.rpt").read_text()
        for token in (
            "STATUS=PASS",
            "OUTCOME_CLASS=ATTRIBUTABLE_CANDIDATE_PACKAGE",
            "EVENT_IMMUTABLE_HANDOFF_STAGING_STATUS=PASS",
            "EVENT_PVS_PREFLIGHT_AUTHORIZED=YES",
            "PVS_EXECUTED=NO",
            "ASSEMBLY_INSERTION_AUTHORIZED=NO",
        ):
            self.assertIn(token, status)
        self.assertIn("PACKAGE_STATUS=CANDIDATE", qualification)
        self.assertIn("PVS_BASE_DRC_STATUS=NOT_RUN", qualification)
        self.assertIn("PIN_PARITY_STATUS=PASS", source)
        self.assertIn("SOURCE_TOP_PORT_COUNT=65", source)
        self.assertIn("LEF_PIN_COUNT=65", source)
        self.assertIn("UNRESOLVED_MASTER_COUNT=0", source)

    def test_shell_syntax(self) -> None:
        for script in (DRIVER, HANDOFF):
            result = subprocess.run(
                ["bash", "-n", str(script)],
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
