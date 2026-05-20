#!/usr/bin/env python3
"""Detect raw-feature aliasing in fixed-delay MPTDC characterization data.

The raw timestamp formula can only be tapeout-grade if the packet-visible
feature tuple uniquely identifies the physical delay over the supported range.
This script quantifies that property directly: for each candidate key, it
reports collisions where one key maps to multiple fixed delays and computes the
best possible per-key oracle RMSE floor.
"""

from __future__ import annotations

import argparse
import json
import math
import re
import sys
from pathlib import Path

import numpy as np
import pandas as pd


DELAY_DIR_RE = re.compile(r"delay_(\d+)ps$")
DEFAULT_KEY_SETS: dict[str, list[str]] = {
    "raw_formula_inputs": ["nslow", "nfast_hit", "ns", "nf", "slow_boundary_inc"],
    "packet_no_hit": ["nslow", "nfast_hit", "ns", "nf", "phase0_snap", "slow_boundary_inc"],
    "packet_with_hit": [
        "nslow", "nfast_hit", "ns", "nf", "phase0_snap", "slow_boundary_inc", "hit_idx",
    ],
    "packet_stop_disc": [
        "nslow", "nfast_hit", "ns", "nf", "stop_phase_disc", "phase0_snap",
        "slow_boundary_inc", "hit_idx",
    ],
    "packet_all_csv": [
        "nslow", "nfast_hit", "ns", "nf", "stop_phase_disc", "phase0_snap", "slow_boundary_inc",
        "hit_idx", "hit_count", "flags", "ctx_id", "mode", "max_hits",
    ],
    "debug_aug": [
        "nslow", "nfast_hit", "ns", "nf", "phase0_snap", "slow_boundary_inc",
        "hit_idx", "hit_count", "flags", "ctx_id", "nfast_snap", "nfast_stop",
        "phase7d_snap", "pd_idx", "event_seq",
    ],
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--campaign-dir",
        default="results/vip_overnight/characterization/fixed_firsthit8_early",
        help="Fixed-delay campaign root containing delay_<N>ps/<config>/seed_*.csv.",
    )
    parser.add_argument(
        "--out-dir",
        default=None,
        help="Output directory. Defaults to <campaign-dir>/analysis/raw_aliases.",
    )
    parser.add_argument(
        "--config-filter",
        default="*",
        help="Shell-style filter for config directory names.",
    )
    parser.add_argument(
        "--max-files-per-delay",
        type=int,
        default=None,
        help="Optional cap on seed CSVs loaded per delay/config.",
    )
    parser.add_argument(
        "--key",
        action="append",
        default=[],
        metavar="NAME:COL,COL",
        help="Additional candidate key. Can be passed multiple times.",
    )
    parser.add_argument(
        "--top-collisions",
        type=int,
        default=100,
        help="Rows to keep in each top-collisions CSV.",
    )
    parser.add_argument("--self-test", action="store_true", help="Run synthetic self-test and exit.")
    return parser.parse_args()


def parse_delay_from_path(path: Path) -> int | None:
    for parent in [path.parent, *path.parents]:
        match = DELAY_DIR_RE.fullmatch(parent.name)
        if match:
            return int(match.group(1))
    return None


def safe_name(name: str) -> str:
    return re.sub(r"[^A-Za-z0-9_.-]+", "_", name).strip("_")


def parse_custom_key(spec: str) -> tuple[str, list[str]]:
    if ":" not in spec:
        raise ValueError(f"Custom key must be NAME:COL,COL, got {spec!r}")
    name, cols = spec.split(":", 1)
    key_cols = [col.strip() for col in cols.split(",") if col.strip()]
    if not name.strip() or not key_cols:
        raise ValueError(f"Custom key must include name and columns, got {spec!r}")
    return safe_name(name.strip()), key_cols


def discover_csvs(root: Path, config_filter: str, max_files_per_delay: int | None) -> dict[str, list[Path]]:
    import fnmatch

    configs: dict[str, list[Path]] = {}
    for delay_dir in sorted(root.glob("delay_*ps")):
        if not delay_dir.is_dir():
            continue
        for cfg_dir in sorted(delay_dir.iterdir()):
            if not cfg_dir.is_dir() or not fnmatch.fnmatch(cfg_dir.name, config_filter):
                continue
            files = sorted(cfg_dir.glob("seed_*.csv"))
            if max_files_per_delay is not None:
                files = files[:max_files_per_delay]
            if files:
                configs.setdefault(cfg_dir.name, []).extend(files)
    return configs


