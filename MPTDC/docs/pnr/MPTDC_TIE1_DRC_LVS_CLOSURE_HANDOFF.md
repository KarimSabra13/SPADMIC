# MPTDC Tie1 DRC/LVS Closure Handoff

Author: Karim Sabra

Status: active execution checkpoint for `mptdc_axis_core`

Last evidence review: 2026-09-01

## Decision

The V13 minimum-area repair is accepted for continued closure. It passed once
as an isolated trial and passed again as a canonical replay from the immutable
pre-repair Tie1 checkpoint. The replay is the only accepted continuation
checkpoint.

PG analysis has now produced five published diagnostics against that exact
replay:

- the first RO ring probe failed topology preflight because its point parser did
  not normalize the live wrapped `.pts` encoding; it made no source mutation;
- the corrected RO ring probe proved the `15 markers / 13 handles / 2 shared`
  source topology, but its generated rings caused 97 DRC violations and 67
  shorts, so its checkpoint is rejected;
- long-prune V1 proved source deletions 1 through 11 with DRC `0`, shorts `0`,
  and regular connectivity `0`, then stopped when source deletion 12 replaced a
  VSS/METTP marker with a previously covered VSS/MET1 marker;
- long-prune V2 accepted that exact first transition and completed all 13 source
  deletions, but deletion 13 exposed a second historical VSS/MET1 corewire.
  Its final two markers are both MET1 while DRC, shorts, and regular
  connectivity remain `0`, so the candidate is rejected;
- long-prune V3 accepted both exact marker transitions and proved all 13 source
  deletions, but the source sWire inventory changed from `450/419` to `445/411`
  and the PG via-handle inventory changed from `4575/4524` to `4412/4197`.
  Deleting the 13 full sWire objects therefore removed 490 associated via
  handles. The two residual MET1 endpoints remained, and no residual object
  was deleted. V3 is rejected.

No PG-mutated candidate has therefore been accepted. The accepted continuation
source remains the V13 replay, never a rejected diagnostic checkpoint. Full
sWire-handle long-prune trial and replay are retired. A long-prune report or
checkpoint is not PVS-eligible even if DRC and regular connectivity are zero.

The next action is one read-only endpoint-anchor probe from V13. It inventories
the retained same-net anchors, opposite-net conflicts, PG vias, and PG terminal
shapes at both ends of every source object. It classifies each of the 15
markers as `TRIM_FEASIBLE`, `STITCH_FEASIBLE`, or `BLOCKED`, records every
predicate and ambiguity, and issues zero PG mutation commands. Its saved
checkpoint is analysis-only, must remain `NOT_SELECTED`, and must not feed PVS.

The current state label is:

```text
MPTDC_TIE1_V13_INNOVUS_DRC_CLEAN_PG15_OPEN_LVS_MISMATCH
```

This label is intentionally not a signoff claim. Fresh Innovus geometry DRC,
short, regular-connectivity, and route checks pass. Raw special-PG connectivity
on the accepted source still reports 15 dangling VDD/VSS endpoints. The best
rejected diagnostic state has two endpoints, but it cannot be promoted. The
last attributable PVS run predates V13, classified all 136 base-DRC results as
antenna rules, and reported an explicit LVS mismatch. Density DRC, timing
requalification, and final streamout qualification are not complete.

Process-antenna repair is outside this closure scope. Antenna results remain
visible as deferred debt; they are not deleted, waived, or relabelled clean.

## Accepted Evidence Lineage

| Role | Run or commit | Decision-bearing identity |
| --- | --- | --- |
| Immutable Tie1 source | `20260831_mptdc_tie1_filler_ecoroute_reconciled_131006` | checkpoint SHA-256 `a8ed5b0b684c0543ddd4e0a6d7dac96b82203f3e7319c443a04d003075d2d1c8` |
| V13 isolated trial | `20260831_174738_mptdc_tie1_minarea_clearance_v13_trial` | evidence commit `072d059645438fff54afbd81bd8f7cbd859e5497`; candidate SHA-256 `aebd16c6dd07605cb41329d3f3f3464b98e8a82f35b8b7fe747131f88e9a39d0` |
| V13 canonical replay | `20260831_175532_mptdc_tie1_minarea_clearance_v13_replay` | evidence commit `b61dfd1a6c476aa41cab43735a28199fa164bc05`; candidate SHA-256 `35fec60377b4fc7c08b83bf550ef457f7bdb3aa69580d8a749feb7a66fa4a7bf` |
| First ring probe, parser failure | `20260901_115029_mptdc_tie1_pg_ro_ring_probe` | evidence commit `aa67bbcf4ba93baed225bd405634429f04b7cccd`; no source mutation; candidate `NOT_SELECTED` |
| Corrected ring probe, physical rejection | `20260901_122444_mptdc_tie1_pg_ro_ring_probe_v2` | evidence commit `d39c8f8b036f92994dea7b7494187ae864c89bf1`; candidate SHA-256 `13b98185ecd7237485762693a82c2ce38188e937a13eebf05f8bf6c4a81fd1a8`; `NOT_SELECTED` |
| Long-prune V1 diagnostic | `20260901_124659_mptdc_tie1_pg_long_prune_trial` | evidence commit `a0647b4f9666ead66fb10f89369144490b397c25`; candidate SHA-256 `0ac03ded6be501c21f5e26885d98e3c5f90a0408c8ca652fdcd832875ad766f8`; `NOT_SELECTED` |
| Long-prune V2 diagnostic | `20260901_131741_mptdc_tie1_pg_long_prune_v2_trial` | evidence commit `2d7cd791ea723b4a215e8422dfb62d7ebf4d0ec3`; candidate SHA-256 `4d2c2b9f19882bae2bec90e92fd6b3bdc4b4d4d2cba17c71797687c90e1daa3f`; `NOT_SELECTED` |
| Long-prune V3 diagnostic | `20260901_141910_mptdc_tie1_pg_long_prune_v3_trial` | evidence commit `d142b547df8df454476dbd3409d6b72010752783`; candidate SHA-256 `1297f79a2f3e19294074256fb92182aec7c1ad2bce2109b9ec5cd4c885ab97a4`; source prune `13/13`; PG via inventory changed by `-490`; `NOT_SELECTED` |
| Prior PVS diagnostic | `20260831_mptdc_tie1_lvs_density_131326` | base DRC `136`, antenna-only classification, LVS `MISMATCH`; predates V13 |
| Historical PG topology witness | `20260825_mptdc_bufftap0_halo10_physical_130313` | identifies the 13 source handles and both exact exposed VSS/MET1 corewires |
| Proven RO ring primitive | `20260828_mptdc_free_pnr_stripevaluefix_151756_u50` | two RO rings, 16 new `blockRing` sWires, VDD delta `+8`, VSS delta `+8` |
| Standalone RO LVS proof | `20260827_mptdc_ro6_standalone_lvs_vddfix_150520` | explicit `MATCH`, zero blackboxes, immutable RO GDS/CDL hashes |

