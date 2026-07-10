#!/usr/bin/env python3
"""Collect an immutable, read-only evidence bundle from an existing PVS LVS run."""

from __future__ import annotations

import argparse
import hashlib
import os
import re
import shutil
import stat
from datetime import datetime, timezone
from pathlib import Path


CONTROL_NAMES = {
    "run.pvs",
    "pvslvsctl",
    ".config.rul",
    ".technology.rul",
    ".preset.autosave",
    "cell_tree.txt",
    "lay_cellMap.txt",
    "pipo1.setup",
    "pipo2.setup",
    "pvs_file.index",
    "var_cdlOutKeys.virtuoso",
    "var_streamOutKeys.virtuoso",
}
CONTROL_SUFFIXES = {".rul", ".ctl", ".cfg", ".conf", ".setup", ".lmap", ".hcell"}
LOG_SUFFIXES = {".log", ".out", ".stdout", ".stderr"}
REPORT_SUFFIXES = {
    ".rpt",
    ".report",
    ".sum",
    ".summary",
    ".cmp",
    ".comparison",
    ".mismatch",
    ".erc",
    ".err",
    ".results",
}
NETLIST_SUFFIXES = {
    ".v",
    ".sv",
    ".cdl",
    ".spi",
    ".sp",
    ".spice",
    ".scs",
    ".cir",
    ".ckt",
    ".net",
    ".netlist",
    ".src",
}
LAYOUT_SUFFIXES = {".gds", ".gdsii", ".oas", ".oasis"}
REFERENCE_SUFFIXES = (
    CONTROL_SUFFIXES
    | REPORT_SUFFIXES
    | LOG_SUFFIXES
    | NETLIST_SUFFIXES
    | LAYOUT_SUFFIXES
    | {".lef", ".lib", ".db"}
)
GIT_CONTROL_NAMES = {
    "run.pvs",
    "pvslvsctl",
    ".config.rul",
    ".technology.rul",
    "cell_tree.txt",
    "lay_cellMap.txt",
    "pipo1.setup",
    "pipo2.setup",
}

ABSOLUTE_PATH_RE = re.compile(r"(?<![A-Za-z0-9_])(/[^\s\"'{};|<>]+)")
CONTRACT_RE = re.compile(
    r"(?:top[_ ]?cell|primary|layout|source|schematic|netlist|cdl|hcell|"
    r"virtual[_ ]?connect|power|ground|vdd|vss|gds)",
    re.IGNORECASE,
)
LVS_STATUS_RE = re.compile(
    r"(?:lvs|match|mismatch|not\s+match|incorrect|discrep|unmatched|compare|"
    r"comparison|error|warning|open|short|device|terminal|port|net)",
    re.IGNORECASE,
)
PVS_TOOL_RE = re.compile(
    r"(?:PVS(?:\s+Version)?|Pegasus|Product\s+Version|/[A-Za-z0-9_./-]*/pvs(?:\s|$))",
    re.IGNORECASE,
)
PORT_RE = re.compile(
    r"(?:^|\s)(?:module|input|output|inout|supply0|supply1|subckt|\.subckt)\b|"
    r"\]\s*\[|>\s*<",
    re.IGNORECASE,
)
DOUBLE_BRACKET_RE = re.compile(
    r"(?:\\?[A-Za-z_$][A-Za-z0-9_$./\\-]*)\s*(?:\[[^\]\r\n]*\]\s*){2,}"
)
EMPTY_DOUBLE_BRACKET_RE = re.compile(r"\[\s*\]\s*\[\s*\]")
DOUBLE_ANGLE_RE = re.compile(
    r"(?:\\?[A-Za-z_$][A-Za-z0-9_$./\\-]*)\s*(?:<[^>\r\n]*>\s*){2,}"
)


def digest(path: Path) -> str:
    hasher = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            hasher.update(block)
    return hasher.hexdigest()


def iso_time(timestamp: float) -> str:
    return datetime.fromtimestamp(timestamp, tz=timezone.utc).isoformat()


def clean_field(value: object) -> str:
    return str(value).replace("\t", " ").replace("\r", " ").replace("\n", " ")


def relative_to(path: Path, parent: Path) -> Path | None:
    try:
        return path.relative_to(parent)
    except ValueError:
        return None


