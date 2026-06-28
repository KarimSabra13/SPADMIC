# Matrix TOP Verification Plan

Status: Phase 0 plan for Phase 1 and later verification.

## Phase 0 Verification

Checks:

- branch, commit, and working-tree status recorded;
- decision log exists;
- final docs record frozen mode rules;
- `clk_cfg_40m` is documented as a separate domain;
- DDR16 target replaces current 8-bit DDR as final target;
- `matrice3` floorplan plan uses normalized `ll_*` CSV coordinates;
- protected MPTDC boundary is documented;
- stale docs/test references are recorded as risk.

## Unit Tests

### OR64 Tree

- every input bit toggles output;
- no cross-axis coupling when three instances are used;
- balanced logic structure is reviewable.

### Snapshot Frontend

- all six R/Y/B arrival orders;
- all three directions nonzero for valid normal snapshot;
- late bit before capture restarts settle;
- incomplete direction watchdog timeout;
- overlap indication;
- snapshot frozen after acceptance;
- rearm after two synchronized all-zero samples;
- capture-only behavior for TDC-only.

### Reset Controller

- outputs all ones after global reset;
- width zero disables pulse;
- width one produces exactly one `clk_sys` cycle;
- arbitrary N produces exactly N cycles;
- multi-bit R/Y/B mask drives Cartesian over-reset;
- mask stable during active reset;
- async reset releases outputs inactive high;
- no retry or clear verification.

### Event Coordinator

- TDC-only does not wait for position packet/queue;
- Position-only does not wait for MPTDC ready/busy/packet;
- BOTH waits for all active required sources;
- Calibration ignores matrix activity;
- masks stable after event open;
- frozen grant prevents first busy TDC from blocking later skewed STARTs;
- one event in flight.

### DDR16 Pairer

- two consecutive words produce one pair;
- older word goes to DATA_L/default low side;
- idle zeros;
- reset clears state;
- busy/empty status correct;
- odd word behavior follows pair-valid policy and is documented/testable.

### Matrix Configuration Controller

- write column 0;
- write column 43;
- read back selected column;
- write-column readback comes from delayed returned `Cout/Dout`, not mirrored `wdata`;
- selected `Dout` is sampled only on the intended returned `Cout` edge;
- missing returned `Cout` reports timeout/error and clears `matrix_cfg_valid`;
- global fill 0;
- global fill 1;
- invalid column rejected;
- command while busy rejected;
- reset aborts operation and clears busy;
- `clk_sys -> clk_cfg_40m` request toggle cannot be lost;
- `clk_cfg_40m -> clk_sys` done toggle cannot be lost;
- no unstable multi-bit bus sampled directly;
- `Din/Cin` sequence uses `clk_cfg_40m`, not combinational clock gating.

## Integration Tests

- TDC-only event with delayed position queue full: no blockage.
- Position-only event while MPTDC busy: no blockage.
- BOTH event all four sources: contiguous bundle.
- Calibration selected one/two/three axes: no unused axis blockage.
- Mode transitions every pair of modes while idle.
- Mode transitions while an event is active drain old-mode resources before commit.
- Reset during matrix configuration.
- Reset during event lifecycle.
- Output pressure stops new event acceptance without losing accepted packets.

Implemented Phase 4/5 tests:

- `tb_spadmic_event_coordinator_modes_unit` covers mode masks, no fixed AND, frozen grant behavior, calibration matrix ignore, rejected-event cleanup reset, position-only event-ID allocation from raw snapshot validity, and the new requirement that selective reset waits for the position packetizer's snapshot copy in position-producing modes.
- `tb_spadmic_position_snapshot_packetizer_unit` covers 14-word raw packet generation, raw R/Y/B word ordering, fixed 8-word cluster packet generation, single-cluster and two-cluster images, 14-bit EOC event ID in both packet modes, snapshot-captured pulse behavior, and busy drop reporting.
- `tb_spadmic_event_bundle_tx_unit` covers deterministic R/Y/B/POSITION order, TDC source header patching, common event ID in all EOC words, missing-source error, and bundle flush.
- `tb_spadmic_top_matrix_v1_shell_unit` covers I2C/CSR, position-only matrix event acceptance, selective reset, raw bundle emission into DDR16, DDR drain, safe idle, matrix configuration after drain, inactive-TDC-safe-idle behavior in position-only mode, and TDC-only event flow through real MPTDC wrappers into the DDR16 bundle path.
- `tb_spadmic_matrix_cfg_ctrl_unit` covers returned-Cout qualified write/read/global-fill readback, column 0 and column 43 operations, invalid column rejection, command-while-busy rejection, reset abort, and Cout timeout/error behavior.
- `tb_spadmic_top_matrix_v1_shell_unit` includes a simple returned-Cout echo model so the top shell exercises the non-mirror matrix configuration path.

Implemented Phase 6 tests:

- `tb_spadmic_output_fifo_unit` covers synchronous FIFO reset, level/free-space, reserve almost-full threshold, push/pop ordering, full/overflow behavior, and simultaneous push/pop while full.
- `tb_spadmic_output_fifo_ddr_marker_unit` covers the top-level FIFO-to-DDR marker convention: two odd one-word bundles separated by ordered FIFO flush markers must serialize as independent padded DDR pairs, not as one cross-event pair.
- `tb_spadmic_matrix_top_csr_unit` covers implemented FIFO status fields, FIFO overflow sticky/count visibility, same-cycle overflow-versus-W1C priority, and W1C clearing through `MTOP_FAULT[4]`.
- `tb_spadmic_top_output_pressure_unit` is an explicit white-box pressure/fault-injection test. It forces top-level output-capacity state to prove that free space below the reservation blocks `pre_event_resources_ready`, the reservation boundary recovers, nonempty FIFO blocks `safe_idle`, and a pending FIFO flush marker blocks `safe_idle`.
- `tb_spadmic_top_matrix_v1_shell_unit` continues to pass with the FIFO inserted between bundle TX and DDR16 pairer.

Still required:

- Full top-level BOTH event simulation using real MPTDC packet completion and position packet completion in one bundle.
- Directed physical skew campaign across all R/Y/B arrival orders.
- Mode transition tests while old-mode producers are draining.
- Compact cluster position packets and a deeper position queue are deferred unless required after Phase 6 output FIFO integration.
- Cadence CDC/RDC and macro-timing review of the returned-Cout sampler remains required before any signoff claim.

## Directed Skew Campaign

Arrival orders:

- R -> Y -> B
- R -> B -> Y
- Y -> R -> B
- Y -> B -> R
- B -> R -> Y
- B -> Y -> R

Offsets:

- 0 ns;
- near `clk_sys` edge;
- near `clk_ref_40m` edge;
- small skew;
- medium skew;
- near snapshot watchdog;
- beyond snapshot watchdog.

## Assertions

Use simple simulation assertions where practical:

- at most one active event;
- active mode stable during event;
- required masks stable during event;
- reset mask stable while active;
- reset pulse exact width;
- no reset in calibration mode;
- no TDC dependency in position-only;
- no position dependency in TDC-only;
- one event ID per bundle;
- no source change mid-packet;
- no new event before prior event closes.

## Static Checks

- lint;
- CDC/RDC classification;
- reset recovery/removal review;
- no unintended latches;
- no unintended combinational clock gating;
- no broad false path hiding useful START-tree reporting;
- SDC coverage for active outputs;
- synchronizer preservation attributes;
- OR-tree path reports.

## Tool Limitations To Record

If a simulator or linter is unavailable, the Verifier report must record the exact command attempted and the failure. A missing tool is not a pass.
