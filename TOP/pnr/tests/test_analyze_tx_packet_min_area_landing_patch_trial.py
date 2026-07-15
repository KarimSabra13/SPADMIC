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
    / "analyze_tx_packet_min_area_landing_patch_trial.py"
)
HEAD = "landing-patch-driver-head"
NETS = ("n_9677", "n_9693", "n_9696", "n_9697", "n_9706", "n_9721")
CONTRACT = {
    "n_9696": ("719.69 158.62 720.07 158.90", "719.88", "158.76", "719.32", "g14627__2802/Q", "716.61 159.02"),
    "n_9693": ("210.09 201.74 210.47 202.02", "210.28", "201.88", "209.72", "g14630__8246/Q", "207.01 201.62"),
    "n_9697": ("663.13 192.78 663.51 193.06", "663.32", "192.92", "662.76", "g14626__1617/Q", "660.05 192.66"),
    "n_9677": ("1666.09 201.74 1666.47 202.02", "1666.28", "201.88", "1666.84", "g14646__2398/Q", "1669.55 201.62"),
    "n_9721": ("1792.65 212.38 1793.03 212.66", "1792.84", "212.52", "1792.28", "g14602__8246/Q", "1789.57 212.78"),
    "n_9706": ("1826.81 212.38 1827.19 212.66", "1827.00", "212.52", "1827.56", "g14617__5477/Q", "1830.27 212.78"),
}
POLICY = "ONE_FRESH_PROCESS_ONE_RESTORE_SIX_BOUNDED_MET1_LANDING_EXTENSIONS"
MARKER_HEADER = (
    "idx\tmarker_handle\tbox\tllx\tlly\turx\tury\tcx\tcy\t"
    "layer\ttype\tsubType\tmessage"
)


