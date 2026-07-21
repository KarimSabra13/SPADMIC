#!/usr/bin/env python3
"""Regression checks for immutable Event coordinator handoff staging."""

from __future__ import annotations

import subprocess
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
DRIVER = REPO / "TOP" / "ci" / "server_stage_event_coordinator_handoff.sh"
SNAPSHOT = (
    REPO
    / "TOP"
    / "docs"
    / "server_snapshots"
    / "innovus"
    / "innovus_ooc_harden_event_coordinator_20260720_173527"
)


class EventCoordinatorHandoffStagingTests(unittest.TestCase):
    def test_driver_is_staging_only_and_refuses_replacement(self) -> None:
        text = DRIVER.read_text()
        self.assertIn("set +e", text)
        self.assertNotIn("set -e", text)
        self.assertNotIn("nohup", text)
        self.assertNotIn("tail -f", text)
        self.assertNotIn("watch ", text)
        self.assertNotIn("run_pvs_drc_handoff.sh", text)
        self.assertNotIn("run_pvs_lvs_handoff.sh", text)
        self.assertEqual(text.count("python3 TOP/pnr/scripts/stage_innovus_handoff.py"), 1)
        self.assertEqual(text.count("python3 TOP/pnr/scripts/audit_innovus_handoff.py"), 1)
        self.assertIn('if [ -e "$PACKAGE" ]; then', text)
        self.assertIn("STOP_HERE_DO_NOT_OVERWRITE", text)
        self.assertIn("SOURCE_MUTATION_AUTHORIZED=NO", text)

    def test_driver_pins_exact_source_diagnostic_and_artifacts(self) -> None:
        text = DRIVER.read_text()
        for token in (
            "event_innovus_execution_20260720_173527",
            "innovus_ooc_harden_event_coordinator_20260720_173527",
            "genus_ooc_event_coordinator_20260720_163038",
            "1b922f0723112e5916107775069c767388ec500e",
            "b53b1fade963c6c57c6b0629ae9a4b21fdac06db",
            "837538f219dacc9521f02bc58b3e2e5e587f859b4e70b69a1ca4a3e5fe7b6857",
            "56345986a887317f0374984b1ea8b3442ea482aeec0572614e9fd2c0b6732a14",
            "f9d6a927c7cecad40916cac67b8142f6fb6c6b013e3d57ab779889fd0ab21a68",
            "0ecc571317f6beaa13c7f006ac3ecc4f1ff2a72b9655a176c0fa21e3c0a07398",
            "b28454211dc5eeda84f17cc5864adcd1c15cd761a9d825e3f5a78182fe0b0ccb",
            "c32e0a54b392017256a790ec73352d7161093c73a4360fe933083c88f7d1cb6a",
            "5ff10b0b31003da9bb6db59eba7d52c82435e3ab68b2ba0a1956e4d9fbaef8cf",
        ):
            self.assertIn(token, text)

    def test_driver_requires_attributable_physical_tuple(self) -> None:
        text = DRIVER.read_text()
        for token in (
            "SOURCE_DIAGNOSTIC_MANIFEST_RC",
            "SOURCE_COPY_IDENTITY_GATE_RC",
            "SOURCE_POST_RECHECK_RC",
            "OUTCOME_CLASS=ATTRIBUTABLE_ABSTRACT_READY",
            "ACTUAL_DIE_WIDTH_UM=237.440",
            "ACTUAL_DIE_HEIGHT_UM=219.520",
            "TOP_RESERVATION_WIDTH_MARGIN_UM=0.020",
            "TOP_RESERVATION_HEIGHT_MARGIN_UM=0.480",
            "DRC_MARKER_TOTAL=0",
            "REGULAR_CONNECTIVITY_STATUS=PASS",
            "PG_CONNECTIVITY_STATUS=PASS",
            "POSTROUTE_SETUP_TIMING=PASS",
            "POSTROUTE_HOLD_TIMING=PASS",
            "GDS_LAYER_MAP_STATUS=PASS",
            "GDS_MERGE_STATUS=PASS",
        ):
            self.assertIn(token, text)

    def test_driver_audits_package_without_claiming_pvs_or_promotion(self) -> None:
        text = DRIVER.read_text()
        for token in (
            "spadmic_event_coordinator.innovus.pg.v",
            "spadmic_event_coordinator.lvs.pg.v",
            "LVS_SOURCE_PREPARATION_STATUS=PASS",
            "PIN_PARITY_STATUS=PASS",
            "STDCELL_CDL_STATUS=PASS",
            "EVENT_IMMUTABLE_HANDOFF_STAGING_STATUS=PASS",
            "OUTCOME_CLASS=ATTRIBUTABLE_CANDIDATE_PACKAGE",
            "EVENT_PVS_BASE_DRC_STATUS=NOT_RUN",
            "EVENT_PVS_DENSITY_DRC_STATUS=NOT_RUN",
            "EVENT_PVS_LVS_STATUS=NOT_RUN",
            "PVS_EXECUTED=NO",
            "EVENT_PVS_PREFLIGHT_AUTHORIZED=YES",
            "ASSEMBLY_INSERTION_AUTHORIZED=NO",
            "ASSEMBLY_BLOCKED_BY=p00_tx,p01_position",
            "FULL_TOP_PNR_AUTHORIZED=NO",
            "BLOCK_PROMOTION_AUTHORIZED=NO",
            "SIGNOFF_READY=NO",
            "NEXT_GATE=PREPARE_EVENT_PVS_BASE_DRC_STRICT_PREFLIGHT",
        ):
            self.assertIn(token, text)

    def test_snapshot_preserves_event_innovus_acceptance(self) -> None:
        status = (SNAPSHOT / "status" / "event_innovus_execution_status.rpt").read_text()
        physical = (
            SNAPSHOT / "event_coordinator" / "reports" / "ooc_harden_status.rpt"
        ).read_text()
        hashes = (
            SNAPSHOT / "event_coordinator" / "reports" / "artifact_hashes.rpt"
        ).read_text()
        for token in (
            "STATUS=PASS",
            "OUTCOME_CLASS=ATTRIBUTABLE_ABSTRACT_READY",
            "EVENT_INNOVUS_OOC_STATUS=PASS",
            "EVENT_HANDOFF_STAGE_AUTHORIZED=YES",
            "EVENT_PVS_BASE_DRC_STATUS=NOT_RUN",
            "ASSEMBLY_INSERTION_AUTHORIZED=NO",
        ):
            self.assertIn(token, status)
        for token in (
            "TOP_RESERVATION_FIT_STATUS=PASS",
            "DRC_MARKER_TOTAL=0",
            "REGULAR_CONNECTIVITY_STATUS=PASS",
            "PG_CONNECTIVITY_STATUS=PASS",
            "POSTROUTE_SETUP_TIMING=PASS",
            "POSTROUTE_HOLD_TIMING=PASS",
        ):
            self.assertIn(token, physical)
        self.assertIn(
            "GDS_SHA256=837538f219dacc9521f02bc58b3e2e5e587f859b4e70b69a1ca4a3e5fe7b6857",
            hashes,
        )

    def test_shell_syntax(self) -> None:
        result = subprocess.run(
            ["bash", "-n", str(DRIVER)],
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_embedded_manifest_auditor_is_valid_python(self) -> None:
        text = DRIVER.read_text()
        embedded = text.split("python3 -c '\n", maxsplit=1)[1].split(
            "\n' \"$PACKAGE_JSON\"", maxsplit=1
        )[0]
        compile(embedded, str(DRIVER), "exec")


if __name__ == "__main__":
    unittest.main()