The replay restored the original Tie1 source checkpoint, not the trial output,
then reapplied the exact V13 operation in one fresh Innovus process. This is why
the different trial and replay candidate hashes are expected: each saved
database is a separate run product, while the source hash, edit contract, object
delta, and verification tuple agree. V1, V2, and V3 are rejected ancestry
evidence only. None is a legal source checkpoint for a later Innovus or PVS
stage.

Primary evidence:

- [accepted Tie1 source gate](../server_snapshots/innovus/20260831_mptdc_tie1_filler_ecoroute_reconciled_131006/reports/operator_gate_tie1_insertion_trial.rpt)
- [V13 trial gate](../server_snapshots/innovus/20260831_174738_mptdc_tie1_minarea_clearance_v13_trial/reports/operator_gate_tie1_minarea_endext_trial.rpt)
- [V13 replay gate](../server_snapshots/innovus/20260831_175532_mptdc_tie1_minarea_clearance_v13_replay/reports/operator_gate_tie1_minarea_endext_replay.rpt)
- [V13 replay object audit](../server_snapshots/innovus/20260831_175532_mptdc_tie1_minarea_clearance_v13_replay/reports/tie1_min_area_fixed_wire_endext_replay_v13.rpt)
- [V13 replay wrapper gate](../server_snapshots/innovus/20260831_175532_mptdc_tie1_minarea_clearance_v13_replay/reports/checkpoint_repair_status.rpt)
- [corrected ring-probe gate](../server_snapshots/innovus/20260901_122444_mptdc_tie1_pg_ro_ring_probe_v2/reports/operator_gate_tie1_pg_ro_ring_probe.rpt)
- [corrected ring-probe object audit](../server_snapshots/innovus/20260901_122444_mptdc_tie1_pg_ro_ring_probe_v2/reports/pg_ro_ring_repair_status.rpt)
- [failed long-prune gate](../server_snapshots/innovus/20260901_124659_mptdc_tie1_pg_long_prune_trial/reports/operator_gate_tie1_pg_long_prune_trial.rpt)
- [failed long-prune incremental audit](../server_snapshots/innovus/20260901_124659_mptdc_tie1_pg_long_prune_trial/reports/pg_ro_ring_repair_status.rpt)
- [failed long-prune final endpoints](../server_snapshots/innovus/20260901_124659_mptdc_tie1_pg_long_prune_trial/reports/pg_ro_final_verify_special_detailed.rpt)
- [failed V2 long-prune gate](../server_snapshots/innovus/20260901_131741_mptdc_tie1_pg_long_prune_v2_trial/reports/operator_gate_tie1_pg_long_prune_trial.rpt)
- [failed V2 long-prune incremental audit](../server_snapshots/innovus/20260901_131741_mptdc_tie1_pg_long_prune_v2_trial/reports/pg_ro_ring_repair_status.rpt)
- [V2 source deletion 12 endpoints](../server_snapshots/innovus/20260901_131741_mptdc_tie1_pg_long_prune_v2_trial/reports/pg_ro_after_prune_12_special_detailed.rpt)
- [V2 source deletion 13 endpoints](../server_snapshots/innovus/20260901_131741_mptdc_tie1_pg_long_prune_v2_trial/reports/pg_ro_after_prune_13_special_detailed.rpt)
- [failed V2 final endpoints](../server_snapshots/innovus/20260901_131741_mptdc_tie1_pg_long_prune_v2_trial/reports/pg_ro_final_verify_special_detailed.rpt)
- [failed V3 long-prune gate](../server_snapshots/innovus/20260901_141910_mptdc_tie1_pg_long_prune_v3_trial/reports/operator_gate_tie1_pg_long_prune_trial.rpt)
- [failed V3 object and inventory audit](../server_snapshots/innovus/20260901_141910_mptdc_tie1_pg_long_prune_v3_trial/reports/pg_ro_ring_repair_status.rpt)
- [failed V3 final endpoints](../server_snapshots/innovus/20260901_141910_mptdc_tie1_pg_long_prune_v3_trial/reports/pg_ro_final_verify_special_detailed.rpt)
- [prior PVS diagnostic summary](../server_snapshots/pvs/20260831_mptdc_tie1_lvs_density_131326_04_lvs/reports/operator_gate_pvs_diagnostic_summary.rpt)

## Accepted V13 Geometry

The only intended database mutation is one regular fixed MET1 wire on
`u_core_n_57556`.

