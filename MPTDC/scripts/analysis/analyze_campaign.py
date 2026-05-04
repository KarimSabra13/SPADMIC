#!/usr/bin/env python3
"""
Campaign-level analysis for MPTDC simulation results.

Loads all campaign CSVs from results/campaign/, computes statistics,
generates plots, and produces a summary report.

Author: Karim Sabra
"""

from __future__ import annotations

import argparse
import fnmatch
import json
import os
import sys
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.colors import TwoSlopeNorm
from scipy import stats

SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from plot_style import PALETTE, apply_report_style, save_figure, style_axes

# ---------------------------------------------------------------------------
# Vernier reconstruction constants & function
# ---------------------------------------------------------------------------
NE = 8
K_VERNIER = 11
DELTA_LSB = 10
VERNIER_NSLOW_ORIGIN_BIAS = 2
VERNIER_NFAST_ORIGIN_BIAS = 1
VERNIER_COEF_BIAS = 25


def vernier_tconv_ps(nslow, nfast, ns, nf, slow_boundary_inc):
    """Reconstruct timestamp in ps from vernier phase fields."""
    coef = (
        (nslow + VERNIER_NSLOW_ORIGIN_BIAS + slow_boundary_inc - 1) * K_VERNIER * NE
        + (nfast + VERNIER_NFAST_ORIGIN_BIAS - 1) * NE
        + ns * K_VERNIER
        - nf * (K_VERNIER - 1)
        + VERNIER_COEF_BIAS
    )
    return coef * DELTA_LSB


# vectorised version for entire dataframe columns
vernier_tconv_ps_vec = np.vectorize(vernier_tconv_ps)

# ---------------------------------------------------------------------------
# Flag bit definitions (bit-field positions)
# Active v2.4 packet flags are packed as:
#   bit 2 = closed_by_fast_maxhit
#   bit 1 = closed_by_maxhits
#   bit 0 = closed_by_watchdog
# ---------------------------------------------------------------------------
FLAG_CLOSED_BY_FAST_MAXHIT = 2
FLAG_CLOSED_BY_MAXHITS = 1
FLAG_CLOSED_BY_WATCHDOG = 0

FLAG_NAMES = {
    FLAG_CLOSED_BY_FAST_MAXHIT: "closed_by_fast_maxhit",
    FLAG_CLOSED_BY_MAXHITS: "closed_by_maxhits",
    FLAG_CLOSED_BY_WATCHDOG: "closed_by_watchdog",
}

PROFILE_DELAY_BINS = 60
PROFILE_TRAW_BINS = 60
DELAY_REGION_BANDS_PS = [
    ("20-200 ps", 20, 200),
    ("0.2-1 ns", 200, 1000),
    ("1-10 ns", 1000, 10_000),
    ("10-30 ns", 10_000, 30_000),
]

apply_report_style()


# ---------------------------------------------------------------------------
# Discovery helpers
# ---------------------------------------------------------------------------

def discover_csv_files(campaign_dir: str, config_filter: str | None = None,
                       max_files: int | None = None) -> dict[str, list[Path]]:
    """
    Walk *campaign_dir* and group CSV files by configuration name.

    Expected layout:
        campaign_dir/{mode}_{maxhits}_{source}_{jitter}/seed_{N}.csv

    Returns dict  config_name -> [path, …]
    """
    campaign_path = Path(campaign_dir)
    if not campaign_path.is_dir():
        print(f"[WARN] Campaign directory does not exist: {campaign_dir}")
        return {}

    configs: dict[str, list[Path]] = {}
    csv_files = sorted(campaign_path.rglob("*.csv"))

    for csv_path in csv_files:
        # config name = immediate parent directory name
        config_name = csv_path.parent.name
        if config_name == campaign_path.name:
            # CSV sits directly in campaign_dir – use filename stem
            config_name = csv_path.stem

        if config_filter and not fnmatch.fnmatch(config_name, config_filter):
            continue

        configs.setdefault(config_name, []).append(csv_path)

    # apply max-files cap per config
    if max_files is not None:
        configs = {k: v[:max_files] for k, v in configs.items()}

    return configs


def load_config_data(paths: list[Path]) -> pd.DataFrame:
    """Load and concatenate CSV files, skipping empty/corrupt ones."""
    frames = []
    for p in paths:
        try:
            df = pd.read_csv(p)
            if df.empty:
                continue
            df["source_file"] = str(p)
            frames.append(df)
        except Exception as exc:
            print(f"  [WARN] Could not load {p}: {exc}")
    if not frames:
        return pd.DataFrame()
    return pd.concat(frames, ignore_index=True)


# ---------------------------------------------------------------------------
# Analysis routines
# ---------------------------------------------------------------------------

