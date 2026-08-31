#!/usr/bin/env python3
"""
Generate a professional A4 SPADMIC schematic pack using Graphviz.

Outputs:
  - TOP/docs/diagrams/spadmic_visual_pack_a4.pdf
  - TOP/docs/diagrams/svg/*.svg
  - TOP/docs/diagrams/pdf/*.pdf
  - TOP/docs/diagrams/dot/*.dot
"""

from __future__ import annotations

import argparse
import html
import subprocess
from dataclasses import dataclass
from pathlib import Path

try:
    from pypdf import PdfReader, PdfWriter
except ModuleNotFoundError:
    from PyPDF2 import PdfReader, PdfWriter


COLORS = {
    "ink": "#0F172A",
    "muted": "#475569",
    "line": "#CBD5E1",
    "control": "#2563EB",
    "control_fill": "#EFF6FF",
    "tdc": "#7C3AED",
    "tdc_fill": "#F5F3FF",
    "position": "#059669",
    "position_fill": "#ECFDF5",
    "egress": "#EA580C",
    "egress_fill": "#FFF7ED",
    "clock": "#334155",
    "clock_fill": "#F8FAFC",
    "io": "#B45309",
    "io_fill": "#FFFBEB",
    "note": "#CA8A04",
    "note_fill": "#FEF3C7",
    "macro": "#0B0F14",
    "macro_fill": "#0B0F14",
    "cluster": "#1E293B",
}

THEMES = {
    "control": (COLORS["control"], COLORS["control_fill"]),
    "tdc": (COLORS["tdc"], COLORS["tdc_fill"]),
    "position": (COLORS["position"], COLORS["position_fill"]),
    "egress": (COLORS["egress"], COLORS["egress_fill"]),
    "clock": (COLORS["clock"], COLORS["clock_fill"]),
    "io": (COLORS["io"], COLORS["io_fill"]),
    "note": (COLORS["note"], COLORS["note_fill"]),
    "neutral": (COLORS["cluster"], "#FFFFFF"),
}


@dataclass(frozen=True)
class Page:
    stem: str
    title: str
    subtitle: str
    source_ref: str
    body: str


def esc(text: str) -> str:
    return html.escape(text, quote=False)


def br(lines: list[str]) -> str:
    return "<BR ALIGN='LEFT'/>".join(esc(line) for line in lines if line)


def page_header(title: str, subtitle: str, source_ref: str) -> str:
    return f"""
    <TABLE BORDER="0" CELLBORDER="0" CELLSPACING="0" CELLPADDING="0">
      <TR><TD ALIGN="LEFT"><FONT POINT-SIZE="28"><B>{esc(title)}</B></FONT></TD></TR>
      <TR><TD HEIGHT="4"></TD></TR>
      <TR><TD ALIGN="LEFT"><FONT POINT-SIZE="12">{esc(subtitle)}</FONT></TD></TR>
      <TR><TD HEIGHT="2"></TD></TR>
      <TR><TD ALIGN="LEFT"><FONT POINT-SIZE="10" COLOR="{COLORS["muted"]}">{esc(source_ref)}</FONT></TD></TR>
    </TABLE>
    """


def block_label(
    title: str,
    *,
    subtitle: str | None = None,
    lines: list[str] | None = None,
    theme: str = "neutral",
    mono: bool = False,
) -> str:
    border, fill = THEMES[theme]
    body = ""
    if subtitle:
        body += (
            f"<TR><TD ALIGN='LEFT' BGCOLOR='{fill}'><FONT POINT-SIZE='10' COLOR='{COLORS['muted']}'>{esc(subtitle)}</FONT></TD></TR>"
        )
    if lines:
        face = "DejaVu Sans Mono" if mono else "DejaVu Sans"
        body += (
            f"<TR><TD ALIGN='LEFT' BGCOLOR='{fill}'><FONT FACE='{face}' POINT-SIZE='10'>{br(lines)}</FONT></TD></TR>"
        )
    return f"""
    <TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" CELLPADDING="7" COLOR="{border}" BGCOLOR="{fill}">
      <TR><TD BGCOLOR="{border}" ALIGN="CENTER"><FONT COLOR="white" POINT-SIZE="15"><B>{esc(title)}</B></FONT></TD></TR>
      {body}
    </TABLE>
    """


def block_node(name: str, title: str, *, subtitle: str | None = None, lines: list[str] | None = None, theme: str = "neutral", mono: bool = False) -> str:
    return f'{name} [shape=plain margin=0 label=<{block_label(title, subtitle=subtitle, lines=lines, theme=theme, mono=mono)}>];'


