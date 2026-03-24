`timescale 1ns/1ps

module tb_multi_conv_stress;
  import mptdc_pkg::*;
  import mptdc_tb_pkg::*;

  // ── Parameters ──────────────────────────────────────────────
  localparam int NUM_CONVERSIONS = 100;
  localparam int TIMEOUT_CYC     = TB_TIMEOUT_CYC;

  // ── Clock generation ────────────────────────────────────────
  logic clk_sys;
  initial clk_sys = 1'b0;
  always #(CLK_SYS_HALF) clk_sys = ~clk_sys;

  // ── Signals ─────────────────────────────────────────────────
  logic                   async_rst_n;
  logic                   start_spad, stop_spad;
  logic                   cal_start,  cal_stop;

  logic                   csr_valid, csr_write;
  logic [CSR_ADDR_W-1:0]  csr_addr;
  logic [CSR_DATA_W-1:0]  csr_wdata;
  logic                   csr_ready, csr_rvalid;
  logic [CSR_DATA_W-1:0]  csr_rdata;

  logic                   narrow_ready;
  logic                   narrow_valid;
  logic [NARROW_W-1:0]    narrow_data;

  // Packet collection storage
  logic [NARROW_W-1:0]    pkt_words [$];
  int                     pkt_cnt;

  // ── DUT ─────────────────────────────────────────────────────
  mptdc_top_asic u_dut (
    .clk_sys            (clk_sys),
    .async_rst_n        (async_rst_n),
    .start_spad_async_i (start_spad),
    .stop_spad_async_i  (stop_spad),
    .cal_start_async_i  (cal_start),
    .cal_stop_async_i   (cal_stop),
    .csr_valid_i        (csr_valid),
    .csr_write_i        (csr_write),
    .csr_addr_i         (csr_addr),
    .csr_wdata_i        (csr_wdata),
    .csr_ready_o        (csr_ready),
    .csr_rvalid_o       (csr_rvalid),
    .csr_rdata_o        (csr_rdata),
    .narrow_ready_i     (narrow_ready),
    .narrow_valid_o     (narrow_valid),
    .narrow_data_o      (narrow_data)
  );

  // ── CSR helper ──────────────────────────────────────────────
  task automatic csr_wr(
    input logic [CSR_ADDR_W-1:0] addr,
    input logic [CSR_DATA_W-1:0] data
  );
    tb_csr_write(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata, addr, data);
  endtask

  // ── Main test ───────────────────────────────────────────────
  initial begin
    int hdr_hits;
    int exp_words;
    int got_conv_id;
    bit timed_out;

    // Defaults
    start_spad   = 1'b0;
    stop_spad    = 1'b0;
    cal_start    = 1'b0;
    cal_stop     = 1'b0;
    csr_valid    = 1'b0;
    csr_write    = 1'b0;
    csr_addr     = '0;
    csr_wdata    = '0;
    narrow_ready = 1'b1;
    async_rst_n  = 1'b0;

    // Reset
    #100ns;
    async_rst_n = 1'b1;
    #50ns;

    // Configure: MULTI_HIT, SPAD input, RAW_FEATURES output
    csr_wr(CSR_MODE,       32'h0000_0000);
    csr_wr(CSR_MAX_HITS,   {28'd0, 4'(MAX_HITS)});
    csr_wr(CSR_WDT_CTX,    32'h0000_0000);
    csr_wr(CSR_WDT_GLOBAL, 32'h0000_0000);
    #50ns;

    // ── Back-to-back conversion loop ──────────────────────────
    for (int conv = 0; conv < NUM_CONVERSIONS; conv++) begin

      // Arm conversion
      csr_wr(CSR_CTRL, 32'h0000_0001);
      #50ns;

      // Inject START pulse
      start_spad = 1'b1;
      #1ns;
      start_spad = 1'b0;

      // Wait, then inject STOP pulse
      #10ns;
      stop_spad = 1'b1;
      #1ns;
      stop_spad = 1'b0;

      // Collect packet with timeout
      timed_out = 0;
      fork
        collect_packet(clk_sys, narrow_valid, narrow_ready, narrow_data,
                       pkt_words, pkt_cnt);
        begin
          repeat (TIMEOUT_CYC) @(posedge clk_sys);
          timed_out = 1;
        end
      join_any
      disable fork;

      // Let FSM settle back to IDLE (writer_done pulse-sync latency)
      repeat (20) @(posedge clk_sys);

      if (timed_out) begin
        $error("[TB] TIMEOUT on conversion %0d", conv);
        $finish;
      end

      // ── Verify header ──────────────────────────────────────
      if (pkt_cnt < 2) begin
        $error("[TB] conv %0d: packet too short (%0d words)", conv, pkt_cnt);
        $finish;
      end

      assert (is_header(pkt_words[0])) else begin
        $error("[TB] conv %0d: first word 0x%04h is not a header", conv, pkt_words[0]);
        $finish;
      end

      hdr_hits = int'(header_hit_count(pkt_words[0]));
      if (hdr_hits == 0) begin
        $error("[TB] conv %0d: hit_count == 0 in header", conv);
        $finish;
      end

      // ── Verify EOC ─────────────────────────────────────────
      assert (is_eoc(pkt_words[pkt_cnt-1])) else begin
        $error("[TB] conv %0d: last word 0x%04h is not EOC", conv, pkt_words[pkt_cnt-1]);
        $finish;
      end

      got_conv_id = int'(eoc_conv_id(pkt_words[pkt_cnt-1]));
      if (got_conv_id !== conv) begin
        $error("[TB] conv %0d: conv_id mismatch (expected %0d, got %0d)",
               conv, conv, got_conv_id);
        $finish;
      end

      // ── Verify word count: 1 header + hits*3 + 1 EOC ──────
      exp_words = 1 + hdr_hits * 3 + 1;
      if (pkt_cnt !== exp_words) begin
        $error("[TB] conv %0d: word_count mismatch (expected %0d, got %0d)",
               conv, exp_words, pkt_cnt);
        $finish;
      end

      // Progress
      if ((conv + 1) % 10 == 0)
        $display("[TB] %0d / %0d conversions OK", conv + 1, NUM_CONVERSIONS);
    end

    $display("[TB] ===== TEST PASSED =====");
    #100ns;
    $finish;
  end

endmodule
