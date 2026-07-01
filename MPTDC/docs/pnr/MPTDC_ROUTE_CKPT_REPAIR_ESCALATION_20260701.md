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

### `20260701_mptdc_route_ckpt_split_guard2_163854`

This run proves that the helper dispatch is fixed and selected-net routing is
actually executing. The first command routed `CTS_6` from the DRC-clean delete
checkpoint:

```text
MPTDC_CKPT_SELECTED_NETS=CTS_6
MPTDC_CKPT_ROUTE_SELECTED_NET_COUNT=1
```

However, the immediate geometry guard failed:

```text
COMMAND_1_STATUS=PASS
COMMAND_1_VERIFY_DRC=2
COMMAND_1_VERIFY_SHORTS=1
COMMAND_1_VERIFY_REGULAR_CONNECTIVITY_BAD=1
CHECKPOINT_REPAIR_FAILED_COMMAND_INDEX=2
CHECKPOINT_REPAIR_FAILED_COMMAND_ERROR=geometry is not clean after checkpoint repair command: DRC=2 SHORTS=1
```

The actual marker dump shows a single bad MET2 patch:

```text
MET2 Metal_Short Regular Wire of Net CTS_6 & Special Wire of Net VDD
  box {54.46 197.35 54.74 197.73}
MET2 Minimal_Area Regular Wire of Net CTS_6
  Actual: 0.10640000 Required: 0.20200000
```

This is not a wrapper failure. It means the default selected-net strategy
`globalDetailRoute -select; detailRoute -select` is not safe for `CTS_6`.
The route-design selected-net strategy reproduced the same failure:

```text
20260701_mptdc_route_ckpt_cts_route_design_164800
COMMAND_1_STATUS=PASS
COMMAND_1_VERIFY_DRC=2
COMMAND_1_VERIFY_SHORTS=1
```

The other two selected-net probes did not produce useful CTS routing:

```text
20260701_mptdc_route_ckpt_cts_detail_only_165032
COMMAND_1_STATUS=FAIL
FINAL_DRC=0
FINAL_SHORTS=0
regular connectivity still reports CTS_6 plus the six other no-routing nets

20260701_mptdc_route_ckpt_cts_legacy_165158
CHECKPOINT_REPAIR_FAILED_COMMAND_ERROR=selected-net route failed: invalid command name "routeSelectedNet"
```

The next useful steps are therefore:

1. Route the six non-`CTS_6` residual regular nets from the clean source
   checkpoint to see whether regular signal connectivity can be reduced to only
   the clock-tree net.
2. Route `CTS_6` with one of the working selected-net engines and surgically
   trim only the bad MET2 regular patch at `{54.46 197.35 54.74 197.73}`.
3. If trimming leaves `CTS_6` connected and geometry-clean, combine the six
   non-CTS route commands plus the CTS trim into one final checkpoint and run
   post-route extraction/timing reports from that checkpoint.
4. If trimming leaves `CTS_6` unrouted, stop automatic routing and make a
   manual/clock-specific route around that VDD stripe; broad `routeDesign` is
   already proven counterproductive.

### `20260701_mptdc_route_ckpt_noncts_all_165944`

This run routed the six non-`CTS_6` residual signal nets together from the
DRC-clean source checkpoint:

```text
u_core_n_64592
u_core_gen_pd_row[1].gen_pd_col[1].u_pd/q1
u_core_n_57562
u_core_ro_fast_code_q[0]
u_core_ro_fast_code_q[6]
u_core_ro_fast_code_q[7]
```

The batch route succeeded from a command perspective and reduced regular
connectivity to only `CTS_6`, but it was not geometry-clean:

```text
COMMAND_1_STATUS=PASS
COMMAND_1_VERIFY_DRC=9
COMMAND_1_VERIFY_SHORTS=5
COMMAND_1_VERIFY_REGULAR_CONNECTIVITY_BAD=1
COMMAND_1_VERIFY_REGULAR_CONNECTIVITY_BAD_LINES={Net CTS_6: no routing.}

FINAL_DRC=9
FINAL_SHORTS=5
FINAL_DRC_STATUS=FAIL
CHECKPOINT_REPAIR_STATUS=FAIL_COMMAND
CHECKPOINT_REPAIR_FAILED_COMMAND_INDEX=2
CHECKPOINT_REPAIR_FAILED_COMMAND_ERROR=geometry is not clean after checkpoint repair command: DRC=9 SHORTS=5
```

Interpretation:

- Routing the six nets together fixes their open regular connectivity.
- The combined route recreates a geometry class similar to the original failed
  route state, including `5` shorts.
- The six-net batch is therefore not an acceptable route-clean repair, but it
  is useful evidence that the unresolved regular connectivity is routable if
  physical DRC is temporarily ignored.
- The next controlled route repair must isolate which individual nets are clean
  and which nets require local manual cleanup.

