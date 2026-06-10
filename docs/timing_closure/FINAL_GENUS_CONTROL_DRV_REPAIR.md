# Final Genus Control DRV Repair

Scope: final typical Genus DRV closure only. Do not relax max transition above
`500 ps`, do not touch raw RO phase nets, and do not apply design-wide
transition pressure.

## Guarded Baseline Root

Known root from `final_typical_genus_repair_guarded_20260610_143941`:

```csv
net,logical_name,driver_inst,driver_cell,fanout,worst_transition_ps,limit_ps,violation_ps,sink_count,sink_family,proposed_fix
n_6984,PD_detect_enable_or_clear_derived_control,g33116,INHDX8,88,511,500,11,89,PD_DETECT_ENABLE_OR_CLEAR_LOCAL_LOGIC,TARGETED_BUFFER_TREE_OR_STRONGER_INVERTER_DRIVER_LOCAL_MAX_FANOUT_16_OR_32
```

This is one high-fanout local PD control root, not 1015 independent root
causes. It is not a raw RO output and not part of the O13 phase clock tree.

## Generated Report

The wrapper writes:

`reports/control_drv_root_causes.csv`

Columns:

- `net`
- `logical_name`
- `driver_inst`
- `driver_cell`
- `fanout`
- `worst_transition_ps`
- `limit_ps`
- `violation_ps`
- `sink_count`
- `sink_family`
- `proposed_fix`

`reports/drv_transition_root_causes.csv` is still produced for backwards
compatibility.

## Control-Only Experiment

The control-only run enables:

- `STRONG_CONTROL_DRV=1`
- local control-net `set_max_fanout 16`
- local control-net `set_max_transition 0.50 ns`

The control-only run disables:

- `STRONG_FAST_TAG_FLOPS`
- fast-tag preserve relaxation
- design-wide DRV pressure
- broad endpoint remapping

Observed result:

- `final_typical_genus_control_only_20260610_152702`
- setup WNS `-23.0 ps`
- setup TNS `-1870.3 ps`
- setup violating paths `218`
- DRV `0 / 0 / 0`

This proves that the control repair can remove the transition violations, but
the all-stage control-cell bias still perturbs fast-domain timing too much.

## Late Control Experiment

The next experiment is:

`MPTDC_FINAL_TYPICAL_GENUS_REPAIR_CONTROL_LATE`

This keeps the guarded baseline mapping as long as possible and applies
control-cell bias only at `post_map_pre_opt`. It also leaves `INHDX8` legal,
because the guarded baseline root was already `INHDX8` and only missed the
`500 ps` max-transition limit by about `11 ps`.

Expected knobs:

- `STRONG_CONTROL_DRV=1`
- `CONTROL_CELL_BIAS_STAGE=post_map_only`
- `CONTROL_AVOID_INHDX8=0`
- `STRONG_FAST_TAG_FLOPS=0`
- fast-tag preserve relaxation disabled
- design-wide DRV pressure disabled

## Interpretation Rules

If timing returns to the guarded baseline and DRV is `0 / 0 / 0`, the control
repair is good.

If timing remains near `-80 ps`, the control-driver bias is still perturbing
fast timing. Replace it with an exact-net repair for the dominant root only.

If DRV returns on `n_6984`, the control-only repair is incomplete. The next
step is a narrow buffer tree or source-strength repair on that exact net, not
a global pressure mode.

If the root is later proven to be reset or asynchronous clear, buffering is
allowed only with recovery/removal protocol review.
