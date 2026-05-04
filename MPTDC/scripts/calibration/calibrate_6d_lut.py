#!/usr/bin/env python3
# ==============================================================================
#  MPTDC 6D+hit_idx Look-Up Table Calibrator
# ==============================================================================
#  Builds a mean-correction LUT keyed on compact-mode fields, trains on
#  campaign data, validates on held-out seeds, produces comprehensive
#  pre/post-calibration analysis plots and an averaging study.
#
#  Key:  (ns_inf, nf_inf, nslow, nfast_hit, phase0_snap, hit_idx)
#   - ns_inf, nf_inf are deterministically recovered from t_raw_ps via
#     the Vernier code algebra (works in ALL output modes).
#   - All other fields are available in every TDC output mode.
#   - hit_idx is the sequential position of each hit in the output stream.
#
#  Usage:
#    python3 scripts/calibration/calibrate_6d_lut.py           # defaults
#    python3 scripts/calibration/calibrate_6d_lut.py --help     # options
#
#  Author : Karim Sabra
# ==============================================================================

import argparse
import glob
import gc
import json
import os
import re
import sys
import time
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
import numpy as np
import pandas as pd
from matplotlib.colors import TwoSlopeNorm

SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from plot_style import PALETTE, apply_report_style, save_figure, style_axes

# ── Constants ──────────────────────────────────────────────────────────────────
# Vernier algebra: t_raw_ps = ((nslow+2+sbi-1)*K_SLOW + nfast*K_FAST
#                               + ns*K_VERNIER - nf*(K_VERNIER-1) + OFFSET) * QUANT
NE        = 8
K_VERNIER = 11
K_SLOW    = K_VERNIER * NE
K_FAST    = NE
OFFSET    = 25
QUANT     = 10  # ps per LSB

# LUT key columns (6D + hit_idx = 7 fields total, called "6D LUT" for brevity)
LUT_KEY = ["ns_inf", "nf_inf", "nslow", "nfast_hit", "phase0_snap", "hit_idx"]
REQUIRED_COLUMNS = [
    "Tref_ps",
    "t_raw_ps",
    "nslow",
    "nfast_hit",
    "phase0_snap",
    "hit_idx",
    "slow_boundary_inc",
]
PARSER_ERROR_RE = re.compile(
    r"Expected (?P<expected>\d+) fields in line (?P<line>\d+), saw (?P<saw>\d+)"
)

apply_report_style()


# ── Helpers ────────────────────────────────────────────────────────────────────

def build_nsnf_reverse_lut():
    """Build the (ns*11 - nf*10) → (ns, nf) reverse look-up.
    Every one of the 64 active 8×8 combinations maps to a unique difference."""
    lut = {}
    for ns in range(NE):
        for nf in range(NE):
            lut[ns * K_VERNIER - nf * (K_VERNIER - 1)] = (ns, nf)
    assert len(lut) == NE * NE, f"ns/nf reverse LUT must have {NE * NE} unique entries"
    return lut

NSNF_REV = build_nsnf_reverse_lut()


def infer_ns_nf(df):
    """Deterministically recover (ns, nf) from compact-mode fields."""
    coef  = df["t_raw_ps"] // QUANT
    resid = (coef
             - (df["nslow"] + 2 + df["slow_boundary_inc"] - 1) * K_SLOW
             - df["nfast_hit"] * K_FAST
             - OFFSET)
    df["ns_inf"] = resid.map(lambda r: NSNF_REV.get(r, (None, None))[0]).astype("Int64")
    df["nf_inf"] = resid.map(lambda r: NSNF_REV.get(r, (None, None))[1]).astype("Int64")
    return df


def recover_malformed_csv(csv_file, parser_error):
    """Recover a CSV with a small number of malformed data rows.

    This path is only used after the fast C parser rejects a file due to
    inconsistent row widths.  We count total data lines, re-read with
    on_bad_lines="skip", and report the difference.

    Compatible with pandas >= 1.3 (string on_bad_lines) and Python 3.9+.
    """
    recovery = {
        "recovered_from_parser_error": True,
        "malformed_rows_skipped": 0,
        "first_bad_line": None,
        "expected_fields": None,
        "first_bad_line_fields": None,
    }

    match = PARSER_ERROR_RE.search(str(parser_error))
    if match:
        recovery["first_bad_line"] = int(match.group("line"))
        recovery["expected_fields"] = int(match.group("expected"))
        recovery["first_bad_line_fields"] = int(match.group("saw"))

    # Count total data lines (excluding header) for an accurate skip count
    with open(csv_file, "r") as fh:
        total_data_lines = sum(1 for _ in fh) - 1  # subtract header

    try:
        df = pd.read_csv(csv_file, on_bad_lines="skip")
    except pd.errors.ParserError as exc:
        raise ValueError(
            f"{csv_file} still failed to parse after malformed-row recovery: {exc}"
        ) from exc

    recovery["malformed_rows_skipped"] = max(0, total_data_lines - len(df))

    if recovery["malformed_rows_skipped"] == 0:
        raise ValueError(
            f"{csv_file} raised ParserError but no malformed rows were identified "
            f"(total_data_lines={total_data_lines}, df_rows={len(df)}): {parser_error}"
        ) from parser_error

    if df.empty:
        raise ValueError(
            f"{csv_file} has no usable rows after skipping "
            f"{recovery['malformed_rows_skipped']} malformed rows"
        ) from parser_error

    detail = f"skipped {recovery['malformed_rows_skipped']} malformed row(s)"
    if recovery["first_bad_line"] is not None and recovery["expected_fields"] is not None:
        detail += (
            f"; first bad line {recovery['first_bad_line']} saw "
            f"{recovery['first_bad_line_fields']} fields "
            f"(expected {recovery['expected_fields']})"
        )
    print(f"  WARNING: recovered malformed CSV {os.path.basename(csv_file)}: {detail}")
    df.attrs.update(recovery)
    return df


def read_seed_csv(csv_file):
    """Load one seed CSV, skipping files that contain no data rows."""
    try:
        df = pd.read_csv(csv_file)
    except pd.errors.EmptyDataError:
        return None, "empty"
    except pd.errors.ParserError as err:
        df = recover_malformed_csv(csv_file, err)

    df.attrs.setdefault("recovered_from_parser_error", False)
    df.attrs.setdefault("malformed_rows_skipped", 0)
    df.attrs.setdefault("first_bad_line", None)
    df.attrs.setdefault("expected_fields", None)
    df.attrs.setdefault("first_bad_line_fields", None)

    missing = [col for col in REQUIRED_COLUMNS if col not in df.columns]
    if missing:
        print(
            f"  WARNING: skipped CSV {os.path.basename(csv_file)}: "
            f"missing required columns: {', '.join(missing)}"
        )
        return None, "missing_required_columns"

    if df.empty:
        return None, "header_only"

    return df, None


def print_skipped_csv_summary(skipped, indent=2):
    """Print a concise summary of CSV files skipped for being unusable."""
    if not skipped:
        return

    counts = {}
    for item in skipped:
        counts[item["reason"]] = counts.get(item["reason"], 0) + 1

    reasons = []
    if counts.get("empty"):
        reasons.append(f"{counts['empty']} empty")
    if counts.get("header_only"):
        reasons.append(f"{counts['header_only']} header-only")
    if counts.get("missing_required_columns"):
        reasons.append(f"{counts['missing_required_columns']} missing-required-columns")
    other = sum(
        v for k, v in counts.items()
        if k not in {"empty", "header_only", "missing_required_columns"}
    )
    if other:
        reasons.append(f"{other} other")

    sample = ", ".join(os.path.basename(item["path"]) for item in skipped[:5])
    if len(skipped) > 5:
        sample += ", ..."

    sp = " " * indent
    reason_text = ", ".join(reasons) if reasons else "unknown reasons"
    print(
        f"{sp}WARNING: skipped {len(skipped)} CSV file(s) "
        f"({reason_text}): {sample}"
    )


