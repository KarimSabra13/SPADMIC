// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// =============================================================================
// Project : SPAD_MPTDC Verification Collateral
// File    : mptdc_vip_tb.sv
// Purpose : Top-level VIP harness tying interfaces, DUT, and test factory together.
// Author  : Karim Sabra
// Notes   : A module-resident BFM executes mailbox transactions while class-based
//           tests drive stimulus and scoreboard expectations.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module mptdc_vip_tb;
  import mptdc_pkg::*;
  import mptdc_vip_pkg::*;
  import mptdc_tb_pkg::*;

  logic clk_sys;
  initial clk_sys = 1'b0;
  always #(6250ps/2) clk_sys = ~clk_sys;

  mptdc_csr_if   csr_if  (clk_sys);
  mptdc_async_io_if async_if();
  mptdc_narrow_if narrow_if(clk_sys);

  logic                  tb_async_rst_n;
  logic                  tb_start_spad;
  logic                  tb_stop_spad;
  logic                  tb_cal_start;
  logic                  tb_cal_stop;
  logic                  tb_csr_valid;
  logic                  tb_csr_write;
  logic [CSR_ADDR_W-1:0] tb_csr_addr;
  logic [CSR_DATA_W-1:0] tb_csr_wdata;
  logic                  tb_csr_ready;
  logic                  tb_csr_rvalid;
  logic [CSR_DATA_W-1:0] tb_csr_rdata;
  logic                  tb_narrow_ready;
  logic                  tb_narrow_valid;
  logic [NARROW_W-1:0]   tb_narrow_data;
  logic                  mon_valid_q;
  logic                  mon_ready_q;
  logic [NARROW_W-1:0]   mon_data_q;

  // Bridge the interface state into plain DUT wires while leaving the VIP
  // classes and helper tasks bound to the interfaces themselves.
  always_comb begin
    tb_async_rst_n = async_if.async_rst_n;
    tb_start_spad  = async_if.start_spad;
    tb_stop_spad   = async_if.stop_spad;
    tb_cal_start   = async_if.cal_start;
    tb_cal_stop    = async_if.cal_stop;

    tb_csr_valid   = csr_if.csr_valid;
    tb_csr_write   = csr_if.csr_write;
    tb_csr_addr    = csr_if.csr_addr;
    tb_csr_wdata   = csr_if.csr_wdata;
    csr_if.csr_ready  = tb_csr_ready;
    csr_if.csr_rvalid = tb_csr_rvalid;
    csr_if.csr_rdata  = tb_csr_rdata;

    tb_narrow_ready     = narrow_if.narrow_ready;
    narrow_if.narrow_valid = tb_narrow_valid;
    narrow_if.narrow_data  = tb_narrow_data;
  end

  mptdc_top_asic u_dut (
    .clk_sys            (clk_sys),
    .async_rst_n        (tb_async_rst_n),
    .start_spad_async_i (tb_start_spad),
    .stop_spad_async_i  (tb_stop_spad),
    .cal_start_async_i  (tb_cal_start),
    .cal_stop_async_i   (tb_cal_stop),
    .csr_valid_i        (tb_csr_valid),
    .csr_write_i        (tb_csr_write),
    .csr_addr_i         (tb_csr_addr),
    .csr_wdata_i        (tb_csr_wdata),
    .csr_ready_o        (tb_csr_ready),
    .csr_rvalid_o       (tb_csr_rvalid),
    .csr_rdata_o        (tb_csr_rdata),
    .narrow_ready_i     (tb_narrow_ready),
    .narrow_valid_o     (tb_narrow_valid),
    .narrow_data_o      (tb_narrow_data)
  );

  initial begin
    async_if.async_rst_n = 1'b0;
    async_if.start_spad  = 1'b0;
    async_if.stop_spad   = 1'b0;
    async_if.cal_start   = 1'b0;
    async_if.cal_stop    = 1'b0;
    csr_if.csr_valid     = 1'b0;
    csr_if.csr_write     = 1'b0;
    csr_if.csr_addr      = '0;
    csr_if.csr_wdata     = '0;
    narrow_if.narrow_ready = 1'b1;
  end

  task automatic bfm_csr_write(input logic [CSR_ADDR_W-1:0] addr,
                               input logic [CSR_DATA_W-1:0] data);
    mptdc_tb_pkg::tb_csr_write(clk_sys, csr_if.csr_valid, csr_if.csr_write,
                               csr_if.csr_addr, csr_if.csr_wdata, addr, data);
  endtask

  // START rejection capture for the most recent injected conversion.
  // Sample 1ps after the async START edge so the frontend SR latch settles.
  logic bfm_last_start_rejected;
  initial bfm_last_start_rejected = 1'b0;

  /* verilator lint_off BLKSEQ */
  always @(posedge tb_start_spad or posedge tb_cal_start) begin
    #1;
    bfm_last_start_rejected = u_dut.u_core.u_frontend.start_rejected_o;
  end
  /* verilator lint_on BLKSEQ */

  always @(negedge clk_sys) begin
    mon_valid_q <= tb_narrow_valid;
    mon_ready_q <= tb_narrow_ready;
    mon_data_q  <= tb_narrow_data;
  end

  always @(posedge clk_sys) begin
    if ((g_mon_word_mb != null) && mon_valid_q && mon_ready_q)
      g_mon_word_mb.put(mon_data_q);
  end

  // Module-resident BFM consumes mailbox transactions so the class-based
  // environment can stay protocol-focused and avoid hierarchical pokes.
  initial begin : vip_module_bfm
    mptdc_base_txn  base;
    mptdc_reset_txn rst;
    mptdc_cfg_txn   cfg_txn;
    mptdc_conv_txn  conv;
    bit             bfm_prev_start_latched;
    bit             bfm_conv_accepted;

    wait(g_bfm_req_mb != null);
    forever begin
      g_bfm_req_mb.get(base);
      if (base == null)
        continue;

      case (base.kind)
        TXN_RESET: begin
          if (!$cast(rst, base))
            $fatal(1, "VIP BFM failed to cast reset txn");
          csr_if.reset_bus();
          async_if.reset_pulses();
          async_if.async_rst_n = 1'b0;
          #rst.low_time_ps;
          async_if.async_rst_n = 1'b1;
          #rst.settle_time_ps;
        end

        TXN_CFG: begin
          if (!$cast(cfg_txn, base))
            $fatal(1, "VIP BFM failed to cast cfg txn");
          bfm_csr_write(CSR_MODE,       cfg_txn.pack_mode_reg());
          bfm_csr_write(CSR_MAX_HITS,   {28'd0, cfg_txn.max_hits});
          bfm_csr_write(CSR_WDT_CTX,    {16'd0, cfg_txn.wdt_ctx_timeout});
          bfm_csr_write(CSR_WDT_GLOBAL, {16'd0, cfg_txn.wdt_global_timeout});
          #50_000;
        end

        TXN_CONV: begin
          if (!$cast(conv, base))
            $fatal(1, "VIP BFM failed to cast conv txn");
          bfm_csr_write(CSR_CTRL, 32'h0000_0001);
          #conv.arm_settle_ps;
          bfm_prev_start_latched = u_dut.u_core.u_frontend.start_latched_o;
          bfm_last_start_rejected = 1'b0;
          if (conv.start_only)
            async_if.inject_start_only(conv.source_sel, conv.pulse_width_ps);
          else
            async_if.inject_pair(conv.source_sel, conv.start_stop_delay_ps, conv.pulse_width_ps);
          bfm_conv_accepted = (!bfm_prev_start_latched) && (!bfm_last_start_rejected);
          g_bfm_ack_mb.put(bfm_conv_accepted);
          if (conv.idle_after_ps > 0)
            #conv.idle_after_ps;
        end

        default: begin
        end
      endcase
    end
  end

  // Factory-selected tests build transactions and scoreboard expectations;
  // plusargs keep smoke scripts free to swap scenarios without editing the TB.
  initial begin
    string           test_name;
    int unsigned     seed;
    int              jitter_sigma_ps;
    int              jitter_bound_ps;
    int              num_conv;
    mptdc_base_test  test;
    mptdc_env_cfg    cfg;

    if (!$value$plusargs("MPTDC_TEST=%s", test_name))
      test_name = "smoke_single_conv";
    if (!$value$plusargs("MPTDC_SEED=%d", seed))
      seed = 32'h1bad_f00d;
    if (!$value$plusargs("OSC_JITTER_SIGMA_PS=%d", jitter_sigma_ps))
      jitter_sigma_ps = 0;
    if (!$value$plusargs("OSC_JITTER_BOUND_PS=%d", jitter_bound_ps))
      jitter_bound_ps = 0;
    if (!$value$plusargs("MPTDC_NUM_CONV=%d", num_conv))
      num_conv = 0;

    $display("[VIP][TB] Starting test=%s seed=%0d jitter_sigma_ps=%0d jitter_bound_ps=%0d num_conv=%0d",
             test_name, seed, jitter_sigma_ps, jitter_bound_ps, num_conv);

    test = mptdc_test_factory::create(test_name);
    if (test == null)
      $fatal(1, "Unknown MPTDC test '%s'", test_name);

    cfg = new();
    cfg.test_name           = test_name;
    cfg.random_seed         = seed;
    cfg.osc_jitter_sigma_ps = jitter_sigma_ps;
    cfg.osc_jitter_bound_ps = jitter_bound_ps;
    cfg.num_conv            = num_conv;
`ifdef MPTDC_ENABLE_FUNC_COV
    cfg.enable_func_cov     = 1'b1;
`else
    cfg.enable_func_cov     = 1'b0;
`endif

    test.cfg = cfg;
    test.set_vifs(csr_if, async_if, narrow_if);
    test.run();
    $display("[VIP][TB] TEST COMPLETE: %s", test_name);
    $finish;
  end

  // Global timeout — scales with num_conv for stress tests
  // Budget: 1µs idle + ~0.5µs meas + ~0.4µs TX + BP stalls → 5µs/conv
  initial begin
    automatic int timeout_conv;
    automatic longint timeout_ps;
    if (!$value$plusargs("MPTDC_NUM_CONV=%d", timeout_conv))
      timeout_conv = 0;
    // Base 10ms + 5µs per conversion (covers random backpressure)
    timeout_ps = 64'd10_000_000_000 + (longint'(timeout_conv) * 64'd5_000_000);
    #(timeout_ps);
    $fatal(1, "VIP TB global timeout after %0d ps", timeout_ps);
  end
endmodule

`default_nettype wire
