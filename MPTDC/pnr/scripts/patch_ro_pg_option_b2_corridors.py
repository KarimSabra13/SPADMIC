#!/usr/bin/env python3
"""Patch RO_tune6 LEF OBS corridors from a protected via-stack access TSV."""

from __future__ import annotations

import argparse
import csv
import datetime as _dt
from dataclasses import dataclass
from pathlib import Path
import re
import sys


ORIENTS = ("R0", "MX", "MY", "R180")


@dataclass(frozen=True)
class Rect:
    x1: float
    y1: float
    x2: float
    y2: float

    def valid(self, min_size: float = 0.0) -> bool:
        return self.x2 - self.x1 > min_size and self.y2 - self.y1 > min_size

    def intersects(self, other: "Rect", min_size: float = 0.0) -> bool:
        return (
            min(self.x2, other.x2) - max(self.x1, other.x1) > min_size
            and min(self.y2, other.y2) - max(self.y1, other.y1) > min_size
        )

    def center(self) -> tuple[float, float]:
        return ((self.x1 + self.x2) / 2.0, (self.y1 + self.y2) / 2.0)

    def fmt(self) -> str:
        return " ".join(_fmt(v) for v in (self.x1, self.y1, self.x2, self.y2))


@dataclass(frozen=True)
class PinRect:
    pin: str
    layer: str
    rect: Rect


@dataclass(frozen=True)
class Macro:
    name: str
    origin: tuple[float, float]
    size: tuple[float, float]
    pin_rects: list[PinRect]
    obs: dict[str, list[Rect]]
    obs_start: int
    obs_end: int


@dataclass(frozen=True)
class Match:
    orient: str
    inst_ll: tuple[float, float]
    local_window: Rect
    pin_rect: PinRect


def _fmt(value: float) -> str:
    text = f"{value:.6f}".rstrip("0").rstrip(".")
    if text == "-0":
        return "0"
    return text


def _parse_rect(text: str) -> Rect:
    vals = [float(x) for x in text.split()]
    if len(vals) != 4:
        raise ValueError(f"expected four coordinates, got {text!r}")
    x1, y1, x2, y2 = vals
    return Rect(min(x1, x2), min(y1, y2), max(x1, x2), max(y1, y2))


def _norm_rect(rect: Rect, origin: tuple[float, float]) -> Rect:
    ox, oy = origin
    return Rect(rect.x1 + ox, rect.y1 + oy, rect.x2 + ox, rect.y2 + oy)


def _orient_rect(norm: Rect, inst_ll: tuple[float, float], size: tuple[float, float], orient: str) -> Rect:
    ix, iy = inst_ll
    width, height = size
    if orient == "R0":
        return Rect(ix + norm.x1, iy + norm.y1, ix + norm.x2, iy + norm.y2)
    if orient == "MX":
        return Rect(ix + norm.x1, iy + height - norm.y2, ix + norm.x2, iy + height - norm.y1)
    if orient == "MY":
        return Rect(ix + width - norm.x2, iy + norm.y1, ix + width - norm.x1, iy + norm.y2)
    if orient == "R180":
        return Rect(ix + width - norm.x2, iy + height - norm.y2, ix + width - norm.x1, iy + height - norm.y1)
    raise ValueError(f"unsupported orient {orient}")


def _inst_ll_for_match(abs_pin: Rect, norm_pin: Rect, size: tuple[float, float], orient: str) -> tuple[float, float]:
    width, height = size
    if orient == "R0":
        return abs_pin.x1 - norm_pin.x1, abs_pin.y1 - norm_pin.y1
    if orient == "MX":
        return abs_pin.x1 - norm_pin.x1, abs_pin.y1 - (height - norm_pin.y2)
    if orient == "MY":
        return abs_pin.x1 - (width - norm_pin.x2), abs_pin.y1 - norm_pin.y1
    if orient == "R180":
        return abs_pin.x1 - (width - norm_pin.x2), abs_pin.y1 - (height - norm_pin.y2)
    raise ValueError(f"unsupported orient {orient}")


