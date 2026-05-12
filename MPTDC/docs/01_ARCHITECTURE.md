# MPTDC v2.2 — RTL Architecture Reference

> - **Author:** Karim Sabra
> - **Purpose:** Reference the active RTL hierarchy, timing-domain partitioning, and end-to-end conversion flow.
> - **Scope:** Covers the implementation compiled by `rtl/filelist.f` and instantiated by `rtl/top/mptdc_top_asic.sv`.

## 1. Purpose and scope

This document describes the active RTL implementation that is compiled through `rtl/filelist.f` and instantiated by `rtl/top/mptdc_top_asic.sv`. It is intended to be the engineering reference for architecture review, synthesis preparation, and handoff.

The live design is a Vernier multi-phase TDC with:

- one slow ring oscillator (`55 ps` tap delay)
- one fast ring oscillator (`50 ps` tap delay)
- an `8 x 8` phase-detector matrix (`64` cells)
- a two-context snapshot bank (`N_CTX=2`)
- a fast-domain measurement FSM and a system-domain drain/serialization pipeline
- purely offline calibration

Compatibility note: the active v2.4 RTL no longer has a separate `FIRST_HIT`
mode. The equivalent minimum-latency close behavior is now obtained with
`max_hits = 1`, and the close flag is named `closed_by_fast_maxhit`.

## 2. Key architectural constants

| Parameter | Value | Meaning |
|-----------|-------|---------|
| `NE` | `8` | Number of taps per oscillator |
| `OSC_TS_SLOW_PS` | `55 ps` | Slow oscillator tap delay |
| `OSC_TS_FAST_PS` | `50 ps` | Fast oscillator tap delay |
| `DELTA_STEP` | `5 ps` | Vernier tap-delay difference |
| `DELTA_LSB` | `10 ps` | Nominal output LSB (`2 * DELTA_STEP`) |
| `K_VERNIER` | `11` | `OSC_TS_SLOW_PS / DELTA_STEP` |
| `PD_N` | `64` | Number of PD cells (`NE * NE`) |
| `MAX_HITS` | `15` | Maximum emitted hits per conversion |
| `N_CTX` | `2` | Number of snapshot contexts |
| `CLK_SYS_HZ` | `160 MHz` | System clock for CSR, drain, and TX |

## 3. Active hierarchy

```text
mptdc_top_asic
  |- mptdc_reset_sync         (pad reset -> sys reset)
  |- mptdc_input_mux          (SPAD vs CAL async source select)
  |- mptdc_csr_minimal        (configuration and status register file)
  `- mptdc_core
       |- mptdc_reset_sync    (sys reset -> fast reset)
       |- mptdc_async_frontend_v2
       |- mptdc_osc_wrapper   (slow)
       |- mptdc_osc_wrapper   (fast)
       |- mptdc_pd_cell x 64
       |- mptdc_stop_capture_async
       |- mptdc_gray_cnt_sync (slow counter)
       |- mptdc_gray_cnt_sync (fast counter)
       |- mptdc_meas_ctrl
       |- mptdc_context_bank
       |- mptdc_drain_ctrl
       |- mptdc_sync_fifo
        |- mptdc_narrow16_tx_v2
        `- mptdc_watchdog
```

`mptdc_top_asic` and `mptdc_core` also expose an optional acquisition-record
export interface used by the active SPADMIC shared-readout top.

Compiled but not instantiated in the live top path:

- `rtl/cdc/mptdc_pulse_sync.sv`
- `rtl/readout/mptdc_tconv_reco.sv`

Simulation-only support block:

- `rtl/osc/mptdc_osc_model.sv`

Synthesis placeholder block:

- `rtl/osc/mptdc_osc_stub.sv`

## 4. Domain partitioning

| Domain | Source | Used by |
|--------|--------|---------|
| `clk_sys` | external `160 MHz` | CSR, drain FSM, FIFO, serializer, global watchdog |
| `osc_fast_ph0` | fast oscillator tap 0 | measurement FSM, context-bank write, fast counter destination |
| `fast_phase[n]` | fast oscillator taps | PD-cell sampling clocks |
| `slow_phase[n]` | slow oscillator taps | PD sampled inputs, slow counter source clock |
| async event domain | START, STOP, latch set/reset, STOP capture | async frontend and boundary capture |

