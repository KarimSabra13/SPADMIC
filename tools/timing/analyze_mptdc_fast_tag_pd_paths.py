#!/usr/bin/env python3
"""Build a focused FAST_TAG_TO_PD_TS timing review from Genus reports."""

from __future__ import annotations

import argparse
import csv
import re
from pathlib import Path


PATH_START_RE = re.compile(r"^Path\s+(\d+):")
DATA_RE = re.compile(r"Data Path:-\s+(-?\d+(?:\.\d+)?)")
SETUP_RE = re.compile(r"Setup:-\s+(-?\d+(?:\.\d+)?)")
LATENCY_RE = re.compile(r"Net Latency:\+\s+(-?\d+(?:\.\d+)?)")
POINT_RE = re.compile(
    r"^\s+(?P<point>\S.*?)\s+-\s+(?P<arc>\S+)\s+(?P<edge>\S+)\s+"
    r"(?P<cell>\S+)\s+(?P<fanout>\d+)\s+(?P<load>-|\d+(?:\.\d+)?)\s+"
    r"(?P<trans>-|\d+(?:\.\d+)?)\s+(?P<delay>-?\d+(?:\.\d+)?)\s+"
    r"(?P<arrival>-?\d+(?:\.\d+)?)\s*$"
)
INST_RE = re.compile(r"^\s*(?P<cell>\S+)\s+(?P<inst>\\?\S+)\s*\(")


def read_text(path: Path) -> str:
    try:
        return path.read_text(errors="replace")
    except FileNotFoundError:
        return ""


def parse_blocks(path: Path) -> dict[str, str]:
    blocks: dict[str, list[str]] = {}
    current: str | None = None
    for line in read_text(path).splitlines():
        match = PATH_START_RE.match(line.strip())
        if match:
            current = match.group(1)
            blocks[current] = [line]
            continue
        if current is not None:
            blocks[current].append(line)
    return {key: "\n".join(value) for key, value in blocks.items()}


def parse_point_rows(block: str) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for line in block.splitlines():
        match = POINT_RE.match(line)
        if match:
            rows.append(match.groupdict())
    return rows


def canonical(value: str) -> str:
    return re.sub(r"[^a-z0-9\[\]]+", "", value.lower().replace("\\", ""))


def cell_basename(cell: str) -> str:
    return cell.rsplit("/", 1)[-1]


def infer_role(inst: str) -> str:
    low = inst.lower()
    if "nfast_hit_latched_reg" in low:
        return "nfast_hit_endpoint"
    if "fast_tag" in low and "tag_o_reg" in low:
        return "fast_tag_source"
    if "fast_tag" in low and "_reg" in low:
        return "local_tag_feedback"
    return ""


def parse_netlist_instances(path: Path) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for raw in read_text(path).splitlines():
        match = INST_RE.match(raw)
        if not match:
            continue
        inst = match.group("inst").lstrip("\\")
        role = infer_role(inst)
        if not role:
            continue
        rows.append(
            {
                "instance": inst,
                "mapped_cell": cell_basename(match.group("cell")),
                "tap_index": infer_tap(inst),
                "bit_index": infer_tag_bit(inst),
                "role": role,
            }
        )
    return rows


def inst_from_pin(value: str) -> str:
    text = value.strip().lstrip("\\")
    if "/" not in text:
        return text
    return text.rsplit("/", 1)[0].lstrip("\\")


def cell_from_mapping(pin: str, role: str, mapping_rows: list[dict[str, str]]) -> str:
    inst = canonical(inst_from_pin(pin))
    for row in mapping_rows:
        if row.get("role") != role:
            continue
        mapped_inst = canonical(row.get("instance", ""))
        if mapped_inst and (mapped_inst == inst or mapped_inst in inst or inst in mapped_inst):
            return row.get("mapped_cell", "")
    tap = infer_tap(pin)
    bit = infer_tag_bit(pin)
    if tap != "unknown" and bit != "unknown":
        for row in mapping_rows:
            if row.get("role") == role and row.get("tap_index") == tap and row.get("bit_index") == bit:
                return row.get("mapped_cell", "")
    return ""


def infer_tap(*names: str) -> str:
    text = " ".join(names)
    for pattern in (r"gen_pd_col\[([0-7])\]", r"gen_fast_tag_col\[([0-7])\]", r"buf_tap([0-7])"):
        match = re.search(pattern, text)
        if match:
            return match.group(1)
    return "unknown"


def infer_tag_bit(*names: str) -> str:
    text = " ".join(names)
    for pattern in (r"nfast_hit_latched_reg\[([0-9]+)\]", r"tag_o_reg\[([0-9]+)\]"):
        match = re.search(pattern, text)
        if match:
            return match.group(1)
    return "unknown"


def infer_row_col(endpoint: str) -> tuple[str, str]:
    row = re.search(r"gen_pd_row\[([0-7])\]", endpoint)
    col = re.search(r"gen_pd_col\[([0-7])\]", endpoint)
    return (row.group(1) if row else "NA", col.group(1) if col else "NA")


