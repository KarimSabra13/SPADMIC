#!/usr/bin/env python3
"""Summarize O0 oscillator phase route/load balance CSV reports."""

from __future__ import annotations

import argparse
import csv
from collections import defaultdict
from pathlib import Path


def f(row: dict[str, str], key: str) -> float | None:
    try:
        if row.get(key, "") == "":
            return None
        return float(row[key])
    except ValueError:
        return None


def pct_spread(values: list[float]) -> float | None:
    if not values:
        return None
    avg = sum(values) / len(values)
    if avg == 0:
        return 0.0
    return 100.0 * (max(values) - min(values)) / avg


def summarize_family(rows: list[dict[str, str]], family: str) -> list[str]:
    fam = [r for r in rows if r.get("family") == family]
    lines = [f"## {family.title()} Tap Balance", ""]
    if not fam:
        return lines + ["- No rows parsed.", ""]
    for metric in ["total_cap_fF", "estimated_delay_ps", "transition_ps", "wire_length_um", "via_count"]:
        values = [v for r in fam if (v := f(r, metric)) is not None]
        if not values:
            lines.append(f"- `{metric}`: not reported")
            continue
        spread = pct_spread(values)
        lines.append(
            f"- `{metric}`: min={min(values):.3f}, max={max(values):.3f}, "
            f"spread={spread:.2f}%"
        )
    extra = [r for r in fam if (f(r, "extra_load_count") or 0.0) > 0.0]
    if extra:
        lines.append(f"- Extra non-PD load taps: {len(extra)}")
        for row in extra:
            lines.append(
                f"  - tap {row.get('tap_index')}: extra_load_count={row.get('extra_load_count')} net={row.get('net')}"
            )
    lines.append("")
    return lines


def write_heatmap(rows: list[dict[str, str]], family: str, path: Path) -> None:
    metrics = defaultdict(dict)
    for row in rows:
        if row.get("family") != family:
            continue
        tap = row.get("tap_index", "")
        for metric in ["total_cap_fF", "estimated_delay_ps", "transition_ps", "wire_length_um"]:
            metrics[metric][tap] = row.get(metric, "")
    with path.open("w", newline="") as fh:
        writer = csv.writer(fh)
        writer.writerow(["metric"] + [str(i) for i in range(8)])
        for metric in ["total_cap_fF", "estimated_delay_ps", "transition_ps", "wire_length_um"]:
            writer.writerow([metric] + [metrics[metric].get(str(i), "") for i in range(8)])


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("csv_file", type=Path)
    parser.add_argument("--out", type=Path)
    parser.add_argument("--slow-heatmap", type=Path)
    parser.add_argument("--fast-heatmap", type=Path)
    args = parser.parse_args()

    rows = list(csv.DictReader(args.csv_file.open()))
    lines = [
        "# Phase Net Balance Summary",
        "",
        f"- Source CSV: `{args.csv_file}`",
        f"- Rows parsed: {len(rows)}",
        "- Status: `PROVISIONAL_REVIEW_REQUIRED`",
        "",
        "Provisional thresholds: cap mismatch target <=2%, warning <=5%, fail >10%; "
        "delay mismatch target <=0.5 ps, warning <=1.0 ps, fail >2.5 ps unless analog approves.",
        "",
    ]
    lines += summarize_family(rows, "slow")
    lines += summarize_family(rows, "fast")
    text = "\n".join(lines)
    if args.out:
        args.out.write_text(text + "\n")
    else:
        print(text)
    if args.slow_heatmap:
        write_heatmap(rows, "slow", args.slow_heatmap)
    if args.fast_heatmap:
        write_heatmap(rows, "fast", args.fast_heatmap)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
