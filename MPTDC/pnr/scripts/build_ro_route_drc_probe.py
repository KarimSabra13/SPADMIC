#!/usr/bin/env python3
"""Build RO-local route DRC probe TSVs from Innovus marker and DEF reports.

The downstream ``audit_ro_marker_vs_lef.py`` script expects marker boxes that
are tied to a placed RO instance.  The standard route-gate reports already have
the raw marker TSV and the failed-route DEF; this helper joins them, filters to
geometry markers around the ``RO_tune6`` instances, and writes:

* ``ro_instance_boxes.tsv``
* ``ro_marker_to_inst_audit.tsv``
* ``ro_route_drc_probe_summary.txt``
"""

from __future__ import annotations

import argparse
import csv
import re
from collections import Counter
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


Box = tuple[float, float, float, float]


@dataclass(frozen=True)
class MacroInfo:
    name: str
    width: float
    height: float


@dataclass(frozen=True)
class Instance:
    inst: str
    macro: str
    def_orient: str
    inst_orient: str
    x: float
    y: float
    width: float
    height: float

    @property
    def box(self) -> Box:
        return (self.x, self.y, self.x + self.width, self.y + self.height)


def parse_box(text: object) -> Box | None:
    values = re.findall(r"[-+]?\d+(?:\.\d+)?", str(text or ""))
    if len(values) < 4:
        return None
    x1, y1, x2, y2 = (float(value) for value in values[:4])
    return (min(x1, x2), min(y1, y2), max(x1, x2), max(y1, y2))


def fmt_num(value: float) -> str:
    text = f"{value:.6f}".rstrip("0").rstrip(".")
    return text if text else "0"


def fmt_box(box: Box) -> str:
    return " ".join(fmt_num(value) for value in box)


def read_tsv(path: Path) -> list[dict[str, str]]:
    lines = [
        line
        for line in path.read_text(encoding="utf-8", errors="replace").splitlines()
        if line.strip() and not line.startswith("#")
    ]
    if not lines:
        return []
    return list(csv.DictReader(lines, delimiter="\t"))


def pick(row: dict[str, str], names: Iterable[str], default: str = "") -> str:
    for name in names:
        value = row.get(name, "")
        if value != "":
            return value
    return default


def overlap(a: Box, b: Box) -> bool:
    return not (a[2] <= b[0] or b[2] <= a[0] or a[3] <= b[1] or b[3] <= a[1])


def expand(box: Box, margin: float) -> Box:
    return (box[0] - margin, box[1] - margin, box[2] + margin, box[3] + margin)


def center(box: Box) -> tuple[float, float]:
    return ((box[0] + box[2]) / 2.0, (box[1] + box[3]) / 2.0)


def center_distance(a: Box, b: Box) -> float:
    ax, ay = center(a)
    bx, by = center(b)
    return ((ax - bx) ** 2 + (ay - by) ** 2) ** 0.5


def local_box(marker_box: Box, inst: Instance) -> Box:
    return (
        marker_box[0] - inst.x,
        marker_box[1] - inst.y,
        marker_box[2] - inst.x,
        marker_box[3] - inst.y,
    )


def def_to_audit_orient(orient: str) -> str:
    orient = orient.upper()
    return {
        "N": "R0",
        "R0": "R0",
        "S": "R180",
        "R180": "R180",
        "FN": "MY",
        "MY": "MY",
        "FS": "MX",
        "MX": "MX",
    }.get(orient, orient)


def parse_lef_macro_size(path: Path, macro_name: str) -> MacroInfo:
    in_prop = False
    in_macro = False
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
        match = re.match(r"SIZE\s+([-+0-9.]+)\s+BY\s+([-+0-9.]+)\s*;", line, re.IGNORECASE)
        if match:
            return MacroInfo(macro_name, float(match.group(1)), float(match.group(2)))
        if len(tokens) >= 2 and tokens[0].upper() == "END" and tokens[1].rstrip(";") == macro_name:
            break
    raise SystemExit(f"ERROR: could not parse SIZE for macro {macro_name} in {path}")


