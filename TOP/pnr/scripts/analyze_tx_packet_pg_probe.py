#!/usr/bin/env python3
"""Classify TX packet PG probe text without opening or modifying a design."""

from __future__ import annotations

import argparse
import hashlib
import re
from collections import Counter
from dataclasses import dataclass
from pathlib import Path


NUMBER_RE = re.compile(r"[-+]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)")
OPEN_RE = re.compile(
    r"Net\s+(VDD|VSS):\s+has special routes with opens at\s+"
    r"\(([-+0-9.]+),\s*([-+0-9.]+)\)\s+"
    r"\(([-+0-9.]+),\s*([-+0-9.]+)\)",
    re.IGNORECASE,
)
VIOLATION_RE = re.compile(r"Verification Complete\s*:\s*([0-9]+)\s+Viols", re.IGNORECASE)
PROBLEM_SUMMARY_RE = re.compile(
    r"^\s*([0-9]+)\s+Problem\(s\)\s+\(IMPVFC-200\):\s+Special Wires:",
    re.IGNORECASE | re.MULTILINE,
)


@dataclass(frozen=True)
class Box:
    llx: float
    lly: float
    urx: float
    ury: float

    @property
    def width(self) -> float:
        return self.urx - self.llx

    @property
    def height(self) -> float:
        return self.ury - self.lly

    @property
    def cy(self) -> float:
        return (self.lly + self.ury) / 2.0

    def intersects(self, other: "Box") -> bool:
        return (
            min(self.urx, other.urx) > max(self.llx, other.llx)
            and min(self.ury, other.ury) > max(self.lly, other.lly)
        )

    def intersection(self, other: "Box") -> "Box | None":
        if not self.intersects(other):
            return None
        return Box(
            max(self.llx, other.llx),
            max(self.lly, other.lly),
            min(self.urx, other.urx),
            min(self.ury, other.ury),
        )

    def text(self) -> str:
        return "{%.3f %.3f %.3f %.3f}" % (self.llx, self.lly, self.urx, self.ury)


@dataclass(frozen=True)
class Swire:
    net: str
    index: int
    shape: str
    layer: str
    status: str
    width: str
    geom_type: str
    box: Box | None


def parse_box(text: str) -> Box | None:
    values = [float(value) for value in NUMBER_RE.findall(text)]
    if len(values) < 4:
        return None
    box = Box(*values[:4])
    if box.width <= 0.0 or box.height <= 0.0:
        return None
    return box


def parse_swires(path: Path) -> list[Swire]:
    rows: list[Swire] = []
    in_table = False
    for raw in path.read_text(errors="replace").splitlines():
        if raw == "SWIRE_TABLE_BEGIN":
            in_table = True
            continue
        if raw == "SWIRE_TABLE_END":
            break
        if not in_table or raw.startswith("net\t") or "\t" not in raw:
            continue
        fields = raw.split("\t", 8)
        if len(fields) < 8 or fields[0] not in {"VDD", "VSS"}:
            continue
        try:
            index = int(fields[1])
        except ValueError:
            continue
        rows.append(
            Swire(
                net=fields[0],
                index=index,
                shape=fields[2],
                layer=fields[3],
                status=fields[4],
                width=fields[5],
                geom_type=fields[6],
                box=parse_box(fields[7]),
            )
        )
    return rows


def parse_opens(path: Path) -> tuple[list[tuple[str, Box]], int | None, int | None]:
    text = path.read_text(errors="replace")
    opens = [
        (match.group(1).upper(), Box(*(float(match.group(i)) for i in range(2, 6))))
        for match in OPEN_RE.finditer(text)
    ]
    violations = VIOLATION_RE.findall(text)
    problem_summaries = PROBLEM_SUMMARY_RE.findall(text)
    return (
        opens,
        int(violations[-1]) if violations else None,
        int(problem_summaries[-1]) if problem_summaries else None,
    )


