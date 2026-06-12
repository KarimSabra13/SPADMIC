# SPADMIC_test Repair6 Localtag Preserve Close

Repair6 is `SPADMIC_TEST_STRIDE2_GENUS_REPAIR6_LOCALTAG_PRESERVE_CLOSE`.

Repair5 proved that exact `FAST_TAG_TO_PD_TS` source/endpoints are discoverable
and DRV can stay clean, but the requested `DFRRQHDX4` exact source-cell mapping
did not survive optimization: the command was accepted, yet the final target
count stayed zero. Repair6 therefore stops using source-cell forcing as the
default closure lever.

## Localtag-Inspired Change

The `SPADMIC_localtag` closure history reduced the same fast-tag-to-PD timestamp
family to a near-clean residual by relaxing only the `preserve` attribute on
`mptdc_fast_epoch_tag`, while keeping hierarchy, packet format, `raw_lfsr_tag`,
PD hierarchy, and the typical timing view intact.

Repair6 applies that lesson to `SPADMIC_test`:

- enable `MPTDC_RELAX_FAST_TAG_PRESERVE`
- keep exact C-pin to endpoint-D path grouping and max-delay pressure
- use localtag-like fanout/transition limits on exact source Q nets
- do not force exact source cells by default
- do not strengthen endpoint `nfast_hit_latched` flops

## Default Knobs

- `MPTDC_GENUS_REPAIR6_LOCALTAG_PRESERVE_CLOSE=1`
- `MPTDC_GENUS_RELAX_FAST_TAG_PRESERVE=1`
- `MPTDC_FAST_TAG_REPAIR_EXACT_TAPS="0 1 2 3 4 5 6 7"`
- `MPTDC_FAST_TAG_REPAIR_EXACT_BITS="0 5 6"`
- `MPTDC_FAST_TAG_REPAIR_EXACT_MAX_FANOUT=8`
- `MPTDC_FAST_TAG_REPAIR_EXACT_MAX_TRANSITION_NS=0.50`
- `MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_NS=1.04`
- `MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_ENABLE=1`
- `MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL=""`

## Invariants

Repair6 must not alter the O13 clock model, PD Vernier exception, RO topology,
phase-buffer topology, packet format, `raw_lfsr_tag`, `r750_delta5`, clk_sys
async grouping, or STRIDE2 drain behavior.

## Pass Criteria

Minimum pass:

- setup WNS >= 0 ps
- setup TNS = 0
- setup violating paths = 0
- max transition/cap/fanout = 0
- `FAST_TAG_PRESERVE_MODE=RELAXED`
- exact source/endpoints/datapaths are 24 / 192 / 192
- SDC command failures = 0
- summary/raw agreement = PASS
- O13 clocks and PD Vernier exception remain exact

If Repair6 only reaches a small negative residual similar to the old localtag
near-clean result, keep it out of Innovus handoff until the residual is reviewed
against schedule and P&R risk. If WNS does not improve, roll back to the Repair4
/ Repair5 exact-discovery baseline and inspect local buffering or endpoint cell
tradeoffs explicitly.
