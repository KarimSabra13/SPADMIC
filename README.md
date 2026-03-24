# MPTDC v2.0 — Vernier Multi-Phase TDC

A high-performance Vernier Time-to-Digital Converter for SPAD matrix readout, featuring triple-buffer architecture for minimal deadtime and purely offline calibration.

## Key Features

- **10 ps LSB** Vernier resolution (NE=9, Δ=5ps)
- **~2-4 ns deadtime** via triple-buffer snapshot contexts
- **15 hits per conversion** within 32 ns measurement window
- **Purely offline calibration** — no on-chip LUT or correction logic
- **16-bit ready/valid output** with configurable modes
- **Dual input** — SPAD matrix or calibration pulse injection
- **Per-context + global watchdog** for robust operation

## Quick Start

```bash
# Lint check
verilator --lint-only --timing +define+MPTDC_USE_OSC_MODEL \
  -f rtl/filelist.f --top-module mptdc_top_asic

# Run single test
bash scripts/sim/run_tb.sh tb_single_conv

# Smoke test (lint + core test)
bash ci/run_smoke.sh

# Full regression
bash ci/run_full_regression.sh
```

## Repository Structure

```
rtl/                    RTL source files
├── pkg/                Package (constants, types)
├── top/                Top-level modules
├── async/              Async-domain logic
├── cdc/                Clock-domain crossing
├── osc/                Ring oscillators
├── pd/                 Phase detectors
├── ctrl/               Control (FSM, watchdog, mux)
├── readout/            Output chain (serializer, CSR)
└── filelist.f          Source file list

tb/                     Testbenches
├── common/             Shared TB utilities
├── unit/               Unit tests
└── int/                Integration tests

scripts/sim/            Simulation scripts
ci/                     CI/CD scripts
docs/                   Documentation
```

## Documentation

| Document | Description |
|----------|-------------|
| [Architecture](docs/01_ARCHITECTURE.md) | System overview, block diagram, triple-buffer design |
| [Output Protocol](docs/02_OUTPUT_PROTOCOL.md) | 16-bit bus packet format specification |
| [CSR Map](docs/03_CSR_MAP.md) | Register map and configuration guide |
| [Verification](docs/04_VERIFICATION.md) | Test strategy and CI |
| [Calibration Plan](docs/05_OFFLINE_CALIBRATION_PLAN.md) | Offline calibration workflow |
| [Deadtime Analysis](docs/06_DEADTIME_ANALYSIS.md) | Performance characteristics |

## Requirements

- **Verilator** ≥ 5.0 (for simulation)
- Optional: Xcelium or VCS (commercial simulators)

## Architecture Summary

```
START/STOP → Async Frontend → Ring Oscillators → PD Matrix (81 cells)
                    ↓
          Context Bank (3 slots) → Writer → Async FIFO → 16-bit TX
                    ↓
          FSM + Watchdog (sys clock domain)
```

The triple-buffer allows frontend re-arm while previous conversion data is still being read out, achieving ~45× deadtime improvement over v1.

## License

Copyright © 2025 Karim Sabra. All rights reserved.