def parse_def_units(path: Path) -> int:
    match = re.search(
        r"UNITS\s+DISTANCE\s+MICRONS\s+([0-9]+)\s*;",
        path.read_text(encoding="utf-8", errors="replace"),
        re.IGNORECASE,
    )
    if not match:
        return 1000
    return int(match.group(1))


def parse_def_components(path: Path, macro: MacroInfo) -> list[Instance]:
    text = path.read_text(encoding="utf-8", errors="replace")
    dbu = parse_def_units(path)
    components_match = re.search(r"\bCOMPONENTS\b.*?\bEND\s+COMPONENTS\b", text, re.DOTALL | re.IGNORECASE)
    if not components_match:
        raise SystemExit(f"ERROR: could not find COMPONENTS section in {path}")
    components = components_match.group(0)
    instances: list[Instance] = []
    for statement in re.findall(r"-\s+.*?;", components, re.DOTALL):
        flat = " ".join(statement.split())
        match = re.match(r"-\s+(\S+)\s+(\S+)\s+", flat)
        if not match or match.group(2) != macro.name:
            continue
        placed = re.search(
            r"\+\s+(?:FIXED|PLACED|COVER)\s+\(\s*(-?\d+)\s+(-?\d+)\s*\)\s+(\S+)",
            flat,
            re.IGNORECASE,
        )
        if not placed:
            continue
        x = int(placed.group(1)) / dbu
        y = int(placed.group(2)) / dbu
        def_orient = placed.group(3).rstrip(";")
        audit_orient = def_to_audit_orient(def_orient)
        width = macro.width
        height = macro.height
        if audit_orient in {"R90", "R270", "E", "W", "FE", "FW"}:
            width, height = height, width
        instances.append(
            Instance(
                inst=match.group(1),
                macro=match.group(2),
                def_orient=def_orient,
                inst_orient=audit_orient,
                x=x,
                y=y,
                width=width,
                height=height,
            )
        )
    if not instances:
        raise SystemExit(f"ERROR: no {macro.name} components found in {path}")
    return instances


def inst_named_in_message(message: str, instances: dict[str, Instance]) -> Instance | None:
    match = re.search(r"Blockage\s+of\s+Cell\s+([^ ;]+)", message)
    if match and match.group(1) in instances:
        return instances[match.group(1)]
    for name, inst in instances.items():
        if name in message:
            return inst
    return None


def choose_instance(marker_box: Box, message: str, instances: list[Instance], margin: float) -> Instance | None:
    by_name = inst_named_in_message(message, {inst.inst: inst for inst in instances})
    if by_name is not None:
        return by_name
    candidates = [inst for inst in instances if overlap(marker_box, expand(inst.box, margin))]
    if not candidates:
        return None
    return min(candidates, key=lambda inst: center_distance(marker_box, inst.box))


