# MPTDC — Vernier Multi-Phase Time-to-Digital Converter

> **Author:** Karim Sabra  
> **Current status:** latest observed lab-server merged coverage is `70.08%` / grade `82.05%`; current repo further expands closure on CSR/top/reset/overflow paths before the next Cadence rerun
> **License:** Copyright © 2025 Karim Sabra. All rights reserved.

## What this repository is

`MPTDC` is a Vernier multi-phase TDC for SPAD readout, built around:

- a `9 × 9` slow/fast phase matrix
- `2` context buffers (hardwired double buffer)
- `15` maximum hits per conversion
- a `16-bit` ready/valid output stream
- three output modes: `RAW_FEATURES`, `RAW_TIMESTAMP`, and `FULL`

The digital RTL is intended to be used with a behavioral oscillator model in simulation and a real current-starved oscillator macro in silicon.

## Status snapshot

### RTL

- Top level: `rtl/top/mptdc_top_asic.sv`
- Core integration: `rtl/top/mptdc_core.sv`
- Async capture frontend: `rtl/async/mptdc_async_frontend_v2.sv`
- Readout serializer: `rtl/readout/mptdc_narrow16_tx_v2.sv`
- Package constants/types: `rtl/pkg/mptdc_pkg.sv`

Key architectural facts from RTL:

| Item | Value |
| --- | --- |
| Vernier geometry | `NE = 9` slow × `9` fast |
| Context buffers | `N_CTX = 2` |
| Max hits | `15` |
| FIFO depth | `64` acquisition records |
| System clock | `160 MHz` |
| Oscillator timing model | behavioral model in simulation, stub for synthesis |

### Verification

Most recently revalidated on the current tree:

- `bash ci/run_vip_smoke.sh` → `13/13` pass
- `bash scripts/sim/run_vip_test.sh overflow_status --sim verilator`
- `bash scripts/sim/run_vip_test.sh hard_reset_readback --sim verilator`
- `bash scripts/sim/run_vip_test.sh csr_readback_control --sim verilator`
- `bash scripts/sim/run_vip_test.sh coverage_exhaustive --sim verilator`

That means:

- the maintained VIP smoke suite (`13` tests) is passing
- the deterministic overflow/recovery and pad-reset readback closure scenarios are regression-safe locally
- the exhaustive VIP closure test still passes after the coverage-suite expansion

Cadence-only flows are prepared but must be run on a machine with `xrun` / `xcelium`, `imc`, and `genus`.

### Coverage

There are two distinct Cadence coverage entrypoints:

- `bash ci/run_vip_coverage.sh --sim xrun --clean`
  - stable merged VIP coverage suite
  - functional + code coverage
  - shared coverage DB under `build/vip_coverage_xrun/`
  - current repo contents expand this suite to `14` directed tests, including deterministic overflow/recovery, hard-reset readback, CSR/readback, and jitter closure

- `bash ci/run_coverage_campaign.sh --sim xrun --seeds 100 --conv-per-seed 5000 --jobs 32`
  - exhaustive + multi-seed stress coverage campaign
  - merged coverage DB under `build/coverage_campaign/`

Most recent merged lab-server report observed after the previous closure push:

- `109 / 109` tests passed (`9` directed + `100` stress),
- merged IMC aggregate report: `11486 / 16389 (70.08%)`,
- average grade: `82.05%`,
- weakest reported modules: `mptdc_top_asic 45.95%`, `mptdc_csr_if 28.26%`, `mptdc_csr_minimal 61.39%`, `mptdc_reset_sync 61.67%`.

The current repo is one step ahead of that measured report: it further hardens
`overflow_status` into a deterministic rejected-START / `OVF_COUNT` recovery
check and adds `hard_reset_readback` to close the pad-reset / `CSR_HIT_COUNT`
path before the next Cadence rerun.

### Calibration

Offline calibration flow is present and documented:

- data collection: `bash scripts/sim/run_campaign.sh`
- LUT calibration: `python3 scripts/calibration/calibrate_6d_lut.py ...`

The committed calibration flow targets the `multihit_15_cal_nominal` dataset structure by default and writes reports under `results/calibration_final/`.

### Synthesis

Cadence Genus setup is committed under `syn/`.

- entrypoint: `syn/scripts/genus.tcl`
- documentation: `syn/README.md`
- PDK path setup required before first run
- oscillator model is **not** synthesized; the synthesis flow uses the oscillator stub

## Repository map

```text
rtl/
  pkg/        constants, enums, packet types, CSR addresses
  cdc/        reset sync, pulse sync, gray-counter CDC, sync FIFO
  osc/        oscillator wrapper, model, and synthesis stub
  pd/         phase detector cells
  async/      START/STOP capture, context bank, async-side logic
  ctrl/       measurement FSM, watchdog, drain control
  readout/    CSR block, timestamp reconstruction helper, serializer
  top/        core + top-level integration

tb/
  common/     shared bench helpers and raw packet monitor
  unit/       5 leaf-level benches
  int/        9 active integration benches + campaign collector
  vip/        class-based verification environment
  tests/      VIP top-level harness

scripts/
  sim/        test and campaign runners
  calibration/ calibration and LUT analysis

ci/           regression wrappers and coverage entrypoints
docs/         architecture, protocol, verification, calibration, runbook, status
syn/          Cadence Genus synthesis collateral
```

