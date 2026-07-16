#!/usr/bin/env python3
"""Promote one immutable package after every independent gate is attributable."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from datetime import datetime, timezone
from pathlib import Path


EXACT_REQUIRED = {
    "HANDOFF_AUDIT_STATUS": "PASS",
    "CANONICAL_NAME_STATUS": "PASS",
    "BBOX_PARITY_STATUS": "PASS",
    "PIN_PARITY_STATUS": "PASS",
    "GDS_LAYER_MAP_STATUS": "PASS",
    "GDS_MERGE_STATUS": "PASS",
    "INTERNAL_PG_STATUS": "PASS",
    "TC_TIMING_STATUS": "PASS",
    "PVS_LVS_STATUS": "MATCH",
}
DRC_REQUIRED = ("PVS_BASE_DRC_STATUS", "PVS_DENSITY_DRC_STATUS")
EVIDENCE_KEYS = (
    "BASE_DRC_EVIDENCE",
    "DENSITY_DRC_EVIDENCE",
    "LVS_EVIDENCE",
    "PG_EVIDENCE",
    "CONTRACT_EVIDENCE",
    "LAYER_MAP_EVIDENCE",
    "TIMING_EVIDENCE",
    "QUALIFICATION_EVIDENCE",
    "HANDOFF_AUDIT_EVIDENCE",
    "LVS_SOURCE_EVIDENCE",
)


def read_status(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for line in path.read_text(errors="replace").splitlines():
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

    expected_gate_dir = package / "status"
    if gate_path.parent != expected_gate_dir:
        raise SystemExit(
            f"PROMOTION_GATE_LOCATION_FAIL: gate={gate_path} expected_dir={expected_gate_dir}"
        )
    if gate.get("LABEL") != "SPADMIC_INNOVUS_HANDOFF_PROMOTION_GATE":
        raise SystemExit(
            f"PROMOTION_GATE_LABEL_FAIL: {gate.get('LABEL', 'MISSING')}"
        )
    if gate.get("PACKAGE") != str(package):
        raise SystemExit(
            f"PROMOTION_PACKAGE_MISMATCH: gate={gate.get('PACKAGE', 'MISSING')} package={package}"
        )
    if gate.get("STATUS") != "PASS":
        raise SystemExit(f"PROMOTION_GATE_STATUS_NOT_PASS: {gate.get('STATUS', 'MISSING')}")

    evidence_keys = list(EVIDENCE_KEYS)
    if gate.get("FORMAL_DRC_WAIVER_STATUS") == "PASS":
        evidence_keys.append("FORMAL_WAIVER_EVIDENCE")
    for key in evidence_keys:
        evidence = Path(gate.get(key, "")).resolve()
        expected_hash = gate.get(f"{key}_SHA256", "MISSING")
        if not evidence.is_file() or digest(evidence) != expected_hash:
            raise SystemExit(f"PROMOTION_EVIDENCE_HASH_FAIL: {key} path={evidence}")

    failures = [
        f"{key}={gate.get(key, 'MISSING')} expected={expected}"
        for key, expected in EXACT_REQUIRED.items()
        if gate.get(key) != expected
    ]
    for key in DRC_REQUIRED:
        if gate.get(key) not in {"PASS", "FORMALLY_WAIVED"}:
            failures.append(
                f"{key}={gate.get(key, 'MISSING')} expected=PASS_OR_FORMALLY_WAIVED"
            )
    waived = any(gate.get(key) == "FORMALLY_WAIVED" for key in DRC_REQUIRED)
    if waived and gate.get("FORMAL_DRC_WAIVER_STATUS") != "PASS":
        failures.append("FORMAL_DRC_WAIVER_STATUS must be PASS for waived DRC")
    try:
        manifest = json.loads((package / "manifests" / "package.json").read_text())
        expected_block = str(manifest["name"])
        expected_gds = (
            package / "gds" / f"{str(manifest['layout_top'])}.gds"
        ).resolve()
        expected_lvs_source = (
            package / "netlist" / f"{str(manifest['source_top'])}.lvs.pg.v"
        ).resolve()
    except (OSError, KeyError, json.JSONDecodeError) as error:
        failures.append(f"package_identity={error}")
        expected_block = ""
        expected_gds = None
        expected_lvs_source = None
    if expected_block and gate.get("BLOCK") != expected_block:
        failures.append(
            f"BLOCK={gate.get('BLOCK', 'MISSING')} expected={expected_block}"
        )
    gate_gds_value = gate.get("GDS", "")
    gate_gds = Path(gate_gds_value).resolve() if gate_gds_value else None
    if gate_gds is None or not gate_gds.is_file():
        failures.append(f"GDS={gate_gds_value or 'MISSING'} expected_existing_file")
    elif expected_gds is not None and gate_gds != expected_gds:
        failures.append(f"GDS={gate_gds} expected={expected_gds}")
    elif digest(gate_gds) != gate.get("GDS_SHA256"):
        failures.append("GDS_SHA256 no longer matches gate GDS")
    gate_source_value = gate.get("LVS_SOURCE", "")
    gate_source = Path(gate_source_value).resolve() if gate_source_value else None
    if gate_source is None or not gate_source.is_file():
        failures.append(
            f"LVS_SOURCE={gate_source_value or 'MISSING'} expected_existing_file"
        )
    elif expected_lvs_source is not None and gate_source != expected_lvs_source:
        failures.append(f"LVS_SOURCE={gate_source} expected={expected_lvs_source}")
    elif digest(gate_source) != gate.get("LVS_SOURCE_SHA256"):
        failures.append("LVS_SOURCE_SHA256 no longer matches gate source")
    if failures:
        raise SystemExit("PROMOTION_GATE_FAIL: " + "; ".join(failures))

    approved = package / "status" / (
        f"APPROVED_{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}.rpt"
    )
    if list((package / "status").glob("APPROVED_*.rpt")):
        raise SystemExit(f"package already approved: {package}")
    approved.write_text(
        "LABEL=SPADMIC_INNOVUS_HANDOFF_APPROVAL\n"
        "STATUS=APPROVED\n"
        f"PROMOTION_BASIS={gate.get('PROMOTION_BASIS', 'MISSING')}\n"
        f"GATE_STATUS={gate_path}\n"
        f"GATE_STATUS_SHA256={digest(gate_path)}\n"
        f"GDS_SHA256={gate.get('GDS_SHA256', 'MISSING')}\n"
        f"LVS_SOURCE_SHA256={gate.get('LVS_SOURCE_SHA256', 'MISSING')}\n"
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
