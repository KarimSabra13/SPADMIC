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

from pypdf import PdfReader, PdfWriter


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
      label="SPADMIC top chip - conceptual floorplan schematic";
      labeljust=l;
      labelloc=t;
      fontsize=18;
      fontcolor="{COLORS["ink"]}";
      color="{COLORS["cluster"]}";
      penwidth=2.2;
      style="rounded";

      {block_node("pad_clk", "I/O pads - clock/reset", theme="io", lines=["ref clock in", "reset / test straps", "power-good / enables"])}
      {macro_node("pll", "PLL / CLOCK MACRO", ["black-box clock source", "clk_ref_40m", "clk_sys_160m"], width=2.3, height=1.0)}
      {block_node("pad_status", "I/O pads - status", theme="io", lines=["tdc_stop_armed[2:0]", "tdc_shared_busy", "position_busy"])}

      {block_node("pad_i2c", "I/O pads - control", theme="io", lines=["i2c_scl_i", "i2c_sda_i", "i2c_sda_oe_o"])}
      {block_node("control", "Control plane", theme="control", subtitle="I2C slave -> bridge -> CSR decoder -> global CSR -> sequencer", lines=["requested image", "active image commit", "fault / status readback"])}
      {block_node("axis_x", "TDC axis X", theme="tdc", subtitle="stop qualifier + preserved mptdc_top_asic", lines=["spad event X", "CAL start/stop X", "CSR + ACQ export"])}
      {block_node("axis_y", "TDC axis Y", theme="tdc", subtitle="stop qualifier + preserved mptdc_top_asic", lines=["spad event Y", "CAL start/stop Y", "CSR + ACQ export"])}
      {block_node("axis_z", "TDC axis Z", theme="tdc", subtitle="stop qualifier + preserved mptdc_top_asic", lines=["spad event Z", "CAL start/stop Z", "CSR + ACQ export"])}
      {block_node("tx_mux", "Shared TX mux", theme="egress", subtitle="one physical chip_tx_* bus", lines=["select TDC or position packet", "ready only to selected source"])}
      {block_node("pad_tx", "I/O pads - chip TX", theme="io", lines=["chip_tx_clk_o", "chip_tx_valid_o", "chip_tx_data_o[7:0] DDR"])}

      {block_node("shared_readout", "Shared TDC readout", theme="tdc", subtitle="META arbitration + shared narrow16 serializer", lines=["packet-atomic owner hold", "source tag patch", "shared TDC packet stream"])}
      {block_node("position", "Position path", theme="position", subtitle="sync + settle FSM + cluster scan + packetizer", lines=["x/y/z line snapshots", "fault counters / stickies", "fixed 8-word position packet"])}

      {macro_node("spad_matrix", "SPAD MATRIX", ["black-box sensor macro", "event taps X / Y / Z", "x_lines / y_lines / z_lines"], width=2.6, height=2.4)}

      {{ rank=same; pad_clk; pll; pad_status; }}
      {{ rank=same; pad_i2c; control; axis_x; axis_y; axis_z; tx_mux; pad_tx; }}
      {{ rank=same; shared_readout; position; }}
      {{ rank=same; spad_matrix; }}

      {invis("pad_i2c", "control")}
      {invis("control", "axis_x")}
      {invis("axis_x", "axis_y")}
      {invis("axis_y", "axis_z")}
      {invis("axis_z", "tx_mux")}
      {invis("tx_mux", "pad_tx")}
      {invis("shared_readout", "position")}

      {edge("pad_clk", "pll", label="ref clock / reset", color=COLORS["io"])}
      {edge("pll", "control", label="clk_sys_160m", color=COLORS["clock"])}
      {edge("pll", "axis_x", label="clk_ref_40m + clk_sys", color=COLORS["clock"])}
      {edge("pll", "axis_y", color=COLORS["clock"])}
      {edge("pll", "axis_z", color=COLORS["clock"])}
      {edge("pll", "shared_readout", color=COLORS["clock"])}
      {edge("pll", "position", color=COLORS["clock"])}

      {edge("pad_i2c", "control", label="scl / sda", color=COLORS["control"])}
      {edge("control", "axis_x", label="X CSR + mode", color=COLORS["control"])}
      {edge("control", "axis_y", label="Y CSR + mode", color=COLORS["control"])}
      {edge("control", "axis_z", label="Z CSR + mode", color=COLORS["control"])}
      {edge("control", "position", label="POS CSR", color=COLORS["control"])}

      {edge("spad_matrix", "axis_x", label="event X", color=COLORS["tdc"])}
      {edge("spad_matrix", "axis_y", label="event Y", color=COLORS["tdc"])}
      {edge("spad_matrix", "axis_z", label="event Z", color=COLORS["tdc"])}
      {edge("spad_matrix", "position", label="x/y/z line buses", color=COLORS["position"])}

      {edge("axis_x", "shared_readout", label="ACQ export X", color=COLORS["tdc"])}
      {edge("axis_y", "shared_readout", label="ACQ export Y", color=COLORS["tdc"])}
      {edge("axis_z", "shared_readout", label="ACQ export Z", color=COLORS["tdc"])}
      {edge("shared_readout", "tx_mux", label="TDC packet bus", color=COLORS["tdc"])}
      {edge("position", "tx_mux", label="position packet bus", color=COLORS["position"])}
      {edge("tx_mux", "pad_tx", label="chip_tx_*", color=COLORS["egress"])}

      {edge("axis_x", "pad_status", label="stop_armed[0]", color=COLORS["io"])}
      {edge("axis_y", "pad_status", label="stop_armed[1]", color=COLORS["io"])}
      {edge("axis_z", "pad_status", label="stop_armed[2]", color=COLORS["io"])}
      {edge("shared_readout", "pad_status", label="tdc_shared_busy", color=COLORS["io"])}
      {edge("position", "pad_status", label="position_busy", color=COLORS["io"])}
    }}

    {block_node("top_note", "Technical note", theme="note", lines=[
        "The SPAD matrix and PLL are shown as black-box macros for chip-level communication clarity.",
        "The active RTL still treats clocks and matrix outputs as top-level interfaces.",
        "Three preserved TDC kernels stay local until acquisition-record export."
    ])}
    {{ rank=same; top_note; }}
    """
    return Page(
        "01_spadmic_top_floorplan",
        "SPADMIC top conceptual floorplan schematic",
        "Professional chip-level page with grouped I/O pads, black-box SPAD matrix, black-box PLL, and the active shared-bus architecture.",
        "TOP/rtl/spadmic_top_v1.sv + TOP/docs/01_ACTIVE_ARCHITECTURE.md",
        body,
    )


def i2c_slave_page() -> Page:
    body = f"""
    {block_node("in_pins", "Inputs", theme="io", lines=["clk_sys", "rst_n", "i2c_scl_i", "i2c_sda_i"], mono=True)}
    {block_node("sync", "SCL/SDA synchronizers", theme="clock", lines=["double-sync into clk_sys", "START / STOP decode", "scl_rise / scl_fall timing"])}
    {block_node("addr_ptr", "Address + pointer FSM", theme="control", lines=["device address match", "16-bit pointer capture", "12-bit CSR mapping"])}
    {block_node("write_path", "Write-byte path", theme="control", lines=["D0 / D1 / D2 / D3 assembly", "ACK held through full SCL-high", "emit write transaction"])}
    {block_node("read_path", "Repeated-start read path", theme="control", lines=["pointer-valid read launch", "predrive first read bit", "ACK/NACK byte stepping"])}
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
        "Schematic page for the synchronized I2C front end and its pointer-based command/readback behavior.",
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


