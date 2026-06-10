# O13 Phase Buffer Topology XLIBD Justification

Status: `O13_ENGINEERING_REFERENCE_NOT_SIGNOFF`

## Inputs

- XLIBD source: `D_CELLS_HD_LPMOS_typ_1.80V_25C`
- VDD: `1.8 V`
- Temperature: `25 C`
- Selected timing input slope: `0.6210 ns`
- Strict RO analog D-load budget: `58.72 fF`
- CN/clock-like analog estimate: `75.59 fF`

## Input Capacitance

| Candidate | Input cap fF | Strict budget ratio | Interpretation |
|---|---:|---:|---|
| `BUHDX2` | 5.72 | 0.10 | Low load, but too weak for final phase-net drive. |
| `BUHDX3` | 8.07 | 0.14 | Low load, but too weak for final phase-net drive. |
| `BUHDX4` | 10.56 | 0.18 | Safe first-stage RO isolation margin. |
| `BUHDX12` | 32.24 | 0.55 | Also under strict budget, but less analog isolation margin. |
| `INHDX12` | 55.64 | 0.95 | Too close to strict budget for direct RO loading without analog approval. |

The first-stage isolation buffer should remain `BUHDX4`.

## Final Driver Timing Reference

Selected timing at input slope `0.6210 ns`:

| Cell | Load pF | Rise transition ns | Fall transition ns | Interpretation |
|---|---:|---:|---:|---|
| `BUHDX2` | 0.8040 | 2.3207 | 1.5194 | Not a final driver for observed phase-net loads. |
| `BUHDX3` | 0.6058 | 1.1723 | 0.8588 | Not a final driver for observed phase-net loads. |
| `BUHDX4` | 0.8075 | 1.1716 | 0.8442 | Too weak for final phase-net drive near 0.5-0.7 pF. |
| `BUHDX12` | 0.6058 | 0.3080 | 0.2295 | Strong candidate around observed O12/O13 fast net loads. |
| `BUHDX12` | 1.2106 | 0.5955 | 0.4391 | Still plausible near 1.2 pF, but rise edge approaches the warning band. |

O12 moved the heavy digital load away from the analog RO pin but left the `BUHDX4` output driving phase nets around `0.5-0.7 pF`. The extracted `BUHDX4` timing confirms that this is the wrong final driver strength.

## Preferred O13 Topology

```text
RO_tune4/S[n]
  -> BUHDX4 isolation
  -> BUHDX12 final phase driver
  -> phase fabric
```

Reasons:

- Raw RO load remains isolated by the low-cap `BUHDX4` input.
- The final digital phase net is driven by the strongest extracted BUHD cell.
- `BUHDX2` and `BUHDX3` remain available as intermediate-drive options, but are not appropriate final phase drivers for `0.5-0.7 pF`.
- `INHDX12` is not used as first isolation because its `55.64 fF` input cap is too close to the strict analog budget and it would invert phase.
- Scan `SDFFQHDX*` cells are not part of this decision because they are marked `dont_use`.
- All taps keep identical topology.
- Added buffer delay is common and calibratable.
- Packet format and `raw_lfsr_tag` semantics are unchanged.

## If O13 Still Fails Routed Transition

Next candidate:

```text
RO_tune4/S[n]
  -> BUHDX4 isolation
  -> BUHDX12
  -> BUHDX12
  -> phase fabric
```

This must be applied identically to all taps unless a later calibrated asymmetry is explicitly approved.

## Decision

`O13 BUHDX4 -> BUHDX12 remains preferred = YES`

Run O13 abs3 Genus first. Do not run Innovus until the final buffer clocks are correctly integrated into the clock/CDC model.
