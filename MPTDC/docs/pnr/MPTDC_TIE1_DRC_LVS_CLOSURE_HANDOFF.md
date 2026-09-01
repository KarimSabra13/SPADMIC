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

The read-only endpoint-anchor probe has now completed from V13. It preserved
the exact source hash, all VDD/VSS sWires, and all PG vias, and issued zero PG
mutation commands. It classified 13 of 15 markers as `TRIM_FEASIBLE`, zero as
`STITCH_FEASIBLE`, and two as `BLOCKED`. The blocked markers are
`VSS|MET3|48.000|205.160` and `VSS|MET3|221.750|205.160`; both have
`NO_RETAINED_ANCHOR`. The saved checkpoint remains analysis-only,
`NOT_SELECTED`, and must not feed PVS.

For the same-day handoff, further PG mutation is explicitly deferred. The
attributable source PVS run has completed directly from the exact accepted V13
replay using the driver's `TIE1_MINAREA_CLEAN_COMPOSITIONAL` intake. Its base
DRC contains 136 results in exactly four antenna rule classes and zero
non-antenna rules. Its raw full-top LVS is an explicit mismatch with the exact
RO abstraction signature: top pins `59:59`, reduced instances `213960:213582`,
and unmatched reduced instances `380:2`. The next legal action is the RO
boundary proof, followed by strict monolithic full-top LVS with the
standalone-matched RO CDL and no HCell or blackbox.

The current state label is:

```text
MPTDC_TIE1_V13_PG15_OPEN_PVS_ANTENNA136_RAW_RO_ABSTRACTION_MONOLITHIC_PENDING
```

This label is intentionally not a signoff claim. Fresh Innovus geometry DRC,
short, regular-connectivity, and route checks pass. Raw special-PG connectivity
on the accepted source still reports 15 dangling VDD/VSS endpoints. The best
rejected diagnostic state has two endpoints, but it cannot be promoted. The
current attributable PVS run uses the V13 streamout, classifies all 136
base-DRC results as antenna rules with zero non-antenna rules, and records an
explicit raw LVS mismatch. Boundary, monolithic LVS, density DRC, timing
requalification, and final streamout qualification remain separate gates.

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
| Endpoint-anchor analysis | `20260901_153052_mptdc_tie1_pg_endpoint_anchor_probe` | evidence commit `55c319891be3adbf4a956ee6a391cacee35ca45e`; source SHA-256 unchanged; markers `13 trim / 0 stitch / 2 blocked`; zero mutations; `NOT_SELECTED` |
| Prior PVS diagnostic | `20260831_mptdc_tie1_lvs_density_131326` | base DRC `136`, antenna-only classification, LVS `MISMATCH`; predates V13 |
| Historical PG topology witness | `20260825_mptdc_bufftap0_halo10_physical_130313` | identifies the 13 source handles and both exact exposed VSS/MET1 corewires |
| Proven RO ring primitive | `20260828_mptdc_free_pnr_stripevaluefix_151756_u50` | two RO rings, 16 new `blockRing` sWires, VDD delta `+8`, VSS delta `+8` |
| Standalone RO LVS proof | `20260827_mptdc_ro6_standalone_lvs_vddfix_150520` | explicit `MATCH`, zero blackboxes, immutable RO GDS/CDL hashes |
| V13 attributable source PVS | `20260901_160902_mptdc_v13_pg15_compositional_pvs` | merged GDS SHA-256 `7cfbde3a11513445d4e2abf7ea329d3dd17d3e1e0b82e6c5c75c031aa46104a2`; base DRC `136` antenna-only / `0` non-antenna; raw LVS exact `380:2` RO abstraction mismatch |

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
- [endpoint-anchor operator gate](../server_snapshots/innovus/20260901_153052_mptdc_tie1_pg_endpoint_anchor_probe/reports/operator_gate_tie1_pg_endpoint_anchor_probe.rpt)
- [endpoint-anchor object audit](../server_snapshots/innovus/20260901_153052_mptdc_tie1_pg_endpoint_anchor_probe/reports/pg_ro_endpoint_anchor_probe_status.rpt)
- [endpoint-anchor final special connectivity](../server_snapshots/innovus/20260901_153052_mptdc_tie1_pg_endpoint_anchor_probe/reports/pg_ro_final_verify_special_detailed.rpt)
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
| Endpoint-anchor probe | source hash/sWires/vias unchanged; zero mutations; 13 markers trim-feasible, 2 blocked | `PASS_ANALYSIS_KEEP_V13` |
| Antenna repair | not attempted by policy | `DEFERRED` |
| PVS base DRC | current V13 source run: 136, all classified antenna-only; zero non-antenna | `FAIL_DEFERRED_ANTENNA` |
| PVS raw full-top LVS | current V13 source run: explicit exact RO-abstraction `MISMATCH` | `FAIL` |
| Standalone `RO_tune6` LVS | explicit non-blackbox `MATCH`, exact GDS/CDL hashes | `PASS_DIAGNOSTIC` |
| Digital-top RO-boundary LVS | not yet run from the exact V13 diagnostic PVS tuple | `NOT_RUN` |
| Monolithic full-top LVS | not yet run with the standalone-matched external RO CDL | `NOT_RUN` |
| PVS density DRC | not run after LVS mismatch | `NOT_RUN` |
| Timing | not run in this DRC/LVS recovery scope | `NOT_RUN` |
| Final signoff eligibility | outstanding PG, LVS, density, timing, and export gates | `NO` |

