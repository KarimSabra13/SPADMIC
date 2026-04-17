from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

import fitz


ROOT = Path(__file__).resolve().parents[1]
SRC_DIR = ROOT / "figures" / "tdc" / "src"
PDF_DIR = ROOT / "figures" / "tdc"
SVG_DIR = ROOT / "figures" / "tdc" / "svg"
PNG_DIR = ROOT / "figures" / "tdc" / "png"
BUILD_DIR = ROOT / "build" / "thesis_tdc_figures"

FIGURES = [
    "mptdc_overview",
    "mptdc_block_diagram",
    "vernier_reference_architecture",
    "vernier_principle_detailed",
    "context_pipeline",
]

ALIASES = {
    "vernier_principle_detailed": ["vernier_timing_principle"],
}


def run(cmd: list[str], *, cwd: Path | None = None) -> None:
    subprocess.run(cmd, cwd=cwd, check=True)


def export_png(pdf_path: Path, png_path: Path, dpi: int = 220) -> None:
    doc = fitz.open(pdf_path)
    page = doc[0]
    scale = dpi / 72.0
    pix = page.get_pixmap(matrix=fitz.Matrix(scale, scale), alpha=False)
    pix.save(png_path)
    doc.close()


def render_figure(name: str) -> None:
    src = SRC_DIR / f"{name}.tex"
    work = BUILD_DIR / name
    work.mkdir(parents=True, exist_ok=True)

    run(
        [
            "pdflatex",
            "-interaction=nonstopmode",
            "-halt-on-error",
            f"-output-directory={work}",
            str(src),
        ],
        cwd=SRC_DIR,
    )

    pdf_src = work / f"{name}.pdf"
    pdf_out = PDF_DIR / f"{name}.pdf"
    svg_out = SVG_DIR / f"{name}.svg"
    png_out = PNG_DIR / f"{name}.png"

    shutil.copy2(pdf_src, pdf_out)
    run(["dvisvgm", "--pdf", str(pdf_out), "-n", "-o", str(svg_out)])
    export_png(pdf_out, png_out)

    for alias in ALIASES.get(name, []):
        shutil.copy2(pdf_out, PDF_DIR / f"{alias}.pdf")
        shutil.copy2(svg_out, SVG_DIR / f"{alias}.svg")
        shutil.copy2(png_out, PNG_DIR / f"{alias}.png")


def main() -> int:
    if shutil.which("pdflatex") is None:
        raise SystemExit("pdflatex is required")
    if shutil.which("dvisvgm") is None:
        raise SystemExit("dvisvgm is required")

    PDF_DIR.mkdir(parents=True, exist_ok=True)
    SVG_DIR.mkdir(parents=True, exist_ok=True)
    PNG_DIR.mkdir(parents=True, exist_ok=True)
    BUILD_DIR.mkdir(parents=True, exist_ok=True)

    for name in FIGURES:
        render_figure(name)

    return 0


if __name__ == "__main__":
    sys.exit(main())
