from __future__ import annotations

import json
import re
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.gridspec import GridSpec
from matplotlib.patches import FancyArrowPatch, FancyBboxPatch, Rectangle


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "figures" / "tdc"
RESULTS_DIR = ROOT.parent / "MPTDC" / "results"

NE = 9
K_VERNIER = 11
DELTA_LSB_PS = 10
OSC_TS_SLOW_PS = 55
OSC_TS_FAST_PS = 50

COLORS = {
    "sys": "#1f4e79",
    "sys_fill": "#e8eef5",
    "slow": "#3a3a3a",
    "slow_fill": "#f0f0f0",
    "fast": "#4a7ab8",
    "fast_fill": "#d9e4f2",
    "async": "#8b2e2e",
    "async_fill": "#f2e4e4",
    "purple": "#5a5a5a",
    "purple_fill": "#ededed",
    "gray": "#2f2f2f",
    "mid_gray": "#7a7a7a",
    "light_gray": "#f5f5f5",
    "dark": "#000000",
    "success": "#1f4e79",
    "danger": "#8b2e2e",
    "gold": "#5a5a5a",
    "white": "#FFFFFF",
}


plt.rcParams.update(
    {
        "font.family": "DejaVu Sans",
        "font.size": 10,
        "axes.titlesize": 14,
        "axes.labelsize": 11,
        "figure.facecolor": "white",
        "savefig.facecolor": "white",
        "pdf.fonttype": 42,
        "ps.fonttype": 42,
        "axes.spines.top": False,
        "axes.spines.right": False,
    }
)


def save(fig: plt.Figure, name: str) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    fig.savefig(OUT_DIR / f"{name}.pdf", bbox_inches="tight")
    plt.close(fig)


def setup_diagram(title: str, size: tuple[float, float] = (12, 6)) -> tuple[plt.Figure, plt.Axes]:
    fig, ax = plt.subplots(figsize=size)
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")
    ax.text(0.5, 0.97, title, ha="center", va="top", fontsize=14, fontweight="bold", color=COLORS["dark"])
    return fig, ax


def add_box(
    ax: plt.Axes,
    xy: tuple[float, float],
    wh: tuple[float, float],
    text: str,
    fc: str,
    ec: str | None = None,
    fontsize: int = 10,
    lw: float = 1.6,
    rounding: float = 0.02,
    text_color: str = COLORS["dark"],
    alpha: float = 1.0,
    zorder: int = 3,
) -> FancyBboxPatch:
    x, y = xy
    w, h = wh
    patch = FancyBboxPatch(
        (x, y),
        w,
        h,
        boxstyle=f"round,pad=0.01,rounding_size={rounding}",
        linewidth=lw,
        edgecolor=ec or COLORS["gray"],
        facecolor=fc,
        alpha=alpha,
        zorder=zorder,
    )
    ax.add_patch(patch)
    ax.text(x + w / 2, y + h / 2, text, ha="center", va="center", fontsize=fontsize, color=text_color, zorder=zorder + 1)
    return patch


def add_domain(
    ax: plt.Axes,
    xy: tuple[float, float],
    wh: tuple[float, float],
    label: str,
    fc: str,
    ec: str,
) -> None:
    x, y = xy
    w, h = wh
    patch = FancyBboxPatch(
        (x, y),
        w,
        h,
        boxstyle="round,pad=0.012,rounding_size=0.025",
        linewidth=1.6,
        edgecolor=ec,
        facecolor=fc,
        alpha=0.38,
        zorder=0,
    )
    ax.add_patch(patch)
    ax.text(x + 0.012, y + h - 0.018, label, ha="left", va="top", fontsize=11, fontweight="bold", color=ec, zorder=1)


def add_arrow(
    ax: plt.Axes,
    p0: tuple[float, float],
    p1: tuple[float, float],
    text: str | None = None,
    offset: tuple[float, float] = (0.0, 0.0),
    color: str = COLORS["gray"],
    lw: float = 1.5,
    rad: float = 0.0,
    ls: str = "-",
    arrowstyle: str = "-|>",
    fontsize: int = 9,
    zorder: int = 4,
) -> None:
    arrow = FancyArrowPatch(
        p0,
        p1,
        arrowstyle=arrowstyle,
        mutation_scale=13,
        linewidth=lw,
        linestyle=ls,
        color=color,
        connectionstyle=f"arc3,rad={rad}",
        zorder=zorder,
    )
    ax.add_patch(arrow)
    if text:
        mx = (p0[0] + p1[0]) / 2 + offset[0]
        my = (p0[1] + p1[1]) / 2 + offset[1]
        ax.text(mx, my, text, ha="center", va="center", fontsize=fontsize, color=color, zorder=zorder + 1)


def add_double_arrow(
    ax: plt.Axes,
    p0: tuple[float, float],
    p1: tuple[float, float],
    text: str | None = None,
    offset: tuple[float, float] = (0.0, 0.0),
    color: str = COLORS["gray"],
    lw: float = 1.4,
    fontsize: int = 9,
) -> None:
    arrow = FancyArrowPatch(
        p0,
        p1,
        arrowstyle="<->",
        mutation_scale=12,
        linewidth=lw,
        color=color,
        zorder=4,
    )
    ax.add_patch(arrow)
    if text:
        mx = (p0[0] + p1[0]) / 2 + offset[0]
        my = (p0[1] + p1[1]) / 2 + offset[1]
        ax.text(mx, my, text, ha="center", va="center", fontsize=fontsize, color=color, zorder=5)


def add_label(
    ax: plt.Axes,
    x: float,
    y: float,
    text: str,
    color: str = COLORS["dark"],
    fontsize: int = 10,
    weight: str = "normal",
    ha: str = "left",
    va: str = "center",
) -> None:
    ax.text(x, y, text, ha=ha, va=va, fontsize=fontsize, color=color, fontweight=weight)


def add_legend_swatches(ax: plt.Axes, items: list[tuple[str, str]], x0: float = 0.04, y0: float = 0.04, dx: float = 0.19) -> None:
    for idx, (label, color) in enumerate(items):
        x = x0 + idx * dx
        ax.add_patch(Rectangle((x, y0), 0.018, 0.018, facecolor=color, edgecolor=COLORS["gray"], linewidth=0.8))
        ax.text(x + 0.024, y0 + 0.009, label, va="center", ha="left", fontsize=9, color=COLORS["dark"])


def load_json_result(folder: str) -> dict:
    path = RESULTS_DIR / folder / "enhanced_calibration_results.json"
    return json.loads(path.read_text())


def parse_calibration_report() -> tuple[dict[str, float], dict[str, np.ndarray]]:
    path = RESULTS_DIR / "calibration_final" / "calibration_report.txt"
    text = path.read_text()

    metrics: dict[str, float] = {}
    held = re.search(r"HELD-OUT VALIDATION.*?Pre-calibration\s+RMSE:\s+([0-9.]+)\s+ps.*?Post-calibration\s+RMSE:\s+([0-9.]+)\s+ps", text, flags=re.S)
    fresh = re.search(r"FRESH VALIDATION.*?Pre-calibration\s+RMSE:\s+([0-9.]+)\s+ps.*?Post-calibration\s+RMSE:\s+([0-9.]+)\s+ps", text, flags=re.S)
    if held:
        metrics["held_pre_rmse"] = float(held.group(1))
        metrics["held_post_rmse"] = float(held.group(2))
    if fresh:
        metrics["fresh_pre_rmse"] = float(fresh.group(1))
        metrics["fresh_post_rmse"] = float(fresh.group(2))

    capture = False
    ns: list[int] = []
    rmses: list[float] = []
    for line in text.splitlines():
        if "N   RMSE (ps)" in line:
            capture = True
            continue
        if capture:
            if not line.strip() or line.strip().startswith("─"):
                if ns:
                    break
                continue
            match = re.match(r"^\s*(\d+)\s+([0-9.]+)\s+([0-9.]+)\s+([0-9.]+)", line)
            if match:
                ns.append(int(match.group(1)))
                rmses.append(float(match.group(2)))

    curves = {"n": np.array(ns, dtype=float), "rmse": np.array(rmses, dtype=float)}
    return metrics, curves


def method_map(data: dict) -> dict[str, dict]:
    return {entry["label"]: entry for entry in data["methods"]}


def draw_measurement_chain() -> None:
    fig, ax = setup_diagram("Chaîne de mesure temporelle", size=(11.5, 4.6))
    add_box(ax, (0.05, 0.33), (0.18, 0.22), "Détecteur\nou SPAD", COLORS["sys_fill"], ec=COLORS["sys"], fontsize=11)
    add_box(ax, (0.30, 0.33), (0.18, 0.22), "Front-end\nmise en forme", COLORS["slow_fill"], ec=COLORS["slow"], fontsize=11)
    add_box(ax, (0.55, 0.33), (0.18, 0.22), "TDC\ncoarse + fine", COLORS["fast_fill"], ec=COLORS["fast"], fontsize=11)
    add_box(ax, (0.80, 0.33), (0.16, 0.22), "Traitement\nnumérique", COLORS["purple_fill"], ec=COLORS["purple"], fontsize=11)
    add_arrow(ax, (0.23, 0.44), (0.30, 0.44), "impulsion", offset=(0, 0.035), color=COLORS["gray"])
    add_arrow(ax, (0.48, 0.44), (0.55, 0.44), "START / STOP", offset=(0, 0.035), color=COLORS["async"])
    add_arrow(ax, (0.73, 0.44), (0.80, 0.44), "mots temps", offset=(0, 0.035), color=COLORS["gray"])
    add_label(
        ax,
        0.50,
        0.16,
        "Le TDC transforme un intervalle d'arrivée en observables numériques\nexploitables par la calibration et la reconstruction temporelle.",
        ha="center",
        fontsize=10,
        color=COLORS["gray"],
    )
    save(fig, "tdc_measurement_chain")