Command return codes are not substituted for these gates. In particular, the
source PVS process returned `0` while the LVS comparison explicitly reported
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

The completed analysis stage was
`tie1-pg-endpoint-anchor-probe`. Its preflight recursively validated:

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

The executed probe reported `ANCHOR_QUERY_COMPLETENESS_STATUS=PASS`, exact
classification counts `13/0/2`, two exact residual support objects, and
unchanged source checkpoint, sWire, and via inventories. Unsupported
exploratory database paths still produced visible `IMPDBTCL-206/204` messages
for `pin`, `allShapes`, `box`, and `rect`; the supported fallback queries
completed the contractual inventory. These messages remain log debt and do
not authorize ignoring a failed report predicate in a future repair trial.

Both `tie1-pg-long-prune-trial` and `tie1-pg-long-prune-replay` are unsupported
driver stages. The PVS driver excludes long-prune gates from its replay
selector and explicitly rejects tracked long-prune replay gates as
`TIE1_PG_LONG_PRUNE_REPLAY_RETIRED`. It also rejects endpoint-anchor gates as
`TIE1_PG_ENDPOINT_ANCHOR_ANALYSIS_ONLY`. Neither class may launch PVS.

Diagnostic compositional mode separately accepts the exact tracked V13
minimum-area replay itself as `TIE1_MINAREA_CLEAN_COMPOSITIONAL`. That path is
the authorized same-day handoff source. It does not consume the anchor run and
does not convert the V13 special-connectivity failure into a pass.

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

The endpoint-anchor probe,
`20260901_153052_mptdc_tie1_pg_endpoint_anchor_probe`, then restored V13 in a
fresh process and performed no mutation. Its decision-bearing result is:

```text
source checkpoint SHA-256: unchanged
source topology:           15 markers / 13 handles / 2 shared
marker classification:     13 trim-feasible / 0 stitch-feasible / 2 blocked
target classification:     11 trim-feasible / 0 stitch-feasible / 2 blocked
blocked markers:           VSS|MET3|48.000|205.160
                           VSS|MET3|221.750|205.160
blocked reason:            NO_RETAINED_ANCHOR
residual support objects:  2, contract PASS
PG mutation commands:      0
source sWires / vias:      unchanged / unchanged
geometry DRC / shorts / regular bad: 0 / 0 / 0
special dangling endpoints: 15
decision:                  PASS_ANALYSIS_KEEP_V13
```

The candidate checkpoint is `NOT_SELECTED` and `SIGNOFF_ELIGIBLE=NO`. This
probe closes the read-only PG analysis step, not the PG connectivity gate.

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
The matching GDS is the copied standalone input
`/sim/ksabra/SPADMIC_work/innovus/20260827_mptdc_ro6_standalone_lvs_vddfix_150520/inputs/RO_tune6.fresh.gds`.
Do not substitute the mutable July merge path: it currently hashes to
`d73b59df73a243af1845add82a58d6ec50113d21a760902c3dab4b391c82d387`
and does not match this standalone proof.

The implemented diagnostic proof is deliberately compositional:

1. `server_run_mptdc_ro6_recovery_pvs.sh` accepts either one tracked passing PG
   replay gate or, in diagnostic compositional mode, the exact tracked V13
   minimum-area replay as `TIE1_MINAREA_CLEAN_COMPOSITIONAL`. It verifies gate
   ancestry and checkpoint content hash before preparing GDS/source/CDL inputs.
   Long-prune and endpoint-anchor run IDs remain ineligible and force PVS
   preflight failure before source preparation.
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
4. Treat that pair only as a diagnostic decomposition proof. It advances to
   `server_run_mptdc_ro6_monolithic_lvs.sh`, which replaces the generated RO
   wrapper with the exact standalone-matched external RO CDL and runs the real
   merged GDS against one full-top source. HCell, blackbox, position-based bus
   mapping, and global-port promotion are forbidden.
