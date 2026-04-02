#!/usr/bin/env python3
# ==============================================================================
#  MPTDC MVUE (Minimum Variance Unbiased Estimator) Calibrator
# ==============================================================================
#  Enhances the 6D LUT calibration with:
#    1. Optimal intra-conversion hit averaging (MVUE weights from covariance)
#    2. Nslow-dependent inter-conversion weighting (1/σ²(nslow))
#    3. Intra-conversion variance quality gating
#    4. Combined pipeline validation
#
#  The MVUE approach exploits the fact that hits within a single conversion
#  share correlated slow-oscillator jitter (ρ ≈ 0.46) while fast-side noise
#  is partially independent. Optimal weights are derived from the full 15×15
#  error covariance matrix.
#
#  Usage:
#    python3 scripts/calibration/calibrate_mvue.py \
#       --train-dir  results/.../train/multihit_15_cal_jitter_raw_features \
#       --val-dir    results/.../val/multihit_15_cal_jitter_raw_features \
#       --fresh-dir  results/.../fresh/multihit_15_cal_jitter_raw_features \
#       --out-dir    results/.../calibration_mvue
#
#  Author : Karim Sabra
# ==============================================================================
from __future__ import annotations

import argparse
import gc
import json
import os
import sys
import time

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
import numpy as np
import pandas as pd

# ── Import shared helpers from the 6D LUT calibrator ──────────────────────────
sys.path.insert(0, os.path.dirname(__file__))
from calibrate_6d_lut import (
    LUT_KEY, K_SLOW, K_FAST, K_VERNIER, OFFSET, QUANT,
    infer_ns_nf, build_lut, apply_lut, compute_metrics, print_metrics,
    plot_error_histogram, plot_comparison_bar, plot_qq,
)

# ── Constants ─────────────────────────────────────────────────────────────────
SHORT_CORE_KEY = [
    "ns_inf", "nf_inf", "nslow", "nfast_hit",
    "nfast_snap", "phase0_snap", "slow_boundary_inc", "hit_idx"
]

# Jitter accumulation model parameters (fitted from data):
#   within_bin_std ≈ JITTER_SLOPE * √nslow + JITTER_INTERCEPT
JITTER_SLOPE     = 5.16   # ps per √nslow
JITTER_INTERCEPT = 25.44  # ps baseline


# ── Helpers ───────────────────────────────────────────────────────────────────

def load_csvs(csv_dir, max_files=None):
    """Load all seed CSVs from a directory."""
    import glob as globmod
    pattern = os.path.join(csv_dir, "seed_*.csv")
    files = sorted(globmod.glob(pattern))
    if max_files:
        files = files[:max_files]
    if not files:
        print(f"  ERROR: no seed_*.csv files in {csv_dir}")
        sys.exit(1)
    return files


def load_and_tag(csv_files, core_only=True):
    """Load CSVs, tag with conversion IDs, infer ns/nf."""
    frames = []
    global_conv = 0
    for fi, f in enumerate(csv_files):
        d = pd.read_csv(f)
        # Build conversion boundaries from hit_idx resets
        conv_breaks = (d["hit_idx"].diff().fillna(0) < 0).cumsum()
        d["conv_id"] = global_conv + conv_breaks
        global_conv = d["conv_id"].max() + 1
        frames.append(d)
        if (fi + 1) % 10 == 0:
            print(f"    ... loaded {fi+1}/{len(csv_files)} seeds")

    df = pd.concat(frames, ignore_index=True)
    if core_only:
        n_before = len(df)
        df = df[df["nslow"] > 0].copy()
        pct = (1 - len(df) / n_before) * 100 if n_before else 0
        print(f"  Core filter: removed {n_before - len(df):,} rows "
              f"({pct:.1f}%) with nslow=0")

    df["offset"] = df["Tref_ps"] - df["t_raw_ps"]
    infer_ns_nf(df)
    bad = df["ns_inf"].isna().sum()
    if bad:
        print(f"  WARNING: {bad} rows failed ns/nf inference – dropped")
        df = df.dropna(subset=["ns_inf", "nf_inf"])
    return df


