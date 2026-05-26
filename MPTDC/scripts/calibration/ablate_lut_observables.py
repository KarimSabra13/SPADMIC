#!/usr/bin/env python3
"""Measure MPTDC LUT sensitivity to packet-visible observables.

This script reproduces the final calibration split used by calibrate_6d_lut.py:
the first N lexicographically sorted seed CSV files train the LUT, and the next
held-out files validate it.  It then rebuilds and validates several LUTs while
removing one observable at a time.

The slow_boundary_inc case is special: it is not a direct LUT key in the current
model.  It is used to infer ns_inf/nf_inf from t_raw_ps.  Its ablation therefore
forces slow_boundary_inc=0 during inference and reports both inference losses
and post-LUT RMSE.
"""

from __future__ import annotations

import argparse
import gc
import json
import os
import sys
import time
from pathlib import Path

import numpy as np
import pandas as pd

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from calibrate_6d_lut import (  # noqa: E402
    LUT_KEY,
    compute_metrics,
    infer_ns_nf,
    print_skipped_csv_summary,
    read_seed_csv,
)


VARIANTS = [
    {
        "name": "full_reference",
        "description": "Full reference key and nominal ns/nf inference",
        "drop_key_fields": [],
        "force_slow_boundary_zero": False,
    },
    {
        "name": "drop_phase0_snap",
        "description": "Remove phase0_snap from the LUT key",
        "drop_key_fields": ["phase0_snap"],
        "force_slow_boundary_zero": False,
    },
    {
        "name": "drop_stop_phase_disc",
        "description": "Remove stop_phase_disc from the LUT key",
        "drop_key_fields": ["stop_phase_disc"],
        "force_slow_boundary_zero": False,
    },
    {
        "name": "drop_slow_boundary_inc",
        "description": "Infer ns/nf with slow_boundary_inc unavailable",
        "drop_key_fields": [],
        "force_slow_boundary_zero": True,
    },
]


def seed_files(path: Path) -> list[Path]:
    return sorted(path.glob("seed_*.csv"))


def lut_key_for_variant(variant: dict) -> list[str]:
    dropped = set(variant["drop_key_fields"])
    return [col for col in LUT_KEY if col not in dropped]


def prepare_frame(df: pd.DataFrame, variant: dict, *, core_only: bool = True) -> tuple[pd.DataFrame, dict]:
    """Prepare one raw CSV frame for a variant and return metadata."""
    meta = {
        "rows_before_core_filter": int(len(df)),
        "rows_after_core_filter": 0,
        "rows_after_inference": 0,
        "rows_inference_failed": 0,
    }

    work = df.copy()
    if core_only:
        work = work[work["nslow"] > 0].copy()
    meta["rows_after_core_filter"] = int(len(work))

    work["offset"] = work["Tref_ps"] - work["t_raw_ps"]
    if variant["force_slow_boundary_zero"]:
        work["slow_boundary_inc_actual"] = work["slow_boundary_inc"]
        work["slow_boundary_inc"] = 0

    infer_ns_nf(work)
    bad = int(work["ns_inf"].isna().sum() + work["nf_inf"].isna().sum())
    work = work.dropna(subset=["ns_inf", "nf_inf"])
    meta["rows_after_inference"] = int(len(work))
    meta["rows_inference_failed"] = int(meta["rows_after_core_filter"] - len(work))
    return work, meta


def add_meta(total: dict, inc: dict) -> None:
    for key, value in inc.items():
        total[key] = int(total.get(key, 0)) + int(value)


def normalize_key(keys):
    if isinstance(keys, tuple):
        return keys
    return (keys,)


def build_lut(train_files: list[Path], variant: dict) -> tuple[pd.DataFrame, dict]:
    key_cols = lut_key_for_variant(variant)
    sums: dict[tuple, float] = {}
    counts: dict[tuple, int] = {}
    meta = {
        "files": len(train_files),
        "usable_files": 0,
        "skipped_files": 0,
        "rows_before_core_filter": 0,
        "rows_after_core_filter": 0,
        "rows_after_inference": 0,
        "rows_inference_failed": 0,
    }
    skipped = []

    for idx, csv_path in enumerate(train_files, start=1):
        frame, skip_reason = read_seed_csv(str(csv_path))
        if frame is None:
            skipped.append({"path": str(csv_path), "reason": skip_reason})
            continue
        meta["usable_files"] += 1
        prepared, prep_meta = prepare_frame(frame, variant)
        add_meta(meta, prep_meta)
        if prepared.empty:
            continue

        grouped = prepared.groupby(key_cols, observed=True)["offset"].agg(["sum", "count"])
        for keys, row in grouped.iterrows():
            key = normalize_key(keys)
            sums[key] = sums.get(key, 0.0) + float(row["sum"])
            counts[key] = counts.get(key, 0) + int(row["count"])

        del frame, prepared, grouped
        gc.collect()
        if idx % 6 == 0 or idx == len(train_files):
            print(
                f"    {variant['name']}: scanned {idx}/{len(train_files)} train files, "
                f"{len(counts):,} bins"
            )

    print_skipped_csv_summary(skipped)
    meta["skipped_files"] = len(skipped)

    if not counts:
        raise ValueError(f"Variant {variant['name']} produced an empty LUT")

    records = []
    for key, count in counts.items():
        records.append((*key, sums[key] / count, count))
    lut = pd.DataFrame(records, columns=key_cols + ["correction", "train_count"])
    lut = lut.set_index(key_cols).sort_index()
    meta["lut_bins"] = int(len(lut))
    meta["min_bin_population"] = int(lut["train_count"].min())
    meta["median_bin_population"] = float(lut["train_count"].median())
    meta["max_bin_population"] = int(lut["train_count"].max())
    return lut, meta


