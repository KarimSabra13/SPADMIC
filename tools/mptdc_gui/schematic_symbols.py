#!/usr/bin/env python3
"""Reusable SVG symbols for the MPTDC presentation GUI.

The functions in this module return SVG fragments. They deliberately stay
dependency-free so the diagram generator can run with the Python standard
library only.
"""

from __future__ import annotations

import html
from typing import Any, Iterable


PALETTE = {
    "bg": "#f7f8fb",
    "ink": "#1d2430",
    "muted": "#64748b",
    "line": "#94a3b8",
    "soft": "#eef3f8",
    "panel": "#ffffff",
    "async": "#be5d00",
    "clock": "#2563eb",
    "data": "#0f766e",
    "control": "#7c3aed",
    "reset": "#64748b",
    "warning": "#b91c1c",
    "domain_async": "#fff7ed",
    "domain_clock": "#eff6ff",
    "domain_data": "#ecfdf5",
    "domain_control": "#f5f3ff",
    "domain_reset": "#f1f5f9",
}


def esc(value: Any) -> str:
    return html.escape(str(value), quote=True)


def css() -> str:
    return """
    .domain-label{font:700 15px Inter,Segoe UI,Arial,sans-serif;fill:#1d2430}
    .caption{font:12px Inter,Segoe UI,Arial,sans-serif;fill:#64748b}
    .pin{font:10.5px Inter,Segoe UI,Arial,sans-serif;fill:#334155}
    .symbol-title{font:700 13px Inter,Segoe UI,Arial,sans-serif;fill:#1d2430}
    .symbol-sub{font:11px Inter,Segoe UI,Arial,sans-serif;fill:#64748b}
    .block{cursor:pointer}
    .block:hover .symbol-body{stroke-width:2.4}
    .active .symbol-body{stroke:#0f766e;stroke-width:2.6}
    .active-signal{stroke-width:4.5;filter:url(#glow)}
    .state-dot{fill:#ffffff;stroke:#7c3aed;stroke-width:1.4}
    .bitlabel{font:10px Inter,Segoe UI,Arial,sans-serif;fill:#334155}
    .fieldlabel{font:700 11px Inter,Segoe UI,Arial,sans-serif;fill:#1d2430}
    """


def svg_header(width: int, height: int, title: str = "") -> str:
    label = f"<title>{esc(title)}</title>" if title else ""
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" '
        f'width="{width}" height="{height}" role="img">'
        f"{label}"
        "<defs>"
        "<marker id='arrow-data' viewBox='0 0 10 10' refX='9' refY='5' markerWidth='8' markerHeight='8' orient='auto-start-reverse'>"
        f"<path d='M0,0 L10,5 L0,10 z' fill='{PALETTE['data']}'/></marker>"
        "<marker id='arrow-control' viewBox='0 0 10 10' refX='9' refY='5' markerWidth='8' markerHeight='8' orient='auto-start-reverse'>"
        f"<path d='M0,0 L10,5 L0,10 z' fill='{PALETTE['control']}'/></marker>"
        "<marker id='arrow-clock' viewBox='0 0 10 10' refX='9' refY='5' markerWidth='8' markerHeight='8' orient='auto-start-reverse'>"
        f"<path d='M0,0 L10,5 L0,10 z' fill='{PALETTE['clock']}'/></marker>"
        "<marker id='arrow-async' viewBox='0 0 10 10' refX='9' refY='5' markerWidth='8' markerHeight='8' orient='auto-start-reverse'>"
        f"<path d='M0,0 L10,5 L0,10 z' fill='{PALETTE['async']}'/></marker>"
        "<marker id='arrow-reset' viewBox='0 0 10 10' refX='9' refY='5' markerWidth='8' markerHeight='8' orient='auto-start-reverse'>"
        f"<path d='M0,0 L10,5 L0,10 z' fill='{PALETTE['reset']}'/></marker>"
        "<filter id='glow' x='-20%' y='-20%' width='140%' height='140%'>"
        "<feGaussianBlur stdDeviation='2.2' result='blur'/><feMerge><feMergeNode in='blur'/><feMergeNode in='SourceGraphic'/></feMerge>"
        "</filter>"
        "<filter id='shadow' x='-15%' y='-15%' width='130%' height='145%'>"
        "<feDropShadow dx='0' dy='3' stdDeviation='3' flood-opacity='0.13'/>"
        "</filter>"
        f"<style>{css()}</style>"
        "</defs>"
        f"<rect width='100%' height='100%' fill='{PALETTE['bg']}'/>"
    )


