`timescale 1ns/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC — Vernier Time-to-Digital Converter
// File     : mptdc_pulse_sync.sv
// Purpose  : Single-pulse clock-domain crossing via toggle synchroniser
// Author   : Karim Sabra
// =============================================================================
// Transfers a single-cycle pulse from one clock domain to another using
// the toggle-and-detect protocol:
//   - Source side: each incoming pulse toggles a register (toggle_src_q).
//     The toggle is quasi-static — it changes only on a pulse and stays
//     stable between pulses, making it safe for 2-FF synchronisation.
//   - Destination side: a 2-FF chain (sync_ff1, sync_ff2) resolves
//     metastability.  A third register (sync_ff3) holds the previous
//     cycle's value.  XOR of sync_ff2 and sync_ff3 produces a single-
//     cycle pulse whenever a toggle transition is detected.
//
// Assumption: consecutive source pulses must be spaced far enough apart
// (at least 2 destination clock cycles + metastability settling) for the
// toggle to propagate before the next pulse inverts it again.  In this
// design, the source is clk_sys (~160 MHz) and the destination is the
// oscillator clock (~1 GHz), so this constraint is easily met.
//
// Usage in the TDC: this module is used to relay conv_arm, start_seen,
// fsm_done, and writer_done pulses between clk_sys and the oscillator
// clock domains.
// =============================================================================
module mptdc_pulse_sync (
  // --- Source domain ---
  input  wire  src_clk,       // Source clock (pulse emitter)
  input  wire  src_rst_n,     // Asynchronous active-low reset
  input  wire  src_pulse,     // Single-cycle pulse to transfer

  // --- Destination domain ---
  input  wire  dst_clk,       // Destination clock (pulse receiver)
  input  wire  dst_rst_n,     // Asynchronous active-low reset
  output wire  dst_pulse      // Reproduced single-cycle pulse in dst domain
);

  // --- Stage 1: Pulse-to-toggle conversion (source domain) ---
  // Each incoming pulse inverts the toggle register.  Between pulses the
  // signal is stable, which is the key property for safe CDC transfer.
  logic toggle_src_q;

  always_ff @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n)        toggle_src_q <= 1'b0;
    else if (src_pulse)    toggle_src_q <= ~toggle_src_q;
  end

  // --- Stage 2: 2-FF synchroniser + edge detect (destination domain) ---
  // sync_ff1: first capture (potentially metastable)
  // sync_ff2: metastability resolution — value is reliable after this stage
  // sync_ff3: one-cycle delay of sync_ff2 for XOR edge detection
  logic sync_ff1, sync_ff2, sync_ff3;

  always_ff @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) begin
      sync_ff1 <= 1'b0;
      sync_ff2 <= 1'b0;
      sync_ff3 <= 1'b0;
    end else begin
      sync_ff1 <= toggle_src_q;   // Capture toggle (possibly metastable)
      sync_ff2 <= sync_ff1;       // Metastability resolution
      sync_ff3 <= sync_ff2;       // Previous-cycle value for edge detect
    end
  end

  // --- Output: transition detection via XOR ---
  // Produces exactly 1 cycle of dst_clk when a toggle transition is detected.
  assign dst_pulse = sync_ff2 ^ sync_ff3;

  // --- Simulation checks ---
  // synthesis translate_off
  always @(posedge dst_clk) begin
    if (dst_rst_n && $isunknown(sync_ff2))
      $display("[PULSE_SYNC] X detected in sync_ff2 -- check reset or timing");
  end
  // synthesis translate_on

endmodule

`default_nettype wire
