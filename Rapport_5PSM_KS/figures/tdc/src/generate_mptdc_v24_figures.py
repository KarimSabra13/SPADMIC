#!/usr/bin/env python3
"""Generate active MPTDC v2.4 schematics for the PFE report.

The PDFs are vector Matplotlib outputs.  They deliberately keep the figure
filenames already used by the LaTeX chapters.
"""

from __future__ import annotations

import math
import os
import textwrap
from pathlib import Path

os.environ.setdefault("SOURCE_DATE_EPOCH", "0")

import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import Circle, FancyArrowPatch, FancyBboxPatch, Rectangle


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT

NE = 8
PD_N = NE * NE

COLORS = {
    "blue": "#2F6DB3",
    "blue2": "#DCEBFA",
    "green": "#2F8F5B",
    "green2": "#DCF2E6",
    "orange": "#D9822B",
    "orange2": "#FCE8D6",
    "purple": "#6F4FB5",
    "purple2": "#E7DFF7",
    "red": "#BA3A3A",
    "red2": "#F7DDDD",
    "gray": "#4A5568",
    "gray2": "#EDF2F7",
    "dark": "#1A202C",
    "line": "#2D3748",
}


mpl.rcParams.update(
    {
        "pdf.fonttype": 42,
        "ps.fonttype": 42,
        "font.family": "DejaVu Sans",
        "font.size": 10,
        "axes.titlesize": 15,
        "axes.labelsize": 11,
    }
)


def save(fig: plt.Figure, name: str) -> None:
    path = OUT_DIR / name
    fig.savefig(
        path,
        format="pdf",
        bbox_inches="tight",
        metadata={"Title": name, "Creator": "generate_mptdc_v24_figures.py"},
    )
    plt.close(fig)


def wrap(label: str, width: int = 24) -> str:
    parts = []
    for line in label.split("\n"):
        parts.extend(textwrap.wrap(line, width=width) or [""])
    return "\n".join(parts)


def rounded_box(
    ax: plt.Axes,
    x: float,
    y: float,
    w: float,
    h: float,
    label: str,
    fc: str,
    ec: str | None = None,
    fontsize: int = 10,
    lw: float = 1.4,
    zorder: int = 2,
) -> FancyBboxPatch:
    patch = FancyBboxPatch(
        (x, y),
        w,
        h,
        boxstyle="round,pad=0.02,rounding_size=0.08",
        facecolor=fc,
        edgecolor=ec or COLORS["line"],
        linewidth=lw,
        zorder=zorder,
    )
    ax.add_patch(patch)
    ax.text(
        x + w / 2,
        y + h / 2,
        wrap(label),
        ha="center",
        va="center",
        fontsize=fontsize,
        color=COLORS["dark"],
        zorder=zorder + 1,
    )
    return patch


def arrow(
    ax: plt.Axes,
    start: tuple[float, float],
    end: tuple[float, float],
    label: str | None = None,
    color: str | None = None,
    rad: float = 0.0,
    lw: float = 1.5,
    ms: float = 11.0,
    fontsize: int = 8,
    dashed: bool = False,
) -> None:
    patch = FancyArrowPatch(
        start,
        end,
        arrowstyle="-|>",
        mutation_scale=ms,
        linewidth=lw,
        color=color or COLORS["line"],
        connectionstyle=f"arc3,rad={rad}",
        linestyle="--" if dashed else "-",
        shrinkA=3,
        shrinkB=3,
        zorder=4,
    )
    ax.add_patch(patch)
    if label:
        mx = (start[0] + end[0]) / 2
        my = (start[1] + end[1]) / 2
        ax.text(
            mx,
            my + 0.12,
            wrap(label, 18),
            ha="center",
            va="bottom",
            fontsize=fontsize,
            color=color or COLORS["dark"],
            bbox=dict(boxstyle="round,pad=0.16", fc="white", ec="none", alpha=0.9),
            zorder=6,
        )


def setup_canvas(
    figsize: tuple[float, float], title: str
) -> tuple[plt.Figure, plt.Axes]:
    fig, ax = plt.subplots(figsize=figsize)
    ax.set_axis_off()
    ax.set_xlim(0, 16)
    ax.set_ylim(0, 9)
    ax.text(8, 8.75, title, ha="center", va="center", fontsize=16, weight="bold")
    return fig, ax


