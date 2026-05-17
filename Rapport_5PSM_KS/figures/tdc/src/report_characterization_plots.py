#!/usr/bin/env python3
"""Generate report-grade MPTDC characterization figures from campaign tables.

The script is intentionally self-contained and uses only CSV tables already
exported by the characterization analysis. The residual histogram is copied from
that analysis because the compact histogram bins were not exported as a table.
"""
from __future__ import annotations

import argparse
import shutil
from pathlib import Path

import matplotlib as mpl
mpl.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.colors import LogNorm
from matplotlib.ticker import FuncFormatter, MaxNLocator

ROOT = Path(__file__).resolve().parents[4]
DEFAULT_CAMPAIGN = ROOT / "results/characterization/mptdc_scientific_150seed_20260515_161404"
DEFAULT_TABLES = DEFAULT_CAMPAIGN / "analysis/tables"
DEFAULT_PLOTS = DEFAULT_CAMPAIGN / "analysis/plots"
DEFAULT_OUT = ROOT / "Rapport_5PSM_KS/figures/tdc"

COLORS = {
    "blue": "#1f77b4",
    "orange": "#ff7f0e",
    "green": "#2ca02c",
    "red": "#d62728",
    "purple": "#9467bd",
    "gray": "#6c757d",
    "dark": "#2f3437",
}


def setup_style() -> None:
    plt.style.use("default")
    mpl.rcParams.update(
        {
            "figure.dpi": 150,
            "savefig.dpi": 300,
            "font.family": "serif",
            "font.serif": ["Times New Roman", "Times", "DejaVu Serif"],
            "font.size": 10,
            "axes.titlesize": 11,
            "axes.labelsize": 10,
            "legend.fontsize": 8.5,
            "xtick.labelsize": 8.5,
            "ytick.labelsize": 8.5,
            "axes.grid": True,
            "grid.color": "#b8bec4",
            "grid.linestyle": (0, (2, 3)),
            "grid.linewidth": 0.45,
            "grid.alpha": 0.75,
            "axes.spines.top": True,
            "axes.spines.right": True,
            "pdf.fonttype": 42,
            "ps.fonttype": 42,
        }
    )


def french_int(x: float, _pos=None) -> str:
    return f"{int(round(x)):,}".replace(",", " ")


def french_float(x: float, digits: int = 1) -> str:
    return f"{x:.{digits}f}".replace(".", ",")


def save(fig: plt.Figure, out: Path) -> None:
    out.parent.mkdir(parents=True, exist_ok=True)
    for ax in fig.axes:
        for spine in ax.spines.values():
            spine.set_visible(True)
            spine.set_color("#111111")
            spine.set_linewidth(0.8)
        ax.tick_params(colors="#111111", width=0.75, length=3.0)
        ax.grid(True, color="#b8bec4", linestyle=(0, (2, 3)), linewidth=0.45, alpha=0.75)
    fig.savefig(out, bbox_inches="tight")
    plt.close(fig)


def plot_phase_occupancy(tables: Path, out: Path) -> None:
    lut = pd.read_csv(tables / "lut_6d.csv")
    pivot = (
        lut.groupby(["ns_inf", "nf_inf"], as_index=False)["train_count"].sum()
        .pivot(index="ns_inf", columns="nf_inf", values="train_count")
        .reindex(index=range(8), columns=range(8))
        .fillna(0)
    )
    values = pivot.to_numpy(dtype=float)
    nonzero = values[values > 0]
    fig, ax = plt.subplots(figsize=(6.2, 5.1), constrained_layout=True)
    norm = LogNorm(vmin=max(float(nonzero.min()), 1.0), vmax=float(nonzero.max())) if nonzero.size else None
    im = ax.imshow(np.where(values > 0, values, np.nan), origin="lower", cmap="viridis", norm=norm)
    for ns in range(values.shape[0]):
        for nf in range(values.shape[1]):
            val = values[ns, nf]
            label = "0" if val == 0 else f"{val/1e6:.1f} M".replace(".", ",")
            ax.text(nf, ns, label, ha="center", va="center", color="white" if val > np.nanmax(values) * 0.2 else "#222222", fontsize=7)
    ax.set_title("Occupation des couples de phase utilisés par la LUT")
    ax.set_xlabel("Phase rapide $n_f$")
    ax.set_ylabel("Phase lente $n_s$")
    ax.set_xticks(range(8))
    ax.set_yticks(range(8))
    cbar = fig.colorbar(im, ax=ax, shrink=0.92)
    cbar.set_label("Échantillons d'entraînement (échelle log)")
    save(fig, out / "char_code_density_phase_occupancy_report.pdf")


