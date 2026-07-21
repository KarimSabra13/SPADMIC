#!/usr/bin/env python3
"""Inventory attributable GDS layers relevant to a hard-block PVS option policy."""

from __future__ import annotations

import argparse
import hashlib
import re
import struct
from collections import Counter
from dataclasses import dataclass, field
from pathlib import Path


TARGETS = ("pad", "pimide")
OPTIONAL_TARGETS = ("nopim",)
GEOMETRY_KINDS = {"BOUNDARY", "PATH", "BOX", "NODE", "TEXTNODE"}

ELEMENT_RECORDS = {
    0x08: "BOUNDARY",
    0x09: "PATH",
    0x0A: "SREF",
    0x0B: "AREF",
    0x0C: "TEXT",
    0x14: "TEXTNODE",
    0x15: "NODE",
    0x2D: "BOX",
}
PURPOSE_RECORDS = {
    0x0E: "DATATYPE",
    0x16: "TEXTTYPE",
    0x2A: "NODETYPE",
    0x2E: "BOXTYPE",
}
EXPECTED_PURPOSE_RECORD = {
    "BOUNDARY": "DATATYPE",
    "PATH": "DATATYPE",
    "TEXT": "TEXTTYPE",
    "TEXTNODE": "NODETYPE",
    "NODE": "NODETYPE",
    "BOX": "BOXTYPE",
}

LAYER_MAP_RE = re.compile(
    r"^\s*layer_map\s+(\d+)\s+(?:-datatype\s+(\d+)\s+)?(\d+)\s*;?",
    re.IGNORECASE,
)
LAYER_DEF_RE = re.compile(
    r"^\s*layer_def\s+([A-Za-z_][A-Za-z0-9_]*)\s+(\d+)\s*;?",
    re.IGNORECASE,
)


class EvidenceError(ValueError):
    pass


@dataclass
class ElementState:
    kind: str
    layer: int | None = None
    purpose: int | None = None
    purpose_record: str = ""
    reference_name: str = ""


@dataclass
class StructureData:
    name: str = ""
    elements: Counter[tuple[str, int, int]] = field(default_factory=Counter)
    references: Counter[str] = field(default_factory=Counter)


@dataclass
class GdsInventory:
    byte_count: int
    record_count: int
    record_types: Counter[int]
    structures: dict[str, StructureData]


@dataclass(frozen=True)
class LayerMapping:
    symbol: str
    internal_layer: int
    gds_layer: int
    gds_datatype: int
    layer_def_line: int
    layer_map_line: int


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def write_lines(path: Path, lines: list[str]) -> None:
    path.write_text("\n".join(lines) + "\n")


def decode_gds_string(payload: bytes, offset: int) -> str:
    try:
        return payload.rstrip(b"\0").decode("ascii")
    except UnicodeDecodeError as error:
        raise EvidenceError(f"non_ascii_gds_string_at_offset={offset}") from error


def int2(payload: bytes, label: str, offset: int) -> int:
    if len(payload) != 2:
        raise EvidenceError(
            f"invalid_{label.lower()}_payload_bytes={len(payload)}_at_offset={offset}"
        )
    return struct.unpack(">h", payload)[0]