def compute_mvue_weights(cal_errors_pivot):
    """Compute MVUE optimal weights from the covariance matrix.

    Given a (n_conv × K) matrix of calibrated errors (one column per hit_idx),
    returns the K-vector of optimal weights that minimizes the variance of the
    weighted average.

    w_mvue = Σ⁻¹ 1 / (1ᵀ Σ⁻¹ 1)
    """
    cov = np.cov(cal_errors_pivot, rowvar=False)
    K = cov.shape[0]
    ones = np.ones(K)

    try:
        cov_inv = np.linalg.inv(cov)
    except np.linalg.LinAlgError:
        # Singular — fallback to pseudoinverse
        cov_inv = np.linalg.pinv(cov)

    w = cov_inv @ ones / (ones @ cov_inv @ ones)

    # Theoretical variance of MVUE estimator
    var_mvue = 1.0 / (ones @ cov_inv @ ones)
    var_simple = (ones @ cov @ ones) / K**2

    return w, np.sqrt(var_mvue), np.sqrt(var_simple), cov


def sigma_nslow(nslow):
    """Expected per-conversion jitter std as a function of nslow."""
    return JITTER_SLOPE * np.sqrt(nslow) + JITTER_INTERCEPT


def apply_mvue_intra_conv(df, lut, weights, max_hits):
    """Apply LUT calibration + MVUE intra-conversion averaging.

    Returns a DataFrame with one row per conversion containing:
    - conv_id, Tref_ps, nslow, n_hits
    - mvue_cal_ps: MVUE-averaged calibrated timestamp
    - simple_cal_ps: simple-mean calibrated timestamp
    - mvue_error_ps, simple_error_ps, raw_error_ps
    """
    # Apply LUT
    merged = apply_lut(df, lut)

    # For each conversion, compute MVUE average
    results = []
    for conv_id, grp in merged.groupby("conv_id"):
        tref = grp["Tref_ps"].iloc[0]
        nslow_val = grp["nslow"].iloc[0]
        n_hits = len(grp)

        # Get per-hit calibrated timestamps
        cal_ts = grp["cal_ps"].values
        raw_ts = grp["t_raw_ps"].values
        hit_idxs = grp["hit_idx"].values.astype(int)

        # Simple mean
        simple_cal = np.nanmean(cal_ts)

        # MVUE: use weights indexed by hit_idx
        valid = ~np.isnan(cal_ts)
        if valid.sum() == 0:
            continue

        w_sel = np.zeros(len(cal_ts))
        for i, hi in enumerate(hit_idxs):
            if hi < max_hits and valid[i]:
                w_sel[i] = weights[hi]
        w_sum = w_sel.sum()
        if w_sum > 0:
            w_norm = w_sel / w_sum
            mvue_cal = np.sum(w_norm * cal_ts)
        else:
            mvue_cal = simple_cal

        # Intra-conversion std (for quality gating)
        intra_std = np.nanstd(cal_ts) if n_hits >= 2 else np.nan

        results.append({
            "conv_id": conv_id,
            "Tref_ps": tref,
            "nslow": nslow_val,
            "n_hits": n_hits,
            "mvue_cal_ps": mvue_cal,
            "simple_cal_ps": simple_cal,
            "raw_cal_ps": np.nanmean(raw_ts),
            "mvue_error_ps": tref - mvue_cal,
            "simple_error_ps": tref - simple_cal,
            "raw_error_ps": tref - np.nanmean(raw_ts),
            "intra_std": intra_std,
        })

    return pd.DataFrame(results)


