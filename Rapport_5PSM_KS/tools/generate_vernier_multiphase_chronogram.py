#!/usr/bin/env python3
"""Generate the vector chronogram used as Figure 6.3.

The script intentionally avoids third-party dependencies so the figure can be
rebuilt in restricted environments. It writes a compact PDF with vector
primitives, using the temporal model documented in Chapter 6.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


PAGE_W = 940.0
PAGE_H = 780.0
LEFT = 170.0
RIGHT = 900.0
T_END = 340.0
SCALE = (RIGHT - LEFT) / T_END


Color = tuple[float, float, float]
WHITE: Color = (1.00, 1.00, 1.00)
BLACK: Color = (0.08, 0.08, 0.08)
GRAY: Color = (0.72, 0.72, 0.72)
LIGHT_GRAY: Color = (0.88, 0.88, 0.88)
RED: Color = (0.69, 0.00, 0.00)
BLUE: Color = (0.00, 0.24, 0.62)
GREEN: Color = (0.00, 0.42, 0.18)
GREEN_LIGHT: Color = (0.82, 0.92, 0.85)
BUS_STROKE: Color = (0.33, 0.33, 0.33)
BUS_FILL: Color = (0.96, 0.96, 0.94)
EMPTY_FILL: Color = (0.985, 0.985, 0.985)


ROWS = [
    ("Départ / START", 700.0),
    ("Arrêt / STOP", 660.0),
    ("S_1", 620.0),
    ("S_2", 590.0),
    ("S_3", 560.0),
    ("S_4", 530.0),
    ("S_5", 500.0),
    ("N_slow", 455.0),
    ("n_s", 420.0),
    ("F_1", 380.0),
    ("F_2", 350.0),
    ("F_3", 320.0),
    ("F_4", 290.0),
    ("F_5", 260.0),
    ("N_fast", 220.0),
    ("n_f", 185.0),
    ("Couples / PD", 105.0),
]

Y = {name: value for name, value in ROWS}


def ps_to_x(t_ps: float) -> float:
    return LEFT + t_ps * SCALE


def esc(text: str) -> str:
    return text.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")


def rgb(color: Color) -> str:
    return f"{color[0]:.4f} {color[1]:.4f} {color[2]:.4f}"


@dataclass
class Canvas:
    width: float
    height: float
    ops: list[str]

    def line(
        self,
        x1: float,
        y1: float,
        x2: float,
        y2: float,
        color: Color = BLACK,
        width: float = 1.0,
        dash: str | None = None,
    ) -> None:
        dash_op = "[] 0 d" if dash is None else f"[{dash}] 0 d"
        self.ops.append(
            f"q {rgb(color)} RG {width:.3f} w {dash_op} "
            f"{x1:.2f} {y1:.2f} m {x2:.2f} {y2:.2f} l S Q"
        )

    def polyline(
        self,
        points: list[tuple[float, float]],
        color: Color = BLACK,
        width: float = 1.0,
        dash: str | None = None,
    ) -> None:
        if len(points) < 2:
            return
        dash_op = "[] 0 d" if dash is None else f"[{dash}] 0 d"
        cmds = [f"{points[0][0]:.2f} {points[0][1]:.2f} m"]
        cmds.extend(f"{x:.2f} {y:.2f} l" for x, y in points[1:])
        self.ops.append(
            f"q {rgb(color)} RG {width:.3f} w {dash_op} "
            + " ".join(cmds)
            + " S Q"
        )

    def rect(
        self,
        x: float,
        y: float,
        w: float,
        h: float,
        stroke: Color = BLACK,
        fill: Color | None = None,
        width: float = 1.0,
    ) -> None:
        fill_cmd = ""
        paint = "S"
        if fill is not None:
            fill_cmd = f" {rgb(fill)} rg"
            paint = "B"
        self.ops.append(
            f"q {rgb(stroke)} RG{fill_cmd} {width:.3f} w "
            f"{x:.2f} {y:.2f} {w:.2f} {h:.2f} re {paint} Q"
        )

    def text(
        self,
        x: float,
        y: float,
        text: str,
        size: float = 9.0,
        color: Color = BLACK,
        align: str = "left",
    ) -> None:
        est_width = 0.52 * size * len(text)
        if align == "center":
            x -= est_width / 2
        elif align == "right":
            x -= est_width
        self.ops.append(
            f"q {rgb(color)} rg BT /F1 {size:.2f} Tf "
            f"1 0 0 1 {x:.2f} {y:.2f} Tm ({esc(text)}) Tj ET Q"
        )

    def arrow(self, x1: float, y1: float, x2: float, y2: float, color: Color = BLACK) -> None:
        self.line(x1, y1, x2, y2, color=color, width=1.45)
        head = 6.5
        self.polyline([(x1 + head, y1 + 4.0), (x1, y1), (x1 + head, y1 - 4.0)], color, 1.45)
        self.polyline([(x2 - head, y2 + 4.0), (x2, y2), (x2 - head, y2 - 4.0)], color, 1.45)


def draw_digital(canvas: Canvas, y: float, transitions: list[tuple[float, int]], color: Color, lw: float = 2.5) -> None:
    low = y
    high = y + 17.0
    pts: list[tuple[float, float]] = []
    current = transitions[0][1]
    pts.append((ps_to_x(transitions[0][0]), high if current else low))
    for t_ps, value in transitions[1:]:
        x = ps_to_x(t_ps)
        pts.append((x, high if current else low))
        if value != current:
            pts.append((x, high if value else low))
            current = value
    canvas.polyline(pts, color=color, width=lw)


def draw_pulse(canvas: Canvas, y: float, t0: float, width_ps: float, color: Color, lw: float = 2.5) -> None:
    draw_digital(
        canvas,
        y,
        [(0.0, 0), (t0, 0), (t0, 1), (t0 + width_ps, 1), (t0 + width_ps, 0), (T_END, 0)],
        color,
        lw,
    )


def draw_bus(
    canvas: Canvas,
    y: float,
    segments: list[tuple[float, float, str]],
    hatch: tuple[float, float] | None = None,
) -> None:
    h = 23.0
    if hatch is not None:
        x0 = ps_to_x(hatch[0])
        x1 = ps_to_x(hatch[1])
        canvas.rect(x0, y - h / 2, x1 - x0, h, stroke=LIGHT_GRAY, fill=EMPTY_FILL, width=1.25)
        step = 8.5
        x = x0 - h
        while x < x1:
            canvas.line(max(x, x0), y - h / 2, min(x + h, x1), y + h / 2, color=LIGHT_GRAY, width=0.85)
            x += step
    for start, end, label in segments:
        x0 = ps_to_x(start)
        x1 = ps_to_x(end)
        canvas.rect(x0, y - h / 2, x1 - x0, h, stroke=BUS_STROKE, fill=BUS_FILL, width=1.45)
        canvas.text((x0 + x1) / 2, y - 5.0, label, size=15.0, color=BLACK, align="center")


def add_event_line(
    canvas: Canvas,
    x_ps: float,
    y_top: float,
    y_bottom: float,
    color: Color,
    width: float = 0.7,
    dash: str = "3 3",
) -> None:
    canvas.line(ps_to_x(x_ps), y_bottom, ps_to_x(x_ps), y_top, color=color, width=width, dash=dash)


def draw_phase_index(canvas: Canvas, y: float, events: list[tuple[float, int]], color: Color) -> None:
    h = 19.0
    for t_ps, idx in events:
        start = max(0.0, t_ps - 11.0)
        end = min(T_END, t_ps + 21.0)
        x0 = ps_to_x(start)
        x1 = ps_to_x(end)
        canvas.rect(x0, y - h / 2, x1 - x0, h, stroke=color, fill=(0.99, 0.99, 0.99), width=1.20)
        canvas.text((x0 + x1) / 2, y - 5.0, str(idx), size=13.5, color=color, align="center")


def text_box(
    canvas: Canvas,
    x: float,
    y: float,
    text: str,
    size: float = 14.0,
    color: Color = GREEN,
    fill: Color = WHITE,
    align: str = "center",
) -> None:
    text_width = 0.52 * size * len(text)
    if align == "center":
        x0 = x - text_width / 2
    elif align == "right":
        x0 = x - text_width
    else:
        x0 = x
    canvas.rect(x0 - 6.0, y - 4.0, text_width + 12.0, size + 8.0, stroke=fill, fill=fill, width=0.10)
    canvas.text(x, y, text, size=size, color=color, align=align)


def draw_pair(
    canvas: Canvas,
    slow_t: float,
    fast_t: float,
    slow_row: str,
    fast_row: str,
    label: str,
    label_x_ps: float,
    label_y: float,
    label_align: str = "center",
) -> None:
    pd_y = Y["Couples / PD"]
    event_bottom = pd_y + 24.0
    add_event_line(canvas, slow_t, Y[slow_row] + 20.0, event_bottom, GREEN, 1.05)
    add_event_line(canvas, fast_t, Y[fast_row] + 20.0, event_bottom, GREEN, 1.05)
    canvas.line(ps_to_x(slow_t), pd_y + 10.0, ps_to_x(fast_t), pd_y + 10.0, GREEN, 1.20)
    draw_pulse(canvas, pd_y, fast_t - 3.0, 11.0, GREEN, 2.65)
    text_box(canvas, ps_to_x(label_x_ps), label_y, label, size=15.0, color=GREEN, align=label_align)


def build() -> Canvas:
    c = Canvas(PAGE_W, PAGE_H, [])
    c.ops.append("1 J 1 j")

    for label, y in ROWS:
        c.text(LEFT - 14.0, y - 5.0, label, size=18.0, color=BLACK, align="right")
        c.line(LEFT, y, RIGHT, y, color=LIGHT_GRAY, width=0.70)

    # START/STOP and phase pulses.
    draw_pulse(c, Y["Départ / START"], 0.0, 18.0, BLACK, 2.30)
    draw_pulse(c, Y["Arrêt / STOP"], 70.0, 18.0, BLACK, 2.30)

    slow_events = [(0.0, 1), (55.0, 2), (110.0, 3), (165.0, 4), (220.0, 5)]
    fast_events = [(70.0, 1), (120.0, 2), (170.0, 3), (220.0, 4), (270.0, 5)]
    for t_ps, idx in slow_events:
        draw_pulse(c, Y[f"S_{idx}"], t_ps, 20.0, RED, 2.65)
    for t_ps, idx in fast_events:
        draw_pulse(c, Y[f"F_{idx}"], t_ps, 20.0, BLUE, 2.65)

    # Coarse counters and phase indices.
    draw_bus(c, Y["N_slow"], [(0.0, 275.0, "0"), (275.0, 340.0, "1")])
    draw_phase_index(c, Y["n_s"], slow_events, RED)
    draw_bus(c, Y["N_fast"], [(70.0, 320.0, "0"), (320.0, 340.0, "1")], hatch=(0.0, 70.0))
    draw_phase_index(c, Y["n_f"], fast_events, BLUE)

    # Timing interval between START and STOP.
    y_arrow = 740.0
    c.arrow(ps_to_x(0.0), y_arrow, ps_to_x(70.0), y_arrow, color=BLACK)
    c.text((ps_to_x(0.0) + ps_to_x(70.0)) / 2 + 22.0, y_arrow - 26.0, "T_hit = 70 ps", size=15.0, color=BLACK, align="center")

    # Observed phase pairs and first useful coincidence.
    draw_pair(c, 110.0, 120.0, "S_3", "F_2", "(S_3,F_2)", label_x_ps=98.0, label_y=126.0)
    draw_pair(c, 165.0, 170.0, "S_4", "F_3", "(S_4,F_3)", label_x_ps=152.0, label_y=126.0)

    pd_y = Y["Couples / PD"]
    add_event_line(c, 220.0, Y["S_5"] + 20.0, pd_y + 16.0, GREEN, 1.80, "4 2")
    add_event_line(c, 220.0, Y["F_4"] + 20.0, pd_y + 16.0, GREEN, 1.80, "4 2")
    draw_pulse(c, pd_y, 217.0, 12.0, GREEN, 2.90)
    x_coinc = ps_to_x(224.0)
    c.rect(x_coinc + 10.0, 116.0, 145.0, 38.0, stroke=GREEN, fill=GREEN_LIGHT, width=1.30)
    c.text(x_coinc + 82.5, 138.0, "coïncidence utile", size=13.5, color=GREEN, align="center")
    c.text(x_coinc + 82.5, 122.0, "(S_5,F_4)", size=14.5, color=GREEN, align="center")

    return c


def write_pdf(canvas: Canvas, path: Path) -> None:
    content = "\n".join(canvas.ops).encode("cp1252")
    objects = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        (
            f"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 {canvas.width:.0f} {canvas.height:.0f}] "
            f"/Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>"
        ).encode("ascii"),
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>",
        b"<< /Length " + str(len(content)).encode("ascii") + b" >>\nstream\n" + content + b"\nendstream",
    ]

    out = bytearray()
    out.extend(b"%PDF-1.4\n%\xe2\xe3\xcf\xd3\n")
    offsets = [0]
    for idx, obj in enumerate(objects, start=1):
        offsets.append(len(out))
        out.extend(f"{idx} 0 obj\n".encode("ascii"))
        out.extend(obj)
        out.extend(b"\nendobj\n")
    xref_pos = len(out)
    out.extend(f"xref\n0 {len(objects) + 1}\n".encode("ascii"))
    out.extend(b"0000000000 65535 f \n")
    for off in offsets[1:]:
        out.extend(f"{off:010d} 00000 n \n".encode("ascii"))
    out.extend(
        (
            f"trailer\n<< /Size {len(objects) + 1} /Root 1 0 R >>\n"
            f"startxref\n{xref_pos}\n%%EOF\n"
        ).encode("ascii")
    )
    path.write_bytes(out)


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    out_dir = root / "figures" / "generated"
    out_dir.mkdir(parents=True, exist_ok=True)
    output = out_dir / "vernier_multiphase_chronogram.pdf"
    write_pdf(build(), output)
    print(output)


if __name__ == "__main__":
    main()