def entry_kind(mode: int) -> str:
    if stat.S_ISREG(mode):
        return "file"
    if stat.S_ISDIR(mode):
        return "directory"
    if stat.S_ISLNK(mode):
        return "symlink"
    return "other"


def snapshot_tree(root: Path, hash_files: bool) -> tuple[list[dict[str, object]], list[str]]:
    records: list[dict[str, object]] = []
    errors: list[str] = []
    for directory, dirnames, filenames in os.walk(root, followlinks=False):
        directory_path = Path(directory)
        names = sorted(set(dirnames + filenames))
        for name in names:
            path = directory_path / name
            try:
                info = path.lstat()
                kind = entry_kind(info.st_mode)
                link_target = os.readlink(path) if kind == "symlink" else ""
                checksum = "NOT_APPLICABLE"
                if hash_files and kind == "file":
                    try:
                        checksum = digest(path)
                    except OSError as error:
                        checksum = "HASH_ERROR"
                        errors.append(f"HASH_ERROR={path}|{error}")
                records.append(
                    {
                        "relative_path": str(path.relative_to(root)),
                        "absolute_path": str(path),
                        "type": kind,
                        "size": info.st_size,
                        "mtime_ns": info.st_mtime_ns,
                        "mtime_utc": iso_time(info.st_mtime),
                        "sha256": checksum,
                        "link_target": link_target,
                    }
                )
            except OSError as error:
                errors.append(f"STAT_ERROR={path}|{error}")
        dirnames[:] = sorted(
            name for name in dirnames if not (directory_path / name).is_symlink()
        )
    records.sort(key=lambda item: str(item["relative_path"]))
    return records, errors


def metadata_signature(records: list[dict[str, object]]) -> dict[str, tuple[object, ...]]:
    return {
        str(record["relative_path"]): (
            record["type"],
            record["size"],
            record["mtime_ns"],
            record["link_target"],
        )
        for record in records
    }


def write_inventory(path: Path, records: list[dict[str, object]]) -> None:
    with path.open("w", encoding="utf-8") as handle:
        handle.write("type\tmtime_utc\tbytes\tsha256\trelative_path\tabsolute_path\tlink_target\n")
        for record in records:
            handle.write(
                "\t".join(
                    clean_field(record[key])
                    for key in (
                        "type",
                        "mtime_utc",
                        "size",
                        "sha256",
                        "relative_path",
                        "absolute_path",
                        "link_target",
                    )
                )
                + "\n"
            )


def is_probably_text(path: Path) -> bool:
    try:
        with path.open("rb") as handle:
            sample = handle.read(8192)
    except OSError:
        return False
    if b"\x00" in sample:
        return False
    if not sample:
        return True
    printable = sum(byte in b"\t\n\r" or 32 <= byte < 127 for byte in sample)
    return printable / len(sample) >= 0.80


def classify_file(path: Path) -> str | None:
    name = path.name
    lower_name = name.lower()
    suffix = path.suffix.lower()
    if name in CONTROL_NAMES or suffix in CONTROL_SUFFIXES or lower_name.endswith("ctl"):
        return "controls"
    if suffix in NETLIST_SUFFIXES:
        return "netlist"
    if suffix in LOG_SUFFIXES or lower_name.endswith("log") or lower_name.endswith("out"):
        return "logs"
    if suffix in REPORT_SUFFIXES or any(
        token in lower_name
        for token in (
            "lvs",
            "mismatch",
            "compare",
            "comparison",
            "summary",
            "report",
            "result",
            "error",
        )
    ):
        return "reports"
    return None


def read_text(path: Path, max_bytes: int) -> str | None:
    try:
        if path.stat().st_size > max_bytes or not is_probably_text(path):
            return None
        return path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return None


