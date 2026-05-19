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

The enhanced closure plan treats MPTDC internals as first-class verification
scope, not only as a pre-verified IP used by TOP. Each active RTL block should
have either direct bench/stress evidence or a documented waiver explaining why
subsystem evidence is sufficient. Verification and characterization are separate
but linked gates: verification proves data integrity, control/status behavior,
packet grammar, and safe recovery; characterization proves timing accuracy and
calibration quality using the verified data path.

This validates RTL behavior and exported observables. It does **not** replace:

- STA / MMMC signoff
- formal CDC review
- analog oscillator integration
- DFT / silicon test planning

Compatibility note: some maintained bench and VIP names still use the historical
`firsthit` label. In the active v2.4 RTL, that label maps to the fast-close
behavior obtained with `max_hits = 1`; there is no separate mode bit in the DUT.

## 2. VIP CDV architecture

The maintained VIP turns into the authoritative single-channel
macro-level CDV environment.  The scope is one MPTDC instance: full SPADMIC
three-instance shared-readout verification remains a higher-level phase.

Key contracts:

- **Use case:** an asynchronous SPAD pulse is START; the first qualified 40 MHz
  reference edge after an accepted START is STOP.
- **Clocking:** `clk_sys` stays at 160 MHz and the reference STOP clock stays at
  40 MHz, but the reference clock receives a seed-derived static phase offset so
  regressions sweep physical CTS skew alignments.
- **Scoreboard:** every attempted START receives an attempt ID; accepted events
  receive event IDs and are matched to packets by order/context with variable
  latency.  Rejected STARTs are logged and covered but do not create expected
  packets.
- **Drop policy:** rejected STARTs are legal only when the macro is not ready or
  context/FIFO pressure prevents safe allocation; rejection must not corrupt
  accepted packets.
- **Coverage:** functional coverage is advisory, but every critical uncovered
  bin must be reviewed, waived, or closed with a directed test before tapeout
  signoff.
- **Metrics:** characterization reports pre/post 6D-LUT RMS, DNL/INL, tuple
  occupancy, and outliers.  These are reportable distributions until explicit
  numeric pass/fail limits are approved.

### 2.1 Dual-simulator policy

Verilator and Xcelium enforce the same functional rules with different depth:

| Flow | Role |
| --- | --- |
| Verilator | First-class shift-left smoke/lint-like sanity. Runs directed and lightweight randomized checks quickly. |
| Xcelium | Authoritative CDV/coverage/assertion/characterization engine, including 32-job overnight regressions. |

Do not let a scenario mean one thing in Verilator and another in Xcelium.  If a
boundary condition is legal or illegal in one flow, the other flow must use the
same rule even if it samples fewer seeds.

### 2.2 VIP entrypoints

```bash
# One VIP test with qualified 40 MHz STOP, transaction CSV/JSONL logs, and artifacts
bash scripts/sim/run_vip_test.sh smoke_single_conv \
  --sim verilator \
  --stop-model qualified-ref \
  --artifact-dir build/vip_smoke_artifacts

# Xcelium 32-job CDV regression with coverage and automatic failure reruns
bash ci/run_vip_xcelium_regression.sh --sim xrun --jobs 32 --seeds 32

# Train/validation characterization split for 6D LUT calibration
bash scripts/sim/run_vip_characterization.sh --jobs 32 --train-seeds 64 --valid-seeds 16
```

The VIP runner accepts:

- `--stop-model direct|qualified-ref`
- `--ref-phase-ps <N>` to override the seed-derived 40 MHz phase
- `--artifact-dir <DIR>` to emit `transactions.csv` and `transactions.jsonl`
- `--vip-asserts` to enable interface-level assertions

## 3. Shared infrastructure

### 3.1 `tb/common/mptdc_tb_pkg.sv`

Reusable helpers for:

- CSR reads/writes
- async START / STOP / CAL injection
- output-word parsing and packet collection
- RAW feature extraction and timestamp checks

### 3.2 `tb/common/mptdc_raw_monitor.sv`

Passive monitor for the 16-bit packet stream.

### 3.3 `scripts/sim/run_tb.sh`

Universal runner for unit and integration benches.

Examples:

```bash
bash scripts/sim/run_tb.sh tb_single_conv
bash scripts/sim/run_tb.sh tb_overflow_count --sim xrun
```

### 3.4 VIP environment: `tb/vip/` + `tb/tests/mptdc_vip_tb.sv`

The maintained VIP contains:

- transaction classes for reset, configuration, conversions, and backpressure
- generator / scenario sequencing
- driver + BFM bridge for timed DUT interaction
- monitor bridge for deterministic accepted-word sampling
- scoreboard / protocol checks
- functional coverage hooks guarded by `MPTDC_ENABLE_FUNC_COV`

### 3.5 `scripts/sim/run_vip_test.sh`

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

### 3.6 VIP interface/bind-style assertions