def svg_footer() -> str:
    return "</svg>\n"


def label(x: float, y: float, text: str, cls: str = "caption", anchor: str = "start") -> str:
    return f"<text x='{x}' y='{y}' class='{cls}' text-anchor='{anchor}'>{esc(text)}</text>"


def group_open(module_id: str, title: str, extra_class: str = "") -> str:
    cls = "block" + (f" {extra_class}" if extra_class else "")
    return f"<g class='{cls}' data-module='{esc(module_id)}' data-title='{esc(title)}'>"


def group_close() -> str:
    return "</g>"


def domain_lane(x: int, y: int, w: int, h: int, title: str, fill: str) -> str:
    domain = (
        title.lower()
        .replace("é", "e")
        .replace("è", "e")
        .replace("ê", "e")
        .replace("à", "a")
        .replace("ç", "c")
    )
    domain = "-".join(part for part in domain.replace("/", " ").replace("_", " ").split() if part)
    return "\n".join(
        [
            f"<rect class='domain-lane' data-domain='{esc(domain)}' x='{x}' y='{y}' width='{w}' height='{h}' rx='12' fill='{fill}' stroke='#d8dee8' stroke-width='1'/>",
            label(x + 14, y + 24, title, "domain-label"),
        ]
    )


def port_pin(x: float, y: float, text: str, side: str = "left", color: str = "#64748b") -> str:
    if side == "left":
        return (
            f"<line x1='{x}' y1='{y}' x2='{x + 12}' y2='{y}' stroke='{color}' stroke-width='1.4'/>"
            f"<circle cx='{x + 12}' cy='{y}' r='2.8' fill='#fff' stroke='{color}'/>"
            f"<text x='{x - 4}' y='{y + 3.5}' class='pin' text-anchor='end'>{esc(text)}</text>"
        )
    if side == "right":
        return (
            f"<line x1='{x - 12}' y1='{y}' x2='{x}' y2='{y}' stroke='{color}' stroke-width='1.4'/>"
            f"<circle cx='{x - 12}' cy='{y}' r='2.8' fill='#fff' stroke='{color}'/>"
            f"<text x='{x + 4}' y='{y + 3.5}' class='pin'>{esc(text)}</text>"
        )
    if side == "top":
        return (
            f"<line x1='{x}' y1='{y}' x2='{x}' y2='{y + 12}' stroke='{color}' stroke-width='1.4'/>"
            f"<circle cx='{x}' cy='{y + 12}' r='2.8' fill='#fff' stroke='{color}'/>"
            f"<text x='{x}' y='{y - 4}' class='pin' text-anchor='middle'>{esc(text)}</text>"
        )
    return (
        f"<line x1='{x}' y1='{y - 12}' x2='{x}' y2='{y}' stroke='{color}' stroke-width='1.4'/>"
        f"<circle cx='{x}' cy='{y - 12}' r='2.8' fill='#fff' stroke='{color}'/>"
        f"<text x='{x}' y='{y + 13}' class='pin' text-anchor='middle'>{esc(text)}</text>"
    )


def _polyline(points: Iterable[tuple[float, float]]) -> str:
    return " ".join(f"{x},{y}" for x, y in points)


def bus_arrow(
    x1: float,
    y1: float,
    x2: float,
    y2: float,
    label_text: str = "",
    color: str = "#0f766e",
    marker: str = "arrow-data",
    width: float = 3.0,
    dashed: bool = False,
    signal_id: str = "",
) -> str:
    dash = " stroke-dasharray='8 6'" if dashed else ""
    data_attr = f" data-signal='{esc(signal_id)}'" if signal_id else ""
    mid_x = (x1 + x2) / 2
    mid_y = (y1 + y2) / 2
    out = [
        f"<line class='signal-wire'{data_attr} x1='{x1}' y1='{y1}' x2='{x2}' y2='{y2}' stroke='{color}' "
        f"stroke-width='{width}' stroke-linecap='round' marker-end='url(#{marker})'{dash}/>"
    ]
    if label_text:
        out.append(label(mid_x, mid_y - 7, label_text, "caption", "middle"))
    return "\n".join(out)


