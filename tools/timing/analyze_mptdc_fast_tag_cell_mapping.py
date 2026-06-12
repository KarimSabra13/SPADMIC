#!/usr/bin/env python3
"""Report fast-tag source and nfast endpoint cell mapping guardrails."""

from __future__ import annotations

import argparse
import csv
import re
import shlex
from collections import Counter
from pathlib import Path


PATH_START_RE = re.compile(r"^Path\s+(\d+):")
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


def canonical(value: str) -> str:
    return re.sub(r"[^a-z0-9\[\]]+", "", value.lower().replace("\\", ""))


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
    return [match.groupdict() for line in block.splitlines() if (match := POINT_RE.match(line))]


def parse_netlist_instances(path: Path) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for raw in read_text(path).splitlines():
        match = INST_RE.match(raw)
        if not match:
            continue
        cell = match.group("cell")
        inst = match.group("inst").lstrip("\\")
        role = infer_role(inst)
        if role:
            rows.append(
                {
                    "instance": inst,
                    "tap_index": infer_tap(inst),
                    "bit_index": infer_bit(inst),
                    "mapped_cell": cell,
                    "drive_strength": infer_drive_strength(cell),
                    "role": role,
                }
            )
    return rows


def infer_role(inst: str) -> str:
    low = inst.lower()
    if "nfast_hit_latched_reg" in low:
        return "nfast_hit_endpoint"
    if "fast_tag" in low and "tag_o_reg" in low:
        return "fast_tag_source"
    if "fast_tag" in low and "_reg" in low:
        return "local_tag_feedback"
    return ""


def infer_tap(name: str) -> str:
    for pattern in (
        r"gen_fast_tag_col\[([0-7])\]",
        r"gen_pd_col\[([0-7])\]",
        r"buf_tap([0-7])",
    ):
        match = re.search(pattern, name)
        if match:
            return match.group(1)
    return "NA"


def infer_bit(name: str) -> str:
    for pattern in (
        r"tag_o_reg(?:_reg)?\[([0-9]+)\]",
        r"nfast_hit_latched_reg\[([0-9]+)\]",
    ):
        match = re.search(pattern, name)
        if match:
            return match.group(1)
    return "NA"


def cell_basename(cell: str) -> str:
    return cell.rsplit("/", 1)[-1]


def infer_drive_strength(cell: str) -> str:
    match = re.search(r"HDX([0-9]+)$", cell)
    return match.group(1) if match else "NA"


def parse_top_fast_paths(path: Path) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    if not path.exists():
        return rows
    with path.open(newline="") as fh:
        for row in csv.DictReader(fh):
            if Path(row.get("report", "")).name != "timing_violations.rpt":
                continue
            if row.get("family") != "FAST_TAG_TO_PD_TS":
                continue
            try:
                if float(row.get("slack_ps", "0")) >= 0:
                    continue
            except ValueError:
                continue
            rows.append(row)
    return rows


def inst_from_pin(value: str) -> str:
    if not value:
        return ""
    text = value.strip().lstrip("\\")
    if "/" not in text:
        return text
    return text.rsplit("/", 1)[0].lstrip("\\")


def source_cell_from_mapping(row: dict[str, str], mapping_rows: list[dict[str, str]]) -> str:
    start_inst = canonical(inst_from_pin(row.get("startpoint", "")))
    start_text = row.get("startpoint", "")
    if start_inst:
        for mapping in mapping_rows:
            if mapping.get("role") != "fast_tag_source":
                continue
            mapped_inst = canonical(mapping.get("instance", ""))
            if mapped_inst and (mapped_inst == start_inst or mapped_inst in start_inst or start_inst in mapped_inst):
                return cell_basename(mapping.get("mapped_cell", ""))
    start_tap = infer_tap(start_text)
    start_bit = infer_bit(start_text)
    if start_tap != "NA" and start_bit != "NA":
        for mapping in mapping_rows:
            if mapping.get("role") != "fast_tag_source":
                continue
            if mapping.get("tap_index") == start_tap and mapping.get("bit_index") == start_bit:
                return cell_basename(mapping.get("mapped_cell", ""))
    endpoint_tap = infer_tap(row.get("endpoint", ""))
    endpoint_bit = infer_bit(row.get("endpoint", ""))
    if endpoint_tap != "NA" and endpoint_bit != "NA":
        for mapping in mapping_rows:
            if mapping.get("role") != "fast_tag_source":
                continue
            if mapping.get("tap_index") == endpoint_tap and mapping.get("bit_index") == endpoint_bit:
                return cell_basename(mapping.get("mapped_cell", ""))
    return ""


