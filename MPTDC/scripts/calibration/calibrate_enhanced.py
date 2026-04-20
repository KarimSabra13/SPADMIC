#!/usr/bin/env python3
# ==============================================================================
#  MPTDC Enhanced Calibration – Multi-Method Comparison
# ==============================================================================
#  Implements and compares multiple calibration strategies for the Vernier TDC:
#
#   1. 6D LUT (mean)          – baseline, compatible with calibrate_6d_lut.py
#   2. 6D LUT (median)        – robust to outliers
#   3. 6D LUT (trimmed mean)  – 10 % tails trimmed
#   4. 7D LUT (+ nfast_stop)  – additional dimension (optional)
#   5. Polynomial regression   – degree 2 and 3 Ridge regression
#   6. Gradient-Boosted        – GradientBoostingRegressor
#   7. Quality-gated averaging – weighted multi-hit fusion
#   8. Temporal re-keying      – LUT keyed on temporal hit order
#
#  Train/test split is by conv_id (80/20) to avoid data leakage.
#
#  Usage:
#    python3 calibrate_enhanced.py --input data.csv --out-dir results/
#    python3 calibrate_enhanced.py --input data.csv --out-dir results/ --nfast-stop
#
#  Author : Karim Sabra
# ==============================================================================

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import warnings

import numpy as np
import pandas as pd

# Vernier algebra constants (must match calibrate_6d_lut.py)
K_SLOW    = 99
K_FAST    = 9
K_VERNIER = 11
OFFSET    = 25
QUANT     = 10  # ps per LSB

# 6D LUT key (same as calibrate_6d_lut.py)
LUT_KEY_6D = ["ns_inf", "nf_inf", "nslow", "nfast_hit", "phase0_snap", "hit_idx"]

# Continuous feature columns for regression models
REGRESSION_FEATURES = [
    "nslow", "nfast_hit", "ns_inf", "nf_inf",
    "nfast_snap", "phase0_snap", "slow_boundary_inc",
]

GB_FEATURES = REGRESSION_FEATURES + ["hit_idx"]


# ── Vernier ns/nf recovery ────────────────────────────────────────────────────

def _build_nsnf_reverse_lut() -> dict[int, tuple[int, int]]:
    lut = {}
    for ns in range(9):
        for nf in range(9):
            lut[ns * K_VERNIER - nf * (K_VERNIER - 1)] = (ns, nf)
    assert len(lut) == 81
    return lut

_NSNF_REV = _build_nsnf_reverse_lut()


def infer_ns_nf(df: pd.DataFrame) -> pd.DataFrame:
    """Deterministically recover (ns, nf) from compact-mode fields."""
    coef  = df["t_raw_ps"] // QUANT
    resid = (coef
             - (df["nslow"] + 2 + df["slow_boundary_inc"] - 1) * K_SLOW
             - df["nfast_hit"] * K_FAST
             - OFFSET)
    df["ns_inf"] = resid.map(lambda r: _NSNF_REV.get(r, (None, None))[0]).astype("Int64")
    df["nf_inf"] = resid.map(lambda r: _NSNF_REV.get(r, (None, None))[1]).astype("Int64")
    return df


# ── Data loading ──────────────────────────────────────────────────────────────

def load_csv(path: str) -> pd.DataFrame:
    """Load CSV, infer ns/nf, compute offset, apply core filter."""
    df = pd.read_csv(path)
    n_raw = len(df)

    # Active compact CSVs omit the legacy repeated-snapshot fields. Keep the
    # historical model sweep runnable by synthesizing zero-valued compatibility
    # columns when they are absent.
    if "nfast_snap" not in df.columns:
        df["nfast_snap"] = 0
    if "nfast_stop" not in df.columns:
        df["nfast_stop"] = 0

    # Core filter: drop nslow == 0
    df = df[df["nslow"] > 0].copy()
    print(f"  Loaded {n_raw:,} rows → {len(df):,} after core filter (nslow > 0)")

    # Compute ground-truth offset (correction target)
    df["offset"] = df["Tref_ps"] - df["t_raw_ps"]

    # Infer ns/nf from Vernier algebra
    infer_ns_nf(df)
    bad = df["ns_inf"].isna().sum()
    if bad:
        print(f"  WARNING: {bad} rows failed ns/nf inference – dropped")
        df = df.dropna(subset=["ns_inf", "nf_inf"])

    # Ensure integer types for LUT keys
    for col in ["ns_inf", "nf_inf", "nslow", "nfast_hit", "phase0_snap",
                "hit_idx", "nfast_stop", "nfast_snap", "slow_boundary_inc"]:
        if col in df.columns:
            df[col] = df[col].astype(int)

    return df


