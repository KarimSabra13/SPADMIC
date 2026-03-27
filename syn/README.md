# MPTDC Synthesis Flow — Cadence Genus / XFAB XH018 (180 nm)

## Overview

This directory contains the complete Cadence Genus synthesis flow for the
MPTDC (Multi-Phase Time-to-Digital Converter). The flow is structured as
four sequential TCL scripts that you source step-by-step inside the Genus
shell.

**Target Technology:** XFAB XH018 — 180 nm CMOS  
**System Clock:** 160 MHz (6.25 ns period)  
**Oscillator Clocks:** osc_slow ~1 GHz, osc_fast ~1.11 GHz (virtual, from analog macro)

## Directory Structure

```
syn/
├── README.md                 ← You are here
├── filelist_synth.f           ← RTL compile list (excludes osc_model)
├── constraints/
│   └── mptdc.sdc              ← Timing constraints (clocks, I/O, CDC, false paths)
├── scripts/
│   ├── genus_setup.tcl        ← Step 1: Library & design configuration
│   ├── genus_elaborate.tcl    ← Step 2: Read HDL, elaborate, lint
│   ├── genus_synthesize.tcl   ← Step 3: Synthesis (generic → map → opt)
│   └── genus_reports.tcl      ← Step 4: Post-synthesis reports
├── work/                      ← (gitignored) Genus working directory
├── outputs/                   ← (gitignored) Netlist, SDC, SDF outputs
├── reports/                   ← (gitignored) All synthesis reports
└── logs/                      ← (gitignored) Genus log files
```

## Prerequisites

1. **Cadence Genus** installed and in your `PATH`
2. **XFAB XH018 PDK** with:
   - Liberty timing library (`.lib`) — at least typical corner
   - LEF physical library (`.lef`) — optional for logic synthesis
   - Technology LEF (`.tlef`) — optional for logic synthesis
3. Valid Cadence license

## Quick Start

### Step 0: Configure Library Paths

Edit `scripts/genus_setup.tcl` and set the three placeholder paths:

```tcl
set XFAB_PDK_ROOT "/path/to/xfab/XH018"
set LIB_TYPICAL   "${XFAB_PDK_ROOT}/diglibs/D_CELLS_HD/.../typical.lib"
set LEF_FILE      "${XFAB_PDK_ROOT}/diglibs/D_CELLS_HD/.../cells.lef"
set TECH_LEF      "${XFAB_PDK_ROOT}/techdata/xh018_xx.tlef"
```

### Step 1: Launch Genus and Run

```bash
cd syn/scripts
genus -log ../logs/genus_run.log
```

Inside the Genus shell, source the scripts in order:

```tcl
source genus_setup.tcl        ;# Load libraries
source genus_elaborate.tcl    ;# Read RTL, elaborate, lint
source genus_synthesize.tcl   ;# Synthesize (generic → map → opt)
source genus_reports.tcl      ;# Generate all reports
```

Or run all at once:

```tcl
source genus_setup.tcl
source genus_elaborate.tcl
source genus_synthesize.tcl
source genus_reports.tcl
```

## Script Details

### `genus_setup.tcl` — Library & Design Configuration

**What it does:**
- Sets the XFAB PDK root path and locates the Liberty timing library
- Configures project directory paths (RTL, outputs, reports, logs)
- Reads the Liberty `.lib` file into Genus
- Configures global Genus settings:
  - `hdl_error_on_latch false` — allows intentional latches (async frontend)
  - `syn_ramstyle registers` — forces register-based memory (no SRAM IP)
  - `hdl_sv_packages true` — enables SystemVerilog package support

**What to check:**
- Genus prints the library name it loaded — verify it matches your PDK
- If the path is wrong, you'll get `Error: Cannot open file`

---

### `genus_elaborate.tcl` — Read HDL, Elaborate, Lint

**What it does:**
1. **Reads RTL** from `filelist_synth.f`:
   - 20 SystemVerilog files in compile order (package → leaves → top)
   - Excludes `mptdc_osc_model.sv` (non-synthesizable behavioural oscillator)
   - Adds `+define+SYNTHESIS` (activates synthesis-specific code guards)

