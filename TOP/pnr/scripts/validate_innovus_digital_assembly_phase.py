#!/usr/bin/env python3
"""Fail-closed Innovus gate for one cumulative soft assembly phase."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
DEFAULT_CONTRACT = ROOT / "TOP/pnr/assembly/spadmic_digital_assembly_contract.json"


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read_kv(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            values[key] = value
    return values


def read_tsv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle, delimiter="\t"))


def floats(value: str) -> tuple[float, ...] | None:
    try:
        return tuple(float(token) for token in value.split())
    except ValueError:
        return None


def same_box(left: str, right: str, tolerance: float = 0.002) -> bool:
    lhs = floats(left)
    rhs = floats(right)
    return (
        lhs is not None
        and rhs is not None
        and len(lhs) == len(rhs) == 4
        and all(abs(a - b) <= tolerance for a, b in zip(lhs, rhs))
    )


def timing_slacks(text: str) -> list[float]:
    patterns = (
        r"(?im)^\s*slack(?:\s+time)?\s*[:=]?\s*([+-]?\d+(?:\.\d+)?)\b",
        r"(?im)^\s*(?:wns|worst(?:\s+reported)?\s+(?:setup|hold)?\s*slack(?:_ns)?)\s*[:=]\s*([+-]?\d+(?:\.\d+)?)\b",
    )
    values: list[float] = []
    for pattern in patterns:
        values.extend(float(value) for value in re.findall(pattern, text))
    return values


def minimum_slack(path: Path, errors: list[str], label: str) -> float | None:
    if not path.is_file() or path.stat().st_size == 0:
        errors.append(f"missing_or_empty_{label}_timing_report={path}")
        return None
    text = path.read_text(encoding="utf-8", errors="replace")
    values = timing_slacks(text)
    if values:
        return min(values)
    if re.search(r"(?i)no\s+(?:timing\s+)?paths?\s+(?:found|reported)", text):
        return math.inf
    errors.append(f"{label}_slack_not_parseable={path}")
    return None


def require(values: dict[str, str], expected: dict[str, str], errors: list[str], prefix: str) -> None:
    for key, value in expected.items():
        actual = values.get(key, "MISSING")
        if actual != value:
            errors.append(f"{prefix}_{key.lower()}={actual} expected={value}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--phase", required=True)
    parser.add_argument("--run-root", required=True, type=Path)
    parser.add_argument("--genus-root", required=True, type=Path)
    parser.add_argument("--phase-contract-root", required=True, type=Path)
    parser.add_argument("--gds-audit", required=True, type=Path)
    parser.add_argument("--status", required=True, type=Path)
    parser.add_argument("--contract", type=Path, default=DEFAULT_CONTRACT)
    args = parser.parse_args()

    contract = json.loads(args.contract.read_text(encoding="utf-8"))
    if args.phase not in contract["phases"]:
        raise SystemExit(f"unknown assembly phase: {args.phase}")
    phase = contract["phases"][args.phase]
    physical = contract["physical_policy"]
    top = str(phase["top"])
    run_root = args.run_root.resolve()
    reports = run_root / "reports"
    outputs = run_root / "outputs"
    implementation_status = reports / "digital_assembly_innovus_status.rpt"
    phase_status_path = args.phase_contract_root / "assembly_phase_contract_status.rpt"
    genus_gate_path = args.genus_root / "reports/timing/digital_assembly_genus_tc_gate.rpt"
    errors: list[str] = []

    required_files = {
        "implementation_status": implementation_status,
        "phase_contract_status": phase_status_path,
        "genus_gate": genus_gate_path,
        "gds_audit": args.gds_audit,
        "def": outputs / f"{top}.def",
        "lef": outputs / f"{top}.lef",
        "gds": outputs / f"{top}.gds",
        "netlist": outputs / f"{top}.v",
        "pg_netlist": outputs / f"{top}.pg.v",
        "setup_timing": reports / "report_timing_post_route_setup.rpt",
        "hold_timing": reports / "report_timing_post_route_hold.rpt",
        "constraints": reports / "report_constraint_post_route.rpt",
        "floorplan": reports / "floorplan_geometry.rpt",
        "guides": reports / "soft_group_guide_application.rpt",
        "obstacles": reports / "fixed_obstacle_application.rpt",
    }
    for label, path in required_files.items():
        if not path.is_file() or path.stat().st_size == 0:
            errors.append(f"missing_or_empty_{label}={path}")

    implementation = read_kv(implementation_status) if implementation_status.is_file() else {}
    phase_status = read_kv(phase_status_path) if phase_status_path.is_file() else {}
    genus_gate = read_kv(genus_gate_path) if genus_gate_path.is_file() else {}
    gds_audit = read_kv(args.gds_audit) if args.gds_audit.is_file() else {}

    expected_impl = {
        "STATUS": "PASS",
        "PHASE": args.phase,
        "TOP_MODULE": top,
        "SOURCE_TOP": top,
        "LAYOUT_TOP": top,
        "IMPLEMENTATION": "CUMULATIVE_SOFT_LOGIC",
        "HARD_MACRO_COUNT": "0",
        "HARD_MACRO_STATUS": "PASS",
        "CHILD_GDS_MERGE_COUNT": "0",
        "FLOORPLAN_GEOMETRY_STATUS": "PASS",
        "FIXED_OBSTACLE_STATUS": "PASS",
        "SOFT_GUIDE_STATUS": "PASS",
        "SIGNAL_PIN_PLACEMENT_STATUS": "PASS",
        "PG_ANCHOR_STATUS": "PASS",
        "PG_CONNECTIVITY_STATUS": "PASS",
        "REGULAR_CONNECTIVITY_STATUS": "PASS",
        "INNOVUS_DRC_STATUS": "PASS",
        "TC_TIMING_CAPTURE_STATUS": "PASS",
        "STANDARD_CELL_FILL_STATUS": "PASS",
        "SIGNAL_ROUTE_LAYERS": "MET1-MET3",
        "METTP_POLICY": "PG_AND_BOUNDED_PIN_ACCESS_ONLY",
        "EXPORT_DEF_STATUS": "PASS",
        "EXPORT_LEF_STATUS": "PASS",
        "EXPORT_GDS_STATUS": "PASS",
        "EXPORT_NETLIST_STATUS": "PASS",
        "EXPORT_PG_NETLIST_STATUS": "PASS",
        "PVS_EXECUTED": "NO",
    }
    require(implementation, expected_impl, errors, "innovus")
    for gate in ("PLACE_DESIGN", "CTS_DESIGN", "ADD_FILLER", "ROUTE_DESIGN", "POSTROUTE_SETUP_TIMING", "POSTROUTE_HOLD_TIMING"):
        if implementation.get(gate) != "PASS":
            errors.append(f"innovus_{gate.lower()}={implementation.get(gate, 'MISSING')} expected=PASS")
    for key in ("INNOVUS_DRC_VIOLATION_COUNT", "REGULAR_CONNECTIVITY_VIOLATION_COUNT", "PG_CONNECTIVITY_VIOLATION_COUNT"):
        if implementation.get(key) != "0":
            errors.append(f"innovus_{key.lower()}={implementation.get(key, 'MISSING')} expected=0")

    require(
        phase_status,
        {
            "STATUS": "PASS",
            "PHASE": args.phase,
            "SOURCE_TOP": top,
            "LAYOUT_TOP": top,
            "IMPLEMENTATION": "CUMULATIVE_SOFT_LOGIC",
            "HARD_MACRO_COUNT": "0",
            "CHILD_GDS_MERGE_COUNT": "0",
        },
        errors,
        "phase_contract",
    )
    require(
        genus_gate,
        {
            "STATUS": "PASS",
            "PHASE": args.phase,
            "TOP_MODULE": top,
            "BOUNDARY_STATUS": "PASS",
            "SETUP_STATUS": "PASS",
            "HOLD_STATUS": "PASS",
            "TYPICAL_CLOSED": "YES",
            "INNOVUS_HANDOFF_READY": "YES",
        },
        errors,
        "genus_gate",
    )
    require(
        gds_audit,
        {
            "STATUS": "PASS",
            "GDS_FILE_STATUS": "PASS",
            "GDS_LAYER_MAP_STATUS": "PASS",
            "GDS_MERGE_STATUS": "PASS",
            "ERROR_COUNT": "0",
        },
        errors,
        "gds_audit",
    )

    expected_die = phase_status.get("SPADMIC2_DIE_BBOX_UM", "MISSING")
    actual_die = implementation.get("ACTUAL_DIE_BBOX_UM", "MISSING")
    if not same_box(expected_die, actual_die):
        errors.append(f"die_bbox={actual_die} expected={expected_die}")

    expected_groups = [group for group in phase_status.get("GROUPS", "").split(",") if group]
    try:
        actual_guide_count = int(implementation.get("SOFT_GUIDE_COUNT", "-1"))
    except ValueError:
        actual_guide_count = -1
    if actual_guide_count != len(expected_groups):
        errors.append(f"soft_guide_count={actual_guide_count} expected={len(expected_groups)}")

    proxy_plan = args.phase_contract_root / "matrix_proxy_pin_plan.tsv"
    proxy_rows = read_tsv(proxy_plan) if proxy_plan.is_file() else []
    expected_proxy_status = "PASS" if args.phase == "p03_matrix_interface" else "NOT_APPLICABLE"
    if implementation.get("EXACT_PROXY_PIN_STATUS") != expected_proxy_status:
        errors.append(
            "exact_proxy_pin_status="
            f"{implementation.get('EXACT_PROXY_PIN_STATUS', 'MISSING')} expected={expected_proxy_status}"
        )
    expected_proxy_count = len(proxy_rows) if args.phase == "p03_matrix_interface" else 0
    if implementation.get("EXACT_PROXY_PIN_COUNT") != str(expected_proxy_count):
        errors.append(
            f"exact_proxy_pin_count={implementation.get('EXACT_PROXY_PIN_COUNT', 'MISSING')} "
            f"expected={expected_proxy_count}"
        )

    setup_slack = minimum_slack(required_files["setup_timing"], errors, "setup")
    hold_slack = minimum_slack(required_files["hold_timing"], errors, "hold")
    if setup_slack is not None and setup_slack < 0.0:
        errors.append(f"setup_min_slack_ns={setup_slack} expected_nonnegative")
    if hold_slack is not None and hold_slack < 0.0:
        errors.append(f"hold_min_slack_ns={hold_slack} expected_nonnegative")

    constraint_text = (
        required_files["constraints"].read_text(encoding="utf-8", errors="replace")
        if required_files["constraints"].is_file()
        else ""
    )
    violated_lines = [
        line.strip()
        for line in constraint_text.splitlines()
        if re.search(r"(?i)\bVIOLATED\b", line)
    ]
    if violated_lines:
        errors.append(f"postroute_design_rule_violator_count={len(violated_lines)} expected=0")

    netlist_text = required_files["pg_netlist"].read_text(errors="replace") if required_files["pg_netlist"].is_file() else ""
    module_count = len(re.findall(rf"(?m)^\s*module\s+{re.escape(top)}\b", netlist_text))
    if module_count != 1:
        errors.append(f"exported_pg_netlist_top_count={module_count} expected=1")
    lef_text = required_files["lef"].read_text(errors="replace") if required_files["lef"].is_file() else ""
    lef_macros = re.findall(r"(?m)^\s*MACRO\s+(\S+)", lef_text)
    if lef_macros != [top]:
        errors.append(f"exported_lef_macros={','.join(lef_macros) or 'MISSING'} expected={top}")
    def_text = required_files["def"].read_text(errors="replace") if required_files["def"].is_file() else ""
    if not re.search(rf"(?m)^\s*DESIGN\s+{re.escape(top)}\s*;", def_text):
        errors.append(f"exported_def_design_missing={top}")

    target_util = f"{float(physical['target_utilization']):g}"
    max_density = f"{float(physical['max_local_density']):g}"
    if implementation.get("TARGET_UTILIZATION") not in {target_util, str(physical["target_utilization"])}:
        errors.append(f"target_utilization={implementation.get('TARGET_UTILIZATION', 'MISSING')} expected={target_util}")
    if implementation.get("MAX_LOCAL_DENSITY") not in {max_density, str(physical["max_local_density"])}:
        errors.append(f"max_local_density={implementation.get('MAX_LOCAL_DENSITY', 'MISSING')} expected={max_density}")

    status_value = "PASS" if not errors else "FAIL"
    values: dict[str, object] = {
        "LABEL": "SPADMIC_DIGITAL_ASSEMBLY_INNOVUS_GATE",
        "STATUS": status_value,
        "RESULT": "INNOVUS_HANDOFF_READY" if not errors else "REVIEW_REQUIRED",
        "PHASE": args.phase,
        "TOP_MODULE": top,
        "SOURCE_TOP": top,
        "LAYOUT_TOP": top,
        "IMPLEMENTATION": "CUMULATIVE_SOFT_LOGIC",
        "HARD_MACRO_COUNT": 0 if implementation.get("HARD_MACRO_COUNT") == "0" else "UNKNOWN",
        "CHILD_GDS_MERGE_COUNT": 0,
        "EXPECTED_DIE_BBOX_UM": expected_die,
        "ACTUAL_DIE_BBOX_UM": actual_die,
        "FLOORPLAN_GEOMETRY_STATUS": "PASS" if same_box(expected_die, actual_die) else "FAIL",
        "FIXED_OBSTACLE_STATUS": implementation.get("FIXED_OBSTACLE_STATUS", "MISSING"),
        "SOFT_GUIDE_STATUS": implementation.get("SOFT_GUIDE_STATUS", "MISSING"),
        "SOFT_GUIDE_COUNT": actual_guide_count,
        "EXACT_PROXY_PIN_STATUS": implementation.get("EXACT_PROXY_PIN_STATUS", "MISSING"),
        "EXACT_PROXY_PIN_COUNT": implementation.get("EXACT_PROXY_PIN_COUNT", "MISSING"),
        "TARGET_UTILIZATION": physical["target_utilization"],
        "MAX_LOCAL_DENSITY": physical["max_local_density"],
        "SIGNAL_ROUTE_LAYERS": "MET1-MET3",
        "METTP_POLICY": "PG_AND_BOUNDED_PIN_ACCESS_ONLY",
        "TC_SETUP_STATUS": "PASS" if setup_slack is not None and setup_slack >= 0.0 else "FAIL",
        "TC_HOLD_STATUS": "PASS" if hold_slack is not None and hold_slack >= 0.0 else "FAIL",
        "WORST_SETUP_SLACK_NS": "INF" if setup_slack == math.inf else "UNKNOWN" if setup_slack is None else f"{setup_slack:.6f}",
        "WORST_HOLD_SLACK_NS": "INF" if hold_slack == math.inf else "UNKNOWN" if hold_slack is None else f"{hold_slack:.6f}",
        "POSTROUTE_DESIGN_RULE_STATUS": "PASS" if not violated_lines else "FAIL",
        "INNOVUS_DRC_STATUS": implementation.get("INNOVUS_DRC_STATUS", "MISSING"),
        "REGULAR_CONNECTIVITY_STATUS": implementation.get("REGULAR_CONNECTIVITY_STATUS", "MISSING"),
        "PG_CONNECTIVITY_STATUS": implementation.get("PG_CONNECTIVITY_STATUS", "MISSING"),
        "GDS_EXPORT_AUDIT_STATUS": gds_audit.get("STATUS", "MISSING"),
        "GDS_SHA256": digest(required_files["gds"]) if required_files["gds"].is_file() else "MISSING",
        "PG_NETLIST_SHA256": digest(required_files["pg_netlist"]) if required_files["pg_netlist"].is_file() else "MISSING",
        "LEF_SHA256": digest(required_files["lef"]) if required_files["lef"].is_file() else "MISSING",
        "DEF_SHA256": digest(required_files["def"]) if required_files["def"].is_file() else "MISSING",
        "DENSITY_GATE": phase["density_gate"],
        "PVS_BASE_DRC_STATUS": "NOT_RUN",
        "PVS_DENSITY_DRC_STATUS": "NOT_RUN",
        "PVS_LVS_STATUS": "NOT_RUN",
        "MMMC_STATUS": "NOT_RUN_TC_ONLY",
        "CDC_RDC_STATUS": "STA_ONLY_NO_DEDICATED_TOOL",
        "SIGNOFF_READY": "NO",
        "ERROR_COUNT": len(errors),
        "NEXT_GATE": "STAGE_EXACT_PHASE_HANDOFF" if not errors else "STOP_AND_REVIEW_INNOVUS",
    }
    args.status.parent.mkdir(parents=True, exist_ok=True)
    args.status.write_text(
        "".join(
            [
                *(f"{key}={value}\n" for key, value in values.items()),
                *(f"ERROR={error}\n" for error in errors),
            ]
        ),
        encoding="utf-8",
    )
    print(args.status.read_text(), end="")
    return 0 if not errors else 8


if __name__ == "__main__":
    raise SystemExit(main())