def _abs_to_local(abs_rect: Rect, inst_ll: tuple[float, float], macro: Macro, orient: str) -> Rect:
    ix, iy = inst_ll
    ox, oy = macro.origin
    width, height = macro.size
    if orient == "R0":
        norm = Rect(abs_rect.x1 - ix, abs_rect.y1 - iy, abs_rect.x2 - ix, abs_rect.y2 - iy)
    elif orient == "MX":
        norm = Rect(abs_rect.x1 - ix, height - (abs_rect.y2 - iy), abs_rect.x2 - ix, height - (abs_rect.y1 - iy))
    elif orient == "MY":
        norm = Rect(width - (abs_rect.x2 - ix), abs_rect.y1 - iy, width - (abs_rect.x1 - ix), abs_rect.y2 - iy)
    elif orient == "R180":
        norm = Rect(width - (abs_rect.x2 - ix), height - (abs_rect.y2 - iy), width - (abs_rect.x1 - ix), height - (abs_rect.y1 - iy))
    else:
        raise ValueError(f"unsupported orient {orient}")
    return Rect(norm.x1 - ox, norm.y1 - oy, norm.x2 - ox, norm.y2 - oy)


def _boxes_close(a: Rect, b: Rect, tol: float) -> bool:
    return (
        abs(a.x1 - b.x1) <= tol
        and abs(a.y1 - b.y1) <= tol
        and abs(a.x2 - b.x2) <= tol
        and abs(a.y2 - b.y2) <= tol
    )


def _orient_order(inst_name: str) -> tuple[str, ...]:
    norm = inst_name.lower()
    if "_fast_" in norm or norm.endswith("_fast"):
        return ("MX", "R0", "MY", "R180")
    if "_slow_" in norm or norm.endswith("_slow"):
        return ("R0", "MX", "MY", "R180")
    return ORIENTS


def _trim_access_to_pin_edge(access: Rect, pin: Rect, target: Rect) -> Rect:
    pcx, pcy = pin.center()
    tcx, tcy = target.center()
    dx = abs(tcx - pcx)
    dy = abs(tcy - pcy)
    if dx >= dy:
        if tcx < pcx:
            return Rect(access.x1, access.y1, min(access.x2, pin.x2), access.y2)
        return Rect(max(access.x1, pin.x1), access.y1, access.x2, access.y2)
    if tcy < pcy:
        return Rect(access.x1, access.y1, access.x2, min(access.y2, pin.y2))
    return Rect(access.x1, max(access.y1, pin.y1), access.x2, access.y2)


def _subtract_window(rect: Rect, window: Rect, min_piece: float) -> list[Rect]:
    if not rect.intersects(window):
        return [rect]
    ix1 = max(rect.x1, window.x1)
    iy1 = max(rect.y1, window.y1)
    ix2 = min(rect.x2, window.x2)
    iy2 = min(rect.y2, window.y2)
    pieces = [
        Rect(rect.x1, rect.y1, ix1, rect.y2),
        Rect(ix2, rect.y1, rect.x2, rect.y2),
        Rect(ix1, rect.y1, ix2, iy1),
        Rect(ix1, iy2, ix2, rect.y2),
    ]
    return [piece for piece in pieces if piece.valid(min_piece)]


def parse_lef(path: Path, macro_name: str) -> tuple[list[str], Macro]:
    lines = path.read_text().splitlines()
    macro_start = None
    macro_end = None
    for idx, line in enumerate(lines):
        if re.match(rf"^\s*MACRO\s+{re.escape(macro_name)}\s*$", line):
            macro_start = idx
            break
    if macro_start is None:
        raise SystemExit(f"ERROR: macro {macro_name} not found in {path}")
    for idx in range(macro_start + 1, len(lines)):
        if re.match(rf"^\s*END\s+{re.escape(macro_name)}\s*$", lines[idx]):
            macro_end = idx
            break
    if macro_end is None:
        raise SystemExit(f"ERROR: END {macro_name} not found in {path}")

    origin = None
    size = None
    obs_start = None
    obs_end = None
    pin_rects: list[PinRect] = []
    obs: dict[str, list[Rect]] = {}
    current_pin = None
    current_layer = None
    in_obs = False

    for idx in range(macro_start + 1, macro_end):
        line = lines[idx]
        stripped = line.strip()
        m = re.match(r"ORIGIN\s+([-+0-9.]+)\s+([-+0-9.]+)\s*;", stripped)
        if m:
            origin = (float(m.group(1)), float(m.group(2)))
            continue
        m = re.match(r"SIZE\s+([-+0-9.]+)\s+BY\s+([-+0-9.]+)\s*;", stripped)
        if m:
            size = (float(m.group(1)), float(m.group(2)))
            continue
        if stripped == "OBS":
            in_obs = True
            obs_start = idx
            current_layer = None
            continue
        if in_obs and stripped == "END":
            obs_end = idx
            in_obs = False
            current_layer = None
            continue
        if in_obs:
            m = re.match(r"LAYER\s+(\S+)\s*;", stripped)
            if m:
                current_layer = m.group(1)
                obs.setdefault(current_layer, [])
                continue
            m = re.match(r"RECT\s+([-+0-9.]+)\s+([-+0-9.]+)\s+([-+0-9.]+)\s+([-+0-9.]+)\s*;", stripped)
            if m and current_layer:
                obs[current_layer].append(_parse_rect(" ".join(m.groups())))
            continue
        m = re.match(r"PIN\s+(\S+)\s*$", stripped)
        if m:
            current_pin = m.group(1)
            current_layer = None
            continue
        if current_pin:
            if re.match(rf"END\s+{re.escape(current_pin)}\s*$", stripped):
                current_pin = None
                current_layer = None
                continue
            m = re.match(r"LAYER\s+(\S+)\s*;", stripped)
            if m:
                current_layer = m.group(1)
                continue
            m = re.match(r"RECT\s+([-+0-9.]+)\s+([-+0-9.]+)\s+([-+0-9.]+)\s+([-+0-9.]+)\s*;", stripped)
            if m and current_layer:
                pin_rects.append(PinRect(current_pin, current_layer, _parse_rect(" ".join(m.groups()))))

    if origin is None:
        raise SystemExit(f"ERROR: macro {macro_name} has no ORIGIN in {path}")
    if size is None:
        raise SystemExit(f"ERROR: macro {macro_name} has no SIZE in {path}")
    if obs_start is None or obs_end is None:
        raise SystemExit(f"ERROR: macro {macro_name} has no parseable OBS block in {path}")
    return lines, Macro(macro_name, origin, size, pin_rects, obs, obs_start, obs_end)


