#!/usr/bin/env python3
"""Derive packet-core internal PG status from OA pins and a PVS LVS MATCH."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


def key(path: Path, name: str) -> str:
    match = re.search(rf"^{re.escape(name)}=(.*)$", path.read_text(), re.M)
    return match.group(1).strip() if match else "MISSING"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--oa-report", required=True, type=Path)
    parser.add_argument("--lvs-status", required=True, type=Path)
    parser.add_argument("--status", required=True, type=Path)
    args = parser.parse_args()
    oa = args.oa_report.read_text()
    lvs = key(args.lvs_status, "PVS_LVS_STATUS")
    pins = set(re.findall(r"^PIN=([^|]+)\|", oa, re.M))
    passed = lvs == "MATCH" and {"VDD", "VSS"}.issubset(pins)
    args.status.parent.mkdir(parents=True, exist_ok=True)
    if args.status.exists():
        raise SystemExit(f"immutable PG status exists: {args.status}")
    args.status.write_text(
        "LABEL=SPADMIC_OA_INTERNAL_PG_GATE\n"
        f"STATUS={'PASS' if passed else 'FAIL'}\n"
        f"INTERNAL_PG_STATUS={'PASS' if passed else 'FAIL'}\n"
        f"PVS_LVS_STATUS={lvs}\n"
        f"OA_VDD_PIN_STATUS={'PASS' if 'VDD' in pins else 'FAIL'}\n"
        f"OA_VSS_PIN_STATUS={'PASS' if 'VSS' in pins else 'FAIL'}\n"
        "NOTE=LVS_MATCH_is_required_to_prove_internal_rail_connectivity_to_boundary_PG_pins\n"
    )
    print(args.status.read_text(), end="")
    if not passed:
        raise SystemExit(8)


if __name__ == "__main__":
    main()
