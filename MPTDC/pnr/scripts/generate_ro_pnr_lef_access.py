#!/usr/bin/env python3
"""Generate a PnR-only RO_tune6 LEF with narrow OBS access windows.

This script consumes the orientation-aware marker audit produced by
``audit_ro_marker_vs_lef.py``.  It does not modify the golden LEF.  It copies the
source LEF and only splits/removes OBS rectangles that overlap narrow access
windows around route-DRC marker boxes and their implicated pins.
"""

from __future__ import annotations

import argparse
import csv
import datetime as _dt
import math
import re
from collections import Counter
from dataclasses import dataclass
from pathlib import Path


Box = tuple[float, float, float, float]


@dataclass(frozen=True)
class PinRect:
    name: str
    layer: str
    box: Box


@dataclass(frozen=True)
class AccessWindow:
    layer: str
    box: Box
    pin: str
    source_idx: str
    reason: str


def parse_box(text: object) -> Box | None:
    values = re.findall(r"[-+]?\d+(?:\.\d+)?", str(text or ""))
    if len(values) < 4:
        return None
    x1, y1, x2, y2 = (float(v) for v in values[:4])
    return (min(x1, x2), min(y1, y2), max(x1, x2), max(y1, y2))


def fmt_num(value: float) -> str:
    text = f"{value:.6f}".rstrip("0").rstrip(".")
    return text if text else "0"


def fmt_box(box: Box) -> str:
    return " ".join(fmt_num(v) for v in box)


def box_area(box: Box) -> float:
    return max(0.0, box[2] - box[0]) * max(0.0, box[3] - box[1])


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


def normalize_box(box: Box) -> Box:
    return (
        min(box[0], box[2]),
        min(box[1], box[3]),
        max(box[0], box[2]),
        max(box[1], box[3]),
    )


def subtract_cut(rect: Box, cut: Box, min_size: float) -> list[Box]:
    if not overlap(rect, cut):
        return [rect]
    x1, y1, x2, y2 = rect
    cx1 = max(x1, cut[0])
    cy1 = max(y1, cut[1])
    cx2 = min(x2, cut[2])
    cy2 = min(y2, cut[3])
    pieces = [
        (x1, y1, cx1, y2),
        (cx2, y1, x2, y2),
        (cx1, y1, cx2, cy1),
        (cx1, cy2, cx2, y2),
    ]
    return [
        normalize_box(piece)
        for piece in pieces
        if piece[2] - piece[0] >= min_size and piece[3] - piece[1] >= min_size
    ]


def subtract_cuts(rect: Box, cuts: list[AccessWindow], min_size: float) -> list[Box]:
    pieces = [rect]
    for cut in cuts:
        new_pieces: list[Box] = []
        for piece in pieces:
            new_pieces.extend(subtract_cut(piece, cut.box, min_size))
        pieces = new_pieces
        if not pieces:
            break
    return pieces


def parse_lef_pins(path: Path, macro_name: str) -> list[PinRect]:
    pins: list[PinRect] = []
    in_prop = False
    in_macro = False
    in_obs = False
    pin = ""
    layer = ""
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
        if pin and layer and match:
            pins.append(PinRect(pin, layer, normalize_box(tuple(float(match.group(i)) for i in range(1, 5)))))
    return pins


def read_audit_rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8", errors="replace") as fh:
        return list(csv.DictReader(fh, delimiter="\t"))


def infer_pin_name(row: dict[str, str]) -> str:
    message = row.get("message", "")
    match = re.search(r"phase_raw\[(\d+)\]", message)
    if match:
        return f"S[{match.group(1)}]"
    if re.search(r"fe_osc_.*_en|rstb", message):
        return "rstb"
    nearest = row.get("nearest_pin_same_layer", "")
    if nearest:
        return nearest.split(":", 1)[0]
    return ""


def nearest_pin_rect(pin_rects: list[PinRect], pin_name: str, marker_layer: str, marker_box: Box) -> PinRect | None:
    same_name = [pin for pin in pin_rects if pin.name == pin_name]
    if not same_name:
        return None
    same_layer = [pin for pin in same_name if pin.layer == marker_layer]
    candidates = same_layer or same_name
    return min(candidates, key=lambda pin: clearance(marker_box, pin.box))