def draw_vernier_reference_architecture() -> None:
    fig, ax = setup_diagram("Architecture Vernier multiphase de référence", size=(12.2, 5.8))
    add_box(ax, (0.05, 0.64), (0.18, 0.13), "START\noscillateur lent", COLORS["slow_fill"], ec=COLORS["slow"], fontsize=11)
    add_box(ax, (0.05, 0.29), (0.18, 0.13), "STOP\noscillateur rapide", COLORS["fast_fill"], ec=COLORS["fast"], fontsize=11)
    add_box(ax, (0.32, 0.63), (0.16, 0.14), "Anneau lent\n9 phases", COLORS["slow_fill"], ec=COLORS["slow"], fontsize=11)
    add_box(ax, (0.32, 0.28), (0.16, 0.14), "Anneau rapide\n9 phases", COLORS["fast_fill"], ec=COLORS["fast"], fontsize=11)
    add_box(ax, (0.56, 0.41), (0.20, 0.22), "Matrice de détection\nmultiphase", COLORS["fast_fill"], ec=COLORS["fast"], fontsize=11)
    add_box(ax, (0.82, 0.61), (0.13, 0.12), "Compteurs\ncoarse", COLORS["purple_fill"], ec=COLORS["purple"], fontsize=11)
    add_box(ax, (0.82, 0.42), (0.13, 0.12), "Mémoire\nsnapshot", COLORS["sys_fill"], ec=COLORS["sys"], fontsize=11)
    add_box(ax, (0.82, 0.23), (0.13, 0.12), "Calibration\nhors puce", COLORS["light_gray"], ec=COLORS["gray"], fontsize=11)

    add_arrow(ax, (0.23, 0.705), (0.32, 0.705), color=COLORS["slow"])
    add_arrow(ax, (0.23, 0.355), (0.32, 0.355), color=COLORS["fast"])
    add_arrow(ax, (0.48, 0.70), (0.56, 0.56), "phases lentes", offset=(0.0, 0.05), color=COLORS["slow"])
    add_arrow(ax, (0.48, 0.35), (0.56, 0.48), "phases rapides", offset=(0.0, -0.05), color=COLORS["fast"])
    add_arrow(ax, (0.76, 0.56), (0.82, 0.67), "Nslow / Nfast", offset=(0.0, 0.03), color=COLORS["purple"])
    add_arrow(ax, (0.76, 0.49), (0.82, 0.48), "hit, ns, nf", offset=(0.0, 0.03), color=COLORS["gray"])
    add_arrow(ax, (0.88, 0.42), (0.88, 0.35), color=COLORS["gray"])

    add_double_arrow(ax, (0.35, 0.88), (0.47, 0.88), r"$T_{slow}$", color=COLORS["slow"], fontsize=10)
    add_double_arrow(ax, (0.35, 0.18), (0.46, 0.18), r"$T_{fast}$", color=COLORS["fast"], fontsize=10)
    add_label(ax, 0.50, 0.12, r"$T_{LSB} = T_{slow} - T_{fast}$", ha="center", fontsize=12, weight="bold", color=COLORS["dark"])
    add_label(ax, 0.50, 0.06, "La première coïncidence utile fournit l'information fine, les compteurs portent l'information coarse.", ha="center", fontsize=9, color=COLORS["gray"])
    save(fig, "vernier_reference_architecture")


def draw_vernier_principle_detailed() -> None:
    fig, ax = setup_diagram("Principe Vernier détaillé : rattrapage, coarse et fine", size=(12.5, 6.4))

    slow_y = 0.74
    fast_y = 0.49
    zoom_y = 0.18

    slow_edges = np.array([0.13, 0.31, 0.49, 0.67, 0.85])
    fast_edges = np.array([0.24, 0.40, 0.56, 0.72, 0.88])
    coincidence_x = 0.72

    ax.hlines([slow_y, fast_y], 0.10, 0.91, color=COLORS["mid_gray"], linewidth=1.0)
    for x in slow_edges:
        ax.vlines(x, slow_y - 0.08, slow_y + 0.08, color=COLORS["slow"], linewidth=3)
    for x in fast_edges:
        ax.vlines(x, fast_y - 0.08, fast_y + 0.08, color=COLORS["fast"], linewidth=3)

    add_label(ax, 0.03, slow_y, "Lent (déclenché par START)", color=COLORS["slow"], fontsize=11)
    add_label(ax, 0.03, fast_y, "Rapide (déclenché par STOP)", color=COLORS["fast"], fontsize=11)

    add_double_arrow(ax, (slow_edges[0], 0.88), (slow_edges[1], 0.88), r"$T_{slow}$", color=COLORS["slow"], fontsize=10)
    add_double_arrow(ax, (fast_edges[0], 0.61), (fast_edges[1], 0.61), r"$T_{fast}$", color=COLORS["fast"], fontsize=10)
    add_double_arrow(ax, (slow_edges[0], 0.37), (coincidence_x, 0.37), r"$N_{slow}$ tours observés", color=COLORS["purple"], fontsize=10, offset=(0, 0.035))
    add_double_arrow(ax, (fast_edges[0], 0.29), (coincidence_x, 0.29), r"$N_{fast}$ tours observés", color=COLORS["purple"], fontsize=10, offset=(0, -0.035))

    ax.annotate(
        "START",
        xy=(slow_edges[0], slow_y + 0.08),
        xytext=(slow_edges[0], 0.95),
        ha="center",
        color=COLORS["slow"],
        fontsize=10,
        arrowprops=dict(arrowstyle="-|>", color=COLORS["slow"], lw=1.3),
    )
    ax.annotate(
        "STOP",
        xy=(fast_edges[0], fast_y + 0.08),
        xytext=(fast_edges[0], 0.67),
        ha="center",
        color=COLORS["fast"],
        fontsize=10,
        arrowprops=dict(arrowstyle="-|>", color=COLORS["fast"], lw=1.3),
    )

    ax.axvspan(coincidence_x - 0.03, coincidence_x + 0.03, ymin=0.22, ymax=0.90, color=COLORS["fast_fill"], alpha=0.7)
    add_label(ax, coincidence_x, 0.91, "première zone de coïncidence", ha="center", va="bottom", fontsize=10, color=COLORS["fast"])
    add_label(ax, 0.78, 0.80, r"$T_{fast} < T_{slow}$", color=COLORS["dark"], fontsize=11, weight="bold")
    add_label(ax, 0.78, 0.75, "le rapide rattrape progressivement le lent", color=COLORS["gray"], fontsize=10)

    add_arrow(ax, (coincidence_x, 0.42), (0.57, 0.24), color=COLORS["fast"], lw=1.3)
    add_label(ax, 0.47, 0.27, "zoom sur la zone fine", fontsize=9, color=COLORS["gray"])

    bar_start, bar_end = 0.23, 0.84
    ticks = np.linspace(bar_start, bar_end, 10)
    ax.hlines(zoom_y, bar_start, bar_end, color=COLORS["gray"], linewidth=2)
    ax.vlines(bar_start, zoom_y - 0.055, zoom_y + 0.055, color=COLORS["slow"], linewidth=3)
    ax.vlines(bar_end, zoom_y - 0.055, zoom_y + 0.055, color=COLORS["fast"], linewidth=3)
    for x in ticks[1:-1]:
        ax.vlines(x, zoom_y - 0.03, zoom_y + 0.03, color=COLORS["gold"], linewidth=2)

    add_double_arrow(ax, (bar_start, 0.27), (bar_end, 0.27), r"$T_{LSB}$", color=COLORS["gray"], fontsize=10)
    add_double_arrow(ax, (ticks[4], 0.09), (ticks[5], 0.09), r"$\Delta$", color=COLORS["purple"], fontsize=10)
    add_label(ax, 0.22, 0.05, r"$n_s$", fontsize=10, color=COLORS["slow"], weight="bold")
    add_label(ax, 0.84, 0.05, r"$n_f$", fontsize=10, color=COLORS["fast"], weight="bold", ha="right")
    add_label(ax, 0.54, 0.02, r"$\mathrm{fine\_coef}=11\,n_s-10\,n_f$", ha="center", fontsize=11, weight="bold", color=COLORS["dark"])
    add_label(ax, 0.54, -0.02, f"Pas lent = {OSC_TS_SLOW_PS} ps, pas rapide = {OSC_TS_FAST_PS} ps, delta élémentaire = 5 ps", ha="center", fontsize=9, color=COLORS["gray"])

    save(fig, "vernier_principle_detailed")
    save(fig, "vernier_timing_principle")


def draw_vernier_transition_map() -> None:
    fig, ax = setup_diagram("De la référence Vernier à l'architecture MPTDC", size=(12.3, 5.8))
    add_label(ax, 0.21, 0.90, "Référence issue de la thèse", ha="center", fontsize=12, weight="bold")
    add_label(ax, 0.76, 0.90, "Implémentation active", ha="center", fontsize=12, weight="bold")

    left_y = [0.72, 0.56, 0.40, 0.24]
    right_y = [0.78, 0.64, 0.50, 0.36, 0.22]
    left_labels = [
        "Deux oscillateurs\nà périodes proches",
        "Matrice de phase\nmultiphase",
        "Compteurs\ncoarse",
        "Mémoire de\ncapture",
    ]
    right_labels = [
        "Frontend asynchrone\nSTART / STOP",
        "Oscillateurs +\nGray counters",
        "Matrice PD 9×9 +\nstop capture",
        "Contextes ×2 +\nFSM de mesure",
        "Drain / FIFO /\nTX 16 bits",
    ]
    left_colors = [COLORS["slow_fill"], COLORS["fast_fill"], COLORS["purple_fill"], COLORS["light_gray"]]
    right_colors = [COLORS["async_fill"], COLORS["slow_fill"], COLORS["fast_fill"], COLORS["purple_fill"], COLORS["sys_fill"]]
    right_edges = [COLORS["async"], COLORS["slow"], COLORS["fast"], COLORS["purple"], COLORS["sys"]]

    for y, label, color in zip(left_y, left_labels, left_colors):
        add_box(ax, (0.08, y), (0.22, 0.11), label, color, fontsize=10)
    for y, label, color, edge in zip(right_y, right_labels, right_colors, right_edges):
        add_box(ax, (0.60, y), (0.24, 0.11), label, color, ec=edge, fontsize=10)

    add_arrow(ax, (0.30, 0.775), (0.60, 0.695), "principe conservé", offset=(0.0, 0.04), color=COLORS["slow"])
    add_arrow(ax, (0.30, 0.615), (0.60, 0.555), "grille fine conservée", offset=(0.0, 0.03), color=COLORS["fast"])
    add_arrow(ax, (0.30, 0.455), (0.60, 0.415), "coarse réinterprété", offset=(0.0, 0.03), color=COLORS["purple"])
    add_arrow(ax, (0.30, 0.295), (0.60, 0.275), "stockage structuré", offset=(0.0, 0.03), color=COLORS["gray"])

    add_arrow(ax, (0.84, 0.83), (0.88, 0.83), "ajout système", offset=(0.0, 0.04), color=COLORS["async"])
    add_box(ax, (0.88, 0.74), (0.08, 0.18), "SPADMIC\ncontexte\nsystème", COLORS["light_gray"], ec=COLORS["gray"], fontsize=10)
    add_arrow(ax, (0.84, 0.27), (0.88, 0.27), color=COLORS["sys"])

    add_label(
        ax,
        0.50,
        0.08,
        "Le principe Vernier est préservé, mais l'implémentation ajoute la capture asynchrone,\nle double-buffer, les FSM de fermeture et un protocole de sortie exploitable à l'échelle système.",
        ha="center",
        fontsize=9,
        color=COLORS["gray"],
    )
    save(fig, "vernier_transition_map")