def generate_pd_matrix_heatmap() -> None:
    ns = np.arange(NE)[:, None]
    nf = np.arange(NE)[None, :]
    coef = 11 * ns - 10 * nf

    fig, ax = plt.subplots(figsize=(9.2, 7.2))
    im = ax.imshow(coef, cmap="coolwarm", origin="lower")
    ax.set_title("MPTDC v2.4 PD matrix: NE=8, PD_N=64")
    ax.set_xlabel("fast phase index nf")
    ax.set_ylabel("slow phase index ns")
    ax.set_xticks(range(NE))
    ax.set_yticks(range(NE))
    ax.set_xticklabels(range(NE))
    ax.set_yticklabels(range(NE))
    ax.set_xticks(np.arange(-0.5, NE, 1), minor=True)
    ax.set_yticks(np.arange(-0.5, NE, 1), minor=True)
    ax.grid(which="minor", color="white", linestyle="-", linewidth=1.6)
    ax.tick_params(which="minor", bottom=False, left=False)

    for r in range(NE):
        for c in range(NE):
            v = int(coef[r, c])
            text_color = "white" if abs(v) > 38 else COLORS["dark"]
            ax.text(
                c,
                r,
                f"{r},{c}\n{v}",
                ha="center",
                va="center",
                fontsize=8,
                color=text_color,
            )

    cbar = fig.colorbar(im, ax=ax, fraction=0.046, pad=0.04)
    cbar.set_label("nominal fine coefficient: 11*ns - 10*nf")
    ax.text(
        0.5,
        -0.14,
        "Each cell is one slow/fast tap pair.  Matrix scan index = 8*ns + nf.",
        transform=ax.transAxes,
        ha="center",
        va="center",
        fontsize=10,
    )
    save(fig, "pd_matrix_heatmap.pdf")


def generate_fine_grid_coverage() -> None:
    values = sorted({11 * ns - 10 * nf for ns in range(NE) for nf in range(NE)})
    full = list(range(min(values), max(values) + 1))
    missing = [v for v in full if v not in values]
    gaps = np.diff(values)
    coverage = len(values) / len(full)

    fig = plt.figure(figsize=(13, 6.8))
    gs = fig.add_gridspec(3, 1, height_ratios=[0.55, 1.35, 1.0], hspace=0.34)
    ax0 = fig.add_subplot(gs[0])
    ax1 = fig.add_subplot(gs[1])
    ax2 = fig.add_subplot(gs[2])

    fig.suptitle("MPTDC v2.4 fine-grid coverage from the 8x8 PD matrix", fontsize=16, weight="bold")

    ax0.axis("off")
    ax0.text(
        0.5,
        0.55,
        f"Reachable codes: {len(values)} over {len(full)} integer positions "
        f"({coverage:.1%}).  Missing positions are structural and handled by calibration.",
        ha="center",
        va="center",
        fontsize=12,
        bbox=dict(boxstyle="round,pad=0.35", fc=COLORS["blue2"], ec=COLORS["blue"]),
    )

    ax1.set_title("Reachable fine coefficients")
    ax1.set_xlim(min(full) - 2, max(full) + 2)
    ax1.set_ylim(-0.2, 1.2)
    ax1.set_yticks([])
    ax1.set_xlabel("fine coefficient")
    ax1.hlines(0.5, min(full), max(full), colors=COLORS["gray"], linewidth=1)
    ax1.vlines(missing, 0.25, 0.75, colors="#F2B6B6", linewidth=0.45, alpha=0.75, label="missing")
    ax1.vlines(values, 0.12, 0.98, colors=COLORS["blue"], linewidth=1.1, label="reachable")
    ax1.legend(loc="upper right", frameon=True)
    ax1.text(
        min(full),
        1.05,
        f"range {min(full)}..{max(full)}; max adjacent reachable-code gap = {int(max(gaps))}",
        ha="left",
        va="center",
        fontsize=9,
    )

    ax2.set_title("Spacing between successive reachable coefficients")
    ax2.bar(range(len(gaps)), gaps, color=COLORS["purple"], width=0.85)
    ax2.axhline(1, color=COLORS["gray"], linestyle="--", linewidth=1)
    ax2.set_xlabel("sorted reachable-code interval")
    ax2.set_ylabel("delta code")
    ax2.set_xlim(-1, len(gaps))
    ax2.grid(axis="y", alpha=0.25)
    ax2.text(
        0.01,
        0.9,
        "Non-uniform spacing is expected from coef = 11*ns - 10*nf.",
        transform=ax2.transAxes,
        ha="left",
        va="center",
        fontsize=9,
    )
    save(fig, "fine_grid_coverage.pdf")


