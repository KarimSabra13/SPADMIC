#!/usr/bin/env python3
"""Extract SPAD matrix macro geometry and pin locations from a LEF abstract.

The script is intentionally dependency-free so it can run on the lab server
even when only a basic Python install is available. It parses the LEF macro
SIZE, pin PORT shapes, and OBS shapes, then writes machine-readable tables plus
an SVG preview that is good enough for first-pass position-block floorplanning.
"""

from __future__ import annotations

import argparse
import csv
import json
import math
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable


NUMBER_RE = re.compile(r"[-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][-+]?\d+)?")
INDEX_RE = re.compile(r"(?:\[|<|_)(\d+)(?:\]|>|$)")


@dataclass
class Shape:
    kind: str
    layer: str
    x1: float
    y1: float
    x2: float
    y2: float
    source: str = ""
    polygon: list[tuple[float, float]] = field(default_factory=list)

    @property
    def cx(self) -> float:
        return (self.x1 + self.x2) / 2.0

    @property
    def cy(self) -> float:
        return (self.y1 + self.y2) / 2.0

    @property
    def width(self) -> float:
        return self.x2 - self.x1

    @property
    def height(self) -> float:
        return self.y2 - self.y1


@dataclass
class Pin:
    name: str
    direction: str = ""
    use: str = ""
    shape: str = ""
    shapes: list[Shape] = field(default_factory=list)


@dataclass
class Macro:
    name: str
    cls: str = ""
    origin: tuple[float, float] = (0.0, 0.0)
    size: tuple[float, float] | None = None
    symmetry: str = ""
    site: str = ""
    pins: dict[str, Pin] = field(default_factory=dict)
    obs: list[Shape] = field(default_factory=list)

    @property
    def width(self) -> float:
        if self.size is None:
            return 0.0
        return self.size[0]

    @property
    def height(self) -> float:
        if self.size is None:
            return 0.0
        return self.size[1]

    @property
    def boundary_x1(self) -> float:
        return -self.origin[0]

    @property
    def boundary_y1(self) -> float:
        return -self.origin[1]

    @property
    def boundary_x2(self) -> float:
        return self.width - self.origin[0]

    @property
    def boundary_y2(self) -> float:
        return self.height - self.origin[1]


def strip_comment(line: str) -> str:
    for marker in ("#", "//"):
        idx = line.find(marker)
        if idx >= 0:
            line = line[:idx]
    return line.strip()


def lef_statements(path: Path) -> Iterable[tuple[int, str]]:
    """Yield LEF statements and block markers with their starting line number."""
    buf: list[str] = []
    start_line = 0
    block_markers = {"MACRO", "PIN", "PORT", "OBS", "END"}
    with path.open("r", encoding="utf-8", errors="replace") as fh:
        for lineno, raw in enumerate(fh, 1):
            line = strip_comment(raw)
            if not line:
                continue
            first = line.split()[0].upper()
            if ";" not in line and not buf and first in block_markers:
                yield lineno, line
                continue
            if not buf:
                start_line = lineno
            buf.append(line)
            joined = " ".join(buf)
            while ";" in joined:
                before, after = joined.split(";", 1)
                if before.strip():
                    yield start_line, before.strip()
                joined = after.strip()
                start_line = lineno
            buf = [joined] if joined else []
    if buf and " ".join(buf).strip():
        yield start_line, " ".join(buf).strip()


def parse_float_list(text: str) -> list[float]:
    return [float(x) for x in NUMBER_RE.findall(text)]


