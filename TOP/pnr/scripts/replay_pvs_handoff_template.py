#!/usr/bin/env python3
"""Clone the executable part of a GUI PVS run and patch explicit values."""

from __future__ import annotations

import argparse
import hashlib
import re
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
    # Apply specific artifact replacements before relocating the template root;
    # otherwise an OLD path under the template is rewritten to run_dir first and
    # can no longer match its canonical GDS/source/CDL replacement.
    replacements.append((str(template), str(run_dir)))

    original_text = {
        path: path.read_text(errors="ignore")
        for path in copied
        if is_text(path)
    }
    replacement_lines = ["LABEL=SPADMIC_PVS_TEMPLATE_REPLACEMENTS"]
    for old, new in explicit_replacements:
        count = sum(text.count(old) for text in original_text.values())
        replacement_lines.append(f"OLD={old}|NEW={new}|OCCURRENCES={count}")
        if old != new and count == 0:
            raise SystemExit(f"REPLACEMENT_SOURCE_NOT_FOUND: {old}")

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

    run_file = run_dir / "run.pvs"
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
    (run_dir / "replay_contract_status.rpt").write_text(
        "LABEL=SPADMIC_PVS_REPLAY_CONTRACT\n"
        "STATUS=PASS\n"
        f"MODE={args.mode.upper()}\n"
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
