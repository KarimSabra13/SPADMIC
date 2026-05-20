#!/usr/bin/env python3
"""Reversible v2 campaign analysis for MPTDC characterization data.

This script intentionally leaves ``analyze_campaign.py`` untouched.  It reuses
the legacy loading/plot helpers, but replaces the DNL/INL extraction path with:

* corrected histogram bin edges, so ideal uniform code data reports 0 DNL/INL;
* stratified DNL/INL by hit_idx and nslow instead of relying on one pooled view;
* an audited Tref column.  Legacy ``tb_campaign_collect.sv`` CSVs record the
  post-START-pulse delay, while the physical reference is START rising edge to
  STOP rising edge, so auto mode adds the 1000 ps START pulse width.
"""

from __future__ import annotations

import argparse
import json
import math
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

import analyze_campaign as legacy  # noqa: E402
from plot_style import PALETTE, save_figure, style_axes  # noqa: E402


DEFAULT_START_PULSE_WIDTH_PS = 1000
TRANSFER_PROFILE_BINS = 120
EPS_ZERO = 1e-12


def _finite_or_nan(value: float) -> float:
    return float(value) if np.isfinite(value) else float("nan")


def _zero_tiny(arr: np.ndarray) -> np.ndarray:
    arr = arr.astype(float, copy=True)
    arr[np.isclose(arr, 0.0, atol=EPS_ZERO, rtol=0.0)] = 0.0
    return arr


def compute_inl_dnl_corrected(
    t_raw: pd.Series,
    bin_width: float = legacy.DELTA_LSB,
) -> tuple[np.ndarray, np.ndarray, np.ndarray, float, float, dict[str, float]]:
    """Compute code-density DNL/INL with inclusive final-bin coverage.

    The legacy analyzer used ``np.arange(lo, hi + bin_width, bin_width)``,
    which omits the final code bin for exact-width discrete code data.  This
    implementation creates one full bin above the maximum observed code, so a
    perfectly uniform sequence over all codes returns exactly 0.0 DNL/INL.
    """
    arr = pd.to_numeric(t_raw, errors="coerce").dropna().to_numpy(dtype=float)
    if arr.size == 0:
        empty_stats = {
            "count": 0,
            "n_bins": 0,
            "ideal_count": float("nan"),
            "code_min_ps": float("nan"),
            "code_max_ps": float("nan"),
            "final_inl": float("nan"),
        }
        return np.array([]), np.array([]), np.array([]), float("nan"), float("nan"), empty_stats

    lo = math.floor(float(np.min(arr)) / bin_width) * bin_width
    hi = math.ceil(float(np.max(arr)) / bin_width) * bin_width
    edges = np.arange(lo, hi + (2 * bin_width), bin_width, dtype=float)
    if edges.size < 2:
        edges = np.array([lo, lo + bin_width], dtype=float)

    counts, edges = np.histogram(arr, bins=edges)
    total = int(counts.sum())
    n_bins = int(len(counts))
    ideal_count = total / n_bins if n_bins else float("nan")

    if n_bins == 0 or not np.isfinite(ideal_count) or ideal_count == 0.0:
        dnl = np.array([], dtype=float)
        inl = np.array([], dtype=float)
    else:
        dnl = _zero_tiny((counts.astype(float) / ideal_count) - 1.0)
        inl = _zero_tiny(np.cumsum(dnl))

    peak_dnl = float(np.max(np.abs(dnl))) if dnl.size else float("nan")
    peak_inl = float(np.max(np.abs(inl))) if inl.size else float("nan")
    stats = {
        "count": total,
        "n_bins": n_bins,
        "ideal_count": _finite_or_nan(ideal_count),
        "code_min_ps": float(lo),
        "code_max_ps": float(hi),
        "final_inl": float(inl[-1]) if inl.size else float("nan"),
    }
    return edges, dnl, inl, peak_dnl, peak_inl, stats


