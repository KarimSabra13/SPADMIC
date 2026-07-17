#!/usr/bin/env python3
"""Collect bounded semantic evidence from an immutable XH018 PVS setup."""

from __future__ import annotations

import argparse
import hashlib
import re
import shutil
import subprocess
import tempfile
from dataclasses import dataclass, field
from pathlib import Path


SYMBOLS = ("DENSITY", "POPPING", "PIMIDE", "DUMMY_FILL", "VAR_ANT_RATIO")
OPTION_RE = re.compile(
    r"-option\s+\"?([A-Za-z_][A-Za-z0-9_]*)\"?.*?"
    r"-default\s+\"?([^\"\s]+)",
    re.IGNORECASE,
)
CONDITIONAL_RE = re.compile(
    r"^\s*#\s*(IFDEF|IFNDEF|IF)\b(?:\s+([A-Za-z_][A-Za-z0-9_]*))?",
    re.IGNORECASE,
)
ELSE_RE = re.compile(r"^\s*#\s*ELSE\b", re.IGNORECASE)
ENDIF_RE = re.compile(r"^\s*#\s*ENDIF\b", re.IGNORECASE)
GUIDE_TERMS_RE = re.compile(
    r"POPPING|PIMIDE|DUMMY(?:_FILL)?|VAR_ANT|rule\s*set|default",
    re.IGNORECASE,
)


@dataclass
class ConditionalBlock:
    directive: str
    symbol: str
    start: int
    else_lines: list[int] = field(default_factory=list)
    end: int = -1


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def sha256_text(lines: list[str]) -> str:
    payload = ("\n".join(lines) + "\n").encode("utf-8", errors="replace")
    return hashlib.sha256(payload).hexdigest()


def write_lines(path: Path, lines: list[str]) -> None:
    path.write_text("\n".join(lines) + "\n")


def numbered_source(label: str, paths: list[Path]) -> list[str]:
    output = [f"LABEL={label}"]
    for path in paths:
        lines = path.read_text(errors="replace").splitlines()
        output.extend(
            [
                f"FILE_BEGIN={path}",
                f"FILE_BYTES={path.stat().st_size}",
                f"FILE_SHA256={sha256_file(path)}",
            ]
        )
        output.extend(f"{index}:{line}" for index, line in enumerate(lines, 1))
        output.append(f"FILE_END={path}")
    return output


def parse_conditional_blocks(lines: list[str]) -> tuple[list[ConditionalBlock], int]:
    stack: list[ConditionalBlock] = []
    completed: list[ConditionalBlock] = []
    unmatched_endif = 0

    for index, line in enumerate(lines):
        start_match = CONDITIONAL_RE.match(line)
        if start_match:
            stack.append(
                ConditionalBlock(
                    directive=start_match.group(1).upper(),
                    symbol=(start_match.group(2) or "").upper(),
                    start=index,
                )
            )
            continue
        if ELSE_RE.match(line):
            if stack:
                stack[-1].else_lines.append(index)
            continue
        if ENDIF_RE.match(line):
            if not stack:
                unmatched_endif += 1
                continue
            block = stack.pop()
            block.end = index
            if block.symbol in SYMBOLS:
                completed.append(block)

    return sorted(completed, key=lambda item: item.start), len(stack) + unmatched_endif


def selected_block_indexes(
    lines: list[str], block: ConditionalBlock, max_full_lines: int
) -> tuple[list[int], bool]:
    indexes = list(range(block.start, block.end + 1))
    if len(indexes) <= max_full_lines:
        return indexes, False

    selected = set(indexes[:30] + indexes[-20:])
    semantic_re = re.compile(
        r"^\s*(?:#|rule\b|caption\b|VARIABLE\b)|"
        r"popping|pimide|dummy|antenna|variable ratio",
        re.IGNORECASE,
    )
    if block.symbol != "DENSITY":
        semantic_indexes = [index for index in indexes if semantic_re.search(lines[index])]
        selected.update(semantic_indexes[:220])
        selected.update(semantic_indexes[-40:])
    return sorted(selected), True


