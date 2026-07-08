// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_ddrs2_adapter.sv
// Purpose  : Expand the internal DDR16 digital stream to the 19-lane DDRs2
//            analog/custom macro input contract.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_ddrs2_adapter #(
  parameter bit FORWARDED_CLK_INVERT = 1'b0
) (
  input  logic        clk_160m_i,
  input  logic        rst_n,
  input  logic        enable_i,
  input  logic [15:0] ddr_data_l_i,
  input  logic [15:0] ddr_data_h_i,
  input  logic        ddr_pair_valid_i,
  output logic [spadmic_pkg::SPADMIC_DDRS2_LANE_W-1:0] ddrs2_data_l_o,
  output logic [spadmic_pkg::SPADMIC_DDRS2_LANE_W-1:0] ddrs2_data_h_o,
  output logic        ddrs2_clk_160m_o
);

  import spadmic_pkg::*;

  logic active;

  assign active = rst_n && enable_i;
  assign ddrs2_clk_160m_o = clk_160m_i;

  always_comb begin
    ddrs2_data_l_o = '0;
    ddrs2_data_h_o = '0;

    if (active) begin
      ddrs2_data_l_o[SPADMIC_DDRS2_DATA_LANES-1:0] = ddr_data_l_i;
      ddrs2_data_h_o[SPADMIC_DDRS2_DATA_LANES-1:0] = ddr_data_h_i;

      ddrs2_data_l_o[SPADMIC_DDRS2_VALID_LANE] = ddr_pair_valid_i;
      ddrs2_data_h_o[SPADMIC_DDRS2_VALID_LANE] = ddr_pair_valid_i;

      ddrs2_data_l_o[SPADMIC_DDRS2_FWD_CLK_LANE] = FORWARDED_CLK_INVERT;
      ddrs2_data_h_o[SPADMIC_DDRS2_FWD_CLK_LANE] = ~FORWARDED_CLK_INVERT;

      ddrs2_data_l_o[SPADMIC_DDRS2_SPARE_LANE] = 1'b0;
      ddrs2_data_h_o[SPADMIC_DDRS2_SPARE_LANE] = 1'b0;
    end
  end

endmodule

`default_nettype wire
