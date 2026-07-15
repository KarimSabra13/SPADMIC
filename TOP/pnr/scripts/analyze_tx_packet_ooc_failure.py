#!/usr/bin/env python3
"""Classify a failed TX packet OOC run from existing text artifacts only."""

from __future__ import annotations

import argparse
import csv
import hashlib
import importlib.util
import re
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
VALIDATOR_PATH = REPO_ROOT / "TOP" / "pnr" / "scripts" / "validate_tx_canonical_ooc.py"
SPEC = importlib.util.spec_from_file_location("tx_packet_ooc_validator", VALIDATOR_PATH)
assert SPEC and SPEC.loader
validator = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = validator
SPEC.loader.exec_module(validator)


def digest(path: Path) -> str:
    sha = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            sha.update(chunk)
    return sha.hexdigest()


def key_values(path: Path) -> dict[str, str]:
    if not path.is_file():
        return {}
    values: dict[str, str] = {}
    for line in path.read_text(errors="replace").splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            values[key] = value
    return values


def read_tsv(path: Path) -> list[dict[str, str]]:
    if not path.is_file():
        return []
    with path.open(newline="", errors="replace") as handle:
        return list(csv.DictReader(handle, delimiter="\t"))


def is_min_area(row: dict[str, str]) -> bool:
    text = " ".join(
        row.get(key, "") for key in ("layer", "type", "subType", "message")
    )
    return (
        row.get("layer", "").upper() == "MET1"
        and row.get("type", "").lower() == "geometry"
        and re.search(r"minimal_area|minimum\s+area|\bmar\b", text, re.IGNORECASE)
        is not None
    )


def is_antenna(row: dict[str, str]) -> bool:
    text = " ".join(row.get(key, "") for key in ("type", "subType", "message"))
    return re.search(r"antenna", text, re.IGNORECASE) is not None


def pg_evidence_lines(path: Path) -> list[str]:
    if not path.is_file():
        return []
    pattern = re.compile(
        r"Net\s+(?:VDD|VSS)|Begin Summary|End Summary|Problem\(s\)|"
        r"Verification Complete|special routes|\bopen\b|\bshort\b",
        re.IGNORECASE,
    )
    return [
        line.strip()
        for line in path.read_text(errors="replace").splitlines()
        if pattern.search(line)
    ]


def parse_pg_problem_count(lines: list[str]) -> int | None:
    for line in lines:
        match = re.search(r"(\d+)\s+Problem\(s\)", line, re.IGNORECASE)
        if match:
            return int(match.group(1))
    for line in lines:
        match = re.search(r"Verification Complete\s*:\s*(\d+)\s+Viols", line, re.IGNORECASE)
        if match:
            return int(match.group(1))
    return None


def grid_um(config: Path) -> float | None:
    if not config.is_file():
        return None
    match = re.search(
        r"^\s*variable\s+pg_grid_um\s+\{?([-+0-9.eE]+)\}?\s*$",
        config.read_text(errors="replace"),
        re.MULTILINE,
    )
    return float(match.group(1)) if match else None


def marker_net(row: dict[str, str]) -> str:
    match = re.search(
        r"Regular\s+Wire\s+of\s+Net\s+([^\s]+)",
        row.get("message", ""),
        re.IGNORECASE,
    )
    return match.group(1) if match else "UNKNOWN"


