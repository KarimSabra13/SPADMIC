#!/usr/bin/env python3
"""
Delay-by-delay short-format observability analysis for fixed-delay campaigns.

This script uses fixed-delay campaigns to answer a non-trivial question:

  "If a model is trained across the full delay range using only RAW_FEATURES-visible
   fields, what single-shot RMSE does it achieve at each held-out fixed delay, and
   what is the irreducible oracle floor of those visible fields?"

Unlike a naive same-delay fit, this analysis trains globally across delays and then
reports metrics by delay. That avoids the trivial zero-error result that appears when a
single fixed delay is allowed to calibrate itself.

Interpretation note:
  fixed-delay points are still a sparse characterization grid. A few isolated delay
  points may look artificially easy even when the continuous delay distribution remains
  observability-limited. Use analyze_shortformat_models.py delay-bucket outputs as the
  primary deployment-proof view, and this script as pointwise validation of selected
  delays.
"""

from __future__ import annotations

import argparse
import fnmatch
import json
import re
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

from calibrate_6d_lut import compute_metrics
from analyze_shortformat_models import (
    KEY_SETS,
    TARGET_PS,
    build_exact_lut,
    build_hier_visible,
    load_dataset,
)


def parse_args():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--campaign-dir", required=True,
                    help="Root fixed-delay campaign directory")
    ap.add_argument("--out-dir", required=True,
                    help="Output directory for tables, plots, and report")
    ap.add_argument("--config-filter", default="*",
                    help="Glob filter for config directory names")
    ap.add_argument("--train-seeds", type=int, default=2,
                    help="Number of seeds per delay used for training (default: 2)")
    ap.add_argument("--max-files-per-delay", type=int, default=None,
                    help="Optional cap on seed CSVs loaded at each delay")
    ap.add_argument("--no-core-filter", action="store_true",
                    help="Keep nslow==0 rows (default filters them out)")
    return ap.parse_args()


def parse_delay_ps(path: Path) -> int | None:
    match = re.fullmatch(r"delay_(\d+)ps", path.name)
    if not match:
        return None
    return int(match.group(1))


def discover_fixed_delay_configs(root: Path, config_filter: str,
                                 max_files_per_delay: int | None) -> dict[str, list[tuple[int, list[Path]]]]:
    configs: dict[str, list[tuple[int, list[Path]]]] = {}
    for delay_dir in sorted(root.iterdir()):
        if not delay_dir.is_dir():
            continue
        delay_ps = parse_delay_ps(delay_dir)
        if delay_ps is None:
            continue
        for cfg_dir in sorted(delay_dir.iterdir()):
            if not cfg_dir.is_dir():
                continue
            cfg_name = cfg_dir.name
            if not fnmatch.fnmatch(cfg_name, config_filter):
                continue
            files = sorted(cfg_dir.glob("seed_*.csv"))
            if max_files_per_delay is not None:
                files = files[:max_files_per_delay]
            if files:
                configs.setdefault(cfg_name, []).append((delay_ps, files))
    return {
        cfg: sorted(entries, key=lambda item: item[0])
        for cfg, entries in configs.items()
    }


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


def add_common_fields(row: dict, *, config: str, delay_ps: int,
                      train_rows: int, eval_rows: int) -> dict:
    out = dict(row)
    out["config"] = config
    out["delay_ps"] = int(delay_ps)
    out["train_rows"] = int(train_rows)
    out["eval_rows"] = int(eval_rows)
    return out


def apply_exact_lut(eval_df: pd.DataFrame, lut: pd.DataFrame, key_cols: list[str]) -> pd.DataFrame:
    merged = eval_df.merge(
        lut[["correction", "train_count"]].reset_index(),
        on=key_cols,
        how="left",
        copy=False,
    )
    matched = merged["correction"].notna()
    merged["error_ps"] = np.where(matched, merged["offset_ps"] - merged["correction"], np.nan)
    return merged


