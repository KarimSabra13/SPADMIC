#!/usr/bin/env python3
"""Clone the executable part of a GUI PVS run and patch explicit values."""

from __future__ import annotations

import argparse
import hashlib
import re
import shlex
import shutil
from pathlib import Path


CORE_FILES = {
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


def is_text(path: Path) -> bool:
    try:
        path.read_text()
        return True
    except (UnicodeDecodeError, OSError):
        return False


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def strip_c_style_comments(text: str) -> str:
    """Remove PVS/C comments without altering quoted path strings."""
    output: list[str] = []
    index = 0
    quote: str | None = None
    while index < len(text):
        char = text[index]
        if quote is not None:
            output.append(char)
            if char == "\\" and index + 1 < len(text):
                output.append(text[index + 1])
                index += 2
                continue
            if char == quote:
                quote = None
            index += 1
            continue
        if char in {'"', "'"}:
            quote = char
            output.append(char)
            index += 1
            continue
        if text.startswith("//", index):
            newline = text.find("\n", index + 2)
            if newline == -1:
                break
            output.append("\n")
            index = newline + 1
            continue
        if text.startswith("/*", index):
            end = text.find("*/", index + 2)
            if end == -1:
                output.extend("\n" * text[index:].count("\n"))
                break
            comment = text[index : end + 2]
            output.extend("\n" * comment.count("\n"))
            index = end + 2
            continue
        output.append(char)
        index += 1
    return "".join(output)


SHELL_VALUE = r'(?:"[^"\n]*"|\'[^\'\n]*\'|[^\s\\;]+)'
PVS_VALUE = r'(?:"[^"\n]*"|\{[^}\n]*\}|[^;\s]+)'


def unquote(value: str) -> str:
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {'"', "'"}:
        return value[1:-1]
    return value


def discover_execution_roots(run_text: str) -> list[Path]:
    roots: set[Path] = set()
    for match in re.finditer(rf"(?m)^\s*cd\s+({SHELL_VALUE})\s*;\\?\s*$", run_text):
        value = unquote(match.group(1))
        if value.startswith("/"):
            roots.add(Path(value))
    for option in ("-control", "-cell_tree"):
        match = re.search(rf"{re.escape(option)}\s+({SHELL_VALUE})", run_text)
        if match:
            value = unquote(match.group(1))
            if value.startswith("/"):
                roots.add(Path(value).parent)
    return sorted(roots, key=lambda path: (-len(str(path)), str(path)))


def shell_option_value(text: str, option: str) -> str | None:
    match = re.search(rf"{re.escape(option)}\s+({SHELL_VALUE})", text)
    return unquote(match.group(1)) if match else None


def replace_shell_option(
    text: str,
    option: str,
    value: Path,
    *,
    required: bool,
) -> tuple[str, int]:
    pattern = re.compile(rf"({re.escape(option)}[ \t]+){SHELL_VALUE}")
    text, count = pattern.subn(
        lambda match: match.group(1) + shlex.quote(str(value)),
        text,
    )
    if required and count == 0:
        raise SystemExit(f"PVS_REPLAY_CONTRACT_FAIL: option missing from run.pvs: {option}")
    return text, count


def replace_shell_file_argument(
    text: str,
    basename: str,
    value: Path,
) -> tuple[str, int]:
    pattern = re.compile(
        rf"(?<!\S)(?:\"(?:[^\"\n]*/)?{re.escape(basename)}\"|"
        rf"'(?:[^'\n]*/)?{re.escape(basename)}'|"
        rf"[^\s\\;]*/{re.escape(basename)}|{re.escape(basename)})(?=\s|\\|$)"
    )
    return pattern.subn(shlex.quote(str(value)), text)


def replace_pvs_directive_path(
    text: str,
    directive: str,
    value: Path,
    *,
    required: bool,
) -> tuple[str, int]:
    pattern = re.compile(rf"({directive}[ \t]+){PVS_VALUE}", re.I)
    escaped = str(value).replace("\\", "\\\\").replace('"', '\\"')
    text, count = pattern.subn(
        lambda match: f'{match.group(1)}"{escaped}"',
        text,
    )
    if required and count == 0:
        raise SystemExit(
            f"PVS_REPLAY_CONTRACT_FAIL: result directive missing: {directive}"
        )
    return text, count


def schematic_path_pattern(format_name: str) -> re.Pattern[str]:
    return re.compile(
        rf"(?im)^([ \t]*schematic_path[ \t]+)"
        rf"(?P<path>{PVS_VALUE})"
        rf"(?P<suffix>[ \t]+{re.escape(format_name)}[ \t]*;[^\n]*)$"
    )


def schematic_path_values(text: str, format_name: str) -> list[str]:
    return [
        unquote(match.group("path"))
        for match in schematic_path_pattern(format_name).finditer(text)
    ]


def normalize_schematic_path(
    text: str,
    format_name: str,
    value: Path,
    *,
    add_if_missing: bool,
) -> tuple[str, str]:
    pattern = schematic_path_pattern(format_name)
    matches = list(pattern.finditer(text))
    if len(matches) > 1:
        raise SystemExit(
            "PVS_REPLAY_CONTRACT_FAIL: multiple executable schematic_path "
            f"{format_name} directives are not supported"
        )
    escaped = str(value).replace("\\", "\\\\").replace('"', '\\"')
    if matches:
        text, count = pattern.subn(
            lambda match: (
                f'{match.group(1)}"{escaped}"{match.group("suffix")}'
            ),
            text,
        )
        if count != 1:
            raise SystemExit(
                "PVS_REPLAY_CONTRACT_FAIL: failed to normalize executable "
                f"schematic_path {format_name}"
            )
        return text, "REPLACED_EXISTING"
    if not add_if_missing:
        raise SystemExit(
            "PVS_REPLAY_CONTRACT_FAIL: executable schematic_path "
            f"{format_name} directive is missing"
        )

    directive = f'schematic_path "{escaped}" {format_name};'
    existing = list(
        re.finditer(r"(?im)^[ \t]*schematic_path\b[^\n]*$", text)
    )
    if existing:
        insertion = existing[-1].end()
        text = text[:insertion] + "\n" + directive + text[insertion:]
    else:
        text = text.rstrip() + "\n" + directive + "\n"
    return text, "ADDED_MISSING"


def normalize_control_inputs(
    control: Path,
    mode: str,
    expected_gds: Path | None,
    expected_source: Path | None,
    expected_cdl: Path | None,
) -> list[str]:
    text = control.read_text()
    lines: list[str] = []
    if expected_gds is None:
        raise SystemExit(
            "PVS_REPLAY_CONTRACT_FAIL: canonical layout GDS input is required"
        )
    text, layout_count = replace_pvs_directive_path(
        text,
        r"layout_path",
        expected_gds,
        required=True,
    )
    if layout_count != 1:
        raise SystemExit(
            "PVS_REPLAY_CONTRACT_FAIL: expected exactly one executable "
            "layout_path directive"
        )
    lines.extend(
        [
            f"LAYOUT_GDS_INPUT={expected_gds}",
            f"LAYOUT_GDS_REWRITE_COUNT={layout_count}",
        ]
    )
    if mode == "lvs":
        if expected_source is None or expected_cdl is None:
            raise SystemExit(
                "PVS_REPLAY_CONTRACT_FAIL: canonical LVS source and CDL "
                "inputs are required"
            )
        text, source_action = normalize_schematic_path(
            text,
            "verilog",
            expected_source,
            add_if_missing=False,
        )
        text, cdl_action = normalize_schematic_path(
            text,
            "spice",
            expected_cdl,
            add_if_missing=True,
        )
        lines.extend(
            [
                f"SCHEMATIC_VERILOG_INPUT={expected_source}",
                f"SCHEMATIC_VERILOG_ACTION={source_action}",
                f"SCHEMATIC_CDL_INPUT={expected_cdl}",
                f"SCHEMATIC_CDL_ACTION={cdl_action}",
            ]
        )
    control.write_text(text)
    return lines


def normalize_run_file(
    run_file: Path,
    run_dir: Path,
    mode: str,
    expected_layout_top: str,
) -> list[str]:
    text = run_file.read_text()
    cd_pattern = re.compile(
        rf"(?m)^([ \t]*)cd[ \t]+({SHELL_VALUE})([ \t]*;\\?[ \t]*)$"
    )
    cd_count = 0

    def replace_cd(match: re.Match[str]) -> str:
        nonlocal cd_count
        value = unquote(match.group(2))
        if value.startswith("$"):
            return match.group(0)
        cd_count += 1
        return (
            f"{match.group(1)}cd {shlex.quote(str(run_dir))}"
            f"{match.group(3)}"
        )

    text = cd_pattern.sub(replace_cd, text)
    control = run_dir / ("pvsdrcctl" if mode == "drc" else "pvslvsctl")
    text, control_count = replace_shell_option(
        text,
        "-control",
        control,
        required=True,
    )
    cell_tree_count = 0
    if re.search(r"(?:^|\s)-cell_tree(?:\s|$)", text):
        cell_tree = run_dir / "cell_tree.txt"
        if not cell_tree.is_file():
            raise SystemExit(
                "PVS_REPLAY_CONTRACT_FAIL: run.pvs requests cell_tree.txt "
                "but the template did not provide a local copy"
            )
        text, cell_tree_count = replace_shell_option(
            text,
            "-cell_tree",
            cell_tree,
            required=True,
        )
    config_count = 0
    technology_count = 0
    text, config_count = replace_shell_file_argument(
        text,
        ".config.rul",
        run_dir / ".config.rul",
    )
    text, technology_count = replace_shell_file_argument(
        text,
        ".technology.rul",
        run_dir / ".technology.rul",
    )
    if config_count == 0 or technology_count == 0:
        raise SystemExit(
            "PVS_REPLAY_CONTRACT_FAIL: run.pvs must execute the copied "
            ".config.rul and .technology.rul"
        )
    spice_count = 0
    if mode == "lvs" and re.search(r"(?:^|\s)-spice(?:\s|$)", text):
        text, spice_count = replace_shell_option(
            text,
            "-spice",
            run_dir / f"{expected_layout_top}.spi",
            required=True,
        )
    run_file.write_text(text)
    return [
        f"WORKING_DIRECTORY_REWRITE_COUNT={cd_count}",
        f"CONTROL_REWRITE_COUNT={control_count}",
        f"CELL_TREE_REWRITE_COUNT={cell_tree_count}",
        f"CONFIG_RULE_REWRITE_COUNT={config_count}",
        f"TECHNOLOGY_RULE_REWRITE_COUNT={technology_count}",
        f"SPICE_OUTPUT_REWRITE_COUNT={spice_count}",
    ]


def normalize_control_outputs(
    control: Path,
    run_dir: Path,
    mode: str,
    expected_layout_top: str,
) -> list[str]:
    text = control.read_text()
    lines: list[str] = []
    if mode == "drc":
        summary = run_dir / f"{expected_layout_top}_drc.sum"
        results = run_dir / f"{expected_layout_top}_drc.err"
        text, count = replace_pvs_directive_path(
            text,
            r"report_summary\s+-drc",
            summary,
            required=True,
        )
        lines.extend(
            [
                f"DRC_SUMMARY={summary}",
                f"DRC_SUMMARY_REWRITE_COUNT={count}",
            ]
        )
        text, count = replace_pvs_directive_path(
            text,
            r"results_db\s+-drc",
            results,
            required=False,
        )
        lines.extend(
            [
                f"DRC_RESULTS_DB={results if count else 'NOT_CONFIGURED'}",
                f"DRC_RESULTS_DB_REWRITE_COUNT={count}",
            ]
        )
    else:
        lvs_report = run_dir / f"{expected_layout_top}_lvs.sum"
        erc_summary = run_dir / f"{expected_layout_top}_erc.sum"
        erc_results = run_dir / f"{expected_layout_top}_lvs.err"
        svdb = run_dir / "svdb"
        text, count = replace_pvs_directive_path(
            text,
            r"lvs_report_file",
            lvs_report,
            required=True,
        )
        lines.extend(
            [
                f"LVS_REPORT={lvs_report}",
                f"LVS_REPORT_REWRITE_COUNT={count}",
            ]
        )
        text, count = replace_pvs_directive_path(
            text,
            r"report_summary\s+-erc",
            erc_summary,
            required=False,
        )
        lines.extend(
            [
                f"ERC_SUMMARY={erc_summary if count else 'NOT_CONFIGURED'}",
                f"ERC_SUMMARY_REWRITE_COUNT={count}",
            ]
        )
        text, count = replace_pvs_directive_path(
            text,
            r"results_db\s+-erc",
            erc_results,
            required=False,
        )
        lines.extend(
            [
                f"ERC_RESULTS_DB={erc_results if count else 'NOT_CONFIGURED'}",
                f"ERC_RESULTS_DB_REWRITE_COUNT={count}",
            ]
        )
        text, count = replace_pvs_directive_path(
            text,
            r"mask_svdb_dir",
            svdb,
            required=False,
        )
        lines.extend(
            [
                f"SVDB_DIRECTORY={svdb if count else 'NOT_CONFIGURED'}",
                f"SVDB_REWRITE_COUNT={count}",
            ]
        )
    control.write_text(text)
    return lines


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--template", required=True, type=Path)
    parser.add_argument("--run-dir", required=True, type=Path)
    parser.add_argument("--mode", choices=["drc", "lvs"], required=True)
    parser.add_argument("--cadence-pvs", required=True)
    parser.add_argument("--replace", action="append", default=[])
    parser.add_argument("--expected-layout-top")
    parser.add_argument("--expected-source-top")
    parser.add_argument("--expected-gds", type=Path)
    parser.add_argument("--expected-source", type=Path)
    parser.add_argument("--expected-cdl", type=Path)
    parser.add_argument("--preprocessor-define", action="append", default=[])
    parser.add_argument("--preprocessor-undefine", action="append", default=[])
    args = parser.parse_args()

    template = args.template.resolve()
    run_dir = args.run_dir.resolve()
    if not template.is_dir():
        raise SystemExit(f"template missing: {template}")
    if run_dir.exists():
        raise SystemExit(f"immutable PVS run already exists: {run_dir}")
    required_control = "pvsdrcctl" if args.mode == "drc" else "pvslvsctl"
    for name in ["run.pvs", ".config.rul", ".technology.rul", required_control]:
        if not (template / name).is_file():
            raise SystemExit(f"template file missing: {template / name}")

    run_dir.mkdir(parents=True)
    copied = []
    for source in template.iterdir():
        if not source.is_file():
            continue
        if source.name in CORE_FILES or source.suffix in {".lmap", ".rul"}:
            destination = run_dir / source.name
            shutil.copy2(source, destination)
            copied.append(destination)

    dependency_lines: list[str] = []
    original_run_text = (template / "run.pvs").read_text(errors="ignore")
    if shell_option_value(original_run_text, "-cell_tree") is not None:
        local_cell_tree = run_dir / "cell_tree.txt"
        if not local_cell_tree.is_file():
            cell_tree_value = shell_option_value(original_run_text, "-cell_tree")
            external_cell_tree = Path(cell_tree_value) if cell_tree_value else Path()
            if not external_cell_tree.is_file():
                raise SystemExit(
                    "PVS_REPLAY_CONTRACT_FAIL: run.pvs requests cell_tree.txt "
                    "but neither the template nor its referenced path provides it"
                )
            shutil.copy2(external_cell_tree, local_cell_tree)
            copied.append(local_cell_tree)
            dependency_lines.append(
                f"COPIED_EXTERNAL_CELL_TREE={external_cell_tree}|"
                f"SHA256={digest(local_cell_tree)}"
            )

    replacements: list[tuple[str, str]] = []
    explicit_replacements: list[tuple[str, str]] = []
    for item in args.replace:
        if "=" not in item:
            raise SystemExit(f"replacement must be OLD=NEW: {item}")
        old, new = item.split("=", 1)
        if not old:
            raise SystemExit(f"empty OLD replacement: {item}")
        explicit_replacements.append((old, new))
        if old != new:
            replacements.append((old, new))
    original_text = {
        path: path.read_text(errors="ignore")
        for path in copied
        if is_text(path)
    }
    run_file = run_dir / "run.pvs"
    inferred_execution_roots = discover_execution_roots(original_text[run_file])
    replacement_lines = ["LABEL=SPADMIC_PVS_TEMPLATE_REPLACEMENTS"]
    replacement_lines.extend(dependency_lines)
    for old, new in explicit_replacements:
        count = sum(text.count(old) for text in original_text.values())
        replacement_lines.append(f"OLD={old}|NEW={new}|OCCURRENCES={count}")
        if old != new and count == 0:
            raise SystemExit(f"REPLACEMENT_SOURCE_NOT_FOUND: {old}")
    # Apply specific artifacts first. Relocate both the selected template and
    # any GUI-generated execution root afterward so old sibling run paths
    # cannot bypass the copied controls.
    relocation_roots = {template, *inferred_execution_roots}
    for root in sorted(relocation_roots, key=lambda path: (-len(str(path)), str(path))):
        if root != run_dir:
            replacements.append((str(root), str(run_dir)))
            replacement_lines.append(
                f"INFERRED_EXECUTION_ROOT={root}|NEW={run_dir}"
            )

    for path in copied:
        if not is_text(path):
            continue
        text = path.read_text()
        for old, new in replacements:
            text = text.replace(old, new)
        # The copied run is pinned to the selected Cadence binary regardless of PATH.
        for known in [
            "/eda/cadence/2023-24/RHELx86/PVS_22.22.000/bin/pvs",
            "/eda/cadence/2023-24/RHELx86/PVS_22.22.000/tools/bin/pvs",
        ]:
            text = text.replace(known, args.cadence_pvs)
        path.write_text(text)

    execution_lines = normalize_run_file(
        run_file,
        run_dir,
        args.mode,
        args.expected_layout_top or "layout",
    )
    control = run_dir / required_control
    input_lines = normalize_control_inputs(
        control,
        args.mode,
        args.expected_gds,
        args.expected_source,
        args.expected_cdl,
    )
    output_lines = normalize_control_outputs(
        control,
        run_dir,
        args.mode,
        args.expected_layout_top or "layout",
    )

    define_lines = ["LABEL=SPADMIC_PVS_PREPROCESSOR_DEFINES"]
    requested_defines = [(name, "DEFINE") for name in args.preprocessor_define]
    requested_defines.extend((name, "UNDEFINE") for name in args.preprocessor_undefine)
    if len({name for name, _ in requested_defines}) != len(requested_defines):
        raise SystemExit("a preprocessor symbol cannot be both defined and undefined")
    for name, directive in requested_defines:
        if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name):
            raise SystemExit(f"invalid preprocessor define: {name}")
        pattern = re.compile(rf"#(?:UN)?DEFINE\s+{re.escape(name)}\b")
        count = 0
        for path in copied:
            if not is_text(path):
                continue
            text = path.read_text()
            text, path_count = pattern.subn(f"#{directive} {name}", text)
            count += path_count
            path.write_text(text)
        define_lines.append(f"{directive}={name}|OCCURRENCES={count}")
        if count == 0:
            raise SystemExit(f"PREPROCESSOR_DEFINE_NOT_FOUND: {name}")

    text = run_file.read_text()
    if args.cadence_pvs not in text:
        raise SystemExit("PVS_BINARY_GATE_FAIL: patched run.pvs does not name the selected Cadence binary")
    stale = [old for old, _ in replacements if old and old in "\n".join(p.read_text(errors="ignore") for p in copied)]
    if stale:
        raise SystemExit(f"STALE_TEMPLATE_PATHS: {stale}")
    all_patched_text = "\n".join(
        path.read_text(errors="ignore")
        for path in copied
        if is_text(path)
    )
    contract_errors: list[str] = []
    if args.expected_layout_top:
        if not re.search(
            rf"-top_cell\s+[\"{{]?{re.escape(args.expected_layout_top)}(?:[\"}}\s]|$)",
            text,
        ):
            contract_errors.append(f"layout_top_not_in_run={args.expected_layout_top}")
    if args.mode == "lvs" and args.expected_source_top:
        if not re.search(
            rf"-source_top_cell\s+[\"{{]?{re.escape(args.expected_source_top)}(?:[\"}}\s]|$)",
            text,
        ):
            contract_errors.append(f"source_top_not_in_run={args.expected_source_top}")
    for label, expected in [
        ("gds", args.expected_gds),
        ("source", args.expected_source),
        ("cdl", args.expected_cdl),
    ]:
        if expected is not None and str(expected.resolve()) not in all_patched_text:
            contract_errors.append(f"{label}_not_in_replay={expected.resolve()}")
    if args.mode == "lvs":
        for required, label in [
            (args.expected_source_top, "expected_source_top"),
            (args.expected_source, "expected_source"),
            (args.expected_cdl, "expected_cdl"),
        ]:
            if required is None:
                contract_errors.append(f"missing_argument={label}")
        control_text = control.read_text()
        if args.expected_source is not None and schematic_path_values(
            control_text,
            "verilog",
        ) != [str(args.expected_source.resolve())]:
            contract_errors.append(
                f"source_not_executable_control={args.expected_source.resolve()}"
            )
        if args.expected_cdl is not None and schematic_path_values(
            control_text,
            "spice",
        ) != [str(args.expected_cdl.resolve())]:
            contract_errors.append(
                f"cdl_not_executable_control={args.expected_cdl.resolve()}"
            )
    if args.expected_layout_top is None or args.expected_gds is None:
        contract_errors.append("missing_argument=expected_layout_top_or_gds")
    if contract_errors:
        raise SystemExit("PVS_REPLAY_CONTRACT_FAIL: " + "; ".join(contract_errors))

    run_file.chmod(0o755)
    external_paths = set()
    for path in copied:
        if not is_text(path):
            continue
        reference_text = strip_c_style_comments(path.read_text(errors="ignore"))
        for value in re.findall(r"(?:\"|\{|\s)(/[^\s\"'{};]+)", reference_text):
            if value.startswith("//"):
                continue
            candidate = Path(value)
            if run_dir not in candidate.parents and candidate != run_dir:
                external_paths.add(candidate)
    reference_lines = ["LABEL=SPADMIC_PVS_EXTERNAL_REFERENCES"]
    for candidate in sorted(external_paths):
        if candidate.is_file():
            reference_lines.append(
                f"FILE={candidate}|{candidate.stat().st_size}|{digest(candidate)}"
            )
        elif candidate.is_dir():
            reference_lines.append(f"DIRECTORY={candidate}")
        else:
            reference_lines.append(f"MISSING={candidate}")
    (run_dir / "external_references.rpt").write_text("\n".join(reference_lines) + "\n")
    (run_dir / "template_replacements.rpt").write_text("\n".join(replacement_lines) + "\n")
    (run_dir / "preprocessor_defines.rpt").write_text("\n".join(define_lines) + "\n")
    (run_dir / "output_isolation.rpt").write_text(
        "LABEL=SPADMIC_PVS_OUTPUT_ISOLATION\n"
        "STATUS=PASS\n"
        f"MODE={args.mode.upper()}\n"
        f"RUN_DIR={run_dir}\n"
        f"CONTROL={control}\n"
        + "\n".join(execution_lines + input_lines + output_lines)
        + "\n"
    )
    (run_dir / "replay_contract_status.rpt").write_text(
        "LABEL=SPADMIC_PVS_REPLAY_CONTRACT\n"
        "STATUS=PASS\n"
        f"MODE={args.mode.upper()}\n"
        "EXECUTION_DIRECTORY_STATUS=PASS\n"
        "OUTPUT_ISOLATION_STATUS=PASS\n"
        f"LAYOUT_TOP={args.expected_layout_top}\n"
        f"SOURCE_TOP={args.expected_source_top or 'NOT_APPLICABLE'}\n"
        f"GDS={args.expected_gds.resolve() if args.expected_gds else 'MISSING'}\n"
        f"SOURCE={args.expected_source.resolve() if args.expected_source else 'NOT_APPLICABLE'}\n"
        f"CDL={args.expected_cdl.resolve() if args.expected_cdl else 'NOT_APPLICABLE'}\n"
    )
    print(f"PVS_REPLAY_RUN_DIR={run_dir}")
    print("PVS_REPLAY_PATCH_STATUS=PASS")


if __name__ == "__main__":
    main()
