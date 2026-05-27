#!/usr/bin/env python3
"""Parse checked-in Innovus summary/path reports when server results exist."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


def read_text(path: Path) -> str:
    try:
        return path.read_text(errors="replace")
    except FileNotFoundError:
        return ""


def first_metric(text: str, name: str) -> str:
    patterns = [
        rf"\b{name}\b\s*[:=]\s*(-?\d+(?:\.\d+)?)",
        rf"\b{name}\b.*?(-?\d+(?:\.\d+)?)",
    ]
    for pattern in patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            return match.group(1)
    return "not found"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("run_dir", type=Path, help="results/innovus/<RUN_ID> directory")
    args = parser.parse_args()

    reports = [
        "timing_preCTS.rpt",
        "timing_postCTS.rpt",
        "timing_postRoute.rpt",
        "timing_hold_postCTS.rpt",
        "timing_hold_postRoute.rpt",
    ]
    print(f"# Innovus Summary: `{args.run_dir.name}`")
    print()
    print("| Report | WNS | TNS | Violating Paths |")
    print("|---|---:|---:|---:|")
    for report in reports:
        text = read_text(args.run_dir / report)
        print(
            f"| `{report}` | {first_metric(text, 'WNS')} | "
            f"{first_metric(text, 'TNS')} | {first_metric(text, 'paths')} |"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
