`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_axis_cluster_scan_unit;
  import spadmic_pkg::*;

  localparam int CLK_PERIOD = 6250;

  logic clk_sys;
  logic rst_n;
  logic start;
  logic busy;
  logic valid;
  logic [SPADMIC_LINE_W-1:0] lines;
  logic [6:0] gap_threshold;
  spadmic_axis_clusters_t clusters;
  int pass_cnt;
  int fail_cnt;

  initial clk_sys = 1'b0;
  always #(CLK_PERIOD/2) clk_sys = ~clk_sys;

  spadmic_axis_cluster_scan u_dut (
    .clk_sys         (clk_sys),
    .rst_n           (rst_n),
    .start_i         (start),
    .lines_i         (lines),
    .gap_threshold_i (gap_threshold),
    .busy_o          (busy),
    .valid_o         (valid),
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

  task automatic run_scan(
    input logic [SPADMIC_LINE_W-1:0] pattern,
    input logic [6:0]                threshold
  );
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
    pass_cnt = 0;
    fail_cnt = 0;
    rst_n = 1'b0;
    start = 1'b0;
    lines = '0;
    gap_threshold = 7'd2;

    repeat (4) @(posedge clk_sys);
    rst_n = 1'b1;
    repeat (2) @(posedge clk_sys);

    lines = '0;
    lines[12:10] = 3'b111;
    run_scan(lines, 7'd2);
    check("one cluster count", clusters.cluster_count == 2'd1);
    check("one cluster low bound", clusters.cluster0.lo == 7'd10);
    check("one cluster high bound", clusters.cluster0.hi == 7'd12);
    check("one cluster no overflow", clusters.overflow == 1'b0);

    lines = '0;
    lines[5:3]   = 3'b111;
    lines[12:10] = 3'b111;
    run_scan(lines, 7'd2);
    check("two clusters count", clusters.cluster_count == 2'd2);
    check("two clusters first range", (clusters.cluster0.lo == 7'd3) && (clusters.cluster0.hi == 7'd5));
    check("two clusters second range", (clusters.cluster1.lo == 7'd10) && (clusters.cluster1.hi == 7'd12));

    run_scan(lines, 7'd8);
    check("merged cluster count", clusters.cluster_count == 2'd1);
    check("merged cluster range", (clusters.cluster0.lo == 7'd3) && (clusters.cluster0.hi == 7'd12));

    lines = '0;
    lines[2]  = 1'b1;
    lines[10] = 1'b1;
    lines[20] = 1'b1;
    run_scan(lines, 7'd1);
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
