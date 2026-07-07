#!/usr/bin/env python3
"""Generate a protected PnR-only RO_tune6 LEF from the real abstract.

Unlike the coordinate proxy, this copy preserves the macro OBS so Innovus sees
the real RO internal-metal keepout contract.  It is still a generated PnR input,
not the golden analog source.
"""

from __future__ import annotations

import argparse
import re
from dataclasses import dataclass
from pathlib import Path


DEFAULT_DROP_PINS = {"vdd!"}
DEFAULT_METAL_LAYERS = {"MET1", "MET2", "MET3", "METTP"}
REQUIRED_PINS = {
    "rstb",
    "VDD",
    "VSS",
    *(f"code[{idx}]" for idx in range(8)),
    *(f"S[{idx}]" for idx in range(8)),
}


@dataclass(frozen=True)
class MacroCopy:
    body: list[str]
    source_pin_names: list[str]
    kept_pin_names: list[str]
    dropped_pin_names: list[str]
    obs_count: int
    obs_layers: list[str]


def find_macro_block(lines: list[str], macro: str) -> tuple[int, int]:
    start = -1
    for idx, line in enumerate(lines):
        if re.match(rf"^\s*MACRO\s+{re.escape(macro)}\s*$", line):
            start = idx
            break
    if start < 0:
        raise ValueError(f"MACRO {macro} not found")

    for idx in range(start + 1, len(lines)):
        if re.match(rf"^\s*END\s+{re.escape(macro)}\s*$", lines[idx]):
            return start, idx
    raise ValueError(f"END {macro} not found")


def source_header(lines: list[str], macro_start: int) -> list[str]:
    kept: list[str] = []
    in_units = False
    in_property_definitions = False
    for line in lines[:macro_start]:
        if re.match(r"^\s*PROPERTYDEFINITIONS\b", line, re.IGNORECASE):
            in_property_definitions = True
        if in_property_definitions:
            kept.append(line)
            if re.match(r"^\s*END\s+PROPERTYDEFINITIONS\b", line, re.IGNORECASE):
                in_property_definitions = False
            continue
        if re.match(r"^\s*UNITS\b", line, re.IGNORECASE):
            in_units = True
        if in_units:
            kept.append(line)
            if re.match(r"^\s*END\s+UNITS\b", line, re.IGNORECASE):
                in_units = False
            continue
        if re.match(r"^\s*(VERSION|BUSBITCHARS|DIVIDERCHAR)\b", line, re.IGNORECASE):
            kept.append(line)

    if not any(re.match(r"^\s*VERSION\b", line, re.IGNORECASE) for line in kept):
        kept.insert(0, "VERSION 5.8 ;")
    if not any(re.match(r"^\s*BUSBITCHARS\b", line, re.IGNORECASE) for line in kept):
        kept.append('BUSBITCHARS "[]" ;')
    if not any(re.match(r"^\s*DIVIDERCHAR\b", line, re.IGNORECASE) for line in kept):
        kept.append('DIVIDERCHAR "/" ;')
    if not any(re.match(r"^\s*UNITS\b", line, re.IGNORECASE) for line in kept):
        kept.extend(["UNITS", "  DATABASE MICRONS 1000 ;", "END UNITS"])
    return kept


def collect_layer_names(block: list[str]) -> list[str]:
    layers: list[str] = []
    seen: set[str] = set()
    for line in block:
        match = re.match(r"^\s*LAYER\s+([^ ;]+)\b", line, re.IGNORECASE)
        if not match:
            continue
        layer = match.group(1)
        key = layer.upper()
        if key not in seen:
            layers.append(layer)
            seen.add(key)
    return layers