def parse_gds(path: Path) -> GdsInventory:
    record_types: Counter[int] = Counter()
    structures: dict[str, StructureData] = {}
    current_structure: StructureData | None = None
    current_element: ElementState | None = None
    offset = 0
    record_count = 0
    endlib_seen = False

    with path.open("rb") as handle:
        while True:
            header = handle.read(4)
            if not header:
                break
            if len(header) != 4:
                raise EvidenceError(f"truncated_record_header_at_offset={offset}")
            if endlib_seen:
                raise EvidenceError(f"record_after_endlib_at_offset={offset}")

            length, record_type, data_type = struct.unpack(">HBB", header)
            if length < 4 or length % 2:
                raise EvidenceError(
                    f"invalid_record_length={length}_at_offset={offset}"
                )
            payload = handle.read(length - 4)
            if len(payload) != length - 4:
                raise EvidenceError(f"truncated_record_at_offset={offset}")

            record_offset = offset
            offset += length
            record_count += 1
            record_types[record_type] += 1

            if record_type == 0x04:  # ENDLIB
                if current_structure is not None or current_element is not None:
                    raise EvidenceError("endlib_with_open_structure_or_element")
                if payload:
                    raise EvidenceError("endlib_has_payload")
                endlib_seen = True
                continue

            if record_type == 0x05:  # BGNSTR
                if current_structure is not None or current_element is not None:
                    raise EvidenceError("nested_bgnstr")
                current_structure = StructureData()
                continue

            if record_type == 0x06:  # STRNAME
                if current_structure is None or current_structure.name:
                    raise EvidenceError("strname_without_unique_open_structure")
                name = decode_gds_string(payload, record_offset)
                if not name or name in structures:
                    raise EvidenceError(f"invalid_or_duplicate_structure={name}")
                current_structure.name = name
                structures[name] = current_structure
                continue

            if record_type == 0x07:  # ENDSTR
                if (
                    current_structure is None
                    or not current_structure.name
                    or current_element is not None
                ):
                    raise EvidenceError("endstr_without_closed_named_structure")
                current_structure = None
                continue

            if record_type in ELEMENT_RECORDS:
                if (
                    current_structure is None
                    or not current_structure.name
                    or current_element is not None
                ):
                    raise EvidenceError(
                        f"invalid_element_start_at_offset={record_offset}"
                    )
                current_element = ElementState(ELEMENT_RECORDS[record_type])
                continue

            if record_type == 0x0D:  # LAYER
                if current_element is None or current_element.kind not in EXPECTED_PURPOSE_RECORD:
                    raise EvidenceError(f"layer_outside_geometry_at_offset={record_offset}")
                if current_element.layer is not None:
                    raise EvidenceError(f"duplicate_layer_at_offset={record_offset}")
                current_element.layer = int2(payload, "layer", record_offset)
                continue

            if record_type in PURPOSE_RECORDS:
                if current_element is None or current_element.kind not in EXPECTED_PURPOSE_RECORD:
                    raise EvidenceError(f"purpose_outside_geometry_at_offset={record_offset}")
                if current_element.purpose is not None:
                    raise EvidenceError(f"duplicate_purpose_at_offset={record_offset}")
                current_element.purpose = int2(payload, PURPOSE_RECORDS[record_type], record_offset)
                current_element.purpose_record = PURPOSE_RECORDS[record_type]
                continue

            if record_type == 0x12:  # SNAME
                if current_element is None or current_element.kind not in {"SREF", "AREF"}:
                    raise EvidenceError(f"sname_outside_reference_at_offset={record_offset}")
                if current_element.reference_name:
                    raise EvidenceError(f"duplicate_sname_at_offset={record_offset}")
                current_element.reference_name = decode_gds_string(payload, record_offset)
                continue

            if record_type == 0x11:  # ENDEL
                if current_structure is None or current_element is None:
                    raise EvidenceError(f"endel_without_element_at_offset={record_offset}")
                if current_element.kind in EXPECTED_PURPOSE_RECORD:
                    expected = EXPECTED_PURPOSE_RECORD[current_element.kind]
                    if current_element.layer is None or current_element.purpose is None:
                        raise EvidenceError(
                            f"incomplete_{current_element.kind.lower()}_at_offset={record_offset}"
                        )
                    if current_element.purpose_record != expected:
                        raise EvidenceError(
                            f"wrong_purpose_record_for_{current_element.kind.lower()}="
                            f"{current_element.purpose_record}_expected={expected}"
                        )
                    current_structure.elements[
                        (
                            current_element.kind,
                            current_element.layer,
                            current_element.purpose,
                        )
                    ] += 1
                else:
                    if not current_element.reference_name:
                        raise EvidenceError(
                            f"reference_without_sname_at_offset={record_offset}"
                        )
                    current_structure.references[current_element.reference_name] += 1
                current_element = None

    if current_structure is not None or current_element is not None:
        raise EvidenceError("gds_ended_with_open_structure_or_element")
    required_singletons = {0x00: "HEADER", 0x01: "BGNLIB", 0x02: "LIBNAME", 0x04: "ENDLIB"}
    for record_type, label in required_singletons.items():
        if record_types[record_type] != 1:
            raise EvidenceError(
                f"{label.lower()}_record_count={record_types[record_type]}_expected=1"
            )
    if record_types[0x05] != record_types[0x07] or record_types[0x05] != len(structures):
        raise EvidenceError("structure_record_count_mismatch")
    if not structures:
        raise EvidenceError("gds_has_no_structures")

    return GdsInventory(
        byte_count=offset,
        record_count=record_count,
        record_types=record_types,
        structures=structures,
    )


