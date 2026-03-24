`timescale 1ns/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC — Vernier Time-to-Digital Converter
// File     : mptdc_async_fifo.sv
// Purpose  : Asynchronous FIFO with Gray-code pointers for multi-bit CDC
// Author   : Karim Sabra
// =============================================================================
// This is the primary clock-domain crossing mechanism for multi-bit data
// in the TDC.  It transfers acquisition records (META + HIT) from the fast
// oscillator clock domain (~1 GHz) to the system clock domain (~160 MHz).
//
// Architecture:
//   - Dual-port memory (RTL array, mapped to FFs or SRAM by synthesis).
//   - Write and read pointers are maintained in binary for memory addressing
//     and in Gray code for safe CDC comparison.
//   - Gray-coded pointers are synchronised to the opposite clock domain
//     via 2-FF chains annotated with ASYNC_REG for correct placement.
//   - Full detection: the write-side Gray pointer equals the read-side
//     Gray pointer with the two MSBs inverted.
//   - Empty detection: the read-side Gray pointer equals the write-side
//     Gray pointer (identical).
//
// Constraints:
//   - DEPTH must be a power of 2 (enforced by elaboration-time check).
//   - Write when full and read when empty are silently ignored (pointer
//     does not advance), guarded by simulation assertions.
//
// Level outputs (wr_level_o, rd_level_o) are approximate: they use the
// synchronised pointer from the opposite domain, so they may lag by up
// to 2 clock cycles.  They are used for CSR status reporting, not for
// flow control.
// =============================================================================
module mptdc_async_fifo #(
  parameter int unsigned WIDTH = 32,
  parameter int unsigned DEPTH = 16
)(
  // Write port (fast oscillator domain)
  input  wire                               wr_clk,
  input  wire                               wr_rst_n,
  input  wire                               wr_clr_i,
  input  wire                               wr_en_i,
  input  wire [WIDTH-1:0]                   wr_data_i,
  output logic                              wr_full_o,
  output logic [$clog2(DEPTH+1)-1:0]        wr_level_o,

  // Read port (system clock domain)
  input  wire                               rd_clk,
  input  wire                               rd_rst_n,
  input  wire                               rd_clr_i,
  input  wire                               rd_en_i,
  output logic [WIDTH-1:0]                  rd_data_o,
  output logic                              rd_empty_o,
  output logic [$clog2(DEPTH+1)-1:0]        rd_level_o
);
  localparam int unsigned ADDR_W = (DEPTH <= 1) ? 1 : $clog2(DEPTH);
  localparam int unsigned PTR_W  = ADDR_W + 1;   // Extra bit for full/empty distinction
  localparam int unsigned LVL_W  = (DEPTH <= 1) ? 1 : $clog2(DEPTH + 1);

  // Dual-port memory
  logic [WIDTH-1:0] mem [0:DEPTH-1];

  // Binary and Gray-code pointers
  logic [PTR_W-1:0] wr_ptr_bin_r, wr_ptr_bin_n;
  logic [PTR_W-1:0] wr_ptr_gray_r, wr_ptr_gray_n;
  logic [PTR_W-1:0] rd_ptr_bin_r, rd_ptr_bin_n;
  logic [PTR_W-1:0] rd_ptr_gray_r, rd_ptr_gray_n;

  // 2-FF synchroniser chains for cross-domain pointer transfer
  (* ASYNC_REG = "TRUE" *) logic [PTR_W-1:0] rd_ptr_gray_sync1_r, rd_ptr_gray_sync2_r;
  (* ASYNC_REG = "TRUE" *) logic [PTR_W-1:0] wr_ptr_gray_sync1_r, wr_ptr_gray_sync2_r;

  // Synchronised binary pointers (decoded from Gray)
  logic [PTR_W-1:0] rd_ptr_bin_sync_w;
  logic [PTR_W-1:0] wr_ptr_bin_sync_w;
  logic wr_full_n;
  logic rd_empty_n;

  // -----------------------------------------------------------------------
  // Power-of-2 constraint check
  // -----------------------------------------------------------------------
  initial begin
    if ((DEPTH & (DEPTH - 1)) != 0) begin
      $fatal(1, "[ASYNC_FIFO] DEPTH=%0d must be a power of 2.", DEPTH);
    end
  end

  // -----------------------------------------------------------------------
  // Gray-code conversion functions
  // -----------------------------------------------------------------------
  function automatic logic [PTR_W-1:0] bin2gray(input logic [PTR_W-1:0] bin_i);
    bin2gray = (bin_i >> 1) ^ bin_i;
  endfunction

  function automatic logic [PTR_W-1:0] gray2bin(input logic [PTR_W-1:0] gray_i);
    logic [PTR_W-1:0] bin_v;
    bin_v[PTR_W-1] = gray_i[PTR_W-1];
    for (int gi = PTR_W-2; gi >= 0; gi--) begin
      bin_v[gi] = bin_v[gi+1] ^ gray_i[gi];
    end
    gray2bin = bin_v;
  endfunction

  // -----------------------------------------------------------------------
  // Next-state pointer computation
  // -----------------------------------------------------------------------
  assign wr_ptr_bin_n  = wr_ptr_bin_r + PTR_W'((wr_en_i && !wr_full_o) ? 1'b1 : 1'b0);
  assign wr_ptr_gray_n = bin2gray(wr_ptr_bin_n);
  assign rd_ptr_bin_n  = rd_ptr_bin_r + PTR_W'((rd_en_i && !rd_empty_o) ? 1'b1 : 1'b0);
  assign rd_ptr_gray_n = bin2gray(rd_ptr_bin_n);

  assign rd_ptr_bin_sync_w = gray2bin(rd_ptr_gray_sync2_r);
  assign wr_ptr_bin_sync_w = gray2bin(wr_ptr_gray_sync2_r);

  // Full detection: MSBs inverted, remaining bits identical
  generate
    if (PTR_W > 2) begin : gen_full_cmp_wide
      assign wr_full_n = (wr_ptr_gray_n ==
          {~rd_ptr_gray_sync2_r[PTR_W-1:PTR_W-2], rd_ptr_gray_sync2_r[PTR_W-3:0]});
    end else begin : gen_full_cmp_narrow
      assign wr_full_n = (wr_ptr_gray_n == ~rd_ptr_gray_sync2_r);
    end
  endgenerate
  // Empty detection: pointers identical
  assign rd_empty_n = (rd_ptr_gray_n == wr_ptr_gray_sync2_r);

  // -----------------------------------------------------------------------
  // Write-side logic
  // -----------------------------------------------------------------------
  always_ff @(posedge wr_clk or negedge wr_rst_n) begin
    if (!wr_rst_n) begin
      wr_ptr_bin_r <= '0;
      wr_ptr_gray_r <= '0;
      rd_ptr_gray_sync1_r <= '0;
      rd_ptr_gray_sync2_r <= '0;
      wr_full_o <= 1'b0;
    end else begin
      // Synchronise read pointer Gray code into the write domain
      rd_ptr_gray_sync1_r <= rd_ptr_gray_r;
      rd_ptr_gray_sync2_r <= rd_ptr_gray_sync1_r;
      if (wr_clr_i) begin
        wr_ptr_bin_r  <= '0;
        wr_ptr_gray_r <= '0;
        wr_full_o     <= 1'b0;
      end else begin
        if (wr_en_i && !wr_full_o) begin
          mem[wr_ptr_bin_r[ADDR_W-1:0]] <= wr_data_i;
        end
        wr_ptr_bin_r  <= wr_ptr_bin_n;
        wr_ptr_gray_r <= wr_ptr_gray_n;
        wr_full_o     <= wr_full_n;
      end
    end
  end

  // -----------------------------------------------------------------------
  // Read-side logic (FWFT / show-ahead: rd_data_o is combinational)
  // -----------------------------------------------------------------------
  always_ff @(posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n) begin
      rd_ptr_bin_r <= '0;
      rd_ptr_gray_r <= '0;
      wr_ptr_gray_sync1_r <= '0;
      wr_ptr_gray_sync2_r <= '0;
      rd_empty_o <= 1'b1;
    end else begin
      // Synchronise write pointer Gray code into the read domain
      wr_ptr_gray_sync1_r <= wr_ptr_gray_r;
      wr_ptr_gray_sync2_r <= wr_ptr_gray_sync1_r;
      if (rd_clr_i) begin
        rd_ptr_bin_r  <= '0;
        rd_ptr_gray_r <= '0;
        rd_empty_o    <= 1'b1;
      end else begin
        rd_ptr_bin_r  <= rd_ptr_bin_n;
        rd_ptr_gray_r <= rd_ptr_gray_n;
        rd_empty_o    <= rd_empty_n;
      end
    end
  end

  // FWFT read data: combinational from memory at current read pointer
  assign rd_data_o = mem[rd_ptr_bin_r[ADDR_W-1:0]];

  // -----------------------------------------------------------------------
  // Approximate level outputs (for CSR status, not flow control)
  // -----------------------------------------------------------------------
  always_comb begin
    wr_level_o = LVL_W'(wr_ptr_bin_r - rd_ptr_bin_sync_w);
    rd_level_o = LVL_W'(wr_ptr_bin_sync_w - rd_ptr_bin_r);
  end

  // -----------------------------------------------------------------------
  // Simulation assertions
  // -----------------------------------------------------------------------
  // synthesis translate_off
`ifndef MPTDC_NO_SVA
  property p_no_write_when_full;
    @(posedge wr_clk) disable iff (!wr_rst_n)
      wr_en_i && wr_full_o |=> (wr_ptr_bin_r == $past(wr_ptr_bin_r));
  endproperty
  a_no_write_when_full: assert property (p_no_write_when_full)
    else $error("[ASYNC_FIFO] Write accepted while FIFO is full.");

  property p_no_read_when_empty;
    @(posedge rd_clk) disable iff (!rd_rst_n)
      rd_en_i && rd_empty_o |=> (rd_ptr_bin_r == $past(rd_ptr_bin_r));
  endproperty
  a_no_read_when_empty: assert property (p_no_read_when_empty)
    else $error("[ASYNC_FIFO] Read accepted while FIFO is empty.");
`endif
  // synthesis translate_on

endmodule

`default_nettype wire
