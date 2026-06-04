#!/usr/bin/env python3
"""
Fine Grid Analysis — MPTDC Vernier TDC
=======================================

Characterizes the Vernier fine-phase grid for an 8×8 MPTDC TDC.

For each hit the fine-value coefficient is:
    fine_coef = ns * K_VERNIER - nf * (K_VERNIER - 1)

where (ns, nf) ∈ {0, …, 7}².  Not all integers in [min, max] are
reachable — this script identifies the gaps, computes theoretical
DNL / INL, and produces diagnostic plots.
"""

import argparse
import sys
from pathlib import Path

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
from matplotlib.colors import TwoSlopeNorm

SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from analysis import mptdc_char_common as char_common
from analysis.mptdc_char_common import FREQ_MODE_CHOICES, FREQ_MODE_NOMINAL

# ── Physical / design constants ──────────────────────────────────────
NE = char_common.NE          # number of phases (slow & fast)
K_VERNIER = char_common.K_VERNIER
DELTA_LSB = char_common.DELTA_LSB_PS


def set_frequency_mode(mode):
    global K_VERNIER, DELTA_LSB
    cfg = char_common.configure_frequency_mode(mode)
    K_VERNIER = int(cfg["K_VERNIER"])
    DELTA_LSB = int(cfg["DELTA_LSB"])
    return cfg


# ── Core computation ─────────────────────────────────────────────────

def build_fine_grid(ne=NE, k=None):
    """Return (ns_arr, nf_arr, coef_grid) for all (ns, nf) pairs."""
    if k is None:
        k = K_VERNIER
    ns = np.arange(ne)
    nf = np.arange(ne)
    NS, NF = np.meshgrid(ns, nf, indexing="ij")  # NS[i,j]=i, NF[i,j]=j
    coef = NS * k - NF * (k - 1)
    return NS, NF, coef


def unique_sorted(coef_grid):
    """Sorted array of unique achievable fine_coef values."""
    return np.unique(coef_grid)


def find_gaps(achievable):
    """Integers in [min, max] that are *not* achievable."""
    full = np.arange(achievable.min(), achievable.max() + 1)
    return np.setdiff1d(full, achievable)


def diagonal_groups(ne=NE, k=None):
    """Per-diagonal (d = ns − nf) statistics.

    Returns a list of dicts sorted by d, each containing:
        d        : diagonal index
        coefs    : sorted achievable values on this diagonal
        count    : number of values
    """
    if k is None:
        k = K_VERNIER
    groups = []
    for d in range(-(ne - 1), ne):
        coefs = []
        for ns in range(ne):
            nf = ns - d
            if 0 <= nf < ne:
                coefs.append(ns * k - nf * (k - 1))
        coefs = sorted(set(coefs))
        groups.append({"d": d, "coefs": np.array(coefs), "count": len(coefs)})
    return groups


def compute_dnl_inl(achievable):
    """Theoretical DNL and INL from non-uniform spacing.

    ideal_bin_width = (max − min) / (N − 1)
    DNL(k)  = (step_k / ideal_bin_width) − 1
    INL(k)  = cumulative sum of DNL
    """
    steps = np.diff(achievable).astype(float)
    ideal = (achievable[-1] - achievable[0]) / (len(achievable) - 1)
    dnl = steps / ideal - 1.0
    inl = np.cumsum(dnl)
    return dnl, inl, ideal


# ── Visualisation ────────────────────────────────────────────────────

def _apply_style():
    plt.rcParams.update({
        "font.family": "sans-serif",
        "font.size": 10,
        "axes.titlesize": 12,
        "axes.labelsize": 11,
        "figure.dpi": 150,
        "savefig.dpi": 150,
        "axes.grid": True,
        "grid.alpha": 0.3,
    })


def plot_heatmap(ax, coef_grid, ne):
    norm = TwoSlopeNorm(vmin=coef_grid.min(), vcenter=0, vmax=coef_grid.max())
    im = ax.imshow(coef_grid, origin="lower", cmap="RdBu_r", norm=norm,
                   aspect="equal")
    ax.set_xticks(range(ne))
    ax.set_yticks(range(ne))
    ax.set_xlabel("$n_f$ (fast phase index)")
    ax.set_ylabel("$n_s$ (slow phase index)")
    ax.set_title(f"fine_coef = $n_s \\cdot {K_VERNIER} - n_f \\cdot {K_VERNIER - 1}$")
    for i in range(ne):
        for j in range(ne):
            ax.text(j, i, str(coef_grid[i, j]), ha="center", va="center",
                    fontsize=7, color="k")
    plt.colorbar(im, ax=ax, label="fine_coef")