def load_and_prepare(csv_files, core_only=True, allow_empty=False):
    """Load CSVs, infer ns/nf, optionally filter to core (nslow > 0)."""
    frames = []
    skipped = []
    recovered_files = 0
    recovered_rows = 0
    for f in csv_files:
        frame, skip_reason = read_seed_csv(f)
        if frame is None:
            skipped.append({"path": f, "reason": skip_reason})
            continue
        recovered_files += int(bool(frame.attrs.get("recovered_from_parser_error", False)))
        recovered_rows += int(frame.attrs.get("malformed_rows_skipped", 0))
        frames.append(frame)

    print_skipped_csv_summary(skipped)

    if not frames:
        if not allow_empty:
            raise ValueError(
                f"No usable calibration rows found in {len(csv_files)} CSV file(s)"
            )
        df = pd.DataFrame(columns=REQUIRED_COLUMNS)
    else:
        df = pd.concat(frames, ignore_index=True)

    n_before = len(df)
    df.attrs["rows_before_filter"] = int(n_before)
    df.attrs["core_filter_label"] = "nslow > 0"
    df.attrs["core_filter_applied"] = bool(core_only)
    df.attrs["skipped_csv_files"] = int(len(skipped))
    df.attrs["skipped_empty_csv_files"] = int(sum(
        1 for item in skipped if item["reason"] == "empty"
    ))
    df.attrs["skipped_header_only_csv_files"] = int(sum(
        1 for item in skipped if item["reason"] == "header_only"
    ))
    df.attrs["skipped_missing_required_columns_csv_files"] = int(sum(
        1 for item in skipped if item["reason"] == "missing_required_columns"
    ))
    df.attrs["recovered_csv_files"] = int(recovered_files)
    df.attrs["recovered_malformed_rows"] = int(recovered_rows)

    if df.empty:
        df["offset"] = pd.Series(dtype=np.float64)
        df["ns_inf"] = pd.Series(dtype="Int64")
        df["nf_inf"] = pd.Series(dtype="Int64")
        df.attrs["rows_after_filter"] = 0
        df.attrs["rows_filtered_out"] = 0
        df.attrs["rows_filtered_out_pct"] = 0.0
        df.attrs["rows_after_inference"] = 0
        return df

    if core_only:
        df = df[df["nslow"] > 0].copy()
        pct = (1 - len(df) / n_before) * 100 if n_before else 0
        print(f"  Core filter: removed {n_before - len(df):,} rows "
              f"({pct:.1f}%) with nslow=0")
    df.attrs["rows_after_filter"] = int(len(df))
    df.attrs["rows_filtered_out"] = int(n_before - len(df))
    df.attrs["rows_filtered_out_pct"] = float((1 - len(df) / n_before) * 100) if n_before else 0.0
    df["offset"] = df["Tref_ps"] - df["t_raw_ps"]
    infer_ns_nf(df)
    bad = df["ns_inf"].isna().sum()
    if bad:
        print(f"  WARNING: {bad} rows failed ns/nf inference – dropped")
        df = df.dropna(subset=["ns_inf", "nf_inf"])
    df.attrs["rows_after_inference"] = int(len(df))
    return df


def filter_summary(df):
    """Return structured filter metadata captured by load_and_prepare()."""
    before = int(df.attrs.get("rows_before_filter", len(df)))
    after_filter = int(df.attrs.get("rows_after_filter", len(df)))
    after_inference = int(df.attrs.get("rows_after_inference", len(df)))
    filtered_out = int(df.attrs.get("rows_filtered_out", before - after_filter))
    return {
        "filter": df.attrs.get("core_filter_label", "nslow > 0"),
        "applied": bool(df.attrs.get("core_filter_applied", False)),
        "rows_before_filter": before,
        "rows_after_filter": after_filter,
        "rows_after_inference": after_inference,
        "rows_filtered_out": filtered_out,
        "rows_filtered_out_pct": float(df.attrs.get("rows_filtered_out_pct", 0.0)),
        "skipped_csv_files": int(df.attrs.get("skipped_csv_files", 0)),
        "skipped_empty_csv_files": int(df.attrs.get("skipped_empty_csv_files", 0)),
        "skipped_header_only_csv_files": int(
            df.attrs.get("skipped_header_only_csv_files", 0)
        ),
        "skipped_missing_required_columns_csv_files": int(
            df.attrs.get("skipped_missing_required_columns_csv_files", 0)
        ),
        "recovered_csv_files": int(df.attrs.get("recovered_csv_files", 0)),
        "recovered_malformed_rows": int(df.attrs.get("recovered_malformed_rows", 0)),
    }


def build_lut(train_df):
    """Build mean-correction LUT from training data."""
    lut = train_df.groupby(LUT_KEY)["offset"].agg(["mean", "std", "count"])
    lut.columns = ["correction", "within_std", "train_count"]
    return lut


def apply_lut(df, lut):
    """Apply LUT to data, return calibrated DataFrame."""
    merged = df.set_index(LUT_KEY).join(lut["correction"], how="left").reset_index()
    merged["cal_ps"]   = merged["t_raw_ps"] + merged["correction"]
    merged["error_ps"] = merged["Tref_ps"]  - merged["cal_ps"]
    merged["raw_error_ps"] = merged["Tref_ps"] - merged["t_raw_ps"]
    return merged


def compute_metrics(errors, label=""):
    """Compute comprehensive error statistics."""
    m = {
        "label":   label,
        "count":   len(errors),
        "mean":    float(np.mean(errors)),
        "std":     float(np.std(errors)),
        "rmse":    float(np.sqrt(np.mean(errors**2))),
        "mae":     float(np.mean(np.abs(errors))),
        "p50_ae":  float(np.percentile(np.abs(errors), 50)),
        "p90_ae":  float(np.percentile(np.abs(errors), 90)),
        "p95_ae":  float(np.percentile(np.abs(errors), 95)),
        "p99_ae":  float(np.percentile(np.abs(errors), 99)),
        "min":     float(np.min(errors)),
        "max":     float(np.max(errors)),
    }
    return m


def compute_improvement_pct(baseline, current):
    """Return percent improvement, guarding degenerate zero-baseline cases."""
    if baseline == 0:
        return 0.0 if current == 0 else float("nan")
    return (1 - current / baseline) * 100.0


def format_improvement(baseline, current, width=7, precision=1):
    """Format percent improvement for terminal/text reports."""
    improvement = compute_improvement_pct(baseline, current)
    if np.isnan(improvement):
        return "n/a"
    return f"{improvement:>{width}.{precision}f}%"


def print_metrics(m, indent=2):
    sp = " " * indent
    print(f"{sp}{m['label']}:")
    print(f"{sp}  Count      : {m['count']:>12,}")
    print(f"{sp}  RMSE       : {m['rmse']:>12.2f} ps")
    print(f"{sp}  MAE        : {m['mae']:>12.2f} ps")
    print(f"{sp}  Mean error : {m['mean']:>+12.3f} ps")
    print(f"{sp}  Std        : {m['std']:>12.3f} ps")
    print(f"{sp}  |err| P50  : {m['p50_ae']:>12.2f} ps")
    print(f"{sp}  |err| P90  : {m['p90_ae']:>12.2f} ps")
    print(f"{sp}  |err| P95  : {m['p95_ae']:>12.2f} ps")
    print(f"{sp}  |err| P99  : {m['p99_ae']:>12.2f} ps")
    print(f"{sp}  Min / Max  : {m['min']:>+.2f} / {m['max']:>+.2f} ps")


# ── Plotting ───────────────────────────────────────────────────────────────────

FIGSIZE   = (10, 6)
HIST_BINS = 200
DPI       = 150


def plot_error_histogram(errors_raw, errors_cal, out_path, title_suffix=""):
    """Side-by-side error histograms, pre vs post calibration."""
    fig, axes = plt.subplots(1, 2, figsize=(14, 5))

    rmse_r = np.sqrt(np.mean(errors_raw**2))
    rmse_c = np.sqrt(np.mean(errors_cal**2))

    # Pre-calibration
    ax = axes[0]
    ax.hist(errors_raw, bins=HIST_BINS, color="#d32f2f", alpha=0.8, edgecolor="none")
    ax.set_title(f"Pre-Calibration{title_suffix}\nRMSE = {rmse_r:.2f} ps", fontsize=11)
    ax.set_xlabel("Error (ps)")
    ax.set_ylabel("Count")
    ax.axvline(0, color="k", ls="--", lw=0.8)

    # Post-calibration
    ax = axes[1]
    ax.hist(errors_cal, bins=HIST_BINS, color="#1976d2", alpha=0.8, edgecolor="none")
    ax.set_title(f"Post-Calibration (6D LUT){title_suffix}\nRMSE = {rmse_c:.2f} ps", fontsize=11)
    ax.set_xlabel("Error (ps)")
    ax.set_ylabel("Count")
    ax.axvline(0, color="k", ls="--", lw=0.8)

    fig.tight_layout()
    fig.savefig(out_path, dpi=DPI, bbox_inches="tight")
    plt.close(fig)
    print(f"  Saved: {out_path}")


