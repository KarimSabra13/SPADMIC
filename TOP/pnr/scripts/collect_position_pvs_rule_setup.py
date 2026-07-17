#!/usr/bin/env python3
"""Collect bounded, read-only evidence for a PVS technology mapping."""

from __future__ import annotations

import argparse
import csv
import hashlib
import os
import re
import shlex
import stat
from dataclasses import dataclass
from pathlib import Path


SYMBOLS = ("DENSITY", "POPPING", "PIMIDE", "DUMMY_FILL", "VAR_ANT_RATIO")
REFERENCE_RE = re.compile(
    r"include|rule.?deck|rules?\s+file|xh018[^\s]*drc|metalswitch",
    re.IGNORECASE,
)


@dataclass(frozen=True)
class Mapping:
    define_count: int
    undefine_count: int
    raw: str
    lexical: Path
    canonical: Path


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def write_lines(path: Path, lines: list[str]) -> None:
    path.write_text("\n".join(lines) + "\n")


def parse_mapping(techlib: Path, technology: str) -> Mapping:
    defines: list[str] = []
    undefine_count = 0

    for raw_line in techlib.read_text(errors="replace").splitlines():
        try:
            fields = shlex.split(raw_line, comments=True, posix=True)
        except ValueError:
            continue
        if len(fields) >= 2 and fields[0] == "UNDEFINE" and fields[1] == technology:
            undefine_count += 1
        if len(fields) >= 3 and fields[0] == "DEFINE" and fields[1] == technology:
            defines.append(fields[2])

    raw = defines[0] if len(defines) == 1 else ""
    raw_path = Path(raw) if raw else Path(".")
    lexical = raw_path if raw_path.is_absolute() else techlib.parent / raw_path
    lexical = Path(os.path.normpath(str(lexical)))
    canonical = Path(os.path.realpath(lexical))
    return Mapping(len(defines), undefine_count, raw, lexical, canonical)


def entry_type(path: Path) -> str:
    mode = path.lstat().st_mode
    if stat.S_ISLNK(mode):
        return "symlink"
    if stat.S_ISDIR(mode):
        return "directory"
    if stat.S_ISREG(mode):
        return "file"
    return "other"


def walk_bounded(root: Path, max_depth: int) -> list[Path]:
    if not root.exists():
        return []
    if not root.is_dir():
        return [root]

    entries: list[Path] = [root]
    pending: list[tuple[Path, int]] = [(root, 0)]
    while pending:
        directory, depth = pending.pop()
        if depth >= max_depth:
            continue
        try:
            children = sorted(directory.iterdir(), key=lambda item: str(item))
        except OSError:
            continue
        for child in children:
            entries.append(child)
            if child.is_dir() and not child.is_symlink():
                pending.append((child, depth + 1))
    return sorted(set(entries), key=lambda item: str(item))


def load_matrix(path: Path) -> tuple[list[dict[str, str]], list[dict[str, str]]]:
    with path.open(newline="") as stream:
        rows = list(csv.DictReader(stream, delimiter="\t"))
    defined = [row for row in rows if row.get("VAR_ANT_RATIO") == "DEFINED"]
    return rows, defined


def context_excerpt(lines: list[str], matches: list[int], radius: int = 2) -> list[str]:
    selected: set[int] = set()
    for index in matches[:80]:
        selected.update(range(max(0, index - radius), min(len(lines), index + radius + 1)))
    return [f"{index + 1}:{lines[index]}" for index in sorted(selected)]


