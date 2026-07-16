#!/usr/bin/env python3
"""Prepare a canonical PG-aware Verilog source for PVS LVS.

Innovus ``saveNetlist -includePowerGround`` is the design source. Standard-cell
module definitions are removed only when the official JIHD CDL contains a
same-named ``.SUBCKT``. The top-level Verilog ports must then match the block
LEF pin set exactly before the filtered source is written.
"""

from __future__ import annotations

import argparse
import hashlib
import re
from dataclasses import dataclass
from pathlib import Path


IDENTIFIER_RE = re.compile(r"\\[^\s,();]+|[A-Za-z_$][A-Za-z0-9_$]*")
DECLARATION_RE = re.compile(r"\b(input|output|inout)\b([^;]*);", re.S)
VERILOG_PRIMITIVES = {
    "and", "buf", "bufif0", "bufif1", "cmos", "nand", "nmos", "nor",
    "not", "notif0", "notif1", "or", "pmos", "pullup", "pulldown",
    "rcmos", "rnmos", "rpmos", "rtran", "rtranif0", "rtranif1", "tran",
    "tranif0", "tranif1", "xnor", "xor",
}


@dataclass(frozen=True)
class ModuleBlock:
    name: str
    start: int
    end: int
    text: str
    masked: str


@dataclass(frozen=True)
class DeclaredPort:
    name: str
    direction: str


def digest(path: Path) -> str:
    sha = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            sha.update(chunk)
    return sha.hexdigest()


def require_file(path: Path, label: str) -> Path:
    resolved = path.expanduser().resolve()
    if not resolved.is_file() or resolved.stat().st_size == 0:
        raise ValueError(f"{label} missing or empty: {resolved}")
    return resolved


def mask_comments_and_strings(text: str) -> str:
    result = list(text)
    index = 0
    state = "normal"
    while index < len(text):
        char = text[index]
        next_char = text[index + 1] if index + 1 < len(text) else ""
        if state == "normal":
            if char == "/" and next_char == "/":
                result[index] = result[index + 1] = " "
                index += 2
                state = "line_comment"
                continue
            if char == "/" and next_char == "*":
                result[index] = result[index + 1] = " "
                index += 2
                state = "block_comment"
                continue
            if char == '"':
                result[index] = " "
                index += 1
                state = "string"
                continue
        elif state == "line_comment":
            if char == "\n":
                state = "normal"
            else:
                result[index] = " "
            index += 1
            continue
        elif state == "block_comment":
            if char == "*" and next_char == "/":
                result[index] = result[index + 1] = " "
                index += 2
                state = "normal"
                continue
            if char != "\n":
                result[index] = " "
            index += 1
            continue
        elif state == "string":
            if char == "\\" and next_char:
                result[index] = result[index + 1] = " "
                index += 2
                continue
            if char == '"':
                result[index] = " "
                state = "normal"
            elif char != "\n":
                result[index] = " "
            index += 1
            continue
        index += 1
    if state in {"block_comment", "string"}:
        raise ValueError(f"unterminated Verilog {state}")
    return "".join(result)


def normalize_identifier(value: str) -> str:
    value = value.strip()
    if value.startswith("\\"):
        value = value[1:]
    return value


def parse_modules(text: str) -> list[ModuleBlock]:
    masked = mask_comments_and_strings(text)
    tokens = list(re.finditer(r"\b(module|endmodule)\b", masked))
    modules: list[ModuleBlock] = []
    active: tuple[str, int] | None = None
    for token in tokens:
        if token.group(1) == "module":
            if active is not None:
                raise ValueError("nested module declarations are not supported")
            suffix = masked[token.end():]
            name_match = re.match(
                r"\s+(?:automatic\s+)?(\\[^\s,();]+|[A-Za-z_$][A-Za-z0-9_$]*)",
                suffix,
            )
            if not name_match:
                raise ValueError(f"module name missing near byte {token.start()}")
            active = (normalize_identifier(name_match.group(1)), token.start())
            continue
        if active is None:
            raise ValueError(f"endmodule without module near byte {token.start()}")
        name, start = active
        end = token.end()
        modules.append(ModuleBlock(name, start, end, text[start:end], masked[start:end]))
        active = None
    if active is not None:
        raise ValueError(f"module {active[0]} has no endmodule")
    if not modules:
        raise ValueError("no Verilog module definitions found")
    return modules