def apply_hier_visible(eval_df: pd.DataFrame, hier_model: dict) -> pd.DataFrame:
    res = eval_df.copy()
    corr_cols = []
    level_names = []
    for idx, (level_name, key_cols, lut_df) in enumerate(hier_model["levels"]):
        corr_col = f"corr_{idx}"
        corr_cols.append(corr_col)
        level_names.append(level_name)
        res = res.merge(
            lut_df.rename(columns={"correction": corr_col}),
            on=key_cols,
            how="left",
            copy=False,
        )

    corr_frame = res[corr_cols]
    res["correction"] = corr_frame.bfill(axis=1).iloc[:, 0].fillna(hier_model["global_mean"])
    res["error_ps"] = res["offset_ps"] - res["correction"]
    res["level_used"] = np.select(
        [res[col].notna() for col in corr_cols],
        level_names,
        default="global_mean",
    )
    return res


def grouped_metric_rows(df: pd.DataFrame, *, config: str, model_name: str, eval_set: str,
                        train_rows: int, coverage_col: str | None = None) -> list[dict]:
    rows = []
    for delay_ps, grp in df.groupby("delay_ps", sort=True):
        if coverage_col is None:
            matched_mask = pd.Series(True, index=grp.index)
        else:
            matched_mask = grp[coverage_col].notna()
        matched_rows = int(matched_mask.sum())
        total_rows = int(len(grp))
        errors = grp.loc[matched_mask, "error_ps"].to_numpy(dtype=float)
        row = {
            "train_corpus": "global_train",
            "model": model_name,
            "eval_set": eval_set,
            "coverage": matched_rows / total_rows if total_rows else 0.0,
            "matched_rows": matched_rows,
            "unmatched_rows": total_rows - matched_rows,
            **safe_metrics(errors, label=f"{model_name}/{delay_ps}"),
        }
        rows.append(add_common_fields(row, config=config, delay_ps=delay_ps,
                                      train_rows=train_rows, eval_rows=total_rows))
    return rows


def oracle_metric_rows(eval_df: pd.DataFrame, *, config: str, model_name: str,
                       key_cols: list[str], train_rows: int) -> list[dict]:
    oracle_mean = eval_df.groupby(key_cols)["offset_ps"].transform("mean")
    errors = eval_df["offset_ps"] - oracle_mean
    work = eval_df.copy()
    work["error_ps"] = errors
    return grouped_metric_rows(work, config=config, model_name=model_name,
                               eval_set="oracle_by_delay", train_rows=train_rows)


def raw_metric_rows(eval_df: pd.DataFrame, *, config: str, train_rows: int) -> list[dict]:
    work = eval_df.copy()
    work["error_ps"] = work["offset_ps"]
    return grouped_metric_rows(work, config=config, model_name="raw_uncalibrated",
                               eval_set="heldout_by_delay", train_rows=train_rows)


def practical_line_plot(practical_df: pd.DataFrame, config: str, out_path: Path):
    keep = practical_df[
        practical_df["model"].isin(["raw_uncalibrated", "current_6d", "short_core", "hier_visible"])
    ].copy()
    fig, ax = plt.subplots(figsize=(10, 6))
    for model_name in ["raw_uncalibrated", "current_6d", "short_core", "hier_visible"]:
        grp = keep[keep["model"] == model_name].sort_values("delay_ps")
        if grp.empty:
            continue
        ax.plot(grp["delay_ps"] / 1000.0, grp["rmse"], marker="o", ms=3, lw=1.4, label=model_name)

    ax.axhline(TARGET_PS, color="crimson", ls="--", lw=1.2, label="20 ps target")
    ax.set_xlabel("Fixed delay (ns)")
    ax.set_ylabel("RMSE (ps)")
    ax.set_title(f"Fixed-delay practical short-format RMSE – {config}")
    ax.grid(alpha=0.25)
    ax.legend()
    fig.tight_layout()
    fig.savefig(out_path, dpi=150, bbox_inches="tight")
    plt.close(fig)