5. Accept LVS at signoff proof level only for explicit monolithic `MATCH`, zero
   blackboxed cells, zero mismatched cells, top `59:59` match, RO `19:19`
   match, no missing instances, and empty short/open evidence. Density remains
   blocked until that result is published.

Running this sequence from V13 does not waive its 15 special-PG endpoints. If
the boundary classifier returns `RO6_PG_OPEN_ONLY` and
`PASS_PG_REPAIR_REQUIRED`, preserve that attributable result and stop before
density. Run only the read-only endpoint probe from a fresh Innovus process;
do not use an endpoint-anchor or long-prune checkpoint as a source. Only
`NONE_MATCH` plus `PASS_COMPOSITIONAL_LVS` authorizes monolithic LVS, and only
the published monolithic `MATCH` authorizes density.

Do not alter Tie1 insertion, top pins, or the RO schematic merely to make the
raw reducer flattening agree. A zero PVS process return code, empty error file,
or stale `matched` marker is never an LVS pass.

Relevant reports:

- [base DRC gate](../server_snapshots/pvs/20260901_160902_mptdc_v13_pg15_compositional_pvs_04_lvs/reports/operator_gate_pvs_drc_base.rpt)
- [base DRC classification](../server_snapshots/pvs/20260901_160902_mptdc_v13_pg15_compositional_pvs_04_lvs/reports/pvs_recovery_base_drc_classification.rpt)
- [LVS source filter](../server_snapshots/pvs/20260901_160902_mptdc_v13_pg15_compositional_pvs_04_lvs/reports/lvs_source_filter.rpt)
- [LVS comparison gate](../server_snapshots/pvs/20260901_160902_mptdc_v13_pg15_compositional_pvs_04_lvs/reports/operator_gate_pvs_lvs.rpt)
- [LVS comparison summary](../server_snapshots/pvs/20260901_160902_mptdc_v13_pg15_compositional_pvs_04_lvs/pvs_lvs/mptdc_axis_core_merged_pg_nonphys_dcells_cdl_ro6_pinfix_noattr_clean_findshorts_script/mptdc_axis_core_lvs.sum.cls)
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
- `server_run_mptdc_ro6_recovery_pvs.sh`: exact V13 or exactly-one eligible
  replay-gate selection in compositional mode, explicit retired-prune
  rejection, and explicit anchor-analysis rejection before PVS invocation;
- `01_generate_lvs_source_pg_filtered.py`: default diagnostic wrapper/HCell
  source plus strict external-CDL mode with an exact 19-pin RO contract and no
  generated RO wrapper or HCell entry;
- `13_prepare_ro6_monolithic_lvs.py`, `14_gate_ro6_monolithic_lvs.py`, and
  `server_run_mptdc_ro6_monolithic_lvs.sh`: isolated no-HCell/no-blackbox
  full-top replay, exact input/hash attribution, and explicit report-level
  monolithic `MATCH` proof;
- `server_run_mptdc_ro6_density_after_boundary.sh`: density continuation only
  after a published attributable monolithic `MATCH`;
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
MPTDC_RO6_BOUNDARY_LVS_DRIVER_TEST=PASS
MPTDC_RO6_MONOLITHIC_LVS_DRIVER_TEST=PASS
MPTDC_RO6_DENSITY_AFTER_BOUNDARY_DRIVER_TEST=PASS
```

These are static and fixture proofs. They did not substitute for the foreground
Innovus endpoint-anchor probe, which independently completed, and they do not
change the accepted V13 evidence.

## Completed Source PVS Command

The foreground block below is retained for exact reproducibility. It completed
as run `20260901_160902_mptdc_v13_pg15_compositional_pvs`; do not create a
replacement source run unless an input hash or source contract is intentionally
changed and re-reviewed. It configured the repository-local Git identity, did
not close the login shell on a failed guard, and never sourced the
endpoint-anchor checkpoint.

The first attempt, run ID
`20260901_160352_mptdc_v13_pg15_compositional_pvs`, stopped correctly before
the driver launch (`PVS_DRIVER_RC=99`). Its live July-merge RO GDS hash was
`d73b59df73a243af1845add82a58d6ec50113d21a760902c3dab4b391c82d387`,
not the standalone-proven hash. No PVS directory, reports, or evidence snapshot
were created. The corrected command below sources only the immutable copied
input from the standalone `MATCH` run.

```bash
set +e

