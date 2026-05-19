`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC v2.1 — Autonomous Frontend Vernier TDC
// File     : mptdc_sync_fifo.sv
// Purpose  : Simple synchronous FIFO with first-word fall-through (FWFT)
// Author   : Karim Sabra
// =============================================================================
// Single-clock FIFO.  Data written on wr_en is available at rd_data the cycle
// AFTER the write (FWFT: rd_valid goes high, rd_data holds the oldest entry).
// Consumer asserts rd_en to advance the read pointer.
//
// Parameters:
//   WIDTH — data width in bits
//   DEPTH — number of entries (must be power of 2 for simple pointer wrap)
// =============================================================================
module mptdc_sync_fifo #(
  parameter int WIDTH = 32,
  parameter int DEPTH = 32
)(
  input  wire              clk,
  input  wire              rst_n,       // synchronous reset, active-low
  input  wire              clr_i,       // synchronous clear

  // Write port
  input  wire              wr_en_i,
  input  wire [WIDTH-1:0]  wr_data_i,
  output logic             wr_full_o,

  // Read port (FWFT)
  input  wire              rd_en_i,
  output logic [WIDTH-1:0] rd_data_o,
  output logic             rd_valid_o,

  // Level
  output logic [$clog2(DEPTH+1)-1:0] level_o
);

  // =========================================================================
  // Local parameters
  // =========================================================================
  localparam int PTR_W = $clog2(DEPTH);
  localparam int LVL_W = $clog2(DEPTH + 1);

  // synthesis translate_off
  initial begin
    if (DEPTH < 2) begin
      $fatal(1, "mptdc_sync_fifo: DEPTH must be >= 2 (got %0d)", DEPTH);
    end
    if ((DEPTH & (DEPTH - 1)) != 0) begin
      $fatal(1, "mptdc_sync_fifo: DEPTH must be a power of two (got %0d)", DEPTH);
    end
  end
  // synthesis translate_on

  // =========================================================================
  // Storage + pointers
  // =========================================================================
  logic [WIDTH-1:0] mem [DEPTH];
  logic [PTR_W-1:0] wr_ptr_q, rd_ptr_q;
  logic [LVL_W-1:0] count_q, count_nxt;
  logic             full_q, valid_q;

  // =========================================================================
  // Status flags
  // =========================================================================
  assign wr_full_o  = full_q;
  assign rd_valid_o = valid_q;
  assign level_o    = count_q;

  // FWFT — combinational read from memory at current read pointer
  assign rd_data_o  = mem[rd_ptr_q];

  // =========================================================================
  // Effective write/read enables (gated by status)
  // =========================================================================
  wire wr_eff = wr_en_i & ~wr_full_o;
  wire rd_eff = rd_en_i & rd_valid_o;

  always_comb begin
    count_nxt = count_q;
    case ({wr_eff, rd_eff})
      2'b10: count_nxt = count_q + LVL_W'(1);
      2'b01: count_nxt = count_q - LVL_W'(1);
      default: ;
    endcase
  end

  // =========================================================================
  // Pointer and count update
  // =========================================================================
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      wr_ptr_q <= '0;
      rd_ptr_q <= '0;
      count_q  <= '0;
      full_q   <= 1'b0;
      valid_q  <= 1'b0;
    end else if (clr_i) begin
      wr_ptr_q <= '0;
      rd_ptr_q <= '0;
      count_q  <= '0;
      full_q   <= 1'b0;
      valid_q  <= 1'b0;
    end else begin
      case ({wr_eff, rd_eff})
        2'b10: begin   // write only
          mem[wr_ptr_q] <= wr_data_i;
          wr_ptr_q <= (wr_ptr_q == PTR_W'(DEPTH - 1)) ? '0 : wr_ptr_q + PTR_W'(1);
        end

        2'b01: begin   // read only
          rd_ptr_q <= (rd_ptr_q == PTR_W'(DEPTH - 1)) ? '0 : rd_ptr_q + PTR_W'(1);
        end

        2'b11: begin   // simultaneous read + write
          mem[wr_ptr_q] <= wr_data_i;
          wr_ptr_q <= (wr_ptr_q == PTR_W'(DEPTH - 1)) ? '0 : wr_ptr_q + PTR_W'(1);
          rd_ptr_q <= (rd_ptr_q == PTR_W'(DEPTH - 1)) ? '0 : rd_ptr_q + PTR_W'(1);
        end

        default: ;   // no operation
      endcase

      count_q <= count_nxt;
      full_q  <= (count_nxt == LVL_W'(DEPTH));
      valid_q <= (count_nxt != '0);
    end
  end

  // synthesis translate_off
  logic             rd_hold_valid_q;
  logic [WIDTH-1:0] rd_data_hold_q;

  always_ff @(posedge clk) begin
    if (!rst_n || clr_i) begin
      rd_hold_valid_q <= 1'b0;
      rd_data_hold_q  <= '0;
    end else begin
      assert (count_q <= LVL_W'(DEPTH));
      if (wr_full_o)  assert (!wr_eff);
      if (!rd_valid_o) assert (!rd_eff);

      if (rd_valid_o && !rd_en_i) begin
        if (rd_hold_valid_q) assert (rd_data_o == rd_data_hold_q);
        rd_hold_valid_q <= 1'b1;
        rd_data_hold_q  <= rd_data_o;
      end else begin
        rd_hold_valid_q <= 1'b0;
      end
    end
  end
  // synthesis translate_on

endmodule

`default_nettype wire
