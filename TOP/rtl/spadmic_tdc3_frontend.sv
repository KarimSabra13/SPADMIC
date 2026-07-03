// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_tdc3_frontend.sv
// Purpose  : Three-axis MPTDC frontend glue for matrix-top handoff.
// Author   : Karim Sabra
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_tdc3_frontend (
  input  wire                                  clk_sys,
  input  wire                                  clk_ref_40m,
  input  wire                                  async_rst_n,
  input  wire                                  global_enable_i,
  input  wire [2:0]                            axis_enable_i,
  input  wire [2:0]                            spad_event_async_i,
  input  wire [2:0]                            cal_start_async_i,
  input  wire [2:0]                            cal_stop_async_i,
  input  mptdc_pkg::input_sel_e                input_sel_i,
  input  wire [2:0]                            conv_arm_i,
  input  wire                                  fifo_clr_i,
  input  wire                                  soft_reset_i,
  input  wire [mptdc_pkg::MAX_HITS_W-1:0]      max_hits_i,
  input  wire [7:0]                            ro_slow_code_i,
  input  wire [7:0]                            ro_fast_code_i,

  output wire [2:0]                            pkt_valid_o,
  input  wire [2:0]                            pkt_ready_i,
  output wire [3*mptdc_pkg::NARROW_W-1:0]      pkt_data_o,
  output wire [2:0]                            pkt_sop_o,
  output wire [2:0]                            pkt_eop_o,
  output wire [2:0]                            packet_active_o,
  output wire [2:0]                            packet_pending_o,

  output wire [2:0]                            ready_o,
  output wire [2:0]                            busy_o,
  output wire [2:0]                            fifo_full_o,
  output wire [2:0]                            stop_armed_o
);
  localparam int unsigned TDC_PKT_W = mptdc_pkg::NARROW_W;
  localparam int unsigned AXIS_R    = 0;
  localparam int unsigned AXIS_Y    = 1;
  localparam int unsigned AXIS_B    = 2;

  spadmic_tdc_axis_wrapper u_tdc_r (
    .clk_sys             (clk_sys),
    .clk_ref_40m         (clk_ref_40m),
    .async_rst_n         (async_rst_n),
    .global_enable_i     (global_enable_i),
    .axis_enable_i       (axis_enable_i[AXIS_R]),
    .spad_event_async_i  (spad_event_async_i[AXIS_R]),
    .cal_start_async_i   (cal_start_async_i[AXIS_R]),
    .cal_stop_async_i    (cal_stop_async_i[AXIS_R]),
    .input_sel_i         (input_sel_i),
    .conv_arm_i          (conv_arm_i[AXIS_R]),
    .fifo_clr_i          (fifo_clr_i),
    .soft_reset_i        (soft_reset_i),
    .max_hits_i          (max_hits_i),
    .ro_slow_code_i      (ro_slow_code_i),
    .ro_fast_code_i      (ro_fast_code_i),
    .pkt_valid_o         (pkt_valid_o[AXIS_R]),
    .pkt_ready_i         (pkt_ready_i[AXIS_R]),
    .pkt_data_o          (pkt_data_o[AXIS_R*TDC_PKT_W +: TDC_PKT_W]),
    .pkt_sop_o           (pkt_sop_o[AXIS_R]),
    .pkt_eop_o           (pkt_eop_o[AXIS_R]),
    .packet_active_o     (packet_active_o[AXIS_R]),
    .packet_pending_o    (packet_pending_o[AXIS_R]),
    .ready_o             (ready_o[AXIS_R]),
    .busy_o              (busy_o[AXIS_R]),
    .fifo_full_o         (fifo_full_o[AXIS_R]),
    .stop_armed_o        (stop_armed_o[AXIS_R])
  );

  spadmic_tdc_axis_wrapper u_tdc_y (
    .clk_sys             (clk_sys),
    .clk_ref_40m         (clk_ref_40m),
    .async_rst_n         (async_rst_n),
    .global_enable_i     (global_enable_i),
    .axis_enable_i       (axis_enable_i[AXIS_Y]),
    .spad_event_async_i  (spad_event_async_i[AXIS_Y]),
    .cal_start_async_i   (cal_start_async_i[AXIS_Y]),
    .cal_stop_async_i    (cal_stop_async_i[AXIS_Y]),
    .input_sel_i         (input_sel_i),
    .conv_arm_i          (conv_arm_i[AXIS_Y]),
    .fifo_clr_i          (fifo_clr_i),
    .soft_reset_i        (soft_reset_i),
    .max_hits_i          (max_hits_i),
    .ro_slow_code_i      (ro_slow_code_i),
    .ro_fast_code_i      (ro_fast_code_i),
    .pkt_valid_o         (pkt_valid_o[AXIS_Y]),
    .pkt_ready_i         (pkt_ready_i[AXIS_Y]),
    .pkt_data_o          (pkt_data_o[AXIS_Y*TDC_PKT_W +: TDC_PKT_W]),
    .pkt_sop_o           (pkt_sop_o[AXIS_Y]),
    .pkt_eop_o           (pkt_eop_o[AXIS_Y]),
    .packet_active_o     (packet_active_o[AXIS_Y]),
    .packet_pending_o    (packet_pending_o[AXIS_Y]),
    .ready_o             (ready_o[AXIS_Y]),
    .busy_o              (busy_o[AXIS_Y]),
    .fifo_full_o         (fifo_full_o[AXIS_Y]),
    .stop_armed_o        (stop_armed_o[AXIS_Y])
  );

  spadmic_tdc_axis_wrapper u_tdc_b (
    .clk_sys             (clk_sys),
    .clk_ref_40m         (clk_ref_40m),
    .async_rst_n         (async_rst_n),
    .global_enable_i     (global_enable_i),
    .axis_enable_i       (axis_enable_i[AXIS_B]),
    .spad_event_async_i  (spad_event_async_i[AXIS_B]),
    .cal_start_async_i   (cal_start_async_i[AXIS_B]),
    .cal_stop_async_i    (cal_stop_async_i[AXIS_B]),
    .input_sel_i         (input_sel_i),
    .conv_arm_i          (conv_arm_i[AXIS_B]),
    .fifo_clr_i          (fifo_clr_i),
    .soft_reset_i        (soft_reset_i),
    .max_hits_i          (max_hits_i),
    .ro_slow_code_i      (ro_slow_code_i),
    .ro_fast_code_i      (ro_fast_code_i),
    .pkt_valid_o         (pkt_valid_o[AXIS_B]),
    .pkt_ready_i         (pkt_ready_i[AXIS_B]),
    .pkt_data_o          (pkt_data_o[AXIS_B*TDC_PKT_W +: TDC_PKT_W]),
    .pkt_sop_o           (pkt_sop_o[AXIS_B]),
    .pkt_eop_o           (pkt_eop_o[AXIS_B]),
    .packet_active_o     (packet_active_o[AXIS_B]),
    .packet_pending_o    (packet_pending_o[AXIS_B]),
    .ready_o             (ready_o[AXIS_B]),
    .busy_o              (busy_o[AXIS_B]),
    .fifo_full_o         (fifo_full_o[AXIS_B]),
    .stop_armed_o        (stop_armed_o[AXIS_B])
  );

endmodule

`default_nettype wire
