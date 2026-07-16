#!/usr/bin/env python3
"""Fail-closed typical-corner Genus gate for reusable digital hard macros."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import re
import sys
from dataclasses import dataclass
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
PARSER_PATH = REPO_ROOT / "TOP" / "pnr" / "scripts" / "prepare_pvs_lvs_source.py"
SPEC = importlib.util.spec_from_file_location("genus_tc_source_parser", PARSER_PATH)
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


@dataclass(frozen=True)
class PortContract:
    direction: str
    width: int = 1


EXPECTED_BOUNDARIES = {
    "spadmic_position_core": {
        "clk_sys": PortContract("input"),
        "rst_n": PortContract("input"),
        "start_i": PortContract("input"),
        "mode_i": PortContract("input"),
        "event_id_i": PortContract("input", 14),
        "snapshot_R_i": PortContract("input", 64),
        "snapshot_Y_i": PortContract("input", 64),
        "snapshot_B_i": PortContract("input", 64),
        "gap_threshold_i": PortContract("input", 7),
        "min_cluster_span_i": PortContract("input", 7),
        "pkt_valid_o": PortContract("output"),
        "pkt_ready_i": PortContract("input"),
        "pkt_data_o": PortContract("output", 16),
        "pkt_sop_o": PortContract("output"),
        "pkt_eop_o": PortContract("output"),
        "packet_pending_o": PortContract("output"),
        "busy_o": PortContract("output"),
        "snapshot_captured_o": PortContract("output"),
        "done_o": PortContract("output"),
        "drop_o": PortContract("output"),
    },
    "spadmic_event_coordinator": {
        "clk_sys": PortContract("input"),
        "rst_n": PortContract("input"),
        "active_mode_i": PortContract("input", 3),
        "global_enable_i": PortContract("input"),
        "active_axis_mask_i": PortContract("input", 3),
        "matrix_activity_i": PortContract("input"),
        "cal_activity_i": PortContract("input"),
        "pre_event_resources_ready_i": PortContract("input"),
        "raw_snapshot_required_i": PortContract("input"),
        "auto_reset_enable_i": PortContract("input"),
        "snapshot_valid_i": PortContract("input"),
        "position_snapshot_captured_i": PortContract("input"),
        "tdc_start_seen_i": PortContract("input", 3),
        "packet_pending_mask_i": PortContract("input", 4),
        "reset_done_i": PortContract("input"),
        "bundle_done_i": PortContract("input"),
        "rearm_ready_i": PortContract("input"),
        "event_open_o": PortContract("output"),
        "event_id_o": PortContract("output", 14),
        "event_id_valid_o": PortContract("output"),
        "required_packet_mask_o": PortContract("output", 4),
        "required_tdc_mask_o": PortContract("output", 3),
        "required_reset_ack_mask_o": PortContract("output", 4),
        "observed_reset_ack_mask_o": PortContract("output", 4),
        "reset_start_o": PortContract("output"),
        "bundle_start_o": PortContract("output"),
        "accept_enable_o": PortContract("output"),
        "rejected_not_ready_o": PortContract("output"),
        "busy_o": PortContract("output"),
        "idle_o": PortContract("output"),
    },
}


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def labeled_counts(text: str) -> dict[str, int]:
    counts: dict[str, int] = {}
    for line in text.splitlines():
        match = re.match(r"^\s*(\S.*?)\s+(\d+)\s*$", line)
        if match:
            counts[match.group(1).strip()] = int(match.group(2))
    return counts


def split_port_bit(port: str) -> tuple[str, int | None]:
    match = re.fullmatch(r"(.+)\[(-?\d+)\]", port)
    if match:
        return match.group(1), int(match.group(2))
    return port, None


def parse_top(
    netlist: Path,
    top_module: str,
    errors: list[str],
) -> tuple[int, int, str]:
    try:
        modules = source_parser.parse_modules(netlist.read_text(errors="replace"))
        matches = [module for module in modules if module.name == top_module]
        if len(matches) != 1:
            errors.append(f"top_module_definition_count={len(matches)} expected=1")
            return 0, 0, "FAIL"
        specs = source_parser.declaration_port_specs(matches[0])
        nested = [port.name for port in specs if "][" in port.name]
        if nested:
            errors.append("nested_top_ports=" + ",".join(sorted(nested)))
        expected = EXPECTED_BOUNDARIES.get(top_module)
        if expected is None:
            errors.append(f"unsupported_boundary_contract={top_module}")
            return len(specs), 0, "FAIL"

        actual_bits: dict[str, set[int | None]] = {}
        actual_directions: dict[str, set[str]] = {}
        for spec in specs:
            base, bit = split_port_bit(spec.name)
            actual_bits.setdefault(base, set()).add(bit)
            actual_directions.setdefault(base, set()).add(spec.direction)

        missing = sorted(set(expected) - set(actual_bits))
        unexpected = sorted(set(actual_bits) - set(expected))
        if missing:
            errors.append("boundary_missing_ports=" + ",".join(missing))
        if unexpected:
            errors.append("boundary_unexpected_ports=" + ",".join(unexpected))

        for name in sorted(set(expected) & set(actual_bits)):
            contract = expected[name]
            directions = actual_directions[name]
            if directions != {contract.direction}:
                errors.append(
                    f"boundary_direction={name}:{','.join(sorted(directions))} "
                    f"expected={contract.direction}"
                )
            expected_bits: set[int | None]
            if contract.width == 1:
                expected_bits = {None}
            else:
                expected_bits = set(range(contract.width))
            if actual_bits[name] != expected_bits:
                actual_text = ",".join(
                    "scalar" if bit is None else str(bit)
                    for bit in sorted(
                        actual_bits[name],
                        key=lambda value: -1 if value is None else value,
                    )
                )
                errors.append(
                    f"boundary_width={name}:{actual_text} "
                    f"expected=0..{contract.width - 1}"
                )

        boundary_status = "PASS" if not any(
            error.startswith(
                (
                    "nested_top_ports=",
                    "boundary_",
                    "unsupported_boundary_contract=",
                )
            )
            for error in errors
        ) else "FAIL"
        return len(specs), len(actual_bits), boundary_status
    except ValueError as error:
        errors.append(f"netlist_parse={error}")
        return 0, 0, "FAIL"


def parse_qor(text: str, clock_name: str, errors: list[str]) -> tuple[float, float, int]:
    match = re.search(
        rf"^\s*{re.escape(clock_name)}\s+([+-]?[0-9.]+)\s+([+-]?[0-9.]+)\s+(\d+)\s*$",
        text,
        re.MULTILINE,
    )
    if not match:
        errors.append(f"qor_clock_row_missing={clock_name}")
        return float("nan"), float("nan"), -1
    return float(match.group(1)), float(match.group(2)), int(match.group(3))


def validate(
    block_root: Path,
    block: str,
    top_module: str,
    clock_name: str,
    expected_period_ps: float,
    report: Path,
) -> dict[str, str]:
    outputs = block_root / "outputs"
    reports = block_root / "reports"
    netlist = outputs / f"{block}.postsyn.v"
    sdc = outputs / f"{block}.postsyn.sdc"
    check_design = reports / "elaboration" / "check_design_post_elab.rpt"
    timing_intent = reports / "timing" / "check_timing_intent.rpt"
    clocks = reports / "timing" / "report_clocks.rpt"
    qor = reports / "qor" / "report_qor.rpt"
    warning_report = reports / "messages" / "warning_classification.rpt"
    errors: list[str] = []

    for label, path in (
        ("postsyn_netlist", netlist),
        ("postsyn_sdc", sdc),
        ("check_design", check_design),
        ("timing_intent", timing_intent),
        ("clock_report", clocks),
        ("qor_report", qor),
        ("warning_classification", warning_report),
    ):
        if not path.is_file() or path.stat().st_size == 0:
            errors.append(f"missing_or_empty_{label}={path}")

    if netlist.is_file():
        port_count, base_port_count, boundary_status = parse_top(
            netlist,
            top_module,
            errors,
        )
    else:
        port_count, base_port_count, boundary_status = 0, 0, "FAIL"
    expected_boundary = EXPECTED_BOUNDARIES.get(top_module, {})
    check_text = check_design.read_text(errors="replace") if check_design.is_file() else ""
    unresolved = re.search(r"^\s*Unresolved References\s+(\d+)\s*$", check_text, re.MULTILINE)
    unresolved_count = int(unresolved.group(1)) if unresolved else 0 if "No unresolved references" in check_text else -1
    if unresolved_count != 0:
        errors.append(f"unresolved_reference_count={unresolved_count} expected=0")

    timing_text = timing_intent.read_text(errors="replace") if timing_intent.is_file() else ""
    counts = labeled_counts(timing_text)
    for label in REQUIRED_TIMING_ZERO:
        value = counts.get(label)
        if value is None:
            errors.append(f"timing_intent_missing={label}")
        elif value != 0:
            errors.append(f"timing_intent_nonzero={label}:{value}")

    clock_text = clocks.read_text(errors="replace") if clocks.is_file() else ""
    clock_match = re.search(
        rf"^\s*{re.escape(clock_name)}\s+([0-9.]+)\s+[0-9.]+\s+[0-9.]+\s+\S+\s+\S+\s+(\d+)\s*$",
        clock_text,
        re.MULTILINE,
    )
    period_ps = float(clock_match.group(1)) if clock_match else -1.0
    register_count = int(clock_match.group(2)) if clock_match else -1
    if not clock_match:
        errors.append(f"clock_row_missing={clock_name}")
    if abs(period_ps - expected_period_ps) > 0.01:
        errors.append(f"clock_period_ps={period_ps} expected={expected_period_ps}")
    if register_count <= 0:
        errors.append(f"clock_register_count={register_count} expected_positive")

    qor_text = qor.read_text(errors="replace") if qor.is_file() else ""
    wns_ps, tns_ps, violating_paths = parse_qor(qor_text, clock_name, errors)
    if wns_ps < 0:
        errors.append(f"wns_ps={wns_ps} expected_nonnegative")
    if abs(tns_ps) > 0.001:
        errors.append(f"tns_ps={tns_ps} expected=0")
    if violating_paths != 0:
        errors.append(f"violating_paths={violating_paths} expected=0")

    warning_text = warning_report.read_text(errors="replace") if warning_report.is_file() else ""
    for warning_class in ("design_rule", "inferred_latch", "missing_external_delay", "no_clock_waveform", "tool_error", "unresolved"):
        match = re.search(
            rf"^{re.escape(warning_class)} count=(\d+)\s*$",
            warning_text,
            re.MULTILINE,
        )
        value = int(match.group(1)) if match else -1
        if value != 0:
            errors.append(f"warning_class_{warning_class}={value} expected=0")

    status = "PASS" if not errors else "FAIL"
    values = {
        "LABEL": "SPADMIC_GENUS_TC_OOC_GATE",
        "STATUS": status,
        "TC_TIMING_STATUS": status,
        "RESULT": "READY_FOR_ISOLATED_INNOVUS_OOC" if not errors else "REVIEW_REQUIRED",
        "BLOCK": block,
        "TOP_MODULE": top_module,
        "CLOCK_NAME": clock_name,
        "CLOCK_PERIOD_PS": f"{period_ps:.1f}",
        "CLOCK_REGISTER_COUNT": str(register_count),
        "TOP_PORT_COUNT": str(port_count),
        "BOUNDARY_PORT_STATUS": boundary_status,
        "EXPECTED_BASE_PORT_COUNT": str(len(expected_boundary)),
        "ACTUAL_BASE_PORT_COUNT": str(base_port_count),
        "EXPECTED_BIT_PORT_COUNT": str(
            sum(contract.width for contract in expected_boundary.values())
        ),
        "ACTUAL_BIT_PORT_COUNT": str(port_count),
        "UNRESOLVED_REFERENCE_COUNT": str(unresolved_count),
        "WNS_PS": f"{wns_ps:.1f}",
        "TNS_PS": f"{tns_ps:.1f}",
        "VIOLATING_PATH_COUNT": str(violating_paths),
        "MMMC_STATUS": "NOT_RUN_TYPICAL_ONLY",
        "SIGNOFF_READY": "NO",
        "POSTSYN_NETLIST_SHA256": digest(netlist) if netlist.is_file() else "MISSING",
        "POSTSYN_SDC_SHA256": digest(sdc) if sdc.is_file() else "MISSING",
        "ERROR_COUNT": str(len(errors)),
    }
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text(
        "\n".join(
            [
                *(f"{key}={value}" for key, value in values.items()),
                *(f"ERROR={error}" for error in errors),
            ]
        )
        + "\n"
    )
    return values


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--block-root", required=True, type=Path)
    parser.add_argument("--block", required=True)
    parser.add_argument("--top-module", required=True)
    parser.add_argument("--clock-name", default="clk_sys")
    parser.add_argument("--period-ps", type=float, default=6250.0)
    parser.add_argument("--status", required=True, type=Path)
    args = parser.parse_args()
    result = validate(
        args.block_root.resolve(),
        args.block,
        args.top_module,
        args.clock_name,
        args.period_ps,
        args.status.resolve(),
    )
    print(args.status.resolve().read_text(), end="")
    if result["STATUS"] != "PASS":
        raise SystemExit(8)


if __name__ == "__main__":
    main()
