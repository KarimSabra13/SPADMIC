#!/usr/bin/env python3
"""Audit immutable handoff structure, hashes, canonical names, LEF and source."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path


def digest(path: Path) -> str:
    sha = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            sha.update(chunk)
    return sha.hexdigest()


def key_values(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for line in path.read_text(errors="replace").splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            values[key] = value
    return values


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("package", type=Path)
    args = parser.parse_args()
    package = args.package.resolve()
    manifest_path = package / "manifests" / "package.json"
    manifest = json.loads(manifest_path.read_text())
    name = manifest["name"]
    layout_top = manifest["layout_top"]
    source_top = manifest["source_top"]
    qualification_profile = manifest.get("qualification_profile", "basic")
    errors: list[str] = []

    required = [
        package / "gds" / f"{layout_top}.gds",
        package / "netlist" / f"{source_top}.lvs.pg.v",
        package / "netlist" / f"{source_top}.innovus.pg.v",
        package / "pdk" / "xh018_D_CELLS_JIHD.cdl",
        package / "reports" / "lvs_source_preparation.rpt",
        package / "manifests" / "SHA256SUMS",
        package / "status" / "qualification.rpt",
    ]
    for path in required:
        if not path.is_file() or path.stat().st_size == 0:
            errors.append(f"missing_or_empty={path}")

    lefs = sorted((package / "lef").glob("*.lef"))
    if not lefs:
        errors.append("missing_lef")
    else:
        text = lefs[0].read_text(errors="replace")
        macro = re.search(r"^\s*MACRO\s+(\S+)", text, re.M)
        if manifest["kind"] == "block" and (not macro or macro.group(1) != name):
            errors.append(f"lef_macro={macro.group(1) if macro else 'MISSING'} expected={name}")

    netlist = package / "netlist" / f"{source_top}.lvs.pg.v"
    if netlist.is_file() and not re.search(rf"\bmodule\s+{re.escape(source_top)}\b", netlist.read_text(errors="replace")):
        errors.append(f"source_top_missing={source_top}")

    preparation = package / "reports" / "lvs_source_preparation.rpt"
    prep_values: dict[str, str] = {}
    if preparation.is_file():
        prep_values = key_values(preparation)
        if prep_values.get("STATUS") != "PASS":
            errors.append(f"lvs_source_preparation={prep_values.get('STATUS', 'MISSING')}")
        if prep_values.get("PIN_PARITY_STATUS") != "PASS":
            errors.append(f"pin_parity={prep_values.get('PIN_PARITY_STATUS', 'MISSING')}")
        if prep_values.get("SOURCE_TOP") != source_top:
            errors.append(f"prepared_source_top={prep_values.get('SOURCE_TOP', 'MISSING')} expected={source_top}")
        if netlist.is_file() and prep_values.get("OUTPUT_SHA256") != digest(netlist):
            errors.append("prepared_source_hash_mismatch")

    package_cdl = package / "pdk" / "xh018_D_CELLS_JIHD.cdl"
    if package_cdl.is_file() and manifest.get("stdcell_cdl_sha256") != digest(package_cdl):
        errors.append("stdcell_cdl_manifest_hash_mismatch")

    qualification = package / "status" / "qualification.rpt"
    qualification_values: dict[str, str] = {}
    if qualification.is_file():
        qualification_values = key_values(qualification)

    waiver_status = "NOT_APPLICABLE"
    if qualification_profile == "canonical_tx_lvs_waiver":
        waiver_status = "FAIL"
        waiver_manifest = manifest.get("temporary_drc_waiver")
        waiver_gate = package / "reports" / "canonical_tx_lvs_waiver_gate.rpt"
        waiver_report = package / "reports" / "temporary_drc_waiver.rpt"
        gds_audit = package / "reports" / "gds_export_audit.rpt"
        for path in (waiver_gate, waiver_report, gds_audit):
            if not path.is_file() or path.stat().st_size == 0:
                errors.append(f"missing_or_empty={path}")
        if not isinstance(waiver_manifest, dict):
            errors.append("temporary_drc_waiver_manifest_missing")
        elif waiver_gate.is_file() and waiver_report.is_file() and gds_audit.is_file():
            expected_hashes = {
                "gate_report_sha256": digest(waiver_gate),
                "waiver_report_sha256": digest(waiver_report),
                "gds_audit_report_sha256": digest(gds_audit),
            }
            for key, expected in expected_hashes.items():
                if waiver_manifest.get(key) != expected:
                    errors.append(f"temporary_drc_waiver_{key}_mismatch")
            expected_manifest = {
                "status": "PASS",
                "scope": "EXACT_FOUR_INNOVUS_MET1_MIN_AREA_ONLY",
                "marker_count": 4,
                "nets": ["n_9677", "n_9693", "n_9696", "n_9697"],
                "pvs_drc_waiver": False,
                "lvs_diagnostic_only": True,
                "manual_fix_required": True,
                "block_promotion_authorized": False,
                "final_signoff_ready": False,
            }
            for key, expected in expected_manifest.items():
                if waiver_manifest.get(key) != expected:
                    errors.append(
                        f"temporary_drc_waiver_manifest_{key}="
                        f"{waiver_manifest.get(key, 'MISSING')}"
                    )
            gate_values = key_values(waiver_gate)
            waiver_values = key_values(waiver_report)
            audit_values = key_values(gds_audit)
            expected_gate = {
                "STATUS": "PASS",
                "RESULT": "READY_FOR_PROVISIONAL_PVS_DRC_LVS",
                "WAIVER_SCOPE": "EXACT_FOUR_INNOVUS_MET1_MIN_AREA_ONLY",
                "WAIVER_MARKER_COUNT": "4",
                "WAIVER_NETS": "n_9677 n_9693 n_9696 n_9697",
                "PVS_DRC_WAIVER": "NO",
                "LVS_DIAGNOSTIC_ONLY": "YES",
                "MANUAL_FIX_REQUIRED": "YES",
                "BLOCK_PROMOTION_AUTHORIZED": "NO",
                "FINAL_SIGNOFF_READY": "NO",
            }
            expected_waiver = {
                "STATUS": "PASS",
                "RESULT": "EXACT_FOUR_MARKERS_RECORDED",
                "WAIVER_SCOPE": "EXACT_FOUR_INNOVUS_MET1_MIN_AREA_ONLY",
                "WAIVER_MARKER_COUNT": "4",
                "WAIVER_NETS": "n_9677 n_9693 n_9696 n_9697",
                "ALLOWED_LAYER": "MET1",
                "ALLOWED_TYPE": "Geometry",
                "ALLOWED_SUBTYPE": "Minimal_Area",
                "PVS_DRC_WAIVER": "NO",
                "LVS_DIAGNOSTIC_ONLY": "YES",
                "MANUAL_FIX_REQUIRED": "YES",
                "BLOCK_PROMOTION_AUTHORIZED": "NO",
                "FINAL_SIGNOFF_READY": "NO",
            }
            for key, expected in expected_gate.items():
                if gate_values.get(key) != expected:
                    errors.append(
                        f"temporary_drc_waiver_gate_{key}="
                        f"{gate_values.get(key, 'MISSING')}"
                    )
            for key, expected in expected_waiver.items():
                if waiver_values.get(key) != expected:
                    errors.append(
                        f"temporary_drc_waiver_report_{key}="
                        f"{waiver_values.get(key, 'MISSING')}"
                    )
            if audit_values.get("STATUS") != "PASS":
                errors.append(
                    f"temporary_drc_waiver_gds_audit="
                    f"{audit_values.get('STATUS', 'MISSING')}"
                )
        expected_qualification = {
            "TEMPORARY_DRC_WAIVER_STATUS": "PASS",
            "TEMPORARY_DRC_WAIVER_SCOPE": "EXACT_FOUR_INNOVUS_MET1_MIN_AREA_ONLY",
            "TEMPORARY_DRC_WAIVER_MARKER_COUNT": "4",
            "PVS_DRC_WAIVER": "NO",
            "LVS_DIAGNOSTIC_ONLY": "YES",
            "MANUAL_DRC_FIX_REQUIRED": "YES",
            "BLOCK_PROMOTION_AUTHORIZED": "NO",
            "GDS_LAYER_MAP_STATUS": "PASS",
            "SIGNOFF_READY": "NO",
        }
        for key, expected in expected_qualification.items():
            if qualification_values.get(key) != expected:
                errors.append(
                    f"qualification_{key}="
                    f"{qualification_values.get(key, 'MISSING')}"
                )
        if not errors:
            waiver_status = "PASS"

    sums = package / "manifests" / "SHA256SUMS"
    if sums.is_file():
        for line in sums.read_text().splitlines():
            expected, rel = line.split(None, 1)
            path = package / rel.strip()
            if not path.is_file() or digest(path) != expected:
                errors.append(f"hash_mismatch={rel.strip()}")

    report = package / "status" / "handoff_audit.rpt"
    report.write_text(
        "LABEL=SPADMIC_INNOVUS_HANDOFF_AUDIT\n"
        f"STATUS={'FAIL' if errors else 'PASS'}\n"
        f"PACKAGE={package}\n"
        f"CANONICAL_NAME={name}\n"
        f"LAYOUT_TOP={layout_top}\n"
        f"SOURCE_TOP={source_top}\n"
        f"LVS_SOURCE_PREPARATION_STATUS={prep_values.get('STATUS', 'MISSING')}\n"
        f"PIN_PARITY_STATUS={prep_values.get('PIN_PARITY_STATUS', 'MISSING')}\n"
        f"STDCELL_CDL_STATUS={'PASS' if package_cdl.is_file() else 'FAIL'}\n"
        f"QUALIFICATION_PROFILE={qualification_profile}\n"
        f"TEMPORARY_DRC_WAIVER_STATUS={waiver_status}\n"
        f"PVS_DRC_WAIVER={qualification_values.get('PVS_DRC_WAIVER', 'MISSING')}\n"
        f"LVS_DIAGNOSTIC_ONLY={qualification_values.get('LVS_DIAGNOSTIC_ONLY', 'MISSING')}\n"
        f"FINAL_SIGNOFF_READY={qualification_values.get('SIGNOFF_READY', 'MISSING')}\n"
        f"ERROR_COUNT={len(errors)}\n"
        + "".join(f"ERROR={error}\n" for error in errors)
    )
    print(report.read_text(), end="")
    if errors:
        raise SystemExit(8)


if __name__ == "__main__":
    main()
