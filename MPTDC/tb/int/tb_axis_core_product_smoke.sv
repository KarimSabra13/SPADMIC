// SPDX-FileCopyrightText: 2026 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// =============================================================================
// Project : SPAD_MPTDC Verification Collateral
// File    : tb_axis_core_product_smoke.sv
// Purpose : Product-only mptdc_axis_core smoke test.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module tb_axis_core_product_smoke;
  import mptdc_pkg::*;
  import mptdc_tb_pkg::*;

  logic clk_sys;
  logic async_rst_n;
  logic start_spad;
  logic stop_spad;
  logic cal_start;
  logic cal_stop;
  input_sel_e input_sel;
  logic conv_arm;
  logic fifo_clr;
  logic soft_reset;
  logic [MAX_HITS_W-1:0] max_hits;
  logic [7:0] ro_slow_code;
  logic [7:0] ro_fast_code;
  logic pkt_valid;
  logic pkt_ready;
  logic [NARROW_W-1:0] pkt_data;
  logic pkt_sop;
  logic pkt_eop;
  logic packet_active;
  logic packet_pending;
  logic ro_slow_tap0;
  logic ro_fast_tap0;
  logic ready;
  logic busy;
  logic fifo_full;

  int pass_count;
  int fail_count;
  logic [NARROW_W-1:0] pkt_words [$];
  int pkt_word_count;

  initial clk_sys = 1'b0;
  always #(CLK_SYS_HALF) clk_sys = ~clk_sys;

  mptdc_axis_core u_dut (
    .clk_sys            (clk_sys),
    .async_rst_n        (async_rst_n),
    .start_spad_async_i (start_spad),
    .stop_spad_async_i  (stop_spad),
    .cal_start_async_i  (cal_start),
    .cal_stop_async_i   (cal_stop),
    .input_sel_i        (input_sel),
    .conv_arm_i         (conv_arm),
    .fifo_clr_i         (fifo_clr),
    .soft_reset_i       (soft_reset),
    .max_hits_i         (max_hits),
    .ro_slow_code_i     (ro_slow_code),
    .ro_fast_code_i     (ro_fast_code),
    .pkt_valid_o        (pkt_valid),
    .pkt_ready_i        (pkt_ready),
    .pkt_data_o         (pkt_data),
    .pkt_sop_o          (pkt_sop),
    .pkt_eop_o          (pkt_eop),
    .packet_active_o    (packet_active),
    .packet_pending_o   (packet_pending),
    .ro_slow_tap0_o     (ro_slow_tap0),
    .ro_fast_tap0_o     (ro_fast_tap0),
    .ready_o            (ready),
    .busy_o             (busy),
    .fifo_full_o        (fifo_full)
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

  task automatic apply_reset();
    async_rst_n = 1'b0;
    start_spad = 1'b0;
    stop_spad = 1'b0;
    cal_start = 1'b0;
    cal_stop = 1'b0;
    input_sel = INPUT_SPAD;
    conv_arm = 1'b0;
    fifo_clr = 1'b0;
    soft_reset = 1'b0;
    max_hits = MAX_HITS_W'(MAX_HITS);
    ro_slow_code = 8'h00;
    ro_fast_code = 8'h00;
    pkt_ready = 1'b1;
    repeat (8) @(posedge clk_sys);
    #1;
    async_rst_n = 1'b1;
    repeat (12) @(posedge clk_sys);
    #1;
  endtask

  task automatic collect_axis_packet(
    output logic [NARROW_W-1:0] words [$],
    output int word_count
  );
    logic saw_sop;
    words = {};
    word_count = 0;
    saw_sop = 1'b0;
    pkt_ready = 1'b1;

    while (!saw_sop) begin
      @(posedge clk_sys);
      if (pkt_valid && pkt_ready) begin
        check("First accepted word carries SOP", pkt_sop);
        words.push_back(pkt_data);
        word_count++;
        saw_sop = 1'b1;
      end
    end

    while (1) begin
      @(posedge clk_sys);
      if (pkt_valid && pkt_ready) begin
        words.push_back(pkt_data);
        word_count++;
        if (pkt_eop)
          break;
      end
    end
  endtask

  task automatic verify_packet(
    input string label,
    input logic [NARROW_W-1:0] words [$],
    input int word_count,
    input int unsigned max_hits_expected
  );
    logic [NARROW_W-1:0] hdr;
    logic [NARROW_W-1:0] eoc_w;
    int unsigned hits;
    int unsigned expected_words;

    check({label, " has header and EOC"}, word_count >= 2);
    if (word_count < 2)
      return;

    hdr = words[0];
    eoc_w = words[word_count-1];
    hits = header_hit_count(hdr);
    expected_words = 1 + (2 * hits) + 1;

    check({label, " header type"}, is_header(hdr));
    check({label, " generic source bits"}, hdr[1:0] == 2'b00);
    check({label, " hit cap"}, hits <= max_hits_expected);
    check({label, " word count"}, word_count == expected_words);
    check({label, " EOC type"}, is_eoc(eoc_w));
    check({label, " EOC placeholder id"}, eoc_w[13:0] == 14'd0);
  endtask

  initial begin
    pass_count = 0;
    fail_count = 0;

    apply_reset();
    conv_arm = 1'b1;
    repeat (4) @(posedge clk_sys);
    #1;
    check("Axis leaves reset ready", ready);
    check("Axis FIFO not full after reset", !fifo_full);
    check("Default slow RO code captured", u_dut.u_core.ro_slow_code_q == 8'h00);
    check("Default fast RO code captured", u_dut.u_core.ro_fast_code_q == 8'h00);

    ro_slow_code = 8'h3c;
    ro_fast_code = 8'ha5;
    repeat (3) @(posedge clk_sys);
    #1;
    check("Idle slow RO code captured", u_dut.u_core.ro_slow_code_q == 8'h3c);
    check("Idle fast RO code captured", u_dut.u_core.ro_fast_code_q == 8'ha5);

    max_hits = MAX_HITS_W'(2);
    #1;
    inject_pulse_pair(start_spad, stop_spad, 10_000ps);
    collect_axis_packet(pkt_words, pkt_word_count);
    verify_packet("max_hits=2 packet", pkt_words, pkt_word_count, 2);
    while (pkt_valid)
      @(posedge clk_sys);
    #1;

    pkt_ready = 1'b0;
    repeat (4) @(posedge clk_sys);
    inject_pulse_pair(start_spad, stop_spad, 10_000ps);
    while (!pkt_valid)
      @(posedge clk_sys);
    #1;
    begin
      logic [NARROW_W-1:0] held_data;
      logic held_sop;
      logic held_eop;
      held_data = pkt_data;
      held_sop = pkt_sop;
      held_eop = pkt_eop;
      repeat (5) begin
        @(posedge clk_sys);
        #1;
        check("Packet data stable under stall", pkt_valid && pkt_data == held_data);
        check("Packet SOP stable under stall", pkt_sop == held_sop);
        check("Packet EOP stable under stall", pkt_eop == held_eop);
      end
    end
    collect_axis_packet(pkt_words, pkt_word_count);
    verify_packet("stalled packet", pkt_words, pkt_word_count, 2);

    soft_reset = 1'b1;
    @(posedge clk_sys);
    #1;
    ro_slow_code = 8'h12;
    ro_fast_code = 8'h34;
    soft_reset = 1'b0;
    repeat (16) @(posedge clk_sys);
    #1;
    check("Soft reset returns ready", ready);
    check("Soft reset clears packet outputs", !pkt_valid && !packet_active && !packet_pending);
    check("Soft reset does not force slow RO code zero", u_dut.u_core.ro_slow_code_q == 8'h12);
    check("Soft reset does not force fast RO code zero", u_dut.u_core.ro_fast_code_q == 8'h34);

    fifo_clr = 1'b1;
    @(posedge clk_sys);
    #1;
    fifo_clr = 1'b0;
    check("FIFO clear leaves FIFO not full", !fifo_full);

    if (fail_count != 0)
      $fatal(1, "tb_axis_core_product_smoke: %0d failures", fail_count);
    $display("tb_axis_core_product_smoke: %0d pass / %0d fail", pass_count, fail_count);
    $finish;
  end

  initial begin
    #(TB_TIMEOUT_CYC * CLK_SYS_PERIOD);
    $fatal(1, "TIMEOUT");
  end

endmodule

`default_nettype wire
