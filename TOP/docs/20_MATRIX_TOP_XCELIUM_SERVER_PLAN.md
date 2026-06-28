# SPADMIC Matrix TOP Xcelium Server Plan

Status: server execution plan only. Xcelium is not available locally.

## Metadata

- Branch: `SPADMIC_test`
- Baseline commit for this plan: `5cdf489fbfb0a13e1a5ee7f5a253002e023602ac`
- Server repo path: `/home/validmgr/ksabra/2026_SPAD/SPADMIC`
- Cadence environment: `source /eda/cadence/eda_2023-2024`
- Work root: `/sim/ksabra/SPADMIC_work`
- Xcelium output root: `/sim/ksabra/SPADMIC_work/xcelium/<RUN_ID>`

## Run ID Convention

Use a human-readable ID:

```bash
RUN_ID=matrix_top_$(date +%Y%m%d_%H%M%S)
```

The script must refuse to overwrite an existing run directory.

## Server Command

The wrapper script `TOP/ci/server_run_matrix_top_xcelium.sh` is now present for
server execution. It must be run on the Cadence server after sourcing the
Cadence environment:

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_test
git pull --ff-only origin SPADMIC_test
source /eda/cadence/eda_2023-2024
export SPADMIC_WORK_ROOT=/sim/ksabra/SPADMIC_work
bash TOP/ci/server_run_matrix_top_xcelium.sh "$RUN_ID"
```

## Output Directory Structure

```text
/sim/ksabra/SPADMIC_work/xcelium/<RUN_ID>/
  run_manifest.txt
  xrun_version.txt
  git_status_short.txt
  test_summary.txt
  SUMMARY.md
  logs/
    <test>.log
    <test>.tail
  work/
    <test>/
```

Do not commit `xcelium.d`, raw `work/`, waves, or large logs.

## Required Tests

The server script should run, at minimum:

- `tb_spadmic_matrix_top_csr_unit`
- `tb_spadmic_i2c_matrix_top_16b_unit`
- `tb_spadmic_matrix_or_tree_unit`
- `tb_spadmic_matrix_snapshot_frontend_unit`
- `tb_spadmic_matrix_reset_ctrl_unit`
- `tb_spadmic_event_coordinator_modes_unit`
- `tb_spadmic_position_modes_unit`
- `tb_spadmic_position_snapshot_cluster_unit`
- `tb_spadmic_matrix_cfg_cout_readback_unit`
- `tb_spadmic_matrix_cfg_ctrl_unit`
- `tb_spadmic_output_fifo_unit`
- `tb_spadmic_output_fifo_ddr_marker_unit`
- `tb_spadmic_ddr16_tx_pairer_unit`
- `tb_spadmic_top_output_pressure_unit`
- `tb_spadmic_top_matrix_v1_both_full_unit`
- `tb_spadmic_top_matrix_v1_skew_campaign`
- `tb_spadmic_top_reset_during_event_unit`
- `tb_spadmic_top_reset_during_matrix_cfg_unit`
- `tb_spadmic_top_mode_transition_unit`
- existing matrix-top smoke/unit tests already in `TOP/ci/run_tapeout_readiness.sh`
- maintained baseline TOP/ARB/I2C/position tests needed to catch portability
  regressions.

Tests that are not implemented at script creation time must be reported as missing/fail, not silently skipped.

## Summary Requirements

`SUMMARY.md` must include:

- branch;
- commit;
- command;
- run directory;
- Cadence version;
- test pass/fail table;
- skipped tests with explicit reason;
- first error per failing test;
- tail of failing logs;
- known limitations.

## Failure Triage

For every failure:

1. Confirm the failing test was run from the intended commit.
2. Inspect the first compile/elaboration error, not only the final line.
3. Separate compile, elaboration, runtime assertion, timeout, and scoreboard failures.
4. Check whether the failure is Verilator/Xcelium portability or a real RTL bug.
5. Record the finding in `TOP/docs/reviews/REVIEW_MATRIX_TOP_XCELIUM_<RUN_ID>.md`.
6. Do not mark the run as pass if any required test failed or was missing.

## Review Document After Logs

After the user provides server logs/results, create:

```text
TOP/docs/reviews/REVIEW_MATRIX_TOP_XCELIUM_<RUN_ID>.md
```

The review must state that Xcelium was run on the server by the user, not locally by Codex.
