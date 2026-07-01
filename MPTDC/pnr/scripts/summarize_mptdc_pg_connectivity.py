#!/usr/bin/env python3
"""Summarize Innovus VDD/VSS special-connectivity evidence.

This parser is intentionally lightweight.  It does not decide signoff status;
it turns verifyConnectivity/probe reports into a compact root-cause view that
is easier to compare across checkpoint repair runs.
"""

from __future__ import annotations

import argparse
import collections
import pathlib
import re
import sys
from typing import Iterable


PROBLEM_RE = re.compile(r"(\d+)\s+Problem\(s\)\s+\((IMPVFC-\d+)\):\s*(.*)")
PIN_RE = re.compile(
    r"^Net\s+(\S+),\s+Pin\s+Pin:\s+([^;]+);.*has an unconnected terminal",
    re.IGNORECASE,
)
NET_LINE_RE = re.compile(r"^Net\s+(\S+):\s*(.*)")
BOX_RE = re.compile(
    r"at\s+\(([0-9.+-]+),\s*([0-9.+-]+)\)\s+\(([0-9.+-]+),\s*([0-9.+-]+)\)"
)


def read_lines(path: pathlib.Path | None) -> list[str]:
    if path is None:
        return []
    try:
        return path.read_text(errors="replace").splitlines()
    except FileNotFoundError:
        return [f"REPORT_MISSING={path}"]


def add_example(bucket: dict[str, list[str]], key: str, line: str, max_examples: int) -> None:
    if len(bucket[key]) < max_examples:
        bucket[key].append(line)


def norm_inst_pin(raw: str) -> tuple[str, str]:
    raw = raw.strip()
    if "/" not in raw:
        return raw, ""
    inst, pin = raw.rsplit("/", 1)
    return inst, pin


def summarize_connectivity(lines: Iterable[str], max_examples: int) -> dict[str, object]:
    problem_counts: collections.Counter[str] = collections.Counter()
    problem_text: dict[str, str] = {}
    net_events: collections.Counter[tuple[str, str]] = collections.Counter()
    unconnected_by_net: collections.Counter[str] = collections.Counter()
    unconnected_by_pin: collections.Counter[str] = collections.Counter()
    unconnected_by_inst: collections.Counter[str] = collections.Counter()
    boxes_by_net: collections.Counter[str] = collections.Counter()
    examples: dict[str, list[str]] = collections.defaultdict(list)
    missing = []

    for raw in lines:
        line = raw.strip()
        if not line:
            continue
        if line.startswith("REPORT_MISSING="):
            missing.append(line.split("=", 1)[1])
            continue

        m = PROBLEM_RE.search(line)
        if m:
            count, code, text = m.groups()
            problem_counts[code] += int(count)
            problem_text.setdefault(code, text.strip())
            add_example(examples, code, line, max_examples)
            continue

        m = PIN_RE.search(line)
        if m:
            net, raw_pin = m.groups()
            inst, pin = norm_inst_pin(raw_pin)
            unconnected_by_net[net] += 1
            unconnected_by_pin[pin] += 1
            unconnected_by_inst[inst] += 1
            add_example(examples, f"PIN:{net}", line, max_examples)
            continue

        m = NET_LINE_RE.search(line)
        if m:
            net, msg = m.groups()
            msg_key = msg.split(".", 1)[0].strip()
            net_events[(net, msg_key)] += 1
            if BOX_RE.search(line):
                boxes_by_net[net] += 1
            add_example(examples, f"NET:{net}:{msg_key}", line, max_examples)

    return {
        "missing": missing,
        "problem_counts": problem_counts,
        "problem_text": problem_text,
        "net_events": net_events,
        "unconnected_by_net": unconnected_by_net,
        "unconnected_by_pin": unconnected_by_pin,
        "unconnected_by_inst": unconnected_by_inst,
        "boxes_by_net": boxes_by_net,
        "examples": examples,
    }


