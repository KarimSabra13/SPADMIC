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


def text_files(root: Path):
    for path in root.rglob("*"):
        if (
            not path.is_file()
            or path.name in TEMPLATE_INPUTS
            or path.stat().st_size > 20 * 1024 * 1024
        ):
            continue
        try:
            yield path, path.read_text(errors="replace")
        except OSError:
            continue


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", choices=["drc", "lvs"], required=True)
    parser.add_argument("--run-dir", required=True, type=Path)
    parser.add_argument("--status", required=True, type=Path)
    parser.add_argument("--tool-rc", type=int, required=True)
    args = parser.parse_args()
    files = list(text_files(args.run_dir.resolve()))
    status = "UNKNOWN"
    evidence = "NONE"

    if args.mode == "drc":
        matches = []
        for path, text in files:
            for value in re.findall(r"Total DRC Results\s*:\s*(\d+)\s*\((\d+)\)", text, re.I):
                matches.append((path, int(value[0]), int(value[1])))
        if matches:
            path, primary, expanded = matches[-1]
            status = "PASS" if args.tool_rc == 0 and primary == 0 and expanded == 0 else "FAIL"
            evidence = f"{path}:Total DRC Results={primary}({expanded})"
        elif args.tool_rc != 0:
            status = "FAIL"
            evidence = f"PVS_RC={args.tool_rc}"
        key = "PVS_DRC_STATUS"
    else:
        negative_patterns = [
            r"circuits?\s+(?:do\s+)?not\s+match",
            r"netlists?\s+(?:do\s+)?not\s+match",
            r"run\s+result\s*:\s*(?:fail|mismatch|incorrect)",
            r"lvs\s+result\s*:\s*(?:fail|mismatch|incorrect)",
        ]
        positive_patterns = [
            r"circuits?\s+match",
            r"netlists?\s+match",
            r"run\s+result\s*:\s*(?:pass|match|correct)",
            r"lvs\s+result\s*:\s*(?:pass|match|correct)",
        ]
        negatives = []
        positives = []
        for path, text in files:
            for pattern in negative_patterns:
                if re.search(pattern, text, re.I):
                    negatives.append((path, pattern))
            for pattern in positive_patterns:
                if re.search(pattern, text, re.I):
                    positives.append((path, pattern))
        if args.tool_rc != 0 or negatives:
            status = "MISMATCH" if negatives else "FAIL"
            evidence = str(negatives[0][0]) if negatives else f"PVS_RC={args.tool_rc}"
        elif positives:
            status = "MATCH"
            evidence = str(positives[-1][0])
        key = "PVS_LVS_STATUS"

    args.status.parent.mkdir(parents=True, exist_ok=True)
    args.status.write_text(
        "LABEL=SPADMIC_PVS_HANDOFF_RESULT\n"
        f"MODE={args.mode.upper()}\n"
        f"PVS_RC={args.tool_rc}\n"
        f"{key}={status}\n"
        f"EVIDENCE={evidence}\n"
        "SIGNOFF_READY=NO\n"
    )
    print(args.status.read_text(), end="")
    expected = "PASS" if args.mode == "drc" else "MATCH"
    if status != expected:
        raise SystemExit(8)


if __name__ == "__main__":
    main()
