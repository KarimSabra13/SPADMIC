#!/usr/bin/env python3

from __future__ import annotations

import hashlib
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
CONTRACT_R2 = {
    **CONTRACT,
    "n_9696": ("719.69 158.62 720.07 158.90", "719.88", "158.76", "719.04", "g14627__2802/Q", "716.61 159.02"),
    "n_9693": ("210.09 201.74 210.47 202.02", "210.28", "201.88", "209.44", "g14630__8246/Q", "207.01 201.62"),
    "n_9697": ("663.13 192.78 663.51 193.06", "663.32", "192.92", "662.48", "g14626__1617/Q", "660.05 192.66"),
    "n_9677": ("1666.09 201.74 1666.47 202.02", "1666.28", "201.88", "1667.12", "g14646__2398/Q", "1669.55 201.62"),
}
CONTRACT_R3 = {
    **CONTRACT,
    "n_9696": ("719.69 158.62 720.07 158.90", "719.88", "158.76", "720.72", "g14627__2802/Q", "716.61 159.02"),
    "n_9693": ("210.09 201.74 210.47 202.02", "210.28", "201.88", "211.12", "g14630__8246/Q", "207.01 201.62"),
    "n_9697": ("663.13 192.78 663.51 193.06", "663.32", "192.92", "664.16", "g14626__1617/Q", "660.05 192.66"),
    "n_9677": ("1666.09 201.74 1666.47 202.02", "1666.28", "201.88", "1665.44", "g14646__2398/Q", "1669.55 201.62"),
}
R2_LONG_NETS = {"n_9677", "n_9693", "n_9696", "n_9697"}
R3_AWAY_NETS = {"n_9677", "n_9693", "n_9696", "n_9697"}
R4_WIDE_NETS = {"n_9677", "n_9693", "n_9696", "n_9697"}
POLICY = "ONE_FRESH_PROCESS_ONE_RESTORE_SIX_BOUNDED_MET1_LANDING_EXTENSIONS"
POLICY_R2 = (
    "ONE_FRESH_PROCESS_ONE_RESTORE_SIX_BOUNDED_MIXED_LENGTH_MET1_LANDING_EXTENSIONS"
)
POLICY_R3 = (
    "ONE_FRESH_PROCESS_ONE_RESTORE_SIX_BOUNDED_MIXED_DIRECTION_MET1_LANDING_EXTENSIONS"
)
POLICY_R4 = (
    "ONE_FRESH_PROCESS_ONE_RESTORE_SIX_BOUNDED_MIXED_WIDTH_MET1_LANDING_EXTENSIONS"
)
POLICY_R5 = (
    "ONE_FRESH_PROCESS_ONE_RESTORE_R4_REPLAY_WITH_LOCAL_WIRE_MATERIALIZATION_CAPTURE"
)
MARKER_HEADER = (
    "idx\tmarker_handle\tbox\tllx\tlly\turx\tury\tcx\tcy\t"
    "layer\ttype\tsubType\tmessage"
)
WIRE_HEADER = (
    "phase\tnet\tmarker_box\trequested_width_um\twire_index\twire_handle\t"
    "local_relation\tbox_status\tbox\tlayer_status\tlayer\t"
    "route_status_status\troute_status\tshape_status\tshape\twidth_status\t"
    "width\tlength_status\tlength\tpts_status\tpts"
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
            "LABEL=SPADMIC_TX_PACKET_MIN_AREA_GEOMETRY_ANALYSIS\n"
            "POLICY=READ_ONLY_RESTORED_CHECKPOINT_LOCAL_TOPOLOGY_CLASSIFICATION\n"
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

    def write_step21(self, path: Path) -> None:
        path.write_text(
            "LABEL=SPADMIC_TX_PACKET_MIN_AREA_LANDING_PATCH_ANALYSIS\n"
            "POLICY=ISOLATED_IN_MEMORY_SIX_NET_MET1_LANDING_PATCH_CLASSIFICATION\n"
            "STATUS=PASS\n"
            "RESULT=MIN_AREA_LANDING_PATCH_TRIAL_CLASSIFIED\n"
            "TRIAL_PROCESS_STATUS=FAIL\n"
            "TRIAL_PROCESS_RESULT=SIX_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED\n"
            "METHOD_STATUS=REJECTED_OR_INCOMPLETE\n"
            "PATCH_CONTRACT_STATUS=PASS_EXACT_SIX_REVIEWED_EXTENSIONS\n"
            "PATCH_WIDTH_UM=0.28\n"
            "PATCH_LENGTH_UM=0.56\n"
            "PATCH_ATTEMPTED_COUNT=6\n"
            "PATCH_APPLIED_COUNT=6\n"
            "COMMAND_PASS_COUNT=24\n"
            "COMMAND_FAIL_COUNT=0\n"
            "PRE_DRC_VIOLATION_COUNT=6\n"
            "FINAL_DRC_VIOLATION_COUNT=4\n"
            "PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "PRE_EXCLUDED_ANTENNA_MARKER_COUNT=21\n"
            "FINAL_EXCLUDED_ANTENNA_MARKER_COUNT=21\n"
            "PRE_MARKER_DATABASE_TOTAL=27\n"
            "FINAL_MARKER_DATABASE_TOTAL=25\n"
            "REMOVED_MARKER_SIGNATURE_COUNT=6\n"
            "ADDED_MARKER_SIGNATURE_COUNT=4\n"
            "FINAL_MIN_AREA_NETS=n_9677 n_9693 n_9696 n_9697\n"
            "SAVE_DESIGN=NOT_RUN\n"
            "EXPORT=NOT_RUN\n"
            "IMMUTABLE_PVS_STAGING=NOT_RUN\n"
            "PVS_DECISION=DO_NOT_RUN\n"
            "CANONICAL_RERUN_DECISION=DO_NOT_RUN_FROM_THIS_STEP\n"
            "NEXT_METHOD_DECISION=STOP_AND_REVIEW_PATCH_EVIDENCE_BEFORE_NEW_METHOD\n"
            "ERROR_COUNT=0\n"
        )

    def write_step22(self, path: Path) -> None:
        path.write_text(
            "LABEL=SPADMIC_TX_PACKET_MIN_AREA_LANDING_PATCH_ANALYSIS\n"
            "POLICY=ISOLATED_IN_MEMORY_SIX_NET_MIXED_LENGTH_MET1_LANDING_PATCH_CLASSIFICATION\n"
            "STATUS=PASS\n"
            "RESULT=MIN_AREA_LANDING_PATCH_TRIAL_CLASSIFIED\n"
            "TRIAL_REVISION=R2\n"
            "TRIAL_PROCESS_STATUS=FAIL\n"
            "TRIAL_PROCESS_RESULT=MIXED_LENGTH_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED\n"
            "METHOD_STATUS=REJECTED_OR_INCOMPLETE\n"
            "PATCH_CONTRACT_STATUS=PASS_EXACT_SIX_MIXED_LENGTH_EXTENSIONS\n"
            "PATCH_WIDTH_UM=0.28\n"
            "PATCH_LENGTH_POLICY=FOUR_SURVIVORS_0.84_TWO_CLOSED_0.56\n"
            "PATCH_LENGTH_UM=MIXED_0.56_0.84\n"
            "PATCH_ATTEMPTED_COUNT=6\n"
            "PATCH_APPLIED_COUNT=6\n"
            "COMMAND_PASS_COUNT=24\n"
            "COMMAND_FAIL_COUNT=0\n"
            "PRE_DRC_VIOLATION_COUNT=6\n"
            "FINAL_DRC_VIOLATION_COUNT=4\n"
            "PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "PRE_EXCLUDED_ANTENNA_MARKER_COUNT=21\n"
            "FINAL_EXCLUDED_ANTENNA_MARKER_COUNT=21\n"
            "PRE_MARKER_DATABASE_TOTAL=27\n"
            "FINAL_MARKER_DATABASE_TOTAL=25\n"
            "REMOVED_MARKER_SIGNATURE_COUNT=6\n"
            "ADDED_MARKER_SIGNATURE_COUNT=4\n"
            "FINAL_MIN_AREA_NETS=n_9677 n_9693 n_9696 n_9697\n"
            "SAVE_DESIGN=NOT_RUN\n"
            "EXPORT=NOT_RUN\n"
            "IMMUTABLE_PVS_STAGING=NOT_RUN\n"
            "PVS_DECISION=DO_NOT_RUN\n"
            "CANONICAL_RERUN_DECISION=DO_NOT_RUN_FROM_THIS_STEP\n"
            "NEXT_METHOD_DECISION=STOP_AND_REVIEW_PATCH_EVIDENCE_BEFORE_NEW_METHOD\n"
            "ERROR_COUNT=0\n"
        )

    def write_step23(self, path: Path) -> None:
        path.write_text(
            "LABEL=SPADMIC_TX_PACKET_MIN_AREA_LANDING_PATCH_ANALYSIS\n"
            "POLICY=ISOLATED_IN_MEMORY_SIX_NET_MIXED_DIRECTION_MET1_LANDING_PATCH_CLASSIFICATION\n"
            "STATUS=PASS\n"
            "RESULT=MIN_AREA_LANDING_PATCH_TRIAL_CLASSIFIED\n"
            "TRIAL_REVISION=R3\n"
            "TRIAL_PROCESS_STATUS=FAIL\n"
            "TRIAL_PROCESS_RESULT=MIXED_DIRECTION_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED\n"
            "METHOD_STATUS=REJECTED_OR_INCOMPLETE\n"
            "PATCH_CONTRACT_STATUS=PASS_EXACT_SIX_MIXED_DIRECTION_EXTENSIONS\n"
            "PATCH_WIDTH_UM=0.28\n"
            "PATCH_LENGTH_POLICY=FOUR_SURVIVORS_0.84_TWO_CLOSED_0.56\n"
            "PATCH_LENGTH_UM=MIXED_0.56_0.84\n"
            "PATCH_DIRECTION_POLICY=FOUR_SURVIVORS_AWAY_FROM_SOURCE_TWO_CLOSED_TOWARD_SOURCE\n"
            "PATCH_ATTEMPTED_COUNT=6\n"
            "PATCH_APPLIED_COUNT=6\n"
            "COMMAND_PASS_COUNT=24\n"
            "COMMAND_FAIL_COUNT=0\n"
            "PRE_DRC_VIOLATION_COUNT=6\n"
            "FINAL_DRC_VIOLATION_COUNT=4\n"
            "PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "PRE_EXCLUDED_ANTENNA_MARKER_COUNT=21\n"
            "FINAL_EXCLUDED_ANTENNA_MARKER_COUNT=21\n"
            "PRE_MARKER_DATABASE_TOTAL=27\n"
            "FINAL_MARKER_DATABASE_TOTAL=25\n"
            "REMOVED_MARKER_SIGNATURE_COUNT=2\n"
            "ADDED_MARKER_SIGNATURE_COUNT=0\n"
            "FINAL_MIN_AREA_NETS=n_9677 n_9693 n_9696 n_9697\n"
            "SAVE_DESIGN=NOT_RUN\n"
            "EXPORT=NOT_RUN\n"
            "IMMUTABLE_PVS_STAGING=NOT_RUN\n"
            "PVS_DECISION=DO_NOT_RUN\n"
            "CANONICAL_RERUN_DECISION=DO_NOT_RUN_FROM_THIS_STEP\n"
            "NEXT_METHOD_DECISION=STOP_AND_REVIEW_PATCH_EVIDENCE_BEFORE_NEW_METHOD\n"
            "ERROR_COUNT=0\n"
        )

    def write_step24(self, path: Path) -> None:
        path.write_text(
            "LABEL=SPADMIC_TX_PACKET_MIN_AREA_LANDING_PATCH_ANALYSIS\n"
            "POLICY=ISOLATED_IN_MEMORY_SIX_NET_MIXED_WIDTH_MET1_LANDING_PATCH_CLASSIFICATION\n"
            "STATUS=PASS\n"
            "RESULT=MIN_AREA_LANDING_PATCH_TRIAL_CLASSIFIED\n"
            "TRIAL_REVISION=R4\n"
            "TRIAL_PROCESS_STATUS=FAIL\n"
            "TRIAL_PROCESS_RESULT=MIXED_WIDTH_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED\n"
            "METHOD_STATUS=REJECTED_OR_INCOMPLETE\n"
            "PATCH_CONTRACT_STATUS=PASS_EXACT_SIX_MIXED_WIDTH_EXTENSIONS\n"
            "PATCH_WIDTH_POLICY=FOUR_SURVIVORS_0.56_TWO_CLOSED_0.28\n"
            "PATCH_WIDTH_UM=MIXED_0.28_0.56\n"
            "PATCH_LENGTH_POLICY=UNIFORM_0.56\n"
            "PATCH_LENGTH_UM=0.56\n"
            "PATCH_DIRECTION_POLICY=ALL_TOWARD_SOURCE\n"
            "PATCH_ATTEMPTED_COUNT=6\n"
            "PATCH_APPLIED_COUNT=6\n"
            "COMMAND_PASS_COUNT=24\n"
            "COMMAND_FAIL_COUNT=0\n"
            "PRE_DRC_VIOLATION_COUNT=6\n"
            "FINAL_DRC_VIOLATION_COUNT=4\n"
            "PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=0\n"
            "PRE_EXCLUDED_ANTENNA_MARKER_COUNT=21\n"
            "FINAL_EXCLUDED_ANTENNA_MARKER_COUNT=21\n"
            "PRE_MARKER_DATABASE_TOTAL=27\n"
            "FINAL_MARKER_DATABASE_TOTAL=25\n"
            "REMOVED_MARKER_SIGNATURE_COUNT=6\n"
            "ADDED_MARKER_SIGNATURE_COUNT=4\n"
            "FINAL_MIN_AREA_NETS=n_9677 n_9693 n_9696 n_9697\n"
            "SAVE_DESIGN=NOT_RUN\n"
            "EXPORT=NOT_RUN\n"
            "IMMUTABLE_PVS_STAGING=NOT_RUN\n"
            "PVS_DECISION=DO_NOT_RUN\n"
            "CANONICAL_RERUN_DECISION=DO_NOT_RUN_FROM_THIS_STEP\n"
            "NEXT_METHOD_DECISION=STOP_AND_REVIEW_PATCH_EVIDENCE_BEFORE_NEW_METHOD\n"
            "ERROR_COUNT=0\n"
        )

    def write_wire_snapshots(
        self, reports: Path, materialization: str
    ) -> tuple[int, int]:
        pre_rows = [WIRE_HEADER]
        post_rows = [WIRE_HEADER]
        for index, net in enumerate(NETS, start=1):
            marker_box, start_x, start_y, end_x, _, _ = CONTRACT[net]
            requested_width = "0.56" if net in R4_WIDE_NETS else "0.28"
            common = (
                f"{net}\t{marker_box}\t{requested_width}\t1\tbase_{net}\t"
                f"INTERSECTS_MARKER\tPASS\t{marker_box}\tPASS\tMET1\t"
                "PASS\trouted\tPASS\tpath\tPASS\t0.28\tPASS\t0.38\t"
                f"PASS\t{{{start_x} {start_y}}}"
            )
            pre_rows.append(f"PRE_EDIT\t{common}")
            post_rows.append(f"POST_EDIT\t{common}")
            if materialization == "none":
                continue
            actual_width = (
                requested_width if materialization == "requested" else "0.28"
            )
            llx = min(float(start_x), float(end_x))
            urx = max(float(start_x), float(end_x))
            half_width = float(actual_width) / 2.0
            lly = float(start_y) - half_width
            ury = float(start_y) + half_width
            added_box = f"{llx:.2f} {lly:.2f} {urx:.2f} {ury:.2f}"
            post_rows.append(
                f"POST_EDIT\t{net}\t{marker_box}\t{requested_width}\t2\t"
                f"added_{index}_{net}\tINTERSECTS_MARKER\tPASS\t{added_box}\t"
                f"PASS\tMET1\tPASS\trouted\tPASS\tpath\tPASS\t{actual_width}\t"
                f"PASS\t0.56\tPASS\t{{{start_x} {start_y}}} "
                f"{{{end_x} {start_y}}}"
            )
        (reports / "wire_snapshot_pre_trial.tsv").write_text(
            "\n".join(pre_rows) + "\n"
        )
        (reports / "wire_snapshot_post_trial.tsv").write_text(
            "\n".join(post_rows) + "\n"
        )
        return len(pre_rows) - 1, len(post_rows) - 1

    def write_fixture(
        self,
        root: Path,
        *,
        validated: bool,
        tamper_contract: bool = False,
        revision: str = "R1",
        materialization: str = "requested",
    ) -> tuple[Path, Path]:
        is_r2 = revision == "R2"
        is_r3 = revision == "R3"
        is_r4 = revision == "R4"
        is_r5 = revision == "R5"
        if materialization not in {"requested", "canonicalized", "none"}:
            raise ValueError(f"unsupported materialization fixture: {materialization}")
        if is_r5:
            contract = CONTRACT
            policy = POLICY_R5
            source_key = "STEP24_ANALYSIS"
            patch_length_policy = "UNIFORM_0.56"
            patch_direction_policy = "ALL_TOWARD_SOURCE"
            patch_width_policy = "FOUR_SURVIVORS_0.56_TWO_CLOSED_0.28"
            patch_width_um = "MIXED_0.28_0.56"
        elif is_r4:
            contract = CONTRACT
            policy = POLICY_R4
            source_key = "STEP23_ANALYSIS"
            patch_length_policy = "UNIFORM_0.56"
            patch_direction_policy = "ALL_TOWARD_SOURCE"
            patch_width_policy = "FOUR_SURVIVORS_0.56_TWO_CLOSED_0.28"
            patch_width_um = "MIXED_0.28_0.56"
        elif is_r3:
            contract = CONTRACT_R3
            policy = POLICY_R3
            source_key = "STEP22_ANALYSIS"
            patch_length_policy = "FOUR_SURVIVORS_0.84_TWO_CLOSED_0.56"
            patch_direction_policy = (
                "FOUR_SURVIVORS_AWAY_FROM_SOURCE_TWO_CLOSED_TOWARD_SOURCE"
            )
            patch_width_policy = "UNIFORM_0.28"
            patch_width_um = "0.28"
        elif is_r2:
            contract = CONTRACT_R2
            policy = POLICY_R2
            source_key = "STEP21_ANALYSIS"
            patch_length_policy = "FOUR_SURVIVORS_0.84_TWO_CLOSED_0.56"
            patch_direction_policy = "ALL_TOWARD_SOURCE"
            patch_width_policy = "UNIFORM_0.28"
            patch_width_um = "0.28"
        else:
            contract = CONTRACT
            policy = POLICY
            source_key = "STEP20_ANALYSIS"
            patch_length_policy = "UNIFORM_0.56"
            patch_direction_policy = "ALL_TOWARD_SOURCE"
            patch_width_policy = "UNIFORM_0.28"
            patch_width_um = "0.28"
        trial_root = root / "trial"
        reports = trial_root / "reports"
        reports.mkdir(parents=True)
        source = root / f"{source_key.lower()}.rpt"
        if is_r5:
            self.write_step24(source)
        elif is_r4:
            self.write_step23(source)
        elif is_r3:
            self.write_step22(source)
        elif is_r2:
            self.write_step21(source)
        else:
            self.write_step20(source)
        source_sha = hashlib.sha256(source.read_bytes()).hexdigest()
        (trial_root / "context.rpt").write_text(
            "SOURCE_CHECKPOINT=/immutable/checkpoints/05_postroute_export.enc.dat\n"
            f"{source_key}={source}\n"
            f"{source_key}_SHA256={source_sha}\n"
            f"HEAD={HEAD}\n"
            f"TRIAL_REVISION={revision}\n"
            f"POLICY={policy}\n"
            "DESIGN_MODIFICATION=IN_MEMORY_ONLY\n"
            "SOURCE_CHECKPOINT_WRITE=NOT_RUN\n"
            "SAVE_DESIGN=NOT_RUN\n"
            "EXPORT=NOT_RUN\n"
            "PVS=NOT_RUN\n"
        )

        post_drc_count = 0 if validated else (4 if is_r5 else 6)
        self.write_verify(reports / "verify_drc_pre_trial.rpt", 6)
        self.write_verify(reports / "verify_connectivity_regular_pre_trial.rpt", 0)
        self.write_verify(reports / "verify_connectivity_special_pre_trial.rpt", 0)
        self.write_verify(reports / "verify_drc_post_trial.rpt", post_drc_count)
        self.write_verify(reports / "verify_connectivity_regular_post_trial.rpt", 0)
        self.write_verify(reports / "verify_connectivity_special_post_trial.rpt", 0)
        marker_text = MARKER_HEADER + "\n" + "\n".join(self.marker_rows()) + "\n"
        (reports / "drc_markers_pre_trial.tsv").write_text(marker_text)
        post_marker_rows = self.marker_rows()[:post_drc_count]
        (reports / "drc_markers_post_trial.tsv").write_text(
            MARKER_HEADER
            + "\n"
            + ("\n".join(post_marker_rows) + "\n" if post_marker_rows else "")
        )

        contract_header = (
            "net\tmarker_box\tstart_x\tstart_y\tend_x\tend_y\tlength_um\t"
            "width_um\tsource_q\tsource_q_point\tdirection\tmarker_status\tvia1_status\t"
            "met2_endpoint_status\tsource_q_status\tinside_source_inst_status\t"
            "contract_status"
        )
        contract_rows = [contract_header]
        for net, values in contract.items():
            box, start_x, start_y, end_x, source_q, source_point = values
            if tamper_contract and net == "n_9696":
                end_x = "720.71" if is_r3 else ("719.03" if is_r2 else "719.31")
            length = (
                "0.84"
                if (is_r2 and net in R2_LONG_NETS)
                or (is_r3 and net in R3_AWAY_NETS)
                else "0.56"
            )
            direction = (
                "AWAY_FROM_SOURCE"
                if is_r3 and net in R3_AWAY_NETS
                else "TOWARD_SOURCE"
            )
            width = (
                "0.56" if (is_r4 or is_r5) and net in R4_WIDE_NETS else "0.28"
            )
            contract_rows.append(
                f"{net}\t{box}\t{start_x}\t{start_y}\t{end_x}\t{start_y}\t"
                f"{length}\t{width}\t{source_q}\t{source_point}\t{direction}\tPASS\tPASS\tPASS\t"
                "PASS\tPASS\tPASS"
            )
        (reports / "min_area_landing_patch_contract.tsv").write_text(
            "\n".join(contract_rows) + "\n"
        )
        command_lines = [
            "LABEL=SPADMIC_OOC_MIN_AREA_LANDING_PATCH_COMMANDS",
            "POLICY="
            + (
                "EXACT_SIX_NET_R4_REPLAY_FOR_WIRE_MATERIALIZATION_CAPTURE"
                if is_r5
                else (
                    "EXACT_SIX_NET_MIXED_WIDTH_MET1_WIRE_EDITOR_EXTENSIONS"
                    if is_r4
                    else (
                        "EXACT_SIX_NET_MIXED_DIRECTION_MET1_WIRE_EDITOR_EXTENSIONS"
                        if is_r3
                        else (
                            "EXACT_SIX_NET_MIXED_LENGTH_MET1_WIRE_EDITOR_EXTENSIONS"
                            if is_r2
                            else "EXACT_SIX_NET_ONE_GRID_MET1_WIRE_EDITOR_EXTENSIONS"
                        )
                    )
                )
            ),
            f"TRIAL_REVISION={revision}",
            f"PATCH_WIDTH_UM={patch_width_um}",
            f"PATCH_LENGTH_POLICY={patch_length_policy}",
            f"PATCH_DIRECTION_POLICY={patch_direction_policy}",
            "PATCH_LENGTH_UM=MIXED_0.56_0.84"
            if is_r2 or is_r3
            else "PATCH_LENGTH_UM=0.56",
            "CONTRACT_VALIDATED_COUNT=6",
        ]
        if is_r4 or is_r5:
            command_lines.insert(3, f"PATCH_WIDTH_POLICY={patch_width_policy}")
        if is_r5:
            command_lines.insert(
                4,
                "MATERIALIZATION_CAPTURE_POLICY="
                "PRE_AND_POST_ALL_WIRES_WITH_LOCAL_MET1_CLASSIFICATION",
            )
        for net, values in contract.items():
            _, start_x, start_y, end_x, source_q, _ = values
            prefix = f"PATCH_{net}"
            length = (
                "0.84"
                if (is_r2 and net in R2_LONG_NETS)
                or (is_r3 and net in R3_AWAY_NETS)
                else "0.56"
            )
            direction = (
                "AWAY_FROM_SOURCE"
                if is_r3 and net in R3_AWAY_NETS
                else "TOWARD_SOURCE"
            )
            width = (
                "0.56" if (is_r4 or is_r5) and net in R4_WIDE_NETS else "0.28"
            )
            command_lines.extend(
                (
                    f"{prefix}_START={start_x} {start_y}",
                    f"{prefix}_END={end_x} {start_y}",
                    f"{prefix}_LENGTH_UM={length}",
                    *([f"{prefix}_WIDTH_UM={width}"] if is_r4 or is_r5 else []),
                    f"{prefix}_DIRECTION={direction}",
                    f"{prefix}_SOURCE_Q={source_q}",
                    f"{prefix}_SET_EDIT_MODE=setEditMode -nets {net} -shape None "
                    "-force_regular 1 -layer_horizontal MET1 -layer_vertical MET1 "
                    f"-snap_to_track_regular 0 -width_horizontal {width} "
                    f"-width_vertical {width}",
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

        pre_wire_row_count = 0
        post_wire_row_count = 0
        materialization_status_lines = ""
        if is_r5:
            pre_wire_row_count, post_wire_row_count = self.write_wire_snapshots(
                reports, materialization
            )
            materialization_status_lines = (
                "MATERIALIZATION_CAPTURE_POLICY="
                "PRE_AND_POST_ALL_WIRES_WITH_LOCAL_MET1_CLASSIFICATION\n"
                "MATERIALIZATION_CAPTURE_STATUS=COMPLETE\n"
                "PRE_WIRE_QUERY_PASS_NET_COUNT=6\n"
                "POST_WIRE_QUERY_PASS_NET_COUNT=6\n"
                f"PRE_WIRE_ROW_COUNT={pre_wire_row_count}\n"
                f"POST_WIRE_ROW_COUNT={post_wire_row_count}\n"
                f"PRE_LOCAL_MET1_ROW_COUNT={pre_wire_row_count}\n"
                f"POST_LOCAL_MET1_ROW_COUNT={post_wire_row_count}\n"
                "PRE_WIRE_ATTRIBUTE_FAIL_COUNT=0\n"
                "POST_WIRE_ATTRIBUTE_FAIL_COUNT=0\n"
                "WIRE_ATTRIBUTE_FAIL_COUNT=0\n"
            )

        final_count = post_drc_count
        final_database = 21 + final_count
        final_nets = " ".join(NETS[:final_count])
        process_status = "PASS" if validated else "FAIL"
        process_result = (
            (
                "WIRE_MATERIALIZATION_REPLAY_DRC_ZERO_VALIDATED"
                if is_r5
                else (
                    "MIXED_WIDTH_MET1_LANDING_EXTENSIONS_DRC_ZERO_VALIDATED"
                    if is_r4
                    else (
                        "MIXED_DIRECTION_MET1_LANDING_EXTENSIONS_DRC_ZERO_VALIDATED"
                        if is_r3
                        else (
                            "MIXED_LENGTH_MET1_LANDING_EXTENSIONS_DRC_ZERO_VALIDATED"
                            if is_r2
                            else "SIX_MET1_LANDING_EXTENSIONS_DRC_ZERO_VALIDATED"
                        )
                    )
                )
            )
            if validated
            else (
                "WIRE_MATERIALIZATION_REPLAY_CHANGED_NOT_CLOSED"
                if is_r5
                else (
                    "MIXED_WIDTH_MET1_LANDING_EXTENSIONS_NO_IMPROVEMENT"
                    if is_r4
                    else (
                        "MIXED_DIRECTION_MET1_LANDING_EXTENSIONS_NO_IMPROVEMENT"
                        if is_r3
                        else (
                            "MIXED_LENGTH_MET1_LANDING_EXTENSIONS_NO_IMPROVEMENT"
                            if is_r2
                            else "SIX_MET1_LANDING_EXTENSIONS_NO_IMPROVEMENT"
                        )
                    )
                )
            )
        )
        (reports / "min_area_landing_patch_trial_status.rpt").write_text(
            "LABEL=SPADMIC_OOC_MIN_AREA_LANDING_PATCH_TRIAL\n"
            f"POLICY={policy}\n"
            f"TRIAL_REVISION={revision}\n"
            f"PATCH_LENGTH_POLICY={patch_length_policy}\n"
            f"PATCH_DIRECTION_POLICY={patch_direction_policy}\n"
            f"PATCH_WIDTH_POLICY={patch_width_policy}\n"
            f"PATCH_WIDTH_UM={patch_width_um}\n"
            f"{materialization_status_lines}"
            "DESIGN_MODIFICATION=IN_MEMORY_ONLY\n"
            "SOURCE_CHECKPOINT_WRITE=NOT_RUN\n"
            "SAVE_DESIGN=NOT_RUN\n"
            "EXPORT=NOT_RUN\n"
            "PVS=NOT_RUN\n"
            "RESTORE_DESIGN=PASS\n"
            f"STATUS={process_status}\n"
            f"RESULT={process_result}\n"
            "SOURCE_CHECKPOINT=/immutable/checkpoints/05_postroute_export.enc.dat\n"
            f"{source_key}={source}\n"
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
        return trial_root, source

    def run_analyzer(
        self,
        trial_root: Path,
        source: Path,
        report: Path,
        revision: str = "R1",
    ) -> subprocess.CompletedProcess[str]:
        source_option = {
            "R1": "--step20-analysis",
            "R2": "--step21-analysis",
            "R3": "--step22-analysis",
            "R4": "--step23-analysis",
            "R5": "--step24-analysis",
        }[revision]
        return subprocess.run(
            [
                "python3",
                str(ANALYZER),
                "--trial-root",
                str(trial_root),
                source_option,
                str(source),
                "--trial-revision",
                revision,
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

    def test_r2_validated_zero_drc_trial_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            trial_root, source = self.write_fixture(
                root, validated=True, revision="R2"
            )
            report = root / "analysis.rpt"
            result = self.run_analyzer(
                trial_root, source, report, revision="R2"
            )
            self.assertEqual(result.returncode, 0, result.stdout)
            text = report.read_text()
            self.assertIn("TRIAL_REVISION=R2", text)
            self.assertIn(
                "PATCH_LENGTH_POLICY=FOUR_SURVIVORS_0.84_TWO_CLOSED_0.56",
                text,
            )
            self.assertIn("METHOD_STATUS=VALIDATED_ZERO_DRC_ZERO_CONNECTIVITY", text)
            self.assertIn("FINAL_MARKER_DATABASE_TOTAL=21", text)

    def test_r2_coherent_no_improvement_is_classified_as_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            trial_root, source = self.write_fixture(
                root, validated=False, revision="R2"
            )
            report = root / "analysis.rpt"
            result = self.run_analyzer(
                trial_root, source, report, revision="R2"
            )
            self.assertEqual(result.returncode, 0, result.stdout)
            text = report.read_text()
            self.assertIn(
                "TRIAL_PROCESS_RESULT=MIXED_LENGTH_MET1_LANDING_EXTENSIONS_NO_IMPROVEMENT",
                text,
            )
            self.assertIn("METHOD_STATUS=REJECTED_OR_INCOMPLETE", text)

    def test_r2_coherent_changed_result_is_classified_as_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            trial_root, source = self.write_fixture(
                root, validated=False, revision="R2"
            )
            reports = trial_root / "reports"
            changed_nets = NETS[:4]
            changed_rows = self.marker_rows()[:4]
            (reports / "drc_markers_post_trial.tsv").write_text(
                MARKER_HEADER + "\n" + "\n".join(changed_rows) + "\n"
            )
            self.write_verify(reports / "verify_drc_post_trial.rpt", 4)
            status_path = reports / "min_area_landing_patch_trial_status.rpt"
            status = status_path.read_text()
            status = status.replace(
                "RESULT=MIXED_LENGTH_MET1_LANDING_EXTENSIONS_NO_IMPROVEMENT",
                "RESULT=MIXED_LENGTH_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED",
            )
            status = status.replace("FINAL_DRC_VIOLATION_COUNT=6", "FINAL_DRC_VIOLATION_COUNT=4")
            status = status.replace("FINAL_DRC_MARKER_COUNT=6", "FINAL_DRC_MARKER_COUNT=4")
            status = status.replace("FINAL_MARKER_DATABASE_TOTAL=27", "FINAL_MARKER_DATABASE_TOTAL=25")
            status = status.replace(
                f"FINAL_MIN_AREA_NETS={' '.join(NETS)}",
                f"FINAL_MIN_AREA_NETS={' '.join(changed_nets)}",
            )
            status_path.write_text(status)
            report = root / "analysis.rpt"
            result = self.run_analyzer(
                trial_root, source, report, revision="R2"
            )
            self.assertEqual(result.returncode, 0, result.stdout)
            text = report.read_text()
            self.assertIn(
                "TRIAL_PROCESS_RESULT=MIXED_LENGTH_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED",
                text,
            )
            self.assertIn("FINAL_DRC_VIOLATION_COUNT=4", text)

    def test_r2_source_tuple_drift_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            trial_root, source = self.write_fixture(
                root, validated=True, revision="R2"
            )
            source.write_text(
                source.read_text().replace(
                    "FINAL_DRC_VIOLATION_COUNT=4",
                    "FINAL_DRC_VIOLATION_COUNT=3",
                )
            )
            report = root / "analysis.rpt"
            result = self.run_analyzer(
                trial_root, source, report, revision="R2"
            )
            self.assertEqual(result.returncode, 8, result.stdout)
            self.assertIn(
                "source_FINAL_DRC_VIOLATION_COUNT=3 expected=4",
                report.read_text(),
            )

    def test_r2_contract_coordinate_drift_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            trial_root, source = self.write_fixture(
                root,
                validated=True,
                tamper_contract=True,
                revision="R2",
            )
            report = root / "analysis.rpt"
            result = self.run_analyzer(
                trial_root, source, report, revision="R2"
            )
            self.assertEqual(result.returncode, 8, result.stdout)
            self.assertIn(
                "contract_n_9696_end_x=719.03 expected=719.04",
                report.read_text(),
            )
            self.assertIn("METHOD_STATUS=REJECTED_OR_INCOMPLETE", report.read_text())

    def test_r3_validated_zero_drc_trial_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            trial_root, source = self.write_fixture(
                root, validated=True, revision="R3"
            )
            report = root / "analysis.rpt"
            result = self.run_analyzer(
                trial_root, source, report, revision="R3"
            )
            self.assertEqual(result.returncode, 0, result.stdout)
            text = report.read_text()
            self.assertIn("TRIAL_REVISION=R3", text)
            self.assertIn(
                "PATCH_DIRECTION_POLICY="
                "FOUR_SURVIVORS_AWAY_FROM_SOURCE_TWO_CLOSED_TOWARD_SOURCE",
                text,
            )
            self.assertIn(
                "PATCH_CONTRACT_STATUS=PASS_EXACT_SIX_MIXED_DIRECTION_EXTENSIONS",
                text,
            )
            self.assertIn("METHOD_STATUS=VALIDATED_ZERO_DRC_ZERO_CONNECTIVITY", text)

    def test_r3_coherent_changed_result_is_classified_as_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            trial_root, source = self.write_fixture(
                root, validated=False, revision="R3"
            )
            reports = trial_root / "reports"
            changed_nets = NETS[:4]
            changed_rows = self.marker_rows()[:4]
            (reports / "drc_markers_post_trial.tsv").write_text(
                MARKER_HEADER + "\n" + "\n".join(changed_rows) + "\n"
            )
            self.write_verify(reports / "verify_drc_post_trial.rpt", 4)
            status_path = reports / "min_area_landing_patch_trial_status.rpt"
            status = status_path.read_text()
            status = status.replace(
                "RESULT=MIXED_DIRECTION_MET1_LANDING_EXTENSIONS_NO_IMPROVEMENT",
                "RESULT=MIXED_DIRECTION_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED",
            )
            status = status.replace(
                "FINAL_DRC_VIOLATION_COUNT=6",
                "FINAL_DRC_VIOLATION_COUNT=4",
            )
            status = status.replace(
                "FINAL_DRC_MARKER_COUNT=6",
                "FINAL_DRC_MARKER_COUNT=4",
            )
            status = status.replace(
                "FINAL_MARKER_DATABASE_TOTAL=27",
                "FINAL_MARKER_DATABASE_TOTAL=25",
            )
            status = status.replace(
                f"FINAL_MIN_AREA_NETS={' '.join(NETS)}",
                f"FINAL_MIN_AREA_NETS={' '.join(changed_nets)}",
            )
            status_path.write_text(status)
            report = root / "analysis.rpt"
            result = self.run_analyzer(
                trial_root, source, report, revision="R3"
            )
            self.assertEqual(result.returncode, 0, result.stdout)
            text = report.read_text()
            self.assertIn(
                "TRIAL_PROCESS_RESULT="
                "MIXED_DIRECTION_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED",
                text,
            )
            self.assertIn("METHOD_STATUS=REJECTED_OR_INCOMPLETE", text)
            self.assertIn("FINAL_DRC_VIOLATION_COUNT=4", text)

    def test_r3_source_tuple_drift_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            trial_root, source = self.write_fixture(
                root, validated=True, revision="R3"
            )
            source.write_text(
                source.read_text().replace(
                    "FINAL_DRC_VIOLATION_COUNT=4",
                    "FINAL_DRC_VIOLATION_COUNT=3",
                )
            )
            report = root / "analysis.rpt"
            result = self.run_analyzer(
                trial_root, source, report, revision="R3"
            )
            self.assertEqual(result.returncode, 8, result.stdout)
            self.assertIn(
                "source_FINAL_DRC_VIOLATION_COUNT=3 expected=4",
                report.read_text(),
            )

    def test_r3_contract_coordinate_drift_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            trial_root, source = self.write_fixture(
                root,
                validated=True,
                tamper_contract=True,
                revision="R3",
            )
            report = root / "analysis.rpt"
            result = self.run_analyzer(
                trial_root, source, report, revision="R3"
            )
            self.assertEqual(result.returncode, 8, result.stdout)
            self.assertIn(
                "contract_n_9696_end_x=720.71 expected=720.72",
                report.read_text(),
            )

    def test_r3_contract_direction_drift_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            trial_root, source = self.write_fixture(
                root, validated=True, revision="R3"
            )
            contract = trial_root / "reports" / "min_area_landing_patch_contract.tsv"
            contract.write_text(
                contract.read_text().replace(
                    "AWAY_FROM_SOURCE",
                    "TOWARD_SOURCE",
                    1,
                )
            )
            report = root / "analysis.rpt"
            result = self.run_analyzer(
                trial_root, source, report, revision="R3"
            )
            self.assertEqual(result.returncode, 8, result.stdout)
            self.assertIn(
                "contract_n_9696_direction=TOWARD_SOURCE "
                "expected=AWAY_FROM_SOURCE",
                report.read_text(),
            )

    def test_r4_validated_zero_drc_trial_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            trial_root, source = self.write_fixture(
                root, validated=True, revision="R4"
            )
            report = root / "analysis.rpt"
            result = self.run_analyzer(
                trial_root, source, report, revision="R4"
            )
            self.assertEqual(result.returncode, 0, result.stdout)
            text = report.read_text()
            self.assertIn("TRIAL_REVISION=R4", text)
            self.assertIn(
                "PATCH_WIDTH_POLICY=FOUR_SURVIVORS_0.56_TWO_CLOSED_0.28",
                text,
            )
            self.assertIn("PATCH_WIDTH_UM=MIXED_0.28_0.56", text)
            self.assertIn(
                "PATCH_CONTRACT_STATUS=PASS_EXACT_SIX_MIXED_WIDTH_EXTENSIONS",
                text,
            )
            self.assertIn("METHOD_STATUS=VALIDATED_ZERO_DRC_ZERO_CONNECTIVITY", text)

    def test_r4_source_tuple_drift_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            trial_root, source = self.write_fixture(
                root, validated=True, revision="R4"
            )
            source.write_text(
                source.read_text().replace(
                    "REMOVED_MARKER_SIGNATURE_COUNT=2",
                    "REMOVED_MARKER_SIGNATURE_COUNT=6",
                )
            )
            report = root / "analysis.rpt"
            result = self.run_analyzer(
                trial_root, source, report, revision="R4"
            )
            self.assertEqual(result.returncode, 8, result.stdout)
            self.assertIn(
                "source_REMOVED_MARKER_SIGNATURE_COUNT=6 expected=2",
                report.read_text(),
            )

    def test_r4_contract_width_drift_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            trial_root, source = self.write_fixture(
                root, validated=True, revision="R4"
            )
            contract = trial_root / "reports" / "min_area_landing_patch_contract.tsv"
            contract.write_text(
                contract.read_text().replace(
                    "0.56\t0.56\tg14627__2802/Q",
                    "0.56\t0.28\tg14627__2802/Q",
                    1,
                )
            )
            report = root / "analysis.rpt"
            result = self.run_analyzer(
                trial_root, source, report, revision="R4"
            )
            self.assertEqual(result.returncode, 8, result.stdout)
            self.assertIn(
                "contract_n_9696_width_um=0.28 expected=0.56",
                report.read_text(),
            )

    def test_r5_requested_wide_width_materialization_is_classified(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            trial_root, source = self.write_fixture(
                root,
                validated=False,
                revision="R5",
                materialization="requested",
            )
            report = root / "analysis.rpt"
            result = self.run_analyzer(trial_root, source, report, revision="R5")
            self.assertEqual(result.returncode, 0, result.stdout)
            text = report.read_text()
            self.assertIn(
                "LABEL=SPADMIC_TX_PACKET_MIN_AREA_LANDING_MATERIALIZATION_ANALYSIS",
                text,
            )
            self.assertIn("METHOD_STATUS=DIAGNOSTIC_CAPTURE_COMPLETE", text)
            self.assertIn(
                "MATERIALIZATION_STATUS=REQUESTED_0P56_WIDTH_MATERIALIZED",
                text,
            )
            self.assertIn("REQUESTED_WIDTH_MATERIALIZED_WIDE_NET_COUNT=4", text)
            self.assertIn(
                "NEXT_METHOD_DECISION="
                "REVIEW_DRC_COUNTED_AREA_VERSUS_MATERIALIZED_0P56_WIRES",
                text,
            )

    def test_r5_canonicalized_wide_width_is_classified(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            trial_root, source = self.write_fixture(
                root,
                validated=False,
                revision="R5",
                materialization="canonicalized",
            )
            report = root / "analysis.rpt"
            result = self.run_analyzer(trial_root, source, report, revision="R5")
            self.assertEqual(result.returncode, 0, result.stdout)
            text = report.read_text()
            self.assertIn(
                "MATERIALIZATION_STATUS=WIDE_REQUEST_CANONICALIZED_TO_0P28",
                text,
            )
            self.assertIn("CANONICALIZED_WIDE_NET_COUNT=4", text)
            self.assertIn(
                "NEXT_METHOD_DECISION="
                "RETIRE_WIRE_EDITOR_WIDTH_CONTROL_REVIEW_NEW_REGULAR_WIRE_PRIMITIVE",
                text,
            )

    def test_r5_no_local_wire_delta_is_classified(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            trial_root, source = self.write_fixture(
                root,
                validated=False,
                revision="R5",
                materialization="none",
            )
            report = root / "analysis.rpt"
            result = self.run_analyzer(trial_root, source, report, revision="R5")
            self.assertEqual(result.returncode, 0, result.stdout)
            text = report.read_text()
            self.assertIn("MATERIALIZATION_STATUS=NO_LOCAL_MET1_WIRE_DELTA", text)
            self.assertIn("NO_LOCAL_DELTA_WIDE_NET_COUNT=4", text)
            self.assertIn("ADDED_WIRE_SIGNATURE_COUNT=0", text)
            self.assertIn(
                "NEXT_METHOD_DECISION="
                "RETIRE_WIRE_EDITOR_COMMAND_PASS_WITHOUT_LOCAL_WIRE_DELTA",
                text,
            )

    def test_r5_snapshot_attribute_failure_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            trial_root, source = self.write_fixture(
                root,
                validated=False,
                revision="R5",
                materialization="requested",
            )
            snapshot = trial_root / "reports" / "wire_snapshot_post_trial.tsv"
            snapshot.write_text(
                snapshot.read_text().replace("\tPASS\tpath\t", "\tFAIL\tUNKNOWN\t", 1)
            )
            report = root / "analysis.rpt"
            result = self.run_analyzer(trial_root, source, report, revision="R5")
            self.assertEqual(result.returncode, 8, result.stdout)
            self.assertIn(
                "wire_snapshot_POST_EDIT_n_9677_shape_status=FAIL expected=PASS",
                report.read_text(),
            )

    def test_r5_replay_command_failure_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            trial_root, source = self.write_fixture(
                root,
                validated=False,
                revision="R5",
                materialization="requested",
            )
            status = trial_root / "reports" / "min_area_landing_patch_trial_status.rpt"
            status.write_text(
                status.read_text()
                .replace("COMMAND_PASS_COUNT=24", "COMMAND_PASS_COUNT=23")
                .replace("COMMAND_FAIL_COUNT=0", "COMMAND_FAIL_COUNT=1")
            )
            report = root / "analysis.rpt"
            result = self.run_analyzer(trial_root, source, report, revision="R5")
            self.assertEqual(result.returncode, 8, result.stdout)
            self.assertIn(
                "r5_replay_command_tuple_not_exact_6_6_24_0",
                report.read_text(),
            )


if __name__ == "__main__":
    unittest.main()
