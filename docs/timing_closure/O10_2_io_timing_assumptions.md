# O10.2 IO Timing Assumptions

## Current Observation

O10.1 top post-route WNS was on `acq_data_o[*]` external output delay paths. The post-synthesis SDC applies a 0.5 ns output delay to many outputs. That may be too aggressive or inappropriate for a block-level first P&R feasibility run.

## O10.2 Policy

- Do not false-path `acq_data_o`.
- Do not hide IO timing.
- Report IO output timing separately from core timing.
- Label the current IO budget as `PROVISIONAL_BLOCK_IO_BUDGET_NOT_SIGNOFF` until the real block/chip interface budget is known.

## Open Questions For Signoff

- Is `mptdc_top_asic` a top-level chip or a block macro in the eventual integration?
- What is the real external timing budget for `acq_data_o`, CSR outputs, and narrow outputs?
- Are these outputs expected to be registered at the boundary?
- Are pad cells present in this P&R stage, or are these abstract block pins?

## O10.2 Decision

IO paths may dominate aggregate WNS, but they must not dominate the core architecture decision until the real IO budget is defined.
