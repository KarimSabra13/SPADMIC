#!/usr/bin/env python3
"""Generate and inspect MPTDC fast-tag decode tables.

This wrapper keeps characterization callers inside the MPTDC scripts tree while
reusing the maintained implementation in tools/mptdc_decode/fast_tag_decode.py.
It does not change packet parsing or packet layout.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

TOOLS_ROOT = Path(__file__).resolve().parents[3] / "tools"
if str(TOOLS_ROOT) not in sys.path:
    sys.path.insert(0, str(TOOLS_ROOT))

from mptdc_decode.fast_tag_decode import (  # noqa: E402
    RAW_GALOIS_TAG,
    RAW_LFSR_TAG,
    FastTagMetadata,
    build_tag_to_index_table,
    decode_table_hash,
)


def table_payload(mode: str) -> dict[str, object]:
    metadata = FastTagMetadata(nfast_encoding=mode).as_dict()
    table = build_tag_to_index_table(mode=mode)
    return {
        "metadata": metadata,
        "decode_table_hash": decode_table_hash(mode),
        "tag_to_index": {str(tag): idx for tag, idx in sorted(table.items())},
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mode", choices=[RAW_LFSR_TAG, RAW_GALOIS_TAG], default=RAW_LFSR_TAG)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--write-default-tables", action="store_true")
    args = parser.parse_args()

    if args.write_default_tables:
        out_dir = args.output or Path(__file__).resolve().parent / "tag_decode_tables"
        out_dir.mkdir(parents=True, exist_ok=True)
        for mode in (RAW_LFSR_TAG, RAW_GALOIS_TAG):
            path = out_dir / f"{mode}.json"
            path.write_text(json.dumps(table_payload(mode), indent=2, sort_keys=True) + "\n",
                            encoding="utf-8")
            print(f"[TAG_DECODE] wrote {path}")
        return 0

    payload = table_payload(args.mode)
    text = json.dumps(payload, indent=2, sort_keys=True) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(text, encoding="utf-8")
        print(f"[TAG_DECODE] wrote {args.output}")
    else:
        print(text, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
