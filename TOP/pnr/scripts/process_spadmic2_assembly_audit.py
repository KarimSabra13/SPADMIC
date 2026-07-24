#!/usr/bin/env python3
"""Validate immutable SPADMIC2/matrice5 OA exports and derive assembly inputs."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
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
METTP_CONTEXT_CANDIDATE_LIMIT = 20
CONTACT_RELATIONS = {"AREA_OVERLAP", "BOUNDARY_TOUCH", "CORNER_TOUCH"}
CONDUCTIVE_SHAPE_TYPES = {"PATH", "PATHSEG", "POLYGON", "RECT"}
SUPPLY_LIKE_TOKEN_RE = re.compile(
    r"^(?:[AD]?VDD|[AD]?VSS|VDDO\d*|GNDO\d*|GND\d*|PSUB|SUB)$",
    re.IGNORECASE,
)


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

    def translate(self, dx: float, dy: float) -> "Rect":
        return Rect(
            self.llx + dx,
            self.lly + dy,
            self.urx + dx,
            self.ury + dy,
        )


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


def is_conductive_shape(row: dict[str, str]) -> bool:
    return row["shape_type"].strip().upper() in CONDUCTIVE_SHAPE_TYPES


def rect_from_bbox(value: str, role: str) -> Rect:
    tokens = value.split()
    if len(tokens) != 4:
        raise ValueError(f"{role} source bbox is missing or malformed")
    return Rect(*(float(token) for token in tokens))


def same_dimension(left: float, right: float) -> bool:
    return math.isclose(left, right, rel_tol=0.0, abs_tol=1e-6)


def axis_gap(first_low: float, first_high: float, second_low: float, second_high: float) -> float:
    if first_high < second_low:
        return second_low - first_high
    if second_high < first_low:
        return first_low - second_high
    return 0.0


def rect_relation(first: Rect, second: Rect) -> tuple[str, float, float, float]:
    overlap_x = min(first.urx, second.urx) - max(first.llx, second.llx)
    overlap_y = min(first.ury, second.ury) - max(first.lly, second.lly)
    gap_x = axis_gap(first.llx, first.urx, second.llx, second.urx)
    gap_y = axis_gap(first.lly, first.ury, second.lly, second.ury)
    distance = math.hypot(gap_x, gap_y)
    if overlap_x > 0.0 and overlap_y > 0.0:
        relation = "AREA_OVERLAP"
    elif same_dimension(gap_x, 0.0) and same_dimension(gap_y, 0.0):
        relation = (
            "BOUNDARY_TOUCH"
            if overlap_x > 0.0 or overlap_y > 0.0
            else "CORNER_TOUCH"
        )
    else:
        relation = "SEPARATED"
    return relation, gap_x, gap_y, distance


def net_classification(net: str) -> str:
    normalized = net.strip().upper()
    if normalized in {"VDD", "VSS"}:
        return "EXACT_DIGITAL_PG"
    tokens = [token for token in re.split(r"[^A-Z0-9]+", normalized) if token]
    if any(SUPPLY_LIKE_TOKEN_RE.fullmatch(token) for token in tokens):
        return "SUPPLY_LIKE_REVIEW"
    return "OTHER_NET"


def shape_context_sort_key(row: dict[str, object]) -> tuple[object, ...]:
    return (
        float(row["bbox_distance_um"]),
        str(row["candidate_net"]),
        str(row["candidate_layer"]),
        str(row["candidate_purpose"]),
        float(row["candidate_llx"]),
        float(row["candidate_lly"]),
        float(row["candidate_urx"]),
        float(row["candidate_ury"]),
    )


def nearest_context_value(
    rows: list[dict[str, object]],
    field: str,
) -> str:
    return str(rows[0][field]) if rows else "NONE"


def infer_r0_translation(source: Rect, placed: Rect, orient: str) -> tuple[float, float] | None:
    normalized_orient = orient.strip().upper()
    if normalized_orient not in {"", "ABSENT", "R0"}:
        return None
    if not (
        same_dimension(source.width, placed.width)
        and same_dimension(source.height, placed.height)
    ):
        return None
    dx = placed.llx - source.llx
    dy = placed.lly - source.lly
    translated = source.translate(dx, dy)
    if not all(
        same_dimension(actual, expected)
        for actual, expected in zip(
            (translated.llx, translated.lly, translated.urx, translated.ury),
            (placed.llx, placed.lly, placed.urx, placed.ury),
        )
    ):
        return None
    return dx, dy


def direction_policy(observed: set[str], expected: str) -> tuple[str, str]:
    expected_upper = expected.strip().upper()
    if observed == {expected_upper}:
        return "PASS", "EXACT_LOGICAL_DIRECTION"
    if observed == {"INPUTOUTPUT"}:
        return "PASS", "OA_INPUTOUTPUT_WITH_CONTRACT_LOGICAL_DIRECTION"
    return "FAIL", "DIRECTION_MISMATCH"


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


def policy_values(value: str | None) -> set[str]:
    return {
        token.strip().upper()
        for token in (value or "").split(";")
        if token.strip()
    }


def load_policy(path: Path) -> dict[str, dict[str, object]]:
    rows = read_tsv(path, []) if path.suffix == ".tsv" else []
    if path.suffix != ".tsv":
        if not path.is_file():
            return {}
        with path.open(newline="", encoding="utf-8") as handle:
            rows = list(csv.DictReader(handle))
    policy: dict[str, dict[str, object]] = {}
    for row in rows:
        family = row.get("family", "").strip()
        disposition = row.get("disposition", "").strip().upper()
        if not family:
            continue
        if disposition not in ALLOWED_UNKNOWN_DISPOSITIONS:
            raise ValueError(f"invalid disposition for {family}: {disposition}")
        policy[family.upper()] = {
            "disposition": disposition,
            "allowed_directions": policy_values(row.get("allowed_directions", "")),
            "allowed_layers": policy_values(row.get("allowed_layers", "")),
            "allowed_purposes": policy_values(row.get("allowed_purposes", "")),
        }
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
    if out.exists():
        if not out.is_dir() or any(out.iterdir()):
            print(f"ERROR=immutable processor output already populated: {out}")
            return 2
    else:
        out.mkdir(parents=True)
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
        ordinary_signal_layers = {
            layer.upper()
            for layer in contract["physical_policy"]["ordinary_signal_layers"]
        }
        observed_indices: dict[str, set[int]] = {name: set() for name in expected_families}
        observed_unindexed: Counter[str] = Counter()
        observed_directions: dict[str, set[str]] = {name: set() for name in expected_families}
        observed_layers: dict[str, set[str]] = {name: set() for name in expected_families}
        observed_purposes: dict[str, set[str]] = {name: set() for name in expected_families}
        unknown_names: set[str] = set()
        unknown_term_rows: dict[str, list[dict[str, str]]] = {}
        for row in matrix_terms:
            family, indices = canonical_family(row["terminal"])
            if family is None:
                unknown_name = row["terminal"].strip()
                unknown_names.add(unknown_name)
                unknown_term_rows.setdefault(unknown_name, []).append(row)
                continue
            if indices:
                observed_indices[family].update(indices)
            else:
                observed_unindexed[family] += 1
            observed_directions[family].add(row["direction"].strip().upper())
            observed_layers[family].add(row["layer"].strip().upper())
            observed_purposes[family].add(row["purpose"].strip().upper())

        family_rows: list[dict[str, object]] = []
        parity_gate = True
        for family, expected in expected_families.items():
            expected_set = set(range(int(expected["width"])))
            actual_set = observed_indices[family]
            if not actual_set and observed_unindexed[family] == int(expected["width"]):
                actual_set = expected_set
            index_status = "PASS" if actual_set == expected_set else "FAIL"
            direction_status, direction_evidence = direction_policy(
                observed_directions[family],
                str(expected["direction"]),
            )
            physical_pin_status = (
                "PASS"
                if observed_layers[family]
                and observed_layers[family].issubset(ordinary_signal_layers)
                and observed_purposes[family] == {"PIN"}
                else "FAIL"
            )
            parity_gate &= (
                index_status == "PASS"
                and direction_status == "PASS"
                and physical_pin_status == "PASS"
            )
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
                    "direction_evidence": direction_evidence,
                    "observed_layers": ",".join(sorted(observed_layers[family])) or "ABSENT",
                    "observed_purposes": ",".join(sorted(observed_purposes[family])) or "ABSENT",
                    "physical_pin_status": physical_pin_status,
                }
            )
        write_tsv(
            out / "matrice5_terminal_family_contract.tsv",
            [
                "family", "expected_width", "observed_index_count",
                "unindexed_terminal_count", "expected_direction",
                "observed_directions", "index_status", "direction_status",
                "direction_evidence", "observed_layers",
                "observed_purposes", "physical_pin_status",
            ],
            family_rows,
        )

        policy = load_policy(args.unknown_family_policy)
        unknown_rows = []
        unknown_gate = True
        for name in sorted(unknown_names):
            family = "SUPPLY" if SUPPLY_RE.match(name) else name.split("<", 1)[0].split("[", 1)[0]
            evidence_rows = unknown_term_rows[name]
            observed_unknown_layers = {
                row["layer"].strip().upper() for row in evidence_rows
            }
            observed_unknown_purposes = {
                row["purpose"].strip().upper() for row in evidence_rows
            }
            observed_unknown_directions = {
                row["direction"].strip().upper() for row in evidence_rows
            }
            policy_entry = policy.get(family.upper())
            disposition = (
                str(policy_entry["disposition"])
                if policy_entry
                else "UNCLASSIFIED"
            )
            allowed_layers = (
                policy_entry["allowed_layers"] if policy_entry else set()
            )
            allowed_purposes = (
                policy_entry["allowed_purposes"] if policy_entry else set()
            )
            allowed_directions = (
                policy_entry["allowed_directions"] if policy_entry else set()
            )
            physical_evidence_gate = bool(
                policy_entry
                and allowed_directions
                and allowed_layers
                and allowed_purposes
            )
            physical_evidence_gate &= observed_unknown_directions.issubset(
                allowed_directions
            )
            physical_evidence_gate &= observed_unknown_layers.issubset(
                allowed_layers
            )
            physical_evidence_gate &= observed_unknown_purposes.issubset(
                allowed_purposes
            )
            accepted = (
                disposition in {"ALLOW_P03", "IGNORE_NON_DIGITAL"}
                and physical_evidence_gate
            )
            if not accepted:
                unknown_gate = False
            unknown_rows.append(
                {
                    "terminal": name,
                    "family": family,
                    "directions": ",".join(sorted(observed_unknown_directions)),
                    "layers": ",".join(sorted(observed_unknown_layers)),
                    "purposes": ",".join(sorted(observed_unknown_purposes)),
                    "disposition": disposition,
                    "policy_evidence_status": (
                        "PASS" if physical_evidence_gate else "FAIL"
                    ),
                    "p03_status": "PASS" if accepted else "BLOCK",
                }
            )
        write_tsv(
            out / "matrice5_unknown_families.tsv",
            [
                "terminal", "family", "directions", "layers", "purposes",
                "disposition", "policy_evidence_status", "p03_status",
            ],
            unknown_rows,
        )

        die = rect_from_bbox(
            by_role.get("spadmic2", {}).get("bbox", ""),
            "SPADMIC2",
        )
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
        proxy_rows: list[dict[str, object]] = []
        proxy_indices: dict[str, set[int]] = {name: set() for name in expected_families}
        proxy_coordinate_source = "NONE"
        proxy_transform_status = "NOT_RUN"
        proxy_translation = "UNKNOWN"
        for row in instance_pins:
            if row["instance"] != matrix_name:
                continue
            family, indices = canonical_family(row["terminal"])
            if family in expected_families:
                try:
                    pin_rect = rect_from_row(row)
                except ValueError:
                    continue
                if pin_rect.area <= 0.0:
                    continue
                for index in sorted(indices):
                    proxy_indices[family].add(index)
                    proxy_rows.append(
                        {
                            **row,
                            "family": family,
                            "index": index,
                            "direction": expected_families[family]["direction"],
                            "oa_direction": row["direction"],
                            "access_policy": "EXACT_AUDITED_TOP_COORDINATE",
                        }
                    )
        direct_proxy_gate = all(
            proxy_indices[family] == set(range(int(expected["width"])))
            for family, expected in expected_families.items()
        )
        if direct_proxy_gate:
            proxy_coordinate_source = "SPADMIC2_INSTANCE_PIN_EXPORT"
            proxy_transform_status = "NOT_REQUIRED"
        else:
            proxy_rows = []
            proxy_indices = {name: set() for name in expected_families}
            matrix_source = rect_from_bbox(
                by_role.get("matrice5", {}).get("bbox", ""),
                "matrice5",
            )
            translation = (
                infer_r0_translation(
                    matrix_source,
                    rect_from_row(matrix_instance),
                    matrix_instance["orient"],
                )
                if matrix_instance
                else None
            )
            if translation is not None:
                dx, dy = translation
                proxy_coordinate_source = "MATRICE5_TOP_TERMINALS_PLUS_R0_BBOX_TRANSLATION"
                proxy_transform_status = "PASS"
                proxy_translation = f"{dx:.6f} {dy:.6f}"
                for row in matrix_terms:
                    family, indices = canonical_family(row["terminal"])
                    if family not in expected_families:
                        continue
                    try:
                        pin_rect = rect_from_row(row)
                    except ValueError:
                        continue
                    transformed = pin_rect.translate(dx, dy)
                    if transformed.area <= 0.0:
                        continue
                    for index in sorted(indices):
                        proxy_indices[family].add(index)
                        proxy_rows.append(
                            {
                                "instance": matrix_name,
                                "terminal": row["terminal"],
                                "family": family,
                                "index": index,
                                "direction": expected_families[family]["direction"],
                                "oa_direction": row["direction"],
                                "net": row["net"],
                                "layer": row["layer"],
                                "purpose": row["purpose"],
                                "llx": f"{transformed.llx:.6f}",
                                "lly": f"{transformed.lly:.6f}",
                                "urx": f"{transformed.urx:.6f}",
                                "ury": f"{transformed.ury:.6f}",
                                "access_policy": (
                                    "MATRIX_SOURCE_PIN_PLUS_EXACT_R0_BBOX_TRANSLATION"
                                ),
                            }
                        )
            else:
                proxy_coordinate_source = "UNAVAILABLE"
                proxy_transform_status = "FAIL"
        write_tsv(
            out / "matrice5_proxy_pin_access.tsv",
            [
                "instance", "terminal", "family", "index", "direction",
                "oa_direction", "net", "layer", "purpose", "llx", "lly",
                "urx", "ury", "access_policy",
            ],
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
            and is_conductive_shape(row)
            and rect_from_row(row).area > 0.0
        ]
        mettp_rows: list[dict[str, object]] = []
        unattributed_mettp: list[tuple[int, dict[str, str], Rect]] = []
        for row in top_shapes:
            if (
                row["layer"].strip().upper() != "METTP"
                or not is_conductive_shape(row)
            ):
                continue
            try:
                shape_rect = rect_from_row(row)
            except ValueError:
                continue
            if shape_rect.area <= 0.0:
                continue
            anchor_index = len(mettp_rows) + 1
            net = row["net"].strip()
            attributed = net.upper() in {"VDD", "VSS"}
            mettp_rows.append(
                {
                    "anchor_index": anchor_index,
                    **row,
                    "attribution_status": (
                        "PASS_EXACT_VDD_VSS_NET"
                        if attributed
                        else "FAIL_UNATTRIBUTED_TO_DIGITAL_PG"
                    ),
                }
            )
            if not attributed:
                unattributed_mettp.append((anchor_index, row, shape_rect))
        write_tsv(
            out / "mettp_top_shape_attribution.tsv",
            [
                "anchor_index", "shape_type", "net", "layer", "purpose",
                "llx", "lly", "urx", "ury", "attribution_status",
            ],
            mettp_rows,
        )

        overlap_candidates: list[dict[str, object]] = []
        for anchor_index, anchor_row, anchor_rect in unattributed_mettp:
            for candidate in top_shapes:
                candidate_net = candidate["net"].strip()
                if (
                    not is_conductive_shape(candidate)
                    or not candidate_net
                    or candidate_net.upper() == "ABSENT"
                ):
                    continue
                try:
                    candidate_rect = rect_from_row(candidate)
                except ValueError:
                    continue
                overlap = anchor_rect.intersect(candidate_rect)
                if overlap is None:
                    continue
                overlap_candidates.append(
                    {
                        "anchor_index": anchor_index,
                        "mettp_llx": anchor_row["llx"],
                        "mettp_lly": anchor_row["lly"],
                        "mettp_urx": anchor_row["urx"],
                        "mettp_ury": anchor_row["ury"],
                        "candidate_net": candidate_net,
                        "candidate_layer": candidate["layer"],
                        "candidate_purpose": candidate["purpose"],
                        "candidate_llx": candidate["llx"],
                        "candidate_lly": candidate["lly"],
                        "candidate_urx": candidate["urx"],
                        "candidate_ury": candidate["ury"],
                        "overlap_llx": f"{overlap.llx:.6f}",
                        "overlap_lly": f"{overlap.lly:.6f}",
                        "overlap_urx": f"{overlap.urx:.6f}",
                        "overlap_ury": f"{overlap.ury:.6f}",
                        "overlap_area_um2": f"{overlap.area:.6f}",
                        "authorization": "REVIEW_ONLY_NOT_A_PG_ANCHOR",
                    }
                )
        write_tsv(
            out / "mettp_overlap_candidates.tsv",
            [
                "anchor_index", "mettp_llx", "mettp_lly", "mettp_urx",
                "mettp_ury", "candidate_net", "candidate_layer",
                "candidate_purpose", "candidate_llx", "candidate_lly",
                "candidate_urx", "candidate_ury", "overlap_llx",
                "overlap_lly", "overlap_urx", "overlap_ury",
                "overlap_area_um2", "authorization",
            ],
            overlap_candidates,
        )

        context_rows: list[dict[str, object]] = []
        context_summary_rows: list[dict[str, object]] = []
        netted_area_overlap_count = 0
        netted_boundary_contact_count = 0
        same_layer_exact_pg_contact_count = 0
        same_layer_supply_like_contact_count = 0
        for anchor_index, anchor_row, anchor_rect in unattributed_mettp:
            candidates: list[dict[str, object]] = []
            anchor_layer = anchor_row["layer"].strip().upper()
            for candidate in top_shapes:
                candidate_net = candidate["net"].strip()
                if (
                    candidate is anchor_row
                    or not is_conductive_shape(candidate)
                    or not candidate_net
                    or candidate_net.upper() == "ABSENT"
                ):
                    continue
                try:
                    candidate_rect = rect_from_row(candidate)
                except ValueError:
                    continue
                if candidate_rect.area <= 0.0:
                    continue
                relation, gap_x, gap_y, distance = rect_relation(
                    anchor_rect,
                    candidate_rect,
                )
                candidate_layer = candidate["layer"].strip().upper()
                candidate_class = net_classification(candidate_net)
                candidates.append(
                    {
                        "anchor_index": anchor_index,
                        "anchor_shape_type": anchor_row["shape_type"],
                        "anchor_net": anchor_row["net"],
                        "anchor_layer": anchor_row["layer"],
                        "anchor_purpose": anchor_row["purpose"],
                        "anchor_llx": anchor_row["llx"],
                        "anchor_lly": anchor_row["lly"],
                        "anchor_urx": anchor_row["urx"],
                        "anchor_ury": anchor_row["ury"],
                        "candidate_shape_type": candidate["shape_type"],
                        "candidate_net": candidate_net,
                        "candidate_net_class": candidate_class,
                        "candidate_layer": candidate["layer"],
                        "candidate_purpose": candidate["purpose"],
                        "candidate_llx": candidate["llx"],
                        "candidate_lly": candidate["lly"],
                        "candidate_urx": candidate["urx"],
                        "candidate_ury": candidate["ury"],
                        "layer_relation": (
                            "SAME_LAYER"
                            if candidate_layer == anchor_layer
                            else "CROSS_LAYER"
                        ),
                        "geometry_relation": relation,
                        "x_gap_um": f"{gap_x:.6f}",
                        "y_gap_um": f"{gap_y:.6f}",
                        "bbox_distance_um": f"{distance:.6f}",
                        "authorization": "REVIEW_ONLY_NOT_A_PG_ANCHOR",
                    }
                )
            candidates.sort(key=shape_context_sort_key)
            same_layer = [
                row for row in candidates if row["layer_relation"] == "SAME_LAYER"
            ]
            supply_like = [
                row
                for row in candidates
                if row["candidate_net_class"]
                in {"EXACT_DIGITAL_PG", "SUPPLY_LIKE_REVIEW"}
            ]
            for scope, scoped_rows in (
                ("ALL_NETTED_NEAREST", candidates),
                ("SAME_LAYER_NETTED_NEAREST", same_layer),
                ("SUPPLY_LIKE_NETTED_NEAREST", supply_like),
            ):
                for rank, candidate in enumerate(
                    scoped_rows[:METTP_CONTEXT_CANDIDATE_LIMIT],
                    start=1,
                ):
                    context_rows.append(
                        {
                            **candidate,
                            "selection_scope": scope,
                            "candidate_rank": rank,
                        }
                    )

            area_overlaps = [
                row
                for row in candidates
                if row["geometry_relation"] == "AREA_OVERLAP"
            ]
            boundary_contacts = [
                row
                for row in candidates
                if row["geometry_relation"] in {"BOUNDARY_TOUCH", "CORNER_TOUCH"}
            ]
            exact_pg_contacts = [
                row
                for row in candidates
                if row["layer_relation"] == "SAME_LAYER"
                and row["geometry_relation"] in CONTACT_RELATIONS
                and row["candidate_net_class"] == "EXACT_DIGITAL_PG"
            ]
            supply_like_contacts = [
                row
                for row in candidates
                if row["layer_relation"] == "SAME_LAYER"
                and row["geometry_relation"] in CONTACT_RELATIONS
                and row["candidate_net_class"]
                in {"EXACT_DIGITAL_PG", "SUPPLY_LIKE_REVIEW"}
            ]
            netted_area_overlap_count += len(area_overlaps)
            netted_boundary_contact_count += len(boundary_contacts)
            same_layer_exact_pg_contact_count += len(exact_pg_contacts)
            same_layer_supply_like_contact_count += len(supply_like_contacts)
            orientation = (
                "HORIZONTAL"
                if anchor_rect.width > anchor_rect.height
                else "VERTICAL"
                if anchor_rect.height > anchor_rect.width
                else "SQUARE"
            )
            context_summary_rows.append(
                {
                    "anchor_index": anchor_index,
                    "shape_type": anchor_row["shape_type"],
                    "net": anchor_row["net"],
                    "layer": anchor_row["layer"],
                    "purpose": anchor_row["purpose"],
                    "llx": anchor_row["llx"],
                    "lly": anchor_row["lly"],
                    "urx": anchor_row["urx"],
                    "ury": anchor_row["ury"],
                    "orientation": orientation,
                    "minor_width_um": f"{min(anchor_rect.width, anchor_rect.height):.6f}",
                    "major_length_um": f"{max(anchor_rect.width, anchor_rect.height):.6f}",
                    "netted_area_overlap_count": len(area_overlaps),
                    "netted_boundary_contact_count": len(boundary_contacts),
                    "same_layer_exact_pg_contact_count": len(exact_pg_contacts),
                    "same_layer_supply_like_contact_count": len(supply_like_contacts),
                    "nearest_netted_distance_um": nearest_context_value(
                        candidates,
                        "bbox_distance_um",
                    ),
                    "nearest_netted_net": nearest_context_value(
                        candidates,
                        "candidate_net",
                    ),
                    "nearest_netted_layer": nearest_context_value(
                        candidates,
                        "candidate_layer",
                    ),
                    "nearest_same_layer_distance_um": nearest_context_value(
                        same_layer,
                        "bbox_distance_um",
                    ),
                    "nearest_same_layer_net": nearest_context_value(
                        same_layer,
                        "candidate_net",
                    ),
                    "nearest_supply_like_distance_um": nearest_context_value(
                        supply_like,
                        "bbox_distance_um",
                    ),
                    "nearest_supply_like_net": nearest_context_value(
                        supply_like,
                        "candidate_net",
                    ),
                    "context_status": "REVIEW_ONLY_NOT_A_PG_ANCHOR",
                }
            )
        write_tsv(
            out / "mettp_anchor_context_summary.tsv",
            [
                "anchor_index", "shape_type", "net", "layer", "purpose",
                "llx", "lly", "urx", "ury", "orientation",
                "minor_width_um", "major_length_um",
                "netted_area_overlap_count", "netted_boundary_contact_count",
                "same_layer_exact_pg_contact_count",
                "same_layer_supply_like_contact_count",
                "nearest_netted_distance_um", "nearest_netted_net",
                "nearest_netted_layer", "nearest_same_layer_distance_um",
                "nearest_same_layer_net", "nearest_supply_like_distance_um",
                "nearest_supply_like_net", "context_status",
            ],
            context_summary_rows,
        )
        write_tsv(
            out / "mettp_netted_shape_context.tsv",
            [
                "anchor_index", "selection_scope", "candidate_rank",
                "anchor_shape_type", "anchor_net", "anchor_layer",
                "anchor_purpose", "anchor_llx", "anchor_lly", "anchor_urx",
                "anchor_ury", "candidate_shape_type", "candidate_net",
                "candidate_net_class", "candidate_layer",
                "candidate_purpose", "candidate_llx", "candidate_lly",
                "candidate_urx", "candidate_ury", "layer_relation",
                "geometry_relation", "x_gap_um", "y_gap_um",
                "bbox_distance_um", "authorization",
            ],
            context_rows,
        )

        pg_gate = (
            {row["net"].upper() for row in mettp_pg_rows} == {"VDD", "VSS"}
            and not unattributed_mettp
        )
        p00_p02_gate = source_gate and exact_matrix_gate and pg_gate
        p03_interface_gate = parity_gate and unknown_gate and proxy_gate
        p03_gate = p00_p02_gate and p03_interface_gate
        if not p00_p02_gate:
            next_gate = "STOP_AND_RECONCILE_PG_ANCHORS"
        elif not p03_interface_gate:
            next_gate = "RUN_P00_THROUGH_P02_THEN_RECONCILE_P03_INTERFACE"
        else:
            next_gate = "REVIEW_AUDIT_THEN_RUN_P00"
        status.update(
            {
                "STATUS": "PASS" if p00_p02_gate else "FAIL",
                "RESULT": "AUDIT_CONTRACT_ACCEPTED" if p00_p02_gate else "AUDIT_CONTRACT_REJECTED",
                "AUDIT_SCOPE": "P00_P02_ENTRY_GATE_WITH_P03_PRECLASSIFICATION",
                "CONTRACT_SCHEMA": contract["schema"],
                "CONTRACT_SHA256": sha256(args.contract),
                "SOURCE_IDENTITY_GATE_STATUS": "PASS" if source_gate else "FAIL",
                "EXACT_MATRICE5_INSTANCE_GATE_STATUS": "PASS" if exact_matrix_gate else "FAIL",
                "MATRICE5_INSTANCE": matrix_name,
                "MATRICE5_INSTANCE_COUNT": len(matrix_instances),
                "MATRICE5_INSTANCE_ORIENT": (
                    matrix_instance["orient"] if matrix_instance else "ABSENT"
                ),
                "MATRIX_TERMINAL_PARITY_STATUS": "PASS" if parity_gate else "FAIL",
                "MATRIX_TERMINAL_DIRECTION_POLICY": (
                    "CONTRACT_LOGICAL_DIRECTION_OR_OA_INPUTOUTPUT"
                ),
                "UNKNOWN_FAMILY_GATE_STATUS": "PASS" if unknown_gate else "FAIL",
                "UNKNOWN_TERMINAL_COUNT": len(unknown_names),
                "UNKNOWN_FAMILY_POLICY_SHA256": sha256(args.unknown_family_policy),
                "MATRIX_PROXY_PIN_SHAPE_COUNT": len(proxy_rows),
                "MATRIX_PROXY_PIN_ACCESS_STATUS": "PASS" if proxy_gate else "FAIL",
                "MATRIX_PROXY_COORDINATE_SOURCE": proxy_coordinate_source,
                "MATRIX_PROXY_TRANSFORM_STATUS": proxy_transform_status,
                "MATRIX_PROXY_TRANSFORM_POLICY": (
                    "TRANSLATION_ONLY_FOR_R0_OR_OA_ABSENT_ORIENT_WITH_EXACT_BBOX"
                ),
                "MATRIX_PROXY_TRANSLATION_UM": proxy_translation,
                "P03_INTERFACE_CONTRACT_STATUS": (
                    "PASS" if p03_interface_gate else "FAIL"
                ),
                "PG_ANCHOR_GATE_STATUS": "PASS" if pg_gate else "FAIL",
                "VDD_ANCHOR_COUNT": sum(row["net"].upper() == "VDD" for row in pg_rows),
                "VSS_ANCHOR_COUNT": sum(row["net"].upper() == "VSS" for row in pg_rows),
                "VDD_METTP_ANCHOR_COUNT": sum(
                    row["net"].upper() == "VDD" for row in mettp_pg_rows
                ),
                "VSS_METTP_ANCHOR_COUNT": sum(
                    row["net"].upper() == "VSS" for row in mettp_pg_rows
                ),
                "METTP_TOP_SHAPE_COUNT": len(mettp_rows),
                "UNATTRIBUTED_METTP_SHAPE_COUNT": len(unattributed_mettp),
                "DIRECT_METTP_ATTRIBUTION_STATUS": (
                    "PASS" if not unattributed_mettp else "FAIL"
                ),
                "METTP_OVERLAP_CANDIDATE_COUNT": len(overlap_candidates),
                "METTP_CONTEXT_REPORT_STATUS": "PASS",
                "METTP_CONTEXT_CANDIDATE_LIMIT_PER_SCOPE": (
                    METTP_CONTEXT_CANDIDATE_LIMIT
                ),
                "METTP_NETTED_AREA_OVERLAP_CANDIDATE_COUNT": (
                    netted_area_overlap_count
                ),
                "METTP_NETTED_BOUNDARY_CONTACT_CANDIDATE_COUNT": (
                    netted_boundary_contact_count
                ),
                "METTP_SAME_LAYER_EXACT_PG_CONTACT_CANDIDATE_COUNT": (
                    same_layer_exact_pg_contact_count
                ),
                "METTP_SAME_LAYER_SUPPLY_LIKE_CONTACT_CANDIDATE_COUNT": (
                    same_layer_supply_like_contact_count
                ),
                "METTP_CONTEXT_AUTHORIZATION": (
                    "REVIEW_ONLY_NOT_A_PG_ANCHOR"
                ),
                "VERIFIED_WHITESPACE_RECT_COUNT": len(free),
                "SPADMIC2_DIE_BBOX_UM": die.format(),
                "GUIDE_SOURCE_RECT": free[0].format(),
                "P00_P02_CONTRACT_STATUS": "PASS" if p00_p02_gate else "FAIL",
                "P00_P02_IMPLEMENTATION_AUTHORIZED": "YES" if p00_p02_gate else "NO",
                "P03_IMPLEMENTATION_AUTHORIZED": "YES" if p03_gate else "NO",
                "NEXT_GATE": next_gate,
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
