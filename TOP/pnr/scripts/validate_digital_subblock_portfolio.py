#!/usr/bin/env python3
"""Validate the digital subblock portfolio against the audited SPADMIC2 floorplan."""

from __future__ import annotations

import argparse
import csv
from dataclasses import dataclass
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
DEFAULT_PORTFOLIO = (
    REPO_ROOT / "TOP" / "pnr" / "assembly" / "spadmic_digital_subblock_portfolio.csv"
)
DEFAULT_REGIONS = (
    REPO_ROOT / "TOP" / "pnr" / "assembly" / "spadmic_digital_floorplan_regions.csv"
)
DEFAULT_AUDIT = (
    REPO_ROOT
    / "TOP"
    / "docs"
    / "layout_audits"
    / "SPADMIC2_20260709_072331"
)


@dataclass(frozen=True)
class Box:
    llx: float
    lly: float
    urx: float
    ury: float

    def valid(self) -> bool:
        return self.llx < self.urx and self.lly < self.ury

    def inside(self, outer: "Box") -> bool:
        return (
            self.llx >= outer.llx
            and self.lly >= outer.lly
            and self.urx <= outer.urx
            and self.ury <= outer.ury
        )

    def intersects(self, other: "Box") -> bool:
        return (
            self.llx < other.urx
            and self.urx > other.llx
            and self.lly < other.ury
            and self.ury > other.lly
        )


def read_csv(path: Path) -> list[dict[str, str]]:
    if not path.is_file():
        raise ValueError(f"missing_csv={path}")
    with path.open(newline="") as handle:
        return list(csv.DictReader(handle))


def region_box(row: dict[str, str]) -> Box:
    return Box(*(float(row[key]) for key in ("llx_um", "lly_um", "urx_um", "ury_um")))


def audit_box(row: dict[str, str]) -> Box:
    return Box(*(float(row[key]) for key in ("norm_llx", "norm_lly", "norm_urx", "norm_ury")))


def validate(portfolio_path: Path, regions_path: Path, audit_dir: Path) -> list[str]:
    errors: list[str] = []
    portfolio = read_csv(portfolio_path)
    regions = read_csv(regions_path)
    audit_rows = read_csv(audit_dir / "csv" / "SPADMIC2_instances_enriched.csv")

    if not portfolio:
        return ["portfolio_empty"]
    if not regions:
        return ["regions_empty"]

    blocks = [row["block"] for row in portfolio]
    if len(blocks) != len(set(blocks)):
        errors.append("duplicate_portfolio_block")
    priorities = [int(row["priority"]) for row in portfolio]
    if priorities != sorted(priorities):
        errors.append("portfolio_priority_not_sorted")

    region_names = [row["region"] for row in regions]
    if len(region_names) != len(set(region_names)):
        errors.append("duplicate_floorplan_region")
    region_by_name = {row["region"]: row for row in regions}
    die_rows = [row for row in regions if row["kind"] == "DIE"]
    if len(die_rows) != 1:
        errors.append(f"die_region_count={len(die_rows)} expected=1")
        return errors
    die = region_box(die_rows[0])

    for row in regions:
        box = region_box(row)
        if not box.valid():
            errors.append(f"invalid_region_box={row['region']}")
        elif row["kind"] != "DIE" and not box.inside(die):
            errors.append(f"region_outside_die={row['region']}")

    hard_rows = [row for row in regions if row["kind"] == "HARD_RESERVATION"]
    for index, left in enumerate(hard_rows):
        for right in hard_rows[index + 1 :]:
            if region_box(left).intersects(region_box(right)):
                errors.append(f"hard_region_overlap={left['region']}:{right['region']}")

    for row in portfolio:
        reservation = row["reservation"]
        if reservation not in region_by_name:
            errors.append(f"portfolio_region_missing={row['block']}:{reservation}")
            continue
        kind = region_by_name[reservation]["kind"]
        if row["implementation"] == "HARD_MACRO" and kind != "HARD_RESERVATION":
            errors.append(f"hard_macro_region_kind={row['block']}:{kind}")
        if row["implementation"] == "SOFT_REGION" and kind not in {"SOFT_GUIDE", "ROUTE_ONLY"}:
            errors.append(f"soft_region_kind={row['block']}:{kind}")
        if row["current_gate"].startswith("BLOCKED") and row["promotion_policy"] != "NO_PROMOTION_WHILE_BLOCKED":
            errors.append(f"blocked_promotion_policy={row['block']}")

    fixed = [
        (row["inst"], row["cell"], audit_box(row))
        for row in audit_rows
        if row["class"] != "PAD_RING"
    ]
    for region in hard_rows:
        box = region_box(region)
        for inst, cell, obstacle in fixed:
            if box.intersects(obstacle):
                errors.append(
                    f"hard_region_hits_audited_instance={region['region']}:{inst}:{cell}"
                )

    expected_clearances = (
        ("POSITION_CORE", "I1", "x_after", 20.0),
        ("EVENT_COORDINATOR", "M86", "x_before", 20.0),
        ("MATRIX_INTERFACE_SOFT", "M182", "y_before", 20.0),
    )
    audit_by_inst = {row["inst"]: audit_box(row) for row in audit_rows}
    for region_name, inst, direction, minimum in expected_clearances:
        box = region_box(region_by_name[region_name])
        obstacle = audit_by_inst[inst]
        if direction == "x_after":
            clearance = box.llx - obstacle.urx
        elif direction == "x_before":
            clearance = obstacle.llx - box.urx
        else:
            clearance = obstacle.lly - box.ury
        if clearance + 0.001 < minimum:
            errors.append(
                f"clearance_fail={region_name}:{inst}:{clearance:.3f} expected>={minimum:.3f}"
            )

    return errors


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--portfolio", type=Path, default=DEFAULT_PORTFOLIO)
    parser.add_argument("--regions", type=Path, default=DEFAULT_REGIONS)
    parser.add_argument("--layout-audit-dir", type=Path, default=DEFAULT_AUDIT)
    parser.add_argument("--status", type=Path)
    args = parser.parse_args()

    errors = validate(
        args.portfolio.resolve(),
        args.regions.resolve(),
        args.layout_audit_dir.resolve(),
    )
    lines = [
        "LABEL=SPADMIC_DIGITAL_SUBBLOCK_PORTFOLIO",
        f"STATUS={'PASS' if not errors else 'FAIL'}",
        f"PORTFOLIO={args.portfolio.resolve()}",
        f"REGIONS={args.regions.resolve()}",
        f"LAYOUT_AUDIT_DIR={args.layout_audit_dir.resolve()}",
        f"ERROR_COUNT={len(errors)}",
        *(f"ERROR={error}" for error in errors),
    ]
    text = "\n".join(lines) + "\n"
    if args.status:
        output = args.status.resolve()
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(text)
    print(text, end="")
    if errors:
        raise SystemExit(8)


if __name__ == "__main__":
    main()