def macro_node(name: str, title: str, lines: list[str], *, width: float = 2.2, height: float = 1.0) -> str:
    label = "\\n".join([title] + lines)
    return (
        f'{name} [shape=box style="rounded,filled,bold" penwidth=2.0 color="{COLORS["macro"]}" '
        f'fillcolor="{COLORS["macro_fill"]}" fontcolor="white" fontname="Helvetica" fontsize=14 '
        f'width={width} height={height} label="{label}"];'
    )


def edge(src: str, dst: str, *, label: str | None = None, color: str = COLORS["cluster"], style: str = "solid", weight: int = 2, extra: str = "") -> str:
    attrs = [f'color="{color}"', f'penwidth=1.6', f'style="{style}"', f'weight={weight}']
    if label:
        attrs.append(f'xlabel="{label}"')
        attrs.append('fontsize=10')
        attrs.append('fontcolor="#334155"')
    if extra:
        attrs.append(extra)
    return f"{src} -> {dst} [{', '.join(attrs)}];"


def invis(src: str, dst: str, *, weight: int = 20) -> str:
    return f'{src} -> {dst} [style="invis" weight={weight}];'


def wrap_graph(page: Page) -> str:
    label = page_header(page.title, page.subtitle, page.source_ref)
    return f"""digraph G {{
      graph [
        rankdir=TB,
        splines=ortho,
        overlap=false,
        newrank=true,
        compound=true,
        nodesep=0.38,
        ranksep=0.68,
        pad=0.18,
        margin=0.08,
        bgcolor="white",
        fontname="Helvetica",
        labelloc=t,
        labeljust=l,
        label=<{label}>,
        size="11.69,8.27!"
      ];
      node [fontname="Helvetica"];
      edge [fontname="Helvetica", arrowsize=0.8];
      {page.body}
    }}"""


def top_page() -> Page:
    body = f"""
    subgraph cluster_chip {{
      label="SPADMIC active matrix-top architecture";
      labeljust=l;
      labelloc=t;
      fontsize=18;
      fontcolor="{COLORS["ink"]}";
      color="{COLORS["cluster"]}";
      penwidth=2.2;
      style="rounded";

      {block_node("clock_reset", "Clock and reset boundary", theme="clock", lines=["clk_sys / clk_ref_40m / clk_cfg_40m", "async_rst_n", "transport-only i2c_rst_i"])}
      {block_node("i2c", "I2C control plane", theme="control", subtitle="7-bit address 0x42, 16-bit pointer, 32-bit data", lines=["slave + one-outstanding bridge", "CSR router + block-owned banks", "fault and counter provenance"])}
      {block_node("analog", "PLL and analog controls", theme="control", lines=["disabled-and-idle writes", "documented active polarity", "PLL lock status"])}

      {macro_node("spad_matrix", "SPAD MATRIX", ["R/Y/B event buses", "Rz/Yz/Bz reset selects", "44-column config/readback"], width=2.6, height=2.2)}
      {block_node("snapshot", "Snapshot + event coordinator", theme="position", lines=["settle/watchdog", "one event ID per physical event", "frozen packet/reset masks"])}
      {block_node("axis_r", "TDC axis R", theme="tdc", subtitle="TOP wrapper around protected mptdc_axis_core", lines=["qualified conversion start", "shared tuning", "packet pending/ready"])}
      {block_node("axis_y", "TDC axis Y", theme="tdc", subtitle="TOP wrapper around protected mptdc_axis_core", lines=["qualified conversion start", "shared tuning", "packet pending/ready"])}
      {block_node("axis_b", "TDC axis B", theme="tdc", subtitle="TOP wrapper around protected mptdc_axis_core", lines=["qualified conversion start", "shared tuning", "packet pending/ready"])}
      {block_node("position", "Position snapshot packetizer", theme="position", lines=["cluster/raw mode", "gap 2 / minimum span 1 reset defaults", "private snapshot before matrix reset"])}

      {block_node("bundle", "Correlated event bundle", theme="egress", lines=["R then Y then B then position", "patch source ID and shared EOC event ID", "packet-completion mask"])}
      {block_node("fifo", "Fixed output FIFO", theme="control", lines=["fixed reserve threshold", "overflow accounting", "ordered flush marker"])}
      {block_node("ddr", "DDR16 pairer", theme="egress", lines=["two logical 16-bit words per transfer", "zero-pad odd final word", "ddr_data_l/h + valid + clock"])}
      {block_node("matrix_cfg", "Matrix configuration controller", theme="control", lines=["44-column serial commands", "64-bit write/readback", "clk_cfg_40m domain"])}

      {{ rank=same; clock_reset; i2c; analog; }}
      {{ rank=same; spad_matrix; snapshot; matrix_cfg; }}
      {{ rank=same; axis_r; axis_y; axis_b; position; }}
      {{ rank=same; bundle; fifo; ddr; }}

      {invis("clock_reset", "i2c")}
      {invis("i2c", "analog")}
      {invis("spad_matrix", "snapshot")}
      {invis("snapshot", "matrix_cfg")}
      {invis("axis_r", "axis_y")}
      {invis("axis_y", "axis_b")}
      {invis("axis_b", "position")}
      {invis("bundle", "fifo")}
      {invis("fifo", "ddr")}

      {edge("clock_reset", "i2c", label="clk/reset domains", color=COLORS["clock"])}
      {edge("clock_reset", "snapshot", color=COLORS["clock"])}
      {edge("clock_reset", "matrix_cfg", color=COLORS["clock"])}
      {edge("i2c", "analog", label="CSR controls", color=COLORS["control"])}
      {edge("i2c", "snapshot", label="mode + event config", color=COLORS["control"])}
      {edge("i2c", "matrix_cfg", label="matrix commands", color=COLORS["control"])}
      {edge("spad_matrix", "snapshot", label="R/Y/B snapshot", color=COLORS["position"])}
      {edge("snapshot", "axis_r", label="event R", color=COLORS["tdc"])}
      {edge("snapshot", "axis_y", label="event Y", color=COLORS["tdc"])}
      {edge("snapshot", "axis_b", label="event B", color=COLORS["tdc"])}
      {edge("snapshot", "position", label="captured R/Y/B", color=COLORS["position"])}
      {edge("axis_r", "bundle", label="R packet", color=COLORS["tdc"])}
      {edge("axis_y", "bundle", label="Y packet", color=COLORS["tdc"])}
      {edge("axis_b", "bundle", label="B packet", color=COLORS["tdc"])}
      {edge("position", "bundle", label="position packet", color=COLORS["position"])}
      {edge("bundle", "fifo", label="16-bit words + flush", color=COLORS["egress"])}
      {edge("fifo", "ddr", label="logical word stream", color=COLORS["egress"])}
      {edge("matrix_cfg", "spad_matrix", label="DIN/CIN and DOUT/COUT", color=COLORS["control"])}
    }}

    {block_node("top_note", "Technical note", theme="note", lines=[
        "The external matrix-top port list is preserved by the CSR ABI 1.0 integration.",
        "MPTDC/rtl/top/mptdc_axis_core.sv remains a protected implementation boundary.",
        "RTL verification does not authorize Genus, Innovus, OA edits, or signoff."
    ])}
    {{ rank=same; top_note; }}
    """
    return Page(
        "01_spadmic_top_floorplan",
        "SPADMIC active matrix-top architecture",
        "Current CSR/I2C, R/Y/B event, correlated packet, matrix configuration, and DDR16 data paths.",
        "TOP/rtl/spadmic_top_matrix_v1.sv + TOP/docs/01_ACTIVE_ARCHITECTURE.md",
        body,
    )


