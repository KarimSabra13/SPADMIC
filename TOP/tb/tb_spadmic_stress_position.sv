// ============================================================================
// Stress test: spadmic_position_block + spadmic_axis_cluster_scan
// Tests: back-to-back events, capture during busy (event-drop), CSR config,
//        multi-axis simultaneous, empty bitmaps, full bitmaps, packet format.
// ============================================================================
`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_stress_position;

  import spadmic_pkg::*;

  localparam int CLK_PERIOD = 6250;

  logic clk_sys, rst_n;
  logic enable;
  logic [126:0] x_lines, y_lines, z_lines;

  // TX output
  logic tx_valid, tx_ready;
  logic [15:0] tx_data;

  // CSR interface
  logic csr_valid, csr_write, csr_ready, csr_rvalid;
  logic [spadmic_pkg::SPADMIC_CSR_ADDR_W-1:0] csr_addr;
  logic [spadmic_pkg::SPADMIC_CSR_DATA_W-1:0] csr_wdata, csr_rdata;

  logic busy, pkt_pending;

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
    .packet_pending_o(pkt_pending)
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

  // Collect output packet
  int pkt_word_count;
  logic [15:0] pkt_words [32];

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
      // Set lines active — this triggers capture automatically
      @(posedge clk_sys);
      x_lines = '0; x_lines[10] = 1; x_lines[11] = 1; x_lines[12] = 1;
      y_lines = '0; y_lines[50] = 1; y_lines[51] = 1;
      z_lines = '0; z_lines[100] = 1;

      // Wait a couple cycles for capture to register
      repeat (3) @(posedge clk_sys);
      collect_packet(n);

      check("T1 basic packet: 11 words", n === 11);
      // Header check
      check("T1 header word", pkt_words[0][15:14] == 2'b10);
      // EOC check
      check("T1 EOC word", pkt_words[n-1][15:14] == 2'b11);

      // Clear lines
      @(posedge clk_sys);
      x_lines = '0; y_lines = '0; z_lines = '0;
      repeat (5) @(posedge clk_sys);
    end

    // ========================================
    // TEST 2: Full bitmaps (all 127 bits)
    // ========================================
    begin
      int n;
      @(posedge clk_sys);
      x_lines = {127{1'b1}};
      y_lines = {127{1'b1}};
      z_lines = {127{1'b1}};
      repeat (3) @(posedge clk_sys);
      collect_packet(n);
      check("T2 full bitmaps → 11 words", n === 11);
      @(posedge clk_sys);
      x_lines = '0; y_lines = '0; z_lines = '0;
      repeat (5) @(posedge clk_sys);
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
        x_lines = '0; x_lines[5] = 1;
        y_lines = '0; y_lines[60] = 1;
        z_lines = '0; z_lines[120] = 1;
        repeat (3) @(posedge clk_sys);
        collect_packet(n);
        total_words += n;
        // Clear lines to allow next rising edge trigger
        @(posedge clk_sys);
        x_lines = '0; y_lines = '0; z_lines = '0;
        repeat (5) @(posedge clk_sys);
      end

      check("T3 10 back-to-back events → 110 words", total_words === 110);
    end

    // ========================================
    // TEST 4: Capture during busy (event should be dropped)
    // ========================================
    begin
      int n;
      // Send first capture
      @(posedge clk_sys);
      x_lines = '0; x_lines[20] = 1;
      y_lines = '0; z_lines = '0;
      // Don't assert tx_ready — packet stays active
      repeat (3) @(posedge clk_sys);

      // Clear and re-set lines to try a second trigger while busy
      @(posedge clk_sys);
      x_lines = '0; y_lines = '0; z_lines = '0;
      repeat (2) @(posedge clk_sys);
      x_lines[30] = 1; // Try to trigger another capture
      repeat (3) @(posedge clk_sys);

      // Now collect first packet
      collect_packet(n);
      check("T4 first packet collected", n === 11);

      // Clear lines
      @(posedge clk_sys);
      x_lines = '0; y_lines = '0; z_lines = '0;

      // Wait to see if second packet appears (it shouldn't)
      tx_ready = 1'b1;
      repeat (20) @(posedge clk_sys);
      check("T4 dropped event during busy", tx_valid === 1'b0);
      tx_ready = 0;
      repeat (5) @(posedge clk_sys);
    end

    // ========================================
    // TEST 5: Backpressure on TX
    // ========================================
    begin
      int n;
      // Trigger capture
      @(posedge clk_sys);
      x_lines = '0; x_lines[30] = 1;
      y_lines = '0; y_lines[70] = 1;
      z_lines = '0; z_lines[110] = 1;
      // Hold tx_ready low for a while
      repeat (20) @(posedge clk_sys);
      // Now start collecting
      collect_packet(n);
      check("T5 backpressure → correct packet", n === 11);
      @(posedge clk_sys);
      x_lines = '0; y_lines = '0; z_lines = '0;
      repeat (5) @(posedge clk_sys);
    end

    // ========================================
    // TEST 6: Disabled → no capture
    // ========================================
    begin
      enable = 0;
      @(posedge clk_sys);
      x_lines = '0; x_lines[40] = 1;
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
        x_lines[40] = 1;
        repeat (3) @(posedge clk_sys);
        collect_packet(n);
        check("T6 re-enabled → packet OK", n === 11);
        @(posedge clk_sys);
        x_lines = '0; y_lines = '0; z_lines = '0;
        repeat (5) @(posedge clk_sys);
      end
    end

    // ========================================
    // TEST 7: Gap threshold via CSR
    // ========================================
    begin
      int n;
      // Write gap_threshold CSR (position region typically at addr 0x004)
      @(posedge clk_sys);
      csr_valid <= 1'b1;
      csr_write <= 1'b1;
      csr_addr <= 12'h004;
      csr_wdata <= 32'd5;
      @(posedge clk_sys);
      csr_valid <= 1'b0;
      repeat (4) @(posedge clk_sys);

      // Trigger capture with modified gap threshold
      x_lines = '0;
      x_lines[10] = 1; x_lines[11] = 1;
      // Gap of 4 (below threshold 5 → should merge)
      x_lines[16] = 1; x_lines[17] = 1;
      y_lines = '0; z_lines = '0;
      repeat (3) @(posedge clk_sys);
      collect_packet(n);
      check("T7 CSR gap config → packet produced", n === 11);
      @(posedge clk_sys);
      x_lines = '0; y_lines = '0; z_lines = '0;
      repeat (5) @(posedge clk_sys);
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
