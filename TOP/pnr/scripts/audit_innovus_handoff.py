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
        f"ERROR_COUNT={len(errors)}\n"
        + "".join(f"ERROR={error}\n" for error in errors)
    )
    print(report.read_text(), end="")
    if errors:
        raise SystemExit(8)


if __name__ == "__main__":
    main()
