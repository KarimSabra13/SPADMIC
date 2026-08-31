#!/usr/bin/env python3
"""Classify density-only DRC debt against an attributable antenna-only base run."""

from __future__ import annotations

import argparse
import hashlib
import sys
from pathlib import Path


ANTENNA_RULES = ("R1M2P1", "R1M3P1", "R2M2P1", "R2M3P1")


class EvidenceError(RuntimeError):
    pass


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def require_file(path: Path, label: str) -> Path:
    resolved = path.expanduser().resolve()
    if not resolved.is_file() or resolved.stat().st_size == 0:
        raise EvidenceError(f"{label} missing or empty: {resolved}")
    return resolved


def values(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for line in path.read_text(errors="replace").splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            result[key.strip()] = value.strip()
    return result


def rules(path: Path) -> dict[str, tuple[int, int]]:
    lines = path.read_text(errors="replace").splitlines()
    if not lines or lines[0] != "rule\tprimary\texpanded":
        raise EvidenceError(f"invalid rule inventory header: {path}")
    result: dict[str, tuple[int, int]] = {}
    for number, line in enumerate(lines[1:], start=2):
        if not line.strip():
            continue
        fields = line.split("\t")
        if len(fields) != 3:
            raise EvidenceError(f"invalid rule row {number}: {line}")
        name = fields[0]
        if name in result:
            raise EvidenceError(f"duplicate rule row: {name}")
        try:
            primary, expanded = int(fields[1]), int(fields[2])
        except ValueError as exc:
            raise EvidenceError(f"non-numeric rule row {number}: {line}") from exc
        if primary < 0 or expanded < 0 or (primary == 0 and expanded == 0):
            raise EvidenceError(f"invalid nonzero rule row {number}: {line}")
        result[name] = (primary, expanded)
    return result


def attributable_status(
    status_path: Path, rule_path: Path, expected_variant: str
) -> tuple[dict[str, str], dict[str, tuple[int, int]]]:
    status = values(status_path)
    required = {
        "STATUS",
        "PVS_DRC_STATUS",
        "PVS_DRC_VARIANT",
        "PVS_RC",
        "DRC_TOTAL_PRIMARY",
        "DRC_TOTAL_EXPANDED",
        "NONZERO_RULE_COUNT",
        "NONZERO_RULE_REPORT",
        "NONZERO_RULE_REPORT_SHA256",
        "LAYOUT_INPUT_SHA256",
    }
    missing = sorted(required - status.keys())
    if missing:
        raise EvidenceError(
            f"{expected_variant.lower()} status missing keys: {','.join(missing)}"
        )
    if status["PVS_DRC_VARIANT"] != expected_variant or status["PVS_RC"] != "0":
        raise EvidenceError(f"{expected_variant} evidence requires PVS_RC=0")
    if status["STATUS"] != status["PVS_DRC_STATUS"] or status["STATUS"] not in {
        "PASS",
        "FAIL",
    }:
        raise EvidenceError(f"{expected_variant} status fields are inconsistent")
    if Path(status["NONZERO_RULE_REPORT"]).expanduser().resolve() != rule_path:
        raise EvidenceError(f"{expected_variant} status references another rule inventory")
    if status["NONZERO_RULE_REPORT_SHA256"].lower() != sha256(rule_path):
        raise EvidenceError(f"{expected_variant} rule inventory hash mismatch")
    parsed = rules(rule_path)
    try:
        primary = int(status["DRC_TOTAL_PRIMARY"])
        expanded = int(status["DRC_TOTAL_EXPANDED"])
        count = int(status["NONZERO_RULE_COUNT"])
    except ValueError as exc:
        raise EvidenceError(f"{expected_variant} totals are not integers") from exc
    if count != len(parsed):
        raise EvidenceError(f"{expected_variant} rule count mismatch")
    if sum(value[0] for value in parsed.values()) != primary or sum(
        value[1] for value in parsed.values()
    ) != expanded:
        raise EvidenceError(f"{expected_variant} rule totals mismatch")
    if status["STATUS"] == "PASS" and (primary or expanded or parsed):
        raise EvidenceError(f"PASS {expected_variant} status contains nonzero rules")
    if status["STATUS"] == "FAIL" and not parsed:
        raise EvidenceError(f"FAIL {expected_variant} status has no rule rows")
    return status, parsed


def classify(
    base_status_path: Path,
    base_rules_path: Path,
    density_status_path: Path,
    density_rules_path: Path,
) -> tuple[str, dict[str, str]]:
    base_status, base = attributable_status(base_status_path, base_rules_path, "BASE")
    density_status, density = attributable_status(
        density_status_path, density_rules_path, "DENSITY"
    )
    if base_status["LAYOUT_INPUT_SHA256"] != density_status["LAYOUT_INPUT_SHA256"]:
        raise EvidenceError("base and density runs use different layout hashes")

    base_non_antenna = sorted(set(base) - set(ANTENNA_RULES))
    if base_non_antenna:
        raise EvidenceError(
            "base run is not clean or antenna-only: " + ",".join(base_non_antenna)
        )
    base_signature = {name: base.get(name, (0, 0)) for name in ANTENNA_RULES}
    density_signature = {name: density.get(name, (0, 0)) for name in ANTENNA_RULES}
    if base_signature != density_signature:
        changed = [
            name
            for name in ANTENNA_RULES
            if base_signature[name] != density_signature[name]
        ]
        raise EvidenceError("density antenna signature drift: " + ",".join(changed))

    debt_names = sorted(set(density) - set(ANTENNA_RULES))
    debt_primary = sum(density[name][0] for name in debt_names)
    debt_expanded = sum(density[name][1] for name in debt_names)
    result = "PASS" if not debt_names else "FAIL"
    details = {
        "PVS_DRC_BASE_RAW_STATUS": base_status["STATUS"],
        "PVS_DRC_DENSITY_RAW_STATUS": density_status["STATUS"],
        "LAYOUT_INPUT_SHA256": base_status["LAYOUT_INPUT_SHA256"],
        "BASE_RULE_REPORT_SHA256": sha256(base_rules_path),
        "DENSITY_RULE_REPORT_SHA256": sha256(density_rules_path),
        "DENSITY_ANTENNA_SIGNATURE_MATCH_STATUS": "PASS",
        "DENSITY_NON_ANTENNA_RULE_COUNT": str(len(debt_names)),
        "DENSITY_NON_ANTENNA_RULE_SET": ",".join(debt_names) if debt_names else "NONE",
        "DENSITY_NON_ANTENNA_TOTAL_PRIMARY": str(debt_primary),
        "DENSITY_NON_ANTENNA_TOTAL_EXPANDED": str(debt_expanded),
        "PVS_DRC_DENSITY_NON_ANTENNA_STATUS": result,
    }
    return result, details


def write_report(path: Path, status: str, details: dict[str, str], error: str = "") -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "STEP=MPTDC_DENSITY_DELTA_CLASSIFICATION",
        f"DENSITY_CLASSIFICATION_STATUS={status}",
        f"ALLOWED_ANTENNA_RULE_SET={','.join(ANTENNA_RULES)}",
    ]
    lines.extend(f"{key}={value}" for key, value in details.items())
    if error:
        lines.append(f"ERROR={error}")
    decision = {
        "PASS": "PASS_NON_ANTENNA_DENSITY_CLEAN",
        "FAIL": "FAIL_REVIEW_ATTRIBUTABLE_DENSITY_DEBT",
    }.get(status, "FAIL_INVALID_EVIDENCE")
    lines.extend(
        [
            "ANTENNA_REPAIR_ATTEMPTED=NO",
            "SIGNOFF_ELIGIBLE=NO",
            f"DECISION={decision}",
        ]
    )
    path.write_text("\n".join(lines) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-status", required=True, type=Path)
    parser.add_argument("--base-rules", required=True, type=Path)
    parser.add_argument("--density-status", required=True, type=Path)
    parser.add_argument("--density-rules", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()
    out = args.out.expanduser().resolve()
    try:
        base_status = require_file(args.base_status, "base status")
        base_rules = require_file(args.base_rules, "base rules")
        density_status = require_file(args.density_status, "density status")
        density_rules = require_file(args.density_rules, "density rules")
        status, details = classify(base_status, base_rules, density_status, density_rules)
        write_report(out, status, details)
        print(out.read_text(), end="")
        return 0 if status == "PASS" else 10
    except EvidenceError as exc:
        write_report(out, "INVALID_EVIDENCE", {}, str(exc))
        print(out.read_text(), end="")
        return 8


if __name__ == "__main__":
    sys.exit(main())
