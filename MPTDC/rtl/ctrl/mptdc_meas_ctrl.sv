`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC v2.2 — Design Review Enhanced Vernier TDC
// File     : mptdc_meas_ctrl.sv
// Purpose  : Fast-domain measurement controller — close detection, capture,
//            oscillator stop, clear, and re-arm.  Runs at ~1 GHz (fast_phase[0]).
// Author   : Karim Sabra
// =============================================================================
// v2.4 changes (first-hit mode removal):
//   - Removed first_hit_mode_i port — single multi-hit operating mode.
//   - max_hits=1 uses the fast OR-reduction close path (close_fast) for
//     minimum-latency single-hit operation.
//   - max_hits>1 uses a deeply pipelined hierarchical count close
//     (close_counted).  The extra latency is intentional: it avoids forcing the
//     PD matrix to drive a 64-bit population-count tree in one ~900 ps cycle.
//   - closed_by_fast_maxhit flag replaces closed_by_firsthit.
//
// v2.2 changes:
//   - FSM: IDLE → MEASURE → SNAPSHOT → CAPTURE → STOP_OSC → CLEAR → IDLE
//     STOP_OSC deasserts osc_keep_alive BEFORE pd_clear to eliminate the
//     async-clear-while-clock-running race on PD cells.
//   - Close detection split:
//     max_hits=1: pure OR-reduction (~0.3-0.6 ns at 180nm, fits 900 ps)
//     max_hits>1: 2-stage pipelined hierarchical saturating count
//       Stage 1: 8 row popcounts (8 bits each → 4-bit partial) + tree → registered
//       Stage 2: compare registered count against max_hits_cfg → close_counted
//     This adds 1 fast-cycle latency to counted close (deadtime ~4.5 ns).
//   - Overflow flag removed (was misused as hit-saturation).
//   - pd_gate_o: gates PD enable off immediately on fast close to
//     limit hit accumulation in single-hit mode.
// =============================================================================
module mptdc_meas_ctrl
  import mptdc_pkg::*;
(
  input  wire                   clk_fast,        // fast_phase[0], ~1 GHz
  input  wire                   rst_n,

  // Frontend status
  input  wire                   meas_active_i,   // start_latched & stop_latched

  // PD hit status (combinational from PD cells)
  input  wire [PD_N-1:0]        hit_level_i,

  // Configuration (quasi-static from CSR — latched before measurement)
  input  wire [MAX_HITS_W-1:0]  max_hits_cfg_i,
  input  wire [15:0]            wdt_timeout_i,   // 0 = disabled

  // Context bank control
  output logic                  snapshot_en_o,   // 1 cycle: freeze context-bank holding regs
  output logic                  capture_en_o,    // 1 cycle: commit frozen snapshot/drain

  // Frontend / PD control
  output logic                  fe_clear_o,      // 1 cycle: clear start/stop latches
  output logic                  pd_clear_o,      // 1 cycle: clear PD cells
  output logic                  pd_gate_o,       // v2.2: gates PD enable (0 = freeze)

  // Oscillator keep-alive (to osc_fast_en logic)
  output logic                  osc_keep_alive_o,

  // Close information (frozen into context bank holding regs on snapshot_en)
  output tdc_conv_flags_t       close_flags_o,
  output logic [MAX_HITS_W-1:0] hit_count_o,

  // Debug / status
  output meas_state_e           state_o
);

  // =========================================================================
  // State register (3-bit for 8 states)
  // =========================================================================
  meas_state_e state_q, state_d;

  // =========================================================================
  // Hit count — split close paths for 180nm timing closure
  // =========================================================================

  // ── OR-reduction: single-hit fast-close path ──
  logic any_hit;
  assign any_hit = |hit_level_i;

  // ── MULTI_HIT: physically-safe pipelined hierarchical saturating count ──
  // Stage 0: register the cumulative PD hit bitmap.
  // Stage 1: 8 row popcounts (8 bits each) → registered.
  // Stage 2: 4 pair sums → registered.
  // Stage 3: final total → registered hit count.
  logic [PD_N-1:0] hit_seen_q;
  logic [PD_N-1:0] hit_seen_next;
  logic [3:0] row_cnt_comb [0:NE-1];  // 8 partial sums (max 8 each → 4 bits)
  logic [3:0] row_cnt_q    [0:NE-1];
  logic [4:0] pair_cnt_q   [0:3];
  logic [6:0] total_cnt_comb;         // 7-bit sum (max 64)
  logic [MAX_HITS_W-1:0] hit_cnt_q;   // registered, saturated at MAX_HITS

  assign hit_seen_next = hit_seen_q | hit_level_i;

  // Row popcounts (each row is 8 bits -> 4-bit result)
  always_comb begin
    for (int r = 0; r < NE; r++) begin
      automatic int unsigned rsum = 0;
      for (int c = 0; c < NE; c++)
        rsum += {31'd0, hit_seen_q[r * NE + c]};
      row_cnt_comb[r] = rsum[3:0];
    end
  end

  always_comb begin
    total_cnt_comb = {2'b0, pair_cnt_q[0]} + {2'b0, pair_cnt_q[1]}
                   + {2'b0, pair_cnt_q[2]} + {2'b0, pair_cnt_q[3]};
  end

  // Pipeline registers.  Counted close is delayed by several fast cycles, but
  // every stage now has a small, local amount of logic suitable for XH018.
  always_ff @(posedge clk_fast or negedge rst_n) begin
    if (!rst_n) begin
      hit_seen_q <= '0;
      for (int r = 0; r < NE; r++)
        row_cnt_q[r] <= '0;
      for (int p = 0; p < 4; p++)
        pair_cnt_q[p] <= '0;
      hit_cnt_q <= '0;
    end else begin
      for (int r = 0; r < NE; r++)
        row_cnt_q[r] <= row_cnt_comb[r];
      pair_cnt_q[0] <= {1'b0, row_cnt_q[0]} + {1'b0, row_cnt_q[1]};
      pair_cnt_q[1] <= {1'b0, row_cnt_q[2]} + {1'b0, row_cnt_q[3]};
      pair_cnt_q[2] <= {1'b0, row_cnt_q[4]} + {1'b0, row_cnt_q[5]};
      pair_cnt_q[3] <= {1'b0, row_cnt_q[6]} + {1'b0, row_cnt_q[7]};
      hit_cnt_q <= (total_cnt_comb > 7'(MAX_HITS)) ? MAX_HITS_W'(MAX_HITS)
                                                     : total_cnt_comb[MAX_HITS_W-1:0];

      if (state_q == ST_M_IDLE) begin
        hit_seen_q <= '0;
      end else if (state_q == ST_M_MEASURE) begin
        hit_seen_q <= hit_seen_next;
      end
    end
  end

  // Context snapshot timing control. snapshot_en_o freezes wide data into
  // holding registers; capture_en_o commits the frozen image one fast cycle
  // later and marks the context drainable.
  logic snapshot_en_q, capture_en_q;

  always_ff @(posedge clk_fast or negedge rst_n) begin
    if (!rst_n) begin
      snapshot_en_q <= 1'b0;
      capture_en_q  <= 1'b0;
    end else begin
      snapshot_en_q <= (state_d == ST_M_SNAPSHOT);
      capture_en_q <= (state_d == ST_M_CAPTURE);
    end
  end

  // Snapshot hit count: single-hit fast close intentionally exports one hit;
  // counted mode uses the registered pipeline value.
  assign hit_count_o = flags_q.closed_by_fast_maxhit ? MAX_HITS_W'(1) : hit_cnt_q;

  // =========================================================================
  // Close conditions (v2.4: unified — no first_hit_mode_i)
  //   close_fast:    max_hits==1  -> OR-reduction, zero-cycle
  //   close_counted: max_hits>1   -> deeply pipelined comparator
  // =========================================================================
  logic close_fast, close_counted, close_wd, close_any;

  // Fast single-hit close: OR-reduction — zero-cycle combinational
  assign close_fast = (max_hits_cfg_i == MAX_HITS_W'(1)) && any_hit;

  // Counted close: pipelined — compares against REGISTERED count (1-cycle lag)
  assign close_counted = (max_hits_cfg_i > MAX_HITS_W'(1))
                       && (hit_cnt_q >= max_hits_cfg_i);

  // ── Watchdog counter ────────────────────────────────────────────
  logic [15:0] wdt_cnt_q;

  always_ff @(posedge clk_fast or negedge rst_n) begin
    if (!rst_n)
      wdt_cnt_q <= '0;
    else if (state_q == ST_M_IDLE)
      wdt_cnt_q <= '0;
    else if (state_q == ST_M_MEASURE && wdt_timeout_i != '0)
      wdt_cnt_q <= wdt_cnt_q + 16'd1;
  end

  assign close_wd = (wdt_timeout_i != '0) && (wdt_cnt_q >= wdt_timeout_i);

  // Close fires ONLY in MEASURE state
  assign close_any = (state_q == ST_M_MEASURE)
                   && (close_fast | close_counted | close_wd);

  // =========================================================================
  // Flags — latched on MEASURE → CAPTURE transition
  // =========================================================================
  tdc_conv_flags_t flags_q, flags_d;

  always_comb begin
    flags_d = flags_q;
    if (state_q == ST_M_MEASURE && close_any) begin
      flags_d.reserved              = 1'b0;
      flags_d.closed_by_fast_maxhit = close_fast;
      flags_d.closed_by_maxhits     = close_counted & ~close_fast;
      flags_d.closed_by_watchdog    = close_wd;
    end
  end

  // =========================================================================
  // PD gate — controls when PD cells can detect hits.
  // Starts LOW (IDLE): prevents hits during rst_fast_n warmup when
  // counters are held in reset and CDC pipeline hasn't settled.
  // Goes HIGH on IDLE→MEASURE: counters are operational, hits are valid.
  // Goes LOW on fast close: freezes PD matrix in single-hit mode.
  // Goes LOW outside MEASURE: prevents spurious hits during CAPTURE/CLEAR.
  // =========================================================================
  logic pd_gate_q;

  always_ff @(posedge clk_fast or negedge rst_n) begin
    if (!rst_n)
      pd_gate_q <= 1'b0;
    else
      pd_gate_q <= (state_d == ST_M_MEASURE);
  end

  // =========================================================================
  // Next-state logic
  // =========================================================================
  always_comb begin
    state_d = state_q;
    case (state_q)
      ST_M_IDLE:      if (meas_active_i) state_d = ST_M_MEASURE;
      ST_M_MEASURE:   if (close_any)     state_d = ST_M_SNAPSHOT;
      ST_M_SNAPSHOT:                     state_d = ST_M_CAPTURE;
      ST_M_CAPTURE:                      state_d = ST_M_STOP_OSC;
      ST_M_STOP_OSC:                     state_d = ST_M_CLEAR;
      ST_M_CLEAR:                        state_d = ST_M_IDLE;
      default:                           state_d = ST_M_IDLE;
    endcase
  end

  // =========================================================================
  // State & flags register
  // =========================================================================
  always_ff @(posedge clk_fast or negedge rst_n) begin
    if (!rst_n) begin
      state_q <= ST_M_IDLE;
      flags_q <= '0;
    end else begin
      state_q <= state_d;
      if (state_d == ST_M_IDLE)
        flags_q <= '0;
      else
        flags_q <= flags_d;
    end
  end

  // =========================================================================
  // Output decode
  // osc_keep_alive: high in ALL active states — FSM needs its own clock.
  // STOP_OSC: fe_clear → clears start/stop latches → slow osc stops → slow
  //           phases become static.  Fast osc stays via osc_keep_alive.
  // CLEAR:    pd_clear + counter async_clr.  Safe because slow phases are
  //           now static (stopped in STOP_OSC), so no PD sampling race.
  // =========================================================================
  assign snapshot_en_o    = snapshot_en_q;
  assign capture_en_o     = capture_en_q;
  assign osc_keep_alive_o = (state_q != ST_M_IDLE);
  assign fe_clear_o       = (state_q == ST_M_STOP_OSC);
  assign pd_clear_o       = (state_q == ST_M_CLEAR);
  assign pd_gate_o        = pd_gate_q;
  assign close_flags_o    = flags_q;
  assign state_o          = state_q;

endmodule

`default_nettype wire