def parse_lef(path: Path) -> dict[str, Macro]:
    macros: dict[str, Macro] = {}
    current_macro: Macro | None = None
    current_pin: Pin | None = None
    current_layer = ""
    in_obs = False

    for lineno, stmt in lef_statements(path):
        tokens = stmt.split()
        if not tokens:
            continue
        head = tokens[0].upper()

        if head == "MACRO" and len(tokens) >= 2:
            name = tokens[1]
            current_macro = Macro(name=name)
            macros[name] = current_macro
            current_pin = None
            in_obs = False
            current_layer = ""
            continue

        if current_macro is None:
            continue

        if head == "END":
            end_name = tokens[1] if len(tokens) > 1 else ""
            if in_obs and (not end_name or end_name.upper() == "OBS"):
                in_obs = False
                current_layer = ""
            elif current_pin is not None and (not end_name or end_name == current_pin.name):
                current_pin = None
                current_layer = ""
            elif end_name == current_macro.name:
                current_macro = None
                current_layer = ""
            continue

        if head == "CLASS" and len(tokens) >= 2:
            current_macro.cls = " ".join(tokens[1:])
            continue

        if head == "ORIGIN":
            nums = parse_float_list(stmt)
            if len(nums) >= 2:
                current_macro.origin = (nums[0], nums[1])
            continue

        if head == "SIZE":
            nums = parse_float_list(stmt)
            if len(nums) >= 2:
                current_macro.size = (nums[0], nums[1])
            continue

        if head == "SYMMETRY":
            current_macro.symmetry = " ".join(tokens[1:])
            continue

        if head == "SITE" and len(tokens) >= 2:
            current_macro.site = tokens[1]
            continue

        if head == "PIN" and len(tokens) >= 2:
            pin_name = " ".join(tokens[1:])
            current_pin = current_macro.pins.setdefault(pin_name, Pin(name=pin_name))
            current_layer = ""
            in_obs = False
            continue

        if head == "OBS":
            in_obs = True
            current_pin = None
            current_layer = ""
            continue

        if current_pin is not None:
            if head == "DIRECTION" and len(tokens) >= 2:
                current_pin.direction = tokens[1]
                continue
            if head == "USE" and len(tokens) >= 2:
                current_pin.use = tokens[1]
                continue
            if head == "SHAPE" and len(tokens) >= 2:
                current_pin.shape = " ".join(tokens[1:])
                continue
            if head == "PORT":
                current_layer = ""
                continue

        if (current_pin is not None or in_obs) and head == "LAYER" and len(tokens) >= 2:
            current_layer = tokens[1]
            continue

        if (current_pin is not None or in_obs) and head in {"RECT", "POLYGON"}:
            nums = parse_float_list(stmt)
            if head == "RECT" and len(nums) >= 4:
                shape = Shape(
                    kind="rect",
                    layer=current_layer,
                    x1=min(nums[0], nums[2]),
                    y1=min(nums[1], nums[3]),
                    x2=max(nums[0], nums[2]),
                    y2=max(nums[1], nums[3]),
                    source=f"{path.name}:{lineno}",
                )
            elif head == "POLYGON" and len(nums) >= 6 and len(nums) % 2 == 0:
                pts = list(zip(nums[0::2], nums[1::2]))
                xs = [p[0] for p in pts]
                ys = [p[1] for p in pts]
                shape = Shape(
                    kind="polygon",
                    layer=current_layer,
                    x1=min(xs),
                    y1=min(ys),
                    x2=max(xs),
                    y2=max(ys),
                    source=f"{path.name}:{lineno}",
                    polygon=pts,
                )
            else:
                continue
            if current_pin is not None:
                current_pin.shapes.append(shape)
            else:
                current_macro.obs.append(shape)

    return macros


def pin_bbox(pin: Pin) -> tuple[float, float, float, float] | None:
    if not pin.shapes:
        return None
    return (
        min(s.x1 for s in pin.shapes),
        min(s.y1 for s in pin.shapes),
        max(s.x2 for s in pin.shapes),
        max(s.y2 for s in pin.shapes),
    )


def guess_axis_index(pin_name: str) -> tuple[str, int | None]:
    name = pin_name.lower()
    axis = "other"
    if "rst" in name or "reset" in name:
        axis = "reset"
    elif re.search(r"(^|[^a-z])x(_?lines?|_?pos)?($|[^a-z])", name) or name.startswith("x"):
        axis = "x"
    elif re.search(r"(^|[^a-z])y(_?lines?|_?pos)?($|[^a-z])", name) or name.startswith("y"):
        axis = "y"
    elif re.search(r"(^|[^a-z])z(_?lines?|_?pos)?($|[^a-z])", name) or name.startswith("z"):
        axis = "z"

    idx_match = INDEX_RE.search(name)
    if not idx_match:
        trailing = re.search(r"(\d+)$", name)
        idx_match = trailing
    index = int(idx_match.group(1)) if idx_match else None
    return axis, index


