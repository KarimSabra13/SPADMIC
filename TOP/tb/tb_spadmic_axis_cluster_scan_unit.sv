`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_axis_cluster_scan_unit;
  import spadmic_pkg::*;

  logic [SPADMIC_LINE_W-1:0] lines;
  logic [6:0] gap_threshold;
  spadmic_axis_clusters_t clusters;
  int pass_cnt;
  int fail_cnt;

  spadmic_axis_cluster_scan u_dut (
    .lines_i         (lines),
    .gap_threshold_i (gap_threshold),
    .clusters_o      (clusters)
  );

  task automatic check(input string label, input logic cond);
    if (cond) begin
      $display("[PASS] %s", label);
      pass_cnt++;
    end else begin
      $display("[FAIL] %s", label);
      fail_cnt++;
    end
  endtask

  initial begin
    pass_cnt = 0;
    fail_cnt = 0;
    lines = '0;
    gap_threshold = 7'd2;
    #1;

    // One cluster.
    lines[12:10] = 3'b111;
    #1;
    check("one cluster count", clusters.cluster_count == 2'd1);
    check("one cluster low bound", clusters.cluster0.lo == 7'd10);
    check("one cluster high bound", clusters.cluster0.hi == 7'd12);
    check("one cluster no overflow", clusters.overflow == 1'b0);

    // Two separated clusters.
    lines = '0;
    lines[5:3]   = 3'b111;
    lines[12:10] = 3'b111;
    #1;
    check("two clusters count", clusters.cluster_count == 2'd2);
    check("two clusters first range", (clusters.cluster0.lo == 7'd3) && (clusters.cluster0.hi == 7'd5));
    check("two clusters second range", (clusters.cluster1.lo == 7'd10) && (clusters.cluster1.hi == 7'd12));

    // Larger gap threshold merges them.
    gap_threshold = 7'd8;
    #1;
    check("merged cluster count", clusters.cluster_count == 2'd1);
    check("merged cluster range", (clusters.cluster0.lo == 7'd3) && (clusters.cluster0.hi == 7'd12));

    // Overflow on third cluster.
    gap_threshold = 7'd1;
    lines = '0;
    lines[2]  = 1'b1;
    lines[10] = 1'b1;
    lines[20] = 1'b1;
    #1;
    check("overflow asserted on third cluster", clusters.overflow == 1'b1);
    check("overflow retains first cluster", clusters.cluster0.lo == 7'd2);
    check("overflow retains second cluster", clusters.cluster1.lo == 7'd10);

    if (fail_cnt != 0)
      $fatal(1, "tb_spadmic_axis_cluster_scan_unit: %0d failures", fail_cnt);

    $display("tb_spadmic_axis_cluster_scan_unit: %0d pass / %0d fail", pass_cnt, fail_cnt);
    $finish;
  end

endmodule

`default_nettype wire
