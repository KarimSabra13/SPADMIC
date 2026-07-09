// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// =============================================================================
// Project  : SPAD_MPTDC - Fixed-Packet Vernier TDC
// File     : mptdc_core.sv
// Purpose  : Measurement/readout integration core — ties together the async
//            frontend, Vernier oscillators, capture path, drain path, FIFO,
//            narrow serializer, and watchdog/status plumbing.
// Author   : Karim Sabra
// =============================================================================
// Architectural split:
//   - analog/measurement-fabric acquisition stays local to the frontend,
//     oscillator taps, counters, and PD matrix
//   - measurement teardown, context commit, draining, status, and readout run on
//     clk_sys
//   - held PD/counter levels cross into clk_sys through a static-bus capture
//     bridge before context-bank commit
//
// Active design invariants:
//   - Slow-domain START watchdog: catches STOP-never-arrives
//   - Global watchdog wdt_force_reset consumed: force-clears frontend
//   - Overflow counting from start_rejected (real context-allocation overflow)
//   - Status.ready/busy reflect active measurement state
//   - pd_gate from meas_ctrl gates PD enable on fast-close (max_hits=1)
//   - slow_boundary_inc wired into context bank for offline calibration
//   - meas_state_e is 3-bit and covers the live measurement states
// =============================================================================

`timescale 1ps/1ps
`default_nettype none

module mptdc_core
  import mptdc_pkg::*;
