#!/usr/bin/env python3
"""Attribute Step 13 DRC to CTS, filler insertion, or PG restitch."""

from __future__ import annotations

import argparse
import re
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


EXPECTED_FILLER_CELLS = (
    "FEED25JIHD FEED15JIHD FEED10JIHD FEED7JIHD "
    "FEED5JIHD FEED3JIHD FEED2JIHD FEED1JIHD"
)
EXPECTED_FILLER_COMMAND = f"addFiller -cell {{{EXPECTED_FILLER_CELLS}}} -prefix FILL"


def verification_count(path: Path) -> int | None:
    text = path.read_text(errors="replace")
    counts = {
        int(value)
        for pattern in (
            r"Verification\s+Complete\s*:\s*(\d+)\s+Viols?",
            r"Total\s+number\s+of\s+DRC\s+violations\s*=\s*(\d+)",
        )
        for value in re.findall(pattern, text, flags=re.IGNORECASE)
    }
    if len(counts) == 1:
        return counts.pop()
    return None


def format_counter(counter: Counter[object], separator: str = ":") -> str:
    if not counter:
        return "NONE"
    return " ".join(
        f"{separator.join(key) if isinstance(key, tuple) else key}:{counter[key]}"
        for key in sorted(counter)
    )


def marker_table(title: str, markers: list[Marker]) -> list[str]:
    lines = [
        f"{title}_BEGIN",
        "index\tsource_index\tlayer\ttype\tsubType\tbox\tcx\tcy\tmessage",
    ]
    for index, marker in enumerate(markers, start=1):
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
                    report_value(marker.message),
                )
            )
        )
    lines.append(f"{title}_END")
    return lines


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--probe-root", type=Path, required=True)
    parser.add_argument("--step13-analysis", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()

    reports = args.probe_root / "reports"
    context_path = args.probe_root / "context.rpt"
    status_path = reports / "postfiller_stage_probe_status.rpt"
    command_path = reports / "postfiller_stage_probe_commands.rpt"
    post_cts_markers_path = reports / "drc_markers_post_cts_pre_filler.tsv"
    post_filler_markers_path = reports / "drc_markers_post_filler_pre_restitch.tsv"
    stage_reports = {
        "POST_CTS_DRC_VIOLATION_COUNT": reports / "verify_drc_post_cts_pre_filler.rpt",
        "POST_CTS_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": reports
        / "verify_connectivity_special_post_cts_pre_filler.rpt",
        "POST_CTS_REGULAR_CONNECTIVITY_VIOLATION_COUNT": reports
        / "verify_connectivity_regular_post_cts_pre_filler.rpt",
        "POST_FILLER_PRE_RESTITCH_DRC_VIOLATION_COUNT": reports
        / "verify_drc_post_filler_pre_restitch.rpt",
        "POST_FILLER_PRE_RESTITCH_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": reports
        / "verify_connectivity_special_post_filler_pre_restitch.rpt",
        "POST_FILLER_PRE_RESTITCH_REGULAR_CONNECTIVITY_VIOLATION_COUNT": reports
        / "verify_connectivity_regular_post_filler_pre_restitch.rpt",
    }
    required = (
        context_path,
        status_path,
        command_path,
        post_cts_markers_path,
        post_filler_markers_path,
        args.step13_analysis,
        *stage_reports.values(),
    )
    missing = [path for path in required if not path.is_file()]
    args.report.parent.mkdir(parents=True, exist_ok=True)
    if missing:
        args.report.write_text(
            "LABEL=SPADMIC_TX_PACKET_POSTFILLER_STAGE_ANALYSIS\n"
            "POLICY=READ_ONLY_POST_CTS_FILLER_STAGE_ATTRIBUTION\n"
            "STATUS=FAIL\n"
            "RESULT=MISSING_REQUIRED_INPUTS\n"
            f"MISSING_INPUTS={' '.join(str(path) for path in missing)}\n"
        )
        return 8

    errors: list[str] = []
    context = read_kv(context_path)
    probe = read_kv(status_path)
    step13 = read_kv(args.step13_analysis)
    command_text = command_path.read_text(errors="replace")
    try:
        post_cts_markers = parse_markers(post_cts_markers_path)
        post_filler_markers = parse_markers(post_filler_markers_path)
    except ValueError as error:
        errors.append(str(error))
        post_cts_markers = []
        post_filler_markers = []

    expected_context = {
        "POLICY": "ONE_FRESH_PROCESS_ONE_RESTORE_POST_CTS_FILLER_STAGE_ATTRIBUTION",
        "DESIGN_MODIFICATION": "IN_MEMORY_FILLER_ONLY",
        "POST_FILLER_SROUTE": "NOT_RUN",
        "SOURCE_CHECKPOINT_WRITE": "NOT_RUN",
        "SAVE_DESIGN": "NOT_RUN",
        "EXPORT": "NOT_RUN",
        "PVS": "NOT_RUN",
        "FILLER_CELLS": EXPECTED_FILLER_CELLS,
        "FILLER_COMMAND": EXPECTED_FILLER_COMMAND,
    }
    for key, expected in expected_context.items():
        if context.get(key) != expected:
            errors.append(f"context_{key}={context.get(key, 'MISSING')} expected={expected}")

    expected_probe = {
        "LABEL": "SPADMIC_OOC_POSTFILLER_STAGE_PROBE",
        "POLICY": "ONE_FRESH_PROCESS_ONE_RESTORE_POST_CTS_FILLER_STAGE_ATTRIBUTION",
        "STATUS": "PASS",
        "RESULT": "POSTFILLER_STAGE_EVIDENCE_CAPTURED",
        "RESTORE_DESIGN": "PASS",
        "DESIGN_MODIFICATION": "IN_MEMORY_FILLER_ONLY",
        "POST_FILLER_SROUTE": "NOT_RUN",
        "SOURCE_CHECKPOINT_WRITE": "NOT_RUN",
        "SAVE_DESIGN": "NOT_RUN",
        "EXPORT": "NOT_RUN",
        "PVS": "NOT_RUN",
        "FILLER_MODE_STATUS": "PASS",
        "ADD_FILLER_STATUS": "PASS",
        "ADD_FILLER_COMMAND": EXPECTED_FILLER_COMMAND,
    }
    for prefix in ("POST_CTS", "POST_FILLER_PRE_RESTITCH"):
        expected_probe[f"{prefix}_DRC_CAPTURE_STATUS"] = "PASS"
        expected_probe[f"{prefix}_DRC_MARKER_DUMP_STATUS"] = "PASS"
        expected_probe[f"{prefix}_SPECIAL_CONNECTIVITY_CAPTURE_STATUS"] = "PASS"
        expected_probe[f"{prefix}_REGULAR_CONNECTIVITY_CAPTURE_STATUS"] = "PASS"
    for key, expected in expected_probe.items():
        if probe.get(key) != expected:
            errors.append(f"probe_{key}={probe.get(key, 'MISSING')} expected={expected}")

    expected_step13 = {
        "STATUS": "PASS",
        "RESULT": "PREROUTE_PG_CANDIDATE_CLASSIFIED",
        "CANDIDATE_PHYSICAL_STATUS": "REJECTED_POST_FILLER_RESTITCH_MILESTONE",
        "PRE_CTS_SPECIAL_CONNECTIVITY_STATUS": "EXPECTED_DANGLING_ONLY",
        "PRE_CTS_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": "156",
        "PRE_CTS_IMPVFC_94_DANGLING_COUNT": "156",
        "PRE_CTS_OTHER_PROBLEM_COUNT": "0",
        "PRE_CTS_DRC_STATUS": "PASS",
        "PRE_CTS_DRC_VIOLATION_COUNT": "0",
        "POST_FILLER_RESTITCH_ENABLED": "YES",
        "POST_FILLER_SROUTE_STATUS": "PASS",
        "POST_FILLER_SPECIAL_CONNECTIVITY_STATUS": "PASS",
        "POST_FILLER_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": "0",
        "POST_FILLER_DRC_STATUS": "FAIL",
        "POST_FILLER_DRC_VIOLATION_COUNT": "165",
    }
    for key, expected in expected_step13.items():
        if step13.get(key) != expected:
            errors.append(f"step13_{key}={step13.get(key, 'MISSING')} expected={expected}")

    if context.get("SOURCE_ROOT") != step13.get("BLOCK_ROOT"):
        errors.append("probe source root does not match the Step 13 candidate block root")
    if context.get("SOURCE_RUN_HEAD") != step13.get("RUN_HEAD"):
        errors.append("probe source run HEAD does not match the Step 13 candidate HEAD")
    source_checkpoint = context.get("SOURCE_CHECKPOINT", "")
    if not source_checkpoint.endswith(("/checkpoints/03_cts.enc.dat", "/checkpoints/03_cts.enc")):
        errors.append(
            f"context_SOURCE_CHECKPOINT={source_checkpoint or 'MISSING'} is not post-CTS"
        )
    if probe.get("SOURCE_CHECKPOINT") != source_checkpoint:
        errors.append("probe status and context disagree on source checkpoint")

    command_lines = [line for line in command_text.splitlines() if "COMMAND=" in line or line.startswith("TRY_")]
    if command_text.count(f"ADD_FILLER_COMMAND={EXPECTED_FILLER_COMMAND}") != 1:
        errors.append("command report does not contain one canonical filler command")
    if "FILLER_MODE_STATUS=PASS" not in command_text or "ADD_FILLER_STATUS=PASS" not in command_text:
        errors.append("command report does not prove filler-mode and filler command success")
    if any(re.search(r"(?:^|\s)sroute(?:\s|$)", line, flags=re.IGNORECASE) for line in command_lines):
        errors.append("command report contains a forbidden sroute command")

    integer_keys = (
        "POST_CTS_DRC_VIOLATION_COUNT",
        "POST_CTS_DRC_MARKER_COUNT",
        "POST_CTS_MARKER_DATABASE_TOTAL",
        "POST_CTS_EXCLUDED_ANTENNA_MARKER_COUNT",
        "POST_CTS_EXCLUDED_CONNECTIVITY_MARKER_COUNT",
        "POST_CTS_SPECIAL_CONNECTIVITY_VIOLATION_COUNT",
        "POST_CTS_REGULAR_CONNECTIVITY_VIOLATION_COUNT",
        "POST_FILLER_PRE_RESTITCH_DRC_VIOLATION_COUNT",
        "POST_FILLER_PRE_RESTITCH_DRC_MARKER_COUNT",
        "POST_FILLER_PRE_RESTITCH_MARKER_DATABASE_TOTAL",
        "POST_FILLER_PRE_RESTITCH_EXCLUDED_ANTENNA_MARKER_COUNT",
        "POST_FILLER_PRE_RESTITCH_EXCLUDED_CONNECTIVITY_MARKER_COUNT",
        "POST_FILLER_PRE_RESTITCH_SPECIAL_CONNECTIVITY_VIOLATION_COUNT",
        "POST_FILLER_PRE_RESTITCH_REGULAR_CONNECTIVITY_VIOLATION_COUNT",
    )
    counts = {key: int_field(probe, key, errors) for key in integer_keys}

    for prefix, markers in (
        ("POST_CTS", post_cts_markers),
        ("POST_FILLER_PRE_RESTITCH", post_filler_markers),
    ):
        drc_count = counts[f"{prefix}_DRC_VIOLATION_COUNT"]
        marker_count = counts[f"{prefix}_DRC_MARKER_COUNT"]
        raw_count = counts[f"{prefix}_MARKER_DATABASE_TOTAL"]
        antenna_count = counts[f"{prefix}_EXCLUDED_ANTENNA_MARKER_COUNT"]
        connectivity_count = counts[f"{prefix}_EXCLUDED_CONNECTIVITY_MARKER_COUNT"]
        if marker_count is not None and len(markers) != marker_count:
            errors.append(f"{prefix} TSV rows {len(markers)} do not match {marker_count}")
        if drc_count is not None and marker_count != drc_count:
            errors.append(f"{prefix} marker count {marker_count} does not match DRC {drc_count}")
        if raw_count is not None and None not in (marker_count, antenna_count, connectivity_count):
            if raw_count != marker_count + antenna_count + connectivity_count:
                errors.append(f"{prefix} marker database accounting does not balance")

    for key, path in stage_reports.items():
        measured = verification_count(path)
        if measured is None:
            errors.append(f"cannot parse one unambiguous count from {path}")
        elif counts[key] != measured:
            errors.append(f"probe_{key}={counts[key]} report={measured}")

    new_filler_markers = counter_difference(post_filler_markers, post_cts_markers)
    removed_filler_markers = counter_difference(post_cts_markers, post_filler_markers)
    post_cts_drc = counts["POST_CTS_DRC_VIOLATION_COUNT"]
    post_filler_drc = counts["POST_FILLER_PRE_RESTITCH_DRC_VIOLATION_COUNT"]
    post_filler_special = counts[
        "POST_FILLER_PRE_RESTITCH_SPECIAL_CONNECTIVITY_VIOLATION_COUNT"
    ]
    post_filler_regular = counts[
        "POST_FILLER_PRE_RESTITCH_REGULAR_CONNECTIVITY_VIOLATION_COUNT"
    ]
    if post_cts_drc is not None and post_filler_drc is not None:
        drc_delta = post_filler_drc - post_cts_drc
        marker_delta = len(new_filler_markers) - len(removed_filler_markers)
        if marker_delta != drc_delta:
            errors.append(
                f"filler marker-set delta {marker_delta} does not match DRC delta {drc_delta}"
            )
    else:
        drc_delta = None

    if errors:
        stage_attribution = "INCOMPLETE"
        restitch_necessity = "UNKNOWN"
        next_decision = "STOP_AND_REPAIR_STAGE_ATTRIBUTION_EVIDENCE"
    else:
        restitch_necessity = (
            "NOT_REQUIRED_CONNECTIVITY_ALREADY_ZERO"
            if post_filler_special == 0 and post_filler_regular == 0
            else "REQUIRED_FOR_SPECIAL_CONNECTIVITY"
            if post_filler_special and post_filler_special > 0 and post_filler_regular == 0
            else "REVIEW_CONNECTIVITY_STATE"
        )
        if post_cts_drc and post_cts_drc > 0 and post_filler_drc and post_filler_drc > post_cts_drc:
            stage_attribution = "CTS_AND_FILLER_STAGES_INTRODUCE_DRC"
            next_decision = "STOP_AND_REVIEW_POST_CTS_AND_FILLER_MARKER_TABLES"
        elif post_cts_drc and post_cts_drc > 0:
            stage_attribution = "CTS_STAGE_INTRODUCES_DRC"
            next_decision = "STOP_AND_REVIEW_POST_CTS_MARKER_TABLE"
        elif post_cts_drc == 0 and post_filler_drc and post_filler_drc > 0:
            stage_attribution = "FILLER_STAGE_INTRODUCES_DRC"
            next_decision = "STOP_AND_REVIEW_FILLER_NEW_MARKER_TABLE"
        elif post_cts_drc == 0 and post_filler_drc == 0:
            stage_attribution = "POST_FILLER_SROUTE_INTRODUCES_DRC"
            if restitch_necessity == "NOT_REQUIRED_CONNECTIVITY_ALREADY_ZERO":
                next_decision = "OMIT_REDUNDANT_POST_FILLER_SROUTE_IN_NEXT_FRESH_CANDIDATE"
            elif restitch_necessity == "REQUIRED_FOR_SPECIAL_CONNECTIVITY":
                next_decision = "DESIGN_BOUNDED_DRC_SAFE_POST_FILLER_STITCH_METHOD"
            else:
                next_decision = "REVIEW_PRE_RESTITCH_CONNECTIVITY_BEFORE_NEW_CANDIDATE"
        else:
            stage_attribution = "REVIEW_REQUIRED"
            next_decision = "STOP_AND_REVIEW_STAGE_COUNTS"

    layer_counts = Counter(marker.layer for marker in new_filler_markers)
    class_counts = Counter((marker.layer, marker.subtype) for marker in new_filler_markers)
    status = "PASS" if not errors else "FAIL"
    result = (
        "POSTFILLER_STAGE_ATTRIBUTION_CLASSIFIED"
        if not errors
        else "POSTFILLER_STAGE_ATTRIBUTION_INCOMPLETE"
    )
    lines = [
        "LABEL=SPADMIC_TX_PACKET_POSTFILLER_STAGE_ANALYSIS",
        "POLICY=READ_ONLY_POST_CTS_FILLER_STAGE_ATTRIBUTION",
        f"STATUS={status}",
        f"RESULT={result}",
        f"PROBE_ROOT={args.probe_root}",
        f"SOURCE_BLOCK_ROOT={context.get('SOURCE_ROOT', 'MISSING')}",
        f"SOURCE_RUN_HEAD={context.get('SOURCE_RUN_HEAD', 'MISSING')}",
        f"REPORT_DRIVER_HEAD={context.get('REPORT_DRIVER_HEAD', 'MISSING')}",
        f"SOURCE_CHECKPOINT={source_checkpoint or 'MISSING'}",
        f"STAGE_ATTRIBUTION={stage_attribution}",
        f"POST_FILLER_RESTITCH_ELECTRICAL_NECESSITY={restitch_necessity}",
        f"POST_CTS_DRC_VIOLATION_COUNT={post_cts_drc if post_cts_drc is not None else 'UNKNOWN'}",
        f"POST_CTS_SPECIAL_CONNECTIVITY_VIOLATION_COUNT={counts['POST_CTS_SPECIAL_CONNECTIVITY_VIOLATION_COUNT'] if counts['POST_CTS_SPECIAL_CONNECTIVITY_VIOLATION_COUNT'] is not None else 'UNKNOWN'}",
        f"POST_CTS_REGULAR_CONNECTIVITY_VIOLATION_COUNT={counts['POST_CTS_REGULAR_CONNECTIVITY_VIOLATION_COUNT'] if counts['POST_CTS_REGULAR_CONNECTIVITY_VIOLATION_COUNT'] is not None else 'UNKNOWN'}",
        f"POST_FILLER_PRE_RESTITCH_DRC_VIOLATION_COUNT={post_filler_drc if post_filler_drc is not None else 'UNKNOWN'}",
        f"POST_FILLER_PRE_RESTITCH_SPECIAL_CONNECTIVITY_VIOLATION_COUNT={post_filler_special if post_filler_special is not None else 'UNKNOWN'}",
        f"POST_FILLER_PRE_RESTITCH_REGULAR_CONNECTIVITY_VIOLATION_COUNT={post_filler_regular if post_filler_regular is not None else 'UNKNOWN'}",
        "STEP13_POST_RESTITCH_SPECIAL_CONNECTIVITY_VIOLATION_COUNT=0",
        "STEP13_POST_RESTITCH_DRC_VIOLATION_COUNT=165",
        f"FILLER_DRC_MARKER_DELTA={drc_delta if drc_delta is not None else 'UNKNOWN'}",
        f"FILLER_NEW_DRC_MARKER_COUNT={len(new_filler_markers)}",
        f"FILLER_REMOVED_DRC_MARKER_COUNT={len(removed_filler_markers)}",
        f"FILLER_NEW_MARKER_LAYER_COUNTS={format_counter(layer_counts)}",
        f"FILLER_NEW_MARKER_LAYER_SUBTYPE_COUNTS={format_counter(class_counts, '/')}",
        f"NEXT_METHOD_DECISION={next_decision}",
        "CANONICAL_RERUN_DECISION=BLOCKED_PENDING_OPERATOR_REVIEW",
        "SAVE_DESIGN=NOT_RUN",
        "EXPORT=NOT_RUN",
        "IMMUTABLE_PVS_STAGING=NOT_RUN",
        "PVS_DECISION=DO_NOT_RUN",
        f"CONTEXT_SHA256={sha256(context_path)}",
        f"PROBE_STATUS_SHA256={sha256(status_path)}",
        f"COMMAND_REPORT_SHA256={sha256(command_path)}",
        f"POST_CTS_MARKERS_SHA256={sha256(post_cts_markers_path)}",
        f"POST_FILLER_MARKERS_SHA256={sha256(post_filler_markers_path)}",
        f"STEP13_ANALYSIS_SHA256={sha256(args.step13_analysis)}",
        f"ERROR_COUNT={len(errors)}",
    ]
    lines.extend(f"ERROR={report_value(error)}" for error in errors)
    lines.extend(marker_table("FILLER_NEW_DRC_MARKER_TABLE", new_filler_markers))
    lines.extend(marker_table("FILLER_REMOVED_DRC_MARKER_TABLE", removed_filler_markers))
    args.report.write_text("\n".join(lines) + "\n")
    return 0 if not errors else 8


if __name__ == "__main__":
    raise SystemExit(main())
