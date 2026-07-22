#!/usr/bin/env python3
"""Validate the read-only p03 OA candidate before top-layout insertion."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


def read_kv(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            values[key] = value
    return values


def normalize_pin(name: str) -> str:
    name = name.strip().lstrip("\\")
    return re.sub(r"<([0-9]+)>", r"[\1]", name)


def oa_contract(path: Path) -> tuple[tuple[float, float, float, float], set[str]]:
    text = path.read_text(encoding="utf-8", errors="replace")
    match = re.search(
        r"^BBOX=([-0-9.]+) ([-0-9.]+) ([-0-9.]+) ([-0-9.]+)$",
        text,
        re.MULTILINE,
    )
    if not match:
        raise ValueError(f"OA bbox missing: {path}")
    pins = {
        normalize_pin(pin.group(1))
        for pin in re.finditer(r"^PIN=([^|]+)\|", text, re.MULTILINE)
    }
    return tuple(float(value) for value in match.groups()), pins


def lef_contract(path: Path) -> tuple[tuple[float, float], set[str], str]:
    text = path.read_text(encoding="utf-8", errors="replace")
    size = re.search(
        r"^\s*SIZE\s+([0-9.]+)\s+BY\s+([0-9.]+)", text, re.MULTILINE
    )
    macro = re.search(r"^\s*MACRO\s+(\S+)", text, re.MULTILINE)
    if not size or not macro:
        raise ValueError(f"LEF macro/size missing: {path}")
    pins = {
        normalize_pin(name)
        for name in re.findall(r"^\s*PIN\s+(\S+)", text, re.MULTILINE)
    }
    return (float(size.group(1)), float(size.group(2))), pins, macro.group(1)


def close(left: float, right: float, tolerance: float) -> bool:
    return abs(left - right) <= tolerance


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pvs-status", required=True, type=Path)
    parser.add_argument("--source-audit-status", required=True, type=Path)
    parser.add_argument("--candidate-oa-report", required=True, type=Path)
    parser.add_argument("--target-oa-report", required=True, type=Path)
    parser.add_argument("--lef", required=True, type=Path)
    parser.add_argument("--status", required=True, type=Path)
    parser.add_argument("--tolerance-um", type=float, default=0.002)
    args = parser.parse_args()

    top = "spadmic_digital_assembly_v1_p03_matrix_interface"
    errors: list[str] = []
    pvs = read_kv(args.pvs_status)
    audit = read_kv(args.source_audit_status)
    expected_pvs = {
        "STATUS": "PASS",
        "PHASE": "p03_matrix_interface",
        "MODE": "LVS",
        "TOP_MODULE": top,
        "LAYOUT_TOP": top,
        "SOURCE_TOP": top,
        "PVS_BASE_DRC_STATUS": "PASS",
        "PVS_DENSITY_DRC_STATUS": "PASS",
        "PVS_LVS_STATUS": "MATCH",
        "ASSEMBLY_PHASE_ACCEPTED": "YES",
        "OA_INSERTION_AUTHORIZED": "YES",
    }
    for key, expected in expected_pvs.items():
        if pvs.get(key) != expected:
            errors.append(f"pvs_{key.lower()}={pvs.get(key, 'MISSING')} expected={expected}")
    expected_audit = {
        "STATUS": "PASS",
        "SOURCE_IDENTITY_GATE_STATUS": "PASS",
        "EXACT_MATRICE5_INSTANCE_GATE_STATUS": "PASS",
        "MATRIX_TERMINAL_PARITY_STATUS": "PASS",
        "UNKNOWN_FAMILY_GATE_STATUS": "PASS",
        "MATRIX_PROXY_PIN_ACCESS_STATUS": "PASS",
        "PG_ANCHOR_GATE_STATUS": "PASS",
        "P03_IMPLEMENTATION_AUTHORIZED": "YES",
    }
    for key, expected in expected_audit.items():
        if audit.get(key) != expected:
            errors.append(
                f"source_audit_{key.lower()}={audit.get(key, 'MISSING')} expected={expected}"
            )

    candidate_bbox: tuple[float, float, float, float] | None = None
    target_bbox: tuple[float, float, float, float] | None = None
    candidate_pins: set[str] = set()
    lef_pins: set[str] = set()
    lef_size: tuple[float, float] | None = None
    macro = "UNKNOWN"
    try:
        candidate_bbox, candidate_pins = oa_contract(args.candidate_oa_report)
        target_bbox, _ = oa_contract(args.target_oa_report)
        lef_size, lef_pins, macro = lef_contract(args.lef)
    except (OSError, ValueError) as error:
        errors.append(str(error))

    bbox_parity = False
    target_parity = False
    pin_parity = candidate_pins == lef_pins and bool(lef_pins)
    if candidate_bbox is not None and target_bbox is not None and lef_size is not None:
        candidate_size = (
            candidate_bbox[2] - candidate_bbox[0],
            candidate_bbox[3] - candidate_bbox[1],
        )
        bbox_parity = all(
            close(actual, expected, args.tolerance_um)
            for actual, expected in zip(candidate_size, lef_size)
        )
        target_parity = all(
            close(actual, expected, args.tolerance_um)
            for actual, expected in zip(candidate_bbox, target_bbox)
        )
    if macro != top:
        errors.append(f"lef_macro={macro} expected={top}")
    if not bbox_parity:
        errors.append("candidate_lef_bbox_parity_failed")
    if not target_parity:
        errors.append("candidate_spadmic2_bbox_parity_failed")
    if not pin_parity:
        errors.append("candidate_lef_pin_parity_failed")

    values = {
        "LABEL": "SPADMIC_DIGITAL_ASSEMBLY_P03_OA_CANDIDATE_GATE",
        "STATUS": "PASS" if not errors else "FAIL",
        "RESULT": "OA_CANDIDATE_READY_FOR_IMMUTABLE_BACKUP" if not errors else "OA_CANDIDATE_REVIEW_REQUIRED",
        "PHASE": "p03_matrix_interface",
        "TOP_MODULE": top,
        "SOURCE_GDS_SHA256": pvs.get("GDS_SHA256", "MISSING"),
        "PVS_EVIDENCE_STATUS": "PASS" if all(pvs.get(k) == v for k, v in expected_pvs.items()) else "FAIL",
        "SOURCE_AUDIT_STATUS": "PASS" if all(audit.get(k) == v for k, v in expected_audit.items()) else "FAIL",
        "OA_CANDIDATE_LEF_BBOX_PARITY_STATUS": "PASS" if bbox_parity else "FAIL",
        "OA_CANDIDATE_SPADMIC2_BBOX_PARITY_STATUS": "PASS" if target_parity else "FAIL",
        "OA_CANDIDATE_LEF_PIN_PARITY_STATUS": "PASS" if pin_parity else "FAIL",
        "OA_EQUIVALENCE_SCOPE": "BBOX_AND_BOUNDARY_PIN_CONTRACT_ONLY",
        "FULL_TOP_GDS_EXPORT_REQUIRED": "YES",
        "FULL_TOP_BASE_DRC_REQUIRED": "YES",
        "FULL_TOP_DENSITY_DRC_REQUIRED": "YES",
        "FULL_TOP_LVS_REQUIRED": "YES",
        "OA_INSERTION_READY_FOR_BACKUP": "YES" if not errors else "NO",
        "OA_MUTATION_EXECUTED": "NO",
        "SIGNOFF_READY": "NO",
        "ERROR_COUNT": len(errors),
    }
    args.status.parent.mkdir(parents=True, exist_ok=True)
    args.status.write_text(
        "".join(
            [
                *(f"{key}={value}\n" for key, value in values.items()),
                *(f"ERROR={error}\n" for error in errors),
            ]
        ),
        encoding="utf-8",
    )
    print(args.status.read_text(), end="")
    return 0 if not errors else 8


if __name__ == "__main__":
    raise SystemExit(main())