def draw_mptdc_overview() -> None:
    fig, ax = setup_diagram("Vue synthétique de l'architecture MPTDC", size=(12.2, 5.5))
    add_box(ax, (0.03, 0.40), (0.15, 0.20), "Entrées\nSPAD / CAL", COLORS["sys_fill"], ec=COLORS["sys"], fontsize=11)
    add_box(ax, (0.23, 0.40), (0.16, 0.20), "Frontend\nasynchrone", COLORS["async_fill"], ec=COLORS["async"], fontsize=11)
    add_box(ax, (0.45, 0.62), (0.15, 0.14), "Oscillateur\nlent", COLORS["slow_fill"], ec=COLORS["slow"], fontsize=11)
    add_box(ax, (0.45, 0.24), (0.15, 0.14), "Oscillateur\nrapide", COLORS["fast_fill"], ec=COLORS["fast"], fontsize=11)
    add_box(ax, (0.65, 0.39), (0.16, 0.23), "Matrice PD\n9×9 + contrôle", COLORS["fast_fill"], ec=COLORS["fast"], fontsize=11)
    add_box(ax, (0.86, 0.58), (0.11, 0.16), "Contextes\n×2", COLORS["purple_fill"], ec=COLORS["purple"], fontsize=11)
    add_box(ax, (0.86, 0.34), (0.11, 0.14), "Drain /\nFIFO", COLORS["sys_fill"], ec=COLORS["sys"], fontsize=11)
    add_box(ax, (0.86, 0.12), (0.11, 0.14), "TX\n16 bits", COLORS["sys_fill"], ec=COLORS["sys"], fontsize=11)

    add_arrow(ax, (0.18, 0.50), (0.23, 0.50), color=COLORS["gray"])
    add_arrow(ax, (0.39, 0.50), (0.45, 0.69), "START", offset=(-0.005, 0.045), color=COLORS["slow"])
    add_arrow(ax, (0.39, 0.50), (0.45, 0.31), "STOP", offset=(-0.005, -0.045), color=COLORS["fast"])
    add_arrow(ax, (0.60, 0.69), (0.65, 0.56), color=COLORS["slow"])
    add_arrow(ax, (0.60, 0.31), (0.65, 0.46), color=COLORS["fast"])
    add_arrow(ax, (0.81, 0.51), (0.86, 0.66), color=COLORS["purple"])
    add_arrow(ax, (0.81, 0.44), (0.86, 0.41), color=COLORS["sys"])
    add_arrow(ax, (0.915, 0.34), (0.915, 0.26), color=COLORS["sys"])

    add_label(ax, 0.52, 0.08, "Le cœur Vernier est découplé de la lecture système par le double-buffer et un FIFO.", ha="center", fontsize=9, color=COLORS["gray"])
    save(fig, "mptdc_overview")


def draw_mptdc_block_diagram() -> None:
    fig, ax = setup_diagram("Hiérarchie détaillée de MPTDC et domaines temporels", size=(14.5, 8.2))

    add_domain(ax, (0.02, 0.10), (0.20, 0.80), "Tissu asynchrone / événements", COLORS["async_fill"], COLORS["async"])
    add_domain(ax, (0.25, 0.54), (0.19, 0.36), "Domaine lent (~1.0 GHz)", COLORS["slow_fill"], COLORS["slow"])
    add_domain(ax, (0.46, 0.10), (0.28, 0.80), "Domaine rapide (~1.11 GHz)", COLORS["fast_fill"], COLORS["fast"])
    add_domain(ax, (0.77, 0.10), (0.21, 0.80), "Domaine système (160 MHz)", COLORS["sys_fill"], COLORS["sys"])

    add_box(ax, (0.04, 0.72), (0.15, 0.11), "mptdc_input_mux", COLORS["white"], ec=COLORS["async"], fontsize=10)
    add_box(ax, (0.04, 0.54), (0.15, 0.13), "mptdc_async_frontend_v2", COLORS["white"], ec=COLORS["async"], fontsize=10)
    add_box(ax, (0.04, 0.36), (0.15, 0.10), "mptdc_stop_\ncapture_async", COLORS["white"], ec=COLORS["async"], fontsize=10)
    add_box(ax, (0.04, 0.20), (0.15, 0.09), "mptdc_reset_sync", COLORS["white"], ec=COLORS["async"], fontsize=10)

    add_box(ax, (0.28, 0.73), (0.12, 0.11), "osc_slow\nwrapper", COLORS["white"], ec=COLORS["slow"], fontsize=10)
    add_box(ax, (0.28, 0.57), (0.12, 0.11), "gray_cnt_sync\nslow→fast", COLORS["white"], ec=COLORS["slow"], fontsize=10)

    add_box(ax, (0.50, 0.74), (0.13, 0.11), "osc_fast\nwrapper", COLORS["white"], ec=COLORS["fast"], fontsize=10)
    add_box(ax, (0.50, 0.58), (0.13, 0.11), "gray_cnt_sync\nfast local", COLORS["white"], ec=COLORS["fast"], fontsize=10)
    add_box(ax, (0.50, 0.40), (0.18, 0.13), "mptdc_pd_matrix\n81 cellules", COLORS["white"], ec=COLORS["fast"], fontsize=10)
    add_box(ax, (0.50, 0.22), (0.18, 0.11), "mptdc_meas_ctrl", COLORS["white"], ec=COLORS["purple"], fontsize=10)
    add_box(ax, (0.70, 0.46), (0.02, 0.04), "", COLORS["fast_fill"], ec=COLORS["fast"], fontsize=1)
    add_box(ax, (0.56, 0.09), (0.12, 0.09), "mptdc_watchdog\nctx/mesure", COLORS["white"], ec=COLORS["purple"], fontsize=9)
    add_box(ax, (0.56, 0.68), (0.15, 0.11), "mptdc_context_bank", COLORS["white"], ec=COLORS["purple"], fontsize=10)

    add_box(ax, (0.80, 0.70), (0.15, 0.11), "mptdc_drain_ctrl", COLORS["white"], ec=COLORS["sys"], fontsize=10)
    add_box(ax, (0.80, 0.52), (0.15, 0.11), "sync_fifo_64x", COLORS["white"], ec=COLORS["sys"], fontsize=10)
    add_box(ax, (0.80, 0.34), (0.15, 0.11), "mptdc_narrow16_tx_v2", COLORS["white"], ec=COLORS["sys"], fontsize=10)
    add_box(ax, (0.80, 0.16), (0.15, 0.11), "CSR + watchdog\nglobal", COLORS["white"], ec=COLORS["sys"], fontsize=10)

    add_arrow(ax, (0.19, 0.775), (0.28, 0.79), "sel entrée", offset=(0.0, 0.03), color=COLORS["async"])
    add_arrow(ax, (0.19, 0.605), (0.28, 0.785), "osc_slow_en", offset=(0.0, 0.05), color=COLORS["slow"])
    add_arrow(ax, (0.19, 0.605), (0.50, 0.795), "osc_fast_en", offset=(0.02, 0.05), color=COLORS["fast"])
    add_arrow(ax, (0.19, 0.605), (0.50, 0.46), "pd_enable", offset=(0.03, 0.03), color=COLORS["async"])
    add_arrow(ax, (0.19, 0.41), (0.56, 0.74), "phase0_snap,\nslow_boundary_inc", offset=(0.02, 0.05), color=COLORS["async"])
    add_arrow(ax, (0.19, 0.24), (0.56, 0.145), "rst_fast_n", offset=(0.02, -0.03), color=COLORS["async"])

    add_arrow(ax, (0.40, 0.79), (0.50, 0.50), "phases lentes", offset=(0.0, 0.04), color=COLORS["slow"])
    add_arrow(ax, (0.40, 0.625), (0.56, 0.74), "Nslow Gray\n+ snapshot STOP", offset=(0.0, 0.05), color=COLORS["slow"])
    add_arrow(ax, (0.63, 0.79), (0.68, 0.50), "phases rapides", offset=(0.03, 0.05), color=COLORS["fast"])
    add_arrow(ax, (0.63, 0.635), (0.56, 0.74), "Nfast local", offset=(0.02, 0.04), color=COLORS["fast"])
    add_arrow(ax, (0.68, 0.46), (0.56, 0.74), "bitmap hit +\nnfast_hit", offset=(-0.01, 0.04), color=COLORS["fast"])
    add_arrow(ax, (0.59, 0.22), (0.59, 0.18), "pd_clear", offset=(0.05, 0.00), color=COLORS["purple"])
    add_arrow(ax, (0.68, 0.27), (0.19, 0.60), "fe_clear / ctx alloc", offset=(0.0, 0.05), color=COLORS["purple"], rad=0.08)
    add_arrow(ax, (0.68, 0.27), (0.56, 0.74), "capture_en", offset=(-0.02, 0.04), color=COLORS["purple"])

    add_arrow(ax, (0.71, 0.74), (0.80, 0.755), "snapshot statique", offset=(0.0, 0.03), color=COLORS["sys"])
    add_arrow(ax, (0.71, 0.74), (0.80, 0.56), "ctx_drain_sync", offset=(0.0, 0.03), color=COLORS["sys"], rad=-0.15)
    add_arrow(ax, (0.95, 0.70), (0.95, 0.63), "META / HIT", offset=(0.04, 0.0), color=COLORS["sys"])
    add_arrow(ax, (0.95, 0.52), (0.95, 0.45), "fifo_rd", offset=(0.04, 0.0), color=COLORS["sys"])
    add_arrow(ax, (0.95, 0.34), (0.98, 0.34), "narrow_valid/data", offset=(0.0, 0.04), color=COLORS["sys"])
    add_arrow(ax, (0.80, 0.22), (0.19, 0.63), "ctx_release", offset=(-0.01, -0.03), color=COLORS["sys"], rad=0.10)

    add_label(ax, 0.51, 0.31, "capture rapide", fontsize=9, color=COLORS["fast"], weight="bold")
    add_label(ax, 0.83, 0.88, "export système", fontsize=9, color=COLORS["sys"], weight="bold")
    add_legend_swatches(
        ax,
        [
            ("Asynchrone", COLORS["async_fill"]),
            ("Oscillateur lent", COLORS["slow_fill"]),
            ("Oscillateur rapide", COLORS["fast_fill"]),
            ("Système", COLORS["sys_fill"]),
        ],
        x0=0.04,
        y0=0.04,
        dx=0.18,
    )
    save(fig, "mptdc_block_diagram")


