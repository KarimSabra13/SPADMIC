#!/usr/bin/env python3
"""Build one immutable promotion gate from independent, hash-bound evidence."""

from __future__ import annotations

import argparse
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path

from validate_formal_drc_waiver import validate_manifest


def values(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for line in path.read_text(errors="replace").splitlines():
        if "=" in line and not line.startswith("#"):
            key, value = line.split("=", 1)
            result[key.strip()] = value.strip()
    return result


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def evidence_digest(path: Path) -> str:
    return digest(path) if path.is_file() else "MISSING"


def load_values(path: Path, label: str, errors: list[str]) -> dict[str, str]:
    if not path.is_file() or path.stat().st_size == 0:
        errors.append(f"{label}_missing_or_empty={path}")
        return {}
    try:
        return values(path)
    except OSError as error:
        errors.append(f"{label}_read={error}")
        return {}


def package_identity(package: Path) -> tuple[str, Path, str, Path, str]:
    manifest = json.loads((package / "manifests" / "package.json").read_text())
    block = str(manifest["name"])
    layout_top = str(manifest["layout_top"])
    source_top = str(manifest["source_top"])
    gds = package / "gds" / f"{layout_top}.gds"
    if not gds.is_file() or gds.stat().st_size == 0:
        raise ValueError(f"package GDS missing or empty: {gds}")
    lvs_source = package / "netlist" / f"{source_top}.lvs.pg.v"
    if not lvs_source.is_file() or lvs_source.stat().st_size == 0:
        raise ValueError(f"package LVS source missing or empty: {lvs_source}")
    return block, gds, digest(gds), lvs_source, digest(lvs_source)


def require_binding(
    report: dict[str, str],
    *,
    package: Path,
    gds: Path,
    gds_hash: str,
    label: str,
    errors: list[str],
) -> None:
    if report.get("PACKAGE") != str(package):
        errors.append(
            f"{label}_package={report.get('PACKAGE', 'MISSING')} expected={package}"
        )
    if report.get("GDS") != str(gds):
        errors.append(
            f"{label}_gds={report.get('GDS', 'MISSING')} expected={gds}"
        )
    if report.get("GDS_SHA256") != gds_hash:
        errors.append(
            f"{label}_gds_sha256={report.get('GDS_SHA256', 'MISSING')} expected={gds_hash}"
        )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--package", required=True, type=Path)
    parser.add_argument("--base-drc-status", required=True, type=Path)
    parser.add_argument("--density-drc-status", required=True, type=Path)
    parser.add_argument("--lvs-status", required=True, type=Path)
    parser.add_argument("--pg-status", required=True, type=Path)
    parser.add_argument("--contract-status", required=True, type=Path)
    parser.add_argument("--layer-status", required=True, type=Path)
    parser.add_argument("--timing-status", required=True, type=Path)
    parser.add_argument("--formal-waiver-manifest", type=Path)
    parser.add_argument("--run-id", default="")
    args = parser.parse_args()

    package = args.package.resolve()
    run_id = args.run_id or datetime.now(timezone.utc).strftime("gate_%Y%m%dT%H%M%SZ")
    output = package / "status" / f"{run_id}.rpt"
    if output.exists():
        raise SystemExit(f"immutable gate exists: {output}")

    try:
        block, gds, gds_hash, lvs_source, lvs_source_hash = package_identity(package)
    except (OSError, KeyError, ValueError, json.JSONDecodeError) as error:
        raise SystemExit(f"PACKAGE_IDENTITY_FAIL: {error}") from error

    report_paths = {
        "BASE_DRC_EVIDENCE": args.base_drc_status.resolve(),
        "DENSITY_DRC_EVIDENCE": args.density_drc_status.resolve(),
        "LVS_EVIDENCE": args.lvs_status.resolve(),
        "PG_EVIDENCE": args.pg_status.resolve(),
        "CONTRACT_EVIDENCE": args.contract_status.resolve(),
        "LAYER_MAP_EVIDENCE": args.layer_status.resolve(),
        "TIMING_EVIDENCE": args.timing_status.resolve(),
        "QUALIFICATION_EVIDENCE": package / "status" / "qualification.rpt",
        "HANDOFF_AUDIT_EVIDENCE": package / "status" / "handoff_audit.rpt",
    }
    paths = dict(report_paths)
    paths["LVS_SOURCE_EVIDENCE"] = lvs_source
    errors: list[str] = []
    for key, path in paths.items():
        if not path.is_relative_to(package):
            errors.append(f"{key.lower()}_outside_package={path}")
    reports = {
        key: load_values(path, key.lower(), errors)
        for key, path in report_paths.items()
    }
    base = reports["BASE_DRC_EVIDENCE"]
    density = reports["DENSITY_DRC_EVIDENCE"]
    lvs = reports["LVS_EVIDENCE"]
    pg = reports["PG_EVIDENCE"]
    contract = reports["CONTRACT_EVIDENCE"]
    layer = reports["LAYER_MAP_EVIDENCE"]
    timing = reports["TIMING_EVIDENCE"]
    qualification = reports["QUALIFICATION_EVIDENCE"]
    handoff_audit = reports["HANDOFF_AUDIT_EVIDENCE"]

    for label, report in (("base_drc", base), ("density_drc", density), ("lvs", lvs)):
        require_binding(
            report,
            package=package,
            gds=gds,
            gds_hash=gds_hash,
            label=label,
            errors=errors,
        )
    if base.get("PVS_DRC_VARIANT") != "BASE":
        errors.append(
            f"base_drc_variant={base.get('PVS_DRC_VARIANT', 'MISSING')} expected=BASE"
        )
    if density.get("PVS_DRC_VARIANT") != "DENSITY":
        errors.append(
            "density_drc_variant="
            f"{density.get('PVS_DRC_VARIANT', 'MISSING')} expected=DENSITY"
        )
    if layer.get("GDS_SHA256") != gds_hash:
        errors.append(
            f"layer_gds_sha256={layer.get('GDS_SHA256', 'MISSING')} expected={gds_hash}"
        )
    if layer.get("GDS") != str(gds):
        errors.append(f"layer_gds={layer.get('GDS', 'MISSING')} expected={gds}")
    if lvs.get("LVS_SOURCE") != str(lvs_source):
        errors.append(
            f"lvs_source={lvs.get('LVS_SOURCE', 'MISSING')} expected={lvs_source}"
        )
    if lvs.get("LVS_SOURCE_SHA256") != lvs_source_hash:
        errors.append(
            "lvs_source_sha256="
            f"{lvs.get('LVS_SOURCE_SHA256', 'MISSING')} expected={lvs_source_hash}"
        )

    waiver_result = {
        "STATUS": "NOT_PROVIDED",
        "BASE_COVERED": "NO",
        "DENSITY_COVERED": "NO",
    }
    if args.formal_waiver_manifest:
        waiver_path = args.formal_waiver_manifest.resolve()
        if not waiver_path.is_relative_to(package):
            errors.append(f"formal_waiver_evidence_outside_package={waiver_path}")
        waiver_result, waiver_errors = validate_manifest(
            waiver_path,
            gds,
            expected_block=block,
        )
        errors.extend(f"formal_waiver_{error}" for error in waiver_errors)
        paths["FORMAL_WAIVER_EVIDENCE"] = waiver_path

    def drc_gate(report: dict[str, str], covered_key: str) -> str:
        drc_status = report.get("PVS_DRC_STATUS", "UNKNOWN")
        if drc_status == "PASS":
            return "PASS"
        if (
            drc_status == "FAIL"
            and waiver_result.get("STATUS") == "PASS"
            and waiver_result.get(covered_key) == "YES"
        ):
            return "FORMALLY_WAIVED"
        return drc_status

    fields = {
        "HANDOFF_AUDIT_STATUS": handoff_audit.get("STATUS", "UNKNOWN"),
        "CANONICAL_NAME_STATUS": qualification.get("CANONICAL_NAME_STATUS", "UNKNOWN"),
        "BBOX_PARITY_STATUS": contract.get("BBOX_PARITY_STATUS", "UNKNOWN"),
        "PIN_PARITY_STATUS": contract.get("PIN_PARITY_STATUS", "UNKNOWN"),
        "GDS_LAYER_MAP_STATUS": layer.get("GDS_LAYER_MAP_STATUS", "UNKNOWN"),
        "GDS_MERGE_STATUS": layer.get("GDS_MERGE_STATUS", "UNKNOWN"),
        "INTERNAL_PG_STATUS": pg.get(
            "INTERNAL_PG_STATUS",
            pg.get("PG_CONNECTIVITY_STATUS", "UNKNOWN"),
        ),
        "TC_TIMING_STATUS": timing.get("TC_TIMING_STATUS", timing.get("STATUS", "UNKNOWN")),
        "PVS_BASE_DRC_STATUS": drc_gate(base, "BASE_COVERED"),
        "PVS_DENSITY_DRC_STATUS": drc_gate(density, "DENSITY_COVERED"),
        "PVS_LVS_STATUS": lvs.get("PVS_LVS_STATUS", "UNKNOWN"),
        "FORMAL_DRC_WAIVER_STATUS": waiver_result.get("STATUS", "NOT_PROVIDED"),
    }
    exact_expected = {
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
    for key, expected in exact_expected.items():
        if fields[key] != expected:
            errors.append(f"{key}={fields[key]} expected={expected}")
    for key in ("PVS_BASE_DRC_STATUS", "PVS_DENSITY_DRC_STATUS"):
        if fields[key] not in {"PASS", "FORMALLY_WAIVED"}:
            errors.append(f"{key}={fields[key]} expected=PASS_OR_FORMALLY_WAIVED")

    waived = any(
        fields[key] == "FORMALLY_WAIVED"
        for key in ("PVS_BASE_DRC_STATUS", "PVS_DENSITY_DRC_STATUS")
    )
    if waived and fields["FORMAL_DRC_WAIVER_STATUS"] != "PASS":
        errors.append("formal_waiver_required_for_waived_drc_gate")
    passed = not errors
    basis = "FORMAL_DRC_WAIVER" if waived else "CLEAN_ZERO_DRC"

    output.write_text(
        "LABEL=SPADMIC_INNOVUS_HANDOFF_PROMOTION_GATE\n"
        f"STATUS={'PASS' if passed else 'FAIL'}\n"
        f"PACKAGE={package}\n"
        f"BLOCK={block}\n"
        f"GDS={gds}\n"
        f"GDS_SHA256={gds_hash}\n"
        f"LVS_SOURCE={lvs_source}\n"
        f"LVS_SOURCE_SHA256={lvs_source_hash}\n"
        f"PROMOTION_BASIS={basis}\n"
        + "".join(f"{key}={value}\n" for key, value in fields.items())
        + "".join(
            f"{key}={path}\n{key}_SHA256={evidence_digest(path)}\n"
            for key, path in paths.items()
        )
        + "".join(f"ERROR={error}\n" for error in errors)
        + f"SIGNOFF_READY={'BLOCK_LEVEL_ONLY' if passed else 'NO'}\n"
    )
    print(output.read_text(), end="")
    print(f"GATE_STATUS_FILE={output}")
    if not passed:
        raise SystemExit(8)


if __name__ == "__main__":
    main()
