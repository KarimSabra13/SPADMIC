#!/usr/bin/env python3
"""Build an attributable physical Verilog source for MPTDC PVS LVS.

The input must be the Innovus ``saveNetlist -phys -includePowerGround`` output.
Foundry module definitions are removed only when the exact module name exists
as a canonical CDL ``.SUBCKT``. Physical instances remain in the top module.
The two RO_tune6 instances and wrapper are rewritten to scalar angle-bracket
pins so PVS compares the same logical pin index on layout and schematic.
"""

from __future__ import annotations

import argparse
import hashlib
import re
from collections import Counter
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Sequence


IDENT = r"(?:\\[^\s]+|[A-Za-z_][A-Za-z0-9_$]*)"
MODULE_START_RE = re.compile(rf"^\s*module\s+({IDENT})", re.MULTILINE)
MODULE_END_RE = re.compile(r"^\s*endmodule\b.*$", re.MULTILINE)
CDL_SUBCKT_RE = re.compile(r"^\s*\.subckt\s+(\S+)", re.IGNORECASE)
RO_PIN_RE = re.compile(r"^(S|code)(?:\[([0-7])\]|<([0-7])>)$")
INSTANCE_LINE_RE = re.compile(
    rf"^\s*({IDENT})\s+(?:#\s*\([^;]*?\)\s*)?({IDENT})\s*\(", re.MULTILINE
)

INSTANCE_KEYWORDS = {
    "always", "and", "assign", "buf", "case", "deassign", "force", "for",
    "forever", "function", "if", "initial", "inout", "input", "module",
    "nand", "nor", "not", "or", "output", "primitive", "pullup", "pulldown",
    "reg", "release", "repeat", "task", "tran", "tri", "wait", "wand",
    "wire", "wor", "xnor", "xor",
}


@dataclass(frozen=True)
class ModuleBlock:
    name: str
    start: int
    end: int
    text: str


def unescape_identifier(value: str) -> str:
    value = value.strip()
    return value[1:] if value.startswith("\\") else value


def module_blocks(text: str) -> list[ModuleBlock]:
    blocks: list[ModuleBlock] = []
    masked = mask_comments(text)
    cursor = 0
    while True:
        match = MODULE_START_RE.search(masked, cursor)
        if match is None:
            break
        end_match = MODULE_END_RE.search(masked, match.end())
        if end_match is None:
            raise ValueError(f"module {match.group(1)} has no endmodule")
        end = end_match.end()
        blocks.append(
            ModuleBlock(
                name=unescape_identifier(match.group(1)),
                start=match.start(),
                end=end,
                text=text[match.start() : end],
            )
        )
        cursor = end
    return blocks


def read_cdl_subckts(paths: Sequence[Path]) -> set[str]:
    names: set[str] = set()
    for path in paths:
        if not path.is_file():
            raise ValueError(f"canonical CDL does not exist: {path}")
        for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
            match = CDL_SUBCKT_RE.match(line)
            if match:
                names.add(match.group(1))
    if not names:
        raise ValueError("canonical CDL set contains no .SUBCKT definitions")
    return names


def remove_cdl_module_definitions(
    text: str, cdl_names: set[str]
) -> tuple[str, list[str], list[ModuleBlock]]:
    blocks = module_blocks(text)
    chunks: list[str] = []
    removed: list[str] = []
    cursor = 0
    for block in blocks:
        chunks.append(text[cursor : block.start])
        if block.name == "RO_tune6" or block.name in cdl_names:
            removed.append(block.name)
        else:
            chunks.append(block.text)
        cursor = block.end
    chunks.append(text[cursor:])
    return "".join(chunks), removed, blocks


def mask_comments(text: str) -> str:
    chars = list(text)
    index = 0
    while index < len(chars):
        if text.startswith("//", index):
            end = text.find("\n", index)
            end = len(text) if end < 0 else end
            for pos in range(index, end):
                chars[pos] = " "
            index = end
        elif text.startswith("/*", index):
            end = text.find("*/", index + 2)
            if end < 0:
                raise ValueError("unterminated block comment")
            for pos in range(index, end + 2):
                if chars[pos] != "\n":
                    chars[pos] = " "
            index = end + 2
        else:
            index += 1
    return "".join(chars)


def find_matching_paren(masked: str, start: int) -> int:
    if start >= len(masked) or masked[start] != "(":
        raise ValueError("internal parser error: expected opening parenthesis")
    depth = 0
    for index in range(start, len(masked)):
        char = masked[index]
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth == 0:
                return index
    raise ValueError("unterminated parenthesized expression")


def skip_space(masked: str, index: int) -> int:
    while index < len(masked) and masked[index].isspace():
        index += 1
    return index


