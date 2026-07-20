#!/usr/bin/env python3
"""Classify one immutable PVS DRC run without changing its evidence."""

from __future__ import annotations

import argparse
import csv
import hashlib
import math
import re
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path


RULECHECK_RE = re.compile(
    r"^RULECHECK\s+(.+?)\s+\.*\s+Total Result\s+"
    r"(\d+)\s+\(\s*(\d+)\s*\)\s*$"
)
TOTAL_RE = re.compile(
    r"^Total DRC Results\s*:\s*(\d+)\s+\(\s*(\d+)\s*\)\s*$",
    re.I,
)
RULECHECK_TOTAL_RE = re.compile(r"^Total DRC RuleChecks\s*:\s*(\d+)\s*$", re.I)
COUNT_LINE_RE = re.compile(r"^(\d+)\s+(\d+)\s+\d+\s+.+$")
GEOMETRY_RECORD_RE = re.compile(r"^([A-Za-z])\s+(\d+)\s+(\d+)\s*$")
COORDINATE_RE = re.compile(r"^(-?\d+)\s+(-?\d+)\s*$")
EXPLICIT_ANTENNA_RE = re.compile(r"\bantenn\w*\b", re.I)
CONNECTED_GATE_AREA_RATIO_RE = re.compile(
    r"\bratio\s+of\s+.+?\s+area\s+to\s+(?:the\s+)?connected\s+"
    r"gates?\s+area\b",
    re.I,
)


@dataclass(frozen=True)
class Rule:
    name: str
    primary: int
    expanded: int
    summary_line: int


@dataclass
class RuleEvidence:
    rule: Rule
    header_primary: int
    header_expanded: int
    description: str
    geometries: list["Geometry"]


@dataclass(frozen=True)
class Geometry:
    rule: str
    result_index: int
    geometry_type: str
    vertices: tuple[tuple[int, int], ...]
    dbu_per_um: int

    @property
    def llx(self) -> float:
        return min(point[0] for point in self.vertices) / self.dbu_per_um

    @property
    def lly(self) -> float:
        return min(point[1] for point in self.vertices) / self.dbu_per_um

    @property
    def urx(self) -> float:
        return max(point[0] for point in self.vertices) / self.dbu_per_um

    @property
    def ury(self) -> float:
        return max(point[1] for point in self.vertices) / self.dbu_per_um

    @property
    def cx(self) -> float:
        return (self.llx + self.urx) / 2.0

    @property
    def cy(self) -> float:
        return (self.lly + self.ury) / 2.0


@dataclass(frozen=True)
class WaiverMarker:
    net: str
    box: tuple[float, float, float, float]


class AnalysisError(RuntimeError):
    pass


def kv_report(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for line in path.read_text(errors="replace").splitlines():
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key] = value
    return values


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def require_file(path: Path, label: str) -> Path:
    if not path.is_file() or path.stat().st_size == 0:
        raise AnalysisError(f"{label} is missing or empty: {path}")
    return path


def report_path(
    report: dict[str, str],
    key: str,
    run_dir: Path,
    fallback_glob: str,
) -> Path:
    configured = report.get(key, "")
    if configured and configured != "NOT_CONFIGURED":
        candidate = Path(configured)
        if not candidate.is_absolute():
            candidate = run_dir / candidate
        if candidate.is_file():
            return candidate.resolve()
    candidates = sorted(run_dir.glob(fallback_glob))
    if len(candidates) != 1:
        raise AnalysisError(
            f"expected one {fallback_glob} file under {run_dir}, found "
            f"{len(candidates)}"
        )
    return candidates[0].resolve()


def parse_summary(path: Path) -> tuple[list[Rule], int, int, int, dict[str, str]]:
    rules: list[Rule] = []
    total_primary: int | None = None
    total_expanded: int | None = None
    declared_rulechecks: int | None = None
    metadata: dict[str, str] = {}

    for line_number, line in enumerate(
        path.read_text(errors="replace").splitlines(),
        start=1,
    ):
        rule_match = RULECHECK_RE.match(line)
        if rule_match:
            rules.append(
                Rule(
                    name=rule_match.group(1).strip(),
                    primary=int(rule_match.group(2)),
                    expanded=int(rule_match.group(3)),
                    summary_line=line_number,
                )
            )
            continue
        total_match = TOTAL_RE.match(line)
        if total_match:
            total_primary = int(total_match.group(1))
            total_expanded = int(total_match.group(2))
            continue
        rulecheck_match = RULECHECK_TOTAL_RE.match(line)
        if rulecheck_match:
            declared_rulechecks = int(rulecheck_match.group(1))
            continue
        for key in (
            "Rule Deck Title",
            "Layout System",
            "Layout Path",
            "Layout Primary Cell",
            "Layout Depth",
            "Text Depth",
            "Maximum Results",
            "Maximum Result Vertices",
        ):
            prefix = f"{key}"
            if line.startswith(prefix) and ":" in line:
                metadata[key] = line.split(":", 1)[1].strip()

    if not rules:
        raise AnalysisError(f"no RULECHECK records found in {path}")
    if total_primary is None or total_expanded is None:
        raise AnalysisError(f"no Total DRC Results record found in {path}")
    if declared_rulechecks is None:
        raise AnalysisError(f"no Total DRC RuleChecks record found in {path}")
    if len(rules) != declared_rulechecks:
        raise AnalysisError(
            "rulecheck count does not reconcile: "
            f"parsed={len(rules)} declared={declared_rulechecks}"
        )
    return rules, total_primary, total_expanded, declared_rulechecks, metadata


