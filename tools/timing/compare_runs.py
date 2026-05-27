#!/usr/bin/env python3
"""Compare timing group summaries between two checked-in Genus runs."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from parse_genus_summary import parse_timing_summary  # noqa: E402


def fmt(value: object) -> str:
    if value is None:
        return "No paths"
    if isinstance(value, float):
        return f"{value:.1f}"
    return str(value)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("base_run", type=Path)
    parser.add_argument("new_run", type=Path)
    args = parser.parse_args()

    base = parse_timing_summary(args.base_run)["groups"]
    new = parse_timing_summary(args.new_run)["groups"]
    groups = sorted(set(base) | set(new))

    print("| Group | Base WNS (ps) | New WNS (ps) | Delta WNS (ps) | Base TNS | New TNS | Base Paths | New Paths |")
    print("|---|---:|---:|---:|---:|---:|---:|---:|")
    for group in groups:
        b = base.get(group, {})
        n = new.get(group, {})
        b_wns = b.get("wns_ps")
        n_wns = n.get("wns_ps")
        delta = None if b_wns is None or n_wns is None else n_wns - b_wns
        print(
            f"| `{group}` | {fmt(b_wns)} | {fmt(n_wns)} | {fmt(delta)} | "
            f"{fmt(b.get('tns_ps', ''))} | {fmt(n.get('tns_ps', ''))} | "
            f"{fmt(b.get('paths', ''))} | {fmt(n.get('paths', ''))} |"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
