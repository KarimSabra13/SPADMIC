#!/usr/bin/env python3
"""Generate final French report plots from the golden MPTDC weekend metrics."""

from __future__ import annotations

from pathlib import Path

import matplotlib as mpl

mpl.use("Agg")
import matplotlib.pyplot as plt
import numpy as np


OUT = Path(__file__).resolve().parents[1]

BLUE = "#2F6DB3"
GREEN = "#2F8F5B"
ORANGE = "#D9822B"
RED = "#BA3A3A"
PURPLE = "#6F4FB5"
GRAY = "#6B7280"
DARK = "#1F2937"


def setup_style() -> None:
    mpl.rcParams.update(
        {
            "figure.dpi": 150,
            "savefig.dpi": 300,
            "font.family": "serif",
            "font.serif": ["DejaVu Serif"],
            "font.size": 10,
            "axes.titlesize": 11,
            "axes.labelsize": 10,
            "legend.fontsize": 8.5,
            "xtick.labelsize": 8.5,
            "ytick.labelsize": 8.5,
            "axes.grid": True,
            "grid.color": "#C8CDD2",
            "grid.linestyle": (0, (2, 3)),
            "grid.linewidth": 0.45,
            "grid.alpha": 0.75,
            "pdf.fonttype": 42,
            "ps.fonttype": 42,
        }
    )


def fr(x: float, digits: int = 1) -> str:
    return f"{x:.{digits}f}".replace(".", ",")


def fr_int(x: float) -> str:
    return f"{int(round(x)):,}".replace(",", " ")


def save(fig: plt.Figure, name: str) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for ax in fig.axes:
        for spine in ax.spines.values():
            spine.set_color("#111111")
            spine.set_linewidth(0.8)
        ax.tick_params(colors="#111111", width=0.75, length=3.0)
    fig.savefig(OUT / name, bbox_inches="tight")
    plt.close(fig)


def plot_calibration_summary() -> None:
    metrics = ["RMSE", "MAE", "p99 |e|"]
    before = np.array([435.706, 375.744, 1161.000])
    after = np.array([19.608, 15.922, 45.936])
    x = np.arange(len(metrics))
    w = 0.36

    fig, axes = plt.subplots(1, 2, figsize=(7.2, 3.9), constrained_layout=True)
    axes[0].bar(x - w / 2, before, w, label="Avant calibration", color=GRAY)
    axes[0].bar(x + w / 2, after, w, label="Après calibration", color=GREEN)
    axes[0].set_yscale("log")
    axes[0].set_ylabel("Erreur (ps, échelle log)")
    axes[0].set_title("Validation fresh, domaine core")
    axes[0].set_xticks(x, metrics)
    axes[0].legend(frameon=False)
    for xpos, val in zip(np.r_[x - w / 2, x + w / 2], np.r_[before, after]):
        axes[0].text(xpos, val * 1.08, fr(val, 1), ha="center", va="bottom", fontsize=7, rotation=90)

    axes[1].bar(["Avant", "Après"], [-137.777, 0.0031], color=[GRAY, GREEN], width=0.55)
    axes[1].axhline(0, color=DARK, linewidth=0.8)
    axes[1].set_ylabel("Moyenne signée (ps)")
    axes[1].set_title("Recentrage de l'erreur")
    axes[1].text(
        0.03,
        0.04,
        "Validation après filtre : 90 810 660 lignes\n"
        "Lignes couvertes LUT : 90 810 228\n"
        "Sans entrée LUT : 432\n"
        "Réduction RMSE : 95,50 %",
        transform=axes[1].transAxes,
        va="bottom",
        ha="left",
        fontsize=8,
        bbox=dict(boxstyle="round,pad=0.35", facecolor="white", edgecolor="#D0D0D0"),
    )
    save(fig, "char_calibration_prepost_summary_report.pdf")


def plot_residual_quantiles() -> None:
    q = np.array([50, 90, 95, 99])
    before = np.array([326.0, 732.0, 796.0, 1161.0])
    after = np.array([13.838, 32.546, 37.537, 45.936])

    fig, ax = plt.subplots(figsize=(7.2, 3.8), constrained_layout=True)
    ax.plot(q, before, marker="o", color=GRAY, linewidth=1.5, label="Avant calibration")
    ax.plot(q, after, marker="o", color=GREEN, linewidth=1.5, label="Après calibration")
    ax.set_yscale("log")
    ax.set_xlabel("Quantile de |erreur| (%)")
    ax.set_ylabel("|erreur| (ps, échelle log)")
    ax.set_title("Distribution résiduelle résumée par quantiles")
    ax.set_xticks(q)
    ax.legend(frameon=False)
    for xs, ys in [(q, before), (q, after)]:
        for x, y in zip(xs, ys):
            ax.text(x, y * 1.07, fr(y, 1), ha="center", va="bottom", fontsize=7)
    ax.text(
        0.02,
        0.06,
        "Source : validation fresh core nslow > 0\n"
        "p50/p90/p95/p99 absolus, pas une mesure silicium",
        transform=ax.transAxes,
        fontsize=8,
        va="bottom",
        bbox=dict(boxstyle="round,pad=0.35", facecolor="white", edgecolor="#D0D0D0"),
    )
    save(fig, "char_calibration_residual_hist_report.pdf")