def plot_dnl_inl(tables: Path, out: Path) -> None:
    df = pd.read_csv(tables / "code_density_dnl_inl.csv")
    x = df["code_index"].to_numpy()
    fig, axes = plt.subplots(3, 1, figsize=(7.2, 7.1), sharex=True, constrained_layout=True)
    axes[0].fill_between(x, df["count"], step="mid", color=COLORS["blue"], alpha=0.82, linewidth=0)
    axes[0].set_ylabel("Coups")
    axes[0].set_title("Code-density : population, DNL et INL")
    axes[0].yaxis.set_major_formatter(FuncFormatter(french_int))

    sigma = df["dnl_sigma_lsb"].to_numpy()
    dnl = df["dnl_lsb"].to_numpy()
    axes[1].plot(x, dnl, color=COLORS["red"], linewidth=0.8, label="DNL")
    axes[1].fill_between(x, dnl - 1.96 * sigma, dnl + 1.96 * sigma, color=COLORS["red"], alpha=0.14, label="IC 95 %")
    axes[1].axhline(0, color=COLORS["dark"], linewidth=0.7)
    axes[1].set_ylabel("DNL (LSB)")
    axes[1].legend(loc="upper right", frameon=False)

    axes[2].plot(x, df["inl_lsb"], color=COLORS["orange"], linewidth=0.9)
    axes[2].axhline(0, color=COLORS["dark"], linewidth=0.7)
    axes[2].set_ylabel("INL (LSB)")
    axes[2].set_xlabel("Index de code")
    for ax in axes:
        ax.margins(x=0)
        ax.grid(True, axis="y")
        ax.grid(False, axis="x")
    save(fig, out / "char_code_density_dnl_inl_report.pdf")


def plot_calibration_summary(tables: Path, plots: Path, out: Path) -> None:
    df = pd.read_csv(tables / "calibration_pre_post.csv")
    order = ["avant_calibration", "apres_calibration"]
    df = df.set_index("metrique").loc[order]
    labels = ["Avant", "Après"]

    fig, axes = plt.subplots(1, 2, figsize=(7.2, 3.9), constrained_layout=True)
    metrics = ["rms_ps", "p95_abs_ps", "p99_abs_ps"]
    names = ["RMS", "p95 |erreur|", "p99 |erreur|"]
    width = 0.36
    idx = np.arange(len(metrics))
    for j, metric in enumerate(metrics):
        vals = df[metric].to_numpy(dtype=float)
        axes[0].bar(j - width / 2, vals[0], width, color=COLORS["gray"], label="Avant" if j == 0 else None)
        axes[0].bar(j + width / 2, vals[1], width, color=COLORS["green"], label="Après" if j == 0 else None)
        for xpos, val in [(j - width / 2, vals[0]), (j + width / 2, vals[1])]:
            axes[0].text(xpos, val * 1.08, french_float(val, 1), ha="center", va="bottom", fontsize=7, rotation=90)
    axes[0].set_yscale("log")
    axes[0].set_xticks(idx, names, rotation=12, ha="right")
    axes[0].set_ylabel("Erreur (ps, échelle log)")
    axes[0].set_title("Réduction d'erreur sur validation")
    axes[0].legend(frameon=False)

    means = df["moyenne_ps"].to_numpy(dtype=float)
    bars = axes[1].bar(labels, means, color=[COLORS["gray"], COLORS["green"]], width=0.55)
    axes[1].axhline(0, color=COLORS["dark"], linewidth=0.8)
    axes[1].set_ylabel("Moyenne signée (ps)")
    axes[1].set_title("Recentrage de l'erreur")
    for bar, val in zip(bars, means):
        y = val - 8 if val < 0 else val + 8
        va = "top" if val < 0 else "bottom"
        axes[1].text(bar.get_x() + bar.get_width() / 2, y, french_float(val, 3 if abs(val) < 1 else 1), ha="center", va=va, fontsize=8)
    info = (
        f"Validation : {french_int(df['validation_lignes'].iloc[0])} lignes\n"
        f"LUT : {french_int(df['train_lut_codes'].iloc[0])} codes\n"
        f"Sans entrée LUT : {french_int(df['validation_sans_lut'].iloc[0])}"
    )
    axes[1].text(0.04, 0.04, info, transform=axes[1].transAxes, fontsize=8, va="bottom", ha="left", bbox=dict(boxstyle="round,pad=0.35", facecolor="white", edgecolor="#d0d0d0"))
    save(fig, out / "char_calibration_prepost_summary_report.pdf")

    source_hist = plots / "calibration_residual_hist.pdf"
    if source_hist.exists():
        shutil.copyfile(source_hist, out / "char_calibration_residual_hist_report.pdf")
    else:
        raise FileNotFoundError(source_hist)


