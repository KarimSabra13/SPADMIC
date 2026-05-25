#!/usr/bin/env python3
"""Oracle analysis for MPTDC calibration-key sufficiency.

The script answers a hardware-facing question: can the packet-visible fields
identify the true delay tightly enough to support a post-calibration INL target,
or is another RTL discriminator required?
"""

from __future__ import annotations

import argparse
import json
import math
import re
import tempfile
from collections.abc import Iterable
from dataclasses import dataclass, field
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

from mptdc_char_common import DELTA_LSB_PS, apply_char_style, discover_stage_csvs, numeric, save_char_figure, style_axes


NE = 8
K_VERNIER = 11
K_SLOW = K_VERNIER * NE
K_FAST = NE
OFFSET = 25
QUANT_PS = 10
DEFAULT_CHUNKSIZE = 500_000
SENTINEL = -1

NSNF_REV = {
    ns * K_VERNIER - nf * (K_VERNIER - 1): (ns, nf)
    for ns in range(NE)
    for nf in range(NE)
}

BASE_USECOLS = {
    "seed",
    "trial_id",
    "conv_id",
    "hit_idx",
    "Tref_ps",
    "start_time_ps",
    "stop_time_ps",
    "true_dt_ps",
    "accepted",
    "rejected",
    "ctx_id",
    "hit_count",
    "flags",
    "phase0_snap",
    "slow_boundary_inc",
    "nslow",
    "nfast_hit",
    "ns",
    "nf",
    "stop_phase_disc",
    "t_raw_ps",
    "tuple_code",
    "scalar_bin",
    "max_hits",
    "input_sel",
    "out_mode",
}

REQUIRED_FILTER_COLS = {
    "hit_idx",
    "hit_count",
    "max_hits",
    "accepted",
    "rejected",
    "t_raw_ps",
}

DEFAULT_KEY_SETS: dict[str, list[str]] = {
    "scalar_bin": ["scalar_bin"],
    "raw_formula_inputs": ["nslow", "nfast_hit", "ns", "nf", "slow_boundary_inc"],
    "packet_visible": [
        "nslow",
        "nfast_hit",
        "ns",
        "nf",
        "stop_phase_disc",
        "phase0_snap",
        "slow_boundary_inc",
        "hit_idx",
    ],
    "cal_lut_key": [
        "ns_inf",
        "nf_inf",
        "nslow",
        "nfast_hit",
        "stop_phase_disc",
        "phase0_snap",
        "hit_idx",
    ],
    "cal_lut_key_with_boundary": [
        "ns_inf",
        "nf_inf",
        "nslow",
        "nfast_hit",
        "stop_phase_disc",
        "phase0_snap",
        "slow_boundary_inc",
        "hit_idx",
    ],
    "cal_lut_key_edge_nslow": [
        "ns_inf",
        "nf_inf",
        "nslow",
        "nfast_hit",
        "stop_phase_disc",
        "phase0_snap",
        "slow_boundary_inc",
        "hit_idx",
        "nslow_zero",
    ],
    "packet_context": [
        "nslow",
        "nfast_hit",
        "ns",
        "nf",
        "stop_phase_disc",
        "phase0_snap",
        "slow_boundary_inc",
        "hit_idx",
        "hit_count",
        "flags",
        "ctx_id",
    ],
}


