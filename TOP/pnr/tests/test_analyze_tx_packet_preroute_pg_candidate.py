#!/usr/bin/env python3

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
ANALYZER = REPO / "TOP" / "pnr" / "scripts" / "analyze_tx_packet_preroute_pg_candidate.py"
AREAS = (
    "515.200 126.160 518.560 126.960",
    "515.200 135.120 518.560 135.920",
    "515.200 278.480 518.560 279.280",
)


class AnalyzeTxPacketPreroutePgCandidateTest(unittest.TestCase):
    def write_fixture(
        self,
        root: Path,
        *,
        pre_connectivity: int = 0,
        final_drc: str = "PASS",
        min_area_count: int = 0,
        manifest_areas: str | None = None,
    ) -> Path:
        run_root = root / "run"
        block_root = run_root / "blocks" / "tx_packet_core"
        reports = block_root / "reports"
        reports.mkdir(parents=True)
        area_value = manifest_areas or " ".join(f"{{{area}}}" for area in AREAS)
        (run_root / "run_manifest.txt").write_text(
            "HEAD=driver-head\n"
            "SPADMIC_OOC_ENABLE_PRE_CTS_PG_DIRECT_VIAS=1\n"
            f"SPADMIC_OOC_PG_DIRECT_VIA_AREAS={area_value}\n"
            "SPADMIC_OOC_ENABLE_PG_SROUTE=1\n"
            "SPADMIC_OOC_SIGNAL_BOTTOM_LAYER=MET1\n"
            "SPADMIC_OOC_SIGNAL_TOP_LAYER=MET3\n"
        )
        pre_status = "PASS" if pre_connectivity == 0 else "FAIL"
        final_fields = ""
        if pre_connectivity == 0:
            final_fields = (
                f"INNOVUS_DRC_STATUS={final_drc}\n"
                "REGULAR_CONNECTIVITY_STATUS=PASS\n"
                "PG_CONNECTIVITY_STATUS=PASS\n"
            )
        (reports / "ooc_harden_status.rpt").write_text(
            "PG_ROUTE_STAGE=PRE_CTS\n"
            "PG_DIRECT_VIA_STACKS=PASS\n"
            f"PG_DIRECT_VIA_PRE_CTS_CONNECTIVITY_STATUS={pre_status}\n"
            "PG_DIRECT_VIA_PRE_CTS_DRC_STATUS=PASS\n"
            + final_fields
            + (
                "RESULT=ABSTRACT_READY_FOR_TOP_REVIEW\n"
                if final_drc == "PASS" and pre_connectivity == 0
                else "RESULT=INNOVUS_TC_OOC_REVIEW_REQUIRED\n"
            )
        )
        stack_lines = [
            "LABEL=SPADMIC_OOC_PRE_CTS_PG_DIRECT_VIAS",
            "POLICY=AFTER_PLACE_BEFORE_CTS_BOUNDED_1X1_STACKS",
            "TARGET_AREA_COUNT=3",
            "BOTTOM_LAYER=MET1",
            "TOP_LAYER=METTP",
            "VIA_ROWS=1",
            "VIA_COLUMNS=1",
            "VIA_GEN_AREA_ONLY_STATUS=PASS",
        ]
        for row, area in enumerate(AREAS, start=1):
            stack_lines.extend(
                (
                    f"ROW_{row}_AREA={area}",
                    f"TRY_ROW_{row}_MET1_TO_METTP_STACK=editPowerVia -add_vias 1 -nets VDD "
                    "-bottom_layer MET1 -top_layer METTP -exclude_stack_vias 0 "
                    f"-area {{{area}}} -via_rows 1 -via_columns 1",
                    f"ROW_{row}_MET1_TO_METTP_STACK_STATUS=PASS",
                )
            )
        stack_lines.extend(
            (
                "TRY_VIA_GEN_AREA_ONLY_RESET=setViaGenMode -area_only 0",
                "VIA_GEN_AREA_ONLY_RESET_STATUS=PASS",
                "COMMAND_PASS_COUNT=5",
                "COMMAND_FAIL_COUNT=0",
                "STATUS=PASS",
            )
        )
        (reports / "PG_DIRECT_VIA_STACKS.rpt").write_text("\n".join(stack_lines) + "\n")
        (reports / "PG_DIRECT_VIA_PRE_CTS_CONNECTIVITY.rpt").write_text(
            f"Verification Complete : {pre_connectivity} Viols.  0 Wrngs.\nSTATUS=PASS\n"
        )
        (reports / "PG_DIRECT_VIA_PRE_CTS_DRC.rpt").write_text(
            "Verification Complete : 0 Viols.\nSTATUS=PASS\n"
        )
        if pre_connectivity == 0:
            (reports / "DRC_MARKER_CLASSIFICATION.rpt").write_text(
                f"MET1_MIN_AREA_MARKER_COUNT={min_area_count}\n"
                "ANTENNA_MARKER_COUNT=29\n"
                "EXPECTED_PG_CONNECTIVITY_MARKER_COUNT=0\n"
                "OTHER_MARKER_COUNT=0\n"
            )
            gate_pass = final_drc == "PASS"
            (reports / "canonical_tx_ooc_gate.rpt").write_text(
                f"STATUS={'PASS' if gate_pass else 'FAIL'}\n"
                f"RESULT={'READY_FOR_PVS_CANDIDATE' if gate_pass else 'REVIEW_REQUIRED'}\n"
                f"ERROR_COUNT={0 if gate_pass else 1}\n"
                "SETUP_WNS_NS=0.100\n"
                "HOLD_WNS_NS=0.100\n"
            )
            for name in (
                "verify_drc_post_route.rpt",
                "verify_connectivity_regular.rpt",
                "verify_connectivity_pg.rpt",
            ):
                (reports / name).write_text("STATUS=PASS\n")
        return block_root

    def run_analyzer(self, block_root: Path) -> tuple[int, str]:
        report = block_root.parents[1] / "analysis.rpt"
        result = subprocess.run(
            [
                "python3",
                str(ANALYZER),
                "--block-root",
                str(block_root),
                "--report",
                str(report),
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
        return result.returncode, report.read_text()

    def test_classifies_clean_candidate_for_pvs_preflight_review(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            block_root = self.write_fixture(Path(tmp))
            rc, report = self.run_analyzer(block_root)
            self.assertEqual(rc, 0, report)
            self.assertIn("STATUS=PASS", report)
            self.assertIn("CANDIDATE_PHYSICAL_STATUS=READY_FOR_PVS_PREFLIGHT", report)
            self.assertIn("CANDIDATE_EXPORT_SCOPE=RUN_LOCAL_AND_RUN_ID_HANDOFF_ONLY", report)
            self.assertIn("PVS_DECISION=DO_NOT_RUN_FROM_THIS_STEP", report)

    def test_classifies_pg_closed_with_only_min_area_remaining(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            block_root = self.write_fixture(Path(tmp), final_drc="FAIL", min_area_count=7)
            rc, report = self.run_analyzer(block_root)
            self.assertEqual(rc, 0, report)
            self.assertIn("CANDIDATE_PHYSICAL_STATUS=PG_CLOSED_MIN_AREA_REMAINS", report)
            self.assertIn("FINAL_MET1_MIN_AREA_MARKER_COUNT=7", report)
            self.assertIn(
                "NEXT_METHOD_DECISION=STOP_PG_EXPERIMENTS_REPAIR_SEVEN_MET1_MIN_AREA_MARKERS",
                report,
            )

    def test_classifies_pre_cts_connectivity_rejection_without_final_outputs(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            block_root = self.write_fixture(Path(tmp), pre_connectivity=1)
            rc, report = self.run_analyzer(block_root)
            self.assertEqual(rc, 0, report)
            self.assertIn("CANDIDATE_PHYSICAL_STATUS=REJECTED_PRE_CTS_MILESTONE", report)
            self.assertIn("PRE_CTS_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=1", report)

    def test_fails_on_manifest_area_mismatch(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            block_root = self.write_fixture(Path(tmp), manifest_areas="{0 0 1 1}")
            rc, report = self.run_analyzer(block_root)
            self.assertEqual(rc, 8, report)
            self.assertIn("STATUS=FAIL", report)
            self.assertIn("manifest_SPADMIC_OOC_PG_DIRECT_VIA_AREAS", report)

    def test_fails_when_command_report_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            block_root = self.write_fixture(Path(tmp))
            (block_root / "reports" / "PG_DIRECT_VIA_STACKS.rpt").unlink()
            rc, report = self.run_analyzer(block_root)
            self.assertEqual(rc, 8, report)
            self.assertIn("RESULT=MISSING_REQUIRED_INPUTS", report)


if __name__ == "__main__":
    unittest.main()