def make_windows(
    audit_rows: list[dict[str, str]],
    pins: list[PinRect],
    x_margin: float,
    y_margin: float,
    also_clear_pin_layer: bool,
) -> list[AccessWindow]:
    windows: list[AccessWindow] = []
    seen: set[tuple[str, tuple[int, int, int, int], str]] = set()
    for row in audit_rows:
        classification = row.get("classification", "")
        if classification not in {"OBS_OVERLAP_NO_PIN", "PIN_AND_OBS_OVERLAP"}:
            continue
        marker_layer = row.get("marker_layer", "")
        marker_box = parse_box(row.get("marker_lef_box", ""))
        if not marker_layer or marker_box is None:
            continue
        pin_name = infer_pin_name(row)
        pin_rect = nearest_pin_rect(pins, pin_name, marker_layer, marker_box) if pin_name else None
        if pin_rect is not None:
            base = (
                min(marker_box[0], pin_rect.box[0]) - x_margin,
                min(marker_box[1], pin_rect.box[1]) - y_margin,
                max(marker_box[2], pin_rect.box[2]) + x_margin,
                max(marker_box[3], pin_rect.box[3]) + y_margin,
            )
            reason = f"{classification}:{pin_name}"
        else:
            base = (
                marker_box[0] - x_margin,
                marker_box[1] - y_margin,
                marker_box[2] + x_margin,
                marker_box[3] + y_margin,
            )
            reason = f"{classification}:marker_only"
        for layer in [marker_layer]:
            box = normalize_box(base)
            key = (layer, tuple(round(v * 1_000_000) for v in box), pin_name)
            if key not in seen:
                windows.append(AccessWindow(layer, box, pin_name, row.get("idx", ""), reason))
                seen.add(key)
        if also_clear_pin_layer and pin_rect is not None and pin_rect.layer != marker_layer:
            box = normalize_box(base)
            key = (pin_rect.layer, tuple(round(v * 1_000_000) for v in box), pin_name)
            if key not in seen:
                windows.append(AccessWindow(pin_rect.layer, box, pin_name, row.get("idx", ""), reason + ":pin_layer"))
                seen.add(key)
    return windows


def patch_lef(source: Path, output: Path, macro_name: str, windows: list[AccessWindow], min_piece: float, audit: Path) -> dict[str, object]:
    lines = source.read_text(encoding="utf-8", errors="replace").splitlines()
    out: list[str] = []
    in_prop = False
    in_macro = False
    in_obs = False
    layer = ""
    stats: Counter[str] = Counter()
    removed_area_by_layer: Counter[str] = Counter()
    windows_by_layer: dict[str, list[AccessWindow]] = {}
    for window in windows:
        windows_by_layer.setdefault(window.layer, []).append(window)

    header = [
        "# Generated PnR-only RO_tune6 LEF access patch.",
        f"# Source LEF: {source}",
        f"# Audit TSV: {audit}",
        f"# Generated UTC: {_dt.datetime.now(_dt.timezone.utc).isoformat()}",
        "# Reason: split only OBS rectangles that overlap route DRC marker access windows.",
        "# This is not golden layout source; use only through O1_RO_LEF_PATH for PnR diagnosis/closure.",
    ]
    out.extend(header)

    for raw in lines:
        line = raw.strip()
        upper = line.upper()
        tokens = line.split()
        if upper.startswith("PROPERTYDEFINITIONS"):
            in_prop = True
        elif in_prop and upper.startswith("END PROPERTYDEFINITIONS"):
            in_prop = False

        if not in_prop and not in_macro:
            if len(tokens) == 2 and tokens[0].upper() == "MACRO" and tokens[1] == macro_name:
                in_macro = True
        elif (
            in_macro
            and not in_obs
            and len(tokens) >= 2
            and tokens[0].upper() == "END"
            and tokens[1].rstrip(";") == macro_name
        ):
            in_macro = False

        if in_macro and not in_obs and upper == "OBS":
            in_obs = True
            layer = ""
            out.append(raw)
            continue
        if in_obs and upper == "END":
            in_obs = False
            layer = ""
            out.append(raw)
            continue
        if in_obs:
            match = re.match(r"(\s*)LAYER\s+([^ ;]+)\s*;", raw, re.IGNORECASE)
            if match:
                layer = match.group(2)
                out.append(raw)
                continue
            match = re.match(
                r"(\s*)RECT\s+([-+0-9.]+)\s+([-+0-9.]+)\s+([-+0-9.]+)\s+([-+0-9.]+)\s*;",
                raw,
                re.IGNORECASE,
            )
            if match and layer in windows_by_layer:
                indent = match.group(1)
                rect = normalize_box(tuple(float(match.group(i)) for i in range(2, 6)))
                cuts = [window for window in windows_by_layer[layer] if overlap(rect, window.box)]
                if cuts:
                    pieces = subtract_cuts(rect, cuts, min_piece)
                    stats["obs_rects_touched"] += 1
                    stats[f"obs_rects_touched_{layer}"] += 1
                    stats["obs_rects_removed"] += 1 if not pieces else 0
                    removed_area = box_area(rect) - sum(box_area(piece) for piece in pieces)
                    removed_area_by_layer[layer] += removed_area
                    out.append(f"{indent}# MPTDC_PNR_ACCESS_TRIM original RECT {fmt_box(rect)} ;")
                    for piece in pieces:
                        out.append(f"{indent}RECT {fmt_box(piece)} ;")
                    continue
        out.append(raw)

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(out) + "\n", encoding="utf-8")
    return {
        "obs_rects_touched": stats["obs_rects_touched"],
        "obs_rects_removed": stats["obs_rects_removed"],
        "obs_rects_touched_by_layer": {k.removeprefix("obs_rects_touched_"): v for k, v in stats.items() if k.startswith("obs_rects_touched_")},
        "removed_area_by_layer": dict(removed_area_by_layer),
    }