def compute_inl_dnl_summary(df: pd.DataFrame, group_cols: list[str] | None = None) -> pd.DataFrame:
    """Return DNL/INL summaries globally or per requested grouping."""
    if "t_raw_ps" not in df.columns:
        return pd.DataFrame()

    group_cols = group_cols or []
    rows: list[dict[str, object]] = []

    if group_cols:
        missing = [col for col in group_cols if col not in df.columns]
        if missing:
            return pd.DataFrame()
        groups = df.groupby(group_cols, observed=True, dropna=False)
    else:
        groups = [((), df)]

    for keys, grp in groups:
        if not isinstance(keys, tuple):
            keys = (keys,)
        _, _, _, peak_dnl, peak_inl, stats = compute_inl_dnl_corrected(grp["t_raw_ps"])
        row: dict[str, object] = {
            "rows": int(stats["count"]),
            "n_bins": int(stats["n_bins"]),
            "ideal_count": stats["ideal_count"],
            "code_min_ps": stats["code_min_ps"],
            "code_max_ps": stats["code_max_ps"],
            "peak_dnl_lsb": peak_dnl,
            "peak_inl_lsb": peak_inl,
            "final_inl_lsb": stats["final_inl"],
        }
        for col, key in zip(group_cols, keys):
            row[col] = key
        rows.append(row)

    result = pd.DataFrame.from_records(rows)
    if result.empty:
        return result
    sort_cols = [col for col in group_cols if col in result.columns]
    if sort_cols:
        result = result.sort_values(sort_cols, ignore_index=True)
    return result


def compute_transfer_linearity_summary(
    df: pd.DataFrame,
    group_cols: list[str] | None = None,
    *,
    n_bins: int = TRANSFER_PROFILE_BINS,
) -> pd.DataFrame:
    """Estimate transfer-curve DNL/INL from mean t_raw versus audited Tref.

    This is the signoff-relevant linearity view for the randomized campaign:
    bin uniformly in the true input-delay axis, average the reconstructed code
    in each occupied bin, then measure deviation from the endpoint line.
    Occupancy/code-density DNL remains useful as a sparsity diagnostic only.
    """
    if not {"Tref_ps", "t_raw_ps"}.issubset(df.columns):
        return pd.DataFrame()

    group_cols = group_cols or []
    if group_cols:
        missing = [col for col in group_cols if col not in df.columns]
        if missing:
            return pd.DataFrame()
        groups = df.groupby(group_cols, observed=True, dropna=False)
    else:
        groups = [((), df)]

    rows: list[dict[str, object]] = []
    for keys, grp in groups:
        if not isinstance(keys, tuple):
            keys = (keys,)

        work = grp[["Tref_ps", "t_raw_ps"]].apply(pd.to_numeric, errors="coerce").dropna()
        if work["Tref_ps"].nunique() < 4:
            continue

        edges = np.linspace(
            float(work["Tref_ps"].min()),
            float(work["Tref_ps"].max()),
            num=min(n_bins, work["Tref_ps"].nunique()) + 1,
        )
        edges = np.unique(edges)
        if len(edges) < 4:
            continue

        work["tref_bin"] = pd.cut(work["Tref_ps"], bins=edges, include_lowest=True, duplicates="drop")
        prof = (
            work.groupby("tref_bin", observed=True)
            .agg(tref_mean_ps=("Tref_ps", "mean"),
                 raw_mean_ps=("t_raw_ps", "mean"),
                 count=("t_raw_ps", "size"))
            .reset_index(drop=True)
        )
        if len(prof) < 4:
            continue

        tref = prof["tref_mean_ps"].to_numpy(dtype=float)
        raw = prof["raw_mean_ps"].to_numpy(dtype=float)
        tref_span = tref[-1] - tref[0]
        if tref_span == 0:
            continue

        endpoint_slope = (raw[-1] - raw[0]) / tref_span
        endpoint_offset = raw[0] - endpoint_slope * tref[0]
        endpoint_raw = endpoint_slope * tref + endpoint_offset
        endpoint_resid = raw - endpoint_raw
        endpoint_inl = endpoint_resid / legacy.DELTA_LSB

        d_tref = np.diff(tref)
        d_raw = np.diff(raw)
        valid = d_tref != 0
        if np.any(valid) and endpoint_slope != 0:
            transfer_dnl = (d_raw[valid] / d_tref[valid]) / endpoint_slope - 1.0
            peak_transfer_dnl = float(np.max(np.abs(transfer_dnl)))
        else:
            peak_transfer_dnl = float("nan")

        row: dict[str, object] = {
            "rows": int(len(work)),
            "occupied_tref_bins": int(len(prof)),
            "tref_min_ps": float(tref[0]),
            "tref_max_ps": float(tref[-1]),
            "endpoint_slope_ps_per_ps": float(endpoint_slope),
            "endpoint_offset_ps": float(endpoint_offset),
            "mean_transfer_residual_ps": float(np.mean(endpoint_resid)),
            "rmse_transfer_residual_ps": float(np.sqrt(np.mean(endpoint_resid ** 2))),
            "peak_transfer_inl_lsb": float(np.max(np.abs(endpoint_inl))),
            "peak_transfer_dnl_lsb": peak_transfer_dnl,
        }
        for col, key in zip(group_cols, keys):
            row[col] = key
        rows.append(row)

    result = pd.DataFrame.from_records(rows)
    if result.empty:
        return result
    sort_cols = [col for col in group_cols if col in result.columns]
    if sort_cols:
        result = result.sort_values(sort_cols, ignore_index=True)
    return result