def draw_async_frontend_fsm() -> None:
    fig, ax = setup_diagram("Frontend asynchrone : logique d'acceptation et de réarmement", size=(11.8, 5.6))

    add_box(ax, (0.05, 0.42), (0.17, 0.14), "Attente armée\nconv_arm=1\nctx libre", COLORS["async_fill"], ec=COLORS["async"], fontsize=11)
    add_box(ax, (0.31, 0.60), (0.18, 0.14), "START accepté\nstart_latched=1\nctx_id figé", COLORS["slow_fill"], ec=COLORS["slow"], fontsize=11)
    add_box(ax, (0.31, 0.24), (0.18, 0.14), "START rejeté\nstart_rejected=1", COLORS["light_gray"], ec=COLORS["danger"], fontsize=11)
    add_box(ax, (0.60, 0.60), (0.18, 0.14), "Mesure ouverte\nosc_slow_en=1", COLORS["slow_fill"], ec=COLORS["slow"], fontsize=11)
    add_box(ax, (0.60, 0.24), (0.18, 0.14), "STOP capturé\nstop_latched=1\nosc_fast_en=1", COLORS["fast_fill"], ec=COLORS["fast"], fontsize=11)
    add_box(ax, (0.82, 0.42), (0.13, 0.14), "Clear\nfrontend", COLORS["purple_fill"], ec=COLORS["purple"], fontsize=11)

    add_arrow(ax, (0.22, 0.49), (0.31, 0.67), "START & ctx_free & conv_arm", offset=(0.01, 0.05), color=COLORS["slow"])
    add_arrow(ax, (0.22, 0.49), (0.31, 0.31), "START invalide", offset=(0.01, -0.05), color=COLORS["danger"])
    add_arrow(ax, (0.49, 0.67), (0.60, 0.67), "osc_slow_en_async_o", offset=(0.0, 0.04), color=COLORS["slow"])
    add_arrow(ax, (0.69, 0.60), (0.69, 0.38), "STOP ou STOP watchdog", offset=(0.06, 0.0), color=COLORS["fast"])
    add_arrow(ax, (0.78, 0.31), (0.82, 0.49), "pd_enable = start & stop", offset=(0.03, 0.04), color=COLORS["async"])
    add_arrow(ax, (0.88, 0.42), (0.22, 0.42), "clear_any", offset=(0.0, -0.05), color=COLORS["purple"], rad=0.10)

    add_label(ax, 0.14, 0.24, r"$ctx\_free = \neg ctx\_drain$", fontsize=10, weight="bold", color=COLORS["dark"])
    add_label(ax, 0.14, 0.18, "Le contexte est reconsidéré libre dès que le drain est retombé,\nindépendamment de start_latched.", fontsize=9, color=COLORS["gray"])
    add_label(ax, 0.50, 0.06, "Représentation fonctionnelle : le frontend n'est pas un automate synchrone classique,\nmais une logique événementielle à verrous set/reset.", ha="center", fontsize=9, color=COLORS["gray"])
    save(fig, "async_frontend_fsm")


def draw_meas_ctrl_fsm() -> None:
    fig, ax = setup_diagram("FSM de mesure dans le domaine rapide", size=(12.0, 5.8))

    states = {
        "IDLE": (0.08, 0.42),
        "MEASURE": (0.28, 0.42),
        "CAPTURE": (0.50, 0.42),
        "STOP_OSC": (0.71, 0.42),
        "CLEAR": (0.88, 0.42),
    }
    widths = {"IDLE": 0.12, "MEASURE": 0.15, "CAPTURE": 0.14, "STOP_OSC": 0.14, "CLEAR": 0.10}
    texts = {
        "IDLE": "IDLE\npd_gate=0",
        "MEASURE": "MEASURE\npd_gate=1\nosc_keep_alive=1",
        "CAPTURE": "CAPTURE\ncapture_en=1",
        "STOP_OSC": "STOP_OSC\nfe_clear=1",
        "CLEAR": "CLEAR\npd_clear=1",
    }
    colors = {
        "IDLE": COLORS["light_gray"],
        "MEASURE": COLORS["fast_fill"],
        "CAPTURE": COLORS["purple_fill"],
        "STOP_OSC": COLORS["purple_fill"],
        "CLEAR": COLORS["light_gray"],
    }
    edges = {
        "IDLE": COLORS["gray"],
        "MEASURE": COLORS["fast"],
        "CAPTURE": COLORS["purple"],
        "STOP_OSC": COLORS["purple"],
        "CLEAR": COLORS["gray"],
    }

    for name, (x, y) in states.items():
        add_box(ax, (x, y), (widths[name], 0.16), texts[name], colors[name], ec=edges[name], fontsize=10)

    add_arrow(ax, (0.20, 0.50), (0.28, 0.50), "meas_active", offset=(0.0, 0.04), color=COLORS["fast"])
    add_arrow(ax, (0.43, 0.50), (0.50, 0.50), "close_any", offset=(0.0, 0.04), color=COLORS["purple"])
    add_arrow(ax, (0.64, 0.50), (0.71, 0.50), "1 cycle", offset=(0.0, 0.04), color=COLORS["gray"])
    add_arrow(ax, (0.85, 0.50), (0.88, 0.50), "1 cycle", offset=(0.0, 0.04), color=COLORS["gray"])
    add_arrow(ax, (0.98, 0.42), (0.14, 0.42), "retour IDLE", offset=(0.0, -0.05), color=COLORS["gray"], rad=0.20)
    add_arrow(ax, (0.36, 0.42), (0.36, 0.61), "¬close_any", offset=(0.07, 0.0), color=COLORS["fast"], rad=1.2)

    add_box(ax, (0.19, 0.12), (0.62, 0.18), "close_any = first_hit  OR  max_hits  OR  watchdog rapide\ncapture retardée d'un cycle pour figer une matrice PD stable avant clear", COLORS["white"], ec=COLORS["gray"], fontsize=10)
    save(fig, "meas_ctrl_fsm")


def draw_drain_ctrl_fsm() -> None:
    fig, ax = setup_diagram("FSM de drain dans le domaine système", size=(11.5, 5.6))

    add_box(ax, (0.08, 0.42), (0.14, 0.16), "ST_D_IDLE\nattente\nctx_drain_sync", COLORS["sys_fill"], ec=COLORS["sys"], fontsize=10)
    add_box(ax, (0.34, 0.42), (0.14, 0.16), "ST_D_META\npush META", COLORS["sys_fill"], ec=COLORS["sys"], fontsize=10)
    add_box(ax, (0.60, 0.42), (0.17, 0.16), "ST_D_SCAN\nscan 81 cellules\nordre fixe", COLORS["sys_fill"], ec=COLORS["sys"], fontsize=10)
    add_box(ax, (0.84, 0.42), (0.11, 0.16), "ST_D_EOC\nctx_release", COLORS["purple_fill"], ec=COLORS["purple"], fontsize=10)

    add_arrow(ax, (0.22, 0.50), (0.34, 0.50), "ctx disponible", offset=(0.0, 0.04), color=COLORS["sys"])
    add_arrow(ax, (0.48, 0.50), (0.60, 0.50), "fifo non plein", offset=(0.0, 0.04), color=COLORS["sys"])
    add_arrow(ax, (0.77, 0.50), (0.84, 0.50), "scan_done\nou all_hits_found", offset=(0.0, 0.05), color=COLORS["purple"])
    add_arrow(ax, (0.95, 0.42), (0.15, 0.42), "fin conversion", offset=(0.0, -0.05), color=COLORS["purple"], rad=0.16)

    add_arrow(ax, (0.41, 0.58), (0.41, 0.74), "stall si fifo plein", offset=(0.08, 0.0), color=COLORS["danger"], rad=1.2)
    add_arrow(ax, (0.685, 0.58), (0.685, 0.76), "hit + fifo plein :\nposition conservée", offset=(0.11, 0.0), color=COLORS["danger"], rad=1.2)

    add_box(ax, (0.14, 0.12), (0.72, 0.18), "Le scan suit l'ordre (ns majoritaire, puis nf). event_seq / hit_idx décrivent donc un ordre de paquetisation,\npas un ordre chronologique physique.", COLORS["white"], ec=COLORS["gray"], fontsize=10)
    save(fig, "drain_ctrl_fsm")


def draw_narrow16_tx_fsm() -> None:
    fig, ax = setup_diagram("FSM du sérialiseur narrow16 v2.3", size=(13.2, 6.4))

    add_box(ax, (0.05, 0.68), (0.11, 0.12), "S_IDLE", COLORS["light_gray"], ec=COLORS["gray"], fontsize=10)
    add_box(ax, (0.22, 0.68), (0.12, 0.12), "S_HEADER", COLORS["sys_fill"], ec=COLORS["sys"], fontsize=10)
    add_box(ax, (0.40, 0.68), (0.13, 0.12), "S_SUBHDR", COLORS["sys_fill"], ec=COLORS["sys"], fontsize=10)
    add_box(ax, (0.22, 0.40), (0.13, 0.12), "S_HIT_FETCH", COLORS["light_gray"], ec=COLORS["gray"], fontsize=10)
    add_box(ax, (0.40, 0.40), (0.11, 0.12), "S_HIT_W0", COLORS["sys_fill"], ec=COLORS["sys"], fontsize=10)
    add_box(ax, (0.57, 0.40), (0.11, 0.12), "S_HIT_W1", COLORS["sys_fill"], ec=COLORS["sys"], fontsize=10)
    add_box(ax, (0.74, 0.40), (0.11, 0.12), "S_HIT_W2", COLORS["sys_fill"], ec=COLORS["sys"], fontsize=10)
    add_box(ax, (0.74, 0.16), (0.11, 0.12), "S_HIT_W3", COLORS["sys_fill"], ec=COLORS["sys"], fontsize=10)
    add_box(ax, (0.90, 0.68), (0.08, 0.12), "S_EOC", COLORS["purple_fill"], ec=COLORS["purple"], fontsize=10)

    add_arrow(ax, (0.16, 0.74), (0.22, 0.74), "META FIFO", offset=(0.0, 0.035), color=COLORS["sys"])
    add_arrow(ax, (0.34, 0.74), (0.40, 0.74), "header émis", offset=(0.0, 0.035), color=COLORS["sys"])
    add_arrow(ax, (0.53, 0.74), (0.90, 0.74), "0 hit", offset=(0.0, 0.05), color=COLORS["purple"])
    add_arrow(ax, (0.46, 0.68), (0.285, 0.52), "hit_count > 0", offset=(-0.02, 0.05), color=COLORS["sys"])
    add_arrow(ax, (0.35, 0.46), (0.40, 0.46), "HIT FIFO", offset=(0.0, 0.035), color=COLORS["sys"])
    add_arrow(ax, (0.51, 0.46), (0.57, 0.46), color=COLORS["sys"])
    add_arrow(ax, (0.68, 0.46), (0.74, 0.46), "FULL / RAW_FEATURES", offset=(0.0, 0.035), color=COLORS["sys"])
    add_arrow(ax, (0.63, 0.40), (0.90, 0.74), "RAW_TIMESTAMP\net dernier hit", offset=(0.0, 0.03), color=COLORS["purple"], rad=0.05)
    add_arrow(ax, (0.79, 0.40), (0.79, 0.28), "FULL", offset=(0.06, 0.0), color=COLORS["sys"])
    add_arrow(ax, (0.85, 0.22), (0.90, 0.68), "dernier mot", offset=(0.03, 0.0), color=COLORS["purple"], rad=0.05)
    add_arrow(ax, (0.85, 0.16), (0.285, 0.40), "hit suivant", offset=(0.0, -0.04), color=COLORS["sys"], rad=-0.20)
    add_arrow(ax, (0.98, 0.68), (0.16, 0.68), "retour IDLE", offset=(0.0, -0.05), color=COLORS["purple"], rad=0.17)

    add_box(ax, (0.16, 0.06), (0.66, 0.16), "Tous les états émetteurs se bloquent sur narrow_ready=0 :\naucun mot n'est perdu, la FSM conserve simplement sa position jusqu'à reprise du handshake.", COLORS["white"], ec=COLORS["gray"], fontsize=10)
    add_box(ax, (0.84, 0.25), (0.12, 0.20), "Tailles:\nRAW_TS = 2N+3\nRAW_FEAT = 3N+3\nFULL = 4N+3", COLORS["white"], ec=COLORS["gray"], fontsize=10)
    save(fig, "narrow16_tx_fsm")


