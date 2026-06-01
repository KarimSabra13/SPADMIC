#!/usr/bin/env python3
"""Summarize fast-counter to PD nfast_hit timing paths from Genus reports."""

from __future__ import annotations

import argparse
import csv
import re
from collections import Counter, defaultdict
from pathlib import Path


TAP_RE = re.compile(r"gen_pd_col\[(\d+)\]")
ROW_RE = re.compile(r"gen_pd_row\[(\d+)\]")
END_BIT_RE = re.compile(r"nfast_hit_latched_reg\[(\d+)\]")
START_BIT_RE = re.compile(r"bin_q_reg\[(\d+)\]")


def read_rows(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        return []
    with path.open(newline="") as fh:
        return list(csv.DictReader(fh))


def extract(pattern: re.Pattern[str], text: str) -> str:
    match = pattern.search(text)
    return match.group(1) if match else "unknown"


def is_fast_count_capture(row: dict[str, str]) -> bool:
    text = " ".join(row.get(key, "") for key in ("classification", "startpoint", "endpoint", "group", "start_clock", "end_clock"))
    return (
        "OSC_FAST_REAL" in text
        and "u_fast_cnt" in text
        and "nfast_hit_latched" in text
    )


def build_capture_rows(rows: list[dict[str, str]]) -> list[dict[str, str]]:
    out: list[dict[str, str]] = []
    for row in rows:
        if not is_fast_count_capture(row):
            continue
        endpoint = row.get("endpoint", "")
        startpoint = row.get("startpoint", "")
        out.append(
            {
                "slack_ps": row.get("slack_ps", ""),
                "group": row.get("group", ""),
                "start_clock": row.get("start_clock", ""),
                "end_clock": row.get("end_clock", ""),
                "pd_row_ns": extract(ROW_RE, endpoint),
                "pd_col_nf": extract(TAP_RE, endpoint),
                "start_bit": extract(START_BIT_RE, startpoint),
                "end_bit": extract(END_BIT_RE, endpoint),
                "startpoint": startpoint,
                "endpoint": endpoint,
                "report": row.get("report", ""),
                "path": row.get("path", ""),
            }
        )
    return out


def slack_value(row: dict[str, str]) -> float:
    try:
        return float(row.get("slack_ps", "nan"))
    except ValueError:
        return float("nan")


def worst_by(rows: list[dict[str, str]], field: str) -> list[tuple[str, int, float]]:
    buckets: dict[str, list[float]] = defaultdict(list)
    for row in rows:
        buckets[row.get(field, "unknown")].append(slack_value(row))
    result = []
    for key, values in buckets.items():
        finite = [value for value in values if value == value]
        worst = min(finite) if finite else float("nan")
        result.append((key, len(values), worst))
    return sorted(result, key=lambda item: (item[2] != item[2], item[2], item[0]))


def write_csv(rows: list[dict[str, str]], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fields = [
        "slack_ps",
        "group",
        "start_clock",
        "end_clock",
        "pd_row_ns",
        "pd_col_nf",
        "start_bit",
        "end_bit",
        "startpoint",
        "endpoint",
        "report",
        "path",
    ]
    with path.open("w", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=fields)
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fields})


def write_summary(rows: list[dict[str, str]], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    group_counts = Counter(row.get("group", "") for row in rows)
    worst = min((slack_value(row) for row in rows), default=float("nan"))
    lines = [
        "# Fast Count Capture Summary",
        "",
        f"- Parsed fast-counter to nfast_hit paths: `{len(rows)}`",
        f"- Worst slack: `{worst:.1f} ps`" if worst == worst else "- Worst slack: `unknown`",
        "",
        "## By Timing Group",
        "",
        "| Group | Paths |",
        "|---|---:|",
    ]
    for group, count in group_counts.most_common():
        lines.append(f"| `{group}` | {count} |")

    for title, field in [
        ("By Fast Tap / PD Column", "pd_col_nf"),
        ("By Slow Tap / PD Row", "pd_row_ns"),
        ("By Fast Counter Launch Bit", "start_bit"),
        ("By nfast_hit Capture Bit", "end_bit"),
    ]:
        lines.extend(["", f"## {title}", "", "| Key | Paths | Worst Slack (ps) |", "|---|---:|---:|"])
        for key, count, key_worst in worst_by(rows, field):
            worst_text = f"{key_worst:.1f}" if key_worst == key_worst else "unknown"
            lines.append(f"| `{key}` | {count} | {worst_text} |")

    lines.extend(["", "## Worst 20 Paths", ""])
    for row in sorted(rows, key=slack_value)[:20]:
        lines.append(
            f"- slack `{row.get('slack_ps')} ps`, group `{row.get('group')}`, "
            f"nf `{row.get('pd_col_nf')}`, ns `{row.get('pd_row_ns')}`, "
            f"bit `{row.get('start_bit')}`: `{row.get('startpoint')}` -> `{row.get('endpoint')}`"
        )

    path.write_text("\n".join(lines) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("run_dir", type=Path)
    parser.add_argument("--input-csv", type=Path)
    parser.add_argument("--out-csv", type=Path)
    parser.add_argument("--out-summary", type=Path)
    args = parser.parse_args()

    input_csv = args.input_csv or args.run_dir / "timing_path_classification.csv"
    out_csv = args.out_csv or args.run_dir / "fast_count_capture_paths.csv"
    out_summary = args.out_summary or args.run_dir / "fast_count_capture_summary.md"

    rows = build_capture_rows(read_rows(input_csv))
    write_csv(rows, out_csv)
    write_summary(rows, out_summary)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
