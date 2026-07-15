#!/usr/bin/env python3
"""Classify the isolated iterative TX minimum-area repair trial."""

from __future__ import annotations

import argparse
import csv
import hashlib
import re
from pathlib import Path


def key_values(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    if not path.is_file():
        return values
    for line in path.read_text(errors="replace").splitlines():
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key] = value
    return values


def read_tsv(path: Path) -> list[dict[str, str]]:
    if not path.is_file():
        return []
    with path.open(newline="", errors="replace") as handle:
        return list(csv.DictReader(handle, delimiter="\t"))


def digest(path: Path) -> str:
    sha = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            sha.update(chunk)
    return sha.hexdigest()


def report_violation_count(path: Path) -> int | None:
    if not path.is_file():
        return None
    text = path.read_text(errors="replace")
    counts = {
        int(value)
        for pattern in (
            r"Verification Complete\s*:\s*([0-9]+)\s+Viol",
            r"([0-9]+)\s+Problem\(s\)\s+\(IMPVFC-200\):\s+Special Wires:",
        )
        for value in re.findall(pattern, text, re.IGNORECASE)
    }
    return counts.pop() if len(counts) == 1 else None


def integer(values: dict[str, str], key: str, errors: list[str]) -> int | None:
    value = values.get(key)
    if value is None or not re.fullmatch(r"[0-9]+", value):
        errors.append(f"invalid_or_missing_{key}={value if value is not None else 'MISSING'}")
        return None
    return int(value)


def is_min_area(row: dict[str, str]) -> bool:
    text = " ".join(
        row.get(key, "") for key in ("layer", "type", "subType", "message")
    )
    return (
        row.get("layer", "").upper() == "MET1"
        and row.get("type", "").lower() == "geometry"
        and re.search(r"minimal_area|minimum\s+area|\bmar\b", text, re.IGNORECASE)
        is not None
    )


def marker_net(row: dict[str, str]) -> str:
    match = re.search(
        r"Regular\s+Wire\s+of\s+Net\s+([^\s]+)",
        row.get("message", ""),
        re.IGNORECASE,
    )
    return match.group(1) if match else "UNKNOWN"