### Latest Single-Net Non-CTS Probes

The single-net probes were run from the DRC-clean source checkpoint with:

```tcl
mptdc_ckpt_route_selected_nets {<net>}
mptdc_ckpt_assert_geometry_clean
```

The guard result is authoritative. `INNOVUS_RC=0` only means Innovus exited;
it does not mean the route is clean.

| Net | Run ID | Final DRC / Shorts | Connectivity effect | Status | Analysis |
| --- | --- | --- | --- | --- | --- |
| `u_core_ro_fast_code_q[0]` | `20260701_mptdc_route_ckpt_single_u_core_ro_fast_code_q_0___171829` | `0 / 0` | Removed this net from the no-routing list; six other residual nets remained. | Clean single-net route | This net can be included in a route-clean candidate. |
| `u_core_ro_fast_code_q[6]` | `20260701_mptdc_route_ckpt_single_u_core_ro_fast_code_q_6___172000` | `0 / 0` | Removed this net from the no-routing list; six other residual nets remained. | Clean single-net route | This net can be included in a route-clean candidate. |
| `u_core_ro_fast_code_q[7]` | `20260701_mptdc_route_ckpt_single_u_core_ro_fast_code_q_7___172133` | `0 / 0` | Removed this net from the no-routing list; six other residual nets remained. | Clean single-net route | This net can be included in a route-clean candidate. |
| `u_core_gen_pd_row[1].gen_pd_col[1].u_pd/q1` | `20260701_mptdc_route_ckpt_single_u_core_gen_pd_row_1__gen_pd_col_1__u_pd_q1__171227` | `1 / 1` | Removed this net from the no-routing list; six other residual nets remained. | Dirty single-net route | This net is routable but creates one short. It is not clean enough for final route closure; it can be used in a timing-only dirty checkpoint. |
| `u_core_n_57562` | `20260701_mptdc_route_ckpt_single_u_core_n_57562__171659` | `1 / 0` | Removed this net from the no-routing list; six other residual nets remained. | Dirty single-net route | This net is routable but creates one non-short DRC. It is not clean enough for final route closure; it can be used in a timing-only dirty checkpoint. |
| `u_core_n_64592` | Not present in pasted single-net evidence | Unknown | Unknown from the pasted single-net logs. | Needs rerun or pasted result | The six-net batch proves it can be routed as part of the group, but its individual DRC behavior is not documented yet. Treat it as suspect until its single-net probe is captured. |

The clean subset from the pasted single-net data is therefore:

```text
u_core_ro_fast_code_q[0]
u_core_ro_fast_code_q[6]
u_core_ro_fast_code_q[7]
```

The dirty-but-routable subset from the pasted single-net data is:

```text
u_core_gen_pd_row[1].gen_pd_col[1].u_pd/q1
u_core_n_57562
```

The unclassified single-net result is:

```text
u_core_n_64592
```

### Latest CTS_6 Probes

The following CTS probes confirm that automatic selected-net routing connects
`CTS_6`, but it still produces the same physical DRC class.

#### `20260701_mptdc_route_ckpt_cts_reverse_box_172315`

This probe attempted to bias routing around the bad MET2 short area with:

```tcl
setNanoRouteMode -route_reverse_direction {54.0 196.8 55.2 198.2 MET1:MET3}
mptdc_ckpt_route_selected_nets_route_design {CTS_6}
setNanoRouteMode -route_reverse_direction {}
mptdc_ckpt_assert_geometry_clean
```

Result:

```text
COMMAND_1_STATUS=PASS
COMMAND_1_VERIFY_DRC=0
COMMAND_1_VERIFY_SHORTS=0

COMMAND_2_STATUS=PASS
COMMAND_2_VERIFY_DRC=2
COMMAND_2_VERIFY_SHORTS=1
COMMAND_2_VERIFY_REGULAR_CONNECTIVITY_BAD_LINES={Net u_core_ro_fast_code_q[7]: no routing.} ... {6 Problem(s) ...}

FINAL_DRC=2
FINAL_SHORTS=1
CHECKPOINT_REPAIR_STATUS=FAIL_COMMAND
CHECKPOINT_REPAIR_FAILED_COMMAND_INDEX=4
```

Interpretation:

- The reverse-direction route mode was accepted by Innovus.
- It did not change the CTS failure mode enough to clear geometry.
- `CTS_6` disappeared from the regular no-routing list after command 2, so it
  was routed/connected, but the route remained dirty.

#### `20260701_mptdc_route_ckpt_cts_direct_area_wire_172518`

This probe attempted to route `CTS_6`, then delete only the MET2 regular wire
inside the known bad area:

```tcl
mptdc_ckpt_route_selected_nets_route_design {CTS_6}
editDelete -area {54.40 197.30 54.80 197.80} -net CTS_6 -layer MET2 -object_type Wire -type Regular
mptdc_ckpt_assert_geometry_clean
```

