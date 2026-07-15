#!/usr/bin/env python3
"""Classify the isolated TX six-net MET1 landing-extension trial."""

from __future__ import annotations

import argparse
import csv
import hashlib
import re
from collections import Counter
from pathlib import Path


EXPECTED_NETS = (
    "n_9677",
    "n_9693",
    "n_9696",
    "n_9697",
    "n_9706",
    "n_9721",
)
EXPECTED_POLICY = (
    "ONE_FRESH_PROCESS_ONE_RESTORE_SIX_BOUNDED_MET1_LANDING_EXTENSIONS"
)
EXPECTED_POLICY_R2 = (
    "ONE_FRESH_PROCESS_ONE_RESTORE_SIX_BOUNDED_MIXED_LENGTH_MET1_LANDING_EXTENSIONS"
)
EXPECTED_POLICY_R3 = (
    "ONE_FRESH_PROCESS_ONE_RESTORE_SIX_BOUNDED_MIXED_DIRECTION_MET1_LANDING_EXTENSIONS"
)
EXPECTED_POLICY_R4 = (
    "ONE_FRESH_PROCESS_ONE_RESTORE_SIX_BOUNDED_MIXED_WIDTH_MET1_LANDING_EXTENSIONS"
)
EXPECTED_POLICY_R5 = (
    "ONE_FRESH_PROCESS_ONE_RESTORE_R4_REPLAY_WITH_LOCAL_WIRE_MATERIALIZATION_CAPTURE"
)
EXPECTED_CONTRACT = {
    "n_9696": ("719.69 158.62 720.07 158.90", "719.88", "158.76", "719.32", "g14627__2802/Q", "716.61 159.02"),
    "n_9693": ("210.09 201.74 210.47 202.02", "210.28", "201.88", "209.72", "g14630__8246/Q", "207.01 201.62"),
    "n_9697": ("663.13 192.78 663.51 193.06", "663.32", "192.92", "662.76", "g14626__1617/Q", "660.05 192.66"),
    "n_9677": ("1666.09 201.74 1666.47 202.02", "1666.28", "201.88", "1666.84", "g14646__2398/Q", "1669.55 201.62"),
    "n_9721": ("1792.65 212.38 1793.03 212.66", "1792.84", "212.52", "1792.28", "g14602__8246/Q", "1789.57 212.78"),
    "n_9706": ("1826.81 212.38 1827.19 212.66", "1827.00", "212.52", "1827.56", "g14617__5477/Q", "1830.27 212.78"),
}
EXPECTED_CONTRACT_R2 = {
    **EXPECTED_CONTRACT,
    "n_9696": ("719.69 158.62 720.07 158.90", "719.88", "158.76", "719.04", "g14627__2802/Q", "716.61 159.02"),
    "n_9693": ("210.09 201.74 210.47 202.02", "210.28", "201.88", "209.44", "g14630__8246/Q", "207.01 201.62"),
    "n_9697": ("663.13 192.78 663.51 193.06", "663.32", "192.92", "662.48", "g14626__1617/Q", "660.05 192.66"),
    "n_9677": ("1666.09 201.74 1666.47 202.02", "1666.28", "201.88", "1667.12", "g14646__2398/Q", "1669.55 201.62"),
}
EXPECTED_CONTRACT_R3 = {
    **EXPECTED_CONTRACT,
    "n_9696": ("719.69 158.62 720.07 158.90", "719.88", "158.76", "720.72", "g14627__2802/Q", "716.61 159.02"),
    "n_9693": ("210.09 201.74 210.47 202.02", "210.28", "201.88", "211.12", "g14630__8246/Q", "207.01 201.62"),
    "n_9697": ("663.13 192.78 663.51 193.06", "663.32", "192.92", "664.16", "g14626__1617/Q", "660.05 192.66"),
    "n_9677": ("1666.09 201.74 1666.47 202.02", "1666.28", "201.88", "1665.44", "g14646__2398/Q", "1669.55 201.62"),
}
R2_LONG_NETS = {"n_9677", "n_9693", "n_9696", "n_9697"}
R3_AWAY_NETS = {"n_9677", "n_9693", "n_9696", "n_9697"}
R4_WIDE_NETS = {"n_9677", "n_9693", "n_9696", "n_9697"}
VALIDATED_RESULT = "SIX_MET1_LANDING_EXTENSIONS_DRC_ZERO_VALIDATED"
NO_IMPROVEMENT_RESULT = "SIX_MET1_LANDING_EXTENSIONS_NO_IMPROVEMENT"
VALIDATED_RESULT_R2 = "MIXED_LENGTH_MET1_LANDING_EXTENSIONS_DRC_ZERO_VALIDATED"
NO_IMPROVEMENT_RESULT_R2 = "MIXED_LENGTH_MET1_LANDING_EXTENSIONS_NO_IMPROVEMENT"
VALIDATED_RESULT_R3 = "MIXED_DIRECTION_MET1_LANDING_EXTENSIONS_DRC_ZERO_VALIDATED"
NO_IMPROVEMENT_RESULT_R3 = "MIXED_DIRECTION_MET1_LANDING_EXTENSIONS_NO_IMPROVEMENT"
VALIDATED_RESULT_R4 = "MIXED_WIDTH_MET1_LANDING_EXTENSIONS_DRC_ZERO_VALIDATED"
NO_IMPROVEMENT_RESULT_R4 = "MIXED_WIDTH_MET1_LANDING_EXTENSIONS_NO_IMPROVEMENT"
VALIDATED_RESULT_R5 = "WIRE_MATERIALIZATION_REPLAY_DRC_ZERO_VALIDATED"
NO_IMPROVEMENT_RESULT_R5 = "WIRE_MATERIALIZATION_REPLAY_NO_IMPROVEMENT"

WIRE_SIGNATURE_FIELDS = (
    "net",
    "local_relation",
    "box",
    "layer",
    "route_status",
    "shape",
    "width",
    "length",
    "pts",
)


def key_values(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    if not path.is_file():
        return values
    for line in path.read_text(errors="replace").splitlines():
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key] = value
    return values


def read_tsv(path: Path) -> list[dict[str, str]]:
    if not path.is_file():
        return []
    with path.open(newline="", errors="replace") as handle:
        return list(csv.DictReader(handle, delimiter="\t"))


def digest(path: Path) -> str:
    sha = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            sha.update(chunk)
    return sha.hexdigest()


def report_violation_count(path: Path) -> int | None:
    if not path.is_file():
        return None
    text = path.read_text(errors="replace")
    counts = {
        int(value)
        for pattern in (
            r"Verification Complete\s*:\s*([0-9]+)\s+Viol",
            r"([0-9]+)\s+Problem\(s\)\s+\(IMPVFC-200\):\s+Special Wires:",
        )
        for value in re.findall(pattern, text, re.IGNORECASE)
    }
    return counts.pop() if len(counts) == 1 else None


def integer(values: dict[str, str], key: str, errors: list[str]) -> int | None:
    value = values.get(key)
    if value is None or not re.fullmatch(r"[0-9]+", value):
        errors.append(f"invalid_or_missing_{key}={value or 'MISSING'}")
        return None
    return int(value)


def marker_net(row: dict[str, str]) -> str:
    match = re.search(
        r"Regular\s+Wire\s+of\s+Net\s+([^\s]+)",
        row.get("message", ""),
        re.IGNORECASE,
    )
    return match.group(1) if match else "UNKNOWN"


def marker_signature(row: dict[str, str]) -> tuple[str, ...]:
    return (
        marker_net(row),
        row.get("box", ""),
        row.get("layer", ""),
        row.get("type", ""),
        row.get("subType", ""),
        row.get("message", ""),
    )


def is_min_area_marker(row: dict[str, str]) -> bool:
    return bool(
        row.get("layer", "").upper() == "MET1"
        and row.get("type", "").lower() == "geometry"
        and re.search(
            r"Minimal_Area|Minimum\s+Area|Mar",
            f"{row.get('subType', '')} {row.get('message', '')}",
            re.IGNORECASE,
        )
    )


def numeric_box(raw: str) -> tuple[float, ...] | None:
    values = re.findall(r"[-+]?[0-9]+(?:\.[0-9]+)?", raw)
    if len(values) < 4:
        return None
    return tuple(float(value) for value in values[:4])


def boxes_match(lhs: str, rhs: str) -> bool:
    left = numeric_box(lhs)
    right = numeric_box(rhs)
    return bool(
        left
        and right
        and all(abs(actual - expected) <= 0.001 for actual, expected in zip(left, right))
    )