def audit_tref(
    df: pd.DataFrame,
    *,
    mode: str,
    start_pulse_width_ps: int,
) -> tuple[pd.DataFrame, dict[str, object]]:
    """Add Tref_audit_ps and preserve the logged Tref_ps for traceability."""
    if "Tref_ps" not in df.columns:
        return df, {
            "mode": mode,
            "source": "missing",
            "offset_applied_ps": float("nan"),
            "note": "No Tref_ps column was found.",
        }

    df = df.copy()
    df["Tref_logged_ps"] = pd.to_numeric(df["Tref_ps"], errors="coerce")

    source = "logged_Tref_ps"
    offset = 0
    note = "Using logged Tref_ps without offset."

    if mode == "auto":
        if "true_dt_ps" in df.columns:
            df["Tref_audit_ps"] = pd.to_numeric(df["true_dt_ps"], errors="coerce")
            source = "true_dt_ps"
            note = "Using true_dt_ps from dataset."
        elif {"stop_time_ps", "start_time_ps"}.issubset(df.columns):
            stop = pd.to_numeric(df["stop_time_ps"], errors="coerce")
            start = pd.to_numeric(df["start_time_ps"], errors="coerce")
            df["Tref_audit_ps"] = stop - start
            source = "stop_time_ps_minus_start_time_ps"
            note = "Using explicit STOP rising minus START rising timestamps."
        else:
            df["Tref_audit_ps"] = df["Tref_logged_ps"] + start_pulse_width_ps
            source = "legacy_campaign_collect_gap_plus_start_pulse"
            offset = start_pulse_width_ps
            note = (
                "Legacy tb_campaign_collect logs the gap after START falls; "
                "analysis uses START rising to STOP rising."
            )
    elif mode == "logged":
        df["Tref_audit_ps"] = df["Tref_logged_ps"]
    elif mode == "start_to_stop":
        if {"stop_time_ps", "start_time_ps"}.issubset(df.columns):
            stop = pd.to_numeric(df["stop_time_ps"], errors="coerce")
            start = pd.to_numeric(df["start_time_ps"], errors="coerce")
            df["Tref_audit_ps"] = stop - start
            source = "stop_time_ps_minus_start_time_ps"
            note = "Forced START rising to STOP rising from explicit timestamps."
        else:
            df["Tref_audit_ps"] = df["Tref_logged_ps"] + start_pulse_width_ps
            source = "logged_Tref_plus_start_pulse"
            offset = start_pulse_width_ps
            note = "Forced START rising to STOP rising by adding pulse width."
    else:
        raise ValueError(f"Unsupported Tref mode: {mode}")

    # Rebind Tref_ps for legacy plotting/profile helpers while preserving input.
    df["Tref_ps"] = df["Tref_audit_ps"]
    valid_delta = (df["Tref_audit_ps"] - df["Tref_logged_ps"]).dropna()
    audit = {
        "mode": mode,
        "source": source,
        "offset_applied_ps": int(offset),
        "start_pulse_width_ps": int(start_pulse_width_ps),
        "logged_min_ps": _finite_or_nan(df["Tref_logged_ps"].min()),
        "logged_max_ps": _finite_or_nan(df["Tref_logged_ps"].max()),
        "audit_min_ps": _finite_or_nan(df["Tref_audit_ps"].min()),
        "audit_max_ps": _finite_or_nan(df["Tref_audit_ps"].max()),
        "delta_min_ps": _finite_or_nan(valid_delta.min()) if not valid_delta.empty else float("nan"),
        "delta_max_ps": _finite_or_nan(valid_delta.max()) if not valid_delta.empty else float("nan"),
        "note": note,
    }
    return df, audit


