# Synthesis Inputs — Constraint Rationale

> **Author:** Karim Sabra
> **Context:** MPTDC trial synthesis on XFAB XH018 (180 nm)

This document explains every constraint value in `mptdc.defines` and
`mptdc.sdc`, why each was chosen, and exactly where to look in the PDK
datasheet to replace the placeholder values with accurate numbers.

---

## 1. Input / Output Delays

```tcl
set design(INPUT_DELAY_FULLCHIP)   2.0   ;# ns
set design(OUTPUT_DELAY_FULLCHIP)  2.0   ;# ns
set design(INPUT_DELAY_MACRO)      0.5   ;# ns
set design(OUTPUT_DELAY_MACRO)     0.5   ;# ns
```

### What they mean

These tell Genus how much of the clock period is already consumed
**outside the chip**. The tool computes:

```
Available internal time = CLK_PERIOD − INPUT_DELAY − OUTPUT_DELAY
```

For a full-chip pad-level assumption at `clk_sys = 160 MHz` (6.25 ns):
`6.25 − 2.0 − 2.0 = 2.25 ns` of internal time.

For the checked-in `MACRO` mode, the default placeholder budget is much lighter:
`6.25 − 0.5 − 0.5 = 5.25 ns`. That better matches an on-chip block boundary
until a real top-level timing allocation exists.

### Why 2.0 ns

At 180 nm with wire-bonded QFP/BGA packaging:

| Component         | Typical delay |
|-------------------|---------------|
| Pad buffer (input)  | 0.5–1.5 ns |
| ESD protection     | 0.1–0.3 ns |
| Bondwire + package | 0.2–0.5 ns |
| PCB trace (short)  | 0.1–0.3 ns |
| **Total**          | **~1.0–2.5 ns** |

2.0 ns is a conservative midpoint — if timing closes here, it will close
with the real numbers.

### Where to find real values

| Source | What to look for |
|--------|-----------------|
| **I/O pad Liberty (.lib)** | `cell_rise` / `cell_fall` tables for the selected I/O pad cell (e.g., `BT4R` or `BBC4R` in XFAB). The pad delay from pad-pin to core-pin is the main contributor. |
| **Package datasheet** | Bondwire inductance → propagation delay. Typical QFP-48 bondwire ≈ 0.1–0.3 ns. |
| **Board-level timing** | Trace length × propagation velocity (~6.7 ps/mm for FR-4 microstrip). A 30 mm trace ≈ 0.2 ns. |
| **Receiving device** | Input setup time of the downstream FPGA/MCU (from its datasheet). |

**Formula for accurate replacement:**

```
INPUT_DELAY  = t_pad_in + t_bondwire + t_board + t_setup_upstream
OUTPUT_DELAY = t_pad_out + t_bondwire + t_board + t_setup_downstream
```

### Typical ranges by process node

| Node   | I/O Delay |
|--------|-----------|
| 180 nm | 1.5–3.0 ns |
| 65 nm  | 0.5–1.5 ns |
| 28 nm  | 0.2–0.8 ns |

---

## 1.1 Production Readout Mode

```tcl
set design(PRODUCTION_SHARED_READOUT) 1
```

### What it means

Production SPADMIC TOP consumes each MPTDC through `acq_*` acquisition records
and uses one shared packet serializer. The Genus SDC therefore applies
`set_case_analysis 1` on `shared_readout_en_i` and `set_case_analysis 0` on
`narrow_ready_i` by default so per-axis local `narrow_*` serializers are trimmed.

For standalone MPTDC packet-output synthesis or debug, launch Genus with:

```bash
export MPTDC_SYN_PRODUCTION_SHARED_READOUT=0
```

---

## 2. Input Transition

```tcl
set design(INPUT_TRANSITION) 0.1   ;# ns (100 ps)
```

### What it means

Maximum rise/fall time of signals arriving at the chip's input pads.
It sets how "sharp" the incoming edges are, which affects internal cell
delay calculations (cells are slower with sluggish inputs).

### Why 100 ps

- 180 nm standard cells are characterized with input slews of 0.1–0.5 ns
- 100 ps assumes a clean digital driver (another ASIC or a modern FPGA)
- The async SPAD/CAL inputs are detector pulses (very fast edges)
- The CSR bus is likely driven by FPGA I/O (100–300 ps typical)

### Where to find real values

| Source | What to look for |
|--------|-----------------|
| **Upstream device datasheet** | Output rise/fall time spec (e.g., FPGA I/O `t_rise`, `t_fall`). Xilinx/Intel FPGAs specify this per I/O standard (LVCMOS33, LVTTL, etc.). |
| **I/O pad Liberty (.lib)** | If the upstream drives through another pad cell, look at the pad cell's `rise_transition` / `fall_transition` tables. |
| **Signal integrity simulation** | IBIS model simulation of the driving device → receiving pad. |

**Conservative rule:** If unknown, use **0.3 ns** for FPGA-driven signals,
**0.1 ns** for ASIC-to-ASIC.

---

