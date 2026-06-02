#!/usr/bin/env python3
"""Unit tests for O2 raw LFSR tag software decode."""

from __future__ import annotations

import tempfile
from pathlib import Path

from fast_tag_decode import (
    DEFAULT_COLUMNS,
    DEFAULT_SEED,
    DEFAULT_WIDTH,
    LEGACY_BINARY_NFAST,
    RAW_GALOIS_TAG,
    RAW_LFSR_TAG,
    annotate_rows,
    build_tag_to_index_table,
    decode_table_hash,
    decode_hit,
    decode_raw_tag,
    generate_galois_sequence,
    generate_lfsr_sequence,
)


def check(cond: bool, label: str) -> None:
    if not cond:
        raise AssertionError(label)
    print(f"[PASS] {label}")


def main() -> int:
    seq = generate_lfsr_sequence(DEFAULT_WIDTH, DEFAULT_SEED)
    check(len(seq) == 127, "7-bit LFSR has 127 states")
    check(len(set(seq)) == 127, "7-bit LFSR has no early repeat")
    check(0 not in seq, "7-bit LFSR excludes zero")
    check(seq[0] == 1, "sequence starts at seed")
    check(seq[5] == 32, "known count 5 tag is raw value 32")

    table = build_tag_to_index_table()
    check(table[seq[73]] == 73, "tag-to-index table decodes count 73")
    check(decode_raw_tag(seq[5], nf=5, mode=RAW_LFSR_TAG) == 5, "raw tag decode uses table")
    check(decode_raw_tag(17, nf=5, mode=LEGACY_BINARY_NFAST) == 17, "legacy mode passes binary through")
    check(decode_raw_tag(seq[5], nf=5, column_offsets=[0, 1, 2, 3, 4, 5, 6, 7]) == 10,
          "per-nf offset is applied")
    check(decode_raw_tag(seq[5], nf=5, detection_offset=2) == 7, "detection offset is applied")
    check(decode_hit({"nf": 7, "nfast_hit": seq[12]}) == 12, "decode_hit reads hit mapping")

    gseq = generate_galois_sequence(DEFAULT_WIDTH, DEFAULT_SEED)
    check(len(gseq) == 127, "7-bit Galois candidate has 127 states")
    check(len(set(gseq)) == 127, "7-bit Galois candidate has no early repeat")
    check(0 not in gseq, "7-bit Galois candidate excludes zero")
    check(gseq[:8] == [1, 2, 4, 8, 16, 32, 64, 3], "known Galois prefix matches mask")
    gtable = build_tag_to_index_table(mode=RAW_GALOIS_TAG)
    check(gtable[gseq[73]] == 73, "Galois table decodes count 73")
    check(decode_raw_tag(gseq[5], nf=2, mode=RAW_GALOIS_TAG) == 5,
          "raw Galois tag decode uses table")
    check(decode_table_hash(RAW_LFSR_TAG) != decode_table_hash(RAW_GALOIS_TAG),
          "decode table hashes distinguish encodings")

    rows = annotate_rows([
        {"conv_id": 1, "hit_idx": 0, "nf": 5, "nfast_hit": seq[5]},
        {"conv_id": 1, "hit_idx": 1, "nf": 7, "nfast_hit": seq[73]},
    ])
    check(rows[0]["nfast_raw_tag"] == seq[5], "annotate keeps raw tag")
    check(rows[0]["nfast_decoded"] == 5, "annotate adds decoded nfast")
    check(rows[0]["nfast_encoding"] == RAW_LFSR_TAG, "annotate adds encoding metadata")
    check(rows[0]["tag_columns"] == DEFAULT_COLUMNS, "annotate adds tag column count")

    try:
        decode_raw_tag(0, nf=0)
    except ValueError:
        print("[PASS] invalid zero tag is rejected")
    else:
        raise AssertionError("invalid zero tag was accepted")

    with tempfile.TemporaryDirectory() as td:
        in_csv = Path(td) / "in.csv"
        out_csv = Path(td) / "out.csv"
        meta_json = Path(td) / "meta.json"
        in_csv.write_text("nf,nfast_hit\n5,32\n", encoding="utf-8")
        from fast_tag_decode import main as cli_main
        import sys

        old_argv = sys.argv
        try:
            sys.argv = [
                "fast_tag_decode.py",
                "--input-csv", str(in_csv),
                "--output-csv", str(out_csv),
                "--metadata-json", str(meta_json),
                "--self-test",
            ]
            check(cli_main() == 0, "CLI decode returns success")
        finally:
            sys.argv = old_argv
        text = out_csv.read_text(encoding="utf-8")
        check("nfast_decoded" in text and "raw_lfsr_tag" in text, "CLI output has decoded column and metadata")
        meta_text = meta_json.read_text(encoding="utf-8")
        check('"nfast_encoding": "raw_lfsr_tag"' in meta_text,
              "CLI metadata JSON records raw tag mode")
        check('"decode_table_hash":' in meta_text, "CLI metadata JSON records decode table hash")

    print("TEST PASSED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