def inter_conv_averaging(conv_df, n_values, method="mvue", use_nslow_weight=False,
                         use_quality_gate=False, quality_pct=90,
                         n_trials=3000, rng_seed=42):
    """Simulate inter-conversion averaging with various strategies.

    Returns a list of dicts with (N, rmse, mae, p90) for each N.
    """
    rng = np.random.RandomState(rng_seed)
    err_col = f"{method}_error_ps"

    df = conv_df.dropna(subset=[err_col]).copy()

    # Quality gating: remove top (100-quality_pct)% noisy conversions
    if use_quality_gate:
        thresh = df["intra_std"].quantile(quality_pct / 100.0)
        df = df[df["intra_std"] <= thresh]

    errors = df[err_col].values
    nslow_vals = df["nslow"].values

    # Nslow weights
    if use_nslow_weight:
        sigma_sq = (JITTER_SLOPE * np.sqrt(nslow_vals) + JITTER_INTERCEPT) ** 2
        weights = 1.0 / sigma_sq
        weights /= weights.sum()  # normalize
    else:
        weights = np.ones(len(errors)) / len(errors)

    results = []
    n_total = len(errors)

    for N in n_values:
        if N > n_total:
            break
        trial_avgs = np.empty(n_trials)
        for t in range(n_trials):
            idx = rng.choice(n_total, N, replace=True)
            if use_nslow_weight:
                w_sel = weights[idx]
                w_sel = w_sel / w_sel.sum()
                trial_avgs[t] = np.sum(w_sel * errors[idx])
            else:
                trial_avgs[t] = errors[idx].mean()
        rmse = np.sqrt(np.mean(trial_avgs**2))
        mae = np.mean(np.abs(trial_avgs))
        p90 = np.percentile(np.abs(trial_avgs), 90)
        results.append({"N": N, "rmse": rmse, "mae": mae, "p90": p90})

    return results


# ── Plotting ──────────────────────────────────────────────────────────────────

def plot_mvue_weights(weights, cov_mat, out_path):
    """Plot MVUE weights and correlation matrix."""
    fig, axes = plt.subplots(1, 2, figsize=(14, 5))

    ax = axes[0]
    ax.bar(range(len(weights)), weights, color="steelblue", edgecolor="navy")
    ax.axhline(1.0/len(weights), color="red", linestyle="--", alpha=0.7,
               label=f"Uniform = {1.0/len(weights):.4f}")
    ax.set_xlabel("hit_idx")
    ax.set_ylabel("Weight")
    ax.set_title("MVUE Optimal Weights per Hit Index")
    ax.legend()

    ax = axes[1]
    # Correlation matrix
    std = np.sqrt(np.diag(cov_mat))
    corr = cov_mat / np.outer(std, std)
    im = ax.imshow(corr, cmap="RdBu_r", vmin=-1, vmax=1, aspect="equal")
    ax.set_xlabel("hit_idx")
    ax.set_ylabel("hit_idx")
    ax.set_title("Inter-Hit Error Correlation Matrix")
    plt.colorbar(im, ax=ax, shrink=0.8)

    plt.tight_layout()
    plt.savefig(out_path, dpi=150)
    plt.close()


def plot_averaging_comparison(results_dict, out_path, title=""):
    """Plot inter-conversion averaging curves for multiple strategies."""
    fig, ax = plt.subplots(figsize=(10, 6))

    colors = ["#2196F3", "#FF9800", "#4CAF50", "#E91E63", "#9C27B0"]
    for i, (label, res) in enumerate(results_dict.items()):
        ns = [r["N"] for r in res]
        rmses = [r["rmse"] for r in res]
        color = colors[i % len(colors)]
        ax.plot(ns, rmses, "o-", color=color, label=label, markersize=4)

    ax.axhline(20, color="red", linestyle="--", alpha=0.5, label="20 ps target")
    ax.axhline(10, color="orange", linestyle=":", alpha=0.5, label="10 ps")
    ax.axhline(5, color="green", linestyle=":", alpha=0.5, label="5 ps")
    ax.set_xscale("log")
    ax.set_yscale("log")
    ax.set_xlabel("Number of conversions averaged (N)")
    ax.set_ylabel("RMSE (ps)")
    ax.set_title(title or "Inter-Conversion Averaging: Strategy Comparison")
    ax.legend(fontsize=8)
    ax.grid(True, alpha=0.3)
    ax.yaxis.set_major_formatter(ticker.ScalarFormatter())
    ax.yaxis.set_minor_formatter(ticker.NullFormatter())

    plt.tight_layout()
    plt.savefig(out_path, dpi=150)
    plt.close()


