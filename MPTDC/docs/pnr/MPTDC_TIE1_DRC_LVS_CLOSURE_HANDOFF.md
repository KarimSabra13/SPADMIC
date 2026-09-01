# MPTDC Tie1 DRC/LVS Closure Handoff

Author: Karim Sabra

Status: active execution checkpoint for `mptdc_axis_core`

Last evidence review: 2026-09-01

## Decision

The V13 minimum-area repair is accepted for continued closure. It passed once
as an isolated trial and passed again as a canonical replay from the immutable
pre-repair Tie1 checkpoint. The replay is the only accepted continuation
checkpoint.

The PG closure implementation is now present locally and unit-tested, but it
has not yet been run in Cadence against the V13 checkpoint. Consequently, no
PG candidate has been accepted and the state label below is unchanged. The
first server action is a disposable RO block-ring probe; its saved checkpoint
is evidence only and must never become the canonical source.

The current state label is:

```text
MPTDC_TIE1_V13_INNOVUS_DRC_CLEAN_PG15_OPEN_LVS_MISMATCH
```

This label is intentionally not a signoff claim. Fresh Innovus geometry DRC,
short, regular-connectivity, and route checks pass. Raw special-PG connectivity
still reports 15 dangling VDD/VSS endpoints. The last attributable PVS run was
made before V13, classified all 136 base-DRC results as antenna rules, and
reported an explicit LVS mismatch. Density DRC, timing requalification, and
final streamout qualification are not complete.

Process-antenna repair is outside this closure scope. Antenna results remain
visible as deferred debt; they are not deleted, waived, or relabelled clean.

## Accepted Evidence Lineage

| Role | Run or commit | Decision-bearing identity |
| --- | --- | --- |
| Immutable Tie1 source | `20260831_mptdc_tie1_filler_ecoroute_reconciled_131006` | checkpoint SHA-256 `a8ed5b0b684c0543ddd4e0a6d7dac96b82203f3e7319c443a04d003075d2d1c8` |
| V13 isolated trial | `20260831_174738_mptdc_tie1_minarea_clearance_v13_trial` | evidence commit `072d059645438fff54afbd81bd8f7cbd859e5497`; candidate SHA-256 `aebd16c6dd07605cb41329d3f3f3464b98e8a82f35b8b7fe747131f88e9a39d0` |
| V13 canonical replay | `20260831_175532_mptdc_tie1_minarea_clearance_v13_replay` | evidence commit `b61dfd1a6c476aa41cab43735a28199fa164bc05`; candidate SHA-256 `35fec60377b4fc7c08b83bf550ef457f7bdb3aa69580d8a749feb7a66fa4a7bf` |
| Prior PVS diagnostic | `20260831_mptdc_tie1_lvs_density_131326` | base DRC `136`, antenna-only classification, LVS `MISMATCH`; predates V13 |
| Historical PG topology witness | `20260825_mptdc_bufftap0_halo10_physical_130313` | identifies the 15 endpoints as 13 exact long MET3/METTP stripe handles |
| Proven RO ring primitive | `20260828_mptdc_free_pnr_stripevaluefix_151756_u50` | two RO rings, 16 new `blockRing` sWires, VDD delta `+8`, VSS delta `+8` |
| Standalone RO LVS proof | `20260827_mptdc_ro6_standalone_lvs_vddfix_150520` | explicit `MATCH`, zero blackboxes, immutable RO GDS/CDL hashes |

The replay restored the original Tie1 source checkpoint, not the trial output,
then reapplied the exact V13 operation in one fresh Innovus process. This is why
the different trial and replay candidate hashes are expected: each saved
database is a separate run product, while the source hash, edit contract, object
delta, and verification tuple agree.

Primary evidence:

