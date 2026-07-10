#!/usr/bin/env python3
"""Build one explicit promotion gate from independent evidence reports."""

from __future__ import annotations

import argparse
import hashlib
from datetime import datetime, timezone
from pathlib import Path


def values(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for line in path.read_text().splitlines():
        if "=" in line and not line.startswith("#"):
            key, value = line.split("=", 1)
            result[key.strip()] = value.strip()
    return result


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--package", required=True, type=Path)
    parser.add_argument("--drc-status", required=True, type=Path)
    parser.add_argument("--lvs-status", required=True, type=Path)
    parser.add_argument("--pg-status", required=True, type=Path)
    parser.add_argument("--contract-status", required=True, type=Path)
    parser.add_argument("--layer-status", required=True, type=Path)
    parser.add_argument("--run-id", default="")
    args = parser.parse_args()
    package = args.package.resolve()
    run_id = args.run_id or datetime.now(timezone.utc).strftime("gate_%Y%m%dT%H%M%SZ")
    output = package / "status" / f"{run_id}.rpt"
    if output.exists():
        raise SystemExit(f"immutable gate exists: {output}")
    drc = values(args.drc_status.resolve())
    lvs = values(args.lvs_status.resolve())
    pg = values(args.pg_status.resolve())
    contract = values(args.contract_status.resolve())
    layer = values(args.layer_status.resolve())
    canonical = values(package / "status" / "qualification.rpt").get("CANONICAL_NAME_STATUS", "UNKNOWN")
    handoff_audit = values(package / "status" / "handoff_audit.rpt").get("STATUS", "UNKNOWN")
    fields = {
        "HANDOFF_AUDIT_STATUS": handoff_audit,
        "CANONICAL_NAME_STATUS": canonical,
        "BBOX_PARITY_STATUS": contract.get("BBOX_PARITY_STATUS", "UNKNOWN"),
        "PIN_PARITY_STATUS": contract.get("PIN_PARITY_STATUS", "UNKNOWN"),
        "GDS_LAYER_MAP_STATUS": layer.get("GDS_LAYER_MAP_STATUS", "UNKNOWN"),
        "INTERNAL_PG_STATUS": pg.get("INTERNAL_PG_STATUS", pg.get("PG_CONNECTIVITY_STATUS", "UNKNOWN")),
        "PVS_DRC_STATUS": drc.get("PVS_DRC_STATUS", "UNKNOWN"),
        "PVS_LVS_STATUS": lvs.get("PVS_LVS_STATUS", "UNKNOWN"),
    }
    expected = {
        "HANDOFF_AUDIT_STATUS": "PASS",
        "CANONICAL_NAME_STATUS": "PASS",
        "BBOX_PARITY_STATUS": "PASS",
        "PIN_PARITY_STATUS": "PASS",
        "GDS_LAYER_MAP_STATUS": "PASS",
        "INTERNAL_PG_STATUS": "PASS",
        "PVS_DRC_STATUS": "PASS",
        "PVS_LVS_STATUS": "MATCH",
    }
    passed = fields == expected
    evidence = {
        "DRC_EVIDENCE": args.drc_status.resolve(),
        "LVS_EVIDENCE": args.lvs_status.resolve(),
        "PG_EVIDENCE": args.pg_status.resolve(),
        "CONTRACT_EVIDENCE": args.contract_status.resolve(),
        "LAYER_MAP_EVIDENCE": args.layer_status.resolve(),
    }
    output.write_text(
        "LABEL=SPADMIC_INNOVUS_HANDOFF_PROMOTION_GATE\n"
        f"STATUS={'PASS' if passed else 'FAIL'}\n"
        f"PACKAGE={package}\n"
        + "".join(f"{key}={value}\n" for key, value in fields.items())
        + "".join(
            f"{key}={path}\n{key}_SHA256={digest(path)}\n"
            for key, path in evidence.items()
        )
        + f"SIGNOFF_READY={'BLOCK_LEVEL_ONLY' if passed else 'NO'}\n"
    )
    print(output.read_text(), end="")
    print(f"GATE_STATUS_FILE={output}")
    if not passed:
        raise SystemExit(8)


if __name__ == "__main__":
    main()
