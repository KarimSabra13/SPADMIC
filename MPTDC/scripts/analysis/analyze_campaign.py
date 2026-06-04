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
import math
import os
import resource
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
from analysis import mptdc_char_common as char_common
from analysis.mptdc_char_common import (
    FREQ_MODE_CHOICES,
    FREQ_MODE_NOMINAL,
    NFAST_ENCODING_CHOICES,
    NFAST_ENCODING_LEGACY,
    add_o2_raw_tag_decode_columns,
    frequency_mode_metadata,
)

# ---------------------------------------------------------------------------
# Vernier reconstruction constants & function
# ---------------------------------------------------------------------------
NE = char_common.NE
K_VERNIER = char_common.K_VERNIER
DELTA_LSB = char_common.DELTA_LSB_PS
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

STREAM_DEFAULT_CHUNKSIZE = 200_000
STREAM_ABS_ERR_HIST_BINS = np.linspace(0.0, 200_000.0, 2001)
STREAM_TRAW_BINS_PS = np.arange(0.0, 200_000.0 + DELTA_LSB, DELTA_LSB)
STREAM_USECOLS = [
    "conv_id",
    "hit_idx",
    "Tref_ps",
    "nslow",
    "nfast_hit",
    "ns",
    "nf",
    "stop_phase_disc",
    "phase0_snap",
    "slow_boundary_inc",
    "hit_count",
    "flags",
    "ctx_id",
    "t_raw_ps",
    "tuple_code",
]
STREAM_DTYPE_MAP = {
    "conv_id": "int32",
    "hit_idx": "int16",
    "Tref_ps": "float32",
    "nslow": "int16",
    "nfast_hit": "int16",
    "ns": "int8",
    "nf": "int8",
    "stop_phase_disc": "int8",
    "phase0_snap": "int8",
    "slow_boundary_inc": "int8",
    "hit_count": "int8",
    "flags": "int16",
    "ctx_id": "int8",
    "t_raw_ps": "float32",
    "tuple_code": "int32",
}


def set_frequency_mode(mode: str) -> dict[str, object]:
    global K_VERNIER, DELTA_LSB, STREAM_TRAW_BINS_PS

    cfg = char_common.configure_frequency_mode(mode)
    K_VERNIER = int(cfg["K_VERNIER"])
    DELTA_LSB = int(cfg["DELTA_LSB"])
    STREAM_TRAW_BINS_PS = np.arange(0.0, 200_000.0 + DELTA_LSB, DELTA_LSB)
    return cfg

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


def log_memory(label: str, sink: list[str] | None = None) -> None:
    """Log process RSS without requiring psutil."""
    rss_gib = None
    try:
        import psutil  # type: ignore
        rss_gib = psutil.Process(os.getpid()).memory_info().rss / 1024**3
    except Exception:
        usage = resource.getrusage(resource.RUSAGE_SELF)
        # Linux ru_maxrss is KiB; macOS is bytes. This flow runs on Linux.
        rss_gib = usage.ru_maxrss / 1024**2
    line = f"[MEM] {label}: RSS={rss_gib:.2f} GiB"
    print(line, flush=True)
    if sink is not None:
        sink.append(line)


def _read_csv_header(path: Path) -> list[str]:
    try:
        return list(pd.read_csv(path, nrows=0).columns)
    except Exception:
        return []


def iter_campaign_chunks(
    configs: dict[str, list[Path]],
    *,
    chunksize: int,
    max_rows_per_file: int | None,
    log_memory_enabled: bool,
    memory_log: list[str],
):
    """Yield one campaign chunk at a time with usecols/dtype pruning.

    This function is deliberately sequential. The memory-safe parallel strategy
    is to run a small number of independent script invocations, not to fork a
    large in-memory campaign object.
    """
    chunk_count = 0
    for config, paths in sorted(configs.items()):
        for path in paths:
            header = _read_csv_header(path)
            if not header:
                print(f"  [WARN] Could not read CSV header: {path}")
                continue

            usecols = [col for col in STREAM_USECOLS if col in header]
            dtype_map = {col: STREAM_DTYPE_MAP[col] for col in usecols if col in STREAM_DTYPE_MAP}
            if "slow_boundary_inc" not in usecols:
                usecols.append("slow_boundary_inc")
                dtype_map["slow_boundary_inc"] = "int8"

            remaining = max_rows_per_file
            try:
                reader = pd.read_csv(
                    path,
                    usecols=[col for col in usecols if col in header],
                    dtype={col: dtype for col, dtype in dtype_map.items() if col in header},
                    chunksize=chunksize,
                )
                for chunk in reader:
                    if remaining is not None:
                        if remaining <= 0:
                            break
                        chunk = chunk.head(remaining)
                        remaining -= len(chunk)
                    if chunk.empty:
                        continue
                    if "slow_boundary_inc" not in chunk.columns:
                        chunk["slow_boundary_inc"] = np.int8(0)
                    chunk["source_file"] = str(path)
                    chunk_count += 1
                    if log_memory_enabled and (chunk_count == 1 or chunk_count % 20 == 0):
                        log_memory(f"after chunk {chunk_count}", memory_log)
                    yield config, path, chunk
            except pd.errors.EmptyDataError:
                continue
            except Exception as exc:
                print(f"  [WARN] Could not stream {path}: {exc}")


