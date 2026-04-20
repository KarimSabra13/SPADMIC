`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_ddr_tx_unit;
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  localparam int CLK_PERIOD = 6250;

  logic clk_sys;
  logic rst_n;
  logic word_valid;
  logic [NARROW_W-1:0] word_data;
  wire  word_ready;
  wire  chip_tx_clk;
  wire  chip_tx_valid;
  wire [SPADMIC_TX_PHY_W-1:0] chip_tx_data;

  logic [7:0] edge_bytes [0:5];
  int edge_idx;
  int pass_count;
  int fail_count;

  initial clk_sys = 1'b0;
  always #(CLK_PERIOD/2) clk_sys = ~clk_sys;

  spadmic_ddr_tx dut (
    .clk_sys        (clk_sys),
    .rst_n          (rst_n),
    .word_valid_i   (word_valid),
    .word_data_i    (word_data),
    .word_ready_o   (word_ready),
    .chip_tx_clk_o  (chip_tx_clk),
    .chip_tx_valid_o(chip_tx_valid),
    .chip_tx_data_o (chip_tx_data)
  );

  task automatic check(input string label, input logic cond);
    if (cond) begin
      $display("[PASS] %s", label);
      pass_count++;
    end else begin
      $display("[FAIL] %s", label);
      fail_count++;
    end
  endtask

  always @(posedge chip_tx_clk or negedge chip_tx_clk) begin
    if (rst_n && chip_tx_valid && (edge_idx < 6)) begin
      edge_bytes[edge_idx] = chip_tx_data;
      edge_idx++;
    end
  end

  initial begin
    rst_n      = 1'b0;
    word_valid = 1'b0;
    word_data  = '0;
    edge_idx   = 0;
    pass_count = 0;
    fail_count = 0;

    repeat (4) @(posedge clk_sys);
    #1;
    rst_n = 1'b1;

    check("Forwarded clock matches clk_sys high phase", chip_tx_clk === clk_sys);
    check("Word interface is always ready", word_ready === 1'b1);

    @(negedge clk_sys);
    word_valid = 1'b1;
    word_data  = 16'h1234;
    @(negedge clk_sys);
    word_data  = 16'hABCD;
    @(negedge clk_sys);
    word_data  = 16'h0F0E;
    @(negedge clk_sys);
    word_valid = 1'b0;
    word_data  = '0;

    repeat (2) @(posedge clk_sys);
    #1;

    check("Captured three DDR words", edge_idx == 6);
    check("Word0 low byte on rising edge", edge_bytes[0] == 8'h34);
    check("Word0 high byte on falling edge", edge_bytes[1] == 8'h12);
    check("Word1 low byte on rising edge", edge_bytes[2] == 8'hCD);
    check("Word1 high byte on falling edge", edge_bytes[3] == 8'hAB);
    check("Word2 low byte on rising edge", edge_bytes[4] == 8'h0E);
    check("Word2 high byte on falling edge", edge_bytes[5] == 8'h0F);
    check("TX valid drops after traffic", chip_tx_valid === 1'b0);
    check("Idle byte returns to zero", chip_tx_data === '0);

    if (fail_count != 0)
      $fatal(1, "tb_spadmic_ddr_tx_unit: %0d failures", fail_count);

    $display("tb_spadmic_ddr_tx_unit: %0d pass / %0d fail", pass_count, fail_count);
    $finish;
  end

  initial begin
    #200_000_000;
    $fatal(1, "TIMEOUT");
  end

endmodule

`default_nettype wire
