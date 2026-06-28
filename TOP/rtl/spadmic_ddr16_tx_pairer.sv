// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_ddr16_tx_pairer.sv
// Purpose  : Single-edge logical word pairer for final 16-bit DDR macro wrapper.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_ddr16_tx_pairer (
  input  logic        clk_sys,
  input  logic        rst_n,
  input  logic        word_valid_i,
  input  logic [15:0] word_data_i,
  input  logic        flush_i,
  output logic        word_ready_o,
  output logic [15:0] ddr_data_l_o,
  output logic [15:0] ddr_data_h_o,
  output logic        ddr_pair_valid_o,
  output logic        ddr_padded_o,
  output logic        ddr_clk_o,
  output logic        busy_o,
  output logic        empty_o
);

  logic        half_full_q;
  logic [15:0] half_word_q;

  assign ddr_clk_o     = clk_sys;
  assign word_ready_o  = 1'b1;
  assign busy_o        = half_full_q || ddr_pair_valid_o;
  assign empty_o       = !half_full_q && !ddr_pair_valid_o;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      half_full_q      <= 1'b0;
      half_word_q      <= '0;
      ddr_data_l_o     <= '0;
      ddr_data_h_o     <= '0;
      ddr_pair_valid_o <= 1'b0;
      ddr_padded_o     <= 1'b0;
    end else begin
      ddr_pair_valid_o <= 1'b0;
      ddr_padded_o     <= 1'b0;

      if (word_valid_i) begin
        if (half_full_q) begin
          ddr_data_l_o     <= half_word_q;
          ddr_data_h_o     <= word_data_i;
          ddr_pair_valid_o <= 1'b1;
          half_full_q      <= 1'b0;
          half_word_q      <= '0;
        end else begin
          half_word_q <= word_data_i;
          half_full_q <= 1'b1;
        end
      end else if (flush_i && half_full_q) begin
        ddr_data_l_o     <= half_word_q;
        ddr_data_h_o     <= 16'h0000;
        ddr_pair_valid_o <= 1'b1;
        ddr_padded_o     <= 1'b1;
        half_full_q      <= 1'b0;
        half_word_q      <= '0;
      end else if (!ddr_pair_valid_o) begin
        ddr_data_l_o <= '0;
        ddr_data_h_o <= '0;
      end
    end
  end

endmodule

`default_nettype wire