def oracle_line_plot(oracle_df: pd.DataFrame, config: str, out_path: Path):
    fig, ax = plt.subplots(figsize=(10, 6))
    for model_name in ["current_6d", "boundary_aug", "short_core", "all_visible"]:
        grp = oracle_df[oracle_df["model"] == model_name].sort_values("delay_ps")
        if grp.empty:
            continue
        ax.plot(grp["delay_ps"] / 1000.0, grp["rmse"], marker="o", ms=3, lw=1.4, label=model_name)

    ax.axhline(TARGET_PS, color="crimson", ls="--", lw=1.2, label="20 ps target")
    ax.set_xlabel("Fixed delay (ns)")
    ax.set_ylabel("Oracle floor RMSE (ps)")
    ax.set_title(f"Fixed-delay oracle floor by visible key – {config}")
    ax.grid(alpha=0.25)
    ax.legend()
    fig.tight_layout()
    fig.savefig(out_path, dpi=150, bbox_inches="tight")
    plt.close(fig)


def coverage_plot(practical_df: pd.DataFrame, config: str, out_path: Path):
    keep = practical_df[
        practical_df["model"].isin(["current_6d", "boundary_aug", "short_core", "all_visible"])
    ].copy()
    fig, ax = plt.subplots(figsize=(10, 6))
    for model_name in ["current_6d", "boundary_aug", "short_core", "all_visible"]:
        grp = keep[keep["model"] == model_name].sort_values("delay_ps")
        if grp.empty:
            continue
        ax.plot(grp["delay_ps"] / 1000.0, grp["coverage"] * 100.0, marker="o", ms=3, lw=1.4,
                label=model_name)

    ax.set_xlabel("Fixed delay (ns)")
    ax.set_ylabel("Matched coverage (%)")
    ax.set_title(f"Exact-key coverage by delay – {config}")
    ax.set_ylim(0, 105)
    ax.grid(alpha=0.25)
    ax.legend()
    fig.tight_layout()
    fig.savefig(out_path, dpi=150, bbox_inches="tight")
    plt.close(fig)


def gain_plot(oracle_df: pd.DataFrame, config: str, out_path: Path):
    piv = oracle_df.pivot_table(index="delay_ps", columns="model", values="rmse", aggfunc="first")
    if not {"current_6d", "boundary_aug", "short_core", "all_visible"}.issubset(piv.columns):
        return
    gain_boundary = piv["current_6d"] - piv["boundary_aug"]
    gain_nfast = piv["boundary_aug"] - piv["short_core"]
    gain_all = piv["short_core"] - piv["all_visible"]

    fig, ax = plt.subplots(figsize=(10, 5))
    ax.plot(gain_boundary.index / 1000.0, gain_boundary.values, marker="o", ms=3, lw=1.4,
            label="current_6d - boundary_aug")
    ax.plot(gain_nfast.index / 1000.0, gain_nfast.values, marker="s", ms=3, lw=1.4,
            label="boundary_aug - short_core")
    ax.plot(gain_all.index / 1000.0, gain_all.values, marker="^", ms=3, lw=1.4,
            label="short_core - all_visible")
    ax.axhline(0.0, color="k", ls="--", lw=0.8)
    ax.set_xlabel("Fixed delay (ns)")
    ax.set_ylabel("Oracle RMSE improvement (ps)")
    ax.set_title(f"Information gain from extra visible fields – {config}")
    ax.grid(alpha=0.25)
    ax.legend()
    fig.tight_layout()
    fig.savefig(out_path, dpi=150, bbox_inches="tight")
    plt.close(fig)