def draw_clock_domain_diagram() -> None:
    fig, ax = setup_diagram("Carte des domaines d'horloge et des traversées CDC", size=(13.2, 6.6))

    lanes = [
        (0.78, "Événements asynchrones", COLORS["async_fill"], COLORS["async"]),
        (0.58, "Domaine lent", COLORS["slow_fill"], COLORS["slow"]),
        (0.38, "Domaine rapide", COLORS["fast_fill"], COLORS["fast"]),
        (0.18, "Domaine système", COLORS["sys_fill"], COLORS["sys"]),
    ]
    for y, label, fill, edge in lanes:
        ax.add_patch(Rectangle((0.08, y - 0.08), 0.84, 0.13, facecolor=fill, edgecolor=edge, linewidth=1.2, alpha=0.65))
        add_label(ax, 0.02, y - 0.015, label, color=edge, fontsize=11, weight="bold")

    add_box(ax, (0.12, 0.76), (0.16, 0.08), "START / STOP\nctx_release", COLORS["white"], ec=COLORS["async"], fontsize=10)
    add_box(ax, (0.32, 0.76), (0.18, 0.08), "async_frontend\n+ stop_capture", COLORS["white"], ec=COLORS["async"], fontsize=10)

    add_box(ax, (0.28, 0.56), (0.16, 0.08), "osc_slow", COLORS["white"], ec=COLORS["slow"], fontsize=10)
    add_box(ax, (0.52, 0.56), (0.18, 0.08), "gray_cnt_sync\nsnapshot STOP", COLORS["white"], ec=COLORS["slow"], fontsize=10)

    add_box(ax, (0.28, 0.36), (0.16, 0.08), "osc_fast", COLORS["white"], ec=COLORS["fast"], fontsize=10)
    add_box(ax, (0.48, 0.36), (0.18, 0.08), "PD matrix\n+ meas_ctrl", COLORS["white"], ec=COLORS["fast"], fontsize=10)
    add_box(ax, (0.72, 0.36), (0.16, 0.08), "context_bank", COLORS["white"], ec=COLORS["fast"], fontsize=10)

    add_box(ax, (0.54, 0.16), (0.16, 0.08), "drain_ctrl\n+ FIFO", COLORS["white"], ec=COLORS["sys"], fontsize=10)
    add_box(ax, (0.76, 0.16), (0.14, 0.08), "narrow16\nserializer", COLORS["white"], ec=COLORS["sys"], fontsize=10)

    add_arrow(ax, (0.28, 0.80), (0.32, 0.80), "capture asynchrone", offset=(0.0, 0.04), color=COLORS["async"])
    add_arrow(ax, (0.40, 0.76), (0.36, 0.64), "START", offset=(-0.03, 0.01), color=COLORS["slow"])
    add_arrow(ax, (0.40, 0.76), (0.36, 0.44), "STOP", offset=(-0.03, 0.01), color=COLORS["fast"])
    add_arrow(ax, (0.44, 0.60), (0.52, 0.60), "Gray + 2FF", offset=(0.0, 0.04), color=COLORS["slow"])
    add_arrow(ax, (0.70, 0.60), (0.72, 0.40), "nslow_snap", offset=(0.03, 0.03), color=COLORS["slow"])
    add_arrow(ax, (0.44, 0.40), (0.48, 0.40), "phases rapides", offset=(0.0, 0.04), color=COLORS["fast"])
    add_arrow(ax, (0.66, 0.40), (0.72, 0.40), "capture_en", offset=(0.0, 0.04), color=COLORS["purple"])
    add_arrow(ax, (0.80, 0.36), (0.62, 0.24), "ctx_drain_sync", offset=(0.0, 0.04), color=COLORS["sys"], rad=-0.1)
    add_arrow(ax, (0.70, 0.20), (0.76, 0.20), "records META/HIT", offset=(0.0, 0.035), color=COLORS["sys"])
    add_arrow(ax, (0.90, 0.20), (0.94, 0.20), "bus 16 bits", offset=(0.0, 0.04), color=COLORS["sys"])
    add_arrow(ax, (0.60, 0.16), (0.20, 0.76), "ctx_release", offset=(0.0, -0.04), color=COLORS["sys"], rad=0.18)

    add_box(ax, (0.10, 0.03), (0.80, 0.08), "Traversées critiques : START/STOP asynchrones, nslow transféré en Gray vers le rapide,\nstatut de drain synchronisé vers clk_sys, puis release renvoyé vers le frontend.", COLORS["white"], ec=COLORS["gray"], fontsize=10)
    save(fig, "clock_domain_diagram")


def draw_pd_matrix_heatmap() -> None:
    ns = np.arange(NE)
    nf = np.arange(NE)
    coeff = K_VERNIER * ns[:, None] - (K_VERNIER - 1) * nf[None, :]
    values_ps = coeff * DELTA_LSB_PS

    fig, ax = plt.subplots(figsize=(8.8, 7.5))
    cmap = plt.get_cmap("coolwarm")
    im = ax.imshow(values_ps, origin="lower", cmap=cmap)

    for i in range(NE):
        for j in range(NE):
            ax.text(j, i, f"{int(values_ps[i, j]):+d}", ha="center", va="center", fontsize=8, color=COLORS["dark"])

    ax.set_title("Distribution des coefficients fins dans la matrice 9×9", fontweight="bold")
    ax.set_xlabel(r"Indice rapide $n_f$")
    ax.set_ylabel(r"Indice lent $n_s$")
    ax.set_xticks(np.arange(NE))
    ax.set_yticks(np.arange(NE))
    cbar = fig.colorbar(im, ax=ax, fraction=0.046, pad=0.04)
    cbar.set_label("Coefficient fin nominal (ps)")
    ax.text(
        0.5,
        -0.15,
        r"$t_{fine,\ nominal} = (11\,n_s - 10\,n_f)\times 10\,\mathrm{ps}$",
        transform=ax.transAxes,
        ha="center",
        fontsize=10,
        color=COLORS["gray"],
    )
    save(fig, "pd_matrix_heatmap")


def draw_fine_grid_coverage() -> None:
    ns = np.arange(NE)
    nf = np.arange(NE)
    coeff = K_VERNIER * ns[:, None] - (K_VERNIER - 1) * nf[None, :]
    reachable = np.sort(np.unique(coeff.ravel() * DELTA_LSB_PS))
    all_codes = np.arange(int(reachable.min()), int(reachable.max()) + DELTA_LSB_PS, DELTA_LSB_PS)
    missing = all_codes[~np.isin(all_codes, reachable)]
    gaps = np.diff(reachable)
    gap_x = (reachable[:-1] + reachable[1:]) / 2
    dnl = gaps / DELTA_LSB_PS - 1.0
    inl = np.concatenate([[0.0], np.cumsum(dnl)])

    fig = plt.figure(figsize=(12.2, 8.4))
    gs = GridSpec(3, 2, figure=fig, height_ratios=[1.05, 0.85, 1.0], hspace=0.35, wspace=0.28)

    ax0 = fig.add_subplot(gs[0, :])
    ax0.scatter(reachable, np.ones_like(reachable), s=48, marker="s", color=COLORS["success"], label="codes atteignables")
    ax0.scatter(missing, np.zeros_like(missing), s=36, marker="x", color=COLORS["danger"], label="codes manquants")
    ax0.set_yticks([0, 1])
    ax0.set_yticklabels(["manquant", "atteignable"])
    ax0.set_xlabel("Temps fin nominal (ps)")
    ax0.set_title("Couverture de la grille fine Vernier", fontweight="bold")
    ax0.grid(axis="x", alpha=0.25)
    ax0.legend(loc="upper left")
    coverage = len(reachable) / len(all_codes) * 100.0
    ax0.text(
        0.99,
        0.95,
        f"{len(reachable)} codes atteignables / {len(all_codes)} positions\n{len(missing)} trous, couverture = {coverage:.1f} %",
        transform=ax0.transAxes,
        ha="right",
        va="top",
        fontsize=10,
        bbox=dict(boxstyle="round,pad=0.3", facecolor="white", edgecolor=COLORS["gray"]),
    )

    ax1 = fig.add_subplot(gs[1, :])
    bars = ax1.bar(gap_x, gaps, width=8.0, color=COLORS["fast_fill"], edgecolor=COLORS["fast"])
    worst_idx = int(np.argmax(gaps))
    bars[worst_idx].set_facecolor(COLORS["gold"])
    bars[worst_idx].set_edgecolor(COLORS["dark"])
    ax1.set_ylabel("Écart entre deux codes\natteignables (ps)")
    ax1.set_xlabel("Position médiane du trou (ps)")
    ax1.set_title("Largeur locale des trous de quantification")
    ax1.grid(axis="y", alpha=0.25)
    ax1.text(gap_x[worst_idx], gaps[worst_idx] + 4, f"gap max = {int(gaps[worst_idx])} ps", ha="center", fontsize=9, color=COLORS["dark"])

    ax2 = fig.add_subplot(gs[2, 0])
    ax2.plot(reachable[1:], dnl, marker="o", color=COLORS["purple"], linewidth=1.6)
    ax2.axhline(0.0, color=COLORS["mid_gray"], linewidth=1.0)
    ax2.set_title("DNL brute estimée")
    ax2.set_xlabel("Code atteignable (ps)")
    ax2.set_ylabel("DNL (LSB)")
    ax2.grid(alpha=0.25)

    ax3 = fig.add_subplot(gs[2, 1])
    ax3.plot(reachable, inl, marker="o", color=COLORS["sys"], linewidth=1.6)
    ax3.axhline(0.0, color=COLORS["mid_gray"], linewidth=1.0)
    ax3.set_title("INL cumulée estimée")
    ax3.set_xlabel("Code atteignable (ps)")
    ax3.set_ylabel("INL (LSB)")
    ax3.grid(alpha=0.25)

    save(fig, "fine_grid_coverage")


