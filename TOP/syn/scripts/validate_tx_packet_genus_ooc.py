#!/usr/bin/env python3
"""Fail-closed feasibility gate for canonical TX packet-core Genus reports."""

from __future__ import annotations

import argparse
import csv
import hashlib
import importlib.util
import re
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
SOURCE_PARSER_PATH = REPO_ROOT / "TOP" / "pnr" / "scripts" / "prepare_pvs_lvs_source.py"
SOURCE_PARSER_SPEC = importlib.util.spec_from_file_location(
    "tx_packet_genus_source_parser", SOURCE_PARSER_PATH
)
assert SOURCE_PARSER_SPEC and SOURCE_PARSER_SPEC.loader
source_parser = importlib.util.module_from_spec(SOURCE_PARSER_SPEC)
sys.modules[SOURCE_PARSER_SPEC.name] = source_parser
SOURCE_PARSER_SPEC.loader.exec_module(source_parser)

TX_SOURCE_MANIFEST = REPO_ROOT / "TOP" / "rtl" / "interfaces" / "tx_src_data_flat.csv"
TOP_MODULE = "spadmic_tx_packet_core"
CLOCK_NAME = "clk_sys"
EXPECTED_PERIOD_PS = 6250.0

REQUIRED_TIMING_INTENT_ZERO = (
    "Unconnected/logic driven clocks",
    "Sequential data pins driven by a clock signal",
    "Sequential clock pins without clock waveform",
    "Sequential clock pins with multiple clock waveforms",
    "Generated clocks without clock waveform",
    "Generated clocks with incompatible options",
    "Generated clocks with multi-master clock",
    "Paths constrained with different clocks",
    "Nets with multiple drivers",
    "Timing exceptions with no effect",
    "Suspicious multi_cycle exceptions",
    "Pins/ports with conflicting case constants",
    "Inputs without clocked external delays",
    "Outputs without clocked external delays",
    "Exceptions with invalid timing start-/endpoints",
)

REQUIRED_WARNING_ZERO = (
    "design_rule",
    "inferred_latch",
    "missing_external_delay",
    "no_clock_waveform",
    "tool_error",
    "unresolved",
)


def digest(path: Path) -> str:
    sha = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            sha.update(chunk)
    return sha.hexdigest()


def require_nonempty(path: Path, label: str, errors: list[str]) -> bool:
    if not path.is_file() or path.stat().st_size == 0:
        errors.append(f"missing_or_empty_{label}={path}")
        return False
    return True


def parse_top_ports(netlist: Path, errors: list[str]) -> set[str]:
    try:
        modules = source_parser.parse_modules(netlist.read_text(errors="replace"))
        matching = [module for module in modules if module.name == TOP_MODULE]
        if len(matching) != 1:
            errors.append(f"top_module_definition_count={len(matching)} expected=1")
            return set()
        return set(source_parser.declaration_ports(matching[0]))
    except ValueError as error:
        errors.append(f"netlist_parse={error}")
        return set()


def expected_scalar_ports(errors: list[str]) -> set[str]:
    canonical = {
        f"src_data_i_s{source}_b{bit}"
        for source in range(4)
        for bit in range(16)
    }
    try:
        with TX_SOURCE_MANIFEST.open(newline="") as handle:
            rows = list(csv.DictReader(handle))
        manifest_names = [row["name"] for row in rows]
    except (OSError, KeyError) as error:
        errors.append(f"source_manifest_read={error}")
        return canonical

    if len(manifest_names) != 64:
        errors.append(f"source_manifest_row_count={len(manifest_names)} expected=64")
    if len(set(manifest_names)) != len(manifest_names):
        errors.append("source_manifest_has_duplicate_names")
    if set(manifest_names) != canonical:
        errors.append("source_manifest_does_not_match_canonical_4x16_contract")
    return canonical


def parse_labeled_counts(text: str) -> dict[str, int]:
    counts: dict[str, int] = {}
    for line in text.splitlines():
        match = re.match(r"^\s*(\S.*?)\s+(\d+)\s*$", line)
        if match:
            counts[match.group(1).strip()] = int(match.group(2))
    return counts


def parse_warning_counts(text: str) -> dict[str, int]:
    return {
        match.group(1): int(match.group(2))
        for match in re.finditer(r"^([a-z_]+) count=(\d+)\s*$", text, re.MULTILINE)
    }


def parse_clock_row(text: str, errors: list[str]) -> tuple[float, int]:
    match = re.search(
        rf"^\s*{re.escape(CLOCK_NAME)}\s+([0-9.]+)\s+[0-9.]+\s+[0-9.]+\s+\S+\s+\S+\s+(\d+)\s*$",
        text,
        re.MULTILINE,
    )
    if not match:
        errors.append(f"clock_row_missing={CLOCK_NAME}")
        return -1.0, -1
    return float(match.group(1)), int(match.group(2))


