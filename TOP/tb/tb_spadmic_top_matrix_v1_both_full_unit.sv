`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_top_matrix_v1_both_full_unit;
  import spadmic_pkg::*;

  localparam int CLK_SYS_PERIOD   = 6250;
  localparam int CLK_40M_PERIOD   = 25000;
  localparam int I2C_HALF_PERIOD  = 200_000;
  localparam int I2C_SAMPLE_DELAY = I2C_HALF_PERIOD/2;

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
  logic cal_r_start;
  logic cal_r_stop;
  logic cal_y_start;
  logic cal_y_stop;
  logic cal_b_start;
  logic cal_b_stop;
  wire [15:0] ddr_data_l;
  wire [15:0] ddr_data_h;
  wire ddr_pair_valid;
  wire ddr_clk;
  int pass_count;
  int fail_count;
  int ddr_word_count;
  logic [15:0] ddr_words [0:255];

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
    .i2c_scl_i(i2c_scl),
    .i2c_sda_i(i2c_sda),
    .i2c_sda_oe_o(i2c_sda_oe),
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
    .cal_r_start_async_i(cal_r_start),
    .cal_r_stop_async_i(cal_r_stop),
    .cal_y_start_async_i(cal_y_start),
    .cal_y_stop_async_i(cal_y_stop),
    .cal_b_start_async_i(cal_b_start),
    .cal_b_stop_async_i(cal_b_stop),
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

  always_ff @(posedge clk_sys or negedge async_rst_n) begin
    if (!async_rst_n) begin
      ddr_word_count <= 0;
      for (int i = 0; i < 256; i++)
        ddr_words[i] <= '0;
    end else if (ddr_pair_valid) begin
      if (ddr_word_count < 255) begin
        ddr_words[ddr_word_count] <= ddr_data_l;
        ddr_words[ddr_word_count + 1] <= ddr_data_h;
        ddr_word_count <= ddr_word_count + 2;
      end
    end
  end

  function automatic int count_eoc_for_id(input logic [13:0] event_id);
    int count;
    count = 0;
    for (int i = 0; i < 256; i++) begin
      if (i < ddr_word_count && ddr_words[i] == {2'b11, event_id})
        count++;
    end
    return count;
  endfunction

  initial begin
    logic [31:0] rd;
    int wait_cycles;

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
    cal_r_start = 1'b0;
    cal_r_stop = 1'b0;
    cal_y_start = 1'b0;
    cal_y_stop = 1'b0;
    cal_b_start = 1'b0;
    cal_b_stop = 1'b0;

    repeat (8) @(posedge clk_sys);
    #1;
    check("reset drives matrix reset outputs inactive", Rz == '1 && Yz == '1 && Bz == '1);
    async_rst_n = 1'b1;
    repeat (12) @(posedge clk_sys);

    i2c_write_csr(SPADMIC_CSR_MATRIX_RESET_CTRL, 32'h0001_0003);
    i2c_write_csr(SPADMIC_CSR_MTOP_CTRL_REQUEST,
                  {24'h0, 1'b1, 3'b111, SPADMIC_MODE_BOTH, 1'b1});
    i2c_read_csr(SPADMIC_CSR_MTOP_CTRL_ACTIVE, rd);
    check("I2C commits BOTH active mode", rd[3:1] == SPADMIC_MODE_BOTH);

    wait_cycles = 0;
    while (!dut.pre_event_resources_ready && wait_cycles < 1000) begin
      wait_cycles++;
      @(posedge clk_sys);
    end
    check("BOTH pre-event resources become ready", dut.pre_event_resources_ready);

    R = 64'h0000_0000_0000_0008;
    Y = 64'h0000_0000_0000_0020;
    B = 64'h0000_0000_0000_0080;
    wait (Rz != {64{1'b1}});
    check("BOTH reset selects captured R/Y/B bits", !Rz[3] && !Yz[5] && !Bz[7]);
    repeat (4) @(posedge clk_sys);
    R = '0;
    Y = '0;
    B = '0;

    wait_cycles = 0;
    while (!dut.safe_idle && wait_cycles < 50_000) begin
      wait_cycles++;
      @(posedge clk_sys);
    end
    check("BOTH event returns safe idle", dut.safe_idle);
    i2c_read_csr(SPADMIC_CSR_MATRIX_EVENT_STATUS, rd);
    check("BOTH required/completed mask is all four sources", rd[7:4] == 4'b1111);
    check("BOTH emits at least one DDR16 pair", ddr_word_count != 0);
    check("BOTH bundle has four EOC words with shared event ID zero",
          count_eoc_for_id(14'h0000) == 4);
    i2c_read_csr(SPADMIC_CSR_TX_STATUS, rd);
    check("TX path drains after BOTH bundle", rd[0] && !rd[1]);

    if (fail_count != 0)
      $fatal(1, "tb_spadmic_top_matrix_v1_both_full_unit: %0d failures", fail_count);

    $display("tb_spadmic_top_matrix_v1_both_full_unit: %0d pass / %0d fail",
             pass_count, fail_count);
    $finish;
  end

  initial begin
    #(64'd3_000_000_000);
    $fatal(1, "tb_spadmic_top_matrix_v1_both_full_unit: TIMEOUT");
  end
endmodule

`default_nettype wire