@dataclass
class KeyStats:
    cols: list[str]
    data: dict[tuple[int, ...], list[float]] = field(default_factory=dict)

    def add_chunk(self, chunk: pd.DataFrame) -> None:
        work = chunk[[*self.cols, "true_dt_ps"]].copy()
        for col in self.cols:
            work[col] = numeric(work, col).fillna(SENTINEL).astype(np.int64)
        work["true_dt_ps"] = numeric(work, "true_dt_ps")
        work = work[work["true_dt_ps"].notna()]
        if work.empty:
            return
        work["_true2"] = work["true_dt_ps"] * work["true_dt_ps"]
        grouped = (
            work.groupby(self.cols, dropna=False, observed=True)
            .agg(
                count=("true_dt_ps", "size"),
                sum_true=("true_dt_ps", "sum"),
                sum_true2=("_true2", "sum"),
                min_true=("true_dt_ps", "min"),
                max_true=("true_dt_ps", "max"),
            )
            .reset_index()
        )
        for row in grouped.itertuples(index=False):
            key = tuple(int(getattr(row, col)) for col in self.cols)
            values = self.data.setdefault(
                key,
                [0.0, 0.0, 0.0, float("inf"), float("-inf")],
            )
            values[0] += float(row.count)
            values[1] += float(row.sum_true)
            values[2] += float(row.sum_true2)
            values[3] = min(values[3], float(row.min_true))
            values[4] = max(values[4], float(row.max_true))

    def to_frame(self) -> pd.DataFrame:
        rows: list[dict[str, object]] = []
        for key, values in self.data.items():
            count, sum_true, sum_true2, min_true, max_true = values
            row = {col: key[i] for i, col in enumerate(self.cols)}
            mean = sum_true / count if count else float("nan")
            row.update(
                {
                    "count": int(count),
                    "mean_true_ps": mean,
                    "sum_true_ps": sum_true,
                    "sum_true2_ps2": sum_true2,
                    "min_true_ps": min_true,
                    "max_true_ps": max_true,
                    "span_true_ps": max_true - min_true,
                }
            )
            rows.append(row)
        if not rows:
            return pd.DataFrame()
        return pd.DataFrame.from_records(rows)

    def means(self) -> dict[tuple[int, ...], float]:
        return {
            key: values[1] / values[0]
            for key, values in self.data.items()
            if values[0] > 0
        }


def rmse(values: np.ndarray | pd.Series) -> float:
    arr = np.asarray(values, dtype=float)
    if arr.size == 0:
        return float("nan")
    return float(math.sqrt(np.mean(arr * arr)))


def weighted_quantile(values: np.ndarray, weights: np.ndarray, quantile: float) -> float:
    values = np.asarray(values, dtype=float)
    weights = np.asarray(weights, dtype=float)
    valid = np.isfinite(values) & np.isfinite(weights) & (weights > 0)
    if not np.any(valid):
        return float("nan")
    order = np.argsort(values[valid])
    sorted_values = values[valid][order]
    sorted_weights = weights[valid][order]
    cdf = np.cumsum(sorted_weights)
    threshold = quantile * cdf[-1]
    return float(sorted_values[np.searchsorted(cdf, threshold, side="left")])


def safe_name(name: str) -> str:
    return re.sub(r"[^A-Za-z0-9_.-]+", "_", name).strip("_")


def parse_custom_key(spec: str) -> tuple[str, list[str]]:
    if ":" not in spec:
        raise ValueError(f"Custom key must use NAME:COL,COL syntax, got {spec!r}")
    name, cols = spec.split(":", 1)
    key_cols = [col.strip() for col in cols.split(",") if col.strip()]
    if not name.strip() or not key_cols:
        raise ValueError(f"Custom key must include name and columns, got {spec!r}")
    return safe_name(name.strip()), key_cols


def discover_code_density_paths(root: Path | None, csv_paths: list[str]) -> list[Path]:
    if csv_paths:
        return sorted(Path(path) for path in csv_paths)
    if root is None:
        raise ValueError("Either --root or explicit CSV paths must be provided.")
    paths = discover_stage_csvs(root, "code_density")
    if not paths:
        raise ValueError(f"No code_density CSV files found under {root}")
    return paths


def true_dt_ps(df: pd.DataFrame) -> pd.Series:
    if "true_dt_ps" in df.columns:
        return numeric(df, "true_dt_ps")
    if {"start_time_ps", "stop_time_ps"}.issubset(df.columns):
        return numeric(df, "stop_time_ps") - numeric(df, "start_time_ps")
    return numeric(df, "Tref_ps")


def mono_hit_mask(df: pd.DataFrame) -> pd.Series:
    missing = sorted(col for col in REQUIRED_FILTER_COLS if col not in df.columns)
    if missing:
        raise ValueError("Missing required mono-hit columns: " + ", ".join(missing))
    mask = (
        (numeric(df, "accepted").fillna(0).astype(int) == 1)
        & (numeric(df, "rejected").fillna(1).astype(int) == 0)
        & (numeric(df, "max_hits").fillna(-1).astype(int) == 1)
        & (numeric(df, "hit_idx").fillna(-1).astype(int) == 0)
        & (numeric(df, "hit_count").fillna(-1).astype(int) == 1)
        & numeric(df, "t_raw_ps").notna()
    )
    if "scalar_bin" in df.columns:
        mask &= numeric(df, "scalar_bin").notna()
    return mask


