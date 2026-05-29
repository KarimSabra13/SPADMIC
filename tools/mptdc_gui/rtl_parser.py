#!/usr/bin/env python3
"""Static RTL and project parser for the MPTDC architecture GUI.

The parser is intentionally conservative: it uses lightweight SystemVerilog
regex extraction for module/port/instance/signal discovery, then combines that
with curated, cited findings from the maintained project documentation. Parsed
relationships are marked separately from inferred/curated relationships in the
JSON database.
"""

from __future__ import annotations

import argparse
import json
import os
import re
from collections import Counter, defaultdict
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Iterable


SOURCE_EXTS = {".sv", ".v", ".vh", ".svh"}
DOC_EXTS = {".md", ".txt", ".tex", ".pdf"}
SCRIPT_EXTS = {".py", ".sh", ".tcl", ".f"}
DATA_EXTS = {".json", ".csv", ".yaml", ".yml", ".rpt"}

DEFAULT_SOURCE_ROOTS = [
    "MPTDC/rtl",
    "TOP/rtl",
    "arb/rtl",
    "position/rtl",
    "I2C/rtl",
]

TEST_ROOTS = [
    "MPTDC/tb",
    "TOP/tb",
    "arb/tb",
    "position/tb",
    "position/vip",
]

DOC_ROOTS = [
    "MPTDC/docs",
    "TOP/docs",
    "docs",
    "charac",
    "Rapport_5PSM_KS/chapters",
]

SCRIPT_ROOTS = [
    "MPTDC/scripts",
    "MPTDC/ci",
    "TOP/scripts",
    "TOP/ci",
    "tools/timing",
]

RESULT_ROOTS = [
    "MPTDC/report_artifacts",
    "Rapport_5PSM_KS/data/mptdc_final_characterization",
]

SKIP_DIR_NAMES = {
    ".git",
    "__pycache__",
    "build",
    "xcelium.d",
    "cov_work",
}

SKIP_REL_DIRS = {
    "MPTDC/artifacts/overnight/vip/artifacts",
    "MPTDC/artifacts/overnight/vip/logs",
    "MPTDC/lab_snapshots",
    "MPTDC/results",
}


@dataclass
class SourceRef:
    file: str
    line: int
    label: str = ""


@dataclass
class Port:
    name: str
    direction: str
    sv_type: str
    width: str
    line: int
    category: str


@dataclass
class Parameter:
    name: str
    value: str
    line: int


@dataclass
class Instance:
    module: str
    name: str
    line: int
    parameters: dict[str, str] = field(default_factory=dict)
    connections: dict[str, str] = field(default_factory=dict)


@dataclass
class ModuleInfo:
    name: str
    kind: str
    file: str
    line: int
    purpose: str = ""
    ports: list[Port] = field(default_factory=list)
    parameters: list[Parameter] = field(default_factory=list)
    instances: list[Instance] = field(default_factory=list)
    signals: list[dict[str, Any]] = field(default_factory=list)
    fsm_states: list[str] = field(default_factory=list)
    key_registers: list[str] = field(default_factory=list)
    direct_evidence: list[dict[str, Any]] = field(default_factory=list)


def repo_rel(path: Path, repo_root: Path) -> str:
    try:
        return path.resolve().relative_to(repo_root.resolve()).as_posix()
    except ValueError:
        return path.as_posix()


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return path.read_text(encoding="latin-1", errors="replace")


def line_number_at(text: str, index: int) -> int:
    return text.count("\n", 0, index) + 1


def should_skip_dir(path: Path, repo_root: Path) -> bool:
    if path.name in SKIP_DIR_NAMES:
        return True
    rel = repo_rel(path, repo_root)
    return any(rel == skip or rel.startswith(skip + "/") for skip in SKIP_REL_DIRS)


def walk_candidate_files(root: Path, base: Path) -> Iterable[Path]:
    for current, dirs, files in os.walk(base):
        current_path = Path(current)
        dirs[:] = [d for d in dirs if not should_skip_dir(current_path / d, root)]
        for name in files:
            yield current_path / name


def iter_files(root: Path, roots: Iterable[str], exts: set[str]) -> list[Path]:
    files: list[Path] = []
    for rel in roots:
        base = root / rel
        if not base.exists():
            continue
        if base.is_file():
            if base.suffix.lower() in exts:
                files.append(base)
            continue
        for path in walk_candidate_files(root, base):
            if path.is_file() and path.suffix.lower() in exts:
                files.append(path)
    return sorted(set(files), key=lambda p: repo_rel(p, root).lower())


def strip_line_comment(line: str) -> str:
    return re.sub(r"//.*$", "", line)


def clean_sv_expr(value: str) -> str:
    value = re.sub(r"/\*.*?\*/", "", value, flags=re.S)
    value = re.sub(r"//.*", "", value)
    return " ".join(value.replace("\n", " ").split()).strip().rstrip(",")


