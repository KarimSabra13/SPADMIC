# Matrix Top Phase 4 Position Full Review

## Metadata

- Branch: `SPADMIC_test`
- Base before phase: `b50952c5e46491b41e9a80eba5948baa52fc6ad2`
- Phase: Position raw/cluster integration from frozen matrix snapshots
- Status: Builder implemented; Verifier review pending at document creation
- Protected-boundary check: no intended edits to protected MPTDC internals or `TOP/rtl/spadmic_top_v1.sv`

## Builder Scope

Files changed:

- `TOP/rtl/spadmic_position_snapshot_packetizer.sv`
- `TOP/rtl/spadmic_event_coordinator.sv`
- `TOP/rtl/spadmic_top_matrix_v1.sv`
- `TOP/tb/tb_spadmic_position_snapshot_packetizer_unit.sv`
- `TOP/tb/tb_spadmic_event_coordinator_modes_unit.sv`
- `TOP/docs/DECISIONS_LOG_MATRIX_TOP.md`
- `TOP/docs/17_VERIFICATION_PLAN_MATRIX_TOP.md`
- `TOP/docs/19_MATRIX_TOP_NEXT_STEPS_TO_ASIC.md`
- `TOP/docs/reviews/REVIEW_MATRIX_TOP_POSITION_FULL.md`

## Builder Design Notes

- The matrix-top position path remains snapshot-owned. It consumes `snapshot_R/Y/B` from `spadmic_matrix_snapshot_frontend` and does not re-detect asynchronous matrix pins.
- `spadmic_position_snapshot_packetizer` now supports:
  - `SPADMIC_POS_MODE_RAW`: 14-word raw bitmap packet.
  - `SPADMIC_POS_MODE_CLUSTER`: fixed 8-word cluster packet using three `spadmic_axis_cluster_scan` instances.
- Cluster defaults in the matrix top are:
  - `gap_threshold = 2`.
  - `min_cluster_span = 1`, so ideal one-bit-per-axis diode events are not filtered out.
- Compact cluster packets and a deeper position queue remain deferred. The matrix top still permits one physical event in flight.
- The packetizer asserts `snapshot_captured_o` when it copies the frozen bitmap into private registers.
- In position-producing modes, `spadmic_event_coordinator` now treats the raw snapshot reset-ack bit as true only after `snapshot_valid_i` and `position_snapshot_captured_i` are both true.
- Position-only event ID allocation still uses raw snapshot validity, so position-only mode does not deadlock waiting for its own packetizer start.

## Builder Tests

Local tools only. Xcelium is server-only and was not run locally.

- `bash TOP/ci/run_tapeout_readiness.sh`
  - Result: 14 pass, 0 fail, 4 skipped.
  - Skips: Xcelium smoke/directed regression because `xrun` is not installed locally; retired VIP smoke/features.
- Manual Verilator packetizer unit with workspace-local `CCACHE_DIR`
  - Result after Verifier fixes: 25 pass, 0 fail.
  - Covers raw packet, cluster packet, multi-cluster image, snapshot-captured pulse, busy drop.
- Manual Verilator coordinator unit with workspace-local `CCACHE_DIR`
  - Result: 24 pass, 0 fail.
  - Covers position-only ID allocation before reset, reset waits for position snapshot copy, no TDC dependency in position-only, no position dependency in TDC-only.
- Final post-fix `bash TOP/ci/run_tapeout_readiness.sh`
  - Result: 14 pass, 0 fail, 4 skipped.
  - Skips: Xcelium smoke/directed regression because `xrun` is not installed locally; retired VIP smoke/features.
- `bash TOP/scripts/sim/run_tb.sh tb_spadmic_position_snapshot_packetizer_unit`
  - Result: expected local failure, `xrun: command not found`.
  - Interpretation: not a design failure; Xcelium tests must be run on the Cadence server.

## Verifier Findings

Independent static review:

- NOTE: no blocker/high/medium/low findings in the scoped five-file Phase 4 diff. The reviewer confirmed frozen snapshot ownership, raw/cluster CSR selection, reset wait for position copy, position-only no-TDC behavior, TDC-only no-position behavior, 14-bit common EOC event ID, no START-path skew change, and no protected-boundary edits.

Independent synthesis-risk review:

- HIGH, FIXED: `packet_pending_o` was true only in `POS_SEND`, not while a cluster packet was being scanned. Builder changed `packet_pending_o` to cover all non-idle accepted packet states and added a unit check for pending during cluster scan.
- MEDIUM, FIXED: noncompact cluster header did not encode `multi_cluster_mask` even though the packetizer computed it. Builder encoded the mask in reserved header bits `[2:0]`, matching compact header placement, updated the position VIP parser, and added a direct unit check.
- MEDIUM, DEFERRED TO GENUS OOC: the packetizer uses packed-struct helper functions for cluster filtering. Verilator lint/sim accepts this, but Genus OOC must explicitly check elaboration and mapped QoR for `spadmic_axis_clusters_t` function returns and struct field writes.
- LOW, CLOSED: reset gating assumes the top preserves the packetizer one-cycle capture pulse. The matrix top latches `pos_snapshot_captured_seen_q`, and the coordinator unit test covers reset waiting until that latch/pulse is true.

## Residual Risks

- Full top-level BOTH event with real MPTDC wrappers and position cluster packet in one bundle is still required.
- Directed R/Y/B skew campaign is still required.
- Cluster mode uses a fixed 8-word packet. Compact cluster mode is deferred.
- Position queuing remains deferred because the matrix-top v1 coordinator admits only one physical event in flight.
- Matrix configuration true Cout-based readback and output FIFO remain later phases.