def i2c_slave_page() -> Page:
    body = f"""
    {block_node("in_pins", "Inputs", theme="io", lines=["clk_sys", "rst_n", "i2c_rst_i", "i2c_scl_i", "i2c_sda_i"], mono=True)}
    {block_node("sync", "SCL/SDA synchronizers", theme="clock", lines=["double-sync into clk_sys", "START / STOP decode", "scl_rise / scl_fall timing"])}
    {block_node("addr_ptr", "Address + pointer FSM", theme="control", lines=["fixed device address 0x42", "16-bit MSB-first pointer", "word-alignment checked by CSR router"])}
    {block_node("write_path", "Atomic write-byte path", theme="control", lines=["four MSB-first data bytes", "emit one 32-bit write only when complete", "discard and log partial write"])}
    {block_node("read_path", "Repeated-start read path", theme="control", lines=["pointer-only phase is valid", "current pointer retained", "one 32-bit register response"])}
    {block_node("sda_drive", "SDA drive control", theme="io", lines=["i2c_sda_oe_o", "ACK generation", "read-data bit drive"])}
    {block_node("txn_out", "Local transaction outputs", theme="control", lines=["txn_valid_o / txn_write_o", "txn_addr_o / txn_wdata_o", "txn_rsp_ready_o"], mono=True)}
    {block_node("rsp_in", "Response inputs", theme="control", lines=["txn_ready_i", "txn_rsp_valid_i", "txn_rsp_rdata_i", "txn_rsp_err_i"], mono=True)}

    {{ rank=same; in_pins; sync; addr_ptr; write_path; txn_out; }}
    {{ rank=same; rsp_in; sda_drive; read_path; }}

    {invis("in_pins", "sync")}
    {invis("sync", "addr_ptr")}
    {invis("addr_ptr", "write_path")}
    {invis("write_path", "txn_out")}
    {invis("rsp_in", "sda_drive")}
    {invis("sda_drive", "read_path")}

    {edge("in_pins", "sync", label="raw I2C pins", color=COLORS["control"])}
    {edge("sync", "addr_ptr", label="sampled bits", color=COLORS["clock"])}
    {edge("addr_ptr", "write_path", label="pointer + write bytes", color=COLORS["control"])}
    {edge("addr_ptr", "read_path", label="repeated-start path", color=COLORS["control"])}
    {edge("write_path", "txn_out", label="write transaction", color=COLORS["control"])}
    {edge("read_path", "txn_out", label="read transaction", color=COLORS["control"])}
    {edge("rsp_in", "read_path", label="readback payload", color=COLORS["control"])}
    {edge("sync", "sda_drive", label="ACK / SDA timing", color=COLORS["io"])}
    {edge("read_path", "sda_drive", label="read-bit drive", color=COLORS["io"])}
    """
    return Page(
        "02_spadmic_i2c_slave",
        "spadmic_i2c_slave",
        "Synchronized I2C front end with atomic 32-bit transactions, partial-write discard, and transport-only reset.",
        "I2C/rtl/spadmic_i2c_slave.sv",
        body,
    )


