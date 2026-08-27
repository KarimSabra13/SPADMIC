#!/usr/bin/env python3
"""Classify the one permitted RO_tune6 OA VDD pin/label repair."""

from __future__ import annotations

import argparse
import csv
import hashlib
from pathlib import Path


EXPECTED_TERMINALS = {
    *(f"S<{index}>" for index in range(8)),
    *(f"code<{index}>" for index in range(8)),
    "VDD",
    "VSS",
    "rstb",
}
ALLOWED_EMPTY_ALIASES = {"gnd!", "vdd!"}
TARGET_BOX = (-68.700, -31.950, -66.670, -30.115)
TARGET_LAYER = "METTP"
TARGET_PURPOSE = "pin"
TARGET_NET = "VDD"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--operator-gate", required=True, type=Path)
    parser.add_argument("--classification", required=True, type=Path)
    parser.add_argument("--cell-summary", required=True, type=Path)
    parser.add_argument("--terminal-figs", required=True, type=Path)
    parser.add_argument("--label-shapes", required=True, type=Path)
    parser.add_argument("--supply-nets", required=True, type=Path)
    parser.add_argument("--supply-shapes", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    return parser.parse_args()


def read_key_values(path: Path) -> tuple[dict[str, str], list[str]]:
    values: dict[str, str] = {}
    terminal_names: list[str] = []
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        if "=" not in raw_line:
            continue
        key, value = raw_line.split("=", 1)
        if key == "TERMINAL_NAME":
            terminal_names.append(value)
        else:
            values[key] = value
    return values, terminal_names


def read_tsv(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8", newline="") as stream:
        return list(csv.DictReader(stream, delimiter="\t"))


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def row_box(row: dict[str, str]) -> tuple[float, float, float, float] | None:
    try:
        return tuple(float(row[key]) for key in ("llx", "lly", "urx", "ury"))  # type: ignore[return-value]
    except (KeyError, TypeError, ValueError):
        return None


def same_box(
    box: tuple[float, float, float, float] | None,
    expected: tuple[float, float, float, float],
    tolerance: float = 1e-6,
) -> bool:
    return box is not None and all(
        abs(actual - wanted) <= tolerance
        for actual, wanted in zip(box, expected, strict=True)
    )


def main() -> int:
    args = parse_args()
    input_paths = (
        args.operator_gate,
        args.classification,
        args.cell_summary,
        args.terminal_figs,
        args.label_shapes,
        args.supply_nets,
        args.supply_shapes,
    )
    missing = [str(path) for path in input_paths if not path.is_file()]
    if missing:
        raise SystemExit(f"missing repair-contract input: {', '.join(missing)}")

    operator, _ = read_key_values(args.operator_gate)
    classification, _ = read_key_values(args.classification)
    summary, terminal_names_list = read_key_values(args.cell_summary)
    terminal_rows = read_tsv(args.terminal_figs)
    label_rows = read_tsv(args.label_shapes)
    supply_net_rows = read_tsv(args.supply_nets)
    supply_shape_rows = read_tsv(args.supply_shapes)

    terminal_names = set(terminal_names_list)
    unexpected = terminal_names - EXPECTED_TERMINALS
    vdd_terminal_rows = [row for row in terminal_rows if row.get("terminal") == "VDD"]
    vdd_pin_fig_rows = [
        row for row in vdd_terminal_rows if row.get("obj_type") not in {"", "ABSENT"}
    ]
    vss_terminal_rows = [row for row in terminal_rows if row.get("terminal") == "VSS"]
    alias_terminal_rows = [
        row for row in terminal_rows if row.get("terminal") in ALLOWED_EMPTY_ALIASES
    ]
    vdd_labels = [row for row in label_rows if row.get("text") == "VDD"]
    supply_net_names = {row.get("net", "") for row in supply_net_rows}

    target_rows = [
        row
        for row in supply_shape_rows
        if row.get("obj_type") == "rect"
        and row.get("net") == TARGET_NET
        and row.get("layer") == TARGET_LAYER
        and row.get("purpose") == TARGET_PURPOSE
        and same_box(row_box(row), TARGET_BOX)
    ]
    exact_stack_layers = {
        row.get("layer", "")
        for row in supply_shape_rows
        if row.get("obj_type") == "rect"
        and row.get("net") == TARGET_NET
        and row.get("purpose") == "drawing"
        and same_box(row_box(row), TARGET_BOX)
    }

    checks = {
        "SOURCE_PROBE_DECISION": operator.get("DECISION")
        == "PASS_REVIEW_EXPORT_CONTRACT",
        "SOURCE_PROBE_READ_ONLY": operator.get("OA_READ_ONLY_STATUS") == "PASS",
        "SOURCE_XSTREAM_BINDING": operator.get("XSTREAM_LOG_BINDING_STATUS")
        == "PASS",
        "SOURCE_XSTREAM_COMPLETION": operator.get("XSTREAM_LOG_COMPLETION_STATUS")
        == "PASS",
        "SOURCE_XSTREAM_ZERO_ERROR": operator.get(
            "XSTREAM_TRANSLATION_ZERO_ERROR_STATUS"
        )
        == "PASS",
        "SOURCE_LAYER_MAP_CAPTURE": operator.get("LAYER_MAP_CAPTURE_STATUS")
        == "PASS",
        "SOURCE_OBJECT_MAP_CAPTURE": operator.get("OBJECT_MAP_CAPTURE_STATUS")
        == "PASS",
        "SOURCE_EXPORT_READ_ONLY": operator.get("SOURCE_EXPORT_READ_ONLY_STATUS")
        == "PASS",
        "SOURCE_STREAM_COLLATERAL_READ_ONLY": operator.get(
            "STREAM_COLLATERAL_READ_ONLY_STATUS"
        )
        == "PASS",
        "SOURCE_CLASSIFICATION": classification.get("OA_PROBE_CLASSIFICATION_STATUS")
        == "PASS",
        "SOURCE_DIAGNOSIS": classification.get("OA_VDD_EXPORT_DIAGNOSIS")
        == "VDD_PIN_AND_LABEL_MISSING_WITH_VDD_NET_GEOMETRY",
        "SUMMARY_TERMINAL_COUNT": summary.get("TERMINAL_COUNT")
        == str(len(terminal_names)),
        "EXPECTED_TERMINALS_PRESENT": EXPECTED_TERMINALS <= terminal_names,
        "ONLY_EMPTY_GLOBAL_ALIASES_EXTRA": unexpected == ALLOWED_EMPTY_ALIASES,
        "VDD_TERMINAL_EMPTY": len(vdd_terminal_rows) == 1
        and vdd_terminal_rows[0].get("direction") == "inputOutput"
        and vdd_terminal_rows[0].get("net") == "VDD"
        and vdd_terminal_rows[0].get("obj_type") == "ABSENT",
        "VSS_TERMINAL_INTACT": len(vss_terminal_rows) == 2
        and all(row.get("obj_type") == "rect" for row in vss_terminal_rows),
        "EMPTY_ALIAS_TERMINALS_INTACT": len(alias_terminal_rows) == 2
        and all(row.get("obj_type") == "ABSENT" for row in alias_terminal_rows),
        "VDD_LABEL_ABSENT": not vdd_labels,
        "SUPPLY_NETS_PRESENT": {"VDD", "VSS", "gnd!", "vdd!"}
        <= supply_net_names,
        "UNIQUE_EXISTING_METTP_PIN_SHAPE": len(target_rows) == 1,
        "VDD_DRAWING_STACK_PRESENT": {"MET1", "MET2", "MET3"}
        <= exact_stack_layers,
    }
    errors = [f"CHECK_FAILED:{name}" for name, passed in checks.items() if not passed]
    status = "PASS" if not errors else "FAIL"

    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w", encoding="utf-8") as report:
        report.write("STEP=RO6_OA_VDD_PIN_LABEL_REPAIR_CONTRACT\n")
        for path in input_paths:
            report.write(f"SOURCE_FILE={path}\n")
            report.write(f"SOURCE_FILE_SHA256={sha256(path)}\n")
        report.write(
            "TERMINAL_NAME_SET="
            f"{','.join(sorted(terminal_names)) if terminal_names else 'NONE'}\n"
        )
        report.write(
            "ALLOWED_EMPTY_ALIAS_SET="
            f"{','.join(sorted(ALLOWED_EMPTY_ALIASES))}\n"
        )
        report.write(f"TARGET_NET={TARGET_NET}\n")
        report.write(f"TARGET_LAYER={TARGET_LAYER}\n")
        report.write(f"TARGET_PURPOSE={TARGET_PURPOSE}\n")
        report.write(
            "TARGET_BOX=" + ",".join(f"{value:.6f}" for value in TARGET_BOX) + "\n"
        )
        report.write(f"TARGET_SHAPE_COUNT={len(target_rows)}\n")
        report.write(
            "TARGET_DRAWING_STACK_LAYER_SET="
            f"{','.join(sorted(exact_stack_layers)) if exact_stack_layers else 'NONE'}\n"
        )
        report.write(f"PRE_VDD_TERMINAL_PIN_FIG_COUNT={len(vdd_pin_fig_rows)}\n")
        report.write(f"PRE_VDD_EXPLICIT_LABEL_COUNT={len(vdd_labels)}\n")
        report.write("REPAIR_METHOD=ATTACH_EXISTING_METTP_PIN_SHAPE_AND_ADD_ONE_MET3_TEXT_LABEL\n")
        report.write("METAL_GEOMETRY_CREATION_AUTHORIZED=NO\n")
        report.write("METAL_GEOMETRY_DELETION_AUTHORIZED=NO\n")
        report.write("NET_OR_TERMINAL_RENAME_AUTHORIZED=NO\n")
        report.write("GLOBAL_ALIAS_EDIT_AUTHORIZED=NO\n")
        report.write("SCHEMATIC_EDIT_AUTHORIZED=NO\n")
        report.write(f"ERROR_COUNT={len(errors)}\n")
        for index, error in enumerate(errors, start=1):
            report.write(f"ERROR_{index}={error}\n")
        report.write(f"REPAIR_CONTRACT_STATUS={status}\n")

    return 0 if status == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
