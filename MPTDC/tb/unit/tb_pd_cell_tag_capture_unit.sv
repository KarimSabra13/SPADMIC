`timescale 1ps/1ps
`default_nettype none

module tb_pd_cell_tag_capture_unit;
  import mptdc_pkg::*;

  logic rst_n;
  logic clear_window;
  logic slow_phase;
  logic fast_phase;
  logic detect_en;
  logic [NFAST_W-1:0] nfast_tag;
  wire hit_level;
  wire [NFAST_W-1:0] nfast_hit;

  int pass_cnt;
  int fail_cnt;

  mptdc_pd_cell #(.SAMPLE_DEPTH(2)) dut (
    .rst_n        (rst_n),
    .clear_window (clear_window),
    .slow_phase   (slow_phase),
    .fast_phase   (fast_phase),
    .detect_en_i  (detect_en),
    .nfast_tag_i  (nfast_tag),
    .hit_level    (hit_level),
    .nfast_hit    (nfast_hit)
  );

  task automatic fast_tick(input logic [NFAST_W-1:0] tag_value);
    begin
      nfast_tag = tag_value;
      #5 fast_phase = 1'b1;
      #5 fast_phase = 1'b0;
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

  task automatic async_clear();
    begin
      clear_window = 1'b1;
      #1;
      clear_window = 1'b0;
      #10;
    end
  endtask

  initial begin
    pass_cnt = 0;
    fail_cnt = 0;
    rst_n = 1'b0;
    clear_window = 1'b0;
    slow_phase = 1'b0;
    fast_phase = 1'b0;
    detect_en = 1'b0;
    nfast_tag = '0;

    #20 rst_n = 1'b1;
    #1;

    // detect_en=0 freezes the sampler, so forcing slow low during teardown
    // cannot fabricate a falling-edge hit.
    slow_phase = 1'b1;
    detect_en = 1'b1;
    fast_tick(7'd1);
    fast_tick(7'd2);
    detect_en = 1'b0;
    slow_phase = 1'b0;
    fast_tick(7'd3);
    fast_tick(7'd4);
    check(hit_level == 1'b0, "detect_en=0 prevents forced-low false hit");

    async_clear();
    check(hit_level == 1'b0, "clear leaves hit low");

    // A real falling edge while detection is enabled latches the current local
    // tag and holds it even as the tag input continues changing.
    detect_en = 1'b1;
    slow_phase = 1'b1;
    fast_tick(7'd10);
    fast_tick(7'd11);
    check(hit_level == 1'b0, "no hit before falling edge");

    slow_phase = 1'b0;
    fast_tick(7'd12);
    check(hit_level == 1'b0, "first edge after slow fall only arms detector");
    fast_tick(7'd13);
    check(hit_level == 1'b1, "second edge after slow fall latches hit");
    check(nfast_hit == 7'd13, "hit captures current local tag");

    fast_tick(7'd42);
    check(hit_level == 1'b1, "hit remains latched");
    check(nfast_hit == 7'd13, "captured tag remains stable after hit");

    async_clear();
    check(hit_level == 1'b0, "clear_window clears hit");

    // O5 intentionally removes hardware reset/clear from the timestamp shadow
    // flops.  The field is ignored while hit_level=0, then overwritten by the
    // local tag before the next valid hit.
    detect_en = 1'b0;
    nfast_tag = 7'd99;
    fast_tick(7'd99);
    check(hit_level == 1'b0, "no-hit cell keeps nfast ignored after clear");

    detect_en = 1'b1;
    slow_phase = 1'b1;
    fast_tick(7'd20);
    fast_tick(7'd21);
    slow_phase = 1'b0;
    fast_tick(7'd22);
    fast_tick(7'd23);
    check(hit_level == 1'b1, "post-clear falling edge latches hit");
    check(nfast_hit == 7'd23, "post-clear hit overwrites stale timestamp");

    $display("===================================");
    $display("  Results: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
    $display("===================================");
    if (fail_cnt != 0)
      $fatal(1, "tb_pd_cell_tag_capture_unit failed");
    $display("TEST PASSED");
    $finish;
  end

  initial begin
    #1_000_000;
    $fatal(1, "tb_pd_cell_tag_capture_unit timeout");
  end
endmodule

`default_nettype wire