REPO=/home/validmgr/ksabra/2026_SPAD/SPADMIC
PNR_RUN=20260831_175532_mptdc_tie1_minarea_clearance_v13_replay
MPTDC_INNOVUS_WORK=/sim/ksabra/SPADMIC_work/innovus
SOURCE_CKPT="$MPTDC_INNOVUS_WORK/$PNR_RUN/checkpoints/repaired_route.enc.dat"
RO_GDS=/sim/ksabra/SPADMIC_work/innovus/20260827_mptdc_ro6_standalone_lvs_vddfix_150520/inputs/RO_tune6.fresh.gds
EXPECTED_RO_GDS_SHA=9d6f269541d51db0c30c5e7cc81334d70578ca8723558b32f34f9803469ea36a
PVS_RUN="$(date +%Y%m%d_%H%M%S)_mptdc_v13_pg15_compositional_pvs"
PVS_DIR="$MPTDC_INNOVUS_WORK/$PVS_RUN"
DRIVER_LOG="/tmp/${PVS_RUN}.driver.log"

CD_RC=99
PULL_RC=99
CONFIG_NAME_RC=99
CONFIG_EMAIL_RC=99
PVS_DRIVER_RC=99

cd "$REPO"
CD_RC=$?
if [[ "$CD_RC" -eq 0 ]]; then
  git pull --ff-only origin SPADMIC_test
  PULL_RC=$?
  git config --local user.name "Karim SABRA"
  CONFIG_NAME_RC=$?
  git config --local user.email "ksabra@lyoelectrosrv01.in2p3.fr"
  CONFIG_EMAIL_RC=$?

  EXPECTED_HEAD="$(git rev-parse HEAD 2>/dev/null)"
  ORIGIN_HEAD="$(git rev-parse refs/remotes/origin/SPADMIC_test 2>/dev/null)"
  TRACKED_STATUS="$(git status --short --untracked-files=no 2>/dev/null)"
  RO_GDS_SHA="$(sha256sum "$RO_GDS" 2>/dev/null | awk '{print $1}')"

  echo "CD_RC=$CD_RC"
  echo "PULL_RC=$PULL_RC"
  echo "CONFIG_NAME_RC=$CONFIG_NAME_RC"
  echo "CONFIG_EMAIL_RC=$CONFIG_EMAIL_RC"
  echo "EXPECTED_HEAD=$EXPECTED_HEAD"
  echo "ORIGIN_HEAD=$ORIGIN_HEAD"
  echo "TRACKED_STATUS=${TRACKED_STATUS:-CLEAN}"
  echo "SOURCE_CKPT=$SOURCE_CKPT"
  echo "RO_GDS=$RO_GDS"
  echo "RO_GDS_SHA=$RO_GDS_SHA"
  echo "PVS_RUN=$PVS_RUN"

  if [[ "$PULL_RC" -eq 0 && "$CONFIG_NAME_RC" -eq 0 &&
        "$CONFIG_EMAIL_RC" -eq 0 && "$EXPECTED_HEAD" == "$ORIGIN_HEAD" &&
        -z "$TRACKED_STATUS" && -d "$SOURCE_CKPT" &&
        "$RO_GDS_SHA" == "$EXPECTED_RO_GDS_SHA" ]]; then
    bash MPTDC/scripts/pvs/server_run_mptdc_ro6_recovery_pvs.sh \
      --pnr-run-id "$PNR_RUN" \
      --run-id "$PVS_RUN" \
      --expected-head "$EXPECTED_HEAD" \
      --ro-gds "$RO_GDS" \
      --diagnostic-antenna-exception \
      --diagnostic-ro-compositional \
      2>&1 | tee "$DRIVER_LOG"
    PVS_DRIVER_RC=${PIPESTATUS[0]}
  else
    echo "STOP_HERE_DO_NOT_CONTINUE: sync, identity, source, or RO GDS preflight failed"
  fi
else
  echo "STOP_HERE_DO_NOT_CONTINUE: repository directory is unavailable"
fi

echo "===== PVS DRIVER SUMMARY ====="
echo "PVS_DRIVER_RC=$PVS_DRIVER_RC"
echo "PVS_RUN=$PVS_RUN"
echo "PVS_DIR=$PVS_DIR"

for relative in \
  reports/operator_gate_pvs_prepare.rpt \
  reports/pvs_prepared_inputs.rpt \
  reports/tap_pin_contract.rpt \
  manifests/pvs_input_hashes.rpt \
  manifests/pvs_diagnostic_scope.rpt \
  reports/operator_gate_pvs_template_audit.rpt \
  reports/operator_gate_pvs_drc_base.rpt \
  reports/pvs_recovery_base_drc_classification.rpt \
  manifests/pvs_recovery_base_drc_classification_scope.rpt \
  reports/pvs_drc_base_nonzero_rules.tsv \
  reports/lvs_source_filter.rpt \
  reports/pvs_lvs_tool_status.rpt \
  reports/pvs_lvs_status.rpt \
  reports/pvs_lvs_result_scan.txt \
  reports/operator_gate_pvs_lvs.rpt; do
  echo "===== $relative ====="
  if [[ -s "$PVS_DIR/$relative" ]]; then
    cat "$PVS_DIR/$relative"
  else
    echo "MISSING=$PVS_DIR/$relative"
  fi
