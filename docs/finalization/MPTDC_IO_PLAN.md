# MPTDC IO Plan

Status: `PLANNED_AFTER_GENUS_REVIEW`

## Goals

- Keep the MPTDC macro interface routable.
- Avoid pad-level assumptions in the macro-level typical-only implementation.
- Preserve the fixed packet/readout contract.

## Constraints

- Do not change packet format.
- Do not change calibration semantics.
- Do not change `raw_lfsr_tag`.
- Do not change oscillator frequency mode.

## Proposed IO Grouping

- `clk_sys` and reset/control pins: near digital control.
- SPAD/calibration async inputs: near frontend/control boundary.
- acquisition record outputs or packet-adapter interface: near readout/FIFO side.
- analog macro controls: near the RO macro side when practical.

## Load Model

Use the provisional XLIBD-backed block-level load model only for reporting and
macro feasibility:

- light: `12.8 fF`
- medium: `25.6 fF`
- heavy: `51.2 fF`

These are not pad-level signoff loads.

## Reports

- IO pin placement summary
- IO load assumptions
- output load check
- reset/control transition check
- packet interface connectivity check