def parse_access_rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="") as fh:
        reader = csv.DictReader(fh, delimiter="\t")
        rows = [row for row in reader]
    required = {"pin", "pin_layer", "pin_box", "target_box", "stack_layers", "access_box", "status", "reason"}
    missing = sorted(required - set(rows[0].keys() if rows else []))
    if missing:
        raise SystemExit(f"ERROR: TSV missing required columns: {', '.join(missing)}")
    return rows


def match_row_to_macro(macro: Macro, row: dict[str, str], tol: float) -> Match:
    pin = row["pin"]
    pin_layer = row["pin_layer"]
    abs_pin = _parse_rect(row["pin_box"])
    access = _parse_rect(row["access_box"])
    target = _parse_rect(row["target_box"])
    trimmed_access = _trim_access_to_pin_edge(access, abs_pin, target)
    candidates = [pr for pr in macro.pin_rects if pr.pin == pin and pr.layer == pin_layer]
    if not candidates:
        raise ValueError(f"{row['terminal']}: no LEF pin rect for {pin}/{pin_layer}")
    best: Match | None = None
    for pr in candidates:
        norm_pin = _norm_rect(pr.rect, macro.origin)
        for orient in _orient_order(row.get("inst", "")):
            inst_ll = _inst_ll_for_match(abs_pin, norm_pin, macro.size, orient)
            predicted = _orient_rect(norm_pin, inst_ll, macro.size, orient)
            if _boxes_close(predicted, abs_pin, tol):
                local_window = _abs_to_local(trimmed_access, inst_ll, macro, orient)
                best = Match(orient, inst_ll, local_window, pr)
                break
        if best:
            break
    if not best:
        raise ValueError(f"{row['terminal']}: cannot infer orientation/placement from pin box")
    if not best.local_window.valid():
        raise ValueError(f"{row['terminal']}: trimmed access window is empty")
    return best


def build_windows(macro: Macro, rows: list[dict[str, str]], tol: float) -> tuple[dict[str, list[Rect]], list[str]]:
    windows: dict[str, list[Rect]] = {}
    notes: list[str] = []
    for row in rows:
        if row["status"] != "FAIL" or "obs_overlap_outside_pin" not in row["reason"]:
            continue
        match = match_row_to_macro(macro, row, tol)
        layers = [layer.strip() for layer in row["stack_layers"].split(",") if layer.strip()]
        for layer in layers:
            windows.setdefault(layer, []).append(match.local_window)
        ix, iy = match.inst_ll
        notes.append(
            "ROW_{idx}={terminal} orient={orient} inst_ll={ix},{iy} window={window} layers={layers}".format(
                idx=row.get("idx", "?"),
                terminal=row.get("terminal", "?"),
                orient=match.orient,
                ix=_fmt(ix),
                iy=_fmt(iy),
                window=match.local_window.fmt(),
                layers=",".join(layers),
            )
        )
    return windows, notes


