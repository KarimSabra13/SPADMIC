#!/usr/bin/env python3
"""Create an immutable Innovus/PVS handoff package for one digital block.

The package contains design-owned collateral and a shared copy of the JIHD PDK
inputs needed by PVS. Foundry rule infrastructure remains referenced by path
and hash because it is installation collateral, not project collateral.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))
from prepare_pvs_lvs_source import prepare_lvs_source


DEFAULT_ROOT = Path("/sim/ksabra/SPADMIC_work/handoff/innovus")
PDK_CANDIDATES = {
    "tech_lef": [
        Path("/data/pdk/xfab/xh018/cadence/v9_0/techLEF/v9_0_1/xh018_xx31_HD_MET3_METMID.lef"),
    ],
    "stdcell_lef": [
        Path("/data/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/LEF/v6_0_0/xh018_D_CELLS_JIHD.lef"),
        Path("/data/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/LEF/v6_0_0/xh018/xh018_D_CELLS_JIHD.lef"),
    ],
    "stdcell_gds": [
        Path("/data/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/gds_cdl/v6_0_0/gds/xh018_D_CELLS_JIHD.gds"),
    ],
    "stdcell_cdl": [
        Path("/data/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/gds_cdl/v6_0_0/cdl/xh018_D_CELLS_JIHD.cdl"),
    ],
    "stdcell_liberty_tc": [
        Path("/data/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/liberty_LPMOS/v6_0_0/PVT_1_80V_range/D_CELLS_JIHD_LPMOS_typ_1_80V_25C.lib"),
    ],
    "streamout_map": [
        Path("/eda/pdk/xfab/xh018/cadence/v10_1/PDK/IC61/v10_1_1/TECH_XH018_HD_1131/pnr_streamout.map"),
    ],
}
RULE_REFERENCES = [
    Path("/eda/pdk/xfab/xh018/cadence/v10_1/pvs/v10_1_1/PVS/xh018_LVS.rul"),
    Path("/eda/pdk/xfab/xh018/cadence/v10_1/PDK/IC61/v10_1_1/TECH_XH018_HD_1131"),
]

ASSEMBLY_TOP_TO_PHASE = {
    "spadmic_digital_assembly_v1_p00_tx": "p00_tx",
    "spadmic_digital_assembly_v1_p01_position": "p01_position",
    "spadmic_digital_assembly_v1_p02_event_control": "p02_event_control",
    "spadmic_digital_assembly_v1_p03_matrix_interface": "p03_matrix_interface",
}


def digest(path: Path) -> str:
    sha = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            sha.update(chunk)
    return sha.hexdigest()


def require_file(path: Path, label: str) -> Path:
    path = path.expanduser().resolve()
    if not path.is_file() or path.stat().st_size == 0:
        raise ValueError(f"{label} missing or empty: {path}")
    return path


def first_existing(paths: list[Path], label: str) -> Path:
    for path in paths:
        if path.is_file() and path.stat().st_size:
            return path.resolve()
    raise ValueError(f"required PDK collateral not found for {label}: {paths}")


def copy_file(src: Path, dst: Path) -> Path:
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.exists():
        if digest(src) == digest(dst):
            return dst
        raise ValueError(f"package filename collision with different content: {dst}")
    shutil.copy2(src, dst)
    return dst


def git_value(repo: Path, *args: str) -> str:
    try:
        return subprocess.check_output(["git", "-C", str(repo), *args], text=True).strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return "UNKNOWN"


def key_values(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for line in path.read_text(errors="replace").splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            values[key] = value
    return values


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--kind", choices=["block", "assembly"], default="block")
    parser.add_argument("--name", required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--source-root", required=True, type=Path)
    parser.add_argument("--gds", required=True, type=Path)
    parser.add_argument("--layout-top", required=True)
    parser.add_argument("--netlist", required=True, type=Path)
    parser.add_argument("--source-top", required=True)
    parser.add_argument("--lef", action="append", required=True, type=Path)
    parser.add_argument("--def-file", type=Path)
    parser.add_argument("--report", action="append", default=[], type=Path)
    parser.add_argument("--log", action="append", default=[], type=Path)
    parser.add_argument("--handoff-root", type=Path, default=DEFAULT_ROOT)
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    parser.add_argument("--state", choices=["candidate", "qualified"], default="candidate")
    parser.add_argument("--copy-shared-pdk", action="store_true")
    parser.add_argument("--stdcell-cdl", type=Path)
    parser.add_argument(
        "--qualification-profile",
        choices=[
            "basic",
            "canonical_tx",
            "canonical_tx_lvs_waiver",
            "digital_assembly_tc",
        ],
        default="basic",
    )
    args = parser.parse_args()

    canonical_ok = args.layout_top == args.name and args.source_top == args.name
    canonical_note = f"{args.kind} layout/source/package names are identical"
    if not canonical_ok:
        raise SystemExit(
            "CANONICAL_TOP_GATE_FAIL: layout top, source top, and package name must be identical"
        )

    source_root = args.source_root.resolve()
    if not source_root.is_dir():
        raise SystemExit(f"source root missing: {source_root}")
    gds = require_file(args.gds, "GDS")
    netlist = require_file(args.netlist, "LVS netlist")
    lefs = [require_file(path, "LEF") for path in args.lef]
    def_file = require_file(args.def_file, "DEF") if args.def_file else None
    reports = [require_file(path, "report") for path in args.report]
    logs = [require_file(path, "log") for path in args.log]
    canonical_tx_gate: Path | None = None
    waiver_gate: Path | None = None
    waiver_report: Path | None = None
    waiver_gds_audit: Path | None = None
    assembly_gate: Path | None = None
    assembly_gds_audit: Path | None = None
    if args.qualification_profile == "canonical_tx":
        if args.kind != "block" or args.name not in {"spadmic_tx_packet_core", "spadmic_tx_ddr_strip"}:
            raise SystemExit("canonical_tx qualification is valid only for the two canonical TX blocks")
        gate_reports = [path for path in reports if path.name == "canonical_tx_ooc_gate.rpt"]
        if len(gate_reports) != 1:
            raise SystemExit("CANONICAL_TX_GATE_FAIL: exactly one canonical_tx_ooc_gate.rpt is required")
        canonical_tx_gate = gate_reports[0]
        gate = key_values(canonical_tx_gate)
        if gate.get("STATUS") != "PASS" or gate.get("RESULT") != "READY_FOR_PVS_CANDIDATE":
            raise SystemExit(
                "CANONICAL_TX_GATE_FAIL: canonical TX OOC report is not PASS/READY_FOR_PVS_CANDIDATE"
            )
        if gate.get("MACRO") != args.name:
            raise SystemExit(
                f"CANONICAL_TX_GATE_FAIL: report macro {gate.get('MACRO', 'MISSING')} != {args.name}"
            )
    elif args.qualification_profile == "canonical_tx_lvs_waiver":
        if args.kind != "block" or args.name != "spadmic_tx_packet_core":
            raise SystemExit(
                "canonical_tx_lvs_waiver qualification is valid only for spadmic_tx_packet_core"
            )
        gate_reports = [
            path for path in reports if path.name == "canonical_tx_lvs_waiver_gate.rpt"
        ]
        waiver_reports = [
            path for path in reports if path.name == "temporary_drc_waiver.rpt"
        ]
        audit_reports = [
            path for path in reports if path.name == "gds_export_audit.rpt"
        ]
        if len(gate_reports) != 1:
            raise SystemExit(
                "CANONICAL_TX_WAIVER_GATE_FAIL: exactly one "
                "canonical_tx_lvs_waiver_gate.rpt is required"
            )
        if len(waiver_reports) != 1:
            raise SystemExit(
                "CANONICAL_TX_WAIVER_GATE_FAIL: exactly one temporary_drc_waiver.rpt is required"
            )
        if len(audit_reports) != 1:
            raise SystemExit(
                "CANONICAL_TX_WAIVER_GATE_FAIL: exactly one gds_export_audit.rpt is required"
            )
        waiver_gate = gate_reports[0]
        waiver_report = waiver_reports[0]
        waiver_gds_audit = audit_reports[0]
        gate = key_values(waiver_gate)
        waiver = key_values(waiver_report)
        gds_audit = key_values(waiver_gds_audit)
        expected_gate = {
            "STATUS": "PASS",
            "RESULT": "READY_FOR_PROVISIONAL_PVS_DRC_LVS",
            "MACRO": args.name,
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
            if gate.get(key) != expected:
                raise SystemExit(
                    f"CANONICAL_TX_WAIVER_GATE_FAIL: {key}="
                    f"{gate.get(key, 'MISSING')} expected={expected}"
                )
        for key, expected in expected_waiver.items():
            if waiver.get(key) != expected:
                raise SystemExit(
                    f"CANONICAL_TX_WAIVER_GATE_FAIL: waiver {key}="
                    f"{waiver.get(key, 'MISSING')} expected={expected}"
                )
        if gds_audit.get("STATUS") != "PASS":
            raise SystemExit(
                "CANONICAL_TX_WAIVER_GATE_FAIL: mapped/merged GDS audit did not pass"
            )
    elif args.qualification_profile == "digital_assembly_tc":
        if args.kind != "assembly" or args.name not in ASSEMBLY_TOP_TO_PHASE:
            raise SystemExit(
                "DIGITAL_ASSEMBLY_GATE_FAIL: profile requires an implemented p00-p03 assembly top"
            )
        gate_reports = [
            path for path in reports if path.name == "digital_assembly_innovus_gate.rpt"
        ]
        audit_reports = [path for path in reports if path.name == "gds_export_audit.rpt"]
        if len(gate_reports) != 1 or len(audit_reports) != 1:
            raise SystemExit(
                "DIGITAL_ASSEMBLY_GATE_FAIL: exactly one Innovus gate and GDS export audit are required"
            )
        assembly_gate = gate_reports[0]
        assembly_gds_audit = audit_reports[0]
        gate = key_values(assembly_gate)
        gds_audit = key_values(assembly_gds_audit)
        expected_gate = {
            "STATUS": "PASS",
            "RESULT": "INNOVUS_HANDOFF_READY",
            "PHASE": ASSEMBLY_TOP_TO_PHASE[args.name],
            "TOP_MODULE": args.name,
            "SOURCE_TOP": args.name,
            "LAYOUT_TOP": args.name,
            "IMPLEMENTATION": "CUMULATIVE_SOFT_LOGIC",
            "HARD_MACRO_COUNT": "0",
            "CHILD_GDS_MERGE_COUNT": "0",
            "FLOORPLAN_GEOMETRY_STATUS": "PASS",
            "TC_SETUP_STATUS": "PASS",
            "TC_HOLD_STATUS": "PASS",
            "POSTROUTE_DESIGN_RULE_STATUS": "PASS",
            "INNOVUS_DRC_STATUS": "PASS",
            "REGULAR_CONNECTIVITY_STATUS": "PASS",
            "PG_CONNECTIVITY_STATUS": "PASS",
            "GDS_EXPORT_AUDIT_STATUS": "PASS",
            "PVS_BASE_DRC_STATUS": "NOT_RUN",
            "PVS_DENSITY_DRC_STATUS": "NOT_RUN",
            "PVS_LVS_STATUS": "NOT_RUN",
            "SIGNOFF_READY": "NO",
        }
        for key, expected in expected_gate.items():
            if gate.get(key) != expected:
                raise SystemExit(
                    f"DIGITAL_ASSEMBLY_GATE_FAIL: {key}={gate.get(key, 'MISSING')} "
                    f"expected={expected}"
                )
        expected_gds_audit = {
            "STATUS": "PASS",
            "GDS_FILE_STATUS": "PASS",
            "GDS_LAYER_MAP_STATUS": "PASS",
            "GDS_MERGE_STATUS": "PASS",
            "ERROR_COUNT": "0",
        }
        for key, expected in expected_gds_audit.items():
            if gds_audit.get(key) != expected:
                raise SystemExit(
                    f"DIGITAL_ASSEMBLY_GATE_FAIL: GDS audit {key}="
                    f"{gds_audit.get(key, 'MISSING')} expected={expected}"
                )
        if gate.get("GDS_SHA256") != digest(gds):
            raise SystemExit("DIGITAL_ASSEMBLY_GATE_FAIL: gate GDS hash does not match staged GDS")

    handoff_root = args.handoff_root.resolve()
    category = "blocks" if args.kind == "block" else "assemblies"
    package = handoff_root / category / args.name / args.version
    if package.exists():
        raise SystemExit(f"IMMUTABLE_PACKAGE_EXISTS: {package}")

    for directory in ["gds", "lef", "def", "netlist", "pdk", "reports", "logs", "manifests", "status", "pvs/drc", "pvs/lvs"]:
        (package / directory).mkdir(parents=True, exist_ok=True)

    copied: list[Path] = []
    copied.append(copy_file(gds, package / "gds" / f"{args.layout_top}.gds"))
    raw_netlist = copy_file(netlist, package / "netlist" / f"{args.source_top}.innovus.pg.v")
    copied.append(raw_netlist)
    package_lefs: list[Path] = []
    for lef in lefs:
        package_lef = copy_file(lef, package / "lef" / lef.name)
        copied.append(package_lef)
        package_lefs.append(package_lef)
    if def_file:
        copied.append(copy_file(def_file, package / "def" / f"{args.name}.def"))
    for report in reports:
        copied.append(copy_file(report, package / "reports" / report.name))
    for log in logs:
        copied.append(copy_file(log, package / "logs" / log.name))

    stdcell_cdl_source = (
        require_file(args.stdcell_cdl, "standard-cell CDL")
        if args.stdcell_cdl
        else first_existing(PDK_CANDIDATES["stdcell_cdl"], "stdcell_cdl")
    )
    package_cdl = copy_file(
        stdcell_cdl_source,
        package / "pdk" / "xh018_D_CELLS_JIHD.cdl",
    )
    copied.append(package_cdl)
    canonical_lvs_source = package / "netlist" / f"{args.source_top}.lvs.pg.v"
    lvs_source_status = package / "reports" / "lvs_source_preparation.rpt"
    try:
        prepare_lvs_source(
            input_netlist=raw_netlist,
            output_netlist=canonical_lvs_source,
            source_top=args.source_top,
            stdcell_cdl=package_cdl,
            lefs=package_lefs,
            status_path=lvs_source_status,
        )
    except ValueError as exc:
        raise SystemExit(str(exc)) from exc
    copied.extend([canonical_lvs_source, lvs_source_status])

    pdk_manifest: dict[str, dict[str, str | int]] = {
        "stdcell_cdl": {
            "source": str(stdcell_cdl_source),
            "package_local": str(package_cdl),
            "bytes": package_cdl.stat().st_size,
            "sha256": digest(package_cdl),
        }
    }
    if args.copy_shared_pdk:
        shared = handoff_root / "_shared" / "pdk" / "xh018_1131_jihd_v6_0"
        shared.mkdir(parents=True, exist_ok=True)
        for label, candidates in PDK_CANDIDATES.items():
            src = stdcell_cdl_source if label == "stdcell_cdl" else first_existing(candidates, label)
            dst = shared / src.name
            if dst.exists():
                if digest(dst) != digest(src):
                    raise SystemExit(f"shared PDK hash collision: {dst}")
            else:
                copy_file(src, dst)
            if label == "stdcell_cdl":
                pdk_manifest[label]["shared_local"] = str(dst)
            else:
                pdk_manifest[label] = {
                    "source": str(src),
                    "shared_local": str(dst),
                    "bytes": dst.stat().st_size,
                    "sha256": digest(dst),
                }

    rule_manifest = []
    for path in RULE_REFERENCES:
        entry: dict[str, str | int] = {"path": str(path), "status": "MISSING"}
        if path.is_file():
            entry.update(status="FILE", bytes=path.stat().st_size, sha256=digest(path))
        elif path.is_dir():
            entry.update(status="DIRECTORY_REFERENCE")
        rule_manifest.append(entry)

    repo = args.repo_root.resolve()
    manifest = {
        "schema": "spadmic.innovus_handoff.v1",
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "kind": args.kind,
        "name": args.name,
        "version": args.version,
        "state": args.state,
        "qualification_profile": args.qualification_profile,
        "package_root": str(package),
        "source_root": str(source_root),
        "layout_top": args.layout_top,
        "source_top": args.source_top,
        "lvs_source": str(canonical_lvs_source),
        "lvs_source_sha256": digest(canonical_lvs_source),
        "stdcell_cdl": str(package_cdl),
        "stdcell_cdl_sha256": digest(package_cdl),
        "canonical_name_note": canonical_note,
        "repo_branch": git_value(repo, "branch", "--show-current"),
        "repo_head": git_value(repo, "rev-parse", "HEAD"),
        "pdk_collateral": pdk_manifest,
        "foundry_rule_references": rule_manifest,
    }
    if waiver_gate and waiver_report and waiver_gds_audit:
        manifest["temporary_drc_waiver"] = {
            "status": "PASS",
            "scope": "EXACT_FOUR_INNOVUS_MET1_MIN_AREA_ONLY",
            "marker_count": 4,
            "nets": ["n_9677", "n_9693", "n_9696", "n_9697"],
            "pvs_drc_waiver": False,
            "lvs_diagnostic_only": True,
            "manual_fix_required": True,
            "block_promotion_authorized": False,
            "final_signoff_ready": False,
            "gate_report": f"reports/{waiver_gate.name}",
            "gate_report_sha256": digest(waiver_gate),
            "waiver_report": f"reports/{waiver_report.name}",
            "waiver_report_sha256": digest(waiver_report),
            "gds_audit_report": f"reports/{waiver_gds_audit.name}",
            "gds_audit_report_sha256": digest(waiver_gds_audit),
        }
    if assembly_gate and assembly_gds_audit:
        manifest["digital_assembly_tc_gate"] = {
            "status": "PASS",
            "phase": ASSEMBLY_TOP_TO_PHASE[args.name],
            "hard_macro_count": 0,
            "child_gds_merge_count": 0,
            "gate_report": f"reports/{assembly_gate.name}",
            "gate_report_sha256": digest(assembly_gate),
            "gds_audit_report": f"reports/{assembly_gds_audit.name}",
            "gds_audit_report_sha256": digest(assembly_gds_audit),
        }
    (package / "manifests" / "package.json").write_text(json.dumps(manifest, indent=2) + "\n")

    waiver_profile = args.qualification_profile == "canonical_tx_lvs_waiver"
    assembly_profile = args.qualification_profile == "digital_assembly_tc"
    (package / "status" / "qualification.rpt").write_text(
        "LABEL=SPADMIC_INNOVUS_HANDOFF\n"
        "PACKAGE_STATUS=CANDIDATE\n"
        "CANONICAL_NAME_STATUS=PASS\n"
        f"CANONICAL_TX_OOC_GATE_STATUS={'PASS' if canonical_tx_gate else 'NOT_REQUIRED'}\n"
        f"TEMPORARY_DRC_WAIVER_STATUS={'PASS' if waiver_profile else 'NOT_APPLICABLE'}\n"
        f"TEMPORARY_DRC_WAIVER_SCOPE={'EXACT_FOUR_INNOVUS_MET1_MIN_AREA_ONLY' if waiver_profile else 'NONE'}\n"
        f"TEMPORARY_DRC_WAIVER_MARKER_COUNT={'4' if waiver_profile else '0'}\n"
        f"PVS_DRC_WAIVER={'NO' if waiver_profile else 'NOT_APPLICABLE'}\n"
        f"LVS_DIAGNOSTIC_ONLY={'YES' if waiver_profile else 'NO'}\n"
        f"MANUAL_DRC_FIX_REQUIRED={'YES' if waiver_profile else 'NO'}\n"
        "BLOCK_PROMOTION_AUTHORIZED=NO\n"
        "LVS_SOURCE_PREPARATION_STATUS=PASS\n"
        "PIN_PARITY_STATUS=PASS\n"
        "STDCELL_CDL_STATUS=PASS\n"
        f"DIGITAL_ASSEMBLY_TC_GATE_STATUS={'PASS' if assembly_profile else 'NOT_APPLICABLE'}\n"
        f"HARD_MACRO_COUNT={'0' if assembly_profile else 'UNKNOWN'}\n"
        f"CHILD_GDS_MERGE_COUNT={'0' if assembly_profile else 'UNKNOWN'}\n"
        f"BBOX_PARITY_STATUS={'PASS' if assembly_profile else 'UNKNOWN'}\n"
        f"GDS_LAYER_MAP_STATUS={'PASS' if waiver_profile or assembly_profile else 'UNKNOWN'}\n"
        f"GDS_MERGE_STATUS={'PASS' if waiver_profile or assembly_profile else 'UNKNOWN'}\n"
        f"INTERNAL_PG_STATUS={'PASS' if assembly_profile else 'UNKNOWN'}\n"
        f"TC_TIMING_STATUS={'PASS' if assembly_profile else 'NOT_RUN'}\n"
        "PVS_BASE_DRC_STATUS=NOT_RUN\n"
        "PVS_DENSITY_DRC_STATUS=NOT_RUN\n"
        "PVS_LVS_STATUS=NOT_RUN\n"
        "SIGNOFF_READY=NO\n"
    )
    hash_lines = []
    for path in sorted(p for p in package.rglob("*") if p.is_file()):
        rel = path.relative_to(package)
        hash_lines.append(f"{digest(path)}  {rel}")
    (package / "manifests" / "SHA256SUMS").write_text("\n".join(hash_lines) + "\n")
    print(f"HANDOFF_PACKAGE={package}")
    print("HANDOFF_STAGE_STATUS=PASS")


if __name__ == "__main__":
    main()
