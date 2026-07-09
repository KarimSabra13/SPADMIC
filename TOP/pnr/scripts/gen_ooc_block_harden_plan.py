#!/usr/bin/env python3
"""Generate local OOC hardening collateral from the SPADMIC2 layout audit.

The generator intentionally emits a conservative local abstract plan. It uses
the audited top-layout CSVs for context, but does not place the block in
absolute top coordinates. Absolute placement remains a later top-assembly step.
"""

from __future__ import annotations

import argparse
import csv
import math
import re
from pathlib import Path
from typing import Iterable


PIN_HEADER = [
    "inst",
    "master_lib",
    "master_cell",
    "master_view",
    "orient",
    "term",
    "direction",
    "net",
    "layer",
    "purpose",
    "master_llx",
    "master_lly",
    "master_urx",
    "master_ury",
    "top_llx",
    "top_lly",
    "top_urx",
    "top_ury",
    "top_cx",
    "top_cy",
    "norm_top_llx",
    "norm_top_lly",
    "norm_top_urx",
    "norm_top_ury",
    "norm_top_cx",
    "norm_top_cy",
    "nearest_inst_side",
]


def read_headered_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="") as fh:
        return list(csv.DictReader(fh))


def read_pin_csv(path: Path) -> list[dict[str, str]]:
    if not path.exists() or path.stat().st_size == 0:
        return []
    with path.open(newline="") as fh:
        sample = fh.readline()
        fh.seek(0)
        if sample.startswith("inst,"):
            return list(csv.DictReader(fh))
        return list(csv.DictReader(fh, fieldnames=PIN_HEADER))


def tcl_quote(value: str) -> str:
    escaped = value.replace("\\", "\\\\").replace("}", "\\}").replace("{", "\\{")
    return "{" + escaped + "}"


def tcl_list(values: Iterable[str]) -> str:
    return " ".join(tcl_quote(v) for v in values)


def bus(name: str, width: int) -> list[str]:
    return [f"{name}[{idx}]" for idx in range(width)]


def bus2(name: str, outer: int, inner: int) -> list[str]:
    return [f"{name}[{outer_idx}][{inner_idx}]" for outer_idx in range(outer) for inner_idx in range(inner)]


def require_file(path: Path) -> None:
    if not path.is_file():
        raise SystemExit(f"required file is missing: {path}")


def class_counts(rows: list[dict[str, str]]) -> dict[str, int]:
    counts: dict[str, int] = {}
    for row in rows:
        cls = row.get("class", "") or "UNKNOWN"
        counts[cls] = counts.get(cls, 0) + 1
    return counts


def float_or_zero(value: str) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return 0.0


def summarize_bbox(rows: list[dict[str, str]], cls: str) -> list[str]:
    selected = [row for row in rows if row.get("class") == cls]
    lines: list[str] = []
    for row in selected:
        inst = row.get("inst", "")
        cell = row.get("cell", "")
        llx = float_or_zero(row.get("norm_llx", ""))
        lly = float_or_zero(row.get("norm_lly", ""))
        urx = float_or_zero(row.get("norm_urx", ""))
        ury = float_or_zero(row.get("norm_ury", ""))
        lines.append(f"- `{inst}` `{cell}` bbox=({llx:.3f}, {lly:.3f})-({urx:.3f}, {ury:.3f}) um")
    return lines


def write_pin_plan_csv(path: Path, plan: dict[str, list[str]], assignments: dict[str, dict[str, str]] | None = None) -> None:
    assignments = assignments or {}
    with path.open("w", newline="") as fh:
        writer = csv.writer(fh)
        writer.writerow([
            "port",
            "side",
            "layer",
            "order",
            "reason",
            "target_x_um",
            "target_y_um",
            "source_inst",
            "source_term",
            "source_x_um",
            "source_y_um",
        ])
        for side, ports in plan.items():
            for order, port in enumerate(ports):
                if side == "NORTH":
                    reason = "toward DDR16/DDRs2 output path"
                elif side == "SOUTH":
                    reason = "toward FIFO/event-bundle producer"
                else:
                    reason = "clock/reset/control entry"
                assignment = assignments.get(port, {})
                writer.writerow([
                    port,
                    side,
                    "MET3",
                    order,
                    reason,
                    assignment.get("target_x_um", ""),
                    assignment.get("target_y_um", ""),
                    assignment.get("source_inst", ""),
                    assignment.get("source_term", ""),
                    assignment.get("source_x_um", ""),
                    assignment.get("source_y_um", ""),
                ])


def write_manifest(path: Path, files: dict[str, Path]) -> None:
    with path.open("w", newline="") as fh:
        writer = csv.writer(fh)
        writer.writerow(["name", "path"])
        for name, file_path in files.items():
            writer.writerow([name, str(file_path)])


def term_lane(term: str) -> int | None:
    match = re.search(r"[<\[]([0-9]+)[>\]]", term)
    if not match:
        return None
    return int(match.group(1))


def ddrs2_macro_instance(instances: list[dict[str, str]]) -> dict[str, str]:
    for row in instances:
        if row.get("cell") == "DDRs2":
            return row
    raise SystemExit("could not find DDRs2 macro instance in SPADMIC2_instances_enriched.csv")


