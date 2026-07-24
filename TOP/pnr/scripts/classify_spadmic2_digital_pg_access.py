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
    "MASTER_TERMINALS_WITH_OPTIONAL_INSTTERM_CONNECTIVITY"
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


def physical_shape_status(row: dict[str, str]) -> str:
    try:
        area = rect_from_row(row).area
    except (KeyError, ValueError):
        return "NO_PHYSICAL_FIGURE"
    if area <= 0.0:
        return "NONPOSITIVE_AREA"
    if row.get("layer", "").strip().upper() == "METTP":
        return "POSITIVE_AREA_METTP"
    return "POSITIVE_AREA_NON_METTP"


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
                "of instTerm connectivity"
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
            "master_library",
            "master_cell",
            "master_view",
            "orient",
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
        whitespace = read_tsv(
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
            local_net, chip_net, match_field = resolved
            rect = rect_from_row(row)
            relation, distance, whitespace_rank = whitespace_context(
                rect,
                whitespace,
            )
            candidates.append(
                {
                    "local_net": local_net,
                    "chip_net": chip_net,
                    "source_object": source_object,
                    "evidence_class": evidence_class,
                    "match_field": match_field,
                    "instance": row.get("instance", "TOP"),
                    "master_library": row.get("master_library", ""),
                    "master_cell": row.get("master_cell", ""),
                    "master_view": row.get("master_view", ""),
                    "orient": row.get("orient", ""),
                    "terminal": row.get("terminal", ""),
                    "connected_net": row.get("net", ""),
                    "shape_type": row.get("shape_type", ""),
                    "layer": row["layer"],
                    "purpose": row["purpose"],
                    "llx": row["llx"],
                    "lly": row["lly"],
                    "urx": row["urx"],
                    "ury": row["ury"],
                    "whitespace_rank": whitespace_rank,
                    "whitespace_relation": relation,
                    "whitespace_distance_um": distance,
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
                    "master_library": row.get("master_library", ""),
                    "master_cell": row.get("master_cell", ""),
                    "master_view": row.get("master_view", ""),
                    "orient": row.get("orient", ""),
                    "terminal": row.get("terminal", ""),
                    "connected_net": row.get("net", ""),
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
                    "physical_shape_status": physical_shape_status(row),
                    "mettp_candidate_status": (
                        "REVIEW_CANDIDATE"
                        if positive_mettp(row)
                        else "NOT_METTP_CANDIDATE"
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
            "master_library",
            "master_cell",
            "master_view",
            "orient",
            "terminal",
            "connected_net",
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
                    "layer": key[4],
                    "purpose": key[5],
                    "physical_shape_status": key[6],
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
            "master_library",
            "master_cell",
            "master_view",
            "orient",
            "terminal",
            "connected_net",
            "shape_type",
            "layer",
            "purpose",
            "llx",
            "lly",
            "urx",
            "ury",
            "whitespace_rank",
            "whitespace_relation",
            "whitespace_distance_um",
            "authorization",
        ]
        candidates.sort(
            key=lambda row: (
                row["local_net"],
                evidence_rank(str(row["evidence_class"])),
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

        recommendations: list[dict[str, object]] = []
        for local_net in local_nets:
            local_candidates = [
                row for row in candidates if row["local_net"] == local_net
            ]
            if local_candidates:
                recommendations.append(
                    {
                        **local_candidates[0],
                        "selection_basis": (
                            "STRONGEST_EVIDENCE_THEN_NEAREST_VERIFIED_WHITESPACE"
                        ),
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
                            "candidate_master_cell": candidate["master_cell"],
                            "candidate_terminal": candidate["terminal"],
                            "candidate_connected_net": candidate["connected_net"],
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
                "candidate_master_cell",
                "candidate_terminal",
                "candidate_connected_net",
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
        pair_gate = len(recommendations) == len(local_nets)
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
        elif instance_gate:
            next_gate = "SELECT_INSTANCE_PIN_PAIR_AND_DEFINE_CANDIDATE_BRIDGES"
        elif all(all_layer_instance_counts[net] > 0 for net in local_nets):
            next_gate = (
                "REVIEW_NON_METTP_CHIP_PG_PINS_AND_REQUEST_ROUTABLE_ACCESS"
            )
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
                "SOURCE_TO_LOCAL_PG_MAPPING_STATUS": "PASS",
                "INSTANCE_TERMINAL_ENUMERATION_POLICY": (
                    INSTANCE_TERMINAL_ENUMERATION_POLICY
                ),
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
                "INSTANCE_CHIP_PG_MASTER_TERMINAL_COUNT": len(
                    master_terminal_keys
                ),
                "INSTANCE_CHIP_PG_DISCONNECTED_MASTER_TERMINAL_COUNT": len(
                    disconnected_master_terminal_keys
                ),
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
