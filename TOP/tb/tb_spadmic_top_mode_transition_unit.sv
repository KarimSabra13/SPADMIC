`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_top_mode_transition_unit;
  import spadmic_pkg::*;

  localparam int CLK_SYS_PERIOD   = 6250;
  localparam int CLK_40M_PERIOD   = 25000;
  localparam int I2C_HALF_PERIOD  = 200_000;
  localparam int I2C_SAMPLE_DELAY = I2C_HALF_PERIOD/2;
  localparam logic [3:0] CMD_ERR_PATH_BUSY = 4'd4;

  logic clk_sys;
  logic clk_ref_40m;
  logic clk_cfg_40m;
  logic async_rst_n;
  logic i2c_scl_drv;
  logic i2c_sda_master_low;
  wire i2c_scl = i2c_scl_drv;
  wire i2c_sda;
  wire i2c_sda_oe;
  logic [63:0] R;
  logic [63:0] Y;
  logic [63:0] B;
  wire [63:0] Rz;
  wire [63:0] Yz;
  wire [63:0] Bz;
  wire [43:0] matrix_din;
  wire [43:0] matrix_cin;
  logic [43:0] matrix_dout;
  logic [43:0] matrix_cout;
  wire [15:0] ddr_data_l;
  wire [15:0] ddr_data_h;
  wire ddr_pair_valid;
  wire ddr_clk;
  int pass_count;
  int fail_count;

  assign i2c_sda = (i2c_sda_master_low | i2c_sda_oe) ? 1'b0 : 1'b1;

  initial clk_sys = 1'b0;
  always #(CLK_SYS_PERIOD/2) clk_sys = ~clk_sys;

  initial clk_ref_40m = 1'b0;
  always #(CLK_40M_PERIOD/2) clk_ref_40m = ~clk_ref_40m;

  initial clk_cfg_40m = 1'b0;
  always #(CLK_40M_PERIOD/2) clk_cfg_40m = ~clk_cfg_40m;

  spadmic_top_matrix_v1 dut (
    .clk_sys(clk_sys),
    .clk_ref_40m(clk_ref_40m),
    .clk_cfg_40m(clk_cfg_40m),
    .async_rst_n(async_rst_n),
    .i2c_rst_i(1'b0),
    .i2c_scl_i(i2c_scl),
    .i2c_sda_i(i2c_sda),
    .i2c_sda_oe_o(i2c_sda_oe),
    .pll_lock_i(1'b1),
    .R_i(R),
    .Y_i(Y),
    .B_i(B),
    .Rz_o(Rz),
    .Yz_o(Yz),
    .Bz_o(Bz),
    .matrix_din_o(matrix_din),
    .matrix_cin_o(matrix_cin),
    .matrix_dout_i(matrix_dout),
    .matrix_cout_i(matrix_cout),
    .cal_r_start_async_i(1'b0),
    .cal_r_stop_async_i(1'b0),
    .cal_y_start_async_i(1'b0),
    .cal_y_stop_async_i(1'b0),
    .cal_b_start_async_i(1'b0),
    .cal_b_stop_async_i(1'b0),
    .ddr_data_l_o(ddr_data_l),
    .ddr_data_h_o(ddr_data_h),
    .ddr_pair_valid_o(ddr_pair_valid),
    .ddr_clk_o(ddr_clk)
  );

  `include "TOP/tb/spadmic_top_matrix_v1_i2c_tasks.svh"

  task automatic check(input string label, input logic cond);
    if (cond) begin
      $display("[PASS] %s", label);
      pass_count++;
    end else begin
      $display("[FAIL] %s", label);
      fail_count++;
    end
  endtask

  task automatic wait_safe_idle(input string label);
    int guard;
    begin
      guard = 0;
      while (!dut.safe_idle && guard < 50_000) begin
        guard++;
        @(posedge clk_sys);
      end
      check(label, dut.safe_idle);
    end
  endtask

  initial begin
    logic [31:0] rd;

    pass_count = 0;
    fail_count = 0;
    async_rst_n = 1'b0;
    i2c_scl_drv = 1'b1;
    i2c_sda_master_low = 1'b0;
    R = '0;
    Y = '0;
    B = '0;
    matrix_dout = '0;
    matrix_cout = '0;

    repeat (8) @(posedge clk_sys);
    async_rst_n = 1'b1;
    repeat (12) @(posedge clk_sys);

    i2c_write_csr(SPADMIC_CSR_MATRIX_RESET_CTRL, 32'h0000_4000);
    i2c_write_csr(SPADMIC_CSR_MTOP_CTRL_REQUEST,
                  {24'h0, 1'b1, 3'b111, SPADMIC_MODE_POSITION_ONLY, 1'b1});
    i2c_read_csr(SPADMIC_CSR_MTOP_CTRL_ACTIVE, rd);
    check("position-only mode write accepted at safe idle",
          rd[3:1] == SPADMIC_MODE_POSITION_ONLY);

    R[0] = 1'b1;
    Y[1] = 1'b1;
    B[2] = 1'b1;
    wait (Rz != {64{1'b1}});
    check("event makes path non-idle", !dut.safe_idle);

    i2c_write_csr(SPADMIC_CSR_MTOP_CTRL_REQUEST,
                  {24'h0, 1'b1, 3'b111, SPADMIC_MODE_TDC_ONLY, 1'b1});
    i2c_read_csr(SPADMIC_CSR_MTOP_CTRL_ACTIVE, rd);
    check("busy mode write does not change active mode",
          rd[3:1] == SPADMIC_MODE_POSITION_ONLY);
    i2c_read_csr(spadmic_csr_map_pkg::CSR_ACCESS_LAST_INFO, rd);
    check("busy mode write records an unsafe GLOBAL_CTRL access",
          rd[15:0] == spadmic_csr_map_pkg::CSR_GLOBAL_CTRL &&
          rd[23:16] == spadmic_csr_map_pkg::CSR_CAUSE_UNSAFE_WRITE && rd[24]);

    R = '0;
    Y = '0;
    B = '0;
    wait_safe_idle("event drains back to safe idle");
    i2c_write_csr(SPADMIC_CSR_MTOP_CTRL_REQUEST,
                  {24'h0, 1'b1, 3'b111, SPADMIC_MODE_TDC_ONLY, 1'b1});
    i2c_read_csr(SPADMIC_CSR_MTOP_CTRL_ACTIVE, rd);
    check("same mode write accepted after safe idle",
          rd[3:1] == SPADMIC_MODE_TDC_ONLY);

    if (fail_count != 0)
      $fatal(1, "tb_spadmic_top_mode_transition_unit: %0d failures", fail_count);

    $display("tb_spadmic_top_mode_transition_unit: %0d pass / %0d fail",
             pass_count, fail_count);
    $finish;
  end

  initial begin
    #(64'd3_000_000_000);
    $fatal(1, "tb_spadmic_top_mode_transition_unit: TIMEOUT");
  end
endmodule

`default_nettype wire
