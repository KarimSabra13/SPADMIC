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
| [`TOP/`](TOP/) | SPADMIC top-level integration (3-axis TDC, arbiter, position scanner, CSR) | First integration scaffold — lint clean, unit tests passing |
| [`I2C/`](I2C/) | I2C slave and CSR bridge for chip configuration | First-pass implementation — lint clean |
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
- the most recent merged IMC report observed on the lab server improved to `11486 / 16389 (70.08%)` with average grade `82.05%`,
- the current repo further expands the maintained VIP closure suite with deterministic overflow/recovery and pad-reset readback checks,
- the repository is suitable for **exploratory offline calibration**, but not yet for synthesis signoff or freeze.

See [`MPTDC/README.md`](MPTDC/README.md) for the detailed architecture, flows, and status of the TDC implementation.

## SPADMIC Top-Level Integration

Branch `SPADMIC_top_v1` contains the first chip-level integration scaffold:

- **3 TDC axes** (X, Y, Z) each wrapping an `mptdc_top_asic` instance with a reverse start-stop qualifier
- **Shared TDC TX path** via a 3-to-1 round-robin arbiter ensuring packet atomicity
- **Position scanner** detecting up to 2 clusters per axis on 127-bit SPAD line bitmaps
- **I2C-to-CSR bridge** for configuration with address-decoded regions (Global, TDC\_X/Y/Z, Position)

Key design rules:
- `clk_sys = 160 MHz`, `clk_ref_40m = 40 MHz`
- Reverse start-stop: SPAD event → START, next 40 MHz rising edge → STOP
- No packet interleaving on shared TX
- Position block has its own dedicated TX path

See [`TOP/docs/SPADMIC_TOPLEVEL_PLAN.md`](TOP/docs/SPADMIC_TOPLEVEL_PLAN.md) for the full architecture design note.

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
├── TOP/                    SPADMIC top-level integration
│   ├── rtl/                Integration RTL (wrappers, arbiter, position, CSR)
│   ├── tb/                 Unit and integration testbenches
│   ├── docs/               Architecture design notes
│   └── filelist.f          Compile list (references MPTDC/ and I2C/)
├── I2C/                    I2C control plane
│   ├── rtl/                I2C slave and CSR bridge
│   └── filelist.f          Compile list
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

### SPADMIC top-level (branch SPADMIC_top_v1)

```bash
git checkout SPADMIC_top_v1
cd MPTDC

# Lint full SPADMIC top
verilator --lint-only --timing +define+MPTDC_USE_OSC_MODEL \
  -f rtl/filelist.f -f ../TOP/filelist.f -f ../I2C/filelist.f \
  --top-module spadmic_top_v1

# Run SPADMIC unit tests
verilator --binary --timing rtl/pkg/mptdc_pkg.sv \
  ../TOP/rtl/spadmic_pkg.sv ../TOP/rtl/spadmic_ref_stop_qualifier.sv \
  ../TOP/tb/tb_spadmic_ref_stop_qualifier_unit.sv \
  --top-module tb_spadmic_ref_stop_qualifier_unit && \
  obj_dir/Vtb_spadmic_ref_stop_qualifier_unit
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