Result:

```text
COMMAND_1_STATUS=PASS
COMMAND_1_VERIFY_DRC=2
COMMAND_1_VERIFY_SHORTS=1

COMMAND_2_STATUS=PASS
COMMAND_2_VERIFY_DRC=2
COMMAND_2_VERIFY_SHORTS=1

FINAL_DRC=2
FINAL_SHORTS=1
CHECKPOINT_REPAIR_STATUS=FAIL_COMMAND
CHECKPOINT_REPAIR_FAILED_COMMAND_INDEX=3
```

Interpretation:

- The local `editDelete` command was accepted but did not remove the offending
  geometry class.
- The DRC marker is probably associated with a via, a patch/trim shape, a
  slightly different object type, or a regular shape that overlaps the marker
  but is not removed by `-object_type Wire`.
- `CTS_6` again disappears from the regular no-routing list after routing, so
  automatic selected routing connects it, but it is not final-clean.

### Temporary Timing-Only Strategy

At this point there are two different goals:

1. Final signoff route closure.
2. Fast timing closure data.

The data does not support waiving these DRCs for final GDS/signoff:

- `CTS_6` has a real MET2 short to `VDD`.
- `u_core_gen_pd_row[1].gen_pd_col[1].u_pd/q1` creates one short when routed.
- `u_core_n_57562` creates one non-short DRC when routed.
- `u_core_n_64592` still lacks captured single-net evidence.

However, the data does support creating a dirty full-connectivity checkpoint for
timing optimization only. The dirty checkpoint is useful because all residual
regular nets can be made routable, and STA can then evaluate a more complete
post-route RC/timing state. It must be labeled explicitly:

```text
DIRTY ROUTE TIMING CANDIDATE ONLY
NOT GDS CLEAN
NOT FINAL SIGNOFF CLEAN
DRC WAIVED ONLY TO UNBLOCK STA/OPTIMIZATION
```

The recommended dirty timing candidate sequence is:

```tcl
mptdc_ckpt_route_selected_nets {u_core_ro_fast_code_q[0]}
mptdc_ckpt_route_selected_nets {u_core_ro_fast_code_q[6]}
mptdc_ckpt_route_selected_nets {u_core_ro_fast_code_q[7]}
mptdc_ckpt_route_selected_nets {u_core_n_64592}
mptdc_ckpt_route_selected_nets {u_core_gen_pd_row[1].gen_pd_col[1].u_pd/q1}
mptdc_ckpt_route_selected_nets {u_core_n_57562}
mptdc_ckpt_route_selected_nets_route_design {CTS_6}
extractRC
timeDesign -postRoute
timeDesign -postRoute -hold
optDesign -postRoute -setup
timeDesign -postRoute
optDesign -postRoute -hold
timeDesign -postRoute -hold
report_timing -view TC_NOMINAL -max_paths 100
report_timing -view TC_NOMINAL -check_type hold -max_paths 100
```

Use `MPTDC_CHECKPOINT_REPAIR_KEEP_GOING=1` only for this timing-only run, so
the wrapper saves reports and the resulting checkpoint even though geometry is
known dirty.

Acceptance for this timing-only checkpoint is not route signoff. It is:

```text
FINAL_REGULAR_CONNECTIVITY_BAD=0
timing setup/hold reports generated
dirty DRC count explicitly recorded
```

After timing is closed, the remaining mandatory pre-GDS work is:

- Rerun or capture the single-net result for `u_core_n_64592`.
- Manually repair `CTS_6` around the MET2 VDD stripe at
  `{54.46 197.35 54.74 197.73}`.
- Manually repair or reroute
  `u_core_gen_pd_row[1].gen_pd_col[1].u_pd/q1`.
- Manually repair or reroute `u_core_n_57562`.
- Re-run fresh `verify_drc` and `verifyConnectivity -type regular`.
- Address or formally classify the remaining VDD/VSS special dangling-wire
  evidence before final signoff packaging.

## Harness Rules After This Escalation

- Do not use `setNanoRouteMode -route_with_via_in_pin true`.
- Do not use broad `routeDesign` from the DRC-clean delete checkpoint.
- Route selected nets through `mptdc_ckpt_route_selected_nets`.
- If the default selected-net route is not clean, use the alternate helper
  probes `mptdc_ckpt_route_selected_nets_route_design`,
  `mptdc_ckpt_route_selected_nets_detail_only`, or
  `mptdc_ckpt_route_selected_nets_legacy` from the clean source checkpoint.
- For marker-local edits, use `mptdc_ckpt_delete_regular_net_area` or
  `mptdc_ckpt_delete_regular_drc_wires`, then require
  `mptdc_ckpt_assert_geometry_regular_clean` before timing reports.
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
