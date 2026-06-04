# O9 R750 SDC Notes

SDC overlay:

```text
MPTDC/syn/inputs/mptdc_osc_typical_r750_delta5.sdc
```

This overlay is typical-only and not signoff. It keeps the O7/O8 guarded
uncertainty derived from the provisional screenshot jitter reference:

| Quantity | Value |
| --- | ---: |
| Fast period | 1.333 ns |
| Slow period | 1.430 ns |
| Fast tap step | 0.074 ns |
| Slow tap step | 0.079 ns |
| Setup uncertainty | 0.010 ns |
| Hold uncertainty | 0.005 ns |

The SDC expects the Genus flow to set:

```text
MPTDC_FREQ_MODE=r750_delta5
MPTDC_FREQ_MODE_DEFINES=MPTDC/syn/inputs/mptdc_freq_modes.defines
MPTDC_OSC_PD_SDC_OVERLAY=MPTDC/syn/inputs/mptdc_osc_typical_r750_delta5.sdc
```

It also expects the RTL filelist to contain `+define+MPTDC_FREQ_R750_DELTA5`.
Do not run an R750 SDC against nominal RTL constants for final comparison.