The VIP interfaces contain assertion-style protocol checks guarded by
`MPTDC_ENABLE_VIP_ASSERTS` so Xcelium signoff can enable them without forcing
every Verilator smoke compile through simulator-specific assertion support:

- CSR request stability while waiting for `csr_ready`
- narrow-stream data stability under `valid && !ready`
- no X/Z on accepted narrow data

These are verification-only checks.  They do not change the synthesizable RTL
interface.

### 3.7 Embedded RTL safety assertions

The active RTL now includes synthesis-excluded assertions around the highest-risk
control/data-integrity contracts:

- measurement teardown pulse ordering in `mptdc_meas_ctrl`
- context-bank capture/metadata exclusivity
- held-image stability in `mptdc_hit_capture_bridge`
- FIFO level and FWFT data stability in `mptdc_sync_fifo`
- pending-record stability and release safety in `mptdc_drain_ctrl`
- narrow ready/valid stability in `mptdc_narrow16_tx_v2`
- START accept/reject exclusivity in `mptdc_async_frontend_v2`
- PD hit stickiness until clear in `mptdc_pd_cell`

These assertions are not a replacement for CDC/STA signoff, but they convert the
main architectural assumptions into executable checks for local simulation and
formal-style lint flows.

## 4. Active maintained benches

### 4.1 Unit benches

| Bench | Purpose |
| --- | --- |
| `tb_input_mux_unit` | SPAD / CAL routing behavior |
| `tb_reset_sync_unit` | reset synchronizer semantics |
| `tb_watchdog_unit` | watchdog counting and trip behavior |
| `tb_context_bank_unit` | context freeze / retention correctness |
| `tb_narrow16_tx_v2_unit` | serializer packet formatting and sequencing |

### 4.2 Integration benches

| Bench | Purpose |
| --- | --- |
| `tb_single_conv` | single conversion sanity |
| `tb_multi_conv_stress` | repeated conversions and sequencing |
| `tb_deadtime_measure` | re-arm timing trends |
| `tb_cal_inject` | CAL injection path |
| `tb_backpressure` | ready/valid stalls and FIFO tolerance |
| `tb_lossless_pressure` | lossless STOP-to-next-START pressure, near-deadtime, saturation/release, and exact rejected-START accounting |
| `tb_watchdog_recovery` | global watchdog trip and recovery |
| `tb_start_wdt` | START-without-STOP watchdog behavior |
| `tb_overflow_count` | rejected START / overflow accounting |
| `tb_firsthit_mode` | compatibility-named fast-close contract (`max_hits = 1`) |

### 4.3 Collection / characterization benches

The maintained raw-data collector is:

- `tb/int/tb_campaign_collect.sv`

It is driven through:

- `bash scripts/sim/run_campaign.sh ...`

This is the active characterization bench for broad `20 ps .. 30 ns` sweeps. Older
`tb_v21_*` collection benches are **not** the maintained path anymore.

## 5. Maintained runner entrypoints

### 5.1 Fast local regression

```bash
bash ci/run_smoke.sh
bash ci/run_full_regression.sh
bash ci/run_vip_smoke.sh
bash scripts/sim/run_tb.sh tb_lossless_pressure --sim verilator
```

### 5.2 VIP smoke suite

`ci/run_vip_smoke.sh` currently runs `15` tests:

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
14. `vip_ref_stop_cdv`
15. `vip_maxhits_matrix`

### 5.3 Cadence coverage suite

`ci/run_vip_coverage.sh` currently runs `16` tests:

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
15. `vip_ref_stop_cdv`
16. `vip_maxhits_matrix`

For a broader Cadence checkpoint:

```bash
bash ci/run_coverage_campaign.sh --sim xrun --seeds 100 --conv-per-seed 5000 --jobs 32 --clean
```

## 6. Raw-data and measurement-proof flows

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
- raw tuple histogram and code-density CSVs/plots for pre-calibration DNL/INL review
- RMSE / tails vs `nslow`
- RMSE / tails vs `nfast_hit`
- RMSE / tails vs `hit_idx`
- RMSE / tails vs `t_raw_ps`
- boundary-class summary figures
- `ns × nf` mean / std / occupancy heatmaps
- fixed engineering delay-region summary tables
- a machine-readable `summary_report.json`

`scripts/calibration/calibrate_6d_lut.py` also exports pre/post
reconstruction-error CSVs for held-out validation and fresh-sample evidence.
For pivot signoff, packet tests are necessary but insufficient: keep both the
raw tuple/code-density evidence and post-calibration reconstructed timestamp
error evidence.

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

## 7. Spec-driven closure plan

The MPTDC spec-to-verification map should cover every rule in:

- [`01_ARCHITECTURE.md`](01_ARCHITECTURE.md)
- [`02_OUTPUT_PROTOCOL.md`](02_OUTPUT_PROTOCOL.md)
- [`03_CSR_MAP.md`](03_CSR_MAP.md)
- [`10_SHARED_READOUT_EXPORT.md`](10_SHARED_READOUT_EXPORT.md)
- [`11_BLOCK_GUIDE.md`](11_BLOCK_GUIDE.md)