def tx_egress_core_north_assignments(
    ddrs2_pins: list[dict[str, str]],
    block_norm_llx: float,
    die_height_um: float,
    signal_pin_depth_um: float,
) -> tuple[list[str], dict[str, dict[str, str]], list[dict[str, str]]]:
    mapped: list[tuple[float, str, dict[str, str]]] = []
    for row in ddrs2_pins:
        term = row.get("term", "")
        lane = term_lane(term)
        if lane is None:
            continue
        if term.startswith("DATA_L"):
            mapped.append((float_or_zero(row.get("norm_top_cx", "")), f"ddrs2_data_l_o[{lane}]", row))
        elif term.startswith("DATA_H"):
            mapped.append((float_or_zero(row.get("norm_top_cx", "")), f"ddrs2_data_h_o[{lane}]", row))

    clk_rows = [row for row in ddrs2_pins if row.get("term", "") == "CLK_160M"]
    if clk_rows:
        # The macro exposes two CLK_160M pins. The core has one clock output, so
        # place it at the right/east clock pin and report both source pins in
        # the context for top-level review.
        clk_row = max(clk_rows, key=lambda row: float_or_zero(row.get("norm_top_cx", "")))
        mapped.append((float_or_zero(clk_row.get("norm_top_cx", "")), "ddrs2_clk_160m_o", clk_row))

    mapped.sort(key=lambda item: (item[0], item[1]))
    ports: list[str] = []
    assignments: dict[str, dict[str, str]] = {}
    target_y = die_height_um - (signal_pin_depth_um / 2.0)
    for x_abs, port, row in mapped:
        if port in assignments:
            continue
        target_x = x_abs - block_norm_llx
        ports.append(port)
        assignments[port] = {
            "target_x_um": f"{target_x:.3f}",
            "target_y_um": f"{target_y:.3f}",
            "source_inst": row.get("inst", ""),
            "source_term": row.get("term", ""),
            "source_x_um": f"{x_abs:.3f}",
            "source_y_um": f"{float_or_zero(row.get('norm_top_cy', '')):.3f}",
        }
    return ports, assignments, clk_rows


def write_pin_assignment_tcl(
    path: Path,
    assignments: dict[str, dict[str, str]],
    side: str,
    layer: str,
    width_um: float,
    depth_um: float,
) -> None:
    with path.open("w") as fh:
        fh.write("# Generated guided pin assignments for OOC north edge.\n")
        fh.write("set spadmic_ooc_pin_assignment_failures [list]\n")
        for port, assignment in assignments.items():
            fh.write(f"if {{[catch {{editPin -pin {tcl_quote(port)} -side {side} -layer {layer} ")
            fh.write(f"-assign {{{assignment['target_x_um']} {assignment['target_y_um']}}} ")
            fh.write(f"-pinWidth {width_um:.3f} -pinDepth {depth_um:.3f} -fixedPin 1}} err]}} {{\n")
            fh.write(f"  lappend spadmic_ooc_pin_assignment_failures [format {{%s:%s}} {tcl_quote(port)} $err]\n")
            fh.write("}\n")
        fh.write("if {[llength $spadmic_ooc_pin_assignment_failures] > 0} {\n")
        fh.write('  error "SPADMIC_OOC_PIN_ASSIGNMENT_FAILED $spadmic_ooc_pin_assignment_failures"\n')
        fh.write("}\n")


def write_ooc_config_tcl(path: Path, values: dict[str, str], pin_plan: dict[str, list[str]]) -> None:
    with path.open("w") as fh:
        fh.write("# Generated by TOP/pnr/scripts/gen_ooc_block_harden_plan.py\n")
        fh.write("namespace eval spadmic_ooc {\n")
        for key, value in values.items():
            fh.write(f"    variable {key} {tcl_quote(value)}\n")
        for side, ports in pin_plan.items():
            fh.write(f"    variable pins_{side.lower()} [list {tcl_list(ports)}]\n")
        fh.write("}\n")


def common_config_values(
    block: str,
    top_module: str,
    layout_dir: Path,
    pin_plan_csv: Path,
    core_width_um: str,
    core_height_um: str,
    *,
    target_utilization: str = "0.55",
    place_max_density: str = "0.65",
    core_margin_um: str = "10.0",
    signal_pin_spacing_um: str = "1.20",
    pg_pin_width_um: str = "17.92",
    pg_pin_depth_um: str = "2.24",
    pg_strap_width_um: str = "2.24",
    pg_strap_spacing_um: str = "2.24",
    pin_assignment_tcl: Path | None = None,
) -> dict[str, str]:
    values = {
        "block": block,
        "top_module": top_module,
        "layout_audit_dir": str(layout_dir),
        "pin_plan_csv": str(pin_plan_csv),
        "target_utilization": target_utilization,
        "place_max_density": place_max_density,
        "core_width_um": core_width_um,
        "core_height_um": core_height_um,
        "core_margin_um": core_margin_um,
        "stdcell_site": "core_jihd",
        "signal_bottom_layer": "MET1",
        "signal_top_layer": "MET3",
        "signal_bottom_layer_idx": "1",
        "signal_top_layer_idx": "3",
        "power_layer": "METTP",
        "pg_power_net": "VDD",
        "pg_ground_net": "VSS",
        "pg_power_pin": "VDD",
        "pg_ground_pin": "VSS",
        "pg_grid_um": "0.56",
        "signal_pin_width_um": "0.40",
        "signal_pin_depth_um": "0.80",
        "signal_pin_spacing_um": signal_pin_spacing_um,
        "pg_pin_width_um": pg_pin_width_um,
        "pg_pin_depth_um": pg_pin_depth_um,
        "pg_strap_width_um": pg_strap_width_um,
        "pg_strap_spacing_um": pg_strap_spacing_um,
        "enable_pg_sroute": "0",
    }
    if pin_assignment_tcl is not None:
        values["pin_assignment_tcl"] = str(pin_assignment_tcl)
    return values


