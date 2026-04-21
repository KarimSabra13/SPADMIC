# MPTDC Lab Synthesis History and PnR Readiness

This README captures the maintained lab-server Genus workflow, the tracked
snapshot history, the current interpretation of the results, and the recommended
next steps toward an industry-grade Innovus bring-up.

## Current status

- **System-clock (`clk_sys`) synthesis closes** in the current signoff-oriented
  lab flow (`wc_view`, slow `1.62V/125C`, global interconnect, physical area).
- **Oscillator-domain signoff does not close yet** because the synthesis flow
  still uses the constant-output oscillator stub and Genus reports hundreds of
  sequential clock pins without a waveform.
- **Proceed with Innovus for digital-shell floorplan / place / route
  preparation**, not for final mixed-signal signoff.

## Maintained workflow

Because the XFAB PDK is available only on the lab server and the raw Genus
output tree under `syn/` is gitignored, the maintained workflow is:

1. run Genus on the lab server from `MPTDC/syn/scripts`
2. copy key reports / log / netlist / SDC into `MPTDC/lab_snapshots/<run_tag>/`
3. commit that snapshot on branch `SPADMIC_TOP`
4. pull locally and review the tracked snapshot here

## Snapshot history

| Snapshot | Commit | Corner / mode | WNS | TNS | Violating paths | Cell area (um^2) | Total area (um^2) | Dynamic power |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `genus_20260421_1057_baseline` | `4931ff5` | `tc_view`, typ `1.80V/25C`, enclosed wireload | `+168.9 ps` | `0.0 ps` | `0` | `28215.906` | `29952.308` | `5.449 mW` |
| `genus_20260421_1116_mmmc_qrc` | `557e7fc` | `wc_view`, slow `1.62V/125C`, global interconnect | `-889.6 ps` | `-14620.6 ps` | `78` | `32509.030` | `50006.532` | `6.675 mW` |
| `genus_20260421_1137_macro_budget` | `80600f4` | `wc_view`, macro-budgeted I/O, global interconnect | `+2.6 ps` | `0.0 ps` | `0` | `31204.454` | `48523.417` | `6.350 mW` |
| `genus_20260421_1149_mmmc_qrc` | `5afe112` | rerun with async-slew cleanup | `+2.6 ps` | `0.0 ps` | `0` | `31204.454` | `48523.417` | `6.350 mW` |

## What changed across the runs

### 1. Baseline run

The first run looked clean, but it was still optimistic:

- `tc_view` only
- typical corner only
- wireload-style estimates
- no real BC/WC split

This run was useful only as a bring-up checkpoint.

### 2. MMMC/QRC run

Enabling BC/WC MMMC, physical-aware estimates, and QRC-backed RC corners exposed
the real timing picture:

- the design failed in `clk_sys`
- the worst path was the FIFO-to-`acq_data_o` export path
- many other failing paths were inside the synchronous FIFO logic

This was the first realistic signoff-oriented front-end view.

### 3. Macro-budget run

The key fix was to stop treating this block as a pad-level full chip and instead
budget it as a **macro**:

- full-chip placeholder I/O budget: `2.0 ns` in / `2.0 ns` out
- macro placeholder I/O budget: `0.5 ns` in / `0.5 ns` out

That removed an over-pessimistic external-delay assumption on the optional
shared-readout interface and recovered timing closure in the same `wc_view`.

### 4. Latest rerun

The latest rerun confirmed the macro-budget result and cleaned up one lint item:

- **`Inputs without external driver/transition` fell from `5` to `0`**
- **`Inputs without clocked external delays` remains `5`**, which is expected for
  the async reset and async detector/calibration inputs
- **`Sequential clock pins without clock waveform` remains `735`**, still caused
  by the oscillator synthesis stub

## Remaining timing-intent findings

### Expected / acceptable for now

1. `5` inputs without clocked external delays  
   These are:
   - `async_rst_n`
   - `cal_start_async_i`
   - `cal_stop_async_i`
   - `start_spad_async_i`
   - `stop_spad_async_i`

   They are intentionally asynchronous and false-pathed.

2. `735` sequential clock pins without waveform  
   These are still caused by the oscillator stub collapsing to constants. This is
   the main reason oscillator-domain STA is not yet signoff-meaningful.

### Not acceptable for final signoff

- claiming oscillator-domain timing closure with the current stub
- claiming full mixed-signal signoff before real oscillator / PLL macro contracts
- freezing a top-level floorplan without reserved sites for the oscillator/PLL
  macros and the symmetry-critical PD island

## Can Innovus start now?

**Yes, but only for the right scope.**

You can start Innovus now for:

- digital-shell floorplan bring-up
- power planning
- placement / CTS / route of the **`clk_sys`** domain
- congestion study
- reserve-area planning for oscillator and PLL macros
- PD-island symmetry planning

You should **not** treat Innovus as final signoff yet for:

- oscillator-domain clock implementation
- oscillator/PLL timing closure
- final top-level mixed-signal integration
- final macro placement until analog contracts are frozen

## What Innovus should assume right now

Until the analog designer delivers the real blocks, treat the oscillator / PLL
content as **macro placeholders with signoff ownership outside the digital RTL**.

At minimum, the digital flow needs the following contract for each analog block:

1. abstract size / aspect ratio
2. pin list and pin locations
3. power pins and domains
4. routing blockage / obstruction assumptions
5. keep-out / halo guidance
6. clock intent (what the macro drives, what uncertainty/jitter budget applies)

If timing arcs are unavailable, that is still enough to begin floorplan-quality
implementation as long as the macro boundaries are treated explicitly.

## Recommended industry-grade next steps

### 1. Create an Innovus bring-up package for the digital shell

There is currently **no checked-in Innovus flow** in this repository. The next
smart step is to create one around the current handoff set:

- post-synthesis netlist
- post-synthesis SDC
- MMMC setup
- tech LEF + std-cell LEF
- QRC decks

### 2. Reserve macro sites before top-level integration

Do not wait for final analog transistor closure to reserve:

- slow oscillator macro site
- fast oscillator macro site
- PLL macro site
- symmetry-critical `9 x 9` PD matrix region

### 3. Run Innovus on the `clk_sys` domain only

The right initial goal is:

- floorplan
- placement
- CTS for `clk_sys`
- trial route
- extracted post-route timing / power / congestion review

This should be framed as **digital implementation readiness**, not full-chip
signoff.

### 4. Re-evaluate the near-zero margin

The block currently closes with only about **`+2.6 ps`** WNS in `wc_view`.
That is legal, but not comfortable. After Innovus extraction, expect this to
move. The right response is not panic; it is to:

- check whether physical synthesis / real CTS improves or degrades it
- identify whether the FIFO/readout cone remains the dominant sys-domain hotspot
- decide whether small RTL micro-architecture cleanup is still warranted

### 5. Prepare the analog handoff checklist now

To avoid blocking later, request from the analog designer:

- abstract LEF for each macro
- agreed pinout
- power hookup requirements
- jitter / frequency budget for the oscillator outputs
- PLL interface and clock assumptions

## Practical interpretation

Today, the block is in a good state to move forward:

- **good enough for Innovus bring-up**
- **good enough for floorplan and top-level planning**
- **not yet good enough for final mixed-signal signoff**

That is the right industry-grade position at this stage of the project.
