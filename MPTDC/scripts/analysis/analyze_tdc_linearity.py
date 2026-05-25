#!/usr/bin/env python3
"""Mono-hit MPTDC code-density and transfer-linearity analysis.

This analyzer is intentionally stricter than the legacy campaign reports.  It
does not treat every scalar gap between min/max code as a physical TDC bin.
Instead, it separates:

* stimulus uniformity checks;
* missing or unobserved scalar codes;
* DNL/INL over the observable code population;
* endpoint/best-fit transfer INL versus the audited true time interval.
"""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

from mptdc_char_common import (
    DELTA_LSB_PS,
    LABELS_FR,
    apply_char_style,
    discover_stage_csvs,
    numeric,
    save_char_figure,
    style_axes,
    write_markdown_table,
)


NE = 8
SLOW_HALF_PERIOD_PS = 440
SYS_CLK_PS = 6250
DEFAULT_TRANSFER_BINS = 160
DEFAULT_CHUNKSIZE = 500_000
EPS = 1e-12

USECOLS = {
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
    "stim_phase_bin",
    "stim_uniformity_bin",
}

REQUIRED_FILTER_COLS = {
    "hit_idx",
    "hit_count",
    "max_hits",
    "accepted",
    "rejected",
    "scalar_bin",
    "t_raw_ps",
}


def _ensure_len(arr: np.ndarray, size: int) -> np.ndarray:
    if size <= len(arr):
        return arr
    return np.pad(arr, (0, size - len(arr)))


def _update_bincount(counts: np.ndarray, values: pd.Series) -> np.ndarray:
    clean = pd.to_numeric(values, errors="coerce").dropna().astype(int)
    clean = clean[clean >= 0]
    if clean.empty:
        return counts
    max_idx = int(clean.max())
    counts = _ensure_len(counts, max_idx + 1)
    counts[: max_idx + 1] += np.bincount(clean.to_numpy(), minlength=max_idx + 1)
    return counts


def _series_mod_counts(values: pd.Series, modulus: int) -> np.ndarray:
    clean = pd.to_numeric(values, errors="coerce").dropna().astype(int)
    clean = clean[clean >= 0]
    if clean.empty:
        return np.zeros(modulus, dtype=np.int64)
    return np.bincount((clean % modulus).to_numpy(), minlength=modulus).astype(np.int64)


def _finite(value: float) -> float:
    return float(value) if np.isfinite(value) else float("nan")


def _true_dt_ps(df: pd.DataFrame) -> pd.Series:
    if "true_dt_ps" in df.columns:
        return numeric(df, "true_dt_ps")
    if {"start_time_ps", "stop_time_ps"}.issubset(df.columns):
        return numeric(df, "stop_time_ps") - numeric(df, "start_time_ps")
    return numeric(df, "Tref_ps")


def _linearity_mask(df: pd.DataFrame) -> pd.Series:
    missing = sorted(col for col in REQUIRED_FILTER_COLS if col not in df.columns)
    if missing:
        raise ValueError("Missing required code-density columns: " + ", ".join(missing))

    scalar = numeric(df, "scalar_bin")
    t_raw = numeric(df, "t_raw_ps")
    mask = (
        (numeric(df, "accepted").fillna(0).astype(int) == 1)
        & (numeric(df, "rejected").fillna(1).astype(int) == 0)
        & (numeric(df, "max_hits").fillna(-1).astype(int) == 1)
        & (numeric(df, "hit_idx").fillna(-1).astype(int) == 0)
        & (numeric(df, "hit_count").fillna(-1).astype(int) == 1)
        & scalar.notna()
        & (scalar >= 0)
        & t_raw.notna()
    )
    return mask


def iter_filtered_chunks(paths: Iterable[Path], chunksize: int):
    for path in paths:
        for chunk in pd.read_csv(
            path,
            chunksize=chunksize,
            usecols=lambda col: col in USECOLS,
        ):
            chunk["source_file"] = str(path)
            mask = _linearity_mask(chunk)
            if not mask.any():
                continue
            work = chunk.loc[mask].copy()
            work["true_dt_ps"] = _true_dt_ps(work)
            work = work[work["true_dt_ps"].notna()]
            if not work.empty:
                yield work