def patch_obs(macro: Macro, windows: dict[str, list[Rect]], min_piece: float) -> tuple[dict[str, list[Rect]], int]:
    patched: dict[str, list[Rect]] = {}
    cuts = 0
    for layer, rects in macro.obs.items():
        layer_windows = windows.get(layer, [])
        current = list(rects)
        for window in layer_windows:
            next_rects: list[Rect] = []
            for rect in current:
                pieces = _subtract_window(rect, window, min_piece)
                if len(pieces) != 1 or pieces[0] != rect:
                    cuts += 1
                next_rects.extend(pieces)
            current = next_rects
        patched[layer] = current
    return patched, cuts


def write_lef(lines: list[str], macro: Macro, obs: dict[str, list[Rect]], out_path: Path) -> None:
    out: list[str] = []
    out.extend(lines[: macro.obs_start])
    out.append("  OBS")
    out.append("    # MPTDC_OPTION_B2_PG_ACCESS_CUT")
    for layer in sorted(obs):
        if not obs[layer]:
            continue
        out.append(f"    LAYER {layer} ;")
        for rect in obs[layer]:
            out.append(f"      RECT {rect.fmt()} ;")
    out.append("  END")
    out.extend(lines[macro.obs_end + 1 :])
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(out) + "\n")


def write_summary(
    path: Path,
    *,
    source: Path,
    tsv: Path,
    out_lef: Path,
    rows: list[dict[str, str]],
    windows: dict[str, list[Rect]],
    notes: list[str],
    macro: Macro,
    patched_obs: dict[str, list[Rect]],
    cuts: int,
) -> None:
    original_count = sum(len(v) for v in macro.obs.values())
    patched_count = sum(len(v) for v in patched_obs.values())
    consumed = sum(1 for row in rows if row["status"] == "FAIL" and "obs_overlap_outside_pin" in row["reason"])
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w") as fh:
        fh.write("# MPTDC RO_tune6 Option B2 PG Corridor Patch\n")
        fh.write(f"PATCHED_AT_UTC={_dt.datetime.now(_dt.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')}\n")
        fh.write(f"SOURCE_LEF={source}\n")
        fh.write(f"VIA_STACK_TSV={tsv}\n")
        fh.write(f"OUTPUT_LEF={out_lef}\n")
        fh.write(f"MACRO={macro.name}\n")
        fh.write(f"ROWS_TOTAL={len(rows)}\n")
        fh.write(f"ROWS_CONSUMED={consumed}\n")
        fh.write(f"WINDOW_LAYER_COUNT={len(windows)}\n")
        fh.write(f"WINDOW_COUNT={sum(len(v) for v in windows.values())}\n")
        fh.write(f"OBS_RECTS_IN={original_count}\n")
        fh.write(f"OBS_RECTS_OUT={patched_count}\n")
        fh.write(f"OBS_RECTS_CUT={cuts}\n")
        fh.write(f"PATCH_STATUS={'PASS' if consumed and cuts else 'FAIL'}\n")
        for note in notes:
            fh.write(note + "\n")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-lef", required=True, type=Path)
    parser.add_argument("--via-stack-tsv", required=True, type=Path)
    parser.add_argument("--out-lef", required=True, type=Path)
    parser.add_argument("--summary", type=Path)
    parser.add_argument("--macro", default="RO_tune6")
    parser.add_argument("--match-tol-um", default=0.02, type=float)
    parser.add_argument("--min-piece-size-um", default=0.001, type=float)
    args = parser.parse_args(argv)

    lines, macro = parse_lef(args.source_lef, args.macro)
    rows = parse_access_rows(args.via_stack_tsv)
    try:
        windows, notes = build_windows(macro, rows, args.match_tol_um)
    except ValueError as exc:
        raise SystemExit(f"ERROR: {exc}") from exc
    if not windows:
        raise SystemExit("ERROR: no failed obs_overlap_outside_pin rows found in TSV")
    patched_obs, cuts = patch_obs(macro, windows, args.min_piece_size_um)
    write_lef(lines, macro, patched_obs, args.out_lef)
    if args.summary:
        write_summary(
            args.summary,
            source=args.source_lef,
            tsv=args.via_stack_tsv,
            out_lef=args.out_lef,
            rows=rows,
            windows=windows,
            notes=notes,
            macro=macro,
            patched_obs=patched_obs,
            cuts=cuts,
        )
    if cuts == 0:
        print("PATCH_STATUS=FAIL")
        print("PATCH_REASON=no_obs_rectangles_cut")
        return 2
    print("PATCH_STATUS=PASS")
    print(f"OUTPUT_LEF={args.out_lef}")
    if args.summary:
        print(f"SUMMARY={args.summary}")
    print(f"OBS_RECTS_CUT={cuts}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
