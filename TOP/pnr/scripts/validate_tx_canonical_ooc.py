#!/usr/bin/env python3
"""Validate a fresh TX packet/strip OOC result before immutable staging."""

from __future__ import annotations

import argparse
import csv
import hashlib
import importlib.util
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
ASSEMBLY_MODULE = REPO_ROOT / "TOP" / "pnr" / "scripts" / "gen_spadmic_digital_assembly_v1.py"
SPEC = importlib.util.spec_from_file_location("tx_ooc_lef_parser", ASSEMBLY_MODULE)
assert SPEC and SPEC.loader
lef_parser = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = lef_parser
SPEC.loader.exec_module(lef_parser)

TX_PIN_CONTRACT = REPO_ROOT / "TOP" / "pnr" / "interfaces" / "tx_packet_strip_pin_contract.csv"
TX_SOURCE_MANIFEST = REPO_ROOT / "TOP" / "rtl" / "interfaces" / "tx_src_data_flat.csv"

BLOCKS = {
    "tx_packet_core": {
        "macro": "spadmic_tx_packet_core",
        "width": 2066.960,
        "height": 366.800,
        "stream_pin_key": "packet_pin",
        "stream_x_key": "packet_local_x_um",
    },
    "tx_ddr_strip": {
        "macro": "spadmic_tx_ddr_strip",
        "width": 3433.360,
        "height": 180.880,
        "stream_pin_key": "strip_pin",
        "stream_x_key": "strip_local_x_um",
    },
}


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


def require_nonempty(path: Path, errors: list[str], label: str) -> bool:
    if not path.is_file() or path.stat().st_size == 0:
        errors.append(f"missing_or_empty_{label}={path}")
        return False
    return True