def write_instances(path: Path, instances: list[Instance]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fields = ["inst", "macro", "def_orient", "inst_orient", "x", "y", "width", "height", "inst_box"]
    with path.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fields, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        for inst in instances:
            writer.writerow(
                {
                    "inst": inst.inst,
                    "macro": inst.macro,
                    "def_orient": inst.def_orient,
                    "inst_orient": inst.inst_orient,
                    "x": fmt_num(inst.x),
                    "y": fmt_num(inst.y),
                    "width": fmt_num(inst.width),
                    "height": fmt_num(inst.height),
                    "inst_box": fmt_box(inst.box),
                }
            )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--markers", required=True, type=Path, help="route_drc_markers.tsv")
    parser.add_argument("--def", dest="def_path", required=True, type=Path, help="failed-route DEF")
    parser.add_argument("--lef", required=True, type=Path, help="RO macro LEF used to get SIZE")
    parser.add_argument("--macro", default="RO_tune6")
    parser.add_argument("--out-dir", required=True, type=Path)
    parser.add_argument("--instance-margin-um", type=float, default=0.50)
    parser.add_argument("--include-connectivity", action="store_true")
    args = parser.parse_args()

    macro = parse_lef_macro_size(args.lef, args.macro)
    instances = parse_def_components(args.def_path, macro)
    rows = read_tsv(args.markers)

    args.out_dir.mkdir(parents=True, exist_ok=True)
    instance_tsv = args.out_dir / "ro_instance_boxes.tsv"
    marker_tsv = args.out_dir / "ro_marker_to_inst_audit.tsv"
    summary = args.out_dir / "ro_route_drc_probe_summary.txt"
    write_instances(instance_tsv, instances)

    fields = [
        "idx",
        "inst",
        "inst_orient",
        "marker_layer",
        "marker_box",
        "marker_local_box",
        "type",
        "subType",
        "message",
    ]
    counts: Counter[str] = Counter()
    selected = 0
    with marker_tsv.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fields, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        for row in rows:
            marker_type = pick(row, ["type", "marker_type"])
            if marker_type != "Geometry" and not args.include_connectivity:
                counts["skipped_non_geometry"] += 1
                continue
            marker_box = parse_box(pick(row, ["box", "marker_box", "abs_box", "absolute_box"]))
            if marker_box is None:
                counts["skipped_missing_box"] += 1
                continue
            message = pick(row, ["message", "msg", "marker_message"])
            inst = choose_instance(marker_box, message, instances, args.instance_margin_um)
            if inst is None:
                counts["skipped_not_near_ro"] += 1
                continue
            selected += 1
            layer = pick(row, ["layer", "marker_layer", "drc_layer"])
            subtype = pick(row, ["subType", "subtype", "marker_subtype"])
            counts[f"selected_by_inst {inst.inst}"] += 1
            counts[f"selected_by_layer {layer}"] += 1
            counts[f"selected_by_subtype {subtype}"] += 1
            writer.writerow(
                {
                    "idx": pick(row, ["idx", "marker_idx", "id"], str(selected)),
                    "inst": inst.inst,
                    "inst_orient": inst.inst_orient,
                    "marker_layer": layer,
                    "marker_box": fmt_box(marker_box),
                    "marker_local_box": fmt_box(local_box(marker_box, inst)),
                    "type": marker_type,
                    "subType": subtype,
                    "message": re.sub(r"[\t\r\n]+", " ", message),
                }
            )

    with summary.open("w", encoding="utf-8") as fh:
        fh.write("# RO Route DRC Probe Summary\n")
        fh.write(f"MARKERS={args.markers}\n")
        fh.write(f"DEF={args.def_path}\n")
        fh.write(f"LEF={args.lef}\n")
        fh.write(f"MACRO={args.macro}\n")
        fh.write(f"INSTANCE_COUNT={len(instances)}\n")
        fh.write(f"MARKER_ROWS_TOTAL={len(rows)}\n")
        fh.write(f"MARKER_ROWS_SELECTED={selected}\n")
        fh.write(f"INSTANCE_MARGIN_UM={args.instance_margin_um}\n")
        for inst in instances:
            fh.write(
                "INSTANCE "
                f"{inst.inst} macro={inst.macro} def_orient={inst.def_orient} "
                f"audit_orient={inst.inst_orient} box={fmt_box(inst.box)}\n"
            )
        for key, count in sorted(counts.items()):
            fh.write(f"COUNT {count} {key}\n")

    print(f"RO_INSTANCE_BOXES={instance_tsv}")
    print(f"RO_MARKER_TO_INST_AUDIT={marker_tsv}")
    print(f"RO_ROUTE_DRC_PROBE_SUMMARY={summary}")
    print(f"MARKER_ROWS_SELECTED={selected}")
    if selected == 0:
        raise SystemExit("ERROR: no RO-local geometry markers selected")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
