# Matrix TOP Phase 3 Review

Status: VERIFIED after Verifier recheck.

## Metadata

- Branch: `SPADMIC_test`
- Base commit before Phase 2/3 edits: `0eb7c84e8b849b930b036f434a6511910c6446bc`
- Phase reviewed: Phase 3 - CSR and I2C integration for `spadmic_top_matrix_v1`
- Protected RTL status: no edits to `TOP/rtl/spadmic_top_v1.sv` or protected `MPTDC/rtl/*` internals.

## Files Reviewed

- `TOP/rtl/spadmic_matrix_top_csr.sv`
- `TOP/rtl/spadmic_top_matrix_v1.sv`
- `TOP/rtl/spadmic_pkg.sv`
- `TOP/tb/tb_spadmic_matrix_top_csr_unit.sv`
- `TOP/tb/tb_spadmic_top_matrix_v1_shell_unit.sv`
- `TOP/ci/run_directed_regression.sh`
- `TOP/ci/run_tapeout_readiness.sh`

## Specification Points Checked

- I2C remains simple one-transaction-at-a-time command/status control;
- long matrix configuration operations are autonomous and are not held open by I2C;
- matrix config commands cross to the separate `clk_cfg_40m` domain only through `spadmic_matrix_cfg_ctrl`;
- busy and unsafe writes are rejected with CSR error response and sticky/counter status;
- W1C fault clearing works;
- matrix config command/status/readback registers are CSR-visible;
- final 16-bit CSR map remains documented as a later migration because active RTL still uses 12-bit internal addresses.

## Verifier Findings And Builder Response

| Severity | Finding | Builder response | Status |
| --- | --- | --- | --- |
| HIGH | Matrix config CSR writes were gated only by `matrix_cfg_busy_i`, allowing reconfiguration during event/snapshot/reset activity. | Added `cfg_path_safe = safe_idle_i && !transition_busy_i && !event_busy_i && !snapshot_busy_i && !reset_busy_i`; `MATRIX_CFG_CMD/COL/WDATA_*` now reject unsafe writes with `CMD_ERR_PATH_BUSY` and reject active config with `CMD_ERR_BUSY`. | FIXED, verified by first recheck |
| MEDIUM | Rejected config command writes changed `MATRIX_CFG_CMD` opcode readback. | Moved `matrix_cfg_cmd_op_q` update into accepted command path only. Tests check opcode remains unchanged after busy and path-busy rejected command writes. | FIXED, verified by first recheck |
| MEDIUM | New CSR/top tests were not in maintained regression gates. | Added `tb_spadmic_matrix_top_csr_unit` and `tb_spadmic_top_matrix_v1_shell_unit` to directed regression and tapeout readiness Verilator list. | FIXED, verified by first recheck |

## Tests Run

- `git diff --check`: PASS.
- `bash TOP/scripts/sim/run_tb.sh tb_spadmic_matrix_top_csr_unit --sim verilator`: PASS, 87 pass / 0 fail.
- `bash TOP/scripts/sim/run_tb.sh tb_spadmic_top_matrix_v1_shell_unit --sim verilator`: PASS, 13 pass / 0 fail.
- `bash TOP/scripts/sim/run_tb.sh tb_spadmic_matrix_cfg_ctrl_unit --sim verilator`: PASS, 32 pass / 0 fail.
- `bash TOP/ci/run_tapeout_readiness.sh`: PASS locally with 11 pass, 0 fail, 4 skipped.

## Final Verifier Recheck

Verifier reported no remaining Phase 3 findings. The config safe-idle gating, busy/path-busy error split, rejected-command readback stability, and maintained-gate additions were accepted.

Skipped readiness steps:

- Xcelium TOP smoke: `xrun` not found.
- Xcelium directed regression: `xrun` not found.
- Xcelium VIP smoke/feature suite: retired standalone VIP.

## Residual Risks

- Phase 3 implements the new matrix-top CSR endpoint with the current internal 12-bit address width. The final external 16-bit map remains a later compatibility migration.
- The CSR endpoint commits requested/active mode immediately on safe-idle writes in this shell. Full requested-versus-active drain sequencing across real packet producers remains Phase 4.
- Matrix config timing remains non-signoff until final macro setup/hold/min high/min low/Dout-Cout handoff is available.