(
  input  wire                   clk_sys,
  input  wire                   async_rst_n_i,
  input  wire                   rst_sys_n,

  // Async START/STOP from input mux
  input  wire                   start_async_i,
  input  wire                   stop_async_i,

  // Product controls from TOP-owned CSR
  input  wire [MAX_HITS_W-1:0] max_hits_i,
  input  wire [7:0]             ro_slow_code_i,
  input  wire [7:0]             ro_fast_code_i,
  input  wire                   conv_arm_i,
  input  wire                   fifo_clr_i,

  // Status to CSR
  output mptdc_pkg::mptdc_status_t status_o,

  // Product 16-bit packet stream
  output wire                   pkt_valid_o,
  input  wire                   pkt_ready_i,
  output wire [NARROW_W-1:0]   pkt_data_o,
  output wire                   pkt_sop_o,
  output wire                   pkt_eop_o,
  output wire                   packet_active_o,
  output wire                   packet_pending_o,

  // Buffered tap0 exports for direct MPTDC block-level observability.
  output wire                   ro_slow_tap0_o,
  output wire                   ro_fast_tap0_o
);

  // synthesis translate_off
  initial begin
    if (NE != 8) begin
      $fatal(1, "mptdc_core: active integration target requires fixed NE=8 (got %0d)", NE);
    end
    if (N_CTX != 2) begin
      $fatal(1, "mptdc_core: retained context bank requires fixed N_CTX=2 (got %0d)", N_CTX);
    end
    if (MAX_HITS > 15) begin
      $fatal(1, "mptdc_core: frozen packet header supports MAX_HITS<=15 (got %0d)", MAX_HITS);
    end
  end
  // synthesis translate_on

  // =========================================================================
  //  Internal wires — oscillators
  // =========================================================================
  wire [NE-1:0] slow_phase_raw, fast_phase_raw;
  wire [NE-1:0] slow_phase, fast_phase;
  wire           slow_phase0_guard, slow_phase7d_probe;
  logic [7:0]    ro_slow_code_q;
  logic [7:0]    ro_fast_code_q;
  logic          ro_code_loaded_q;
  logic [1:0]    ro_code_osc_slow_en_sync_q;
  logic [1:0]    ro_code_osc_fast_en_sync_q;

  // =========================================================================
  //  Internal wires — frontend
  // =========================================================================
  wire           fe_start_latched, fe_stop_latched;
  wire           fe_osc_slow_en, fe_osc_fast_en, fe_pd_enable;
  ctx_id_t       fe_active_ctx;
  ctx_state_e    fe_ctx_state [N_CTX];
  wire [N_CTX-1:0] fe_ctx_drain;
  wire           fe_all_ctx_busy;
  wire           fe_start_rejected;

  // =========================================================================
  //  Internal wires — boundary repair
  // =========================================================================
  wire           phase0_snap, phase7d_snap, slow_boundary_inc;
  stop_phase_disc_t stop_slow_phase_disc;

  // =========================================================================
  //  Internal wires — PD matrix
  // =========================================================================
  wire [PD_N-1:0]          pd_hit_level;
  wire [PD_N*NFAST_W-1:0]  pd_nfast_hit_packed;
  logic [NFAST_W-1:0]      fast_tag_col [NE];

  // =========================================================================
  //  Internal wires — counter/tag fabric
  // =========================================================================
  wire [SLOW_EPOCH_STAGES-1:0] slow_epoch_johnson;
  wire [SLOW_EPOCH_STAGES-1:0] slow_epoch_johnson_stop;
  wire [NSLOW_W-1:0] nslow_src_count;
  wire [NSLOW_W-1:0] nslow_stop_latched;

  // Local-tag compatibility signal: this is the phase-0 encoded raw tag, not a
  // live binary fast counter.  It is exported in the existing nfast metadata
  // field; software and calibration decode it using mode metadata.
  wire [NFAST_W-1:0] nfast_src_count;

  // nfast_stop is retained only as an internal compatibility field. In the
  // current architecture the fast oscillator starts at STOP time
  // (osc_fast_en = stop_latched | keep_alive), so the fast counter is always 0
  // at STOP and the live narrow packet does not export it.
  wire [NFAST_W-1:0] nfast_stop_latched = '0;

  // =========================================================================
  //  Internal wires — meas_ctrl (clk_sys domain)
  // =========================================================================
  wire           meas_capture_en, meas_snapshot_en, meas_fe_clear, meas_pd_clear;
  wire           meas_osc_keep_alive;
  wire           meas_pd_gate;        // PD gate for fast-close freeze when max_hits=1
  tdc_conv_flags_t meas_close_flags;
  wire [MAX_HITS_W-1:0] meas_hit_count;
  meas_state_e   meas_state;
  wire           meas_active_sync;
  wire           stop_latched_sync;
  wire           start_timeout_sync;

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
  mptdc_ctx_snapshot_t hit_capture_snapshot;

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
  //  Reset distribution
  //  The pad/core boundary reset is already async-assert/sync-deassert in
  //  clk_sys. Local clk_sys leaves drive synchronous reset checks inside normal
  //  downstream logic; only true CDC/oscillator-domain logic keeps async reset
  //  sensitivity. Sys-domain leaves use staggered depths so synthesis cannot
  //  merge equivalent reset synchronizers back into one high-fanout control net.
  // =========================================================================
  (* keep = "true", dont_touch = "true" *) wire [NE-1:0] rst_fast_tap_n;
  (* keep = "true", dont_touch = "true" *) wire rst_sys_status_n;
  (* keep = "true", dont_touch = "true" *) wire rst_sys_drain_n;
  (* keep = "true", dont_touch = "true" *) wire rst_sys_fifo_n;
  (* keep = "true", dont_touch = "true" *) wire rst_sys_tx_n;
  (* keep = "true", dont_touch = "true" *) wire rst_sys_wdt_n;

  (* keep_hierarchy = "yes", dont_touch = "true", preserve *)
  mptdc_reset_sync #(.STAGES(2)) u_rst_status_sync (
    .clk         (clk_sys),
    .async_rst_n (rst_sys_n),
    .rst_n_o     (rst_sys_status_n)
  );

  (* keep_hierarchy = "yes", dont_touch = "true", preserve *)
  mptdc_reset_sync #(.STAGES(4)) u_rst_drain_sync (
    .clk         (clk_sys),
    .async_rst_n (rst_sys_n),
    .rst_n_o     (rst_sys_drain_n)
  );

  (* keep_hierarchy = "yes", dont_touch = "true", preserve *)
  mptdc_reset_sync #(.STAGES(3)) u_rst_fifo_sync (
    .clk         (clk_sys),
    .async_rst_n (rst_sys_n),
    .rst_n_o     (rst_sys_fifo_n)
  );

  (* keep_hierarchy = "yes", dont_touch = "true", preserve *)
  mptdc_reset_sync #(.STAGES(5)) u_rst_tx_sync (
    .clk         (clk_sys),
    .async_rst_n (rst_sys_n),
    .rst_n_o     (rst_sys_tx_n)
  );

  (* keep_hierarchy = "yes", dont_touch = "true", preserve *)
  mptdc_reset_sync #(.STAGES(6)) u_rst_wdt_sync (
    .clk         (clk_sys),
    .async_rst_n (rst_sys_n),
    .rst_n_o     (rst_sys_wdt_n)
  );

  // =========================================================================
  //  START watchdog
  //  Catches STOP-never-arrives with a held synthetic STOP level. The recovery
  //  counter is in clk_sys so no binary incrementer remains in the
  //  slow_phase[0] oscillator domain. The countdown update path is limited to
  //  zero-detect/decrement logic.
  // =========================================================================
  logic [15:0] start_wdt_cnt;
  logic       start_timeout_latched;
  localparam logic [15:0] START_WDT_DEFAULT_SYS_CYCLES = 16'd64;

  // Combined force-clear into frontend (global watchdog only — emergency).
  // start_timeout_latched injects a SYNTHETIC STOP (not a clear) to trigger normal
  // measurement flow: meas_ctrl MEASURE → close → capture → drain → packet.
  wire fe_clear_with_wdt = meas_fe_clear | wdt_force_reset;
  wire frontend_teardown_busy = meas_fe_clear | meas_pd_clear | wdt_force_reset;

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
  always_ff @(posedge clk_sys or negedge rst_sys_status_n) begin
    if (!rst_sys_status_n) begin
      ctx_drain_sync_ff1 <= '0;
      ctx_drain_sync_ff2 <= '0;
    end else begin
      ctx_drain_sync_ff1 <= fe_ctx_drain;
      ctx_drain_sync_ff2 <= ctx_drain_sync_ff1;
    end
  end

  // =========================================================================
  //  Rejected-START event capture for overflow counting
  // =========================================================================
  // fe_start_rejected is an async START-width pulse.  A direct clk_sys 2-FF
  // sampler can miss narrow rejected pulses, so first hold a pending level until
  // clk_sys has observed and counted it.  The bounded-overload contract assumes
  // rejected START pulses are separated by at least the synchronizer/ack latency;
  // accepted STARTs remain protected by the frontend SR latch itself.
  logic       start_rejected_pending;
  logic       start_rejected_pending_clr;
  (* ASYNC_REG = "TRUE" *)
  logic [1:0] rejected_sync_pipe;

  always_ff @(posedge fe_start_rejected or negedge rst_sys_n or posedge start_rejected_pending_clr) begin
    if (!rst_sys_n || start_rejected_pending_clr)
      start_rejected_pending <= 1'b0;
    else
      start_rejected_pending <= 1'b1;
  end

  always_ff @(posedge clk_sys or negedge rst_sys_status_n) begin
    if (!rst_sys_status_n)
      rejected_sync_pipe <= '0;
    else
      rejected_sync_pipe <= {rejected_sync_pipe[0], start_rejected_pending};
  end
  wire rejected_sync_pulse = rejected_sync_pipe[0] & ~rejected_sync_pipe[1];
  assign start_rejected_pending_clr = rejected_sync_pipe[1];

  // =========================================================================
  //  start_latched sync for accurate status reporting
  // =========================================================================
  (* ASYNC_REG = "TRUE" *)
  logic [1:0] start_sync_pipe;
  (* ASYNC_REG = "TRUE" *)
  logic [1:0] stop_sync_pipe;
  always_ff @(posedge clk_sys or negedge rst_sys_status_n) begin
    if (!rst_sys_status_n) begin
      start_sync_pipe <= '0;
      stop_sync_pipe  <= '0;
    end else begin
      start_sync_pipe <= {start_sync_pipe[0], fe_start_latched};
      stop_sync_pipe  <= {stop_sync_pipe[0], fe_stop_latched};
    end
  end
  wire start_latched_sync = start_sync_pipe[1];
  assign stop_latched_sync = stop_sync_pipe[1];
  assign meas_active_sync  = start_latched_sync & stop_latched_sync;
  assign start_timeout_sync = start_timeout_latched;

  always_ff @(posedge clk_sys or negedge async_rst_n_i) begin
    if (!async_rst_n_i) begin
      ro_code_osc_slow_en_sync_q <= '0;
      ro_code_osc_fast_en_sync_q <= '0;
    end else begin
      ro_code_osc_slow_en_sync_q <= {ro_code_osc_slow_en_sync_q[0], fe_osc_slow_en};
      ro_code_osc_fast_en_sync_q <= {ro_code_osc_fast_en_sync_q[0], fe_osc_fast_en};
    end
  end

  wire ro_code_capture_idle = !ro_code_osc_slow_en_sync_q[1]
                            && !ro_code_osc_fast_en_sync_q[1]
                            && !start_latched_sync
                            && !stop_latched_sync
                            && !(|ctx_drain_sync_ff2)
                            && (meas_state == ST_M_IDLE)
                            && (drain_state == ST_D_IDLE)
                            && !frontend_teardown_busy;

  always_ff @(posedge clk_sys or negedge async_rst_n_i) begin
    if (!async_rst_n_i) begin
      ro_slow_code_q  <= 8'h00;
      ro_fast_code_q  <= 8'h00;
      ro_code_loaded_q <= 1'b0;
    end else if (ro_code_capture_idle) begin
      ro_slow_code_q  <= ro_slow_code_i;
      ro_fast_code_q  <= ro_fast_code_i;
      ro_code_loaded_q <= 1'b1;
    end
  end

  wire conv_arm_after_ro_code_load = conv_arm_i & ro_code_loaded_q;

  wire [15:0] start_wdt_limit = START_WDT_DEFAULT_SYS_CYCLES;
  wire start_window_active = start_latched_sync && !stop_latched_sync;
  logic start_window_active_q;
  wire start_window_open = start_window_active && !start_window_active_q;
  wire [15:0] start_wdt_reload = (start_wdt_limit == 16'd0) ? 16'd0
                                                            : (start_wdt_limit - 16'd1);

  always_ff @(posedge clk_sys or negedge rst_sys_status_n) begin
    if (!rst_sys_status_n) begin
      start_wdt_cnt         <= '0;
      start_timeout_latched <= 1'b0;
      start_window_active_q <= 1'b0;
    end else if (meas_fe_clear) begin
      start_wdt_cnt         <= '0;
      start_timeout_latched <= 1'b0;
      start_window_active_q <= 1'b0;
    end else if (start_timeout_latched) begin
      start_window_active_q <= start_window_active;
    end else begin
      start_window_active_q <= start_window_active;
      if (start_window_open) begin
        start_wdt_cnt <= start_wdt_reload;
      end else if (start_window_active) begin
        if (start_wdt_cnt == 16'd0) begin
          start_timeout_latched <= 1'b1;
        end else begin
          start_wdt_cnt <= start_wdt_cnt - 16'd1;
        end
      end else begin
        start_wdt_cnt <= '0;
      end
    end
  end

  // synthesis translate_off
  always_ff @(posedge clk_sys or negedge rst_sys_status_n) begin
    if (rst_sys_status_n && !meas_fe_clear && !start_timeout_latched) begin
      if (start_window_active && !start_window_open && start_wdt_cnt == 16'd0) begin
        assert (!stop_latched_sync)
          else $error("mptdc_core: watchdog timeout and STOP observed together");
      end
    end
  end
  // synthesis translate_on

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
    .conv_arm_i           (conv_arm_after_ro_code_load),
    .start_async_i        (start_async_i),
    .stop_async_i         (stop_async_i),
    .fe_clear_async_i     (fe_clear_with_wdt),         // meas clear + global watchdog
    .frontend_teardown_busy_i(frontend_teardown_busy),
    .start_timeout_async_i(start_timeout_latched),     // held synthetic STOP
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
    .start_rejected_o     (fe_start_rejected)
  );

  // ── Slow oscillator ────────────────────────────────────────────
  mptdc_osc_wrapper #(.NE(NE), .TS_STEP_PS(OSC_TS_SLOW_PS)) u_osc_slow (
    .en              (fe_osc_slow_en),
    .rst_n           (rst_sys_n),
    .trim_i          (ro_slow_code_q),
    .phase           (slow_phase_raw),
    .phase0_guard_o  (/* buffered below */),
    .phase7d_probe_o (/* buffered below */)
  );

  // ── Fast oscillator ────────────────────────────────────────────
  mptdc_osc_wrapper #(.NE(NE), .TS_STEP_PS(OSC_TS_FAST_PS)) u_osc_fast (
    .en              (fe_osc_fast_en),
    .rst_n           (rst_sys_n),
    .trim_i          (ro_fast_code_q),
    .phase           (fast_phase_raw),
    .phase0_guard_o  (/* unused */),
    .phase7d_probe_o (/* unused */)
  );

  // ── Phase isolation buffers ────────────────────────────────────
  // The RO outputs drive only one matched buffer input per tap.  All downstream
  // phase consumers remain connected to slow_phase/fast_phase.
  mptdc_phase_buffer_bank u_phase_buf_slow (
    .phase_raw_i (slow_phase_raw[7:0]),
    .phase_buf_o (slow_phase[7:0])
  );

  mptdc_phase_buffer_bank u_phase_buf_fast (
    .phase_raw_i (fast_phase_raw[7:0]),
    .phase_buf_o (fast_phase[7:0])
  );

  mptdc_ro_probe_buffer u_ro_probe_slow_tap0 (
    .phase_tap_i (slow_phase[0]),
    .probe_o     (ro_slow_tap0_o)
  );

  mptdc_ro_probe_buffer u_ro_probe_fast_tap0 (
    .phase_tap_i (fast_phase[0]),
    .probe_o     (ro_fast_tap0_o)
  );

  assign slow_phase0_guard  = slow_phase[0];
  assign slow_phase7d_probe = slow_phase[7];

  // Release each fast-tag reset in the same phase-tap domain that clocks the
  // tag flops. A phase-0-only synchronizer leaves recovery timed against the
  // other fast taps as an asynchronous crossing.
  for (genvar nf_rst = 0; nf_rst < NE; nf_rst++) begin : gen_rst_fast_tap
    (* keep_hierarchy = "yes", dont_touch = "true", preserve *)
    mptdc_reset_sync #(.STAGES(2)) u_rst_fast_sync (
      .clk         (fast_phase[nf_rst]),
      .async_rst_n (rst_sys_n),
      .rst_n_o     (rst_fast_tap_n[nf_rst])
    );
  end

  // ── Local fast epoch tags (one shallow tag generator per fast column) ──────
  // Each tag is clocked by the same fast tap that samples the corresponding PD
  // column.  This avoids a shared phase-0 binary counter crossing into every
  // fast column and limits tag fanout to the eight cells in one column.
  for (genvar nf_tag = 0; nf_tag < NE; nf_tag++) begin : gen_fast_tag_col
