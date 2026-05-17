#!/usr/bin/env python3
"""Generate publication-style vector figures for the SPADMIC/MPTDC report.

The report keeps the generated PDFs as the LaTeX-facing artifacts.  This script
is the source of truth for the architecture, CDC, FSM, timing and packet-format
figures that need a strict IEEE-like visual style.
"""

from __future__ import annotations

import os
import re
import subprocess
import textwrap
from pathlib import Path

os.environ.setdefault("SOURCE_DATE_EPOCH", "0")

import matplotlib as mpl

mpl.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.lines import Line2D
from matplotlib.patches import Circle, FancyArrowPatch, FancyBboxPatch, Rectangle


OUT_DIR = Path(__file__).resolve().parents[1]
SRC_DIR = OUT_DIR / "src"
STEEL = "#315F8C"
STEEL_LIGHT = "#E8F0F8"
GRAY_0 = "#111111"
GRAY_1 = "#3F454A"
GRAY_2 = "#7D858C"
GRAY_3 = "#D9DEE2"
GRAY_4 = "#F4F6F7"
ASYNC = "#8A4B08"


mpl.rcParams.update(
    {
        "pdf.fonttype": 42,
        "ps.fonttype": 42,
        "font.family": "DejaVu Sans",
        "font.size": 9.5,
        "axes.titlesize": 13,
        "axes.titleweight": "bold",
        "figure.facecolor": "white",
        "savefig.facecolor": "white",
    }
)


def save(fig: plt.Figure, name: str) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    fig.savefig(OUT_DIR / name, format="pdf", bbox_inches="tight")
    plt.close(fig)


def compile_tikz_source(source_name: str, jobname: str) -> None:
    subprocess.run(
        [
            "pdflatex",
            "-interaction=nonstopmode",
            "-halt-on-error",
            f"-jobname={jobname}",
            f"-output-directory={OUT_DIR}",
            source_name,
        ],
        cwd=SRC_DIR,
        check=True,
    )
    for suffix in (".aux", ".log"):
        aux = OUT_DIR / f"{jobname}{suffix}"
        if aux.exists():
            aux.unlink()


def run_python_source(source_name: str) -> None:
    subprocess.run(["python", source_name], cwd=SRC_DIR, check=True)


def render_wavedrom_source(source_name: str, stem: str) -> None:
    source = SRC_DIR / source_name
    subprocess.run(
        ["npx", "--yes", "wavedrom-cli", "-i", str(source), "-s", str(OUT_DIR / f"{stem}.svg")],
        cwd=SRC_DIR,
        check=True,
    )
    subprocess.run(
        ["npx", "--yes", "wavedrom-cli", "-i", str(source), "-p", str(OUT_DIR / f"{stem}.png")],
        cwd=SRC_DIR,
        check=True,
    )
    if stem == "vernier_principle_detailed":
        postprocess_vernier_principle_wavedrom(stem)


def postprocess_vernier_principle_wavedrom(stem: str) -> None:
    svg_path = OUT_DIR / f"{stem}.svg"
    png_path = OUT_DIR / f"{stem}.png"
    if not svg_path.exists():
        return

    text = svg_path.read_text(encoding="utf-8")
    text = re.sub(r'width="(\d+)"', lambda m: f'width="{int(m.group(1)) + 120}"', text, count=1)
    text = re.sub(
        r'viewBox="0 0 (\d+) (\d+)"',
        lambda m: f'viewBox="-120 0 {int(m.group(1)) + 120} {m.group(2)}"',
        text,
        count=1,
    )
    marker_match = re.search(r"(<marker id=\"arrowhead\".*?</marker>)", text, re.DOTALL)
    if marker_match and "arrowhead_red" not in text:
        red_marker = marker_match.group(1).replace('id="arrowhead"', 'id="arrowhead_red"').replace("#0041c4", "#b32020")
        text = text[: marker_match.end()] + red_marker + text[marker_match.end() :]

    text = re.sub(
        r'(<path id="gmark_A_B"[^>]*marker-end:url\(#)arrowhead(\)[^>]*stroke:)[^;"]+(;stroke-width:)[^;"]+',
        r"\1arrowhead_red\2#b32020\g<3>1.4",
        text,
        count=1,
    )
    text = text.replace(
        '<text text-anchor="middle" y="3" style="font-size:11px;"><tspan>T_{hit}</tspan></text>',
        '<text text-anchor="middle" y="3" style="font-size:11px;fill:#b32020;font-weight:bold;"><tspan>T_{hit}</tspan></text>',
    )
    svg_path.write_text(text, encoding="utf-8")

    try:
        import cairosvg

        cairosvg.svg2png(bytestring=text.encode("utf-8"), write_to=str(png_path))
    except Exception:
        pass