def plot_deadtime(tables: Path, out: Path) -> None:
    df = pd.read_csv(tables / "deadtime_acceptance.csv")
    x = df["gap_ns"].to_numpy()
    p = df["probabilite_acceptation_pct"].to_numpy()
    fig, axes = plt.subplots(2, 1, figsize=(7.2, 5.6), sharex=True, constrained_layout=True, height_ratios=[2.0, 1.2])
    axes[0].plot(x, p, color=COLORS["blue"], marker="o", markersize=3, linewidth=1.3)
    axes[0].set_ylim(-4, 104)
    axes[0].set_ylabel("Acceptation (%)")
    axes[0].set_title("Temps mort : transition d'acceptation")
    transition = df[(df["probabilite_acceptation_pct"] > 0) & (df["probabilite_acceptation_pct"] < 100)]
    first_full = df[df["probabilite_acceptation_pct"] >= 100]["gap_ns"].min()
    last_zero = df[df["probabilite_acceptation_pct"] <= 0]["gap_ns"].max()
    if pd.notna(first_full) and pd.notna(last_zero):
        axes[0].axvspan(last_zero, first_full, color=COLORS["orange"], alpha=0.18, label=f"Transition {french_float(last_zero)}–{french_float(first_full)} ns")
        axes[0].annotate("bascule observée", xy=((last_zero + first_full) / 2, 50), xytext=(first_full + 8, 45), arrowprops=dict(arrowstyle="->", color=COLORS["dark"], lw=0.8), fontsize=8)
    if not transition.empty:
        axes[0].scatter(transition["gap_ns"], transition["probabilite_acceptation_pct"], s=22, color=COLORS["orange"], zorder=3)
    axes[0].legend(loc="lower right", frameon=False)

    axes[1].bar(x, df["essais"], width=0.38, color="#c8d8e6", label="Essais")
    axes[1].bar(x, df["acceptes"], width=0.22, color=COLORS["green"], label="Acceptés")
    axes[1].set_ylabel("Nombre")
    axes[1].set_xlabel("Gap injecté STOP-START (ns)")
    axes[1].yaxis.set_major_formatter(FuncFormatter(french_int))
    axes[1].legend(loc="upper right", frameon=False, ncol=2)
    axes[1].set_xlim(x.min() - 0.5, min(x.max(), 20.0) + 0.5)
    save(fig, out / "char_deadtime_acceptance_report.pdf")


def plot_boundary(tables: Path, out: Path) -> None:
    df = pd.read_csv(tables / "boundary_summary.csv")
    x = df["boundary_offset_ps"].to_numpy()
    fig, axes = plt.subplots(2, 1, figsize=(7.2, 5.6), sharex=True, constrained_layout=True)
    axes[0].plot(x, df["erreur_rms_ps"], color=COLORS["purple"], marker="o", markersize=3, linewidth=1.25)
    axes[0].axhline(df["erreur_rms_ps"].mean(), color=COLORS["purple"], linestyle="--", linewidth=0.8, alpha=0.7, label=f"Moyenne {french_float(df['erreur_rms_ps'].mean())} ps")
    axes[0].set_ylabel("RMS erreur (ps)")
    axes[0].set_title("Stress de frontière : RMS et biais moyen")
    axes[0].legend(frameon=False, loc="upper right")

    axes[1].plot(x, df["erreur_moy_ps"], color=COLORS["red"], marker="s", markersize=3, linewidth=1.1)
    axes[1].axhline(df["erreur_moy_ps"].mean(), color=COLORS["red"], linestyle="--", linewidth=0.8, alpha=0.7, label=f"Moyenne {french_float(df['erreur_moy_ps'].mean())} ps")
    axes[1].axvline(0, color=COLORS["dark"], linestyle=":", linewidth=0.8)
    axes[1].set_ylabel("Erreur moyenne (ps)")
    axes[1].set_xlabel("Offset de frontière (ps)")
    axes[1].legend(frameon=False, loc="upper right")
    save(fig, out / "char_boundary_rms_mean_report.pdf")