class OnlineStats:
    """Chunk-safe scalar error accumulator."""

    def __init__(self) -> None:
        self.count = 0
        self.sum = 0.0
        self.sumsq = 0.0
        self.abs_sum = 0.0
        self.min = math.inf
        self.max = -math.inf
        self.abs_hist = np.zeros(len(STREAM_ABS_ERR_HIST_BINS) - 1, dtype=np.int64)

    def update(self, values) -> None:
        if isinstance(values, np.ndarray):
            arr = values.astype(np.float64, copy=False)
        else:
            arr = pd.to_numeric(values, errors="coerce").to_numpy(dtype=np.float64, copy=False)
        arr = arr[np.isfinite(arr)]
        if arr.size == 0:
            return
        abs_arr = np.abs(arr)
        self.count += int(arr.size)
        self.sum += float(arr.sum())
        self.sumsq += float(np.square(arr).sum())
        self.abs_sum += float(abs_arr.sum())
        self.min = min(self.min, float(arr.min()))
        self.max = max(self.max, float(arr.max()))
        hist, _ = np.histogram(abs_arr, bins=STREAM_ABS_ERR_HIST_BINS)
        self.abs_hist += hist.astype(np.int64)

    def _hist_percentile(self, pct: float) -> float:
        if self.count == 0:
            return float("nan")
        cdf = np.cumsum(self.abs_hist)
        if cdf[-1] == 0:
            return float("nan")
        target = pct / 100.0 * cdf[-1]
        idx = int(np.searchsorted(cdf, target, side="left"))
        idx = min(idx, len(STREAM_ABS_ERR_HIST_BINS) - 2)
        return float(STREAM_ABS_ERR_HIST_BINS[idx + 1])

    def to_dict(self) -> dict:
        if self.count == 0:
            return basic_stats(pd.Series(dtype=float))
        mean = self.sum / self.count
        var = max(0.0, (self.sumsq - self.sum * self.sum / self.count) / max(1, self.count - 1))
        return {
            "count": int(self.count),
            "mean": float(mean),
            "std": float(math.sqrt(var)),
            "min": float(self.min),
            "max": float(self.max),
            "median": float("nan"),
            "rmse": float(math.sqrt(self.sumsq / self.count)),
            "mae": float(self.abs_sum / self.count),
            "p90_ae": self._hist_percentile(90.0),
            "p99_ae": self._hist_percentile(99.0),
        }


def _stats_frame_from_dict(stats_by_key: dict, key_cols: list[str]) -> pd.DataFrame:
    records = []
    for key, acc in sorted(stats_by_key.items()):
        key_tuple = key if isinstance(key, tuple) else (key,)
        row = {col: value for col, value in zip(key_cols, key_tuple)}
        row.update(acc.to_dict())
        records.append(row)
    return pd.DataFrame.from_records(records)


def _profile_frame_from_bins(stats_by_idx: dict[int, OnlineStats], edges: np.ndarray) -> pd.DataFrame:
    records = []
    for idx, acc in sorted(stats_by_idx.items()):
        if idx < 0 or idx >= len(edges) - 1:
            continue
        row = {
            "x_lo": float(edges[idx]),
            "x_hi": float(edges[idx + 1]),
            "x_mid": float((edges[idx] + edges[idx + 1]) / 2.0),
        }
        row.update(acc.to_dict())
        records.append(row)
    return pd.DataFrame.from_records(records)


def _update_discrete(stats_by_key: dict, df: pd.DataFrame, x_col: str, err_col: str = "offset_ps") -> None:
    if x_col not in df.columns or err_col not in df.columns:
        return
    for key, grp in df[[x_col, err_col]].dropna().groupby(x_col, observed=True):
        stats_by_key.setdefault(int(key), OnlineStats()).update(grp[err_col])