def plot_number_line(ax, achievable, missing):
    ax.eventplot([achievable], lineoffsets=0.5, linelengths=0.8,
                 colors="steelblue", label="Achievable")
    if len(missing):
        ax.eventplot([missing], lineoffsets=0.5, linelengths=0.4,
                     colors="salmon", label="Missing")
    ax.set_yticks([])
    ax.set_xlabel("fine_coef value")
    ax.set_title("Achievable vs Missing Values on the Number Line")
    ax.legend(loc="upper right", fontsize=8)


def plot_gap_histogram(ax, achievable):
    steps = np.diff(achievable)
    bins = np.arange(steps.min() - 0.5, steps.max() + 1.5, 1)
    ax.hist(steps, bins=bins, color="teal", edgecolor="white", rwidth=0.85)
    ax.set_xlabel("Gap size (fine_coef units)")
    ax.set_ylabel("Count")
    ax.set_title("Histogram of Consecutive-Value Gap Sizes")
    ax.set_xticks(range(int(steps.min()), int(steps.max()) + 1))


def plot_dnl_inl(ax_dnl, ax_inl, dnl, inl, achievable):
    codes = achievable[1:]  # DNL is between consecutive codes
    ax_dnl.bar(codes, dnl, width=0.8, color="darkorange", edgecolor="none")
    ax_dnl.axhline(0, color="k", lw=0.5)
    ax_dnl.set_ylabel("DNL (LSB)")
    ax_dnl.set_title(f"DNL  (worst case: {dnl.max():+.2f} / {dnl.min():+.2f} LSB)")

    ax_inl.plot(codes, inl, "-o", ms=2, color="purple")
    ax_inl.axhline(0, color="k", lw=0.5)
    ax_inl.set_xlabel("fine_coef code")
    ax_inl.set_ylabel("INL (LSB)")
    ax_inl.set_title(f"INL  (worst case: {inl.max():+.2f} / {inl.min():+.2f} LSB)")


def plot_diagonal_groups(ax, groups):
    for g in groups:
        d = g["d"]
        coefs = g["coefs"]
        ax.plot(coefs, [d] * len(coefs), "s", ms=4, color="steelblue")
    ax.set_xlabel("fine_coef value")
    ax.set_ylabel("Diagonal $d = n_s - n_f$")
    ax.set_title("Per-Diagonal Value Distribution")
    ax.set_yticks([g["d"] for g in groups])


def generate_pdf(pdf_path, coef_grid, ne, achievable, missing, dnl, inl, groups):
    _apply_style()
    with PdfPages(pdf_path) as pdf:
        # Page 1: heatmap + number line
        fig, axes = plt.subplots(2, 1, figsize=(10, 9),
                                 gridspec_kw={"height_ratios": [3, 1]})
        plot_heatmap(axes[0], coef_grid, ne)
        plot_number_line(axes[1], achievable, missing)
        fig.tight_layout()
        pdf.savefig(fig)
        plt.close(fig)

        # Page 2: gap histogram + diagonal groups
        fig, axes = plt.subplots(2, 1, figsize=(10, 8))
        plot_gap_histogram(axes[0], achievable)
        plot_diagonal_groups(axes[1], groups)
        fig.tight_layout()
        pdf.savefig(fig)
        plt.close(fig)

        # Page 3: DNL / INL
        fig, axes = plt.subplots(2, 1, figsize=(10, 7), sharex=True)
        plot_dnl_inl(axes[0], axes[1], dnl, inl, achievable)
        fig.tight_layout()
        pdf.savefig(fig)
        plt.close(fig)


# ── Text report ──────────────────────────────────────────────────────