def build_delay_summary(practical_df: pd.DataFrame, oracle_df: pd.DataFrame) -> pd.DataFrame:
    practical_piv = practical_df.pivot_table(index=["config", "delay_ps"], columns="model",
                                             values="rmse", aggfunc="first")
    oracle_piv = oracle_df.pivot_table(index=["config", "delay_ps"], columns="model",
                                       values="rmse", aggfunc="first")
    merged = practical_piv.join(oracle_piv, how="outer", lsuffix="_practical", rsuffix="_oracle")
    merged = merged.reset_index()

    if {"current_6d_oracle", "boundary_aug_oracle"}.issubset(merged.columns):
        merged["gain_boundary_ps"] = merged["current_6d_oracle"] - merged["boundary_aug_oracle"]
    if {"boundary_aug_oracle", "short_core_oracle"}.issubset(merged.columns):
        merged["gain_nfast_snap_ps"] = merged["boundary_aug_oracle"] - merged["short_core_oracle"]
    if {"short_core_oracle", "all_visible_oracle"}.issubset(merged.columns):
        merged["gain_all_visible_ps"] = merged["short_core_oracle"] - merged["all_visible_oracle"]
    return merged


def write_report(config: str, practical_df: pd.DataFrame, oracle_df: pd.DataFrame,
                 out_path: Path):
    practical_hier = practical_df[practical_df["model"] == "hier_visible"].sort_values("delay_ps")
    oracle_short = oracle_df[oracle_df["model"] == "short_core"].sort_values("delay_ps")
    oracle_all = oracle_df[oracle_df["model"] == "all_visible"].sort_values("delay_ps")
    oracle_curr = oracle_df[oracle_df["model"] == "current_6d"].sort_values("delay_ps")
    oracle_boundary = oracle_df[oracle_df["model"] == "boundary_aug"].sort_values("delay_ps")

    best_practical = practical_hier.loc[practical_hier["rmse"].idxmin()]
    worst_practical = practical_hier.loc[practical_hier["rmse"].idxmax()]
    best_oracle_short = oracle_short.loc[oracle_short["rmse"].idxmin()]
    worst_oracle_short = oracle_short.loc[oracle_short["rmse"].idxmax()]
    best_oracle_all = oracle_all.loc[oracle_all["rmse"].idxmin()]
    worst_oracle_all = oracle_all.loc[oracle_all["rmse"].idxmax()]

    oracle_piv = oracle_df.pivot_table(index="delay_ps", columns="model", values="rmse", aggfunc="first")
    gain_boundary = oracle_piv["current_6d"] - oracle_piv["boundary_aug"]
    gain_nfast = oracle_piv["boundary_aug"] - oracle_piv["short_core"]
    gain_all = oracle_piv["short_core"] - oracle_piv["all_visible"]

    short_hits = int((oracle_short["rmse"] <= TARGET_PS).sum())
    all_hits = int((oracle_all["rmse"] <= TARGET_PS).sum())
    total_delays = int(len(oracle_short))

    if short_hits == total_delays:
        conclusion = ("The robust short-format field set is sufficient across the full tested "
                      "delay range under this jitter setting; the remaining gap is practical-model limited.")
    elif all_hits == total_delays:
        conclusion = ("The full visible short-format field set is sufficient across the full "
                      "tested delay range, but the reduced robust key leaves measurable information unused.")
    elif max(short_hits, all_hits) > 0:
        conclusion = ("Some fixed-delay regions are compatible with sub-20 ps in principle, but "
                      "the short-format observable set does not support that target uniformly across the full range.")
    else:
        conclusion = ("Even the per-delay oracle floor stays above 20 ps across the tested range, "
                      "so the current short-format observable set is the dominant limiter under this jitter setting.")

    report = {
        "config": config,
        "target_ps": TARGET_PS,
        "delay_points": total_delays,
        "best_practical_hier_visible": best_practical.to_dict(),
        "worst_practical_hier_visible": worst_practical.to_dict(),
        "best_oracle_short_core": best_oracle_short.to_dict(),
        "worst_oracle_short_core": worst_oracle_short.to_dict(),
        "best_oracle_all_visible": best_oracle_all.to_dict(),
        "worst_oracle_all_visible": worst_oracle_all.to_dict(),
        "oracle_short_core_delays_le_target": short_hits,
        "oracle_all_visible_delays_le_target": all_hits,
        "boundary_gain_summary_ps": {
            "mean": float(gain_boundary.mean()),
            "median": float(gain_boundary.median()),
            "max": float(gain_boundary.max()),
        },
        "nfast_snap_gain_summary_ps": {
            "mean": float(gain_nfast.mean()),
            "median": float(gain_nfast.median()),
            "max": float(gain_nfast.max()),
        },
        "all_visible_gain_summary_ps": {
            "mean": float(gain_all.mean()),
            "median": float(gain_all.median()),
            "max": float(gain_all.max()),
        },
        "conclusion": conclusion,
    }
    out_path.with_suffix(".json").write_text(json.dumps(report, indent=2), encoding="utf-8")

    with out_path.open("w", encoding="utf-8") as fh:
        fh.write("MPTDC Fixed-Delay Short-Format Analysis\n")
        fh.write("=" * 40 + "\n\n")
        fh.write(f"Config: {config}\n")
        fh.write(f"Target: sub-{TARGET_PS:.0f} ps single-shot under jitter\n")
        fh.write(f"Delay points analyzed: {total_delays}\n\n")

        fh.write("Best practical 100% coverage model (hier_visible):\n")
        fh.write(f"  best delay  : {int(best_practical['delay_ps'])} ps\n")
        fh.write(f"  best RMSE   : {best_practical['rmse']:.2f} ps\n")
        fh.write(f"  worst delay : {int(worst_practical['delay_ps'])} ps\n")
        fh.write(f"  worst RMSE  : {worst_practical['rmse']:.2f} ps\n\n")

        fh.write("Oracle short_core floor:\n")
        fh.write(f"  best delay  : {int(best_oracle_short['delay_ps'])} ps @ {best_oracle_short['rmse']:.2f} ps\n")
        fh.write(f"  worst delay : {int(worst_oracle_short['delay_ps'])} ps @ {worst_oracle_short['rmse']:.2f} ps\n")
        fh.write(f"  delays <= 20 ps : {short_hits}/{total_delays}\n\n")

        fh.write("Oracle all_visible floor:\n")
        fh.write(f"  best delay  : {int(best_oracle_all['delay_ps'])} ps @ {best_oracle_all['rmse']:.2f} ps\n")
        fh.write(f"  worst delay : {int(worst_oracle_all['delay_ps'])} ps @ {worst_oracle_all['rmse']:.2f} ps\n")
        fh.write(f"  delays <= 20 ps : {all_hits}/{total_delays}\n\n")

        fh.write("Oracle improvement from adding slow-boundary metadata (current_6d -> boundary_aug):\n")
        fh.write(f"  mean / median / max : {gain_boundary.mean():.2f} / {gain_boundary.median():.2f} / {gain_boundary.max():.2f} ps\n\n")
        fh.write("Oracle improvement from adding nfast_snap after boundary bits (boundary_aug -> short_core):\n")
        fh.write(f"  mean / median / max : {gain_nfast.mean():.2f} / {gain_nfast.median():.2f} / {gain_nfast.max():.2f} ps\n\n")
        fh.write("Oracle improvement from adding all visible hit-identity fields (short_core -> all_visible):\n")
        fh.write(f"  mean / median / max : {gain_all.mean():.2f} / {gain_all.median():.2f} / {gain_all.max():.2f} ps\n\n")

        fh.write("Conclusion:\n")
        fh.write(f"  {conclusion}\n")