def _update_grouped(stats_by_key: dict, df: pd.DataFrame, key_cols: list[str],
                    err_col: str = "offset_ps") -> None:
    if not set(key_cols + [err_col]).issubset(df.columns):
        return
    for key, grp in df[key_cols + [err_col]].dropna().groupby(key_cols, observed=True):
        stats_by_key.setdefault(key, OnlineStats()).update(grp[err_col])


def _update_binned(stats_by_idx: dict[int, OnlineStats], x_values, err_values, edges: np.ndarray) -> None:
    x = pd.to_numeric(x_values, errors="coerce").to_numpy(dtype=np.float64, copy=False)
    err = pd.to_numeric(err_values, errors="coerce").to_numpy(dtype=np.float64, copy=False)
    mask = np.isfinite(x) & np.isfinite(err)
    if not np.any(mask):
        return
    idxs = np.searchsorted(edges, x[mask], side="right") - 1
    valid = (idxs >= 0) & (idxs < len(edges) - 1)
    idxs = idxs[valid]
    err = err[mask][valid]
    for idx in np.unique(idxs):
        stats_by_idx.setdefault(int(idx), OnlineStats()).update(err[idxs == idx])


def _decode_nfast_chunk(df: pd.DataFrame, nfast_encoding: str) -> tuple[pd.DataFrame, int]:
    """Decode raw tag encodings chunk-wise without row iterrows."""
    out = df.copy()
    if "nfast_hit" not in out.columns:
        return out, 0
    if nfast_encoding == NFAST_ENCODING_LEGACY:
        out["nfast_decoded"] = pd.to_numeric(out["nfast_hit"], errors="coerce").astype("Int16")
        return out, 0

    from mptdc_decode.fast_tag_decode import build_tag_to_index_table

    tag_table = build_tag_to_index_table(width=7, seed=1, mode=nfast_encoding)
    raw = pd.to_numeric(out["nfast_hit"], errors="coerce").astype("Int16")
    decoded = raw.map(tag_table)
    invalid = int(decoded.isna().sum())
    out["nfast_raw_tag"] = raw
    out["nfast_decoded"] = decoded.astype("Int16")
    out["nfast_hit_packet_raw_tag"] = raw
    # Existing analysis equations operate on decoded binary-like fast cycle.
    out = out.dropna(subset=["nfast_decoded"]).copy()
    out["nfast_hit"] = out["nfast_decoded"].astype("int16")
    return out, invalid


def _reconstruct_t_raw_chunk(df: pd.DataFrame) -> pd.DataFrame:
    required = {"nslow", "nfast_hit", "ns", "nf", "slow_boundary_inc"}
    if not required.issubset(df.columns):
        return df
    coef = (
        (pd.to_numeric(df["nslow"], errors="coerce") + VERNIER_NSLOW_ORIGIN_BIAS
         + pd.to_numeric(df["slow_boundary_inc"], errors="coerce") - 1) * K_VERNIER * NE
        + (pd.to_numeric(df["nfast_hit"], errors="coerce") + VERNIER_NFAST_ORIGIN_BIAS - 1) * NE
        + pd.to_numeric(df["ns"], errors="coerce") * K_VERNIER
        - pd.to_numeric(df["nf"], errors="coerce") * (K_VERNIER - 1)
        + VERNIER_COEF_BIAS
    )
    if "t_raw_ps" in df.columns:
        df["t_raw_ps_packet"] = df["t_raw_ps"]
    df["t_raw_ps"] = coef.astype(np.float64) * DELTA_LSB
    return df