The design intentionally mixes synchronous logic, async latches, and generated clocks. That is acceptable for this architecture, but it means synthesis, STA, and CDC review must understand which crossings are ordinary digital crossings and which ones are intentional measurement structures.

## 5. End-to-end conversion flow

### 5.1 Idle state

`conv_arm` is set through the CSR block. The frontend waits for a valid `START` pulse while at least one context is free. The PD gate is low and both oscillators are effectively idle.

### 5.2 START arrival

The async frontend accepts `START` only when:

- `conv_arm_i = 1`
- at least one context is free
- the frontend is not already holding a START for the current conversion

On acceptance, the frontend:

- sets `start_latched`
- allocates the active context
- asserts `osc_slow_en_async_o`

That launches the slow oscillator and starts the slow coarse counting process.

### 5.3 STOP arrival

When `STOP` arrives, the frontend:

- sets `stop_latched`
- asserts `osc_fast_en_async_o`
- asserts `pd_enable_async_o`

Now the PD matrix is logically eligible to capture crossings, but the actual PD cells also require `meas_pd_gate` from the measurement FSM. This extra gate is part of the silicon-safety cleanup and prevents false hits during warmup and teardown.

### 5.4 Coarse and fine timing capture

While the oscillators run:

- the slow counter increments from `slow_phase[0]`
- the fast counter increments from `osc_fast_ph0`
- each PD cell samples one slow phase tap using one fast phase tap
- on a valid detected crossing, a PD cell latches its `hit_level` and captures its local `nfast_hit`

At the same time, `mptdc_stop_capture_async` captures boundary metadata on the STOP edge:

- `phase0_snap`
- `phase7d_snap` (debug / diagnostic helper)
- `slow_boundary_inc`

The slow counter also takes a STOP-side Gray snapshot so exported `Nslow` is coherent with STOP rather than a later CAPTURE moment.

### 5.5 Close detection

`mptdc_meas_ctrl` runs on `osc_fast_ph0` and closes the conversion when one of three conditions occurs:

- fast close: `max_hits_cfg_i == 1` and any PD cell has asserted `hit_level`
- counted close: registered hit count has reached `max_hits_cfg_i` for `max_hits_cfg_i > 1`
- watchdog: fast-domain context watchdog reaches `wdt_timeout_i`

### 5.6 Safe shutdown sequence

The fast FSM sequence is:

```text
IDLE -> MEASURE -> CAPTURE -> STOP_OSC -> CLEAR -> IDLE
```

This ordering matters:

- `CAPTURE` freezes the conversion into the context bank
- `STOP_OSC` clears the frontend latches, which stops the slow oscillator and leaves phases static
- `CLEAR` asynchronously clears the PD cells and counters only after the oscillators are safely quiesced

This sequence is one of the main silicon-safety improvements over older versions.

### 5.7 Context drain and output

Once captured, the owning context enters `DRAINING`. The system-clock drain FSM waits until the async drain flag has crossed through a 2-FF synchronizer, then:

1. reads the frozen context bank snapshot
2. emits one META record
3. scans all 64 PD cells and emits one HIT record per active cell
4. releases the context
5. pulses `conv_done`

The FIFO buffers those acquisition records, and the 16-bit serializer converts them into external packet words.
In the shared-readout integration, the same FIFO can instead be drained through
the exported `acq_*` interface; see [`10_SHARED_READOUT_EXPORT.md`](10_SHARED_READOUT_EXPORT.md).

## 6. Module-by-module reference

### 6.1 `rtl/pkg/mptdc_pkg.sv`

Purpose:
- central package for constants, enums, packed structs, widths, and helper functions

Key exports:
- dimensions (`NE`, `PD_N`, `N_CTX`, widths)
- configuration and status structs
- acquisition-record types for the drain/FIFO/TX path
- `pd_from_phases()`
- `vernier_coef()` and `vernier_tconv_ps()`

Silicon notes:
- no state, no clocks, no CDC
- this file is the source of truth for the raw timestamp contract

### 6.2 `rtl/top/mptdc_top_asic.sv`

Purpose:
- pad-facing wrapper
- connects reset, input selection, CSR, and the reusable core

Inputs:
- `clk_sys`, `async_rst_n`
- async SPAD start/stop
- async calibration start/stop
- CSR bus
- 16-bit output ready