def matching_parenthesis(text: str, opening: int) -> int:
    depth = 0
    for index in range(opening, len(text)):
        if text[index] == "(":
            depth += 1
        elif text[index] == ")":
            depth -= 1
            if depth == 0:
                return index
    raise ValueError("unterminated module port list")


def expand_range(name: str, range_text: str | None) -> list[str]:
    if not range_text:
        return [name]
    match = re.fullmatch(r"\[\s*(-?\d+)\s*:\s*(-?\d+)\s*\]", range_text)
    if not match:
        raise ValueError(f"non-constant top-level port range for {name}: {range_text}")
    msb, lsb = int(match.group(1)), int(match.group(2))
    step = -1 if msb >= lsb else 1
    return [f"{name}[{bit}]" for bit in range(msb, lsb + step, step)]


def split_commas(text: str) -> list[str]:
    parts: list[str] = []
    start = 0
    depth = 0
    for index, char in enumerate(text):
        if char in "([{":
            depth += 1
        elif char in ")]}":
            depth -= 1
        elif char == "," and depth == 0:
            parts.append(text[start:index])
            start = index + 1
    parts.append(text[start:])
    return parts


def declaration_port_specs(module: ModuleBlock) -> list[DeclaredPort]:
    module_keyword = re.search(r"\bmodule\b", module.masked)
    if not module_keyword:
        raise ValueError(f"module keyword missing for {module.name}")
    name_match = re.search(
        r"(?:automatic\s+)?(?:\\[^\s,();]+|[A-Za-z_$][A-Za-z0-9_$]*)",
        module.masked[module_keyword.end():],
    )
    if not name_match:
        raise ValueError(f"module name missing for {module.name}")
    cursor = module_keyword.end() + name_match.end()
    while cursor < len(module.masked) and module.masked[cursor].isspace():
        cursor += 1
    if cursor < len(module.masked) and module.masked[cursor] == "#":
        parameter_open = module.masked.find("(", cursor)
        if parameter_open < 0:
            raise ValueError(f"parameter list missing for {module.name}")
        cursor = matching_parenthesis(module.masked, parameter_open) + 1
    port_open = module.masked.find("(", cursor)
    if port_open < 0:
        raise ValueError(f"port list missing for {module.name}")
    port_close = matching_parenthesis(module.masked, port_open)
    header = module.masked[port_open + 1:port_close]

    ports: list[DeclaredPort] = []
    if re.search(r"\b(?:input|output|inout)\b", header):
        inherited_direction: str | None = None
        inherited_range: str | None = None
        for segment in split_commas(header):
            direction_match = re.search(r"\b(input|output|inout)\b", segment)
            if direction_match:
                inherited_direction = direction_match.group(1)
                inherited_range = None
            range_match = re.search(r"\[\s*-?\d+\s*:\s*-?\d+\s*\]", segment)
            if range_match:
                inherited_range = range_match.group(0)
            identifiers = [
                normalize_identifier(match.group(0))
                for match in IDENTIFIER_RE.finditer(segment)
                if normalize_identifier(match.group(0))
                not in {"input", "output", "inout", "wire", "reg", "logic", "signed", "unsigned"}
            ]
            if identifiers:
                if inherited_direction is None:
                    raise ValueError(
                        f"ANSI top-level port direction missing for {identifiers[-1]} "
                        f"in {module.name}"
                    )
                ports.extend(
                    DeclaredPort(name, inherited_direction)
                    for name in expand_range(identifiers[-1], inherited_range)
                )
    else:
        body = module.masked[port_close + 1:]
        for declaration in DECLARATION_RE.finditer(body):
            direction = declaration.group(1)
            payload = declaration.group(2)
            range_match = re.search(r"\[\s*-?\d+\s*:\s*-?\d+\s*\]", payload)
            range_text = range_match.group(0) if range_match else None
            if range_match:
                payload = payload[:range_match.start()] + " " + payload[range_match.end():]
            for segment in split_commas(payload):
                identifiers = [
                    normalize_identifier(match.group(0))
                    for match in IDENTIFIER_RE.finditer(segment)
                    if normalize_identifier(match.group(0))
                    not in {"wire", "reg", "logic", "signed", "unsigned", "supply0", "supply1"}
                ]
                if identifiers:
                    ports.extend(
                        DeclaredPort(name, direction)
                        for name in expand_range(identifiers[-1], range_text)
                    )

    if not ports:
        raise ValueError(f"no top-level ports parsed for {module.name}")
    port_names = [port.name for port in ports]
    duplicates = sorted({name for name in port_names if port_names.count(name) > 1})
    if duplicates:
        raise ValueError(f"duplicate top-level ports for {module.name}: {duplicates}")
    return ports


