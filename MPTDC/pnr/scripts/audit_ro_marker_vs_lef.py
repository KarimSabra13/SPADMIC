#!/usr/bin/env python3
"""Compare RO route DRC markers against the RO_tune6 LEF abstract.

The marker probe reports boxes relative to the placed macro bounding box.  The
RO_tune6 LEF uses a non-zero ORIGIN and negative pin coordinates, so the inverse
transform is not simply local+ORIGIN.  For R0 the LEF coordinate is
local-ORIGIN; mirrored orientations also invert the coordinate within the macro
SIZE before subtracting ORIGIN.
"""

from __future__ import annotations

import argparse
import csv
import math
import re
from collections import Counter
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


Box = tuple[float, float, float, float]


@dataclass(frozen=True)
class LefRect:
    section: str
    name: str
    layer: str
    box: Box


@dataclass
class LefMacro:
    name: str
    origin: tuple[float, float] = (0.0, 0.0)
    size: tuple[float, float] | None = None
    rects: list[LefRect] | None = None


def parse_box(text: object) -> Box | None:
    values = re.findall(r"[-+]?\d+(?:\.\d+)?", str(text or ""))
    if len(values) < 4:
        return None
    x1, y1, x2, y2 = (float(v) for v in values[:4])
    return (min(x1, x2), min(y1, y2), max(x1, x2), max(y1, y2))


def fmt_box(box: Box | None) -> str:
    if box is None:
        return ""
    return "{:.6f} {:.6f} {:.6f} {:.6f}".format(*box)


def overlap(a: Box, b: Box) -> bool:
    return not (a[2] <= b[0] or b[2] <= a[0] or a[3] <= b[1] or b[3] <= a[1])


def clearance(a: Box, b: Box) -> float:
    dx = 0.0
    if a[2] < b[0]:
        dx = b[0] - a[2]
    elif b[2] < a[0]:
        dx = a[0] - b[2]
    dy = 0.0
    if a[3] < b[1]:
        dy = b[1] - a[3]
    elif b[3] < a[1]:
        dy = a[1] - b[3]
    if dx == 0.0:
        return dy
    if dy == 0.0:
        return dx
    return math.hypot(dx, dy)


def pick(row: dict[str, str], names: Iterable[str], default: str = "") -> str:
    for name in names:
        if name in row and row[name] != "":
            return row[name]
    return default


def read_tsv(path: Path) -> list[dict[str, str]]:
    lines = [
        line for line in path.read_text(encoding="utf-8", errors="replace").splitlines()
        if line.strip() and not line.startswith("#")
    ]
    if not lines:
        return []
    return list(csv.DictReader(lines, delimiter="\t"))


def parse_lef_macro(path: Path, macro_name: str) -> LefMacro:
    in_prop = False
    in_macro = False
    in_obs = False
    pin = ""
    layer = ""
    macro = LefMacro(name=macro_name, rects=[])

    for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw.strip()
        if not line:
            continue
        upper = line.upper()
        tokens = line.split()
        if upper.startswith("PROPERTYDEFINITIONS"):
            in_prop = True
            continue
        if in_prop:
            if upper.startswith("END PROPERTYDEFINITIONS"):
                in_prop = False
            continue
        if not in_macro:
            if len(tokens) == 2 and tokens[0].upper() == "MACRO" and tokens[1] == macro_name:
                in_macro = True
            continue
        if pin == "" and not in_obs and tokens[0].upper() == "END":
            if len(tokens) < 2 or tokens[1].rstrip(";") == macro_name:
                break
        match = re.match(r"ORIGIN\s+([-+0-9.]+)\s+([-+0-9.]+)\s*;", line, re.IGNORECASE)
        if pin == "" and not in_obs and match:
            macro.origin = (float(match.group(1)), float(match.group(2)))
            continue
        match = re.match(r"SIZE\s+([-+0-9.]+)\s+BY\s+([-+0-9.]+)\s*;", line, re.IGNORECASE)
        if pin == "" and not in_obs and match:
            macro.size = (float(match.group(1)), float(match.group(2)))
            continue
        match = re.match(r"PIN\s+([^ ;]+)", line, re.IGNORECASE)
        if not in_obs and match:
            pin = match.group(1)
            layer = ""
            continue
        if pin and re.match(rf"END\s+{re.escape(pin)}\s*$", line):
            pin = ""
            layer = ""
            continue
        if pin == "" and upper == "OBS":
            in_obs = True
            layer = ""
            continue
        if in_obs and upper == "END":
            in_obs = False
            layer = ""
            continue
        match = re.match(r"LAYER\s+([^ ;]+)\s*;", line, re.IGNORECASE)
        if match:
            layer = match.group(1)
            continue
        match = re.match(
            r"RECT\s+([-+0-9.]+)\s+([-+0-9.]+)\s+([-+0-9.]+)\s+([-+0-9.]+)\s*;",
            line,
            re.IGNORECASE,
        )
        if match and layer:
            box = tuple(float(match.group(i)) for i in range(1, 5))
            name = pin if pin else "OBS"
            section = "PIN" if pin else "OBS"
            macro.rects.append(LefRect(section=section, name=name, layer=layer, box=box))  # type: ignore[arg-type]

    if macro.size is None:
        raise SystemExit(f"ERROR: could not parse SIZE for macro {macro_name} in {path}")
    return macro


