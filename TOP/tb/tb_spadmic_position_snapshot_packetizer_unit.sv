`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_position_snapshot_packetizer_unit;
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  localparam int CLK_PERIOD = 6250;

  logic clk_sys;
  logic rst_n;
  logic start;
  logic [13:0] event_id;
  logic [63:0] snapshot_R;
  logic [63:0] snapshot_Y;
  logic [63:0] snapshot_B;
  wire pkt_valid;
  logic pkt_ready;
  wire [NARROW_W-1:0] pkt_data;
  wire pkt_sop;
  wire pkt_eop;
  wire packet_pending;
  wire busy;
  wire done;
  wire drop;
  int pass_count;
  int fail_count;
  int word_count;
  logic [NARROW_W-1:0] captured [0:SPADMIC_POS_RAW_PKT_WORDS-1];

  initial clk_sys = 1'b0;
  always #(CLK_PERIOD/2) clk_sys = ~clk_sys;

  spadmic_position_snapshot_packetizer dut (
    .clk_sys(clk_sys),
    .rst_n(rst_n),
    .start_i(start),
    .event_id_i(event_id),
    .snapshot_R_i(snapshot_R),
    .snapshot_Y_i(snapshot_Y),
    .snapshot_B_i(snapshot_B),
    .pkt_valid_o(pkt_valid),
    .pkt_ready_i(pkt_ready),
    .pkt_data_o(pkt_data),
    .pkt_sop_o(pkt_sop),
    .pkt_eop_o(pkt_eop),
    .packet_pending_o(packet_pending),
    .busy_o(busy),
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

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      word_count <= 0;
      for (int i = 0; i < SPADMIC_POS_RAW_PKT_WORDS; i++)
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
    event_id = 14'h155;
    snapshot_R = 64'h0000_0000_0000_0003;
    snapshot_Y = 64'h0000_0000_0000_00C0;
    snapshot_B = 64'h8000_0000_0000_0000;
    pkt_ready = 1'b1;

    repeat (4) @(posedge clk_sys);
    rst_n = 1'b1;
    repeat (2) @(posedge clk_sys);
    #1;
    check("reset leaves packetizer idle", !busy && !packet_pending);

    @(negedge clk_sys);
    start = 1'b1;
    @(negedge clk_sys);
    start = 1'b0;
    wait (done);
    @(posedge clk_sys);
    #1;

    check("raw position packet has 14 words", word_count == SPADMIC_POS_RAW_PKT_WORDS);
    check("raw position header encodes all directions", captured[0] == spadmic_pos_raw_header_word(3'b111));
    check("R raw low word captured", captured[1] == 16'h0003);
    check("Y raw low word captured", captured[5] == 16'h00C0);
    check("B raw high word captured", captured[12] == 16'h8000);
    check("EOC uses 14-bit event ID", captured[13] == {2'b11, event_id});
    check("packetizer returns idle", !busy && !packet_pending);

    @(negedge clk_sys);
    start = 1'b1;
    @(posedge clk_sys);
    #1;
    check("start creates pending packet", packet_pending);
    @(negedge clk_sys);
    start = 1'b1;
    @(posedge clk_sys);
    #1;
    check("second start while busy reports drop", drop);
    start = 1'b0;

    if (fail_count != 0)
      $fatal(1, "tb_spadmic_position_snapshot_packetizer_unit: %0d failures", fail_count);

    $display("tb_spadmic_position_snapshot_packetizer_unit: %0d pass / %0d fail",
             pass_count, fail_count);
    $finish;
  end

  initial begin
    #2_000_000;
    $fatal(1, "tb_spadmic_position_snapshot_packetizer_unit: TIMEOUT");
  end
endmodule

`default_nettype wire
