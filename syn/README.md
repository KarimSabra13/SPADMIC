# MPTDC Synthesis Flow — Cadence Genus / XFAB XH018 (180 nm)

## Overview

Industry-grade Cadence Genus synthesis flow for the MPTDC (Multi-Phase
Time-to-Digital Converter), targeting the XFAB XH018 180 nm CMOS process.

The flow follows the centralized-defines methodology (inspired by
[enics-labs/rtl2gds-demo](https://github.com/enics-labs/rtl2gds-demo)):
all design variables in one file, separated library definitions, reusable
procedures, and a single `genus.tcl` entry point that orchestrates everything.

**Target Technology:** XFAB XH018 — 180 nm CMOS  
**System Clock:** 160 MHz (6.25 ns period)  
**Oscillator Clocks:** osc_slow ~1 GHz, osc_fast ~1.11 GHz (virtual, from analog macro)

## Directory Structure

```
syn/
├── README.md                          ← You are here
├── filelist_synth.f                    ← RTL compile list (excludes osc_model)
│
├── inputs/                             ← Design-specific definitions
│   ├── mptdc.defines                   ← All variables: ports, clocks, paths, SDC params
│   ├── mptdc.sdc                       ← Timing constraints (parameterized)
│   └── mptdc.mmmc                      ← Multi-Mode Multi-Corner view definitions
│
├── libraries/                          ← Technology library definitions
│   ├── libraries.xh018.tcl             ← XFAB PDK: process, metal stack, physical cells
│   └── libraries.xh018-stdcells.tcl    ← Standard cells: Liberty (.lib), LEF, corners
│
├── scripts/                            ← Synthesis flow scripts
│   ├── genus.tcl                       ← Main entry point (run this)
│   ├── settings.tcl                    ← Genus tool configuration
│   └── procedures.tcl                  ← Helper procs: logging, reports, cost groups
│
├── work/                               ← (gitignored) Genus working directory
├── outputs/                            ← (gitignored) Netlist, SDC, SDF, DB
├── reports/                            ← (gitignored) All synthesis reports
└── logs/                               ← (gitignored) Genus log files
```

## Prerequisites

1. **Cadence Genus** installed and in your `PATH`
2. **XFAB XH018 PDK** with Liberty timing libraries (`.lib`)
3. Valid Cadence license

## Quick Start

### Step 0: Configure Library Paths

Edit two files with your XFAB installation paths:

**`libraries/libraries.xh018.tcl`** — Set the PDK root:
```tcl
set paths(PDK_ROOT) "/your/path/to/xfab/XH018"
```

**`libraries/libraries.xh018-stdcells.tcl`** — Verify lib file names:
```tcl
set paths(SC_ROOT) "$paths(PDK_ROOT)/diglibs/D_CELLS_HD/v3_0"
set paths(LIB_DIR) "$paths(SC_ROOT)/liberty_LPMOS/v3_0_0/PVT_1_80V_range"
```

### Step 1: Run Genus

```bash
cd syn/scripts
genus -files genus.tcl -log ../logs/genus.log
```

That's it — `genus.tcl` handles everything: loading libraries, reading RTL,
elaborating, synthesizing, generating reports, and exporting the netlist.

---

## Flow Details

### File: `inputs/mptdc.defines`

**What it contains:**
All design-specific variables in one place — the single source of truth.

| Variable Group | Examples | Purpose |
|---|---|---|
| **Design hierarchy** | `TOPLEVEL`, `FULLCHIP_OR_MACRO` | What to synthesize |
| **Technology names** | `TECHNOLOGY`, `SC_TECHNOLOGY` | Which library TCL files to load |
| **Clock definitions** | `CLK_NAME/PORT/PERIOD`, `OSC_SLOW_*`, `OSC_FAST_*` | Clock constraints (SDC uses these) |
| **Port names** | `RST_PORT`, `ASYNC_INPUTS` | Reset and async input definitions |
| **SDC parameters** | `INPUT_DELAY`, `CLOCK_UNCERTAINTY`, `MAX_FANOUT` | Constraint values |
| **File paths** | `rtl_dir`, `export_dir`, `synthesis_reports` | Directory structure |
| **MMMC views** | `selected_setup/hold_analysis_views` | Corner selection |
| **Latch audit** | `EXPECTED_LATCH_COUNT = 5` | Post-synthesis verification |

**Why centralized:** Changing a clock frequency or adding a port only requires
editing `mptdc.defines` — the SDC, MMMC, and genus.tcl all read from it.

---

### File: `inputs/mptdc.sdc`

**What it does:**
Defines all timing constraints. Uses variables from `mptdc.defines` so
constraint values are never hardcoded in two places.

| Section | Constraint | Purpose |
|---|---|---|
| **§1 Primary clock** | `create_clock clk_sys -period 6.25` | 160 MHz system domain |
| **§2 Osc clocks** | Virtual clocks at osc stub pins | Timing for osc-domain logic |
| **§3 Clock groups** | `set_clock_groups -asynchronous` | 3 async domains (sys, slow, fast) |
| **§4 Async inputs** | `set_false_path` on START/STOP | No timing relationship |
| **§5 Reset** | `set_false_path` on async_rst_n | Deasserts through sync chain |
| **§6 CDC protection** | `set_dont_touch` on sync FFs | Prevents optimizer from breaking synchronizers |
| **§7 CDC max delay** | `set_max_delay` across domains | Limits combinational path in CDC |
| **§8-9 I/O delays** | 2 ns input/output delay | Conservative for 180 nm routing |
| **§10 Load/drive** | 50 fF load, 100 ps transition | Pad characteristics |
| **§11 Design rules** | Max fanout 20, max transition 0.5 ns | Signal integrity |

---

### File: `inputs/mptdc.mmmc`

**What it does:**
Defines PVT (Process-Voltage-Temperature) corners for timing analysis.
For trial synthesis, only the typical corner (TC) is active. BC and WC
corners are prepared as commented-out templates for signoff.

| Corner | PVT | Purpose | Status |
|---|---|---|---|
| **TC** (typical) | TT, 1.80V, 25°C | Trial synthesis | ✅ Active |
| **BC** (best-case) | FF, 1.98V, −40°C | Hold analysis | 📋 Prepared |
| **WC** (worst-case) | SS, 1.62V, 125°C | Setup analysis | 📋 Prepared |

---

### File: `libraries/libraries.xh018.tcl`

**What it does:**
Technology-level PDK definitions: process node, metal stack, parasitic
extraction files, physical cell names (well taps, fillers, endcaps),
and CTS routing layer preferences.

**Action required:** Set `paths(PDK_ROOT)` and physical cell names.

---

### File: `libraries/libraries.xh018-stdcells.tcl`

**What it does:**
Standard cell library paths for all PVT corners (Liberty `.lib`, LEF, Verilog).
Also defines the driving cell and load pin for SDC constraints.

**Action required:** Verify `.lib` file names match your PDK version.

---

### File: `scripts/procedures.tcl`

**What it does:**
Reusable helper procedures used throughout the flow:

| Procedure | Purpose |
|---|---|
| `mptdc_start_stage` | Prints a banner, creates report subdirectory, tracks elapsed time |
| `mptdc_message` | Formatted info/debug/warning messages |
| `mptdc_report_timing` | Generates setup/hold/summary/violation timing reports |
| `mptdc_default_cost_groups` | Creates reg2reg, in2reg, reg2out, in2out path groups |
| `mptdc_latch_audit` | Counts latches and compares to expected count (5) |
| `mptdc_full_reports` | Generates all post-synthesis reports (area, gates, power, DRV, QoR) |
| `mptdc_print_summary` | Final summary banner with checklist |

---

### File: `scripts/settings.tcl`

**What it does:**
Genus tool-level configuration (not design-specific):

- **HDL settings**: SystemVerilog mode, latch tolerance, undriven signals
- **Memory inference**: `syn_ramstyle = registers` (no SRAM IP available)
- **Clock gating**: Enabled with min 8 FFs threshold
- **Synthesis effort**: Medium (increase to high for tapeout)
- **Verbosity**: Level 7 (detailed logging)

---

### File: `scripts/genus.tcl`

**What it does:**
The single entry point that orchestrates the entire synthesis flow:

```
Stage 1: INIT
  └── Load defines → libraries → settings
  └── Create output directories

Stage 2: MMMC
  └── Load multi-corner view definitions

Stage 3: READ_RTL
  └── Read 20 SystemVerilog files (osc_model excluded)

Stage 4: ELABORATE
  └── Resolve parameters, unroll generates (81 PD cells)
  └── Run check_design (lint)

Stage 5: POST_ELABORATION
  └── Init design with MMMC constraints
  └── check_timing_intent (SDC lint)
  └── Save elaboration checkpoint

Stage 6: SYNTHESIS
  └── Define cost groups (reg2reg, in2reg, reg2out, in2out)
  └── syn_generic  → Phase 1: technology-independent optimization
  └── syn_map      → Phase 2: map to XFAB XH018 cells
  └── syn_opt      → Phase 3: incremental gate sizing, buffering, hold fixing

Stage 7: POST_SYNTHESIS
  └── Timing reports (setup, hold, violations)
  └── Area, power, gate count, design rules, QoR
  └── Latch audit (expect exactly 5)

Stage 8: EXPORT
  └── Gate-level netlist (.v)
  └── Updated SDC
  └── SDF for gate-level simulation
  └── Genus/Innovus database
```

Each stage creates its own report subdirectory under `reports/synthesis/`.

---

## Key Design Decisions

### No SRAM IP
The 57-bit × 64-entry sync FIFO is implemented entirely as flip-flops
(~3648 FFs). `syn_ramstyle = registers` prevents Genus from attempting
SRAM inference.

### Intentional Latches
The async frontend (`mptdc_async_frontend_v2`) uses 5 SR latches for
pulse capture. These are architecturally required — the design captures
sub-nanosecond START/STOP pulses that cannot be sampled by clocked FFs.
The latch audit verifies exactly 5 exist post-synthesis.

### Oscillator Stubs
Oscillators are analog macros (current-starved ring oscillators) designed
separately. For synthesis, `mptdc_osc_stub` provides static outputs.
Virtual clocks at the stub pins enable timing analysis. In the final chip,
stubs are replaced by the physical oscillator macro.

For simulation, `mptdc_osc_model.sv` provides a behavioural oscillator
with `#delay` and configurable jitter via `+osc_jitter_ps=<value>` plusarg.
It is selected via `` `define MPTDC_USE_OSC_MODEL `` (never set during synthesis).

### CDC Synchronizers
All clock domain crossings use structural synchronizers with `ASYNC_REG`
attributes. SDC `set_dont_touch` prevents the optimizer from breaking
these metastability barriers.

---

## Troubleshooting

### "Cannot open file" errors
→ Check `libraries/libraries.xh018.tcl` — `paths(PDK_ROOT)` must point
to your actual XFAB installation.

### Unexpected latches (more than 5)
→ Check `reports/synthesis/post_synthesis/latch_audit.rpt`. Latches
outside `mptdc_async_frontend_v2` indicate an RTL bug.

### Timing violations on oscillator-domain paths
→ The PD pipeline must fit within ~0.9 ns. If violated, the critical path
is likely through the phase detector OR-reduction tree.

### FIFO area too large
→ The 57b × 64 FIFO uses ~3648 FFs. To reduce area, change `FIFO_DEPTH`
from 64 to 32 in `rtl/pkg/mptdc_pkg.sv`.

### "Memory not mapped" warnings
→ Expected — we force register-based implementation. Not an error.
