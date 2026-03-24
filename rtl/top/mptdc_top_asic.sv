// ============================================================================
//  mptdc_top_asic.sv — Pad-facing ASIC top-level wrapper
//
//  Instantiates reset synchroniser, input mux, CSR register file, and
//  TDC core.  All pads connect here; nothing above this module except
//  the pad ring.
// ============================================================================
`timescale 1ns / 1ps
`default_nettype none

module mptdc_top_asic
  import mptdc_pkg::*;
(
  // ── Pad-facing clock and reset ──────────────────────────────────
  input  wire                    clk_sys,           // 160 MHz system clock
  input  wire                    async_rst_n,       // Async active-low reset

  // ── SPAD matrix async inputs ────────────────────────────────────
  input  wire                    start_spad_async_i,
  input  wire                    stop_spad_async_i,

  // ── Calibration injection async inputs ──────────────────────────
  input  wire                    cal_start_async_i,
  input  wire                    cal_stop_async_i,

  // ── CSR bus (from controller / SPI bridge) ──────────────────────
  input  wire                    csr_valid_i,
  input  wire                    csr_write_i,
  input  wire  [CSR_ADDR_W-1:0] csr_addr_i,
  input  wire  [CSR_DATA_W-1:0] csr_wdata_i,
  output wire                    csr_ready_o,
  output wire                    csr_rvalid_o,
  output wire  [CSR_DATA_W-1:0] csr_rdata_o,

  // ── 16-bit narrow output (ready/valid) ──────────────────────────
  input  wire                    narrow_ready_i,
  output wire                    narrow_valid_o,
  output wire  [NARROW_W-1:0]   narrow_data_o
);

  // ────────────────────────────────────────────────────────────────
  //  Internal wires
  // ────────────────────────────────────────────────────────────────
  wire             rst_sync_n;        // synchronised reset from pad
  wire             rst_n_internal;    // combined reset (pad + soft)

  wire             start_async;       // mux → core
  wire             stop_async;        // mux → core

  mptdc_cfg_t      cfg;               // CSR → core  (quasi-static config)
  mptdc_status_t   status;            // core → CSR  (live status)
  logic            conv_arm_pulse;
  logic            fifo_clr_pulse;
  logic            soft_rst_pulse;

  // Combined reset: pad-synchronised AND inverse of software reset pulse
  assign rst_n_internal = rst_sync_n & ~soft_rst_pulse;

  // ────────────────────────────────────────────────────────────────
  //  Reset synchroniser
  // ────────────────────────────────────────────────────────────────
  mptdc_reset_sync #(.STAGES(2)) u_rst_sync (
    .clk         (clk_sys),
    .async_rst_n (async_rst_n),
    .rst_n_o     (rst_sync_n)
  );

  // ────────────────────────────────────────────────────────────────
  //  SPAD / calibration input mux
  // ────────────────────────────────────────────────────────────────
  mptdc_input_mux u_input_mux (
    .clk_sys            (clk_sys),
    .rst_n              (rst_n_internal),
    .start_spad_async_i (start_spad_async_i),
    .stop_spad_async_i  (stop_spad_async_i),
    .cal_start_async_i  (cal_start_async_i),
    .cal_stop_async_i   (cal_stop_async_i),
    .input_sel_i        (cfg.input_sel),
    .start_async_o      (start_async),
    .stop_async_o       (stop_async)
  );

  // ────────────────────────────────────────────────────────────────
  //  CSR register file
  // ────────────────────────────────────────────────────────────────
  mptdc_csr_minimal u_csr (
    .clk_sys          (clk_sys),
    .rst_n            (rst_n_internal),
    .csr_valid_i      (csr_valid_i),
    .csr_write_i      (csr_write_i),
    .csr_addr_i       (csr_addr_i),
    .csr_wdata_i      (csr_wdata_i),
    .csr_ready_o      (csr_ready_o),
    .csr_rvalid_o     (csr_rvalid_o),
    .csr_rdata_o      (csr_rdata_o),
    .status_i         (status),
    .cfg_o            (cfg),
    .conv_arm_pulse_o (conv_arm_pulse),
    .fifo_clr_pulse_o (fifo_clr_pulse),
    .soft_rst_pulse_o (soft_rst_pulse)
  );

  // ────────────────────────────────────────────────────────────────
  //  TDC core (measurement logic, FIFO, narrow serialiser)
  // ────────────────────────────────────────────────────────────────
  mptdc_core u_core (
    .clk_sys        (clk_sys),
    .rst_sys_n      (rst_n_internal),
    .start_async_i  (start_async),
    .stop_async_i   (stop_async),
    .cfg_i          (cfg),
    .conv_arm_i     (conv_arm_pulse),
    .fifo_clr_i     (fifo_clr_pulse),
    .status_o       (status),
    .narrow_ready_i (narrow_ready_i),
    .narrow_valid_o (narrow_valid_o),
    .narrow_data_o  (narrow_data_o)
  );

endmodule : mptdc_top_asic

`default_nettype wire