def cell_from_pin_mapping(pin: str, role: str, mapping_rows: list[dict[str, str]]) -> str:
    inst = canonical(inst_from_pin(pin))
    if not inst:
        return ""
    for mapping in mapping_rows:
        if mapping.get("role") != role:
            continue
        mapped_inst = canonical(mapping.get("instance", ""))
        if mapped_inst and (mapped_inst == inst or mapped_inst in inst or inst in mapped_inst):
            return cell_basename(mapping.get("mapped_cell", ""))
    tap = infer_tap(pin)
    bit = infer_bit(pin)
    if tap != "NA" and bit != "NA":
        for mapping in mapping_rows:
            if mapping.get("role") == role and mapping.get("tap_index") == tap and mapping.get("bit_index") == bit:
                return cell_basename(mapping.get("mapped_cell", ""))
    return ""


def source_cell_from_block(block: str) -> str:
    points = parse_point_rows(block)
    for point in points:
        cell = cell_basename(point["cell"])
        if point["point"].endswith(("/Q", "/QN")) and cell.startswith(("DF", "SDF")):
            return cell
    candidates = [
        point
        for point in points
        if "tag" in point["point"].lower()
        and cell_basename(point["cell"]).startswith(("DF", "SDF"))
    ]
    for point in candidates:
        if point["point"].endswith(("/Q", "/QN")):
            return cell_basename(point["cell"])
    if candidates:
        return cell_basename(candidates[0]["cell"])
    return "UNKNOWN"


