#!/usr/bin/env python3
"""Generate a PVS LVS source netlist from an Innovus PG-aware Verilog netlist.

The Innovus netlist can include foundry standard-cell module definitions. PVS
LVS should use the foundry CDL for those cells, so this helper removes matching
Verilog module definitions and appends a simple RO_tune6 LVS wrapper plus an
HCell mapping file.
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path
from typing import Iterable


DEFAULT_REMOVE_REGEX = r".*JIHD.*|ANTENNACELL.*"
RO_WRAPPER = """\

module RO_tune6 (VDD, VSS, rstb, code, S);
  inout VDD;
  inout VSS;
  inout rstb;
  inout [7:0] code;
  inout [7:0] S;
endmodule
"""


def iter_filtered_modules(text: str, remove_re: re.Pattern[str]) -> tuple[str, list[str]]:
    module_start_re = re.compile(r"^\s*module\s+([A-Za-z_\\][^\s(;]*)", re.MULTILINE)
    chunks: list[str] = []
    removed: list[str] = []
    pos = 0

    for match in module_start_re.finditer(text):
        start = match.start()
        name = match.group(1).strip()
        end_match = re.search(r"^\s*endmodule\b.*$", text[match.end():], re.MULTILINE)
        if end_match is None:
            continue
        end = match.end() + end_match.end()

        chunks.append(text[pos:start])
        if name == "RO_tune6" or remove_re.fullmatch(name):
            removed.append(name)
        else:
            chunks.append(text[start:end])
        pos = end

    chunks.append(text[pos:])
    return "".join(chunks), removed


def normalize_blank_lines(text: str) -> str:
    text = re.sub(r"\n{4,}", "\n\n\n", text)
    return text.rstrip() + "\n"


def write_lines(path: Path, lines: Iterable[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path, help="Innovus PG-aware Verilog")
    parser.add_argument("--output", required=True, type=Path, help="Filtered Verilog output")
    parser.add_argument("--hcell", required=True, type=Path, help="PVS HCell output")
    parser.add_argument("--report", required=True, type=Path, help="Filtering report")
    parser.add_argument(
        "--remove-regex",
        default=DEFAULT_REMOVE_REGEX,
        help=f"Module-name regex to remove. Default: {DEFAULT_REMOVE_REGEX}",
    )
    args = parser.parse_args()

    if not args.input.is_file():
        raise SystemExit(f"ERROR: input netlist not found: {args.input}")

    text = args.input.read_text(encoding="utf-8", errors="replace")
    remove_re = re.compile(args.remove_regex)
    filtered, removed = iter_filtered_modules(text, remove_re)
    filtered = normalize_blank_lines(filtered)
    filtered += RO_WRAPPER

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(filtered, encoding="utf-8")
    write_lines(args.hcell, ["RO_tune6 RO_tune6"])

    report_lines = [
        "# MPTDC PVS LVS Source Filter",
        f"INPUT={args.input}",
        f"OUTPUT={args.output}",
        f"HCELL={args.hcell}",
        f"REMOVE_REGEX={args.remove_regex}",
        f"REMOVED_MODULE_COUNT={len(removed)}",
    ]
    for name in removed:
        report_lines.append(f"REMOVED_MODULE={name}")
    report_lines.append("RO_TUNE6_WRAPPER_APPENDED=1")
    write_lines(args.report, report_lines)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