def _word_x(msb: int, lsb: int) -> tuple[float, float]:
    width = msb - lsb + 1
    x = 15 - msb
    return x, width


def draw_bitfield_word(ax: plt.Axes, y: float, label: str, segments: list[tuple[int, int, str, str]], height: float = 0.42) -> None:
    ax.text(-1.3, y + height / 2, label, ha="left", va="center", fontsize=10, fontweight="bold")
    ax.add_patch(Rectangle((0, y), 16, height, facecolor="white", edgecolor=COLORS["gray"], linewidth=1.2))
    for msb, lsb, color, text in segments:
        x, width = _word_x(msb, lsb)
        ax.add_patch(Rectangle((x, y), width, height, facecolor=color, edgecolor=COLORS["gray"], linewidth=1.0))
        ax.text(x + width / 2, y + height / 2, text, ha="center", va="center", fontsize=8, color=COLORS["dark"])


def draw_packet_format_v23() -> None:
    fig, ax = plt.subplots(figsize=(13.2, 7.4))
    ax.set_xlim(-1.8, 20.5)
    ax.set_ylim(0.0, 4.4)
    ax.axis("off")
    ax.set_title("Format de paquet narrow16 v2.3", fontweight="bold", fontsize=14, pad=14)

    for bit in range(16):
        ax.text(bit + 0.5, 4.05, str(15 - bit), ha="center", va="bottom", fontsize=8, color=COLORS["gray"])
    ax.text(8.0, 4.22, "Bits (MSB à gauche)", ha="center", fontsize=9, color=COLORS["gray"])

    draw_bitfield_word(
        ax,
        3.45,
        "Header",
        [
            (15, 14, COLORS["sys_fill"], "10"),
            (13, 12, COLORS["purple_fill"], "ctx"),
            (11, 11, COLORS["slow_fill"], "phase0"),
            (10, 7, COLORS["fast_fill"], "hit_count"),
            (6, 3, COLORS["async_fill"], "flags"),
            (2, 1, COLORS["light_gray"], "mode"),
            (0, 0, COLORS["gold"], "sbi"),
        ],
    )
    draw_bitfield_word(
        ax,
        2.85,
        "Sub-header",
        [
            (15, 13, COLORS["sys_fill"], "101"),
            (12, 6, COLORS["purple_fill"], "nfast_stop"),
            (5, 0, COLORS["light_gray"], "réservé"),
        ],
    )
    draw_bitfield_word(
        ax,
        2.25,
        "Hit W0",
        [
            (15, 15, COLORS["light_gray"], "0"),
            (14, 8, COLORS["slow_fill"], "nslow"),
            (7, 1, COLORS["fast_fill"], "nfast_hit"),
            (0, 0, COLORS["light_gray"], "0"),
        ],
    )
    draw_bitfield_word(
        ax,
        1.65,
        "Hit W1 feat",
        [
            (15, 15, COLORS["light_gray"], "0"),
            (14, 11, COLORS["slow_fill"], "ns"),
            (10, 7, COLORS["fast_fill"], "nf"),
            (6, 0, COLORS["purple_fill"], "pd_idx"),
        ],
    )
    draw_bitfield_word(
        ax,
        1.05,
        "Hit W1 ts",
        [
            (15, 0, COLORS["sys_fill"], "t_raw_ps[15:0]"),
        ],
    )
    draw_bitfield_word(
        ax,
        0.45,
        "Hit W2 / W3 / EOC",
        [
            (15, 15, COLORS["light_gray"], "0"),
            (14, 11, COLORS["purple_fill"], "event_seq"),
            (10, 4, COLORS["fast_fill"], "nfast_snap"),
            (3, 0, COLORS["light_gray"], "0"),
        ],
    )
    draw_bitfield_word(
        ax,
        -0.15,
        "W3 ou EOC",
        [
            (15, 14, COLORS["sys_fill"], "11"),
            (13, 0, COLORS["gold"], "conv_count"),
        ],
    )

    add_box(
        ax,
        (16.8 / 20.5, 0.12),
        (3.1 / 20.5, 0.72),
        "Contrats:\nRAW_TIMESTAMP = W0 + W1 ts\nRAW_FEATURES = W0 + W1 feat + W2\nFULL = W0 + W1 feat + W2 + W3",
        COLORS["white"],
        ec=COLORS["gray"],
        fontsize=9,
    )
    save(fig, "packet_format_v23")


def _plot_digital(ax: plt.Axes, times: list[float], values: list[int], base: float, amp: float, color: str, label: str) -> None:
    y = base + amp * np.array(values)
    ax.step(times, y, where="post", color=color, linewidth=2.0)
    ax.text(times[0] - 0.55, base + amp * 0.45, label, ha="right", va="center", fontsize=10, color=COLORS["dark"])


def draw_timing_diagram_conversion() -> None:
    fig, ax = plt.subplots(figsize=(13.2, 7.1))
    ax.set_title("Chronogramme synthétique d'une conversion complète", fontweight="bold")
    ax.set_xlim(0, 16.5)
    ax.set_ylim(-0.3, 10.2)
    ax.set_xlabel("Temps (ns)")
    ax.set_yticks([])
    ax.grid(axis="x", alpha=0.25)

    _plot_digital(ax, [0, 1.0, 1.2, 16.5], [0, 1, 0, 0], 9.0, 0.6, COLORS["async"], "START")
    _plot_digital(ax, [0, 4.1, 4.3, 16.5], [0, 1, 0, 0], 8.0, 0.6, COLORS["async"], "STOP")
    _plot_digital(ax, [0, 1.0, 9.1, 16.5], [0, 1, 0, 0], 7.0, 0.6, COLORS["slow"], "osc_slow_en")
    _plot_digital(ax, [0, 4.1, 9.1, 16.5], [0, 1, 0, 0], 6.0, 0.6, COLORS["fast"], "osc_fast_en")

    slow_edges = np.arange(1.3, 8.9, 0.99)
    fast_edges = np.arange(4.45, 8.95, 0.90)
    ax.hlines(5.3, 0.5, 15.8, color=COLORS["mid_gray"], linewidth=1.0)
    ax.hlines(4.2, 0.5, 15.8, color=COLORS["mid_gray"], linewidth=1.0)
    for x in slow_edges:
        ax.vlines(x, 5.0, 5.6, color=COLORS["slow"], linewidth=2)
    for x in fast_edges:
        ax.vlines(x, 3.9, 4.5, color=COLORS["fast"], linewidth=2)
    ax.text(-0.05, 5.3, "slow_phase[0]", ha="right", va="center", fontsize=10, color=COLORS["dark"])
    ax.text(-0.05, 4.2, "fast_phase[0]", ha="right", va="center", fontsize=10, color=COLORS["dark"])

    _plot_digital(ax, [0, 6.95, 7.35, 16.5], [0, 1, 0, 0], 3.0, 0.6, COLORS["fast"], "any_hit / close_any")
    _plot_digital(ax, [0, 7.85, 8.15, 16.5], [0, 1, 0, 0], 2.0, 0.6, COLORS["purple"], "capture_en")
    _plot_digital(ax, [0, 8.80, 9.10, 16.5], [0, 1, 0, 0], 1.0, 0.6, COLORS["purple"], "fe_clear")
    _plot_digital(ax, [0, 9.70, 10.00, 16.5], [0, 1, 0, 0], 0.0, 0.6, COLORS["purple"], "pd_clear")

    ax.axvspan(7.2, 8.1, color=COLORS["purple_fill"], alpha=0.5)
    ax.text(7.65, 3.75, "1 cycle rapide pour stabiliser\nla matrice avant capture", ha="center", va="bottom", fontsize=9, color=COLORS["purple"])
    ax.axvspan(11.0, 14.8, color=COLORS["sys_fill"], alpha=0.45)
    ax.text(12.9, 6.7, "drain + FIFO + émission narrow16", ha="center", fontsize=10, color=COLORS["sys"], weight="bold")

    ax.annotate("osc rapide démarre au STOP", xy=(4.1, 6.0), xytext=(5.3, 7.0), arrowprops=dict(arrowstyle="-|>", color=COLORS["fast"], lw=1.2), fontsize=9, color=COLORS["fast"])
    ax.annotate("snapshot de contexte", xy=(8.0, 2.6), xytext=(9.4, 3.3), arrowprops=dict(arrowstyle="-|>", color=COLORS["purple"], lw=1.2), fontsize=9, color=COLORS["purple"])

    save(fig, "timing_diagram_conversion")


def draw_context_pipeline() -> None:
    fig, ax = plt.subplots(figsize=(12.4, 4.8))
    ax.set_title("Pipeline à double contexte", fontweight="bold")
    ax.set_xlim(0, 10)
    ax.set_ylim(-0.1, 2.3)
    ax.set_xlabel("Temps arbitraire")
    ax.set_yticks([1.55, 0.65])
    ax.set_yticklabels(["ctx0", "ctx1"])
    ax.grid(axis="x", alpha=0.22)

    def block(row: float, x0: float, x1: float, color: str, text: str, edge: str) -> None:
        ax.add_patch(Rectangle((x0, row), x1 - x0, 0.55, facecolor=color, edgecolor=edge, linewidth=1.2))
        ax.text((x0 + x1) / 2, row + 0.275, text, ha="center", va="center", fontsize=9)

    block(1.28, 0.4, 3.0, COLORS["fast_fill"], "capture conv k", COLORS["fast"])
    block(1.28, 3.0, 3.5, COLORS["purple_fill"], "snapshot", COLORS["purple"])
    block(1.28, 3.5, 6.9, COLORS["sys_fill"], "drain + TX", COLORS["sys"])
    block(1.28, 6.9, 9.6, COLORS["light_gray"], "libre / re-armé", COLORS["gray"])

    block(0.38, 0.4, 2.1, COLORS["light_gray"], "libre", COLORS["gray"])
    block(0.38, 2.4, 5.1, COLORS["fast_fill"], "capture conv k+1", COLORS["fast"])
    block(0.38, 5.1, 5.6, COLORS["purple_fill"], "snapshot", COLORS["purple"])
    block(0.38, 5.6, 9.0, COLORS["sys_fill"], "drain + TX", COLORS["sys"])

    ax.annotate("recouvrement mesure / lecture", xy=(4.3, 1.0), xytext=(4.3, 2.0), ha="center", arrowprops=dict(arrowstyle="<->", color=COLORS["purple"], lw=1.4), fontsize=9, color=COLORS["purple"])
    ax.text(8.8, 2.05, "si les deux contextes sont occupés,\nSTART suivant est rejeté", ha="center", va="top", fontsize=9, color=COLORS["danger"])

    handles = [
        Rectangle((0, 0), 1, 1, facecolor=COLORS["fast_fill"], edgecolor=COLORS["fast"], label="capture"),
        Rectangle((0, 0), 1, 1, facecolor=COLORS["purple_fill"], edgecolor=COLORS["purple"], label="snapshot figé"),
        Rectangle((0, 0), 1, 1, facecolor=COLORS["sys_fill"], edgecolor=COLORS["sys"], label="drain / sérialisation"),
        Rectangle((0, 0), 1, 1, facecolor=COLORS["light_gray"], edgecolor=COLORS["gray"], label="libre"),
    ]
    ax.legend(handles=handles, loc="upper left", ncol=4, frameon=False)
    save(fig, "context_pipeline")