def bridge_page() -> Page:
    body = f"""
    {block_node("i2c_cmd", "I2C command channel", theme="control", lines=["i2c_cmd_valid_i", "i2c_cmd_write_i", "i2c_cmd_addr_i", "i2c_cmd_wdata_i"], mono=True)}
    {block_node("idle", "ST_IDLE", theme="clock", lines=["accept next command only", "no outstanding CSR response"], mono=False)}
    {block_node("wait_rsp", "ST_WAIT_RSP", theme="control", lines=["drive csr_req_*", "hold one outstanding transaction", "wait csr_rsp_valid_i"])}
    {block_node("hold_rsp", "ST_HOLD_RSP", theme="egress", lines=["hold i2c_rsp_* stable", "release after i2c_rsp_ready_i"])}
    {block_node("csr_req", "CSR request bus", theme="control", lines=["csr_req_valid_o", "csr_req_write_o", "csr_req_addr_o", "csr_req_wdata_o"], mono=True)}
    {block_node("csr_rsp", "CSR response bus", theme="control", lines=["csr_rsp_valid_i", "csr_rsp_rdata_i", "csr_rsp_err_i", "csr_rsp_ready_o"], mono=True)}
    {block_node("i2c_rsp", "I2C response channel", theme="control", lines=["i2c_rsp_valid_o", "i2c_rsp_rdata_o", "i2c_rsp_err_o", "i2c_rsp_ready_i"], mono=True)}

    {{ rank=same; i2c_cmd; idle; wait_rsp; hold_rsp; csr_req; }}
    {{ rank=same; i2c_rsp; csr_rsp; }}

    {invis("i2c_cmd", "idle")}
    {invis("idle", "wait_rsp")}
    {invis("wait_rsp", "hold_rsp")}
    {invis("hold_rsp", "csr_req")}

    {edge("i2c_cmd", "idle", label="command arrival", color=COLORS["control"])}
    {edge("idle", "wait_rsp", label="accepted", color=COLORS["clock"])}
    {edge("wait_rsp", "csr_req", label="csr_req_*", color=COLORS["control"])}
    {edge("csr_rsp", "wait_rsp", label="csr_rsp_*", color=COLORS["control"])}
    {edge("wait_rsp", "hold_rsp", label="capture response", color=COLORS["egress"])}
    {edge("hold_rsp", "i2c_rsp", label="i2c_rsp_*", color=COLORS["egress"])}
    """
    return Page(
        "03_spadmic_i2c_csr_bridge",
        "spadmic_i2c_csr_bridge",
        "Single-outstanding bridge between the I2C transaction channel and the shared local CSR bus.",
        "I2C/rtl/spadmic_i2c_csr_bridge.sv",
        body,
    )


