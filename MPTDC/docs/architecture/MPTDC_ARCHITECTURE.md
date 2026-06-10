# MPTDC Architecture

Author: Karim Sabra

This document describes the active MPTDC RTL architecture.  It is a design
description, not a final signoff statement.

## System Boundary

The top-level ASIC wrapper is `rtl/top/mptdc_top_asic.sv`; the main integration
point is `rtl/top/mptdc_core.sv`.  The design contains:

- `clk_sys` control, drain, FIFO, CSR, and readout logic.
- Two oscillator phase families: slow and fast.
- An `8 x 8` phase-detector matrix.
- Async capture/context logic that bridges measurement-local phase activity
  into the system-clock drain path.
- A fixed 16-bit packetized output stream.

The packet format is fixed by RTL package types and readout logic.  Cleanup and
timing-flow work must not change packet fields, ordering, or calibration
semantics.

## Oscillator And Phase Distribution

The physical timing model uses two `RO_tune4` macro abstracts, one slow and one
fast.  Their `S[0:7]` pins are the raw analog phase sources and remain protected
load-check points in synthesis and PnR.

The current digital phase distribution inserts a two-stage buffer chain per tap:

```text
RO_tune4/S[n] -> BUHDX4 -> BUHDX12 -> buffered phase clock
```

The raw RO phase pins are still modeled and checked.  The buffered phase clocks
are the intended downstream digital phase clocks used by the current typical
clock model.  Clock-tree synthesis must not treat RO or phase clocks like
ordinary `clk_sys` clocks.

## Phase Detector Matrix

The PD fabric is an `8 x 8` matrix.  Each row corresponds to a slow phase and
each column corresponds to a fast phase.  The intended timing relationship is a
Vernier slow-to-fast sampling relation: selected slow-phase state is sampled in
the fast-phase domain by the PD cell.

That slow-to-fast sampling is intentional measurement behavior.  It is not a
packet-format change and it is not a calibration bypass.  Timing exceptions for
this path must be narrow, count-checked, and limited to the intentional PD
sampler relation.

## Epoch And Tags

The design uses a local fast `raw_lfsr_tag` for fast-side phase context and a
slow Johnson epoch for slow-side context.  These fields preserve measurement
state without reintroducing a global fast counter.

The raw tag and epoch are consumed by the capture and drain path, then emitted
through the existing fixed packet format.  Any calibration or reconstruction
change must remain compatible with that packet contract.

## Async Capture And Context Bridge

Measurement activity is local to oscillator and PD timing domains.  The capture
bridge holds the raw PD image and associated context, then hands a stable image
to the `clk_sys` drain path.  The current architecture keeps the measurement
fabric and system control fabric separated:

- Async STOP and epoch capture record measurement-local events.
- Context banks preserve the sampled image.
- CDC helpers synchronize control pulses and counters where needed.
- Drain logic consumes complete records only after capture is stable.

## Drain, FIFO, And Readout

The drain controller serializes hit records into an acquisition FIFO.  The
readout path can use the local narrow 16-bit transmitter or the shared
acquisition-record export interface, depending on integration mode.  The active
RTL keeps a fixed packet format and does not use cleanup work to alter software
visible fields.

## Design Constraints

The active closure assumptions are:

- Typical-only timing view for the current flow.
- R750_delta5 frequency mode for the active oscillator timing constants.
- `RO_tune4` macro binding is required for physical synthesis/PnR studies.
- RO/phase clocks are protected from normal CTS treatment.
- `clk_sys` remains the ordinary digital clock-tree target.
- Final MMMC, post-layout characterization, LVS/DRC/PEX, and analog phase
  confirmation are not complete in this repository state.
