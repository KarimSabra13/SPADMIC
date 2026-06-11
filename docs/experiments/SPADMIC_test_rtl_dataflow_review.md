# SPADMIC_test RTL Dataflow Review

## Measurement FSM Baseline

`mptdc_meas_ctrl` uses:

`IDLE -> MEASURE -> SNAPSHOT -> COUNT -> EVAL -> CAPTURE -> CLEAR -> IDLE`

Baseline outputs:

- `snapshot_en_o = ST_M_SNAPSHOT`
- `capture_en_o = ST_M_CAPTURE`
- `fe_clear_o = ST_M_CAPTURE`
- `pd_clear_o = ST_M_CLEAR`

`MPTDC_PD_CLEAR_EARLY` optionally changes only `pd_clear_o` to assert in CAPTURE and CLEAR. It keeps the CLEAR state.

## Frontend START, STOP, Clear

`mptdc_async_frontend_v2` latches START when armed, any context is free, and no clear or teardown block is active. STOP or watchdog timeout closes the active measurement and enables PD capture behavior.

`SAFE_TEARDOWN` adds an explicit `frontend_teardown_busy_i` block. In `mptdc_core`, it is driven by:

`meas_fe_clear | meas_pd_clear | wdt_force_reset`

STARTs during this window are rejected, not accepted into a new measurement.

## PD Sampling And Tag Capture

The PD sampling principle remains unchanged. Fast phase, slow phase, PD cell latches, and timestamp freeze behavior are not modified. `mptdc_pd_cell`, `mptdc_fast_epoch_tag`, and `mptdc_slow_epoch_johnson` keep their measurement behavior.

Fast tags still use the existing `rst_fast_n` reset scheme in this pass. That reset release remains documented as `RESET_RECOVERY_NOT_SIGNOFF_READY` until a separate cleanup is simulated and closed.

## Snapshot, Context, Drain

`mptdc_hit_capture_bridge` samples PD hit levels, per-cell fast tags, slow snapshot metadata, phase0, STOP discriminator metadata, and flags into `mptdc_ctx_snapshot_t`.

With `MPTDC_DRAIN_ROW_SKIP`, the bridge also stores:

`row_nonzero[row] = |pd_hit_level[row*8 +: 8]`

`mptdc_context_bank` stores the snapshot per context. `mptdc_drain_ctrl` selects one draining context, emits META, scans HIT records, and releases the context at EOC.

## FIFO And Packet Flow

`mptdc_drain_ctrl` writes acquisition records into the sync FIFO. `mptdc_narrow16_tx_v2` serializes fixed 16-bit internal records. `spadmic_tdc_packet_adapter` maps MPTDC records into the top-level packet stream. The chip-visible TX remains:

- `chip_tx_clk_o`
- `chip_tx_valid_o`
- `chip_tx_data_o[7:0]`

`acq_data_o`, `acq_valid_o`, `csr_rdata_o`, and `csr_rvalid_o` remain internal integration signals.

## Timing-Critical Domains

Do not add logic on:

- RO raw outputs.
- `fast_phase` into `mptdc_pd_cell`.
- `mptdc_fast_epoch_tag` fast-domain critical data paths.
- Phase-buffer root and final driver topology.

Allowed optimization area is `clk_sys`-only logic around measurement control, teardown gating, context metadata, drain scan, FIFO scheduling, and readout scheduling.

## Safe And Risky Changes

Safe first-pass changes:

- START blocking during teardown.
- `ready` deassertion during teardown.
- Row metadata stored at snapshot time.
- Drain row skip in `clk_sys`.
- Stride-2 scan with local pending hit state.

Risky or deferred:

- Removing fast-tag reset without first-conversion proof.
- Removing `ST_M_CLEAR`.
- Removing `ST_M_MEASURE`.
- Priority next-hit scan.
- Any PD sampling behavior change.
