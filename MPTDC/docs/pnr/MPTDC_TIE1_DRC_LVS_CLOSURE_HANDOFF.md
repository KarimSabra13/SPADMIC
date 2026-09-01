# MPTDC Tie1 DRC/LVS Closure Handoff

Author: Karim Sabra

Status: active execution checkpoint for `mptdc_axis_core`

Last evidence review: 2026-09-01

## Decision

The V13 minimum-area repair is accepted for continued closure. It passed once
as an isolated trial and passed again as a canonical replay from the immutable
pre-repair Tie1 checkpoint. The replay is the only accepted continuation
checkpoint.

PG analysis has now produced four published diagnostics against that exact
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
  connectivity remain `0`, so the one-residual V2 checkpoint is rejected.

No PG-mutated candidate has therefore been accepted. The accepted continuation
source remains the V13 replay, never a rejected diagnostic checkpoint. The next
action is one V3 long-prune trial from V13. V3 recognizes both proven marker
transitions and permits deletion of exactly two residual MET1 corewires only
when both live objects match their complete historical database fingerprints.

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
| Prior PVS diagnostic | `20260831_mptdc_tie1_lvs_density_131326` | base DRC `136`, antenna-only classification, LVS `MISMATCH`; predates V13 |
| Historical PG topology witness | `20260825_mptdc_bufftap0_halo10_physical_130313` | identifies the 13 source handles and both exact exposed VSS/MET1 corewires |
| Proven RO ring primitive | `20260828_mptdc_free_pnr_stripevaluefix_151756_u50` | two RO rings, 16 new `blockRing` sWires, VDD delta `+8`, VSS delta `+8` |
| Standalone RO LVS proof | `20260827_mptdc_ro6_standalone_lvs_vddfix_150520` | explicit `MATCH`, zero blackboxes, immutable RO GDS/CDL hashes |

The replay restored the original Tie1 source checkpoint, not the trial output,
then reapplied the exact V13 operation in one fresh Innovus process. This is why
the different trial and replay candidate hashes are expected: each saved
database is a separate run product, while the source hash, edit contract, object
delta, and verification tuple agree. V1 and V2 are ancestry evidence only and
are never legal inputs to V3.

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
| Long-prune V3 | dual-residual contract implemented and locally tested; no Cadence result yet | `NOT_RUN` |
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

The V2 final report contains exactly these north and south MET1 markers. The
complete deterministic sequence is therefore 13 source-handle deletions
followed by two exact exposed-corewire deletions.

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
only authorized next branch is long-prune V3.

V3 requires all of the following before mutation:

- accepted V13 source path and SHA-256;
- corrected rejected ring probe
  `20260901_122444_mptdc_tie1_pg_ro_ring_probe_v2`;
- failed V1 prune `20260901_124659_mptdc_tie1_pg_long_prune_trial` with exact
  `12 attempts / 11 successes`, final DRC `0`, and exactly the two observed
  residual markers;
- failed V2 prune `20260901_131741_mptdc_tie1_pg_long_prune_v2_trial`, whose
  recursively validated ancestry names that exact V1 run, whose source is the
  same immutable V13 checkpoint, and whose final detailed report contains only
  `VSS|MET1|124.160|723.520` and `VSS|MET1|204.160|150.080`;
- exact V2 result `13 attempts / 12 gate successes`, DRC `0`, shorts `0`,
  regular connectivity `0`, source-transition status `FAIL`, no residual
  deletion, and candidate `NOT_SELECTED`;
- exact source preflight `15 markers / 13 handles / 2 shared`;
- literal authorization
  `EXACT_V13_PG15_13_HANDLE_PLUS_TWO_EXPOSED_MET1_COREWIRES_PRUNE_V3`.

The mutation contract is:

1. Delete the same 13 source sWire handles by exact live handle. After every
   delete, run DRC, short, regular-connectivity, and detailed special checks.
2. Compare the full sorted marker fingerprint, not only the marker count.
   Deletions 1 through 11 must remove their exact source keys. Deletion 12 may
   replace only `VSS|METTP|125.160|721.750` with
   `VSS|MET1|124.160|723.520`. Deletion 13 must replace only
   `VSS|METTP|205.160|158.320` with
   `VSS|MET1|204.160|150.080`.
3. Before either residual mutation, require exactly one north candidate and one
   south candidate. Each must match net `VSS`, layer `MET1`, shape `corewire`,
   status `routed`, width `0.8`, geometry type `pathSeg`, and its exact points,
   box, and length within `0.002 um`. The two live handles must be distinct.
4. Delete the north and then south live handles with `dbDeleteObj`; there is no
   area fallback. Each step must remove exactly one pre-existing handle, add no
   sWire or via handle, preserve DRC `0`, shorts `0`, and regular connectivity
   `0`, and produce the exact next marker fingerprint.