done

for log in prepare_pvs_inputs.log operator_template_audit.log \
           operator_drc_base.log operator_base_drc_classification.log \
           operator_lvs.log; do
  echo "===== LOG TAIL: $log ====="
  if [[ -s "$PVS_DIR/logs/$log" ]]; then
    tail -n 200 "$PVS_DIR/logs/$log"
  else
    echo "MISSING=$PVS_DIR/logs/$log"
  fi
done

echo "FINAL_HEAD=$(git -C "$REPO" rev-parse HEAD 2>/dev/null)"
```

The completed stage met the collection contract:
`PVS_DRIVER_RC=0`, attributable base classification `PASS` with zero
non-antenna rules, `PVS_RC=0`, and
`RAW_FULL_TOP_LVS_STATUS=MISMATCH_PENDING_BOUNDARY_PROOF`. The raw
`MISMATCH` is expected collection evidence for the RO boundary proof, not an
LVS pass.

## Continuation Order

First run this live identity and synchronization gate in the foreground. The
supplied server transcripts show login `ksabra` and host
`lyoelectrosrv01.in2p3.fr`; this command is the authoritative check for the
current shell. It sets only repository-local Git identity and returns control
instead of terminating the SSH session on failure.

```bash
set +e

REPO=/home/validmgr/ksabra/2026_SPAD/SPADMIC
EXPECTED_LOGIN=ksabra
EXPECTED_HOST=lyoelectrosrv01.in2p3.fr
EXPECTED_GIT_NAME="Karim SABRA"
EXPECTED_GIT_EMAIL=ksabra@lyoelectrosrv01.in2p3.fr
IDENTITY_SYNC_STATUS=FAIL
CD_RC=99
PULL_RC=99

LOGIN_NAME="$(id -un 2>/dev/null)"
HOST_FQDN="$(hostname -f 2>/dev/null)"
cd "$REPO"
CD_RC=$?
if [[ "$CD_RC" -eq 0 ]]; then
  git pull --ff-only origin SPADMIC_test
  PULL_RC=$?
  git config --local user.name "$EXPECTED_GIT_NAME"
  CONFIG_NAME_RC=$?
  git config --local user.email "$EXPECTED_GIT_EMAIL"
  CONFIG_EMAIL_RC=$?
  BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
  HEAD_SHA="$(git rev-parse HEAD 2>/dev/null)"
  ORIGIN_SHA="$(git rev-parse refs/remotes/origin/SPADMIC_test 2>/dev/null)"
  TRACKED_STATUS="$(git status --short --untracked-files=no 2>/dev/null)"
  GIT_NAME="$(git config --local user.name 2>/dev/null)"
  GIT_EMAIL="$(git config --local user.email 2>/dev/null)"
  if [[ "$LOGIN_NAME" == "$EXPECTED_LOGIN" &&
        "$HOST_FQDN" == "$EXPECTED_HOST" && "$PULL_RC" -eq 0 &&
        "$CONFIG_NAME_RC" -eq 0 && "$CONFIG_EMAIL_RC" -eq 0 &&
        "$BRANCH" == SPADMIC_test && "$HEAD_SHA" == "$ORIGIN_SHA" &&
        -z "$TRACKED_STATUS" && "$GIT_NAME" == "$EXPECTED_GIT_NAME" &&
        "$GIT_EMAIL" == "$EXPECTED_GIT_EMAIL" ]]; then
    IDENTITY_SYNC_STATUS=PASS
  else
    echo "STOP_HERE_DO_NOT_CONTINUE: identity or repository synchronization failed"
  fi
else
  echo "STOP_HERE_DO_NOT_CONTINUE: repository directory is unavailable"
fi

