# O12C Slow Phase0 Asymmetry

REPORT_STATUS=REVIEW_REQUIRED

O12B abs4 measured `slow[0]` as much heavier than the other slow taps:

| Tap | Cap fF | Fanout | R ohm |
|---:|---:|---:|---:|
| slow[0] | 520 | 73 | 730 |
| slow[1] | 103 | 8 | 198 |
| slow[2] | 74 | 8 | 103 |
| slow[3] | 128 | 9 | 229 |
| slow[4] | 183 | 9 | 362 |
| slow[5] | 147 | 9 | 279 |
| slow[6] | 94 | 8 | 163 |
| slow[7] | 93 | 8 | 156 |

The likely cause is that `slow[0]` carries slow epoch and metadata loads in addition to phase fabric loads.  This is not an analog-load failure because the analog RO output is already isolated.  It is a digital phase-distribution mismatch risk.

O12C should quantify:

- PD loads on `slow[0]`.
- Slow epoch loads.
- Metadata/debug/probe loads.
- Output transition and delay for `slow[0]`.
- `slow[0]` route length compared to other slow taps.

Do not fix this by adding a one-off stronger buffer to `slow[0]` unless the asymmetry and calibration impact are explicitly documented.

Potential later O13-level decision:

```text
slow_phase0_pd
slow_phase0_epoch_metadata
```

That split would be an RTL/physical change and must not be hidden inside O12C.
