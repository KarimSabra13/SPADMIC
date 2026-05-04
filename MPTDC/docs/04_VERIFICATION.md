# MPTDC v2.2 — Verification Guide

> - **Author:** Karim Sabra
> - **Purpose:** Describe the maintained verification, collection, and characterization flows in the current repository.
> - **Scope:** Covers active benches, VIP regressions, coverage entrypoints, and measurement-proof helpers. It is not a signoff methodology document.

## 1. Verification philosophy

The maintained verification stack is intentionally layered:

- unit benches for leaf RTL and packet formatting
- integration benches for end-to-end functional behavior through `mptdc_top_asic`
- a reusable class-based VIP for scenario-driven regression and coverage hooks
- campaign collectors for raw-data characterization
- fixed-delay characterization to prove same-delay one-shot RMS and averaging behavior

This validates RTL behavior and exported observables. It does **not** replace:

- STA / MMMC signoff
- formal CDC review
- analog oscillator integration
- DFT / silicon test planning

Compatibility note: some maintained bench and VIP names still use the historical
`firsthit` label. In the active v2.4 RTL, that label maps to the fast-close
behavior obtained with `max_hits = 1`; there is no separate mode bit in the DUT.

## 2. Shared infrastructure

### 2.1 `tb/common/mptdc_tb_pkg.sv`

Reusable helpers for:

- CSR reads/writes
- async START / STOP / CAL injection
- output-word parsing and packet collection
- RAW feature extraction and timestamp checks

### 2.2 `tb/common/mptdc_raw_monitor.sv`

Passive monitor for the 16-bit packet stream.

### 2.3 `scripts/sim/run_tb.sh`

Universal runner for unit and integration benches.

Examples:

```bash
bash scripts/sim/run_tb.sh tb_single_conv
bash scripts/sim/run_tb.sh tb_overflow_count --sim xrun
```

### 2.4 VIP environment: `tb/vip/` + `tb/tests/mptdc_vip_tb.sv`

The maintained VIP contains:

- transaction classes for reset, configuration, conversions, and backpressure
- generator / scenario sequencing
- driver + BFM bridge for timed DUT interaction
- monitor bridge for deterministic accepted-word sampling
- scoreboard / protocol checks
- functional coverage hooks guarded by `MPTDC_ENABLE_FUNC_COV`

### 2.5 `scripts/sim/run_vip_test.sh`

Primary VIP runner.

Key uses:

- fast local Verilator regression
- Cadence functional/code coverage runs
- jitter-aware VIP stress

Examples:

```bash
bash scripts/sim/run_vip_test.sh smoke_single_conv --sim verilator
bash scripts/sim/run_vip_test.sh jitter_robustness --sim xrun \
  --osc-jitter-sigma 8 --osc-jitter-bound 24
```

## 3. Active maintained benches

### 3.1 Unit benches

| Bench | Purpose |
| --- | --- |
| `tb_input_mux_unit` | SPAD / CAL routing behavior |
| `tb_reset_sync_unit` | reset synchronizer semantics |
| `tb_watchdog_unit` | watchdog counting and trip behavior |
| `tb_context_bank_unit` | context freeze / retention correctness |
| `tb_narrow16_tx_v2_unit` | serializer packet formatting and sequencing |

### 3.2 Integration benches

| Bench | Purpose |
| --- | --- |
| `tb_single_conv` | single conversion sanity |
| `tb_multi_conv_stress` | repeated conversions and sequencing |
| `tb_deadtime_measure` | re-arm timing trends |
| `tb_cal_inject` | CAL injection path |
| `tb_backpressure` | ready/valid stalls and FIFO tolerance |
| `tb_watchdog_recovery` | global watchdog trip and recovery |
| `tb_start_wdt` | START-without-STOP watchdog behavior |
| `tb_overflow_count` | rejected START / overflow accounting |
| `tb_firsthit_mode` | compatibility-named fast-close contract (`max_hits = 1`) |

### 3.3 Collection / characterization benches

The maintained raw-data collector is:

- `tb/int/tb_campaign_collect.sv`

It is driven through:

- `bash scripts/sim/run_campaign.sh ...`

This is the active characterization bench for broad `20 ps .. 30 ns` sweeps. Older
`tb_v21_*` collection benches are **not** the maintained path anymore.

## 4. Maintained runner entrypoints

### 4.1 Fast local regression

```bash
bash ci/run_smoke.sh
bash ci/run_full_regression.sh
bash ci/run_vip_smoke.sh
```

### 4.2 VIP smoke suite

`ci/run_vip_smoke.sh` currently runs `13` tests:

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
12. `hard_reset_readback`
13. `jitter_robustness`

### 4.3 Cadence coverage suite

`ci/run_vip_coverage.sh` currently runs `14` tests:

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
13. `hard_reset_readback`
14. `coverage_exhaustive`

For a broader Cadence checkpoint:

```bash
bash ci/run_coverage_campaign.sh --sim xrun --seeds 100 --conv-per-seed 5000 --jobs 32 --clean
```

