# Review: Matrix TOP Xcelium Snapshot xcelium_matrix_top_20260630_0943

## Metadata

- Branch reviewed: `SPADMIC_test`
- Server run commit: `fe8f68712e5e6a3f990c996c3daf2b957613a889`
- Snapshot commit: `cfc42289`
- Run ID: `xcelium_matrix_top_20260630_0943`
- Xcelium version: `xrun(64) 23.03-s007`
- Snapshot source: `TOP/docs/server_snapshots/xcelium/xcelium_matrix_top_20260630_0943/`
- Review status: failing Xcelium snapshot analyzed; local portability fix prepared

## Snapshot Result

| Metric | Count |
| --- | ---: |
| PASS | 27 |
| FAIL | 4 |
| MISSING | 0 |

Failing tests:

- `tb_spadmic_top_matrix_v1_both_full_unit`
- `tb_spadmic_top_matrix_v1_skew_campaign`
- `tb_spadmic_top_reset_during_matrix_cfg_unit`
- `tb_spadmic_top_mode_transition_unit`

## Verifier Findings

| ID | Severity | Finding | Evidence | Builder Response | Status |
| --- | --- | --- | --- | --- | --- |
| XCELIUM-001 | HIGH | Three integration tests used unsized long timeout delays. Xcelium interpreted constants above 32-bit signed range as negative delays, so the timeout block fired at time 0. | `*W,TRNEGDEL` followed by `$fatal` at time 0 in `tb_spadmic_top_matrix_v1_both_full_unit`, `tb_spadmic_top_matrix_v1_skew_campaign`, and `tb_spadmic_top_mode_transition_unit`. | Cast long timeout delays to explicit 64-bit delay constants. Also audited nearby top-level/I2C tests with long timeouts. | FIXED LOCALLY, NEEDS SERVER RERUN |
| XCELIUM-002 | HIGH | `tb_spadmic_top_reset_during_matrix_cfg_unit` drove `saw_reset_error` from both an `always_ff` block and the main initial block. Xcelium correctly rejected this as multiple drivers on an `always_ff` output variable. | `xmelab: *E,MULAXX ... Multiple drivers to always_ff output variable saw_reset_error detected.` | Removed the initial-block assignment. The flag is now owned by the reset/error tracking process. | FIXED LOCALLY, NEEDS SERVER RERUN |
| XCELIUM-003 | NOTE | Server working tree contains many unrelated untracked Cadence artifacts. The snapshot commit staged only the curated snapshot directory, so no source contamination occurred, but future server commands must keep staging explicit. | `git_status_short.txt` contains many untracked `.GenusRestruct`, MPTDC PnR, logs, reports, and scheduling files. | Continue using `git add TOP/docs/server_snapshots/...` only. Do not clean or delete server-owned files from Codex. | OPEN NOTE |

## Files Fixed Locally

- `TOP/tb/tb_spadmic_top_matrix_v1_both_full_unit.sv`
- `TOP/tb/tb_spadmic_top_matrix_v1_skew_campaign.sv`
- `TOP/tb/tb_spadmic_top_mode_transition_unit.sv`
- `TOP/tb/tb_spadmic_top_reset_during_matrix_cfg_unit.sv`
- `TOP/tb/tb_spadmic_top_reset_during_event_unit.sv`
- `TOP/tb/tb_spadmic_top_matrix_v1_shell_unit.sv`
- `TOP/tb/tb_spadmic_top_output_fifo_pressure_integration_unit.sv`
- `TOP/tb/tb_spadmic_i2c_matrix_top_16b_unit.sv`

## Local Recheck

Local tools available: Verilator only. Xcelium is not installed locally.

| Check | Result |
| --- | --- |
| `git diff --check` | PASS |
| Protected MPTDC/legacy-top diff check | PASS, no protected files changed |
| `tb_spadmic_top_matrix_v1_both_full_unit --sim verilator` | PASS, 9 pass / 0 fail |
| `tb_spadmic_top_matrix_v1_skew_campaign --sim verilator` | PASS, 139 pass / 0 fail |
| `tb_spadmic_top_reset_during_matrix_cfg_unit --sim verilator` | PASS, 5 pass / 0 fail |
| `tb_spadmic_top_mode_transition_unit --sim verilator` | PASS, 6 pass / 0 fail |
| `bash TOP/ci/run_tapeout_readiness.sh` | PASS, 33 pass / 0 fail / 4 skipped |

Expected local skips:

- Xcelium TOP smoke: `xrun` not found locally.
- Xcelium directed regression: `xrun` not found locally.
- Retired standalone VIP smoke.
- Retired standalone VIP feature suite.

## Required Next Gate

Rerun `TOP/ci/server_run_matrix_top_xcelium.sh` on the Cadence server after the fix commit is pushed.

Do not treat this review as Xcelium closure until a new server snapshot shows:

- no `TRNEGDEL` time-zero timeout failures;
- no `MULAXX` elaboration failure;
- all matrix-top required tests pass or any remaining failure has a new root-cause review.

## Signoff Limitations

This review is functional simulation triage only.

It is not:

- CDC/RDC signoff;
- Genus or STA closure;
- Innovus physical closure;
- MMMC;
- extracted timing;
- DRC/LVS/PEX;
- DDR macro timing signoff;
- matrix macro timing signoff.