def canvas(name: str, width: float = 14.0, height: float = 7.5) -> tuple[plt.Figure, plt.Axes]:
    fig, ax = plt.subplots(figsize=(width, height))
    ax.set_xlim(0, width)
    ax.set_ylim(0, height)
    ax.set_axis_off()
    ax.text(width / 2, height - 0.28, name, ha="center", va="top", fontsize=13, fontweight="bold")
    return fig, ax


def wrap(text: str, width: int = 22) -> str:
    return "\n".join(textwrap.wrap(text, width=width, break_long_words=False))


def domain(ax: plt.Axes, x: float, y: float, w: float, h: float, title: str) -> None:
    ax.add_patch(
        Rectangle(
            (x, y),
            w,
            h,
            facecolor="none",
            edgecolor=GRAY_2,
            linewidth=1.1,
            linestyle=(0, (4, 3)),
        )
    )
    ax.text(x + 0.18, y + h - 0.18, title, ha="left", va="top", fontsize=9.5, fontweight="bold")


def block(
    ax: plt.Axes,
    x: float,
    y: float,
    w: float,
    h: float,
    title: str,
    signals: str = "",
    *,
    accent: bool = False,
    dashed: bool = False,
    fontsize: float = 9.5,
) -> None:
    ax.add_patch(
        FancyBboxPatch(
            (x, y),
            w,
            h,
            boxstyle="round,pad=0.018,rounding_size=0.055",
            facecolor=STEEL_LIGHT if accent else "white",
            edgecolor=STEEL if accent else GRAY_0,
            linewidth=1.35,
            linestyle="--" if dashed else "-",
        )
    )
    if signals:
        ax.text(x + w / 2, y + h * 0.62, wrap(title, 18), ha="center", va="center", fontsize=fontsize, fontweight="bold")
        ax.text(x + w / 2, y + h * 0.28, wrap(signals, 20), ha="center", va="center", fontsize=fontsize - 1.3, family="monospace")
    else:
        ax.text(x + w / 2, y + h / 2, wrap(title, 20), ha="center", va="center", fontsize=fontsize, fontweight="bold")


def state(ax: plt.Axes, x: float, y: float, name: str, action: str = "", *, r: float = 0.52, accent: bool = False) -> None:
    ax.add_patch(Circle((x, y), r, facecolor=STEEL_LIGHT if accent else "white", edgecolor=GRAY_0, linewidth=1.5))
    ax.text(x, y + (0.11 if action else 0), name, ha="center", va="center", fontsize=9.5, fontweight="bold")
    if action:
        ax.text(x, y - 0.22, wrap(action, 14), ha="center", va="center", fontsize=7.3, family="monospace")


def orth_arrow(
    ax: plt.Axes,
    start: tuple[float, float],
    end: tuple[float, float],
    label: str = "",
    *,
    kind: str = "control",
    via: tuple[float, float] | None = None,
    above: bool = True,
    label_offset: float = 0.12,
) -> None:
    color = STEEL if kind == "data" else ASYNC if kind == "async" else GRAY_1
    lw = 2.0 if kind == "data" else 1.0
    ls = (0, (3, 3)) if kind == "async" else "-"
    if via is None and start[0] != end[0] and start[1] != end[1]:
        via = ((start[0] + end[0]) / 2, start[1])
        points = [start, via, (via[0], end[1]), end]
    elif via is None:
        points = [start, end]
    else:
        points = [start, via, end] if (via[0] == start[0] or via[1] == start[1]) else [start, (via[0], start[1]), via, (via[0], end[1]), end]

    for p0, p1 in zip(points[:-2], points[1:-1]):
        ax.add_line(Line2D([p0[0], p1[0]], [p0[1], p1[1]], color=color, linewidth=lw, linestyle=ls))
    p0, p1 = points[-2], points[-1]
    ax.add_patch(
        FancyArrowPatch(
            p0,
            p1,
            arrowstyle="-|>",
            mutation_scale=10,
            linewidth=lw,
            color=color,
            linestyle=ls,
            shrinkA=2,
            shrinkB=3,
        )
    )
    if label:
        mx = (start[0] + end[0]) / 2
        my = (start[1] + end[1]) / 2 + (label_offset if above else -label_offset)
        ax.text(mx, my, wrap(label, 24), ha="center", va="center", fontsize=7.5, family="monospace", color=color, bbox=dict(fc="white", ec="none", pad=1.2))


