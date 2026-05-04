#!/usr/bin/env python3
"""
Fixed-delay characterization analysis for MPTDC campaign data.

Expected input layout:
    results/fixed_delay_campaign/
      delay_00020ps/<config>/seed_*.csv
      delay_00050ps/<config>/seed_*.csv
      ...

The script computes same-delay one-shot error metrics and actual same-delay
averaging curves from measured conversions.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))
SCRIPT_ROOT = SCRIPT_DIR.parent
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from analyze_campaign import basic_stats, discover_csv_files, load_config_data
from plot_style import PALETTE, apply_report_style, save_figure, style_axes

AVERAGING_N_VALUES = list(range(1, 16))
PLOT_N_VALUES = [1, 2, 4, 8, 15]
SELECTED_DELAY_TARGETS_PS = [20, 100, 1000, 10000, 30000]

apply_report_style()


def parse_delay_dir(path: Path) -> int | None:
    match = re.fullmatch(r"delay_(\d+)ps", path.name)
    if not match:
        return None
    return int(match.group(1))


def discover_fixed_delay_configs(root: Path, config_filter: str | None,
                                 max_files: int | None) -> dict[str, list[tuple[int, list[Path]]]]:
    """Return config -> [(delay_ps, [csv paths]), ...]."""
    configs: dict[str, list[tuple[int, list[Path]]]] = {}
    for delay_dir in sorted(root.iterdir()):
        if not delay_dir.is_dir():
            continue
        delay_ps = parse_delay_dir(delay_dir)
        if delay_ps is None:
            continue
        per_delay_cfgs = discover_csv_files(str(delay_dir), config_filter, max_files)
        for cfg, paths in per_delay_cfgs.items():
            configs.setdefault(cfg, []).append((delay_ps, paths))
    return {
        cfg: sorted(entries, key=lambda item: item[0])
        for cfg, entries in configs.items()
    }


def build_conversion_views(df: pd.DataFrame) -> dict[str, pd.DataFrame]:
    """Construct conversion-level estimators from row-level campaign data."""
    work = df.copy()
    work["error_ps"] = work["Tref_ps"] - work["t_raw_ps"]
    work["conv_uid"] = work["source_file"].astype(str) + "::" + work["conv_id"].astype(str)

    first_hit = (
        work.sort_values(["conv_uid", "hit_idx"])
            .groupby("conv_uid", as_index=False)
            .first()
            .copy()
    )
    first_hit["error_ps"] = first_hit["Tref_ps"] - first_hit["t_raw_ps"]

    conv_mean = (
        work.groupby("conv_uid", as_index=False)
            .agg(
                Tref_ps=("Tref_ps", "first"),
                t_raw_ps=("t_raw_ps", "mean"),
                hit_rows=("hit_idx", "size"),
                hit_count=("hit_count", "first"),
            )
            .copy()
    )
    conv_mean["error_ps"] = conv_mean["Tref_ps"] - conv_mean["t_raw_ps"]

    return {
        "row": work,
        "first_hit_scan": first_hit,
        "conv_mean": conv_mean,
    }


def run_same_delay_averaging(errors: np.ndarray, n_values: list[int], *,
                             n_trials: int, rng_seed: int) -> list[dict]:
    """Estimate RMSE after averaging N independently measured conversions."""
    arr = np.asarray(errors, dtype=float)
    if arr.size == 0:
        return []

    rng = np.random.RandomState(rng_seed)
    results: list[dict] = []
    for n_avg in n_values:
        replace = n_avg > arr.size
        means = np.empty(n_trials, dtype=float)
        for trial_idx in range(n_trials):
            pick = rng.choice(arr.size, size=n_avg, replace=replace)
            means[trial_idx] = float(arr[pick].mean())
        stats_dict = basic_stats(pd.Series(means))
        results.append({
            "N": n_avg,
            **stats_dict,
        })
    return results


def safe_name(name: str) -> str:
    return name.replace("/", "_").replace("\\", "_").replace(" ", "_")


def pick_representative_delays(delays: list[int], targets: list[int]) -> list[int]:
    """Pick a small set of existing delays closest to engineering targets."""
    if not delays:
        return []
    picked: list[int] = []
    for target in targets:
        nearest = min(delays, key=lambda value: abs(value - target))
        if nearest not in picked:
            picked.append(nearest)
    return picked


def plot_oneshot_vs_delay(summary_df: pd.DataFrame, config: str, out_dir: Path):
    """Plot one-shot RMSE versus fixed delay for each estimator."""
    if summary_df.empty:
        return

    labels = {
        "row": "Toutes les mesures",
        "first_hit_scan": "Premier hit scanne",
        "conv_mean": "Moyenne intra-conversion",
    }
    fig, ax = plt.subplots(figsize=(8, 4.5))
    for sample_kind, group in summary_df.groupby("sample_kind", observed=True):
        ax.plot(
            group["delay_ps"].values / 1000.0,
            group["rmse"].values,
            marker="o",
            lw=1.5,
            ms=3,
            label=labels.get(sample_kind, sample_kind),
        )
    ax.set_xlabel("Delai fixe (ns)")
    ax.set_ylabel("RMSE (ps)")
    ax.set_title(f"RMSE mono-mesure vs delai fixe – {config}")
    style_axes(ax)
    ax.legend()
    save_figure(fig, out_dir / f"fixed_delay_oneshot_rmse_{safe_name(config)}.png")


def plot_tail_vs_delay(summary_df: pd.DataFrame, config: str, out_dir: Path):
    """Plot P90/P99 absolute error versus fixed delay."""
    if summary_df.empty:
        return

    labels = {
        "row": "Toutes les mesures",
        "first_hit_scan": "Premier hit scanne",
        "conv_mean": "Moyenne intra-conversion",
    }
    fig, axes = plt.subplots(2, 1, figsize=(8, 6), sharex=True)
    for sample_kind, group in summary_df.groupby("sample_kind", observed=True):
        x = group["delay_ps"].values / 1000.0
        axes[0].plot(x, group["p90_ae"].values, marker="o", ms=3, lw=1.4,
                     label=labels.get(sample_kind, sample_kind))
        axes[1].plot(x, group["p99_ae"].values, marker="o", ms=3, lw=1.4,
                     label=labels.get(sample_kind, sample_kind))
    axes[0].set_ylabel("|Erreur| P90 (ps)")
    axes[0].set_title(f"Queues d'erreur vs delai fixe – {config}")
    axes[0].legend()
    axes[1].set_ylabel("|Erreur| P99 (ps)")
    axes[1].set_xlabel("Delai fixe (ns)")
    for ax in axes:
        style_axes(ax)
    save_figure(fig, out_dir / f"fixed_delay_tails_{safe_name(config)}.png")


def plot_averaging_vs_delay(avg_df: pd.DataFrame, config: str, estimator: str, out_dir: Path):
    """Plot same-delay averaging RMSE versus fixed delay for selected N."""
    subset = avg_df[avg_df["estimator"] == estimator].copy()
    if subset.empty:
        return

    estimator_title = {
        "first_hit_scan": "premier hit scanne",
        "conv_mean": "moyenne intra-conversion",
    }.get(estimator, estimator)

    fig, ax = plt.subplots(figsize=(8, 4.5))
    for n_avg in PLOT_N_VALUES:
        group = subset[subset["N"] == n_avg]
        if group.empty:
            continue
        ax.plot(group["delay_ps"].values / 1000.0, group["rmse"].values,
                marker="o", ms=3, lw=1.4, label=f"N={n_avg}")
    ax.set_xlabel("Delai fixe (ns)")
    ax.set_ylabel("RMSE (ps)")
    ax.set_title(f"Averaging meme-delai ({estimator_title}) – {config}")
    style_axes(ax)
    ax.legend(ncol=min(5, len(PLOT_N_VALUES)))
    save_figure(fig, out_dir / f"fixed_delay_avg_{estimator}_{safe_name(config)}.png")


def plot_averaging_vs_n(avg_df: pd.DataFrame, config: str, estimator: str, out_dir: Path):
    """Plot RMSE vs averaging depth for representative fixed delays."""
    subset = avg_df[avg_df["estimator"] == estimator].copy()
    if subset.empty:
        return

    delays = sorted(int(value) for value in subset["delay_ps"].unique())
    chosen_delays = pick_representative_delays(delays, SELECTED_DELAY_TARGETS_PS)
    if not chosen_delays:
        return

    estimator_title = {
        "first_hit_scan": "premier hit scanne",
        "conv_mean": "moyenne intra-conversion",
    }.get(estimator, estimator)

    fig, ax = plt.subplots(figsize=(8.5, 5))
    color_cycle = [PALETTE["blue"], PALETTE["red"], PALETTE["green"], PALETTE["purple"], PALETTE["orange"]]
    for color, delay_ps in zip(color_cycle, chosen_delays):
        group = subset[subset["delay_ps"] == delay_ps].sort_values("N")
        if group.empty:
            continue
        rmse = group["rmse"].values
        n_vals = group["N"].values
        ref = rmse[0] / np.sqrt(n_vals.astype(float))
        ax.plot(n_vals, rmse, marker="o", ms=3.5, lw=1.5, color=color,
                label=f"{delay_ps/1000.0:g} ns")
        ax.plot(n_vals, ref, ls="--", lw=1.0, color=color, alpha=0.45)
    ax.set_xscale("log")
    ax.set_yscale("log")
    ax.set_xlabel("Nombre de moyennes N")
    ax.set_ylabel("RMSE (ps)")
    ax.set_title(f"Averaging vs N ({estimator_title}) – {config}")
    style_axes(ax)
    ax.legend(title="Delai fixe")
    save_figure(fig, out_dir / f"fixed_delay_avg_vs_n_{estimator}_{safe_name(config)}.png")


def _json_ready(summary_df: pd.DataFrame, avg_df: pd.DataFrame) -> dict:
    """Convert fixed-delay outputs to a JSON-friendly structure."""
    result: dict[str, dict] = {}
    for cfg in sorted(summary_df["config"].unique()):
        cfg_summary = summary_df[summary_df["config"] == cfg].copy()
        cfg_avg = avg_df[avg_df["config"] == cfg].copy()
        result[cfg] = {
            "oneshot_summary": cfg_summary.to_dict(orient="records"),
            "averaging_summary": cfg_avg.to_dict(orient="records"),
        }
    return result


def write_text_report(summary_df: pd.DataFrame, avg_df: pd.DataFrame, out_path: Path):
    """Write a concise human-readable report."""
    lines: list[str] = []
    lines.append("=" * 80)
    lines.append("MPTDC Fixed-Delay Characterization Report")
    lines.append("=" * 80)
    lines.append("")
    lines.append("This report is based on repeated measurements at fixed injected delays.")
    lines.append("Averaging curves use actual same-delay conversion populations, not")
    lines.append("the mixed-delay global resampling flow used by calibrate_6d_lut.py.")
    lines.append("")

    for cfg in sorted(summary_df["config"].unique()):
        lines.append("-" * 80)
        lines.append(f"Config: {cfg}")
        lines.append("-" * 80)

        cfg_summary = summary_df[summary_df["config"] == cfg].copy()
        header = (
            f"{'Delay (ps)':>10s} {'Sample kind':<20s} {'Count':>10s} "
            f"{'RMSE':>9s} {'P90':>9s} {'P99':>9s}"
        )
        lines.append(header)
        lines.append("-" * len(header))
        for _, row in cfg_summary.iterrows():
            lines.append(
                f"{int(row['delay_ps']):>10d} {row['sample_kind']:<20s} "
                f"{int(row['count']):>10d} {row['rmse']:>9.2f} "
                f"{row['p90_ae']:>9.2f} {row['p99_ae']:>9.2f}"
            )

        cfg_avg = avg_df[avg_df["config"] == cfg].copy()
        if not cfg_avg.empty:
            lines.append("")
            lines.append("Selected same-delay averaging checkpoints")
            for estimator in sorted(cfg_avg["estimator"].unique()):
                subset = cfg_avg[(cfg_avg["estimator"] == estimator) & (cfg_avg["N"].isin(PLOT_N_VALUES))]
                if subset.empty:
                    continue
                lines.append(f"  Estimator: {estimator}")
                for _, row in subset.iterrows():
                    lines.append(
                        f"    delay={int(row['delay_ps']):>6d} ps  N={int(row['N']):>2d}  "
                        f"RMSE={row['rmse']:.2f} ps"
                    )
        lines.append("")

    lines.append("=" * 80)
    lines.append("End of report")
    lines.append("=" * 80)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(
        description="Analyze repeated fixed-delay MPTDC campaigns."
    )
    parser.add_argument("--campaign-dir", default="results/fixed_delay_campaign",
                        help="Root directory containing delay_<N>ps subdirectories.")
    parser.add_argument("--output-dir", default="results/fixed_delay_campaign/analysis",
                        help="Directory for CSV summaries, plots, and report.")
    parser.add_argument("--config-filter", default=None,
                        help="Glob filter passed to campaign discovery.")
    parser.add_argument("--max-files", type=int, default=None,
                        help="Cap CSV files loaded per config at each delay.")
    parser.add_argument("--n-trials", type=int, default=1000,
                        help="Trials per averaging point (default: 1000).")
    parser.add_argument("--no-plots", action="store_true",
                        help="Skip plot generation.")
    args = parser.parse_args()

    root = Path(args.campaign_dir)
    if not root.is_dir():
        raise SystemExit(f"[ERROR] Missing campaign directory: {root}")

    out_dir = Path(args.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    configs = discover_fixed_delay_configs(root, args.config_filter, args.max_files)
    if not configs:
        raise SystemExit("[ERROR] No fixed-delay CSV files found.")

    print(f"[INFO] Found {len(configs)} configuration(s) under {root}")

    summary_records: list[dict] = []
    averaging_records: list[dict] = []

    for cfg, entries in sorted(configs.items()):
        print(f"{'─' * 60}\nConfig: {cfg}\n{'─' * 60}")
        for delay_ps, paths in entries:
            df = load_config_data(paths)
            if df.empty:
                print(f"  [WARN] Empty dataset at {delay_ps} ps")
                continue
            views = build_conversion_views(df)

            for sample_kind, sample_df in views.items():
                stats_dict = basic_stats(sample_df["error_ps"])
                summary_records.append({
                    "config": cfg,
                    "delay_ps": delay_ps,
                    "sample_kind": sample_kind,
                    **stats_dict,
                })
                print(f"  delay={delay_ps:>6d} ps  kind={sample_kind:<16s} "
                      f"count={stats_dict['count']:>8d}  rmse={stats_dict['rmse']:.2f} ps")

            for estimator in ("first_hit_scan", "conv_mean"):
                errors = views[estimator]["error_ps"].to_numpy(dtype=float)
                for row in run_same_delay_averaging(
                    errors,
                    AVERAGING_N_VALUES,
                    n_trials=args.n_trials,
                    rng_seed=delay_ps,
                ):
                    averaging_records.append({
                        "config": cfg,
                        "delay_ps": delay_ps,
                        "estimator": estimator,
                        **row,
                    })

    summary_df = pd.DataFrame.from_records(summary_records)
    avg_df = pd.DataFrame.from_records(averaging_records)
    if summary_df.empty:
        raise SystemExit("[ERROR] No fixed-delay data could be analyzed.")

    summary_csv = out_dir / "fixed_delay_summary.csv"
    avg_csv = out_dir / "fixed_delay_averaging.csv"
    summary_df.sort_values(["config", "delay_ps", "sample_kind"]).to_csv(summary_csv, index=False)
    avg_df.sort_values(["config", "estimator", "delay_ps", "N"]).to_csv(avg_csv, index=False)
    print(f"[INFO] Wrote {summary_csv}")
    print(f"[INFO] Wrote {avg_csv}")
    json_path = out_dir / "fixed_delay_report.json"
    json_path.write_text(json.dumps(_json_ready(summary_df, avg_df), indent=2) + "\n", encoding="utf-8")
    print(f"[INFO] Wrote {json_path}")

    write_text_report(summary_df, avg_df, out_dir / "fixed_delay_report.txt")

    if not args.no_plots:
        for cfg in sorted(summary_df["config"].unique()):
            cfg_summary = summary_df[summary_df["config"] == cfg].copy()
            plot_oneshot_vs_delay(cfg_summary, cfg, out_dir)
            plot_tail_vs_delay(cfg_summary, cfg, out_dir)
            cfg_avg = avg_df[avg_df["config"] == cfg].copy()
            for estimator in ("first_hit_scan", "conv_mean"):
                plot_averaging_vs_delay(cfg_avg, cfg, estimator, out_dir)
                plot_averaging_vs_n(cfg_avg, cfg, estimator, out_dir)

    print("[INFO] Fixed-delay analysis complete.")


if __name__ == "__main__":
    main()
