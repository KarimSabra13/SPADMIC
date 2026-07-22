#!/usr/bin/env python3
"""Generate one audit-bound cumulative soft assembly phase contract."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
from dataclasses import dataclass, field
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
DEFAULT_CONTRACT = ROOT / "TOP/pnr/assembly/spadmic_digital_assembly_contract.json"
DEFAULT_RTL = ROOT / "TOP/pnr/assembly/spadmic_digital_assembly_v1.sv"

GROUP_PATTERNS = {
    "tx_packet": "*u_tx_packet_core*",
    "tx_ddr_strip": "*u_tx_ddr_strip*",
    "position": "*u_position*",
    "event": "*u_event*",
    "matrix_or": "*u_matrix_or_*",
    "matrix_snapshot_reset": "*u_matrix_snapshot* *u_matrix_reset*",
    "matrix_cfg": "*u_matrix_cfg*",
}

FAMILY_PORTS = {
    "R": "R_i",
    "Y": "Y_i",
    "B": "B_i",
    "Rz": "Rz_o",
    "Yz": "Yz_o",
    "Bz": "Bz_o",
    "Din": "matrix_din_o",
    "Cin": "matrix_cin_o",
    "Dout": "matrix_dout_i",
    "Cout": "matrix_cout_i",
}


# Legacy TX OOC validators import this parser from this module. Keep the parser
# API stable even though the active assembly generator no longer places child
# LEF macros.
@dataclass(frozen=True)
class Rect:
    layer: str
    llx: float
    lly: float
    urx: float
    ury: float

    @property
    def cx(self) -> float:
        return (self.llx + self.urx) / 2.0


@dataclass
class Pin:
    name: str
    direction: str = "INOUT"
    use: str = "SIGNAL"
    rects: list[Rect] = field(default_factory=list)

    def primary_rect(self) -> Rect:
        if not self.rects:
            raise ValueError(f"pin has no RECT geometry: {self.name}")
        return self.rects[0]


@dataclass
class Macro:
    name: str
    width: float
    height: float
    symmetry: set[str]
    pins: dict[str, Pin]
    lef: Path


def parse_lef(path: Path) -> Macro:
    if not path.is_file():
        raise ValueError(f"LEF missing: {path}")
    macro_name = ""
    width: float | None = None
    height: float | None = None
    symmetry: set[str] = set()
    pins: dict[str, Pin] = {}
    current_pin: Pin | None = None
    current_layer = ""
    for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        match = re.match(r"MACRO\s+(\S+)", line)
        if match and not macro_name:
            macro_name = match.group(1)
            continue
        match = re.match(r"SIZE\s+([-+0-9.eE]+)\s+BY\s+([-+0-9.eE]+)", line)
        if match and width is None:
            width, height = float(match.group(1)), float(match.group(2))
            continue
        match = re.match(r"SYMMETRY\s+(.+?)\s*;?$", line)
        if match and current_pin is None:
            symmetry.update(token.rstrip(";") for token in match.group(1).split())
            continue
        match = re.match(r"PIN\s+(\S+)", line)
        if match:
            current_pin = Pin(name=match.group(1))
            pins[current_pin.name] = current_pin
            current_layer = ""
            continue
        if current_pin is None:
            continue
        match = re.match(r"DIRECTION\s+(\S+)", line)
        if match:
            current_pin.direction = match.group(1).rstrip(";").upper()
            continue
        match = re.match(r"USE\s+(\S+)", line)
        if match:
            current_pin.use = match.group(1).rstrip(";").upper()
            continue
        match = re.match(r"LAYER\s+(\S+)", line)
        if match:
            current_layer = match.group(1).rstrip(";")
            continue
        match = re.match(
            r"RECT\s+([-+0-9.eE]+)\s+([-+0-9.eE]+)\s+"
            r"([-+0-9.eE]+)\s+([-+0-9.eE]+)",
            line,
        )
        if match:
            current_pin.rects.append(
                Rect(current_layer, *(float(match.group(index)) for index in range(1, 5)))
            )
            continue
        if re.match(rf"END\s+{re.escape(current_pin.name)}$", line):
            current_pin = None
            current_layer = ""
    if not macro_name or width is None or height is None:
        raise ValueError(f"LEF macro header incomplete: {path}")
    return Macro(macro_name, width, height, symmetry, pins, path.resolve())


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--phase", required=True)
    parser.add_argument("--audit-root", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--contract", type=Path, default=DEFAULT_CONTRACT)
    parser.add_argument("--rtl", type=Path, default=DEFAULT_RTL)
    return parser.parse_args()


def read_kv(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            values[key] = value
    return values


def read_tsv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle, delimiter="\t"))


def write_tsv(path: Path, fields: list[str], rows: list[dict[str, object]]) -> None:
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fields, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fields})


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def render_config(
    phase: str,
    phase_data: dict[str, object],
    contract: dict[str, object],
    obstacles: list[dict[str, str]],
    guides: list[dict[str, str]],
    pg_anchors: list[dict[str, str]],
    die_bbox: str,
) -> str:
    top = str(phase_data["top"])
    physical = contract["physical_policy"]
    lines = [
        "# Generated soft-assembly physical contract.",
        "namespace eval spadmic_da_phase {",
        f"  variable phase {{{phase}}}",
        f"  variable top {{{top}}}",
        "  variable source_top {" + top + "}",
        "  variable layout_top {" + top + "}",
        f"  variable target_utilization {physical['target_utilization']}",
        f"  variable max_local_density {physical['max_local_density']}",
        f"  variable die_bbox {{{die_bbox}}}",
        "  variable signal_bottom_layer {MET1}",
        "  variable signal_top_layer {MET3}",
        "  variable mettp_policy {PG_AND_BOUNDED_PIN_ACCESS_ONLY}",
        "  variable hard_macro_count 0",
        "  variable child_gds_merge_count 0",
        "  variable groups {" + " ".join(str(group) for group in phase_data["groups"]) + "}",
        "  variable group_patterns",
    ]
    for group in phase_data["groups"]:
        lines.append(f"  set group_patterns({group}) {{{GROUP_PATTERNS[str(group)]}}}")
    lines.extend(["  variable guides", "  variable obstacles", "  variable pg_anchors"])
    for row in guides:
        if row["group"] in phase_data["groups"]:
            box = " ".join(row[key] for key in ("llx", "lly", "urx", "ury"))
            lines.append(f"  set guides({row['group']}) {{{box}}}")
    for index, row in enumerate(obstacles):
        box = " ".join(row[key] for key in ("llx", "lly", "urx", "ury"))
        lines.append(f"  set obstacles({index}) {{{box}}}")
    for net in ("VDD", "VSS"):
        boxes = [
            "{" + " ".join(row[key] for key in ("llx", "lly", "urx", "ury")) + "}"
            for row in pg_anchors
            if row["net"].upper() == net
            and row["layer"].strip().upper() == "METTP"
        ]
        lines.append(f"  set pg_anchors({net}) {{{' '.join(boxes)}}}")
    lines.append("}")
    return "\n".join(lines) + "\n"


def main() -> int:
    args = parse_args()
    contract = json.loads(args.contract.read_text(encoding="utf-8"))
    phases = contract["phases"]
    if args.phase not in phases:
        raise SystemExit(f"unknown assembly phase: {args.phase}")
    phase_data = phases[args.phase]
    top = phase_data["top"]
    rtl_text = args.rtl.read_text(encoding="utf-8")
    if f"module {top} (" not in rtl_text:
        raise SystemExit(f"phase top missing from RTL: {top}")

    audit = args.audit_root.resolve()
    status_file = audit / "assembly_audit_status.rpt"
    if not status_file.is_file():
        raise SystemExit(f"assembly audit status missing: {status_file}")
    audit_status = read_kv(status_file)
    if audit_status.get("STATUS") != "PASS" or audit_status.get("P00_P02_IMPLEMENTATION_AUTHORIZED") != "YES":
        raise SystemExit("assembly audit does not authorize p00-p02 implementation")
    if args.phase == "p03_matrix_interface" and audit_status.get("P03_IMPLEMENTATION_AUTHORIZED") != "YES":
        raise SystemExit("assembly audit does not authorize p03 matrix implementation")

    required = {
        "fixed_obstacles.tsv": ["instance", "llx", "lly", "urx", "ury"],
        "soft_group_guides.tsv": ["group", "llx", "lly", "urx", "ury"],
        "pg_overlap_anchors.tsv": ["net", "layer", "llx", "lly", "urx", "ury"],
    }
    tables: dict[str, list[dict[str, str]]] = {}
    for name, columns in required.items():
        path = audit / name
        if not path.is_file():
            raise SystemExit(f"required audit contract missing: {path}")
        rows = read_tsv(path)
        missing = sorted(set(columns) - set(rows[0] if rows else []))
        if missing:
            raise SystemExit(f"{path}: missing columns {missing}")
        tables[name] = rows

    out = args.out.resolve()
    if out.exists() and any(out.iterdir()):
        raise SystemExit(f"immutable phase contract output already populated: {out}")
    out.mkdir(parents=True, exist_ok=True)

    (out / "assembly_phase_config.tcl").write_text(
        render_config(
            args.phase,
            phase_data,
            contract,
            tables["fixed_obstacles.tsv"],
            tables["soft_group_guides.tsv"],
            tables["pg_overlap_anchors.tsv"],
            audit_status["SPADMIC2_DIE_BBOX_UM"],
        ),
        encoding="utf-8",
    )
    for name, rows in tables.items():
        fields = list(rows[0]) if rows else required[name]
        write_tsv(out / name, fields, rows)

    proxy_rows: list[dict[str, object]] = []
    proxy_source = audit / "matrice5_proxy_pin_access.tsv"
    if args.phase == "p03_matrix_interface":
        for row in read_tsv(proxy_source):
            index = int(row["index"])
            proxy_rows.append(
                {
                    "port": f"{FAMILY_PORTS[row['family']]}[{index}]",
                    "matrix_terminal": row["terminal"],
                    "family": row["family"],
                    "index": index,
                    "direction": row["direction"],
                    "layer": row["layer"],
                    "purpose": row["purpose"],
                    "llx": row["llx"], "lly": row["lly"],
                    "urx": row["urx"], "ury": row["ury"],
                    "placement_policy": "EXACT_AUDITED_GLOBAL_PROXY_SHAPE",
                }
            )
    write_tsv(
        out / "matrix_proxy_pin_plan.tsv",
        ["port", "matrix_terminal", "family", "index", "direction", "layer", "purpose", "llx", "lly", "urx", "ury", "placement_policy"],
        proxy_rows,
    )

    status = {
        "LABEL": "SPADMIC_DIGITAL_ASSEMBLY_PHASE_CONTRACT",
        "STATUS": "PASS",
        "RESULT": "PHASE_CONTRACT_READY_FOR_FRESH_GENUS_AND_INNOVUS",
        "PHASE": args.phase,
        "SOURCE_TOP": top,
        "LAYOUT_TOP": top,
        "IMPLEMENTATION": "CUMULATIVE_SOFT_LOGIC",
        "GROUPS": ",".join(phase_data["groups"]),
        "HARD_MACRO_COUNT": 0,
        "CHILD_GDS_MERGE_COUNT": 0,
        "TARGET_UTILIZATION": contract["physical_policy"]["target_utilization"],
        "MAX_LOCAL_DENSITY": contract["physical_policy"]["max_local_density"],
        "SPADMIC2_DIE_BBOX_UM": audit_status["SPADMIC2_DIE_BBOX_UM"],
        "SIGNAL_ROUTE_LAYERS": "MET1-MET3",
        "METTP_POLICY": "PG_AND_BOUNDED_PIN_ACCESS_ONLY",
        "PG_ANCHOR_STATUS": "PASS",
        "DENSITY_GATE": phase_data["density_gate"],
        "METAL_FILL_STATUS": "DEFERRED_TO_FINAL_CHIP_INTEGRATION",
        "SOURCE_AUDIT_ROOT": audit,
        "SOURCE_AUDIT_STATUS_SHA256": sha256(status_file),
        "RTL_SHA256": sha256(args.rtl),
        "CONTRACT_SHA256": sha256(args.contract),
        "SIGNOFF_READY": "NO",
        "NEXT_GATE": "RUN_PHASE_RTL_REGRESSION",
    }
    with (out / "assembly_phase_contract_status.rpt").open("w", encoding="utf-8") as handle:
        for key, value in status.items():
            handle.write(f"{key}={value}\n")

    files = sorted(path for path in out.iterdir() if path.name != "SHA256SUMS")
    with (out / "SHA256SUMS").open("w", encoding="utf-8") as handle:
        for path in files:
            handle.write(f"{sha256(path)}  {path.name}\n")
    print(f"ASSEMBLY_PHASE={args.phase}")
    print(f"ASSEMBLY_TOP={top}")
    print(f"ASSEMBLY_CONTRACT_ROOT={out}")
    print("ASSEMBLY_PHASE_CONTRACT_STATUS=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