def validate(
    block_root: Path,
    block: str,
    report: Path,
    allow_antenna_deferred: bool,
) -> dict[str, str]:
    config = BLOCKS[block]
    outputs = block_root / "outputs"
    reports = block_root / "reports"
    lef_path = outputs / f"{block}.abstract.lef"
    gds_path = outputs / f"{block}.gds"
    def_path = outputs / f"{block}.def"
    pg_netlist = outputs / f"{block}.routed.pg.v"
    status_path = reports / "ooc_harden_status.rpt"
    gds_audit_path = reports / "gds_export_audit.rpt"
    errors: list[str] = []
    for path, label in [
        (lef_path, "lef"),
        (gds_path, "gds"),
        (def_path, "def"),
        (pg_netlist, "pg_netlist"),
        (status_path, "ooc_status"),
        (gds_audit_path, "gds_audit"),
    ]:
        require_nonempty(path, errors, label)

    status = key_values(status_path) if status_path.is_file() else {}
    required_status = {
        "RESULT": "ABSTRACT_READY_FOR_TOP_REVIEW",
        "INNOVUS_DRC_STATUS": "PASS",
        "REGULAR_CONNECTIVITY_STATUS": "PASS",
        "PG_CONNECTIVITY_STATUS": "PASS",
        "CREATE_PG_STRAPS": "PASS",
        "CREATE_PG_STRAP_VDD": "PASS",
        "CREATE_PG_STRAP_VSS": "PASS",
        "SROUTE_PG": "PASS",
        "POSTROUTE_SETUP_TIMING": "PASS",
        "POSTROUTE_HOLD_TIMING": "PASS",
        "EXPORT_GDS_FILE": "PASS",
        "EXPORT_ABSTRACT_LEF_FILE": "PASS",
        "EXPORT_NETLIST_PG": "PASS",
    }
    for key, expected in required_status.items():
        if status.get(key) != expected:
            errors.append(f"ooc_status_{key}={status.get(key, 'MISSING')} expected={expected}")

    gds_audit = key_values(gds_audit_path) if gds_audit_path.is_file() else {}
    for key in ["STATUS", "GDS_FILE_STATUS", "GDS_LAYER_MAP_STATUS", "GDS_MERGE_STATUS"]:
        if gds_audit.get(key) != "PASS":
            errors.append(f"gds_audit_{key}={gds_audit.get(key, 'MISSING')} expected=PASS")

    macro = None
    if lef_path.is_file():
        try:
            macro = lef_parser.parse_lef(lef_path)
        except ValueError as exc:
            errors.append(f"lef_parse={exc}")
    if macro is not None:
        if macro.name != config["macro"]:
            errors.append(f"lef_macro={macro.name} expected={config['macro']}")
        if abs(macro.width - config["width"]) > 0.002 or abs(macro.height - config["height"]) > 0.002:
            errors.append(
                f"lef_size={macro.width:.6f}x{macro.height:.6f} "
                f"expected={config['width']:.6f}x{config['height']:.6f}"
            )
        with TX_PIN_CONTRACT.open(newline="") as fh:
            contract_rows = list(csv.DictReader(fh))
        for row in contract_rows:
            pin_name = row[config["stream_pin_key"]]
            pin = macro.pins.get(pin_name)
            if pin is None or not pin.rects:
                errors.append(f"missing_stream_pin={pin_name}")
                continue
            rect = pin.primary_rect()
            expected_x = float(row[config["stream_x_key"]])
            if rect.layer != "MET3":
                errors.append(f"stream_pin_layer={pin_name}:{rect.layer} expected=MET3")
            if abs(rect.cx - expected_x) > 0.002:
                errors.append(f"stream_pin_x={pin_name}:{rect.cx:.6f} expected={expected_x:.6f}")
        for pin_name, expected_use in [("VDD", "POWER"), ("VSS", "GROUND")]:
            pin = macro.pins.get(pin_name)
            if pin is None or not pin.rects:
                errors.append(f"missing_pg_pin={pin_name}")
                continue
            if pin.use != expected_use:
                errors.append(f"pg_pin_use={pin_name}:{pin.use} expected={expected_use}")
            if {rect.layer for rect in pin.rects} != {"METTP"}:
                errors.append(f"pg_pin_layers={pin_name}:{','.join(sorted({rect.layer for rect in pin.rects}))}")
        if block == "tx_packet_core":
            with TX_SOURCE_MANIFEST.open(newline="") as fh:
                scalar_names = [row["name"] for row in csv.DictReader(fh)]
            missing_scalars = [name for name in scalar_names if name not in macro.pins]
            if missing_scalars:
                errors.append("missing_scalar_source_pins=" + ",".join(missing_scalars))
            nested = sorted(name for name in macro.pins if "][" in name)
            if nested:
                errors.append("nested_lef_pins=" + ",".join(nested))

    try:
        antenna_count = int(status.get("ANTENNA_MARKER_COUNT", "-1"))
    except ValueError:
        antenna_count = -1
    if antenna_count < 0:
        errors.append(f"antenna_marker_count={status.get('ANTENNA_MARKER_COUNT', 'MISSING')}")
        antenna_status = "UNKNOWN"
    elif antenna_count == 0:
        antenna_status = "PASS"
    elif allow_antenna_deferred:
        antenna_status = "DEFERRED_FINAL_HANDOFF_BLOCKED"
    else:
        errors.append(f"antenna_markers_not_allowed={antenna_count}")
        antenna_status = "FAIL"

    result = "READY_FOR_PVS_CANDIDATE" if not errors else "REVIEW_REQUIRED"
    values = {
        "LABEL": "SPADMIC_TX_CANONICAL_OOC_GATE",
        "STATUS": "PASS" if not errors else "FAIL",
        "RESULT": result,
        "BLOCK": block,
        "MACRO": str(config["macro"]),
        "BLOCK_ROOT": str(block_root),
        "ANTENNA_MARKER_COUNT": str(antenna_count),
        "ANTENNA_MILESTONE_STATUS": antenna_status,
        "PVS_STATUS": "NOT_RUN",
        "FINAL_HANDOFF_READY": "NO",
        "LEF_SHA256": digest(lef_path) if lef_path.is_file() else "MISSING",
        "GDS_SHA256": digest(gds_path) if gds_path.is_file() else "MISSING",
        "PG_NETLIST_SHA256": digest(pg_netlist) if pg_netlist.is_file() else "MISSING",
        "ERROR_COUNT": str(len(errors)),
    }
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text(
        "\n".join([*(f"{key}={value}" for key, value in values.items()), *(f"ERROR={error}" for error in errors)])
        + "\n"
    )
    return values


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--block-root", required=True, type=Path)
    parser.add_argument("--block", required=True, choices=sorted(BLOCKS))
    parser.add_argument("--status", type=Path)
    parser.add_argument("--allow-antenna-deferred", action="store_true")
    args = parser.parse_args()
    block_root = args.block_root.resolve()
    report = args.status.resolve() if args.status else block_root / "reports" / "canonical_tx_ooc_gate.rpt"
    values = validate(block_root, args.block, report, args.allow_antenna_deferred)
    print(report.read_text(), end="")
    if values["STATUS"] != "PASS":
        raise SystemExit(8)


if __name__ == "__main__":
    main()