Each rule should map to directed tests, constrained-random scenarios,
assertions, scoreboard checks, coverpoints, or an explicit waiver. The mandatory
non-waivable categories are reset behavior, CDC-boundary assumptions, CSR
fault/status semantics, serializer packet grammar, FIFO/backpressure behavior,
overflow/rejected-START accounting, watchdog recovery, and output-mode/max-hit
coverage.

### 7.1 Block closure matrix

| Block area | Required verification evidence |
|------------|--------------------------------|
| `mptdc_pkg` | constant/domain sanity, legal `ns/nf` ranges, helper-function packet/timestamp checks |
| `mptdc_input_mux` | SPAD/CAL selection, disabled/quasi-static select assumptions, reset/readback interaction |
| `mptdc_reset_sync` | async assert, sync release, recovery after short/long reset pulses |
| `mptdc_async_frontend_v2` | START acceptance, STOP acceptance, context availability, ignored/rejected starts, held-level behavior |
| `mptdc_stop_capture_async` | STOP-edge boundary metadata, phase snapshots, boundary carry assumptions |
| `mptdc_context_bank` | split raw-image capture and metadata update, freeze, retention, drain read stability, release, double-buffer interaction |
| `mptdc_gray_cnt_sync` | Gray transition assumptions, snapshot coherence, reset behavior |
| `mptdc_pd_cell` and PD matrix | legal 8x8 geometry, hit latch/clear, one-cell and multi-cell hit patterns, model/macro assumptions |
| `mptdc_meas_ctrl` | fast close, max-hit close, watchdog close, `SNAPSHOT->COUNT->EVAL->CAPTURE->CLEAR` ordering, no `pd_clear` before raw commit/metadata update |
| `mptdc_drain_ctrl` | META-first sequencing, HIT count agreement, context release, zero-hit and max-hit scans |
| `mptdc_sync_fifo` | full/empty, simultaneous read/write, clear/reset, sustained backpressure |
| `mptdc_csr_minimal` | W/R/W1C/readback, invalid or stale status avoidance, soft reset, `OVF_COUNT`, `CSR_HIT_COUNT` |
| `mptdc_narrow16_tx_v2` | RAW_FEATURES, RAW_TIMESTAMP, FULL packet lengths, EOC, local `conv_id`, payload parsing by structure |
| shared-readout export | local serializer bypass, `acq_valid/ready`, META grant assumptions for TOP |
| `mptdc_top_asic` / `mptdc_core` | complete conversion flow, reset recovery, output modes, jitter robustness, calibration-data integrity |

### 7.2 Golden model and timing tolerance policy

Digital contracts should be checked exactly: CSR state, packet grammar, META/HIT
sequencing, output mode, hit counts, flags, FIFO behavior, and reset/fault
status. Timing/timestamp accuracy should use configurable tolerance data loaded
from calibration or campaign manifests with documented defaults. The test code
should not hide magic tolerances; any default tolerance must point back to a
characterization artifact or an explicit temporary engineering assumption.

Until the real analog oscillator macro is available, the verification spec
should document a formal macro contract and check the digital logic against the
behavioral oscillator model plus assumption checks. The macro contract should
cover tap count/order, nominal/min/max tap delays, enable/disable latency,
deterministic idle/reset behavior if required, generated clock names, jitter
inputs, and physical symmetry constraints for the 8x8 PD island.

### 7.3 Coverage and signoff tiers

Closure targets:

- 100% functional-bin review
- at least 95% aggregate functional coverage
- at least 90% code coverage
- zero accepted scoreboard or assertion failures
- waivers tied to unreachable logic, documented analog/macro assumptions, or
  intentionally excluded features

Signoff should be split into:

| Tier | Purpose | Evidence |
|------|---------|----------|
| Local Verilator | fast portable regression | `ci/run_smoke.sh`, `ci/run_full_regression.sh`, `ci/run_vip_smoke.sh` |
| Xcelium regression | full SV behavior and assertions | VIP smoke/feature/stress tests under `xrun` |
| Coverage campaign | functional and code closure | merged coverage DB, zero-bin review, waiver list |
| CDC/lint/formal-style | async/reset/static safety | CDC exception review, lint/formal reports where available |
| Synthesis/timing sanity | implementation readiness | clean elaboration, generated-clock/false-path review, macro-contract alignment |
| Characterization | timing accuracy/calibration quality | campaign and fixed-delay reports using verified data outputs |

## 8. What is still not proven here

The verification collateral is still **not** a silicon-signoff package.

Important remaining gaps:

- no signoff-quality CDC / async exception proof
- no analog oscillator macro timing signoff
- no dedicated maintained bench that isolates `nfast_snap` coherency under stress
- coverage closure still depends on Cadence reruns

## 9. Recommended usage order

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
