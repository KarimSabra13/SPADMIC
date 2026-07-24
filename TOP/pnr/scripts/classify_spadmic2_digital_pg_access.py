#!/usr/bin/env python3
"""Classify read-only SPADMIC2 DVDD/DVSS access evidence."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


ROOT = Path(__file__).resolve().parents[3]
DEFAULT_CONTRACT = ROOT / "TOP/pnr/assembly/spadmic_digital_assembly_contract.json"
CONDUCTIVE_SHAPE_TYPES = {"PATH", "PATHSEG", "POLYGON", "RECT"}
CONTEXT_LIMIT_PER_NET = 20
INSTANCE_TERMINAL_ENUMERATION_POLICY = (
    "MASTER_TERMINALS_WITH_OPTIONAL_INSTTERM_CONNECTIVITY_AND_"
    "TRANSFORM_PROVENANCE_V2"
)
INSTANCE_TRANSFORM_POLICY = (
    "DB_TRANSFORM_OR_BBOX_VERIFIED_XY_ORIENT_UNIT_MAG_STANDARD_INSTANCE"
)
UNAVAILABLE_TRANSFORM_POLICY = "MASTER_LOCAL_ONLY_NOT_A_CANDIDATE"
ASSEMBLY_BOUNDARY_POLICY = "HOLLOW_PAD_RING_REFERENCE"
ASSEMBLY_COORDINATE_POLICY = "NORMALIZE_TO_BOUNDARY_INSTANCE_LOWER_LEFT"
ASSEMBLY_FIXED_OBSTACLE_POLICY = "ALL_OTHER_TOP_INSTANCE_BBOXES"
ASSEMBLY_PRIMARY_WHITESPACE_POLICY = (
    "LARGEST_CORE_RECT_AFTER_FIXED_BBOX_SUBTRACTION"
)
PAIR_SELECTION_POLICY = (
    "SAME_OWNER_COMPLETE_PAIR_THEN_EVIDENCE_THEN_PRIMARY_WHITESPACE_DISTANCE"
)
ELIGIBLE_INSTANCE_TRANSFORMS = {
    "DB_INSTANCE_TRANSFORM",
    "RECONSTRUCTED_XY_ORIENT_UNIT_MAG_BBOX_VERIFIED",
}


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

    def translate(self, dx: float, dy: float) -> "Rect":
        return Rect(
            self.llx + dx,
            self.lly + dy,
            self.urx + dx,
            self.ury + dy,
        )

    def inset(self, margin: float) -> "Rect":
        return Rect(
            self.llx + margin,
            self.lly + margin,
            self.urx - margin,
            self.ury - margin,
        )

    def format(self) -> str:
        return (
            f"{self.llx:.6f} {self.lly:.6f} "
            f"{self.urx:.6f} {self.ury:.6f}"
        )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--probe-root", required=True, type=Path)
    parser.add_argument("--source-audit-root", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--contract", type=Path, default=DEFAULT_CONTRACT)
    return parser.parse_args()


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read_tsv(path: Path, required: Iterable[str]) -> list[dict[str, str]]:
    if not path.is_file():
        raise ValueError(f"missing probe input: {path}")
    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        missing = sorted(set(required) - set(reader.fieldnames or []))
        if missing:
            raise ValueError(f"{path}: missing columns {missing}")
        return list(reader)


def read_status(path: Path) -> dict[str, str]:
    if not path.is_file():
        raise ValueError(f"missing probe status: {path}")
    return dict(
        line.split("=", 1)
        for line in path.read_text(encoding="utf-8").splitlines()
        if "=" in line
    )


def write_tsv(
    path: Path,
    fields: list[str],
    rows: Iterable[dict[str, object]],
) -> None:
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fields,
            delimiter="\t",
            lineterminator="\n",
        )
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fields})


def rect_from_row(row: dict[str, str]) -> Rect:
    return Rect(*(float(row[key]) for key in ("llx", "lly", "urx", "ury")))


def master_rect_from_row(row: dict[str, str]) -> Rect:
    return Rect(
        *(
            float(row[key])
            for key in ("master_llx", "master_lly", "master_urx", "master_ury")
        )
    )


def axis_gap(
    first_low: float,
    first_high: float,
    second_low: float,
    second_high: float,
) -> float:
    if first_high < second_low:
        return second_low - first_high
    if second_high < first_low:
        return first_low - second_high
    return 0.0


def rect_relation(first: Rect, second: Rect) -> tuple[str, float]:
    overlap_x = min(first.urx, second.urx) - max(first.llx, second.llx)
    overlap_y = min(first.ury, second.ury) - max(first.lly, second.lly)
    gap_x = axis_gap(first.llx, first.urx, second.llx, second.urx)
    gap_y = axis_gap(first.lly, first.ury, second.lly, second.ury)
    distance = math.hypot(gap_x, gap_y)
    if (
        first.llx >= second.llx
        and first.lly >= second.lly
        and first.urx <= second.urx
        and first.ury <= second.ury
    ):
        return "CONTAINED_IN_VERIFIED_WHITESPACE", distance
    if overlap_x > 0.0 and overlap_y > 0.0:
        return "AREA_OVERLAP", distance
    if math.isclose(gap_x, 0.0, abs_tol=1e-9) and math.isclose(
        gap_y,
        0.0,
        abs_tol=1e-9,
    ):
        if overlap_x > 0.0 or overlap_y > 0.0:
            return "BOUNDARY_TOUCH", distance
        return "CORNER_TOUCH", distance
    return "SEPARATED", distance


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


def source_instance_rect(row: dict[str, str]) -> Rect:
    return Rect(*(float(row[key]) for key in ("llx", "lly", "urx", "ury")))


def rect_output(prefix: str, rect: Rect) -> dict[str, str]:
    return {
        f"{prefix}_llx": f"{rect.llx:.6f}",
        f"{prefix}_lly": f"{rect.lly:.6f}",
        f"{prefix}_urx": f"{rect.urx:.6f}",
        f"{prefix}_ury": f"{rect.ury:.6f}",
    }


def chip_mapping_for_row(
    row: dict[str, str],
    mapping: dict[str, str],
) -> tuple[str, str, str] | None:
    names = (
        ("net", row.get("net", "")),
        ("terminal", row.get("terminal", "")),
    )
    for local_net, chip_net in mapping.items():
        for source, value in names:
            if value.strip().upper() == chip_net.upper():
                return local_net, chip_net, source.upper()
    return None


def positive_mettp(row: dict[str, str]) -> bool:
    if row.get("layer", "").strip().upper() != "METTP":
        return False
    try:
        return rect_from_row(row).area > 0.0
    except ValueError:
        return False


def instance_transform_eligible(row: dict[str, str]) -> bool:
    return row.get("transform_status", "") in ELIGIBLE_INSTANCE_TRANSFORMS


def physical_shape_status(
    row: dict[str, str],
    source_object: str,
) -> str:
    if (
        source_object == "INSTANCE_MASTER_TERMINAL_PIN"
        and not instance_transform_eligible(row)
    ):
        try:
            master_area = master_rect_from_row(row).area
        except (KeyError, ValueError):
            return "NO_PHYSICAL_FIGURE"
        if master_area <= 0.0:
            return "NONPOSITIVE_MASTER_LOCAL_AREA"
        return "MASTER_LOCAL_FIGURE_TOP_COORDINATE_UNAVAILABLE"
    try:
        area = rect_from_row(row).area
    except (KeyError, ValueError):
        return "NO_PHYSICAL_FIGURE"
    if area <= 0.0:
        return "NONPOSITIVE_AREA"
    if row.get("layer", "").strip().upper() == "METTP":
        return "POSITIVE_AREA_METTP"
    return "POSITIVE_AREA_NON_METTP"


def mettp_candidate_status(
    row: dict[str, str],
    source_object: str,
) -> str:
    if (
        source_object == "INSTANCE_MASTER_TERMINAL_PIN"
        and not instance_transform_eligible(row)
    ):
        return "REJECT_UNPROVEN_TOP_COORDINATES"
    if positive_mettp(row):
        return "REVIEW_CANDIDATE"
    return "NOT_METTP_CANDIDATE"


def connectivity_status(row: dict[str, str], chip_net: str) -> str:
    net = row.get("net", "").strip().upper()
    if net in {"", "ABSENT"}:
        return "NO_INSTTERM_CONNECTIVITY"
    if net == chip_net:
        return "CONNECTED_TO_EXACT_CHIP_NET"
    return "CONNECTED_TO_OTHER_NET"


def whitespace_context(
    rect: Rect,
    whitespace: list[dict[str, str]],
) -> tuple[str, str, str]:
    candidates: list[tuple[float, str, int]] = []
    for row in whitespace:
        try:
            relation, distance = rect_relation(rect, rect_from_row(row))
        except ValueError:
            continue
        candidates.append((distance, relation, int(row.get("rank", "0") or 0)))
    if not candidates:
        return "UNKNOWN", "UNKNOWN", "UNKNOWN"
    distance, relation, rank = min(candidates)
    return relation, f"{distance:.6f}", str(rank)


def evidence_rank(evidence_class: str) -> int:
    return {
        "DIRECT_TOP_SHAPE_EXACT_NET": 0,
        "TOP_TERMINAL_EXACT_NAME_OR_NET": 1,
        "INSTANCE_PIN_EXACT_CONNECTED_NET": 2,
        "INSTANCE_PIN_EXACT_TERMINAL_NAME": 3,
    }[evidence_class]


def main() -> int:
    args = parse_args()
    probe = args.probe_root.resolve()
    source = args.source_audit_root.resolve()
    out = args.out.resolve()
    if out.exists():
        if not out.is_dir() or any(out.iterdir()):
            print(f"ERROR=immutable PG classification output already populated: {out}")
            return 2
    else:
        out.mkdir(parents=True)

    status_path = out / "digital_pg_access_status.rpt"
    status: dict[str, object] = {
        "LABEL": "SPADMIC2_DIGITAL_PG_ACCESS_CLASSIFICATION",
        "STATUS": "FAIL",
        "RESULT": "PG_ACCESS_EVIDENCE_REJECTED",
        "PROCESSOR_SHA256": sha256(Path(__file__).resolve()),
        "SOURCE_MUTATION_AUTHORIZED": "NO",
        "OA_EDIT_AUTHORIZED": "NO",
        "GENUS_AUTHORIZED": "NO",
        "INNOVUS_AUTHORIZED": "NO",
    }

    try:
        contract = json.loads(args.contract.read_text(encoding="utf-8"))
        physical = contract["physical_policy"]
        local_nets = [str(value).upper() for value in physical["power_nets"]]
        mapping = {
            str(local).upper(): str(chip).upper()
            for local, chip in physical["digital_to_chip_power_net_map"].items()
        }
        if set(local_nets) != set(mapping):
            raise ValueError(
                "digital_to_chip_power_net_map must cover every local power net"
            )
        if len(set(mapping.values())) != len(mapping):
            raise ValueError("chip power aliases must be unique")

        export_status = read_status(probe / "virtuoso_export_status.rpt")
        if export_status.get("STATUS") != "PASS":
            raise ValueError("PG probe Virtuoso export status is not PASS")
        if (
            export_status.get("INSTANCE_TERMINAL_ENUMERATION_POLICY")
            != INSTANCE_TERMINAL_ENUMERATION_POLICY
        ):
            raise ValueError(
                "PG probe does not prove master-terminal enumeration independent "
                "of instTerm connectivity with explicit transform provenance"
            )
        if (
            export_status.get("INSTANCE_TRANSFORM_POLICY")
            != INSTANCE_TRANSFORM_POLICY
        ):
            raise ValueError(
                "PG probe instance transform policy is missing or unsupported"
            )
        if (
            export_status.get("UNAVAILABLE_TRANSFORM_POLICY")
            != UNAVAILABLE_TRANSFORM_POLICY
        ):
            raise ValueError(
                "PG probe unavailable-transform policy is missing or unsupported"
            )

        source_identity = read_tsv(
            probe / "source_identity.tsv",
            [
                "role",
                "library",
                "cell",
                "view",
                "filesystem_path",
                "open_status",
                "bbox",
            ],
        )
        expected_source = contract["source_layouts"]["spadmic2"]
        expected_identity = {
            "role": "spadmic2",
            "library": expected_source["library"],
            "cell": expected_source["cell"],
            "view": expected_source["view"],
            "filesystem_path": expected_source["filesystem_path"],
            "open_status": "PASS",
        }
        if len(source_identity) != 1 or any(
            source_identity[0].get(key) != value
            for key, value in expected_identity.items()
        ):
            raise ValueError("SPADMIC2 probe source identity does not match contract")

        floorplan = contract["assembly_floorplan"]
        if floorplan.get("boundary_policy") != ASSEMBLY_BOUNDARY_POLICY:
            raise ValueError("unsupported assembly boundary policy")
        if floorplan.get("coordinate_policy") != ASSEMBLY_COORDINATE_POLICY:
            raise ValueError("unsupported assembly coordinate policy")
        if (
            floorplan.get("fixed_obstacle_policy")
            != ASSEMBLY_FIXED_OBSTACLE_POLICY
        ):
            raise ValueError("unsupported assembly fixed-obstacle policy")
        if (
            floorplan.get("primary_whitespace_policy")
            != ASSEMBLY_PRIMARY_WHITESPACE_POLICY
        ):
            raise ValueError("unsupported assembly primary-whitespace policy")

        source_instances_path = (
            source / "raw_oa_export/spadmic2_instances.tsv"
        )
        source_instances = read_tsv(
            source_instances_path,
            [
                "instance",
                "master_library",
                "master_cell",
                "master_view",
                "orient",
                "llx",
                "lly",
                "urx",
                "ury",
            ],
        )
        boundary_spec = floorplan["boundary_instance"]
        boundary_matches = [
            row
            for row in source_instances
            if all(
                row.get(field) == str(boundary_spec[field])
                for field in (
                    "instance",
                    "master_library",
                    "master_cell",
                    "master_view",
                    "orient",
                )
            )
        ]
        if len(boundary_matches) != 1:
            raise ValueError(
                "assembly boundary instance contract must match exactly one "
                "source instance"
            )
        boundary_row = boundary_matches[0]
        boundary_source = source_instance_rect(boundary_row)
        if boundary_source.area <= 0.0:
            raise ValueError("assembly boundary instance has nonpositive bbox")

        source_bbox_values = source_identity[0]["bbox"].split()
        if len(source_bbox_values) != 4:
            raise ValueError("SPADMIC2 source identity bbox is malformed")
        source_cellview_bbox = Rect(*(float(value) for value in source_bbox_values))
        if (
            boundary_source.llx < source_cellview_bbox.llx
            or boundary_source.lly < source_cellview_bbox.lly
            or boundary_source.urx > source_cellview_bbox.urx
            or boundary_source.ury > source_cellview_bbox.ury
        ):
            raise ValueError(
                "assembly boundary instance is outside the source cellview bbox"
            )

        keepout_um = float(floorplan["core_keepout_um"])
        if keepout_um <= 0.0:
            raise ValueError("assembly core keepout must be positive")
        core_source = boundary_source.inset(keepout_um)
        if core_source.area <= 0.0:
            raise ValueError("assembly core bbox is empty after pad-ring keepout")

        source_to_assembly_dx = -boundary_source.llx
        source_to_assembly_dy = -boundary_source.lly
        boundary_assembly = boundary_source.translate(
            source_to_assembly_dx,
            source_to_assembly_dy,
        )
        core_assembly = core_source.translate(
            source_to_assembly_dx,
            source_to_assembly_dy,
        )

        obstacle_rows: list[dict[str, object]] = []
        obstacle_rects: list[Rect] = []
        for row in source_instances:
            if row is boundary_row:
                continue
            source_rect = source_instance_rect(row)
            if source_rect.area <= 0.0:
                raise ValueError(
                    f"source instance {row['instance']} has nonpositive bbox"
                )
            core_overlap = source_rect.intersect(core_source)
            if core_overlap is not None:
                obstacle_rects.append(source_rect)
            assembly_rect = source_rect.translate(
                source_to_assembly_dx,
                source_to_assembly_dy,
            )
            obstacle_rows.append(
                {
                    "instance": row["instance"],
                    "master_library": row["master_library"],
                    "master_cell": row["master_cell"],
                    "master_view": row["master_view"],
                    "orient": row["orient"],
                    **rect_output("source", source_rect),
                    **rect_output("assembly", assembly_rect),
                    "core_overlap_status": (
                        "OVERLAPS_CORE" if core_overlap is not None else "OUTSIDE_CORE"
                    ),
                    "obstacle_policy": ASSEMBLY_FIXED_OBSTACLE_POLICY,
                }
            )

        free_source = free_rectangles(core_source, obstacle_rects)
        if not free_source:
            raise ValueError("no verified interior whitespace remains")
        whitespace_rows: list[dict[str, object]] = []
        whitespace_context_rows: list[dict[str, str]] = []
        for rank, source_rect in enumerate(free_source, start=1):
            assembly_rect = source_rect.translate(
                source_to_assembly_dx,
                source_to_assembly_dy,
            )
            whitespace_rows.append(
                {
                    "rank": rank,
                    **rect_output("source", source_rect),
                    **rect_output("assembly", assembly_rect),
                    "area_um2": f"{source_rect.area:.6f}",
                    "status": "VERIFIED_INTERIOR_EMPTY",
                }
            )
            whitespace_context_rows.append(
                {
                    "rank": str(rank),
                    "llx": f"{source_rect.llx:.6f}",
                    "lly": f"{source_rect.lly:.6f}",
                    "urx": f"{source_rect.urx:.6f}",
                    "ury": f"{source_rect.ury:.6f}",
                    "status": "VERIFIED_INTERIOR_EMPTY",
                }
            )
        primary_whitespace_source = free_source[0]
        primary_whitespace_assembly = primary_whitespace_source.translate(
            source_to_assembly_dx,
            source_to_assembly_dy,
        )

        write_tsv(
            out / "assembly_floorplan_boundary.tsv",
            [
                "instance",
                "master_library",
                "master_cell",
                "master_view",
                "orient",
                "boundary_policy",
                "coordinate_policy",
                "core_keepout_um",
                "source_llx",
                "source_lly",
                "source_urx",
                "source_ury",
                "assembly_llx",
                "assembly_lly",
                "assembly_urx",
                "assembly_ury",
                "core_source_llx",
                "core_source_lly",
                "core_source_urx",
                "core_source_ury",
                "core_assembly_llx",
                "core_assembly_lly",
                "core_assembly_urx",
                "core_assembly_ury",
                "source_to_assembly_dx",
                "source_to_assembly_dy",
            ],
            [
                {
                    "instance": boundary_row["instance"],
                    "master_library": boundary_row["master_library"],
                    "master_cell": boundary_row["master_cell"],
                    "master_view": boundary_row["master_view"],
                    "orient": boundary_row["orient"],
                    "boundary_policy": ASSEMBLY_BOUNDARY_POLICY,
                    "coordinate_policy": ASSEMBLY_COORDINATE_POLICY,
                    "core_keepout_um": f"{keepout_um:.6f}",
                    **rect_output("source", boundary_source),
                    **rect_output("assembly", boundary_assembly),
                    **rect_output("core_source", core_source),
                    **rect_output("core_assembly", core_assembly),
                    "source_to_assembly_dx": f"{source_to_assembly_dx:.6f}",
                    "source_to_assembly_dy": f"{source_to_assembly_dy:.6f}",
                }
            ],
        )
        write_tsv(
            out / "assembly_fixed_obstacles_normalized.tsv",
            [
                "instance",
                "master_library",
                "master_cell",
                "master_view",
                "orient",
                "source_llx",
                "source_lly",
                "source_urx",
                "source_ury",
                "assembly_llx",
                "assembly_lly",
                "assembly_urx",
                "assembly_ury",
                "core_overlap_status",
                "obstacle_policy",
            ],
            obstacle_rows,
        )
        write_tsv(
            out / "assembly_verified_whitespace_normalized.tsv",
            [
                "rank",
                "source_llx",
                "source_lly",
                "source_urx",
                "source_ury",
                "assembly_llx",
                "assembly_lly",
                "assembly_urx",
                "assembly_ury",
                "area_um2",
                "status",
            ],
            whitespace_rows,
        )

        top_shape_fields = [
            "shape_type",
            "net",
            "layer",
            "purpose",
            "llx",
            "lly",
            "urx",
            "ury",
        ]
        top_terminal_fields = [
            "terminal",
            "direction",
            "net",
            "layer",
            "purpose",
            "llx",
            "lly",
            "urx",
            "ury",
        ]
        instance_pin_fields = [
            "instance",
            "instance_object_type",
            "master_library",
            "master_cell",
            "master_view",
            "orient",
            "terminal",
            "direction",
            "net",
            "layer",
            "purpose",
            "transform_status",
            "coordinate_space",
            "master_llx",
            "master_lly",
            "master_urx",
            "master_ury",
            "llx",
            "lly",
            "urx",
            "ury",
        ]
        top_shapes = read_tsv(probe / "supply_top_shapes.tsv", top_shape_fields)
        top_terminals = read_tsv(
            probe / "supply_top_terminals.tsv",
            top_terminal_fields,
        )
        instance_pins = read_tsv(
            probe / "supply_instance_pins.tsv",
            instance_pin_fields,
        )
        direct_mettp = read_tsv(
            probe / "direct_mettp_shapes.tsv",
            top_shape_fields,
        )
        _legacy_whitespace = read_tsv(
            source / "processed_contract/verified_digital_whitespace.tsv",
            ["rank", "llx", "lly", "urx", "ury", "status"],
        )

        candidates: list[dict[str, object]] = []
        inventory: list[dict[str, object]] = []

        def add_candidate(
            row: dict[str, str],
            evidence_class: str,
            source_object: str,
        ) -> None:
            resolved = chip_mapping_for_row(row, mapping)
            if resolved is None or not positive_mettp(row):
                return
            if (
                source_object == "INSTANCE_TERMINAL_PIN"
                and not instance_transform_eligible(row)
            ):
                return
            local_net, chip_net, match_field = resolved
            rect = rect_from_row(row)
            relation, distance, whitespace_rank = whitespace_context(
                rect,
                whitespace_context_rows,
            )
            primary_relation, primary_distance = rect_relation(
                rect,
                primary_whitespace_source,
            )
            assembly_rect = rect.translate(
                source_to_assembly_dx,
                source_to_assembly_dy,
            )
            candidates.append(
                {
                    "local_net": local_net,
                    "chip_net": chip_net,
                    "source_object": source_object,
                    "evidence_class": evidence_class,
                    "match_field": match_field,
                    "instance": row.get("instance", "TOP"),
                    "instance_object_type": row.get(
                        "instance_object_type",
                        "TOP",
                    ),
                    "master_library": row.get("master_library", ""),
                    "master_cell": row.get("master_cell", ""),
                    "master_view": row.get("master_view", ""),
                    "orient": row.get("orient", ""),
                    "terminal": row.get("terminal", ""),
                    "connected_net": row.get("net", ""),
                    "transform_status": row.get(
                        "transform_status",
                        "TOP_LEVEL_NOT_APPLICABLE",
                    ),
                    "coordinate_space": row.get(
                        "coordinate_space",
                        "TOP_CELLVIEW",
                    ),
                    "master_llx": row.get("master_llx", "NOT_APPLICABLE"),
                    "master_lly": row.get("master_lly", "NOT_APPLICABLE"),
                    "master_urx": row.get("master_urx", "NOT_APPLICABLE"),
                    "master_ury": row.get("master_ury", "NOT_APPLICABLE"),
                    "shape_type": row.get("shape_type", ""),
                    "layer": row["layer"],
                    "purpose": row["purpose"],
                    "llx": row["llx"],
                    "lly": row["lly"],
                    "urx": row["urx"],
                    "ury": row["ury"],
                    **rect_output("assembly", assembly_rect),
                    "whitespace_rank": whitespace_rank,
                    "whitespace_relation": relation,
                    "whitespace_distance_um": distance,
                    "primary_whitespace_relation": primary_relation,
                    "primary_whitespace_distance_um": (
                        f"{primary_distance:.6f}"
                    ),
                    "authorization": "REVIEW_ONLY_NOT_AN_ASSEMBLY_ANCHOR",
                }
            )

        def add_inventory(
            row: dict[str, str],
            evidence_class: str,
            source_object: str,
        ) -> None:
            resolved = chip_mapping_for_row(row, mapping)
            if resolved is None:
                return
            local_net, chip_net, match_field = resolved
            inventory.append(
                {
                    "local_net": local_net,
                    "chip_net": chip_net,
                    "source_object": source_object,
                    "evidence_class": evidence_class,
                    "match_field": match_field,
                    "instance": row.get("instance", "TOP"),
                    "instance_object_type": row.get(
                        "instance_object_type",
                        "TOP",
                    ),
                    "master_library": row.get("master_library", ""),
                    "master_cell": row.get("master_cell", ""),
                    "master_view": row.get("master_view", ""),
                    "orient": row.get("orient", ""),
                    "terminal": row.get("terminal", ""),
                    "connected_net": row.get("net", ""),
                    "transform_status": row.get(
                        "transform_status",
                        "TOP_LEVEL_NOT_APPLICABLE",
                    ),
                    "coordinate_space": row.get(
                        "coordinate_space",
                        "TOP_CELLVIEW",
                    ),
                    "master_llx": row.get("master_llx", "NOT_APPLICABLE"),
                    "master_lly": row.get("master_lly", "NOT_APPLICABLE"),
                    "master_urx": row.get("master_urx", "NOT_APPLICABLE"),
                    "master_ury": row.get("master_ury", "NOT_APPLICABLE"),
                    "connectivity_status": (
                        connectivity_status(row, chip_net)
                        if source_object == "INSTANCE_MASTER_TERMINAL_PIN"
                        else "TOP_LEVEL"
                    ),
                    "shape_type": row.get("shape_type", "PIN_FIG"),
                    "layer": row.get("layer", ""),
                    "purpose": row.get("purpose", ""),
                    "llx": row.get("llx", ""),
                    "lly": row.get("lly", ""),
                    "urx": row.get("urx", ""),
                    "ury": row.get("ury", ""),
                    "physical_shape_status": physical_shape_status(
                        row,
                        source_object,
                    ),
                    "mettp_candidate_status": mettp_candidate_status(
                        row,
                        source_object,
                    ),
                    "authorization": "REVIEW_ONLY_NOT_AN_ASSEMBLY_ANCHOR",
                }
            )

        for row in top_shapes:
            if (
                row["shape_type"].strip().upper() in CONDUCTIVE_SHAPE_TYPES
                and row["net"].strip().upper() in set(mapping.values())
            ):
                add_inventory(
                    row,
                    "DIRECT_TOP_SHAPE_EXACT_NET",
                    "TOP_SHAPE",
                )
                add_candidate(
                    row,
                    "DIRECT_TOP_SHAPE_EXACT_NET",
                    "TOP_SHAPE",
                )

        for row in top_terminals:
            resolved = chip_mapping_for_row(row, mapping)
            if resolved is not None:
                add_inventory(
                    row,
                    "TOP_TERMINAL_EXACT_NAME_OR_NET",
                    "TOP_TERMINAL_PIN",
                )
                add_candidate(
                    row,
                    "TOP_TERMINAL_EXACT_NAME_OR_NET",
                    "TOP_TERMINAL_PIN",
                )

        for row in instance_pins:
            resolved = chip_mapping_for_row(row, mapping)
            if resolved is None:
                continue
            _, chip_net, _ = resolved
            evidence_class = (
                "INSTANCE_PIN_EXACT_CONNECTED_NET"
                if row["net"].strip().upper() == chip_net
                else "INSTANCE_PIN_EXACT_TERMINAL_NAME"
            )
            add_inventory(
                row,
                evidence_class,
                "INSTANCE_MASTER_TERMINAL_PIN",
            )
            add_candidate(row, evidence_class, "INSTANCE_TERMINAL_PIN")

        inventory_fields = [
            "local_net",
            "chip_net",
            "source_object",
            "evidence_class",
            "match_field",
            "instance",
            "instance_object_type",
            "master_library",
            "master_cell",
            "master_view",
            "orient",
            "terminal",
            "connected_net",
            "transform_status",
            "coordinate_space",
            "master_llx",
            "master_lly",
            "master_urx",
            "master_ury",
            "connectivity_status",
            "shape_type",
            "layer",
            "purpose",
            "llx",
            "lly",
            "urx",
            "ury",
            "physical_shape_status",
            "mettp_candidate_status",
            "authorization",
        ]
        inventory.sort(
            key=lambda row: (
                row["local_net"],
                str(row["source_object"]),
                str(row["instance"]),
                str(row["transform_status"]),
                str(row["layer"]),
                float(row["llx"]) if row["llx"] not in {"", "UNKNOWN"} else math.inf,
                float(row["lly"]) if row["lly"] not in {"", "UNKNOWN"} else math.inf,
            )
        )
        write_tsv(
            out / "digital_pg_access_all_layers.tsv",
            inventory_fields,
            inventory,
        )

        summary: dict[tuple[str, ...], dict[str, object]] = {}
        for row in inventory:
            key = (
                str(row["source_object"]),
                str(row["local_net"]),
                str(row["chip_net"]),
                str(row["connectivity_status"]),
                str(row["instance_object_type"]),
                str(row["transform_status"]),
                str(row["coordinate_space"]),
                str(row["layer"]),
                str(row["purpose"]),
                str(row["physical_shape_status"]),
            )
            if key not in summary:
                summary[key] = {
                    "source_object": key[0],
                    "local_net": key[1],
                    "chip_net": key[2],
                    "connectivity_status": key[3],
                    "instance_object_type": key[4],
                    "transform_status": key[5],
                    "coordinate_space": key[6],
                    "layer": key[7],
                    "purpose": key[8],
                    "physical_shape_status": key[9],
                    "row_count": 0,
                    "instances": set(),
                }
            summary[key]["row_count"] = int(summary[key]["row_count"]) + 1
            if row["instance"] not in {"", "TOP"}:
                instances = summary[key]["instances"]
                assert isinstance(instances, set)
                instances.add(str(row["instance"]))
        summary_rows: list[dict[str, object]] = []
        for key in sorted(summary):
            row = summary[key]
            instances = row.pop("instances")
            assert isinstance(instances, set)
            row["unique_instance_count"] = len(instances)
            summary_rows.append(row)
        write_tsv(
            out / "digital_pg_access_layer_summary.tsv",
            [
                "source_object",
                "local_net",
                "chip_net",
                "connectivity_status",
                "instance_object_type",
                "transform_status",
                "coordinate_space",
                "layer",
                "purpose",
                "physical_shape_status",
                "row_count",
                "unique_instance_count",
            ],
            summary_rows,
        )

        candidate_fields = [
            "local_net",
            "chip_net",
            "source_object",
            "evidence_class",
            "match_field",
            "instance",
            "instance_object_type",
            "master_library",
            "master_cell",
            "master_view",
            "orient",
            "terminal",
            "connected_net",
            "transform_status",
            "coordinate_space",
            "master_llx",
            "master_lly",
            "master_urx",
            "master_ury",
            "shape_type",
            "layer",
            "purpose",
            "llx",
            "lly",
            "urx",
            "ury",
            "assembly_llx",
            "assembly_lly",
            "assembly_urx",
            "assembly_ury",
            "whitespace_rank",
            "whitespace_relation",
            "whitespace_distance_um",
            "primary_whitespace_relation",
            "primary_whitespace_distance_um",
            "authorization",
        ]
        candidates.sort(
            key=lambda row: (
                row["local_net"],
                evidence_rank(str(row["evidence_class"])),
                float(row["primary_whitespace_distance_um"]),
                float(row["whitespace_distance_um"]),
                str(row["instance"]),
                float(row["llx"]),
                float(row["lly"]),
            )
        )
        write_tsv(
            out / "digital_pg_access_candidates.tsv",
            candidate_fields,
            candidates,
        )

        def owner_key(row: dict[str, object]) -> tuple[str, str, str, str, str]:
            if row["source_object"] in {"TOP_SHAPE", "TOP_TERMINAL_PIN"}:
                return ("TOP", "TOP", "", "", "")
            return (
                "INSTANCE",
                str(row["instance"]),
                str(row["master_library"]),
                str(row["master_cell"]),
                str(row["master_view"]),
            )

        pair_candidates: list[
            tuple[
                tuple[int, int, float, str, str],
                tuple[str, str, str, str, str],
                dict[str, dict[str, object]],
            ]
        ] = []
        owners = sorted({owner_key(row) for row in candidates})
        for owner in owners:
            selected_by_net: dict[str, dict[str, object]] = {}
            for local_net in local_nets:
                owner_net_candidates = [
                    row
                    for row in candidates
                    if owner_key(row) == owner and row["local_net"] == local_net
                ]
                if not owner_net_candidates:
                    break
                owner_net_candidates.sort(
                    key=lambda row: (
                        evidence_rank(str(row["evidence_class"])),
                        float(row["primary_whitespace_distance_um"]),
                        float(row["whitespace_distance_um"]),
                        float(row["llx"]),
                        float(row["lly"]),
                    )
                )
                selected_by_net[local_net] = owner_net_candidates[0]
            if len(selected_by_net) != len(local_nets):
                continue
            evidence_ranks = [
                evidence_rank(str(selected_by_net[net]["evidence_class"]))
                for net in local_nets
            ]
            primary_distance_sum = sum(
                float(selected_by_net[net]["primary_whitespace_distance_um"])
                for net in local_nets
            )
            pair_candidates.append(
                (
                    (
                        max(evidence_ranks),
                        sum(evidence_ranks),
                        primary_distance_sum,
                        owner[0],
                        owner[1],
                    ),
                    owner,
                    selected_by_net,
                )
            )
        pair_candidates.sort(key=lambda item: item[0])

        pair_rows: list[dict[str, object]] = []
        for pair_rank, (_, owner, selected_by_net) in enumerate(
            pair_candidates,
            start=1,
        ):
            vdd = selected_by_net["VDD"]
            vss = selected_by_net["VSS"]
            pair_distance_sum = sum(
                float(
                    selected_by_net[net][
                        "primary_whitespace_distance_um"
                    ]
                )
                for net in local_nets
            )
            pair_rows.append(
                {
                    "pair_rank": pair_rank,
                    "owner_scope": owner[0],
                    "instance": owner[1],
                    "master_library": owner[2],
                    "master_cell": owner[3],
                    "master_view": owner[4],
                    "vdd_evidence_class": vdd["evidence_class"],
                    "vdd_terminal": vdd["terminal"],
                    "vdd_source_llx": vdd["llx"],
                    "vdd_source_lly": vdd["lly"],
                    "vdd_source_urx": vdd["urx"],
                    "vdd_source_ury": vdd["ury"],
                    "vdd_assembly_llx": vdd["assembly_llx"],
                    "vdd_assembly_lly": vdd["assembly_lly"],
                    "vdd_assembly_urx": vdd["assembly_urx"],
                    "vdd_assembly_ury": vdd["assembly_ury"],
                    "vdd_primary_whitespace_distance_um": vdd[
                        "primary_whitespace_distance_um"
                    ],
                    "vss_evidence_class": vss["evidence_class"],
                    "vss_terminal": vss["terminal"],
                    "vss_source_llx": vss["llx"],
                    "vss_source_lly": vss["lly"],
                    "vss_source_urx": vss["urx"],
                    "vss_source_ury": vss["ury"],
                    "vss_assembly_llx": vss["assembly_llx"],
                    "vss_assembly_lly": vss["assembly_lly"],
                    "vss_assembly_urx": vss["assembly_urx"],
                    "vss_assembly_ury": vss["assembly_ury"],
                    "vss_primary_whitespace_distance_um": vss[
                        "primary_whitespace_distance_um"
                    ],
                    "pair_primary_whitespace_distance_sum_um": (
                        f"{pair_distance_sum:.6f}"
                    ),
                    "selection_policy": PAIR_SELECTION_POLICY,
                    "authorization": "REVIEW_ONLY_NOT_AN_ASSEMBLY_ANCHOR",
                }
            )
        write_tsv(
            out / "digital_pg_pair_ranking.tsv",
            [
                "pair_rank",
                "owner_scope",
                "instance",
                "master_library",
                "master_cell",
                "master_view",
                "vdd_evidence_class",
                "vdd_terminal",
                "vdd_source_llx",
                "vdd_source_lly",
                "vdd_source_urx",
                "vdd_source_ury",
                "vdd_assembly_llx",
                "vdd_assembly_lly",
                "vdd_assembly_urx",
                "vdd_assembly_ury",
                "vdd_primary_whitespace_distance_um",
                "vss_evidence_class",
                "vss_terminal",
                "vss_source_llx",
                "vss_source_lly",
                "vss_source_urx",
                "vss_source_ury",
                "vss_assembly_llx",
                "vss_assembly_lly",
                "vss_assembly_urx",
                "vss_assembly_ury",
                "vss_primary_whitespace_distance_um",
                "pair_primary_whitespace_distance_sum_um",
                "selection_policy",
                "authorization",
            ],
            pair_rows,
        )

        recommendations: list[dict[str, object]] = []
        selected_pair_owner: tuple[str, str, str, str, str] | None = None
        if pair_candidates:
            _, selected_pair_owner, selected_by_net = pair_candidates[0]
            for local_net in local_nets:
                recommendations.append(
                    {
                        **selected_by_net[local_net],
                        "selection_basis": PAIR_SELECTION_POLICY,
                    }
                )
        write_tsv(
            out / "digital_pg_review_pair.tsv",
            candidate_fields + ["selection_basis"],
            recommendations,
        )

        context_rows: list[dict[str, object]] = []
        for anchor_index, anchor in enumerate(direct_mettp, start=1):
            if not positive_mettp(anchor):
                continue
            anchor_rect = rect_from_row(anchor)
            for local_net in local_nets:
                ranked: list[tuple[float, dict[str, object], str]] = []
                for candidate in candidates:
                    if candidate["local_net"] != local_net:
                        continue
                    candidate_rect = Rect(
                        *(
                            float(candidate[key])
                            for key in ("llx", "lly", "urx", "ury")
                        )
                    )
                    relation, distance = rect_relation(
                        anchor_rect,
                        candidate_rect,
                    )
                    ranked.append((distance, candidate, relation))
                ranked.sort(
                    key=lambda item: (
                        item[0],
                        evidence_rank(str(item[1]["evidence_class"])),
                        str(item[1]["instance"]),
                    )
                )
                for rank, (distance, candidate, relation) in enumerate(
                    ranked[:CONTEXT_LIMIT_PER_NET],
                    start=1,
                ):
                    context_rows.append(
                        {
                            "anchor_index": anchor_index,
                            "local_net": local_net,
                            "chip_net": mapping[local_net],
                            "candidate_rank": rank,
                            "anchor_net": anchor["net"],
                            "anchor_llx": anchor["llx"],
                            "anchor_lly": anchor["lly"],
                            "anchor_urx": anchor["urx"],
                            "anchor_ury": anchor["ury"],
                            "candidate_instance": candidate["instance"],
                            "candidate_instance_object_type": candidate[
                                "instance_object_type"
                            ],
                            "candidate_master_cell": candidate["master_cell"],
                            "candidate_terminal": candidate["terminal"],
                            "candidate_connected_net": candidate["connected_net"],
                            "candidate_transform_status": candidate[
                                "transform_status"
                            ],
                            "candidate_coordinate_space": candidate[
                                "coordinate_space"
                            ],
                            "candidate_llx": candidate["llx"],
                            "candidate_lly": candidate["lly"],
                            "candidate_urx": candidate["urx"],
                            "candidate_ury": candidate["ury"],
                            "geometry_relation": relation,
                            "bbox_distance_um": f"{distance:.6f}",
                            "authorization": (
                                "REVIEW_ONLY_NOT_AN_ASSEMBLY_ANCHOR"
                            ),
                        }
                    )
        write_tsv(
            out / "mettp_to_supply_access_context.tsv",
            [
                "anchor_index",
                "local_net",
                "chip_net",
                "candidate_rank",
                "anchor_net",
                "anchor_llx",
                "anchor_lly",
                "anchor_urx",
                "anchor_ury",
                "candidate_instance",
                "candidate_instance_object_type",
                "candidate_master_cell",
                "candidate_terminal",
                "candidate_connected_net",
                "candidate_transform_status",
                "candidate_coordinate_space",
                "candidate_llx",
                "candidate_lly",
                "candidate_urx",
                "candidate_ury",
                "geometry_relation",
                "bbox_distance_um",
                "authorization",
            ],
            context_rows,
        )

        direct_counts = {
            local_net: sum(
                row["local_net"] == local_net
                and row["source_object"] in {"TOP_SHAPE", "TOP_TERMINAL_PIN"}
                for row in candidates
            )
            for local_net in local_nets
        }
        instance_counts = {
            local_net: sum(
                row["local_net"] == local_net
                and row["source_object"] == "INSTANCE_TERMINAL_PIN"
                for row in candidates
            )
            for local_net in local_nets
        }
        direct_gate = all(direct_counts[net] > 0 for net in local_nets)
        instance_gate = all(instance_counts[net] > 0 for net in local_nets)
        pair_gate = (
            selected_pair_owner is not None
            and len(recommendations) == len(local_nets)
        )
        selected_pair_scope = (
            selected_pair_owner[0] if selected_pair_owner is not None else "NONE"
        )
        selected_pair_instance = (
            selected_pair_owner[1] if selected_pair_owner is not None else "NONE"
        )
        complete_instance_pair_gate = (
            pair_gate and selected_pair_scope == "INSTANCE"
        )
        instance_inventory = [
            row
            for row in inventory
            if row["source_object"] == "INSTANCE_MASTER_TERMINAL_PIN"
        ]
        master_terminal_keys = {
            (str(row["local_net"]), str(row["instance"]), str(row["terminal"]))
            for row in instance_inventory
        }
        disconnected_master_terminal_keys = {
            (str(row["local_net"]), str(row["instance"]), str(row["terminal"]))
            for row in instance_inventory
            if row["connectivity_status"] == "NO_INSTTERM_CONNECTIVITY"
        }
        transform_eligible_master_terminal_keys = {
            (str(row["local_net"]), str(row["instance"]), str(row["terminal"]))
            for row in instance_inventory
            if str(row["transform_status"]) in ELIGIBLE_INSTANCE_TRANSFORMS
        }
        transform_unavailable_master_terminal_keys = {
            (str(row["local_net"]), str(row["instance"]), str(row["terminal"]))
            for row in instance_inventory
            if str(row["transform_status"]) not in ELIGIBLE_INSTANCE_TRANSFORMS
        }
        nonstandard_unavailable_master_terminal_keys = {
            (str(row["local_net"]), str(row["instance"]), str(row["terminal"]))
            for row in instance_inventory
            if str(row["transform_status"]) not in ELIGIBLE_INSTANCE_TRANSFORMS
            and str(row["instance_object_type"]).lower() != "inst"
        }
        if not transform_unavailable_master_terminal_keys:
            transform_coverage_status = "PASS"
        elif transform_eligible_master_terminal_keys:
            transform_coverage_status = "PARTIAL"
        else:
            transform_coverage_status = "UNAVAILABLE"
        all_layer_instance_counts = {
            local_net: sum(
                row["local_net"] == local_net
                and str(row["physical_shape_status"]).startswith("POSITIVE_AREA_")
                for row in instance_inventory
            )
            for local_net in local_nets
        }
        if direct_gate:
            next_gate = "REVIEW_DIRECT_CHIP_PG_ACCESS_AND_DEFINE_LOCAL_RAILS"
        elif complete_instance_pair_gate:
            next_gate = "RUN_READ_ONLY_SELECTED_INSTANCE_METTP_CORRIDOR_PROBE"
        elif instance_gate:
            next_gate = "STOP_AND_REQUIRE_COMPLETE_SAME_INSTANCE_PG_PAIR"
        elif all(all_layer_instance_counts[net] > 0 for net in local_nets):
            next_gate = (
                "REVIEW_NON_METTP_CHIP_PG_PINS_AND_REQUEST_ROUTABLE_ACCESS"
            )
        elif transform_unavailable_master_terminal_keys:
            next_gate = "STOP_AND_RESOLVE_UNAVAILABLE_INSTANCE_TRANSFORMS"
        else:
            next_gate = "STOP_AND_REQUEST_CHIP_PG_OWNER_INPUT"

        status.update(
            {
                "STATUS": "PASS",
                "RESULT": "PG_ACCESS_EVIDENCE_READY_FOR_REVIEW",
                "CONTRACT_SCHEMA": contract["schema"],
                "CONTRACT_SHA256": sha256(args.contract),
                "PROBE_ROOT": probe,
                "SOURCE_AUDIT_ROOT": source,
                "SOURCE_IDENTITY_GATE_STATUS": "PASS",
                "SOURCE_IDENTITY_SHA256": sha256(probe / "source_identity.tsv"),
                "SUPPLY_TOP_SHAPES_SHA256": sha256(
                    probe / "supply_top_shapes.tsv"
                ),
                "SUPPLY_TOP_TERMINALS_SHA256": sha256(
                    probe / "supply_top_terminals.tsv"
                ),
                "SUPPLY_INSTANCE_PINS_SHA256": sha256(
                    probe / "supply_instance_pins.tsv"
                ),
                "DIRECT_METTP_SHAPES_SHA256": sha256(
                    probe / "direct_mettp_shapes.tsv"
                ),
                "VERIFIED_WHITESPACE_SHA256": sha256(
                    source
                    / "processed_contract/verified_digital_whitespace.tsv"
                ),
                "LEGACY_WHITESPACE_POLICY_STATUS": (
                    "SUPERSEDED_BY_BOUNDARY_INSTANCE_MODEL"
                ),
                "SOURCE_INSTANCES_SHA256": sha256(source_instances_path),
                "ASSEMBLY_FLOORPLAN_MODEL_STATUS": "PASS",
                "ASSEMBLY_BOUNDARY_INSTANCE": boundary_row["instance"],
                "ASSEMBLY_BOUNDARY_MASTER": (
                    f"{boundary_row['master_library']}/"
                    f"{boundary_row['master_cell']}/"
                    f"{boundary_row['master_view']}"
                ),
                "ASSEMBLY_BOUNDARY_ORIENT": boundary_row["orient"],
                "ASSEMBLY_BOUNDARY_POLICY": ASSEMBLY_BOUNDARY_POLICY,
                "ASSEMBLY_COORDINATE_POLICY": ASSEMBLY_COORDINATE_POLICY,
                "ASSEMBLY_FIXED_OBSTACLE_POLICY": (
                    ASSEMBLY_FIXED_OBSTACLE_POLICY
                ),
                "ASSEMBLY_PRIMARY_WHITESPACE_POLICY": (
                    ASSEMBLY_PRIMARY_WHITESPACE_POLICY
                ),
                "SOURCE_CELLVIEW_BBOX_UM": source_cellview_bbox.format(),
                "ASSEMBLY_SOURCE_BOUNDARY_BBOX_UM": boundary_source.format(),
                "ASSEMBLY_NORMALIZED_DIE_BBOX_UM": boundary_assembly.format(),
                "ASSEMBLY_SOURCE_CORE_BBOX_UM": core_source.format(),
                "ASSEMBLY_NORMALIZED_CORE_BBOX_UM": core_assembly.format(),
                "SOURCE_TO_ASSEMBLY_TRANSLATION_UM": (
                    f"{source_to_assembly_dx:.6f} "
                    f"{source_to_assembly_dy:.6f}"
                ),
                "ASSEMBLY_TO_SOURCE_TRANSLATION_UM": (
                    f"{-source_to_assembly_dx:.6f} "
                    f"{-source_to_assembly_dy:.6f}"
                ),
                "ASSEMBLY_CORE_KEEPOUT_UM": f"{keepout_um:.6f}",
                "ASSEMBLY_FIXED_OBSTACLE_COUNT": len(obstacle_rows),
                "ASSEMBLY_CORE_OVERLAP_OBSTACLE_COUNT": len(obstacle_rects),
                "ASSEMBLY_VERIFIED_INTERIOR_WHITESPACE_RECT_COUNT": len(
                    free_source
                ),
                "ASSEMBLY_PRIMARY_WHITESPACE_SOURCE_BBOX_UM": (
                    primary_whitespace_source.format()
                ),
                "ASSEMBLY_PRIMARY_WHITESPACE_NORMALIZED_BBOX_UM": (
                    primary_whitespace_assembly.format()
                ),
                "ASSEMBLY_PRIMARY_WHITESPACE_AREA_UM2": (
                    f"{primary_whitespace_source.area:.6f}"
                ),
                "ASSEMBLY_FLOORPLAN_BOUNDARY_SHA256": sha256(
                    out / "assembly_floorplan_boundary.tsv"
                ),
                "ASSEMBLY_FIXED_OBSTACLES_SHA256": sha256(
                    out / "assembly_fixed_obstacles_normalized.tsv"
                ),
                "ASSEMBLY_VERIFIED_WHITESPACE_SHA256": sha256(
                    out / "assembly_verified_whitespace_normalized.tsv"
                ),
                "SOURCE_TO_LOCAL_PG_MAPPING_STATUS": "PASS",
                "INSTANCE_TERMINAL_ENUMERATION_POLICY": (
                    INSTANCE_TERMINAL_ENUMERATION_POLICY
                ),
                "INSTANCE_TRANSFORM_POLICY": INSTANCE_TRANSFORM_POLICY,
                "UNAVAILABLE_TRANSFORM_POLICY": UNAVAILABLE_TRANSFORM_POLICY,
                "LOCAL_VDD_NET": "VDD",
                "CHIP_VDD_NET": mapping["VDD"],
                "LOCAL_VSS_NET": "VSS",
                "CHIP_VSS_NET": mapping["VSS"],
                "DIRECT_TOP_VDD_METTP_ACCESS_COUNT": direct_counts["VDD"],
                "DIRECT_TOP_VSS_METTP_ACCESS_COUNT": direct_counts["VSS"],
                "DIRECT_TOP_CHIP_PG_METTP_ACCESS_STATUS": (
                    "PASS" if direct_gate else "FAIL"
                ),
                "INSTANCE_PIN_VDD_METTP_CANDIDATE_COUNT": instance_counts["VDD"],
                "INSTANCE_PIN_VSS_METTP_CANDIDATE_COUNT": instance_counts["VSS"],
                "INSTANCE_PIN_CHIP_PG_METTP_CANDIDATE_STATUS": (
                    "PASS" if instance_gate else "FAIL"
                ),
                "COMPLETE_SAME_OWNER_PG_PAIR_STATUS": (
                    "PASS" if pair_gate else "FAIL"
                ),
                "COMPLETE_SAME_INSTANCE_PG_PAIR_STATUS": (
                    "PASS" if complete_instance_pair_gate else "FAIL"
                ),
                "REVIEW_CANDIDATE_PAIR_INSTANCE": selected_pair_instance,
                "REVIEW_CANDIDATE_PAIR_OWNER_SCOPE": selected_pair_scope,
                "REVIEW_CANDIDATE_PAIR_SELECTION_POLICY": (
                    PAIR_SELECTION_POLICY
                ),
                "REVIEW_CANDIDATE_COMPLETE_PAIR_COUNT": len(pair_candidates),
                "INSTANCE_CHIP_PG_MASTER_TERMINAL_COUNT": len(
                    master_terminal_keys
                ),
                "INSTANCE_CHIP_PG_DISCONNECTED_MASTER_TERMINAL_COUNT": len(
                    disconnected_master_terminal_keys
                ),
                "INSTANCE_CHIP_PG_TRANSFORM_ELIGIBLE_MASTER_TERMINAL_COUNT": len(
                    transform_eligible_master_terminal_keys
                ),
                "INSTANCE_CHIP_PG_TRANSFORM_UNAVAILABLE_MASTER_TERMINAL_COUNT": (
                    len(transform_unavailable_master_terminal_keys)
                ),
                "INSTANCE_CHIP_PG_NONSTANDARD_UNAVAILABLE_MASTER_TERMINAL_COUNT": (
                    len(nonstandard_unavailable_master_terminal_keys)
                ),
                "INSTANCE_CHIP_PG_TRANSFORM_UNAVAILABLE_ROW_COUNT": sum(
                    str(row["transform_status"])
                    not in ELIGIBLE_INSTANCE_TRANSFORMS
                    for row in instance_inventory
                ),
                "INSTANCE_TRANSFORM_COVERAGE_STATUS": transform_coverage_status,
                "INSTANCE_PIN_VDD_ALL_LAYER_SHAPE_COUNT": (
                    all_layer_instance_counts["VDD"]
                ),
                "INSTANCE_PIN_VSS_ALL_LAYER_SHAPE_COUNT": (
                    all_layer_instance_counts["VSS"]
                ),
                "REVIEW_CANDIDATE_PAIR_STATUS": "PASS" if pair_gate else "FAIL",
                "REVIEW_CANDIDATE_COUNT": len(candidates),
                "DIRECT_METTP_SHAPE_COUNT": sum(
                    positive_mettp(row) for row in direct_mettp
                ),
                "CONTEXT_LIMIT_PER_NET": CONTEXT_LIMIT_PER_NET,
                "CANDIDATE_AUTHORIZATION": (
                    "REVIEW_ONLY_NOT_AN_ASSEMBLY_ANCHOR"
                ),
                "TARGET_INSTANCE_METTP_CONTEXT_STATUS": "NOT_PROBED",
                "BRIDGE_GEOMETRY_STATUS": "NOT_AUTHORIZED",
                "P00_P02_IMPLEMENTATION_AUTHORIZED": "NO",
                "P03_IMPLEMENTATION_AUTHORIZED": "NO",
                "NEXT_GATE": next_gate,
            }
        )
    except Exception as exc:
        status["ERROR"] = str(exc).replace("\n", " ")
        status_path.write_text(
            "".join(f"{key}={value}\n" for key, value in status.items()),
            encoding="utf-8",
        )
        print(f"DIGITAL_PG_ACCESS_STATUS={status_path}")
        print(f"ERROR={status['ERROR']}")
        return 2

    status_path.write_text(
        "".join(f"{key}={value}\n" for key, value in status.items()),
        encoding="utf-8",
    )
    files = sorted(
        path for path in out.iterdir() if path.is_file() and path.name != "SHA256SUMS"
    )
    with (out / "SHA256SUMS").open("w", encoding="utf-8") as handle:
        for path in files:
            handle.write(f"{sha256(path)}  {path.name}\n")
    print(f"DIGITAL_PG_ACCESS_STATUS={status_path}")
    print("DIGITAL_PG_ACCESS_CLASSIFICATION_STATUS=PASS_EVIDENCE_READY")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
