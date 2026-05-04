#!/usr/bin/env python3
"""
Shared plotting helpers for MPTDC analysis and calibration scripts.
"""

from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt

PALETTE = {
    "blue": "#1565c0",
    "red": "#c62828",
    "green": "#2e7d32",
    "purple": "#6a1b9a",
    "orange": "#ef6c00",
    "teal": "#00838f",
    "gray": "#616161",
}


def apply_report_style() -> None:
    """Apply a consistent plotting style suitable for report figures."""
    plt.rcParams.update({
        "font.family": "DejaVu Sans",
        "font.size": 10,
        "axes.titlesize": 12,
        "axes.labelsize": 11,
        "axes.titleweight": "semibold",
        "axes.grid": True,
        "grid.alpha": 0.22,
        "grid.linestyle": "--",
        "grid.linewidth": 0.6,
        "axes.spines.top": False,
        "axes.spines.right": False,
        "legend.frameon": True,
        "legend.framealpha": 0.92,
        "legend.edgecolor": "#cccccc",
        "figure.dpi": 150,
        "savefig.dpi": 180,
        "lines.linewidth": 1.6,
    })


def style_axes(ax, *, grid_axis: str = "both") -> None:
    """Apply consistent axis styling."""
    ax.grid(True, axis=grid_axis, alpha=0.22, linestyle="--", linewidth=0.6)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)


def save_figure(fig, out_path: str | Path) -> None:
    """Tight-layout and save a figure, creating parent directories as needed."""
    out_path = Path(out_path)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fig.tight_layout()
    fig.savefig(out_path, bbox_inches="tight")
    plt.close(fig)