def write_leaf_context(
    path: Path,
    *,
    title: str,
    layout_dir: Path,
    block: str,
    top_module: str,
    contents: str,
    core_target: str,
    pin_plan: dict[str, list[str]],
    instances: list[dict[str, str]],
    extra_lines: list[str] | None = None,
) -> None:
    counts = class_counts(instances)
    with path.open("w") as fh:
        fh.write(f"# {title} OOC Hardening Context\n\n")
        fh.write("This context was generated from the read-only SPADMIC2 layout audit. The block is hardened as a local abstract; final absolute placement remains a top/assembly decision.\n\n")
        fh.write(f"- Layout audit dir: `{layout_dir}`\n")
        fh.write(f"- Block: `{block}`\n")
        fh.write(f"- Top module: `{top_module}`\n")
        fh.write(f"- Contents: {contents}\n")
        fh.write(f"- Local core target: `{core_target}`\n")
        fh.write("- Ordinary signal routing: `MET1`-`MET3`\n")
        fh.write("- Power access: one north `VDD` bar and one north `VSS` bar on `METTP`\n")
        fh.write("- Local special PG route is disabled by default; top-level assembly must connect the exported `METTP` VDD/VSS access pins.\n")
        for line in extra_lines or []:
            fh.write(f"- {line}\n")
        fh.write("\n## Instance Classes\n\n")
        for cls, count in sorted(counts.items()):
            fh.write(f"- `{cls}`: {count}\n")
        fh.write("\n## Pin Plan\n\n")
        for side, ports in pin_plan.items():
            fh.write(f"- `{side}`: {len(ports)} pins\n")


def generate_event_bundle_tx(layout_dir: Path, out_dir: Path) -> None:
    csv_dir = layout_dir / "csv"
    instances_csv = csv_dir / "SPADMIC2_instances_enriched.csv"
    nets_csv = csv_dir / "SPADMIC2_nets.csv"
    for path in [instances_csv, nets_csv]:
        require_file(path)

    instances = read_headered_csv(instances_csv)
    pin_plan = {
        "WEST": [
            "clk_sys",
            "rst_n",
            "bundle_start_i",
            *bus("event_id_i", 14),
            *bus("required_packet_mask_i", 4),
            *bus("source_pending_mask_i", 4),
            *bus("completed_packet_mask_o", 4),
            "done_o",
            "busy_o",
            "idle_o",
            "missing_source_error_o",
        ],
        "SOUTH": [
            *bus("src_valid_i", 4),
            *bus("src_ready_o", 4),
            *bus("src_sop_i", 4),
            *bus("src_eop_i", 4),
            *bus2("src_data_i", 4, 16),
        ],
        "NORTH": ["word_valid_o", "word_ready_i", "flush_o", *bus("word_data_o", 16)],
    }

    out_dir.mkdir(parents=True, exist_ok=True)
    config_tcl = out_dir / "ooc_block_harden_config.tcl"
    pin_plan_csv = out_dir / "ooc_block_pin_plan.csv"
    context_md = out_dir / "ooc_block_context.md"
    input_manifest = out_dir / "ooc_harden_input_manifest.csv"

    write_pin_plan_csv(pin_plan_csv, pin_plan)
    write_manifest(input_manifest, {"layout_audit_dir": layout_dir, "instances_enriched": instances_csv, "nets": nets_csv})
    values = common_config_values(
        "event_bundle_tx",
        "spadmic_event_bundle_tx",
        layout_dir,
        pin_plan_csv,
        "320.0",
        "220.0",
        target_utilization="0.58",
        place_max_density="0.66",
    )
    write_ooc_config_tcl(config_tcl, values, pin_plan)
    write_leaf_context(
        context_md,
        title="EVENT_BUNDLE_TX",
        layout_dir=layout_dir,
        block="event_bundle_tx",
        top_module="spadmic_event_bundle_tx",
        contents="`spadmic_event_bundle_tx`",
        core_target="320.0 um x 220.0 um",
        pin_plan=pin_plan,
        instances=instances,
        extra_lines=["Word/flush output pins are placed on the north edge toward the output FIFO leaf."],
    )


def generate_output_fifo(layout_dir: Path, out_dir: Path) -> None:
    csv_dir = layout_dir / "csv"
    instances_csv = csv_dir / "SPADMIC2_instances_enriched.csv"
    nets_csv = csv_dir / "SPADMIC2_nets.csv"
    for path in [instances_csv, nets_csv]:
        require_file(path)

    instances = read_headered_csv(instances_csv)
    pin_plan = {
        "WEST": [
            "clk_sys",
            "rst_n",
            *bus("level_o", 9),
            *bus("free_words_o", 9),
            "empty_o",
            "full_o",
            "almost_full_o",
            "overflow_o",
        ],
        "SOUTH": ["push_valid_i", "push_ready_o", *bus("push_data_i", 17)],
        "NORTH": ["pop_valid_o", "pop_ready_i", *bus("pop_data_o", 17)],
    }

    out_dir.mkdir(parents=True, exist_ok=True)
    config_tcl = out_dir / "ooc_block_harden_config.tcl"
    pin_plan_csv = out_dir / "ooc_block_pin_plan.csv"
    context_md = out_dir / "ooc_block_context.md"
    input_manifest = out_dir / "ooc_harden_input_manifest.csv"

    write_pin_plan_csv(pin_plan_csv, pin_plan)
    write_manifest(input_manifest, {"layout_audit_dir": layout_dir, "instances_enriched": instances_csv, "nets": nets_csv})
    values = common_config_values(
        "output_fifo",
        "spadmic_output_fifo_topcfg",
        layout_dir,
        pin_plan_csv,
        "720.0",
        "520.0",
        target_utilization="0.60",
        place_max_density="0.68",
    )
    write_ooc_config_tcl(config_tcl, values, pin_plan)
    write_leaf_context(
        context_md,
        title="OUTPUT_FIFO",
        layout_dir=layout_dir,
        block="output_fifo",
        top_module="spadmic_output_fifo_topcfg",
        contents="`spadmic_output_fifo_topcfg`",
        core_target="720.0 um x 520.0 um",
        pin_plan=pin_plan,
        instances=instances,
        extra_lines=["Push pins are placed south toward the event bundle leaf; pop pins are placed north toward the DDR16 pairer leaf."],
    )