class AnalyzeTxPacketMinAreaLandingPatchTrialTest(unittest.TestCase):
    def write_verify(self, path: Path, count: int) -> None:
        path.write_text(f"Verification Complete : {count} Viols.  0 Wrngs.\n")

    def marker_rows(self) -> list[str]:
        rows: list[str] = []
        for index, net in enumerate(NETS, start=1):
            box, start_x, start_y, _, _, _ = CONTRACT[net]
            llx, lly, urx, ury = box.split()
            message = (
                f"Regular Wire of Net {net} Actual: 0.10640000 "
                "Required: 0.20200000 Type: Minimum Area"
            )
            rows.append(
                f"{index}\th{index}\t{{{box}}}\t{llx}\t{lly}\t{urx}\t{ury}\t"
                f"{float(start_x):.6f}\t{float(start_y):.6f}\t"
                f"MET1\tGeometry\tMinimal_Area\t{message}"
            )
        return rows

    def write_step20(self, path: Path) -> None:
        path.write_text(
            "STATUS=PASS\n"
            "RESULT=MIN_AREA_LOCAL_GEOMETRY_CLASSIFIED\n"
            "SELECTED_NET_REROUTE_METHOD_STATUS=REJECTED_NO_IMPROVEMENT\n"
            "PRE_DRC_VIOLATION_COUNT=6\n"
            "POST_DRC_VIOLATION_COUNT=6\n"
            "PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "POST_REGULAR_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "POST_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "PRE_EXCLUDED_ANTENNA_MARKER_COUNT=21\n"
            "POST_EXCLUDED_ANTENNA_MARKER_COUNT=21\n"
            "PRE_MARKER_DATABASE_TOTAL=27\n"
            "POST_MARKER_DATABASE_TOTAL=27\n"
            "MARKER_SIGNATURE_STABILITY=PASS_IDENTICAL_BEFORE_AND_AFTER_QUERY_PROBE\n"
            "RESOLVED_NET_COUNT=6\n"
            "WIRE_QUERY_PASS_NET_COUNT=6\n"
            "LOCAL_WIRE_NET_COUNT=6\n"
            "INST_TERM_NET_COUNT=6\n"
            "INST_TERM_ROW_COUNT=12\n"
            "LOCAL_GEOMETRY_CAPTURE_STATUS=PARTIAL_TERMINAL_OR_PIN_SHAPE_COVERAGE\n"
            "DIRECT_GEOMETRY_TRIAL_DECISION=BLOCKED_PENDING_OPERATOR_REVIEW\n"
            "CANONICAL_RERUN_DECISION=BLOCKED_PENDING_LOCAL_GEOMETRY_REVIEW\n"
            "SAVE_DESIGN=NOT_RUN\n"
            "EXPORT=NOT_RUN\n"
            "IMMUTABLE_PVS_STAGING=NOT_RUN\n"
            "PVS_DECISION=DO_NOT_RUN\n"
            "ERROR_COUNT=0\n"
        )

    def write_fixture(
        self,
        root: Path,
        *,
        validated: bool,
        tamper_contract: bool = False,
    ) -> tuple[Path, Path]:
        trial_root = root / "trial"
        reports = trial_root / "reports"
        reports.mkdir(parents=True)
        step20 = root / "step20.rpt"
        self.write_step20(step20)
        (trial_root / "context.rpt").write_text(
            "SOURCE_CHECKPOINT=/immutable/checkpoints/05_postroute_export.enc.dat\n"
            f"STEP20_ANALYSIS={step20}\n"
            f"HEAD={HEAD}\n"
            f"POLICY={POLICY}\n"
            "DESIGN_MODIFICATION=IN_MEMORY_ONLY\n"
            "SOURCE_CHECKPOINT_WRITE=NOT_RUN\n"
            "SAVE_DESIGN=NOT_RUN\n"
            "EXPORT=NOT_RUN\n"
            "PVS=NOT_RUN\n"
        )

        self.write_verify(reports / "verify_drc_pre_trial.rpt", 6)
        self.write_verify(reports / "verify_connectivity_regular_pre_trial.rpt", 0)
        self.write_verify(reports / "verify_connectivity_special_pre_trial.rpt", 0)
        self.write_verify(
            reports / "verify_drc_post_trial.rpt", 0 if validated else 6
        )
        self.write_verify(reports / "verify_connectivity_regular_post_trial.rpt", 0)
        self.write_verify(reports / "verify_connectivity_special_post_trial.rpt", 0)
        marker_text = MARKER_HEADER + "\n" + "\n".join(self.marker_rows()) + "\n"
        (reports / "drc_markers_pre_trial.tsv").write_text(marker_text)
        (reports / "drc_markers_post_trial.tsv").write_text(
            MARKER_HEADER + "\n" if validated else marker_text
        )

        contract_header = (
            "net\tmarker_box\tstart_x\tstart_y\tend_x\tend_y\tlength_um\t"
            "width_um\tsource_q\tsource_q_point\tmarker_status\tvia1_status\t"
            "met2_endpoint_status\tsource_q_status\tinside_source_inst_status\t"
            "contract_status"
        )
        contract_rows = [contract_header]
        for net, values in CONTRACT.items():
            box, start_x, start_y, end_x, source_q, source_point = values
            if tamper_contract and net == "n_9696":
                end_x = "719.31"
            contract_rows.append(
                f"{net}\t{box}\t{start_x}\t{start_y}\t{end_x}\t{start_y}\t"
                f"0.56\t0.28\t{source_q}\t{source_point}\tPASS\tPASS\tPASS\t"
                "PASS\tPASS\tPASS"
            )
        (reports / "min_area_landing_patch_contract.tsv").write_text(
            "\n".join(contract_rows) + "\n"
        )
        command_lines = [
            "LABEL=SPADMIC_OOC_MIN_AREA_LANDING_PATCH_COMMANDS",
            "POLICY=EXACT_SIX_NET_ONE_GRID_MET1_WIRE_EDITOR_EXTENSIONS",
            "PATCH_WIDTH_UM=0.28",
            "PATCH_LENGTH_UM=0.56",
            "CONTRACT_VALIDATED_COUNT=6",
        ]
        for net, values in CONTRACT.items():
            _, start_x, start_y, end_x, source_q, _ = values
            prefix = f"PATCH_{net}"
            command_lines.extend(
                (
                    f"{prefix}_START={start_x} {start_y}",
                    f"{prefix}_END={end_x} {start_y}",
                    f"{prefix}_SOURCE_Q={source_q}",
                    f"{prefix}_SET_EDIT_MODE=setEditMode -nets {net} -shape None "
                    "-force_regular 1 -layer_horizontal MET1 -layer_vertical MET1 "
                    "-snap_to_track_regular 0 -width_horizontal 0.28 "
                    "-width_vertical 0.28",
                    f"{prefix}_APPLIED=YES",
                )
            )
        command_lines.extend(
            (
                "PATCH_ATTEMPTED_COUNT=6",
                "PATCH_APPLIED_COUNT=6",
                "COMMAND_PASS_COUNT=24",
                "COMMAND_FAIL_COUNT=0",
            )
        )
        (reports / "min_area_landing_patch_commands.rpt").write_text(
            "\n".join(command_lines) + "\n"
        )

        final_count = 0 if validated else 6
        final_database = 21 if validated else 27
        final_nets = "" if validated else " ".join(NETS)
        process_status = "PASS" if validated else "FAIL"
        process_result = (
            "SIX_MET1_LANDING_EXTENSIONS_DRC_ZERO_VALIDATED"
            if validated
            else "SIX_MET1_LANDING_EXTENSIONS_NO_IMPROVEMENT"
        )
        (reports / "min_area_landing_patch_trial_status.rpt").write_text(
            "LABEL=SPADMIC_OOC_MIN_AREA_LANDING_PATCH_TRIAL\n"
            f"POLICY={POLICY}\n"
            "DESIGN_MODIFICATION=IN_MEMORY_ONLY\n"
            "SOURCE_CHECKPOINT_WRITE=NOT_RUN\n"
            "SAVE_DESIGN=NOT_RUN\n"
            "EXPORT=NOT_RUN\n"
            "PVS=NOT_RUN\n"
            "RESTORE_DESIGN=PASS\n"
            f"STATUS={process_status}\n"
            f"RESULT={process_result}\n"
            "SOURCE_CHECKPOINT=/immutable/checkpoints/05_postroute_export.enc.dat\n"
            f"STEP20_ANALYSIS={step20}\n"
            "PRE_DRC_VIOLATION_COUNT=6\n"
            "PRE_DRC_MARKER_COUNT=6\n"
            "PRE_MARKER_DATABASE_TOTAL=27\n"
            "PRE_EXCLUDED_ANTENNA_MARKER_COUNT=21\n"
            "PRE_EXCLUDED_CONNECTIVITY_MARKER_COUNT=0\n"
            "PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=0\n"
            f"PRE_MIN_AREA_NETS={' '.join(NETS)}\n"
            f"FINAL_DRC_VIOLATION_COUNT={final_count}\n"
            f"FINAL_DRC_MARKER_COUNT={final_count}\n"
            f"FINAL_MARKER_DATABASE_TOTAL={final_database}\n"
            "FINAL_EXCLUDED_ANTENNA_MARKER_COUNT=21\n"
            "FINAL_EXCLUDED_CONNECTIVITY_MARKER_COUNT=0\n"
            "FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=0\n"
            f"FINAL_MIN_AREA_NETS={final_nets}\n"
            "CONTRACT_VALIDATED_COUNT=6\n"
            "PATCH_ATTEMPTED_COUNT=6\n"
            "PATCH_APPLIED_COUNT=6\n"
            "COMMAND_PASS_COUNT=24\n"
            "COMMAND_FAIL_COUNT=0\n"
        )
        return trial_root, step20

    def run_analyzer(
        self, trial_root: Path, step20: Path, report: Path
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [
                "python3",
                str(ANALYZER),
                "--trial-root",
                str(trial_root),
                "--step20-analysis",
                str(step20),
                "--report-driver-head",
                HEAD,
                "--report",
                str(report),
            ],
            cwd=REPO,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )

    def test_validated_zero_drc_trial_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            trial_root, step20 = self.write_fixture(root, validated=True)
            report = root / "analysis.rpt"
            result = self.run_analyzer(trial_root, step20, report)
            self.assertEqual(result.returncode, 0, result.stdout)
            text = report.read_text()
            self.assertIn("STATUS=PASS", text)
            self.assertIn("RESULT=MIN_AREA_LANDING_PATCH_TRIAL_CLASSIFIED", text)
            self.assertIn("METHOD_STATUS=VALIDATED_ZERO_DRC_ZERO_CONNECTIVITY", text)
            self.assertIn("REMOVED_MARKER_SIGNATURE_COUNT=6", text)
            self.assertIn("PVS_DECISION=DO_NOT_RUN", text)

    def test_coherent_no_improvement_is_classified_as_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            trial_root, step20 = self.write_fixture(root, validated=False)
            report = root / "analysis.rpt"
            result = self.run_analyzer(trial_root, step20, report)
            self.assertEqual(result.returncode, 0, result.stdout)
            text = report.read_text()
            self.assertIn(
                "TRIAL_PROCESS_RESULT=SIX_MET1_LANDING_EXTENSIONS_NO_IMPROVEMENT",
                text,
            )
            self.assertIn("METHOD_STATUS=REJECTED_OR_INCOMPLETE", text)
            self.assertIn("ADDED_MARKER_SIGNATURE_COUNT=0", text)

    def test_contract_coordinate_drift_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            trial_root, step20 = self.write_fixture(
                root, validated=True, tamper_contract=True
            )
            report = root / "analysis.rpt"
            result = self.run_analyzer(trial_root, step20, report)
            self.assertEqual(result.returncode, 8, result.stdout)
            self.assertIn("contract_n_9696_end_x=719.31 expected=719.32", report.read_text())


if __name__ == "__main__":
    unittest.main()
