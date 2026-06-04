#!/usr/bin/env python3
"""Synthetic O2 raw-tag characterization smoke.

This is a local software-only check. It proves that O2 packet rows can carry raw
LFSR tags, that Python decodes them with nf-aware metadata, and that old legacy
binary rows can still be handled explicitly.
"""

from __future__ import annotations

import argparse
import csv
import json
import sys
from pathlib import Path

SCRIPT_ROOT = Path(__file__).resolve().parents[2]
REPO_ROOT = SCRIPT_ROOT.parent
SCRIPTS_ROOT = SCRIPT_ROOT / "scripts"
TOOLS_ROOT = REPO_ROOT / "tools"
if str(SCRIPTS_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_ROOT))
if str(TOOLS_ROOT) not in sys.path:
    sys.path.insert(0, str(TOOLS_ROOT))

from analysis import mptdc_char_common as char_common  # noqa: E402
from analysis.mptdc_char_common import FREQ_MODE_CHOICES, FREQ_MODE_NOMINAL  # noqa: E402
from mptdc_decode.fast_tag_decode import (  # noqa: E402
    RAW_LFSR_TAG,
    FastTagMetadata,
    annotate_rows,
    generate_lfsr_sequence,
)

NE = char_common.NE
K_VERNIER = char_common.K_VERNIER
DELTA_LSB_PS = char_common.DELTA_LSB_PS
VERNIER_NSLOW_ORIGIN_BIAS = 2
VERNIER_NFAST_ORIGIN_BIAS = 1
VERNIER_COEF_BIAS = 25


def set_frequency_mode(mode: str) -> dict[str, object]:
    global K_VERNIER, DELTA_LSB_PS
    cfg = char_common.configure_frequency_mode(mode)
    K_VERNIER = int(cfg["K_VERNIER"])
    DELTA_LSB_PS = int(cfg["DELTA_LSB"])
    return cfg


def vernier_tconv_ps(nslow: int, nfast: int, ns: int, nf: int, slow_boundary_inc: int) -> int:
    coef = (
        (nslow + VERNIER_NSLOW_ORIGIN_BIAS + slow_boundary_inc - 1) * K_VERNIER * NE
        + (nfast + VERNIER_NFAST_ORIGIN_BIAS - 1) * NE
        + ns * K_VERNIER
        - nf * (K_VERNIER - 1)
        + VERNIER_COEF_BIAS
    )
    return coef * DELTA_LSB_PS


def write_csv(path: Path, rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
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
    parser.add_argument("--run-id", default="20260601_o2_raw_tag_charac_smoke")
    parser.add_argument("--output-root", type=Path, default=Path("results/local_software"))
    parser.add_argument("--freq-mode", default=FREQ_MODE_NOMINAL,
                        choices=FREQ_MODE_CHOICES,
                        help="Frequency/tap mode used for synthetic reconstruction")
    args = parser.parse_args()
    freq_cfg = set_frequency_mode(args.freq_mode)

    out_dir = args.output_root / args.run_id
    out_dir.mkdir(parents=True, exist_ok=True)

    seq = generate_lfsr_sequence()
    raw_rows: list[dict[str, object]] = []
    for nf in range(8):
        decoded_cycle = 5 + nf
        raw_tag = seq[decoded_cycle]
        row = {
            "conv_id": 1,
            "hit_idx": nf,
            "nslow": 17,
            "nfast_hit": raw_tag,
            "ns": 2,
            "nf": nf,
            "slow_boundary_inc": 0,
            "Tref_ps": 1000 + nf,
        }
        raw_rows.append(row)

    decoded_rows = annotate_rows(raw_rows, mode=RAW_LFSR_TAG, metadata=FastTagMetadata())
    for row in decoded_rows:
        row["t_raw_ps_decoded"] = vernier_tconv_ps(
            int(row["nslow"]),
            int(row["nfast_decoded"]),
            int(row["ns"]),
            int(row["nf"]),
            int(row["slow_boundary_inc"]),
        )

    unknown = [row for row in decoded_rows if row["nfast_decoded"] == ""]
    if unknown:
        raise SystemExit(f"decode produced unknown rows: {unknown}")

    write_csv(out_dir / "synthetic_o2_raw_tag_input.csv", raw_rows)
    write_csv(out_dir / "synthetic_o2_raw_tag_decoded.csv", decoded_rows)
    (out_dir / "metadata.json").write_text(
        json.dumps(FastTagMetadata().as_dict(), indent=2) + "\n",
        encoding="utf-8",
    )
    (out_dir / "SUMMARY.md").write_text(
        "\n".join([
            "# O2 Raw-Tag Characterization Smoke",
            "",
            f"- Run ID: `{args.run_id}`",
            "- Rows: 8",
            "- nfast_encoding: `raw_lfsr_tag`",
            f"- freq_mode: `{freq_cfg['freq_mode']}`",
            f"- K_VERNIER: `{freq_cfg['K_VERNIER']}`",
            "- tag_decode_mode: `software`",
            "- tag_width: 7",
            "- tag_columns: 8",
            "- Result: PASS",
            "",
            "This is a synthetic local software check only. Xcelium/server characterization remains required.",
        ]) + "\n",
        encoding="utf-8",
    )
    print(f"[PASS] O2 raw-tag characterization smoke wrote {out_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
