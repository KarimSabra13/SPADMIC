#!/usr/bin/env python3

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
ANALYZER = (
    REPO
    / "TOP"
    / "pnr"
    / "scripts"
    / "analyze_tx_packet_min_area_second_pass_trial.py"
)
HEAD = "driver-head"
NETS = ("n_9677", "n_9693", "n_9696", "n_9697", "n_9706", "n_9721")
HEADER = (
    "idx\tmarker_handle\tbox\tllx\tlly\turx\tury\tcx\tcy\t"
    "layer\ttype\tsubType\tmessage"
)


class AnalyzeTxPacketMinAreaSecondPassTrialTest(unittest.TestCase):
    def marker_rows(self, count: int) -> list[str]:
        rows: list[str] = []
        for index, net in enumerate(NETS[:count], start=1):
            llx = 100.0 + index
            lly = 200.0 + index
            urx = llx + 0.38
            ury = lly + 0.28
            rows.append(
                f"{index}\th{index}\t{{{llx:.2f} {lly:.2f} {urx:.2f} {ury:.2f}}}\t"
                f"{llx:.2f}\t{lly:.2f}\t{urx:.2f}\t{ury:.2f}\t"
                f"{(llx + urx) / 2:.6f}\t{(lly + ury) / 2:.6f}\t"
                "MET1\tGeometry\tMinimal_Area\t"
                f"Regular Wire of Net {net} Actual: 0.10640000 Required: 0.20200000 "
                "Type: Minimum Area"
            )
        return rows

    def write_verify(self, path: Path, count: int) -> None:
        path.write_text(f"Verification Complete : {count} Viols.  0 Wrngs.\n")

    def write_fixture(
        self,
        root: Path,
        *,
        final_count: int = 0,
        sequence: str = "6 3 0",
        iteration_count: int = 2,
    ) -> tuple[Path, Path]:
        trial_root = root / "trial"
        reports = trial_root / "reports"
        reports.mkdir(parents=True)
        step17 = root / "step17.rpt"
        step17.write_text(
            "STATUS=PASS\n"
            "RESULT=BLOCKERS_CLASSIFIED\n"
            "PHYSICAL_CANDIDATE_STATUS=PG_AND_REGULAR_CLOSED_FINAL_REPAIR_REQUIRED\n"
            "FINAL_DRC_STATUS=FAIL\n"
            "REGULAR_CONNECTIVITY_STATUS=PASS\n"
            "PG_CONNECTIVITY_STATUS=PASS\n"
            "PG_PROBLEM_COUNT=0\n"
            "MIN_AREA_REPAIR_EFFECT=REDUCED_10_TO_6\n"
            "MIN_AREA_PRE_MARKER_COUNT=10\n"
            "MIN_AREA_POST_MARKER_COUNT=6\n"
            "MIN_AREA_FINAL_MARKER_COUNT=6\n"
            f"MIN_AREA_FINAL_NETS={' '.join(NETS)}\n"
            "ANTENNA_FINAL_MARKER_COUNT=177\n"
            "STREAM_PIN_TARGET_STATUS=CANONICAL_TARGETS_PRESERVED\n"
            "STREAM_PIN_COMMAND_MAPPING_DECISION="
            "REMOVE_NEGATIVE_COMPENSATION_KEEP_CANONICAL_CENTERS\n"
            "PVS_DECISION=DO_NOT_RUN\n"
        )
        (trial_root / "context.rpt").write_text(
            "SOURCE_CHECKPOINT=/immutable/checkpoints/05_postroute_export.enc.dat\n"
            f"STEP17_ANALYSIS={step17}\n"
            f"HEAD={HEAD}\n"
            "POLICY=ONE_FRESH_PROCESS_ONE_RESTORE_IN_MEMORY_TRIAL\n"
            "ITERATION_LIMIT=3\n"
            "SOURCE_CHECKPOINT_WRITE=NOT_RUN\n"
            "SAVE_DESIGN=NOT_RUN\n"
            "EXPORT=NOT_RUN\n"
        )
        (reports / "min_area_second_pass_trial_commands.rpt").write_text(
            "LABEL=SPADMIC_OOC_MIN_AREA_SECOND_PASS_TRIAL_COMMANDS\n"
            "POLICY=BOUNDED_SELECTED_NET_EXISTING_REPAIR_SEQUENCE\n"
            f"DRC_COUNT_SEQUENCE={sequence}\n"
        )

        pre_drc = reports / "verify_drc_pre_trial.rpt"
        pre_regular = reports / "verify_connectivity_regular_pre_trial.rpt"
        pre_special = reports / "verify_connectivity_special_pre_trial.rpt"
        final_drc = reports / f"verify_drc_iteration_{iteration_count}.rpt"
        final_regular = (
            reports / f"verify_connectivity_regular_iteration_{iteration_count}.rpt"
        )
        final_special = (
            reports / f"verify_connectivity_special_iteration_{iteration_count}.rpt"
        )
        final_markers = reports / f"drc_markers_iteration_{iteration_count}.tsv"
        self.write_verify(pre_drc, 6)
        self.write_verify(pre_regular, 0)
        self.write_verify(pre_special, 0)
        self.write_verify(final_drc, final_count)
        self.write_verify(final_regular, 0)
        self.write_verify(final_special, 0)
        (reports / "drc_markers_pre_trial.tsv").write_text(
            HEADER + "\n" + "\n".join(self.marker_rows(6)) + "\n"
        )
        final_lines = self.marker_rows(final_count)
        final_markers.write_text(
            HEADER + "\n" + ("\n".join(final_lines) + "\n" if final_lines else "")
        )

        validated = final_count == 0
        process_status = "PASS" if validated else "FAIL"
        process_result = (
            "ITERATIVE_MIN_AREA_REPAIR_VALIDATED"
            if validated
            else "ITERATIVE_MIN_AREA_REPAIR_NO_IMPROVEMENT"
        )
        (reports / "min_area_second_pass_trial_status.rpt").write_text(
            f"STATUS={process_status}\n"
            f"RESULT={process_result}\n"
            "POLICY=ONE_FRESH_PROCESS_ONE_RESTORE_IN_MEMORY_TRIAL\n"
            "DESIGN_MODIFICATION=IN_MEMORY_ONLY\n"
            "SOURCE_CHECKPOINT_WRITE=NOT_RUN\n"
            "SAVE_DESIGN=NOT_RUN\n"
            "EXPORT=NOT_RUN\n"
            "RESTORE_DESIGN=PASS\n"
            "ITERATION_LIMIT=3\n"
            "SOURCE_CHECKPOINT=/immutable/checkpoints/05_postroute_export.enc.dat\n"
            f"STEP17_ANALYSIS={step17}\n"
            "PRE_DRC_VIOLATION_COUNT=6\n"
            "PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "PRE_DRC_MARKER_COUNT=6\n"
            "PRE_EXCLUDED_ANTENNA_MARKER_COUNT=177\n"
            "PRE_MARKER_DATABASE_TOTAL=183\n"
            "PRE_EXCLUDED_CONNECTIVITY_MARKER_COUNT=0\n"
            f"FINAL_DRC_VIOLATION_COUNT={final_count}\n"
            "FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=0\n"
            f"FINAL_DRC_MARKER_COUNT={final_count}\n"
            "FINAL_EXCLUDED_ANTENNA_MARKER_COUNT=177\n"
            f"FINAL_MARKER_DATABASE_TOTAL={177 + final_count}\n"
            "FINAL_EXCLUDED_CONNECTIVITY_MARKER_COUNT=0\n"
            "COMMAND_PASS_COUNT=16\n"
            "COMMAND_FAIL_COUNT=0\n"
            f"ITERATION_COUNT={iteration_count}\n"
            f"DRC_COUNT_SEQUENCE={sequence}\n"
            f"FINAL_DRC_MARKER_REPORT={final_markers}\n"
            f"FINAL_DRC_REPORT={final_drc}\n"
            f"FINAL_REGULAR_CONNECTIVITY_REPORT={final_regular}\n"
            f"FINAL_SPECIAL_CONNECTIVITY_REPORT={final_special}\n"
        )
        return trial_root, step17

    def run_analyzer(self, trial_root: Path, step17: Path) -> tuple[int, str]:
        report = trial_root.parent / "analysis.rpt"
        result = subprocess.run(
            [
                "python3",
                str(ANALYZER),
                "--trial-root",
                str(trial_root),
                "--step17-analysis",
                str(step17),
                "--report-driver-head",
                HEAD,
                "--report",
                str(report),
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
        return result.returncode, report.read_text()

    def test_accepts_zero_drc_with_zero_connectivity(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            trial_root, step17 = self.write_fixture(Path(tmp))
            rc, report = self.run_analyzer(trial_root, step17)
            self.assertEqual(rc, 0, report)
            self.assertIn("STATUS=PASS", report)
            self.assertIn("RESULT=ITERATIVE_MIN_AREA_TRIAL_CLASSIFIED", report)
            self.assertIn("METHOD_STATUS=VALIDATED_ZERO_DRC_ZERO_CONNECTIVITY", report)
            self.assertIn("DRC_COUNT_SEQUENCE=6 3 0", report)
            self.assertIn(
                "NEXT_METHOD_DECISION=AUTHORIZE_FRESH_RERUN_WITH_ITERATIVE_REPAIR_AND_ZERO_PIN_COMPENSATION",
                report,
            )

    def test_classifies_coherent_no_improvement_as_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            trial_root, step17 = self.write_fixture(
                Path(tmp), final_count=6, sequence="6 6", iteration_count=1
            )
            rc, report = self.run_analyzer(trial_root, step17)
            self.assertEqual(rc, 0, report)
            self.assertIn("STATUS=PASS", report)
            self.assertIn("METHOD_STATUS=REJECTED_OR_INCOMPLETE", report)
            self.assertIn("TRIAL_PROCESS_RESULT=ITERATIVE_MIN_AREA_REPAIR_NO_IMPROVEMENT", report)

    def test_fails_when_required_trial_artifact_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            trial_root, step17 = self.write_fixture(Path(tmp))
            (trial_root / "reports" / "drc_markers_pre_trial.tsv").unlink()
            rc, report = self.run_analyzer(trial_root, step17)
            self.assertEqual(rc, 8, report)
            self.assertIn("STATUS=FAIL", report)
            self.assertIn("missing_required_artifact=", report)

    def test_fails_when_verify_report_disagrees_with_status(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            trial_root, step17 = self.write_fixture(Path(tmp))
            self.write_verify(
                trial_root / "reports" / "verify_drc_iteration_2.rpt", 1
            )
            rc, report = self.run_analyzer(trial_root, step17)
            self.assertEqual(rc, 8, report)
            self.assertIn("STATUS=FAIL", report)
            self.assertIn("final_drc_report_status_mismatch=1,0", report)


if __name__ == "__main__":
    unittest.main()
