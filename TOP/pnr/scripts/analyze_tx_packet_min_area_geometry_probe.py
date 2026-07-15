#!/usr/bin/env python3
"""Classify the read-only TX residual minimum-area geometry probe."""

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
EXPECTED_POLICY = "ONE_FRESH_PROCESS_ONE_RESTORE_READ_ONLY_LOCAL_GEOMETRY_PROBE"


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


def sorted_nets(rows: list[dict[str, str]], key: str = "net") -> tuple[str, ...]:
    return tuple(sorted({row.get(key, "") for row in rows if row.get(key, "")}))


def classify(
    probe_root: Path,
    step19_analysis: Path,
    report_driver_head: str,
    report: Path,
) -> dict[str, str]:
    reports = probe_root / "reports"
    context_path = probe_root / "context.rpt"
    status_path = reports / "min_area_geometry_probe_status.rpt"
    pre_markers_path = reports / "drc_markers_pre_probe.tsv"
    post_markers_path = reports / "drc_markers_post_probe.tsv"
    pre_drc_path = reports / "verify_drc_pre_probe.rpt"
    post_drc_path = reports / "verify_drc_post_probe.rpt"
    pre_regular_path = reports / "verify_connectivity_regular_pre_probe.rpt"
    post_regular_path = reports / "verify_connectivity_regular_post_probe.rpt"
    pre_special_path = reports / "verify_connectivity_special_pre_probe.rpt"
    post_special_path = reports / "verify_connectivity_special_post_probe.rpt"
    marker_geometry_path = reports / "min_area_marker_geometry.tsv"
    topology_path = reports / "min_area_net_topology.tsv"
    local_wires_path = reports / "min_area_local_wires.tsv"
    local_vias_path = reports / "min_area_local_vias.tsv"
    inst_terms_path = reports / "min_area_inst_terms.tsv"
    pin_shapes_path = reports / "min_area_pin_shapes.tsv"
    top_terms_path = reports / "min_area_top_terms.tsv"
    raw_queries_path = reports / "min_area_raw_queries.rpt"

    context = key_values(context_path)
    status = key_values(status_path)
    step19 = key_values(step19_analysis)
    errors: list[str] = []

    schema_paths = [
        reports / f"dbschema_{name}.rpt"
        for name in (
            "net",
            "wire",
            "instTerm",
            "inst",
            "term",
            "pin",
            "pinShape",
            "marker",
            "layerShape",
            "shape",
            "viaInst",
        )
    ]
    help_paths = [
        reports / f"man_{name}.rpt"
        for name in (
            "editAddRoute",
            "editCommitRoute",
            "setEditMode",
            "uiSetTool",
            "add_shape",
            "create_shape",
        )
    ]
    required = [
        context_path,
        status_path,
        step19_analysis,
        pre_markers_path,
        post_markers_path,
        pre_drc_path,
        post_drc_path,
        pre_regular_path,
        post_regular_path,
        pre_special_path,
        post_special_path,
        marker_geometry_path,
        topology_path,
        local_wires_path,
        local_vias_path,
        inst_terms_path,
        pin_shapes_path,
        top_terms_path,
        raw_queries_path,
        *schema_paths,
        *help_paths,
    ]
    for path in required:
        if not path.is_file():
            errors.append(f"missing_required_artifact={path}")

    expected_step19 = {
        "STATUS": "PASS",
        "RESULT": "ITERATIVE_MIN_AREA_TRIAL_CLASSIFIED",
        "TRIAL_REVISION": "R2",
        "TRIAL_PROCESS_STATUS": "FAIL",
        "TRIAL_PROCESS_RESULT": "ITERATIVE_MIN_AREA_REPAIR_NO_IMPROVEMENT",
        "METHOD_STATUS": "REJECTED_OR_INCOMPLETE",
        "PRE_DRC_VIOLATION_COUNT": "6",
        "FINAL_DRC_VIOLATION_COUNT": "6",
        "DRC_COUNT_SEQUENCE": "6 6",
        "ITERATION_COUNT": "1",
        "PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT": "0",
        "FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT": "0",
        "PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": "0",
        "FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": "0",
        "PRE_EXCLUDED_ANTENNA_MARKER_COUNT": "21",
        "FINAL_EXCLUDED_ANTENNA_MARKER_COUNT": "21",
        "PRE_MARKER_DATABASE_TOTAL": "27",
        "FINAL_MARKER_DATABASE_TOTAL": "27",
        "COMMAND_PASS_COUNT": "22",
        "COMMAND_FAIL_COUNT": "0",
        "PRE_MIN_AREA_NETS": " ".join(EXPECTED_NETS),
        "FINAL_MIN_AREA_NETS": " ".join(EXPECTED_NETS),
        "SAVE_DESIGN": "NOT_RUN",
        "EXPORT": "NOT_RUN",
        "PVS_DECISION": "DO_NOT_RUN",
        "ERROR_COUNT": "0",
    }
    for key, expected in expected_step19.items():
        if step19.get(key) != expected:
            errors.append(f"step19_{key}={step19.get(key, 'MISSING')} expected={expected}")

    expected_context = {
        "HEAD": report_driver_head,
        "POLICY": EXPECTED_POLICY,
        "DESIGN_MODIFICATION": "NOT_RUN",
        "SOURCE_CHECKPOINT_WRITE": "NOT_RUN",
        "SAVE_DESIGN": "NOT_RUN",
        "EXPORT": "NOT_RUN",
    }
    for key, expected in expected_context.items():
        if context.get(key) != expected:
            errors.append(f"context_{key}={context.get(key, 'MISSING')} expected={expected}")
    context_analysis = context.get("STEP19_ANALYSIS", "")
    if not context_analysis or Path(context_analysis).resolve() != step19_analysis:
        errors.append(
            f"context_STEP19_ANALYSIS={context_analysis or 'MISSING'} "
            f"expected={step19_analysis}"
        )

    expected_status = {
        "STATUS": "PASS",
        "RESULT": "MIN_AREA_LOCAL_GEOMETRY_EVIDENCE_CAPTURED",
        "POLICY": EXPECTED_POLICY,
        "DESIGN_MODIFICATION": "NOT_RUN",
        "SOURCE_CHECKPOINT_WRITE": "NOT_RUN",
        "SAVE_DESIGN": "NOT_RUN",
        "EXPORT": "NOT_RUN",
        "PVS": "NOT_RUN",
        "RESTORE_DESIGN": "PASS",
        "PRE_MIN_AREA_NETS": " ".join(EXPECTED_NETS),
        "POST_MIN_AREA_NETS": " ".join(EXPECTED_NETS),
        "NET_HANDLE_PASS_COUNT": "6",
        "SCHEMA_net_STATUS": "PASS",
        "SCHEMA_wire_STATUS": "PASS",
        "SCHEMA_instTerm_STATUS": "PASS",
        "SCHEMA_inst_STATUS": "PASS",
        "SCHEMA_term_STATUS": "PASS",
        "SCHEMA_pin_STATUS": "PASS",
        "SCHEMA_pinShape_STATUS": "PASS",
        "NEXT_METHOD_DECISION": (
            "REVIEW_LOCAL_WIRE_AND_TERMINAL_GEOMETRY_BEFORE_DIRECT_PATCH_TRIAL"
        ),
    }
    for key, expected in expected_status.items():
        if status.get(key) != expected:
            errors.append(f"probe_{key}={status.get(key, 'MISSING')} expected={expected}")
    status_analysis = status.get("STEP19_ANALYSIS", "")
    if not status_analysis or Path(status_analysis).resolve() != step19_analysis:
        errors.append(
            f"probe_STEP19_ANALYSIS={status_analysis or 'MISSING'} "
            f"expected={step19_analysis}"
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
        "POST_DRC_VIOLATION_COUNT",
        "POST_DRC_MARKER_COUNT",
        "POST_MARKER_DATABASE_TOTAL",
        "POST_EXCLUDED_ANTENNA_MARKER_COUNT",
        "POST_EXCLUDED_CONNECTIVITY_MARKER_COUNT",
        "POST_REGULAR_CONNECTIVITY_VIOLATION_COUNT",
        "POST_SPECIAL_CONNECTIVITY_VIOLATION_COUNT",
        "SCHEMA_PASS_COUNT",
        "SCHEMA_FAIL_COUNT",
        "HELP_PASS_COUNT",
        "HELP_UNAVAILABLE_COUNT",
        "QUERY_PASS_COUNT",
        "QUERY_FAIL_COUNT",
        "WIRE_QUERY_PASS_NET_COUNT",
        "LOCAL_WIRE_NET_COUNT",
        "LOCAL_WIRE_ROW_COUNT",
        "WIRE_CONTEXT_ROW_COUNT",
        "VIA_QUERY_PASS_NET_COUNT",
        "LOCAL_VIA_NET_COUNT",
        "LOCAL_VIA_ROW_COUNT",
        "VIA_CONTEXT_ROW_COUNT",
        "INST_TERM_NET_COUNT",
        "INST_TERM_ROW_COUNT",
        "TOP_TERM_ROW_COUNT",
        "PIN_SHAPE_NET_COUNT",
        "PIN_SHAPE_ROW_COUNT",
    )
    counts = {key: integer(status, key, errors) for key in count_keys}
    expected_tuple = {
        "PRE_DRC_VIOLATION_COUNT": 6,
        "PRE_DRC_MARKER_COUNT": 6,
        "PRE_MARKER_DATABASE_TOTAL": 27,
        "PRE_EXCLUDED_ANTENNA_MARKER_COUNT": 21,
        "PRE_EXCLUDED_CONNECTIVITY_MARKER_COUNT": 0,
        "PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT": 0,
        "PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": 0,
        "POST_DRC_VIOLATION_COUNT": 6,
        "POST_DRC_MARKER_COUNT": 6,
        "POST_MARKER_DATABASE_TOTAL": 27,
        "POST_EXCLUDED_ANTENNA_MARKER_COUNT": 21,
        "POST_EXCLUDED_CONNECTIVITY_MARKER_COUNT": 0,
        "POST_REGULAR_CONNECTIVITY_VIOLATION_COUNT": 0,
        "POST_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": 0,
    }
    for key, expected in expected_tuple.items():
        if counts.get(key) != expected:
            errors.append(f"probe_tuple_{key}={counts.get(key)} expected={expected}")

    report_counts = {
        "PRE_DRC_VIOLATION_COUNT": report_violation_count(pre_drc_path),
        "POST_DRC_VIOLATION_COUNT": report_violation_count(post_drc_path),
        "PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT": report_violation_count(
            pre_regular_path
        ),
        "POST_REGULAR_CONNECTIVITY_VIOLATION_COUNT": report_violation_count(
            post_regular_path
        ),
        "PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": report_violation_count(
            pre_special_path
        ),
        "POST_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": report_violation_count(
            post_special_path
        ),
    }
    for key, value in report_counts.items():
        if value != counts.get(key):
            errors.append(f"report_count_{key}={value} expected={counts.get(key)}")

    pre_markers = read_tsv(pre_markers_path)
    post_markers = read_tsv(post_markers_path)
    pre_signatures = sorted(marker_signature(row) for row in pre_markers)
    post_signatures = sorted(marker_signature(row) for row in post_markers)
    if len(pre_markers) != 6:
        errors.append(f"pre_marker_row_count={len(pre_markers)} expected=6")
    if len(post_markers) != 6:
        errors.append(f"post_marker_row_count={len(post_markers)} expected=6")
    pre_marker_nets = tuple(sorted(marker_net(row) for row in pre_markers))
    post_marker_nets = tuple(sorted(marker_net(row) for row in post_markers))
    if pre_marker_nets != EXPECTED_NETS:
        errors.append(f"pre_marker_nets={pre_marker_nets} expected={EXPECTED_NETS}")
    if post_marker_nets != EXPECTED_NETS:
        errors.append(f"post_marker_nets={post_marker_nets} expected={EXPECTED_NETS}")
    if pre_signatures != post_signatures:
        errors.append("marker_signature_changed_across_read_only_probe")

    marker_geometry = read_tsv(marker_geometry_path)
    topology = read_tsv(topology_path)
    local_wires = read_tsv(local_wires_path)
    local_vias = read_tsv(local_vias_path)
    inst_terms = read_tsv(inst_terms_path)
    pin_shapes = read_tsv(pin_shapes_path)
    top_terms = read_tsv(top_terms_path)
    if len(marker_geometry) != 6 or sorted_nets(marker_geometry) != EXPECTED_NETS:
        errors.append(
            f"marker_geometry_rows={len(marker_geometry)} nets={sorted_nets(marker_geometry)}"
        )
    for row in marker_geometry:
        if (
            row.get("actual_area_um2") != "0.10640000"
            or row.get("required_area_um2") != "0.20200000"
            or row.get("additional_area_um2") != "0.09560000"
        ):
            errors.append(
                "unexpected_marker_area="
                f"{row.get('net')}:{row.get('actual_area_um2')}:"
                f"{row.get('required_area_um2')}:{row.get('additional_area_um2')}"
            )

    if len(topology) != 6 or sorted_nets(topology) != EXPECTED_NETS:
        errors.append(f"topology_rows={len(topology)} nets={sorted_nets(topology)}")
    resolved_nets = {
        row.get("net", "")
        for row in topology
        if row.get("net_handle_status") == "PASS"
        and row.get("net_handle") not in ("", "NONE", "UNKNOWN")
    }
    wire_query_nets = {
        row.get("net", "")
        for row in topology
        if row.get("wire_query_status") == "PASS"
    }
    numeric_local_wires = [
        row
        for row in local_wires
        if row.get("local_relation") in ("INTERSECTS_MARKER", "WITHIN_2UM_CONTEXT")
    ]
    local_wire_nets = {
        row.get("net", "") for row in numeric_local_wires if row.get("net")
    }
    via_query_nets = {
        row.get("net", "")
        for row in topology
        if row.get("via_query_status") == "PASS"
    }
    numeric_local_vias = [
        row
        for row in local_vias
        if row.get("local_relation") in ("INTERSECTS_MARKER", "WITHIN_2UM_CONTEXT")
    ]
    local_via_nets = {
        row.get("net", "") for row in numeric_local_vias if row.get("net")
    }
    inst_term_nets = {row.get("net", "") for row in inst_terms if row.get("net")}
    pin_shape_nets = {row.get("net", "") for row in pin_shapes if row.get("net")}

    actual_table_counts = {
        "WIRE_QUERY_PASS_NET_COUNT": len(wire_query_nets),
        "LOCAL_WIRE_NET_COUNT": len(local_wire_nets),
        "LOCAL_WIRE_ROW_COUNT": len(numeric_local_wires),
        "WIRE_CONTEXT_ROW_COUNT": len(local_wires),
        "VIA_QUERY_PASS_NET_COUNT": len(via_query_nets),
        "LOCAL_VIA_NET_COUNT": len(local_via_nets),
        "LOCAL_VIA_ROW_COUNT": len(numeric_local_vias),
        "VIA_CONTEXT_ROW_COUNT": len(local_vias),
        "INST_TERM_NET_COUNT": len(inst_term_nets),
        "INST_TERM_ROW_COUNT": len(inst_terms),
        "TOP_TERM_ROW_COUNT": len(top_terms),
        "PIN_SHAPE_NET_COUNT": len(pin_shape_nets),
        "PIN_SHAPE_ROW_COUNT": len(pin_shapes),
    }
    if len(resolved_nets) != 6:
        errors.append(f"resolved_net_count={len(resolved_nets)} expected=6")
    for key, actual in actual_table_counts.items():
        if counts.get(key) != actual:
            errors.append(f"{key}_table_count={actual} status_count={counts.get(key)}")

    expected_net_set = set(EXPECTED_NETS)
    if (
        wire_query_nets == expected_net_set
        and local_wire_nets == expected_net_set
        and inst_term_nets == expected_net_set
        and pin_shape_nets == expected_net_set
    ):
        local_capture = "COMPLETE_FOR_ALL_SIX_NETS"
    elif wire_query_nets == expected_net_set and local_wire_nets:
        local_capture = "PARTIAL_TERMINAL_OR_PIN_SHAPE_COVERAGE"
    else:
        local_capture = "PARTIAL_SCHEMA_GUIDED_QUERY_COVERAGE"

    result = {
        "LABEL": "SPADMIC_TX_PACKET_MIN_AREA_GEOMETRY_ANALYSIS",
        "POLICY": "READ_ONLY_RESTORED_CHECKPOINT_LOCAL_TOPOLOGY_CLASSIFICATION",
        "STATUS": "PASS" if not errors else "FAIL",
        "RESULT": (
            "MIN_AREA_LOCAL_GEOMETRY_CLASSIFIED"
            if not errors
            else "MIN_AREA_LOCAL_GEOMETRY_CLASSIFICATION_INCOMPLETE"
        ),
        "PROBE_ROOT": str(probe_root),
        "SOURCE_CHECKPOINT": context.get("SOURCE_CHECKPOINT", "MISSING"),
        "REPORT_DRIVER_HEAD": report_driver_head,
        "SELECTED_NET_REROUTE_METHOD_STATUS": "REJECTED_NO_IMPROVEMENT",
        "PRE_DRC_VIOLATION_COUNT": status.get("PRE_DRC_VIOLATION_COUNT", "UNKNOWN"),
        "POST_DRC_VIOLATION_COUNT": status.get("POST_DRC_VIOLATION_COUNT", "UNKNOWN"),
        "PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT": status.get(
            "PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT", "UNKNOWN"
        ),
        "POST_REGULAR_CONNECTIVITY_VIOLATION_COUNT": status.get(
            "POST_REGULAR_CONNECTIVITY_VIOLATION_COUNT", "UNKNOWN"
        ),
        "PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": status.get(
            "PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT", "UNKNOWN"
        ),
        "POST_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": status.get(
            "POST_SPECIAL_CONNECTIVITY_VIOLATION_COUNT", "UNKNOWN"
        ),
        "PRE_EXCLUDED_ANTENNA_MARKER_COUNT": status.get(
            "PRE_EXCLUDED_ANTENNA_MARKER_COUNT", "UNKNOWN"
        ),
        "POST_EXCLUDED_ANTENNA_MARKER_COUNT": status.get(
            "POST_EXCLUDED_ANTENNA_MARKER_COUNT", "UNKNOWN"
        ),
        "PRE_MARKER_DATABASE_TOTAL": status.get("PRE_MARKER_DATABASE_TOTAL", "UNKNOWN"),
        "POST_MARKER_DATABASE_TOTAL": status.get(
            "POST_MARKER_DATABASE_TOTAL", "UNKNOWN"
        ),
        "MARKER_SIGNATURE_STABILITY": (
            "PASS_IDENTICAL_BEFORE_AND_AFTER_QUERY_PROBE"
            if pre_signatures == post_signatures
            else "FAIL_CHANGED"
        ),
        "RESOLVED_NET_COUNT": str(len(resolved_nets)),
        "WIRE_QUERY_PASS_NET_COUNT": str(len(wire_query_nets)),
        "LOCAL_WIRE_NET_COUNT": str(len(local_wire_nets)),
        "LOCAL_WIRE_ROW_COUNT": str(len(numeric_local_wires)),
        "WIRE_CONTEXT_ROW_COUNT": str(len(local_wires)),
        "VIA_QUERY_PASS_NET_COUNT": str(len(via_query_nets)),
        "LOCAL_VIA_NET_COUNT": str(len(local_via_nets)),
        "LOCAL_VIA_ROW_COUNT": str(len(numeric_local_vias)),
        "VIA_CONTEXT_ROW_COUNT": str(len(local_vias)),
        "INST_TERM_NET_COUNT": str(len(inst_term_nets)),
        "INST_TERM_ROW_COUNT": str(len(inst_terms)),
        "TOP_TERM_ROW_COUNT": str(len(top_terms)),
        "PIN_SHAPE_NET_COUNT": str(len(pin_shape_nets)),
        "PIN_SHAPE_ROW_COUNT": str(len(pin_shapes)),
        "SCHEMA_PASS_COUNT": status.get("SCHEMA_PASS_COUNT", "UNKNOWN"),
        "SCHEMA_FAIL_COUNT": status.get("SCHEMA_FAIL_COUNT", "UNKNOWN"),
        "HELP_PASS_COUNT": status.get("HELP_PASS_COUNT", "UNKNOWN"),
        "HELP_UNAVAILABLE_COUNT": status.get("HELP_UNAVAILABLE_COUNT", "UNKNOWN"),
        "QUERY_PASS_COUNT": status.get("QUERY_PASS_COUNT", "UNKNOWN"),
        "QUERY_FAIL_COUNT": status.get("QUERY_FAIL_COUNT", "UNKNOWN"),
        "LOCAL_GEOMETRY_CAPTURE_STATUS": local_capture,
        "PIN_SHAPE_COORDINATE_INTERPRETATION": (
            "MASTER_LOCAL_REQUIRES_INSTANCE_TRANSFORM_UNLESS_DIRECT_ITERM_QUERY_PROVES_OTHERWISE"
        ),
        "DIRECT_GEOMETRY_TRIAL_DECISION": "BLOCKED_PENDING_OPERATOR_REVIEW",
        "CANONICAL_RERUN_DECISION": "BLOCKED_PENDING_LOCAL_GEOMETRY_REVIEW",
        "SAVE_DESIGN": "NOT_RUN",
        "EXPORT": "NOT_RUN",
        "IMMUTABLE_PVS_STAGING": "NOT_RUN",
        "PVS_DECISION": "DO_NOT_RUN",
        "NEXT_METHOD_DECISION": (
            "REVIEW_STEP20_LOCAL_GEOMETRY_TABLES_BEFORE_DIRECT_PATCH_TRIAL"
        ),
        "ERROR_COUNT": str(len(errors)),
    }

    evidence = [path for path in required if path.is_file()]
    lines = [f"{key}={value}" for key, value in result.items()]
    lines.extend(("", "MIN_AREA_MARKER_GEOMETRY_TABLE_BEGIN"))
    if marker_geometry:
        lines.append("\t".join(marker_geometry[0].keys()))
        lines.extend("\t".join(row.values()) for row in marker_geometry)
    lines.append("MIN_AREA_MARKER_GEOMETRY_TABLE_END")
    lines.extend(("", "NET_TOPOLOGY_SUMMARY_TABLE_BEGIN"))
    if topology:
        lines.append("\t".join(topology[0].keys()))
        lines.extend("\t".join(row.values()) for row in topology)
    lines.append("NET_TOPOLOGY_SUMMARY_TABLE_END")
    lines.extend(("", "LOCAL_WIRE_CONTEXT_TABLE_BEGIN"))
    if local_wires:
        lines.append("\t".join(local_wires[0].keys()))
        lines.extend("\t".join(row.values()) for row in local_wires[:120])
        if len(local_wires) > 120:
            lines.append(f"TRUNCATED\trows={len(local_wires)}\tshown=120")
    lines.append("LOCAL_WIRE_CONTEXT_TABLE_END")
    lines.extend(("", "LOCAL_VIA_CONTEXT_TABLE_BEGIN"))
    if local_vias:
        lines.append("\t".join(local_vias[0].keys()))
        lines.extend("\t".join(row.values()) for row in local_vias[:120])
        if len(local_vias) > 120:
            lines.append(f"TRUNCATED\trows={len(local_vias)}\tshown=120")
    lines.append("LOCAL_VIA_CONTEXT_TABLE_END")
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
    parser.add_argument("--probe-root", type=Path, required=True)
    parser.add_argument("--step19-analysis", type=Path, required=True)
    parser.add_argument("--report-driver-head", required=True)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    result = classify(
        args.probe_root.resolve(),
        args.step19_analysis.resolve(),
        args.report_driver_head,
        args.report.resolve(),
    )
    print(args.report.read_text(), end="")
    return 0 if result["STATUS"] == "PASS" else 8


if __name__ == "__main__":
    raise SystemExit(main())
