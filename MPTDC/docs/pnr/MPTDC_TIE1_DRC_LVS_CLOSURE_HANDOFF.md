# MPTDC Tie1 DRC/LVS Closure Handoff

Author: Karim Sabra

Status: active execution checkpoint for `mptdc_axis_core`

Last evidence review: 2026-08-31

## Decision

The V13 minimum-area repair is accepted for continued closure. It passed once
as an isolated trial and passed again as a canonical replay from the immutable
pre-repair Tie1 checkpoint. The replay is the only accepted continuation
checkpoint.

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
| PVS LVS | prior attributable run: explicit `MISMATCH` | `FAIL` |
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

The next stage is read-only. For each marker it requires exactly one special
wire on the same net and layer whose first or last point matches within
`0.002 um`. It rejects missing or ambiguous matches, duplicate handles, and
segments longer than `10.0 um`. `MPTDC_PG_DANGLING_REQUIRE_ALL_ELIGIBLE=1` and
`MPTDC_PG_DANGLING_ALLOW_LONG_DELETE=0` prevent any partial or long-segment
deletion.

Only this exact analysis result authorizes a deletion trial:

```text
PG_DANGLING_STATUS=ANALYSIS_ONLY
PG_DANGLING_ELIGIBLE_COUNT=15
PG_DANGLING_ALL_ELIGIBLE_STATUS=PASS
PG_DANGLING_UNSAFE_LENGTH_COUNT=0
PG_DANGLING_DUPLICATE_HANDLE_COUNT=0
PG_DANGLING_MUTATION_ALLOWED=0
PG_DANGLING_DELETE_ATTEMPTS=0
PG_DANGLING_DELETE_SUCCESSES=0
FINAL_DANGLING_MARKER_COUNT=15
PG_DELETE_TRIAL_OUTCOME=ANALYSIS_ALL_ELIGIBLE
DECISION=PASS_CONTINUE
NEXT_STAGE=TIE1_PG_DANGLING_DELETE_TRIAL
```

Any other result keeps the accepted V13 replay checkpoint and forbids PG
mutation. Do not set `ALLOW_LONG_DELETE=1`, bypass the all-eligible gate, or
delete by area without a unique exact handle.

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

This strongly points to an RO hierarchy/hcell abstraction mismatch: the source
retained two abstract `RO_tune6` instances while PVS compared their device
content on the layout side. It is a triage hypothesis, not yet a proven root
cause. Do not change the Tie1 insertion or top pin contract based only on this
signature. After PG disposition and fresh streamout, first prove whether the
same signature remains, then audit the exact GDS cell name/hierarchy, hcell
mapping, and source abstraction as one attributable experiment.

Relevant reports:

- [base DRC gate](../server_snapshots/pvs/20260831_mptdc_tie1_lvs_density_131326_04_lvs/reports/operator_gate_pvs_drc_base.rpt)
- [base DRC classification](../server_snapshots/pvs/20260831_mptdc_tie1_lvs_density_131326_04_lvs/reports/pvs_recovery_base_drc_classification.rpt)
- [LVS source filter](../server_snapshots/pvs/20260831_mptdc_tie1_lvs_density_131326_04_lvs/reports/lvs_source_filter.rpt)
- [LVS comparison gate](../server_snapshots/pvs/20260831_mptdc_tie1_lvs_density_131326_04_lvs/reports/operator_gate_pvs_lvs.rpt)
- [LVS comparison summary](../server_snapshots/pvs/20260831_mptdc_tie1_lvs_density_131326_04_lvs/pvs_lvs/mptdc_axis_core_merged_pg_nonphys_dcells_cdl_ro6_pinfix_noattr_clean_findshorts_script/mptdc_axis_core_lvs.sum.cls)

The reported `PHYSICAL_TIE_INSTANCE_COUNT=8` in the source-filter inventory is
not by itself proof that 77 Tie1 cells were dropped. Innovus separately proves
85 inserted Tie1 nets and the LVS comparison does not list `LOGIC1DJIHD` as an
unmatched model. Treat that count as a hierarchy/accounting item to explain,
not as the current mismatch root cause.

## Exact Next Command

Run only the read-only PG analysis next. Use this foreground block on
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
  PG_ANALYZE_RUN="$(date +%Y%m%d_%H%M%S)_mptdc_tie1_pg_dangling_analysis"
  echo "PG_ANALYZE_RUN=$PG_ANALYZE_RUN"

  bash MPTDC/pnr/scripts/server_run_mptdc_tie1_closure_stage.sh \
    --stage tie1-pg-analyze \
    --source-tie1-run-id 20260831_mptdc_tie1_filler_ecoroute_reconciled_131006 \
    --source-minarea-replay-run-id 20260831_175532_mptdc_tie1_minarea_clearance_v13_replay \
    --run-id "$PG_ANALYZE_RUN" \
    --expected-head "$CURRENT_HEAD"

  PG_ANALYZE_RC=$?
  echo "PG_ANALYZE_RC=$PG_ANALYZE_RC"
  echo "PG_ANALYZE_RUN=$PG_ANALYZE_RUN"

  PG_ANALYZE_DIR="/sim/ksabra/SPADMIC_work/innovus/$PG_ANALYZE_RUN"
  cat "$PG_ANALYZE_DIR/reports/operator_gate_tie1_pg_dangling_analysis.rpt" 2>/dev/null
  cat "$PG_ANALYZE_DIR/reports/pg_dangling_analysis_status.rpt" 2>/dev/null
  echo "FINAL_HEAD=$(git rev-parse HEAD 2>/dev/null)"
else
  echo "STOP: checkout must be tracked-clean and equal to origin/SPADMIC_test"
fi
```

Return both reports in full. Do not launch the delete trial from a partial
console summary.

## Continuation Order

1. Run the read-only `tie1-pg-analyze` stage above.
2. If and only if all 15 candidates pass the exact preflight, run one isolated
   `tie1-pg-delete-trial` from the accepted V13 replay checkpoint.
3. Accept the deletion trial only with 15 successful exact-handle deletions,
   final special connectivity `0`, fresh DRC `0`, shorts `0`, regular
   connectivity `0`, unroutes `0`, and all Tie1/filler/placement invariants
   preserved.
4. Replay a passing deletion in a fresh process from the V13 replay checkpoint.
   Do not use the delete-trial checkpoint as canonical input.
5. Stream out and run attributable PVS base DRC and raw LVS from the selected
   replay checkpoint. Keep all antenna counts visible and do not attempt
   antenna repair.
6. If LVS repeats the RO signature, isolate the RO hcell/hierarchy contract in
   one fresh PVS experiment. Require explicit `MATCH`; a zero PVS process return
   code is insufficient.
7. Run density DRC only under the PVS stage policy after the LVS gate is
   resolved. Keep base DRC, density DRC, and LVS as separate decisions.
8. Requalify timing and final export separately before any signoff claim.

## Stop Conditions

Stop and preserve the accepted V13 replay checkpoint if any of these occurs:

- source checkpoint path or SHA-256 differs;
- tracked checkout is dirty or HEAD differs from the expected remote head;
- the analysis sees other than 15 markers;
- any marker has zero or multiple exact special-wire matches;
- any candidate handle is referenced more than once;
- any candidate length exceeds `10.0 um`;
- a deletion attempt is made during analysis;
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