def compute_residual(df: pd.DataFrame) -> pd.DataFrame:
    """Add offset_ps column = Tref_ps - t_raw_ps."""
    df = df.copy()
    df["offset_ps"] = df["Tref_ps"] - df["t_raw_ps"]
    return df


def cross_check_vernier(df: pd.DataFrame) -> int:
    """Compare Python vernier reconstruction with RTL t_raw_ps. Return mismatch count."""
    required = {"nslow", "nfast_hit", "ns", "nf", "slow_boundary_inc", "t_raw_ps"}
    if not required.issubset(df.columns):
        return -1  # cannot check

    py_t = vernier_tconv_ps_vec(
        df["nslow"].values,
        df["nfast_hit"].values,
        df["ns"].values,
        df["nf"].values,
        df["slow_boundary_inc"].values,
    )
    mismatches = int(np.sum(py_t != df["t_raw_ps"].values))
    return mismatches


def basic_stats(series: pd.Series) -> dict:
    """Return dict with mean, std, min, max, median, rmse."""
    arr = series.dropna().values.astype(float)
    if len(arr) == 0:
        return {
            "count": 0,
            "mean": np.nan,
            "std": np.nan,
            "min": np.nan,
            "max": np.nan,
            "median": np.nan,
            "rmse": np.nan,
            "mae": np.nan,
            "p90_ae": np.nan,
            "p99_ae": np.nan,
        }
    abs_arr = np.abs(arr)
    return {
        "count": len(arr),
        "mean": float(np.mean(arr)),
        "std": float(np.std(arr, ddof=1)) if len(arr) > 1 else 0.0,
        "min": float(np.min(arr)),
        "max": float(np.max(arr)),
        "median": float(np.median(arr)),
        "rmse": float(np.sqrt(np.mean(arr ** 2))),
        "mae": float(np.mean(abs_arr)),
        "p90_ae": float(np.percentile(abs_arr, 90)),
        "p99_ae": float(np.percentile(abs_arr, 99)),
    }


def compute_binned_profile(df: pd.DataFrame, x_col: str, error_col: str = "offset_ps",
                           *, n_bins: int = 60) -> pd.DataFrame:
    """Aggregate error metrics over evenly spaced bins of *x_col*."""
    if x_col not in df.columns or error_col not in df.columns:
        return pd.DataFrame()

    work = df[[x_col, error_col]].dropna().copy()
    if work.empty:
        return pd.DataFrame()

    x = work[x_col].astype(float)
    if x.nunique() < 2:
        return pd.DataFrame()

    edges = np.linspace(float(x.min()), float(x.max()), num=min(n_bins, x.nunique()) + 1)
    edges = np.unique(edges)
    if len(edges) < 2:
        return pd.DataFrame()

    work["bin"] = pd.cut(work[x_col], bins=edges, include_lowest=True, duplicates="drop")
    grouped = work.groupby("bin", observed=True)
    records: list[dict] = []
    for interval, grp in grouped:
        if grp.empty:
            continue
        stats_dict = basic_stats(grp[error_col])
        records.append({
            "x_lo": float(interval.left),
            "x_hi": float(interval.right),
            "x_mid": float((interval.left + interval.right) / 2.0),
            **stats_dict,
        })
    return pd.DataFrame.from_records(records)


def compute_discrete_profile(df: pd.DataFrame, x_col: str, error_col: str = "offset_ps") -> pd.DataFrame:
    """Aggregate error metrics over each discrete value of *x_col*."""
    if x_col not in df.columns or error_col not in df.columns:
        return pd.DataFrame()

    work = df[[x_col, error_col]].dropna().copy()
    if work.empty:
        return pd.DataFrame()

    grouped = work.groupby(x_col, observed=True)
    records: list[dict] = []
    for x_val, grp in grouped:
        if grp.empty:
            continue
        stats_dict = basic_stats(grp[error_col])
        records.append({"x": float(x_val), **stats_dict})
    return pd.DataFrame.from_records(records).sort_values("x", ignore_index=True)


def compute_delay_regions(df: pd.DataFrame, error_col: str = "offset_ps") -> pd.DataFrame:
    """Aggregate error metrics over fixed true-delay regions of engineering interest."""
    if "Tref_ps" not in df.columns or error_col not in df.columns:
        return pd.DataFrame()

    records: list[dict] = []
    for label, lo_ps, hi_ps in DELAY_REGION_BANDS_PS:
        mask = (df["Tref_ps"] >= lo_ps) & (df["Tref_ps"] < hi_ps)
        grp = df.loc[mask, error_col]
        stats_dict = basic_stats(grp)
        records.append({
            "label": label,
            "lo_ps": lo_ps,
            "hi_ps": hi_ps,
            **stats_dict,
        })
    return pd.DataFrame.from_records(records)


# ---------------------------------------------------------------------------
# INL / DNL
# ---------------------------------------------------------------------------

