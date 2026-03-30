# 09 — Current Project Status

This document is the current checkpoint handoff for the repository. It summarizes what is implemented, what has been validated, what still needs Cadence-side confirmation, and the exact recommended next commands.

## 1. Executive summary

The repository is in a strong pre-calibration checkpoint, but not yet at verification or synthesis signoff:

- the RTL architecture is stable and documented
- the maintained Verilator VIP regressions are currently green (`12/12`)
- the class-based VIP is functioning and no longer deadlocks on the previously failing stress pattern
- the latest broad Cadence baseline campaign passed `109/109` and merges cleanly in IMC
- the merged IMC aggregate baseline is `10986 / 16389 (67.03%)` with average grade `73.62%`
- the repo now includes additional CSR/control-path closure stimulus on top of the earlier stress fix
- the offline calibration and Genus synthesis flows are both scripted and documented

The main remaining gate is **targeted Cadence-side coverage closure** on the updated VIP, especially around the top wrapper, CSR block/interface, and reset behavior.

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

The maintained VIP smoke suite currently contains `12` tests:

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
11. `csr_readback_control`
12. `jitter_robustness`

The Cadence merged-coverage VIP suite currently contains `13` tests:

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
12. `csr_readback_control`
13. `coverage_exhaustive`

There is also a stress test kept outside the normal smoke/coverage suites:

- `stress_random`

### Recent VIP fix status

The previously failing long stress behavior was traced to VIP-side accounting and sampling issues under rejection/backpressure stress, not a clearly isolated DUT packetizer failure.

The current VIP now uses:

- a BFM acknowledgment path to decide whether a conversion was really accepted
- expectation routing that only forwards accepted conversions to the scoreboard
- a sampled monitor bridge so accepted narrow-bus words are captured deterministically
- deterministic random-ready generation on the safe clock edge

This is why the next meaningful server checkpoint is a Cadence rerun of the expanded directed suite plus the broad stress campaign, not another round of local packet-stress triage.

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

Latest measured Cadence baseline:

- campaign pass count: `109 / 109` (`9` directed + `100` stress),
- aggregate IMC coverage: `10986 / 16389 (67.03%)`,
- average grade: `73.62%`,
- weakest reported modules: `mptdc_top_asic 45.95%`, `mptdc_csr_if 28.26%`, `mptdc_csr_minimal 61.39%`, `mptdc_reset_sync 61.67%`.

The current repo expands the directed closure suite to `13` tests by adding:

- `multi_conv_rearm_stress`
- `global_watchdog_recovery`
- `jitter_robustness`
- `csr_readback_control`

### IMC review

Launch GUI:

```bash
bash scripts/sim/report_coverage.sh --cov-root build/coverage_campaign
imc -load build/coverage_campaign/cov_work/scope/merged_cov &
```

The helper also emits HTML summary reports in
`build/coverage_campaign/cov_report_aggregate/index.html` and
`build/coverage_campaign/cov_report_expand/index.html`.

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

Current gate recommendation:

- **Allowed now:** exploratory offline calibration using the existing data-collection flow
- **Not yet recommended as a freeze criterion:** using the current codebase as the final verification signoff point for synthesis, because merged code coverage is still too low in CSR/top/reset logic

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
bash scripts/sim/report_coverage.sh --cov-root build/coverage_campaign
imc -load build/coverage_campaign/cov_work/scope/merged_cov &
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

The repo is **not yet at final silicon signoff**, but it is at a strong engineering checkpoint:

- RTL looks coherent
- verification infrastructure is mature
- the known VIP stress deadlock class has been fixed and the `109/109` broad campaign baseline is green
- the remaining meaningful holes are concentrated in CSR / top-level / reset control paths, not in the packet stress path
- exploratory calibration can proceed in parallel with closure work
- final synthesis freeze should wait for the next Cadence closure rerun on the expanded directed suite
