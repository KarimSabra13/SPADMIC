#!/usr/bin/env python3
"""Parse checked-in Genus reports without requiring Cadence tools."""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


PATH_RE = re.compile(
    r"^Path\s+(?P<idx>\d+):\s+(?P<status>\S+)\s+\((?P<slack>-?\d+(?:\.\d+)?)\s+ps\)"
)


def read_text(path: Path) -> str:
    try:
        return path.read_text(errors="replace")
    except FileNotFoundError:
        return ""


def parse_timing_summary(run_dir: Path) -> dict[str, Any]:
    text = read_text(run_dir / "timing_summary.rpt")
    groups: dict[str, dict[str, Any]] = {}
    total: dict[str, Any] = {}
    instance_counts: dict[str, int] = {}
    area: dict[str, float] = {}
    power: dict[str, float] = {}
    max_fanout: dict[str, Any] = {}

    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("-"):
            continue

        parts = line.split()
        if parts and parts[0] == "wc_view":
            parts = parts[1:]

        if parts and parts[0].startswith("clk_"):
            if len(parts) >= 5 and parts[1] == "No" and parts[2] == "paths":
                groups[parts[0]] = {"wns_ps": None, "tns_ps": float(parts[3]), "paths": int(parts[4])}
            elif len(parts) >= 4:
                try:
                    groups[parts[0]] = {
                        "wns_ps": float(parts[1]),
                        "tns_ps": float(parts[2]),
                        "paths": int(parts[3]),
                    }
                except ValueError:
                    pass
        elif parts and parts[0] == "Total" and len(parts) >= 3:
            try:
                total = {"tns_ps": float(parts[1]), "paths": int(parts[2])}
            except ValueError:
                pass

        count_match = re.match(r"^(Leaf|Physical|Sequential|Combinational|Hierarchical) Instance Count\s+(\d+)", line)
        if count_match:
            instance_counts[count_match.group(1).lower()] = int(count_match.group(2))

        area_match = re.match(r"^(Cell Area|Physical Cell Area|Total Cell Area .*|Net Area|Total Area .*)\s+(-?\d+(?:\.\d+)?)", line)
        if area_match:
            area[area_match.group(1)] = float(area_match.group(2))

        power_match = re.match(r"^(Leakage Power|Dynamic Power|Total Power)\s+(-?\d+(?:\.\d+)?)", line)
        if power_match:
            power[power_match.group(1)] = float(power_match.group(2))

        fanout_match = re.match(r"^Max Fanout\s+(\d+)\s+\((.+)\)", line)
        if fanout_match:
            max_fanout = {"fanout": int(fanout_match.group(1)), "net": fanout_match.group(2)}

    return {
        "groups": groups,
        "total": total,
        "instance_counts": instance_counts,
        "area": area,
        "power": power,
        "max_fanout": max_fanout,
    }


def classify_path(path: dict[str, Any]) -> str:
    group = path.get("group") or ""
    start_clock = path.get("start_clock") or ""
    end_clock = path.get("end_clock") or ""
    start = path.get("startpoint") or ""
    end = path.get("endpoint") or ""
    joined = " ".join([group, start_clock, end_clock, start, end]).lower()

    if group == "clk_sys" and start_clock == "clk_sys" and end_clock == "clk_sys":
        return "A_real_clk_sys_setup"
    if "u_hit_capture_bridge" in joined and end_clock == "clk_sys":
        return "E_held_static_bus_cdc"
    if "clear" in joined or "async_clr" in joined or "/rn" in joined or "/clr" in joined:
        return "F_async_clear_recovery"
    if group.startswith("clk_osc") or "gen_pd_row" in joined or "u_pd" in joined:
        return "D_oscillator_pd_measurement"
    if "start_async" in joined or "stop_async" in joined or "u_frontend" in joined:
        return "C_async_start_stop"
    if group == "clk_sys":
        return "A_real_clk_sys_setup"
    return "unclassified"


def parse_paths(report_path: Path) -> list[dict[str, Any]]:
    paths: list[dict[str, Any]] = []
    current: dict[str, Any] | None = None
    clock_seen = 0

    for raw in read_text(report_path).splitlines():
        line = raw.rstrip()
        match = PATH_RE.match(line.strip())
        if match:
            if current is not None:
                current["bucket"] = classify_path(current)
                paths.append(current)
            current = {
                "path": int(match.group("idx")),
                "status": match.group("status"),
                "slack_ps": float(match.group("slack")),
                "report": str(report_path),
            }
            clock_seen = 0
            continue

        if current is None:
            continue

        stripped = line.strip()
        if stripped.startswith("Group:"):
            current["group"] = stripped.split(":", 1)[1].strip()
        elif stripped.startswith("Startpoint:"):
            current["startpoint"] = stripped.split(":", 1)[1].strip()
        elif stripped.startswith("Endpoint:"):
            current["endpoint"] = stripped.split(":", 1)[1].strip()
        elif stripped.startswith("Clock:"):
            clock = stripped.split(":", 1)[1].strip()
            clock_name = clock.split()[-1]
            if clock_seen == 0:
                current["start_clock"] = clock_name
            else:
                current["end_clock"] = clock_name
            clock_seen += 1
        elif "Data Path:-" in stripped:
            try:
                current["data_path_ps"] = float(stripped.split("Data Path:-", 1)[1].split()[0])
            except (IndexError, ValueError):
                pass

    if current is not None:
        current["bucket"] = classify_path(current)
        paths.append(current)

    return paths