def load_validation(val_files: list[Path], variant: dict) -> tuple[pd.DataFrame, dict]:
    frames = []
    meta = {
        "files": len(val_files),
        "usable_files": 0,
        "skipped_files": 0,
        "rows_before_core_filter": 0,
        "rows_after_core_filter": 0,
        "rows_after_inference": 0,
        "rows_inference_failed": 0,
    }
    skipped = []

    for csv_path in val_files:
        frame, skip_reason = read_seed_csv(str(csv_path))
        if frame is None:
            skipped.append({"path": str(csv_path), "reason": skip_reason})
            continue
        meta["usable_files"] += 1
        prepared, prep_meta = prepare_frame(frame, variant)
        add_meta(meta, prep_meta)
        if not prepared.empty:
            frames.append(prepared)
        del frame

    print_skipped_csv_summary(skipped)
    meta["skipped_files"] = len(skipped)
    if not frames:
        raise ValueError(f"Variant {variant['name']} has no usable validation rows")
    return pd.concat(frames, ignore_index=True), meta


def validate_variant(val_df: pd.DataFrame, lut: pd.DataFrame, key_cols: list[str]) -> tuple[dict, pd.DataFrame]:
    merged = val_df.set_index(key_cols).join(lut["correction"], how="left").reset_index()
    before_match = len(merged)
    matched = merged.dropna(subset=["correction"]).copy()
    matched["cal_ps"] = matched["t_raw_ps"] + matched["correction"]
    matched["error_ps"] = matched["Tref_ps"] - matched["cal_ps"]
    matched["raw_error_ps"] = matched["Tref_ps"] - matched["t_raw_ps"]

    metrics = {
        "rows_before_lut_match": int(before_match),
        "rows_after_lut_match": int(len(matched)),
        "rows_unmatched_lut": int(before_match - len(matched)),
        "lut_coverage_pct": float(100.0 * len(matched) / before_match) if before_match else 0.0,
        "pre_cal": compute_metrics(matched["raw_error_ps"].values, "Pre-calibration"),
        "post_cal": compute_metrics(matched["error_ps"].values, "Post-calibration"),
    }
    return metrics, matched


