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
EXPECTED_POLICY_R6 = (
    "ONE_FRESH_PROCESS_ONE_RESTORE_SIX_BASE_STUBS_THEN_FOUR_CHAINED_ENDPOINT_STUBS"
)
EXPECTED_POLICY_R7 = (
    "ONE_FRESH_PROCESS_ONE_RESTORE_SIX_BASE_STUBS_THEN_FOUR_NORMALIZED_VIA_SIDE_STUBS"
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
VALIDATED_RESULT_R6 = "CHAINED_ENDPOINT_MET1_LANDING_EXTENSIONS_DRC_ZERO_VALIDATED"
NO_IMPROVEMENT_RESULT_R6 = "CHAINED_ENDPOINT_MET1_LANDING_EXTENSIONS_NO_IMPROVEMENT"
VALIDATED_RESULT_R7 = (
    "NORMALIZED_VIA_SIDE_MET1_LANDING_EXTENSIONS_DRC_ZERO_VALIDATED"
)
NO_IMPROVEMENT_RESULT_R7 = (
    "NORMALIZED_VIA_SIDE_MET1_LANDING_EXTENSIONS_NO_IMPROVEMENT"
)
R6_CHAIN_CONTRACT = {
    "n_9696": ("719.69 158.62 720.07 158.90", "719.495", "158.795", "718.935", "TOWARD_SOURCE_WEST", "g14627__2802/Q"),
    "n_9693": ("210.09 201.74 210.47 202.02", "209.895", "201.845", "209.335", "TOWARD_SOURCE_WEST", "g14630__8246/Q"),
    "n_9697": ("663.13 192.78 663.51 193.06", "662.935", "192.885", "662.375", "TOWARD_SOURCE_WEST", "g14626__1617/Q"),
    "n_9677": ("1666.09 201.74 1666.47 202.02", "1666.665", "201.845", "1667.225", "TOWARD_SOURCE_EAST", "g14646__2398/Q"),
}
R7_VIA_SIDE_CONTRACT = {
    "n_9696": (
        "719.69 158.62 720.07 158.90",
        "719.495",
        "158.795",
        "719.880",
        "158.795",
        "720.440",
        "AWAY_FROM_SOURCE_EAST",
        "g14627__2802/Q",
    ),
    "n_9693": (
        "210.09 201.74 210.47 202.02",
        "209.895",
        "201.845",
        "210.280",
        "201.845",
        "210.840",
        "AWAY_FROM_SOURCE_EAST",
        "g14630__8246/Q",
    ),
    "n_9697": (
        "663.13 192.78 663.51 193.06",
        "662.935",
        "192.885",
        "663.320",
        "192.885",
        "663.880",
        "AWAY_FROM_SOURCE_EAST",
        "g14626__1617/Q",
    ),
    "n_9677": (
        "1666.09 201.74 1666.47 202.02",
        "1666.665",
        "201.845",
        "1666.280",
        "201.845",
        "1665.720",
        "AWAY_FROM_SOURCE_WEST",
        "g14646__2398/Q",
    ),
}

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


def is_local_layer_wire_signature(
    signature: tuple[str, ...], layer_name: str
) -> bool:
    relation = signature[1]
    layer = signature[3]
    return bool(
        layer.upper() == layer_name
        and relation in {"INTERSECTS_MARKER", "WITHIN_2UM_CONTEXT"}
    )


def is_local_met1_wire_signature(signature: tuple[str, ...]) -> bool:
    return is_local_layer_wire_signature(signature, "MET1")


def is_local_met2_wire_signature(signature: tuple[str, ...]) -> bool:
    return is_local_layer_wire_signature(signature, "MET2")


def width_matches(raw: str, expected: float) -> bool:
    try:
        return abs(float(raw) - expected) <= 0.001
    except ValueError:
        return False


def is_canonical_fixed_met1_stub(signature: tuple[str, ...]) -> bool:
    box = numeric_box(signature[2])
    box_width = abs(box[2] - box[0]) if box else None
    box_height = abs(box[3] - box[1]) if box else None
    return bool(
        is_local_met1_wire_signature(signature)
        and box_width is not None
        and box_height is not None
        and abs(box_width - 0.50) <= 0.001
        and abs(box_height - 0.23) <= 0.001
        and signature[4].lower() == "fixed"
        and signature[5] == "0x0"
        and width_matches(signature[6], 0.23)
        and width_matches(signature[7], 0.385)
    )


def classify(
    trial_root: Path,
    source_analysis: Path,
    report_driver_head: str,
    report: Path,
    trial_revision: str = "R1",
) -> dict[str, str]:
    if trial_revision not in {"R1", "R2", "R3", "R4", "R5", "R6", "R7"}:
        raise ValueError(f"unsupported trial revision: {trial_revision}")
    is_r2 = trial_revision == "R2"
    is_r3 = trial_revision == "R3"
    is_r4 = trial_revision == "R4"
    is_r5 = trial_revision == "R5"
    is_r6 = trial_revision == "R6"
    is_r7 = trial_revision == "R7"
    is_multistage = is_r6 or is_r7
    if is_r7:
        source_key = "STEP27_ANALYSIS"
        expected_policy = EXPECTED_POLICY_R7
        expected_contract = EXPECTED_CONTRACT
        command_policy = (
            "EXACT_SIX_BASE_STUBS_THEN_FOUR_NORMALIZED_VIA_ENDPOINT_"
            "OPPOSITE_SIDE_STUBS"
        )
        patch_length_policy = (
            "FIRST_STAGE_SIX_0.56_SECOND_STAGE_FOUR_NORMALIZED_VIA_SIDE_0.56"
        )
        patch_direction_policy = (
            "FIRST_STAGE_ALL_TOWARD_SOURCE_SECOND_STAGE_FOUR_AWAY_FROM_SOURCE"
        )
        patch_width_policy = "UNIFORM_0.28"
        patch_width_um = "0.28"
        validated_result_name = VALIDATED_RESULT_R7
        no_improvement_result_name = NO_IMPROVEMENT_RESULT_R7
        changed_result_name = (
            "NORMALIZED_VIA_SIDE_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED"
        )
    elif is_r6:
        source_key = "STEP26_ANALYSIS"
        expected_policy = EXPECTED_POLICY_R6
        expected_contract = EXPECTED_CONTRACT
        command_policy = "EXACT_SIX_BASE_STUBS_THEN_FOUR_ACTUAL_ENDPOINT_CHAIN_STUBS"
        patch_length_policy = "FIRST_STAGE_SIX_0.56_SECOND_STAGE_FOUR_DYNAMIC_0.56"
        patch_direction_policy = "ALL_TOWARD_SOURCE"
        patch_width_policy = "UNIFORM_0.28"
        patch_width_um = "0.28"
        validated_result_name = VALIDATED_RESULT_R6
        no_improvement_result_name = NO_IMPROVEMENT_RESULT_R6
        changed_result_name = (
            "CHAINED_ENDPOINT_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED"
        )
    elif is_r5:
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
    base_drc_path = reports / "verify_drc_after_base_stage.rpt"
    base_markers_path = reports / "drc_markers_after_base_stage.tsv"
    base_regular_path = reports / "verify_connectivity_regular_after_base_stage.rpt"
    base_special_path = reports / "verify_connectivity_special_after_base_stage.rpt"
    base_wire_snapshot_path = reports / "wire_snapshot_after_base_stage.tsv"
    chain_contract_path = reports / "min_area_chained_endpoint_contract.tsv"
    post_chain_wire_snapshot_path = reports / "wire_snapshot_post_chain_stage.tsv"
    via_side_contract_path = reports / "min_area_normalized_via_side_contract.tsv"
    post_via_side_wire_snapshot_path = (
        reports / "wire_snapshot_post_via_side_stage.tsv"
    )
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
    if is_multistage:
        required.extend(
            (
                base_drc_path,
                base_markers_path,
                base_regular_path,
                base_special_path,
                base_wire_snapshot_path,
            )
        )
    if is_r6:
        required.extend((chain_contract_path, post_chain_wire_snapshot_path))
    if is_r7:
        required.extend((via_side_contract_path, post_via_side_wire_snapshot_path))

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
    base_markers = read_tsv(base_markers_path) if is_multistage else []
    base_wire_snapshot = read_tsv(base_wire_snapshot_path) if is_multistage else []
    chain_contract = read_tsv(chain_contract_path) if is_r6 else []
    post_chain_wire_snapshot = (
        read_tsv(post_chain_wire_snapshot_path) if is_r6 else []
    )
    via_side_contract = read_tsv(via_side_contract_path) if is_r7 else []
    post_via_side_wire_snapshot = (
        read_tsv(post_via_side_wire_snapshot_path) if is_r7 else []
    )

    if is_r7:
        expected_source = {
            "LABEL": "SPADMIC_TX_PACKET_MIN_AREA_CHAINED_LANDING_ANALYSIS",
            "POLICY": (
                "ISOLATED_IN_MEMORY_SIX_BASE_THEN_FOUR_CHAINED_ENDPOINT_"
                "CLASSIFICATION"
            ),
            "STATUS": "PASS",
            "RESULT": "MIN_AREA_CHAINED_LANDING_TRIAL_CLASSIFIED",
            "TRIAL_REVISION": "R6",
            "TRIAL_PROCESS_STATUS": "FAIL",
            "TRIAL_PROCESS_RESULT": (
                "CHAINED_ENDPOINT_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED"
            ),
            "METHOD_STATUS": "REJECTED_OR_INCOMPLETE",
            "PATCH_CONTRACT_STATUS": (
                "PASS_EXACT_SIX_BASE_AND_FOUR_CHAIN_ENDPOINTS"
            ),
            "PATCH_WIDTH_POLICY": "UNIFORM_0.28",
            "PATCH_WIDTH_UM": "0.28",
            "PATCH_LENGTH_POLICY": (
                "FIRST_STAGE_SIX_0.56_SECOND_STAGE_FOUR_DYNAMIC_0.56"
            ),
            "PATCH_LENGTH_UM": "0.56",
            "PATCH_DIRECTION_POLICY": "ALL_TOWARD_SOURCE",
            "PATCH_ATTEMPTED_COUNT": "10",
            "PATCH_APPLIED_COUNT": "10",
            "COMMAND_PASS_COUNT": "40",
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
            "NEXT_METHOD_DECISION": (
                "STOP_AND_REVIEW_CHAINED_ENDPOINT_EVIDENCE_BEFORE_NEW_METHOD"
            ),
            "ERROR_COUNT": "0",
            "CHAIN_CAPTURE_STATUS": "COMPLETE",
            "BASE_STAGE_STATUS": "PASS_EXACT_FOUR_0P1777_SURVIVORS",
            "BASE_DRC_VIOLATION_COUNT": "4",
            "BASE_DRC_MARKER_COUNT": "4",
            "BASE_MIN_AREA_NETS": "n_9677 n_9693 n_9696 n_9697",
            "BASE_REGULAR_CONNECTIVITY_VIOLATION_COUNT": "0",
            "BASE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": "0",
            "BASE_EXCLUDED_ANTENNA_MARKER_COUNT": "21",
            "BASE_MARKER_DATABASE_TOTAL": "25",
            "BASE_CANONICAL_FIXED_STUB_NET_COUNT": "6",
            "CHAIN_ENDPOINT_CONTRACT_STATUS": (
                "PASS_EXACT_FOUR_ACTUAL_CANONICAL_ENDPOINTS"
            ),
            "CHAIN_ENDPOINT_CONTRACT_VALIDATED_COUNT": "4",
            "CHAIN_STAGE_STATUS": "APPLIED_EXACT_FOUR",
            "BASE_PATCH_ATTEMPTED_COUNT": "6",
            "BASE_PATCH_APPLIED_COUNT": "6",
            "CHAIN_PATCH_ATTEMPTED_COUNT": "4",
            "CHAIN_PATCH_APPLIED_COUNT": "4",
        }
    elif is_r6:
        expected_source = {
            "LABEL": "SPADMIC_TX_PACKET_MIN_AREA_LANDING_MATERIALIZATION_ANALYSIS",
            "POLICY": "ISOLATED_IN_MEMORY_R4_REPLAY_WIRE_MATERIALIZATION_CLASSIFICATION",
            "STATUS": "PASS",
            "RESULT": "MIN_AREA_LANDING_MATERIALIZATION_PROBE_CLASSIFIED",
            "TRIAL_REVISION": "R5",
            "TRIAL_PROCESS_STATUS": "FAIL",
            "TRIAL_PROCESS_RESULT": "WIRE_MATERIALIZATION_REPLAY_CHANGED_NOT_CLOSED",
            "METHOD_STATUS": "DIAGNOSTIC_CAPTURE_COMPLETE",
            "PATCH_CONTRACT_STATUS": "PASS_EXACT_SIX_R4_REPLAY_EXTENSIONS",
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
            "NEXT_METHOD_DECISION": "COMPARE_CLOSED_CONTROL_AND_SURVIVOR_LANDING_COMPONENT_GEOMETRY",
            "ERROR_COUNT": "0",
            "MATERIALIZATION_CAPTURE_STATUS": "COMPLETE",
            "MATERIALIZATION_STATUS": "UNIFORM_FIXED_0P23_BY_0P385_MET1_WITH_MET2_SPLIT",
            "PRE_WIRE_QUERY_PASS_NET_COUNT": "6",
            "POST_WIRE_QUERY_PASS_NET_COUNT": "6",
            "PRE_LOCAL_MET1_ROW_COUNT": "0",
            "POST_LOCAL_MET1_ROW_COUNT": "6",
            "WIRE_ATTRIBUTE_FAIL_COUNT": "0",
            "ADDED_LOCAL_MET1_SIGNATURE_COUNT": "6",
            "REMOVED_LOCAL_MET1_SIGNATURE_COUNT": "0",
            "ADDED_LOCAL_MET2_SIGNATURE_COUNT": "12",
            "REMOVED_LOCAL_MET2_SIGNATURE_COUNT": "6",
            "CANONICAL_FIXED_STUB_NET_COUNT": "6",
            "MET2_SPLIT_NET_COUNT": "6",
            "MATERIALIZED_MET1_WIDTH_UM": "0.23",
            "MATERIALIZED_MET1_CENTERLINE_LENGTH_UM": "0.385",
            "WIRE_EDITOR_PARAMETER_CONTROL_STATUS": "REQUESTED_WIDTH_AND_ENDPOINT_NORMALIZED",
            "CLOSED_CONTROL_MATERIALIZATION_MATCH_STATUS": "PASS_SAME_CANONICAL_STUB_CLASS_AS_SURVIVORS",
            "PATCH_PARAMETER_SWEEP_DECISION": "RETIRED_LENGTH_DIRECTION_AND_WIDTH",
            "REQUESTED_WIDTH_MATERIALIZED_WIDE_NET_COUNT": "0",
            "CANONICALIZED_WIDE_NET_COUNT": "0",
            "NO_LOCAL_DELTA_WIDE_NET_COUNT": "0",
        }
    elif is_r5:
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
    if is_r3 or is_r4 or is_r5 or is_multistage:
        expected_status["PATCH_DIRECTION_POLICY"] = patch_direction_policy
    if is_r4 or is_r5 or is_multistage:
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
    if is_r6:
        expected_status.update(
            {
                "CHAIN_CAPTURE_POLICY": (
                    "EXACT_FOUR_SURVIVOR_ACTUAL_ENDPOINTS_AFTER_VALIDATED_BASE_STAGE"
                ),
                "BASE_STAGE_STATUS": "PASS_EXACT_FOUR_0P1777_SURVIVORS",
                "BASE_MARKER_VALUE_STATUS": "PASS",
                "CHAIN_ENDPOINT_CONTRACT_STATUS": (
                    "PASS_EXACT_FOUR_ACTUAL_CANONICAL_ENDPOINTS"
                ),
                "CHAIN_STAGE_STATUS": "APPLIED_EXACT_FOUR",
                "BASE_MIN_AREA_NETS": "n_9677 n_9693 n_9696 n_9697",
            }
        )
    if is_r7:
        expected_status.update(
            {
                "VIA_SIDE_CAPTURE_POLICY": (
                    "EXACT_FOUR_SURVIVOR_NORMALIZED_VIA_ENDPOINTS_AFTER_"
                    "VALIDATED_BASE_STAGE"
                ),
                "BASE_STAGE_STATUS": "PASS_EXACT_FOUR_0P1777_SURVIVORS",
                "BASE_MARKER_VALUE_STATUS": "PASS",
                "VIA_SIDE_ENDPOINT_CONTRACT_STATUS": (
                    "PASS_EXACT_FOUR_ACTUAL_NORMALIZED_VIA_ENDPOINTS"
                ),
                "VIA_SIDE_STAGE_STATUS": "APPLIED_EXACT_FOUR",
                "BASE_MIN_AREA_NETS": "n_9677 n_9693 n_9696 n_9697",
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
    if is_multistage:
        for key in (
            "BASE_DRC_VIOLATION_COUNT",
            "BASE_DRC_MARKER_COUNT",
            "BASE_MARKER_DATABASE_TOTAL",
            "BASE_EXCLUDED_ANTENNA_MARKER_COUNT",
            "BASE_EXCLUDED_CONNECTIVITY_MARKER_COUNT",
            "BASE_REGULAR_CONNECTIVITY_VIOLATION_COUNT",
            "BASE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT",
            "BASE_WIRE_QUERY_PASS_NET_COUNT",
            "BASE_WIRE_ROW_COUNT",
            "BASE_LOCAL_MET1_ROW_COUNT",
            "BASE_WIRE_ATTRIBUTE_FAIL_COUNT",
            "BASE_PATCH_ATTEMPTED_COUNT",
            "BASE_PATCH_APPLIED_COUNT",
        ):
            counts[key] = integer(status, key, errors)
    if is_r6:
        for key in (
            "CHAIN_ENDPOINT_CONTRACT_VALIDATED_COUNT",
            "POST_CHAIN_WIRE_QUERY_PASS_NET_COUNT",
            "POST_CHAIN_WIRE_ROW_COUNT",
            "POST_CHAIN_LOCAL_MET1_ROW_COUNT",
            "POST_CHAIN_WIRE_ATTRIBUTE_FAIL_COUNT",
            "CHAIN_PATCH_ATTEMPTED_COUNT",
            "CHAIN_PATCH_APPLIED_COUNT",
        ):
            counts[key] = integer(status, key, errors)
    if is_r7:
        for key in (
            "VIA_SIDE_ENDPOINT_CONTRACT_VALIDATED_COUNT",
            "POST_VIA_SIDE_WIRE_QUERY_PASS_NET_COUNT",
            "POST_VIA_SIDE_WIRE_ROW_COUNT",
            "POST_VIA_SIDE_LOCAL_MET1_ROW_COUNT",
            "POST_VIA_SIDE_WIRE_ATTRIBUTE_FAIL_COUNT",
            "VIA_SIDE_PATCH_ATTEMPTED_COUNT",
            "VIA_SIDE_PATCH_APPLIED_COUNT",
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
    if is_multistage:
        report_counts.update(
            {
                "BASE_DRC_VIOLATION_COUNT": report_violation_count(base_drc_path),
                "BASE_REGULAR_CONNECTIVITY_VIOLATION_COUNT": report_violation_count(
                    base_regular_path
                ),
                "BASE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": report_violation_count(
                    base_special_path
                ),
            }
        )
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

    if is_multistage:
        expected_base_counts = {
            "BASE_DRC_VIOLATION_COUNT": 4,
            "BASE_DRC_MARKER_COUNT": 4,
            "BASE_MARKER_DATABASE_TOTAL": 25,
            "BASE_EXCLUDED_ANTENNA_MARKER_COUNT": 21,
            "BASE_EXCLUDED_CONNECTIVITY_MARKER_COUNT": 0,
            "BASE_REGULAR_CONNECTIVITY_VIOLATION_COUNT": 0,
            "BASE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": 0,
            "BASE_WIRE_QUERY_PASS_NET_COUNT": 6,
            "BASE_LOCAL_MET1_ROW_COUNT": 6,
            "BASE_WIRE_ATTRIBUTE_FAIL_COUNT": 0,
            "BASE_PATCH_ATTEMPTED_COUNT": 6,
            "BASE_PATCH_APPLIED_COUNT": 6,
        }
        if is_r6:
            expected_base_counts.update(
                {
                    "CHAIN_ENDPOINT_CONTRACT_VALIDATED_COUNT": 4,
                    "POST_CHAIN_WIRE_QUERY_PASS_NET_COUNT": 6,
                    "POST_CHAIN_WIRE_ATTRIBUTE_FAIL_COUNT": 0,
                    "CHAIN_PATCH_ATTEMPTED_COUNT": 4,
                    "CHAIN_PATCH_APPLIED_COUNT": 4,
                }
            )
        else:
            expected_base_counts.update(
                {
                    "VIA_SIDE_ENDPOINT_CONTRACT_VALIDATED_COUNT": 4,
                    "POST_VIA_SIDE_WIRE_QUERY_PASS_NET_COUNT": 6,
                    "POST_VIA_SIDE_WIRE_ATTRIBUTE_FAIL_COUNT": 0,
                    "VIA_SIDE_PATCH_ATTEMPTED_COUNT": 4,
                    "VIA_SIDE_PATCH_APPLIED_COUNT": 4,
                }
            )
        for key, expected in expected_base_counts.items():
            if counts.get(key) != expected:
                errors.append(
                    f"{trial_revision.lower()}_{key}={counts.get(key)} "
                    f"expected={expected}"
                )
        expected_base_nets = tuple(
            sorted(R6_CHAIN_CONTRACT if is_r6 else R7_VIA_SIDE_CONTRACT)
        )
        base_nets = tuple(sorted(marker_net(row) for row in base_markers))
        if len(base_markers) != 4 or base_nets != expected_base_nets:
            errors.append(
                f"{trial_revision.lower()}_base_marker_rows={len(base_markers)} "
                f"nets={base_nets} "
                f"expected={expected_base_nets}"
            )
        for row in base_markers:
            net = marker_net(row)
            if not is_min_area_marker(row):
                errors.append(
                    f"{trial_revision.lower()}_base_marker_class={net}"
                )
            if not re.search(
                r"Actual:\s+0[.]17770000\s+Required:\s+0[.]20200000",
                row.get("message", ""),
                re.IGNORECASE,
            ):
                errors.append(
                    f"{trial_revision.lower()}_base_marker_value="
                    f"{net}:{row.get('message', '')}"
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
        if is_r3 or is_r4 or is_r5 or is_multistage:
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
    if is_r3 or is_r4 or is_r5 or is_multistage:
        expected_commands["PATCH_DIRECTION_POLICY"] = patch_direction_policy
    if is_r4 or is_r5 or is_multistage:
        expected_commands["PATCH_WIDTH_POLICY"] = patch_width_policy
    if is_r5:
        expected_commands["MATERIALIZATION_CAPTURE_POLICY"] = (
            "PRE_AND_POST_ALL_WIRES_WITH_LOCAL_MET1_CLASSIFICATION"
        )
    if is_r6:
        expected_commands.update(
            {
                "CHAIN_CAPTURE_POLICY": (
                    "EXACT_FOUR_SURVIVOR_ACTUAL_ENDPOINTS_AFTER_VALIDATED_BASE_STAGE"
                ),
                "BASE_STAGE_STATUS": "PASS_EXACT_FOUR_0P1777_SURVIVORS",
                "CHAIN_ENDPOINT_CONTRACT_VALIDATED_COUNT": "4",
                "BASE_PATCH_ATTEMPTED_COUNT": "6",
                "BASE_PATCH_APPLIED_COUNT": "6",
                "CHAIN_PATCH_ATTEMPTED_COUNT": "4",
                "CHAIN_PATCH_APPLIED_COUNT": "4",
            }
        )
    if is_r7:
        expected_commands.update(
            {
                "VIA_SIDE_CAPTURE_POLICY": (
                    "EXACT_FOUR_SURVIVOR_NORMALIZED_VIA_ENDPOINTS_AFTER_"
                    "VALIDATED_BASE_STAGE"
                ),
                "BASE_STAGE_STATUS": "PASS_EXACT_FOUR_0P1777_SURVIVORS",
                "VIA_SIDE_ENDPOINT_CONTRACT_VALIDATED_COUNT": "4",
                "BASE_PATCH_ATTEMPTED_COUNT": "6",
                "BASE_PATCH_APPLIED_COUNT": "6",
                "VIA_SIDE_PATCH_ATTEMPTED_COUNT": "4",
                "VIA_SIDE_PATCH_APPLIED_COUNT": "4",
            }
        )
    for key, expected in expected_commands.items():
        if commands.get(key) != expected:
            errors.append(f"commands_{key}={commands.get(key, 'MISSING')} expected={expected}")
    command_status_keys = [
        "PATCH_ATTEMPTED_COUNT",
        "PATCH_APPLIED_COUNT",
        "COMMAND_PASS_COUNT",
        "COMMAND_FAIL_COUNT",
    ]
    if is_r6:
        command_status_keys.extend(
            (
                "BASE_PATCH_ATTEMPTED_COUNT",
                "BASE_PATCH_APPLIED_COUNT",
                "CHAIN_PATCH_ATTEMPTED_COUNT",
                "CHAIN_PATCH_APPLIED_COUNT",
                "CHAIN_ENDPOINT_CONTRACT_VALIDATED_COUNT",
            )
        )
    if is_r7:
        command_status_keys.extend(
            (
                "BASE_PATCH_ATTEMPTED_COUNT",
                "BASE_PATCH_APPLIED_COUNT",
                "VIA_SIDE_PATCH_ATTEMPTED_COUNT",
                "VIA_SIDE_PATCH_APPLIED_COUNT",
                "VIA_SIDE_ENDPOINT_CONTRACT_VALIDATED_COUNT",
            )
        )
    for key in command_status_keys:
        if commands.get(key) != status.get(key):
            errors.append(f"commands_status_mismatch_{key}={commands.get(key)}:{status.get(key)}")

    command_fail_count = counts.get("COMMAND_FAIL_COUNT")
    command_pass_count = counts.get("COMMAND_PASS_COUNT")
    patch_attempted = counts.get("PATCH_ATTEMPTED_COUNT")
    patch_applied = counts.get("PATCH_APPLIED_COUNT")
    if command_fail_count == 0:
        expected_success_tuple = (
            (40, 10, 10) if is_multistage else (24, 6, 6)
        )
        if (command_pass_count, patch_attempted, patch_applied) != expected_success_tuple:
            errors.append(
                "unexpected_success_command_tuple="
                f"{command_pass_count},{patch_attempted},{patch_applied} "
                f"expected={','.join(str(value) for value in expected_success_tuple)}"
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
            if is_r4 or is_r5 or is_multistage:
                expected_commands_for_net[f"{prefix}_WIDTH_UM"] = expected_width
            if is_r3 or is_r4 or is_r5 or is_multistage:
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
        if is_r6:
            for net, expected in R6_CHAIN_CONTRACT.items():
                prefix = f"CHAIN_{net}"
                expected_chain_commands = {
                    f"{prefix}_START": f"{expected[1]} {expected[2]}",
                    f"{prefix}_END": f"{expected[3]} {expected[2]}",
                    f"{prefix}_LENGTH_UM": "0.56",
                    f"{prefix}_WIDTH_UM": "0.28",
                    f"{prefix}_DIRECTION": expected[4],
                    f"{prefix}_SOURCE_Q": expected[5],
                    f"{prefix}_APPLIED": "YES",
                }
                for key, value in expected_chain_commands.items():
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
                        "-width_horizontal 0.28",
                        "-width_vertical 0.28",
                    )
                ):
                    errors.append(f"commands_{prefix}_SET_EDIT_MODE_contract_mismatch")
        if is_r7:
            for net, expected in R7_VIA_SIDE_CONTRACT.items():
                prefix = f"VIA_SIDE_{net}"
                expected_via_side_commands = {
                    f"{prefix}_START": f"{expected[3]} {expected[4]}",
                    f"{prefix}_END": f"{expected[5]} {expected[4]}",
                    f"{prefix}_LENGTH_UM": "0.56",
                    f"{prefix}_WIDTH_UM": "0.28",
                    f"{prefix}_DIRECTION": expected[6],
                    f"{prefix}_SOURCE_Q": expected[7],
                    f"{prefix}_APPLIED": "YES",
                }
                for key, value in expected_via_side_commands.items():
                    if commands.get(key) != value:
                        errors.append(
                            f"commands_{key}={commands.get(key, 'MISSING')} "
                            f"expected={value}"
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
                        "-width_horizontal 0.28",
                        "-width_vertical 0.28",
                    )
                ):
                    errors.append(
                        f"commands_{prefix}_SET_EDIT_MODE_contract_mismatch"
                    )
    elif command_fail_count is not None:
        maximum_attempts = 10 if is_multistage else 6
        if (
            command_fail_count < 1
            or patch_attempted is None
            or not 1 <= patch_attempted <= maximum_attempts
        ):
            errors.append("invalid_failed_command_tuple")
    if is_r5 and (
        counts.get("PATCH_ATTEMPTED_COUNT"),
        counts.get("PATCH_APPLIED_COUNT"),
        counts.get("COMMAND_PASS_COUNT"),
        counts.get("COMMAND_FAIL_COUNT"),
    ) != (6, 6, 24, 0):
        errors.append("r5_replay_command_tuple_not_exact_6_6_24_0")

    via_side_materialized_net_count = 0
    via_side_no_local_delta_net_count = 0
    via_side_control_stability_status = "NOT_APPLICABLE"
    via_side_materialization_summary: list[dict[str, str]] = []
    if is_multistage:
        post_stage_phase = (
            "AFTER_CHAIN_STAGE" if is_r6 else "AFTER_VIA_SIDE_STAGE"
        )
        post_stage_rows = (
            post_chain_wire_snapshot if is_r6 else post_via_side_wire_snapshot
        )
        post_stage_row_count_key = (
            "POST_CHAIN_WIRE_ROW_COUNT"
            if is_r6
            else "POST_VIA_SIDE_WIRE_ROW_COUNT"
        )
        post_stage_local_count_key = (
            "POST_CHAIN_LOCAL_MET1_ROW_COUNT"
            if is_r6
            else "POST_VIA_SIDE_LOCAL_MET1_ROW_COUNT"
        )
        error_prefix = trial_revision.lower()
        for phase, rows, row_count_key, local_count_key in (
            (
                "AFTER_BASE_STAGE",
                base_wire_snapshot,
                "BASE_WIRE_ROW_COUNT",
                "BASE_LOCAL_MET1_ROW_COUNT",
            ),
            (
                post_stage_phase,
                post_stage_rows,
                post_stage_row_count_key,
                post_stage_local_count_key,
            ),
        ):
            for row in rows:
                net = row.get("net", "")
                if row.get("phase") != phase:
                    errors.append(
                        f"{error_prefix}_wire_snapshot_phase="
                        f"{row.get('phase', 'MISSING')} expected={phase}"
                    )
                if net not in EXPECTED_CONTRACT:
                    errors.append(
                        f"{error_prefix}_wire_snapshot_unexpected_net="
                        f"{net or 'MISSING'}"
                    )
                    continue
                if not boxes_match(
                    row.get("marker_box", ""), EXPECTED_CONTRACT[net][0]
                ):
                    errors.append(
                        f"{error_prefix}_wire_snapshot_{phase}_{net}_"
                        "marker_box_mismatch"
                    )
                if row.get("requested_width_um") != "0.28":
                    errors.append(
                        f"{error_prefix}_wire_snapshot_{phase}_{net}_requested_width="
                        f"{row.get('requested_width_um', 'MISSING')} expected=0.28"
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
                            f"{error_prefix}_wire_snapshot_{phase}_{net}_{field}="
                            f"{row.get(field, 'MISSING')} expected=PASS"
                        )
            snapshot_nets = {row.get("net", "") for row in rows}
            if snapshot_nets != set(EXPECTED_NETS):
                errors.append(
                    f"{error_prefix}_wire_snapshot_{phase}_nets="
                    f"{sorted(snapshot_nets)} "
                    f"expected={list(EXPECTED_NETS)}"
                )
            local_met1_count = sum(
                1
                for row in rows
                if is_local_met1_wire_signature(wire_signature(row))
            )
            if counts.get(row_count_key) != len(rows):
                errors.append(
                    f"{error_prefix}_wire_snapshot_{row_count_key}={len(rows)} "
                    f"status={counts.get(row_count_key)}"
                )
            if counts.get(local_count_key) != local_met1_count:
                errors.append(
                    f"{error_prefix}_wire_snapshot_{local_count_key}="
                    f"{local_met1_count} "
                    f"status={counts.get(local_count_key)}"
                )

        for net in EXPECTED_NETS:
            base_local_stubs = [
                wire_signature(row)
                for row in base_wire_snapshot
                if row.get("net") == net
                and is_local_met1_wire_signature(wire_signature(row))
            ]
            if len(base_local_stubs) != 1 or not is_canonical_fixed_met1_stub(
                base_local_stubs[0] if base_local_stubs else tuple("" for _ in WIRE_SIGNATURE_FIELDS)
            ):
                errors.append(
                    f"{error_prefix}_base_canonical_stub_{net}="
                    f"count_{len(base_local_stubs)}"
                )

    if is_r6:
        chain_contract_by_net = {
            row.get("net", ""): row for row in chain_contract
        }
        if len(chain_contract) != 4 or set(chain_contract_by_net) != set(
            R6_CHAIN_CONTRACT
        ):
            errors.append(
                f"r6_chain_contract_rows={len(chain_contract)} "
                f"nets={tuple(sorted(chain_contract_by_net))}"
            )
        for net, expected in R6_CHAIN_CONTRACT.items():
            row = chain_contract_by_net.get(net, {})
            expected_fields = {
                "start_x": expected[1],
                "start_y": expected[2],
                "end_x": expected[3],
                "end_y": expected[2],
                "length_um": "0.56",
                "requested_width_um": "0.28",
                "direction": expected[4],
                "source_q": expected[5],
                "inside_source_inst_status": "PASS",
                "contract_status": "PASS",
            }
            if not boxes_match(row.get("marker_box", ""), expected[0]):
                errors.append(f"r6_chain_contract_{net}_marker_box_mismatch")
            for key, value in expected_fields.items():
                if row.get(key) != value:
                    errors.append(
                        f"r6_chain_contract_{net}_{key}="
                        f"{row.get(key, 'MISSING')} expected={value}"
                    )
            if row.get("canonical_wire", "") in {"", "NONE", "UNKNOWN", "0x0"}:
                errors.append(f"r6_chain_contract_{net}_canonical_wire_invalid")
            canonical_box = numeric_box(row.get("canonical_box", ""))
            if not canonical_box or (
                abs(abs(canonical_box[2] - canonical_box[0]) - 0.50) > 0.001
                or abs(abs(canonical_box[3] - canonical_box[1]) - 0.23) > 0.001
            ):
                errors.append(f"r6_chain_contract_{net}_canonical_box_invalid")
            points = numeric_box(row.get("canonical_pts", ""))
            expected_start = (float(expected[1]), float(expected[2]))
            if not points or not any(
                abs(x - expected_start[0]) <= 0.001
                and abs(y - expected_start[1]) <= 0.001
                for x, y in ((points[0], points[1]), (points[2], points[3]))
            ):
                errors.append(f"r6_chain_contract_{net}_canonical_endpoint_invalid")
    if is_r7:
        via_side_contract_by_net = {
            row.get("net", ""): row for row in via_side_contract
        }
        if len(via_side_contract) != 4 or set(via_side_contract_by_net) != set(
            R7_VIA_SIDE_CONTRACT
        ):
            errors.append(
                f"r7_via_side_contract_rows={len(via_side_contract)} "
                f"nets={tuple(sorted(via_side_contract_by_net))}"
            )
        for net, expected in R7_VIA_SIDE_CONTRACT.items():
            row = via_side_contract_by_net.get(net, {})
            expected_fields = {
                "source_side_x": expected[1],
                "source_side_y": expected[2],
                "start_x": expected[3],
                "start_y": expected[4],
                "end_x": expected[5],
                "end_y": expected[4],
                "length_um": "0.56",
                "requested_width_um": "0.28",
                "direction": expected[6],
                "source_q": expected[7],
                "normalized_via_endpoint_status": "PASS",
                "canonical_source_side_endpoint_status": "PASS",
                "met2_split_endpoint_status": "PASS",
                "away_from_source_status": "PASS",
                "contract_status": "PASS",
            }
            if not boxes_match(row.get("marker_box", ""), expected[0]):
                errors.append(
                    f"r7_via_side_contract_{net}_marker_box_mismatch"
                )
            for key, value in expected_fields.items():
                if row.get(key) != value:
                    errors.append(
                        f"r7_via_side_contract_{net}_{key}="
                        f"{row.get(key, 'MISSING')} expected={value}"
                    )
            if row.get("canonical_wire", "") in {"", "NONE", "UNKNOWN", "0x0"}:
                errors.append(
                    f"r7_via_side_contract_{net}_canonical_wire_invalid"
                )
            canonical_box = numeric_box(row.get("canonical_box", ""))
            if not canonical_box or (
                abs(abs(canonical_box[2] - canonical_box[0]) - 0.50) > 0.001
                or abs(abs(canonical_box[3] - canonical_box[1]) - 0.23) > 0.001
            ):
                errors.append(
                    f"r7_via_side_contract_{net}_canonical_box_invalid"
                )
            points = numeric_box(row.get("canonical_pts", ""))
            required_points = (
                (float(expected[1]), float(expected[2])),
                (float(expected[3]), float(expected[4])),
            )
            if not points or any(
                not any(
                    abs(x - required_x) <= 0.001
                    and abs(y - required_y) <= 0.001
                    for x, y in (
                        (points[0], points[1]),
                        (points[2], points[3]),
                    )
                )
                for required_x, required_y in required_points
            ):
                errors.append(
                    f"r7_via_side_contract_{net}_canonical_endpoints_invalid"
                )

        survivor_nets = set(R7_VIA_SIDE_CONTRACT)
        controls_stable = True
        for net in EXPECTED_NETS:
            base_signatures = Counter(
                wire_signature(row)
                for row in base_wire_snapshot
                if row.get("net") == net
                and is_local_met1_wire_signature(wire_signature(row))
            )
            post_signatures = Counter(
                wire_signature(row)
                for row in post_via_side_wire_snapshot
                if row.get("net") == net
                and is_local_met1_wire_signature(wire_signature(row))
            )
            changed = base_signatures != post_signatures
            if net in survivor_nets:
                if changed:
                    via_side_materialized_net_count += 1
                    materialization = "LOCAL_MET1_CHANGED"
                else:
                    via_side_no_local_delta_net_count += 1
                    materialization = "NO_LOCAL_MET1_DELTA"
                via_side_materialization_summary.append(
                    {
                        "net": net,
                        "base_local_met1_signature_count": str(
                            sum(base_signatures.values())
                        ),
                        "post_local_met1_signature_count": str(
                            sum(post_signatures.values())
                        ),
                        "materialization_status": materialization,
                    }
                )
            elif changed:
                controls_stable = False
                errors.append(f"r7_unedited_control_local_met1_changed={net}")
        via_side_control_stability_status = (
            "PASS_UNEDITED_CONTROLS_STABLE"
            if controls_stable
            else "FAIL_UNEDITED_CONTROL_CHANGED"
        )
        if (
            via_side_materialized_net_count
            + via_side_no_local_delta_net_count
            != 4
        ):
            errors.append(
                "r7_via_side_materialization_accounting="
                f"{via_side_materialized_net_count}+"
                f"{via_side_no_local_delta_net_count} expected=4"
            )

    materialization_status = "NOT_APPLICABLE"
    materialization_summary: list[dict[str, str]] = []
    added_wire_signatures: Counter[tuple[str, ...]] = Counter()
    removed_wire_signatures: Counter[tuple[str, ...]] = Counter()
    added_wire_handle_count = 0
    removed_wire_handle_count = 0
    added_local_met1_signature_count = 0
    removed_local_met1_signature_count = 0
    added_local_met2_signature_count = 0
    removed_local_met2_signature_count = 0
    requested_width_materialized_wide_net_count = 0
    canonicalized_wide_net_count = 0
    no_local_delta_wide_net_count = 0
    canonical_fixed_stub_net_count = 0
    met2_split_net_count = 0
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
        added_local_met2_signature_count = sum(
            count
            for signature, count in added_wire_signatures.items()
            if is_local_met2_wire_signature(signature)
        )
        removed_local_met2_signature_count = sum(
            count
            for signature, count in removed_wire_signatures.items()
            if is_local_met2_wire_signature(signature)
        )

        for net in EXPECTED_NETS:
            requested_width = 0.56 if net in R4_WIDE_NETS else 0.28
            net_local_added = [
                signature
                for signature, count in added_wire_signatures.items()
                for _ in range(count)
                if signature[0] == net and is_local_met1_wire_signature(signature)
            ]
            net_local_met2_added = [
                signature
                for signature, count in added_wire_signatures.items()
                for _ in range(count)
                if signature[0] == net and is_local_met2_wire_signature(signature)
            ]
            net_local_met2_removed = [
                signature
                for signature, count in removed_wire_signatures.items()
                for _ in range(count)
                if signature[0] == net and is_local_met2_wire_signature(signature)
            ]
            widths = sorted({signature[6] for signature in net_local_added})
            canonical_fixed_stub = bool(
                len(net_local_added) == 1
                and is_canonical_fixed_met1_stub(net_local_added[0])
            )
            met2_split = bool(
                len(net_local_met2_removed) == 1
                and len(net_local_met2_added) == 2
                and all(
                    signature[4].lower() == "routed"
                    and width_matches(signature[6], 0.28)
                    for signature in net_local_met2_removed + net_local_met2_added
                )
                and sum(
                    width_matches(signature[7], 0.155)
                    for signature in net_local_met2_added
                )
                == 1
            )
            if canonical_fixed_stub and met2_split:
                net_status = "CANONICAL_FIXED_0P23_BY_0P385_WITH_MET2_SPLIT"
                canonical_fixed_stub_net_count += 1
                met2_split_net_count += 1
            elif canonical_fixed_stub:
                net_status = "CANONICAL_FIXED_0P23_BY_0P385"
                canonical_fixed_stub_net_count += 1
            elif any(width_matches(signature[6], requested_width) for signature in net_local_added):
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

        if canonical_fixed_stub_net_count == 6 and met2_split_net_count == 6:
            materialization_status = (
                "UNIFORM_FIXED_0P23_BY_0P385_MET1_WITH_MET2_SPLIT"
            )
        elif requested_width_materialized_wide_net_count == 4:
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
    if is_r7:
        analysis_label = (
            "SPADMIC_TX_PACKET_MIN_AREA_NORMALIZED_VIA_SIDE_ANALYSIS"
        )
        analysis_policy = (
            "ISOLATED_IN_MEMORY_SIX_BASE_THEN_FOUR_NORMALIZED_VIA_SIDE_"
            "CLASSIFICATION"
        )
        analysis_result = (
            "MIN_AREA_NORMALIZED_VIA_SIDE_TRIAL_CLASSIFIED"
            if not errors
            else "MIN_AREA_NORMALIZED_VIA_SIDE_CLASSIFICATION_INCOMPLETE"
        )
        method_status = (
            "VALIDATED_ZERO_DRC_ZERO_CONNECTIVITY"
            if validated
            else "REJECTED_OR_INCOMPLETE"
        )
        contract_status = (
            "PASS_EXACT_SIX_BASE_AND_FOUR_NORMALIZED_VIA_ENDPOINTS"
            if counts.get("CONTRACT_VALIDATED_COUNT") == 6
            and counts.get("VIA_SIDE_ENDPOINT_CONTRACT_VALIDATED_COUNT") == 4
            else "FAIL"
        )
        if validated:
            next_method_decision = (
                "INTEGRATE_NORMALIZED_VIA_SIDE_METHOD_IN_FRESH_CANONICAL_REPLAY"
            )
        elif via_side_materialized_net_count == 4:
            next_method_decision = (
                "RETIRE_NORMALIZED_VIA_SIDE_WIRE_EDITOR_REVIEW_REGULAR_"
                "SIGNAL_SHAPE_PRIMITIVE"
            )
        elif via_side_no_local_delta_net_count == 4:
            next_method_decision = (
                "RETIRE_NORMALIZED_VIA_SIDE_WIRE_EDITOR_NO_LOCAL_DELTA"
            )
        else:
            next_method_decision = (
                "STOP_AND_REVIEW_NORMALIZED_VIA_SIDE_EVIDENCE_BEFORE_NEW_METHOD"
            )
    elif is_r6:
        analysis_label = "SPADMIC_TX_PACKET_MIN_AREA_CHAINED_LANDING_ANALYSIS"
        analysis_policy = (
            "ISOLATED_IN_MEMORY_SIX_BASE_THEN_FOUR_CHAINED_ENDPOINT_CLASSIFICATION"
        )
        analysis_result = (
            "MIN_AREA_CHAINED_LANDING_TRIAL_CLASSIFIED"
            if not errors
            else "MIN_AREA_CHAINED_LANDING_CLASSIFICATION_INCOMPLETE"
        )
        method_status = (
            "VALIDATED_ZERO_DRC_ZERO_CONNECTIVITY"
            if validated
            else "REJECTED_OR_INCOMPLETE"
        )
        contract_status = (
            "PASS_EXACT_SIX_BASE_AND_FOUR_CHAIN_ENDPOINTS"
            if counts.get("CONTRACT_VALIDATED_COUNT") == 6
            and counts.get("CHAIN_ENDPOINT_CONTRACT_VALIDATED_COUNT") == 4
            else "FAIL"
        )
        next_method_decision = (
            "INTEGRATE_CHAINED_ENDPOINT_METHOD_IN_FRESH_CANONICAL_REPLAY"
            if validated
            else "STOP_AND_REVIEW_CHAINED_ENDPOINT_EVIDENCE_BEFORE_NEW_METHOD"
        )
    elif is_r5:
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
        elif materialization_status == (
            "UNIFORM_FIXED_0P23_BY_0P385_MET1_WITH_MET2_SPLIT"
        ):
            next_method_decision = (
                "COMPARE_CLOSED_CONTROL_AND_SURVIVOR_LANDING_COMPONENT_GEOMETRY"
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
    if is_multistage:
        result.update(
            {
                "BASE_STAGE_STATUS": status.get("BASE_STAGE_STATUS", "MISSING"),
                "BASE_DRC_VIOLATION_COUNT": status.get(
                    "BASE_DRC_VIOLATION_COUNT", "UNKNOWN"
                ),
                "BASE_DRC_MARKER_COUNT": status.get(
                    "BASE_DRC_MARKER_COUNT", "UNKNOWN"
                ),
                "BASE_MIN_AREA_NETS": status.get("BASE_MIN_AREA_NETS", ""),
                "BASE_REGULAR_CONNECTIVITY_VIOLATION_COUNT": status.get(
                    "BASE_REGULAR_CONNECTIVITY_VIOLATION_COUNT", "UNKNOWN"
                ),
                "BASE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": status.get(
                    "BASE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT", "UNKNOWN"
                ),
                "BASE_EXCLUDED_ANTENNA_MARKER_COUNT": status.get(
                    "BASE_EXCLUDED_ANTENNA_MARKER_COUNT", "UNKNOWN"
                ),
                "BASE_MARKER_DATABASE_TOTAL": status.get(
                    "BASE_MARKER_DATABASE_TOTAL", "UNKNOWN"
                ),
                "BASE_CANONICAL_FIXED_STUB_NET_COUNT": "6",
                "BASE_PATCH_ATTEMPTED_COUNT": status.get(
                    "BASE_PATCH_ATTEMPTED_COUNT", "UNKNOWN"
                ),
                "BASE_PATCH_APPLIED_COUNT": status.get(
                    "BASE_PATCH_APPLIED_COUNT", "UNKNOWN"
                ),
            }
        )
    if is_r6:
        result.update(
            {
                "CHAIN_CAPTURE_STATUS": (
                    "COMPLETE" if not errors else "INCOMPLETE"
                ),
                "CHAIN_ENDPOINT_CONTRACT_STATUS": status.get(
                    "CHAIN_ENDPOINT_CONTRACT_STATUS", "MISSING"
                ),
                "CHAIN_ENDPOINT_CONTRACT_VALIDATED_COUNT": status.get(
                    "CHAIN_ENDPOINT_CONTRACT_VALIDATED_COUNT", "UNKNOWN"
                ),
                "CHAIN_STAGE_STATUS": status.get("CHAIN_STAGE_STATUS", "MISSING"),
                "CHAIN_PATCH_ATTEMPTED_COUNT": status.get(
                    "CHAIN_PATCH_ATTEMPTED_COUNT", "UNKNOWN"
                ),
                "CHAIN_PATCH_APPLIED_COUNT": status.get(
                    "CHAIN_PATCH_APPLIED_COUNT", "UNKNOWN"
                ),
            }
        )
    if is_r7:
        result.update(
            {
                "VIA_SIDE_CAPTURE_STATUS": (
                    "COMPLETE" if not errors else "INCOMPLETE"
                ),
                "VIA_SIDE_ENDPOINT_CONTRACT_STATUS": status.get(
                    "VIA_SIDE_ENDPOINT_CONTRACT_STATUS", "MISSING"
                ),
                "VIA_SIDE_ENDPOINT_CONTRACT_VALIDATED_COUNT": status.get(
                    "VIA_SIDE_ENDPOINT_CONTRACT_VALIDATED_COUNT", "UNKNOWN"
                ),
                "VIA_SIDE_STAGE_STATUS": status.get(
                    "VIA_SIDE_STAGE_STATUS", "MISSING"
                ),
                "VIA_SIDE_PATCH_ATTEMPTED_COUNT": status.get(
                    "VIA_SIDE_PATCH_ATTEMPTED_COUNT", "UNKNOWN"
                ),
                "VIA_SIDE_PATCH_APPLIED_COUNT": status.get(
                    "VIA_SIDE_PATCH_APPLIED_COUNT", "UNKNOWN"
                ),
                "VIA_SIDE_MATERIALIZED_NET_COUNT": str(
                    via_side_materialized_net_count
                ),
                "VIA_SIDE_NO_LOCAL_DELTA_NET_COUNT": str(
                    via_side_no_local_delta_net_count
                ),
                "VIA_SIDE_CONTROL_STABILITY_STATUS": (
                    via_side_control_stability_status
                ),
            }
        )
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
                "ADDED_LOCAL_MET2_SIGNATURE_COUNT": str(
                    added_local_met2_signature_count
                ),
                "REMOVED_LOCAL_MET2_SIGNATURE_COUNT": str(
                    removed_local_met2_signature_count
                ),
                "CANONICAL_FIXED_STUB_NET_COUNT": str(
                    canonical_fixed_stub_net_count
                ),
                "MET2_SPLIT_NET_COUNT": str(met2_split_net_count),
                "MATERIALIZED_MET1_WIDTH_UM": (
                    "0.23"
                    if canonical_fixed_stub_net_count == 6
                    else "MIXED_OR_UNKNOWN"
                ),
                "MATERIALIZED_MET1_CENTERLINE_LENGTH_UM": (
                    "0.385"
                    if canonical_fixed_stub_net_count == 6
                    else "MIXED_OR_UNKNOWN"
                ),
                "WIRE_EDITOR_PARAMETER_CONTROL_STATUS": (
                    "REQUESTED_WIDTH_AND_ENDPOINT_NORMALIZED"
                    if materialization_status
                    == "UNIFORM_FIXED_0P23_BY_0P385_MET1_WITH_MET2_SPLIT"
                    else "NOT_EXACTLY_CLASSIFIED"
                ),
                "CLOSED_CONTROL_MATERIALIZATION_MATCH_STATUS": (
                    "PASS_SAME_CANONICAL_STUB_CLASS_AS_SURVIVORS"
                    if materialization_status
                    == "UNIFORM_FIXED_0P23_BY_0P385_MET1_WITH_MET2_SPLIT"
                    else "NOT_EXACTLY_CLASSIFIED"
                ),
                "PATCH_PARAMETER_SWEEP_DECISION": (
                    "RETIRED_LENGTH_DIRECTION_AND_WIDTH"
                    if materialization_status
                    == "UNIFORM_FIXED_0P23_BY_0P385_MET1_WITH_MET2_SPLIT"
                    else "PENDING_EXACT_MATERIALIZATION_CLASSIFICATION"
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
    if is_multistage:
        lines.extend(("", "BASE_MARKER_TABLE_BEGIN"))
        if base_markers:
            lines.append("\t".join(base_markers[0].keys()))
            lines.extend("\t".join(row.values()) for row in base_markers)
        lines.append("BASE_MARKER_TABLE_END")
    if is_r6:
        lines.extend(("", "CHAIN_ENDPOINT_CONTRACT_TABLE_BEGIN"))
        if chain_contract:
            lines.append("\t".join(chain_contract[0].keys()))
            lines.extend("\t".join(row.values()) for row in chain_contract)
        lines.append("CHAIN_ENDPOINT_CONTRACT_TABLE_END")
    if is_r7:
        lines.extend(("", "VIA_SIDE_ENDPOINT_CONTRACT_TABLE_BEGIN"))
        if via_side_contract:
            lines.append("\t".join(via_side_contract[0].keys()))
            lines.extend("\t".join(row.values()) for row in via_side_contract)
        lines.append("VIA_SIDE_ENDPOINT_CONTRACT_TABLE_END")
        lines.extend(("", "VIA_SIDE_MATERIALIZATION_SUMMARY_TABLE_BEGIN"))
        if via_side_materialization_summary:
            lines.append(
                "\t".join(via_side_materialization_summary[0].keys())
            )
            lines.extend(
                "\t".join(row.values())
                for row in via_side_materialization_summary
            )
        lines.append("VIA_SIDE_MATERIALIZATION_SUMMARY_TABLE_END")
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
    parser.add_argument("--step26-analysis", type=Path)
    parser.add_argument("--step27-analysis", type=Path)
    parser.add_argument(
        "--trial-revision",
        choices=("R1", "R2", "R3", "R4", "R5", "R6", "R7"),
        default="R1",
    )
    parser.add_argument("--report-driver-head", required=True)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    source_analysis = (
        args.source_analysis
        or args.step27_analysis
        or args.step26_analysis
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
        "R6": args.step26_analysis,
        "R7": args.step27_analysis,
    }[args.trial_revision]
    if source_analysis is None:
        parser.error("one source analysis argument is required")
    if expected_alias is None and args.source_analysis is None:
        parser.error(
            f"--{dict(R1='step20', R2='step21', R3='step22', R4='step23', R5='step24', R6='step26', R7='step27')[args.trial_revision]}-analysis "
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