def collect_guide_evidence(guide: Path, output: Path) -> tuple[str, str]:
    report = [
        "LABEL=SPADMIC_POSITION_PVS_DRC_RULE_SEMANTICS_USER_GUIDE_SCAN",
        f"USER_GUIDE={guide}",
    ]
    if not guide.is_file():
        report.extend(["USER_GUIDE_TEXT_STATUS=NOT_PRESENT", "MATCHING_LINE_COUNT=0"])
        write_lines(output, report)
        return "NOT_PRESENT", ""

    guide_sha = sha256_file(guide)
    report.extend(
        [
            f"USER_GUIDE_BYTES={guide.stat().st_size}",
            f"USER_GUIDE_SHA256={guide_sha}",
        ]
    )
    tool = shutil.which("pdftotext")
    if tool is None:
        report.extend(["PDFTOTEXT_TOOL=NOT_FOUND", "USER_GUIDE_TEXT_STATUS=TOOL_UNAVAILABLE", "MATCHING_LINE_COUNT=0"])
        write_lines(output, report)
        return "TOOL_UNAVAILABLE", guide_sha

    with tempfile.NamedTemporaryFile(
        prefix="position_pvs_user_guide_", suffix=".txt", dir=output.parent, delete=False
    ) as stream:
        text_path = Path(stream.name)
    try:
        result = subprocess.run(
            [tool, "-layout", str(guide), str(text_path)],
            text=True,
            capture_output=True,
            check=False,
        )
        report.extend([f"PDFTOTEXT_TOOL={tool}", f"PDFTOTEXT_RC={result.returncode}"])
        if result.returncode != 0:
            report.extend(
                [
                    "USER_GUIDE_TEXT_STATUS=EXTRACTION_FAILED",
                    "MATCHING_LINE_COUNT=0",
                    f"PDFTOTEXT_STDERR={result.stderr.strip()[:500]}",
                ]
            )
            status = "EXTRACTION_FAILED"
        else:
            lines = text_path.read_text(errors="replace").splitlines()
            matches = [index for index, line in enumerate(lines) if GUIDE_TERMS_RE.search(line)]
            selected: set[int] = set()
            for index in matches[:120]:
                selected.update(range(max(0, index - 2), min(len(lines), index + 3)))
            status = "PASS_MATCHES_FOUND" if matches else "PASS_NO_MATCHES"
            report.extend(
                [
                    f"USER_GUIDE_TEXT_STATUS={status}",
                    f"MATCHING_LINE_COUNT={len(matches)}",
                ]
            )
            report.extend(f"{index + 1}:{lines[index]}" for index in sorted(selected))
            if len(matches) > 120:
                report.append("USER_GUIDE_CONTEXT_TRUNCATED=YES")
    finally:
        text_path.unlink(missing_ok=True)

    write_lines(output, report)
    return status, guide_sha


