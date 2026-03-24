`timescale 1ns/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC v2.0 — Raw-Output Vernier TDC with Triple-Buffer
// File     : mptdc_async_frontend_v2.sv
// Purpose  : Asynchronous frontend v2 — triple-buffered context management
//            with minimal-deadtime re-arm path (~4-11 ns)
// Author   : Karim Sabra
// =============================================================================
// Purely asynchronous, clock-free module.  All state is held in SR latches
// and transparent latches; all outputs are combinational or latch-level.
//
// Architecture:
//   1. START pulse → allocate lowest-index FREE context → CAPTURING.
//   2. STOP  pulse → CAPTURING context transitions to DRAINING; snapshot
//      trigger (capture_done_async_o) fires.
//   3. fe_clear_async_i (from CDC after writer confirms snapshot) clears
//      the start/stop latches so a new START can arrive immediately.
//      The previously-captured context remains DRAINING — the frontend
//      does NOT wait for the writer.
//   4. ctx_release_async_i[k] (from writer when drain finishes) returns
//      context k to FREE.
//
// Deadtime ≈ fe_clear propagation + first-free priority-encode + SR-set.
// =============================================================================
module mptdc_async_frontend_v2
  import mptdc_pkg::*;
(
  // Global async reset (active-low)
  input  wire                  rst_n,

  // Async pulse inputs from input mux
  input  wire                  start_async_i,
  input  wire                  stop_async_i,

  // Clear / release handshake
  input  wire                  fe_clear_async_i,         // clears start+stop latches
  input  wire  [N_CTX-1:0]    ctx_release_async_i,       // per-ctx: writer done draining

  // Latch status
  output logic                 start_latched_o,
  output logic                 stop_latched_o,

  // Oscillator / phase-detector enables
  output logic                 osc_slow_en_async_o,       // = start_latched
  output logic                 osc_fast_en_async_o,       // = stop_latched
  output logic                 pd_enable_async_o,         // = start & stop

  // Context management
  output ctx_id_t              active_ctx_o,              // currently CAPTURING ctx
  output ctx_state_e           ctx_state_o [N_CTX],       // per-ctx state
  output logic                 all_ctx_busy_o,            // no free ctx (overflow)

  // Snapshot trigger
  output logic                 capture_done_async_o       // pulse on STOP capture
);

  // =========================================================================
  // Internal state elements
  // =========================================================================
  logic              start_latched_q;
  logic              stop_latched_q;
  ctx_id_t           active_ctx_q;
  logic [N_CTX-1:0]  ctx_drain_q;

  // =========================================================================
  // Free-context detection and priority allocation
  // =========================================================================
  // Free-context detection and priority allocation
  // =========================================================================
  // ctx_free is based only on drain state, NOT on start_latched — this
  // breaks the combinational loop that Verilator cannot converge on.
  // The "busy" accounting is: a context is unavailable if it's draining.
  // The CAPTURING context is implicitly "unavailable" because start_latched_q
  // prevents re-arming until fe_clear.
  logic [N_CTX-1:0] ctx_free;
  logic             any_ctx_free;
  ctx_id_t          alloc_ctx;

  always_comb begin
    for (int i = 0; i < N_CTX; i++) begin
      ctx_free[i] = ~ctx_drain_q[i];
    end
    any_ctx_free = |ctx_free;

    // Priority encoder: lowest-index free context wins
    alloc_ctx = ctx_id_t'(0);
    for (int i = N_CTX - 1; i >= 0; i--) begin
      if (ctx_free[i])
        alloc_ctx = ctx_id_t'(i);
    end
  end

  // =========================================================================
  // START latch  (SR: set by start_async, reset by fe_clear / rst_n)
  // =========================================================================
  // Reset-dominant: fe_clear can arrive while start_async is still high.
  always_latch begin
    if (!rst_n || fe_clear_async_i)
      start_latched_q = 1'b0;
    else if (start_async_i & any_ctx_free)
      start_latched_q = 1'b1;
  end

  // =========================================================================
  // STOP latch  (SR: set by stop_async, reset by fe_clear / rst_n)
  // =========================================================================
  always_latch begin
    if (!rst_n || fe_clear_async_i)
      stop_latched_q = 1'b0;
    else if (stop_async_i & start_latched_q)
      stop_latched_q = 1'b1;
  end

  // =========================================================================
  // Active-context register  (transparent latch, captures alloc on START)
  // =========================================================================
  always_latch begin
    if (!rst_n)
      active_ctx_q = ctx_id_t'(0);
    else if (start_async_i & any_ctx_free & ~fe_clear_async_i)
      active_ctx_q = alloc_ctx;
  end

  // =========================================================================
  // Per-context drain latches
  // =========================================================================
  // Each context has an independent SR latch:
  //   SET   — STOP captured while this context is CAPTURING
  //   RESET — writer releases this context (or global rst_n)
  for (genvar g = 0; g < N_CTX; g++) begin : gen_ctx_drain
    always_latch begin
      if (!rst_n || ctx_release_async_i[g])
        ctx_drain_q[g] = 1'b0;
      else if (stop_async_i & start_latched_q
               & (active_ctx_q == ctx_id_t'(g)))
        ctx_drain_q[g] = 1'b1;
    end
  end

  // =========================================================================
  // Context state decode  (combinational from drain latches + active ctx)
  // =========================================================================
  always_comb begin
    for (int i = 0; i < N_CTX; i++) begin
      if (ctx_drain_q[i])
        ctx_state_o[i] = CTX_DRAINING;
      else if (start_latched_q & (active_ctx_q == ctx_id_t'(i)))
        ctx_state_o[i] = CTX_CAPTURING;
      else
        ctx_state_o[i] = CTX_FREE;
    end
  end

  // =========================================================================
  // Output assignments
  // =========================================================================
  assign start_latched_o      = start_latched_q;
  assign stop_latched_o       = stop_latched_q;
  assign active_ctx_o         = active_ctx_q;
  assign all_ctx_busy_o       = ~any_ctx_free;

  // Oscillators must keep running while CAPTURING *or* while any context
  // is DRAINING (the writer is clocked by osc_fast_ph0 and needs it alive).
  assign osc_slow_en_async_o  = start_latched_q | (|ctx_drain_q);
  assign osc_fast_en_async_o  = start_latched_q | (|ctx_drain_q);
  assign pd_enable_async_o    = start_latched_q;    // PD samples only during capture

  // Pulse coincident with STOP while a capture is active.
  // Uses the raw stop_async_i for immediate, single-cycle trigger.
  assign capture_done_async_o = stop_async_i & start_latched_q;

endmodule

`default_nettype wire
