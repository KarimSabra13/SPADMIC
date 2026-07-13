# Innovus 22.33 PG Routing Command Notes

Status: verified from the installed server command manuals on 2026-07-10.

Evidence root:

```text
/sim/ksabra/SPADMIC_work/diagnostics/innovus_pg_command_help_20260710_151605
```

The running tool is Innovus 22.33-s094_1. Its installed command pages identify
the documented command set as Product Version 22.13.

## addStripe

`addStripe` supports both `-area` and `-extend_to design_boundary`, but these
options are mutually exclusive. It also supports `-create_pins`,
`-start_offset`, `-stop_offset`, and `-number_of_sets`.

Important offset rule: without an explicit area, `-start_offset` is measured
from the applicable core/region reference. In the first TX DDR strip PG run,
the intended center was used as if the origin were zero. The core-left value
`10.080 um` was therefore added a second time and both stripes shifted east by
exactly `10.080 um`.

Use `addStripe` when power-planner distribution, ring extension, or repeated
stripe sets are intended. For one exact handoff stripe, explicit special-net
geometry is easier to audit.

## add_shape

The canonical batch command is `add_shape`; the camel-case `addShape` help
entry was empty in this installation.

Verified syntax:

```tcl
add_shape \
  -net VDD \
  -layer METTP \
  -shape STRIPE \
  -status ROUTED \
  -pathSeg {858.480 10.080 858.480 180.880} \
  -width 3.360
```

`add_shape` adds DEF `SPECIALNETS` geometry and supports `-rect`, `-patch`,
`-polygon`, or `-pathSeg` plus width and end extensions. It is selected for
TX DDR strip P02-R2 because the marker-derived stripe centerlines and endpoints
must be exact and reproducible.

## sroute

The verified connection classes include `corePin`, `blockPin`, `padPin`,
`padRing`, `floatingStripe`, and `secondaryPowerPin`.

The TX DDR strip boundary VDD/VSS terminals are top-level PG terminals, not
hierarchical block pins. The failed command requested `blockPin` and Innovus
reported that no VDD/VSS block pins existed. P02-R2 therefore makes the stripe
itself overlap each boundary PG terminal and asks `sroute` only for standard
cell rail stitching:

```tcl
sroute \
  -connect {corePin} \
  -nets {VDD VSS} \
  -corePinTarget stripe \
  -corePinCheckStdcellGeoms \
  -allowJogging 1 \
  -allowLayerChange 1 \
  -layerChangeRange {MET1 METTP}
```

`-corePinCheckStdcellGeoms` directs the tool to check standard-cell geometry
around rail-to-stripe vias. It is required because the first run omitted two
VDD via stacks.

Command completion is never the acceptance gate. Always run detailed special
connectivity, regular connectivity, and DRC afterward.

## editAddRoute

`editAddRoute` is a Wire Editor command. It relies on `uiSetTool`,
`setEditMode`, successive points, and `editCommitRoute`. It is appropriate for
an interactive, reviewed repair but is not selected for the automated P02-R2
flow because its stateful editing context is harder to reproduce and audit.

## TX DDR Strip P02-R2 Geometry

```text
die box  = 0.000,0.000 -> 3433.360,180.880
core box = 10.080,10.080 -> 3423.280,170.800

VDD stripe center = 858.480
VDD stripe y range = 10.080 -> 180.880

VSS stripe center = 2574.880
VSS stripe y range = 14.560 -> 180.880

stripe layer = METTP
stripe width = 3.360
```

P02-R2 restores the clean P01 checkpoint. It must not restore the failed P02
checkpoint and must not run placement, CTS, or signal routing.

P02-R2 closed VSS and the north PG terminals but left two isolated VDD
followpin rows. The local repair therefore adds a bounded VDD helper stripe:

```text
helper y range = 126.560 -> 153.440 um
isolated rows  = 135.520, 144.480 um
anchor rows    = 126.560, 153.440 um
```