`ifdef MPTDC_RELAX_FAST_TAG_PRESERVE
    (* keep_hierarchy = "yes" *)
`else
    (* keep_hierarchy = "yes", preserve *)
`endif
    mptdc_fast_epoch_tag #(
      .W                (NFAST_W),
      .SEED             (FAST_TAG_SEED),
      .TAG_ENCODING_SEL (FAST_TAG_ENCODING_SEL)
    ) u_fast_tag (
      .clk_fast     (fast_phase[nf_tag]),
      .rst_n        (rst_fast_tap_n[nf_tag]),
      .clear_window (meas_pd_clear),
      .enable_i     (fe_osc_fast_en),
      .tag_o        (fast_tag_col[nf_tag])
    );
  end

  assign nfast_src_count = fast_tag_col[0];
  assign nslow_src_count = slow_johnson_to_count(slow_epoch_johnson);
  assign nslow_stop_latched = slow_johnson_to_count(slow_epoch_johnson_stop);

  // ── Slow epoch tag ─────────────────────────────────────────────
  // Johnson encoding removes the slow-domain binary counter/Gray encoder and
  // gives STOP an asynchronously captured one-bit-change raw epoch state.
  (* keep_hierarchy = "yes", preserve *)
  mptdc_slow_epoch_johnson #(
    .STAGES (SLOW_EPOCH_STAGES)
  ) u_slow_epoch (
    .clk_slow     (slow_phase[0]),
    .rst_n        (rst_sys_n),
    .clear_window (meas_pd_clear),
    .enable_i     (fe_osc_slow_en),
    .johnson_o    (slow_epoch_johnson)
  );

  // ── Phase Detector Matrix (PD_N cells) ─────────────────────────
  // The PD island is the critical physical-performance block.  Keep the 8x8
  // hierarchy regular so backend placement/routing can preserve row/column
  // symmetry, matched phase-tap loading, and reviewable RC/skew assumptions.
  // detect_en_i freezes the PD samplers outside the valid measurement window
  // without forcing slow_phase low and fabricating a falling-edge hit.
  for (genvar ns = 0; ns < NE; ns++) begin : gen_pd_row
    for (genvar nf = 0; nf < NE; nf++) begin : gen_pd_col
      localparam int unsigned CELL = ns * NE + nf;
      (* keep_hierarchy = "yes" *)
      mptdc_pd_cell #(.SAMPLE_DEPTH(2)) u_pd (
        .rst_n        (rst_sys_n),
        .clear_window (meas_pd_clear),
        .slow_phase   (slow_phase[ns]),
        .fast_phase   (fast_phase[nf]),
        .detect_en_i  (pd_enable_gated),
        .nfast_tag_i  (fast_tag_col[nf]),
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
    .slow_phase_disc_i    (stop_phase_disc_t'(slow_phase[STOP_PHASE_DISC_MSB:STOP_PHASE_DISC_LSB])),
    .slow_phase0_guard_i  (slow_phase0_guard),
    .slow_phase7d_probe_i (slow_phase7d_probe),
    .phase0_snap_o        (phase0_snap),
    .stop_slow_phase_disc_o (stop_slow_phase_disc),
    .phase7d_snap_o       (phase7d_snap),
    .slow_boundary_inc_o  (slow_boundary_inc)
  );

  // ── STOP-side raw slow epoch capture ──────────────────────────
  mptdc_stop_epoch_capture_async u_stop_epoch_capture (
    .rst_n                       (rst_sys_n),
    .async_clr_i                 (meas_pd_clear),
    .stop_async_i                (stop_async_i),
    .slow_epoch_johnson_i        (slow_epoch_johnson),
    .slow_epoch_johnson_stop_o   (slow_epoch_johnson_stop)
  );

  // ── Measurement FSM (clk_sys domain) ──────────────────────────
  mptdc_meas_ctrl u_meas_ctrl (
    .clk_sys          (clk_sys),
    .rst_n            (rst_sys_drain_n),
    .meas_active_i    (meas_active_sync),
    .timeout_active_i (start_timeout_sync),
    .hit_level_i      (pd_hit_level),
    .max_hits_cfg_i   (max_hits_i),
    .capture_en_o     (meas_capture_en),
    .snapshot_en_o    (meas_snapshot_en),
    .fe_clear_o       (meas_fe_clear),
    .pd_clear_o       (meas_pd_clear),
    .pd_gate_o        (meas_pd_gate),
    .osc_keep_alive_o (meas_osc_keep_alive),
    .close_flags_o    (meas_close_flags),
    .hit_count_o      (meas_hit_count),
    .state_o          (meas_state)
  );

  // ── Static-bus bridge from measurement fabric to clk_sys ───────
  mptdc_hit_capture_bridge u_hit_capture_bridge (
    .clk_sys                (clk_sys),
    .rst_n                  (rst_sys_drain_n),
    .sample_en_i            (meas_snapshot_en),
    .pd_hit_level_i         (pd_hit_level),
    .pd_nfast_hit_packed_i  (pd_nfast_hit_packed),
    .slow_epoch_johnson_stop_i (slow_epoch_johnson_stop),
    .nfast_snap_i           (nfast_src_count),
    .nfast_stop_i           (nfast_stop_latched),
    .phase0_snap_i          (phase0_snap),
    .stop_slow_phase_disc_i (stop_slow_phase_disc),
    .slow_boundary_inc_i    (slow_boundary_inc),
    .snapshot_o             (hit_capture_snapshot)
  );

  // ── Context bank (clk_sys write/read) ──────────────────────────
  mptdc_context_bank u_ctx_bank (
    .clk_sys              (clk_sys),
    .rst_n                (rst_sys_drain_n),
    .capture_ctx_i        (fe_active_ctx),
    .capture_en_i         (meas_capture_en),
    .capture_snapshot_i   (hit_capture_snapshot),
    .hit_count_i          (meas_hit_count),
    .flags_i              (meas_close_flags),
    .read_ctx_i           (drain_read_ctx),
    .snapshot_o           (ctx_snapshot)
  );

  // ── Drain FSM (sys domain) ────────────────────────────────────
  mptdc_drain_ctrl u_drain_ctrl (
    .clk_sys           (clk_sys),
    .rst_n             (rst_sys_drain_n),
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
    .rst_n     (rst_sys_fifo_n),
    .clr_i     (fifo_clr_i),
    .wr_en_i   (drain_fifo_wr_en),
    .wr_data_i (drain_fifo_wr_data),
    .wr_full_o (fifo_wr_full),
    .rd_en_i   (fifo_rd_en),
    .rd_data_o (fifo_rd_data),
    .rd_valid_o(fifo_rd_valid),
    .level_o   (fifo_level)
  );

  // ── Product 16-bit packet TX ──────────────────────────────────
  mptdc_packet16_tx u_packet_tx (
    .clk_sys         (clk_sys),
    .rst_n           (rst_sys_tx_n),
    .fifo_rd_valid_i (fifo_rd_valid),
    .fifo_rd_data_i  (fifo_rd_data),
    .fifo_rd_en_o    (fifo_rd_en),
    .pkt_valid_o     (pkt_valid_o),
    .pkt_ready_i     (pkt_ready_i),
    .pkt_data_o      (pkt_data_o),
    .pkt_sop_o       (pkt_sop_o),
    .pkt_eop_o       (pkt_eop_o),
    .packet_active_o (packet_active_o),
    .packet_pending_o(packet_pending_o)
  );

  // ── Watchdog (sys domain, global only) ─────────────────────────
  mptdc_watchdog u_wdt (
    .clk_sys               (clk_sys),
    .rst_n                 (rst_sys_wdt_n),
    .conv_done_i           (drain_conv_done),
    .wdt_global_timeout_i  (16'd0),
    .wdt_force_reset_o     (wdt_force_reset),
    .wdt_global_trip_cnt_o (wdt_global_trip_cnt)
  );

  // =========================================================================
  //  Conversion and overflow counters
  // =========================================================================
  always_ff @(posedge clk_sys) begin
    if (!rst_sys_status_n) begin
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
      // Count real rejected START events (context-allocation overflow).
      if (rejected_sync_pulse)
        ovf_count_r <= ovf_count_r + 16'd1;
    end
  end

  // =========================================================================
  //  Status assembly reflects active measurement state.
  // =========================================================================
`ifdef MPTDC_SAFE_TEARDOWN
  wire status_measure_idle = (meas_state == ST_M_IDLE);
  wire status_teardown_idle = ~frontend_teardown_busy;
`else
  wire status_measure_idle = 1'b1;
  wire status_teardown_idle = 1'b1;
`endif

  assign status_o.ready              = conv_arm_after_ro_code_load & ~fe_all_ctx_busy
                                     & ~start_latched_sync
                                     & status_measure_idle
                                     & status_teardown_idle;
  assign status_o.busy               = start_latched_sync
                                     | (|ctx_drain_sync_ff2)
                                     | (drain_state != ST_D_IDLE)
                                     | ~status_measure_idle
                                     | ~status_teardown_idle;
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
