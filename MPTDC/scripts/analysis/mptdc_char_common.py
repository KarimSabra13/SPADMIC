#!/usr/bin/env python3
"""Shared helpers for MPTDC characterization analysis."""

from __future__ import annotations

from pathlib import Path
from typing import Iterable

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

SCRIPT_ROOT = Path(__file__).resolve().parents[1]
import sys
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from plot_style import PALETTE, apply_report_style, save_figure, style_axes

NE = 8
K_VERNIER = 11
DELTA_STEP_PS = 5
DELTA_LSB_PS = 10
VERNIER_NSLOW_ORIGIN_BIAS = 2
VERNIER_NFAST_ORIGIN_BIAS = 1
VERNIER_COEF_BIAS = 25

FIG_EXTS = ("png", "pdf")

LABELS_FR = {
    "Tref_ps": "Temps vrai (ps)",
    "t_raw_ps": "Temps brut reconstruit (ps)",
    "error_ps": "Erreur (ps)",
    "delay_ns": "Delai injecte (ns)",
    "count": "Population (coups)",
    "prob_accept": "Probabilite d'acceptation (%)",
    "gap_ns": "Ecart STOP-START (ns)",
    "dnl": "DNL (LSB)",
    "inl": "INL (LSB)",
    "ns": "Phase lente ns",
    "nf": "Phase rapide nf",
    "ready_duty": "Rapport ready (%)",
    "throughput": "Debit (evenements/s)",
}


def apply_char_style() -> None:
    apply_report_style()
    plt.rcParams.update({
        "axes.titlesize": 12,
        "axes.labelsize": 11,
        "legend.fontsize": 8,
        "figure.figsize": (8, 4.8),
    })


def save_char_figure(fig, out_stem: Path) -> None:
    for ext in FIG_EXTS:
        save_figure(fig, out_stem.with_suffix(f".{ext}"))


def vernier_tconv_ps(nslow, nfast, ns, nf, slow_boundary_inc):
    coef = (
        (nslow + VERNIER_NSLOW_ORIGIN_BIAS + slow_boundary_inc - 1) * K_VERNIER * NE
        + (nfast + VERNIER_NFAST_ORIGIN_BIAS - 1) * NE
        + ns * K_VERNIER
        - nf * (K_VERNIER - 1)
        + VERNIER_COEF_BIAS
    )
    return coef * DELTA_LSB_PS


def discover_stage_csvs(root: Path, stage: str | None = None) -> list[Path]:
    base = root / "stages"
    if stage:
        return sorted((base / stage).glob("seed_*.csv"))
    return sorted(base.glob("*/seed_*.csv"))


def iter_csv_chunks(paths: Iterable[Path], chunksize: int = 500_000):
    for path in paths:
        try:
            for chunk in pd.read_csv(path, chunksize=chunksize):
                chunk["source_file"] = str(path)
                yield chunk
        except pd.errors.EmptyDataError:
            continue


def load_csvs(paths: Iterable[Path], *, max_rows: int | None = None) -> pd.DataFrame:
    frames: list[pd.DataFrame] = []
    remaining = max_rows
    for chunk in iter_csv_chunks(paths):
        if remaining is not None:
            if remaining <= 0:
                break
            chunk = chunk.head(remaining)
            remaining -= len(chunk)
        frames.append(chunk)
    if not frames:
        return pd.DataFrame()
    df = pd.concat(frames, ignore_index=True)
    if "stage" not in df.columns:
        extracted = df["source_file"].astype(str).str.extract(r"/stages/([^/]+)/")[0]
        df["stage"] = extracted.fillna(df.get("stage_id", "unknown").astype(str))
    if "config" not in df.columns:
        df["config"] = df.get("config_id", "0").astype(str)
    return df


def add_error_columns(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    if {"Tref_ps", "t_raw_ps"}.issubset(df.columns):
        df["error_ps"] = df["Tref_ps"] - df["t_raw_ps"]
    return df


def numeric(df: pd.DataFrame, column: str, default=np.nan):
    if column not in df.columns:
        return pd.Series(default, index=df.index)
    return pd.to_numeric(df[column], errors="coerce")


def write_markdown_table(df: pd.DataFrame, path: Path, title: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = [f"# {title}", ""]
    if df.empty:
        lines.append("_Aucune donnee._")
    else:
        cols = [str(col) for col in df.columns]
        lines.append("| " + " | ".join(cols) + " |")
        lines.append("| " + " | ".join("---" for _ in cols) + " |")
        for _, row in df.iterrows():
            values = [str(row[col]) for col in df.columns]
            lines.append("| " + " | ".join(values) + " |")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def basic_summary(df: pd.DataFrame) -> pd.DataFrame:
    if df.empty:
        return pd.DataFrame()
    work = add_error_columns(df)
    grouped = work.groupby(["stage", "config"], dropna=False)
    rows = []
    for (stage, config), grp in grouped:
        hit_rows = grp[grp["hit_idx"] >= 0] if "hit_idx" in grp else grp
        err = pd.to_numeric(hit_rows.get("error_ps", pd.Series(dtype=float)), errors="coerce").dropna()
        accepted = pd.to_numeric(grp.get("accepted", pd.Series(dtype=float)), errors="coerce").fillna(0)
        rejected = pd.to_numeric(grp.get("rejected", pd.Series(dtype=float)), errors="coerce").fillna(0)
        rows.append({
            "etape": stage,
            "configuration": config,
            "lignes": int(len(grp)),
            "hits": int(len(hit_rows)),
            "acceptes": int(accepted.sum()),
            "rejetes": int(rejected.sum()),
            "erreur_moy_ps": float(err.mean()) if len(err) else np.nan,
            "erreur_rms_ps": float(np.sqrt(np.mean(err.to_numpy() ** 2))) if len(err) else np.nan,
            "erreur_p99_abs_ps": float(np.percentile(np.abs(err), 99)) if len(err) else np.nan,
        })
    return pd.DataFrame(rows)