def plot_inl_dnl_corrected(edges, dnl, inl, config: str, out_dir: Path) -> None:
    fig, axes = plt.subplots(2, 1, figsize=(8, 6), sharex=True)
    x = np.arange(len(dnl))
    axes[0].bar(x, dnl, width=1.0, color=PALETTE["blue"])
    axes[0].set_ylabel("DNL (LSB)")
    axes[0].set_title(f"Corrected pooled DNL diagnostic - {config}")
    axes[1].plot(x, inl, color=PALETTE["orange"])
    axes[1].set_ylabel("INL (LSB)")
    axes[1].set_xlabel("Code bin index")
    axes[1].set_title("Corrected pooled INL diagnostic")
    for ax in axes:
        style_axes(ax)
    save_figure(fig, out_dir / f"inl_dnl_corrected_pooled_{legacy._safe_config(config)}.png")


def plot_stratified_metric(summary: pd.DataFrame, x_col: str, config: str, out_dir: Path) -> None:
    if summary.empty or x_col not in summary.columns:
        return
    fig, ax = plt.subplots(figsize=(8, 4.5))
    x = summary[x_col].astype(float).to_numpy()
    ax.plot(x, summary["peak_dnl_lsb"], marker="o", lw=1.2, label="Peak DNL")
    ax.plot(x, summary["peak_inl_lsb"], marker="s", lw=1.2, label="Peak INL")
    ax.set_xlabel(x_col)
    ax.set_ylabel("LSB")
    ax.set_title(f"Corrected DNL/INL by {x_col} - {config}")
    ax.legend()
    style_axes(ax)
    save_figure(fig, out_dir / f"stratified_dnl_inl_by_{x_col}_{legacy._safe_config(config)}.png")


def _best_worst_lines(summary: pd.DataFrame, label: str, key_cols: list[str]) -> list[str]:
    if summary.empty:
        return [f"    {label}: unavailable"]
    worst = summary.loc[summary["peak_inl_lsb"].idxmax()]
    key = ", ".join(f"{col}={worst[col]}" for col in key_cols if col in worst)
    return [
        f"    Worst {label}: {key}  rows={int(worst['rows'])}  "
        f"PkDNL={worst['peak_dnl_lsb']:.3f} LSB  "
        f"PkINL={worst['peak_inl_lsb']:.3f} LSB  "
        f"finalINL={worst['final_inl_lsb']:.3g} LSB"
    ]


def _best_worst_transfer_lines(summary: pd.DataFrame, label: str, key_cols: list[str]) -> list[str]:
    if summary.empty:
        return [f"    {label}: unavailable"]
    worst = summary.loc[summary["peak_transfer_inl_lsb"].idxmax()]
    key = ", ".join(f"{col}={worst[col]}" for col in key_cols if col in worst)
    return [
        f"    Worst {label}: {key}  rows={int(worst['rows'])}  "
        f"slope={worst['endpoint_slope_ps_per_ps']:.6f}  "
        f"PkTransferDNL={worst['peak_transfer_dnl_lsb']:.3f} LSB  "
        f"PkTransferINL={worst['peak_transfer_inl_lsb']:.3f} LSB"
    ]


