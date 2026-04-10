// =============================================================================
// SPADMIC VIP — Top-Level Testbench Harness
// Instantiates DUT + interfaces + BFM bridges + test entry point.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_vip_tb;
  import mptdc_pkg::*;
  import spadmic_pkg::*;
  import spadmic_vip_pkg::*;

  // ── Clock and Reset ───────────────────────────────────────────
  localparam int CLK_PERIOD   = 6250;     // 160 MHz
  localparam int REF_PERIOD   = 25000;    // 40 MHz

  logic clk_sys, clk_ref_40m;
  logic async_rst_n;

  initial begin clk_sys = 1'b0;     forever #(CLK_PERIOD/2)  clk_sys = ~clk_sys;     end
  initial begin clk_ref_40m = 1'b0; forever #(REF_PERIOD/2)  clk_ref_40m = ~clk_ref_40m; end

  // ── DUT output wires ──────────────────────────────────────────
  wire        i2c_sda_oe;
  wire        chip_tx_valid;
  wire [NARROW_W-1:0] chip_tx_data;
  wire [2:0]  tdc_stop_armed;
  wire        tdc_shared_busy;
  wire        position_busy;

  // ── VIP Interfaces ────────────────────────────────────────────
  spadmic_i2c_if            i2c_if   (.clk_sys(clk_sys), .rst_n(async_rst_n));
  spadmic_csr_req_if        csr_if   (.clk_sys(clk_sys), .rst_n(async_rst_n));
  spadmic_async_event_if    x_ev_if  ();
  spadmic_async_event_if    y_ev_if  ();
  spadmic_async_event_if    z_ev_if  ();
  spadmic_position_line_if  pos_if   ();
  spadmic_narrow_tx_if      tx_if    (.clk_sys(clk_sys), .rst_n(async_rst_n));

  // ── DUT Instantiation ─────────────────────────────────────────
  spadmic_top_v1 u_dut (
    .clk_sys              (clk_sys),
    .clk_ref_40m          (clk_ref_40m),
    .async_rst_n          (async_rst_n),

    // I2C
    .i2c_scl_i            (i2c_if.scl),
    .i2c_sda_i            (i2c_if.sda),
    .i2c_sda_oe_o         (i2c_sda_oe),

    // TDC async events (per axis)
    .spad_x_event_async_i (x_ev_if.spad_event_async),
    .spad_y_event_async_i (y_ev_if.spad_event_async),
    .spad_z_event_async_i (z_ev_if.spad_event_async),
    .cal_x_start_async_i  (x_ev_if.cal_start_async),
    .cal_x_stop_async_i   (x_ev_if.cal_stop_async),
    .cal_y_start_async_i  (y_ev_if.cal_start_async),
    .cal_y_stop_async_i   (y_ev_if.cal_stop_async),
    .cal_z_start_async_i  (z_ev_if.cal_start_async),
    .cal_z_stop_async_i   (z_ev_if.cal_stop_async),

    // Position lines
    .x_lines_i            (pos_if.x_lines),
    .y_lines_i            (pos_if.y_lines),
    .z_lines_i            (pos_if.z_lines),

    // Chip TX output
    .chip_tx_ready_i      (tx_if.ready),
    .chip_tx_valid_o      (chip_tx_valid),
    .chip_tx_data_o       (chip_tx_data),

    // Debug / status
    .tdc_stop_armed_o     (tdc_stop_armed),
    .tdc_shared_busy_o    (tdc_shared_busy),
    .position_busy_o      (position_busy)
  );

  // ── Wire connections ──────────────────────────────────────────
  assign i2c_if.sda_oe = i2c_sda_oe;
  assign tx_if.valid    = chip_tx_valid;
  assign tx_if.data     = chip_tx_data;

  // ── Direct CSR BFM Bridge ────────────────────────────────────
  // For direct CSR mode, override the DUT's internal CSR decoder inputs
  // via force (continuous force tracks RHS expression) to bypass I2C.
  initial begin
    force u_dut.csr_req_valid = csr_if.req_valid;
    force u_dut.csr_req_write = csr_if.req_write;
    force u_dut.csr_req_addr  = csr_if.req_addr;
    force u_dut.csr_req_wdata = csr_if.req_wdata;
    force u_dut.csr_rsp_ready = csr_if.rsp_ready;
  end

  // Reflect DUT CSR bus responses back to the VIP interface
  assign csr_if.req_ready = u_dut.csr_req_ready;
  assign csr_if.rsp_valid = u_dut.csr_rsp_valid;
  assign csr_if.rsp_rdata = u_dut.csr_rsp_rdata;
  assign csr_if.rsp_err   = u_dut.csr_rsp_err;

  // ── Reset Sequence ────────────────────────────────────────────
  initial begin
    async_rst_n = 1'b0;
    repeat (20) @(posedge clk_sys);
    async_rst_n = 1'b1;
    $display("[HARNESS] Reset released at %0t", $time);
  end

  // ── Test Entry Point ──────────────────────────────────────────
  initial begin
    string test_name;
    spadmic_base_test test;

    // Wait for reset release
    @(posedge async_rst_n);
    repeat (10) @(posedge clk_sys);

    // Get test name from plusargs
    if (!$value$plusargs("SPADMIC_TEST=%s", test_name))
      test_name = "smoke_tdc";

    $display("[HARNESS] Running test: %s", test_name);

    // Create and run test
    test = spadmic_test_factory::create_test(test_name);
    test.run_test(csr_if, i2c_if, x_ev_if, y_ev_if, z_ev_if, pos_if, tx_if);

    // Finish
    repeat (100) @(posedge clk_sys);
    $finish;
  end

  // ── Timeout Watchdog ──────────────────────────────────────────
  initial begin
    #(100_000_000 * 1000);  // 100ms absolute timeout
    $display("[HARNESS] GLOBAL TIMEOUT — aborting");
    $finish;
  end

  // ── Waveform Dump (for debug) ─────────────────────────────────
  initial begin
    if ($test$plusargs("DUMP_VCD")) begin
      $dumpfile("spadmic_vip.vcd");
      $dumpvars(0, spadmic_vip_tb);
    end
  end

endmodule

`default_nettype wire
