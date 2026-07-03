// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : mptdc_axis_core_blackbox.sv
// Purpose  : Black-box declaration for TOP glue synthesis only.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

(* black_box, syn_black_box, keep_hierarchy = "yes" *)
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
  input  wire [MAX_HITS_W-1:0]   max_hits_i,
  input  wire [7:0]              ro_slow_code_i,
  input  wire [7:0]              ro_fast_code_i,

  output wire                    pkt_valid_o,
  input  wire                    pkt_ready_i,
  output wire [NARROW_W-1:0]     pkt_data_o,
  output wire                    pkt_sop_o,
  output wire                    pkt_eop_o,
  output wire                    packet_active_o,
  output wire                    packet_pending_o,

  output wire                    ready_o,
  output wire                    busy_o,
  output wire                    fifo_full_o
);
endmodule

`default_nettype wire