5. Require final VDD/VSS sWire inventories `445/409`, exact deltas `-5/-10`
   from source inventories `450/419`, and an unchanged via-handle fingerprint.
6. A passing gate must report source prune `13/13`, residual prune `2/2`, total
   prune `15/15`, source transition `PASS`, residual policy
   `EXACT_TWO_EXPOSED_VSS_MET1_COREWIRES_V3`, route gate `1`, unchanged
   Tie1/filler/placement invariants, `CANDIDATE_CHECKPOINT_STATUS=PASS`, and
   `DECISION=PASS_CONTINUE`.
7. Replay the same operation from V13 in a separate Innovus process. The trial
   checkpoint remains ancestry evidence and is never the replay input.

This is a closure-first removal of disconnected PG branches and may reduce PG
redundancy. Passing Innovus connectivity does not prove LVS or power integrity;
attributable PVS and subsequent PG review remain mandatory.

Never set `MPTDC_PG_DANGLING_ALLOW_LONG_DELETE=1`, delete by area, use a broad
`sroute`, or invoke `ecoRoute`, `routeDesign`, or any global optimizer in this
ladder. No stage repairs or suppresses antenna results.

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
V3 fixes that bookkeeping by recording the observed marker set before deciding
step status, contracts the second transition explicitly, and still relaxes no
physical gate.

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
   PG replay gate: legacy short-delete, RO ring-stitch, or exact long-prune.
   It verifies replay ancestry, checkpoint content hash, DRC/connectivity
   tuple, and physical invariants before preparing GDS/source/CDL inputs.
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
  both exact source-marker transitions, two contracted exposed-corewire
  lookups, exact-handle V3 deletion, and sWire/via handle-delta auditing;
- `server_run_mptdc_tie1_closure_stage.sh`: isolated probe/trial/replay stages,
  immutable V13/probe/failed-V1/failed-V2 ancestry checks, V3 authorization,
  dual-residual report parsing, and independent physical gates;
- `server_run_mptdc_ro6_recovery_pvs.sh`: exactly-one replay-gate selection and
  hash-guarded compositional PVS intake that recursively revalidates V1 and V2
  failure evidence and requires matching V3 trial/replay ancestry and object
  invariants;
- `test_pg_ro_ring_checkpoint_tools.tcl`, the Tie1 closure-driver test, and the
  PVS recovery-driver test: exact 15/13/2 topology, both source-marker
  transitions, both exact residual objects, 15/15 completion, sWire/via
  invariants, missing-prior and wrong-generation rejection, rejected-checkpoint
  hash-drift rejection, canonical replay, and PVS candidate attribution.

Local validation on 2026-09-01 passed:

```text
MPTDC_PG_RO_RING_CHECKPOINT_TOOLS_TEST=PASS
MPTDC_PG_DANGLING_CHECKPOINT_TOOLS_TEST=PASS
MPTDC_RO_PG_BLOCK_RING_CONTRACT_TEST=PASS
MPTDC_TIE1_CLOSURE_STAGE_DRIVER_TEST=PASS
MPTDC_RO6_RECOVERY_PVS_DRIVER_TEST=PASS
```

These are static and fixture proofs. They do not substitute for a foreground
Innovus V3 trial and do not change the accepted V13 evidence.

## Exact Next Command