## 5. Raw-data and measurement-proof flows

### 5.1 Broad-range campaign collection

Use the maintained sweep flow when you want statistical coverage across the full delay range:

```bash
# Official nominal baseline (12 jobs, 100000 conv/seed, optional downstream stages)
bash scripts/sim/run_characterization_baseline.sh \
  --sim verilator \
  --analyze \
  --calibrate \
  --with-fixed-delay

# Generic sweep entrypoint
bash scripts/sim/run_campaign.sh --sim verilator --jobs 12
bash scripts/sim/run_campaign.sh --sim xrun --jobs 32 --configs multihit_15_cal_nominal
```

Supported knobs that matter for characterization:

- `--sim verilator|xrun|xcelium`
- `--out-mode full|raw_features`
- `--jitter-sigma <ps> --jitter-bound <ps>`
- `--delay-min <ps> --delay-max <ps>`
- `--seed-start`, `--seeds`, `--n-conv`, `--configs`, `--out-dir`

The baseline wrapper writes a stable output tree and a
`characterization_manifest.json` file that records the campaign parameters and
the optional downstream analysis/calibration/fixed-delay stages.

### 5.2 Broad-range campaign analysis

`scripts/analysis/analyze_campaign.py` is the maintained post-processing entrypoint for sweep campaigns.

It now emits first-class outputs for:

- RMSE / mean / tails vs true delay
- RMSE / tails vs `nslow`
- RMSE / tails vs `nfast_hit`
- RMSE / tails vs `hit_idx`
- RMSE / tails vs `t_raw_ps`
- boundary-class summary figures
- `ns × nf` mean / std / occupancy heatmaps
- fixed engineering delay-region summary tables
- a machine-readable `summary_report.json`

Example:

```bash
python3 scripts/analysis/analyze_campaign.py \
  --campaign-dir results/campaign \
  --output-dir results/campaign/analysis \
  --config-filter 'multihit_15_*'
```

### 5.3 Repeated fixed-delay characterization

Use this flow when the question is **same-delay empirical one-shot RMS** rather than broad sweep behavior:

```bash
bash scripts/sim/run_fixed_delay_campaign.sh \
  --sim verilator \
  --configs multihit_15_cal_nominal \
  --delay-list "20,50,100,200,500,1000,2000,5000,10000,30000" \
  --seeds 6 \
  --n-conv 2000 \
  --out-dir results/fixed_delay_campaign \
  --analyze
```

This wrapper reuses `tb_campaign_collect` and simply runs independent campaigns with
`delay_min == delay_max`.

The paired analyzer:

- `scripts/analysis/analyze_fixed_delay_campaign.py`

produces:

- `fixed_delay_summary.csv`
- `fixed_delay_averaging.csv`
- `fixed_delay_report.json`
- `fixed_delay_report.txt`
- RMSE / tail plots vs fixed delay
- same-delay averaging curves for:
  - `first_hit_scan`
  - `conv_mean`
- RMSE-vs-`N` plots for representative fixed delays

This is the maintained proof path for repeated-measurement RMS and averaging studies.

## 6. What the current verification proves well

The current tree gives good confidence in:

1. serializer and packet framing behavior across active modes
2. context freeze / drain / release sequencing
3. watchdog and overflow recovery semantics
4. fast close (`max_hits = 1`) vs higher-`max_hits` behavior
5. broad raw-data collection across `20 ps .. 30 ns`
6. same-delay empirical characterization through the fixed-delay flow
7. VIP-driven regression and coverage handoff infrastructure

## 7. What is still not proven here

The verification collateral is still **not** a silicon-signoff package.

Important remaining gaps:

- no signoff-quality CDC / async exception proof
- no analog oscillator macro timing signoff
- no dedicated maintained bench that isolates `nfast_snap` coherency under stress
- coverage closure still depends on Cadence reruns

## 8. Recommended usage order

### Local engineering loop

```bash
bash ci/run_smoke.sh
bash ci/run_full_regression.sh
bash ci/run_vip_smoke.sh
python3 scripts/analysis/analyze_campaign.py --campaign-dir results/campaign --output-dir results/campaign/analysis
```

### Cadence-equipped server loop

```bash
bash ci/run_vip_coverage.sh --sim xrun --clean
bash ci/run_coverage_campaign.sh --sim xrun --seeds 100 --conv-per-seed 5000 --jobs 32 --clean
bash scripts/sim/report_coverage.sh --cov-root build/coverage_campaign
imc -load build/coverage_campaign/cov_work/scope/merged_cov &
```

### Calibration-proof loop

```bash
bash scripts/sim/run_campaign.sh --sim verilator --configs multihit_15_cal_nominal
python3 scripts/calibration/calibrate_6d_lut.py \
  --train-dir results/campaign/multihit_15_cal_nominal \
  --fresh-dir results/campaign_validation/multihit_15_cal_nominal \
  --out-dir results/calibration_final

bash scripts/sim/run_fixed_delay_campaign.sh --sim verilator --smoke --analyze
```
