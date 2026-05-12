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
| QRC tech files | ❌ Optional but recommended | Enables RC-corner-aware MMMC during synthesis and is now wired by default for the verified lab-server deck |

**Bottom line:** Get your `.lib` file (e.g., `D_CELLS_HD_LPMOS_typ_1_80V_25C.lib`),
set the path, and you can run synthesis immediately.

### What to Set Before Running

The checked-in defaults now target the verified lab-server install:

- `PDK_ROOT=/data/pdk/xfab/xh018`
- `SC_ROOT=$PDK_ROOT/diglibs/D_CELLS_HD/v6_0`
- `TECHNOLOGY_LEF=$PDK_ROOT/cadence/v9_0/techLEF/v9_0_1/xh018_xx41_HD_MET4_METMID.lef`
- `QRC_ROOT=$PDK_ROOT/cadence/v10_1/QRC_pvs/v10_1_1/XH018_1141`

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

The checked-in flow now builds BC/TC/WC MMMC views by default, with
`wc_view` selected for setup and `bc_view` selected for hold. Override
`design(selected_setup_analysis_views)` / `design(selected_hold_analysis_views)`
in `syn/inputs/mptdc.defines` if you need a tc-only bring-up run.

### How to Run

```bash
cd syn/scripts
mkdir -p ../logs
genus -files genus.tcl -log ../logs/genus.log
```

That's it — `genus.tcl` handles everything: loading libraries, reading RTL,
elaborating, synthesizing, generating reports, and exporting the netlist.
The default optimization label is `area_first`, with high/extreme Genus effort
settings and expanded QoR reports for area/timing/power triage. Override only
when intentionally running a different experiment:

```bash
export MPTDC_OPT_GOAL=timing_first
```

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

### Tracked Lab Snapshot Workflow

Because the raw Genus output tree is gitignored and the XFAB PDK is only
available on the lab server, the maintained review workflow is:

1. run Genus on the lab server from `MPTDC/syn/scripts`
2. collect the key reports/log/netlist/SDC into `MPTDC/lab_snapshots/<run_tag>/`
3. commit that snapshot on `SPADMIC_TOP`
4. pull the branch locally and review the tracked snapshot here

This keeps the repository clean while still preserving synthesis evidence for
future analysis sessions.

Use the helper after each lab run:

```bash
cd MPTDC/syn/scripts
bash collect_snapshot.sh genus_$(date +%Y%m%d_%H%M)_area_first
```

First reports to review:

- `run_manifest.rpt` — exact PDK/MMMC/settings baseline
- `timing_violations.rpt` and `timing_summary.rpt` — timing closure status
- `report_area.rpt` and `report_area_hier.rpt` — total and per-hierarchy area targets
- `report_power.rpt` and `report_power_hier.rpt` — vectorless or activity-backed power baseline
- `report_design_rules.rpt` — transition/fanout/capacitance issues
- `latch_audit.rpt` — intentional async-frontend latch count

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
| **SDC parameters** | `INPUT_DELAY_*`, `OUTPUT_DELAY_*`, `CLOCK_UNCERTAINTY`, `MAX_FANOUT` | Constraint values |
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
| **§6 CDC protection** | best-effort `set_dont_touch` wrappers on sync FF patterns | Preserves synchronizers where the active Genus/DC parser accepts the matched objects |
| **§7 CDC max delay** | simplified `set_max_delay` across domains | Keeps CDC intent without relying on unsupported `-datapath_only` forms |
| **§8-9 I/O delays** | 2 ns input/output delay | Conservative for 180 nm routing |
| **§10 Load/drive** | 50 fF load, 100 ps transition | Pad characteristics |
| **§11 Design rules** | Max fanout 20, max transition 0.5 ns | Signal integrity |

---

### File: `inputs/mptdc.mmmc`

**What it does:**
Defines PVT (Process-Voltage-Temperature) corners for timing analysis.
The checked-in flow defines BC/TC/WC corners and selects signoff-oriented
views by default.

