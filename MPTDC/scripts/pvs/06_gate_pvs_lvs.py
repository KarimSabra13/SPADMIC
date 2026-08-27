#!/usr/bin/env python3
"""Fail closed unless PVS explicitly matches one immutable GDS/source tuple."""

from __future__ import annotations

import argparse
import csv
import hashlib
import re
import sys
from dataclasses import dataclass
from pathlib import Path


NEGATIVE_PATTERNS = [
    re.compile(r"circuits?\s+(?:do\s+)?not\s+match", re.I),
    re.compile(r"net[- ]?lists?\s+(?:do\s+)?not\s+match", re.I),
    re.compile(r"(?:run|lvs)\s+result\s*:\s*(?:fail|mismatch|incorrect)", re.I),
]
POSITIVE_PATTERNS = [
    re.compile(r"circuits?\s+(?:are\s+)?(?:equivalent|match)", re.I),
    re.compile(r"net[- ]?lists?\s+match", re.I),
    re.compile(r"(?:run|lvs)\s+result\s*:\s*(?:pass|match|correct)", re.I),
]
EXCLUDED_NAMES = {
    "run.pvs",
    "pvslvsctl",
    "pvsdrcctl",
    ".config.rul",
    ".technology.rul",
    "cell_tree.txt",
}


class GateError(RuntimeError):
    pass


class MismatchError(GateError):
    pass


@dataclass(frozen=True)
class Evidence:
    path: Path
    negative: int
    positive: int
    report_level: bool


@dataclass(frozen=True)
class PathDirective:
    path: Path
    arguments: tuple[str, ...]


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


def require_existing_file(path: Path, label: str) -> Path:
    resolved = path.expanduser().resolve()
    if not resolved.is_file():
        raise GateError(f"{label} missing: {resolved}")
    return resolved