def generate_mptdc_block_diagram() -> None:
    fig, ax = setup_canvas((15.5, 8.5), "MPTDC v2.4 functional block diagram")

    rounded_box(ax, 0.4, 6.7, 2.3, 1.0, "CSR config\nclk_sys\nmax_hits=1", COLORS["gray2"])
    rounded_box(ax, 0.4, 4.5, 2.3, 1.2, "Async capture\nSTART / STOP\nctx allocate", COLORS["orange2"], COLORS["orange"])
    rounded_box(ax, 3.4, 5.95, 2.2, 1.0, "slow ring osc\nNE=8 taps", COLORS["green2"], COLORS["green"])
    rounded_box(ax, 3.4, 4.25, 2.2, 1.0, "fast ring osc\nNE=8 taps", COLORS["purple2"], COLORS["purple"])
    rounded_box(ax, 6.25, 4.7, 2.65, 1.45, "8x8 PD matrix\nPD_N=64\nhit_level + nfast", COLORS["blue2"], COLORS["blue"])
    rounded_box(ax, 6.25, 2.5, 2.65, 1.35, "meas_ctrl\nIDLE -> MEASURE\n-> SNAPSHOT\n-> CAPTURE\n-> STOP_OSC -> CLEAR", "#FFF6D8", "#B7791F", fontsize=9)
    rounded_box(ax, 9.7, 4.6, 2.35, 1.5, "2-context bank\nsnapshot hold\natomic capture", COLORS["green2"], COLORS["green"])
    rounded_box(ax, 12.85, 4.75, 2.45, 1.3, "drain_ctrl\nclk_sys\nIDLE / META\nSCAN / EOC", COLORS["purple2"], COLORS["purple"])
    rounded_box(ax, 12.85, 2.65, 2.45, 1.25, "sync FIFO\nnarrow16 TX\n16-bit ready/valid", COLORS["gray2"])
    rounded_box(ax, 3.35, 2.45, 2.25, 1.1, "gray counters\nslow snapshot\nfast count", COLORS["blue2"], COLORS["blue"])

    arrow(ax, (2.7, 5.1), (3.4, 6.45), "start enables slow", COLORS["orange"])
    arrow(ax, (2.7, 5.0), (3.4, 4.75), "stop enables fast", COLORS["orange"])
    arrow(ax, (5.6, 6.45), (6.25, 5.72), "slow phases", COLORS["green"])
    arrow(ax, (5.6, 4.75), (6.25, 5.02), "fast phases", COLORS["purple"])
    arrow(ax, (5.55, 3.0), (6.25, 4.88), "counts", COLORS["blue"])
    arrow(ax, (8.9, 5.35), (9.7, 5.35), "wide image", COLORS["blue"])
    arrow(ax, (7.55, 4.7), (7.55, 3.85), "any_hit", COLORS["blue"])
    arrow(ax, (8.9, 3.15), (9.7, 4.85), "snapshot_en\ncapture_en", "#B7791F")
    arrow(ax, (12.05, 5.35), (12.85, 5.35), "ctx ready", COLORS["green"])
    arrow(ax, (14.08, 4.75), (14.08, 3.9), "records", COLORS["purple"])
    arrow(ax, (12.85, 3.25), (11.95, 4.65), "release ctx", COLORS["purple"], rad=-0.18)
    arrow(ax, (1.55, 6.7), (1.55, 5.7), "arm / mode", COLORS["gray"], dashed=True)
    arrow(ax, (2.7, 7.15), (12.85, 3.25), "out_mode + backpressure status", COLORS["gray"], rad=-0.12, dashed=True)

    ax.text(
        8,
        0.85,
        "Active report truth: NE=8, PD_N=64, two contexts, configured max_hits=1 for fast OR-reduction close.",
        ha="center",
        va="center",
        fontsize=11,
        bbox=dict(boxstyle="round,pad=0.35", fc="white", ec=COLORS["line"]),
    )
    save(fig, "mptdc_block_diagram.pdf")