The helper is not a full-height power trunk. It is a local METTP jumper whose
endpoints coincide with already-connected VDD rows. Only a zero-PG,
zero-regular-connectivity, zero-DRC candidate can enter a canonical replay.

## restoreDesign Process Isolation

Innovus 22.33 rejects a second `restoreDesign` in the same process with
`IMPIMEX-7031`. P02-R3 exposed this guard before any helper candidate was
created. Its saved `02_core_pin_stitched.enc.dat` checkpoint was complete, but
all ten candidate rows were `RESTORE_FAIL`; this was an orchestration failure,
not evidence that the candidate geometries failed electrically.

Do not set `restore_db_stop_at_design_in_memory` to bypass the guard. P02-R4
uses this process contract instead:

1. Launch a fresh Innovus process for one candidate X.
2. Restore the clean P01 signal checkpoint exactly once.
3. Recreate the exact main VDD/VSS geometry and verify the known three-marker
   VDD residual.
4. Add one local VDD helper, then require special connectivity, regular
   connectivity, and DRC all to report zero.
5. Emit no GDS, LEF, DEF, netlist, or reusable checkpoint from a trial.
6. After a clean trial, launch another fresh Innovus process and replay the same
   candidate from P01 before canonical export and GDS audit.

The wrapper records this as
`PROCESS_ISOLATION=ONE_INNOVUS_PROCESS_PER_CANDIDATE`. A failed or interrupted
trial remains diagnostic evidence under its own immutable `trials/` directory.

P02-R4 proved that this process architecture works, but rejected the local
helper method itself. All ten candidate X coordinates were evaluated in fresh
processes and all produced the same result:

```text
PG_CONNECTIVITY_VIOLATION_COUNT=6
PG_MARKER_COUNT=6
REGULAR_CONNECTIVITY_VIOLATION_COUNT=0
DRC_MARKER_TOTAL=0
```

This is negative knowledge with a clear reuse rule: do not test more X values
with the same bounded `add_shape` plus local second `sroute` sequence. The
invariance across `x=298.480..1418.480 um` points to a method/topology problem,
not candidate placement. Exact marker decomposition remains required before a
different repair is selected.

The complete command, error, and anti-pattern ledger is maintained in
`TOP/docs/35_INNOVUS_PG_DEBUGGING_PLAYBOOK_AND_FAILURE_LEDGER.md`.

## Required Gates

- PG-term centers read from the restored DB, not fallback values.
- Clean source checkpoint with zero pre-existing VDD/VSS special wires.
- Exact die/core geometry guard.
- Special connectivity: zero violations and zero markers.
- Regular connectivity: zero violations.
- Innovus DRC: zero violations.
- Official XFAB stream map: PASS.
- JIHD standard-cell GDS merge: PASS.
- PVS DRC/LVS remain independent later gates.

## Canonical Clean-Rebuild Strategy

Status: implemented in Git; Innovus server validation pending.

The restore-only R1-R4 experiments remain valid negative evidence, but they no
longer define the packet/strip implementation path. The canonical path starts
from fresh RTL and Genus netlists. For `tx_packet_core` and `tx_ddr_strip`, the
generated OOC configuration selects:

```tcl
enable_pg_sroute = 1
pg_route_strategy = explicit_exact
route_profile = met1_effort
```

`spadmic_ooc_create_pg_pins` and `spadmic_ooc_create_pg_straps` now call the
same `spadmic_ooc_pg_pin_centers` function. The main stripes therefore use the
same snapped X as the north VDD/VSS terminal:

```tcl
add_shape -net <VDD-or-VSS> -layer METTP -shape STRIPE -status ROUTED \
  -pathSeg {<pin_center_x> <first_rail_y> <pin_center_x> <die_top_y>} \
  -width <configured_width>
```

VDD begins on the first VDD followpin row at the core lower edge. VSS begins
one half-row later; the JIHD default offset is `4.48 um`. Both end at the die
top, overlapping their generated PG terminal. `sroute` then requests only
`corePin` stitching. PG is created before ordinary signal routing so NanoRoute
sees the METTP power geometry rather than routing signals first and inserting
PG afterward.

