#!/usr/bin/env python3
"""Generate staged SPADMIC matrix-top floorplan planning collateral.

This is a planning generator, not a signoff placer. It consumes the final
matrice3 normalized pin CSV, a pad-policy CSV, and the current TOP physical
planning decisions to create reviewable Tcl/CSV/Markdown collateral for the
next Innovus stage.
"""

from __future__ import annotations

import argparse
import csv
import re
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path


KNOWN_FAMILIES = {
    "R",
    "Rz",
    "Y",
    "Yz",
    "B",
    "Bz",
    "Din",
    "Cin",
    "Dout",
    "Cout",
}

SUPPLY_RE = re.compile(r"(vdd|vss|gnd|avdd|avss|dvdd|dvss|vdda|vssa)", re.IGNORECASE)
AXIS_ORDER = ("R", "Y", "B")


@dataclass(frozen=True)
class MptdcScenario:
    name: str
    description: str
    boundary_width_um: float
    boundary_height_um: float
    dimension_margin_pct: float
    halo_um: float
    gap_um: float

    @property
    def margin_scale(self) -> float:
        return 1.0 + (self.dimension_margin_pct / 100.0)

    @property
    def macro_width_um(self) -> float:
        return self.boundary_width_um * self.margin_scale

    @property
    def macro_height_um(self) -> float:
        return self.boundary_height_um * self.margin_scale

    @property
    def planning_width_um(self) -> float:
        return self.macro_width_um + (2.0 * self.halo_um)

    @property
    def planning_height_um(self) -> float:
        return self.macro_height_um + (2.0 * self.halo_um)

    @property
    def planning_area_um2(self) -> float:
        return self.planning_width_um * self.planning_height_um

    @property
    def aspect_ratio(self) -> float:
        return self.planning_width_um / self.planning_height_um


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--csv",
        default=(
            "position/docs/matrix_handoffs/"
            "20260626_matrice3_final_lef_extract_norm/"
            "matrice3_pin_coordinates.csv"
        ),
        help="Input matrice3 pin CSV with ll_* normalized columns.",
    )
    parser.add_argument(
        "--pad-policy",
        default="TOP/pnr/inputs/matrix_top_pad_policy_template.csv",
        help="Pad-side policy CSV used before pad-ring LEF/DEF exists.",
    )
    parser.add_argument("--out", required=True, help="Output directory.")
    parser.add_argument("--run-id", default="matrix_top_floorplan", help="Run ID.")
    parser.add_argument("--die-width-um", type=float, default=4293.179)
    parser.add_argument("--die-height-um", type=float, default=3209.173)
    parser.add_argument("--pad-keepout-um", type=float, default=164.0)
    parser.add_argument("--box-ring-source", default="/group/validmgr/PROJET/Prj_xh018/ksabra/cds/design/SPADMIC")
    parser.add_argument("--matrix-width-um", type=float, default=1999.91)
    parser.add_argument("--matrix-height-um", type=float, default=1725.54)
    parser.add_argument("--matrix-left-margin-um", type=float, default=164.0)
    parser.add_argument("--matrix-halo-um", type=float, default=50.0)
    parser.add_argument("--internal-corridor-extra-um", type=float, default=250.0)
    parser.add_argument("--mptdc-left-gap-um", type=float, default=100.0)
    parser.add_argument("--mptdc-gap-um", type=float, default=20.0)
    parser.add_argument("--mptdc-width-um", type=float, default=1061.20)
    parser.add_argument("--mptdc-height-um", type=float, default=801.92)
    parser.add_argument("--mptdc-dimension-margin-pct", type=float, default=5.0)
    parser.add_argument("--mptdc-halo-um", type=float, default=20.0)
    parser.add_argument("--scenario-a-mptdc-width-um", type=float, default=1020.88)
    parser.add_argument("--scenario-a-mptdc-height-um", type=float, default=761.60)
    parser.add_argument("--scenario-a-mptdc-gap-um", type=float, default=40.0)
    parser.add_argument("--horizontal-extension-pct", type=float, default=0.0)
    parser.add_argument("--pll-width-um", type=float, default=300.0)
    parser.add_argument("--pll-height-um", type=float, default=220.0)
    return parser.parse_args()