def copy_selected_files(
    source: Path,
    bundle: Path,
    records: list[dict[str, object]],
    max_bytes: int,
) -> tuple[list[dict[str, object]], dict[Path, str]]:
    selected: list[dict[str, object]] = []
    text_cache: dict[Path, str] = {}
    for record in records:
        if record["type"] != "file":
            continue
        source_path = Path(str(record["absolute_path"]))
        category = classify_file(source_path)
        if category is None:
            continue
        text = read_text(source_path, max_bytes)
        copy_status = "SKIPPED_NOT_SMALL_TEXT"
        destination = "NONE"
        if text is not None:
            relative = Path(str(record["relative_path"]))
            destination_path = bundle / category / relative
            destination_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source_path, destination_path)
            destination = str(destination_path)
            copy_status = "COPIED"
            text_cache[source_path] = text
        selected.append(
            {
                "class": category,
                "relative_path": record["relative_path"],
                "absolute_path": record["absolute_path"],
                "size": record["size"],
                "mtime_utc": record["mtime_utc"],
                "sha256": record["sha256"],
                "copy_status": copy_status,
                "bundle_path": destination,
            }
        )
    selected.sort(key=lambda item: (str(item["class"]), str(item["relative_path"])))
    return selected, text_cache


def write_selected_manifest(path: Path, selected: list[dict[str, object]]) -> None:
    keys = (
        "class",
        "relative_path",
        "absolute_path",
        "size",
        "mtime_utc",
        "sha256",
        "copy_status",
        "bundle_path",
    )
    with path.open("w", encoding="utf-8") as handle:
        handle.write("\t".join(keys) + "\n")
        for record in selected:
            handle.write("\t".join(clean_field(record[key]) for key in keys) + "\n")


def extract_absolute_paths(text: str) -> set[Path]:
    paths: set[Path] = set()
    for match in ABSOLUTE_PATH_RE.finditer(text):
        value = match.group(1).rstrip("),]\\")
        if value:
            paths.add(Path(value))
    return paths


def extract_line_paths(line: str, base_directory: Path) -> set[Path]:
    paths = extract_absolute_paths(line)
    tokens = re.findall(r'"([^"\r\n]+)"|\'([^\'\r\n]+)\'|([^\s{};]+)', line)
    for groups in tokens:
        token = next((value for value in groups if value), "").strip().rstrip("),]\\")
        if not token or token.startswith("-") or token.startswith("/"):
            continue
        candidate = Path(token)
        if "/" not in token and candidate.suffix.lower() not in REFERENCE_SUFFIXES:
            continue
        paths.add((base_directory / candidate).resolve(strict=False))
    return paths


def reference_class(path: Path) -> str:
    lower = str(path).lower()
    suffix = path.suffix.lower()
    if suffix in LAYOUT_SUFFIXES:
        return "LAYOUT"
    if "d_cells_jihd" in lower or "/pdk/" in lower or lower.startswith("/eda/"):
        return "PDK_OR_STDCELL"
    if suffix == ".cdl":
        return "CDL"
    if suffix in NETLIST_SUFFIXES:
        return "SOURCE_NETLIST"
    if suffix in {".rul", ".rule", ".rules"}:
        return "RULE_DECK"
    if path.name == "pvs" or "/pvs_" in lower:
        return "PVS_TOOL"
    return "OTHER"


def inspect_external_references(
    source: Path,
    bundle: Path,
    text_cache: dict[Path, str],
    max_copy_bytes: int,
) -> tuple[list[dict[str, object]], list[Path]]:
    candidates: set[Path] = set()
    source_candidates: set[Path] = set()
    for text_path, text in text_cache.items():
        candidates.update(extract_absolute_paths(text))
        for line in text.splitlines():
            if CONTRACT_RE.search(line):
                candidates.update(extract_line_paths(line, text_path.parent))
            if re.search(r"(?:source|schematic|netlist|cdl)", line, re.IGNORECASE):
                source_candidates.update(extract_line_paths(line, text_path.parent))

    records: list[dict[str, object]] = []
    copied_project_netlists: list[Path] = []
    for candidate in sorted(candidates, key=str):
        if relative_to(candidate, source) is not None:
            continue
        kind = "missing"
        size: object = 0
        mtime = "MISSING"
        checksum = "MISSING"
        target = ""
        copy_status = "REFERENCE_ONLY"
        try:
            info = candidate.lstat()
            kind = entry_kind(info.st_mode)
            size = info.st_size
            mtime = iso_time(info.st_mtime)
            if kind == "symlink":
                target = os.readlink(candidate)
            elif kind == "file":
                checksum = digest(candidate)
        except OSError:
            pass

        classification = reference_class(candidate)
        if (
            candidate in source_candidates
            and classification in {"SOURCE_NETLIST", "CDL"}
            and "d_cells_jihd" not in str(candidate).lower()
            and kind == "file"
            and isinstance(size, int)
            and size <= max_copy_bytes
            and is_probably_text(candidate)
        ):
            destination = bundle / "netlist" / "external" / candidate.name
            if destination.exists():
                destination = destination.with_name(
                    f"{destination.stem}_{checksum[:12]}{destination.suffix}"
                )
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(candidate, destination)
            copied_project_netlists.append(candidate)
            copy_status = f"COPIED_PROJECT_SOURCE={destination}"

        records.append(
            {
                "class": classification,
                "path": str(candidate),
                "type": kind,
                "size": size,
                "mtime_utc": mtime,
                "sha256": checksum,
                "link_target": target,
                "copy_status": copy_status,
            }
        )
    return records, copied_project_netlists