def classify_signal(name: str, direction: str = "") -> str:
    low = name.lower()
    if "clk" in low or low.startswith("osc_") or "phase" in low and direction == "input":
        return "clock/timing"
    if "rst" in low or "reset" in low:
        return "reset"
    if any(k in low for k in ["valid", "ready", "enable", "_en", "arm", "clear", "clr", "gate", "sel"]):
        return "control"
    if any(k in low for k in ["status", "busy", "done", "full", "empty", "flag", "error", "ovf", "wdt"]):
        return "status"
    if any(k in low for k in ["debug", "probe", "snap", "count", "ctx", "hit", "nslow", "nfast", "data", "packet", "acq"]):
        return "data/debug"
    if direction in {"input", "output", "inout"}:
        return "interface"
    return "internal"


def find_purpose(text: str) -> str:
    match = re.search(r"Purpose\s*:\s*(.+)", text)
    return match.group(1).strip() if match else ""


def find_matching_paren(text: str, open_index: int) -> int:
    depth = 0
    in_line_comment = False
    in_block_comment = False
    in_string = False
    i = open_index
    while i < len(text):
        ch = text[i]
        nxt = text[i + 1] if i + 1 < len(text) else ""
        if in_line_comment:
            if ch == "\n":
                in_line_comment = False
            i += 1
            continue
        if in_block_comment:
            if ch == "*" and nxt == "/":
                in_block_comment = False
                i += 2
            else:
                i += 1
            continue
        if in_string:
            if ch == '"' and text[i - 1] != "\\":
                in_string = False
            i += 1
            continue
        if ch == "/" and nxt == "/":
            in_line_comment = True
            i += 2
            continue
        if ch == "/" and nxt == "*":
            in_block_comment = True
            i += 2
            continue
        if ch == '"':
            in_string = True
            i += 1
            continue
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return -1


def split_top_level_commas(text: str) -> list[str]:
    chunks: list[str] = []
    start = 0
    depth = 0
    for i, ch in enumerate(text):
        if ch in "({[":
            depth += 1
        elif ch in ")}]" and depth > 0:
            depth -= 1
        elif ch == "," and depth == 0:
            chunks.append(text[start:i].strip())
            start = i + 1
    tail = text[start:].strip()
    if tail:
        chunks.append(tail)
    return chunks


def split_top_level_commas_with_offsets(text: str) -> list[tuple[str, int]]:
    chunks: list[tuple[str, int]] = []
    start = 0
    depth = 0
    for i, ch in enumerate(text):
        if ch in "({[":
            depth += 1
        elif ch in ")}]" and depth > 0:
            depth -= 1
        elif ch == "," and depth == 0:
            chunk = text[start:i].strip()
            if chunk:
                chunks.append((chunk, start))
            start = i + 1
    tail = text[start:].strip()
    if tail:
        chunks.append((tail, start))
    return chunks


def strip_sv_comments_preserve_lines(text: str) -> str:
    """Remove SV comments while preserving line numbering."""
    def block_repl(match: re.Match[str]) -> str:
        body = match.group(0)
        return "\n" * body.count("\n")

    text = re.sub(r"/\*.*?\*/", block_repl, text, flags=re.S)
    return re.sub(r"//[^\n\r]*", "", text)


def parse_parameters_from_text(text: str, base_line: int) -> list[Parameter]:
    params: list[Parameter] = []
    pattern = re.compile(
        r"\b(?:parameter|localparam)\s+(?:\w+\s+)?(?:signed\s+|unsigned\s+)?"
        r"(?P<name>[A-Za-z_]\w*)\s*=\s*(?P<value>[^;,\n]+)"
    )
    for match in pattern.finditer(text):
        line = base_line + text.count("\n", 0, match.start())
        params.append(Parameter(match.group("name"), clean_sv_expr(match.group("value")), line))
    return params


def parse_ports(header: str, base_line: int) -> list[Port]:
    ports: list[Port] = []
    current_direction = ""
    current_type = ""
    current_width = ""
    header_no_comments = strip_sv_comments_preserve_lines(header)
    for chunk, offset in split_top_level_commas_with_offsets(header_no_comments):
        chunk_clean = clean_sv_expr(chunk).rstrip(";")
        if not chunk_clean:
            continue
        chunk_line = base_line + header_no_comments.count("\n", 0, offset)
        match = re.match(r"^(?P<dir>input|output|inout)\b(?P<rest>.*)$", chunk_clean)
        if match:
            current_direction = match.group("dir")
            rest = match.group("rest").strip()
        else:
            rest = chunk_clean
        if not current_direction:
            continue
        rest = re.sub(r"\s*=\s*.+$", "", rest).strip()
        name_match = re.match(
            r"^(?P<prefix>.*?)(?P<name>[A-Za-z_]\w*)\s*(?P<arrays>(?:\s*\[[^\]]+\])*)\s*$",
            rest,
        )
        if not name_match:
            continue
        prefix = " ".join(name_match.group("prefix").split()).strip()
        name = name_match.group("name")
        array_dims = " ".join(re.findall(r"\[[^\]]+\]", name_match.group("arrays")))
        packed_dims = " ".join(re.findall(r"\[[^\]]+\]", prefix))
        prefix_no_width = re.sub(r"\[[^\]]+\]", " ", prefix)
        sv_type = " ".join(prefix_no_width.split()).strip()
        width = " ".join(part for part in [packed_dims, array_dims] if part).strip()
        if sv_type or width:
            current_type = sv_type
            current_width = width
        else:
            sv_type = current_type
            width = current_width
        if re.match(r"^[A-Za-z_]\w*$", name):
            ports.append(
                Port(
                    name=name,
                    direction=current_direction,
                    sv_type=sv_type,
                    width=width,
                    line=chunk_line,
                    category=classify_signal(name, current_direction),
                )
            )
    return ports


