#!/usr/bin/env python3

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
ANALYZER = (
    REPO / "TOP" / "pnr" / "scripts" / "analyze_tx_packet_postfiller_stage_probe.py"
)
FILLERS = (
    "FEED25JIHD FEED15JIHD FEED10JIHD FEED7JIHD "
    "FEED5JIHD FEED3JIHD FEED2JIHD FEED1JIHD"
)
FILLER_COMMAND = f"addFiller -cell {{{FILLERS}}} -prefix FILL"
MARKER_HEADER = (
    "idx\tmarker_handle\tbox\tllx\tlly\turx\tury\tcx\tcy\t"
    "layer\ttype\tsubType\tmessage\n"
)


class AnalyzeTxPacketPostfillerStageProbeTest(unittest.TestCase):
    def marker_rows(self, count: int) -> str:
        rows = [MARKER_HEADER]
        for index in range(1, count + 1):
            llx = 100.0 + index
            urx = llx + 0.28
            rows.append(
                f"{index}\t0x{index:x}\t{{{llx:.2f} 10.00 {urx:.2f} 10.28}}\t"
                f"{llx:.2f}\t10.00\t{urx:.2f}\t10.28\t{(llx + urx) / 2:.6f}\t"
                f"10.140000\tMET2\tGeometry\tMetal_Short\tfixture marker {index}\n"
            )
        return "".join(rows)

    def write_fixture(
        self,
        root: Path,
        *,
        post_cts_drc: int = 0,
        post_cts_special: int = 156,
        post_filler_drc: int = 0,
        post_filler_special: int = 156,
        post_filler_regular: int = 0,
        report_post_filler_drc: int | None = None,
    ) -> tuple[Path, Path, Path]:
        probe_root = root / "probe"
        reports = probe_root / "reports"
        reports.mkdir(parents=True)
        source_block = "/source/run/blocks/tx_packet_core"
        checkpoint = f"{source_block}/checkpoints/03_cts.enc.dat"
        (probe_root / "context.rpt").write_text(
            f"SOURCE_ROOT={source_block}\n"
            "SOURCE_RUN_HEAD=source-head\n"
            f"SOURCE_CHECKPOINT={checkpoint}\n"
            "REPORT_DRIVER_HEAD=driver-head\n"
            "POLICY=ONE_FRESH_PROCESS_ONE_RESTORE_POST_CTS_FILLER_STAGE_ATTRIBUTION\n"
            "DESIGN_MODIFICATION=IN_MEMORY_FILLER_ONLY\n"
            "POST_FILLER_SROUTE=NOT_RUN\n"
            "SOURCE_CHECKPOINT_WRITE=NOT_RUN\n"
            "SAVE_DESIGN=NOT_RUN\n"
            "EXPORT=NOT_RUN\n"
            "PVS=NOT_RUN\n"
            f"FILLER_CELLS={FILLERS}\n"
            f"FILLER_COMMAND={FILLER_COMMAND}\n"
        )
        step13 = root / "step13.rpt"
        step13.write_text(
            "STATUS=PASS\n"
            "RESULT=PREROUTE_PG_CANDIDATE_CLASSIFIED\n"
            f"BLOCK_ROOT={source_block}\n"
            "RUN_HEAD=source-head\n"
            "CANDIDATE_PHYSICAL_STATUS=REJECTED_POST_FILLER_RESTITCH_MILESTONE\n"
            "PRE_CTS_SPECIAL_CONNECTIVITY_STATUS=EXPECTED_DANGLING_ONLY\n"
            "PRE_CTS_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=156\n"
            "PRE_CTS_IMPVFC_94_DANGLING_COUNT=156\n"
            "PRE_CTS_OTHER_PROBLEM_COUNT=0\n"
            "PRE_CTS_DRC_STATUS=PASS\n"
            "PRE_CTS_DRC_VIOLATION_COUNT=0\n"
            "POST_FILLER_RESTITCH_ENABLED=YES\n"
            "POST_FILLER_SROUTE_STATUS=PASS\n"
            "POST_FILLER_SPECIAL_CONNECTIVITY_STATUS=PASS\n"
            "POST_FILLER_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "POST_FILLER_DRC_STATUS=FAIL\n"
            "POST_FILLER_DRC_VIOLATION_COUNT=165\n"
        )

        status_lines = [
            "LABEL=SPADMIC_OOC_POSTFILLER_STAGE_PROBE",
            "POLICY=ONE_FRESH_PROCESS_ONE_RESTORE_POST_CTS_FILLER_STAGE_ATTRIBUTION",
            "STATUS=PASS",
            "RESULT=POSTFILLER_STAGE_EVIDENCE_CAPTURED",
            "RESTORE_DESIGN=PASS",
            "DESIGN_MODIFICATION=IN_MEMORY_FILLER_ONLY",
            "POST_FILLER_SROUTE=NOT_RUN",
            "SOURCE_CHECKPOINT_WRITE=NOT_RUN",
            "SAVE_DESIGN=NOT_RUN",
            "EXPORT=NOT_RUN",
            "PVS=NOT_RUN",
            "FILLER_MODE_STATUS=PASS",
            "ADD_FILLER_STATUS=PASS",
            f"ADD_FILLER_COMMAND={FILLER_COMMAND}",
            f"SOURCE_CHECKPOINT={checkpoint}",
        ]
        stage_values = (
            ("POST_CTS", post_cts_drc, post_cts_special, 0),
            (
                "POST_FILLER_PRE_RESTITCH",
                post_filler_drc,
                post_filler_special,
                post_filler_regular,
            ),
        )
        for prefix, drc, special, regular in stage_values:
            status_lines.extend(
                (
                    f"{prefix}_DRC_CAPTURE_STATUS=PASS",
                    f"{prefix}_DRC_MARKER_DUMP_STATUS=PASS",
                    f"{prefix}_SPECIAL_CONNECTIVITY_CAPTURE_STATUS=PASS",
                    f"{prefix}_REGULAR_CONNECTIVITY_CAPTURE_STATUS=PASS",
                    f"{prefix}_DRC_VIOLATION_COUNT={drc}",
                    f"{prefix}_DRC_MARKER_COUNT={drc}",
                    f"{prefix}_MARKER_DATABASE_TOTAL={drc}",
                    f"{prefix}_EXCLUDED_ANTENNA_MARKER_COUNT=0",
                    f"{prefix}_EXCLUDED_CONNECTIVITY_MARKER_COUNT=0",
                    f"{prefix}_SPECIAL_CONNECTIVITY_VIOLATION_COUNT={special}",
                    f"{prefix}_REGULAR_CONNECTIVITY_VIOLATION_COUNT={regular}",
                )
            )
        (reports / "postfiller_stage_probe_status.rpt").write_text(
            "\n".join(status_lines) + "\n"
        )
        (reports / "postfiller_stage_probe_commands.rpt").write_text(
            "LABEL=SPADMIC_OOC_POSTFILLER_STAGE_PROBE_COMMANDS\n"
            "FILLER_MODE_STATUS=PASS\n"
            "FILLER_MODE_COMMAND=setFillerMode -add_fillers_with_drc false\n"
            "ADD_FILLER_STATUS=PASS\n"
            f"ADD_FILLER_COMMAND={FILLER_COMMAND}\n"
            "POST_FILLER_SROUTE=NOT_RUN\n"
        )
        (reports / "drc_markers_post_cts_pre_filler.tsv").write_text(
            self.marker_rows(post_cts_drc)
        )
        (reports / "drc_markers_post_filler_pre_restitch.tsv").write_text(
            self.marker_rows(post_filler_drc)
        )

        report_counts = {
            "verify_drc_post_cts_pre_filler.rpt": post_cts_drc,
            "verify_connectivity_special_post_cts_pre_filler.rpt": post_cts_special,
            "verify_connectivity_regular_post_cts_pre_filler.rpt": 0,
            "verify_drc_post_filler_pre_restitch.rpt": (
                post_filler_drc
                if report_post_filler_drc is None
                else report_post_filler_drc
            ),
            "verify_connectivity_special_post_filler_pre_restitch.rpt": post_filler_special,
            "verify_connectivity_regular_post_filler_pre_restitch.rpt": post_filler_regular,
        }
        for name, count in report_counts.items():
            (reports / name).write_text(f"Verification Complete : {count} Viols.  0 Wrngs.\n")
        return probe_root, step13, root / "analysis.rpt"

    def run_analyzer(self, probe_root: Path, step13: Path, report: Path) -> tuple[int, str]:
        result = subprocess.run(
            [
                "python3",
                str(ANALYZER),
                "--probe-root",
                str(probe_root),
                "--step13-analysis",
                str(step13),
                "--report",
                str(report),
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
        return result.returncode, report.read_text()

    def test_attributes_clean_pre_restitch_state_to_sroute_when_pg_still_open(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            fixture = self.write_fixture(Path(tmp))
            rc, report = self.run_analyzer(*fixture)
            self.assertEqual(rc, 0, report)
            self.assertIn("STATUS=PASS", report)
            self.assertIn("STAGE_ATTRIBUTION=POST_FILLER_SROUTE_INTRODUCES_DRC", report)
            self.assertIn(
                "POST_FILLER_RESTITCH_ELECTRICAL_NECESSITY=REQUIRED_FOR_SPECIAL_CONNECTIVITY",
                report,
            )
            self.assertIn(
                "NEXT_METHOD_DECISION=DESIGN_BOUNDED_DRC_SAFE_POST_FILLER_STITCH_METHOD",
                report,
            )

    def test_marks_restitch_redundant_when_pre_restitch_connectivity_is_zero(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            fixture = self.write_fixture(Path(tmp), post_filler_special=0)
            rc, report = self.run_analyzer(*fixture)
            self.assertEqual(rc, 0, report)
            self.assertIn(
                "POST_FILLER_RESTITCH_ELECTRICAL_NECESSITY=NOT_REQUIRED_CONNECTIVITY_ALREADY_ZERO",
                report,
            )
            self.assertIn(
                "NEXT_METHOD_DECISION=OMIT_REDUNDANT_POST_FILLER_SROUTE_IN_NEXT_FRESH_CANDIDATE",
                report,
            )

    def test_attributes_new_marker_set_to_filler_stage(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            fixture = self.write_fixture(Path(tmp), post_filler_drc=2)
            rc, report = self.run_analyzer(*fixture)
            self.assertEqual(rc, 0, report)
            self.assertIn("STAGE_ATTRIBUTION=FILLER_STAGE_INTRODUCES_DRC", report)
            self.assertIn("FILLER_NEW_DRC_MARKER_COUNT=2", report)
            self.assertIn("FILLER_NEW_MARKER_LAYER_COUNTS=MET2:2", report)

    def test_fails_when_status_and_raw_report_counts_disagree(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            fixture = self.write_fixture(Path(tmp), report_post_filler_drc=1)
            rc, report = self.run_analyzer(*fixture)
            self.assertEqual(rc, 8, report)
            self.assertIn("STATUS=FAIL", report)
            self.assertIn(
                "probe_POST_FILLER_PRE_RESTITCH_DRC_VIOLATION_COUNT=0 report=1",
                report,
            )


if __name__ == "__main__":
    unittest.main()
