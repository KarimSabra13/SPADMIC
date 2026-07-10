#!/usr/bin/env python3
"""Compare read-only OA bbox/terminal audit with the canonical macro LEF."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


def normalize_pin(name: str) -> str:
    name = name.strip().lstrip("\\")
    return re.sub(r"<([0-9]+)>", r"[\1]", name)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--oa-report", required=True, type=Path)
    parser.add_argument("--lef", required=True, type=Path)
    parser.add_argument("--status", required=True, type=Path)
    parser.add_argument("--tolerance-um", type=float, default=0.002)
    args = parser.parse_args()
    oa_text = args.oa_report.read_text()
    lef_text = args.lef.read_text(errors="replace")
    oa_bbox_match = re.search(r"^BBOX=([-0-9.]+) ([-0-9.]+) ([-0-9.]+) ([-0-9.]+)$", oa_text, re.M)
    lef_size_match = re.search(r"^\s*SIZE\s+([0-9.]+)\s+BY\s+([0-9.]+)", lef_text, re.M)
    if not oa_bbox_match or not lef_size_match:
        raise SystemExit("OA/LEF bbox records missing")
    box = [float(value) for value in oa_bbox_match.groups()]
    oa_size = (box[2] - box[0], box[3] - box[1])
    lef_size = tuple(float(value) for value in lef_size_match.groups())
    bbox_pass = all(abs(a - b) <= args.tolerance_um for a, b in zip(oa_size, lef_size))

    oa_pins = {normalize_pin(match.group(1)) for match in re.finditer(r"^PIN=([^|]+)\|", oa_text, re.M)}
    lef_pins = {normalize_pin(name) for name in re.findall(r"^\s*PIN\s+(\S+)", lef_text, re.M)}
    missing_oa = sorted(lef_pins - oa_pins)
    extra_oa = sorted(oa_pins - lef_pins)
    pin_pass = not missing_oa and not extra_oa
    status = args.status.resolve()
    if status.exists():
        raise SystemExit(f"immutable contract status exists: {status}")
    status.parent.mkdir(parents=True, exist_ok=True)
    status.write_text(
        "LABEL=SPADMIC_OA_LEF_CONTRACT\n"
        f"STATUS={'PASS' if bbox_pass and pin_pass else 'FAIL'}\n"
        f"BBOX_PARITY_STATUS={'PASS' if bbox_pass else 'FAIL'}\n"
        f"PIN_PARITY_STATUS={'PASS' if pin_pass else 'FAIL'}\n"
        f"OA_SIZE_UM={oa_size[0]:.6f} {oa_size[1]:.6f}\n"
        f"LEF_SIZE_UM={lef_size[0]:.6f} {lef_size[1]:.6f}\n"
        f"OA_PIN_COUNT={len(oa_pins)}\n"
        f"LEF_PIN_COUNT={len(lef_pins)}\n"
        f"MISSING_OA_PINS={' '.join(missing_oa)}\n"
        f"EXTRA_OA_PINS={' '.join(extra_oa)}\n"
    )
    print(status.read_text(), end="")
    if not bbox_pass or not pin_pass:
        raise SystemExit(8)


if __name__ == "__main__":
    main()