def generate_mptdc_overview() -> None:
    fig, ax = setup_canvas((15.5, 8.4), "MPTDC active overview inside SPADMIC")

    rounded_box(ax, 0.6, 5.75, 2.5, 1.1, "SPAD / CAL\nasync events", COLORS["orange2"], COLORS["orange"])
    rounded_box(ax, 0.6, 3.8, 2.5, 1.1, "CSR control\nclk_sys\nmax_hits", COLORS["gray2"], COLORS["gray"])
    rounded_box(ax, 3.9, 5.15, 2.45, 1.35, "async front-end\nSTART / STOP\ncontext allocate", "#FFF6D8", "#B7791F")
    rounded_box(ax, 7.05, 5.85, 2.2, 0.95, "slow ring\nNE=8 taps", COLORS["green2"], COLORS["green"])
    rounded_box(ax, 7.05, 4.45, 2.2, 0.95, "fast ring\nNE=8 taps", COLORS["purple2"], COLORS["purple"])
    rounded_box(ax, 7.05, 2.75, 2.2, 0.95, "Gray counters\nboundary snaps", COLORS["blue2"], COLORS["blue"])
    rounded_box(ax, 10.0, 4.35, 2.45, 1.55, "PD matrix\n8x8 phases\n64 cells", COLORS["blue2"], COLORS["blue"])
    rounded_box(ax, 10.0, 2.45, 2.45, 1.05, "measurement FSM\nclose / capture", "#FFF6D8", "#B7791F")
    rounded_box(ax, 13.05, 4.7, 2.15, 1.2, "2-context\nsnapshot bank", COLORS["green2"], COLORS["green"])
    rounded_box(ax, 13.05, 2.65, 2.15, 1.25, "drain + FIFO\nnarrow16 TX", COLORS["purple2"], COLORS["purple"])

    arrow(ax, (3.1, 6.3), (3.9, 5.9), "events")
    arrow(ax, (3.1, 4.35), (3.9, 5.2), "arm / cfg", COLORS["gray"], dashed=True)
    arrow(ax, (6.35, 5.85), (7.05, 6.32), "start")
    arrow(ax, (6.35, 5.45), (7.05, 4.92), "stop")
    arrow(ax, (9.25, 6.32), (10.0, 5.35), "slow phases", COLORS["green"])
    arrow(ax, (9.25, 4.92), (10.0, 4.95), "fast phases", COLORS["purple"])
    arrow(ax, (9.25, 3.2), (10.0, 4.45), "counts", COLORS["blue"])
    arrow(ax, (11.25, 4.35), (11.25, 3.5), "hit image")
    arrow(ax, (12.45, 5.25), (13.05, 5.25), "snapshot")
    arrow(ax, (14.12, 4.7), (14.12, 3.9), "records")
    arrow(ax, (13.05, 3.2), (12.45, 4.85), "release", COLORS["purple"], rad=-0.15)

    ax.text(
        8,
        0.95,
        "Report baseline: active RTL uses an 8x8 phase detector matrix, 64 PD cells, two contexts, and host-side calibration.",
        ha="center",
        va="center",
        fontsize=10.5,
        bbox=dict(boxstyle="round,pad=0.35", fc="white", ec=COLORS["line"]),
    )
    save(fig, "mptdc_overview.pdf")


