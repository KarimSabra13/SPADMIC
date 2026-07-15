#!/usr/bin/env python3
"""Classify the round-number post-CTS VIA1 capture without loading Innovus."""

from __future__ import annotations

import argparse
import re
from collections import Counter
from pathlib import Path

from analyze_tx_packet_pg_via_drc import (
    Marker,
    counter_difference,
    parse_markers,
    read_kv,
    report_value,
    sha256,
)


EXPECTED_CAPTURED_DRC_COUNT = 1000


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


def format_counter(counter: Counter[object], separator: str = "/") -> str:
    if not counter:
        return "NONE"
    return " ".join(
        f"{separator.join(key) if isinstance(key, tuple) else key}:{counter[key]}"
        for key in sorted(counter, key=lambda item: str(item))
    )


def parse_layer_totals(path: Path) -> Counter[str]:
    totals: Counter[str] = Counter()
    in_summary = False
    for raw in path.read_text(errors="replace").splitlines():
        if "Violation Summary By Layer and Type" in raw:
            in_summary = True
            continue
        if not in_summary:
            continue
        stripped = raw.strip()
        if stripped.startswith("*** End"):
            break
        fields = stripped.split()
        if len(fields) < 2 or fields[0].lower() == "totals":
            continue
        if not re.fullmatch(
            r"(?:MET|VIA|POLY|CONT|DIFF|NWELL|PIMP|NIMP)[A-Z0-9_]*",
            fields[0],
        ):
            continue
        numeric = [field for field in fields[1:] if re.fullmatch(r"\d+", field)]
        if numeric:
            totals[fields[0]] += int(numeric[-1])
    return totals


def normalize_message(message: str) -> str:
    value = message.split(" #", 1)[0]
    value = re.sub(
        r"\b(Regular|Special)\s+(Wire|Via)\s+of\s+Net\s+[^\s&;,]+",
        r"\1 \2 of Net <NET>",
        value,
        flags=re.IGNORECASE,
    )
    value = re.sub(r"\bPIN:\s*[^\s;,]+", "PIN: <PIN>", value, flags=re.IGNORECASE)
    value = re.sub(
        r"\b(?:Instance|Cell)\s+[^\s&;,]+",
        lambda match: match.group(0).split()[0] + " <OBJECT>",
        value,
        flags=re.IGNORECASE,
    )
    value = re.sub(r"0x[0-9a-f]+", "<HEX>", value, flags=re.IGNORECASE)
    value = re.sub(r"(?<![A-Za-z_])[-+]?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?", "<N>", value)
    return " ".join(value.split()) or "UNKNOWN"


def extract_named_objects(markers: list[Marker], qualifier: str) -> Counter[str]:
    pattern = re.compile(
        rf"\b{qualifier}\s+(?:Wire|Via)\s+of\s+Net\s+([^\s&;,]+)",
        flags=re.IGNORECASE,
    )
    counts: Counter[str] = Counter()
    for marker in markers:
        for name in pattern.findall(marker.message):
            counts[name] += 1
    return counts


def top_counter(counter: Counter[str], limit: int = 30) -> str:
    if not counter:
        return "NONE"
    return " ".join(f"{name}:{count}" for name, count in counter.most_common(limit))


def marker_extent(markers: list[Marker]) -> str:
    if not markers:
        return "UNKNOWN"
    return (
        f"{{{min(marker.llx for marker in markers):.6f} "
        f"{min(marker.lly for marker in markers):.6f} "
        f"{max(marker.urx for marker in markers):.6f} "
        f"{max(marker.ury for marker in markers):.6f}}}"
    )


