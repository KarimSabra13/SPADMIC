#!/usr/bin/env python3
"""Prepare a standalone RO_tune6 PVS LVS run from an attributable template."""

from __future__ import annotations

import argparse
import re
import shutil
from pathlib import Path


DROP_CONTROL = re.compile(
    r"^\s*(schematic_path|layout_path|lvs_black_box|lvs_verilog_bus_map_by_position|lvs_global_sigs_are_ports)\b",
    re.IGNORECASE,
)
EXPECTED_RO6_PINS = {
    "VDD",
    "VSS",
    "rstb",
    *(f"code<{bit}>" for bit in range(8)),
    *(f"S<{bit}>" for bit in range(8)),
}


def quoted(path: Path) -> str:
    value = str(path)
    if '"' in value or "\n" in value:
        raise ValueError(f"unsafe path for PVS control: {value}")
    return f'"{value}"'


def extract_pvs_binary(run_file: Path) -> str:
    text = run_file.read_text(encoding="utf-8", errors="replace")
    match = re.search(r"^\s*(/\S*/pvs|pvs)\s*\\?\s*$", text, re.MULTILINE)
    if match is None:
        raise ValueError(f"cannot identify PVS executable in {run_file}")
    return match.group(1)


def logical_cdl_lines(path: Path) -> list[str]:
    logical: list[str] = []
    for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
        stripped = raw.strip()
        if not stripped or stripped.startswith("*"):
            continue
        if stripped.startswith("+"):
            if not logical:
                raise ValueError(f"orphan CDL continuation in {path}: {raw}")
            logical[-1] += " " + stripped[1:].strip()
        else:
            logical.append(stripped)
    return logical


def validate_ro6_cdl(path: Path) -> list[str]:
    definitions: list[list[str]] = []
    for line in logical_cdl_lines(path):
        tokens = line.split()
        if len(tokens) >= 2 and tokens[0].upper() == ".SUBCKT" and tokens[1] == "RO_tune6":
            pins = []
            for token in tokens[2:]:
                if token.upper() == "PARAMS:" or "=" in token:
                    break
                pins.append(token.lstrip("\\"))
            definitions.append(pins)
    if len(definitions) != 1:
        raise ValueError(
            f"expected one .SUBCKT RO_tune6 in {path}, found {len(definitions)}"
        )
    pins = definitions[0]
    if len(pins) != len(set(pins)):
        raise ValueError(f"RO_tune6 CDL pin list contains duplicates: {pins}")
    actual = set(pins)
    if actual != EXPECTED_RO6_PINS:
        missing = sorted(EXPECTED_RO6_PINS - actual)
        extra = sorted(actual - EXPECTED_RO6_PINS)
        raise ValueError(
            "RO_tune6 CDL pin contract mismatch: "
            f"missing={missing or 'NONE'} extra={extra or 'NONE'}"
        )
    return pins


def rewrite_control(template: Path, output: Path, gds: Path, cdl: Path) -> None:
    kept: list[str] = []
    report_seen = 0
    layout_format_seen = 0
    for line in template.read_text(encoding="utf-8", errors="replace").splitlines():
        if DROP_CONTROL.match(line):
            continue
        if re.match(r"^\s*lvs_report_file\b", line, re.IGNORECASE):
            kept.append('lvs_report_file "RO_tune6_lvs.sum";')
            report_seen += 1
            continue
        if re.match(r"^\s*layout_format\s+gdsii\s*;", line, re.IGNORECASE):
            layout_format_seen += 1
        kept.append(line)
    if report_seen != 1:
        raise ValueError(f"expected one lvs_report_file control, found {report_seen}")
    if layout_format_seen != 1:
        raise ValueError(f"expected one GDSII layout_format control, found {layout_format_seen}")
    kept.extend(
        [
            "",
            "// MPTDC standalone RO_tune6 LVS; no HCell and no blackbox.",
            f"schematic_path {quoted(cdl)} cdl;",
            f"layout_path {quoted(gds)};",
        ]
    )
    output.write_text("\n".join(kept) + "\n", encoding="utf-8")


def write_run_file(output: Path, pvs: str, run_dir: Path) -> None:
    lines = [
        "#!/bin/sh -f",
        "# MPTDC attributable standalone RO_tune6 LVS",
        f"cd {quoted(run_dir)} || exit 3",
        f"{pvs} \\",
        "  -lvs \\",
        "  -top_cell RO_tune6 \\",
        "  -source_top_cell RO_tune6 \\",
        f"  -spice {quoted(run_dir / 'RO_tune6.spi')} \\",
        f"  -control {quoted(run_dir / 'pvslvsctl')} \\",
        "  -ui_data \\",
        "  -gdb_data \\",
        f"  {quoted(run_dir / '.config.rul')} \\",
        f"  {quoted(run_dir / '.technology.rul')}",
    ]
    output.write_text("\n".join(lines) + "\n", encoding="utf-8")
    output.chmod(0o755)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--template-run", required=True, type=Path)
    parser.add_argument("--run-dir", required=True, type=Path)
    parser.add_argument("--ro-gds", required=True, type=Path)
    parser.add_argument("--ro-cdl", required=True, type=Path)
    args = parser.parse_args()

    try:
        for path in (args.ro_gds, args.ro_cdl):
            if not path.is_file() or path.stat().st_size == 0:
                raise ValueError(f"required RO artifact is missing or empty: {path}")
        required = ["run.pvs", "pvslvsctl", ".config.rul", ".technology.rul"]
        for name in required:
            path = args.template_run / name
            if not path.is_file():
                raise ValueError(f"template file is missing: {path}")
        if args.run_dir.exists():
            raise ValueError(f"standalone LVS run directory already exists: {args.run_dir}")

        cdl_pins = validate_ro6_cdl(args.ro_cdl)

        args.run_dir.mkdir(parents=True)
        shutil.copy2(args.template_run / ".config.rul", args.run_dir / ".config.rul")
        shutil.copy2(args.template_run / ".technology.rul", args.run_dir / ".technology.rul")
        rewrite_control(
            args.template_run / "pvslvsctl",
            args.run_dir / "pvslvsctl",
            args.ro_gds.resolve(),
            args.ro_cdl.resolve(),
        )
        write_run_file(
            args.run_dir / "run.pvs",
            extract_pvs_binary(args.template_run / "run.pvs"),
            args.run_dir.resolve(),
        )
        print("RO6_STANDALONE_PREP_STATUS=PASS")
        print("RO6_CDL_PIN_CONTRACT_STATUS=PASS")
        print(f"RO6_CDL_PIN_COUNT={len(cdl_pins)}")
        print(f"RO6_CDL_PINS={','.join(cdl_pins)}")
        print(f"RO6_STANDALONE_RUN_DIR={args.run_dir}")
        return 0
    except ValueError as error:
        print(f"RO6_STANDALONE_PREP_STATUS=FAIL")
        print("RO6_CDL_PIN_CONTRACT_STATUS=FAIL")
        print(f"RO6_STANDALONE_PREP_ERROR={error}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
