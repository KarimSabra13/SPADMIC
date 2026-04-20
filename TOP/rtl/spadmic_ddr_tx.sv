// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_ddr_tx.sv
// Purpose  : Repack the internal 16-bit logical packet stream onto the
//            silicon-facing 8-bit DDR source-synchronous TX bus.
// Author   : Karim Sabra
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_ddr_tx (
  input  wire                                clk_sys,
  input  wire                                rst_n,
  input  wire                                word_valid_i,
  input  wire [mptdc_pkg::NARROW_W-1:0]      word_data_i,
  output wire                                word_ready_o,
  output wire                                chip_tx_clk_o,
  output logic                               chip_tx_valid_o,
  output logic [spadmic_pkg::SPADMIC_TX_PHY_W-1:0] chip_tx_data_o
);
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  logic [NARROW_W-1:0] word_q;

  // The physical TX has no off-chip backpressure; the upstream correlated TX can
  // retire one logical word every clk_sys cycle.
  assign word_ready_o   = 1'b1;
  assign chip_tx_clk_o  = clk_sys;

  always @(posedge clk_sys or negedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      chip_tx_valid_o <= 1'b0;
      chip_tx_data_o <= '0;
      word_q         <= '0;
    end else if (clk_sys) begin
      chip_tx_valid_o <= word_valid_i;
      word_q          <= word_data_i;
      chip_tx_data_o  <= word_valid_i ? word_data_i[7:0] : '0;
    end else begin
      chip_tx_data_o  <= chip_tx_valid_o ? word_q[15:8] : '0;
    end
  end

endmodule

`default_nettype wire