def read_instance_map(path: Path | None) -> dict[str, dict[str, str]]:
    if path is None or not path.exists():
        return {}
    out: dict[str, dict[str, str]] = {}
    for row in read_tsv(path):
        inst = pick(row, ["inst", "instance", "inst_name", "name"])
        if inst:
            out[inst] = row
    return out


def local_to_lef(local: Box, orient: str, macro: LefMacro) -> tuple[Box, str]:
    assert macro.size is not None
    ox, oy = macro.origin
    w, h = macro.size
    x1, y1, x2, y2 = local
    orient = (orient or "R0").upper()
    warning = ""
    if orient == "R0":
        out = (x1 - ox, y1 - oy, x2 - ox, y2 - oy)
    elif orient == "MX":
        out = (x1 - ox, h - y2 - oy, x2 - ox, h - y1 - oy)
    elif orient == "MY":
        out = (w - x2 - ox, y1 - oy, w - x1 - ox, y2 - oy)
    elif orient == "R180":
        out = (w - x2 - ox, h - y2 - oy, w - x1 - ox, h - y1 - oy)
    else:
        out = (x1 - ox, y1 - oy, x2 - ox, y2 - oy)
        warning = f"unsupported_orientation:{orient}"
    return (min(out[0], out[2]), min(out[1], out[3]), max(out[0], out[2]), max(out[1], out[3])), warning