def parse_latch_audit(run_dir: Path) -> dict[str, Any]:
    text = read_text(run_dir / "latch_audit.rpt")
    count = None
    instances: list[str] = []
    for line in text.splitlines():
        if line.startswith("Count:"):
            try:
                count = int(line.split(":", 1)[1].strip())
            except ValueError:
                pass
        elif line.startswith("u_"):
            instances.append(line.split()[0])
    return {"count": count, "instances": instances}


def parse_design_rules(run_dir: Path) -> dict[str, Any]:
    text = read_text(run_dir / "report_design_rules.rpt")
    result: dict[str, Any] = {}
    for line in text.splitlines():
        match = re.search(r"(Max_\w+) design rule \(violation total = (\d+)\)", line)
        if match:
            result[match.group(1).lower()] = int(match.group(2))
    return result


def parse_timing_intent(run_dir: Path) -> dict[str, int]:
    text = read_text(run_dir / "check_timing_intent.rpt")
    counts: dict[str, int] = {}
    for line in text.splitlines():
        match = re.match(r"\s*([A-Za-z][A-Za-z /-]+?)\s+(\d+)\s*$", line)
        if match:
            key = " ".join(match.group(1).split()).lower().replace(" ", "_").replace("/", "_")
            counts[key] = int(match.group(2))
    return counts


def summarize_paths(paths: list[dict[str, Any]]) -> dict[str, Any]:
    by_group = Counter(p.get("group", "unknown") for p in paths)
    by_bucket = Counter(p.get("bucket", "unknown") for p in paths)
    endpoints = Counter(p.get("endpoint", "unknown") for p in paths)
    startpoints = Counter(p.get("startpoint", "unknown") for p in paths)

    top_by_group: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for path in paths:
        group = path.get("group", "unknown")
        if len(top_by_group[group]) < 5:
            top_by_group[group].append(path)

    return {
        "path_count": len(paths),
        "by_group": dict(by_group),
        "by_bucket": dict(by_bucket),
        "top_endpoints": endpoints.most_common(10),
        "top_startpoints": startpoints.most_common(10),
        "top_by_group": dict(top_by_group),
    }


def parse_run(run_dir: Path) -> dict[str, Any]:
    path_reports = [
        run_dir / "timing_violations.rpt",
        run_dir / "timing_fast_count_to_nfast_hit.rpt",
        run_dir / "timing_clk_sys_full_clock.rpt",
        run_dir / "timing_clk_sys_violations.rpt",
        run_dir / "timing_meas_ctrl_hotspots.rpt",
        run_dir / "timing_context_bank_hotspots.rpt",
        run_dir / "timing_drain_ctrl_hotspots.rpt",
        run_dir / "timing_fifo_hotspots.rpt",
    ]
    paths: list[dict[str, Any]] = []
    for report in path_reports:
        if report.exists():
            paths.extend(parse_paths(report))

    return {
        "run_dir": str(run_dir),
        "timing_summary": parse_timing_summary(run_dir),
        "paths": summarize_paths(paths),
        "latch_audit": parse_latch_audit(run_dir),
        "design_rules": parse_design_rules(run_dir),
        "timing_intent": parse_timing_intent(run_dir),
    }


def print_markdown(data: dict[str, Any]) -> None:
    print(f"# Genus Summary: `{Path(data['run_dir']).name}`")
    print()
    print("## Timing Groups")
    groups = data["timing_summary"]["groups"]
    if not groups:
        print()
        print("- No timing group table parsed.")
    else:
        print()
        print("| Group | WNS (ps) | TNS (ps) | Paths |")
        print("|---|---:|---:|---:|")
        for group, row in sorted(groups.items(), key=lambda item: (item[1]["wns_ps"] is None, item[1]["wns_ps"] or 0.0)):
            wns = "No paths" if row["wns_ps"] is None else f"{row['wns_ps']:.1f}"
            print(f"| `{group}` | {wns} | {row['tns_ps']:.1f} | {row['paths']} |")

    total = data["timing_summary"].get("total", {})
    if total:
        print()
        print(f"Total TNS: `{total.get('tns_ps')}` ps, violating paths: `{total.get('paths')}`")

    fanout = data["timing_summary"].get("max_fanout", {})
    if fanout:
        print(f"Max fanout: `{fanout.get('fanout')}` on `{fanout.get('net')}`")

    print()
    print("## Detailed Path Coverage")
    paths = data["paths"]
    print()
    print(f"- Parsed detailed paths: `{paths['path_count']}`")
    print(f"- Detailed paths by group: `{paths['by_group']}`")
    print(f"- Detailed paths by bucket: `{paths['by_bucket']}`")
    if "clk_sys" not in paths["by_group"] and groups.get("clk_sys", {}).get("paths", 0):
        print("- `clk_sys` has summary violations, but no detailed `clk_sys` paths were present in parsed reports.")

    latch = data["latch_audit"]
    print()
    print("## Latch/DRV/Intent")
    print()
    print(f"- Latch count: `{latch.get('count')}`")
    print(f"- DRV totals: `{data['design_rules']}`")
    print(f"- Timing-intent counts: `{data['timing_intent']}`")

    if latch.get("instances"):
        print()
        print("Intentional latch instances parsed:")
        for inst in latch["instances"]:
            print(f"- `{inst}`")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("run_dir", type=Path, help="results/genus/<RUN_ID> directory")
    parser.add_argument("--json", action="store_true", help="emit JSON instead of Markdown")
    args = parser.parse_args()

    data = parse_run(args.run_dir)
    if args.json:
        print(json.dumps(data, indent=2, sort_keys=True))
    else:
        print_markdown(data)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