def copy_macro(lines: list[str], macro: str, drop_pins: set[str]) -> MacroCopy:
    start, end = find_macro_block(lines, macro)
    body = lines[start + 1 : end]
    copied: list[str] = []
    source_pin_names: list[str] = []
    kept_pin_names: list[str] = []
    dropped_pin_names: list[str] = []
    obs_layers: list[str] = []
    obs_seen: set[str] = set()
    obs_count = 0
    idx = 0

    while idx < len(body):
        line = body[idx]
        pin_match = re.match(r"^(\s*)PIN\s+([^ ;]+)\s*$", line)
        if pin_match:
            pin_name = pin_match.group(2)
            source_pin_names.append(pin_name)
            block = [line]
            idx += 1
            while idx < len(body):
                block.append(body[idx])
                if re.match(rf"^\s*END\s+{re.escape(pin_name)}\s*$", body[idx]):
                    break
                idx += 1
            else:
                raise ValueError(f"PIN {pin_name} has no END")

            if pin_name in drop_pins:
                dropped_pin_names.append(pin_name)
            else:
                copied.extend(block)
                kept_pin_names.append(pin_name)
            idx += 1
            continue

        if re.match(r"^\s*OBS\s*$", line):
            block = [line]
            idx += 1
            while idx < len(body):
                block.append(body[idx])
                if re.match(r"^\s*END\s*$", body[idx]):
                    break
                idx += 1
            else:
                raise ValueError("OBS has no END")

            obs_count += 1
            for layer in collect_layer_names(block):
                key = layer.upper()
                if key not in obs_seen:
                    obs_layers.append(layer)
                    obs_seen.add(key)
            copied.extend(block)
            idx += 1
            continue

        copied.append(line)
        idx += 1

    return MacroCopy(
        body=copied,
        source_pin_names=source_pin_names,
        kept_pin_names=kept_pin_names,
        dropped_pin_names=dropped_pin_names,
        obs_count=obs_count,
        obs_layers=obs_layers,
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-lef", required=True, type=Path, help="Real RO_tune6 LEF source.")
    parser.add_argument("--out-lef", required=True, type=Path, help="Protected PnR LEF output path.")
    parser.add_argument("--summary", type=Path, help="Optional status summary path.")
    parser.add_argument("--macro", default="RO_tune6", help="Macro name to preserve.")
    parser.add_argument(
        "--drop-pin",
        action="append",
        default=[],
        help="Pin to omit from the generated PnR LEF. May be repeated. Defaults include vdd!.",
    )
    parser.add_argument(
        "--require-metal-obs",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="Require at least one OBS on a routing metal layer.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    source = args.source_lef.resolve()
    out = args.out_lef.resolve()
    summary_path = args.summary.resolve() if args.summary else out.with_suffix(".summary.rpt")
    drop_pins = set(DEFAULT_DROP_PINS)
    drop_pins.update(args.drop_pin)

    lines = source.read_text(encoding="utf-8", errors="replace").splitlines()
    macro_start, _ = find_macro_block(lines, args.macro)
    macro = copy_macro(lines, args.macro, drop_pins)

    missing = sorted(REQUIRED_PINS - set(macro.kept_pin_names))
    if missing:
        raise SystemExit(f"ERROR: protected LEF would miss required pins: {', '.join(missing)}")

    metal_obs_layers = sorted({layer.upper() for layer in macro.obs_layers} & DEFAULT_METAL_LAYERS)
    if args.require_metal_obs and not metal_obs_layers:
        raise SystemExit("ERROR: protected LEF has no OBS on required routing metal layers")

    output: list[str] = []
    output.extend(source_header(lines, macro_start))
    output.append("")
    output.append(f"# Protected PnR-only RO_tune6 LEF generated from {source}")
    output.append("# Macro geometry, pins, and OBS are preserved except explicitly dropped pins.")
    output.append("# This generated file is for Innovus routing only; it is not golden analog source.")
    output.append(f"MACRO {args.macro}")
    output.extend(macro.body)
    output.append(f"END {args.macro}")
    output.append("")
    output.append("END LIBRARY")
    output.append("")

    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text("\n".join(output), encoding="utf-8")

    summary = [
        "# MPTDC Protected RO PnR LEF",
        "PROXY_KIND=PROTECTED_PNR_REAL_OBS",
        f"SOURCE_LEF={source}",
        f"OUTPUT_LEF={out}",
        f"MACRO={args.macro}",
        f"PINS_SOURCE={len(macro.source_pin_names)}",
        f"PINS_KEPT={len(macro.kept_pin_names)}",
        f"PIN_NAMES_KEPT={' '.join(macro.kept_pin_names)}",
        f"PINS_DROPPED={' '.join(macro.dropped_pin_names) if macro.dropped_pin_names else 'NONE'}",
        f"OBS_COPIED={'YES' if macro.obs_count else 'NO'}",
        f"OBS_COUNT={macro.obs_count}",
        f"OBS_LAYERS={' '.join(macro.obs_layers) if macro.obs_layers else 'NONE'}",
        f"METAL_OBS_LAYERS={' '.join(metal_obs_layers) if metal_obs_layers else 'NONE'}",
        "SIGNOFF_BOUNDARY=PNR_INPUT_ONLY_NOT_FINAL_LAYOUT_SIGNOFF",
    ]
    summary_path.parent.mkdir(parents=True, exist_ok=True)
    summary_path.write_text("\n".join(summary) + "\n", encoding="utf-8")

    print(f"RO_PROTECTED_PNR_LEF={out}")
    print(f"RO_PROTECTED_PNR_SUMMARY={summary_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
