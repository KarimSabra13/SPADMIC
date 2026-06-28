# Matrix Top Phase 5 Review - Event Bundle And DDR16 Output

Date: 2026-06-28  
Branch: `SPADMIC_test`  
Reviewed HEAD: `0eb7c84e8b849b930b036f434a6511910c6446bc` plus local Phase 5 working-tree diff  
Status: VERIFIED for local RTL/unit/top-shell scope; final DDR macro handoff remains non-signoff.

## Files Reviewed

- `TOP/rtl/spadmic_event_bundle_tx.sv`
- `TOP/rtl/spadmic_ddr16_tx_pairer.sv`
- `TOP/rtl/spadmic_top_matrix_v1.sv`
- `TOP/rtl/spadmic_matrix_top_csr.sv`
- `TOP/tb/tb_spadmic_event_bundle_tx_unit.sv`
- `TOP/tb/tb_spadmic_ddr16_tx_pairer_unit.sv`
- `TOP/tb/tb_spadmic_top_matrix_v1_shell_unit.sv`
- `TOP/ci/run_tapeout_readiness.sh`

## Specification Points Checked

- Final matrix top does not use the obsolete 8-bit DDR path.
- DDR16 pairer receives logical 16-bit words and emits `DATA_L/DATA_H` pairs without dual-edge procedural RTL.
- Bundle TX waits for the required packet mask and never waits for inactive sources.
- EOC words are patched to the coordinator-owned event ID.
- Bundle output is contiguous relative to one event.
- Pairer flush handles odd final word padding.
- Output busy/empty contributes to safe idle.

## Initial Verifier Findings

| Severity | Finding | Status |
| --- | --- | --- |
| BLOCKER | No bundle barrier; old arbiter/correlated TX could interleave policy incorrectly. | FIXED |
| BLOCKER | Old correlated TX incremented IDs per packet. | FIXED by new bundle path |
| MEDIUM | DDR16 pairer was not integrated with EOP/flush. | FIXED |
| MEDIUM | Readiness CI did not lint the new matrix top. | FIXED |

## Builder Fixes Reviewed

- Connected `spadmic_event_bundle_tx` to `spadmic_ddr16_tx_pairer`.
- Added deterministic R/Y/B/POSITION source order for debug readability.
- Patched TDC headers with source ID and patched all EOC words with one physical event ID.
- Added `flush_o` from bundle TX to DDR16 pairer.
- Added `TX_STATUS` bits for bundle missing-source and position packet drop diagnostics.
- Updated readiness CI to lint both `spadmic_top_v1` and `spadmic_top_matrix_v1`.

## Tests Run

- `bash TOP/scripts/sim/run_tb.sh tb_spadmic_event_bundle_tx_unit --sim verilator`: PASS, 14 pass / 0 fail.
- `bash TOP/scripts/sim/run_tb.sh tb_spadmic_ddr16_tx_pairer_unit --sim verilator`: PASS.
- `bash TOP/scripts/sim/run_tb.sh tb_spadmic_top_matrix_v1_shell_unit --sim verilator`: PASS, 23 pass / 0 fail.
- `bash TOP/ci/run_tapeout_readiness.sh`: PASS, 14 pass / 0 fail / 4 skipped.

Skipped readiness steps:

- Xcelium TOP smoke: `xrun` not found.
- Xcelium directed regression: `xrun` not found.
- Xcelium VIP smoke and feature suite: retired standalone VIP.

## Residual Risks

- DDR macro port list, `DATA_L/DATA_H` edge mapping, valid semantics, reset behavior, and timing remain TBD from macro designer.
- No final board timing or DDR output timing signoff is claimed.
- Legacy `spadmic_ddr_tx` remains for `spadmic_top_v1` only and is still covered by the legacy unit test.

## Signoff

Phase 5 is signed off for local matrix-top RTL integration and maintained Verilator coverage. It is not final DDR macro signoff.
