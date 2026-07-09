#!/usr/bin/env python3
"""Generate a macro-only Verilog netlist for TX leaf assembly smoke import."""

from __future__ import annotations

import argparse
import csv
import re
from dataclasses import dataclass
from pathlib import Path


TOP_MODULE = "spadmic_tx_egress_leaf_assembly_smoke"


@dataclass(frozen=True)
class Macro:
    block: str
    top_module: str
    macro_name: str
    instance: str
    lef: Path
    width_um: str
    height_um: str
    pins: list[str]


def parse_lef(path: Path, fallback_macro: str) -> tuple[str, list[str]]:
    macro = fallback_macro
    pins: list[str] = []
    if not path.is_file():
        return macro, pins
    for raw in path.read_text(errors="replace").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        macro_match = re.match(r"^MACRO\s+(\S+)", line)
        if macro_match:
            macro = macro_match.group(1)
            continue
        pin_match = re.match(r"^PIN\s+(\S+)", line)
        if pin_match:
            pin = pin_match.group(1)
            if pin not in pins:
                pins.append(pin)
    return macro, pins


def verilog_ident(name: str) -> str:
    if re.match(r"^[A-Za-z_][A-Za-z0-9_$]*$", name):
        return name
    return "\\" + name + " "


def load_macros(plan_root: Path) -> list[Macro]:
    placements_csv = plan_root / "tx_egress_leaf_assembly_placements.csv"
    sources_csv = plan_root / "tx_egress_leaf_assembly_sources.csv"
    if not placements_csv.is_file():
        raise SystemExit(f"missing placement CSV: {placements_csv}")
    if not sources_csv.is_file():
        raise SystemExit(f"missing sources CSV: {sources_csv}")

    sources: dict[str, dict[str, str]] = {}
    with sources_csv.open(newline="") as fh:
        for row in csv.DictReader(fh):
            sources[row["block"]] = row

    macros: list[Macro] = []
    with placements_csv.open(newline="") as fh:
        for row in csv.DictReader(fh):
            block = row["block"]
            source = sources.get(block)
            if source is None:
                raise SystemExit(f"missing source row for block: {block}")
            macro_name, pins = parse_lef(Path(source["lef"]), row["top_module"])
            macros.append(
                Macro(
                    block=block,
                    top_module=row["top_module"],
                    macro_name=macro_name,
                    instance=row["primary_instance"],
                    lef=Path(source["lef"]),
                    width_um=row["width_um"],
                    height_um=row["height_um"],
                    pins=pins,
                )
            )
    return macros


def write_netlist(path: Path, macros: list[Macro]) -> None:
    with path.open("w") as fh:
        fh.write("// Auto-generated macro-only TX egress leaf assembly smoke netlist.\n")
        fh.write("// This is for Innovus import/placement validation only.\n")
        fh.write("// Leaf module ports are intentionally omitted: this smoke only proves\n")
        fh.write("// macro import, floorplan capacity, and fixed placement mechanics.\n\n")
        fh.write(f"module {TOP_MODULE} ();\n")
        for macro in macros:
            fh.write(f"  {verilog_ident(macro.macro_name)} {verilog_ident(macro.instance)} ();\n")
        fh.write("endmodule\n\n")

        for macro in macros:
            module_name = verilog_ident(macro.macro_name)
            fh.write(f"(* black_box *) module {module_name} ();\n")
            fh.write("endmodule\n\n")


def write_manifest(path: Path, macros: list[Macro]) -> None:
    with path.open("w", newline="") as fh:
        fieldnames = [
            "block",
            "top_module",
            "macro_name",
            "instance",
            "lef",
            "width_um",
            "height_um",
            "pin_count",
        ]
        writer = csv.DictWriter(fh, fieldnames=fieldnames)
        writer.writeheader()
        for macro in macros:
            writer.writerow(
                {
                    "block": macro.block,
                    "top_module": macro.top_module,
                    "macro_name": macro.macro_name,
                    "instance": macro.instance,
                    "lef": macro.lef,
                    "width_um": macro.width_um,
                    "height_um": macro.height_um,
                    "pin_count": len(macro.pins),
                }
            )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--plan-root", required=True, type=Path)
    parser.add_argument("--out-dir", required=True, type=Path)
    args = parser.parse_args()

    out_dir = args.out_dir.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    macros = load_macros(args.plan_root.resolve())
    netlist = out_dir / "tx_egress_leaf_assembly_smoke.v"
    manifest = out_dir / "tx_egress_leaf_assembly_smoke_manifest.csv"
    write_netlist(netlist, macros)
    write_manifest(manifest, macros)

    print(f"SMOKE_NETLIST={netlist}")
    print(f"SMOKE_MANIFEST={manifest}")
    print("SMOKE_NETLIST_RESULT=PASS")


if __name__ == "__main__":
    main()