def reconstruct_cumulative(table: pd.DataFrame, column: str) -> np.ndarray:
    arr = table[column].to_numpy(dtype=float)
    diff = np.diff(arr, prepend=0.0)
    increments = np.where(diff >= 0, diff, arr)
    return np.cumsum(increments)


def plot_throughput(tables: Path, out: Path) -> None:
    df = pd.read_csv(tables / "throughput.csv")
    event_m = df["event_idx"].to_numpy(dtype=float) / 1e6
    conv = reconstruct_cumulative(df, "conv_after")
    ovf = reconstruct_cumulative(df, "ovf_after")
    packets = reconstruct_cumulative(df, "packet_count")
    fifo = df["fifo_level"].to_numpy(dtype=float)

    stride = max(1, len(df) // 3500)
    sl = slice(None, None, stride)
    win = 10_000
    edges = np.arange(0, len(df) + win, win)
    centers = (edges[:-1] + edges[1:]) / 2 / 1e6
    conv_rate = np.diff(np.interp(edges, np.arange(len(df)), conv, left=0, right=conv[-1])) / win
    ovf_rate = np.diff(np.interp(edges, np.arange(len(df)), ovf, left=0, right=ovf[-1])) / win

    fig, axes = plt.subplots(3, 1, figsize=(7.2, 7.2), sharex=False, constrained_layout=True, height_ratios=[1.55, 1.15, 1.05])
    axes[0].plot(event_m[sl], conv[sl], color=COLORS["blue"], linewidth=1.25, label="Conversions drainées")
    axes[0].plot(event_m[sl], packets[sl], color=COLORS["green"], linewidth=1.1, label="Paquets sortis")
    axes[0].plot(event_m[sl], ovf[sl], color=COLORS["red"], linewidth=1.1, label="Rejets cumulés")
    axes[0].set_title("Débit sous rétropression : compteurs agrégés")
    axes[0].set_ylabel("Cumul")
    axes[0].yaxis.set_major_formatter(FuncFormatter(french_int))
    axes[0].legend(loc="upper left", frameon=False, ncol=1)

    axes[1].plot(event_m[sl], fifo[sl], color=COLORS["purple"], linewidth=0.75)
    axes[1].axhline(np.nanmax(fifo), color=COLORS["red"], linestyle="--", linewidth=0.8, label=f"niveau max {int(np.nanmax(fifo))}")
    axes[1].set_ylabel("Niveau FIFO")
    axes[1].set_xlabel("Index événement (millions)")
    axes[1].legend(loc="lower right", frameon=False)
    axes[1].yaxis.set_major_locator(MaxNLocator(integer=True, nbins=5))

    axes[2].plot(centers, conv_rate, color=COLORS["blue"], linewidth=1.0, label="Conversions / événement")
    axes[2].plot(centers, ovf_rate, color=COLORS["red"], linewidth=1.0, label="Rejets / événement")
    axes[2].set_ylabel("Taux local")
    axes[2].set_xlabel("Index événement (millions)")
    axes[2].legend(frameon=False, loc="upper right")
    axes[2].set_ylim(bottom=0)
    save(fig, out / "char_throughput_counters_report.pdf")


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate report-grade characterization figures.")
    parser.add_argument("--tables", type=Path, default=DEFAULT_TABLES)
    parser.add_argument("--plots", type=Path, default=DEFAULT_PLOTS)
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT)
    args = parser.parse_args()

    setup_style()
    plot_phase_occupancy(args.tables, args.out)
    plot_dnl_inl(args.tables, args.out)
    plot_calibration_summary(args.tables, args.plots, args.out)
    plot_deadtime(args.tables, args.out)
    plot_boundary(args.tables, args.out)
    plot_throughput(args.tables, args.out)
    print(f"Figures écrites dans {args.out}")


if __name__ == "__main__":
    main()