Outputs:
- CSR response
- 16-bit output valid/data
- optional acquisition-record export plus FIFO-full indication for shared top-level readout

Behavior:
- synchronizes pad reset into `clk_sys`
- combines synchronized reset with `soft_rst_pulse`
- routes selected async inputs into the core
- pushes config into the core and returns status to CSR
- optionally bypasses the local narrow serializer and exports acquisition records from the internal FIFO

Silicon notes:
- straightforward synchronous wrapper
- no measurement logic here

### 6.3 `rtl/ctrl/mptdc_input_mux.sv`

Purpose:
- chooses between SPAD inputs and calibration inputs

Inputs:
- `start_spad_async_i`, `stop_spad_async_i`
- `cal_start_async_i`, `cal_stop_async_i`
- `input_sel_i`

Outputs:
- `start_async_o`, `stop_async_o`

Behavior:
- pure combinational async mux

Silicon notes:
- safe as long as `input_sel_i` is not toggled during active measurement
- no sequential state, no CDC logic

### 6.4 `rtl/readout/mptdc_csr_minimal.sv`

Purpose:
- register-file interface for control and status

Domain:
- `clk_sys`

Writes control:
- input source (`SPAD` / `CAL`)
- output mode (`RAW_FEATURES`, `RAW_TIMESTAMP`, `FULL`)
- max hits
- per-context watchdog timeout
- global watchdog timeout
- `conv_arm`
- `fifo_clr` pulse
- `soft_rst` pulse

Reads back:
- config registers
- status, last hit count, flags, FIFO state, watchdog count, conversion count, overflow count

Silicon notes:
- always-ready interface with registered read response
- `conv_arm` is a persistent level, not a pulse

### 6.5 `rtl/top/mptdc_core.sv`

Purpose:
- integrates all runtime datapath blocks
- optionally exports acquisition records from the internal FIFO when shared readout is enabled

Domains:
- `clk_sys`
- `osc_fast_ph0`
- oscillator taps
- async control domain

Important internal functions:
- fast-domain reset synchronization
- slow-domain START watchdog for missing STOP
- drain flag synchronization into `clk_sys`
- rejected-start synchronization for true overflow counting
- status generation and counters

Silicon notes:
- this is the main place where all CDC assumptions come together
- the correctness of `pd_enable_gated`, `ctx_drain_sync_ff2`, and reset synchronization is critical for silicon behavior

### 6.6 `rtl/cdc/mptdc_reset_sync.sv`

Purpose:
- async-assert / sync-deassert reset synchronizer

Inputs:
- `clk`, `async_rst_n`

Output:
- `rst_n_o`

Silicon notes:
- standard and safe
- marked with `ASYNC_REG`

### 6.7 `rtl/cdc/mptdc_pulse_sync.sv` (compiled, not instantiated)

Purpose:
- generic toggle-based pulse synchronizer

Live-role status:
- compiled utility, not used in the active top path

### 6.8 `rtl/cdc/mptdc_gray_cnt_sync.sv`

Purpose:
- source-domain counter plus Gray-coded CDC for continuous and snapshot values

Inputs:
- source-domain clock, reset, clear, enable, synchronous/async snapshot triggers
- destination-domain clock and reset

Outputs:
- live source count
- continuous destination count
- destination latched snapshot

Active use:
- slow counter: `slow_phase[0] -> osc_fast_ph0`, with STOP-side async snapshot enabled
- fast counter: `osc_fast_ph0 -> osc_fast_ph0`

Silicon notes:
- Gray code bounds crossing ambiguity
- async STOP snapshot is intentional and central to timing correctness
- source snapshot is deliberately not cleared by ordinary count-clear logic

### 6.9 `rtl/cdc/mptdc_sync_fifo.sv`

Purpose:
- synchronous FWFT FIFO between drain FSM and serializer

Domain:
- `clk_sys`

Inputs/outputs:
- write port from drain FSM
- read port to serializer
- fill level and full/valid flags

Silicon notes:
- no CDC inside
- deterministic storage and backpressure handling

### 6.10 `rtl/osc/mptdc_osc_wrapper.sv`

Purpose:
- selects simulation model or synthesis placeholder

Behavior:
- with `MPTDC_USE_OSC_MODEL`, instantiates `mptdc_osc_model`
- otherwise instantiates `mptdc_osc_stub`

