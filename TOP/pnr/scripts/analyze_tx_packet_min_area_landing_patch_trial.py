#!/usr/bin/env python3
"""Classify the isolated TX six-net MET1 landing-extension trial."""

from __future__ import annotations

import argparse
import csv
import hashlib
import re
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
EXPECTED_CONTRACT = {
    "n_9696": ("719.69 158.62 720.07 158.90", "719.88", "158.76", "719.32", "g14627__2802/Q", "716.61 159.02"),
    "n_9693": ("210.09 201.74 210.47 202.02", "210.28", "201.88", "209.72", "g14630__8246/Q", "207.01 201.62"),
    "n_9697": ("663.13 192.78 663.51 193.06", "663.32", "192.92", "662.76", "g14626__1617/Q", "660.05 192.66"),
    "n_9677": ("1666.09 201.74 1666.47 202.02", "1666.28", "201.88", "1666.84", "g14646__2398/Q", "1669.55 201.62"),
    "n_9721": ("1792.65 212.38 1793.03 212.66", "1792.84", "212.52", "1792.28", "g14602__8246/Q", "1789.57 212.78"),
    "n_9706": ("1826.81 212.38 1827.19 212.66", "1827.00", "212.52", "1827.56", "g14617__5477/Q", "1830.27 212.78"),
}
VALIDATED_RESULT = "SIX_MET1_LANDING_EXTENSIONS_DRC_ZERO_VALIDATED"
NO_IMPROVEMENT_RESULT = "SIX_MET1_LANDING_EXTENSIONS_NO_IMPROVEMENT"


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


