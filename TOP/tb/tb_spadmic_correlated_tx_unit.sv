`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_correlated_tx_unit;
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  localparam int CLK_PERIOD = 6250;
  localparam int TDC_WORDS  = 12;
  localparam int POS_WORDS  = 6;
  localparam int OUT_WORDS  = TDC_WORDS + POS_WORDS;

  logic clk_sys;
  logic rst_n;
  logic shared_ready;
  logic tdc_valid;
  logic [NARROW_W-1:0] tdc_data;
  wire  tdc_ready;
  logic pos_valid;
  logic [NARROW_W-1:0] pos_data;
  wire  pos_ready;
  wire  shared_valid;
  wire [NARROW_W-1:0] shared_data;
  wire  correlation_overflow;

  logic [NARROW_W-1:0] tdc_words [0:TDC_WORDS-1];
  logic [NARROW_W-1:0] pos_words [0:POS_WORDS-1];
  logic [NARROW_W-1:0] out_words [0:OUT_WORDS-1];
  int tdc_idx;
  int pos_idx;
  int out_idx;
  int pass_count;
  int fail_count;

  initial clk_sys = 1'b0;
  always #(CLK_PERIOD/2) clk_sys = ~clk_sys;

  spadmic_correlated_tx dut (
    .clk_sys         (clk_sys),
    .rst_n           (rst_n),
    .tx_sel_i        (SPADMIC_TX_TDC),
    .axis_enable_i   (3'b111),
    .position_enable_i(1'b1),
    .tdc_valid_i     (tdc_valid),
    .tdc_data_i      (tdc_data),
    .tdc_ready_o     (tdc_ready),
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
    tdc_valid = (tdc_idx < TDC_WORDS);
    tdc_data  = tdc_valid ? tdc_words[tdc_idx] : '0;
    pos_valid = (pos_idx < POS_WORDS);
    pos_data  = pos_valid ? pos_words[pos_idx] : '0;
  end

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      tdc_idx <= 0;
      pos_idx <= 0;
      out_idx <= 0;
    end else begin
      if (tdc_valid && tdc_ready)
        tdc_idx <= tdc_idx + 1;
      if (pos_valid && pos_ready)
        pos_idx <= pos_idx + 1;
      if (shared_valid && shared_ready) begin
        out_words[out_idx] <= shared_data;
        out_idx <= out_idx + 1;
      end
    end
  end

  initial begin
    // TDC stream: X0, X1, Y0, Z0, Y1, Z1.
    tdc_words[0]  = 16'h8001;  // X0 header
    tdc_words[1]  = 16'hC111;  // X0 eoc (patched)
    tdc_words[2]  = 16'h8002;  // X1 header
    tdc_words[3]  = 16'hC222;  // X1 eoc (patched)
    tdc_words[4]  = 16'h9101;  // Y0 header
    tdc_words[5]  = 16'hC333;  // Y0 eoc (patched)
    tdc_words[6]  = 16'h8241;  // Z0 header
    tdc_words[7]  = 16'hC444;  // Z0 eoc (patched)
    tdc_words[8]  = 16'h9102;  // Y1 header
    tdc_words[9]  = 16'hC555;  // Y1 eoc (patched)
    tdc_words[10] = 16'h8242;  // Z1 header
    tdc_words[11] = 16'hC666;  // Z1 eoc (patched)

    // Position stream: P0 then P1.
    pos_words[0] = 16'h9001;   // P0 header
    pos_words[1] = 16'hA031;   // P0 subheader source=POSITION
    pos_words[2] = 16'hC777;   // P0 eoc (patched)
    pos_words[3] = 16'h9002;   // P1 header
    pos_words[4] = 16'hA031;   // P1 subheader
    pos_words[5] = 16'hC888;   // P1 eoc (patched)
  end

  initial begin
    rst_n        = 1'b0;
    shared_ready = 1'b1;
    pass_count   = 0;
    fail_count   = 0;

    repeat (4) @(posedge clk_sys);
    #1;
    rst_n = 1'b1;

    while (out_idx < OUT_WORDS)
      @(posedge clk_sys);

    repeat (2) @(posedge clk_sys);
    #1;

    check("All TDC words drained", tdc_idx == TDC_WORDS);
    check("All position words drained", pos_idx == POS_WORDS);
    check("No correlation overflow", correlation_overflow == 1'b0);

    // Packet order under round-robin arbitration is:
    //   X0, P0, X1, P1, Y0, Z0, Y1, Z1.
    // Event 0: X0, P0, Y0, Z0 all share event ID 0.
    check("X0 event ID patched to 0", out_words[1]  == 16'hC000);
    check("P0 event ID patched to 0", out_words[4]  == 16'hC000);
    check("Y0 event ID patched to 0", out_words[11] == 16'hC000);
    check("Z0 event ID patched to 0", out_words[13] == 16'hC000);

    // Event 1: X1, P1, Y1, Z1 all share event ID 1.
    check("X1 event ID patched to 1", out_words[6]  == 16'hC001);
    check("P1 event ID patched to 1", out_words[9]  == 16'hC001);
    check("Y1 event ID patched to 1", out_words[15] == 16'hC001);
    check("Z1 event ID patched to 1", out_words[17] == 16'hC001);

    // Arbitration is packet-atomic: each packet drains completely before the
    // next one starts.
    check("Packet 0 stays atomic", out_words[0][15:13] == 3'b100 && out_words[1][15:14] == 2'b11);
    check("Packet 1 stays atomic", out_words[2][15:13] == 3'b100 && out_words[3][15:13] == 3'b101 && out_words[4][15:14] == 2'b11);
    check("Packet 2 stays atomic", out_words[5][15:13] == 3'b100 && out_words[6][15:14] == 2'b11);

    if (fail_count != 0)
      $fatal(1, "tb_spadmic_correlated_tx_unit: %0d failures", fail_count);

    $display("tb_spadmic_correlated_tx_unit: %0d pass / %0d fail", pass_count, fail_count);
    $finish;
  end

  initial begin
    #200_000_000;
    $fatal(1, "TIMEOUT");
  end

endmodule

`default_nettype wire
