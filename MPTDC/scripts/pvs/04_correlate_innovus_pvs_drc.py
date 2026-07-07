#!/usr/bin/env python3
"""Correlate PVS DRC text output with the four current Innovus MET1 Mar boxes."""

from __future__ import annotations

import argparse
import os
import re
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Marker:
    idx: int
    net: str
    box: tuple[float, float, float, float]


DEFAULT_MARKERS = [
    Marker(1, "u_core_n_57561", (490.65, 290.78, 491.03, 291.06)),
    Marker(2, "n_1353", (677.69, 534.38, 678.07, 534.66)),
    Marker(3, "n_1343", (726.41, 518.14, 726.79, 518.42)),
    Marker(4, "n_1355", (793.61, 527.10, 793.99, 527.38)),
]

TEXT_SUFFIXES = {
    ".txt",
    ".rpt",
    ".log",
    ".out",
    ".err",
    ".sum",
    ".shorts",
    ".rul",
    ".rsf",
    ".pvs",
}


def expand(box: tuple[float, float, float, float], margin: float) -> tuple[float, float, float, float]:
    x1, y1, x2, y2 = box
    return (x1 - margin, y1 - margin, x2 + margin, y2 + margin)


def overlaps(a: tuple[float, float, float, float], b: tuple[float, float, float, float]) -> bool:
    return min(a[2], b[2]) >= max(a[0], b[0]) and min(a[3], b[3]) >= max(a[1], b[1])


def parse_marker_tsv(path: Path) -> list[Marker]:
    markers: list[Marker] = []
    box_re = re.compile(r"\{?\s*(-?\d+(?:\.\d+)?)\s+(-?\d+(?:\.\d+)?)\s+(-?\d+(?:\.\d+)?)\s+(-?\d+(?:\.\d+)?)\s*\}?")
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if line.startswith("idx") or not line.strip():
            continue
        fields = line.split("\t")
        if len(fields) < 7:
            fields = re.split(r"\s{2,}", line.strip())
        if len(fields) < 7:
            continue
        match = box_re.search(line)
        if not match:
            continue
        msg = line
        net_match = re.search(r"Net\s+([A-Za-z0-9_\\/\\.\[\]-]+)", msg)
        net = net_match.group(1) if net_match else "UNKNOWN"
        markers.append(
            Marker(
                len(markers) + 1,
                net,
                tuple(float(match.group(i)) for i in range(1, 5)),  # type: ignore[arg-type]
            )
        )
    return markers


def should_read(path: Path) -> bool:
    if any(part in {"REPORTDB", "netlistLAYOUT", "netlistSOURCE"} for part in path.parts):
        return False
    if path.suffix.lower() in {".rdb", ".ecdb", ".gds", ".gz", ".dat"}:
        return False
    return path.suffix.lower() in TEXT_SUFFIXES or path.name in {"run.pvs", "pvslvsctl"}


def iter_text_files(root: Path):
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in {"REPORTDB", "netlistLAYOUT", "netlistSOURCE"}]
        for name in filenames:
            path = Path(dirpath) / name
            if should_read(path):
                yield path


RECT_PATTERNS = [
    re.compile(r"\{\s*(-?\d+(?:\.\d+)?)\s+(-?\d+(?:\.\d+)?)\s+(-?\d+(?:\.\d+)?)\s+(-?\d+(?:\.\d+)?)\s*\}"),
    re.compile(r"\b(?:bbox|box|rect)\b[^-\d]*(-?\d+(?:\.\d+)?)\D+(-?\d+(?:\.\d+)?)\D+(-?\d+(?:\.\d+)?)\D+(-?\d+(?:\.\d+)?)", re.IGNORECASE),
]


def extract_rects(line: str) -> list[tuple[float, float, float, float]]:
    rects: list[tuple[float, float, float, float]] = []
    for pattern in RECT_PATTERNS:
        for match in pattern.finditer(line):
            nums = [float(match.group(i)) for i in range(1, 5)]
            x1, x2 = sorted((nums[0], nums[2]))
            y1, y2 = sorted((nums[1], nums[3]))
            rects.append((x1, y1, x2, y2))
    return rects


def find_total_drc(line: str) -> str | None:
    patterns = [
        r"Total\s+DRC\s+Results?\s*[:=]\s*([0-9]+)",
        r"Total\s+number\s+of\s+DRC\s+violations?\s*[:=]\s*([0-9]+)",
        r"Verification\s+Complete\s*:\s*([0-9]+)\s+Viols?",
    ]
    for pattern in patterns:
        match = re.search(pattern, line, re.IGNORECASE)
        if match:
            return match.group(1)
    if re.search(r"\b(no|zero)\s+DRC\s+(results?|violations?)\b", line, re.IGNORECASE):
        return "0"
    return None


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pvs-root", required=True, type=Path, help="PVS DRC run directory")
    parser.add_argument("--out", required=True, type=Path, help="Correlation report")
    parser.add_argument("--innovus-markers", type=Path, help="Optional Innovus marker TSV")
    parser.add_argument("--margin", type=float, default=0.35, help="Marker expansion in microns")
    args = parser.parse_args()

    if not args.pvs_root.is_dir():
        raise SystemExit(f"ERROR: PVS root is not a directory: {args.pvs_root}")

    markers = parse_marker_tsv(args.innovus_markers) if args.innovus_markers else DEFAULT_MARKERS
    expanded = {m.idx: expand(m.box, args.margin) for m in markers}
    hits: dict[int, list[str]] = {m.idx: [] for m in markers}
    total_drc = "UNKNOWN"
    files_scanned = 0
    lines_scanned = 0

    for path in iter_text_files(args.pvs_root):
        files_scanned += 1
        try:
            lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
        except OSError:
            continue
        for lineno, line in enumerate(lines, start=1):
            lines_scanned += 1
            found_total = find_total_drc(line)
            if found_total is not None:
                total_drc = found_total
            if not re.search(r"MET1|m1|m1trm|area|AREA|drc|DRC|viol|VIOL|Rule|RESULT", line):
                continue
            for rect in extract_rects(line):
                for marker in markers:
                    if overlaps(rect, expanded[marker.idx]):
                        hits[marker.idx].append(f"{path}:{lineno}:{line.strip()[:300]}")

    hit_count = sum(1 for marker_hits in hits.values() if marker_hits)
    if hit_count == len(markers):
        status = "YES"
    elif hit_count == 0 and total_drc == "0":
        status = "NO"
    elif hit_count == 0:
        status = "NO"
    else:
        status = "PARTIAL"

    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w", encoding="utf-8") as fh:
        print("# MPTDC PVS DRC vs Innovus Mar4 Correlation", file=fh)
        print(f"PVS_ROOT={args.pvs_root}", file=fh)
        print(f"FILES_SCANNED={files_scanned}", file=fh)
        print(f"LINES_SCANNED={lines_scanned}", file=fh)
        print(f"PVS_DRC_TOTAL={total_drc}", file=fh)
        print(f"MARKER_MARGIN_UM={args.margin}", file=fh)
        print(f"PVS_REPRODUCES_INNOVUS_MAR4={status}", file=fh)
        for marker in markers:
            print("", file=fh)
            print(f"MARKER_{marker.idx}_NET={marker.net}", file=fh)
            print(f"MARKER_{marker.idx}_BOX={marker.box}", file=fh)
            print(f"MARKER_{marker.idx}_HIT_COUNT={len(hits[marker.idx])}", file=fh)
            for hit in hits[marker.idx][:25]:
                print(f"MARKER_{marker.idx}_HIT={hit}", file=fh)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