def collect(args: argparse.Namespace) -> int:
    output = args.output_dir.resolve()
    output.mkdir(parents=True, exist_ok=True)

    required_paths = [
        args.project_techrulesets,
        args.pdk_techrulesets,
        args.metalswitch,
        args.revision,
        args.drc_rule,
        args.pvs_config,
        args.dummy_config,
        args.dummy_output,
        args.density_selector,
    ]
    required_paths = [path.resolve() for path in required_paths]
    required_gate = all(path.is_file() and path.stat().st_size > 0 for path in required_paths)
    if not required_gate:
        missing = [str(path) for path in required_paths if not path.is_file() or path.stat().st_size == 0]
        write_lines(
            output / "rule_semantics_collector_status.rpt",
            [
                "LABEL=SPADMIC_POSITION_PVS_DRC_RULE_SEMANTICS_COLLECTOR",
                "COLLECTOR_STATUS=FAIL",
                "SOURCE_REQUIRED_FILE_GATE_STATUS=FAIL",
                *[f"MISSING_OR_EMPTY={path}" for path in missing],
                "STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO",
                "PVS_REPLAY_AUTHORIZED=NO",
                "PVS_EXECUTED=NO",
            ],
        )
        return 1

    before_hashes = {path: sha256_file(path) for path in required_paths}
    guide_path = args.user_guide.resolve()
    guide_before = sha256_file(guide_path) if guide_path.is_file() else ""

    project_rules = args.project_techrulesets.resolve()
    pdk_rules = args.pdk_techrulesets.resolve()
    drc_rule = args.drc_rule.resolve()
    pvs_config = args.pvs_config.resolve()

    write_lines(
        output / "named_rule_sets_numbered.rpt",
        numbered_source(
            "SPADMIC_POSITION_PVS_DRC_NAMED_RULE_SETS",
            [project_rules, pdk_rules],
        ),
    )
    write_lines(
        output / "metalswitch_and_revision_numbered.rpt",
        numbered_source(
            "SPADMIC_POSITION_PVS_DRC_METALSWITCH_AND_REVISION",
            [args.metalswitch.resolve(), args.revision.resolve()],
        ),
    )

    project_text = project_rules.read_text(errors="replace")
    pdk_text = pdk_rules.read_text(errors="replace")
    project_default_count = len(re.findall(r"(?<![A-Za-z0-9_])default(?![A-Za-z0-9_])", project_text, re.IGNORECASE))
    pdk_default_count = len(re.findall(r"(?<![A-Za-z0-9_])default(?![A-Za-z0-9_])", pdk_text, re.IGNORECASE))
    project_drc_count = len(re.findall(r"\bDrcRules\b", project_text, re.IGNORECASE))
    pdk_drc_count = len(re.findall(r"\bDrcRules\b", pdk_text, re.IGNORECASE))
    default_gate = (
        project_default_count > 0
        and pdk_default_count > 0
        and project_drc_count > 0
        and pdk_drc_count > 0
    )

    config_lines = pvs_config.read_text(errors="replace").splitlines()
    option_hits: dict[str, list[tuple[int, str, str]]] = {symbol: [] for symbol in SYMBOLS}
    for index, line in enumerate(config_lines, 1):
        match = OPTION_RE.search(line)
        if not match:
            continue
        symbol = match.group(1).upper()
        if symbol in option_hits:
            option_hits[symbol].append((index, match.group(2), line))

    option_report = ["symbol\tmatch_count\tdefault\tline"]
    option_gate = True
    for symbol in SYMBOLS:
        hits = option_hits[symbol]
        defaults = sorted({default for _, default, _ in hits})
        if not hits or defaults != ["0"]:
            option_gate = False
        rendered = ";".join(f"{line_number}:{line}" for line_number, _, line in hits)
        option_report.append(
            f"{symbol}\t{len(hits)}\t{','.join(defaults)}\t{rendered}"
        )
    write_lines(output / "pdk_config_option_defaults.tsv", option_report)

    drc_lines = drc_rule.read_text(errors="replace").splitlines()
    blocks, unmatched_count = parse_conditional_blocks(drc_lines)
    block_counts = {symbol: 0 for symbol in SYMBOLS}
    block_summary = [
        "symbol\tdirective\tstart_line\telse_lines\tend_line\tline_count\tsegment_sha256\trule_count\tcaption_count"
    ]
    block_context = [
        "LABEL=SPADMIC_POSITION_PVS_DRC_CONDITIONAL_BLOCK_CONTEXT",
        f"SOURCE={drc_rule}",
        f"SOURCE_SHA256={before_hashes[drc_rule]}",
    ]
    for block in blocks:
        block_counts[block.symbol] += 1
        segment = drc_lines[block.start : block.end + 1]
        rule_count = sum(bool(re.match(r"^\s*rule\b", line, re.IGNORECASE)) for line in segment)
        caption_count = sum(bool(re.match(r"^\s*caption\b", line, re.IGNORECASE)) for line in segment)
        block_summary.append(
            "\t".join(
                [
                    block.symbol,
                    block.directive,
                    str(block.start + 1),
                    ",".join(str(line + 1) for line in block.else_lines),
                    str(block.end + 1),
                    str(len(segment)),
                    sha256_text(segment),
                    str(rule_count),
                    str(caption_count),
                ]
            )
        )
        selected, truncated = selected_block_indexes(
            drc_lines, block, args.max_full_block_lines
        )
        block_context.extend(
            [
                f"BLOCK_BEGIN={block.symbol}:{block.start + 1}",
                f"DIRECTIVE={block.directive}",
                f"END_LINE={block.end + 1}",
                f"LINE_COUNT={len(segment)}",
                f"SEGMENT_SHA256={sha256_text(segment)}",
                f"FULL_BLOCK_RECORDED={'NO' if truncated else 'YES'}",
            ]
        )
        block_context.extend(f"{index + 1}:{drc_lines[index]}" for index in selected)
        if truncated:
            block_context.append("BLOCK_CONTEXT_TRUNCATED=YES")
        block_context.append(f"BLOCK_END={block.symbol}:{block.end + 1}")

    write_lines(output / "directive_conditional_block_summary.tsv", block_summary)
    write_lines(output / "directive_conditional_block_context.rpt", block_context)
    block_gate = unmatched_count == 0 and all(block_counts[symbol] > 0 for symbol in SYMBOLS)

    guide_status, _ = collect_guide_evidence(
        guide_path, output / "user_guide_semantic_scan.rpt"
    )

    expected_hashes = {
        drc_rule: args.expected_drc_sha,
        pvs_config: args.expected_pvs_config_sha,
        args.dummy_config.resolve(): args.expected_dummy_config_sha,
        args.dummy_output.resolve(): args.expected_dummy_output_sha,
        args.density_selector.resolve(): args.expected_density_selector_sha,
    }
    known_hash_gate = all(
        not expected or before_hashes[path] == expected
        for path, expected in expected_hashes.items()
    )

    semantic_contract = [
        "LABEL=SPADMIC_POSITION_PVS_DRC_RULE_SEMANTIC_CONTRACT",
        "DIRECTIVE=DENSITY",
        "PDK_DEFAULT=0",
        "CLASS=OPTIONAL_BASE_DECK_DENSITY_FAMILY",
        "POSITION_POLICY=SEPARATE_DENSITY_DRC_REQUIRED",
        "DIRECTIVE=POPPING",
        "PDK_DEFAULT=0",
        "CLASS=OPTIONAL_IMD_POPPING_CHECK_FAMILY",
        "POSITION_APPLICABILITY_STATUS=REVIEW_REQUIRED",
        "DIRECTIVE=PIMIDE",
        "PDK_DEFAULT=0",
        "CLASS=OPTIONAL_PAD_MARKER_BRANCH",
        "POSITION_APPLICABILITY_STATUS=REVIEW_REQUIRED",
        "DIRECTIVE=DUMMY_FILL",
        "PDK_DEFAULT=0",
        "CLASS=DUMMY_PATTERN_GENERATION_AND_OUTPUT_SELECTOR",
        "POSITION_APPLICABILITY_STATUS=REVIEW_REQUIRED",
        "DIRECTIVE=VAR_ANT_RATIO",
        "PDK_DEFAULT=0",
        "PRIMARY_SEED_STATE=DEFINED",
        "CLASS=ADDITIONAL_VARIABLE_RATIO_ANTENNA_FAMILY",
        "POSITION_POLICY_STATUS=REVIEW_REQUIRED",
        "DEFAULT_RULE_SET_SELECTION_STATUS=REVIEW_REQUIRED",
        "STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO",
        "PVS_REPLAY_AUTHORIZED=NO",
        "PVS_EXECUTED=NO",
    ]
    write_lines(output / "rule_semantic_contract.rpt", semantic_contract)

    after_hashes = {path: sha256_file(path) for path in required_paths}
    source_recheck = before_hashes == after_hashes
    guide_after = sha256_file(guide_path) if guide_path.is_file() else ""
    guide_recheck = guide_before == guide_after

    source_report = ["path\tbytes\tsha256_before\tsha256_after\tunchanged"]
    for path in required_paths:
        source_report.append(
            f"{path}\t{path.stat().st_size}\t{before_hashes[path]}\t{after_hashes[path]}\t"
            f"{'YES' if before_hashes[path] == after_hashes[path] else 'NO'}"
        )
    if guide_path.is_file():
        source_report.append(
            f"{guide_path}\t{guide_path.stat().st_size}\t{guide_before}\t{guide_after}\t"
            f"{'YES' if guide_recheck else 'NO'}"
        )
    write_lines(output / "source_file_identity.tsv", source_report)

    status = "PASS" if all(
        (required_gate, known_hash_gate, source_recheck, guide_recheck, default_gate, option_gate, block_gate)
    ) else "FAIL"
    status_lines = [
        "LABEL=SPADMIC_POSITION_PVS_DRC_RULE_SEMANTICS_COLLECTOR",
        f"COLLECTOR_STATUS={status}",
        "SOURCE_REQUIRED_FILE_GATE_STATUS=PASS",
        f"KNOWN_SOURCE_HASH_GATE_STATUS={'PASS' if known_hash_gate else 'FAIL'}",
        f"SOURCE_RECHECK_STATUS={'PASS' if source_recheck and guide_recheck else 'FAIL'}",
        f"PROJECT_TECHRULESETS_SHA256={before_hashes[project_rules]}",
        f"PDK_TECHRULESETS_SHA256={before_hashes[pdk_rules]}",
        f"METALSWITCH_SHA256={before_hashes[args.metalswitch.resolve()]}",
        f"PVS_REVISION_SHA256={before_hashes[args.revision.resolve()]}",
        f"DRC_RULE_SHA256={before_hashes[drc_rule]}",
        f"PVS_CONFIG_SHA256={before_hashes[pvs_config]}",
        f"PROJECT_DEFAULT_TOKEN_COUNT={project_default_count}",
        f"PDK_DEFAULT_TOKEN_COUNT={pdk_default_count}",
        f"PROJECT_DRCRULES_REFERENCE_COUNT={project_drc_count}",
        f"PDK_DRCRULES_REFERENCE_COUNT={pdk_drc_count}",
        f"DEFAULT_RULE_SET_EVIDENCE_STATUS={'PASS' if default_gate else 'FAIL'}",
        f"PVS_CONFIG_OPTION_DEFAULT_GATE_STATUS={'PASS' if option_gate else 'FAIL'}",
    ]
    status_lines.extend(f"{symbol}_CONDITIONAL_BLOCK_COUNT={block_counts[symbol]}" for symbol in SYMBOLS)
    status_lines.extend(
        [
            f"UNMATCHED_CONDITIONAL_COUNT={unmatched_count}",
            f"DIRECTIVE_CONDITIONAL_BLOCK_GATE_STATUS={'PASS' if block_gate else 'FAIL'}",
            f"USER_GUIDE_TEXT_STATUS={guide_status}",
            "SEMANTIC_EVIDENCE_COLLECTION_STATUS=PASS" if status == "PASS" else "SEMANTIC_EVIDENCE_COLLECTION_STATUS=FAIL",
            "DEFAULT_RULE_SET_SELECTION_STATUS=REVIEW_REQUIRED",
            "POPPING_APPLICABILITY_STATUS=REVIEW_REQUIRED",
            "PIMIDE_APPLICABILITY_STATUS=REVIEW_REQUIRED",
            "DUMMY_FILL_APPLICABILITY_STATUS=REVIEW_REQUIRED",
            "VAR_ANT_RATIO_POLICY_STATUS=REVIEW_REQUIRED",
            "STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO",
            "PVS_REPLAY_AUTHORIZED=NO",
            "PVS_EXECUTED=NO",
        ]
    )
    write_lines(output / "rule_semantics_collector_status.rpt", status_lines)
    return 0 if status == "PASS" else 1


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-techrulesets", type=Path, required=True)
    parser.add_argument("--pdk-techrulesets", type=Path, required=True)
    parser.add_argument("--metalswitch", type=Path, required=True)
    parser.add_argument("--revision", type=Path, required=True)
    parser.add_argument("--drc-rule", type=Path, required=True)
    parser.add_argument("--pvs-config", type=Path, required=True)
    parser.add_argument("--dummy-config", type=Path, required=True)
    parser.add_argument("--dummy-output", type=Path, required=True)
    parser.add_argument("--density-selector", type=Path, required=True)
    parser.add_argument("--user-guide", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--expected-drc-sha", default="")
    parser.add_argument("--expected-pvs-config-sha", default="")
    parser.add_argument("--expected-dummy-config-sha", default="")
    parser.add_argument("--expected-dummy-output-sha", default="")
    parser.add_argument("--expected-density-selector-sha", default="")
    parser.add_argument("--max-full-block-lines", type=int, default=400)
    return parser.parse_args()


if __name__ == "__main__":
    raise SystemExit(collect(parse_args()))