def as_float(row: dict[str, str], key: str) -> float:
    try:
        return float(row[key])
    except KeyError as exc:
        raise SystemExit(f"missing required CSV column: {key}") from exc
    except ValueError as exc:
        raise SystemExit(f"invalid float in column {key}: {row.get(key)!r}") from exc


def classify(row: dict[str, str]) -> str:
    family = row.get("pin_family", "").strip()
    pin = row.get("pin", "").strip()
    use = row.get("use", "").strip().upper()
    if family in KNOWN_FAMILIES:
        return family
    if SUPPLY_RE.search(pin) or SUPPLY_RE.search(family) or use in {"POWER", "GROUND"}:
        return "SUPPLY"
    match = re.match(r"^(Rz|Yz|Bz|R|Y|B|Din|Cin|Dout|Cout)(?:\[|$)", pin)
    if match:
        return match.group(1)
    return "UNKNOWN"


def bbox(rows: list[dict[str, str]]) -> tuple[float, float, float, float]:
    return (
        min(as_float(r, "ll_bbox_x1") for r in rows),
        min(as_float(r, "ll_bbox_y1") for r in rows),
        max(as_float(r, "ll_bbox_x2") for r in rows),
        max(as_float(r, "ll_bbox_y2") for r in rows),
    )


def fmt_rect(rect: tuple[float, float, float, float]) -> str:
    return " ".join(f"{v:.3f}" for v in rect)


def rect_area(rect: tuple[float, float, float, float]) -> float:
    return max(0.0, rect[2] - rect[0]) * max(0.0, rect[3] - rect[1])


def shrink_rect(rect: tuple[float, float, float, float], amount: float) -> tuple[float, float, float, float]:
    return (rect[0] + amount, rect[1] + amount, rect[2] - amount, rect[3] - amount)