def generate_vernier_transition_map() -> None:
    fig, ax = setup_canvas((15.5, 8.2), "From Vernier reference to active MPTDC RTL")

    rounded_box(ax, 0.55, 5.55, 3.4, 1.15, "Reference idea\nslow / fast ring\nphase comparison", COLORS["blue2"], COLORS["blue"])
    rounded_box(ax, 0.55, 3.45, 3.4, 1.15, "Theoretical output\nfine code + coarse count", COLORS["green2"], COLORS["green"])
    rounded_box(ax, 4.9, 5.55, 3.35, 1.15, "Active event capture\nasync START / STOP\nboundary class", COLORS["orange2"], COLORS["orange"])
    rounded_box(ax, 4.9, 3.45, 3.35, 1.15, "Implemented matrix\nNE=8 per ring\n64 phase cells", COLORS["blue2"], COLORS["blue"])
    rounded_box(ax, 9.1, 5.55, 3.2, 1.15, "Robust storage\n2 contexts\natomic snapshot", COLORS["green2"], COLORS["green"])
    rounded_box(ax, 9.1, 3.45, 3.2, 1.15, "Digital readout\nfixed scan order\n16-bit packets", COLORS["purple2"], COLORS["purple"])
    rounded_box(ax, 12.8, 4.5, 2.55, 1.35, "Host analysis\n6D LUT\ncalibration", "#FFF6D8", "#B7791F")

    arrow(ax, (3.95, 6.12), (4.9, 6.12), "real inputs")
    arrow(ax, (3.95, 4.02), (4.9, 4.02), "RTL budget")
    arrow(ax, (8.25, 6.12), (9.1, 6.12), "freeze")
    arrow(ax, (8.25, 4.02), (9.1, 4.02), "scan")
    arrow(ax, (12.3, 6.12), (13.0, 5.65), "observables")
    arrow(ax, (12.3, 4.02), (13.0, 4.72), "CSV")
    arrow(ax, (6.58, 5.55), (6.58, 4.6), "maps to")
    arrow(ax, (10.7, 5.55), (10.7, 4.6), "drains as")

    ax.text(
        8,
        1.25,
        "The transition preserves the Vernier principle while adding asynchronous capture, CDC-safe counters, buffering, packetization, and external calibration.",
        ha="center",
        va="center",
        fontsize=10.5,
        bbox=dict(boxstyle="round,pad=0.35", fc="white", ec=COLORS["line"]),
    )
    save(fig, "vernier_transition_map.pdf")


def generate_calibration_flow() -> None:
    fig, ax = setup_canvas((15.0, 7.4), "External calibration flow")
    ax.set_ylim(0, 7.7)

    rounded_box(ax, 0.55, 4.9, 2.45, 1.1, "MPTDC RTL\nraw observables\n8x8 phases", COLORS["blue2"], COLORS["blue"])
    rounded_box(ax, 3.65, 4.9, 2.45, 1.1, "campaign CSV\ncode-density\nstress runs", COLORS["green2"], COLORS["green"])
    rounded_box(ax, 6.75, 4.9, 2.45, 1.1, "training split\naggregate keys\nmean residual", "#FFF6D8", "#B7791F")
    rounded_box(ax, 9.85, 4.9, 2.45, 1.1, "6D LUT\nns, nf, nslow\nnfast_hit, phase, hit_idx", COLORS["purple2"], COLORS["purple"], fontsize=8.5)
    rounded_box(ax, 12.85, 4.9, 1.95, 1.1, "held-out\nvalidation", COLORS["orange2"], COLORS["orange"])
    rounded_box(ax, 6.65, 2.35, 2.75, 1.2, "report figures\nRMS / residuals\nDNL / INL", COLORS["gray2"], COLORS["gray"])

    arrow(ax, (3.0, 5.45), (3.65, 5.45), "export")
    arrow(ax, (6.1, 5.45), (6.75, 5.45), "tables")
    arrow(ax, (9.2, 5.45), (9.85, 5.45), "learn")
    arrow(ax, (12.3, 5.45), (12.85, 5.45), "apply")
    arrow(ax, (13.82, 4.9), (9.25, 3.2), "metrics", COLORS["orange"], rad=-0.15)
    arrow(ax, (5.0, 4.9), (6.85, 3.25), "plots", COLORS["green"], rad=0.1)

    ax.text(
        7.5,
        1.05,
        "Calibration remains outside the ASIC: the silicon exports rich raw data, while model updates stay in host-side analysis.",
        ha="center",
        va="center",
        fontsize=10.5,
        bbox=dict(boxstyle="round,pad=0.35", fc="white", ec=COLORS["line"]),
    )
    save(fig, "calibration_flow.pdf")