def diagnose(block_root: Path, report: Path) -> dict[str, str]:
    outputs = block_root / "outputs"
    reports = block_root / "reports"
    generated = block_root / "generated"
    status_path = reports / "ooc_harden_status.rpt"
    gate_path = reports / "canonical_tx_ooc_gate.rpt"
    lef_path = outputs / "tx_packet_core.abstract.lef"
    pin_plan_path = generated / "ooc_block_pin_plan.csv"
    config_path = generated / "ooc_block_harden_config.tcl"
    pg_path = reports / "verify_connectivity_pg.rpt"
    sroute_path = reports / "SROUTE_PG.rpt"
    repair_path = reports / "POSTROUTE_MIN_AREA_REPAIR.rpt"
    pre_markers_path = reports / "postroute_min_area_repair_pre_markers.tsv"
    post_markers_path = reports / "postroute_min_area_repair_post_markers.tsv"
    final_markers_path = reports / "verify_drc_post_route_markers.tsv"

    required = [
        status_path,
        gate_path,
        lef_path,
        pin_plan_path,
        config_path,
        pg_path,
        repair_path,
        pre_markers_path,
        post_markers_path,
        final_markers_path,
    ]
    missing = [str(path) for path in required if not path.is_file()]
    status = key_values(status_path)
    gate = key_values(gate_path)
    sroute = key_values(sroute_path)
    repair = key_values(repair_path)

    with validator.TX_PIN_CONTRACT.open(newline="") as handle:
        contract_rows = list(csv.DictReader(handle))
    pin_plan: dict[str, dict[str, str]] = {}
    if pin_plan_path.is_file():
        with pin_plan_path.open(newline="") as handle:
            pin_plan = {row["port"]: row for row in csv.DictReader(handle)}

    stream_rows: list[dict[str, str | float]] = []
    parse_error = ""
    if lef_path.is_file():
        try:
            macro = validator.lef_parser.parse_lef(lef_path)
            for contract in contract_rows:
                pin_name = contract["packet_pin"]
                expected_x = float(contract["packet_local_x_um"])
                pin = macro.pins.get(pin_name)
                if pin is None or not pin.rects:
                    stream_rows.append(
                        {
                            "pin": pin_name,
                            "expected_x": expected_x,
                            "planned_x": float("nan"),
                            "assign_x": float("nan"),
                            "actual_x": float("nan"),
                            "delta_x": float("nan"),
                            "width": float("nan"),
                            "layer": "MISSING",
                        }
                    )
                    continue
                rect = pin.primary_rect()
                planned_text = pin_plan.get(pin_name, {}).get("target_x_um", "")
                planned_x = float(planned_text) if planned_text else float("nan")
                assign_text = pin_plan.get(pin_name, {}).get("assign_x_um", "")
                assign_x = float(assign_text) if assign_text else float("nan")
                stream_rows.append(
                    {
                        "pin": pin_name,
                        "expected_x": expected_x,
                        "planned_x": planned_x,
                        "assign_x": assign_x,
                        "actual_x": rect.cx,
                        "delta_x": rect.cx - expected_x,
                        "width": rect.urx - rect.llx,
                        "layer": rect.layer,
                    }
                )
        except ValueError as exc:
            parse_error = str(exc)

    finite_deltas = [
        round(float(row["delta_x"]), 6)
        for row in stream_rows
        if isinstance(row["delta_x"], float) and row["delta_x"] == row["delta_x"]
    ]
    unique_deltas = sorted(set(finite_deltas))

    def unique_difference(lhs_key: str, rhs_key: str) -> tuple[list[float], int]:
        differences: list[float] = []
        for row in stream_rows:
            lhs = float(row[lhs_key])
            rhs = float(row[rhs_key])
            if lhs == lhs and rhs == rhs:
                differences.append(round(lhs - rhs, 6))
        return sorted(set(differences)), len(differences)

    unique_target_contract_deltas, target_contract_count = unique_difference(
        "planned_x", "expected_x"
    )
    unique_assign_target_deltas, assign_target_count = unique_difference(
        "assign_x", "planned_x"
    )
    unique_actual_assign_deltas, actual_assign_count = unique_difference(
        "actual_x", "assign_x"
    )
    grid = grid_um(config_path)
    uniform_delta = unique_deltas[0] if len(unique_deltas) == 1 else None
    half_grid_match = (
        grid is not None
        and uniform_delta is not None
        and abs(abs(uniform_delta) - grid / 2.0) <= 0.002
    )

    pre_markers = read_tsv(pre_markers_path)
    post_markers = read_tsv(post_markers_path)
    final_markers = read_tsv(final_markers_path)
    pre_min = [row for row in pre_markers if is_min_area(row)]
    post_min = [row for row in post_markers if is_min_area(row)]
    final_min = [row for row in final_markers if is_min_area(row)]
    final_antenna = [row for row in final_markers if is_antenna(row)]
    min_area_nets = sorted({marker_net(row) for row in final_min})

    pg_lines = pg_evidence_lines(pg_path)
    pg_problem_count = parse_pg_problem_count(pg_lines)
    regular_status = status.get("REGULAR_CONNECTIVITY_STATUS", "MISSING")
    pg_connectivity_status = status.get("PG_CONNECTIVITY_STATUS", "MISSING")
    final_drc_status = status.get("INNOVUS_DRC_STATUS", "MISSING")
    pg_closed = pg_connectivity_status == "PASS" and pg_problem_count == 0
    target_status = (
        "CANONICAL_TARGETS_PRESERVED"
        if target_contract_count == len(contract_rows)
        and unique_target_contract_deltas == [0.0]
        else "TARGETS_MISSING_OR_DIFFER_FROM_CONTRACT"
    )
    assignment_status = (
        "ACTUAL_MATCHES_GENERATED_ASSIGN_X"
        if actual_assign_count == len(contract_rows)
        and unique_actual_assign_deltas == [0.0]
        else (
            "GENERATED_ASSIGN_X_MISSING_OR_INCOMPLETE"
            if actual_assign_count != len(contract_rows)
            else "ACTUAL_DIFFERS_FROM_GENERATED_ASSIGN_X"
        )
    )
    remove_negative_compensation = (
        target_status == "CANONICAL_TARGETS_PRESERVED"
        and assignment_status == "ACTUAL_MATCHES_GENERATED_ASSIGN_X"
        and assign_target_count == len(contract_rows)
        and unique_assign_target_deltas == [-0.28]
        and unique_deltas == [-0.28]
    )
    if regular_status == "PASS" and pg_closed and final_drc_status == "FAIL" and final_min:
        physical_status = "PG_AND_REGULAR_CLOSED_FINAL_REPAIR_REQUIRED"
        reroute_decision = "DO_NOT_RERUN_UNTIL_MIN_AREA_AND_PIN_MAPPING_REPAIRS_ARE_REVIEWED"
    else:
        physical_status = "FAIL"
        reroute_decision = "DO_NOT_RERUN_UNTIL_PG_PROBE_AND_REPAIR_EVIDENCE_REVIEWED"
    if len(post_min) < len(pre_min):
        min_area_effect = f"REDUCED_{len(pre_min)}_TO_{len(post_min)}"
    elif len(post_min) == len(pre_min):
        min_area_effect = f"UNCHANGED_AT_{len(post_min)}"
    else:
        min_area_effect = f"INCREASED_{len(pre_min)}_TO_{len(post_min)}"

    def format_differences(values: list[float]) -> str:
        return ",".join(f"{value:.6f}" for value in values) if values else "UNKNOWN"

    evidence_paths = [
        status_path,
        gate_path,
        lef_path,
        pin_plan_path,
        config_path,
        pg_path,
        sroute_path,
        repair_path,
        pre_markers_path,
        post_markers_path,
        final_markers_path,
    ]

    captured = (
        not missing
        and not parse_error
        and len(stream_rows) == len(contract_rows)
        and len(finite_deltas) == len(contract_rows)
    )
    values = {
        "LABEL": "SPADMIC_TX_PACKET_OOC_FAILURE_DIAGNOSIS",
        "POLICY": "READ_ONLY_EXISTING_ARTIFACTS_NO_DESIGN_MODIFICATION",
        "STATUS": "PASS" if captured else "FAIL",
        "DIAGNOSIS_STATUS": "PASS" if captured else "FAIL",
        "RESULT": "BLOCKERS_CLASSIFIED" if captured else "DIAGNOSTIC_INCOMPLETE",
        "BLOCK_ROOT": str(block_root),
        "PHYSICAL_CANDIDATE_STATUS": physical_status,
        "PVS_DECISION": "DO_NOT_RUN",
        "REROUTE_DECISION": reroute_decision,
        "FINAL_DRC_STATUS": final_drc_status,
        "REGULAR_CONNECTIVITY_STATUS": regular_status,
        "PG_COMMAND_STATUS": sroute.get("STATUS", status.get("SROUTE_PG", "MISSING")),
        "PG_CONNECTIVITY_STATUS": pg_connectivity_status,
        "PG_PROBLEM_COUNT": str(pg_problem_count) if pg_problem_count is not None else "UNKNOWN",
        "PG_DIAGNOSIS": "TOPOLOGY_CLOSED" if pg_closed else "COMMAND_EXECUTED_TOPOLOGY_NOT_CLOSED",
        "MIN_AREA_REPAIR_STATUS": status.get("POSTROUTE_MIN_AREA_REPAIR", repair.get("STATUS", "MISSING")),
        "MIN_AREA_REPAIR_EFFECT": min_area_effect,
        "MIN_AREA_PRE_MARKER_COUNT": str(len(pre_min)),
        "MIN_AREA_POST_MARKER_COUNT": str(len(post_min)),
        "MIN_AREA_FINAL_MARKER_COUNT": str(len(final_min)),
        "MIN_AREA_FINAL_NETS": " ".join(min_area_nets) if min_area_nets else "NONE",
        "ANTENNA_FINAL_MARKER_COUNT": str(len(final_antenna)),
        "ANTENNA_MILESTONE_STATUS": gate.get("ANTENNA_MILESTONE_STATUS", "MISSING"),
        "STREAM_PIN_COUNT": str(len(stream_rows)),
        "STREAM_PIN_EXPECTED_COUNT": str(len(contract_rows)),
        "STREAM_PIN_UNIQUE_DELTA_UM": (
            ",".join(f"{delta:.6f}" for delta in unique_deltas) if unique_deltas else "UNKNOWN"
        ),
        "STREAM_PIN_DELTA_STATUS": "UNIFORM" if len(unique_deltas) == 1 else "NONUNIFORM",
        "STREAM_PIN_TARGET_STATUS": target_status,
        "STREAM_PIN_UNIQUE_TARGET_MINUS_CONTRACT_UM": format_differences(
            unique_target_contract_deltas
        ),
        "STREAM_PIN_UNIQUE_ASSIGN_MINUS_TARGET_UM": format_differences(
            unique_assign_target_deltas
        ),
        "STREAM_PIN_UNIQUE_ACTUAL_MINUS_ASSIGN_UM": format_differences(
            unique_actual_assign_deltas
        ),
        "STREAM_PIN_ASSIGNMENT_STATUS": assignment_status,
        "PG_GRID_UM": f"{grid:.6f}" if grid is not None else "UNKNOWN",
        "STREAM_PIN_GRID_RELATION": (
            "CONSISTENT_WITH_HALF_GRID_ASSIGNMENT_REFERENCE_SHIFT"
            if half_grid_match
            else "NOT_ESTABLISHED"
        ),
        "STREAM_PIN_CONTRACT_DECISION": "KEEP_CANONICAL_CENTERS_FIX_COMMAND_MAPPING",
        "STREAM_PIN_COMMAND_MAPPING_DECISION": (
            "REMOVE_NEGATIVE_COMPENSATION_KEEP_CANONICAL_CENTERS"
            if remove_negative_compensation
            else "REVIEW_GENERATED_ASSIGNMENT_EVIDENCE"
        ),
        "MISSING_REQUIRED_ARTIFACTS": ";".join(missing) if missing else "NONE",
        "LEF_PARSE_ERROR": parse_error or "NONE",
    }

    lines = [*(f"{key}={value}" for key, value in values.items())]
    lines.extend(["", "STREAM_PIN_TABLE_BEGIN", "pin\texpected_x_um\tplanned_x_um\tassign_x_um\tactual_x_um\tdelta_x_um\twidth_um\tlayer"])
    for row in stream_rows:
        def number(key: str) -> str:
            value = float(row[key])
            return f"{value:.6f}" if value == value else "UNKNOWN"

        lines.append(
            "\t".join(
                [
                    str(row["pin"]),
                    number("expected_x"),
                    number("planned_x"),
                    number("assign_x"),
                    number("actual_x"),
                    number("delta_x"),
                    number("width"),
                    str(row["layer"]),
                ]
            )
        )
    lines.append("STREAM_PIN_TABLE_END")

    lines.extend(["", "PG_REPORT_EVIDENCE_BEGIN"])
    lines.extend(pg_lines or ["NONE"])
    lines.append("PG_REPORT_EVIDENCE_END")

    lines.extend(["", "MIN_AREA_FINAL_TABLE_BEGIN", "net\tbox\tcx\tcy\tsubType\tmessage"])
    for row in final_min:
        lines.append(
            "\t".join(
                [
                    marker_net(row),
                    row.get("box", "UNKNOWN"),
                    row.get("cx", "UNKNOWN"),
                    row.get("cy", "UNKNOWN"),
                    row.get("subType", "UNKNOWN"),
                    row.get("message", "UNKNOWN"),
                ]
            )
        )
    lines.append("MIN_AREA_FINAL_TABLE_END")

    lines.extend(["", "REPAIR_LEDGER_BEGIN"])
    for key in (
        "PRE_MARKER_COUNT",
        "MIN_AREA_MARKER_COUNT",
        "MIN_AREA_NET_COUNT",
        "MIN_AREA_NETS",
        "SELECTED_NET_MODE_STATUS",
        "SELECTED_NET_COUNT",
        "SELECTED_NETS",
        "AREA_DELETE_COUNT",
        "AREA_DELETE_FAILURES",
        "DRC_WIRE_DELETE_FAILURES",
        "ROUTE_COMMANDS",
        "ROUTE_FAILURES",
        "POST_MARKER_COUNT",
        "POST_DRC_STATUS",
        "STATUS",
    ):
        lines.append(f"REPAIR_{key}={repair.get(key, 'MISSING')}")
    lines.append("REPAIR_LEDGER_END")

    lines.extend(["", "EVIDENCE_HASHES_BEGIN"])
    for path in evidence_paths:
        if path.is_file():
            lines.append(f"{digest(path)}  {path}")
    lines.append("EVIDENCE_HASHES_END")

    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text("\n".join(lines) + "\n")
    return values


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--block-root", required=True, type=Path)
    parser.add_argument("--report", required=True, type=Path)
    args = parser.parse_args()
    values = diagnose(args.block_root.resolve(), args.report.resolve())
    print(args.report.read_text(), end="")
    if values["STATUS"] != "PASS":
        raise SystemExit(8)


if __name__ == "__main__":
    main()