def compute_inl_dnl(t_raw: pd.Series, bin_width: float = DELTA_LSB):
    """
    Compute DNL and INL in LSBs.

    Returns (bin_edges, dnl, inl, peak_dnl, peak_inl).
    """
    arr = t_raw.dropna().values.astype(float)
    if len(arr) == 0:
        return np.array([]), np.array([]), np.array([]), np.nan, np.nan

    lo, hi = arr.min(), arr.max()
    bins = np.arange(lo, hi + bin_width, bin_width)
    counts, edges = np.histogram(arr, bins=bins)

    total = counts.sum()
    n_bins = len(counts)
    ideal_count = total / n_bins if n_bins else 1

    dnl = (counts / ideal_count) - 1.0
    inl = np.cumsum(dnl)

    peak_dnl = float(np.max(np.abs(dnl))) if len(dnl) else np.nan
    peak_inl = float(np.max(np.abs(inl))) if len(inl) else np.nan
    return edges, dnl, inl, peak_dnl, peak_inl


# ---------------------------------------------------------------------------
# Boundary-class analysis
# ---------------------------------------------------------------------------

def boundary_class_analysis(df: pd.DataFrame):
    """
    Split by (phase0_snap, slow_boundary_inc) -> 4 classes.
    Returns per-class stats dict and pairwise t-test results.
    """
    required = {"phase0_snap", "slow_boundary_inc", "offset_ps"}
    if not required.issubset(df.columns):
        return {}, []

    groups = df.groupby(["phase0_snap", "slow_boundary_inc"])
    class_stats = {}
    class_data = {}
    for name, grp in groups:
        s = basic_stats(grp["offset_ps"])
        class_stats[name] = s
        class_data[name] = grp["offset_ps"].dropna().values

    # pairwise t-tests
    keys = list(class_data.keys())
    ttest_results = []
    for i in range(len(keys)):
        for j in range(i + 1, len(keys)):
            a, b = class_data[keys[i]], class_data[keys[j]]
            if len(a) > 1 and len(b) > 1:
                t_stat, p_val = stats.ttest_ind(a, b, equal_var=False)
                ttest_results.append({
                    "class_a": keys[i],
                    "class_b": keys[j],
                    "t_stat": float(t_stat),
                    "p_value": float(p_val),
                    "significant": p_val < 0.05,
                })
    return class_stats, ttest_results


# ---------------------------------------------------------------------------
# Phase-class analysis (ns x nf heatmaps)
# ---------------------------------------------------------------------------

def phase_heatmaps(df: pd.DataFrame):
    """Return (mean, std, count) pivots indexed by (ns, nf)."""
    required = {"ns", "nf", "offset_ps"}
    if not required.issubset(df.columns):
        return None, None, None
    mean_piv = df.pivot_table(values="offset_ps", index="ns", columns="nf", aggfunc="mean")
    std_piv = df.pivot_table(values="offset_ps", index="ns", columns="nf", aggfunc="std")
    count_piv = df.pivot_table(values="offset_ps", index="ns", columns="nf", aggfunc="count")
    return mean_piv, std_piv, count_piv


# ---------------------------------------------------------------------------
# Flag distribution
# ---------------------------------------------------------------------------

def flag_distribution(df: pd.DataFrame) -> dict[str, int]:
    """Decode flag bits and count each closure type."""
    if "flags" not in df.columns:
        return {}
    dist = {}
    for bit, name in FLAG_NAMES.items():
        flags_arr = pd.to_numeric(df["flags"], errors="coerce").fillna(0).values.astype(int)
        dist[name] = int(((flags_arr >> bit) & 1).sum())
    return dist


# ---------------------------------------------------------------------------
# Plotting helpers
# ---------------------------------------------------------------------------

def _safe_config(name: str) -> str:
    """Sanitise config name for use in filenames."""
    return name.replace("/", "_").replace("\\", "_").replace(" ", "_")


def _annotate_heatmap(ax, matrix: np.ndarray, *, fmt: str):
    for row_idx in range(matrix.shape[0]):
        for col_idx in range(matrix.shape[1]):
            value = matrix[row_idx, col_idx]
            if np.isnan(value):
                continue
            ax.text(col_idx, row_idx, format(value, fmt),
                    ha="center", va="center", fontsize=7, color="black")


def plot_linearity(df: pd.DataFrame, config: str, out_dir: Path):
    """Scatter Traw vs Tref (sub-sampled)."""
    sub = df.sample(n=min(5000, len(df)), random_state=42)
    fig, ax = plt.subplots(figsize=(7, 5))
    ax.scatter(sub["Tref_ps"], sub["t_raw_ps"], s=1, alpha=0.4)
    ax.set_xlabel("Tref (ps)")
    ax.set_ylabel("t_raw (ps)")
    ax.set_title(f"Linearity – {config}")
    ax.plot(ax.get_xlim(), ax.get_xlim(), "r--", lw=0.8, label="ideal")
    ax.legend()
    style_axes(ax)
    save_figure(fig, out_dir / f"linearity_{_safe_config(config)}.png")