def find_port_header(text: str, name: str) -> tuple[str, int] | None:
    """Return the ANSI port-list text and its first line for a module/interface."""
    decl_match = re.search(rf"\b{re.escape(name)}\b", text)
    if not decl_match:
        return None
    pos = decl_match.end()
    while pos < len(text):
        while pos < len(text) and text[pos].isspace():
            pos += 1
        if text.startswith("import", pos):
            semi = text.find(";", pos)
            if semi == -1:
                return None
            pos = semi + 1
            continue
        if pos < len(text) and text[pos] == "#":
            open_idx = text.find("(", pos)
            if open_idx == -1:
                return None
            close_idx = find_matching_paren(text, open_idx)
            if close_idx == -1:
                return None
            pos = close_idx + 1
            continue
        break
    if pos >= len(text) or text[pos] != "(":
        open_idx = text.find("(", pos)
    else:
        open_idx = pos
    if open_idx == -1:
        return None
    close_idx = find_matching_paren(text, open_idx)
    semi_idx = text.find(";", close_idx)
    if close_idx == -1 or semi_idx == -1:
        return None
    return text[open_idx + 1 : close_idx], text.count("\n", 0, open_idx) + 1


def parse_signal_declarations(body: str, base_line: int) -> list[dict[str, Any]]:
    signals: list[dict[str, Any]] = []
    lines = body.splitlines()
    idx = 0
    while idx < len(lines):
        raw = lines[idx]
        start_line = base_line + idx
        line = strip_line_comment(raw).strip()
        if not re.match(r"^(logic|wire|reg)\b", line):
            idx += 1
            continue
        stmt = line
        look = idx + 1
        while ";" not in stmt and look < len(lines) and look < idx + 8:
            stmt += " " + strip_line_comment(lines[look]).strip()
            look += 1
        idx = max(look, idx + 1)
        if ";" not in stmt:
            continue
        stmt = stmt.split(";", 1)[0]
        decl_match = re.match(r"^(?P<kind>logic|wire|reg)\s+(?P<rest>.+)$", stmt)
        if not decl_match:
            continue
        kind = decl_match.group("kind")
        rest = clean_sv_expr(decl_match.group("rest"))
        # Separate declarator list from type/width by finding the first comma-
        # separated declarator tail. This is intentionally heuristic and fast.
        width_match = re.search(r"\[[^\]]+\]", rest)
        width = width_match.group(0) if width_match else ""
        # Remove common qualifiers and packed widths. The last whitespace-
        # separated token before a comma-list is the first name.
        tokens = rest.split()
        if not tokens:
            continue
        type_tokens: list[str] = []
        name_start = 0
        for pos, token in enumerate(tokens):
            bare = re.sub(r"\[[^\]]+\]", "", token).strip(",")
            if re.match(r"^[A-Za-z_]\w*(?:,|$)", bare) and pos > 0:
                name_start = pos
                break
            type_tokens.append(token)
        if name_start == 0:
            # Handles simple "logic foo" declarations.
            name_start = max(0, len(tokens) - 1)
            type_tokens = tokens[:name_start]
        names_blob = " ".join(tokens[name_start:])
        for raw_name in split_top_level_commas(names_blob):
            raw_name = raw_name.split("=")[0].strip()
            raw_name = re.sub(r"\[[^\]]+\]", "", raw_name).strip()
            if re.match(r"^[A-Za-z_]\w*$", raw_name):
                signals.append(
                    {
                        "name": raw_name,
                        "kind": kind,
                        "type": clean_sv_expr(" ".join(type_tokens)),
                        "width": width,
                        "line": start_line,
                        "category": classify_signal(raw_name),
                    }
                )
    return signals


def parse_enum_states(text: str) -> list[str]:
    states: list[str] = []
    for block in re.finditer(r"typedef\s+enum\s+[^{}]*\{(?P<body>.*?)\}\s*(?P<name>\w+)", text, re.S):
        for state in re.findall(r"\b([A-Z][A-Z0-9_]+)\b\s*(?:=|,|$)", block.group("body")):
            if state not in states:
                states.append(state)
    return states


def parse_connection_map(port_blob: str) -> dict[str, str]:
    conns: dict[str, str] = {}
    for match in re.finditer(r"\.(?P<port>[A-Za-z_]\w*)\s*\((?P<expr>.*?)\)", port_blob, re.S):
        expr = clean_sv_expr(match.group("expr"))
        if expr and "unused" not in expr.lower():
            conns[match.group("port")] = expr
    return conns


def parse_instance_params(param_blob: str | None) -> dict[str, str]:
    params: dict[str, str] = {}
    if not param_blob:
        return params
    for match in re.finditer(r"\.(?P<name>[A-Za-z_]\w*)\s*\((?P<expr>.*?)\)", param_blob, re.S):
        params[match.group("name")] = clean_sv_expr(match.group("expr"))
    return params