## 3. Clock Uncertainty

```tcl
set design(CLOCK_UNCERTAINTY)     0.3    ;# ns (300 ps) — clk_sys
set design(OSC_CLOCK_UNCERTAINTY) 0.05   ;# ns (50 ps)  — oscillators
```

### What it means

Clock uncertainty is subtracted from the timing window. It accounts for
**jitter + clock tree skew + on-chip variation (OCV)**:

```
Effective period = PERIOD − UNCERTAINTY
```

This is a **pre-CTS** (pre-clock-tree-synthesis) estimate. After CTS in
the PnR tool, you replace it with actual post-CTS skew numbers.

### Why 300 ps for clk_sys

| Component | Budget |
|-----------|--------|
| PLL/crystal jitter (cycle-to-cycle) | 50–100 ps |
| Clock tree skew (pre-CTS estimate at 180 nm) | 100–200 ps |
| OCV (process/voltage/temperature variation) | 50–100 ps |
| **Total** | **~250–400 ps** |

300 ps is the standard starting point for 180 nm pre-CTS synthesis.

### Why 50 ps for oscillators

The on-chip ring oscillators have **no clock tree** — they directly drive
nearby flip-flops. The only uncertainty source is jitter:

| Component | Budget |
|-----------|--------|
| Ring oscillator cycle-to-cycle jitter | 10–30 ps |
| Local routing variation | 5–10 ps |
| OCV on short local path | 5–10 ps |
| **Total** | **~20–50 ps** |

### Where to find real values

| Source | What to look for |
|--------|-----------------|
| **PLL/clock source datasheet** | Cycle-to-cycle jitter spec (usually in ps RMS). Multiply by 3× for peak-to-peak. For XFAB's PLL IP: check the IP datasheet "jitter" section. |
| **Post-CTS reports** | After PnR, Innovus/Tempus reports actual clock skew per group. Replace `CLOCK_UNCERTAINTY` with `actual_skew + jitter + OCV_margin`. |
| **Analog oscillator characterization** | The analog designer provides jitter measurements (phase noise → jitter conversion). This directly replaces `OSC_CLOCK_UNCERTAINTY`. |
| **XFAB process docs** | OCV derating factors (e.g., 5% for 180 nm) — used to compute the OCV component. |

### Typical ranges by node

| Node   | Pre-CTS uncertainty |
|--------|-------------------|
| 180 nm | 0.2–0.5 ns |
| 65 nm  | 0.1–0.2 ns |
| 28 nm  | 0.05–0.15 ns |

**Post-CTS:** Typically 2–5× tighter than pre-CTS because actual skew
replaces the estimate.

---

## 4. Clock Transition

```tcl
set design(CLOCK_TRANSITION) 0.15   ;# ns (150 ps)
```

### What it means

Maximum allowed rise/fall time on clock edges. Sharp clock edges give
clean sampling (tight setup/hold windows). The CTS tool targets this.

### Why 150 ps

- 180 nm clock buffers can achieve 100–200 ps transitions
- 150 ps is in the fast-to-moderate range
- Too tight (< 50 ps) → oversized buffers, wasted area/power
- Too loose (> 500 ps) → poor setup/hold margins, increased clock-to-Q

### Where to find real values

| Source | What to look for |
|--------|-----------------|
| **Standard cell Liberty (.lib)** | Look at the clock buffer cells (e.g., `CLKBUF*`, `CLKINV*`). Check the `output_transition` values in the timing tables. The max characterized slew in the lib header (`slew_upper_threshold_pct_rise/fall`) tells you the valid range. |
| **CTS guidelines from foundry** | XFAB's digital flow guide specifies recommended max clock transition for their cell library. |

**Rule of thumb:** Set to ~30–50% of the maximum characterized clock
buffer output slew.

---

## 5. Max Fanout

```tcl
set design(MAX_FANOUT) 20
```

### What it means

Maximum number of gate inputs a single cell output can drive. If exceeded,
Genus inserts buffer trees to split the load.

### Why 20

- At 180 nm, a standard-drive cell (1×) drives 15–25 loads comfortably
- 20 is the de facto industry default for 180 nm / 130 nm
- Lower (8–12) → more buffers, easier timing, more area
- Higher (30–40) → less area, but longer nets, harder timing closure

### Where to find real values

| Source | What to look for |
|--------|-----------------|
| **Standard cell Liberty (.lib)** | `max_fanout` attribute on cells (if specified). Also check `max_capacitance` — if a cell can drive 100 fF and each input is ~5 fF, max fanout ≈ 20. |
| **Foundry digital flow guide** | XFAB's recommended max fanout for their standard cell library. |

### Typical ranges by node

| Node   | Max Fanout |
|--------|-----------|
| 180 nm | 16–24 |
| 65 nm  | 10–16 |
| 28 nm  | 8–12 |

---

## 6. Max Transition

```tcl
set design(MAX_TRANSITION) 0.5   ;# ns (500 ps)
```

### What it means

Global cap on signal transition times (rise/fall). If any signal is
slower than this, Genus adds buffers or upsizes cells.

