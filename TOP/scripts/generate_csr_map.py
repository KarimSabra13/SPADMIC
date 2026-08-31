#!/usr/bin/env python3
"""Generate software and documentation collateral from the SV CSR package."""

from __future__ import annotations

import argparse
import csv
import io
import re
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "TOP/rtl/spadmic_csr_map_pkg.sv"
OUTPUTS = {
    ROOT / "TOP/sw/include/spadmic_csr.h": "c",
    ROOT / "TOP/sw/python/spadmic_csr_map.py": "python",
    ROOT / "TOP/docs/csr/spadmic_csr_map.csv": "csv",
    ROOT / "TOP/docs/csr/spadmic_csr_fields.csv": "fields_csv",
    ROOT / "TOP/docs/csr/CSR_MAP.md": "markdown",
}
RECORD_RE = re.compile(
    r"^\s*// CSR_MAP: (?P<name>[A-Z0-9_]+)\|(?P<address>0x[0-9A-Fa-f]{4})"
    r"\|(?P<access>RO|RW|WO|W1C)\|(?P<reset>0x[0-9A-Fa-f]{8})"
    r"\|(?P<page>[^|]+)\|(?P<description>.+)$"
)
PARAM_RE = re.compile(
    r"^\s*localparam logic \[15:0\] (?P<name>[A-Z0-9_]+) = 16'h(?P<address>[0-9A-Fa-f]{4});$"
)
FIELD_RE = re.compile(
    r"^\s*// CSR_FIELD: (?P<register>[A-Z0-9_]+)\|(?P<name>[A-Z0-9_]+)"
    r"\|(?P<lsb>[0-9]+)\|(?P<width>[0-9]+)\|(?P<access>RO|RW|WO|W1C)"
    r"\|(?P<description>.+)$"
)


@dataclass(frozen=True)
class Register:
    name: str
    address: int
    access: str
    reset: int
    page: str
    description: str


@dataclass(frozen=True)
class Field:
    register: str
    name: str
    lsb: int
    width: int
    access: str
    description: str

    @property
    def mask(self) -> int:
        return ((1 << self.width) - 1) << self.lsb


def parse_source() -> tuple[list[Register], list[Field]]:
    lines = SOURCE.read_text(encoding="ascii").splitlines()
    registers: list[Register] = []
    fields: list[Field] = []
    for index, line in enumerate(lines):
        match = RECORD_RE.match(line)
        if match:
            if index + 1 >= len(lines):
                raise ValueError(f"{SOURCE}:{index + 1}: missing localparam after CSR_MAP")
            param = PARAM_RE.match(lines[index + 1])
            if not param:
                raise ValueError(f"{SOURCE}:{index + 2}: malformed localparam after CSR_MAP")
            if param.group("name") != f"CSR_{match.group('name')}":
                raise ValueError(f"{SOURCE}:{index + 2}: CSR_MAP/localparam name mismatch")
            if param.group("address").upper() != match.group("address")[2:].upper():
                raise ValueError(f"{SOURCE}:{index + 2}: CSR_MAP/localparam address mismatch")
            registers.append(
                Register(
                    name=match.group("name"),
                    address=int(match.group("address"), 16),
                    access=match.group("access"),
                    reset=int(match.group("reset"), 16),
                    page=match.group("page"),
                    description=match.group("description"),
                )
            )
            continue

        field = FIELD_RE.match(line)
        if field:
            fields.append(
                Field(
                    register=field.group("register"),
                    name=field.group("name"),
                    lsb=int(field.group("lsb")),
                    width=int(field.group("width")),
                    access=field.group("access"),
                    description=field.group("description"),
                )
            )

    if not registers:
        raise ValueError(f"no CSR_MAP records found in {SOURCE}")
    names = [register.name for register in registers]
    addresses = [register.address for register in registers]
    if len(names) != len(set(names)):
        raise ValueError("duplicate CSR register name")
    if len(addresses) != len(set(addresses)):
        raise ValueError("duplicate CSR register address")
    for register in registers:
        if register.address & 0x3:
            raise ValueError(f"{register.name}: address is not 32-bit word aligned")
        if (register.address >> 12) > 0x9:
            raise ValueError(f"{register.name}: address is outside implemented pages 0x0-0x9")

    by_name = {register.name: register for register in registers}
    field_keys = [(field.register, field.name) for field in fields]
    if len(field_keys) != len(set(field_keys)):
        raise ValueError("duplicate CSR field name within a register")
    allowed_field_access = {
        "RO": {"RO"},
        "WO": {"WO"},
        "RW": {"RO", "RW", "WO"},
        "W1C": {"RO", "W1C"},
    }
    coverage = {register.name: 0 for register in registers}
    for field in fields:
        if field.register not in by_name:
            raise ValueError(f"{field.register}.{field.name}: unknown register")
        if field.width < 1 or field.lsb < 0 or (field.lsb + field.width) > 32:
            raise ValueError(f"{field.register}.{field.name}: field is outside 32-bit register")
        register = by_name[field.register]
        if field.access not in allowed_field_access[register.access]:
            raise ValueError(
                f"{field.register}.{field.name}: {field.access} field is incompatible "
                f"with {register.access} register"
            )
        if coverage[field.register] & field.mask:
            raise ValueError(f"{field.register}.{field.name}: field overlaps another field")
        coverage[field.register] |= field.mask

    for register in registers:
        if coverage[register.name] == 0:
            raise ValueError(f"{register.name}: register has no CSR_FIELD records")
        if register.reset & ~coverage[register.name]:
            raise ValueError(f"{register.name}: reset value sets a reserved bit")
    return registers, fields


