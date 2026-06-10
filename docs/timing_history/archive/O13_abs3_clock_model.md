# O13 abs3 Clock Model

Status: `IMPLEMENTED_FOR_GENUS_ABS3`

## Raw RO Clocks

The existing checked-in raw clock names are preserved for flow compatibility:

- `clk_osc_slow`, `clk_osc_slow_tap1..7`
- `clk_osc_fast`, `clk_osc_fast_tap1..7`

Conceptually these are the raw tap clocks for tap `0..7`. They remain attached to `RO_tune4/S[0:7]` and are still the analog source/load-check reference.

## Final Digital Phase Clocks

Abs3 creates final generated clocks at BUHDX12 `Q` outputs:

- `clk_osc_slow_buf_tap0..7`
- `clk_osc_fast_buf_tap0..7`

These are the clocks for downstream digital phase timing.

## Groups

Abs3 applies:

- group 1: `clk_sys`
- group 2: all raw RO clocks plus all final buffer phase clocks

That cuts ordinary synchronous timing between `clk_sys` and oscillator phase clocks, while preserving timing visibility within the oscillator/phase clock group.