def collect(args: argparse.Namespace) -> int:
    techlib = Path(os.path.abspath(args.techlib))
    matrix_path = Path(os.path.abspath(args.candidate_matrix))
    output = Path(os.path.abspath(args.output_dir))
    output.mkdir(parents=True, exist_ok=True)

    techlib_before = sha256_file(techlib)
    matrix_before = sha256_file(matrix_path)
    mapping = parse_mapping(techlib, args.technology)

    pdk_root = techlib.parent / ".xkit/setup/xh018/cadence/pvs/PVS"
    root_candidates = [mapping.canonical, Path(os.path.realpath(pdk_root))]
    search_roots: list[Path] = []
    for root in root_candidates:
        if root.exists() and root not in search_roots:
            search_roots.append(root)

    rows, defined_rows = load_matrix(matrix_path)

    mapping_lines = [
        "LABEL=SPADMIC_POSITION_PVS_DRC_PVTECH_MAPPING_RESOLUTION",
        f"TECHNOLOGY={args.technology}",
        f"TECHLIB_PATH={techlib}",
        f"TECHLIB_SHA256={techlib_before}",
        f"MAPPING_DEFINE_COUNT={mapping.define_count}",
        f"MAPPING_UNDEFINE_COUNT={mapping.undefine_count}",
        f"MAPPING_RAW={mapping.raw}",
        f"MAPPING_LEXICAL={mapping.lexical}",
        f"MAPPING_CANONICAL={mapping.canonical}",
        f"MAPPING_LEXICAL_EXISTS={'YES' if mapping.lexical.exists() else 'NO'}",
        f"MAPPING_CANONICAL_EXISTS={'YES' if mapping.canonical.exists() else 'NO'}",
        f"PDK_PVS_ROOT_CANDIDATE={pdk_root}",
        f"PDK_PVS_ROOT_EXISTS={'YES' if pdk_root.exists() else 'NO'}",
        "PREVIOUS_REFERENCE_RENDERING=/PVS",
        "PREVIOUS_REFERENCE_RENDERING_STATUS=TRUNCATED_RELATIVE_TOKEN",
    ]
    write_lines(output / "pvtech_mapping_resolution.rpt", mapping_lines)

    defined_lines = [
        "candidate\tDENSITY\tPOPPING\tPIMIDE\tDUMMY_FILL\tVAR_ANT_RATIO"
    ]
    for row in defined_rows:
        defined_lines.append(
            "\t".join(
                row.get(field, "")
                for field in (
                    "candidate",
                    "DENSITY",
                    "POPPING",
                    "PIMIDE",
                    "DUMMY_FILL",
                    "VAR_ANT_RATIO",
                )
            )
        )
    write_lines(output / "var_ant_defined_candidates.tsv", defined_lines)

    search_root_lines = ["LABEL=SPADMIC_POSITION_PVS_DRC_RULE_SETUP_SEARCH_ROOTS"]
    for root in search_roots:
        search_root_lines.append(f"SEARCH_ROOT={root}")
    write_lines(output / "rule_setup_search_roots.rpt", search_root_lines)

    inventory_lines = ["root\ttype\tbytes\tpath\tlink_target"]
    file_candidates: dict[str, Path] = {}
    for root in search_roots:
        for path in walk_bounded(root, args.max_depth):
            try:
                kind = entry_type(path)
                size = path.lstat().st_size
                link_target = os.readlink(path) if path.is_symlink() else ""
            except OSError:
                continue
            inventory_lines.append(
                f"{root}\t{kind}\t{size}\t{path}\t{link_target}"
            )
            if path.is_file():
                try:
                    canonical = str(path.resolve())
                except OSError:
                    canonical = str(path)
                file_candidates[canonical] = path
    write_lines(output / "rule_setup_inventory.tsv", inventory_lines)

    summary_lines = [
        "file\tbytes\tsha256\tDENSITY\tPOPPING\tPIMIDE\tDUMMY_FILL\tVAR_ANT_RATIO"
    ]
    context_lines = ["LABEL=SPADMIC_POSITION_PVS_DRC_DIRECTIVE_CONTEXT_EXCERPT"]
    reference_lines = ["LABEL=SPADMIC_POSITION_PVS_DRC_RULE_REFERENCE_EXCERPT"]
    skipped_lines = ["path\treason"]
    matched_file_count = 0
    scanned_text_file_count = 0

    symbol_patterns = {
        symbol: re.compile(
            rf"(?<![A-Za-z0-9_]){re.escape(symbol)}(?![A-Za-z0-9_])",
            re.IGNORECASE,
        )
        for symbol in SYMBOLS
    }

    for canonical, path in sorted(file_candidates.items()):
        try:
            size = path.stat().st_size
        except OSError:
            skipped_lines.append(f"{path}\tSTAT_FAILED")
            continue
        if size > args.max_file_bytes:
            skipped_lines.append(f"{path}\tSIZE_LIMIT_{size}")
            continue
        try:
            data = path.read_bytes()
        except OSError:
            skipped_lines.append(f"{path}\tREAD_FAILED")
            continue
        if b"\x00" in data[:8192]:
            skipped_lines.append(f"{path}\tBINARY")
            continue

        text = data.decode("utf-8", errors="replace")
        lines = text.splitlines()
        scanned_text_file_count += 1
        counts: dict[str, int] = {}
        matching_indexes: set[int] = set()
        for symbol, pattern in symbol_patterns.items():
            symbol_indexes = [index for index, line in enumerate(lines) if pattern.search(line)]
            counts[symbol] = len(symbol_indexes)
            matching_indexes.update(symbol_indexes)

        if any(counts.values()):
            matched_file_count += 1
            summary_lines.append(
                "\t".join(
                    [canonical, str(size), sha256_file(path)]
                    + [str(counts[symbol]) for symbol in SYMBOLS]
                )
            )
            context_lines.append(f"FILE_BEGIN={canonical}")
            context_lines.append(f"TOTAL_MATCHING_LINES={len(matching_indexes)}")
            context_lines.extend(context_excerpt(lines, sorted(matching_indexes)))
            if len(matching_indexes) > 80:
                context_lines.append("CONTEXT_TRUNCATED=YES")
            context_lines.append(f"FILE_END={canonical}")

        reference_indexes = [
            index for index, line in enumerate(lines) if REFERENCE_RE.search(line)
        ]
        if reference_indexes:
            reference_lines.append(f"FILE_BEGIN={canonical}")
            reference_lines.append(f"TOTAL_REFERENCE_LINES={len(reference_indexes)}")
            for index in reference_indexes[:120]:
                reference_lines.append(f"{index + 1}:{lines[index]}")
            if len(reference_indexes) > 120:
                reference_lines.append("REFERENCE_EXCERPT_TRUNCATED=YES")
            reference_lines.append(f"FILE_END={canonical}")

    write_lines(output / "directive_symbol_file_summary.tsv", summary_lines)
    write_lines(output / "directive_context_excerpt.rpt", context_lines)
    write_lines(output / "rule_reference_excerpt.rpt", reference_lines)
    write_lines(output / "rule_setup_skipped_files.tsv", skipped_lines)

    techlib_after = sha256_file(techlib)
    matrix_after = sha256_file(matrix_path)
    mapping_gate = (
        mapping.define_count == 1
        and mapping.undefine_count == 1
        and mapping.raw == args.expected_mapping
        and mapping.canonical.exists()
    )
    matrix_gate = len(rows) == args.expected_candidate_count and len(defined_rows) == 3
    scan_gate = bool(search_roots) and bool(file_candidates) and scanned_text_file_count > 0
    source_recheck = techlib_before == techlib_after and matrix_before == matrix_after
    status = "PASS" if mapping_gate and matrix_gate and scan_gate and source_recheck else "FAIL"

    status_lines = [
        "LABEL=SPADMIC_POSITION_PVS_DRC_RULE_SETUP_COLLECTOR",
        f"COLLECTOR_STATUS={status}",
        f"TECHLIB_PATH={techlib}",
        f"TECHLIB_SHA256={techlib_before}",
        f"MAPPING_RAW={mapping.raw}",
        f"MAPPING_LEXICAL={mapping.lexical}",
        f"MAPPING_CANONICAL={mapping.canonical}",
        f"MAPPING_GATE_STATUS={'PASS' if mapping_gate else 'FAIL'}",
        f"MATRIX_CANDIDATE_COUNT={len(rows)}",
        f"VAR_ANT_DEFINED_CANDIDATE_COUNT={len(defined_rows)}",
        f"MATRIX_GATE_STATUS={'PASS' if matrix_gate else 'FAIL'}",
        f"SEARCH_ROOT_COUNT={len(search_roots)}",
        f"INVENTORY_ENTRY_COUNT={len(inventory_lines) - 1}",
        f"RULE_FILE_CANDIDATE_COUNT={len(file_candidates)}",
        f"SCANNED_TEXT_FILE_COUNT={scanned_text_file_count}",
        f"DIRECTIVE_MATCH_FILE_COUNT={matched_file_count}",
        f"RULE_SETUP_SCAN_STATUS={'PASS' if scan_gate else 'FAIL'}",
        f"SOURCE_RECHECK_STATUS={'PASS' if source_recheck else 'FAIL'}",
        "PREPROCESSOR_SEMANTIC_REVIEW_STATUS=REVIEW_REQUIRED",
        "STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO",
        "PVS_REPLAY_AUTHORIZED=NO",
        "PVS_EXECUTED=NO",
    ]
    write_lines(output / "rule_setup_collector_status.rpt", status_lines)
    return 0 if status == "PASS" else 1


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--techlib", type=Path, required=True)
    parser.add_argument("--candidate-matrix", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--technology", default="XH018_1131")
    parser.add_argument("--expected-mapping", default=".pvsSetup/PVS")
    parser.add_argument("--expected-candidate-count", type=int, default=114)
    parser.add_argument("--max-depth", type=int, default=6)
    parser.add_argument("--max-file-bytes", type=int, default=16 * 1024 * 1024)
    return parser.parse_args()


if __name__ == "__main__":
    raise SystemExit(collect(parse_args()))