| Corner | PVT | Purpose | Status |
|---|---|---|---|
| **TC** (typical) | TT, 1.80V, 25°C | Correlation / debug | ✅ Defined |
| **BC** (best-case) | FF, 1.98V, −40°C | Hold analysis | ✅ Active |
| **WC** (worst-case) | SS, 1.62V, 125°C | Setup analysis | ✅ Active |

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
| `mptdc_report_timing` | Generates Genus-22.13-compatible worst-path, summary, and violation reports; writes a note when a dedicated hold split is unavailable |
| `mptdc_default_cost_groups` | Creates reg2reg, in2reg, reg2out, in2out path groups |
| `mptdc_latch_audit` | Writes a latch inventory via `get_db` and compares the count to the expected value (5) |
| `mptdc_full_reports` | Generates all post-synthesis reports (area, gates, power, DRV, QoR) |
| `mptdc_print_summary` | Final summary banner with checklist |

---

### File: `scripts/settings.tcl`

**What it does:**
Genus tool-level configuration (not design-specific):

- **HDL settings**: SystemVerilog mode, latch tolerance, undriven signals
- **Memory inference**: request `syn_ramstyle = registers` when supported by the
  active Genus build
- **Genus compatibility**: tolerate unsupported root attributes and minor SDC
  option differences across lab-server releases
- **Clock gating**: Disabled for bring-up because the current XFAB HD ICG cells are marked `dont_use`
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
  └── Resolve parameters, unroll generates (64 PD cells)
  └── Run check_design (lint)

Stage 5: POST_ELABORATION
  └── Init design with MMMC constraints
  └── check_timing_intent (SDC lint)
  └── Save elaboration checkpoint

Stage 6: SYNTHESIS
  └── Define custom cost groups when supported, otherwise keep default clock-derived groups
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
(~3648 FFs). The settings script requests `syn_ramstyle = registers` when the
active Genus build supports that attribute; if the build rejects the root
attribute, the flow now continues instead of aborting.

### Genus-Version Tolerance

The checked-in flow is written to survive the small command-set differences seen
across deployed Genus releases:

- unsupported root attributes are guarded instead of aborting the run
- unsupported SDC option forms are reduced to the simpler forms accepted by the lab-server build
- unsupported cost-group commands fall back to the default clock-derived optimization groups
- latch reporting uses `get_db` instead of `report_gates -type`

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

**The intended virtual clock trick:**
In the SDC, we define **virtual clocks** on the stub's output pins:
```tcl
create_clock -name clk_osc_slow -period 1.0 [get_pins u_core/u_osc_slow/u_stub/phase[0]]
create_clock -name clk_osc_fast -period 0.9 [get_pins u_core/u_osc_fast/u_stub/phase[0]]
```
However, the current Genus 22.13 lab-server run still propagates the constant
stub values into the netlist and reports hundreds of oscillator-domain
sequential clock pins as having **no clock waveform**. In other words, the
virtual clocks are created, but this stub model is **not yet sufficient to make
oscillator-domain timing signoff-meaningful** in the active bring-up flow.

**What gets validated vs what doesn't:**

| Aspect | Validated? | Why |
|---|---|---|
| Combinational logic depth in osc domain | ⚠️ Partial only | Current constant stub still collapses many osc clocks to case constants |
| CDC synchronizer paths (osc↔sys) | ⚠️ Intent only | Simplified constraints load, but current stub prevents full waveform-based checking |
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

### Advancing Before the Analog Oscillator Is Finished

The analog oscillator design does **not** need to be transistor-final before the
digital flow can advance. What must be frozen early is the **macro contract**
that digital synthesis and physical design will build around.

At the current checkpoint, the right interpretation is:

- continue with **system-domain synthesis bring-up**
- continue with **floorplan / placement planning**
- continue with **PD-matrix symmetry planning**
- do **not** claim oscillator-domain timing closure yet

The current constant-output oscillator stub is good enough to keep the digital
project moving, but it is **not** a valid endpoint for mixed-signal timing
signoff. The Genus lab run already shows why: the stub collapses to constants,
the virtual oscillator clocks are stripped during optimization, and hundreds of
oscillator-domain sequential pins end up without a waveform.

