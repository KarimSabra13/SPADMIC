#!/usr/bin/env python3
"""Classify attributable MPTDC base DRC for a bounded diagnostic context."""

from __future__ import annotations

import argparse
import hashlib
import sys
from pathlib import Path
from typing import Optional


ALLOWED_ANTENNA_RULES = ("R1M2P1", "R1M3P1", "R2M2P1", "R2M3P1")
CLASSIFICATION_CONTEXTS = {
    "free-placement": {
        "step": "MPTDC_FREE_TRIAL_BASE_DRC_CLASSIFICATION",
        "run_class": "DIAGNOSTIC_FREE_PLACEMENT_MANAGER_SCOPE",
        "scope": "BASE_DRC_PLUS_FULL_LVS",
    },
    "recovery-deferred-minarea": {
        "step": "MPTDC_RECOVERY_BASE_DRC_CLASSIFICATION",
        "run_class": "DIAGNOSTIC_NOT_SIGNOFF",
        "scope": "RECOVERY_BASE_DRC_CLASSIFICATION_ONLY",
    },
}


class ClassificationError(RuntimeError):
    pass


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def values(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for line in path.read_text(errors="replace").splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            result[key.strip()] = value.strip()
    return result


def require_file(path: Path, label: str) -> Path:
    resolved = path.expanduser().resolve()
    if not resolved.is_file() or resolved.stat().st_size == 0:
        raise ClassificationError(f"{label} missing or empty: {resolved}")
    return resolved


def parse_rules(path: Path) -> list[tuple[str, int, int]]:
    lines = path.read_text(errors="replace").splitlines()
    if not lines or lines[0] != "rule\tprimary\texpanded":
        raise ClassificationError("nonzero-rule inventory has an invalid header")
    rows: list[tuple[str, int, int]] = []
    for number, line in enumerate(lines[1:], start=2):
        if not line.strip():
            continue
        fields = line.split("\t")
        if len(fields) != 3:
            raise ClassificationError(f"invalid rule row {number}: {line}")
        name, primary_text, expanded_text = fields
        try:
            primary = int(primary_text)
            expanded = int(expanded_text)
        except ValueError as exc:
            raise ClassificationError(f"non-numeric rule row {number}: {line}") from exc
        if primary < 0 or expanded < 0 or (primary == 0 and expanded == 0):
            raise ClassificationError(f"invalid nonzero rule row {number}: {line}")
        rows.append((name, primary, expanded))
    return rows


def classify(status_report: Path, rule_report: Path) -> tuple[str, dict[str, str]]:
    status = values(status_report)
    required = {
        "STATUS",
        "PVS_DRC_STATUS",
        "PVS_DRC_VARIANT",
        "PVS_RC",
        "DRC_TOTAL_PRIMARY",
        "DRC_TOTAL_EXPANDED",
        "NONZERO_RULE_COUNT",
        "NONZERO_RULE_REPORT",
        "NONZERO_RULE_REPORT_SHA256",
        "LAYOUT_INPUT_SHA256",
    }
    missing = sorted(required - status.keys())
    if missing:
        raise ClassificationError(f"base DRC status missing keys: {','.join(missing)}")
    if status["PVS_DRC_VARIANT"] != "BASE" or status["PVS_RC"] != "0":
        raise ClassificationError("classification requires attributable BASE DRC with PVS_RC=0")
    if status["STATUS"] != status["PVS_DRC_STATUS"] or status["STATUS"] not in {"PASS", "FAIL"}:
        raise ClassificationError("base DRC status fields are inconsistent")
    if Path(status["NONZERO_RULE_REPORT"]).expanduser().resolve() != rule_report:
        raise ClassificationError("base DRC status references a different rule inventory")
    if status["NONZERO_RULE_REPORT_SHA256"].lower() != sha256(rule_report):
        raise ClassificationError("base DRC rule inventory hash mismatch")

    try:
        primary = int(status["DRC_TOTAL_PRIMARY"])
        expanded = int(status["DRC_TOTAL_EXPANDED"])
        row_count = int(status["NONZERO_RULE_COUNT"])
    except ValueError as exc:
        raise ClassificationError("base DRC totals are not integers") from exc
    rows = parse_rules(rule_report)
    if row_count != len(rows):
        raise ClassificationError(f"rule count mismatch: status={row_count} rows={len(rows)}")
    if sum(row[1] for row in rows) != primary or sum(row[2] for row in rows) != expanded:
        raise ClassificationError("rule totals do not match report-level totals")

    names = sorted(row[0] for row in rows)
    non_antenna = sorted(name for name in names if name not in ALLOWED_ANTENNA_RULES)
    if status["STATUS"] == "PASS":
        if primary != 0 or expanded != 0 or rows:
            raise ClassificationError("PASS base DRC contains nonzero evidence")
        result = "CLEAN"
    elif not rows:
        raise ClassificationError("FAIL base DRC has no attributable rule rows")
    elif non_antenna:
        result = "NON_ANTENNA_DRC"
    else:
        result = "ANTENNA_ONLY_MANAGER_EXCEPTION"

    details = {
        "DRC_TOTAL_PRIMARY": str(primary),
        "DRC_TOTAL_EXPANDED": str(expanded),
        "NONZERO_RULE_COUNT": str(len(rows)),
        "NONZERO_RULE_SET": ",".join(names) if names else "NONE",
        "NON_ANTENNA_RULE_COUNT": str(len(non_antenna)),
        "NON_ANTENNA_RULE_SET": ",".join(non_antenna) if non_antenna else "NONE",
        "LAYOUT_INPUT_SHA256": status["LAYOUT_INPUT_SHA256"],
        "RULE_REPORT_SHA256": sha256(rule_report),
    }
    return result, details


def write_reports(
    out: Path,
    scope_out: Path,
    context: str,
    classification: str,
    details: dict[str, str],
    error: Optional[str] = None,
) -> None:
    context_data = CLASSIFICATION_CONTEXTS[context]
    out.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        f"STEP={context_data['step']}",
        f"CLASSIFICATION_CONTEXT={context.upper().replace('-', '_')}",
        f"PVS_BASE_DRC_CLASS={classification}",
        f"ALLOWED_ANTENNA_RULE_SET={','.join(ALLOWED_ANTENNA_RULES)}",
    ]
    lines.extend(f"{key}={value}" for key, value in details.items())
    if error:
        lines.append(f"ERROR={error}")
    status = "PASS" if classification in {"CLEAN", "ANTENNA_ONLY_MANAGER_EXCEPTION", "NON_ANTENNA_DRC"} else "FAIL"
    decision = {
        "CLEAN": "PASS_CONTINUE_LVS",
        "ANTENNA_ONLY_MANAGER_EXCEPTION": "PASS_CONTINUE_LVS_WITH_MANAGER_EXCEPTION",
        "NON_ANTENNA_DRC": "FAIL_STOP_ONE_ATTRIBUTED_ROUTING_ECO_ELIGIBLE",
    }.get(classification, "FAIL_STOP")
    lines.extend(
        [
            f"CLASSIFICATION_STATUS={status}",
            "ANTENNA_REPAIR_ATTEMPTED=NO",
            "SIGNOFF_ELIGIBLE=NO",
            f"DECISION={decision}",
        ]
    )
    out.write_text("\n".join(lines) + "\n")

    if classification in {"CLEAN", "ANTENNA_ONLY_MANAGER_EXCEPTION"}:
        scope_out.parent.mkdir(parents=True, exist_ok=True)
        exception = "YES" if classification == "ANTENNA_ONLY_MANAGER_EXCEPTION" else "NOT_NEEDED"
        scope_out.write_text(
            f"PVS_RUN_CLASS={context_data['run_class']}\n"
            f"DIAGNOSTIC_SCOPE={context_data['scope']}\n"
            f"CLASSIFICATION_CONTEXT={context.upper().replace('-', '_')}\n"
            f"BASE_DRC_CLASS={classification}\n"
            "DENSITY_DRC_STATUS=NOT_RUN_BY_SCOPE\n"
            "ANTENNA_REPAIR_ATTEMPTED=NO\n"
            f"MANAGER_ANTENNA_EXCEPTION={exception}\n"
            f"ALLOWED_ANTENNA_RULE_SET={','.join(ALLOWED_ANTENNA_RULES)}\n"
            f"BASE_DRC_LAYOUT_SHA256={details['LAYOUT_INPUT_SHA256']}\n"
            f"BASE_DRC_RULE_REPORT_SHA256={details['RULE_REPORT_SHA256']}\n"
            "SIGNOFF_ELIGIBLE=NO\n"
        )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--status-report", required=True, type=Path)
    parser.add_argument("--rule-report", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--scope-out", required=True, type=Path)
    parser.add_argument(
        "--context",
        choices=sorted(CLASSIFICATION_CONTEXTS),
        default="free-placement",
    )
    args = parser.parse_args()

    out = args.out.expanduser().resolve()
    scope_out = args.scope_out.expanduser().resolve()
    try:
        status_report = require_file(args.status_report, "base DRC status")
        rule_report = require_file(args.rule_report, "base DRC rule inventory")
        classification, details = classify(status_report, rule_report)
        write_reports(out, scope_out, args.context, classification, details)
        print(out.read_text(), end="")
        return 0 if classification in {"CLEAN", "ANTENNA_ONLY_MANAGER_EXCEPTION"} else 10
    except ClassificationError as exc:
        write_reports(out, scope_out, args.context, "INVALID_EVIDENCE", {}, str(exc))
        print(out.read_text(), end="")
        return 8


if __name__ == "__main__":
    sys.exit(main())
