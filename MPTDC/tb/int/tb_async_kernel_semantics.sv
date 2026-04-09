// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// =============================================================================
// Project : SPAD_MPTDC Verification Collateral
// File    : tb_async_kernel_semantics.sv
// Purpose : Block-owner checks for async kernel acceptance/rejection, state
//           sequencing, and watchdog/reset collisions.
// Author  : Karim Sabra
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module tb_async_kernel_semantics;
  import mptdc_pkg::*;
  import mptdc_tb_pkg::*;

  logic clk_sys;
  logic async_rst_n;
  initial clk_sys = 1'b0;
  always #(CLK_SYS_HALF) clk_sys = ~clk_sys;

  logic start_spad, stop_spad, cal_start, cal_stop;
  logic                   csr_valid, csr_write;
  logic [CSR_ADDR_W-1:0]  csr_addr;
  logic [CSR_DATA_W-1:0]  csr_wdata;
  logic                   csr_ready, csr_rvalid;
  logic [CSR_DATA_W-1:0]  csr_rdata;
  logic                   narrow_ready, narrow_valid;
  logic [NARROW_W-1:0]    narrow_data;

  logic [NARROW_W-1:0] pkt [$];
  int wc;

  mptdc_top_asic u_dut (
    .clk_sys(clk_sys), .async_rst_n(async_rst_n),
    .start_spad_async_i(start_spad), .stop_spad_async_i(stop_spad),
    .cal_start_async_i(cal_start), .cal_stop_async_i(cal_stop),
    .input_sel_override_en_i(1'b0),
    .input_sel_override_i(INPUT_SPAD),
    .out_mode_override_en_i(1'b0),
    .out_mode_override_i(OUT_MODE_RAW_FEATURES),
    .csr_valid_i(csr_valid), .csr_write_i(csr_write),
    .csr_addr_i(csr_addr), .csr_wdata_i(csr_wdata),
    .csr_ready_o(csr_ready), .csr_rvalid_o(csr_rvalid),
    .csr_rdata_o(csr_rdata),
    .narrow_ready_i(narrow_ready), .narrow_valid_o(narrow_valid),
    .narrow_data_o(narrow_data),
    .shared_readout_en_i(1'b0), .acq_ready_i(1'b0),
    .acq_valid_o(), .acq_data_o(), .fifo_full_o()
  );

  task automatic csr_wr(input logic [CSR_ADDR_W-1:0] a, input logic [CSR_DATA_W-1:0] d);
    tb_csr_write(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata, a, d);
  endtask

  task automatic csr_rd(
    input logic [CSR_ADDR_W-1:0] a,
    output logic [CSR_DATA_W-1:0] d
  );
    tb_csr_read(clk_sys, csr_valid, csr_write, csr_addr, csr_wdata,
                csr_rvalid, csr_rdata, a, d);
  endtask

  task automatic apply_reset();
    async_rst_n = 1'b0;
    start_spad = 1'b0;
    stop_spad = 1'b0;
    cal_start = 1'b0;
    cal_stop = 1'b0;
    csr_valid = 1'b0;
    csr_write = 1'b0;
    csr_addr = '0;
    csr_wdata = '0;
    narrow_ready = 1'b1;
    #100_000;
    async_rst_n = 1'b1;
    #100_000;
  endtask

  function automatic logic status_ready(input logic [CSR_DATA_W-1:0] w);
    return w[0];
  endfunction

  function automatic logic status_busy(input logic [CSR_DATA_W-1:0] w);
    return w[1];
  endfunction

  function automatic ctx_state_e status_ctx0(input logic [CSR_DATA_W-1:0] w);
    return ctx_state_e'(w[3:2]);
  endfunction

  task automatic expect_no_packet_for(input time delay_ps);
    fork
      begin
        #(delay_ps);
      end
      begin
        wait (narrow_valid === 1'b1);
        $error("[TB] Unexpected narrow packet activity");
        $finish;
      end
    join_any
    disable fork;
  endtask

  initial begin
    logic [CSR_DATA_W-1:0] rd_data;
    tdc_conv_flags_t flags;

    apply_reset();

    $display("[TB] === tb_async_kernel_semantics ===");

    // -----------------------------------------------------------------------
    // TEST 1: START/STOP acceptance and rejection from idle/unarmed states
    // -----------------------------------------------------------------------
    $display("[TB] Test 1: idle STOP ignored, unarmed START rejected");

    stop_spad = 1'b1; #1000; stop_spad = 1'b0;
    expect_no_packet_for(100_000);
    csr_rd(CSR_STATUS, rd_data);
    assert (!status_busy(rd_data)) else begin
      $error("[TB] FAIL Test 1: idle STOP made the DUT busy");
      $finish;
    end
    csr_rd(CSR_CONV_COUNT, rd_data);
    assert (rd_data == '0) else begin
      $error("[TB] FAIL Test 1: idle STOP changed conversion count");
      $finish;
    end

    start_spad = 1'b1; #1000; start_spad = 1'b0;
    repeat (4) @(posedge clk_sys);
    csr_rd(CSR_STATUS, rd_data);
    assert (!status_ready(rd_data) && !status_busy(rd_data)) else begin
      $error("[TB] FAIL Test 1: unarmed START changed ready/busy state (0x%08h)", rd_data);
      $finish;
    end
    csr_rd(CSR_OVF_COUNT, rd_data);
    assert (rd_data[15:0] == 16'd1) else begin
      $error("[TB] FAIL Test 1: rejected START did not increment OVF_COUNT (0x%08h)", rd_data);
      $finish;
    end

    // -----------------------------------------------------------------------
    // TEST 2: max_hits=1 fast close keeps context CAPTURING until clear
    // -----------------------------------------------------------------------
    $display("[TB] Test 2: fast-close state sequencing");

    csr_wr(CSR_MODE,       32'h0000_0000);
    csr_wr(CSR_MAX_HITS,   32'h0000_0001);
    csr_wr(CSR_WDT_CTX,    32'h0000_FFFF);
    csr_wr(CSR_WDT_GLOBAL, 32'h0000_0000);
    #50_000;

    csr_wr(CSR_CTRL, 32'h0000_0001);
    #50_000;
    csr_rd(CSR_STATUS, rd_data);
    assert (status_ready(rd_data) && !status_busy(rd_data)
            && status_ctx0(rd_data) == CTX_FREE) else begin
      $error("[TB] FAIL Test 2: DUT not ready before accepted START (0x%08h)", rd_data);
      $finish;
    end

    start_spad = 1'b1; #1000; start_spad = 1'b0;
    wait (u_dut.u_core.fe_start_latched === 1'b1);
    repeat (3) @(posedge clk_sys);
    csr_rd(CSR_STATUS, rd_data);
    assert (status_busy(rd_data) && status_ctx0(rd_data) == CTX_CAPTURING) else begin
      $error("[TB] FAIL Test 2: accepted START did not enter CAPTURING (0x%08h)", rd_data);
      $finish;
    end

    stop_spad = 1'b1; #1000; stop_spad = 1'b0;

    fork
      begin
        @(posedge u_dut.u_core.meas_capture_en);
        assert (u_dut.u_core.meas_state == ST_M_CAPTURE) else begin
          $error("[TB] FAIL Test 2: capture pulse arrived outside ST_M_CAPTURE");
          $finish;
        end
        assert (u_dut.u_core.fe_ctx_drain[0]) else begin
          $error("[TB] FAIL Test 2: ctx0 did not reserve for draining at capture");
          $finish;
        end
        assert (u_dut.u_core.ctx_state_packed[1:0] == CTX_CAPTURING) else begin
          $error("[TB] FAIL Test 2: ctx0 left CAPTURING too early (state=%0d)",
                 u_dut.u_core.ctx_state_packed[1:0]);
          $finish;
        end
      end
      begin
        #5_000_000;
        $error("[TB] TIMEOUT Test 2 waiting for capture");
        $finish;
      end
    join_any
    disable fork;

    fork
      begin
        wait (u_dut.u_core.meas_fe_clear === 1'b1);
        #1;
        assert (u_dut.u_core.ctx_state_packed[1:0] == CTX_DRAINING) else begin
          $error("[TB] FAIL Test 2: ctx0 did not enter DRAINING after clear");
          $finish;
        end
      end
      begin
        #5_000_000;
        $error("[TB] TIMEOUT Test 2 waiting for fe_clear");
        $finish;
      end
    join_any
    disable fork;

    fork
      collect_packet(clk_sys, narrow_valid, narrow_ready, narrow_data, pkt, wc);
      begin #5_000_000; $error("[TB] TIMEOUT Test 2 packet"); $finish; end
    join_any
    disable fork;

    assert (wc >= 2 && is_header(pkt[0]) && is_eoc(pkt[wc-1])) else begin
      $error("[TB] FAIL Test 2: malformed fast-close packet");
      $finish;
    end
    flags = header_flags(pkt[0]);
    assert (flags.closed_by_fast_maxhit && !flags.closed_by_watchdog) else begin
      $error("[TB] FAIL Test 2: wrong fast-close flags (%04b)", flags);
      $finish;
    end

    // -----------------------------------------------------------------------
    // TEST 3: START-only watchdog collision with async reset aborts cleanly
    // -----------------------------------------------------------------------
    $display("[TB] Test 3: watchdog/reset collision recovery");

    csr_wr(CSR_MAX_HITS,   32'h0000_0000);
    csr_wr(CSR_WDT_CTX,    32'h0000_0200);
    csr_wr(CSR_WDT_GLOBAL, 32'h0000_0000);
    #50_000;

    csr_wr(CSR_CTRL, 32'h0000_0001);
    #50_000;
    start_spad = 1'b1; #1000; start_spad = 1'b0;

    fork
      begin
        wait (u_dut.u_core.fe_stop_latched === 1'b1);
        wait (u_dut.u_core.meas_state == ST_M_MEASURE);
        #10_000;
        async_rst_n = 1'b0;
      end
      begin
        #10_000_000;
        $error("[TB] TIMEOUT Test 3 waiting for synthetic STOP");
        $finish;
      end
    join_any
    disable fork;

    #100_000;
    async_rst_n = 1'b1;
    #150_000;

    expect_no_packet_for(200_000);
    assert (u_dut.u_core.meas_state == ST_M_IDLE
            && u_dut.u_core.fe_start_latched == 1'b0
            && u_dut.u_core.fe_stop_latched == 1'b0
            && u_dut.u_core.fe_ctx_drain == '0) else begin
      $error("[TB] FAIL Test 3: reset collision did not return kernel to idle");
      $finish;
    end

    csr_rd(CSR_CONV_COUNT, rd_data);
    assert (rd_data == '0) else begin
      $error("[TB] FAIL Test 3: reset collision leaked a conversion count (0x%08h)", rd_data);
      $finish;
    end

    csr_wr(CSR_MAX_HITS,   32'h0000_000F);
    csr_wr(CSR_WDT_CTX,    32'h0000_FFFF);
    csr_wr(CSR_WDT_GLOBAL, 32'h0000_0000);
    #50_000;

    csr_wr(CSR_CTRL, 32'h0000_0001);
    #50_000;
    start_spad = 1'b1; #1000; start_spad = 1'b0;
    #10_000;
    stop_spad = 1'b1; #1000; stop_spad = 1'b0;

    fork
      collect_packet(clk_sys, narrow_valid, narrow_ready, narrow_data, pkt, wc);
      begin #5_000_000; $error("[TB] TIMEOUT Test 3 recovery packet"); $finish; end
    join_any
    disable fork;

    assert (wc >= 2 && is_header(pkt[0]) && is_eoc(pkt[wc-1])) else begin
      $error("[TB] FAIL Test 3: malformed recovery packet");
      $finish;
    end
    flags = header_flags(pkt[0]);
    assert (!flags.closed_by_watchdog) else begin
      $error("[TB] FAIL Test 3: watchdog flag leaked into recovery packet");
      $finish;
    end
    assert (header_hit_count(pkt[0]) > 0) else begin
      $error("[TB] FAIL Test 3: recovery packet has no hits");
      $finish;
    end
    csr_rd(CSR_CONV_COUNT, rd_data);
    assert (rd_data == 32'd1) else begin
      $error("[TB] FAIL Test 3: recovery conversion count incorrect (0x%08h)", rd_data);
      $finish;
    end

    $display("[TB] ===== TEST PASSED =====");
    $finish;
  end

  initial begin
    #100_000_000;
    $fatal(1, "[TB] GLOBAL TIMEOUT");
  end
endmodule

`default_nettype wire