# ── Train / test split by conv_id ─────────────────────────────────────────────

def split_by_conv_id(df: pd.DataFrame, test_frac: float = 0.20,
                     seed: int = 42) -> tuple[pd.DataFrame, pd.DataFrame]:
    """80/20 split by conv_id to keep conversions intact."""
    rng = np.random.RandomState(seed)
    conv_ids = df["conv_id"].unique()
    rng.shuffle(conv_ids)
    n_test = max(1, int(len(conv_ids) * test_frac))
    test_ids = set(conv_ids[:n_test])
    mask = df["conv_id"].isin(test_ids)
    return df[~mask].copy(), df[mask].copy()


# ── Metrics ───────────────────────────────────────────────────────────────────

def compute_metrics(errors: np.ndarray) -> dict:
    if len(errors) == 0:
        return {
            "rmse": float("nan"), "mae": float("nan"),
            "p90": float("nan"), "p99": float("nan"),
            "count": 0, "mean": float("nan"), "std": float("nan"),
        }
    ae = np.abs(errors)
    return {
        "rmse":   float(np.sqrt(np.mean(errors ** 2))),
        "mae":    float(np.mean(ae)),
        "p90":    float(np.percentile(ae, 90)),
        "p99":    float(np.percentile(ae, 99)),
        "count":  int(len(errors)),
        "mean":   float(np.mean(errors)),
        "std":    float(np.std(errors)),
    }


# ── LUT helpers ───────────────────────────────────────────────────────────────

def _trimmed_mean(series: pd.Series, trim_frac: float = 0.10) -> float:
    """Compute symmetrically-trimmed mean, trimming `trim_frac` from each tail."""
    arr = series.values
    n = len(arr)
    k = int(n * trim_frac)
    if n < 3 or k < 1:
        return float(np.mean(arr))
    sorted_arr = np.sort(arr)
    return float(np.mean(sorted_arr[k : n - k]))


def build_lut(train: pd.DataFrame, key_cols: list[str],
              agg: str = "mean") -> pd.DataFrame:
    """Build a LUT with the specified aggregation (mean / median / trimmed)."""
    grp = train.groupby(key_cols)["offset"]
    if agg == "mean":
        lut = grp.agg(correction="mean", within_std="std", train_count="count")
    elif agg == "median":
        lut = grp.agg(correction="median", within_std="std", train_count="count")
    elif agg == "trimmed":
        lut = grp.agg(
            correction=lambda s: _trimmed_mean(s, 0.10),
            within_std="std",
            train_count="count",
        )
    else:
        raise ValueError(f"Unknown agg: {agg}")
    return lut


def apply_lut(df: pd.DataFrame, lut: pd.DataFrame,
              key_cols: list[str]) -> np.ndarray:
    """Apply LUT, return calibrated errors (Tref - calibrated). NaN for misses."""
    merged = df.set_index(key_cols).join(lut["correction"], how="left").reset_index()
    cal_ps = merged["t_raw_ps"] + merged["correction"]
    errors = merged["Tref_ps"] - cal_ps
    return errors.values


def evaluate_lut(train: pd.DataFrame, test: pd.DataFrame,
                 key_cols: list[str], agg: str,
                 label: str) -> dict:
    """Build LUT on train, evaluate on both train and test."""
    lut = build_lut(train, key_cols, agg)
    bin_stats = {
        "n_bins":       len(lut),
        "median_pop":   float(lut["train_count"].median()),
        "min_pop":      int(lut["train_count"].min()),
    }

    train_err = apply_lut(train, lut, key_cols)
    test_err  = apply_lut(test,  lut, key_cols)

    # Coverage
    train_cov = float(np.isfinite(train_err).mean())
    test_cov  = float(np.isfinite(test_err).mean())

    # Drop NaN for metrics
    train_err = train_err[np.isfinite(train_err)]
    test_err  = test_err[np.isfinite(test_err)]

    return {
        "label":      label,
        "train":      compute_metrics(train_err),
        "test":       compute_metrics(test_err),
        "train_cov":  train_cov,
        "test_cov":   test_cov,
        **bin_stats,
    }