Silicon notes:
- wrapper itself is synthesizable
- real silicon must replace stub behavior with the intended oscillator implementation

### 6.11 `rtl/osc/mptdc_osc_model.sv` (simulation only)

Purpose:
- picosecond behavioral oscillator model

Features:
- per-tap phase delay
- optional jitter via plusargs
- helper guard/probe outputs for boundary debugging

Silicon notes:
- not synthesizable
- simulation-only timing reference

### 6.12 `rtl/osc/mptdc_osc_stub.sv` (synthesis placeholder)

Purpose:
- deterministic implementation placeholder with no real oscillation

Behavior:
- phase pins are controllable from `en/rst_n`, but do not model tap delay or
  real oscillation

Silicon notes:
- keeps oscillator-domain/PD structure present for early physical planning
- not a functional oscillator

### 6.13 `rtl/pd/mptdc_pd_cell.sv`

Purpose:
- one phase-detector cell in the `8 x 8` matrix

Inputs:
- one slow phase tap
- one fast phase tap (clock)
- `nfast_count`
- async clear

Outputs:
- sticky `hit_level`
- latched `nfast_hit`

Behavior:
- samples slow phase in the fast domain
- detects the slow falling edge relative to the fast sample stream
- captures the current fast coarse count on first valid event

Silicon notes:
- this is an intentional asynchronous sampler, not an ordinary CDC block
- the PD gate and clear sequencing are what make its integration safe

### 6.14 `rtl/async/mptdc_async_frontend_v2.sv`

Purpose:
- async START/STOP latch control and two-context allocation

Inputs:
- `conv_arm_i`
- async start/stop
- async clear
- synthetic STOP from missing-STOP watchdog
- context release
- capture trigger
- oscillator keep-alive

Outputs:
- `start_latched`, `stop_latched`
- slow/fast oscillator enables
- PD enable
- active context and context states
- start rejection indicator

Behavior:
- uses explicit latches, not clocks, for START/STOP ownership and context holding
- allocates one free context on START
- marks the active context as draining on capture
- releases a context when the drain FSM signals completion

Silicon notes:
- latch usage is intentional
- this block must be reviewed as true async control logic, not as a missed synchronous rewrite

### 6.15 `rtl/async/mptdc_stop_capture_async.sv`

Purpose:
- captures boundary metadata on STOP

Inputs:
- STOP pulse
- `slow_phase0`
- `slow_phase0_guard`
- `slow_phase7d_probe`
- async clear, reset

Outputs:
- `phase0_snap`
- `phase7d_snap`
- `slow_boundary_inc`

Silicon notes:
- another intentional async capture structure
- `slow_boundary_inc` is a useful boundary tag for both raw timestamp centering and offline calibration

### 6.16 `rtl/async/mptdc_context_bank.sv`

Purpose:
- double-buffered snapshot storage for one full conversion per context

Write-side contents:
- hit bitmap
- packed per-cell `nfast_hit`
- STOP-side `nslow`
- CAPTURE-side `nfast_snap`
- boundary metadata
- hit count
- close flags

Read-side behavior:
- combinational mux of the selected context

Silicon notes:
- read path is a static-data CDC assumption, not a dynamic unsynchronized bus crossing
- data is only consumed after the drain flag has safely crossed into `clk_sys`

### 6.17 `rtl/ctrl/mptdc_meas_ctrl.sv`

Purpose:
- fast-domain conversion FSM

Domain:
- `osc_fast_ph0`

Inputs:
- measurement-active level from frontend
- full PD bitmap
- max-hits config and watchdog timeout

Outputs:
- capture pulse
- frontend clear pulse
- PD clear pulse
- PD gate level
- oscillator keep-alive
- hit count and close flags

Behavior:
- fast close (`max_hits = 1`) uses an OR reduction
- higher `max_hits` values use a pipelined hierarchical count tree
- watchdog close is local to the measurement window
- safe sequence: capture first, stop oscillators next, clear last

Silicon notes:
- count tree is pipelined specifically to keep the fast domain synthesizable at nominal fast-oscillator speed
- PD gate prevents bogus hits during startup and teardown

### 6.18 `rtl/ctrl/mptdc_drain_ctrl.sv`

