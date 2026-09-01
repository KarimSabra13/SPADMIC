#!/usr/bin/env python3
"""Classify the known two-RO_tune6 raw full-top LVS mismatch exactly."""

from __future__ import annotations

import argparse
import hashlib
import re
import sys
from collections import Counter
from dataclasses import dataclass
from pathlib import Path


EXPECTED_TOTAL = (220440, 213961, 220311, 213961, 213960, 213582, 380, 2)
EXPECTED_LAYOUT_MODELS = Counter(
    {
        "MP(PEI)": 18,
        "MP(PELI)": 108,
        "MN(NEI)": 34,
        "MN(NELI)": 122,
        "R(RNP1_3)": 2,
        "C(CSF3)": 96,
    }
)
EXPECTED_ROOTS = Counter({"X0/X0": 190, "X3/X5127": 190})
DEFAULT_RO_INSTANCES = (
    "u_core_u_osc_fast_u_ro_tune4",
    "u_core_u_osc_slow_u_ro_tune4",
)


@dataclass(frozen=True)
class MismatchRecord:
    layout_instance: str
    schematic_instance: str
    layout_model: str
    schematic_model: str
    marker: int


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Require the raw MPTDC mismatch to be exactly two RO_tune6 interiors."
    )
    parser.add_argument("--cls", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--expected-ro-instance", action="append", default=[])
    return parser.parse_args()


def report_scalar(text: str, label: str) -> str | None:
    match = re.search(rf"^{re.escape(label)}\s*[:|]\s*([^|\n]+)", text, re.MULTILINE)
    return match.group(1).strip() if match else None


def parse_records(lines: list[str]) -> list[MismatchRecord]:
    records: list[MismatchRecord] = []
    for index, line in enumerate(lines):
        if not line.startswith("Layout Inst :") or "| Schematic Inst :" not in line:
            continue
        layout_instance, schematic_instance = line.split("| Schematic Inst :", 1)
        layout_instance = layout_instance.split("Layout Inst :", 1)[1].strip()
        schematic_instance = schematic_instance.strip()
        if index + 2 >= len(lines) or "| Schematic Model:" not in lines[index + 1]:
            continue
        layout_model, schematic_model = lines[index + 1].split("| Schematic Model:", 1)
        layout_model = layout_model.split("Layout Model:", 1)[1].strip()
        schematic_model = schematic_model.strip()
        marker_match = re.search(r"\(mi\s+(\d+)\)", lines[index + 2])
        if not marker_match:
            continue
        records.append(
            MismatchRecord(
                layout_instance=layout_instance,
                schematic_instance=schematic_instance,
                layout_model=layout_model,
                schematic_model=schematic_model,
                marker=int(marker_match.group(1)),
            )
        )
    return records


def parse_four_column_row(text: str, label: str) -> tuple[int, ...] | None:
    pattern = re.compile(
        rf"^{re.escape(label)}\s*\|\s*(\d+)\s*:\s*(\d+)\s*\|"
        r"\s*(\d+)\s*:\s*(\d+)\s*\|\s*(\d+)\s*:\s*(\d+)\s*\|"
        r"\s*(\d+)\s*:\s*(\d+)\s*$",
        re.MULTILINE,
    )
    normalized = text.replace(",", "").replace("*", "")
    match = pattern.search(normalized)
    return tuple(int(value) for value in match.groups()) if match else None


def parse_unmatched_pair(text: str, label: str) -> tuple[int, int] | None:
    normalized = text.replace(",", "").replace("*", "")
    for line in normalized.splitlines():
        if not line.startswith(label) or line.count("|") < 4:
            continue
        match = re.search(r"\|\s*(\d+)\s*:\s*(\d+)\s*$", line)
        if match:
            return int(match.group(1)), int(match.group(2))
    return None


def coordinate(instance: str) -> tuple[float, float] | None:
    match = re.search(r"@\((-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)\)$", instance)
    return (float(match.group(1)), float(match.group(2))) if match else None


def hierarchy_root(instance: str) -> str | None:
    path = instance.split(" @(", 1)[0]
    parts = path.split("/")
    return "/".join(parts[:2]) if len(parts) >= 3 else None


def main() -> int:
    args = parse_args()
    expected_instances = tuple(args.expected_ro_instance or DEFAULT_RO_INSTANCES)
    failures: list[str] = []

    if not args.cls.is_file() or args.cls.stat().st_size == 0:
        failures.append(f"CLS report is missing or empty: {args.cls}")
        raw_bytes = b""
        text = ""
    else:
        raw_bytes = args.cls.read_bytes()
        text = raw_bytes.decode("utf-8", errors="replace")

    lines = text.splitlines()
    records = parse_records(lines)
    run_result = report_scalar(text, "#####  Run Result")
    cells_mismatch = report_scalar(text, "Cells which mismatch")
    blackboxed = report_scalar(text, "Cells that have been blackboxed")
    total = parse_four_column_row(text, "Total")
    pins_unmatched = parse_unmatched_pair(text, "Pins")
    nets_unmatched = parse_unmatched_pair(text, "Nets")

    top_match = re.search(
        r"^mptdc_axis_core\s*\|\s*59\s*:\s*59\s*\|\s*59\s*:\s*59"
        r"\s*\|\s*mismatch\b",
        text,
        re.MULTILINE,
    )
    all_markers = Counter(kind for kind, _ in re.findall(r"\((mi|mn|so|mp)\s+(\d+)\)", text))

    source_only = [
        record
        for record in records
        if record.layout_instance == "** missing inst **"
        and record.schematic_instance != "** missing inst **"
    ]
    layout_only = [
        record
        for record in records
        if record.schematic_instance == "** missing inst **"
        and record.layout_instance != "** missing inst **"
    ]
    other_records = [
        record for record in records if record not in source_only and record not in layout_only
    ]

    source_instance_set = tuple(sorted(record.schematic_instance for record in source_only))
    expected_instance_set = tuple(sorted(expected_instances))
    layout_models = Counter(record.layout_model for record in layout_only)
    roots = Counter(
        root for record in layout_only if (root := hierarchy_root(record.layout_instance)) is not None
    )
    coordinates = [coordinate(record.layout_instance) for record in layout_only]
    coordinate_status = all(value is not None for value in coordinates) and len(coordinates) == 380

    root_ranges: dict[str, tuple[float, float, float, float]] = {}
    if coordinate_status:
        for root in sorted(roots):
            points = [
                coordinate(record.layout_instance)
                for record in layout_only
                if hierarchy_root(record.layout_instance) == root
            ]
            typed_points = [point for point in points if point is not None]
            root_ranges[root] = (
                min(point[0] for point in typed_points),
                max(point[0] for point in typed_points),
                min(point[1] for point in typed_points),
                max(point[1] for point in typed_points),
            )

    cluster_status = False
    if set(root_ranges) == set(EXPECTED_ROOTS):
        south = root_ranges["X0/X0"]
        north = root_ranges["X3/X5127"]
        cluster_status = (
            abs(south[0] - north[0]) < 0.001
            and abs(south[1] - north[1]) < 0.001
            and south[3] < north[2]
            and north[2] - south[3] > 100.0
        )

    checks = (
        (run_result == "MISMATCH", f"Run Result is {run_result!r}, expected MISMATCH"),
        (cells_mismatch == "1", f"Cells which mismatch is {cells_mismatch!r}, expected 1"),
        (blackboxed == "0", f"blackboxed cell count is {blackboxed!r}, expected 0"),
        (top_match is not None, "top-cell 59:59 mismatch signature is missing"),
        (total == EXPECTED_TOTAL, f"total signature is {total!r}, expected {EXPECTED_TOTAL!r}"),
        (pins_unmatched == (0, 0), f"unmatched pin pair is {pins_unmatched!r}, expected (0, 0)"),
        (nets_unmatched == (0, 0), f"unmatched net pair is {nets_unmatched!r}, expected (0, 0)"),
        (
            all_markers == Counter({"mi": 382}),
            f"mismatch marker signature is {dict(all_markers)!r}, expected mi:382 only",
        ),
        (len(records) == 382, f"parsed mismatch record count is {len(records)}, expected 382"),
        (
            [record.marker for record in records] == list(range(1, 383)),
            "mismatch instance markers are not the contiguous range 1..382",
        ),
        (len(source_only) == 2, f"source-only instance count is {len(source_only)}, expected 2"),
        (
            source_instance_set == expected_instance_set,
            f"source-only instance set is {source_instance_set!r}, expected {expected_instance_set!r}",
        ),
        (
            all(record.schematic_model == "RO_tune6" and not record.layout_model for record in source_only),
            "source-only records are not exactly RO_tune6 models",
        ),
        (len(layout_only) == 380, f"layout-only instance count is {len(layout_only)}, expected 380"),
        (not other_records, f"found {len(other_records)} non-source-only/non-layout-only records"),
        (
            layout_models == EXPECTED_LAYOUT_MODELS,
            f"layout-only model signature is {dict(layout_models)!r}",
        ),
        (roots == EXPECTED_ROOTS, f"layout hierarchy roots are {dict(roots)!r}"),
        (coordinate_status, "one or more layout-only instances lacks an extraction coordinate"),
        (cluster_status, f"RO coordinate clusters are not attributable: {root_ranges!r}"),
    )
    failures.extend(message for passed, message in checks if not passed)

    status = "PASS" if not failures else "FAIL"
    attribution = "EXACT_TWO_RO6_INTERNALS_ONLY" if not failures else "REJECTED"
    eligible = "YES" if not failures else "NO"
    model_signature = ",".join(
        f"{model}:{count}" for model, count in sorted(layout_models.items())
    )
    root_signature = ",".join(f"{root}:{count}" for root, count in sorted(roots.items()))

    report_lines = [
        "STEP=MPTDC_RO6_RAW_LVS_MISMATCH_CLASSIFICATION",
        f"STATUS={status}",
        f"CLS={args.cls}",
        f"CLS_SHA256={hashlib.sha256(raw_bytes).hexdigest() if raw_bytes else 'MISSING'}",
        f"CLS_RUN_RESULT={run_result or 'MISSING'}",
        f"CELLS_WHICH_MISMATCH={cells_mismatch or 'MISSING'}",
        f"BLACKBOXED_CELL_COUNT={blackboxed or 'MISSING'}",
        f"TOTAL_SIGNATURE_STATUS={'PASS' if total == EXPECTED_TOTAL else 'FAIL'}",
        f"MISMATCH_MARKER_SIGNATURE={'mi:382,mn:0,so:0,mp:0' if all_markers == Counter({'mi': 382}) else dict(all_markers)}",
        f"SOURCE_ONLY_INSTANCE_COUNT={len(source_only)}",
        f"RO_SOURCE_INSTANCE_SET={','.join(source_instance_set) or 'NONE'}",
        f"LAYOUT_ONLY_INSTANCE_COUNT={len(layout_only)}",
        f"LAYOUT_ONLY_MODEL_SIGNATURE={model_signature}",
        f"RO_LAYOUT_ROOT_SIGNATURE={root_signature}",
        f"RO_LAYOUT_CLUSTER_COUNT={len(roots)}",
        f"RO_CLUSTER_COORDINATE_STATUS={'PASS' if cluster_status else 'FAIL'}",
        f"MISMATCH_ATTRIBUTION={attribution}",
        f"DIRECT_MONOLITHIC_ELIGIBLE={eligible}",
        f"HIERARCHICAL_COMPOSITION_ELIGIBLE={eligible}",
        f"FAILURE_COUNT={len(failures)}",
    ]
    report_lines.extend(f"ERROR_{index}={message}" for index, message in enumerate(failures, 1))
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text("\n".join(report_lines) + "\n", encoding="utf-8")

    print(f"RAW_LVS_MISMATCH_CLASSIFICATION_STATUS={status}")
    print(f"MISMATCH_ATTRIBUTION={attribution}")
    print(f"DIRECT_MONOLITHIC_ELIGIBLE={eligible}")
    print(f"HIERARCHICAL_COMPOSITION_ELIGIBLE={eligible}")
    return 0 if not failures else 10


if __name__ == "__main__":
    sys.exit(main())