def parse_qor(text: str, errors: list[str]) -> tuple[float, float, int, bool]:
    match = re.search(
        rf"^\s*{re.escape(CLOCK_NAME)}\s+([+-]?[0-9.]+)\s+([+-]?[0-9.]+)\s+(\d+)\s*$",
        text,
        re.MULTILINE,
    )
    if not match:
        errors.append(f"qor_clock_row_missing={CLOCK_NAME}")
        return float("nan"), float("nan"), -1, False
    default_no_paths = bool(re.search(r"^\s*default\s+No paths\s+0\.0\s*$", text, re.MULTILINE))
    if not default_no_paths:
        errors.append("qor_default_group_has_paths_or_is_missing")
    return float(match.group(1)), float(match.group(2)), int(match.group(3)), default_no_paths


def parse_sequential_instance_count(text: str, errors: list[str]) -> int:
    match = re.search(r"^\s*Sequential Instance Count\s+(\d+)\s*$", text, re.MULTILINE)
    if not match:
        errors.append("qor_sequential_instance_count_missing")
        return -1
    return int(match.group(1))


def validate(block_root: Path, report: Path) -> dict[str, str]:
    outputs = block_root / "outputs"
    reports = block_root / "reports"
    netlist = outputs / "tx_packet_core.postsyn.v"
    sdc = outputs / "tx_packet_core.postsyn.sdc"
    check_design = reports / "elaboration" / "check_design_post_elab.rpt"
    timing_intent = reports / "timing" / "check_timing_intent.rpt"
    clock_report = reports / "timing" / "report_clocks.rpt"
    qor_report = reports / "qor" / "report_qor.rpt"
    warning_report = reports / "messages" / "warning_classification.rpt"
    errors: list[str] = []

    for path, label in (
        (netlist, "postsyn_netlist"),
        (sdc, "postsyn_sdc"),
        (check_design, "check_design"),
        (timing_intent, "timing_intent"),
        (clock_report, "clock_report"),
        (qor_report, "qor_report"),
        (warning_report, "warning_classification"),
    ):
        require_nonempty(path, label, errors)

    ports = parse_top_ports(netlist, errors) if netlist.is_file() else set()
    expected_scalars = expected_scalar_ports(errors)
    actual_scalars = {port for port in ports if port.startswith("src_data_i_s")}
    missing_scalars = sorted(expected_scalars - ports)
    extra_scalars = sorted(actual_scalars - expected_scalars)
    nested_ports = sorted(port for port in ports if "][" in port)
    if missing_scalars:
        errors.append("missing_scalar_ports=" + ",".join(missing_scalars))
    if extra_scalars:
        errors.append("unexpected_scalar_ports=" + ",".join(extra_scalars))
    if nested_ports:
        errors.append("nested_top_ports=" + ",".join(nested_ports))

    check_design_text = check_design.read_text(errors="replace") if check_design.is_file() else ""
    unresolved_count = -1
    unresolved_match = re.search(
        r"^\s*Unresolved References\s+(\d+)\s*$",
        check_design_text,
        re.MULTILINE,
    )
    if unresolved_match:
        unresolved_count = int(unresolved_match.group(1))
    elif "No unresolved references" in check_design_text:
        unresolved_count = 0
    else:
        errors.append("unresolved_reference_summary_missing")
    if unresolved_count != 0:
        errors.append(f"unresolved_reference_count={unresolved_count} expected=0")

    intent_text = timing_intent.read_text(errors="replace") if timing_intent.is_file() else ""
    intent_counts = parse_labeled_counts(intent_text)
    for label in REQUIRED_TIMING_INTENT_ZERO:
        value = intent_counts.get(label)
        if value is None:
            errors.append(f"timing_intent_missing={label}")
        elif value != 0:
            errors.append(f"timing_intent_nonzero={label}:{value}")
    no_driver_count = intent_counts.get("Inputs without external driver/transition", -1)
    no_load_count = intent_counts.get("Outputs without external load", -1)
    if no_driver_count < 0:
        errors.append("timing_intent_missing=Inputs without external driver/transition")
    if no_load_count < 0:
        errors.append("timing_intent_missing=Outputs without external load")

    clock_text = clock_report.read_text(errors="replace") if clock_report.is_file() else ""
    clock_period_ps, clock_register_count = parse_clock_row(clock_text, errors)
    if abs(clock_period_ps - EXPECTED_PERIOD_PS) > 0.01:
        errors.append(f"clock_period_ps={clock_period_ps} expected={EXPECTED_PERIOD_PS}")
    if clock_register_count <= 0:
        errors.append(f"clock_register_count={clock_register_count} expected_positive")

    qor_text = qor_report.read_text(errors="replace") if qor_report.is_file() else ""
    wns_ps, tns_ps, violating_paths, default_no_paths = parse_qor(qor_text, errors)
    sequential_instance_count = parse_sequential_instance_count(qor_text, errors)
    if wns_ps < 0:
        errors.append(f"wns_ps={wns_ps} expected_nonnegative")
    if abs(tns_ps) > 0.001:
        errors.append(f"tns_ps={tns_ps} expected=0")
    if violating_paths != 0:
        errors.append(f"violating_paths={violating_paths} expected=0")
    if sequential_instance_count != clock_register_count:
        errors.append(
            "clocked_register_coverage="
            f"{clock_register_count}/{sequential_instance_count} expected_equal"
        )

    warning_text = warning_report.read_text(errors="replace") if warning_report.is_file() else ""
    warning_counts = parse_warning_counts(warning_text)
    for key in REQUIRED_WARNING_ZERO:
        value = warning_counts.get(key)
        if value is None:
            errors.append(f"warning_class_missing={key}")
        elif value != 0:
            errors.append(f"warning_class_nonzero={key}:{value}")

    tool_warning_count = warning_counts.get("tool_warning", -1)
    legacy_undriven_classifier_count = warning_counts.get("undriven", -1)
    status = "PASS" if not errors else "FAIL"
    values = {
        "LABEL": "SPADMIC_TX_PACKET_GENUS_OOC_GATE",
        "STATUS": status,
        "RESULT": "READY_FOR_PACKET_INNOVUS_FEASIBILITY" if not errors else "REVIEW_REQUIRED",
        "BLOCK_ROOT": str(block_root),
        "TOP_MODULE": TOP_MODULE,
        "CLOCK_NAME": CLOCK_NAME,
        "CLOCK_PERIOD_PS": f"{clock_period_ps:.1f}",
        "CLOCK_REGISTER_COUNT": str(clock_register_count),
        "SEQUENTIAL_INSTANCE_COUNT": str(sequential_instance_count),
        "WNS_PS": f"{wns_ps:.1f}",
        "TNS_PS": f"{tns_ps:.1f}",
        "VIOLATING_PATH_COUNT": str(violating_paths),
        "DEFAULT_PATH_GROUP_STATUS": "NO_PATHS" if default_no_paths else "REVIEW_REQUIRED",
        "UNRESOLVED_REFERENCE_COUNT": str(unresolved_count),
        "SCALAR_SOURCE_PORT_COUNT": str(len(actual_scalars)),
        "NESTED_TOP_PORT_COUNT": str(len(nested_ports)),
        "INPUTS_WITHOUT_CLOCKED_EXTERNAL_DELAY": str(
            intent_counts.get("Inputs without clocked external delays", -1)
        ),
        "OUTPUTS_WITHOUT_CLOCKED_EXTERNAL_DELAY": str(
            intent_counts.get("Outputs without clocked external delays", -1)
        ),
        "INPUTS_WITHOUT_EXTERNAL_DRIVER_TRANSITION": str(no_driver_count),
        "OUTPUTS_WITHOUT_EXTERNAL_LOAD": str(no_load_count),
        "IO_TIMING_MODEL_STATUS": "OOC_FEASIBILITY_LIMITATION_EXTERNAL_DRIVE_LOAD_DEFERRED",
        "NONBLOCKING_TOOL_WARNING_COUNT": str(tool_warning_count),
        "LEGACY_UNDRIVEN_CLASSIFIER_COUNT": str(legacy_undriven_classifier_count),
        "INNOVUS_FEASIBILITY_READY": "YES" if not errors else "NO",
        "MMMC_STATUS": "NOT_RUN_TYPICAL_ONLY",
        "SIGNOFF_READY": "NO",
        "POSTSYN_NETLIST_SHA256": digest(netlist) if netlist.is_file() else "MISSING",
        "POSTSYN_SDC_SHA256": digest(sdc) if sdc.is_file() else "MISSING",
        "ERROR_COUNT": str(len(errors)),
    }
    report.parent.mkdir(parents=True, exist_ok=True)
    report_lines = [
        *(f"{key}={value}" for key, value in values.items()),
        *(f"ERROR={error}" for error in errors),
    ]
    report.write_text(
        "\n".join(report_lines) + "\n"
    )
    return values


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--block-root", required=True, type=Path)
    parser.add_argument("--status", type=Path)
    args = parser.parse_args()
    block_root = args.block_root.resolve()
    report = args.status.resolve() if args.status else block_root / "reports" / "canonical_tx_genus_gate.rpt"
    values = validate(block_root, report)
    print(report.read_text(), end="")
    if values["STATUS"] != "PASS":
        raise SystemExit(8)


if __name__ == "__main__":
    main()