def generate_ddrs2_adapter(layout_dir: Path, out_dir: Path) -> None:
    csv_dir = layout_dir / "csv"
    reports_dir = layout_dir / "reports"
    instances_csv = csv_dir / "SPADMIC2_instances_enriched.csv"
    instance_pins_csv = csv_dir / "SPADMIC2_instance_pins_enriched.csv"
    ddr_pins_csv = reports_dir / "SPADMIC2_ddr_slvs_pins.csv"
    nets_csv = csv_dir / "SPADMIC2_nets.csv"
    for path in [instances_csv, instance_pins_csv, ddr_pins_csv, nets_csv]:
        require_file(path)

    instances = read_headered_csv(instances_csv)
    instance_pins = read_pin_csv(instance_pins_csv)
    ddr_pins = [row for row in instance_pins if row.get("master_cell") == "DDRs2"]
    ddr_report_pins = read_pin_csv(ddr_pins_csv)
    ddrs2_inst = ddrs2_macro_instance(instances)

    data_clk_rows = [
        row for row in ddr_pins
        if row.get("term", "").startswith(("DATA_L", "DATA_H")) or row.get("term", "") == "CLK_160M"
    ]
    if not data_clk_rows:
        raise SystemExit("could not find DDRs2 DATA_L/DATA_H/CLK_160M pins in SPADMIC2_instance_pins_enriched.csv")

    tx_margin_left_um = 40.0
    tx_margin_right_default_um = 40.0
    tx_margin_right_min_um = 20.0
    tx_side_macro_clearance_um = 10.0
    core_margin_um = 8.0
    signal_pin_width_um = 0.40
    signal_pin_depth_um = 0.80
    data_x_min = min(float_or_zero(row.get("norm_top_cx", "")) for row in data_clk_rows)
    data_x_max = max(float_or_zero(row.get("norm_top_cx", "")) for row in data_clk_rows)
    side_macro_rows = [row for row in instances if row.get("cell") == "TXRX4TDC2"]
    side_macro_llx = min([float_or_zero(row.get("norm_llx", "")) for row in side_macro_rows] or [0.0])
    if side_macro_llx > data_x_max:
        available_right_margin = side_macro_llx - data_x_max - tx_side_macro_clearance_um
        tx_margin_right_um = max(
            tx_margin_right_min_um,
            min(tx_margin_right_default_um, available_right_margin),
        )
    else:
        tx_margin_right_um = tx_margin_right_default_um
    block_norm_llx = data_x_min - tx_margin_left_um
    block_norm_urx = data_x_max + tx_margin_right_um
    die_width_um = block_norm_urx - block_norm_llx
    core_width_um = die_width_um - (2.0 * core_margin_um)
    core_height_um = 30.0
    die_height_um = core_height_um + (2.0 * core_margin_um)

    north_ports, north_assignments, clk_rows = tx_egress_core_north_assignments(
        ddr_pins,
        block_norm_llx,
        die_height_um,
        signal_pin_depth_um,
    )
    pin_plan = {
        "WEST": ["clk_160m_i", "rst_n", "enable_i"],
        "SOUTH": [*bus("ddr_data_l_i", 16), *bus("ddr_data_h_i", 16), "ddr_pair_valid_i"],
        "NORTH": north_ports,
    }

    out_dir.mkdir(parents=True, exist_ok=True)
    config_tcl = out_dir / "ooc_block_harden_config.tcl"
    pin_plan_csv = out_dir / "ooc_block_pin_plan.csv"
    pin_assignment_tcl = out_dir / "ooc_block_pin_assignments.tcl"
    context_md = out_dir / "ooc_block_context.md"
    input_manifest = out_dir / "ooc_harden_input_manifest.csv"

    write_pin_plan_csv(pin_plan_csv, pin_plan, north_assignments)
    write_pin_assignment_tcl(pin_assignment_tcl, north_assignments, "NORTH", "MET3", signal_pin_width_um, signal_pin_depth_um)
    write_manifest(
        input_manifest,
        {
            "layout_audit_dir": layout_dir,
            "instances_enriched": instances_csv,
            "instance_pins_enriched": instance_pins_csv,
            "ddr_slvs_pins": ddr_pins_csv,
            "nets": nets_csv,
        },
    )
    values = common_config_values(
        "ddrs2_adapter",
        "spadmic_ddrs2_adapter",
        layout_dir,
        pin_plan_csv,
        f"{core_width_um:.3f}",
        f"{core_height_um:.3f}",
        target_utilization="0.20",
        place_max_density="0.40",
        core_margin_um=f"{core_margin_um:.3f}",
        signal_pin_spacing_um="1.40",
        pg_pin_width_um="60.48",
        pg_pin_depth_um="3.92",
        pg_strap_width_um="4.48",
        pg_strap_spacing_um="4.48",
        pin_assignment_tcl=pin_assignment_tcl,
    )
    values.update({
        "allow_cts_skip": "1",
        "prelim_top_bbox_llx_um": f"{block_norm_llx:.3f}",
        "prelim_top_bbox_urx_um": f"{block_norm_urx:.3f}",
        "ddrs2_data_pin_x_min_um": f"{data_x_min:.3f}",
        "ddrs2_data_pin_x_max_um": f"{data_x_max:.3f}",
        "ddrs2_margin_left_um": f"{tx_margin_left_um:.3f}",
        "ddrs2_margin_right_um": f"{tx_margin_right_um:.3f}",
        "txrx4tdc2_clearance_x_um": f"{(side_macro_llx - block_norm_urx) if side_macro_llx > 0.0 else 0.0:.3f}",
    })
    write_ooc_config_tcl(config_tcl, values, pin_plan)

    ddr_data_pin_count = sum(1 for row in ddr_pins if row.get("term", "").startswith(("DATA_L", "DATA_H")))
    north_pin_count = sum(1 for row in ddr_report_pins if row.get("nearest_inst_side", "") == "TOP")
    write_leaf_context(
        context_md,
        title="DDRS2_ADAPTER",
        layout_dir=layout_dir,
        block="ddrs2_adapter",
        top_module="spadmic_ddrs2_adapter",
        contents="`spadmic_ddrs2_adapter`",
        core_target=f"{core_width_um:.3f} um x {core_height_um:.3f} um",
        pin_plan=pin_plan,
        instances=instances,
        extra_lines=[
            "This is intentionally a wide, shallow pin-alignment bridge under the DDRs2 macro.",
            f"DDRs2 macro `{ddrs2_inst.get('inst')}` bbox=({float_or_zero(ddrs2_inst.get('norm_llx', '')):.3f}, {float_or_zero(ddrs2_inst.get('norm_lly', '')):.3f})-({float_or_zero(ddrs2_inst.get('norm_urx', '')):.3f}, {float_or_zero(ddrs2_inst.get('norm_ury', '')):.3f}) um",
            f"DDRs2 DATA/CLK span: x=({data_x_min:.3f}, {data_x_max:.3f}) um, span={data_x_max - data_x_min:.3f} um",
            f"DDR/SLVS audit pins read: `{len(ddr_pins)}` total, `{ddr_data_pin_count}` DATA_L/DATA_H pins, `{north_pin_count}` top-side pins",
            f"Visible DDRs2 CLK_160M source pins: `{len(clk_rows)}`; the single adapter clock pin is assigned to the right/east CLK_160M coordinate",
        ],
    )