def parse_modules(source_files: list[Path], repo_root: Path) -> dict[str, ModuleInfo]:
    modules: dict[str, ModuleInfo] = {}
    module_ranges: dict[str, tuple[Path, int, int, int]] = {}
    module_decl = re.compile(r"^\s*(module|interface|package)\s+([A-Za-z_]\w*)\b", re.M)

    for path in source_files:
        text = read_text(path)
        for match in module_decl.finditer(text):
            kind, name = match.group(1), match.group(2)
            start = match.start()
            line = line_number_at(text, start)
            end_pat = {"module": "endmodule", "interface": "endinterface", "package": "endpackage"}[kind]
            end_match = re.search(rf"\b{end_pat}\b", text[match.end() :], re.M)
            end = match.end() + end_match.end() if end_match else len(text)
            module_ranges[name] = (path, start, end, line)
            modules[name] = ModuleInfo(
                name=name,
                kind=kind,
                file=repo_rel(path, repo_root),
                line=line,
                purpose=find_purpose(text[: max(start, 1)]),
            )

    known_modules = sorted(modules.keys(), key=len, reverse=True)
    known_module_set = set(known_modules)

    for name, mod in modules.items():
        path, start, end, line = module_ranges[name]
        full_text = read_text(path)
        text = full_text[start:end]
        base_line = line
        mod.fsm_states = parse_enum_states(text)
        mod.parameters.extend(parse_parameters_from_text(text, base_line))
        mod.signals = parse_signal_declarations(text, base_line)
        mod.key_registers = sorted(
            {
                sig["name"]
                for sig in mod.signals
                if sig["name"].endswith("_q")
                or sig["name"].endswith("_r")
                or "state" in sig["name"].lower()
                or "count" in sig["name"].lower()
            }
        )[:40]

        header_info = find_port_header(text, name)
        if header_info:
            header, local_header_line = header_info
            mod.ports = parse_ports(header, base_line + local_header_line - 1)

        # Instance extraction is intentionally line-seeded. A naive DOTALL
        # regex for every known module against every module body is very slow
        # on large generated blocks. RTL instances in this project begin with
        # the child module name at statement start, so collect only those
        # statement-sized snippets and parse them.
        lines = text.splitlines(keepends=True)
        offsets: list[int] = []
        cursor = 0
        for line_text in lines:
            offsets.append(cursor)
            cursor += len(line_text)
        for idx, line_text in enumerate(lines):
            stripped = strip_line_comment(line_text).strip()
            first = re.match(r"([A-Za-z_]\w*)\b", stripped)
            if not first:
                continue
            child = first.group(1)
            if child == name or child not in known_module_set:
                continue
            start_idx = offsets[idx] + line_text.find(child)
            snippet_lines = [line_text]
            for next_line in lines[idx + 1 : min(len(lines), idx + 90)]:
                snippet_lines.append(next_line)
                if ");" in next_line:
                    break
            snippet = "".join(snippet_lines)
            inst_re = re.compile(
                rf"\b{re.escape(child)}\b\s*(?:#\s*\((?P<params>.*?)\)\s*)?(?P<inst>[A-Za-z_]\w*)\s*\(",
                re.S,
            )
            match = inst_re.search(snippet)
            if not match:
                continue
            inst_name = match.group("inst")
            open_idx = snippet.find("(", match.end() - 1)
            close_idx = find_matching_paren(snippet, open_idx)
            if close_idx == -1:
                continue
            line_no = base_line + text.count("\n", 0, start_idx)
            port_blob = snippet[open_idx + 1 : close_idx]
            mod.instances.append(
                Instance(
                    module=child,
                    name=inst_name,
                    line=line_no,
                    parameters=parse_instance_params(match.group("params")),
                    connections=parse_connection_map(port_blob),
                )
            )

        mod.direct_evidence.append({"file": mod.file, "line": mod.line, "kind": "definition"})

    return modules


def build_hierarchy(modules: dict[str, ModuleInfo], top: str) -> dict[str, Any]:
    visited: set[str] = set()

    def walk(name: str) -> dict[str, Any]:
        if name in visited:
            return {"name": name, "repeated": True, "children": []}
        visited.add(name)
        mod = modules.get(name)
        children = []
        if mod:
            for inst in mod.instances:
                children.append(
                    {
                        "module": inst.module,
                        "instance": inst.name,
                        "line": inst.line,
                        "children": walk(inst.module).get("children", []),
                    }
                )
        return {"name": name, "children": children}

    return walk(top)