def classify_side(macro: Macro, bbox: tuple[float, float, float, float], tolerance: float) -> tuple[str, float]:
    x1, y1, x2, y2 = bbox
    distances = {
        "LEFT": abs(x1 - macro.boundary_x1),
        "RIGHT": abs(macro.boundary_x2 - x2),
        "BOTTOM": abs(y1 - macro.boundary_y1),
        "TOP": abs(macro.boundary_y2 - y2),
    }
    side, dist = min(distances.items(), key=lambda kv: kv[1])
    if dist <= tolerance:
        return side, dist
    return f"INTERNAL_NEAREST_{side}", dist


def shape_to_dict(shape: Shape) -> dict[str, object]:
    return {
        "kind": shape.kind,
        "layer": shape.layer,
        "x1": shape.x1,
        "y1": shape.y1,
        "x2": shape.x2,
        "y2": shape.y2,
        "cx": shape.cx,
        "cy": shape.cy,
        "width": shape.width,
        "height": shape.height,
        "source": shape.source,
        "polygon": shape.polygon,
    }


def collect_pin_rows(macro: Macro, edge_tolerance: float) -> tuple[list[dict[str, object]], list[dict[str, object]]]:
    pin_summary: list[dict[str, object]] = []
    pin_rects: list[dict[str, object]] = []
    for pin in sorted(macro.pins.values(), key=lambda p: natural_sort_key(p.name)):
        bbox = pin_bbox(pin)
        axis, index = guess_axis_index(pin.name)
        if bbox is None:
            side = "NO_SHAPE"
            edge_dist = math.nan
            cx = cy = width = height = math.nan
            ll_x1 = ll_y1 = ll_x2 = ll_y2 = ll_cx = ll_cy = math.nan
        else:
            side, edge_dist = classify_side(macro, bbox, edge_tolerance)
            cx = (bbox[0] + bbox[2]) / 2.0
            cy = (bbox[1] + bbox[3]) / 2.0
            width = bbox[2] - bbox[0]
            height = bbox[3] - bbox[1]
            ll_x1 = bbox[0] - macro.boundary_x1
            ll_y1 = bbox[1] - macro.boundary_y1
            ll_x2 = bbox[2] - macro.boundary_x1
            ll_y2 = bbox[3] - macro.boundary_y1
            ll_cx = cx - macro.boundary_x1
            ll_cy = cy - macro.boundary_y1
        layers = sorted({s.layer for s in pin.shapes if s.layer})
        pin_summary.append(
            {
                "macro": macro.name,
                "pin": pin.name,
                "direction": pin.direction,
                "use": pin.use,
                "shape": pin.shape,
                "axis_guess": axis,
                "index_guess": "" if index is None else index,
                "layer_count": len(layers),
                "layers": "|".join(layers),
                "shape_count": len(pin.shapes),
                "bbox_x1": "" if bbox is None else bbox[0],
                "bbox_y1": "" if bbox is None else bbox[1],
                "bbox_x2": "" if bbox is None else bbox[2],
                "bbox_y2": "" if bbox is None else bbox[3],
                "center_x": cx,
                "center_y": cy,
                "ll_bbox_x1": ll_x1,
                "ll_bbox_y1": ll_y1,
                "ll_bbox_x2": ll_x2,
                "ll_bbox_y2": ll_y2,
                "ll_center_x": ll_cx,
                "ll_center_y": ll_cy,
                "width": width,
                "height": height,
                "side": side,
                "edge_distance": edge_dist,
            }
        )
        for shape_id, shape in enumerate(pin.shapes):
            ll_shape_x1 = shape.x1 - macro.boundary_x1
            ll_shape_y1 = shape.y1 - macro.boundary_y1
            ll_shape_x2 = shape.x2 - macro.boundary_x1
            ll_shape_y2 = shape.y2 - macro.boundary_y1
            pin_rects.append(
                {
                    "macro": macro.name,
                    "pin": pin.name,
                    "direction": pin.direction,
                    "use": pin.use,
                    "axis_guess": axis,
                    "index_guess": "" if index is None else index,
                    "shape_id": shape_id,
                    **shape_to_dict(shape),
                    "ll_x1": ll_shape_x1,
                    "ll_y1": ll_shape_y1,
                    "ll_x2": ll_shape_x2,
                    "ll_y2": ll_shape_y2,
                    "ll_cx": shape.cx - macro.boundary_x1,
                    "ll_cy": shape.cy - macro.boundary_y1,
                    "side": side,
                    "edge_distance": edge_dist,
                }
            )
    return pin_summary, pin_rects