def analyze_campaign_streaming(configs: dict[str, list[Path]], args, out_dir: Path) -> tuple[dict, dict]:
    """Memory-safe campaign analysis using one CSV chunk at a time."""
    memory_log: list[str] = []
    if args.log_memory:
        log_memory("streaming start", memory_log)

    print(f"[ANALYSIS] backend=streaming")
    print(f"[ANALYSIS] analysis_jobs={args.analysis_jobs} (streaming backend uses bounded sequential aggregation)")
    print(f"[ANALYSIS] chunksize={args.analysis_chunksize}")
    print(f"[ANALYSIS] usecols={','.join(STREAM_USECOLS)}")
    print(f"[ANALYSIS] dtype_map={json.dumps(STREAM_DTYPE_MAP, sort_keys=True)}")

    states: dict[str, dict] = {}
    for cfg in configs:
        states[cfg] = {
            "offset": OnlineStats(),
            "delay_bins": {},
            "traw_bins": {},
            "delay_regions": {label: OnlineStats() for label, _, _ in DELAY_REGION_BANDS_PS},
            "nslow": {},
            "nfast": {},
            "hit_idx": {},
            "stop_disc": {},
            "boundary": {},
            "phase": {},
            "flags": {name: 0 for name in FLAG_NAMES.values()},
            "raw_tuple_counts": {},
            "traw_hist": np.zeros(len(STREAM_TRAW_BINS_PS) - 1, dtype=np.int64),
            "rows": 0,
            "invalid_raw_tags": 0,
            "mismatches": -1,
        }

    delay_edges = np.linspace(20.0, 30_000.0, PROFILE_DELAY_BINS + 1)
    for cfg, path, chunk in iter_campaign_chunks(
        configs,
        chunksize=args.analysis_chunksize,
        max_rows_per_file=args.max_rows_per_file,
        log_memory_enabled=args.log_memory,
        memory_log=memory_log,
    ):
        state = states[cfg]
        chunk, invalid = _decode_nfast_chunk(chunk, args.nfast_encoding)
        state["invalid_raw_tags"] += invalid
        if chunk.empty:
            continue
        chunk = _reconstruct_t_raw_chunk(chunk)
        if {"Tref_ps", "t_raw_ps"}.issubset(chunk.columns):
            chunk["offset_ps"] = pd.to_numeric(chunk["Tref_ps"], errors="coerce") - pd.to_numeric(chunk["t_raw_ps"], errors="coerce")
        else:
            continue

        state["rows"] += int(len(chunk))
        state["offset"].update(chunk["offset_ps"])
        _update_binned(state["delay_bins"], chunk["Tref_ps"], chunk["offset_ps"], delay_edges)
        _update_binned(state["traw_bins"], chunk["t_raw_ps"], chunk["offset_ps"], STREAM_TRAW_BINS_PS)
        _update_discrete(state["nslow"], chunk, "nslow")
        _update_discrete(state["nfast"], chunk, "nfast_hit")
        _update_discrete(state["hit_idx"], chunk, "hit_idx")
        _update_discrete(state["stop_disc"], chunk, "stop_phase_disc")
        _update_grouped(state["boundary"], chunk, ["phase0_snap", "slow_boundary_inc"])
        _update_grouped(state["phase"], chunk, ["ns", "nf"])

        for label, lo_ps, hi_ps in DELAY_REGION_BANDS_PS:
            mask = (chunk["Tref_ps"] >= lo_ps) & (chunk["Tref_ps"] < hi_ps)
            state["delay_regions"][label].update(chunk.loc[mask, "offset_ps"])

        if "flags" in chunk.columns:
            flags_arr = pd.to_numeric(chunk["flags"], errors="coerce").fillna(0).to_numpy(dtype=np.int64)
            for bit, name in FLAG_NAMES.items():
                state["flags"][name] += int(((flags_arr >> bit) & 1).sum())

        if "tuple_code" in chunk.columns:
            tuple_counts = chunk["tuple_code"].value_counts(dropna=True)
            for key, value in tuple_counts.items():
                if int(key) < 0:
                    continue
                state["raw_tuple_counts"][int(key)] = state["raw_tuple_counts"].get(int(key), 0) + int(value)

        hist, _ = np.histogram(pd.to_numeric(chunk["t_raw_ps"], errors="coerce").dropna(), bins=STREAM_TRAW_BINS_PS)
        state["traw_hist"] += hist.astype(np.int64)

    all_results: dict[str, dict] = {}
    ttest_all: dict[str, list] = {}
    summary_rows = []
    for cfg, state in sorted(states.items()):
        safe_cfg = _safe_config(cfg)
        result: dict = {
            "nfast_encoding": args.nfast_encoding,
            "offset_stats": state["offset"].to_dict(),
            "mismatches": int(state["mismatches"]),
            "flag_dist": state["flags"],
            "streaming": True,
            "invalid_raw_tags": int(state["invalid_raw_tags"]),
        }

        delay_profile = _profile_frame_from_bins(state["delay_bins"], delay_edges)
        traw_profile = _profile_frame_from_bins(state["traw_bins"], STREAM_TRAW_BINS_PS)
        nslow_profile = _stats_frame_from_dict(state["nslow"], ["x"])
        nfast_profile = _stats_frame_from_dict(state["nfast"], ["x"])
        hit_idx_profile = _stats_frame_from_dict(state["hit_idx"], ["x"])
        stop_disc_profile = _stats_frame_from_dict(state["stop_disc"], ["x"])
        boundary_df = _stats_frame_from_dict(state["boundary"], ["phase0_snap", "slow_boundary_inc"])
        phase_df = _stats_frame_from_dict(state["phase"], ["ns", "nf"])
        regions = []
        for label, lo_ps, hi_ps in DELAY_REGION_BANDS_PS:
            row = {"label": label, "lo_ps": lo_ps, "hi_ps": hi_ps}
            row.update(state["delay_regions"][label].to_dict())
            regions.append(row)
        delay_regions = pd.DataFrame.from_records(regions)

        result["delay_profile"] = delay_profile
        result["nslow_profile"] = nslow_profile
        result["nfast_profile"] = nfast_profile
        result["hit_idx_profile"] = hit_idx_profile
        result["stop_disc_profile"] = stop_disc_profile
        result["traw_profile"] = traw_profile
        result["delay_regions"] = delay_regions
        result["boundary_classes"] = {}
        for _, row in boundary_df.iterrows():
            key = (int(row["phase0_snap"]), int(row["slow_boundary_inc"]))
            result["boundary_classes"][key] = {k: row[k] for k in row.index if k not in {"phase0_snap", "slow_boundary_inc"}}

        tuple_counts = state["raw_tuple_counts"]
        if tuple_counts:
            hist = pd.DataFrame({
                "tuple_code": list(tuple_counts.keys()),
                "count": list(tuple_counts.values()),
            }).sort_values("tuple_code", ignore_index=True)
            ideal = float(hist["count"].mean())
            hist["raw_tuple_dnl_est"] = hist["count"] / ideal - 1.0
            hist["raw_tuple_inl_est"] = hist["raw_tuple_dnl_est"].cumsum()
            hist.to_csv(out_dir / f"raw_tuple_histogram_{safe_cfg}.csv", index=False)
            result["raw_tuple_histogram_summary"] = {
                "occupied_bins": int(len(hist)),
                "total_samples": int(hist["count"].sum()),
                "min_count": int(hist["count"].min()),
                "median_count": float(hist["count"].median()),
                "max_count": int(hist["count"].max()),
                "peak_dnl_est": float(hist["raw_tuple_dnl_est"].abs().max()),
                "peak_inl_est": float(hist["raw_tuple_inl_est"].abs().max()),
            }
        else:
            result["raw_tuple_histogram_summary"] = {}

        counts = state["traw_hist"]
        occupied = counts[counts > 0]
        if occupied.size:
            ideal = float(occupied.mean())
            dnl = occupied / ideal - 1.0
            inl = np.cumsum(dnl)
            result["peak_dnl"] = float(np.max(np.abs(dnl)))
            result["peak_inl"] = float(np.max(np.abs(inl)))
        else:
            result["peak_dnl"] = float("nan")
            result["peak_inl"] = float("nan")

        if not delay_profile.empty:
            delay_profile.to_csv(out_dir / f"delay_profile_{safe_cfg}.csv", index=False)
        if not nslow_profile.empty:
            nslow_profile.to_csv(out_dir / f"nslow_profile_{safe_cfg}.csv", index=False)
        if not nfast_profile.empty:
            nfast_profile.to_csv(out_dir / f"nfast_hit_profile_{safe_cfg}.csv", index=False)
        if not hit_idx_profile.empty:
            hit_idx_profile.to_csv(out_dir / f"hit_idx_profile_{safe_cfg}.csv", index=False)
        if not stop_disc_profile.empty:
            stop_disc_profile.to_csv(out_dir / f"stop_phase_disc_profile_{safe_cfg}.csv", index=False)
        if not traw_profile.empty:
            traw_profile.to_csv(out_dir / f"t_raw_profile_{safe_cfg}.csv", index=False)
        if not delay_regions.empty:
            delay_regions.to_csv(out_dir / f"delay_regions_{safe_cfg}.csv", index=False)
        if not phase_df.empty:
            count_piv = phase_df.pivot_table(values="count", index="ns", columns="nf", aggfunc="sum")
            count_piv.to_csv(out_dir / f"phase_count_heatmap_{safe_cfg}.csv")

        if not args.no_plots:
            try:
                plot_binned_profile(delay_profile, cfg, out_dir, "delay_error_profile",
                                    title="Error profile vs Tref",
                                    x_label="True delay (ns)", x_scale=1000.0)
                plot_discrete_profile(nslow_profile, cfg, out_dir, "nslow_error_profile",
                                      title="Error profile vs nslow", x_label="nslow")
                plot_discrete_profile(nfast_profile, cfg, out_dir, "nfast_hit_error_profile",
                                      title="Error profile vs nfast_hit", x_label="nfast_hit")
                plot_discrete_profile(hit_idx_profile, cfg, out_dir, "hit_idx_error_profile",
                                      title="Error profile vs hit_idx", x_label="hit_idx")
                plot_binned_profile(traw_profile, cfg, out_dir, "t_raw_error_profile",
                                    title="Error profile vs t_raw",
                                    x_label="t_raw (ns)", x_scale=1000.0)
            except Exception as exc:
                print(f"  [WARN] Streaming plot generation error for {cfg}: {exc}")

        all_results[cfg] = result
        ttest_all[cfg] = []
        row = {"config": cfg, "rows": int(state["rows"]), "invalid_raw_tags": int(state["invalid_raw_tags"])}
        row.update(result["offset_stats"])
        summary_rows.append(row)

    pd.DataFrame.from_records(summary_rows).to_csv(out_dir / "chunked_metrics_summary.csv", index=False)
    streaming_config = {
        "backend": "streaming",
        "analysis_jobs": args.analysis_jobs,
        "chunksize": args.analysis_chunksize,
        "max_files": args.max_files,
        "max_rows_per_file": args.max_rows_per_file,
        "nfast_encoding": args.nfast_encoding,
        "frequency_mode": frequency_mode_metadata(args.freq_mode),
        "usecols": STREAM_USECOLS,
        "dtype_map": STREAM_DTYPE_MAP,
        "notes": [
            "Streaming mode never concatenates the full campaign.",
            "P90/P99 absolute-error tails are histogram approximations.",
            "Raw scatter plots and pairwise t-tests are intentionally skipped in streaming mode.",
        ],
    }
    (out_dir / "streaming_config.json").write_text(json.dumps(streaming_config, indent=2) + "\n", encoding="utf-8")
    if args.log_memory:
        log_memory("streaming end", memory_log)
    (out_dir / "analysis_memory_report.txt").write_text("\n".join(memory_log) + "\n", encoding="utf-8")
    return all_results, ttest_all


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


