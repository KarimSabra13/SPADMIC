// ============================================================================
// Stress test: spadmic_axis_cluster_scan
// Tests: empty/full bitmaps, edge bits, gap sweep, overflow, and random patterns.
// ============================================================================
`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_stress_cluster_scan;

  import spadmic_pkg::*;

  localparam int CLK_PERIOD = 6250;
  localparam int W = SPADMIC_LINE_W;
  localparam int LAST = W - 1;
  localparam int LAST_EVEN = LAST & ~1;

  logic clk_sys;
  logic rst_n;
  logic start;
  logic busy;
  logic valid;
  logic [W-1:0] lines;
  logic [6:0]   gap_threshold;
  spadmic_pkg::spadmic_axis_clusters_t clusters;

  wire valid_cluster = !clusters.empty;
  wire [1:0] cluster_count = clusters.cluster_count;
  wire [SPADMIC_LINE_IDX_W-1:0] c0_min = clusters.cluster0.lo;
  wire [SPADMIC_LINE_IDX_W-1:0] c0_max = clusters.cluster0.hi;
  wire [SPADMIC_LINE_IDX_W-1:0] c1_min = clusters.cluster1.lo;
  wire [SPADMIC_LINE_IDX_W-1:0] c1_max = clusters.cluster1.hi;
  wire overflow = clusters.overflow;

  initial clk_sys = 1'b0;
  always #(CLK_PERIOD/2) clk_sys = ~clk_sys;

  spadmic_axis_cluster_scan #(.LINE_W(W)) dut (
    .clk_sys        (clk_sys),
    .rst_n          (rst_n),
    .start_i        (start),
    .lines_i        (lines),
    .gap_threshold_i(gap_threshold),
    .busy_o         (busy),
    .valid_o        (valid),
    .clusters_o     (clusters)
  );

  int pass_count = 0;
  int fail_count = 0;
  int test_num = 0;

  task automatic check(string name, logic cond);
    test_num++;
    if (cond) begin
      $display("[PASS] T%0d: %s", test_num, name);
      pass_count++;
    end else begin
      $display("[FAIL] T%0d: %s", test_num, name);
      fail_count++;
    end
  endtask

  task automatic run_scan(input logic [W-1:0] pattern, input logic [6:0] threshold);
    @(posedge clk_sys);
    #1;
    lines = pattern;
    gap_threshold = threshold;
    start = 1'b1;
    @(posedge clk_sys);
    #1;
    start = 1'b0;
    while (!valid)
      @(posedge clk_sys);
    #1;
  endtask

  initial begin
    logic [W-1:0] pattern;

    $display("========================================");
    $display("STRESS TEST: spadmic_axis_cluster_scan");
    $display("========================================");

    rst_n = 1'b0;
    start = 1'b0;
    lines = '0;
    gap_threshold = 7'd3;
    repeat (4) @(posedge clk_sys);
    rst_n = 1'b1;
    repeat (2) @(posedge clk_sys);

    pattern = '0;
    run_scan(pattern, 7'd3);
    check("empty bitmap -> invalid", valid_cluster === 1'b0);
    check("empty -> count=0", cluster_count === 2'd0);

    pattern = {W{1'b1}};
    run_scan(pattern, 7'd3);
    check("all-ones valid", valid_cluster === 1'b1);
    check("all-ones 1 cluster", cluster_count === 2'd1);
    check("all-ones c0=[0,LAST]", c0_min === 7'd0 && c0_max === SPADMIC_LINE_IDX_W'(LAST));
    check("all-ones no overflow", overflow === 1'b0);

    pattern = '0;
    pattern[0] = 1'b1;
    run_scan(pattern, 7'd3);
    check("bit[0] 1 cluster", cluster_count === 2'd1);
    check("bit[0] c0=[0,0]", c0_min === 7'd0 && c0_max === 7'd0);

    pattern = '0;
    pattern[LAST] = 1'b1;
    run_scan(pattern, 7'd3);
    check("bit[LAST] 1 cluster", cluster_count === 2'd1);
    check("bit[LAST] c0=[LAST,LAST]",
          c0_min === SPADMIC_LINE_IDX_W'(LAST) && c0_max === SPADMIC_LINE_IDX_W'(LAST));

    pattern = '0;
    for (int i = 10; i <= 15; i++) pattern[i] = 1'b1;
    for (int i = 50; i <= 55; i++) pattern[i] = 1'b1;
    run_scan(pattern, 7'd3);
    check("two clusters count=2", cluster_count === 2'd2);
    check("two clusters c0=[10,15]", c0_min === 7'd10 && c0_max === 7'd15);
    check("two clusters c1=[50,55]", c1_min === 7'd50 && c1_max === 7'd55);

    pattern = '0;
    for (int i = 0; i <= 3; i++) pattern[i] = 1'b1;
    for (int i = 25; i <= 28; i++) pattern[i] = 1'b1;
    for (int i = 50; i <= 53; i++) pattern[i] = 1'b1;
    run_scan(pattern, 7'd3);
    check("three clusters overflow", overflow === 1'b1);
    check("three clusters retain count=2", cluster_count === 2'd2);

    for (int g = 1; g <= 10; g++) begin
      pattern = '0;
      for (int i = 20; i <= 25; i++) pattern[i] = 1'b1;
      for (int i = 26 + g; i <= 31 + g; i++) begin
        if (i < W) pattern[i] = 1'b1;
      end
      run_scan(pattern, SPADMIC_LINE_COUNT_W'(g));
      check($sformatf("gap=%0d threshold=%0d -> split", g, g), cluster_count === 2'd2);
    end

    pattern = '0;
    for (int i = 0; i < W; i += 2) pattern[i] = 1'b1;
    run_scan(pattern, 7'd2);
    check("alternating gap=2 -> 1 cluster", cluster_count === 2'd1);
    check("alternating c0=[0,LAST_EVEN]",
          c0_min === 7'd0 && c0_max === SPADMIC_LINE_IDX_W'(LAST_EVEN));

    run_scan(pattern, 7'd1);
    check("alternating gap=1 -> overflow", overflow === 1'b1);

    pattern = '0;
    for (int i = 0; i <= 9; i++) pattern[i] = 1'b1;
    for (int i = LAST - 9; i <= LAST; i++) pattern[i] = 1'b1;
    run_scan(pattern, 7'd3);
    check("two ends count=2", cluster_count === 2'd2);
    check("two ends c0=[0,9]", c0_min === 7'd0 && c0_max === 7'd9);
    check("two ends c1=[LAST-9,LAST]",
          c1_min === SPADMIC_LINE_IDX_W'(LAST - 9) && c1_max === SPADMIC_LINE_IDX_W'(LAST));

    begin
      logic [31:0] lfsr;
      lfsr = 32'hDEAD_BEEF;
      for (int trial = 0; trial < 50; trial++) begin
        for (int b = 0; b < W; b++) begin
          lfsr = {lfsr[30:0], lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0]};
          pattern[b] = lfsr[0];
        end
        run_scan(pattern, 7'd5);
        check($sformatf("random[%0d] no X in valid", trial),
              valid_cluster === 1'b1 || valid_cluster === 1'b0);
      end
    end

    pattern = '0;
    for (int i = 30; i <= 40; i++) pattern[i] = 1'b1;
    for (int i = 45; i <= 55; i++) pattern[i] = 1'b1;
    run_scan(pattern, 7'd5);
    check("gap=4 < threshold=5 -> 1 cluster", cluster_count === 2'd1);
    check("merged c0=[30,55]", c0_min === 7'd30 && c0_max === 7'd55);

    pattern = '0;
    for (int i = 30; i <= 40; i++) pattern[i] = 1'b1;
    for (int i = 46; i <= 55; i++) pattern[i] = 1'b1;
    run_scan(pattern, 7'd5);
    check("gap=5 == threshold=5 -> 2 clusters", cluster_count === 2'd2);

    $display("========================================");
    $display("CLUSTER SCAN STRESS: %0d PASS, %0d FAIL out of %0d",
             pass_count, fail_count, test_num);
    $display("========================================");
    if (fail_count > 0) $fatal(1, "STRESS TEST FAILED");
    $finish;
  end

endmodule

`default_nettype wire
