#!/usr/bin/env python3
"""Prepare a strict full-top PVS LVS run with an external RO_tune6 CDL."""

from __future__ import annotations

import argparse
import re
import shutil
from pathlib import Path


DROP_CONTROL = re.compile(
    r"^\s*(schematic_path|layout_path|lvs_black_box|"
    r"lvs_verilog_bus_map_by_position|lvs_global_sigs_are_ports)\b",
    re.IGNORECASE,
)
FORBIDDEN_CONTROL = re.compile(
    r"^\s*(lvs_black_box|lvs_verilog_bus_map_by_position|"
    r"lvs_global_sigs_are_ports)\b",
    re.IGNORECASE | re.MULTILINE,
)


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


def rewrite_control(
    template: Path,
    output: Path,
    gds: Path,
    source: Path,
    dcell_cdl: Path,
    ro_cdl: Path,
) -> None:
    kept: list[str] = []
    report_seen = 0
    layout_format_seen = 0
    for line in template.read_text(encoding="utf-8", errors="replace").splitlines():
        if DROP_CONTROL.match(line):
            continue
        if re.match(r"^\s*lvs_report_file\b", line, re.IGNORECASE):
            kept.append('lvs_report_file "mptdc_axis_core_lvs.sum";')
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
            "// MPTDC monolithic full-top LVS; external RO CDL, no HCell/blackbox.",
            f"schematic_path {quoted(source)} verilog -keep_backslash;",
            f"schematic_path {quoted(dcell_cdl)} cdl;",
            f"schematic_path {quoted(ro_cdl)} cdl;",
            f"layout_path {quoted(gds)};",
        ]
    )
    text = "\n".join(kept) + "\n"
    if FORBIDDEN_CONTROL.search(text):
        raise ValueError("forbidden blackbox, bus-position, or global-port rule remains")
    if len(re.findall(r"^\s*schematic_path\b", text, re.MULTILINE | re.IGNORECASE)) != 3:
        raise ValueError("monolithic control does not contain exactly three schematic paths")
    if len(re.findall(r"^\s*layout_path\b", text, re.MULTILINE | re.IGNORECASE)) != 1:
        raise ValueError("monolithic control does not contain exactly one layout path")
    output.write_text(text, encoding="utf-8")


def write_run_file(output: Path, pvs: str, run_dir: Path) -> None:
    lines = [
        "#!/bin/sh -f",
        "# MPTDC attributable monolithic full-top LVS",
        f"cd {quoted(run_dir)} || exit 3",
        f"{pvs} \\",
        "  -lvs \\",
        "  -top_cell mptdc_axis_core \\",
        "  -source_top_cell mptdc_axis_core \\",
        f"  -spice {quoted(run_dir / 'mptdc_axis_core.spi')} \\",
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
    parser.add_argument("--gds", required=True, type=Path)
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--dcell-cdl", required=True, type=Path)
    parser.add_argument("--ro-cdl", required=True, type=Path)
    args = parser.parse_args()

    try:
        for path in (args.gds, args.source, args.dcell_cdl, args.ro_cdl):
            if not path.is_file() or path.stat().st_size == 0:
                raise ValueError(f"required monolithic LVS input is missing or empty: {path}")
        for name in ("run.pvs", "pvslvsctl", ".config.rul", ".technology.rul"):
            path = args.template_run / name
            if not path.is_file():
                raise ValueError(f"template file is missing: {path}")
        if (args.template_run / ".config.rul").stat().st_size != 0:
            raise ValueError("monolithic LVS requires an empty template .config.rul")
        if (args.template_run / ".technology.rul").stat().st_size == 0:
            raise ValueError("monolithic LVS requires a nonempty template .technology.rul")
        if args.run_dir.exists():
            raise ValueError(f"monolithic LVS run directory already exists: {args.run_dir}")

        args.run_dir.mkdir(parents=True)
        shutil.copy2(args.template_run / ".config.rul", args.run_dir / ".config.rul")
        shutil.copy2(
            args.template_run / ".technology.rul",
            args.run_dir / ".technology.rul",
        )
        rewrite_control(
            args.template_run / "pvslvsctl",
            args.run_dir / "pvslvsctl",
            args.gds.resolve(),
            args.source.resolve(),
            args.dcell_cdl.resolve(),
            args.ro_cdl.resolve(),
        )
        write_run_file(
            args.run_dir / "run.pvs",
            extract_pvs_binary(args.template_run / "run.pvs"),
            args.run_dir.resolve(),
        )
        print("RO6_MONOLITHIC_PREP_STATUS=PASS")
        print("LVS_SCHEMATIC_PATH_COUNT=3")
        print("LVS_LAYOUT_PATH_COUNT=1")
        print("LVS_HCELL_STATUS=NOT_USED")
        print("LVS_BLACKBOX_STATUS=NOT_USED")
        print("LVS_CONFIG_RULE_STATUS=PASS_EMPTY")
        print("LVS_TECHNOLOGY_RULE_STATUS=PASS")
        print(f"RO6_MONOLITHIC_RUN_DIR={args.run_dir}")
        return 0
    except ValueError as error:
        print("RO6_MONOLITHIC_PREP_STATUS=FAIL")
        print(f"RO6_MONOLITHIC_PREP_ERROR={error}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
