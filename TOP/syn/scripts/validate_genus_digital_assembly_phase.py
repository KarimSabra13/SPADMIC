#!/usr/bin/env python3
"""Fail-closed TC Genus gate for one cumulative digital assembly phase."""

from __future__ import annotations

import argparse
import csv
import hashlib
import importlib.util
import json
import math
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
PARSER_PATH = ROOT / "TOP/pnr/scripts/prepare_pvs_lvs_source.py"
SPEC = importlib.util.spec_from_file_location("digital_assembly_netlist_parser", PARSER_PATH)
assert SPEC and SPEC.loader
source_parser = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = source_parser
SPEC.loader.exec_module(source_parser)

REQUIRED_TIMING_ZERO = (
    "Unconnected/logic driven clocks",
    "Sequential data pins driven by a clock signal",
    "Sequential clock pins without clock waveform",
    "Sequential clock pins with multiple clock waveforms",
    "Generated clocks without clock waveform",
    "Paths constrained with different clocks",
    "Nets with multiple drivers",
    "Timing exceptions with no effect",
    "Inputs without clocked external delays",
    "Outputs without clocked external delays",
    "Inputs without external driver/transition",
    "Outputs without external load",
)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read_tsv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle, delimiter="\t"))


def labeled_counts(text: str) -> dict[str, int]:
    counts: dict[str, int] = {}
    for line in text.splitlines():
        match = re.match(r"^\s*(\S.*?)\s+(\d+)\s*$", line)
        if match:
            counts[match.group(1).strip()] = int(match.group(2))
    return counts


def parse_top_bits(netlist: Path, top: str, errors: list[str]) -> set[tuple[str, str]]:
    try:
        modules = source_parser.parse_modules(netlist.read_text(errors="replace"))
        matches = [module for module in modules if module.name == top]
        if len(matches) != 1:
            errors.append(f"top_module_definition_count={len(matches)} expected=1")
            return set()
        specs = source_parser.declaration_port_specs(matches[0])
    except ValueError as exc:
        errors.append(f"netlist_parse={exc}")
        return set()
    nested = sorted(port.name for port in specs if "][" in port.name)
    if nested:
        errors.append("adjacent_top_dimensions=" + ",".join(nested))
    return {(port.name, port.direction.lower()) for port in specs}


def parse_qor_row(text: str, clock: str) -> tuple[float, float, int] | None:
    match = re.search(
        rf"^\s*{re.escape(clock)}\s+([+-]?[0-9.]+)\s+([+-]?[0-9.]+)\s+(\d+)\s*$",
        text,
        re.MULTILINE,
    )
    if not match:
        return None
    return float(match.group(1)), float(match.group(2)), int(match.group(3))


def minimum_slack(text: str) -> float | None:
    values = [
        float(value)
        for value in re.findall(
            r"(?im)^\s*(?:slack\s*:?=|slack)\s*([+-]?[0-9]+(?:\.[0-9]+)?)",
            text,
        )
    ]
    if values:
        return min(values)
    if re.search(r"(?i)no\s+(?:timing\s+)?paths?\s+(?:found|reported)", text):
        return math.inf
    return None


def warning_count(text: str, name: str) -> int | None:
    match = re.search(rf"^{re.escape(name)} count=(\d+)\s*$", text, re.MULTILINE)
    return int(match.group(1)) if match else None