def plot_nslow_weighting(conv_df, out_path):
    """Plot the nslow-dependent noise profile and weighting function."""
    fig, axes = plt.subplots(1, 3, figsize=(16, 5))

    # 1. Actual RMSE by nslow
    ax = axes[0]
    nslow_rmse = conv_df.groupby("nslow")["mvue_error_ps"].apply(
        lambda x: np.sqrt((x**2).mean()))
    ax.plot(nslow_rmse.index, nslow_rmse.values, "o-", color="steelblue",
            markersize=3, label="Actual RMSE")
    ns_range = np.arange(1, 30)
    predicted = JITTER_SLOPE * np.sqrt(ns_range) + JITTER_INTERCEPT
    ax.plot(ns_range, predicted, "--", color="red", alpha=0.7,
            label=f"Model: {JITTER_SLOPE:.1f}√n + {JITTER_INTERCEPT:.1f}")
    ax.set_xlabel("nslow")
    ax.set_ylabel("RMSE (ps)")
    ax.set_title("Per-Conversion RMSE vs nslow")
    ax.legend()

    # 2. Weight function
    ax = axes[1]
    sigma_sq = (JITTER_SLOPE * np.sqrt(ns_range) + JITTER_INTERCEPT) ** 2
    w = 1.0 / sigma_sq
    w_norm = w / w.sum() * len(w)  # normalize so mean = 1
    ax.bar(ns_range, w_norm, color="coral", edgecolor="darkred", alpha=0.8)
    ax.set_xlabel("nslow")
    ax.set_ylabel("Relative weight (mean=1)")
    ax.set_title("Nslow-Dependent Weight: 1/σ²(nslow)")

    # 3. Population by nslow
    ax = axes[2]
    nslow_counts = conv_df["nslow"].value_counts().sort_index()
    ax.bar(nslow_counts.index, nslow_counts.values, color="lightgreen",
           edgecolor="darkgreen")
    ax.set_xlabel("nslow")
    ax.set_ylabel("Number of conversions")
    ax.set_title("Conversion Distribution by nslow")

    plt.tight_layout()
    plt.savefig(out_path, dpi=150)
    plt.close()


def plot_quality_gating(conv_df, out_path):
    """Plot the quality gating analysis."""
    fig, axes = plt.subplots(1, 2, figsize=(12, 5))

    ax = axes[0]
    ax.scatter(conv_df["intra_std"], conv_df["mvue_error_ps"].abs(),
               alpha=0.1, s=2, color="steelblue")
    ax.set_xlabel("Intra-conversion hit std (ps)")
    ax.set_ylabel("|MVUE error| (ps)")
    ax.set_title("Quality Gating: Intra-Conv Std vs |Error|")

    ax = axes[1]
    pcts = list(range(50, 101, 5))
    rmses = []
    for p in pcts:
        thresh = conv_df["intra_std"].quantile(p / 100.0)
        sub = conv_df[conv_df["intra_std"] <= thresh]
        rmse = np.sqrt((sub["mvue_error_ps"]**2).mean())
        rmses.append(rmse)
    ax.plot(pcts, rmses, "o-", color="coral")
    ax.set_xlabel("Percentile of conversions kept")
    ax.set_ylabel("MVUE RMSE (ps)")
    ax.set_title("RMSE vs Quality Gate Threshold")

    plt.tight_layout()
    plt.savefig(out_path, dpi=150)
    plt.close()


