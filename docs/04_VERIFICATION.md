# MPTDC v2.2 — Verification Guide

> - **Author:** Karim Sabra
> - **Purpose:** Summarize the active bench inventory, VIP flow, and supported regression entry points.
> - **Scope:** Covers repository verification collateral and runner usage; it does not replace signoff methodology.

## 1. Verification philosophy

The active verification strategy combines:

- unit benches for leaf blocks and protocol helpers
- integration benches for end-to-end behavior through `mptdc_top_asic`
- a reusable class-based VIP environment for layered regression
- focused collection benches for raw-data characterization
- simulation with the behavioral oscillator model (`MPTDC_USE_OSC_MODEL`) so the async Vernier path behaves realistically

This is functional verification of the RTL architecture. It is not a replacement for gate-level signoff, static timing, formal CDC review, or real oscillator-macro integration.

## 2. Shared TB infrastructure

### 2.1 `tb/common/mptdc_tb_pkg.sv`

Provides reusable helpers for:

- packet detection: `is_header()`, `is_eoc()`
- header parsing: context id, hit count, flags, mode, boundary bit
- hit parsing: `nslow`, `nfast`, `nfast_snap`, `ns`, `nf`, `pd_idx`, `event_seq`
- CSR transactions
- async START/STOP injection
- packet collection from the 16-bit output stream

### 2.2 `tb/common/mptdc_raw_monitor.sv`

Passive packet observer that can log and sanity-check the 16-bit stream.

### 2.3 `scripts/sim/run_tb.sh`

Universal test runner used by most local workflows.

Examples:

```bash
bash scripts/sim/run_tb.sh tb_single_conv
bash scripts/sim/run_tb.sh tb_v21_collect
```

### 2.4 `tb/vip/` and `tb/tests/`

The reusable VIP flow is built around:

- interfaces for CSR, async START/STOP/CAL stimulus, and narrow output
- transaction classes for reset, configuration, conversion stimulus, and backpressure
- generator / scenario queueing
- driver plus module-scope BFM bridging for stable timed DUT driving
- passive packet monitor
- scoreboard and protocol / semantic checks
- functional coverage hooks guarded by `MPTDC_ENABLE_FUNC_COV`

The current reusable top is `tb/tests/mptdc_vip_tb.sv`. The main package is `tb/vip/pkg/mptdc_vip_pkg.sv`.

### 2.5 `scripts/sim/run_vip_test.sh`

Runner for the class-based VIP tests.

It also provides the coverage-runner hooks used for closure handoff:

- `--func-cov` / `--code-cov` to enable coverage-capable simulator flows
- `--cov-workdir DIR` and `--cov-test-name NAME` so multiple Cadence runs can share one coverage database
- `--dry-run` so command lines can be reviewed locally without requiring `xrun`

Examples:

```bash
bash scripts/sim/run_vip_test.sh smoke_single_conv --sim verilator
bash scripts/sim/run_vip_test.sh smoke_single_conv --sim xrun --func-cov --code-cov \
  --cov-workdir build/vip_coverage_xrun/cov_work --cov-test-name smoke_single_conv
bash scripts/sim/run_vip_test.sh smoke_single_conv --sim xrun --func-cov --code-cov --dry-run
bash scripts/sim/run_vip_test.sh long_random --sim verilator
```

### 2.6 `ci/run_vip_smoke.sh`

Smoke regression wrapper for the VIP suite. It currently exercises:

- `smoke_single_conv`
- `full_mode_timestamp`
- `firsthit_contract`
- `backpressure_integrity`
- `start_watchdog`
- `cal_inject`
- `overflow_status`
- `long_random`
- `multi_conv_rearm_stress`
- `global_watchdog_recovery`
- `jitter_robustness` (run with non-zero oscillator jitter plusargs)

### 2.7 `ci/run_vip_coverage.sh`

Cadence-side VIP coverage regression wrapper.

It:

- runs the stable VIP coverage suite under `xrun` / `xcelium`
- enables both functional coverage and code coverage
- shares one coverage work directory across tests so IMC / Xcelium can review a merged database
- supports `--clean`, `--seed-base`, `--waves`, `--dry-run`, and optional per-invocation test selection

Examples:

```bash
bash ci/run_vip_coverage.sh --sim xrun --clean
bash ci/run_vip_coverage.sh long_random --sim xcelium --seed-base 100
bash ci/run_vip_coverage.sh --dry-run
```

### 2.8 `ci/run_full_regression.sh`

Current active regression driver.

Runs:

- lint on `mptdc_top_asic`
- the active integration suite

## 3. Active unit benches

| Bench | Purpose |
|------|---------|
| `tb_input_mux_unit` | SPAD/CAL routing behavior |
| `tb_reset_sync_unit` | reset synchronizer semantics |
| `tb_watchdog_unit` | global watchdog counting and trip behavior |
| `tb_context_bank_unit` | snapshot storage correctness and boundary-bit retention |
| `tb_narrow16_tx_v2_unit` | packet formatting, serializer sequencing, and timestamp-word generation |

## 4. Active integration benches

| Bench | Purpose | Typical focus |
|------|---------|---------------|
| `tb_single_conv` | single conversion sanity | packet framing, hit presence, basic data validity |
| `tb_multi_conv_stress` | repeated conversions | sustained operation, sequencing, no packet loss |
| `tb_deadtime_measure` | re-arm timing | conversion-to-conversion recovery and deadtime behavior |
| `tb_cal_inject` | calibration input path | muxing, CAL-mode behavior, delay sweep sanity |
| `tb_backpressure` | output stalls | ready/valid backpressure and FIFO tolerance |
| `tb_watchdog_recovery` | global watchdog recovery | force-reset behavior and cleanup |
| `tb_start_wdt` | missing-STOP recovery | slow-domain START watchdog and synthetic STOP flow |
| `tb_overflow_count` | rejected START accounting | real overflow counting via `start_rejected` |
| `tb_firsthit_mode` | FIRST_HIT semantics | close behavior and limited-hit packet expectations |