@dataclass
class LinearityAggregates:
    rows_total: int = 0
    rows_valid: int = 0
    rejected_by_filter: int = 0
    scalar_counts: np.ndarray = field(default_factory=lambda: np.zeros(1, dtype=np.int64))
    tuple_counts: np.ndarray = field(default_factory=lambda: np.zeros(1, dtype=np.int64))
    phase_counts: np.ndarray = field(default_factory=lambda: np.zeros((NE, NE), dtype=np.int64))
    stop_disc_counts: np.ndarray = field(default_factory=lambda: np.zeros(8, dtype=np.int64))
    stim_phase_counts: np.ndarray = field(default_factory=lambda: np.zeros(SLOW_HALF_PERIOD_PS, dtype=np.int64))
    true_mod_counts: np.ndarray = field(default_factory=lambda: np.zeros(SLOW_HALF_PERIOD_PS, dtype=np.int64))
    start_phase_counts: np.ndarray = field(default_factory=lambda: np.zeros(64, dtype=np.int64))
    true_min_ps: float = float("inf")
    true_max_ps: float = float("-inf")
    raw_min_ps: float = float("inf")
    raw_max_ps: float = float("-inf")

    def add_raw_chunk_stats(self, chunk: pd.DataFrame) -> None:
        self.rows_total += int(len(chunk))
        try:
            valid = int(_linearity_mask(chunk).sum())
        except ValueError:
            valid = 0
        self.rows_valid += valid
        self.rejected_by_filter += int(len(chunk) - valid)

    def add_filtered(self, work: pd.DataFrame) -> None:
        self.scalar_counts = _update_bincount(self.scalar_counts, work["scalar_bin"])
        if "tuple_code" in work.columns:
            self.tuple_counts = _update_bincount(self.tuple_counts, work["tuple_code"])

        ns = numeric(work, "ns").astype("Int64")
        nf = numeric(work, "nf").astype("Int64")
        valid_phase = ns.notna() & nf.notna() & (ns >= 0) & (ns < NE) & (nf >= 0) & (nf < NE)
        for ns_i, nf_i in zip(ns[valid_phase].astype(int), nf[valid_phase].astype(int)):
            self.phase_counts[ns_i, nf_i] += 1

        if "stop_phase_disc" in work.columns:
            self.stop_disc_counts += np.bincount(
                numeric(work, "stop_phase_disc").dropna().astype(int).clip(0, 7),
                minlength=8,
            )[:8]
        # Use the requested delay as the primary stimulus audit.  The optional
        # stim_phase_bin column is useful for TB debug, but older or malformed
        # rows can leave it incomplete while Tref_ps remains the authoritative
        # plusarg-driven delay.
        if "Tref_ps" in work.columns:
            self.stim_phase_counts += _series_mod_counts(work["Tref_ps"], SLOW_HALF_PERIOD_PS)
        elif "stim_phase_bin" in work.columns:
            self.stim_phase_counts += _series_mod_counts(work["stim_phase_bin"], SLOW_HALF_PERIOD_PS)
        if "start_time_ps" in work.columns:
            self.start_phase_counts += np.bincount(
                ((numeric(work, "start_time_ps").dropna().astype(int) % SYS_CLK_PS) * 64 // SYS_CLK_PS),
                minlength=64,
            )[:64]

        true_dt = pd.to_numeric(work["true_dt_ps"], errors="coerce").dropna()
        raw = numeric(work, "t_raw_ps").dropna()
        if not true_dt.empty:
            self.true_mod_counts += _series_mod_counts(true_dt, SLOW_HALF_PERIOD_PS)
            self.true_min_ps = min(self.true_min_ps, float(true_dt.min()))
            self.true_max_ps = max(self.true_max_ps, float(true_dt.max()))
        if not raw.empty:
            self.raw_min_ps = min(self.raw_min_ps, float(raw.min()))
            self.raw_max_ps = max(self.raw_max_ps, float(raw.max()))


@dataclass
class TransferAggregates:
    edges: np.ndarray
    count: np.ndarray
    sum_true: np.ndarray
    sum_raw: np.ndarray
    sum_raw2: np.ndarray

    @classmethod
    def create(cls, lo: float, hi: float, n_bins: int):
        if not np.isfinite(lo) or not np.isfinite(hi) or hi <= lo:
            edges = np.array([0.0, 1.0])
        else:
            edges = np.linspace(lo, hi, n_bins + 1)
        n = len(edges) - 1
        return cls(
            edges=edges,
            count=np.zeros(n, dtype=np.int64),
            sum_true=np.zeros(n, dtype=float),
            sum_raw=np.zeros(n, dtype=float),
            sum_raw2=np.zeros(n, dtype=float),
        )

    def add(self, work: pd.DataFrame) -> None:
        true_dt = pd.to_numeric(work["true_dt_ps"], errors="coerce").to_numpy(dtype=float)
        raw = numeric(work, "t_raw_ps").to_numpy(dtype=float)
        valid = np.isfinite(true_dt) & np.isfinite(raw)
        if not np.any(valid):
            return
        idx = np.searchsorted(self.edges, true_dt[valid], side="right") - 1
        idx = np.clip(idx, 0, len(self.count) - 1)
        np.add.at(self.count, idx, 1)
        np.add.at(self.sum_true, idx, true_dt[valid])
        np.add.at(self.sum_raw, idx, raw[valid])
        np.add.at(self.sum_raw2, idx, raw[valid] ** 2)

    def profile(self) -> pd.DataFrame:
        valid = self.count > 0
        if not np.any(valid):
            return pd.DataFrame()
        count = self.count[valid].astype(float)
        true_mean = self.sum_true[valid] / count
        raw_mean = self.sum_raw[valid] / count
        raw_std = np.sqrt(np.maximum(0.0, self.sum_raw2[valid] / count - raw_mean**2))
        bins = np.flatnonzero(valid)
        return pd.DataFrame(
            {
                "bin_index": bins,
                "true_lo_ps": self.edges[bins],
                "true_hi_ps": self.edges[bins + 1],
                "count": self.count[valid],
                "true_mean_ps": true_mean,
                "raw_mean_ps": raw_mean,
                "raw_std_ps": raw_std,
            }
        )


def discover_code_density_paths(root: Path | None, csv_paths: list[str]) -> list[Path]:
    if csv_paths:
        return sorted(Path(p) for p in csv_paths)
    if root is None:
        raise ValueError("Either --root or CSV paths must be provided.")
    paths = discover_stage_csvs(root, "code_density")
    if not paths:
        raise ValueError(f"No code_density CSV files found under {root}")
    return paths


def aggregate_first_pass(paths: list[Path], chunksize: int) -> LinearityAggregates:
    agg = LinearityAggregates()
    for path in paths:
        for raw_chunk in pd.read_csv(
            path,
            chunksize=chunksize,
            usecols=lambda col: col in USECOLS,
        ):
            agg.add_raw_chunk_stats(raw_chunk)
    for work in iter_filtered_chunks(paths, chunksize):
        agg.add_filtered(work)
    return agg


def aggregate_transfer(paths: list[Path], chunksize: int, lo: float, hi: float, n_bins: int) -> TransferAggregates:
    transfer = TransferAggregates.create(lo, hi, n_bins)
    for work in iter_filtered_chunks(paths, chunksize):
        transfer.add(work)
    return transfer


def compute_observable_dnl_inl(counts_full: np.ndarray) -> tuple[pd.DataFrame, pd.DataFrame, dict[str, float]]:
    nz = np.flatnonzero(counts_full)
    if nz.size == 0:
        return pd.DataFrame(), pd.DataFrame(), {}

    lo, hi = int(nz.min()), int(nz.max())
    full_codes = np.arange(lo, hi + 1)
    full_counts = counts_full[lo : hi + 1]
    missing_mask = full_counts == 0
    missing = pd.DataFrame(
        {
            "scalar_bin": full_codes[missing_mask],
            "status": "unobserved_or_structural",
        }
    )

    observed_codes = full_codes[~missing_mask]
    observed_counts = full_counts[~missing_mask].astype(float)
    ideal = float(observed_counts.mean())
    dnl = observed_counts / ideal - 1.0
    dnl[np.isclose(dnl, 0.0, atol=EPS, rtol=0.0)] = 0.0

    transition = np.concatenate(([0.0], np.cumsum(dnl)))
    endpoint = np.linspace(transition[0], transition[-1], len(transition))
    inl = (transition - endpoint)[1:]
    inl[np.isclose(inl, 0.0, atol=EPS, rtol=0.0)] = 0.0
    sigma_dnl = np.sqrt(np.maximum(observed_counts, 1.0)) / ideal

    table = pd.DataFrame(
        {
            "scalar_bin": observed_codes,
            "count": observed_counts.astype(np.int64),
            "dnl_lsb": dnl,
            "dnl_sigma_lsb": sigma_dnl,
            "dnl_ci95_lsb": 1.96 * sigma_dnl,
            "inl_endpoint_lsb": inl,
        }
    )
    edge_trimmed = table.iloc[1:-1].copy() if len(table) > 2 else pd.DataFrame()
    if not edge_trimmed.empty:
        edge_counts = edge_trimmed["count"].to_numpy(dtype=float)
        edge_ideal = float(edge_counts.mean())
        edge_dnl = edge_counts / edge_ideal - 1.0
        edge_transition = np.concatenate(([0.0], np.cumsum(edge_dnl)))
        edge_endpoint = np.linspace(edge_transition[0], edge_transition[-1], len(edge_transition))
        edge_inl = (edge_transition - edge_endpoint)[1:]
        edge_trimmed["dnl_edge_trimmed_lsb"] = edge_dnl
        edge_trimmed["inl_edge_trimmed_lsb"] = edge_inl

        edge_peak_dnl = float(np.max(np.abs(edge_dnl)))
        edge_peak_inl = float(np.max(np.abs(edge_inl)))
        edge_final_inl = float(edge_transition[-1])
    else:
        edge_peak_dnl = float("nan")
        edge_peak_inl = float("nan")
        edge_final_inl = float("nan")

    dominant_idx = int(np.argmax(observed_counts)) if len(observed_counts) else 0
    dominant_code = int(observed_codes[dominant_idx]) if len(observed_codes) else -1
    dominant_count = int(observed_counts[dominant_idx]) if len(observed_counts) else 0
    dominant_fraction = float(dominant_count / observed_counts.sum()) if observed_counts.sum() else float("nan")
    summary = {
        "code_min": lo,
        "code_max": hi,
        "full_code_slots": int(len(full_codes)),
        "observed_codes": int(len(observed_codes)),
        "missing_or_unobserved_codes": int(missing_mask.sum()),
        "total_hits": int(observed_counts.sum()),
        "ideal_count_observable": ideal,
        "peak_dnl_lsb": float(np.max(np.abs(dnl))) if len(dnl) else float("nan"),
        "peak_inl_endpoint_lsb": float(np.max(np.abs(inl))) if len(inl) else float("nan"),
        "edge_trimmed_peak_dnl_lsb": edge_peak_dnl,
        "edge_trimmed_peak_inl_endpoint_lsb": edge_peak_inl,
        "edge_trimmed_final_inl_lsb": edge_final_inl,
        "dominant_code": dominant_code,
        "dominant_code_count": dominant_count,
        "dominant_code_fraction": dominant_fraction,
        "final_inl_lsb": float(transition[-1]),
    }
    table.attrs["edge_trimmed"] = edge_trimmed
    return table, missing, summary


def compute_transfer_linearity(profile: pd.DataFrame) -> tuple[pd.DataFrame, dict[str, float]]:
    if profile.empty or len(profile) < 4:
        return profile, {}

    out = profile.copy()
    true = out["true_mean_ps"].to_numpy(dtype=float)
    raw = out["raw_mean_ps"].to_numpy(dtype=float)
    weights = out["count"].to_numpy(dtype=float)

    span = true[-1] - true[0]
    if span <= 0:
        return out, {}

    endpoint_slope = (raw[-1] - raw[0]) / span
    endpoint_offset = raw[0] - endpoint_slope * true[0]
    endpoint_line = endpoint_slope * true + endpoint_offset
    endpoint_err = raw - endpoint_line

    fit_slope, fit_offset = np.polyfit(true, raw, deg=1, w=np.sqrt(weights))
    fit_line = fit_slope * true + fit_offset
    fit_err = raw - fit_line

    local_dnl = np.full(len(out), np.nan)
    d_true = np.diff(true)
    d_raw = np.diff(raw)
    valid = (d_true != 0) & (endpoint_slope != 0)
    if np.any(valid):
        local = (d_raw[valid] / d_true[valid]) / endpoint_slope - 1.0
        local_dnl[1:][valid] = local

    out["endpoint_line_ps"] = endpoint_line
    out["endpoint_error_ps"] = endpoint_err
    out["endpoint_inl_lsb"] = endpoint_err / DELTA_LSB_PS
    out["bestfit_line_ps"] = fit_line
    out["bestfit_error_ps"] = fit_err
    out["bestfit_inl_lsb"] = fit_err / DELTA_LSB_PS
    out["transfer_dnl_endpoint_lsb"] = local_dnl

    summary = {
        "transfer_bins": int(len(out)),
        "endpoint_slope_ps_per_ps": float(endpoint_slope),
        "endpoint_offset_ps": float(endpoint_offset),
        "bestfit_slope_ps_per_ps": float(fit_slope),
        "bestfit_offset_ps": float(fit_offset),
        "peak_transfer_dnl_endpoint_lsb": _finite(np.nanmax(np.abs(local_dnl))),
        "peak_transfer_inl_endpoint_lsb": float(np.max(np.abs(out["endpoint_inl_lsb"]))),
        "peak_transfer_inl_bestfit_lsb": float(np.max(np.abs(out["bestfit_inl_lsb"]))),
        "peak_transfer_inl_endpoint_ps": float(np.max(np.abs(endpoint_err))),
        "peak_transfer_inl_bestfit_ps": float(np.max(np.abs(fit_err))),
    }
    return out, summary


def counts_table(counts: np.ndarray, name: str) -> pd.DataFrame:
    return pd.DataFrame({name: np.arange(len(counts)), "count": counts.astype(np.int64)})


def phase_table(phase_counts: np.ndarray) -> pd.DataFrame:
    rows = []
    for ns in range(phase_counts.shape[0]):
        for nf in range(phase_counts.shape[1]):
            rows.append({"ns": ns, "nf": nf, "count": int(phase_counts[ns, nf])})
    return pd.DataFrame(rows)


def plot_stimulus(agg: LinearityAggregates, out_dir: Path) -> None:
    fig, axes = plt.subplots(3, 1, figsize=(9, 8), constrained_layout=True)
    axes[0].bar(np.arange(len(agg.start_phase_counts)), agg.start_phase_counts, color="#1565c0")
    axes[0].set_title("Uniformite du START dans la periode clk_sys")
    axes[0].set_ylabel(LABELS_FR["count"])
    axes[0].set_xlabel("Bin de phase START / clk_sys")
    axes[1].bar(np.arange(len(agg.true_mod_counts)), agg.true_mod_counts, color="#2e7d32")
    axes[1].set_title("Temps vrai modulo 440 ps")
    axes[1].set_ylabel(LABELS_FR["count"])
    axes[1].set_xlabel("true_dt_ps mod 440 ps")
    axes[2].bar(np.arange(len(agg.stim_phase_counts)), agg.stim_phase_counts, color="#ef6c00")
    axes[2].set_title("Delai injecte modulo 440 ps")
    axes[2].set_ylabel(LABELS_FR["count"])
    axes[2].set_xlabel("stim_phase_bin")
    for ax in axes:
        style_axes(ax)
    save_char_figure(fig, out_dir / "linearity_stimulus_audit")


def plot_phase(phase_counts: np.ndarray, out_dir: Path) -> None:
    fig, ax = plt.subplots(figsize=(6.5, 5.4))
    im = ax.imshow(phase_counts, origin="lower", aspect="equal", cmap="viridis")
    ax.set_title("Occupation mono-hit des cellules de phase")
    ax.set_xlabel(LABELS_FR["nf"])
    ax.set_ylabel(LABELS_FR["ns"])
    ax.set_xticks(range(NE))
    ax.set_yticks(range(NE))
    for ns in range(NE):
        for nf in range(NE):
            ax.text(nf, ns, str(int(phase_counts[ns, nf])), ha="center", va="center", fontsize=7)
    fig.colorbar(im, ax=ax, label=LABELS_FR["count"])
    save_char_figure(fig, out_dir / "linearity_phase_occupancy")


def plot_observable_dnl_inl(table: pd.DataFrame, missing: pd.DataFrame, out_dir: Path) -> None:
    if table.empty:
        return
    fig, axes = plt.subplots(4, 1, figsize=(10, 9), sharex=False, constrained_layout=True)
    axes[0].bar(table["scalar_bin"], table["count"], width=1.0, color="#1565c0")
    axes[0].set_ylabel(LABELS_FR["count"])
    axes[0].set_title("Histogramme des codes scalaires observes")

    axes[1].plot(table["scalar_bin"], table["dnl_lsb"], color="#c62828", lw=1.0, label="DNL")
    axes[1].fill_between(
        table["scalar_bin"],
        table["dnl_lsb"] - table["dnl_ci95_lsb"],
        table["dnl_lsb"] + table["dnl_ci95_lsb"],
        color="#c62828",
        alpha=0.16,
        label="IC 95 %",
    )
    axes[1].set_ylabel(LABELS_FR["dnl"])
    axes[1].legend(loc="upper right")

    axes[2].plot(table["scalar_bin"], table["inl_endpoint_lsb"], color="#ef6c00", lw=1.0)
    axes[2].set_ylabel(LABELS_FR["inl"])

    if not missing.empty:
        axes[3].eventplot(missing["scalar_bin"].to_numpy(), colors="#6d4c41", lineoffsets=0.5)
    axes[3].set_yticks([])
    axes[3].set_ylabel("Codes vides")
    axes[3].set_xlabel("Index de code scalaire")
    axes[3].set_title("Codes non observes dans l'intervalle min-max")
    for ax in axes:
        style_axes(ax)
    save_char_figure(fig, out_dir / "linearity_observable_dnl_inl")


def plot_transfer(profile: pd.DataFrame, out_dir: Path) -> None:
    if profile.empty or "endpoint_inl_lsb" not in profile.columns:
        return
    fig, axes = plt.subplots(3, 1, figsize=(9, 8), sharex=True, constrained_layout=True)
    axes[0].plot(profile["true_mean_ps"], profile["raw_mean_ps"], color="#1565c0", lw=1.0, label="moyenne brute")
    axes[0].plot(profile["true_mean_ps"], profile["endpoint_line_ps"], "--", color="#424242", lw=1.0, label="droite endpoint")
    axes[0].set_ylabel("t_raw moyen (ps)")
    axes[0].set_title("Linaerite de transfert mono-hit")
    axes[0].legend()
    axes[1].plot(profile["true_mean_ps"], profile["endpoint_inl_lsb"], color="#ef6c00", lw=1.0, label="INL endpoint")
    axes[1].plot(profile["true_mean_ps"], profile["bestfit_inl_lsb"], color="#6a1b9a", lw=1.0, label="INL best-fit")
    axes[1].set_ylabel(LABELS_FR["inl"])
    axes[1].legend()
    axes[2].plot(profile["true_mean_ps"], profile["transfer_dnl_endpoint_lsb"], color="#c62828", lw=1.0)
    axes[2].set_ylabel(LABELS_FR["dnl"])
    axes[2].set_xlabel(LABELS_FR["Tref_ps"])
    for ax in axes:
        style_axes(ax)
    save_char_figure(fig, out_dir / "linearity_transfer")


def stimulus_summary(agg: LinearityAggregates) -> pd.DataFrame:
    rows = []
    for name, counts in (
        ("start_phase_clk_sys_64bins", agg.start_phase_counts),
        ("true_dt_mod_440ps", agg.true_mod_counts),
        ("stim_phase_mod_440ps", agg.stim_phase_counts),
    ):
        nonzero = counts[counts > 0]
        rows.append(
            {
                "histogram": name,
                "bins": int(len(counts)),
                "total": int(counts.sum()),
                "nonzero_bins": int(np.count_nonzero(counts)),
                "min_nonzero": int(nonzero.min()) if len(nonzero) else 0,
                "median_nonzero": float(np.median(nonzero)) if len(nonzero) else 0.0,
                "max": int(counts.max()) if len(counts) else 0,
                "rel_spread_peak_to_peak": float((counts.max() - nonzero.min()) / nonzero.mean())
                if len(nonzero) and nonzero.mean() else float("nan"),
            }
        )
    return pd.DataFrame(rows)


def write_outputs(
    out_dir: Path,
    agg: LinearityAggregates,
    dnl_table: pd.DataFrame,
    missing: pd.DataFrame,
    dnl_summary: dict[str, float],
    transfer_profile: pd.DataFrame,
    transfer_summary: dict[str, float],
    paths: list[Path],
    make_plots: bool,
) -> None:
    tables_dir = out_dir / "tables"
    plots_dir = out_dir / "plots"
    tables_dir.mkdir(parents=True, exist_ok=True)
    plots_dir.mkdir(parents=True, exist_ok=True)

    summary = {
        "input_files": [str(p) for p in paths],
        "rows_total": agg.rows_total,
        "rows_valid_mono_hit": agg.rows_valid,
        "rows_rejected_by_filter": agg.rejected_by_filter,
        "true_min_ps": _finite(agg.true_min_ps),
        "true_max_ps": _finite(agg.true_max_ps),
        "raw_min_ps": _finite(agg.raw_min_ps),
        "raw_max_ps": _finite(agg.raw_max_ps),
        **{f"observable_{k}": v for k, v in dnl_summary.items()},
        **{f"transfer_{k}": v for k, v in transfer_summary.items()},
    }
    (out_dir / "linearity_summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    pd.DataFrame([summary]).to_csv(tables_dir / "linearity_summary.csv", index=False)
    write_markdown_table(pd.DataFrame([summary]), tables_dir / "linearity_summary.md", "Synthese INL DNL mono-hit")

    dnl_table.to_csv(tables_dir / "observable_dnl_inl.csv", index=False)
    edge_trimmed = dnl_table.attrs.get("edge_trimmed", pd.DataFrame())
    if isinstance(edge_trimmed, pd.DataFrame) and not edge_trimmed.empty:
        edge_trimmed.to_csv(tables_dir / "observable_dnl_inl_edge_trimmed.csv", index=False)
    missing.to_csv(tables_dir / "missing_scalar_codes.csv", index=False)
    transfer_profile.to_csv(tables_dir / "transfer_linearity.csv", index=False)
    phase_table(agg.phase_counts).to_csv(tables_dir / "phase_occupancy.csv", index=False)
    stimulus_summary(agg).to_csv(tables_dir / "stimulus_audit.csv", index=False)
    counts_table(agg.stop_disc_counts, "stop_phase_disc").to_csv(tables_dir / "stop_phase_disc_counts.csv", index=False)

    if make_plots:
        plot_stimulus(agg, plots_dir)
        plot_phase(agg.phase_counts, plots_dir)
        plot_observable_dnl_inl(dnl_table, missing, plots_dir)
        plot_transfer(transfer_profile, plots_dir)


def run_analysis(args: argparse.Namespace) -> None:
    apply_char_style()
    root = Path(args.root) if args.root else None
    paths = discover_code_density_paths(root, args.csv)
    out_dir = Path(args.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    agg = aggregate_first_pass(paths, args.chunksize)
    if agg.rows_valid == 0:
        raise RuntimeError("No valid mono-hit rows after filters; check max_hits=1/hit_count=1 campaign setup.")

    transfer = aggregate_transfer(paths, args.chunksize, agg.true_min_ps, agg.true_max_ps, args.transfer_bins)
    transfer_profile, transfer_summary = compute_transfer_linearity(transfer.profile())
    dnl_table, missing, dnl_summary = compute_observable_dnl_inl(agg.scalar_counts)

    write_outputs(
        out_dir=out_dir,
        agg=agg,
        dnl_table=dnl_table,
        missing=missing,
        dnl_summary=dnl_summary,
        transfer_profile=transfer_profile,
        transfer_summary=transfer_summary,
        paths=paths,
        make_plots=not args.no_plots,
    )
    print(f"[LINEARITY] valid mono-hit rows: {agg.rows_valid}")
    print(
        "[LINEARITY] observable DNL/INL: "
        f"peak DNL={dnl_summary.get('peak_dnl_lsb', float('nan')):.3f} LSB, "
        f"peak endpoint INL={dnl_summary.get('peak_inl_endpoint_lsb', float('nan')):.3f} LSB, "
        f"missing/unobserved codes={dnl_summary.get('missing_or_unobserved_codes', 0)}"
    )
    print(
        "[LINEARITY] transfer INL: "
        f"endpoint={transfer_summary.get('peak_transfer_inl_endpoint_lsb', float('nan')):.3f} LSB, "
        f"best-fit={transfer_summary.get('peak_transfer_inl_bestfit_lsb', float('nan')):.3f} LSB"
    )
    print(f"[LINEARITY] outputs: {out_dir}")


def run_self_test() -> None:
    counts = np.zeros(32, dtype=np.int64)
    counts[8:24] = 1000
    dnl_table, missing, summary = compute_observable_dnl_inl(counts)
    if not missing.empty:
        # Only the observed min/max interval is audited, so exterior zero bins
        # must not be counted as missing physical codes.
        raise AssertionError("Observable interval should not include exterior zero bins")
    if summary["peak_dnl_lsb"] != 0.0 or summary["peak_inl_endpoint_lsb"] != 0.0:
        raise AssertionError("Uniform observable DNL/INL self-test failed")

    profile = pd.DataFrame(
        {
            "bin_index": np.arange(20),
            "true_lo_ps": np.arange(20) * 10.0,
            "true_hi_ps": np.arange(1, 21) * 10.0,
            "count": np.full(20, 100),
            "true_mean_ps": np.arange(20) * 10.0 + 5.0,
            "raw_mean_ps": np.arange(20) * 10.0 + 5.0,
            "raw_std_ps": np.zeros(20),
        }
    )
    transfer, tsummary = compute_transfer_linearity(profile)
    if transfer.empty or tsummary["peak_transfer_inl_endpoint_lsb"] != 0.0:
        raise AssertionError("Ideal transfer self-test failed")
    print("[SELFTEST] observable DNL/INL uniform: PASS")
    print("[SELFTEST] ideal transfer-linearity: PASS")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Strict mono-hit MPTDC DNL/INL and transfer-linearity analyzer."
    )
    parser.add_argument("csv", nargs="*", help="Optional explicit code-density CSV paths.")
    parser.add_argument("--root", help="Characterization root containing stages/code_density.")
    parser.add_argument("--output-dir", default="results/characterization/linearity_analysis")
    parser.add_argument("--chunksize", type=int, default=DEFAULT_CHUNKSIZE)
    parser.add_argument("--transfer-bins", type=int, default=DEFAULT_TRANSFER_BINS)
    parser.add_argument("--no-plots", action="store_true")
    parser.add_argument("--self-test", action="store_true", help="Run synthetic self-tests and exit.")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if args.self_test:
        run_self_test()
        return
    run_analysis(args)


if __name__ == "__main__":
    main()
