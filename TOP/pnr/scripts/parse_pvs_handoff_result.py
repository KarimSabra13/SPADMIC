#!/usr/bin/env python3
"""Conservatively classify PVS DRC or LVS results."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


TEMPLATE_INPUTS = {
    "run.pvs",
    ".config.rul",
    ".technology.rul",
    ".preset.autosave",
    "pvsdrcctl",
    "pvslvsctl",
    "cell_tree.txt",
    "pipo1.setup",
    "pipo2.setup",
    "var_streamOutKeys.virtuoso",
    "var_cdlOutKeys.virtuoso",
}

DRC_TOTAL_PATTERN = re.compile(
    r"Total DRC Results\s*:\s*(\d+)\s*\((\d+)\)",
    re.I,
)
LVS_NEGATIVE_PATTERNS = [
    r"circuits?\s+(?:do\s+)?not\s+match",
    r"netlists?\s+(?:do\s+)?not\s+match",
    r"run\s+result\s*:\s*(?:fail|mismatch|incorrect)",
    r"lvs\s+result\s*:\s*(?:fail|mismatch|incorrect)",
]
LVS_POSITIVE_PATTERNS = [
    r"circuits?\s+match",
    r"netlists?\s+match",
    r"run\s+result\s*:\s*(?:pass|match|correct)",
    r"lvs\s+result\s*:\s*(?:pass|match|correct)",
]


def text_files(root: Path, excluded: set[Path]):
    for path in sorted(root.rglob("*")):
        if (
            not path.is_file()
            or path.resolve() in excluded
            or path.name in TEMPLATE_INPUTS
            or path.stat().st_size > 20 * 1024 * 1024
        ):
            continue
        try:
            yield path, path.read_text(errors="replace")
        except OSError:
            continue


def write_inventory(
    root: Path,
    files: list[tuple[Path, str]],
    inventory: Path,
) -> None:
    lines = [
        "LABEL=SPADMIC_PVS_RESULT_EVIDENCE_INVENTORY",
        f"RUN_DIR={root}",
        f"SCANNED_TEXT_FILE_COUNT={len(files)}",
        "FILE_TABLE_BEGIN",
        "path|bytes|drc_total_lines|lvs_negative_patterns|lvs_positive_patterns",
    ]
    for path, text in files:
        negatives = sum(
            bool(re.search(pattern, text, re.I))
            for pattern in LVS_NEGATIVE_PATTERNS
        )
        positives = sum(
            bool(re.search(pattern, text, re.I))
            for pattern in LVS_POSITIVE_PATTERNS
        )
        lines.append(
            f"{path.relative_to(root)}|{path.stat().st_size}|"
            f"{len(DRC_TOTAL_PATTERN.findall(text))}|{negatives}|{positives}"
        )
    lines.append("FILE_TABLE_END")
    inventory.write_text("\n".join(lines) + "\n")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", choices=["drc", "lvs"], required=True)
    parser.add_argument("--run-dir", required=True, type=Path)
    parser.add_argument("--status", required=True, type=Path)
    parser.add_argument("--tool-rc", type=int, required=True)
    args = parser.parse_args()
    run_dir = args.run_dir.resolve()
    status_path = args.status.resolve()
    inventory = status_path.with_name("pvs_result_evidence_inventory.rpt")
    files = list(text_files(run_dir, {status_path, inventory.resolve()}))
    write_inventory(run_dir, files, inventory)
    status = "UNKNOWN"
    evidence = "NONE"
    detail_lines = [
        f"SCANNED_TEXT_FILE_COUNT={len(files)}",
        f"RESULT_EVIDENCE_INVENTORY={inventory}",
    ]

    if args.mode == "drc":
        matches = []
        for path, text in files:
            for value in DRC_TOTAL_PATTERN.findall(text):
                matches.append((path, int(value[0]), int(value[1])))
        detail_lines.append(f"DRC_TOTAL_MATCH_COUNT={len(matches)}")
        if matches:
            totals = {(primary, expanded) for _, primary, expanded in matches}
            if len(totals) != 1:
                status = "UNKNOWN"
                evidence = "CONFLICTING_REPORT_LEVEL_DRC_TOTALS_IN_RUN_DIR"
                detail_lines.append(
                    "DRC_TOTAL_VALUES="
                    + ",".join(
                        f"{primary}({expanded})"
                        for primary, expanded in sorted(totals)
                    )
                )
            else:
                primary, expanded = next(iter(totals))
                path = sorted(
                    candidate
                    for candidate, candidate_primary, candidate_expanded in matches
                    if (candidate_primary, candidate_expanded) == (primary, expanded)
                )[0]
                status = (
                    "PASS"
                    if args.tool_rc == 0 and primary == 0 and expanded == 0
                    else "FAIL"
                )
                evidence = f"{path}:Total DRC Results={primary}({expanded})"
                detail_lines.extend(
                    [
                        f"DRC_TOTAL_PRIMARY={primary}",
                        f"DRC_TOTAL_EXPANDED={expanded}",
                    ]
                )
        elif args.tool_rc != 0:
            status = "FAIL"
            evidence = f"PVS_RC={args.tool_rc}"
        else:
            evidence = "NO_REPORT_LEVEL_DRC_TOTAL_IN_RUN_DIR"
        key = "PVS_DRC_STATUS"
    else:
        negatives = []
        positives = []
        for path, text in files:
            for pattern in LVS_NEGATIVE_PATTERNS:
                if re.search(pattern, text, re.I):
                    negatives.append((path, pattern))
            for pattern in LVS_POSITIVE_PATTERNS:
                if re.search(pattern, text, re.I):
                    positives.append((path, pattern))
        detail_lines.extend(
            [
                f"LVS_NEGATIVE_MATCH_COUNT={len(negatives)}",
                f"LVS_POSITIVE_MATCH_COUNT={len(positives)}",
            ]
        )
        if args.tool_rc != 0 or negatives:
            status = "MISMATCH" if negatives else "FAIL"
            evidence = str(negatives[0][0]) if negatives else f"PVS_RC={args.tool_rc}"
        elif positives:
            status = "MATCH"
            evidence = str(positives[-1][0])
        else:
            evidence = "NO_EXPLICIT_REPORT_LEVEL_LVS_RESULT_IN_RUN_DIR"
        key = "PVS_LVS_STATUS"

    args.status.parent.mkdir(parents=True, exist_ok=True)
    args.status.write_text(
        "LABEL=SPADMIC_PVS_HANDOFF_RESULT\n"
        f"MODE={args.mode.upper()}\n"
        f"PVS_RC={args.tool_rc}\n"
        f"{key}={status}\n"
        f"EVIDENCE={evidence}\n"
        + "\n".join(detail_lines)
        + "\n"
        "SIGNOFF_READY=NO\n"
    )
    print(args.status.read_text(), end="")
    expected = "PASS" if args.mode == "drc" else "MATCH"
    if status != expected:
        raise SystemExit(8)


if __name__ == "__main__":
    main()