- [accepted Tie1 source gate](../server_snapshots/innovus/20260831_mptdc_tie1_filler_ecoroute_reconciled_131006/reports/operator_gate_tie1_insertion_trial.rpt)
- [V13 trial gate](../server_snapshots/innovus/20260831_174738_mptdc_tie1_minarea_clearance_v13_trial/reports/operator_gate_tie1_minarea_endext_trial.rpt)
- [V13 replay gate](../server_snapshots/innovus/20260831_175532_mptdc_tie1_minarea_clearance_v13_replay/reports/operator_gate_tie1_minarea_endext_replay.rpt)
- [V13 replay object audit](../server_snapshots/innovus/20260831_175532_mptdc_tie1_minarea_clearance_v13_replay/reports/tie1_min_area_fixed_wire_endext_replay_v13.rpt)
- [V13 replay wrapper gate](../server_snapshots/innovus/20260831_175532_mptdc_tie1_minarea_clearance_v13_replay/reports/checkpoint_repair_status.rpt)
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
| Special PG connectivity | 15 raw VDD/VSS dangling endpoints | `FAIL_OPEN` |
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

All stages require the exact RO instance set
`u_core_u_osc_fast_u_ro_tune4,u_core_u_osc_slow_u_ro_tune4`, source-marker
match tolerance `0.002 um`, minimum source-handle length `10.0 um`, maximum
ring-tail distance `20.0 um`, via readback half-area `0.400 um`, and ring
width/spacing/offset `2.0/1.0/2.0 um`. These values are written into every
trial and replay gate and are rechecked by the PVS intake.

1. `tie1-pg-ro-ring-probe` performs the exact 15-marker/13-handle/2-shared
   preflight, creates the two disposable rings, requires the exact `+8/+8`
   sWire effect, maps all 15 endpoints to perpendicular same-net ring sides
   within `20.0 um`, and reruns fresh DRC and regular connectivity. It performs
   no source-handle replacement, via insertion, or pruning. Its candidate is
   always `NOT_SELECTED`.
2. If the probe is clean and maps all 15 endpoints, run
   `tie1-pg-ro-ring-stitch-trial` with `--source-pg-probe-run-id` naming that
   tracked clean probe. It extends only endpoint handles that do not already
   cross a mapped ring side, preserves all other source handles, and invokes
   bounded `editPowerVia` candidates only at the 15 exact intersections.
   Every new handle and via effect is read back before the final gate.
3. Accept ring stitching only with two rings, VDD/VSS deltas `+8/+8`, all 15
   mappings and via effects proven, special dangling count `0`, DRC `0`,
   shorts `0`, regular connectivity `0`, unroutes `0`, and unchanged Tie1,
   filler, and placement invariants. Then replay it from V13 in another fresh
   process.
4. If ring creation, mapping, or post-ring geometry is rejected, use
   `tie1-pg-long-prune-trial` with `--source-pg-probe-run-id` naming that
   tracked rejected probe. It requires the literal authorization
   `EXACT_V13_PG15_13_HANDLE_LONG_PRUNE`, deletes only the 13 preflight handles
   by exact object handle, and reruns fresh DRC, regular connectivity, and
   dangling-marker accounting after every deletion. It has no area-delete
   fallback and does not create rings or vias. A passing prune is also replayed
   from V13 in a fresh process.

The ring probe is preferred because it restores an explicit local PG boundary
around each RO. Long prune is acceptable only as the documented closure-first
fallback: it removes the cut mesh branches and may reduce redundant PG
coverage, so the subsequent PVS and final PG evidence remain mandatory.

Never set `MPTDC_PG_DANGLING_ALLOW_LONG_DELETE=1`, delete by area, use a broad
`sroute`, or invoke `ecoRoute`, `routeDesign`, or any global optimizer in this
ladder. No stage repairs or suppresses antenna results.

### First Ring-Probe Result

