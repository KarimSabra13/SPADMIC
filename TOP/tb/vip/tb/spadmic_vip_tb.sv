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

  initial begin clk_sys = 1'b0;     forever #(CLK_PERIOD/2)  clk_sys = ~clk_sys;     end
  initial begin clk_ref_40m = 1'b0; forever #(REF_PERIOD/2)  clk_ref_40m = ~clk_ref_40m; end

  // ── DUT output wires ──────────────────────────────────────────
  wire        i2c_sda_oe;
  wire        ddr_clk;
  wire        ddr_pair_valid;
  wire [SPADMIC_DDR16_PHY_W-1:0] ddr_data_l;
  wire [SPADMIC_DDR16_PHY_W-1:0] ddr_data_h;
  wire        spad_matrix_rst;
  wire [SPADMIC_LINE_W-1:0] matrix_r;
  wire [SPADMIC_LINE_W-1:0] matrix_y;
  wire [SPADMIC_LINE_W-1:0] matrix_b;
  wire [SPADMIC_LINE_W-1:0] matrix_rz;
  wire [SPADMIC_LINE_W-1:0] matrix_yz;
  wire [SPADMIC_LINE_W-1:0] matrix_bz;
  wire [SPADMIC_MATRIX_COLUMN_COUNT-1:0] matrix_din;
  wire [SPADMIC_MATRIX_COLUMN_COUNT-1:0] matrix_cin;
  wire [7:0] pll_fint_sel;
  wire [4:0] pll_ro_sw;
  wire pll_sel_pulse_pfd;
  wire pll_enable_div;
  wire pll_sel_40m;
  wire clk_160m_ext_select;
  wire [3:0] slvs_s_drv;
  wire slvs_en_vref_ext;
  wire slvs_en_drv;
  wire slvs_vref_adj_b;
  wire slvs_en_vref_400mv;
  wire slvs_en_ref_drv_b;
  wire [3:0] rx_s_rx;
  wire rx_en_rx;
  wire rx_en_term;

  // ── VIP Interfaces ────────────────────────────────────────────
  spadmic_reset_if          reset_if (.clk_sys(clk_sys));
  spadmic_i2c_if            i2c_if   ();
  spadmic_csr_req_if        csr_if   (.clk_sys(clk_sys), .rst_n(reset_if.rst_n));
  spadmic_async_event_if    x_ev_if  ();
  spadmic_async_event_if    y_ev_if  ();
  spadmic_async_event_if    z_ev_if  ();
  spadmic_position_line_if  pos_if   ();
  spadmic_narrow_tx_if      tx_if    (.clk_sys(clk_sys), .rst_n(reset_if.rst_n));
  spadmic_spad_reset_if     spad_rst_if (.clk_sys(clk_sys), .rst_n(reset_if.rst_n));

  // ── DUT Instantiation ─────────────────────────────────────────
  assign matrix_r = pos_if.x_lines | {{(SPADMIC_LINE_W-1){1'b0}}, x_ev_if.spad_event_async};
  assign matrix_y = pos_if.y_lines | {{(SPADMIC_LINE_W-1){1'b0}}, y_ev_if.spad_event_async};
  assign matrix_b = pos_if.z_lines | {{(SPADMIC_LINE_W-1){1'b0}}, z_ev_if.spad_event_async};

  spadmic_top_matrix_v1 u_dut (
    .clk_sys              (clk_sys),
    .clk_ref_40m          (clk_ref_40m),
    .clk_cfg_40m          (clk_ref_40m),
    .async_rst_n          (reset_if.rst_n),

    // I2C
    .i2c_rst_i            (1'b0),
    .i2c_scl_i            (i2c_if.scl),
    .i2c_sda_i            (i2c_if.sda),
    .i2c_sda_oe_o         (i2c_sda_oe),

    .pll_lock_i           (1'b1),
    .pll_fint_sel_o       (pll_fint_sel),
    .pll_ro_sw_o          (pll_ro_sw),
    .pll_sel_pulse_pfd_o  (pll_sel_pulse_pfd),
    .pll_enable_div_o     (pll_enable_div),
    .pll_sel_40m_o        (pll_sel_40m),
    .clk_160m_ext_select_o(clk_160m_ext_select),
    .slvs_s_drv_o         (slvs_s_drv),
    .slvs_en_vref_ext_o   (slvs_en_vref_ext),
    .slvs_en_drv_o        (slvs_en_drv),
    .slvs_vref_adj_b_o    (slvs_vref_adj_b),
    .slvs_en_vref_400mv_o (slvs_en_vref_400mv),
    .slvs_en_ref_drv_b_o  (slvs_en_ref_drv_b),
    .rx_s_rx_o            (rx_s_rx),
    .rx_en_rx_o           (rx_en_rx),
    .rx_en_term_o         (rx_en_term),

    .R_i                  (matrix_r),
    .Y_i                  (matrix_y),
    .B_i                  (matrix_b),
    .Rz_o                 (matrix_rz),
    .Yz_o                 (matrix_yz),
    .Bz_o                 (matrix_bz),
    .matrix_din_o         (matrix_din),
    .matrix_cin_o         (matrix_cin),
    .matrix_dout_i        ('0),
    .matrix_cout_i        ('0),

    .cal_r_start_async_i  (x_ev_if.cal_start_async),
    .cal_r_stop_async_i   (x_ev_if.cal_stop_async),
    .cal_y_start_async_i  (y_ev_if.cal_start_async),
    .cal_y_stop_async_i   (y_ev_if.cal_stop_async),
    .cal_b_start_async_i  (z_ev_if.cal_start_async),
    .cal_b_stop_async_i   (z_ev_if.cal_stop_async),

    .ddr_data_l_o         (ddr_data_l),
    .ddr_data_h_o         (ddr_data_h),
    .ddr_pair_valid_o     (ddr_pair_valid),
    .ddr_clk_o            (ddr_clk)
  );

  assign spad_matrix_rst = ~((&matrix_rz) & (&matrix_yz) & (&matrix_bz));

  // ── Wire connections ──────────────────────────────────────────
  assign i2c_if.clk_sys = clk_sys;
  assign i2c_if.rst_n   = reset_if.rst_n;
  assign i2c_if.sda_oe = i2c_sda_oe;
  assign tx_if.ddr_clk     = ddr_clk;
  assign tx_if.pair_valid  = ddr_pair_valid;
  assign tx_if.pair_padded = u_dut.ddr_padded;
  assign tx_if.data_l      = ddr_data_l;
  assign tx_if.data_h      = ddr_data_h;
  assign spad_rst_if.spad_matrix_rst = spad_matrix_rst;
  assign spad_rst_if.expected_width_cycles = u_dut.reset_width;

  initial begin
    i2c_if.idle_bus();
  end

  // ── Direct CSR BFM Bridge ────────────────────────────────────
  // Direct-CSR tests bypass I2C with a hierarchical force. I2C tests must leave
  // the DUT bridge in control, otherwise pin-level reads can never retire.
  task automatic enable_direct_csr_override();
    force u_dut.csr_req_valid = csr_if.req_valid;
    force u_dut.csr_req_write = csr_if.req_write;
    force u_dut.csr_req_addr  = csr_if.req_addr;
    force u_dut.csr_req_wdata = csr_if.req_wdata;
    force u_dut.csr_rsp_ready = csr_if.rsp_ready;
  endtask

  task automatic enable_i2c_csr_monitor_mirror();
    force csr_if.req_valid = u_dut.csr_req_valid;
    force csr_if.req_write = u_dut.csr_req_write;
    force csr_if.req_addr  = u_dut.csr_req_addr;
    force csr_if.req_wdata = u_dut.csr_req_wdata;
    force csr_if.rsp_ready = u_dut.csr_rsp_ready;
  endtask

  // Reflect DUT CSR bus responses back to the VIP interface
  assign csr_if.req_ready = u_dut.csr_req_ready;
  assign csr_if.rsp_valid = u_dut.csr_rsp_valid;
  assign csr_if.rsp_rdata = u_dut.csr_rsp_rdata;
  assign csr_if.rsp_err   = u_dut.csr_rsp_err;

  // ── Reset Sequence ────────────────────────────────────────────
  initial begin
    reset_if.apply_startup_reset(20);
    $display("[HARNESS] Reset released at %0t", $time);
  end

  // ── Test Entry Point ──────────────────────────────────────────
  initial begin
    string test_name;
    spadmic_base_test test;

    // Wait for reset release
    @(posedge reset_if.rst_n);
    repeat (10) @(posedge clk_sys);

    // Get test name from plusargs
    if (!$value$plusargs("SPADMIC_TEST=%s", test_name))
      test_name = "smoke_tdc";

    $display("[HARNESS] Running test: %s", test_name);

    // Create test and pre-resolve its driver mode so the harness does not
    // permanently override the real I2C CSR path during I2C-mode tests.
    test = spadmic_test_factory::create_test(test_name);
    test.configure();
    test.cfg.parse_plusargs();
    if (test.cfg.drv_mode == DRV_MODE_DIRECT_CSR) begin
      $display("[HARNESS] Direct CSR override enabled");
      enable_direct_csr_override();
    end else begin
      $display("[HARNESS] Direct CSR override disabled; mirroring DUT I2C CSR bus");
      enable_i2c_csr_monitor_mirror();
    end

    test.run_test(reset_if, csr_if, i2c_if, x_ev_if, y_ev_if, z_ev_if, pos_if, tx_if, spad_rst_if);

    // Finish
    repeat (100) @(posedge clk_sys);
    $finish;
  end

  // ── Timeout Watchdog ──────────────────────────────────────────
  initial begin
    #(64'd1000 * 64'd100_000_000);  // 100ms absolute timeout
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