def generate_ddr16_pairer(layout_dir: Path, out_dir: Path) -> None:
    csv_dir = layout_dir / "csv"
    reports_dir = layout_dir / "reports"
    instances_csv = csv_dir / "SPADMIC2_instances_enriched.csv"
    ddr_pins_csv = reports_dir / "SPADMIC2_ddr_slvs_pins.csv"
    mptdc_pins_csv = reports_dir / "SPADMIC2_mptdc_pins.csv"
    nets_csv = csv_dir / "SPADMIC2_nets.csv"
    for path in [instances_csv, ddr_pins_csv, mptdc_pins_csv, nets_csv]:
        require_file(path)

    instances = read_headered_csv(instances_csv)
    ddr_pins = read_pin_csv(ddr_pins_csv)
    mptdc_pins = read_pin_csv(mptdc_pins_csv)
    counts = class_counts(instances)

    pin_plan = {
        "WEST": ["clk_sys", "rst_n"],
        "SOUTH": ["word_valid_i", "flush_i", *bus("word_data_i", 16), "word_ready_o", "busy_o", "empty_o"],
        "NORTH": [
            "ddr_clk_o",
            "ddr_pair_valid_o",
            "ddr_padded_o",
            *bus("ddr_data_l_o", 16),
            *bus("ddr_data_h_o", 16),
        ],
    }

    out_dir.mkdir(parents=True, exist_ok=True)
    config_tcl = out_dir / "ooc_block_harden_config.tcl"
    pin_plan_csv = out_dir / "ooc_block_pin_plan.csv"
    context_md = out_dir / "ooc_block_context.md"
    input_manifest = out_dir / "ooc_harden_input_manifest.csv"

    write_pin_plan_csv(pin_plan_csv, pin_plan)
    write_manifest(
        input_manifest,
        {
            "layout_audit_dir": layout_dir,
            "instances_enriched": instances_csv,
            "ddr_slvs_pins": ddr_pins_csv,
            "mptdc_pins": mptdc_pins_csv,
            "nets": nets_csv,
        },
    )

    with config_tcl.open("w") as fh:
        fh.write("# Generated by TOP/pnr/scripts/gen_ooc_block_harden_plan.py\n")
        fh.write("namespace eval spadmic_ooc {\n")
        values = {
            "block": "ddr16_pairer",
            "top_module": "spadmic_ddr16_tx_pairer",
            "layout_audit_dir": str(layout_dir),
            "pin_plan_csv": str(pin_plan_csv),
            "target_utilization": "0.55",
            "place_max_density": "0.65",
            "core_width_um": "120.0",
            "core_height_um": "80.0",
            "core_margin_um": "10.0",
            "stdcell_site": "core_jihd",
            "signal_bottom_layer": "MET1",
            "signal_top_layer": "MET3",
            "signal_bottom_layer_idx": "1",
            "signal_top_layer_idx": "3",
            "power_layer": "METTP",
            "pg_power_net": "VDD",
            "pg_ground_net": "VSS",
            "pg_power_pin": "VDD",
            "pg_ground_pin": "VSS",
            "pg_grid_um": "0.56",
            "signal_pin_width_um": "0.40",
            "signal_pin_depth_um": "0.80",
            "signal_pin_spacing_um": "1.20",
            "pg_pin_width_um": "17.92",
            "pg_pin_depth_um": "2.24",
            "pg_strap_width_um": "2.24",
            "pg_strap_spacing_um": "2.24",
            "enable_pg_sroute": "0",
        }
        for key, value in values.items():
            fh.write(f"    variable {key} {tcl_quote(value)}\n")
        for side, ports in pin_plan.items():
            fh.write(f"    variable pins_{side.lower()} [list {tcl_list(ports)}]\n")
        fh.write("}\n")

    ddr_data_pin_count = sum(1 for row in ddr_pins if row.get("term", "").startswith(("DATA_L", "DATA_H")))
    ddr_bottom_pin_count = sum(1 for row in ddr_pins if row.get("nearest_inst_side", "") == "BOTTOM")
    with context_md.open("w") as fh:
        fh.write("# DDR16 Pairer OOC Hardening Context\n\n")
        fh.write("This context was generated from the read-only SPADMIC2 layout audit. The block is hardened as a local abstract, not at absolute top coordinates.\n\n")
        fh.write(f"- Layout audit dir: `{layout_dir}`\n")
        fh.write("- Block: `ddr16_pairer`\n")
        fh.write("- Top module: `spadmic_ddr16_tx_pairer`\n")
        fh.write("- Local core target: `120.0 um x 80.0 um`, `55%` utilization\n")
        fh.write("- Ordinary signal routing: `MET1`-`MET3`\n")
        fh.write("- Power access: one north `VDD` bar and one north `VSS` bar on `METTP`\n")
        fh.write("- Local special PG route is disabled by default; top-level assembly must connect the exported `METTP` VDD/VSS access pins.\n")
        fh.write(f"- DDR/SLVS audit pins read: `{len(ddr_pins)}` total, `{ddr_data_pin_count}` DATA_L/DATA_H pins, `{ddr_bottom_pin_count}` bottom-side pins\n")
        fh.write(f"- MPTDC audit pins read: `{len(mptdc_pins)}`; MPTDC placement is bbox/halo only until final abstracts exist\n\n")
        fh.write("## Instance Classes\n\n")
        for cls, count in sorted(counts.items()):
            fh.write(f"- `{cls}`: {count}\n")
        fh.write("\n## DDR/SLVS And MPTDC Anchors\n\n")
        for line in summarize_bbox(instances, "TX_RX_DDR_SLVS"):
            fh.write(f"{line}\n")
        for line in summarize_bbox(instances, "MPTDC"):
            fh.write(f"{line}\n")
        fh.write("\n## Pin Plan\n\n")
        for side, ports in pin_plan.items():
            fh.write(f"- `{side}`: {', '.join('`' + port + '`' for port in ports)}\n")


