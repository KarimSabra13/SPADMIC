# O13 Phase Buffer Placement Plan

REPORT_STATUS=REVIEW_REQUIRED

O13 is only physically meaningful if the two-stage phase-distribution cells are placed in a controlled and balanced way.

## Topology

Each tap should use the same topology:

```text
RO_tune4/S[n]
  -> BUHDX4 u_iso
  -> BUHDX12 u_drv
  -> phase fabric
```

No tap-specific sizing is allowed in the first O13 experiment.

## Placement Goals

- Place the first-stage `BUHDX4 u_iso` cells close to the RO output side.
- Place the second-stage `BUHDX12 u_drv` cells close to the start of digital phase distribution.
- Preserve tap order from `0` to `7`.
- Use identical orientation where possible.
- Keep raw RO to `u_iso/A` routes very short.
- Keep `u_iso/Q` to `u_drv/A` routes comparable across taps.
- Keep final `u_drv/Q` distribution routes balanced enough for calibration.
- Avoid placing phase buffers in unrelated backend regions.
- Report tap-to-tap distance, route, delay, cap, and transition mismatch.

## Innovus Hook

Placement hook:

```text
MPTDC/pnr/scripts/innovus_o13_phase_buffer_place.tcl
```

Required origins before applying the hook:

```text
MPTDC_O13_SLOW_ISO_X
MPTDC_O13_SLOW_ISO_Y
MPTDC_O13_SLOW_DRV_X
MPTDC_O13_SLOW_DRV_Y
MPTDC_O13_FAST_ISO_X
MPTDC_O13_FAST_ISO_Y
MPTDC_O13_FAST_DRV_X
MPTDC_O13_FAST_DRV_Y
```

Optional placement controls:

```text
MPTDC_O13_PHASE_BUF_PITCH_UM
MPTDC_O13_PHASE_BUF_ORIENT
```

The hook writes:

```text
reports/phase_buffer_placement_constraints.rpt
```

## Metrics

Required report files:

- `phase_buffer_topology.csv`
- `phase_buffer_placement.csv`
- `phase_buffer_output_loads.csv`
- `phase_buffer_route_summary.csv`
- `phase_buffer_delay_estimate.csv`
- `phase_buffer_balance_summary.md`

Pass targets for feasibility:

| Metric | Preferred | Warning | Fail unless explicitly accepted |
|---|---:|---:|---:|
| Raw RO load | <= 58.72 fF | <= 75.59 fF | > 75.59 fF |
| Final output transition | <= 0.5 ns | 0.5-0.75 ns | > 0.75 ns |
| Tap-to-tap cap mismatch | < 10% | 10-20% | > 20% |
| Raw RO route | short/balanced | review | long/asymmetric |
| Phase delay mismatch | quantified | review | unmeasured |

If placement remains unknown or highly asymmetric, O13 is not closure-quality even if the topology and raw load are correct.