### Why 500 ps

- 180 nm libs are typically characterized up to 0.5–1.0 ns input slew
- 500 ps = moderate constraint, ~50% of max characterized slew
- Prevents sluggish signals without forcing excessive buffering
- Tighter (200 ps) → more buffers, cleaner signals, more area
- Looser (1 ns) → risk of operating outside characterized cell behavior

### Where to find real values

| Source | What to look for |
|--------|-----------------|
| **Standard cell Liberty (.lib)** | Open the `.lib` file and find the `slew_upper_threshold_pct_rise` and the max value in the `input_net_transition` index tables. The largest index value is the max characterized slew. Set `MAX_TRANSITION` to 50–70% of that value. |
| **Foundry DRM (Design Rule Manual)** | May specify maximum allowed signal transition for reliability (electromigration, hot carrier injection). |

**Example from a typical 180 nm lib:**
```
lu_table_template(delay_template_7x7) {
  variable_1 : input_net_transition ;
  index_1 ("0.01, 0.05, 0.1, 0.2, 0.4, 0.8, 1.0");  ← max = 1.0 ns
  ...
}
```
→ Set `MAX_TRANSITION` = 0.5–0.7 ns (50–70% of 1.0 ns).

---

## 7. Output Load

```tcl
set design(OUTPUT_LOAD_MACRO)    0.01   ;# pF (10 fF)
set design(OUTPUT_LOAD_FULLCHIP) 0.05   ;# pF (50 fF)
```

### What it means

Capacitive load Genus assumes each output pin drives. This directly
affects output cell sizing and timing.

### Why 10 fF / 50 fF

The checked-in default is `MACRO`, so `10 fF` models a light on-chip SPADMIC
sink until the top-level timing allocation replaces it. `50 fF` remains the
full-chip/pad-ring placeholder:

| Load component | Typical value |
|---------------|---------------|
| Routing to pad ring | 10–30 fF |
| Pad driver input cap | 10–30 fF |
| **Core sees** | **~20–60 fF** |

The pad driver itself handles the external load (2–5 pF for bondwire +
PCB). That's modeled separately in the pad cell Liberty.

### Where to find real values

| Source | What to look for |
|--------|-----------------|
| **Pad cell Liberty (.lib)** | Input capacitance of the output pad driver cell (e.g., `BT4R`). Look for `capacitance` attribute on the input pin `I` or `A`. This is what the core logic must drive. |
| **Pad cell datasheet** | "Input capacitance" specification for the digital-side input pin of the I/O pad. |
| **Post-PnR extraction** | After routing, parasitic extraction gives actual wire + load capacitance per net. |

**If you don't have a pad cell yet:** 50 fF is conservative for a full-chip
core-to-pad placeholder in 180 nm. Increase to 100–200 fF if you expect long
routing to the pad ring.

**If driving directly off-chip (no pad model):** Use 2–5 pF to model the
full bondwire + package + board trace load.

---

## 8. Checklist: Replacing Placeholders with Real Values

When you receive the XFAB XH018 PDK, go through this checklist:

### From the Standard Cell Liberty (.lib)

- [ ] **MAX_TRANSITION:** Find max `input_net_transition` index → set to 50–70%
- [ ] **MAX_FANOUT:** Find `max_capacitance` on a standard buffer ÷ typical input `capacitance`
- [ ] **CLOCK_TRANSITION:** Check max output slew of clock buffer cells (`CLKBUF*`)

### From the I/O Pad Cell Liberty (.lib)

- [ ] **OUTPUT_LOAD:** Input `capacitance` of the output pad driver
- [ ] **INPUT_DELAY:** `cell_rise`/`cell_fall` delay from pad pin to core pin
- [ ] **OUTPUT_DELAY:** `cell_rise`/`cell_fall` delay from core pin to pad pin
- [ ] **INPUT_TRANSITION:** Use upstream device datasheet instead

### From the PLL / Clock Source Datasheet

- [ ] **CLOCK_UNCERTAINTY:** Cycle-to-cycle jitter (×3 for peak) + skew estimate

### From the Analog Oscillator Characterization

- [ ] **OSC_CLOCK_UNCERTAINTY:** Measured jitter from analog team + small OCV margin

### From Package / Board Design

- [ ] **INPUT_DELAY / OUTPUT_DELAY refinement:** Bondwire delay + PCB trace delay

### After Clock Tree Synthesis (PnR stage)

- [ ] **CLOCK_UNCERTAINTY:** Replace pre-CTS estimate with actual skew from CTS report
- [ ] **CLOCK_TRANSITION:** Replace target with achieved transition from CTS report

---

## 9. Files in This Directory

| File | Purpose |
|------|---------|
| `mptdc.defines` | All design variables — single source of truth |
| `mptdc.sdc` | SDC constraints parameterized from `mptdc.defines` |
| `mptdc.mmmc` | Multi-Mode Multi-Corner analysis view definitions |
| `README.md` | This document — constraint rationale and PDK lookup guide |