def plot_dnl_inl_summary() -> None:
    labels = ["Train", "Validation"]
    dnl = [1.208, 1.308]
    inl = [98.802, 98.673]

    fig, axes = plt.subplots(1, 2, figsize=(7.2, 3.6), constrained_layout=True)
    axes[0].bar(labels, dnl, color=[BLUE, ORANGE], width=0.55)
    axes[0].set_ylabel("Pic |DNL| (LSB)")
    axes[0].set_title("Non-linéarité différentielle")
    axes[0].set_ylim(0, 1.55)
    for i, val in enumerate(dnl):
        axes[0].text(i, val + 0.04, fr(val, 3), ha="center", fontsize=8)

    axes[1].bar(labels, inl, color=[BLUE, ORANGE], width=0.55)
    axes[1].set_ylabel("Pic |INL| (LSB)")
    axes[1].set_title("Non-linéarité intégrale")
    axes[1].set_ylim(0, 115)
    for i, val in enumerate(inl):
        axes[1].text(i, val + 2, fr(val, 3), ha="center", fontsize=8)

    fig.suptitle("Sweeps échantillonnés : 3 000 000 lignes train et 3 000 000 lignes validation", fontsize=10.5)
    save(fig, "char_code_density_dnl_inl_report.pdf")


def plot_boundary_summary() -> None:
    fig, axes = plt.subplots(1, 2, figsize=(7.2, 3.6), constrained_layout=True)
    labels = ["Train", "Validation"]
    rms = [459.094, 459.021]
    bias = [-157.194, -157.451]
    axes[0].bar(labels, rms, color=[PURPLE, BLUE], width=0.55)
    axes[0].set_ylabel("RMSE brute (ps)")
    axes[0].set_title("Dispersion globale")
    axes[0].set_ylim(0, 520)
    axes[1].bar(labels, bias, color=[RED, ORANGE], width=0.55)
    axes[1].axhline(0, color=DARK, linewidth=0.8)
    axes[1].set_ylabel("Biais moyen (ps)")
    axes[1].set_title("Biais global")
    for ax, vals in zip(axes, [rms, bias]):
        for i, val in enumerate(vals):
            y = val + (10 if val >= 0 else -10)
            va = "bottom" if val >= 0 else "top"
            ax.text(i, y, fr(val, 3), ha="center", va=va, fontsize=8)
    fig.suptitle("Stress de frontière avant calibration : synthèse globale", fontsize=10.5)
    save(fig, "char_boundary_rms_mean_report.pdf")


def plot_alias() -> None:
    labels = ["Toutes\nlignes", "Core\nnslow > 0", "Non-core\nnslow = 0"]
    total_keys = np.array([439, 235, 204])
    aliased = np.array([56, 0, 56])
    oracle = np.array([162.340, 0.0, 209.580])
    x = np.arange(len(labels))

    fig, axes = plt.subplots(1, 2, figsize=(7.2, 3.8), constrained_layout=True)
    axes[0].bar(x, total_keys - aliased, color=GREEN, label="Clés non aliasées")
    axes[0].bar(x, aliased, bottom=total_keys - aliased, color=RED, label="Clés aliasées")
    axes[0].set_xticks(x, labels)
    axes[0].set_ylabel("Nombre de clés")
    axes[0].set_title("Unicité de la clé")
    axes[0].legend(frameon=False, loc="upper left")

    axes[1].bar(x, oracle, color=[GRAY, GREEN, RED], width=0.55)
    axes[1].set_xticks(x, labels)
    axes[1].set_ylabel("RMSE oracle (ps)")
    axes[1].set_title("Plancher si alias non résolu")
    axes[1].set_ylim(0, 240)
    for i, val in enumerate(oracle):
        axes[1].text(i, val + 6, fr(val, 1), ha="center", fontsize=8)
    save(fig, "alias_core_noncore_report.pdf")


def plot_fixed_delay() -> None:
    delays = np.array([20, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 30000], dtype=float)
    rmse = np.array([1319.546, 1317.652, 1276.561, 1175.405, 914.178, 479.892, 437.256, 339.021, 350.587, 500.168])
    bias = np.array([-1284.724, -1282.158, -1225.965, -1105.460, -872.977, -284.153, -168.140, 73.798, -53.922, -345.362])

    fig, ax = plt.subplots(figsize=(7.2, 4.3), constrained_layout=True)
    ax.plot(delays, rmse, marker="o", color=PURPLE, linewidth=1.4, label="RMSE brute")
    ax.plot(delays, np.abs(bias), marker="s", color=RED, linewidth=1.2, label="|biais moyen|")
    ax.set_xscale("log")
    ax.set_xlabel("Délai fixe injecté (ps, échelle log)")
    ax.set_ylabel("Erreur (ps)")
    ax.set_title("Fixed-delay brut avant calibration")
    ax.legend(frameon=False)
    ax.grid(True, which="both", axis="x", alpha=0.35)
    ax.text(
        0.03,
        0.06,
        "24 seeds, 10 000 conversions/seed/délai\n"
        "3 600 000 lignes row par délai",
        transform=ax.transAxes,
        fontsize=8,
        bbox=dict(boxstyle="round,pad=0.35", facecolor="white", edgecolor="#D0D0D0"),
    )
    save(fig, "fixed_delay_raw_rmse_report.pdf")


