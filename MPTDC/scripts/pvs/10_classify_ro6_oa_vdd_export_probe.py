#!/usr/bin/env python3
"""Classify read-only OA terminal/label evidence for the missing RO6 VDD pin."""

from __future__ import annotations

import argparse
import csv
from pathlib import Path


EXPECTED_TERMINALS = {
    *(f"code<{index}>" for index in range(8)),
    *(f"S<{index}>" for index in range(8)),
    "rstb",
    "VDD",
    "VSS",
}
ALLOWED_EMPTY_GLOBAL_ALIASES = {"gnd!", "vdd!"}
GOLDEN_VDD_PIN_BOX = (-66.670, -71.560, -61.525, -68.325)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--cell-summary", required=True, type=Path)
    parser.add_argument("--terminal-figs", required=True, type=Path)
    parser.add_argument("--label-shapes", required=True, type=Path)
    parser.add_argument("--supply-nets", required=True, type=Path)
    parser.add_argument("--supply-shapes", required=True, type=Path)
    parser.add_argument("--candidate-shapes", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    return parser.parse_args()


def read_key_values(path: Path) -> dict[str, list[str]]:
    values: dict[str, list[str]] = {}
    for raw_line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if "=" not in raw_line:
            continue
        key, value = raw_line.split("=", 1)
        values.setdefault(key, []).append(value)
    return values


def read_tsv(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8", errors="replace", newline="") as stream:
        return list(csv.DictReader(stream, delimiter="\t"))


def lpp_set(rows: list[dict[str, str]]) -> str:
    values = {
        f"{row.get('layer', 'UNKNOWN')}:{row.get('purpose', 'UNKNOWN')}"
        for row in rows
        if row.get("obj_type") not in {None, "", "ABSENT"}
    }
    return ",".join(sorted(values)) if values else "NONE"


def box_set(rows: list[dict[str, str]]) -> str:
    values = {
        ",".join(
            row.get(field, "UNKNOWN") for field in ("llx", "lly", "urx", "ury")
        )
        for row in rows
        if row.get("obj_type") not in {None, "", "ABSENT"}
    }
    return ";".join(sorted(values)) if values else "NONE"


def main() -> int:
    args = parse_args()
    errors: list[str] = []
    try:
        summary = read_key_values(args.cell_summary)
        terminal_rows = read_tsv(args.terminal_figs)
        label_rows = read_tsv(args.label_shapes)
        supply_net_rows = read_tsv(args.supply_nets)
        supply_shape_rows = read_tsv(args.supply_shapes)
        candidate_shape_rows = read_tsv(args.candidate_shapes)
    except (OSError, csv.Error) as exc:
        summary = {}
        terminal_rows = []
        label_rows = []
        supply_net_rows = []
        supply_shape_rows = []
        candidate_shape_rows = []
        errors.append(f"PROBE_READ_FAILED:{exc}")

    summary_terminal_count = -1
    try:
        summary_terminal_count = int(summary.get("TERMINAL_COUNT", ["-1"])[-1])
    except ValueError:
        errors.append("INVALID_TERMINAL_COUNT")

    terminal_names = {
        row.get("terminal", "") for row in terminal_rows if row.get("terminal")
    }
    summary_terminal_names = set(summary.get("TERMINAL_NAME", []))
    unexpected_terminal_names = terminal_names - EXPECTED_TERMINALS
    unexpected_terminal_rows = [
        row
        for row in terminal_rows
        if row.get("terminal") in unexpected_terminal_names
    ]
    unexpected_terminal_fig_rows = [
        row
        for row in unexpected_terminal_rows
        if row.get("obj_type") not in {None, "", "ABSENT"}
    ]
    empty_global_aliases_safe = (
        unexpected_terminal_names <= ALLOWED_EMPTY_GLOBAL_ALIASES
        and not unexpected_terminal_fig_rows
    )
    vdd_rows = [row for row in terminal_rows if row.get("terminal") == "VDD"]
    vss_rows = [row for row in terminal_rows if row.get("terminal") == "VSS"]
    vdd_fig_rows = [row for row in vdd_rows if row.get("obj_type") != "ABSENT"]
    vss_fig_rows = [row for row in vss_rows if row.get("obj_type") != "ABSENT"]
    vdd_pin_count = len(
        {row["pin_index"] for row in vdd_rows if row.get("pin_index", "-1") != "-1"}
    )
    vss_pin_count = len(
        {row["pin_index"] for row in vss_rows if row.get("pin_index", "-1") != "-1"}
    )
    vdd_net_names = {row.get("net", "") for row in vdd_rows}
    vss_net_names = {row.get("net", "") for row in vss_rows}

    terminal_text_rows = [
        row
        for row in terminal_rows
        if row.get("text") not in {None, "", "ABSENT"}
    ]
    label_evidence_rows = label_rows + terminal_text_rows
    vdd_global_label_rows = [row for row in label_rows if row.get("text") == "VDD"]
    vss_global_label_rows = [row for row in label_rows if row.get("text") == "VSS"]
    vdd_pin_text_rows = [
        row for row in terminal_text_rows if row.get("text") == "VDD"
    ]
    vss_pin_text_rows = [
        row for row in terminal_text_rows if row.get("text") == "VSS"
    ]
    vdd_label_rows = vdd_global_label_rows + vdd_pin_text_rows
    vss_label_rows = vss_global_label_rows + vss_pin_text_rows
    vdd_like_label_rows = [
        row
        for row in label_evidence_rows
        if row.get("text", "").upper().rstrip("!").startswith(("VDD", "DVDD"))
    ]
    vss_like_label_rows = [
        row
        for row in label_evidence_rows
        if row.get("text", "").upper().rstrip("!").startswith(("VSS", "DVSS"))
    ]
    labelled_terminal_names = {
        row.get("text", "")
        for row in label_evidence_rows
        if row.get("text") in EXPECTED_TERMINALS
    }

    supply_net_names = {
        row.get("net", "") for row in supply_net_rows if row.get("net")
    }
    vdd_supply_shape_rows = [
        row
        for row in supply_shape_rows
        if row.get("net") == "VDD"
        and row.get("obj_type") not in {None, "", "ABSENT"}
    ]
    vss_supply_shape_rows = [
        row
        for row in supply_shape_rows
        if row.get("net") == "VSS"
        and row.get("obj_type") not in {None, "", "ABSENT"}
    ]
    vdd_candidate_shape_rows = [
        row
        for row in candidate_shape_rows
        if row.get("net") == "VDD"
        and row.get("obj_type") not in {None, "", "ABSENT"}
    ]

    checks = {
        "SUMMARY_TERMINAL_COUNT": summary_terminal_count == len(terminal_names),
        "SUMMARY_TERMINAL_NAMES": summary_terminal_names == terminal_names,
        "EXPECTED_TERMINAL_SUBSET": EXPECTED_TERMINALS <= terminal_names,
        "UNEXPECTED_TERMINALS_SAFE": empty_global_aliases_safe,
        "VDD_TERMINAL_NET": bool(vdd_rows) and vdd_net_names == {"VDD"},
        "VSS_TERMINAL_NET": bool(vss_rows) and vss_net_names == {"VSS"},
        "VSS_PIN_FIGURES": vss_pin_count > 0 and bool(vss_fig_rows),
        "SUPPLY_NET_INVENTORY": {"VDD", "VSS"} <= supply_net_names,
    }
    for name, passed in checks.items():
        if not passed:
            errors.append(f"CHECK_FAILED:{name}")

    terminal_contract_pass = (
        EXPECTED_TERMINALS <= terminal_names
        and empty_global_aliases_safe
        and vdd_pin_count > 0
        and bool(vdd_fig_rows)
        and vss_pin_count > 0
        and bool(vss_fig_rows)
    )

    if errors:
        diagnosis = "PROBE_INCOMPLETE_OR_OA_TERMINAL_CONTRACT_INVALID"
        next_action = "STOP_AND_REVIEW_OA_PROBE_EVIDENCE"
    elif terminal_contract_pass and vdd_label_rows:
        diagnosis = "VDD_PIN_LABEL_CONTRACT_PRESENT"
        next_action = "EXPORT_FRESH_RO6_GDS_AND_RERUN_STANDALONE_LVS"
    elif not vdd_fig_rows and not vdd_label_rows and vdd_candidate_shape_rows:
        diagnosis = "VDD_PIN_AND_LABEL_MISSING_ON_PROVEN_VDD_GEOMETRY"
        next_action = "REVIEW_ONE_HASH_GUARDED_VDD_PIN_LABEL_REPAIR"
    elif not vdd_fig_rows and not vdd_label_rows and vdd_supply_shape_rows:
        diagnosis = "VDD_PIN_AND_LABEL_MISSING_WITH_VDD_NET_GEOMETRY"
        next_action = "REVIEW_VDD_SHAPE_FOR_ONE_HASH_GUARDED_PIN_LABEL_REPAIR"
    elif not vdd_fig_rows and not vdd_label_rows:
        diagnosis = "VDD_PIN_AND_LABEL_MISSING_GEOMETRY_UNRESOLVED"
        next_action = "STOP_AND_REVIEW_VDD_NET_GEOMETRY"
    elif not vdd_fig_rows:
        diagnosis = "VDD_PIN_FIGURE_MISSING"
        next_action = "REVIEW_ONE_HASH_GUARDED_VDD_PIN_FIGURE_REPAIR"
    elif not vdd_label_rows and vdd_like_label_rows:
        diagnosis = "VDD_LABEL_TEXT_NOT_EXACT"
        next_action = "REVIEW_ONE_VDD_LABEL_NAME_OR_NET_CONTRACT_REPAIR"
    elif not vdd_label_rows and vss_label_rows:
        diagnosis = "VDD_EXPLICIT_LABEL_ABSENT_WHILE_VSS_LABEL_PRESENT"
        next_action = "REVIEW_ONE_VDD_LABEL_CONTRACT_REPAIR"
    elif not vdd_label_rows and not vss_label_rows:
        diagnosis = "NO_EXPLICIT_SUPPLY_LABELS_COMPARE_TERMINAL_EXPORT_MAPPING"
        next_action = "REVIEW_TERMINAL_TO_GDS_LABEL_EXPORT_MAPPING"
    elif vdd_label_rows:
        diagnosis = "VDD_LABEL_PRESENT_COMPARE_LPP_AND_NET_ATTACHMENT"
        next_action = "REVIEW_RUN_LOCAL_STREAM_EXPORT_MAPPING"
    else:
        diagnosis = "UNCLASSIFIED"
        next_action = "STOP_AND_REVIEW_OA_PROBE_EVIDENCE"

    status = "PASS" if not errors else "FAIL"
    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w", encoding="utf-8") as report:
        report.write("STEP=RO6_OA_VDD_EXPORT_CLASSIFICATION\n")
        report.write(f"OA_SUMMARY_TERMINAL_COUNT={summary_terminal_count}\n")
        report.write(f"OA_TERMINAL_NAME_COUNT={len(terminal_names)}\n")
        report.write(
            "OA_TERMINAL_NAME_SET="
            f"{','.join(sorted(terminal_names)) if terminal_names else 'NONE'}\n"
        )
        report.write(
            "OA_EXPECTED_TERMINAL_SET_STATUS="
            f"{'PASS' if terminal_names == EXPECTED_TERMINALS else 'FAIL'}\n"
        )
        report.write(
            "OA_EXPECTED_TERMINAL_SUBSET_STATUS="
            f"{'PASS' if EXPECTED_TERMINALS <= terminal_names else 'FAIL'}\n"
        )
        report.write(
            f"OA_UNEXPECTED_TERMINAL_COUNT={len(unexpected_terminal_names)}\n"
        )
        report.write(
            "OA_UNEXPECTED_TERMINAL_SET="
            f"{','.join(sorted(unexpected_terminal_names)) if unexpected_terminal_names else 'NONE'}\n"
        )
        report.write(
            "OA_EMPTY_GLOBAL_ALIAS_STATUS="
            f"{'PASS' if empty_global_aliases_safe else 'FAIL'}\n"
        )
        report.write(
            "OA_TERMINAL_CONTRACT_STATUS="
            f"{'PASS' if terminal_contract_pass else 'FAIL'}\n"
        )
        report.write(f"OA_VDD_TERMINAL_COUNT={1 if vdd_rows else 0}\n")
        report.write(f"OA_VDD_PIN_COUNT={vdd_pin_count}\n")
        report.write(f"OA_VDD_PIN_FIG_COUNT={len(vdd_fig_rows)}\n")
        report.write(f"OA_VDD_NET_SET={','.join(sorted(vdd_net_names)) or 'NONE'}\n")
        report.write(f"OA_VDD_PIN_LPP_SET={lpp_set(vdd_fig_rows)}\n")
        report.write(f"OA_VDD_PIN_BOX_SET={box_set(vdd_fig_rows)}\n")
        report.write(f"OA_VDD_EXPLICIT_LABEL_COUNT={len(vdd_label_rows)}\n")
        report.write(
            f"OA_VDD_GLOBAL_LABEL_SHAPE_COUNT={len(vdd_global_label_rows)}\n"
        )
        report.write(f"OA_VDD_PIN_FIG_TEXT_COUNT={len(vdd_pin_text_rows)}\n")
        report.write(f"OA_VDD_LABEL_LPP_SET={lpp_set(vdd_label_rows)}\n")
        report.write(f"OA_VDD_LABEL_BOX_SET={box_set(vdd_label_rows)}\n")
        report.write(f"OA_VDD_LIKE_LABEL_COUNT={len(vdd_like_label_rows)}\n")
        report.write(
            "OA_VDD_LIKE_LABEL_TEXT_SET="
            f"{','.join(sorted({row.get('text', '') for row in vdd_like_label_rows})) if vdd_like_label_rows else 'NONE'}\n"
        )
        report.write(f"OA_VDD_LIKE_LABEL_LPP_SET={lpp_set(vdd_like_label_rows)}\n")
        report.write(f"OA_VSS_TERMINAL_COUNT={1 if vss_rows else 0}\n")
        report.write(f"OA_VSS_PIN_COUNT={vss_pin_count}\n")
        report.write(f"OA_VSS_PIN_FIG_COUNT={len(vss_fig_rows)}\n")
        report.write(f"OA_VSS_NET_SET={','.join(sorted(vss_net_names)) or 'NONE'}\n")
        report.write(f"OA_VSS_PIN_LPP_SET={lpp_set(vss_fig_rows)}\n")
        report.write(f"OA_VSS_PIN_BOX_SET={box_set(vss_fig_rows)}\n")
        report.write(f"OA_VSS_EXPLICIT_LABEL_COUNT={len(vss_label_rows)}\n")
        report.write(
            f"OA_VSS_GLOBAL_LABEL_SHAPE_COUNT={len(vss_global_label_rows)}\n"
        )
        report.write(f"OA_VSS_PIN_FIG_TEXT_COUNT={len(vss_pin_text_rows)}\n")
        report.write(f"OA_VSS_LABEL_LPP_SET={lpp_set(vss_label_rows)}\n")
        report.write(f"OA_VSS_LABEL_BOX_SET={box_set(vss_label_rows)}\n")
        report.write(f"OA_VSS_LIKE_LABEL_COUNT={len(vss_like_label_rows)}\n")
        report.write(
            "OA_VSS_LIKE_LABEL_TEXT_SET="
            f"{','.join(sorted({row.get('text', '') for row in vss_like_label_rows})) if vss_like_label_rows else 'NONE'}\n"
        )
        report.write(
            "OA_EXPLICIT_LABELLED_TERMINAL_COUNT="
            f"{len(labelled_terminal_names)}\n"
        )
        report.write(
            "OA_EXPLICIT_LABELLED_TERMINAL_SET="
            f"{','.join(sorted(labelled_terminal_names)) if labelled_terminal_names else 'NONE'}\n"
        )
        report.write(
            f"OA_VDD_NET_ASSOCIATED_SHAPE_COUNT={len(vdd_supply_shape_rows)}\n"
        )
        report.write(
            f"OA_VDD_NET_ASSOCIATED_SHAPE_LPP_SET={lpp_set(vdd_supply_shape_rows)}\n"
        )
        report.write(
            f"OA_VDD_NET_ASSOCIATED_SHAPE_BOX_SET={box_set(vdd_supply_shape_rows)}\n"
        )
        report.write(
            f"OA_VSS_NET_ASSOCIATED_SHAPE_COUNT={len(vss_supply_shape_rows)}\n"
        )
        report.write(
            "OA_GOLDEN_VDD_PIN_BOX="
            f"{','.join(f'{value:.3f}' for value in GOLDEN_VDD_PIN_BOX)}\n"
        )
        report.write(
            f"OA_GOLDEN_VDD_PIN_OVERLAP_SHAPE_COUNT={len(candidate_shape_rows)}\n"
        )
        report.write(
            "OA_GOLDEN_VDD_PIN_OVERLAP_VDD_SHAPE_COUNT="
            f"{len(vdd_candidate_shape_rows)}\n"
        )
        report.write(f"OA_VDD_EXPORT_DIAGNOSIS={diagnosis}\n")
        report.write(f"OA_VDD_EXPORT_REVIEW_ACTION={next_action}\n")
        report.write(f"ERROR_COUNT={len(errors)}\n")
        for index, error in enumerate(errors, start=1):
            report.write(f"ERROR_{index}={error}\n")
        report.write(f"OA_PROBE_CLASSIFICATION_STATUS={status}\n")

    return 0 if status == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
