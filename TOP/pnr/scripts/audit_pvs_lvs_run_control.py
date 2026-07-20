#!/usr/bin/env python3
"""Audit the executable inputs and SVDB path in a patched PVS LVS control."""

from __future__ import annotations

import argparse
import hashlib
import re
from pathlib import Path

from replay_pvs_handoff_template import (
    PVS_VALUE,
    schematic_path_values,
    strip_c_style_comments,
    unquote,
)


def directive_path_values(text: str, directive: str) -> list[str]:
    pattern = re.compile(
        rf"(?im)^[ \t]*{re.escape(directive)}[ \t]+"
        rf"(?P<path>{PVS_VALUE})(?=[ \t;]|$)"
    )
    values: list[str] = []
    for match in pattern.finditer(strip_c_style_comments(text)):
        value = unquote(match.group("path"))
        if len(value) >= 2 and value[0] == "{" and value[-1] == "}":
            value = value[1:-1]
        values.append(value)
    return values


def expected_path(value: Path) -> str:
    return str(value)


def record_exact_single(
    label: str,
    values: list[str],
    expected: str,
    report: list[str],
    errors: list[str],
) -> None:
    report.append(f"{label}_COUNT={len(values)}")
    report.append(f"{label}={'|'.join(values) if values else 'NONE'}")
    report.append(f"EXPECTED_{label}={expected}")
    if values != [expected]:
        errors.append(
            f"{label.lower()}_values={'|'.join(values) if values else 'NONE'}"
        )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--control", required=True, type=Path)
    parser.add_argument("--expected-gds", required=True, type=Path)
    parser.add_argument("--expected-source", required=True, type=Path)
    parser.add_argument("--expected-cdl", required=True, type=Path)
    parser.add_argument("--expected-svdb", required=True, type=Path)
    args = parser.parse_args()

    report = [
        "LABEL=SPADMIC_PVS_LVS_RUN_CONTROL_AUDIT",
        f"CONTROL={args.control.resolve()}",
        "SOURCE_MUTATION_AUTHORIZED=NO",
    ]
    errors: list[str] = []

    try:
        control_bytes = args.control.read_bytes()
        text = control_bytes.decode()
    except (OSError, UnicodeDecodeError) as error:
        report.extend(
            [
                "STATUS=FAIL",
                "CONTROL_SHA256=UNKNOWN",
                "ERROR_COUNT=1",
                f"ERROR=control_read_failed={type(error).__name__}",
            ]
        )
        print("\n".join(report))
        return 1

    report.append(f"CONTROL_SHA256={hashlib.sha256(control_bytes).hexdigest()}")
    executable_text = strip_c_style_comments(text)
    record_exact_single(
        "LAYOUT_PATH",
        directive_path_values(text, "layout_path"),
        expected_path(args.expected_gds),
        report,
        errors,
    )
    record_exact_single(
        "SCHEMATIC_VERILOG_PATH",
        schematic_path_values(executable_text, "verilog"),
        expected_path(args.expected_source),
        report,
        errors,
    )
    record_exact_single(
        "SCHEMATIC_SPICE_PATH",
        schematic_path_values(executable_text, "spice"),
        expected_path(args.expected_cdl),
        report,
        errors,
    )
    record_exact_single(
        "SVDB_DIRECTORY",
        directive_path_values(text, "mask_svdb_dir"),
        expected_path(args.expected_svdb),
        report,
        errors,
    )

    report.insert(1, f"STATUS={'PASS' if not errors else 'FAIL'}")
    report.append(f"ERROR_COUNT={len(errors)}")
    report.extend(f"ERROR={error}" for error in errors)
    print("\n".join(report))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
