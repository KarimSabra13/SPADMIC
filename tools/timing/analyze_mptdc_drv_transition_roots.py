#!/usr/bin/env python3
"""Summarize Genus max-transition root causes for final-typical repair."""

from __future__ import annotations

import argparse
import csv
import re
from pathlib import Path


DRV_ROW_RE = re.compile(
    r"^(?P<pin>\S+)\s+(?P<slew>\d+(?:\.\d+)?)\s+"
    r"(?P<limit>\d+(?:\.\d+)?)\s+(?P<violation>\d+(?:\.\d+)?)$"
)
HF_ROW_RE = re.compile(r"^\s*(?P<fanout>\d+)\s+(?P<net>\S+)\s+(?P<driver>\S+)\s*$")


def read_text(path: Path) -> str:
    try:
        return path.read_text(errors="replace")
    except FileNotFoundError:
        return ""


def parse_drv_rows(path: Path) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    current_root = ""
    for raw in read_text(path).splitlines():
        match = DRV_ROW_RE.match(raw.strip())
        if match:
            row = match.groupdict()
            pin = row["pin"]
            if pin.endswith("/Q"):
                current_root = pin
            row["root_driver"] = current_root or pin
            rows.append(row)
    return rows


def parse_high_fanout(path: Path) -> dict[str, dict[str, str]]:
    by_driver: dict[str, dict[str, str]] = {}
    for raw in read_text(path).splitlines():
        match = HF_ROW_RE.match(raw)
        if not match:
            continue
        row = match.groupdict()
        by_driver[row["driver"]] = row
    return by_driver


def parse_driver_cells(netlist: Path) -> dict[str, str]:
    out: dict[str, str] = {}
    inst_re = re.compile(r"^\s*(?P<cell>\S+)\s+(?P<inst>\\?\S+)\(")
    for raw in read_text(netlist).splitlines():
        match = inst_re.match(raw)
        if not match:
            continue
        out[match.group("inst").lstrip("\\")] = match.group("cell")
    return out


def sink_family(pin: str) -> str:
    if "gen_pd_row" in pin and "u_pd" in pin:
        if "drc_bufs" in pin or "detect_en" in pin or "/g2/" in pin:
            return "PD_DETECT_ENABLE_OR_CLEAR_LOCAL_LOGIC"
        return "PD_LOCAL_LOGIC"
    if "rst" in pin:
        return "RESET"
    if "phase_buf" in pin or "fast_phase" in pin or "slow_phase" in pin:
        return "PHASE_CLOCK_FABRIC"
    return "OTHER"


def proposed_fix(row: dict[str, str], net: str, family: str) -> str:
    if family.startswith("PHASE"):
        return "REVIEW_ONLY_DO_NOT_OVERBUFFER_RAW_RO_OR_PHASE_CLOCK_IN_GENUS"
    if "rst" in net.lower() or family == "RESET":
        return "BUFFER_TREE_OR_STRONGER_DRIVER_WITH_RECOVERY_REMOVAL_PROTOCOL_REVIEW"
    if family.startswith("PD_DETECT"):
        return "TARGETED_BUFFER_TREE_OR_STRONGER_INVERTER_DRIVER_LOCAL_MAX_FANOUT_16_OR_32"
    return "TARGETED_STRONGER_DRIVER_OR_BUFFER_TREE_KEEP_MAX_TRANSITION_500PS"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", type=Path, required=True)
    parser.add_argument("--out-csv", type=Path, required=True)
    args = parser.parse_args()

    drv_rows = parse_drv_rows(args.run_dir / "report_design_rules.rpt")
    hf_by_driver = parse_high_fanout(args.run_dir / "report_high_fanout.rpt")
    driver_cells = parse_driver_cells(args.run_dir / "mptdc_top_asic.postsyn.v")

    grouped: dict[str, dict[str, object]] = {}
    for row in drv_rows:
        pin = row["pin"]
        key = row.get("root_driver") or pin
        item = grouped.setdefault(
            key,
            {
                "driver_pin": key,
                "sinks": [],
                "worst_transition_ps": 0.0,
                "limit_ps": row["limit"],
                "violation_ps": 0.0,
            },
        )
        item["sinks"].append(pin)
        item["worst_transition_ps"] = max(float(item["worst_transition_ps"]), float(row["slew"]))
        item["violation_ps"] = max(float(item["violation_ps"]), float(row["violation"]))

    args.out_csv.parent.mkdir(parents=True, exist_ok=True)
    fields = [
        "net",
        "logical_name",
        "driver_inst",
        "driver_cell",
        "fanout",
        "worst_transition_ps",
        "limit_ps",
        "violation_ps",
        "sink_count",
        "sink_family",
        "proposed_fix",
    ]
    with args.out_csv.open("w", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=fields)
        writer.writeheader()
        for item in grouped.values():
            driver_pin = str(item["driver_pin"])
            hf = hf_by_driver.get(driver_pin, {})
            driver_inst = driver_pin.rsplit("/", 1)[0] if "/" in driver_pin else driver_pin
            families = [sink_family(pin) for pin in item["sinks"] if not pin.endswith("/Q")]
            family = max(set(families), key=families.count) if families else sink_family(driver_pin)
            net = hf.get("net", "UNKNOWN")
            logical = net
            if net.startswith("n_") and family.startswith("PD_DETECT"):
                logical = "PD_detect_enable_or_clear_derived_control"
            writer.writerow(
                {
                    "net": net,
                    "logical_name": logical,
                    "driver_inst": driver_inst,
                    "driver_cell": driver_cells.get(driver_inst, "UNKNOWN"),
                    "fanout": hf.get("fanout", "UNKNOWN"),
                    "worst_transition_ps": f"{float(item['worst_transition_ps']):.0f}",
                    "limit_ps": item["limit_ps"],
                    "violation_ps": f"{float(item['violation_ps']):.0f}",
                    "sink_count": len(item["sinks"]),
                    "sink_family": family,
                    "proposed_fix": proposed_fix({}, net, family),
                }
            )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