def reset_dot(ax: plt.Axes, x: float, y: float, to: tuple[float, float]) -> None:
    ax.add_patch(Circle((x, y), 0.075, facecolor=GRAY_0, edgecolor=GRAY_0))
    orth_arrow(ax, (x + 0.08, y), to, "", kind="control")


def bit_word(ax: plt.Axes, y: float, title: str, fields: list[tuple[int, str, str]]) -> None:
    x0, scale, h = 0.7, 0.54, 0.46
    ax.text(x0, y + 0.58, title, ha="left", va="center", fontsize=9.5, fontweight="bold")
    x = x0
    bit_hi = 15
    for width, label, category in fields:
        color = {"hdr": GRAY_3, "payload": STEEL_LIGHT, "eoc": "#EFEFEF", "rsvd": GRAY_4}[category]
        ax.add_patch(Rectangle((x, y), width * scale, h, facecolor=color, edgecolor=GRAY_0, linewidth=0.9, hatch="//" if category == "hdr" else "\\\\" if category == "eoc" else None))
        bit_lo = bit_hi - width + 1
        ax.text(x + width * scale / 2, y + h * 0.58, label, ha="center", va="center", fontsize=7.1, family="monospace")
        ax.text(x + width * scale / 2, y - 0.06, f"{bit_hi}" if width == 1 else f"{bit_hi}:{bit_lo}", ha="center", va="top", fontsize=6.5, color=GRAY_1, family="monospace")
        x += width * scale
        bit_hi = bit_lo - 1


def waveform(ax: plt.Axes, y: float, vals: list[int], label: str, data: list[str] | None = None) -> None:
    ax.text(0.45, y + 0.12, label, ha="right", va="center", fontsize=8.4, family="monospace")
    xs, ys = [], []
    for i, val in enumerate(vals):
        hi = y + 0.22 if val else y - 0.22
        xs += [i, i + 1]
        ys += [hi, hi]
        if i < len(vals) - 1 and vals[i + 1] != val:
            xs += [i + 1, i + 1]
            ys += [hi, y + (0.22 if vals[i + 1] else -0.22)]
    ax.plot(np.array(xs) + 0.8, ys, color=GRAY_0, linewidth=1.25)
    if data:
        for i, d in enumerate(data):
            if d:
                ax.text(i + 1.3, y, d, ha="center", va="center", fontsize=7.6, family="monospace", bbox=dict(fc="white", ec=GRAY_3, pad=1.0))


def timing_canvas(title: str, n: int = 9, height: float = 4.9) -> tuple[plt.Figure, plt.Axes]:
    fig, ax = plt.subplots(figsize=(12.0, height))
    ax.set_xlim(0, n + 1.2)
    ax.set_ylim(0, height)
    ax.set_axis_off()
    ax.text((n + 1.2) / 2, height - 0.15, title, ha="center", va="top", fontsize=12.5, fontweight="bold")
    for i in range(n + 1):
        ax.axvline(i + 0.8, ymin=0.11, ymax=0.86, color=GRAY_3, linewidth=0.55, linestyle=":")
    return fig, ax


def generate_tdc_measurement_chain() -> None:
    compile_tikz_source("tdc_measurement_chain.tex", "tdc_measurement_chain")


def generate_vernier_principle_detailed() -> None:
    render_wavedrom_source("vernier_principle_detailed.wavedrom.json", "vernier_principle_detailed")


def generate_vernier_reference_architecture() -> None:
    compile_tikz_source("vernier_reference_architecture.tex", "vernier_reference_architecture")


