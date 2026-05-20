#!/usr/bin/env python3
"""Search TB-only debug columns for a minimal raw-timestamp discriminator.

This complements analyze_raw_aliases.py: instead of checking a few named packet
keys, it tries every debug column and small debug-column combination added to
the fixed packet-visible key. The goal is to find the smallest internal state
that makes fixed-delay keys injective before any RTL packet change is proposed.
"""

from __future__ import annotations

import argparse
import itertools
import json
import math
import sys
from pathlib import Path

import numpy as np
import pandas as pd

from analyze_raw_aliases import discover_csvs, load_fixed_delay_csvs, rmse, safe_name, summarize_key


DEFAULT_BASE_KEY = ["nslow", "nfast_hit", "ns", "nf", "phase0_snap", "slow_boundary_inc", "hit_idx"]
DEFAULT_EXCLUDE = {
    "conv_id",
    "Tref_ps",
    "delay_ps",
    "source_file",
    "t_raw_ps",
    "mode",
    "max_hits",
    "hit_count",
    "flags",
    "ctx_id",
    "dbg_snapshot_time_ps",
    "dbg_stop_time_ps",
}
DEFAULT_BITMAP_COLUMNS = [
    "dbg_stop_slow_phase",
    "dbg_stop_fast_phase",
    "dbg_snapshot_slow_phase",
    "dbg_snapshot_fast_phase",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--campaign-dir",
        default="results/fixed_delay_campaign",
        help="Fixed-delay campaign root.",
    )
    parser.add_argument("--out-dir", default=None, help="Output directory.")
    parser.add_argument("--config-filter", default="*", help="Config directory glob.")
    parser.add_argument("--max-files-per-delay", type=int, default=None)
    parser.add_argument("--base-key", default=",".join(DEFAULT_BASE_KEY))
    parser.add_argument("--candidate-prefix", action="append", default=[])
    parser.add_argument("--candidate", action="append", default=[], help="Explicit candidate column.")
    parser.add_argument("--exclude", action="append", default=[], help="Additional column to exclude.")
    parser.add_argument("--include-time", action="store_true", help="Allow TB absolute-time columns as candidates.")
    parser.add_argument(
        "--expand-bitmaps",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="Derive per-bit candidate columns from packed phase bitmap probes.",
    )
    parser.add_argument("--max-combo", type=int, default=3, help="Largest candidate combination to try.")
    parser.add_argument("--top", type=int, default=50, help="Rows to keep in the ranked CSV/report.")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if not args.candidate_prefix and not args.candidate:
        args.candidate_prefix = ["dbg_"]
    return args


def parse_cols(spec: str) -> list[str]:
    return [col.strip() for col in spec.split(",") if col.strip()]


def augment_derived_columns(df: pd.DataFrame, args: argparse.Namespace) -> pd.DataFrame:
    if not args.expand_bitmaps:
        return df
    df = df.copy()
    for col in DEFAULT_BITMAP_COLUMNS:
        if col not in df.columns:
            continue
        numeric = pd.to_numeric(df[col], errors="coerce").fillna(0).astype("int64")
        max_val = int(numeric.max()) if len(numeric) else 0
        width = max(1, max_val.bit_length())
        for bit in range(width):
            df[f"{col}_b{bit}"] = np.right_shift(numeric.to_numpy(), bit) & 1
    return df


def candidate_columns(df: pd.DataFrame, args: argparse.Namespace, base_key: list[str]) -> list[str]:
    exclude = set(DEFAULT_EXCLUDE)
    exclude.update(args.exclude)
    if args.include_time:
      exclude.discard("dbg_snapshot_time_ps")
      exclude.discard("dbg_stop_time_ps")

    cols: list[str] = []
    for col in df.columns:
        if col in base_key or col in exclude:
            continue
        if col in args.candidate or any(col.startswith(prefix) for prefix in args.candidate_prefix):
            if df[col].nunique(dropna=False) > 1:
                cols.append(col)
    for col in args.candidate:
        if col in df.columns and col not in cols and col not in base_key and col not in exclude:
            if df[col].nunique(dropna=False) > 1:
                cols.append(col)
    return cols


def evaluate_candidates(
    df: pd.DataFrame,
    base_key: list[str],
    candidates: list[str],
    max_combo: int,
) -> pd.DataFrame:
    rows: list[dict[str, object]] = []
    base_summary, _ = summarize_key(df, base_key)
    rows.append({"combo_size": 0, "candidate_cols": "", **base_summary})

    for size in range(1, max_combo + 1):
        for combo in itertools.combinations(candidates, size):
            key_cols = [*base_key, *combo]
            summary, _ = summarize_key(df, key_cols)
            rows.append({
                "combo_size": size,
                "candidate_cols": ",".join(combo),
                **summary,
            })
    ranked = pd.DataFrame.from_records(rows)
    ranked = ranked.sort_values(
        ["aliased_keys", "max_delay_span_ps", "oracle_floor_rmse_ps", "combo_size", "unique_keys"],
        ascending=[True, True, True, True, True],
    ).reset_index(drop=True)
    return ranked