def plot_residual(df: pd.DataFrame, config: str, out_dir: Path):
    """Offset vs Tref."""
    sub = df.sample(n=min(5000, len(df)), random_state=42)
    fig, ax = plt.subplots(figsize=(7, 4))
    ax.scatter(sub["Tref_ps"], sub["offset_ps"], s=1, alpha=0.4, color=PALETTE["blue"])
    ax.axhline(0, color=PALETTE["gray"], lw=0.8)
    ax.set_xlabel("Tref (ps)")
    ax.set_ylabel("Offset (ps)")
    ax.set_title(f"Residual – {config}")
    style_axes(ax)
    save_figure(fig, out_dir / f"residual_{_safe_config(config)}.png")


def plot_residual_hist(df: pd.DataFrame, config: str, out_dir: Path):
    """Histogram of offset_ps per boundary class."""
    fig, ax = plt.subplots(figsize=(7, 4))
    if {"phase0_snap", "slow_boundary_inc"}.issubset(df.columns):
        for name, grp in df.groupby(["phase0_snap", "slow_boundary_inc"]):
            label = f"p0={name[0]},sbi={name[1]}"
            ax.hist(grp["offset_ps"].dropna(), bins=80, alpha=0.5, label=label)
        ax.legend(fontsize=7)
    else:
        ax.hist(df["offset_ps"].dropna(), bins=80, alpha=0.7)
    ax.set_xlabel("Offset (ps)")
    ax.set_ylabel("Count")
    ax.set_title(f"Residual histogram – {config}")
    style_axes(ax, grid_axis="y")
    save_figure(fig, out_dir / f"residual_hist_{_safe_config(config)}.png")


def plot_inl_dnl(edges, dnl, inl, config: str, out_dir: Path):
    """INL and DNL vs bin index."""
    fig, axes = plt.subplots(2, 1, figsize=(8, 6), sharex=True)
    x = np.arange(len(dnl))
    axes[0].bar(x, dnl, width=1.0, color=PALETTE["blue"])
    axes[0].set_ylabel("DNL (LSB)")
    axes[0].set_title(f"DNL – {config}")
    axes[1].plot(x, inl, color=PALETTE["orange"])
    axes[1].set_ylabel("INL (LSB)")
    axes[1].set_xlabel("Bin index")
    axes[1].set_title(f"INL – {config}")
    for ax in axes:
        style_axes(ax)
    save_figure(fig, out_dir / f"inl_dnl_{_safe_config(config)}.png")


def plot_phase_heatmap(matrix: pd.DataFrame, config: str, out_dir: Path, *,
                       stem: str, title: str, cbar_label: str,
                       cmap: str = "viridis", center_zero: bool = False,
                       fmt: str = ".1f"):
    """Generic heatmap for ns x nf phase statistics."""
    if matrix is None or matrix.empty:
        return
    fig, ax = plt.subplots(figsize=(6, 5))
    values = matrix.values.astype(float)
    norm = None
    if center_zero and np.isfinite(values).any():
        vmax = float(np.nanmax(np.abs(values)))
        if vmax > 0:
            norm = TwoSlopeNorm(vmin=-vmax, vcenter=0.0, vmax=vmax)
    im = ax.imshow(values, aspect="auto", origin="lower", cmap=cmap, norm=norm)
    ax.set_xlabel("nf")
    ax.set_ylabel("ns")
    ax.set_xticks(range(matrix.shape[1]))
    ax.set_yticks(range(matrix.shape[0]))
    ax.set_title(f"{title} – {config}")
    _annotate_heatmap(ax, values, fmt=fmt)
    fig.colorbar(im, ax=ax, label=cbar_label)
    save_figure(fig, out_dir / f"{stem}_{_safe_config(config)}.png")


def plot_boundary_class_summary(class_stats: dict, config: str, out_dir: Path):
    """Plot mean/RMSE/count per boundary class."""
    if not class_stats:
        return

    labels = [f"p0={p0}, sbi={sbi}" for p0, sbi in sorted(class_stats)]
    means = [class_stats[key]["mean"] for key in sorted(class_stats)]
    rmses = [class_stats[key]["rmse"] for key in sorted(class_stats)]
    counts = [class_stats[key]["count"] for key in sorted(class_stats)]

    fig, axes = plt.subplots(3, 1, figsize=(8.5, 8), sharex=True)
    axes[0].bar(labels, means, color=PALETTE["red"], alpha=0.85)
    axes[0].axhline(0.0, color=PALETTE["gray"], lw=0.8)
    axes[0].set_ylabel("Biais moyen (ps)")
    axes[0].set_title(f"Boundary classes – {config}")

    axes[1].bar(labels, rmses, color=PALETTE["blue"], alpha=0.85)
    axes[1].set_ylabel("RMSE (ps)")

    axes[2].bar(labels, counts, color=PALETTE["green"], alpha=0.85)
    axes[2].set_ylabel("Population")
    axes[2].set_xlabel("Classe de frontiere")

    for ax in axes:
        style_axes(ax, grid_axis="y")
    save_figure(fig, out_dir / f"boundary_class_summary_{_safe_config(config)}.png")


