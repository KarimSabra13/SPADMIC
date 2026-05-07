`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_correlated_tx_raw_unit;
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  localparam int CLK_PERIOD = 6250;

  logic clk_sys;
  logic rst_n;
  logic shared_ready;
  logic pos_valid;
  logic [NARROW_W-1:0] pos_data;
  wire  pos_ready;
  wire  shared_valid;
  wire [NARROW_W-1:0] shared_data;
  wire  correlation_overflow;

  logic [NARROW_W-1:0] pos_words [0:SPADMIC_POS_RAW_PKT_WORDS-1];
  logic [NARROW_W-1:0] out_words [0:SPADMIC_POS_RAW_PKT_WORDS-1];
  int pos_idx;
  int out_idx;
  int pass_count;
  int fail_count;

  initial clk_sys = 1'b0;
  always #(CLK_PERIOD/2) clk_sys = ~clk_sys;

  spadmic_correlated_tx dut (
    .clk_sys         (clk_sys),
    .rst_n           (rst_n),
    .tx_sel_i        (SPADMIC_TX_POSITION),
    .axis_enable_i   (3'b000),
    .position_enable_i(1'b1),
    .tdc_valid_i     (1'b0),
    .tdc_data_i      ('0),
    .tdc_ready_o     (),
    .pos_valid_i     (pos_valid),
    .pos_data_i      (pos_data),
    .pos_ready_o     (pos_ready),
    .shared_ready_i  (shared_ready),
    .shared_valid_o  (shared_valid),
    .shared_data_o   (shared_data),
    .correlation_overflow_o(correlation_overflow)
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

  always_comb begin
    pos_valid = (pos_idx < SPADMIC_POS_RAW_PKT_WORDS);
    pos_data  = pos_valid ? pos_words[pos_idx] : '0;
  end

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      pos_idx <= 0;
      out_idx <= 0;
    end else begin
      if (pos_valid && pos_ready)
        pos_idx <= pos_idx + 1;
      if (shared_valid && shared_ready) begin
        out_words[out_idx] <= shared_data;
        out_idx <= out_idx + 1;
      end
    end
  end

  initial begin
    for (int i = 0; i < SPADMIC_POS_RAW_PKT_WORDS; i++)
      pos_words[i] = 16'h0000;

    pos_words[0] = spadmic_pos_raw_header_word(3'b111);
    for (int i = 1; i <= SPADMIC_POS_RAW_PAYLOAD_WORDS; i++)
      pos_words[i] = i;

    pos_words[2]                          = 16'hFFFF;
    pos_words[5]                          = 16'h8123;
    pos_words[7]                          = 16'hC123;
    pos_words[SPADMIC_POS_RAW_PKT_WORDS-2] = 16'hF00D;
    pos_words[SPADMIC_POS_RAW_PKT_WORDS-1] = 16'hCAFE;
  end

  initial begin
    rst_n        = 1'b0;
    shared_ready = 1'b1;
    pass_count   = 0;
    fail_count   = 0;

    repeat (4) @(posedge clk_sys);
    #1;
    rst_n = 1'b1;

    while (out_idx < SPADMIC_POS_RAW_PKT_WORDS)
      @(posedge clk_sys);

    repeat (2) @(posedge clk_sys);
    #1;

    check("Raw position packet drained completely", pos_idx == SPADMIC_POS_RAW_PKT_WORDS);
    check("Raw output count is fixed length", out_idx == SPADMIC_POS_RAW_PKT_WORDS);
    check("Raw header forwarded", out_words[0] == spadmic_pos_raw_header_word(3'b111));
    check("EOC-like raw payload 0xFFFF preserved", out_words[2] == 16'hFFFF);
    check("Header-like raw payload 0x8123 preserved", out_words[5] == 16'h8123);
    check("EOC-like raw payload 0xC123 preserved", out_words[7] == 16'hC123);
    check("EOC-like raw payload 0xF00D preserved", out_words[SPADMIC_POS_RAW_PKT_WORDS-2] == 16'hF00D);
    check("Only raw final word is event-ID patched", out_words[SPADMIC_POS_RAW_PKT_WORDS-1] == 16'hC000);
    check("No correlation overflow in raw packet", correlation_overflow == 1'b0);

    if (fail_count != 0)
      $fatal(1, "tb_spadmic_correlated_tx_raw_unit: %0d failures", fail_count);

    $display("tb_spadmic_correlated_tx_raw_unit: %0d pass / %0d fail", pass_count, fail_count);
    $finish;
  end

  initial begin
    #200_000_000;
    $fatal(1, "TIMEOUT");
  end

endmodule

`default_nettype wire