def csr_decoder_page() -> Page:
    body = f"""
    {block_node("csr_req", "Shared CSR request", theme="control", lines=["csr_req_valid_i", "csr_req_write_i", "csr_req_addr_i[11:0]", "csr_req_wdata_i", "csr_req_ready_o"], mono=True)}
    {block_node("decode", "Region decode", theme="control", lines=["[11:8] -> GLOBAL / X / Y / Z / POS", "lower subset forwarded to local MPTDC CSR"], mono=False)}
    {block_node("write_fast", "Write fast-path", theme="egress", lines=["immediate empty response", "invalid region -> error"], mono=False)}
    {block_node("read_wait", "Read wait / timeout", theme="clock", lines=["wait downstream rvalid", "15-cycle timeout", "avoid stalled CSR fabric"], mono=False)}
    {block_node("global", "GLOBAL region", theme="control", lines=["global_csr_*"], mono=True)}
    {block_node("x_tdc", "TDC X region", theme="tdc", lines=["x_csr_*"], mono=True)}
    {block_node("y_tdc", "TDC Y region", theme="tdc", lines=["y_csr_*"], mono=True)}
    {block_node("z_tdc", "TDC Z region", theme="tdc", lines=["z_csr_*"], mono=True)}
    {block_node("pos", "POSITION region", theme="position", lines=["pos_csr_*"], mono=True)}
    {block_node("rsp_mux", "Response mux / hold", theme="control", lines=["csr_rsp_valid_o", "csr_rsp_rdata_o", "csr_rsp_err_o", "csr_rsp_ready_i"], mono=True)}

    {{ rank=same; csr_req; decode; global; x_tdc; y_tdc; z_tdc; pos; }}
    {{ rank=same; write_fast; read_wait; rsp_mux; }}

    {invis("csr_req", "decode")}
    {invis("global", "x_tdc")}
    {invis("x_tdc", "y_tdc")}
    {invis("y_tdc", "z_tdc")}
    {invis("z_tdc", "pos")}

    {edge("csr_req", "decode", label="region select", color=COLORS["control"])}
    {edge("decode", "global", label="GLOBAL", color=COLORS["control"])}
    {edge("decode", "x_tdc", label="X", color=COLORS["tdc"])}
    {edge("decode", "y_tdc", label="Y", color=COLORS["tdc"])}
    {edge("decode", "z_tdc", label="Z", color=COLORS["tdc"])}
    {edge("decode", "pos", label="POS", color=COLORS["position"])}
    {edge("decode", "write_fast", label="write requests", color=COLORS["egress"])}
    {edge("decode", "read_wait", label="read requests", color=COLORS["clock"])}
    {edge("global", "rsp_mux", color=COLORS["control"])}
    {edge("x_tdc", "rsp_mux", color=COLORS["tdc"])}
    {edge("y_tdc", "rsp_mux", color=COLORS["tdc"])}
    {edge("z_tdc", "rsp_mux", color=COLORS["tdc"])}
    {edge("pos", "rsp_mux", color=COLORS["position"])}
    """
    return Page(
        "04_spadmic_csr_decoder",
        "spadmic_csr_decoder",
        "Shared 12-bit CSR routing page with timeout-protected read behavior and explicit invalid-region handling.",
        "TOP/rtl/spadmic_csr_decoder.sv",
        body,
    )