def data_arrow(*args: Any, **kwargs: Any) -> str:
    kwargs.setdefault("color", PALETTE["data"])
    kwargs.setdefault("marker", "arrow-data")
    kwargs.setdefault("width", 3.2)
    return bus_arrow(*args, **kwargs)


def control_arrow(*args: Any, **kwargs: Any) -> str:
    kwargs.setdefault("color", PALETTE["control"])
    kwargs.setdefault("marker", "arrow-control")
    kwargs.setdefault("width", 2.4)
    return bus_arrow(*args, **kwargs)


def clock_arrow(*args: Any, **kwargs: Any) -> str:
    kwargs.setdefault("color", PALETTE["clock"])
    kwargs.setdefault("marker", "arrow-clock")
    kwargs.setdefault("width", 2.6)
    return bus_arrow(*args, **kwargs)


def async_arrow(*args: Any, **kwargs: Any) -> str:
    kwargs.setdefault("color", PALETTE["async"])
    kwargs.setdefault("marker", "arrow-async")
    kwargs.setdefault("width", 2.4)
    kwargs.setdefault("dashed", True)
    return bus_arrow(*args, **kwargs)


def reset_arrow(*args: Any, **kwargs: Any) -> str:
    kwargs.setdefault("color", PALETTE["reset"])
    kwargs.setdefault("marker", "arrow-reset")
    kwargs.setdefault("width", 2.0)
    return bus_arrow(*args, **kwargs)


def warning_marker(x: float, y: float, text: str = "") -> str:
    points = _polyline([(x, y - 12), (x - 13, y + 12), (x + 13, y + 12)])
    return "\n".join(
        [
            f"<polygon points='{points}' fill='#fff1f2' stroke='{PALETTE['warning']}' stroke-width='1.6'/>",
            f"<text x='{x}' y='{y + 8}' text-anchor='middle' font-family='Inter,Segoe UI,Arial' font-weight='800' font-size='18' fill='{PALETTE['warning']}'>!</text>",
            label(x + 18, y + 5, text, "caption") if text else "",
        ]
    )


def mux_symbol(
    x: int,
    y: int,
    w: int,
    h: int,
    module_id: str,
    title: str,
    inputs: list[str],
    outputs: list[str],
    select: str,
) -> str:
    body = _polyline([(x + 18, y), (x + w - 8, y + h * 0.18), (x + w - 8, y + h * 0.82), (x + 18, y + h)])
    lines = [group_open(module_id, title), f"<polygon class='symbol-body' points='{body}' fill='#fff7ed' stroke='{PALETTE['async']}' stroke-width='1.8' filter='url(#shadow)'/>"]
    lines.append(label(x + w * 0.5, y + h * 0.45, title, "symbol-title", "middle"))
    lines.append(label(x + w * 0.5, y + h * 0.63, "MUX", "symbol-sub", "middle"))
    for idx, name in enumerate(inputs[:4]):
        lines.append(port_pin(x, y + 18 + idx * 18, name, "left", PALETTE["async"]))
    for idx, name in enumerate(outputs[:2]):
        lines.append(port_pin(x + w, y + h * 0.42 + idx * 18, name, "right", PALETTE["async"]))
    lines.append(port_pin(x + w * 0.55, y + h + 16, select, "bottom", PALETTE["control"]))
    lines.append(group_close())
    return "\n".join(lines)


def register_bank_symbol(
    x: int,
    y: int,
    w: int,
    h: int,
    module_id: str,
    title: str,
    subtitle: str,
    pins_left: list[str] | None = None,
    pins_right: list[str] | None = None,
) -> str:
    lines = [group_open(module_id, title)]
    lines.append(f"<rect class='symbol-body' x='{x}' y='{y}' width='{w}' height='{h}' rx='7' fill='#ffffff' stroke='{PALETTE['reset']}' stroke-width='1.7' filter='url(#shadow)'/>")
    for row in range(3):
        for col in range(4):
            cx = x + 16 + col * 20
            cy = y + 36 + row * 18
            lines.append(f"<rect x='{cx}' y='{cy}' width='13' height='11' fill='#eef3f8' stroke='#cbd5e1'/>")
    lines.append(label(x + w - 12, y + 24, title, "symbol-title", "end"))
    lines.append(label(x + w - 12, y + 43, subtitle, "symbol-sub", "end"))
    for idx, name in enumerate((pins_left or [])[:4]):
        lines.append(port_pin(x, y + 26 + idx * 18, name, "left", PALETTE["control"]))
    for idx, name in enumerate((pins_right or [])[:4]):
        lines.append(port_pin(x + w, y + 26 + idx * 18, name, "right", PALETTE["data"]))
    lines.append(group_close())
    return "\n".join(lines)


