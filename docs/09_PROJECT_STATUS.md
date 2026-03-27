# 09 — Current Project Status

This document is the current checkpoint handoff for the repository. It summarizes what is implemented, what has been validated, what still needs Cadence-side confirmation, and the exact recommended next commands.

## 1. Executive summary

The repository is in a good pre-synthesis / pre-calibration state:

- the RTL architecture is stable and documented
- the maintained Verilator regressions are passing locally
- the class-based VIP is functioning and no longer deadlocks on the previously failing stress pattern
- the Cadence coverage entrypoints are in place for closure work
- the offline calibration and Genus synthesis flows are both scripted and documented

The main remaining gate is **Cadence-side coverage closure and review** on the updated VIP.

## 2. RTL status

### Architecture snapshot

The current TDC implements:

- a `9 × 9` Vernier phase matrix
- `2` measurement contexts
- up to `15` hits per conversion
- three output modes:
  - `RAW_FEATURES`
  - `RAW_TIMESTAMP`
  - `FULL`

Key top-level files:

- `rtl/top/mptdc_top_asic.sv`
- `rtl/top/mptdc_core.sv`
- `rtl/pkg/mptdc_pkg.sv`

### Practical readiness

What looks solid:

- reset / CDC structure is partitioned cleanly
- watchdog and overflow handling are implemented
- context storage and readout path are integrated
- packetization path is validated by both integration benches and VIP

What still depends on downstream work:

- oscillator realism still depends on the eventual analog macro
- final timing closure still needs Genus + STA review
- offline calibration quality still depends on campaign data and LUT fitting

## 3. Verification status

### Maintained local regression state

The intended local regression sequence is:

```bash
bash ci/run_smoke.sh
bash ci/run_full_regression.sh
bash ci/run_vip_smoke.sh
```

Those flows cover:

- leaf/unit checks
- active integration benches
- maintained VIP smoke scenarios

### VIP status

The maintained VIP smoke suite currently contains `11` tests:

1. `smoke_single_conv`
2. `full_mode_timestamp`
3. `firsthit_contract`
4. `backpressure_integrity`
5. `start_watchdog`
6. `cal_inject`
7. `overflow_status`
8. `long_random`
9. `multi_conv_rearm_stress`
10. `global_watchdog_recovery`
11. `jitter_robustness`

The Cadence merged-coverage VIP suite currently contains `9` tests:

1. `smoke_single_conv`
2. `full_mode_timestamp`
3. `firsthit_contract`
4. `backpressure_integrity`
5. `start_watchdog`
6. `cal_inject`
7. `overflow_status`
8. `long_random`
9. `coverage_exhaustive`

There is also a stress test kept outside the normal smoke/coverage suites:

- `stress_random`

### Recent VIP fix status

The previously failing long stress behavior was traced to VIP-side accounting and sampling issues under rejection/backpressure stress, not a clearly isolated DUT packetizer failure.

The current VIP now uses:

- a BFM acknowledgment path to decide whether a conversion was really accepted
- expectation routing that only forwards accepted conversions to the scoreboard
- a sampled monitor bridge so accepted narrow-bus words are captured deterministically
- deterministic random-ready generation on the safe clock edge

This is the reason the repo should now be re-run on Cadence coverage before declaring closure.

## 4. Coverage status

### Local vs Cadence split

Use Verilator for:

- fast local debug
- smoke regressions
- long random sanity checks

Use Cadence for:

- covergroups
- merged functional/code coverage
- IMC review
- final coverage handoff evidence

### Main Cadence commands

Stable merged VIP coverage:

```bash
bash ci/run_vip_coverage.sh --sim xrun --clean
```

Broader stress campaign:

```bash
bash ci/run_coverage_campaign.sh --sim xrun --seeds 100 --conv-per-seed 5000 --jobs 32 --clean
```

### IMC review

Launch GUI:

```bash
imc -load build/coverage_campaign/cov_work/scope/test &
```

Generate a text report:

```bash
imc -execcmd "
  load_test build/coverage_campaign/cov_work -run *
  report_metrics -out build/coverage_campaign/cov_report.txt -detail -kind cover
  exit
" -batch -nocopyright
```

### How to read the result

A useful review order is:

1. confirm that all planned tests completed
2. inspect covergroup bins first
3. inspect line / condition / toggle coverage next
4. map uncovered logic to:
   - unreachable behavior
   - intentionally excluded behavior
   - missing test stimulus
   - a real functional problem

If the stress campaign still shows failures, debug the failing seeds first before trusting aggregate percentages.

## 5. Calibration status

The repo is set up for offline LUT calibration after RTL behavior is trusted.

Generate fresh data:

```bash
bash scripts/sim/run_campaign.sh --jobs 12
```

Run the LUT calibrator with explicit directories:

```bash
python3 scripts/calibration/calibrate_6d_lut.py \
  --train-dir results/campaign/multihit_15_cal_nominal \
  --fresh-dir results/campaign_validation/multihit_15_cal_nominal \
  --out-dir results/calibration_final
```

Optional arguments:

- `--val-dir` to override the validation split
- `--train-seeds` to change the number of training seeds
- `--chunk-load` to keep memory usage controlled

## 6. Synthesis status

The Cadence Genus flow is prepared under `syn/`.

Recommended first run:

```bash
cd syn/scripts
genus -batch -files genus.tcl 2>&1 | tee ../logs/genus_run.log
```

Important synthesis assumptions:

- the oscillator model is for simulation only
- synthesis should use the stub path
- the async frontend contains intentional latch-style structures that must be reviewed, not blindly eliminated
- final silicon closure still depends on real library data and the analog oscillator macro

## 7. Recommended next steps

If you are running on a Cadence server now, the recommended sequence is:

```bash
bash ci/run_vip_coverage.sh --sim xrun --clean
bash ci/run_coverage_campaign.sh --sim xrun --seeds 100 --conv-per-seed 5000 --jobs 32 --clean
imc -load build/coverage_campaign/cov_work/scope/test &
```

If that looks clean enough, then move to:

```bash
bash scripts/sim/run_campaign.sh --jobs 12
python3 scripts/calibration/calibrate_6d_lut.py \
  --train-dir results/campaign/multihit_15_cal_nominal \
  --fresh-dir results/campaign_validation/multihit_15_cal_nominal \
  --out-dir results/calibration_final
cd syn/scripts
genus -batch -files genus.tcl 2>&1 | tee ../logs/genus_run.log
```

## 8. Bottom line

The repo is **not yet at final silicon signoff**, but it is in a strong engineering checkpoint:

- RTL looks coherent
- verification infrastructure is mature
- the known VIP stress deadlock class has been fixed locally
- Cadence coverage closure is the right immediate next gate
- calibration and trial synthesis can follow once that Cadence pass is accepted
