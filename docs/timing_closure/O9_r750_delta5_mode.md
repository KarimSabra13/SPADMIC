# O9 R750 Delta5 Mode

Mode name: `O9_R750_DELTA5`

This mode is a typical feasibility and characterization candidate. It is not
final signoff, does not replace MMMC/PVT closure, and does not prove analog RO
tune codes. The oscillator reference is still provisional screenshot-derived
typical data; CSV/Ocean and corner data are still required before signoff.

## Frequency And Tap Target

| Quantity | Value |
| --- | ---: |
| Fast period | about 1.333 ns |
| Fast frequency | about 750 MHz |
| Fast tap step | 74 ps |
| Slow tap step | 79 ps |
| Slow period | about 1.430 ns |
| Slow frequency | about 700 MHz |
| Vernier delta | 5 ps |
| DELTA_LSB | 10 ps |

The mode preserves the current 5 ps Vernier delta approximately while moving
the fast oscillator target to the first practical timing-closure point from O8.
O8 typical closure still had about -416 ps WNS at a 0.900 ns fast period; adding
that slack demand gives a required period near 1.316 ns, so 1.333 ns is a clean
first R750 target.

## Impact

- Fine resolution target stays near the current 10 ps LSB.
- Absolute tap steps change from 55/50 ps to 79/74 ps.
- `K_VERNIER` changes from 11 to 15 with integer package math.
- Calibration must be regenerated for this mode.
- Packet word count, field widths, and HEADER/HIT/EOC layout do not change.
- `nfast[6:0]` remains a raw LFSR tag in the production candidate.
- Conversion timing and deadtime can change and must be re-characterized.

Do not use only SDC changes for characterization. RTL, simulation manifests,
analysis, calibration, and synthesis must all declare `freq_mode=r750_delta5`
and use the same 79/74 ps constants.