## Recommended command flow

### 1) Local sanity before pushing

```bash
bash ci/run_smoke.sh
bash ci/run_full_regression.sh
bash ci/run_vip_smoke.sh
```

### 2) Single VIP test

```bash
bash scripts/sim/run_vip_test.sh smoke_single_conv --sim verilator
```

### 3) Cadence VIP smoke / debug

```bash
bash scripts/sim/run_vip_test.sh smoke_single_conv --sim xrun
bash scripts/sim/run_vip_test.sh jitter_robustness --sim xrun \
  --osc-jitter-sigma 8 --osc-jitter-bound 24
```

### 4) Cadence coverage closure

```bash
bash ci/run_vip_coverage.sh --sim xrun --clean
bash ci/run_coverage_campaign.sh --sim xrun --seeds 100 --conv-per-seed 5000 --jobs 32
```

### 5) Review coverage in IMC

```bash
bash scripts/sim/report_coverage.sh --cov-root build/coverage_campaign

# Open the merged run in IMC
imc -load build/coverage_campaign/cov_work/scope/merged_cov &

# Open the generated HTML summary
xdg-open build/coverage_campaign/cov_report_aggregate/index.html
```

`xrun` writes one coverage bucket per `-covtest`, so IMC reporting must merge
those buckets before load/report.

### 6) Data collection and calibration

```bash
bash scripts/sim/run_campaign.sh --jobs 12

python3 scripts/calibration/calibrate_6d_lut.py \
  --train-dir results/campaign/multihit_15_cal_nominal \
  --fresh-dir results/campaign_validation/multihit_15_cal_nominal \
  --out-dir results/calibration_final
```

### 7) Trial synthesis

```bash
cd syn/scripts
genus -batch -files genus.tcl 2>&1 | tee ../logs/genus_run.log
```

## Verification inventory

| Category | Current maintained set |
| --- | --- |
| Unit benches | `5` |
| Active integration benches | `9` in `ci/run_full_regression.sh` |
| Collection / characterization benches | `tb_campaign_collect` plus maintained collection flows |
| VIP smoke tests | `13` in `ci/run_vip_smoke.sh` |
| VIP coverage suite | `14` in `ci/run_vip_coverage.sh` |
| Coverage campaign | `14` directed tests + `stress_random × N seeds` |

## Coverage guidance

Use Verilator for fast local confidence and Cadence for coverage closure.

Recommended interpretation order for Cadence coverage:

1. confirm every coverage-suite test passed cleanly
2. inspect `stim_cg` for stimulus-space holes
3. inspect `pkt_cg` for packet-space holes
4. review line/condition/toggle/FSM coverage on active RTL
5. classify remaining holes as:
   - intentionally unreachable
   - simulator / environment limitation
   - missing scenario
   - real RTL or VIP bug

At the current checkpoint, the most important open holes are not packetizer stress anymore; they are CSR/control/reset visibility and top-level wrapper coverage.

## Calibration note

The RTL is designed for offline calibration, not on-chip correction. The host reconstructs and corrects time using exported raw features and/or timestamps.

Previously reported calibration quality remains the repository target:

- single-shot post-calibration RMSE: about `18.89 ps`
- `N=100` averaging RMSE: about `1.90 ps`

## Synthesis note

For synthesis, the oscillator wrapper must use the stub path. The behavioral oscillator model is for simulation only.

What the current Genus flow is intended to validate:

- RTL synthesizability
- latch audit for intentional async SR latches
- `clk_sys` timing setup
- oscillator-domain virtual-clock timing sanity
- area / QoR / reporting infrastructure

What it does **not** replace:

- final macro timing for the analog oscillator
- signoff STA
- formal CDC signoff
- post-layout correlation

## Documentation index

| Document | Purpose |
| --- | --- |
| `docs/01_ARCHITECTURE.md` | block-level architecture and dataflow |
| `docs/02_OUTPUT_PROTOCOL.md` | 16-bit output packet format |
| `docs/03_CSR_MAP.md` | CSR programming model |
| `docs/04_VERIFICATION.md` | bench inventory, VIP flow, coverage strategy |
| `docs/05_OFFLINE_CALIBRATION_PLAN.md` | calibration methodology and analysis |
| `docs/06_DEADTIME_ANALYSIS.md` | recovery / throughput discussion |
| `docs/07_DESIGN_REVIEW.md` | design review findings and silicon-readiness concerns |
| `docs/08_LAB_RUNBOOK.md` | server workflow and run commands |
| `docs/09_PROJECT_STATUS.md` | current repository status and recommended next steps |
| `tb/vip/README.md` | VIP internals and usage |
| `syn/README.md` | Genus flow details |