def analyze_config_v2(
    config: str,
    df: pd.DataFrame,
    out_dir: Path,
    *,
    do_plots: bool,
    tref_mode: str,
    start_pulse_width_ps: int,
) -> dict[str, object]:
    result: dict[str, object] = {}
    df, tref_audit = audit_tref(
        df,
        mode=tref_mode,
        start_pulse_width_ps=start_pulse_width_ps,
    )
    result["tref_audit"] = tref_audit
    df = legacy.compute_residual(df)

    result["offset_stats"] = legacy.basic_stats(df["offset_ps"])
    print(f"  Rows: {len(df):>10d}  |  Mean offset: {result['offset_stats']['mean']:.2f} ps  "
          f"|  Std: {result['offset_stats']['std']:.2f} ps  "
          f"|  RMSE: {result['offset_stats']['rmse']:.2f} ps")
    print(f"  Tref audit: {tref_audit['source']}  "
          f"delta={tref_audit['delta_min_ps']:.0f}..{tref_audit['delta_max_ps']:.0f} ps")

    mismatches = legacy.cross_check_vernier(df)
    result["mismatches"] = mismatches
    if mismatches == 0:
        print("  Vernier cross-check: PASS (0 mismatches)")
    elif mismatches > 0:
        print(f"  Vernier cross-check: FAIL ({mismatches} mismatches)")
    else:
        print("  Vernier cross-check: SKIPPED (missing columns)")

    edges, dnl, inl, peak_dnl, peak_inl, pooled_stats = compute_inl_dnl_corrected(df["t_raw_ps"])
    result["pooled_dnl_inl"] = {
        **pooled_stats,
        "peak_dnl_lsb": peak_dnl,
        "peak_inl_lsb": peak_inl,
        "diagnostic_only": True,
    }
    print("  Corrected pooled code-occupancy diagnostic: "
          f"Peak DNL={peak_dnl:.3f} LSB  Peak INL={peak_inl:.3f} LSB  "
          f"final INL={pooled_stats['final_inl']:.3g} LSB")

    hit_idx_dnl = compute_inl_dnl_summary(df, ["hit_idx"])
    nslow_dnl = compute_inl_dnl_summary(df, ["nslow"])
    hit_idx_transfer = compute_transfer_linearity_summary(df, ["hit_idx"])
    nslow_transfer = compute_transfer_linearity_summary(df, ["nslow"])
    result["hit_idx_dnl_inl"] = hit_idx_dnl
    result["nslow_dnl_inl"] = nslow_dnl
    result["hit_idx_transfer_linearity"] = hit_idx_transfer
    result["nslow_transfer_linearity"] = nslow_transfer

    for line in _best_worst_lines(hit_idx_dnl, "hit_idx INL", ["hit_idx"]):
        print(line)
    for line in _best_worst_lines(nslow_dnl, "nslow INL", ["nslow"]):
        print(line)
    for line in _best_worst_transfer_lines(hit_idx_transfer, "hit_idx transfer INL", ["hit_idx"]):
        print(line)
    for line in _best_worst_transfer_lines(nslow_transfer, "nslow transfer INL", ["nslow"]):
        print(line)

    class_stats, ttest_results = legacy.boundary_class_analysis(df)
    result["boundary_classes"] = class_stats
    result["ttest_results"] = ttest_results
    if class_stats:
        print(f"  Boundary classes found: {len(class_stats)}")

    raw_tuple_hist = legacy.compute_raw_tuple_histogram(df)
    result["raw_tuple_histogram_summary"] = {}
    if not raw_tuple_hist.empty:
        result["raw_tuple_histogram_summary"] = {
            "occupied_bins": int(len(raw_tuple_hist)),
            "total_samples": int(raw_tuple_hist["count"].sum()),
            "min_count": int(raw_tuple_hist["count"].min()),
            "median_count": float(raw_tuple_hist["count"].median()),
            "max_count": int(raw_tuple_hist["count"].max()),
            "peak_dnl_est": float(raw_tuple_hist["raw_tuple_dnl_est"].abs().max()),
            "peak_inl_est": float(raw_tuple_hist["raw_tuple_inl_est"].abs().max()),
        }

    fdist = legacy.flag_distribution(df)
    result["flag_dist"] = fdist
    if fdist:
        print("  Flags: " + ", ".join(f"{k}={v}" for k, v in fdist.items()))

    delay_profile = legacy.compute_binned_profile(df, "Tref_ps", n_bins=legacy.PROFILE_DELAY_BINS)
    nslow_profile = legacy.compute_discrete_profile(df, "nslow")
    nfast_profile = legacy.compute_discrete_profile(df, "nfast_hit")
    hit_idx_profile = legacy.compute_discrete_profile(df, "hit_idx")
    traw_profile = legacy.compute_binned_profile(df, "t_raw_ps", n_bins=legacy.PROFILE_TRAW_BINS)
    delay_regions = legacy.compute_delay_regions(df)
    result.update({
        "delay_profile": delay_profile,
        "nslow_profile": nslow_profile,
        "nfast_profile": nfast_profile,
        "hit_idx_profile": hit_idx_profile,
        "traw_profile": traw_profile,
        "delay_regions": delay_regions,
    })

    out_dir.mkdir(parents=True, exist_ok=True)
    safe_cfg = legacy._safe_config(config)
    hit_idx_dnl.to_csv(out_dir / f"stratified_dnl_inl_by_hit_idx_{safe_cfg}.csv", index=False)
    nslow_dnl.to_csv(out_dir / f"stratified_dnl_inl_by_nslow_{safe_cfg}.csv", index=False)
    hit_idx_transfer.to_csv(out_dir / f"transfer_linearity_by_hit_idx_{safe_cfg}.csv", index=False)
    nslow_transfer.to_csv(out_dir / f"transfer_linearity_by_nslow_{safe_cfg}.csv", index=False)
    if not delay_profile.empty:
        delay_profile.to_csv(out_dir / f"delay_profile_{safe_cfg}.csv", index=False)
        worst_delay = delay_profile.loc[delay_profile["rmse"].idxmax()]
        print("  Worst corrected-Tref delay bin: "
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
    if not raw_tuple_hist.empty:
        raw_tuple_hist.to_csv(out_dir / f"raw_tuple_histogram_{safe_cfg}.csv", index=False)

    mean_piv, std_piv, count_piv = legacy.phase_heatmaps(df)
    if count_piv is not None and not count_piv.empty:
        count_piv.to_csv(out_dir / f"phase_count_heatmap_{safe_cfg}.csv")

    if do_plots:
        try:
            if {"Tref_ps", "t_raw_ps"}.issubset(df.columns):
                legacy.plot_linearity(df, config, out_dir)
                legacy.plot_residual(df, config, out_dir)
            legacy.plot_residual_hist(df, config, out_dir)
            plot_inl_dnl_corrected(edges, dnl, inl, config, out_dir)
            plot_stratified_metric(hit_idx_dnl, "hit_idx", config, out_dir)
            plot_stratified_metric(nslow_dnl, "nslow", config, out_dir)
            legacy.plot_raw_tuple_histogram(raw_tuple_hist, config, out_dir)
            if mean_piv is not None and not mean_piv.empty:
                legacy.plot_phase_heatmap(
                    mean_piv, config, out_dir,
                    stem="phase_heatmap_mean",
                    title="Mean bias ns x nf",
                    cbar_label="ps",
                    cmap="RdBu_r",
                    center_zero=True,
                )
            if std_piv is not None and not std_piv.empty:
                legacy.plot_phase_heatmap(
                    std_piv, config, out_dir,
                    stem="phase_heatmap_std",
                    title="Std dev ns x nf",
                    cbar_label="ps",
                    cmap="viridis",
                )
            legacy.plot_boundary_class_summary(class_stats, config, out_dir)
            legacy.plot_hit_count_dist(df, config, out_dir)
            legacy.plot_binned_profile(
                delay_profile, config, out_dir, "delay_error_profile",
                title="Error profile vs audited Tref",
                x_label="Audited true delay (ns)", x_scale=1000.0,
            )
            print(f"  Plots saved to {out_dir}/")
        except Exception as exc:
            print(f"  [WARN] Plot generation error: {exc}")

    return result


def _df_records(df: object) -> list[dict[str, object]]:
    if isinstance(df, pd.DataFrame):
        return df.to_dict(orient="records")
    return []


def _json_ready_results(all_results: dict[str, dict[str, object]], ttest_all: dict) -> dict:
    ready: dict[str, dict[str, object]] = {}
    for cfg, res in sorted(all_results.items()):
        cfg_ready: dict[str, object] = {
            "offset_stats": res.get("offset_stats", {}),
            "pooled_dnl_inl": res.get("pooled_dnl_inl", {}),
            "tref_audit": res.get("tref_audit", {}),
            "raw_tuple_histogram": res.get("raw_tuple_histogram_summary", {}),
            "mismatches": res.get("mismatches"),
            "flag_dist": res.get("flag_dist", {}),
            "ttest_results": ttest_all.get(cfg, []),
            "hit_idx_dnl_inl": _df_records(res.get("hit_idx_dnl_inl")),
            "nslow_dnl_inl": _df_records(res.get("nslow_dnl_inl")),
            "hit_idx_transfer_linearity": _df_records(res.get("hit_idx_transfer_linearity")),
            "nslow_transfer_linearity": _df_records(res.get("nslow_transfer_linearity")),
        }
        boundary = res.get("boundary_classes", {})
        cfg_ready["boundary_classes"] = {
            f"phase0_{key[0]}__sbi_{key[1]}": value
            for key, value in boundary.items()
        }
        for profile_name in (
            "delay_profile", "nslow_profile", "nfast_profile",
            "hit_idx_profile", "traw_profile", "delay_regions",
        ):
            cfg_ready[profile_name] = _df_records(res.get(profile_name))
        ready[cfg] = cfg_ready
    return ready


def write_summary_report_v2(all_results: dict, out_path: Path, ttest_all: dict) -> None:
    lines: list[str] = []
    lines.append("=" * 80)
    lines.append("MPTDC Campaign Analysis v2 - Corrected DNL/INL Summary")
    lines.append("=" * 80)
    lines.append("")
    lines.append("Notes:")
    lines.append("  - Pooled code-occupancy DNL/INL is diagnostic only; signoff review should use strata.")
    lines.append("  - Transfer-linearity INL/DNL is computed from mean t_raw versus Tref bins.")
    lines.append("  - DNL/INL bin edges include one full bin above max code.")
    lines.append("  - Auto Tref mode uses START-rising to STOP-rising semantics.")
    lines.append("")

    header = (
        f"{'Config':<40s} {'Count':>10s} {'RMSE':>10s} "
        f"{'OccDNL':>9s} {'OccINL':>9s} {'HitXferINL':>12s} "
        f"{'NslowXferINL':>14s} {'TrefSource':>24s}"
    )
    lines.append(header)
    lines.append("-" * len(header))
    for cfg, res in sorted(all_results.items()):
        stats = res.get("offset_stats", {})
        pooled = res.get("pooled_dnl_inl", {})
        hit_df = res.get("hit_idx_transfer_linearity")
        nslow_df = res.get("nslow_transfer_linearity")
        hit_worst = float(hit_df["peak_transfer_inl_lsb"].max()) if isinstance(hit_df, pd.DataFrame) and not hit_df.empty else float("nan")
        nslow_worst = float(nslow_df["peak_transfer_inl_lsb"].max()) if isinstance(nslow_df, pd.DataFrame) and not nslow_df.empty else float("nan")
        tref = res.get("tref_audit", {})
        lines.append(
            f"{cfg:<40s} {stats.get('count', 0):>10d} {stats.get('rmse', 0):>10.2f} "
            f"{pooled.get('peak_dnl_lsb', float('nan')):>9.3f} "
            f"{pooled.get('peak_inl_lsb', float('nan')):>9.3f} "
            f"{hit_worst:>12.3f} {nslow_worst:>14.3f} "
            f"{str(tref.get('source', '?')):>24s}"
        )
    lines.append("")

    lines.append("-" * 80)
    lines.append("Tref audit")
    lines.append("-" * 80)
    for cfg, res in sorted(all_results.items()):
        tref = res.get("tref_audit", {})
        lines.append(f"  Config: {cfg}")
        lines.append(f"    source: {tref.get('source')}")
        lines.append(f"    note  : {tref.get('note')}")
        lines.append(
            f"    logged range: {tref.get('logged_min_ps'):.0f}..{tref.get('logged_max_ps'):.0f} ps; "
            f"audited range: {tref.get('audit_min_ps'):.0f}..{tref.get('audit_max_ps'):.0f} ps"
        )
        lines.append(
            f"    applied delta: {tref.get('delta_min_ps'):.0f}..{tref.get('delta_max_ps'):.0f} ps"
        )

    lines.append("")
    lines.append("-" * 80)
    lines.append("Worst stratified DNL/INL")
    lines.append("-" * 80)
    for cfg, res in sorted(all_results.items()):
        lines.append(f"  Config: {cfg}")
        lines.extend(_best_worst_lines(res.get("hit_idx_dnl_inl", pd.DataFrame()), "hit_idx occupancy INL", ["hit_idx"]))
        lines.extend(_best_worst_lines(res.get("nslow_dnl_inl", pd.DataFrame()), "nslow occupancy INL", ["nslow"]))
        lines.extend(_best_worst_transfer_lines(res.get("hit_idx_transfer_linearity", pd.DataFrame()), "hit_idx transfer INL", ["hit_idx"]))
        lines.extend(_best_worst_transfer_lines(res.get("nslow_transfer_linearity", pd.DataFrame()), "nslow transfer INL", ["nslow"]))
    lines.append("")

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
    lines.append("=" * 80)
    lines.append("End of v2 report")
    lines.append("=" * 80)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"[INFO] Summary report written to {out_path}")