def write_external_manifest(path: Path, records: list[dict[str, object]]) -> None:
    keys = ("class", "path", "type", "size", "mtime_utc", "sha256", "link_target", "copy_status")
    with path.open("w", encoding="utf-8") as handle:
        handle.write("\t".join(keys) + "\n")
        for record in records:
            handle.write("\t".join(clean_field(record[key]) for key in keys) + "\n")


def write_line_extract(
    path: Path,
    text_cache: dict[Path, str],
    pattern: re.Pattern[str],
    per_file_limit: int,
) -> int:
    count = 0
    with path.open("w", encoding="utf-8") as handle:
        for source_path in sorted(text_cache, key=str):
            file_count = 0
            for line_number, line in enumerate(text_cache[source_path].splitlines(), start=1):
                if not pattern.search(line):
                    continue
                handle.write(f"{source_path}:{line_number}:{clean_field(line)}\n")
                count += 1
                file_count += 1
                if file_count >= per_file_limit:
                    handle.write(f"{source_path}:TRUNCATED_AFTER={per_file_limit}\n")
                    break
    return count


def write_pin_name_audit(path: Path, text_cache: dict[Path, str]) -> dict[str, int]:
    counts = {"DOUBLE_BRACKET": 0, "EMPTY_DOUBLE_BRACKET": 0, "DOUBLE_ANGLE": 0}
    with path.open("w", encoding="utf-8") as handle:
        handle.write("category\tpath\tline\ttoken_or_text\n")
        for source_path in sorted(text_cache, key=str):
            for line_number, line in enumerate(text_cache[source_path].splitlines(), start=1):
                for category, pattern in (
                    ("EMPTY_DOUBLE_BRACKET", EMPTY_DOUBLE_BRACKET_RE),
                    ("DOUBLE_BRACKET", DOUBLE_BRACKET_RE),
                    ("DOUBLE_ANGLE", DOUBLE_ANGLE_RE),
                ):
                    for match in pattern.finditer(line):
                        counts[category] += 1
                        handle.write(
                            f"{category}\t{source_path}\t{line_number}\t"
                            f"{clean_field(match.group(0))}\n"
                        )
    return counts


def write_hash_manifest(
    path: Path,
    source_records: list[dict[str, object]],
    external_records: list[dict[str, object]],
) -> None:
    with path.open("w", encoding="utf-8") as handle:
        for record in source_records:
            if record["type"] == "file" and record["sha256"] != "HASH_ERROR":
                handle.write(f"{record['sha256']}  {record['absolute_path']}\n")
        for record in external_records:
            if record["type"] == "file" and record["sha256"] not in {"MISSING", "HASH_ERROR"}:
                handle.write(f"{record['sha256']}  {record['path']}\n")