def plot_hit_count_dist(df: pd.DataFrame, config: str, out_dir: Path):
    """Hit-count histogram."""
    if "hit_count" not in df.columns:
        return
    fig, ax = plt.subplots(figsize=(6, 4))
    counts = df["hit_count"].value_counts().sort_index()
    ax.bar(counts.index, counts.values, color=PALETTE["teal"])
    ax.set_xlabel("hit_count")
    ax.set_ylabel("Conversions")
    ax.set_title(f"Hit-count distribution – {config}")
    style_axes(ax, grid_axis="y")
    save_figure(fig, out_dir / f"hit_count_dist_{_safe_config(config)}.png")


def plot_binned_profile(profile: pd.DataFrame, config: str, out_dir: Path, stem: str, *,
                        title: str, x_label: str, x_scale: float = 1.0):
    """Plot mean/RMSE and tail metrics for a binned profile."""
    if profile.empty:
        return

    x = profile["x_mid"].values / x_scale
    fig, axes = plt.subplots(2, 1, figsize=(8, 6), sharex=True)

    axes[0].plot(x, profile["rmse"].values, color="#1976d2", lw=1.6, label="RMSE")
    axes[0].plot(x, profile["mean"].values, color=PALETTE["red"], lw=1.1, label="Mean offset")
    axes[0].axhline(0, color="k", ls="--", lw=0.8)
    axes[0].set_ylabel("Erreur (ps)")
    axes[0].set_title(f"{title} – {config}")
    axes[0].legend()

    axes[1].plot(x, profile["p90_ae"].values, color=PALETTE["green"], lw=1.4, label="|err| P90")
    axes[1].plot(x, profile["p99_ae"].values, color=PALETTE["purple"], lw=1.4, label="|err| P99")
    axes[1].set_xlabel(x_label)
    axes[1].set_ylabel("|Erreur| (ps)")
    axes[1].legend()

    for ax in axes:
        style_axes(ax)
    save_figure(fig, out_dir / f"{stem}_{_safe_config(config)}.png")


def plot_discrete_profile(profile: pd.DataFrame, config: str, out_dir: Path, stem: str, *,
                          title: str, x_label: str):
    """Plot RMSE and tail metrics versus a discrete counter/code."""
    if profile.empty:
        return

    x = profile["x"].values
    fig, ax = plt.subplots(figsize=(8, 4.5))
    ax.plot(x, profile["rmse"].values, color=PALETTE["blue"], marker="o", ms=3, lw=1.4, label="RMSE")
    ax.plot(x, profile["p99_ae"].values, color=PALETTE["purple"], marker="s", ms=2.5, lw=1.1,
            label="|err| P99")
    ax.set_xlabel(x_label)
    ax.set_ylabel("Erreur (ps)")
    ax.set_title(f"{title} – {config}")
    ax.legend()
    style_axes(ax)
    save_figure(fig, out_dir / f"{stem}_{_safe_config(config)}.png")


def _json_ready_results(all_results: dict, ttest_all: dict) -> dict:
    """Convert analysis results to JSON-friendly scalars."""
    ready: dict[str, dict] = {}
    for cfg, res in sorted(all_results.items()):
        cfg_ready: dict[str, object] = {
            "offset_stats": res.get("offset_stats", {}),
            "peak_dnl": res.get("peak_dnl"),
            "peak_inl": res.get("peak_inl"),
            "mismatches": res.get("mismatches"),
            "flag_dist": res.get("flag_dist", {}),
            "ttest_results": ttest_all.get(cfg, []),
        }
        boundary = res.get("boundary_classes", {})
        cfg_ready["boundary_classes"] = {
            f"phase0_{key[0]}__sbi_{key[1]}": value
            for key, value in boundary.items()
        }
        for profile_name in ("delay_profile", "nslow_profile", "nfast_profile", "hit_idx_profile",
                             "traw_profile", "delay_regions"):
            profile = res.get(profile_name)
            if isinstance(profile, pd.DataFrame):
                cfg_ready[profile_name] = profile.to_dict(orient="records")
        ready[cfg] = cfg_ready
    return ready


