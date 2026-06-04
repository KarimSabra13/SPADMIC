# O10.1 Innovus SDC Repair

O10 used the O9 Genus overlay directly:

- `MPTDC/syn/inputs/mptdc_osc_typical_r750_delta5.sdc`

That file references Genus-side `design(...)` variables. Innovus does not define those variables, so O10 saw `CTE-27` and the SDC read aborted.

O10.1 uses:

- `MPTDC/pnr/constraints/mptdc_osc_typical_r750_delta5_innovus.sdc`

This overlay is self-contained:

- fast period: `1.333 ns`
- slow period: `1.430 ns`
- fast tap step: `0.074 ns`
- slow tap step: `0.079 ns`
- setup uncertainty: `0.010 ns`
- hold uncertainty: `0.005 ns`

The post-synthesis SDC remains loaded first. The O10.1 overlay applies oscillator uncertainty to existing clocks and only attempts to create missing RO clocks if necessary.

This remains a typical-only feasibility constraint view. It is not MMMC signoff.