These nine benches make up the active regression suite.

## 5. Collection and characterization benches

### 5.1 `tb/int/tb_v21_collect.sv`

This is the maintained comprehensive collection bench for the current architecture.

It:

- runs `1000` `FIRST_HIT` conversions
- runs `1000` `MULTI_HIT` conversions with `max_hits=15`
- generates delays across the active measurement range
- writes CSV files in `results/`
- logs raw features plus the current raw timestamp reconstruction

Current CSV fields include:

- `Nslow`
- `Nfast_hit`
- `Nfast_snap`
- `ns`
- `nf`
- `event_seq`
- `phase0_snap`
- `slow_boundary_inc`
- `Tconv_ps`
- `offset_ps`

### 5.2 `tb/int/tb_data_collect.sv`

Legacy-style sweep bench retained for targeted collection. It now uses the shared package raw-timestamp helper but is not the primary maintained collection flow.

### 5.3 `tb/int/tb_v21_debug.sv`

Debug-oriented bench, useful during investigation work but not part of the main regression contract.

## 6. What the current verification covers well

1. Packet framing and serializer behavior across all active output modes
2. Double-buffer context flow and context release
3. Missing-STOP and global-watchdog recovery behavior
4. Output backpressure and FIFO stalling behavior
5. FIRST_HIT and MULTI_HIT operation
6. Raw-data collection over a broad time range using the behavioral oscillator model
7. Current STOP-side `Nslow` snapshot behavior and boundary metadata export
8. Reusable scenario-driven regression through the class-based VIP
9. Cross-checking of packet structure, flags, output mode, and timestamp reconstruction in the VIP scoreboard

### 6.1 Coverage strategy in the VIP flow

The VIP is designed to support:

- functional coverage through the `stim_cg` and `pkt_cg` covergroups in the VIP package
- code coverage in `xrun` / Xcelium
- scenario-driven smoke validation in Verilator

In the current local environment, Verilator is the validated runtime path and does not support covergroups. As a result:

- local preflight stays on `ci/run_vip_smoke.sh`
- functional coverage must be enabled on a coverage-capable simulator such as `xrun`
- `scripts/sim/run_vip_test.sh` intentionally rejects `--func-cov` / `--code-cov` when `--sim verilator` is selected
- `ci/run_vip_coverage.sh` is the handoff entrypoint for Cadence-side coverage closure
- Verilator should be treated as compile-and-smoke validation for the VIP flow
- coverage closure remains a Cadence-side activity even though the hooks are already present in the TB architecture

### 6.2 Coverage-closure handoff

Recommended Cadence-side entry command:

```bash
bash ci/run_vip_coverage.sh --sim xrun --clean
```

Local command review without Cadence tools:

```bash
bash ci/run_vip_coverage.sh --dry-run
```

Closure review goals for the new VIP flow:

1. Every test in the stable VIP coverage suite passes with the scoreboard clean.
2. The shared coverage database under `build/vip_coverage_<sim>/cov_work` contains one `covtest` bucket per executed scenario.
3. `stim_cg` and `pkt_cg` are reviewed in IMC / Xcelium coverage reporting; any remaining holes are traced to a missing scenario, a known simulator limitation, or a documented waiver.
4. Code coverage is reviewed on the active RTL path (`mptdc_top_asic`, `mptdc_core`, async/control/readout/FIFO logic), with exclusions documented instead of silently ignored.
5. The Cadence-generated coverage database and report snapshot are archived together with the regression log as the closure handoff artifact.

## 7. What the current verification does not replace

The repository tests do not replace:

- signoff CDC analysis
- static timing analysis on generated oscillator clocks
- real oscillator-macro characterization
- gate-level simulation with implementation-specific cells
- DFT and scan insertion checks
- post-layout extraction and correlation

## 8. Oscillator-model assumptions

All benches that care about real timing should run with the oscillator model enabled.

That means:

- `mptdc_osc_model` is active
- `mptdc_osc_stub` is not used
- phase relationships, startup, and optional jitter are exercised realistically enough for RTL-level architecture verification

The oscillator model is still a behavioral approximation. Silicon correlation is the job of the offline calibration flow.

## 9. Typical commands

```bash
# Full active regression
bash ci/run_full_regression.sh

# One end-to-end sanity bench
bash scripts/sim/run_tb.sh tb_single_conv

# One VIP smoke test
bash scripts/sim/run_vip_test.sh smoke_single_conv --sim verilator

# VIP smoke regression
bash ci/run_vip_smoke.sh

# Cadence VIP coverage regression
bash ci/run_vip_coverage.sh --sim xrun --clean

# Local dry-run of the Cadence coverage commands
bash ci/run_vip_coverage.sh --dry-run

# Comprehensive collection bench
mkdir -p build/tb_v21_collect/results
bash scripts/sim/run_tb.sh tb_v21_collect
```

## 10. Review guidance before synthesis

Before synthesis signoff, use the simulation suite to confirm functional intent, then add dedicated implementation-stage checks for:

- generated-clock constraints
- async latch handling in `mptdc_async_frontend_v2`
- STOP-edge capture logic in `mptdc_stop_capture_async`
- Gray-counter snapshot assumptions in `mptdc_gray_cnt_sync`
- real oscillator replacement for `mptdc_osc_stub`