def global_csr_page() -> Page:
    body = f"""
    {block_node("csr_if", "CSR interface", theme="control", lines=["csr_valid_i / csr_write_i", "csr_addr_i / csr_wdata_i", "csr_ready_o / csr_rvalid_o / csr_rdata_o"], mono=True)}
    {block_node("requested", "Requested image registers", theme="control", lines=["req_global_enable_o", "req_axis_enable_o[2:0]", "req_position_enable_o", "req_shared_tx_sel_o", "req_tdc_input_sel_o / req_tdc_out_mode_o"], mono=True)}
    {block_node("admission", "Admission + reject logic", theme="egress", lines=["cfg_accept_i gate", "ctrl_change_req detect", "mode_reject_count_q", "mode_reject_sticky_q"])}
    {block_node("status_in", "Datapath status inputs", theme="position", lines=["tdc_tx_busy_i / tdc_pkt_pending_i", "tdc_pkt_full_i", "position busy / pending", "position drop / glitch sticky"], mono=True)}
    {block_node("active", "Active image mirror", theme="clock", lines=["active_global_enable_i", "active_axis_enable_i", "active_position_enable_i", "active_shared_tx_sel_i", "active_tdc_input_sel_i / active_tdc_out_mode_i"], mono=True)}
    {block_node("readback", "Readback mux", theme="control", lines=["GLOBAL_ID / VERSION", "GLOBAL_CTRL request image", "GLOBAL_STATUS live image + path state", "GLOBAL_FAULT / GLOBAL_FAULT_COUNT"], mono=False)}
    {block_node("out_req", "Requested outputs", theme="control", lines=["req_* image", "cfg_update_o pulse"], mono=True)}

    {{ rank=same; csr_if; requested; admission; out_req; }}
    {{ rank=same; status_in; active; readback; }}

    {invis("csr_if", "requested")}
    {invis("requested", "admission")}
    {invis("admission", "out_req")}
    {invis("status_in", "active")}
    {invis("active", "readback")}

    {edge("csr_if", "requested", label="writes requested image", color=COLORS["control"])}
    {edge("requested", "admission", label="ctrl_change_req", color=COLORS["egress"])}
    {edge("admission", "out_req", label="req_* + cfg_update_o", color=COLORS["control"])}
    {edge("status_in", "readback", label="fault / path state", color=COLORS["position"])}
    {edge("active", "readback", label="active image mirror", color=COLORS["clock"])}
    {edge("requested", "readback", label="requested image mirror", color=COLORS["control"])}
    """
    return Page(
        "05_spadmic_global_csr",
        "spadmic_global_csr",
        "Requested-control bank with active-state mirror, path-idle visibility, and counted reject reporting.",
        "TOP/rtl/spadmic_global_csr.sv",
        body,
    )