def generate_tx_egress_core(
    layout_dir: Path,
    out_dir: Path,
    *,
    block_name: str = "tx_egress_core",
    context_title: str = "TX_EGRESS_CORE",
) -> None:
    csv_dir = layout_dir / "csv"
    reports_dir = layout_dir / "reports"
    instances_csv = csv_dir / "SPADMIC2_instances_enriched.csv"
    instance_pins_csv = csv_dir / "SPADMIC2_instance_pins_enriched.csv"
    ddr_pins_csv = reports_dir / "SPADMIC2_ddr_slvs_pins.csv"
    matrix_pins_csv = reports_dir / "SPADMIC2_matrix_pins.csv"
    nets_csv = csv_dir / "SPADMIC2_nets.csv"
    for path in [instances_csv, instance_pins_csv, ddr_pins_csv, matrix_pins_csv, nets_csv]:
        require_file(path)

    instances = read_headered_csv(instances_csv)
    instance_pins = read_pin_csv(instance_pins_csv)
    ddr_pins = [row for row in instance_pins if row.get("master_cell") == "DDRs2"]
    ddr_report_pins = read_pin_csv(ddr_pins_csv)
    matrix_pins = read_pin_csv(matrix_pins_csv)
    counts = class_counts(instances)
    ddrs2_inst = ddrs2_macro_instance(instances)

    data_clk_rows = [
        row for row in ddr_pins
        if row.get("term", "").startswith(("DATA_L", "DATA_H")) or row.get("term", "") == "CLK_160M"
    ]
    if not data_clk_rows:
        raise SystemExit("could not find DDRs2 DATA_L/DATA_H/CLK_160M pins in SPADMIC2_instance_pins_enriched.csv")

    tx_margin_left_um = 40.0
    tx_margin_right_default_um = 40.0
    tx_margin_right_min_um = 20.0
    tx_side_macro_clearance_um = 10.0
    tx_channel_below_ddrs2_um = 30.0
    core_margin_um = 8.0
    target_utilization = 0.65
    place_max_density = 0.72
    signal_pin_width_um = 0.40
    signal_pin_depth_um = 0.80
    latest_genus_cell_area_um2 = 334245.0

    data_x_min = min(float_or_zero(row.get("norm_top_cx", "")) for row in data_clk_rows)
    data_x_max = max(float_or_zero(row.get("norm_top_cx", "")) for row in data_clk_rows)
    side_macro_rows = [row for row in instances if row.get("cell") == "TXRX4TDC2"]
    side_macro_llx = min([float_or_zero(row.get("norm_llx", "")) for row in side_macro_rows] or [0.0])
    if side_macro_llx > data_x_max:
        available_right_margin = side_macro_llx - data_x_max - tx_side_macro_clearance_um
        tx_margin_right_um = max(
            tx_margin_right_min_um,
            min(tx_margin_right_default_um, available_right_margin),
        )
    else:
        tx_margin_right_um = tx_margin_right_default_um
    block_norm_llx = data_x_min - tx_margin_left_um
    block_norm_urx = data_x_max + tx_margin_right_um
    die_width_um = block_norm_urx - block_norm_llx
    core_width_um = die_width_um - (2.0 * core_margin_um)
    estimated_core_height = latest_genus_cell_area_um2 / (target_utilization * core_width_um)
    core_height_um = math.ceil(max(150.0, estimated_core_height))
    die_height_um = core_height_um + (2.0 * core_margin_um)
    ddrs2_bottom_y = float_or_zero(ddrs2_inst.get("norm_lly", ""))
    block_norm_ury = ddrs2_bottom_y - tx_channel_below_ddrs2_um
    block_norm_lly = block_norm_ury - die_height_um
    mptdc_top_y = max(
        [float_or_zero(row.get("norm_ury", "")) for row in instances if row.get("class") == "MPTDC"] or [0.0]
    )
    matrix_array_top_y = max(
        [
            float_or_zero(row.get("norm_ury", ""))
            for row in instances
            if row.get("cell", "").lower().startswith("matrice")
        ] or [0.0]
    )
    side_macro_clearance_x = side_macro_llx - block_norm_urx if side_macro_llx > 0.0 else 0.0

    north_ports, north_assignments, clk_rows = tx_egress_core_north_assignments(
        ddr_pins,
        block_norm_llx,
        die_height_um,
        signal_pin_depth_um,
    )

    pin_plan = {
        "WEST": [
            "clk_sys",
            "clk_160m_i",
            "rst_n",
            "ddrs2_enable_i",
            "bundle_start_i",
            *bus("event_id_i", 14),
            *bus("required_packet_mask_i", 4),
            *bus("source_pending_mask_i", 4),
            *bus("completed_packet_mask_o", 4),
            "bundle_done_o",
            "bundle_busy_o",
            "bundle_idle_o",
            "bundle_missing_source_error_o",
            *bus("output_fifo_level_o", 9),
            *bus("output_fifo_free_words_o", 9),
            "output_fifo_empty_o",
            "output_fifo_full_o",
            "output_fifo_almost_full_o",
            "output_fifo_overflow_o",
            "ddr_pair_valid_o",
            "ddr_padded_o",
            "ddr_busy_o",
            "ddr_empty_o",
        ],
        "SOUTH": [
            *bus("src_valid_i", 4),
            *bus("src_ready_o", 4),
            *bus("src_sop_i", 4),
            *bus("src_eop_i", 4),
            *bus2("src_data_i", 4, 16),
        ],
        "NORTH": north_ports,
    }

    out_dir.mkdir(parents=True, exist_ok=True)
    config_tcl = out_dir / "ooc_block_harden_config.tcl"
    pin_plan_csv = out_dir / "ooc_block_pin_plan.csv"
    pin_assignment_tcl = out_dir / "ooc_block_pin_assignments.tcl"
    context_md = out_dir / "ooc_block_context.md"
    input_manifest = out_dir / "ooc_harden_input_manifest.csv"

    write_pin_plan_csv(pin_plan_csv, pin_plan, north_assignments)
    write_pin_assignment_tcl(
        pin_assignment_tcl,
        north_assignments,
        "NORTH",
        "MET3",
        signal_pin_width_um,
        signal_pin_depth_um,
    )
    write_manifest(
        input_manifest,
        {
            "layout_audit_dir": layout_dir,
            "instances_enriched": instances_csv,
            "instance_pins_enriched": instance_pins_csv,
            "ddr_slvs_pins": ddr_pins_csv,
            "matrix_pins": matrix_pins_csv,
            "nets": nets_csv,
        },
    )

    with config_tcl.open("w") as fh:
        fh.write("# Generated by TOP/pnr/scripts/gen_ooc_block_harden_plan.py\n")
        fh.write("namespace eval spadmic_ooc {\n")
        values = {
            "block": block_name,
            "top_module": "spadmic_tx_egress_core",
            "layout_audit_dir": str(layout_dir),
            "pin_plan_csv": str(pin_plan_csv),
            "pin_assignment_tcl": str(pin_assignment_tcl),
            "target_utilization": f"{target_utilization:.2f}",
            "place_max_density": f"{place_max_density:.2f}",
            "core_width_um": f"{core_width_um:.3f}",
            "core_height_um": f"{core_height_um:.3f}",
            "core_margin_um": f"{core_margin_um:.3f}",
            "prelim_top_bbox_llx_um": f"{block_norm_llx:.3f}",
            "prelim_top_bbox_lly_um": f"{block_norm_lly:.3f}",
            "prelim_top_bbox_urx_um": f"{block_norm_urx:.3f}",
            "prelim_top_bbox_ury_um": f"{block_norm_ury:.3f}",
            "ddrs2_data_pin_x_min_um": f"{data_x_min:.3f}",
            "ddrs2_data_pin_x_max_um": f"{data_x_max:.3f}",
            "ddrs2_margin_left_um": f"{tx_margin_left_um:.3f}",
            "ddrs2_margin_right_um": f"{tx_margin_right_um:.3f}",
            "txrx4tdc2_clearance_x_um": f"{side_macro_clearance_x:.3f}",
            "ddrs2_below_channel_um": f"{tx_channel_below_ddrs2_um:.3f}",
            "stdcell_site": "core_jihd",
            "signal_bottom_layer": "MET1",
            "signal_top_layer": "MET3",
            "signal_bottom_layer_idx": "1",
            "signal_top_layer_idx": "3",
            "power_layer": "METTP",
            "pg_power_net": "VDD",
            "pg_ground_net": "VSS",
            "pg_power_pin": "VDD",
            "pg_ground_pin": "VSS",
            "pg_grid_um": "0.56",
            "signal_pin_width_um": f"{signal_pin_width_um:.2f}",
            "signal_pin_depth_um": f"{signal_pin_depth_um:.2f}",
            "signal_pin_spacing_um": "1.40",
            "pg_pin_width_um": "60.48",
            "pg_pin_depth_um": "3.92",
            "pg_strap_width_um": "4.48",
            "pg_strap_spacing_um": "4.48",
            "enable_pg_sroute": "0",
        }
        for key, value in values.items():
            fh.write(f"    variable {key} {tcl_quote(value)}\n")
        for side, ports in pin_plan.items():
            fh.write(f"    variable pins_{side.lower()} [list {tcl_list(ports)}]\n")
        fh.write("}\n")

    ddr_data_pin_count = sum(1 for row in ddr_pins if row.get("term", "").startswith(("DATA_L", "DATA_H")))
    north_pin_count = sum(1 for row in ddr_report_pins if row.get("nearest_inst_side", "") == "TOP")
    with context_md.open("w") as fh:
        fh.write(f"# {context_title} OOC Hardening Context\n\n")
        fh.write("This context was generated from the read-only SPADMIC2 layout audit. The block is hardened as a local abstract and includes a preliminary top-coordinate placement bbox for review.\n\n")
        fh.write(f"- Layout audit dir: `{layout_dir}`\n")
        fh.write(f"- Block: `{block_name}`\n")
        fh.write("- Top module: `spadmic_tx_egress_core`\n")
        fh.write("- Contents: explicit leaf instances of `spadmic_event_bundle_tx`, `spadmic_output_fifo_topcfg`, `spadmic_ddr16_tx_pairer`, `spadmic_ddrs2_adapter`\n")
        fh.write(f"- DDRs2 macro: `{ddrs2_inst.get('inst')}` bbox=({float_or_zero(ddrs2_inst.get('norm_llx', '')):.3f}, {float_or_zero(ddrs2_inst.get('norm_lly', '')):.3f})-({float_or_zero(ddrs2_inst.get('norm_urx', '')):.3f}, {float_or_zero(ddrs2_inst.get('norm_ury', '')):.3f}) um\n")
        fh.write(f"- DDRs2 DATA/CLK span: x=({data_x_min:.3f}, {data_x_max:.3f}) um, span={data_x_max - data_x_min:.3f} um\n")
        fh.write(f"- Horizontal margin around DATA/CLK span: left `{tx_margin_left_um:.3f} um`, right `{tx_margin_right_um:.3f} um`\n")
        fh.write(f"- Preliminary top bbox: ({block_norm_llx:.3f}, {block_norm_lly:.3f})-({block_norm_urx:.3f}, {block_norm_ury:.3f}) um\n")
        fh.write(f"- Local core target: `{core_width_um:.3f} um x {core_height_um:.3f} um`, target util `{target_utilization:.2f}`, max place density `{place_max_density:.2f}`\n")
        fh.write(f"- Clearance estimate to MPTDC top bbox: `{block_norm_lly - mptdc_top_y:.3f} um`; matrix-array top clearance `{block_norm_lly - matrix_array_top_y:.3f} um`; TXRX4TDC2 east clearance `{side_macro_clearance_x:.3f} um`\n")
        fh.write("- Ordinary signal routing: `MET1`-`MET3`\n")
        fh.write("- Power access: one north `VDD` bar and one north `VSS` bar on `METTP`\n")
        fh.write("- Local special PG route is disabled by default; top-level assembly must connect the exported `METTP` VDD/VSS access pins.\n")
        fh.write("- Pin intent: source/event inputs south, controls/status west, DDRs2 digital egress north aligned to DDRs2 DATA/CLK pins\n")
        fh.write(f"- DDR/SLVS audit pins read: `{len(ddr_pins)}` total, `{ddr_data_pin_count}` DATA_L/DATA_H pins, `{north_pin_count}` top-side pins\n")
        fh.write(f"- Visible DDRs2 CLK_160M source pins: `{len(clk_rows)}`; the single cluster clock pin is assigned to the right/east CLK_160M coordinate\n")
        fh.write(f"- Matrix audit pins read: `{len(matrix_pins)}`; source-side pins remain top-level cluster pins until final top placement\n\n")
        fh.write("## Instance Classes\n\n")
        for cls, count in sorted(counts.items()):
            fh.write(f"- `{cls}`: {count}\n")
        fh.write("\n## DDR/SLVS Anchors\n\n")
        for line in summarize_bbox(instances, "TX_RX_DDR_SLVS"):
            fh.write(f"{line}\n")
        fh.write("\n## Pin Plan\n\n")
        for side, ports in pin_plan.items():
            fh.write(f"- `{side}`: {len(ports)} pins\n")
        fh.write("\n## North Pin Alignment\n\n")
        for port in north_ports:
            assignment = north_assignments[port]
            fh.write(
                f"- `{port}` local_x={assignment['target_x_um']} um "
                f"from `{assignment['source_inst']}/{assignment['source_term']}` "
                f"top_x={assignment['source_x_um']} um\n"
            )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("block")
    parser.add_argument("--layout-audit-dir", required=True, type=Path)
    parser.add_argument("--out-dir", required=True, type=Path)
    args = parser.parse_args()

    block = args.block.strip()
    if block in {"event_bundle_tx", "spadmic_event_bundle_tx"}:
        generate_event_bundle_tx(args.layout_audit_dir.resolve(), args.out_dir.resolve())
        return
    if block in {"output_fifo", "spadmic_output_fifo", "spadmic_output_fifo_topcfg"}:
        generate_output_fifo(args.layout_audit_dir.resolve(), args.out_dir.resolve())
        return
    if block in {"ddr16_pairer", "spadmic_ddr16_tx_pairer"}:
        generate_ddr16_pairer(args.layout_audit_dir.resolve(), args.out_dir.resolve())
        return
    if block in {"ddrs2_adapter", "spadmic_ddrs2_adapter"}:
        generate_ddrs2_adapter(args.layout_audit_dir.resolve(), args.out_dir.resolve())
        return
    if block in {"tx_egress_cluster", "tx_egress_core", "spadmic_tx_egress_cluster", "spadmic_tx_egress_core"}:
        generate_tx_egress_core(args.layout_audit_dir.resolve(), args.out_dir.resolve())
        return
    if block in {"tx_egress_assembly", "TX_EGRESS_ASSEMBLY"}:
        generate_tx_egress_core(
            args.layout_audit_dir.resolve(),
            args.out_dir.resolve(),
            block_name="tx_egress_assembly",
            context_title="TX_EGRESS_ASSEMBLY",
        )
        return
    raise SystemExit(f"unsupported hardening block for this generator: {args.block}")


if __name__ == "__main__":
    main()