def copy_git_candidate(
    bundle: Path,
    selected: list[dict[str, object]],
    git_max_bytes: int,
) -> Path:
    git_root = bundle / "git_text_candidate"
    git_root.mkdir()
    generated_names = (
        "collection_status.rpt",
        "source_inventory.tsv",
        "inventory_by_date.tsv",
        "inventory_by_size.tsv",
        "selected_file_manifest.tsv",
        "external_reference_manifest.tsv",
        "source_netlist_candidates.tsv",
        "input_contract_extract.rpt",
        "pvs_tool_version_extract.rpt",
        "lvs_status_extract.rpt",
        "netlist_port_extract.rpt",
        "pin_name_audit.rpt",
        "hashes.sha256",
    )
    for name in generated_names:
        source_path = bundle / name
        if source_path.is_file():
            shutil.copy2(source_path, git_root / name)

    for record in selected:
        if record["copy_status"] != "COPIED" or int(record["size"]) > git_max_bytes:
            continue
        name = Path(str(record["relative_path"])).name
        include = record["class"] == "reports" or (
            record["class"] == "controls" and name in GIT_CONTROL_NAMES
        )
        if not include:
            continue
        source_path = Path(str(record["bundle_path"]))
        destination = git_root / str(record["class"]) / str(record["relative_path"])
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source_path, destination)

    (git_root / "README.txt").write_text(
        "SPADMIC TX_PACKET_CORE_HV PVS LVS read-only intake candidate.\n"
        "Contains compact text evidence only. No GDS, OA, full netlist, PDK,\n"
        "rule installation, or PVS result database is included.\n",
        encoding="utf-8",
    )
    manifest_path = git_root / "MANIFEST.sha256"
    with manifest_path.open("w", encoding="utf-8") as handle:
        for candidate in sorted(git_root.rglob("*"), key=lambda item: str(item.relative_to(git_root))):
            if candidate.is_file() and candidate != manifest_path:
                handle.write(f"{digest(candidate)}  {candidate.relative_to(git_root)}\n")
    return git_root


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-run", required=True, type=Path)
    parser.add_argument("--bundle-root", required=True, type=Path)
    parser.add_argument("--max-copy-bytes", type=int, default=25_000_000)
    parser.add_argument("--git-max-bytes", type=int, default=2_000_000)
    args = parser.parse_args()

    source = args.source_run.expanduser().resolve()
    bundle = args.bundle_root.expanduser().resolve(strict=False)
    if not source.is_dir():
        raise SystemExit(f"SOURCE_RUN_MISSING={source}")
    if bundle.exists():
        raise SystemExit(f"IMMUTABLE_BUNDLE_EXISTS={bundle}")
    if relative_to(bundle, source) is not None:
        raise SystemExit("BUNDLE_MUST_NOT_BE_INSIDE_SOURCE_RUN")
    if args.max_copy_bytes <= 0 or args.git_max_bytes <= 0:
        raise SystemExit("COPY_LIMITS_MUST_BE_POSITIVE")

    before_records, errors = snapshot_tree(source, hash_files=True)
    before_signature = metadata_signature(before_records)
    bundle.mkdir(parents=True)
    for name in ("controls", "logs", "reports", "netlist", "status"):
        (bundle / name).mkdir()

    write_inventory(bundle / "source_inventory.tsv", before_records)
    date_records = sorted(before_records, key=lambda item: int(item["mtime_ns"]), reverse=True)
    size_records = sorted(before_records, key=lambda item: int(item["size"]), reverse=True)
    write_inventory(bundle / "inventory_by_date.tsv", date_records)
    write_inventory(bundle / "inventory_by_size.tsv", size_records)

    selected, text_cache = copy_selected_files(
        source, bundle, before_records, args.max_copy_bytes
    )
    write_selected_manifest(bundle / "selected_file_manifest.tsv", selected)
    external, copied_netlists = inspect_external_references(
        source, bundle, text_cache, args.max_copy_bytes
    )
    write_external_manifest(bundle / "external_reference_manifest.tsv", external)

    source_candidates = [
        {
            "class": "LOCAL_NETLIST",
            "path": record["absolute_path"],
            "type": "file",
            "size": record["size"],
            "sha256": record["sha256"],
            "copy_status": record["copy_status"],
        }
        for record in selected
        if record["class"] == "netlist"
    ]
    source_candidates.extend(
        record
        for record in external
        if record["class"] in {"SOURCE_NETLIST", "CDL"}
    )
    with (bundle / "source_netlist_candidates.tsv").open("w", encoding="utf-8") as handle:
        handle.write("class\tpath\ttype\tbytes\tsha256\tcopy_status\n")
        for record in source_candidates:
            handle.write(
                "\t".join(
                    clean_field(record[key])
                    for key in ("class", "path", "type", "size", "sha256", "copy_status")
                )
                + "\n"
            )

    for netlist_path in copied_netlists:
        text = read_text(netlist_path, args.max_copy_bytes)
        if text is not None:
            text_cache[netlist_path] = text

    contract_lines = write_line_extract(
        bundle / "input_contract_extract.rpt", text_cache, CONTRACT_RE, 1000
    )
    tool_lines = write_line_extract(
        bundle / "pvs_tool_version_extract.rpt", text_cache, PVS_TOOL_RE, 500
    )
    lvs_lines = write_line_extract(
        bundle / "lvs_status_extract.rpt", text_cache, LVS_STATUS_RE, 1500
    )
    port_lines = write_line_extract(
        bundle / "netlist_port_extract.rpt", text_cache, PORT_RE, 1000
    )
    pin_counts = write_pin_name_audit(bundle / "pin_name_audit.rpt", text_cache)
    write_hash_manifest(bundle / "hashes.sha256", before_records, external)

    after_records, after_errors = snapshot_tree(source, hash_files=False)
    errors.extend(after_errors)
    source_stable = before_signature == metadata_signature(after_records)
    if not source_stable:
        errors.append("SOURCE_METADATA_CHANGED_DURING_COLLECTION")

    run_pvs_count = sum(
        Path(str(record["relative_path"])).name == "run.pvs" for record in selected
    )
    lvs_control_count = sum(
        Path(str(record["relative_path"])).name == "pvslvsctl" for record in selected
    )
    if run_pvs_count == 0:
        errors.append("RUN_PVS_MISSING")
    if lvs_control_count == 0:
        errors.append("PVSLVSCTL_MISSING")

    status_path = bundle / "collection_status.rpt"
    status_path.write_text(
        "LABEL=SPADMIC_TX_PACKET_CORE_HV_LVS_READ_ONLY_INTAKE\n"
        "POLICY=READ_ONLY_NO_PVS_NO_SOURCE_WRITES\n"
        f"SOURCE_RUN={source}\n"
        f"BUNDLE_ROOT={bundle}\n"
        f"SOURCE_ENTRY_COUNT={len(before_records)}\n"
        f"SOURCE_FILE_COUNT={sum(item['type'] == 'file' for item in before_records)}\n"
        f"SELECTED_TEXT_COUNT={sum(item['copy_status'] == 'COPIED' for item in selected)}\n"
        f"EXTERNAL_REFERENCE_COUNT={len(external)}\n"
        f"COPIED_PROJECT_NETLIST_COUNT={len(copied_netlists)}\n"
        f"RUN_PVS_COUNT={run_pvs_count}\n"
        f"PVSLVSCTL_COUNT={lvs_control_count}\n"
        f"INPUT_CONTRACT_LINE_COUNT={contract_lines}\n"
        f"PVS_TOOL_VERSION_LINE_COUNT={tool_lines}\n"
        f"LVS_STATUS_LINE_COUNT={lvs_lines}\n"
        f"NETLIST_PORT_LINE_COUNT={port_lines}\n"
        f"DOUBLE_BRACKET_OCCURRENCE_COUNT={pin_counts['DOUBLE_BRACKET']}\n"
        f"EMPTY_DOUBLE_BRACKET_OCCURRENCE_COUNT={pin_counts['EMPTY_DOUBLE_BRACKET']}\n"
        f"DOUBLE_ANGLE_OCCURRENCE_COUNT={pin_counts['DOUBLE_ANGLE']}\n"
        f"SOURCE_STABILITY_STATUS={'PASS' if source_stable else 'FAIL'}\n"
        f"ERROR_COUNT={len(errors)}\n"
        + "".join(f"ERROR={clean_field(error)}\n" for error in errors)
        + f"STATUS={'PASS' if not errors and source_stable else 'FAIL'}\n",
        encoding="utf-8",
    )

    git_root = copy_git_candidate(bundle, selected, args.git_max_bytes)
    print(status_path.read_text(encoding="utf-8"), end="")
    print(f"GIT_TEXT_CANDIDATE={git_root}")
    if errors or not source_stable:
        raise SystemExit(8)


if __name__ == "__main__":
    main()