def generate_clock_domain_diagram() -> None:
    fig, ax = setup_canvas((15.5, 8.6), "Clock-domain and CDC map")

    zones = [
        (0.45, 1.2, 4.55, 6.45, "Async event domain", COLORS["orange2"], COLORS["orange"]),
        (5.55, 1.2, 4.8, 6.45, "fast / slow oscillator domains", COLORS["blue2"], COLORS["blue"]),
        (10.9, 1.2, 4.65, 6.45, "clk_sys domain", COLORS["purple2"], COLORS["purple"]),
    ]
    for x, y, w, h, title, fc, ec in zones:
        ax.add_patch(Rectangle((x, y), w, h, facecolor=fc, edgecolor=ec, linewidth=1.5, alpha=0.8))
        ax.text(x + w / 2, y + h - 0.35, title, ha="center", va="center", fontsize=12, weight="bold")

    rounded_box(ax, 0.85, 5.9, 3.75, 0.9, "START latch\naccept if context free", "white", COLORS["orange"])
    rounded_box(ax, 0.85, 4.55, 3.75, 0.9, "STOP latch\nstarts fast osc", "white", COLORS["orange"])
    rounded_box(ax, 0.85, 2.8, 3.75, 1.0, "async boundary capture\nphase0_snap\nslow_boundary_inc", "white", COLORS["orange"])

    rounded_box(ax, 5.95, 5.95, 3.9, 0.85, "slow counter\nasync snapshot at STOP", "white", COLORS["green"])
    rounded_box(ax, 5.95, 4.6, 3.9, 0.95, "fast counter + 8x8 PD\nmax_hits=1 OR close", "white", COLORS["blue"])
    rounded_box(ax, 5.95, 3.05, 3.9, 1.05, "meas_ctrl fast FSM\nSNAPSHOT before CAPTURE", "white", "#B7791F")
    rounded_box(ax, 5.95, 1.75, 3.9, 0.85, "context bank\nstable static image", "white", COLORS["green"])

    rounded_box(ax, 11.3, 6.0, 3.85, 0.85, "CSR + global watchdog", "white", COLORS["gray"])
    rounded_box(ax, 11.3, 4.6, 3.85, 0.95, "2-flop status sync\nctx ready / release", "white", COLORS["purple"])
    rounded_box(ax, 11.3, 3.1, 3.85, 0.95, "drain_ctrl\nMETA -> SCAN -> EOC", "white", COLORS["purple"])
    rounded_box(ax, 11.3, 1.75, 3.85, 0.85, "sync FIFO + narrow16", "white", COLORS["purple"])

    arrow(ax, (4.6, 6.35), (5.95, 6.35), "slow enable", COLORS["orange"])
    arrow(ax, (4.6, 5.0), (5.95, 5.08), "fast enable", COLORS["orange"])
    arrow(ax, (4.6, 3.28), (5.95, 5.98), "STOP snapshot", COLORS["orange"], rad=0.1)
    arrow(ax, (7.9, 5.95), (7.9, 5.55), "gray CDC", COLORS["green"])
    arrow(ax, (7.9, 4.6), (7.9, 4.1), "close_any", COLORS["blue"])
    arrow(ax, (7.9, 3.05), (7.9, 2.6), "capture", "#B7791F")
    arrow(ax, (9.85, 2.18), (11.3, 5.05), "ready sync", COLORS["purple"], rad=0.12)
    arrow(ax, (11.3, 3.55), (9.85, 2.18), "release sync", COLORS["purple"], rad=0.12)
    arrow(ax, (13.22, 4.6), (13.22, 4.05), "select ctx", COLORS["purple"])
    arrow(ax, (13.22, 3.1), (13.22, 2.6), "records", COLORS["purple"])
    arrow(ax, (11.3, 6.42), (4.6, 6.35), "conv_arm", COLORS["gray"], dashed=True, rad=0.14)

    ax.text(
        8,
        0.65,
        "Only compact control/status crosses domains; the wide PD image is frozen first, then scanned in clk_sys.",
        ha="center",
        va="center",
        fontsize=10,
        bbox=dict(boxstyle="round,pad=0.3", fc="white", ec=COLORS["line"]),
    )
    save(fig, "clock_domain_diagram.pdf")