def generate_pd_matrix_heatmap() -> None:
    run_python_source("pd_matrix_heatmap.py")


def generate_fine_grid_coverage() -> None:
    values = sorted({11 * ns - 10 * nf for ns in range(8) for nf in range(8)})
    full = np.arange(min(values), max(values) + 1)
    missing = [v for v in full if v not in values]
    gaps = np.diff(values)
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10.8, 4.9), gridspec_kw={"height_ratios": [1.2, 1.0]}, constrained_layout=True)
    fig.suptitle("Structural fine-grid coverage of the 8 x 8 Vernier matrix", fontsize=12.5, fontweight="bold")
    ax1.hlines(0, full.min(), full.max(), color=GRAY_2, linewidth=0.8)
    ax1.vlines(missing, -0.25, 0.25, color=GRAY_3, linewidth=0.55, label="missing")
    ax1.vlines(values, -0.45, 0.45, color=STEEL, linewidth=1.0, label="reachable")
    ax1.set_yticks([])
    ax1.set_xlabel("fine coefficient")
    ax1.set_xlim(full.min() - 2, full.max() + 2)
    ax1.legend(frameon=False, ncol=2, loc="upper right")
    ax1.text(0.01, 0.88, "64 reachable / 148 integer positions = 43.2% coverage", transform=ax1.transAxes, fontsize=8.8)
    ax2.bar(np.arange(len(gaps)), gaps * 10, color=STEEL, width=0.82)
    ax2.set_xlabel("sorted reachable-code interval")
    ax2.set_ylabel("gap (ps)")
    ax2.axhline(10, color=GRAY_1, linewidth=0.8, linestyle="--")
    save(fig, "fine_grid_coverage.pdf")


def generate_context_pipeline() -> None:
    compile_tikz_source("context_pipeline.tex", "context_pipeline")


def generate_mptdc_overview() -> None:
    compile_tikz_source("spadmic_architecture_lecture.tex", "mptdc_overview")


def generate_vernier_transition_map() -> None:
    compile_tikz_source("vernier_transition_map.tex", "vernier_transition_map")


def generate_clock_domain_diagram() -> None:
    compile_tikz_source("clock_domain_diagram.tex", "clock_domain_diagram")


def generate_mptdc_block_diagram() -> None:
    fig, ax = canvas("mptdc_top_asic / mptdc_core hierarchy", 15.0, 7.2)
    domain(ax, 0.55, 1.0, 3.6, 5.5, "pad / async inputs")
    domain(ax, 4.55, 1.0, 5.3, 5.5, "fast measurement core")
    domain(ax, 10.25, 1.0, 4.2, 5.5, "clk_sys readout")
    block(ax, 0.95, 5.05, 2.7, 0.65, "input mux", "SPAD or CAL")
    block(ax, 0.95, 3.65, 2.7, 0.75, "async_frontend_v2", "start_latched\nstop_latched")
    block(ax, 4.95, 5.25, 1.9, 0.65, "slow ring", "8 taps")
    block(ax, 4.95, 4.0, 1.9, 0.65, "fast ring", "8 taps")
    block(ax, 4.95, 2.55, 1.9, 0.65, "Gray counters", "Nslow,Nfast")
    block(ax, 7.25, 3.8, 2.1, 1.0, "8 x 8 PD matrix", "PD_N=64", accent=True)
    block(ax, 7.25, 2.3, 2.1, 0.8, "meas_ctrl", "SNAPSHOT")
    block(ax, 10.65, 4.6, 3.25, 0.8, "context_bank", "2 frozen images")
    block(ax, 10.65, 3.25, 3.25, 0.8, "drain_ctrl", "META/SCAN/EOC")
    block(ax, 10.65, 1.9, 3.25, 0.8, "sync FIFO + narrow16", "ready/valid")
    orth_arrow(ax, (3.65, 4.0), (4.95, 5.57), "START", kind="async")
    orth_arrow(ax, (3.65, 4.0), (4.95, 4.32), "STOP", kind="async")
    orth_arrow(ax, (6.85, 5.57), (7.25, 4.45), "slow phases", kind="data")
    orth_arrow(ax, (6.85, 4.32), (7.25, 4.1), "fast phases", kind="data")
    orth_arrow(ax, (6.85, 2.88), (7.25, 3.85), "counts", kind="data")
    orth_arrow(ax, (8.3, 3.8), (8.3, 3.1), "any_hit", kind="control")
    orth_arrow(ax, (9.35, 4.3), (10.65, 5.0), "wide snapshot", kind="data")
    orth_arrow(ax, (13.9, 4.95), (13.9, 4.05), "scan", kind="control")
    orth_arrow(ax, (12.25, 3.25), (12.25, 2.7), "records", kind="data")
    save(fig, "mptdc_block_diagram.pdf")