def marker_classes(path: Path) -> Counter[str]:
    counts: Counter[str] = Counter()
    for index, raw in enumerate(path.read_text(errors="replace").splitlines()):
        if index == 0 or not raw:
            continue
        fields = raw.split("\t", 6)
        if len(fields) < 7:
            continue
        marker_type = fields[4]
        subtype = fields[5]
        message = fields[6]
        if marker_type == "Connectivity" and subtype == "Open":
            net = "VDD" if "VDD" in message else "VSS" if "VSS" in message else "UNKNOWN"
            counts[f"connectivity_open_{net}"] += 1
        elif subtype == "Minimal_Area":
            counts["minimum_area"] += 1
        elif marker_type == "Antenna":
            counts["antenna"] += 1
        else:
            counts["other"] += 1
    return counts


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--probe-root", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()

    reports = args.probe_root / "reports"
    detail = reports / "verify_connectivity_special_detail.rpt"
    topology = reports / "pg_topology.rpt"
    markers = reports / "pg_connectivity_markers.tsv"
    missing = [path for path in (detail, topology, markers) if not path.is_file()]
    if missing:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(
            "LABEL=SPADMIC_TX_PACKET_PG_TOPOLOGY_ANALYSIS\n"
            "POLICY=READ_ONLY_TEXT_ARTIFACT_ANALYSIS\n"
            "STATUS=FAIL\n"
            "RESULT=MISSING_REQUIRED_INPUTS\n"
            f"MISSING_INPUTS={' '.join(str(path) for path in missing)}\n"
        )
        return 8

    opens, verification_count, problem_summary_count = parse_opens(detail)
    swires = parse_swires(topology)
    classes = marker_classes(markers)

    if verification_count is not None and problem_summary_count is not None:
        violation_count = verification_count
        count_source = "VERIFICATION_COMPLETE_AND_IMPVFC_200_PROBLEM_SUMMARY"
        count_consistency = "PASS" if verification_count == problem_summary_count else "FAIL"
    elif verification_count is not None:
        violation_count = verification_count
        count_source = "VERIFICATION_COMPLETE"
        count_consistency = "PASS"
    elif problem_summary_count is not None:
        violation_count = problem_summary_count
        count_source = "IMPVFC_200_PROBLEM_SUMMARY"
        count_consistency = "PASS"
    else:
        violation_count = None
        count_source = "NONE"
        count_consistency = "FAIL"

    row_opens = [(net, box) for net, box in opens if box.height <= 10.0]
    aggregate_opens = [(net, box) for net, box in opens if box.height > 10.0]
    vdd_rows = [box for net, box in row_opens if net == "VDD"]
    vss_rows = [box for net, box in row_opens if net == "VSS"]
    vdd_aggregate = [box for net, box in aggregate_opens if net == "VDD"]
    vss_aggregate = [box for net, box in aggregate_opens if net == "VSS"]

    vdd_stripes = [
        swire
        for swire in swires
        if swire.net == "VDD"
        and swire.layer == "METTP"
        and swire.box is not None
        and swire.box.height > swire.box.width
    ]
    vdd_stripes.sort(key=lambda swire: swire.box.height if swire.box else 0.0, reverse=True)

    row_evidence: list[dict[str, object]] = []
    for row_number, row_box in enumerate(sorted(vdd_rows, key=lambda box: box.cy), start=1):
        rails = [
            swire
            for swire in swires
            if swire.net == "VDD"
            and swire.layer == "MET1"
            and swire.box is not None
            and swire.box.width > swire.box.height
            and swire.box.intersects(row_box)
        ]
        rails.sort(key=lambda swire: swire.box.width if swire.box else 0.0, reverse=True)
        overlap: Box | None = None
        selected_rail: Swire | None = None
        selected_stripe: Swire | None = None
        for rail in rails:
            for stripe in vdd_stripes:
                if rail.box is None or stripe.box is None:
                    continue
                candidate = rail.box.intersection(stripe.box)
                if candidate is not None:
                    overlap = candidate
                    selected_rail = rail
                    selected_stripe = stripe
                    break
            if overlap is not None:
                break
        row_evidence.append(
            {
                "number": row_number,
                "box": row_box,
                "rails": rails,
                "rail": selected_rail,
                "stripe": selected_stripe,
                "overlap": overlap,
            }
        )

    topology_ready = (
        violation_count is not None
        and count_consistency == "PASS"
        and violation_count == len(opens)
        and len(vdd_rows) == 3
        and len(vss_rows) == 0
        and len(vdd_aggregate) == 1
        and len(vss_aggregate) == 0
        and classes["connectivity_open_VDD"] == sum(net == "VDD" for net, _ in opens)
        and classes["connectivity_open_VSS"] == sum(net == "VSS" for net, _ in opens)
        and len(vdd_stripes) > 0
        and all(row["overlap"] is not None for row in row_evidence)
    )
    status = "PASS" if opens and swires else "FAIL"
    result = "VDD_ROW_COMPONENTS_CLASSIFIED" if status == "PASS" else "TOPOLOGY_EVIDENCE_INCOMPLETE"
    via_decision = "READY_FOR_ONE_ISOLATED_TRIAL" if topology_ready else "BLOCKED_NEEDS_TOPOLOGY_REVIEW"

    layer_counts = Counter((swire.net, swire.layer) for swire in swires)
    lines = [
        "LABEL=SPADMIC_TX_PACKET_PG_TOPOLOGY_ANALYSIS",
        "POLICY=READ_ONLY_TEXT_ARTIFACT_ANALYSIS",
        f"STATUS={status}",
        f"RESULT={result}",
        f"PROBE_ROOT={args.probe_root}",
        f"SPECIAL_CONNECTIVITY_VIOLATION_COUNT={violation_count if violation_count is not None else 'UNKNOWN'}",
        f"SPECIAL_CONNECTIVITY_COUNT_SOURCE={count_source}",
        f"SPECIAL_CONNECTIVITY_COUNT_CONSISTENCY={count_consistency}",
        f"SPECIAL_CONNECTIVITY_VERIFICATION_COUNT={verification_count if verification_count is not None else 'NOT_PRESENT'}",
        f"SPECIAL_CONNECTIVITY_PROBLEM_SUMMARY_COUNT={problem_summary_count if problem_summary_count is not None else 'NOT_PRESENT'}",
        f"OPEN_COMPONENT_COUNT={len(opens)}",
        f"VDD_OPEN_COMPONENT_COUNT={sum(net == 'VDD' for net, _ in opens)}",
        f"VSS_OPEN_COMPONENT_COUNT={sum(net == 'VSS' for net, _ in opens)}",
        f"VDD_HORIZONTAL_ROW_COMPONENT_COUNT={len(vdd_rows)}",
        f"VSS_HORIZONTAL_ROW_COMPONENT_COUNT={len(vss_rows)}",
        f"VDD_AGGREGATE_COMPONENT_COUNT={len(vdd_aggregate)}",
        f"VSS_AGGREGATE_COMPONENT_COUNT={len(vss_aggregate)}",
        f"VDD_VERTICAL_METTP_STRIPE_COUNT={len(vdd_stripes)}",
        f"VDD_SWIRE_COUNT={sum(swire.net == 'VDD' for swire in swires)}",
        f"VSS_SWIRE_COUNT={sum(swire.net == 'VSS' for swire in swires)}",
        f"DRC_MINIMUM_AREA_MARKER_COUNT={classes['minimum_area']}",
        f"DRC_ANTENNA_MARKER_COUNT={classes['antenna']}",
        f"CONNECTIVITY_MARKER_VDD_COUNT={classes['connectivity_open_VDD']}",
        f"CONNECTIVITY_MARKER_VSS_COUNT={classes['connectivity_open_VSS']}",
        f"EDIT_POWER_VIA_TRIAL_DECISION={via_decision}",
        "SECOND_SROUTE_DECISION=DO_NOT_REPEAT_COORDINATE_INVARIANT_METHOD",
        "CANONICAL_RERUN_DECISION=BLOCKED_PENDING_ISOLATED_VIA_TRIAL_AND_MIN_AREA_METHOD",
    ]
    for net in ("VDD", "VSS"):
        for layer in ("MET1", "MET2", "MET3", "METTP"):
            lines.append(f"{net}_{layer}_SWIRE_COUNT={layer_counts[(net, layer)]}")
    for number, box in enumerate(vdd_aggregate, start=1):
        lines.append(f"VDD_AGGREGATE_{number}_BOX={box.text()}")
    for row in row_evidence:
        number = row["number"]
        rail = row["rail"]
        stripe = row["stripe"]
        overlap = row["overlap"]
        lines.extend(
            [
                f"VDD_ROW_{number}_BOX={row['box'].text()}",
                f"VDD_ROW_{number}_CENTER_Y_UM={row['box'].cy:.3f}",
                f"VDD_ROW_{number}_MET1_SWIRE_COUNT={len(row['rails'])}",
                f"VDD_ROW_{number}_SELECTED_MET1_SWIRE={rail.index if isinstance(rail, Swire) else 'NONE'}",
                f"VDD_ROW_{number}_SELECTED_METTP_SWIRE={stripe.index if isinstance(stripe, Swire) else 'NONE'}",
                f"VDD_ROW_{number}_VIA_SEARCH_AREA={overlap.text() if isinstance(overlap, Box) else 'NONE'}",
            ]
        )
    lines.extend(
        [
            "EVIDENCE_HASHES_BEGIN",
            f"{sha256(detail)}  {detail}",
            f"{sha256(topology)}  {topology}",
            f"{sha256(markers)}  {markers}",
            "EVIDENCE_HASHES_END",
        ]
    )
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text("\n".join(lines) + "\n")
    return 0 if status == "PASS" else 8


if __name__ == "__main__":
    raise SystemExit(main())
