# O7 Typical RO Model Plan

Branch: `SPADMIC_localtag`

Purpose: run one typical-only Genus feasibility pass that uses the latest
available oscillator simulation reference without pretending it is signoff data.

## Scope

O7 uses the screenshot-derived YAML model:

`MPTDC/analog_handoff/ro_tune4_typical_from_screenshot.yaml`

The source is manual screenshot extraction.  The screenshots appear labeled
`RO_tune3`, while digital synthesis binds `RO_tune4`.  The equivalence is not
confirmed.  This is a feasibility-only bridge until analog can provide real CSV,
Ocean, corner, load, and Liberty data.

## Timing Model

The screenshots do not justify a new oscillator frequency or exact tap spacing.
O7 therefore keeps the existing nominal digital clock model:

| Quantity | O7 value |
|---|---:|
| slow period | 1.000 ns |
| fast period | 0.900 ns |
| slow tap step | 0.055 ns |
| fast tap step | 0.050 ns |
| observed jitter RMS | 0.614 ps |
| setup uncertainty | 10.0 ps |
| hold uncertainty | 5.0 ps |
| rstb-to-S5 startup marker | 367.907 ps |

The uncertainty is reduced from the older generic placeholder to a guarded
typical value.  `10 ps` is much larger than six sigma of the visible `0.614 ps`
S<5> RMS jitter, but it still leaves room for screenshot error and tap mismatch.

## Genus Use

Use:

- typical standard-cell Liberty only
- real `RO_tune4` LEF if available
- `RO_tune4` Liberty shell only as a structural shell
- clocks on `RO_tune4/S[0:7]`
- SDC overlay `MPTDC/syn/inputs/mptdc_osc_typical_from_screenshot.sdc`
- no broad oscillator-domain false paths
- no Innovus launch from this step

Do not use:

- worst/slow standard-cell setup view
- BC/WC MMMC analysis views
- screenshot-derived period/tap/frequency inventions
- screenshot slopes as final clock transition/slew

The checked-in Genus entrypoint still reads a file named `mptdc.mmmc`, but O7
sets `MPTDC_TIMING_VIEW=tc_only`, so the file creates only `tc_view` and selects
it for both setup and hold.

## Required Follow-Up

Analog still needs to provide real RO_tune4 data:

- confirmed RO_tune4 simulation source, not RO_tune3 unless equivalence is shown
- period per tune mode
- tap threshold crossing times
- per-tap slew and jitter
- output load used during characterization
- PVT/corner behavior
- real Liberty and physical timing model