def plot_combined_table(results_dict, out_path):
    """Plot a comparison table of all strategies."""
    fig, ax = plt.subplots(figsize=(12, 6))
    ax.axis("off")

    headers = ["N conversions"]
    for label in results_dict:
        headers.append(label)

    # Collect all N values
    all_ns = set()
    for res in results_dict.values():
        for r in res:
            all_ns.add(r["N"])
    all_ns = sorted(all_ns)

    rows = []
    cell_colors = []
    for n in all_ns:
        row = [str(n)]
        colors_row = ["#f0f0f0"]
        for label, res in results_dict.items():
            match = [r for r in res if r["N"] == n]
            if match:
                rmse = match[0]["rmse"]
                cell = f"{rmse:.2f} ps"
                if rmse < 5:
                    colors_row.append("#c8e6c9")
                elif rmse < 10:
                    colors_row.append("#dcedc8")
                elif rmse < 20:
                    colors_row.append("#fff9c4")
                else:
                    colors_row.append("#ffcdd2")
            else:
                cell = "—"
                colors_row.append("white")
            row.append(cell)
        rows.append(row)
        cell_colors.append(colors_row)

    table = ax.table(cellText=rows, colLabels=headers,
                     cellColours=cell_colors, loc="center",
                     cellLoc="center")
    table.auto_set_font_size(False)
    table.set_fontsize(9)
    table.scale(1.0, 1.4)

    ax.set_title("RMSE by Strategy and Number of Conversions Averaged",
                 fontsize=13, fontweight="bold", pad=20)
    plt.tight_layout()
    plt.savefig(out_path, dpi=150, bbox_inches="tight")
    plt.close()


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    t0 = time.time()

    parser = argparse.ArgumentParser(
        description="MPTDC MVUE Calibrator — optimal multi-hit averaging")
    parser.add_argument("--train-dir", required=True,
                        help="Training seed directory")
    parser.add_argument("--val-dir", required=True,
                        help="Validation (held-out) seed directory")
    parser.add_argument("--fresh-dir", default=None,
                        help="Fresh (never-seen) seed directory")
    parser.add_argument("--out-dir", required=True,
                        help="Output directory for results")
    parser.add_argument("--max-train", type=int, default=None,
                        help="Limit training seeds")
    parser.add_argument("--max-hits", type=int, default=15,
                        help="Max hit_idx to use (default 15)")
    parser.add_argument("--quality-pct", type=float, default=90,
                        help="Quality gate percentile (default 90)")
    args = parser.parse_args()

    os.makedirs(args.out_dir, exist_ok=True)
    plot_dir = os.path.join(args.out_dir, "plots")
    os.makedirs(plot_dir, exist_ok=True)

    print("=" * 70)
    print("  MPTDC MVUE Calibrator")
    print("=" * 70)

    # ── Step 1: Load training data ────────────────────────────────────────
    print(f"\n[1/7] Loading training data...")
    train_files = load_csvs(args.train_dir, args.max_train)
    print(f"  Training files: {len(train_files)}")
    train_df = load_and_tag(train_files)
    print(f"  Total rows: {len(train_df):,}")
    print(f"  Conversions: {train_df.conv_id.nunique():,}")

    # ── Step 2: Build LUT ─────────────────────────────────────────────────
    print(f"\n[2/7] Building 6D LUT from training data...")
    lut = build_lut(train_df)
    n_bins = len(lut)
    print(f"  LUT bins: {n_bins:,}")

    # Apply LUT to get calibrated errors for covariance estimation
    train_cal = apply_lut(train_df, lut)

    # ── Step 3: Compute MVUE weights ──────────────────────────────────────
    print(f"\n[3/7] Computing MVUE weights from covariance matrix...")
    piv = train_cal.pivot_table(index="conv_id", columns="hit_idx",
                                values="error_ps")
    # Keep only conversions with all max_hits present
    hit_cols = [c for c in piv.columns if c < args.max_hits]
    piv_clean = piv[hit_cols].dropna()
    print(f"  Complete conversions (all {len(hit_cols)} hits): {len(piv_clean):,}")

    weights, rmse_mvue_th, rmse_simple_th, cov_mat = compute_mvue_weights(
        piv_clean.values)

    print(f"\n  MVUE weights:")
    for i, w in enumerate(weights):
        marker = " ◀ max" if w == max(weights) else ""
        print(f"    hit_{i:2d}: {w:+.5f}{marker}")
    print(f"\n  Theoretical simple-mean RMSE: {rmse_simple_th:.2f} ps")
    print(f"  Theoretical MVUE RMSE:        {rmse_mvue_th:.2f} ps")
    print(f"  Improvement: {(1 - rmse_mvue_th/rmse_simple_th)*100:.1f}%")

    # Correlation analysis
    std_diag = np.sqrt(np.diag(cov_mat))
    corr_mat = cov_mat / np.outer(std_diag, std_diag)
    upper = corr_mat[np.triu_indices_from(corr_mat, k=1)]
    print(f"\n  Mean inter-hit correlation: ρ = {upper.mean():.4f}")
    print(f"  Min/Max correlation: {upper.min():.4f} / {upper.max():.4f}")

    # Noise decomposition
    rho = upper.mean()
    sigma_single = rmse_simple_th * np.sqrt(len(hit_cols))
    sigma_corr = sigma_single * np.sqrt(rho)
    sigma_indep = sigma_single * np.sqrt(1 - rho)
    print(f"\n  Noise decomposition:")
    print(f"    σ_single-shot  = {sigma_single:.2f} ps")
    print(f"    σ_correlated   = {sigma_corr:.2f} ps (slow-osc jitter, common-mode)")
    print(f"    σ_independent  = {sigma_indep:.2f} ps (fast-side + quantization)")

    # Save weights
    weight_path = os.path.join(args.out_dir, "mvue_weights.json")
    weight_data = {
        "weights": weights.tolist(),
        "max_hits": args.max_hits,
        "rmse_mvue_theoretical": float(rmse_mvue_th),
        "rmse_simple_theoretical": float(rmse_simple_th),
        "mean_correlation": float(rho),
        "sigma_correlated_ps": float(sigma_corr),
        "sigma_independent_ps": float(sigma_indep),
        "jitter_model": {
            "slope": JITTER_SLOPE,
            "intercept": JITTER_INTERCEPT,
            "formula": "sigma(nslow) = slope * sqrt(nslow) + intercept"
        }
    }
    with open(weight_path, "w") as f:
        json.dump(weight_data, f, indent=2)
    print(f"  Saved: {weight_path}")

    # Plot weights and correlation
    plot_mvue_weights(weights, cov_mat,
                      os.path.join(plot_dir, "mvue_weights_and_corr.png"))
    print(f"  Saved: plots/mvue_weights_and_corr.png")

    # Free training pivot
    del piv, piv_clean, train_cal
    gc.collect()

    # ── Step 4: Validate on held-out data ─────────────────────────────────
    print(f"\n[4/7] Validating on held-out data...")
    val_files = load_csvs(args.val_dir)
    print(f"  Validation files: {len(val_files)}")
    val_df = load_and_tag(val_files)
    print(f"  Validation rows: {len(val_df):,}")

    # Apply MVUE per-conversion
    conv_val = apply_mvue_intra_conv(val_df, lut, weights, args.max_hits)
    print(f"  Conversions: {len(conv_val):,}")

    # Per-conversion metrics
    print(f"\n  Single-shot (per-hit) metrics:")
    val_cal = apply_lut(val_df, lut)
    m_single = compute_metrics(val_cal["error_ps"].dropna(), "single-shot")
    print_metrics(m_single)

    print(f"\n  Simple 15-hit mean (per-conversion):")
    m_simple = compute_metrics(conv_val["simple_error_ps"].dropna().values,
                               "simple-mean")
    print_metrics(m_simple)

    print(f"\n  MVUE 15-hit (per-conversion):")
    m_mvue = compute_metrics(conv_val["mvue_error_ps"].dropna().values, "MVUE")
    print_metrics(m_mvue)

    # Nslow-stratified
    print(f"\n  MVUE RMSE by nslow band:")
    for lo, hi in [(1,5), (5,10), (10,15), (15,20), (20,25), (25,30)]:
        sub = conv_val[(conv_val.nslow >= lo) & (conv_val.nslow < hi)]
        if len(sub) == 0:
            continue
        rmse = np.sqrt((sub.mvue_error_ps**2).mean())
        print(f"    nslow {lo:2d}-{hi:2d}: RMSE={rmse:.2f} ps ({len(sub)} conv)")

    # Plot nslow weighting
    plot_nslow_weighting(conv_val,
                         os.path.join(plot_dir, "nslow_weighting.png"))
    print(f"  Saved: plots/nslow_weighting.png")

    # Plot quality gating
    plot_quality_gating(conv_val,
                        os.path.join(plot_dir, "quality_gating.png"))
    print(f"  Saved: plots/quality_gating.png")

    # ── Step 5: Inter-conversion averaging study ──────────────────────────
    print(f"\n[5/7] Inter-conversion averaging study...")
    n_values = [1, 2, 3, 4, 5, 8, 10, 15, 20, 30, 50, 75, 100, 150, 200,
                300, 500, 750, 1000]

    strategies = {}

    # Strategy 1: Simple single-hit (baseline)
    print(f"  Strategy: single-hit (no intra-conv averaging)...")
    strategies["Single-hit"] = inter_conv_averaging(
        conv_val, n_values, method="simple", use_nslow_weight=False)

    # Strategy 2: Simple 15-hit mean
    print(f"  Strategy: 15-hit simple mean...")
    strategies["15-hit simple"] = inter_conv_averaging(
        conv_val, n_values, method="simple", use_nslow_weight=False)

    # Strategy 3: MVUE 15-hit
    print(f"  Strategy: 15-hit MVUE...")
    strategies["15-hit MVUE"] = inter_conv_averaging(
        conv_val, n_values, method="mvue", use_nslow_weight=False)

    # Strategy 4: MVUE + nslow weighting
    print(f"  Strategy: MVUE + nslow weighting...")
    strategies["MVUE + nslow-wt"] = inter_conv_averaging(
        conv_val, n_values, method="mvue", use_nslow_weight=True)

    # Strategy 5: MVUE + nslow weight + quality gate
    print(f"  Strategy: MVUE + nslow-wt + quality gate (P{args.quality_pct:.0f})...")
    strategies["MVUE + nslow-wt + QG"] = inter_conv_averaging(
        conv_val, n_values, method="mvue", use_nslow_weight=True,
        use_quality_gate=True, quality_pct=args.quality_pct)

    # Print comparison table
    print(f"\n  {'N':>5s}", end="")
    for label in strategies:
        print(f"  {label:>20s}", end="")
    print()
    print("  " + "─" * (5 + 22 * len(strategies)))

    for i, n in enumerate(n_values):
        print(f"  {n:5d}", end="")
        for label, res in strategies.items():
            if i < len(res):
                rmse = res[i]["rmse"]
                marker = " ✓" if rmse < 20 else ""
                print(f"  {rmse:17.2f} ps{marker}", end="")
            else:
                print(f"  {'—':>20s}", end="")
        print()

    # Find N for sub-20 and sub-5 for each strategy
    print(f"\n  Milestones:")
    for label, res in strategies.items():
        n20 = next((r["N"] for r in res if r["rmse"] < 20), ">1000")
        n10 = next((r["N"] for r in res if r["rmse"] < 10), ">1000")
        n5 = next((r["N"] for r in res if r["rmse"] < 5), ">1000")
        print(f"    {label:30s}: sub-20 @ N={n20}, sub-10 @ N={n10}, sub-5 @ N={n5}")

    # Plot
    plot_averaging_comparison(strategies,
                              os.path.join(plot_dir, "averaging_comparison.png"),
                              "Held-out: Inter-Conversion Averaging Strategies")
    print(f"  Saved: plots/averaging_comparison.png")

    plot_combined_table(strategies,
                        os.path.join(plot_dir, "averaging_table.png"))
    print(f"  Saved: plots/averaging_table.png")

    # ── Step 6: Fresh validation ──────────────────────────────────────────
    if args.fresh_dir:
        print(f"\n[6/7] Validating on FRESH data...")
        fresh_files = load_csvs(args.fresh_dir)
        print(f"  Fresh files: {len(fresh_files)}")
        fresh_df = load_and_tag(fresh_files)
        print(f"  Fresh rows: {len(fresh_df):,}")

        conv_fresh = apply_mvue_intra_conv(fresh_df, lut, weights, args.max_hits)
        print(f"  Fresh conversions: {len(conv_fresh):,}")

        print(f"\n  Fresh single-shot:")
        fresh_cal = apply_lut(fresh_df, lut)
        m_fresh_single = compute_metrics(fresh_cal["error_ps"].dropna(),
                                         "fresh single-shot")
        print_metrics(m_fresh_single)

        print(f"\n  Fresh MVUE 15-hit:")
        m_fresh_mvue = compute_metrics(
            conv_fresh["mvue_error_ps"].dropna().values, "fresh MVUE")
        print_metrics(m_fresh_mvue)

        # Fresh averaging
        print(f"\n  Fresh inter-conversion averaging (MVUE + nslow-wt):")
        fresh_avg = inter_conv_averaging(
            conv_fresh, n_values, method="mvue", use_nslow_weight=True)
        for r in fresh_avg:
            marker = " ✓" if r["rmse"] < 20 else ""
            print(f"    N={r['N']:5d}: RMSE={r['rmse']:.2f} ps{marker}")

        del fresh_df, fresh_cal, conv_fresh
        gc.collect()
    else:
        print(f"\n[6/7] Skipped (no --fresh-dir)")

    # ── Step 7: Save report ───────────────────────────────────────────────
    print(f"\n[7/7] Writing report...")

    report = {
        "training_seeds": len(train_files),
        "validation_seeds": len(val_files),
        "lut_bins": n_bins,
        "max_hits": args.max_hits,
        "mvue_weights": weights.tolist(),
        "mean_correlation_rho": float(rho),
        "noise_decomposition": {
            "sigma_single_shot_ps": float(sigma_single),
            "sigma_correlated_ps": float(sigma_corr),
            "sigma_independent_ps": float(sigma_indep),
        },
        "jitter_model": {
            "formula": "sigma = slope * sqrt(nslow) + intercept",
            "slope_ps": JITTER_SLOPE,
            "intercept_ps": JITTER_INTERCEPT,
        },
        "held_out_metrics": {
            "single_shot": m_single,
            "simple_15hit": m_simple,
            "mvue_15hit": m_mvue,
        },
        "strategies": {
            label: res for label, res in strategies.items()
        },
    }
    report_path = os.path.join(args.out_dir, "mvue_report.json")
    with open(report_path, "w") as f:
        json.dump(report, f, indent=2, default=str)
    print(f"  Saved: {report_path}")

    # Text report
    txt_path = os.path.join(args.out_dir, "mvue_report.txt")
    with open(txt_path, "w") as f:
        f.write("MPTDC MVUE Calibration Report\n")
        f.write("=" * 60 + "\n\n")
        f.write(f"Training seeds: {len(train_files)}\n")
        f.write(f"LUT bins: {n_bins:,}\n")
        f.write(f"Max hits: {args.max_hits}\n\n")

        f.write("Noise Decomposition\n")
        f.write("-" * 40 + "\n")
        f.write(f"  σ_single-shot  = {sigma_single:.2f} ps\n")
        f.write(f"  σ_correlated   = {sigma_corr:.2f} ps\n")
        f.write(f"  σ_independent  = {sigma_indep:.2f} ps\n")
        f.write(f"  Mean inter-hit ρ = {rho:.4f}\n\n")

        f.write("MVUE Weights\n")
        f.write("-" * 40 + "\n")
        for i, w in enumerate(weights):
            f.write(f"  hit_{i:2d}: {w:+.5f}\n")
        f.write(f"\n")

        f.write("Performance (Held-Out)\n")
        f.write("-" * 40 + "\n")
        f.write(f"  Single-shot RMSE:   {m_single['rmse']:.2f} ps\n")
        f.write(f"  Simple 15-hit RMSE: {m_simple['rmse']:.2f} ps\n")
        f.write(f"  MVUE 15-hit RMSE:   {m_mvue['rmse']:.2f} ps\n\n")

        f.write("Inter-Conversion Averaging (MVUE + nslow-wt)\n")
        f.write("-" * 40 + "\n")
        best = strategies.get("MVUE + nslow-wt", [])
        for r in best:
            marker = " ✓ SUB-20" if r["rmse"] < 20 else ""
            f.write(f"  N={r['N']:5d}: RMSE={r['rmse']:.2f} ps{marker}\n")

    print(f"  Saved: {txt_path}")

    elapsed = time.time() - t0
    print(f"\n{'=' * 70}")
    print(f"  MVUE CALIBRATION COMPLETE ({elapsed:.1f}s)")
    print(f"{'=' * 70}")
    print(f"  Single-shot:  {m_single['rmse']:.2f} ps")
    print(f"  15-hit mean:  {m_simple['rmse']:.2f} ps")
    print(f"  15-hit MVUE:  {m_mvue['rmse']:.2f} ps")
    for label, res in strategies.items():
        n20 = next((r["N"] for r in res if r["rmse"] < 20), None)
        if n20:
            print(f"  Sub-20 ps:    N≥{n20} ({label})")
            break
    print(f"{'=' * 70}")
    print(f"\nOutputs in: {args.out_dir}/")


if __name__ == "__main__":
    main()
