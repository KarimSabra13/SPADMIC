# Matrix TOP CSR16 And Shared TDC Review

## Metadata

- Branch: `SPADMIC_test`
- Base commit reviewed: `2b6fdfe6fd13842019a6d3b87543a91b50e9f657`
- Phase: CSR16 address migration and shared TDC configuration plumbing
- Status: Builder fixes applied; local recheck complete
- Protected boundaries: no changes allowed in protected MPTDC internals or `TOP/rtl/spadmic_top_v1.sv`

## Files Reviewed

- `TOP/rtl/spadmic_pkg.sv`
- `I2C/rtl/spadmic_i2c_slave.sv`
- `TOP/rtl/spadmic_matrix_top_csr.sv`
- `TOP/rtl/spadmic_top_matrix_v1.sv`
- `TOP/tb/tb_spadmic_matrix_top_csr_unit.sv`
- `TOP/tb/tb_spadmic_i2c_control_plane_unit.sv`
- `TOP/tb/tb_spadmic_top_matrix_v1_shell_unit.sv`
- `TOP/docs/12_FINAL_CSR_MAP_PROPOSAL.md`
- `TOP/docs/DECISIONS_LOG_MATRIX_TOP.md`

## Specification Points Checked

- Full 16-bit CSR address width in the matrix-top path.
- I2C pointer high byte is not truncated.
- Unsupported 16-bit addresses return a clean CSR error instead of low-12 aliasing.
- Shared `max_hits`, slow RO code, fast RO code, soft reset, and FIFO clear are CSR visible.
- Shared TDC configuration is wired to all three `spadmic_tdc_axis_wrapper` instances.
- Normal `TDC_ONLY` and `BOTH` still require axis mask `3'b111`.
- Partial axis masks are calibration-only through `CALIB_AXIS_MASK`.
- New implementation does not modify protected MPTDC internals or the protected legacy top.

## Verifier Findings

| Severity | Finding | Builder response | Status |
| --- | --- | --- | --- |
| HIGH | Calibration activity opened on any calibration START input, even when that axis was not selected by `active_axis_mask`. This could open a calibration event whose expected packet source never starts. | Masked `cal_activity` with `{B,Y,R}` calibration starts and `active_axis_mask` in `spadmic_top_matrix_v1.sv`. Added shell coverage for ignored unselected Y/B starts and selected R activity under calibration mask `3'b001`. | FIXED |
| MEDIUM | `POSITION_MODE`, `OUTPUT_FIFO_STATUS`, and `OUTPUT_FIFO_WATERMARKS` were active in the CSR implementation although the current code phase is CSR16/shared TDC. | Waived. The Phase 2 user requirements explicitly requested these CSR categories. They remain documented as placeholders where final position/FIFO behavior is not yet implemented. | WAIVED |
| LOW | Direct CSR alias/error coverage did not hit `0x1000`, `0x2000`, `0x3000`, and TX high-region unsupported addresses. | Added direct CSR tests for `0x1000`, `0x2000`, `0x3000`, valid `0x7000`, unsupported `0x700C`, and unsupported write `0x2A00`. | FIXED |
| LOW | Docs still had stale 12-bit/current-status language and omitted the updated I2C unit test. | Updated the decision log and CSR map proposal to describe the current CSR16 state, remaining legacy-decoder risk, placeholder CSRs, and the I2C unit test. | FIXED |

## Builder Fix Summary

- `spadmic_top_matrix_v1.sv`
  - Added `cal_start_vector`.
  - Changed `cal_activity` to require a selected calibration axis.
- `tb_spadmic_top_matrix_v1_shell_unit.sv`
  - Converted calibration pins from tied constants to driven test signals.
  - Added calibration mask checks for ignored unselected starts and selected start gating.
- `tb_spadmic_matrix_top_csr_unit.sv`
  - Added high-region CSR alias/error tests.
- `TOP/docs/12_FINAL_CSR_MAP_PROPOSAL.md`
  - Updated active CSR16 status and test coverage.
- `TOP/docs/DECISIONS_LOG_MATRIX_TOP.md`
  - Recorded CSR16/shared-TDC implementation and remaining limitations.

## Tests Run

- `git diff --check`: PASS
- `bash TOP/scripts/sim/run_tb.sh tb_spadmic_matrix_top_csr_unit --sim verilator`: PASS, 160 pass / 0 fail
- `bash TOP/scripts/sim/run_tb.sh tb_spadmic_i2c_control_plane_unit --sim verilator`: PASS, 16 pass / 0 fail
- `bash TOP/scripts/sim/run_tb.sh tb_spadmic_top_matrix_v1_shell_unit --sim verilator`: PASS, 32 pass / 0 fail
- `bash TOP/ci/run_tapeout_readiness.sh`: PASS, 14 pass / 0 fail / 4 skipped

## Remaining Risks

- `TOP/rtl/spadmic_csr_decoder.sv` still has legacy old-top decode assumptions. This is out of scope because `TOP/rtl/spadmic_top_v1.sv` is protected and the active target is `spadmic_top_matrix_v1`.
- `POSITION_MODE` is CSR visible but final raw/cluster position integration is a later phase.
- `OUTPUT_FIFO_STATUS` and `OUTPUT_FIFO_WATERMARKS` are CSR placeholders until the required 512-word output FIFO is inserted.
- Matrix configuration readback still needs the Cout-based physical path in the matrix configuration phase.
- Xcelium was skipped because `xrun` is not available locally.
- Genus, Innovus, CDC/RDC, and STA signoff were not run locally.

## Recheck Status

- Builder focused recheck: PASS.
- Full local readiness recheck: PASS with expected Xcelium/VIP skips.
- Final Verifier recheck: PASS. No remaining findings in scope.
