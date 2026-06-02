# O4 R600 What-If Plan

## Purpose

R600 is now the main accepted fallback for PD-local timestamp-freeze timing because the PD behavior is locked.

This is a Genus timing-feasibility experiment, not analog or calibration signoff.

## What-If Values

The first R600 SDC-only what-if uses:

| Parameter | Value |
| --- | ---: |
| slow period | `1.667 ns` |
| fast period | `1.567 ns` |
| slow tap step | `0.1041875 ns` |
| fast tap step | `0.0979375 ns` |

These values are internally consistent with eight taps over a half period. They do not prove that analog can preserve the original 5 ps Vernier delta.

## Required Analog Confirmation Before Keeping R600

R600 cannot become final until analog confirms:

- slow tune code
- fast tune code
- slow tap delay
- fast tap delay
- Vernier delta
- startup delay
- valid first-edge behavior
- jitter
- output slew
- maximum load per S output

## Expected Genus Interpretation

If nominal still fails but R600 moves `OSC_FAST_REAL` into a plausible range, use R600 as the next analog-confirmed path.

If R600 still has `OSC_FAST_REAL` WNS around `-1.5 ns` to `-2 ns` on the same PD-local timestamp-freeze paths, do not spend more closure-effort runtime on this RTL/frequency. That result means the locked PD standard-cell implementation is still not feasible at R600.