def load_fixed_delay_csvs(paths: list[Path]) -> pd.DataFrame:
    frames: list[pd.DataFrame] = []
    for path in paths:
        try:
            frame = pd.read_csv(path)
        except pd.errors.EmptyDataError:
            continue
        if frame.empty:
            continue
        delay_ps = parse_delay_from_path(path)
        if delay_ps is None:
            raise ValueError(f"Could not infer delay_<N>ps directory for {path}")
        frame = frame.copy()
        frame["delay_ps"] = delay_ps
        frame["source_file"] = str(path)
        frames.append(frame)
    if not frames:
        return pd.DataFrame()
    data = pd.concat(frames, ignore_index=True)
    for col in ("delay_ps", "Tref_ps", "t_raw_ps"):
        if col not in data.columns:
            raise ValueError(f"Required column {col!r} missing from loaded data")
        data[col] = pd.to_numeric(data[col], errors="coerce")
    data = data.dropna(subset=["delay_ps", "Tref_ps", "t_raw_ps"]).copy()
    data["delay_ps"] = data["delay_ps"].astype(int)
    data["err_current_ps"] = data["Tref_ps"] - data["t_raw_ps"]
    return data


def available_key_sets(df: pd.DataFrame, custom_specs: list[str]) -> dict[str, list[str]]:
    key_sets = dict(DEFAULT_KEY_SETS)
    for spec in custom_specs:
        name, cols = parse_custom_key(spec)
        key_sets[name] = cols

    available: dict[str, list[str]] = {}
    for name, cols in key_sets.items():
        present = [col for col in cols if col in df.columns]
        if present:
            available[name] = present
    return available


def rmse(values: pd.Series | np.ndarray) -> float:
    arr = np.asarray(values, dtype=float)
    if arr.size == 0:
        return float("nan")
    return float(math.sqrt(np.mean(np.square(arr))))


def string_join_unique(values: pd.Series, *, max_items: int = 32) -> str:
    unique = sorted(pd.Series(values).dropna().unique().tolist())
    text = ",".join(str(int(v)) if float(v).is_integer() else str(v) for v in unique[:max_items])
    if len(unique) > max_items:
        text += f",...(+{len(unique) - max_items})"
    return text


def summarize_key(df: pd.DataFrame, key_cols: list[str]) -> tuple[dict[str, object], pd.DataFrame]:
    group = df.groupby(key_cols, dropna=False, observed=True)
    mean_tref = group["Tref_ps"].transform("mean")
    oracle_err = df["Tref_ps"] - mean_tref

    collisions = (
        group.agg(
            count=("Tref_ps", "size"),
            n_delays=("delay_ps", "nunique"),
            min_delay_ps=("delay_ps", "min"),
            max_delay_ps=("delay_ps", "max"),
            delays=("delay_ps", string_join_unique),
            mean_tref_ps=("Tref_ps", "mean"),
            mean_raw_ps=("t_raw_ps", "mean"),
            current_rmse_ps=("err_current_ps", rmse),
        )
        .reset_index()
    )
    collisions["span_delay_ps"] = collisions["max_delay_ps"] - collisions["min_delay_ps"]
    aliased = collisions[collisions["n_delays"] > 1].copy()

    summary = {
        "key_cols": key_cols,
        "rows": int(len(df)),
        "unique_keys": int(len(collisions)),
        "aliased_keys": int(len(aliased)),
        "aliased_rows": int(aliased["count"].sum()) if not aliased.empty else 0,
        "aliased_row_fraction": float(aliased["count"].sum() / len(df)) if len(df) and not aliased.empty else 0.0,
        "current_rmse_ps": rmse(df["err_current_ps"]),
        "oracle_floor_rmse_ps": rmse(oracle_err),
        "oracle_floor_p99_abs_ps": float(np.percentile(np.abs(oracle_err), 99)) if len(df) else float("nan"),
        "max_delay_span_ps": int(aliased["span_delay_ps"].max()) if not aliased.empty else 0,
    }
    return summary, collisions


def dominant_tuples(df: pd.DataFrame, key_cols: list[str], top_per_delay: int) -> pd.DataFrame:
    group_cols = ["delay_ps", *key_cols]
    rows = (
        df.groupby(group_cols, dropna=False, observed=True)
        .agg(
            count=("Tref_ps", "size"),
            mean_tref_ps=("Tref_ps", "mean"),
            mean_raw_ps=("t_raw_ps", "mean"),
            current_rmse_ps=("err_current_ps", rmse),
        )
        .reset_index()
        .sort_values(["delay_ps", "count"], ascending=[True, False])
    )
    return rows.groupby("delay_ps", group_keys=False).head(top_per_delay).reset_index(drop=True)


def analyze_config(config: str, df: pd.DataFrame, out_dir: Path, args: argparse.Namespace) -> dict[str, object]:
    config_dir = out_dir / safe_name(config)
    config_dir.mkdir(parents=True, exist_ok=True)

    key_sets = available_key_sets(df, args.key)
    summaries: list[dict[str, object]] = []
    for key_name, key_cols in key_sets.items():
        summary, collisions = summarize_key(df, key_cols)
        summary = {"config": config, "key_name": key_name, **summary}
        summaries.append(summary)

        aliased = collisions[collisions["n_delays"] > 1].sort_values(
            ["n_delays", "count", "span_delay_ps"],
            ascending=[False, False, False],
        )
        aliased.head(args.top_collisions).to_csv(
            config_dir / f"top_collisions_{safe_name(key_name)}.csv",
            index=False,
        )
        dominant_tuples(df, key_cols, args.top_collisions).to_csv(
            config_dir / f"dominant_tuples_{safe_name(key_name)}.csv",
            index=False,
        )

    summary_df = pd.DataFrame.from_records(summaries)
    summary_df.to_csv(config_dir / "alias_key_summary.csv", index=False)
    write_report(config, summary_df, config_dir / "raw_alias_report.txt")
    return {
        "config": config,
        "rows": int(len(df)),
        "key_summary": summary_df.to_dict(orient="records"),
    }


