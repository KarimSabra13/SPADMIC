# CDC/Async Waiver Package

Status: draft package for review. This is not signoff approval.

Evidence sources:

- `results/genus/20260527_0845_current_head_genus_baseline/check_timing_intent.rpt`
- `results/genus/20260527_0845_current_head_genus_baseline/cdc_manual_audit.rpt`
- local Verilator baseline `results/local_verilator/20260527_0845_baseline_local/`

## START Async Input

- Source domain/event: async START pulse from SPAD/calibration mux.
- Destination/domain: async frontend latches, then clk_sys status/control.
- Signals: `start_async_i`, `start_latched_q`, `start_accept_seen_q`.
- Mechanism: intentional level/event latch in `mptdc_async_frontend_v2`.
- Constraint: async input false path.
- Evidence: Verilator smoke covered normal conversion and rejected START
  accounting through existing VIP tests.
- Residual risk: Xcelium async-edge stress still server-required.

## STOP Async Input

- Source domain/event: async STOP pulse from SPAD/calibration mux.
- Destination/domain: async frontend STOP latch and STOP metadata capture.
- Signals: `stop_async_i`, `stop_latched_q`, STOP metadata registers.
- Mechanism: event latch plus held metadata sampled later by clk_sys bridge.
- Constraint: async input false path and STOP metadata data-pin false paths.
- Residual risk: STOP-near-clk_sys-edge stress still server-required.

## Async Frontend Latches

- Source domain/event: START/STOP/clear/release async control.
- Destination/domain: frontend ownership and context drain latches.
- Signals: `start_latched_q`, `stop_latched_q`, `start_accept_seen_q`,
  `start_reject_seen_q`, `active_ctx_q`, `ctx_drain_q`.
- Mechanism: intentional latch-based event ownership.
- Constraint: latch audit; expected latch count is now `7`.
- Evidence: Genus baseline observed exactly those 7 latches.
- Waiver status: draft, pending next Genus latch audit and Xcelium stress.

## Rejected START Capture

- Source domain/event: rejected START pulse.
- Destination/domain: clk_sys overflow accounting.
- Signals: `start_rejected_o`, `start_rejected_pending`,
  `rejected_sync_pipe`.
- Mechanism: async pending latch plus 2FF sync/ack; avoids losing narrow reject
  pulses.
- Constraint: preserve rejected pending/sync structures.
- Evidence: RTL comments and CDC audit list this class.
- Residual risk: server Xcelium rejected-START stress still required.

## STOP Metadata Capture

- Source domain/event: STOP edge.
- Destination/domain: clk_sys held-bus bridge.
- Signals: `phase0_snap`, `stop_slow_phase_disc`, `slow_boundary_inc`.
- Mechanism: STOP captures stable slow-ring metadata; bridge samples held level.
- Constraint: data-pin false paths plus static-bus max-delay into snapshot regs.
- Residual risk: verify max-delay is active in exception report.

## Gray Counter Snapshot/Sync

- Source domain/event: slow and fast oscillator phases.
- Destination/domain: fast or clk_sys consumers depending on counter instance.
- Signals: `gray_cont_ff*`, `gray_snap_ff*`, `src_async_clr`.
- Mechanism: Gray coding plus synchronizer/snapshot flops.
- Constraint: synchronizer preservation, async clear false path.
- Residual risk: recovery/removal and clear ordering need server review.

## Held PD Bitmap Into Hit-Capture Bridge

- Source domain/event: PD cells and oscillator counters hold measurement image.
- Destination/domain: clk_sys bridge.
- Signals: `pd_hit_level`, packed `nfast_hit`, `nslow`, `nfast`, STOP metadata.
- Mechanism: held static-bus CDC; `snapshot_en_o` samples before `pd_clear_o`.
- Stable window: at least from STOP/MEASURE recognition through SNAPSHOT and
  COUNT, until CLEAR asserts `pd_clear_o`.
- Constraint: static-bus max-delay for STOP metadata; broader held-bus physical
  bounds still need review.
- Evidence: Verilator bridge and meas_ctrl smoke assert sample/capture before
  clear.
- Residual risk: Xcelium async/event stress required.

## PD Async Clear

- Source domain/event: clk_sys teardown pulse.
- Destination/domain: PD cells and source-domain counters.
- Signals: `meas_pd_clear`.
- Mechanism: clear occurs only after bridge snapshot and context capture.
- Constraint: async clear false paths.
- Evidence: local `tb_meas_ctrl_unit` asserts snapshot and capture before clear.
- Residual risk: recovery/removal waiver requires server signoff evidence.
