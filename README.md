# SPADMIC — SPAD Matrix Digital IC

> **Author:** Karim Sabra  
> **Affiliation:** IP2I Lyon / Université Claude Bernard Lyon 1  
> **License:** Copyright © 2025 Karim Sabra. All rights reserved.

## Overview

SPADMIC is the digital readout IC for a SPAD (Single-Photon Avalanche Diode) matrix detector. The repository now contains both the digital design work around the TDC and the active LaTeX report used to document the project work and its theoretical context.

## Sub-Projects

| Directory | Description | Status |
|-----------|-------------|--------|
| [`MPTDC/`](MPTDC/) | Vernier Multi-Phase Time-to-Digital Converter | `109/109` Cadence campaign baseline passed; exploratory calibration-ready; targeted coverage closure ongoing |
| [`Rapport_5PSM_KS/`](Rapport_5PSM_KS/) | Rapport d'alternance 5PSM autour de SPADMIC | Rédaction en cours |

## MPTDC

A high-precision Vernier TDC with an 81-cell phase detector matrix, designed for offline calibration. The implementation provides:

- 10 ps nominal LSB,
- 9×9 Vernier phase detector,
- 15-hit multi-hit capability per conversion,
- double-buffered context architecture,
- 16-bit ready/valid output with 3 selectable modes,
- verification and calibration infrastructure.

Current checkpoint summary for `MPTDC/`:

- latest broad Cadence baseline campaign passed `109/109`,
- merged IMC aggregate coverage baseline is `10986 / 16389 (67.03%)` with average grade `73.62%`,
- the repository is suitable for **exploratory offline calibration**, but not yet for synthesis signoff or freeze.

See [`MPTDC/README.md`](MPTDC/README.md) for the detailed architecture, flows, and status of the TDC implementation.

## Report Project

The active report project is stored in [`Rapport_5PSM_KS/`](Rapport_5PSM_KS/). It contains:

- the LaTeX source of the report,
- the figures and front matter,
- a `build_pdf.sh` helper script for iterative PDF builds,
- a `README_COPILOT.md` continuity file capturing writing context and editorial constraints.

Some local reference material used during writing may remain outside the published Git content when redistribution rights are uncertain.

## Repository Structure

```text
SPADMIC/
├── MPTDC/                  Vernier Multi-Phase TDC
│   ├── rtl/                SystemVerilog RTL
│   ├── tb/                 Testbenches and VIP
│   ├── scripts/            Simulation, analysis, and calibration
│   ├── ci/                 Regression scripts
│   ├── docs/               Architecture and calibration documentation
│   └── syn/                Synthesis collateral
└── Rapport_5PSM_KS/        LaTeX report project
```

## Getting Started

### TDC work

```bash
git clone https://github.com/KarimSabra13/SPADMIC.git
cd SPADMIC/MPTDC

verilator --lint-only --timing +define+MPTDC_USE_OSC_MODEL \
  -f rtl/filelist.f --top-module mptdc_top_asic

bash ci/run_full_regression.sh
```

### Report build

```bash
cd SPADMIC/Rapport_5PSM_KS
./build_pdf.sh
```

## Tools

| Tool | Purpose | Required |
|------|---------|----------|
| Verilator | RTL lint & simulation | Yes (primary) |
| Xcelium / xrun | Coverage-driven verification | Optional |
| Python 3.10+ | Calibration and analysis | For calibration only |
| `pdflatex` + `biber` | Report compilation | For report only |