def write_report(config: str, summary_df: pd.DataFrame, path: Path) -> None:
    lines = [
        "=" * 80,
        "MPTDC Raw Feature Alias Report",
        "=" * 80,
        "",
        f"Config: {config}",
        "",
        "A key with aliased_keys > 0 cannot uniquely reconstruct absolute delay",
        "without another discriminator. oracle_floor_rmse_ps is the best possible",
        "RMSE for a per-key mean timestamp on this dataset.",
        "",
    ]
    if summary_df.empty:
        lines.append("No candidate keys were available.")
    else:
        header = (
            f"{'Key':<22s} {'Rows':>10s} {'Keys':>9s} {'Aliased':>9s} "
            f"{'AliasRows':>10s} {'RawRMSE':>10s} {'OracleRMSE':>11s} {'MaxSpan':>8s}"
        )
        lines.append(header)
        lines.append("-" * len(header))
        for _, row in summary_df.sort_values("oracle_floor_rmse_ps").iterrows():
            lines.append(
                f"{row['key_name']:<22s} {int(row['rows']):>10d} "
                f"{int(row['unique_keys']):>9d} {int(row['aliased_keys']):>9d} "
                f"{int(row['aliased_rows']):>10d} {row['current_rmse_ps']:>10.2f} "
                f"{row['oracle_floor_rmse_ps']:>11.2f} {int(row['max_delay_span_ps']):>8d}"
            )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def run_self_test() -> None:
    injective = pd.DataFrame({
        "delay_ps": [10, 20, 30, 40],
        "Tref_ps": [10, 20, 30, 40],
        "t_raw_ps": [10, 20, 30, 40],
        "nslow": [0, 0, 0, 0],
        "nfast_hit": [0, 1, 2, 3],
        "ns": [0, 0, 0, 0],
        "nf": [0, 0, 0, 0],
        "phase0_snap": [0, 0, 0, 0],
        "slow_boundary_inc": [0, 0, 0, 0],
        "hit_idx": [0, 0, 0, 0],
    })
    injective["err_current_ps"] = injective["Tref_ps"] - injective["t_raw_ps"]
    summary, _ = summarize_key(injective, ["nslow", "nfast_hit"])
    assert summary["aliased_keys"] == 0
    assert summary["oracle_floor_rmse_ps"] == 0.0

    aliased = pd.concat([injective, injective.iloc[[1]].assign(delay_ps=100, Tref_ps=100)], ignore_index=True)
    aliased["err_current_ps"] = aliased["Tref_ps"] - aliased["t_raw_ps"]
    summary, collisions = summarize_key(aliased, ["nslow", "nfast_hit"])
    assert summary["aliased_keys"] == 1
    assert summary["oracle_floor_rmse_ps"] > 0.0
    assert int(collisions["n_delays"].max()) == 2
    print("analyze_raw_aliases.py self-test PASS")


def main() -> int:
    args = parse_args()
    if args.self_test:
        run_self_test()
        return 0

    root = Path(args.campaign_dir)
    if not root.is_dir():
        raise SystemExit(f"[ERROR] Missing campaign directory: {root}")
    out_dir = Path(args.out_dir) if args.out_dir else root / "analysis" / "raw_aliases"
    out_dir.mkdir(parents=True, exist_ok=True)

    configs = discover_csvs(root, args.config_filter, args.max_files_per_delay)
    if not configs:
        raise SystemExit(f"[ERROR] No fixed-delay seed CSVs found under {root}")

    all_results: list[dict[str, object]] = []
    all_summary_frames: list[pd.DataFrame] = []
    for config, paths in sorted(configs.items()):
        print(f"[INFO] Loading {config}: {len(paths)} CSV file(s)")
        df = load_fixed_delay_csvs(paths)
        if df.empty:
            print(f"[WARN] {config}: no usable rows")
            continue
        result = analyze_config(config, df, out_dir, args)
        all_results.append(result)
        all_summary_frames.append(pd.DataFrame.from_records(result["key_summary"]))

    if not all_results:
        raise SystemExit("[ERROR] No usable configurations were analyzed")

    if all_summary_frames:
        pd.concat(all_summary_frames, ignore_index=True).to_csv(out_dir / "alias_key_summary_all.csv", index=False)
    (out_dir / "raw_alias_report.json").write_text(
        json.dumps(all_results, indent=2, default=str) + "\n",
        encoding="utf-8",
    )
    print(f"[INFO] Raw alias analysis complete: {out_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