def apply_nfast_encoding(df: pd.DataFrame, nfast_encoding: str) -> pd.DataFrame:
    """Prepare `nfast_hit` for legacy or O2 raw-tag reconstruction.

    In raw-tag mode the packet column is preserved as `nfast_raw_tag`, decoded
    in software, and then `nfast_hit`/`t_raw_ps` are replaced with decoded values
    for the existing analysis code paths.
    """
    if nfast_encoding == NFAST_ENCODING_LEGACY:
        return add_o2_raw_tag_decode_columns(df, nfast_encoding=nfast_encoding)

    out = add_o2_raw_tag_decode_columns(df, nfast_encoding=nfast_encoding)
    if {"nfast_hit", "nfast_decoded"}.issubset(out.columns):
        out["nfast_hit_packet_raw_tag"] = out["nfast_hit"]
        out["nfast_hit"] = out["nfast_decoded"].astype(np.int64)
    if "t_raw_ps_decoded_nfast" in out.columns:
        if "t_raw_ps" in out.columns:
            out["t_raw_ps_packet_raw_tag_interpreted"] = out["t_raw_ps"]
        out["t_raw_ps"] = out["t_raw_ps_decoded_nfast"]
    return out


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


def compute_raw_tuple_histogram(df: pd.DataFrame) -> pd.DataFrame:
    """Return raw Vernier tuple occupancy for hardware code-density review."""
    required = {"tuple_code", "nslow", "nfast_hit", "ns", "nf", "slow_boundary_inc"}
    if not required.issubset(df.columns):
        return pd.DataFrame()

    work = df[list(required)].copy()
    if "stop_phase_disc" in df.columns:
        work["stop_phase_disc"] = pd.to_numeric(df["stop_phase_disc"], errors="coerce")
    work = work[pd.to_numeric(work["tuple_code"], errors="coerce") >= 0]
    if work.empty:
        return pd.DataFrame()

    group_cols = ["tuple_code", "nslow", "nfast_hit", "ns", "nf", "slow_boundary_inc"]
    if "stop_phase_disc" in work.columns:
        group_cols.append("stop_phase_disc")
    hist = (
        work.groupby(group_cols, observed=True)
        .size()
        .reset_index(name="count")
        .sort_values("tuple_code", ignore_index=True)
    )
    ideal = float(hist["count"].mean()) if not hist.empty else np.nan
    if ideal and np.isfinite(ideal):
        hist["raw_tuple_dnl_est"] = hist["count"] / ideal - 1.0
        hist["raw_tuple_inl_est"] = hist["raw_tuple_dnl_est"].cumsum()
    else:
        hist["raw_tuple_dnl_est"] = np.nan
        hist["raw_tuple_inl_est"] = np.nan
    return hist


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


