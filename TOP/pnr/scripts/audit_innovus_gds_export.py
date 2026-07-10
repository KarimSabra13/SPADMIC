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


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--gds", required=True, type=Path)
    parser.add_argument("--log", required=True, type=Path)
    parser.add_argument("--stream-map", required=True, type=Path)
    parser.add_argument("--status", required=True, type=Path)
    parser.add_argument("--min-gds-bytes", type=int, default=1_000_000)
    args = parser.parse_args()
    gds = args.gds.resolve()
    log_path = args.log.resolve()
    stream_map = args.stream_map.resolve()
    log = log_path.read_text(errors="replace")
    errors = []
    if not gds.is_file() or gds.stat().st_size < args.min_gds_bytes:
        errors.append("gds_missing_or_too_small")
    map_hash = digest(stream_map)
    if map_hash != KNOWN_STREAM_MAP_SHA256:
        errors.append(f"stream_map_hash_drift={map_hash}")
    command_pattern = rf"streamOut\s+{re.escape(str(gds))}.*-mapFile\s+{re.escape(str(stream_map))}"
    if not re.search(command_pattern, log):
        errors.append("mapped_streamout_command_missing")
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
        f"GDS_LAYER_MAP_STATUS={'PASS' if not errors else 'FAIL'}\n"
        f"GDS={gds}\n"
        f"GDS_BYTES={gds.stat().st_size if gds.is_file() else 0}\n"
        f"GDS_SHA256={digest(gds) if gds.is_file() else 'MISSING'}\n"
        f"STREAM_MAP={stream_map}\n"
        f"STREAM_MAP_SHA256={map_hash}\n"
        f"INNOVUS_LOG={log_path}\n"
        f"ERROR_COUNT={len(errors)}\n"
        + "".join(f"ERROR={error}\n" for error in errors)
    )
    print(args.status.read_text(), end="")
    if errors:
        raise SystemExit(8)


if __name__ == "__main__":
    main()