# ── Polynomial regression ────────────────────────────────────────────────────

def evaluate_polynomial(train: pd.DataFrame, test: pd.DataFrame,
                        degree: int) -> dict:
    """Fit Ridge regression with polynomial features on continuous vars."""
    from sklearn.linear_model import Ridge
    from sklearn.preprocessing import PolynomialFeatures, StandardScaler
    from sklearn.pipeline import make_pipeline

    label = f"Polynomial (deg {degree})"
    feats = REGRESSION_FEATURES

    X_train = train[feats].values.astype(np.float64)
    y_train = train["offset"].values.astype(np.float64)
    X_test  = test[feats].values.astype(np.float64)
    y_test  = test["offset"].values.astype(np.float64)

    pipe = make_pipeline(
        StandardScaler(),
        PolynomialFeatures(degree=degree, interaction_only=False, include_bias=False),
        Ridge(alpha=1.0),
    )
    pipe.fit(X_train, y_train)

    pred_train = pipe.predict(X_train)
    pred_test  = pipe.predict(X_test)

    train_err = y_train - pred_train  # residual after correction
    test_err  = y_test  - pred_test

    return {
        "label": label,
        "train": compute_metrics(train_err),
        "test":  compute_metrics(test_err),
        "n_features": int(pipe.named_steps["polynomialfeatures"].n_output_features_),
    }


# ── Gradient-Boosted regression ───────────────────────────────────────────────

def evaluate_gradient_boosted(train: pd.DataFrame,
                              test: pd.DataFrame) -> dict:
    """Fit GradientBoostingRegressor and report metrics."""
    from sklearn.ensemble import GradientBoostingRegressor

    label = "GradientBoosted"
    feats = GB_FEATURES

    X_train = train[feats].values.astype(np.float64)
    y_train = train["offset"].values.astype(np.float64)
    X_test  = test[feats].values.astype(np.float64)
    y_test  = test["offset"].values.astype(np.float64)

    # Subsample training if very large (GB is slow)
    max_train = 500_000
    if len(X_train) > max_train:
        rng = np.random.RandomState(0)
        idx = rng.choice(len(X_train), max_train, replace=False)
        X_train_fit = X_train[idx]
        y_train_fit = y_train[idx]
        print(f"  GBR: subsampled training to {max_train:,} rows")
    else:
        X_train_fit = X_train
        y_train_fit = y_train

    gbr = GradientBoostingRegressor(
        n_estimators=300,
        max_depth=5,
        learning_rate=0.1,
        subsample=0.8,
        min_samples_leaf=20,
        random_state=42,
    )
    gbr.fit(X_train_fit, y_train_fit)

    pred_train = gbr.predict(X_train)
    pred_test  = gbr.predict(X_test)

    train_err = y_train - pred_train
    test_err  = y_test  - pred_test

    # Feature importances
    importances = dict(zip(feats, gbr.feature_importances_.tolist()))

    return {
        "label": label,
        "train": compute_metrics(train_err),
        "test":  compute_metrics(test_err),
        "feature_importances": importances,
        "n_estimators": gbr.n_estimators,
        "max_depth": gbr.max_depth,
    }


# ── Quality-gated multi-hit averaging ────────────────────────────────────────

