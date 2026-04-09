// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_tdc_axis_wrapper.sv
// Purpose  : Per-axis wrapper around the stop qualifier and one preserved
//            mptdc_top_asic instance.
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
  input  mptdc_pkg::input_sel_e     input_sel_override_i,
  input  mptdc_pkg::out_mode_e      out_mode_override_i,

  input  wire                       csr_valid_i,
  input  wire                       csr_write_i,
  input  wire [mptdc_pkg::CSR_ADDR_W-1:0] csr_addr_i,
  input  wire [mptdc_pkg::CSR_DATA_W-1:0] csr_wdata_i,
  output wire                       csr_ready_o,
  output wire                       csr_rvalid_o,
  output wire [mptdc_pkg::CSR_DATA_W-1:0] csr_rdata_o,

  input  wire                       acq_ready_i,
  output wire                       acq_valid_o,
  output wire [mptdc_pkg::ACQ_REC_W-1:0] acq_data_o,
  output wire                       fifo_full_o,

  output wire                       stop_armed_o
);
  wire start_async_gated;
  wire stop_async_qualified;

  // These enables are configured quiescently through CSR and are treated as
  // stable during active measurement, matching the existing MPTDC async-mux use.
  assign start_async_gated = spad_event_async_i & global_enable_i & axis_enable_i;

  // Convert the asynchronous SPAD event into exactly one qualified STOP pulse on
  // the next clk_ref_40m rising edge.
  spadmic_ref_stop_qualifier u_stop_qualifier (
    .rst_n         (async_rst_n),
    .start_async_i (start_async_gated),
    .clk_ref_40m   (clk_ref_40m),
    .stop_async_o  (stop_async_qualified),
    .armed_o       (stop_armed_o)
  );

  // The active top-level path uses the acquisition-record export interface. The
  // legacy per-axis narrow output stays tied off in this architecture.
  mptdc_top_asic u_tdc (
    .clk_sys            (clk_sys),
    .async_rst_n        (async_rst_n),
    .start_spad_async_i (start_async_gated),
    .stop_spad_async_i  (stop_async_qualified),
    .cal_start_async_i  (cal_start_async_i),
    .cal_stop_async_i   (cal_stop_async_i),
    .input_sel_override_en_i(1'b1),
    .input_sel_override_i(input_sel_override_i),
    .out_mode_override_en_i(1'b1),
    .out_mode_override_i(out_mode_override_i),
    .csr_valid_i        (csr_valid_i),
    .csr_write_i        (csr_write_i),
    .csr_addr_i         (csr_addr_i),
    .csr_wdata_i        (csr_wdata_i),
    .csr_ready_o        (csr_ready_o),
    .csr_rvalid_o       (csr_rvalid_o),
    .csr_rdata_o        (csr_rdata_o),
    .narrow_ready_i     (1'b0),
    .narrow_valid_o     (/* unused */),
    .narrow_data_o      (/* unused */),
    .shared_readout_en_i(1'b1),
    .acq_ready_i        (acq_ready_i),
    .acq_valid_o        (acq_valid_o),
    .acq_data_o         (acq_data_o),
    .fifo_full_o        (fifo_full_o)
  );

endmodule

`default_nettype wire
