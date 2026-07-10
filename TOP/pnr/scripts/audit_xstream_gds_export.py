#!/usr/bin/env python3
"""Gate an OA XStream export and the XH018 stream layer table by evidence."""

from __future__ import annotations

import argparse
import hashlib
import re
from pathlib import Path


KNOWN_LAYER_TABLE_SHA256 = "3198c31b841a29b1126206f7962632fd7f6dc239c53931962cd57327d2320869"
EXPECTED_METALS = {
    "MET1": (16, 0),
    "MET2": (18, 0),
    "MET3": (28, 0),
    "METTP": (33, 0),
}


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--gds", required=True, type=Path)
    parser.add_argument("--log", required=True, type=Path)
    parser.add_argument("--layer-table", required=True, type=Path)
    parser.add_argument("--status", required=True, type=Path)
    parser.add_argument("--min-gds-bytes", type=int, default=1_000_000)
    args = parser.parse_args()
    gds = args.gds.resolve()
    log = args.log.read_text(errors="replace")
    layer_text = args.layer_table.read_text(errors="replace")
    errors = []
    completion = re.search(r"Translation completed\.\s*'0' error\(s\)", log)
    if not completion:
        errors.append("xstream_zero_error_completion_missing")
    if not gds.is_file() or gds.stat().st_size < args.min_gds_bytes:
        errors.append("gds_missing_or_too_small")
    for layer, (number, datatype) in EXPECTED_METALS.items():
        pattern = rf"^\s*{layer}\s+drawing\s+{number}\s+{datatype}\s*$"
        if not re.search(pattern, layer_text, re.M | re.I):
            errors.append(f"layer_mapping_missing={layer}:{number}:{datatype}")
    table_hash = digest(args.layer_table)
    if table_hash != KNOWN_LAYER_TABLE_SHA256:
        errors.append(f"layer_table_hash_drift={table_hash}")
    args.status.parent.mkdir(parents=True, exist_ok=True)
    if args.status.exists():
        raise SystemExit(f"immutable layer-map status exists: {args.status}")
    args.status.write_text(
        "LABEL=SPADMIC_XSTREAM_GDS_EXPORT_AUDIT\n"
        f"STATUS={'PASS' if not errors else 'FAIL'}\n"
        f"GDS_LAYER_MAP_STATUS={'PASS' if not errors else 'FAIL'}\n"
        f"GDS={gds}\n"
        f"GDS_BYTES={gds.stat().st_size if gds.is_file() else 0}\n"
        f"GDS_SHA256={digest(gds) if gds.is_file() else 'MISSING'}\n"
        f"LAYER_TABLE={args.layer_table.resolve()}\n"
        f"LAYER_TABLE_SHA256={table_hash}\n"
        f"ERROR_COUNT={len(errors)}\n"
        + "".join(f"ERROR={error}\n" for error in errors)
    )
    print(args.status.read_text(), end="")
    if errors:
        raise SystemExit(8)


if __name__ == "__main__":
    main()
