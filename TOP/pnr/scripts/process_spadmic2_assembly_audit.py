#!/usr/bin/env python3
"""Validate immutable SPADMIC2/matrice5 OA exports and derive assembly inputs."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
from collections import Counter
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


ROOT = Path(__file__).resolve().parents[3]
DEFAULT_CONTRACT = ROOT / "TOP/pnr/assembly/spadmic_digital_assembly_contract.json"
DEFAULT_POLICY = ROOT / "TOP/pnr/assembly/matrice5_unknown_family_policy.csv"
FAMILY_RE = re.compile(
    r"^(Rz|Yz|Bz|Dout|Cout|Din|Cin|R|Y|B)(?:[<\[](-?\d+)(?::(-?\d+))?[>\]])?$",
    re.IGNORECASE,
)
SUPPLY_RE = re.compile(r"^(?:[ad]?vdd|[ad]?vss|gnd)(?:[<\[].*)?$", re.IGNORECASE)
ALLOWED_UNKNOWN_DISPOSITIONS = {"ALLOW_P03", "IGNORE_NON_DIGITAL", "BLOCK"}


@dataclass(frozen=True)
class Rect:
    llx: float
    lly: float
    urx: float
    ury: float

    @property
    def width(self) -> float:
        return max(0.0, self.urx - self.llx)

    @property
    def height(self) -> float:
        return max(0.0, self.ury - self.lly)

    @property
    def area(self) -> float:
        return self.width * self.height

    def intersect(self, other: "Rect") -> "Rect | None":
        result = Rect(
            max(self.llx, other.llx),
            max(self.lly, other.lly),
            min(self.urx, other.urx),
            min(self.ury, other.ury),
        )
        return result if result.width > 0.0 and result.height > 0.0 else None

    def format(self) -> str:
        return f"{self.llx:.6f} {self.lly:.6f} {self.urx:.6f} {self.ury:.6f}"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--audit-root", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--contract", type=Path, default=DEFAULT_CONTRACT)
    parser.add_argument("--unknown-family-policy", type=Path, default=DEFAULT_POLICY)
    return parser.parse_args()


def read_tsv(path: Path, required: Iterable[str]) -> list[dict[str, str]]:
    if not path.is_file():
        raise ValueError(f"missing audit export: {path}")
    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        missing = sorted(set(required) - set(reader.fieldnames or []))
        if missing:
            raise ValueError(f"{path}: missing columns {missing}")
        return list(reader)


def write_tsv(path: Path, fields: list[str], rows: Iterable[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fields, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fields})


def rect_from_row(row: dict[str, str]) -> Rect:
    return Rect(*(float(row[key]) for key in ("llx", "lly", "urx", "ury")))


def subtract_rect(source: Rect, obstacle: Rect) -> list[Rect]:
    overlap = source.intersect(obstacle)
    if overlap is None:
        return [source]
    candidates = [
        Rect(source.llx, source.lly, overlap.llx, source.ury),
        Rect(overlap.urx, source.lly, source.urx, source.ury),
        Rect(overlap.llx, source.lly, overlap.urx, overlap.lly),
        Rect(overlap.llx, overlap.ury, overlap.urx, source.ury),
    ]
    return [rect for rect in candidates if rect.area > 1.0]


def free_rectangles(boundary: Rect, obstacles: Iterable[Rect]) -> list[Rect]:
    free = [boundary]
    for obstacle in obstacles:
        next_free: list[Rect] = []
        for candidate in free:
            next_free.extend(subtract_rect(candidate, obstacle))
        free = next_free
    unique = {(r.llx, r.lly, r.urx, r.ury): r for r in free}
    return sorted(unique.values(), key=lambda rect: (-rect.area, rect.llx, rect.lly))


def canonical_family(name: str) -> tuple[str | None, set[int]]:
    compact = name.strip().lstrip("\\").replace(" ", "")
    match = FAMILY_RE.fullmatch(compact)
    if not match:
        return None, set()
    raw_family, first, second = match.groups()
    family_map = {
        "r": "R", "y": "Y", "b": "B", "rz": "Rz", "yz": "Yz",
        "bz": "Bz", "din": "Din", "cin": "Cin", "dout": "Dout", "cout": "Cout",
    }
    family = family_map[raw_family.lower()]
    if first is None:
        return family, set()
    start = int(first)
    stop = int(second) if second is not None else start
    step = 1 if stop >= start else -1
    return family, set(range(start, stop + step, step))


def load_policy(path: Path) -> dict[str, str]:
    rows = read_tsv(path, []) if path.suffix == ".tsv" else []
    if path.suffix != ".tsv":
        if not path.is_file():
            return {}
        with path.open(newline="", encoding="utf-8") as handle:
            rows = list(csv.DictReader(handle))
    policy: dict[str, str] = {}
    for row in rows:
        family = row.get("family", "").strip()
        disposition = row.get("disposition", "").strip().upper()
        if not family:
            continue
        if disposition not in ALLOWED_UNKNOWN_DISPOSITIONS:
            raise ValueError(f"invalid disposition for {family}: {disposition}")
        policy[family] = disposition
    return policy


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def split_guides(region: Rect, groups: list[str]) -> list[dict[str, object]]:
    if not groups:
        return []
    horizontal = region.width >= region.height
    span = region.width if horizontal else region.height
    result: list[dict[str, object]] = []
    for index, group in enumerate(groups):
        low = span * index / len(groups)
        high = span * (index + 1) / len(groups)
        if horizontal:
            guide = Rect(region.llx + low, region.lly, region.llx + high, region.ury)
        else:
            guide = Rect(region.llx, region.lly + low, region.urx, region.lly + high)
        result.append(
            {
                "group": group,
                "guide_kind": "SOFT",
                "llx": f"{guide.llx:.6f}",
                "lly": f"{guide.lly:.6f}",
                "urx": f"{guide.urx:.6f}",
                "ury": f"{guide.ury:.6f}",
                "target_utilization": "0.600",
                "max_local_density": "0.700",
                "spill_policy": "VERIFIED_DIGITAL_WHITESPACE_ONLY",
            }
        )
    return result


def write_status(path: Path, values: dict[str, object]) -> None:
    path.write_text("".join(f"{key}={value}\n" for key, value in values.items()), encoding="utf-8")


def main() -> int:
    args = parse_args()
    audit = args.audit_root.resolve()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    status_path = out / "assembly_audit_status.rpt"
    status: dict[str, object] = {
        "LABEL": "SPADMIC2_MATRICE5_IMMUTABLE_ASSEMBLY_AUDIT",
        "STATUS": "FAIL",
        "RESULT": "AUDIT_CONTRACT_REJECTED",
        "SOURCE_MUTATION_AUTHORIZED": "NO",
        "P00_P02_IMPLEMENTATION_AUTHORIZED": "NO",
        "P03_IMPLEMENTATION_AUTHORIZED": "NO",
        "SIGNOFF_READY": "NO",
    }
    try:
        contract = json.loads(args.contract.read_text(encoding="utf-8"))
        identity = read_tsv(
            audit / "source_identity.tsv",
            ["role", "library", "cell", "view", "filesystem_path", "open_status", "bbox"],
        )
        instances = read_tsv(
            audit / "spadmic2_instances.tsv",
            ["instance", "master_library", "master_cell", "master_view", "orient", "llx", "lly", "urx", "ury"],
        )
        matrix_terms = read_tsv(
            audit / "matrice5_top_terminals.tsv",
            ["terminal", "direction", "net", "layer", "purpose", "llx", "lly", "urx", "ury"],
        )
        instance_pins = read_tsv(
            audit / "spadmic2_instance_pins.tsv",
            ["instance", "terminal", "direction", "net", "layer", "purpose", "llx", "lly", "urx", "ury"],
        )
        top_shapes = read_tsv(
            audit / "spadmic2_top_shapes.tsv",
            ["shape_type", "net", "layer", "purpose", "llx", "lly", "urx", "ury"],
        )

        expected_sources = contract["source_layouts"]
        by_role = {row["role"]: row for row in identity}
        source_gate = True
        for role, expected in expected_sources.items():
            row = by_role.get(role)
            if not row:
                source_gate = False
                continue
            source_gate &= all(
                row[key] == expected[key]
                for key in ("library", "cell", "view", "filesystem_path")
            )
            source_gate &= row["open_status"] == "PASS"

        matrix_instances = [
            row for row in instances
            if row["master_library"] == expected_sources["matrice5"]["library"]
            and row["master_cell"] == expected_sources["matrice5"]["cell"]
            and row["master_view"] == expected_sources["matrice5"]["view"]
        ]
        exact_matrix_gate = len(matrix_instances) == 1
        matrix_instance = matrix_instances[0] if exact_matrix_gate else None

        expected_families = contract["matrix_terminal_families"]
        observed_indices: dict[str, set[int]] = {name: set() for name in expected_families}
        observed_unindexed: Counter[str] = Counter()
        observed_directions: dict[str, set[str]] = {name: set() for name in expected_families}
        unknown_names: set[str] = set()
        for row in matrix_terms:
            family, indices = canonical_family(row["terminal"])
            if family is None:
                unknown_names.add(row["terminal"].strip())
                continue
            if indices:
                observed_indices[family].update(indices)
            else:
                observed_unindexed[family] += 1
            observed_directions[family].add(row["direction"].strip().upper())

        family_rows: list[dict[str, object]] = []
        parity_gate = True
        for family, expected in expected_families.items():
            expected_set = set(range(int(expected["width"])))
            actual_set = observed_indices[family]
            if not actual_set and observed_unindexed[family] == int(expected["width"]):
                actual_set = expected_set
            index_status = "PASS" if actual_set == expected_set else "FAIL"
            direction_status = (
                "PASS" if observed_directions[family] == {expected["direction"]} else "FAIL"
            )
            parity_gate &= index_status == "PASS" and direction_status == "PASS"
            family_rows.append(
                {
                    "family": family,
                    "expected_width": expected["width"],
                    "observed_index_count": len(actual_set),
                    "unindexed_terminal_count": observed_unindexed[family],
                    "expected_direction": expected["direction"],
                    "observed_directions": ",".join(sorted(observed_directions[family])) or "ABSENT",
                    "index_status": index_status,
                    "direction_status": direction_status,
                }
            )
        write_tsv(
            out / "matrice5_terminal_family_contract.tsv",
            ["family", "expected_width", "observed_index_count", "unindexed_terminal_count", "expected_direction", "observed_directions", "index_status", "direction_status"],
            family_rows,
        )

        policy = load_policy(args.unknown_family_policy)
        unknown_rows = []
        unknown_gate = True
        for name in sorted(unknown_names):
            family = "SUPPLY" if SUPPLY_RE.match(name) else name.split("<", 1)[0].split("[", 1)[0]
            disposition = policy.get(family, "UNCLASSIFIED")
            if disposition not in {"ALLOW_P03", "IGNORE_NON_DIGITAL"}:
                unknown_gate = False
            unknown_rows.append(
                {"terminal": name, "family": family, "disposition": disposition, "p03_status": "PASS" if disposition in {"ALLOW_P03", "IGNORE_NON_DIGITAL"} else "BLOCK"}
            )
        write_tsv(out / "matrice5_unknown_families.tsv", ["terminal", "family", "disposition", "p03_status"], unknown_rows)

        bbox_tokens = by_role.get("spadmic2", {}).get("bbox", "").split()
        if len(bbox_tokens) != 4:
            raise ValueError("SPADMIC2 source bbox is missing or malformed")
        die = Rect(*(float(value) for value in bbox_tokens))
        obstacle_rows = []
        obstacles: list[Rect] = []
        for row in instances:
            rect = rect_from_row(row)
            obstacles.append(rect)
            obstacle_rows.append(
                {
                    "instance": row["instance"], "master_library": row["master_library"],
                    "master_cell": row["master_cell"], "master_view": row["master_view"],
                    "orient": row["orient"], "llx": f"{rect.llx:.6f}", "lly": f"{rect.lly:.6f}",
                    "urx": f"{rect.urx:.6f}", "ury": f"{rect.ury:.6f}", "policy": "FIXED_OBSTACLE",
                }
            )
        write_tsv(
            out / "fixed_obstacles.tsv",
            ["instance", "master_library", "master_cell", "master_view", "orient", "llx", "lly", "urx", "ury", "policy"],
            obstacle_rows,
        )

        free = free_rectangles(die, obstacles)
        free_rows = [
            {"rank": index + 1, "llx": f"{rect.llx:.6f}", "lly": f"{rect.lly:.6f}", "urx": f"{rect.urx:.6f}", "ury": f"{rect.ury:.6f}", "area_um2": f"{rect.area:.6f}", "status": "VERIFIED_NO_INSTANCE_BBOX_OVERLAP"}
            for index, rect in enumerate(free)
        ]
        write_tsv(out / "verified_digital_whitespace.tsv", ["rank", "llx", "lly", "urx", "ury", "area_um2", "status"], free_rows)
        if not free:
            raise ValueError("no instance-bbox-free SPADMIC2 whitespace remains")

        all_groups = contract["phases"]["p03_matrix_interface"]["groups"]
        guide_rows = split_guides(free[0], all_groups)
        write_tsv(
            out / "soft_group_guides.tsv",
            ["group", "guide_kind", "llx", "lly", "urx", "ury", "target_utilization", "max_local_density", "spill_policy"],
            guide_rows,
        )
        with (out / "soft_group_guides.tcl").open("w", encoding="utf-8") as handle:
            handle.write("# Audit-derived elastic guides; source OA remains immutable.\n")
            handle.write("namespace eval spadmic_da_guides { variable guides\n")
            for row in guide_rows:
                handle.write(f"  set guides({row['group']}) {{{row['llx']} {row['lly']} {row['urx']} {row['ury']}}}\n")
            handle.write("}\n")

        matrix_name = matrix_instance["instance"] if matrix_instance else "ABSENT"
        proxy_rows = []
        proxy_indices: dict[str, set[int]] = {name: set() for name in expected_families}
        for row in instance_pins:
            if row["instance"] != matrix_name:
                continue
            family, indices = canonical_family(row["terminal"])
            if family in expected_families:
                for index in sorted(indices):
                    proxy_indices[family].add(index)
                    proxy_rows.append(
                        {
                            **row,
                            "family": family,
                            "index": index,
                            "access_policy": "EXACT_AUDITED_TOP_COORDINATE",
                        }
                    )
        write_tsv(
            out / "matrice5_proxy_pin_access.tsv",
            ["instance", "terminal", "family", "index", "direction", "net", "layer", "purpose", "llx", "lly", "urx", "ury", "access_policy"],
            proxy_rows,
        )
        proxy_gate = all(
            proxy_indices[family] == set(range(int(expected["width"])))
            for family, expected in expected_families.items()
        )

        pg_rows = []
        for row in top_shapes:
            net = row["net"].upper()
            if net in {"VDD", "VSS"}:
                pg_rows.append({**row, "anchor_status": "AUDITED_TOP_SHAPE"})
        write_tsv(
            out / "pg_overlap_anchors.tsv",
            ["shape_type", "net", "layer", "purpose", "llx", "lly", "urx", "ury", "anchor_status"],
            pg_rows,
        )
        mettp_pg_rows = [
            row for row in pg_rows
            if row["layer"].strip().upper() == "METTP"
            and rect_from_row(row).area > 0.0
        ]
        pg_gate = {row["net"].upper() for row in mettp_pg_rows} == {"VDD", "VSS"}

        p00_p02_gate = source_gate and exact_matrix_gate and pg_gate
        p03_gate = p00_p02_gate and parity_gate and unknown_gate and proxy_gate
        status.update(
            {
                "STATUS": "PASS" if p00_p02_gate else "FAIL",
                "RESULT": "AUDIT_CONTRACT_ACCEPTED" if p00_p02_gate else "AUDIT_CONTRACT_REJECTED",
                "CONTRACT_SCHEMA": contract["schema"],
                "CONTRACT_SHA256": sha256(args.contract),
                "SOURCE_IDENTITY_GATE_STATUS": "PASS" if source_gate else "FAIL",
                "EXACT_MATRICE5_INSTANCE_GATE_STATUS": "PASS" if exact_matrix_gate else "FAIL",
                "MATRICE5_INSTANCE": matrix_name,
                "MATRICE5_INSTANCE_COUNT": len(matrix_instances),
                "MATRIX_TERMINAL_PARITY_STATUS": "PASS" if parity_gate else "FAIL",
                "UNKNOWN_FAMILY_GATE_STATUS": "PASS" if unknown_gate else "FAIL",
                "UNKNOWN_TERMINAL_COUNT": len(unknown_names),
                "MATRIX_PROXY_PIN_SHAPE_COUNT": len(proxy_rows),
                "MATRIX_PROXY_PIN_ACCESS_STATUS": "PASS" if proxy_gate else "FAIL",
                "PG_ANCHOR_GATE_STATUS": "PASS" if pg_gate else "FAIL",
                "VDD_ANCHOR_COUNT": sum(row["net"].upper() == "VDD" for row in pg_rows),
                "VSS_ANCHOR_COUNT": sum(row["net"].upper() == "VSS" for row in pg_rows),
                "VDD_METTP_ANCHOR_COUNT": sum(
                    row["net"].upper() == "VDD" for row in mettp_pg_rows
                ),
                "VSS_METTP_ANCHOR_COUNT": sum(
                    row["net"].upper() == "VSS" for row in mettp_pg_rows
                ),
                "VERIFIED_WHITESPACE_RECT_COUNT": len(free),
                "SPADMIC2_DIE_BBOX_UM": die.format(),
                "GUIDE_SOURCE_RECT": free[0].format(),
                "P00_P02_IMPLEMENTATION_AUTHORIZED": "YES" if p00_p02_gate else "NO",
                "P03_IMPLEMENTATION_AUTHORIZED": "YES" if p03_gate else "NO",
                "NEXT_GATE": "REVIEW_AUDIT_THEN_RUN_P00" if p00_p02_gate else "STOP_AND_RECONCILE_OA_AUDIT",
            }
        )
        if p00_p02_gate and not p03_gate:
            status["NEXT_GATE_AFTER_P02"] = "CLASSIFY_MATRICE5_UNKNOWN_FAMILIES_OR_FIX_PIN_PARITY"
    except Exception as exc:
        status["ERROR"] = str(exc).replace("\n", " ")
        write_status(status_path, status)
        print(f"ASSEMBLY_AUDIT_STATUS={status_path}")
        print(f"ERROR={status['ERROR']}")
        return 2

    write_status(status_path, status)
    manifest_files = sorted(path for path in out.rglob("*") if path.is_file() and path.name != "SHA256SUMS")
    with (out / "SHA256SUMS").open("w", encoding="utf-8") as handle:
        for path in manifest_files:
            handle.write(f"{sha256(path)}  {path.relative_to(out)}\n")
    print(f"ASSEMBLY_AUDIT_STATUS={status_path}")
    print(f"P00_P02_IMPLEMENTATION_AUTHORIZED={status['P00_P02_IMPLEMENTATION_AUTHORIZED']}")
    print(f"P03_IMPLEMENTATION_AUTHORIZED={status['P03_IMPLEMENTATION_AUTHORIZED']}")
    return 0 if status["STATUS"] == "PASS" else 2


if __name__ == "__main__":
    raise SystemExit(main())