def infer_signal_roles(modules: dict[str, ModuleInfo], repo_root: Path, source_files: list[Path]) -> list[dict[str, Any]]:
    role_map: dict[str, dict[str, Any]] = {}

    def entry(name: str) -> dict[str, Any]:
        if name not in role_map:
            role_map[name] = {
                "name": name,
                "category": classify_signal(name),
                "widths": set(),
                "directions": set(),
                "producers": set(),
                "consumers": set(),
                "appearances": [],
            }
        return role_map[name]

    for mod in modules.values():
        for port in mod.ports:
            e = entry(port.name)
            e["category"] = port.category
            e["widths"].add(port.width or "scalar")
            e["directions"].add(port.direction)
            if port.direction == "output":
                e["producers"].add(mod.name)
            else:
                e["consumers"].add(mod.name)
            e["appearances"].append({"file": mod.file, "line": port.line, "context": f"{mod.name}.{port.name} port"})
        for sig in mod.signals:
            e = entry(sig["name"])
            e["category"] = sig["category"]
            e["widths"].add(sig["width"] or "scalar")
            e["appearances"].append({"file": mod.file, "line": sig["line"], "context": f"{mod.name} declaration"})

    module_port_dirs = {
        mod.name: {port.name: port.direction for port in mod.ports}
        for mod in modules.values()
    }
    for mod in modules.values():
        for inst in mod.instances:
            dirs = module_port_dirs.get(inst.module, {})
            for child_port, expr in inst.connections.items():
                for sig_name in re.findall(r"\b[A-Za-z_]\w*\b", expr):
                    if sig_name in {"logic", "wire", "assign"} or sig_name.isupper():
                        continue
                    e = entry(sig_name)
                    child_dir = dirs.get(child_port, "")
                    if child_dir == "output":
                        e["producers"].add(f"{mod.name}.{inst.name}:{child_port}")
                    elif child_dir == "input":
                        e["consumers"].add(f"{mod.name}.{inst.name}:{child_port}")
                    e["appearances"].append(
                        {
                            "file": mod.file,
                            "line": inst.line,
                            "context": f"{mod.name}.{inst.name}.{child_port}",
                        }
                    )

    # Add bounded occurrence data for searched RTL files.
    interesting = set(role_map.keys())
    for path in source_files:
        rel = repo_rel(path, repo_root)
        text = read_text(path)
        for i, line in enumerate(text.splitlines(), 1):
            for sig in re.findall(r"\b[A-Za-z_]\w*\b", line):
                if sig in interesting and len(role_map[sig]["appearances"]) < 16:
                    role_map[sig]["appearances"].append({"file": rel, "line": i, "context": line.strip()[:120]})

    result = []
    for data in role_map.values():
        result.append(
            {
                "name": data["name"],
                "category": data["category"],
                "widths": sorted(data["widths"]),
                "directions": sorted(data["directions"]),
                "producers": sorted(data["producers"]),
                "consumers": sorted(data["consumers"]),
                "appearances": data["appearances"][:20],
            }
        )
    return sorted(result, key=lambda item: item["name"])


def inventory(repo_root: Path) -> dict[str, Any]:
    selected_roots = ["MPTDC", "TOP", "arb", "position", "I2C", "docs", "charac", "tools", "Rapport_5PSM_KS"]
    counts: Counter[str] = Counter()
    examples: dict[str, list[str]] = defaultdict(list)
    for rel in selected_roots:
        base = repo_root / rel
        if not base.exists():
            continue
        for path in walk_candidate_files(repo_root, base):
            if not path.is_file():
                continue
            suffix = path.suffix.lower() or "<none>"
            if suffix in SOURCE_EXTS | DOC_EXTS | SCRIPT_EXTS | DATA_EXTS:
                counts[suffix] += 1
                if len(examples[suffix]) < 12:
                    examples[suffix].append(repo_rel(path, repo_root))
    return {"counts_by_extension": dict(sorted(counts.items())), "examples_by_extension": dict(examples)}


def load_json_if_exists(path: Path) -> Any:
    if not path.exists():
        return None
    try:
        return json.loads(read_text(path))
    except Exception:
        return None


