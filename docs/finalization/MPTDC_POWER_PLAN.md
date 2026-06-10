# MPTDC Power Plan

Status: `PLANNED_AFTER_GENUS_REVIEW`

## Goals

- Provide stable digital supply routing for the PD matrix, buffers, control, and readout.
- Preserve analog macro power intent for `RO_tune4`.
- Keep power planning compatible with later LVS/DRC/PEX work.

## Nets

- Digital standard-cell supply: use the XH018 standard-cell rails required by the PDK.
- RO macro supply pins: preserve `VDD`, `VSS`, and `vdd!` connectivity from the macro abstract.
- Do not rename macro power pins in the implementation flow.

## Plan

1. Define global power and ground nets.
2. Connect standard-cell rails.
3. Connect `RO_tune4` macro power pins explicitly.
4. Build core rings/straps appropriate for the macro-level block.
5. Verify no unconnected macro power pins remain.
6. Run early IR-aware checks if available, but do not claim final IR signoff.

## Reports

- power-net connectivity
- macro power pin connectivity
- stdcell rail continuity
- preliminary power summary

## Limitations

This plan does not claim final EM/IR, LVS, DRC, or PEX signoff.
