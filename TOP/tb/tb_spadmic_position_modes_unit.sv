`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_position_modes_unit;
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  localparam int CLK_PERIOD = 6250;

  logic clk_sys;
  logic rst_n;
  logic start;
  spadmic_pos_mode_e mode;
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
  wire snapshot_captured;
  wire done;
  wire drop;
  int pass_count;
  int fail_count;
  int word_count;
  logic [NARROW_W-1:0] first_word;
  logic [NARROW_W-1:0] last_word;

  initial clk_sys = 1'b0;
  always #(CLK_PERIOD/2) clk_sys = ~clk_sys;

  spadmic_position_snapshot_packetizer dut (
    .clk_sys(clk_sys),
    .rst_n(rst_n),
    .start_i(start),
    .mode_i(mode),
    .event_id_i(event_id),
    .snapshot_R_i(snapshot_R),
    .snapshot_Y_i(snapshot_Y),
    .snapshot_B_i(snapshot_B),
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

  task automatic run_packet(
    input spadmic_pos_mode_e packet_mode,
    input logic [13:0] packet_id,
    output int words,
    output logic [NARROW_W-1:0] header,
    output logic [NARROW_W-1:0] eoc
  );
    begin
      word_count = 0;
      first_word = '0;
      last_word = '0;
      mode = packet_mode;
      event_id = packet_id;
      @(negedge clk_sys);
      start = 1'b1;
      @(posedge clk_sys);
      #1;
      check("packetizer copies snapshot on start", snapshot_captured);
      @(negedge clk_sys);
      start = 1'b0;
      wait (done);
      @(posedge clk_sys);
      #1;
      words = word_count;
      header = first_word;
      eoc = last_word;
    end
  endtask

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      word_count <= 0;
      first_word <= '0;
      last_word <= '0;
    end else if (pkt_valid && pkt_ready) begin
      if (word_count == 0)
        first_word <= pkt_data;
      last_word <= pkt_data;
      word_count <= word_count + 1;
    end
  end

  initial begin
    int words;
    logic [NARROW_W-1:0] header;
    logic [NARROW_W-1:0] eoc;

    pass_count = 0;
    fail_count = 0;
    rst_n = 1'b0;
    start = 1'b0;
    mode = SPADMIC_POS_MODE_RAW;
    event_id = 14'h001;
    snapshot_R = 64'h0000_0000_0000_0003;
    snapshot_Y = 64'h0000_0000_0000_00C0;
    snapshot_B = 64'h0000_0000_0000_1000;
    pkt_ready = 1'b1;

    repeat (4) @(posedge clk_sys);
    rst_n = 1'b1;
    repeat (2) @(posedge clk_sys);

    run_packet(SPADMIC_POS_MODE_RAW, 14'h123, words, header, eoc);
    check("RAW mode packet length", words == SPADMIC_POS_RAW_PKT_WORDS);
    check("RAW mode header selected", header == spadmic_pos_raw_header_word(3'b111));
    check("RAW mode EOC uses event ID", eoc == {2'b11, 14'h123});

    run_packet(SPADMIC_POS_MODE_CLUSTER, 14'h124, words, header, eoc);
    check("CLUSTER mode packet length", words == SPADMIC_POS_PKT_WORDS);
    check("CLUSTER mode header selected",
          header == spadmic_pos_header_word(1'b0, 3'b111, 3'b000));
    check("CLUSTER mode EOC uses event ID", eoc == {2'b11, 14'h124});

    if (fail_count != 0)
      $fatal(1, "tb_spadmic_position_modes_unit: %0d failures", fail_count);

    $display("tb_spadmic_position_modes_unit: %0d pass / %0d fail", pass_count, fail_count);
    $finish;
  end

  initial begin
    #1_000_000;
    $fatal(1, "tb_spadmic_position_modes_unit: TIMEOUT");
  end
endmodule

`default_nettype wire
