#!/usr/bin/env python3
"""Gate an Innovus GDS export against the official XFAB streamout map."""

from __future__ import annotations

import argparse
import hashlib
import re
from pathlib import Path


KNOWN_STREAM_MAP_SHA256 = "4d7b850f74ef193b6bc7b15b1e52fd38ba61cc4a6e1b283c4201343a20ad233d"


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def same_file_path(left: str | Path, right: str | Path) -> bool:
    """Compare lexical paths while accepting symlinked installation roots."""
    left_path = Path(str(left).strip("{}\"'")).expanduser()
    right_path = Path(str(right).strip("{}\"'")).expanduser()
    try:
        return left_path.resolve(strict=False) == right_path.resolve(strict=False)
    except OSError:
        return left_path.absolute() == right_path.absolute()


def mapped_streamout_command(
    log: str,
    gds: Path,
    stream_map: Path,
    required_merge: Path | None = None,
) -> tuple[bool, bool]:
    """Find a mapped streamOut command and optionally its required merge GDS."""
    mapped = False
    merged = required_merge is None
    for line in log.splitlines():
        if "streamOut" not in line or "-mapFile" not in line:
            continue
        gds_match = re.search(r"\bstreamOut\s+(\S+)", line)
        map_match = re.search(r"\s-mapFile\s+(\S+)", line)
        if not gds_match or not map_match:
            continue
        if not same_file_path(gds_match.group(1), gds):
            continue
        if not same_file_path(map_match.group(1), stream_map):
            continue
        mapped = True
        if required_merge is None:
            merged = True
            continue
        merge_match = re.search(r"\s-merge\s+(.+?)(?:\s+-\w+|$)", line)
        if not merge_match:
            continue
        merge_tokens = re.findall(r"[^\s{}]+", merge_match.group(1))
        if any(same_file_path(token, required_merge) for token in merge_tokens):
            merged = True
    return mapped, merged


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--gds", required=True, type=Path)
    parser.add_argument("--log", required=True, type=Path)
    parser.add_argument("--stream-map", required=True, type=Path)
    parser.add_argument("--required-merge", type=Path)
    parser.add_argument("--status", required=True, type=Path)
    parser.add_argument("--min-gds-bytes", type=int, default=100_000)
    args = parser.parse_args()
    gds = args.gds.expanduser().absolute()
    log_path = args.log.expanduser().absolute()
    stream_map = args.stream_map.expanduser().absolute()
    required_merge = (
        args.required_merge.expanduser().absolute() if args.required_merge else None
    )
    log = log_path.read_text(errors="replace")
    errors = []
    file_ok = gds.is_file() and gds.stat().st_size >= args.min_gds_bytes
    if not file_ok:
        errors.append("gds_missing_or_too_small")
    map_hash = digest(stream_map)
    map_hash_ok = map_hash == KNOWN_STREAM_MAP_SHA256
    if not map_hash_ok:
        errors.append(f"stream_map_hash_drift={map_hash}")
    mapped, merged = mapped_streamout_command(log, gds, stream_map, required_merge)
    if not mapped:
        errors.append("mapped_streamout_command_missing")
    if required_merge is not None and not merged:
        errors.append("required_merge_gds_missing")
    if not re.search(r"Streamout is finished", log, re.I):
        errors.append("streamout_completion_missing")
    if re.search(r"\*\*ERROR.*(?:streamOut|GDS|mapFile)", log, re.I):
        errors.append("streamout_error_in_log")
    args.status.parent.mkdir(parents=True, exist_ok=True)
    if args.status.exists():
        raise SystemExit(f"immutable export status exists: {args.status}")
    args.status.write_text(
        "LABEL=SPADMIC_INNOVUS_GDS_EXPORT_AUDIT\n"
        f"STATUS={'PASS' if not errors else 'FAIL'}\n"
        f"GDS_FILE_STATUS={'PASS' if file_ok else 'FAIL'}\n"
        f"GDS_LAYER_MAP_STATUS={'PASS' if map_hash_ok and mapped else 'FAIL'}\n"
        f"GDS_MERGE_STATUS={'PASS' if merged else 'FAIL'}\n"
        f"GDS={gds}\n"
        f"GDS_BYTES={gds.stat().st_size if gds.is_file() else 0}\n"
        f"GDS_SHA256={digest(gds) if gds.is_file() else 'MISSING'}\n"
        f"STREAM_MAP={stream_map}\n"
        f"STREAM_MAP_RESOLVED={stream_map.resolve(strict=False)}\n"
        f"STREAM_MAP_SHA256={map_hash}\n"
        f"REQUIRED_MERGE={required_merge if required_merge else 'NONE'}\n"
        f"INNOVUS_LOG={log_path}\n"
        f"ERROR_COUNT={len(errors)}\n"
        + "".join(f"ERROR={error}\n" for error in errors)
    )
    print(args.status.read_text(), end="")
    if errors:
        raise SystemExit(8)


if __name__ == "__main__":
    main()