def fsm_node(
    ax: plt.Axes,
    xy: tuple[float, float],
    label: str,
    note: str,
    fc: str,
    ec: str,
    r: float = 0.82,
) -> None:
    x, y = xy
    circ = Circle((x, y), r, facecolor=fc, edgecolor=ec, linewidth=1.6, zorder=3)
    ax.add_patch(circ)
    ax.text(x, y + 0.14, label, ha="center", va="center", fontsize=10.5, weight="bold", zorder=4)
    ax.text(x, y - 0.28, wrap(note, 14), ha="center", va="center", fontsize=8, zorder=4)


def generate_meas_ctrl_fsm() -> None:
    fig, ax = setup_canvas((14.5, 8.2), "Measurement FSM in the fast domain")

    nodes = {
        "IDLE": (2.0, 4.7, "wait for\nmeas_active", COLORS["gray2"], COLORS["gray"]),
        "MEASURE": (4.05, 6.35, "PD gate open\naccumulate hits", COLORS["blue2"], COLORS["blue"]),
        "SNAPSHOT": (7.1, 6.35, "freeze wide\nimage in hold regs", COLORS["green2"], COLORS["green"]),
        "CAPTURE": (10.15, 6.35, "commit selected\ncontext", COLORS["green2"], COLORS["green"]),
        "STOP_OSC": (12.2, 4.7, "clear frontend\nstop slow osc", COLORS["orange2"], COLORS["orange"]),
        "CLEAR": (7.1, 2.85, "clear PD cells\nand counters", COLORS["red2"], COLORS["red"]),
    }
    for name, (x, y, note, fc, ec) in nodes.items():
        fsm_node(ax, (x, y), name, note, fc, ec)

    arrow(ax, (2.72, 5.25), (3.37, 5.82), "meas_active")
    arrow(ax, (4.9, 6.35), (6.22, 6.35), "close_any")
    arrow(ax, (7.98, 6.35), (9.28, 6.35), "next fast edge")
    arrow(ax, (10.92, 5.92), (11.62, 5.22), "context written")
    arrow(ax, (11.55, 4.12), (7.8, 3.28), "osc stopped", rad=0.1)
    arrow(ax, (6.28, 3.12), (2.72, 4.25), "clear done", rad=0.15)
    arrow(ax, (4.05, 5.52), (4.05, 4.45), "max_hits=1:\nfast OR close", COLORS["blue"], rad=0.2)
    arrow(ax, (4.85, 5.85), (6.28, 3.42), "watchdog or\ncounted close", COLORS["gray"], dashed=True, rad=-0.18)

    rounded_box(
        ax,
        1.0,
        1.05,
        12.2,
        0.9,
        "Active sequence: IDLE -> MEASURE -> SNAPSHOT -> CAPTURE -> STOP_OSC -> CLEAR -> IDLE.  SNAPSHOT protects the measurement image before cleanup.",
        "white",
        COLORS["line"],
        fontsize=10,
    )
    save(fig, "meas_ctrl_fsm.pdf")


def generate_drain_ctrl_fsm() -> None:
    fig, ax = setup_canvas((12.8, 7.2), "System-domain drain FSM")
    ax.set_xlim(0, 13)
    ax.set_ylim(0, 7.5)

    pos = {
        "IDLE": (2.0, 4.1, "wait for synced\nready context", COLORS["gray2"], COLORS["gray"]),
        "META": (5.0, 5.55, "push one META\nrecord", COLORS["blue2"], COLORS["blue"]),
        "SCAN": (8.4, 4.1, "scan PD_N=64\nemit hit records", COLORS["green2"], COLORS["green"]),
        "EOC": (5.0, 2.65, "release context\nconv_done pulse", COLORS["purple2"], COLORS["purple"]),
    }
    for name, (x, y, note, fc, ec) in pos.items():
        fsm_node(ax, (x, y), name, note, fc, ec, r=0.9)

    arrow(ax, (2.8, 4.5), (4.17, 5.15), "any selectable")
    arrow(ax, (5.9, 5.35), (7.58, 4.55), "FIFO has room")
    arrow(ax, (7.58, 3.65), (5.85, 2.9), "scan_done or\nall hits found")
    arrow(ax, (4.12, 2.92), (2.75, 3.68), "release")
    arrow(ax, (8.4, 3.18), (8.4, 5.02), "skip empty /\nwrite hit /\nstall if full", COLORS["green"], rad=0.33)

    rounded_box(ax, 0.9, 0.75, 11.0, 0.9, "The drain never reconstructs timing order; it packetizes the frozen matrix in fixed ns-major, nf-minor scan order.", "white", COLORS["line"], fontsize=10)
    save(fig, "drain_ctrl_fsm.pdf")