def plot_averaging() -> None:
    n = np.array([1, 2, 3, 4, 5, 8, 10, 15], dtype=float)
    rmse = np.array([19.578, 13.866, 11.227, 9.801, 8.747, 6.848, 6.194, 5.090])
    ideal = rmse[0] / np.sqrt(n)

    fig, ax = plt.subplots(figsize=(6.8, 4.1), constrained_layout=True)
    ax.plot(n, rmse, marker="o", color=BLUE, linewidth=1.5, label="Campagne calibrée")
    ax.plot(n, ideal, linestyle="--", color=GRAY, linewidth=1.1, label=r"Loi $1/\sqrt{N}$ ancrée à N=1")
    ax.set_xlabel("Nombre de hits moyennés N")
    ax.set_ylabel("RMSE (ps)")
    ax.set_title("Gain de moyennage borné par MAX_HITS = 15")
    ax.set_xticks(n.astype(int))
    ax.set_ylim(0, 22)
    ax.legend(frameon=False)
    for x, y in zip(n, rmse):
        ax.text(x, y + 0.45, fr(y, 3), ha="center", fontsize=7.5)
    save(fig, "multihit_averaging_plot.pdf")


def plot_deadtime() -> None:
    gaps = np.arange(29.0, 35.5, 0.5)
    acc = np.where(gaps >= 32.0, 100.0, 0.0)
    essais = np.full_like(gaps, 2400.0)

    fig, axes = plt.subplots(2, 1, figsize=(7.2, 5.4), sharex=True, constrained_layout=True, height_ratios=[2.0, 1.1])
    axes[0].step(gaps, acc, where="post", color=BLUE, linewidth=1.6)
    axes[0].scatter(gaps, acc, color=BLUE, s=18)
    axes[0].axvspan(31.5, 32.0, color=ORANGE, alpha=0.2, label="Transition 31,5-32,0 ns")
    axes[0].set_ylim(-5, 105)
    axes[0].set_ylabel("Acceptation (%)")
    axes[0].set_title("Deadtime persistent-arm : acceptation du second événement")
    axes[0].annotate("100 % dès 32,0 ns", xy=(32.0, 100), xytext=(32.7, 68), arrowprops=dict(arrowstyle="->", lw=0.8), fontsize=8)
    axes[0].legend(frameon=False, loc="lower right")

    axes[1].bar(gaps, essais, width=0.35, color="#CFE0F1")
    axes[1].set_ylabel("Essais/gap")
    axes[1].set_xlabel("Gap STOP-to-next-START (ns)")
    axes[1].set_ylim(0, 2800)
    axes[1].text(0.02, 0.78, "24 seeds x 100 essais = 2 400", transform=axes[1].transAxes, fontsize=8)
    save(fig, "char_deadtime_acceptance_report.pdf")


def plot_throughput() -> None:
    labels = ["Événements", "Conversions\nacceptées", "START\nrejetés", "Paquets\nsortis"]
    values = [480000, 121439, 358517, 121343]
    colors = [GRAY, BLUE, RED, GREEN]

    fig, axes = plt.subplots(1, 2, figsize=(7.2, 3.8), constrained_layout=True, gridspec_kw={"width_ratios": [1.45, 1.0]})
    x = np.arange(len(labels))
    axes[0].bar(x, values, color=colors, width=0.62)
    axes[0].set_xticks(x, labels)
    axes[0].set_ylabel("Cumul")
    axes[0].set_title("Compteurs finaux")
    for i, val in enumerate(values):
        axes[0].text(i, val + 12000, fr_int(val), ha="center", va="bottom", fontsize=7.5, rotation=90)
    axes[0].set_ylim(0, 560000)

    axes[1].bar(["FIFO max"], [64], color=PURPLE, width=0.52)
    axes[1].axhline(64, color=RED, linestyle="--", linewidth=0.8)
    axes[1].set_ylim(0, 72)
    axes[1].set_ylabel("Mots")
    axes[1].set_title("Rétropression ready=50 %")
    axes[1].text(
        0.5,
        0.12,
        "FIFO atteint 64 mots\naucune corruption VIP\n2048/2048 PASS",
        transform=axes[1].transAxes,
        ha="center",
        fontsize=8,
        bbox=dict(boxstyle="round,pad=0.35", facecolor="white", edgecolor="#D0D0D0"),
    )
    save(fig, "char_throughput_counters_report.pdf")


def main() -> None:
    setup_style()
    plot_calibration_summary()
    plot_residual_quantiles()
    plot_dnl_inl_summary()
    plot_boundary_summary()
    plot_alias()
    plot_fixed_delay()
    plot_averaging()
    plot_deadtime()
    plot_throughput()
    print(f"Figures golden écrites dans {OUT}")


if __name__ == "__main__":
    main()