def summarize_degradation(rows: list[dict]) -> list[dict]:
    ref = next(row for row in rows if row["variant"] == "full_reference")
    ref_rmse = ref["post_rmse_ps"]
    ref_p99 = ref["post_p99_abs_ps"]
    for row in rows:
        row["delta_rmse_ps"] = float(row["post_rmse_ps"] - ref_rmse)
        row["delta_rmse_pct"] = float(100.0 * row["delta_rmse_ps"] / ref_rmse) if ref_rmse else 0.0
        row["delta_p99_abs_ps"] = float(row["post_p99_abs_ps"] - ref_p99)
    return rows


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--train-dir", required=True, help="Directory containing seed_*.csv campaign files")
    parser.add_argument("--out-dir", required=True, help="Directory for ablation JSON/CSV reports")
    parser.add_argument("--train-seeds", type=int, default=24,
                        help="Number of lexicographically sorted seed CSVs used for training")
    parser.add_argument("--val-count", type=int, default=6,
                        help="Number of held-out CSVs after the training split")
    parser.add_argument("--val-max-rows", type=int, default=0,
                        help="Optional validation row cap for smoke/debug runs")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    t0 = time.time()
    train_dir = Path(args.train_dir).resolve()
    out_dir = Path(args.out_dir).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    all_files = seed_files(train_dir)
    if len(all_files) < args.train_seeds + 1:
        raise ValueError(
            f"Need at least {args.train_seeds + 1} seed CSVs in {train_dir}, found {len(all_files)}"
        )
    train_files = all_files[:args.train_seeds]
    val_files = all_files[args.train_seeds:args.train_seeds + args.val_count]
    if not val_files:
        raise ValueError("No held-out validation files selected")

    print("=" * 78)
    print("MPTDC LUT observable ablation")
    print("=" * 78)
    print(f"Train directory : {train_dir}")
    print(f"Training files  : {len(train_files)}")
    print(f"Validation files: {len(val_files)}")
    print(f"Output directory: {out_dir}")
    print("Validation split:")
    for path in val_files:
        print(f"  - {path.name}")

    report = {
        "train_dir": str(train_dir),
        "train_files": [path.name for path in train_files],
        "validation_files": [path.name for path in val_files],
        "train_seeds": args.train_seeds,
        "val_count": args.val_count,
        "variants": {},
        "summary": [],
    }

    rows = []
    for variant in VARIANTS:
        print("\n" + "-" * 78)
        print(f"Variant: {variant['name']}")
        print(f"  {variant['description']}")
        key_cols = lut_key_for_variant(variant)
        print(f"  LUT key: {', '.join(key_cols)}")

        lut, train_meta = build_lut(train_files, variant)
        val_df, val_meta = load_validation(val_files, variant)
        if args.val_max_rows and len(val_df) > args.val_max_rows:
            val_df = val_df.sample(n=args.val_max_rows, random_state=0).sort_index().reset_index(drop=True)
            val_meta["rows_after_inference_capped"] = int(len(val_df))

        metrics, matched = validate_variant(val_df, lut, key_cols)
        pre = metrics["pre_cal"]
        post = metrics["post_cal"]
        print(
            f"  RMSE: {pre['rmse']:.3f} ps -> {post['rmse']:.3f} ps | "
            f"P99: {post['p99_ae']:.3f} ps | "
            f"LUT coverage: {metrics['lut_coverage_pct']:.5f}%"
        )
        if train_meta["rows_inference_failed"] or val_meta["rows_inference_failed"]:
            print(
                "  Inference losses: "
                f"train={train_meta['rows_inference_failed']:,}, "
                f"val={val_meta['rows_inference_failed']:,}"
            )

        variant_report = {
            "description": variant["description"],
            "drop_key_fields": variant["drop_key_fields"],
            "force_slow_boundary_zero": bool(variant["force_slow_boundary_zero"]),
            "lut_key": key_cols,
            "training": train_meta,
            "validation": val_meta,
            "metrics": metrics,
        }
        report["variants"][variant["name"]] = variant_report

        rows.append({
            "variant": variant["name"],
            "dropped": ",".join(variant["drop_key_fields"])
                       or ("slow_boundary_inc_inference" if variant["force_slow_boundary_zero"] else "none"),
            "lut_key_width_fields": len(key_cols),
            "lut_bins": train_meta["lut_bins"],
            "train_rows_after_inference": train_meta["rows_after_inference"],
            "train_inference_failed": train_meta["rows_inference_failed"],
            "val_rows_core": val_meta["rows_after_core_filter"],
            "val_rows_after_inference": val_meta["rows_after_inference"],
            "val_inference_failed": val_meta["rows_inference_failed"],
            "val_rows_matched": metrics["rows_after_lut_match"],
            "val_rows_unmatched_lut": metrics["rows_unmatched_lut"],
            "lut_coverage_pct": metrics["lut_coverage_pct"],
            "effective_val_coverage_pct": (
                float(100.0 * metrics["rows_after_lut_match"] / val_meta["rows_after_core_filter"])
                if val_meta["rows_after_core_filter"] else 0.0
            ),
            "pre_rmse_ps": pre["rmse"],
            "post_rmse_ps": post["rmse"],
            "post_mae_ps": post["mae"],
            "post_p90_abs_ps": post["p90_ae"],
            "post_p95_abs_ps": post["p95_ae"],
            "post_p99_abs_ps": post["p99_ae"],
            "post_mean_ps": post["mean"],
            "post_min_ps": post["min"],
            "post_max_ps": post["max"],
        })

        del lut, val_df, matched
        gc.collect()

    rows = summarize_degradation(rows)
    summary_df = pd.DataFrame(rows)
    csv_path = out_dir / "observable_ablation_report.csv"
    json_path = out_dir / "observable_ablation_report.json"
    summary_df.to_csv(csv_path, index=False)
    report["summary"] = rows
    report["elapsed_s"] = float(time.time() - t0)
    json_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

    print("\n" + "=" * 78)
    print("Ablation summary")
    print("=" * 78)
    display_cols = [
        "variant", "post_rmse_ps", "delta_rmse_ps", "post_p99_abs_ps",
        "delta_p99_abs_ps", "effective_val_coverage_pct",
        "val_inference_failed", "val_rows_unmatched_lut",
    ]
    print(summary_df[display_cols].to_string(index=False, float_format=lambda x: f"{x:.4f}"))
    print(f"\nWrote: {csv_path}")
    print(f"Wrote: {json_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