def parse_error_database(
    path: Path,
    nonzero_rules: list[Rule],
) -> tuple[str, int, dict[str, RuleEvidence]]:
    lines = path.read_text(errors="replace").splitlines()
    if not lines:
        raise AnalysisError(f"empty ASCII DRC error database: {path}")
    first = lines[0].split()
    if len(first) != 2 or not first[1].isdigit():
        raise AnalysisError(f"invalid ASCII DRC error database header: {lines[0]}")
    layout_top = first[0]
    dbu_per_um = int(first[1])
    if dbu_per_um <= 0:
        raise AnalysisError(f"invalid database units in {path}: {dbu_per_um}")

    expected = {rule.name: rule for rule in nonzero_rules}
    evidence: dict[str, RuleEvidence] = {}
    index = 1
    while index < len(lines):
        name = lines[index].strip()
        if name not in expected:
            index += 1
            continue
        if name in evidence:
            raise AnalysisError(f"duplicate rule section in {path}: {name}")
        if index + 1 >= len(lines):
            raise AnalysisError(f"missing count record after rule {name}")
        count_match = COUNT_LINE_RE.match(lines[index + 1].strip())
        if not count_match:
            raise AnalysisError(
                f"invalid count record after rule {name}: {lines[index + 1]}"
            )
        header_primary = int(count_match.group(1))
        header_expanded = int(count_match.group(2))
        index += 2

        description = ""
        while index < len(lines):
            candidate = lines[index].strip()
            if candidate in expected:
                break
            if candidate.startswith('"') and candidate.endswith('"'):
                description = candidate[1:-1]
                index += 1
                break
            index += 1

        geometries: list[Geometry] = []
        while index < len(lines):
            candidate = lines[index].strip()
            if candidate in expected:
                break
            record_match = GEOMETRY_RECORD_RE.match(candidate)
            if not record_match:
                index += 1
                continue
            geometry_type = record_match.group(1)
            result_index = int(record_match.group(2))
            vertex_count = int(record_match.group(3))
            vertices: list[tuple[int, int]] = []
            for offset in range(vertex_count):
                coordinate_index = index + 1 + offset
                if coordinate_index >= len(lines):
                    raise AnalysisError(
                        f"truncated geometry for {name} result {result_index}"
                    )
                coordinate_match = COORDINATE_RE.match(
                    lines[coordinate_index].strip()
                )
                if not coordinate_match:
                    raise AnalysisError(
                        f"invalid coordinate for {name} result {result_index}: "
                        f"{lines[coordinate_index]}"
                    )
                vertices.append(
                    (int(coordinate_match.group(1)), int(coordinate_match.group(2)))
                )
            geometries.append(
                Geometry(
                    rule=name,
                    result_index=result_index,
                    geometry_type=geometry_type,
                    vertices=tuple(vertices),
                    dbu_per_um=dbu_per_um,
                )
            )
            index += vertex_count + 1

        evidence[name] = RuleEvidence(
            rule=expected[name],
            header_primary=header_primary,
            header_expanded=header_expanded,
            description=description,
            geometries=geometries,
        )

    missing = sorted(set(expected) - set(evidence))
    if missing:
        raise AnalysisError(
            "nonzero rules missing from ASCII DRC error database: "
            + ", ".join(missing)
        )
    return layout_top, dbu_per_um, evidence


def symbol_state(control_text: str, symbol: str) -> str:
    defines = len(
        re.findall(rf"^\s*#DEFINE\s+{re.escape(symbol)}\s*$", control_text, re.M)
    )
    undefines = len(
        re.findall(rf"^\s*#UNDEFINE\s+{re.escape(symbol)}\s*$", control_text, re.M)
    )
    if defines == 1 and undefines == 0:
        return "DEFINED"
    if defines == 0 and undefines == 1:
        return "UNDEFINED"
    if defines == 0 and undefines == 0:
        return "MISSING"
    return f"CONFLICT_DEFINE_{defines}_UNDEFINE_{undefines}"


def antenna_classification_basis(name: str, description: str) -> str:
    text = f"{name} {description}"
    if EXPLICIT_ANTENNA_RE.search(text):
        return "EXPLICIT_ANTENNA_TERM"
    if CONNECTED_GATE_AREA_RATIO_RE.search(text):
        return "CONDUCTOR_AREA_TO_CONNECTED_GATE_AREA_RATIO"
    return "NONE"


def rule_classification(name: str, description: str) -> str:
    if antenna_classification_basis(name, description) != "NONE":
        return "ANTENNA_RULE"
    return "NON_ANTENNA_REVIEW"


def semantic_category(name: str, description: str) -> str:
    text = f"{name} {description}".lower()
    if rule_classification(name, description) == "ANTENNA_RULE":
        return "ANTENNA"
    if "density" in text or ("ratio" in text and "extent area" in text):
        return "DENSITY"
    if "offgrid" in text or "off-grid" in text:
        return "OFFGRID"
    if "skewedge" in text or "skew edge" in text:
        return "SKEW_EDGE"
    if "short" in text or "connectivity" in text:
        return "CONNECTIVITY"
    if "enclosure" in text or "overlap" in text:
        return "ENCLOSURE"
    if "spacing" in text or "notch" in text:
        return "SPACING_OR_NOTCH"
    if "area" in text:
        return "AREA"
    if "bend" in text or "angle" in text:
        return "BEND_OR_ANGLE"
    if "width" in text or "fixed via" in text or "size" in text:
        return "WIDTH_OR_SIZE"
    return "OTHER_PHYSICAL_RULE"


def affected_layer(name: str, description: str) -> str:
    text = f"{name} {description}".upper()
    tokens = (
        "METTP",
        "VIATP",
        "VIA3",
        "VIA2",
        "VIA1",
        "MET3",
        "MET2",
        "MET1",
        "DNWELLMV",
        "NWELL",
        "DIFF",
        "POLY",
    )
    found = [token for token in tokens if re.search(rf"\b{token}\b", text)]
    return ",".join(found) if found else "UNKNOWN"