def write_report(config: str, ranked: pd.DataFrame, out_path: Path, top: int) -> None:
    baseline = ranked[ranked["combo_size"] == 0].iloc[0]
    winners = ranked[(ranked["aliased_keys"] == 0) & (ranked["combo_size"] > 0)]
    lines = [
        "=" * 88,
        "MPTDC Raw Discriminator Search",
        "=" * 88,
        "",
        f"Config: {config}",
        f"Rows: {int(baseline['rows'])}",
        "",
        "Baseline packet-visible key:",
        f"  aliased_keys={int(baseline['aliased_keys'])} "
        f"aliased_rows={int(baseline['aliased_rows'])} "
        f"oracle_rmse={baseline['oracle_floor_rmse_ps']:.6g} ps "
        f"max_span={int(baseline['max_delay_span_ps'])} ps",
        "",
    ]
    if winners.empty:
        best = ranked.iloc[0]
        lines.extend([
            "No candidate combination fully eliminated aliases within the search bound.",
            "Best observed key:",
            f"  + {best['candidate_cols'] or '<none>'}",
            f"  aliased_keys={int(best['aliased_keys'])} "
            f"aliased_rows={int(best['aliased_rows'])} "
            f"oracle_rmse={best['oracle_floor_rmse_ps']:.6g} ps "
            f"p99={best['oracle_floor_p99_abs_ps']:.6g} ps "
            f"max_span={int(best['max_delay_span_ps'])} ps",
        ])
    else:
        winner = winners.sort_values(
            ["combo_size", "oracle_floor_rmse_ps", "unique_keys"]
        ).iloc[0]
        lines.extend([
            "Smallest alias-free discriminator:",
            f"  + {winner['candidate_cols']}",
            f"  oracle_rmse={winner['oracle_floor_rmse_ps']:.6g} ps "
            f"p99={winner['oracle_floor_p99_abs_ps']:.6g} ps "
            f"unique_keys={int(winner['unique_keys'])}",
        ])

    lines.extend(["", f"Top {top} ranked candidates:", ""])
    for _, row in ranked.head(top).iterrows():
        lines.append(
            f"size={int(row['combo_size'])} +[{row['candidate_cols'] or '<none>'}] "
            f"aliases={int(row['aliased_keys'])} rows={int(row['aliased_rows'])} "
            f"oracle={row['oracle_floor_rmse_ps']:.6g} p99={row['oracle_floor_p99_abs_ps']:.6g} "
            f"span={int(row['max_delay_span_ps'])} keys={int(row['unique_keys'])}"
        )
    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def analyze_config(config: str, paths: list[Path], out_dir: Path, args: argparse.Namespace) -> dict[str, object]:
    df = augment_derived_columns(load_fixed_delay_csvs(paths), args)
    if df.empty:
        raise ValueError(f"{config}: no usable rows")
    base_key = [col for col in parse_cols(args.base_key) if col in df.columns]
    if not base_key:
        raise ValueError(f"{config}: no base-key columns present")
    candidates = candidate_columns(df, args, base_key)
    ranked = evaluate_candidates(df, base_key, candidates, args.max_combo)

    cfg_dir = out_dir / safe_name(config)
    cfg_dir.mkdir(parents=True, exist_ok=True)
    ranked.to_csv(cfg_dir / "discriminator_ranked.csv", index=False)
    write_report(config, ranked, cfg_dir / "discriminator_report.txt", args.top)

    winners = ranked[(ranked["aliased_keys"] == 0) & (ranked["combo_size"] > 0)]
    winner = None if winners.empty else winners.sort_values(
        ["combo_size", "oracle_floor_rmse_ps", "unique_keys"]
    ).iloc[0].to_dict()
    return {
        "config": config,
        "rows": int(len(df)),
        "base_key": base_key,
        "candidate_columns": candidates,
        "winner": winner,
        "best": ranked.iloc[0].to_dict(),
    }


def run_self_test() -> None:
    df = pd.DataFrame({
        "delay_ps": [20, 20, 1000, 1000],
        "Tref_ps": [20, 20, 1000, 1000],
        "t_raw_ps": [1130, 1130, 1130, 1130],
        "nslow": [0, 0, 0, 0],
        "nfast_hit": [0, 0, 0, 0],
        "ns": [0, 0, 0, 0],
        "nf": [0, 0, 0, 0],
        "phase0_snap": [1, 1, 1, 1],
        "slow_boundary_inc": [0, 0, 0, 0],
        "hit_idx": [0, 0, 0, 0],
        "dbg_epoch": [0, 0, 1, 1],
        "dbg_noise": [0, 1, 0, 1],
    })
    df["err_current_ps"] = df["Tref_ps"] - df["t_raw_ps"]
    ranked = evaluate_candidates(df, DEFAULT_BASE_KEY, ["dbg_epoch", "dbg_noise"], 2)
    winner = ranked[(ranked["aliased_keys"] == 0) & (ranked["combo_size"] > 0)].iloc[0]
    assert winner["candidate_cols"] == "dbg_epoch"
    assert math.isclose(float(winner["oracle_floor_rmse_ps"]), 0.0)
    print("find_raw_discriminator.py self-test PASS")


def main() -> int:
    args = parse_args()
    if args.self_test:
        run_self_test()
        return 0

    root = Path(args.campaign_dir)
    if not root.is_dir():
        raise SystemExit(f"[ERROR] Missing campaign directory: {root}")
    out_dir = Path(args.out_dir) if args.out_dir else root / "analysis" / "raw_discriminator"
    out_dir.mkdir(parents=True, exist_ok=True)

    configs = discover_csvs(root, args.config_filter, args.max_files_per_delay)
    if not configs:
        raise SystemExit(f"[ERROR] No fixed-delay seed CSVs found under {root}")

    results = []
    for config, paths in sorted(configs.items()):
        print(f"[INFO] Searching {config}: {len(paths)} CSV file(s)")
        results.append(analyze_config(config, paths, out_dir, args))
    (out_dir / "discriminator_summary.json").write_text(
        json.dumps(results, indent=2, default=str) + "\n",
        encoding="utf-8",
    )
    print(f"[INFO] Discriminator search complete: {out_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
