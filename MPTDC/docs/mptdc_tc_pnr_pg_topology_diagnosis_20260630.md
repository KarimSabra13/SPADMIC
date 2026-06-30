# MPTDC TC PnR PG Topology Diagnosis - 2026-06-30

## Scope

This note records the power-grid failure observed in:

- Run: `/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_defer_preroute_sroute_v1`
- Checkpoint inspected: `checkpoints/04_route_failed.enc.dat`
- DEF inspected: `def/04_route_failed.def`

The issue is a PG topology construction failure, not a timing-closure result.
Timing reports are missing because the route gate stops first.

## Findings

The failed run created eight top-level PG pins:

- `VDD_LEFT`, `VSS_LEFT`, `VDD_RIGHT`, `VSS_RIGHT` on `METTP`
- `VDD_TOP`, `VSS_TOP`, `VDD_BOTTOM`, `VSS_BOTTOM` on `MET3`

Those pins were large slab geometries. For example, the horizontal left/right
pins were 44 um wide and crossed the core boundary deeply enough to overlap
adjacent VDD/VSS ring rails. The vertical top/bottom pins were also 44 um long
and crossed nearby horizontal rails. Geometry markers confirmed actual VDD/VSS
shorts at the PG pin locations, including `METTP` shorts near the right-side
rails and `MET3` shorts near the top-side rails.

The pre-place sroute step also created partial special routing before standard
cell placement was complete. It reported nonzero open ports, and post-place
sroute then preserved or inherited the bad topology instead of repairing it.

## Implemented Direction

The flow now defaults to a mesh-aligned block PG pin style:

- `MPTDC_BLOCK_PG_PIN_STYLE=mesh_intersection_vdd_vss`
- `MPTDC_ENABLE_PREPLACE_PG_SROUTE=0`
- `MPTDC_ENABLE_BLOCK_PG_STITCH_STRIPES=0`
- `MPTDC_REQUIRE_POSTPLACE_PRE_ROUTE_SROUTE_CLEAN=1`
- `MPTDC_ENABLE_FINAL_FILLER=0`

Mesh-aligned PG pins are compact rectangles placed at same-net ring and stripe
intersections. They use the same default ring and stripe parameters as the PG
grid commands:

- ring width 2 um, spacing 1 um, offset 2 um
- stripe width 2 um, spacing 2 um, pitch 80 um, start offset 20 um

This avoids spanning the adjacent opposite-net rail while preserving external
VDD/VSS pins on all four sides.

## Next Gate

The next server run should stop at `postplace_pre_route_sroute_status.rpt` if
special PG connectivity is still not clean. The key reports to inspect are:

- `reports/block_pg_pin_status.rpt`
- `reports/postplace_pre_route_pg_topology_before_sroute.rpt`
- `reports/postplace_pre_route_pg_topology_after_sroute.rpt`
- `reports/postplace_pre_route_verify_connectivity_special.rpt`
- `reports/route_status.rpt` if the postplace gate passes

Do not interpret later missing timing reports as timing failures until this PG
gate has passed.