def write_csv(path: Path, header: list[str], rows: list[list[object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="") as fh:
        writer = csv.writer(fh)
        writer.writerow(header)
        writer.writerows(rows)


def read_matrix_rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="") as fh:
        reader = csv.DictReader(fh)
        required = {
            "pin",
            "direction",
            "use",
            "pin_family",
            "ll_bbox_x1",
            "ll_bbox_y1",
            "ll_bbox_x2",
            "ll_bbox_y2",
            "ll_center_x",
            "ll_center_y",
            "side",
        }
        missing = sorted(required - set(reader.fieldnames or []))
        if missing:
            raise SystemExit(f"CSV missing required ll_* planning columns: {missing}")
        rows = list(reader)
    if not rows:
        raise SystemExit("CSV has no pin rows")
    for row in rows:
        row["classified_family"] = classify(row)
    return rows


def read_pad_policy(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        return []
    with path.open(newline="") as fh:
        reader = csv.DictReader(fh)
        required = {"side", "order", "signal_or_group", "direction", "voltage_domain", "notes"}
        missing = sorted(required - set(reader.fieldnames or []))
        if missing:
            raise SystemExit(f"pad policy CSV missing required columns: {missing}")
        return list(reader)


def pin_family_summary(rows: list[dict[str, str]]) -> tuple[list[list[object]], Counter[tuple[str, str]]]:
    by_family: dict[str, list[dict[str, str]]] = defaultdict(list)
    by_side: Counter[tuple[str, str]] = Counter()
    for row in rows:
        fam = row["classified_family"]
        side = row.get("side", "UNKNOWN") or "UNKNOWN"
        by_family[fam].append(row)
        by_side[(fam, side)] += 1

    family_rows: list[list[object]] = []
    for fam in sorted(by_family):
        fam_rows = by_family[fam]
        x1, y1, x2, y2 = bbox(fam_rows)
        family_rows.append(
            [
                fam,
                len(fam_rows),
                f"{x1:.3f}",
                f"{y1:.3f}",
                f"{x2:.3f}",
                f"{y2:.3f}",
                ",".join(sorted({r.get("side", "UNKNOWN") or "UNKNOWN" for r in fam_rows})),
            ]
        )
    return family_rows, by_side


def axis_pin_centers(rows: list[dict[str, str]]) -> dict[str, float]:
    centers: dict[str, float] = {}
    for axis in AXIS_ORDER:
        axis_rows = [r for r in rows if r["classified_family"] == axis]
        if axis_rows:
            centers[axis] = sum(as_float(r, "ll_center_y") for r in axis_rows) / len(axis_rows)
        else:
            centers[axis] = 0.0
    return centers


def place_mptdc_stack(
    scenario: MptdcScenario,
    matrix: tuple[float, float, float, float],
    core: tuple[float, float, float, float],
    left_gap_um: float,
) -> tuple[dict[str, tuple[float, float, float, float]], dict[str, float | str]]:
    planning_w = scenario.planning_width_um
    planning_h = scenario.planning_height_um
    stack_h = (3.0 * planning_h) + (2.0 * scenario.gap_um)
    x1 = matrix[2] + left_gap_um
    stack_y1 = core[1] + (((core[3] - core[1]) - stack_h) / 2.0)

    boxes: dict[str, tuple[float, float, float, float]] = {}
    y_top = stack_y1 + stack_h
    for axis in AXIS_ORDER:
        y2 = y_top
        y1 = y2 - planning_h
        boxes[axis] = (x1, y1, x1 + planning_w, y2)
        y_top = y1 - scenario.gap_um

    width_excess = max(0.0, (x1 + planning_w) - core[2])
    height_excess = max(0.0, core[1] - stack_y1, (stack_y1 + stack_h) - core[3])
    aspect = scenario.aspect_ratio
    height_limit = max(0.0, ((core[3] - core[1]) - (2.0 * scenario.gap_um)) / 3.0)
    width_limit = max(0.0, core[2] - x1)
    max_plan_h = min(height_limit, width_limit / aspect if aspect > 0.0 else 0.0)
    max_area_fit = max_plan_h * max_plan_h * aspect
    issues: list[str] = []
    if width_excess > 0.0:
        issues.append("MPTDC_STACK_EXCEEDS_CORE_WIDTH")
    if height_excess > 0.0:
        issues.append("MPTDC_VERTICAL_STACK_EXCEEDS_CORE_HEIGHT")

    metrics: dict[str, float | str] = {
        "status": "FAIL" if issues else "PASS",
        "issues": " ".join(issues),
        "width_excess_um": width_excess,
        "height_excess_um": height_excess,
        "max_area_fit_um2": max_area_fit,
        "stack_height_um": stack_h,
        "planning_width_um": planning_w,
        "planning_height_um": planning_h,
        "planning_area_um2": scenario.planning_area_um2,
    }
    return boxes, metrics


def main() -> int:
    args = parse_args()
    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    matrix_csv = Path(args.csv)
    pad_policy_csv = Path(args.pad_policy)
    rows = read_matrix_rows(matrix_csv)
    pad_rows = read_pad_policy(pad_policy_csv)

    pin_bbox = bbox(rows)
    internal_rows = [r for r in rows if r.get("side", "") == "INTERNAL_NEAREST_RIGHT"]
    internal_bbox = bbox(internal_rows) if internal_rows else None
    family_rows, by_side = pin_family_summary(rows)
    axis_centers = axis_pin_centers(rows)
    unknown_rows = [r for r in rows if r["classified_family"] == "UNKNOWN"]

    die_w = args.die_width_um
    die_h = args.die_height_um
    keepout = args.pad_keepout_um
    core = (keepout, keepout, die_w - keepout, die_h - keepout)
    core_w = core[2] - core[0]
    core_h = core[3] - core[1]
    matrix_x1 = max(core[0], args.matrix_left_margin_um)
    matrix_y1 = core[1] + ((core_h - args.matrix_height_um) / 2.0)
    matrix = (matrix_x1, matrix_y1, matrix_x1 + args.matrix_width_um, matrix_y1 + args.matrix_height_um)
    matrix_halo = (
        matrix[0] - args.matrix_halo_um,
        matrix[1] - args.matrix_halo_um,
        matrix[2] + args.matrix_halo_um,
        matrix[3] + args.matrix_halo_um,
    )

    scenario_a = MptdcScenario(
        name="A_CORE_OPTIMISTIC",
        description="MPTDC core-box estimate only; no dimensional margin or halo.",
        boundary_width_um=args.scenario_a_mptdc_width_um,
        boundary_height_um=args.scenario_a_mptdc_height_um,
        dimension_margin_pct=0.0,
        halo_um=0.0,
        gap_um=args.scenario_a_mptdc_gap_um,
    )
    scenario_b = MptdcScenario(
        name="B_FULL_BOUNDARY_MARGIN_HALO",
        description="Required TOP planning case: full DEF boundary, 5 percent dimension margin, and provisional halo.",
        boundary_width_um=args.mptdc_width_um,
        boundary_height_um=args.mptdc_height_um,
        dimension_margin_pct=args.mptdc_dimension_margin_pct,
        halo_um=args.mptdc_halo_um,
        gap_um=args.mptdc_gap_um,
    )
    scenarios = [scenario_a, scenario_b]

    scenario_boxes: dict[str, dict[str, tuple[float, float, float, float]]] = {}
    scenario_metrics: dict[str, dict[str, float | str]] = {}
    scenario_rows: list[list[object]] = []
    for scenario in scenarios:
        boxes, metrics = place_mptdc_stack(scenario, matrix, core, args.mptdc_left_gap_um)
        scenario_boxes[scenario.name] = boxes
        scenario_metrics[scenario.name] = metrics
        scenario_rows.append(
            [
                scenario.name,
                scenario.description,
                f"{scenario.boundary_width_um:.3f}",
                f"{scenario.boundary_height_um:.3f}",
                f"{scenario.dimension_margin_pct:.3f}",
                f"{scenario.halo_um:.3f}",
                f"{scenario.gap_um:.3f}",
                f"{scenario.planning_width_um:.3f}",
                f"{scenario.planning_height_um:.3f}",
                f"{scenario.planning_area_um2:.3f}",
                metrics["status"],
                metrics["issues"],
                f"{float(metrics['width_excess_um']):.3f}",
                f"{float(metrics['height_excess_um']):.3f}",
                f"{float(metrics['max_area_fit_um2']):.3f}",
            ]
        )

    main_scenario = scenario_b
    mptdc_boxes = scenario_boxes[main_scenario.name]
    main_metrics = scenario_metrics[main_scenario.name]
    feasibility_issues: list[str] = []
    if matrix[0] < core[0] or matrix[2] > core[2] or matrix[1] < core[1] or matrix[3] > core[3]:
        feasibility_issues.append("MATRIX_OUTSIDE_CORE")
    if main_metrics["issues"]:
        feasibility_issues.extend(str(main_metrics["issues"]).split())
    if internal_bbox is None:
        feasibility_issues.append("NO_INTERNAL_RIGHT_CORRIDOR_DETECTED")
    top_status = "FAIL" if feasibility_issues else "PASS"

    internal_corridor = None
    if internal_bbox:
        internal_corridor = (
            matrix[0] + max(0.0, internal_bbox[0] - 25.0),
            matrix[1] + max(0.0, internal_bbox[1] - 25.0),
            matrix[2] + args.internal_corridor_extra_um,
            matrix[1] + min(args.matrix_height_um, internal_bbox[3] + 25.0),
        )

    regions: dict[str, tuple[float, float, float, float]] = {
        "die": (0.0, 0.0, die_w, die_h),
        "box_ring_outer": (0.0, 0.0, die_w, die_h),
        "box_ring_inner_planning": core,
        "core_planning": core,
        "matrice3_macro": matrix,
        "matrice3_halo": matrix_halo,
        "or64_reset_matrix_edge": (matrix[2] - 220.0, matrix[1], matrix[2] + 160.0, matrix[3]),
        "matrix_cfg_bottom": (matrix[0], core[1], matrix[2] + 250.0, matrix[1] + 260.0),
        "matrix_cout_dout_top": (matrix[0], matrix[3] - 220.0, matrix[2] + 250.0, min(core[3], matrix[3] + 260.0)),
        "position_distributed_frontend": (matrix[2] - 280.0, matrix[1], matrix[2] + 300.0, matrix[3]),
        "position_cluster_main": (matrix[2] + 420.0, matrix[1] + 280.0, min(core[2], matrix[2] + 920.0), matrix[1] + 920.0),
        "control_reset_supervision_south": (matrix[0], core[1], min(core[2], matrix[2] + 1050.0), matrix[1] - 80.0),
        "fifo_bundle_north": (matrix[2] + 220.0, max(matrix[3] - 50.0, core[3] - 420.0), core[2], core[3]),
        "pll_clock_mux_south_east": (core[2] - args.pll_width_um, core[1], core[2], core[1] + args.pll_height_um),
    }
    if internal_corridor:
        regions["internal_nearest_right_corridor"] = internal_corridor
    for axis, rect in mptdc_boxes.items():
        macro_rect = shrink_rect(rect, main_scenario.halo_um)
        regions[f"mptdc_{axis.lower()}_planning_halo"] = rect
        regions[f"mptdc_{axis.lower()}_macro_boundary_margin"] = macro_rect

    mptdc_rows: list[list[object]] = []
    for axis in AXIS_ORDER:
        rect = mptdc_boxes[axis]
        macro_rect = shrink_rect(rect, main_scenario.halo_um)
        mptdc_rows.append(
            [
                axis,
                main_scenario.name,
                f"{rect[0]:.3f}",
                f"{rect[1]:.3f}",
                f"{rect[2]:.3f}",
                f"{rect[3]:.3f}",
                f"{rect[2] - rect[0]:.3f}",
                f"{rect[3] - rect[1]:.3f}",
                f"{rect_area(rect):.3f}",
                f"{macro_rect[0]:.3f}",
                f"{macro_rect[1]:.3f}",
                f"{macro_rect[2]:.3f}",
                f"{macro_rect[3]:.3f}",
                f"{axis_centers[axis]:.3f}",
            ]
        )

    write_csv(
        out_dir / "matrix_pin_family_summary.csv",
        ["family", "pin_count", "ll_bbox_x1", "ll_bbox_y1", "ll_bbox_x2", "ll_bbox_y2", "sides"],
        family_rows,
    )
    write_csv(
        out_dir / "matrix_pin_side_summary.csv",
        ["family", "side", "pin_count"],
        [[fam, side, count] for (fam, side), count in sorted(by_side.items())],
    )
    write_csv(
        out_dir / "matrix_unknown_pins.csv",
        ["pin", "pin_family", "direction", "use", "side", "ll_center_x", "ll_center_y"],
        [
            [
                r.get("pin", ""),
                r.get("pin_family", ""),
                r.get("direction", ""),
                r.get("use", ""),
                r.get("side", ""),
                r.get("ll_center_x", ""),
                r.get("ll_center_y", ""),
            ]
            for r in unknown_rows
        ],
    )
    write_csv(
        out_dir / "matrix_top_region_summary.csv",
        ["region", "x1_um", "y1_um", "x2_um", "y2_um", "area_um2"],
        [
            [name, f"{r[0]:.3f}", f"{r[1]:.3f}", f"{r[2]:.3f}", f"{r[3]:.3f}", f"{rect_area(r):.3f}"]
            for name, r in sorted(regions.items())
        ],
    )
    write_csv(
        out_dir / "mptdc_placeholder_summary.csv",
        [
            "axis",
            "scenario",
            "planning_x1_um",
            "planning_y1_um",
            "planning_x2_um",
            "planning_y2_um",
            "planning_width_um",
            "planning_height_um",
            "planning_area_um2",
            "macro_x1_um",
            "macro_y1_um",
            "macro_x2_um",
            "macro_y2_um",
            "matrix_axis_pin_y_centroid_um",
        ],
        mptdc_rows,
    )
    write_csv(
        out_dir / "mptdc_scenario_summary.csv",
        [
            "scenario",
            "description",
            "boundary_width_um",
            "boundary_height_um",
            "dimension_margin_pct",
            "halo_um",
            "gap_um",
            "planning_width_um",
            "planning_height_um",
            "planning_area_um2",
            "status",
            "issues",
            "width_excess_um",
            "height_excess_um",
            "max_planning_area_fit_um2",
        ],
        scenario_rows,
    )
    write_csv(
        out_dir / "pad_policy_summary.csv",
        ["side", "order", "signal_or_group", "direction", "voltage_domain", "notes"],
        [
            [
                r.get("side", ""),
                r.get("order", ""),
                r.get("signal_or_group", ""),
                r.get("direction", ""),
                r.get("voltage_domain", ""),
                r.get("notes", ""),
            ]
            for r in pad_rows
        ],
    )

    with (out_dir / "top_floorplan_regions.tcl").open("w") as fh:
        fh.write("# Generated by gen_matrix_top_floorplan_plan.py\n")
        fh.write("# Coordinates are absolute planning coordinates in um for the TOP seed.\n")
        fh.write("namespace eval spadmic_matrix_top_fp {\n")
        fh.write(f"  variable run_id {{{args.run_id}}}\n")
        fh.write(f"  variable status {{{top_status}}}\n")
        fh.write(f"  variable issue_list {{{' '.join(feasibility_issues)}}}\n")
        fh.write(f"  variable scenario {{{main_scenario.name}}}\n")
        fh.write(f"  variable box_ring_source {{{args.box_ring_source}}}\n")
        fh.write(f"  variable die_width_um {die_w:.3f}\n")
        fh.write(f"  variable die_height_um {die_h:.3f}\n")
        fh.write(f"  variable pad_ring_depth_um {keepout:.3f}\n")
        fh.write(f"  variable mptdc_boundary_width_um {main_scenario.boundary_width_um:.3f}\n")
        fh.write(f"  variable mptdc_boundary_height_um {main_scenario.boundary_height_um:.3f}\n")
        fh.write(f"  variable mptdc_dimension_margin_pct {main_scenario.dimension_margin_pct:.3f}\n")
        fh.write(f"  variable mptdc_halo_um {main_scenario.halo_um:.3f}\n")
        fh.write(f"  variable mptdc_axis_order {{{' '.join(AXIS_ORDER)}}}\n")
        fh.write("  variable regions\n")
        for name, rect in sorted(regions.items()):
            fh.write(f"  set regions({name}) {{{fmt_rect(rect)}}}\n")
        fh.write("  proc report_regions {} {\n")
        fh.write("    variable regions\n")
        fh.write("    foreach name [lsort [array names regions]] { puts \"$name $regions($name)\" }\n")
        fh.write("  }\n")
        fh.write("}\n")
        fh.write("spadmic_matrix_top_fp::report_regions\n")

    with (out_dir / "feasibility_status.txt").open("w") as fh:
        fh.write(f"STATUS={top_status}\n")
        fh.write(f"SCENARIO={main_scenario.name}\n")
        fh.write(f"ISSUES={' '.join(feasibility_issues)}\n")
        fh.write(f"MPTDC_WIDTH_EXCESS_UM={float(main_metrics['width_excess_um']):.3f}\n")
        fh.write(f"MPTDC_HEIGHT_EXCESS_UM={float(main_metrics['height_excess_um']):.3f}\n")
        fh.write(f"MPTDC_MAX_PLANNING_AREA_FIT_UM2={float(main_metrics['max_area_fit_um2']):.3f}\n")
        fh.write(f"MPTDC_MAX_PLANNING_AREA_FIT_MM2={float(main_metrics['max_area_fit_um2']) / 1_000_000.0:.6f}\n")
        fh.write("HORIZONTAL_EXTENSION_CAN_FIX_WIDTH=False\n")

    with (out_dir / "top_floorplan_summary.md").open("w") as fh:
        fh.write("# SPADMIC Matrix TOP Staged Floorplan Plan\n\n")
        fh.write(f"- Run ID: `{args.run_id}`\n")
        fh.write(f"- Input matrix CSV: `{matrix_csv}`\n")
        fh.write(f"- Pad policy CSV: `{pad_policy_csv}`\n")
        fh.write(f"- BOX_RING/OA source: `{args.box_ring_source}`\n")
        fh.write("- Coordinate basis: absolute planning coordinates in um; matrix pins use normalized `ll_*` source columns\n")
        fh.write(f"- Gated scenario: `{main_scenario.name}`\n")
        fh.write(f"- Status: `{top_status}`\n")
        fh.write(f"- Issues: `{', '.join(feasibility_issues) if feasibility_issues else 'none'}`\n")
        fh.write(f"- Die: `{die_w:.3f} um x {die_h:.3f} um` ({(die_w * die_h) / 1_000_000.0:.3f} mm^2)\n")
        fh.write(f"- Pad-ring/core physical planning depth: `{keepout:.3f} um`\n")
        fh.write(f"- Core planning box: `{fmt_rect(core)}`\n")
        fh.write(f"- Matrix placement: `{fmt_rect(matrix)}`\n")
        fh.write(f"- Matrix area: `{rect_area(matrix) / 1_000_000.0:.6f} mm^2`\n")
        fh.write(f"- Required MPTDC planning envelope per axis: `{main_scenario.planning_width_um:.3f} um x {main_scenario.planning_height_um:.3f} um`\n")
        fh.write(f"- Required MPTDC planning area per axis: `{main_scenario.planning_area_um2 / 1_000_000.0:.6f} mm^2`\n")
        fh.write(f"- MPTDC vertical stack height including gaps: `{float(main_metrics['stack_height_um']):.3f} um`\n")
        fh.write(f"- MPTDC width excess beyond core: `{float(main_metrics['width_excess_um']):.3f} um`\n")
        fh.write(f"- MPTDC height excess beyond core: `{float(main_metrics['height_excess_um']):.3f} um`\n")
        fh.write(f"- Maximum required-style MPTDC planning area per axis that fits: `{float(main_metrics['max_area_fit_um2']) / 1_000_000.0:.6f} mm^2`\n")
        fh.write("- Horizontal die extension allowed by normal flow: `0.000%`\n")
        fh.write("\n## Scenario Comparison\n\n")
        fh.write("| Scenario | Boundary | Margin | Halo | Gap | Planning envelope | Status | Issues |\n")
        fh.write("| --- | --- | ---: | ---: | ---: | --- | --- | --- |\n")
        for scenario in scenarios:
            metrics = scenario_metrics[scenario.name]
            fh.write(
                f"| `{scenario.name}` | `{scenario.boundary_width_um:.3f} x {scenario.boundary_height_um:.3f} um` "
                f"| {scenario.dimension_margin_pct:.1f}% | {scenario.halo_um:.1f} um | {scenario.gap_um:.1f} um "
                f"| `{scenario.planning_width_um:.3f} x {scenario.planning_height_um:.3f} um` "
                f"| `{metrics['status']}` | `{metrics['issues'] or 'none'}` |\n"
            )
        fh.write("\n## Axis Placeholder Order\n\n")
        fh.write("| Axis | Planning halo box | Macro boundary+margin box | Pin centroid y from CSV |\n")
        fh.write("| --- | --- | --- | ---: |\n")
        for axis in AXIS_ORDER:
            rect = mptdc_boxes[axis]
            macro_rect = shrink_rect(rect, main_scenario.halo_um)
            fh.write(f"| `{axis}` | `{fmt_rect(rect)}` | `{fmt_rect(macro_rect)}` | {axis_centers[axis]:.3f} |\n")
        fh.write("\n## Pin Evidence\n\n")
        fh.write(f"- Matrix pin rows: `{len(rows)}`\n")
        fh.write(f"- Pin normalized bbox: `{fmt_rect(pin_bbox)}`\n")
        fh.write(f"- INTERNAL_NEAREST_RIGHT pins: `{len(internal_rows)}`\n")
        if internal_bbox:
            fh.write(f"- INTERNAL_NEAREST_RIGHT normalized bbox: `{fmt_rect(internal_bbox)}`\n")
        fh.write("- Unknown/analog rows are reported in `matrix_unknown_pins.csv`.\n")
        fh.write("\n## Pad And Clock Policy\n\n")
        fh.write(f"- Policy rows: `{len(pad_rows)}`\n")
        fh.write("- Current policy uses one external 160 MHz clock pad; `clk_cfg_40m` and `clk_ref_40m` are not independent external pads.\n")
        fh.write("- Reset default selects PLL 160 MHz; external 160 MHz mode uses one divide-by-4 clock for both logical 40 MHz domains.\n")
        fh.write("- DDR16 entries are north-side placeholders and intentionally low priority.\n")
        fh.write("- `VTUNE` and matrix supplies are analog/macro-owned and not digital route claims.\n")
        fh.write("\n## Promotion Rule\n\n")
        fh.write("- If `Status` is `FAIL`, the server Innovus wrapper must stop after generating reports.\n")
        fh.write("- Do not silently switch to a 2+1 MPTDC arrangement.\n")
        fh.write("- Do not claim placement, route, CTS, DRC/LVS, PG, PEX, MMMC, or final signoff from this plan.\n")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