def generate_async_frontend_fsm() -> None:
    fig, ax = canvas("Asynchronous front-end latch flow", 11.6, 5.5)
    reset_dot(ax, 0.7, 2.8, (1.35, 2.8))
    state(ax, 1.9, 2.8, "ARMED", "wait START")
    state(ax, 4.3, 3.7, "START_L", "slow_en=1", accent=True)
    state(ax, 6.85, 3.7, "STOP_L", "fast_en=1", accent=True)
    state(ax, 9.15, 2.8, "CLEAR", "latches reset")
    state(ax, 4.3, 1.45, "REJECT", "start_rejected")
    orth_arrow(ax, (2.38, 3.02), (3.8, 3.48), "start & ctx_free & conv_arm")
    orth_arrow(ax, (4.82, 3.7), (6.33, 3.7), "stop | slow_wdt", kind="async")
    orth_arrow(ax, (7.37, 3.48), (8.67, 3.02), "fe_clear")
    orth_arrow(ax, (8.63, 2.58), (2.42, 2.58), "done", via=(8.63, 2.05))
    orth_arrow(ax, (2.38, 2.58), (3.85, 1.65), "!ctx_free | !conv_arm", kind="control")
    orth_arrow(ax, (4.8, 1.45), (1.9, 2.28), "next clear", via=(4.8, 0.95))
    save(fig, "async_frontend_fsm.pdf")


def generate_boundary_disambiguation() -> None:
    fig, ax = timing_canvas("STOP-side boundary disambiguation", 9, 4.9)
    ax.axvspan(3.8, 4.8, color=GRAY_4, zorder=0)
    waveform(ax, 3.45, [0, 1, 1, 0, 0, 1, 1, 0, 0], "slow_phase[0]")
    waveform(ax, 2.65, [0, 0, 0, 0, 1, 0, 0, 0, 0], "STOP")
    waveform(ax, 1.85, [0, 0, 0, 0, 1, 1, 1, 1, 1], "phase0_snap")
    waveform(ax, 1.05, [0, 0, 0, 0, 1, 1, 1, 1, 1], "slow_boundary_inc")
    ax.annotate("STOP cuts a slow boundary", xy=(4.8, 2.9), xytext=(5.45, 4.1), arrowprops=dict(arrowstyle="->", lw=0.9, connectionstyle="arc3,rad=-0.2"), fontsize=8.2)
    ax.text(4.3, 0.45, "critical cycle", ha="center", fontsize=8, family="monospace")
    save(fig, "boundary_disambiguation.pdf")


def generate_meas_ctrl_fsm() -> None:
    fig, ax = canvas("mptdc_meas_ctrl FSM", 13.0, 6.3)
    reset_dot(ax, 0.75, 3.2, (1.45, 3.2))
    coords = {"IDLE": (2.0, 3.2), "MEASURE": (4.3, 4.55), "SNAPSHOT": (6.9, 4.55), "CAPTURE": (9.5, 4.55), "STOP_OSC": (11.0, 3.2), "CLEAR": (6.9, 1.75)}
    actions = {"IDLE": "pd_gate=0", "MEASURE": "pd_gate=1", "SNAPSHOT": "snapshot_en", "CAPTURE": "capture_en", "STOP_OSC": "fe_clear", "CLEAR": "pd_clear"}
    for name, xy in coords.items():
        state(ax, *xy, name, actions[name], accent=(name in {"SNAPSHOT", "CAPTURE"}))
    orth_arrow(ax, (2.48, 3.48), (3.82, 4.27), "meas_active")
    orth_arrow(ax, (4.82, 4.55), (6.38, 4.55), "close_any")
    orth_arrow(ax, (7.42, 4.55), (8.98, 4.55), "next clk_fast")
    orth_arrow(ax, (9.98, 4.27), (10.55, 3.48), "context written")
    orth_arrow(ax, (10.48, 2.95), (7.42, 1.98), "osc stopped", via=(10.48, 1.98))
    orth_arrow(ax, (6.38, 1.98), (2.48, 2.95), "clear done", via=(3.1, 1.1))
    save(fig, "meas_ctrl_fsm.pdf")