def run_self_test() -> None:
    uniform = pd.Series(np.repeat(np.arange(0, 1000, legacy.DELTA_LSB), 1000))
    _, _, _, peak_dnl, peak_inl, stats = compute_inl_dnl_corrected(uniform)
    if peak_dnl != 0.0 or peak_inl != 0.0 or stats["final_inl"] != 0.0:
        raise AssertionError(
            "Uniform synthetic DNL/INL self-test failed: "
            f"peak_dnl={peak_dnl}, peak_inl={peak_inl}, final_inl={stats['final_inl']}"
        )
    linear_df = pd.DataFrame({
        "Tref_ps": np.arange(0, 1000, legacy.DELTA_LSB),
        "t_raw_ps": np.arange(0, 1000, legacy.DELTA_LSB),
        "hit_idx": 0,
        "nslow": 1,
    })
    xfer = compute_transfer_linearity_summary(linear_df)
    if xfer.empty or xfer.iloc[0]["peak_transfer_inl_lsb"] != 0.0:
        raise AssertionError("Linear transfer self-test failed")
    print("[SELFTEST] uniform synthetic DNL/INL: PASS (0.0 / 0.0 LSB)")
    print("[SELFTEST] ideal transfer linearity: PASS (0.0 INL)")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="MPTDC campaign analysis v2 with corrected and stratified DNL/INL."
    )
    parser.add_argument("--campaign-dir", default="results/campaign/",
                        help="Root directory of campaign CSV files.")
    parser.add_argument("--output-dir", default="results/campaign/analysis_v2/",
                        help="Directory for output plots and reports.")
    parser.add_argument("--config-filter", default=None,
                        help="Glob pattern to select configurations.")
    parser.add_argument("--max-files", type=int, default=None,
                        help="Max CSV files to load per config.")
    parser.add_argument("--no-plots", action="store_true",
                        help="Skip plot generation.")
    parser.add_argument("--tref-mode", choices=("auto", "logged", "start_to_stop"),
                        default="logged",
                        help="Reference time interpretation. Use start_to_stop/auto for explicit timing audits.")
    parser.add_argument("--start-pulse-width-ps", type=int,
                        default=DEFAULT_START_PULSE_WIDTH_PS,
                        help="START pulse width added for legacy campaign_collect Tref audit.")
    parser.add_argument("--self-test", action="store_true",
                        help="Run synthetic DNL/INL self-test and exit.")
    args = parser.parse_args()

    if args.self_test:
        run_self_test()
        return

    out_dir = Path(args.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    configs = legacy.discover_csv_files(args.campaign_dir, args.config_filter, args.max_files)
    if not configs:
        print("[ERROR] No CSV files found. Check --campaign-dir path.")
        sys.exit(1)

    print(f"[INFO] Found {len(configs)} configuration(s) in {args.campaign_dir}")
    for cfg, paths in configs.items():
        print(f"  {cfg}: {len(paths)} file(s)")
    print()

    all_results: dict[str, dict[str, object]] = {}
    ttest_all: dict[str, list] = {}
    for cfg, paths in sorted(configs.items()):
        print("-" * 60)
        print(f"Config: {cfg}")
        print("-" * 60)
        df = legacy.load_config_data(paths)
        if df.empty:
            print("  [WARN] No data - skipping.\n")
            continue
        result = analyze_config_v2(
            cfg, df, out_dir,
            do_plots=not args.no_plots,
            tref_mode=args.tref_mode,
            start_pulse_width_ps=args.start_pulse_width_ps,
        )
        all_results[cfg] = result
        ttest_all[cfg] = result.get("ttest_results", [])
        print()

    report_path = out_dir / "summary_report_v2.txt"
    write_summary_report_v2(all_results, report_path, ttest_all)
    summary_json = out_dir / "summary_report_v2.json"
    summary_json.write_text(
        json.dumps(_json_ready_results(all_results, ttest_all), indent=2, default=str) + "\n",
        encoding="utf-8",
    )
    print(f"[INFO] Summary JSON written to {summary_json}")
    print("[INFO] Analysis v2 complete.")


if __name__ == "__main__":
    main()
