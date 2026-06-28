# Matrix TOP Phase 2 Review

Status: VERIFIED after Verifier recheck.

## Metadata

- Branch: `SPADMIC_test`
- Base commit before Phase 2/3 edits: `0eb7c84e8b849b930b036f434a6511910c6446bc`
- Phase reviewed: Phase 2 - new matrix top shell
- Protected RTL status: no edits to `TOP/rtl/spadmic_top_v1.sv` or protected `MPTDC/rtl/*` internals.

## Files Reviewed

- `TOP/rtl/spadmic_top_matrix_v1.sv`
- `TOP/rtl/spadmic_matrix_snapshot_frontend.sv`
- `TOP/rtl/spadmic_pkg.sv`
- `TOP/filelist.f`
- `TOP/tb/tb_spadmic_top_matrix_v1_shell_unit.sv`
- `TOP/tb/tb_spadmic_matrix_snapshot_frontend_unit.sv`
- `TOP/ci/run_directed_regression.sh`
- `TOP/ci/run_tapeout_readiness.sh`

## Specification Points Checked

- final matrix shell exposes R/Y/B, Rz/Yz/Bz, Din/Cin/Dout/Cout, `clk_cfg_40m`, calibration inputs, and DDR16 boundary;
- old top remains intact;
- MPTDC internals remain protected;
- matrix config uses separate `clk_cfg_40m` controller through `spadmic_matrix_cfg_ctrl`;
- no final DDR8 path in the new matrix top;
- snapshot/event activity uses mode/direction masks rather than an unqualified fixed AND;
- Phase 2 shell intentionally blocks accepted normal events until Phase 4 integrates real MPTDC/position packet producers.

## Verifier Findings And Builder Response

| Severity | Finding | Builder response | Status |
| --- | --- | --- | --- |
| BLOCKER | Snapshot frontend was fixed-all-direction because the top did not provide mode/mask context. | Added `required_direction_mask_i` to `spadmic_matrix_snapshot_frontend`; `spadmic_top_matrix_v1` now derives `snapshot_required_direction_mask` from `active_mode` and `active_axis_mask`. | FIXED, VERIFIED |
| MEDIUM | Unrequired directions could still delay capture/rearm because `sample_changed` and rearm were all-bus predicates. | Made `sample_changed` and rearm required-mask-aware. Added test coverage for R+B required with Y absent/high. | FIXED, VERIFIED |
| LOW | New snapshot mask test was not in maintained gates. | Added `tb_spadmic_matrix_snapshot_frontend_unit` to directed regression and tapeout readiness Verilator list. | FIXED, VERIFIED |
| NOTE | DDR8 is not used by `spadmic_top_matrix_v1`; legacy DDR8 remains only for old top. | No RTL change required. | CLOSED |
| NOTE | Protected files were untouched. | Confirmed by `git diff`. | CLOSED |

## Tests Run

- `git diff --check`: PASS.
- `bash TOP/scripts/sim/run_tb.sh tb_spadmic_matrix_snapshot_frontend_unit --sim verilator`: PASS, 19 pass / 0 fail.
- `bash TOP/scripts/sim/run_tb.sh tb_spadmic_top_matrix_v1_shell_unit --sim verilator`: PASS, 13 pass / 0 fail.
- `bash TOP/ci/run_tapeout_readiness.sh`: PASS locally with 11 pass, 0 fail, 4 skipped.

## Final Verifier Recheck

Verifier reported no remaining BLOCKER, MEDIUM, or LOW findings from the prior pass. The mode-derived snapshot mask, masked `matrix_activity`, mask-aware frontend `sample_changed`/rearm predicates, and CI additions were all accepted.

Skipped readiness steps:

- Xcelium TOP smoke: `xrun` not found.
- Xcelium directed regression: `xrun` not found.
- Xcelium VIP smoke/feature suite: retired standalone VIP.

## Residual Risks

- Phase 2 shell is not a functional event readout top yet. `pre_event_resources_ready_i` remains intentionally false until Phase 4 connects MPTDC/position/output packet producers.
- Final 16-bit CSR address migration is not part of Phase 2.
- Final STA/CDC signoff for `clk_cfg_40m` and final matrix macro timing remains deferred until analog handoff.