| Property | Accepted value |
| --- | --- |
| Repair mode | `CANONICAL_FIXED_MET1_VIA_OVERLAP_SHELF_CLEARANCE_V13` |
| Interactive endpoints | `(385.175, 328.305)` -> `(385.560, 328.305)` |
| Materialized centerline | `(385.290, 328.305)` -> `(385.445, 328.305)` |
| Materialized box | `(385.175, 328.190)` -> `(385.560, 328.420)` |
| Layer, width, status | `MET1`, `0.23 um`, `fixed` |
| Materialized length | `0.155 um` |
| Predicted connected area | `0.211450 um2`, above required `0.202000 um2` |
| Predicted `FE_RC_5_0` clearance | `0.240 um`, margin `0.010 um` over the `0.230 um` requirement |

Both the trial and replay prove the following mutation contract:

- target regular-wire count delta `+1`;
- exactly one new target wire;
- all pre-existing target-wire handles preserved;
- all non-target route objects unchanged;
- reserved fill objects unchanged;
- landing representation unchanged;
- four target vias before and after, with an unchanged fingerprint;
- no placement move, global route, `ecoRoute`, `routeDesign`, via edit, or PG
  edit;
- no unsupported wire `shape` attribute query in the accepted V13 audit.

The fresh post-edit `verify_drc` report is authoritative and contains zero
violations. The saved marker TSV still contains one old MET1 spacing row at
`{364.47 358.235 364.67 358.275}` plus the special-connectivity markers. That
geometry row is stale database marker persistence, not a live violation: fresh
DRC class counts are zero. Continue to reconcile marker tables against fresh
`verify_drc` totals instead of counting every saved marker row.

## V8 Through V13 Lessons

| Revision | Result | Lesson retained |
| --- | --- | --- |
| V8 | command and manual ECO failed; DRC remained `1` | Direct end extension did not produce an attributable accepted object. Do not replay it. |
| V9 | marker reconciliation passed, edit still failed; DRC remained `1` | The live minimum-area marker was correctly separated from one stale geometry marker, but object creation was still not proven. |
| V10 | one horizontal free-end tail materialized; DRC increased `1 -> 2` | Adding area into the free-end corridor created a new spacing failure. Geometry growth alone is insufficient. |
| V11 | perpendicular tail normalized to a shorter database object; DRC remained `1` | Innovus clips interactive endpoints to canonical wire geometry. Validate the resulting box and centerline, not the requested cursor path. The vertical tail also formed a `VIA1_o` notch-spacing defect. |
| V12 | via-overlap shelf box was correct; DRC remained `1` | The shelf was `0.215 um` from `FE_RC_5_0`, below the required `0.230 um`. The readback guard was also too strict because it compared UI endpoints with a normalized centerline. |
| V13 trial | DRC `1 -> 0`, all invariants passed | Shift the shelf upward by `0.025 um`, require exact materialized box and canonical centerline, and avoid the unsupported wire `shape` query. |
| V13 replay | DRC `1 -> 0`, all invariants passed again | The repair is deterministic from the immutable Tie1 checkpoint and is eligible to feed the PG analysis stage. |

Do not rerun V8 through V12, broaden the edit, invoke a route optimizer, or use
the V13 trial checkpoint as the source of another canonical stage.

## Gate Matrix

| Gate | Current evidence | State |
| --- | --- | --- |
| Tie-high target set | 91 targets connected, 0 disconnected | `PASS` |
| Tie-high net contract | 85 nets, maximum observed fanout 3 | `PASS` |
| Filler set | 24,856 fillers; tracked master set preserved | `PASS` |
| Placement | occupied `907533` of capacity `907533`; no instance moved | `PASS` |
| Innovus geometry DRC | fresh post-replay total `0` | `PASS` |
| Innovus shorts | `0` | `PASS` |
| Regular connectivity | `0` bad | `PASS` |
| Route completeness | fallback result `0`; report-route-zero contract passed | `PASS` |
| Special PG connectivity, accepted V13 source | 15 raw VDD/VSS dangling endpoints | `FAIL_OPEN` |
| Ring-probe candidate | 97 DRC, 67 shorts, 13 dangling endpoints | `REJECTED` |
| Long-prune V1 candidate | DRC `0`, shorts `0`, regular `0`, but 2 dangling endpoints | `REJECTED_DIAGNOSTIC` |
| Long-prune V2 candidate | DRC `0`, shorts `0`, regular `0`; second residual transition exposed | `REJECTED_DIAGNOSTIC` |
| Long-prune V3 candidate | source prune `13/13`, two residual MET1 endpoints; VDD/VSS vias `4575/4524 -> 4412/4197` | `REJECTED_TOPOLOGY_DESTRUCTIVE` |
| Full-handle long-prune stages | trial/replay entry points retired; PVS intake explicitly rejects legacy replay gates | `RETIRED` |
| Endpoint-anchor probe | read-only helper and V3 ancestry gate locally tested; no Cadence result yet | `NOT_RUN` |
| Antenna repair | not attempted by policy | `DEFERRED` |
| PVS base DRC | prior run: 136, all classified antenna-only | `FAIL_DEFERRED_ANTENNA` |
| PVS raw full-top LVS | prior attributable run: explicit `MISMATCH` | `FAIL` |
| Standalone `RO_tune6` LVS | explicit non-blackbox `MATCH`, exact GDS/CDL hashes | `PASS_DIAGNOSTIC` |
| Digital-top RO-boundary LVS | not rerun from a PG-clean V13 descendant | `NOT_RUN` |
| PVS density DRC | not run after LVS mismatch | `NOT_RUN` |
| Timing | not run in this DRC/LVS recovery scope | `NOT_RUN` |
| Final signoff eligibility | outstanding PG, LVS, density, timing, and export gates | `NO` |

Command return codes are not substituted for these gates. In particular, the
prior PVS process returned `0` while the LVS comparison explicitly reported
`MISMATCH`.

## Remaining PG Debt