def csr_router_page() -> Page:
    body = f"""
    {block_node("csr_req", "Shared CSR request", theme="control", lines=["valid / write", "16-bit byte address", "32-bit write payload"], mono=True)}
    {block_node("validate", "Request validation", theme="egress", lines=["32-bit word alignment", "implemented 4 KiB page", "single outstanding request"])}
    {block_node("decode", "Page decode", theme="control", lines=["0x0 System", "0x1/0x2/0x3 TDC R/Y/B", "0x4 Position, 0x5 Event", "0x6 Matrix, 0x7 TX", "0x8 PLL, 0x9 Analog"])}
    {block_node("banks", "Block-owned bank request", theme="control", lines=["one-hot valid", "full address and payload", "bank response handshake"])}
    {block_node("invalid", "Invalid-access response", theme="egress", lines=["read returns zero", "write has no side effect", "cause/address/data recorded"])}
    {block_node("rsp", "Held CSR response", theme="control", lines=["valid / 32-bit read data / error", "stable until bridge accepts", "bank cause forwarded"])}

    {{ rank=same; csr_req; validate; decode; banks; rsp; }}
    {{ rank=same; invalid; }}

    {invis("csr_req", "validate")}
    {invis("validate", "decode")}
    {invis("decode", "banks")}
    {invis("banks", "rsp")}

    {edge("csr_req", "validate", label="request", color=COLORS["control"])}
    {edge("validate", "decode", label="aligned + mapped", color=COLORS["control"])}
    {edge("validate", "invalid", label="reject", color=COLORS["egress"])}
    {edge("decode", "banks", label="one bank selected", color=COLORS["control"])}
    {edge("banks", "rsp", label="bank response", color=COLORS["control"])}
    {edge("invalid", "rsp", label="zero + error", color=COLORS["egress"])}
    """
    return Page(
        "04_spadmic_csr_router",
        "spadmic_csr_router",
        "ABI 1.0 request validation, page routing, and fail-closed invalid-access behavior.",
        "TOP/rtl/spadmic_csr_router.sv",
        body,
    )


def csr_banks_page() -> Page:
    body = f"""
    {block_node("system", "System bank", theme="control", lines=["ID and ABI version", "atomic GLOBAL_CTRL", "safe-idle and access diagnostics", "maintenance counter clear"])}
    {block_node("tdc", "TDC R/Y/B banks", theme="tdc", lines=["per-axis status", "W1C FIFO fault", "saturating error count"])}
    {block_node("position", "Position bank", theme="position", lines=["cluster/raw mode", "gap and minimum span", "drop fault/count"])}
    {block_node("event", "Event bank", theme="position", lines=["event lifecycle and masks", "snapshot/reset configuration", "R/Y/B snapshot readback"])}
    {block_node("matrix", "Matrix bank", theme="control", lines=["column command and 64-bit data", "readback and validity", "W1C command fault"])}
    {block_node("tx", "TX bank", theme="egress", lines=["bundle/FIFO/DDR status", "fixed FIFO geometry", "missing/overflow faults and counts"])}
    {block_node("pll", "PLL bank", theme="clock", lines=["PLL control image", "lock status", "disabled-and-idle write gate"])}
    {block_node("analog", "Analog bank", theme="io", lines=["SLVS/RX controls", "explicit active polarity", "disabled-and-idle write gate"])}
    {block_node("policy", "Shared bank policy", theme="note", lines=["Configuration writes require global disabled and safe idle.", "GLOBAL_CTRL validates and commits a complete image atomically.", "Faults are W1C; maintenance clears counters only while disabled and idle."])}

    {{ rank=same; system; tdc; position; event; }}
    {{ rank=same; matrix; tx; pll; analog; }}
    {{ rank=same; policy; }}

    {invis("system", "tdc")}
    {invis("tdc", "position")}
    {invis("position", "event")}
    {invis("matrix", "tx")}
    {invis("tx", "pll")}
    {invis("pll", "analog")}
    {invis("system", "matrix", weight=40)}
    {invis("matrix", "policy", weight=40)}
    """
    return Page(
        "05_spadmic_csr_banks",
        "SPADMIC block-owned CSR banks",
        "ABI 1.0 register ownership, write admission, W1C fault handling, and saturating diagnostics.",
        "TOP/rtl/spadmic_csr_banks.sv + TOP/rtl/spadmic_csr_map_pkg.sv",
        body,
    )


def event_coordinator_page() -> Page:
    body = f"""
    {block_node("trigger", "Accepted trigger", theme="position", lines=["normal matrix event", "or selected calibration start", "resources ready before admission"])}
    {block_node("idle", "EVT_IDLE", theme="clock", lines=["compute required packet/reset masks", "allocate one shared event ID"])}
    {block_node("ack", "EVT_WAIT_RESET_ACK", theme="position", lines=["wait snapshot capture", "wait selected TDC start acknowledgements"])}
    {block_node("reset", "EVT_WAIT_RESET_DONE", theme="control", lines=["optional automatic matrix reset", "width from RESET_CFG"])}
    {block_node("packets", "EVT_WAIT_PACKETS", theme="tdc", lines=["wait every required source pending", "frozen event mask"])}
    {block_node("transmit", "EVT_TRANSMIT", theme="egress", lines=["start one correlated bundle", "wait ordered bundle completion"])}
    {block_node("rearm", "EVT_REARM", theme="clock", lines=["wait matrix inputs clear", "return to safe idle"])}

    {{ rank=same; trigger; idle; ack; reset; packets; transmit; rearm; }}
    {invis("trigger", "idle")}
    {invis("idle", "ack")}
    {invis("ack", "reset")}
    {invis("reset", "packets")}
    {invis("packets", "transmit")}
    {invis("transmit", "rearm")}
    {edge("trigger", "idle", label="event trigger", color=COLORS["position"])}
    {edge("idle", "ack", label="freeze masks", color=COLORS["control"])}
    {edge("ack", "reset", label="auto reset enabled", color=COLORS["control"])}
    {edge("ack", "packets", label="no reset", color=COLORS["tdc"])}
    {edge("reset", "packets", label="reset done", color=COLORS["tdc"])}
    {edge("packets", "transmit", label="all sources pending", color=COLORS["egress"])}
    {edge("transmit", "rearm", label="bundle done", color=COLORS["egress"])}
    """
    return Page(
        "06_spadmic_event_coordinator",
        "spadmic_event_coordinator",
        "One-event-at-a-time lifecycle with frozen source masks, reset acknowledgements, and one shared event ID.",
        "TOP/rtl/spadmic_event_coordinator.sv",
        body,
    )


