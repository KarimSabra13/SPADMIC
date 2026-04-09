`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC v2.2 — Design Review Enhanced Vernier TDC
// File     : mptdc_async_frontend_v2.sv
// Purpose  : Asynchronous frontend — classic Vernier oscillator control
//            with double-buffered context management
// Author   : Karim Sabra
// =============================================================================
// v2.2 changes:
//   - start_rejected_o: pulses when START arrives but is rejected (no free
//     context or not armed). Used for real overflow counting in sys_clk.
//   - start_timeout_async_i: injects a synthetic STOP when slow-domain
//     watchdog fires (STOP never arrived). Triggers normal measurement
//     close → capture → drain → packet with watchdog flag.
//   - overflow flag removed from conv_flags (was misused as hit-saturation).
//   - Comments corrected: double-buffer (N_CTX=2), not triple-buffer.
// =============================================================================
module mptdc_async_frontend_v2
  import mptdc_pkg::*;
(
  input  wire                  rst_n,

  // Arm control (quasi-static level from CSR — gates START acceptance)
  input  wire                  conv_arm_i,

  // Async pulse inputs from input mux
  input  wire                  start_async_i,
  input  wire                  stop_async_i,

  // Clear / release handshake
  input  wire                  fe_clear_async_i,         // clears start+stop latches
  input  wire                  start_timeout_async_i,    // v2.2: slow-domain wdt force-clear
  input  wire  [N_CTX-1:0]    ctx_release_async_i,       // per-ctx: drain FSM done

  // Capture trigger from meas_ctrl (fast domain registered output)
  input  wire                  capture_en_i,

  // Oscillator keep-alive from meas_ctrl
  input  wire                  osc_keep_alive_i,

  // Latch status
  output logic                 start_latched_o,
  output logic                 stop_latched_o,

  // Oscillator / phase-detector enables (classic Vernier)
  output logic                 osc_slow_en_async_o,
  output logic                 osc_fast_en_async_o,
  output logic                 pd_enable_async_o,

  // Context management
  output ctx_id_t              active_ctx_o,
  output ctx_state_e           ctx_state_o [N_CTX],
  output logic [N_CTX-1:0]    ctx_drain_o,
  output logic                 all_ctx_busy_o,

  // v2.2: rejected START indicator (for real overflow counting)
  output logic                 start_rejected_o
);

  // Combined clear: measurement FSM clear only (not timeout — that injects synthetic STOP)
  wire clear_any = fe_clear_async_i;

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
  // ctx_free is based only on drain state, NOT on start_latched — this
  // breaks the combinational loop that Verilator cannot converge on.
  // CAPTURING context is implicitly unavailable (start_latched prevents re-arm).
  logic [N_CTX-1:0] ctx_free;
  logic             any_ctx_free;
  ctx_id_t          alloc_ctx;

  always_comb begin
    for (int i = 0; i < N_CTX; i++) begin
      ctx_free[i] = ~ctx_drain_q[i];
    end
    any_ctx_free = |ctx_free;

    alloc_ctx = ctx_id_t'(0);
    for (int i = N_CTX - 1; i >= 0; i--) begin
      if (ctx_free[i])
        alloc_ctx = ctx_id_t'(i);
    end
  end

  // =========================================================================
  // START rejected: START present but cannot be accepted
  // =========================================================================
  assign start_rejected_o = start_async_i & (~any_ctx_free | ~conv_arm_i)
                          & ~start_latched_q;

  // =========================================================================
  // START latch  (SR: set by start_async, reset by clear_any / rst_n)
  // =========================================================================
  always_latch begin
    if (!rst_n || clear_any)
      start_latched_q = 1'b0;
    else if (start_async_i & any_ctx_free & conv_arm_i)
      start_latched_q = 1'b1;
  end

  // =========================================================================
  // STOP latch  (SR: set by stop_async or synthetic stop from timeout,
  //              reset by clear_any / rst_n)
  // =========================================================================
  always_latch begin
    if (!rst_n || clear_any)
      stop_latched_q = 1'b0;
    else if ((stop_async_i | start_timeout_async_i) & start_latched_q)
      stop_latched_q = 1'b1;
  end

  // =========================================================================
  // Active-context register  (transparent latch, captures alloc on START)
  // =========================================================================
  always_latch begin
    if (!rst_n)
      active_ctx_q = ctx_id_t'(0);
    else if (start_async_i & any_ctx_free & ~clear_any)
      active_ctx_q = alloc_ctx;
  end

  // =========================================================================
  // Per-context drain latches
  // =========================================================================
  for (genvar g = 0; g < N_CTX; g++) begin : gen_ctx_drain
    always_latch begin
      if (!rst_n || ctx_release_async_i[g])
        ctx_drain_q[g] = 1'b0;
      else if (capture_en_i & start_latched_q
               & (active_ctx_q == ctx_id_t'(g)))
        ctx_drain_q[g] = 1'b1;
    end
  end

  // =========================================================================
  // Context state decode
  // =========================================================================
  always_comb begin
    for (int i = 0; i < N_CTX; i++) begin
      if (start_latched_q & (active_ctx_q == ctx_id_t'(i)))
        ctx_state_o[i] = CTX_CAPTURING;
      else if (ctx_drain_q[i])
        ctx_state_o[i] = CTX_DRAINING;
      else
        ctx_state_o[i] = CTX_FREE;
    end
  end

  // =========================================================================
  // Output assignments — Classic Vernier oscillator enables (v2.2)
  // =========================================================================
  assign start_latched_o      = start_latched_q;
  assign stop_latched_o       = stop_latched_q;
  assign active_ctx_o         = active_ctx_q;
  assign ctx_drain_o          = ctx_drain_q;
  assign all_ctx_busy_o       = ~any_ctx_free;

  assign osc_slow_en_async_o  = start_latched_q;
  assign osc_fast_en_async_o  = stop_latched_q | osc_keep_alive_i;
  assign pd_enable_async_o    = start_latched_q & stop_latched_q;

endmodule

`default_nettype wire