The 15 findings below are raw `verifyConnectivity -type special` dangling-wire
endpoints. Although Innovus stores related marker rows with subtype
`ConnectivityAntenna`, they are special-wire topology findings, not the process
antenna-rule debt that is explicitly excluded from repair.

| Net | Layer | Endpoint |
| --- | --- | --- |
| VDD | MET3 | `(221.750, 681.160)` |
| VDD | MET3 | `(221.750, 201.160)` |
| VDD | MET3 | `(48.000, 681.160)` |
| VDD | MET3 | `(48.000, 201.160)` |
| VDD | METTP | `(121.160, 233.620)` |
| VDD | METTP | `(121.160, 648.320)` |
| VSS | MET3 | `(221.750, 685.160)` |
| VSS | MET3 | `(221.750, 205.160)` |
| VSS | MET3 | `(48.000, 685.160)` |
| VSS | MET3 | `(48.000, 205.160)` |
| VSS | METTP | `(125.160, 233.620)` |
| VSS | METTP | `(125.160, 648.320)` |
| VSS | METTP | `(125.160, 721.750)` |
| VSS | METTP | `(205.160, 158.320)` |
| VSS | METTP | `(125.160, 158.320)` |

The detailed source is the [replay special-connectivity
report](../server_snapshots/innovus/20260831_175532_mptdc_tie1_minarea_clearance_v13_replay/reports/01_after_command_verify_connectivity_special_detailed.rpt).

### Proven Topology

The old short-segment deletion plan is intentionally retired. Historical
post-`sroute` topology proves that these markers are cuts in the original
2.0-um PG mesh around the two RO obstructions, not 15 independent stubs. The
same-net, same-layer endpoint matcher resolves all 15 markers to 13 unique
axis-aligned handles:

- 8 MET3 endpoint markers and 7 METTP endpoint markers;
- 6 VDD markers and 9 VSS markers;
- 13 unique handles, all longer than `10.0 um`;
- exactly two handles referenced at both ends: VDD METTP
  `(121.160,233.620)` to `(121.160,648.320)` and VSS METTP
  `(125.160,233.620)` to `(125.160,648.320)`;
- representative MET3 cuts are VDD `(16.160,201.160)` to
  `(48.000,201.160)` and `(221.750,201.160)` to
  `(1152.560,201.160)`, with analogous rows at `y=681.160` and on VSS.

This is why the previous guard correctly rejected both duplicate handles and
long deletion. Treating 15 markers as 15 objects would double-delete two
handles, while enabling a generic long-delete switch would authorize a much
broader mutation than the evidence supports.

The two failed prune generations add two decisive topology facts. After deleting
source handle 12, VSS METTP `{125.16 721.75}->{125.16 869.4}`, its original
endpoint marker disappeared and Innovus exposed the north VSS MET1 endpoint
`(124.160,723.520)`. Historical post-`sroute` evidence identifies the exact
pre-existing object:

```text
net=VSS object=368 shape=corewire layer=MET1 status=routed width=0.8
geomType=pathSeg box={124.16 723.12 240.8 723.92}
points={{124.16 723.52} {240.8 723.52}} length=116.64
```

It is not a newly created error and not a short tail. It was already present
under the deleted METTP topology. V2 then deleted source handle 13, VSS METTP
`{205.16 13.16}->{205.16 158.32}`. The METTP marker disappeared and Innovus
exposed a second, south VSS MET1 endpoint at `(204.160,150.080)`. The same
historical inventory identifies that object exactly:

```text
net=VSS object=365 shape=corewire layer=MET1 status=routed width=0.8
geomType=pathSeg box={204.16 149.68 240.8 150.48}
points={{204.16 150.08} {240.8 150.08}} length=36.64
```

The V2 final report contains exactly these north and south MET1 markers. V3
confirmed that both transitions are deterministic and that all 13 source
handles can be removed while preserving geometry DRC `0`, shorts `0`, and
regular connectivity `0`. It also proved why that sequence cannot be promoted:
full-object deletion removed associated vias throughout the affected PG
objects. Zero DRC is not evidence that the retained PG topology is equivalent.

The accepted V13 lineage has no RO block rings. A separate proven Innovus run
created one VDD/VSS block ring around each of the two exact RO instances using
MET3 top/bottom and METTP left/right sides. Its audited effect was exactly two
rings, 16 new `blockRing` sWires, VDD `+8`, and VSS `+8`. The new probe reuses
that command contract but derives all ring coordinates and all endpoint
intersections from the live V13 database. It does not copy historical
coordinates.

Evidence:

- [original post-sroute PG topology](../server_snapshots/innovus/20260825_mptdc_bufftap0_halo10_physical_130313/reports/postplace_pre_route_pg_topology_after_sroute.rpt)
- [proven two-ring effect](../server_snapshots/innovus/20260828_mptdc_free_pnr_stripevaluefix_151756_u50/reports/ro_block_ring_status.rpt)
- [proven ring topology](../server_snapshots/innovus/20260828_mptdc_free_pnr_stripevaluefix_151756_u50/reports/postplace_pre_route_pg_topology_after_sroute.rpt)

### Implemented Repair Ladder

The implementation is in
`MPTDC/pnr/scripts/innovus_mptdc_pg_ro_ring_checkpoint_tools.tcl` and is
orchestrated by `server_run_mptdc_tie1_closure_stage.sh`. Every candidate starts
from the accepted V13 replay in a fresh Innovus process.

The ring branch remains available for other attributable sources, but it is
closed for this V13 source because the corrected probe physically failed. The
full-handle long-prune branch is also closed: V3 demonstrated a nonlocal PG-via
loss even though geometry and regular-connectivity checks stayed clean.

The only authorized next stage is
`tie1-pg-endpoint-anchor-probe`. Its preflight recursively validates:

- the accepted V13 source path and SHA-256;
- corrected rejected ring probe
  `20260901_122444_mptdc_tie1_pg_ro_ring_probe_v2`;
- rejected V1, V2, and V3 prune evidence, including exact run ancestry;
- V3 source prune `13/13`, exact NORTH and SOUTH marker transitions, final
  VDD/VSS sWire inventories `445/411`, and failed via inventories
  `4575/4524 -> 4412/4197`;
- exact V3 candidate status `NOT_SELECTED`, decision `FAIL_STOP`, and the two
  final MET1 endpoints;
- exact live V13 source preflight `15 markers / 13 handles / 2 shared`.

The endpoint-anchor probe contract is:

1. Restore V13 in one fresh Innovus process. Do not restore V1, V2, V3, or a
   ring-probe candidate.
2. Parse flat and recursively wrapped `.box` values into canonical numeric
   rectangles. A malformed or nonnumeric rectangle fails its predicate; it is
   never treated as an empty match or silently accepted.
3. Inventory same-net and opposite-net sWires, PG via locations, and PG terminal
   shapes around both endpoints of all 13 source objects. Keep candidate
   identity, geometry, retained-side distance, conflicts, and query failures in
   the report.
4. Classify all 15 markers conservatively. `TRIM_FEASIBLE` requires one unique
   retained same-net anchor, no opposite-net conflict, and complete queries.
   Ambiguity, conflict, missing geometry, or incomplete query data is
   `BLOCKED`. The current probe makes no stitch-feasibility claim without an
   independently proven bounded stitch primitive.
5. Re-identify the exact north and south residual support objects and report
   every contract predicate: net, layer, shape, status, geometry type, width,
   orientation, points, rectangle, marker containment, and length.
6. Require `PG_MUTATION_COMMAND_COUNT=0`, unchanged VDD/VSS sWire inventories,
   unchanged PG via inventories, unchanged source checkpoint SHA-256, final
   DRC/shorts/regular tuple `0/0/0`, and the original 15 special endpoints.
7. Publish `PASS_ANALYSIS_KEEP_V13` only. The generated checkpoint is
   `NOT_SELECTED`, `SIGNOFF_ELIGIBLE=NO`, and the next stage is
   `STOP_AND_REVIEW_ENDPOINT_ANCHORS`.

`ANCHOR_QUERY_COMPLETENESS_STATUS=FAIL` does not authorize a repair. It forces
affected markers to `BLOCKED`; the analysis snapshot may still be published so
the missing database attributes are attributable and can be reviewed.

Both `tie1-pg-long-prune-trial` and `tie1-pg-long-prune-replay` are unsupported
driver stages. The PVS driver excludes long-prune gates from its replay
selector and explicitly rejects tracked long-prune replay gates as
`TIE1_PG_LONG_PRUNE_REPLAY_RETIRED`. It also rejects endpoint-anchor gates as
`TIE1_PG_ENDPOINT_ANCHOR_ANALYSIS_ONLY`. Neither class may launch PVS.

Never set `MPTDC_PG_DANGLING_ALLOW_LONG_DELETE=1`, delete by area, use a broad
`sroute`, invoke `ecoRoute`, `routeDesign`, or a global optimizer, or manually
promote an analysis checkpoint. No stage repairs or suppresses antenna results.

### Executed PG Results and Lessons

The first probe, `20260901_115029_mptdc_tie1_pg_ro_ring_probe`, failed before
mutation because the point parser did not normalize wrapped nested `.pts`
values before endpoint matching. It remains useful infrastructure evidence but
does not decide physical feasibility.

The corrected probe,
`20260901_122444_mptdc_tie1_pg_ro_ring_probe_v2`, proved the full source
inventory: 450 VDD and 419 VSS sWires, all using the observed wrapped nested
two-point encoding, with every source marker matching exactly one handle. It
also identified the exact two RO instances. Both `addRing` calls returned pass
and created two rings, but the effect was VDD `+10`, VSS `+8` rather than the
historical `+8/+8`. Fresh checks then reported 97 DRC violations, including 67
shorts, while special debt changed from 15 to 13. This is a physical rejection,
not a parser failure. The probe checkpoint is `NOT_SELECTED`; do not retry ring
stitching from it.

The V1 prune, `20260901_124659_mptdc_tie1_pg_long_prune_trial`, restored V13
again and made no rings or vias. Its incremental sequence proved that source
deletions 1 through 11 are individually clean and attributable:

```text
special markers: 15 -> 14 -> 13 -> 12 -> 11 -> 9 -> 8 -> 7 -> 6 -> 5 -> 4 -> 2
geometry DRC:     0 at every accepted step
shorts:           0 at every accepted step
regular bad:      0 at every accepted step
```

The two-marker drops at source handles 5 and 11 are expected because those
handles are referenced at both endpoints. At deletion 12 the expected count
was 1 but the observed count stayed 2: the old VSS/METTP marker vanished and
the exact north VSS/MET1 marker appeared. V1 correctly stopped before source
handle 13 and saved its candidate as `NOT_SELECTED`. The V1 gate model had
assumed every successful source deletion reduced the count by its reference
count.

V2, `20260901_131741_mptdc_tie1_pg_long_prune_v2_trial`, restored V13 again and
replaced the count-only check with complete marker-set comparisons. Deletions 1
through 11 repeated exactly. Deletion 12 passed with the expected north
METTP-to-MET1 transition. Deletion 13 physically removed the remaining source
METTP handle, but exposed the south MET1 endpoint instead of leaving only the
north marker. The authoritative detailed progression is:

```text
after source delete 12:
  VSS|MET1|124.160|723.520
  VSS|METTP|205.160|158.320
after source delete 13 and at final verification:
  VSS|MET1|124.160|723.520
  VSS|MET1|204.160|150.080
geometry DRC / shorts / regular bad: 0 / 0 / 0
```