def plot_raw_tuple_histogram(hist: pd.DataFrame, config: str, out_dir: Path):
    """Plot raw tuple occupancy and estimated raw tuple INL/DNL."""
    if hist.empty:
        return

    safe_cfg = _safe_config(config)
    fig, axes = plt.subplots(3, 1, figsize=(9, 8), sharex=True)
    axes[0].plot(hist["tuple_code"], hist["count"], lw=0.8, color=PALETTE["blue"])
    axes[0].set_ylabel("Count")
    axes[0].set_title(f"Raw tuple occupancy – {config}")

    axes[1].plot(hist["tuple_code"], hist["raw_tuple_dnl_est"],
                 lw=0.8, color=PALETTE["orange"])
    axes[1].axhline(0.0, color=PALETTE["gray"], ls="--", lw=0.8)
    axes[1].set_ylabel("DNL est. (LSB)")

    axes[2].plot(hist["tuple_code"], hist["raw_tuple_inl_est"],
                 lw=0.8, color=PALETTE["red"])
    axes[2].axhline(0.0, color=PALETTE["gray"], ls="--", lw=0.8)
    axes[2].set_ylabel("INL est. (LSB)")
    axes[2].set_xlabel("Raw tuple code")

    for ax in axes:
        style_axes(ax)
    save_figure(fig, out_dir / f"raw_tuple_histogram_{safe_cfg}.png")


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
            "frequency_mode": res.get("frequency_mode", {}),
            "offset_stats": res.get("offset_stats", {}),
            "peak_dnl": res.get("peak_dnl"),
            "peak_inl": res.get("peak_inl"),
            "raw_tuple_histogram": res.get("raw_tuple_histogram_summary", {}),
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
                             "stop_disc_profile", "traw_profile", "delay_regions"):
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
        f"{'RMSE':>10s} {'PkDNL':>8s} {'PkINL':>8s} {'RawBins':>8s} {'XChk':>6s}"
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
            f"{res.get('raw_tuple_histogram_summary', {}).get('occupied_bins', 0):>8d} "
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
                   do_plots: bool = True,
                   nfast_encoding: str = NFAST_ENCODING_LEGACY) -> dict:
    """Run full analysis on one configuration, return results dict."""
    result: dict = {}
    result["nfast_encoding"] = nfast_encoding
    result["frequency_mode"] = frequency_mode_metadata()
    df = apply_nfast_encoding(df, nfast_encoding)

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

    # raw tuple code-density histogram for pre-calibration hardware review
    raw_tuple_hist = compute_raw_tuple_histogram(df)
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
      print("  Raw tuple histogram: "
            f"{result['raw_tuple_histogram_summary']['occupied_bins']} occupied bins, "
            f"peak DNL est={result['raw_tuple_histogram_summary']['peak_dnl_est']:.3f} LSB, "
            f"peak INL est={result['raw_tuple_histogram_summary']['peak_inl_est']:.3f} LSB")
    else:
      result["raw_tuple_histogram_summary"] = {}

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
    stop_disc_profile = compute_discrete_profile(df, "stop_phase_disc")
    traw_profile = compute_binned_profile(df, "t_raw_ps", n_bins=PROFILE_TRAW_BINS)
    delay_regions = compute_delay_regions(df)

    result["delay_profile"] = delay_profile
    result["nslow_profile"] = nslow_profile
    result["nfast_profile"] = nfast_profile
    result["hit_idx_profile"] = hit_idx_profile
    result["stop_disc_profile"] = stop_disc_profile
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
    if not stop_disc_profile.empty:
        stop_disc_profile.to_csv(out_dir / f"stop_phase_disc_profile_{safe_cfg}.csv", index=False)
    if not traw_profile.empty:
        traw_profile.to_csv(out_dir / f"t_raw_profile_{safe_cfg}.csv", index=False)
    if not delay_regions.empty:
        delay_regions.to_csv(out_dir / f"delay_regions_{safe_cfg}.csv", index=False)
    if count_piv is not None and not count_piv.empty:
        count_piv.to_csv(out_dir / f"phase_count_heatmap_{safe_cfg}.csv")
    if not raw_tuple_hist.empty:
        raw_tuple_hist.to_csv(out_dir / f"raw_tuple_histogram_{safe_cfg}.csv", index=False)

    # plots
    if do_plots:
        try:
            if {"Tref_ps", "t_raw_ps"}.issubset(df.columns):
                plot_linearity(df, config, out_dir)
                plot_residual(df, config, out_dir)
            plot_residual_hist(df, config, out_dir)
            if len(dnl) > 0:
                plot_inl_dnl(edges, dnl, inl, config, out_dir)
            plot_raw_tuple_histogram(raw_tuple_hist, config, out_dir)
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
    parser.add_argument("--max-rows-per-file", type=int, default=None,
                        help="Debug cap on rows read from each CSV file")
    parser.add_argument("--no-plots", action="store_true",
                        help="Skip plot generation")
    parser.add_argument("--nfast-encoding", default=NFAST_ENCODING_LEGACY,
                        choices=NFAST_ENCODING_CHOICES,
                        help="Interpret packet nfast_hit according to the declared tag encoding")
    parser.add_argument("--freq-mode", default=FREQ_MODE_NOMINAL,
                        choices=FREQ_MODE_CHOICES,
                        help="Frequency/tap mode used by the RTL that produced the CSVs")
    parser.add_argument("--analysis-backend", default="legacy",
                        choices=["legacy", "streaming"],
                        help="Analysis implementation (legacy loads all rows; streaming is chunked)")
    parser.add_argument("--analysis-low-memory", action="store_true",
                        help="Alias for --analysis-backend streaming")
    parser.add_argument("--analysis-jobs", type=int, default=min(4, os.cpu_count() or 1),
                        help="Reserved analysis worker budget; streaming keeps aggregation bounded")
    parser.add_argument("--analysis-chunksize", "--chunksize", dest="analysis_chunksize",
                        type=int, default=STREAM_DEFAULT_CHUNKSIZE,
                        help=f"CSV rows per streaming chunk (default {STREAM_DEFAULT_CHUNKSIZE})")
    parser.add_argument("--log-memory", action="store_true",
                        help="Log process RSS during analysis")
    args = parser.parse_args()

    out_dir = Path(args.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    freq_cfg = set_frequency_mode(args.freq_mode)
    print(
        "[INFO] Frequency mode: "
        f"{freq_cfg['freq_mode']} "
        f"OSC_TS_SLOW_PS={freq_cfg['OSC_TS_SLOW_PS']} "
        f"OSC_TS_FAST_PS={freq_cfg['OSC_TS_FAST_PS']} "
        f"DELTA_STEP={freq_cfg['DELTA_STEP']} "
        f"DELTA_LSB={freq_cfg['DELTA_LSB']} "
        f"K_VERNIER={freq_cfg['K_VERNIER']}"
    )

    # discover
    configs = discover_csv_files(args.campaign_dir, args.config_filter, args.max_files)
    if not configs:
        print("[ERROR] No CSV files found. Check --campaign-dir path.")
        sys.exit(1)

    print(f"[INFO] Found {len(configs)} configuration(s) in {args.campaign_dir}")
    for cfg, paths in configs.items():
        print(f"  {cfg}: {len(paths)} file(s)")
    print()

    if args.analysis_low_memory:
        args.analysis_backend = "streaming"
    if args.analysis_jobs < 1:
        print("[ERROR] --analysis-jobs must be >= 1")
        sys.exit(1)
    if args.analysis_chunksize < 1:
        print("[ERROR] --analysis-chunksize must be >= 1")
        sys.exit(1)

    if args.analysis_backend == "streaming":
        all_results, ttest_all = analyze_campaign_streaming(configs, args, out_dir)
        report_path = out_dir / "summary_report.txt"
        write_summary_report(all_results, report_path, ttest_all)
        summary_json = out_dir / "summary_report.json"
        summary_json.write_text(
            json.dumps(_json_ready_results(all_results, ttest_all), indent=2, default=str) + "\n",
            encoding="utf-8",
        )
        print(f"[INFO] Summary JSON written to {summary_json}")
        print("[INFO] Streaming analysis complete.")
        return

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

        result = analyze_config(
            cfg,
            df,
            out_dir,
            do_plots=not args.no_plots,
            nfast_encoding=args.nfast_encoding,
        )
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