def generated_banner(prefix: str) -> str:
    return (
        f"{prefix} AUTO-GENERATED by TOP/scripts/generate_csr_map.py.\n"
        f"{prefix} Source: TOP/rtl/spadmic_csr_map_pkg.sv\n"
        f"{prefix} Do not edit this file directly.\n"
    )


def render_c(registers: list[Register], fields: list[Field]) -> str:
    lines = [
        generated_banner("//").rstrip(),
        "#ifndef SPADMIC_CSR_H",
        "#define SPADMIC_CSR_H",
        "",
        "#include <stdint.h>",
        "",
        "#define SPADMIC_I2C_ADDRESS UINT8_C(0x42)",
        "#define SPADMIC_CSR_ABI_VERSION_VALUE UINT32_C(0x00010000)",
        "#define SPADMIC_CSR_FIELD_PREP(mask, shift, value) \\",
        "  ((((uint32_t)(value)) << (shift)) & (mask))",
        "#define SPADMIC_CSR_FIELD_GET(mask, shift, value) \\",
        "  ((((uint32_t)(value)) & (mask)) >> (shift))",
        "",
    ]
    for register in registers:
        lines.append(f"#define SPADMIC_CSR_{register.name} UINT16_C(0x{register.address:04X})")
        lines.append(f"#define SPADMIC_CSR_{register.name}_RESET UINT32_C(0x{register.reset:08X})")
        for field in fields:
            if field.register != register.name:
                continue
            prefix = f"SPADMIC_CSR_{register.name}_{field.name}"
            field_reset = (register.reset & field.mask) >> field.lsb
            lines.append(f"#define {prefix}_SHIFT {field.lsb}u")
            lines.append(f"#define {prefix}_WIDTH {field.width}u")
            lines.append(f"#define {prefix}_MASK UINT32_C(0x{field.mask:08X})")
            lines.append(f"#define {prefix}_RESET UINT32_C(0x{field_reset:X})")
    lines.extend(["", "#endif", ""])
    return "\n".join(lines)


def render_python(registers: list[Register], fields: list[Field]) -> str:
    lines = [
        generated_banner("#").rstrip(),
        "from dataclasses import dataclass",
        "",
        "I2C_ADDRESS = 0x42",
        "CSR_ABI_VERSION = 0x00010000",
        "",
        "@dataclass(frozen=True)",
        "class Register:",
        "    address: int",
        "    access: str",
        "    reset: int",
        "    page: str",
        "    description: str",
        "",
        "@dataclass(frozen=True)",
        "class Field:",
        "    lsb: int",
        "    width: int",
        "    access: str",
        "    reset: int",
        "    description: str",
        "",
        "    @property",
        "    def mask(self) -> int:",
        "        return ((1 << self.width) - 1) << self.lsb",
        "",
        "    def prep(self, value: int) -> int:",
        "        if value < 0 or value >= (1 << self.width):",
        "            raise ValueError(f'value {value} does not fit in {self.width} bits')",
        "        return (value << self.lsb) & self.mask",
        "",
        "    def get(self, register_value: int) -> int:",
        "        return (register_value & self.mask) >> self.lsb",
        "",
        "REGISTERS = {",
    ]
    for register in registers:
        lines.append(
            f"    {register.name!r}: Register(0x{register.address:04X}, "
            f"{register.access!r}, 0x{register.reset:08X}, {register.page!r}, "
            f"{register.description!r}),"
        )
    lines.extend(["}", "", "REGISTER_FIELDS = {"])
    for register in registers:
        lines.append(f"    {register.name!r}: {{")
        for field in fields:
            if field.register != register.name:
                continue
            field_reset = (register.reset & field.mask) >> field.lsb
            lines.append(
                f"        {field.name!r}: Field({field.lsb}, {field.width}, {field.access!r}, "
                f"0x{field_reset:X}, {field.description!r}),"
            )
        lines.append("    },")
    lines.extend(
        [
            "}",
            "",
            "BY_ADDRESS = {reg.address: (name, reg) for name, reg in REGISTERS.items()}",
            "",
        ]
    )
    return "\n".join(lines)


def render_csv(registers: list[Register], _fields: list[Field]) -> str:
    stream = io.StringIO(newline="")
    writer = csv.writer(stream, lineterminator="\n")
    writer.writerow(["name", "address", "access", "reset", "page", "description"])
    for register in registers:
        writer.writerow(
            [
                register.name,
                f"0x{register.address:04X}",
                register.access,
                f"0x{register.reset:08X}",
                register.page,
                register.description,
            ]
        )
    return stream.getvalue()


