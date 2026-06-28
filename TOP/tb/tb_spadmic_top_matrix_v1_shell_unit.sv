`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_top_matrix_v1_shell_unit;
  import spadmic_pkg::*;

  localparam int CLK_SYS_PERIOD    = 6250;
  localparam int CLK_CFG_PERIOD    = 25000;
  localparam int I2C_HALF_PERIOD   = 200_000;
  localparam int I2C_SAMPLE_DELAY  = I2C_HALF_PERIOD/2;
  localparam logic [2:0] OP_WRITE_COLUMN_64 = 3'd1;

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
  int ddr_pair_count;

  assign i2c_sda = (i2c_sda_master_low | i2c_sda_oe) ? 1'b0 : 1'b1;

  initial clk_sys = 1'b0;
  always #(CLK_SYS_PERIOD/2) clk_sys = ~clk_sys;

  initial clk_ref_40m = 1'b0;
  always #(CLK_CFG_PERIOD/2) clk_ref_40m = ~clk_ref_40m;

  initial clk_cfg_40m = 1'b0;
  always #(CLK_CFG_PERIOD/2) clk_cfg_40m = ~clk_cfg_40m;

  genvar matrix_col;
  generate
    for (matrix_col = 0; matrix_col < 44; matrix_col++) begin : g_matrix_cfg_return_model
      always @(posedge matrix_cin[matrix_col]) begin
        logic sample_bit;
        sample_bit = matrix_din[matrix_col];
        #(CLK_CFG_PERIOD/5);
        matrix_dout[matrix_col] <= sample_bit;
        matrix_cout[matrix_col] <= 1'b1;
        #(CLK_CFG_PERIOD/5);
        matrix_cout[matrix_col] <= 1'b0;
      end
    end
  endgenerate

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

  task automatic check(input string label, input logic cond);
    if (cond) begin
      $display("[PASS] %s", label);
      pass_count++;
    end else begin
      $display("[FAIL] %s", label);
      fail_count++;
    end
  endtask

  task automatic i2c_start;
    begin
      i2c_sda_master_low = 1'b0;
      i2c_scl_drv        = 1'b1;
      #(I2C_HALF_PERIOD);
      i2c_sda_master_low = 1'b1;
      #(I2C_HALF_PERIOD);
      i2c_scl_drv        = 1'b0;
      #(I2C_HALF_PERIOD);
    end
  endtask

  task automatic i2c_restart;
    begin
      i2c_sda_master_low = 1'b0;
      #(I2C_HALF_PERIOD);
      i2c_scl_drv        = 1'b1;
      #(I2C_HALF_PERIOD);
      i2c_sda_master_low = 1'b1;
      #(I2C_HALF_PERIOD);
      i2c_scl_drv        = 1'b0;
      #(I2C_HALF_PERIOD);
    end
  endtask

  task automatic i2c_stop;
    begin
      i2c_scl_drv        = 1'b0;
      i2c_sda_master_low = 1'b1;
      #(I2C_HALF_PERIOD);
      i2c_scl_drv        = 1'b1;
      #(I2C_HALF_PERIOD);
      i2c_sda_master_low = 1'b0;
      #(I2C_HALF_PERIOD);
    end
  endtask

  task automatic i2c_write_bit(input logic bit_value);
    begin
      i2c_scl_drv        = 1'b0;
      i2c_sda_master_low = ~bit_value;
      #(I2C_HALF_PERIOD);
      i2c_scl_drv        = 1'b1;
      #(I2C_HALF_PERIOD);
      i2c_scl_drv        = 1'b0;
      #(I2C_HALF_PERIOD);
    end
  endtask

  task automatic i2c_read_bit(output logic bit_value);
    begin
      i2c_scl_drv        = 1'b0;
      i2c_sda_master_low = 1'b0;
      #(I2C_HALF_PERIOD);
      i2c_scl_drv        = 1'b1;
      #(I2C_SAMPLE_DELAY);
      bit_value = i2c_sda;
      #(I2C_HALF_PERIOD-I2C_SAMPLE_DELAY);
      i2c_scl_drv        = 1'b0;
      #(I2C_HALF_PERIOD);
    end
  endtask

  task automatic i2c_write_byte(
    input logic [7:0] byte_value,
    output logic ack_ok
  );
    logic ack_bit;
    begin
      for (int bit_idx = 7; bit_idx >= 0; bit_idx--)
        i2c_write_bit(byte_value[bit_idx]);
      i2c_read_bit(ack_bit);
      ack_ok = (ack_bit == 1'b0);
    end
  endtask

  task automatic i2c_read_byte(
    output logic [7:0] byte_value,
    input logic send_ack
  );
    logic bit_value;
    begin
      byte_value = '0;
      for (int bit_idx = 7; bit_idx >= 0; bit_idx--) begin
        i2c_read_bit(bit_value);
        byte_value[bit_idx] = bit_value;
      end

      i2c_scl_drv        = 1'b0;
      i2c_sda_master_low = send_ack;
      #(I2C_HALF_PERIOD);
      i2c_scl_drv        = 1'b1;
      #(I2C_HALF_PERIOD);
      i2c_scl_drv        = 1'b0;
      i2c_sda_master_low = 1'b0;
      #(I2C_HALF_PERIOD);
    end
  endtask

  task automatic i2c_expect_ack(input logic ack_ok, input string label);
    if (!ack_ok)
      $fatal(1, "Missing I2C ACK during %s", label);
  endtask

  task automatic i2c_write_csr(
    input logic [15:0] addr,
    input logic [31:0] data
  );
    logic ack_ok;
    begin
      i2c_start();
      i2c_write_byte({SPADMIC_I2C_ADDR, 1'b0}, ack_ok);
      i2c_expect_ack(ack_ok, "device-address write");
      i2c_write_byte(addr[15:8], ack_ok);
      i2c_expect_ack(ack_ok, "pointer high");
      i2c_write_byte(addr[7:0], ack_ok);
      i2c_expect_ack(ack_ok, "pointer low");
      i2c_write_byte(data[31:24], ack_ok);
      i2c_expect_ack(ack_ok, "data byte 3");
      i2c_write_byte(data[23:16], ack_ok);
      i2c_expect_ack(ack_ok, "data byte 2");
      i2c_write_byte(data[15:8], ack_ok);
      i2c_expect_ack(ack_ok, "data byte 1");
      i2c_write_byte(data[7:0], ack_ok);
      i2c_expect_ack(ack_ok, "data byte 0");
      i2c_stop();
      repeat (12) @(posedge clk_sys);
    end
  endtask

  task automatic i2c_read_csr(
    input logic [15:0] addr,
    output logic [31:0] data
  );
    logic ack_ok;
    logic [7:0] b3;
    logic [7:0] b2;
    logic [7:0] b1;
    logic [7:0] b0;
    begin
      i2c_start();
      i2c_write_byte({SPADMIC_I2C_ADDR, 1'b0}, ack_ok);
      i2c_expect_ack(ack_ok, "device-address pointer");
      i2c_write_byte(addr[15:8], ack_ok);
      i2c_expect_ack(ack_ok, "pointer high");
      i2c_write_byte(addr[7:0], ack_ok);
      i2c_expect_ack(ack_ok, "pointer low");
      i2c_restart();
      i2c_write_byte({SPADMIC_I2C_ADDR, 1'b1}, ack_ok);
      i2c_expect_ack(ack_ok, "device-address read");
      repeat (4) @(posedge clk_sys);
      i2c_read_byte(b3, 1'b1);
      i2c_read_byte(b2, 1'b1);
      i2c_read_byte(b1, 1'b1);
      i2c_read_byte(b0, 1'b0);
      data = {b3, b2, b1, b0};
      i2c_stop();
      repeat (6) @(posedge clk_sys);
    end
  endtask

  always_ff @(posedge clk_sys or negedge async_rst_n) begin
    if (!async_rst_n) begin
      ddr_pair_count <= 0;
    end else if (ddr_pair_valid) begin
      ddr_pair_count <= ddr_pair_count + 1;
    end
  end

  initial begin
    logic [31:0] rd;
    int start_pair_count;
    int wait_cycles;

    pass_count = 0;
    fail_count = 0;
    async_rst_n = 1'b0;
    i2c_scl_drv = 1'b1;
    i2c_sda_master_low = 1'b0;
    R = '0;
    Y = '0;
    B = '0;
    cal_r_start = 1'b0;
    cal_r_stop = 1'b0;
    cal_y_start = 1'b0;
    cal_y_stop = 1'b0;
    cal_b_start = 1'b0;
    cal_b_stop = 1'b0;
    matrix_dout = '0;
    matrix_cout = '0;

    repeat (8) @(posedge clk_sys);
    #1;
    check("async reset drives reset-select buses inactive", Rz == '1 && Yz == '1 && Bz == '1);
    check("async reset drives matrix config idle", matrix_din == '0 && matrix_cin == '0);
    check("async reset drives DDR outputs idle", ddr_data_l == '0 && ddr_data_h == '0 && !ddr_pair_valid);

    async_rst_n = 1'b1;
    repeat (12) @(posedge clk_sys);
    #1;
    check("reset release keeps reset-select buses inactive", Rz == '1 && Yz == '1 && Bz == '1);
    check("DDR clock follows clk_sys boundary", ddr_clk == clk_sys);

    i2c_read_csr(SPADMIC_CSR_GLOBAL_ID, rd);
    check("I2C reads matrix-top ID", rd == 32'h5350_4D54);

    i2c_write_csr(SPADMIC_CSR_SHARED_TDC_MAX_HITS, 32'h0000_000A);
    i2c_read_csr(SPADMIC_CSR_SHARED_TDC_MAX_HITS, rd);
    check("I2C writes shared TDC max_hits", rd[3:0] == 4'd10 && dut.shared_tdc_max_hits == 4'd10);
    i2c_write_csr(SPADMIC_CSR_SHARED_TDC_RO_SLOW, 32'h0000_0012);
    i2c_write_csr(SPADMIC_CSR_SHARED_TDC_RO_FAST, 32'h0000_0034);
    i2c_read_csr(SPADMIC_CSR_SHARED_TDC_RO_SLOW, rd);
    check("I2C writes shared slow RO code", rd[7:0] == 8'h12 && dut.shared_tdc_ro_slow_code == 8'h12);
    i2c_read_csr(SPADMIC_CSR_SHARED_TDC_RO_FAST, rd);
    check("I2C writes shared fast RO code", rd[7:0] == 8'h34 && dut.shared_tdc_ro_fast_code == 8'h34);

    i2c_write_csr(SPADMIC_CSR_CALIB_AXIS_MASK, 32'h0000_0001);
    i2c_write_csr(SPADMIC_CSR_MTOP_CTRL_REQUEST,
                  {24'h0, 1'b1, 3'b111, SPADMIC_MODE_CALIBRATION, 1'b1});
    i2c_read_csr(SPADMIC_CSR_MTOP_CTRL_ACTIVE, rd);
    check("I2C commits calibration mode", rd[3:1] == SPADMIC_MODE_CALIBRATION);
    check("calibration active axis mask uses CSR selection", rd[6:4] == 3'b001);
    cal_y_start = 1'b1;
    #1;
    check("unselected calibration Y start is ignored", !dut.cal_activity);
    cal_y_start = 1'b0;
    cal_b_start = 1'b1;
    #1;
    check("unselected calibration B start is ignored", !dut.cal_activity);
    cal_b_start = 1'b0;
    cal_r_start = 1'b1;
    #1;
    check("selected calibration R start is accepted", dut.cal_activity);
    cal_r_start = 1'b0;
    async_rst_n = 1'b0;
    repeat (8) @(posedge clk_sys);
    #1;
    check("reset after calibration gate check restores idle outputs",
          Rz == '1 && Yz == '1 && Bz == '1 && matrix_din == '0 && matrix_cin == '0);
    async_rst_n = 1'b1;
    repeat (12) @(posedge clk_sys);

    i2c_write_csr(SPADMIC_CSR_MATRIX_RESET_CTRL, 32'h0001_0003);
    i2c_read_csr(SPADMIC_CSR_MATRIX_RESET_CTRL, rd);
    check("I2C writes reset width and auto reset", rd[16] && rd[15:0] == 16'd3);

    i2c_write_csr(SPADMIC_CSR_MTOP_CTRL_REQUEST,
                  {24'h0, 1'b1, 3'b111, SPADMIC_MODE_POSITION_ONLY, 1'b1});
    i2c_read_csr(SPADMIC_CSR_MTOP_CTRL_ACTIVE, rd);
    check("I2C commits position-only active mode", rd[3:1] == SPADMIC_MODE_POSITION_ONLY);
    check("I2C commits global enable", rd[0]);

    start_pair_count = ddr_pair_count;
    R = 64'h0000_0000_0000_0001;
    Y = 64'h0000_0000_0000_0002;
    B = 64'h0000_0000_0000_0004;
    wait (Rz != {64{1'b1}});
    check("position event asserts selective reset", !Rz[0] && !Yz[1] && !Bz[2]);
    repeat (2) @(posedge clk_sys);
    R = '0;
    Y = '0;
    B = '0;
    wait ((ddr_pair_count - start_pair_count) >= 7);
    repeat (10) @(posedge clk_sys);
    i2c_read_csr(SPADMIC_CSR_TX_STATUS, rd);
    check("position-only event drains DDR16 pairer", rd[0] && !rd[1]);
    i2c_read_csr(SPADMIC_CSR_MTOP_STATUS, rd);
    check("top returns safe idle after position event", rd[0]);

    force dut.tdc_busy[0] = 1'b1;
    i2c_read_csr(SPADMIC_CSR_MTOP_STATUS, rd);
    check("position-only safe_idle ignores inactive TDC busy", rd[0]);
    release dut.tdc_busy[0];
    repeat (4) @(posedge clk_sys);

    i2c_write_csr(SPADMIC_CSR_MATRIX_CFG_COL, 32'd7);
    i2c_write_csr(SPADMIC_CSR_MATRIX_CFG_WDATA_LO, 32'h89AB_CDEF);
    i2c_write_csr(SPADMIC_CSR_MATRIX_CFG_WDATA_HI, 32'h0123_4567);
    i2c_write_csr(SPADMIC_CSR_MATRIX_CFG_CMD, {28'h0, OP_WRITE_COLUMN_64, 1'b1});
    repeat (300) @(posedge clk_sys);
    i2c_read_csr(SPADMIC_CSR_MATRIX_CFG_STATUS, rd);
    check("I2C observes matrix cfg valid", rd[8] && rd[7] && !rd[2]);
    i2c_read_csr(SPADMIC_CSR_MATRIX_CFG_RDATA_LO, rd);
    check("I2C reads matrix cfg low readback", rd == 32'h89AB_CDEF);
    i2c_read_csr(SPADMIC_CSR_MATRIX_CFG_RDATA_HI, rd);
    check("I2C reads matrix cfg high readback", rd == 32'h0123_4567);
    check("matrix config outputs return idle after command", matrix_din == '0 && matrix_cin == '0);

    i2c_write_csr(SPADMIC_CSR_MTOP_CTRL_REQUEST,
                  {24'h0, 1'b1, 3'b111, SPADMIC_MODE_TDC_ONLY, 1'b1});
    i2c_read_csr(SPADMIC_CSR_MTOP_CTRL_ACTIVE, rd);
    check("I2C commits TDC-only active mode", rd[3:1] == SPADMIC_MODE_TDC_ONLY);

    wait_cycles = 0;
    while (!dut.pre_event_resources_ready && wait_cycles < 500) begin
      wait_cycles++;
      @(posedge clk_sys);
    end
    check("TDC-only resources become ready", dut.pre_event_resources_ready);

    start_pair_count = ddr_pair_count;
    R = 64'h0000_0000_0000_0020;
    Y = 64'h0000_0000_0000_0040;
    B = 64'h0000_0000_0000_0080;
    wait (Rz != {64{1'b1}});
    check("TDC-only event asserts selective reset", !Rz[5] && !Yz[6] && !Bz[7]);
    repeat (4) @(posedge clk_sys);
    R = '0;
    Y = '0;
    B = '0;

    wait_cycles = 0;
    while (!dut.safe_idle && wait_cycles < 20_000) begin
      wait_cycles++;
      @(posedge clk_sys);
    end
    i2c_read_csr(SPADMIC_CSR_MTOP_STATUS, rd);
    check("TDC-only event returns safe idle", rd[0]);
    check("TDC-only event emits DDR16 output", ddr_pair_count > start_pair_count);
    i2c_read_csr(SPADMIC_CSR_MATRIX_EVENT_STATUS, rd);
    check("TDC-only completed packet mask is R/Y/B only", rd[7:4] == 4'b0111);

    if (fail_count != 0)
      $fatal(1, "tb_spadmic_top_matrix_v1_shell_unit: %0d failures", fail_count);

    $display("tb_spadmic_top_matrix_v1_shell_unit: %0d pass / %0d fail", pass_count, fail_count);
    $finish;
  end

  initial begin
    #2_000_000_000;
    $fatal(1, "tb_spadmic_top_matrix_v1_shell_unit: TIMEOUT");
  end
endmodule

`default_nettype wire
