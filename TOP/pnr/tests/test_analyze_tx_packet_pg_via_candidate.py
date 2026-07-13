#!/usr/bin/env python3

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
ANALYZER = REPO / "TOP" / "pnr" / "scripts" / "analyze_tx_packet_pg_via_candidate.py"


class AnalyzeTxPacketPgViaCandidateTest(unittest.TestCase):
    def write_fixture(
        self,
        root: Path,
        *,
        new_marker_count: int = 0,
        post_special: int = 0,
        post_regular: int = 0,
        raw_total_adjustment: int = 0,
        force_trial_fail: bool = False,
    ) -> tuple[Path, Path]:
        trial_root = root / "trial"
        reports = trial_root / "reports"
        reports.mkdir(parents=True)
        topology = root / "topology.rpt"
        topology.write_text(
            "STATUS=PASS\n"
            "RESULT=VDD_ROW_COMPONENTS_CLASSIFIED\n"
            "VDD_ROW_1_CENTER_Y_UM=126.560\n"
            "VDD_ROW_2_CENTER_Y_UM=135.520\n"
            "VDD_ROW_3_CENTER_Y_UM=278.880\n"
        )

        post_drc = 7 + new_marker_count
        physically_valid = post_special == 0 and post_regular == 0 and new_marker_count == 0
        trial_status = "PASS" if physically_valid and not force_trial_fail else "FAIL"
        trial_result = (
            "PG_VIA_METHOD_VALIDATED_NOT_CANONICAL"
            if physically_valid and not force_trial_fail
            else "PG_VIA_METHOD_REJECTED"
        )
        post_excluded_connectivity = post_special
        post_database_total = (
            post_drc + 29 + post_excluded_connectivity + raw_total_adjustment
        )
        (reports / "pg_via_trial_status.rpt").write_text(
            f"STATUS={trial_status}\n"
            f"RESULT={trial_result}\n"
            "MODE=via-1x1\n"
            "SOURCE_CHECKPOINT=/immutable/checkpoints/05_postroute_export.enc.dat\n"
            "RESTORE_DESIGN=PASS\n"
            "DESIGN_MODIFICATION=IN_MEMORY_ONLY\n"
            "SOURCE_CHECKPOINT_WRITE=NOT_RUN\n"
            "SAVE_DESIGN=NOT_RUN\n"
            "EXPORT=NOT_RUN\n"
            "VIA_GEN_AREA_ONLY_STATUS=PASS\n"
            "TARGET_ROW_COUNT=3\n"
            "COMMAND_PASS_COUNT=4\n"
            "COMMAND_FAIL_COUNT=0\n"
            "PRE_DRC_VIOLATION_COUNT=7\n"
            f"POST_DRC_VIOLATION_COUNT={post_drc}\n"
            "PRE_DRC_MARKER_DUMP_STATUS=PASS\n"
            "POST_DRC_MARKER_DUMP_STATUS=PASS\n"
            "PRE_DRC_MARKER_COUNT=7\n"
            f"POST_DRC_MARKER_COUNT={post_drc}\n"
            "PRE_MARKER_DATABASE_TOTAL=40\n"
            f"POST_MARKER_DATABASE_TOTAL={post_database_total}\n"
            "PRE_EXCLUDED_ANTENNA_MARKER_COUNT=29\n"
            "POST_EXCLUDED_ANTENNA_MARKER_COUNT=29\n"
            "PRE_EXCLUDED_CONNECTIVITY_MARKER_COUNT=4\n"
            f"POST_EXCLUDED_CONNECTIVITY_MARKER_COUNT={post_excluded_connectivity}\n"
            "PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT=0\n"
            f"POST_REGULAR_CONNECTIVITY_VIOLATION_COUNT={post_regular}\n"
            "PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=4\n"
            f"POST_SPECIAL_CONNECTIVITY_VIOLATION_COUNT={post_special}\n"
        )
        (reports / "pg_via_trial_commands.rpt").write_text(
            "LABEL=SPADMIC_OOC_PG_VIA_TRIAL_COMMANDS\n"
            "MODE=via-1x1\n"
            "TARGET_ROW_COUNT=3\n"
            + "\n".join(
                f"TRY_ROW_{row}_MET1_TO_METTP_STACK=editPowerVia -add_vias 1 -nets VDD "
                "-bottom_layer MET1 -top_layer METTP -exclude_stack_vias 0 "
                f"-area {{{row}.0 1.0 {row}.5 1.5}} -via_rows 1 -via_columns 1"
                for row in range(1, 4)
            )
            + "\n"
        )

        header = (
            "idx\tmarker_handle\tbox\tllx\tlly\turx\tury\tcx\tcy\t"
            "layer\ttype\tsubType\tmessage"
        )
        baseline = [
            f"{index}\th{index}\t{{{index}.0 100.0 {index}.2 100.2}}\t{index}.0\t100.0\t{index}.2\t100.2\t{index}.1\t100.1\tMET1\tGeometry\tMinimal_Area\tn_{index}"
            for index in range(1, 8)
        ]
        introduced: list[str] = []
        row_centers = (126.560, 135.520, 278.880)
        for offset in range(new_marker_count):
            index = 8 + offset
            cy = row_centers[offset % 3]
            introduced.append(
                f"{index}\th{index}\t{{516.0 {cy - 0.1:.3f} 517.0 {cy + 0.1:.3f}}}\t"
                f"516.0\t{cy - 0.1:.3f}\t517.0\t{cy + 0.1:.3f}\t516.5\t{cy:.3f}\t"
                f"MET2\tGeometry\tMetal_Short\tnew marker {index}"
            )
        (reports / "drc_markers_pre_trial.tsv").write_text(
            header + "\n" + "\n".join(baseline) + "\n"
        )
        (reports / "drc_markers_post_trial.tsv").write_text(
            header + "\n" + "\n".join(baseline + introduced) + "\n"
        )
        return trial_root, topology

    def run_analyzer(self, trial_root: Path, topology: Path) -> tuple[int, str]:
        report = trial_root.parent / "candidate.rpt"
        result = subprocess.run(
            [
                "python3",
                str(ANALYZER),
                "--trial-root",
                str(trial_root),
                "--analysis-report",
                str(topology),
                "--expected-mode",
                "via-1x1",
                "--report",
                str(report),
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
        return result.returncode, report.read_text()

    def test_accepts_zero_connectivity_and_no_drc_increase(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            trial_root, topology = self.write_fixture(Path(tmp))
            rc, report = self.run_analyzer(trial_root, topology)
            self.assertEqual(rc, 0, report)
            self.assertIn("STATUS=PASS", report)
            self.assertIn("RESULT=PG_VIA_CANDIDATE_CLASSIFIED", report)
            self.assertIn("CANDIDATE_PHYSICAL_STATUS=VALIDATED_NOT_CANONICAL", report)
            self.assertIn("CANDIDATE_DRC_STATUS=PASS_NO_INCREASE", report)
            self.assertIn("NEW_DRC_MARKER_COUNT=0", report)
            self.assertIn("CANONICAL_RERUN_DECISION=BLOCKED_PENDING_REVIEW", report)

    def test_classifies_coherent_new_drc_rejection(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            trial_root, topology = self.write_fixture(Path(tmp), new_marker_count=3)
            rc, report = self.run_analyzer(trial_root, topology)
            self.assertEqual(rc, 0, report)
            self.assertIn("CANDIDATE_PHYSICAL_STATUS=REJECTED_NEW_DRC", report)
            self.assertIn("DRC_MARKER_DELTA=3", report)
            self.assertIn("NEW_DRC_MARKER_COUNT=3", report)
            self.assertIn("NEW_MARKER_LAYER_COUNTS=MET2:3", report)

    def test_classifies_remaining_special_connectivity(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            trial_root, topology = self.write_fixture(Path(tmp), post_special=1)
            rc, report = self.run_analyzer(trial_root, topology)
            self.assertEqual(rc, 0, report)
            self.assertIn("CANDIDATE_PHYSICAL_STATUS=REJECTED_SPECIAL_CONNECTIVITY", report)
            self.assertIn("POST_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=1", report)

    def test_fails_on_raw_marker_accounting_mismatch(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            trial_root, topology = self.write_fixture(Path(tmp), raw_total_adjustment=1)
            rc, report = self.run_analyzer(trial_root, topology)
            self.assertEqual(rc, 8, report)
            self.assertIn("STATUS=FAIL", report)
            self.assertIn("post marker database filter accounting does not balance", report)

    def test_fails_when_trial_status_disagrees_with_physical_tuple(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            trial_root, topology = self.write_fixture(Path(tmp), force_trial_fail=True)
            rc, report = self.run_analyzer(trial_root, topology)
            self.assertEqual(rc, 8, report)
            self.assertIn("trial_STATUS=FAIL expected=PASS", report)
            self.assertIn(
                "trial_RESULT=PG_VIA_METHOD_REJECTED expected=PG_VIA_METHOD_VALIDATED_NOT_CANONICAL",
                report,
            )


if __name__ == "__main__":
    unittest.main()
