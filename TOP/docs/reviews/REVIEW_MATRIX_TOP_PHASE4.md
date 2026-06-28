# Matrix Top Phase 4 Review - MPTDC, Position, Event Integration

Date: 2026-06-28  
Branch: `SPADMIC_test`  
Reviewed HEAD: `0eb7c84e8b849b930b036f434a6511910c6446bc` plus local Phase 4 working-tree diff  
Status: VERIFIED for local RTL/unit/top-shell scope; final BOTH/skew campaign remains open.

## Files Reviewed

- `TOP/rtl/spadmic_top_matrix_v1.sv`
- `TOP/rtl/spadmic_event_coordinator.sv`
- `TOP/rtl/spadmic_position_snapshot_packetizer.sv`
- `TOP/rtl/spadmic_event_bundle_tx.sv`
- `TOP/rtl/spadmic_matrix_top_csr.sv`
- `TOP/tb/tb_spadmic_event_coordinator_modes_unit.sv`
- `TOP/tb/tb_spadmic_position_snapshot_packetizer_unit.sv`
- `TOP/tb/tb_spadmic_event_bundle_tx_unit.sv`
- `TOP/tb/tb_spadmic_top_matrix_v1_shell_unit.sv`
- `TOP/filelist.f`

## Specification Points Checked

- TDC-only does not wait for position packetization.
- Position-only does not wait for any TDC state.
- BOTH and calibration use mode-dependent source masks.
- Rejected/not-ready matrix events do not produce normal bundles and still clean up matrix lines.
- One physical event uses one 14-bit event ID across expected packets.
- TOP preserves the protected MPTDC product boundary.
- START gating is TOP-owned, skew-safe, and does not recompute a live all-ready gate after first START.

## Initial Verifier Findings

| Severity | Finding | Status |
| --- | --- | --- |
| BLOCKER | Rejected matrix events did not reset/clear matrix lines. | FIXED |
| BLOCKER | Existing correlated TX could not provide one event ID per physical event. | FIXED |
| BLOCKER | No bundle barrier before output. | FIXED |
| BLOCKER | TDC START gating was not frozen-grant safe. | FIXED |
| HIGH | Position path was still coupled to legacy position block ownership. | FIXED for raw v1 path |
| HIGH | `safe_idle` was not mode-aware and inactive paths could block CSR/config acceptance. | FIXED |
| MEDIUM | Normal TDC/BOTH accepted partial axis masks. | FIXED |

## Builder Fixes Reviewed

- Added cleanup-only rejected-event path in `spadmic_event_coordinator`.
- Added `spadmic_position_snapshot_packetizer` as a raw packet consumer of the protected matrix snapshot.
- Added `spadmic_event_bundle_tx` for deterministic masked bundle transmission and event-ID patching.
- Integrated three existing `spadmic_tdc_axis_wrapper` instances in `spadmic_top_matrix_v1` without editing MPTDC internals.
- Made `safe_idle` and `pre_event_resources_ready` mode-aware.
- Removed `stop_armed_o` from pre-event grant logic because it changes in response to START and is not a stable pre-event ready signal.
- Added one-shot per-axis TOP START gating after `tdc_start_seen_q` to prevent repeated conversions from held matrix lines.
- Restricted normal TDC-only/BOTH CSR mode writes to axis mask `3'b111`; partial masks remain calibration-only.

## Tests Run

- `bash TOP/scripts/sim/run_tb.sh tb_spadmic_event_coordinator_modes_unit --sim verilator`: PASS, 22 pass / 0 fail.
- `bash TOP/scripts/sim/run_tb.sh tb_spadmic_position_snapshot_packetizer_unit --sim verilator`: PASS, 10 pass / 0 fail.
- `bash TOP/scripts/sim/run_tb.sh tb_spadmic_event_bundle_tx_unit --sim verilator`: PASS, 14 pass / 0 fail.
- `bash TOP/scripts/sim/run_tb.sh tb_spadmic_matrix_top_csr_unit --sim verilator`: PASS, 95 pass / 0 fail.
- `bash TOP/scripts/sim/run_tb.sh tb_spadmic_top_matrix_v1_shell_unit --sim verilator`: PASS, 23 pass / 0 fail.

## Residual Risks

- BOTH-mode top-level event generation through real MPTDC packets and the position raw packet in the same bundle still needs a dedicated test.
- Directed R/Y/B skew campaign across all six arrival orders remains open.
- Shared TDC `max_hits` and RO-code CSR fields remain safe constants in the matrix top until the final CSR migration.
- Legacy cluster packetization is not yet snapshot-driven.

## Signoff

Phase 4 is signed off for local matrix-top shell implementation and maintained Verilator coverage. It is not final silicon signoff.
