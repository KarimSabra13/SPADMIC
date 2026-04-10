// =============================================================================
// SPADMIC VIP — I2C Pin-Level Interface
// Provides I2C SCL/SDA signals plus BFM tasks for write/read transactions.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

interface spadmic_i2c_if (
  input wire clk_sys,
  input wire rst_n
);
  import spadmic_pkg::*;

  // I2C bus signals (directly connected to DUT)
  logic scl;
  logic sda_drive;    // TB drives SDA when master
  logic sda_oe;       // DUT drives SDA via open-drain
  wire  sda = sda_drive & ~sda_oe;  // resolved SDA line

  // Timing parameters (in clk_sys cycles)
  int unsigned i2c_half_period = 80;  // ~1 MHz I2C @ 160 MHz sys clock

  // ── Helpers ────────────────────────────────────────────────────
  task automatic drive_bit(input logic bit_val);
    sda_drive = bit_val;
    #1;
    scl = 1'b1;
    repeat (i2c_half_period) @(posedge clk_sys);
    scl = 1'b0;
    repeat (i2c_half_period) @(posedge clk_sys);
  endtask

  task automatic read_bit(output logic bit_val);
    sda_drive = 1'b1;  // release SDA for slave to drive
    #1;
    scl = 1'b1;
    repeat (i2c_half_period / 2) @(posedge clk_sys);
    bit_val = sda;
    repeat (i2c_half_period - i2c_half_period / 2) @(posedge clk_sys);
    scl = 1'b0;
    repeat (i2c_half_period) @(posedge clk_sys);
  endtask

  task automatic start_condition();
    sda_drive = 1'b1;
    scl = 1'b1;
    repeat (i2c_half_period) @(posedge clk_sys);
    sda_drive = 1'b0;  // SDA falls while SCL is high
    repeat (i2c_half_period) @(posedge clk_sys);
    scl = 1'b0;
    repeat (i2c_half_period) @(posedge clk_sys);
  endtask

  task automatic stop_condition();
    sda_drive = 1'b0;
    scl = 1'b1;
    repeat (i2c_half_period) @(posedge clk_sys);
    sda_drive = 1'b1;  // SDA rises while SCL is high
    repeat (i2c_half_period) @(posedge clk_sys);
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

  // Write 32-bit data to 12-bit CSR address via I2C
  task automatic i2c_write(
    input logic [11:0] addr,
    input logic [31:0] data,
    output logic       success
  );
    logic ack;
    success = 1'b1;

    start_condition();

    // Address byte (write)
    write_byte({SPADMIC_I2C_ADDR, 1'b0}, ack);
    if (ack) begin success = 1'b0; stop_condition(); return; end

    // Pointer high byte (addr[11:8] in lower nibble)
    write_byte({4'b0, addr[11:8]}, ack);
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

  // Read 32-bit data from 12-bit CSR address via I2C (repeated-START)
  task automatic i2c_read(
    input  logic [11:0] addr,
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

    write_byte({4'b0, addr[11:8]}, ack);
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

  // ── Initial state ─────────────────────────────────────────────
  initial begin
    scl       = 1'b1;
    sda_drive = 1'b1;
  end

endinterface

`default_nettype wire
