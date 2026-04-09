// ============================================================================
// I2C command-path unit test
// Covers: multi-byte write command capture, repeated-start read command capture,
//         non-global CSR address propagation, and payload integrity.
// ============================================================================
`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_i2c_control_plane_unit;
  import spadmic_pkg::*;

  localparam int CLK_PERIOD       = 6250;
  localparam int I2C_HALF_PERIOD  = 200_000;
  localparam int I2C_SAMPLE_DELAY = I2C_HALF_PERIOD/2;

  logic clk_sys;
  logic rst_n;

  logic i2c_scl_drv;
  logic i2c_sda_master_low;
  logic i2c_sda_oe;
  wire  i2c_scl = i2c_scl_drv;
  wire  i2c_sda = (i2c_sda_master_low | i2c_sda_oe) ? 1'b0 : 1'b1;

  logic                          txn_valid;
  logic                          txn_write;
  logic [SPADMIC_CSR_ADDR_W-1:0] txn_addr;
  logic [SPADMIC_CSR_DATA_W-1:0] txn_wdata;
  logic                          txn_ready;
  logic                          txn_rsp_valid;
  logic [SPADMIC_CSR_DATA_W-1:0] txn_rsp_rdata;
  logic                          txn_rsp_err;
  logic                          txn_rsp_ready;
  logic [31:0]                   readback_data;

  int pass_count;
  int fail_count;
  int test_num;

  initial clk_sys = 1'b0;
  always #(CLK_PERIOD/2) clk_sys = ~clk_sys;

  spadmic_i2c_slave u_dut (
    .clk_sys        (clk_sys),
    .rst_n          (rst_n),
    .i2c_scl_i      (i2c_scl),
    .i2c_sda_i      (i2c_sda),
    .i2c_sda_oe_o   (i2c_sda_oe),
    .txn_valid_o    (txn_valid),
    .txn_write_o    (txn_write),
    .txn_addr_o     (txn_addr),
    .txn_wdata_o    (txn_wdata),
    .txn_ready_i    (txn_ready),
    .txn_rsp_valid_i(txn_rsp_valid),
    .txn_rsp_rdata_i(txn_rsp_rdata),
    .txn_rsp_err_i  (txn_rsp_err),
    .txn_rsp_ready_o(txn_rsp_ready)
  );

  task automatic check(input string label, input logic cond);
    begin
      test_num++;
      if (cond) begin
        $display("[PASS] T%0d: %s", test_num, label);
        pass_count++;
      end else begin
        $display("[FAIL] T%0d: %s", test_num, label);
        fail_count++;
      end
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
    input  logic [7:0] byte_value,
    output logic       ack_ok
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
    input  logic       send_ack
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
    begin
      if (!ack_ok)
        $fatal(1, "Missing I2C ACK during %s", label);
    end
  endtask

  task automatic i2c_write_cmd(
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
      repeat (8) @(posedge clk_sys);
    end
  endtask

  task automatic i2c_begin_read_cmd(input logic [15:0] addr);
    logic ack_ok;
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
    end
  endtask

  task automatic clear_txn_valid;
    begin
      txn_ready = 1'b1;
      repeat (2) @(posedge clk_sys);
      txn_ready = 1'b0;
      repeat (2) @(posedge clk_sys);
    end
  endtask

  initial begin
    $display("========================================");
    $display("I2C COMMAND-PATH UNIT TEST");
    $display("========================================");

    pass_count         = 0;
    fail_count         = 0;
    test_num           = 0;
    rst_n              = 1'b0;
    i2c_scl_drv        = 1'b1;
    i2c_sda_master_low = 1'b0;
    txn_ready          = 1'b0;
    txn_rsp_valid      = 1'b0;
    txn_rsp_rdata      = '0;
    txn_rsp_err        = 1'b0;
    readback_data      = '0;

    repeat (10) @(posedge clk_sys);
    rst_n = 1'b1;
    repeat (10) @(posedge clk_sys);

    i2c_write_cmd(16'h0100, 32'hAABB_CCDD);
    check("Write command emitted", txn_valid === 1'b1);
    check("Write command marked write", txn_write === 1'b1);
    check("Write command captures full TDC_X address", txn_addr === 12'h100);
    check("Write command preserves 32-bit payload", txn_wdata === 32'hAABB_CCDD);
    clear_txn_valid();
    check("Write command clears after ready", txn_valid === 1'b0);

    i2c_begin_read_cmd(16'h0400);
    check("Read command emitted", txn_valid === 1'b1);
    check("Read command marked read", txn_write === 1'b0);
    check("Read command captures full POSITION address", txn_addr === 12'h400);
    txn_ready     = 1'b1;
    @(posedge clk_sys);
    txn_ready     = 1'b0;
    txn_rsp_rdata = 32'h1234_5678;
    txn_rsp_valid = 1'b1;
    @(posedge clk_sys);
    txn_rsp_valid = 1'b0;
    repeat (2) @(posedge clk_sys);
    begin
      logic [7:0] read_b3;
      logic [7:0] read_b2;
      logic [7:0] read_b1;
      logic [7:0] read_b0;
      i2c_read_byte(read_b3, 1'b1);
      i2c_read_byte(read_b2, 1'b1);
      i2c_read_byte(read_b1, 1'b1);
      i2c_read_byte(read_b0, 1'b0);
      readback_data = {read_b3, read_b2, read_b1, read_b0};
    end
    i2c_stop();
    repeat (2) @(posedge clk_sys);
    check("Read command returns 32-bit payload", readback_data === 32'h1234_5678);
    check("Read command clears after ready", txn_valid === 1'b0);

    $display("========================================");
    $display("I2C CMD PATH: %0d PASS, %0d FAIL out of %0d",
             pass_count, fail_count, test_num);
    $display("========================================");
    if (fail_count != 0)
      $fatal(1, "tb_spadmic_i2c_control_plane_unit: %0d failures", fail_count);
    $finish;
  end

  initial begin
    #500_000_000;
    $fatal(1, "TIMEOUT");
  end

endmodule

`default_nettype wire
