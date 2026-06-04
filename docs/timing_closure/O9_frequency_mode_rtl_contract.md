# O9 Frequency Mode RTL Contract

The default build remains the current nominal model:

| Constant | Default nominal | O9 R750 delta5 |
| --- | ---: | ---: |
| `OSC_TS_SLOW_PS` | 55 | 79 |
| `OSC_TS_FAST_PS` | 50 | 74 |
| `DELTA_STEP` | 5 | 5 |
| `DELTA_LSB` | 10 | 10 |
| `K_VERNIER` | 11 | 15 |

O9 is enabled only by compiling RTL with:

```text
+define+MPTDC_FREQ_R750_DELTA5
```

The packet contract is unchanged:

- `NSLOW_W = 7`
- `NFAST_W = 7`
- `nfast` remains the existing 7-bit field
- HIT W0/W1 layout is unchanged
- HEADER + 2*HIT + EOC word structure is unchanged

Calibration and analysis must not assume `K_VERNIER=11` for O9. The
characterization wrappers now record `freq_mode`, `OSC_TS_SLOW_PS`,
`OSC_TS_FAST_PS`, `DELTA_STEP`, `DELTA_LSB`, and `K_VERNIER` in the manifest.
The analysis and LUT calibration CLIs also accept `--freq-mode r750_delta5` so
simulation and reconstruction math can be audited for consistency.