def fsm_symbol(
    x: int,
    y: int,
    w: int,
    h: int,
    module_id: str,
    title: str,
    states: list[str],
    pins_left: list[str] | None = None,
    pins_right: list[str] | None = None,
) -> str:
    lines = [group_open(module_id, title)]
    lines.append(f"<rect class='symbol-body' x='{x}' y='{y}' width='{w}' height='{h}' rx='8' fill='#ffffff' stroke='{PALETTE['control']}' stroke-width='1.7' filter='url(#shadow)'/>")
    lines.append(label(x + 12, y + 23, title, "symbol-title"))
    cx0 = x + 42
    cy = y + h * 0.58
    shown = states[:5] if states else ["IDLE", "RUN"]
    for idx, state in enumerate(shown):
        cx = cx0 + idx * 38
        lines.append(f"<circle cx='{cx}' cy='{cy}' r='13' class='state-dot'/>")
        lines.append(label(cx, cy + 4, state.replace('ST_M_', '').replace('S_', '')[:5], "bitlabel", "middle"))
        if idx < len(shown) - 1:
            lines.append(control_arrow(cx + 14, cy, cx + 24, cy, ""))
    for idx, name in enumerate((pins_left or [])[:3]):
        lines.append(port_pin(x, y + 36 + idx * 18, name, "left", PALETTE["control"]))
    for idx, name in enumerate((pins_right or [])[:3]):
        lines.append(port_pin(x + w, y + 36 + idx * 18, name, "right", PALETTE["control"]))
    lines.append(group_close())
    return "\n".join(lines)


def ring_oscillator_symbol(
    x: int,
    y: int,
    w: int,
    h: int,
    module_id: str,
    title: str,
    phase_label: str,
    flavor: str = "lent",
) -> str:
    color = PALETTE["clock"] if flavor == "rapide" else "#1d4ed8"
    lines = [group_open(module_id, title, f"osc-{flavor}")]
    lines.append(f"<rect class='symbol-body' x='{x}' y='{y}' width='{w}' height='{h}' rx='8' fill='#eff6ff' stroke='{color}' stroke-width='1.7' filter='url(#shadow)'/>")
    lines.append(label(x + 12, y + 22, title, "symbol-title"))
    center_x = x + w * 0.52
    center_y = y + h * 0.55
    rx = w * 0.25
    ry = h * 0.23
    lines.append(f"<ellipse cx='{center_x}' cy='{center_y}' rx='{rx}' ry='{ry}' fill='none' stroke='{color}' stroke-width='2'/>")
    for idx, angle in enumerate([0, 60, 120, 180, 240, 300]):
        px = center_x + rx * 0.86 * __import__('math').cos(__import__('math').radians(angle))
        py = center_y + ry * 0.86 * __import__('math').sin(__import__('math').radians(angle))
        tri = _polyline([(px - 6, py - 6), (px - 6, py + 6), (px + 7, py)])
        lines.append(f"<polygon points='{tri}' fill='#ffffff' stroke='{color}' stroke-width='1.2'/>")
        if idx % 2 == 0:
            lines.append(f"<circle cx='{px + 9}' cy='{py}' r='2.5' fill='#ffffff' stroke='{color}'/>")
    lines.append(port_pin(x, y + h * 0.55, "osc_en", "left", PALETTE["control"]))
    lines.append(port_pin(x + w, y + h * 0.55, phase_label, "right", PALETTE["clock"]))
    lines.append(group_close())
    return "\n".join(lines)