# ---------------------------------------------------------------------------
# Summary report
# ---------------------------------------------------------------------------

def write_summary_report(all_results: dict, out_path: Path, ttest_all: dict):
    """Write a human-readable summary report."""
    lines: list[str] = []
    lines.append("=" * 80)
    lines.append("MPTDC Campaign Analysis – Summary Report")
    lines.append("=" * 80)
    lines.append("")

    # per-config table
    header = (
        f"{'Config':<40s} {'Count':>8s} {'Mean':>10s} {'Std':>10s} "
        f"{'RMSE':>10s} {'PkDNL':>8s} {'PkINL':>8s} {'XChk':>6s}"
    )
    lines.append(header)
    lines.append("-" * len(header))

    for cfg, res in sorted(all_results.items()):
        s = res.get("offset_stats", {})
        lines.append(
            f"{cfg:<40s} {s.get('count', 0):>8d} {s.get('mean', 0):>10.2f} "
            f"{s.get('std', 0):>10.2f} {s.get('rmse', 0):>10.2f} "
            f"{res.get('peak_dnl', float('nan')):>8.3f} "
            f"{res.get('peak_inl', float('nan')):>8.3f} "
            f"{res.get('mismatches', '?'):>6}"
        )
    lines.append("")

    # boundary-class significance
    lines.append("-" * 80)
    lines.append("Boundary-class t-test results")
    lines.append("-" * 80)
    for cfg, tests in sorted(ttest_all.items()):
        if not tests:
            continue
        lines.append(f"\n  Config: {cfg}")
        for t in tests:
            sig = "***" if t["significant"] else "   "
            lines.append(
                f"    {t['class_a']} vs {t['class_b']}: "
                f"t={t['t_stat']:.3f}  p={t['p_value']:.2e}  {sig}"
            )
    lines.append("")

    lines.append("-" * 80)
    lines.append("Delay / counter dependent summaries")
    lines.append("-" * 80)
    for cfg, res in sorted(all_results.items()):
        lines.append(f"\n  Config: {cfg}")

        delay_profile = res.get("delay_profile")
        if isinstance(delay_profile, pd.DataFrame) and not delay_profile.empty:
            worst_delay = delay_profile.loc[delay_profile["rmse"].idxmax()]
            lines.append(
                "    Worst delay bin : "
                f"{worst_delay['x_lo']:.0f}..{worst_delay['x_hi']:.0f} ps  "
                f"RMSE={worst_delay['rmse']:.2f} ps  P99={worst_delay['p99_ae']:.2f} ps"
            )

        regions = res.get("delay_regions")
        if isinstance(regions, pd.DataFrame) and not regions.empty:
            for _, row in regions.iterrows():
                lines.append(
                    f"    {row['label']:<10s}  count={int(row['count']):>8d}  "
                    f"RMSE={row['rmse']:>7.2f} ps  P99={row['p99_ae']:>7.2f} ps"
                )

        nslow_profile = res.get("nslow_profile")
        if isinstance(nslow_profile, pd.DataFrame) and not nslow_profile.empty:
            worst_nslow = nslow_profile.loc[nslow_profile["rmse"].idxmax()]
            lines.append(
                f"    Worst nslow     : {int(worst_nslow['x']):>3d}  "
                f"RMSE={worst_nslow['rmse']:.2f} ps  "
                f"P99={worst_nslow['p99_ae']:.2f} ps"
            )

        nfast_profile = res.get("nfast_profile")
        if isinstance(nfast_profile, pd.DataFrame) and not nfast_profile.empty:
            worst_nfast = nfast_profile.loc[nfast_profile["rmse"].idxmax()]
            lines.append(
                f"    Worst nfast_hit : {int(worst_nfast['x']):>3d}  "
                f"RMSE={worst_nfast['rmse']:.2f} ps  "
                f"P99={worst_nfast['p99_ae']:.2f} ps"
            )

    lines.append("")

    # cross-config comparison
    lines.append("-" * 80)
    lines.append("Cross-config comparison")
    lines.append("-" * 80)
    if all_results:
        best = min(all_results, key=lambda c: all_results[c].get("offset_stats", {}).get("rmse", float("inf")))
        worst = max(all_results, key=lambda c: all_results[c].get("offset_stats", {}).get("rmse", 0))
        lines.append(f"  Best  RMSE : {best} ({all_results[best]['offset_stats'].get('rmse', 0):.2f} ps)")
        lines.append(f"  Worst RMSE : {worst} ({all_results[worst]['offset_stats'].get('rmse', 0):.2f} ps)")
    lines.append("")

    # recommendations
    lines.append("-" * 80)
    lines.append("Calibration recommendations")
    lines.append("-" * 80)
    lines.append("  1. Apply per-boundary-class offset correction to reduce systematic bias.")
    lines.append("  2. Use ns×nf phase-map LUT for residual INL compensation.")
    lines.append("  3. Increase hit statistics in under-represented phase bins.")
    lines.append("  4. Re-run with jitter sweep to validate robustness of correction.")
    lines.append("")
    lines.append("=" * 80)
    lines.append("End of report")
    lines.append("=" * 80)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"[INFO] Summary report written to {out_path}")