def marker_local_box(row: dict[str, str], inst_row: dict[str, str]) -> Box | None:
    local = parse_box(pick(row, ["local_box", "marker_local_box", "local"]))
    if local is not None:
        return local
    abs_box = parse_box(pick(row, ["marker_box", "box", "abs_box", "absolute_box"]))
    inst_box = parse_box(pick(inst_row, ["inst_box", "bbox", "box", "instance_box"]))
    if abs_box is None or inst_box is None:
        return None
    return (
        abs_box[0] - inst_box[0],
        abs_box[1] - inst_box[1],
        abs_box[2] - inst_box[0],
        abs_box[3] - inst_box[1],
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--markers", required=True, type=Path, help="RO marker-to-instance TSV")
    parser.add_argument("--instances", type=Path, help="RO instance box/orientation TSV")
    parser.add_argument("--lef", required=True, type=Path, help="RO_tune6 LEF")
    parser.add_argument("--macro", default="RO_tune6")
    parser.add_argument("--out-tsv", required=True, type=Path)
    parser.add_argument("--summary", required=True, type=Path)
    args = parser.parse_args()

    macro = parse_lef_macro(args.lef, args.macro)
    instance_map = read_instance_map(args.instances)
    rects = macro.rects or []
    pins = [rect for rect in rects if rect.section == "PIN"]
    obs = [rect for rect in rects if rect.section == "OBS"]
    rows = read_tsv(args.markers)
    args.out_tsv.parent.mkdir(parents=True, exist_ok=True)
    args.summary.parent.mkdir(parents=True, exist_ok=True)

    fieldnames = [
        "idx",
        "inst",
        "inst_orient",
        "marker_layer",
        "marker_local_box",
        "marker_lef_box",
        "overlapping_lef_pins_same_layer",
        "overlapping_obs_count_same_layer",
        "nearest_pin_same_layer",
        "nearest_pin_distance_um",
        "classification",
        "orientation_warning",
        "message",
    ]

    counts: Counter[str] = Counter()
    warnings: Counter[str] = Counter()
    total = 0
    with args.out_tsv.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=fieldnames, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        for row in rows:
            inst = pick(row, ["inst", "instance", "inst_name"])
            inst_row = instance_map.get(inst, {})
            orient = pick(row, ["inst_orient", "orient", "orientation"], pick(inst_row, ["inst_orient", "orient", "orientation"], "R0"))
            layer = pick(row, ["marker_layer", "layer", "drc_layer"])
            local = marker_local_box(row, inst_row)
            if local is None:
                warnings["missing_local_box"] += 1
                continue
            lef_box, orient_warning = local_to_lef(local, orient, macro)
            if orient_warning:
                warnings[orient_warning] += 1

            pin_hits = [rect for rect in pins if rect.layer == layer and overlap(lef_box, rect.box)]
            obs_hits = [rect for rect in obs if rect.layer == layer and overlap(lef_box, rect.box)]
            same_layer_pins = [rect for rect in pins if rect.layer == layer]
            nearest = ""
            nearest_dist = ""
            if same_layer_pins:
                near = min(same_layer_pins, key=lambda rect: clearance(lef_box, rect.box))
                dist = clearance(lef_box, near.box)
                nearest = f"{near.name}:{near.layer}:{fmt_box(near.box)}"
                nearest_dist = f"{dist:.6f}"

            if obs_hits and pin_hits:
                classification = "PIN_AND_OBS_OVERLAP"
            elif obs_hits:
                classification = "OBS_OVERLAP_NO_PIN"
            elif pin_hits:
                classification = "PIN_OVERLAP_NO_OBS"
            else:
                classification = "NO_OBS_OR_PIN_OVERLAP"

            total += 1
            counts[f"{orient}|{layer}|{classification}"] += 1
            writer.writerow({
                "idx": pick(row, ["idx", "marker_idx", "id"], str(total)),
                "inst": inst,
                "inst_orient": orient,
                "marker_layer": layer,
                "marker_local_box": fmt_box(local),
                "marker_lef_box": fmt_box(lef_box),
                "overlapping_lef_pins_same_layer": " | ".join(
                    f"{rect.name}:{rect.layer}:{fmt_box(rect.box)}" for rect in pin_hits
                ),
                "overlapping_obs_count_same_layer": str(len(obs_hits)),
                "nearest_pin_same_layer": nearest,
                "nearest_pin_distance_um": nearest_dist,
                "classification": classification,
                "orientation_warning": orient_warning,
                "message": re.sub(r"[\t\r\n]+", " ", pick(row, ["message", "msg", "marker_message"])),
            })

    with args.summary.open("w", encoding="utf-8") as fh:
        fh.write("# RO Marker vs LEF Oriented Audit Summary\n")
        fh.write(f"MARKERS={args.markers}\n")
        fh.write(f"INSTANCES={args.instances or ''}\n")
        fh.write(f"RO_LEF={args.lef}\n")
        fh.write(f"MACRO={macro.name}\n")
        fh.write(f"LEF_ORIGIN={macro.origin[0]} {macro.origin[1]}\n")
        fh.write(f"LEF_SIZE={macro.size[0]} {macro.size[1]}\n")
        fh.write(f"PIN_RECT_COUNT={len(pins)}\n")
        fh.write(f"OBS_RECT_COUNT={len(obs)}\n")
        fh.write(f"MARKER_ROWS_ANALYZED={total}\n")
        for key, value in sorted(counts.items()):
            fh.write(f"COUNT {value} {key}\n")
        for key, value in sorted(warnings.items()):
            fh.write(f"WARNING_COUNT {value} {key}\n")
        fh.write("\n")
        fh.write("INTERPRETATION_RULES:\n")
        fh.write("OBS_OVERLAP_NO_PIN means the abstract OBS blocks the marker region without a legal same-layer pin.\n")
        fh.write("PIN_AND_OBS_OVERLAP means a pin-access window may be covered by OBS and should be split or trimmed.\n")
        fh.write("NO_OBS_OR_PIN_OVERLAP means do not patch OBS blindly; use absolute geometry or local routing guidance next.\n")
        fh.write("PIN_OVERLAP_NO_OBS means the marker reaches a legal pin shape; investigate spacing/via/access rules next.\n")

    print(f"RO_MARKER_VS_LEF_TSV={args.out_tsv}")
    print(f"RO_MARKER_VS_LEF_SUMMARY={args.summary}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
