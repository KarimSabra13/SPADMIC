// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// mptdc_core.sv — Reusable TDC core: all measurement, CDC, and readout logic
//
// Instantiates and wires: frontend, oscillators, PD matrix, boundary repair,
// context bank, FSM, writer, watchdog, gray-code CDC, pulse syncs, async FIFO,
// and the 16-bit narrow serializer.
//
// Clock domains:
//   clk_sys        — 160 MHz system clock (FSM, watchdog, FIFO read, narrow TX)
//   osc_fast_ph0   — fast oscillator tap 0 (context bank, writer, FIFO write)
//   async          — frontend latches, stop capture, PD cells

`timescale 1ns / 1ps
`default_nettype none

module mptdc_core
  import mptdc_pkg::*;
(
  input  wire                   clk_sys,
  input  wire                   rst_sys_n,

  // Async START/STOP from input mux
  input  wire                   start_async_i,
  input  wire                   stop_async_i,

  // Configuration from CSR
  input  mptdc_cfg_t            cfg_i,
  input  wire                   conv_arm_i,
  input  wire                   fifo_clr_i,

  // Status to CSR
  output mptdc_status_t         status_o,

  // 16-bit output
  input  wire                   narrow_ready_i,
  output wire                   narrow_valid_o,
  output wire [NARROW_W-1:0]   narrow_data_o
);

  // =========================================================================
  //  Internal wires — oscillators
  // =========================================================================
  wire [NE-1:0] slow_phase, fast_phase;
  wire           slow_phase0_guard, slow_phase7d_probe;
  wire           osc_fast_ph0 = fast_phase[0];

  // =========================================================================
  //  Internal wires — frontend
  // =========================================================================
  wire           fe_start_latched, fe_stop_latched;
  wire           fe_osc_slow_en, fe_osc_fast_en, fe_pd_enable;
  ctx_id_t       fe_active_ctx;
  ctx_state_e    fe_ctx_state [N_CTX];
  wire           fe_all_ctx_busy;
  wire           fe_capture_done_async;

  // =========================================================================
  //  Internal wires — boundary repair
  // =========================================================================
  wire           phase0_snap, phase7d_snap, slow_boundary_inc;

  // =========================================================================
  //  Internal wires — PD matrix
  // =========================================================================
  wire [PD_N-1:0]          pd_hit_level;
  wire [PD_N*NFAST_W-1:0]  pd_nfast_hit_packed;

  // =========================================================================
  //  Internal wires — gray counter CDC
  // =========================================================================
  wire [NSLOW_W-1:0] nslow_src_count, nslow_sys_continuous;
  wire [NFAST_W-1:0] nfast_src_count, nfast_sys_continuous;

  // =========================================================================
  //  Internal wires — FSM
  // =========================================================================
  wire           fsm_ready, fsm_busy;
  wire           fsm_capture_pulse, fsm_fe_clear, fsm_conv_done;
  tdc_conv_flags_t fsm_flags;
  fsm_state_e    fsm_state;

  // =========================================================================
  //  Internal wires — CDC pulses
  // =========================================================================
  wire           start_seen_sync, stop_seen_sync;
  wire           writer_done_sync;
  wire           fe_clear_fast;        // fe_clear in fast domain
  wire           capture_pulse_fast;   // capture_pulse in fast domain
  wire           drain_start_fast;     // drain trigger in fast domain

  // =========================================================================
  //  Internal wires — writer
  // =========================================================================
  wire           writer_fifo_wr_en;
  mptdc_acq_rec_t writer_fifo_wr_data;
  wire           writer_done;
  wire           writer_ctx_release;
  wire           writer_scan_active;
  ctx_id_t       writer_drain_ctx;

  // =========================================================================
  //  Internal wires — context bank
  // =========================================================================
  mptdc_ctx_snapshot_t ctx_snapshot;

  // =========================================================================
  //  Internal wires — FIFO
  // =========================================================================
  wire           fifo_wr_full;
  wire           fifo_rd_empty;
  wire [ACQ_REC_W-1:0] fifo_rd_data_raw;
  wire [$clog2(FIFO_DEPTH+1)-1:0] fifo_rd_level;
  wire           fifo_rd_en;

  // =========================================================================
  //  Internal wires — narrow TX
  // =========================================================================
  // (outputs go to module ports)

  // =========================================================================
  //  Internal wires — watchdog
  // =========================================================================
  wire           wdt_force_close, wdt_force_reset;
  wire [7:0]     wdt_ctx_trip_cnt, wdt_global_trip_cnt;

  // =========================================================================
  //  Conversion / overflow counters (sys domain)
  // =========================================================================
  logic [31:0]   conv_count_r;
  logic [15:0]   ovf_count_r;
  logic [MAX_HITS_W-1:0] last_hit_count_r;
  tdc_conv_flags_t       last_flags_r;

  // =========================================================================
  //  Hit count — popcount of pd_hit_level (combinational, fast domain)
  //  Saturates at MAX_HITS to avoid 4-bit overflow (81 cells > 15)
  // =========================================================================
  logic [MAX_HITS_W-1:0] hit_count_live;
  always_comb begin
    automatic int cnt = 0;
    for (int i = 0; i < PD_N; i++) cnt += pd_hit_level[i];
    hit_count_live = (cnt > MAX_HITS) ? MAX_HITS_W'(MAX_HITS) : cnt[MAX_HITS_W-1:0];
  end

  // =========================================================================
  //  Context release vector — convert scalar writer release to per-ctx
  // =========================================================================
  logic [N_CTX-1:0] ctx_release_vec;
  always_comb begin
    ctx_release_vec = '0;
    if (writer_ctx_release)
      ctx_release_vec[writer_drain_ctx] = 1'b1;
  end

  // =========================================================================
  //  Context state packing for status register
  // =========================================================================
  logic [N_CTX*2-1:0] ctx_state_packed;
  always_comb begin
    for (int i = 0; i < N_CTX; i++)
      ctx_state_packed[i*2 +: 2] = fe_ctx_state[i];
  end

  // ========================================================================
  //  Instantiations
  // ========================================================================

  // ── Frontend ────────────────────────────────────────────────────
  // When the watchdog forces an early close, inject a synthetic STOP
  // into the frontend so it follows the normal STOP path: the active
  // context transitions CAPTURING → DRAINING, oscillators remain
  // enabled (gated by ctx_drain_q), and capture_done_async fires to
  // trigger the existing capture → writer → packet pipeline.
  wire wdt_synth_stop = fsm_capture_pulse;

  mptdc_async_frontend_v2 u_frontend (
    .rst_n                (rst_sys_n),
    .start_async_i        (start_async_i),
    .stop_async_i         (stop_async_i | wdt_synth_stop),
    .fe_clear_async_i     (fe_clear_fast),
    .ctx_release_async_i  (ctx_release_vec),
    .start_latched_o      (fe_start_latched),
    .stop_latched_o       (fe_stop_latched),
    .osc_slow_en_async_o  (fe_osc_slow_en),
    .osc_fast_en_async_o  (fe_osc_fast_en),
    .pd_enable_async_o    (fe_pd_enable),
    .active_ctx_o         (fe_active_ctx),
    .ctx_state_o          (fe_ctx_state),
    .all_ctx_busy_o       (fe_all_ctx_busy),
    .capture_done_async_o (fe_capture_done_async)
  );

  // ── Slow oscillator ────────────────────────────────────────────
  mptdc_osc_wrapper #(.NE(NE), .TS_STEP_PS(OSC_TS_SLOW_PS)) u_osc_slow (
    .en              (fe_osc_slow_en),
    .rst_n           (rst_sys_n),
    .trim_i          (1'b0),
    .phase           (slow_phase),
    .phase0_guard_o  (slow_phase0_guard),
    .phase7d_probe_o (slow_phase7d_probe)
  );

  // ── Fast oscillator ────────────────────────────────────────────
  // Keep the fast oscillator alive while the writer is scanning so it
  // can complete and assert writer_done before the clock is gated.
  wire osc_fast_en = fe_osc_fast_en | writer_scan_active;

  mptdc_osc_wrapper #(.NE(NE), .TS_STEP_PS(OSC_TS_FAST_PS)) u_osc_fast (
    .en              (osc_fast_en),
    .rst_n           (rst_sys_n),
    .trim_i          (1'b0),
    .phase           (fast_phase),
    .phase0_guard_o  (/* unused */),
    .phase7d_probe_o (/* unused */)
  );

  // ── PD matrix clear ─────────────────────────────────────────────
  // The PD cells must NOT be cleared until the context bank has captured
  // their state. fe_clear fires in the sys domain (FSM → DRAIN_WAIT)
  // which can race with the fast-domain capture_pulse_fast.
  // Fix: clear PD cells 1 fast clock cycle AFTER capture completes.
  logic pd_clear_fast_r;
  always_ff @(posedge osc_fast_ph0 or negedge rst_sys_n) begin
    if (!rst_sys_n) pd_clear_fast_r <= 1'b0;
    else            pd_clear_fast_r <= capture_pulse_fast;
  end

  // ── Phase Detector Matrix (81 cells) ───────────────────────────
  for (genvar ns = 0; ns < NE; ns++) begin : gen_pd_row
    for (genvar nf = 0; nf < NE; nf++) begin : gen_pd_col
      localparam int unsigned CELL = ns * NE + nf;
      mptdc_pd_cell #(.SAMPLE_DEPTH(2)) u_pd (
        .rst_n        (rst_sys_n),
        .clear_window (pd_clear_fast_r),
        .slow_phase   (slow_phase[ns]),
        .fast_phase   (fast_phase[nf]),
        .nfast_count  (nfast_src_count),
        .hit_level    (pd_hit_level[CELL]),
        .nfast_hit    (pd_nfast_hit_packed[CELL*NFAST_W +: NFAST_W])
      );
    end
  end

  // ── Boundary repair (stop capture) ─────────────────────────────
  mptdc_stop_capture_async u_stop_capture (
    .rst_n                (rst_sys_n),
    .async_clr_i          (pd_clear_fast_r),
    .stop_async_i         (stop_async_i),
    .slow_phase0_i        (slow_phase[0]),
    .slow_phase0_guard_i  (slow_phase0_guard),
    .slow_phase7d_probe_i (slow_phase7d_probe),
    .phase0_snap_o        (phase0_snap),
    .phase7d_snap_o       (phase7d_snap),
    .slow_boundary_inc_o  (slow_boundary_inc)
  );

  // ── Gray counter CDC: slow counter ─────────────────────────────
  mptdc_gray_cnt_sync #(.W(NSLOW_W)) u_slow_cnt (
    .src_clk              (slow_phase[0]),
    .src_rst_n            (rst_sys_n),
    .src_async_clr        (pd_clear_fast_r),
    .src_en               (1'b1),
    .src_clr              (1'b0),
    .src_latch_p          (1'b0),
    .src_count            (nslow_src_count),
    .dst_clk              (clk_sys),
    .dst_rst_n            (rst_sys_n),
    .dst_latch_p          (1'b0),
    .dst_count_continuous (nslow_sys_continuous),
    .dst_count_latched    (/* unused */)
  );

  // ── Gray counter CDC: fast counter ─────────────────────────────
  mptdc_gray_cnt_sync #(.W(NFAST_W)) u_fast_cnt (
    .src_clk              (osc_fast_ph0),
    .src_rst_n            (rst_sys_n),
    .src_async_clr        (pd_clear_fast_r),
    .src_en               (1'b1),
    .src_clr              (1'b0),
    .src_latch_p          (1'b0),
    .src_count            (nfast_src_count),
    .dst_clk              (clk_sys),
    .dst_rst_n            (rst_sys_n),
    .dst_latch_p          (1'b0),
    .dst_count_continuous (nfast_sys_continuous),
    .dst_count_latched    (/* unused */)
  );

  // ── Pulse sync: start_seen (async → sys) ───────────────────────
  // We sync the level fe_start_latched to sys domain via 2-FF sync
  logic [1:0] start_sync_pipe;
  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n)
      start_sync_pipe <= '0;
    else
      start_sync_pipe <= {start_sync_pipe[0], fe_start_latched};
  end
  // Rising-edge detect
  assign start_seen_sync = start_sync_pipe[0] & ~start_sync_pipe[1];

  // ── Pulse sync: stop_seen (async → sys) ────────────────────────
  logic [1:0] stop_sync_pipe;
  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n)
      stop_sync_pipe <= '0;
    else
      stop_sync_pipe <= {stop_sync_pipe[0], fe_stop_latched};
  end
  assign stop_seen_sync = stop_sync_pipe[0] & ~stop_sync_pipe[1];

  // ── Pulse sync: writer_done (fast → sys) ───────────────────────
  mptdc_pulse_sync u_ps_writer_done (
    .src_clk   (osc_fast_ph0),
    .src_rst_n (rst_sys_n),
    .src_pulse (writer_done),
    .dst_clk   (clk_sys),
    .dst_rst_n (rst_sys_n),
    .dst_pulse (writer_done_sync)
  );

  // ── Pulse sync: fe_clear (sys → fast) ──────────────────────────
  // fe_clear is a level from FSM; drives frontend latches directly.
  // Since the frontend is purely async, no clock domain crossing needed.
  assign fe_clear_fast = fsm_fe_clear;

  // ── Capture trigger: use frontend's capture_done_async ─────────
  // The capture must happen while oscillators are still running.
  // fe_capture_done_async fires at the instant STOP is detected (async).
  // We register it with osc_fast_ph0 to create a clean 1-cycle pulse
  // for the context bank and writer.
  logic capture_done_sync_ff1, capture_done_sync_ff2, capture_done_pulse;
  always_ff @(posedge osc_fast_ph0 or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      capture_done_sync_ff1 <= 1'b0;
      capture_done_sync_ff2 <= 1'b0;
    end else begin
      capture_done_sync_ff1 <= fe_capture_done_async;
      capture_done_sync_ff2 <= capture_done_sync_ff1;
    end
  end
  assign capture_done_pulse = capture_done_sync_ff1 & ~capture_done_sync_ff2;
  assign capture_pulse_fast = capture_done_pulse;

  // Drain starts 1 fast cycle AFTER capture — the context bank uses
  // non-blocking assignments, so the snapshot is only readable on the
  // NEXT posedge after capture_en_i was asserted.
  logic drain_start_delayed;
  always_ff @(posedge osc_fast_ph0 or negedge rst_sys_n) begin
    if (!rst_sys_n) drain_start_delayed <= 1'b0;
    else            drain_start_delayed <= capture_done_pulse;
  end

  wire drain_request_raw = drain_start_delayed;

  // ── Drain request queue ──────────────────────────────────────────
  // The writer is single-threaded. All drain requests are enqueued,
  // and we dequeue one at a time when the writer is idle.
  localparam int DRAIN_Q_DEPTH = N_CTX;
  logic [CTX_W-1:0] drain_q_ctx [DRAIN_Q_DEPTH];
  logic [$clog2(DRAIN_Q_DEPTH+1)-1:0] drain_q_wr, drain_q_rd, drain_q_cnt;

  wire drain_q_push = drain_request_raw && !drain_immediate
                      && (drain_q_cnt < DRAIN_Q_DEPTH[$clog2(DRAIN_Q_DEPTH+1)-1:0]);

  // Track writer state: idle after reset or 1 cycle after writer_done
  logic writer_idle_ff;
  always_ff @(posedge osc_fast_ph0 or negedge rst_sys_n) begin
    if (!rst_sys_n) writer_idle_ff <= 1'b1;
    else if (drain_start_fast) writer_idle_ff <= 1'b0;
    else if (writer_done) writer_idle_ff <= 1'b1;
  end

  // Dequeue: writer is idle AND queue has entries AND no push this cycle
  // (give push priority to avoid reading stale entry)
  // Also: must wait 1 cycle after writer_done for state to settle
  logic writer_done_r;  // registered writer_done to delay 1 cycle
  always_ff @(posedge osc_fast_ph0 or negedge rst_sys_n) begin
    if (!rst_sys_n) writer_done_r <= 1'b0;
    else            writer_done_r <= writer_done;
  end

  wire drain_q_pop = writer_idle_ff && writer_done_r && (drain_q_cnt > 0);

  always_ff @(posedge osc_fast_ph0 or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      drain_q_wr  <= '0;
      drain_q_rd  <= '0;
      drain_q_cnt <= '0;
    end else begin
      case ({drain_q_push, drain_q_pop})
        2'b10: begin
          drain_q_ctx[drain_q_wr] <= drain_ctx_latch_raw;
          drain_q_wr  <= (drain_q_wr == DRAIN_Q_DEPTH[$clog2(DRAIN_Q_DEPTH+1)-1:0]-1)
                         ? '0 : drain_q_wr + 1;
          drain_q_cnt <= drain_q_cnt + 1;
        end
        2'b01: begin
          drain_q_rd  <= (drain_q_rd == DRAIN_Q_DEPTH[$clog2(DRAIN_Q_DEPTH+1)-1:0]-1)
                         ? '0 : drain_q_rd + 1;
          drain_q_cnt <= drain_q_cnt - 1;
        end
        2'b11: begin
          drain_q_ctx[drain_q_wr] <= drain_ctx_latch_raw;
          drain_q_wr  <= (drain_q_wr == DRAIN_Q_DEPTH[$clog2(DRAIN_Q_DEPTH+1)-1:0]-1)
                         ? '0 : drain_q_wr + 1;
          drain_q_rd  <= (drain_q_rd == DRAIN_Q_DEPTH[$clog2(DRAIN_Q_DEPTH+1)-1:0]-1)
                         ? '0 : drain_q_rd + 1;
          // cnt stays same
        end
        default: ;
      endcase
    end
  end

  // Issue drain_start: immediate if writer idle and queue empty, else from queue
  wire drain_immediate = drain_request_raw && writer_idle_ff && !writer_done_r && (drain_q_cnt == 0);
  assign drain_start_fast = drain_immediate | drain_q_pop;

  // ── Writer drain context: the currently active ctx at capture time ──
  // Latch the active context when capture fires (fast domain)
  logic [CTX_W-1:0] drain_ctx_latch_raw;
  always_ff @(posedge osc_fast_ph0 or negedge rst_sys_n) begin
    if (!rst_sys_n)
      drain_ctx_latch_raw <= '0;
    else if (capture_pulse_fast)
      drain_ctx_latch_raw <= fe_active_ctx;
  end

  // Select drain context: immediate uses latch, queue pop uses queue head
  logic [CTX_W-1:0] writer_drain_ctx_sel;
  always_comb begin
    if (drain_immediate)
      writer_drain_ctx_sel = drain_ctx_latch_raw;
    else if (drain_q_pop)
      writer_drain_ctx_sel = drain_q_ctx[drain_q_rd];
    else
      writer_drain_ctx_sel = drain_ctx_latch_raw;
  end
  assign writer_drain_ctx = writer_drain_ctx_sel;

  // ── Control FSM ────────────────────────────────────────────────
  mptdc_ctrl_fsm_v2 u_fsm (
    .clk_sys            (clk_sys),
    .rst_n              (rst_sys_n),
    .conv_arm_i         (conv_arm_i),
    .start_seen_sync_i  (start_seen_sync),
    .stop_seen_sync_i   (stop_seen_sync),
    .writer_done_sync_i (writer_done_sync),
    .hit_count_sync_i   (hit_count_live),  // Note: async, but FSM only samples during stable windows
    .nfast_cnt_sync_i   (nfast_sys_continuous),
    .mode_cfg_i         (cfg_i.mode_cfg),
    .max_hits_cfg_i     (cfg_i.max_hits),
    .all_ctx_busy_i     (fe_all_ctx_busy),
    .wdt_force_close_i  (wdt_force_close | wdt_force_reset),
    .ready_o            (fsm_ready),
    .busy_o             (fsm_busy),
    .osc_slow_en_o      (/* unused — frontend drives oscs */),
    .osc_fast_en_o      (/* unused */),
    .pd_enable_o        (/* unused */),
    .capture_pulse_o    (fsm_capture_pulse),
    .fe_clear_o         (fsm_fe_clear),
    .conv_done_o        (fsm_conv_done),
    .flags_o            (fsm_flags),
    .state_o            (fsm_state)
  );

  // ── Context bank ───────────────────────────────────────────────
  // Combinational flags bypass: when an early-close fires (watchdog,
  // maxhits, firsthit), the FSM sets flags_d but flags_q only updates
  // next posedge.  The synthetic STOP triggers capture in the same
  // cycle, so the context bank would sample stale flags.  Bypass the
  // registered path for the watchdog bit so it is visible at capture.
  wire wdt_any_force = wdt_force_close | wdt_force_reset;
  tdc_conv_flags_t ctx_capture_flags;
  always_comb begin
    ctx_capture_flags = fsm_flags;
    if (wdt_any_force)
      ctx_capture_flags.closed_by_watchdog = 1'b1;
  end

  mptdc_context_bank u_ctx_bank (
    .clk_fast              (osc_fast_ph0),
    .capture_ctx_i         (fe_active_ctx),
    .capture_en_i          (capture_pulse_fast),
    .pd_hit_level_i        (pd_hit_level),
    .pd_nfast_hit_packed_i (pd_nfast_hit_packed),
    .nslow_snap_i          (nslow_src_count),
    .nfast_snap_i          (nfast_src_count),
    .phase0_snap_i         (phase0_snap),
    .hit_count_i           (hit_count_live),
    .flags_i               (ctx_capture_flags),
    .read_ctx_i            (writer_drain_ctx),
    .snapshot_o            (ctx_snapshot)
  );

  // ── Writer (scan-order) ────────────────────────────────────────
  mptdc_writer_scan u_writer (
    .clk_fast       (osc_fast_ph0),
    .rst_async_n    (rst_sys_n),
    .drain_start_i  (drain_start_fast),
    .drain_ctx_i    (writer_drain_ctx),
    .snapshot_i     (ctx_snapshot),
    .fifo_full_i    (fifo_wr_full),
    .fifo_wr_en_o   (writer_fifo_wr_en),
    .fifo_wr_data_o (writer_fifo_wr_data),
    .writer_done_o  (writer_done),
    .ctx_release_o  (writer_ctx_release),
    .scan_active_o  (writer_scan_active)
  );

  // ── Watchdog ───────────────────────────────────────────────────
  mptdc_watchdog u_wdt (
    .clk_sys              (clk_sys),
    .rst_n                (rst_sys_n),
    .ctx_state_i          (fe_ctx_state),
    .conv_done_i          (fsm_conv_done),
    .wdt_ctx_timeout_i    (cfg_i.wdt_ctx_timeout),
    .wdt_global_timeout_i (cfg_i.wdt_global_timeout),
    .wdt_force_close_o    (wdt_force_close),
    .wdt_force_reset_o    (wdt_force_reset),
    .wdt_ctx_trip_cnt_o   (wdt_ctx_trip_cnt),
    .wdt_global_trip_cnt_o(wdt_global_trip_cnt)
  );

  // ── Async FIFO (fast → sys) ────────────────────────────────────
  mptdc_async_fifo #(
    .WIDTH (ACQ_REC_W),
    .DEPTH (FIFO_DEPTH)
  ) u_fifo (
    .wr_clk    (osc_fast_ph0),
    .wr_rst_n  (rst_sys_n),
    .wr_clr_i  (1'b0),
    .wr_en_i   (writer_fifo_wr_en),
    .wr_data_i (writer_fifo_wr_data),
    .wr_full_o (fifo_wr_full),
    .wr_level_o(/* unused */),
    .rd_clk    (clk_sys),
    .rd_rst_n  (rst_sys_n),
    .rd_clr_i  (fifo_clr_i),
    .rd_en_i   (fifo_rd_en),
    .rd_data_o (fifo_rd_data_raw),
    .rd_empty_o(fifo_rd_empty),
    .rd_level_o(fifo_rd_level)
  );

  // ── Narrow 16-bit TX ──────────────────────────────────────────
  mptdc_narrow16_tx_v2 u_narrow_tx (
    .clk_sys         (clk_sys),
    .rst_n           (rst_sys_n),
    .out_mode_i      (cfg_i.out_mode),
    .fifo_rd_valid_i (~fifo_rd_empty),
    .fifo_rd_data_i  (fifo_rd_data_raw),
    .fifo_rd_en_o    (fifo_rd_en),
    .narrow_ready_i  (narrow_ready_i),
    .narrow_valid_o  (narrow_valid_o),
    .narrow_data_o   (narrow_data_o)
  );

  // =========================================================================
  //  Conversion and overflow counters
  // =========================================================================
  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      conv_count_r     <= '0;
      ovf_count_r      <= '0;
      last_hit_count_r <= '0;
      last_flags_r     <= '0;
    end else begin
      if (fsm_conv_done) begin
        conv_count_r     <= conv_count_r + 32'd1;
        last_hit_count_r <= hit_count_live;  // Approximate — may be stale
        last_flags_r     <= fsm_flags;
      end
      // Count overflow events (start attempted with all contexts busy)
      if (fe_all_ctx_busy & start_seen_sync)
        ovf_count_r <= ovf_count_r + 16'd1;
    end
  end

  // =========================================================================
  //  FIFO wr_full synced to sys domain for status
  // =========================================================================
  logic [1:0] fifo_full_sync;
  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n)
      fifo_full_sync <= '0;
    else
      fifo_full_sync <= {fifo_full_sync[0], fifo_wr_full};
  end

  // =========================================================================
  //  Status assembly
  // =========================================================================
  assign status_o.ready              = fsm_ready;
  assign status_o.busy               = fsm_busy;
  assign status_o.ctx_state_packed   = ctx_state_packed;
  assign status_o.last_hit_count     = last_hit_count_r;
  assign status_o.last_flags         = last_flags_r;
  assign status_o.fifo_level         = fifo_rd_level;
  assign status_o.fifo_full          = fifo_full_sync[1];
  assign status_o.fifo_empty         = fifo_rd_empty;
  assign status_o.wdt_ctx_trip_cnt   = wdt_ctx_trip_cnt;
  assign status_o.wdt_global_trip_cnt = wdt_global_trip_cnt;
  assign status_o.conv_count         = conv_count_r;
  assign status_o.ovf_count          = ovf_count_r;

endmodule : mptdc_core

`default_nettype wire
