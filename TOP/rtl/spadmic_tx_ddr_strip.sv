// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_tx_ddr_strip.sv
// Purpose  : Wide, shallow DDRs2-facing half of the split TX egress path.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_tx_ddr_strip #(
  parameter bit FORWARDED_CLK_INVERT = 1'b0
) (
  input  wire logic                                      clk_sys,
  input  wire logic                                      clk_160m_i,
  input  wire logic                                      rst_n,
  input  wire logic                                      ddrs2_enable_i,

  input  wire logic                                      tx_valid_i,
  output logic                                      tx_ready_o,
  input  wire logic [mptdc_pkg::NARROW_W-1:0]            tx_data_i,
  input  wire logic                                      tx_flush_i,

  output logic                                      ddr_pair_valid_o,
  output logic                                      ddr_padded_o,
  output logic                                      ddr_busy_o,
  output logic                                      ddr_empty_o,

  output logic [spadmic_pkg::SPADMIC_DDRS2_LANE_W-1:0] ddrs2_data_l_o,
  output logic [spadmic_pkg::SPADMIC_DDRS2_LANE_W-1:0] ddrs2_data_h_o,
  output logic                                      ddrs2_clk_160m_o
);
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  logic [SPADMIC_DDR16_PHY_W-1:0] ddr_data_l;
  logic [SPADMIC_DDR16_PHY_W-1:0] ddr_data_h;
  logic ddr_clk_unused;

  wire tx_word_valid = tx_valid_i && !tx_flush_i;
  wire tx_flush_valid = tx_valid_i && tx_flush_i;

  spadmic_ddr16_tx_pairer u_ddr16_pairer (
    .clk_sys          (clk_sys),
    .rst_n            (rst_n),
    .word_valid_i     (tx_word_valid),
    .word_data_i      (tx_data_i),
    .flush_i          (tx_flush_valid),
    .word_ready_o     (tx_ready_o),
    .ddr_data_l_o     (ddr_data_l),
    .ddr_data_h_o     (ddr_data_h),
    .ddr_pair_valid_o (ddr_pair_valid_o),
    .ddr_padded_o     (ddr_padded_o),
    .ddr_clk_o        (ddr_clk_unused),
    .busy_o           (ddr_busy_o),
    .empty_o          (ddr_empty_o)
  );

  spadmic_ddrs2_adapter #(
    .FORWARDED_CLK_INVERT(FORWARDED_CLK_INVERT)
  ) u_ddrs2_adapter (
    .clk_160m_i       (clk_160m_i),
    .rst_n            (rst_n),
    .enable_i         (ddrs2_enable_i),
    .ddr_data_l_i     (ddr_data_l),
    .ddr_data_h_i     (ddr_data_h),
    .ddr_pair_valid_i (ddr_pair_valid_o),
    .ddrs2_data_l_o   (ddrs2_data_l_o),
    .ddrs2_data_h_o   (ddrs2_data_h_o),
    .ddrs2_clk_160m_o (ddrs2_clk_160m_o)
  );

endmodule

`default_nettype wire