def generate_timing_diagram_conversion() -> None:
    fig, ax = timing_canvas("Conversion timing around close / snapshot / capture", 10, 5.2)
    ax.axvspan(5.8, 6.8, color=GRAY_4, zorder=0)
    waveform(ax, 4.0, [0, 1, 1, 1, 1, 1, 1, 0, 0, 0], "pd_gate")
    waveform(ax, 3.25, [0, 0, 0, 0, 1, 1, 1, 0, 0, 0], "hit_level")
    waveform(ax, 2.5, [0, 0, 0, 0, 0, 1, 0, 0, 0, 0], "close_any")
    waveform(ax, 1.75, [0, 0, 0, 0, 0, 0, 1, 0, 0, 0], "snapshot_en")
    waveform(ax, 1.0, [0, 0, 0, 0, 0, 0, 0, 1, 0, 0], "capture_en")
    ax.annotate("one fast cycle settle", xy=(6.3, 1.95), xytext=(6.9, 4.45), arrowprops=dict(arrowstyle="->", lw=0.9, connectionstyle="arc3,rad=-0.18"), fontsize=8.2)
    save(fig, "timing_diagram_conversion.pdf")


def generate_drain_ctrl_fsm() -> None:
    fig, ax = canvas("mptdc_drain_ctrl FSM", 10.8, 5.8)
    reset_dot(ax, 0.7, 2.85, (1.45, 2.85))
    state(ax, 2.0, 2.85, "IDLE", "wait ctx")
    state(ax, 4.6, 4.15, "META", "push META", accent=True)
    state(ax, 7.55, 2.85, "SCAN", "emit HIT")
    state(ax, 4.6, 1.55, "EOC", "release")
    orth_arrow(ax, (2.5, 3.08), (4.1, 3.92), "any_selectable")
    orth_arrow(ax, (5.1, 4.0), (7.05, 3.08), "!fifo_full")
    orth_arrow(ax, (7.05, 2.62), (5.1, 1.75), "scan_done | all_hits_found")
    orth_arrow(ax, (4.1, 1.75), (2.5, 2.62), "ctx_release")
    orth_arrow(ax, (7.55, 2.33), (7.55, 3.37), "skip/emit/stall", via=(8.85, 2.33))
    save(fig, "drain_ctrl_fsm.pdf")


def generate_narrow16_tx_fsm() -> None:
    fig, ax = canvas("mptdc_narrow16_tx_v2 serializer FSM", 13.0, 6.2)
    reset_dot(ax, 0.65, 3.1, (1.25, 3.1))
    nodes = {
        "S_IDLE": (1.75, 3.1, "wait META"),
        "S_HEADER": (3.85, 4.25, "emit header"),
        "S_HIT_FETCH": (6.15, 4.25, "read HIT"),
        "S_HIT_CALC": (8.45, 4.25, "t_raw_ps"),
        "S_HIT_W0": (10.75, 4.25, "emit W0"),
        "S_HIT_W1": (10.75, 2.15, "emit W1"),
        "S_HIT_W2": (8.45, 2.15, "FULL only"),
        "S_EOC": (4.15, 2.15, "emit EOC"),
    }
    for name, (x, y, act) in nodes.items():
        state(ax, x, y, name, act, r=0.47, accent=(name in {"S_HEADER", "S_EOC"}))
    orth_arrow(ax, (2.15, 3.35), (3.45, 4.0), "META valid")
    orth_arrow(ax, (4.32, 4.25), (5.68, 4.25), "hit_count>0")
    orth_arrow(ax, (6.62, 4.25), (7.98, 4.25), "HIT valid")
    orth_arrow(ax, (8.92, 4.25), (10.28, 4.25), "calc done")
    orth_arrow(ax, (10.75, 3.78), (10.75, 2.62), "accepted")
    orth_arrow(ax, (10.28, 2.15), (8.92, 2.15), "FULL")
    orth_arrow(ax, (7.98, 2.15), (4.62, 2.15), "last hit")
    orth_arrow(ax, (3.72, 2.15), (2.15, 2.85), "accepted")
    orth_arrow(ax, (10.75, 1.68), (6.15, 3.78), "more hits", via=(11.8, 1.68))
    orth_arrow(ax, (3.85, 3.78), (4.15, 2.62), "hit_count==0")
    save(fig, "narrow16_tx_fsm.pdf")


