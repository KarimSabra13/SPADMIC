#!/usr/bin/env python3
"""Classify one isolated TX packet PG via candidate from immutable reports."""

from __future__ import annotations

import argparse
from collections import Counter
from pathlib import Path

from analyze_tx_packet_pg_via_drc import (
    Marker,
    counter_difference,
    int_field,
    parse_markers,
    read_kv,
    report_value,
    sha256,
)


def marker_table(
    title: str,
    markers: list[Marker],
    row_centers: dict[int, float],
) -> list[str]:
    lines = [
        f"{title}_BEGIN",
        "index\tsource_index\tlayer\ttype\tsubType\tbox\tcx\tcy\tnearest_row\trow_distance_um\tmessage",
    ]
    for index, marker in enumerate(markers, start=1):
        if row_centers:
            nearest_row = min(row_centers, key=lambda row: abs(marker.cy - row_centers[row]))
            distance = abs(marker.cy - row_centers[nearest_row])
        else:
            nearest_row = 0
            distance = float("nan")
        lines.append(
            "\t".join(
                (
                    str(index),
                    marker.post_index,
                    report_value(marker.layer),
                    report_value(marker.marker_type),
                    report_value(marker.subtype),
                    report_value(marker.box),
                    f"{marker.cx:.6f}",
                    f"{marker.cy:.6f}",
                    str(nearest_row) if nearest_row else "UNKNOWN",
                    f"{distance:.6f}" if distance == distance else "UNKNOWN",
                    report_value(marker.message),
                )
            )
        )
    lines.append(f"{title}_END")
    return lines


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--trial-root", type=Path, required=True)
    parser.add_argument("--analysis-report", type=Path, required=True)
    parser.add_argument("--expected-mode", required=True)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()

    reports = args.trial_root / "reports"
    trial_status_path = reports / "pg_via_trial_status.rpt"
    command_report_path = reports / "pg_via_trial_commands.rpt"
    pre_markers_path = reports / "drc_markers_pre_trial.tsv"
    post_markers_path = reports / "drc_markers_post_trial.tsv"
    required = (
        trial_status_path,
        command_report_path,
        pre_markers_path,
        post_markers_path,
        args.analysis_report,
    )
    missing = [path for path in required if not path.is_file()]
    args.report.parent.mkdir(parents=True, exist_ok=True)
    if missing:
        args.report.write_text(
            "LABEL=SPADMIC_TX_PACKET_PG_VIA_CANDIDATE_ANALYSIS\n"
            "POLICY=READ_ONLY_TRIAL_ARTIFACT_CLASSIFICATION\n"
            "STATUS=FAIL\n"
            "RESULT=MISSING_REQUIRED_INPUTS\n"
            f"MISSING_INPUTS={' '.join(str(path) for path in missing)}\n"
        )
        return 8

    errors: list[str] = []
    trial = read_kv(trial_status_path)
    command_text = command_report_path.read_text(errors="replace")
    topology = read_kv(args.analysis_report)
    try:
        pre_markers = parse_markers(pre_markers_path)
        post_markers = parse_markers(post_markers_path)
    except ValueError as error:
        errors.append(str(error))
        pre_markers = []
        post_markers = []

    expected_trial_fields = {
        "MODE": args.expected_mode,
        "RESTORE_DESIGN": "PASS",
        "DESIGN_MODIFICATION": "IN_MEMORY_ONLY",
        "SOURCE_CHECKPOINT_WRITE": "NOT_RUN",
        "SAVE_DESIGN": "NOT_RUN",
        "EXPORT": "NOT_RUN",
        "VIA_GEN_AREA_ONLY_STATUS": "PASS",
        "PRE_DRC_MARKER_DUMP_STATUS": "PASS",
        "POST_DRC_MARKER_DUMP_STATUS": "PASS",
    }
    for key, expected in expected_trial_fields.items():
        if trial.get(key) != expected:
            errors.append(f"trial_{key}={trial.get(key, 'MISSING')} expected={expected}")

    source_checkpoint = trial.get("SOURCE_CHECKPOINT", "")
    if not source_checkpoint.endswith("/checkpoints/05_postroute_export.enc.dat"):
        errors.append(f"trial_SOURCE_CHECKPOINT={source_checkpoint or 'MISSING'} is not the immutable post-route checkpoint")
    if command_text.count("-via_rows 1 -via_columns 1") != 3:
        errors.append("command report does not contain three explicit 1x1 via constraints")
    if command_text.count("-bottom_layer MET1 -top_layer METTP -exclude_stack_vias 0") != 3:
        errors.append("command report does not contain three direct MET1-to-METTP stacks")

    if topology.get("STATUS") != "PASS" or topology.get("RESULT") != "VDD_ROW_COMPONENTS_CLASSIFIED":
        errors.append("topology analysis is not the accepted VDD row classification")

    integer_keys = (
        "TARGET_ROW_COUNT",
        "COMMAND_PASS_COUNT",
        "COMMAND_FAIL_COUNT",
        "PRE_DRC_VIOLATION_COUNT",
        "POST_DRC_VIOLATION_COUNT",
        "PRE_DRC_MARKER_COUNT",
        "POST_DRC_MARKER_COUNT",
        "PRE_MARKER_DATABASE_TOTAL",
        "POST_MARKER_DATABASE_TOTAL",
        "PRE_EXCLUDED_ANTENNA_MARKER_COUNT",
        "POST_EXCLUDED_ANTENNA_MARKER_COUNT",
        "PRE_EXCLUDED_CONNECTIVITY_MARKER_COUNT",
        "POST_EXCLUDED_CONNECTIVITY_MARKER_COUNT",
        "PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT",
        "POST_REGULAR_CONNECTIVITY_VIOLATION_COUNT",
        "PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT",
        "POST_SPECIAL_CONNECTIVITY_VIOLATION_COUNT",
    )
    counts = {key: int_field(trial, key, errors) for key in integer_keys}

    expected_baseline = {
        "TARGET_ROW_COUNT": 3,
        "COMMAND_PASS_COUNT": 4,
        "COMMAND_FAIL_COUNT": 0,
        "PRE_DRC_VIOLATION_COUNT": 7,
        "PRE_DRC_MARKER_COUNT": 7,
        "PRE_MARKER_DATABASE_TOTAL": 40,
        "PRE_EXCLUDED_ANTENNA_MARKER_COUNT": 29,
        "PRE_EXCLUDED_CONNECTIVITY_MARKER_COUNT": 4,
        "PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT": 0,
        "PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": 4,
    }
    for key, expected in expected_baseline.items():
        if counts[key] != expected:
            errors.append(f"trial_{key}={counts[key]} expected={expected}")

    pre_drc = counts["PRE_DRC_VIOLATION_COUNT"]
    post_drc = counts["POST_DRC_VIOLATION_COUNT"]
    pre_dump_count = counts["PRE_DRC_MARKER_COUNT"]
    post_dump_count = counts["POST_DRC_MARKER_COUNT"]
    pre_database_total = counts["PRE_MARKER_DATABASE_TOTAL"]
    post_database_total = counts["POST_MARKER_DATABASE_TOTAL"]
    pre_excluded_antenna = counts["PRE_EXCLUDED_ANTENNA_MARKER_COUNT"]
    post_excluded_antenna = counts["POST_EXCLUDED_ANTENNA_MARKER_COUNT"]
    pre_excluded_connectivity = counts["PRE_EXCLUDED_CONNECTIVITY_MARKER_COUNT"]
    post_excluded_connectivity = counts["POST_EXCLUDED_CONNECTIVITY_MARKER_COUNT"]
    post_regular = counts["POST_REGULAR_CONNECTIVITY_VIOLATION_COUNT"]
    post_special = counts["POST_SPECIAL_CONNECTIVITY_VIOLATION_COUNT"]

    if pre_dump_count is not None and len(pre_markers) != pre_dump_count:
        errors.append(f"pre TSV rows {len(pre_markers)} do not match marker count {pre_dump_count}")
    if post_dump_count is not None and len(post_markers) != post_dump_count:
        errors.append(f"post TSV rows {len(post_markers)} do not match marker count {post_dump_count}")
    if pre_drc is not None and pre_dump_count != pre_drc:
        errors.append(f"pre marker count {pre_dump_count} does not match DRC count {pre_drc}")
    if post_drc is not None and post_dump_count != post_drc:
        errors.append(f"post marker count {post_dump_count} does not match DRC count {post_drc}")

    pre_filter_values = (pre_dump_count, pre_excluded_antenna, pre_excluded_connectivity)
    post_filter_values = (post_dump_count, post_excluded_antenna, post_excluded_connectivity)
    if pre_database_total is not None and all(value is not None for value in pre_filter_values):
        if pre_database_total != sum(value for value in pre_filter_values if value is not None):
            errors.append("pre marker database filter accounting does not balance")
    if post_database_total is not None and all(value is not None for value in post_filter_values):
        if post_database_total != sum(value for value in post_filter_values if value is not None):
            errors.append("post marker database filter accounting does not balance")

    new_markers = counter_difference(post_markers, pre_markers)
    removed_markers = counter_difference(pre_markers, post_markers)
    drc_delta = post_drc - pre_drc if pre_drc is not None and post_drc is not None else None
    marker_delta = len(new_markers) - len(removed_markers)
    if drc_delta is not None and marker_delta != drc_delta:
        errors.append(
            f"marker set delta {marker_delta} does not match DRC count delta {drc_delta}"
        )

    if counts["COMMAND_FAIL_COUNT"] not in (None, 0):
        candidate_status = "REJECTED_COMMAND_FAILURE"
    elif post_special is not None and post_special != 0:
        candidate_status = "REJECTED_SPECIAL_CONNECTIVITY"
    elif post_regular is not None and post_regular != 0:
        candidate_status = "REJECTED_REGULAR_CONNECTIVITY"
    elif pre_drc is not None and post_drc is not None and post_drc > pre_drc:
        candidate_status = "REJECTED_NEW_DRC"
    elif None not in (post_special, post_regular, pre_drc, post_drc):
        candidate_status = "VALIDATED_NOT_CANONICAL"
    else:
        candidate_status = "INCOMPLETE"

    if candidate_status == "VALIDATED_NOT_CANONICAL":
        expected_status = "PASS"
        expected_result = "PG_VIA_METHOD_VALIDATED_NOT_CANONICAL"
    else:
        expected_status = "FAIL"
        expected_result = "PG_VIA_METHOD_REJECTED"
    if trial.get("STATUS") != expected_status:
        errors.append(f"trial_STATUS={trial.get('STATUS', 'MISSING')} expected={expected_status}")
    if trial.get("RESULT") != expected_result:
        errors.append(f"trial_RESULT={trial.get('RESULT', 'MISSING')} expected={expected_result}")

    row_count = counts["TARGET_ROW_COUNT"] or 0
    row_centers: dict[int, float] = {}
    for row in range(1, row_count + 1):
        key = f"VDD_ROW_{row}_CENTER_Y_UM"
        raw = topology.get(key)
        try:
            row_centers[row] = float(raw) if raw is not None else float("nan")
        except ValueError:
            errors.append(f"{key}={raw} is not numeric")
    if len(row_centers) != row_count or any(value != value for value in row_centers.values()):
        errors.append("missing row centers from topology analysis")

    layer_counts = Counter(marker.layer for marker in new_markers)
    class_counts = Counter((marker.layer, marker.subtype) for marker in new_markers)
    row_counts: Counter[int] = Counter()
    for marker in new_markers:
        if row_centers:
            nearest_row = min(row_centers, key=lambda row: abs(marker.cy - row_centers[row]))
            row_counts[nearest_row] += 1

    status = "PASS" if not errors else "FAIL"
    result = "PG_VIA_CANDIDATE_CLASSIFIED" if not errors else "PG_VIA_CANDIDATE_CLASSIFICATION_INCOMPLETE"
    connectivity_status = (
        "PASS_ZERO_SPECIAL_AND_REGULAR"
        if post_special == 0 and post_regular == 0
        else "FAIL"
    )
    drc_status = (
        "PASS_NO_INCREASE"
        if pre_drc is not None and post_drc is not None and post_drc <= pre_drc
        else "FAIL_NEW_MARKERS"
        if pre_drc is not None and post_drc is not None
        else "UNKNOWN"
    )
    lines = [
        "LABEL=SPADMIC_TX_PACKET_PG_VIA_CANDIDATE_ANALYSIS",
        "POLICY=READ_ONLY_TRIAL_ARTIFACT_CLASSIFICATION",
        f"STATUS={status}",
        f"RESULT={result}",
        f"TRIAL_ROOT={args.trial_root}",
        f"TRIAL_MODE={trial.get('MODE', 'MISSING')}",
        f"CANDIDATE_PHYSICAL_STATUS={candidate_status}",
        f"CANDIDATE_CONNECTIVITY_STATUS={connectivity_status}",
        f"CANDIDATE_DRC_STATUS={drc_status}",
        f"COMMAND_PASS_COUNT={counts['COMMAND_PASS_COUNT'] if counts['COMMAND_PASS_COUNT'] is not None else 'UNKNOWN'}",
        f"COMMAND_FAIL_COUNT={counts['COMMAND_FAIL_COUNT'] if counts['COMMAND_FAIL_COUNT'] is not None else 'UNKNOWN'}",
        f"PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT={counts['PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT'] if counts['PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT'] is not None else 'UNKNOWN'}",
        f"POST_SPECIAL_CONNECTIVITY_VIOLATION_COUNT={post_special if post_special is not None else 'UNKNOWN'}",
        f"PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT={counts['PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT'] if counts['PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT'] is not None else 'UNKNOWN'}",
        f"POST_REGULAR_CONNECTIVITY_VIOLATION_COUNT={post_regular if post_regular is not None else 'UNKNOWN'}",
        f"PRE_DRC_MARKER_COUNT={len(pre_markers)}",
        f"POST_DRC_MARKER_COUNT={len(post_markers)}",
        f"DRC_MARKER_DELTA={drc_delta if drc_delta is not None else 'UNKNOWN'}",
        f"NEW_DRC_MARKER_COUNT={len(new_markers)}",
        f"REMOVED_BASELINE_MARKER_COUNT={len(removed_markers)}",
        f"PRE_MARKER_DATABASE_TOTAL={pre_database_total if pre_database_total is not None else 'UNKNOWN'}",
        f"POST_MARKER_DATABASE_TOTAL={post_database_total if post_database_total is not None else 'UNKNOWN'}",
        f"PRE_EXCLUDED_ANTENNA_MARKER_COUNT={pre_excluded_antenna if pre_excluded_antenna is not None else 'UNKNOWN'}",
        f"POST_EXCLUDED_ANTENNA_MARKER_COUNT={post_excluded_antenna if post_excluded_antenna is not None else 'UNKNOWN'}",
        f"PRE_EXCLUDED_CONNECTIVITY_MARKER_COUNT={pre_excluded_connectivity if pre_excluded_connectivity is not None else 'UNKNOWN'}",
        f"POST_EXCLUDED_CONNECTIVITY_MARKER_COUNT={post_excluded_connectivity if post_excluded_connectivity is not None else 'UNKNOWN'}",
        "NEW_MARKER_LAYER_COUNTS="
        + (" ".join(f"{layer}:{layer_counts[layer]}" for layer in sorted(layer_counts)) or "NONE"),
        "NEW_MARKER_LAYER_SUBTYPE_COUNTS="
        + (
            " ".join(
                f"{layer}/{subtype}:{class_counts[(layer, subtype)]}"
                for layer, subtype in sorted(class_counts)
            )
            or "NONE"
        ),
    ]
    for row in range(1, row_count + 1):
        lines.append(f"NEW_MARKER_NEAREST_ROW_{row}_COUNT={row_counts[row]}")
    lines.extend(
        (
            "CANONICAL_RERUN_DECISION=BLOCKED_PENDING_REVIEW",
            "PVS_DECISION=DO_NOT_RUN",
            "NEXT_METHOD_DECISION=STOP_AND_REVIEW_CANDIDATE_CLASSIFICATION",
            f"PRE_MARKERS_SHA256={sha256(pre_markers_path)}",
            f"POST_MARKERS_SHA256={sha256(post_markers_path)}",
            f"COMMAND_REPORT_SHA256={sha256(command_report_path)}",
        )
    )
    lines.extend(marker_table("NEW_DRC_MARKER_TABLE", new_markers, row_centers))
    lines.extend(marker_table("REMOVED_BASELINE_MARKER_TABLE", removed_markers, row_centers))
    lines.append(f"ERROR_COUNT={len(errors)}")
    lines.extend(f"ERROR={report_value(error)}" for error in errors)
    args.report.write_text("\n".join(lines) + "\n")
    return 0 if not errors else 8


if __name__ == "__main__":
    raise SystemExit(main())