def pd_matrix_symbol(
    x: int,
    y: int,
    w: int,
    h: int,
    module_id: str,
    title: str = "Matrice PD 8x8",
    example_hit: tuple[int, int] | None = (3, 5),
) -> str:
    lines = [group_open(module_id, title)]
    lines.append(f"<rect class='symbol-body' x='{x}' y='{y}' width='{w}' height='{h}' rx='8' fill='#ffffff' stroke='{PALETTE['data']}' stroke-width='1.7' filter='url(#shadow)'/>")
    lines.append(label(x + 12, y + 23, title, "symbol-title"))
    grid_x = x + 42
    grid_y = y + 48
    cell = min((w - 92) / 8, (h - 82) / 8)
    for ns in range(8):
        lines.append(label(grid_x - 10, grid_y + ns * cell + cell * 0.62, f"s{ns}", "bitlabel", "end"))
        for nf in range(8):
            fill = "#dcfce7" if example_hit == (ns, nf) else "#f8fafc"
            stroke = PALETTE["data"] if example_hit == (ns, nf) else "#cbd5e1"
            lines.append(
                f"<rect x='{grid_x + nf * cell}' y='{grid_y + ns * cell}' width='{cell - 2}' height='{cell - 2}' "
                f"fill='{fill}' stroke='{stroke}' stroke-width='1'/>"
            )
    for nf in range(8):
        lines.append(label(grid_x + nf * cell + cell * 0.4, grid_y - 8, f"f{nf}", "bitlabel", "middle"))
    lines.append(label(grid_x + cell * 4, y + h - 18, "64 cellules PD - CELL = ns * NE + nf", "symbol-sub", "middle"))
    lines.append(port_pin(x, grid_y + cell * 4, "slow_phase[7:0]", "left", PALETTE["clock"]))
    lines.append(port_pin(x + w * 0.52, y, "fast_phase[7:0]", "top", PALETTE["clock"]))
    lines.append(port_pin(x + w, grid_y + cell * 3.1, "pd_hit_level[63:0]", "right", PALETTE["data"]))
    lines.append(port_pin(x + w, grid_y + cell * 4.4, "pd_nfast_hit_packed", "right", PALETTE["data"]))
    lines.append(group_close())
    return "\n".join(lines)


def gray_counter_symbol(x: int, y: int, w: int, h: int, module_id: str, title: str) -> str:
    lines = [group_open(module_id, title)]
    lines.append(f"<rect class='symbol-body' x='{x}' y='{y}' width='{w}' height='{h}' rx='8' fill='#ffffff' stroke='{PALETTE['clock']}' stroke-width='1.7' filter='url(#shadow)'/>")
    lines.append(label(x + 12, y + 23, title, "symbol-title"))
    for idx in range(6):
        bx = x + 22 + idx * 22
        lines.append(f"<rect x='{bx}' y='{y + 46}' width='16' height='28' fill='#eff6ff' stroke='{PALETTE['clock']}'/>")
        lines.append(label(bx + 8, y + 64, str(idx), "bitlabel", "middle"))
    lines.append(label(x + w * 0.5, y + h - 16, "Compteur Gray + snapshot CDC", "symbol-sub", "middle"))
    lines.append(port_pin(x, y + 58, "phase[0]", "left", PALETTE["clock"]))
    lines.append(port_pin(x + w, y + 58, "count snapshot", "right", PALETTE["data"]))
    lines.append(group_close())
    return "\n".join(lines)


def cdc_sync_symbol(
    x: int,
    y: int,
    w: int,
    h: int,
    module_id: str,
    title: str,
    stages: int = 2,
    warning: bool = False,
) -> str:
    lines = [group_open(module_id, title)]
    lines.append(f"<rect class='symbol-body' x='{x}' y='{y}' width='{w}' height='{h}' rx='8' fill='#ffffff' stroke='{PALETTE['reset']}' stroke-width='1.7' filter='url(#shadow)'/>")
    lines.append(label(x + 12, y + 23, title, "symbol-title"))
    start_x = x + 36
    for idx in range(stages):
        rx = start_x + idx * 38
        lines.append(f"<rect x='{rx}' y='{y + 44}' width='26' height='36' fill='#f8fafc' stroke='{PALETTE['reset']}'/>")
        lines.append(label(rx + 13, y + 66, "D", "fieldlabel", "middle"))
        if idx < stages - 1:
            lines.append(reset_arrow(rx + 27, y + 62, rx + 37, y + 62, ""))
    lines.append(port_pin(x, y + 62, "source", "left", PALETTE["async"]))
    lines.append(port_pin(x + w, y + 62, "destination", "right", PALETTE["data"]))
    if warning:
        lines.append(warning_marker(x + w - 20, y + 24))
    lines.append(group_close())
    return "\n".join(lines)