def render_fields_csv(registers: list[Register], fields: list[Field]) -> str:
    stream = io.StringIO(newline="")
    writer = csv.writer(stream, lineterminator="\n")
    writer.writerow(
        ["register", "field", "address", "bits", "lsb", "width", "access", "reset", "description"]
    )
    register_by_name = {register.name: register for register in registers}
    for field in fields:
        register = register_by_name[field.register]
        bits = f"[{field.lsb}]" if field.width == 1 else f"[{field.lsb + field.width - 1}:{field.lsb}]"
        field_reset = (register.reset & field.mask) >> field.lsb
        writer.writerow(
            [
                field.register,
                field.name,
                f"0x{register.address:04X}",
                bits,
                field.lsb,
                field.width,
                field.access,
                f"0x{field_reset:X}",
                field.description,
            ]
        )
    return stream.getvalue()


def render_markdown(registers: list[Register], fields: list[Field]) -> str:
    lines = [
        "<!-- AUTO-GENERATED by TOP/scripts/generate_csr_map.py. -->",
        "<!-- Source: TOP/rtl/spadmic_csr_map_pkg.sv -->",
        "# SPADMIC CSR ABI 1.0",
        "",
        "This is the canonical software-visible register map for `spadmic_top_matrix_v1`.",
        "",
        "## Transport contract",
        "",
        "- Fixed 7-bit I2C address: `0x42`; standard-mode operation is 100 kHz.",
        "- No clock stretching, burst transfer, auto-increment, interrupt, or address straps.",
        "- Register pointers are 16-bit, word-aligned, and transferred most-significant byte first.",
        "- Register data is 32-bit and transferred most-significant byte first.",
        "- Reads support pointer plus repeated START and current-pointer transactions.",
        "- A pointer-only write is valid. A partial 1-3-byte data write is discarded atomically and logged.",
        "- Invalid reads return zero and log an access fault; invalid writes have no side effect and log a fault.",
        "- `i2c_rst_i` resets only I2C transport state. CSR configuration, faults, and counters are preserved.",
        "",
        "## Access policy",
        "",
        "Configuration writes are accepted only while global acquisition is disabled and the system is idle,",
        "except `GLOBAL_CTRL`, which atomically selects the disabled or enabled operating state while idle.",
        "Reserved write bits are ignored and always read as zero. Sticky faults use write-one-to-clear semantics.",
        "Counters saturate at `0xFFFFFFFF`; `MAINT_CMD.CLEAR_ERROR_COUNTERS` clears them only while disabled and idle.",
        "",
    ]
    pages: list[str] = []
    for register in registers:
        if register.page not in pages:
            pages.append(register.page)
    for page in pages:
        lines.extend(
            [
                f"## {page}",
                "",
                "| Register | Address | Access | Reset | Description |",
                "| --- | ---: | :---: | ---: | --- |",
            ]
        )
        for register in registers:
            if register.page == page:
                lines.append(
                    f"| `{register.name}` | `0x{register.address:04X}` | {register.access} | "
                    f"`0x{register.reset:08X}` | {register.description} |"
                )
        lines.append("")
        lines.extend(
            [
                "### Fields",
                "",
                "| Register | Bits | Field | Access | Reset | Description |",
                "| --- | ---: | --- | :---: | ---: | --- |",
            ]
        )
        register_by_name = {register.name: register for register in registers}
        page_registers = {register.name for register in registers if register.page == page}
        for field in fields:
            if field.register not in page_registers:
                continue
            register = register_by_name[field.register]
            bits = f"[{field.lsb}]" if field.width == 1 else f"[{field.lsb + field.width - 1}:{field.lsb}]"
            field_reset = (register.reset & field.mask) >> field.lsb
            lines.append(
                f"| `{field.register}` | `{bits}` | `{field.name}` | {field.access} | "
                f"`0x{field_reset:X}` | {field.description} |"
            )
        lines.append("")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="fail when generated files are stale")
    args = parser.parse_args()
    registers, fields = parse_source()
    renderers = {
        "c": render_c,
        "python": render_python,
        "csv": render_csv,
        "fields_csv": render_fields_csv,
        "markdown": render_markdown,
    }
    stale: list[Path] = []
    for path, kind in OUTPUTS.items():
        content = renderers[kind](registers, fields)
        if args.check:
            if not path.is_file() or path.read_text(encoding="utf-8") != content:
                stale.append(path)
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8")

    if stale:
        for path in stale:
            print(f"STALE={path.relative_to(ROOT)}")
        print("SPADMIC_CSR_MAP_GENERATED_STATUS=FAIL_STALE")
        return 1
    print(f"SPADMIC_CSR_MAP_REGISTER_COUNT={len(registers)}")
    print(f"SPADMIC_CSR_MAP_FIELD_COUNT={len(fields)}")
    print("SPADMIC_CSR_MAP_GENERATED_STATUS=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