echo "LOGIN_NAME=$LOGIN_NAME"
echo "HOST_FQDN=$HOST_FQDN"
echo "CD_RC=$CD_RC"
echo "PULL_RC=$PULL_RC"
echo "BRANCH=${BRANCH:-MISSING}"
echo "HEAD_SHA=${HEAD_SHA:-MISSING}"
echo "ORIGIN_SHA=${ORIGIN_SHA:-MISSING}"
echo "TRACKED_STATUS=${TRACKED_STATUS:-CLEAN}"
echo "GIT_NAME=${GIT_NAME:-MISSING}"
echo "GIT_EMAIL=${GIT_EMAIL:-MISSING}"
echo "IDENTITY_SYNC_STATUS=$IDENTITY_SYNC_STATUS"
```

1. Preserve the completed anchor run and V13 source unchanged. No PG repair is
   part of this expedited handoff.
2. Reuse exact source run
   `20260901_160902_mptdc_v13_pg15_compositional_pvs` and tracked snapshot
   `20260901_160902_mptdc_v13_pg15_compositional_pvs_04_lvs`. Require
   `PNR_CANDIDATE_KIND=TIE1_MINAREA_CLEAN_COMPOSITIONAL`, candidate/hash
   gates `PASS`, attributable base DRC with zero non-antenna rules, and
   the expected raw LVS mismatch collection. Keep every antenna count visible.
3. Run the boundary proof below only after `IDENTITY_SYNC_STATUS=PASS`:

```bash
set +e
SOURCE_PVS_RUN=20260901_160902_mptdc_v13_pg15_compositional_pvs
STANDALONE_PVS_RUN=20260827_mptdc_ro6_standalone_lvs_vddfix_150520
BOUNDARY_RUN="$(date +%Y%m%d_%H%M%S)_mptdc_v13_ro6_boundary_lvs"
EXPECTED_HEAD="$(git rev-parse HEAD 2>/dev/null)"
BOUNDARY_DRIVER_RC=99

if [[ -n "$SOURCE_PVS_RUN" ]]; then
  bash MPTDC/scripts/pvs/server_run_mptdc_ro6_boundary_lvs.sh \
    --source-pvs-run-id "$SOURCE_PVS_RUN" \
    --standalone-pvs-run-id "$STANDALONE_PVS_RUN" \
    --run-id "$BOUNDARY_RUN" \
    --expected-head "$EXPECTED_HEAD" \
    2>&1 | tee "/tmp/${BOUNDARY_RUN}.driver.log"
  BOUNDARY_DRIVER_RC=${PIPESTATUS[0]}
else
  echo "STOP_HERE_DO_NOT_CONTINUE: source run ID is missing"
fi

echo "BOUNDARY_DRIVER_RC=$BOUNDARY_DRIVER_RC"
echo "SOURCE_PVS_RUN=$SOURCE_PVS_RUN"
echo "BOUNDARY_RUN=$BOUNDARY_RUN"
for report in operator_gate_pvs_ro6_boundary_lvs.rpt \
              pvs_lvs_ro6_boundary_blackbox_status.rpt \
              pvs_lvs_status.rpt \
              operator_gate_pvs_compositional_lvs.rpt; do
  echo "===== $report ====="
  if [[ -s "/sim/ksabra/SPADMIC_work/innovus/$BOUNDARY_RUN/reports/$report" ]]; then
    cat "/sim/ksabra/SPADMIC_work/innovus/$BOUNDARY_RUN/reports/$report"
  else
    echo "MISSING=/sim/ksabra/SPADMIC_work/innovus/$BOUNDARY_RUN/reports/$report"
  fi
done
echo "===== LOG TAIL ====="
tail -n 200 "/tmp/${BOUNDARY_RUN}.driver.log" 2>/dev/null
echo "FINAL_HEAD=$(git rev-parse HEAD 2>/dev/null)"
```

4. A boundary driver RC of zero is not enough. Proceed only for explicit
   `MATCH`, `BOUNDARY_REMAINDER_CLASS=NONE_MATCH`,
   `DECISION=PASS_COMPOSITIONAL_LVS`, and
   `NEXT_STAGE=PVS_RO6_MONOLITHIC_FULL_TOP_LVS`. If it reports
   `RO6_PG_OPEN_ONLY` / `PASS_PG_REPAIR_REQUIRED`, stop and run only
   `server_run_mptdc_ro6_pg_endpoint_probe.sh` from the V13 source in a fresh
   Innovus process. Do not run monolithic LVS or density and do not promote an
   endpoint-anchor or long-prune checkpoint.
5. Only after the exact boundary `MATCH`, run the strict monolithic block in
   the same login shell. After a reconnect, restore `BOUNDARY_RUN` from its
   published ID and rerun the identity/synchronization gate first:

```bash
set +e
SOURCE_PVS_RUN=20260901_160902_mptdc_v13_pg15_compositional_pvs
SOURCE_PVS_EVIDENCE_ID=20260901_160902_mptdc_v13_pg15_compositional_pvs_04_lvs
BOUNDARY_RUN="${BOUNDARY_RUN:-}"
STANDALONE_PVS_RUN=20260827_mptdc_ro6_standalone_lvs_vddfix_150520
MONOLITHIC_RUN="$(date +%Y%m%d_%H%M%S)_mptdc_v13_ro6_monolithic_lvs"
EXPECTED_HEAD="$(git rev-parse HEAD 2>/dev/null)"
MONOLITHIC_DRIVER_RC=99

