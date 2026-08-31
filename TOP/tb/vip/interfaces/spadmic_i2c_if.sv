// =============================================================================
// SPADMIC VIP — I2C Pin-Level Interface
// Provides I2C SCL/SDA signals plus BFM tasks for write/read transactions.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

interface spadmic_i2c_if;
  import spadmic_pkg::*;

  logic clk_sys;
  logic rst_n;

  // I2C bus signals (directly connected to DUT)
  logic scl;
  logic sda_drive;    // TB drives SDA when master
  logic sda_oe;       // DUT drives SDA via open-drain
  logic sda;          // resolved SDA line

  // Timing parameters (in clk_sys cycles)
  localparam int unsigned I2C_HALF_PERIOD_CYC = 800;  // 100 kHz @ 160 MHz sys clock

  assign sda = sda_drive & ~sda_oe;

  // ── Helpers ────────────────────────────────────────────────────
  task automatic drive_bit(input logic bit_val);
    sda_drive = bit_val;
    #1;
    scl = 1'b1;
    repeat (I2C_HALF_PERIOD_CYC) @(posedge clk_sys);
    scl = 1'b0;
    repeat (I2C_HALF_PERIOD_CYC) @(posedge clk_sys);
  endtask

  task automatic read_bit(output logic bit_val);
    sda_drive = 1'b1;  // release SDA for slave to drive
    #1;
    scl = 1'b1;
    repeat (I2C_HALF_PERIOD_CYC / 2) @(posedge clk_sys);
    bit_val = sda;
    repeat (I2C_HALF_PERIOD_CYC - I2C_HALF_PERIOD_CYC / 2) @(posedge clk_sys);
    scl = 1'b0;
    repeat (I2C_HALF_PERIOD_CYC) @(posedge clk_sys);
  endtask

  task automatic start_condition();
    sda_drive = 1'b1;
    scl = 1'b1;
    repeat (I2C_HALF_PERIOD_CYC) @(posedge clk_sys);
    sda_drive = 1'b0;  // SDA falls while SCL is high
    repeat (I2C_HALF_PERIOD_CYC) @(posedge clk_sys);
    scl = 1'b0;
    repeat (I2C_HALF_PERIOD_CYC) @(posedge clk_sys);
  endtask

  task automatic stop_condition();
    sda_drive = 1'b0;
    scl = 1'b1;
    repeat (I2C_HALF_PERIOD_CYC) @(posedge clk_sys);
    sda_drive = 1'b1;  // SDA rises while SCL is high
    repeat (I2C_HALF_PERIOD_CYC) @(posedge clk_sys);
  endtask

  task automatic write_byte(input logic [7:0] data, output logic ack);
    for (int i = 7; i >= 0; i--)
      drive_bit(data[i]);
    read_bit(ack);  // 0=ACK, 1=NACK
  endtask

  task automatic read_byte(output logic [7:0] data, input logic send_ack);
    for (int i = 7; i >= 0; i--)
      read_bit(data[i]);
    drive_bit(~send_ack);  // 0=ACK, 1=NACK
  endtask

  // ── High-Level BFM Tasks ──────────────────────────────────────

  // Write one 32-bit CSR word using the ABI 1.0 16-bit pointer.
  task automatic i2c_write(
    input logic [15:0] addr,
    input logic [31:0] data,
    output logic       success
  );
    logic ack;
    success = 1'b1;

    start_condition();

    // Address byte (write)
    write_byte({SPADMIC_I2C_ADDR, 1'b0}, ack);
    if (ack) begin success = 1'b0; stop_condition(); return; end

    // Pointer bytes are MSB first.
    write_byte(addr[15:8], ack);
    if (ack) begin success = 1'b0; stop_condition(); return; end

    // Pointer low byte
    write_byte(addr[7:0], ack);
    if (ack) begin success = 1'b0; stop_condition(); return; end

    // Data bytes (big-endian)
    write_byte(data[31:24], ack);
    if (ack) begin success = 1'b0; stop_condition(); return; end
    write_byte(data[23:16], ack);
    if (ack) begin success = 1'b0; stop_condition(); return; end
    write_byte(data[15:8], ack);
    if (ack) begin success = 1'b0; stop_condition(); return; end
    write_byte(data[7:0], ack);
    if (ack) begin success = 1'b0; stop_condition(); return; end

    stop_condition();
  endtask

  // Read one 32-bit CSR word using a repeated START.
  task automatic i2c_read(
    input  logic [15:0] addr,
    output logic [31:0] data,
    output logic        success
  );
    logic ack;
    logic [7:0] byte_val;
    success = 1'b1;

    // Phase 1: write pointer
    start_condition();
    write_byte({SPADMIC_I2C_ADDR, 1'b0}, ack);
    if (ack) begin success = 1'b0; stop_condition(); return; end

    write_byte(addr[15:8], ack);
    if (ack) begin success = 1'b0; stop_condition(); return; end

    write_byte(addr[7:0], ack);
    if (ack) begin success = 1'b0; stop_condition(); return; end

    // Phase 2: repeated-START then read
    start_condition();
    write_byte({SPADMIC_I2C_ADDR, 1'b1}, ack);
    if (ack) begin success = 1'b0; stop_condition(); return; end

    read_byte(byte_val, 1'b1);  data[31:24] = byte_val;
    read_byte(byte_val, 1'b1);  data[23:16] = byte_val;
    read_byte(byte_val, 1'b1);  data[15:8]  = byte_val;
    read_byte(byte_val, 1'b0);  data[7:0]   = byte_val;  // NACK last byte

    stop_condition();
  endtask

  task automatic idle_bus();
    scl       = 1'b1;
    sda_drive = 1'b1;
  endtask
endinterface

`default_nettype wire