def print_report(achievable, missing, dnl, inl, ideal_step, groups):
    total_range = achievable.max() - achievable.min() + 1
    n_ach = len(achievable)
    n_mis = len(missing)
    steps = np.diff(achievable)

    hdr = (
        f"\nFine Grid Analysis — MPTDC Vernier TDC "
        f"(NE={NE}, K_VERNIER={K_VERNIER})"
    )
    print(hdr)
    print("=" * len(hdr.strip()))
    print(f"Achievable values : {n_ach} / {total_range} "
          f"({100 * n_ach / total_range:.1f}%)")
    print(f"Range             : {achievable.min()} to {achievable.max()}")
    print(f"Missing values    : {n_mis}")
    print(f"Ideal bin width   : {ideal_step:.4f} codes "
          f"({ideal_step * DELTA_LSB:.2f} ps)")
    print()

    print("Gap statistics (between consecutive achievable codes):")
    print(f"  Min gap  : {steps.min()} ({steps.min() * DELTA_LSB} ps)")
    print(f"  Max gap  : {steps.max()} ({steps.max() * DELTA_LSB} ps)")
    print(f"  Mean gap : {steps.mean():.2f} ({steps.mean() * DELTA_LSB:.1f} ps)")
    print()

    print("DNL / INL (theoretical, uniform-density model):")
    print(f"  Worst DNL : {dnl.max():+.4f} / {dnl.min():+.4f} LSB")
    print(f"  Worst INL : {inl.max():+.4f} / {inl.min():+.4f} LSB")
    print()

    print("Per-diagonal statistics (d = ns − nf):")
    print(f"  {'d':>3s}  {'count':>5s}  {'min':>5s}  {'max':>5s}  "
          f"{'span':>5s}  achievable values")
    print(f"  {'---':>3s}  {'-----':>5s}  {'-----':>5s}  {'-----':>5s}  "
          f"{'-----':>5s}  " + "-" * 30)
    for g in groups:
        c = g["coefs"]
        vals = ", ".join(str(v) for v in c)
        print(f"  {g['d']:>3d}  {g['count']:>5d}  {c.min():>5d}  "
              f"{c.max():>5d}  {c.max() - c.min():>5d}  [{vals}]")

    # Inter-diagonal gaps
    print()
    print("Inter-diagonal gaps (last value of d → first value of d+1):")
    for i in range(len(groups) - 1):
        last_val = groups[i]["coefs"].max()
        first_val = groups[i + 1]["coefs"].min()
        gap = first_val - last_val
        print(f"  d={groups[i]['d']:>3d} → d={groups[i + 1]['d']:>3d} : "
              f"gap = {gap:>3d} ({gap * DELTA_LSB:>4d} ps)")


# ── CLI ──────────────────────────────────────────────────────────────

def parse_args():
    p = argparse.ArgumentParser(
        description="Characterise the Vernier fine-phase grid "
                    "for the MPTDC TDC.")
    p.add_argument("-o", "--output", type=str,
                   default="fine_grid_analysis.pdf",
                   help="Output PDF path (default: fine_grid_analysis.pdf)")
    p.add_argument("--no-plot", action="store_true",
                   help="Skip PDF generation (text report only)")
    p.add_argument("--freq-mode", default=FREQ_MODE_NOMINAL,
                   choices=FREQ_MODE_CHOICES,
                   help="Frequency/tap mode used by the RTL")
    return p.parse_args()


def main():
    args = parse_args()
    freq_cfg = set_frequency_mode(args.freq_mode)
    print(
        "Frequency mode: "
        f"{freq_cfg['freq_mode']} "
        f"OSC_TS_SLOW_PS={freq_cfg['OSC_TS_SLOW_PS']} "
        f"OSC_TS_FAST_PS={freq_cfg['OSC_TS_FAST_PS']} "
        f"DELTA_STEP={freq_cfg['DELTA_STEP']} "
        f"DELTA_LSB={freq_cfg['DELTA_LSB']} "
        f"K_VERNIER={freq_cfg['K_VERNIER']}"
    )

    # 1–2. Build grid, unique values
    NS, NF, coef_grid = build_fine_grid()
    achievable = unique_sorted(coef_grid)

    # 3. Gaps
    missing = find_gaps(achievable)

    # 4. Diagonal groups
    groups = diagonal_groups()

    # 5. DNL / INL
    dnl, inl, ideal_step = compute_dnl_inl(achievable)

    # 7. Text report
    print_report(achievable, missing, dnl, inl, ideal_step, groups)

    # 6. PDF
    if not args.no_plot:
        pdf_path = Path(args.output)
        generate_pdf(pdf_path, coef_grid, NE, achievable, missing,
                     dnl, inl, groups)
        print(f"\nPlots saved to: {pdf_path.resolve()}")


if __name__ == "__main__":
    main()