The legacy `addStripe` branch is retained for other blocks, but its formula is
corrected to account for the core reference:

```text
start_offset = desired_center_x - core_left - stripe_width / 2
```

Do not simplify this back to `desired_center_x - stripe_width / 2`; that was
the exact R1 coordinate bug. Do not add `-extend_to design_boundary` together
with `-area`; installed help says those options are mutually exclusive.

The mapped GDS export now appends both:

```text
-mapFile <official-XH018-pnr_streamout.map>
-merge <xh018_D_CELLS_JIHD.gds>
```

The shell wrapper runs `audit_innovus_gds_export.py --required-merge` and will
not report `ABSTRACT_READY_FOR_TOP_REVIEW` unless that audit passes. This
prevents the earlier LEF-only/small-GDS ambiguity from reaching PVS.

This implementation is not a PG pass claim. Server acceptance still requires
zero detailed special-connectivity violations and markers, zero regular
connectivity violations, and zero Innovus DRC markers. If a fresh rebuild
reproduces isolated VDD rows, capture the exact row/via markers from that fresh
run; do not resume the coordinate-invariant R4 helper sweep.

## editPowerVia Trial Discipline

The repository has exercised this Innovus 22.33 syntax successfully at command
level:

```tcl
editPowerVia -add_vias 1 -nets {VDD} \
  -bottom_layer MET1 -top_layer MET2 \
  -area {<llx> <lly> <urx> <ury>}
```

The installed manual adds two constraints that must govern a bounded packet
trial:

```tcl
setViaGenMode -area_only 1
editPowerVia -add_vias 1 -nets {VDD} \
  -bottom_layer MET1 -top_layer METTP \
  -exclude_stack_vias 0 \
  -area {<llx> <lly> <urx> <ury>}
```

`-area_only 1` prevents generation outside the supplied windows.
`-exclude_stack_vias 0` permits the non-adjacent stack between the existing
MET1 rail and METTP stripe. This is the correct `via-only` hypothesis because
the packet probe has zero VDD MET2 and MET3 SWIREs.

Negative evidence is equally important: an older MPTDC run recorded all
`editPowerVia` construction commands as PASS and still failed raw special
connectivity. Therefore do not add this command directly to the canonical TX
flow. Test one restored in-memory candidate, save/export nothing, and require
the post-command connectivity report to reach zero.

The earlier MPTDC method issued adjacent-layer commands even when intermediate
special wires were not proven. Those commands returned PASS while downstream
connectivity remained broken. Do not repeat them as the packet `via-only`
method. Reserve adjacent pairs for `patch-stack`, where bounded MET2/MET3
special-net patches are created first with verified `add_shape -rect` syntax.
Each mode must use a separate process and the same immutable source checkpoint.
Never run patch-stack after via-only in the same loaded design because the
result would not identify which method changed connectivity.

## Direct Stack Trial Result

The bounded direct stack is command-valid and topology-effective, but it is
not physically acceptable in its default generated form:

```text
COMMAND_PASS_COUNT=4
COMMAND_FAIL_COUNT=0
SPECIAL_CONNECTIVITY=4 -> 0
REGULAR_CONNECTIVITY=0 -> 0
INNOVUS_DRC=7 -> 25
```

The 18 added violations are `MET2 Short=6`, `MET2 MetSpc=2`,
`VIA2 CShort=3`, `VIA2 CutSpc=1`, and `MET3 Short=6`. This proves that
`editPowerVia -exclude_stack_vias 0` can create the required electrical
topology while selecting an intermediate stack geometry that collides with the
routed design. A zero command RC is therefore capability evidence only.

Do not run the existing patch-stack fallback from this result. MET2 and MET3
are already the short-bearing layers, and the direct method already closes all
special connectivity. First replay the same method once in a fresh process
with immediate pre/post `top.markers` dumps. Review exact boxes, messages, and
row attribution before considering constrained cut count, one row at a time,
or a reviewed single-via construction. Save/export and PVS remain prohibited
during this diagnosis.
