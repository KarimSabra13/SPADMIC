#!/usr/bin/env python3
"""Classify read-only hierarchical METTP context around the selected I6 PG pair."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


ROOT = Path(__file__).resolve().parents[3]
DEFAULT_CONTRACT = ROOT / "TOP/pnr/assembly/spadmic_digital_assembly_contract.json"
QUERY_POLICY = "DB_GET_TRUE_OVERLAPS_DEPTH_0_32_WITH_ROW_COLUMN_ENUMERATION"
TRANSFORM_POLICY = "DB_GET_HIER_PATH_TRANSFORM"
CANDIDATE_POLICY = "REVIEW_ONLY_NO_GEOMETRY_CREATION"
ALLOWED_TRANSFORMS = {
    "TOP_CELLVIEW_IDENTITY",
    "DB_GET_HIER_PATH_TRANSFORM",
}


@dataclass(frozen=True)
class Rect:
    llx: float
    lly: float
    urx: float
    ury: float

    @property
    def width(self) -> float:
        return self.urx - self.llx

    @property
    def height(self) -> float:
        return self.ury - self.lly

    @property
    def positive(self) -> bool:
        return self.width > 0.0 and self.height > 0.0

    def intersection(self, other: "Rect") -> "Rect | None":
        result = Rect(
            max(self.llx, other.llx),
            max(self.lly, other.lly),
            min(self.urx, other.urx),
            min(self.ury, other.ury),
        )
        return result if result.positive else None

    def contacts(self, other: "Rect") -> bool:
        return (
            min(self.urx, other.urx) >= max(self.llx, other.llx)
            and min(self.ury, other.ury) >= max(self.lly, other.lly)
        )

    def format(self) -> str:
        return (
            f"{self.llx:.6f} {self.lly:.6f} "
            f"{self.urx:.6f} {self.ury:.6f}"
        )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--probe-root", required=True, type=Path)
    parser.add_argument("--floorplan-root", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--contract", type=Path, default=DEFAULT_CONTRACT)
    return parser.parse_args()


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read_status(path: Path) -> dict[str, str]:
    if not path.is_file():
        raise ValueError(f"missing status report: {path}")
    return dict(
        line.split("=", 1)
        for line in path.read_text(encoding="utf-8").splitlines()
        if "=" in line
    )


def read_tsv(path: Path, required: Iterable[str]) -> list[dict[str, str]]:
    if not path.is_file():
        raise ValueError(f"missing TSV input: {path}")
    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        missing = sorted(set(required) - set(reader.fieldnames or []))
        if missing:
            raise ValueError(f"{path}: missing columns {missing}")
        return list(reader)


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


def rect_from_row(row: dict[str, str], prefix: str = "") -> Rect:
    return Rect(
        *(float(row[f"{prefix}{name}"]) for name in ("llx", "lly", "urx", "ury"))
    )


def rect_from_values(values: Iterable[object]) -> Rect:
    rect = Rect(*(float(value) for value in values))
    if not rect.positive:
        raise ValueError(f"non-positive rectangle: {rect.format()}")
    return rect


def same_rect(first: Rect, second: Rect, tolerance: float = 1e-6) -> bool:
    return all(
        abs(left - right) <= tolerance
        for left, right in zip(
            (first.llx, first.lly, first.urx, first.ury),
            (second.llx, second.lly, second.urx, second.ury),
        )
    )


def main() -> int:
    args = parse_args()
    probe = args.probe_root.resolve()
    floorplan = args.floorplan_root.resolve()
    out = args.out.resolve()
    if out.exists():
        if not out.is_dir() or any(out.iterdir()):
            print(f"ERROR=immutable corridor classification output populated: {out}")
            return 2
    else:
        out.mkdir(parents=True)

    status_path = out / "selected_i6_corridor_status.rpt"
    status: dict[str, object] = {
        "LABEL": "SPADMIC2_SELECTED_I6_METTP_CORRIDOR_CLASSIFICATION",
        "STATUS": "FAIL",
        "RESULT": "CORRIDOR_EVIDENCE_REJECTED",
        "PROCESSOR_SHA256": sha256(Path(__file__).resolve()),
        "SOURCE_MUTATION_AUTHORIZED": "NO",
        "OA_EDIT_AUTHORIZED": "NO",
        "GENUS_AUTHORIZED": "NO",
        "INNOVUS_AUTHORIZED": "NO",
        "BRIDGE_GEOMETRY_STATUS": "NOT_AUTHORIZED",
        "P00_P02_IMPLEMENTATION_AUTHORIZED": "NO",
        "P03_IMPLEMENTATION_AUTHORIZED": "NO",
    }

    try:
        contract = json.loads(args.contract.read_text(encoding="utf-8"))
        corridor = contract["selected_pg_corridor_probe"]
        target_spec = corridor["target_instance"]
        pin_specs = corridor["target_pins"]
        if corridor.get("candidate_policy") != CANDIDATE_POLICY:
            raise ValueError("unsupported selected-PG corridor candidate policy")
        if corridor.get("hierarchy_depth") != [0, 32]:
            raise ValueError("selected-PG corridor hierarchy depth must be 0:32")
        if corridor.get("include_mosaic_rows_and_columns") is not True:
            raise ValueError("mosaic row/column enumeration must be enabled")

        expected_pins = {
            local_net: rect_from_values(spec["source_bbox_um"])
            for local_net, spec in pin_specs.items()
        }
        if set(expected_pins) != {"VDD", "VSS"}:
            raise ValueError("selected-PG corridor must define VDD and VSS")
        entry_x = float(corridor["primary_whitespace_entry_x_um"])
        margins = {
            key: float(value)
            for key, value in corridor["context_margin_um"].items()
        }
        pair_llx = min(rect.llx for rect in expected_pins.values())
        pair_lly = min(rect.lly for rect in expected_pins.values())
        pair_ury = max(rect.ury for rect in expected_pins.values())
        query_window = Rect(
            pair_llx - margins["west"],
            pair_lly - margins["south"],
            entry_x + margins["inside_primary_whitespace"],
            pair_ury + margins["north"],
        )

        export_status = read_status(probe / "virtuoso_export_status.rpt")
        query_status = read_status(probe / "corridor_query_status.rpt")
        if export_status.get("STATUS") != "PASS":
            raise ValueError("corridor Virtuoso export status is not PASS")
        if export_status.get("HIERARCHICAL_QUERY_POLICY") != QUERY_POLICY:
            raise ValueError("corridor hierarchical query policy mismatch")
        if export_status.get("HIERARCHICAL_TRANSFORM_POLICY") != TRANSFORM_POLICY:
            raise ValueError("corridor hierarchy transform policy mismatch")
        if export_status.get("CORRIDOR_AUTHORIZATION") != CANDIDATE_POLICY:
            raise ValueError("corridor export authorization mismatch")
        if query_status.get("STATUS") != "PASS":
            raise ValueError("hierarchical corridor query status is not PASS")
        if query_status.get("QUERY_WINDOW_UM") != query_window.format():
            raise ValueError("hierarchical query window does not match contract")
        if query_status.get("HIERARCHICAL_TRANSFORM_FAILURE_COUNT") != "0":
            raise ValueError("hierarchical query contains transform failures")

        expected_source = contract["source_layouts"]["spadmic2"]
        identity = read_tsv(
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
        if len(identity) != 1:
            raise ValueError("corridor source identity row count is not one")
        for key, expected in {
            "role": "spadmic2",
            "library": expected_source["library"],
            "cell": expected_source["cell"],
            "view": expected_source["view"],
            "filesystem_path": expected_source["filesystem_path"],
            "open_status": "PASS",
        }.items():
            if identity[0].get(key) != expected:
                raise ValueError(f"corridor source identity mismatch: {key}")

        target_rows = read_tsv(
            probe / "target_instance.tsv",
            [
                "instance",
                "instance_object_type",
                "master_library",
                "master_cell",
                "master_view",
                "orient",
                "transform",
                "llx",
                "lly",
                "urx",
                "ury",
            ],
        )
        if len(target_rows) != 1:
            raise ValueError("selected target instance row count is not one")
        target = target_rows[0]
        for key in (
            "instance",
            "master_library",
            "master_cell",
            "master_view",
            "orient",
        ):
            if target.get(key) != str(target_spec[key]):
                raise ValueError(f"selected target instance mismatch: {key}")
        if target.get("instance_object_type") != "inst":
            raise ValueError("selected target must be a standard OA instance")

        pin_rows = read_tsv(
            probe / "target_pg_pins.tsv",
            [
                "instance",
                "terminal",
                "direction",
                "net",
                "shape_type",
                "layer",
                "purpose",
                "master_llx",
                "master_lly",
                "master_urx",
                "master_ury",
                "llx",
                "lly",
                "urx",
                "ury",
                "transform_status",
            ],
        )
        if int(query_status.get("TARGET_PG_PIN_SHAPE_COUNT", "-1")) != len(
            pin_rows
        ):
            raise ValueError("target PG pin row count does not match query status")
        selected_pins: dict[str, dict[str, str]] = {}
        for local_net, spec in pin_specs.items():
            matching = [
                row
                for row in pin_rows
                if row["instance"] == target_spec["instance"]
                and row["terminal"].upper() == str(spec["chip_net"]).upper()
                and row["layer"].upper() == str(spec["layer"]).upper()
                and row["purpose"].upper() == str(spec["purpose"]).upper()
                and row["transform_status"] == "DB_INSTANCE_TRANSFORM"
                and same_rect(rect_from_row(row), expected_pins[local_net])
            ]
            if len(matching) != 1:
                raise ValueError(
                    f"selected {local_net} target pin exact-match count is "
                    f"{len(matching)}, expected one"
                )
            selected_pins[local_net] = matching[0]

        floorplan_status = read_status(floorplan / "digital_pg_access_status.rpt")
        required_floorplan = {
            "STATUS": "PASS",
            "ASSEMBLY_FLOORPLAN_MODEL_STATUS": "PASS",
            "REVIEW_CANDIDATE_PAIR_INSTANCE": target_spec["instance"],
            "REVIEW_CANDIDATE_PAIR_OWNER_SCOPE": "INSTANCE",
            "TARGET_INSTANCE_METTP_CONTEXT_STATUS": "NOT_PROBED",
            "BRIDGE_GEOMETRY_STATUS": "NOT_AUTHORIZED",
            "NEXT_GATE": "RUN_READ_ONLY_SELECTED_INSTANCE_METTP_CORRIDOR_PROBE",
        }
        for key, expected in required_floorplan.items():
            if floorplan_status.get(key) != expected:
                raise ValueError(f"accepted floorplan status mismatch: {key}")
        if (
            floorplan_status.get("ASSEMBLY_PRIMARY_WHITESPACE_SOURCE_BBOX_UM", "")
            .split()[0]
            != f"{entry_x:.6f}"
        ):
            raise ValueError("primary whitespace entry does not match contract")

        accepted_pair = read_tsv(
            floorplan / "digital_pg_review_pair.tsv",
            [
                "local_net",
                "chip_net",
                "instance",
                "layer",
                "purpose",
                "llx",
                "lly",
                "urx",
                "ury",
            ],
        )
        if len(accepted_pair) != 2:
            raise ValueError("accepted floorplan pair must contain two rows")
        for local_net, spec in pin_specs.items():
            matching = [
                row
                for row in accepted_pair
                if row["local_net"].upper() == local_net
                and row["chip_net"].upper() == str(spec["chip_net"]).upper()
                and row["instance"] == target_spec["instance"]
                and row["layer"].upper() == str(spec["layer"]).upper()
                and row["purpose"].upper() == str(spec["purpose"]).upper()
                and same_rect(rect_from_row(row), expected_pins[local_net])
            ]
            if len(matching) != 1:
                raise ValueError(
                    f"accepted floorplan {local_net} pair geometry mismatch"
                )

        shape_rows = read_tsv(
            probe / "corridor_hierarchical_shapes.tsv",
            [
                "query_index",
                "hierarchy_depth",
                "top_instance",
                "hierarchy_path",
                "shape_type",
                "net",
                "layer",
                "purpose",
                "transform_status",
                "master_llx",
                "master_lly",
                "master_urx",
                "master_ury",
                "llx",
                "lly",
                "urx",
                "ury",
            ],
        )
        if not shape_rows:
            raise ValueError("hierarchical corridor shape inventory is empty")
        if int(query_status.get("HIERARCHICAL_SHAPE_ROW_COUNT", "-1")) != len(
            shape_rows
        ):
            raise ValueError(
                "hierarchical shape row count does not match query status"
            )
        for row in shape_rows:
            if row["transform_status"] not in ALLOWED_TRANSFORMS:
                raise ValueError(
                    "hierarchical corridor shape has unavailable transform"
                )
            rect = rect_from_row(row)
            if not rect.contacts(query_window):
                raise ValueError("hierarchical shape lies outside query window")

        target_coverage: dict[str, list[dict[str, str]]] = {}
        for local_net, pin in expected_pins.items():
            target_coverage[local_net] = [
                row
                for row in shape_rows
                if row["top_instance"] == target_spec["instance"]
                and row["layer"].upper()
                == str(pin_specs[local_net]["layer"]).upper()
                and row["purpose"].upper()
                == str(pin_specs[local_net]["purpose"]).upper()
                and same_rect(rect_from_row(row), pin)
            ]
            if not target_coverage[local_net]:
                raise ValueError(
                    f"hierarchical query did not recover exact {local_net} pin"
                )

        vdd = expected_pins["VDD"]
        vss = expected_pins["VSS"]
        regions = [
            {
                "region": "DVDD_DIRECT_EAST_SWEEP",
                "local_net": "VDD",
                "bbox": Rect(vdd.urx, vdd.lly, entry_x, vdd.ury),
                "intent": "PROVE_DIRECT_PATH_REJECTION_OR_CLEARANCE",
            },
            {
                "region": "DVSS_DIRECT_EAST_SWEEP",
                "local_net": "VSS",
                "bbox": Rect(vss.urx, vss.lly, entry_x, vss.ury),
                "intent": "SEARCH_DIRECT_WHITESPACE_ENTRY",
            },
            {
                "region": "DVDD_NORTH_ESCAPE_SEARCH",
                "local_net": "VDD",
                "bbox": Rect(
                    vdd.llx,
                    pair_ury,
                    entry_x,
                    query_window.ury,
                ),
                "intent": "SEARCH_JOG_CONTEXT_ONLY",
            },
            {
                "region": "DVDD_SOUTH_ESCAPE_SEARCH",
                "local_net": "VDD",
                "bbox": Rect(
                    vdd.llx,
                    query_window.lly,
                    entry_x,
                    pair_lly,
                ),
                "intent": "SEARCH_JOG_CONTEXT_ONLY",
            },
            {
                "region": "PRIMARY_WHITESPACE_ENTRY_SEARCH",
                "local_net": "VDD_VSS",
                "bbox": Rect(
                    entry_x,
                    query_window.lly,
                    query_window.urx,
                    query_window.ury,
                ),
                "intent": "SEARCH_ENTRY_CONTEXT_ONLY",
            },
        ]
        if not all(item["bbox"].positive for item in regions):
            raise ValueError("derived corridor search region is non-positive")

        region_rows: list[dict[str, object]] = []
        contact_rows: list[dict[str, object]] = []
        region_mettp_contacts: dict[str, int] = {}
        for region in regions:
            region_rect = region["bbox"]
            contacts = []
            for row in shape_rows:
                shape_rect = rect_from_row(row)
                if not shape_rect.contacts(region_rect):
                    continue
                target_pin_owner = "NONE"
                for local_net, pin_rect in expected_pins.items():
                    if (
                        row["layer"].upper()
                        == str(pin_specs[local_net]["layer"]).upper()
                        and same_rect(shape_rect, pin_rect)
                    ):
                        target_pin_owner = local_net
                        break
                overlap = shape_rect.intersection(region_rect)
                relation = "AREA_OVERLAP" if overlap else "BOUNDARY_CONTACT"
                contact = {
                    "region": region["region"],
                    "local_net": region["local_net"],
                    "query_index": row["query_index"],
                    "hierarchy_depth": row["hierarchy_depth"],
                    "top_instance": row["top_instance"],
                    "hierarchy_path": row["hierarchy_path"],
                    "shape_type": row["shape_type"],
                    "net": row["net"],
                    "layer": row["layer"],
                    "purpose": row["purpose"],
                    "llx": f"{shape_rect.llx:.6f}",
                    "lly": f"{shape_rect.lly:.6f}",
                    "urx": f"{shape_rect.urx:.6f}",
                    "ury": f"{shape_rect.ury:.6f}",
                    "geometry_relation": relation,
                    "target_pin_owner": target_pin_owner,
                    "authorization": "CONTEXT_ONLY_NOT_A_BRIDGE",
                }
                contacts.append(contact)
                contact_rows.append(contact)
            mettp_contacts = sum(
                row["layer"].upper() == "METTP" for row in contacts
            )
            non_target_mettp_contacts = sum(
                row["layer"].upper() == "METTP"
                and row["target_pin_owner"] == "NONE"
                for row in contacts
            )
            region_mettp_contacts[str(region["region"])] = mettp_contacts
            region_rows.append(
                {
                    "region": region["region"],
                    "local_net": region["local_net"],
                    "intent": region["intent"],
                    "llx": f"{region_rect.llx:.6f}",
                    "lly": f"{region_rect.lly:.6f}",
                    "urx": f"{region_rect.urx:.6f}",
                    "ury": f"{region_rect.ury:.6f}",
                    "all_layer_contact_count": len(contacts),
                    "mettp_contact_count": mettp_contacts,
                    "non_target_mettp_contact_count": non_target_mettp_contacts,
                    "authorization": "SEARCH_REGION_ONLY_NO_GEOMETRY_CREATION",
                }
            )

        direct_target_intersection = Rect(
            vdd.urx,
            vdd.lly,
            entry_x,
            vdd.ury,
        ).intersection(vss)
        if direct_target_intersection is None:
            raise ValueError("expected DVDD direct sweep does not intersect DVSS")

        layer_counts: dict[tuple[str, str, str], int] = {}
        for row in shape_rows:
            key = (
                row["layer"].upper(),
                row["purpose"].upper(),
                row["transform_status"],
            )
            layer_counts[key] = layer_counts.get(key, 0) + 1
        layer_rows = [
            {
                "layer": layer,
                "purpose": purpose,
                "transform_status": transform,
                "shape_count": count,
            }
            for (layer, purpose, transform), count in sorted(layer_counts.items())
        ]

        write_tsv(
            out / "corridor_search_regions.tsv",
            [
                "region",
                "local_net",
                "intent",
                "llx",
                "lly",
                "urx",
                "ury",
                "all_layer_contact_count",
                "mettp_contact_count",
                "non_target_mettp_contact_count",
                "authorization",
            ],
            region_rows,
        )
        write_tsv(
            out / "corridor_region_contacts.tsv",
            [
                "region",
                "local_net",
                "query_index",
                "hierarchy_depth",
                "top_instance",
                "hierarchy_path",
                "shape_type",
                "net",
                "layer",
                "purpose",
                "llx",
                "lly",
                "urx",
                "ury",
                "geometry_relation",
                "target_pin_owner",
                "authorization",
            ],
            sorted(
                contact_rows,
                key=lambda row: (
                    str(row["region"]),
                    str(row["layer"]),
                    int(str(row["query_index"])),
                ),
            ),
        )
        write_tsv(
            out / "corridor_layer_summary.tsv",
            ["layer", "purpose", "transform_status", "shape_count"],
            layer_rows,
        )
        write_tsv(
            out / "target_pin_hierarchy_coverage.tsv",
            [
                "local_net",
                "chip_net",
                "query_index",
                "hierarchy_depth",
                "top_instance",
                "hierarchy_path",
                "layer",
                "purpose",
                "llx",
                "lly",
                "urx",
                "ury",
                "authorization",
            ],
            [
                {
                    "local_net": local_net,
                    "chip_net": pin_specs[local_net]["chip_net"],
                    "query_index": row["query_index"],
                    "hierarchy_depth": row["hierarchy_depth"],
                    "top_instance": row["top_instance"],
                    "hierarchy_path": row["hierarchy_path"],
                    "layer": row["layer"],
                    "purpose": row["purpose"],
                    "llx": row["llx"],
                    "lly": row["lly"],
                    "urx": row["urx"],
                    "ury": row["ury"],
                    "authorization": "PROVEN_TARGET_PIN_CONTEXT_ONLY",
                }
                for local_net in ("VDD", "VSS")
                for row in target_coverage[local_net]
            ],
        )

        status.update(
            {
                "STATUS": "PASS",
                "RESULT": "SELECTED_I6_METTP_CORRIDOR_EVIDENCE_READY",
                "CONTRACT_SCHEMA": contract["schema"],
                "CONTRACT_SHA256": sha256(args.contract.resolve()),
                "PROBE_ROOT": probe,
                "FLOORPLAN_ROOT": floorplan,
                "SOURCE_IDENTITY_SHA256": sha256(probe / "source_identity.tsv"),
                "TARGET_INSTANCE_SHA256": sha256(probe / "target_instance.tsv"),
                "TARGET_PG_PINS_SHA256": sha256(probe / "target_pg_pins.tsv"),
                "HIERARCHICAL_SHAPES_SHA256": sha256(
                    probe / "corridor_hierarchical_shapes.tsv"
                ),
                "FLOORPLAN_STATUS_SHA256": sha256(
                    floorplan / "digital_pg_access_status.rpt"
                ),
                "FLOORPLAN_REVIEW_PAIR_SHA256": sha256(
                    floorplan / "digital_pg_review_pair.tsv"
                ),
                "SOURCE_IDENTITY_GATE_STATUS": "PASS",
                "ACCEPTED_FLOORPLAN_GATE_STATUS": "PASS",
                "TARGET_INSTANCE_GATE_STATUS": "PASS",
                "TARGET_INSTANCE": target_spec["instance"],
                "TARGET_MASTER": (
                    f"{target_spec['master_library']}/"
                    f"{target_spec['master_cell']}/"
                    f"{target_spec['master_view']}"
                ),
                "TARGET_ORIENT": target_spec["orient"],
                "TARGET_PIN_PAIR_STATUS": "PASS",
                "LOCAL_VDD_NET": "VDD",
                "CHIP_VDD_NET": pin_specs["VDD"]["chip_net"],
                "LOCAL_VSS_NET": "VSS",
                "CHIP_VSS_NET": pin_specs["VSS"]["chip_net"],
                "TARGET_VDD_SOURCE_BBOX_UM": vdd.format(),
                "TARGET_VSS_SOURCE_BBOX_UM": vss.format(),
                "PRIMARY_WHITESPACE_ENTRY_X_UM": f"{entry_x:.6f}",
                "CORRIDOR_QUERY_WINDOW_UM": query_window.format(),
                "HIERARCHICAL_QUERY_POLICY": QUERY_POLICY,
                "HIERARCHICAL_TRANSFORM_POLICY": TRANSFORM_POLICY,
                "HIERARCHICAL_QUERY_STATUS": "PASS",
                "HIERARCHICAL_SHAPE_ROW_COUNT": len(shape_rows),
                "HIERARCHICAL_TRANSFORM_FAILURE_COUNT": 0,
                "TARGET_VDD_HIERARCHICAL_COVERAGE_COUNT": len(
                    target_coverage["VDD"]
                ),
                "TARGET_VSS_HIERARCHICAL_COVERAGE_COUNT": len(
                    target_coverage["VSS"]
                ),
                "TARGET_PIN_HIERARCHICAL_COVERAGE_STATUS": "PASS",
                "DVDD_DIRECT_EAST_TO_WHITESPACE_STATUS": (
                    "REJECT_TARGET_DVSS_INTERSECTION"
                ),
                "DVDD_DIRECT_DVSS_INTERSECTION_BBOX_UM": (
                    direct_target_intersection.format()
                ),
                "DVSS_DIRECT_EAST_SEARCH_METTP_CONTACT_COUNT": (
                    region_mettp_contacts["DVSS_DIRECT_EAST_SWEEP"]
                ),
                "DVDD_NORTH_ESCAPE_SEARCH_METTP_CONTACT_COUNT": (
                    region_mettp_contacts["DVDD_NORTH_ESCAPE_SEARCH"]
                ),
                "DVDD_SOUTH_ESCAPE_SEARCH_METTP_CONTACT_COUNT": (
                    region_mettp_contacts["DVDD_SOUTH_ESCAPE_SEARCH"]
                ),
                "CORRIDOR_SEARCH_REGION_STATUS": "PASS_EVIDENCE_READY",
                "CANDIDATE_AUTHORIZATION": CANDIDATE_POLICY,
                "BRIDGE_CANDIDATE_DEFINITION_STATUS": (
                    "DEFERRED_UNTIL_CORRIDOR_REVIEW"
                ),
                "NEXT_GATE": (
                    "RETURN_I6_CORRIDOR_EVIDENCE_FOR_BRIDGE_CANDIDATE_DEFINITION"
                ),
            }
        )
    except Exception as exc:
        status["ERROR"] = str(exc).replace("\n", " ")
        status_path.write_text(
            "".join(f"{key}={value}\n" for key, value in status.items()),
            encoding="utf-8",
        )
        print(f"SELECTED_I6_CORRIDOR_STATUS={status_path}")
        print(f"ERROR={status['ERROR']}")
        return 2

    status_path.write_text(
        "".join(f"{key}={value}\n" for key, value in status.items()),
        encoding="utf-8",
    )
    files = sorted(
        path
        for path in out.iterdir()
        if path.is_file() and path.name != "SHA256SUMS"
    )
    with (out / "SHA256SUMS").open("w", encoding="utf-8") as handle:
        for path in files:
            handle.write(f"{sha256(path)}  {path.name}\n")
    print(f"SELECTED_I6_CORRIDOR_STATUS={status_path}")
    print("SELECTED_I6_CORRIDOR_CLASSIFICATION_STATUS=PASS_EVIDENCE_READY")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