def hierarchy_closure(
    structures: dict[str, StructureData], top: str
) -> tuple[set[str], set[str], int]:
    if top not in structures:
        return set(), {top}, 0

    reachable: set[str] = set()
    unresolved: set[str] = set()
    colors: dict[str, int] = {}
    cycle_edges = 0

    def visit(name: str) -> None:
        nonlocal cycle_edges
        colors[name] = 1
        reachable.add(name)
        for reference in structures[name].references:
            if reference not in structures:
                unresolved.add(reference)
                continue
            if colors.get(reference) == 1:
                cycle_edges += 1
                continue
            if colors.get(reference) != 2:
                visit(reference)
        colors[name] = 2

    visit(top)
    return reachable, unresolved, cycle_edges


def aggregate_elements(
    structures: dict[str, StructureData], names: set[str] | None = None
) -> Counter[tuple[str, int, int]]:
    total: Counter[tuple[str, int, int]] = Counter()
    selected = structures if names is None else {name: structures[name] for name in names}
    for structure in selected.values():
        total.update(structure.elements)
    return total


def parse_target_mappings(
    deck: Path, subject: str,
) -> tuple[dict[str, LayerMapping], list[str], list[str]]:
    lines = deck.read_text(errors="replace").splitlines()
    map_by_internal: dict[int, list[tuple[int, int, int]]] = {}
    definitions: dict[str, list[tuple[int, int]]] = {}

    for line_number, line in enumerate(lines, 1):
        map_match = LAYER_MAP_RE.match(line)
        if map_match:
            gds_layer = int(map_match.group(1))
            gds_datatype = int(map_match.group(2) or 0)
            internal_layer = int(map_match.group(3))
            map_by_internal.setdefault(internal_layer, []).append(
                (gds_layer, gds_datatype, line_number)
            )
        definition_match = LAYER_DEF_RE.match(line)
        if definition_match:
            definitions.setdefault(definition_match.group(1).lower(), []).append(
                (int(definition_match.group(2)), line_number)
            )

    mappings: dict[str, LayerMapping] = {}
    errors: list[str] = []
    report = [
        "symbol\tlayer_def_line\tinternal_layer\tgds_layer\tgds_datatype\tlayer_map_line\tstatus"
    ]
    for symbol in TARGETS + OPTIONAL_TARGETS:
        candidates: set[tuple[int, int, int, int, int]] = set()
        for internal_layer, def_line in definitions.get(symbol, []):
            for gds_layer, gds_datatype, map_line in map_by_internal.get(internal_layer, []):
                candidates.add(
                    (internal_layer, gds_layer, gds_datatype, def_line, map_line)
                )
        if len(candidates) == 1:
            internal_layer, gds_layer, gds_datatype, def_line, map_line = next(
                iter(candidates)
            )
            mappings[symbol] = LayerMapping(
                symbol,
                internal_layer,
                gds_layer,
                gds_datatype,
                def_line,
                map_line,
            )
            report.append(
                f"{symbol.upper()}\t{def_line}\t{internal_layer}\t{gds_layer}\t"
                f"{gds_datatype}\t{map_line}\tPASS"
            )
        else:
            status = "NOT_FOUND" if not candidates else "AMBIGUOUS"
            report.append(f"{symbol.upper()}\t\t\t\t\t\t{status}")
            if symbol in TARGETS:
                errors.append(f"{symbol}_mapping_{status.lower()}")

    context_indexes: set[int] = set()
    for symbol in TARGETS + OPTIONAL_TARGETS:
        for internal_layer, def_line in definitions.get(symbol, []):
            relevant_lines = [def_line]
            relevant_lines.extend(
                map_line for _, _, map_line in map_by_internal.get(internal_layer, [])
            )
            for line_number in relevant_lines:
                context_indexes.update(
                    range(max(1, line_number - 2), min(len(lines), line_number + 2) + 1)
                )
    context = [
        f"LABEL=SPADMIC_{subject}_PVS_DRC_TARGET_LAYER_MAPPING_CONTEXT",
        f"SOURCE={deck}",
        f"SOURCE_SHA256={sha256_file(deck)}",
        *(f"{index}:{lines[index - 1]}" for index in sorted(context_indexes)),
    ]
    return mappings, report, context + [f"MAPPING_ERROR_COUNT={len(errors)}"]


