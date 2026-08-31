// ============================================================================
// I2C command-path unit test
// Covers: fixed-address framing, 16-bit pointer and 32-bit big-endian payloads,
//         repeated/current-pointer reads, pointer-only writes, and atomic
//         rejection of one-, two-, and three-byte partial write payloads.
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
  logic                          transaction_active;
  logic                          incomplete_write_active;
  logic                          write_abort;
  logic [SPADMIC_CSR_ADDR_W-1:0] write_abort_addr;
  logic [SPADMIC_CSR_DATA_W-1:0] write_abort_wdata;
  logic [31:0]                   readback_data;
  int                            abort_count;
  logic [15:0]                   last_abort_addr;
  logic [31:0]                   last_abort_wdata;

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
    .txn_rsp_ready_o(txn_rsp_ready),
    .transaction_active_o(transaction_active),
    .incomplete_write_active_o(incomplete_write_active),
    .write_abort_o(write_abort),
    .write_abort_addr_o(write_abort_addr),
    .write_abort_wdata_o(write_abort_wdata)
  );

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      abort_count <= 0;
      last_abort_addr <= '0;
      last_abort_wdata <= '0;
    end else if (write_abort) begin
      abort_count <= abort_count + 1;
      last_abort_addr <= write_abort_addr;
      last_abort_wdata <= write_abort_wdata;
    end
  end

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

  task automatic i2c_set_pointer(input logic [15:0] addr);
    logic ack_ok;
    begin
      i2c_start();
      i2c_write_byte({SPADMIC_I2C_ADDR, 1'b0}, ack_ok);
      i2c_expect_ack(ack_ok, "device-address pointer-only");
      i2c_write_byte(addr[15:8], ack_ok);
      i2c_expect_ack(ack_ok, "pointer-only high");
      i2c_write_byte(addr[7:0], ack_ok);
      i2c_expect_ack(ack_ok, "pointer-only low");
      i2c_stop();
      repeat (4) @(posedge clk_sys);
    end
  endtask

  task automatic i2c_begin_current_pointer_read;
    logic ack_ok;
    begin
      i2c_start();
      i2c_write_byte({SPADMIC_I2C_ADDR, 1'b1}, ack_ok);
      i2c_expect_ack(ack_ok, "device-address current-pointer read");
      repeat (4) @(posedge clk_sys);
    end
  endtask

  task automatic i2c_partial_write(
    input logic [15:0] addr,
    input logic [31:0] data,
    input int byte_count,
    input logic terminate_with_restart
  );
    logic ack_ok;
    begin
      i2c_start();
      i2c_write_byte({SPADMIC_I2C_ADDR, 1'b0}, ack_ok);
      i2c_expect_ack(ack_ok, "partial device-address");
      i2c_write_byte(addr[15:8], ack_ok);
      i2c_expect_ack(ack_ok, "partial pointer high");
      i2c_write_byte(addr[7:0], ack_ok);
      i2c_expect_ack(ack_ok, "partial pointer low");
      if (byte_count >= 1) begin
        i2c_write_byte(data[31:24], ack_ok);
        i2c_expect_ack(ack_ok, "partial data byte 0");
      end
      if (byte_count >= 2) begin
        i2c_write_byte(data[23:16], ack_ok);
        i2c_expect_ack(ack_ok, "partial data byte 1");
      end
      if (byte_count >= 3) begin
        i2c_write_byte(data[15:8], ack_ok);
        i2c_expect_ack(ack_ok, "partial data byte 2");
      end
      if (terminate_with_restart) begin
        i2c_restart();
        i2c_write_byte({7'h43, 1'b0}, ack_ok);
        i2c_stop();
      end else begin
        i2c_stop();
      end
      repeat (8) @(posedge clk_sys);
    end
  endtask

  task automatic i2c_read_response(
    input logic [31:0] response_data,
    input logic response_error,
    output logic [31:0] received_data
  );
    logic [7:0] read_b3;
    logic [7:0] read_b2;
    logic [7:0] read_b1;
    logic [7:0] read_b0;
    begin
      txn_ready = 1'b1;
      @(posedge clk_sys);
      txn_ready = 1'b0;
      txn_rsp_rdata = response_data;
      txn_rsp_err = response_error;
      txn_rsp_valid = 1'b1;
      @(posedge clk_sys);
      txn_rsp_valid = 1'b0;
      txn_rsp_err = 1'b0;
      repeat (2) @(posedge clk_sys);
      i2c_read_byte(read_b3, 1'b1);
      i2c_read_byte(read_b2, 1'b1);
      i2c_read_byte(read_b1, 1'b1);
      i2c_read_byte(read_b0, 1'b0);
      received_data = {read_b3, read_b2, read_b1, read_b0};
      i2c_stop();
      repeat (2) @(posedge clk_sys);
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
    abort_count        = 0;

    repeat (10) @(posedge clk_sys);
    rst_n = 1'b1;
    repeat (10) @(posedge clk_sys);

    begin
      logic ack_ok;

      i2c_start();
      i2c_write_byte({7'h43, 1'b0}, ack_ok);
      check("Non-matching I2C address NACKs", ack_ok === 1'b0);
      i2c_stop();
      repeat (4) @(posedge clk_sys);
      check("Non-matching address emits no transaction", txn_valid === 1'b0);

      i2c_start();
      i2c_write_byte({SPADMIC_I2C_ADDR, 1'b1}, ack_ok);
      check("Read without valid pointer NACKs", ack_ok === 1'b0);
      i2c_stop();
      repeat (4) @(posedge clk_sys);
      check("Pointerless read emits no transaction", txn_valid === 1'b0);
    end

    i2c_write_cmd(16'h0100, 32'hAABB_CCDD);
    check("Write command emitted", txn_valid === 1'b1);
    check("Write command marked write", txn_write === 1'b1);
    check("Write command captures full TDC_X address", txn_addr === 16'h0100);
    check("Write command preserves 32-bit payload", txn_wdata === 32'hAABB_CCDD);
    clear_txn_valid();
    check("Write command clears after ready", txn_valid === 1'b0);

    i2c_begin_read_cmd(16'h0400);
    check("Read command emitted", txn_valid === 1'b1);
    check("Read command marked read", txn_write === 1'b0);
    check("Read command captures full POSITION address", txn_addr === 16'h0400);
    i2c_read_response(32'h1234_5678, 1'b0, readback_data);
    check("Read command returns 32-bit payload", readback_data === 32'h1234_5678);
    check("Read command clears after ready", txn_valid === 1'b0);

    begin
      int abort_before;
      abort_before = abort_count;
      i2c_set_pointer(16'h9004);
      check("Pointer-only write emits no CSR command", txn_valid === 1'b0);
      check("Pointer-only write is not an incomplete write", abort_count == abort_before);
      i2c_begin_current_pointer_read();
      check("Current-pointer read emits a read command", txn_valid && !txn_write);
      check("Current-pointer read reuses the stored pointer", txn_addr == 16'h9004);
      i2c_read_response(32'hCAFE_BABE, 1'b0, readback_data);
      check("Current-pointer read preserves byte order", readback_data == 32'hCAFE_BABE);
    end

    i2c_begin_read_cmd(16'hA000);
    i2c_read_response(32'hFFFF_FFFF, 1'b1, readback_data);
    check("Errored CSR reads return four zero bytes", readback_data == 32'h0000_0000);

    begin
      int abort_before;
      abort_before = abort_count;
      i2c_partial_write(16'h4000, 32'hA5B6_C7D8, 1, 1'b0);
      check("One-byte partial write is discarded", txn_valid === 1'b0);
      check("STOP reports one-byte partial write", abort_count == abort_before + 1);
      check("One-byte abort preserves address and received MSB",
            last_abort_addr == 16'h4000 && last_abort_wdata == 32'hA500_0000);

      abort_before = abort_count;
      i2c_partial_write(16'h8000, 32'h1122_3344, 2, 1'b1);
      check("Two-byte repeated-start write is discarded", txn_valid === 1'b0);
      check("Repeated START reports two-byte partial write", abort_count == abort_before + 1);
      check("Two-byte abort preserves received prefix",
            last_abort_addr == 16'h8000 && last_abort_wdata == 32'h1122_0000);

      abort_before = abort_count;
      i2c_partial_write(16'h9000, 32'hDEAD_BEEF, 3, 1'b0);
      check("Three-byte partial write is discarded", txn_valid === 1'b0);
      check("STOP reports three-byte partial write", abort_count == abort_before + 1);
      check("Three-byte abort preserves received prefix",
            last_abort_addr == 16'h9000 && last_abort_wdata == 32'hDEAD_BE00);
    end

    i2c_write_cmd(16'h7100, 32'h5566_7788);
    check("Write command preserves full 16-bit high region address", txn_addr === 16'h7100);
    check("High-region write command preserves payload", txn_wdata === 32'h5566_7788);
    clear_txn_valid();

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
