#!/usr/bin/env python3
"""Decode O2 raw local fast LFSR tags in software.

O2_RAW_TAG_SW_DECODE keeps the packet bit layout unchanged but changes the
meaning of HIT.nfast: it carries the raw 7-bit local fast-column LFSR tag.
Software must decode it with the fast-column index (`nf`) and calibration
offset metadata before using Vernier reconstruction.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Mapping, MutableMapping, Sequence


DEFAULT_WIDTH = 7
DEFAULT_SEED = 1
DEFAULT_COLUMNS = 8
RAW_LFSR_TAG = "raw_lfsr_tag"
RAW_GALOIS_TAG = "raw_galois_tag"
LEGACY_BINARY_NFAST = "legacy_binary_nfast"
SOFTWARE_DECODE = "software"
IDENTITY_DECODE = "identity"
GALOIS_MASK = 0x03
TAG_ENCODING_CHOICES = (LEGACY_BINARY_NFAST, RAW_LFSR_TAG, RAW_GALOIS_TAG)


def tag_type_for_encoding(nfast_encoding: str) -> str:
    if nfast_encoding == LEGACY_BINARY_NFAST:
        return "legacy_binary_counter"
    if nfast_encoding == RAW_LFSR_TAG:
        return "fibonacci_lfsr"
    if nfast_encoding == RAW_GALOIS_TAG:
        return "galois_lfsr"
    raise ValueError(f"Unsupported nfast encoding mode: {nfast_encoding}")


def decode_mode_for_encoding(nfast_encoding: str) -> str:
    return IDENTITY_DECODE if nfast_encoding == LEGACY_BINARY_NFAST else SOFTWARE_DECODE


@dataclass(frozen=True)
class FastTagMetadata:
    nfast_encoding: str = RAW_LFSR_TAG
    tag_decode_mode: str = SOFTWARE_DECODE
    lfsr_width: int = DEFAULT_WIDTH
    lfsr_seed: int = DEFAULT_SEED
    tag_columns: int = DEFAULT_COLUMNS
    column_offsets_version: str = "o2_initial_zero_offsets"

    def as_dict(self) -> dict[str, object]:
        decode_mode = decode_mode_for_encoding(self.nfast_encoding)
        return {
            "nfast_encoding": self.nfast_encoding,
            "tag_decode_mode": decode_mode,
            "tag_type": tag_type_for_encoding(self.nfast_encoding),
            "lfsr_width": self.lfsr_width,
            "tag_width": self.lfsr_width,
            "lfsr_seed": self.lfsr_seed,
            "tag_columns": self.tag_columns,
            "column_offsets_version": self.column_offsets_version,
            "decode_table_hash": decode_table_hash(self.nfast_encoding, self.lfsr_width, self.lfsr_seed),
        }


def lfsr_next(tag: int, width: int = DEFAULT_WIDTH) -> int:
    """Return next state for x^7 + x^6 + 1 style Fibonacci LFSR."""
    if width != 7:
        raise ValueError("Only the verified 7-bit O2 polynomial is supported")
    mask = (1 << width) - 1
    tag &= mask
    feedback = ((tag >> (width - 1)) ^ (tag >> (width - 2))) & 1
    return ((tag << 1) & mask) | feedback


def galois_next(tag: int, width: int = DEFAULT_WIDTH, mask: int = GALOIS_MASK) -> int:
    """Return next state for the O6C candidate 7-bit left-shift Galois LFSR."""
    if width != 7:
        raise ValueError("Only the verified 7-bit O6C Galois candidate is supported")
    full_mask = (1 << width) - 1
    tag &= full_mask
    feedback = (tag >> (width - 1)) & 1
    nxt = (tag << 1) & full_mask
    if feedback:
        nxt ^= mask
    return nxt


def generate_lfsr_sequence(width: int = DEFAULT_WIDTH, seed: int = DEFAULT_SEED) -> list[int]:
    return generate_tag_sequence(RAW_LFSR_TAG, width, seed)


def generate_galois_sequence(width: int = DEFAULT_WIDTH, seed: int = DEFAULT_SEED) -> list[int]:
    return generate_tag_sequence(RAW_GALOIS_TAG, width, seed)


def generate_tag_sequence(
    mode: str = RAW_LFSR_TAG,
    width: int = DEFAULT_WIDTH,
    seed: int = DEFAULT_SEED,
) -> list[int]:
    if seed == 0:
        raise ValueError("tag seed must be non-zero")
    if mode == LEGACY_BINARY_NFAST:
        return list(range(1 << width))
    if mode not in (RAW_LFSR_TAG, RAW_GALOIS_TAG):
        raise ValueError(f"Unsupported nfast encoding mode: {mode}")
    count = (1 << width) - 1
    seq: list[int] = []
    state = seed
    seen: set[int] = set()
    for _ in range(count):
        if state == 0:
            raise ValueError("LFSR entered zero state")
        if state in seen:
            raise ValueError(f"tag sequence repeated early at state {state}")
        seq.append(state)
        seen.add(state)
        if mode == RAW_LFSR_TAG:
            state = lfsr_next(state, width)
        else:
            state = galois_next(state, width)
    if state != seed:
        raise ValueError("tag sequence did not return to seed after full sequence")
    return seq


def build_tag_to_index_table(
    width: int = DEFAULT_WIDTH,
    seed: int = DEFAULT_SEED,
    mode: str = RAW_LFSR_TAG,
) -> dict[int, int]:
    return {tag: idx for idx, tag in enumerate(generate_tag_sequence(mode, width, seed))}


def decode_table_hash(
    mode: str = RAW_LFSR_TAG,
    width: int = DEFAULT_WIDTH,
    seed: int = DEFAULT_SEED,
) -> str:
    if mode == LEGACY_BINARY_NFAST:
        return ""
    payload = {
        "mode": mode,
        "width": width,
        "seed": seed,
        "sequence": generate_tag_sequence(mode, width, seed),
    }
    encoded = json.dumps(payload, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def _offset_for_nf(column_offsets: Mapping[int, int] | Sequence[int] | None, nf: int) -> int:
    if column_offsets is None:
        return 0
    if isinstance(column_offsets, Mapping):
        return int(column_offsets.get(nf, 0))
    return int(column_offsets[nf])


def decode_raw_tag(
    raw_tag: int,
    nf: int,
    *,
    mode: str = RAW_LFSR_TAG,
    width: int = DEFAULT_WIDTH,
    seed: int = DEFAULT_SEED,
    column_offsets: Mapping[int, int] | Sequence[int] | None = None,
    detection_offset: int = 0,
) -> int:
    """Decode packet HIT.nfast according to the declared encoding mode."""
    raw_tag = int(raw_tag)
    nf = int(nf)
    if mode == LEGACY_BINARY_NFAST:
        return raw_tag
    if mode not in (RAW_LFSR_TAG, RAW_GALOIS_TAG):
        raise ValueError(f"Unsupported nfast encoding mode: {mode}")

    table = build_tag_to_index_table(width, seed, mode=mode)
    if raw_tag not in table:
        raise ValueError(f"Invalid raw tag 0x{raw_tag:x} for mode={mode}, width={width}, seed={seed}")
    return table[raw_tag] + _offset_for_nf(column_offsets, nf) + int(detection_offset)


def decode_hit(
    hit: Mapping[str, object],
    *,
    mode: str = RAW_LFSR_TAG,
    nf_key: str = "nf",
    nfast_key: str = "nfast_hit",
    **kwargs,
) -> int:
    return decode_raw_tag(int(hit[nfast_key]), int(hit[nf_key]), mode=mode, **kwargs)


def annotate_rows(
    rows: Iterable[Mapping[str, object]],
    *,
    mode: str = RAW_LFSR_TAG,
    metadata: FastTagMetadata | None = None,
) -> list[dict[str, object]]:
    meta = metadata or FastTagMetadata(nfast_encoding=mode)
    annotated: list[dict[str, object]] = []
    for row in rows:
        out: dict[str, object] = dict(row)
        raw = int(out.get("nfast_hit", out.get("nfast", 0)))
        nf = int(out.get("nf", 0))
        out["nfast_raw_tag"] = raw if mode != LEGACY_BINARY_NFAST else ""
        out["nfast_decoded"] = decode_raw_tag(raw, nf, mode=mode)
        out.update(meta.as_dict())
        annotated.append(out)
    return annotated


def _read_csv(path: Path) -> list[dict[str, object]]:
    with path.open(newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def _write_csv(path: Path, rows: Sequence[Mapping[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if not rows:
        path.write_text("", encoding="utf-8")
        return
    fieldnames: list[str] = []
    for row in rows:
        for key in row:
            if key not in fieldnames:
                fieldnames.append(key)
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input-csv", type=Path)
    parser.add_argument("--output-csv", type=Path)
    parser.add_argument("--metadata-json", type=Path)
    parser.add_argument("--mode", choices=TAG_ENCODING_CHOICES, default=RAW_LFSR_TAG)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    if args.self_test:
        seq = generate_lfsr_sequence()
        assert len(seq) == 127
        assert len(set(seq)) == 127
        assert 0 not in seq
        gseq = generate_galois_sequence()
        assert len(gseq) == 127
        assert len(set(gseq)) == 127
        assert 0 not in gseq
        table = build_tag_to_index_table()
        for i, tag in enumerate(seq):
            assert table[tag] == i

    metadata = FastTagMetadata(nfast_encoding=args.mode)
    if args.input_csv:
        if not args.output_csv:
            raise SystemExit("--output-csv is required with --input-csv")
        rows = annotate_rows(_read_csv(args.input_csv), mode=args.mode, metadata=metadata)
        _write_csv(args.output_csv, rows)

    if args.metadata_json:
        args.metadata_json.parent.mkdir(parents=True, exist_ok=True)
        args.metadata_json.write_text(json.dumps(metadata.as_dict(), indent=2) + "\n", encoding="utf-8")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
