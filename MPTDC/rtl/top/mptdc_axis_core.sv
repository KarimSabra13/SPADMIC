`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC - Product axis core
// File     : mptdc_axis_core.sv
// Purpose  : SPADMIC product boundary for one MPTDC axis.
// Author   : Karim Sabra
// =============================================================================
module mptdc_axis_core
  import mptdc_pkg::*;
(
  input  wire                    clk_sys,
  input  wire                    async_rst_n,

  input  wire                    start_spad_async_i,
  input  wire                    stop_spad_async_i,
  input  wire                    cal_start_async_i,
  input  wire                    cal_stop_async_i,

  input  mptdc_pkg::input_sel_e  input_sel_i,
  input  wire                    conv_arm_i,
  input  wire                    fifo_clr_i,
  input  wire                    soft_reset_i,
  input  wire [MAX_HITS_W-1:0]  max_hits_i,
  input  wire [7:0]              ro_slow_code_i,
  input  wire [7:0]              ro_fast_code_i,

  output wire                    pkt_valid_o,
  input  wire                    pkt_ready_i,
  output wire [NARROW_W-1:0]    pkt_data_o,
  output wire                    pkt_sop_o,
  output wire                    pkt_eop_o,
  output wire                    packet_active_o,
  output wire                    packet_pending_o,

  output wire                    ready_o,
  output wire                    busy_o,
  output wire                    fifo_full_o
);

  (* keep = "true", dont_touch = "true" *) wire rst_core_n;
  wire local_async_rst_n;
  wire start_async;
  wire stop_async;
  mptdc_status_t status;
  logic [1:0] soft_rst_hold_q;

  always_ff @(posedge clk_sys or negedge async_rst_n) begin
    if (!async_rst_n)
      soft_rst_hold_q <= '0;
    else if (soft_reset_i)
      soft_rst_hold_q <= 2'd3;
    else if (soft_rst_hold_q != '0)
      soft_rst_hold_q <= soft_rst_hold_q - 2'd1;
  end

  assign local_async_rst_n = async_rst_n & ~(soft_rst_hold_q != 2'd0);

  (* keep_hierarchy = "yes", dont_touch = "true", preserve *)
  mptdc_reset_sync #(.STAGES(4)) u_rst_core_sync (
    .clk         (clk_sys),
    .async_rst_n (local_async_rst_n),
    .rst_n_o     (rst_core_n)
  );

  mptdc_input_mux u_input_mux (
    .start_spad_async_i (start_spad_async_i),
    .stop_spad_async_i  (stop_spad_async_i),
    .cal_start_async_i  (cal_start_async_i),
    .cal_stop_async_i   (cal_stop_async_i),
    .input_sel_i        (input_sel_i),
    .start_async_o      (start_async),
    .stop_async_o       (stop_async)
  );

  mptdc_core u_core (
    .clk_sys          (clk_sys),
    .async_rst_n_i    (async_rst_n),
    .rst_sys_n        (rst_core_n),
    .start_async_i    (start_async),
    .stop_async_i     (stop_async),
    .max_hits_i       (max_hits_i),
    .ro_slow_code_i   (ro_slow_code_i),
    .ro_fast_code_i   (ro_fast_code_i),
    .conv_arm_i       (conv_arm_i),
    .fifo_clr_i       (fifo_clr_i),
    .status_o         (status),
    .pkt_valid_o      (pkt_valid_o),
    .pkt_ready_i      (pkt_ready_i),
    .pkt_data_o       (pkt_data_o),
    .pkt_sop_o        (pkt_sop_o),
    .pkt_eop_o        (pkt_eop_o),
    .packet_active_o  (packet_active_o),
    .packet_pending_o (packet_pending_o)
  );

  assign ready_o     = status.ready;
  assign busy_o      = status.busy;
  assign fifo_full_o = status.fifo_full;

endmodule : mptdc_axis_core

`default_nettype wire