def draw_word(
    ax: plt.Axes,
    y: float,
    fields: list[tuple[int, str, str]],
    title: str,
    note: str = "",
) -> None:
    x = 0.5
    bit_hi = 15
    ax.text(x, y + 0.48, title, ha="left", va="center", fontsize=11, weight="bold")
    for width, label, color in fields:
        rect = Rectangle((x, y - 0.28), width, 0.55, facecolor=color, edgecolor=COLORS["line"], linewidth=1.0)
        ax.add_patch(rect)
        bit_lo = bit_hi - width + 1
        rng = f"[{bit_hi}]" if width == 1 else f"[{bit_hi}:{bit_lo}]"
        ax.text(x + width / 2, y + 0.04, wrap(label, max(5, width * 3)), ha="center", va="center", fontsize=8)
        ax.text(x + width / 2, y - 0.43, rng, ha="center", va="top", fontsize=7, color=COLORS["gray"])
        x += width
        bit_hi = bit_lo - 1
    if note:
        ax.text(17.0, y, wrap(note, 30), ha="left", va="center", fontsize=8.5)


def generate_packet_format() -> None:
    fig, ax = plt.subplots(figsize=(15.5, 7.8))
    ax.set_axis_off()
    ax.set_xlim(0, 21.2)
    ax.set_ylim(0, 8.2)
    ax.text(10.6, 7.85, "MPTDC v2.4 narrow 16-bit packet words", ha="center", va="center", fontsize=16, weight="bold")

    header = [
        (2, "10", COLORS["purple2"]),
        (2, "ctx", COLORS["blue2"]),
        (1, "phase0", COLORS["green2"]),
        (4, "hit_count", "#FFF6D8"),
        (4, "flags", COLORS["orange2"]),
        (2, "out_mode", COLORS["gray2"]),
        (1, "boundary", COLORS["red2"]),
    ]
    hit_w0 = [
        (1, "0", COLORS["gray2"]),
        (7, "nslow[6:0]", COLORS["blue2"]),
        (7, "nfast[6:0]", COLORS["green2"]),
        (1, "0", COLORS["gray2"]),
    ]
    hit_w1_feat = [
        (1, "0", COLORS["gray2"]),
        (4, "ns", COLORS["blue2"]),
        (4, "nf", COLORS["green2"]),
        (7, "reserved", COLORS["gray2"]),
    ]
    hit_w1_ts = [(16, "t_raw_ps[15:0]", COLORS["purple2"])]
    eoc = [(2, "11", COLORS["purple2"]), (14, "conv_count[13:0]", COLORS["orange2"])]

    draw_word(ax, 6.8, header, "Header", "Conversion metadata from META record.")
    draw_word(ax, 5.55, hit_w0, "Hit W0", "Common per-hit coarse counters.")
    draw_word(ax, 4.3, hit_w1_feat, "Hit W1, RAW_FEATURES", "Phase fields use values 0..7 in active NE=8 RTL.")
    draw_word(ax, 3.05, hit_w1_ts, "Hit W1, RAW_TIMESTAMP", "Timestamp-only mode.")
    draw_word(ax, 1.8, hit_w1_ts, "Hit W2, FULL only", "FULL mode adds timestamp after feature word.")
    draw_word(ax, 0.55, eoc, "EOC", "End marker and running conversion count.")

    ax.text(
        10.6,
        7.25,
        "Packet order: Header, hit words for each emitted hit, then EOC.  With configured max_hits=1, only the earliest close is requested, but the frozen matrix remains the source of truth.",
        ha="center",
        va="center",
        fontsize=10,
        bbox=dict(boxstyle="round,pad=0.25", fc="white", ec=COLORS["line"]),
    )
    save(fig, "packet_format_v23.pdf")


def main() -> None:
    from generate_ieee_mptdc_figures import main as generate_publication_figures

    generate_publication_figures()


if __name__ == "__main__":
    main()