def repair_guidance(category: str) -> str:
    guidance = {
        "AREA": (
            "Increase the localized polygon area at the reported marker while "
            "preserving spacing and connectivity; verify the exact object in "
            "the result browser before changing routing."
        ),
        "SPACING_OR_NOTCH": (
            "Inspect both sides of the reported gap or notch in the GDS result "
            "browser, then move, reshape, or reroute the offending geometry."
        ),
        "ENCLOSURE": (
            "Extend the enclosing metal around the via or stripe, or replace "
            "the malformed via construct with a legal generated structure."
        ),
        "WIDTH_OR_SIZE": (
            "Check whether streamout produced a noncanonical wire, via, or "
            "stripe width; resize or regenerate the exact physical object."
        ),
        "BEND_OR_ANGLE": (
            "Inspect the polygon or stripe generator at the hotspot; remove "
            "illegal bends instead of applying a broad routing change."
        ),
        "OFFGRID": (
            "Snap the originating geometry to the foundry manufacturing grid "
            "and re-export with the same audited stream map."
        ),
        "SKEW_EDGE": (
            "Replace the skew edge with legal orthogonal or allowed-angle "
            "geometry and verify that the source object is not a bad merge."
        ),
        "CONNECTIVITY": (
            "Treat this as a separate electrical/physical defect; inspect the "
            "reported conductors before changing spacing-only geometry."
        ),
        "DENSITY": (
            "Treat this as whole-window coverage debt in the dedicated "
            "density-enabled variant. Review the foundry fill and assembled "
            "chip-level policy; do not apply a localized minimum-area repair."
        ),
        "ANTENNA": (
            "Keep this in the separate antenna closure flow. Review legal "
            "foundry remedies such as route segmentation or layer hopping, "
            "antenna-diode insertion, reduced pre-gate conductor area, or "
            "additional connected diffusion; do not treat it as minimum area."
        ),
        "OTHER_PHYSICAL_RULE": (
            "Use the foundry rule description and result geometry as the "
            "repair contract; do not infer a fix from the short rule code."
        ),
    }
    return guidance[category]


def parse_waiver_markers(path: Path | None) -> list[WaiverMarker]:
    if path is None:
        return []
    require_file(path, "Innovus waiver table")
    markers: list[WaiverMarker] = []
    with path.open(newline="") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        required = {"net", "marker_box"}
        if not reader.fieldnames or not required.issubset(reader.fieldnames):
            raise AnalysisError(
                f"Innovus waiver table lacks columns {sorted(required)}: {path}"
            )
        for row in reader:
            values = row["marker_box"].replace("{", "").replace("}", "").split()
            if len(values) != 4:
                raise AnalysisError(
                    f"invalid marker_box for {row.get('net', 'UNKNOWN')}: "
                    f"{row['marker_box']}"
                )
            markers.append(
                WaiverMarker(
                    net=row["net"],
                    box=tuple(float(value) for value in values),  # type: ignore[arg-type]
                )
            )
    return markers


def expanded_box(
    box: tuple[float, float, float, float],
    margin: float,
) -> tuple[float, float, float, float]:
    return (
        box[0] - margin,
        box[1] - margin,
        box[2] + margin,
        box[3] + margin,
    )


def overlaps(
    left: tuple[float, float, float, float],
    right: tuple[float, float, float, float],
) -> bool:
    return (
        min(left[2], right[2]) >= max(left[0], right[0])
        and min(left[3], right[3]) >= max(left[1], right[1])
    )


def geometry_box(geometry: Geometry) -> tuple[float, float, float, float]:
    return geometry.llx, geometry.lly, geometry.urx, geometry.ury


def rule_bbox(geometries: list[Geometry]) -> str:
    if not geometries:
        return "UNKNOWN"
    return (
        f"{min(item.llx for item in geometries):.6f} "
        f"{min(item.lly for item in geometries):.6f} "
        f"{max(item.urx for item in geometries):.6f} "
        f"{max(item.ury for item in geometries):.6f}"
    )


def markdown_escape(value: str) -> str:
    return value.replace("|", "\\|")


def write_tsv(path: Path, header: list[str], rows: list[list[object]]) -> None:
    with path.open("w", newline="") as handle:
        writer = csv.writer(handle, delimiter="\t", lineterminator="\n")
        writer.writerow(header)
        writer.writerows(rows)


