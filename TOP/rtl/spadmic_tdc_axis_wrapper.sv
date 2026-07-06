// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_tdc_axis_wrapper.sv
// Purpose  : Per-axis wrapper around the stop qualifier and product MPTDC core.
// Author   : Karim Sabra
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_tdc_axis_wrapper (
  input  wire                       clk_sys,
  input  wire                       clk_ref_40m,
  input  wire                       async_rst_n,
  input  wire                       global_enable_i,
  input  wire                       axis_enable_i,
  input  wire                       spad_event_async_i,
  input  wire                       cal_start_async_i,
  input  wire                       cal_stop_async_i,
  input  mptdc_pkg::input_sel_e     input_sel_i,
  input  wire                       conv_arm_i,
  input  wire                       fifo_clr_i,
  input  wire                       soft_reset_i,
  input  wire [mptdc_pkg::MAX_HITS_W-1:0] max_hits_i,
  input  wire [7:0]                 ro_slow_code_i,
  input  wire [7:0]                 ro_fast_code_i,

  output wire                       pkt_valid_o,
  input  wire                       pkt_ready_i,
  output wire [mptdc_pkg::NARROW_W-1:0] pkt_data_o,
  output wire                       pkt_sop_o,
  output wire                       pkt_eop_o,
  output wire                       packet_active_o,
  output wire                       packet_pending_o,

  output wire                       ready_o,
  output wire                       busy_o,
  output wire                       fifo_full_o,

  output wire                       stop_armed_o
);
  wire start_async_gated;
  wire cal_start_async_gated;
  wire cal_stop_async_gated;
  wire stop_async_qualified;
  wire ro_slow_tap0_unused;
  wire ro_fast_tap0_unused;

  // These enables are configured quiescently through CSR and are treated as
  // stable during active measurement, matching the existing MPTDC async-mux use.
  assign start_async_gated = spad_event_async_i & global_enable_i & axis_enable_i;
  assign cal_start_async_gated = cal_start_async_i & global_enable_i & axis_enable_i;
  assign cal_stop_async_gated  = cal_stop_async_i  & global_enable_i & axis_enable_i;

  // Convert the asynchronous SPAD event into exactly one qualified STOP pulse on
  // the next clk_ref_40m rising edge.
  spadmic_ref_stop_qualifier u_stop_qualifier (
    .rst_n         (async_rst_n),
    .start_async_i (start_async_gated),
    .clk_ref_40m   (clk_ref_40m),
    .stop_async_o  (stop_async_qualified),
    .armed_o       (stop_armed_o)
  );

  mptdc_axis_core u_tdc (
    .clk_sys            (clk_sys),
    .async_rst_n        (async_rst_n),
    .start_spad_async_i (start_async_gated),
    .stop_spad_async_i  (stop_async_qualified),
    .cal_start_async_i  (cal_start_async_gated),
    .cal_stop_async_i   (cal_stop_async_gated),
    .input_sel_i        (input_sel_i),
    .conv_arm_i         (conv_arm_i),
    .fifo_clr_i         (fifo_clr_i),
    .soft_reset_i       (soft_reset_i),
    .max_hits_i         (max_hits_i),
    .ro_slow_code_i     (ro_slow_code_i),
    .ro_fast_code_i     (ro_fast_code_i),
    .pkt_valid_o        (pkt_valid_o),
    .pkt_ready_i        (pkt_ready_i),
    .pkt_data_o         (pkt_data_o),
    .pkt_sop_o          (pkt_sop_o),
    .pkt_eop_o          (pkt_eop_o),
    .packet_active_o    (packet_active_o),
    .packet_pending_o   (packet_pending_o),
    .ro_slow_tap0_o     (ro_slow_tap0_unused),
    .ro_fast_tap0_o     (ro_fast_tap0_unused),
    .ready_o            (ready_o),
    .busy_o             (busy_o),
    .fifo_full_o        (fifo_full_o)
  );

endmodule

`default_nettype wire
