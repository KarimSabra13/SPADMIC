#!/usr/bin/env python3
"""Generate the scalar 4x16 TX source-data boundary contract.

The active matrix TX path uses scalar external ports so Verilog, LEF, DEF,
GDS, and PVS share unambiguous terminal names. Modules may reconstruct the
original 4x16 array internally. Generated regions stay explicit in the RTL so
all supported tools see ordinary SystemVerilog without include-path coupling.
"""

from __future__ import annotations

import argparse
import csv
import re
import sys
from dataclasses import dataclass
from pathlib import Path


SOURCE_COUNT = 4
DATA_WIDTH = 16
BEGIN_RE = re.compile(
    r"^(?P<indent>[ \t]*)// SPADMIC_TX_SRC_DATA_GENERATED_BEGIN "
    r"(?P<kind>[A-Z_]+)(?: (?P<arg>[A-Za-z_][A-Za-z0-9_$]*))?\s*$"
)
END_TEMPLATE = "// SPADMIC_TX_SRC_DATA_GENERATED_END {kind}"
SCAN_ROOTS = (
    Path("TOP/rtl"),
    Path("TOP/tb"),
    Path("TOP/pnr/assembly"),
)


@dataclass(frozen=True)
class Pin:
    source: int
    bit: int
    name: str


def read_manifest(path: Path) -> list[Pin]:
    with path.open(newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))

    pins: list[Pin] = []
    errors: list[str] = []
    for line_number, row in enumerate(rows, start=2):
        try:
            source = int(row["source"])
            bit = int(row["bit"])
            name = row["name"].strip()
        except (KeyError, TypeError, ValueError) as exc:
            errors.append(f"line {line_number}: malformed row: {exc}")
            continue
        expected_name = f"src_data_i_s{source}_b{bit}"
        if name != expected_name:
            errors.append(
                f"line {line_number}: name {name!r} != canonical {expected_name!r}"
            )
        pins.append(Pin(source, bit, name))

    expected_pairs = {
        (source, bit)
        for source in range(SOURCE_COUNT)
        for bit in range(DATA_WIDTH)
    }
    actual_pairs = {(pin.source, pin.bit) for pin in pins}
    names = [pin.name for pin in pins]
    if len(pins) != SOURCE_COUNT * DATA_WIDTH:
        errors.append(f"pin count {len(pins)} != {SOURCE_COUNT * DATA_WIDTH}")
    if actual_pairs != expected_pairs:
        errors.append(
            f"index coverage mismatch: missing={sorted(expected_pairs - actual_pairs)} "
            f"extra={sorted(actual_pairs - expected_pairs)}"
        )
    if len(names) != len(set(names)):
        errors.append("pin names are not unique")
    if errors:
        raise ValueError("invalid TX source-data manifest:\n" + "\n".join(errors))
    return sorted(pins, key=lambda pin: (pin.source, pin.bit))


def render(kind: str, arg: str | None, indent: str, pins: list[Pin]) -> list[str]:
    if kind == "PORT_DECLS":
        return [f"{indent}input wire logic {pin.name}," for pin in pins]
    if kind == "PASS_CONNECTIONS":
        return [f"{indent}.{pin.name:<21} ({pin.name})," for pin in pins]
    if kind == "ARRAY_CONNECTIONS":
        if not arg:
            raise ValueError("ARRAY_CONNECTIONS marker requires an array name")
        return [
            f"{indent}.{pin.name:<21} ({arg}[{pin.source}][{pin.bit}]),"
            for pin in pins
        ]
    if kind == "ARRAY_ASSIGNMENTS":
        if not arg:
            raise ValueError("ARRAY_ASSIGNMENTS marker requires an array name")
        return [
            f"{indent}assign {arg}[{pin.source}][{pin.bit}] = {pin.name};"
            for pin in pins
        ]
    if kind == "FLAT_CONNECTIONS":
        if not arg:
            raise ValueError("FLAT_CONNECTIONS marker requires a packed vector name")
        return [
            f"{indent}.{pin.name:<21} ({arg}[{pin.source * DATA_WIDTH + pin.bit}]),"
            for pin in pins
        ]
    if kind == "FLAT_ASSIGNMENTS":
        if not arg:
            raise ValueError("FLAT_ASSIGNMENTS marker requires a packed vector name")
        return [
            f"{indent}assign {arg}[{pin.source * DATA_WIDTH + pin.bit}] = {pin.name};"
            for pin in pins
        ]
    raise ValueError(f"unsupported generated-region kind: {kind}")


def transform(text: str, pins: list[Pin], path: Path) -> tuple[str, int]:
    lines = text.splitlines()
    output: list[str] = []
    index = 0
    region_count = 0
    while index < len(lines):
        line = lines[index]
        match = BEGIN_RE.match(line)
        if not match:
            output.append(line)
            index += 1
            continue

        kind = match.group("kind")
        arg = match.group("arg")
        indent = match.group("indent")
        output.append(line)
        output.extend(render(kind, arg, indent, pins))
        expected_end = indent + END_TEMPLATE.format(kind=kind)
        index += 1
        while index < len(lines) and lines[index] != expected_end:
            index += 1
        if index >= len(lines):
            raise ValueError(f"{path}: missing marker {expected_end!r}")
        output.append(lines[index])
        index += 1
        region_count += 1

    suffix = "\n" if text.endswith("\n") else ""
    return "\n".join(output) + suffix, region_count


def candidate_files(repo_root: Path) -> list[Path]:
    paths: list[Path] = []
    for relative_root in SCAN_ROOTS:
        root = repo_root / relative_root
        if root.is_dir():
            paths.extend(root.rglob("*.sv"))
    return sorted(paths)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    parser.add_argument(
        "--manifest",
        type=Path,
        default=Path("TOP/rtl/interfaces/tx_src_data_flat.csv"),
    )
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--write", action="store_true", help="update generated regions")
    mode.add_argument("--check", action="store_true", help="fail if regions are stale")
    args = parser.parse_args()

    repo_root = args.repo_root.resolve()
    manifest = args.manifest
    if not manifest.is_absolute():
        manifest = repo_root / manifest
    pins = read_manifest(manifest)

    stale: list[Path] = []
    touched: list[Path] = []
    region_count = 0
    for path in candidate_files(repo_root):
        original = path.read_text(encoding="utf-8")
        generated, count = transform(original, pins, path)
        if count == 0:
            continue
        region_count += count
        touched.append(path)
        if generated != original:
            stale.append(path)
            if args.write or not args.check:
                path.write_text(generated, encoding="utf-8")

    if region_count == 0:
        print("ERROR: no TX source-data generated regions found", file=sys.stderr)
        return 2
    print(f"TX_SRC_DATA_PIN_COUNT={len(pins)}")
    print(f"TX_SRC_DATA_GENERATED_FILE_COUNT={len(touched)}")
    print(f"TX_SRC_DATA_GENERATED_REGION_COUNT={region_count}")
    if args.check and stale:
        for path in stale:
            print(f"STALE={path.relative_to(repo_root)}")
        print("TX_SRC_DATA_GENERATED_STATUS=FAIL_STALE")
        return 1
    print("TX_SRC_DATA_GENERATED_STATUS=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
