#!/usr/bin/env python3
"""VIP characterization dataset schema helpers.

The SystemVerilog environment emits stable CSV/JSONL event logs for CDV and
characterization.  This module validates the common columns and normalizes older
CSV-only characterization rows into the VIP column vocabulary used by the
6D LUT calibration flow.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import pandas as pd


REQUIRED_COLUMNS = {
    "seed",
    "accepted",
    "rejected",
    "t_raw_ps",
    "nslow",
    "nfast_hit",
    "stop_phase_disc",
    "phase0_snap",
    "hit_idx",
    "slow_boundary_inc",
}

VIP_COLUMNS = [
    "schema_version",
    "test_name",
    "seed",
    "config_id",
    "stage",
    "train_valid_split",
    "attempt_id",
    "event_id",
    "conv_id",
    "ctx_id",
    "hit_idx",
    "t_start_fs",
    "t_stop_fs",
    "true_dt_fs",
    "t_start_ps",
    "t_stop_ps",
    "true_dt_ps",
    "accepted",
    "rejected",
    "reject_reason",
    "close_reason",
    "max_hits",
    "out_mode",
    "input_sel",
    "nslow",
    "nfast_hit",
    "ns",
    "nf",
    "ns_inf",
    "nf_inf",
    "stop_phase_disc",
    "phase0_snap",
    "slow_boundary_inc",
    "hit_count",
    "flags",
    "t_raw_ps",
    "reconstructed_time_pre_cal_ps",
    "reconstructed_time_post_cal_ps",
    "residual_pre_cal_ps",
    "residual_post_cal_ps",
]


def read_dataset(path: Path) -> pd.DataFrame:
    if path.suffix == ".jsonl":
        rows = [json.loads(line) for line in path.read_text().splitlines() if line.strip()]
        return pd.DataFrame(rows)
    return pd.read_csv(path)


def validate(df: pd.DataFrame) -> dict[str, object]:
    missing = sorted(REQUIRED_COLUMNS - set(df.columns))
    if "hit_idx" in df.columns:
        hit_idx = pd.to_numeric(df["hit_idx"], errors="coerce").fillna(-1)
    else:
        hit_idx = pd.Series([-1] * len(df))
    hit_rows = int((hit_idx >= 0).sum())
    return {
        "rows": int(len(df)),
        "hit_rows": hit_rows,
        "missing_required_columns": missing,
        "vip_columns_present": sorted(set(VIP_COLUMNS) & set(df.columns)),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("datasets", nargs="+", type=Path)
    parser.add_argument("--summary-json", type=Path)
    args = parser.parse_args()

    summaries = {}
    for path in args.datasets:
      df = read_dataset(path)
      summaries[str(path)] = validate(df)

    text = json.dumps(summaries, indent=2)
    print(text)
    if args.summary_json:
        args.summary_json.parent.mkdir(parents=True, exist_ok=True)
        args.summary_json.write_text(text + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
