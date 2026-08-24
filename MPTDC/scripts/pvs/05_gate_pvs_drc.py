#!/usr/bin/env python3
"""Fail closed unless one attributable PVS DRC variant has zero results."""

from __future__ import annotations

import argparse
import hashlib
import re
import sys
from pathlib import Path


RULECHECK_RE = re.compile(
    r"^RULECHECK\s+(.+?)\s+\.*\s+Total Result\s+(\d+)\s+\(\s*(\d+)\s*\)\s*$"
)
TOTAL_RE = re.compile(r"Total DRC Results\s*:\s*(\d+)\s*\(\s*(\d+)\s*\)", re.I)
RULECHECK_TOTAL_RE = re.compile(r"^Total DRC RuleChecks\s*:\s*(\d+)\s*$", re.I)


class GateError(RuntimeError):
    pass


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def require_file(path: Path, label: str) -> Path:
    resolved = path.expanduser().resolve()
    if not resolved.is_file() or resolved.stat().st_size == 0:
        raise GateError(f"{label} missing or empty: {resolved}")
    return resolved


def manifest_values(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for line in path.read_text(errors="replace").splitlines():
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip()
    return values


def verify_layout_manifest(manifest: Path, layout: Path) -> str:
    values = manifest_values(manifest)
    if values.get("STRICT_ATTRIBUTION") != "1":
        raise GateError("PVS preparation did not enable strict attribution")
    expected_path = values.get("MERGED_GDS_PATH")
    expected_hash = values.get("MERGED_GDS_SHA256")
    if not expected_path or not expected_hash:
        raise GateError("hash manifest is missing MERGED_GDS_PATH or MERGED_GDS_SHA256")
    if Path(expected_path).expanduser().resolve() != layout:
        raise GateError("DRC layout input is not the immutable merged GDS")
    actual = sha256(layout)
    if actual != expected_hash.lower():
        raise GateError("DRC layout SHA256 differs from immutable manifest")
    return actual


def discover_summary(run_dir: Path) -> Path:
    summaries = sorted(run_dir.glob("*_drc.sum"))
    if len(summaries) == 1:
        return require_file(summaries[0], "DRC summary")
    for name in (".drcSummaryReport", "drcSummaryReport.txt"):
        candidate = run_dir / name
        if candidate.is_file() and candidate.stat().st_size:
            return candidate.resolve()
    raise GateError(f"expected one *_drc.sum or DRC summary report under {run_dir}")


def parse_summary(path: Path) -> tuple[int, int, int]:
    rules: list[tuple[str, int, int]] = []
    totals: set[tuple[int, int]] = set()
    declared: int | None = None
    for line in path.read_text(errors="replace").splitlines():
        rule = RULECHECK_RE.match(line)
        if rule:
            rules.append((rule.group(1).strip(), int(rule.group(2)), int(rule.group(3))))
        total = TOTAL_RE.search(line)
        if total:
            totals.add((int(total.group(1)), int(total.group(2))))
        count = RULECHECK_TOTAL_RE.match(line)
        if count:
            declared = int(count.group(1))
    if len(totals) != 1:
        raise GateError(f"missing or conflicting report-level DRC totals in {path}: {sorted(totals)}")
    primary, expanded = next(iter(totals))
    if rules:
        rule_totals = (sum(row[1] for row in rules), sum(row[2] for row in rules))
        if rule_totals != (primary, expanded):
            raise GateError(f"rule totals {rule_totals} do not match report total {(primary, expanded)}")
        if declared is not None and declared != len(rules):
            raise GateError(f"declared rulecheck count {declared} does not match parsed {len(rules)}")
    return primary, expanded, len([row for row in rules if row[1] or row[2]])


def one_path(text: str, directive: str, label: str) -> Path:
    values = re.findall(rf'(?im)^\s*{re.escape(directive)}\s+"([^"]+)"\s*;', text)
    if len(values) != 1:
        raise GateError(f"expected one executable {directive}, found {values}")
    return require_file(Path(values[0]), label)


def option_paths(text: str, option: str) -> list[Path]:
    pattern = re.compile(
        rf'{re.escape(option)}\s+(?:"([^"]+)"|\'([^\']+)\'|(\S+))'
    )
    values = [next(value for value in match if value) for match in pattern.findall(text)]
    return [Path(value).expanduser().resolve() for value in values]


def verify_controls(run_dir: Path, variant: str, expected_top: str) -> tuple[Path, Path, Path]:
    run_control = require_file(run_dir / "run.pvs", "run.pvs")
    drc_control = require_file(run_dir / "pvsdrcctl", "pvsdrcctl")
    run_text = run_control.read_text(errors="replace")
    control_text = drc_control.read_text(errors="replace")

    tops = re.findall(r"-top_cell\s+[\"{]?([A-Za-z_][A-Za-z0-9_$]*)", run_text)
    if tops != [expected_top]:
        raise GateError(f"layout top must occur once as {expected_top}; found {tops}")

    controls = option_paths(run_text, "-control")
    if controls != [drc_control]:
        raise GateError(f"run.pvs does not reference the run-local DRC control exactly once: {controls}")

    defines = len(re.findall(r"(?m)^\s*#DEFINE\s+DENSITY\s*$", control_text))
    undefines = len(re.findall(r"(?m)^\s*#UNDEFINE\s+DENSITY\s*$", control_text))
    expected = (0, 1) if variant == "base" else (1, 0)
    if (defines, undefines) != expected:
        raise GateError(
            f"{variant} variant has invalid DENSITY controls: define={defines} undefine={undefines}"
        )

    layout = one_path(control_text, "layout_path", "DRC layout input")
    return run_control, drc_control, layout


def write_failure(path: Path, error: Exception) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        "LABEL=MPTDC_PVS_DRC_GATE\n"
        "STATUS=FAIL\n"
        "PVS_DRC_STATUS=NOT_PROVEN\n"
        f"ERROR={error}\n"
        "FINAL_PHYSICAL_SIGNOFF_READY=NO\n"
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", required=True, type=Path)
    parser.add_argument("--tool-rc", required=True, type=int)
    parser.add_argument("--variant", required=True, choices=["base", "density"])
    parser.add_argument("--expected-top", required=True)
    parser.add_argument("--hash-manifest", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()

    out = args.out.expanduser().resolve()
    try:
        run_dir = args.run_dir.expanduser().resolve()
        if not run_dir.is_dir():
            raise GateError(f"PVS DRC run directory missing: {run_dir}")
        if args.tool_rc != 0:
            raise GateError(f"PVS DRC tool return code is nonzero: {args.tool_rc}")
        summary = discover_summary(run_dir)
        primary, expanded, nonzero_rules = parse_summary(summary)
        run_control, drc_control, layout = verify_controls(run_dir, args.variant, args.expected_top)
        hash_manifest = require_file(args.hash_manifest, "PVS input hash manifest")
        layout_hash = verify_layout_manifest(hash_manifest, layout)
        status = "PASS" if (primary, expanded) == (0, 0) else "FAIL"
        report = "\n".join(
            [
                "LABEL=MPTDC_PVS_DRC_GATE",
                f"STATUS={status}",
                f"PVS_DRC_STATUS={status}",
                f"PVS_DRC_VARIANT={args.variant.upper()}",
                f"PVS_RC={args.tool_rc}",
                f"LAYOUT_TOP={args.expected_top}",
                f"DRC_TOTAL_PRIMARY={primary}",
                f"DRC_TOTAL_EXPANDED={expanded}",
                f"NONZERO_RULE_COUNT={nonzero_rules}",
                f"LAYOUT_INPUT={layout}",
                f"LAYOUT_INPUT_SHA256={layout_hash}",
                f"HASH_MANIFEST={hash_manifest}",
                f"HASH_MANIFEST_SHA256={sha256(hash_manifest)}",
                f"SUMMARY={summary}",
                f"SUMMARY_SHA256={sha256(summary)}",
                f"RUN_CONTROL={run_control}",
                f"RUN_CONTROL_SHA256={sha256(run_control)}",
                f"DRC_CONTROL={drc_control}",
                f"DRC_CONTROL_SHA256={sha256(drc_control)}",
                "FINAL_PHYSICAL_SIGNOFF_READY=NO",
            ]
        ) + "\n"
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(report)
        print(report, end="")
        return 0 if status == "PASS" else 9
    except GateError as exc:
        write_failure(out, exc)
        print(out.read_text(), end="")
        return 8


if __name__ == "__main__":
    sys.exit(main())
