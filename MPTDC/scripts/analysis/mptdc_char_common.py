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
TOOLS_ROOT = SCRIPT_ROOT.parents[1] / "tools"
if str(TOOLS_ROOT) not in sys.path:
    sys.path.insert(0, str(TOOLS_ROOT))

from plot_style import PALETTE, apply_report_style, save_figure, style_axes
from mptdc_decode.fast_tag_decode import (
    LEGACY_BINARY_NFAST,
    RAW_GALOIS_TAG,
    RAW_LFSR_TAG,
    FastTagMetadata,
    build_tag_to_index_table,
)

NE = 8
FREQ_MODE_NOMINAL = "nominal"
FREQ_MODE_R750_DELTA5 = "r750_delta5"
FREQ_MODE_CHOICES = (FREQ_MODE_NOMINAL, FREQ_MODE_R750_DELTA5)

FREQ_MODE_TABLE = {
    FREQ_MODE_NOMINAL: {
        "osc_ts_slow_ps": 55,
        "osc_ts_fast_ps": 50,
        "slow_period_ns": 1.000,
        "fast_period_ns": 0.900,
        "status": "current_nominal",
    },
    FREQ_MODE_R750_DELTA5: {
        "osc_ts_slow_ps": 79,
        "osc_ts_fast_ps": 74,
        "slow_period_ns": 1.430,
        "fast_period_ns": 1.333,
        "status": "typical_characterization_candidate_not_signoff",
    },
}

FREQ_MODE = FREQ_MODE_NOMINAL
OSC_TS_SLOW_PS = 55
OSC_TS_FAST_PS = 50
DELTA_STEP_PS = 5
DELTA_LSB_PS = 10
K_VERNIER = 11
VERNIER_NSLOW_ORIGIN_BIAS = 2
VERNIER_NFAST_ORIGIN_BIAS = 1
VERNIER_COEF_BIAS = 25
NFAST_ENCODING_LEGACY = LEGACY_BINARY_NFAST
NFAST_ENCODING_RAW_LFSR_TAG = RAW_LFSR_TAG
NFAST_ENCODING_RAW_GALOIS_TAG = RAW_GALOIS_TAG
NFAST_ENCODING_CHOICES = (
    NFAST_ENCODING_LEGACY,
    NFAST_ENCODING_RAW_LFSR_TAG,
    NFAST_ENCODING_RAW_GALOIS_TAG,
)

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


def resolve_frequency_mode(mode: str = FREQ_MODE_NOMINAL) -> dict[str, object]:
    if mode not in FREQ_MODE_TABLE:
        raise ValueError(f"Unsupported frequency mode: {mode}")
    cfg = dict(FREQ_MODE_TABLE[mode])
    slow_ps = int(cfg["osc_ts_slow_ps"])
    fast_ps = int(cfg["osc_ts_fast_ps"])
    delta_step_ps = slow_ps - fast_ps
    if delta_step_ps <= 0:
        raise ValueError(
            f"Frequency mode {mode} has non-positive Vernier delta: "
            f"slow={slow_ps} fast={fast_ps}"
        )
    cfg.update({
        "freq_mode": mode,
        "OSC_TS_SLOW_PS": slow_ps,
        "OSC_TS_FAST_PS": fast_ps,
        "DELTA_STEP": delta_step_ps,
        "DELTA_LSB": 2 * delta_step_ps,
        "K_VERNIER": slow_ps // delta_step_ps,
    })
    return cfg


def configure_frequency_mode(mode: str = FREQ_MODE_NOMINAL) -> dict[str, object]:
    global FREQ_MODE, OSC_TS_SLOW_PS, OSC_TS_FAST_PS
    global DELTA_STEP_PS, DELTA_LSB_PS, K_VERNIER

    cfg = resolve_frequency_mode(mode)
    FREQ_MODE = mode
    OSC_TS_SLOW_PS = int(cfg["OSC_TS_SLOW_PS"])
    OSC_TS_FAST_PS = int(cfg["OSC_TS_FAST_PS"])
    DELTA_STEP_PS = int(cfg["DELTA_STEP"])
    DELTA_LSB_PS = int(cfg["DELTA_LSB"])
    K_VERNIER = int(cfg["K_VERNIER"])
    return cfg


def frequency_mode_metadata(mode: str | None = None) -> dict[str, object]:
    return resolve_frequency_mode(FREQ_MODE if mode is None else mode)


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


def add_o2_raw_tag_decode_columns(
    df: pd.DataFrame,
    *,
    nfast_encoding: str = LEGACY_BINARY_NFAST,
    column_offsets: dict[int, int] | list[int] | None = None,
    detection_offset: int = 0,
) -> pd.DataFrame:
    """Annotate characterization rows with O2 raw-tag decode metadata.

    In `legacy_binary_nfast` mode this preserves old datasets by copying
    `nfast_hit` to `nfast_decoded`.  In `raw_lfsr_tag` mode the existing
    `nfast_hit` column is treated as a raw LFSR tag and decoded in software.
    """
    out = df.copy()
    meta = FastTagMetadata(nfast_encoding=nfast_encoding)
    for key, value in meta.as_dict().items():
        out[key] = value

    if "nfast_hit" not in out.columns or "nf" not in out.columns:
        return out

    nfast = pd.to_numeric(out["nfast_hit"], errors="coerce").astype("Int64")
    nf = pd.to_numeric(out["nf"], errors="coerce").astype("Int64")
    if nfast_encoding in (RAW_LFSR_TAG, RAW_GALOIS_TAG):
        table = build_tag_to_index_table(mode=nfast_encoding)
        decoded = nfast.map(table).astype("Int64")
        out["nfast_raw_tag"] = nfast
    elif nfast_encoding == LEGACY_BINARY_NFAST:
        decoded = nfast
        out["nfast_raw_tag"] = pd.Series(np.nan, index=out.index)
    else:
        raise ValueError(f"Unsupported nfast encoding mode: {nfast_encoding}")

    if column_offsets is not None:
        if isinstance(column_offsets, dict):
            offset_map = {int(k): int(v) for k, v in column_offsets.items()}
        else:
            offset_map = {idx: int(value) for idx, value in enumerate(column_offsets)}
        decoded = decoded + nf.map(offset_map).fillna(0).astype("Int64")
    if detection_offset:
        decoded = decoded + int(detection_offset)
    out["nfast_decoded"] = decoded

    required = {"nslow", "ns", "nf", "slow_boundary_inc"}
    if required.issubset(out.columns):
        coef = (
            (pd.to_numeric(out["nslow"], errors="coerce")
             + VERNIER_NSLOW_ORIGIN_BIAS
             + pd.to_numeric(out["slow_boundary_inc"], errors="coerce")
             - 1) * K_VERNIER * NE
            + (pd.to_numeric(out["nfast_decoded"], errors="coerce")
               + VERNIER_NFAST_ORIGIN_BIAS
               - 1) * NE
            + pd.to_numeric(out["ns"], errors="coerce") * K_VERNIER
            - pd.to_numeric(out["nf"], errors="coerce") * (K_VERNIER - 1)
            + VERNIER_COEF_BIAS
        )
        out["t_raw_ps_decoded_nfast"] = coef * DELTA_LSB_PS
    return out


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