def write_markdown(
    path: Path,
    *,
    run_dir: Path,
    summary_path: Path,
    error_path: Path,
    control_path: Path,
    layout_top: str,
    total_primary: int,
    total_expanded: int,
    drc_variant: str,
    density_state: str,
    antenna_state: str,
    ordered: list[RuleEvidence],
    waiver_markers: list[WaiverMarker],
    correlations: dict[str, list[Geometry]],
    geometry_tsv: Path,
    rule_tsv: Path,
    antenna_tsv: Path,
    non_antenna_tsv: Path,
    bin_tsv: Path,
) -> None:
    variant_title = drc_variant.title()
    variant_label = f"{drc_variant.lower()}-DRC"
    non_antenna = [
        item
        for item in ordered
        if rule_classification(item.rule.name, item.description)
        == "NON_ANTENNA_REVIEW"
    ]
    antenna_rules = [
        item
        for item in ordered
        if rule_classification(item.rule.name, item.description)
        == "ANTENNA_RULE"
    ]
    non_antenna_total = sum(item.rule.primary for item in non_antenna)
    antenna_total = sum(item.rule.primary for item in antenna_rules)
    if waiver_markers:
        lvs_statement = (
            "- LVS state: separate explicit `MATCH`; it does not waive this "
            "DRC debt."
        )
    else:
        lvs_statement = (
            "- LVS state: separate gate; this DRC analysis does not infer an "
            "LVS result."
        )
    if antenna_state == "UNDEFINED":
        variable_ratio_statement = (
            "`VAR_ANT_RATIO=UNDEFINED` disables the optional variable-ratio "
            "family; it does not disable fixed metal-to-connected-gate "
            "antenna checks."
        )
    else:
        variable_ratio_statement = (
            "`VAR_ANT_RATIO=DEFINED` enables the supplemental variable-ratio "
            "family in addition to the standard antenna checks."
        )

    lines = [
        f"# PVS {variant_title} DRC Rule Classification and Non-Antenna Analysis",
        "",
        "## Verdict",
        "",
        f"- Layout top: `{layout_top}`",
        f"- Immutable source run: `{run_dir}`",
        f"- PVS {drc_variant.lower()} DRC total: "
        f"`{total_primary} ({total_expanded})`",
        f"- Retained non-antenna review total: `{non_antenna_total}`",
        f"- Classified antenna result total: `{antenna_total}`",
        f"- DENSITY configurator state: `{density_state}`",
        f"- VAR_ANT_RATIO configurator state: `{antenna_state}`",
        lvs_statement,
        "",
        "The classification policy is deliberately conservative. A result is",
        "classified as antenna only when its rule name or foundry description",
        "contains an explicit antenna term or describes the antenna mechanism",
        "as conductor area divided by connected gate area. Every other",
        "ambiguous rule remains in the non-antenna repair inventory.",
        "",
        variable_ratio_statement,
        "",
        "## Antenna Rule Inventory",
        "",
        "| Rank | Rule | Results | Basis | Layer | Foundry description |",
        "| ---: | --- | ---: | --- | --- | --- |",
    ]
    for rank, item in enumerate(ordered, start=1):
        if rule_classification(item.rule.name, item.description) != "ANTENNA_RULE":
            continue
        lines.append(
            f"| {rank} | `{item.rule.name}` | {item.rule.primary} | "
            f"{antenna_classification_basis(item.rule.name, item.description)} | "
            f"{affected_layer(item.rule.name, item.description)} | "
            f"{markdown_escape(item.description or 'DESCRIPTION_MISSING')} |"
        )

    lines.extend(
        [
            "",
            "## Non-Antenna Rule Inventory",
            "",
        ]
    )
    if not non_antenna:
        lines.extend(
            [
                f"No non-antenna PVS {variant_label} rule remains after semantic",
                "classification of the executed foundry descriptions.",
            ]
        )
    else:
        lines.extend(
            [
                "| Rank | Rule | Results | Category | Layer | Foundry description |",
                "| ---: | --- | ---: | --- | --- | --- |",
            ]
        )
        for rank, item in enumerate(ordered, start=1):
            if (
                rule_classification(item.rule.name, item.description)
                != "NON_ANTENNA_REVIEW"
            ):
                continue
            lines.append(
                f"| {rank} | `{item.rule.name}` | {item.rule.primary} | "
                f"{semantic_category(item.rule.name, item.description)} | "
                f"{affected_layer(item.rule.name, item.description)} | "
                f"{markdown_escape(item.description or 'DESCRIPTION_MISSING')} |"
            )

    lines.extend(
        [
            "",
            "## Non-Antenna Per-Rule Evidence",
            "",
        ]
    )
    if not non_antenna:
        lines.extend(
            [
                "None. The complete antenna geometry remains available in the",
                "rule inventory and marker-geometry TSV for the deferred antenna",
                "closure flow.",
                "",
            ]
        )
    for item in ordered:
        classification = rule_classification(item.rule.name, item.description)
        if classification != "NON_ANTENNA_REVIEW":
            continue
        category = semantic_category(item.rule.name, item.description)
        share = (
            100.0 * item.rule.primary / total_primary if total_primary else 0.0
        )
        lines.extend(
            [
                f"### {item.rule.name}",
                "",
                f"- Results: `{item.rule.primary} ({item.rule.expanded})` "
                f"or `{share:.2f}%` of the {drc_variant.lower()} total.",
                f"- Category: `{category}`",
                f"- Layer/object: `{affected_layer(item.rule.name, item.description)}`",
                f"- Foundry description: `{item.description or 'DESCRIPTION_MISSING'}`",
                f"- Aggregate bounding box in microns: `{rule_bbox(item.geometries)}`",
                f"- Repair interpretation: {repair_guidance(category)}",
                "",
                "| Result | LLX | LLY | URX | URY | Center X | Center Y |",
                "| ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
            ]
        )
        for geometry in item.geometries[:12]:
            lines.append(
                f"| {geometry.result_index} | {geometry.llx:.6f} | "
                f"{geometry.lly:.6f} | {geometry.urx:.6f} | "
                f"{geometry.ury:.6f} | {geometry.cx:.6f} | "
                f"{geometry.cy:.6f} |"
            )
        if len(item.geometries) > 12:
            lines.append(
                f"| ... | ... | ... | ... | ... | ... | "
                f"{len(item.geometries) - 12} more in `{geometry_tsv.name}` |"
            )
        lines.append("")

    lines.extend(
        [
            "## Innovus Four-Marker Correlation",
            "",
        ]
    )
    if waiver_markers:
        lines.extend(
            [
                "| Net | Innovus marker box | Overlapping PVS results | Rules |",
                "| --- | --- | ---: | --- |",
            ]
        )
        for marker in waiver_markers:
            hits = correlations.get(marker.net, [])
            rules = ",".join(sorted({item.rule for item in hits})) or "NONE"
            box = " ".join(f"{value:.6f}" for value in marker.box)
            lines.append(
                f"| `{marker.net}` | `{box}` | {len(hits)} | `{rules}` |"
            )
        lines.extend(
            [
                "",
                "A zero overlap does not prove that the Innovus marker vanished;",
                "the foundry deck can report a different polygon or rule footprint.",
                "A nonzero overlap is direct spatial evidence and should be reviewed",
                "in the PVS result browser before editing.",
            ]
        )
    else:
        lines.append(
            "No Innovus waiver TSV was supplied, so cross-tool spatial "
            "correlation was not requested."
        )

    lines.extend(["", "## Closure Order", ""])
    if waiver_markers:
        lines.extend(
            [
                "1. Keep the supplied Innovus markers as their own manually",
                "   repairable debt; do not treat them as a PVS waiver.",
                "2. Defer or repair the classified antenna rules according to the",
                "   milestone policy, but do not relabel them as generic area errors.",
            ]
        )
    else:
        lines.extend(
            [
                "1. Review the classified non-antenna rules before changing the",
                "   layout; retain every ambiguous rule in the repair inventory.",
                "2. Review the antenna family separately from non-antenna debt.",
            ]
        )
    lines.append("3. Export a new mapped and standard-cell-merged GDS after any repair.")
    if drc_variant == "BASE":
        lines.extend(
            [
                "4. Require base PVS DRC zero for final closure, then run and require",
                "   density-enabled PVS DRC zero.",
            ]
        )
    else:
        lines.extend(
            [
                "4. Retain the separate accepted base-DRC evidence and repair or",
                "   rerun this density variant until its report-level total is zero.",
            ]
        )
    lines.extend(
        [
            "5. Run LVS on the final exact GDS and require an explicit `MATCH`.",
            "",
            "Do not edit or rerun inside the immutable source run. This report and",
            "all generated TSV files live in the separate analysis directory.",
            "",
            "## Machine-Readable Evidence",
            "",
            f"- Rule inventory: `{rule_tsv}`",
            f"- Antenna rules: `{antenna_tsv}`",
            f"- Non-antenna rules: `{non_antenna_tsv}`",
            f"- Every result geometry: `{geometry_tsv}`",
            f"- Spatial bins: `{bin_tsv}`",
            f"- Summary source: `{summary_path}`",
            f"- ASCII geometry source: `{error_path}`",
            f"- Executed DRC control: `{control_path}`",
            "",
        ]
    )
    path.write_text("\n".join(lines))