V2 reports `13 attempts / 12 gate successes`, performs no residual deletion,
and leaves its checkpoint `NOT_SELECTED`. Its
`SOURCE_PRUNE_FINAL_OBSERVED_MARKER_FINGERPRINT` field retained the pre-delete
13 set after the incremental failure; the delete-13 detailed report, final
detailed report, and marker TSV independently prove the actual two-MET1 state.

V3, `20260901_141910_mptdc_tie1_pg_long_prune_v3_trial`, fixed that bookkeeping
and accepted both exact transitions. It completed source prune `13/13` with
exact final marker set:

```text
VSS|MET1|124.160|723.520
VSS|MET1|204.160|150.080
geometry DRC / shorts / regular bad: 0 / 0 / 0
```

The residual lookup saw one raw exact object at each location, but its
contracted candidate count was zero because Innovus returned recursively
wrapped `.box` values that the old rectangle helper did not normalize. No
residual delete was attempted. More importantly, the source sequence itself
changed the physical inventory as follows:

```text
VDD sWires: 450 -> 445  (delta -5)
VSS sWires: 419 -> 411  (delta -8)
VDD vias:   4575 -> 4412 (delta -163)
VSS vias:   4524 -> 4197 (delta -327)
```

The sWire deltas match the 13 deleted source handles, but the 490-via loss does
not satisfy topology preservation. V3 therefore reports
`SWIRE_INVENTORY_STATUS=FAIL`, `PG_VIA_HANDLE_STATUS=FAIL_CHANGED`, retains two
special endpoints, and leaves its checkpoint `NOT_SELECTED`. The recursive
rectangle parser has since been fixed and unit-tested, but that parser fix does
not rehabilitate full-handle deletion. It is used only by the read-only anchor
probe.

## Prior PVS Result

The prior PVS run is useful triage evidence but cannot certify the V13 replay
because it predates the V13 geometry repair and the pending PG decision.

Base DRC reported 136 results in four rules:

| Rule | Count |
| --- | ---: |
| `R1M2P1` | 6 |
| `R1M3P1` | 68 |
| `R2M2P1` | 7 |
| `R2M3P1` | 55 |

The classifier found zero non-antenna rules and labelled the set
`ANTENNA_ONLY_MANAGER_EXCEPTION`. This is not a clean DRC result. Under the
current user scope it is retained as explicit deferred antenna debt, without an
antenna repair attempt.

The LVS source-preparation contract passed: exact inputs were hashed, all
24,856 tracked fillers were removed from the comparison source, unresolved
active masters were zero, top pin counts were `59:59`, and both named
`RO_tune6` source instances were present. PVS nevertheless reported one
mismatched top cell and connectivity mismatch.

The dominant exact mismatch signature is:

- two schematic `RO_tune6` instances unmatched on the layout side;
- 380 reduced layout devices unmatched versus those two source instances:
  18 `MP(PEI)`, 108 `MP(PELI)`, 34 `MN(NEI)`, 122 `MN(NELI)`, 2 `R(RNP1_3)`,
  and 96 `C(CSF3)`;
- reduced total instances `213960` layout versus `213582` schematic;
- no pin-count mismatch (`59:59`), parameter mismatch, or instance-subtype
  mismatch.

This is an RO hierarchy/hcell abstraction mismatch signature: the source
retained two abstract `RO_tune6` instances while raw full-top reduction exposed
their device content on the layout side. Independent standalone evidence now
proves that the RO itself is not an unresolved leaf. Run
`20260827_mptdc_ro6_standalone_lvs_vddfix_150520` has explicit report-level
`MATCH`, `BLACKBOXED_CELL_COUNT=0`, GDS SHA-256
`9d6f269541d51db0c30c5e7cc81334d70578ca8723558b32f34f9803469ea36a`,
and CDL SHA-256
`b925af01b36b1bcc80557c3c584aaf02fdb7b75df268ee6dd3c50dce7810039b`.

The implemented post-PG proof is deliberately compositional:

1. `server_run_mptdc_ro6_recovery_pvs.sh` accepts exactly one tracked passing
   PG replay gate: legacy bounded short-delete or RO ring-stitch. It verifies
   replay ancestry, checkpoint content hash, DRC/connectivity tuple, and
   physical invariants before preparing GDS/source/CDL inputs. Long-prune replay
   gates are retired, and endpoint-anchor gates are analysis-only; either one
   forces PVS preflight failure before source preparation.
2. Run it with `--diagnostic-antenna-exception` and
   `--diagnostic-ro-compositional`. Base DRC may continue only when all nonzero
   rules classify as the already authorized antenna-only debt. Antenna remains
   reported and is never repaired or waived.
3. Preserve the attributable raw full-top mismatch evidence. Then run
   `server_run_mptdc_ro6_boundary_lvs.sh` using that exact PVS run and the
   standalone RO run above. The boundary run must apply the RO hcell/blackbox
   contract, prove zero Tie1 mismatch residue, and end with explicit boundary
   `MATCH`, `BOUNDARY_REMAINDER_CLASS=NONE_MATCH`, and
   `DECISION=PASS_COMPOSITIONAL_LVS`.
4. The pair of an exact standalone non-blackbox RO `MATCH` and an exact
   digital-top RO-boundary `MATCH` is the accepted compositional LVS proof.
   It is diagnostic closure, not a claim that raw monolithic LVS or final
   signoff is clean. Density remains blocked until this pair passes.

Do not alter Tie1 insertion, top pins, or the RO schematic merely to make the
raw reducer flattening agree. A zero PVS process return code, empty error file,
or stale `matched` marker is never an LVS pass.

Relevant reports:

