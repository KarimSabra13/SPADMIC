# MPTDC — Block Guide

## Scope

This document is the grouped module reference for the active RTL compiled through
`MPTDC/rtl/filelist.f`.

It complements [`01_ARCHITECTURE.md`](01_ARCHITECTURE.md) by answering a simpler
question: **what does each block do, and where does it sit in the design?**

## 1. Grouped hierarchy

| Area | Main files | Role in the TDC |
|------|------------|-----------------|
| Package | `rtl/pkg/mptdc_pkg.sv` | constants, structs, helper functions, output grammar |
| Top wrappers | `rtl/top/mptdc_top_asic.sv`, `rtl/top/mptdc_core.sv` | pad-facing wrapper and reusable core integration |
| Async frontend | `rtl/async/*.sv` | START/STOP acceptance, context allocation, async-side capture |
| CDC | `rtl/cdc/*.sv` | reset sync, Gray-counter sync, FIFO, pulse crossing helpers |
| Oscillator | `rtl/osc/*.sv` | model, wrapper, synthesis stub |
| Phase detector | `rtl/pd/mptdc_pd_cell.sv` | single PD-cell behavior, instantiated across the 8x8 matrix |
| Control | `rtl/ctrl/*.sv` | input select, measurement close, drain ownership, watchdog |
| Readout | `rtl/readout/*.sv` | CSR file, record reconstruction helper, narrow serializer |

## 2. Package and top wrappers

| Block | File | Domain | What it owns |
|-------|------|--------|--------------|
| `mptdc_pkg` | `rtl/pkg/mptdc_pkg.sv` | none | widths, enums, structs, conversion helpers, packet helpers |
| `mptdc_top_asic` | `rtl/top/mptdc_top_asic.sv` | pad-facing wrapper | reset sync, input mux, CSR, core connection, optional shared-readout export |
| `mptdc_core` | `rtl/top/mptdc_core.sv` | mixed async/oscillator/`clk_sys` | full measurement kernel integration |

### `mptdc_pkg`

This package is the source of truth for:

- Vernier geometry
- width calculations
- acquisition-record types
- serializer packet helpers
- timestamp conversion helpers

Any change to the raw-output contract should start here.

### `mptdc_top_asic`

This is the safe reusable shell around the kernel. It:

- synchronizes reset into `clk_sys`
- selects SPAD versus calibration async inputs
- exposes the CSR programming model
- surfaces either the local narrow packet stream or the shared-readout export

It is the module the TOP-level SPADMIC design instantiates three times.

### `mptdc_core`

This is the real TDC kernel integration point. It contains:

- async START/STOP handling
- both oscillator domains
- the 8x8 PD matrix
- context capture
- drain/FIFO/readout plumbing

If `mptdc_top_asic` is the shell, `mptdc_core` is the engine.

## 3. Async frontend blocks

| Block | File | Role |
|-------|------|------|
| `mptdc_async_frontend_v2` | `rtl/async/mptdc_async_frontend_v2.sv` | accepts START/STOP, allocates contexts, controls async oscillator enables |
| `mptdc_stop_capture_async` | `rtl/async/mptdc_stop_capture_async.sv` | captures STOP-edge boundary metadata |
| `mptdc_context_bank` | `rtl/async/mptdc_context_bank.sv` | frozen storage for one conversion snapshot per context |

### `mptdc_async_frontend_v2`

This block owns the earliest event acceptance policy:

- when START can arm a conversion
- when STOP is accepted
- how context availability gates new work
- how async oscillator enables are driven

It is the front door to the measurement engine.

### `mptdc_stop_capture_async`

This is the boundary observer for the STOP edge. It captures side information
that is needed to reconstruct the event coherently later, including the phase-0
and debug boundary snapshots.

### `mptdc_context_bank`

The context bank is where an in-flight conversion becomes a frozen drainable
record. It separates the fast capture side from the slower system-clock drain
side and is central to the design's double-buffered behavior.

## 4. CDC blocks

| Block | File | Role |
|-------|------|------|
| `mptdc_reset_sync` | `rtl/cdc/mptdc_reset_sync.sv` | asynchronous reset assertion with synchronous release |
| `mptdc_gray_cnt_sync` | `rtl/cdc/mptdc_gray_cnt_sync.sv` | Gray-counter capture into a destination domain |
| `mptdc_sync_fifo` | `rtl/cdc/mptdc_sync_fifo.sv` | small synchronous FIFO used in the drain/readout path |
| `mptdc_pulse_sync` | `rtl/cdc/mptdc_pulse_sync.sv` | generic pulse crossing helper, compiled but not in the active top path |

These files are not interchangeable utilities. Each exists because the design
crosses intentionally between:

- async event logic
- oscillator-generated measurement clocks
- `clk_sys`

`mptdc_reset_sync` is the most broadly reused of the group and also appears in the
TOP-level integration.

## 5. Oscillator blocks

| Block | File | Role |
|-------|------|------|
| `mptdc_osc_wrapper` | `rtl/osc/mptdc_osc_wrapper.sv` | interface wrapper around the chosen oscillator implementation |
| `mptdc_osc_model` | `rtl/osc/mptdc_osc_model.sv` | simulation-time behavioral oscillator |
| `mptdc_osc_stub` | `rtl/osc/mptdc_osc_stub.sv` | synthesis-time placeholder until the real macro is available |

The wrapper exists so the rest of the digital design can keep a stable contract
while simulation and synthesis use different oscillator realizations.

## 6. Phase-detector block

