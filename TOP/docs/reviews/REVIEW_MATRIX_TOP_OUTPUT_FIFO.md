# Review Matrix Top Output FIFO

Status: Verifier signed off for local Phase 6 scope.

## Metadata

- Branch: `SPADMIC_test`
- Base commit reviewed: `1569c9b82216651a01df0c46f829fd8574543718`
- Phase: output FIFO and event admission control
- Date: `2026-06-28`
- Scope: local Verilator/open-source review only. Xcelium, CDC/RDC, Genus,
  Innovus, extracted timing, and macro timing were not run locally.

## Files Reviewed

- `TOP/rtl/spadmic_output_fifo.sv`
- `TOP/rtl/spadmic_top_matrix_v1.sv`
- `TOP/rtl/spadmic_matrix_top_csr.sv`
- `TOP/tb/tb_spadmic_output_fifo_unit.sv`
- `TOP/tb/tb_spadmic_output_fifo_ddr_marker_unit.sv`
- `TOP/tb/tb_spadmic_matrix_top_csr_unit.sv`
- `TOP/tb/tb_spadmic_top_output_pressure_unit.sv`
- `TOP/filelist.f`
- `TOP/ci/run_tapeout_readiness.sh`
- `TOP/docs/DECISIONS_LOG_MATRIX_TOP.md`
- `TOP/docs/12_FINAL_CSR_MAP_PROPOSAL.md`
- `TOP/docs/14_DDR16_TX_MACRO_CONTRACT.md`
- `TOP/docs/17_VERIFICATION_PLAN_MATRIX_TOP.md`
- `TOP/docs/19_MATRIX_TOP_NEXT_STEPS_TO_ASIC.md`

## Builder Summary

- Added `spadmic_output_fifo`, a synchronous `clk_sys` FIFO with 512-entry top
  integration, level/free-space reporting, reserve almost-full status, and
  overflow pulse.
- Inserted the FIFO between `spadmic_event_bundle_tx` and
  `spadmic_ddr16_tx_pairer`.
- Changed pre-event resource admission to require enough FIFO entries for the
  128-word logical bundle estimate plus one ordered flush marker.
- Converted bundle `flush_o` into an ordered internal FIFO marker. This avoids
  pairing an odd final word from one bundle with the first word of a later
  bundle.
- Updated `safe_idle` to include FIFO empty state and pending flush-marker
  state in addition to bundle and DDR pairer state.
- Added CSR visibility for FIFO empty/full/almost-full, level, free entries,
  overflow sticky, and overflow counter.
- Added W1C clearing for output FIFO overflow at `MTOP_FAULT[4]`.

## Specification Points Checked

- Output FIFO exists between bundle TX and DDR16 pairer: PASS.
- New event admission depends on output free-space reservation: PASS.
- Accepted packet words are not silently dropped when FIFO is full: PASS by
  ready/valid review and FIFO unit test.
- Bundle boundary flush is ordered with the data stream: PASS after Builder fix
  from pending-bit-to-marker design.
- `safe_idle` includes output FIFO and DDR pairer drain state: PASS.
- CSR reports FIFO status and fault visibility: PASS.
- Protected MPTDC internals untouched: PASS by diff scope.
- `TOP/rtl/spadmic_top_v1.sv` untouched: PASS by diff scope.

## Tests Run

| Test | Result |
| --- | --- |
| `bash TOP/scripts/sim/run_tb.sh tb_spadmic_output_fifo_unit --sim verilator` | PASS, 17 pass / 0 fail |
| `bash TOP/scripts/sim/run_tb.sh tb_spadmic_output_fifo_ddr_marker_unit --sim verilator` | PASS, 17 pass / 0 fail |
| `bash TOP/scripts/sim/run_tb.sh tb_spadmic_matrix_top_csr_unit --sim verilator` | PASS, 190 pass / 0 fail |
| `bash TOP/scripts/sim/run_tb.sh tb_spadmic_top_output_pressure_unit --sim verilator` | PASS, 6 pass / 0 fail |
| `bash TOP/scripts/sim/run_tb.sh tb_spadmic_top_matrix_v1_shell_unit --sim verilator` | PASS, 32 pass / 0 fail |
| `bash TOP/ci/run_tapeout_readiness.sh` | PASS, 17 pass / 0 fail / 4 skipped |

## Findings

| Severity | Finding | Builder Response | Status |
| --- | --- | --- | --- |
| HIGH | Initial draft held `flush_o` outside the FIFO until the FIFO drained. That could allow future odd bundle lengths to pair the last word of event N with the first word of event N+1. | Replaced external pending flush with an ordered FIFO marker bit. Pairer receives marker in stream order. | FIXED |
| MEDIUM | Output FIFO overflow sticky was initially reset-only. User policy expects sticky faults to be W1C where practical. | Added `MTOP_FAULT[4]` W1C clear and tests. | FIXED |
| MEDIUM | Verifier found that a same-cycle `MTOP_FAULT[4]` W1C clear could clear a new FIFO overflow pulse in the original CSR update order. | Made new overflow set-dominant over W1C clear and added a CSR unit check for same-cycle overflow-versus-clear priority. | FIXED |
| MEDIUM | Verifier found that the original tests did not prove the ordered FIFO flush marker prevents odd bundle cross-pairing at the DDR16 pairer boundary. | Added `tb_spadmic_output_fifo_ddr_marker_unit` and inserted it into the readiness script. | FIXED |
| LOW | The first draft of this review marked Verifier signoff before the recheck of the two Phase 6 fixes. | Corrected status and will update this section after Verifier recheck. | FIXED |
| LOW | Current DDR macro has no ready/backpressure contract, so local tests can only prove FIFO admission/status and the current pairer consumption path. | Documented macro-boundary limitation and kept future wrapper update explicit. | DEFERRED |
| NOTE | FIFO level/free-space counts internal flush markers as entries. | Documented in CSR and DDR contract docs. Admission now uses a 129-entry reserve. | CLOSED |

## Remaining Risks

- This is not Xcelium evidence.
- This is not CDC/RDC signoff.
- This is not Genus/STA/Innovus evidence.
- The final DDR macro contract may require per-half valid or ready/enable
  support, which would update the pairer/FIFO boundary.
- Full BOTH-mode and directed skew campaigns remain required local/server tests.

## Verifier Status

Verifier signoff for this phase is complete for the local/open-source scope:

- Full local readiness passed with 17 pass, 0 fail, and 4 expected local skips.
- Verifier recheck found no remaining BLOCKER, HIGH, MEDIUM, or LOW findings.
- The same-cycle overflow-versus-W1C priority and ordered FIFO marker coverage
  findings are fixed.
- Skips are expected local limitations: `xrun` unavailable and retired VIP
  suites.
- Protected MPTDC internals and `TOP/rtl/spadmic_top_v1.sv` have no local diff.

This does not close Xcelium, CDC/RDC, Genus, Innovus, DDR macro timing, or
matrix macro timing.