- [base DRC gate](../server_snapshots/pvs/20260831_mptdc_tie1_lvs_density_131326_04_lvs/reports/operator_gate_pvs_drc_base.rpt)
- [base DRC classification](../server_snapshots/pvs/20260831_mptdc_tie1_lvs_density_131326_04_lvs/reports/pvs_recovery_base_drc_classification.rpt)
- [LVS source filter](../server_snapshots/pvs/20260831_mptdc_tie1_lvs_density_131326_04_lvs/reports/lvs_source_filter.rpt)
- [LVS comparison gate](../server_snapshots/pvs/20260831_mptdc_tie1_lvs_density_131326_04_lvs/reports/operator_gate_pvs_lvs.rpt)
- [LVS comparison summary](../server_snapshots/pvs/20260831_mptdc_tie1_lvs_density_131326_04_lvs/pvs_lvs/mptdc_axis_core_merged_pg_nonphys_dcells_cdl_ro6_pinfix_noattr_clean_findshorts_script/mptdc_axis_core_lvs.sum.cls)
- [standalone RO LVS gate](../server_snapshots/pvs/20260827_mptdc_ro6_standalone_lvs_vddfix_150520/reports/operator_gate_pvs_ro6_standalone_lvs.rpt)
- [standalone RO input hashes](../server_snapshots/pvs/20260827_mptdc_ro6_standalone_lvs_vddfix_150520/manifests/ro6_standalone_lvs_inputs.rpt)

The reported `PHYSICAL_TIE_INSTANCE_COUNT=8` in the source-filter inventory is
not by itself proof that 77 Tie1 cells were dropped. Innovus separately proves
85 inserted Tie1 nets and the LVS comparison does not list `LOGIC1DJIHD` as an
unmatched model. Treat that count as a hierarchy/accounting item to explain,
not as the current mismatch root cause.

## Implementation State

The following repository changes implement this handoff:

- `innovus_mptdc_pg_ro_ring_checkpoint_tools.tcl`: exact topology preflight,
  recursive rectangle normalization, per-predicate residual diagnostics, and a
  read-only endpoint-anchor inventory/classifier with zero mutation commands;
- `innovus_mptdc_pg_dangling_checkpoint_tools.tcl`: canonical flat or wrapped
  rectangle parsing with fail-closed malformed/nonnumeric handling;
- `server_run_mptdc_tie1_closure_stage.sh`: isolated probe/trial/replay stages,
  immutable V13/probe/failed-V1/V2/V3 ancestry checks, a zero-mutation anchor
  gate, source-hash preservation, and unsupported long-prune entry points;
- `server_run_mptdc_ro6_recovery_pvs.sh`: exactly-one eligible replay-gate
  selection, explicit retired-prune rejection, and explicit anchor-analysis
  rejection before any PVS invocation;
- `test_pg_ro_ring_checkpoint_tools.tcl`, the Tie1 closure-driver test, and the
  PVS recovery-driver test: wrapped rectangle fixtures, anchor ambiguity and
  conflict classification, exact V1/V2/V3 rejected ancestry, retired-stage
  rejection, source-hash preservation, zero-mutation publication, and PVS
  candidate exclusion.

Local validation on 2026-09-01 passed:

```text
MPTDC_PG_RO_RING_CHECKPOINT_TOOLS_TEST=PASS
MPTDC_PG_DANGLING_CHECKPOINT_TOOLS_TEST=PASS
MPTDC_RO_PG_BLOCK_RING_CONTRACT_TEST=PASS
MPTDC_TIE1_CLOSURE_STAGE_DRIVER_TEST=PASS
MPTDC_RO6_RECOVERY_PVS_DRIVER_TEST=PASS
```

These are static and fixture proofs. They do not substitute for the foreground
Innovus endpoint-anchor probe and do not change the accepted V13 evidence.

## Exact Next Command

Run only the endpoint-anchor probe next. Use this foreground block on
`lyoelectrosrv01`; it does not close the login shell on a failed guard.

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC

git pull --ff-only origin SPADMIC_test
PULL_RC=$?

CURRENT_HEAD="$(git rev-parse HEAD 2>/dev/null)"
ORIGIN_HEAD="$(git rev-parse refs/remotes/origin/SPADMIC_test 2>/dev/null)"
TRACKED_STATUS="$(git status --short --untracked-files=no 2>/dev/null)"

echo "PULL_RC=$PULL_RC"
echo "CURRENT_HEAD=$CURRENT_HEAD"
echo "ORIGIN_HEAD=$ORIGIN_HEAD"
echo "TRACKED_STATUS=${TRACKED_STATUS:-CLEAN}"