if [[ -n "$BOUNDARY_RUN" ]]; then
  bash MPTDC/scripts/pvs/server_run_mptdc_ro6_monolithic_lvs.sh \
    --source-pvs-run-id "$SOURCE_PVS_RUN" \
    --source-pvs-evidence-id "$SOURCE_PVS_EVIDENCE_ID" \
    --boundary-pvs-run-id "$BOUNDARY_RUN" \
    --standalone-pvs-run-id "$STANDALONE_PVS_RUN" \
    --run-id "$MONOLITHIC_RUN" \
    --expected-head "$EXPECTED_HEAD" \
    2>&1 | tee "/tmp/${MONOLITHIC_RUN}.driver.log"
  MONOLITHIC_DRIVER_RC=${PIPESTATUS[0]}
else
  echo "STOP_HERE_DO_NOT_CONTINUE: restore the published boundary run ID"
fi

echo "MONOLITHIC_DRIVER_RC=$MONOLITHIC_DRIVER_RC"
echo "SOURCE_PVS_RUN=$SOURCE_PVS_RUN"
echo "BOUNDARY_RUN=$BOUNDARY_RUN"
echo "MONOLITHIC_RUN=$MONOLITHIC_RUN"
for relative in \
  reports/lvs_source_external_ro6.rpt \
  reports/pvs_ro6_monolithic_lvs_status.rpt \
  reports/operator_gate_pvs_monolithic_lvs.rpt \
  reports/mptdc_lvs_drc_handoff_status.rpt \
  manifests/pvs_ro6_monolithic_lvs_inputs.rpt; do
  echo "===== $relative ====="
  if [[ -s "/sim/ksabra/SPADMIC_work/innovus/$MONOLITHIC_RUN/$relative" ]]; then
    cat "/sim/ksabra/SPADMIC_work/innovus/$MONOLITHIC_RUN/$relative"
  else
    echo "MISSING=/sim/ksabra/SPADMIC_work/innovus/$MONOLITHIC_RUN/$relative"
  fi
done
echo "===== DRIVER LOG TAIL ====="
tail -n 200 "/tmp/${MONOLITHIC_RUN}.driver.log" 2>/dev/null
echo "===== PVS LOG TAIL ====="
tail -n 200 "/sim/ksabra/SPADMIC_work/innovus/$MONOLITHIC_RUN/logs/pvs_ro6_monolithic_lvs.log" 2>/dev/null
echo "FINAL_HEAD=$(git rev-parse HEAD 2>/dev/null)"
```

6. A monolithic driver RC of zero is not enough. Accept LVS at signoff proof
   level only for `MONOLITHIC_LVS_STATUS=MATCH`, `CLS_RUN_RESULT=MATCH`,
   `LVS_BLACKBOXED_CELL_COUNT=0`, `LVS_HCELL_STATUS=NOT_USED`,
   `CELLS_WHICH_MISMATCH=0`, `TOP_59_PIN_MATCH_STATUS=PASS`,
   `RO6_19_PIN_MATCH_STATUS=PASS`, `SHORT_OPEN_EVIDENCE_STATUS=PASS`, and
   `LVS_SIGNOFF_ELIGIBLE=YES`. The block remains
   `FINAL_PHYSICAL_SIGNOFF_READY=NO` because PG15 and the accepted antenna
   exception are independent open gates.
7. Only after the published monolithic `MATCH`, run density in the same login
   shell. After a reconnect, restore `BOUNDARY_RUN` and `MONOLITHIC_RUN` from
   their exact published IDs and rerun the identity/synchronization gate:

```bash
set +e
SOURCE_PVS_RUN=20260901_160902_mptdc_v13_pg15_compositional_pvs
SOURCE_PVS_EVIDENCE_ID=20260901_160902_mptdc_v13_pg15_compositional_pvs_04_lvs
BOUNDARY_RUN="${BOUNDARY_RUN:-}"
STANDALONE_PVS_RUN=20260827_mptdc_ro6_standalone_lvs_vddfix_150520
MONOLITHIC_RUN="${MONOLITHIC_RUN:-}"
DENSITY_RUN="$(date +%Y%m%d_%H%M%S)_mptdc_v13_ro6_density"
EXPECTED_HEAD="$(git rev-parse HEAD 2>/dev/null)"
DENSITY_DRIVER_RC=99