def template_table(markers: list[Marker], limit: int = 30) -> list[str]:
    grouped: dict[tuple[str, str, str], list[Marker]] = {}
    for marker in markers:
        key = (marker.layer, marker.subtype, normalize_message(marker.message))
        grouped.setdefault(key, []).append(marker)
    ordered = sorted(grouped.items(), key=lambda item: (-len(item[1]), item[0]))
    lines = [
        "POST_CTS_RULE_TEMPLATE_TABLE_BEGIN",
        "rank\tcount\tlayer\tsubType\trepresentative_index\tbox\ttemplate\trepresentative_message",
    ]
    for rank, ((layer, subtype, template), members) in enumerate(
        ordered[:limit], start=1
    ):
        representative = members[0]
        lines.append(
            "\t".join(
                (
                    str(rank),
                    str(len(members)),
                    report_value(layer),
                    report_value(subtype),
                    representative.post_index,
                    report_value(representative.box),
                    report_value(template),
                    report_value(representative.message),
                )
            )
        )
    lines.append("POST_CTS_RULE_TEMPLATE_TABLE_END")
    return lines


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--probe-root", type=Path, required=True)
    parser.add_argument("--step13-block-root", type=Path, required=True)
    parser.add_argument("--step13-analysis", type=Path, required=True)
    parser.add_argument("--step14-analysis", type=Path, required=True)
    parser.add_argument("--report-driver-head", required=True)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()

    probe_reports = args.probe_root / "reports"
    context_path = args.probe_root / "context.rpt"
    probe_status_path = probe_reports / "postfiller_stage_probe_status.rpt"
    post_cts_markers_path = probe_reports / "drc_markers_post_cts_pre_filler.tsv"
    post_filler_markers_path = probe_reports / "drc_markers_post_filler_pre_restitch.tsv"
    post_cts_drc_path = probe_reports / "verify_drc_post_cts_pre_filler.rpt"
    post_filler_drc_path = probe_reports / "verify_drc_post_filler_pre_restitch.rpt"
    post_cts_special_path = probe_reports / "verify_connectivity_special_post_cts_pre_filler.rpt"
    post_filler_special_path = (
        probe_reports / "verify_connectivity_special_post_filler_pre_restitch.rpt"
    )
    post_cts_regular_path = probe_reports / "verify_connectivity_regular_post_cts_pre_filler.rpt"
    post_filler_regular_path = (
        probe_reports / "verify_connectivity_regular_post_filler_pre_restitch.rpt"
    )
    step13_post_restitch_drc_path = (
        args.step13_block_root / "reports" / "PG_POST_FILLER_DRC.rpt"
    )
    step13_post_restitch_special_path = (
        args.step13_block_root / "reports" / "PG_POST_FILLER_CONNECTIVITY.rpt"
    )
    required = (
        context_path,
        probe_status_path,
        post_cts_markers_path,
        post_filler_markers_path,
        post_cts_drc_path,
        post_filler_drc_path,
        post_cts_special_path,
        post_filler_special_path,
        post_cts_regular_path,
        post_filler_regular_path,
        step13_post_restitch_drc_path,
        step13_post_restitch_special_path,
        args.step13_analysis,
        args.step14_analysis,
    )
    args.report.parent.mkdir(parents=True, exist_ok=True)
    missing = [path for path in required if not path.is_file()]
    if missing:
        args.report.write_text(
            "LABEL=SPADMIC_TX_PACKET_POSTCTS_VIA1_MARKER_ANALYSIS\n"
            "POLICY=READ_ONLY_EXISTING_TEXT_ARTIFACT_ANALYSIS\n"
            "STATUS=FAIL\n"
            "RESULT=MISSING_REQUIRED_INPUTS\n"
            f"MISSING_INPUTS={' '.join(str(path) for path in missing)}\n"
        )
        return 8

    errors: list[str] = []
    context = read_kv(context_path)
    probe = read_kv(probe_status_path)
    step13 = read_kv(args.step13_analysis)
    step14 = read_kv(args.step14_analysis)
    try:
        post_cts_markers = parse_markers(post_cts_markers_path)
        post_filler_markers = parse_markers(post_filler_markers_path)
    except ValueError as error:
        errors.append(str(error))
        post_cts_markers = []
        post_filler_markers = []

    expected_step14 = {
        "STATUS": "PASS",
        "RESULT": "POSTFILLER_STAGE_ATTRIBUTION_CLASSIFIED",
        "STAGE_ATTRIBUTION": "CTS_STAGE_INTRODUCES_DRC",
        "POST_CTS_DRC_VIOLATION_COUNT": "1000",
        "POST_CTS_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": "154",
        "POST_CTS_REGULAR_CONNECTIVITY_VIOLATION_COUNT": "239",
        "POST_FILLER_PRE_RESTITCH_DRC_VIOLATION_COUNT": "1000",
        "POST_FILLER_PRE_RESTITCH_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": "0",
        "POST_FILLER_PRE_RESTITCH_REGULAR_CONNECTIVITY_VIOLATION_COUNT": "239",
        "FILLER_DRC_MARKER_DELTA": "0",
        "FILLER_NEW_DRC_MARKER_COUNT": "0",
        "FILLER_REMOVED_DRC_MARKER_COUNT": "0",
        "SAVE_DESIGN": "NOT_RUN",
        "EXPORT": "NOT_RUN",
        "IMMUTABLE_PVS_STAGING": "NOT_RUN",
        "PVS_DECISION": "DO_NOT_RUN",
    }
    for key, expected in expected_step14.items():
        if step14.get(key) != expected:
            errors.append(f"step14_{key}={step14.get(key, 'MISSING')} expected={expected}")

    expected_probe = {
        "STATUS": "PASS",
        "RESULT": "POSTFILLER_STAGE_EVIDENCE_CAPTURED",
        "RESTORE_DESIGN": "PASS",
        "POST_FILLER_SROUTE": "NOT_RUN",
        "SOURCE_CHECKPOINT_WRITE": "NOT_RUN",
        "SAVE_DESIGN": "NOT_RUN",
        "EXPORT": "NOT_RUN",
        "PVS": "NOT_RUN",
        "POST_CTS_DRC_VIOLATION_COUNT": "1000",
        "POST_CTS_DRC_MARKER_COUNT": "1000",
        "POST_CTS_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": "154",
        "POST_CTS_REGULAR_CONNECTIVITY_VIOLATION_COUNT": "239",
        "POST_FILLER_PRE_RESTITCH_DRC_VIOLATION_COUNT": "1000",
        "POST_FILLER_PRE_RESTITCH_DRC_MARKER_COUNT": "1000",
        "POST_FILLER_PRE_RESTITCH_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": "0",
        "POST_FILLER_PRE_RESTITCH_REGULAR_CONNECTIVITY_VIOLATION_COUNT": "239",
    }
    for key, expected in expected_probe.items():
        if probe.get(key) != expected:
            errors.append(f"probe_{key}={probe.get(key, 'MISSING')} expected={expected}")

    expected_step13 = {
        "STATUS": "PASS",
        "RESULT": "PREROUTE_PG_CANDIDATE_CLASSIFIED",
        "BLOCK_ROOT": str(args.step13_block_root),
        "POST_FILLER_SPECIAL_CONNECTIVITY_STATUS": "PASS",
        "POST_FILLER_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": "0",
        "POST_FILLER_DRC_STATUS": "FAIL",
        "POST_FILLER_DRC_VIOLATION_COUNT": "165",
    }
    for key, expected in expected_step13.items():
        if step13.get(key) != expected:
            errors.append(f"step13_{key}={step13.get(key, 'MISSING')} expected={expected}")

    if context.get("SOURCE_ROOT") != str(args.step13_block_root):
        errors.append("probe source root does not match the Step 13 block root")
    if context.get("SOURCE_RUN_HEAD") != step13.get("RUN_HEAD"):
        errors.append("probe source run HEAD does not match Step 13")
    if context.get("REPORT_DRIVER_HEAD") != step14.get("REPORT_DRIVER_HEAD"):
        errors.append("probe and Step 14 report-driver HEAD values disagree")
    if len(post_cts_markers) != EXPECTED_CAPTURED_DRC_COUNT:
        errors.append(
            f"post-CTS marker rows={len(post_cts_markers)} expected={EXPECTED_CAPTURED_DRC_COUNT}"
        )
    if len(post_filler_markers) != EXPECTED_CAPTURED_DRC_COUNT:
        errors.append(
            f"post-filler marker rows={len(post_filler_markers)} expected={EXPECTED_CAPTURED_DRC_COUNT}"
        )

    new_after_filler = counter_difference(post_filler_markers, post_cts_markers)
    removed_after_filler = counter_difference(
        post_cts_markers, post_filler_markers
    )
    if new_after_filler or removed_after_filler:
        errors.append(
            "filler changed marker signatures "
            f"new={len(new_after_filler)} removed={len(removed_after_filler)}"
        )

    measured_reports = {
        "POST_CTS_DRC": (post_cts_drc_path, 1000),
        "POST_FILLER_DRC": (post_filler_drc_path, 1000),
        "POST_CTS_SPECIAL": (post_cts_special_path, 154),
        "POST_FILLER_SPECIAL": (post_filler_special_path, 0),
        "POST_CTS_REGULAR": (post_cts_regular_path, 239),
        "POST_FILLER_REGULAR": (post_filler_regular_path, 239),
        "STEP13_POST_RESTITCH_DRC": (step13_post_restitch_drc_path, 165),
        "STEP13_POST_RESTITCH_SPECIAL": (step13_post_restitch_special_path, 0),
    }
    measured_counts: dict[str, int | None] = {}
    for key, (path, expected) in measured_reports.items():
        measured_counts[key] = verification_count(path)
        if measured_counts[key] != expected:
            errors.append(f"{key}_report_count={measured_counts[key]} expected={expected}")

    layer_counts = Counter(marker.layer for marker in post_cts_markers)
    type_counts = Counter(marker.marker_type for marker in post_cts_markers)
    subtype_counts = Counter(marker.subtype for marker in post_cts_markers)
    layer_subtype_counts = Counter(
        (marker.layer, marker.subtype) for marker in post_cts_markers
    )
    if layer_counts != Counter({"VIA1": EXPECTED_CAPTURED_DRC_COUNT}):
        errors.append(
            f"post-CTS marker layers={format_counter(layer_counts)} expected=VIA1:1000"
        )

    post_cts_layer_totals = parse_layer_totals(post_cts_drc_path)
    post_filler_layer_totals = parse_layer_totals(post_filler_drc_path)
    if post_cts_layer_totals != Counter({"VIA1": EXPECTED_CAPTURED_DRC_COUNT}):
        errors.append(
            f"post-CTS DRC summary={format_counter(post_cts_layer_totals)} expected=VIA1:1000"
        )
    if post_filler_layer_totals != Counter({"VIA1": EXPECTED_CAPTURED_DRC_COUNT}):
        errors.append(
            f"post-filler DRC summary={format_counter(post_filler_layer_totals)} expected=VIA1:1000"
        )

    regular_nets = extract_named_objects(post_cts_markers, "Regular")
    special_nets = extract_named_objects(post_cts_markers, "Special")
    templates = Counter(normalize_message(marker.message) for marker in post_cts_markers)
    step13_layer_totals = parse_layer_totals(step13_post_restitch_drc_path)
    capture_interpretation = "AT_LEAST_1000_EXACT_TOTAL_UNPROVEN"
    signature_status = (
        "PASS_IDENTICAL_BEFORE_AND_AFTER_FILLER"
        if not new_after_filler and not removed_after_filler
        else "FAIL_CHANGED"
    )
    status = "PASS" if not errors else "FAIL"
    result = (
        "POST_CTS_VIA1_MARKERS_CLASSIFIED"
        if not errors
        else "POST_CTS_VIA1_MARKER_CLASSIFICATION_INCOMPLETE"
    )
    lines = [
        "LABEL=SPADMIC_TX_PACKET_POSTCTS_VIA1_MARKER_ANALYSIS",
        "POLICY=READ_ONLY_EXISTING_TEXT_ARTIFACT_ANALYSIS",
        f"STATUS={status}",
        f"RESULT={result}",
        f"PROBE_ROOT={args.probe_root}",
        f"STEP13_BLOCK_ROOT={args.step13_block_root}",
        f"SOURCE_RUN_HEAD={step13.get('RUN_HEAD', 'MISSING')}",
        f"SOURCE_STEP14_REPORT_DRIVER_HEAD={step14.get('REPORT_DRIVER_HEAD', 'MISSING')}",
        f"REPORT_DRIVER_HEAD={args.report_driver_head}",
        f"POST_CTS_CAPTURED_DRC_MARKER_COUNT={len(post_cts_markers)}",
        f"POST_CTS_DRC_COUNT_INTERPRETATION={capture_interpretation}",
        "POST_CTS_CAPTURE_COMPLETENESS=UNPROVEN_EXACTLY_1000_REPORTED_AND_DUMPED",
        f"POST_CTS_MARKER_SIGNATURE_STABILITY={signature_status}",
        f"POST_CTS_MARKER_LAYER_COUNTS={format_counter(layer_counts)}",
        f"POST_CTS_MARKER_TYPE_COUNTS={format_counter(type_counts)}",
        f"POST_CTS_MARKER_SUBTYPE_COUNTS={format_counter(subtype_counts)}",
        f"POST_CTS_MARKER_LAYER_SUBTYPE_COUNTS={format_counter(layer_subtype_counts)}",
        f"POST_CTS_RULE_TEMPLATE_UNIQUE_COUNT={len(templates)}",
        f"POST_CTS_RULE_TEMPLATE_TABLE_ROW_COUNT={min(len(templates), 30)}",
        f"POST_CTS_RULE_TEMPLATE_TABLE_TRUNCATED={'YES' if len(templates) > 30 else 'NO'}",
        f"POST_CTS_REGULAR_NET_UNIQUE_COUNT={len(regular_nets)}",
        f"POST_CTS_REGULAR_NET_TOP_COUNTS={top_counter(regular_nets)}",
        f"POST_CTS_SPECIAL_NET_UNIQUE_COUNT={len(special_nets)}",
        f"POST_CTS_SPECIAL_NET_TOP_COUNTS={top_counter(special_nets)}",
        f"POST_CTS_MARKER_EXTENT_UM={marker_extent(post_cts_markers)}",
        f"POST_CTS_UNIQUE_CENTER_X_COUNT={len({round(marker.cx, 6) for marker in post_cts_markers})}",
        f"POST_CTS_UNIQUE_CENTER_Y_COUNT={len({round(marker.cy, 6) for marker in post_cts_markers})}",
        f"POST_CTS_DRC_REPORT_LAYER_TOTALS={format_counter(post_cts_layer_totals)}",
        f"POST_FILLER_DRC_REPORT_LAYER_TOTALS={format_counter(post_filler_layer_totals)}",
        f"STEP13_POST_RESTITCH_DRC_VIOLATION_COUNT={measured_counts['STEP13_POST_RESTITCH_DRC'] if measured_counts['STEP13_POST_RESTITCH_DRC'] is not None else 'UNKNOWN'}",
        f"STEP13_POST_RESTITCH_DRC_REPORT_LAYER_TOTALS={format_counter(step13_layer_totals)}",
        "STEP13_COUNT_COMPARABILITY=NOT_NUMERICALLY_COMPARABLE_PRE_RESTITCH_EXACT_TOTAL_UNPROVEN_AND_GEOMETRY_CHANGED",
        "FILLER_DRC_EFFECT=NO_CAPTURED_SIGNATURE_CHANGE",
        "FILLER_SPECIAL_CONNECTIVITY_EFFECT=CLOSED_154_TO_0_WITHOUT_SROUTE",
        "POST_FILLER_SROUTE_ELECTRICAL_NECESSITY=NOT_REQUIRED_FOR_SPECIAL_CONNECTIVITY",
        "REGULAR_CONNECTIVITY_INTERPRETATION=PRE_SIGNAL_ROUTE_OBSERVATION_NOT_A_FINAL_CONNECTIVITY_GATE",
        "NEXT_METHOD_DECISION=REVIEW_VIA1_RULE_TEMPLATES_AND_CTS_VIA_GENERATION_BEFORE_ANY_NEW_CANDIDATE",
        "CANONICAL_RERUN_DECISION=BLOCKED_PENDING_OPERATOR_REVIEW",
        "SAVE_DESIGN=NOT_RUN",
        "EXPORT=NOT_RUN",
        "IMMUTABLE_PVS_STAGING=NOT_RUN",
        "PVS_DECISION=DO_NOT_RUN",
        f"CONTEXT_SHA256={sha256(context_path)}",
        f"PROBE_STATUS_SHA256={sha256(probe_status_path)}",
        f"POST_CTS_MARKERS_SHA256={sha256(post_cts_markers_path)}",
        f"POST_FILLER_MARKERS_SHA256={sha256(post_filler_markers_path)}",
        f"POST_CTS_DRC_SHA256={sha256(post_cts_drc_path)}",
        f"POST_FILLER_DRC_SHA256={sha256(post_filler_drc_path)}",
        f"STEP13_POST_RESTITCH_DRC_SHA256={sha256(step13_post_restitch_drc_path)}",
        f"STEP13_ANALYSIS_SHA256={sha256(args.step13_analysis)}",
        f"STEP14_ANALYSIS_SHA256={sha256(args.step14_analysis)}",
        f"ERROR_COUNT={len(errors)}",
    ]
    lines.extend(f"ERROR={report_value(error)}" for error in errors)
    lines.extend(template_table(post_cts_markers))
    args.report.write_text("\n".join(lines) + "\n")
    return 0 if not errors else 8


if __name__ == "__main__":
    raise SystemExit(main())