def natural_sort_key(text: str) -> list[object]:
    parts = re.split(r"(\d+)", text)
    return [int(part) if part.isdigit() else part.lower() for part in parts]


def write_csv(path: Path, rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if not rows:
        path.write_text("", encoding="utf-8")
        return
    with path.open("w", encoding="utf-8", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)


def summarize(rows: list[dict[str, object]], key: str) -> dict[str, int]:
    out: dict[str, int] = {}
    for row in rows:
        value = str(row.get(key, "") or "UNKNOWN")
        out[value] = out.get(value, 0) + 1
    return dict(sorted(out.items(), key=lambda kv: kv[0]))


def missing_axis_indices(rows: list[dict[str, object]], axis: str, expected_count: int) -> list[int]:
    found = {
        int(row["index_guess"])
        for row in rows
        if row.get("axis_guess") == axis and str(row.get("index_guess", "")).isdigit()
    }
    return [idx for idx in range(expected_count) if idx not in found]


def write_json(path: Path, macro: Macro, pin_summary: list[dict[str, object]], pin_rects: list[dict[str, object]], edge_tolerance: float, expected_axis_count: int) -> None:
    payload = {
        "macro": {
            "name": macro.name,
            "class": macro.cls,
            "origin": macro.origin,
            "boundary_raw": {
                "x1": macro.boundary_x1,
                "y1": macro.boundary_y1,
                "x2": macro.boundary_x2,
                "y2": macro.boundary_y2,
            },
            "lower_left_normalized_boundary": {
                "x1": 0.0,
                "y1": 0.0,
                "x2": macro.width,
                "y2": macro.height,
            },
            "width": macro.width,
            "height": macro.height,
            "symmetry": macro.symmetry,
            "site": macro.site,
            "pin_count": len(macro.pins),
            "obs_shape_count": len(macro.obs),
        },
        "edge_tolerance": edge_tolerance,
        "pin_axis_counts": summarize(pin_summary, "axis_guess"),
        "pin_side_counts": summarize(pin_summary, "side"),
        "pin_layer_counts": summarize(pin_rects, "layer"),
        "missing_axis_indices": {
            axis: missing_axis_indices(pin_summary, axis, expected_axis_count)
            for axis in ("x", "y", "z")
        },
        "pins": pin_summary,
        "pin_shapes": pin_rects,
        "obstructions": [shape_to_dict(shape) for shape in macro.obs],
    }
    path.write_text(json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8")


def color_for_axis(axis: str) -> str:
    return {
        "x": "#d33f49",
        "y": "#246eb9",
        "z": "#2f9c5a",
        "reset": "#f18f01",
        "other": "#6f4aa2",
    }.get(axis, "#6f4aa2")


def esc(text: object) -> str:
    return (
        str(text)
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )


def write_svg(path: Path, macro: Macro, pin_rects: list[dict[str, object]], label_mode: str) -> None:
    width = max(macro.width, 1.0)
    height = max(macro.height, 1.0)
    canvas_target = 1200.0
    scale = canvas_target / max(width, height)
    margin = 60.0
    svg_w = width * scale + 2 * margin
    svg_h = height * scale + 2 * margin

    def sx(x: float) -> float:
        return margin + x * scale

    def sy(y: float) -> float:
        return margin + (height - y) * scale

    lines = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{svg_w:.1f}" height="{svg_h:.1f}" viewBox="0 0 {svg_w:.1f} {svg_h:.1f}">',
        "<style>",
        "text { font-family: sans-serif; font-size: 11px; fill: #202124; }",
        ".macro { fill: #fbfbfb; stroke: #111; stroke-width: 2; }",
        ".obs { fill: #9aa0a6; opacity: 0.25; stroke: #5f6368; stroke-width: 0.6; }",
        ".pin { opacity: 0.82; stroke: #111; stroke-width: 0.5; }",
        ".axis { font-weight: 700; }",
        "</style>",
        f'<rect class="macro" x="{sx(0):.3f}" y="{sy(height):.3f}" width="{width * scale:.3f}" height="{height * scale:.3f}"/>',
        f'<text x="{sx(0):.3f}" y="{sy(height) - 18:.3f}">{esc(macro.name)} {width:.3f}um x {height:.3f}um</text>',
    ]

    for obs in macro.obs:
        lines.append(
            f'<rect class="obs" x="{sx(obs.x1):.3f}" y="{sy(obs.y2):.3f}" '
            f'width="{obs.width * scale:.3f}" height="{obs.height * scale:.3f}">'
            f"<title>OBS {esc(obs.layer)} ({obs.x1},{obs.y1})-({obs.x2},{obs.y2})</title></rect>"
        )

    for row in pin_rects:
        x1 = float(row["x1"])
        y1 = float(row["y1"])
        x2 = float(row["x2"])
        y2 = float(row["y2"])
        axis = str(row["axis_guess"])
        pin = str(row["pin"])
        color = color_for_axis(axis)
        lines.append(
            f'<rect class="pin" x="{sx(x1):.3f}" y="{sy(y2):.3f}" '
            f'width="{(x2 - x1) * scale:.3f}" height="{(y2 - y1) * scale:.3f}" '
            f'fill="{color}"><title>{esc(pin)} {esc(row["layer"])} '
            f'({x1},{y1})-({x2},{y2}) side={esc(row["side"])}</title></rect>'
        )
        if label_mode == "all":
            lines.append(
                f'<text x="{sx((x1 + x2) / 2):.3f}" y="{sy((y1 + y2) / 2):.3f}" '
                f'text-anchor="middle">{esc(pin)}</text>'
            )

    legend_y = sy(0) + 30
    for idx, axis in enumerate(["x", "y", "z", "reset", "other"]):
        lx = sx(0) + idx * 120
        lines.append(f'<rect x="{lx:.3f}" y="{legend_y:.3f}" width="16" height="10" fill="{color_for_axis(axis)}"/>')
        lines.append(f'<text class="axis" x="{lx + 22:.3f}" y="{legend_y + 10:.3f}">{axis}</text>')

    lines.append("</svg>")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_report(path: Path, macro: Macro, pin_summary: list[dict[str, object]], pin_rects: list[dict[str, object]], expected_axis_count: int) -> None:
    axis_counts = summarize(pin_summary, "axis_guess")
    side_counts = summarize(pin_summary, "side")
    layer_counts = summarize(pin_rects, "layer")
    missing = {axis: missing_axis_indices(pin_summary, axis, expected_axis_count) for axis in ("x", "y", "z")}
    no_shape = [row["pin"] for row in pin_summary if row["side"] == "NO_SHAPE"]
    internal = [row["pin"] for row in pin_summary if str(row["side"]).startswith("INTERNAL")]

    lines = [
        "# SPAD Matrix Abstract Extraction Report",
        "",
        f"MACRO={macro.name}",
        f"WIDTH_UM={macro.width}",
        f"HEIGHT_UM={macro.height}",
        f"ORIGIN={macro.origin[0]},{macro.origin[1]}",
        f"RAW_BOUNDARY_X1_UM={macro.boundary_x1}",
        f"RAW_BOUNDARY_Y1_UM={macro.boundary_y1}",
        f"RAW_BOUNDARY_X2_UM={macro.boundary_x2}",
        f"RAW_BOUNDARY_Y2_UM={macro.boundary_y2}",
        f"CLASS={macro.cls}",
        f"SITE={macro.site}",
        f"SYMMETRY={macro.symmetry}",
        f"PIN_COUNT={len(macro.pins)}",
        f"PIN_SHAPE_COUNT={len(pin_rects)}",
        f"OBS_SHAPE_COUNT={len(macro.obs)}",
        "",
        "## Axis Guess Counts",
        "",
    ]
    lines += [f"- {key}: {value}" for key, value in axis_counts.items()]
    lines += ["", "## Side Counts", ""]
    lines += [f"- {key}: {value}" for key, value in side_counts.items()]
    lines += ["", "## Layer Counts", ""]
    lines += [f"- {key}: {value}" for key, value in layer_counts.items()]
    lines += ["", "## Missing Axis Indices", ""]
    for axis in ("x", "y", "z"):
        values = ",".join(str(i) for i in missing[axis])
        lines.append(f"- {axis}: {values if values else 'none'}")
    lines += ["", "## Review Flags", ""]
    lines.append(f"- pins_without_shapes: {', '.join(no_shape) if no_shape else 'none'}")
    lines.append(f"- pins_not_on_macro_edge: {', '.join(internal) if internal else 'none'}")
    lines += [
        "",
        "## Generated Files",
        "",
        "- `matrix_macro_summary.json`",
        "- `matrix_pin_summary.csv`",
        "- `matrix_pin_shapes.csv`",
        "- `matrix_pin_map.svg`",
        "- `position_pnr_seed.tcl`",
    ]
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_seed_tcl(path: Path, macro: Macro, pin_summary: list[dict[str, object]]) -> None:
    lines = [
        "# Auto-generated from SPAD matrix abstract extraction.",
        "# Use as floorplan seed data only; review before sourcing into Innovus.",
        f"set spad_matrix_macro_name {{{macro.name}}}",
        f"set spad_matrix_width_um {macro.width}",
        f"set spad_matrix_height_um {macro.height}",
        f"set spad_matrix_origin_um {{{macro.origin[0]} {macro.origin[1]}}}",
        f"set spad_matrix_raw_boundary_um {{{macro.boundary_x1} {macro.boundary_y1} {macro.boundary_x2} {macro.boundary_y2}}}",
        "array unset spad_matrix_pin_center",
        "array unset spad_matrix_pin_center_ll",
        "array unset spad_matrix_pin_side",
        "array unset spad_matrix_pin_axis",
    ]
    for row in pin_summary:
        pin = str(row["pin"])
        lines.append(f"set spad_matrix_pin_center({{{pin}}}) {{{row['center_x']} {row['center_y']}}}")
        lines.append(f"set spad_matrix_pin_center_ll({{{pin}}}) {{{row['ll_center_x']} {row['ll_center_y']}}}")
        lines.append(f"set spad_matrix_pin_side({{{pin}}}) {{{row['side']}}}")
        lines.append(f"set spad_matrix_pin_axis({{{pin}}}) {{{row['axis_guess']}}}")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def sanitize_name(name: str) -> str:
    safe = re.sub(r"[^A-Za-z0-9_.+-]+", "_", name)
    return safe.strip("._") or "macro"


def macro_index_row(macro: Macro) -> dict[str, object]:
    return {
        "macro": macro.name,
        "class": macro.cls,
        "origin_x": macro.origin[0],
        "origin_y": macro.origin[1],
        "raw_boundary_x1": macro.boundary_x1,
        "raw_boundary_y1": macro.boundary_y1,
        "raw_boundary_x2": macro.boundary_x2,
        "raw_boundary_y2": macro.boundary_y2,
        "width_um": macro.width,
        "height_um": macro.height,
        "symmetry": macro.symmetry,
        "site": macro.site,
        "pin_count": len(macro.pins),
        "obs_shape_count": len(macro.obs),
    }


def write_macro_outputs(out_dir: Path, macro: Macro, edge_tolerance: float, expected_axis_count: int, svg_labels: str) -> tuple[list[dict[str, object]], list[dict[str, object]]]:
    out_dir.mkdir(parents=True, exist_ok=True)
    pin_summary, pin_rects = collect_pin_rows(macro, edge_tolerance)

    write_csv(out_dir / "matrix_pin_summary.csv", pin_summary)
    write_csv(out_dir / "matrix_pin_shapes.csv", pin_rects)
    write_json(out_dir / "matrix_macro_summary.json", macro, pin_summary, pin_rects, edge_tolerance, expected_axis_count)
    write_svg(out_dir / "matrix_pin_map.svg", macro, pin_rects, svg_labels)
    write_report(out_dir / "matrix_handoff_report.md", macro, pin_summary, pin_rects, expected_axis_count)
    write_seed_tcl(out_dir / "position_pnr_seed.tcl", macro, pin_summary)
    return pin_summary, pin_rects


def choose_macro(macros: dict[str, Macro], requested: str | None) -> Macro:
    if requested:
        if requested not in macros:
            available = ", ".join(sorted(macros))
            raise SystemExit(f"ERROR: macro '{requested}' not found. Available macros: {available}")
        return macros[requested]
    if len(macros) == 1:
        return next(iter(macros.values()))
    available = ", ".join(sorted(macros))
    raise SystemExit(f"ERROR: LEF contains multiple macros. Pass --macro. Available macros: {available}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lef", required=True, type=Path, help="SPAD matrix LEF abstract path")
    parser.add_argument("--macro", help="Macro name inside the LEF; required when LEF has multiple macros")
    parser.add_argument("--out-dir", type=Path, help="Output directory")
    parser.add_argument("--expected-axis-count", type=int, default=64, help="Expected X/Y/Z line count")
    parser.add_argument("--edge-tolerance-um", type=float, default=-1.0, help="Pin-to-edge tolerance in um; default is max(size)*0.001")
    parser.add_argument("--svg-labels", choices=["none", "all"], default="none", help="Whether to draw pin names in the SVG")
    parser.add_argument("--list-macros", action="store_true", help="List macros in the LEF and exit")
    parser.add_argument("--all-macros", action="store_true", help="Extract every macro in the LEF")
    args = parser.parse_args()

    if not args.lef.is_file():
        raise SystemExit(f"ERROR: LEF file not found: {args.lef}")

    macros = parse_lef(args.lef)
    if not macros:
        raise SystemExit(f"ERROR: no LEF MACRO blocks found in {args.lef}")

    if args.list_macros:
        writer = csv.DictWriter(sys.stdout, fieldnames=list(macro_index_row(next(iter(macros.values()))).keys()))
        writer.writeheader()
        for macro in sorted(macros.values(), key=lambda m: natural_sort_key(m.name)):
            writer.writerow(macro_index_row(macro))
        return 0

    if args.out_dir is None:
        raise SystemExit("ERROR: --out-dir is required unless --list-macros is used")

    if args.all_macros:
        selected_macros = sorted(macros.values(), key=lambda m: natural_sort_key(m.name))
    else:
        selected_macros = [choose_macro(macros, args.macro)]

    for macro in selected_macros:
        if macro.size is None:
            raise SystemExit(f"ERROR: macro {macro.name} has no SIZE statement")

    args.out_dir.mkdir(parents=True, exist_ok=True)
    index_rows = [macro_index_row(macro) for macro in selected_macros]
    write_csv(args.out_dir / "matrix_macro_index.csv", index_rows)
    (args.out_dir / "matrix_macro_index.json").write_text(
        json.dumps(index_rows, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )

    for macro in selected_macros:
        edge_tolerance = args.edge_tolerance_um
        if edge_tolerance < 0:
            edge_tolerance = max(macro.width, macro.height) * 0.001

        macro_out_dir = args.out_dir
        if len(selected_macros) > 1:
            macro_out_dir = args.out_dir / "macros" / sanitize_name(macro.name)
        write_macro_outputs(macro_out_dir, macro, edge_tolerance, args.expected_axis_count, args.svg_labels)

        print(f"SPAD_MATRIX_MACRO={macro.name}")
        print(f"SPAD_MATRIX_SIZE_UM={macro.width}x{macro.height}")
        print(f"SPAD_MATRIX_PIN_COUNT={len(macro.pins)}")
        print(f"SPAD_MATRIX_MACRO_OUTPUT_DIR={macro_out_dir}")
    print(f"SPAD_MATRIX_OUTPUT_DIR={args.out_dir}")
    if len(selected_macros) == 1:
        print(f"SPAD_MATRIX_REPORT={args.out_dir / 'matrix_handoff_report.md'}")
    else:
        print(f"SPAD_MATRIX_MACRO_INDEX={args.out_dir / 'matrix_macro_index.csv'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
