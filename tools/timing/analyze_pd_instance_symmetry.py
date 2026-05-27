#!/usr/bin/env python3
"""Summarize O0 PD instance placement symmetry CSV reports."""

from __future__ import annotations

import argparse
import csv
from collections import Counter
from pathlib import Path


def as_float(value: str) -> float | None:
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("csv_file", type=Path)
    parser.add_argument("--out", type=Path)
    parser.add_argument("--grid-tol-um", type=float, default=0.5)
    args = parser.parse_args()

    rows = list(csv.DictReader(args.csv_file.open()))
    coords = Counter((r.get("ns", ""), r.get("nf", "")) for r in rows)
    orientations = Counter(r.get("orientation", "") for r in rows)
    masters = Counter(r.get("master", "") for r in rows)
    missing = [(ns, nf) for ns in range(8) for nf in range(8) if coords[(str(ns), str(nf))] == 0]
    duplicates = [coord for coord, count in coords.items() if coord != ("", "") and count > 1]
    large_offsets = []
    for row in rows:
        dx = as_float(row.get("dx_um", ""))
        dy = as_float(row.get("dy_um", ""))
        if dx is not None and dy is not None and (abs(dx) > args.grid_tol_um or abs(dy) > args.grid_tol_um):
            large_offsets.append(row)

    status = "PASS"
    if len(rows) != 64 or missing or duplicates or large_offsets:
        status = "REVIEW_REQUIRED"
    if len(rows) == 0:
        status = "FAIL"

    lines = [
        "# PD Instance Symmetry Summary",
        "",
        f"- Source CSV: `{args.csv_file}`",
        f"- Status: `{status}`",
        f"- Rows parsed: {len(rows)}",
        f"- Missing logical cells: {len(missing)}",
        f"- Duplicate logical coordinates: {len(duplicates)}",
        f"- Placement offsets over {args.grid_tol_um:.3f} um: {len(large_offsets)}",
        "",
        "## Orientation Histogram",
        "",
    ]
    for key, count in orientations.most_common():
        lines.append(f"- `{key or 'unknown'}`: {count}")
    lines.extend(["", "## Master Histogram", ""])
    for key, count in masters.most_common():
        lines.append(f"- `{key or 'unknown'}`: {count}")
    if missing:
        lines.extend(["", "## Missing Coordinates", ""])
        lines.extend(f"- ns={ns}, nf={nf}" for ns, nf in missing)
    if duplicates:
        lines.extend(["", "## Duplicate Coordinates", ""])
        lines.extend(f"- ns={ns}, nf={nf}" for ns, nf in duplicates)
    if large_offsets:
        lines.extend(["", "## Large Grid Offsets", ""])
        for row in large_offsets[:50]:
            lines.append(
                f"- `{row.get('instance')}` ns={row.get('ns')} nf={row.get('nf')} "
                f"dx={row.get('dx_um')} dy={row.get('dy_um')}"
            )

    text = "\n".join(lines) + "\n"
    if args.out:
        args.out.write_text(text)
    else:
        print(text, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