The first server probe,
`20260901_115029_mptdc_tie1_pg_ro_ring_probe`, is immutable evidence at commit
`aa67bbcf4ba93baed225bd405634429f04b7cccd`. It restored the exact accepted V13
checkpoint hash `35fec60377b4fc7c08b83bf550ef457f7bdb3aa69580d8a749feb7a66fa4a7bf`
and reproduced the expected source tuple: geometry DRC `0`, shorts `0`, regular
connectivity `0`, route debt `0`, and the exact 15 VDD/VSS dangling markers.
No source replacement, power-via insertion, pruning, ring creation, or antenna
repair was attempted. The saved probe checkpoint is `NOT_SELECTED` and must
never be used as a source candidate.

The probe stopped in source-topology preflight because every marker returned
`exact_count:0`. This is an infrastructure rejection, not a physical rejection
of the ring topology. Code review found that the legacy matcher compared marker
coordinates directly against the raw restored-checkpoint `.pts` value, while
the ring tool's parser that accepts both nested `{{x y} {x y}}` and flat
`{x y x y}` encodings was applied only after a candidate had already matched.
The inherited path-length calculation also mishandled flat point lists. These
are confirmed code defects consistent with the all-zero result, but the first
probe did not report raw point encodings or source-object inventory, so their
server-side attribution remains pending the corrected probe. The local
regression had also mocked the candidate lookup, so it did not exercise this
boundary.

The corrective patch canonicalizes point lists and recomputes length before
endpoint comparison,
flattens wrapped DB object lists, supports multiple same-name net handles
without broadening the net scope, and records per-net inventory counts,
per-marker exact/nearby counts, and each accepted handle's point encoding. The
next action is therefore another disposable `tie1-pg-ro-ring-probe` from the
same immutable V13 replay. Do not run ring stitching or long pruning until that
new probe publishes one of the two explicitly accepted probe outcomes.

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
  disposable ring probe, bounded ring stitching, and authorized long-prune;
- `server_run_mptdc_tie1_closure_stage.sh`: isolated probe/trial/replay stages,
  immutable V13 ancestry checks, and independent physical gates;
- `server_run_mptdc_ro6_recovery_pvs.sh`: exactly-one replay-gate selection and
  hash-guarded compositional PVS intake for legacy delete, ring-stitch, or
  long-prune replay;
- `test_pg_ro_ring_checkpoint_tools.tcl`, the Tie1 closure-driver test, and the
  PVS recovery-driver test: exact 15/13/2 topology, both repair branches,
  canonical ancestry, negative authorization, and PVS candidate attribution.

Local validation on 2026-09-01 passed:

```text
MPTDC_PG_RO_RING_CHECKPOINT_TOOLS_TEST=PASS
MPTDC_PG_DANGLING_CHECKPOINT_TOOLS_TEST=PASS
MPTDC_RO_PG_BLOCK_RING_CONTRACT_TEST=PASS
MPTDC_TIE1_CLOSURE_STAGE_DRIVER_TEST=PASS
MPTDC_RO6_RECOVERY_PVS_DRIVER_TEST=PASS
```

These are static and fixture proofs. They do not substitute for the next
foreground Innovus probe, and they do not change the accepted V13 evidence.

## Exact Next Command

Run only the disposable RO ring probe next. Use this foreground block on
`lyoelectrosrv01`; it does not close the login shell on a failed guard.

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC

git pull --ff-only origin SPADMIC_test

CURRENT_HEAD="$(git rev-parse HEAD 2>/dev/null)"
ORIGIN_HEAD="$(git rev-parse refs/remotes/origin/SPADMIC_test 2>/dev/null)"
TRACKED_STATUS="$(git status --short --untracked-files=no 2>/dev/null)"

echo "CURRENT_HEAD=$CURRENT_HEAD"
echo "ORIGIN_HEAD=$ORIGIN_HEAD"
echo "TRACKED_STATUS=${TRACKED_STATUS:-CLEAN}"