def load_global_splits(config: str, entries: list[tuple[int, list[Path]]], *,
                       train_seeds: int, core_only: bool) -> tuple[pd.DataFrame, pd.DataFrame]:
    train_frames = []
    eval_frames = []
    for delay_ps, files in entries:
        if len(files) <= train_seeds:
            print(f"  [WARN] delay {delay_ps} ps skipped: need > train_seeds files, found {len(files)}")
            continue
        train_files = files[:train_seeds]
        eval_files = files[train_seeds:]
        train_df = load_dataset(f"{config}:{delay_ps}:train", train_files, core_only=core_only)
        eval_df = load_dataset(f"{config}:{delay_ps}:eval", eval_files, core_only=core_only)
        if train_df.empty or eval_df.empty:
            print(f"  [WARN] delay {delay_ps} ps skipped after filtering: "
                  f"train_rows={len(train_df)} eval_rows={len(eval_df)}")
            continue
        train_df = train_df.copy()
        eval_df = eval_df.copy()
        train_df["delay_ps"] = delay_ps
        eval_df["delay_ps"] = delay_ps
        train_frames.append(train_df)
        eval_frames.append(eval_df)

    if not train_frames or not eval_frames:
        return pd.DataFrame(), pd.DataFrame()
    return (
        pd.concat(train_frames, ignore_index=True, copy=False),
        pd.concat(eval_frames, ignore_index=True, copy=False),
    )


