#!/usr/bin/env python3
"""Read-only semantic audit of a GUI-generated PVS LVS control scaffold."""

from __future__ import annotations

import argparse
import hashlib
import re
from pathlib import Path

from replay_pvs_handoff_template import (
    PVS_VALUE,
    SHELL_VALUE,
    schematic_path_values,
    strip_c_style_comments,
    unquote,
)


CONTROL_FILES = (
    ".config.rul",
    ".preset.autosave",
    ".technology.rul",
    "pipo1.setup",
    "pvslvsctl",
    "run.pvs",
)


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def shell_option_values(text: str, option: str) -> list[str]:
    pattern = re.compile(rf"(?<!\S){re.escape(option)}[ \t]+({SHELL_VALUE})")
    return [unquote(match.group(1)) for match in pattern.finditer(text)]


def pvs_directive_values(text: str, directive: str) -> list[str]:
    pattern = re.compile(
        rf"(?im)^[ \t]*{directive}[ \t]+(?P<value>{PVS_VALUE})"
    )
    return [unquote(match.group("value")) for match in pattern.finditer(text)]


def regex_count(text: str, pattern: str) -> int:
    return len(re.findall(pattern, text, re.I | re.M))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--template", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--expected-pvs-bin", required=True)
    args = parser.parse_args()

    template = args.template.resolve()
    output = args.output.resolve()
    errors: list[str] = []
    controls: dict[str, Path] = {
        name: template / name for name in CONTROL_FILES
    }
    for name, path in controls.items():
        if not path.is_file():
            errors.append(f"missing_control={name}")

    run_text = ""
    control_text = ""
    if controls["run.pvs"].is_file():
        run_text = strip_c_style_comments(
            controls["run.pvs"].read_text(errors="replace")
        )
    if controls["pvslvsctl"].is_file():
        control_text = strip_c_style_comments(
            controls["pvslvsctl"].read_text(errors="replace")
        )

    mode_lvs_count = regex_count(run_text, r"(?<!\S)-lvs(?=\s|\\|$)")
    mode_drc_count = regex_count(run_text, r"(?<!\S)-drc(?=\s|\\|$)")
    pvs_binary_count = run_text.count(args.expected_pvs_bin)
    if mode_lvs_count != 1:
        errors.append(f"lvs_mode_count={mode_lvs_count}")
    if mode_drc_count != 0:
        errors.append(f"drc_mode_count={mode_drc_count}")
    if pvs_binary_count != 1:
        errors.append(f"expected_pvs_binary_count={pvs_binary_count}")

    option_values = {
        option: shell_option_values(run_text, option)
        for option in ("-top_cell", "-source_top_cell", "-control", "-spice")
    }
    for option, values in option_values.items():
        if len(values) != 1:
            errors.append(f"{option.removeprefix('-')}_count={len(values)}")

    template_layout_top = (
        option_values["-top_cell"][0]
        if len(option_values["-top_cell"]) == 1
        else "UNKNOWN"
    )
    template_source_top = (
        option_values["-source_top_cell"][0]
        if len(option_values["-source_top_cell"]) == 1
        else "UNKNOWN"
    )
    control_path = (
        option_values["-control"][0]
        if len(option_values["-control"]) == 1
        else "UNKNOWN"
    )
    if control_path != "UNKNOWN" and Path(control_path).name != "pvslvsctl":
        errors.append(f"unexpected_control_basename={Path(control_path).name}")

    layout_paths = pvs_directive_values(control_text, r"layout_path")
    verilog_paths = schematic_path_values(control_text, "verilog")
    spice_paths = schematic_path_values(control_text, "spice")
    if len(layout_paths) != 1:
        errors.append(f"layout_path_count={len(layout_paths)}")
    if len(verilog_paths) != 1:
        errors.append(f"schematic_verilog_count={len(verilog_paths)}")
    if len(spice_paths) > 1:
        errors.append(f"schematic_spice_count={len(spice_paths)}")

    template_gds = layout_paths[0] if len(layout_paths) == 1 else "UNKNOWN"
    template_source = verilog_paths[0] if len(verilog_paths) == 1 else "UNKNOWN"
    template_executable_cdl = spice_paths[0] if spice_paths else "NONE"
    for label, value in (
        ("template_gds", template_gds),
        ("template_source", template_source),
    ):
        if value != "UNKNOWN" and not Path(value).is_absolute():
            errors.append(f"{label}_not_absolute={value}")

    required_control_patterns = {
        "layout_format_gdsii": r"^[ \t]*layout_format[ \t]+gdsii[ \t]*;",
        "lvs_report_file": r"^[ \t]*lvs_report_file[ \t]+",
        "erc_report_summary": r"^[ \t]*report_summary[ \t]+-erc[ \t]+",
        "erc_results_db": r"^[ \t]*results_db[ \t]+-erc[ \t]+",
        "lvs_ignore_ports_no": r"^[ \t]*lvs_ignore_ports[ \t]+no[ \t]*;",
        "lvs_expand_cell_on_error_no": (
            r"^[ \t]*lvs_expand_cell_on_error[ \t]+no[ \t]*;"
        ),
        "lvs_run_erc_checks_yes": (
            r"^[ \t]*lvs_run_erc_checks[ \t]+yes[ \t]*;"
        ),
        "abort_on_layout_error_yes": (
            r"^[ \t]*abort_on_layout_error[ \t]+yes[ \t]*;"
        ),
        "dummy_fill_undefined": r"^[ \t]*#UNDEFINE[ \t]+DUMMY_FILL\b",
    }
    control_counts: dict[str, int] = {}
    for label, pattern in required_control_patterns.items():
        count = regex_count(control_text, pattern)
        control_counts[label] = count
        if count != 1:
            errors.append(f"{label}_count={count}")

    svdb_count = regex_count(
        control_text,
        r"^[ \t]*mask_svdb_dir[ \t]+",
    )
    control_counts["svdb_directory"] = svdb_count
    if svdb_count > 1:
        errors.append(f"svdb_directory_count={svdb_count}")

    output.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "LABEL=SPADMIC_PVS_LVS_CONTROL_SCAFFOLD_AUDIT",
        f"STATUS={'FAIL' if errors else 'PASS'}",
        f"TEMPLATE={template}",
        "SOURCE_MUTATION_AUTHORIZED=NO",
        f"EXPECTED_PVS_BIN={args.expected_pvs_bin}",
        f"EXPECTED_PVS_BIN_OCCURRENCES={pvs_binary_count}",
        f"LVS_MODE_OCCURRENCES={mode_lvs_count}",
        f"DRC_MODE_OCCURRENCES={mode_drc_count}",
        f"TEMPLATE_LAYOUT_TOP={template_layout_top}",
        f"TEMPLATE_SOURCE_TOP={template_source_top}",
        f"TEMPLATE_GDS={template_gds}",
        f"TEMPLATE_SOURCE={template_source}",
        f"TEMPLATE_EXECUTABLE_CDL={template_executable_cdl}",
        f"TEMPLATE_CONTROL={control_path}",
        f"LAYOUT_PATH_COUNT={len(layout_paths)}",
        f"SCHEMATIC_VERILOG_COUNT={len(verilog_paths)}",
        f"SCHEMATIC_SPICE_COUNT={len(spice_paths)}",
    ]
    for label, count in control_counts.items():
        lines.append(f"{label.upper()}_COUNT={count}")
    for name, path in controls.items():
        if path.is_file():
            lines.append(
                f"CONTROL={name}|BYTES={path.stat().st_size}|SHA256={digest(path)}"
            )
    lines.append(f"ERROR_COUNT={len(errors)}")
    lines.extend(f"ERROR={error}" for error in errors)
    output.write_text("\n".join(lines) + "\n")
    print(output.read_text(), end="")
    if errors:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