def analyze(args: argparse.Namespace) -> Path:
    run_dir = args.run_dir.resolve()
    output_dir = args.output_dir.resolve()
    if not run_dir.is_dir():
        raise AnalysisError(f"PVS DRC run directory is missing: {run_dir}")
    try:
        output_dir.relative_to(run_dir)
    except ValueError:
        pass
    else:
        raise AnalysisError(
            "analysis output must be outside the immutable PVS run directory"
        )
    if output_dir.exists():
        raise AnalysisError(f"analysis output directory already exists: {output_dir}")

    status_path = require_file(run_dir / "pvs_drc_status.rpt", "PVS DRC status")
    replay_path = require_file(
        run_dir / "replay_contract_status.rpt",
        "PVS replay contract",
    )
    isolation_path = require_file(
        run_dir / "output_isolation.rpt",
        "PVS output isolation report",
    )
    references_path = require_file(
        run_dir / "external_references.rpt",
        "PVS external reference report",
    )
    control_path = require_file(run_dir / "pvsdrcctl", "executed PVS DRC control")

    expected_variant = args.expected_variant.upper()
    expected_density_state = (
        "DEFINED" if expected_variant == "DENSITY" else "UNDEFINED"
    )
    status = kv_report(status_path)
    replay = kv_report(replay_path)
    isolation = kv_report(isolation_path)
    if status.get("PVS_RC") != "0":
        raise AnalysisError(f"PVS tool return code is not zero: {status.get('PVS_RC')}")
    if status.get("PVS_DRC_STATUS") != "FAIL":
        raise AnalysisError(
            "this analyzer expects a classified nonzero DRC run, found "
            f"{status.get('PVS_DRC_STATUS', 'MISSING')}"
        )
    if status.get("PVS_DRC_VARIANT") != expected_variant:
        raise AnalysisError(
            f"this analyzer expects the {expected_variant.lower()} DRC variant, found "
            f"{status.get('PVS_DRC_VARIANT', 'MISSING')}"
        )
    if replay.get("STATUS") != "PASS" or replay.get("MODE") != "DRC":
        raise AnalysisError("strict DRC replay contract did not pass")
    if isolation.get("STATUS") != "PASS" or isolation.get("MODE") != "DRC":
        raise AnalysisError("PVS DRC output isolation did not pass")
    if any(
        line.startswith("MISSING=")
        for line in references_path.read_text(errors="replace").splitlines()
    ):
        raise AnalysisError("the PVS DRC run contains missing external references")

    summary_path = require_file(
        report_path(isolation, "DRC_SUMMARY", run_dir, "*_drc.sum"),
        "PVS DRC summary",
    )
    error_path = require_file(
        report_path(isolation, "DRC_RESULTS_DB", run_dir, "*_drc.err"),
        "PVS ASCII DRC error database",
    )
    for label, path in (
        ("PVS DRC summary", summary_path),
        ("PVS ASCII DRC error database", error_path),
    ):
        try:
            path.relative_to(run_dir)
        except ValueError as error:
            raise AnalysisError(
                f"{label} escaped the immutable run directory: {path}"
            ) from error
    rules, total_primary, total_expanded, declared_rulechecks, metadata = (
        parse_summary(summary_path)
    )
    nonzero_rules = [rule for rule in rules if rule.primary or rule.expanded]
    if not nonzero_rules:
        raise AnalysisError("classified FAIL run has no nonzero RULECHECK records")
    if sum(rule.primary for rule in nonzero_rules) != total_primary:
        raise AnalysisError(
            "primary result count does not reconcile between per-rule and total "
            f"records: per_rule={sum(rule.primary for rule in nonzero_rules)} "
            f"total={total_primary}"
        )
    if sum(rule.expanded for rule in nonzero_rules) != total_expanded:
        raise AnalysisError(
            "expanded result count does not reconcile between per-rule and total "
            f"records: per_rule={sum(rule.expanded for rule in nonzero_rules)} "
            f"total={total_expanded}"
        )
    if int(status.get("DRC_TOTAL_PRIMARY", "-1")) != total_primary:
        raise AnalysisError("status and summary primary DRC totals disagree")
    if int(status.get("DRC_TOTAL_EXPANDED", "-1")) != total_expanded:
        raise AnalysisError("status and summary expanded DRC totals disagree")
    if args.expected_primary is not None and total_primary != args.expected_primary:
        raise AnalysisError(
            f"unexpected primary DRC total: {total_primary}, "
            f"expected {args.expected_primary}"
        )
    if args.expected_expanded is not None and total_expanded != args.expected_expanded:
        raise AnalysisError(
            f"unexpected expanded DRC total: {total_expanded}, "
            f"expected {args.expected_expanded}"
        )

    layout_top, dbu_per_um, evidence = parse_error_database(
        error_path,
        nonzero_rules,
    )
    for name, item in evidence.items():
        if item.header_primary != item.rule.primary:
            raise AnalysisError(
                f"ASCII error header and summary primary count disagree for {name}"
            )
        if item.header_expanded != item.rule.expanded:
            raise AnalysisError(
                f"ASCII error header and summary expanded count disagree for {name}"
            )
        if len(item.geometries) != item.rule.primary:
            raise AnalysisError(
                f"ASCII result geometry count does not reconcile for {name}: "
                f"geometry={len(item.geometries)} primary={item.rule.primary}"
            )

    control_text = control_path.read_text(errors="replace")
    density_state = symbol_state(control_text, "DENSITY")
    antenna_state = symbol_state(control_text, "VAR_ANT_RATIO")
    if density_state != expected_density_state:
        raise AnalysisError(
            f"expected {expected_variant.lower()} DRC with DENSITY "
            f"{expected_density_state.lower()}, found {density_state}"
        )
    if antenna_state not in {"DEFINED", "UNDEFINED"}:
        raise AnalysisError(
            "VAR_ANT_RATIO control state is not deterministic: "
            f"{antenna_state}"
        )
    if replay.get("LAYOUT_TOP") and replay["LAYOUT_TOP"] != layout_top:
        raise AnalysisError(
            "replay and ASCII error database layout tops disagree: "
            f"replay={replay['LAYOUT_TOP']} error_database={layout_top}"
        )
    summary_top = metadata.get("Layout Primary Cell")
    if summary_top and summary_top != layout_top:
        raise AnalysisError(
            "summary and ASCII error database layout tops disagree: "
            f"summary={summary_top} error_database={layout_top}"
        )

    waiver_markers = parse_waiver_markers(args.innovus_waiver_tsv)
    ordered = sorted(
        evidence.values(),
        key=lambda item: (-item.rule.primary, item.rule.name),
    )
    all_geometries = [
        geometry for item in ordered for geometry in item.geometries
    ]
    antenna_rules = [
        item
        for item in ordered
        if rule_classification(item.rule.name, item.description)
        == "ANTENNA_RULE"
    ]
    non_antenna = [
        item
        for item in ordered
        if rule_classification(item.rule.name, item.description)
        == "NON_ANTENNA_REVIEW"
    ]
    antenna_primary = sum(item.rule.primary for item in antenna_rules)
    antenna_expanded = sum(item.rule.expanded for item in antenna_rules)
    explicit_term_rule_count = sum(
        antenna_classification_basis(item.rule.name, item.description)
        == "EXPLICIT_ANTENNA_TERM"
        for item in antenna_rules
    )
    gate_area_ratio_rule_count = sum(
        antenna_classification_basis(item.rule.name, item.description)
        == "CONDUCTOR_AREA_TO_CONNECTED_GATE_AREA_RATIO"
        for item in antenna_rules
    )
    non_antenna_primary = sum(item.rule.primary for item in non_antenna)
    non_antenna_expanded = sum(item.rule.expanded for item in non_antenna)
    if antenna_primary + non_antenna_primary != total_primary:
        raise AnalysisError("antenna/non-antenna primary result partition failed")
    if antenna_expanded + non_antenna_expanded != total_expanded:
        raise AnalysisError("antenna/non-antenna expanded result partition failed")

    correlations: dict[str, list[Geometry]] = defaultdict(list)
    for marker in waiver_markers:
        search_box = expanded_box(marker.box, args.correlation_margin_um)
        for geometry in all_geometries:
            if overlaps(search_box, geometry_box(geometry)):
                correlations[marker.net].append(geometry)

    output_dir.mkdir(parents=True)
    rule_tsv = output_dir / "pvs_drc_rule_inventory.tsv"
    non_antenna_tsv = output_dir / "pvs_drc_non_antenna_rules.tsv"
    antenna_tsv = output_dir / "pvs_drc_antenna_rules.tsv"
    geometry_tsv = output_dir / "pvs_drc_marker_geometry.tsv"
    bin_tsv = output_dir / "pvs_drc_spatial_bins.tsv"
    correlation_tsv = output_dir / "pvs_innovus_marker_correlation.tsv"
    markdown_path = output_dir / "pvs_drc_non_antenna_analysis.md"
    status_output = output_dir / "pvs_drc_analysis_status.rpt"

    rule_header = [
        "rank",
        "rule",
        "primary_results",
        "expanded_results",
        "share_of_total_pct",
        "classification",
        "classification_basis",
        "category",
        "layer_or_object",
        "description",
        "geometry_record_count",
        "aggregate_bbox_um",
        "repair_guidance",
    ]
    rule_rows: list[list[object]] = []
    for rank, item in enumerate(ordered, start=1):
        category = semantic_category(item.rule.name, item.description)
        rule_rows.append(
            [
                rank,
                item.rule.name,
                item.rule.primary,
                item.rule.expanded,
                f"{100.0 * item.rule.primary / total_primary:.6f}",
                rule_classification(item.rule.name, item.description),
                antenna_classification_basis(item.rule.name, item.description),
                category,
                affected_layer(item.rule.name, item.description),
                item.description,
                len(item.geometries),
                rule_bbox(item.geometries),
                repair_guidance(category),
            ]
        )
    write_tsv(rule_tsv, rule_header, rule_rows)
    write_tsv(
        non_antenna_tsv,
        rule_header,
        [
            row
            for row in rule_rows
            if row[5] == "NON_ANTENNA_REVIEW"
        ],
    )
    write_tsv(
        antenna_tsv,
        rule_header,
        [row for row in rule_rows if row[5] == "ANTENNA_RULE"],
    )

    geometry_rows: list[list[object]] = []
    for item in ordered:
        classification = rule_classification(item.rule.name, item.description)
        category = semantic_category(item.rule.name, item.description)
        layer = affected_layer(item.rule.name, item.description)
        for geometry in item.geometries:
            geometry_rows.append(
                [
                    item.rule.name,
                    item.description,
                    classification,
                    antenna_classification_basis(
                        item.rule.name,
                        item.description,
                    ),
                    category,
                    layer,
                    geometry.result_index,
                    geometry.geometry_type,
                    len(geometry.vertices),
                    f"{geometry.llx:.6f}",
                    f"{geometry.lly:.6f}",
                    f"{geometry.urx:.6f}",
                    f"{geometry.ury:.6f}",
                    f"{geometry.cx:.6f}",
                    f"{geometry.cy:.6f}",
                    f"{geometry.urx - geometry.llx:.6f}",
                    f"{geometry.ury - geometry.lly:.6f}",
                ]
            )
    write_tsv(
        geometry_tsv,
        [
            "rule",
            "description",
            "classification",
            "classification_basis",
            "category",
            "layer_or_object",
            "result_index",
            "geometry_type",
            "vertex_count",
            "llx_um",
            "lly_um",
            "urx_um",
            "ury_um",
            "center_x_um",
            "center_y_um",
            "width_um",
            "height_um",
        ],
        geometry_rows,
    )

    spatial: dict[tuple[int, int], list[Geometry]] = defaultdict(list)
    for geometry in all_geometries:
        spatial[
            (
                math.floor(geometry.cx / args.spatial_bin_um),
                math.floor(geometry.cy / args.spatial_bin_um),
            )
        ].append(geometry)
    spatial_rows: list[list[object]] = []
    for (x_index, y_index), geometries in sorted(
        spatial.items(),
        key=lambda item: (-len(item[1]), item[0][1], item[0][0]),
    ):
        spatial_rows.append(
            [
                len(geometries),
                f"{x_index * args.spatial_bin_um:.6f}",
                f"{y_index * args.spatial_bin_um:.6f}",
                f"{(x_index + 1) * args.spatial_bin_um:.6f}",
                f"{(y_index + 1) * args.spatial_bin_um:.6f}",
                ",".join(sorted({geometry.rule for geometry in geometries})),
                ",".join(
                    f"{geometry.rule}:{geometry.result_index}"
                    for geometry in geometries
                ),
            ]
        )
    write_tsv(
        bin_tsv,
        [
            "result_count",
            "bin_llx_um",
            "bin_lly_um",
            "bin_urx_um",
            "bin_ury_um",
            "rules",
            "result_ids",
        ],
        spatial_rows,
    )

    correlation_rows: list[list[object]] = []
    for marker in waiver_markers:
        for geometry in correlations.get(marker.net, []):
            correlation_rows.append(
                [
                    marker.net,
                    " ".join(f"{value:.6f}" for value in marker.box),
                    f"{args.correlation_margin_um:.6f}",
                    geometry.rule,
                    geometry.result_index,
                    f"{geometry.llx:.6f} {geometry.lly:.6f} "
                    f"{geometry.urx:.6f} {geometry.ury:.6f}",
                    f"{geometry.cx:.6f}",
                    f"{geometry.cy:.6f}",
                ]
            )
    write_tsv(
        correlation_tsv,
        [
            "innovus_net",
            "innovus_marker_box_um",
            "search_margin_um",
            "pvs_rule",
            "pvs_result_index",
            "pvs_bbox_um",
            "pvs_center_x_um",
            "pvs_center_y_um",
        ],
        correlation_rows,
    )

    write_markdown(
        markdown_path,
        run_dir=run_dir,
        summary_path=summary_path,
        error_path=error_path,
        control_path=control_path,
        layout_top=layout_top,
        total_primary=total_primary,
        total_expanded=total_expanded,
        drc_variant=expected_variant,
        density_state=density_state,
        antenna_state=antenna_state,
        ordered=ordered,
        waiver_markers=waiver_markers,
        correlations=correlations,
        geometry_tsv=geometry_tsv,
        rule_tsv=rule_tsv,
        antenna_tsv=antenna_tsv,
        non_antenna_tsv=non_antenna_tsv,
        bin_tsv=bin_tsv,
    )

    waiver_hit_results = {
        (geometry.rule, geometry.result_index)
        for hits in correlations.values()
        for geometry in hits
    }
    status_lines = [
        "LABEL=SPADMIC_PVS_DRC_RULE_ANALYSIS",
        "STATUS=PASS",
        "RESULT=PVS_DRC_RULE_DEBT_CLASSIFIED",
        f"RUN_DIR={run_dir}",
        f"OUTPUT_DIR={output_dir}",
        "SOURCE_RUN_MUTATION_AUTHORIZED=NO",
        "OUTPUT_LOCATION_STATUS=OUTSIDE_IMMUTABLE_SOURCE_RUN",
        "REPLAY_CONTRACT_STATUS=PASS",
        "OUTPUT_ISOLATION_STATUS=PASS",
        "PVS_RC=0",
        "PVS_DRC_STATUS=FAIL",
        f"PVS_DRC_VARIANT={expected_variant}",
        f"LAYOUT_TOP={layout_top}",
        f"DBU_PER_UM={dbu_per_um}",
        f"DECLARED_RULECHECK_COUNT={declared_rulechecks}",
        f"NONZERO_RULE_COUNT={len(nonzero_rules)}",
        f"DRC_TOTAL_PRIMARY={total_primary}",
        f"DRC_TOTAL_EXPANDED={total_expanded}",
        "RESULT_COUNT_RECONCILIATION=PASS",
        "ASCII_ERROR_GEOMETRY_RECONCILIATION=PASS",
        "ANTENNA_CLASSIFICATION_POLICY="
        "EXPLICIT_TERM_OR_CONDUCTOR_AREA_TO_CONNECTED_GATE_AREA_RATIO",
        "AMBIGUOUS_RULE_POLICY=RETAIN_AS_NON_ANTENNA_REVIEW",
        f"VAR_ANT_RATIO_STATE={antenna_state}",
        "VAR_ANT_RATIO_SCOPE=ADDITIONAL_OPTIONAL_RULE_FAMILY_ONLY",
        f"DENSITY_STATE={density_state}",
        f"ANTENNA_RULE_COUNT={len(antenna_rules)}",
        f"ANTENNA_PRIMARY_RESULT_COUNT={antenna_primary}",
        f"ANTENNA_EXPANDED_RESULT_COUNT={antenna_expanded}",
        f"ANTENNA_EXPLICIT_TERM_RULE_COUNT={explicit_term_rule_count}",
        f"ANTENNA_GATE_AREA_RATIO_RULE_COUNT={gate_area_ratio_rule_count}",
        "ANTENNA_RESULT_STATUS="
        f"{'NONZERO' if antenna_primary else 'ZERO'}",
        f"NON_ANTENNA_RULE_COUNT={len(non_antenna)}",
        f"NON_ANTENNA_PRIMARY_RESULT_COUNT={non_antenna_primary}",
        f"NON_ANTENNA_EXPANDED_RESULT_COUNT={non_antenna_expanded}",
        "NON_ANTENNA_RESULT_STATUS="
        f"{'NONZERO' if non_antenna_primary else 'ZERO'}",
        f"INNOVUS_WAIVER_MARKER_COUNT={len(waiver_markers)}",
        "INNOVUS_WAIVER_MARKERS_WITH_PVS_HITS="
        f"{sum(bool(correlations.get(marker.net)) for marker in waiver_markers)}",
        f"PVS_RESULTS_OVERLAPPING_WAIVER_BOXES={len(waiver_hit_results)}",
        f"CORRELATION_MARGIN_UM={args.correlation_margin_um:.6f}",
        f"SPATIAL_BIN_UM={args.spatial_bin_um:.6f}",
        f"SUMMARY={summary_path}",
        f"SUMMARY_SHA256={sha256(summary_path)}",
        f"ASCII_ERROR_DATABASE={error_path}",
        f"ASCII_ERROR_DATABASE_SHA256={sha256(error_path)}",
        f"CONTROL={control_path}",
        f"CONTROL_SHA256={sha256(control_path)}",
        f"RULE_INVENTORY={rule_tsv}",
        f"NON_ANTENNA_RULES={non_antenna_tsv}",
        f"ANTENNA_RULES={antenna_tsv}",
        f"MARKER_GEOMETRY={geometry_tsv}",
        f"SPATIAL_BINS={bin_tsv}",
        f"INNOVUS_CORRELATION={correlation_tsv}",
        f"MARKDOWN_REPORT={markdown_path}",
        f"RULE_DECK_TITLE={metadata.get('Rule Deck Title', 'UNKNOWN')}",
        f"LAYOUT_SYSTEM={metadata.get('Layout System', 'UNKNOWN')}",
        f"LAYOUT_DEPTH={metadata.get('Layout Depth', 'UNKNOWN')}",
        f"TEXT_DEPTH={metadata.get('Text Depth', 'UNKNOWN')}",
        "LVS_MATCH_STATUS=UNCHANGED_SEPARATE_GATE",
        *(
            [
                "PVS_BASE_DRC_STATUS=FAIL",
                "PVS_DENSITY_DRC_STATUS=NOT_RUN",
            ]
            if expected_variant == "BASE"
            else [
                "PVS_BASE_DRC_STATUS=UNCHANGED_SEPARATE_GATE",
                "PVS_DENSITY_DRC_STATUS=FAIL",
            ]
        ),
        "FINAL_SIGNOFF_READY=NO",
        "BLOCK_PROMOTION_AUTHORIZED=NO",
    ]
    status_output.write_text("\n".join(status_lines) + "\n")
    return status_output


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    parser.add_argument("--expected-primary", type=int)
    parser.add_argument("--expected-expanded", type=int)
    parser.add_argument(
        "--expected-variant",
        choices=("base", "density"),
        default="base",
    )
    parser.add_argument("--innovus-waiver-tsv", type=Path)
    parser.add_argument("--correlation-margin-um", type=float, default=0.35)
    parser.add_argument("--spatial-bin-um", type=float, default=10.0)
    args = parser.parse_args()
    if args.correlation_margin_um < 0:
        raise SystemExit("ERROR: --correlation-margin-um must be nonnegative")
    if args.spatial_bin_um <= 0:
        raise SystemExit("ERROR: --spatial-bin-um must be positive")
    try:
        status = analyze(args)
    except (AnalysisError, OSError, ValueError) as error:
        raise SystemExit(f"ERROR: {error}") from error
    print(status.read_text(), end="")


if __name__ == "__main__":
    main()
