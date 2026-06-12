# MPTDC Repair8 Genus Typical Closure Review

Review run: `spadmic_test_stride2_genus_repair8_jihd_exact_20260612_130302`

Branch: `SPADMIC_test`

Genus Git HEAD: `f46e1390800dc3ef03caa709560f024ba1e75fa5`

## Decision

`GENUS_TYPICAL_CLOSED`

The Repair8 JIHD exact fast-tag closure run is the current Genus typical
handoff candidate for Innovus typical closure. It closes setup in STRIDE2 mode
without changing packet semantics, `raw_lfsr_tag`, `r750_delta5`, or the O13
phase-buffer topology.

## What Changed In Repair8

- Used `MPTDC_STDCELL_FAMILY=JIHD`.
- Kept the exact FAST_TAG_TO_PD_TS datapath pressure active.
- Kept exact taps `0..7` and bits `0`, `5`, `6`.
- Used exact max delay pressure around `1.04 ns`.
- Did not enable global strong fast-tag flop bias.
- Did not enable design-wide DRV pressure.
- Did not apply source-cell forcing in the final run.

The final run does not require `FAST_TAG_EXACT_SOURCE_CELL_*` reports to pass.
Those reports are required only for source-cell forcing experiments. For
Repair8, the relevant conditions are setup closure, DRV cleanliness, exact
path repair status `PASS`, and fast-tag mapping parser status `PASS`.

## Evidence

| Check | Result |
|---|---:|
| Setup WNS | `+0.1 ps` |
| Setup TNS | `0 ps` |
| Setup violating paths | `0` |
| Real timed WNS | `+0.1 ps` |
| Real timed TNS | `0 ps` |
| Real timed violating paths | `0` |
| Max transition violations | `0` |
| Max capacitance violations | `0` |
| Max fanout violations | `0` |
| UNKNOWN_REVIEW_REQUIRED | `0` |
| PD Vernier exception | `64/64`, applied `YES` |
| Raw RO clocks | `16` |
| Buffered phase clocks | `16` |
| clk_sys async grouping | `YES` |
| RO_tune4 instances | `2` |
| old oscillator stub residue | `0` |

## Former Critical Path

The closed path family was:

```text
fast_tag_col[nf][bit] -> PD nfast_hit_latched[bit]
```

This path is real fast oscillator-domain timing. It must remain timed in
Innovus. It is not CDC, not the intentional PD Vernier exception, and not a
candidate for false-path or multicycle relaxation.

## Low-Margin Warning

`GENUS_WNS_MARGIN_LOW=YES`

The margin is only about `+0.1 ps`, which is technically positive but not
physically robust. The first Innovus closure run must use timing-preserving
placement and routing, not density alone, to protect FAST_TAG_TO_PD_TS.

## Limitations

Repair8 is a Genus typical closure handoff. It is not MMMC signoff and not
final silicon signoff. Reset/recovery, antenna, physical DRC/LVS, extraction,
and post-route timing remain P&R and signoff responsibilities.