def generate_packet_format() -> None:
    fig, ax = canvas("Active 16-bit narrow packet format", 11.0, 6.0)
    ax.text(5.05, 5.15, "bit rule", ha="center", fontsize=8.2, family="monospace")
    for i in range(16):
        ax.text(0.7 + (i + 0.5) * 0.54, 4.92, f"{15-i}", ha="center", va="center", fontsize=6.4, family="monospace", color=GRAY_1)
    bit_word(ax, 4.25, "Header", [(2, "10", "hdr"), (2, "ctx", "hdr"), (1, "phase0", "hdr"), (4, "hit_count", "hdr"), (4, "flags", "hdr"), (2, "mode", "hdr"), (1, "boundary", "hdr")])
    bit_word(ax, 3.25, "Hit W0", [(1, "0", "rsvd"), (7, "nslow", "payload"), (7, "nfast_hit", "payload"), (1, "0", "rsvd")])
    bit_word(ax, 2.25, "Hit W1 RAW_FEATURES", [(1, "0", "rsvd"), (4, "ns", "payload"), (4, "nf", "payload"), (7, "reserved", "rsvd")])
    bit_word(ax, 1.25, "Hit W1 RAW_TIMESTAMP", [(16, "t_raw_ps[15:0]", "payload")])
    bit_word(ax, 0.25, "EOC", [(2, "11", "eoc"), (14, "conv_id[13:0]", "eoc")])
    ax.text(9.55, 2.55, "FULL mode adds\none extra W2:\nt_raw_ps[15:0]", ha="left", va="center", fontsize=8.2, family="monospace", bbox=dict(fc="white", ec=GRAY_2, pad=3))
    save(fig, "packet_format_v23.pdf")


def generate_calibration_flow() -> None:
    fig, ax = canvas("External characterization and calibration flow", 13.2, 4.9)
    steps = [
        (0.7, "Campaign CSV", "code_density\nboundary\nstress"),
        (3.05, "Feature table", "ns,nf,nslow\nnfast_hit"),
        (5.4, "Train split", "120 files"),
        (7.75, "6D LUT", "mean residual"),
        (10.1, "Held-out validation", "30 files"),
    ]
    for x, title, sig in steps:
        block(ax, x, 2.6, 1.75, 0.9, title, sig, accent=(title == "6D LUT"))
    for (x0, _, _), (x1, _, _) in zip(steps[:-1], steps[1:]):
        orth_arrow(ax, (x0 + 1.75, 3.05), (x1, 3.05), "stream", kind="data")
    block(ax, 5.15, 0.95, 3.05, 0.75, "Report metrics", "RMS / p95 / DNL / INL")
    orth_arrow(ax, (10.98, 2.6), (8.2, 1.32), "residuals", kind="data", via=(11.55, 1.32))
    save(fig, "calibration_flow.pdf")


def main() -> None:
    generate_tdc_measurement_chain()
    generate_vernier_principle_detailed()
    generate_vernier_reference_architecture()
    generate_pd_matrix_heatmap()
    generate_fine_grid_coverage()
    generate_context_pipeline()
    generate_mptdc_overview()
    generate_vernier_transition_map()
    generate_clock_domain_diagram()
    generate_mptdc_block_diagram()
    generate_async_frontend_fsm()
    generate_boundary_disambiguation()
    generate_meas_ctrl_fsm()
    generate_timing_diagram_conversion()
    generate_drain_ctrl_fsm()
    generate_narrow16_tx_fsm()
    generate_packet_format()
    generate_calibration_flow()


if __name__ == "__main__":
    main()
