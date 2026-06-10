#!/usr/bin/env python3
"""Extract authoritative final-typical Genus closure metrics from run reports."""

from __future__ import annotations

import argparse
import csv
import re
from collections import Counter
from pathlib import Path


NUMBER_RE = re.compile(r"-?\d+(?:\.\d+)?")


def read_text(path: Path) -> str:
    try:
        return path.read_text(errors="replace")
    except FileNotFoundError:
        return ""


def fmt(value: float | None) -> str:
    if value is None:
        return "NA"
    return f"{value:.1f}"


def parse_qor(path: Path) -> dict[str, object]:
    rows: list[dict[str, object]] = []
    total_tns: float | None = None
    total_paths: int | None = None
    for raw in read_text(path).splitlines():
        line = raw.strip()
        if not line:
            continue
        tokens = line.split()
        if not tokens:
            continue
        if tokens[0] == "Total" and len(tokens) >= 3:
            nums = NUMBER_RE.findall(line)
            if len(nums) >= 2:
                total_tns = float(nums[-2])
                total_paths = int(float(nums[-1]))
            continue
        if tokens[0] == "tc_view":
            tokens = tokens[1:]
        if len(tokens) < 4:
            continue
        group = tokens[0]
        if tokens[1:3] == ["No", "paths"] and len(tokens) >= 5:
            rows.append(
                {
                    "group": group,
                    "wns": None,
                    "tns": float(tokens[3]),
                    "paths": int(float(tokens[4])),
                }
            )
            continue
        try:
            rows.append(
                {
                    "group": group,
                    "wns": float(tokens[1]),
                    "tns": float(tokens[2]),
                    "paths": int(float(tokens[3])),
                }
            )
        except ValueError:
            continue

    numeric_wns = [row["wns"] for row in rows if row["wns"] is not None]
    setup_wns = min(numeric_wns) if numeric_wns else None
    if total_tns is None:
        total_tns = sum(float(row["tns"]) for row in rows if float(row["tns"]) < 0)
    if total_paths is None:
        total_paths = sum(int(row["paths"]) for row in rows if float(row["tns"]) < 0)
    return {
        "status": "PASS" if rows and setup_wns is not None else "FAIL",
        "setup_wns": setup_wns,
        "setup_tns": total_tns,
        "setup_paths": total_paths,
        "groups": rows,
    }


def parse_classification(path: Path) -> dict[str, object]:
    if not path.exists():
        return {
            "status": "FAIL",
            "rows": [],
            "unknown": "NA",
            "worst_family": "NA",
        }
    rows: list[dict[str, str]] = []
    with path.open(newline="") as fh:
        rows = list(csv.DictReader(fh))
    unknown = sum(1 for row in rows if row.get("classification") == "UNKNOWN_REVIEW_REQUIRED")

    # Use timing_violations.rpt rows for the family diagnosis. Other focused
    # reports intentionally duplicate paths and would overcount TNS.
    violating_rows = [
        row
        for row in rows
        if row.get("classification") != "PD_INTENTIONAL_VERNIER"
        and Path(row.get("report", "")).name == "timing_violations.rpt"
    ]
    negative_rows = []
    for row in violating_rows:
        try:
            slack = float(row.get("slack_ps", "0"))
        except ValueError:
            continue
        if slack < 0:
            negative_rows.append((slack, row))
    worst_family = "NA"
    if negative_rows:
        worst_family = min(negative_rows, key=lambda item: item[0])[1].get("family", "NA")
    family_counts = Counter(row.get("family", "OTHER") for _, row in negative_rows)
    return {
        "status": "PASS" if rows else "FAIL",
        "rows": rows,
        "unknown": unknown,
        "worst_family": worst_family,
        "negative_count": len(negative_rows),
        "family_counts": family_counts,
    }


def parse_report_helpers(path: Path) -> tuple[str, str]:
    text = read_text(path)
    if not text:
        return "NA", "MISSING"
    count = "NA"
    status = "REVIEW_REQUIRED"
    for line in text.splitlines():
        if line.startswith("REPORT_HELPER_FAILURE_COUNT="):
            count = line.split("=", 1)[1].strip()
        elif line.startswith("REPORT_HELPERS_STATUS="):
            status = line.split("=", 1)[1].strip()
    return count, status


def write_env(path: Path, values: dict[str, str]) -> None:
    with path.open("w") as fh:
        for key in sorted(values):
            fh.write(f"{key}={values[key]}\n")