# ---------------------------------------------------------------------------
# Main driver
# ---------------------------------------------------------------------------

def analyze_config(config: str, df: pd.DataFrame, out_dir: Path, *,
                   do_plots: bool = True) -> dict:
    """Run full analysis on one configuration, return results dict."""
    result: dict = {}

    # residual
    df = compute_residual(df)

    # basic stats
    result["offset_stats"] = basic_stats(df["offset_ps"])
    print(f"  Rows: {len(df):>10d}  |  Mean offset: {result['offset_stats']['mean']:.2f} ps  "
          f"|  Std: {result['offset_stats']['std']:.2f} ps  "
          f"|  RMSE: {result['offset_stats']['rmse']:.2f} ps")

    # cross-check
    mismatches = cross_check_vernier(df)
    result["mismatches"] = mismatches
    if mismatches == 0:
        print("  Vernier cross-check: PASS (0 mismatches)")
    elif mismatches > 0:
        print(f"  Vernier cross-check: FAIL ({mismatches} mismatches)")
    else:
        print("  Vernier cross-check: SKIPPED (missing columns)")

    # INL / DNL
    if "t_raw_ps" in df.columns:
        edges, dnl, inl, peak_dnl, peak_inl = compute_inl_dnl(df["t_raw_ps"])
        result["peak_dnl"] = peak_dnl
        result["peak_inl"] = peak_inl
        print(f"  Peak DNL: {peak_dnl:.3f} LSB  |  Peak INL: {peak_inl:.3f} LSB")
    else:
        edges, dnl, inl = np.array([]), np.array([]), np.array([])
        result["peak_dnl"] = np.nan
        result["peak_inl"] = np.nan

    # boundary-class
    class_stats, ttest_results = boundary_class_analysis(df)
    result["boundary_classes"] = class_stats
    result["ttest_results"] = ttest_results
    if class_stats:
        print(f"  Boundary classes found: {len(class_stats)}")

    # phase heatmaps
    mean_piv, std_piv, count_piv = phase_heatmaps(df)

    # flag distribution
    fdist = flag_distribution(df)
    result["flag_dist"] = fdist
    if fdist:
        parts = ", ".join(f"{k}={v}" for k, v in fdist.items())
        print(f"  Flags: {parts}")

    # first-class profiling views
    delay_profile = compute_binned_profile(df, "Tref_ps", n_bins=PROFILE_DELAY_BINS)
    nslow_profile = compute_discrete_profile(df, "nslow")
    nfast_profile = compute_discrete_profile(df, "nfast_hit")
    hit_idx_profile = compute_discrete_profile(df, "hit_idx")
    traw_profile = compute_binned_profile(df, "t_raw_ps", n_bins=PROFILE_TRAW_BINS)
    delay_regions = compute_delay_regions(df)

    result["delay_profile"] = delay_profile
    result["nslow_profile"] = nslow_profile
    result["nfast_profile"] = nfast_profile
    result["hit_idx_profile"] = hit_idx_profile
    result["traw_profile"] = traw_profile
    result["delay_regions"] = delay_regions

    out_dir.mkdir(parents=True, exist_ok=True)
    safe_cfg = _safe_config(config)
    if not delay_profile.empty:
        delay_profile.to_csv(out_dir / f"delay_profile_{safe_cfg}.csv", index=False)
        worst_delay = delay_profile.loc[delay_profile["rmse"].idxmax()]
        print("  Worst delay bin: "
              f"{worst_delay['x_lo']:.0f}..{worst_delay['x_hi']:.0f} ps  "
              f"RMSE={worst_delay['rmse']:.2f} ps  P99={worst_delay['p99_ae']:.2f} ps")
    if not nslow_profile.empty:
        nslow_profile.to_csv(out_dir / f"nslow_profile_{safe_cfg}.csv", index=False)
    if not nfast_profile.empty:
        nfast_profile.to_csv(out_dir / f"nfast_hit_profile_{safe_cfg}.csv", index=False)
    if not hit_idx_profile.empty:
        hit_idx_profile.to_csv(out_dir / f"hit_idx_profile_{safe_cfg}.csv", index=False)
    if not traw_profile.empty:
        traw_profile.to_csv(out_dir / f"t_raw_profile_{safe_cfg}.csv", index=False)
    if not delay_regions.empty:
        delay_regions.to_csv(out_dir / f"delay_regions_{safe_cfg}.csv", index=False)
    if count_piv is not None and not count_piv.empty:
        count_piv.to_csv(out_dir / f"phase_count_heatmap_{safe_cfg}.csv")

    # plots
    if do_plots:
        try:
            if {"Tref_ps", "t_raw_ps"}.issubset(df.columns):
                plot_linearity(df, config, out_dir)
                plot_residual(df, config, out_dir)
            plot_residual_hist(df, config, out_dir)
            if len(dnl) > 0:
                plot_inl_dnl(edges, dnl, inl, config, out_dir)
            if mean_piv is not None and not mean_piv.empty:
                plot_phase_heatmap(mean_piv, config, out_dir,
                                   stem="phase_heatmap_mean",
                                   title="Biais moyen ns×nf",
                                   cbar_label="ps",
                                   cmap="RdBu_r",
                                   center_zero=True)
            if std_piv is not None and not std_piv.empty:
                plot_phase_heatmap(std_piv, config, out_dir,
                                   stem="phase_heatmap_std",
                                   title="Ecart-type ns×nf",
                                   cbar_label="ps",
                                   cmap="viridis")
            if count_piv is not None and not count_piv.empty:
                plot_phase_heatmap(count_piv, config, out_dir,
                                   stem="phase_heatmap_count",
                                   title="Occupation ns×nf",
                                   cbar_label="echantillons",
                                   cmap="magma",
                                   fmt=".0f")
            plot_boundary_class_summary(class_stats, config, out_dir)
            plot_hit_count_dist(df, config, out_dir)
            plot_binned_profile(delay_profile, config, out_dir, "delay_error_profile",
                                title="Error profile vs Tref",
                                x_label="True delay (ns)", x_scale=1000.0)
            plot_discrete_profile(nslow_profile, config, out_dir, "nslow_error_profile",
                                  title="Error profile vs nslow", x_label="nslow")
            plot_discrete_profile(nfast_profile, config, out_dir, "nfast_hit_error_profile",
                                  title="Error profile vs nfast_hit", x_label="nfast_hit")
            plot_discrete_profile(hit_idx_profile, config, out_dir, "hit_idx_error_profile",
                                  title="Error profile vs hit_idx", x_label="hit_idx")
            plot_binned_profile(traw_profile, config, out_dir, "t_raw_error_profile",
                                title="Error profile vs t_raw",
                                x_label="t_raw (ns)", x_scale=1000.0)
            print(f"  Plots saved to {out_dir}/")
        except Exception as exc:
            print(f"  [WARN] Plot generation error: {exc}")

    return result


