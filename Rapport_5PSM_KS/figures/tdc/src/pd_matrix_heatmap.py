#!/usr/bin/env python3
"""Génère la carte thermique 8x8 de la matrice de phases Vernier."""

from __future__ import annotations

from pathlib import Path

import matplotlib as mpl

mpl.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

OUT_DIR = Path(__file__).resolve().parents[1]


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
            "xtick.labelsize": 9,
            "ytick.labelsize": 9,
            "axes.spines.top": True,
            "axes.spines.right": True,
            "pdf.fonttype": 42,
            "ps.fonttype": 42,
        }
    )


def save(fig: plt.Figure, stem: str) -> None:
    for ext in ("pdf", "svg"):
        fig.savefig(OUT_DIR / f"{stem}.{ext}", bbox_inches="tight")
    plt.close(fig)


def main() -> None:
    setup_style()

    ns = np.arange(8)[:, None]
    nf = np.arange(8)[None, :]
    values = 11 * ns - 10 * nf

    fig, ax = plt.subplots(figsize=(6.4, 5.5), constrained_layout=True)
    cmap = plt.get_cmap("viridis")
    im = ax.imshow(values, origin="lower", cmap=cmap)

    ax.set_title("Carte thermique de la matrice de phases 8x8")
    ax.set_xlabel("Indice de phase rapide $n_f$")
    ax.set_ylabel("Indice de phase lente $n_s$")
    ax.set_xticks(range(8))
    ax.set_yticks(range(8))
    ax.set_xticks(np.arange(-0.5, 8, 1), minor=True)
    ax.set_yticks(np.arange(-0.5, 8, 1), minor=True)
    ax.grid(which="minor", color="white", linestyle="-", linewidth=1.2)
    ax.tick_params(which="minor", bottom=False, left=False)

    norm = mpl.colors.Normalize(vmin=int(values.min()), vmax=int(values.max()))
    for row in range(8):
        for col in range(8):
            val = int(values[row, col])
            rgba = cmap(norm(val))
            luminance = 0.2126 * rgba[0] + 0.7152 * rgba[1] + 0.0722 * rgba[2]
            text_color = "white" if luminance < 0.48 else "#111111"
            ax.text(
                col,
                row,
                f"${row}, {col}$\n{val:+d}",
                ha="center",
                va="center",
                color=text_color,
                fontsize=8,
            )

    colorbar = fig.colorbar(im, ax=ax, shrink=0.92)
    colorbar.set_label(r"Valeur nominale $11n_s - 10n_f$")

    for spine in ax.spines.values():
        spine.set_visible(True)
        spine.set_color("#111111")
        spine.set_linewidth(0.8)

    save(fig, "pd_matrix_heatmap")


if __name__ == "__main__":
    main()
