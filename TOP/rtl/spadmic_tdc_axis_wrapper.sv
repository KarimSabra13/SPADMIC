`timescale 1ps/1ps
`default_nettype none

module spadmic_tdc_axis_wrapper (
  input  wire                       clk_sys,
  input  wire                       clk_ref_40m,
  input  wire                       async_rst_n,
  input  wire                       global_enable_i,
  input  wire                       axis_enable_i,
  input  wire                       spad_event_async_i,

  input  wire                       csr_valid_i,
  input  wire                       csr_write_i,
  input  wire [mptdc_pkg::CSR_ADDR_W-1:0] csr_addr_i,
  input  wire [mptdc_pkg::CSR_DATA_W-1:0] csr_wdata_i,
  output wire                       csr_ready_o,
  output wire                       csr_rvalid_o,
  output wire [mptdc_pkg::CSR_DATA_W-1:0] csr_rdata_o,

  input  wire                       narrow_ready_i,
  output wire                       narrow_valid_o,
  output wire [mptdc_pkg::NARROW_W-1:0] narrow_data_o,

  output wire                       stop_armed_o
);
  wire start_async_gated;
  wire stop_async_qualified;

  // These enables are configured quiescently through CSR and are treated as
  // stable during active measurement, matching the existing MPTDC async-mux use.
  assign start_async_gated = spad_event_async_i & global_enable_i & axis_enable_i;

  spadmic_ref_stop_qualifier u_stop_qualifier (
    .rst_n         (async_rst_n),
    .start_async_i (start_async_gated),
    .clk_ref_40m   (clk_ref_40m),
    .stop_async_o  (stop_async_qualified),
    .armed_o       (stop_armed_o)
  );

  mptdc_top_asic u_tdc (
    .clk_sys            (clk_sys),
    .async_rst_n        (async_rst_n),
    .start_spad_async_i (start_async_gated),
    .stop_spad_async_i  (stop_async_qualified),
    .cal_start_async_i  (1'b0),
    .cal_stop_async_i   (1'b0),
    .csr_valid_i        (csr_valid_i),
    .csr_write_i        (csr_write_i),
    .csr_addr_i         (csr_addr_i),
    .csr_wdata_i        (csr_wdata_i),
    .csr_ready_o        (csr_ready_o),
    .csr_rvalid_o       (csr_rvalid_o),
    .csr_rdata_o        (csr_rdata_o),
    .narrow_ready_i     (narrow_ready_i),
    .narrow_valid_o     (narrow_valid_o),
    .narrow_data_o      (narrow_data_o)
  );

endmodule

`default_nettype wire
