#!/usr/bin/env python3

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
ANALYZER = REPO / "TOP" / "pnr" / "scripts" / "analyze_tx_packet_pg_via_drc.py"


class AnalyzeTxPacketPgViaDrcTest(unittest.TestCase):
    def write_fixture(
        self,
        root: Path,
        *,
        post_special: int = 0,
        remove_baseline: bool = False,
        reference_post_drc: int = 25,
    ) -> tuple[Path, Path, Path]:
        trial_root = root / "trial"
        reports = trial_root / "reports"
        reports.mkdir(parents=True)
        analysis = root / "topology.rpt"
        analysis.write_text(
            "STATUS=PASS\n"
            "RESULT=VDD_ROW_COMPONENTS_CLASSIFIED\n"
            "VDD_ROW_1_CENTER_Y_UM=126.560\n"
            "VDD_ROW_2_CENTER_Y_UM=135.520\n"
            "VDD_ROW_3_CENTER_Y_UM=278.880\n"
        )

        common_status = (
            "MODE=via-only\n"
            "SOURCE_CHECKPOINT=/immutable/05_postroute_export.enc.dat\n"
            "TARGET_ROW_COUNT=3\n"
            "COMMAND_PASS_COUNT=4\n"
            "COMMAND_FAIL_COUNT=0\n"
            "PRE_DRC_VIOLATION_COUNT=7\n"
            "PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "POST_REGULAR_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=4\n"
        )
        reference = root / "reference.rpt"
        reference.write_text(
            "STATUS=FAIL\n"
            "RESULT=PG_VIA_METHOD_REJECTED\n"
            + common_status
            + f"POST_DRC_VIOLATION_COUNT={reference_post_drc}\n"
            "POST_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=0\n"
        )
        (reports / "pg_via_trial_status.rpt").write_text(
            "STATUS=FAIL\n"
            "RESULT=PG_VIA_METHOD_REJECTED\n"
            "RESTORE_DESIGN=PASS\n"
            "DESIGN_MODIFICATION=IN_MEMORY_ONLY\n"
            "SOURCE_CHECKPOINT_WRITE=NOT_RUN\n"
            "SAVE_DESIGN=NOT_RUN\n"
            "EXPORT=NOT_RUN\n"
            "PRE_DRC_MARKER_DUMP_STATUS=PASS\n"
            "POST_DRC_MARKER_DUMP_STATUS=PASS\n"
            "PRE_DRC_MARKER_COUNT=7\n"
            "POST_DRC_MARKER_COUNT=25\n"
            + common_status
            + "POST_DRC_VIOLATION_COUNT=25\n"
            f"POST_SPECIAL_CONNECTIVITY_VIOLATION_COUNT={post_special}\n"
        )

        header = (
            "idx\tmarker_handle\tbox\tllx\tlly\turx\tury\tcx\tcy\t"
            "layer\ttype\tsubType\tmessage"
        )
        baseline = [
            f"{index}\th{index}\t{{{index}.0 100.0 {index}.2 100.2}}\t{index}.0\t100.0\t{index}.2\t100.2\t{index}.1\t100.1\tMET1\tGeometry\tMinimal_Area\tn_{index}"
            for index in range(1, 8)
        ]
        pre_rows = baseline[1:] if remove_baseline else baseline
        (reports / "drc_markers_pre_trial.tsv").write_text(
            header + "\n" + "\n".join(pre_rows) + "\n"
        )

        introduced: list[str] = []
        classes = (
            [("MET2", "Short")] * 6
            + [("MET2", "MetSpc")] * 2
            + [("VIA2", "CShort")] * 3
            + [("VIA2", "CutSpc")]
            + [("MET3", "Short")] * 6
        )
        row_centers = (126.560, 135.520, 278.880)
        for offset, (layer, subtype) in enumerate(classes, start=8):
            cy = row_centers[(offset - 8) % 3]
            introduced.append(
                f"{offset}\th{offset}\t{{516.0 {cy - 0.1:.3f} 517.0 {cy + 0.1:.3f}}}\t"
                f"516.0\t{cy - 0.1:.3f}\t517.0\t{cy + 0.1:.3f}\t516.5\t{cy:.3f}\t"
                f"{layer}\tGeometry\t{subtype}\tnew marker {offset}"
            )
        (reports / "drc_markers_post_trial.tsv").write_text(
            header + "\n" + "\n".join(baseline + introduced) + "\n"
        )
        return trial_root, analysis, reference

    def run_analyzer(
        self, trial_root: Path, analysis: Path, reference: Path
    ) -> tuple[subprocess.CompletedProcess[str], str]:
        report = trial_root.parent / "analysis.rpt"
        result = subprocess.run(
            [
                "python3",
                str(ANALYZER),
                "--trial-root",
                str(trial_root),
                "--analysis-report",
                str(analysis),
                "--reference-status",
                str(reference),
                "--report",
                str(report),
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
        return result, report.read_text()

    def test_classifies_exact_eighteen_marker_delta(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            trial_root, analysis, reference = self.write_fixture(Path(tmp))
            result, report = self.run_analyzer(trial_root, analysis, reference)
            self.assertEqual(result.returncode, 0, result.stdout)
            self.assertIn("STATUS=PASS", report)
            self.assertIn("RESULT=DIRECT_STACK_DRC_MARKERS_CLASSIFIED", report)
            self.assertIn("DRC_MARKER_DELTA=18", report)
            self.assertIn("NEW_DRC_MARKER_COUNT=18", report)
            self.assertIn("REMOVED_BASELINE_MARKER_COUNT=0", report)
            self.assertIn("NEW_MARKER_LAYER_COUNTS=MET2:8 MET3:6 VIA2:4", report)
            self.assertIn("PATCH_STACK_DECISION=DO_NOT_RUN", report)
            self.assertIn("ERROR_COUNT=0", report)

    def test_fails_when_replay_does_not_match_reference(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            trial_root, analysis, reference = self.write_fixture(
                Path(tmp), reference_post_drc=24
            )
            result, report = self.run_analyzer(trial_root, analysis, reference)
            self.assertEqual(result.returncode, 8, result.stdout)
            self.assertIn("STATUS=FAIL", report)
            self.assertIn("REFERENCE_REPLAY_COUNT_CONSISTENCY=FAIL", report)

    def test_fails_when_special_connectivity_remains_open(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            trial_root, analysis, reference = self.write_fixture(Path(tmp), post_special=1)
            result, report = self.run_analyzer(trial_root, analysis, reference)
            self.assertEqual(result.returncode, 8, result.stdout)
            self.assertIn("trial_POST_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=1 expected=0", report)

    def test_fails_when_baseline_marker_set_is_not_preserved(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            trial_root, analysis, reference = self.write_fixture(Path(tmp), remove_baseline=True)
            result, report = self.run_analyzer(trial_root, analysis, reference)
            self.assertEqual(result.returncode, 8, result.stdout)
            self.assertIn("pre TSV rows 6 do not match marker count 7", report)


if __name__ == "__main__":
    unittest.main()