def canonical_cell(value: str) -> str:
    return " ".join(value.split())


def wire_signature(row: dict[str, str]) -> tuple[str, ...]:
    return tuple(canonical_cell(row.get(field, "")) for field in WIRE_SIGNATURE_FIELDS)


def is_local_met1_wire_signature(signature: tuple[str, ...]) -> bool:
    relation = signature[1]
    layer = signature[3]
    return bool(
        layer.upper() == "MET1"
        and relation in {"INTERSECTS_MARKER", "WITHIN_2UM_CONTEXT"}
    )


def width_matches(raw: str, expected: float) -> bool:
    try:
        return abs(float(raw) - expected) <= 0.001
    except ValueError:
        return False


def classify(
    trial_root: Path,
    source_analysis: Path,
    report_driver_head: str,
    report: Path,
    trial_revision: str = "R1",
) -> dict[str, str]:
    if trial_revision not in {"R1", "R2", "R3", "R4", "R5"}:
        raise ValueError(f"unsupported trial revision: {trial_revision}")
    is_r2 = trial_revision == "R2"
    is_r3 = trial_revision == "R3"
    is_r4 = trial_revision == "R4"
    is_r5 = trial_revision == "R5"
    if is_r5:
        source_key = "STEP24_ANALYSIS"
        expected_policy = EXPECTED_POLICY_R5
        expected_contract = EXPECTED_CONTRACT
        command_policy = "EXACT_SIX_NET_R4_REPLAY_FOR_WIRE_MATERIALIZATION_CAPTURE"
        patch_length_policy = "UNIFORM_0.56"
        patch_direction_policy = "ALL_TOWARD_SOURCE"
        patch_width_policy = "FOUR_SURVIVORS_0.56_TWO_CLOSED_0.28"
        patch_width_um = "MIXED_0.28_0.56"
        validated_result_name = VALIDATED_RESULT_R5
        no_improvement_result_name = NO_IMPROVEMENT_RESULT_R5
        changed_result_name = "WIRE_MATERIALIZATION_REPLAY_CHANGED_NOT_CLOSED"
    elif is_r4:
        source_key = "STEP23_ANALYSIS"
        expected_policy = EXPECTED_POLICY_R4
        expected_contract = EXPECTED_CONTRACT
        command_policy = "EXACT_SIX_NET_MIXED_WIDTH_MET1_WIRE_EDITOR_EXTENSIONS"
        patch_length_policy = "UNIFORM_0.56"
        patch_direction_policy = "ALL_TOWARD_SOURCE"
        patch_width_policy = "FOUR_SURVIVORS_0.56_TWO_CLOSED_0.28"
        patch_width_um = "MIXED_0.28_0.56"
        validated_result_name = VALIDATED_RESULT_R4
        no_improvement_result_name = NO_IMPROVEMENT_RESULT_R4
        changed_result_name = "MIXED_WIDTH_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED"
    elif is_r3:
        source_key = "STEP22_ANALYSIS"
        expected_policy = EXPECTED_POLICY_R3
        expected_contract = EXPECTED_CONTRACT_R3
        command_policy = "EXACT_SIX_NET_MIXED_DIRECTION_MET1_WIRE_EDITOR_EXTENSIONS"
        patch_length_policy = "FOUR_SURVIVORS_0.84_TWO_CLOSED_0.56"
        patch_direction_policy = (
            "FOUR_SURVIVORS_AWAY_FROM_SOURCE_TWO_CLOSED_TOWARD_SOURCE"
        )
        patch_width_policy = "UNIFORM_0.28"
        patch_width_um = "0.28"
        validated_result_name = VALIDATED_RESULT_R3
        no_improvement_result_name = NO_IMPROVEMENT_RESULT_R3
        changed_result_name = (
            "MIXED_DIRECTION_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED"
        )
    elif is_r2:
        source_key = "STEP21_ANALYSIS"
        expected_policy = EXPECTED_POLICY_R2
        expected_contract = EXPECTED_CONTRACT_R2
        command_policy = "EXACT_SIX_NET_MIXED_LENGTH_MET1_WIRE_EDITOR_EXTENSIONS"
        patch_length_policy = "FOUR_SURVIVORS_0.84_TWO_CLOSED_0.56"
        patch_direction_policy = "ALL_TOWARD_SOURCE"
        patch_width_policy = "UNIFORM_0.28"
        patch_width_um = "0.28"
        validated_result_name = VALIDATED_RESULT_R2
        no_improvement_result_name = NO_IMPROVEMENT_RESULT_R2
        changed_result_name = "MIXED_LENGTH_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED"
    else:
        source_key = "STEP20_ANALYSIS"
        expected_policy = EXPECTED_POLICY
        expected_contract = EXPECTED_CONTRACT
        command_policy = "EXACT_SIX_NET_ONE_GRID_MET1_WIRE_EDITOR_EXTENSIONS"
        patch_length_policy = "UNIFORM_0.56"
        patch_direction_policy = "ALL_TOWARD_SOURCE"
        patch_width_policy = "UNIFORM_0.28"
        patch_width_um = "0.28"
        validated_result_name = VALIDATED_RESULT
        no_improvement_result_name = NO_IMPROVEMENT_RESULT
        changed_result_name = "SIX_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED"
    reports = trial_root / "reports"
    context_path = trial_root / "context.rpt"
    status_path = reports / "min_area_landing_patch_trial_status.rpt"
    commands_path = reports / "min_area_landing_patch_commands.rpt"
    contract_path = reports / "min_area_landing_patch_contract.tsv"
    pre_markers_path = reports / "drc_markers_pre_trial.tsv"
    post_markers_path = reports / "drc_markers_post_trial.tsv"
    pre_drc_path = reports / "verify_drc_pre_trial.rpt"
    post_drc_path = reports / "verify_drc_post_trial.rpt"
    pre_regular_path = reports / "verify_connectivity_regular_pre_trial.rpt"
    post_regular_path = reports / "verify_connectivity_regular_post_trial.rpt"
    pre_special_path = reports / "verify_connectivity_special_pre_trial.rpt"
    post_special_path = reports / "verify_connectivity_special_post_trial.rpt"
    pre_wire_snapshot_path = reports / "wire_snapshot_pre_trial.tsv"
    post_wire_snapshot_path = reports / "wire_snapshot_post_trial.tsv"
    required = [
        context_path,
        status_path,
        commands_path,
        contract_path,
        source_analysis,
        pre_markers_path,
        post_markers_path,
        pre_drc_path,
        post_drc_path,
        pre_regular_path,
        post_regular_path,
        pre_special_path,
        post_special_path,
    ]
    if is_r5:
        required.extend((pre_wire_snapshot_path, post_wire_snapshot_path))

    errors: list[str] = []
    for path in required:
        if not path.is_file():
            errors.append(f"missing_required_artifact={path}")

    context = key_values(context_path)
    status = key_values(status_path)
    commands = key_values(commands_path)
    source = key_values(source_analysis)
    contract = read_tsv(contract_path)
    pre_markers = read_tsv(pre_markers_path)
    post_markers = read_tsv(post_markers_path)
    pre_wire_snapshot = read_tsv(pre_wire_snapshot_path) if is_r5 else []
    post_wire_snapshot = read_tsv(post_wire_snapshot_path) if is_r5 else []

    if is_r5:
        expected_source = {
            "LABEL": "SPADMIC_TX_PACKET_MIN_AREA_LANDING_PATCH_ANALYSIS",
            "POLICY": "ISOLATED_IN_MEMORY_SIX_NET_MIXED_WIDTH_MET1_LANDING_PATCH_CLASSIFICATION",
            "STATUS": "PASS",
            "RESULT": "MIN_AREA_LANDING_PATCH_TRIAL_CLASSIFIED",
            "TRIAL_REVISION": "R4",
            "TRIAL_PROCESS_STATUS": "FAIL",
            "TRIAL_PROCESS_RESULT": "MIXED_WIDTH_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED",
            "METHOD_STATUS": "REJECTED_OR_INCOMPLETE",
            "PATCH_CONTRACT_STATUS": "PASS_EXACT_SIX_MIXED_WIDTH_EXTENSIONS",
            "PATCH_WIDTH_POLICY": "FOUR_SURVIVORS_0.56_TWO_CLOSED_0.28",
            "PATCH_WIDTH_UM": "MIXED_0.28_0.56",
            "PATCH_LENGTH_POLICY": "UNIFORM_0.56",
            "PATCH_LENGTH_UM": "0.56",
            "PATCH_DIRECTION_POLICY": "ALL_TOWARD_SOURCE",
            "PATCH_ATTEMPTED_COUNT": "6",
            "PATCH_APPLIED_COUNT": "6",
            "COMMAND_PASS_COUNT": "24",
            "COMMAND_FAIL_COUNT": "0",
            "PRE_DRC_VIOLATION_COUNT": "6",
            "FINAL_DRC_VIOLATION_COUNT": "4",
            "PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT": "0",
            "FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT": "0",
            "PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": "0",
            "FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": "0",
            "PRE_EXCLUDED_ANTENNA_MARKER_COUNT": "21",
            "FINAL_EXCLUDED_ANTENNA_MARKER_COUNT": "21",
            "PRE_MARKER_DATABASE_TOTAL": "27",
            "FINAL_MARKER_DATABASE_TOTAL": "25",
            "REMOVED_MARKER_SIGNATURE_COUNT": "6",
            "ADDED_MARKER_SIGNATURE_COUNT": "4",
            "FINAL_MIN_AREA_NETS": "n_9677 n_9693 n_9696 n_9697",
            "SAVE_DESIGN": "NOT_RUN",
            "EXPORT": "NOT_RUN",
            "IMMUTABLE_PVS_STAGING": "NOT_RUN",
            "PVS_DECISION": "DO_NOT_RUN",
            "CANONICAL_RERUN_DECISION": "DO_NOT_RUN_FROM_THIS_STEP",
            "NEXT_METHOD_DECISION": "STOP_AND_REVIEW_PATCH_EVIDENCE_BEFORE_NEW_METHOD",
            "ERROR_COUNT": "0",
        }
    elif is_r4:
        expected_source = {
            "LABEL": "SPADMIC_TX_PACKET_MIN_AREA_LANDING_PATCH_ANALYSIS",
            "POLICY": "ISOLATED_IN_MEMORY_SIX_NET_MIXED_DIRECTION_MET1_LANDING_PATCH_CLASSIFICATION",
            "STATUS": "PASS",
            "RESULT": "MIN_AREA_LANDING_PATCH_TRIAL_CLASSIFIED",
            "TRIAL_REVISION": "R3",
            "TRIAL_PROCESS_STATUS": "FAIL",
            "TRIAL_PROCESS_RESULT": "MIXED_DIRECTION_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED",
            "METHOD_STATUS": "REJECTED_OR_INCOMPLETE",
            "PATCH_CONTRACT_STATUS": "PASS_EXACT_SIX_MIXED_DIRECTION_EXTENSIONS",
            "PATCH_WIDTH_UM": "0.28",
            "PATCH_LENGTH_POLICY": "FOUR_SURVIVORS_0.84_TWO_CLOSED_0.56",
            "PATCH_LENGTH_UM": "MIXED_0.56_0.84",
            "PATCH_DIRECTION_POLICY": "FOUR_SURVIVORS_AWAY_FROM_SOURCE_TWO_CLOSED_TOWARD_SOURCE",
            "PATCH_ATTEMPTED_COUNT": "6",
            "PATCH_APPLIED_COUNT": "6",
            "COMMAND_PASS_COUNT": "24",
            "COMMAND_FAIL_COUNT": "0",
            "PRE_DRC_VIOLATION_COUNT": "6",
            "FINAL_DRC_VIOLATION_COUNT": "4",
            "PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT": "0",
            "FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT": "0",
            "PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": "0",
            "FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": "0",
            "PRE_EXCLUDED_ANTENNA_MARKER_COUNT": "21",
            "FINAL_EXCLUDED_ANTENNA_MARKER_COUNT": "21",
            "PRE_MARKER_DATABASE_TOTAL": "27",
            "FINAL_MARKER_DATABASE_TOTAL": "25",
            "REMOVED_MARKER_SIGNATURE_COUNT": "2",
            "ADDED_MARKER_SIGNATURE_COUNT": "0",
            "FINAL_MIN_AREA_NETS": "n_9677 n_9693 n_9696 n_9697",
            "SAVE_DESIGN": "NOT_RUN",
            "EXPORT": "NOT_RUN",
            "IMMUTABLE_PVS_STAGING": "NOT_RUN",
            "PVS_DECISION": "DO_NOT_RUN",
            "CANONICAL_RERUN_DECISION": "DO_NOT_RUN_FROM_THIS_STEP",
            "NEXT_METHOD_DECISION": "STOP_AND_REVIEW_PATCH_EVIDENCE_BEFORE_NEW_METHOD",
            "ERROR_COUNT": "0",
        }
    elif is_r3:
        expected_source = {
            "LABEL": "SPADMIC_TX_PACKET_MIN_AREA_LANDING_PATCH_ANALYSIS",
            "POLICY": "ISOLATED_IN_MEMORY_SIX_NET_MIXED_LENGTH_MET1_LANDING_PATCH_CLASSIFICATION",
            "STATUS": "PASS",
            "RESULT": "MIN_AREA_LANDING_PATCH_TRIAL_CLASSIFIED",
            "TRIAL_REVISION": "R2",
            "TRIAL_PROCESS_STATUS": "FAIL",
            "TRIAL_PROCESS_RESULT": "MIXED_LENGTH_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED",
            "METHOD_STATUS": "REJECTED_OR_INCOMPLETE",
            "PATCH_CONTRACT_STATUS": "PASS_EXACT_SIX_MIXED_LENGTH_EXTENSIONS",
            "PATCH_WIDTH_UM": "0.28",
            "PATCH_LENGTH_POLICY": "FOUR_SURVIVORS_0.84_TWO_CLOSED_0.56",
            "PATCH_LENGTH_UM": "MIXED_0.56_0.84",
            "PATCH_ATTEMPTED_COUNT": "6",
            "PATCH_APPLIED_COUNT": "6",
            "COMMAND_PASS_COUNT": "24",
            "COMMAND_FAIL_COUNT": "0",
            "PRE_DRC_VIOLATION_COUNT": "6",
            "FINAL_DRC_VIOLATION_COUNT": "4",
            "PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT": "0",
            "FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT": "0",
            "PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": "0",
            "FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": "0",
            "PRE_EXCLUDED_ANTENNA_MARKER_COUNT": "21",
            "FINAL_EXCLUDED_ANTENNA_MARKER_COUNT": "21",
            "PRE_MARKER_DATABASE_TOTAL": "27",
            "FINAL_MARKER_DATABASE_TOTAL": "25",
            "REMOVED_MARKER_SIGNATURE_COUNT": "6",
            "ADDED_MARKER_SIGNATURE_COUNT": "4",
            "FINAL_MIN_AREA_NETS": "n_9677 n_9693 n_9696 n_9697",
            "SAVE_DESIGN": "NOT_RUN",
            "EXPORT": "NOT_RUN",
            "IMMUTABLE_PVS_STAGING": "NOT_RUN",
            "PVS_DECISION": "DO_NOT_RUN",
            "CANONICAL_RERUN_DECISION": "DO_NOT_RUN_FROM_THIS_STEP",
            "NEXT_METHOD_DECISION": "STOP_AND_REVIEW_PATCH_EVIDENCE_BEFORE_NEW_METHOD",
            "ERROR_COUNT": "0",
        }
    elif is_r2:
        expected_source = {
            "LABEL": "SPADMIC_TX_PACKET_MIN_AREA_LANDING_PATCH_ANALYSIS",
            "POLICY": "ISOLATED_IN_MEMORY_SIX_NET_MET1_LANDING_PATCH_CLASSIFICATION",
            "STATUS": "PASS",
            "RESULT": "MIN_AREA_LANDING_PATCH_TRIAL_CLASSIFIED",
            "TRIAL_PROCESS_STATUS": "FAIL",
            "TRIAL_PROCESS_RESULT": "SIX_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED",
            "METHOD_STATUS": "REJECTED_OR_INCOMPLETE",
            "PATCH_CONTRACT_STATUS": "PASS_EXACT_SIX_REVIEWED_EXTENSIONS",
            "PATCH_WIDTH_UM": "0.28",
            "PATCH_LENGTH_UM": "0.56",
            "PATCH_ATTEMPTED_COUNT": "6",
            "PATCH_APPLIED_COUNT": "6",
            "COMMAND_PASS_COUNT": "24",
            "COMMAND_FAIL_COUNT": "0",
            "PRE_DRC_VIOLATION_COUNT": "6",
            "FINAL_DRC_VIOLATION_COUNT": "4",
            "PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT": "0",
            "FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT": "0",
            "PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": "0",
            "FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": "0",
            "PRE_EXCLUDED_ANTENNA_MARKER_COUNT": "21",
            "FINAL_EXCLUDED_ANTENNA_MARKER_COUNT": "21",
            "PRE_MARKER_DATABASE_TOTAL": "27",
            "FINAL_MARKER_DATABASE_TOTAL": "25",
            "REMOVED_MARKER_SIGNATURE_COUNT": "6",
            "ADDED_MARKER_SIGNATURE_COUNT": "4",
            "FINAL_MIN_AREA_NETS": "n_9677 n_9693 n_9696 n_9697",
            "SAVE_DESIGN": "NOT_RUN",
            "EXPORT": "NOT_RUN",
            "IMMUTABLE_PVS_STAGING": "NOT_RUN",
            "PVS_DECISION": "DO_NOT_RUN",
            "CANONICAL_RERUN_DECISION": "DO_NOT_RUN_FROM_THIS_STEP",
            "NEXT_METHOD_DECISION": "STOP_AND_REVIEW_PATCH_EVIDENCE_BEFORE_NEW_METHOD",
            "ERROR_COUNT": "0",
        }
    else:
        expected_source = {
            "LABEL": "SPADMIC_TX_PACKET_MIN_AREA_GEOMETRY_ANALYSIS",
            "POLICY": "READ_ONLY_RESTORED_CHECKPOINT_LOCAL_TOPOLOGY_CLASSIFICATION",
            "STATUS": "PASS",
            "RESULT": "MIN_AREA_LOCAL_GEOMETRY_CLASSIFIED",
            "SELECTED_NET_REROUTE_METHOD_STATUS": "REJECTED_NO_IMPROVEMENT",
            "PRE_DRC_VIOLATION_COUNT": "6",
            "POST_DRC_VIOLATION_COUNT": "6",
            "PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT": "0",
            "POST_REGULAR_CONNECTIVITY_VIOLATION_COUNT": "0",
            "PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": "0",
            "POST_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": "0",
            "PRE_EXCLUDED_ANTENNA_MARKER_COUNT": "21",
            "POST_EXCLUDED_ANTENNA_MARKER_COUNT": "21",
            "PRE_MARKER_DATABASE_TOTAL": "27",
            "POST_MARKER_DATABASE_TOTAL": "27",
            "MARKER_SIGNATURE_STABILITY": "PASS_IDENTICAL_BEFORE_AND_AFTER_QUERY_PROBE",
            "RESOLVED_NET_COUNT": "6",
            "WIRE_QUERY_PASS_NET_COUNT": "6",
            "LOCAL_WIRE_NET_COUNT": "6",
            "INST_TERM_NET_COUNT": "6",
            "INST_TERM_ROW_COUNT": "12",
            "LOCAL_GEOMETRY_CAPTURE_STATUS": "PARTIAL_TERMINAL_OR_PIN_SHAPE_COVERAGE",
            "DIRECT_GEOMETRY_TRIAL_DECISION": "BLOCKED_PENDING_OPERATOR_REVIEW",
            "CANONICAL_RERUN_DECISION": "BLOCKED_PENDING_LOCAL_GEOMETRY_REVIEW",
            "SAVE_DESIGN": "NOT_RUN",
            "EXPORT": "NOT_RUN",
            "IMMUTABLE_PVS_STAGING": "NOT_RUN",
            "PVS_DECISION": "DO_NOT_RUN",
            "ERROR_COUNT": "0",
        }
    for key, expected in expected_source.items():
        if source.get(key) != expected:
            errors.append(
                f"source_{key}={source.get(key, 'MISSING')} expected={expected}"
            )

    expected_context = {
        "HEAD": report_driver_head,
        "POLICY": expected_policy,
        "TRIAL_REVISION": trial_revision,
        "DESIGN_MODIFICATION": "IN_MEMORY_ONLY",
        "SOURCE_CHECKPOINT_WRITE": "NOT_RUN",
        "SAVE_DESIGN": "NOT_RUN",
        "EXPORT": "NOT_RUN",
        "PVS": "NOT_RUN",
    }
    for key, expected in expected_context.items():
        if context.get(key) != expected:
            errors.append(f"context_{key}={context.get(key, 'MISSING')} expected={expected}")
    context_analysis = context.get(source_key, "")
    if not context_analysis or Path(context_analysis).resolve() != source_analysis:
        errors.append(
            f"context_{source_key}={context_analysis or 'MISSING'} expected={source_analysis}"
        )
    context_analysis_sha = context.get(f"{source_key}_SHA256", "")
    expected_analysis_sha = digest(source_analysis) if source_analysis.is_file() else ""
    if not context_analysis_sha or context_analysis_sha != expected_analysis_sha:
        errors.append(
            f"context_{source_key}_SHA256={context_analysis_sha or 'MISSING'} "
            f"expected={expected_analysis_sha or 'MISSING'}"
        )

    expected_status = {
        "LABEL": "SPADMIC_OOC_MIN_AREA_LANDING_PATCH_TRIAL",
        "POLICY": expected_policy,
        "TRIAL_REVISION": trial_revision,
        "PATCH_LENGTH_POLICY": patch_length_policy,
        "DESIGN_MODIFICATION": "IN_MEMORY_ONLY",
        "SOURCE_CHECKPOINT_WRITE": "NOT_RUN",
        "SAVE_DESIGN": "NOT_RUN",
        "EXPORT": "NOT_RUN",
        "PVS": "NOT_RUN",
        "RESTORE_DESIGN": "PASS",
        "PRE_MIN_AREA_NETS": " ".join(EXPECTED_NETS),
        "CONTRACT_VALIDATED_COUNT": "6",
    }
    if is_r3 or is_r4 or is_r5:
        expected_status["PATCH_DIRECTION_POLICY"] = patch_direction_policy
    if is_r4 or is_r5:
        expected_status.update(
            {
                "PATCH_WIDTH_POLICY": patch_width_policy,
                "PATCH_WIDTH_UM": patch_width_um,
            }
        )
    if is_r5:
        expected_status.update(
            {
                "MATERIALIZATION_CAPTURE_POLICY": (
                    "PRE_AND_POST_ALL_WIRES_WITH_LOCAL_MET1_CLASSIFICATION"
                ),
                "MATERIALIZATION_CAPTURE_STATUS": "COMPLETE",
            }
        )
    for key, expected in expected_status.items():
        if status.get(key) != expected:
            errors.append(f"trial_{key}={status.get(key, 'MISSING')} expected={expected}")
    status_analysis = status.get(source_key, "")
    if not status_analysis or Path(status_analysis).resolve() != source_analysis:
        errors.append(
            f"trial_{source_key}={status_analysis or 'MISSING'} expected={source_analysis}"
        )
    if status.get("SOURCE_CHECKPOINT") != context.get("SOURCE_CHECKPOINT"):
        errors.append("source_checkpoint_mismatch")

    count_keys = (
        "PRE_DRC_VIOLATION_COUNT",
        "PRE_DRC_MARKER_COUNT",
        "PRE_MARKER_DATABASE_TOTAL",
        "PRE_EXCLUDED_ANTENNA_MARKER_COUNT",
        "PRE_EXCLUDED_CONNECTIVITY_MARKER_COUNT",
        "PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT",
        "PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT",
        "FINAL_DRC_VIOLATION_COUNT",
        "FINAL_DRC_MARKER_COUNT",
        "FINAL_MARKER_DATABASE_TOTAL",
        "FINAL_EXCLUDED_ANTENNA_MARKER_COUNT",
        "FINAL_EXCLUDED_CONNECTIVITY_MARKER_COUNT",
        "FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT",
        "FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT",
        "CONTRACT_VALIDATED_COUNT",
        "PATCH_ATTEMPTED_COUNT",
        "PATCH_APPLIED_COUNT",
        "COMMAND_PASS_COUNT",
        "COMMAND_FAIL_COUNT",
    )
    counts = {key: integer(status, key, errors) for key in count_keys}
    if is_r5:
        for key in (
            "PRE_WIRE_QUERY_PASS_NET_COUNT",
            "POST_WIRE_QUERY_PASS_NET_COUNT",
            "PRE_WIRE_ROW_COUNT",
            "POST_WIRE_ROW_COUNT",
            "PRE_LOCAL_MET1_ROW_COUNT",
            "POST_LOCAL_MET1_ROW_COUNT",
            "PRE_WIRE_ATTRIBUTE_FAIL_COUNT",
            "POST_WIRE_ATTRIBUTE_FAIL_COUNT",
            "WIRE_ATTRIBUTE_FAIL_COUNT",
        ):
            counts[key] = integer(status, key, errors)
    expected_baseline = {
        "PRE_DRC_VIOLATION_COUNT": 6,
        "PRE_DRC_MARKER_COUNT": 6,
        "PRE_MARKER_DATABASE_TOTAL": 27,
        "PRE_EXCLUDED_ANTENNA_MARKER_COUNT": 21,
        "PRE_EXCLUDED_CONNECTIVITY_MARKER_COUNT": 0,
        "PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT": 0,
        "PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": 0,
        "CONTRACT_VALIDATED_COUNT": 6,
    }
    for key, expected in expected_baseline.items():
        if counts.get(key) != expected:
            errors.append(f"baseline_{key}={counts.get(key)} expected={expected}")

    report_counts = {
        "PRE_DRC_VIOLATION_COUNT": report_violation_count(pre_drc_path),
        "FINAL_DRC_VIOLATION_COUNT": report_violation_count(post_drc_path),
        "PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT": report_violation_count(pre_regular_path),
        "FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT": report_violation_count(post_regular_path),
        "PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": report_violation_count(pre_special_path),
        "FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": report_violation_count(post_special_path),
    }
    for key, actual in report_counts.items():
        if actual != counts.get(key):
            errors.append(f"report_{key}={actual} status={counts.get(key)}")

    if len(pre_markers) != 6:
        errors.append(f"pre_marker_row_count={len(pre_markers)} expected=6")
    pre_nets = tuple(sorted(marker_net(row) for row in pre_markers))
    if pre_nets != EXPECTED_NETS:
        errors.append(f"pre_marker_nets={pre_nets} expected={EXPECTED_NETS}")
    for row in pre_markers:
        net = marker_net(row)
        expected = expected_contract.get(net)
        if expected is None or not boxes_match(row.get("box", ""), expected[0]):
            errors.append(f"unexpected_pre_marker_box={net}:{row.get('box', '')}")
        if row.get("layer") != "MET1" or row.get("type") != "Geometry":
            errors.append(
                f"unexpected_pre_marker_class={net}:{row.get('layer')}:{row.get('type')}"
            )

    contract_by_net = {row.get("net", ""): row for row in contract}
    if len(contract) != 6 or tuple(sorted(contract_by_net)) != EXPECTED_NETS:
        errors.append(
            f"contract_rows={len(contract)} nets={tuple(sorted(contract_by_net))}"
        )
    for net, expected in expected_contract.items():
        row = contract_by_net.get(net, {})
        expected_length = (
            "0.84"
            if (is_r2 and net in R2_LONG_NETS) or (is_r3 and net in R3_AWAY_NETS)
            else "0.56"
        )
        expected_width = (
            "0.56" if (is_r4 or is_r5) and net in R4_WIDE_NETS else "0.28"
        )
        expected_fields = {
            "start_x": expected[1],
            "start_y": expected[2],
            "end_x": expected[3],
            "end_y": expected[2],
            "length_um": expected_length,
            "width_um": expected_width,
            "source_q": expected[4],
            "source_q_point": expected[5],
            "marker_status": "PASS",
            "via1_status": "PASS",
            "met2_endpoint_status": "PASS",
            "source_q_status": "PASS",
            "inside_source_inst_status": "PASS",
            "contract_status": "PASS",
        }
        if is_r3 or is_r4 or is_r5:
            expected_fields["direction"] = (
                "AWAY_FROM_SOURCE"
                if is_r3 and net in R3_AWAY_NETS
                else "TOWARD_SOURCE"
            )
        if not boxes_match(row.get("marker_box", ""), expected[0]):
            errors.append(f"contract_{net}_marker_box={row.get('marker_box', 'MISSING')}")
        for key, value in expected_fields.items():
            if row.get(key) != value:
                errors.append(f"contract_{net}_{key}={row.get(key, 'MISSING')} expected={value}")

    expected_commands = {
        "LABEL": "SPADMIC_OOC_MIN_AREA_LANDING_PATCH_COMMANDS",
        "POLICY": command_policy,
        "TRIAL_REVISION": trial_revision,
        "PATCH_WIDTH_UM": patch_width_um,
        "PATCH_LENGTH_POLICY": patch_length_policy,
        "PATCH_LENGTH_UM": "MIXED_0.56_0.84" if is_r2 or is_r3 else "0.56",
        "CONTRACT_VALIDATED_COUNT": "6",
    }
    if is_r3 or is_r4 or is_r5:
        expected_commands["PATCH_DIRECTION_POLICY"] = patch_direction_policy
    if is_r4 or is_r5:
        expected_commands["PATCH_WIDTH_POLICY"] = patch_width_policy
    if is_r5:
        expected_commands["MATERIALIZATION_CAPTURE_POLICY"] = (
            "PRE_AND_POST_ALL_WIRES_WITH_LOCAL_MET1_CLASSIFICATION"
        )
    for key, expected in expected_commands.items():
        if commands.get(key) != expected:
            errors.append(f"commands_{key}={commands.get(key, 'MISSING')} expected={expected}")
    for key in ("PATCH_ATTEMPTED_COUNT", "PATCH_APPLIED_COUNT", "COMMAND_PASS_COUNT", "COMMAND_FAIL_COUNT"):
        if commands.get(key) != status.get(key):
            errors.append(f"commands_status_mismatch_{key}={commands.get(key)}:{status.get(key)}")

    command_fail_count = counts.get("COMMAND_FAIL_COUNT")
    command_pass_count = counts.get("COMMAND_PASS_COUNT")
    patch_attempted = counts.get("PATCH_ATTEMPTED_COUNT")
    patch_applied = counts.get("PATCH_APPLIED_COUNT")
    if command_fail_count == 0:
        if (command_pass_count, patch_attempted, patch_applied) != (24, 6, 6):
            errors.append(
                "unexpected_success_command_tuple="
                f"{command_pass_count},{patch_attempted},{patch_applied} expected=24,6,6"
            )
        for net, expected in expected_contract.items():
            prefix = f"PATCH_{net}"
            expected_length = (
                "0.84"
                if (is_r2 and net in R2_LONG_NETS)
                or (is_r3 and net in R3_AWAY_NETS)
                else "0.56"
            )
            expected_width = (
                "0.56"
                if (is_r4 or is_r5) and net in R4_WIDE_NETS
                else "0.28"
            )
            expected_commands_for_net = {
                f"{prefix}_START": f"{expected[1]} {expected[2]}",
                f"{prefix}_END": f"{expected[3]} {expected[2]}",
                f"{prefix}_LENGTH_UM": expected_length,
                f"{prefix}_SOURCE_Q": expected[4],
                f"{prefix}_APPLIED": "YES",
            }
            if is_r4 or is_r5:
                expected_commands_for_net[f"{prefix}_WIDTH_UM"] = expected_width
            if is_r3 or is_r4 or is_r5:
                expected_commands_for_net[f"{prefix}_DIRECTION"] = (
                    "AWAY_FROM_SOURCE"
                    if is_r3 and net in R3_AWAY_NETS
                    else "TOWARD_SOURCE"
                )
            for key, value in expected_commands_for_net.items():
                if commands.get(key) != value:
                    errors.append(
                        f"commands_{key}={commands.get(key, 'MISSING')} expected={value}"
                    )
            setup = commands.get(f"{prefix}_SET_EDIT_MODE", "")
            if not all(
                token in setup
                for token in (
                    "setEditMode",
                    f"-nets {net}",
                    "-force_regular 1",
                    "-layer_horizontal MET1",
                    "-layer_vertical MET1",
                    "-snap_to_track_regular 0",
                    f"-width_horizontal {expected_width}",
                    f"-width_vertical {expected_width}",
                )
            ):
                errors.append(f"commands_{prefix}_SET_EDIT_MODE_contract_mismatch")
    elif command_fail_count is not None:
        if command_fail_count < 1 or patch_attempted is None or not 1 <= patch_attempted <= 6:
            errors.append("invalid_failed_command_tuple")
    if is_r5 and (
        counts.get("PATCH_ATTEMPTED_COUNT"),
        counts.get("PATCH_APPLIED_COUNT"),
        counts.get("COMMAND_PASS_COUNT"),
        counts.get("COMMAND_FAIL_COUNT"),
    ) != (6, 6, 24, 0):
        errors.append("r5_replay_command_tuple_not_exact_6_6_24_0")

    materialization_status = "NOT_APPLICABLE"
    materialization_summary: list[dict[str, str]] = []
    added_wire_signatures: Counter[tuple[str, ...]] = Counter()
    removed_wire_signatures: Counter[tuple[str, ...]] = Counter()
    added_wire_handle_count = 0
    removed_wire_handle_count = 0
    added_local_met1_signature_count = 0
    removed_local_met1_signature_count = 0
    requested_width_materialized_wide_net_count = 0
    canonicalized_wide_net_count = 0
    no_local_delta_wide_net_count = 0
    if is_r5:
        for phase, rows in (
            ("PRE_EDIT", pre_wire_snapshot),
            ("POST_EDIT", post_wire_snapshot),
        ):
            for row in rows:
                net = row.get("net", "")
                expected = expected_contract.get(net)
                expected_width = (
                    "0.56" if net in R4_WIDE_NETS else "0.28"
                )
                if row.get("phase") != phase:
                    errors.append(
                        f"wire_snapshot_phase={row.get('phase', 'MISSING')} expected={phase}"
                    )
                if expected is None:
                    errors.append(f"wire_snapshot_unexpected_net={net or 'MISSING'}")
                    continue
                if not boxes_match(row.get("marker_box", ""), expected[0]):
                    errors.append(f"wire_snapshot_{phase}_{net}_marker_box_mismatch")
                if row.get("requested_width_um") != expected_width:
                    errors.append(
                        f"wire_snapshot_{phase}_{net}_requested_width="
                        f"{row.get('requested_width_um', 'MISSING')} expected={expected_width}"
                    )
                for field in (
                    "box_status",
                    "layer_status",
                    "route_status_status",
                    "shape_status",
                    "width_status",
                    "length_status",
                    "pts_status",
                ):
                    if row.get(field) != "PASS":
                        errors.append(
                            f"wire_snapshot_{phase}_{net}_{field}="
                            f"{row.get(field, 'MISSING')} expected=PASS"
                        )
                if row.get("wire_handle", "") in {"", "UNKNOWN", "0x0"}:
                    errors.append(f"wire_snapshot_{phase}_{net}_invalid_wire_handle")
                if row.get("local_relation") not in {
                    "INTERSECTS_MARKER",
                    "WITHIN_2UM_CONTEXT",
                    "OUTSIDE_CONTEXT",
                    "UNKNOWN_BOX",
                }:
                    errors.append(
                        f"wire_snapshot_{phase}_{net}_local_relation="
                        f"{row.get('local_relation', 'MISSING')}"
                    )

            snapshot_nets = {row.get("net", "") for row in rows}
            if snapshot_nets != set(EXPECTED_NETS):
                errors.append(
                    f"wire_snapshot_{phase}_nets={sorted(snapshot_nets)} "
                    f"expected={list(EXPECTED_NETS)}"
                )

        derived_wire_counts = {
            "PRE_WIRE_ROW_COUNT": len(pre_wire_snapshot),
            "POST_WIRE_ROW_COUNT": len(post_wire_snapshot),
            "PRE_LOCAL_MET1_ROW_COUNT": sum(
                1
                for row in pre_wire_snapshot
                if is_local_met1_wire_signature(wire_signature(row))
            ),
            "POST_LOCAL_MET1_ROW_COUNT": sum(
                1
                for row in post_wire_snapshot
                if is_local_met1_wire_signature(wire_signature(row))
            ),
        }
        for key, actual in derived_wire_counts.items():
            if counts.get(key) != actual:
                errors.append(f"wire_snapshot_{key}={actual} status={counts.get(key)}")
        for key in (
            "PRE_WIRE_QUERY_PASS_NET_COUNT",
            "POST_WIRE_QUERY_PASS_NET_COUNT",
        ):
            if counts.get(key) != 6:
                errors.append(f"wire_snapshot_{key}={counts.get(key)} expected=6")
        for key in (
            "PRE_WIRE_ATTRIBUTE_FAIL_COUNT",
            "POST_WIRE_ATTRIBUTE_FAIL_COUNT",
            "WIRE_ATTRIBUTE_FAIL_COUNT",
        ):
            if counts.get(key) != 0:
                errors.append(f"wire_snapshot_{key}={counts.get(key)} expected=0")

        pre_signature_counter = Counter(
            wire_signature(row) for row in pre_wire_snapshot
        )
        post_signature_counter = Counter(
            wire_signature(row) for row in post_wire_snapshot
        )
        added_wire_signatures = post_signature_counter - pre_signature_counter
        removed_wire_signatures = pre_signature_counter - post_signature_counter
        pre_handles = {row.get("wire_handle", "") for row in pre_wire_snapshot}
        post_handles = {row.get("wire_handle", "") for row in post_wire_snapshot}
        pre_handles.discard("")
        post_handles.discard("")
        added_wire_handle_count = len(post_handles - pre_handles)
        removed_wire_handle_count = len(pre_handles - post_handles)
        added_local_met1_signature_count = sum(
            count
            for signature, count in added_wire_signatures.items()
            if is_local_met1_wire_signature(signature)
        )
        removed_local_met1_signature_count = sum(
            count
            for signature, count in removed_wire_signatures.items()
            if is_local_met1_wire_signature(signature)
        )

        for net in EXPECTED_NETS:
            requested_width = 0.56 if net in R4_WIDE_NETS else 0.28
            net_local_added = [
                signature
                for signature, count in added_wire_signatures.items()
                for _ in range(count)
                if signature[0] == net and is_local_met1_wire_signature(signature)
            ]
            widths = sorted({signature[6] for signature in net_local_added})
            if any(width_matches(signature[6], requested_width) for signature in net_local_added):
                net_status = "REQUESTED_WIDTH_MATERIALIZED"
            elif any(width_matches(signature[6], 0.28) for signature in net_local_added):
                net_status = "CANONICALIZED_TO_0P28"
            elif net_local_added:
                net_status = "OTHER_LOCAL_MET1_DELTA"
            else:
                net_status = "NO_LOCAL_MET1_DELTA"
            if net in R4_WIDE_NETS:
                if net_status == "REQUESTED_WIDTH_MATERIALIZED":
                    requested_width_materialized_wide_net_count += 1
                elif net_status == "CANONICALIZED_TO_0P28":
                    canonicalized_wide_net_count += 1
                elif net_status == "NO_LOCAL_MET1_DELTA":
                    no_local_delta_wide_net_count += 1
            materialization_summary.append(
                {
                    "net": net,
                    "requested_width_um": f"{requested_width:.2f}",
                    "added_local_met1_signature_count": str(len(net_local_added)),
                    "added_local_met1_widths": " ".join(widths) if widths else "NONE",
                    "materialization_status": net_status,
                }
            )

        if requested_width_materialized_wide_net_count == 4:
            materialization_status = "REQUESTED_0P56_WIDTH_MATERIALIZED"
        elif canonicalized_wide_net_count == 4:
            materialization_status = "WIDE_REQUEST_CANONICALIZED_TO_0P28"
        elif no_local_delta_wide_net_count == 4:
            materialization_status = "NO_LOCAL_MET1_WIRE_DELTA"
        else:
            materialization_status = "MIXED_LOCAL_MET1_MATERIALIZATION"

    final_drc = counts.get("FINAL_DRC_VIOLATION_COUNT")
    final_markers = counts.get("FINAL_DRC_MARKER_COUNT")
    final_database = counts.get("FINAL_MARKER_DATABASE_TOTAL")
    final_antenna = counts.get("FINAL_EXCLUDED_ANTENNA_MARKER_COUNT")
    final_connectivity_markers = counts.get("FINAL_EXCLUDED_CONNECTIVITY_MARKER_COUNT")
    final_regular = counts.get("FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT")
    final_special = counts.get("FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT")
    if None not in (final_markers, final_database, final_antenna, final_connectivity_markers):
        if final_database != final_markers + final_antenna + final_connectivity_markers:
            errors.append(
                f"final_marker_database_accounting={final_database} expected="
                f"{final_markers + final_antenna + final_connectivity_markers}"
            )
    if len(post_markers) != (final_markers or 0):
        errors.append(f"post_marker_row_count={len(post_markers)} status={final_markers}")
    final_min_area_nets = tuple(
        sorted(
            marker_net(row)
            for row in post_markers
            if is_min_area_marker(row) and marker_net(row) != "UNKNOWN"
        )
    )
    if any(not is_min_area_marker(row) for row in post_markers):
        errors.append("post_marker_class_not_all_met1_min_area")
    if not set(final_min_area_nets).issubset(EXPECTED_NETS):
        errors.append(f"unexpected_post_marker_nets={final_min_area_nets}")
    if status.get("FINAL_MIN_AREA_NETS", "").split() != list(final_min_area_nets):
        errors.append(
            f"final_min_area_nets={status.get('FINAL_MIN_AREA_NETS', 'MISSING')} rows={final_min_area_nets}"
        )

    if is_r5 and status.get("MATERIALIZATION_CAPTURE_STATUS") != "COMPLETE":
        expected_process_result = "WIRE_MATERIALIZATION_CAPTURE_INCOMPLETE"
    elif command_fail_count and command_fail_count > 0:
        expected_process_result = "PATCH_COMMAND_FAILED"
    elif (final_regular or 0) != 0 or (final_special or 0) != 0 or (final_connectivity_markers or 0) != 0:
        expected_process_result = "PATCH_CONNECTIVITY_REGRESSION"
    elif final_antenna != 21:
        expected_process_result = "PATCH_RESTORED_ANTENNA_SENTINEL_CHANGED"
    elif (final_drc, final_markers, final_database, len(post_markers)) == (0, 0, 21, 0):
        expected_process_result = validated_result_name
    elif (
        (final_drc, final_markers, final_database) == (6, 6, 27)
        and final_min_area_nets == EXPECTED_NETS
    ):
        expected_process_result = no_improvement_result_name
    else:
        expected_process_result = changed_result_name

    expected_process_status = (
        "PASS" if expected_process_result == validated_result_name else "FAIL"
    )
    if status.get("RESULT") != expected_process_result:
        errors.append(
            f"trial_RESULT={status.get('RESULT', 'MISSING')} expected={expected_process_result}"
        )
    if status.get("STATUS") != expected_process_status:
        errors.append(
            f"trial_STATUS={status.get('STATUS', 'MISSING')} expected={expected_process_status}"
        )

    pre_signatures = sorted(marker_signature(row) for row in pre_markers)
    post_signatures = sorted(marker_signature(row) for row in post_markers)
    removed = sorted(set(pre_signatures) - set(post_signatures))
    added = sorted(set(post_signatures) - set(pre_signatures))
    validated = expected_process_result == validated_result_name and not errors
    if is_r5:
        analysis_label = "SPADMIC_TX_PACKET_MIN_AREA_LANDING_MATERIALIZATION_ANALYSIS"
        analysis_policy = (
            "ISOLATED_IN_MEMORY_R4_REPLAY_WIRE_MATERIALIZATION_CLASSIFICATION"
        )
        analysis_result = (
            "MIN_AREA_LANDING_MATERIALIZATION_PROBE_CLASSIFIED"
            if not errors
            else "MIN_AREA_LANDING_MATERIALIZATION_CLASSIFICATION_INCOMPLETE"
        )
        method_status = (
            "DIAGNOSTIC_CAPTURE_COMPLETE"
            if not errors
            else "DIAGNOSTIC_CAPTURE_INCOMPLETE"
        )
        contract_status = (
            "PASS_EXACT_SIX_R4_REPLAY_EXTENSIONS"
            if counts.get("CONTRACT_VALIDATED_COUNT") == 6
            else "FAIL"
        )
        if validated:
            next_method_decision = (
                "REVIEW_DRC_ZERO_MATERIALIZATION_PROBE_BEFORE_CANONICAL_INTEGRATION"
            )
        elif materialization_status == "REQUESTED_0P56_WIDTH_MATERIALIZED":
            next_method_decision = (
                "REVIEW_DRC_COUNTED_AREA_VERSUS_MATERIALIZED_0P56_WIRES"
            )
        elif materialization_status == "WIDE_REQUEST_CANONICALIZED_TO_0P28":
            next_method_decision = (
                "RETIRE_WIRE_EDITOR_WIDTH_CONTROL_REVIEW_NEW_REGULAR_WIRE_PRIMITIVE"
            )
        elif materialization_status == "NO_LOCAL_MET1_WIRE_DELTA":
            next_method_decision = (
                "RETIRE_WIRE_EDITOR_COMMAND_PASS_WITHOUT_LOCAL_WIRE_DELTA"
            )
        else:
            next_method_decision = "REVIEW_MIXED_WIRE_MATERIALIZATION_BEFORE_NEW_METHOD"
    else:
        analysis_label = "SPADMIC_TX_PACKET_MIN_AREA_LANDING_PATCH_ANALYSIS"
        analysis_policy = (
            "ISOLATED_IN_MEMORY_SIX_NET_MIXED_WIDTH_MET1_LANDING_PATCH_CLASSIFICATION"
            if is_r4
            else (
                "ISOLATED_IN_MEMORY_SIX_NET_MIXED_DIRECTION_MET1_LANDING_PATCH_CLASSIFICATION"
                if is_r3
                else (
                    "ISOLATED_IN_MEMORY_SIX_NET_MIXED_LENGTH_MET1_LANDING_PATCH_CLASSIFICATION"
                    if is_r2
                    else "ISOLATED_IN_MEMORY_SIX_NET_MET1_LANDING_PATCH_CLASSIFICATION"
                )
            )
        )
        analysis_result = (
            "MIN_AREA_LANDING_PATCH_TRIAL_CLASSIFIED"
            if not errors
            else "MIN_AREA_LANDING_PATCH_CLASSIFICATION_INCOMPLETE"
        )
        method_status = (
            "VALIDATED_ZERO_DRC_ZERO_CONNECTIVITY"
            if validated
            else "REJECTED_OR_INCOMPLETE"
        )
        contract_status = (
            (
                "PASS_EXACT_SIX_MIXED_WIDTH_EXTENSIONS"
                if is_r4
                else (
                    "PASS_EXACT_SIX_MIXED_DIRECTION_EXTENSIONS"
                    if is_r3
                    else (
                        "PASS_EXACT_SIX_MIXED_LENGTH_EXTENSIONS"
                        if is_r2
                        else "PASS_EXACT_SIX_REVIEWED_EXTENSIONS"
                    )
                )
            )
            if counts.get("CONTRACT_VALIDATED_COUNT") == 6
            else "FAIL"
        )
        if validated:
            next_method_decision = (
                "REVIEW_DRC_ZERO_MIXED_WIDTH_PATCH_BEFORE_CANONICAL_INTEGRATION"
                if is_r4
                else (
                    "REVIEW_DRC_ZERO_MIXED_DIRECTION_PATCH_BEFORE_CANONICAL_INTEGRATION"
                    if is_r3
                    else (
                        "REVIEW_DRC_ZERO_MIXED_LENGTH_PATCH_BEFORE_CANONICAL_INTEGRATION"
                        if is_r2
                        else "REVIEW_DRC_ZERO_PATCH_BEFORE_CANONICAL_INTEGRATION"
                    )
                )
            )
        else:
            next_method_decision = "STOP_AND_REVIEW_PATCH_EVIDENCE_BEFORE_NEW_METHOD"
    result = {
        "LABEL": analysis_label,
        "POLICY": analysis_policy,
        "STATUS": "PASS" if not errors else "FAIL",
        "RESULT": analysis_result,
        "TRIAL_ROOT": str(trial_root),
        "SOURCE_CHECKPOINT": context.get("SOURCE_CHECKPOINT", "MISSING"),
        "REPORT_DRIVER_HEAD": report_driver_head,
        "TRIAL_REVISION": trial_revision,
        "TRIAL_PROCESS_STATUS": status.get("STATUS", "MISSING"),
        "TRIAL_PROCESS_RESULT": status.get("RESULT", "MISSING"),
        "METHOD_STATUS": method_status,
        "PATCH_CONTRACT_STATUS": contract_status,
        "PATCH_WIDTH_POLICY": patch_width_policy,
        "PATCH_WIDTH_UM": patch_width_um,
        "PATCH_LENGTH_POLICY": patch_length_policy,
        "PATCH_LENGTH_UM": "MIXED_0.56_0.84" if is_r2 or is_r3 else "0.56",
        "PATCH_DIRECTION_POLICY": patch_direction_policy,
        "PATCH_ATTEMPTED_COUNT": status.get("PATCH_ATTEMPTED_COUNT", "UNKNOWN"),
        "PATCH_APPLIED_COUNT": status.get("PATCH_APPLIED_COUNT", "UNKNOWN"),
        "COMMAND_PASS_COUNT": status.get("COMMAND_PASS_COUNT", "UNKNOWN"),
        "COMMAND_FAIL_COUNT": status.get("COMMAND_FAIL_COUNT", "UNKNOWN"),
        "PRE_DRC_VIOLATION_COUNT": status.get("PRE_DRC_VIOLATION_COUNT", "UNKNOWN"),
        "FINAL_DRC_VIOLATION_COUNT": status.get("FINAL_DRC_VIOLATION_COUNT", "UNKNOWN"),
        "PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT": status.get("PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT", "UNKNOWN"),
        "FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT": status.get("FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT", "UNKNOWN"),
        "PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": status.get("PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT", "UNKNOWN"),
        "FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": status.get("FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT", "UNKNOWN"),
        "PRE_EXCLUDED_ANTENNA_MARKER_COUNT": status.get("PRE_EXCLUDED_ANTENNA_MARKER_COUNT", "UNKNOWN"),
        "FINAL_EXCLUDED_ANTENNA_MARKER_COUNT": status.get("FINAL_EXCLUDED_ANTENNA_MARKER_COUNT", "UNKNOWN"),
        "PRE_MARKER_DATABASE_TOTAL": status.get("PRE_MARKER_DATABASE_TOTAL", "UNKNOWN"),
        "FINAL_MARKER_DATABASE_TOTAL": status.get("FINAL_MARKER_DATABASE_TOTAL", "UNKNOWN"),
        "REMOVED_MARKER_SIGNATURE_COUNT": str(len(removed)),
        "ADDED_MARKER_SIGNATURE_COUNT": str(len(added)),
        "FINAL_MIN_AREA_NETS": status.get("FINAL_MIN_AREA_NETS", ""),
        "SAVE_DESIGN": "NOT_RUN",
        "EXPORT": "NOT_RUN",
        "IMMUTABLE_PVS_STAGING": "NOT_RUN",
        "PVS_DECISION": "DO_NOT_RUN",
        "CANONICAL_RERUN_DECISION": "DO_NOT_RUN_FROM_THIS_STEP",
        "NEXT_METHOD_DECISION": next_method_decision,
        "ERROR_COUNT": str(len(errors)),
    }
    if is_r5:
        result.update(
            {
                "MATERIALIZATION_CAPTURE_STATUS": status.get(
                    "MATERIALIZATION_CAPTURE_STATUS", "MISSING"
                ),
                "MATERIALIZATION_STATUS": materialization_status,
                "PRE_WIRE_QUERY_PASS_NET_COUNT": status.get(
                    "PRE_WIRE_QUERY_PASS_NET_COUNT", "UNKNOWN"
                ),
                "POST_WIRE_QUERY_PASS_NET_COUNT": status.get(
                    "POST_WIRE_QUERY_PASS_NET_COUNT", "UNKNOWN"
                ),
                "PRE_WIRE_ROW_COUNT": status.get("PRE_WIRE_ROW_COUNT", "UNKNOWN"),
                "POST_WIRE_ROW_COUNT": status.get("POST_WIRE_ROW_COUNT", "UNKNOWN"),
                "PRE_LOCAL_MET1_ROW_COUNT": status.get(
                    "PRE_LOCAL_MET1_ROW_COUNT", "UNKNOWN"
                ),
                "POST_LOCAL_MET1_ROW_COUNT": status.get(
                    "POST_LOCAL_MET1_ROW_COUNT", "UNKNOWN"
                ),
                "WIRE_ATTRIBUTE_FAIL_COUNT": status.get(
                    "WIRE_ATTRIBUTE_FAIL_COUNT", "UNKNOWN"
                ),
                "ADDED_WIRE_HANDLE_COUNT": str(added_wire_handle_count),
                "REMOVED_WIRE_HANDLE_COUNT": str(removed_wire_handle_count),
                "ADDED_WIRE_SIGNATURE_COUNT": str(
                    sum(added_wire_signatures.values())
                ),
                "REMOVED_WIRE_SIGNATURE_COUNT": str(
                    sum(removed_wire_signatures.values())
                ),
                "ADDED_LOCAL_MET1_SIGNATURE_COUNT": str(
                    added_local_met1_signature_count
                ),
                "REMOVED_LOCAL_MET1_SIGNATURE_COUNT": str(
                    removed_local_met1_signature_count
                ),
                "REQUESTED_WIDTH_MATERIALIZED_WIDE_NET_COUNT": str(
                    requested_width_materialized_wide_net_count
                ),
                "CANONICALIZED_WIDE_NET_COUNT": str(canonicalized_wide_net_count),
                "NO_LOCAL_DELTA_WIDE_NET_COUNT": str(no_local_delta_wide_net_count),
            }
        )

    evidence = [path for path in required if path.is_file()]
    lines = [f"{key}={value}" for key, value in result.items()]
    lines.extend(("", "PATCH_CONTRACT_TABLE_BEGIN"))
    if contract:
        lines.append("\t".join(contract[0].keys()))
        lines.extend("\t".join(row.values()) for row in contract)
    lines.append("PATCH_CONTRACT_TABLE_END")
    lines.extend(("", "FINAL_MARKER_TABLE_BEGIN"))
    if post_markers:
        lines.append("\t".join(post_markers[0].keys()))
        lines.extend("\t".join(row.values()) for row in post_markers)
    lines.append("FINAL_MARKER_TABLE_END")
    lines.extend(("", "MARKER_DELTA_BEGIN"))
    lines.extend(f"REMOVED\t{' | '.join(signature)}" for signature in removed)
    lines.extend(f"ADDED\t{' | '.join(signature)}" for signature in added)
    if not removed and not added:
        lines.append("NONE")
    lines.append("MARKER_DELTA_END")
    if is_r5:
        lines.extend(("", "WIRE_MATERIALIZATION_SUMMARY_TABLE_BEGIN"))
        if materialization_summary:
            lines.append("\t".join(materialization_summary[0].keys()))
            lines.extend("\t".join(row.values()) for row in materialization_summary)
        lines.append("WIRE_MATERIALIZATION_SUMMARY_TABLE_END")
        lines.extend(("", "WIRE_SIGNATURE_DELTA_BEGIN"))
        lines.append("action\tcount\t" + "\t".join(WIRE_SIGNATURE_FIELDS))
        for action, signatures in (
            ("REMOVED", removed_wire_signatures),
            ("ADDED", added_wire_signatures),
        ):
            for signature, count in sorted(signatures.items()):
                lines.append(f"{action}\t{count}\t" + "\t".join(signature))
        if not removed_wire_signatures and not added_wire_signatures:
            lines.append("NONE")
        lines.append("WIRE_SIGNATURE_DELTA_END")
    lines.extend(("", "ERRORS_BEGIN"))
    lines.extend(errors or ["NONE"])
    lines.extend(("ERRORS_END", "", "EVIDENCE_HASHES_BEGIN"))
    lines.extend(f"{digest(path)}  {path}" for path in evidence)
    lines.append("EVIDENCE_HASHES_END")
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text("\n".join(lines) + "\n")
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--trial-root", type=Path, required=True)
    parser.add_argument("--source-analysis", type=Path)
    parser.add_argument("--step20-analysis", type=Path)
    parser.add_argument("--step21-analysis", type=Path)
    parser.add_argument("--step22-analysis", type=Path)
    parser.add_argument("--step23-analysis", type=Path)
    parser.add_argument("--step24-analysis", type=Path)
    parser.add_argument(
        "--trial-revision", choices=("R1", "R2", "R3", "R4", "R5"), default="R1"
    )
    parser.add_argument("--report-driver-head", required=True)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    source_analysis = (
        args.source_analysis
        or args.step24_analysis
        or args.step23_analysis
        or args.step22_analysis
        or args.step21_analysis
        or args.step20_analysis
    )
    expected_alias = {
        "R1": args.step20_analysis,
        "R2": args.step21_analysis,
        "R3": args.step22_analysis,
        "R4": args.step23_analysis,
        "R5": args.step24_analysis,
    }[args.trial_revision]
    if source_analysis is None:
        parser.error("one source analysis argument is required")
    if expected_alias is None and args.source_analysis is None:
        parser.error(
            f"--{dict(R1='step20', R2='step21', R3='step22', R4='step23', R5='step24')[args.trial_revision]}-analysis "
            f"is required for {args.trial_revision}"
        )
    result = classify(
        args.trial_root.resolve(),
        source_analysis.resolve(),
        args.report_driver_head,
        args.report.resolve(),
        args.trial_revision,
    )
    print(args.report.read_text(), end="")
    return 0 if result["STATUS"] == "PASS" else 8


if __name__ == "__main__":
    raise SystemExit(main())
