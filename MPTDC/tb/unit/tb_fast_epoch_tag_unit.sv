`timescale 1ps/1ps
`default_nettype none

module tb_fast_epoch_tag_unit;
  import mptdc_pkg::*;

  logic clk_fast;
  logic rst_n;
  logic clear_window;
  logic enable_i;
  logic [NFAST_W-1:0] tag;

  int pass_cnt;
  int fail_cnt;

  mptdc_fast_epoch_tag u_dut (
    .clk_fast     (clk_fast),
    .rst_n        (rst_n),
    .clear_window (clear_window),
    .enable_i     (enable_i),
    .tag_o        (tag)
  );

  task automatic tick();
    begin
      #5 clk_fast = 1'b1;
      #5 clk_fast = 1'b0;
      #1;
    end
  endtask

  task automatic check(input bit cond, input string label);
    if (cond) begin
      $display("[PASS] %s", label);
      pass_cnt++;
    end else begin
      $display("[FAIL] %s", label);
      fail_cnt++;
    end
  endtask

  initial begin
    logic [NFAST_W-1:0] expected;
    logic [127:0] seen;

    pass_cnt = 0;
    fail_cnt = 0;
    clk_fast = 1'b0;
    rst_n = 1'b0;
    clear_window = 1'b0;
    enable_i = 1'b0;

    tick();
    #20 rst_n = 1'b1;
    #1;
    check(tag == FAST_TAG_SEED, "reset loads non-zero seed");

    expected = fast_tag_next(FAST_TAG_SEED);
    tick();
    check(tag == expected, "tag advances every clock edge with enable=0 ignored");

    enable_i = 1'b1;
    expected = fast_tag_next(expected);
    tick();
    check(tag == expected, "tag also advances with enable=1");

    enable_i = 1'b0;
    expected = fast_tag_next(expected);
    tick();
    check(tag == expected, "enable input does not gate the muxless tag");

    clear_window = 1'b1;
    #1;
    check(tag == FAST_TAG_SEED, "clear_window asynchronously reloads seed");
    clear_window = 1'b0;
    #1;

    seen = '0;
    expected = FAST_TAG_SEED;
    for (int i = 0; i < FAST_TAG_SEQUENCE_LEN; i++) begin
      check(expected != '0, $sformatf("sequence state %0d is non-zero", i));
      check(!seen[int'(expected)], $sformatf("sequence state %0d not repeated early", i));
      seen[int'(expected)] = 1'b1;
      expected = fast_tag_next(expected);
    end
    check(expected == FAST_TAG_SEED, "maximal 127-state sequence returns to seed");

    $display("===================================");
    $display("  Results: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
    $display("===================================");
    if (fail_cnt != 0)
      $fatal(1, "tb_fast_epoch_tag_unit failed");
    $display("TEST PASSED");
    $finish;
  end

  initial begin
    #1_000_000;
    $fatal(1, "tb_fast_epoch_tag_unit timeout");
  end
endmodule

`default_nettype wire
