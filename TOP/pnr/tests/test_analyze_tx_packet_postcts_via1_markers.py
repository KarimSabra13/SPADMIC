#!/usr/bin/env python3

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
ANALYZER = REPO / "TOP" / "pnr" / "scripts" / "analyze_tx_packet_postcts_via1_markers.py"
MARKER_HEADER = (
    "idx\tmarker_handle\tbox\tllx\tlly\turx\tury\tcx\tcy\t"
    "layer\ttype\tsubType\tmessage\n"
)


class AnalyzeTxPacketPostctsVia1MarkersTest(unittest.TestCase):
    def marker_rows(
        self,
        *,
        handle_offset: int = 0,
        changed_last: bool = False,
        last_layer: str = "VIA1",
    ) -> str:
        rows = [MARKER_HEADER]
        for index in range(1, 1001):
            llx = 10.0 + (index % 100) * 0.56
            lly = 10.0 + (index // 100) * 8.96
            urx = llx + 0.26
            ury = lly + 0.26
            layer = last_layer if index == 1000 else "VIA1"
            suffix = " changed" if changed_last and index == 1000 else ""
            message = (
                f"Regular Via of Net CTS_{index % 10} & Special Wire of Net VDD "
                "Actual: 0.140000 Required: 0.260000 Type: Same Layer Cut Spacing "
                f"# fixture {index}{suffix}"
            )
            rows.append(
                f"{index}\t0x{index + handle_offset:x}\t"
                f"{{{llx:.2f} {lly:.2f} {urx:.2f} {ury:.2f}}}\t"
                f"{llx:.2f}\t{lly:.2f}\t{urx:.2f}\t{ury:.2f}\t"
                f"{(llx + urx) / 2:.6f}\t{(lly + ury) / 2:.6f}\t"
                f"{layer}\tGeometry\tCut_Spacing\t{message}\n"
            )
        return "".join(rows)

    @staticmethod
    def verify_report(count: int, layer: str | None = None) -> str:
        lines = [f"Verification Complete : {count} Viols.  0 Wrngs."]
        if layer is not None:
            lines.extend(
                (
                    "Violation Summary By Layer and Type:",
                    "             CutSpc   Totals",
                    f"{layer:<8} {count:8d} {count:8d}",
                    f"Totals   {count:8d} {count:8d}",
                    "*** End Verify DRC",
                )
            )
        return "\n".join(lines) + "\n"

    def write_fixture(
        self,
        root: Path,
        *,
        changed_last: bool = False,
        last_layer: str = "VIA1",
    ) -> tuple[Path, Path, Path, Path, Path]:
        probe_root = root / "probe"
        probe_reports = probe_root / "reports"
        block_root = root / "run" / "blocks" / "tx_packet_core"
        block_reports = block_root / "reports"
        probe_reports.mkdir(parents=True)
        block_reports.mkdir(parents=True)
        (probe_root / "context.rpt").write_text(
            f"SOURCE_ROOT={block_root}\n"
            "SOURCE_RUN_HEAD=step13-head\n"
            "SOURCE_CHECKPOINT=/source/checkpoints/03_cts.enc.dat\n"
            "REPORT_DRIVER_HEAD=step14-head\n"
        )
        (probe_reports / "postfiller_stage_probe_status.rpt").write_text(
            "STATUS=PASS\n"
            "RESULT=POSTFILLER_STAGE_EVIDENCE_CAPTURED\n"
            "RESTORE_DESIGN=PASS\n"
            "POST_FILLER_SROUTE=NOT_RUN\n"
            "SOURCE_CHECKPOINT_WRITE=NOT_RUN\n"
            "SAVE_DESIGN=NOT_RUN\n"
            "EXPORT=NOT_RUN\n"
            "PVS=NOT_RUN\n"
            "POST_CTS_DRC_VIOLATION_COUNT=1000\n"
            "POST_CTS_DRC_MARKER_COUNT=1000\n"
            "POST_CTS_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=154\n"
            "POST_CTS_REGULAR_CONNECTIVITY_VIOLATION_COUNT=239\n"
            "POST_FILLER_PRE_RESTITCH_DRC_VIOLATION_COUNT=1000\n"
            "POST_FILLER_PRE_RESTITCH_DRC_MARKER_COUNT=1000\n"
            "POST_FILLER_PRE_RESTITCH_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "POST_FILLER_PRE_RESTITCH_REGULAR_CONNECTIVITY_VIOLATION_COUNT=239\n"
        )
        (probe_reports / "drc_markers_post_cts_pre_filler.tsv").write_text(
            self.marker_rows(last_layer=last_layer)
        )
        (probe_reports / "drc_markers_post_filler_pre_restitch.tsv").write_text(
            self.marker_rows(
                handle_offset=0x10000,
                changed_last=changed_last,
                last_layer=last_layer,
            )
        )
        for name, count, layer in (
            ("verify_drc_post_cts_pre_filler.rpt", 1000, "VIA1"),
            ("verify_drc_post_filler_pre_restitch.rpt", 1000, "VIA1"),
            ("verify_connectivity_special_post_cts_pre_filler.rpt", 154, None),
            ("verify_connectivity_special_post_filler_pre_restitch.rpt", 0, None),
            ("verify_connectivity_regular_post_cts_pre_filler.rpt", 239, None),
            ("verify_connectivity_regular_post_filler_pre_restitch.rpt", 239, None),
        ):
            (probe_reports / name).write_text(self.verify_report(count, layer))

        (block_reports / "PG_POST_FILLER_DRC.rpt").write_text(
            self.verify_report(165, "VIA1")
        )
        (block_reports / "PG_POST_FILLER_CONNECTIVITY.rpt").write_text(
            self.verify_report(0)
        )
        step13 = root / "step13_analysis.rpt"
        step13.write_text(
            "STATUS=PASS\n"
            "RESULT=PREROUTE_PG_CANDIDATE_CLASSIFIED\n"
            f"BLOCK_ROOT={block_root}\n"
            "RUN_HEAD=step13-head\n"
            "POST_FILLER_SPECIAL_CONNECTIVITY_STATUS=PASS\n"
            "POST_FILLER_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "POST_FILLER_DRC_STATUS=FAIL\n"
            "POST_FILLER_DRC_VIOLATION_COUNT=165\n"
        )
        step14 = root / "step14_analysis.rpt"
        step14.write_text(
            "STATUS=PASS\n"
            "RESULT=POSTFILLER_STAGE_ATTRIBUTION_CLASSIFIED\n"
            "REPORT_DRIVER_HEAD=step14-head\n"
            "STAGE_ATTRIBUTION=CTS_STAGE_INTRODUCES_DRC\n"
            "POST_CTS_DRC_VIOLATION_COUNT=1000\n"
            "POST_CTS_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=154\n"
            "POST_CTS_REGULAR_CONNECTIVITY_VIOLATION_COUNT=239\n"
            "POST_FILLER_PRE_RESTITCH_DRC_VIOLATION_COUNT=1000\n"
            "POST_FILLER_PRE_RESTITCH_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "POST_FILLER_PRE_RESTITCH_REGULAR_CONNECTIVITY_VIOLATION_COUNT=239\n"
            "FILLER_DRC_MARKER_DELTA=0\n"
            "FILLER_NEW_DRC_MARKER_COUNT=0\n"
            "FILLER_REMOVED_DRC_MARKER_COUNT=0\n"
            "SAVE_DESIGN=NOT_RUN\n"
            "EXPORT=NOT_RUN\n"
            "IMMUTABLE_PVS_STAGING=NOT_RUN\n"
            "PVS_DECISION=DO_NOT_RUN\n"
        )
        return probe_root, block_root, step13, step14, root / "report.rpt"

    @staticmethod
    def run_analyzer(fixture: tuple[Path, Path, Path, Path, Path]) -> tuple[int, str]:
        probe_root, block_root, step13, step14, report = fixture
        result = subprocess.run(
            [
                "python3",
                str(ANALYZER),
                "--probe-root",
                str(probe_root),
                "--step13-block-root",
                str(block_root),
                "--step13-analysis",
                str(step13),
                "--step14-analysis",
                str(step14),
                "--report-driver-head",
                "step15-head",
                "--report",
                str(report),
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
        return result.returncode, report.read_text()

    def test_classifies_stable_capped_via1_marker_capture(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            fixture = self.write_fixture(Path(tmp))
            rc, report = self.run_analyzer(fixture)
            self.assertEqual(rc, 0, report)
            self.assertIn("STATUS=PASS", report)
            self.assertIn("RESULT=POST_CTS_VIA1_MARKERS_CLASSIFIED", report)
            self.assertIn(
                "POST_CTS_DRC_COUNT_INTERPRETATION=AT_LEAST_1000_EXACT_TOTAL_UNPROVEN",
                report,
            )
            self.assertIn("POST_CTS_MARKER_LAYER_COUNTS=VIA1:1000", report)
            self.assertIn("POST_CTS_MARKER_SUBTYPE_COUNTS=Cut_Spacing:1000", report)
            self.assertIn("POST_CTS_RULE_TEMPLATE_UNIQUE_COUNT=1", report)
            self.assertIn("POST_CTS_REGULAR_NET_UNIQUE_COUNT=10", report)
            self.assertIn("FILLER_DRC_EFFECT=NO_CAPTURED_SIGNATURE_CHANGE", report)
            self.assertIn(
                "FILLER_SPECIAL_CONNECTIVITY_EFFECT=CLOSED_154_TO_0_WITHOUT_SROUTE",
                report,
            )
            self.assertIn(
                "REGULAR_CONNECTIVITY_INTERPRETATION=PRE_SIGNAL_ROUTE_OBSERVATION_NOT_A_FINAL_CONNECTIVITY_GATE",
                report,
            )

    def test_fails_when_filler_changes_one_marker_signature(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            fixture = self.write_fixture(Path(tmp), changed_last=True)
            rc, report = self.run_analyzer(fixture)
            self.assertEqual(rc, 8, report)
            self.assertIn("STATUS=FAIL", report)
            self.assertIn("filler changed marker signatures new=1 removed=1", report)

    def test_fails_when_capture_is_not_exclusively_via1(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            fixture = self.write_fixture(Path(tmp), last_layer="MET1")
            rc, report = self.run_analyzer(fixture)
            self.assertEqual(rc, 8, report)
            self.assertIn("STATUS=FAIL", report)
            self.assertIn("expected=VIA1:1000", report)


if __name__ == "__main__":
    unittest.main()
