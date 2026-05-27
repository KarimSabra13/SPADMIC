#!/usr/bin/env python3
"""Analyze oscillator tap load CSV reports from O0 Innovus runs."""

from __future__ import annotations

import argparse
import csv
from pathlib import Path


def to_float(value: str) -> float | None:
    try:
        if value == "":
            return None
        return float(value)
    except ValueError:
        return None


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("tap_loads_csv", type=Path)
    parser.add_argument("--nfast-csv", type=Path)
    parser.add_argument("--out", type=Path)
    args = parser.parse_args()

    rows = list(csv.DictReader(args.tap_loads_csv.open()))
    lines = [
        "# Oscillator Tap Load Balance Summary",
        "",
        f"- Source CSV: `{args.tap_loads_csv}`",
        f"- Rows parsed: {len(rows)}",
        "- Status: `PROVISIONAL_REVIEW_REQUIRED`",
        "",
    ]
    for family in ["slow", "fast"]:
        fam = [r for r in rows if r.get("family") == family]
        caps = [v for r in fam if (v := to_float(r.get("total_cap_fF", ""))) is not None]
        extra = [r for r in fam if (to_float(r.get("extra_load_count", "")) or 0.0) > 0.0]
        lines.append(f"## {family.title()} Taps")
        lines.append("")
        lines.append(f"- Rows: {len(fam)}")
        if caps:
            avg = sum(caps) / len(caps)
            spread = 0.0 if avg == 0 else 100.0 * (max(caps) - min(caps)) / avg
            lines.append(f"- Total cap fF: min={min(caps):.3f}, max={max(caps):.3f}, spread={spread:.2f}%")
        else:
            lines.append("- Total cap fF: not reported")
        lines.append(f"- Taps with extra non-PD loads: {len(extra)}")
        for row in extra:
            lines.append(f"  - tap {row.get('tap_index')}: {row.get('extra_load_notes', '')}")
        lines.append("")

    if args.nfast_csv and args.nfast_csv.exists():
        nfast_rows = list(csv.DictReader(args.nfast_csv.open()))
        bit_caps = [v for r in nfast_rows if (v := to_float(r.get("total_cap_fF", ""))) is not None]
        lines.extend(["## nfast_src_count Bus", ""])
        lines.append(f"- Rows: {len(nfast_rows)}")
        if bit_caps:
            avg = sum(bit_caps) / len(bit_caps)
            spread = 0.0 if avg == 0 else 100.0 * (max(bit_caps) - min(bit_caps)) / avg
            lines.append(f"- Bit cap fF: min={min(bit_caps):.3f}, max={max(bit_caps):.3f}, spread={spread:.2f}%")
        else:
            lines.append("- Bit cap fF: not reported")
        lines.append("")

    text = "\n".join(lines) + "\n"
    if args.out:
        args.out.write_text(text)
    else:
        print(text, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
