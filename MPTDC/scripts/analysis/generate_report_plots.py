#!/usr/bin/env python3
"""Generate the final report figures from the maintained MPTDC flow.

Inputs are the canonical characterization outputs produced by
scripts/sim/run_report_flow.sh or by the equivalent manual sequence:

* baseline characterization root with analysis/calibration;
* optional focused root with analysis/linearity and boundary tables.

The script does not rerun simulations. It only republishes selected tables into
French-labeled PNG/PDF figures and writes a JSON manifest.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from plot_style import PALETTE, apply_report_style, style_axes


ERROR_BINS_PS = np.linspace(-3200.0, 3200.0, 321)
ABS_ERROR_BINS_PS = np.linspace(0.0, 200.0, 401)


def resolve_char_root(path: Path) -> Path:
    path = path.resolve()
    if (path / "analysis" / "calibration").is_dir():
        return path
    if (path / "characterization" / "analysis" / "calibration").is_dir():
        return path / "characterization"
    raise FileNotFoundError(
        f"Cannot locate characterization analysis/calibration under {path}"
    )


def read_json(path: Path) -> dict:
    if not path.exists():
        raise FileNotFoundError(path)
    return json.loads(path.read_text(encoding="utf-8"))


def save_current_figure(fig, out_dir: Path, stem: str) -> list[str]:
    out_dir.mkdir(parents=True, exist_ok=True)
    paths = []
    for ext in ("png", "pdf"):
        out_path = out_dir / f"{stem}.{ext}"
        fig.savefig(out_path, bbox_inches="tight")
        paths.append(str(out_path))
    plt.close(fig)
    return paths


def load_error_histograms(csv_path: Path) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    if not csv_path.exists():
        raise FileNotFoundError(csv_path)
    raw_hist = np.zeros(len(ERROR_BINS_PS) - 1, dtype=np.int64)
    cal_hist = np.zeros(len(ERROR_BINS_PS) - 1, dtype=np.int64)
    abs_cal_hist = np.zeros(len(ABS_ERROR_BINS_PS) - 1, dtype=np.int64)
    usecols = ["raw_error_ps", "error_ps"]
    for chunk in pd.read_csv(csv_path, usecols=usecols, chunksize=750_000):
        raw = pd.to_numeric(chunk["raw_error_ps"], errors="coerce").dropna().to_numpy()
        cal = pd.to_numeric(chunk["error_ps"], errors="coerce").dropna().to_numpy()
        raw_hist += np.histogram(raw, bins=ERROR_BINS_PS)[0]
        cal_hist += np.histogram(cal, bins=ERROR_BINS_PS)[0]
        abs_cal_hist += np.histogram(np.abs(cal), bins=ABS_ERROR_BINS_PS)[0]
    return raw_hist, cal_hist, abs_cal_hist


def plot_error_histogram(csv_path: Path, out_dir: Path, manifest: dict) -> None:
    raw_hist, cal_hist, _ = load_error_histograms(csv_path)
    centers = 0.5 * (ERROR_BINS_PS[:-1] + ERROR_BINS_PS[1:])
    raw_den = raw_hist / max(raw_hist.sum(), 1)
    cal_den = cal_hist / max(cal_hist.sum(), 1)

    fig, ax = plt.subplots(figsize=(8.2, 4.8))
    ax.step(centers, raw_den, where="mid", color=PALETTE["gray"], label="Avant LUT")
    ax.step(centers, cal_den, where="mid", color=PALETTE["blue"], label="Apres LUT")
    ax.set_xlabel("Erreur temporelle (ps)")
    ax.set_ylabel("Probabilite")
    ax.set_title("Distribution de l'erreur avant/apres calibration")
    ax.set_xlim(-3200, 3200)
    ax.legend()
    style_axes(ax)
    manifest["figures"]["error_histogram_pre_post"] = save_current_figure(
        fig, out_dir, "01_erreur_histogramme_pre_post_lut"
    )


def plot_abs_error_cdf(csv_path: Path, out_dir: Path, manifest: dict) -> None:
    _, _, abs_cal_hist = load_error_histograms(csv_path)
    centers = 0.5 * (ABS_ERROR_BINS_PS[:-1] + ABS_ERROR_BINS_PS[1:])
    cdf = np.cumsum(abs_cal_hist) / max(abs_cal_hist.sum(), 1)

    fig, ax = plt.subplots(figsize=(7.4, 4.6))
    ax.plot(centers, cdf, color=PALETTE["blue"])
    for x in (10, 20, 40):
        ax.axvline(x, color=PALETTE["gray"], linestyle="--", linewidth=0.8)
    ax.set_xlabel("Erreur absolue post-LUT (ps)")
    ax.set_ylabel("Fonction de repartition")
    ax.set_title("CDF de l'erreur absolue calibree")
    ax.set_xlim(0, 120)
    ax.set_ylim(0, 1.002)
    style_axes(ax)
    manifest["figures"]["post_lut_abs_error_cdf"] = save_current_figure(
        fig, out_dir, "02_cdf_erreur_absolue_post_lut"
    )


def plot_averaging(cal_report: dict, out_dir: Path, manifest: dict) -> None:
    rows = cal_report.get("averaging_study", {}).get("results", [])
    if not rows:
        manifest["warnings"].append("No averaging_study.results found in calibration report")
        return
    df = pd.DataFrame(rows)
    fig, ax = plt.subplots(figsize=(7.4, 4.6))
    ax.plot(df["N"], df["rmse_ps"], marker="o", label="RMSE", color=PALETTE["blue"])
    ax.plot(df["N"], df["mae_ps"], marker="s", label="MAE", color=PALETTE["green"])
    ax.plot(df["N"], df["p90_ps"], marker="^", label="P90", color=PALETTE["orange"])
    ax.axhline(10, color=PALETTE["gray"], linestyle="--", linewidth=0.9, label="10 ps")
    ax.axhline(5, color=PALETTE["red"], linestyle=":", linewidth=0.9, label="5 ps")
    ax.set_xscale("log")
    ax.set_xlabel("Nombre de mesures moyennees N")
    ax.set_ylabel("Erreur (ps)")
    ax.set_title("Reduction statistique de l'erreur par moyennage")
    ax.legend(ncol=2)
    style_axes(ax)
    manifest["figures"]["averaging_rmse"] = save_current_figure(
        fig, out_dir, "03_rmse_vs_moyennage"
    )


def find_linearity_tables(focused_root: Path | None, char_root: Path) -> Path | None:
    candidates = []
    if focused_root is not None:
        candidates.extend([
            focused_root / "analysis" / "linearity" / "tables",
            focused_root / "linearity" / "tables",
        ])
    candidates.extend([
        char_root / "analysis" / "linearity" / "tables",
        char_root / "linearity" / "tables",
    ])
    for candidate in candidates:
        if (candidate / "observable_dnl_inl.csv").exists():
            return candidate
    return None


def plot_dnl_inl(tables_dir: Path, out_dir: Path, manifest: dict) -> None:
    df = pd.read_csv(tables_dir / "observable_dnl_inl.csv")
    fig, axes = plt.subplots(2, 1, figsize=(8.2, 6.0), sharex=True)
    axes[0].bar(df["scalar_bin"], df["dnl_lsb"], width=6.0, color=PALETTE["blue"])
    axes[0].set_ylabel("DNL (LSB)")
    axes[0].set_title("DNL/INL observables sur les codes atteints")
    style_axes(axes[0], grid_axis="y")
    axes[1].plot(df["scalar_bin"], df["inl_endpoint_lsb"], color=PALETTE["orange"])
    axes[1].set_xlabel("Code scalaire observe")
    axes[1].set_ylabel("INL endpoint (LSB)")
    style_axes(axes[1])
    manifest["figures"]["observable_dnl_inl"] = save_current_figure(
        fig, out_dir, "04_dnl_inl_observable"
    )


def plot_transfer(tables_dir: Path, out_dir: Path, manifest: dict) -> None:
    path = tables_dir / "transfer_linearity.csv"
    if not path.exists():
        manifest["warnings"].append(f"Missing transfer table: {path}")
        return
    df = pd.read_csv(path)
    x = df["true_mean_ps"] / 1000.0
    fig, axes = plt.subplots(2, 1, figsize=(8.2, 6.0), sharex=True)
    axes[0].plot(x, df["raw_mean_ps"], marker=".", linestyle="-", color=PALETTE["blue"])
    axes[0].plot(x, df["endpoint_line_ps"], linestyle="--", color=PALETTE["gray"], label="Droite endpoint")
    axes[0].set_ylabel("Temps brut moyen (ps)")
    axes[0].set_title("Linearite de transfert brute")
    axes[0].legend()
    style_axes(axes[0])
    axes[1].plot(x, df["endpoint_inl_lsb"], color=PALETTE["orange"], label="Endpoint")
    if "bestfit_inl_lsb" in df:
        axes[1].plot(x, df["bestfit_inl_lsb"], color=PALETTE["green"], label="Best-fit")
    axes[1].set_xlabel("Temps vrai moyen (ns)")
    axes[1].set_ylabel("INL de transfert (LSB)")
    axes[1].legend()
    style_axes(axes[1])
    manifest["figures"]["transfer_linearity"] = save_current_figure(
        fig, out_dir, "05_linearite_transfert"
    )


def find_boundary_table(focused_root: Path | None, char_root: Path) -> Path | None:
    candidates = []
    if focused_root is not None:
        candidates.extend([
            focused_root / "analysis" / "tables" / "boundary_summary.csv",
            focused_root / "tables" / "boundary_summary.csv",
        ])
    candidates.append(char_root / "analysis" / "tables" / "boundary_summary.csv")
    for candidate in candidates:
        if candidate.exists():
            return candidate
    return None


def plot_boundary(path: Path, out_dir: Path, manifest: dict) -> None:
    df = pd.read_csv(path)
    fig, ax = plt.subplots(figsize=(7.6, 4.6))
    ax.plot(df["boundary_offset_ps"], df["erreur_rms_ps"], marker="o",
            color=PALETTE["blue"], label="RMS brute")
    ax.plot(df["boundary_offset_ps"], df["erreur_moy_ps"], marker="s",
            color=PALETTE["orange"], label="Moyenne brute")
    ax.set_xlabel("Offset autour de la frontiere lente (ps)")
    ax.set_ylabel("Erreur brute (ps)")
    ax.set_title("Stress des frontieres temporelles")
    ax.legend()
    style_axes(ax)
    manifest["figures"]["boundary_sweep"] = save_current_figure(
        fig, out_dir, "06_boundary_offset_sweep"
    )


def write_metrics_tables(cal_report: dict, char_root: Path, out_dir: Path, manifest: dict) -> None:
    tables_dir = out_dir / "tables"
    tables_dir.mkdir(parents=True, exist_ok=True)
    held = cal_report.get("held_out_validation", {})
    rows = []
    for key, label in (("pre_cal", "Avant LUT"), ("post_cal", "Apres LUT")):
        data = held.get(key, {})
        if data:
            row = {"cas": label}
            for metric in ("count", "mean", "std", "rmse", "mae", "p50_ae", "p90_ae", "p95_ae", "p99_ae", "min", "max"):
                if metric in data:
                    row[metric] = data[metric]
            rows.append(row)
    if rows:
        path = tables_dir / "calibration_pre_post_summary.csv"
        pd.DataFrame(rows).to_csv(path, index=False)
        manifest["tables"]["calibration_pre_post_summary"] = str(path)

    sweep_report = char_root / "analysis" / "sweep" / "summary_report.json"
    if sweep_report.exists():
        manifest["source_reports"]["sweep_summary"] = str(sweep_report)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--char-root", required=True,
                        help="Baseline characterization root or parent containing characterization/")
    parser.add_argument("--focused-root", default="",
                        help="Optional focused characterization root containing analysis/linearity and boundary tables")
    parser.add_argument("--output-dir", required=True,
                        help="Directory for final report figures and manifest")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    apply_report_style()
    plt.rcParams.update({
        "font.family": "DejaVu Sans",
        "font.size": 10,
        "axes.labelsize": 11,
        "axes.titlesize": 12,
        "figure.dpi": 180,
        "savefig.dpi": 300,
    })

    char_root = resolve_char_root(Path(args.char_root))
    focused_root = Path(args.focused_root).resolve() if args.focused_root else None
    out_dir = Path(args.output_dir).resolve()
    figs_dir = out_dir / "figures"

    cal_dir = char_root / "analysis" / "calibration"
    cal_report_path = cal_dir / "calibration_report.json"
    error_csv = cal_dir / "val_reconstruction_errors_pre_post.csv"
    cal_report = read_json(cal_report_path)

    manifest: dict = {
        "char_root": str(char_root),
        "focused_root": str(focused_root) if focused_root else "",
        "source_reports": {"calibration_report": str(cal_report_path)},
        "figures": {},
        "tables": {},
        "warnings": [],
    }

    plot_error_histogram(error_csv, figs_dir, manifest)
    plot_abs_error_cdf(error_csv, figs_dir, manifest)
    plot_averaging(cal_report, figs_dir, manifest)

    line_tables = find_linearity_tables(focused_root, char_root)
    if line_tables:
        manifest["source_reports"]["linearity_tables"] = str(line_tables)
        plot_dnl_inl(line_tables, figs_dir, manifest)
        plot_transfer(line_tables, figs_dir, manifest)
    else:
        manifest["warnings"].append("No linearity tables found; DNL/INL figures skipped")

    boundary_table = find_boundary_table(focused_root, char_root)
    if boundary_table:
        manifest["source_reports"]["boundary_table"] = str(boundary_table)
        plot_boundary(boundary_table, figs_dir, manifest)
    else:
        manifest["warnings"].append("No boundary_summary.csv found; boundary figure skipped")

    write_metrics_tables(cal_report, char_root, out_dir, manifest)
    out_dir.mkdir(parents=True, exist_ok=True)
    manifest_path = out_dir / "report_plot_manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"[PLOTS] Wrote {manifest_path}")
    for name, paths in manifest["figures"].items():
        print(f"[PLOTS] {name}: {paths[0]}")
    for warning in manifest["warnings"]:
        print(f"[WARN] {warning}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