def fifo_symbol(x: int, y: int, w: int, h: int, module_id: str, title: str) -> str:
    lines = [group_open(module_id, title)]
    lines.append(f"<rect class='symbol-body' x='{x}' y='{y}' width='{w}' height='{h}' rx='8' fill='#ffffff' stroke='{PALETTE['data']}' stroke-width='1.7' filter='url(#shadow)'/>")
    lines.append(label(x + 12, y + 23, title, "symbol-title"))
    mem_x = x + 42
    mem_y = y + 38
    for idx in range(5):
        lines.append(f"<rect x='{mem_x}' y='{mem_y + idx * 14}' width='{w - 84}' height='12' fill='#ecfdf5' stroke='#99f6e4'/>")
    for idx, pin in enumerate(["wr_en", "rd_en"]):
        lines.append(port_pin(x, y + 45 + idx * 22, pin, "left", PALETTE["control"]))
    for idx, pin in enumerate(["full", "empty", "valid"]):
        lines.append(port_pin(x + w, y + 38 + idx * 18, pin, "right", PALETTE["data"]))
    lines.append(group_close())
    return "\n".join(lines)


def serializer_symbol(x: int, y: int, w: int, h: int, module_id: str, title: str) -> str:
    lines = [group_open(module_id, title)]
    lines.append(f"<rect class='symbol-body' x='{x}' y='{y}' width='{w}' height='{h}' rx='8' fill='#ffffff' stroke='{PALETTE['data']}' stroke-width='1.7' filter='url(#shadow)'/>")
    lines.append(label(x + 12, y + 23, title, "symbol-title"))
    sx = x + 24
    sy = y + 48
    for idx in range(8):
        lines.append(f"<rect x='{sx + idx * 18}' y='{sy}' width='15' height='24' fill='#ecfdf5' stroke='{PALETTE['data']}'/>")
    lines.append(data_arrow(sx + 8, sy + 36, sx + 8 + 18 * 7, sy + 36, "décalage 16-bit"))
    lines.append(port_pin(x, y + 62, "fifo_rd_data", "left", PALETTE["data"]))
    lines.append(port_pin(x + w, y + 55, "narrow_valid_o", "right", PALETTE["data"]))
    lines.append(port_pin(x + w, y + 75, "narrow_data_o", "right", PALETTE["data"]))
    lines.append(group_close())
    return "\n".join(lines)


def packet_adapter_symbol(x: int, y: int, w: int, h: int, module_id: str, title: str) -> str:
    lines = [group_open(module_id, title)]
    lines.append(f"<rect class='symbol-body' x='{x}' y='{y}' width='{w}' height='{h}' rx='8' fill='#ffffff' stroke='{PALETTE['data']}' stroke-width='1.7' filter='url(#shadow)'/>")
    lines.append(label(x + 12, y + 23, title, "symbol-title"))
    fields = [("META", "#dbeafe"), ("HIT", "#dcfce7"), ("EOC", "#fef3c7")]
    fx = x + 22
    for idx, (name, fill) in enumerate(fields):
        lines.append(f"<rect x='{fx + idx * 58}' y='{y + 46}' width='48' height='30' fill='{fill}' stroke='#94a3b8'/>")
        lines.append(label(fx + idx * 58 + 24, y + 65, name, "fieldlabel", "middle"))
    lines.append(port_pin(x, y + 62, "acq_*", "left", PALETTE["data"]))
    lines.append(port_pin(x + w, y + 62, "TX paquet", "right", PALETTE["data"]))
    lines.append(group_close())
    return "\n".join(lines)


def bit_field(x: int, y: int, w: int, h: int, name: str, bits: str, fill: str) -> str:
    return "\n".join(
        [
            f"<rect x='{x}' y='{y}' width='{w}' height='{h}' fill='{fill}' stroke='#94a3b8'/>",
            label(x + w / 2, y + 18, name, "fieldlabel", "middle"),
            label(x + w / 2, y + h - 7, bits, "bitlabel", "middle"),
        ]
    )
