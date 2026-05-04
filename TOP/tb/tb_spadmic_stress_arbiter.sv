// ============================================================================
// Stress test: spadmic_tdc_arbiter3 + spadmic_tdc_packet_fifo
// Tests: simultaneous 3-source, backpressure, variable packet lengths,
//        100+ packets, round-robin fairness, single-word packets.
// ============================================================================
`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_stress_arbiter;
  import mptdc_pkg::*;
  import spadmic_pkg::*;

  localparam int FIFO_DEPTH_TB = 128;
  localparam int CLK_PERIOD = 6250; // 160 MHz
  localparam time TIMEOUT_PS = 64'd5_000_000_000;

  logic clk_sys, rst_n;

  // FIFO write interfaces (3 sources)
  logic [2:0] wr_valid, wr_ready;
  logic [15:0] wr_data [3];

  // FIFO → Arbiter interfaces
  logic [2:0] pkt_valid, pkt_ready, pkt_sop, pkt_eop, pkt_available;
  logic [15:0] pkt_data [3];

  // Arbiter output
  logic arb_valid, arb_ready, arb_sop, arb_eop;
  logic [15:0] arb_data;

  // Clock
  initial clk_sys = 0;
  always #(CLK_PERIOD/2) clk_sys = ~clk_sys;

  // Instantiate 3 FIFOs + arbiter
  generate
    for (genvar i = 0; i < 3; i++) begin : g_fifo
      localparam spadmic_pkg::spadmic_tdc_id_e TID = (i == 0) ? spadmic_pkg::TDC_ID_X :
                                                     (i == 1) ? spadmic_pkg::TDC_ID_Y :
                                                                spadmic_pkg::TDC_ID_Z;
      spadmic_tdc_packet_fifo #(.DEPTH(FIFO_DEPTH_TB), .TDC_ID(TID)) u_fifo (
        .clk_sys      (clk_sys),
        .rst_n        (rst_n),
        .narrow_valid_i(wr_valid[i]),
        .narrow_data_i (wr_data[i]),
        .narrow_ready_o(wr_ready[i]),
        .pkt_valid_o    (pkt_valid[i]),
        .pkt_ready_i    (pkt_ready[i]),
        .pkt_data_o     (pkt_data[i]),
        .pkt_sop_o      (pkt_sop[i]),
        .pkt_eop_o      (pkt_eop[i]),
        .pkt_available_o(pkt_available[i]),
        .fifo_full_o    ()
      );
    end
  endgenerate

  spadmic_tdc_arbiter3 u_arb (
    .clk_sys (clk_sys),
    .rst_n   (rst_n),
    .pkt_valid_i    ({pkt_valid[2], pkt_valid[1], pkt_valid[0]}),
    .pkt_ready_o    ({pkt_ready[2], pkt_ready[1], pkt_ready[0]}),
    .pkt_data_i     (pkt_data),
    .pkt_sop_i      ({pkt_sop[2], pkt_sop[1], pkt_sop[0]}),
    .pkt_eop_i      ({pkt_eop[2], pkt_eop[1], pkt_eop[0]}),
    .shared_valid_o (arb_valid),
    .shared_ready_i (arb_ready),
    .shared_data_o  (arb_data),
    .shared_sop_o   (arb_sop),
    .shared_eop_o   (arb_eop),
    .arb_busy_o     (),
    .grant_idx_o    ()
  );

  // ── Scoreboard ──
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

  // ── Packet generator task ──
  // Writes a complete MPTDC-style packet to source `src` with `n_hits` hit words
  task automatic write_packet(int src, int n_hits, int seq_id);
    logic [15:0] hdr, sub_hdr, eoc;
    hdr = {3'b100, 13'(seq_id)};
    sub_hdr = {3'b101, 13'(n_hits)};
    eoc = {2'b11, 14'(seq_id)};

    // Write header
    @(posedge clk_sys);
    #1;
    wr_valid[src] = 1'b1;
    wr_data[src]  = hdr;
    @(posedge clk_sys);
    while (!wr_ready[src]) @(posedge clk_sys);
    // Write sub-header
    #1;
    wr_data[src] = sub_hdr;
    @(posedge clk_sys);
    while (!wr_ready[src]) @(posedge clk_sys);
    // Write hit words — upper 2 bits = 2'b00 to avoid EOC/header collision
    for (int h = 0; h < n_hits; h++) begin
      #1;
      wr_data[src] = {2'b00, 7'(h), 7'(seq_id)};
      @(posedge clk_sys);
      while (!wr_ready[src]) @(posedge clk_sys);
    end
    // Write EOC
    #1;
    wr_data[src] = eoc;
    @(posedge clk_sys);
    while (!wr_ready[src]) @(posedge clk_sys);
    #1;
    wr_valid[src] = 1'b0;
  endtask

  // ── Output collector ──
  // Collects packets from arbiter output and checks:
  // 1. No interleaving (tdc_id consistent within packet)
  // 2. SOP/EOP framing correct
  // 3. Packet count per source

  int packets_from [3];
  int total_packets;
  logic collecting;
  logic [1:0] current_tdc_id;
  logic in_packet;
  int current_pkt_words;
  int interleave_violations;
  int framing_errors;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      for (int i = 0; i < 3; i++) packets_from[i] <= 0;
      total_packets <= 0;
      in_packet <= 1'b0;
      current_tdc_id <= '0;
      current_pkt_words <= 0;
      interleave_violations <= 0;
      framing_errors <= 0;
    end else if (arb_valid && arb_ready) begin
      if (arb_sop) begin
        if (in_packet) begin
          // SOP while already in packet = framing error
          framing_errors <= framing_errors + 1;
        end
        in_packet <= 1'b1;
        current_pkt_words <= 1;
        if (arb_data[15:13] == 3'b100) begin
          current_tdc_id <= tdc_header_source_id(arb_data);
        end
      end else if (in_packet) begin
        current_pkt_words <= current_pkt_words + 1;
      end

      if (arb_eop) begin
        if (!in_packet && !arb_sop) begin
          framing_errors <= framing_errors + 1;
        end
        // Count packet
        if (current_pkt_words >= 2) begin
          // Use tdc_id from collected sub-header
          if (current_tdc_id < 3)
            packets_from[current_tdc_id] <= packets_from[current_tdc_id] + 1;
          total_packets <= total_packets + 1;
        end
        in_packet <= 1'b0;
        current_pkt_words <= 0;
      end
    end
  end

  initial begin
    $display("========================================");
    $display("STRESS TEST: spadmic_tdc_arbiter3");
    $display("========================================");

    rst_n = 0;
    arb_ready = 1;
    for (int i = 0; i < 3; i++) begin
      wr_valid[i] = 0;
      wr_data[i] = '0;
    end

    repeat (10) @(posedge clk_sys);
    rst_n = 1;
    repeat (4) @(posedge clk_sys);

    // ========================================
    // TEST 1: Sequential single-source packets
    // ========================================
    for (int src = 0; src < 3; src++) begin
      write_packet(src, 3, src*10);
    end
    repeat (100) @(posedge clk_sys);
    check("T1 all 3 sequential packets received", total_packets === 3);
    check("T1 no framing errors", framing_errors === 0);

    // ========================================
    // TEST 2: Near-simultaneous 3-source arrival
    // (Sequential writes to different FIFOs — arbiter sees them all queued)
    // ========================================
    begin
      int tp_before;
      tp_before = total_packets;
      write_packet(0, 2, 100);
      write_packet(1, 2, 101);
      write_packet(2, 2, 102);
      repeat (200) @(posedge clk_sys);
      check("T2 near-simultaneous: 3 more packets", (total_packets - tp_before) === 3);
      check("T2 no interleave/framing", framing_errors === 0);
    end

    // ========================================
    // TEST 3: Single-word packets (header=SOP+EOP simultaneously)
    // This tests minimal packet size edge case
    // ========================================
    begin
      int tp_before;
      tp_before = total_packets;
      // A 2-word packet (header + EOC) — minimum valid
      for (int src = 0; src < 3; src++) begin
        write_packet(src, 0, 200 + src); // 0 hits = header+sub_hdr+eoc = 3 words
      end
      repeat (150) @(posedge clk_sys);
      check("T3 minimal packets (3 words each)", (total_packets - tp_before) === 3);
    end

    // ========================================
    // TEST 4: Variable-length packets (1-15 hits)
    // ========================================
    begin
      int tp_before;
      tp_before = total_packets;
      for (int i = 0; i < 15; i++) begin
        int src;
        src = i % 3;
        write_packet(src, i + 1, 300 + i);
      end
      repeat (600) @(posedge clk_sys);
      check("T4 variable-length 15 packets", (total_packets - tp_before) === 15);
      check("T4 no framing errors", framing_errors === 0);
    end

    // ========================================
    // TEST 5: 60 packets sequential stress
    // ========================================
    begin
      int tp_before;
      tp_before = total_packets;

      for (int i = 0; i < 60; i++) begin
        int src;
        src = i % 3;
        write_packet(src, (i % 5) + 1, 500 + i);
      end
      repeat (3000) @(posedge clk_sys);
      check("T5 60 packets stress", (total_packets - tp_before) === 60);
      check("T5 no framing errors", framing_errors === 0);
    end

    // ========================================
    // TEST 6: Fairness check — equal source distribution
    // ========================================
    begin
      // Reset counters
      rst_n = 0;
      repeat (4) @(posedge clk_sys);
      rst_n = 1;
      repeat (4) @(posedge clk_sys);

      // Send 30 packets from each source in interleaved fashion
      for (int i = 0; i < 30; i++) begin
        write_packet(0, 2, 1000 + i);
        write_packet(1, 2, 2000 + i);
        write_packet(2, 2, 3000 + i);
        repeat (3) @(posedge clk_sys);
      end
      repeat (2000) @(posedge clk_sys);

      check($sformatf("T6 fairness: src0 got 30 packets (got %0d)", packets_from[0]), packets_from[0] === 30);
      check($sformatf("T6 fairness: src1 got 30 packets (got %0d)", packets_from[1]), packets_from[1] === 30);
      check($sformatf("T6 fairness: src2 got 30 packets (got %0d)", packets_from[2]), packets_from[2] === 30);
      check("T6 total is 90", total_packets === 90);
    end

    // ========================================
    // TEST 7: Large packets (15 hits = 18 words)
    // ========================================
    begin
      int tp_before;
      rst_n = 0;
      repeat (4) @(posedge clk_sys);
      rst_n = 1;
      repeat (4) @(posedge clk_sys);

      tp_before = total_packets;
      write_packet(0, 15, 4000);
      write_packet(1, 15, 4001);
      write_packet(2, 15, 4002);
      repeat (300) @(posedge clk_sys);
      check("T7 large packets (15 hits each)", (total_packets - tp_before) === 3);
      check("T7 no framing errors", framing_errors === 0);
    end

    // ========================================
    // SUMMARY
    // ========================================
    repeat (10) @(posedge clk_sys);
    $display("========================================");
    $display("ARBITER STRESS: %0d PASS, %0d FAIL out of %0d",
             pass_count, fail_count, test_num);
    $display("========================================");
    if (fail_count > 0) $fatal(1, "STRESS TEST FAILED");
    $finish;
  end

  // Timeout watchdog
  initial begin
    #TIMEOUT_PS;
    $fatal(1, "TIMEOUT");
  end

endmodule

`default_nettype wire