def count_tuple(
    elements: Counter[tuple[str, int, int]], mapping: LayerMapping
) -> tuple[int, int]:
    geometry = 0
    text = 0
    for (kind, layer, datatype), count in elements.items():
        if layer != mapping.gds_layer or datatype != mapping.gds_datatype:
            continue
        if kind in GEOMETRY_KINDS:
            geometry += count
        elif kind == "TEXT":
            text += count
    return geometry, text


def collect(args: argparse.Namespace) -> int:
    output = args.output_dir.resolve()
    output.mkdir(parents=True, exist_ok=True)
    subject = args.subject_label.upper()
    subject_lower = args.subject_label.lower()
    source_paths = [args.gds.resolve(), args.stream_map.resolve(), args.drc_rule.resolve()]
    errors: list[str] = []

    required_gate = all(path.is_file() and path.stat().st_size > 0 for path in source_paths)
    if not required_gate:
        errors.extend(f"missing_or_empty={path}" for path in source_paths if not path.is_file() or path.stat().st_size == 0)
        write_lines(
            output / "gds_layer_applicability_collector_status.rpt",
            [
                f"LABEL=SPADMIC_{subject}_PVS_DRC_GDS_LAYER_APPLICABILITY_COLLECTOR",
                "COLLECTOR_STATUS=FAIL",
                "SOURCE_REQUIRED_FILE_GATE_STATUS=FAIL",
                "STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO",
                "PVS_REPLAY_AUTHORIZED=NO",
                "PVS_EXECUTED=NO",
                f"ERROR_COUNT={len(errors)}",
                *(f"ERROR={error}" for error in errors),
            ],
        )
        return 8

    before = {path: sha256_file(path) for path in source_paths}
    expected = {
        source_paths[0]: args.expected_gds_sha,
        source_paths[1]: args.expected_stream_map_sha,
        source_paths[2]: args.expected_drc_sha,
    }
    known_hash_gate = all(before[path] == expected[path] for path in source_paths)
    if not known_hash_gate:
        errors.append("known_source_hash_mismatch")

    mappings, mapping_report, mapping_context = parse_target_mappings(
        source_paths[2], subject
    )
    write_lines(output / "pvs_target_layer_mapping.tsv", mapping_report)
    write_lines(output / "pvs_target_layer_context.rpt", mapping_context)
    mapping_gate = all(symbol in mappings for symbol in TARGETS)
    if not mapping_gate:
        errors.append("required_target_layer_mapping_unresolved")

    stream_lines = source_paths[1].read_text(errors="replace").splitlines()
    stream_matches = [
        (index, line)
        for index, line in enumerate(stream_lines, 1)
        if re.search(r"(?i)(?<![A-Za-z0-9_])(pad|pimide|nopim)(?![A-Za-z0-9_])", line)
    ]
    write_lines(
        output / "stream_map_target_context.rpt",
        [
            f"LABEL=SPADMIC_{subject}_PVS_DRC_STREAM_MAP_TARGET_CONTEXT",
            f"STREAM_MAP={source_paths[1]}",
            f"STREAM_MAP_BYTES={source_paths[1].stat().st_size}",
            f"STREAM_MAP_SHA256={before[source_paths[1]]}",
            f"TARGET_MATCH_LINE_COUNT={len(stream_matches)}",
            *(f"{index}:{line}" for index, line in stream_matches),
        ],
    )

    inventory: GdsInventory | None = None
    parse_error = ""
    try:
        inventory = parse_gds(source_paths[0])
    except (EvidenceError, OSError) as error:
        parse_error = str(error)
        errors.append(f"gds_parse={parse_error}")

    parse_gate = inventory is not None
    top_gate = False
    hierarchy_gate = False
    reachable: set[str] = set()
    unresolved: set[str] = set()
    cycle_edges = 0
    all_elements: Counter[tuple[str, int, int]] = Counter()
    reachable_elements: Counter[tuple[str, int, int]] = Counter()

    if inventory is not None:
        top_gate = args.top_structure in inventory.structures
        reachable, unresolved, cycle_edges = hierarchy_closure(
            inventory.structures, args.top_structure
        )
        hierarchy_gate = top_gate and not unresolved and cycle_edges == 0
        if not top_gate:
            errors.append(f"top_structure_missing={args.top_structure}")
        if unresolved:
            errors.append("reachable_unresolved_references=" + ",".join(sorted(unresolved)))
        if cycle_edges:
            errors.append(f"reachable_hierarchy_cycle_edges={cycle_edges}")
        all_elements = aggregate_elements(inventory.structures)
        reachable_elements = aggregate_elements(inventory.structures, reachable)

        structure_report = [
            "structure\treachable\telement_record_count\treference_record_count\tunique_reference_count"
        ]
        for name in sorted(inventory.structures):
            structure = inventory.structures[name]
            structure_report.append(
                f"{name}\t{'YES' if name in reachable else 'NO'}\t"
                f"{sum(structure.elements.values())}\t{sum(structure.references.values())}\t"
                f"{len(structure.references)}"
            )
        write_lines(output / "gds_structure_inventory.tsv", structure_report)

        layer_report = ["scope\telement_kind\tlayer\tdatatype\tdefinition_element_count"]
        for scope, elements in (("ALL", all_elements), ("REACHABLE", reachable_elements)):
            for (kind, layer, datatype), count in sorted(elements.items()):
                layer_report.append(f"{scope}\t{kind}\t{layer}\t{datatype}\t{count}")
        write_lines(output / "gds_layer_inventory.tsv", layer_report)
    else:
        write_lines(
            output / "gds_structure_inventory.tsv",
            ["structure\treachable\telement_record_count\treference_record_count\tunique_reference_count"],
        )
        write_lines(
            output / "gds_layer_inventory.tsv",
            ["scope\telement_kind\tlayer\tdatatype\tdefinition_element_count"],
        )

    parser_summary = [
        f"LABEL=SPADMIC_{subject}_PVS_DRC_GDS_PARSER_SUMMARY",
        f"GDS={source_paths[0]}",
        f"GDS_BYTES={source_paths[0].stat().st_size}",
        f"GDS_SHA256={before[source_paths[0]]}",
        f"GDS_PARSE_STATUS={'PASS' if parse_gate else 'FAIL'}",
        f"GDS_PARSE_ERROR={parse_error if parse_error else 'NONE'}",
        f"TOP_STRUCTURE={args.top_structure}",
        f"TOP_STRUCTURE_STATUS={'PASS' if top_gate else 'FAIL'}",
        f"HIERARCHY_STATUS={'PASS' if hierarchy_gate else 'FAIL'}",
        f"REACHABLE_UNRESOLVED_REFERENCE_COUNT={len(unresolved)}",
        f"REACHABLE_HIERARCHY_CYCLE_EDGE_COUNT={cycle_edges}",
    ]
    if inventory is not None:
        parser_summary.extend(
            [
                f"PARSED_BYTE_COUNT={inventory.byte_count}",
                f"RECORD_COUNT={inventory.record_count}",
                f"STRUCTURE_COUNT={len(inventory.structures)}",
                f"REACHABLE_STRUCTURE_COUNT={len(reachable)}",
                f"SERIALIZED_ELEMENT_RECORD_COUNT={sum(all_elements.values())}",
                f"REACHABLE_DEFINITION_ELEMENT_RECORD_COUNT={sum(reachable_elements.values())}",
                f"ENDLIB_RECORD_COUNT={inventory.record_types[0x04]}",
            ]
        )
    write_lines(output / "gds_parser_summary.rpt", parser_summary)

    target_counts: dict[str, tuple[int, int, int, int]] = {}
    for symbol, mapping in mappings.items():
        all_geometry, all_text = count_tuple(all_elements, mapping)
        reachable_geometry, reachable_text = count_tuple(reachable_elements, mapping)
        target_counts[symbol] = (
            all_geometry,
            all_text,
            reachable_geometry,
            reachable_text,
        )

    pad_geometry = target_counts.get("pad", (-1, -1, -1, -1))[2]
    pimide_geometry = target_counts.get("pimide", (-1, -1, -1, -1))[2]
    applicability_ready = (
        parse_gate
        and hierarchy_gate
        and mapping_gate
        and pad_geometry == 0
        and pimide_geometry == 0
    )
    if not (parse_gate and hierarchy_gate and mapping_gate):
        pimide_status = "UNKNOWN_EVIDENCE_GATE_FAILED"
        recommendation = "HOLD"
    elif applicability_ready:
        pimide_status = "NOT_APPLICABLE_NO_REACHABLE_PAD_OR_PIMIDE_GEOMETRY"
        recommendation = "READY_FOR_MANUAL_AUTHORIZATION"
    else:
        pimide_status = "REVIEW_REQUIRED_REACHABLE_PAD_OR_PIMIDE_GEOMETRY_PRESENT"
        recommendation = "HOLD"

    policy_report = [
        f"LABEL=SPADMIC_{subject}_PVS_DRC_OPTION_POLICY_CONTRACT",
        "DEFAULT_RULE_SET=default",
        "DEFAULT_RULE_SET_SELECTION_STATUS=PASS",
        "DENSITY_STATE=UNDEFINED",
        "DENSITY_POLICY=BASE_DRC_PLUS_SEPARATE_DENSITY_DRC",
        "POPPING_STATE=UNDEFINED",
        "POPPING_POLICY=DEFER_TO_POST_FILL_CHIP_LEVEL_CONTEXT",
        "DUMMY_FILL_STATE=UNDEFINED",
        f"DUMMY_FILL_POLICY=NO_VIRTUAL_DUMMY_GENERATION_DURING_{subject}_OOC_DRC",
        "VAR_ANT_RATIO_STATE=DEFINED",
        "VAR_ANT_RATIO_POLICY=RETAIN_SUPPLEMENTAL_ADD_RULE_FAMILY",
        f"PIMIDE_STATE=UNDEFINED",
        f"PIMIDE_{subject}_APPLICABILITY_STATUS={pimide_status}",
        f"STRICT_DRY_RUN_PREFLIGHT_RECOMMENDATION={recommendation}",
        "STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO",
        "PVS_REPLAY_AUTHORIZED=NO",
        "PVS_EXECUTED=NO",
    ]
    write_lines(output / f"{subject_lower}_option_policy_contract.rpt", policy_report)

    after = {path: sha256_file(path) for path in source_paths}
    source_recheck = before == after
    if not source_recheck:
        errors.append("source_recheck_mismatch")
    source_report = ["path\tbytes\tsha256_before\tsha256_after\tunchanged"]
    for path in source_paths:
        source_report.append(
            f"{path}\t{path.stat().st_size}\t{before[path]}\t{after[path]}\t"
            f"{'YES' if before[path] == after[path] else 'NO'}"
        )
    write_lines(output / "source_file_identity.tsv", source_report)

    technical_pass = all(
        (required_gate, known_hash_gate, mapping_gate, parse_gate, top_gate, hierarchy_gate, source_recheck)
    )
    status_lines = [
        f"LABEL=SPADMIC_{subject}_PVS_DRC_GDS_LAYER_APPLICABILITY_COLLECTOR",
        f"COLLECTOR_STATUS={'PASS' if technical_pass else 'FAIL'}",
        "SOURCE_REQUIRED_FILE_GATE_STATUS=PASS",
        f"KNOWN_SOURCE_HASH_GATE_STATUS={'PASS' if known_hash_gate else 'FAIL'}",
        f"GDS_PARSE_STATUS={'PASS' if parse_gate else 'FAIL'}",
        f"GDS_TOP_STRUCTURE_STATUS={'PASS' if top_gate else 'FAIL'}",
        f"GDS_HIERARCHY_STATUS={'PASS' if hierarchy_gate else 'FAIL'}",
        f"TARGET_LAYER_MAPPING_STATUS={'PASS' if mapping_gate else 'FAIL'}",
        f"SOURCE_RECHECK_STATUS={'PASS' if source_recheck else 'FAIL'}",
        f"GDS_SHA256={before[source_paths[0]]}",
        f"STREAM_MAP_SHA256={before[source_paths[1]]}",
        f"DRC_RULE_SHA256={before[source_paths[2]]}",
        f"TOP_STRUCTURE={args.top_structure}",
        f"STRUCTURE_COUNT={len(inventory.structures) if inventory else 0}",
        f"REACHABLE_STRUCTURE_COUNT={len(reachable)}",
        "TARGET_COUNT_BASIS=UNIQUE_REACHABLE_STRUCTURE_DEFINITIONS",
    ]
    for symbol in TARGETS + OPTIONAL_TARGETS:
        upper = symbol.upper()
        if symbol in mappings:
            mapping = mappings[symbol]
            all_geometry, all_text, reachable_geometry, reachable_text = target_counts[symbol]
            status_lines.extend(
                [
                    f"{upper}_MAPPING_STATUS=PASS",
                    f"{upper}_INTERNAL_LAYER={mapping.internal_layer}",
                    f"{upper}_GDS_LAYER={mapping.gds_layer}",
                    f"{upper}_GDS_DATATYPE={mapping.gds_datatype}",
                    f"{upper}_ALL_GEOMETRY_ELEMENT_COUNT={all_geometry}",
                    f"{upper}_ALL_TEXT_ELEMENT_COUNT={all_text}",
                    f"{upper}_REACHABLE_GEOMETRY_ELEMENT_COUNT={reachable_geometry}",
                    f"{upper}_REACHABLE_TEXT_ELEMENT_COUNT={reachable_text}",
                ]
            )
        else:
            status_lines.append(f"{upper}_MAPPING_STATUS=NOT_FOUND")
    status_lines.extend(
        [
            f"PIMIDE_{subject}_APPLICABILITY_STATUS={pimide_status}",
            f"STRICT_DRY_RUN_PREFLIGHT_RECOMMENDATION={recommendation}",
            "STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO",
            "PVS_REPLAY_AUTHORIZED=NO",
            "PVS_EXECUTED=NO",
            f"ERROR_COUNT={len(errors)}",
            *(f"ERROR={error}" for error in errors),
        ]
    )
    write_lines(output / "gds_layer_applicability_collector_status.rpt", status_lines)
    return 0 if technical_pass else 8


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--gds", type=Path, required=True)
    parser.add_argument("--stream-map", type=Path, required=True)
    parser.add_argument("--drc-rule", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--top-structure", default="spadmic_position_core")
    parser.add_argument(
        "--subject-label",
        choices=("position", "event"),
        default="position",
        help="label used in generated contracts; defaults preserve Position output",
    )
    parser.add_argument("--expected-gds-sha", required=True)
    parser.add_argument("--expected-stream-map-sha", required=True)
    parser.add_argument("--expected-drc-sha", required=True)
    return parser.parse_args()


if __name__ == "__main__":
    raise SystemExit(collect(parse_args()))