if [[ "$PULL_RC" -eq 0 && "$CURRENT_HEAD" == "$ORIGIN_HEAD" && -z "$TRACKED_STATUS" ]]; then
  ANCHOR_RUN="$(date +%Y%m%d_%H%M%S)_mptdc_tie1_pg_endpoint_anchor_probe"
  echo "ANCHOR_RUN=$ANCHOR_RUN"

  bash MPTDC/pnr/scripts/server_run_mptdc_tie1_closure_stage.sh \
    --stage tie1-pg-endpoint-anchor-probe \
    --source-tie1-run-id 20260831_mptdc_tie1_filler_ecoroute_reconciled_131006 \
    --source-minarea-replay-run-id 20260831_175532_mptdc_tie1_minarea_clearance_v13_replay \
    --source-pg-probe-run-id 20260901_122444_mptdc_tie1_pg_ro_ring_probe_v2 \
    --source-pg-prior-trial-run-id 20260901_141910_mptdc_tie1_pg_long_prune_v3_trial \
    --run-id "$ANCHOR_RUN" \
    --expected-head "$CURRENT_HEAD"

  ANCHOR_RC=$?
  ANCHOR_DIR="/sim/ksabra/SPADMIC_work/innovus/$ANCHOR_RUN"
  echo "ANCHOR_RC=$ANCHOR_RC"
  echo "ANCHOR_RUN=$ANCHOR_RUN"
  echo "ANCHOR_DIR=$ANCHOR_DIR"

  for report in \
    operator_gate_tie1_pg_endpoint_anchor_probe.rpt \
    pg_ro_endpoint_anchor_probe_status.rpt \
    pg_ro_initial_verify_special_detailed.rpt \
    pg_ro_final_verify_special_detailed.rpt \
    01_after_command_verify_drc.rpt \
    01_after_command_verify_connectivity_regular.rpt \
    01_after_command_verify_connectivity_special.rpt \
    01_after_command_report_route.rpt \
    checkpoint_repair_status.rpt; do
    echo "===== $report ====="
    if [[ -s "$ANCHOR_DIR/reports/$report" ]]; then
      cat "$ANCHOR_DIR/reports/$report"
    else
      echo "MISSING=$ANCHOR_DIR/reports/$report"
    fi
  done

  for log in tie1_closure_driver.log checkpoint_repair_wrapper.log innovus_route_checkpoint_repair.log; do
    echo "===== LOG TAIL: $log ====="
    if [[ -s "$ANCHOR_DIR/logs/$log" ]]; then
      tail -n 200 "$ANCHOR_DIR/logs/$log"
    else
      echo "MISSING=$ANCHOR_DIR/logs/$log"
    fi
  done
else
  echo "STOP: pull must pass and checkout must be tracked-clean and equal to origin/SPADMIC_test"
fi

echo "FINAL_HEAD=$(git rev-parse HEAD 2>/dev/null)"
```

Return the printed reports in full, including the driver summary above them.
Do not source a ring or long-prune candidate, do not manually edit the output,
and do not launch PVS from this run. A zero wrapper return or `INNOVUS_RC=0`
alone does not decide acceptance; the operator gate and report-level checks do.

## Continuation Order

1. Run the endpoint-anchor probe above from the accepted V13 replay. Require
   zero mutation commands, unchanged source checkpoint hash, unchanged sWire
   and via inventories, exact source topology `15/13/2`, two exact residual
   support objects, and final DRC/shorts/regular tuple `0/0/0` with the original
   15 special endpoints still present.
2. Review every per-marker candidate set and predicate failure. Do not infer a
   trim or stitch from marker count alone. A future repair trial must have one
   bounded, reviewable operation per approved endpoint class and must preserve
   all retained PG vias.
3. Implement and locally test that bounded operation only after the probe
   evidence is reviewed. Run its trial and canonical replay in separate fresh
   Innovus processes from V13. Neither the anchor checkpoint nor a failed trial
   is a replay source.
4. Run attributable PVS base DRC and raw LVS only from a selected PG-clean
   canonical replay using `--diagnostic-antenna-exception
   --diagnostic-ro-compositional` and the exact standalone-proven RO GDS. Keep
   all antenna counts visible.
5. Run boundary LVS against that exact raw PVS run and standalone run
   `20260827_mptdc_ro6_standalone_lvs_vddfix_150520`. Require explicit
   compositional `MATCH`; process RC `0` is insufficient.
6. Run density DRC through `server_run_mptdc_ro6_density_after_boundary.sh`
   only after `PASS_COMPOSITIONAL_LVS`. Keep base DRC, density DRC, raw LVS,
   boundary LVS, and standalone LVS as separate evidence.
7. Requalify timing, power integrity, and final export separately before any
   signoff claim.

## Stop Conditions

Stop and preserve the accepted V13 replay checkpoint if any of these occurs:

- source checkpoint path or SHA-256 differs;
- tracked checkout is dirty or HEAD differs from the expected remote head;
- the preflight sees anything other than 15 markers, 13 unique handles, and
  exactly two double-referenced handles;
- any marker has zero or multiple exact special-wire matches;
- a handle has any reference count other than one or two, or the number of
  double-referenced handles is not exactly two;
- any source handle is non-axis-aligned or is not longer than `10.0 um`;
- the corrected ring probe or failed V1/V2/V3 evidence is
  missing, untracked, swapped, recursively inconsistent, or has a different
  source/checkpoint/result fingerprint;
- the anchor stage attempts any PG mutation, ring, via, replacement, prune,
  area deletion, broad PG route, or optimizer;
- the recursively wrapped rectangle parser cannot produce one numeric
  canonical box for either residual support object;
- either residual support query returns other than one exact object, the two
  objects share a handle, or any net/layer/shape/status/width/type/box/points/
  length predicate differs from its contract;
- source checkpoint SHA-256, VDD/VSS sWire inventory, or PG via inventory
  changes during the read-only probe;
- the final special marker set differs from the original exact 15-marker set;
- geometry DRC, shorts, regular connectivity, or route completeness regresses;
- Tie1 target/net counts, filler count, placement occupancy, or via fingerprint
  changes unexpectedly;
- any anchor candidate is ambiguous, has an opposite-net conflict, or depends
  on an incomplete query but is classified as feasible;
- an endpoint-anchor or long-prune checkpoint is offered to PVS;
- PVS evidence is missing exact GDS/source/control hashes;
- LVS lacks an explicit `MATCH` statement.

Do not use false paths, multicycle paths, clock relaxation, DRC waivers, short
waivers, PG-dangling waivers, or antenna-result suppression to change any gate.

## Known Nonblocking Log Debt

The replay log still reports inherited library and deprecation messages,
including ignored LEF property `CatenaDesignType` (`IMPLF-186`), incomplete
antenna attributes, timing-library defaults, obsolete `reportRoute`, and
inactive-view timing warnings. They did not invalidate the bounded V13 geometry
proof, but they remain visible debt. Timing is explicitly not requalified by
this checkpoint-repair run.
