#!/usr/bin/env python3
"""Classify the exact RO_tune6 standalone VDD-only LVS mismatch."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


EXPECTED_CORRESPONDENCES = {
    *(f"code<{index}>" for index in range(8)),
    *(f"S<{index}>" for index in range(8)),
    "rstb",
    "VSS",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--cls", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    return parser.parse_args()


def match_int(pattern: str, text: str) -> int | None:
    match = re.search(pattern, text, re.MULTILINE)
    return int(match.group(1).replace(",", "")) if match else None


def section(text: str, start: str, end: str) -> str:
    start_index = text.find(start)
    if start_index < 0:
        return ""
    end_index = text.find(end, start_index + len(start))
    if end_index < 0:
        end_index = len(text)
    return text[start_index:end_index]


def main() -> int:
    args = parse_args()
    errors: list[str] = []

    try:
        text = args.cls.read_text(encoding="utf-8", errors="replace")
    except OSError as exc:
        text = ""
        errors.append(f"CLS_READ_FAILED:{exc}")

    result_match = re.search(r"Run Result\s*:\s*(\S+)", text)
    run_result = result_match.group(1).upper() if result_match else "MISSING"
    top_pair_status = (
        "PASS"
        if re.search(r"Top Cell\s*:\s*RO_tune6\s+<vs>\s+RO_tune6", text)
        else "FAIL"
    )
    blackboxed = match_int(r"Cells that have been blackboxed\s*\|\s*([\d,]+)", text)

    cell_summary = re.search(
        r"^RO_tune6\s*\|\s*\*?(\d+)\s*:\s*(\d+)\s*"
        r"\|\s*\*?(\d+)\s*:\s*(\d+)\s*\|\s*(\w+)",
        text,
        re.MULTILINE,
    )
    if cell_summary:
        initial_layout_pins = int(cell_summary.group(1))
        initial_schematic_pins = int(cell_summary.group(2))
        compare_layout_pins = int(cell_summary.group(3))
        compare_schematic_pins = int(cell_summary.group(4))
        cell_status = cell_summary.group(5).lower()
    else:
        initial_layout_pins = initial_schematic_pins = -1
        compare_layout_pins = compare_schematic_pins = -1
        cell_status = "missing"

    totals = re.search(
        r"^Total\s*\|\s*([\d,]+)\s*:\s*([\d,]+)\s*"
        r"\|\s*([\d,]+)\s*:\s*([\d,]+)\s*"
        r"\|\s*([\d,]+)\s*:\s*([\d,]+)\s*"
        r"\|\s*([\d,]+)\s*:\s*([\d,]+)\s*$",
        text,
        re.MULTILINE,
    )
    if totals:
        reduced_layout_devices = int(totals.group(5).replace(",", ""))
        reduced_schematic_devices = int(totals.group(6).replace(",", ""))
        unmatched_layout_devices = int(totals.group(7).replace(",", ""))
        unmatched_schematic_devices = int(totals.group(8).replace(",", ""))
    else:
        reduced_layout_devices = reduced_schematic_devices = -1
        unmatched_layout_devices = unmatched_schematic_devices = -1

    pin_stats = re.search(
        r"^Pins\s*\|.*?\|.*?\|\s*\*?(\d+)\s*:\s*(\d+)\s*"
        r"\|\s*(\d+)\s*:\s*(\d+)\s*$",
        text,
        re.MULTILINE,
    )
    net_stats = re.search(
        r"^Nets\s*\|.*?\|.*?\|\s*\*?(\d+)\s*:\s*(\d+)\s*"
        r"\|\s*(\d+)\s*:\s*(\d+)\s*$",
        text,
        re.MULTILINE,
    )
    if pin_stats:
        reduced_layout_pins = int(pin_stats.group(1))
        reduced_schematic_pins = int(pin_stats.group(2))
    else:
        reduced_layout_pins = reduced_schematic_pins = -1
    if net_stats:
        reduced_layout_nets = int(net_stats.group(1))
        reduced_schematic_nets = int(net_stats.group(2))
    else:
        reduced_layout_nets = reduced_schematic_nets = -1

    correspondence_text = section(
        text, "INITIAL CORRESPONDENCES", "UNMATCHED SCHEMATIC PIN LABELS"
    )
    found_correspondences = {
        pin for pin in EXPECTED_CORRESPONDENCES if pin in correspondence_text
    }

    unmatched_text = section(
        text, "UNMATCHED SCHEMATIC PIN LABELS", "END OF REPORT"
    )
    unmatched_rows: list[tuple[str, str, str]] = []
    for line in unmatched_text.splitlines():
        if "|" not in line or line.lstrip().startswith(("Labeled ", "---", "+")):
            continue
        columns = [column.strip() for column in line.split("|")]
        if len(columns) == 3 and columns[0]:
            unmatched_rows.append((columns[0], columns[1], columns[2]))

    vdd_only = (
        len(unmatched_rows) == 1
        and unmatched_rows[0][0] == "VDD"
        and "missing pin" in unmatched_rows[0][1].lower()
        and unmatched_rows[0][2] == "12"
    )

    checks = {
        "RUN_RESULT_MISMATCH": run_result == "MISMATCH",
        "TOP_CELL_PAIR": top_pair_status == "PASS",
        "NO_BLACKBOX": blackboxed == 0,
        "CELL_PIN_COUNTS": (
            initial_layout_pins,
            initial_schematic_pins,
            compare_layout_pins,
            compare_schematic_pins,
            cell_status,
        )
        == (18, 19, 18, 19, "mismatch"),
        "REDUCED_DEVICE_PARITY": (
            reduced_layout_devices,
            reduced_schematic_devices,
            unmatched_layout_devices,
            unmatched_schematic_devices,
        )
        == (190, 190, 0, 0),
        "REDUCED_PIN_COUNTS": (reduced_layout_pins, reduced_schematic_pins)
        == (18, 19),
        "REDUCED_NET_COUNTS": (reduced_layout_nets, reduced_schematic_nets)
        == (45, 44),
        "NON_VDD_CORRESPONDENCES": found_correspondences
        == EXPECTED_CORRESPONDENCES,
        "VDD_ONLY_MISSING_PIN": vdd_only,
    }
    for name, passed in checks.items():
        if not passed:
            errors.append(f"CHECK_FAILED:{name}")

    status = "PASS" if not errors else "FAIL"
    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w", encoding="utf-8") as report:
        report.write("STEP=RO6_STANDALONE_VDD_MISMATCH_CLASSIFICATION\n")
        report.write(f"CLS_FILE={args.cls.resolve()}\n")
        report.write(f"CLS_RUN_RESULT={run_result}\n")
        report.write(f"CLS_TOP_CELL_PAIR_STATUS={top_pair_status}\n")
        report.write(
            "CLS_BLACKBOXED_CELL_COUNT="
            f"{blackboxed if blackboxed is not None else 'MISSING'}\n"
        )
        report.write(f"CLS_INITIAL_LAYOUT_PIN_COUNT={initial_layout_pins}\n")
        report.write(f"CLS_INITIAL_SCHEMATIC_PIN_COUNT={initial_schematic_pins}\n")
        report.write(f"CLS_COMPARE_LAYOUT_PIN_COUNT={compare_layout_pins}\n")
        report.write(f"CLS_COMPARE_SCHEMATIC_PIN_COUNT={compare_schematic_pins}\n")
        report.write(f"CLS_REDUCED_LAYOUT_DEVICE_COUNT={reduced_layout_devices}\n")
        report.write(f"CLS_REDUCED_SCHEMATIC_DEVICE_COUNT={reduced_schematic_devices}\n")
        report.write(f"CLS_UNMATCHED_LAYOUT_DEVICE_COUNT={unmatched_layout_devices}\n")
        report.write(
            f"CLS_UNMATCHED_SCHEMATIC_DEVICE_COUNT={unmatched_schematic_devices}\n"
        )
        report.write(f"CLS_REDUCED_LAYOUT_PIN_COUNT={reduced_layout_pins}\n")
        report.write(f"CLS_REDUCED_SCHEMATIC_PIN_COUNT={reduced_schematic_pins}\n")
        report.write(f"CLS_REDUCED_LAYOUT_NET_COUNT={reduced_layout_nets}\n")
        report.write(f"CLS_REDUCED_SCHEMATIC_NET_COUNT={reduced_schematic_nets}\n")
        report.write(
            "CLS_NON_VDD_INITIAL_CORRESPONDENCE_COUNT="
            f"{len(found_correspondences)}\n"
        )
        report.write(f"CLS_UNMATCHED_SCHEMATIC_PIN_COUNT={len(unmatched_rows)}\n")
        if unmatched_rows:
            report.write(f"CLS_UNMATCHED_SCHEMATIC_PIN={unmatched_rows[0][0]}\n")
            report.write(
                "CLS_VDD_MATCHED_LAYOUT_PIN_STATUS="
                f"{'MISSING' if 'missing pin' in unmatched_rows[0][1].lower() else 'PRESENT'}\n"
            )
            report.write(f"CLS_VDD_MATCHED_LAYOUT_NET={unmatched_rows[0][2]}\n")
        else:
            report.write("CLS_UNMATCHED_SCHEMATIC_PIN=MISSING\n")
            report.write("CLS_VDD_MATCHED_LAYOUT_PIN_STATUS=MISSING\n")
            report.write("CLS_VDD_MATCHED_LAYOUT_NET=MISSING\n")
        report.write(
            f"CLS_VDD_ONLY_MISSING_PIN_STATUS={'PASS' if vdd_only else 'FAIL'}\n"
        )
        report.write(f"ERROR_COUNT={len(errors)}\n")
        for index, error in enumerate(errors, start=1):
            report.write(f"ERROR_{index}={error}\n")
        report.write(f"RO6_STANDALONE_MISMATCH_CLASSIFICATION={status}\n")

    return 0 if status == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
