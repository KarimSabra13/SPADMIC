// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// =============================================================================
// Project  : SPAD_MPTDC v2.2 — Design Review Enhanced Vernier TDC
// File     : mptdc_core.sv
// Purpose  : Measurement/readout integration core — ties together the async
//            frontend, Vernier oscillators, capture path, drain path, FIFO,
//            narrow serializer, and watchdog/status plumbing.
// Author   : Karim Sabra
// =============================================================================
// Architectural split:
//   - async and fast-domain acquisition stay local to the frontend, counters,
//     PD matrix, and measurement FSM
//   - sys-domain draining, status, and readout stay on clk_sys
//   - ctx_drain plus the static context-bank snapshot form the key cross-domain
//     contract between capture and drain
//
// v2.2 review updates:
//   - Slow-domain START watchdog: catches STOP-never-arrives
//   - Global watchdog wdt_force_reset consumed: force-clears frontend
//   - Overflow counting from start_rejected (real context-allocation overflow)
//   - Status.ready/busy reflect active measurement state
//   - pd_gate from meas_ctrl gates PD enable (FIRST_HIT freeze)
//   - slow_boundary_inc wired into context bank for offline calibration
//   - meas_state_e is now 3-bit (5 states)
// =============================================================================

`timescale 1ps/1ps
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
  wire [N_CTX-1:0] fe_ctx_drain;
  wire           fe_all_ctx_busy;
  wire           fe_start_rejected;  // v2.2

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
  wire [NSLOW_W-1:0] nslow_src_count, nslow_stop_latched;
  wire [NFAST_W-1:0] nfast_src_count;

  // =========================================================================
  //  Internal wires — meas_ctrl (fast domain)
  // =========================================================================
  wire           meas_capture_en, meas_fe_clear, meas_pd_clear;
  wire           meas_osc_keep_alive;
  wire           meas_pd_gate;        // v2.2: PD gate for FIRST_HIT freeze
  tdc_conv_flags_t meas_close_flags;
  wire [MAX_HITS_W-1:0] meas_hit_count;
  meas_state_e   meas_state;

  // =========================================================================
  //  Internal wires — drain_ctrl (sys domain)
  // =========================================================================
  wire           drain_fifo_wr_en;
  mptdc_acq_rec_t drain_fifo_wr_data;
  wire [N_CTX-1:0] drain_ctx_release;
  wire           drain_conv_done;
  ctx_id_t       drain_read_ctx;
  drain_state_e  drain_state;

  // =========================================================================
  //  Internal wires — context bank
  // =========================================================================
  // Static-data CDC contract: drain_ctrl only samples ctx_snapshot after
  // ctx_drain_sync_ff2 rises, so the selected entry is already frozen.
  mptdc_ctx_snapshot_t ctx_snapshot;

  // =========================================================================
  //  Internal wires — sync FIFO
  // =========================================================================
  wire           fifo_wr_full;
  wire           fifo_rd_valid;
  wire [ACQ_REC_W-1:0] fifo_rd_data;
  wire           fifo_rd_en;
  wire [$clog2(FIFO_DEPTH+1)-1:0] fifo_level;

  // =========================================================================
  //  Internal wires — watchdog
  // =========================================================================
  wire           wdt_force_reset;
  wire [7:0]     wdt_global_trip_cnt;

  // =========================================================================
  //  v2.2: Fast-domain reset synchronizer
  //  Ensures rst_sys_n deasserts cleanly in osc_fast_ph0 domain.
  //  Async assert is immediate; sync deassert waits 2 fast edges.
  // =========================================================================
  wire rst_fast_n;

  mptdc_reset_sync #(.STAGES(2)) u_rst_fast_sync (
    .clk         (osc_fast_ph0),
    .async_rst_n (rst_sys_n),
    .rst_n_o     (rst_fast_n)
  );

  // =========================================================================
  //  v2.2: Slow-domain START watchdog
  //  Catches STOP-never-arrives: counter in slow_phase[0] domain.
  //  When start_latched is high and stop_latched is low, counts slow cycles.
  //  On saturation, asserts start_timeout to force-clear frontend.
  //  Async reset on meas_fe_clear ensures counter resets even if slow osc
  //  stops before a rising edge (STOP_OSC kills the slow clock).
  // =========================================================================
  logic [7:0] start_wdt_cnt;
  logic       start_timeout_raw;

  always_ff @(posedge slow_phase[0] or negedge rst_sys_n or posedge meas_fe_clear) begin
    if (!rst_sys_n || meas_fe_clear)
      start_wdt_cnt <= '0;
    else if (!fe_start_latched || fe_stop_latched)
      start_wdt_cnt <= '0;
    else if (start_wdt_cnt != 8'hFF)
      start_wdt_cnt <= start_wdt_cnt + 8'd1;
  end

  assign start_timeout_raw = (start_wdt_cnt == 8'hFF);

  // v2.2: Combined force-clear into frontend (global watchdog only — emergency)
  // start_timeout injects a SYNTHETIC STOP (not a clear) to trigger normal
  // measurement flow: meas_ctrl MEASURE → close → capture → drain → packet.
  wire fe_clear_with_wdt = meas_fe_clear | wdt_force_reset;

  // =========================================================================
  //  Conversion / overflow counters (sys domain)
  // =========================================================================
  logic [31:0]   conv_count_r;
  logic [15:0]   ovf_count_r;
  logic [MAX_HITS_W-1:0] last_hit_count_r;
  tdc_conv_flags_t       last_flags_r;

  // =========================================================================
  //  Context state packing for status register
  // =========================================================================
  logic [N_CTX*2-1:0] ctx_state_packed;
  always_comb begin
    for (int i = 0; i < N_CTX; i++)
      ctx_state_packed[i*2 +: 2] = fe_ctx_state[i];
  end

  // =========================================================================
  //  ctx_drain: 2-FF sync (async → sys_clk) for drain_ctrl
  // =========================================================================
  (* ASYNC_REG = "TRUE" *)
  logic [N_CTX-1:0] ctx_drain_sync_ff1, ctx_drain_sync_ff2;
  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
      ctx_drain_sync_ff1 <= '0;
      ctx_drain_sync_ff2 <= '0;
    end else begin
      ctx_drain_sync_ff1 <= fe_ctx_drain;
      ctx_drain_sync_ff2 <= ctx_drain_sync_ff1;
    end
  end

  // =========================================================================
  //  v2.2: start_rejected sync for real overflow counting
  // =========================================================================
  (* ASYNC_REG = "TRUE" *)
  logic [1:0] rejected_sync_pipe;
  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n)
      rejected_sync_pipe <= '0;
    else
      rejected_sync_pipe <= {rejected_sync_pipe[0], fe_start_rejected};
  end
  wire rejected_sync_pulse = rejected_sync_pipe[0] & ~rejected_sync_pipe[1];

  // =========================================================================
  //  v2.2: start_latched sync for accurate status reporting
  // =========================================================================
  (* ASYNC_REG = "TRUE" *)
  logic [1:0] start_sync_pipe;
  always_ff @(posedge clk_sys or negedge rst_sys_n) begin
    if (!rst_sys_n)
      start_sync_pipe <= '0;
    else
      start_sync_pipe <= {start_sync_pipe[0], fe_start_latched};
  end
  wire start_latched_sync = start_sync_pipe[1];

  // =========================================================================
  //  PD enable gating: combine frontend pd_enable with meas_ctrl pd_gate
  // =========================================================================
  wire pd_enable_gated = fe_pd_enable & meas_pd_gate;

  // ========================================================================
  //  Instantiations
  // ========================================================================

  // ── Frontend ────────────────────────────────────────────────────
  mptdc_async_frontend_v2 u_frontend (
    .rst_n                (rst_sys_n),
    .conv_arm_i           (conv_arm_i),
    .start_async_i        (start_async_i),
    .stop_async_i         (stop_async_i),
    .fe_clear_async_i     (fe_clear_with_wdt),        // v2.2: meas clear + global wdt
    .start_timeout_async_i(start_timeout_raw),         // v2.2: synthetic STOP
    .ctx_release_async_i  (drain_ctx_release),
    .capture_en_i         (meas_capture_en),
    .osc_keep_alive_i     (meas_osc_keep_alive),
    .start_latched_o      (fe_start_latched),
    .stop_latched_o       (fe_stop_latched),
    .osc_slow_en_async_o  (fe_osc_slow_en),
    .osc_fast_en_async_o  (fe_osc_fast_en),
    .pd_enable_async_o    (fe_pd_enable),
    .active_ctx_o         (fe_active_ctx),
    .ctx_state_o          (fe_ctx_state),
    .ctx_drain_o          (fe_ctx_drain),
    .all_ctx_busy_o       (fe_all_ctx_busy),
    .start_rejected_o     (fe_start_rejected)     // v2.2
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
  mptdc_osc_wrapper #(.NE(NE), .TS_STEP_PS(OSC_TS_FAST_PS)) u_osc_fast (
    .en              (fe_osc_fast_en),
    .rst_n           (rst_sys_n),
    .trim_i          (1'b0),
    .phase           (fast_phase),
    .phase0_guard_o  (/* unused */),
    .phase7d_probe_o (/* unused */)
  );

  // ── Phase Detector Matrix (PD_N cells) ─────────────────────────
  // slow_phase is gated by pd_enable_gated: PD cells only see
  // oscillator edges when FSM is in MEASURE and pd_gate is high.
  // This prevents hits during rst_fast_n warmup (when counters = 0).
  for (genvar ns = 0; ns < NE; ns++) begin : gen_pd_row
    for (genvar nf = 0; nf < NE; nf++) begin : gen_pd_col
      localparam int unsigned CELL = ns * NE + nf;
      mptdc_pd_cell #(.SAMPLE_DEPTH(2)) u_pd (
        .rst_n        (rst_sys_n),
        .clear_window (meas_pd_clear),
        .slow_phase   (pd_enable_gated & slow_phase[ns]),
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
    .async_clr_i          (meas_pd_clear),
    .stop_async_i         (stop_async_i),
    .slow_phase0_i        (slow_phase[0]),
    .slow_phase0_guard_i  (slow_phase0_guard),
    .slow_phase7d_probe_i (slow_phase7d_probe),
    .phase0_snap_o        (phase0_snap),
    .phase7d_snap_o       (phase7d_snap),
    .slow_boundary_inc_o  (slow_boundary_inc)
  );

  // ── Gray counter CDC: slow counter (slow → fast) ──────────────
  mptdc_gray_cnt_sync #(
    .W                  (NSLOW_W),
    .USE_ASYNC_SNAPSHOT (1'b1)
  ) u_slow_cnt (
    .src_clk              (slow_phase[0]),
    .src_rst_n            (rst_sys_n),
    .src_async_clr        (meas_pd_clear),
    .src_en               (1'b1),
    .src_clr              (1'b0),
    .src_latch_p          (1'b0),
    .src_async_latch_p    (stop_async_i),
    .src_count            (nslow_src_count),
    .dst_clk              (osc_fast_ph0),
    .dst_rst_n            (rst_fast_n),
    .dst_latch_p          (1'b0),
    .dst_count_continuous (/* unused */),
    .dst_count_latched    (nslow_stop_latched)
  );

  // ── Fast counter ──────────────────────────────────────────────
  mptdc_gray_cnt_sync #(.W(NFAST_W)) u_fast_cnt (
    .src_clk              (osc_fast_ph0),
    .src_rst_n            (rst_fast_n),
    .src_async_clr        (meas_pd_clear),
    .src_en               (1'b1),
    .src_clr              (1'b0),
    .src_latch_p          (1'b0),
    .src_async_latch_p    (1'b0),
    .src_count            (nfast_src_count),
    .dst_clk              (osc_fast_ph0),
    .dst_rst_n            (rst_fast_n),
    .dst_latch_p          (1'b0),
    .dst_count_continuous (/* unused — same domain, use src_count */),
    .dst_count_latched    (/* unused */)
  );

  // ── Measurement FSM (fast domain) ─────────────────────────────
  mptdc_meas_ctrl u_meas_ctrl (
    .clk_fast         (osc_fast_ph0),
    .rst_n            (rst_fast_n),
    .meas_active_i    (fe_start_latched & fe_stop_latched),
    .hit_level_i      (pd_hit_level),
    .max_hits_cfg_i   (cfg_i.max_hits),
    .first_hit_mode_i (cfg_i.mode_cfg == MODE_FIRST_HIT),
    .wdt_timeout_i    (cfg_i.wdt_ctx_timeout),
    .capture_en_o     (meas_capture_en),
    .fe_clear_o       (meas_fe_clear),
    .pd_clear_o       (meas_pd_clear),
    .pd_gate_o        (meas_pd_gate),           // v2.2
    .osc_keep_alive_o (meas_osc_keep_alive),
    .close_flags_o    (meas_close_flags),
    .hit_count_o      (meas_hit_count),
    .state_o          (meas_state)
  );

  // ── Context bank ───────────────────────────────────────────────
  mptdc_context_bank u_ctx_bank (
    .clk_fast              (osc_fast_ph0),
    .capture_ctx_i         (fe_active_ctx),
    .capture_en_i          (meas_capture_en),
    .pd_hit_level_i        (pd_hit_level),
    .pd_nfast_hit_packed_i (pd_nfast_hit_packed),
    .nslow_snap_i          (nslow_stop_latched),
    .nfast_snap_i          (nfast_src_count),
    .phase0_snap_i         (phase0_snap),
    .slow_boundary_inc_i   (slow_boundary_inc),   // v2.2
    .hit_count_i           (meas_hit_count),
    .flags_i               (meas_close_flags),
    .read_ctx_i            (drain_read_ctx),
    .snapshot_o            (ctx_snapshot)
  );

  // ── Drain FSM (sys domain) ────────────────────────────────────
  mptdc_drain_ctrl u_drain_ctrl (
    .clk_sys           (clk_sys),
    .rst_n             (rst_sys_n),
    .ctx_drain_sync_i  (ctx_drain_sync_ff2),
    .read_ctx_o        (drain_read_ctx),
    .snapshot_i        (ctx_snapshot),
    .fifo_wr_en_o      (drain_fifo_wr_en),
    .fifo_wr_data_o    (drain_fifo_wr_data),
    .fifo_wr_full_i    (fifo_wr_full),
    .ctx_release_o     (drain_ctx_release),
    .conv_done_o       (drain_conv_done),
    .state_o           (drain_state)
  );

  // ── Sync FIFO (sys domain: drain → narrow16) ──────────────────
  mptdc_sync_fifo #(
    .WIDTH (ACQ_REC_W),
    .DEPTH (FIFO_DEPTH)
  ) u_fifo (
    .clk       (clk_sys),
    .rst_n     (rst_sys_n),
    .clr_i     (fifo_clr_i),
    .wr_en_i   (drain_fifo_wr_en),
    .wr_data_i (drain_fifo_wr_data),
    .wr_full_o (fifo_wr_full),
    .rd_en_i   (fifo_rd_en),
    .rd_data_o (fifo_rd_data),
    .rd_valid_o(fifo_rd_valid),
    .level_o   (fifo_level)
  );

  // ── Narrow 16-bit TX ──────────────────────────────────────────
  mptdc_narrow16_tx_v2 u_narrow_tx (
    .clk_sys         (clk_sys),
    .rst_n           (rst_sys_n),
    .out_mode_i      (cfg_i.out_mode),
    .fifo_rd_valid_i (fifo_rd_valid),
    .fifo_rd_data_i  (fifo_rd_data),
    .fifo_rd_en_o    (fifo_rd_en),
    .narrow_ready_i  (narrow_ready_i),
    .narrow_valid_o  (narrow_valid_o),
    .narrow_data_o   (narrow_data_o)
  );

  // ── Watchdog (sys domain, global only) ─────────────────────────
  mptdc_watchdog u_wdt (
    .clk_sys               (clk_sys),
    .rst_n                 (rst_sys_n),
    .conv_done_i           (drain_conv_done),
    .wdt_global_timeout_i  (cfg_i.wdt_global_timeout),
    .wdt_force_reset_o     (wdt_force_reset),
    .wdt_global_trip_cnt_o (wdt_global_trip_cnt)
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
      if (drain_conv_done) begin
        conv_count_r     <= conv_count_r + 32'd1;
        last_hit_count_r <= ctx_snapshot.hit_count;
        last_flags_r     <= ctx_snapshot.flags;
      end
      // v2.2: count real rejected START events (context-allocation overflow)
      if (rejected_sync_pulse)
        ovf_count_r <= ovf_count_r + 16'd1;
    end
  end

  // =========================================================================
  //  Status assembly (v2.2: reflects active measurement state)
  // =========================================================================
  assign status_o.ready              = conv_arm_i & ~fe_all_ctx_busy
                                     & ~start_latched_sync;
  assign status_o.busy               = start_latched_sync
                                     | (|ctx_drain_sync_ff2)
                                     | (drain_state != ST_D_IDLE);
  assign status_o.ctx_state_packed   = ctx_state_packed;
  assign status_o.drain_state        = drain_state;
  assign status_o.last_hit_count     = last_hit_count_r;
  assign status_o.last_flags         = last_flags_r;
  assign status_o.fifo_level         = fifo_level;
  assign status_o.fifo_full          = fifo_wr_full;
  assign status_o.fifo_empty         = ~fifo_rd_valid;
  assign status_o.wdt_global_trip_cnt = wdt_global_trip_cnt;
  assign status_o.conv_count         = conv_count_r;
  assign status_o.ovf_count          = ovf_count_r;

endmodule : mptdc_core

`default_nettype wire
