// ============================================================================
// Stress test: spadmic_position_block + spadmic_axis_cluster_scan
// Tests: back-to-back events, capture during busy (queued overlap), CSR config,
//        multi-axis simultaneous, empty bitmaps, full bitmaps, packet format.
// ============================================================================
`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_stress_position;

  import spadmic_pkg::*;

  localparam int CLK_PERIOD = 6250;

  logic clk_sys, rst_n;
  logic enable;
  logic [SPADMIC_LINE_W-1:0] x_lines, y_lines, z_lines;

  // TX output
  logic tx_valid, tx_ready;
  logic [15:0] tx_data;

  // CSR interface
  logic csr_valid, csr_write, csr_ready, csr_rvalid;
  logic [spadmic_pkg::SPADMIC_CSR_ADDR_W-1:0] csr_addr;
  logic [spadmic_pkg::SPADMIC_CSR_DATA_W-1:0] csr_wdata, csr_rdata;

  logic busy, pkt_pending;
  logic drop_sticky, glitch_reject_sticky;
  logic spad_matrix_rst;

  initial clk_sys = 0;
  always #(CLK_PERIOD/2) clk_sys = ~clk_sys;

  spadmic_position_block dut (
    .clk_sys         (clk_sys),
    .rst_n           (rst_n),
    .global_enable_i (enable),
    .x_lines_i       (x_lines),
    .y_lines_i       (y_lines),
    .z_lines_i       (z_lines),
    .csr_valid_i     (csr_valid),
    .csr_write_i     (csr_write),
    .csr_addr_i      (csr_addr),
    .csr_wdata_i     (csr_wdata),
    .csr_ready_o     (csr_ready),
    .csr_rvalid_o    (csr_rvalid),
    .csr_rdata_o     (csr_rdata),
    .pos_ready_i     (tx_ready),
    .pos_valid_o     (tx_valid),
    .pos_data_o      (tx_data),
    .busy_o          (busy),
    .packet_pending_o(pkt_pending),
    .drop_sticky_o   (drop_sticky),
    .glitch_reject_sticky_o(glitch_reject_sticky),
    .spad_matrix_rst_o(spad_matrix_rst)
  );

  // Scoreboard
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

  function automatic spadmic_cluster_t make_cluster(
    input logic        valid,
    input int unsigned lo,
    input int unsigned hi
  );
    spadmic_cluster_t cluster;
    cluster = '0;
    cluster.valid = valid;
    cluster.lo    = SPADMIC_LINE_IDX_W'(lo);
    cluster.hi    = SPADMIC_LINE_IDX_W'(hi);
    return cluster;
  endfunction

  function automatic spadmic_axis_clusters_t make_axis_clusters(
    input spadmic_cluster_t cluster0,
    input spadmic_cluster_t cluster1,
    input logic             overflow
  );
    spadmic_axis_clusters_t axis_clusters;
    axis_clusters = '0;
    axis_clusters.cluster0 = cluster0;
    axis_clusters.cluster1 = cluster1;
    axis_clusters.overflow = overflow;
    axis_clusters.empty    = ~(cluster0.valid | cluster1.valid);
    axis_clusters.cluster_count = {1'b0, cluster0.valid}
                                + {1'b0, cluster1.valid};
    return axis_clusters;
  endfunction

  // Collect output packet (declared before check_word to satisfy Xcelium forward-ref rules)
  int pkt_word_count;
  logic [15:0] pkt_words [32];

  task automatic check_word(
    input string       name,
    input int unsigned idx,
    input logic [15:0] expected
  );
    check(name, pkt_words[idx] === expected);
  endtask

  task automatic wait_spad_reset_pulse(
    input int unsigned max_cycles,
    output logic       seen
  );
    seen = 1'b0;
    for (int cycle = 0; cycle < max_cycles; cycle++) begin
      @(posedge clk_sys);
      #1;
      if (spad_matrix_rst) begin
        seen = 1'b1;
        break;
      end
    end
  endtask

  task automatic collect_packet(output int n_words);
    n_words = 0;
    @(posedge clk_sys);
    #1;
    tx_ready = 1'b1;
    forever begin
      @(posedge clk_sys);
      if (tx_valid) begin
        pkt_words[n_words] = tx_data;
        n_words++;
        // Check for EOC (bits[15:14]=2'b11)
        if (tx_data[15:14] == 2'b11) break;
        if (n_words >= 32) break; // Safety
      end
    end
    #1;
    tx_ready = 1'b0;
  endtask

  task automatic csr_write_pos(
    input logic [spadmic_pkg::SPADMIC_CSR_ADDR_W-1:0] addr,
    input logic [spadmic_pkg::SPADMIC_CSR_DATA_W-1:0] data
  );
    @(posedge clk_sys);
    #1;
    csr_valid = 1'b1;
    csr_write = 1'b1;
    csr_addr  = addr;
    csr_wdata = data;
    @(posedge clk_sys);
    #1;
    csr_valid = 1'b0;
    csr_write = 1'b0;
  endtask

  task automatic csr_read_pos(
    input logic [spadmic_pkg::SPADMIC_CSR_ADDR_W-1:0] addr,
    output logic [spadmic_pkg::SPADMIC_CSR_DATA_W-1:0] data
  );
    @(posedge clk_sys);
    #1;
    csr_valid = 1'b1;
    csr_write = 1'b0;
    csr_addr  = addr;
    csr_wdata = '0;
    @(posedge clk_sys);
    #1;
    csr_valid = 1'b0;
    while (!csr_rvalid) @(posedge clk_sys);
    data = csr_rdata;
  endtask

  initial begin
    $display("========================================");
    $display("STRESS TEST: spadmic_position_block");
    $display("========================================");

    rst_n = 0;
    enable = 0;
    x_lines = '0;
    y_lines = '0;
    z_lines = '0;
    tx_ready = 0;
    csr_valid = 0;
    csr_write = 0;
    csr_addr = '0;
    csr_wdata = '0;

    repeat (10) @(posedge clk_sys);
    rst_n = 1;
    enable = 1;
    repeat (4) @(posedge clk_sys);

    // ========================================
    // TEST 1: Basic single capture with known pattern
    // Position block self-triggers when any line goes active (rising edge)
    // ========================================
    begin
      int n;
      logic [31:0] rd_data;
      // Set lines active — this triggers capture automatically
      @(posedge clk_sys);
      x_lines = '0; x_lines[10] = 1; x_lines[11] = 1; x_lines[12] = 1;
      y_lines = '0; y_lines[50] = 1; y_lines[51] = 1;
      z_lines = '0; z_lines[60] = 1;

      repeat (6) @(posedge clk_sys);
      collect_packet(n);

      check("T1 basic packet: 8 words", n === SPADMIC_POS_PKT_WORDS);
      check("T1 header word", pkt_words[0][15:14] == 2'b01);
      check("T1 EOC word", pkt_words[n-1][15:14] == 2'b11);
      csr_read_pos(SPADMIC_CSR_POS_EVENT_COUNT, rd_data);
      check("T1 event tag increments", rd_data[3:0] === 4'd1);

      // Clear lines
      @(posedge clk_sys);
      x_lines = '0; y_lines = '0; z_lines = '0;
      repeat (6) @(posedge clk_sys);
    end

    // ========================================
    // TEST 2: Full bitmaps
    // ========================================
    begin
      int n;
      @(posedge clk_sys);
      x_lines = {SPADMIC_LINE_W{1'b1}};
      y_lines = {SPADMIC_LINE_W{1'b1}};
      z_lines = {SPADMIC_LINE_W{1'b1}};
      repeat (6) @(posedge clk_sys);
      collect_packet(n);
      check("T2 full bitmaps -> 8 words", n === SPADMIC_POS_PKT_WORDS);
      @(posedge clk_sys);
      x_lines = '0; y_lines = '0; z_lines = '0;
      repeat (6) @(posedge clk_sys);
    end

    // ========================================
    // TEST 3: Back-to-back captures (10 events)
    // ========================================
    begin
      int total_words;
      total_words = 0;

      for (int i = 0; i < 10; i++) begin
        int n;
        // Trigger: set lines active
        @(posedge clk_sys);
        x_lines = '0; x_lines[5] = 1; x_lines[6] = 1;
        y_lines = '0; y_lines[60] = 1; y_lines[61] = 1;
        z_lines = '0; z_lines[62] = 1; z_lines[63] = 1;
        repeat (6) @(posedge clk_sys);
        collect_packet(n);
        total_words += n;
        // Clear lines to allow next rising edge trigger
        @(posedge clk_sys);
        x_lines = '0; y_lines = '0; z_lines = '0;
        repeat (6) @(posedge clk_sys);
      end

      check("T3 10 back-to-back events -> 80 words", total_words === (10 * SPADMIC_POS_PKT_WORDS));
    end

    // ========================================
    // TEST 4: Capture during busy (event should queue)
    // ========================================
    begin
      int n;
      logic [31:0] rd_data;
      // Send first capture
      @(posedge clk_sys);
      x_lines = '0; x_lines[20] = 1; x_lines[21] = 1;
      y_lines = '0; z_lines = '0;
      // Don't assert tx_ready — packet stays active
      repeat (6) @(posedge clk_sys);

      // Clear and re-set lines to try a second trigger while busy
      @(posedge clk_sys);
      x_lines = '0; y_lines = '0; z_lines = '0;
      repeat (6) @(posedge clk_sys);
      x_lines[30] = 1; x_lines[31] = 1; // Try to trigger another capture
      repeat (6) @(posedge clk_sys);

      // Now collect first packet
      collect_packet(n);
      check("T4 first packet collected", n === SPADMIC_POS_PKT_WORDS);

      // Clear lines
      @(posedge clk_sys);
      x_lines = '0; y_lines = '0; z_lines = '0;

      // Drain the queued second packet
      collect_packet(n);
      check("T4 second packet queued behind first", n === SPADMIC_POS_PKT_WORDS);
      csr_read_pos(SPADMIC_CSR_POS_DROP_COUNT, rd_data);
      check("T4 no drop counted while queue absorbs overlap", rd_data[15:0] === 16'd0);
      csr_read_pos(SPADMIC_CSR_POS_FAULT_STATUS, rd_data);
      check("T4 drop sticky remains clear", rd_data[0] === 1'b0);
      repeat (6) @(posedge clk_sys);
    end

    // ========================================
    // TEST 5: Backpressure on TX
    // ========================================
    begin
      int n;
      // Trigger capture
      @(posedge clk_sys);
      x_lines = '0; x_lines[30] = 1; x_lines[31] = 1;
      y_lines = '0; y_lines[52] = 1; y_lines[53] = 1;
      z_lines = '0; z_lines[60] = 1; z_lines[61] = 1;
      // Hold tx_ready low for a while
      repeat (24) @(posedge clk_sys);
      // Now start collecting
      collect_packet(n);
      check("T5 backpressure → correct packet", n === SPADMIC_POS_PKT_WORDS);
      @(posedge clk_sys);
      x_lines = '0; y_lines = '0; z_lines = '0;
      repeat (6) @(posedge clk_sys);
    end

    // ========================================
    // TEST 6: Disabled → no capture
    // ========================================
    begin
      enable = 0;
      @(posedge clk_sys);
      x_lines = '0; x_lines[40] = 1; x_lines[41] = 1;
      y_lines = '0; z_lines = '0;
      repeat (10) @(posedge clk_sys);
      tx_ready = 1;
      repeat (20) @(posedge clk_sys);
      check("T6 disabled → no tx_valid", tx_valid === 1'b0);
      tx_ready = 0;
      @(posedge clk_sys);
      x_lines = '0; y_lines = '0; z_lines = '0;

      // Re-enable and verify functionality
      enable = 1;
      repeat (4) @(posedge clk_sys);
      begin
        int n;
        @(posedge clk_sys);
        x_lines[40] = 1; x_lines[41] = 1;
        repeat (6) @(posedge clk_sys);
        collect_packet(n);
        check("T6 re-enabled → packet OK", n === SPADMIC_POS_PKT_WORDS);
        @(posedge clk_sys);
        x_lines = '0; y_lines = '0; z_lines = '0;
        repeat (6) @(posedge clk_sys);
      end
    end

    // ========================================
    // TEST 7: Gap threshold via CSR
    // ========================================
    begin
      int n;
      csr_write_pos(SPADMIC_CSR_POS_GAP_CFG, 32'd5);
      repeat (4) @(posedge clk_sys);

      // Trigger capture with modified gap threshold
      x_lines = '0;
      x_lines[10] = 1; x_lines[11] = 1;
      // Gap of 4 (below threshold 5 → should merge)
      x_lines[16] = 1; x_lines[17] = 1;
      y_lines = '0; z_lines = '0;
      repeat (6) @(posedge clk_sys);
      collect_packet(n);
      check("T7 CSR gap config → packet produced", n === SPADMIC_POS_PKT_WORDS);
      @(posedge clk_sys);
      x_lines = '0; y_lines = '0; z_lines = '0;
      repeat (6) @(posedge clk_sys);
    end

    // ========================================
    // TEST 7b: Threshold/min-span can be lowered to 1 via CSR
    // ========================================
    begin
      int n;
      spadmic_axis_clusters_t exp_x;

      csr_write_pos(SPADMIC_CSR_POS_FILTER_CFG, 32'h0000_0101);
      repeat (4) @(posedge clk_sys);

      @(posedge clk_sys);
      x_lines = '0;
      x_lines[12] = 1;
      y_lines = '0; z_lines = '0;
      repeat (6) @(posedge clk_sys);
      collect_packet(n);

      exp_x = make_axis_clusters(
        make_cluster(1'b1, 12, 12),
        make_cluster(1'b0, 0, 0),
        1'b0
      );
      check("T7b min-span 1 packet length", n === SPADMIC_POS_PKT_WORDS);
      check_word("T7b single line retained as cluster", 1, spadmic_pos_cluster_word(exp_x.cluster0));

      @(posedge clk_sys);
      x_lines = '0; y_lines = '0; z_lines = '0;
      repeat (6) @(posedge clk_sys);

      csr_write_pos(SPADMIC_CSR_POS_FILTER_CFG, 32'h0000_0102);
      repeat (2) @(posedge clk_sys);
    end

    // ========================================
    // TEST 8: Glitch rejection accounting and sticky clear
    // ========================================
    begin
      logic [31:0] fault_status;
      logic [31:0] reject_before;
      logic [31:0] reject_after;

      csr_read_pos(SPADMIC_CSR_POS_REJECT_COUNT, reject_before);

      @(posedge clk_sys);
      x_lines = '0; x_lines[24] = 1; x_lines[25] = 1;
      y_lines = '0; z_lines = '0;
      @(posedge clk_sys);
      x_lines = '0; y_lines = '0; z_lines = '0;
      repeat (12) @(posedge clk_sys);

      check("T8 glitch pulse produces no packet", tx_valid === 1'b0);
      csr_read_pos(SPADMIC_CSR_POS_REJECT_COUNT, reject_after);
      check("T8 reject counter increments", reject_after[15:0] === (reject_before[15:0] + 16'd1));
      csr_read_pos(SPADMIC_CSR_POS_FAULT_STATUS, fault_status);
      check("T8 glitch sticky set", fault_status[1] === 1'b1);

      csr_write_pos(SPADMIC_CSR_POS_FAULT_STATUS, 32'h0000_0002);
      repeat (2) @(posedge clk_sys);
      csr_read_pos(SPADMIC_CSR_POS_FAULT_STATUS, fault_status);
      check("T8 glitch sticky clears", fault_status[1] === 1'b0);
    end

    // ========================================
    // TEST 9: Settle-cycle configuration gates acceptance
    // ========================================
    begin
      int n;
      logic [31:0] reject_before;
      logic [31:0] reject_after;

      csr_write_pos(SPADMIC_CSR_POS_FILTER_CFG, 32'h0000_0302);
      repeat (2) @(posedge clk_sys);
      csr_read_pos(SPADMIC_CSR_POS_REJECT_COUNT, reject_before);

      @(posedge clk_sys);
      x_lines = '0; x_lines[32] = 1; x_lines[33] = 1;
      y_lines = '0; z_lines = '0;
      repeat (4) @(posedge clk_sys);
      x_lines = '0; y_lines = '0; z_lines = '0;
      repeat (12) @(posedge clk_sys);

      check("T9 short pulse rejected by settle window", tx_valid === 1'b0);
      csr_read_pos(SPADMIC_CSR_POS_REJECT_COUNT, reject_after);
      check("T9 settle-window reject counted", reject_after[15:0] === (reject_before[15:0] + 16'd1));

      @(posedge clk_sys);
      x_lines = '0; x_lines[36] = 1; x_lines[37] = 1;
      repeat (6) @(posedge clk_sys);
      check("T9 settle window delays packet start", tx_valid === 1'b0);
      repeat (4) @(posedge clk_sys);
      check("T9 settle window eventually queues packet", pkt_pending === 1'b1);

      collect_packet(n);
      check("T9 stable event captured after settle window", n === SPADMIC_POS_PKT_WORDS);

      @(posedge clk_sys);
      x_lines = '0; y_lines = '0; z_lines = '0;
      repeat (6) @(posedge clk_sys);

      csr_write_pos(SPADMIC_CSR_POS_FILTER_CFG, 32'h0000_0102);
      repeat (2) @(posedge clk_sys);
    end

    // ========================================
    // TEST 10: Gap threshold boundary updates packetized clusters
    // ========================================
    begin
      int n;
      spadmic_axis_clusters_t exp_x;

      csr_write_pos(SPADMIC_CSR_POS_GAP_CFG, 32'd5);
      repeat (2) @(posedge clk_sys);

      @(posedge clk_sys);
      x_lines = '0;
      x_lines[10] = 1; x_lines[11] = 1;
      x_lines[16] = 1; x_lines[17] = 1;
      y_lines = '0; z_lines = '0;
      repeat (6) @(posedge clk_sys);
      collect_packet(n);

      exp_x = make_axis_clusters(
        make_cluster(1'b1, 10, 17),
        make_cluster(1'b0, 0, 0),
        1'b0
      );
      check("T10 merged-gap packet length", n === SPADMIC_POS_PKT_WORDS);
      check_word("T10 merged-gap header", 0, spadmic_pos_header_word(1'b0, 3'b001, 3'b000));
      check_word("T10 merged-gap x cluster0", 1, spadmic_pos_cluster_word(exp_x.cluster0));
      check_word("T10 merged-gap x cluster1 invalid", 2, spadmic_pos_cluster_word(exp_x.cluster1));

      @(posedge clk_sys);
      x_lines = '0; y_lines = '0; z_lines = '0;
      repeat (6) @(posedge clk_sys);

      @(posedge clk_sys);
      x_lines = '0;
      x_lines[10] = 1; x_lines[11] = 1;
      x_lines[17] = 1; x_lines[18] = 1;
      y_lines = '0; z_lines = '0;
      repeat (6) @(posedge clk_sys);
      collect_packet(n);

      exp_x = make_axis_clusters(
        make_cluster(1'b1, 10, 11),
        make_cluster(1'b1, 17, 18),
        1'b0
      );
      check("T10 threshold-gap packet length", n === SPADMIC_POS_PKT_WORDS);
      check_word("T10 threshold-gap header", 0, spadmic_pos_header_word(1'b0, 3'b001, 3'b001));
      check_word("T10 threshold-gap x cluster0", 1, spadmic_pos_cluster_word(exp_x.cluster0));
      check_word("T10 threshold-gap x cluster1", 2, spadmic_pos_cluster_word(exp_x.cluster1));

      @(posedge clk_sys);
      x_lines = '0; y_lines = '0; z_lines = '0;
      repeat (6) @(posedge clk_sys);

      csr_write_pos(SPADMIC_CSR_POS_GAP_CFG, 32'd2);
      repeat (2) @(posedge clk_sys);
    end

    // ========================================
    // TEST 11: Mid-packet stalls hold the current word stable
    // ========================================
    begin
      int words_seen;
      logic [15:0] stalled_word;

      @(posedge clk_sys);
      x_lines = '0; x_lines[44] = 1; x_lines[45] = 1;
      y_lines = '0; y_lines[52] = 1; y_lines[53] = 1;
      z_lines = '0; z_lines[60] = 1; z_lines[61] = 1;
      repeat (6) @(posedge clk_sys);

      words_seen = 0;
      @(posedge clk_sys);
      #1;
      tx_ready = 1'b1;
      while (words_seen < 4) begin
        @(posedge clk_sys);
        if (tx_valid)
          words_seen++;
      end

      #1;
      tx_ready = 1'b0;
      stalled_word = tx_data;
      check("T11 mid-packet stall keeps valid high", tx_valid === 1'b1);
      repeat (2) begin
        @(posedge clk_sys);
        #1;
        check("T11 mid-packet stall keeps valid high", tx_valid === 1'b1);
        check("T11 mid-packet stall holds data", tx_data === stalled_word);
      end

      tx_ready = 1'b1;
      while (tx_valid) @(posedge clk_sys);
      #1;
      tx_ready = 1'b0;

      @(posedge clk_sys);
      x_lines = '0; y_lines = '0; z_lines = '0;
      repeat (6) @(posedge clk_sys);
    end

    // ========================================
    // TEST 12: Overflow keeps the first two cluster bounds
    // ========================================
    begin
      int n;
      spadmic_axis_clusters_t exp_x;

      @(posedge clk_sys);
      x_lines = '0;
      x_lines[0] = 1; x_lines[1] = 1;
      x_lines[4] = 1; x_lines[5] = 1;
      x_lines[8] = 1; x_lines[9] = 1;
      y_lines = '0; z_lines = '0;
      repeat (6) @(posedge clk_sys);
      collect_packet(n);

      exp_x = make_axis_clusters(
        make_cluster(1'b1, 0, 1),
        make_cluster(1'b1, 4, 5),
        1'b1
      );
      check("T12 overflow packet length", n === SPADMIC_POS_PKT_WORDS);
      check_word("T12 overflow header", 0, spadmic_pos_header_word(1'b1, 3'b001, 3'b001));
      check_word("T12 overflow x cluster0 retained", 1, spadmic_pos_cluster_word(exp_x.cluster0));
      check_word("T12 overflow x cluster1 retained", 2, spadmic_pos_cluster_word(exp_x.cluster1));

      @(posedge clk_sys);
      x_lines = '0; y_lines = '0; z_lines = '0;
      repeat (6) @(posedge clk_sys);
    end

    // ========================================
    // TEST 13: Raw low-rate bitmap mode emits full X/Y/Z line levels
    // ========================================
    begin
      int n;

      csr_write_pos(SPADMIC_CSR_POS_CTRL, 32'h0000_0003); // enable + raw mode
      repeat (2) @(posedge clk_sys);

      @(posedge clk_sys);
      x_lines = '0; y_lines = '0; z_lines = '0;
      x_lines[0] = 1; x_lines[15] = 1; x_lines[SPADMIC_LINE_W-1] = 1;
      y_lines[16] = 1; y_lines[SPADMIC_LINE_W-1] = 1;
      z_lines[31] = 1; z_lines[SPADMIC_LINE_W-2] = 1;
      repeat (6) @(posedge clk_sys);
      collect_packet(n);

      check("T13 raw packet length", n === SPADMIC_POS_RAW_PKT_WORDS);
      check_word("T13 raw header", 0, spadmic_pos_raw_header_word(3'b111));
      check_word("T13 raw X word0", 1, spadmic_pos_raw_word(x_lines, 0));
      check_word("T13 raw X word3", 4, spadmic_pos_raw_word(x_lines, 3));
      check_word("T13 raw Y word1", 6, spadmic_pos_raw_word(y_lines, 1));
      check_word("T13 raw Z word1", 10, spadmic_pos_raw_word(z_lines, 1));
      check_word("T13 raw Z word3", 12, spadmic_pos_raw_word(z_lines, 3));
      check("T13 raw EOC", pkt_words[n-1][15:14] === 2'b11);

      @(posedge clk_sys);
      x_lines = '0; y_lines = '0; z_lines = '0;
      repeat (6) @(posedge clk_sys);

      csr_write_pos(SPADMIC_CSR_POS_CTRL, 32'h0000_0001); // back to cluster/manual
      repeat (2) @(posedge clk_sys);
    end

    // ========================================
    // TEST 14: SPAD matrix reset CSR modes
    // ========================================
    begin
      logic seen_reset;

      csr_write_pos(SPADMIC_CSR_POS_CTRL, 32'h0000_0011); // manual W1P
      #1;
      check("T14 manual reset pulse asserted", spad_matrix_rst === 1'b1);
      @(posedge clk_sys);
      #1;
      check("T14 manual reset pulse is one cycle", spad_matrix_rst === 1'b0);

      csr_write_pos(SPADMIC_CSR_POS_RESET_CFG, 32'd4);
      csr_write_pos(SPADMIC_CSR_POS_CTRL, 32'h0000_000B); // enable + raw + periodic
      wait_spad_reset_pulse(8, seen_reset);
      check("T14 periodic reset pulse appears", seen_reset === 1'b1);

      csr_write_pos(SPADMIC_CSR_POS_CTRL, 32'h0000_0005); // enable + event-deferred
      @(posedge clk_sys);
      x_lines = '0; x_lines[20] = 1; x_lines[21] = 1;
      wait_spad_reset_pulse(8, seen_reset);
      check("T14 deferred reset waits while lines active", seen_reset === 1'b0);
      @(posedge clk_sys);
      x_lines = '0; y_lines = '0; z_lines = '0;
      tx_ready = 1'b1;
      repeat (20) @(posedge clk_sys);
      tx_ready = 1'b0;
      wait_spad_reset_pulse(12, seen_reset);
      check("T14 deferred reset fires after safe idle", seen_reset === 1'b1);

      csr_write_pos(SPADMIC_CSR_POS_CTRL, 32'h0000_0001);
      csr_write_pos(SPADMIC_CSR_POS_RESET_CFG, 32'd0);
      repeat (2) @(posedge clk_sys);
    end

    // ========================================
    // SUMMARY
    // ========================================
    repeat (10) @(posedge clk_sys);
    $display("========================================");
    $display("POSITION STRESS: %0d PASS, %0d FAIL out of %0d",
             pass_count, fail_count, test_num);
    $display("========================================");
    if (fail_count > 0) $fatal(1, "STRESS TEST FAILED");
    $finish;
  end

  // Timeout watchdog
  initial begin
    #200_000_000;
    $fatal(1, "TIMEOUT");
  end

endmodule

`default_nettype wire
