`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_ddr16_tx_pairer_unit;
  localparam int CLK_PERIOD = 6250;

  logic clk_sys;
  logic rst_n;
  logic word_valid;
  logic [15:0] word_data;
  logic flush;
  wire word_ready;
  wire [15:0] ddr_data_l;
  wire [15:0] ddr_data_h;
  wire ddr_pair_valid;
  wire ddr_padded;
  wire ddr_clk;
  wire busy;
  wire empty;
  int pass_count;
  int fail_count;

  initial clk_sys = 1'b0;
  always #(CLK_PERIOD/2) clk_sys = ~clk_sys;

  spadmic_ddr16_tx_pairer dut (
    .clk_sys(clk_sys),
    .rst_n(rst_n),
    .word_valid_i(word_valid),
    .word_data_i(word_data),
    .flush_i(flush),
    .word_ready_o(word_ready),
    .ddr_data_l_o(ddr_data_l),
    .ddr_data_h_o(ddr_data_h),
    .ddr_pair_valid_o(ddr_pair_valid),
    .ddr_padded_o(ddr_padded),
    .ddr_clk_o(ddr_clk),
    .busy_o(busy),
    .empty_o(empty)
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

  task automatic send_word(input logic [15:0] data);
    begin
      @(negedge clk_sys);
      word_valid = 1'b1;
      word_data  = data;
      @(negedge clk_sys);
      word_valid = 1'b0;
      word_data  = '0;
    end
  endtask

  initial begin
    pass_count = 0;
    fail_count = 0;
    rst_n      = 1'b0;
    word_valid = 1'b0;
    word_data  = '0;
    flush      = 1'b0;

    repeat (3) @(posedge clk_sys);
    rst_n = 1'b1;
    repeat (2) @(posedge clk_sys);
    #1;
    check("reset leaves pairer empty", empty);
    check("word interface ready", word_ready);
    check("DDR clock follows clk_sys", ddr_clk == clk_sys);

    send_word(16'h1111);
    #1;
    check("single word makes pairer busy", busy && !empty);
    send_word(16'h2222);
    #1;
    check("two words produce valid pair", ddr_pair_valid);
    check("older word appears on DATA_L", ddr_data_l == 16'h1111);
    check("newer word appears on DATA_H", ddr_data_h == 16'h2222);
    check("real pair is not padded", !ddr_padded);

    send_word(16'h3333);
    @(negedge clk_sys);
    flush = 1'b1;
    @(negedge clk_sys);
    flush = 1'b0;
    #1;
    check("flush emits odd final word", ddr_pair_valid);
    check("odd word uses DATA_L", ddr_data_l == 16'h3333);
    check("odd word pads DATA_H with zero", ddr_data_h == 16'h0000);
    check("odd flush reports padded pair", ddr_padded);

    repeat (2) @(posedge clk_sys);
    #1;
    check("idle data returns to zero", ddr_data_l == 16'h0000 && ddr_data_h == 16'h0000);
    check("pairer empty after flush", empty);

    if (fail_count != 0)
      $fatal(1, "tb_spadmic_ddr16_tx_pairer_unit: %0d failures", fail_count);

    $display("tb_spadmic_ddr16_tx_pairer_unit: %0d pass / %0d fail", pass_count, fail_count);
    $finish;
  end

  initial begin
    #1_000_000;
    $fatal(1, "tb_spadmic_ddr16_tx_pairer_unit: TIMEOUT");
  end
endmodule

`default_nettype wire