def manifest_values(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for line in path.read_text(errors="replace").splitlines():
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip()
    return values


def verify_manifest_item(
    values: dict[str, str], label: str, path: Path
) -> str:
    manifest_path = values.get(f"{label}_PATH")
    manifest_hash = values.get(f"{label}_SHA256")
    if not manifest_path or not manifest_hash:
        raise GateError(f"hash manifest is missing {label}_PATH or {label}_SHA256")
    if Path(manifest_path).expanduser().resolve() != path:
        raise GateError(f"{label} path differs from immutable manifest")
    actual = sha256(path)
    if actual != manifest_hash.lower():
        raise GateError(f"{label} SHA256 differs from immutable manifest")
    return actual


def path_directives(text: str, directive: str) -> list[PathDirective]:
    candidate_pattern = re.compile(
        rf"(?im)^\s*{re.escape(directive)}\b[^\r\n]*$"
    )
    directive_pattern = re.compile(
        rf'^\s*{re.escape(directive)}\s+"([^"\r\n]+)"([^;\r\n]*)\s*;\s*$'
    )
    directives: list[PathDirective] = []
    for candidate in candidate_pattern.findall(text):
        match = directive_pattern.fullmatch(candidate)
        if match is None:
            raise GateError(f"malformed {directive} directive: {candidate.strip()}")
        directives.append(
            PathDirective(
                Path(match.group(1)).expanduser().resolve(),
                tuple(match.group(2).split()),
            )
        )
    return directives


def option_paths(text: str, option: str) -> list[Path]:
    pattern = re.compile(
        rf'{re.escape(option)}\s+(?:"([^"]+)"|\'([^\']+)\'|(\S+))'
    )
    values = [next(value for value in match if value) for match in pattern.findall(text)]
    return [Path(value).expanduser().resolve() for value in values]


def verify_controls(
    run_dir: Path,
    gds: Path,
    source: Path,
    cdl: Path,
    hcell: Path,
    layout_top: str,
    source_top: str,
) -> tuple[Path, Path]:
    run_control = require_file(run_dir / "run.pvs", "run.pvs")
    lvs_control = require_file(run_dir / "pvslvsctl", "pvslvsctl")
    run_text = run_control.read_text(errors="replace")
    lvs_text = lvs_control.read_text(errors="replace")

    layout_directives = path_directives(lvs_text, "layout_path")
    if layout_directives != [PathDirective(gds, ())]:
        raise GateError("pvslvsctl layout_path is not exactly the immutable merged GDS")

    schematic_directives = path_directives(lvs_text, "schematic_path")
    verilog_directives = [
        item
        for item in schematic_directives
        if item.arguments and item.arguments[0].lower() == "verilog"
    ]
    cdl_directives = [
        item
        for item in schematic_directives
        if item.arguments and item.arguments[0].lower() in {"cdl", "spice"}
    ]
    if len(schematic_directives) != 2:
        raise GateError(
            "pvslvsctl must contain exactly one Verilog and one CDL schematic_path"
        )
    if len(verilog_directives) != 1 or verilog_directives[0].path != source:
        raise GateError("pvslvsctl Verilog schematic_path is not exactly the immutable source")
    if verilog_directives[0].arguments[1:] not in {(), ("-keep_backslash",)}:
        raise GateError(
            "pvslvsctl Verilog schematic_path has unsupported options: "
            f"{verilog_directives[0].arguments[1:]}"
        )
    if len(cdl_directives) != 1 or cdl_directives[0].path != cdl:
        raise GateError(
            "pvslvsctl must reference only the expected D_CELLS CDL: "
            f"{[item.path for item in cdl_directives]}"
        )
    if cdl_directives[0].arguments[1:]:
        raise GateError(
            "pvslvsctl D_CELLS schematic_path has unsupported options: "
            f"{cdl_directives[0].arguments[1:]}"
        )

    layout_tops = re.findall(r"-top_cell\s+[\"{]?([A-Za-z_][A-Za-z0-9_$]*)", run_text)
    source_tops = re.findall(r"-source_top_cell\s+[\"{]?([A-Za-z_][A-Za-z0-9_$]*)", run_text)
    if layout_tops != [layout_top]:
        raise GateError(f"layout top must occur once as {layout_top}; found {layout_tops}")
    if source_tops != [source_top]:
        raise GateError(f"source top must occur once as {source_top}; found {source_tops}")

    controls = option_paths(run_text, "-control")
    if controls != [lvs_control]:
        raise GateError(f"run.pvs does not reference the run-local LVS control exactly once: {controls}")
    control_files = [
        run_control,
        lvs_control,
        require_existing_file(run_dir / ".config.rul", ".config.rul"),
        require_file(run_dir / ".technology.rul", ".technology.rul"),
    ]
    hcell_references = sum(
        path.read_text(errors="replace").count(str(hcell)) for path in control_files
    )
    if hcell_references < 1:
        raise GateError("PVS controls do not reference the immutable HCell file")
    return run_control, lvs_control


def is_report_level(path: Path) -> bool:
    name = path.name.lower()
    return (
        "lvs" in name
        or name.endswith((".sum", ".cls", ".rpt", ".report"))
        or name in {"pvs.stdout.log", ".lvsresults"}
    )


def collect_evidence(run_dir: Path) -> tuple[list[Evidence], list[Path], list[Path]]:
    rows: list[Evidence] = []
    negatives: list[Path] = []
    positives: list[Path] = []
    for path in sorted(run_dir.rglob("*")):
        if (
            not path.is_file()
            or path.name in EXCLUDED_NAMES
            or path.stat().st_size == 0
            or path.stat().st_size > 20 * 1024 * 1024
            or path.suffix.lower() in {".gds", ".oas", ".rdb", ".ecdb", ".gz"}
        ):
            continue
        try:
            text = path.read_text(errors="replace")
        except OSError:
            continue
        negative = sum(1 for pattern in NEGATIVE_PATTERNS if pattern.search(text))
        positive = sum(1 for pattern in POSITIVE_PATTERNS if pattern.search(text))
        report_level = is_report_level(path)
        rows.append(Evidence(path, negative, positive, report_level))
        if negative:
            negatives.append(path)
        if positive and report_level:
            positives.append(path)
    return rows, negatives, positives


def write_inventory(path: Path, run_dir: Path, rows: list[Evidence]) -> None:
    with path.open("w", newline="") as handle:
        writer = csv.writer(handle, delimiter="\t", lineterminator="\n")
        writer.writerow(["path", "negative_patterns", "positive_patterns", "report_level"])
        for row in rows:
            writer.writerow(
                [
                    row.path.relative_to(run_dir),
                    row.negative,
                    row.positive,
                    "YES" if row.report_level else "NO",
                ]
            )


def write_failure(path: Path, error: Exception, tool_rc: int) -> None:
    lvs_status = "MISMATCH" if isinstance(error, MismatchError) else "NOT_PROVEN"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        "LABEL=MPTDC_PVS_LVS_GATE\n"
        "STATUS=FAIL\n"
        f"PVS_LVS_STATUS={lvs_status}\n"
        f"PVS_RC={tool_rc}\n"
        f"ERROR={error}\n"
        "FINAL_PHYSICAL_SIGNOFF_READY=NO\n"
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", required=True, type=Path)
    parser.add_argument("--tool-rc", required=True, type=int)
    parser.add_argument("--gds", required=True, type=Path)
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--cdl", required=True, type=Path)
    parser.add_argument("--hcell", required=True, type=Path)
    parser.add_argument("--hash-manifest", required=True, type=Path)
    parser.add_argument("--layout-top", required=True)
    parser.add_argument("--source-top", required=True)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--inventory", required=True, type=Path)
    args = parser.parse_args()

    out = args.out.expanduser().resolve()
    try:
        run_dir = args.run_dir.expanduser().resolve()
        if not run_dir.is_dir():
            raise GateError(f"PVS LVS run directory missing: {run_dir}")
        if args.tool_rc != 0:
            raise GateError(f"PVS LVS tool return code is nonzero: {args.tool_rc}")

        gds = require_file(args.gds, "merged GDS")
        source = require_file(args.source, "filtered LVS source")
        cdl = require_file(args.cdl, "D_CELLS CDL")
        hcell = require_file(args.hcell, "HCell file")
        hash_manifest = require_file(args.hash_manifest, "PVS input hash manifest")
        values = manifest_values(hash_manifest)
        if values.get("STRICT_ATTRIBUTION") != "1":
            raise GateError("PVS preparation did not enable strict attribution")
        gds_hash = verify_manifest_item(values, "MERGED_GDS", gds)
        source_hash = verify_manifest_item(values, "LVS_SOURCE_FILTERED", source)
        cdl_hash = verify_manifest_item(values, "DCELL_CDL", cdl)
        hcell_hash = verify_manifest_item(values, "LVS_HCELL", hcell)
        run_control, lvs_control = verify_controls(
            run_dir, gds, source, cdl, hcell, args.layout_top, args.source_top
        )

        rows, negatives, positives = collect_evidence(run_dir)
        inventory = args.inventory.expanduser().resolve()
        inventory.parent.mkdir(parents=True, exist_ok=True)
        write_inventory(inventory, run_dir, rows)
        if negatives:
            raise MismatchError(
                f"explicit LVS mismatch evidence found in {negatives[0]}"
            )
        if not positives:
            raise GateError("no explicit report-level LVS MATCH evidence found")

        report = "\n".join(
            [
                "LABEL=MPTDC_PVS_LVS_GATE",
                "STATUS=PASS",
                "PVS_LVS_STATUS=MATCH",
                f"PVS_RC={args.tool_rc}",
                f"LAYOUT_TOP={args.layout_top}",
                f"SOURCE_TOP={args.source_top}",
                f"GDS={gds}",
                f"GDS_SHA256={gds_hash}",
                f"SOURCE={source}",
                f"SOURCE_SHA256={source_hash}",
                f"CDL={cdl}",
                f"CDL_SHA256={cdl_hash}",
                f"HCELL={hcell}",
                f"HCELL_SHA256={hcell_hash}",
                f"HASH_MANIFEST={hash_manifest}",
                f"HASH_MANIFEST_SHA256={sha256(hash_manifest)}",
                f"RUN_CONTROL={run_control}",
                f"RUN_CONTROL_SHA256={sha256(run_control)}",
                f"LVS_CONTROL={lvs_control}",
                f"LVS_CONTROL_SHA256={sha256(lvs_control)}",
                f"MATCH_EVIDENCE={positives[-1]}",
                f"EVIDENCE_INVENTORY={inventory}",
                "FINAL_PHYSICAL_SIGNOFF_READY=NO",
            ]
        ) + "\n"
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(report)
        print(report, end="")
        return 0
    except GateError as exc:
        write_failure(out, exc, args.tool_rc)
        print(out.read_text(), end="")
        return 8


if __name__ == "__main__":
    sys.exit(main())