def parse_exact_discovery(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        return []
    with path.open(newline="") as fh:
        return list(csv.DictReader(fh))


def first_existing(paths: list[Path]) -> Path | None:
    return next((path for path in paths if path.exists()), None)


def mark_top_path_membership(mapping_rows: list[dict[str, str]], top_paths: list[dict[str, str]]) -> None:
    top_texts = [
        canonical(" ".join([row.get("startpoint", ""), row.get("endpoint", "")]))
        for row in top_paths
    ]
    for row in mapping_rows:
        inst = canonical(row["instance"])
        count = sum(1 for text in top_texts if inst and (inst in text or text in inst))
        row["appears_in_top_timing_paths"] = "YES" if count else "NO"
        row["top_timing_path_count"] = str(count)


def write_env(path: Path, values: dict[str, str]) -> None:
    with path.open("w") as fh:
        for key in sorted(values):
            fh.write(f"{key}={shlex.quote(str(values[key]))}\n")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", type=Path, required=True)
    parser.add_argument("--out-csv", type=Path, required=True)
    parser.add_argument("--out-env", type=Path, required=True)
    parser.add_argument("--out-report", type=Path, required=True)
    args = parser.parse_args()

    netlist = args.run_dir / "mptdc_top_asic.postsyn.v"
    if not netlist.exists():
        netlist = args.run_dir / "outputs" / "mptdc_top_asic.postsyn.v"

    mapping_rows = parse_netlist_instances(netlist)
    top_paths = parse_top_fast_paths(args.run_dir / "timing_path_classification.csv")
    blocks = parse_blocks(args.run_dir / "timing_violations.rpt")
    mark_top_path_membership(mapping_rows, top_paths)

    top_source_counter: Counter[str] = Counter()
    for row in top_paths:
        source_cell = source_cell_from_mapping(row, mapping_rows)
        if not source_cell:
            source_cell = source_cell_from_block(blocks.get(row.get("path", ""), ""))
        top_source_counter[source_cell or "UNKNOWN"] += 1

    exact_source_path = first_existing(
        [
            args.run_dir / "fast_tag_exact_source_discovery.csv",
            args.run_dir / "reports" / "fast_tag_exact_source_discovery.csv",
        ]
    )
    exact_endpoint_path = first_existing(
        [
            args.run_dir / "fast_tag_exact_endpoint_discovery.csv",
            args.run_dir / "reports" / "fast_tag_exact_endpoint_discovery.csv",
        ]
    )
    exact_source_counter: Counter[str] = Counter()
    for row in parse_exact_discovery(exact_source_path) if exact_source_path else []:
        cell = cell_from_pin_mapping(row.get("object", ""), "fast_tag_source", mapping_rows)
        exact_source_counter[cell or "UNKNOWN"] += 1
    exact_endpoint_counter: Counter[str] = Counter()
    for row in parse_exact_discovery(exact_endpoint_path) if exact_endpoint_path else []:
        cell = cell_from_pin_mapping(row.get("object", ""), "nfast_hit_endpoint", mapping_rows)
        exact_endpoint_counter[cell or "UNKNOWN"] += 1

    mapped_source_counter = Counter(
        row["mapped_cell"] for row in mapping_rows if row["role"] == "fast_tag_source"
    )
    endpoint_count = sum(1 for row in mapping_rows if row["role"] == "nfast_hit_endpoint")
    weak_top = (
        top_source_counter.get("DFRRQHDX0", 0)
        + top_source_counter.get("DFRSQHDX0", 0)
        + top_source_counter.get("DFRJIHDX0", 0)
        + top_source_counter.get("DFRRQJIHDX0", 0)
    )
    unknown_top = top_source_counter.get("UNKNOWN", 0)
    status = "PASS"
    unknown_exact_source = exact_source_counter.get("UNKNOWN", 0)
    if not netlist.exists() or weak_top > 0 or unknown_top > 0 or unknown_exact_source > 0:
        status = "REVIEW_REQUIRED"

    values = {
        "FAST_TAG_MAPPING_PARSE_STATUS": "PASS" if netlist.exists() else "FAIL",
        "FAST_TAG_MAPPING_STATUS": status,
        "FAST_TAG_MAPPED_SOURCE_COUNT": str(sum(mapped_source_counter.values())),
        "FAST_TAG_MAPPED_ENDPOINT_COUNT": str(endpoint_count),
        "FAST_TAG_SOURCE_DFRRQHDX0_COUNT": str(top_source_counter.get("DFRRQHDX0", 0)),
        "FAST_TAG_SOURCE_DFRRQHDX1_COUNT": str(top_source_counter.get("DFRRQHDX1", 0)),
        "FAST_TAG_SOURCE_DFRRQHDX2_COUNT": str(top_source_counter.get("DFRRQHDX2", 0)),
        "FAST_TAG_SOURCE_DFRRQHDX4_COUNT": str(top_source_counter.get("DFRRQHDX4", 0)),
        "FAST_TAG_SOURCE_DFRSQHDX0_COUNT": str(top_source_counter.get("DFRSQHDX0", 0)),
        "FAST_TAG_SOURCE_DFRSQHDX1_COUNT": str(top_source_counter.get("DFRSQHDX1", 0)),
        "FAST_TAG_SOURCE_DFRSQHDX2_COUNT": str(top_source_counter.get("DFRSQHDX2", 0)),
        "FAST_TAG_SOURCE_DFRSQHDX4_COUNT": str(top_source_counter.get("DFRSQHDX4", 0)),
        "FAST_TAG_SOURCE_DFRJIHDX0_COUNT": str(top_source_counter.get("DFRJIHDX0", 0)),
        "FAST_TAG_SOURCE_DFRJIHDX1_COUNT": str(top_source_counter.get("DFRJIHDX1", 0)),
        "FAST_TAG_SOURCE_DFRJIHDX2_COUNT": str(top_source_counter.get("DFRJIHDX2", 0)),
        "FAST_TAG_SOURCE_DFRJIHDX4_COUNT": str(top_source_counter.get("DFRJIHDX4", 0)),
        "FAST_TAG_SOURCE_DFRRQJIHDX0_COUNT": str(top_source_counter.get("DFRRQJIHDX0", 0)),
        "FAST_TAG_SOURCE_DFRRQJIHDX1_COUNT": str(top_source_counter.get("DFRRQJIHDX1", 0)),
        "FAST_TAG_SOURCE_DFRRQJIHDX2_COUNT": str(top_source_counter.get("DFRRQJIHDX2", 0)),
        "FAST_TAG_SOURCE_DFRRQJIHDX4_COUNT": str(top_source_counter.get("DFRRQJIHDX4", 0)),
        "FAST_TAG_SOURCE_DFRSJIHDX2_COUNT": str(top_source_counter.get("DFRSJIHDX2", 0)),
        "FAST_TAG_SOURCE_UNKNOWN_COUNT": str(top_source_counter.get("UNKNOWN", 0)),
        "FAST_TAG_MAPPED_SOURCE_DFRRQHDX0_COUNT": str(mapped_source_counter.get("DFRRQHDX0", 0)),
        "FAST_TAG_MAPPED_SOURCE_DFRRQHDX1_COUNT": str(mapped_source_counter.get("DFRRQHDX1", 0)),
        "FAST_TAG_MAPPED_SOURCE_DFRRQHDX2_COUNT": str(mapped_source_counter.get("DFRRQHDX2", 0)),
        "FAST_TAG_MAPPED_SOURCE_DFRRQHDX4_COUNT": str(mapped_source_counter.get("DFRRQHDX4", 0)),
        "FAST_TAG_MAPPED_SOURCE_DFRSQHDX0_COUNT": str(mapped_source_counter.get("DFRSQHDX0", 0)),
        "FAST_TAG_MAPPED_SOURCE_DFRSQHDX1_COUNT": str(mapped_source_counter.get("DFRSQHDX1", 0)),
        "FAST_TAG_MAPPED_SOURCE_DFRSQHDX2_COUNT": str(mapped_source_counter.get("DFRSQHDX2", 0)),
        "FAST_TAG_MAPPED_SOURCE_DFRSQHDX4_COUNT": str(mapped_source_counter.get("DFRSQHDX4", 0)),
        "FAST_TAG_MAPPED_SOURCE_DFRJIHDX0_COUNT": str(mapped_source_counter.get("DFRJIHDX0", 0)),
        "FAST_TAG_MAPPED_SOURCE_DFRJIHDX1_COUNT": str(mapped_source_counter.get("DFRJIHDX1", 0)),
        "FAST_TAG_MAPPED_SOURCE_DFRJIHDX2_COUNT": str(mapped_source_counter.get("DFRJIHDX2", 0)),
        "FAST_TAG_MAPPED_SOURCE_DFRJIHDX4_COUNT": str(mapped_source_counter.get("DFRJIHDX4", 0)),
        "FAST_TAG_MAPPED_SOURCE_DFRRQJIHDX0_COUNT": str(mapped_source_counter.get("DFRRQJIHDX0", 0)),
        "FAST_TAG_MAPPED_SOURCE_DFRRQJIHDX1_COUNT": str(mapped_source_counter.get("DFRRQJIHDX1", 0)),
        "FAST_TAG_MAPPED_SOURCE_DFRRQJIHDX2_COUNT": str(mapped_source_counter.get("DFRRQJIHDX2", 0)),
        "FAST_TAG_MAPPED_SOURCE_DFRRQJIHDX4_COUNT": str(mapped_source_counter.get("DFRRQJIHDX4", 0)),
        "FAST_TAG_MAPPED_SOURCE_DFRSJIHDX2_COUNT": str(mapped_source_counter.get("DFRSJIHDX2", 0)),
        "FAST_TAG_TOP_PATH_COUNT": str(len(top_paths)),
        "FAST_TAG_EXACT_SOURCE_COUNT": str(sum(exact_source_counter.values())),
        "FAST_TAG_EXACT_SOURCE_DFRRQHDX1_COUNT": str(exact_source_counter.get("DFRRQHDX1", 0)),
        "FAST_TAG_EXACT_SOURCE_DFRRQHDX2_COUNT": str(exact_source_counter.get("DFRRQHDX2", 0)),
        "FAST_TAG_EXACT_SOURCE_DFRRQHDX4_COUNT": str(exact_source_counter.get("DFRRQHDX4", 0)),
        "FAST_TAG_EXACT_SOURCE_DFRSQHDX0_COUNT": str(exact_source_counter.get("DFRSQHDX0", 0)),
        "FAST_TAG_EXACT_SOURCE_DFRSQHDX1_COUNT": str(exact_source_counter.get("DFRSQHDX1", 0)),
        "FAST_TAG_EXACT_SOURCE_DFRSQHDX2_COUNT": str(exact_source_counter.get("DFRSQHDX2", 0)),
        "FAST_TAG_EXACT_SOURCE_DFRSQHDX4_COUNT": str(exact_source_counter.get("DFRSQHDX4", 0)),
        "FAST_TAG_EXACT_SOURCE_DFRJIHDX1_COUNT": str(exact_source_counter.get("DFRJIHDX1", 0)),
        "FAST_TAG_EXACT_SOURCE_DFRJIHDX2_COUNT": str(exact_source_counter.get("DFRJIHDX2", 0)),
        "FAST_TAG_EXACT_SOURCE_DFRJIHDX4_COUNT": str(exact_source_counter.get("DFRJIHDX4", 0)),
        "FAST_TAG_EXACT_SOURCE_DFRRQJIHDX1_COUNT": str(exact_source_counter.get("DFRRQJIHDX1", 0)),
        "FAST_TAG_EXACT_SOURCE_DFRRQJIHDX2_COUNT": str(exact_source_counter.get("DFRRQJIHDX2", 0)),
        "FAST_TAG_EXACT_SOURCE_DFRRQJIHDX4_COUNT": str(exact_source_counter.get("DFRRQJIHDX4", 0)),
        "FAST_TAG_EXACT_SOURCE_DFRSJIHDX2_COUNT": str(exact_source_counter.get("DFRSJIHDX2", 0)),
        "FAST_TAG_EXACT_SOURCE_UNKNOWN_COUNT": str(exact_source_counter.get("UNKNOWN", 0)),
        "FAST_TAG_EXACT_ENDPOINT_COUNT": str(sum(exact_endpoint_counter.values())),
        "FAST_TAG_EXACT_ENDPOINT_DFRHDX2_COUNT": str(exact_endpoint_counter.get("DFRHDX2", 0)),
        "FAST_TAG_EXACT_ENDPOINT_DFRHDX4_COUNT": str(exact_endpoint_counter.get("DFRHDX4", 0)),
        "FAST_TAG_EXACT_ENDPOINT_DFRSHDX2_COUNT": str(exact_endpoint_counter.get("DFRSHDX2", 0)),
        "FAST_TAG_EXACT_ENDPOINT_DFRSHDX4_COUNT": str(exact_endpoint_counter.get("DFRSHDX4", 0)),
        "FAST_TAG_EXACT_ENDPOINT_UNKNOWN_COUNT": str(exact_endpoint_counter.get("UNKNOWN", 0)),
        "FAST_TAG_EXACT_SOURCE_PHASE_CLOCK_LOAD_DELTA_ESTIMATE": (
            f"{sum(exact_source_counter.values())} exact source flops changed candidate; final delta requires Liberty pin-cap report"
            if exact_source_counter
            else "NA"
        ),
    }

    args.out_csv.parent.mkdir(parents=True, exist_ok=True)
    args.out_env.parent.mkdir(parents=True, exist_ok=True)
    args.out_report.parent.mkdir(parents=True, exist_ok=True)
    fields = [
        "instance",
        "tap_index",
        "bit_index",
        "mapped_cell",
        "drive_strength",
        "role",
        "appears_in_top_timing_paths",
        "top_timing_path_count",
    ]
    with args.out_csv.open("w", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=fields)
        writer.writeheader()
        for row in mapping_rows:
            writer.writerow({field: row.get(field, "") for field in fields})
    write_env(args.out_env, values)
    args.out_report.write_text(
        "\n".join(
            [
                "# Fast Tag Cell Mapping Guardrail",
                "",
                f"FAST_TAG_MAPPING_PARSE_STATUS={values['FAST_TAG_MAPPING_PARSE_STATUS']}",
                f"FAST_TAG_MAPPING_STATUS={values['FAST_TAG_MAPPING_STATUS']}",
                f"FAST_TAG_TOP_PATH_COUNT={values['FAST_TAG_TOP_PATH_COUNT']}",
                f"FAST_TAG_SOURCE_DFRRQHDX0_COUNT={values['FAST_TAG_SOURCE_DFRRQHDX0_COUNT']}",
                f"FAST_TAG_SOURCE_DFRRQHDX1_COUNT={values['FAST_TAG_SOURCE_DFRRQHDX1_COUNT']}",
                f"FAST_TAG_SOURCE_DFRRQHDX2_COUNT={values['FAST_TAG_SOURCE_DFRRQHDX2_COUNT']}",
                f"FAST_TAG_SOURCE_DFRRQHDX4_COUNT={values['FAST_TAG_SOURCE_DFRRQHDX4_COUNT']}",
                f"FAST_TAG_SOURCE_DFRSQHDX0_COUNT={values['FAST_TAG_SOURCE_DFRSQHDX0_COUNT']}",
                f"FAST_TAG_SOURCE_DFRSQHDX1_COUNT={values['FAST_TAG_SOURCE_DFRSQHDX1_COUNT']}",
                f"FAST_TAG_SOURCE_DFRSQHDX2_COUNT={values['FAST_TAG_SOURCE_DFRSQHDX2_COUNT']}",
                f"FAST_TAG_SOURCE_DFRSQHDX4_COUNT={values['FAST_TAG_SOURCE_DFRSQHDX4_COUNT']}",
                f"FAST_TAG_SOURCE_DFRJIHDX0_COUNT={values['FAST_TAG_SOURCE_DFRJIHDX0_COUNT']}",
                f"FAST_TAG_SOURCE_DFRJIHDX1_COUNT={values['FAST_TAG_SOURCE_DFRJIHDX1_COUNT']}",
                f"FAST_TAG_SOURCE_DFRJIHDX2_COUNT={values['FAST_TAG_SOURCE_DFRJIHDX2_COUNT']}",
                f"FAST_TAG_SOURCE_DFRJIHDX4_COUNT={values['FAST_TAG_SOURCE_DFRJIHDX4_COUNT']}",
                f"FAST_TAG_SOURCE_DFRRQJIHDX0_COUNT={values['FAST_TAG_SOURCE_DFRRQJIHDX0_COUNT']}",
                f"FAST_TAG_SOURCE_DFRRQJIHDX1_COUNT={values['FAST_TAG_SOURCE_DFRRQJIHDX1_COUNT']}",
                f"FAST_TAG_SOURCE_DFRRQJIHDX2_COUNT={values['FAST_TAG_SOURCE_DFRRQJIHDX2_COUNT']}",
                f"FAST_TAG_SOURCE_DFRRQJIHDX4_COUNT={values['FAST_TAG_SOURCE_DFRRQJIHDX4_COUNT']}",
                f"FAST_TAG_SOURCE_DFRSJIHDX2_COUNT={values['FAST_TAG_SOURCE_DFRSJIHDX2_COUNT']}",
                f"FAST_TAG_SOURCE_UNKNOWN_COUNT={values['FAST_TAG_SOURCE_UNKNOWN_COUNT']}",
                "",
                "## Exact Repaired Source Set",
                "",
                f"FAST_TAG_EXACT_SOURCE_COUNT={values['FAST_TAG_EXACT_SOURCE_COUNT']}",
                f"FAST_TAG_EXACT_SOURCE_DFRRQHDX1_COUNT={values['FAST_TAG_EXACT_SOURCE_DFRRQHDX1_COUNT']}",
                f"FAST_TAG_EXACT_SOURCE_DFRRQHDX2_COUNT={values['FAST_TAG_EXACT_SOURCE_DFRRQHDX2_COUNT']}",
                f"FAST_TAG_EXACT_SOURCE_DFRRQHDX4_COUNT={values['FAST_TAG_EXACT_SOURCE_DFRRQHDX4_COUNT']}",
                f"FAST_TAG_EXACT_SOURCE_DFRSQHDX0_COUNT={values['FAST_TAG_EXACT_SOURCE_DFRSQHDX0_COUNT']}",
                f"FAST_TAG_EXACT_SOURCE_DFRSQHDX1_COUNT={values['FAST_TAG_EXACT_SOURCE_DFRSQHDX1_COUNT']}",
                f"FAST_TAG_EXACT_SOURCE_DFRSQHDX2_COUNT={values['FAST_TAG_EXACT_SOURCE_DFRSQHDX2_COUNT']}",
                f"FAST_TAG_EXACT_SOURCE_DFRSQHDX4_COUNT={values['FAST_TAG_EXACT_SOURCE_DFRSQHDX4_COUNT']}",
                f"FAST_TAG_EXACT_SOURCE_DFRJIHDX1_COUNT={values['FAST_TAG_EXACT_SOURCE_DFRJIHDX1_COUNT']}",
                f"FAST_TAG_EXACT_SOURCE_DFRJIHDX2_COUNT={values['FAST_TAG_EXACT_SOURCE_DFRJIHDX2_COUNT']}",
                f"FAST_TAG_EXACT_SOURCE_DFRJIHDX4_COUNT={values['FAST_TAG_EXACT_SOURCE_DFRJIHDX4_COUNT']}",
                f"FAST_TAG_EXACT_SOURCE_DFRRQJIHDX1_COUNT={values['FAST_TAG_EXACT_SOURCE_DFRRQJIHDX1_COUNT']}",
                f"FAST_TAG_EXACT_SOURCE_DFRRQJIHDX2_COUNT={values['FAST_TAG_EXACT_SOURCE_DFRRQJIHDX2_COUNT']}",
                f"FAST_TAG_EXACT_SOURCE_DFRRQJIHDX4_COUNT={values['FAST_TAG_EXACT_SOURCE_DFRRQJIHDX4_COUNT']}",
                f"FAST_TAG_EXACT_SOURCE_DFRSJIHDX2_COUNT={values['FAST_TAG_EXACT_SOURCE_DFRSJIHDX2_COUNT']}",
                f"FAST_TAG_EXACT_SOURCE_UNKNOWN_COUNT={values['FAST_TAG_EXACT_SOURCE_UNKNOWN_COUNT']}",
                f"FAST_TAG_EXACT_SOURCE_PHASE_CLOCK_LOAD_DELTA_ESTIMATE={values['FAST_TAG_EXACT_SOURCE_PHASE_CLOCK_LOAD_DELTA_ESTIMATE']}",
                "",
                "## Exact Endpoint Set",
                "",
                f"FAST_TAG_EXACT_ENDPOINT_COUNT={values['FAST_TAG_EXACT_ENDPOINT_COUNT']}",
                f"FAST_TAG_EXACT_ENDPOINT_DFRHDX2_COUNT={values['FAST_TAG_EXACT_ENDPOINT_DFRHDX2_COUNT']}",
                f"FAST_TAG_EXACT_ENDPOINT_DFRHDX4_COUNT={values['FAST_TAG_EXACT_ENDPOINT_DFRHDX4_COUNT']}",
                f"FAST_TAG_EXACT_ENDPOINT_DFRSHDX2_COUNT={values['FAST_TAG_EXACT_ENDPOINT_DFRSHDX2_COUNT']}",
                f"FAST_TAG_EXACT_ENDPOINT_DFRSHDX4_COUNT={values['FAST_TAG_EXACT_ENDPOINT_DFRSHDX4_COUNT']}",
                f"FAST_TAG_EXACT_ENDPOINT_UNKNOWN_COUNT={values['FAST_TAG_EXACT_ENDPOINT_UNKNOWN_COUNT']}",
                "",
                "## Interpretation",
                "",
                "- Counts without the `MAPPED` prefix are extracted from top negative FAST_TAG_TO_PD_TS timing startpoints.",
                "- `MAPPED` counts enumerate fast-tag source registers found in the exported netlist.",
                "- `EXACT_SOURCE` counts enumerate only the targeted Repair4/Repair5 source-register discovery set.",
                "- `EXACT_ENDPOINT` counts enumerate only the targeted Repair4/Repair5 endpoint discovery set.",
                "- `REVIEW_REQUIRED` means a weak `DFRRQHDX0`/`DFRJIHDX0`/`DFRRQJIHDX0` or unknown source cell appears on top FAST_TAG_TO_PD_TS paths.",
            ]
        )
        + "\n"
    )
    return 0 if status == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
