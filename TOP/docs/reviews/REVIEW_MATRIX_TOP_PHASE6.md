# Matrix Top Phase 6 Review - Regression, Hygiene, And Signoff Limits

Date: 2026-06-28  
Branch: `SPADMIC_test`  
Reviewed HEAD: `0eb7c84e8b849b930b036f434a6511910c6446bc` plus local Phase 6 working-tree diff  
Status: VERIFIED for local maintained Verilator readiness; final silicon signoff remains open.

## Files Reviewed

- `TOP/ci/run_tapeout_readiness.sh`
- `TOP/ci/run_directed_regression.sh`
- `TOP/scripts/sim/run_tb.sh`
- `TOP/docs/DECISIONS_LOG_MATRIX_TOP.md`
- `TOP/docs/11_FINAL_TOP_RESET_CONTROL_PLAN.md`
- `TOP/docs/12_FINAL_CSR_MAP_PROPOSAL.md`
- `TOP/docs/16_TOP_IMPLEMENTATION_PHASES.md`
- `TOP/docs/17_VERIFICATION_PLAN_MATRIX_TOP.md`
- Phase 4/5 RTL and tests listed in the corresponding review reports.

## Checks Run

- `git diff --check`: PASS.
- `bash TOP/scripts/sim/run_tb.sh tb_spadmic_event_coordinator_modes_unit --sim verilator`: PASS, 22 pass / 0 fail.
- `bash TOP/scripts/sim/run_tb.sh tb_spadmic_position_snapshot_packetizer_unit --sim verilator`: PASS, 10 pass / 0 fail.
- `bash TOP/scripts/sim/run_tb.sh tb_spadmic_event_bundle_tx_unit --sim verilator`: PASS, 14 pass / 0 fail.
- `bash TOP/scripts/sim/run_tb.sh tb_spadmic_matrix_top_csr_unit --sim verilator`: PASS, 95 pass / 0 fail.
- `bash TOP/scripts/sim/run_tb.sh tb_spadmic_top_matrix_v1_shell_unit --sim verilator`: PASS, 23 pass / 0 fail.
- `bash TOP/ci/run_tapeout_readiness.sh`: PASS, 14 pass / 0 fail / 4 skipped.

## Readiness Gate Details

The readiness script now performs:

- Verilator lint for legacy `spadmic_top_v1`: PASS.
- Verilator lint for new `spadmic_top_matrix_v1`: PASS.
- Maintained Verilator units including ARB, I2C, snapshot, raw position packetizer, bundle TX, matrix-top CSR, matrix top shell, sequencer, stress CSR, stress position, and legacy DDR8 test: PASS.

Skipped readiness steps:

- Xcelium TOP smoke: `xrun` not found.
- Xcelium directed regression: `xrun` not found.
- Xcelium VIP smoke: retired standalone VIP.
- Xcelium VIP feature suite: retired standalone VIP.

## Protected Boundary Check

- `TOP/rtl/spadmic_top_v1.sv` remains unmodified.
- Protected MPTDC internals remain unmodified.
- Root reference files `ParameterDefs.sv`, `multi_ShiftRegisterChain_cfg_v1.sv`, and `pixel_readout.pdf` remain untracked and untouched as user-owned references.

## Findings

| Severity | Finding | Status |
| --- | --- | --- |
| HIGH | `safe_idle` not mode-aware in earlier Phase 4/5 diff. | FIXED |
| HIGH | `stop_armed_o` used as live pre-event grant input, causing first START to collapse acceptance. | FIXED |
| HIGH | Held matrix lines could retrigger same-axis MPTDC conversions during one event. | FIXED |
| MEDIUM | Readiness CI lacked matrix-top lint. | FIXED |
| MEDIUM | BOTH-mode top-level event test still missing. | DEFERRED |
| MEDIUM | Shared TDC config CSRs not fully migrated. | DEFERRED |

## Independent Verifier Recheck

Subagent Verifier rechecked the final fixes read-only and reported:

- no BLOCKER, HIGH, or MEDIUM findings remain for the requested Phase 4/5/6 scope;
- `git diff --check`: PASS;
- Verilator lint for `spadmic_top_v1`: PASS;
- Verilator lint for `spadmic_top_matrix_v1`: PASS;
- `tb_spadmic_top_matrix_v1_shell_unit`: PASS, 23 pass / 0 fail;
- protected MPTDC internals and `TOP/rtl/spadmic_top_v1.sv` remain unmodified.

## Signoff Limits

This review does not claim:

- final MMMC timing;
- extracted timing;
- CDC/RDC tool signoff;
- DRC/LVS/PEX;
- final DDR macro timing;
- final matrix macro timing;
- final board timing;
- final analog reset/config electrical signoff.

## Signoff

Phase 6 is signed off for the local implementation scope and maintained Verilator readiness. Remaining risks are documented and are not waived as silicon signoff.
