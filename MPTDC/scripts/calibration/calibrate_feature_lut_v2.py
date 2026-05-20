#!/usr/bin/env python3
"""Direct-feature LUT calibration for MPTDC campaign CSVs.

This is a non-destructive v2 path for raw-feature calibration.  Unlike the
legacy 6D calibrator, it does not infer ns/nf from t_raw_ps and it does not
silently hide nslow==0 unless requested.  It trains a mean correction per
packet-visible feature key and reports ambiguity floors alongside held-out
validation metrics.
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


DEFAULT_KEY = ["nslow", "nfast_hit", "ns", "nf", "phase0_snap", "slow_boundary_inc", "hit_idx"]
OPTIONAL_REPORT_KEYS = {
    "current_6d": ["ns", "nf", "nslow", "nfast_hit", "phase0_snap", "hit_idx"],
    "boundary_aug": DEFAULT_KEY,
    "packet_all": [
        "nslow", "nfast_hit", "ns", "nf", "phase0_snap", "slow_boundary_inc",
        "hit_idx", "hit_count", "flags", "ctx_id", "mode", "max_hits",
    ],
}
REQUIRED_BASE_COLUMNS = {"Tref_ps", "t_raw_ps"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--train-dir", help="Directory containing training seed CSVs.")
    parser.add_argument("--val-dir", help="Directory containing held-out validation seed CSVs.")
    parser.add_argument("--out-dir", default="results/calibration_feature_lut_v2")
    parser.add_argument(
        "--key",
        default=",".join(DEFAULT_KEY),
        help="Comma-separated LUT key columns. Defaults to direct packet boundary-augmented key.",
    )
    parser.add_argument("--recursive", action="store_true", help="Search for seed_*.csv recursively.")
    parser.add_argument("--max-train-files", type=int, default=None)
    parser.add_argument("--max-val-files", type=int, default=None)
    parser.add_argument(
        "--core-only",
        action="store_true",
        help="Filter out nslow==0 rows. Default keeps first-cycle/early-delay rows visible.",
    )
    parser.add_argument("--self-test", action="store_true", help="Run synthetic self-test and exit.")
    return parser.parse_args()


def discover_seed_csvs(root: str | None, *, recursive: bool, max_files: int | None) -> list[Path]:
    if not root:
        return []
    base = Path(root)
    if not base.is_dir():
        raise FileNotFoundError(f"Dataset directory does not exist: {root}")
    pattern = "**/seed_*.csv" if recursive else "seed_*.csv"
    files = sorted(base.glob(pattern))
    if max_files is not None:
        files = files[:max_files]
    if not files:
        raise FileNotFoundError(f"No seed_*.csv files found under {root}")
    return files


def parse_key(spec: str) -> list[str]:
    key = [col.strip() for col in spec.split(",") if col.strip()]
    if not key:
        raise ValueError("Calibration key cannot be empty")
    return key


def read_csv(path: Path) -> pd.DataFrame | None:
    try:
        frame = pd.read_csv(path)
    except pd.errors.EmptyDataError:
        return None
    if frame.empty:
        return None
    frame = frame.copy()
    frame["source_file"] = str(path)
    return frame


def load_dataset(label: str, files: list[Path], *, core_only: bool, key_cols: list[str]) -> pd.DataFrame:
    frames = [frame for path in files if (frame := read_csv(path)) is not None]
    if not frames:
        raise ValueError(f"{label}: no usable CSV rows")
    data = pd.concat(frames, ignore_index=True)

    missing_required = sorted(REQUIRED_BASE_COLUMNS - set(data.columns))
    if missing_required:
        raise ValueError(f"{label}: missing required columns: {', '.join(missing_required)}")
    missing_key = [col for col in key_cols if col not in data.columns]
    if missing_key:
        raise ValueError(f"{label}: missing key columns: {', '.join(missing_key)}")

    for col in sorted(REQUIRED_BASE_COLUMNS | set(key_cols)):
        data[col] = pd.to_numeric(data[col], errors="coerce")
    data = data.dropna(subset=["Tref_ps", "t_raw_ps", *key_cols]).copy()

    before_filter = len(data)
    if core_only:
        if "nslow" not in data.columns:
            raise ValueError("--core-only requires nslow column")
        data = data[data["nslow"] > 0].copy()
    data["offset_ps"] = data["Tref_ps"] - data["t_raw_ps"]
    data.attrs["label"] = label
    data.attrs["rows_before_filter"] = int(before_filter)
    data.attrs["rows_after_filter"] = int(len(data))
    print(
        f"[{label}] Loaded {len(files)} file(s), {len(data):,} usable row(s)"
        + (f" after filtering {before_filter - len(data):,} nslow==0 row(s)" if core_only else "")
    )
    return data


def rmse(values: pd.Series | np.ndarray) -> float:
    arr = np.asarray(values, dtype=float)
    if arr.size == 0:
        return float("nan")
    return float(math.sqrt(np.mean(np.square(arr))))


def metrics(errors: pd.Series | np.ndarray, label: str) -> dict[str, object]:
    arr = np.asarray(errors, dtype=float)
    if arr.size == 0:
        return {
            "label": label,
            "count": 0,
            "mean": float("nan"),
            "std": float("nan"),
            "rmse": float("nan"),
            "mae": float("nan"),
            "p50_ae": float("nan"),
            "p90_ae": float("nan"),
            "p95_ae": float("nan"),
            "p99_ae": float("nan"),
            "min": float("nan"),
            "max": float("nan"),
        }
    abs_arr = np.abs(arr)
    return {
        "label": label,
        "count": int(arr.size),
        "mean": float(np.mean(arr)),
        "std": float(np.std(arr)),
        "rmse": rmse(arr),
        "mae": float(np.mean(abs_arr)),
        "p50_ae": float(np.percentile(abs_arr, 50)),
        "p90_ae": float(np.percentile(abs_arr, 90)),
        "p95_ae": float(np.percentile(abs_arr, 95)),
        "p99_ae": float(np.percentile(abs_arr, 99)),
        "min": float(np.min(arr)),
        "max": float(np.max(arr)),
    }


def build_lut(train_df: pd.DataFrame, key_cols: list[str]) -> pd.DataFrame:
    lut = train_df.groupby(key_cols, dropna=False, observed=True)["offset_ps"].agg(["mean", "std", "count"])
    lut.columns = ["correction_ps", "within_std_ps", "train_count"]
    return lut.reset_index()


def apply_lut(eval_df: pd.DataFrame, lut: pd.DataFrame, key_cols: list[str]) -> pd.DataFrame:
    merged = eval_df.merge(lut, on=key_cols, how="left", copy=False)
    matched = merged["correction_ps"].notna()
    merged["matched"] = matched
    merged["cal_ps"] = merged["t_raw_ps"] + merged["correction_ps"]
    merged["raw_error_ps"] = merged["Tref_ps"] - merged["t_raw_ps"]
    merged["cal_error_ps"] = merged["Tref_ps"] - merged["cal_ps"]
    return merged


def oracle_floor(df: pd.DataFrame, key_cols: list[str], label: str) -> dict[str, object]:
    mean_tref = df.groupby(key_cols, dropna=False, observed=True)["Tref_ps"].transform("mean")
    return metrics(df["Tref_ps"] - mean_tref, label=f"oracle/{label}")


def ambiguity_bins(df: pd.DataFrame, key_cols: list[str]) -> pd.DataFrame:
    grouped = (
        df.groupby(key_cols, dropna=False, observed=True)
        .agg(
            rows=("Tref_ps", "size"),
            unique_tref=("Tref_ps", "nunique"),
            tref_min_ps=("Tref_ps", "min"),
            tref_max_ps=("Tref_ps", "max"),
            offset_std_ps=("offset_ps", "std"),
        )
        .reset_index()
    )
    grouped["tref_span_ps"] = grouped["tref_max_ps"] - grouped["tref_min_ps"]
    return grouped.sort_values(["unique_tref", "rows", "tref_span_ps"], ascending=[False, False, False])


def report_optional_key_floors(df: pd.DataFrame) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    for name, key_cols in OPTIONAL_REPORT_KEYS.items():
        if all(col in df.columns for col in key_cols):
            row = {
                "key_name": name,
                "key_cols": ",".join(key_cols),
                **oracle_floor(df, key_cols, name),
            }
            amb = ambiguity_bins(df, key_cols)
            row["unique_bins"] = int(len(amb))
            row["ambiguous_bins"] = int((amb["unique_tref"] > 1).sum())
            row["ambiguous_rows"] = int(amb.loc[amb["unique_tref"] > 1, "rows"].sum())
            rows.append(row)
    return rows


def safe_name(text: str) -> str:
    return re.sub(r"[^A-Za-z0-9_.-]+", "_", text).strip("_")


def write_report(summary: dict[str, object], key_floors: pd.DataFrame, out_path: Path) -> None:
    lines = [
        "=" * 80,
        "MPTDC Feature LUT Calibration v2",
        "=" * 80,
        "",
        f"Key columns: {', '.join(summary['key_cols'])}",
        f"Train rows : {summary['train_rows']}",
        f"Val rows   : {summary['val_rows']}",
        f"Coverage   : {summary['coverage']:.6f}",
        "",
        "Validation metrics",
        "-" * 80,
    ]
    for name in ("raw_metrics", "cal_metrics_matched", "oracle_floor_selected_key"):
        metric = summary[name]
        lines.append(
            f"{name:<28s} count={metric['count']:>10d} "
            f"rmse={metric['rmse']:>10.2f} ps  p99={metric['p99_ae']:>10.2f} ps  "
            f"mean={metric['mean']:>+10.2f} ps"
        )
    if not key_floors.empty:
        lines.extend(["", "Optional key oracle floors", "-" * 80])
        for _, row in key_floors.sort_values("rmse").iterrows():
            lines.append(
                f"{row['key_name']:<16s} rmse={row['rmse']:>10.2f} ps  "
                f"ambiguous_bins={int(row['ambiguous_bins']):>8d}  "
                f"ambiguous_rows={int(row['ambiguous_rows']):>10d}"
            )
    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def run_self_test() -> None:
    train = pd.DataFrame({
        "Tref_ps": [10, 20, 30, 40],
        "t_raw_ps": [15, 25, 35, 45],
        "nslow": [0, 0, 0, 0],
        "nfast_hit": [0, 1, 2, 3],
        "ns": [0, 0, 0, 0],
        "nf": [0, 0, 0, 0],
        "phase0_snap": [0, 0, 0, 0],
        "slow_boundary_inc": [0, 0, 0, 0],
        "hit_idx": [0, 0, 0, 0],
    })
    train["offset_ps"] = train["Tref_ps"] - train["t_raw_ps"]
    lut = build_lut(train, DEFAULT_KEY)
    val = apply_lut(train, lut, DEFAULT_KEY)
    assert val["matched"].all()
    assert metrics(val["cal_error_ps"], "self")["rmse"] == 0.0

    aliased = pd.concat([train, train.iloc[[1]].assign(Tref_ps=100, t_raw_ps=105)], ignore_index=True)
    aliased["offset_ps"] = aliased["Tref_ps"] - aliased["t_raw_ps"]
    assert oracle_floor(aliased, DEFAULT_KEY, "aliased")["rmse"] > 0.0
    print("calibrate_feature_lut_v2.py self-test PASS")


def main() -> int:
    args = parse_args()
    if args.self_test:
        run_self_test()
        return 0
    if not args.train_dir or not args.val_dir:
        raise SystemExit("[ERROR] --train-dir and --val-dir are required unless --self-test is used")

    key_cols = parse_key(args.key)
    train_files = discover_seed_csvs(args.train_dir, recursive=args.recursive, max_files=args.max_train_files)
    val_files = discover_seed_csvs(args.val_dir, recursive=args.recursive, max_files=args.max_val_files)

    train_df = load_dataset("train", train_files, core_only=args.core_only, key_cols=key_cols)
    val_df = load_dataset("validation", val_files, core_only=args.core_only, key_cols=key_cols)
    if train_df.empty or val_df.empty:
        raise SystemExit("[ERROR] Empty train or validation dataset after filtering")

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    lut = build_lut(train_df, key_cols)
    evaluated = apply_lut(val_df, lut, key_cols)
    matched = evaluated["matched"]
    raw_metrics = metrics(evaluated["raw_error_ps"], "validation/raw")
    cal_metrics = metrics(evaluated.loc[matched, "cal_error_ps"], "validation/cal_matched")
    selected_oracle = oracle_floor(val_df, key_cols, "selected_key")

    amb_train = ambiguity_bins(train_df, key_cols)
    amb_val = ambiguity_bins(val_df, key_cols)
    key_floors = pd.DataFrame.from_records(report_optional_key_floors(val_df))

    summary: dict[str, object] = {
        "key_cols": key_cols,
        "train_dir": args.train_dir,
        "val_dir": args.val_dir,
        "train_files": len(train_files),
        "val_files": len(val_files),
        "train_rows": int(len(train_df)),
        "val_rows": int(len(val_df)),
        "lut_bins": int(len(lut)),
        "matched_rows": int(matched.sum()),
        "unmatched_rows": int((~matched).sum()),
        "coverage": float(matched.mean()) if len(matched) else 0.0,
        "core_only": bool(args.core_only),
        "raw_metrics": raw_metrics,
        "cal_metrics_matched": cal_metrics,
        "oracle_floor_selected_key": selected_oracle,
    }

    lut.to_csv(out_dir / "feature_lut_v2.csv", index=False)
    evaluated.to_csv(out_dir / "validation_feature_lut_v2.csv", index=False)
    amb_train.to_csv(out_dir / "ambiguity_bins_train.csv", index=False)
    amb_val.to_csv(out_dir / "ambiguity_bins_validation.csv", index=False)
    if not key_floors.empty:
        key_floors.to_csv(out_dir / "optional_key_oracle_floors.csv", index=False)
    (out_dir / "summary_report_v2.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    write_report(summary, key_floors, out_dir / "summary_report_v2.txt")

    print(f"[INFO] LUT bins: {len(lut):,}")
    print(f"[INFO] Validation coverage: {summary['coverage']:.6f}")
    print(f"[INFO] Raw RMSE: {raw_metrics['rmse']:.2f} ps")
    print(f"[INFO] Calibrated RMSE matched: {cal_metrics['rmse']:.2f} ps")
    print(f"[INFO] Selected-key oracle floor: {selected_oracle['rmse']:.2f} ps")
    print(f"[INFO] Wrote {out_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