def main():
    args = parse_args()
    root = Path(args.campaign_dir)
    out_dir = Path(args.out_dir)
    plots_dir = out_dir / "plots"
    tables_dir = out_dir / "tables"
    plots_dir.mkdir(parents=True, exist_ok=True)
    tables_dir.mkdir(parents=True, exist_ok=True)

    core_only = not args.no_core_filter
    configs = discover_fixed_delay_configs(root, args.config_filter, args.max_files_per_delay)
    if not configs:
        raise SystemExit("[ERROR] No fixed-delay CSV files found for the requested config filter.")

    for config, entries in sorted(configs.items()):
        print(f"[INFO] Config: {config} ({len(entries)} delay points)")
        train_df, eval_df = load_global_splits(config, entries, train_seeds=args.train_seeds, core_only=core_only)
        if train_df.empty or eval_df.empty:
            print(f"[WARN] No usable global train/eval split for {config}")
            continue

        practical_rows = raw_metric_rows(eval_df, config=config, train_rows=len(train_df))
        oracle_rows = []

        for key_name, key_cols in KEY_SETS.items():
            lut, _ = build_exact_lut(train_df, key_cols)
            exact_eval = apply_exact_lut(eval_df, lut, key_cols)
            practical_rows.extend(
                grouped_metric_rows(exact_eval, config=config, model_name=key_name,
                                    eval_set="heldout_by_delay", train_rows=len(train_df),
                                    coverage_col="correction")
            )
            oracle_rows.extend(
                oracle_metric_rows(eval_df, config=config, model_name=key_name,
                                   key_cols=key_cols, train_rows=len(train_df))
            )

        hier_model = build_hier_visible(train_df)
        hier_eval = apply_hier_visible(eval_df, hier_model)
        practical_rows.extend(
            grouped_metric_rows(hier_eval, config=config, model_name="hier_visible",
                                eval_set="heldout_by_delay", train_rows=len(train_df))
        )

        practical_df = pd.DataFrame(practical_rows)
        oracle_df = pd.DataFrame(oracle_rows)
        if practical_df.empty or oracle_df.empty:
            print(f"[WARN] No usable analysis rows for config {config}")
            continue

        practical_df.to_csv(tables_dir / f"{config}_practical_metrics.csv", index=False)
        oracle_df.to_csv(tables_dir / f"{config}_oracle_metrics.csv", index=False)
        build_delay_summary(practical_df, oracle_df).to_csv(
            tables_dir / f"{config}_delay_summary.csv", index=False
        )

        practical_line_plot(practical_df, config, plots_dir / f"{config}_practical_rmse_by_delay.png")
        oracle_line_plot(oracle_df, config, plots_dir / f"{config}_oracle_rmse_by_delay.png")
        coverage_plot(practical_df, config, plots_dir / f"{config}_exact_coverage_by_delay.png")
        gain_plot(oracle_df, config, plots_dir / f"{config}_oracle_gain_by_delay.png")
        write_report(config, practical_df, oracle_df, out_dir / f"{config}_report.txt")
        print(f"[INFO] Wrote fixed-delay short-format analysis for {config}")


if __name__ == "__main__":
    main()