def declaration_ports(module: ModuleBlock) -> list[str]:
    return [port.name for port in declaration_port_specs(module)]


def cdl_subcircuits(path: Path) -> set[str]:
    names = set()
    for line in path.read_text(errors="replace").splitlines():
        match = re.match(r"\s*\.subckt\s+(\S+)", line, re.I)
        if match:
            names.add(match.group(1))
    if not names:
        raise ValueError(f"no .SUBCKT definitions found in CDL: {path}")
    return names


def referenced_masters(module: ModuleBlock) -> set[str]:
    masters: set[str] = set()
    for raw_statement in module.masked.split(";"):
        statement = re.sub(r"^\s*\(\*.*?\*\)\s*", "", raw_statement, flags=re.S)
        match = re.match(
            r"\s*(\\[^\s,();]+|[A-Za-z_$][A-Za-z0-9_$]*)\s+"
            r"(?:#\s*\(.*\)\s*)?"
            r"(\\[^\s,();]+|[A-Za-z_$][A-Za-z0-9_$]*)"
            r"(?:\s*\[[^\]]+\])?\s*\(",
            statement,
            re.S,
        )
        if not match:
            continue
        master = normalize_identifier(match.group(1))
        if master not in {
            "module", "input", "output", "inout", "wire", "tri", "reg",
            "logic", "assign", "always", "initial", "if", "for", "case",
            "function", "task",
        }:
            masters.add(master)
    return masters


def lef_pins(path: Path, source_top: str) -> set[str] | None:
    text = path.read_text(errors="replace")
    macro = re.search(r"^\s*MACRO\s+(\S+)", text, re.M)
    if not macro or macro.group(1) != source_top:
        return None
    return set(re.findall(r"^\s*PIN\s+(\S+)", text, re.M))