def infer_ns_nf(df: pd.DataFrame) -> pd.DataFrame:
    required = {"t_raw_ps", "nslow", "nfast_hit", "slow_boundary_inc"}
    if not required.issubset(df.columns):
        df["ns_inf"] = SENTINEL
        df["nf_inf"] = SENTINEL
        return df
    coef = (numeric(df, "t_raw_ps") // QUANT_PS).astype("Int64")
    resid = (
        coef
        - (numeric(df, "nslow").astype("Int64") + 2 + numeric(df, "slow_boundary_inc").astype("Int64") - 1) * K_SLOW
        - numeric(df, "nfast_hit").astype("Int64") * K_FAST
        - OFFSET
    )
    df["ns_inf"] = resid.map(lambda r: NSNF_REV.get(int(r), (SENTINEL, SENTINEL))[0] if pd.notna(r) else SENTINEL)
    df["nf_inf"] = resid.map(lambda r: NSNF_REV.get(int(r), (SENTINEL, SENTINEL))[1] if pd.notna(r) else SENTINEL)
    return df


def add_derived_columns(df: pd.DataFrame, edge_code: int | None) -> pd.DataFrame:
    df = infer_ns_nf(df.copy())
    if "nslow" in df.columns:
        df["nslow_zero"] = (numeric(df, "nslow").fillna(SENTINEL).astype(int) == 0).astype(int)
    else:
        df["nslow_zero"] = 0
    if "scalar_bin" in df.columns and edge_code is not None:
        df[f"scalar_bin_{edge_code}"] = (numeric(df, "scalar_bin").fillna(SENTINEL).astype(int) == edge_code).astype(int)
    return df


def iter_filtered_chunks(
    paths: Iterable[Path],
    chunksize: int,
    usecols: set[str],
    edge_code: int | None,
    delay_min_ps: float,
    delay_max_ps: float,
):
    for path in paths:
        for chunk in pd.read_csv(path, chunksize=chunksize, usecols=lambda col: col in usecols):
            chunk["source_file"] = str(path)
            mask = mono_hit_mask(chunk)
            if not mask.any():
                continue
            work = chunk.loc[mask].copy()
            work["true_dt_ps"] = true_dt_ps(work)
            work = work[work["true_dt_ps"].notna()]
            work = work[(work["true_dt_ps"] >= delay_min_ps) & (work["true_dt_ps"] <= delay_max_ps)]
            if work.empty:
                continue
            yield add_derived_columns(work, edge_code)


def available_key_sets(columns: set[str], custom_specs: list[str], edge_code: int | None) -> dict[str, list[str]]:
    key_sets = dict(DEFAULT_KEY_SETS)
    if edge_code is not None:
        edge_col = f"scalar_bin_{edge_code}"
        key_sets[f"cal_lut_key_edge_code_{edge_code}"] = [
            "ns_inf",
            "nf_inf",
            "nslow",
            "nfast_hit",
            "stop_phase_disc",
            "phase0_snap",
            "slow_boundary_inc",
            "hit_idx",
            edge_col,
        ]
        columns = set(columns)
        columns.add(edge_col)
    for spec in custom_specs:
        name, cols = parse_custom_key(spec)
        key_sets[name] = cols
    return {name: cols for name, cols in key_sets.items() if all(col in columns or col in {"ns_inf", "nf_inf", "nslow_zero"} for col in cols)}


def collect_columns(paths: list[Path], custom_specs: list[str], edge_code: int | None) -> tuple[set[str], set[str]]:
    custom_cols = {col for spec in custom_specs for col in parse_custom_key(spec)[1]}
    usecols = set(BASE_USECOLS) | custom_cols
    if edge_code is not None:
        usecols.add("scalar_bin")
    present: set[str] = set()
    for path in paths:
        header = pd.read_csv(path, nrows=0)
        present.update(header.columns)
    return present | {"ns_inf", "nf_inf", "nslow_zero"}, usecols


def seed_split(work: pd.DataFrame, validation_seed_mod: int) -> tuple[pd.DataFrame, pd.DataFrame]:
    if "seed" not in work.columns or validation_seed_mod <= 1:
        return work, work.iloc[0:0].copy()
    seed = numeric(work, "seed").fillna(SENTINEL).astype(int)
    valid_mask = (seed % validation_seed_mod) == 0
    return work.loc[~valid_mask].copy(), work.loc[valid_mask].copy()


def build_stats(
    paths: list[Path],
    key_sets: dict[str, list[str]],
    args: argparse.Namespace,
    usecols: set[str],
) -> tuple[dict[str, KeyStats], dict[str, KeyStats], dict[str, int]]:
    all_stats = {name: KeyStats(cols) for name, cols in key_sets.items()}
    train_stats = {name: KeyStats(cols) for name, cols in key_sets.items()}
    counters = {"rows_valid": 0, "rows_train": 0, "rows_validation": 0}
    for work in iter_filtered_chunks(
        paths,
        args.chunksize,
        usecols,
        args.edge_code,
        args.delay_min_ps,
        args.delay_max_ps,
    ):
        counters["rows_valid"] += int(len(work))
        train, validation = seed_split(work, args.validation_seed_mod)
        counters["rows_train"] += int(len(train))
        counters["rows_validation"] += int(len(validation))
        for name in key_sets:
            all_stats[name].add_chunk(work)
            if not train.empty:
                train_stats[name].add_chunk(train)
    return all_stats, train_stats, counters


def summarize_stats(
    name: str,
    stats: KeyStats,
    lsb_ps: float,
    top_dir: Path,
    top_keys: int,
) -> dict[str, object]:
    table = stats.to_frame()
    if table.empty:
        return {"key_name": name, "key_cols": stats.cols, "rows": 0}

    count = table["count"].to_numpy(dtype=float)
    span = table["span_true_ps"].to_numpy(dtype=float)
    total = int(count.sum())
    within_var_sum = float((table["sum_true2_ps2"] - (table["sum_true_ps"] ** 2) / table["count"]).sum())
    oracle_floor_rmse = math.sqrt(max(0.0, within_var_sum / total)) if total else float("nan")
    span_gt_1lsb = span > lsb_ps
    span_gt_2lsb = span > (2.0 * lsb_ps)
    summary = {
        "key_name": name,
        "key_cols": stats.cols,
        "rows": total,
        "unique_keys": int(len(table)),
        "ambiguous_keys_span_gt_1lsb": int(span_gt_1lsb.sum()),
        "ambiguous_rows_span_gt_1lsb": int(count[span_gt_1lsb].sum()) if np.any(span_gt_1lsb) else 0,
        "ambiguous_row_fraction_span_gt_1lsb": float(count[span_gt_1lsb].sum() / total) if total and np.any(span_gt_1lsb) else 0.0,
        "ambiguous_keys_span_gt_2lsb": int(span_gt_2lsb.sum()),
        "ambiguous_rows_span_gt_2lsb": int(count[span_gt_2lsb].sum()) if np.any(span_gt_2lsb) else 0,
        "ambiguous_row_fraction_span_gt_2lsb": float(count[span_gt_2lsb].sum() / total) if total and np.any(span_gt_2lsb) else 0.0,
        "oracle_floor_rmse_ps": oracle_floor_rmse,
        "weighted_p50_span_ps": weighted_quantile(span, count, 0.50),
        "weighted_p90_span_ps": weighted_quantile(span, count, 0.90),
        "weighted_p99_span_ps": weighted_quantile(span, count, 0.99),
        "max_span_ps": float(np.nanmax(span)) if len(span) else float("nan"),
    }
    top = table.sort_values(["span_true_ps", "count"], ascending=[False, False]).head(top_keys)
    top.to_csv(top_dir / f"worst_keys_{safe_name(name)}.csv", index=False)
    return summary


def residuals_against_means(
    paths: list[Path],
    cols: list[str],
    means: dict[tuple[int, ...], float],
    args: argparse.Namespace,
    usecols: set[str],
    validation_only: bool,
) -> tuple[np.ndarray, int, int]:
    chunks: list[np.ndarray] = []
    rows = 0
    misses = 0
    for work in iter_filtered_chunks(
        paths,
        args.chunksize,
        usecols,
        args.edge_code,
        args.delay_min_ps,
        args.delay_max_ps,
    ):
        if validation_only:
            _, work = seed_split(work, args.validation_seed_mod)
            if work.empty:
                continue
        for col in cols:
            work[col] = numeric(work, col).fillna(SENTINEL).astype(np.int64)
        keys = list(map(tuple, work[cols].to_numpy(dtype=np.int64)))
        mean = np.array([means.get(key, np.nan) for key in keys], dtype=float)
        true = numeric(work, "true_dt_ps").to_numpy(dtype=float)
        valid = np.isfinite(mean) & np.isfinite(true)
        rows += int(len(work))
        misses += int((~np.isfinite(mean)).sum())
        if np.any(valid):
            chunks.append(true[valid] - mean[valid])
    residual = np.concatenate(chunks) if chunks else np.array([], dtype=float)
    return residual, rows, misses


def add_exact_residual_metrics(
    summaries: list[dict[str, object]],
    key_sets: dict[str, list[str]],
    all_stats: dict[str, KeyStats],
    train_stats: dict[str, KeyStats],
    paths: list[Path],
    args: argparse.Namespace,
    usecols: set[str],
) -> None:
    by_name = {row["key_name"]: row for row in summaries}
    for name, cols in key_sets.items():
        residual, _, _ = residuals_against_means(
            paths,
            cols,
            all_stats[name].means(),
            args,
            usecols,
            validation_only=False,
        )
        row = by_name[name]
        row["oracle_floor_mae_ps"] = float(np.mean(np.abs(residual))) if len(residual) else float("nan")
        row["oracle_floor_p99_abs_ps"] = float(np.percentile(np.abs(residual), 99)) if len(residual) else float("nan")
        row["oracle_floor_p999_abs_ps"] = float(np.percentile(np.abs(residual), 99.9)) if len(residual) else float("nan")

        if args.validation_seed_mod > 1:
            valid_residual, valid_rows, valid_misses = residuals_against_means(
                paths,
                cols,
                train_stats[name].means(),
                args,
                usecols,
                validation_only=True,
            )
            row["validation_rows"] = int(valid_rows)
            row["validation_misses"] = int(valid_misses)
            row["validation_coverage"] = float((valid_rows - valid_misses) / valid_rows) if valid_rows else float("nan")
            row["validation_oracle_rmse_ps"] = rmse(valid_residual)
            row["validation_oracle_p99_abs_ps"] = float(np.percentile(np.abs(valid_residual), 99)) if len(valid_residual) else float("nan")


def verdict(summary: pd.DataFrame, lsb_ps: float) -> dict[str, object]:
    if summary.empty:
        return {"status": "no_data", "reason": "No key summary was produced."}
    ranked = summary.sort_values(
        ["validation_oracle_p99_abs_ps", "oracle_floor_p99_abs_ps", "weighted_p99_span_ps", "unique_keys"],
        ascending=[True, True, True, True],
        na_position="last",
    ).reset_index(drop=True)
    best = ranked.iloc[0].to_dict()
    p99 = best.get("validation_oracle_p99_abs_ps")
    if not np.isfinite(p99):
        p99 = best.get("oracle_floor_p99_abs_ps")
    span_p99 = best.get("weighted_p99_span_ps")
    span_gt_2 = best.get("ambiguous_row_fraction_span_gt_2lsb", 1.0)
    passes = (
        np.isfinite(p99)
        and float(p99) <= lsb_ps
        and np.isfinite(span_p99)
        and float(span_p99) <= 2.0 * lsb_ps
        and float(span_gt_2) == 0.0
    )
    return {
        "status": "software_key_candidate" if passes else "additional_discriminator_or_edge_policy_required",
        "best_key_name": best.get("key_name"),
        "best_key_cols": best.get("key_cols"),
        "best_validation_oracle_p99_abs_ps": best.get("validation_oracle_p99_abs_ps"),
        "best_oracle_floor_p99_abs_ps": best.get("oracle_floor_p99_abs_ps"),
        "best_weighted_p99_span_ps": best.get("weighted_p99_span_ps"),
        "lsb_ps": lsb_ps,
        "reason": (
            "Best key meets the strict oracle p99/span gate."
            if passes
            else "At least one strict oracle gate remains above 1 LSB or has >2 LSB key spans."
        ),
    }


def plot_summary(summary: pd.DataFrame, out_dir: Path, lsb_ps: float) -> None:
    if summary.empty:
        return
    plot_df = summary.sort_values("oracle_floor_p99_abs_ps").copy()
    x = np.arange(len(plot_df))
    fig, axes = plt.subplots(3, 1, figsize=(10, 8), sharex=True, constrained_layout=True)
    axes[0].bar(x, plot_df["oracle_floor_rmse_ps"], color="#1565c0")
    axes[0].axhline(lsb_ps, color="#c62828", ls="--", lw=1.0, label="1 LSB")
    axes[0].set_ylabel("RMSE oracle (ps)")
    axes[0].legend()

    axes[1].bar(x, plot_df["oracle_floor_p99_abs_ps"], color="#2e7d32")
    axes[1].axhline(lsb_ps, color="#c62828", ls="--", lw=1.0)
    axes[1].set_ylabel("P99 abs oracle (ps)")

    axes[2].bar(x, plot_df["weighted_p99_span_ps"], color="#ef6c00")
    axes[2].axhline(2.0 * lsb_ps, color="#c62828", ls="--", lw=1.0, label="2 LSB")
    axes[2].set_ylabel("P99 span cle (ps)")
    axes[2].set_xticks(x)
    axes[2].set_xticklabels(plot_df["key_name"], rotation=30, ha="right")
    axes[2].legend()
    for ax in axes:
        style_axes(ax)
    save_char_figure(fig, out_dir / "oracle_key_summary")


def write_report(summary: pd.DataFrame, verdict_data: dict[str, object], out_path: Path) -> None:
    lines = [
        "=" * 88,
        "MPTDC Oracle Calibration-Key Analysis",
        "=" * 88,
        "",
        f"Verdict: {verdict_data['status']}",
        f"Best key: {verdict_data.get('best_key_name')}",
        f"Reason: {verdict_data['reason']}",
        "",
        "A key with large true-delay span cannot guarantee event-level < 1 LSB",
        "without either another discriminator, a qualified edge policy, or an",
        "explicit specification exception for the ambiguous population.",
        "",
    ]
    if not summary.empty:
        header = (
            f"{'Key':<30s} {'Rows':>10s} {'Keys':>9s} {'RMSE':>9s} "
            f"{'P99':>9s} {'ValP99':>9s} {'P99Span':>9s} {'Rows>2LSB':>10s}"
        )
        lines.append(header)
        lines.append("-" * len(header))
        for _, row in summary.sort_values("oracle_floor_p99_abs_ps").iterrows():
            lines.append(
                f"{row['key_name']:<30s} {int(row['rows']):>10d} {int(row['unique_keys']):>9d} "
                f"{row['oracle_floor_rmse_ps']:>9.3f} {row['oracle_floor_p99_abs_ps']:>9.3f} "
                f"{row.get('validation_oracle_p99_abs_ps', float('nan')):>9.3f} "
                f"{row['weighted_p99_span_ps']:>9.3f} {row['ambiguous_rows_span_gt_2lsb']:>10d}"
            )
    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def run_analysis(args: argparse.Namespace) -> None:
    apply_char_style()
    paths = discover_code_density_paths(Path(args.root) if args.root else None, args.csv)
    present_cols, usecols = collect_columns(paths, args.key, args.edge_code)
    key_sets = available_key_sets(present_cols, args.key, args.edge_code)
    if not key_sets:
        raise RuntimeError("No candidate key set is available in the input CSV columns.")

    out_dir = Path(args.output_dir)
    tables_dir = out_dir / "tables"
    plots_dir = out_dir / "plots"
    tables_dir.mkdir(parents=True, exist_ok=True)
    plots_dir.mkdir(parents=True, exist_ok=True)

    all_stats, train_stats, counters = build_stats(paths, key_sets, args, usecols)
    if counters["rows_valid"] == 0:
        raise RuntimeError("No valid mono-hit rows after filters and delay-window selection.")

    summaries = [
        summarize_stats(name, stats, args.lsb_ps, tables_dir, args.top_keys)
        for name, stats in all_stats.items()
    ]
    add_exact_residual_metrics(summaries, key_sets, all_stats, train_stats, paths, args, usecols)
    summary_df = pd.DataFrame.from_records(summaries)
    verdict_data = verdict(summary_df, args.lsb_ps)

    summary = {
        "input_files": [str(path) for path in paths],
        "delay_min_ps": args.delay_min_ps,
        "delay_max_ps": args.delay_max_ps,
        "lsb_ps": args.lsb_ps,
        **counters,
        "verdict": verdict_data,
    }
    (out_dir / "oracle_summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    summary_df.to_csv(tables_dir / "oracle_key_summary.csv", index=False)
    write_report(summary_df, verdict_data, out_dir / "oracle_report.txt")
    if not args.no_plots:
        plot_summary(summary_df, plots_dir, args.lsb_ps)

    print(f"[ORACLE] valid rows: {counters['rows_valid']}")
    print(f"[ORACLE] verdict: {verdict_data['status']} best_key={verdict_data.get('best_key_name')}")
    print(f"[ORACLE] outputs: {out_dir}")


def run_self_test() -> None:
    base = pd.DataFrame(
        {
            "seed": [1, 1, 2, 2, 5, 5],
            "accepted": [1, 1, 1, 1, 1, 1],
            "rejected": [0, 0, 0, 0, 0, 0],
            "max_hits": [1, 1, 1, 1, 1, 1],
            "hit_idx": [0, 0, 0, 0, 0, 0],
            "hit_count": [1, 1, 1, 1, 1, 1],
            "Tref_ps": [20, 20, 100, 100, 20, 100],
            "true_dt_ps": [20, 20, 100, 100, 20, 100],
            "t_raw_ps": [1210, 1210, 1210, 1210, 1210, 1210],
            "nslow": [0, 0, 0, 0, 0, 0],
            "nfast_hit": [0, 0, 0, 0, 0, 0],
            "ns": [0, 0, 0, 0, 0, 0],
            "nf": [0, 0, 0, 0, 0, 0],
            "stop_phase_disc": [0, 0, 1, 1, 0, 1],
            "phase0_snap": [0, 0, 0, 0, 0, 0],
            "slow_boundary_inc": [0, 0, 0, 0, 0, 0],
            "scalar_bin": [121, 121, 121, 121, 121, 121],
        }
    )
    work = add_derived_columns(base, edge_code=121)
    with tempfile.TemporaryDirectory(prefix="mptdc_oracle_selftest_") as tmp:
        tmp_dir = Path(tmp)
        stats = KeyStats(["stop_phase_disc"])
        stats.add_chunk(work)
        summary = summarize_stats("disc", stats, 10.0, tmp_dir, 5)
        if summary["ambiguous_keys_span_gt_1lsb"] != 0:
            raise AssertionError("stop_phase_disc should disambiguate the synthetic delays")
        stats_alias = KeyStats(["scalar_bin"])
        stats_alias.add_chunk(work)
        summary_alias = summarize_stats("alias", stats_alias, 10.0, tmp_dir, 5)
        if summary_alias["ambiguous_keys_span_gt_1lsb"] == 0:
            raise AssertionError("scalar_bin should be ambiguous in the synthetic dataset")
    print("[SELFTEST] oracle key span discrimination: PASS")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="MPTDC oracle calibration-key sufficiency analyzer.")
    parser.add_argument("csv", nargs="*", help="Optional explicit code-density CSV paths.")
    parser.add_argument("--root", help="Characterization root containing stages/code_density.")
    parser.add_argument("--output-dir", default="results/characterization/oracle_analysis")
    parser.add_argument("--chunksize", type=int, default=DEFAULT_CHUNKSIZE)
    parser.add_argument("--delay-min-ps", type=float, default=20.0)
    parser.add_argument("--delay-max-ps", type=float, default=30_000.0)
    parser.add_argument("--lsb-ps", type=float, default=float(DELTA_LSB_PS))
    parser.add_argument("--validation-seed-mod", type=int, default=5)
    parser.add_argument("--edge-code", type=int, default=None, help="Optional known edge/saturation scalar code to test as a 1-bit class.")
    parser.add_argument("--key", action="append", default=[], metavar="NAME:COL,COL", help="Additional candidate key.")
    parser.add_argument("--top-keys", type=int, default=100)
    parser.add_argument("--no-plots", action="store_true")
    parser.add_argument("--self-test", action="store_true", help="Run synthetic self-test and exit.")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if args.self_test:
        run_self_test()
        return
    run_analysis(args)


if __name__ == "__main__":
    main()
