`timescale 1ps/1ps
`default_nettype none

module tb_pd_gate_false_hit_unit;
  import mptdc_pkg::*;

  logic rst_n;
  logic clear_window;
  logic slow_phase;
  logic fast_phase;
  logic detect_en;
  logic [NFAST_W-1:0] nfast_tag;
  wire hit_level;
  wire [NFAST_W-1:0] nfast_hit;

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

  task automatic fast_tick(input logic [NFAST_W-1:0] count_value);
    begin
      nfast_tag = count_value;
      #5 fast_phase = 1'b1;
      #5 fast_phase = 1'b0;
      #1;
    end
  endtask

  initial begin
    rst_n = 1'b0;
    clear_window = 1'b0;
    slow_phase = 1'b0;
    fast_phase = 1'b0;
    detect_en = 1'b0;
    nfast_tag = '0;

    #20 rst_n = 1'b1;

    // Prime the PD pipeline with a high slow input, matching the case where the
    // real slow tap is high before clk_sys-side teardown starts.
    slow_phase = 1'b1;
    detect_en = 1'b1;
    fast_tick(7'd1);
    fast_tick(7'd2);
    if (hit_level !== 1'b0) begin
      $error("hit_level asserted before any falling input was presented");
      $finish;
    end

    // O2 no longer gates slow_phase with pd_enable.  If detection is disabled
    // before teardown, a forced-low sampled input must not fabricate a hit.
    detect_en = 1'b0;
    slow_phase = 1'b0;
    fast_tick(7'd3);
    fast_tick(7'd4);
    if (hit_level !== 1'b0) begin
      $error("detect_en=0 allowed forced-low input to create a false hit");
      $finish;
    end

    // Detection still works when enabled for a real falling edge.
    clear_window = 1'b1;
    #1;
    clear_window = 1'b0;
    #10;
    slow_phase = 1'b1;
    detect_en = 1'b1;
    fast_tick(7'd5);
    fast_tick(7'd6);
    slow_phase = 1'b0;
    fast_tick(7'd7);
    fast_tick(7'd8);
    if (hit_level !== 1'b1) begin
      $error("expected enabled falling-edge detection to latch a hit");
      $finish;
    end
    if (nfast_hit !== 7'd8) begin
      $error("unexpected nfast_hit value after real hit: got %0d", nfast_hit);
      $finish;
    end

    clear_window = 1'b1;
    #1;
    clear_window = 1'b0;
    #10;
    if (hit_level !== 1'b0) begin
      $error("hit_level did not clear");
      $finish;
    end

    $display("PASS tb_pd_gate_false_hit_unit: detect_en blocks forced-low false hit");
    $finish;
  end
endmodule

`default_nettype wire
