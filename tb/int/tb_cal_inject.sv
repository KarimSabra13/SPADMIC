`timescale 1ns/1ps

module tb_cal_inject;
  import mptdc_pkg::*;
  import mptdc_tb_pkg::*;

  localparam real CLK_SYS_PERIOD = 6.25;

  logic clk_sys;
  initial clk_sys = 0;
  always #(CLK_SYS_PERIOD / 2.0) clk_sys = ~clk_sys;

  logic async_rst_n;
  initial async_rst_n = 0;
  logic cal_start;
  initial cal_start = 0;
  logic cal_stop;
  initial cal_stop = 0;
  logic                    csr_valid;
  initial csr_valid = 0;
  logic                    csr_wr;
  initial csr_wr = 0;
  logic [CSR_ADDR_W-1:0]  csr_addr;
  initial csr_addr = '0;
  logic [CSR_DATA_W-1:0]  csr_wdata;
  initial csr_wdata = '0;
  logic                    csr_ready;
  logic                    csr_rvalid;
  logic [CSR_DATA_W-1:0]  csr_rdata;
  logic [NARROW_W-1:0]    narrow_data;
  logic                    narrow_valid;
  logic                    narrow_ready;
  initial narrow_ready = 0;

  mptdc_top_asic u_dut (
    .clk_sys            (clk_sys),
    .async_rst_n        (async_rst_n),
    .start_spad_async_i (1'b0),
    .stop_spad_async_i  (1'b0),
    .cal_start_async_i  (cal_start),
    .cal_stop_async_i   (cal_stop),
    .csr_valid_i        (csr_valid),
    .csr_write_i        (csr_wr),
    .csr_addr_i         (csr_addr),
    .csr_wdata_i        (csr_wdata),
    .csr_ready_o        (csr_ready),
    .csr_rvalid_o       (csr_rvalid),
    .csr_rdata_o        (csr_rdata),
    .narrow_ready_i     (narrow_ready),
    .narrow_valid_o     (narrow_valid),
    .narrow_data_o      (narrow_data)
  );

  task automatic csr_wr_reg(input logic [CSR_ADDR_W-1:0] addr, input logic [CSR_DATA_W-1:0] data);
    tb_csr_write(clk_sys, csr_valid, csr_wr, csr_addr, csr_wdata, addr, data);
  endtask

  task automatic csr_rd_reg(input logic [CSR_ADDR_W-1:0] addr, output logic [CSR_DATA_W-1:0] data);
    tb_csr_read(clk_sys, csr_valid, csr_wr, csr_addr, csr_wdata, csr_rvalid, csr_rdata, addr, data);
  endtask

  task automatic wait_tdc_ready(input int max_cycles = 50000);
    logic [CSR_DATA_W-1:0] status;
    for (int i = 0; i < max_cycles; i++) begin
      csr_rd_reg(CSR_STATUS, status);
      if (status[0]) return;
      @(posedge clk_sys);
    end
    $error("[TB] TDC not ready after %0d cycles", max_cycles);
    $finish;
  endtask

  initial begin
    logic [NARROW_W-1:0] pkt [$];
    int wc, hit_count, pass_count, fail_count, expected_wc, conv_ok;
    tb_hit_features_t hf;

    fork begin #50_000_000; $error("[TB] GLOBAL TIMEOUT"); $finish; end join_none

    async_rst_n = 0; #100;
    async_rst_n = 1; #100;

    csr_wr_reg(CSR_MODE,     32'h0000_0002);   // CAL input
    csr_wr_reg(CSR_MAX_HITS, 32'h0000_000F);   // max_hits=15

    pass_count = 0;
    fail_count = 0;

    for (int d = 1; d <= 30; d++) begin
      pkt.delete();
      wc = 0;
      conv_ok = 0;
      narrow_ready = 0;

      wait_tdc_ready();
      csr_wr_reg(CSR_CTRL, 32'h0000_0001);
      #50;

      cal_start = 1; #1; cal_start = 0;
      #(d);
      cal_stop = 1; #1; cal_stop = 0;

      #800;
      narrow_ready = 1;

      fork
        begin collect_packet(clk_sys, narrow_valid, narrow_ready, narrow_data, pkt, wc); conv_ok = 1; end
        begin #200_000; end
      join_any
      disable fork;
      #500;

      if (!conv_ok) begin
        $display("[TB] delay=%0dns: SKIP (timeout)", d);
        fail_count++;
        async_rst_n = 0; narrow_ready = 0; #200;
        async_rst_n = 1; #200;
        csr_wr_reg(CSR_MODE, 32'h0000_0002);
        csr_wr_reg(CSR_MAX_HITS, 32'h0000_000F);
        continue;
      end

      if (wc < 2 || !is_header(pkt[0]) || !is_eoc(pkt[wc-1])) begin
        $display("[TB] delay=%0dns: FAIL structure (wc=%0d)", d, wc);
        fail_count++;
        continue;
      end

      hit_count = int'(header_hit_count(pkt[0]));
      expected_wc = 1 + hit_count * 3 + 1;
      if (wc != expected_wc || hit_count < 1) begin
        $display("[TB] delay=%0dns: FAIL wc=%0d exp=%0d hits=%0d", d, wc, expected_wc, hit_count);
        fail_count++;
        continue;
      end

      hf = parse_hit_features(pkt[1], pkt[2], pkt[3]);
      $display("[TB] delay=%0dns  nslow=%0d  nfast=%0d  hits=%0d  words=%0d  conv_id=%0d",
               d, hf.nslow, hf.nfast, hit_count, wc, eoc_conv_id(pkt[wc-1]));
      pass_count++;
    end

    $display("[TB]");
    $display("[TB] ===== CALIBRATION INJECT RESULTS =====");
    $display("[TB] Passed: %0d / 30  Failed: %0d / 30", pass_count, fail_count);
    if (pass_count >= 25)
      $display("[TB] ===== TEST PASSED =====");
    else begin
      $error("[TB] ===== TEST FAILED =====");
    end
    $finish;
  end

endmodule