def stop_qualifier_page() -> Page:
    body = f"""
    {block_node("inputs", "Inputs", theme="io", lines=["rst_n", "start_async_i", "clk_ref_40m"], mono=True)}
    {block_node("arm", "arm_req_q", theme="control", lines=["latch request while clock low", "clear after pulse_seen_q"])}
    {block_node("rearm", "rearm_block_q", theme="egress", lines=["held-high request must drop low", "prevents repeated STOPs"])}
    {block_node("gate", "gate_en_q", theme="clock", lines=["sample arm_req_q only when clk_ref_40m is low"])}
    {block_node("pulse", "pulse_seen_q", theme="clock", lines=["remember one consumed pulse", "clear when clock returns low"])}
    {block_node("outputs", "Outputs", theme="tdc", lines=["stop_async_o", "armed_o"], mono=True)}
    {block_node("timing_note", "Waveform rule", theme="note", lines=["Held-high start_async_i generates one STOP pulse only.", "A new pulse is allowed only after the source returns low."])}

    {{ rank=same; inputs; arm; rearm; gate; outputs; }}
    {{ rank=same; pulse; timing_note; }}

    {invis("inputs", "arm")}
    {invis("arm", "rearm")}
    {invis("rearm", "gate")}
    {invis("gate", "outputs")}

    {edge("inputs", "arm", label="request", color=COLORS["control"])}
    {edge("arm", "rearm", label="pulse seen", color=COLORS["egress"])}
    {edge("rearm", "gate", label="re-arm enable", color=COLORS["egress"])}
    {edge("gate", "pulse", label="qualified high phase", color=COLORS["clock"])}
    {edge("gate", "outputs", label="stop_async_o", color=COLORS["tdc"])}
    {edge("pulse", "outputs", label="armed_o contribution", color=COLORS["clock"])}
    """
    return Page(
        "07_spadmic_ref_stop_qualifier",
        "spadmic_ref_stop_qualifier",
        "One-shot STOP qualifier with explicit held-high re-arm blocking.",
        "TOP/rtl/spadmic_ref_stop_qualifier.sv",
        body,
    )


def axis_wrapper_page() -> Page:
    body = f"""
    {block_node("in_async", "Async/event inputs", theme="io", lines=["clk_sys / clk_ref_40m / async_rst_n", "spad_event_async_i", "cal_start_async_i / cal_stop_async_i"], mono=True)}
    {block_node("mode_csr", "Mode + CSR inputs", theme="control", lines=["global_enable_i / axis_enable_i", "input_sel_override_i", "out_mode_override_i", "csr_valid_i / csr_addr_i / csr_wdata_i"], mono=True)}
    {block_node("gate_evt", "Event gate", theme="control", lines=["spad_event_async_i AND global/axis enable"])}
    {block_node("qual", "STOP qualifier", theme="tdc", lines=["exactly one qualified STOP pulse", "stop_armed_o"])}
    {block_node("mptdc", "Protected mptdc_axis_core", theme="tdc", subtitle="kernel remains local to the R, Y, or B axis", lines=["coordinator-owned conversion start", "shared tuning inputs", "local acquisition and packet state"])}
    {block_node("export", "Packet outputs", theme="tdc", lines=["pkt_valid_o / pkt_data_o", "pkt_sop_o / pkt_eop_o", "pending / ready / busy / fifo_full"], mono=True)}

    {{ rank=same; in_async; gate_evt; qual; mptdc; export; }}
    {{ rank=same; mode_csr; }}

    {invis("in_async", "gate_evt")}
    {invis("gate_evt", "qual")}
    {invis("qual", "mptdc")}
    {invis("mptdc", "export")}

    {edge("in_async", "gate_evt", label="SPAD event", color=COLORS["control"])}
    {edge("gate_evt", "qual", label="start_async_gated", color=COLORS["tdc"])}
    {edge("qual", "mptdc", label="qualified STOP", color=COLORS["tdc"])}
    {edge("mode_csr", "mptdc", label="CSR + override controls", color=COLORS["control"])}
    {edge("mptdc", "export", label="16-bit packet stream", color=COLORS["tdc"])}
    """
    return Page(
        "08_spadmic_tdc_axis_wrapper",
        "spadmic_tdc_axis_wrapper",
        "TOP-owned R/Y/B wrapper around the stop qualifier and protected MPTDC axis core.",
        "TOP/rtl/spadmic_tdc_axis_wrapper.sv",
        body,
    )