2. **Elaborates** `mptdc_top_asic`:
   - Resolves all parameters (NE=9, N_CTX=2, MAX_HITS=15, etc.)
   - Unrolls generate blocks (81 PD cells = 9×9 matrix)
   - Validates parameter-check `$fatal` guards (e.g., STAGES ≥ 2)

3. **Forces register memory**:
   - Sets `syn_ramstyle = registers` globally
   - The 57-bit × 64-entry sync FIFO will be implemented as flip-flops
   - No SRAM compiler/IP is needed

4. **Reads SDC constraints** from `constraints/mptdc.sdc`

5. **Runs design checks** (`check_design -all`):
   - Reports undriven/unloaded ports
   - Detects combinational loops (should be 0)
   - Flags multi-driven nets
   - Checks constraint completeness

6. **Reports inferred latches**:
   - Expect exactly **5 intentional latches** from `mptdc_async_frontend_v2`:
     - `start_latched_q` — SR latch capturing async START pulse
     - `stop_latched_q` — SR latch capturing async STOP pulse
     - `active_ctx_q[1:0]` — Transparent latch for context ID
     - `ctx_drain_q[0]`, `ctx_drain_q[1]` — Per-context drain SR latches
   - Any additional latches indicate an RTL bug

**What to check:**
- `check_design.rpt` — should have no errors, warnings are OK to review
- `latch_report.rpt` — exactly 5 latches, all in `async_frontend_v2`
- `hierarchy.rpt` — 81 `mptdc_pd_cell` instances under `u_core`

---

### `genus_synthesize.tcl` — Three-Phase Synthesis

**What it does:**

**Phase 1: `syn_generic` (Technology-Independent)**
- Boolean optimization: constant propagation, dead-code removal
- Resource sharing: identifies shared arithmetic (adders, comparators)
- FSM encoding: chooses optimal encoding (one-hot, binary, gray)
- Output: optimized design in generic gates (AND, OR, MUX, FF, LATCH)
- Generates `timing_post_generic.rpt` — catches gross timing violations

**Phase 2: `syn_map` (Technology Mapping)**
- Maps generic gates to actual XFAB XH018 standard cells
- Selects drive strengths based on fanout and timing requirements
- Maps latches to XFAB latch cells (DLN/DLP variants)
- Maps FFs to XFAB DFF cells with appropriate set/reset
- Generates `timing_post_map.rpt` — post-mapping timing snapshot

**Phase 3: `syn_opt` (Incremental Optimization)**
- Gate sizing: upsizes cells on critical paths, downsizes non-critical
- Buffer insertion: adds buffers for high-fanout nets
- Logic restructuring: re-synthesizes critical cones
- Hold-time fixing: inserts delay cells where hold is violated

**Outputs written:**
- `outputs/mptdc_top_asic_synth.v` — Gate-level Verilog netlist
- `outputs/mptdc_top_asic_synth.sdc` — Updated timing constraints
- `outputs/mptdc_top_asic_synth.sdf` — Standard Delay Format (for GLS)
- `outputs/mptdc_top_asic.genus_db` — Genus database (for incremental)

**What to check:**
- Compare `timing_post_generic.rpt` vs `timing_post_map.rpt` — slack should
  improve or stay similar after mapping
- If timing degrades significantly, the library may not have cells fast enough

---

### `genus_reports.tcl` — Comprehensive Post-Synthesis Reports

**What it does:**

Generates 12 report files covering every aspect of synthesis quality:

| Report File | Content | What to Look For |
|---|---|---|
| `timing_setup.rpt` | Worst 20 setup paths | All paths should have positive slack |
| `timing_hold.rpt` | Worst 20 hold paths | Hold violations need delay cell insertion |
| `timing_summary.rpt` | Per-clock timing summary | WNS (Worst Negative Slack) per clock |
| `timing_violations.rpt` | Only violating paths | **Must be empty** for clean synthesis |
| `area_summary.rpt` | Total area | Compare against chip budget |
| `area_detail.rpt` | Per-module area breakdown | Identify area-dominant blocks |
| `power_summary.rpt` | Total power (dynamic + leak) | Compare against power budget |
| `power_detail.rpt` | Per-module power breakdown | Find power-hungry modules |
| `gates_summary.rpt` | Total gate count | Sanity check for 180 nm |
| `gates_by_type.rpt` | Cell usage statistics | Verify cell library coverage |
| `gates_sequential.rpt` | FF and latch count | Cross-check with RTL |
| `latch_audit.rpt` | Latch instances | **Must show exactly 5 latches** |
| `clock_summary.rpt` | Clock definitions | Verify 3 clocks defined correctly |
| `drv_summary.rpt` | Design rule violations | Max transition, max fanout, max cap |
| `constraint_coverage.rpt` | Unconstrained paths | Should have minimal unconstrained endpoints |
| `qor_summary.rpt` | Quality of Results | Overall synthesis health dashboard |

**What to check (trial synthesis checklist):**
1. ✅ `timing_violations.rpt` is empty (no setup violations)
2. ✅ `latch_audit.rpt` shows exactly 5 latches (all in async_frontend)
3. ✅ Area is reasonable for 180 nm (typical MPTDC: ~50K-100K gates)
4. ✅ No critical DRV violations
5. ✅ All three clocks appear in `clock_summary.rpt`

## SDC Constraints Explained

The `constraints/mptdc.sdc` file defines:

| Section | What | Why |
|---|---|---|
| **Primary clock** | `clk_sys` @ 160 MHz (6.25 ns) | System domain — CSR, FIFO, drain logic |
| **Oscillator clocks** | Virtual `clk_osc_slow` @ 1 GHz, `clk_osc_fast` @ 1.11 GHz | Timing analysis for osc-domain logic (stubs provide static output) |
| **Clock groups** | All 3 clocks are asynchronous | CDC handled by structural synchronizers |
| **False paths** | START/STOP async inputs, async_rst_n | Truly asynchronous — no timing relationship |
| **CDC dont_touch** | Reset sync, gray sync, pulse sync flops | Prevents optimization from breaking metastability barriers |
| **CDC max_delay** | Cross-domain paths limited to 1 period | Ensures combinational path fits within synchronizer window |
| **I/O delays** | 2 ns input/output delay on CSR and narrow ports | Conservative for 180 nm external routing |
| **Design rules** | Max fanout 20, max transition 0.5 ns | Prevents signal integrity issues |

## Oscillator Notes

The oscillator blocks in this design are **analog macros** — they will be
designed separately by an analog designer as current-starved ring oscillators.

For synthesis:
- `mptdc_osc_stub.sv` provides **static phase outputs** (phase[0]=1, rest=0)
- No actual oscillation occurs — the stub is purely for logic verification
- The SDC uses **virtual clocks** at the oscillator pins so Genus can
  analyze timing through the oscillator-domain logic
- In the final chip, the stub is replaced by the physical oscillator macro

For simulation:
- `mptdc_osc_model.sv` provides a **behavioural oscillator** with `#delay`
- Supports configurable jitter via `+osc_jitter_ps=<value>` plusarg
- Selected via `` `define MPTDC_USE_OSC_MODEL `` (never set during synthesis)

## Troubleshooting

### "Cannot open file" errors
→ Check `genus_setup.tcl` — the XFAB_PDK_ROOT path must point to your
actual PDK installation directory.

### Unexpected latches (more than 5)
→ Check `latch_report.rpt` for the module hierarchy. Latches outside
`mptdc_async_frontend_v2` indicate an RTL bug. Common cause: incomplete
`if/case` in `always_comb` blocks.

### Timing violations on oscillator-domain paths
→ The PD pipeline must fit within ~0.9 ns (osc_fast period). If violations
appear, check the critical path — it's likely through the phase detector
matrix OR-reduction tree. May need pipeline registers.

### FIFO area too large
→ The 57b × 64 sync FIFO is implemented entirely in flip-flops (~3648 FFs).
This is intentional (no SRAM IP available). If area is critical, consider
reducing FIFO_DEPTH from 64 to 32 in `mptdc_pkg.sv`.

### Memory inference warnings
→ Genus may warn about "array not mapped to memory". This is expected —
we force register-based implementation via `syn_ramstyle = registers`.
