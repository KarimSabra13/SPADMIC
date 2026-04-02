#!/usr/bin/env python3
"""Generate a two-page A4 PDF comparing single-ended and differential ring oscillators."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Tuple

import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.backends.backend_pdf import PdfPages
from matplotlib.gridspec import GridSpec, GridSpecFromSubplotSpec
from matplotlib.patches import Circle, FancyArrowPatch, FancyBboxPatch, Polygon, Rectangle
from matplotlib.ticker import FuncFormatter


mpl.rcParams.update(
    {
        "font.family": "DejaVu Sans",
        "axes.titlesize": 11,
        "axes.labelsize": 9,
        "xtick.labelsize": 8,
        "ytick.labelsize": 8,
        "figure.facecolor": "white",
        "savefig.facecolor": "white",
    }
)


A4_PORTRAIT = (8.27, 11.69)
TITLE_COLOR = "#17324D"
SUBTITLE_COLOR = "#51606F"
BOX_EDGE = "#8FA2B2"
BOX_FILL = "#F7FAFC"
GRID_COLOR = "#D5DCE3"
P_COLOR = "#2E7AC9"
N_COLOR = "#CE5C66"
SINGLE_COLORS = [
    "#1B4965",
    "#2F6C8E",
    "#3C8DAD",
    "#4FA3B9",
    "#63B4C7",
    "#7C8FA3",
    "#8C6F9F",
    "#A05C7F",
    "#B3475E",
]
P_STAGE_COLORS = ["#1F5AA6", "#2F7BC1", "#3F95CF", "#5AA9D6"]
N_STAGE_COLORS = ["#A53A49", "#BC5560", "#CC6C73", "#DB8689"]


def fr(value: float, decimals: int = 2) -> str:
    return f"{value:.{decimals}f}".replace(".", ",")


def ns_from_ps(value_ps: float) -> float:
    return value_ps / 1000.0


def axis_formatter(decimals: int = 1) -> FuncFormatter:
    return FuncFormatter(lambda x, pos: f"{x:.{decimals}f}".replace(".", ","))


@dataclass
class ArchitectureCase:
    name: str
    frequency_hz: float
    period_ps: float
    stage_delay_ps: float
    edge_spacing_ps: float
    time_ps: np.ndarray
    waveforms: Dict[str, np.ndarray]
    rising_edges_ps: Dict[str, float]
    rising_order: List[str]


def build_time_axis(period_ps: float, stage_delay_ps: float, periods: int = 3, oversample: int = 240) -> np.ndarray:
    dt_ps = stage_delay_ps / oversample
    start_ps = -0.5 * dt_ps
    stop_ps = periods * period_ps + 0.5 * dt_ps
    count = int(np.ceil((stop_ps - start_ps) / dt_ps)) + 1
    return start_ps + np.arange(count) * dt_ps


def square_wave(time_ps: np.ndarray, period_ps: float, phase_ps: float = 0.0) -> np.ndarray:
    phase = np.mod(time_ps - phase_ps, period_ps)
    return (phase < 0.5 * period_ps).astype(int)


def detect_rising_edges(time_ps: np.ndarray, values: np.ndarray) -> np.ndarray:
    indices = np.where((values[:-1] == 0) & (values[1:] == 1))[0]
    if len(indices) == 0:
        return np.array([], dtype=float)
    return 0.5 * (time_ps[indices] + time_ps[indices + 1])


def first_rising_edge_in_period(time_ps: np.ndarray, values: np.ndarray, period_ps: float) -> float:
    dt_ps = time_ps[1] - time_ps[0]
    edges = detect_rising_edges(time_ps, values)
    mask = (edges >= -dt_ps) & (edges < period_ps - 0.25 * dt_ps)
    candidates = edges[mask]
    if len(candidates) == 0:
        raise RuntimeError("Aucun front montant detecte dans la periode de reference.")
    edge = candidates[0]
    return 0.0 if abs(edge) < dt_ps else float(edge)


def make_single_ended_case(frequency_hz: float, stages: int = 9) -> ArchitectureCase:
    period_ps = 1e12 / frequency_hz
    stage_delay_ps = period_ps / (2.0 * stages)
    edge_spacing_ps = 2.0 * stage_delay_ps
    time_ps = build_time_axis(period_ps, stage_delay_ps)
    waveforms: Dict[str, np.ndarray] = {}

    for idx in range(stages):
        shifted = square_wave(time_ps - idx * stage_delay_ps, period_ps)
        waveforms[f"T{idx}"] = shifted if idx % 2 == 0 else 1 - shifted

    rising_edges_ps = {
        label: first_rising_edge_in_period(time_ps, values, period_ps)
        for label, values in waveforms.items()
    }
    rising_order = sorted(waveforms, key=lambda label: rising_edges_ps[label])

    return ArchitectureCase(
        name="simple",
        frequency_hz=frequency_hz,
        period_ps=period_ps,
        stage_delay_ps=stage_delay_ps,
        edge_spacing_ps=edge_spacing_ps,
        time_ps=time_ps,
        waveforms=waveforms,
        rising_edges_ps=rising_edges_ps,
        rising_order=rising_order,
    )


def make_differential_case(frequency_hz: float, stages: int = 4) -> ArchitectureCase:
    period_ps = 1e12 / frequency_hz
    stage_delay_ps = period_ps / (2.0 * stages)
    edge_spacing_ps = stage_delay_ps
    time_ps = build_time_axis(period_ps, stage_delay_ps)
    waveforms: Dict[str, np.ndarray] = {}

    for idx in range(stages):
        shifted = square_wave(time_ps - idx * stage_delay_ps, period_ps)
        p_wave = shifted if idx % 2 == 0 else 1 - shifted
        n_wave = 1 - p_wave
        waveforms[f"S{idx}P"] = p_wave
        waveforms[f"S{idx}N"] = n_wave

    rising_edges_ps = {
        label: first_rising_edge_in_period(time_ps, values, period_ps)
        for label, values in waveforms.items()
    }
    rising_order = sorted(waveforms, key=lambda label: rising_edges_ps[label])

    return ArchitectureCase(
        name="differentiel",
        frequency_hz=frequency_hz,
        period_ps=period_ps,
        stage_delay_ps=stage_delay_ps,
        edge_spacing_ps=edge_spacing_ps,
        time_ps=time_ps,
        waveforms=waveforms,
        rising_edges_ps=rising_edges_ps,
        rising_order=rising_order,
    )


def stage_color_for_diff(label: str) -> str:
    stage_idx = int(label[1])
    return P_STAGE_COLORS[stage_idx] if label.endswith("P") else N_STAGE_COLORS[stage_idx]


def add_box(ax: plt.Axes, title: str, body: str, title_color: str = TITLE_COLOR) -> None:
    ax.set_axis_off()
    box = FancyBboxPatch(
        (0.01, 0.03),
        0.98,
        0.94,
        boxstyle="round,pad=0.02,rounding_size=0.02",
        linewidth=1.0,
        edgecolor=BOX_EDGE,
        facecolor=BOX_FILL,
        transform=ax.transAxes,
    )
    ax.add_patch(box)
    ax.text(0.04, 0.90, title, fontsize=11, fontweight="bold", color=title_color, transform=ax.transAxes)
    ax.text(
        0.04,
        0.84,
        body,
        fontsize=8.6,
        color="#243341",
        va="top",
        linespacing=1.35,
        transform=ax.transAxes,
    )


def add_page_header(ax: plt.Axes, title: str, subtitle: str, page_tag: str) -> None:
    ax.set_axis_off()
    ax.text(0.00, 0.72, title, fontsize=16.5, fontweight="bold", color=TITLE_COLOR, linespacing=1.05, transform=ax.transAxes)
    ax.text(0.00, 0.18, subtitle, fontsize=9.2, color=SUBTITLE_COLOR, transform=ax.transAxes)
    tag = FancyBboxPatch(
        (0.88, 0.48),
        0.10,
        0.36,
        boxstyle="round,pad=0.02,rounding_size=0.03",
        linewidth=0.0,
        facecolor="#D9E6F2",
        transform=ax.transAxes,
    )
    ax.add_patch(tag)
    ax.text(0.93, 0.66, page_tag, ha="center", va="center", fontsize=10, fontweight="bold", color=TITLE_COLOR, transform=ax.transAxes)


def draw_single_inverter(ax: plt.Axes, center: Tuple[float, float], width: float, height: float, label: str, direction: str) -> Dict[str, Tuple[float, float]]:
    cx, cy = center
    x0 = cx - width / 2.0
    y0 = cy - height / 2.0
    rect = Rectangle((x0, y0), width, height, linewidth=1.2, edgecolor="#40515F", facecolor="white")
    ax.add_patch(rect)
    ax.text(cx, cy, label, ha="center", va="center", fontsize=8.5, color=TITLE_COLOR, fontweight="bold")

    pin_len = 0.035
    bubble_r = 0.010
    if direction == "right":
        input_pt = (x0 - pin_len, cy)
        input_block = (x0, cy)
        bubble_center = (x0 + width + bubble_r, cy)
        output_pt = (bubble_center[0] + bubble_r + pin_len, cy)
        ax.plot([input_pt[0], input_block[0]], [cy, cy], color="#40515F", lw=1.2)
        ax.plot([x0 + width, bubble_center[0] - bubble_r], [cy, cy], color="#40515F", lw=1.2)
        ax.plot([bubble_center[0] + bubble_r, output_pt[0]], [cy, cy], color="#40515F", lw=1.2)
    else:
        input_pt = (x0 + width + pin_len, cy)
        input_block = (x0 + width, cy)
        bubble_center = (x0 - bubble_r, cy)
        output_pt = (bubble_center[0] - bubble_r - pin_len, cy)
        ax.plot([input_pt[0], input_block[0]], [cy, cy], color="#40515F", lw=1.2)
        ax.plot([x0, bubble_center[0] + bubble_r], [cy, cy], color="#40515F", lw=1.2)
        ax.plot([bubble_center[0] - bubble_r, output_pt[0]], [cy, cy], color="#40515F", lw=1.2)

    ax.add_patch(Circle(bubble_center, bubble_r, edgecolor="#40515F", facecolor="white", lw=1.2))
    return {"input": input_pt, "output": output_pt, "bubble": bubble_center}


def draw_single_ended_schematic(ax: plt.Axes) -> None:
    ax.set_axis_off()
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.text(0.02, 0.97, "Schéma de principe — anneau 9 étages", fontsize=11, fontweight="bold", color=TITLE_COLOR, va="top")

    width, height = 0.10, 0.09
    positions = {
        0: (0.12, 0.72, "right"),
        1: (0.29, 0.72, "right"),
        2: (0.46, 0.72, "right"),
        3: (0.63, 0.72, "right"),
        4: (0.80, 0.72, "right"),
        5: (0.80, 0.32, "left"),
        6: (0.63, 0.32, "left"),
        7: (0.46, 0.32, "left"),
        8: (0.29, 0.32, "left"),
    }
    pins: Dict[int, Dict[str, Tuple[float, float]]] = {}
    for idx in range(9):
        cx, cy, direction = positions[idx]
        pins[idx] = draw_single_inverter(ax, (cx, cy), width, height, f"INV{idx}", direction)
        tap_x, tap_y = pins[idx]["output"]
        if cy > 0.5:
            ax.plot([tap_x, tap_x], [tap_y, tap_y + 0.08], color=SINGLE_COLORS[idx], lw=1.5)
            ax.text(tap_x, tap_y + 0.10, f"T{idx}", ha="center", va="bottom", fontsize=8.5, color=SINGLE_COLORS[idx], fontweight="bold")
        else:
            ax.plot([tap_x, tap_x], [tap_y, tap_y - 0.08], color=SINGLE_COLORS[idx], lw=1.5)
            ax.text(tap_x, tap_y - 0.10, f"T{idx}", ha="center", va="top", fontsize=8.5, color=SINGLE_COLORS[idx], fontweight="bold")

    def connect(p0: Tuple[float, float], p1: Tuple[float, float]) -> None:
        arrow = FancyArrowPatch(p0, p1, arrowstyle="-|>", mutation_scale=10, lw=1.2, color="#60717F")
        ax.add_patch(arrow)

    for idx in range(4):
        connect(pins[idx]["output"], pins[idx + 1]["input"])
    connect(pins[4]["output"], (0.91, 0.72))
    connect((0.91, 0.72), (0.91, 0.32))
    connect((0.91, 0.32), pins[5]["input"])
    for idx in range(5, 8):
        connect(pins[idx]["output"], pins[idx + 1]["input"])
    connect(pins[8]["output"], (0.12, 0.32))
    connect((0.12, 0.32), (0.06, 0.32))
    connect((0.06, 0.32), (0.06, 0.72))
    connect((0.06, 0.72), pins[0]["input"])
    ax.text(0.02, 0.05, "Propagation inverseuse séquentielle ; fermeture de boucle explicite.", fontsize=8.5, color=SUBTITLE_COLOR)


def draw_differential_block(ax: plt.Axes, center: Tuple[float, float], width: float, height: float, label: str) -> Dict[str, Tuple[float, float]]:
    cx, cy = center
    x0 = cx - width / 2.0
    y0 = cy - height / 2.0
    rect = Rectangle((x0, y0), width, height, linewidth=1.2, edgecolor="#40515F", facecolor="white")
    ax.add_patch(rect)
    ax.text(cx, cy + 0.02, label, ha="center", va="center", fontsize=8.5, color=TITLE_COLOR, fontweight="bold")
    ax.text(cx, cy - 0.04, "cellule diff.", ha="center", va="center", fontsize=7.2, color=SUBTITLE_COLOR)

    y_p = cy + 0.055
    y_n = cy - 0.055
    x_in = x0 - 0.035
    x_out = x0 + width + 0.035
    ax.plot([x_in, x0], [y_p, y_p], color=P_COLOR, lw=1.4)
    ax.plot([x_in, x0], [y_n, y_n], color=N_COLOR, lw=1.4)
    ax.plot([x0 + width, x_out], [y_p, y_p], color=P_COLOR, lw=1.4)
    ax.plot([x0 + width, x_out], [y_n, y_n], color=N_COLOR, lw=1.4)
    ax.text(x0 + 0.01, y_p + 0.015, "P", fontsize=7.2, color=P_COLOR)
    ax.text(x0 + 0.01, y_n - 0.030, "N", fontsize=7.2, color=N_COLOR)
    return {
        "in_p": (x_in, y_p),
        "in_n": (x_in, y_n),
        "out_p": (x_out, y_p),
        "out_n": (x_out, y_n),
    }


def draw_polyline(ax: plt.Axes, points: Iterable[Tuple[float, float]], color: str, lw: float = 1.6) -> None:
    pts = list(points)
    xs = [pt[0] for pt in pts]
    ys = [pt[1] for pt in pts]
    ax.plot(xs, ys, color=color, lw=lw)


def draw_differential_schematic(ax: plt.Axes) -> None:
    ax.set_axis_off()
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.text(0.02, 0.97, "Schéma de principe — anneau différentiel 4 étages", fontsize=11, fontweight="bold", color=TITLE_COLOR, va="top")

    width, height = 0.14, 0.24
    centers = [(0.15, 0.60), (0.38, 0.60), (0.61, 0.60), (0.84, 0.60)]
    blocks: Dict[int, Dict[str, Tuple[float, float]]] = {}
    for idx, center in enumerate(centers):
        blocks[idx] = draw_differential_block(ax, center, width, height, f"D{idx}")
        ax.text(blocks[idx]["out_p"][0] + 0.01, blocks[idx]["out_p"][1] + 0.02, f"S{idx}P", fontsize=8.1, color=P_COLOR, fontweight="bold")
        ax.text(blocks[idx]["out_n"][0] + 0.01, blocks[idx]["out_n"][1] - 0.04, f"S{idx}N", fontsize=8.1, color=N_COLOR, fontweight="bold")

    for idx in range(3):
        draw_polyline(ax, [blocks[idx]["out_p"], blocks[idx + 1]["in_p"]], P_COLOR)
        draw_polyline(ax, [blocks[idx]["out_n"], blocks[idx + 1]["in_n"]], N_COLOR)

    p3 = blocks[3]["out_p"]
    n3 = blocks[3]["out_n"]
    p0 = blocks[0]["in_p"]
    n0 = blocks[0]["in_n"]
    y_low = 0.20
    draw_polyline(ax, [p3, (0.93, p3[1]), (0.93, y_low), (0.38, y_low), p0], P_COLOR)
    draw_polyline(ax, [n3, (0.90, n3[1]), (0.90, 0.12), (0.32, 0.12), n0], N_COLOR)
    ax.text(0.46, 0.17, "retour croisé P/N", fontsize=8.2, color=SUBTITLE_COLOR, ha="center")
    ax.text(0.02, 0.05, "Hypothèse : 3 liaisons directes + 1 fermeture croisée.", fontsize=8.4, color=SUBTITLE_COLOR)


def plot_chronogram(
    ax: plt.Axes,
    case: ArchitectureCase,
    order: List[str],
    title: str,
    color_map: Dict[str, str],
    extra_note: str | None = None,
    show_edge_markers: bool = False,
    show_xlabel: bool = True,
) -> None:
    mask = (case.time_ps >= 0.0) & (case.time_ps <= 3.0 * case.period_ps + 1e-9)
    time_ns = ns_from_ps(case.time_ps[mask])
    row_pitch = 1.18
    amp = 0.78
    n = len(order)
    y_centers: List[float] = []

    for idx, label in enumerate(order):
        baseline = (n - 1 - idx) * row_pitch
        values = case.waveforms[label][mask]
        ax.step(time_ns, baseline + amp * values, where="post", lw=1.6, color=color_map[label])
        ax.hlines(baseline, time_ns[0], time_ns[-1], color="#C8D0D8", lw=0.6)
        y_centers.append(baseline + 0.38)

    ax.set_yticks(y_centers)
    ax.set_yticklabels(order)
    ax.set_xlim(0.0, ns_from_ps(3.0 * case.period_ps))
    ax.set_ylim(-0.25, (n - 1) * row_pitch + amp + 0.85)
    ax.grid(axis="x", color=GRID_COLOR, lw=0.8, alpha=0.8)
    ax.axvspan(0.0, ns_from_ps(case.period_ps), color="#EEF3F8", alpha=0.50, zorder=0)
    ax.set_xlabel("Temps (ns)" if show_xlabel else "")
    ax.set_title(title, loc="left", fontsize=11.2, fontweight="bold", color=TITLE_COLOR, pad=8)
    ax.text(
        0.00,
        1.02,
        f"T = {fr(ns_from_ps(case.period_ps), 3)} ns ; t_d = {fr(case.stage_delay_ps, 2)} ps ; pas utile = {fr(case.edge_spacing_ps, 2)} ps",
        transform=ax.transAxes,
        fontsize=8.2,
        color=SUBTITLE_COLOR,
    )
    if extra_note:
        ax.text(0.00, 1.085, extra_note, transform=ax.transAxes, fontsize=7.2, color=SUBTITLE_COLOR)

    top_y = (n - 1) * row_pitch + amp + 0.38
    ax.annotate(
        "",
        xy=(ns_from_ps(case.period_ps), top_y),
        xytext=(0.0, top_y),
        arrowprops=dict(arrowstyle="<->", color="#55616C", lw=1.0),
    )
    ax.text(
        ns_from_ps(case.period_ps) / 2.0,
        top_y + 0.10,
        f"1 période = {fr(case.period_ps, 1)} ps",
        ha="center",
        va="bottom",
        fontsize=7.9,
        color="#55616C",
    )

    if show_edge_markers:
        ordered_edges = [case.rising_edges_ps[label] for label in order]
        for edge_ps in ordered_edges:
            ax.axvline(ns_from_ps(edge_ps), color="#9FB0BF", lw=0.9, linestyle=(0, (3, 3)))
        for label, edge_ps in zip(order, ordered_edges):
            ax.plot(ns_from_ps(edge_ps), top_y - 0.10, marker="o", ms=3.0, color=color_map[label], clip_on=False)

    ax.xaxis.set_major_formatter(axis_formatter(1))
    for spine in ["top", "right"]:
        ax.spines[spine].set_visible(False)
    ax.spines["left"].set_color("#AAB5C0")
    ax.spines["bottom"].set_color("#AAB5C0")


def build_single_summary(slow: ArchitectureCase, fast: ArchitectureCase) -> str:
    return (
        "- 9 étages inverseurs simple voie ; 9 taps observables T0 à T8\n"
        "- Fréquence lente cible : 1,00 GHz\n"
        f"- Délai élémentaire lent : t_d = {fr(slow.stage_delay_ps, 2)} ps\n"
        "- Fréquence rapide cible : 1,11 GHz\n"
        f"- Délai élémentaire rapide : t_d = {fr(fast.stage_delay_ps, 2)} ps\n"
        "- Relation de boucle : f = 1 / (2 · N · t_d)\n"
        "- Modèle temporel : V_i(t) = 1 - V_{i-1}(t - t_d),\n"
        "  avec régime établi périodique et fermeture inverseuse."
    )


def build_differential_summary(slow: ArchitectureCase, fast: ArchitectureCase) -> str:
    return (
        "- 4 étages entièrement différentiels ; 8 taps observables\n"
        "- Chaque étage fournit deux sorties : P et N\n"
        "- Sorties locales complémentaires : N_i = 1 - P_i (180° local)\n"
        "- Hypothèse de boucle : fermeture croisée P/N sur D3 -> D0\n"
        "- Fréquence lente cible : 1,00 GHz\n"
        f"- Délai par étage lent : t_d = {fr(slow.stage_delay_ps, 2)} ps\n"
        "- Fréquence rapide cible : 1,11 GHz\n"
        f"- Délai par étage rapide : t_d = {fr(fast.stage_delay_ps, 2)} ps\n"
        "- Modèle : P_i(t) = 1 - P_{i-1}(t - t_d)\n"
        "  et fermeture croisée : P_0(t) = P_3(t - t_d)"
    )


def build_single_interpretation(slow: ArchitectureCase, fast: ArchitectureCase) -> str:
    order = " -> ".join(slow.rising_order)
    return (
        f"- Les 9 taps donnent 9 positions distinctes de front montant sur une période.\n"
        f"- Pas temporel utile : T/9 = {fr(slow.edge_spacing_ps, 2)} ps (lent) et {fr(fast.edge_spacing_ps, 2)} ps (rapide).\n"
        "- Les taps adjacents dans la structure alternent l’inversion ; l’ordre temporel réel\n"
        f"  des fronts montants est : {order}.\n"
        "- La période est ainsi couverte quasi uniformément, ce qui fournit une base multiphase\n"
        "  dense et exploitable pour l’interpolation d’un TDC."
    )


def build_differential_interpretation(slow: ArchitectureCase, fast: ArchitectureCase) -> str:
    order = " -> ".join(slow.rising_order)
    return (
        "- Les 8 sorties observables fournissent 8 positions distinctes de front montant sur la période.\n"
        f"- Pas temporel utile : T/8 = {fr(slow.edge_spacing_ps, 2)} ps (lent) et {fr(fast.edge_spacing_ps, 2)} ps (rapide).\n"
        "- Les paires P/N sont structurellement redondantes en niveau logique, car complémentaires,\n"
        "  mais elles ajoutent des fronts montants intercalés et donc utiles pour une lecture à fronts.\n"
        "- Par rapport au cas 9 simple voie : une phase montante de moins et un pas 12,5 % plus grossier.\n"
        "- Conclusion : la fonctionnalité multiphase est préservée pour un TDC, mais avec une richesse\n"
        f"  temporelle légèrement réduite et plus contrainte par la complémentarité.\n- Ordre lent : {order}."
    )


def format_reordered_note(case: ArchitectureCase, labels: List[str]) -> str:
    chunks = []
    for idx, label in enumerate(labels):
        chunks.append(f"{label} ({fr(case.rising_edges_ps[label], 1)} ps)")
        if idx == 3:
            chunks.append("\n")
    return "Ordre détecté des fronts montants sur 1 période : " + " -> ".join(chunks)


def build_page_one(pdf: PdfPages, slow: ArchitectureCase, fast: ArchitectureCase) -> None:
    fig = plt.figure(figsize=A4_PORTRAIT)
    grid = GridSpec(5, 1, height_ratios=[0.10, 0.26, 0.22, 0.22, 0.20], figure=fig)
    header_ax = fig.add_subplot(grid[0])
    add_page_header(
        header_ax,
        "Oscillateur en anneau actuel — 9 inverseurs simple voie",
        "Comparaison temporelle déterministe des 9 taps pour les cas lent (1,00 GHz) et rapide (1,11 GHz).",
        "Recto",
    )

    top_grid = GridSpecFromSubplotSpec(1, 2, subplot_spec=grid[1], width_ratios=[0.38, 0.62], wspace=0.10)
    summary_ax = fig.add_subplot(top_grid[0])
    add_box(summary_ax, "Résumé technique", build_single_summary(slow, fast))
    schematic_ax = fig.add_subplot(top_grid[1])
    draw_single_ended_schematic(schematic_ax)

    single_color_map = {label: SINGLE_COLORS[idx] for idx, label in enumerate(slow.waveforms)}
    slow_ax = fig.add_subplot(grid[2])
    plot_chronogram(slow_ax, slow, [f"T{i}" for i in range(9)], "Chronogramme — oscillateur lent (1,00 GHz)", single_color_map)
    fast_ax = fig.add_subplot(grid[3])
    plot_chronogram(fast_ax, fast, [f"T{i}" for i in range(9)], "Chronogramme — oscillateur rapide (1,11 GHz)", single_color_map)

    interpretation_ax = fig.add_subplot(grid[4])
    add_box(interpretation_ax, "Interprétation visuelle", build_single_interpretation(slow, fast))

    fig.subplots_adjust(left=0.055, right=0.975, top=0.975, bottom=0.035, hspace=0.34)
    pdf.savefig(fig)
    plt.close(fig)


def build_page_two(pdf: PdfPages, slow: ArchitectureCase, fast: ArchitectureCase) -> None:
    fig = plt.figure(figsize=A4_PORTRAIT)
    grid = GridSpec(6, 1, height_ratios=[0.10, 0.24, 0.16, 0.16, 0.17, 0.17], figure=fig)
    header_ax = fig.add_subplot(grid[0])
    add_page_header(
        header_ax,
        "Alternative — 4 étages différentiels\net 8 taps observables",
        "Sorties P/N complémentaires, boucle croisée et réordonnancement numérique des fronts montants.",
        "Verso",
    )

    top_grid = GridSpecFromSubplotSpec(1, 2, subplot_spec=grid[1], width_ratios=[0.36, 0.64], wspace=0.10)
    summary_ax = fig.add_subplot(top_grid[0])
    add_box(summary_ax, "Résumé technique", build_differential_summary(slow, fast))
    schematic_ax = fig.add_subplot(top_grid[1])
    draw_differential_schematic(schematic_ax)

    raw_order = ["S0P", "S0N", "S1P", "S1N", "S2P", "S2N", "S3P", "S3N"]
    diff_color_map = {label: stage_color_for_diff(label) for label in raw_order}

    slow_ax = fig.add_subplot(grid[2])
    plot_chronogram(
        slow_ax,
        slow,
        raw_order,
        "Chronogramme brut — oscillateur lent",
        diff_color_map,
        show_xlabel=False,
    )
    fast_ax = fig.add_subplot(grid[3])
    plot_chronogram(
        fast_ax,
        fast,
        raw_order,
        "Chronogramme brut — oscillateur rapide",
        diff_color_map,
        show_xlabel=False,
    )

    reordered_ax = fig.add_subplot(grid[4])
    plot_chronogram(
        reordered_ax,
        slow,
        slow.rising_order,
        "Chronogramme réordonné — fronts montants (cas lent)",
        diff_color_map,
        show_edge_markers=True,
    )

    interpretation_ax = fig.add_subplot(grid[5])
    add_box(interpretation_ax, "Évaluation de la richesse multiphase", build_differential_interpretation(slow, fast))

    fig.subplots_adjust(left=0.055, right=0.975, top=0.975, bottom=0.035, hspace=0.34)
    pdf.savefig(fig)
    plt.close(fig)


def generate_pdf(output_path: Path) -> None:
    single_slow = make_single_ended_case(1.00e9)
    single_fast = make_single_ended_case(1.11e9)
    diff_slow = make_differential_case(1.00e9)
    diff_fast = make_differential_case(1.11e9)

    with PdfPages(output_path) as pdf:
        build_page_one(pdf, single_slow, single_fast)
        build_page_two(pdf, diff_slow, diff_fast)


def main() -> None:
    output_path = Path("oscillator_multiphase_comparison_recto_verso.pdf")
    generate_pdf(output_path)
    print(f"PDF généré : {output_path.resolve()}")


if __name__ == "__main__":
    main()
