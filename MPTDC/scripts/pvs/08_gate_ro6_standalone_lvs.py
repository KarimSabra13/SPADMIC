#!/usr/bin/env python3
"""Gate a standalone RO_tune6 PVS LVS run on an explicit comparison MATCH."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


def count_named(root: Path, name: str) -> int:
    return sum(1 for path in root.rglob(name) if path.is_file())


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", required=True, type=Path)
    parser.add_argument("--pvs-rc", required=True, type=int)
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()

    cls_files = [path for path in args.run_dir.rglob("*.cls") if path.is_file()]
    run_result = "MISSING"
    blackboxed = "MISSING"
    if len(cls_files) == 1:
        text = cls_files[0].read_text(encoding="utf-8", errors="replace")
        match = re.search(r"Run Result\s*:\s*([A-Za-z_]+)", text)
        if match:
            run_result = match.group(1).upper()
        blackbox_match = re.search(
            r"Cells that have been blackboxed\s*\|\s*([0-9]+)", text
        )
        blackboxed = blackbox_match.group(1) if blackbox_match else "MISSING"

    matched_count = count_named(args.run_dir, "matched")
    mismatched_count = count_named(args.run_dir, "mismatched")
    status = (
        "PASS"
        if args.pvs_rc == 0
        and len(cls_files) == 1
        and run_result == "MATCH"
        and blackboxed == "0"
        and matched_count >= 1
        and mismatched_count == 0
        else "FAIL"
    )
    lines = [
        "STEP=PVS_RO6_STANDALONE_LVS",
        f"STATUS={status}",
        f"PVS_LVS_STATUS={'MATCH' if status == 'PASS' else 'NOT_PROVEN'}",
        f"PVS_RC={args.pvs_rc}",
        f"CLS_FILE_COUNT={len(cls_files)}",
        f"CLS_FILE={cls_files[0] if len(cls_files) == 1 else 'MISSING'}",
        f"CLS_RUN_RESULT={run_result}",
        f"BLACKBOXED_CELL_COUNT={blackboxed}",
        f"MATCHED_MARKER_COUNT={matched_count}",
        f"MISMATCHED_MARKER_COUNT={mismatched_count}",
        "HCELL_STATUS=NOT_USED",
        "BLACKBOX_STATUS=NOT_USED",
        "RO6_STANDALONE_LVS_PROVEN=" + ("YES" if status == "PASS" else "NO"),
        "SIGNOFF_ELIGIBLE=NO",
    ]
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines))
    return 0 if status == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