def draw_boundary_disambiguation() -> None:
    fig, axes = plt.subplots(1, 2, figsize=(12.6, 4.8), sharey=True)
    fig.suptitle("Disambiguïsation de frontière coarse / fine", fontweight="bold", y=0.98)

    cases = [
        ("STOP juste avant phase0", -0.08, 0, 0, "Nslow = k"),
        ("STOP juste après phase0", 0.08, 1, 1, "Nslow = k+1"),
    ]
    for ax, (title, stop_x, phase0, sbi, coarse_text) in zip(axes, cases):
        ax.set_xlim(-0.5, 0.5)
        ax.set_ylim(-0.2, 2.4)
        ax.set_xticks([])
        ax.set_yticks([])
        ax.set_title(title, fontsize=11)
        ax.hlines(1.6, -0.45, 0.45, color=COLORS["mid_gray"], linewidth=1.0)
        ax.hlines(0.8, -0.45, 0.45, color=COLORS["mid_gray"], linewidth=1.0)
        ax.text(-0.52, 1.6, "phase0", ha="right", va="center", fontsize=10)
        ax.text(-0.52, 0.8, "compteur lent", ha="right", va="center", fontsize=10)
        ax.step([-0.45, 0.0, 0.45], [1.35, 1.85, 1.85], where="post", color=COLORS["slow"], linewidth=2.4)
        ax.step([-0.45, 0.0, 0.45], [0.55, 0.55, 1.05], where="post", color=COLORS["purple"], linewidth=2.4)
        ax.axvline(0.0, color=COLORS["gray"], linestyle="--", linewidth=1.1)
        ax.axvline(stop_x, color=COLORS["async"], linewidth=2.0)
        ax.text(stop_x, 2.1, "STOP", ha="center", color=COLORS["async"], fontsize=10)
        ax.text(0.02, 1.05, coarse_text, color=COLORS["purple"], fontsize=10, weight="bold")
        ax.text(-0.42, 0.22, f"phase0_snap = {phase0}", fontsize=10, color=COLORS["slow"])
        ax.text(-0.42, 0.00, f"slow_boundary_inc = {sbi}", fontsize=10, color=COLORS["purple"])
        ax.text(-0.42, -0.16, "sans ces bits : ambiguïté ±1 période lente", fontsize=9, color=COLORS["gray"])

    save(fig, "boundary_disambiguation")


def draw_calibration_flow() -> None:
    fig, ax = setup_diagram("Chaîne de calibration offline", size=(13.4, 5.8))

    add_box(ax, (0.03, 0.40), (0.17, 0.22), "Paquet v2.3\nnslow, nfast_hit,\nns, nf, phase0,\nhit_idx, nfast_snap", COLORS["sys_fill"], ec=COLORS["sys"], fontsize=10)
    add_box(ax, (0.26, 0.40), (0.17, 0.22), "Extraction hôte\nCSV / campagnes\nseed par seed", COLORS["light_gray"], ec=COLORS["gray"], fontsize=10)
    add_box(ax, (0.49, 0.58), (0.16, 0.14), "Clé 6D\n(ns, nf, nslow,\nnfast_hit,\nphase0_snap, hit_idx)", COLORS["purple_fill"], ec=COLORS["purple"], fontsize=10)
    add_box(ax, (0.49, 0.24), (0.16, 0.14), "t_raw_ps +\ninverseur 81 états", COLORS["fast_fill"], ec=COLORS["fast"], fontsize=10)
    add_box(ax, (0.72, 0.58), (0.13, 0.14), "LUT 6D", COLORS["slow_fill"], ec=COLORS["slow"], fontsize=10)
    add_box(ax, (0.72, 0.24), (0.13, 0.14), "GBR /\nmodèles", COLORS["slow_fill"], ec=COLORS["slow"], fontsize=10)
    add_box(ax, (0.89, 0.40), (0.10, 0.22), "t corrigé\nmono-hit", COLORS["gold"], ec=COLORS["gray"], fontsize=10)
    add_box(ax, (0.89, 0.10), (0.10, 0.18), "moyennage\nmulti-hit\n+ métriques", COLORS["white"], ec=COLORS["gray"], fontsize=10)

    add_arrow(ax, (0.20, 0.51), (0.26, 0.51), color=COLORS["sys"])
    add_arrow(ax, (0.43, 0.56), (0.49, 0.65), "features riches", offset=(0.0, 0.04), color=COLORS["purple"])
    add_arrow(ax, (0.43, 0.46), (0.49, 0.31), "timestamp brut", offset=(0.0, -0.04), color=COLORS["fast"])
    add_arrow(ax, (0.65, 0.65), (0.72, 0.65), color=COLORS["slow"])
    add_arrow(ax, (0.65, 0.31), (0.72, 0.31), color=COLORS["slow"])
    add_arrow(ax, (0.85, 0.65), (0.89, 0.52), color=COLORS["gray"])
    add_arrow(ax, (0.85, 0.31), (0.89, 0.50), color=COLORS["gray"])
    add_arrow(ax, (0.94, 0.40), (0.94, 0.28), "N hits / conversion", offset=(0.07, 0.0), color=COLORS["purple"])

    add_label(ax, 0.50, 0.08, "Philosophie du projet : laisser le silicium exporter des observables stables,\nplacer la correction statistique, l'adaptation PVT et le choix du modèle côté hôte.", ha="center", fontsize=9, color=COLORS["gray"])
    save(fig, "calibration_flow")


def draw_calibration_results_plot() -> None:
    nominal = load_json_result("calibration_enhanced_nominal")
    jitter = load_json_result("calibration_enhanced_jitter")
    metrics, _ = parse_calibration_report()
    nominal_methods = method_map(nominal)
    jitter_methods = method_map(jitter)

    selected = [
        ("6D LUT (mean)", "6D LUT"),
        ("6D LUT (trimmed mean)", "6D LUT\ntronquée"),
        ("GradientBoosted", "GBR"),
        ("Temporal Re-Keyed LUT", "LUT\nre-clée"),
        ("Polynomial (deg 3)", "Poly.\ndeg 3"),
    ]
    nominal_rmse = [nominal_methods[key]["test"]["rmse"] for key, _ in selected]
    jitter_rmse = [jitter_methods[key]["test"]["rmse"] for key, _ in selected]

    fig = plt.figure(figsize=(12.8, 8.2))
    gs = GridSpec(2, 2, figure=fig, height_ratios=[1.25, 1.0], width_ratios=[1.25, 0.95], hspace=0.38, wspace=0.28)

    ax0 = fig.add_subplot(gs[0, :])
    x = np.arange(len(selected))
    width = 0.34
    ax0.bar(x - width / 2, nominal_rmse, width, label="Nominal", color=COLORS["slow_fill"], edgecolor=COLORS["slow"])
    ax0.bar(x + width / 2, jitter_rmse, width, label=r"Jitter $\sigma=6$ ps", color=COLORS["fast_fill"], edgecolor=COLORS["fast"])
    ax0.set_xticks(x)
    ax0.set_xticklabels([label for _, label in selected])
    ax0.set_ylabel("RMSE test (ps)")
    ax0.set_title("Comparaison des méthodes de calibration")
    ax0.legend(frameon=False)
    ax0.grid(axis="y", alpha=0.25)
    ax0.axhline(metrics["fresh_post_rmse"], linestyle="--", linewidth=1.2, color=COLORS["purple"])
    ax0.text(4.35, metrics["fresh_post_rmse"] + 1.0, f"baseline maintenue = {metrics['fresh_post_rmse']:.2f} ps", ha="right", fontsize=9, color=COLORS["purple"])

    ax1 = fig.add_subplot(gs[1, 0])
    fi = jitter_methods["GradientBoosted"]["feature_importances"]
    labels = [
        ("nf_inf", "nf"),
        ("ns_inf", "ns"),
        ("phase0_snap", "phase0_snap"),
        ("nfast_hit", "nfast_hit"),
        ("hit_idx", "hit_idx"),
        ("nfast_snap", "nfast_snap"),
        ("nslow", "nslow"),
        ("slow_boundary_inc", "slow_boundary_inc"),
    ]
    values = np.array([fi[key] for key, _ in labels])
    names = [name for _, name in labels]
    order = np.argsort(values)
    ax1.barh(np.array(names)[order], values[order], color=COLORS["purple_fill"], edgecolor=COLORS["purple"])
    ax1.set_xlabel("Importance relative")
    ax1.set_title("Importances de variables GBR sous jitter")
    ax1.grid(axis="x", alpha=0.25)

    ax2 = fig.add_subplot(gs[1, 1])
    ax2.axis("off")
    held_pre = metrics["held_pre_rmse"]
    held_post = metrics["held_post_rmse"]
    best_nominal = min(nominal_rmse)
    best_jitter = min(jitter_rmse)
    improvement = 100.0 * (1.0 - held_post / held_pre)
    summary = (
        "Lecture rapide\n\n"
        f"• Baseline maintenue : {held_pre:.2f} ps → {held_post:.2f} ps\n"
        f"• Gain relatif : {improvement:.1f} %\n"
        f"• Meilleur nominal : {best_nominal:.2f} ps\n"
        f"• Meilleur sous jitter : {best_jitter:.2f} ps\n"
        "• Les variables fines (nf, ns, phase0)\n  dominent nettement la reconstruction."
    )
    ax2.text(
        0.02,
        0.98,
        summary,
        ha="left",
        va="top",
        fontsize=11,
        bbox=dict(boxstyle="round,pad=0.5", facecolor="white", edgecolor=COLORS["gray"]),
    )

    save(fig, "calibration_results_plot")