def main():
    parser = argparse.ArgumentParser(
        description="MPTDC campaign analysis – load CSVs, compute stats, generate plots & report."
    )
    parser.add_argument("--campaign-dir", default="results/campaign/",
                        help="Root directory of campaign CSV files (default: results/campaign/)")
    parser.add_argument("--output-dir", default="results/campaign/analysis/",
                        help="Directory for output plots and report (default: results/campaign/analysis/)")
    parser.add_argument("--config-filter", default=None,
                        help="Glob pattern to select configurations (e.g. 'multihit_15_*')")
    parser.add_argument("--max-files", type=int, default=None,
                        help="Max CSV files to load per config (for quick testing)")
    parser.add_argument("--no-plots", action="store_true",
                        help="Skip plot generation")
    args = parser.parse_args()

    out_dir = Path(args.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    # discover
    configs = discover_csv_files(args.campaign_dir, args.config_filter, args.max_files)
    if not configs:
        print("[ERROR] No CSV files found. Check --campaign-dir path.")
        sys.exit(1)

    print(f"[INFO] Found {len(configs)} configuration(s) in {args.campaign_dir}")
    for cfg, paths in configs.items():
        print(f"  {cfg}: {len(paths)} file(s)")
    print()

    all_results: dict[str, dict] = {}
    ttest_all: dict[str, list] = {}

    for cfg, paths in sorted(configs.items()):
        print(f"{'─' * 60}")
        print(f"Config: {cfg}")
        print(f"{'─' * 60}")

        df = load_config_data(paths)
        if df.empty:
            print("  [WARN] No data – skipping.\n")
            continue

        result = analyze_config(cfg, df, out_dir, do_plots=not args.no_plots)
        all_results[cfg] = result
        ttest_all[cfg] = result.get("ttest_results", [])
        print()

    # summary report
    report_path = out_dir / "summary_report.txt"
    write_summary_report(all_results, report_path, ttest_all)
    summary_json = out_dir / "summary_report.json"
    summary_json.write_text(
        json.dumps(_json_ready_results(all_results, ttest_all), indent=2, default=str) + "\n",
        encoding="utf-8",
    )
    print(f"[INFO] Summary JSON written to {summary_json}")

    print("[INFO] Analysis complete.")


if __name__ == "__main__":
    main()
