#!/usr/bin/env python3
"""Analyze standalone MPTDC Verilator characterization runs.

The overnight code-density stage can easily exceed tens of millions of rows, so
this script deliberately streams CSV chunks and only materializes compact
aggregates needed for plots, tables, and calibration reports.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

from mptdc_char_common import (
    DELTA_LSB_PS,
    LABELS_FR,
    add_error_columns,
    apply_char_style,
    discover_stage_csvs,
    numeric,
    save_char_figure,
    style_axes,
    write_markdown_table,
)


CHUNK_ROWS = 500_000
ABS_ERR_BINS_PS = np.arange(0.0, 5000.0 + DELTA_LSB_PS, DELTA_LSB_PS)
SIGNED_ERR_BINS_PS = np.arange(-5000.0, 5000.0 + DELTA_LSB_PS, DELTA_LSB_PS)
NE = 8
K_VERNIER = 11
K_SLOW = K_VERNIER * NE
K_FAST = NE
VERNIER_COEF_BIAS = 25
VERNIER_QUANT_PS = 10

# Match scripts/calibration/calibrate_6d_lut.py:
# discriminator-aware LUT = (ns_inf, nf_inf, nslow, nfast_hit,
# stop_phase_disc, phase0_snap, hit_idx).
CALIBRATION_LUT_KEY = [
    "ns_inf",
    "nf_inf",
    "nslow",
    "nfast_hit",
    "stop_phase_disc",
    "phase0_snap",
    "hit_idx",
]
NSNF_REV = {
    ns * K_VERNIER - nf * (K_VERNIER - 1): (ns, nf)
    for ns in range(NE)
    for nf in range(NE)
}


@dataclass
class MomentStats:
    n: int = 0
    sum_x: float = 0.0
    sum_x2: float = 0.0
    abs_hist: np.ndarray | None = None
    abs_under: int = 0
    abs_over: int = 0

    def add(self, values: pd.Series | np.ndarray) -> None:
        arr = pd.to_numeric(pd.Series(values), errors="coerce").dropna().to_numpy(dtype=float)
        if arr.size == 0:
            return
        self.n += int(arr.size)
        self.sum_x += float(arr.sum())
        self.sum_x2 += float(np.square(arr).sum())
        hist, _ = np.histogram(np.abs(arr), bins=ABS_ERR_BINS_PS)
        if self.abs_hist is None:
            self.abs_hist = hist.astype(np.int64)
        else:
            self.abs_hist += hist
        self.abs_over += int((np.abs(arr) >= ABS_ERR_BINS_PS[-1]).sum())

    def row(self, prefix: str) -> dict[str, float | int | str]:
        if self.n == 0:
            return {
                "metrique": prefix,
                "echantillons": 0,
                "moyenne_ps": np.nan,
                "rms_ps": np.nan,
                "p95_abs_ps": np.nan,
                "p99_abs_ps": np.nan,
                "hors_fenetre_abs": 0,
            }
        return {
            "metrique": prefix,
            "echantillons": self.n,
            "moyenne_ps": self.sum_x / self.n,
            "rms_ps": float(np.sqrt(self.sum_x2 / self.n)),
            "p95_abs_ps": hist_quantile(self.abs_hist, ABS_ERR_BINS_PS, 0.95),
            "p99_abs_ps": hist_quantile(self.abs_hist, ABS_ERR_BINS_PS, 0.99),
            "hors_fenetre_abs": self.abs_over,
        }


def hist_quantile(hist: np.ndarray | None, edges: np.ndarray, q: float) -> float:
    if hist is None or hist.sum() == 0:
        return float("nan")
    target = q * hist.sum()
    idx = int(np.searchsorted(np.cumsum(hist), target, side="left"))
    idx = min(max(idx, 0), len(edges) - 2)
    return float((edges[idx] + edges[idx + 1]) / 2.0)


def infer_ns_nf(df: pd.DataFrame) -> pd.DataFrame:
    """Recover (ns_inf, nf_inf) with the maintained 6D LUT algebra."""
    coef = (numeric(df, "t_raw_ps") // VERNIER_QUANT_PS).astype("Int64")
    resid = (
        coef
        - (numeric(df, "nslow").astype("Int64") + 2 + numeric(df, "slow_boundary_inc").astype("Int64") - 1) * K_SLOW
        - numeric(df, "nfast_hit").astype("Int64") * K_FAST
        - VERNIER_COEF_BIAS
    )
    mapped = resid.map(lambda r: NSNF_REV.get(int(r), (pd.NA, pd.NA)) if not pd.isna(r) else (pd.NA, pd.NA))
    df["ns_inf"] = mapped.map(lambda pair: pair[0]).astype("Int64")
    df["nf_inf"] = mapped.map(lambda pair: pair[1]).astype("Int64")
    return df


def prepare_calibration_hits(chunk: pd.DataFrame) -> pd.DataFrame:
    """Apply the same core filter and key inference as calibrate_6d_lut.py."""
    hits = chunk[numeric(chunk, "hit_idx").fillna(-1) >= 0].copy()
    if hits.empty:
        return hits
    hits = hits[numeric(hits, "nslow").fillna(0) > 0].copy()
    if hits.empty:
        return hits
    hits["offset"] = numeric(hits, "Tref_ps") - numeric(hits, "t_raw_ps")
    infer_ns_nf(hits)
    hits = hits.dropna(subset=CALIBRATION_LUT_KEY + ["offset"])
    for col in CALIBRATION_LUT_KEY:
        hits[col] = numeric(hits, col).astype(int)
    return hits


def save_table(
    df: pd.DataFrame,
    out_dir: Path,
    stem: str,
    title: str,
    *,
    max_markdown_rows: int = 2000,
) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    df.to_csv(out_dir / f"{stem}.csv", index=False)
    if len(df) <= max_markdown_rows:
        write_markdown_table(df, out_dir / f"{stem}.md", title)
    else:
        preview = df.head(max_markdown_rows).copy()
        md_path = out_dir / f"{stem}.md"
        write_markdown_table(preview, md_path, title)
        with md_path.open("a", encoding="utf-8") as handle:
            handle.write(
                f"\n_Table tronquee: {len(df)} lignes dans le CSV complet, "
                f"{max_markdown_rows} lignes affichees ici._\n"
            )


def stage_name_from_path(path: Path) -> str:
    try:
        return path.parent.name
    except IndexError:
        return "unknown"


def iter_chunks(paths: Iterable[Path], chunksize: int, usecols: list[str] | None = None):
    for path in paths:
        stage = stage_name_from_path(path)
        try:
            reader = pd.read_csv(path, chunksize=chunksize, usecols=usecols)
            for chunk in reader:
                chunk["stage"] = stage
                chunk["source_file"] = str(path)
                yield chunk
        except pd.errors.EmptyDataError:
            continue
        except ValueError:
            # If an older CSV lacks a requested optional column, fall back to all
            # columns for that file rather than failing the whole overnight run.
            for chunk in pd.read_csv(path, chunksize=chunksize):
                chunk["stage"] = stage
                chunk["source_file"] = str(path)
                yield chunk


class SummaryAccumulator:
    def __init__(self) -> None:
        self.rows: dict[tuple[str, str], dict[str, float | int | str]] = {}

    def add_chunk(self, chunk: pd.DataFrame) -> None:
        work = add_error_columns(chunk)
        if "config" not in work.columns:
            work["config"] = work.get("config_id", "0").astype(str)
        for (stage, config), grp in work.groupby(["stage", "config"], dropna=False):
            key = (str(stage), str(config))
            row = self.rows.setdefault(
                key,
                {
                    "etape": key[0],
                    "configuration": key[1],
                    "lignes": 0,
                    "hits": 0,
                    "acceptes": 0,
                    "rejetes": 0,
                    "_err_n": 0,
                    "_err_sum": 0.0,
                    "_err_sum2": 0.0,
                },
            )
            hit_mask = numeric(grp, "hit_idx").fillna(-1) >= 0
            err = pd.to_numeric(grp.loc[hit_mask, "error_ps"], errors="coerce").dropna()
            row["lignes"] = int(row["lignes"]) + len(grp)
            row["hits"] = int(row["hits"]) + int(hit_mask.sum())
            row["acceptes"] = int(row["acceptes"]) + int(numeric(grp, "accepted").fillna(0).sum())
            row["rejetes"] = int(row["rejetes"]) + int(numeric(grp, "rejected").fillna(0).sum())
            row["_err_n"] = int(row["_err_n"]) + len(err)
            row["_err_sum"] = float(row["_err_sum"]) + float(err.sum())
            row["_err_sum2"] = float(row["_err_sum2"]) + float(np.square(err.to_numpy()).sum())

    def dataframe(self) -> pd.DataFrame:
        out = []
        for row in self.rows.values():
            err_n = int(row.pop("_err_n"))
            err_sum = float(row.pop("_err_sum"))
            err_sum2 = float(row.pop("_err_sum2"))
            row["erreur_moy_ps"] = err_sum / err_n if err_n else np.nan
            row["erreur_rms_ps"] = float(np.sqrt(err_sum2 / err_n)) if err_n else np.nan
            out.append(row)
        return pd.DataFrame(out).sort_values(["etape", "configuration"])


def analyze_global_summary(paths: list[Path], chunksize: int, tables_dir: Path) -> None:
    acc = SummaryAccumulator()
    for chunk in iter_chunks(paths, chunksize):
        acc.add_chunk(chunk)
    save_table(acc.dataframe(), tables_dir, "resume_global", "Resume global de caracterisation")


def update_bincount(counts: np.ndarray, values: pd.Series) -> np.ndarray:
    clean = pd.to_numeric(values, errors="coerce").dropna().astype(int)
    clean = clean[clean >= 0]
    if clean.empty:
        return counts
    max_idx = int(clean.max())
    if max_idx >= len(counts):
        counts = np.pad(counts, (0, max_idx + 1 - len(counts)))
    counts[: max_idx + 1] += np.bincount(clean.to_numpy(), minlength=max_idx + 1)
    return counts


def plot_phase_occupancy_from_counts(phase_counts: np.ndarray, out_dir: Path) -> None:
    if phase_counts.sum() == 0:
        return
    fig, ax = plt.subplots(figsize=(6.5, 5.4))
    im = ax.imshow(phase_counts, origin="lower", aspect="auto", cmap="viridis")
    ax.set_xlabel(LABELS_FR["nf"])
    ax.set_ylabel(LABELS_FR["ns"])
    ax.set_title("Occupation des cellules de phase")
    ax.set_xticks(range(phase_counts.shape[1]))
    ax.set_yticks(range(phase_counts.shape[0]))
    fig.colorbar(im, ax=ax, label=LABELS_FR["count"])
    save_char_figure(fig, out_dir / "code_density_phase_occupancy")


def plot_dnl_inl_from_counts(counts_full: np.ndarray, out_dir: Path) -> pd.DataFrame:
    nz = np.flatnonzero(counts_full)
    if nz.size == 0:
        return pd.DataFrame()
    lo, hi = int(nz.min()), int(nz.max())
    counts = counts_full[lo : hi + 1]
    ideal = counts.sum() / len(counts)
    dnl = counts / ideal - 1.0
    inl = np.cumsum(dnl)
    sigma_dnl = np.sqrt(np.maximum(counts, 1)) / ideal
    code_index = np.arange(lo, hi + 1)

    fig, axes = plt.subplots(3, 1, figsize=(9, 8), sharex=True)
    axes[0].bar(code_index, counts, width=1.0, color="#1565c0")
    axes[0].set_ylabel(LABELS_FR["count"])
    axes[0].set_title("Histogramme code-density")
    axes[1].plot(code_index, dnl, color="#c62828", lw=1.0, label="DNL")
    axes[1].fill_between(
        code_index,
        dnl - 1.96 * sigma_dnl,
        dnl + 1.96 * sigma_dnl,
        color="#c62828",
        alpha=0.18,
        label="IC 95 % approx.",
    )
    axes[1].set_ylabel(LABELS_FR["dnl"])
    axes[1].legend()
    axes[2].plot(code_index, inl, color="#ef6c00", lw=1.0)
    axes[2].set_ylabel(LABELS_FR["inl"])
    axes[2].set_xlabel("Index de code")
    for ax in axes:
        style_axes(ax)
    save_char_figure(fig, out_dir / "code_density_dnl_inl")

    return pd.DataFrame(
        {
            "code_index": code_index,
            "count": counts,
            "dnl_lsb": dnl,
            "dnl_sigma_lsb": sigma_dnl,
            "inl_lsb": inl,
        }
    )


def analyze_code_density(
    paths: list[Path],
    plots_dir: Path,
    tables_dir: Path,
    chunksize: int,
    train_seeds: int,
) -> None:
    scalar_counts = np.zeros(1, dtype=np.int64)
    phase_counts = np.zeros((8, 8), dtype=np.int64)
    train_sum: dict[tuple[int, ...], float] = {}
    train_sumsq: dict[tuple[int, ...], float] = {}
    train_count: dict[tuple[int, ...], int] = {}

    usecols = [
        "seed",
        "hit_idx",
        "Tref_ps",
        "t_raw_ps",
        "scalar_bin",
        "ns",
        "nf",
        "nslow",
        "nfast_hit",
        "phase0_snap",
        "slow_boundary_inc",
    ]
    usecols = sorted(set(usecols))
    train_paths = paths[:train_seeds]
    val_paths = paths[train_seeds:]
    validation_mode = "held_out_seeds"
    if not val_paths:
        val_paths = paths
        validation_mode = "same_files_shape_check"

    for chunk in iter_chunks(paths, chunksize, usecols=usecols):
        hits = chunk[numeric(chunk, "hit_idx").fillna(-1) >= 0].copy()
        if hits.empty:
            continue
        scalar_counts = update_bincount(scalar_counts, hits["scalar_bin"])
        ns = numeric(hits, "ns").astype("Int64")
        nf = numeric(hits, "nf").astype("Int64")
        valid_phase = ns.notna() & nf.notna() & (ns >= 0) & (ns < 8) & (nf >= 0) & (nf < 8)
        for ns_i, nf_i in zip(ns[valid_phase].astype(int), nf[valid_phase].astype(int)):
            phase_counts[ns_i, nf_i] += 1

    for chunk in iter_chunks(train_paths, chunksize, usecols=usecols):
        train = prepare_calibration_hits(chunk)
        if train.empty:
            continue
        grouped = train.groupby(CALIBRATION_LUT_KEY)["offset"].agg(["count", "sum", lambda s: float(np.square(s.to_numpy()).sum())])
        grouped = grouped.rename(columns={"<lambda_0>": "sumsq"})
        for key, row in grouped.iterrows():
            key_tuple = tuple(int(k) for k in key)
            train_count[key_tuple] = train_count.get(key_tuple, 0) + int(row["count"])
            train_sum[key_tuple] = train_sum.get(key_tuple, 0.0) + float(row["sum"])
            train_sumsq[key_tuple] = train_sumsq.get(key_tuple, 0.0) + float(row["sumsq"])

    plot_phase_occupancy_from_counts(phase_counts, plots_dir)
    dnl_table = plot_dnl_inl_from_counts(scalar_counts, plots_dir)
    if not dnl_table.empty:
        save_table(dnl_table, tables_dir, "code_density_dnl_inl", "DNL et INL code-density")

    records = []
    lut: dict[tuple[int, ...], float] = {}
    for key, count in train_count.items():
        if count <= 0:
            continue
        correction = train_sum[key] / count
        variance = max(0.0, train_sumsq[key] / count - correction * correction)
        lut[key] = correction
        records.append((*key, correction, float(np.sqrt(variance)), count))
    lut_table = pd.DataFrame(records, columns=CALIBRATION_LUT_KEY + ["correction", "within_std", "train_count"])
    if not lut_table.empty:
        lut_table = lut_table.sort_values(CALIBRATION_LUT_KEY)
    save_table(lut_table, tables_dir, "lut_6d", "LUT 6D plus hit_idx")

    pre_stats = MomentStats()
    post_stats = MomentStats()
    signed_pre_hist = np.zeros(len(SIGNED_ERR_BINS_PS) - 1, dtype=np.int64)
    signed_post_hist = np.zeros(len(SIGNED_ERR_BINS_PS) - 1, dtype=np.int64)
    val_rows = 0
    calibrated_rows = 0
    missing_rows = 0
    inference_dropped_rows = 0

    for chunk in iter_chunks(val_paths, chunksize, usecols=usecols):
        val_input_rows = int((numeric(chunk, "hit_idx").fillna(-1) >= 0).sum())
        val = prepare_calibration_hits(chunk)
        inference_dropped_rows += max(val_input_rows - len(val), 0)
        if val.empty:
            continue
        val["pre_error_ps"] = val["offset"]
        val_rows += len(val)
        pre = val["pre_error_ps"].dropna()
        pre_stats.add(pre)
        hist_pre, _ = np.histogram(pre.to_numpy(dtype=float), bins=SIGNED_ERR_BINS_PS)
        signed_pre_hist += hist_pre

        keys = list(zip(*(val[col].astype(int).to_numpy() for col in CALIBRATION_LUT_KEY)))
        corr = pd.Series((lut.get(tuple(key), np.nan) for key in keys), index=val.index, dtype=float)
        has_corr = corr.notna()
        missing_rows += int((~has_corr).sum())
        calibrated_rows += int(has_corr.sum())
        post = (val.loc[has_corr, "pre_error_ps"].astype(float) - corr[has_corr].astype(float)).dropna()
        post_stats.add(post)
        hist_post, _ = np.histogram(post.to_numpy(dtype=float), bins=SIGNED_ERR_BINS_PS)
        signed_post_hist += hist_post

    stats_table = pd.DataFrame([pre_stats.row("avant_calibration"), post_stats.row("apres_calibration")])
    stats_table["methode_calibration"] = "6D_plus_hit_idx"
    stats_table["cle_calibration"] = ",".join(CALIBRATION_LUT_KEY)
    stats_table["train_fichiers"] = len(train_paths)
    stats_table["validation_fichiers"] = len(val_paths)
    stats_table["validation_mode"] = validation_mode
    stats_table["validation_lignes"] = val_rows
    stats_table["validation_calibrees"] = calibrated_rows
    stats_table["validation_sans_lut"] = missing_rows
    stats_table["validation_filtrees_ou_inference"] = inference_dropped_rows
    stats_table["train_lut_codes"] = len(lut)
    save_table(stats_table, tables_dir, "calibration_pre_post", "Calibration avant et apres")

    plot_calibration_hist(signed_pre_hist, signed_post_hist, plots_dir)


def plot_calibration_hist(pre_hist: np.ndarray, post_hist: np.ndarray, out_dir: Path) -> None:
    centers = (SIGNED_ERR_BINS_PS[:-1] + SIGNED_ERR_BINS_PS[1:]) / 2.0
    if pre_hist.sum() == 0 and post_hist.sum() == 0:
        return
    fig, ax = plt.subplots(figsize=(8.5, 4.8))
    if pre_hist.sum():
        ax.step(centers, pre_hist / pre_hist.sum(), where="mid", lw=1.3, label="Avant calibration")
    if post_hist.sum():
        ax.step(centers, post_hist / post_hist.sum(), where="mid", lw=1.3, label="Apres calibration")
    ax.set_xlabel("Erreur de temps (ps)")
    ax.set_ylabel("Frequence normalisee")
    ax.set_title("Distribution d'erreur avant/apres calibration")
    ax.legend()
    style_axes(ax)
    save_char_figure(fig, out_dir / "calibration_residual_hist")


def load_stage(paths: list[Path], chunksize: int, max_rows: int | None = None) -> pd.DataFrame:
    frames: list[pd.DataFrame] = []
    remaining = max_rows
    for chunk in iter_chunks(paths, chunksize):
        if remaining is not None:
            if remaining <= 0:
                break
            chunk = chunk.head(remaining)
            remaining -= len(chunk)
        frames.append(chunk)
    return pd.concat(frames, ignore_index=True) if frames else pd.DataFrame()


def plot_deadtime(df: pd.DataFrame, out_dir: Path) -> pd.DataFrame:
    work = df[df["pair_index"] == 1].copy() if "pair_index" in df.columns else df.copy()
    if work.empty:
        return pd.DataFrame()
    if "gap_req_ps" in work.columns:
        work["gap_ns"] = numeric(work, "gap_req_ps") / 1000.0
    else:
        work["gap_ns"] = numeric(work, "trial_id")
    work["accepted_num"] = numeric(work, "accepted").fillna(0)
    summary = (
        work.groupby("gap_ns", as_index=False)
        .agg(essais=("accepted_num", "size"), acceptes=("accepted_num", "sum"))
    )
    summary["probabilite_acceptation_pct"] = 100.0 * summary["acceptes"] / summary["essais"].clip(lower=1)
    fig, ax = plt.subplots(figsize=(8, 4.6))
    ax.plot(summary["gap_ns"], summary["probabilite_acceptation_pct"], marker="o", ms=3, lw=1.4, color="#1565c0")
    ax.set_xlabel(LABELS_FR["gap_ns"] if "gap_req_ps" in work.columns else "Index essai")
    ax.set_ylabel(LABELS_FR["prob_accept"])
    ax.set_title("Deadtime mesure: bras persistant")
    ax.set_ylim(-2, 102)
    style_axes(ax)
    save_char_figure(fig, out_dir / "deadtime_acceptance")
    return summary


def analyze_boundary(paths: list[Path], plots_dir: Path, tables_dir: Path, chunksize: int) -> None:
    groups: dict[float, dict[str, float | int]] = {}
    x_col = "boundary_offset_ps"
    first_cols: set[str] | None = None

    for chunk in iter_chunks(paths, chunksize):
        if first_cols is None:
            first_cols = set(chunk.columns)
            if "boundary_offset_ps" not in first_cols:
                x_col = "Tref_ps"
        work = add_error_columns(chunk[numeric(chunk, "hit_idx").fillna(-1) >= 0].copy())
        if work.empty:
            continue
        work[x_col] = numeric(work, x_col)
        work["error_ps"] = numeric(work, "error_ps")
        work = work.dropna(subset=[x_col, "error_ps"])
        grouped = work.groupby(x_col)["error_ps"].agg(["count", "sum", lambda s: float(np.square(s.to_numpy()).sum())])
        grouped = grouped.rename(columns={"<lambda_0>": "sum2"})
        for key, row in grouped.iterrows():
            g = groups.setdefault(float(key), {"hits": 0, "sum": 0.0, "sum2": 0.0})
            g["hits"] = int(g["hits"]) + int(row["count"])
            g["sum"] = float(g["sum"]) + float(row["sum"])
            g["sum2"] = float(g["sum2"]) + float(row["sum2"])

    if not groups:
        return
    rows = []
    for key in sorted(groups):
        g = groups[key]
        hits = int(g["hits"])
        rows.append(
            {
                x_col: key,
                "hits": hits,
                "erreur_moy_ps": float(g["sum"]) / hits,
                "erreur_rms_ps": float(np.sqrt(float(g["sum2"]) / hits)),
            }
        )
    summary = pd.DataFrame(rows)

    fig, ax = plt.subplots(figsize=(8, 4.6))
    ax.plot(summary[x_col], summary["erreur_rms_ps"], marker="o", ms=3, lw=1.4, color="#6a1b9a", label="RMS")
    ax.plot(summary[x_col], summary["erreur_moy_ps"], marker="s", ms=2.5, lw=1.0, color="#c62828", label="Moyenne")
    ax.set_xlabel("Offset de frontiere (ps)" if x_col == "boundary_offset_ps" else LABELS_FR["Tref_ps"])
    ax.set_ylabel(LABELS_FR["error_ps"])
    ax.set_title("Stress des frontieres de phase")
    ax.legend()
    style_axes(ax)
    save_char_figure(fig, plots_dir / "boundary_error_vs_offset")
    save_table(summary, tables_dir, "boundary_summary", "Resume stress frontieres")


def plot_context(df: pd.DataFrame, out_dir: Path) -> pd.DataFrame:
    work = df.copy()
    work["attempt"] = numeric(work, "attempt") if "attempt" in work.columns else numeric(work, "trial_id")
    work["ovf_after"] = numeric(work, "ovf_after") if "ovf_after" in work.columns else numeric(work, "rejected").fillna(0).cumsum()
    work["fifo_level"] = numeric(work, "fifo_level") if "fifo_level" in work.columns else 0
    work["fifo_full"] = numeric(work, "fifo_full") if "fifo_full" in work.columns else 0
    summary = work[["attempt", "ovf_after", "fifo_level", "fifo_full"]].drop_duplicates()
    fig, ax1 = plt.subplots(figsize=(8, 4.8))
    ax1.plot(summary["attempt"], summary["ovf_after"], color="#c62828", lw=1.4, label="Overflow cumule")
    ax1.set_xlabel("Tentative")
    ax1.set_ylabel("Overflow cumule")
    ax2 = ax1.twinx()
    ax2.plot(summary["attempt"], summary["fifo_level"], color="#1565c0", lw=1.1, label="Niveau FIFO")
    ax2.set_ylabel("Niveau FIFO (mots)")
    ax1.set_title("Pression contexte/FIFO")
    style_axes(ax1)
    save_char_figure(fig, out_dir / "context_overflow_fifo")
    return summary


def plot_throughput(df: pd.DataFrame, out_dir: Path) -> pd.DataFrame:
    work = df.copy()
    work["event_idx"] = np.arange(len(work))
    work["conv_after"] = numeric(work, "conv_after") if "conv_after" in work.columns else numeric(work, "accepted").fillna(0).cumsum()
    work["ovf_after"] = numeric(work, "ovf_after") if "ovf_after" in work.columns else numeric(work, "rejected").fillna(0).cumsum()
    work["packet_count"] = numeric(work, "packet_count") if "packet_count" in work.columns else work["conv_after"]
    work["fifo_level"] = numeric(work, "fifo_level") if "fifo_level" in work.columns else 0
    summary = work[["event_idx", "conv_after", "ovf_after", "packet_count", "fifo_level"]].copy()
    fig, ax = plt.subplots(figsize=(8.5, 4.8))
    ax.plot(summary["event_idx"], summary["conv_after"], lw=1.3, label="Conversions drainees")
    ax.plot(summary["event_idx"], summary["packet_count"], lw=1.1, label="Paquets sortis")
    ax.plot(summary["event_idx"], summary["ovf_after"], lw=1.1, label="Rejets cumules")
    ax.set_xlabel("Index evenement")
    ax.set_ylabel("Compte cumule")
    ax.set_title("Debit sous backpressure")
    ax.legend()
    style_axes(ax)
    save_char_figure(fig, out_dir / "throughput_counters")
    return summary


def main() -> None:
    parser = argparse.ArgumentParser(description="Analyze MPTDC characterization overnight results.")
    parser.add_argument("--root", required=True, help="Characterization output root.")
    parser.add_argument("--output-dir", default=None, help="Analysis output directory.")
    parser.add_argument("--max-rows", type=int, default=None, help="Optional row cap for small loaded stages.")
    parser.add_argument("--chunksize", type=int, default=CHUNK_ROWS, help="CSV chunk size.")
    parser.add_argument(
        "--train-seeds",
        type=int,
        default=12,
        help="Number of code-density seed files used to train the maintained 6D LUT.",
    )
    args = parser.parse_args()

    root = Path(args.root)
    out_dir = Path(args.output_dir) if args.output_dir else root / "analysis"
    plots_dir = out_dir / "plots"
    tables_dir = out_dir / "tables"
    plots_dir.mkdir(parents=True, exist_ok=True)
    tables_dir.mkdir(parents=True, exist_ok=True)
    apply_char_style()

    all_paths = discover_stage_csvs(root)
    if not all_paths:
        raise SystemExit(f"[ERROR] No CSV files found under {root}/stages")

    analyze_global_summary(all_paths, args.chunksize, tables_dir)

    code_paths = discover_stage_csvs(root, "code_density")
    if code_paths:
        analyze_code_density(code_paths, plots_dir, tables_dir, args.chunksize, args.train_seeds)

    boundary_paths = discover_stage_csvs(root, "boundary")
    if boundary_paths:
        analyze_boundary(boundary_paths, plots_dir, tables_dir, args.chunksize)

    for stage, plot_fn, stem, title in [
        ("deadtime", plot_deadtime, "deadtime_acceptance", "Deadtime persistant"),
        ("context_overflow", plot_context, "context_overflow", "Contexte et overflow"),
        ("throughput", plot_throughput, "throughput", "Debit et backpressure"),
    ]:
        paths = discover_stage_csvs(root, stage)
        if not paths:
            continue
        df = load_stage(paths, args.chunksize, args.max_rows)
        if df.empty:
            continue
        table = plot_fn(df, plots_dir)
        if not table.empty:
            save_table(table, tables_dir, stem, title)

    print(f"[ANALYZE] Wrote analysis to {out_dir}")


if __name__ == "__main__":
    main()
