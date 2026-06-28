# Phase 5 Review - Matrix Config Returned-Cout Readback

Status: Verifier signed off for Phase 5 commit with documented non-signoff CDC/RDC and macro-timing limitations.

## Scope

Phase 5 replaces the temporary write-data mirror readback behavior in the matrix configuration controller with a returned-`Cout` qualified `Dout` readback model.

Reviewed working tree base:

- Branch: `SPADMIC_test`
- Base commit before Phase 5 commit: `d0489282b16e9685045c46aecb9fbd90aa76ae93`
- Protected RTL policy: no MPTDC internals and no legacy `TOP/rtl/spadmic_top_v1.sv` edits.

## Files Reviewed

- `TOP/rtl/spadmic_matrix_cfg_ctrl.sv`
- `TOP/tb/tb_spadmic_matrix_cfg_ctrl_unit.sv`
- `TOP/tb/tb_spadmic_top_matrix_v1_shell_unit.sv`
- `TOP/docs/DECISIONS_LOG_MATRIX_TOP.md`
- `TOP/docs/12_FINAL_CSR_MAP_PROPOSAL.md`
- `TOP/docs/13_MATRIX_CONFIG_AND_RESET_CONTRACT.md`
- `TOP/docs/17_VERIFICATION_PLAN_MATRIX_TOP.md`
- `TOP/docs/19_MATRIX_TOP_NEXT_STEPS_TO_ASIC.md`

## Builder Summary

- Added a per-column returned-`Cout` sampler in `spadmic_matrix_cfg_ctrl`.
- `WRITE_COLUMN_64` now pulses selected `Cin[col]`, waits for returned `Cout[col]`, and samples `Dout[col]`.
- `READ_COLUMN_64` samples selected `Dout[col]` on returned `Cout[col]`.
- `GLOBAL_FILL_0/1` drive all columns and use column 0 as the readback reference.
- Missing returned `Cout` raises `ERR_COUT_TIMEOUT`, clears `readback_valid`, clears `matrix_cfg_valid`, and idles physical config outputs.
- The top shell test now includes a simple returned-`Cout` echo model.
- Documentation explicitly marks returned-`Cout` capture as CDC/RDC and non-signoff until matrix macro timing and Cadence CDC/RDC review are available.

## Tests Run

| Command | Result |
| --- | --- |
| `bash TOP/scripts/sim/run_tb.sh tb_spadmic_matrix_cfg_ctrl_unit --sim verilator` | PASS, 36 pass / 0 fail |
| `bash TOP/scripts/sim/run_tb.sh tb_spadmic_top_matrix_v1_shell_unit --sim verilator` | PASS, 32 pass / 0 fail |
| `bash TOP/ci/run_tapeout_readiness.sh` | PASS, 14 pass / 0 fail / 4 skipped |
| `bash TOP/scripts/sim/run_tb.sh tb_spadmic_matrix_cfg_ctrl_unit` | FAIL as expected locally: `xrun` not found |
| `bash TOP/scripts/sim/run_tb.sh tb_spadmic_top_matrix_v1_shell_unit` | FAIL as expected locally: `xrun` not found |
| `git diff --check` | PASS |

Skipped local readiness items:

- Xcelium TOP smoke: `xrun` not found locally.
- Xcelium directed regression: `xrun` not found locally.
- Retired standalone VIP smoke/feature suite.

## Verifier Findings

| Severity | Finding | Builder Response | Status |
| --- | --- | --- | --- |
| MEDIUM | A direct `cmd_start_i` pulse on the same `clk_sys` edge as config completion could overwrite returned completion status/readback because the command-start block executed after `sys_done_seen`. | Fixed by making completion assignment the final priority in the `clk_sys` sequential block, so returned status/readback cannot be corrupted. CSR already starts only when not busy. Focused matrix-config unit test rerun passed 36/0. | FIXED |
| LOW | `TOP/docs/12_FINAL_CSR_MAP_PROPOSAL.md` was updated even though it was not in the initial Phase 5 file list. | Kept intentionally because it contained stale statements saying Cout readback was still future Phase 5 work. | FIXED |
| NOTE | Root reference files remain untracked. | They are user-owned references and are not staged. | OPEN NOTE |

Verifier recheck result:

- No remaining BLOCKER, HIGH, or MEDIUM findings.
- Phase 5 is acceptable to commit with the documented limitations.

## CDC/RDC Risks

- Returned `Cout` acts as a macro-return strobe and is not treated as ordinary synchronous `clk_cfg_40m` data.
- `Dout[col]` is captured in a per-column returned-`Cout` event domain, then a capture toggle/data pair is synchronized into `clk_cfg_40m`.
- The command/return path between `clk_sys` and `clk_cfg_40m` remains a stable-bus plus toggle handshake.
- This review is not a CDC/RDC signoff. Cadence CDC/RDC and STA classification are still required.

## STA/PnR Risks

- `Cout` timing, `Dout` setup/hold to returned `Cout`, returned-Cout latency, and reset behavior remain matrix macro handoff items.
- `COUT_TIMEOUT_CYCLES=16` is a simulation/bring-up placeholder, not a signed-off macro timing bound.
- The returned-`Cout` sampler and Dout capture should be placed near the top matrix config pins once floorplan scripts are active.

## Protocol And Mode Impact

- CSR readback now reflects returned-`Cout` sampled data instead of write-data mirror behavior.
- Long operations remain command/status based; I2C transactions are not held open.
- Selective matrix reset remains independent from matrix configuration; selective reset does not clear configuration.
- No extra debug pads were added.

## Protected Boundary Check

- No tracked diff under protected MPTDC internals.
- No tracked diff in `TOP/rtl/spadmic_top_v1.sv`.
- Untracked root reference files are not included in this phase.

## Signoff Limitations

- Verilator pass is not Xcelium pass.
- Xcelium was not run locally because `xrun` is unavailable.
- No CDC/RDC tool was run.
- No Genus/Innovus run was performed.
- Matrix configuration timing is not final without analog matrix handoff.
- No final silicon signoff is claimed.