def read_identifier(masked: str, index: int) -> tuple[str, int]:
    index = skip_space(masked, index)
    if index >= len(masked):
        raise ValueError("expected identifier at end of input")
    if masked[index] == "\\":
        end = index + 1
        while end < len(masked) and not masked[end].isspace():
            end += 1
        if end == index + 1:
            raise ValueError("empty escaped identifier")
        return masked[index:end], end
    match = re.match(r"[A-Za-z_][A-Za-z0-9_$]*", masked[index:])
    if match is None:
        raise ValueError(f"expected identifier near offset {index}")
    return match.group(0), index + match.end()


def split_top_level(text: str, delimiter: str = ",") -> list[str]:
    parts: list[str] = []
    start = 0
    paren = bracket = brace = 0
    for index, char in enumerate(text):
        if char == "(":
            paren += 1
        elif char == ")":
            paren -= 1
        elif char == "[":
            bracket += 1
        elif char == "]":
            bracket -= 1
        elif char == "{":
            brace += 1
        elif char == "}":
            brace -= 1
        elif char == delimiter and paren == bracket == brace == 0:
            parts.append(text[start:index].strip())
            start = index + 1
        if min(paren, bracket, brace) < 0:
            raise ValueError("unbalanced connection expression")
    if paren or bracket or brace:
        raise ValueError("unbalanced connection expression")
    parts.append(text[start:].strip())
    return [part for part in parts if part]


def parse_named_connections(body: str) -> dict[str, str]:
    result: dict[str, str] = {}
    for item in split_top_level(body):
        if not item.startswith("."):
            raise ValueError("RO_tune6 positional connections are not accepted")
        match = re.match(
            rf"^\.\s*({IDENT}(?:\[[^\]]+\]|<[0-7]>)?)\s*\((.*)\)\s*$",
            item,
            re.DOTALL,
        )
        if match is None:
            raise ValueError(f"cannot parse RO_tune6 named connection: {item}")
        port = unescape_identifier(match.group(1))
        if port in result:
            raise ValueError(f"duplicate RO_tune6 port connection: {port}")
        result[port] = match.group(2).strip()
    return result


def expand_vector_expression(expression: str, label: str) -> dict[int, str]:
    expression = expression.strip()
    if expression.startswith("{") and expression.endswith("}"):
        items = split_top_level(expression[1:-1])
        if len(items) != 8:
            raise ValueError(f"{label} concatenation width is {len(items)}, expected 8")
        return {bit: items[7 - bit] for bit in range(8)}

    part_select = re.fullmatch(r"(.+?)\[([0-7]):([0-7])\]", expression)
    if part_select:
        base = part_select.group(1).strip()
        left = int(part_select.group(2))
        right = int(part_select.group(3))
        step = -1 if left > right else 1
        indices = list(range(left, right + step, step))
        if len(indices) != 8:
            raise ValueError(f"{label} part select is not eight bits: {expression}")
        return {
            7 - position: f"{base}[{source_bit}]"
            for position, source_bit in enumerate(indices)
        }

    if re.fullmatch(rf"{IDENT}", expression):
        return {bit: f"{expression}[{bit}]" for bit in range(8)}
    raise ValueError(
        f"{label} must be an eight-item concatenation, vector identifier, or part select: {expression}"
    )


def scalarize_ro_connections(connections: dict[str, str]) -> dict[str, str]:
    scalars: dict[str, str] = {}
    for scalar in ("VDD", "VSS", "rstb"):
        if scalar not in connections:
            raise ValueError(f"RO_tune6 instance is missing {scalar}")
        scalars[scalar] = connections[scalar]

    for bus in ("code", "S"):
        bits: dict[int, str] = {}
        if bus in connections:
            bits.update(expand_vector_expression(connections[bus], bus))
        for port, expression in connections.items():
            match = RO_PIN_RE.fullmatch(port)
            if match is None or match.group(1) != bus:
                continue
            bit = int(match.group(2) or match.group(3))
            if bit in bits:
                raise ValueError(f"RO_tune6 {bus}[{bit}] is connected more than once")
            bits[bit] = expression
        missing = sorted(set(range(8)) - set(bits))
        if missing:
            raise ValueError(f"RO_tune6 {bus} scalarization is missing bits: {missing}")
        for bit in range(8):
            scalars[f"{bus}<{bit}>"] = bits[bit]

    allowed = {"VDD", "VSS", "rstb", "code", "S"}
    allowed.update(f"{bus}[{bit}]" for bus in ("code", "S") for bit in range(8))
    allowed.update(f"{bus}<{bit}>" for bus in ("code", "S") for bit in range(8))
    unexpected = sorted(set(connections) - allowed)
    if unexpected:
        raise ValueError(f"RO_tune6 instance has unexpected ports: {unexpected}")
    return scalars