def curated_knowledge(repo_root: Path) -> dict[str, Any]:
    calibration_report = load_json_if_exists(
        repo_root / "MPTDC/report_artifacts/final_protocol_v27_boundaryfix/calibration/calibration_report.json"
    )
    characterization_manifest = load_json_if_exists(
        repo_root / "MPTDC/report_artifacts/final_protocol_v27_boundaryfix/characterization_manifest.json"
    )
    vip_summary = load_json_if_exists(repo_root / "MPTDC/artifacts/overnight/vip/vip_summary.json")

    calibration_metrics: dict[str, Any] = {}
    if isinstance(calibration_report, dict):
        held = calibration_report.get("held_out_validation", {})
        calibration_metrics = {
            "method": calibration_report.get("method"),
            "lut_key": calibration_report.get("lut_key", []),
            "pre_cal_rmse_ps": held.get("pre_cal", {}).get("rmse"),
            "post_cal_rmse_ps": held.get("post_cal", {}).get("rmse"),
            "slow_boundary_inc_nonzero_pct": held.get("slow_boundary_inc", {}).get("nonzero_pct"),
            "evidence": [
                {"file": "MPTDC/report_artifacts/final_protocol_v27_boundaryfix/calibration/calibration_report.json", "line": 2},
                {"file": "MPTDC/report_artifacts/final_protocol_v27_boundaryfix/calibration/calibration_report.json", "line": 81},
                {"file": "MPTDC/report_artifacts/final_protocol_v27_boundaryfix/calibration/calibration_report.json", "line": 95},
            ],
        }
    if isinstance(characterization_manifest, dict):
        calibration_metrics["characterization_status"] = characterization_manifest.get("status")
        calibration_metrics["campaign_row_count"] = characterization_manifest.get("summary", {}).get("campaign_row_count")

    vip_artifact_summary: dict[str, Any] = {}
    if isinstance(vip_summary, dict):
        vip_artifact_summary = {
            "total": vip_summary.get("total"),
            "pass": vip_summary.get("pass"),
            "fail": vip_summary.get("fail"),
            "note": "Committed artifact conflicts with README/status docs if it reports all failures; treat as stale or failed until rerun.",
            "evidence": [{"file": "MPTDC/artifacts/overnight/vip/vip_summary.json", "line": 2}],
        }

    return {
        "active_top": {
            "mptdc": "mptdc_top_asic",
            "full_chip": "spadmic_top_v1",
            "absent_expected_name": "mptdc_vernier_top_silicon",
            "evidence": [
                {"file": "MPTDC/README.md", "line": 26},
                {"file": "MPTDC/rtl/top/mptdc_top_asic.sv", "line": 25},
                {"file": "MPTDC/ci/run_smoke.sh", "line": 46},
                {"file": "TOP/rtl/spadmic_tdc_axis_wrapper.sv", "line": 61},
            ],
        },
        "flows": {
            "dataflow": [
                {
                    "id": "source_select",
                    "title": "SPAD/CAL async source select",
                    "claim": "mptdc_input_mux selects SPAD or calibration START/STOP as pure combinational async signals.",
                    "evidence": [{"file": "MPTDC/rtl/ctrl/mptdc_input_mux.sv", "line": 47}],
                },
                {
                    "id": "frontend_start",
                    "title": "START accepts and allocates a context",
                    "claim": "The frontend accepts START only when armed, unlatched, and with a free context; it then latches active_ctx.",
                    "evidence": [{"file": "MPTDC/rtl/async/mptdc_async_frontend_v2.sv", "line": 98}],
                },
                {
                    "id": "frontend_stop",
                    "title": "STOP launches fast oscillator and PD eligibility",
                    "claim": "STOP or synthetic timeout sets stop_latched only after START; fast oscillator and PD enable derive from START/STOP latches.",
                    "evidence": [{"file": "MPTDC/rtl/async/mptdc_async_frontend_v2.sv", "line": 144}],
                },
                {
                    "id": "pd_matrix",
                    "title": "8 x 8 phase detector matrix",
                    "claim": "mptdc_core generates one PD cell per slow/fast phase pair and latches per-cell nfast_hit.",
                    "evidence": [{"file": "MPTDC/rtl/top/mptdc_core.sv", "line": 406}],
                },
                {
                    "id": "context_and_drain",
                    "title": "Snapshot, context bank, drain",
                    "claim": "clk_sys measurement control samples the held image, commits context, then drain_ctrl emits META/HIT records.",
                    "evidence": [{"file": "MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv", "line": 165}],
                },
                {
                    "id": "fifo_stream",
                    "title": "FIFO to local or shared readout",
                    "claim": "The acquisition FIFO is consumed either by local narrow16 serializer or by acq_valid/acq_ready shared export.",
                    "evidence": [{"file": "MPTDC/rtl/top/mptdc_core.sv", "line": 563}],
                },
            ],
            "control_flow": [
                {
                    "name": "measurement_fsm",
                    "states": ["ST_M_IDLE", "ST_M_MEASURE", "ST_M_SNAPSHOT", "ST_M_COUNT", "ST_M_EVAL", "ST_M_CAPTURE", "ST_M_CLEAR"],
                    "evidence": [{"file": "MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv", "line": 119}],
                    "uncertain": "ST_M_STOP_OSC remains in the package enum but is not traversed by the current FSM.",
                },
                {
                    "name": "drain_fsm",
                    "states": ["ST_D_IDLE", "ST_D_META", "ST_D_SCAN", "ST_D_EMIT", "ST_D_EOC"],
                    "evidence": [{"file": "MPTDC/rtl/ctrl/mptdc_drain_ctrl.sv", "line": 173}],
                },
                {
                    "name": "serializer_fsm",
                    "states": ["S_IDLE", "S_HEADER", "S_HIT_FETCH", "S_HIT_W0", "S_HIT_W1", "S_EOC"],
                    "evidence": [{"file": "MPTDC/rtl/readout/mptdc_narrow16_tx_v2.sv", "line": 47}],
                },
            ],
            "timing_cdc": [
                {
                    "domain": "clk_sys",
                    "role": "CSR, measurement FSM, hit bridge, context bank, drain, FIFO, serializer, watchdog.",
                    "evidence": [{"file": "MPTDC/docs/01_ARCHITECTURE.md", "line": 89}],
                },
                {
                    "domain": "slow_phase[0]",
                    "role": "Slow coarse counter and missing-STOP watchdog source clock.",
                    "evidence": [{"file": "MPTDC/rtl/top/mptdc_core.sv", "line": 225}],
                },
                {
                    "domain": "fast_phase[n]",
                    "role": "PD cell sampling clocks; fast_phase[0] also clocks fast counter.",
                    "evidence": [{"file": "MPTDC/rtl/pd/mptdc_pd_cell.sv", "line": 29}],
                },
                {
                    "domain": "async_event",
                    "role": "START/STOP latches and STOP-side metadata capture.",
                    "evidence": [{"file": "MPTDC/rtl/async/mptdc_stop_capture_async.sv", "line": 41}],
                },
            ],
        },
        "event_format": {
            "words": [
                {"name": "Header", "bits": "[15:14]=10, [13:12]=ctx_id, [11]=phase0_snap, [10:7]=hit_count, [6:3]=flags, [2]=slow_boundary_inc"},
                {"name": "Hit W0", "bits": "[15]=0, [14:8]=nslow, [7:1]=nfast_hit, [0]=0"},
                {"name": "Hit W1", "bits": "[15]=0, [14:11]=ns, [10:7]=nf, [6:3]=reserved, [2:0]=stop_phase_disc"},
                {"name": "EOC", "bits": "[15:14]=11, [13:0]=conv_count"},
            ],
            "evidence": [
                {"file": "MPTDC/docs/02_OUTPUT_PROTOCOL.md", "line": 29},
                {"file": "MPTDC/rtl/readout/mptdc_narrow16_tx_v2.sv", "line": 91},
            ],
        },
        "verification": {
            "entrypoints": [
                "bash MPTDC/ci/run_smoke.sh",
                "bash MPTDC/ci/run_full_regression.sh",
                "bash MPTDC/ci/run_vip_smoke.sh",
                "bash MPTDC/scripts/sim/run_vip_test.sh smoke_single_conv --sim verilator",
                "bash MPTDC/ci/run_vip_coverage.sh --sim xrun --clean",
            ],
            "unit_benches": [
                "tb_input_mux_unit",
                "tb_reset_sync_unit",
                "tb_watchdog_unit",
                "tb_context_bank_unit",
                "tb_narrow16_tx_v2_unit",
                "tb_gray_cnt_sync_unit",
                "tb_hit_capture_bridge_unit",
                "tb_meas_ctrl_unit",
                "tb_drain_ctrl_unit",
            ],
            "integration_benches": [
                "tb_single_conv",
                "tb_multi_conv_stress",
                "tb_deadtime_measure",
                "tb_cal_inject",
                "tb_backpressure",
                "tb_lossless_pressure",
                "tb_watchdog_recovery",
                "tb_start_wdt",
                "tb_overflow_count",
                "tb_firsthit_mode",
            ],
            "evidence": [{"file": "MPTDC/docs/04_VERIFICATION.md", "line": 217}],
            "vip_artifact_summary": vip_artifact_summary,
        },
        "calibration": calibration_metrics,
        "uncertainties": [
            {
                "title": "Expected top name absent",
                "detail": "mptdc_vernier_top_silicon was not found in searched repo files.",
                "severity": "medium",
            },
            {
                "title": "Physical oscillator not signoff-ready in repo",
                "detail": "Synthesis path uses placeholder/stub until real macro contracts exist.",
                "severity": "high",
                "evidence": [{"file": "MPTDC/docs/07_DESIGN_REVIEW.md", "line": 350}],
            },
            {
                "title": "Standard CDC/STA closure not proven",
                "detail": "Intentional async latches, STOP capture, Gray snapshot, and PD local clocks need methodology/waiver closure.",
                "severity": "high",
                "evidence": [{"file": "docs/timing_closure/cdc_async_waiver_package.md", "line": 74}],
            },
            {
                "title": "Committed VIP artifact appears stale or failed",
                "detail": "vip_summary.json reports 4096 failures, inconsistent with current README status claims.",
                "severity": "medium",
                "evidence": [{"file": "MPTDC/artifacts/overnight/vip/vip_summary.json", "line": 2}],
            },
        ],
    }


