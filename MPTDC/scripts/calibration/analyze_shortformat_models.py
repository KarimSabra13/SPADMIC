#!/usr/bin/env python3
"""
Short-format observability and calibration analysis for jittered MPTDC campaigns.

This script evaluates host-side calibration models that use only RAW_FEATURES-visible
observables. It compares practical train->eval LUT performance against oracle
per-key floors to answer a key question:

  "Is sub-20 ps single-shot under jitter blocked by the model, by data sparsity,
   or by the information content of the deployed narrow packet itself?"

The active compact CSV no longer emits `nfast_snap`, `nfast_stop`, `pd_idx`, or
`event_seq`. When those columns are absent this script synthesizes compatibility
views (`pd_idx` from `ns/nf`, `event_seq` from `hit_idx`, the removed fast-side
snapshots as zero) so historical comparisons can still be rerun on the new data.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

from calibrate_6d_lut import compute_metrics


CSV_DTYPES = {
    "conv_id": "int32",
    "hit_idx": "int16",
    "Tref_ps": "int32",
    "nslow": "int16",
    "nfast_hit": "int16",
    "nfast_snap": "int16",
    "nfast_stop": "int16",
    "ns": "int16",
    "nf": "int16",
    "pd_idx": "int16",
    "event_seq": "int16",
    "phase0_snap": "int16",
    "slow_boundary_inc": "int16",
    "hit_count": "int16",
    "flags": "int16",
    "ctx_id": "int16",
    "t_raw_ps": "int32",
    "mode": "int16",
    "max_hits": "int16",
}

USECOLS = [
    "hit_idx",
    "Tref_ps",
    "nslow",
    "nfast_hit",
    "nfast_snap",
    "nfast_stop",
    "ns",
    "nf",
    "pd_idx",
    "event_seq",
    "phase0_snap",
    "slow_boundary_inc",
    "t_raw_ps",
]

KEY_SETS = {
    "current_6d": ["ns", "nf", "nslow", "nfast_hit", "phase0_snap", "hit_idx"],
    "boundary_aug": ["ns", "nf", "nslow", "nfast_hit", "phase0_snap", "slow_boundary_inc", "hit_idx"],
    "short_core": ["ns", "nf", "nslow", "nfast_hit", "nfast_snap", "phase0_snap", "slow_boundary_inc", "hit_idx"],
    "nfast_stop_aug": ["ns", "nf", "nslow", "nfast_hit", "nfast_stop", "phase0_snap", "slow_boundary_inc", "hit_idx"],
    "all_visible": ["ns", "nf", "nslow", "nfast_hit", "nfast_snap", "nfast_stop",
                    "phase0_snap", "slow_boundary_inc", "pd_idx", "event_seq", "hit_idx"],
}

TARGET_PS = 20.0
DEFAULT_DELAY_POINTS_PS = [
    20, 30, 40, 50, 75, 100, 150, 200, 300, 500, 750, 1000,
    1500, 2000, 3000, 5000, 8000, 10000, 15000, 20000, 30000,
]


def parse_args():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--nominal-train-dir", type=str, default=None,
                    help="Optional nominal-training campaign directory")
    ap.add_argument("--jitter-train-dir", type=str, required=True,
                    help="Jitter-training campaign directory")
    ap.add_argument("--val-dir", type=str, required=True,
                    help="Held-out jitter validation directory")
    ap.add_argument("--fresh-dir", type=str, default=None,
                    help="Optional fresh jitter validation directory")
    ap.add_argument("--out-dir", type=str, required=True,
                    help="Output directory for tables, plots, and reports")
    ap.add_argument("--max-files", type=int, default=None,
                    help="Optional cap on CSV files loaded per dataset")
    ap.add_argument("--no-core-filter", action="store_true",
                    help="Keep nslow==0 rows (default filters them out)")
    return ap.parse_args()


def discover_csvs(dataset_dir: str | None, max_files: int | None = None) -> list[Path]:
    if not dataset_dir:
        return []
    root = Path(dataset_dir)
    if not root.is_dir():
        raise FileNotFoundError(f"Dataset directory does not exist: {dataset_dir}")
    files = sorted(root.glob("seed_*.csv"))
    if max_files is not None:
        files = files[:max_files]
    if not files:
        raise FileNotFoundError(f"No CSVs found under {dataset_dir}")
    return files


def load_dataset(label: str, files: list[Path], core_only: bool = True) -> pd.DataFrame:
    frames = []
    for path in files:
        # Active compact CSVs omit several historical observability columns.
        hdr = pd.read_csv(path, nrows=0).columns.tolist()
        use = [c for c in USECOLS if c in hdr]
        dt  = {c: v for c, v in CSV_DTYPES.items() if c in hdr}
        df = pd.read_csv(path, usecols=use, dtype=dt)
        if "nfast_snap" not in df.columns:
            df["nfast_snap"] = 0
        if "nfast_stop" not in df.columns:
            df["nfast_stop"] = 0
        if "event_seq" not in df.columns:
            df["event_seq"] = df["hit_idx"]
        if "pd_idx" not in df.columns:
            df["pd_idx"] = (df["ns"].astype(int) * 9 + df["nf"].astype(int)).astype("int16")
        frames.append(df)

    data = pd.concat(frames, ignore_index=True)
    if core_only:
        n_before = len(data)
        data = data[data["nslow"] > 0].copy()
        pct = (1.0 - len(data) / n_before) * 100.0 if n_before else 0.0
        print(f"[{label}] Core filter removed {n_before - len(data):,} rows ({pct:.1f}%)")
    else:
        data = data.copy()

    data["offset_ps"] = data["Tref_ps"] - data["t_raw_ps"]
    print(f"[{label}] Loaded {len(files)} file(s), {len(data):,} rows")
    return data


def safe_metrics(errors: np.ndarray, label: str) -> dict:
    if len(errors) == 0:
        return {
            "label": label,
            "count": 0,
            "mean": np.nan,
            "std": np.nan,
            "rmse": np.nan,
            "mae": np.nan,
            "p50_ae": np.nan,
            "p90_ae": np.nan,
            "p95_ae": np.nan,
            "p99_ae": np.nan,
            "min": np.nan,
            "max": np.nan,
        }
    return compute_metrics(errors, label=label)


def assign_delay_bucket(df: pd.DataFrame, delay_points: list[int]) -> pd.DataFrame:
    mids = [(a + b) / 2.0 for a, b in zip(delay_points[:-1], delay_points[1:])]
    left_edge = delay_points[0] - (delay_points[1] - delay_points[0]) / 2.0
    right_edge = delay_points[-1] + (delay_points[-1] - delay_points[-2]) / 2.0
    bins = [left_edge, *mids, right_edge]
    labels = pd.cut(
        df["Tref_ps"],
        bins=bins,
        labels=delay_points,
        include_lowest=True,
        right=False,
    )
    work = df.copy()
    work["delay_bucket_ps"] = labels.astype("Int64")
    work = work.dropna(subset=["delay_bucket_ps"]).copy()
    work["delay_bucket_ps"] = work["delay_bucket_ps"].astype(int)
    return work


def bin_stats(counts: pd.Series) -> dict[str, float]:
    arr = counts.to_numpy()
    return {
        "unique_bins": int(len(arr)),
        "min_count": int(arr.min()) if len(arr) else 0,
        "median_count": float(np.median(arr)) if len(arr) else 0.0,
        "p90_count": float(np.percentile(arr, 90)) if len(arr) else 0.0,
        "max_count": int(arr.max()) if len(arr) else 0,
    }


def build_exact_lut(train_df: pd.DataFrame, key_cols: list[str]) -> tuple[pd.DataFrame, dict[str, float]]:
    lut = train_df.groupby(key_cols)["offset_ps"].agg(["mean", "std", "count"])
    lut.columns = ["correction", "within_std", "train_count"]
    return lut, bin_stats(lut["train_count"])


def evaluate_exact(train_name: str, model_name: str, key_cols: list[str],
                   eval_name: str, eval_df: pd.DataFrame, lut: pd.DataFrame,
                   lut_stats: dict[str, float]) -> dict:
    merged = eval_df.merge(
        lut[["correction", "train_count"]].reset_index(),
        on=key_cols,
        how="left",
        copy=False,
    )
    matched = merged["correction"].notna()
    matched_rows = int(matched.sum())
    unmatched_rows = int((~matched).sum())
    coverage = matched_rows / len(merged) if len(merged) else 0.0

    row = {
        "train_corpus": train_name,
        "model": model_name,
        "eval_set": eval_name,
        "coverage": coverage,
        "matched_rows": matched_rows,
        "unmatched_rows": unmatched_rows,
        **lut_stats,
    }

    if matched_rows:
        errors = (merged.loc[matched, "offset_ps"] - merged.loc[matched, "correction"]).to_numpy()
        row.update(compute_metrics(errors, label=f"{train_name}/{model_name}/{eval_name}"))
    else:
        row.update({k: np.nan for k in ("count", "mean", "std", "rmse", "mae",
                                        "p50_ae", "p90_ae", "p95_ae", "p99_ae",
                                        "min", "max")})
        row["label"] = f"{train_name}/{model_name}/{eval_name}"
    return row


def evaluate_oracle(key_name: str, key_cols: list[str], eval_name: str, eval_df: pd.DataFrame) -> dict:
    grp = eval_df.groupby(key_cols)["offset_ps"]
    oracle_mean = grp.transform("mean")
    oracle_count = grp.transform("count")
    errors = (eval_df["offset_ps"] - oracle_mean).to_numpy()
    counts = grp.size()

    row = {
        "model": key_name,
        "eval_set": eval_name,
        "coverage": 1.0,
        "matched_rows": int(len(eval_df)),
        "unmatched_rows": 0,
        **bin_stats(counts),
        **compute_metrics(errors, label=f"oracle/{key_name}/{eval_name}"),
        "oracle_mean_bin_count": float(np.mean(oracle_count.to_numpy())),
    }
    return row


def build_hier_visible(train_df: pd.DataFrame) -> dict:
    levels = [
        ("short_core", KEY_SETS["short_core"]),
        ("boundary_aug", KEY_SETS["boundary_aug"]),
        ("current_6d", KEY_SETS["current_6d"]),
        ("coarse_phase", ["nslow", "nfast_hit", "phase0_snap", "slow_boundary_inc", "hit_idx"]),
        ("coarse_hit", ["nslow", "nfast_hit", "phase0_snap", "hit_idx"]),
        ("coarse_nslow_hit", ["nslow", "hit_idx"]),
        ("hit_only", ["hit_idx"]),
    ]
    tables = []
    for level_name, key_cols in levels:
        lut, _ = build_exact_lut(train_df, key_cols)
        tables.append((level_name, key_cols, lut[["correction"]].reset_index()))
    return {
        "levels": tables,
        "global_mean": float(train_df["offset_ps"].mean()),
    }


def evaluate_hier_visible(train_name: str, eval_name: str, eval_df: pd.DataFrame, hier_model: dict) -> dict:
    res = eval_df.copy()
    corr_cols = []
    level_names = []

    for idx, (level_name, key_cols, lut_df) in enumerate(hier_model["levels"]):
        corr_col = f"corr_{idx}"
        level_names.append(level_name)
        corr_cols.append(corr_col)
        res = res.merge(
            lut_df.rename(columns={"correction": corr_col}),
            on=key_cols,
            how="left",
            copy=False,
        )

    corr_frame = res[corr_cols]
    res["correction"] = corr_frame.bfill(axis=1).iloc[:, 0].fillna(hier_model["global_mean"])
    level_used = np.select(
        [res[col].notna() for col in corr_cols],
        level_names,
        default="global_mean",
    )
    errors = (res["offset_ps"] - res["correction"]).to_numpy()
    level_hist = pd.Series(level_used).value_counts().to_dict()

    return {
        "train_corpus": train_name,
        "model": "hier_visible",
        "eval_set": eval_name,
        "coverage": 1.0,
        "matched_rows": int(len(res)),
        "unmatched_rows": 0,
        "unique_bins": 0,
        "min_count": 0,
        "median_count": 0.0,
        "p90_count": 0.0,
        "max_count": 0,
        **compute_metrics(errors, label=f"{train_name}/hier_visible/{eval_name}"),
        "level_usage": {k: int(v) for k, v in level_hist.items()},
    }


def evaluate_exact_by_delay(train_name: str, model_name: str, key_cols: list[str],
                            eval_name: str, eval_df: pd.DataFrame,
                            lut: pd.DataFrame) -> list[dict]:
    merged = eval_df.merge(
        lut[["correction"]].reset_index(),
        on=key_cols,
        how="left",
        copy=False,
    )
    merged["error_ps"] = merged["offset_ps"] - merged["correction"]
    rows = []
    for delay_bucket_ps, grp in merged.groupby("delay_bucket_ps", sort=True):
        matched = grp["correction"].notna()
        matched_rows = int(matched.sum())
        total_rows = int(len(grp))
        row = {
            "train_corpus": train_name,
            "model": model_name,
            "eval_set": eval_name,
            "delay_bucket_ps": int(delay_bucket_ps),
            "coverage": matched_rows / total_rows if total_rows else 0.0,
            "matched_rows": matched_rows,
            "unmatched_rows": total_rows - matched_rows,
            **safe_metrics(grp.loc[matched, "error_ps"].to_numpy(),
                           label=f"{train_name}/{model_name}/{eval_name}/{delay_bucket_ps}"),
        }
        rows.append(row)
    return rows


def evaluate_oracle_by_delay(key_name: str, key_cols: list[str], eval_name: str,
                             eval_df: pd.DataFrame) -> list[dict]:
    grp = eval_df.groupby(key_cols)["offset_ps"]
    oracle_mean = grp.transform("mean")
    work = eval_df.copy()
    work["error_ps"] = work["offset_ps"] - oracle_mean
    rows = []
    for delay_bucket_ps, bucket in work.groupby("delay_bucket_ps", sort=True):
        row = {
            "model": key_name,
            "eval_set": eval_name,
            "delay_bucket_ps": int(delay_bucket_ps),
            "coverage": 1.0,
            "matched_rows": int(len(bucket)),
            "unmatched_rows": 0,
            **safe_metrics(bucket["error_ps"].to_numpy(),
                           label=f"oracle/{key_name}/{eval_name}/{delay_bucket_ps}"),
        }
        rows.append(row)
    return rows


def evaluate_hier_visible_by_delay(train_name: str, eval_name: str,
                                   eval_df: pd.DataFrame, hier_model: dict) -> list[dict]:
    res = eval_df.copy()
    corr_cols = []
    for idx, (_, key_cols, lut_df) in enumerate(hier_model["levels"]):
        corr_col = f"corr_{idx}"
        corr_cols.append(corr_col)
        res = res.merge(
            lut_df.rename(columns={"correction": corr_col}),
            on=key_cols,
            how="left",
            copy=False,
        )

    corr_frame = res[corr_cols]
    res["correction"] = corr_frame.bfill(axis=1).iloc[:, 0].fillna(hier_model["global_mean"])
    res["error_ps"] = res["offset_ps"] - res["correction"]

    rows = []
    for delay_bucket_ps, grp in res.groupby("delay_bucket_ps", sort=True):
        row = {
            "train_corpus": train_name,
            "model": "hier_visible",
            "eval_set": eval_name,
            "delay_bucket_ps": int(delay_bucket_ps),
            "coverage": 1.0,
            "matched_rows": int(len(grp)),
            "unmatched_rows": 0,
            **safe_metrics(grp["error_ps"].to_numpy(),
                           label=f"{train_name}/hier_visible/{eval_name}/{delay_bucket_ps}"),
        }
        rows.append(row)
    return rows


def raw_by_delay(eval_name: str, eval_df: pd.DataFrame) -> list[dict]:
    rows = []
    for delay_bucket_ps, grp in eval_df.groupby("delay_bucket_ps", sort=True):
        row = {
            "train_corpus": "baseline",
            "model": "raw_uncalibrated",
            "eval_set": eval_name,
            "delay_bucket_ps": int(delay_bucket_ps),
            "coverage": 1.0,
            "matched_rows": int(len(grp)),
            "unmatched_rows": 0,
            **safe_metrics(grp["offset_ps"].to_numpy(), label=f"raw/{eval_name}/{delay_bucket_ps}"),
        }
        rows.append(row)
    return rows


def build_oracle_error_frame(eval_df: pd.DataFrame) -> pd.DataFrame:
    work = eval_df.copy()
    for model_name in ["current_6d", "boundary_aug", "short_core", "all_visible"]:
        key_cols = KEY_SETS[model_name]
        oracle_mean = work.groupby(key_cols)["offset_ps"].transform("mean")
        work[f"oracle_err_{model_name}"] = work["offset_ps"] - oracle_mean
    return work


def oracle_gain_rows(oracle_err_df: pd.DataFrame, eval_name: str, group_col: str) -> list[dict]:
    rows = []
    for group_value, grp in oracle_err_df.groupby(group_col, sort=True):
        current_rmse = safe_metrics(grp["oracle_err_current_6d"].to_numpy(),
                                    label=f"gain/current/{eval_name}/{group_col}/{group_value}")["rmse"]
        boundary_rmse = safe_metrics(grp["oracle_err_boundary_aug"].to_numpy(),
                                     label=f"gain/boundary/{eval_name}/{group_col}/{group_value}")["rmse"]
        short_rmse = safe_metrics(grp["oracle_err_short_core"].to_numpy(),
                                  label=f"gain/short/{eval_name}/{group_col}/{group_value}")["rmse"]
        all_rmse = safe_metrics(grp["oracle_err_all_visible"].to_numpy(),
                                label=f"gain/all/{eval_name}/{group_col}/{group_value}")["rmse"]
        rows.append({
            "eval_set": eval_name,
            group_col: int(group_value),
            "count": int(len(grp)),
            "current_6d_rmse": float(current_rmse),
            "boundary_aug_rmse": float(boundary_rmse),
            "short_core_rmse": float(short_rmse),
            "all_visible_rmse": float(all_rmse),
            "gain_boundary_ps": float(current_rmse - boundary_rmse),
            "gain_nfast_snap_ps": float(boundary_rmse - short_rmse),
            "gain_all_visible_ps": float(short_rmse - all_rmse),
        })
    return rows


def summarize_nfast_snap_split(oracle_err_df: pd.DataFrame, eval_name: str) -> dict:
    boundary_cols = KEY_SETS["boundary_aug"]
    per_bin_rows = oracle_err_df.groupby(boundary_cols).size().rename("rows")
    per_bin_snap = oracle_err_df.groupby(boundary_cols)["nfast_snap"].nunique().rename("distinct_nfast_snap")
    per_bin = pd.concat([per_bin_rows, per_bin_snap], axis=1).reset_index()
    multi = per_bin["distinct_nfast_snap"] > 1
    weighted_mean_distinct = np.average(per_bin["distinct_nfast_snap"], weights=per_bin["rows"])
    return {
        "eval_set": eval_name,
        "boundary_bins": int(len(per_bin)),
        "boundary_bins_multi_snap": int(multi.sum()),
        "boundary_bins_single_snap": int((~multi).sum()),
        "row_fraction_in_multi_snap_bins": float(per_bin.loc[multi, "rows"].sum() / per_bin["rows"].sum()),
        "weighted_mean_distinct_nfast_snap": float(weighted_mean_distinct),
        "median_distinct_nfast_snap": float(per_bin["distinct_nfast_snap"].median()),
        "p90_distinct_nfast_snap": float(per_bin["distinct_nfast_snap"].quantile(0.90)),
        "max_distinct_nfast_snap": int(per_bin["distinct_nfast_snap"].max()),
    }


def overall_oracle_gain_row(oracle_err_df: pd.DataFrame, eval_name: str) -> dict:
    current_rmse = safe_metrics(oracle_err_df["oracle_err_current_6d"].to_numpy(),
                                label=f"overall/current/{eval_name}")["rmse"]
    boundary_rmse = safe_metrics(oracle_err_df["oracle_err_boundary_aug"].to_numpy(),
                                 label=f"overall/boundary/{eval_name}")["rmse"]
    short_rmse = safe_metrics(oracle_err_df["oracle_err_short_core"].to_numpy(),
                              label=f"overall/short/{eval_name}")["rmse"]
    all_rmse = safe_metrics(oracle_err_df["oracle_err_all_visible"].to_numpy(),
                            label=f"overall/all/{eval_name}")["rmse"]
    return {
        "eval_set": eval_name,
        "count": int(len(oracle_err_df)),
        "current_6d_rmse": float(current_rmse),
        "boundary_aug_rmse": float(boundary_rmse),
        "short_core_rmse": float(short_rmse),
        "all_visible_rmse": float(all_rmse),
        "gain_boundary_ps": float(current_rmse - boundary_rmse),
        "gain_nfast_snap_ps": float(boundary_rmse - short_rmse),
        "gain_all_visible_ps": float(short_rmse - all_rmse),
    }


def save_plot_practical(practical_df: pd.DataFrame, out_path: Path):
    keep = practical_df[
        (
            (practical_df["train_corpus"] == "baseline")
            & (practical_df["model"] == "raw_uncalibrated")
        )
        | (practical_df["model"].isin(["current_6d", "short_core", "hier_visible"]))
    ].copy()

    order = []
    for train_name in ["baseline", "nominal", "jitter", "mixed"]:
        for model_name in ["raw_uncalibrated", "current_6d", "short_core", "hier_visible"]:
            mask = (keep["train_corpus"] == train_name) & (keep["model"] == model_name)
            if mask.any():
                order.append((train_name, model_name))

    labels = [f"{t}:{m}" if t != "baseline" else "raw" for t, m in order]
    eval_sets = list(dict.fromkeys(keep["eval_set"]))
    x = np.arange(len(order))
    width = 0.35 if len(eval_sets) > 1 else 0.55

    fig, ax = plt.subplots(figsize=(max(12, len(order) * 1.3), 6))
    for idx, eval_name in enumerate(eval_sets):
        vals = []
        for train_name, model_name in order:
            row = keep[(keep["train_corpus"] == train_name)
                       & (keep["model"] == model_name)
                       & (keep["eval_set"] == eval_name)]
            vals.append(float(row["rmse"].iloc[0]) if not row.empty else np.nan)
        ax.bar(x + idx * width - width * (len(eval_sets) - 1) / 2, vals,
               width=width, label=eval_name)

    ax.axhline(TARGET_PS, color="crimson", ls="--", lw=1.2, label="20 ps target")
    ax.set_ylabel("RMSE (ps)")
    ax.set_title("Short-format practical RMSE comparison")
    ax.set_xticks(x)
    ax.set_xticklabels(labels, rotation=30, ha="right")
    ax.legend()
    ax.grid(axis="y", alpha=0.25)
    fig.tight_layout()
    fig.savefig(out_path, dpi=150, bbox_inches="tight")
    plt.close(fig)


def save_plot_oracle(oracle_df: pd.DataFrame, out_path: Path):
    order = ["current_6d", "boundary_aug", "short_core", "all_visible"]
    eval_sets = list(dict.fromkeys(oracle_df["eval_set"]))
    x = np.arange(len(order))
    width = 0.35 if len(eval_sets) > 1 else 0.55

    fig, ax = plt.subplots(figsize=(10, 6))
    for idx, eval_name in enumerate(eval_sets):
        vals = []
        for model_name in order:
            row = oracle_df[(oracle_df["model"] == model_name) & (oracle_df["eval_set"] == eval_name)]
            vals.append(float(row["rmse"].iloc[0]) if not row.empty else np.nan)
        ax.bar(x + idx * width - width * (len(eval_sets) - 1) / 2, vals,
               width=width, label=eval_name)

    ax.axhline(TARGET_PS, color="crimson", ls="--", lw=1.2, label="20 ps target")
    ax.set_ylabel("Oracle floor RMSE (ps)")
    ax.set_title("Short-format oracle floor by visible key")
    ax.set_xticks(x)
    ax.set_xticklabels(order, rotation=20, ha="right")
    ax.legend()
    ax.grid(axis="y", alpha=0.25)
    fig.tight_layout()
    fig.savefig(out_path, dpi=150, bbox_inches="tight")
    plt.close(fig)


def save_plot_coverage(practical_df: pd.DataFrame, out_path: Path):
    keep = practical_df[
        (practical_df["train_corpus"] != "baseline")
        & (practical_df["model"].isin(["current_6d", "boundary_aug", "short_core", "all_visible"]))
    ].copy()

    keep["label"] = keep["train_corpus"] + ":" + keep["model"]
    eval_sets = list(dict.fromkeys(keep["eval_set"]))
    labels = list(dict.fromkeys(keep["label"]))
    x = np.arange(len(labels))
    width = 0.35 if len(eval_sets) > 1 else 0.55

    fig, ax = plt.subplots(figsize=(max(12, len(labels) * 1.1), 6))
    for idx, eval_name in enumerate(eval_sets):
        vals = []
        for label in labels:
            row = keep[(keep["label"] == label) & (keep["eval_set"] == eval_name)]
            vals.append(float(row["coverage"].iloc[0]) * 100.0 if not row.empty else np.nan)
        ax.bar(x + idx * width - width * (len(eval_sets) - 1) / 2, vals,
               width=width, label=eval_name)

    ax.set_ylabel("Matched coverage (%)")
    ax.set_title("Exact-LUT coverage by train corpus and visible key")
    ax.set_xticks(x)
    ax.set_xticklabels(labels, rotation=35, ha="right")
    ax.set_ylim(0, 105)
    ax.legend()
    ax.grid(axis="y", alpha=0.25)
    fig.tight_layout()
    fig.savefig(out_path, dpi=150, bbox_inches="tight")
    plt.close(fig)


def save_plot_oracle_by_hit(eval_name: str, eval_df: pd.DataFrame, out_path: Path):
    fig, ax = plt.subplots(figsize=(10, 6))
    for model_name in ["current_6d", "short_core"]:
        key_cols = KEY_SETS[model_name]
        oracle_mean = eval_df.groupby(key_cols)["offset_ps"].transform("mean")
        err = eval_df["offset_ps"] - oracle_mean
        by_hit = err.groupby(eval_df["hit_idx"]).apply(lambda x: np.sqrt(np.mean(np.square(x))))
        ax.plot(by_hit.index, by_hit.values, marker="o", ms=3, lw=1.2, label=model_name)

    ax.axhline(TARGET_PS, color="crimson", ls="--", lw=1.2, label="20 ps target")
    ax.set_xlabel("hit_idx")
    ax.set_ylabel("Oracle floor RMSE (ps)")
    ax.set_title(f"Oracle floor by hit index ({eval_name})")
    ax.grid(alpha=0.25)
    ax.legend()
    fig.tight_layout()
    fig.savefig(out_path, dpi=150, bbox_inches="tight")
    plt.close(fig)


def save_plot_practical_by_delay(practical_delay_df: pd.DataFrame, out_path: Path,
                                 eval_name: str, train_name: str):
    keep = practical_delay_df[
        (practical_delay_df["eval_set"] == eval_name)
        & (
            ((practical_delay_df["train_corpus"] == "baseline")
             & (practical_delay_df["model"] == "raw_uncalibrated"))
            | ((practical_delay_df["train_corpus"] == train_name)
               & practical_delay_df["model"].isin(["current_6d", "short_core", "hier_visible"]))
        )
    ].copy()
    fig, ax = plt.subplots(figsize=(10, 6))
    for train_corpus, model_name, label in [
        ("baseline", "raw_uncalibrated", "raw"),
        (train_name, "current_6d", f"{train_name}:current_6d"),
        (train_name, "short_core", f"{train_name}:short_core"),
        (train_name, "hier_visible", f"{train_name}:hier_visible"),
    ]:
        grp = keep[(keep["train_corpus"] == train_corpus) & (keep["model"] == model_name)]
        grp = grp.sort_values("delay_bucket_ps")
        if grp.empty:
            continue
        ax.plot(grp["delay_bucket_ps"] / 1000.0, grp["rmse"], marker="o", ms=3, lw=1.4, label=label)

    ax.axhline(TARGET_PS, color="crimson", ls="--", lw=1.2, label="20 ps target")
    ax.set_xlabel("Delay bucket center (ns)")
    ax.set_ylabel("RMSE (ps)")
    ax.set_title(f"Delay-binned practical RMSE ({eval_name}, train={train_name})")
    ax.grid(alpha=0.25)
    ax.legend()
    fig.tight_layout()
    fig.savefig(out_path, dpi=150, bbox_inches="tight")
    plt.close(fig)


def save_plot_oracle_by_delay_bucket(oracle_delay_df: pd.DataFrame, out_path: Path, eval_name: str):
    keep = oracle_delay_df[oracle_delay_df["eval_set"] == eval_name].copy()
    fig, ax = plt.subplots(figsize=(10, 6))
    for model_name in ["current_6d", "boundary_aug", "short_core", "all_visible"]:
        grp = keep[keep["model"] == model_name].sort_values("delay_bucket_ps")
        if grp.empty:
            continue
        ax.plot(grp["delay_bucket_ps"] / 1000.0, grp["rmse"], marker="o", ms=3, lw=1.4, label=model_name)

    ax.axhline(TARGET_PS, color="crimson", ls="--", lw=1.2, label="20 ps target")
    ax.set_xlabel("Delay bucket center (ns)")
    ax.set_ylabel("Oracle floor RMSE (ps)")
    ax.set_title(f"Delay-binned oracle floor ({eval_name})")
    ax.grid(alpha=0.25)
    ax.legend()
    fig.tight_layout()
    fig.savefig(out_path, dpi=150, bbox_inches="tight")
    plt.close(fig)


def save_plot_gain_by_group(gain_df: pd.DataFrame, out_path: Path, eval_name: str,
                            group_col: str, x_label: str, title: str, x_scale: float = 1.0):
    keep = gain_df[gain_df["eval_set"] == eval_name].sort_values(group_col)
    if keep.empty:
        return

    fig, ax = plt.subplots(figsize=(10, 6))
    ax.plot(keep[group_col] / x_scale, keep["gain_boundary_ps"], marker="o", ms=3, lw=1.4,
            label="current_6d - boundary_aug")
    ax.plot(keep[group_col] / x_scale, keep["gain_nfast_snap_ps"], marker="s", ms=3, lw=1.4,
            label="boundary_aug - short_core")
    ax.plot(keep[group_col] / x_scale, keep["gain_all_visible_ps"], marker="^", ms=3, lw=1.4,
            label="short_core - all_visible")
    ax.axhline(0.0, color="k", ls="--", lw=0.8)
    ax.set_xlabel(x_label)
    ax.set_ylabel("Oracle RMSE improvement (ps)")
    ax.set_title(title)
    ax.grid(alpha=0.25)
    ax.legend()
    fig.tight_layout()
    fig.savefig(out_path, dpi=150, bbox_inches="tight")
    plt.close(fig)


def main():
    args = parse_args()
    out_dir = Path(args.out_dir)
    plots_dir = out_dir / "plots"
    tables_dir = out_dir / "tables"
    plots_dir.mkdir(parents=True, exist_ok=True)
    tables_dir.mkdir(parents=True, exist_ok=True)

    core_only = not args.no_core_filter

    nominal_files = discover_csvs(args.nominal_train_dir, args.max_files) if args.nominal_train_dir else []
    jitter_files = discover_csvs(args.jitter_train_dir, args.max_files)
    val_files = discover_csvs(args.val_dir, args.max_files)
    fresh_files = discover_csvs(args.fresh_dir, args.max_files) if args.fresh_dir else []

    datasets = {
        "jitter_train": load_dataset("jitter_train", jitter_files, core_only=core_only),
        "heldout_jitter": load_dataset("heldout_jitter", val_files, core_only=core_only),
    }
    if nominal_files:
        datasets["nominal_train"] = load_dataset("nominal_train", nominal_files, core_only=core_only)
    if fresh_files:
        datasets["fresh_jitter"] = load_dataset("fresh_jitter", fresh_files, core_only=core_only)

    train_sets = {
        "jitter": datasets["jitter_train"],
    }
    if "nominal_train" in datasets:
        train_sets["nominal"] = datasets["nominal_train"]
        train_sets["mixed"] = pd.concat(
            [datasets["nominal_train"], datasets["jitter_train"]],
            ignore_index=True,
            copy=False,
        )

    eval_sets = {
        "heldout_jitter": assign_delay_bucket(datasets["heldout_jitter"], DEFAULT_DELAY_POINTS_PS),
    }
    if "fresh_jitter" in datasets:
        eval_sets["fresh_jitter"] = assign_delay_bucket(datasets["fresh_jitter"], DEFAULT_DELAY_POINTS_PS)

    practical_rows = []
    oracle_rows = []
    practical_delay_rows = []
    oracle_delay_rows = []
    oracle_gain_delay_rows = []
    oracle_gain_nslow_rows = []
    oracle_gain_nfast_hit_rows = []
    oracle_gain_overall_rows = []
    nfast_snap_split_rows = []

    for eval_name, eval_df in eval_sets.items():
        raw_row = {
            "train_corpus": "baseline",
            "model": "raw_uncalibrated",
            "eval_set": eval_name,
            "coverage": 1.0,
            "matched_rows": int(len(eval_df)),
            "unmatched_rows": 0,
            "unique_bins": 0,
            "min_count": 0,
            "median_count": 0.0,
            "p90_count": 0.0,
            "max_count": 0,
            **compute_metrics(eval_df["offset_ps"].to_numpy(), label=f"raw/{eval_name}"),
        }
        practical_rows.append(raw_row)
        practical_delay_rows.extend(raw_by_delay(eval_name, eval_df))

        for key_name, key_cols in KEY_SETS.items():
            oracle_rows.append(evaluate_oracle(key_name, key_cols, eval_name, eval_df))
            oracle_delay_rows.extend(evaluate_oracle_by_delay(key_name, key_cols, eval_name, eval_df))

        oracle_err_df = build_oracle_error_frame(eval_df)
        oracle_gain_delay_rows.extend(oracle_gain_rows(oracle_err_df, eval_name, "delay_bucket_ps"))
        oracle_gain_nslow_rows.extend(oracle_gain_rows(oracle_err_df, eval_name, "nslow"))
        oracle_gain_nfast_hit_rows.extend(oracle_gain_rows(oracle_err_df, eval_name, "nfast_hit"))
        oracle_gain_overall_rows.append(overall_oracle_gain_row(oracle_err_df, eval_name))
        nfast_snap_split_rows.append(summarize_nfast_snap_split(oracle_err_df, eval_name))

    for train_name, train_df in train_sets.items():
        print(f"\n=== Training corpus: {train_name} ({len(train_df):,} rows) ===")
        for model_name, key_cols in KEY_SETS.items():
            lut, lut_stats = build_exact_lut(train_df, key_cols)
            for eval_name, eval_df in eval_sets.items():
                practical_rows.append(
                    evaluate_exact(train_name, model_name, key_cols, eval_name, eval_df, lut, lut_stats)
                )
                practical_delay_rows.extend(
                    evaluate_exact_by_delay(train_name, model_name, key_cols, eval_name, eval_df, lut)
                )

        hier_model = build_hier_visible(train_df)
        for eval_name, eval_df in eval_sets.items():
            practical_rows.append(evaluate_hier_visible(train_name, eval_name, eval_df, hier_model))
            practical_delay_rows.extend(
                evaluate_hier_visible_by_delay(train_name, eval_name, eval_df, hier_model)
            )

    practical_df = pd.DataFrame(practical_rows)
    oracle_df = pd.DataFrame(oracle_rows)
    practical_delay_df = pd.DataFrame(practical_delay_rows)
    oracle_delay_df = pd.DataFrame(oracle_delay_rows)
    oracle_gain_delay_df = pd.DataFrame(oracle_gain_delay_rows)
    oracle_gain_nslow_df = pd.DataFrame(oracle_gain_nslow_rows)
    oracle_gain_nfast_hit_df = pd.DataFrame(oracle_gain_nfast_hit_rows)
    oracle_gain_overall_df = pd.DataFrame(oracle_gain_overall_rows)
    nfast_snap_split_df = pd.DataFrame(nfast_snap_split_rows)

    practical_df.to_csv(tables_dir / "practical_metrics.csv", index=False)
    oracle_df.to_csv(tables_dir / "oracle_metrics.csv", index=False)
    practical_delay_df.to_csv(tables_dir / "practical_metrics_by_delay_bucket.csv", index=False)
    oracle_delay_df.to_csv(tables_dir / "oracle_metrics_by_delay_bucket.csv", index=False)
    oracle_gain_delay_df.to_csv(tables_dir / "oracle_gain_by_delay_bucket.csv", index=False)
    oracle_gain_nslow_df.to_csv(tables_dir / "oracle_gain_by_nslow.csv", index=False)
    oracle_gain_nfast_hit_df.to_csv(tables_dir / "oracle_gain_by_nfast_hit.csv", index=False)
    oracle_gain_overall_df.to_csv(tables_dir / "oracle_gain_overall.csv", index=False)
    nfast_snap_split_df.to_csv(tables_dir / "nfast_snap_split_summary.csv", index=False)

    save_plot_practical(practical_df, plots_dir / "practical_rmse.png")
    save_plot_oracle(oracle_df, plots_dir / "oracle_floor_rmse.png")
    save_plot_coverage(practical_df, plots_dir / "exact_lut_coverage.png")
    for eval_name, eval_df in eval_sets.items():
        save_plot_oracle_by_hit(eval_name, eval_df, plots_dir / f"{eval_name}_oracle_by_hit.png")

    best_exact = practical_df[
        (practical_df["train_corpus"] != "baseline")
        & (practical_df["model"] != "hier_visible")
    ].sort_values("rmse").iloc[0]
    best_practical = practical_df[
        (practical_df["train_corpus"] != "baseline")
        & (practical_df["coverage"] >= 0.999999)
    ].sort_values("rmse").iloc[0]
    best_oracle_core = oracle_df[oracle_df["model"] == "short_core"].sort_values("rmse").iloc[0]
    best_oracle_all = oracle_df[oracle_df["model"] == "all_visible"].sort_values("rmse").iloc[0]
    heldout_oracle_by_delay = oracle_delay_df[
        (oracle_delay_df["eval_set"] == "heldout_jitter")
        & (oracle_delay_df["model"] == "short_core")
    ].sort_values("delay_bucket_ps")
    heldout_best_practical_by_delay = practical_delay_df[
        (practical_delay_df["eval_set"] == "heldout_jitter")
        & (practical_delay_df["train_corpus"] == best_practical["train_corpus"])
        & (practical_delay_df["model"] == "hier_visible")
    ].sort_values("delay_bucket_ps")
    heldout_gain_delay = oracle_gain_delay_df[
        oracle_gain_delay_df["eval_set"] == "heldout_jitter"
    ].sort_values("delay_bucket_ps")
    heldout_overall_gain = oracle_gain_overall_df[
        oracle_gain_overall_df["eval_set"] == "heldout_jitter"
    ].iloc[0].to_dict()
    heldout_snap_split = nfast_snap_split_df[
        nfast_snap_split_df["eval_set"] == "heldout_jitter"
    ].iloc[0].to_dict()
    best_nfast_gain_bucket = heldout_gain_delay.sort_values("gain_nfast_snap_ps", ascending=False).iloc[0].to_dict()
    worst_nfast_gain_bucket = heldout_gain_delay.sort_values("gain_nfast_snap_ps", ascending=True).iloc[0].to_dict()

    if float(best_oracle_core["rmse"]) <= TARGET_PS:
        conclusion = ("The robust short-format field set appears sufficient in principle; "
                      "remaining gap is model/data-limited, not observability-limited.")
    elif float(best_oracle_all["rmse"]) <= TARGET_PS:
        conclusion = ("Sub-20 ps is only reachable if the calibration model exploits the full "
                      "visible narrow packet, including hit-identity fields.")
    else:
        conclusion = ("Even the oracle floor stays above 20 ps, so the present narrow-field "
                      "observable set is likely the dominant limiter under this jitter model.")

    report = {
        "target_ps": TARGET_PS,
        "train_rows": {name: int(len(df)) for name, df in train_sets.items()},
        "eval_rows": {name: int(len(df)) for name, df in eval_sets.items()},
        "best_exact_matched_only": best_exact.to_dict(),
        "best_practical": best_practical.to_dict(),
        "best_oracle_short_core": best_oracle_core.to_dict(),
        "best_oracle_all_visible": best_oracle_all.to_dict(),
        "delay_bucket_reference_ps": DEFAULT_DELAY_POINTS_PS,
        "heldout_short_core_bins_le_target": int((heldout_oracle_by_delay["rmse"] <= TARGET_PS).sum()),
        "heldout_short_core_total_bins": int(len(heldout_oracle_by_delay)),
        "heldout_short_core_best_bin": heldout_oracle_by_delay.sort_values("rmse").iloc[0].to_dict(),
        "heldout_short_core_worst_bin": heldout_oracle_by_delay.sort_values("rmse").iloc[-1].to_dict(),
        "heldout_best_practical_best_bin": heldout_best_practical_by_delay.sort_values("rmse").iloc[0].to_dict(),
        "heldout_best_practical_worst_bin": heldout_best_practical_by_delay.sort_values("rmse").iloc[-1].to_dict(),
        "heldout_oracle_gain_overall": heldout_overall_gain,
        "heldout_best_nfast_snap_gain_bucket": best_nfast_gain_bucket,
        "heldout_worst_nfast_snap_gain_bucket": worst_nfast_gain_bucket,
        "heldout_nfast_snap_split_summary": heldout_snap_split,
        "conclusion": conclusion,
    }

    (out_dir / "report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")

    with (out_dir / "report.txt").open("w", encoding="utf-8") as fh:
        fh.write("MPTDC Short-Format Jitter Analysis\n")
        fh.write("=" * 40 + "\n\n")
        fh.write(f"Target: sub-{TARGET_PS:.0f} ps single-shot under jitter\n\n")
        fh.write("Best practical model:\n")
        fh.write(f"  train/eval : {best_practical['train_corpus']} -> {best_practical['eval_set']}\n")
        fh.write(f"  model      : {best_practical['model']}\n")
        fh.write(f"  RMSE       : {best_practical['rmse']:.2f} ps\n")
        fh.write(f"  coverage   : {best_practical['coverage']*100:.2f}%\n\n")
        fh.write("Best exact-key (matched subset only):\n")
        fh.write(f"  train/eval : {best_exact['train_corpus']} -> {best_exact['eval_set']}\n")
        fh.write(f"  model      : {best_exact['model']}\n")
        fh.write(f"  RMSE       : {best_exact['rmse']:.2f} ps\n")
        fh.write(f"  coverage   : {best_exact['coverage']*100:.2f}%\n\n")
        fh.write("Oracle floor (robust short_core key):\n")
        fh.write(f"  eval set   : {best_oracle_core['eval_set']}\n")
        fh.write(f"  RMSE       : {best_oracle_core['rmse']:.2f} ps\n\n")
        fh.write("Oracle floor (all visible narrow fields):\n")
        fh.write(f"  eval set   : {best_oracle_all['eval_set']}\n")
        fh.write(f"  RMSE       : {best_oracle_all['rmse']:.2f} ps\n\n")
        fh.write("Held-out jitter delay-bucket view (short_core oracle):\n")
        fh.write(f"  bins <= 20 ps : {report['heldout_short_core_bins_le_target']}/{report['heldout_short_core_total_bins']}\n")
        fh.write(f"  best bucket   : {int(report['heldout_short_core_best_bin']['delay_bucket_ps'])} ps "
                 f"@ {report['heldout_short_core_best_bin']['rmse']:.2f} ps\n")
        fh.write(f"  worst bucket  : {int(report['heldout_short_core_worst_bin']['delay_bucket_ps'])} ps "
                 f"@ {report['heldout_short_core_worst_bin']['rmse']:.2f} ps\n\n")
        fh.write("Held-out jitter incremental oracle gain from extra visible fields:\n")
        fh.write(f"  current_6d -> boundary_aug : {report['heldout_oracle_gain_overall']['gain_boundary_ps']:.2f} ps\n")
        fh.write(f"  boundary_aug -> short_core : {report['heldout_oracle_gain_overall']['gain_nfast_snap_ps']:.2f} ps\n")
        fh.write(f"  short_core -> all_visible  : {report['heldout_oracle_gain_overall']['gain_all_visible_ps']:.2f} ps\n")
        fh.write(f"  best nfast_snap bucket     : {int(report['heldout_best_nfast_snap_gain_bucket']['delay_bucket_ps'])} ps "
                 f"@ +{report['heldout_best_nfast_snap_gain_bucket']['gain_nfast_snap_ps']:.2f} ps\n")
        fh.write(f"  worst nfast_snap bucket    : {int(report['heldout_worst_nfast_snap_gain_bucket']['delay_bucket_ps'])} ps "
                 f"@ {report['heldout_worst_nfast_snap_gain_bucket']['gain_nfast_snap_ps']:.2f} ps\n")
        fh.write(f"  row fraction in multi-snap boundary bins : "
                 f"{report['heldout_nfast_snap_split_summary']['row_fraction_in_multi_snap_bins']*100:.2f}%\n\n")
        fh.write("Conclusion:\n")
        fh.write(f"  {conclusion}\n")

    print("\n======================================================================")
    print("  SHORT-FORMAT JITTER SUMMARY")
    print("======================================================================")
    print(f"  Best practical RMSE     : {best_practical['rmse']:.2f} ps "
          f"({best_practical['train_corpus']} / {best_practical['model']} / {best_practical['eval_set']})")
    print(f"  Best exact matched RMSE : {best_exact['rmse']:.2f} ps "
          f"({best_exact['train_corpus']} / {best_exact['model']} / {best_exact['eval_set']}, "
          f"coverage {best_exact['coverage']*100:.1f}%)")
    print(f"  Oracle short_core floor : {best_oracle_core['rmse']:.2f} ps "
          f"({best_oracle_core['eval_set']})")
    print(f"  Oracle all_visible floor: {best_oracle_all['rmse']:.2f} ps "
          f"({best_oracle_all['eval_set']})")
    print(f"  Heldout short_core bins <=20 ps : {report['heldout_short_core_bins_le_target']}/"
          f"{report['heldout_short_core_total_bins']}")
    print(f"  Heldout nfast_snap gain (boundary->short): "
          f"{report['heldout_oracle_gain_overall']['gain_nfast_snap_ps']:.2f} ps")
    print(f"  Conclusion              : {conclusion}")
    print("======================================================================")
    print(f"\nOutputs in: {out_dir}")

    for eval_name in eval_sets:
        save_plot_practical_by_delay(
            practical_delay_df,
            plots_dir / f"{eval_name}_practical_rmse_by_delay_bucket.png",
            eval_name,
            str(best_practical["train_corpus"]),
        )
        save_plot_oracle_by_delay_bucket(
            oracle_delay_df,
            plots_dir / f"{eval_name}_oracle_floor_by_delay_bucket.png",
            eval_name,
        )
        save_plot_gain_by_group(
            oracle_gain_delay_df,
            plots_dir / f"{eval_name}_oracle_gain_by_delay_bucket.png",
            eval_name,
            "delay_bucket_ps",
            "Delay bucket center (ns)",
            f"Delay-binned oracle gain from boundary and nfast_snap ({eval_name})",
            x_scale=1000.0,
        )
        save_plot_gain_by_group(
            oracle_gain_nslow_df,
            plots_dir / f"{eval_name}_oracle_gain_by_nslow.png",
            eval_name,
            "nslow",
            "nslow",
            f"Oracle gain from boundary and nfast_snap vs nslow ({eval_name})",
        )
        save_plot_gain_by_group(
            oracle_gain_nfast_hit_df,
            plots_dir / f"{eval_name}_oracle_gain_by_nfast_hit.png",
            eval_name,
            "nfast_hit",
            "nfast_hit",
            f"Oracle gain from boundary and nfast_snap vs nfast_hit ({eval_name})",
        )


if __name__ == "__main__":
    main()
