#!/usr/bin/env python3
"""Small LEF macro/pin parser for MPTDC macro-binding audits.

The parser intentionally ignores PROPERTYDEFINITIONS.  Cadence LEF often
contains lines such as `MACRO CatenaDesignType STRING ;` in that section; those
are property declarations, not physical macro blocks.
"""

from __future__ import annotations

import argparse
import csv
import json
import re
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Iterable


@dataclass
class LefPin:
    name: str
    direction: str = ""
    use: str = ""
    layers: list[str] = field(default_factory=list)
    rects: list[str] = field(default_factory=list)


@dataclass
class LefMacro:
    name: str
    size: tuple[float, float] | None = None
    origin: tuple[float, float] | None = None
    foreign: str = ""
    symmetry: list[str] = field(default_factory=list)
    pins: dict[str, LefPin] = field(default_factory=dict)
    has_obs: bool = False


def _strip_semicolon(token: str) -> str:
    return token.rstrip(";")


def _numbers(tokens: Iterable[str]) -> list[float]:
    vals: list[float] = []
    for token in tokens:
        token = token.rstrip(";")
        try:
            vals.append(float(token))
        except ValueError:
            pass
    return vals


def parse_lef_macros(path: str | Path) -> list[LefMacro]:
    macros: list[LefMacro] = []
    in_property_definitions = False
    current_macro: LefMacro | None = None
    current_pin: LefPin | None = None
    current_layer = ""
    in_obs = False

    for raw_line in Path(path).read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue

        upper = line.upper()
        tokens = line.split()
        if not tokens:
            continue

        if upper.startswith("PROPERTYDEFINITIONS"):
            in_property_definitions = True
            continue
        if in_property_definitions:
            if upper.startswith("END PROPERTYDEFINITIONS"):
                in_property_definitions = False
            continue

        if current_macro is None:
            # A real macro block starts with `MACRO <name>` outside property
            # definitions.  Property declarations have extra tokens and are
            # ignored above, but keep this strict for malformed files too.
            if len(tokens) == 2 and tokens[0].upper() == "MACRO":
                current_macro = LefMacro(name=_strip_semicolon(tokens[1]))
            continue

        if current_pin is None and not in_obs and tokens[0].upper() == "END":
            end_name = _strip_semicolon(tokens[1]) if len(tokens) > 1 else ""
            if not end_name or end_name == current_macro.name:
                macros.append(current_macro)
                current_macro = None
            continue

        if current_pin is None and tokens[0].upper() == "SIZE":
            vals = _numbers(tokens[1:])
            if len(vals) >= 2:
                current_macro.size = (vals[0], vals[1])
            continue

        if current_pin is None and tokens[0].upper() == "ORIGIN":
            vals = _numbers(tokens[1:])
            if len(vals) >= 2:
                current_macro.origin = (vals[0], vals[1])
            continue

        if current_pin is None and tokens[0].upper() == "FOREIGN":
            current_macro.foreign = " ".join(tokens[1:]).rstrip(";")
            continue

        if current_pin is None and tokens[0].upper() == "SYMMETRY":
            current_macro.symmetry = [_strip_semicolon(tok) for tok in tokens[1:]]
            continue

        if current_pin is None and tokens[0].upper() == "OBS":
            current_macro.has_obs = True
            in_obs = True
            continue

        if in_obs:
            if tokens[0].upper() == "END":
                in_obs = False
            continue

        if current_pin is None and len(tokens) >= 2 and tokens[0].upper() == "PIN":
            current_pin = LefPin(name=_strip_semicolon(tokens[1]))
            current_layer = ""
            continue

        if current_pin is not None:
            key = tokens[0].upper()
            if key == "DIRECTION" and len(tokens) >= 2:
                current_pin.direction = _strip_semicolon(tokens[1])
            elif key == "USE" and len(tokens) >= 2:
                current_pin.use = _strip_semicolon(tokens[1])
            elif key == "LAYER" and len(tokens) >= 2:
                current_layer = _strip_semicolon(tokens[1])
                current_pin.layers.append(current_layer)
            elif key == "RECT":
                rect = re.sub(r"^RECT\s+", "", line, flags=re.IGNORECASE).rstrip(";")
                current_pin.rects.append(f"{current_layer}:{rect}" if current_layer else rect)
            elif key == "END":
                end_name = _strip_semicolon(tokens[1]) if len(tokens) > 1 else ""
                if not end_name or end_name == current_pin.name:
                    current_macro.pins[current_pin.name] = current_pin
                    current_pin = None
                    current_layer = ""

    return macros


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("lef", help="LEF file to parse")
    parser.add_argument("--json", action="store_true", help="emit JSON")
    parser.add_argument("--pins-csv", help="write pin summary CSV")
    parser.add_argument("--summary", help="write text macro summary")
    args = parser.parse_args()

    macros = parse_lef_macros(args.lef)

    if args.pins_csv:
        with Path(args.pins_csv).open("w", newline="", encoding="utf-8") as fh:
            writer = csv.writer(fh)
            writer.writerow(["macro", "pin_name", "direction", "use", "layers", "rects"])
            for macro in macros:
                for pin in macro.pins.values():
                    writer.writerow([
                        macro.name,
                        pin.name,
                        pin.direction,
                        pin.use,
                        " ".join(pin.layers),
                        " | ".join(pin.rects),
                    ])

    if args.summary:
        with Path(args.summary).open("w", encoding="utf-8") as fh:
            for macro in macros:
                fh.write(f"MACRO {macro.name}\n")
                if macro.size is not None:
                    fh.write(f"SIZE {macro.size[0]} BY {macro.size[1]}\n")
                if macro.origin is not None:
                    fh.write(f"ORIGIN {macro.origin[0]} {macro.origin[1]}\n")
                if macro.foreign:
                    fh.write(f"FOREIGN {macro.foreign}\n")
                if macro.symmetry:
                    fh.write(f"SYMMETRY {' '.join(macro.symmetry)}\n")
                fh.write(f"PINS {len(macro.pins)}\n")
                fh.write(f"OBS {'yes' if macro.has_obs else 'no'}\n")

    if args.json:
        print(json.dumps([asdict(macro) for macro in macros], indent=2, sort_keys=True))
    elif not args.pins_csv and not args.summary:
        for macro in macros:
            print(macro.name)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