def format_ro_instance(instance_name: str, connections: dict[str, str]) -> str:
    scalars = scalarize_ro_connections(connections)
    order = ["VDD", "VSS", "rstb"]
    order.extend(f"code<{bit}>" for bit in range(8))
    order.extend(f"S<{bit}>" for bit in range(8))
    lines = [f"RO_tune6 {instance_name} ("]
    for index, port in enumerate(order):
        comma = "," if index != len(order) - 1 else ""
        escaped = port if port in {"VDD", "VSS", "rstb"} else f"\\{port} "
        lines.append(f"  .{escaped}({scalars[port]}){comma}")
    lines.append(");")
    return "\n".join(lines)


def rewrite_ro_instances(text: str) -> tuple[str, list[str]]:
    masked = mask_comments(text)
    master_re = re.compile(r"\bRO_tune6\b")
    replacements: list[tuple[int, int, str]] = []
    instance_names: list[str] = []
    cursor = 0
    while True:
        match = master_re.search(masked, cursor)
        if match is None:
            break
        index = skip_space(masked, match.end())
        if index < len(masked) and masked[index] == "#":
            index = skip_space(masked, index + 1)
            if index >= len(masked) or masked[index] != "(":
                raise ValueError("malformed RO_tune6 parameter override")
            index = skip_space(masked, find_matching_paren(masked, index) + 1)
        raw_instance, index = read_identifier(masked, index)
        instance_name = raw_instance.strip()
        index = skip_space(masked, index)
        if index >= len(masked) or masked[index] != "(":
            raise ValueError(f"RO_tune6 {instance_name} has no connection list")
        close = find_matching_paren(masked, index)
        end = skip_space(masked, close + 1)
        if end >= len(masked) or masked[end] != ";":
            raise ValueError(f"RO_tune6 {instance_name} is not a single-instance statement")
        body = text[index + 1 : close]
        replacement = format_ro_instance(instance_name, parse_named_connections(body))
        replacements.append((match.start(), end + 1, replacement))
        instance_names.append(unescape_identifier(instance_name))
        cursor = end + 1

    for start, end, replacement in reversed(replacements):
        text = text[:start] + replacement + text[end:]
    return text, instance_names


def ro_wrapper() -> str:
    ports = ["VDD", "VSS", "rstb"]
    ports.extend(f"\\code<{bit}> " for bit in range(8))
    ports.extend(f"\\S<{bit}> " for bit in range(8))
    lines = [
        "",
        f"module RO_tune6 ({', '.join(ports)});",
        "  inout VDD;",
        "  inout VSS;",
        "  inout rstb;",
    ]
    lines.extend(f"  inout \\code<{bit}> ;" for bit in range(8))
    lines.extend(f"  inout \\S<{bit}> ;" for bit in range(8))
    lines.extend(["endmodule", ""])
    return "\n".join(lines)


def find_top_block(text: str, top: str) -> ModuleBlock:
    matches = [block for block in module_blocks(text) if block.name == top]
    if len(matches) != 1:
        raise ValueError(f"expected exactly one {top} module, found {len(matches)}")
    return matches[0]


def instance_masters(module_text: str) -> Counter[str]:
    masked = mask_comments(module_text)
    counts: Counter[str] = Counter()
    for match in INSTANCE_LINE_RE.finditer(masked):
        master = unescape_identifier(match.group(1))
        if master.lower() not in INSTANCE_KEYWORDS:
            counts[master] += 1
    return counts


def normalize_blank_lines(text: str) -> str:
    return re.sub(r"\n{4,}", "\n\n\n", text).rstrip() + "\n"