Run only the V3 long-prune trial next. Use this foreground block on
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
  LONG_PRUNE_V3_RUN="$(date +%Y%m%d_%H%M%S)_mptdc_tie1_pg_long_prune_v3_trial"
  echo "LONG_PRUNE_V3_RUN=$LONG_PRUNE_V3_RUN"

  bash MPTDC/pnr/scripts/server_run_mptdc_tie1_closure_stage.sh \
    --stage tie1-pg-long-prune-trial \
    --source-tie1-run-id 20260831_mptdc_tie1_filler_ecoroute_reconciled_131006 \
    --source-minarea-replay-run-id 20260831_175532_mptdc_tie1_minarea_clearance_v13_replay \
    --source-pg-probe-run-id 20260901_122444_mptdc_tie1_pg_ro_ring_probe_v2 \
    --source-pg-prior-trial-run-id 20260901_131741_mptdc_tie1_pg_long_prune_v2_trial \
    --run-id "$LONG_PRUNE_V3_RUN" \
    --expected-head "$CURRENT_HEAD"

  LONG_PRUNE_V3_RC=$?
  echo "LONG_PRUNE_V3_RC=$LONG_PRUNE_V3_RC"
  echo "LONG_PRUNE_V3_RUN=$LONG_PRUNE_V3_RUN"

  LONG_PRUNE_V3_DIR="/sim/ksabra/SPADMIC_work/innovus/$LONG_PRUNE_V3_RUN"
  cat "$LONG_PRUNE_V3_DIR/reports/operator_gate_tie1_pg_long_prune_trial.rpt" 2>/dev/null
  cat "$LONG_PRUNE_V3_DIR/reports/pg_ro_ring_repair_status.rpt" 2>/dev/null
  cat "$LONG_PRUNE_V3_DIR/reports/pg_ro_after_prune_12_special_detailed.rpt" 2>/dev/null
  cat "$LONG_PRUNE_V3_DIR/reports/pg_ro_after_prune_13_special_detailed.rpt" 2>/dev/null
  cat "$LONG_PRUNE_V3_DIR/reports/pg_ro_after_source_prune_special_detailed.rpt" 2>/dev/null
  cat "$LONG_PRUNE_V3_DIR/reports/pg_ro_after_residual_prune_01_special_detailed.rpt" 2>/dev/null
  cat "$LONG_PRUNE_V3_DIR/reports/pg_ro_after_residual_prune_02_special_detailed.rpt" 2>/dev/null
  cat "$LONG_PRUNE_V3_DIR/reports/pg_ro_final_verify_special_detailed.rpt" 2>/dev/null
  cat "$LONG_PRUNE_V3_DIR/reports/pg_ro_after_long_prune_verify_drc.rpt" 2>/dev/null
  cat "$LONG_PRUNE_V3_DIR/reports/checkpoint_repair_status.rpt" 2>/dev/null
  echo "FINAL_HEAD=$(git rev-parse HEAD 2>/dev/null)"
else
  echo "STOP: pull must pass and checkout must be tracked-clean and equal to origin/SPADMIC_test"
fi
```

Return the printed reports in full, including the driver summary above them.
Do not source the V1 or V2 candidate and do not manually edit the V3 output. A
nonzero wrapper return or `INNOVUS_RC=0` alone does not decide acceptance; the
operator gate and report-level checks do.

## Continuation Order

1. Run the V3 trial above from the accepted V13 replay. Require source prune
   `13/13`, exposed residual set `NORTH SOUTH`, residual prune `2/2`, total
   prune `15/15`, exact transition status `PASS`, final special connectivity
   `0`, DRC `0`, shorts `0`, regular connectivity `0`, unroutes `0`, route gate
   `1`, VDD/VSS sWire inventories `445/409`, deltas `-5/-10`, unchanged via
   handles, and unchanged Tie1/filler/placement invariants.
2. If and only if the trial publishes `DECISION=PASS_CONTINUE`, run
   `tie1-pg-long-prune-replay` in a fresh process, naming that trial with
   `--source-pg-trial-run-id`. Replay must restore V13, inherit the exact probe
   and failed-V2 ID from the trial, recursively recover the failed-V1 ancestry,
   and reproduce every V3 gate. Never use the trial checkpoint as replay input.
3. Run attributable PVS base DRC and raw LVS from the selected PG replay using
   `--diagnostic-antenna-exception --diagnostic-ro-compositional` and the exact
   standalone-proven RO GDS. Keep all antenna counts visible.
4. Run boundary LVS against that exact raw PVS run and standalone run
   `20260827_mptdc_ro6_standalone_lvs_vddfix_150520`. Require explicit
   compositional `MATCH`; process RC `0` is insufficient.
5. Run density DRC through `server_run_mptdc_ro6_density_after_boundary.sh`
   only after `PASS_COMPOSITIONAL_LVS`. Keep base DRC, density DRC, raw LVS,
   boundary LVS, and standalone LVS as separate evidence.
6. Requalify timing, power integrity, and final export separately before any
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
- the corrected ring probe, failed V1 evidence, or failed V2 evidence is
  missing, untracked, swapped, recursively inconsistent, or has a different
  source/checkpoint/result fingerprint;
- V3 lacks the literal authorization or attempts a ring, via, replacement,
  area deletion, broad PG route, or optimizer;
- an incremental marker set differs, including either deletion-12 or
  deletion-13 transition differing from its exact METTP-to-MET1 replacement;
- either residual query returns other than one object, the two candidates share
  a handle, or any net/layer/shape/status/width/type/box/points/length field
  differs from its contract;
- the source sequence is not `13/13`, residual sequence not `2/2`, or total not
  `15/15`;
- final VDD/VSS sWire inventories are not `445/409`, their deltas are not
  `-5/-10`, or the PG via-handle fingerprint changes;
- geometry DRC, shorts, regular connectivity, or route completeness regresses;
- Tie1 target/net counts, filler count, placement occupancy, or via fingerprint
  changes unexpectedly;
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
