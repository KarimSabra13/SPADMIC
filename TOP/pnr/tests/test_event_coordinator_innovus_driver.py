#!/usr/bin/env python3
"""Regression checks for the hash-bound Event Innovus transaction."""

from __future__ import annotations

import subprocess
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
DRIVER = REPO / "TOP" / "ci" / "server_run_event_coordinator_innovus.sh"
GENUS_SNAPSHOT = (
    REPO
    / "TOP"
    / "docs"
    / "server_snapshots"
    / "genus"
    / "genus_ooc_event_coordinator_20260720_163038"
)
POSITION_REVIEW_SNAPSHOT = (
    REPO
    / "TOP"
    / "docs"
    / "server_snapshots"
    / "pvs_lvs"
    / "position_lvs_match_review_20260720_163037"
)


class EventCoordinatorInnovusDriverTests(unittest.TestCase):
    def test_driver_is_foreground_and_runs_one_event_hardening_process(self) -> None:
        text = DRIVER.read_text()
        self.assertIn("set +e", text)
        self.assertNotIn("set -e", text)
        self.assertNotIn("nohup", text)
        self.assertNotIn("tail -f", text)
        self.assertNotIn("watch ", text)
        self.assertEqual(text.count("bash TOP/pnr/scripts/run_innovus_ooc_harden_block.sh"), 1)
        self.assertIn("event_coordinator", text)
        self.assertIn('PIPE_RCS=("${PIPESTATUS[@]}")', text)
        self.assertIn('EVENT_INNOVUS_RC="${PIPE_RCS[0]}"', text)
        self.assertIn('EVENT_CONSOLE_TEE_RC="${PIPE_RCS[1]}"', text)
        self.assertIn("git diff --quiet\n", text)
        self.assertIn("git diff --cached --quiet\n", text)

    def test_driver_pins_exact_event_genus_identity(self) -> None:
        text = DRIVER.read_text()
        for token in (
            "genus_ooc_event_coordinator_20260720_163038",
            "b53b1fade963c6c57c6b0629ae9a4b21fdac06db",
            "b28454211dc5eeda84f17cc5864adcd1c15cd761a9d825e3f5a78182fe0b0ccb",
            "c32e0a54b392017256a790ec73352d7161093c73a4360fe933083c88f7d1cb6a",
            "CLOCK_REGISTER_COUNT=51",
            "TOP_PORT_COUNT=63",
            "EXPECTED_BASE_PORT_COUNT=30",
            "ACTUAL_BASE_PORT_COUNT=30",
            "EXPECTED_BIT_PORT_COUNT=63",
            "ACTUAL_BIT_PORT_COUNT=63",
            "WNS_PS=2143.7",
            "VIOLATING_PATH_COUNT=0",
        ):
            self.assertIn(token, text)

    def test_driver_revalidates_genus_without_mutating_source_gate(self) -> None:
        text = DRIVER.read_text()
        self.assertIn("validate_genus_tc_ooc.py", text)
        self.assertIn("tc_ooc_gate.revalidated.rpt", text)
        self.assertNotIn(
            '--status "$EVENT_GENUS_ROOT/reports/timing/tc_ooc_gate.rpt"',
            text,
        )
        self.assertIn("SHA256SUMS.pre_execution", text)
        self.assertIn("SHA256SUMS.post_execution_check.rpt", text)
        self.assertIn('for FILE in "${SOURCE_FILES[@]}"', text)
        self.assertIn("SOURCE_POST_RECHECK_RC", text)

    def test_driver_keeps_physical_and_signoff_gates_separate(self) -> None:
        text = DRIVER.read_text()
        for token in (
            "RESULT=ABSTRACT_READY_FOR_TOP_REVIEW",
            "TOP_RESERVATION_FIT_STATUS=PASS",
            "ACTUAL_DIE_WIDTH_UM=237.440",
            "ACTUAL_DIE_HEIGHT_UM=219.520",
            "INNOVUS_DRC_STATUS=PASS",
            "DRC_MARKER_TOTAL=0",
            "REGULAR_CONNECTIVITY_STATUS=PASS",
            "PG_CONNECTIVITY_STATUS=PASS",
            "POSTROUTE_SETUP_TIMING=PASS",
            "POSTROUTE_HOLD_TIMING=PASS",
            "GDS_LAYER_MAP_STATUS=PASS",
            "GDS_MERGE_STATUS=PASS",
            "RUN_ARTIFACT_HASH_GATE_RC",
            "OUTCOME_CLASS=ATTRIBUTABLE_ABSTRACT_READY",
            "EVENT_PVS_BASE_DRC_STATUS=NOT_RUN",
            "EVENT_PVS_DENSITY_DRC_STATUS=NOT_RUN",
            "EVENT_PVS_LVS_STATUS=NOT_RUN",
            "ASSEMBLY_PHASE=p02_event_control",
            "ASSEMBLY_INSERTION_AUTHORIZED=NO",
            "ASSEMBLY_BLOCKED_BY=p00_tx,p01_position",
            "FULL_TOP_PNR_AUTHORIZED=NO",
            "BLOCK_PROMOTION_AUTHORIZED=NO",
            "SIGNOFF_READY=NO",
            "NEXT_GATE=REVIEW_AND_STAGE_IMMUTABLE_EVENT_HANDOFF",
        ):
            self.assertIn(token, text)

    def test_driver_creates_copy_evidence_and_diagnostic_manifest(self) -> None:
        text = DRIVER.read_text()
        for token in (
            "event_innovus_execution_status.rpt",
            "artifact_hashes.rpt",
            "source_genus/tc_ooc_gate.rpt",
            "SOURCE_SHA_MANIFEST_CREATE_RC",
            "run_evidence/ooc_harden_status.rpt",
            "run_evidence/gds_export_audit.rpt",
            "run_evidence/report_timing_post_route.rpt",
            "run_evidence/ooc_block_harden_config.tcl",
            "run_evidence/ooc_harden_input_manifest.csv",
            "run_evidence/ooc_block_pin_plan.csv",
            "DIAGNOSTIC_MANIFEST_CREATE_RC",
            "SHA256SUMS",
        ):
            self.assertIn(token, text)

    def test_diagnostic_copy_failure_cannot_retain_pass_classification(self) -> None:
        text = DRIVER.read_text()
        self.assertIn("MISSING_OR_UNREADABLE_COPY_SOURCE", text)
        copy_gate = 'if [ "$DIAGNOSTIC_COPY_GATE_RC" != "0" ]; then'
        self.assertIn(copy_gate, text)
        correction = text.split(copy_gate, maxsplit=1)[1].split("fi", maxsplit=1)[0]
        self.assertIn("TRANSACTION_STATUS=FAIL", correction)
        self.assertIn("EVENT_HANDOFF_STAGE_AUTHORIZED=NO", correction)

    def test_snapshots_preserve_the_two_accepted_gate_tuples(self) -> None:
        genus = (
            GENUS_SNAPSHOT
            / "event_coordinator"
            / "reports"
            / "timing"
            / "tc_ooc_gate.rpt"
        ).read_text()
        position = (
            POSITION_REVIEW_SNAPSHOT
            / "status"
            / "position_pvs_lvs_match_review_status.rpt"
        ).read_text()
        for token in (
            "STATUS=PASS",
            "RESULT=READY_FOR_ISOLATED_INNOVUS_OOC",
            "BOUNDARY_PORT_STATUS=PASS",
            "WNS_PS=2143.7",
            "POSTSYN_NETLIST_SHA256=b28454211dc5eeda84f17cc5864adcd1c15cd761a9d825e3f5a78182fe0b0ccb",
        ):
            self.assertIn(token, genus)
        for token in (
            "STATUS=PASS",
            "OUTCOME_CLASS=ATTRIBUTABLE_MATCH",
            "PVS_LVS_STATUS=MATCH",
            "RUN_CONTROL_GATE_RC=0",
            "PVS_DENSITY_DRC_STATUS=FAIL",
            "EVENT_OOC_START_AUTHORIZED=YES",
        ):
            self.assertIn(token, position)

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
