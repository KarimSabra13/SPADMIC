#!/usr/bin/env python3
"""Validate the cumulative soft digital-assembly portfolio and phase contract."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
DEFAULT_PORTFOLIO = REPO_ROOT / "TOP/pnr/assembly/spadmic_digital_subblock_portfolio.csv"
DEFAULT_PHASES = REPO_ROOT / "TOP/pnr/assembly/spadmic_digital_assembly_phases.csv"
DEFAULT_CONTRACT = REPO_ROOT / "TOP/pnr/assembly/spadmic_digital_assembly_contract.json"
DEFAULT_REGIONS = REPO_ROOT / "TOP/pnr/assembly/spadmic_digital_floorplan_regions.csv"
DEFAULT_AUDIT = REPO_ROOT / "TOP/docs/layout_audits/SPADMIC2_20260709_072331"


def read_csv(path: Path) -> list[dict[str, str]]:
    if not path.is_file():
        raise ValueError(f"missing_csv={path}")
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def validate(
    portfolio_path: Path,
    phases_path: Path = DEFAULT_PHASES,
    contract_path: Path = DEFAULT_CONTRACT,
) -> list[str]:
    errors: list[str] = []
    portfolio = read_csv(portfolio_path)
    phases = read_csv(phases_path)
    contract = json.loads(contract_path.read_text(encoding="utf-8"))
    if not portfolio:
        return ["portfolio_empty"]
    if not phases:
        return ["phases_empty"]

    blocks = [row["block"] for row in portfolio]
    if len(blocks) != len(set(blocks)):
        errors.append("duplicate_portfolio_block")
    priorities = [int(row["priority"]) for row in portfolio]
    if priorities != sorted(priorities):
        errors.append("portfolio_priority_not_sorted")

    phase_by_name = {row["phase"]: row for row in phases}
    if set(phase_by_name) != set(contract["phases"]) | {"p04_mptdc_frontend", "p05_csr_i2c"}:
        errors.append("phase_table_contract_mismatch")

    for phase, phase_contract in contract["phases"].items():
        row = phase_by_name.get(phase)
        if not row:
            errors.append(f"phase_missing={phase}")
            continue
        if row["logical_top"] != phase_contract["top"] or row["layout_top"] != phase_contract["top"]:
            errors.append(f"canonical_phase_top_mismatch={phase}")
        if row["build_mode"] != "FRESH_FROM_RTL":
            errors.append(f"phase_not_fresh_from_rtl={phase}")
        if row["density_gate"] != phase_contract["density_gate"] and not (
            phase == "p03_matrix_interface" and row["density_gate"].startswith("EXACT_")
        ):
            errors.append(f"density_policy_mismatch={phase}")

    expected_groups = {
        group
        for phase in contract["phases"].values()
        for group in phase["groups"]
    }
    observed_groups = {
        row["reservation"]
        for row in portfolio
        if row["phase"] in contract["phases"]
    }
    if observed_groups != expected_groups:
        errors.append(
            f"group_coverage_mismatch=missing:{sorted(expected_groups - observed_groups)}:"
            f"extra:{sorted(observed_groups - expected_groups)}"
        )

    for row in portfolio:
        phase = row["phase"]
        if phase in contract["phases"]:
            if row["implementation"] != "SOFT_SYNTHESIZED":
                errors.append(f"phase_block_not_soft={row['block']}")
            if row["physical_top"] != contract["phases"][phase]["top"]:
                errors.append(f"phase_physical_top_mismatch={row['block']}")
            if "HARD" in row["promotion_policy"] or "CHILD" in row["promotion_policy"]:
                errors.append(f"historical_hard_handoff_on_critical_path={row['block']}")
        elif row["implementation"] != "DEFERRED":
            errors.append(f"out_of_horizon_block_not_deferred={row['block']}")
        if row["current_gate"].startswith("BLOCKED") and row["promotion_policy"] != "NO_PROMOTION_WHILE_BLOCKED":
            errors.append(f"blocked_promotion_policy={row['block']}")

    matrix_groups = set(contract["phases"]["p03_matrix_interface"]["groups"])
    p03_rows = [row for row in portfolio if row["phase"] == "p03_matrix_interface"]
    if not matrix_groups.issubset({row["reservation"] for row in p03_rows} | {
        "tx_packet", "tx_ddr_strip", "position", "event"
    }):
        errors.append("p03_group_contract_incomplete")
    if contract["physical_policy"]["implementation"] != "CUMULATIVE_SOFT_LOGIC":
        errors.append("physical_policy_not_cumulative_soft")
    if contract["timing_policy"]["automated_cdc_rdc_gate"] is not False:
        errors.append("unexpected_automated_cdc_rdc_gate")
    return errors


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--portfolio", type=Path, default=DEFAULT_PORTFOLIO)
    parser.add_argument("--phases", type=Path, default=DEFAULT_PHASES)
    parser.add_argument("--contract", type=Path, default=DEFAULT_CONTRACT)
    parser.add_argument("--regions", type=Path, default=DEFAULT_REGIONS, help=argparse.SUPPRESS)
    parser.add_argument("--layout-audit-dir", type=Path, default=DEFAULT_AUDIT, help=argparse.SUPPRESS)
    parser.add_argument("--status", type=Path)
    args = parser.parse_args()
    errors = validate(args.portfolio.resolve(), args.phases.resolve(), args.contract.resolve())
    lines = [
        "LABEL=SPADMIC_DIGITAL_SUBBLOCK_PORTFOLIO",
        f"STATUS={'PASS' if not errors else 'FAIL'}",
        "IMPLEMENTATION=CUMULATIVE_SOFT_LOGIC",
        f"PORTFOLIO={args.portfolio.resolve()}",
        f"PHASES={args.phases.resolve()}",
        f"CONTRACT={args.contract.resolve()}",
        f"ERROR_COUNT={len(errors)}",
        *(f"ERROR={error}" for error in errors),
        "SIGNOFF_READY=NO",
    ]
    text = "\n".join(lines) + "\n"
    if args.status:
        output = args.status.resolve()
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(text, encoding="utf-8")
    print(text, end="")
    if errors:
        raise SystemExit(8)


if __name__ == "__main__":
    main()