def write_lines(path: Path, lines: Iterable[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path, help="Innovus physical PG Verilog")
    parser.add_argument("--output", required=True, type=Path, help="Attributable Verilog output")
    parser.add_argument("--hcell", required=True, type=Path, help="PVS HCell output")
    parser.add_argument("--report", required=True, type=Path, help="Source-contract report")
    parser.add_argument("--cdl", required=True, action="append", type=Path, help="Canonical CDL; repeatable")
    parser.add_argument("--top", default="mptdc_axis_core")
    parser.add_argument("--expected-ro-instance-count", type=int, default=2)
    parser.add_argument(
        "--expected-ro-instance",
        action="append",
        default=[],
        help="Required RO_tune6 instance name; repeatable",
    )
    args = parser.parse_args()

    try:
        if not args.input.is_file():
            raise ValueError(f"physical input netlist does not exist: {args.input}")
        if "phys_with_pg" not in args.input.name:
            raise ValueError("input filename must identify saveNetlist -phys -includePowerGround")
        source = args.input.read_text(encoding="utf-8", errors="replace")
        cdl_names = read_cdl_subckts(args.cdl)
        filtered, removed, original_blocks = remove_cdl_module_definitions(source, cdl_names)
        filtered, ro_instances = rewrite_ro_instances(filtered)
        if len(ro_instances) != args.expected_ro_instance_count:
            raise ValueError(
                f"expected {args.expected_ro_instance_count} RO_tune6 instances, found {len(ro_instances)}"
            )
        instance_name_status = "NOT_ENFORCED"
        if len(args.expected_ro_instance) != len(set(args.expected_ro_instance)):
            raise ValueError("expected RO_tune6 instance-name list contains duplicates")
        if args.expected_ro_instance and set(ro_instances) != set(args.expected_ro_instance):
            raise ValueError(
                "RO_tune6 instance-name contract mismatch: "
                f"expected={sorted(args.expected_ro_instance)} actual={sorted(ro_instances)}"
            )
        if args.expected_ro_instance:
            instance_name_status = "PASS"
        filtered = normalize_blank_lines(filtered) + ro_wrapper()

        retained_modules = {block.name for block in module_blocks(filtered)}
        top_block = find_top_block(filtered, args.top)
        masters = instance_masters(top_block.text)
        unresolved = sorted(set(masters) - retained_modules - cdl_names)
        if unresolved:
            raise ValueError(f"active instance masters lack Verilog or canonical CDL definitions: {unresolved}")

        original_top = find_top_block(source, args.top)
        original_masters = instance_masters(original_top.text)
        tie_master_names = sorted(name for name in original_masters if "TIE" in name.upper())
        for name in tie_master_names:
            if masters[name] != original_masters[name]:
                raise ValueError(f"physical tie instances were not preserved for {name}")
            if name not in cdl_names:
                raise ValueError(f"physical tie master is absent from canonical CDL: {name}")

        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(filtered, encoding="utf-8")
        write_lines(args.hcell, ["RO_tune6 RO_tune6"])

        report_lines = [
            "# MPTDC Physical PVS LVS Source Contract",
            "LVS_SOURCE_CONTRACT_STATUS=PASS",
            "SOURCE_KIND=INNOVUS_SAVE_NETLIST_PHYS_INCLUDE_POWER_GROUND",
            f"INPUT={args.input}",
            f"INPUT_SHA256={sha256(args.input)}",
            f"OUTPUT={args.output}",
            f"OUTPUT_SHA256={sha256(args.output)}",
            f"HCELL={args.hcell}",
            f"TOP={args.top}",
            "MODULE_REMOVAL_POLICY=EXACT_CANONICAL_CDL_MEMBERSHIP",
            "RO6_PIN_NORMALIZATION=EXACT_SAME_INDEX_SCALAR_ANGLE_PORTS",
            f"CANONICAL_CDL_COUNT={len(args.cdl)}",
            f"CANONICAL_SUBCKT_COUNT={len(cdl_names)}",
            f"INPUT_MODULE_COUNT={len(original_blocks)}",
            f"REMOVED_MODULE_COUNT={len(removed)}",
            f"RO_TUNE6_INSTANCE_COUNT={len(ro_instances)}",
            f"RO_TUNE6_INSTANCE_NAMES={','.join(ro_instances)}",
            f"RO_TUNE6_INSTANCE_NAME_STATUS={instance_name_status}",
            "RO_TUNE6_SCALAR_PIN_COUNT=19",
            f"TOP_INSTANCE_COUNT={sum(masters.values())}",
            f"TOP_INSTANCE_MASTER_COUNT={len(masters)}",
            f"CDL_BACKED_TOP_INSTANCE_COUNT={sum(count for name, count in masters.items() if name in cdl_names)}",
            f"PHYSICAL_TIE_MASTER_COUNT={len(tie_master_names)}",
            f"PHYSICAL_TIE_INSTANCE_COUNT={sum(original_masters[name] for name in tie_master_names)}",
            "UNRESOLVED_ACTIVE_MASTER_COUNT=0",
        ]
        report_lines.extend(f"CANONICAL_CDL={path}" for path in args.cdl)
        report_lines.extend(f"REMOVED_MODULE={name}" for name in removed)
        report_lines.extend(
            f"PHYSICAL_TIE_MASTER={name}:{original_masters[name]}" for name in tie_master_names
        )
        write_lines(args.report, report_lines)
        return 0
    except ValueError as error:
        write_lines(
            args.report,
            [
                "# MPTDC Physical PVS LVS Source Contract",
                "LVS_SOURCE_CONTRACT_STATUS=FAIL",
                "SOURCE_KIND=INNOVUS_SAVE_NETLIST_PHYS_INCLUDE_POWER_GROUND",
                f"ERROR={error}",
            ],
        )
        print(f"ERROR: {error}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