def classify(
    trial_root: Path,
    step17_analysis: Path,
    report_driver_head: str,
    report: Path,
) -> dict[str, str]:
    reports = trial_root / "reports"
    context_path = trial_root / "context.rpt"
    status_path = reports / "min_area_second_pass_trial_status.rpt"
    commands_path = reports / "min_area_second_pass_trial_commands.rpt"
    pre_markers_path = reports / "drc_markers_pre_trial.tsv"
    pre_drc_path = reports / "verify_drc_pre_trial.rpt"
    pre_regular_path = reports / "verify_connectivity_regular_pre_trial.rpt"
    pre_special_path = reports / "verify_connectivity_special_pre_trial.rpt"

    context = key_values(context_path)
    status = key_values(status_path)
    step17 = key_values(step17_analysis)
    errors: list[str] = []

    final_markers_text = status.get("FINAL_DRC_MARKER_REPORT", "")
    final_drc_text = status.get("FINAL_DRC_REPORT", "")
    final_regular_text = status.get("FINAL_REGULAR_CONNECTIVITY_REPORT", "")
    final_special_text = status.get("FINAL_SPECIAL_CONNECTIVITY_REPORT", "")
    final_markers_path = Path(final_markers_text) if final_markers_text else Path()
    final_drc_path = Path(final_drc_text) if final_drc_text else Path()
    final_regular_path = Path(final_regular_text) if final_regular_text else Path()
    final_special_path = Path(final_special_text) if final_special_text else Path()

    required = [
        context_path,
        status_path,
        commands_path,
        pre_markers_path,
        pre_drc_path,
        pre_regular_path,
        pre_special_path,
        step17_analysis,
    ]
    if final_markers_text:
        required.append(final_markers_path)
    if final_drc_text:
        required.append(final_drc_path)
    if final_regular_text:
        required.append(final_regular_path)
    if final_special_text:
        required.append(final_special_path)
    for path in required:
        if not path.is_file():
            errors.append(f"missing_required_artifact={path}")

    expected_step17 = {
        "STATUS": "PASS",
        "RESULT": "BLOCKERS_CLASSIFIED",
        "PHYSICAL_CANDIDATE_STATUS": "PG_AND_REGULAR_CLOSED_FINAL_REPAIR_REQUIRED",
        "FINAL_DRC_STATUS": "FAIL",
        "REGULAR_CONNECTIVITY_STATUS": "PASS",
        "PG_CONNECTIVITY_STATUS": "PASS",
        "PG_PROBLEM_COUNT": "0",
        "MIN_AREA_REPAIR_EFFECT": "REDUCED_10_TO_6",
        "MIN_AREA_PRE_MARKER_COUNT": "10",
        "MIN_AREA_POST_MARKER_COUNT": "6",
        "MIN_AREA_FINAL_MARKER_COUNT": "6",
        "ANTENNA_FINAL_MARKER_COUNT": "177",
        "STREAM_PIN_TARGET_STATUS": "CANONICAL_TARGETS_PRESERVED",
        "STREAM_PIN_COMMAND_MAPPING_DECISION": (
            "REMOVE_NEGATIVE_COMPENSATION_KEEP_CANONICAL_CENTERS"
        ),
        "PVS_DECISION": "DO_NOT_RUN",
    }
    for key, expected in expected_step17.items():
        if step17.get(key) != expected:
            errors.append(f"step17_{key}={step17.get(key, 'MISSING')} expected={expected}")

    if context.get("HEAD") != report_driver_head:
        errors.append(
            f"context_HEAD={context.get('HEAD', 'MISSING')} expected={report_driver_head}"
        )
    if context.get("POLICY") != "ONE_FRESH_PROCESS_ONE_RESTORE_IN_MEMORY_TRIAL":
        errors.append(f"context_POLICY={context.get('POLICY', 'MISSING')}")
    if context.get("ITERATION_LIMIT") != "3":
        errors.append(
            f"context_ITERATION_LIMIT={context.get('ITERATION_LIMIT', 'MISSING')}"
        )
    context_analysis = context.get("STEP17_ANALYSIS", "")
    if not context_analysis or Path(context_analysis).resolve() != step17_analysis:
        errors.append(
            f"context_STEP17_ANALYSIS={context_analysis or 'MISSING'} "
            f"expected={step17_analysis}"
        )
    for key in ("SOURCE_CHECKPOINT_WRITE", "SAVE_DESIGN", "EXPORT"):
        if context.get(key) != "NOT_RUN":
            errors.append(f"context_{key}={context.get(key, 'MISSING')}")

    expected_status = {
        "POLICY": "ONE_FRESH_PROCESS_ONE_RESTORE_IN_MEMORY_TRIAL",
        "DESIGN_MODIFICATION": "IN_MEMORY_ONLY",
        "SOURCE_CHECKPOINT_WRITE": "NOT_RUN",
        "SAVE_DESIGN": "NOT_RUN",
        "EXPORT": "NOT_RUN",
        "RESTORE_DESIGN": "PASS",
        "ITERATION_LIMIT": "3",
    }
    for key, expected in expected_status.items():
        if status.get(key) != expected:
            errors.append(f"trial_{key}={status.get(key, 'MISSING')} expected={expected}")
    status_analysis = status.get("STEP17_ANALYSIS", "")
    if not status_analysis or Path(status_analysis).resolve() != step17_analysis:
        errors.append(
            f"trial_STEP17_ANALYSIS={status_analysis or 'MISSING'} "
            f"expected={step17_analysis}"
        )
    if status.get("SOURCE_CHECKPOINT") != context.get("SOURCE_CHECKPOINT"):
        errors.append(
            "source_checkpoint_mismatch="
            f"{status.get('SOURCE_CHECKPOINT', 'MISSING')},"
            f"{context.get('SOURCE_CHECKPOINT', 'MISSING')}"
        )

    pre_drc = integer(status, "PRE_DRC_VIOLATION_COUNT", errors)
    pre_regular = integer(status, "PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT", errors)
    pre_special = integer(status, "PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT", errors)
    pre_markers = integer(status, "PRE_DRC_MARKER_COUNT", errors)
    pre_antenna = integer(status, "PRE_EXCLUDED_ANTENNA_MARKER_COUNT", errors)
    pre_database_total = integer(status, "PRE_MARKER_DATABASE_TOTAL", errors)
    pre_connectivity_markers = integer(
        status, "PRE_EXCLUDED_CONNECTIVITY_MARKER_COUNT", errors
    )
    final_drc = integer(status, "FINAL_DRC_VIOLATION_COUNT", errors)
    final_regular = integer(status, "FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT", errors)
    final_special = integer(status, "FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT", errors)
    final_markers = integer(status, "FINAL_DRC_MARKER_COUNT", errors)
    final_antenna = integer(status, "FINAL_EXCLUDED_ANTENNA_MARKER_COUNT", errors)
    final_database_total = integer(status, "FINAL_MARKER_DATABASE_TOTAL", errors)
    final_connectivity_markers = integer(
        status, "FINAL_EXCLUDED_CONNECTIVITY_MARKER_COUNT", errors
    )
    iteration_count = integer(status, "ITERATION_COUNT", errors)
    command_pass_count = integer(status, "COMMAND_PASS_COUNT", errors)
    command_fail_count = integer(status, "COMMAND_FAIL_COUNT", errors)

    report_count_pairs = (
        ("pre_drc", pre_drc_path, pre_drc),
        ("pre_regular", pre_regular_path, pre_regular),
        ("pre_special", pre_special_path, pre_special),
        ("final_drc", final_drc_path, final_drc),
        ("final_regular", final_regular_path, final_regular),
        ("final_special", final_special_path, final_special),
    )
    for label, path, status_count in report_count_pairs:
        report_count = report_violation_count(path)
        if report_count is None:
            errors.append(f"unparseable_{label}_report={path}")
        elif status_count is not None and report_count != status_count:
            errors.append(
                f"{label}_report_status_mismatch={report_count},{status_count}"
            )

    if (pre_drc, pre_regular, pre_special, pre_markers, pre_antenna) != (6, 0, 0, 6, 177):
        errors.append(
            "baseline_tuple="
            f"{pre_drc},{pre_regular},{pre_special},{pre_markers},{pre_antenna}"
        )
    if final_regular != 0 or final_special != 0:
        errors.append(f"final_connectivity_tuple={final_regular},{final_special}")
    if final_drc is not None and final_markers is not None and final_drc != final_markers:
        errors.append(f"final_drc_marker_mismatch={final_drc},{final_markers}")
    if final_antenna != 177:
        errors.append(f"final_antenna_count={final_antenna}")
    if pre_connectivity_markers != 0 or final_connectivity_markers != 0:
        errors.append(
            "excluded_connectivity_marker_tuple="
            f"{pre_connectivity_markers},{final_connectivity_markers}"
        )
    if (
        pre_database_total is not None
        and pre_markers is not None
        and pre_antenna is not None
        and pre_connectivity_markers is not None
        and pre_database_total
        != pre_markers + pre_antenna + pre_connectivity_markers
    ):
        errors.append("pre_marker_database_filter_accounting_mismatch")
    if (
        final_database_total is not None
        and final_markers is not None
        and final_antenna is not None
        and final_connectivity_markers is not None
        and final_database_total
        != final_markers + final_antenna + final_connectivity_markers
    ):
        errors.append("final_marker_database_filter_accounting_mismatch")
    if command_pass_count is not None and command_pass_count <= 0:
        errors.append(f"command_pass_count={command_pass_count}")
    if command_fail_count != 0:
        errors.append(f"command_fail_count={command_fail_count}")
    if iteration_count is not None and not 1 <= iteration_count <= 3:
        errors.append(f"iteration_count_out_of_range={iteration_count}")

    sequence: list[int] = []
    sequence_text = status.get("DRC_COUNT_SEQUENCE", "")
    if sequence_text:
        try:
            sequence = [int(value) for value in sequence_text.split()]
        except ValueError:
            errors.append(f"invalid_DRC_COUNT_SEQUENCE={sequence_text}")
    else:
        errors.append("missing_DRC_COUNT_SEQUENCE")
    if sequence and (sequence[0] != 6 or final_drc is None or sequence[-1] != final_drc):
        errors.append(f"inconsistent_DRC_COUNT_SEQUENCE={sequence_text}")
    if iteration_count is not None and len(sequence) != iteration_count + 1:
        errors.append(
            f"sequence_length={len(sequence)} expected={iteration_count + 1}"
        )
    if any(after > before for before, after in zip(sequence, sequence[1:])):
        errors.append(f"increasing_DRC_COUNT_SEQUENCE={sequence_text}")

    process_pair = (status.get("STATUS"), status.get("RESULT"))
    allowed_process_pairs = {
        ("PASS", "ITERATIVE_MIN_AREA_REPAIR_VALIDATED"),
        ("FAIL", "ITERATIVE_MIN_AREA_REPAIR_NO_IMPROVEMENT"),
        ("FAIL", "ITERATIVE_MIN_AREA_REPAIR_REDUCED_NOT_CLOSED"),
    }
    if process_pair not in allowed_process_pairs:
        errors.append(
            "unexpected_trial_process_pair="
            f"{process_pair[0] or 'MISSING'},{process_pair[1] or 'MISSING'}"
        )

    pre_rows = read_tsv(pre_markers_path)
    final_rows = read_tsv(final_markers_path) if final_markers_text else []
    if len(pre_rows) != 6 or any(not is_min_area(row) for row in pre_rows):
        errors.append("pre_marker_table_not_six_met1_min_area_rows")
    if final_markers is not None and len(final_rows) != final_markers:
        errors.append(f"final_marker_table_count={len(final_rows)} expected={final_markers}")
    if any(not is_min_area(row) for row in final_rows):
        errors.append("final_marker_table_contains_non_min_area_rows")

    expected_nets = sorted(step17.get("MIN_AREA_FINAL_NETS", "").split())
    pre_nets = sorted({marker_net(row) for row in pre_rows})
    final_nets = sorted({marker_net(row) for row in final_rows})
    if pre_nets != expected_nets:
        errors.append(f"pre_nets={' '.join(pre_nets)} expected={' '.join(expected_nets)}")

    method_validated = (
        not errors
        and status.get("STATUS") == "PASS"
        and status.get("RESULT") == "ITERATIVE_MIN_AREA_REPAIR_VALIDATED"
        and final_drc == 0
    )
    if method_validated:
        method_status = "VALIDATED_ZERO_DRC_ZERO_CONNECTIVITY"
        next_decision = "AUTHORIZE_FRESH_RERUN_WITH_ITERATIVE_REPAIR_AND_ZERO_PIN_COMPENSATION"
    else:
        method_status = "REJECTED_OR_INCOMPLETE"
        next_decision = "STOP_AND_REVIEW_ITERATION_EVIDENCE_BEFORE_NEW_REPAIR_METHOD"

    analysis_status = "PASS" if not errors else "FAIL"
    values = {
        "LABEL": "SPADMIC_TX_PACKET_MIN_AREA_SECOND_PASS_ANALYSIS",
        "POLICY": "READ_ONLY_ISOLATED_TRIAL_ARTIFACT_CLASSIFICATION",
        "STATUS": analysis_status,
        "RESULT": (
            "ITERATIVE_MIN_AREA_TRIAL_CLASSIFIED"
            if not errors
            else "ITERATIVE_MIN_AREA_TRIAL_CLASSIFICATION_INCOMPLETE"
        ),
        "TRIAL_ROOT": str(trial_root),
        "SOURCE_CHECKPOINT": context.get("SOURCE_CHECKPOINT", "MISSING"),
        "REPORT_DRIVER_HEAD": report_driver_head,
        "TRIAL_PROCESS_STATUS": status.get("STATUS", "MISSING"),
        "TRIAL_PROCESS_RESULT": status.get("RESULT", "MISSING"),
        "METHOD_STATUS": method_status,
        "PRE_DRC_VIOLATION_COUNT": str(pre_drc) if pre_drc is not None else "UNKNOWN",
        "FINAL_DRC_VIOLATION_COUNT": str(final_drc) if final_drc is not None else "UNKNOWN",
        "DRC_COUNT_SEQUENCE": sequence_text or "UNKNOWN",
        "ITERATION_COUNT": str(iteration_count) if iteration_count is not None else "UNKNOWN",
        "PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT": str(pre_regular) if pre_regular is not None else "UNKNOWN",
        "FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT": str(final_regular) if final_regular is not None else "UNKNOWN",
        "PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": str(pre_special) if pre_special is not None else "UNKNOWN",
        "FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT": str(final_special) if final_special is not None else "UNKNOWN",
        "PRE_EXCLUDED_ANTENNA_MARKER_COUNT": str(pre_antenna) if pre_antenna is not None else "UNKNOWN",
        "FINAL_EXCLUDED_ANTENNA_MARKER_COUNT": str(final_antenna) if final_antenna is not None else "UNKNOWN",
        "PRE_MARKER_DATABASE_TOTAL": str(pre_database_total) if pre_database_total is not None else "UNKNOWN",
        "FINAL_MARKER_DATABASE_TOTAL": str(final_database_total) if final_database_total is not None else "UNKNOWN",
        "COMMAND_PASS_COUNT": str(command_pass_count) if command_pass_count is not None else "UNKNOWN",
        "COMMAND_FAIL_COUNT": str(command_fail_count) if command_fail_count is not None else "UNKNOWN",
        "PRE_MIN_AREA_NETS": " ".join(pre_nets) if pre_nets else "NONE",
        "FINAL_MIN_AREA_NETS": " ".join(final_nets) if final_nets else "NONE",
        "NEXT_METHOD_DECISION": next_decision,
        "SAVE_DESIGN": "NOT_RUN",
        "EXPORT": "NOT_RUN",
        "PVS_DECISION": "DO_NOT_RUN",
        "ERROR_COUNT": str(len(errors)),
    }

    lines = [f"{key}={value}" for key, value in values.items()]
    lines.extend(["", "FINAL_MIN_AREA_MARKER_TABLE_BEGIN"])
    lines.append("net\tbox\tcx\tcy\tsubType\tmessage")
    for row in final_rows:
        lines.append(
            "\t".join(
                [
                    marker_net(row),
                    row.get("box", "UNKNOWN"),
                    row.get("cx", "UNKNOWN"),
                    row.get("cy", "UNKNOWN"),
                    row.get("subType", "UNKNOWN"),
                    row.get("message", "UNKNOWN"),
                ]
            )
        )
    lines.append("FINAL_MIN_AREA_MARKER_TABLE_END")
    lines.extend(["", "ERRORS_BEGIN", *(errors or ["NONE"]), "ERRORS_END"])
    lines.extend(["", "EVIDENCE_HASHES_BEGIN"])
    for path in required:
        if path.is_file():
            lines.append(f"{digest(path)}  {path}")
    lines.append("EVIDENCE_HASHES_END")

    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text("\n".join(lines) + "\n")
    return values


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--trial-root", required=True, type=Path)
    parser.add_argument("--step17-analysis", required=True, type=Path)
    parser.add_argument("--report-driver-head", required=True)
    parser.add_argument("--report", required=True, type=Path)
    args = parser.parse_args()
    values = classify(
        args.trial_root.resolve(),
        args.step17_analysis.resolve(),
        args.report_driver_head,
        args.report.resolve(),
    )
    print(args.report.read_text(), end="")
    if values["STATUS"] != "PASS":
        raise SystemExit(8)


if __name__ == "__main__":
    main()
