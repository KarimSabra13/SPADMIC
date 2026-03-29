`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC v2.2 — Design Review Enhanced Vernier TDC
// File     : mptdc_meas_ctrl.sv
// Purpose  : Fast-domain measurement controller — close detection, capture,
//            oscillator stop, clear, and re-arm.  Runs at ~1 GHz (fast_phase[0]).
// Author   : Karim Sabra
// =============================================================================
// v2.2 changes:
//   - 5-state FSM: IDLE → MEASURE → CAPTURE → STOP_OSC → CLEAR → IDLE
//     STOP_OSC deasserts osc_keep_alive BEFORE pd_clear to eliminate the
//     async-clear-while-clock-running race on PD cells.
//   - Close detection split:
//     FIRST_HIT: pure OR-reduction (~0.3-0.6 ns at 180nm, fits 900 ps)
//     MULTI_HIT: 2-stage pipelined hierarchical saturating count
//       Stage 1: 9 row popcounts (9 bits each → 4-bit partial) + tree → registered
//       Stage 2: compare registered count against max_hits_cfg → close_mh
//     This adds 1 fast-cycle latency to MULTI_HIT close (deadtime ~4.5 ns).
//   - Overflow flag removed (was misused as hit-saturation).
//   - pd_gate_o: gates PD enable off immediately on first-hit close to
//     limit hit accumulation in FIRST_HIT mode.
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
  input  wire                   first_hit_mode_i,
  input  wire [15:0]            wdt_timeout_i,   // 0 = disabled

  // Context bank control
  output logic                  capture_en_o,    // 1 cycle: snapshot

  // Frontend / PD control
  output logic                  fe_clear_o,      // 1 cycle: clear start/stop latches
  output logic                  pd_clear_o,      // 1 cycle: clear PD cells
  output logic                  pd_gate_o,       // v2.2: gates PD enable (0 = freeze)

  // Oscillator keep-alive (to osc_fast_en logic)
  output logic                  osc_keep_alive_o,

  // Close information (captured into context bank on capture_en)
  output tdc_conv_flags_t       close_flags_o,
  output logic [MAX_HITS_W-1:0] hit_count_o,

  // Debug / status
  output meas_state_e           state_o
);

  // =========================================================================
  // State register (3-bit for 5 states)
  // =========================================================================
  meas_state_e state_q, state_d;

  // =========================================================================
  // Hit count — split close paths for 180nm timing closure
  // =========================================================================

  // ── FIRST_HIT: pure OR-reduction (~0.3-0.6 ns) ──
  logic any_hit;
  assign any_hit = |hit_level_i;

  // ── MULTI_HIT: 2-stage pipelined hierarchical saturating count ──
  // Stage 1: 9 row popcounts (9 bits each) → balanced tree → registered
  logic [3:0] row_cnt [0:NE-1];      // 9 partial sums (max 9 each → 4 bits)
  logic [6:0] total_cnt_comb;         // 7-bit sum (max 81)
  logic [MAX_HITS_W-1:0] hit_cnt_q;  // registered, saturated at MAX_HITS

  // Row popcounts (each row is 9 bits → 4-bit result)
  always_comb begin
    for (int r = 0; r < NE; r++) begin
      automatic int unsigned rsum = 0;
      for (int c = 0; c < NE; c++)
        rsum += {31'd0, hit_level_i[r * NE + c]};
      row_cnt[r] = rsum[3:0];
    end
  end

  // Balanced 3-level adder tree: 9 → 5 → 3 → 1
  logic [4:0] l1_a, l1_b, l1_c, l1_d;  // level 1: pairs → 5-bit
  logic [4:0] l1_e;                      // level 1: leftover
  logic [5:0] l2_a, l2_b;               // level 2: pairs → 6-bit
  logic [5:0] l2_c;                      // level 2: leftover
  logic [6:0] l3;                        // level 3: final → 7-bit

  always_comb begin
    // Level 1: 9 → 5 values (4 pairs + 1 leftover)
    l1_a = {1'b0, row_cnt[0]} + {1'b0, row_cnt[1]};
    l1_b = {1'b0, row_cnt[2]} + {1'b0, row_cnt[3]};
    l1_c = {1'b0, row_cnt[4]} + {1'b0, row_cnt[5]};
    l1_d = {1'b0, row_cnt[6]} + {1'b0, row_cnt[7]};
    l1_e = {1'b0, row_cnt[8]};

    // Level 2: 5 → 3 values (2 pairs + 1 leftover)
    l2_a = {1'b0, l1_a} + {1'b0, l1_b};
    l2_b = {1'b0, l1_c} + {1'b0, l1_d};
    l2_c = {1'b0, l1_e};

    // Level 3: 3 → 1 value
    l3 = {1'b0, l2_a} + {1'b0, l2_b} + {1'b0, l2_c};

    // Saturate at MAX_HITS for combinational output
    total_cnt_comb = l3;
  end

  // Pipeline register: sample the tree result every fast cycle in MEASURE
  always_ff @(posedge clk_fast or negedge rst_n) begin
    if (!rst_n)
      hit_cnt_q <= '0;
    else if (state_q == ST_M_IDLE)
      hit_cnt_q <= '0;
    else if (state_q == ST_M_MEASURE)
      hit_cnt_q <= (total_cnt_comb > 7'(MAX_HITS)) ? MAX_HITS_W'(MAX_HITS)
                                                     : total_cnt_comb[MAX_HITS_W-1:0];
  end

  // Snapshot hit count: use the registered pipeline value
  // (available 1 cycle after the hits appear — close_mh acts on this)
  assign hit_count_o = hit_cnt_q;

  // =========================================================================
  // Close conditions
  // =========================================================================
  logic close_fh, close_mh, close_wd, close_any;

  // FIRST_HIT: OR-reduction — zero-cycle combinational, fits 900 ps at 180nm
  assign close_fh = first_hit_mode_i && any_hit;

  // MULTI_HIT: pipelined — compares against REGISTERED count (1-cycle lag)
  assign close_mh = !first_hit_mode_i
                  && (max_hits_cfg_i != '0)
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
                   && (close_fh | close_mh | close_wd);

  // =========================================================================
  // Flags — latched on MEASURE → CAPTURE transition
  // =========================================================================
  tdc_conv_flags_t flags_q, flags_d;

  always_comb begin
    flags_d = flags_q;
    if (state_q == ST_M_MEASURE && close_any) begin
      flags_d.reserved           = 1'b0;
      flags_d.closed_by_firsthit = close_fh;
      flags_d.closed_by_maxhits  = close_mh & ~close_fh;
      flags_d.closed_by_watchdog = close_wd;
    end
  end

  // =========================================================================
  // PD gate — controls when PD cells can detect hits.
  // Starts LOW (IDLE): prevents hits during rst_fast_n warmup when
  // counters are held in reset and CDC pipeline hasn't settled.
  // Goes HIGH on IDLE→MEASURE: counters are operational, hits are valid.
  // Goes LOW on first-hit close: freezes PD matrix in FIRST_HIT mode.
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
  // Next-state logic (5-state FSM)
  // =========================================================================
  always_comb begin
    state_d = state_q;
    case (state_q)
      ST_M_IDLE:     if (meas_active_i) state_d = ST_M_MEASURE;
      ST_M_MEASURE:  if (close_any)     state_d = ST_M_CAPTURE;
      ST_M_CAPTURE:                     state_d = ST_M_STOP_OSC;
      ST_M_STOP_OSC:                    state_d = ST_M_CLEAR;
      ST_M_CLEAR:                       state_d = ST_M_IDLE;
      default:                          state_d = ST_M_IDLE;
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
  assign capture_en_o     = (state_q == ST_M_CAPTURE);
  assign osc_keep_alive_o = (state_q != ST_M_IDLE);
  assign fe_clear_o       = (state_q == ST_M_STOP_OSC);
  assign pd_clear_o       = (state_q == ST_M_CLEAR);
  assign pd_gate_o        = pd_gate_q;
  assign close_flags_o    = flags_q;
  assign state_o          = state_q;

endmodule

`default_nettype wire