def write_summary(path: Path, source: Path, audit: Path, output: Path, windows: list[AccessWindow], patch_stats: dict[str, object]) -> None:
    by_layer = Counter(window.layer for window in windows)
    by_pin = Counter(window.pin or "UNKNOWN" for window in windows)
    with path.open("w", encoding="utf-8") as fh:
        fh.write("# RO PnR LEF Access Patch Summary\n")
        fh.write(f"SOURCE_LEF={source}\n")
        fh.write(f"AUDIT_TSV={audit}\n")
        fh.write(f"OUTPUT_LEF={output}\n")
        fh.write(f"ACCESS_WINDOW_COUNT={len(windows)}\n")
        for layer, count in sorted(by_layer.items()):
            fh.write(f"ACCESS_WINDOWS_BY_LAYER {layer} {count}\n")
        for pin, count in sorted(by_pin.items()):
            fh.write(f"ACCESS_WINDOWS_BY_PIN {pin} {count}\n")
        fh.write(f"OBS_RECTS_TOUCHED={patch_stats['obs_rects_touched']}\n")
        fh.write(f"OBS_RECTS_REMOVED={patch_stats['obs_rects_removed']}\n")
        for layer, count in sorted(dict(patch_stats["obs_rects_touched_by_layer"]).items()):
            fh.write(f"OBS_RECTS_TOUCHED_BY_LAYER {layer} {count}\n")
        for layer, area in sorted(dict(patch_stats["removed_area_by_layer"]).items()):
            fh.write(f"OBS_REMOVED_AREA_UM2 {layer} {area:.6f}\n")
        fh.write("\nWINDOWS:\n")
        for window in windows:
            fh.write(
                f"{window.layer}\t{fmt_box(window.box)}\t"
                f"pin={window.pin or 'UNKNOWN'}\tidx={window.source_idx}\treason={window.reason}\n"
            )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-lef", required=True, type=Path)
    parser.add_argument("--audit-tsv", required=True, type=Path)
    parser.add_argument("--out-lef", required=True, type=Path)
    parser.add_argument("--summary", type=Path)
    parser.add_argument("--macro", default="RO_tune6")
    parser.add_argument("--x-margin-um", type=float, default=0.20)
    parser.add_argument("--y-margin-um", type=float, default=0.20)
    parser.add_argument("--min-piece-um", type=float, default=0.001)
    parser.add_argument("--no-clear-pin-layer", action="store_true")
    args = parser.parse_args()

    pins = parse_lef_pins(args.source_lef, args.macro)
    audit_rows = read_audit_rows(args.audit_tsv)
    windows = make_windows(
        audit_rows,
        pins,
        x_margin=args.x_margin_um,
        y_margin=args.y_margin_um,
        also_clear_pin_layer=not args.no_clear_pin_layer,
    )
    if not windows:
        raise SystemExit("ERROR: audit produced no OBS-overlap access windows")
    patch_stats = patch_lef(args.source_lef, args.out_lef, args.macro, windows, args.min_piece_um, args.audit_tsv)
    summary = args.summary or args.out_lef.with_suffix(args.out_lef.suffix + ".summary.txt")
    write_summary(summary, args.source_lef, args.audit_tsv, args.out_lef, windows, patch_stats)
    print(f"RO_PNR_LEF={args.out_lef}")
    print(f"RO_PNR_LEF_SUMMARY={summary}")
    print(f"ACCESS_WINDOW_COUNT={len(windows)}")
    print(f"OBS_RECTS_TOUCHED={patch_stats['obs_rects_touched']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