def event_bundle_page() -> Page:
    body = f"""
    {block_node("r", "R packet", theme="tdc", lines=["pending + SOP/EOP", "16-bit logical words"])}
    {block_node("y", "Y packet", theme="tdc", lines=["pending + SOP/EOP", "16-bit logical words"])}
    {block_node("b", "B packet", theme="tdc", lines=["pending + SOP/EOP", "16-bit logical words"])}
    {block_node("pos", "Position packet", theme="position", lines=["cluster or raw", "pending + SOP/EOP"])}
    {block_node("mask", "Frozen required mask", theme="control", lines=["captured at bundle start", "source presence checked before send"])}
    {block_node("order", "Deterministic source order", theme="egress", lines=["R -> Y -> B -> position", "hold each source through EOP"])}
    {block_node("patch", "Public identity patch", theme="egress", lines=["TDC header gets R/Y/B source ID", "every EOP gets shared event ID"])}
    {block_node("flush", "Ordered flush", theme="control", lines=["emit after final required packet", "pad odd DDR word deterministically"])}

    {{ rank=same; r; y; b; pos; }}
    {{ rank=same; mask; order; patch; flush; }}
    {invis("r", "y")}
    {invis("y", "b")}
    {invis("b", "pos")}
    {invis("mask", "order")}
    {invis("order", "patch")}
    {invis("patch", "flush")}
    {edge("r", "order", label="source 0", color=COLORS["tdc"])}
    {edge("y", "order", label="source 1", color=COLORS["tdc"])}
    {edge("b", "order", label="source 2", color=COLORS["tdc"])}
    {edge("pos", "order", label="source 3", color=COLORS["position"])}
    {edge("mask", "order", label="required sources", color=COLORS["control"])}
    {edge("order", "patch", label="packet-atomic words", color=COLORS["egress"])}
    {edge("patch", "flush", label="completed mask", color=COLORS["egress"])}
    """
    return Page(
        "09_spadmic_event_bundle_tx",
        "spadmic_event_bundle_tx",
        "Deterministic R/Y/B/position packet bundle with one shared event ID and an ordered flush marker.",
        "TOP/rtl/spadmic_event_bundle_tx.sv",
        body,
    )


def position_packetizer_page() -> Page:
    body = f"""
    {block_node("start", "Coordinator start", theme="control", lines=["shared event ID", "cluster/raw mode", "gap and minimum-span settings"])}
    {block_node("capture", "Private snapshot capture", theme="position", lines=["copy R/Y/B snapshot", "acknowledge capture before matrix reset"])}
    {block_node("scan", "Three cluster scanners", theme="position", lines=["R/Y/B independently", "retain first two clusters", "filter by minimum span"])}
    {block_node("cluster", "Cluster packet", theme="egress", lines=["8 logical words", "header + six cluster words + EOP"])}
    {block_node("raw", "Raw packet", theme="egress", lines=["14 logical words", "header + 12 bitmap words + EOP"])}
    {block_node("handshake", "Packet handshake", theme="position", lines=["SOP/EOP sidebands", "pending/busy/done", "drop if start arrives busy"])}

    {{ rank=same; start; capture; scan; cluster; raw; handshake; }}
    {invis("start", "capture")}
    {invis("capture", "scan")}
    {invis("scan", "cluster")}
    {invis("cluster", "raw")}
    {invis("raw", "handshake")}
    {edge("start", "capture", label="start", color=COLORS["control"])}
    {edge("capture", "scan", label="stable private image", color=COLORS["position"])}
    {edge("scan", "cluster", label="cluster mode", color=COLORS["position"])}
    {edge("capture", "raw", label="raw mode", color=COLORS["position"])}
    {edge("cluster", "handshake", label="16-bit words", color=COLORS["egress"])}
    {edge("raw", "handshake", label="16-bit words", color=COLORS["egress"])}
    """
    return Page(
        "10_spadmic_position_snapshot_packetizer",
        "spadmic_position_snapshot_packetizer",
        "Private R/Y/B snapshot capture with cluster/raw packet generation under coordinator control.",
        "TOP/rtl/spadmic_position_snapshot_packetizer.sv",
        body,
    )


