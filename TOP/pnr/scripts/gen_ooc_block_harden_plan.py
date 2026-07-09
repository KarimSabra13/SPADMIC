#!/usr/bin/env python3
"""Generate local OOC hardening collateral from the SPADMIC2 layout audit.

The generator intentionally emits a conservative local abstract plan. It uses
the audited top-layout CSVs for context, but does not place the block in
absolute top coordinates. Absolute placement remains a later top-assembly step.
"""

from __future__ import annotations

import argparse
import csv
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


def write_pin_plan_csv(path: Path, plan: dict[str, list[str]]) -> None:
    with path.open("w", newline="") as fh:
        writer = csv.writer(fh)
        writer.writerow(["port", "side", "layer", "order", "reason"])
        for side, ports in plan.items():
            for order, port in enumerate(ports):
                if side == "NORTH":
                    reason = "toward DDR16/DDRs2 output path"
                elif side == "SOUTH":
                    reason = "toward FIFO/event-bundle producer"
                else:
                    reason = "clock/reset/control entry"
                writer.writerow([port, side, "MET3", order, reason])


def write_manifest(path: Path, files: dict[str, Path]) -> None:
    with path.open("w", newline="") as fh:
        writer = csv.writer(fh)
        writer.writerow(["name", "path"])
        for name, file_path in files.items():
            writer.writerow([name, str(file_path)])


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
            "signal_pin_width_um": "0.40",
            "signal_pin_depth_um": "0.80",
            "signal_pin_spacing_um": "1.20",
            "pg_pin_width_um": "18.0",
            "pg_pin_depth_um": "2.0",
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


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("block")
    parser.add_argument("--layout-audit-dir", required=True, type=Path)
    parser.add_argument("--out-dir", required=True, type=Path)
    args = parser.parse_args()

    block = args.block.strip()
    if block not in {"ddr16_pairer", "spadmic_ddr16_tx_pairer"}:
        raise SystemExit(f"unsupported hardening block for this generator: {args.block}")
    generate_ddr16_pairer(args.layout_audit_dir.resolve(), args.out_dir.resolve())


if __name__ == "__main__":
    main()
