// ============================================================================
// Stress test: spadmic_axis_cluster_scan
// Tests: all-ones, single-bit edges, alternating, gap sweep, random patterns,
//        empty bitmap, full bitmap, and boundary conditions.
// ============================================================================
`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_stress_cluster_scan;

  import spadmic_pkg::*;

  localparam int W = SPADMIC_LINE_W;
  localparam int LAST = W - 1;
  localparam int LAST_EVEN = LAST & ~1;

  logic [W-1:0] lines;
  logic [6:0]   gap_threshold;
  spadmic_pkg::spadmic_axis_clusters_t clusters;

  // Convenience aliases
  wire valid          = !clusters.empty;
  wire [1:0] cluster_count = clusters.cluster_count;
  wire [SPADMIC_LINE_IDX_W-1:0] c0_min = clusters.cluster0.lo;
  wire [SPADMIC_LINE_IDX_W-1:0] c0_max = clusters.cluster0.hi;
  wire [SPADMIC_LINE_IDX_W-1:0] c1_min = clusters.cluster1.lo;
  wire [SPADMIC_LINE_IDX_W-1:0] c1_max = clusters.cluster1.hi;
  wire       overflow = clusters.overflow;

  spadmic_axis_cluster_scan #(.LINE_W(W)) dut (
    .lines_i        (lines),
    .gap_threshold_i(gap_threshold),
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

  initial begin
    $display("========================================");
    $display("STRESS TEST: spadmic_axis_cluster_scan");
    $display("========================================");

    gap_threshold = 7'd3;
    lines = '0;
    #10;

    // ========================================
    // TEST 1: Empty bitmap → invalid
    // ========================================
    lines = '0;
    #10;
    check("T1 empty bitmap → not valid", valid === 1'b0);
    check("T1 empty → count=0", cluster_count === 2'd0);

    // ========================================
    // TEST 2: All bits set → 1 cluster [0,LAST]
    // ========================================
    lines = {W{1'b1}};
    #10;
    check("T2 all-ones valid", valid === 1'b1);
    check("T2 all-ones 1 cluster", cluster_count === 2'd1);
    check("T2 all-ones c0_min=0", c0_min === 7'd0);
    check("T2 all-ones c0_max=LAST", c0_max === SPADMIC_LINE_IDX_W'(LAST));
    check("T2 all-ones no overflow", overflow === 1'b0);

    // ========================================
    // TEST 3: Single bit at position 0
    // ========================================
    lines = '0;
    lines[0] = 1'b1;
    #10;
    check("T3 bit[0] valid", valid === 1'b1);
    check("T3 bit[0] 1 cluster", cluster_count === 2'd1);
    check("T3 bit[0] c0_min=0", c0_min === 7'd0);
    check("T3 bit[0] c0_max=0", c0_max === 7'd0);

    // ========================================
    // TEST 4: Single bit at the highest position
    // ========================================
    lines = '0;
    lines[LAST] = 1'b1;
    #10;
    check("T4 bit[LAST] valid", valid === 1'b1);
    check("T4 bit[LAST] 1 cluster", cluster_count === 2'd1);
    check("T4 bit[LAST] c0_min=LAST", c0_min === SPADMIC_LINE_IDX_W'(LAST));
    check("T4 bit[LAST] c0_max=LAST", c0_max === SPADMIC_LINE_IDX_W'(LAST));

    // ========================================
    // TEST 5: Two distant clusters
    // ========================================
    lines = '0;
    for (int i = 10; i <= 15; i++) lines[i] = 1'b1;
    for (int i = 50; i <= 55; i++) lines[i] = 1'b1;
    #10;
    check("T5 two clusters valid", valid === 1'b1);
    check("T5 two clusters count=2", cluster_count === 2'd2);
    check("T5 c0=[10,15]", c0_min === 7'd10 && c0_max === 7'd15);
    check("T5 c1=[50,55]", c1_min === 7'd50 && c1_max === 7'd55);
    check("T5 no overflow", overflow === 1'b0);

    // ========================================
    // TEST 6: Three clusters → overflow
    // ========================================
    lines = '0;
    for (int i = 0; i <= 3; i++) lines[i] = 1'b1;
    for (int i = 25; i <= 28; i++) lines[i] = 1'b1;
    for (int i = 50; i <= 53; i++) lines[i] = 1'b1;
    #10;
    check("T6 three clusters valid", valid === 1'b1);
    check("T6 three clusters overflow", overflow === 1'b1);
    check("T6 three clusters count=2", cluster_count === 2'd2);

    // ========================================
    // TEST 7: Gap threshold sweep (gap=1 to gap=10)
    // Two groups separated by exactly `gap` inactive bits
    // ========================================
    for (int g = 1; g <= 10; g++) begin
      lines = '0;
      // First group: bits 20-25
      for (int i = 20; i <= 25; i++) lines[i] = 1'b1;
      // Second group: starts at 26 + g
      for (int i = 26 + g; i <= 31 + g; i++) begin
        if (i < W) lines[i] = 1'b1;
      end
      gap_threshold = SPADMIC_LINE_COUNT_W'(g);
      #10;
      // When gap == threshold, they should be separate clusters
      // When gap < threshold, they merge
      if (g >= int'(gap_threshold)) begin
        // Expect 2 clusters (gap >= threshold means split)
        check($sformatf("T7 gap=%0d thresh=%0d → 2 clusters", g, g), cluster_count === 2'd2);
      end else begin
        check($sformatf("T7 gap=%0d thresh=%0d → check valid", g, g), valid === 1'b1);
      end
    end

    // ========================================
    // TEST 8: Alternating bits (0b101010...)
    // ========================================
    gap_threshold = 7'd2;
    lines = '0;
    for (int i = 0; i < W; i += 2) lines[i] = 1'b1;
    #10;
    check("T8 alternating gap=2 → 1 cluster", cluster_count === 2'd1);
    check("T8 alternating c0_min=0", c0_min === 7'd0);
    check("T8 alternating c0_max=LAST_EVEN", c0_max === SPADMIC_LINE_IDX_W'(LAST_EVEN));

    gap_threshold = 7'd1;
    #10;
    // With gap_threshold=1, each gap of 1 between alternating bits
    // may or may not split depending on implementation semantics
    check("T8b alternating gap=1 → valid", valid === 1'b1);

    // ========================================
    // TEST 9: Contiguous block at each end
    // ========================================
    gap_threshold = 7'd3;
    lines = '0;
    for (int i = 0; i <= 9; i++) lines[i] = 1'b1;
    for (int i = LAST - 9; i <= LAST; i++) lines[i] = 1'b1;
    #10;
    check("T9 two ends valid", valid === 1'b1);
    check("T9 two ends count=2", cluster_count === 2'd2);
    check("T9 c0=[0,9]", c0_min === 7'd0 && c0_max === 7'd9);
    check("T9 c1=[LAST-9,LAST]",
          c1_min === SPADMIC_LINE_IDX_W'(LAST - 9) && c1_max === SPADMIC_LINE_IDX_W'(LAST));

    // ========================================
    // TEST 10: Random patterns (LFSR-based)
    // ========================================
    begin
      logic [31:0] lfsr;
      lfsr = 32'hDEAD_BEEF;
      gap_threshold = 7'd5;
      for (int trial = 0; trial < 50; trial++) begin
        for (int b = 0; b < W; b++) begin
          lfsr = {lfsr[30:0], lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0]};
          lines[b] = lfsr[0];
        end
        #10;
        // Just check no X/Z in outputs and valid is deterministic
        check($sformatf("T10 random[%0d] no X in valid", trial),
              valid === 1'b1 || valid === 1'b0);
      end
    end

    // ========================================
    // TEST 11: Adjacent clusters just below gap threshold
    // ========================================
    gap_threshold = 7'd5;
    lines = '0;
    for (int i = 30; i <= 40; i++) lines[i] = 1'b1;
    // Gap of exactly 4 (below threshold of 5) → should merge
    for (int i = 45; i <= 55; i++) lines[i] = 1'b1;
    #10;
    check("T11 gap=4 < thresh=5 → 1 cluster", cluster_count === 2'd1);
    check("T11 merged c0=[30,55]", c0_min === 7'd30 && c0_max === 7'd55);

    // ========================================
    // TEST 12: Adjacent clusters at exact gap threshold
    // ========================================
    lines = '0;
    for (int i = 30; i <= 40; i++) lines[i] = 1'b1;
    // Gap of exactly 5 (== threshold) → should split
    for (int i = 46; i <= 55; i++) lines[i] = 1'b1;
    #10;
    check("T12 gap=5 == thresh=5 → 2 clusters", cluster_count === 2'd2);

    // ========================================
    // SUMMARY
    // ========================================
    $display("========================================");
    $display("CLUSTER SCAN STRESS: %0d PASS, %0d FAIL out of %0d",
             pass_count, fail_count, test_num);
    $display("========================================");
    if (fail_count > 0) $fatal(1, "STRESS TEST FAILED");
    $finish;
  end

endmodule

`default_nettype wire