| Block | File | Role |
|-------|------|------|
| `mptdc_pd_cell` | `rtl/pd/mptdc_pd_cell.sv` | one phase-detector cell in the 8x8 matrix |

This is the leaf that turns the slow/fast phase relationship into one hit-level
decision plus local metadata. It is replicated `64` times, so its behavior is
small locally but architecturally dominant globally.

## 7. Control blocks

| Block | File | Role |
|-------|------|------|
| `mptdc_input_mux` | `rtl/ctrl/mptdc_input_mux.sv` | selects SPAD or CAL async inputs |
| `mptdc_meas_ctrl` | `rtl/ctrl/mptdc_meas_ctrl.sv` | fast-domain measurement FSM and safe shutdown sequence |
| `mptdc_drain_ctrl` | `rtl/ctrl/mptdc_drain_ctrl.sv` | system-domain drain FSM over the frozen context |
| `mptdc_watchdog` | `rtl/ctrl/mptdc_watchdog.sv` | global/system watchdog logic |

### `mptdc_meas_ctrl`

This is one of the most important blocks in the design because it owns:

- close detection
- hit-count-based stop
- watchdog-based stop
- the `CAPTURE -> STOP_OSC -> CLEAR` sequence

That sequence is the core of the design's safe shutdown behavior.

### `mptdc_drain_ctrl`

Once capture is complete, this block walks the frozen context and emits:

1. one META record
2. one HIT record per active PD cell
3. context release

It is the bridge between "analog-adjacent measurement" and "digital packetized readout".

## 8. Readout blocks

| Block | File | Role |
|-------|------|------|
| `mptdc_csr_minimal` | `rtl/readout/mptdc_csr_minimal.sv` | software-visible control and status register bank |
| `mptdc_narrow16_tx_v2` | `rtl/readout/mptdc_narrow16_tx_v2.sv` | 16-bit packet serializer |
| `mptdc_tconv_reco` | `rtl/readout/mptdc_tconv_reco.sv` | timestamp reconstruction helper, compiled but not in the active datapath |

### `mptdc_csr_minimal`

This block exposes the software knobs that shape the measurement behavior:

- input select
- output mode
- `max_hits`
- watchdog settings
- `conv_arm`
- FIFO clear and status visibility

### `mptdc_narrow16_tx_v2`

This is the local packetizer that turns acquisition records into the 16-bit word
stream used both by standalone MPTDC and by the TOP shared-readout path.

Even after the TOP DDR-TX redesign, this serializer still matters because the TOP
preserves the logical 16-bit packet grammar upstream of the physical packer.

## 9. Special-status blocks

| Status | Meaning |
|--------|---------|
| active in silicon-oriented path | compiled and used in the live TDC datapath |
| compiled support block | built with the RTL but not used in the live top-level path |
| simulation-only | used only for simulation realism |
| synthesis placeholder | used only to let digital synthesis proceed before analog macro handoff |

### Current classification

- active in path: all top, async, PD, main control, CSR, serializer, sync FIFO blocks
- compiled support block: `mptdc_pulse_sync`, `mptdc_tconv_reco`
- simulation-only: `mptdc_osc_model`
- synthesis placeholder: `mptdc_osc_stub`

## 10. Verification-closure expectation

Every active-in-path block should have direct verification evidence or an
explicit waiver. Direct evidence can be a unit bench, stress bench, VIP scenario,
assertion, functional coverage bin, scoreboard check, or campaign analysis hook.
Waivers should be reserved for blocks whose behavior is better proven at a
subsystem boundary than at the leaf boundary.

The minimum closure intent by group is:

| Area | Closure expectation |
|------|---------------------|
| Package | constants, legal ranges, packet helpers, and timestamp helpers cross-checked against protocol docs |
| Top wrappers | CSR/reset/input-select/shared-export behavior checked in standalone and TOP-integrated modes |
| Async frontend | START/STOP/context acceptance, rejected STARTs, held events, and reset recovery stressed |
| CDC | reset release, Gray snapshots, FIFO state, and intentional exceptions reviewed with CDC/lint evidence |
| Oscillator | behavioral model checked against a documented macro contract until the real macro exists |
| Phase detector | single-cell behavior, matrix geometry, clear behavior, and physical-symmetry assumptions covered |
| Control | fast close, max-hit close, watchdog close, and safe shutdown ordering asserted/tested |
| Readout | META/HIT sequencing, FIFO pressure, serializer packet grammar, and shared-export mode checked exactly |

The verification guide owns the detailed closure matrix and signoff tiers:
[`04_VERIFICATION.md`](04_VERIFICATION.md).

## 11. Suggested reading order

For a newcomer trying to understand the live RTL:

1. `rtl/pkg/mptdc_pkg.sv`
2. `rtl/top/mptdc_top_asic.sv`
3. `rtl/top/mptdc_core.sv`
4. `rtl/async/mptdc_async_frontend_v2.sv`
5. `rtl/ctrl/mptdc_meas_ctrl.sv`
6. `rtl/async/mptdc_context_bank.sv`
7. `rtl/ctrl/mptdc_drain_ctrl.sv`
8. `rtl/readout/mptdc_narrow16_tx_v2.sv`

Then use:

- [`01_ARCHITECTURE.md`](01_ARCHITECTURE.md)
- [`02_OUTPUT_PROTOCOL.md`](02_OUTPUT_PROTOCOL.md)
- [`10_SHARED_READOUT_EXPORT.md`](10_SHARED_READOUT_EXPORT.md)