def evaluate_quality_gated(train: pd.DataFrame, test: pd.DataFrame,
                           key_cols: list[str]) -> dict:
    """
    After per-hit LUT calibration, do quality-weighted and trimmed averaging
    across hits within each conversion. Report per-conversion RMSE for
    different hit budgets.
    """
    lut = build_lut(train, key_cols, agg="mean")

    # Apply LUT to test data
    merged = test.set_index(key_cols).join(lut[["correction", "train_count"]],
                                           how="left").reset_index()
    merged["cal_ps"]   = merged["t_raw_ps"] + merged["correction"]
    merged["error_ps"] = merged["Tref_ps"]  - merged["cal_ps"]

    # Drop unmatched
    merged = merged.dropna(subset=["correction"]).copy()

    # Per-hit weight = 1 / estimated_variance. Use inverse bin population as proxy.
    merged["weight"] = 1.0 / np.maximum(merged["train_count"].values, 1).astype(float)

    hit_budgets = [1, 3, 5, 10, 15]
    results_uniform  = {}
    results_weighted = {}
    results_trimmed  = {}

    for budget in hit_budgets:
        # Take first `budget` hits per conv_id (by hit_idx order)
        subset = (merged.sort_values(["conv_id", "hit_idx"])
                  .groupby("conv_id")
                  .head(budget))

        # ── Uniform average ──
        conv_mean = subset.groupby("conv_id").agg(
            avg_error=("error_ps", "mean"),
            tref=("Tref_ps", "first"),
        )
        results_uniform[budget] = compute_metrics(conv_mean["avg_error"].values)

        # ── Weighted average (1/bin_pop) ──
        def _wmean(g):
            w = g["weight"].values
            e = g["error_ps"].values
            return np.average(e, weights=w)

        conv_wmean = subset.groupby("conv_id").apply(_wmean, include_groups=False)
        results_weighted[budget] = compute_metrics(conv_wmean.values)

        # ── Trimmed average (drop worst 20% of hits per conversion) ──
        def _trimmed(g):
            errs = g["error_ps"].values
            n = len(errs)
            if n <= 2:
                return np.mean(errs)
            k = max(1, int(n * 0.20))
            idx_sorted = np.argsort(np.abs(errs))
            return np.mean(errs[idx_sorted[:n - k]])

        conv_trimmed = subset.groupby("conv_id").apply(_trimmed, include_groups=False)
        results_trimmed[budget] = compute_metrics(conv_trimmed.values)

    return {
        "label": "Quality-Gated Averaging",
        "uniform":  results_uniform,
        "weighted": results_weighted,
        "trimmed":  results_trimmed,
    }


# ── Temporal re-keying ────────────────────────────────────────────────────────

def evaluate_temporal_rekey(train: pd.DataFrame,
                            test: pd.DataFrame) -> dict:
    """
    Sort hits within each conversion by nfast_hit (ascending = temporal order),
    assign temporal_hit_idx, re-key the LUT using temporal index.
    """
    def _assign_temporal(df: pd.DataFrame) -> pd.DataFrame:
        df = df.sort_values(["conv_id", "nfast_hit"]).copy()
        df["temporal_hit_idx"] = df.groupby("conv_id").cumcount()
        return df

    train_t = _assign_temporal(train)
    test_t  = _assign_temporal(test)

    key_temporal = ["ns_inf", "nf_inf", "nslow", "nfast_hit",
                    "phase0_snap", "temporal_hit_idx"]

    lut = build_lut(train_t, key_temporal, agg="mean")

    train_err = apply_lut(train_t, lut, key_temporal)
    test_err  = apply_lut(test_t,  lut, key_temporal)

    train_cov = float(np.isfinite(train_err).mean())
    test_cov  = float(np.isfinite(test_err).mean())

    train_err = train_err[np.isfinite(train_err)]
    test_err  = test_err[np.isfinite(test_err)]

    return {
        "label":     "Temporal Re-Keyed LUT",
        "train":     compute_metrics(train_err),
        "test":      compute_metrics(test_err),
        "train_cov": train_cov,
        "test_cov":  test_cov,
    }


# ── Pretty-print comparison table ────────────────────────────────────────────

def print_comparison_table(results: list[dict]) -> str:
    """Print and return a formatted comparison table."""
    header = (f"{'Method':<30s} | {'Train RMSE':>10s} | {'Test RMSE':>10s} "
              f"| {'Test MAE':>10s} | {'Test P90':>10s} | {'Test P99':>10s}")
    sep    = "-" * len(header)
    lines  = [sep, header, sep]

    for r in results:
        tr = r.get("train", {})
        te = r.get("test", {})
        lines.append(
            f"{r['label']:<30s} | {tr.get('rmse', float('nan')):>10.2f} "
            f"| {te.get('rmse', float('nan')):>10.2f} "
            f"| {te.get('mae', float('nan')):>10.2f} "
            f"| {te.get('p90', float('nan')):>10.2f} "
            f"| {te.get('p99', float('nan')):>10.2f}"
        )

    lines.append(sep)
    table = "\n".join(lines)
    print(table)
    return table


