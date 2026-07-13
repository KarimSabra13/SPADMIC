#!/usr/bin/env python3
"""Compare pre/post DRC markers from an isolated TX packet PG via replay."""

from __future__ import annotations

import argparse
import csv
import hashlib
from collections import Counter
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Marker:
    post_index: str
    box: str
    llx: float
    lly: float
    urx: float
    ury: float
    layer: str
    marker_type: str
    subtype: str
    message: str

    @property
    def cx(self) -> float:
        return (self.llx + self.urx) / 2.0

    @property
    def cy(self) -> float:
        return (self.lly + self.ury) / 2.0

    @property
    def signature(self) -> tuple[object, ...]:
        return (
            round(self.llx, 6),
            round(self.lly, 6),
            round(self.urx, 6),
            round(self.ury, 6),
            self.layer,
            self.marker_type,
            self.subtype,
            self.message,
        )


def read_kv(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for raw in path.read_text(errors="replace").splitlines():
        if "=" not in raw:
            continue
        key, value = raw.split("=", 1)
        if key:
            values[key] = value
    return values


def parse_float(value: str) -> float:
    return float(value.strip())


def parse_markers(path: Path) -> list[Marker]:
    markers: list[Marker] = []
    with path.open(newline="", errors="replace") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        required = {
            "idx",
            "box",
            "llx",
            "lly",
            "urx",
            "ury",
            "layer",
            "type",
            "subType",
            "message",
        }
        if reader.fieldnames is None or not required.issubset(reader.fieldnames):
            raise ValueError(f"bad marker schema in {path}")
        for row in reader:
            try:
                markers.append(
                    Marker(
                        post_index=row["idx"],
                        box=row["box"],
                        llx=parse_float(row["llx"]),
                        lly=parse_float(row["lly"]),
                        urx=parse_float(row["urx"]),
                        ury=parse_float(row["ury"]),
                        layer=row["layer"],
                        marker_type=row["type"],
                        subtype=row["subType"],
                        message=row["message"],
                    )
                )
            except (KeyError, TypeError, ValueError) as error:
                raise ValueError(f"invalid marker row {row.get('idx', 'UNKNOWN')} in {path}: {error}") from error
    return markers


def counter_difference(left: list[Marker], right: list[Marker]) -> list[Marker]:
    remaining = Counter(marker.signature for marker in right)
    difference: list[Marker] = []
    for marker in left:
        if remaining[marker.signature] > 0:
            remaining[marker.signature] -= 1
        else:
            difference.append(marker)
    return difference


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def report_value(value: object) -> str:
    return str(value).replace("\t", " ").replace("\r", " ").replace("\n", " ")


def int_field(values: dict[str, str], key: str, errors: list[str]) -> int | None:
    raw = values.get(key)
    if raw is None:
        errors.append(f"{key}=MISSING is not an integer")
        return None
    try:
        return int(raw)
    except ValueError:
        errors.append(f"{key}={raw} is not an integer")
        return None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--trial-root", type=Path, required=True)
    parser.add_argument("--analysis-report", type=Path, required=True)
    parser.add_argument("--reference-status", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()

    reports = args.trial_root / "reports"
    trial_status_path = reports / "pg_via_trial_status.rpt"
    pre_markers_path = reports / "drc_markers_pre_trial.tsv"
    post_markers_path = reports / "drc_markers_post_trial.tsv"
    required = (
        trial_status_path,
        pre_markers_path,
        post_markers_path,
        args.analysis_report,
        args.reference_status,
    )
    missing = [path for path in required if not path.is_file()]
    args.report.parent.mkdir(parents=True, exist_ok=True)
    if missing:
        args.report.write_text(
            "LABEL=SPADMIC_TX_PACKET_PG_VIA_DRC_ANALYSIS\n"
            "POLICY=READ_ONLY_TRIAL_ARTIFACT_COMPARISON\n"
            "STATUS=FAIL\n"
            "RESULT=MISSING_REQUIRED_INPUTS\n"
            f"MISSING_INPUTS={' '.join(str(path) for path in missing)}\n"
        )
        return 8

    errors: list[str] = []
    trial = read_kv(trial_status_path)
    reference = read_kv(args.reference_status)
    analysis = read_kv(args.analysis_report)
    try:
        pre_markers = parse_markers(pre_markers_path)
        post_markers = parse_markers(post_markers_path)
    except ValueError as error:
        errors.append(str(error))
        pre_markers = []
        post_markers = []

    expected_trial_fields = {
        "STATUS": "FAIL",
        "RESULT": "PG_VIA_METHOD_REJECTED",
        "MODE": "via-only",
        "RESTORE_DESIGN": "PASS",
        "DESIGN_MODIFICATION": "IN_MEMORY_ONLY",
        "SOURCE_CHECKPOINT_WRITE": "NOT_RUN",
        "SAVE_DESIGN": "NOT_RUN",
        "EXPORT": "NOT_RUN",
        "COMMAND_FAIL_COUNT": "0",
        "PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT": "0",
        "POST_REGULAR_CONNECTIVITY_VIOLATION_COUNT": "0",
        "POST_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": "0",
        "PRE_DRC_MARKER_DUMP_STATUS": "PASS",
        "POST_DRC_MARKER_DUMP_STATUS": "PASS",
    }
    for key, expected in expected_trial_fields.items():
        if trial.get(key) != expected:
            errors.append(f"trial_{key}={trial.get(key, 'MISSING')} expected={expected}")

    if reference.get("STATUS") != "FAIL" or reference.get("RESULT") != "PG_VIA_METHOD_REJECTED":
        errors.append("reference status is not the rejected via-only method")
    if not trial.get("SOURCE_CHECKPOINT") or not reference.get("SOURCE_CHECKPOINT"):
        errors.append("trial or reference source checkpoint is missing")

    if analysis.get("STATUS") != "PASS" or analysis.get("RESULT") != "VDD_ROW_COMPONENTS_CLASSIFIED":
        errors.append("topology analysis is not the accepted VDD row classification")

    integer_keys = (
        "TARGET_ROW_COUNT",
        "COMMAND_PASS_COUNT",
        "COMMAND_FAIL_COUNT",
        "PRE_DRC_VIOLATION_COUNT",
        "POST_DRC_VIOLATION_COUNT",
        "PRE_DRC_MARKER_COUNT",
        "POST_DRC_MARKER_COUNT",
        "PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT",
        "POST_REGULAR_CONNECTIVITY_VIOLATION_COUNT",
        "PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT",
        "POST_SPECIAL_CONNECTIVITY_VIOLATION_COUNT",
    )
    trial_counts = {key: int_field(trial, key, errors) for key in integer_keys}

    replay_fields = (
        "MODE",
        "SOURCE_CHECKPOINT",
        "TARGET_ROW_COUNT",
        "COMMAND_PASS_COUNT",
        "COMMAND_FAIL_COUNT",
        "PRE_DRC_VIOLATION_COUNT",
        "POST_DRC_VIOLATION_COUNT",
        "PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT",
        "POST_REGULAR_CONNECTIVITY_VIOLATION_COUNT",
        "PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT",
        "POST_SPECIAL_CONNECTIVITY_VIOLATION_COUNT",
    )
    replay_consistency = "PASS"
    for key in replay_fields:
        if reference.get(key) != trial.get(key):
            replay_consistency = "FAIL"
            errors.append(
                f"replay_{key}={trial.get(key, 'MISSING')} reference={reference.get(key, 'MISSING')}"
            )

    pre_drc = trial_counts["PRE_DRC_VIOLATION_COUNT"]
    post_drc = trial_counts["POST_DRC_VIOLATION_COUNT"]
    pre_dump_count = trial_counts["PRE_DRC_MARKER_COUNT"]
    post_dump_count = trial_counts["POST_DRC_MARKER_COUNT"]
    if pre_drc is not None and pre_dump_count != pre_drc:
        errors.append(f"pre marker count {pre_dump_count} does not match DRC count {pre_drc}")
    if post_drc is not None and post_dump_count != post_drc:
        errors.append(f"post marker count {post_dump_count} does not match DRC count {post_drc}")
    if pre_dump_count is not None and len(pre_markers) != pre_dump_count:
        errors.append(f"pre TSV rows {len(pre_markers)} do not match marker count {pre_dump_count}")
    if post_dump_count is not None and len(post_markers) != post_dump_count:
        errors.append(f"post TSV rows {len(post_markers)} do not match marker count {post_dump_count}")
    if pre_drc is not None and post_drc is not None and post_drc <= pre_drc:
        errors.append(f"expected rejected method to increase DRC: pre={pre_drc} post={post_drc}")

    new_markers = counter_difference(post_markers, pre_markers)
    removed_markers = counter_difference(pre_markers, post_markers)
    drc_delta = post_drc - pre_drc if pre_drc is not None and post_drc is not None else None
    if removed_markers:
        errors.append(f"baseline markers removed or changed: {len(removed_markers)}")
    if drc_delta is not None and len(new_markers) != drc_delta:
        errors.append(f"new marker count {len(new_markers)} does not match DRC delta {drc_delta}")

    row_count = trial_counts["TARGET_ROW_COUNT"] or 0
    row_centers: dict[int, float] = {}
    for row in range(1, row_count + 1):
        key = f"VDD_ROW_{row}_CENTER_Y_UM"
        raw = analysis.get(key)
        try:
            row_centers[row] = float(raw) if raw is not None else float("nan")
        except ValueError:
            errors.append(f"{key}={raw} is not numeric")
    if len(row_centers) != row_count or any(value != value for value in row_centers.values()):
        errors.append("missing row centers from topology analysis")

    layer_counts = Counter(marker.layer for marker in new_markers)
    class_counts = Counter((marker.layer, marker.subtype) for marker in new_markers)
    row_counts: Counter[int] = Counter()
    marker_rows: list[tuple[Marker, int, float]] = []
    for marker in new_markers:
        if row_centers:
            nearest_row = min(row_centers, key=lambda row: abs(marker.cy - row_centers[row]))
            distance = abs(marker.cy - row_centers[nearest_row])
            row_counts[nearest_row] += 1
        else:
            nearest_row = 0
            distance = float("nan")
        marker_rows.append((marker, nearest_row, distance))

    status = "PASS" if not errors else "FAIL"
    result = "DIRECT_STACK_DRC_MARKERS_CLASSIFIED" if not errors else "DRC_MARKER_CLASSIFICATION_INCOMPLETE"
    connectivity_status = (
        "PASS_ZERO_SPECIAL_AND_REGULAR"
        if trial.get("POST_SPECIAL_CONNECTIVITY_VIOLATION_COUNT") == "0"
        and trial.get("POST_REGULAR_CONNECTIVITY_VIOLATION_COUNT") == "0"
        else "FAIL"
    )
    drc_status = (
        "FAIL_NEW_MARKERS"
        if pre_drc is not None and post_drc is not None and post_drc > pre_drc
        else "UNKNOWN"
    )
    lines = [
        "LABEL=SPADMIC_TX_PACKET_PG_VIA_DRC_ANALYSIS",
        "POLICY=READ_ONLY_TRIAL_ARTIFACT_COMPARISON",
        f"STATUS={status}",
        f"RESULT={result}",
        f"TRIAL_ROOT={args.trial_root}",
        f"REFERENCE_STATUS={args.reference_status}",
        f"REFERENCE_REPLAY_COUNT_CONSISTENCY={replay_consistency}",
        f"DIRECT_STACK_CONNECTIVITY_STATUS={connectivity_status}",
        f"DIRECT_STACK_DRC_STATUS={drc_status}",
        f"PRE_DRC_MARKER_COUNT={len(pre_markers)}",
        f"POST_DRC_MARKER_COUNT={len(post_markers)}",
        f"DRC_MARKER_DELTA={drc_delta if drc_delta is not None else 'UNKNOWN'}",
        f"NEW_DRC_MARKER_COUNT={len(new_markers)}",
        f"REMOVED_BASELINE_MARKER_COUNT={len(removed_markers)}",
        "NEW_MARKER_LAYER_COUNTS="
        + (" ".join(f"{layer}:{layer_counts[layer]}" for layer in sorted(layer_counts)) or "NONE"),
        "NEW_MARKER_LAYER_SUBTYPE_COUNTS="
        + (
            " ".join(
                f"{layer}/{subtype}:{class_counts[(layer, subtype)]}"
                for layer, subtype in sorted(class_counts)
            )
            or "NONE"
        ),
    ]
    for row in range(1, row_count + 1):
        lines.append(f"NEW_MARKER_NEAREST_ROW_{row}_COUNT={row_counts[row]}")
    lines.extend(
        (
            "PATCH_STACK_DECISION=DO_NOT_RUN_INTERMEDIATE_LAYER_DRC_ALREADY_INTRODUCED",
            "CANONICAL_RERUN_DECISION=BLOCKED",
            "PVS_DECISION=DO_NOT_RUN",
            "NEXT_METHOD_DECISION=REVIEW_NEW_MARKER_TABLE_BEFORE_ANY_NEW_TRIAL",
            f"PRE_MARKERS_SHA256={sha256(pre_markers_path)}",
            f"POST_MARKERS_SHA256={sha256(post_markers_path)}",
            "NEW_DRC_MARKER_TABLE_BEGIN",
            "new_index\tpost_index\tlayer\ttype\tsubType\tbox\tcx\tcy\tnearest_row\trow_distance_um\tmessage",
        )
    )
    for new_index, (marker, nearest_row, distance) in enumerate(marker_rows, start=1):
        lines.append(
            "\t".join(
                (
                    str(new_index),
                    marker.post_index,
                    report_value(marker.layer),
                    report_value(marker.marker_type),
                    report_value(marker.subtype),
                    report_value(marker.box),
                    f"{marker.cx:.6f}",
                    f"{marker.cy:.6f}",
                    str(nearest_row) if nearest_row else "UNKNOWN",
                    f"{distance:.6f}" if distance == distance else "UNKNOWN",
                    report_value(marker.message),
                )
            )
        )
    lines.append("NEW_DRC_MARKER_TABLE_END")
    lines.append(f"ERROR_COUNT={len(errors)}")
    lines.extend(f"ERROR={report_value(error)}" for error in errors)
    args.report.write_text("\n".join(lines) + "\n")
    return 0 if not errors else 8


if __name__ == "__main__":
    raise SystemExit(main())