if [[ -n "$BOUNDARY_RUN" && -n "$MONOLITHIC_RUN" ]]; then
  bash MPTDC/scripts/pvs/server_run_mptdc_ro6_density_after_boundary.sh \
    --source-pvs-run-id "$SOURCE_PVS_RUN" \
    --source-pvs-evidence-id "$SOURCE_PVS_EVIDENCE_ID" \
    --boundary-pvs-run-id "$BOUNDARY_RUN" \
    --standalone-pvs-run-id "$STANDALONE_PVS_RUN" \
    --monolithic-pvs-run-id "$MONOLITHIC_RUN" \
    --run-id "$DENSITY_RUN" \
    --expected-head "$EXPECTED_HEAD" \
    2>&1 | tee "/tmp/${DENSITY_RUN}.driver.log"
  DENSITY_DRIVER_RC=${PIPESTATUS[0]}
else
  echo "STOP_HERE_DO_NOT_CONTINUE: restore boundary and monolithic run IDs"
fi

echo "DENSITY_DRIVER_RC=$DENSITY_DRIVER_RC"
echo "MONOLITHIC_RUN=$MONOLITHIC_RUN"
echo "DENSITY_RUN=$DENSITY_RUN"
for report in operator_gate_pvs_drc_density.rpt \
              pvs_density_delta_classification.rpt \
              pvs_drc_density_status.rpt \
              pvs_drc_density_nonzero_rules.tsv; do
  echo "===== $report ====="
  if [[ -s "/sim/ksabra/SPADMIC_work/innovus/$DENSITY_RUN/reports/$report" ]]; then
    cat "/sim/ksabra/SPADMIC_work/innovus/$DENSITY_RUN/reports/$report"
  else
    echo "MISSING=/sim/ksabra/SPADMIC_work/innovus/$DENSITY_RUN/reports/$report"
  fi
done
echo "===== LOG TAIL ====="
tail -n 200 "/tmp/${DENSITY_RUN}.driver.log" 2>/dev/null
echo "FINAL_HEAD=$(git rev-parse HEAD 2>/dev/null)"
```

8. Accept density only as `PASS_NON_ANTENNA_DENSITY_CLEAN`. Any other
   classification remains published density debt.
9. Update this gate matrix with the exact PVS run IDs, hashes, report-level
   outcomes, and remaining owner actions. Timing, power integrity, final export,
   and PG15 remain separate before any signoff claim.

## Handoff Gate Matrix

| Gate | Current evidence | Acceptance | Current state |
| --- | --- | --- | --- |
| Innovus geometry/regular routing | V13 replay | DRC `0`, shorts `0`, regular connectivity `0` | `PASS` |
| Innovus special PG | V13 replay | zero dangling VDD/VSS endpoints | `FAIL_15_DANGLING` |
| PVS base non-antenna DRC | source PVS run | zero non-antenna rules | `PASS` |
| PVS antenna | source PVS run | project-owner exception only | `136`, accepted policy exception, not tool-clean |
| Raw full-top LVS | source PVS run | explicit `MATCH` | exact `380:2` RO abstraction `MISMATCH` |
| Boundary LVS | next run | explicit boundary `MATCH`, no residue | `PENDING` |
| Monolithic full-top LVS | after boundary | explicit no-HCell/no-blackbox `MATCH` | `PENDING` |
| Density DRC | after monolithic | `PASS_NON_ANTENNA_DENSITY_CLEAN` | `PENDING` |
| Final physical readiness | all applicable gates | all required signoff evidence complete | `NO` |

Monolithic `LVS_SIGNOFF_ELIGIBLE=YES` means the exact GDS/source/CDL
comparison is proven. It does not override the independent PG15, antenna,
density, timing, IR/EM, extraction, or final-export gates.

## Stop Conditions

Stop and preserve the accepted V13 replay checkpoint if any of these occurs:

- source checkpoint path or SHA-256 differs;
- login, hostname, repository-local Git identity, branch, tracked status, or
  local/remote HEAD differs from the identity gate;
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
- the boundary proof does not publish the exact
  `PVS_RO6_MONOLITHIC_FULL_TOP_LVS` next stage;
- monolithic control contains `-hcell`, `lvs_black_box`, positional bus
  mapping, global-port promotion, any extra schematic/layout path, or any
  source/GDS/CDL hash drift;
- monolithic LVS lacks one explicit `MATCH`, has any blackboxed or mismatched
  cell, lacks exact top `59:59` or RO `19:19` pin matches, reports a missing
  instance, or has nonempty short/open evidence;
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
