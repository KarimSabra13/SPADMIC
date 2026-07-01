# MPTDC Route Checkpoint Repair Escalation - 2026-07-01

This note records the route-closure state after the RO_tune6 PnR LEF v2
recovery attempts. The objective is to close the route gate without rerunning
import, floorplan, placement, CTS, and full route from scratch unless the
checkpoint evidence proves that a clean route cannot be repaired in place.

## Current Objective

Move from the DRC-clean-but-unrouted checkpoint to a route-gate-clean checkpoint
that can continue into timing optimization and final signoff.

The active repair source is:

```text
/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_route_ckpt_delete_probe_161359/checkpoints/repaired_route.enc.dat
```

This checkpoint is the best known starting point because fresh `verify_drc`
reports `0` geometry violations and `0` shorts.

## Evidence Timeline

### `20260701_mptdc_tc_ro6_pnrlef_v2_recovery_153333`

The full Innovus recovery run still failed the route gate after the built-in
route recovery attempts:

```text
GEOMETRY_DRC_VIOLATIONS=7
SHORTS=5
ROUTE_DRC_CLASS_COUNTS=Short 5 MetSpc 1 Mar 1
SPECIAL_NET_CONNECTIVITY_BAD=1
```

The remaining signal DRCs were concentrated in two classes:

- RO fast-code routing at `u_core_u_osc_fast_u_ro_tune4`, especially
  `u_core_ro_fast_code_q[*]`.
- A small set of regular signal routes shorting special VDD/VSS routes, plus
  one MET1 minimum-area marker.

Broad `routeDesign` and `ecoRoute -fix_drc` were not sufficient.

### `20260701_mptdc_route_ckpt_repair_ro_residual_160423`

Deleting the exact offending regular nets proved that the routed shapes, not
the base placement, were causing the geometry failure:

```text
COMMAND_7_VERIFY_DRC=0
COMMAND_7_VERIFY_SHORTS=0
```

However, rerunning broad routing from that state was counterproductive:

```text
routeDesign -> 12 DRC / 8 shorts
ecoRoute -fix_drc -> 7 DRC / 4 shorts
```

That run also moved the RO fast-code problem to nearby code bits, so full
reroute is not a controlled repair path.

### `20260701_mptdc_route_ckpt_delete_probe_161359`

This is the best known checkpoint:

```text
FINAL_DRC=0
FINAL_SHORTS=0
FINAL_DRC_STATUS=PASS
FINAL_REGULAR_CONNECTIVITY_BAD=1
FINAL_SPECIAL_CONNECTIVITY_BAD=1
CHECKPOINT_REPAIR_STATUS=PASS_GEOMETRY_REVIEW_CONNECTIVITY
```

The remaining regular connectivity violations are exactly seven unrouted nets:

```text
CTS_6
u_core_ro_fast_code_q[7]
u_core_ro_fast_code_q[6]
u_core_ro_fast_code_q[0]
u_core_n_57562
u_core_n_64592
u_core_gen_pd_row[1].gen_pd_col[1].u_pd/q1
```

The remaining special connectivity violation is VDD/VSS dangling wire evidence:

```text
Net VDD: dangling Wire.
Net VSS: dangling Wire.
32 Problem(s) (IMPVFC-94): The net has dangling wire(s).
```

This should be treated separately from signal geometry and regular-net
connectivity repair.

### `20260701_mptdc_route_ckpt_selected_via_pin_162321`

This run is invalid as route evidence. It exposed two harness/command issues:

1. `selectNet` accepts one net argument per call. The attempted multi-argument
   `selectNet {a} {b} ...` failed, so no nets were selected.
2. `setNanoRouteMode -route_with_via_in_pin true` immediately generated
   `1000` MET1 `Via_In_Pin` violations on the existing design. This option must
   not be used for this checkpoint repair.

### `20260701_mptdc_route_ckpt_split_guard_163330`

This run also did not route anything. It failed before command 1 because the
repair harness appended `>> report` to the Tcl helper command:

```text
CHECKPOINT_REPAIR_STATUS=FAIL_COMMAND
CHECKPOINT_REPAIR_FAILED_COMMAND_INDEX=1
CHECKPOINT_REPAIR_FAILED_COMMAND_ERROR=wrong # args: should be "mptdc_ckpt_route_selected_nets nets"
```

The final checkpoint stayed geometry clean:

```text
FINAL_DRC=0
FINAL_SHORTS=0
FINAL_DRC_STATUS=PASS
```

The harness was then fixed so `mptdc_ckpt_*` helper commands execute directly
instead of receiving Innovus-style `>> report` redirection as extra Tcl
arguments.

## Harness Rules After This Escalation

- Do not use `setNanoRouteMode -route_with_via_in_pin true`.
- Do not use broad `routeDesign` from the DRC-clean delete checkpoint.
- Route selected nets through `mptdc_ckpt_route_selected_nets`.
- Check geometry immediately with `mptdc_ckpt_assert_geometry_clean`.
- Fail fast on command errors unless `MPTDC_CHECKPOINT_REPAIR_KEEP_GOING=1` is
  explicitly set for exploratory runs.
- Treat fresh `verify_drc` as authoritative over stale saved marker counts.

## Next Acceptance Criteria

The next useful checkpoint must satisfy:

```text
FINAL_DRC=0
FINAL_SHORTS=0
FINAL_REGULAR_CONNECTIVITY_BAD=0
```

If `FINAL_SPECIAL_CONNECTIVITY_BAD=1` remains only because of bounded
`IMPVFC-94` VDD/VSS dangling-wire reports, handle that as a PG policy or PG
cleanup item after regular signal connectivity is restored.