if [[ "$CURRENT_HEAD" == "$ORIGIN_HEAD" && -z "$TRACKED_STATUS" ]]; then
  PG_RING_PROBE_RUN="$(date +%Y%m%d_%H%M%S)_mptdc_tie1_pg_ro_ring_probe"
  echo "PG_RING_PROBE_RUN=$PG_RING_PROBE_RUN"

  bash MPTDC/pnr/scripts/server_run_mptdc_tie1_closure_stage.sh \
    --stage tie1-pg-ro-ring-probe \
    --source-tie1-run-id 20260831_mptdc_tie1_filler_ecoroute_reconciled_131006 \
    --source-minarea-replay-run-id 20260831_175532_mptdc_tie1_minarea_clearance_v13_replay \
    --run-id "$PG_RING_PROBE_RUN" \
    --expected-head "$CURRENT_HEAD"

  PG_RING_PROBE_RC=$?
  echo "PG_RING_PROBE_RC=$PG_RING_PROBE_RC"
  echo "PG_RING_PROBE_RUN=$PG_RING_PROBE_RUN"

  PG_RING_PROBE_DIR="/sim/ksabra/SPADMIC_work/innovus/$PG_RING_PROBE_RUN"
  cat "$PG_RING_PROBE_DIR/reports/operator_gate_tie1_pg_ro_ring_probe.rpt" 2>/dev/null
  cat "$PG_RING_PROBE_DIR/reports/pg_ro_ring_repair_status.rpt" 2>/dev/null
  echo "FINAL_HEAD=$(git rev-parse HEAD 2>/dev/null)"
else
  echo "STOP: checkout must be tracked-clean and equal to origin/SPADMIC_test"
fi
```

Return both reports in full. The probe is expected to retain 15 dangling
markers because it intentionally does not stitch them. Do not launch either
mutating trial from a partial console summary.

## Continuation Order

1. Run `tie1-pg-ro-ring-probe` above. Require exact source topology `15/13/2`,
   two RO instances, two rings, 16 new ring sWires, VDD/VSS `+8/+8`, all 15
   mappings, post-ring DRC/regular clean, zero mutation attempts, and
   `CANDIDATE_CHECKPOINT_STATUS=NOT_SELECTED`.
2. On `RING_PROBE_READY`, run `tie1-pg-ro-ring-stitch-trial` from V13. On the
   explicit rejected-probe outcome, run `tie1-pg-long-prune-trial` instead.
   Pass the published probe ID through `--source-pg-probe-run-id`; the driver
   rejects a missing, untracked, swapped, or wrong-outcome probe gate. Never
   run both branches as competing accepted candidates.
3. Accept a mutating trial only with final special connectivity `0`, DRC `0`,
   shorts `0`, regular connectivity `0`, unroutes `0`, route gate `1`, and all
   Tie1/filler/placement invariants preserved.
4. Replay only the passing branch in a fresh process from V13. The trial
   checkpoint is ancestry evidence, never canonical replay input.
5. Run attributable PVS base DRC and raw LVS from the selected PG replay using
   `--diagnostic-antenna-exception --diagnostic-ro-compositional` and the exact
   standalone-proven RO GDS. Keep all antenna counts visible.
6. Run boundary LVS against that exact raw PVS run and standalone run
   `20260827_mptdc_ro6_standalone_lvs_vddfix_150520`. Require explicit
   compositional `MATCH`; process RC `0` is insufficient.
7. Run density DRC through `server_run_mptdc_ro6_density_after_boundary.sh`
   only after `PASS_COMPOSITIONAL_LVS`. Keep base DRC, density DRC, raw LVS,
   boundary LVS, and standalone LVS as separate evidence.
8. Requalify timing and final export separately before any signoff claim.

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
- the probe creates other than two rings or exact VDD/VSS `+8/+8` sWire deltas;
- the probe performs source replacement, via insertion, or pruning;
- a ring trial uses broad PG routing instead of exact mapped intersections;
- long prune lacks the literal authorization or attempts any non-handle or
  area-based deletion;
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