Purpose:
- reads one frozen context in `clk_sys` and converts it to acquisition records

States:
- `ST_D_IDLE`
- `ST_D_META`
- `ST_D_SCAN`
- `ST_D_EOC`

Outputs:
- FIFO write records
- context release pulse
- conversion-done pulse

Silicon notes:
- synchronous, simple, and backpressure-safe
- includes a released-context mask so a just-cleared async context is not immediately reselected while its synchronized drain flag is still high

### 6.19 `rtl/ctrl/mptdc_watchdog.sv`

Purpose:
- global inactivity watchdog in `clk_sys`

Inputs:
- `conv_done_i`
- global timeout config

Outputs:
- one-cycle `wdt_force_reset_o`
- saturating global trip counter

Silicon notes:
- simple synchronous counter
- emergency recovery path only

### 6.20 `rtl/readout/mptdc_narrow16_tx_v2.sv`

Purpose:
- serializes acquisition records into the external 16-bit packet stream

Inputs:
- output mode
- FIFO valid/data
- output ready

Outputs:
- FIFO read enable
- packet valid/data

Behavior:
- latches META context first
- emits header
- fetches one HIT record at a time
- emits 2, 3, or 4 words per hit depending on mode
- emits EOC with a local `conv_count_q`

Silicon notes:
- fully synchronous to `clk_sys`
- all packet semantics should be taken from this block and the package, not from stale older docs

### 6.21 `rtl/readout/mptdc_tconv_reco.sv` (compiled, not instantiated)

Purpose:
- standalone combinational raw timestamp helper

Live-role status:
- not currently used by the active top path
- useful as a reference implementation of the package formula

## 7. Raw timestamp contract

The live raw timestamp helper is in `mptdc_pkg::vernier_tconv_ps()`.

Current contract:

```text
coef = (Nslow + VERNIER_NSLOW_ORIGIN_BIAS + slow_boundary_inc - 1) * K_VERNIER * NE
     + (Nfast + VERNIER_NFAST_ORIGIN_BIAS - 1) * NE
     + ns * K_VERNIER
     - nf * (K_VERNIER - 1)
     + VERNIER_COEF_BIAS

t_raw_ps = coef * DELTA_LSB
```

Where the current package constants are:

- `VERNIER_NSLOW_ORIGIN_BIAS = 2`
- `VERNIER_NFAST_ORIGIN_BIAS = 1`
- `VERNIER_COEF_BIAS = 25`
- `slow_boundary_inc` is the captured STOP-side boundary carry

This preserves the original Vernier dependency on `Nslow`, `Nfast`, `ns`, `nf`, `K_VERNIER`, and `DELTA_LSB`, while aligning the equation to the current live counter semantics.

## 8. Silicon review checklist

Before synthesis / signoff, review the following explicitly:

1. Replace `mptdc_osc_stub` with the intended physical oscillator implementation.
2. Define generated clocks and STA constraints for `slow_phase[*]`, `fast_phase[*]`, and `osc_fast_ph0`.
3. Review latch-based async frontend behavior as intentional architecture, not accidental latch inference.
4. Review STOP-edge capture structures (`mptdc_stop_capture_async`, async snapshot in `mptdc_gray_cnt_sync`) as intentional measurement logic.
5. Preserve `ASYNC_REG` handling on reset and Gray-counter synchronizers.
6. Confirm the static-data CDC assumption for the context-bank read path in the chosen signoff methodology.
7. Keep `input_sel`, `mode`, and `conv_arm` usage consistent with the intended control model: do not retarget inputs or modes mid-conversion.
8. Treat `mptdc_osc_model` as simulation-only and do not rely on it for synthesis behavior.

## 9. Practical reading order

If you want to understand the RTL quickly, read in this order:

1. `rtl/pkg/mptdc_pkg.sv`
2. `rtl/top/mptdc_top_asic.sv`
3. `rtl/top/mptdc_core.sv`
4. `rtl/async/mptdc_async_frontend_v2.sv`
5. `rtl/ctrl/mptdc_meas_ctrl.sv`
6. `rtl/async/mptdc_context_bank.sv`
7. `rtl/ctrl/mptdc_drain_ctrl.sv`
8. `rtl/readout/mptdc_narrow16_tx_v2.sv`

That order follows the real measurement path from pads to packets.
