#!/usr/bin/env python3
"""Classify MPTDC timing paths for oscillator/PD signoff review."""

from __future__ import annotations

import argparse
import csv
import re
from collections import Counter
from pathlib import Path


PATH_RE = re.compile(r"^Path\s+(\d+):\s+(\S+)\s+\((-?\d+(?:\.\d+)?)\s+ps\)")


def norm(value: str) -> str:
    return value.lower()


def read_text(path: Path) -> str:
    try:
        return path.read_text(errors="replace")
    except FileNotFoundError:
        return ""


def is_pd_vernier_sampler(row: dict[str, str]) -> bool:
    start_clock = row.get("start_clock", "")
    end_clock = row.get("end_clock", "")
    startpoint = norm(row.get("startpoint", ""))
    endpoint = norm(row.get("endpoint", ""))
    group = row.get("group", "")

    source_is_slow_phase = (
        start_clock.startswith("clk_osc_slow_buf_tap")
        or "u_phase_buf_slow" in startpoint
        or "slow_phase" in startpoint
    )
    dest_is_fast_pd_q1 = (
        end_clock.startswith("clk_osc_fast_buf_tap")
        and group.startswith("clk_osc_fast_buf_tap")
        and "gen_pd_row" in endpoint
        and "gen_pd_col" in endpoint
        and "u_pd" in endpoint
        and "q1_reg" in endpoint
        and endpoint.endswith("/d")
    )
    return source_is_slow_phase and dest_is_fast_pd_q1


def classify(row: dict[str, str]) -> str:
    text = " ".join(row.values()).lower()
    group = row.get("group", "")
    start_clock = row.get("start_clock", "")
    end_clock = row.get("end_clock", "")
    start_is_sys = start_clock == "clk_sys"
    end_is_sys = end_clock == "clk_sys"
    start_is_osc = start_clock.startswith("clk_osc_")
    end_is_osc = end_clock.startswith("clk_osc_")
    if is_pd_vernier_sampler(row):
        return "PD_INTENTIONAL_VERNIER"
    if (start_is_sys and end_is_osc) or (start_is_osc and end_is_sys):
        if "u_hit_capture_bridge" in text or "snapshot" in text or "held" in text:
            return "HELD_BUS_CDC"
        return "UNKNOWN_REVIEW_REQUIRED"
    if group == "clk_sys" and start_clock == "clk_sys" and end_clock == "clk_sys":
        return "CLK_SYS_REAL"
    if "u_pd" in text or "gen_pd_row" in text:
        if "slow_phase" in text and "fast_phase" in text:
            return "PD_INTENTIONAL_VERNIER"
        if start_clock.startswith("clk_osc_fast") and end_clock.startswith("clk_osc_fast"):
            return "OSC_FAST_REAL"
        return "UNKNOWN_REVIEW_REQUIRED"
    if "u_fast_cnt" in text or "nfast_src_count" in text or "nfast_hit" in text:
        return "OSC_FAST_REAL"
    if "u_slow_cnt" in text or "start_wdt_cnt" in text:
        return "OSC_SLOW_REAL"
    if "clear" in text or "async_clr" in text or "/rn" in text or "/clr" in text:
        return "PD_CLEAR_RECOVERY_REMOVAL"
    if "u_hit_capture_bridge" in text:
        return "OSC_TO_SYS_HELD_BUS_CDC"
    if "u_stop_capture" in text or "stop_async" in text or "start_async" in text or "u_frontend" in text:
        return "STOP_EVENT_CAPTURE"
    if group == "clk_sys" or start_clock == "clk_sys" or end_clock == "clk_sys":
        return "CLK_SYS_REAL"
    if group.startswith("clk_osc_fast") or start_clock.startswith("clk_osc_fast") or end_clock.startswith("clk_osc_fast"):
        return "OSC_FAST_REAL"
    if group.startswith("clk_osc_slow") or start_clock.startswith("clk_osc_slow") or end_clock.startswith("clk_osc_slow"):
        return "OSC_SLOW_REAL"
    if "no paths" in text or "not generated" in text:
        return "CONSTRAINT_ARTIFACT"
    return "UNKNOWN_REVIEW_REQUIRED"


def classify_family(row: dict[str, str]) -> str:
    text = " ".join(row.values()).lower()
    start_clock = row.get("start_clock", "")
    end_clock = row.get("end_clock", "")
    if row.get("classification") == "PD_INTENTIONAL_VERNIER":
        return "PD_SLOW_PHASE_SAMPLED_BY_FAST_PD"
    if "u_phase_buf" in text or "phase_buffer" in text:
        if start_clock.startswith("clk_osc_") and end_clock.startswith("clk_osc_"):
            return "PHASE_BUFFER_CHAIN"
    if "q1_reg" in text and "q2_reg" in text:
        return "PD_Q1_TO_Q2_LOCAL_FAST"
    if "q1_reg" in text and row.get("endpoint", "").lower().endswith("q1_reg/d"):
        return "PD_Q1_LOCAL_FAST_CONTROL"
    if "hit_latched_reg" in text and row.get("endpoint", "").lower().endswith("hit_latched_reg/d"):
        return "PD_HIT_LATCH_LOCAL_FAST"
    if "nfast_hit_latched" in text:
        return "FAST_TAG_TO_PD_TS"
    if "hit_latched" in text and ("q1_reg" in text or "q2_reg" in text):
        return "PD_HIT_TO_TS_FREEZE"
    if "u_fast_tag" in text or "gen_fast_tag_col" in text:
        return "LOCAL_FAST_TAG_SELF"
    if start_clock == "clk_sys" and end_clock == "clk_sys":
        if "u_drain_ctrl" in text or "drain" in text or "fifo" in text:
            return "CLK_SYS_DRAIN"
        if "watchdog" in text or "wdt" in text:
            return "CLK_SYS_WATCHDOG"
        return "CLK_SYS_OTHER"
    if row.get("classification") == "HELD_BUS_CDC":
        return "HELD_BUS_CDC"
    return "OTHER"


