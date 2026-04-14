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

### Current repository status

The synthesis collateral in `syn/` is prepared for a trial Genus run, but it should be interpreted as **flow-ready, not signoff-complete**.

At the current checkpoint:

- the RTL and verification environment are locally validated
- the most recent merged IMC report observed on the lab server improved to `70.08%` overall (average grade `82.05%`), but the design still needs another Cadence rerun after the newest local closure additions before any freeze decision
- targeted closure work is currently focused on CSR/top/reset coverage, so synthesis should still be treated as exploratory rather than freeze-ready
- the oscillator behavioral model is a simulation-only artifact and is excluded from synthesis
- the async frontend intentionally contains `5` latch-style storage elements that must be reviewed, not treated as accidental inference
- final QoR, timing, and library legality still depend on your actual XFAB/XH018 PDK installation and Genus run logs

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

## What You Need to Run Synthesis

### Required PDK Files

For **logic synthesis only**, you need a single file from the XFAB PDK:

| File | Required? | Purpose |
|---|---|---|
| **Liberty `.lib`** | ✅ **YES** | Cell timing, area, and power data — this is the **only** PDK file Genus needs |
| LEF `.lef` | ❌ Optional | Physical cell abstracts — enables "physical-aware" synthesis for better estimates, but not required |
| Technology LEF `.tlef` | ❌ No | Layer/via definitions — only needed for Place & Route (Innovus) |
| QRC tech files | ❌ No | Parasitic extraction — only needed for PnR signoff |

**Bottom line:** Get your `.lib` file (e.g., `D_CELLS_HD_LPMOS_typ_1_80V_25C.lib`),
set the path, and you can run synthesis immediately.

### What to Set Before Running

The checked-in defaults now target the verified lab-server install:

- `PDK_ROOT=/data/pdk/xfab/xh018`
- `SC_ROOT=$PDK_ROOT/diglibs/D_CELLS_HD/v6_0`
- `TECHNOLOGY_LEF=$PDK_ROOT/cadence/v9_0/techLEF/v9_0_1/xh018_xx41_HD_MET4_METMID.lef`

If you are using that server, you can run Genus immediately with no further
library edits. On another machine, override the defaults with shell environment
variables before launching Genus:

```bash
export PDK_ROOT=/your/actual/path/to/xfab/xh018
export SC_ROOT=$PDK_ROOT/diglibs/D_CELLS_HD/v6_0
export TECHNOLOGY_LEF=$PDK_ROOT/cadence/v9_0/techLEF/v9_0_1/xh018_xx41_HD_MET4_METMID.lef
```

The default standard-cell timing set is:

```tcl
set tech_files(STDCELLS_TC_LIB) "$paths(SC_ROOT)/liberty_LPMOS/v6_0_0/PVT_1_80V_range/D_CELLS_HD_LPMOS_typ_1_80V_25C.lib"
set tech_files(STDCELLS_WC_LIB) "$paths(SC_ROOT)/liberty_LPMOS/v6_0_0/PVT_1_80V_range/D_CELLS_HD_LPMOS_slow_1_62V_125C.lib"
set tech_files(STDCELLS_BC_LIB) "$paths(SC_ROOT)/liberty_LPMOS/v6_0_0/PVT_1_80V_range/D_CELLS_HD_LPMOS_fast_1_98V_m40C.lib"
```

For the current checked-in flow, the typical corner is enough for first bring-up
because `syn/inputs/mptdc.mmmc` uses `tc_view` for both setup and hold.

### How to Run

```bash
cd syn/scripts
genus -files genus.tcl -log ../logs/genus.log
```

That's it — `genus.tcl` handles everything: loading libraries, reading RTL,
elaborating, synthesizing, generating reports, and exporting the netlist.

### Generated Directories (Gitignored)

Genus creates several output directories during a run. These are all
gitignored and should **not** be committed:

| Directory | Content | Gitignored? |
|---|---|---|
| `syn/work/` | Genus internal working files | ✅ Yes |
| `syn/outputs/` | Netlist (`.v`), SDC, SDF, Genus database | ✅ Yes |
| `syn/reports/` | All synthesis reports (timing, area, power, etc.) | ✅ Yes |
| `syn/logs/` | Genus log files | ✅ Yes |
| `fv/` | Formal verification directory (auto-created by Genus) | ✅ Yes |

Additionally, Genus may create a `debug.txt` file in the working directory
and various `.genus_db` files — these are also gitignored.

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

### Oscillator Stubs — How Timing Works Without a Real Oscillator

The oscillator blocks are **analog macros** (current-starved ring oscillators)
designed separately by the analog team. They are NOT synthesizable — so how
does Genus perform timing analysis on oscillator-domain logic?

**What Genus sees:**
The `mptdc_osc_stub` module is fully synthesizable — it's just constant assigns:
```verilog
assign phase = {{8{1'b0}}, 1'b1};  // phase[0]=1, all others=0
```
Genus synthesizes this as **tie-high/tie-low cells** (wires to VDD/VSS).
The oscillator "block" essentially disappears — zero gates, zero area.

**The virtual clock trick:**
In the SDC, we define **virtual clocks** on the stub's output pins:
```tcl
create_clock -name clk_osc_slow -period 1.0 [get_pins u_core/u_osc_slow/u_stub/phase[0]]
create_clock -name clk_osc_fast -period 0.9 [get_pins u_core/u_osc_fast/u_stub/phase[0]]
```
Even though `phase[0]` is tied to `1'b1` (not physically toggling), **Genus
treats it as if a 1 GHz / 1.11 GHz clock drives that pin** for timing analysis.
This means:
- All FFs clocked by `phase[0]` (meas_ctrl, gray_cnt_sync, pd_cell, etc.)
  get proper setup/hold analysis against the correct period
- CDC paths (osc→sys) get `set_max_delay` constraints applied
- The PD pipeline timing is checked against the 0.9 ns fast clock period

**What gets validated vs what doesn't:**

| Aspect | Validated? | Why |
|---|---|---|
| Combinational logic depth in osc domain | ✅ Yes | Virtual clock enforces timing |
| CDC synchronizer paths (osc↔sys) | ✅ Yes | `set_max_delay` constraints |
| System clock domain logic | ✅ Yes | Real clock definition |
| Actual oscillator frequency | ❌ No | Analog — not synthesized |
| Phase tap matching / routing skew | ❌ No | Physical routing concern, PnR stage |
| Oscillator startup time | ❌ No | Analog characterization |

**In the real chip:** The stub is replaced by the physical oscillator macro.
At that point, you provide a Liberty model (`.lib`) for the macro that
specifies its output timing characteristics, and PnR connects the macro
outputs to the digital logic.

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
