#!/usr/bin/env python3
"""Promote a candidate handoff after explicit physical-verification gates."""

from __future__ import annotations

import argparse
import hashlib
import os
from datetime import datetime, timezone
from pathlib import Path


REQUIRED = {
    "HANDOFF_AUDIT_STATUS": "PASS",
    "CANONICAL_NAME_STATUS": "PASS",
    "BBOX_PARITY_STATUS": "PASS",
    "PIN_PARITY_STATUS": "PASS",
    "GDS_LAYER_MAP_STATUS": "PASS",
    "INTERNAL_PG_STATUS": "PASS",
    "PVS_DRC_STATUS": "PASS",
    "PVS_LVS_STATUS": "MATCH",
}


def read_status(path: Path) -> dict[str, str]:
    result = {}
    for line in path.read_text().splitlines():
        if "=" in line and not line.startswith("#"):
            key, value = line.split("=", 1)
            result[key.strip()] = value.strip()
    return result


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("package", type=Path)
    parser.add_argument("--gate-status", required=True, type=Path)
    args = parser.parse_args()
    package = args.package.resolve()
    gate_path = args.gate_status.resolve()
    gate = read_status(gate_path)
    if gate.get("PACKAGE") != str(package):
        raise SystemExit(
            f"PROMOTION_PACKAGE_MISMATCH: gate={gate.get('PACKAGE', 'MISSING')} package={package}"
        )
    if gate.get("STATUS") != "PASS":
        raise SystemExit(f"PROMOTION_GATE_STATUS_NOT_PASS: {gate.get('STATUS', 'MISSING')}")
    for key in ["DRC_EVIDENCE", "LVS_EVIDENCE", "PG_EVIDENCE", "CONTRACT_EVIDENCE", "LAYER_MAP_EVIDENCE"]:
        evidence = Path(gate.get(key, "")).resolve()
        expected_hash = gate.get(f"{key}_SHA256", "MISSING")
        if not evidence.is_file() or digest(evidence) != expected_hash:
            raise SystemExit(f"PROMOTION_EVIDENCE_HASH_FAIL: {key} path={evidence}")
    failures = [f"{key}={gate.get(key, 'MISSING')} expected={expected}" for key, expected in REQUIRED.items() if gate.get(key) != expected]
    if failures:
        raise SystemExit("PROMOTION_GATE_FAIL: " + "; ".join(failures))

    approved = package / "status" / f"APPROVED_{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}.rpt"
    if list((package / "status").glob("APPROVED_*.rpt")):
        raise SystemExit(f"package already approved: {package}")
    approved.write_text(
        "LABEL=SPADMIC_INNOVUS_HANDOFF_APPROVAL\n"
        "STATUS=APPROVED\n"
        f"GATE_STATUS={gate_path}\n"
        f"GATE_STATUS_SHA256={digest(gate_path)}\n"
        f"APPROVED_UTC={datetime.now(timezone.utc).isoformat()}\n"
        "SIGNOFF_READY=BLOCK_LEVEL_ONLY\n"
    )
    current = package.parent / "current"
    temporary = package.parent / ".current.new"
    if temporary.exists() or temporary.is_symlink():
        temporary.unlink()
    temporary.symlink_to(package.name)
    os.replace(temporary, current)
    print(f"APPROVAL={approved}")
    print(f"CURRENT={current}")
    print("PROMOTION_STATUS=PASS")


if __name__ == "__main__":
    main()