def draw_multihit_averaging_plot() -> None:
    jitter = load_json_result("calibration_enhanced_jitter")
    _, report_curve = parse_calibration_report()

    n_nom = report_curve["n"]
    rmse_nom = report_curve["rmse"]
    ideal = rmse_nom[0] / np.sqrt(n_nom)

    jitter_trimmed = jitter["averaging"]["trimmed"]
    n_jitter = np.array(sorted(int(key) for key in jitter_trimmed.keys()), dtype=float)
    rmse_jitter = np.array([jitter_trimmed[str(int(n))]["rmse"] for n in n_jitter], dtype=float)

    fig, ax = plt.subplots(figsize=(12.2, 5.8))
    ax.plot(n_nom, rmse_nom, marker="o", linewidth=2.0, color=COLORS["slow"], label="Nominal 6D LUT (rapport maintenu)")
    ax.plot(n_nom, ideal, linestyle="--", linewidth=1.5, color=COLORS["mid_gray"], label=r"Loi idéale $1/\sqrt{N}$")
    ax.plot(n_jitter, rmse_jitter, marker="s", linewidth=1.8, color=COLORS["fast"], label=r"Jitter $\sigma=6$ ps (trimmed)")
    ax.set_xscale("log")
    ax.set_xlabel("Nombre de hits moyennés")
    ax.set_ylabel("RMSE (ps)")
    ax.set_title("Gain de résolution par moyennage multi-hit", fontweight="bold")
    ax.grid(alpha=0.25, which="both")
    ax.legend(frameon=False)
    ax.set_xticks([1, 3, 5, 10, 15, 20, 50, 100, 1000])
    ax.get_xaxis().set_major_formatter(matplotlib.ticker.ScalarFormatter())
    idx_15 = int(np.where(n_nom == 15)[0][0])
    ax.annotate(
        f"{rmse_nom[idx_15]:.2f} ps à 15 hits",
        xy=(15, rmse_nom[idx_15]),
        xytext=(27, rmse_nom[idx_15] + 2.2),
        arrowprops=dict(arrowstyle="-|>", color=COLORS["slow"], lw=1.2),
        fontsize=9,
        color=COLORS["slow"],
    )
    ax.annotate(
        f"{rmse_jitter[-1]:.2f} ps sous jitter",
        xy=(15, rmse_jitter[-1]),
        xytext=(27, rmse_jitter[-1] + 4.0),
        arrowprops=dict(arrowstyle="-|>", color=COLORS["fast"], lw=1.2),
        fontsize=9,
        color=COLORS["fast"],
    )
    save(fig, "multihit_averaging_plot")


def _load_fixed_delay(config_dir: str) -> dict:
    import csv

    path = RESULTS_DIR / config_dir / "analysis" / "fixed_delay_summary.csv"
    if not path.exists():
        return {}
    rows = {"conv_mean": {}, "first_hit_scan": {}, "row": {}}
    with open(path) as f:
        reader = csv.DictReader(f)
        for r in reader:
            kind = r["sample_kind"]
            if kind not in rows:
                continue
            d = int(r["delay_ps"])
            rows[kind][d] = {
                "rmse": float(r["rmse"]),
                "mae": float(r["mae"]),
                "p90": float(r["p90_ae"]),
                "p99": float(r["p99_ae"]),
                "std": float(r["std"]),
            }
    return rows


def draw_fixed_delay_rmse_curve() -> None:
    """RMSE vs programmed delay, nominal vs jitter, single-shot vs moyenne par conversion."""
    full = _load_fixed_delay("fixed_delay_full_jitter_js6b24")
    short = _load_fixed_delay("fixed_delay_shortformat_jitter_js6b24")
    if not full or not short:
        return

    fig, axes = plt.subplots(1, 2, figsize=(12.6, 5.2), sharey=True)
    for ax, data, title in zip(
        axes,
        (full, short),
        ("Mode FULL (jitter $\sigma=6$ ps)", "Mode SHORT-FORMAT (jitter $\sigma=6$ ps)"),
    ):
        for kind, color, label, marker in [
            ("row", COLORS["mid_gray"], "Single-shot", "o"),
            ("first_hit_scan", COLORS["fast"], "First-hit (scan order)", "s"),
            ("conv_mean", COLORS["sys"], "Moyenne 15-hit (conv_mean)", "D"),
        ]:
            delays = sorted(data[kind].keys())
            rmse = [data[kind][d]["rmse"] for d in delays]
            ax.plot(delays, rmse, marker=marker, linewidth=1.6, color=color, label=label, markersize=5)
        ax.set_xscale("log")
        ax.set_xlabel("Délai programmé (ps)")
        ax.set_title(title, fontsize=11)
        ax.grid(alpha=0.25, which="both", linestyle=":")
    axes[0].set_ylabel("RMSE sur l'erreur de mesure (ps)")
    axes[0].legend(frameon=False, fontsize=9, loc="upper right")
    fig.suptitle(
        "Caractérisation délai fixe : RMSE en fonction du délai de consigne",
        fontsize=12, fontweight="bold", y=1.00,
    )
    save(fig, "fixed_delay_rmse_curve")


def draw_calibration_methods_comparison() -> None:
    """Comparaison nominale vs jitter des méthodes enrichies."""
    nom = load_json_result("calibration_enhanced_nominal")
    jit = load_json_result("calibration_enhanced_jitter")
    if not nom or not jit:
        return

    labels_order = [
        "6D LUT (mean)",
        "6D LUT (median)",
        "6D LUT (trimmed mean)",
        "GradientBoosted",
        "Temporal Re-Keyed LUT",
        "Polynomial (deg 3)",
        "Polynomial (deg 2)",
    ]
    short_names = {
        "6D LUT (mean)": "LUT 6D\nmoyenne",
        "6D LUT (median)": "LUT 6D\nmédiane",
        "6D LUT (trimmed mean)": "LUT 6D\ntronquée",
        "GradientBoosted": "GBR",
        "Temporal Re-Keyed LUT": "LUT re-clefée\ntemporel",
        "Polynomial (deg 3)": "Polynôme\ndeg 3",
        "Polynomial (deg 2)": "Polynôme\ndeg 2",
    }
    by_label_nom = {m["label"]: m for m in nom["methods"]}
    by_label_jit = {m["label"]: m for m in jit["methods"]}
    rmse_nom, rmse_jit, names = [], [], []
    for lab in labels_order:
        if lab in by_label_nom and lab in by_label_jit:
            rmse_nom.append(by_label_nom[lab]["test"]["rmse"])
            rmse_jit.append(by_label_jit[lab]["test"]["rmse"])
            names.append(short_names[lab])

    x = np.arange(len(names))
    w = 0.4
    fig, ax = plt.subplots(figsize=(12.2, 5.4))
    bars_n = ax.bar(x - w / 2, rmse_nom, width=w, color=COLORS["sys"], edgecolor=COLORS["dark"], linewidth=0.8, label="Nominal")
    bars_j = ax.bar(x + w / 2, rmse_jit, width=w, color=COLORS["mid_gray"], edgecolor=COLORS["dark"], linewidth=0.8, label=r"Jitter $\sigma=6$ ps")
    for bar in list(bars_n) + list(bars_j):
        h = bar.get_height()
        ax.text(bar.get_x() + bar.get_width() / 2, h + 1.5, f"{h:.1f}", ha="center", va="bottom", fontsize=8, color=COLORS["dark"])
    ax.set_xticks(x)
    ax.set_xticklabels(names, fontsize=9)
    ax.set_ylabel("RMSE sur jeu de test (ps)")
    ax.set_title("Comparaison des méthodes de correction, single-shot", fontweight="bold")
    ax.legend(frameon=False, loc="upper left")
    ax.grid(axis="y", alpha=0.25, linestyle=":")
    ax.set_axisbelow(True)
    save(fig, "calibration_methods_comparison")


def draw_shortformat_limit_plot() -> None:
    """Plafond pratique du mode short-format sous jitter, illustré via l'oracle et les modèles."""
    report = RESULTS_DIR / "shortformat_deep" / "analysis" / "report.txt"
    if not report.exists():
        return
    text = report.read_text()

    import re as _re

    def grab(pattern: str) -> float | None:
        m = _re.search(pattern, text)
        return float(m.group(1)) if m else None

    best_practical = grab(r"Best practical model:[\s\S]+?RMSE\s*:\s*([0-9.]+)\s*ps")
    best_exact = grab(r"Best exact-key[\s\S]+?RMSE\s*:\s*([0-9.]+)\s*ps")
    oracle = grab(r"Oracle floor \(robust[\s\S]+?RMSE\s*:\s*([0-9.]+)\s*ps")
    if None in (best_practical, best_exact, oracle):
        return

    labels = [
        "Oracle\n(clef robuste)",
        "Meilleur\nexact-key",
        "Meilleur\nmodèle pratique",
    ]
    values = [oracle, best_exact, best_practical]
    colors = [COLORS["mid_gray"], COLORS["sys"], COLORS["fast"]]

    fig, ax = plt.subplots(figsize=(9.5, 5.0))
    bars = ax.bar(labels, values, color=colors, edgecolor=COLORS["dark"], linewidth=0.9, width=0.55)
    for bar, v in zip(bars, values):
        ax.text(bar.get_x() + bar.get_width() / 2, v + 0.8, f"{v:.2f} ps", ha="center", va="bottom", fontsize=10, color=COLORS["dark"])
    ax.axhline(20.0, color=COLORS["async"], linestyle="--", linewidth=1.2, alpha=0.8)
    ax.text(2.45, 21.0, "Cible < 20 ps", color=COLORS["async"], fontsize=9, ha="right")
    ax.set_ylabel("RMSE (ps) sur jeu jitter tenu de côté")
    ax.set_title("Plafond pratique du mode SHORT-FORMAT sous jitter $\sigma=6$ ps", fontweight="bold")
    ax.grid(axis="y", alpha=0.25, linestyle=":")
    ax.set_axisbelow(True)
    ax.set_ylim(0, max(values) * 1.25)
    save(fig, "shortformat_limit_plot")


def draw_all() -> None:
    draw_measurement_chain()
    draw_vernier_reference_architecture()
    draw_vernier_principle_detailed()
    draw_vernier_transition_map()
    draw_mptdc_overview()
    draw_mptdc_block_diagram()
    draw_async_frontend_fsm()
    draw_meas_ctrl_fsm()
    draw_drain_ctrl_fsm()
    draw_narrow16_tx_fsm()
    draw_clock_domain_diagram()
    draw_pd_matrix_heatmap()
    draw_fine_grid_coverage()
    draw_packet_format_v23()
    draw_timing_diagram_conversion()
    draw_context_pipeline()
    draw_boundary_disambiguation()
    draw_calibration_flow()
    draw_calibration_results_plot()
    draw_multihit_averaging_plot()
    draw_fixed_delay_rmse_curve()
    draw_calibration_methods_comparison()
    draw_shortformat_limit_plot()


if __name__ == "__main__":
    draw_all()
