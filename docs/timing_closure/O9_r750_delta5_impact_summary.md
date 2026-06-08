# O9 R750 Delta5 Impact Summary

O9 R750 delta5 is a new calibrated frequency/tap mode. It is not the same
oscillator model as the prior nominal 0.900 ns / 1.000 ns synthesis target.

## What Changed

| Quantity | Previous nominal | O9 R750 delta5 |
|---|---:|---:|
| Fast period | 0.900 ns | 1.333 ns |
| Fast frequency | about 1111 MHz | about 750.2 MHz |
| Slow period | 1.000 ns | 1.430 ns |
| Slow frequency | 1000 MHz | about 699.3 MHz |
| Fast tap step | 50 ps | 74 ps |
| Slow tap step | 55 ps | 79 ps |
| Vernier delta | 5 ps | 5 ps |
| `DELTA_LSB` | 10 ps | 10 ps |
| `K_VERNIER` | 11 | 15 |

The mode is enabled with:

```systemverilog
`define MPTDC_FREQ_R750_DELTA5
```

The package-derived constants for this mode are:

- `OSC_TS_SLOW_PS = 79`
- `OSC_TS_FAST_PS = 74`
- `DELTA_STEP = 5 ps`
- `DELTA_LSB = 10 ps`
- `K_VERNIER = 15`

## Why It Was Changed

O8 typical closure was still missing the fast oscillator view by roughly
hundreds of ps. The R750/R700 target lowers the fast oscillator requirement to
about 1.333 ns while preserving the 5 ps tap delta:

- fast tap step scales from 50 ps to about 74 ps,
- slow tap step is fast tap step plus 5 ps, about 79 ps,
- slow period becomes about 1.43 ns,
- fast frequency becomes about 750 MHz,
- slow frequency becomes about 700 MHz.

This moved the final O9 Genus result to a near-clean state: WNS -1.6 ps, TNS
-11.2 ps, and 7 residual `OSC_FAST_REAL` setup paths.

## Packet Impact

The production packet format does not need to change for O9:

- `HEADER + 2*HIT + EOC` structure remains the same.
- HIT W0 layout remains `nslow[6:0]` and `nfast[6:0]`.
- HIT W1 layout remains `ns`, `nf`, and `stop_phase_disc`.
- `NFAST_W` remains 7.
- `NSLOW_W` remains 7.
- `ns` and `nf` widths remain unchanged.
- `nfast_encoding` remains `raw_lfsr_tag`.

The packet bits carry the same fields, but the interpretation of those fields
must use the O9 timing constants. This is a calibration/model change, not a
packet-format change.

## Calibration Impact

Calibration must be regenerated for O9 because the absolute tap steps changed.
The fine Vernier delta remains 5 ps and the 10 ps LSB target is preserved, but:

- `K_VERNIER` changes from 11 to 15,
- absolute fast and slow tap spacing changes,
- delay reconstruction must use the O9 mode constants,
- raw tag decoding must remain synchronized with the `raw_lfsr_tag` table,
- conversion timing/deadtime can change because oscillator periods changed.

The committed characterization manifests show the O9 run used `freq_mode =
r750_delta5` consistently in simulation and analysis, but the detailed
calibration metric reports are not committed locally.

## Range And Deadtime

The 7-bit `nfast` and `nslow` fields remain unchanged. The raw measurement range
is still represented through the same packet fields, but the physical time
represented by a count changes because the oscillator periods and tap steps are
different. That means downstream reconstruction must use the O9 constants and
O9 LUT/calibration products.

The characterization campaign requested delays from 20 ps to 30000 ps and
fixed-delay points from 20 ps through 30000 ps. The manifests show the campaign
completed, but the committed checkout does not include enough metric summaries
to prove coverage quality, boundary behavior, no-hit rate, max-hit rate, or
deadtime behavior.

## Analog Dependency

O9 remains analog-dependent and provisional:

- The oscillator model is based on screenshot-derived typical values, not CSV or
  Ocean exports.
- The screenshot reference was labeled around `RO_tune3`, while the digital macro
  is `RO_tune4`; equivalence still must be confirmed.
- The `RO_tune4` LEF is real, but the Liberty remains a structural shell.
- Analog tune codes for the R750/R700 target still need confirmation.
- No PVT/corner oscillator data has been applied.
- This is not MMMC or final silicon signoff.

## Bottom Line

O9 R750 delta5 preserves the intended 5 ps Vernier delta and the production
packet layout, while relaxing the oscillator period enough to make Genus timing
nearly close in the typical view. It must be treated as a new calibrated mode:
the packet format stays fixed, but simulation, analysis, calibration, and
synthesis must all use the same O9 frequency constants.