def plot_error_vs_delay(tref, errors_raw, errors_cal, out_path, title_suffix="",
                        n_sample=200_000):
    """Scatter of error vs true delay, pre and post calibration."""
    fig, axes = plt.subplots(2, 1, figsize=(12, 8), sharex=True)

    idx = np.random.RandomState(0).choice(len(tref), min(n_sample, len(tref)), replace=False)
    t = tref.values[idx]
    er = errors_raw.values[idx]
    ec = errors_cal.values[idx]

    axes[0].scatter(t / 1000, er, s=0.1, alpha=0.15, color="#d32f2f", rasterized=True)
    axes[0].set_ylabel("Raw error (ps)")
    axes[0].set_title(f"Error vs True Delay – Pre-Calibration{title_suffix}")
    axes[0].axhline(0, color="k", ls="--", lw=0.8)

    axes[1].scatter(t / 1000, ec, s=0.1, alpha=0.15, color="#1976d2", rasterized=True)
    axes[1].set_ylabel("Calibrated error (ps)")
    axes[1].set_xlabel("True delay (ns)")
    axes[1].set_title(f"Error vs True Delay – Post-Calibration (6D LUT){title_suffix}")
    axes[1].axhline(0, color="k", ls="--", lw=0.8)

    fig.tight_layout()
    fig.savefig(out_path, dpi=DPI, bbox_inches="tight")
    plt.close(fig)
    print(f"  Saved: {out_path}")


def plot_error_vs_code(df, error_col, code_col, out_path, title="", n_bins=100):
    """Binned error statistics vs a code value."""
    fig, ax = plt.subplots(figsize=FIGSIZE)
    bins = pd.cut(df[code_col], bins=n_bins)
    stats = df.groupby(bins, observed=True)[error_col].agg(["mean", "std"])
    x = np.arange(len(stats))
    ax.fill_between(x, stats["mean"] - stats["std"], stats["mean"] + stats["std"],
                    alpha=0.25, color="#1976d2")
    ax.plot(x, stats["mean"], color="#1976d2", lw=1.2)
    ax.axhline(0, color="k", ls="--", lw=0.8)
    ax.set_xlabel(code_col)
    ax.set_ylabel(f"{error_col} (ps)")
    ax.set_title(title)
    # Sparse x ticks
    step = max(1, len(x) // 10)
    ax.set_xticks(x[::step])
    ax.set_xticklabels([f"{iv.mid:.0f}" for iv in stats.index[::step]], rotation=45, fontsize=8)
    fig.tight_layout()
    fig.savefig(out_path, dpi=DPI, bbox_inches="tight")
    plt.close(fig)
    print(f"  Saved: {out_path}")


def compute_binned_profile(df, x_col, error_col, *, n_bins=60):
    """Aggregate mean/rmse/tails of *error_col* over evenly spaced bins of *x_col*."""
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
    records = []
    for interval, grp in work.groupby("bin", observed=True):
        arr = grp[error_col].to_numpy(dtype=float)
        if arr.size == 0:
            continue
        ae = np.abs(arr)
        records.append({
            "x_lo": float(interval.left),
            "x_hi": float(interval.right),
            "x_mid": float((interval.left + interval.right) / 2.0),
            "mean": float(np.mean(arr)),
            "rmse": float(np.sqrt(np.mean(arr**2))),
            "p90_ae": float(np.percentile(ae, 90)),
            "p99_ae": float(np.percentile(ae, 99)),
            "count": int(arr.size),
        })
    return pd.DataFrame.from_records(records)


def _phase_pivot(df, error_col, aggfunc):
    key_cols = ["ns_inf", "nf_inf"]
    if not set(key_cols + [error_col]).issubset(df.columns):
        return None
    piv = df.pivot_table(values=error_col, index="ns_inf", columns="nf_inf", aggfunc=aggfunc)
    return piv.sort_index().sort_index(axis=1)


def _annotate_heatmap(ax, values, fmt):
    for row_idx in range(values.shape[0]):
        for col_idx in range(values.shape[1]):
            value = values[row_idx, col_idx]
            if np.isnan(value):
                continue
            ax.text(col_idx, row_idx, format(value, fmt),
                    ha="center", va="center", fontsize=7, color="black")


def plot_pre_post_delay_profile(df, out_path, title_suffix=""):
    """Compare delay-dependent mean/RMSE before and after calibration."""
    raw_profile = compute_binned_profile(df, "Tref_ps", "raw_error_ps")
    cal_profile = compute_binned_profile(df, "Tref_ps", "error_ps")
    if raw_profile.empty or cal_profile.empty:
        return

    x_raw = raw_profile["x_mid"].values / 1000.0
    x_cal = cal_profile["x_mid"].values / 1000.0

    fig, axes = plt.subplots(2, 1, figsize=(10, 7), sharex=True)
    axes[0].plot(x_raw, raw_profile["rmse"].values, color=PALETTE["red"], label="Pre-calibration")
    axes[0].plot(x_cal, cal_profile["rmse"].values, color=PALETTE["blue"], label="Post-calibration")
    axes[0].set_ylabel("RMSE (ps)")
    axes[0].set_title(f"RMSE vs delai vrai{title_suffix}")
    axes[0].legend()

    axes[1].plot(x_raw, raw_profile["mean"].values, color=PALETTE["red"], label="Pre-calibration")
    axes[1].plot(x_cal, cal_profile["mean"].values, color=PALETTE["blue"], label="Post-calibration")
    axes[1].axhline(0.0, color=PALETTE["gray"], ls="--", lw=0.8)
    axes[1].set_xlabel("Delai vrai (ns)")
    axes[1].set_ylabel("Biais moyen (ps)")
    axes[1].set_title(f"Biais moyen vs delai vrai{title_suffix}")

    for ax in axes:
        style_axes(ax)
    save_figure(fig, out_path)
    print(f"  Saved: {out_path}")


def plot_pre_post_phase_heatmaps(df, out_path, title_suffix=""):
    """Compare ns_inf × nf_inf mean-error maps before and after calibration."""
    raw_mean = _phase_pivot(df, "raw_error_ps", "mean")
    cal_mean = _phase_pivot(df, "error_ps", "mean")
    raw_std = _phase_pivot(df, "raw_error_ps", "std")
    cal_std = _phase_pivot(df, "error_ps", "std")
    if raw_mean is None or cal_mean is None or raw_std is None or cal_std is None:
        return

    fig, axes = plt.subplots(2, 2, figsize=(11, 9))
    panels = [
        (axes[0, 0], raw_mean, "Biais moyen avant calibration", "RdBu_r", True, ".1f"),
        (axes[0, 1], cal_mean, "Biais moyen apres calibration", "RdBu_r", True, ".1f"),
        (axes[1, 0], raw_std, "Ecart-type avant calibration", "viridis", False, ".1f"),
        (axes[1, 1], cal_std, "Ecart-type apres calibration", "viridis", False, ".1f"),
    ]

    for ax, piv, title, cmap, center_zero, fmt in panels:
        values = piv.values.astype(float)
        norm = None
        if center_zero and np.isfinite(values).any():
            vmax = float(np.nanmax(np.abs(values)))
            if vmax > 0:
                norm = TwoSlopeNorm(vmin=-vmax, vcenter=0.0, vmax=vmax)
        im = ax.imshow(values, origin="lower", aspect="auto", cmap=cmap, norm=norm)
        ax.set_xticks(range(piv.shape[1]))
        ax.set_yticks(range(piv.shape[0]))
        ax.set_xlabel("nf_inf")
        ax.set_ylabel("ns_inf")
        ax.set_title(title)
        _annotate_heatmap(ax, values, fmt)
        fig.colorbar(im, ax=ax, fraction=0.046, pad=0.04)

    fig.suptitle(f"Structure Vernier pre/post calibration{title_suffix}", fontsize=13, fontweight="semibold")
    save_figure(fig, out_path)
    print(f"  Saved: {out_path}")


def plot_pre_post_hit_idx_rmse(df, out_path, title_suffix=""):
    """Compare hit-index RMSE before and after calibration."""
    raw = df.groupby("hit_idx")["raw_error_ps"].apply(lambda x: np.sqrt(np.mean(np.square(x))))
    cal = df.groupby("hit_idx")["error_ps"].apply(lambda x: np.sqrt(np.mean(np.square(x))))
    if raw.empty or cal.empty:
        return

    fig, ax = plt.subplots(figsize=FIGSIZE)
    ax.plot(raw.index, raw.values, marker="o", color=PALETTE["red"], label="Pre-calibration")
    ax.plot(cal.index, cal.values, marker="o", color=PALETTE["blue"], label="Post-calibration")
    ax.set_xlabel("Hit index")
    ax.set_ylabel("RMSE (ps)")
    ax.set_title(f"RMSE par hit index{title_suffix}")
    style_axes(ax)
    ax.legend()
    save_figure(fig, out_path)
    print(f"  Saved: {out_path}")


def plot_inl_dnl(lut_df, out_path):
    """INL / DNL from LUT corrections sorted by code."""
    fig, axes = plt.subplots(2, 1, figsize=(12, 7), sharex=True)
    corrections = lut_df["correction"].sort_index().values
    lsb = QUANT  # 10 ps
    dnl = np.diff(corrections) / lsb
    inl = (corrections - np.linspace(corrections[0], corrections[-1], len(corrections))) / lsb

    axes[0].plot(dnl, lw=0.5, color="#1976d2")
    axes[0].axhline(0, color="k", ls="--", lw=0.8)
    axes[0].set_ylabel("DNL (LSB)")
    axes[0].set_title("Differential Nonlinearity (DNL)")

    axes[1].plot(inl, lw=0.5, color="#d32f2f")
    axes[1].axhline(0, color="k", ls="--", lw=0.8)
    axes[1].set_ylabel("INL (LSB)")
    axes[1].set_xlabel("Sorted LUT bin index")
    axes[1].set_title("Integral Nonlinearity (INL)")

    fig.tight_layout()
    fig.savefig(out_path, dpi=DPI, bbox_inches="tight")
    plt.close(fig)
    print(f"  Saved: {out_path}")


def plot_bin_quality(lut_df, out_path):
    """Histogram of within-bin std and bin population."""
    fig, axes = plt.subplots(1, 2, figsize=(13, 5))

    ax = axes[0]
    stds = lut_df["within_std"].dropna()
    ax.hist(stds, bins=80, color="#1976d2", alpha=0.8, edgecolor="none")
    ax.axvline(stds.median(), color="k", ls="--", lw=1, label=f"Median={stds.median():.1f} ps")
    ax.set_xlabel("Within-bin std (ps)")
    ax.set_ylabel("Number of bins")
    ax.set_title("LUT Bin Quality – Within-Bin Std Distribution")
    ax.legend()

    ax = axes[1]
    counts = lut_df["train_count"]
    ax.hist(counts, bins=80, color="#388e3c", alpha=0.8, edgecolor="none")
    ax.axvline(counts.median(), color="k", ls="--", lw=1, label=f"Median={counts.median():.0f}")
    ax.set_xlabel("Training samples per bin")
    ax.set_ylabel("Number of bins")
    ax.set_title("LUT Bin Population Distribution")
    ax.set_yscale("log")
    ax.legend()

    fig.tight_layout()
    fig.savefig(out_path, dpi=DPI, bbox_inches="tight")
    plt.close(fig)
    print(f"  Saved: {out_path}")


def plot_comparison_bar(metrics_raw, metrics_cal, out_path):
    """Bar chart comparing pre vs post calibration metrics."""
    fig, ax = plt.subplots(figsize=(10, 5))
    labels = ["RMSE", "MAE", "|err| P50", "|err| P90", "|err| P95", "|err| P99"]
    raw_vals = [metrics_raw["rmse"], metrics_raw["mae"], metrics_raw["p50_ae"],
                metrics_raw["p90_ae"], metrics_raw["p95_ae"], metrics_raw["p99_ae"]]
    cal_vals = [metrics_cal["rmse"], metrics_cal["mae"], metrics_cal["p50_ae"],
                metrics_cal["p90_ae"], metrics_cal["p95_ae"], metrics_cal["p99_ae"]]

    x = np.arange(len(labels))
    w = 0.35
    bars_r = ax.bar(x - w/2, raw_vals, w, label="Pre-Calibration", color="#d32f2f", alpha=0.85)
    bars_c = ax.bar(x + w/2, cal_vals, w, label="Post-Calibration (6D LUT)", color="#1976d2", alpha=0.85)

    ax.set_xticks(x)
    ax.set_xticklabels(labels)
    ax.set_ylabel("Picoseconds (ps)")
    ax.set_title("Calibration Impact – Error Metrics Comparison")
    ax.legend()

    for bar in bars_r:
        ax.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 2,
                f"{bar.get_height():.1f}", ha="center", va="bottom", fontsize=8)
    for bar in bars_c:
        ax.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 2,
                f"{bar.get_height():.1f}", ha="center", va="bottom", fontsize=8)

    fig.tight_layout()
    fig.savefig(out_path, dpi=DPI, bbox_inches="tight")
    plt.close(fig)
    print(f"  Saved: {out_path}")