def expected_clocks(phase: str) -> tuple[str, ...]:
    common = ("clk_160m_root", "clk_sys", "ddrs2_clk_160m_out")
    if phase == "p03_matrix_interface":
        return common + ("clk_cfg_40m", "clk_ref_40m")
    return common


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--phase", required=True)
    parser.add_argument("--block-root", required=True, type=Path)
    parser.add_argument("--boundary-bits", required=True, type=Path)
    parser.add_argument(
        "--contract",
        type=Path,
        default=ROOT / "TOP/pnr/assembly/spadmic_digital_assembly_contract.json",
    )
    parser.add_argument("--status", required=True, type=Path)
    args = parser.parse_args()

    contract = json.loads(args.contract.read_text(encoding="utf-8"))
    if args.phase not in contract["phases"]:
        raise SystemExit(f"unknown assembly phase: {args.phase}")
    top = contract["phases"][args.phase]["top"]
    block_root = args.block_root.resolve()
    reports = block_root / "reports"
    outputs = block_root / "outputs"
    netlist = outputs / f"{top}.postsyn.v"
    sdc = outputs / f"{top}.postsyn.sdc"
    required_files = {
        "POSTSYN_NETLIST": netlist,
        "POSTSYN_SDC": sdc,
        "CHECK_DESIGN": reports / "elaboration/check_design_post_elab.rpt",
        "TIMING_INTENT": reports / "timing/check_timing_intent.rpt",
        "CLOCK_REPORT": reports / "timing/report_clocks.rpt",
        "SETUP_REPORT": reports / "timing/report_timing_post_opt_setup.rpt",
        "HOLD_REPORT": reports / "timing/report_timing_post_opt_hold.rpt",
        "QOR_REPORT": reports / "qor/report_qor.rpt",
        "DESIGN_RULE_REPORT": reports / "qor/report_design_rules.rpt",
        "WARNING_REPORT": reports / "messages/warning_classification.rpt",
        "HIERARCHY_POLICY": reports / "messages/physical_hierarchy_policy.rpt",
    }
    errors: list[str] = []
    for label, path in required_files.items():
        if not path.is_file() or path.stat().st_size == 0:
            errors.append(f"missing_or_empty_{label.lower()}={path}")

    expected_rows = read_tsv(args.boundary_bits) if args.boundary_bits.is_file() else []
    if not expected_rows:
        errors.append(f"missing_or_empty_boundary_bits={args.boundary_bits}")
    expected_bits = {(row["bit_name"], row["direction"].lower()) for row in expected_rows}
    actual_bits = parse_top_bits(netlist, top, errors) if netlist.is_file() else set()
    missing_bits = sorted(expected_bits - actual_bits)
    unexpected_bits = sorted(actual_bits - expected_bits)
    if missing_bits:
        errors.append("boundary_missing=" + ",".join(f"{direction}:{name}" for name, direction in missing_bits))
    if unexpected_bits:
        errors.append("boundary_unexpected=" + ",".join(f"{direction}:{name}" for name, direction in unexpected_bits))
    for supply in ("VDD", "VSS"):
        if (supply, "inout") not in actual_bits:
            errors.append(f"required_supply_boundary_missing={supply}")

    check_text = required_files["CHECK_DESIGN"].read_text(errors="replace") if required_files["CHECK_DESIGN"].is_file() else ""
    unresolved = re.search(r"^\s*Unresolved References\s+(\d+)\s*$", check_text, re.MULTILINE)
    unresolved_count = int(unresolved.group(1)) if unresolved else 0 if "No unresolved references" in check_text else -1
    if unresolved_count != 0:
        errors.append(f"unresolved_reference_count={unresolved_count} expected=0")

    timing_text = required_files["TIMING_INTENT"].read_text(errors="replace") if required_files["TIMING_INTENT"].is_file() else ""
    timing_counts = labeled_counts(timing_text)
    for label in REQUIRED_TIMING_ZERO:
        value = timing_counts.get(label)
        if value is None:
            errors.append(f"timing_intent_missing={label}")
        elif value != 0:
            errors.append(f"timing_intent_nonzero={label}:{value}")

    clock_text = required_files["CLOCK_REPORT"].read_text(errors="replace") if required_files["CLOCK_REPORT"].is_file() else ""
    missing_clocks = [
        clock for clock in expected_clocks(args.phase)
        if not re.search(rf"(?m)^\s*{re.escape(clock)}(?:\s|$)", clock_text)
    ]
    if missing_clocks:
        errors.append("clock_report_missing=" + ",".join(missing_clocks))

    sdc_text = sdc.read_text(errors="replace") if sdc.is_file() else ""
    if re.search(r"(?i)set_clock_groups[^\n]*-asynchronous", sdc_text):
        errors.append("prohibited_asynchronous_clock_group=present")
    for clock in expected_clocks(args.phase):
        if clock not in sdc_text:
            errors.append(f"postsyn_sdc_clock_missing={clock}")

    qor_text = required_files["QOR_REPORT"].read_text(errors="replace") if required_files["QOR_REPORT"].is_file() else ""
    qor_clock_names = ["clk_sys"]
    if args.phase == "p03_matrix_interface":
        qor_clock_names.append("clk_cfg_40m")
    worst_wns = math.inf
    total_tns = 0.0
    violating_paths = 0
    for clock in qor_clock_names:
        row = parse_qor_row(qor_text, clock)
        if row is None:
            errors.append(f"qor_clock_row_missing={clock}")
            continue
        wns, tns, paths = row
        worst_wns = min(worst_wns, wns)
        total_tns += tns
        violating_paths += paths
        if wns < 0.0:
            errors.append(f"setup_wns={clock}:{wns} expected_nonnegative")
        if abs(tns) > 0.001:
            errors.append(f"setup_tns={clock}:{tns} expected=0")
        if paths != 0:
            errors.append(f"setup_violating_paths={clock}:{paths} expected=0")

    setup_text = required_files["SETUP_REPORT"].read_text(errors="replace") if required_files["SETUP_REPORT"].is_file() else ""
    hold_text = required_files["HOLD_REPORT"].read_text(errors="replace") if required_files["HOLD_REPORT"].is_file() else ""
    setup_slack = minimum_slack(setup_text)
    hold_slack = minimum_slack(hold_text)
    if setup_slack is None:
        errors.append("setup_slack_not_parseable")
    elif setup_slack < 0.0:
        errors.append(f"setup_report_min_slack={setup_slack} expected_nonnegative")
    if hold_slack is None:
        errors.append("hold_slack_not_parseable")
    elif hold_slack < 0.0:
        errors.append(f"hold_report_min_slack={hold_slack} expected_nonnegative")

    warning_text = required_files["WARNING_REPORT"].read_text(errors="replace") if required_files["WARNING_REPORT"].is_file() else ""
    for warning_class in (
        "design_rule", "inferred_latch", "missing_external_delay",
        "no_clock_waveform", "tool_error", "unresolved",
    ):
        value = warning_count(warning_text, warning_class)
        if value is None:
            errors.append(f"warning_class_missing={warning_class}")
        elif value != 0:
            errors.append(f"warning_class_{warning_class}={value} expected=0")

    hierarchy_text = required_files["HIERARCHY_POLICY"].read_text(errors="replace") if required_files["HIERARCHY_POLICY"].is_file() else ""
    if not re.search(r"(?m)^STATUS=PASS$", hierarchy_text):
        errors.append("physical_hierarchy_policy_status=FAIL_OR_MISSING")

    status_value = "PASS" if not errors else "FAIL"
    boundary_status = "PASS" if not missing_bits and not unexpected_bits else "FAIL"
    values: dict[str, object] = {
        "LABEL": "SPADMIC_DIGITAL_ASSEMBLY_GENUS_TC_GATE",
        "STATUS": status_value,
        "RESULT": "INNOVUS_HANDOFF_READY" if not errors else "REVIEW_REQUIRED",
        "PHASE": args.phase,
        "TOP_MODULE": top,
        "SOURCE_TOP": top,
        "LAYOUT_TOP": top,
        "IMPLEMENTATION": "CUMULATIVE_SOFT_LOGIC",
        "HARD_MACRO_COUNT": 0,
        "PHYSICAL_HIERARCHY_STATUS": "PASS" if "physical_hierarchy_policy_status=FAIL_OR_MISSING" not in errors else "FAIL",
        "BOUNDARY_STATUS": boundary_status,
        "EXPECTED_BIT_PORT_COUNT": len(expected_bits),
        "ACTUAL_BIT_PORT_COUNT": len(actual_bits),
        "UNRESOLVED_REFERENCE_COUNT": unresolved_count,
        "RELATED_CLOCK_STATUS": "PASS" if not missing_clocks else "FAIL",
        "ASYNCHRONOUS_CLOCK_GROUP_COUNT": 0 if "prohibited_asynchronous_clock_group=present" not in errors else 1,
        "SETUP_STATUS": "PASS" if setup_slack is not None and setup_slack >= 0.0 and violating_paths == 0 else "FAIL",
        "HOLD_STATUS": "PASS" if hold_slack is not None and hold_slack >= 0.0 else "FAIL",
        "WORST_SETUP_WNS_PS": "INF" if math.isinf(worst_wns) else f"{worst_wns:.3f}",
        "TOTAL_SETUP_TNS_PS": f"{total_tns:.3f}",
        "SETUP_VIOLATING_PATH_COUNT": violating_paths,
        "MIN_SETUP_REPORT_SLACK_PS": "UNKNOWN" if setup_slack is None else "INF" if math.isinf(setup_slack) else f"{setup_slack:.3f}",
        "MIN_HOLD_REPORT_SLACK_PS": "UNKNOWN" if hold_slack is None else "INF" if math.isinf(hold_slack) else f"{hold_slack:.3f}",
        "DESIGN_RULE_STATUS": "PASS" if not any(error.startswith("warning_class_design_rule=") for error in errors) else "FAIL",
        "TYPICAL_CLOSED": "YES" if not errors else "NO",
        "INNOVUS_HANDOFF_READY": "YES" if not errors else "NO",
        "MMMC_STATUS": "NOT_RUN_TC_ONLY",
        "CDC_RDC_STATUS": "STA_ONLY_NO_DEDICATED_TOOL",
        "PVS_STATUS": "NOT_RUN",
        "SIGNOFF_READY": "NO",
        "BOUNDARY_BITS_SHA256": sha256(args.boundary_bits) if args.boundary_bits.is_file() else "MISSING",
        "POSTSYN_NETLIST_SHA256": sha256(netlist) if netlist.is_file() else "MISSING",
        "POSTSYN_SDC_SHA256": sha256(sdc) if sdc.is_file() else "MISSING",
        "ERROR_COUNT": len(errors),
        "NEXT_GATE": "RUN_PHASE_INNOVUS" if not errors else "STOP_AND_REVIEW_GENUS_TC",
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
