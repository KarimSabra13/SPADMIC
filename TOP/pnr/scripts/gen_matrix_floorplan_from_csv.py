#!/usr/bin/env python3
"""Generate SPADMIC matrice3 floorplan planning collateral from pin CSV.

The generator intentionally uses the lower-left-normalized ll_* columns from
the LEF extraction. Raw LEF-origin coordinates are not used for planning.
"""

from __future__ import annotations

import argparse
import csv
import math
import re
from collections import Counter, defaultdict
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
    parser.add_argument("--out", required=True, help="Output directory.")
    parser.add_argument("--run-id", default="matrix_floorplan", help="Run ID.")
    parser.add_argument("--halo-um", type=float, default=50.0, help="Planning halo.")
    parser.add_argument(
        "--macro-width-um",
        type=float,
        default=1999.91,
        help="matrice3 macro width from final LEF handoff.",
    )
    parser.add_argument(
        "--macro-height-um",
        type=float,
        default=1725.54,
        help="matrice3 macro height from final LEF handoff.",
    )
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


def write_csv(path: Path, header: list[str], rows: list[list[object]]) -> None:
    with path.open("w", newline="") as fh:
        writer = csv.writer(fh)
        writer.writerow(header)
        writer.writerows(rows)


def fmt_rect(rect: tuple[float, float, float, float]) -> str:
    return " ".join(f"{v:.3f}" for v in rect)


def main() -> int:
    args = parse_args()
    csv_path = Path(args.csv)
    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    with csv_path.open(newline="") as fh:
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

    pin_bbox = bbox(rows)
    pin_span_w = pin_bbox[2] - pin_bbox[0]
    pin_span_h = pin_bbox[3] - pin_bbox[1]
    macro_w = args.macro_width_um
    macro_h = args.macro_height_um
    pin_count = len(rows)
    shape_count = sum(int(float(r.get("shape_count", "1") or 1)) for r in rows)

    by_family: dict[str, list[dict[str, str]]] = defaultdict(list)
    by_side: Counter[tuple[str, str]] = Counter()
    by_unknown: list[dict[str, str]] = []
    for row in rows:
        fam = row["classified_family"]
        side = row.get("side", "UNKNOWN") or "UNKNOWN"
        by_family[fam].append(row)
        by_side[(fam, side)] += 1
        if fam == "UNKNOWN":
            by_unknown.append(row)

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

    side_rows = [[fam, side, count] for (fam, side), count in sorted(by_side.items())]

    internal_right = [
        r for r in rows if (r.get("side", "") == "INTERNAL_NEAREST_RIGHT")
    ]
    internal_bbox = bbox(internal_right) if internal_right else None

    halo = args.halo_um
    regions: dict[str, tuple[float, float, float, float]] = {
        "matrix_macro_ll_relative": (0.0, 0.0, macro_w, macro_h),
        "matrix_halo": (-halo, -halo, macro_w + halo, macro_h + halo),
        "mptdc_cluster_right": (macro_w + 100.0, macro_h * 0.25, macro_w + 950.0, macro_h * 0.75),
        "or64_input_banks": (macro_w - 200.0, 0.0, macro_w + 300.0, macro_h),
        "reset_driver_banks": (macro_w - 250.0, 0.0, macro_w + 250.0, macro_h),
        "position_distributed_frontend": (macro_w - 300.0, 0.0, macro_w + 350.0, macro_h),
        "position_cluster_main": (macro_w + 450.0, macro_h * 0.15, macro_w + 950.0, macro_h * 0.55),
        "control_reset_supervision_bottom": (0.0, -450.0, macro_w + 900.0, -80.0),
        "fifo_bundle_ddr_north": (macro_w + 350.0, macro_h + 80.0, macro_w + 1200.0, macro_h + 520.0),
        "pll_placeholder_bottom_right": (macro_w + 950.0, -450.0, macro_w + 1300.0, -80.0),
    }
    if internal_bbox:
        x1, y1, x2, y2 = internal_bbox
        regions["internal_nearest_right_corridor"] = (
            max(0.0, x1 - 25.0),
            max(0.0, y1 - 25.0),
            macro_w + 250.0,
            min(macro_h, y2 + 25.0),
        )

    write_csv(
        out_dir / "matrix_pin_family_summary.csv",
        ["family", "pin_count", "ll_bbox_x1", "ll_bbox_y1", "ll_bbox_x2", "ll_bbox_y2", "sides"],
        family_rows,
    )
    write_csv(out_dir / "matrix_pin_side_summary.csv", ["family", "side", "pin_count"], side_rows)
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
            for r in by_unknown
        ],
    )

    with (out_dir / "matrix_floorplan_regions.tcl").open("w") as fh:
        fh.write("# Generated by gen_matrix_floorplan_from_csv.py\n")
        fh.write("# Coordinates are lower-left-normalized relative to matrice3.\n")
        fh.write("namespace eval spadmic_matrix_fp {\n")
        fh.write(f"  variable run_id {{{args.run_id}}}\n")
        fh.write(f"  variable matrix_width_um {macro_w:.3f}\n")
        fh.write(f"  variable matrix_height_um {macro_h:.3f}\n")
        fh.write("  variable regions\n")
        for name, rect in regions.items():
            fh.write(f"  set regions({name}) {{{fmt_rect(rect)}}}\n")
        fh.write("  proc report_regions {} {\n")
        fh.write('    variable regions\n')
        fh.write('    foreach name [lsort [array names regions]] { puts "$name $regions($name)" }\n')
        fh.write("  }\n")
        fh.write("}\n")
        fh.write("spadmic_matrix_fp::report_regions\n")

    with (out_dir / "floorplan_summary.md").open("w") as fh:
        fh.write("# matrice3 Floorplan Planning Summary\n\n")
        fh.write(f"- Run ID: `{args.run_id}`\n")
        fh.write(f"- Input CSV: `{csv_path}`\n")
        fh.write("- Coordinate basis: `ll_*` lower-left-normalized extraction columns\n")
        fh.write(f"- Pin rows: {pin_count}\n")
        fh.write(f"- Pin shapes reported by CSV: {shape_count}\n")
        fh.write(f"- Matrix macro size used for planning: `{macro_w:.3f} um x {macro_h:.3f} um`\n")
        fh.write(f"- Pin normalized bbox: `{fmt_rect(pin_bbox)}`\n")
        fh.write(f"- Pin normalized span: `{pin_span_w:.3f} um x {pin_span_h:.3f} um`\n")
        fh.write(f"- INTERNAL_NEAREST_RIGHT pins: {len(internal_right)}\n")
        if internal_bbox:
            fh.write(f"- INTERNAL_NEAREST_RIGHT bbox: `{fmt_rect(internal_bbox)}`\n")
        fh.write("\n## Family Counts\n\n")
        fh.write("| Family | Pins | Sides |\n| --- | ---: | --- |\n")
        for fam, count, *_rest, sides in family_rows:
            fh.write(f"| `{fam}` | {count} | `{sides}` |\n")
        fh.write("\n## Required Planning Notes\n\n")
        fh.write("- Place `matrice3` on the left side of the chip, vertically centered.\n")
        fh.write("- Place three MPTDC axes to the right of the matrix and close together.\n")
        fh.write("- Reserve the `internal_nearest_right_corridor` when present.\n")
        fh.write("- Place FIFO/bundle/DDR north or north-east because final DDR pins are north.\n")
        fh.write("- Place control/reset/supervision logic below the matrix.\n")
        fh.write("- Treat all regions as planning guides, not signoff coordinates.\n")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