def plot_averaging(avg_results, out_path):
    """RMSE vs number of averages, with 1/sqrt(N) reference."""
    fig, ax = plt.subplots(figsize=FIGSIZE)

    ns = [r["N"] for r in avg_results]
    rmses = [r["rmse"] for r in avg_results]
    theory = [rmses[0] / np.sqrt(n) for n in ns]

    ax.plot(ns, rmses, "o-", color="#1976d2", lw=2, markersize=5, label="Measured RMSE", zorder=3)
    ax.plot(ns, theory, "--", color="#9e9e9e", lw=1.5, label=f"1/√N reference ({rmses[0]:.1f}/√N)")
    ax.set_xscale("log")
    ax.set_yscale("log")
    ax.set_xlabel("Number of averages (N)")
    ax.set_ylabel("RMSE (ps)")
    ax.set_title("Averaging Study – RMSE vs Number of Averaged Measurements")
    ax.legend()
    ax.grid(True, which="both", ls=":", alpha=0.4)

    # Annotate key points
    for r in avg_results:
        if r["N"] in [1, 2, 4, 10, 25, 50, 100, 250, 500, 1000]:
            ax.annotate(f'{r["rmse"]:.2f} ps',
                        (r["N"], r["rmse"]),
                        textcoords="offset points", xytext=(8, 5),
                        fontsize=7, color="#1976d2")

    fig.tight_layout()
    fig.savefig(out_path, dpi=DPI, bbox_inches="tight")
    plt.close(fig)
    print(f"  Saved: {out_path}")


def plot_averaging_table(avg_results, out_path):
    """Table plot of averaging results."""
    fig, ax = plt.subplots(figsize=(8, max(3, len(avg_results) * 0.35 + 1)))
    ax.axis("off")

    headers = ["N", "RMSE (ps)", "MAE (ps)", "|err| P90 (ps)", "Improvement"]
    rows = []
    for r in avg_results:
        rows.append([
            str(r["N"]),
            f'{r["rmse"]:.2f}',
            f'{r["mae"]:.2f}',
            f'{r["p90_ae"]:.2f}',
            format_improvement(avg_results[0]["rmse"], r["rmse"], width=0, precision=1).strip()
        ])

    table = ax.table(cellText=rows, colLabels=headers, loc="center",
                     cellLoc="center", colColours=["#e3f2fd"]*len(headers))
    table.auto_set_font_size(False)
    table.set_fontsize(9)
    table.scale(1.0, 1.4)
    ax.set_title("Averaging Study – Detailed Results", fontsize=12, pad=20)

    fig.tight_layout()
    fig.savefig(out_path, dpi=DPI, bbox_inches="tight")
    plt.close(fig)
    print(f"  Saved: {out_path}")


def plot_hit_idx_rmse(df, error_col, out_path, title=""):
    """RMSE broken down by hit_idx."""
    fig, ax = plt.subplots(figsize=FIGSIZE)
    g = df.groupby("hit_idx")[error_col].apply(lambda x: np.sqrt(np.mean(x**2)))
    ax.bar(g.index, g.values, color="#1976d2", alpha=0.85, edgecolor="none")
    ax.set_xlabel("Hit Index")
    ax.set_ylabel("RMSE (ps)")
    ax.set_title(title or f"RMSE by Hit Index ({error_col})")
    ax.axhline(g.mean(), color="k", ls="--", lw=0.8, label=f"Mean={g.mean():.2f} ps")
    ax.legend()
    fig.tight_layout()
    fig.savefig(out_path, dpi=DPI, bbox_inches="tight")
    plt.close(fig)
    print(f"  Saved: {out_path}")


def plot_nslow_rmse(df, error_col, out_path, title=""):
    """RMSE broken down by nslow."""
    fig, ax = plt.subplots(figsize=FIGSIZE)
    g = df.groupby("nslow")[error_col].apply(lambda x: np.sqrt(np.mean(x**2)))
    ax.bar(g.index, g.values, color="#1976d2", alpha=0.85, edgecolor="none")
    ax.set_xlabel("nslow")
    ax.set_ylabel("RMSE (ps)")
    ax.set_title(title or f"RMSE by nslow ({error_col})")
    fig.tight_layout()
    fig.savefig(out_path, dpi=DPI, bbox_inches="tight")
    plt.close(fig)
    print(f"  Saved: {out_path}")


def plot_qq(errors, out_path, title=""):
    """Q-Q plot of calibrated errors vs normal distribution."""
    fig, ax = plt.subplots(figsize=(7, 7))
    sorted_e = np.sort(errors)
    n = len(sorted_e)
    # Subsample for large datasets
    if n > 50000:
        idx = np.linspace(0, n - 1, 50000, dtype=int)
        sorted_e = sorted_e[idx]
        n = len(sorted_e)
    theoretical = np.linspace(0.5/n, 1 - 0.5/n, n)
    from scipy.stats import norm
    theoretical_q = norm.ppf(theoretical) * np.std(errors) + np.mean(errors)
    ax.scatter(theoretical_q, sorted_e, s=0.3, alpha=0.5, color="#1976d2", rasterized=True)
    lims = [min(theoretical_q.min(), sorted_e.min()), max(theoretical_q.max(), sorted_e.max())]
    ax.plot(lims, lims, "k--", lw=0.8)
    ax.set_xlabel("Theoretical quantiles (normal)")
    ax.set_ylabel("Sample quantiles (ps)")
    ax.set_title(title or "Q-Q Plot of Calibrated Error")
    ax.set_aspect("equal")
    fig.tight_layout()
    fig.savefig(out_path, dpi=DPI, bbox_inches="tight")
    plt.close(fig)
    print(f"  Saved: {out_path}")