def prepare_lvs_source(
    *,
    input_netlist: Path,
    output_netlist: Path,
    source_top: str,
    stdcell_cdl: Path,
    lefs: list[Path],
    status_path: Path,
) -> dict[str, str | int]:
    source = require_file(input_netlist, "Innovus PG netlist")
    cdl = require_file(stdcell_cdl, "standard-cell CDL")
    lef_paths = [require_file(path, "block LEF") for path in lefs]
    status_path.parent.mkdir(parents=True, exist_ok=True)
    errors: list[str] = []
    details: dict[str, str | int] = {}
    try:
        source_text = source.read_text(errors="strict")
        modules = parse_modules(source_text)
        cell_names = cdl_subcircuits(cdl)
        cell_names_folded = {name.upper() for name in cell_names}
        top_modules = [module for module in modules if module.name == source_top]
        if len(top_modules) != 1:
            raise ValueError(f"source top definition count is {len(top_modules)}, expected 1: {source_top}")
        if source_top.upper() in cell_names_folded:
            raise ValueError(f"source top collides with a CDL .SUBCKT: {source_top}")

        ports = declaration_ports(top_modules[0])
        port_set = set(ports)
        for supply in ("VDD", "VSS"):
            if supply not in port_set:
                errors.append(f"missing_supply_port={supply}")
        nested_ports = sorted(port for port in port_set if "][" in port)
        if nested_ports:
            errors.append("nested_top_ports=" + ",".join(nested_ports))

        matching_lefs = [pins for path in lef_paths if (pins := lef_pins(path, source_top)) is not None]
        if len(matching_lefs) != 1:
            errors.append(f"matching_lef_macro_count={len(matching_lefs)} expected=1")
            lef_pin_set: set[str] = set()
        else:
            lef_pin_set = matching_lefs[0]
            missing_in_lef = sorted(port_set - lef_pin_set)
            missing_in_source = sorted(lef_pin_set - port_set)
            if missing_in_lef:
                errors.append("ports_missing_in_lef=" + ",".join(missing_in_lef))
            if missing_in_source:
                errors.append("pins_missing_in_source=" + ",".join(missing_in_source))

        removed = [module for module in modules if module.name.upper() in cell_names_folded]
        retained = [module for module in modules if module.name.upper() not in cell_names_folded]
        retained_cell_overlap = sorted(
            module.name for module in retained if module.name.upper() in cell_names_folded
        )
        if retained_cell_overlap:
            errors.append("retained_cdl_module_overlap=" + ",".join(retained_cell_overlap))
        retained_module_names = {module.name.upper() for module in retained}
        referenced = sorted({master for module in retained for master in referenced_masters(module)})
        unresolved = sorted(
            master
            for master in referenced
            if master.upper() not in retained_module_names
            and master.upper() not in cell_names_folded
            and master.lower() not in VERILOG_PRIMITIVES
        )
        if unresolved:
            errors.append("unresolved_master_not_in_source_or_cdl=" + ",".join(unresolved))

        details.update(
            INPUT_MODULE_COUNT=len(modules),
            RETAINED_MODULE_COUNT=len(retained),
            REMOVED_STDCELL_MODULE_COUNT=len(removed),
            REMOVED_STDCELL_MODULES=",".join(sorted(module.name for module in removed)),
            SOURCE_TOP_PORT_COUNT=len(port_set),
            LEF_PIN_COUNT=len(lef_pin_set),
            NESTED_TOP_PORT_COUNT=len(nested_ports),
            REFERENCED_MASTER_COUNT=len(referenced),
            CDL_RESOLVED_MASTER_COUNT=sum(master.upper() in cell_names_folded for master in referenced),
            DESIGN_RESOLVED_MASTER_COUNT=sum(master.upper() in retained_module_names for master in referenced),
            UNRESOLVED_MASTER_COUNT=len(unresolved),
            UNRESOLVED_MASTERS=",".join(unresolved),
        )
        if errors:
            raise ValueError("; ".join(errors))

        cursor = 0
        output_parts = [
            "// SPADMIC canonical PVS LVS source.\n",
            f"// Source top: {source_top}\n",
            f"// JIHD definitions removed by CDL membership: {len(removed)}\n\n",
        ]
        for module in modules:
            output_parts.append(source_text[cursor:module.start])
            if module.name.upper() in cell_names_folded:
                output_parts.append(f"\n// Removed JIHD definition: {module.name}; use official CDL.\n")
            else:
                output_parts.append(source_text[module.start:module.end])
            cursor = module.end
        output_parts.append(source_text[cursor:])
        output_text = "".join(output_parts)
        output_netlist.parent.mkdir(parents=True, exist_ok=True)
        output_netlist.write_text(output_text)
        details["OUTPUT_SHA256"] = digest(output_netlist)
    except (OSError, UnicodeError, ValueError) as exc:
        if output_netlist.exists():
            output_netlist.unlink()
        if not errors:
            errors.append(str(exc))

    status = "FAIL" if errors else "PASS"
    lines = [
        "LABEL=SPADMIC_PVS_LVS_SOURCE_PREPARATION",
        f"STATUS={status}",
        f"SOURCE_TOP={source_top}",
        f"INPUT_NETLIST={source}",
        f"INPUT_SHA256={digest(source)}",
        f"OUTPUT_NETLIST={output_netlist.resolve()}",
        f"STDCELL_CDL={cdl}",
        f"STDCELL_CDL_SHA256={digest(cdl)}",
        f"LEF_FILES={','.join(str(path) for path in lef_paths)}",
        "PIN_PARITY_STATUS=" + ("FAIL" if any("missing" in error or "matching_lef" in error for error in errors) else "PASS"),
    ]
    lines.extend(f"{key}={value}" for key, value in details.items())
    lines.append(f"ERROR_COUNT={len(errors)}")
    lines.extend(f"ERROR={error}" for error in errors)
    status_path.write_text("\n".join(lines) + "\n")
    if errors:
        raise ValueError("PVS LVS source preparation failed: " + "; ".join(errors))
    return details


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--source-top", required=True)
    parser.add_argument("--stdcell-cdl", required=True, type=Path)
    parser.add_argument("--lef", required=True, action="append", type=Path)
    parser.add_argument("--status", required=True, type=Path)
    args = parser.parse_args()
    try:
        prepare_lvs_source(
            input_netlist=args.input,
            output_netlist=args.output,
            source_top=args.source_top,
            stdcell_cdl=args.stdcell_cdl,
            lefs=args.lef,
            status_path=args.status,
        )
    except ValueError as exc:
        print(exc)
        raise SystemExit(8) from exc
    print(f"PVS_LVS_SOURCE={args.output.resolve()}")
    print(f"PVS_LVS_SOURCE_STATUS={args.status.resolve()}")
    print("PVS_LVS_SOURCE_PREPARATION=PASS")


if __name__ == "__main__":
    main()