def review_status(row: dict[str, str]) -> str:
    classification = row.get("classification", "UNKNOWN_REVIEW_REQUIRED")
    if classification == "PD_INTENTIONAL_VERNIER":
        return "INTENTIONAL_MEASUREMENT_CROSSING"
    if classification == "UNKNOWN_REVIEW_REQUIRED":
        return "REVIEW_REQUIRED"
    if classification in {"HELD_BUS_CDC", "OSC_TO_SYS_HELD_BUS_CDC"}:
        return "CDC_CONTRACT_REVIEW"
    if classification in {"OSC_FAST_REAL", "OSC_SLOW_REAL", "CLK_SYS_REAL"}:
        return "REAL_TIMING"
    return "CLASSIFIED"


def slack_ps(row: dict[str, str]) -> float:
    try:
        return float(row.get("slack_ps", "0"))
    except ValueError:
        return 0.0


def summarize_metric(rows: list[dict[str, str]], key: str) -> list[tuple[str, int, float, float]]:
    groups: dict[str, list[float]] = {}
    for row in rows:
        groups.setdefault(row.get(key, "UNKNOWN"), []).append(slack_ps(row))
    out: list[tuple[str, int, float, float]] = []
    for name, slacks in groups.items():
        if not slacks:
            continue
        wns = min(slacks)
        tns = sum(slack for slack in slacks if slack < 0)
        out.append((name, len(slacks), wns, tns))
    out.sort(key=lambda item: (item[2], item[0]))
    return out


def parse_report(path: Path) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    current: dict[str, str] | None = None
    clock_seen = 0
    for raw in read_text(path).splitlines():
        line = raw.strip()
        match = PATH_RE.match(line)
        if match:
            if current:
                current["classification"] = classify(current)
                current["family"] = classify_family(current)
                current["review_status"] = review_status(current)
                rows.append(current)
            current = {
                "report": str(path),
                "path": match.group(1),
                "status": match.group(2),
                "slack_ps": match.group(3),
                "group": "",
                "startpoint": "",
                "endpoint": "",
                "start_clock": "",
                "end_clock": "",
            }
            clock_seen = 0
            continue
        if current is None:
            continue
        if line.startswith("Group:"):
            current["group"] = line.split(":", 1)[1].strip()
        elif line.startswith("Startpoint:"):
            current["startpoint"] = line.split(":", 1)[1].strip()
        elif line.startswith("Endpoint:"):
            current["endpoint"] = line.split(":", 1)[1].strip()
        elif line.startswith("Clock:"):
            clock = line.split(":", 1)[1].strip().split()[-1]
            if clock_seen == 0:
                current["start_clock"] = clock
            else:
                current["end_clock"] = clock
            clock_seen += 1
    if current:
        current["classification"] = classify(current)
        current["family"] = classify_family(current)
        current["review_status"] = review_status(current)
        rows.append(current)
    return rows


def write_summary(rows: list[dict[str, str]], path: Path) -> None:
    counts = Counter(r["classification"] for r in rows)
    lines = [
        "# Timing Path Classification Summary",
        "",
        f"- Parsed paths: {len(rows)}",
        f"- UNKNOWN_REVIEW_REQUIRED paths: {counts.get('UNKNOWN_REVIEW_REQUIRED', 0)}",
        "",
        "## WNS/TNS By Class",
        "",
        "| Classification | Paths | WNS ps | TNS ps |",
        "|---|---:|---:|---:|",
    ]
    for key, count, wns, tns in summarize_metric(rows, "classification"):
        lines.append(f"| `{key}` | {count} | {wns:.1f} | {tns:.1f} |")
    lines.extend([
        "",
        "## WNS/TNS By Family",
        "",
        "| Family | Paths | WNS ps | TNS ps |",
        "|---|---:|---:|---:|",
    ])
    for key, count, wns, tns in summarize_metric(rows, "family"):
        lines.append(f"| `{key}` | {count} | {wns:.1f} | {tns:.1f} |")
    lines.extend(["", "## Top Unknown Paths", ""])
    unknown = [r for r in rows if r["classification"] == "UNKNOWN_REVIEW_REQUIRED"]
    if not unknown:
        lines.append("- None")
    else:
        for row in unknown[:20]:
            lines.append(
                f"- {row.get('report')} path {row.get('path')}: slack={row.get('slack_ps')} ps, "
                f"group={row.get('group')}, start=`{row.get('startpoint')}`, end=`{row.get('endpoint')}`"
            )
    path.write_text("\n".join(lines) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("reports", nargs="+", type=Path)
    parser.add_argument("--out-csv", type=Path, required=True)
    parser.add_argument("--out-summary", type=Path, required=True)
    args = parser.parse_args()

    rows: list[dict[str, str]] = []
    for report in args.reports:
        rows.extend(parse_report(report))
    args.out_csv.parent.mkdir(parents=True, exist_ok=True)
    fields = ["classification", "family", "review_status", "report", "path", "status", "slack_ps", "group", "start_clock", "end_clock", "startpoint", "endpoint"]
    with args.out_csv.open("w", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=fields)
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fields})
    write_summary(rows, args.out_summary)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