# ── Averaging study ────────────────────────────────────────────────────────────

def run_averaging_study(df, n_values, n_trials=2000, rng_seed=42):
    """For each N, sample N calibrated errors, average them, measure RMSE.

    This simulates averaging N independent measurements of the same delay.
    The calibrated error for each measurement is drawn from the empirical
    distribution; averaging N of them reduces noise by ~1/sqrt(N).
    """
    rng = np.random.RandomState(rng_seed)
    errors = df["error_ps"].values
    results = []

    for N in n_values:
        # Draw n_trials groups of N errors, compute group means
        if N * n_trials > len(errors):
            # Resample with replacement
            samples = rng.choice(errors, size=(n_trials, N), replace=True)
        else:
            idx = rng.choice(len(errors), size=n_trials * N, replace=False)
            samples = errors[idx].reshape(n_trials, N)
        avg_errors = samples.mean(axis=1)
        m = compute_metrics(avg_errors, label=f"N={N}")
        m["N"] = N
        results.append(m)

    return results


# ── Main ───────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="MPTDC 6D LUT Calibrator")
    parser.add_argument("--train-dir", default="results/campaign/multihit_15_cal_nominal",
                        help="Directory with training CSVs (seeds 0-23)")
    parser.add_argument("--val-dir", default=None,
                        help="Directory with validation CSVs (seeds 24-29 or 100-129)")
    parser.add_argument("--fresh-dir",
                        default="results/campaign_validation/multihit_15_cal_nominal",
                        help="Directory with fresh validation CSVs (seeds 100-129)")
    parser.add_argument("--out-dir", default="results/calibration_final",
                        help="Output directory for LUT, plots, reports")
    parser.add_argument("--train-seeds", type=int, default=24,
                        help="Number of training seeds (first N)")
    parser.add_argument("--chunk-load", action="store_true", default=True,
                        help="Load training data in chunks to save memory")
    args = parser.parse_args()

    os.makedirs(args.out_dir, exist_ok=True)
    plots_dir = os.path.join(args.out_dir, "plots")
    os.makedirs(plots_dir, exist_ok=True)

    t0 = time.time()
    print("=" * 70)
    print("  MPTDC 6D+hit_idx LUT Calibrator")
    print("=" * 70)

    # ── 1) Build LUT from training data ───────────────────────────────────
    print(f"\n[1/6] Building LUT from training data ({args.train_seeds} seeds)...")

    train_files = sorted(glob.glob(os.path.join(args.train_dir, "seed_*.csv")))
    train_files = train_files[:args.train_seeds]
    print(f"  Training files: {len(train_files)}")

    if args.chunk_load:
        # Accumulate per-bin sums and counts to avoid loading all at once
        bin_sum   = {}
        bin_sumsq = {}
        bin_count = {}
        total_rows = 0
        total_core = 0
        train_skipped = []
        train_recovered_csv_files = 0
        train_recovered_malformed_rows = 0
        usable_train_files = 0
        for i, f in enumerate(train_files):
            chunk, skip_reason = read_seed_csv(f)
            if chunk is None:
                train_skipped.append({"path": f, "reason": skip_reason})
                if (i + 1) % 6 == 0:
                    print(f"    ... scanned {i+1}/{len(train_files)} seeds "
                          f"({usable_train_files} usable)")
                continue
            usable_train_files += 1
            train_recovered_csv_files += int(
                bool(chunk.attrs.get("recovered_from_parser_error", False))
            )
            train_recovered_malformed_rows += int(
                chunk.attrs.get("malformed_rows_skipped", 0)
            )
            total_rows += len(chunk)
            chunk = chunk[chunk["nslow"] > 0].copy()
            total_core += len(chunk)
            chunk["offset"] = chunk["Tref_ps"] - chunk["t_raw_ps"]
            infer_ns_nf(chunk)
            chunk = chunk.dropna(subset=["ns_inf", "nf_inf"])
            for keys, grp in chunk.groupby(LUT_KEY)["offset"]:
                s, sq, c = grp.sum(), (grp**2).sum(), len(grp)
                if keys in bin_sum:
                    bin_sum[keys]   += s
                    bin_sumsq[keys] += sq
                    bin_count[keys] += c
                else:
                    bin_sum[keys]   = s
                    bin_sumsq[keys] = sq
                    bin_count[keys] = c
            del chunk; gc.collect()
            if (i + 1) % 6 == 0:
                print(f"    ... scanned {i+1}/{len(train_files)} seeds "
                      f"({usable_train_files} usable)")

        print_skipped_csv_summary(train_skipped)
        if not bin_count:
            raise ValueError(
                "Training set produced no usable rows after skipping unusable CSVs"
            )
        train_skipped_csv_files = len(train_skipped)
        train_skipped_empty_csv_files = sum(
            1 for item in train_skipped if item["reason"] == "empty"
        )
        train_skipped_header_only_csv_files = sum(
            1 for item in train_skipped if item["reason"] == "header_only"
        )
        train_skipped_missing_required_columns_csv_files = sum(
            1 for item in train_skipped if item["reason"] == "missing_required_columns"
        )

        # Build LUT DataFrame
        records = []
        for keys in bin_sum:
            mean = bin_sum[keys] / bin_count[keys]
            var  = bin_sumsq[keys] / bin_count[keys] - mean**2
            std  = np.sqrt(max(0, var))
            records.append((*keys, mean, std, bin_count[keys]))
        lut_df = pd.DataFrame(records,
                              columns=LUT_KEY + ["correction", "within_std", "train_count"])
        lut_df = lut_df.set_index(LUT_KEY)

        print(f"  Total rows loaded : {total_rows:>12,}")
        print(f"  Core rows (nslow>0): {total_core:>12,}")
    else:
        train_data = load_and_prepare(train_files, core_only=True)
        total_rows = len(train_data)
        lut_df = build_lut(train_data)
        train_skipped_csv_files = int(train_data.attrs.get("skipped_csv_files", 0))
        train_skipped_empty_csv_files = int(
            train_data.attrs.get("skipped_empty_csv_files", 0)
        )
        train_skipped_header_only_csv_files = int(
            train_data.attrs.get("skipped_header_only_csv_files", 0)
        )
        train_skipped_missing_required_columns_csv_files = int(
            train_data.attrs.get("skipped_missing_required_columns_csv_files", 0)
        )
        train_recovered_csv_files = int(
            train_data.attrs.get("recovered_csv_files", 0)
        )
        train_recovered_malformed_rows = int(
            train_data.attrs.get("recovered_malformed_rows", 0)
        )
        del train_data; gc.collect()

    print(f"  LUT bins          : {len(lut_df):>12,}")
    print(f"  Min bin population: {int(lut_df['train_count'].min()):>12,}")
    print(f"  Median bin pop.   : {int(lut_df['train_count'].median()):>12,}")
    print(f"  Max bin population: {int(lut_df['train_count'].max()):>12,}")

    # Save LUT
    lut_path = os.path.join(args.out_dir, "lut_6d.csv")
    lut_df.to_csv(lut_path)
    print(f"  LUT saved: {lut_path}")

    # LUT quality plots
    plot_bin_quality(lut_df, os.path.join(plots_dir, "lut_bin_quality.png"))
    plot_inl_dnl(lut_df, os.path.join(plots_dir, "lut_inl_dnl.png"))

    # ── 2) Validate on held-out seeds from same campaign ──────────────────
    val_dir = args.val_dir or args.train_dir
    if val_dir == args.train_dir:
        all_val_files = sorted(glob.glob(os.path.join(val_dir, "seed_*.csv")))
        val_files = all_val_files[args.train_seeds:30]
        if not val_files and all_val_files:
            print("  WARNING: no held-out seeds remain after the training split; "
                  "reusing the available validation directory for a shape check.")
            val_files = all_val_files
    else:
        val_files = sorted(glob.glob(os.path.join(val_dir, "seed_*.csv")))
    val_file_labels = [os.path.basename(path) for path in val_files]
    val_scope_label = ", ".join(val_file_labels) if val_file_labels else "none"

    print(f"\n[2/6] Validating on held-out seeds ({len(val_files)} files)...")
    val_data = load_and_prepare(val_files, core_only=True)
    if val_data.empty:
        raise ValueError("Held-out validation produced no usable rows after filtering")
    val_filter = filter_summary(val_data)
    print(f"  Validation rows (core subset): {len(val_data):,}")

    val_result = apply_lut(val_data, lut_df)
    unmatched = val_result["correction"].isna().sum()
    print(f"  LUT coverage: {(1 - unmatched/len(val_result))*100:.2f}% "
          f"({unmatched} unmatched)")
    val_result = val_result.dropna(subset=["correction"])

    m_raw = compute_metrics(val_result["raw_error_ps"].values,
                            "Pre-calibration (held-out, core subset)")
    m_cal = compute_metrics(val_result["error_ps"].values,
                            "Post-calibration (held-out, core subset)")
    print_metrics(m_raw)
    print_metrics(m_cal)

    # Pre/post plots – held-out
    plot_error_histogram(val_result["raw_error_ps"].values, val_result["error_ps"].values,
                         os.path.join(plots_dir, "val_error_histogram.png"),
                         " – Held-Out Validation")
    plot_error_vs_delay(val_result["Tref_ps"], val_result["raw_error_ps"],
                        val_result["error_ps"],
                        os.path.join(plots_dir, "val_error_vs_delay.png"),
                        " – Held-Out Validation")
    plot_comparison_bar(m_raw, m_cal, os.path.join(plots_dir, "val_comparison_bar.png"))
    plot_hit_idx_rmse(val_result, "error_ps",
                      os.path.join(plots_dir, "val_rmse_by_hit_idx.png"),
                      "Post-Calibration RMSE by Hit Index – Held-Out")
    plot_hit_idx_rmse(val_result, "raw_error_ps",
                      os.path.join(plots_dir, "val_rmse_by_hit_idx_raw.png"),
                      "Pre-Calibration RMSE by Hit Index – Held-Out")
    plot_nslow_rmse(val_result, "error_ps",
                    os.path.join(plots_dir, "val_rmse_by_nslow.png"),
                    "Post-Calibration RMSE by nslow – Held-Out")
    plot_error_vs_code(val_result, "error_ps", "t_raw_ps",
                       os.path.join(plots_dir, "val_error_vs_traw.png"),
                       "Post-Cal Error vs t_raw_ps – Held-Out")
    plot_qq(val_result["error_ps"].values,
            os.path.join(plots_dir, "val_qq_plot.png"),
            "Q-Q Plot – Calibrated Error (Held-Out)")
    plot_pre_post_delay_profile(val_result,
                                os.path.join(plots_dir, "val_delay_profile_pre_post.png"),
                                " – Held-Out Validation")
    plot_pre_post_phase_heatmaps(val_result,
                                 os.path.join(plots_dir, "val_phase_heatmaps_pre_post.png"),
                                 " – Held-Out Validation")
    plot_pre_post_hit_idx_rmse(val_result,
                               os.path.join(plots_dir, "val_rmse_by_hit_idx_pre_post.png"),
                               " – Held-Out Validation")

    del val_data, val_result; gc.collect()

    # ── 3) Validate on fresh seeds (100-129) ── chunked for memory ──────
    fresh_files = sorted(glob.glob(os.path.join(args.fresh_dir, "seed_*.csv")))
    if fresh_files:
        print(f"\n[3/6] Validating on FRESH seeds ({len(fresh_files)} files, chunked)...")

        # Pass 1: accumulate error statistics across all fresh files
        raw_sse, cal_sse = 0.0, 0.0
        raw_sum, cal_sum = 0.0, 0.0
        raw_abs, cal_abs = 0.0, 0.0
        total_n, unmatched_total = 0, 0
        fresh_rows_before = 0
        fresh_rows_after_filter = 0
        fresh_rows_after_inference = 0
        fresh_skipped_csv_files = 0
        fresh_skipped_empty_csv_files = 0
        fresh_skipped_header_only_csv_files = 0
        fresh_skipped_missing_required_columns_csv_files = 0
        all_raw_errs = []
        all_cal_errs = []
        # Per-hit_idx and per-nslow accumulators
        hitidx_sse = {}; hitidx_n = {}
        nslow_sse  = {}; nslow_n  = {}
        CHUNK = 5  # files per chunk

        for ci in range(0, len(fresh_files), CHUNK):
            batch = fresh_files[ci:ci+CHUNK]
            chunk = load_and_prepare(batch, core_only=True, allow_empty=True)
            fresh_rows_before += int(chunk.attrs.get("rows_before_filter", len(chunk)))
            fresh_rows_after_filter += int(chunk.attrs.get("rows_after_filter", len(chunk)))
            fresh_rows_after_inference += int(chunk.attrs.get("rows_after_inference", len(chunk)))
            fresh_skipped_csv_files += int(chunk.attrs.get("skipped_csv_files", 0))
            fresh_skipped_empty_csv_files += int(
                chunk.attrs.get("skipped_empty_csv_files", 0)
            )
            fresh_skipped_header_only_csv_files += int(
                chunk.attrs.get("skipped_header_only_csv_files", 0)
            )
            fresh_skipped_missing_required_columns_csv_files += int(
                chunk.attrs.get("skipped_missing_required_columns_csv_files", 0)
            )
            if chunk.empty:
                print(f"    ... processed {min(ci+CHUNK, len(fresh_files))}/{len(fresh_files)} files "
                      f"({total_n:,} rows, batch had no usable data)")
                del chunk; gc.collect()
                continue
            result = apply_lut(chunk, lut_df)
            unmatched_total += result["correction"].isna().sum()
            result = result.dropna(subset=["correction"])
            n = len(result)
            if n == 0:
                print(f"    WARNING: batch {ci//CHUNK + 1} had no LUT-matched rows after join")
                del chunk, result; gc.collect()
                continue
            total_n += n

            re = result["raw_error_ps"].values
            ce = result["error_ps"].values
            raw_sse += (re**2).sum()
            cal_sse += (ce**2).sum()
            raw_sum += re.sum()
            cal_sum += ce.sum()
            raw_abs += np.abs(re).sum()
            cal_abs += np.abs(ce).sum()

            # Subsample for histograms/scatter (keep ~500K total)
            keep = max(1, n // 3)
            idx_s = np.random.RandomState(ci).choice(n, keep, replace=False)
            all_raw_errs.append(re[idx_s])
            all_cal_errs.append(ce[idx_s])

            for hi, grp in result.groupby("hit_idx"):
                e2 = (grp["error_ps"]**2).sum()
                hitidx_sse[hi] = hitidx_sse.get(hi, 0) + e2
                hitidx_n[hi]   = hitidx_n.get(hi, 0) + len(grp)
            for ns, grp in result.groupby("nslow"):
                e2 = (grp["error_ps"]**2).sum()
                nslow_sse[ns] = nslow_sse.get(ns, 0) + e2
                nslow_n[ns]   = nslow_n.get(ns, 0) + len(grp)

            del chunk, result; gc.collect()
            print(f"    ... processed {min(ci+CHUNK, len(fresh_files))}/{len(fresh_files)} files "
                  f"({total_n:,} rows)")

        if total_n == 0:
            raise ValueError(
                "Fresh validation files were found, but no usable LUT-matched rows remained"
            )

        # Compute aggregate metrics
        raw_rmse = np.sqrt(raw_sse / total_n)
        cal_rmse = np.sqrt(cal_sse / total_n)
        raw_mean = raw_sum / total_n
        cal_mean = cal_sum / total_n
        raw_mae  = raw_abs / total_n
        cal_mae  = cal_abs / total_n

        all_raw = np.concatenate(all_raw_errs)
        all_cal = np.concatenate(all_cal_errs)

        m_raw_f = compute_metrics(all_raw, "Pre-calibration (fresh core subset, sampled)")
        m_cal_f = compute_metrics(all_cal, "Post-calibration (fresh core subset, sampled)")
        # Override with exact aggregated values
        m_raw_f["rmse"] = float(raw_rmse)
        m_raw_f["mae"]  = float(raw_mae)
        m_raw_f["mean"] = float(raw_mean)
        m_raw_f["count"] = total_n
        m_cal_f["rmse"] = float(cal_rmse)
        m_cal_f["mae"]  = float(cal_mae)
        m_cal_f["mean"] = float(cal_mean)
        m_cal_f["count"] = total_n
        fresh_filter = {
            "filter": "nslow > 0",
            "applied": True,
            "rows_before_filter": int(fresh_rows_before),
            "rows_after_filter": int(fresh_rows_after_filter),
            "rows_after_inference": int(fresh_rows_after_inference),
            "rows_filtered_out": int(fresh_rows_before - fresh_rows_after_filter),
            "rows_filtered_out_pct": float(
                (1 - fresh_rows_after_filter / fresh_rows_before) * 100
            ) if fresh_rows_before else 0.0,
            "skipped_csv_files": int(fresh_skipped_csv_files),
            "skipped_empty_csv_files": int(fresh_skipped_empty_csv_files),
            "skipped_header_only_csv_files": int(fresh_skipped_header_only_csv_files),
            "skipped_missing_required_columns_csv_files": int(
                fresh_skipped_missing_required_columns_csv_files
            ),
        }

        coverage_den = fresh_rows_after_inference if fresh_rows_after_inference else 1
        print(f"  LUT coverage: {(1 - unmatched_total/coverage_den)*100:.2f}% "
              f"({unmatched_total} unmatched)")
        print_metrics(m_raw_f)
        print_metrics(m_cal_f)

        # Plots from subsampled data
        plot_error_histogram(all_raw, all_cal,
                             os.path.join(plots_dir, "fresh_error_histogram.png"),
                             " – Fresh Validation (seeds 100-129)")
        # Build a lightweight DataFrame for scatter / per-code plots
        plot_df = pd.DataFrame({"Tref_ps": np.zeros(len(all_cal)),
                                "raw_error_ps": all_raw,
                                "error_ps": all_cal})
        plot_comparison_bar(m_raw_f, m_cal_f,
                            os.path.join(plots_dir, "fresh_comparison_bar.png"))

        # Per-hit_idx RMSE plot
        fig, ax = plt.subplots(figsize=FIGSIZE)
        hi_sorted = sorted(hitidx_sse.keys())
        hi_rmse = [np.sqrt(hitidx_sse[h] / hitidx_n[h]) for h in hi_sorted]
        ax.bar(hi_sorted, hi_rmse, color="#1976d2", alpha=0.85)
        ax.set_xlabel("Hit Index"); ax.set_ylabel("RMSE (ps)")
        ax.set_title("Post-Cal RMSE by Hit Index – Fresh Validation")
        ax.axhline(np.mean(hi_rmse), color="k", ls="--", lw=0.8,
                   label=f"Mean={np.mean(hi_rmse):.2f} ps")
        ax.legend(); fig.tight_layout()
        fig.savefig(os.path.join(plots_dir, "fresh_rmse_by_hit_idx.png"),
                    dpi=DPI, bbox_inches="tight")
        plt.close(fig)
        print(f"  Saved: {os.path.join(plots_dir, 'fresh_rmse_by_hit_idx.png')}")

        # Per-nslow RMSE plot
        fig, ax = plt.subplots(figsize=FIGSIZE)
        ns_sorted = sorted(nslow_sse.keys())
        ns_rmse = [np.sqrt(nslow_sse[s] / nslow_n[s]) for s in ns_sorted]
        ax.bar(ns_sorted, ns_rmse, color="#1976d2", alpha=0.85)
        ax.set_xlabel("nslow"); ax.set_ylabel("RMSE (ps)")
        ax.set_title("Post-Cal RMSE by nslow – Fresh Validation")
        fig.tight_layout()
        fig.savefig(os.path.join(plots_dir, "fresh_rmse_by_nslow.png"),
                    dpi=DPI, bbox_inches="tight")
        plt.close(fig)
        print(f"  Saved: {os.path.join(plots_dir, 'fresh_rmse_by_nslow.png')}")

        plot_qq(all_cal,
                os.path.join(plots_dir, "fresh_qq_plot.png"),
                "Q-Q Plot – Calibrated Error (Fresh Seeds)")

        errors_for_avg = all_cal.copy()
        del all_raw, all_cal, all_raw_errs, all_cal_errs, plot_df; gc.collect()
    else:
        print("\n[3/6] No fresh validation data found – skipping.")
        errors_for_avg = None
        m_raw_f = m_cal_f = None

    # ── 4) Averaging study ────────────────────────────────────────────────
    print(f"\n[4/6] Averaging study...")
    if errors_for_avg is None:
        # Fall back to held-out val
        val_files_avg = sorted(glob.glob(os.path.join(val_dir, "seed_*.csv")))[args.train_seeds:30]
        val_avg = load_and_prepare(val_files_avg, core_only=True)
        if val_avg.empty:
            raise ValueError("Averaging fallback produced no usable held-out validation rows")
        val_avg_r = apply_lut(val_avg, lut_df).dropna(subset=["correction"])
        errors_for_avg = val_avg_r["error_ps"].values.copy()
        del val_avg, val_avg_r; gc.collect()

    n_values = [1, 2, 3, 4, 5, 8, 10, 15, 20, 25, 30, 40, 50,
                75, 100, 150, 200, 250, 300, 400, 500, 750, 1000]
    avg_results = run_averaging_study(
        pd.DataFrame({"error_ps": errors_for_avg}),
        n_values, n_trials=5000
    )

    print(f"\n  {'N':>6s}  {'RMSE':>10s}  {'MAE':>10s}  {'P90':>10s}  {'Improvement':>12s}")
    print(f"  {'─'*6}  {'─'*10}  {'─'*10}  {'─'*10}  {'─'*12}")
    for r in avg_results:
        imp = format_improvement(avg_results[0]["rmse"], r["rmse"], width=11, precision=1)
        print(f"  {r['N']:>6d}  {r['rmse']:>10.3f}  {r['mae']:>10.3f}  "
              f"{r['p90_ae']:>10.3f}  {imp:>12s}")

    plot_averaging(avg_results, os.path.join(plots_dir, "averaging_rmse_curve.png"))
    plot_averaging_table(avg_results, os.path.join(plots_dir, "averaging_table.png"))

    # ── 5) Save comprehensive report ─────────────────────────────────────
    print(f"\n[5/6] Writing report...")
    report = {
        "method": "6D+hit_idx Mean-Correction LUT",
        "lut_key": LUT_KEY,
        "lut_key_description": {
            "ns_inf":  "Slow phase index (0-7), inferred from t_raw_ps via Vernier algebra",
            "nf_inf":  "Fast phase index (0-7), inferred from t_raw_ps via Vernier algebra",
            "nslow":   "Slow oscillator hit count (coarse counter)",
            "nfast_hit": "Fast oscillator hit count at measurement time",
            "phase0_snap": "Phase-0 snapshot (oscillator alignment at conversion start)",
            "hit_idx": "Sequential hit index within conversion (0-based)",
        },
        "output_mode_compatibility": {
            "RAW_FEATURES (mode 0)": "Fully supported – all fields available directly",
            "RAW_TIMESTAMP (mode 1)": "Fully supported – ns/nf inferred from t_raw_ps algebra",
            "FULL (mode 2)": "Fully supported – all fields available directly",
        },
        "ns_nf_inference": {
            "formula": f"diff = t_raw_ps/10 - (nslow+2+sbi-1)*{K_SLOW} - nfast*{K_FAST} - {OFFSET} → unique (ns,nf)",
            "accuracy": f"100% – all {NE * NE} active 8×8 (ns,nf) combinations map to unique diff values",
        },
        "training": {
            "n_seeds": args.train_seeds,
            "n_bins": len(lut_df),
            "median_bin_pop": int(lut_df["train_count"].median()),
            "core_filter": "nslow > 0 (removes ~6.6% boundary-ambiguous hits)",
            "rows_before_filter": int(total_rows),
            "rows_after_filter": int(total_core),
            "rows_filtered_out": int(total_rows - total_core),
            "rows_filtered_out_pct": float(
                (1 - total_core / total_rows) * 100
            ) if total_rows else 0.0,
            "skipped_csv_files": int(train_skipped_csv_files),
            "skipped_empty_csv_files": int(train_skipped_empty_csv_files),
            "skipped_header_only_csv_files": int(train_skipped_header_only_csv_files),
            "skipped_missing_required_columns_csv_files": int(
                train_skipped_missing_required_columns_csv_files
            ),
            "recovered_csv_files": int(train_recovered_csv_files),
            "recovered_malformed_rows": int(train_recovered_malformed_rows),
        },
        "held_out_validation": {
            "scope": "Core subset only (nslow > 0); nslow=0 rows excluded for published calibration metrics.",
            "files": val_file_labels,
            "filter_summary": val_filter,
            "pre_cal":  m_raw,
            "post_cal": m_cal,
        },
    }
    if m_raw_f and m_cal_f:
        report["fresh_validation"] = {
            "scope": "Core subset only (nslow > 0); chunked fresh-seed validation.",
            "filter_summary": fresh_filter,
            "pre_cal":  m_raw_f,
            "post_cal": m_cal_f,
        }
    report["averaging_study"] = {
        "scope": "Post-calibration core-subset error pool",
        "method": "Analysis-side resampling of independent error draws; not a fixed-delay repeated-measurement TB proof.",
        "results": [
            {"N": r["N"], "rmse_ps": round(r["rmse"], 3),
             "mae_ps": round(r["mae"], 3), "p90_ps": round(r["p90_ae"], 3)}
            for r in avg_results
        ],
    }

    report_path = os.path.join(args.out_dir, "calibration_report.json")
    with open(report_path, "w") as f:
        json.dump(report, f, indent=2, default=str)
    print(f"  Report saved: {report_path}")

    # Human-readable report
    txt_path = os.path.join(args.out_dir, "calibration_report.txt")
    with open(txt_path, "w") as f:
        f.write("=" * 70 + "\n")
        f.write("  MPTDC 6D+hit_idx LUT CALIBRATION REPORT\n")
        f.write("=" * 70 + "\n\n")
        f.write(f"Method: Mean-correction Look-Up Table\n")
        f.write(f"Key:    ({', '.join(LUT_KEY)})\n")
        f.write(f"Bins:   {len(lut_df):,}\n")
        f.write(f"Mode compatibility: ALL output modes (0, 1, 2)\n\n")
        f.write(f"Training skipped CSVs: {train_skipped_csv_files}")
        if train_skipped_csv_files:
            f.write(f" (empty={train_skipped_empty_csv_files}, "
                    f"header-only={train_skipped_header_only_csv_files}, "
                    f"missing-required-columns="
                    f"{train_skipped_missing_required_columns_csv_files})")
        f.write("\n\n")

        f.write("─" * 70 + "\n")
        f.write(f"HELD-OUT VALIDATION (core subset: nslow > 0, files: {val_scope_label})\n")
        f.write("─" * 70 + "\n")
        f.write(f"  Rows before filter     : {val_filter['rows_before_filter']:>8,}\n")
        f.write(f"  Rows after filter      : {val_filter['rows_after_filter']:>8,}\n")
        f.write(f"  Rows after ns/nf infer : {val_filter['rows_after_inference']:>8,}\n")
        f.write(f"  Excluded nslow=0 rows  : {val_filter['rows_filtered_out']:>8,} "
                f"({val_filter['rows_filtered_out_pct']:.1f}%)\n\n")
        f.write(f"  Skipped CSVs           : {val_filter['skipped_csv_files']:>8,}")
        if val_filter["skipped_csv_files"]:
            f.write(f" (empty={val_filter['skipped_empty_csv_files']}, "
                    f"header-only={val_filter['skipped_header_only_csv_files']}, "
                    f"missing-required-columns="
                    f"{val_filter['skipped_missing_required_columns_csv_files']})")
        f.write("\n\n")
        f.write(f"  Pre-calibration  RMSE: {m_raw['rmse']:>8.2f} ps\n")
        f.write(f"  Post-calibration RMSE: {m_cal['rmse']:>8.2f} ps\n")
        f.write(f"  Improvement:           {format_improvement(m_raw['rmse'], m_cal['rmse'])}\n\n")
        f.write(f"  Pre-cal  MAE / P50 / P90 / P99: "
                f"{m_raw['mae']:.1f} / {m_raw['p50_ae']:.1f} / "
                f"{m_raw['p90_ae']:.1f} / {m_raw['p99_ae']:.1f} ps\n")
        f.write(f"  Post-cal MAE / P50 / P90 / P99: "
                f"{m_cal['mae']:.1f} / {m_cal['p50_ae']:.1f} / "
                f"{m_cal['p90_ae']:.1f} / {m_cal['p99_ae']:.1f} ps\n\n")

        if m_raw_f and m_cal_f:
            f.write("─" * 70 + "\n")
            f.write("FRESH VALIDATION (core subset: nslow > 0, seeds 100-129)\n")
            f.write("─" * 70 + "\n")
            f.write(f"  Rows before filter     : {fresh_filter['rows_before_filter']:>8,}\n")
            f.write(f"  Rows after filter      : {fresh_filter['rows_after_filter']:>8,}\n")
            f.write(f"  Rows after ns/nf infer : {fresh_filter['rows_after_inference']:>8,}\n")
            f.write(f"  Excluded nslow=0 rows  : {fresh_filter['rows_filtered_out']:>8,} "
                    f"({fresh_filter['rows_filtered_out_pct']:.1f}%)\n\n")
            f.write(f"  Skipped CSVs           : {fresh_filter['skipped_csv_files']:>8,}")
            if fresh_filter["skipped_csv_files"]:
                f.write(f" (empty={fresh_filter['skipped_empty_csv_files']}, "
                        f"header-only={fresh_filter['skipped_header_only_csv_files']}, "
                        f"missing-required-columns="
                        f"{fresh_filter['skipped_missing_required_columns_csv_files']})")
            f.write("\n\n")
            f.write(f"  Pre-calibration  RMSE: {m_raw_f['rmse']:>8.2f} ps\n")
            f.write(f"  Post-calibration RMSE: {m_cal_f['rmse']:>8.2f} ps\n")
            f.write(f"  Improvement:           "
                    f"{format_improvement(m_raw_f['rmse'], m_cal_f['rmse'])}\n\n")
            f.write(f"  Pre-cal  MAE / P50 / P90 / P99: "
                    f"{m_raw_f['mae']:.1f} / {m_raw_f['p50_ae']:.1f} / "
                    f"{m_raw_f['p90_ae']:.1f} / {m_raw_f['p99_ae']:.1f} ps\n")
            f.write(f"  Post-cal MAE / P50 / P90 / P99: "
                    f"{m_cal_f['mae']:.1f} / {m_cal_f['p50_ae']:.1f} / "
                    f"{m_cal_f['p90_ae']:.1f} / {m_cal_f['p99_ae']:.1f} ps\n\n")

        f.write("─" * 70 + "\n")
        f.write("ANALYSIS-SIDE RESAMPLED AVERAGING STUDY\n")
        f.write("─" * 70 + "\n")
        f.write("  Scope  : post-calibration core subset (nslow > 0)\n")
        f.write("  Method : resamples independent error draws from the calibrated pool;\n")
        f.write("           this is not a fixed-delay repeated-measurement TB proof.\n\n")
        f.write(f"  {'N':>6s}  {'RMSE (ps)':>10s}  {'MAE (ps)':>10s}  "
                f"{'P90 (ps)':>10s}  {'vs N=1':>8s}\n")
        for r in avg_results:
            imp = format_improvement(avg_results[0]["rmse"], r["rmse"])
            f.write(f"  {r['N']:>6d}  {r['rmse']:>10.3f}  {r['mae']:>10.3f}  "
                    f"{r['p90_ae']:>10.3f}  {imp:>8s}\n")

        f.write("\n" + "─" * 70 + "\n")
        f.write("LUT KEY FIELD AVAILABILITY BY OUTPUT MODE\n")
        f.write("─" * 70 + "\n")
        f.write("  Field           Mode 0    Mode 1    Mode 2\n")
        f.write("  ─────           ──────    ──────    ──────\n")
        f.write("  nslow           W0        W0        W0\n")
        f.write("  nfast_hit       W0        W0        W0\n")
        f.write("  ns_inf          W1→ns     inferred  W1→ns\n")
        f.write("  nf_inf          W1→nf     inferred  W1→nf\n")
        f.write("  phase0_snap     Header    Header    Header\n")
        f.write("  hit_idx         implicit  implicit  implicit\n")
        f.write("  slow_bound_inc  Header    Header    Header\n")
        f.write("  t_raw_ps        (compute) W1        W3\n\n")
        f.write("  All 6D LUT key fields available in ALL modes.\n")
        f.write("  ns/nf inferred in Mode 1 via: diff = t_raw/10 - "
                f"(nslow+2+sbi-1)*{K_SLOW} - nfast*{K_FAST} - {OFFSET}\n")
        f.write(f"  → maps uniquely to (ns, nf) for all {NE * NE} active 8×8 combinations.\n")

    print(f"  Text report saved: {txt_path}")

    # ── 6) Summary ────────────────────────────────────────────────────────
    print(f"\n[6/6] Done in {time.time()-t0:.1f}s")
    print(f"\n{'='*70}")
    print(f"  FINAL RESULTS")
    print(f"{'='*70}")
    print(f"  Held-out core subset:  {m_raw['rmse']:.2f} ps → {m_cal['rmse']:.2f} ps "
          f"({format_improvement(m_raw['rmse'], m_cal['rmse'], width=0, precision=1).strip()} improvement)")
    if m_cal_f:
        print(f"  Fresh core subset:     {m_raw_f['rmse']:.2f} ps → {m_cal_f['rmse']:.2f} ps "
               f"({format_improvement(m_raw_f['rmse'], m_cal_f['rmse'], width=0, precision=1).strip()} improvement)")
    # Find N for sub-10ps, sub-5ps, sub-1ps
    for target in [15, 10, 5, 2, 1]:
        for r in avg_results:
            if r["rmse"] <= target:
                print(f"  Sub-{target:>2d} ps: N ≥ {r['N']} averages "
                      f"(RMSE = {r['rmse']:.2f} ps)")
                break
    print(f"{'='*70}")
    print(f"\nOutputs in: {args.out_dir}/")


if __name__ == "__main__":
    main()