def write_report(path: Path, values: dict[str, str], qor: dict[str, object], cls: dict[str, object]) -> None:
    lines = [
        "# MPTDC Genus Summary Parser Check",
        "",
        f"TIMING_SUMMARY_PARSE_STATUS={values['TIMING_SUMMARY_PARSE_STATUS']}",
        f"TIMING_CLASSIFICATION_PARSE_STATUS={values['TIMING_CLASSIFICATION_PARSE_STATUS']}",
        f"SUMMARY_RAW_AGREEMENT_STATUS={values['SUMMARY_RAW_AGREEMENT_STATUS']}",
        "",
        "## Raw Timing Summary Source",
        "",
        f"- Setup WNS ps: `{values['SETUP_WNS_PS']}`",
        f"- Setup TNS ps: `{values['SETUP_TNS_PS']}`",
        f"- Setup violating paths: `{values['SETUP_VIOLATING_PATHS']}`",
        f"- Real timed WNS ps: `{values['REAL_TIMED_WNS_PS']}`",
        f"- Real timed TNS ps: `{values['REAL_TIMED_TNS_PS']}`",
        f"- Worst real path family: `{values['WORST_REAL_PATH_FAMILY']}`",
        f"- UNKNOWN_REVIEW_REQUIRED count: `{values['UNKNOWN_REVIEW_REQUIRED_COUNT']}`",
        "",
        "## Cost Groups",
        "",
        "| Group | WNS ps | TNS ps | Violating Paths |",
        "|---|---:|---:|---:|",
    ]
    for row in qor.get("groups", []):
        lines.append(
            "| `{group}` | {wns} | {tns:.1f} | {paths} |".format(
                group=row["group"],
                wns=fmt(row["wns"]),
                tns=row["tns"],
                paths=row["paths"],
            )
        )
    lines.extend(["", "## Negative Path Families From timing_violations.rpt", ""])
    family_counts = cls.get("family_counts", Counter())
    if family_counts:
        for family, count in family_counts.most_common():
            lines.append(f"- `{family}`: {count}")
    else:
        lines.append("- None")
    path.write_text("\n".join(lines) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", type=Path, required=True)
    parser.add_argument("--out-env", type=Path, required=True)
    parser.add_argument("--out-report", type=Path, required=True)
    args = parser.parse_args()

    qor = parse_qor(args.run_dir / "timing_summary.rpt")
    cls = parse_classification(args.run_dir / "timing_path_classification.csv")
    helper_count, helper_status = parse_report_helpers(args.run_dir / "report_helpers_status.rpt")

    if qor["status"] == "PASS":
        setup_wns = qor.get("setup_wns")
        setup_tns = qor.get("setup_tns")
        setup_paths = qor.get("setup_paths")
    else:
        setup_wns = None
        setup_tns = None
        setup_paths = None
    agreement = "PASS"
    if qor["status"] != "PASS" or cls["status"] != "PASS":
        agreement = "FAIL"
    values = {
        "TIMING_SUMMARY_PARSE_STATUS": str(qor["status"]),
        "TIMING_CLASSIFICATION_PARSE_STATUS": str(cls["status"]),
        "SUMMARY_RAW_AGREEMENT_STATUS": agreement,
        "SETUP_WNS_PS": fmt(setup_wns if isinstance(setup_wns, float) else None),
        "SETUP_TNS_PS": fmt(setup_tns if isinstance(setup_tns, float) else None),
        "SETUP_VIOLATING_PATHS": str(setup_paths if setup_paths is not None else "NA"),
        "HOLD_WNS_PS": "NA",
        "HOLD_TNS_PS": "NA",
        "REAL_TIMED_WNS_PS": fmt(setup_wns if isinstance(setup_wns, float) else None),
        "REAL_TIMED_TNS_PS": fmt(setup_tns if isinstance(setup_tns, float) else None),
        "REAL_TIMED_VIOLATING_PATHS": str(setup_paths if setup_paths is not None else "NA"),
        "UNKNOWN_REVIEW_REQUIRED_COUNT": str(cls.get("unknown", "NA")),
        "WORST_REAL_PATH_FAMILY": str(cls.get("worst_family", "NA")),
        "REPORT_HELPER_FAILURE_COUNT": helper_count,
        "REPORT_HELPERS_STATUS": helper_status,
    }
    args.out_env.parent.mkdir(parents=True, exist_ok=True)
    args.out_report.parent.mkdir(parents=True, exist_ok=True)
    write_env(args.out_env, values)
    write_report(args.out_report, values, qor, cls)
    return 0 if agreement == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
