`timescale 1ns/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC v2.0 — Raw-Output Vernier TDC with Triple-Buffer
// File     : mptdc_ctrl_fsm_v2.sv
// Purpose  : Control FSM — conversion lifecycle with async capture awareness
// Author   : Karim Sabra
// =============================================================================
// In the v2.0 architecture, capture happens ASYNCHRONOUSLY on STOP:
//   - fe_capture_done_async fires at the instant STOP is detected
//   - Context bank snapshots on the next fast clock edge
//   - Writer starts draining immediately in the fast domain
//
// The FSM's role is simplified to:
//   1. Arm and track START/STOP events (synced to sys clock)
//   2. Assert fe_clear to release frontend for re-arm
//   3. Wait for writer completion
//   4. Track early-closure conditions (first_hit, max_hits, watchdog)
//
// States:
//   ST_IDLE       — waiting for arm + start
//   ST_ACTIVE     — oscillators running, capture in progress
//   ST_DRAIN_WAIT — frontend cleared, waiting for writer to finish
//
// Early closure (first_hit / max_hits / watchdog) requires FSM-driven
// capture since there's no STOP event. The FSM fires capture_pulse_o
// which gets CDC'd while oscillators are still running.
// =============================================================================
module mptdc_ctrl_fsm_v2
  import mptdc_pkg::*;
(
  // Clock / reset
  input  wire                   clk_sys,
  input  wire                   rst_n,

  // Arm / trigger interface (all synchronous to clk_sys)
  input  wire                   conv_arm_i,
  input  wire                   start_seen_sync_i,
  input  wire                   stop_seen_sync_i,

  // Writer feedback (synchronous to clk_sys)
  input  wire                   writer_done_sync_i,

  // Fast-domain status (synchronised to clk_sys)
  input  wire [MAX_HITS_W-1:0]  hit_count_sync_i,
  input  wire [NFAST_W-1:0]     nfast_cnt_sync_i,

  // Configuration
  input  wire mode_e            mode_cfg_i,
  input  wire [MAX_HITS_W-1:0]  max_hits_cfg_i,

  // Context / watchdog
  input  wire                   all_ctx_busy_i,
  input  wire                   wdt_force_close_i,

  // Status outputs
  output logic                  ready_o,
  output logic                  busy_o,

  // Oscillator / PD control (unused — frontend drives oscillators)
  output logic                  osc_slow_en_o,
  output logic                  osc_fast_en_o,
  output logic                  pd_enable_o,

  // Snapshot / clear / done
  output logic                  capture_pulse_o,
  output logic                  fe_clear_o,
  output logic                  conv_done_o,

  // Flags and debug
  output tdc_conv_flags_t       flags_o,
  output fsm_state_e            state_o
);

  // -------------------------------------------------------------------------
  // Internal signals
  // -------------------------------------------------------------------------
  fsm_state_e            state_q, state_d;
  logic                  armed_q, armed_d;
  tdc_conv_flags_t       flags_q, flags_d;

  // Early closure conditions (checked during ST_ACTIVE)
  logic close_firsthit;
  logic close_maxhits;
  logic close_watchdog;
  logic close_early;

  assign close_firsthit = (mode_cfg_i == MODE_FIRST_HIT) &&
                           (hit_count_sync_i >= MAX_HITS_W'(1));
  assign close_maxhits  = (hit_count_sync_i >= max_hits_cfg_i) &&
                           (max_hits_cfg_i != '0);
  assign close_watchdog = wdt_force_close_i;
  assign close_early = close_firsthit | close_maxhits | close_watchdog;

  // -------------------------------------------------------------------------
  // FSM — next-state logic
  // -------------------------------------------------------------------------
  always_comb begin : fsm_nxt
    state_d   = state_q;
    armed_d   = armed_q;
    flags_d   = flags_q;

    case (state_q)
      // -------------------------------------------------------------------
      ST_IDLE: begin
        flags_d = '0;
        if (conv_arm_i && !all_ctx_busy_i)
          armed_d = 1'b1;
        if (armed_q && start_seen_sync_i) begin
          armed_d = 1'b0;
          state_d = ST_ACTIVE;
        end
      end

      // -------------------------------------------------------------------
      // ST_ACTIVE: Oscillators running, PD accumulating hits.
      // Normal path: wait for stop_seen_sync (capture already happened async)
      // Early close: first_hit / max_hits / watchdog
      // -------------------------------------------------------------------
      ST_ACTIVE: begin
        if (stop_seen_sync_i) begin
          // Normal closure — capture already happened in async domain
          state_d = ST_DRAIN_WAIT;
        end else if (close_early) begin
          // Early closure — FSM triggers capture via capture_pulse_o
          flags_d.closed_by_firsthit = close_firsthit;
          flags_d.closed_by_maxhits  = close_maxhits & ~close_firsthit;
          flags_d.closed_by_watchdog = close_watchdog;
          flags_d.overflow = (hit_count_sync_i >= MAX_HITS_W'(MAX_HITS));
          state_d = ST_DRAIN_WAIT;
        end
      end

      // -------------------------------------------------------------------
      // ST_DRAIN_WAIT: Frontend cleared (re-arming), writer draining.
      // Wait for writer_done to return to IDLE.
      // -------------------------------------------------------------------
      ST_DRAIN_WAIT: begin
        if (writer_done_sync_i)
          state_d = ST_IDLE;
      end

      default: state_d = ST_IDLE;
    endcase
  end

  // -------------------------------------------------------------------------
  // FSM — state register
  // -------------------------------------------------------------------------
  always_ff @(posedge clk_sys or negedge rst_n) begin : fsm_seq
    if (!rst_n) begin
      state_q   <= ST_IDLE;
      armed_q   <= 1'b0;
      flags_q   <= '0;
    end else begin
      state_q   <= state_d;
      armed_q   <= armed_d;
      flags_q   <= flags_d;
    end
  end

  // -------------------------------------------------------------------------
  // Output decode
  // -------------------------------------------------------------------------
  assign ready_o = (state_q == ST_IDLE) && !armed_q;
  assign busy_o  = (state_q != ST_IDLE);

  // Oscillator/PD enables — unused, frontend drives these directly
  assign osc_slow_en_o = 1'b0;
  assign osc_fast_en_o = 1'b0;
  assign pd_enable_o   = 1'b0;

  // capture_pulse: only for FSM-driven early closure (not normal STOP path)
  assign capture_pulse_o = (state_q == ST_ACTIVE) && close_early;

  // fe_clear: assert throughout DRAIN_WAIT so frontend re-arms
  assign fe_clear_o = (state_q == ST_DRAIN_WAIT);

  // conv_done: single-cycle pulse on DRAIN_WAIT → IDLE transition
  assign conv_done_o = (state_q == ST_DRAIN_WAIT) && (state_d == ST_IDLE);

  // Flags and debug state
  assign flags_o = flags_q;
  assign state_o = state_q;

endmodule

`default_nettype wire