#### What the analog designer must freeze as soon as possible

For each oscillator macro, freeze these interface items before final analog
completion:

1. **Tap contract**
   - exactly `9` phase taps per oscillator
   - stable logical order (`tap[0]` ... `tap[8]`)
   - unambiguous mapping between tap name and physical output pin
2. **Macro outline**
   - approximate width / height
   - preferred orientation(s)
   - origin convention and pin coordinates
   - keepout / blockage expectations around the macro
3. **Electrical contract**
   - nominal output swing / logic interface assumption
   - maximum capacitive load per tap
   - whether digital buffering is allowed or forbidden on tap nets
   - enable / reset / trim interface semantics
4. **Power / noise contract**
   - supply pins and domains
   - guard-ring / shielding expectations
   - allowed aggressor classes near tap outputs
   - any substrate or supply isolation requirements

#### What digital / PnR can do immediately

Even before the oscillator transistor design is done, the project can still
advance in a disciplined way:

1. **Replace the current constant stub for synthesis/PnR handoff**
   - black-box Verilog wrapper
   - LEF abstract with the real `9` tap pins
   - placeholder timing shell / macro Liberty (even approximate) so the clock
     source survives synthesis
   - preserve / dont_touch treatment on the oscillator macro instances
2. **Build an early floorplan**
   - reserve real space for the two oscillator macros
   - reserve a dedicated symmetry-critical region for the PD matrix
   - place the oscillator macros with pin locations that make matched routing
     physically achievable
3. **Run early place-and-route experiments**
   - verify that the `8 x 8` PD matrix can be placed without overlap or
     legalization distortion
   - verify that tap routing can be matched with practical metal resources
   - verify that the surrounding logic can escape without disturbing the matrix

#### What must wait for the real macro model

These items are **not** credible until the oscillator macro has a real timing
abstraction:

- oscillator-domain setup / hold closure
- final phase-tap skew assessment
- final RC-matching judgment on tap delivery
- startup / enable / trim timing behavior
- analog jitter / phase-noise interaction with the digital front-end

### `8 x 8` PD Matrix — Physical Design Requirements

The PD matrix is the most symmetry-sensitive digital block in the design. The
goal is not merely “legal placement”; the goal is **matched electrical
environment** across the full detector array.

The architecture is fixed:

- `8` slow-phase taps
- `8` fast-phase taps
- `64` PD cells (`8 x 8`)
- each PD cell sees one slow tap and one fast tap

That means the matrix must be treated as a **symmetry-critical island**, not as
ordinary standard-cell logic.

#### Non-negotiable implementation goals

| Requirement | Why it matters | Implementation direction |
|---|---|---|
| Fixed `8 x 8` regular array | Prevents placer distortion from changing electrical symmetry | Preserve matrix hierarchy; constrain to a dedicated region / fence |
| No PD overlap or spill | Legalizer movement destroys regular geometry | Keep enough whitespace and rows so the whole array fits cleanly |
| Slow taps distributed uniformly to rows | Keeps one consistent slow-phase environment per row | Route slow taps as matched row trunks |
| Fast taps distributed uniformly to columns | Keeps one consistent fast-phase environment per column | Route fast taps as matched column trunks |
| Same routing class for matched nets | RC mismatch comes from metal / via / shielding differences, not only length | Same layers, widths, spacing, shielding, via count, and jog style |
| Same load seen by each tap | Unequal fanout changes edge shape and delay | Keep one PD input load per crossing and matched buffering policy |
| No opportunistic reshaping by tools | Ungrouping / logic spreading breaks geometric intent | Preserve hierarchy; use regions / placement constraints; review optimization settings |
| Quiet routing neighborhood | Nearby switching aggressors can disturb the matched nets differently | Keep unrelated high-activity nets away from the tap-routing channels |

#### Practical placement topology

For a clean physical implementation, the preferred conceptual topology is:

1. one oscillator macro feeds the **row family**
2. the other oscillator macro feeds the **column family**
3. slow taps fan out in one dominant direction
4. fast taps fan out orthogonally
5. each PD cell sits at one controlled row/column intersection

In practice this means:

- place the slow-oscillator macro on one side of the matrix
- place the fast-oscillator macro on an orthogonal side if possible
- route the slow taps as matched trunks across the rows
- route the fast taps as matched trunks across the columns
- keep PD outputs and downstream logic escape routes away from the sensitive tap
  channels

#### Important note on “same wire length”

The design goal should be stated carefully.

It is reasonable to ask for:

- the **same routing topology**
- the **same metal stack**
- the **same shielding strategy**
- the **same via count**
- and as much **length matching** as is physically practical

But for an edge-fed macro, making every source-to-destination path literally
identical in Euclidean length is often impossible. The more correct target for
mixed-signal quality is **matched RC and matched environment**, not only a
single geometric length number.

So the review criterion after PnR should be:

- row-family matching
- column-family matching
- extracted parasitic consistency
- skew and imbalance metrics from routed extraction

not just “did every segment have exactly the same drawn length.”

#### Buffering policy for tap nets

If the oscillator taps can directly drive the PD inputs within the allowed load
budget, that is the cleanest case.

If buffering becomes necessary, do **not** allow ad-hoc per-net fixes.
Instead:

- use the same buffer structure on every matched tap family
- place the buffers symmetrically
- keep the same drive strength and stage count
- keep the same metal / via environment on the buffer outputs

An unmatched buffer insertion can easily break more symmetry than it fixes.

#### What synthesis can and cannot enforce

Cadence Genus can help with:

- preserving hierarchy
- preventing macro removal
- preventing unwanted logical reshaping around the matrix
- keeping the netlist aligned with the intended block structure

But Genus **cannot by itself guarantee**:

- symmetric physical placement
- equal tap routing topology
- equal RC
- matched shielding
- no overlap / no spill after legalization

Those are fundamentally **floorplanning / placement / routing** responsibilities
for Innovus (and possibly semi-custom manual guidance for the PD island).

#### Recommended mixed-signal handoff strategy

1. Freeze the oscillator macro contract.
2. Replace the synthesis constant stub with a preserved macro placeholder.
3. Floorplan the oscillator macros and the `8 x 8` PD island together.
4. Constrain the PD matrix as a symmetry-critical region before detailed place.
5. Route taps with matched topology and review extracted RC/skew explicitly.
6. Only after a real oscillator timing model exists should oscillator-domain STA
   be treated as signoff-relevant.

### CDC Synchronizers
All clock domain crossings use structural synchronizers with `ASYNC_REG`
attributes. The checked-in flow applies best-effort synchronizer preservation
constraints where the active Genus build accepts the matched objects, but this
area still needs a cleaner tool-native preservation strategy for final signoff.

### Clock Gating
Clock-gating insertion is currently disabled in the checked-in bring-up flow.
The active XFAB HD liberty marks the integrated clock-gating cells as
`dont_use`, so enabling automatic insertion is not reliable until the library
policy is revisited.

### Timing Report Compatibility
The lab-server Genus 22.13 build rejects `report_timing` options such as
`-late`, `-early`, `-summary`, and `-slack_lesser_than`. The checked-in helper
therefore uses only the supported forms:

- a generic worst-path report for the active view
- a QoR-based summary report
- a violations-only report using `-max_slack 0.0`

The helper currently writes a note instead of a split hold report. That is
acceptable for bring-up, but dedicated hold reporting should be revisited before
claiming signoff-quality synthesis reporting.

### Expected Remaining Timing-Intent Noise

Two `check_timing_intent` findings are still expected in the checked-in flow:

- the five async input/reset ports have no clocked external delay because they
  are intentionally asynchronous and are false-pathed
- hundreds of oscillator-domain sequential pins still show no waveform because
  the synthesis stub collapses the oscillator outputs to constants

The first item is acceptable for macro-level bring-up. The second remains the
main blocker to oscillator-domain signoff and will require a preserved macro
placeholder or real oscillator timing model.

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