def summarize_probe(lines: Iterable[str]) -> dict[str, object]:
    counters: collections.Counter[str] = collections.Counter()
    marker_classes: collections.Counter[str] = collections.Counter()
    marker_subtypes: collections.Counter[str] = collections.Counter()
    in_markers = False

    for raw in lines:
        line = raw.rstrip("\n")
        if line == "RO_PG_MARKERS_BEGIN":
            in_markers = True
            continue
        if line == "RO_PG_MARKERS_END":
            in_markers = False
            continue
        if re.match(r"^[A-Z0-9_]+=", line):
            key, value = line.split("=", 1)
            if key.startswith("RO_PG_"):
                counters[f"{key}={value}"] += 1
        if not in_markers or line.startswith("idx\t"):
            continue
        fields = line.split("\t")
        if len(fields) >= 6:
            marker_classes[fields[1]] += 1
            marker_subtypes[fields[5]] += 1

    return {
        "probe_fields": counters,
        "marker_classes": marker_classes,
        "marker_subtypes": marker_subtypes,
    }


def write_counter(out: list[str], title: str, counter: collections.Counter, limit: int = 30) -> None:
    out.append("")
    out.append(f"## {title}")
    if not counter:
        out.append("none")
        return
    for key, count in counter.most_common(limit):
        out.append(f"{key}: {count}")


def build_report(args: argparse.Namespace) -> str:
    summary = summarize_connectivity(
        read_lines(args.summary) + read_lines(args.detail),
        args.max_examples,
    )
    probe = summarize_probe(read_lines(args.probe))

    out: list[str] = []
    out.append("# MPTDC PG Connectivity Summary")
    out.append("")
    out.append(f"summary_report={args.summary or ''}")
    out.append(f"detail_report={args.detail or ''}")
    out.append(f"probe_report={args.probe or ''}")

    if summary["missing"]:
        out.append("")
        out.append("## Missing Inputs")
        out.extend(str(path) for path in summary["missing"])

    problem_counts = summary["problem_counts"]
    problem_text = summary["problem_text"]
    out.append("")
    out.append("## IMPVFC Problem Counts")
    if problem_counts:
        for code, count in problem_counts.most_common():
            out.append(f"{code}: {count} - {problem_text.get(code, '')}")
    else:
        out.append("none")

    write_counter(out, "Unconnected Terminals By Net", summary["unconnected_by_net"])
    write_counter(out, "Unconnected Terminals By Pin Name", summary["unconnected_by_pin"])
    write_counter(out, "Top Unconnected Instances", summary["unconnected_by_inst"], limit=40)
    write_counter(out, "Net Event Classes", summary["net_events"], limit=50)
    write_counter(out, "Coordinate-Bearing Net Lines", summary["boxes_by_net"])
    write_counter(out, "Probe Marker Classes", probe["marker_classes"])
    write_counter(out, "Probe Marker Subtypes", probe["marker_subtypes"])

    out.append("")
    out.append("## Probe Fields")
    if probe["probe_fields"]:
        for field in sorted(probe["probe_fields"]):
            out.append(field)
    else:
        out.append("none")

    examples = summary["examples"]
    out.append("")
    out.append("## Examples")
    if not examples:
        out.append("none")
    else:
        for key in sorted(examples):
            out.append("")
            out.append(f"### {key}")
            out.extend(examples[key])

    return "\n".join(out) + "\n"


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--summary", type=pathlib.Path, help="verifyConnectivity summary report")
    parser.add_argument("--detail", type=pathlib.Path, help="verifyConnectivity detailed report")
    parser.add_argument("--probe", type=pathlib.Path, help="filtered_ro_pg_probe.rpt")
    parser.add_argument("--out", type=pathlib.Path, help="Output report path")
    parser.add_argument("--max-examples", type=int, default=12)
    args = parser.parse_args(argv)

    report = build_report(args)
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(report)
    else:
        sys.stdout.write(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
