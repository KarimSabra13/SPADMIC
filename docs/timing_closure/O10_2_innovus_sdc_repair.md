# O10.2 Innovus SDC Repair

## Intent

Use the same O9 R750 delta5 typical timing intent in Innovus without relying on Genus-side Tcl variables.

## Constraints

- Do not use Genus-only `design(...)` variables.
- Do not duplicate clocks if the post-synthesis SDC already defines them.
- Do not change the R750 delta5 timing model.
- Do not create CTS trees for RO phase clocks.
- Keep uncertainty at 10 ps setup and 5 ps hold.

## O10.2 SDC

File:

`MPTDC/pnr/constraints/mptdc_osc_typical_r750_delta5_innovus.sdc`

Constants:

- fast period: 1.333 ns
- slow period: 1.430 ns
- fast tap step: 0.074 ns
- slow tap step: 0.079 ns
- setup uncertainty: 0.010 ns
- hold uncertainty: 0.005 ns

Expected clocks:

- `clk_osc_fast` plus `clk_osc_fast_tap1` through `clk_osc_fast_tap7`
- `clk_osc_slow` plus `clk_osc_slow_tap1` through `clk_osc_slow_tap7`
- `clk_sys`

O10.2 reports the matched RO pins and final RO clock count. If 16 RO clocks are not present, the run remains review-required.

## Status

This is an Innovus-safe expression of the existing O9 typical feasibility view. It is not MMMC signoff and not final silicon signoff.
