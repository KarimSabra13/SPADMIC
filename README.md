# MPTDC — Vernier Multi-Phase Time-to-Digital Converter

> **Author:** Karim Sabra  
> **Status:** Pre-synthesis, calibration-validated  
> **License:** Copyright © 2025 Karim Sabra. All rights reserved.

## Overview

MPTDC is a Vernier multi-phase time-to-digital converter designed for SPAD (Single-Photon Avalanche Diode) matrix readout. The architecture is purpose-built for offline calibration: silicon exports raw measurement features over a 16-bit ready/valid stream, and all correction is performed host-side.

**Key specifications:**

| Parameter | Value |
|-----------|-------|
| Nominal LSB | 10 ps |
| Vernier phases | 9 slow × 9 fast (81-cell PD matrix) |
| Max hits per conversion | 15 |
| Context buffers | 2 (double-buffered) |
| Output interface | 16-bit ready/valid |
| Output modes | RAW_FEATURES, RAW_TIMESTAMP, FULL |
| **Calibrated single-shot RMSE** | **18.89 ps** |
| **Calibrated RMSE (N=100 avg)** | **1.90 ps** |

## Architecture

```
mptdc_top_asic
  ├── mptdc_reset_sync          Reset synchronizer
  ├── mptdc_input_mux           SPAD / CAL input selector
  ├── mptdc_csr_minimal         Control & status registers
  └── mptdc_core
       ├── mptdc_async_frontend_v2   Async START/STOP capture
       ├── mptdc_osc_wrapper ×2      Slow + fast ring oscillators
       ├── mptdc_pd_cell ×81         Phase detector matrix
       ├── mptdc_stop_capture_async  STOP-side coarse snapshot
       ├── mptdc_gray_cnt_sync ×2    CDC for coarse counters
       ├── mptdc_meas_ctrl           Measurement FSM
       ├── mptdc_context_bank        Double-buffered context storage
       ├── mptdc_drain_ctrl          Readout drain FSM
       ├── mptdc_sync_fifo           Output FIFO
       ├── mptdc_narrow16_tx_v2      16-bit packet serializer
       └── mptdc_watchdog            START timeout watchdog
```

## Repository Structure

```
rtl/
  pkg/          Package constants, types, Vernier algebra
  cdc/          Reset sync, pulse sync, gray-counter CDC, sync FIFO
  osc/          Oscillator wrapper, simulation model, synthesis stub
  pd/           Phase detector cell
  async/        Async frontend, STOP capture, context bank
  ctrl/         Input mux, measurement FSM, drain FSM, watchdog
  readout/      CSR block, timestamp helper, 16-bit serializer
  top/          Core integration and ASIC top wrapper

tb/
  common/       Shared testbench package and raw monitor
  unit/         5 unit testbenches (leaf block verification)
  int/          9 integration testbenches + campaign collector
  vip/          Class-based VIP (transactions, drivers, monitor, scoreboard)
  tests/        VIP top-level harness

scripts/
  sim/          Simulation runners (run_tb.sh, run_campaign.sh, run_vip_test.sh)
  analysis/     Campaign analysis (analyze_campaign.py)
  calibration/  6D LUT calibrator (calibrate_6d_lut.py)

ci/             CI regression scripts (smoke, full, VIP coverage)
syn/            Cadence Genus synthesis flow (XFAB XH018)
docs/           Architecture, protocol, CSR map, verification, calibration, design review
```

## Quick Start

```bash
# Lint the RTL
verilator --lint-only --timing +define+MPTDC_USE_OSC_MODEL \
  -f rtl/filelist.f --top-module mptdc_top_asic

# Run a single integration test
bash scripts/sim/run_tb.sh tb_single_conv

# Run the full regression (13 directed tests)
bash ci/run_full_regression.sh

# Run VIP smoke tests
bash ci/run_vip_smoke.sh

# Run a data collection campaign (12-core parallel)
bash scripts/sim/run_campaign.sh --jobs 12

# Run calibration
python3 scripts/calibration/calibrate_6d_lut.py
```

### Running on Cadence Xcelium

```bash
# Single VIP test
bash scripts/sim/run_vip_test.sh smoke_single_conv --sim xrun

# Single directed test
bash scripts/sim/run_tb.sh tb_single_conv --sim xcelium

# Full VIP coverage regression (functional + code coverage)
bash ci/run_vip_coverage.sh --sim xrun --clean

# Preview commands without Cadence tools (dry-run)
bash ci/run_vip_coverage.sh --dry-run
```

See [04 Verification](docs/04_VERIFICATION.md) §10 for the complete Xcelium guide.

## Calibration Results

The TDC uses a **6D mean-correction look-up table** keyed on fields available in all output modes:

```
Key: (ns_inf, nf_inf, nslow, nfast_hit, phase0_snap, hit_idx)
```

`ns` and `nf` are deterministically recovered from `t_raw_ps` in compact mode via Vernier algebra — no information loss.

### Single-Shot Precision

| Metric | Pre-Cal | Post-Cal | Improvement |
|--------|---------|----------|-------------|
| RMSE | 425.8 ps | **18.89 ps** | 95.6% |
| MAE | 350.8 ps | 14.6 ps | 95.8% |
| P90 | 637 ps | 32.9 ps | 94.8% |
| P99 | 1057 ps | 45.0 ps | 95.7% |

Validated on 21 million fresh data points (seeds never seen during training). 16,014 LUT bins, 100% coverage.

### Averaging Performance

| Averages | RMSE (ps) |
|----------|-----------|
| 1 | 18.95 |
| 4 | 9.49 |
| 10 | 6.03 |
| 100 | **1.90** |
| 1000 | **0.60** |

Follows 1/√N — residual is purely random noise.

## Verification

- **5 unit tests** covering leaf blocks (context bank, input mux, serializer, reset sync, watchdog)
- **9 integration tests** covering end-to-end conversion, backpressure, calibration injection, deadtime, first-hit mode, overflow, watchdog recovery, stress
- **1 campaign collector** for large-scale data generation (tb_campaign_collect)
- **Class-based VIP** with transaction-level modeling, coverage hooks, and Xcelium compatibility

All 13 directed tests pass on Verilator. The VIP framework targets Xcelium for coverage closure.

## Documentation

| Document | Contents |
|----------|----------|
| [01 Architecture](docs/01_ARCHITECTURE.md) | Module hierarchy and conversion flow |
| [02 Output Protocol](docs/02_OUTPUT_PROTOCOL.md) | 16-bit packet format and parsing |
| [03 CSR Map](docs/03_CSR_MAP.md) | Register addresses, fields, control semantics |
| [04 Verification](docs/04_VERIFICATION.md) | Test suite and VIP description |
| [05 Calibration Plan](docs/05_OFFLINE_CALIBRATION_PLAN.md) | Calibration methodology, LUT results, averaging study |
| [06 Deadtime Analysis](docs/06_DEADTIME_ANALYSIS.md) | Re-arm timing and throughput |
| [07 Design Review](docs/07_DESIGN_REVIEW.md) | Pre-synthesis review findings and recommendations |

## Synthesis Note

The oscillator wrappers instantiate `mptdc_osc_model` (behavioral) when `MPTDC_USE_OSC_MODEL` is defined, or `mptdc_osc_stub` (deterministic placeholder) otherwise. A real silicon build must replace the stub with the target current-starved oscillator macro and constrain the generated clocks accordingly.