def cluster_scan_page() -> Page:
    body = f"""
    {block_node("in_bits", "Inputs", theme="position", lines=["lines_i[LINE_W-1:0]", "gap_threshold_i[6:0]"], mono=True)}
    {block_node("c0", "cluster0 builder", theme="position", lines=["first active run", "track lo / hi", "merge sub-threshold gaps"])}
    {block_node("c1", "cluster1 builder", theme="position", lines=["start only after gap >= threshold", "track second lo / hi"])}
    {block_node("ovf", "Overflow detect", theme="egress", lines=["third qualified cluster -> overflow", "freeze cluster1 after overflow"])}
    {block_node("out_sum", "clusters_o", theme="position", lines=["cluster0", "cluster1", "overflow", "empty / cluster_count"], mono=True)}
    {block_node("rule", "Scan rule", theme="note", lines=["A new cluster begins only after a zero-gap run reaches gap_threshold_i.", "Additional clusters do not overwrite the first two reported clusters."])}

    {{ rank=same; in_bits; c0; c1; ovf; out_sum; }}
    {{ rank=same; rule; }}

    {invis("in_bits", "c0")}
    {invis("c0", "c1")}
    {invis("c1", "ovf")}
    {invis("ovf", "out_sum")}

    {edge("in_bits", "c0", label="scan bitmap", color=COLORS["position"])}
    {edge("c0", "c1", label="gap split", color=COLORS["position"])}
    {edge("c1", "ovf", label="third cluster check", color=COLORS["egress"])}
    {edge("ovf", "out_sum", label="summary result", color=COLORS["position"])}
    """
    return Page(
        "11_spadmic_axis_cluster_scan",
        "spadmic_axis_cluster_scan",
        "Two-cluster bitmap scanner with threshold-based split and overflow retention of the first two clusters.",
        "position/rtl/spadmic_axis_cluster_scan.sv",
        body,
    )


def pages() -> list[Page]:
    return [
        top_page(),
        i2c_slave_page(),
        bridge_page(),
        csr_router_page(),
        csr_banks_page(),
        event_coordinator_page(),
        stop_qualifier_page(),
        axis_wrapper_page(),
        event_bundle_page(),
        position_packetizer_page(),
        cluster_scan_page(),
    ]


def render_page(page: Page, dot_dir: Path, svg_dir: Path, pdf_dir: Path) -> Path:
    dot_path = dot_dir / f"{page.stem}.dot"
    svg_path = svg_dir / f"{page.stem}.svg"
    pdf_path = pdf_dir / f"{page.stem}.pdf"
    dot_path.write_text(wrap_graph(page), encoding="utf-8")
    subprocess.run(["dot", "-Tsvg", str(dot_path), "-o", str(svg_path)], check=True)
    subprocess.run(["dot", "-Tpdf", str(dot_path), "-o", str(pdf_path)], check=True)
    return pdf_path


def parse_args():
    default_out = Path(__file__).resolve().parent / "diagrams"
    parser = argparse.ArgumentParser(description="Generate Graphviz-based SPADMIC schematic pack.")
    parser.add_argument("--outdir", type=Path, default=default_out, help="Output directory.")
    return parser.parse_args()


def main():
    args = parse_args()
    outdir = args.outdir.resolve()
    dot_dir = outdir / "dot"
    svg_dir = outdir / "svg"
    pdf_dir = outdir / "pdf"
    for path in (outdir, dot_dir, svg_dir, pdf_dir):
        path.mkdir(parents=True, exist_ok=True)
    for path, suffix in ((dot_dir, ".dot"), (svg_dir, ".svg"), (pdf_dir, ".pdf")):
        for generated_path in path.glob(f"*{suffix}"):
            generated_path.unlink()

    rendered = []
    for page in pages():
        rendered.append(render_page(page, dot_dir, svg_dir, pdf_dir))

    pack_path = outdir / "spadmic_visual_pack_a4.pdf"
    writer = PdfWriter()
    for pdf_path in rendered:
        reader = PdfReader(str(pdf_path))
        for page in reader.pages:
            writer.add_page(page)
    with pack_path.open("wb") as handle:
        writer.write(handle)

    print(f"Wrote DOT sources: {dot_dir}")
    print(f"Wrote SVG pages : {svg_dir}")
    print(f"Wrote PDF pages : {pdf_dir}")
    print(f"Wrote PDF pack  : {pack_path}")
    print(f"Page count      : {len(rendered)}")


if __name__ == "__main__":
    main()
