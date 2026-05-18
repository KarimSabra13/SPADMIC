// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// =============================================================================
// Project : SPAD_MPTDC Verification Collateral
// File    : tb_lossless_pressure.sv
// Purpose : Lossless STOP-to-next-START pressure/deadtime regression.
// Notes   : Exercises always-ready, randomized-stall, and saturation/release
//           envelopes while checking packet accounting, overflow accounting,
//           context ownership, and PD-clear-after-context-commit ordering.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module tb_lossless_pressure;
  import mptdc_pkg::*;
  import mptdc_tb_pkg::*;

  typedef enum int unsigned {
    READY_ALWAYS = 0,
    READY_RANDOM = 1,
    READY_STALL  = 2
  } ready_mode_e;

  localparam int CONV_DELAY_PS = 10_000;
  localparam int GLOBAL_TIMEOUT_NS = 20_000_000;
  localparam int MAX_ACCOUNTING_CYCLES = 80_000;

  logic clk_sys;
  logic async_rst_n;
  logic start_spad, stop_spad, cal_start, cal_stop;
  logic csr_valid, csr_write;
  logic [CSR_ADDR_W-1:0] csr_addr;
  logic [CSR_DATA_W-1:0] csr_wdata;
  logic csr_ready, csr_rvalid;
  logic [CSR_DATA_W-1:0] csr_rdata;
  logic narrow_ready, narrow_valid;
  logic [NARROW_W-1:0] narrow_data;

  ready_mode_e ready_mode;
  int unsigned ready_rng;
  int          ready_stall_count;

  int packet_count;
  int packet_error_count;
  bit packet_active;
  int packet_word_count;
  int packet_expected_words;
  int expected_conv_id;

  bit [N_CTX-1:0] ctx_inflight;
  bit             bridge_snapshot_pending;
  bit             capture_seen_since_snapshot;
  int             protocol_error_count;

  initial clk_sys = 1'b0;
  always #(CLK_SYS_HALF) clk_sys = ~clk_sys;

  mptdc_top_asic u_dut (
    .clk_sys            (clk_sys),
    .async_rst_n        (async_rst_n),
    .start_spad_async_i (start_spad),
    .stop_spad_async_i  (stop_spad),
    .cal_start_async_i  (cal_start),
    .cal_stop_async_i   (cal_stop),
    .input_sel_override_en_i(1'b0),
    .input_sel_override_i(INPUT_SPAD),
    .out_mode_override_en_i(1'b0),
    .out_mode_override_i(OUT_MODE_RAW_FEATURES),
    .csr_valid_i        (csr_valid),
    .csr_write_i        (csr_write),
    .csr_addr_i         (csr_addr),
    .csr_wdata_i        (csr_wdata),
    .csr_ready_o        (csr_ready),
    .csr_rvalid_o       (csr_rvalid),
    .csr_rdata_o        (csr_rdata),
    .narrow_ready_i     (narrow_ready),
    .narrow_valid_o     (narrow_valid),
    .narrow_data_o      (narrow_data),
    .shared_readout_en_i(1'b0),
    .acq_ready_i        (1'b0),
    .acq_valid_o        (),
    .acq_data_o         (),
    .fifo_full_o        ()
  );

  always_ff @(posedge clk_sys or negedge async_rst_n) begin
    if (!async_rst_n) begin
      narrow_ready      <= 1'b1;
      ready_rng         <= 32'h1357_2468;
      ready_stall_count <= 0;
    end else begin
      ready_rng <= ready_rng * 32'd1664525 + 32'd1013904223;
      unique case (ready_mode)
        READY_ALWAYS: begin
          narrow_ready      <= 1'b1;
          ready_stall_count <= 0;
        end
        READY_STALL: begin
          narrow_ready      <= 1'b0;
          ready_stall_count <= 0;
        end
        READY_RANDOM: begin
          if (ready_stall_count > 0) begin
            narrow_ready      <= 1'b0;
            ready_stall_count <= ready_stall_count - 1;
          end else if ((ready_rng % 13) == 0) begin
            narrow_ready      <= 1'b0;
            ready_stall_count <= int'(ready_rng % 4) + 1;
          end else begin
            narrow_ready <= 1'b1;
          end
        end
        default: begin
          narrow_ready      <= 1'b1;
          ready_stall_count <= 0;
        end
      endcase
    end
  end

  always_ff @(posedge clk_sys or negedge async_rst_n) begin
    if (!async_rst_n) begin
      packet_count          <= 0;
      packet_error_count    <= 0;
      packet_active         <= 1'b0;
      packet_word_count     <= 0;
      packet_expected_words <= 0;
      expected_conv_id      <= 0;
    end else if (narrow_valid && narrow_ready) begin
      if (!packet_active) begin
        if (!is_header(narrow_data)) begin
          packet_error_count <= packet_error_count + 1;
          $error("[TB] Word 0x%04h outside packet is not a header", narrow_data);
        end else begin
          packet_active         <= 1'b1;
          packet_word_count     <= 1;
          packet_expected_words <= 1 + int'(header_hit_count(narrow_data)) * 2 + 1;
        end
      end else begin
        packet_word_count <= packet_word_count + 1;
        if (is_header(narrow_data)) begin
          packet_error_count <= packet_error_count + 1;
          $error("[TB] Nested header 0x%04h before EOC", narrow_data);
        end
        if (is_eoc(narrow_data)) begin
          if ((packet_word_count + 1) != packet_expected_words) begin
            packet_error_count <= packet_error_count + 1;
            $error("[TB] Packet word count %0d != expected %0d",
                   packet_word_count + 1, packet_expected_words);
          end
          if (int'(eoc_conv_id(narrow_data)) != expected_conv_id) begin
            packet_error_count <= packet_error_count + 1;
            $error("[TB] EOC conv_id %0d != expected %0d",
                   int'(eoc_conv_id(narrow_data)), expected_conv_id);
          end
          expected_conv_id  <= expected_conv_id + 1;
          packet_count      <= packet_count + 1;
          packet_active     <= 1'b0;
          packet_word_count <= 0;
        end
      end
    end
  end

  always_ff @(posedge clk_sys or negedge async_rst_n) begin
    if (!async_rst_n) begin
      ctx_inflight                <= '0;
      bridge_snapshot_pending     <= 1'b0;
      capture_seen_since_snapshot <= 1'b0;
      protocol_error_count        <= 0;
    end else begin
      if (u_dut.u_core.meas_snapshot_en) begin
        bridge_snapshot_pending     <= 1'b1;
        capture_seen_since_snapshot <= 1'b0;
      end

      if (u_dut.u_core.meas_capture_en) begin
        if (!bridge_snapshot_pending) begin
          protocol_error_count <= protocol_error_count + 1;
          $error("[TB] capture_en without prior snapshot_en");
        end
        if (ctx_inflight[u_dut.u_core.fe_active_ctx]) begin
          protocol_error_count <= protocol_error_count + 1;
          $error("[TB] Context %0d captured while still in flight",
                 int'(u_dut.u_core.fe_active_ctx));
        end
        ctx_inflight[u_dut.u_core.fe_active_ctx] <= 1'b1;
        capture_seen_since_snapshot <= 1'b1;
      end

      for (int i = 0; i < N_CTX; i++) begin
        if (u_dut.u_core.drain_ctx_release[i])
          ctx_inflight[i] <= 1'b0;
      end

      if (u_dut.u_core.meas_pd_clear) begin
        if (!capture_seen_since_snapshot) begin
          protocol_error_count <= protocol_error_count + 1;
          $error("[TB] pd_clear before context capture");
        end
        bridge_snapshot_pending     <= 1'b0;
        capture_seen_since_snapshot <= 1'b0;
      end
    end
  end

  task automatic csr_wr(input logic [CSR_ADDR_W-1:0] addr,
                        input logic [CSR_DATA_W-1:0] data);
    tb_csr_write(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata, addr, data);
  endtask

  task automatic csr_rd(input logic [CSR_ADDR_W-1:0] addr,
                        output logic [CSR_DATA_W-1:0] data);
    tb_csr_read(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata,
                csr_rvalid, csr_rdata, addr, data);
  endtask

  task automatic reset_dut();
    async_rst_n  = 1'b0;
    start_spad   = 1'b0;
    stop_spad    = 1'b0;
    cal_start    = 1'b0;
    cal_stop     = 1'b0;
    csr_valid    = 1'b0;
    csr_write    = 1'b0;
    csr_addr     = '0;
    csr_wdata    = '0;
    ready_mode   = READY_ALWAYS;
    repeat (20) @(posedge clk_sys);
    async_rst_n = 1'b1;
    repeat (40) @(posedge clk_sys);
  endtask

  task automatic configure_persistent_arm(input int max_hits);
    csr_wr(CSR_CTRL,      32'h0000_0000);
    csr_wr(CSR_MODE,      32'h0000_0000);
    csr_wr(CSR_MAX_HITS,  {28'd0, max_hits[3:0]});
    csr_wr(CSR_WDT_CTX,   32'h0000_FFFF);
    csr_wr(CSR_WDT_GLOBAL,32'h0000_0000);
    csr_wr(CSR_CTRL,      32'h0000_0001);
    repeat (12) @(posedge clk_sys);
  endtask

  task automatic fire_conversion(input int stop_delay_ps, output longint stop_time_ps);
    start_spad = 1'b1;
    #(1_000);
    start_spad = 1'b0;
    #(stop_delay_ps);
    stop_spad = 1'b1;
    stop_time_ps = longint'($realtime);
    #(1_000);
    stop_spad = 1'b0;
  endtask

  task automatic read_counts(output int conv_count,
                             output int ovf_count,
                             output int fifo_level,
                             output bit fifo_full);
    logic [CSR_DATA_W-1:0] data;
    csr_rd(CSR_CONV_COUNT, data);
    conv_count = int'(data);
    csr_rd(CSR_OVF_COUNT, data);
    ovf_count = int'(data[15:0]);
    csr_rd(CSR_FIFO_STATUS, data);
    fifo_level = int'(data[FIFO_LVL_W-1:0]);
    fifo_full = data[FIFO_LVL_W];
  endtask

  task automatic wait_for_accounting(input int attempts,
                                     input int conv_before,
                                     input int ovf_before,
                                     output int conv_delta,
                                     output int ovf_delta);
    int conv_now;
    int ovf_now;
    int fifo_level;
    int cycles;
    bit fifo_full;
    cycles = 0;
    do begin
      repeat (20) @(posedge clk_sys);
      read_counts(conv_now, ovf_now, fifo_level, fifo_full);
      cycles += 20;
    end while (((conv_now - conv_before) + (ovf_now - ovf_before) < attempts)
               && (cycles < MAX_ACCOUNTING_CYCLES));

    conv_delta = conv_now - conv_before;
    ovf_delta  = ovf_now - ovf_before;
    if ((conv_delta + ovf_delta) != attempts) begin
      $fatal(1,
        "[TB] Accounting timeout: attempts=%0d conv_delta=%0d ovf_delta=%0d fifo_level=%0d fifo_full=%0b",
        attempts, conv_delta, ovf_delta, fifo_level, fifo_full);
    end
  endtask

  task automatic wait_for_packets(input int target_packet_count);
    int cycles;
    cycles = 0;
    while ((packet_count < target_packet_count) && (cycles < MAX_ACCOUNTING_CYCLES)) begin
      @(posedge clk_sys);
      cycles++;
    end
    if (packet_count < target_packet_count) begin
      $fatal(1, "[TB] Packet drain timeout: packet_count=%0d target=%0d",
             packet_count, target_packet_count);
    end
  endtask

  task automatic run_gap_envelope(input string label,
                                  input int max_hits,
                                  input ready_mode_e mode,
                                  input bit expect_zero_reject);
    int conv_before, ovf_before, fifo_level_before;
    int conv_delta, ovf_delta;
    int packet_before;
    bit fifo_full_before;
    longint stop_time_ps;
    int gaps_ps [0:7];

    gaps_ps = '{60_000, 55_000, 50_000, 45_000, 42_000, 40_000, 50_000, 60_000};
    reset_dut();
    configure_persistent_arm(max_hits);
    ready_mode = mode;
    read_counts(conv_before, ovf_before, fifo_level_before, fifo_full_before);
    packet_before = packet_count;

    $display("[TB] Envelope %s max_hits=%0d attempts=%0d", label, max_hits, 8);
    for (int i = 0; i < 8; i++) begin
      fire_conversion(CONV_DELAY_PS, stop_time_ps);
      #(gaps_ps[i]);
    end

    ready_mode = READY_ALWAYS;
    wait_for_accounting(8, conv_before, ovf_before, conv_delta, ovf_delta);
    wait_for_packets(packet_before + conv_delta);

    if (expect_zero_reject && (ovf_delta != 0))
      $fatal(1, "[TB] %s max_hits=%0d expected zero rejects, got %0d",
             label, max_hits, ovf_delta);
    if ((packet_count - packet_before) != conv_delta)
      $fatal(1, "[TB] %s max_hits=%0d packet_delta=%0d conv_delta=%0d",
             label, max_hits, packet_count - packet_before, conv_delta);

    $display("[TB] %s max_hits=%0d PASS attempts=8 accepted=%0d rejected=%0d",
             label, max_hits, conv_delta, ovf_delta);
  endtask

  task automatic run_saturation_envelope(input int max_hits);
    int conv_before, ovf_before, fifo_level_before;
    int conv_delta, ovf_delta;
    int packet_before;
    int attempts;
    bit fifo_full_before;
    longint stop_time_ps;

    attempts = (max_hits == 1) ? 40 : 28;
    reset_dut();
    configure_persistent_arm(max_hits);
    ready_mode = READY_STALL;
    read_counts(conv_before, ovf_before, fifo_level_before, fifo_full_before);
    packet_before = packet_count;

    $display("[TB] Envelope saturation_release max_hits=%0d attempts=%0d",
             max_hits, attempts);
    for (int i = 0; i < attempts; i++) begin
      fire_conversion(CONV_DELAY_PS, stop_time_ps);
      #(60_000);
    end

    repeat (40) @(posedge clk_sys);
    ready_mode = READY_ALWAYS;
    wait_for_accounting(attempts, conv_before, ovf_before, conv_delta, ovf_delta);
    wait_for_packets(packet_before + conv_delta);

    if (ovf_delta == 0)
      $fatal(1, "[TB] saturation_release max_hits=%0d expected rejects under saturation", max_hits);
    if ((conv_delta + ovf_delta) != attempts)
      $fatal(1, "[TB] saturation_release max_hits=%0d accepted+rejected mismatch", max_hits);
    if ((packet_count - packet_before) != conv_delta)
      $fatal(1, "[TB] saturation_release max_hits=%0d packet_delta=%0d conv_delta=%0d",
             max_hits, packet_count - packet_before, conv_delta);

    fire_conversion(CONV_DELAY_PS, stop_time_ps);
    #(80_000);
    wait_for_accounting(attempts + 1, conv_before, ovf_before, conv_delta, ovf_delta);
    wait_for_packets(packet_before + conv_delta);
    if ((packet_count - packet_before) != conv_delta)
      $fatal(1, "[TB] post-release recovery packet mismatch");

    $display("[TB] saturation_release max_hits=%0d PASS accepted=%0d rejected=%0d",
             max_hits, conv_delta, ovf_delta);
  endtask

  initial begin
    int max_hits_values [0:3];
    max_hits_values = '{1, 15, 2, 8};

    async_rst_n  = 1'b0;
    start_spad   = 1'b0;
    stop_spad    = 1'b0;
    cal_start    = 1'b0;
    cal_stop     = 1'b0;
    csr_valid    = 1'b0;
    csr_write    = 1'b0;
    csr_addr     = '0;
    csr_wdata    = '0;
    ready_mode   = READY_ALWAYS;

    $display("[TB] ===== LOSSLESS PRESSURE / DEADTIME TEST =====");

    foreach (max_hits_values[i]) begin
      run_gap_envelope("always_ready", max_hits_values[i], READY_ALWAYS, 1'b0);
      run_gap_envelope("random_short_stalls", max_hits_values[i], READY_RANDOM, 1'b0);
      run_saturation_envelope(max_hits_values[i]);
    end

    if (packet_error_count != 0)
      $fatal(1, "[TB] Packet monitor saw %0d error(s)", packet_error_count);
    if (protocol_error_count != 0)
      $fatal(1, "[TB] Protocol monitor saw %0d error(s)", protocol_error_count);

    $display("[TB] ===== TEST PASSED =====");
    $finish;
  end

  initial begin
    #(GLOBAL_TIMEOUT_NS * 1ns);
    $fatal(1, "[TB] Global timeout");
  end

endmodule

`default_nettype wire