def print_averaging_table(avg_result: dict) -> str:
    """Print quality-gated averaging summary."""
    header = (f"{'Hits':<6s} | {'Uniform RMSE':>12s} | {'Weighted RMSE':>13s} "
              f"| {'Trimmed RMSE':>13s}")
    sep = "-" * len(header)
    lines = ["\n  Quality-Gated Multi-Hit Averaging (per-conversion)", sep, header, sep]

    for budget in sorted(avg_result["uniform"].keys()):
        u = avg_result["uniform"][budget]["rmse"]
        w = avg_result["weighted"][budget]["rmse"]
        t = avg_result["trimmed"][budget]["rmse"]
        lines.append(f"{budget:<6d} | {u:>12.2f} | {w:>13.2f} | {t:>13.2f}")

    lines.append(sep)
    table = "\n".join(lines)
    print(table)
    return table


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="MPTDC Enhanced Calibration – Multi-Method Comparison")
    parser.add_argument("--input", required=True,
                        help="Input CSV path (or glob pattern for multiple files)")
    parser.add_argument("--out-dir", default="results/calibration_enhanced",
                        help="Output directory for JSON results")
    parser.add_argument("--nfast-stop", action="store_true",
                        help="Enable 7D LUT methods using nfast_stop column")
    parser.add_argument("--test-frac", type=float, default=0.20,
                        help="Fraction of conv_ids for test set (default 0.20)")
    parser.add_argument("--seed", type=int, default=42,
                        help="Random seed for train/test split")
    parser.add_argument("--skip-gb", action="store_true",
                        help="Skip GradientBoosted (slow on large data)")
    args = parser.parse_args()

    os.makedirs(args.out_dir, exist_ok=True)
    t0 = time.time()

    print("=" * 70)
    print("  MPTDC Enhanced Calibration – Multi-Method Comparison")
    print("=" * 70)

    # ── Load data ─────────────────────────────────────────────────────────
    import glob as globmod
    csv_files = sorted(globmod.glob(args.input))
    if not csv_files:
        # Try as single file
        if os.path.isfile(args.input):
            csv_files = [args.input]
        else:
            print(f"ERROR: no files matching '{args.input}'", file=sys.stderr)
            sys.exit(1)

    print(f"\n[1/8] Loading {len(csv_files)} CSV file(s)...")
    frames = [load_csv(f) for f in csv_files]
    df = pd.concat(frames, ignore_index=True)
    print(f"  Total rows after merge: {len(df):,}")

    # ── Train/test split ──────────────────────────────────────────────────
    print(f"\n[2/8] Splitting by conv_id ({1 - args.test_frac:.0%} / {args.test_frac:.0%})...")
    train, test = split_by_conv_id(df, test_frac=args.test_frac, seed=args.seed)
    print(f"  Train: {len(train):,} rows  ({train['conv_id'].nunique():,} conversions)")
    print(f"  Test:  {len(test):,} rows  ({test['conv_id'].nunique():,} conversions)")
    del df  # free memory

    all_results = []

    # ── Method 1: 6D LUT (mean) – baseline ───────────────────────────────
    print("\n[3/8] 6D LUT (mean) – baseline...")
    r = evaluate_lut(train, test, LUT_KEY_6D, "mean", "6D LUT (mean)")
    all_results.append(r)
    print(f"  Test RMSE = {r['test']['rmse']:.2f} ps  "
          f"(coverage: {r['test_cov']:.2%})")

    # ── Method 2a: 6D LUT (median) ───────────────────────────────────────
    print("\n[4/8] 6D LUT (median)...")
    r = evaluate_lut(train, test, LUT_KEY_6D, "median", "6D LUT (median)")
    all_results.append(r)
    print(f"  Test RMSE = {r['test']['rmse']:.2f} ps")

    # ── Method 2b: 6D LUT (trimmed mean) ─────────────────────────────────
    print("       6D LUT (trimmed mean 10%)...")
    r = evaluate_lut(train, test, LUT_KEY_6D, "trimmed", "6D LUT (trimmed mean)")
    all_results.append(r)
    print(f"  Test RMSE = {r['test']['rmse']:.2f} ps")

    # ── Method 3: 7D LUT (+ nfast_stop) ──────────────────────────────────
    if args.nfast_stop:
        print("\n[4b/8] 7D LUT (mean + nfast_stop)...")
        key_7d = LUT_KEY_6D + ["nfast_stop"]
        r = evaluate_lut(train, test, key_7d, "mean",
                         "7D LUT (mean + nfast_stop)")
        all_results.append(r)
        print(f"  Test RMSE = {r['test']['rmse']:.2f} ps  "
              f"(coverage: {r['test_cov']:.2%}, bins: {r['n_bins']:,})")
    else:
        print("\n       7D LUT skipped (use --nfast-stop to enable)")

    # ── Method 4: Polynomial regression ───────────────────────────────────
    print("\n[5/8] Polynomial regression (deg 2)...")
    r2 = evaluate_polynomial(train, test, degree=2)
    all_results.append(r2)
    print(f"  Test RMSE = {r2['test']['rmse']:.2f} ps  "
          f"({r2['n_features']} features)")

    print("       Polynomial regression (deg 3)...")
    r3 = evaluate_polynomial(train, test, degree=3)
    all_results.append(r3)
    print(f"  Test RMSE = {r3['test']['rmse']:.2f} ps  "
          f"({r3['n_features']} features)")

    # ── Method 5: Gradient-Boosted ────────────────────────────────────────
    if not args.skip_gb:
        print("\n[6/8] Gradient-Boosted regression...")
        r_gb = evaluate_gradient_boosted(train, test)
        all_results.append(r_gb)
        print(f"  Test RMSE = {r_gb['test']['rmse']:.2f} ps")
        print(f"  Feature importances: "
              + ", ".join(f"{k}={v:.3f}" for k, v in
                          sorted(r_gb["feature_importances"].items(),
                                 key=lambda x: -x[1])))
    else:
        print("\n[6/8] GradientBoosted skipped (--skip-gb)")

    # ── Method 6: Temporal re-keying ──────────────────────────────────────
    print("\n[7/8] Temporal re-keying LUT...")
    r_temp = evaluate_temporal_rekey(train, test)
    all_results.append(r_temp)
    print(f"  Test RMSE = {r_temp['test']['rmse']:.2f} ps  "
          f"(coverage: {r_temp['test_cov']:.2%})")

    # ── Comparison table ──────────────────────────────────────────────────
    print("\n" + "=" * 70)
    print("  COMPARISON TABLE")
    print("=" * 70 + "\n")
    table_str = print_comparison_table(all_results)

    # ── Method 7: Quality-gated averaging ─────────────────────────────────
    print("\n[8/8] Quality-gated multi-hit averaging...")
    avg_result = evaluate_quality_gated(train, test, LUT_KEY_6D)
    avg_table_str = print_averaging_table(avg_result)

    # ── Save JSON report ──────────────────────────────────────────────────
    elapsed = time.time() - t0
    report = {
        "timestamp":    time.strftime("%Y-%m-%dT%H:%M:%S"),
        "elapsed_s":    round(elapsed, 1),
        "input_files":  csv_files,
        "test_frac":    args.test_frac,
        "seed":         args.seed,
        "nfast_stop":   args.nfast_stop,
        "train_rows":   int(len(train)),
        "test_rows":    int(len(test)),
        "methods":      all_results,
        "averaging":    {
            "uniform":  {str(k): v for k, v in avg_result["uniform"].items()},
            "weighted": {str(k): v for k, v in avg_result["weighted"].items()},
            "trimmed":  {str(k): v for k, v in avg_result["trimmed"].items()},
        },
    }

    json_path = os.path.join(args.out_dir, "enhanced_calibration_results.json")
    with open(json_path, "w") as f:
        json.dump(report, f, indent=2, default=str)

    print(f"\n  Results saved: {json_path}")
    print(f"  Elapsed: {elapsed:.1f} s")
    print("=" * 70)


if __name__ == "__main__":
    main()
