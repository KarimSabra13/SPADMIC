#!/usr/bin/env python3
"""Audit XH018 buffer input capacitance against the O12 analog load budget."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


STRICT_BUDGET_FF = 58.72
CN_BUDGET_FF = 75.59
DEFAULT_CELLS = ("BUHDX4", "BUHDX6", "BUHDX8", "BUHDX12")


def _strip_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return re.sub(r"//.*", "", text)


def _find_block(text: str, header_regex: str) -> str | None:
    match = re.search(header_regex, text)
    if not match:
        return None
    brace = text.find("{", match.end())
    if brace < 0:
        return None

    depth = 0
    for idx in range(brace, len(text)):
        char = text[idx]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return text[brace + 1 : idx]
    return None


def _first_float(block: str, names: tuple[str, ...]) -> float | None:
    for name in names:
        match = re.search(rf"\b{re.escape(name)}\s*:\s*([-+0-9.eE]+)\s*;", block)
        if match:
            return float(match.group(1))
    return None


def audit_cell(text: str, cell: str, pin: str) -> dict[str, object]:
    cell_block = _find_block(text, rf"\bcell\s*\(\s*{re.escape(cell)}\s*\)\s*")
    if cell_block is None:
        return {
            "cell": cell,
            "pin": pin,
            "cap_pf": None,
            "cap_ff": None,
            "strict_ratio": None,
            "cn_ratio": None,
            "status": "CELL_NOT_FOUND",
        }

    pin_block = _find_block(cell_block, rf"\bpin\s*\(\s*{re.escape(pin)}\s*\)\s*")
    if pin_block is None:
        return {
            "cell": cell,
            "pin": pin,
            "cap_pf": None,
            "cap_ff": None,
            "strict_ratio": None,
            "cn_ratio": None,
            "status": "PIN_NOT_FOUND",
        }

    cap_pf = _first_float(
        pin_block,
        (
            "capacitance",
            "rise_capacitance",
            "fall_capacitance",
            "max_capacitance",
        ),
    )
    if cap_pf is None:
        return {
            "cell": cell,
            "pin": pin,
            "cap_pf": None,
            "cap_ff": None,
            "strict_ratio": None,
            "cn_ratio": None,
            "status": "CAP_NOT_FOUND",
        }

    cap_ff = cap_pf * 1000.0
    strict_ratio = cap_ff / STRICT_BUDGET_FF
    cn_ratio = cap_ff / CN_BUDGET_FF
    if cap_ff <= STRICT_BUDGET_FF:
        status = "OK_STRICT"
    elif cap_ff <= CN_BUDGET_FF:
        status = "OK_CN"
    else:
        status = "OVER_ANALOG_BUDGET"

    return {
        "cell": cell,
        "pin": pin,
        "cap_pf": cap_pf,
        "cap_ff": cap_ff,
        "strict_ratio": strict_ratio,
        "cn_ratio": cn_ratio,
        "status": status,
    }


def format_markdown(rows: list[dict[str, object]], liberty: Path) -> str:
    lines = [
        "# O12C Buffer Input Cap Audit",
        "",
        "REPORT_STATUS=REVIEW_REQUIRED",
        "",
        f"- Liberty: `{liberty}`",
        f"- Strict RO D-input budget: `{STRICT_BUDGET_FF:.2f} fF`.",
        f"- CN/clock-like budget: `{CN_BUDGET_FF:.2f} fF`.",
        "",
        "| Cell | Pin | Cap pF | Cap fF | Strict Ratio | CN Ratio | Status |",
        "|---|---|---:|---:|---:|---:|---|",
    ]
    for row in rows:
        cap_pf = row["cap_pf"]
        cap_ff = row["cap_ff"]
        strict = row["strict_ratio"]
        cn = row["cn_ratio"]
        lines.append(
            "| {cell} | {pin} | {cap_pf} | {cap_ff} | {strict} | {cn} | {status} |".format(
                cell=row["cell"],
                pin=row["pin"],
                cap_pf="" if cap_pf is None else f"{cap_pf:.6g}",
                cap_ff="" if cap_ff is None else f"{cap_ff:.2f}",
                strict="" if strict is None else f"{strict:.2f}",
                cn="" if cn is None else f"{cn:.2f}",
                status=row["status"],
            )
        )
    lines.extend(
        [
            "",
            "Use a stronger single-stage phase buffer only if its input cap stays inside the chosen analog budget.",
            "If a stronger cell exceeds the first-stage budget, evaluate a two-stage topology with a small isolation buffer first.",
        ]
    )
    return "\n".join(lines) + "\n"


def format_csv(rows: list[dict[str, object]], liberty: Path) -> str:
    lines = [
        "liberty,cell,pin,cap_pf,cap_ff,strict_ratio,cn_ratio,status",
    ]
    for row in rows:
        cap_pf = row["cap_pf"]
        cap_ff = row["cap_ff"]
        strict = row["strict_ratio"]
        cn = row["cn_ratio"]
        lines.append(
            "{liberty},{cell},{pin},{cap_pf},{cap_ff},{strict},{cn},{status}".format(
                liberty=liberty,
                cell=row["cell"],
                pin=row["pin"],
                cap_pf="" if cap_pf is None else f"{cap_pf:.8g}",
                cap_ff="" if cap_ff is None else f"{cap_ff:.3f}",
                strict="" if strict is None else f"{strict:.4f}",
                cn="" if cn is None else f"{cn:.4f}",
                status=row["status"],
            )
        )
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("liberty", type=Path, help="Timing Liberty file to audit")
    parser.add_argument(
        "--cells",
        nargs="+",
        default=list(DEFAULT_CELLS),
        help="Buffer cells to audit",
    )
    parser.add_argument("--pin", default="A", help="Input pin to audit")
    parser.add_argument("--csv", action="store_true", help="Emit CSV instead of Markdown")
    parser.add_argument("--output", type=Path, help="Optional output path")
    args = parser.parse_args()

    text = _strip_comments(args.liberty.read_text(errors="ignore"))
    rows = [audit_cell(text, cell, args.pin) for cell in args.cells]
    output = format_csv(rows, args.liberty) if args.csv else format_markdown(rows, args.liberty)

    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(output)
    else:
        print(output, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