PORT_VALIDATION_EXPECTED = {
    "mptdc_input_mux": [
        "clk_sys",
        "rst_n",
        "start_spad_async_i",
        "stop_spad_async_i",
        "cal_start_async_i",
        "cal_stop_async_i",
        "input_sel_i",
        "start_async_o",
        "stop_async_o",
    ],
    "mptdc_core": [
        "clk_sys",
        "rst_sys_n",
        "start_async_i",
        "stop_async_i",
        "cfg_i",
        "conv_arm_i",
        "fifo_clr_i",
        "status_o",
        "narrow_ready_i",
        "narrow_valid_o",
        "narrow_data_o",
        "shared_readout_en_i",
        "acq_ready_i",
        "acq_valid_o",
        "acq_data_o",
    ],
    "mptdc_top_asic": [
        "clk_sys",
        "async_rst_n",
        "start_spad_async_i",
        "stop_spad_async_i",
        "cal_start_async_i",
        "cal_stop_async_i",
        "input_sel_override_en_i",
        "input_sel_override_i",
        "out_mode_override_en_i",
        "out_mode_override_i",
        "csr_valid_i",
        "csr_write_i",
        "csr_addr_i",
        "csr_wdata_i",
        "csr_ready_o",
        "csr_rvalid_o",
        "csr_rdata_o",
        "narrow_ready_i",
        "narrow_valid_o",
        "narrow_data_o",
        "shared_readout_en_i",
        "acq_ready_i",
        "acq_valid_o",
        "acq_data_o",
        "fifo_full_o",
    ],
    "mptdc_async_frontend_v2": [
        "rst_n",
        "conv_arm_i",
        "start_async_i",
        "stop_async_i",
        "fe_clear_async_i",
        "start_timeout_async_i",
        "ctx_release_async_i",
        "capture_en_i",
        "osc_keep_alive_i",
        "start_latched_o",
        "stop_latched_o",
        "osc_slow_en_async_o",
        "osc_fast_en_async_o",
        "pd_enable_async_o",
        "active_ctx_o",
        "ctx_state_o",
        "ctx_drain_o",
        "all_ctx_busy_o",
        "start_rejected_o",
    ],
    "mptdc_narrow16_tx_v2": [
        "clk_sys",
        "rst_n",
        "out_mode_i",
        "fifo_rd_valid_i",
        "fifo_rd_data_i",
        "fifo_rd_en_o",
        "narrow_ready_i",
        "narrow_valid_o",
        "narrow_data_o",
    ],
}


