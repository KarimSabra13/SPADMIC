// SPDX-FileCopyrightText: 2026 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// =============================================================================
// Project : SPAD_MPTDC Verification Collateral
// File    : tb_10_events_spacing_sweep.sv
// Purpose : Ten-event spacing sweep for lossless/reject accounting.
// Notes   : Accepted conversions must produce well-formed packets. Attempts
//           below the safe interval may reject, but accounting must close.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module tb_10_events_spacing_sweep;
  import mptdc_pkg::*;
  import mptdc_tb_pkg::*;

  localparam int N_SPACINGS = 8;
  localparam int N_EVENTS   = 10;
  localparam int SETTLE_CYC = 120_000;

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

  int spacings_ns [0:N_SPACINGS-1];
  int packet_count;
  int packet_error_count;
  bit packet_active;
  int packet_word_count;
  int packet_expected_words;
  int expected_conv_id;

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
            $error("[TB] Packet words %0d != expected %0d",
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
    narrow_ready = 1'b1;
    repeat (20) @(posedge clk_sys);
    async_rst_n = 1'b1;
    repeat (40) @(posedge clk_sys);
  endtask

  task automatic configure();
    csr_wr(CSR_CTRL,       32'h0000_0000);
    csr_wr(CSR_MODE,       32'h0000_0000);
    csr_wr(CSR_MAX_HITS,   32'h0000_000F);
    csr_wr(CSR_WDT_CTX,    32'h0000_FFFF);
    csr_wr(CSR_WDT_GLOBAL, 32'h0000_0000);
    csr_wr(CSR_CTRL,       32'h0000_0001);
    repeat (12) @(posedge clk_sys);
  endtask

  task automatic fire_conversion();
    start_spad = 1'b1;
    #1ns;
    start_spad = 1'b0;
    #10ns;
    stop_spad = 1'b1;
    #1ns;
    stop_spad = 1'b0;
  endtask

  task automatic read_counts(output int conv_count, output int ovf_count);
    logic [CSR_DATA_W-1:0] data;
    csr_rd(CSR_CONV_COUNT, data);
    conv_count = int'(data);
    csr_rd(CSR_OVF_COUNT, data);
    ovf_count = int'(data[15:0]);
  endtask

  task automatic wait_accounting(input int attempts,
                                 output int conv_count,
                                 output int ovf_count);
    int cycles;
    cycles = 0;
    do begin
      repeat (20) @(posedge clk_sys);
      read_counts(conv_count, ovf_count);
      cycles += 20;
    end while (((conv_count + ovf_count) < attempts) && (cycles < SETTLE_CYC));

    if ((conv_count + ovf_count) != attempts)
      $fatal(1, "[TB] accounting timeout conv=%0d ovf=%0d attempts=%0d",
             conv_count, ovf_count, attempts);
  endtask

  task automatic wait_packets(input int target_packets);
    int cycles;
    cycles = 0;
    while ((packet_count < target_packets) && (cycles < SETTLE_CYC)) begin
      @(posedge clk_sys);
      cycles++;
    end
    if (packet_count != target_packets)
      $fatal(1, "[TB] packet timeout packets=%0d target=%0d",
             packet_count, target_packets);
  endtask

  task automatic run_spacing(input int spacing_ns);
    int conv_count;
    int ovf_count;
    int start_packets;

    reset_dut();
    configure();
    start_packets = packet_count;

    for (int ev = 0; ev < N_EVENTS; ev++) begin
      fire_conversion();
      if (ev != (N_EVENTS - 1))
        #(spacing_ns * 1ns);
    end

    wait_accounting(N_EVENTS, conv_count, ovf_count);
    wait_packets(start_packets + conv_count);

    if (packet_error_count != 0)
      $fatal(1, "[TB] packet monitor saw %0d error(s)", packet_error_count);
    if (spacing_ns >= 600 && ovf_count != 0)
      $fatal(1, "[TB] spacing=%0dns expected no rejects, got %0d",
             spacing_ns, ovf_count);

    $display("[TB] spacing=%0dns PASS attempts=%0d accepted=%0d rejected=%0d",
             spacing_ns, N_EVENTS, conv_count, ovf_count);
  endtask

  initial begin
    spacings_ns = '{40, 60, 80, 100, 150, 200, 300, 600};
    async_rst_n  = 1'b0;
    start_spad   = 1'b0;
    stop_spad    = 1'b0;
    cal_start    = 1'b0;
    cal_stop     = 1'b0;
    csr_valid    = 1'b0;
    csr_write    = 1'b0;
    csr_addr     = '0;
    csr_wdata    = '0;
    narrow_ready = 1'b1;

    $display("[TB] ===== 10-EVENT SPACING SWEEP =====");
    foreach (spacings_ns[i])
      run_spacing(spacings_ns[i]);

    $display("[TB] ===== TEST PASSED =====");
    $finish;
  end

  initial begin
    #20_000_000ns;
    $fatal(1, "[TB] Global timeout");
  end
endmodule

`default_nettype wire
