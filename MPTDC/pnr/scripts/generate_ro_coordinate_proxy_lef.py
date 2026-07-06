#!/usr/bin/env python3
"""Generate a coordinate/pin-contract RO_tune6 proxy LEF for digital PnR.

The proxy keeps the macro outline and exported digital/PG pin shapes but omits
internal OBS geometry.  It is only a digital route-planning contract; final
analog RO placement/integration must be checked with the real layout abstract
and physical verification.
"""

from __future__ import annotations

import argparse
import re
from dataclasses import dataclass
from pathlib import Path


DEFAULT_DROP_PINS = {"vdd!"}
REQUIRED_PINS = {"rstb", "VDD", "VSS", *(f"code[{idx}]" for idx in range(8)), *(f"S[{idx}]" for idx in range(8))}


@dataclass(frozen=True)
class MacroParts:
    header: list[str]
    pins: list[list[str]]
    pin_names: list[str]


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


def parse_macro(lines: list[str], macro: str, drop_pins: set[str]) -> MacroParts:
    start, end = find_macro_block(lines, macro)
    body = lines[start + 1 : end]
    header: list[str] = []
    pins: list[list[str]] = []
    pin_names: list[str] = []
    idx = 0

    while idx < len(body):
        line = body[idx]
        pin_match = re.match(r"^(\s*)PIN\s+([^ ;]+)\s*$", line)
        if pin_match:
            pin_name = pin_match.group(2)
            block = [line]
            idx += 1
            while idx < len(body):
                block.append(body[idx])
                if re.match(rf"^\s*END\s+{re.escape(pin_name)}\s*$", body[idx]):
                    break
                idx += 1
            else:
                raise ValueError(f"PIN {pin_name} has no END")

            if pin_name not in drop_pins:
                pins.append(block)
                pin_names.append(pin_name)
            idx += 1
            continue

        if re.match(r"^\s*OBS\s*$", line):
            idx += 1
            while idx < len(body):
                if re.match(r"^\s*END\s*$", body[idx]):
                    idx += 1
                    break
                idx += 1
            continue

        if not re.match(r"^\s*END\s+", line):
            header.append(line)
        idx += 1

    return MacroParts(header=header, pins=pins, pin_names=pin_names)


def source_header(lines: list[str], macro_start: int) -> list[str]:
    kept: list[str] = []
    allowed = (
        re.compile(r"^\s*VERSION\b", re.IGNORECASE),
        re.compile(r"^\s*BUSBITCHARS\b", re.IGNORECASE),
        re.compile(r"^\s*DIVIDERCHAR\b", re.IGNORECASE),
        re.compile(r"^\s*UNITS\b", re.IGNORECASE),
        re.compile(r"^\s*DATABASE\s+MICRONS\b", re.IGNORECASE),
        re.compile(r"^\s*END\s+UNITS\b", re.IGNORECASE),
    )
    in_units = False
    for line in lines[:macro_start]:
        if re.match(r"^\s*UNITS\b", line, re.IGNORECASE):
            in_units = True
        if in_units:
            kept.append(line)
            if re.match(r"^\s*END\s+UNITS\b", line, re.IGNORECASE):
                in_units = False
            continue
        if any(pattern.match(line) for pattern in allowed[:3]):
            kept.append(line)
    if not any(re.match(r"^\s*VERSION\b", line, re.IGNORECASE) for line in kept):
        kept.insert(0, "VERSION 5.8 ;")
    if not any(re.match(r"^\s*BUSBITCHARS\b", line, re.IGNORECASE) for line in kept):
        kept.append('BUSBITCHARS "[]" ;')
    if not any(re.match(r"^\s*DIVIDERCHAR\b", line, re.IGNORECASE) for line in kept):
        kept.append('DIVIDERCHAR "/" ;')
    return kept


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-lef", required=True, type=Path, help="Real RO_tune6 LEF source.")
    parser.add_argument("--out-lef", required=True, type=Path, help="Proxy LEF output path.")
    parser.add_argument("--summary", type=Path, help="Optional status summary path.")
    parser.add_argument("--macro", default="RO_tune6", help="Macro name to preserve.")
    parser.add_argument(
        "--drop-pin",
        action="append",
        default=[],
        help="Pin to omit from the proxy. May be repeated. Defaults include vdd!.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    source = args.source_lef.resolve()
    out = args.out_lef.resolve()
    drop_pins = set(DEFAULT_DROP_PINS)
    drop_pins.update(args.drop_pin)

    lines = source.read_text(encoding="utf-8", errors="replace").splitlines()
    macro_start, _ = find_macro_block(lines, args.macro)
    parts = parse_macro(lines, args.macro, drop_pins)
    found = set(parts.pin_names)
    missing = sorted(REQUIRED_PINS - found)
    if missing:
        raise SystemExit(f"ERROR: proxy would miss required pins: {', '.join(missing)}")

    output: list[str] = []
    output.extend(source_header(lines, macro_start))
    output.append("")
    output.append(f"# Coordinate proxy generated from {source}")
    output.append("# Digital PnR contract only: macro size/origin and pin shapes are preserved; OBS is omitted.")
    output.append("# Final RO layout placement, PG hookup, DRC, LVS, and extraction remain manual/signoff work.")
    output.append(f"MACRO {args.macro}")
    output.extend(parts.header)
    for pin_block in parts.pins:
        output.extend(pin_block)
    output.append(f"END {args.macro}")
    output.append("")
    output.append("END LIBRARY")
    output.append("")

    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text("\n".join(output), encoding="utf-8")

    summary_path = args.summary.resolve() if args.summary else out.with_suffix(".summary.rpt")
    dropped_present = sorted(set(re.findall(r"^\s*PIN\s+([^ ;]+)\s*$", "\n".join(lines), re.MULTILINE)) & drop_pins)
    summary = [
        "# MPTDC RO Coordinate Proxy LEF",
        "PROXY_KIND=COORDINATE_PIN_CONTRACT",
        f"SOURCE_LEF={source}",
        f"OUTPUT_LEF={out}",
        f"MACRO={args.macro}",
        f"PINS_KEPT={len(parts.pin_names)}",
        f"PIN_NAMES_KEPT={' '.join(parts.pin_names)}",
        f"PINS_DROPPED={' '.join(dropped_present) if dropped_present else 'NONE'}",
        "OBS_COPIED=0",
        "SIGNOFF_BOUNDARY=NOT_FINAL_RO_LAYOUT_SIGNOFF",
        "MANUAL_RO_INTEGRATION_REQUIRED=YES",
        "REAL_RO_LEF_RECHECK_REQUIRED=YES",
    ]
    summary_path.parent.mkdir(parents=True, exist_ok=True)
    summary_path.write_text("\n".join(summary) + "\n", encoding="utf-8")

    print(f"RO_COORDINATE_PROXY_LEF={out}")
    print(f"RO_COORDINATE_PROXY_SUMMARY={summary_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