def classify(
    trial_root: Path,
    step20_analysis: Path,
    report_driver_head: str,
    report: Path,
) -> dict[str, str]:
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
    required = [
        context_path,
        status_path,
        commands_path,
        contract_path,
        step20_analysis,
        pre_markers_path,
        post_markers_path,
        pre_drc_path,
        post_drc_path,
        pre_regular_path,
        post_regular_path,
        pre_special_path,
        post_special_path,
    ]

    errors: list[str] = []
    for path in required:
        if not path.is_file():
            errors.append(f"missing_required_artifact={path}")

    context = key_values(context_path)
    status = key_values(status_path)
    commands = key_values(commands_path)
    step20 = key_values(step20_analysis)
    contract = read_tsv(contract_path)
    pre_markers = read_tsv(pre_markers_path)
    post_markers = read_tsv(post_markers_path)

    expected_step20 = {
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
    for key, expected in expected_step20.items():
        if step20.get(key) != expected:
            errors.append(f"step20_{key}={step20.get(key, 'MISSING')} expected={expected}")

    expected_context = {
        "HEAD": report_driver_head,
        "POLICY": EXPECTED_POLICY,
        "DESIGN_MODIFICATION": "IN_MEMORY_ONLY",
        "SOURCE_CHECKPOINT_WRITE": "NOT_RUN",
        "SAVE_DESIGN": "NOT_RUN",
        "EXPORT": "NOT_RUN",
        "PVS": "NOT_RUN",
    }
    for key, expected in expected_context.items():
        if context.get(key) != expected:
            errors.append(f"context_{key}={context.get(key, 'MISSING')} expected={expected}")
    context_analysis = context.get("STEP20_ANALYSIS", "")
    if not context_analysis or Path(context_analysis).resolve() != step20_analysis:
        errors.append(
            f"context_STEP20_ANALYSIS={context_analysis or 'MISSING'} expected={step20_analysis}"
        )

    expected_status = {
        "LABEL": "SPADMIC_OOC_MIN_AREA_LANDING_PATCH_TRIAL",
        "POLICY": EXPECTED_POLICY,
        "DESIGN_MODIFICATION": "IN_MEMORY_ONLY",
        "SOURCE_CHECKPOINT_WRITE": "NOT_RUN",
        "SAVE_DESIGN": "NOT_RUN",
        "EXPORT": "NOT_RUN",
        "PVS": "NOT_RUN",
        "RESTORE_DESIGN": "PASS",
        "PRE_MIN_AREA_NETS": " ".join(EXPECTED_NETS),
        "CONTRACT_VALIDATED_COUNT": "6",
    }
    for key, expected in expected_status.items():
        if status.get(key) != expected:
            errors.append(f"trial_{key}={status.get(key, 'MISSING')} expected={expected}")
    status_analysis = status.get("STEP20_ANALYSIS", "")
    if not status_analysis or Path(status_analysis).resolve() != step20_analysis:
        errors.append(
            f"trial_STEP20_ANALYSIS={status_analysis or 'MISSING'} expected={step20_analysis}"
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
        expected = EXPECTED_CONTRACT.get(net)
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
    for net, expected in EXPECTED_CONTRACT.items():
        row = contract_by_net.get(net, {})
        expected_fields = {
            "start_x": expected[1],
            "start_y": expected[2],
            "end_x": expected[3],
            "end_y": expected[2],
            "length_um": "0.56",
            "width_um": "0.28",
            "source_q": expected[4],
            "source_q_point": expected[5],
            "marker_status": "PASS",
            "via1_status": "PASS",
            "met2_endpoint_status": "PASS",
            "source_q_status": "PASS",
            "inside_source_inst_status": "PASS",
            "contract_status": "PASS",
        }
        if not boxes_match(row.get("marker_box", ""), expected[0]):
            errors.append(f"contract_{net}_marker_box={row.get('marker_box', 'MISSING')}")
        for key, value in expected_fields.items():
            if row.get(key) != value:
                errors.append(f"contract_{net}_{key}={row.get(key, 'MISSING')} expected={value}")

    expected_commands = {
        "LABEL": "SPADMIC_OOC_MIN_AREA_LANDING_PATCH_COMMANDS",
        "POLICY": "EXACT_SIX_NET_ONE_GRID_MET1_WIRE_EDITOR_EXTENSIONS",
        "PATCH_WIDTH_UM": "0.28",
        "PATCH_LENGTH_UM": "0.56",
        "CONTRACT_VALIDATED_COUNT": "6",
    }
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
        for net, expected in EXPECTED_CONTRACT.items():
            prefix = f"PATCH_{net}"
            expected_commands_for_net = {
                f"{prefix}_START": f"{expected[1]} {expected[2]}",
                f"{prefix}_END": f"{expected[3]} {expected[2]}",
                f"{prefix}_SOURCE_Q": expected[4],
                f"{prefix}_APPLIED": "YES",
            }
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
                    "-width_horizontal 0.28",
                    "-width_vertical 0.28",
                )
            ):
                errors.append(f"commands_{prefix}_SET_EDIT_MODE_contract_mismatch")
    elif command_fail_count is not None:
        if command_fail_count < 1 or patch_attempted is None or not 1 <= patch_attempted <= 6:
            errors.append("invalid_failed_command_tuple")

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
    if status.get("FINAL_MIN_AREA_NETS", "").split() != list(final_min_area_nets):
        errors.append(
            f"final_min_area_nets={status.get('FINAL_MIN_AREA_NETS', 'MISSING')} rows={final_min_area_nets}"
        )

    if command_fail_count and command_fail_count > 0:
        expected_process_result = "PATCH_COMMAND_FAILED"
    elif (final_regular or 0) != 0 or (final_special or 0) != 0 or (final_connectivity_markers or 0) != 0:
        expected_process_result = "PATCH_CONNECTIVITY_REGRESSION"
    elif final_antenna != 21:
        expected_process_result = "PATCH_RESTORED_ANTENNA_SENTINEL_CHANGED"
    elif (final_drc, final_markers, final_database, len(post_markers)) == (0, 0, 21, 0):
        expected_process_result = VALIDATED_RESULT
    elif (
        (final_drc, final_markers, final_database) == (6, 6, 27)
        and final_min_area_nets == EXPECTED_NETS
    ):
        expected_process_result = NO_IMPROVEMENT_RESULT
    else:
        expected_process_result = "SIX_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED"

    expected_process_status = "PASS" if expected_process_result == VALIDATED_RESULT else "FAIL"
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
    validated = expected_process_result == VALIDATED_RESULT
    result = {
        "LABEL": "SPADMIC_TX_PACKET_MIN_AREA_LANDING_PATCH_ANALYSIS",
        "POLICY": "ISOLATED_IN_MEMORY_SIX_NET_MET1_LANDING_PATCH_CLASSIFICATION",
        "STATUS": "PASS" if not errors else "FAIL",
        "RESULT": (
            "MIN_AREA_LANDING_PATCH_TRIAL_CLASSIFIED"
            if not errors
            else "MIN_AREA_LANDING_PATCH_CLASSIFICATION_INCOMPLETE"
        ),
        "TRIAL_ROOT": str(trial_root),
        "SOURCE_CHECKPOINT": context.get("SOURCE_CHECKPOINT", "MISSING"),
        "REPORT_DRIVER_HEAD": report_driver_head,
        "TRIAL_PROCESS_STATUS": status.get("STATUS", "MISSING"),
        "TRIAL_PROCESS_RESULT": status.get("RESULT", "MISSING"),
        "METHOD_STATUS": (
            "VALIDATED_ZERO_DRC_ZERO_CONNECTIVITY"
            if validated
            else "REJECTED_OR_INCOMPLETE"
        ),
        "PATCH_CONTRACT_STATUS": (
            "PASS_EXACT_SIX_REVIEWED_EXTENSIONS"
            if counts.get("CONTRACT_VALIDATED_COUNT") == 6
            else "FAIL"
        ),
        "PATCH_WIDTH_UM": "0.28",
        "PATCH_LENGTH_UM": "0.56",
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
        "NEXT_METHOD_DECISION": (
            "REVIEW_DRC_ZERO_PATCH_BEFORE_CANONICAL_INTEGRATION"
            if validated
            else "STOP_AND_REVIEW_PATCH_EVIDENCE_BEFORE_NEW_METHOD"
        ),
        "ERROR_COUNT": str(len(errors)),
    }

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
    parser.add_argument("--step20-analysis", type=Path, required=True)
    parser.add_argument("--report-driver-head", required=True)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    result = classify(
        args.trial_root.resolve(),
        args.step20_analysis.resolve(),
        args.report_driver_head,
        args.report.resolve(),
    )
    print(args.report.read_text(), end="")
    return 0 if result["STATUS"] == "PASS" else 8


if __name__ == "__main__":
    raise SystemExit(main())