def validate_key_ports(modules: dict[str, ModuleInfo]) -> dict[str, Any]:
    checks: list[dict[str, Any]] = []
    passed = True
    for module_name, expected in PORT_VALIDATION_EXPECTED.items():
        parsed = [port.name for port in modules.get(module_name, ModuleInfo(module_name, "module", "", 0)).ports]
        missing = [name for name in expected if name not in parsed]
        bad_short_names = [name for name in parsed if len(name) == 1 and name in {"s", "n", "i", "o"}]
        ok = not missing and not bad_short_names
        passed = passed and ok
        checks.append(
            {
                "module": module_name,
                "passed": ok,
                "expected": expected,
                "parsed": parsed,
                "missing": missing,
                "bad_short_names": bad_short_names,
            }
        )
    return {
        "passed": passed,
        "checks": checks,
        "note": "Validation locale des ports ANSI clés; ne remplace pas un parseur SystemVerilog complet.",
    }


def make_db(repo_root: Path) -> dict[str, Any]:
    source_files = iter_files(repo_root, DEFAULT_SOURCE_ROOTS, SOURCE_EXTS)
    modules = parse_modules(source_files, repo_root)
    signals = infer_signal_roles(modules, repo_root, source_files)
    docs = iter_files(repo_root, DOC_ROOTS, DOC_EXTS)
    scripts = iter_files(repo_root, SCRIPT_ROOTS, SCRIPT_EXTS)
    tests = iter_files(repo_root, TEST_ROOTS, SOURCE_EXTS | {".f", ".md"})
    result_files = iter_files(repo_root, RESULT_ROOTS, DATA_EXTS)

    filelist_path = repo_root / "MPTDC/rtl/filelist.f"
    filelist = read_text(filelist_path).splitlines() if filelist_path.exists() else []
    active_rtl_files = [
        line.strip()
        for line in filelist
        if line.strip() and not line.strip().startswith("//") and line.strip().endswith((".sv", ".v"))
    ]

    db = {
        "schema_version": 1,
        "generated_by": "tools/mptdc_gui/rtl_parser.py",
        "repo_root_name": repo_root.name,
        "active_top": "mptdc_top_asic",
        "full_chip_top": "spadmic_top_v1",
        "active_rtl_filelist": active_rtl_files,
        "repo_inventory": inventory(repo_root),
        "files": {
            "rtl": [repo_rel(p, repo_root) for p in source_files],
            "testbench": [repo_rel(p, repo_root) for p in tests],
            "docs": [repo_rel(p, repo_root) for p in docs],
            "scripts": [repo_rel(p, repo_root) for p in scripts],
            "result_examples": [repo_rel(p, repo_root) for p in result_files[:120]],
        },
        "modules": [asdict(mod) for mod in sorted(modules.values(), key=lambda m: (m.file, m.line))],
        "module_index": {name: asdict(mod) for name, mod in modules.items()},
        "hierarchy": {
            "mptdc_top_asic": build_hierarchy(modules, "mptdc_top_asic"),
            "spadmic_top_v1": build_hierarchy(modules, "spadmic_top_v1"),
        },
        "signals": signals,
        "parser_validation": validate_key_ports(modules),
        "curated": curated_knowledge(repo_root),
    }
    return db


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate MPTDC architecture database.")
    parser.add_argument("--repo-root", default=".", help="Repository root")
    parser.add_argument(
        "--out",
        default="tools/mptdc_gui/architecture_db.json",
        help="Output JSON path relative to repo root unless absolute",
    )
    parser.add_argument(
        "--validate-ports",
        action="store_true",
        help="Exit non-zero if key ANSI port parsing checks fail.",
    )
    args = parser.parse_args()

    repo_root = Path(args.repo_root).resolve()
    out_path = Path(args.out)
    if not out_path.is_absolute():
        out_path = repo_root / out_path
    out_path.parent.mkdir(parents=True, exist_ok=True)

    db = make_db(repo_root)
    out_path.write_text(json.dumps(db, indent=2, sort_keys=False), encoding="utf-8")
    print(f"Wrote {out_path} with {len(db['modules'])} modules and {len(db['signals'])} signals")
    validation = db.get("parser_validation", {})
    print(f"Port validation: {'PASS' if validation.get('passed') else 'FAIL'}")
    if args.validate_ports and not validation.get("passed"):
        for check in validation.get("checks", []):
            if not check.get("passed"):
                print(
                    f"  {check['module']}: missing={check['missing']} "
                    f"bad_short_names={check['bad_short_names']}"
                )
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
