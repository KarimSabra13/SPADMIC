# Xcelium Runbook

## Preconditions

Run from a clean exact-commit checkout on a host where `xrun` is available. Do
not mix results from different commits or reuse a failed run directory as
closure evidence.

```bash
cd /path/to/SPADMIC
git status --short --branch
git rev-parse HEAD
command -v xrun
bash TOP/ci/check_csr_map_generated.sh
```

Record the branch, full HEAD, `xrun -version`, command, and result directory.

## Directed regression

```bash
SPADMIC_SIM=xrun bash TOP/ci/run_directed_regression.sh
```

For a single bench:

```bash
bash TOP/scripts/sim/run_tb.sh tb_spadmic_i2c_matrix_top_16b_unit --sim xrun
```

## VIP smoke

```bash
bash TOP/ci/run_vip_smoke.sh
```

Individual tests:

```bash
bash TOP/scripts/sim/run_vip_test.sh smoke_tdc --sim xrun
bash TOP/scripts/sim/run_vip_test.sh smoke_position --sim xrun
bash TOP/scripts/sim/run_vip_test.sh smoke_position_raw --sim xrun
bash TOP/scripts/sim/run_vip_test.sh smoke_switching --sim xrun
bash TOP/scripts/sim/run_vip_test.sh spad_reset_modes --sim xrun
bash TOP/scripts/sim/run_vip_test.sh i2c_end_to_end --sim xrun
```

The I2C VIP models 100 kHz timing. Its timeout is intentionally longer than
direct-CSR tests.

## Functional coverage

```bash
bash TOP/ci/run_vip_coverage.sh
```

This campaign requests functional coverage only. Preserve the Xcelium coverage
database and reports, then review uncovered mandatory bins rather than relying
only on the shell return code.

## Result acceptance

Accept an RTL run only when all of the following are attributable to the same
HEAD:

- map generation check passes
- compile/elaboration has no errors
- every selected test reports PASS
- no fatal assertion or scoreboard mismatch exists
- functional coverage artifacts exist for coverage runs
- the exact command and logs are retained

These results authorize no Genus, Innovus, OA edit, DRC, LVS, or signoff claim by
themselves.