def sequencer_page() -> Page:
    body = f"""
    {block_node("req_img", "Requested image inputs", theme="control", lines=["cfg_update_i", "req_global_enable_i", "req_axis_enable_i", "req_position_enable_i", "req_shared_tx_sel_i", "req_tdc_input_sel_i / req_tdc_out_mode_i"], mono=True)}
    {block_node("path_state", "Drain-status inputs", theme="clock", lines=["tdc_tx_busy_i", "tdc_pkt_pending_i[2:0]", "position_busy_i", "position_pending_i"], mono=True)}
    {block_node("reset_s", "SEQ_RESET", theme="clock", lines=["active image disabled", "wait path_idle"])}
    {block_node("idle_s", "SEQ_IDLE", theme="control", lines=["cfg_accept_o only if path_idle", "wait cfg_update_i"])}
    {block_node("drain_s", "SEQ_DRAIN", theme="egress", lines=["force active_global_enable_o low", "drain old path", "copy req_* -> active_* when idle"])}
    {block_node("active_img", "Active image outputs", theme="control", lines=["active_global_enable_o", "active_axis_enable_o", "active_position_enable_o", "active_shared_tx_sel_o", "active_tdc_input_sel_o / active_tdc_out_mode_o"], mono=True)}
    {block_node("status", "Status outputs", theme="egress", lines=["cfg_accept_o", "transition_busy_o"], mono=True)}

    {{ rank=same; req_img; reset_s; idle_s; drain_s; active_img; }}
    {{ rank=same; path_state; status; }}

    {invis("req_img", "reset_s")}
    {invis("reset_s", "idle_s")}
    {invis("idle_s", "drain_s")}
    {invis("drain_s", "active_img")}

    {edge("req_img", "idle_s", label="cfg_update_i", color=COLORS["control"])}
    {edge("path_state", "reset_s", label="path_idle", color=COLORS["clock"])}
    {edge("path_state", "idle_s", color=COLORS["clock"])}
    {edge("path_state", "drain_s", color=COLORS["clock"])}
    {edge("drain_s", "active_img", label="commit active_*", color=COLORS["control"])}
    {edge("idle_s", "status", label="cfg_accept_o", color=COLORS["egress"])}
    {edge("drain_s", "status", label="transition_busy_o", color=COLORS["egress"])}
    """
    return Page(
        "06_spadmic_top_sequencer",
        "spadmic_top_sequencer",
        "Drain-aware requested-to-active handoff that keeps mode/source changes packet-safe.",
        "TOP/rtl/spadmic_top_sequencer.sv",
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
    {block_node("mptdc", "Preserved mptdc_top_asic", theme="tdc", subtitle="kernel remains local to the axis", lines=["async measurement kernel", "CSR endpoint", "local acquisition FIFO", "shared_readout_en_i = 1"])}
    {block_node("export", "Export outputs", theme="tdc", lines=["acq_valid_o / acq_data_o", "acq_ready_i", "fifo_full_o"], mono=True)}

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
    {edge("mptdc", "export", label="ACQ record export", color=COLORS["tdc"])}
    """
    return Page(
        "08_spadmic_tdc_axis_wrapper",
        "spadmic_tdc_axis_wrapper",
        "Per-axis wrapper around the qualifier and one preserved MPTDC kernel, exporting acquisition records to the top-level shared readout.",
        "TOP/rtl/spadmic_tdc_axis_wrapper.sv",
        body,
    )


def unified_arb_page() -> Page:
    body = f"""
    {block_node("tdc_inputs", "3 acquisition-record inputs", theme="tdc", lines=["acq_valid_i[2:0]", "ACQ_REC_META / ACQ_REC_HIT", "RAW_FEATURES or FULL only"], mono=True)}
    {block_node("adapters", "TDC packet adapters x3", theme="tdc", lines=["HEADER", "HIT W0/W1(/W2)", "EOC placeholder"])}
    {block_node("pos", "Position packet sideband adapter", theme="position", lines=["cluster fixed 8 words", "raw fixed 14 words", "SOP/EOP/source sidebands"])}
    {block_node("mask", "Registered source masks", theme="control", lines=["axis_enable", "position_enable", "RAW_TIMESTAMP masked"])}
    {block_node("arb", "4-way packet arbiter", theme="egress", lines=["source skids", "registered grant", "lock until EOP"])}
    {block_node("tag", "Unified event tag patch", theme="egress", lines=["single 14-bit rolling tag", "overwrite producer EOC", "increment on FIFO write EOP"])}
    {block_node("fifo", "Output FIFO", theme="control", lines=["256 words", "155-word max burst + margin", "DDR always-ready baseline"])}

    {{ rank=same; tdc_inputs; adapters; arb; tag; fifo; }}
    {{ rank=same; pos; mask; }}

    {invis("tdc_inputs", "adapters")}
    {invis("adapters", "arb")}
    {invis("arb", "tag")}
    {invis("tag", "fifo")}

    {edge("tdc_inputs", "adapters", label="per-axis records", color=COLORS["tdc"])}
    {edge("adapters", "arb", label="TDC_X/Y/Z packet streams", color=COLORS["tdc"])}
    {edge("pos", "arb", label="position packet stream", color=COLORS["position"])}
    {edge("mask", "arb", label="enabled sources", color=COLORS["control"])}
    {edge("arb", "tag", label="packet-atomic words", color=COLORS["egress"])}
    {edge("tag", "fifo", label="tagged logical stream", color=COLORS["egress"])}
    """
    return Page(
        "09_spadmic_correlated_tx",
        "spadmic_correlated_tx",
        "Unified four-source ARB with per-axis TDC adapters, packet locks, event tagging, and a 256-word output FIFO.",
        "arb/rtl/spadmic_correlated_tx.sv",
        body,
    )


def position_block_page() -> Page:
    body = f"""
    {block_node("pins", "Position inputs", theme="position", lines=["clk_sys / rst_n", "global_enable_i", "x_lines_i / y_lines_i / z_lines_i", "pos_ready_i"], mono=True)}
    {block_node("csr", "Position CSR", theme="control", lines=["csr_valid_i / csr_write_i", "csr_addr_i / csr_wdata_i", "csr_ready_o / csr_rvalid_o / csr_rdata_o"], mono=True)}
    {block_node("sync", "3-stage synchronizers", theme="clock", lines=["ff1 / ff2 / ff3 for x, y, z", "lines_nonzero_sync", "lines_stable_sync"])}
    {block_node("fsm", "Detect / settle / scan FSM", theme="position", lines=["DET_IDLE", "DET_SETTLE", "DET_SCAN", "DET_WAIT_CLEAR"])}
    {block_node("scan", "3x five-cycle cluster scan + filter", theme="position", lines=["u_scan_x / u_scan_y / u_scan_z", "gap_threshold_q", "min_cluster_span_q", "meaningful_event / overflow_any"])}
    {block_node("acct", "Accounting", theme="egress", lines=["event_count_q", "drop_count_q", "reject_count_q", "drop / glitch sticky"], mono=True)}
    {block_node("pkt", "Fixed 8-word packetizer", theme="egress", lines=["header", "six cluster words", "EOC/tag"])}
    {block_node("outs", "Outputs", theme="position", lines=["pos_valid_o / pos_data_o", "busy_o / packet_pending_o", "drop_sticky_o", "glitch_reject_sticky_o"], mono=True)}

    {{ rank=same; pins; sync; fsm; scan; pkt; outs; }}
    {{ rank=same; csr; acct; }}

    {invis("pins", "sync")}
    {invis("sync", "fsm")}
    {invis("fsm", "scan")}
    {invis("scan", "pkt")}
    {invis("pkt", "outs")}

    {edge("pins", "sync", label="async line buses", color=COLORS["position"])}
    {edge("sync", "fsm", label="stable / nonzero detect", color=COLORS["clock"])}
    {edge("fsm", "scan", label="accepted snapshots", color=COLORS["position"])}
    {edge("scan", "pkt", label="cluster summaries", color=COLORS["position"])}
    {edge("csr", "fsm", label="enable / settle config", color=COLORS["control"])}
    {edge("csr", "scan", label="gap / span config", color=COLORS["control"])}
    {edge("fsm", "acct", label="drops / rejects", color=COLORS["egress"])}
    {edge("pkt", "outs", label="position packet bus", color=COLORS["egress"])}
    """
    return Page(
        "10_spadmic_position_block",
        "spadmic_position_block",
        "Async-qualified position detector with explicit settle filtering, cluster extraction, and fixed packet output.",
        "position/rtl/spadmic_position_block.sv",
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
        csr_decoder_page(),
        global_csr_page(),
        sequencer_page(),
        stop_qualifier_page(),
        axis_wrapper_page(),
        unified_arb_page(),
        position_block_page(),
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
