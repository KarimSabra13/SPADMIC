# O7 Photo-Extracted RO Values

Status: `PROVISIONAL_FROM_SCREENSHOT_NOT_FOR_SIGNOFF`

These values come from manual inspection of Virtuoso screenshots, not CSV,
Ocean, or Liberty export.  They are approximate and are only for the O7
typical-only Genus feasibility run.  They must not be used for MMMC, tapeout
signoff, or final oscillator signoff.

The screenshots are labeled around `SPADMIC_RO_tune3_sim2_maestro` /
`RO_tune3_sim2`, while the digital macro is `RO_tune4`.  RO_tune3/RO_tune4
equivalence is not proven and must be confirmed before any signoff use.

## Visible Electrical Context

| Item | Provisional value |
|---|---:|
| VDD | about 1.8 V |
| VSS | 0 V |
| measurement threshold | about 0.9 V |
| output swing | about 0 mV to 1.75-1.80 V |

At the displayed cursor around `1.02863 ns`, the visible voltages are:

| Node | Voltage |
|---|---:|
| `/rstb` | about 1801.0 mV |
| `S<5>` | about 1787.5 mV |
| `S<6>` | about 1741.8 mV |
| `S<7>` | about 898.34 mV |
| `S<0>` | about -2.01 mV |
| `S<1>` | about 1.284 mV |
| `S<2>` | about 19.11 mV |
| `S<3>` | about 966.94 mV |
| `S<4>` | about 1792.6 mV |

`S<7>` and `S<3>` are near the 0.9 V threshold at this cursor, which suggests
phase progression across the eight taps.  This single cursor is not enough to
derive exact tap spacing.

## Startup Marker

| Marker | Time | Voltage |
|---|---:|---:|
| `rstb` threshold-like marker | 432.843 ps | 869.598 mV |
| `S<5>` threshold-like marker | 800.750 ps | 945.803 mV |
| delta | 367.907 ps | 76.2043 mV |
| local cursor slope | 207.13 MV/s |  |

Use `367.907 ps` only as a provisional rstb-to-first-observed-`S<5>` crossing
startup delay.  Do not use it as oscillator period or tap spacing.

## Eye/Jitter Marker

For `S<5>`, the eye diagram annotation after 45 start/stop events shows:

| Item | Provisional value |
|---|---:|
| RMS jitter/noise | 613.561 fs |
| RMS jitter/noise | 0.613561 ps |
| threshold | about 900.0 mV |
| marker A | 2.467601 ns, 900.02458 mV |
| marker B | 2.4682145 ns, 900.19908 mV |
| dx | 613.561 fs |
| dy | 174.508 uV |
| local cursor slope | 284.42 MV/s |

The O7 feasibility overlay rounds this to `RO_JITTER_RMS_PS = 0.614`.  Since
this is one visible tap in a screenshot, the SDC uses guarded uncertainty:
`10 ps` setup and `5 ps` hold.  Do not assume all taps have identical jitter
without real data.

## Unsupported Values

The screenshots do not support deriving:

- exact oscillator period
- exact tap-to-tap threshold crossing times
- per-tap slew
- per-tap jitter
- extracted load per tap
- PVT/corner behavior
- RO_tune3/RO_tune4 equivalence
- real Liberty timing
