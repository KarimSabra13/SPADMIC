`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_position_snapshot_cluster_unit;
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  localparam int CLK_PERIOD = 6250;

  logic clk_sys;
  logic rst_n;
  logic start;
  wire pkt_valid;
  logic pkt_ready;
  wire [NARROW_W-1:0] pkt_data;
  wire pkt_sop;
  wire pkt_eop;
  wire packet_pending;
  wire busy;
  wire snapshot_captured;
  wire done;
  wire drop;
  int pass_count;
  int fail_count;
  int word_count;
  logic [NARROW_W-1:0] captured [0:SPADMIC_POS_PKT_WORDS-1];

  initial clk_sys = 1'b0;
  always #(CLK_PERIOD/2) clk_sys = ~clk_sys;

  spadmic_position_snapshot_packetizer dut (
    .clk_sys(clk_sys),
    .rst_n(rst_n),
    .start_i(start),
    .mode_i(SPADMIC_POS_MODE_CLUSTER),
    .event_id_i(14'h2C0),
    .snapshot_R_i(64'h0000_0000_0000_0401),
    .snapshot_Y_i(64'h0000_0000_0000_0018),
    .snapshot_B_i(64'h0000_0000_8000_0000),
    .gap_threshold_i(SPADMIC_LINE_COUNT_W'(2)),
    .min_cluster_span_i(SPADMIC_LINE_COUNT_W'(1)),
    .pkt_valid_o(pkt_valid),
    .pkt_ready_i(pkt_ready),
    .pkt_data_o(pkt_data),
    .pkt_sop_o(pkt_sop),
    .pkt_eop_o(pkt_eop),
    .packet_pending_o(packet_pending),
    .busy_o(busy),
    .snapshot_captured_o(snapshot_captured),
    .done_o(done),
    .drop_o(drop)
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

  function automatic spadmic_cluster_t mk_cluster(input int unsigned lo, input int unsigned hi);
    spadmic_cluster_t cluster;
    cluster = '0;
    cluster.valid = 1'b1;
    cluster.lo = SPADMIC_LINE_IDX_W'(lo);
    cluster.hi = SPADMIC_LINE_IDX_W'(hi);
    return cluster;
  endfunction

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      word_count <= 0;
      for (int i = 0; i < SPADMIC_POS_PKT_WORDS; i++)
        captured[i] <= '0;
    end else if (pkt_valid && pkt_ready) begin
      captured[word_count] <= pkt_data;
      word_count <= word_count + 1;
    end
  end

  initial begin
    pass_count = 0;
    fail_count = 0;
    rst_n = 1'b0;
    start = 1'b0;
    pkt_ready = 1'b1;

    repeat (4) @(posedge clk_sys);
    rst_n = 1'b1;
    repeat (2) @(posedge clk_sys);

    @(negedge clk_sys);
    start = 1'b1;
    @(posedge clk_sys);
    #1;
    check("cluster packetizer captures frozen snapshot immediately", snapshot_captured);
    @(negedge clk_sys);
    start = 1'b0;
    wait (done);
    @(posedge clk_sys);
    #1;

    check("cluster snapshot produces fixed packet length", word_count == SPADMIC_POS_PKT_WORDS);
    check("cluster header marks R multi-cluster", captured[0][2:0] == 3'b001);
    check("R cluster0 extracted from frozen bitmap",
          captured[1] == spadmic_pos_cluster_word(mk_cluster(0, 0)));
    check("R cluster1 extracted from frozen bitmap",
          captured[2] == spadmic_pos_cluster_word(mk_cluster(10, 10)));
    check("Y cluster extracted from frozen bitmap",
          captured[3] == spadmic_pos_cluster_word(mk_cluster(3, 4)));
    check("B cluster extracted from frozen bitmap",
          captured[5] == spadmic_pos_cluster_word(mk_cluster(31, 31)));
    check("cluster packet EOC uses common event ID", captured[7] == {2'b11, 14'h2C0});

    if (fail_count != 0)
      $fatal(1, "tb_spadmic_position_snapshot_cluster_unit: %0d failures", fail_count);

    $display("tb_spadmic_position_snapshot_cluster_unit: %0d pass / %0d fail",
             pass_count, fail_count);
    $finish;
  end

  initial begin
    #1_000_000;
    $fatal(1, "tb_spadmic_position_snapshot_cluster_unit: TIMEOUT");
  end
endmodule

`default_nettype wire
