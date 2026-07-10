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
        choices=["basic", "canonical_tx"],
        default="basic",
    )
    args = parser.parse_args()

    if args.kind == "block":
        canonical_ok = args.layout_top == args.name and args.source_top == args.name
        canonical_note = "block layout/source/package names are identical"
    else:
        canonical_ok = args.layout_top == args.name and args.source_top == "spadmic_digital_assembly_v1"
        canonical_note = "phase-suffixed layout top with stable logical assembly source top"
    if not canonical_ok:
        raise SystemExit(
            "CANONICAL_TOP_GATE_FAIL: blocks require identical names; assemblies require "
            "layout-top=name and source-top=spadmic_digital_assembly_v1"
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
    (package / "manifests" / "package.json").write_text(json.dumps(manifest, indent=2) + "\n")

    (package / "status" / "qualification.rpt").write_text(
        "LABEL=SPADMIC_INNOVUS_HANDOFF\n"
        "PACKAGE_STATUS=CANDIDATE\n"
        "CANONICAL_NAME_STATUS=PASS\n"
        f"CANONICAL_TX_OOC_GATE_STATUS={'PASS' if canonical_tx_gate else 'NOT_REQUIRED'}\n"
        "LVS_SOURCE_PREPARATION_STATUS=PASS\n"
        "PIN_PARITY_STATUS=PASS\n"
        "STDCELL_CDL_STATUS=PASS\n"
        "BBOX_PARITY_STATUS=UNKNOWN\n"
        "PIN_PARITY_STATUS=UNKNOWN\n"
        "GDS_LAYER_MAP_STATUS=UNKNOWN\n"
        "INTERNAL_PG_STATUS=UNKNOWN\n"
        "PVS_DRC_STATUS=NOT_RUN\n"
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