def dominant_component(source_q: dict[str, str] | None, data_path: str) -> str:
    if not source_q or data_path == "NA":
        return "UNKNOWN"
    try:
        cq = float(source_q["delay"])
        data = float(data_path)
    except ValueError:
        return "UNKNOWN"
    if data <= 0:
        return "UNKNOWN"
    ratio = cq / data
    if ratio >= 0.60:
        return "SOURCE_CQ_DOMINATED"
    if ratio >= 0.40:
        return "SOURCE_CQ_PLUS_LOCAL_LOGIC"
    return "LOCAL_LOGIC_OR_WIRE_DOMINATED"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", type=Path, required=True)
    parser.add_argument("--out-md", type=Path, required=True)
    parser.add_argument("--limit", type=int, default=50)
    args = parser.parse_args()

    csv_path = args.run_dir / "timing_path_classification.csv"
    timing_path = args.run_dir / "timing_violations.rpt"
    rows: list[dict[str, str]] = []
    with csv_path.open(newline="") as fh:
        for row in csv.DictReader(fh):
            if Path(row.get("report", "")).name != "timing_violations.rpt":
                continue
            if row.get("family") not in {"FAST_TAG_TO_PD_TS", "LOCAL_FAST_TAG_SELF"}:
                continue
            try:
                if float(row.get("slack_ps", "0")) >= 0:
                    continue
            except ValueError:
                continue
            rows.append(row)
    rows = rows[: args.limit]
    blocks = parse_blocks(timing_path)
    netlist = args.run_dir / "mptdc_top_asic.postsyn.v"
    if not netlist.exists():
        netlist = args.run_dir / "outputs" / "mptdc_top_asic.postsyn.v"
    mapping_rows = parse_netlist_instances(netlist)

    lines = [
        "# Final Genus FAST_TAG_TO_PD_TS Analysis",
        "",
        f"- Run directory: `{args.run_dir}`",
        f"- Source CSV: `{csv_path}`",
        f"- Source timing report: `{timing_path}`",
        f"- Rows analyzed: `{len(rows)}`",
        "",
        "This is real fast oscillator-domain setup timing. It is not CDC, not the intentional PD Vernier crossing, and not a candidate for false-path or multicycle relaxation.",
        "",
        "## Top Violating Paths",
        "",
        "| Path | Family | Slack ps | Tap | Tag Bit | Start Cell | Endpoint Cell | Row | Col | Data Path ps | Clock Path ps | Setup ps | Source Fanout | Source Load fF | Source Trans ps | Freeze Mux | Dominant Term |",
        "|---:|---|---:|---:|---:|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---|",
    ]
    for row in rows:
        block = blocks.get(row["path"], "")
        points = parse_point_rows(block)
        source_q = next((p for p in points if p["point"].endswith("/Q") and "tag_o_reg" in p["point"]), None)
        endpoint_point = next((p for p in reversed(points) if p["point"].endswith("/D")), None)
        data_match = DATA_RE.search(block)
        setup_match = SETUP_RE.search(block)
        latencies = LATENCY_RE.findall(block)
        data_path = data_match.group(1) if data_match else "NA"
        setup = setup_match.group(1) if setup_match else "NA"
        clock_path = "0"
        if latencies:
            clock_path = "/".join(latencies[:2])
        start = row.get("startpoint", "")
        endpoint = row.get("endpoint", "")
        tap = infer_tap(start, endpoint, row.get("group", ""))
        bit = infer_tag_bit(start, endpoint)
        row_idx, col_idx = infer_row_col(endpoint)
        start_cell = source_q["cell"] if source_q else cell_from_mapping(start, "fast_tag_source", mapping_rows)
        if not start_cell:
            start_cell = cell_from_mapping(endpoint, "fast_tag_source", mapping_rows)
        endpoint_cell = endpoint_point["cell"] if endpoint_point else cell_from_mapping(endpoint, "nfast_hit_endpoint", mapping_rows)
        if not start_cell:
            start_cell = "UNKNOWN"
        if not endpoint_cell:
            endpoint_cell = "UNKNOWN"
        fanout = source_q["fanout"] if source_q else "NA"
        load = source_q["load"] if source_q else "NA"
        trans = source_q["trans"] if source_q else "NA"
        freeze_mux = "YES" if "nfast_hit_latched" in endpoint else "NO"
        lines.append(
            "| {path} | `{family}` | {slack} | {tap} | {bit} | `{start_cell}` | `{endpoint_cell}` | {row} | {col} | {data_path} | {clock_path} | {setup} | {fanout} | {load} | {trans} | {freeze_mux} | {dominant} |".format(
                path=row["path"],
                family=row["family"],
                slack=row["slack_ps"],
                tap=tap,
                bit=bit,
                start_cell=start_cell,
                endpoint_cell=endpoint_cell,
                row=row_idx,
                col=col_idx,
                data_path=data_path,
                clock_path=clock_path,
                setup=setup,
                fanout=fanout,
                load=load,
                trans=trans,
                freeze_mux=freeze_mux,
                dominant=dominant_component(source_q, data_path),
            )
        )
    lines.extend(
        [
            "",
            "## Repair Direction",
            "",
            "- Keep these paths timed in the fast buffered phase clock domains.",
            "- If source cells are already strong and WNS is unchanged, pivot to exact local datapath/library pressure before considering endpoint or local buffering.",
            "- Do not alter the O13 PD Vernier exception; it applies to slow buffered phase sources into q1 endpoints, not these nfast tag paths.",
        ]
    )
    args.out_md.parent.mkdir(parents=True, exist_ok=True)
    args.out_md.write_text("\n".join(lines) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
