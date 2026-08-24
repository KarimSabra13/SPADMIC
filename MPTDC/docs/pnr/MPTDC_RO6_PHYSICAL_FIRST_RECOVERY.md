# MPTDC RO6 Physical-First Recovery

## Starting Point

The design has exactly two buffered debug outputs, `ro_slow_tap0_o` and
`ro_fast_tap0_o`, placed on the south edge on MET3. The earlier physical run
`20260824_mptdc_bufftap0_tempblk_physical_143726` proved that
the named temporary METTP blockage was created for signal routing and removed
before final verification. The lifecycle is no longer the blocker.

That run still failed with 22 geometry DRCs and 19 shorts. Eighteen shorts are
the same bounded RO signal-access family: `S[0:7]` and `rstb` for each of the
two `RO_tune6` instances. The pre-sroute `ecoRoute -target` marker snapshot
shows those 18 failures on MET3 at the macro edges; later repair merely moved
them to METTP. One independent MET2 signal/VSS short and three MET2 spacing
markers remain. Regular connectivity is clean, but raw special connectivity is
not final-clean. Therefore another routing-layer or `sroute` sweep is not the
next experiment.

The completed bounded action generated a fresh marker-derived PnR-only
`RO_tune6` LEF from the pre-sroute MET3 markers. It may open OBS access only for
`S[0:7]` and `rstb`; VDD, VSS, code pins, and unknown-pin windows are rejected.
The canonical `/group/.../RO_tune6.lef` remains read-only and is still the
physical source identity.

The published sweep `20260824_mptdc_bufftap0_pgsweep_125418` completed all 10
isolated `sroute` candidates and found no raw-clean candidate. Every mode kept
the same 34 `IMPVFC-94` VDD/VSS mesh tails at the RO obstructions. The sweep
also exposed three independent VDD-to-VSS METTP shorts made by the old broad
`simple_vdd_vss_pair` top-pin rectangles. Do not rerun that sweep: the next
canonical run uses exactly two ring-aligned VDD/VSS pins and explicitly gates
the VDD/VSS cross-net-short count at zero.

The published PG proof
`20260824_mptdc_bufftap0_simplepg_pgproof_135116` is accepted for the next
physical run. It uses exactly two ring-aligned PG pins, has zero VDD/VSS
cross-net shorts, and bounds the remaining 34 pre-route `IMPVFC-94` dangling
tails. This is permission to attempt routing, not final PG closure.

The first physical retry
`20260824_mptdc_bufftap0_mettpfix_physical_140734` did not start detailed
routing. NanoRoute rejected global top layer MET3 with `NRDB-954` because legal
special PG wires already exist on METTP (layer 4). The corrected policy keeps
NanoRoute's global command ceiling at METTP, creates one named temporary METTP
blockage during signal routing, and removes it before filler PG work and final
DRC. This preserves an ordinary signal top of MET3 without leaving the broad
blockage in the final database.

The first marker-derived PnR-LEF replay,
`20260824_151753_mptdc_bufftap0_pnrlef_physical`, proved the requested LEF path
and SHA-256, all 26 access windows, floorplan, placement, CTS, and the two south
MET3 pin plans. It stopped before detailed routing because the pre-route PG
classifier found 35 dangling-only `IMPVFC-94` row tails while the replay still
used the PG-proof bound of 34. Relative to the accepted PG proof, the only added
marker is VSS at `(219.580, 660.800)` on MET1, immediately outside the slow RO
right edge. The original 34 marker signatures are unchanged; cross-net PG
shorts and fatal special-connectivity findings remain zero.

The completed 35-tail replay,
`20260824_154115_mptdc_bufftap0_pnrlef35_physical`, reached the final route
gate. The custom PnR LEF eliminated the complete 18-short RO access family.
Only three logical geometry violations remain: one MET1 minimum-area marker on
`u_core_n_57563`, one MET2 VDD-spacing marker on `u_core_n_67240`, and one
MET2 VSS short on `u_core_n_66687`. Regular connectivity is clean, both tap0
pins remain present, and special connectivity contains 12 RO-area
`IMPVFC-94` dangling tails. The saved `04_route_failed.enc.dat` checkpoint is
therefore the bounded repair source; do not rerun floorplan, placement, CTS, or
full detail route for this experiment.

The first checkpoint repair,
`20260824_161415_mptdc_bufftap0_route_geometry_repair`, proved that deleting
each DRC-bearing wire removes its marker. Its unconstrained selected reroute
then recreated all three original markers at the same coordinates. Repeating
that candidate cannot improve the result.

The second checkpoint repair,
`20260824_163028_mptdc_bufftap0_route_geometry_repair_v2`, proved that preferred
layers alone are not a hard pin-access constraint. It moved the VSS short by
only 0.56 um, moved the VDD-spacing segment by 0.42 um, and added one MET1
cell-obstruction spacing marker. The minimum-area marker was unchanged. Do not
repeat either selected-route candidate.

The active repair keeps the same signal-layer policy but adds three temporary,
named local route blockages over only the recurrence corridors. The VSS repair
blocks MET2 around its exact special-wire overlap; the VDD repair blocks MET1
and MET2 across both its PG-spacing corridor and the newly observed cell-OBS
corridor; the minimum-area repair blocks the center of the old MET1 segment so
the selected router must take a longer path. Each blockage is queried after
creation, removed after its net is routed, and queried again before the final
gate. It does not modify VDD/VSS special wires, move cells, run global routing,
waive DRC, or stream GDS from a run with shorts.

## Acceptance Order

1. Reuse the latest buffered-tap Genus handoff; do not resynthesize.
2. Run a fresh PG proof with the ring-aligned two-pin topology. Continue on
   either raw-clean special connectivity or no more than 34 classified
   `IMPVFC-94` dangling mesh tails, only when fatal connectivity findings and
   VDD/VSS cross-net shorts are both zero.
3. Generate one fresh PnR-only RO LEF from the failed run's pre-sroute MET3
   marker snapshot. Require all nine signal pin classes, both MET2 and MET3
   access windows, no unexpected pin windows, and at least one OBS trim.
4. Run a fresh physical-first PnR with that exact LEF. The completed replay
   reduced the route debt to the exact three-marker class recorded above.
5. Restore its failed-route checkpoint once and apply the bounded three-net
   geometry repair. Require final DRC 0, shorts 0, regular connectivity 0, and
   exactly two tap pins before considering any PG-tail repair.
6. Confirm ordinary signal top is MET3, NanoRoute command top is METTP, the
   temporary METTP blockage was created and removed, and both tap pins exist.
7. Require raw special connectivity zero. A geometry-clean result with only
   the same or fewer classified `IMPVFC-94` tails is an intermediate checkpoint,
   not route closure and not permission to launch PVS.
8. Restore only a fully clean route checkpoint and merge the real RO
   OA GDS.
9. Require zero base PVS DRC, zero density-enabled PVS DRC, then explicit LVS
   MATCH on the same hashed inputs.
10. Keep TC setup/hold/DRV separate. Full MMMC, characterized RO timing, PEX,
   IR/EM, and final tapeout remain outside this physical-first gate.

## Step Decisions and Evidence

Every executable step writes an `operator_gate_*.rpt` with either
`DECISION=PASS_CONTINUE` or `DECISION=FAIL_STOP`. Missing fields are failures.
Publish the snapshot even when a step fails; the failed reports and diagnostic
log tails are what make remote analysis possible.

| Step | Required to continue | Snapshot kind |
|---|---|---|
| Pre-PnR | package RC 0, pre-PnR RC 0, `PRE_PNR_GATE=PASS` | `genus` |
| PG proof | wrapper RC 0, sroute PASS, PG cross-net shorts 0, non-RO failures 0, and either raw clean or bounded classified `IMPVFC-94` only | `innovus` |
| PnR LEF preparation | preparation PASS, `S[0:7]` plus `rstb` present, MET2/MET3 windows nonzero, unexpected-pin count 0, OBS trims nonzero | bundled into physical `innovus` snapshot |
| Physical PnR | pre-route status PASS with the audited PnR-LEF-only bound 35, requested/imported PnR LEF path and hash match, signal top MET3, router top METTP, temporary blockage removed, route/DRC PASS, every final DRC/connectivity/unrouted count 0, exactly two tap0 pins planned south on MET3 | `innovus` |
| Route geometry repair | exact published 3-DRC/1-short source signature, fresh single restore, final DRC 0, shorts 0, regular connectivity 0, saved checkpoint present, exactly two tap0 pins | `innovus` |
| PVS preparation | preparation PASS, strict attribution 1, tap contract PASS, tap count 2, hash manifest present | `pvs` |
| Template audit | audit RC 0 and `PVS_TEMPLATE_AUDIT_STATUS=PASS` | `pvs` |
| Base DRC | gate PASS, variant BASE, both report totals 0 | `pvs` |
| Density DRC | gate PASS, variant DENSITY, both report totals 0 | `pvs` |
| LVS | gate RC 0 and explicit `PVS_LVS_STATUS=MATCH` | `pvs` |

The collector copies small text reports, manifests, PVS controls, and filtered
diagnostic tails. It excludes checkpoints, databases, GDS/OAS, and DEF by
default, and skips text files larger than 2 MiB. Do not manually add those
excluded artifacts to Git.

## Recommended Short Server Commands

Use these commands for the next run. They replace the long manual blocks later
in this document. Each driver runs one fresh physical process, evaluates the
authoritative reports, writes an `operator_gate_*.rpt`, and publishes only the
bounded evidence directory. The PVS driver applies the same rule independently
to preparation, template audit, base DRC, density DRC, and LVS.

The many historical untracked files in the server checkout do not block these
commands. The drivers inspect tracked changes with
`git status --short --untracked-files=no`. Do not run `git add -A`, do not clean
the checkout, and do not add the historical untracked files.

### 0. Synchronize Once

```bash
set +e

REPO=/home/validmgr/ksabra/2026_SPAD/SPADMIC
SYNC_RC=99

if [ -d "$REPO/.git" ]; then
  cd "$REPO"
  git checkout SPADMIC_test
  git pull --ff-only origin SPADMIC_test
  SYNC_RC=$?
else
  echo "STOP: repository missing: $REPO"
fi

echo "SYNC_RC=$SYNC_RC"
echo "HEAD=$(git rev-parse HEAD 2>/dev/null)"
echo "TRACKED_STATUS_BEGIN"
git status --short --untracked-files=no 2>/dev/null
echo "TRACKED_STATUS_END"
```

Continue only when `SYNC_RC=0` and there is no line between the two tracked
status markers. The drivers also enforce `SPADMIC_test` and require local HEAD
to match `origin/SPADMIC_test` when no explicit hash is supplied.

### 1. PG Proof

```bash
set +e

bash MPTDC/pnr/scripts/server_run_mptdc_ro6_recovery_stage.sh \
  --stage pg-proof \
  --genus-run-id MPTDC_TC_BufferedROTap0Pins_Genus_20260709_155623 \
  --handoff-dir /sim/ksabra/SPADMIC_work/handoff/genus_typical_pnrcompat/MPTDC_TC_BufferedROTap0Pins_Genus_20260709_155623

PG_DRIVER_RC=$?
echo "PG_DRIVER_RC=$PG_DRIVER_RC"
echo "HEAD=$(git rev-parse HEAD 2>/dev/null)"
```

Pass requires all of these markers:

```text
CADENCE_ENV_STATUS=PASS
PG_DRIVER_RC=0
DECISION=PASS_CONTINUE
PUBLISH_RC=0
POSTPLACE_PRE_ROUTE_PG_CROSS_NET_SHORT_STATUS=PASS
POSTPLACE_PRE_ROUTE_PG_CROSS_NET_SHORT_COUNT=0
BLOCK_PG_PIN_STYLE=ring_aligned_vdd_vss_pair
BLOCK_PG_PIN_REQUESTED_COUNT=2
PG_GATE_MODE=RAW_CLEAN or BOUNDED_DANGLING_CONTINUATION
NEXT_STAGE=PHYSICAL_PNR
NEXT_REQUIRED_PG_RUN_ID=<new PG run id>
```

Save the printed `NEXT_REQUIRED_PG_RUN_ID`; it is the only value needed by the
next command. On any failure, stop. If `PUBLISH_RC=0`, send the run id and
printed HEAD so the pushed failure evidence can be reviewed remotely.

`RECOVERY_PREFLIGHT=PASS` alone does not mean Innovus launched. The driver must
next print `CADENCE_ENV_STATUS=PASS`. A missing status means the checkout still
has the older startup bug; `CADENCE_ENV_STATUS=FAIL` means the Cadence site
setup itself failed. In either case, stop before retrying.

### Completed PG SRoute Sweep

The isolated sweep is complete and has no winner. Its published decision is
`STRICT_PASS_COUNT=0`; rerunning it would repeat the same topology. The bounded
pre-route continuation in step 1 is not final connectivity acceptance. Step 2
still requires raw special connectivity, all DRC, and all shorts to be zero.

### 2. Prepare the PnR LEF and Run Physical PnR

The preparation and first replay are complete. They reused the accepted PG proof
`20260824_mptdc_bufftap0_simplepg_pgproof_135116` and the exact pre-sroute MET3
marker snapshot from the earlier failed physical run. The generated server LEF
is `/sim/ksabra/SPADMIC_work/lef/RO_tune6_pnr_pin_access_tempblk_met3_20260824_151753.lef`
with SHA-256
`6788f856561a3e8c002dc7f2536ac338b16fc76b56aaae9d2062f4dccfec8469`.

#### 2A. Completed 35-Tail Replay Reference

Do not rerun this block. It produced
`20260824_154115_mptdc_bufftap0_pnrlef35_physical` and is retained only as an
audit reference for the exact handoff, PnR LEF, and 35-tail continuation.

```bash
set +e

REPO=/home/validmgr/ksabra/2026_SPAD/SPADMIC
PG_RUN_ID=20260824_mptdc_bufftap0_simplepg_pgproof_135116
GENUS_RUN_ID=MPTDC_TC_BufferedROTap0Pins_Genus_20260709_155623
HANDOFF=/sim/ksabra/SPADMIC_work/handoff/genus_typical_pnrcompat/$GENUS_RUN_ID
SOURCE_LEF=/group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune6.lef
PNR_LEF=/sim/ksabra/SPADMIC_work/lef/RO_tune6_pnr_pin_access_tempblk_met3_20260824_151753.lef
PNR_LEF_SUMMARY=${PNR_LEF%.lef}.summary.txt
TAG=$(date +%Y%m%d_%H%M%S)
PNR_RUN=${TAG}_mptdc_bufftap0_pnrlef35_physical
PNR_DIR=/sim/ksabra/SPADMIC_work/innovus/$PNR_RUN
DRIVER_LOG=/tmp/${PNR_RUN}.driver.log

SYNC_RC=99
PNR_DRIVER_RC=99
REPO_READY=0

if [ -d "$REPO/.git" ]; then
  cd "$REPO"
  git checkout SPADMIC_test
  git pull --ff-only origin SPADMIC_test
  SYNC_RC=$?
  [ "$SYNC_RC" -eq 0 ] && REPO_READY=1
else
  echo "STOP: repository missing: $REPO"
fi

EXPECTED_HEAD="$(git rev-parse HEAD 2>/dev/null)"
TRACKED_STATUS="$(git status --short --untracked-files=no 2>/dev/null)"
PREP_STATUS="$(sed -n 's/^PNR_LEF_PREP_STATUS=//p' "$PNR_LEF_SUMMARY" 2>/dev/null | tail -1)"

if [ "$REPO_READY" -eq 1 ] && [ -z "$TRACKED_STATUS" ] && \
   [ -r "$PNR_LEF" ] && [ -r "$PNR_LEF_SUMMARY" ] && \
   [ "$PREP_STATUS" = PASS ]; then
  bash MPTDC/pnr/scripts/server_run_mptdc_ro6_recovery_stage.sh \
    --stage physical-pnr \
    --run-id "$PNR_RUN" \
    --pg-run-id "$PG_RUN_ID" \
    --expected-head "$EXPECTED_HEAD" \
    --genus-run-id "$GENUS_RUN_ID" \
    --handoff-dir "$HANDOFF" \
    --source-lef "$SOURCE_LEF" \
    --pnr-lef "$PNR_LEF" \
    --pre-route-dangling-max 35 \
    2>&1 | tee "$DRIVER_LOG"
  PNR_DRIVER_RC=${PIPESTATUS[0]}
else
  echo "STOP: sync, tracked-tree, PnR LEF, or PnR LEF summary gate failed"
  [ -n "$TRACKED_STATUS" ] && printf '%s\n' "$TRACKED_STATUS"
fi

echo "===== SEND BACK ====="
echo "SYNC_RC=$SYNC_RC"
echo "PREP_STATUS=$PREP_STATUS"
echo "PNR_RUN=$PNR_RUN"
echo "PNR_DRIVER_RC=$PNR_DRIVER_RC"
echo "FINAL_HEAD=$(git rev-parse HEAD 2>/dev/null)"
grep -E '^(RECOVERY_STAGE|RECOVERY_RUN_ID|TOOL_RC|DECISION|PUBLISH_RC|NEXT_EXPECTED_HEAD|NEXT_STAGE|NEXT_REQUIRED_PNR_RUN_ID)=' \
  "$DRIVER_LOG" 2>/dev/null | tail -20
cat "$PNR_DIR/reports/operator_gate_physical_pnr.rpt" 2>/dev/null
```

The completed result is intentionally `DECISION=FAIL_STOP`: DRC is 3, shorts are
1, regular connectivity is 0, and special connectivity contains 12 dangling
tails. Its failed-route checkpoint is the source for the active command below.

#### 2B. Current Next Command: Local-Keepout Route Geometry Repair

Run this block once. The driver refuses any source other than the tracked exact
three-marker signature, restores the source checkpoint once in a fresh Innovus
process, applies the exact per-net layer policy and three named local keepouts
recorded below, reroutes only the three named regular nets with selected-net
`routeDesign`, removes and verifies removal of every keepout, evaluates fresh
DRC and connectivity, and publishes the result automatically. A failed guard
returns to the SSH prompt; it does not close the login shell.

```text
u_core_n_66687  MET3-MET3  block MET2      {220.10 177.80 221.20 181.20}
u_core_n_67240  MET3-MET3  block MET1/MET2 {219.30 222.80 221.20 225.90}
u_core_n_57563  MET2-MET3  block MET1      {364.79 328.10 364.89 328.78}
```

```bash
set +e

REPO=/home/validmgr/ksabra/2026_SPAD/SPADMIC
SOURCE_PNR_RUN=20260824_154115_mptdc_bufftap0_pnrlef35_physical
TAG=$(date +%Y%m%d_%H%M%S)
REPAIR_RUN=${TAG}_mptdc_bufftap0_local_keepout_repair_v3
REPAIR_DIR=/sim/ksabra/SPADMIC_work/innovus/$REPAIR_RUN
DRIVER_LOG=/tmp/${REPAIR_RUN}.driver.log

SYNC_RC=99
REPAIR_DRIVER_RC=99
REPO_READY=0

if [ -d "$REPO/.git" ]; then
  cd "$REPO"
  git checkout SPADMIC_test
  git pull --ff-only origin SPADMIC_test
  SYNC_RC=$?
  [ "$SYNC_RC" -eq 0 ] && REPO_READY=1
else
  echo "STOP: repository missing: $REPO"
fi

EXPECTED_HEAD="$(git rev-parse HEAD 2>/dev/null)"
TRACKED_STATUS="$(git status --short --untracked-files=no 2>/dev/null)"

if [ "$REPO_READY" -eq 1 ] && [ -z "$TRACKED_STATUS" ]; then
  bash MPTDC/pnr/scripts/server_run_mptdc_ro6_recovery_stage.sh \
    --stage route-geometry-repair \
    --run-id "$REPAIR_RUN" \
    --source-pnr-run-id "$SOURCE_PNR_RUN" \
    --expected-head "$EXPECTED_HEAD" \
    2>&1 | tee "$DRIVER_LOG"
  REPAIR_DRIVER_RC=${PIPESTATUS[0]}
else
  echo "STOP: sync or tracked-tree gate failed"
  [ -n "$TRACKED_STATUS" ] && printf '%s\n' "$TRACKED_STATUS"
fi

echo "===== SEND BACK ====="
echo "SYNC_RC=$SYNC_RC"
echo "SOURCE_PNR_RUN=$SOURCE_PNR_RUN"
echo "REPAIR_RUN=$REPAIR_RUN"
echo "REPAIR_DRIVER_RC=$REPAIR_DRIVER_RC"
echo "FINAL_HEAD=$(git rev-parse HEAD 2>/dev/null)"
grep -E '^(RECOVERY_STAGE|RECOVERY_RUN_ID|TOOL_RC|DECISION|PUBLISH_RC|NEXT_EXPECTED_HEAD|NEXT_STAGE|NEXT_REQUIRED_REPAIR_RUN_ID|NEXT_REQUIRED_PNR_RUN_ID)=' \
  "$DRIVER_LOG" 2>/dev/null | tail -20
cat "$REPAIR_DIR/reports/operator_gate_route_geometry_repair.rpt" 2>/dev/null
```

The geometry step passes only when fresh Innovus evidence reports:

```text
INITIAL_DRC=3
INITIAL_SHORTS=1
INITIAL_REGULAR_CONNECTIVITY_BAD=0
INITIAL_SPECIAL_DANGLING_COUNT=12
FINAL_DRC=0
FINAL_SHORTS=0
FINAL_REGULAR_CONNECTIVITY_BAD=0
FINAL_CHECKPOINT_DAT_EXISTS=1
RO_TAP_OBSERVABILITY_PIN_COUNT=2
DECISION=PASS_CONTINUE
PUBLISH_RC=0
```

If `GEOMETRY_REPAIR_GATE_MODE=GEOMETRY_REGULAR_CLEAN_PG_DANGLING_REVIEW`, stop
after publication and send the short result block. Geometry is then repaired,
but the remaining PG-tail class still needs its own isolated repair before PVS.
Only `GEOMETRY_REPAIR_GATE_MODE=FULL_ROUTE_GATE_CLEAN` with `NEXT_STAGE=PVS`
permits direct continuation to PVS.

#### 2C. Completed PnR-LEF Generation Reference

Do not rerun this block while the exact generated LEF and summary above remain
readable. It is retained only to reproduce the file if server scratch storage
is lost. It does not modify the canonical RO LEF or reuse a dirty checkpoint.

```bash
set +e

REPO=/home/validmgr/ksabra/2026_SPAD/SPADMIC
FAILED_PNR_RUN=20260824_mptdc_bufftap0_tempblk_physical_143726
FAILED_PNR_DIR=/sim/ksabra/SPADMIC_work/innovus/$FAILED_PNR_RUN
MARKERS=$FAILED_PNR_DIR/reports/POST_FILLER_PRE_SROUTE_ecoRoute_target_markers.tsv
FAILED_DEF=$FAILED_PNR_DIR/def/04_route_failed.def
SOURCE_LEF=/group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune6.lef
PG_RUN_ID=20260824_mptdc_bufftap0_simplepg_pgproof_135116
GENUS_RUN_ID=MPTDC_TC_BufferedROTap0Pins_Genus_20260709_155623
HANDOFF=/sim/ksabra/SPADMIC_work/handoff/genus_typical_pnrcompat/$GENUS_RUN_ID
TAG=$(date +%Y%m%d_%H%M%S)
PNR_LEF=/sim/ksabra/SPADMIC_work/lef/RO_tune6_pnr_pin_access_tempblk_met3_$TAG.lef
PNR_LEF_SUMMARY=${PNR_LEF%.lef}.summary.txt
PNR_RUN=${TAG}_mptdc_bufftap0_pnrlef_physical
PNR_DIR=/sim/ksabra/SPADMIC_work/innovus/$PNR_RUN

LEF_PREP_RC=99
PREP_STATUS=MISSING
PNR_DRIVER_RC=99
REPO_READY=0

if [ -d "$REPO/.git" ]; then
  cd "$REPO"
  [ "$?" -eq 0 ] && REPO_READY=1
else
  echo "STOP: repository missing: $REPO"
fi

if [ "$REPO_READY" -eq 1 ] && [ -r "$MARKERS" ] && \
   [ -r "$FAILED_DEF" ] && [ -r "$SOURCE_LEF" ]; then
  bash MPTDC/pnr/scripts/server_prepare_ro_tune6_pnr_lef.sh \
    --run "$FAILED_PNR_DIR" \
    --source-lef "$SOURCE_LEF" \
    --markers "$MARKERS" \
    --failed-def "$FAILED_DEF" \
    --out-lef "$PNR_LEF"
  LEF_PREP_RC=$?
else
  echo "STOP: marker, failed DEF, or canonical source LEF is missing"
fi

PREP_STATUS="$(sed -n 's/^PNR_LEF_PREP_STATUS=//p' "$PNR_LEF_SUMMARY" 2>/dev/null | tail -1)"

if [ "$LEF_PREP_RC" -eq 0 ] && [ "$PREP_STATUS" = PASS ]; then
  bash MPTDC/pnr/scripts/server_run_mptdc_ro6_recovery_stage.sh \
    --stage physical-pnr \
    --run-id "$PNR_RUN" \
    --pg-run-id "$PG_RUN_ID" \
    --genus-run-id "$GENUS_RUN_ID" \
    --handoff-dir "$HANDOFF" \
    --source-lef "$SOURCE_LEF" \
    --pnr-lef "$PNR_LEF" \
    --pre-route-dangling-max 35
  PNR_DRIVER_RC=$?
else
  echo "STOP: PnR LEF preparation failed; Innovus was not launched"
fi

echo "===== SEND BACK ====="
echo "LEF_PREP_RC=$LEF_PREP_RC"
echo "PREP_STATUS=$PREP_STATUS"
echo "PNR_LEF=$PNR_LEF"
echo "PNR_RUN=$PNR_RUN"
echo "PNR_DRIVER_RC=$PNR_DRIVER_RC"
echo "FINAL_HEAD=$(git rev-parse HEAD 2>/dev/null)"
tail -40 "$PNR_LEF_SUMMARY" 2>/dev/null
cat "$PNR_DIR/reports/operator_gate_physical_pnr.rpt" 2>/dev/null
```

LEF preparation passes only with:

```text
LEF_PREP_RC=0
PREP_STATUS=PASS
REQUIRED_ACCESS_PIN_SET_STATUS=PASS
UNEXPECTED_ACCESS_PIN_COUNT=0
MET2_ACCESS_WINDOW_COUNT=13
MET3_ACCESS_WINDOW_COUNT=13
PNR_LEF_PREP_STATUS=PASS
```

A local reconstruction with the published marker TSV, recorded RO placements,
and checked-in Option-A abstract produced 26 windows: 13 on MET2, 13 on MET3,
all nine required pin classes, zero unexpected pins, and 15 touched OBS
rectangles. The server-side status gate is authoritative because it hashes the
actual canonical source and generated output.

Physical PnR passes only with:

```text
CADENCE_ENV_STATUS=PASS
PNR_DRIVER_RC=0
DECISION=PASS_CONTINUE
PUBLISH_RC=0
PNR_LEF_SUMMARY_BINDING_STATUS=PASS
PNR_LEF_PATH_MATCH_STATUS=PASS
PNR_LEF_EVIDENCE_STATUS=PASS
PNR_LEF_GATE_STATUS=PASS
PRE_ROUTE_SROUTE_STATUS=PASS
PRE_ROUTE_DANGLING_MODE=PNR_LEF_ONE_MARKER_CONTINUATION
PRE_ROUTE_DANGLING_ONLY_STATUS=DANGLING_ONLY
PRE_ROUTE_DANGLING_COUNT=35
PRE_ROUTE_DANGLING_MAX=35
PRE_ROUTE_DANGLING_FATAL_COUNT=0
PRE_ROUTE_PG_CROSS_NET_SHORT_COUNT=0
signal_top_layer=MET3
router_command_top_layer=METTP
ROUTE_COMMAND_STATUS=PASS
SIGNAL_TOP_ROUTE_BLOCKAGE_TEMPORARY=1
SIGNAL_TOP_ROUTE_BLOCKAGE_CREATE_STATUS=PASS
SIGNAL_TOP_ROUTE_BLOCKAGE_REMOVE_STATUS=PASS
SIGNAL_TOP_ROUTE_BLOCKAGE_STATUS=REMOVED
NEXT_STAGE=PVS
NEXT_REQUIRED_PNR_RUN_ID=<new physical PnR run id>
```

The driver independently requires zero Innovus DRC and shorts, zero regular
and special connectivity debt, zero unrouted nets, and exactly the two
south-edge MET3 buffered tap pins. It copies the exact generated LEF and its
summary into the bounded evidence snapshot before publishing. On failure,
send only `PNR_RUN`, `FINAL_HEAD`, and the final driver lines; the reports are
already on GitHub when `PUBLISH_RC=0`. Do not run PVS after a failed decision.

### 3. PVS Preparation, DRC, and LVS

Replace only `REPLACE_WITH_PNR_RUN_ID` with the value printed by step 2. The RO
GDS path below is the known real-OA export; stop and replace it if the OA layout
has changed since that export.

```bash
set +e

bash MPTDC/scripts/pvs/server_run_mptdc_ro6_recovery_pvs.sh \
  --pnr-run-id REPLACE_WITH_PNR_RUN_ID \
  --ro-gds /sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_211109_falsepath_nfast_risk_235618/drygds_oa_20260702_001608/merge_libs/RO_tune6_from_OA.gds

PVS_DRIVER_RC=$?
echo "PVS_DRIVER_RC=$PVS_DRIVER_RC"
echo "HEAD=$(git rev-parse HEAD 2>/dev/null)"
```

The command stops at the first failed PVS gate. Full success requires:

```text
CADENCE_ENV_STATUS=PASS
PVS_DRIVER_RC=0
PVS_RECOVERY_STATUS=PASS
PVS_PREPARATION=PASS
PVS_TEMPLATE_AUDIT=PASS
PVS_DRC_BASE=PASS
PVS_DRC_DENSITY=PASS
PVS_LVS=MATCH
DECISION=PASS_CONTINUE
PUBLISH_RC=0
```

### What to Send After Each Command

Do not paste full Innovus or PVS logs into chat. Send only:

```text
STEP=<PG_PROOF, PHYSICAL_PNR, ROUTE_GEOMETRY_REPAIR, or PVS>
RUN_ID=<NEXT_REQUIRED_*_RUN_ID or PVS_RUN_ID>
DRIVER_RC=<printed driver RC>
DECISION=<printed decision>
PUBLISH_RC=<printed publish RC, when present>
HEAD=<printed repository HEAD>
```

For `PG_PROOF`, also send `PG_GATE_MODE` and
`POSTPLACE_PRE_ROUTE_PG_CROSS_NET_SHORT_COUNT`. No full Innovus log needs to be
pasted when `PUBLISH_RC=0`. For `ROUTE_GEOMETRY_REPAIR`, also send
`GEOMETRY_REPAIR_GATE_MODE` and `FINAL_SPECIAL_DANGLING_COUNT`.

When publication succeeds, the pushed snapshot contains all authoritative
small reports and manifests plus filtered diagnostic log tails. The local GDS,
DEF, checkpoints, databases, and oversized full logs remain under `/sim`; they
are intentionally not pushed to Git. If publication itself fails, stop and send
the final `EVIDENCE_*` lines so the existing snapshot can be recovered without
rerunning the EDA stage.

The detailed blocks below remain as manual debugging reference. Do not mix
their shell variables with the short driver commands during a normal run.

### Reuse an Already Collected Snapshot

If collection succeeded but commit or push failed, do not recollect or rerun the
EDA step. After pulling any publisher fix, reuse the existing snapshot:

```bash
set +e

SNAPSHOT_KIND=genus
SNAPSHOT_ID=REPLACE_WITH_EXISTING_SNAPSHOT_DIRECTORY_NAME
SOURCE_DIR=REPLACE_WITH_ORIGINAL_HANDOFF_OR_RESULT_DIRECTORY
STEP_LABEL=PRE_PNR
SNAPSHOT_REL=MPTDC/docs/server_snapshots/$SNAPSHOT_KIND/$SNAPSHOT_ID

git restore --staged "$SNAPSHOT_REL" 2>/dev/null
git pull --ff-only origin SPADMIC_test

MPTDC_SNAPSHOT_REUSE_EXISTING=1 \
bash MPTDC/ci/publish_mptdc_server_snapshot.sh \
  "$SNAPSHOT_KIND" "$SNAPSHOT_ID" "$SOURCE_DIR" "$STEP_LABEL"
RECOVERY_PUBLISH_RC=$?
EXPECTED_HEAD="$(git rev-parse HEAD 2>/dev/null)"

echo "RECOVERY_PUBLISH_RC=$RECOVERY_PUBLISH_RC"
echo "NEXT_EXPECTED_HEAD=$EXPECTED_HEAD"
```

Generated reports are committed verbatim. Trailing whitespace in a Cadence
report is not a publication failure and is not altered.

## Archived Long-Form Commands

Do not run the long-form blocks below. They are retained only to explain the
earlier evidence and include the superseded raw-strict gate and broad top-pin
topology. For execution, use only **Recommended Short Server Commands** above;
the recovery-stage driver now owns all pass/fail and snapshot publication
logic.

### Archived Strict PG Proof

The commands are foreground-only. They avoid `set -e` and shell-level `exit`,
so a failed guard does not close an interactive SSH session. Run all Bash
blocks below in the same SSH shell; the evidence helper and guarded state carry
forward between blocks.

```bash
set +e

cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
source /eda/cadence/eda_2023-2024 2>/dev/null

export MPTDC_WORK_ROOT=/sim/ksabra/SPADMIC_work
export MPTDC_GENUS_WORK=$MPTDC_WORK_ROOT/genus
export MPTDC_INNOVUS_WORK=$MPTDC_WORK_ROOT/innovus

git checkout SPADMIC_test
git pull --ff-only origin SPADMIC_test

EXPECTED_HEAD="$(git rev-parse HEAD 2>/dev/null)"
echo "EXPECTED_HEAD=$EXPECTED_HEAD"

TRACKED_STATUS="$(git status --short --untracked-files=no 2>/dev/null)"
if [ -n "$TRACKED_STATUS" ]; then
  echo "$TRACKED_STATUS"
  echo "STOP: tracked working tree is dirty"
fi

mptdc_publish_snapshot() {
  local snapshot_kind="$1"
  local snapshot_id="$2"
  local source_dir="$3"
  local step_label="$4"
  MPTDC_SNAPSHOT_MAX_TEXT_BYTES=2097152 \
  bash MPTDC/ci/publish_mptdc_server_snapshot.sh \
    "$snapshot_kind" "$snapshot_id" "$source_dir" "$step_label"
  local publish_rc=$?
  EXPECTED_HEAD="$(git rev-parse HEAD 2>/dev/null)"
  return "$publish_rc"
}

GENUS_DIR="$(ls -td "$MPTDC_GENUS_WORK"/MPTDC_TC_BufferedROTap0Pins_Genus_20260709_* 2>/dev/null | sed -n '1p')"
GENUS_RUN="${GENUS_DIR##*/}"
HANDOFF_ROOT=$MPTDC_WORK_ROOT/handoff/genus_typical_pnrcompat
HANDOFF=$HANDOFF_ROOT/$GENUS_RUN

STOP=0
[ -z "$TRACKED_STATUS" ] || STOP=1
[ -n "$GENUS_DIR" ] || { echo "STOP: buffered Genus run not found"; STOP=1; }
[ -d "$GENUS_DIR" ] || { echo "STOP: missing Genus directory: $GENUS_DIR"; STOP=1; }

if [ "$STOP" -eq 0 ] && [ ! -d "$HANDOFF" ]; then
  MPTDC_GENUS_HANDOFF_ROOT="$HANDOFF_ROOT" \
  bash MPTDC/syn/scripts/package_genus_typical_handoff.sh "$GENUS_RUN"
  PACKAGE_RC=$?
elif [ "$STOP" -eq 0 ]; then
  PACKAGE_RC=0
else
  PACKAGE_RC=99
fi

if [ "$PACKAGE_RC" -eq 0 ]; then
  mkdir -p "$HANDOFF/reports"
  PRE_PNR_REPORT="$HANDOFF/reports/pre_pnr_gate_recheck.rpt"
  bash MPTDC/pnr/scripts/check_mptdc_pre_pnr_gate.sh \
    --genus-run-id "$GENUS_RUN" \
    --handoff-dir "$HANDOFF" \
    2>&1 | tee "$PRE_PNR_REPORT"
  PRE_PNR_RC=${PIPESTATUS[0]}
else
  PRE_PNR_REPORT="$HANDOFF/reports/pre_pnr_gate_recheck.rpt"
  PRE_PNR_RC=99
fi

PRE_PNR_STATUS="$(sed -n 's/^PRE_PNR_GATE=//p' "$PRE_PNR_REPORT" 2>/dev/null | tail -1)"
if [ "$PACKAGE_RC" -eq 0 ] && \
   [ "$PRE_PNR_RC" -eq 0 ] && \
   [ "$PRE_PNR_STATUS" = "PASS" ]; then
  PRE_PNR_DECISION=PASS_CONTINUE
else
  PRE_PNR_DECISION=FAIL_STOP
fi

if [ -d "$HANDOFF" ]; then
  mkdir -p "$HANDOFF/reports"
  {
    echo "STEP=PRE_PNR"
    echo "PACKAGE_RC=$PACKAGE_RC"
    echo "PRE_PNR_RC=$PRE_PNR_RC"
    echo "PRE_PNR_GATE=$PRE_PNR_STATUS"
    echo "DECISION=$PRE_PNR_DECISION"
  } | tee "$HANDOFF/reports/operator_gate_pre_pnr.rpt"
  PRE_PNR_SNAPSHOT_ID="${GENUS_RUN}_prepnr_$(date +%Y%m%d_%H%M%S)"
  mptdc_publish_snapshot genus "$PRE_PNR_SNAPSHOT_ID" "$HANDOFF" "PRE_PNR"
  PRE_PNR_PUBLISH_RC=$?
else
  echo "STOP: no handoff directory exists for evidence collection"
  PRE_PNR_PUBLISH_RC=99
fi

PG_RUN=$(date +%Y%m%d)_mptdc_bufftap0_simplepg_pgproof_$(date +%H%M%S)
PG_DIR=$MPTDC_INNOVUS_WORK/$PG_RUN

if [ "$PRE_PNR_DECISION" = "PASS_CONTINUE" ] && \
   [ "$PRE_PNR_PUBLISH_RC" -eq 0 ]; then
  bash MPTDC/pnr/scripts/server_run_mptdc_ro6_latestlef_simplepg.sh \
    --run-id "$PG_RUN" \
    --stage pg_proof \
    --expected-head "$EXPECTED_HEAD" \
    --handoff-dir "$HANDOFF" \
    --genus-run-id "$GENUS_RUN" \
    --no-free-all \
    --local-phase-preplace \
    --strict-special-clean \
    --no-signal-top-route-blockage
  PG_RC=$?
else
  PG_RC=99
fi

echo "PACKAGE_RC=$PACKAGE_RC"
echo "PRE_PNR_RC=$PRE_PNR_RC"
echo "PRE_PNR_DECISION=$PRE_PNR_DECISION"
echo "PRE_PNR_PUBLISH_RC=$PRE_PNR_PUBLISH_RC"
echo "PG_RC=$PG_RC"
cat "$PG_DIR/reports/postplace_pre_route_sroute_status.rpt" 2>/dev/null

PG_STATUS_REPORT="$PG_DIR/reports/postplace_pre_route_sroute_status.rpt"
PG_SROUTE_STATUS="$(sed -n 's/^POSTPLACE_PRE_ROUTE_SROUTE_STATUS=//p' "$PG_STATUS_REPORT" 2>/dev/null | tail -1)"
PG_RAW_BAD="$(sed -n 's/^POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_RAW_BAD=//p' "$PG_STATUS_REPORT" 2>/dev/null | tail -1)"
PG_BAD="$(sed -n 's/^POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_BAD=//p' "$PG_STATUS_REPORT" 2>/dev/null | tail -1)"
PG_NON_RO_BAD="$(sed -n 's/^POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_NON_RO_FAILURES=//p' "$PG_STATUS_REPORT" 2>/dev/null | tail -1)"

if [ "$PG_RC" -eq 0 ] && \
   [ "$PG_SROUTE_STATUS" = "PASS" ] && \
   [ "$PG_RAW_BAD" = "0" ] && \
   [ "$PG_BAD" = "0" ] && \
   [ "$PG_NON_RO_BAD" = "0" ]; then
  PG_DECISION=PASS_CONTINUE
else
  PG_DECISION=FAIL_STOP
fi

if [ -d "$PG_DIR" ]; then
  mkdir -p "$PG_DIR/reports"
  {
    echo "STEP=STRICT_PG_PROOF"
    echo "PG_RC=$PG_RC"
    echo "POSTPLACE_PRE_ROUTE_SROUTE_STATUS=$PG_SROUTE_STATUS"
    echo "POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_BAD=$PG_BAD"
    echo "POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_RAW_BAD=$PG_RAW_BAD"
    echo "POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_NON_RO_FAILURES=$PG_NON_RO_BAD"
    echo "DECISION=$PG_DECISION"
  } | tee "$PG_DIR/reports/operator_gate_pg_proof.rpt"
  mptdc_publish_snapshot innovus "$PG_RUN" "$PG_DIR" "STRICT_PG_PROOF"
  PG_PUBLISH_RC=$?
else
  PG_PUBLISH_RC=99
fi

echo "PG_DECISION=$PG_DECISION"
echo "PG_PUBLISH_RC=$PG_PUBLISH_RC"
```

### Archived Physical-First PnR

Continue in the same shell. The full route is a new Innovus process.

```bash
set +e

PNR_RUN=$(date +%Y%m%d)_mptdc_bufftap0_mettpfix_physical_$(date +%H%M%S)
PNR_DIR=$MPTDC_INNOVUS_WORK/$PNR_RUN

if [ "$PG_DECISION" = "PASS_CONTINUE" ] && \
   [ "$PG_PUBLISH_RC" -eq 0 ]; then
  bash MPTDC/pnr/scripts/server_run_mptdc_ro6_latestlef_simplepg.sh \
    --run-id "$PNR_RUN" \
    --stage full_closure \
    --expected-head "$EXPECTED_HEAD" \
    --handoff-dir "$HANDOFF" \
    --genus-run-id "$GENUS_RUN" \
    --no-free-all \
    --local-phase-preplace \
    --physical-first \
    --strict-special-clean \
    --post-filler-sroute \
    --temporary-signal-top-route-blockage
  PNR_RC=$?
else
  echo "STOP: strict PG proof did not pass; full route not launched"
  PNR_RC=99
fi

ROUTE_REPORT="$PNR_DIR/reports/route_status.rpt"
ROUTE_INTENT_REPORT="$PNR_DIR/reports/route_layer_intent.rpt"
ROUTE_COMMAND_REPORT="$PNR_DIR/reports/route_command_status.rpt"
SIGNAL_TOP_BLOCKAGE_REPORT="$PNR_DIR/reports/signal_top_route_blockage_status.rpt"
IO_PIN_SUMMARY="$PNR_DIR/reports/io_pin_placement_summary.md"
IO_PIN_CSV="$PNR_DIR/reports/io_pin_placement.csv"
ROUTE_PASS="$(sed -n 's/^ROUTE_STATUS=//p' "$ROUTE_REPORT" 2>/dev/null | tail -1)"
DRC_PASS="$(sed -n 's/^INNOVUS_VERIFY_DRC_STATUS=//p' "$ROUTE_REPORT" 2>/dev/null | tail -1)"
GEOMETRY_DRC="$(sed -n 's/^GEOMETRY_DRC_VIOLATIONS=//p' "$ROUTE_REPORT" 2>/dev/null | tail -1)"
SHORTS="$(sed -n 's/^SHORTS=//p' "$ROUTE_REPORT" 2>/dev/null | tail -1)"
REGULAR_BAD="$(sed -n 's/^REGULAR_NET_CONNECTIVITY_BAD=//p' "$ROUTE_REPORT" 2>/dev/null | tail -1)"
SPECIAL_BAD="$(sed -n 's/^SPECIAL_NET_CONNECTIVITY_BAD=//p' "$ROUTE_REPORT" 2>/dev/null | tail -1)"
SPECIAL_RAW_BAD="$(sed -n 's/^SPECIAL_NET_CONNECTIVITY_RAW_BAD=//p' "$ROUTE_REPORT" 2>/dev/null | tail -1)"
SPECIAL_NON_RO_BAD="$(sed -n 's/^SPECIAL_NET_CONNECTIVITY_NON_RO_FAILURES=//p' "$ROUTE_REPORT" 2>/dev/null | tail -1)"
UNROUTED="$(sed -n 's/^UNROUTED_NETS=//p' "$ROUTE_REPORT" 2>/dev/null | tail -1)"
ROUTER_TOP="$(sed -n 's/^router_command_top_layer=//p' "$ROUTE_INTENT_REPORT" 2>/dev/null | tail -1)"
SIGNAL_TOP="$(sed -n 's/^signal_top_layer=//p' "$ROUTE_INTENT_REPORT" 2>/dev/null | tail -1)"
ROUTE_COMMAND_STATUS="$(sed -n 's/^ROUTE_COMMAND_STATUS=//p' "$ROUTE_COMMAND_REPORT" 2>/dev/null | tail -1)"
SIGNAL_TOP_BLOCKAGE_TEMPORARY="$(sed -n 's/^SIGNAL_TOP_ROUTE_BLOCKAGE_TEMPORARY=//p' "$SIGNAL_TOP_BLOCKAGE_REPORT" 2>/dev/null | tail -1)"
SIGNAL_TOP_BLOCKAGE_CREATE="$(sed -n 's/^SIGNAL_TOP_ROUTE_BLOCKAGE_CREATE_STATUS=//p' "$SIGNAL_TOP_BLOCKAGE_REPORT" 2>/dev/null | tail -1)"
SIGNAL_TOP_BLOCKAGE_REMOVE="$(sed -n 's/^SIGNAL_TOP_ROUTE_BLOCKAGE_REMOVE_STATUS=//p' "$SIGNAL_TOP_BLOCKAGE_REPORT" 2>/dev/null | tail -1)"
SIGNAL_TOP_BLOCKAGE_STATUS="$(sed -n 's/^SIGNAL_TOP_ROUTE_BLOCKAGE_STATUS=//p' "$SIGNAL_TOP_BLOCKAGE_REPORT" 2>/dev/null | tail -1)"
IO_PIN_STATUS="$(sed -n 's/^REPORT_STATUS=//p' "$IO_PIN_SUMMARY" 2>/dev/null | tail -1)"
TAP_SLOW_SOUTH_PLAN_COUNT="$(awk -F, '$1 == "\"ro_slow_tap0_o\"" && $3 == "SOUTH" && $4 == "MET3" && $5 == "REQUESTED" {count++} END {print count + 0}' "$IO_PIN_CSV" 2>/dev/null)"
TAP_FAST_SOUTH_PLAN_COUNT="$(awk -F, '$1 == "\"ro_fast_tap0_o\"" && $3 == "SOUTH" && $4 == "MET3" && $5 == "REQUESTED" {count++} END {print count + 0}' "$IO_PIN_CSV" 2>/dev/null)"

ROUTE_DEF=""
for candidate in \
  "$PNR_DIR/def/04_route.def" \
  "$PNR_DIR/def/04_route_failed.def"
do
  if [ -s "$candidate" ]; then
    ROUTE_DEF="$candidate"
    break
  fi
done

TAP_SLOW_COUNT=0
TAP_FAST_COUNT=0
TAP_TOTAL_COUNT=0
if [ -n "$ROUTE_DEF" ]; then
  TAP_SLOW_COUNT="$(awk -v wanted=ro_slow_tap0_o '
    /^PINS[[:space:]]/ {in_pins=1; next}
    /^END PINS/ {in_pins=0}
    in_pins && /^-[[:space:]]/ && $2 == wanted {count++}
    END {print count + 0}
  ' "$ROUTE_DEF")"
  TAP_FAST_COUNT="$(awk -v wanted=ro_fast_tap0_o '
    /^PINS[[:space:]]/ {in_pins=1; next}
    /^END PINS/ {in_pins=0}
    in_pins && /^-[[:space:]]/ && $2 == wanted {count++}
    END {print count + 0}
  ' "$ROUTE_DEF")"
  TAP_TOTAL_COUNT="$(awk '
    /^PINS[[:space:]]/ {in_pins=1; next}
    /^END PINS/ {in_pins=0}
    in_pins && /^-[[:space:]]/ && $2 ~ /^ro_(slow|fast)_tap[0-9]+_o$/ {count++}
    END {print count + 0}
  ' "$ROUTE_DEF")"
fi

if [ "$PNR_RC" -eq 0 ] && \
   [ "$ROUTE_PASS" = "PASS" ] && \
   [ "$DRC_PASS" = "PASS" ] && \
   [ "$GEOMETRY_DRC" = "0" ] && \
   [ "$SHORTS" = "0" ] && \
   [ "$REGULAR_BAD" = "0" ] && \
   [ "$SPECIAL_BAD" = "0" ] && \
   [ "$SPECIAL_RAW_BAD" = "0" ] && \
   [ "$SPECIAL_NON_RO_BAD" = "0" ] && \
   [ "$UNROUTED" = "0" ] && \
   [ "$SIGNAL_TOP" = "MET3" ] && \
   [ "$ROUTER_TOP" = "METTP" ] && \
   [ "$ROUTE_COMMAND_STATUS" = "PASS" ] && \
   [ "$SIGNAL_TOP_BLOCKAGE_TEMPORARY" = "1" ] && \
   [ "$SIGNAL_TOP_BLOCKAGE_CREATE" = "PASS" ] && \
   [ "$SIGNAL_TOP_BLOCKAGE_REMOVE" = "PASS" ] && \
   [ "$SIGNAL_TOP_BLOCKAGE_STATUS" = "REMOVED" ] && \
   [ "$IO_PIN_STATUS" = "OK" ] && \
   [ "$TAP_SLOW_SOUTH_PLAN_COUNT" = "1" ] && \
   [ "$TAP_FAST_SOUTH_PLAN_COUNT" = "1" ] && \
   [ "$TAP_SLOW_COUNT" = "1" ] && \
   [ "$TAP_FAST_COUNT" = "1" ] && \
   [ "$TAP_TOTAL_COUNT" = "2" ]; then
  PNR_DECISION=PASS_CONTINUE
else
  PNR_DECISION=FAIL_STOP
fi

if [ -d "$PNR_DIR" ]; then
  mkdir -p "$PNR_DIR/reports"
  {
    echo "ROUTE_DEF=$ROUTE_DEF"
    echo "ro_slow_tap0_o_COUNT=$TAP_SLOW_COUNT"
    echo "ro_fast_tap0_o_COUNT=$TAP_FAST_COUNT"
    echo "RO_TAP_OBSERVABILITY_PIN_COUNT=$TAP_TOTAL_COUNT"
    if [ -n "$ROUTE_DEF" ]; then
      awk '
        /^PINS[[:space:]]/ {in_pins=1; next}
        /^END PINS/ {in_pins=0}
        in_pins && /^-[[:space:]]/ {
          if (active) {print record}
          active=($2 == "ro_slow_tap0_o" || $2 == "ro_fast_tap0_o")
          record=$0
          next
        }
        in_pins && active {record=record " " $0}
        END {if (active) print record}
      ' "$ROUTE_DEF"
    fi
  } > "$PNR_DIR/reports/tap_pin_def_excerpt.rpt"

  {
    echo "STEP=PHYSICAL_PNR"
    echo "PNR_RC=$PNR_RC"
    echo "ROUTE_STATUS=$ROUTE_PASS"
    echo "INNOVUS_VERIFY_DRC_STATUS=$DRC_PASS"
    echo "GEOMETRY_DRC_VIOLATIONS=$GEOMETRY_DRC"
    echo "SHORTS=$SHORTS"
    echo "REGULAR_NET_CONNECTIVITY_BAD=$REGULAR_BAD"
    echo "SPECIAL_NET_CONNECTIVITY_BAD=$SPECIAL_BAD"
    echo "SPECIAL_NET_CONNECTIVITY_RAW_BAD=$SPECIAL_RAW_BAD"
    echo "SPECIAL_NET_CONNECTIVITY_NON_RO_FAILURES=$SPECIAL_NON_RO_BAD"
    echo "UNROUTED_NETS=$UNROUTED"
    echo "signal_top_layer=$SIGNAL_TOP"
    echo "router_command_top_layer=$ROUTER_TOP"
    echo "ROUTE_COMMAND_STATUS=$ROUTE_COMMAND_STATUS"
    echo "SIGNAL_TOP_ROUTE_BLOCKAGE_TEMPORARY=$SIGNAL_TOP_BLOCKAGE_TEMPORARY"
    echo "SIGNAL_TOP_ROUTE_BLOCKAGE_CREATE_STATUS=$SIGNAL_TOP_BLOCKAGE_CREATE"
    echo "SIGNAL_TOP_ROUTE_BLOCKAGE_REMOVE_STATUS=$SIGNAL_TOP_BLOCKAGE_REMOVE"
    echo "SIGNAL_TOP_ROUTE_BLOCKAGE_STATUS=$SIGNAL_TOP_BLOCKAGE_STATUS"
    echo "IO_PIN_PLACEMENT_STATUS=$IO_PIN_STATUS"
    echo "ro_slow_tap0_o_SOUTH_MET3_PLAN_COUNT=$TAP_SLOW_SOUTH_PLAN_COUNT"
    echo "ro_fast_tap0_o_SOUTH_MET3_PLAN_COUNT=$TAP_FAST_SOUTH_PLAN_COUNT"
    echo "ro_slow_tap0_o_COUNT=$TAP_SLOW_COUNT"
    echo "ro_fast_tap0_o_COUNT=$TAP_FAST_COUNT"
    echo "RO_TAP_OBSERVABILITY_PIN_COUNT=$TAP_TOTAL_COUNT"
    echo "DECISION=$PNR_DECISION"
  } | tee "$PNR_DIR/reports/operator_gate_physical_pnr.rpt"

  mptdc_publish_snapshot innovus "$PNR_RUN" "$PNR_DIR" "PHYSICAL_PNR"
  PNR_PUBLISH_RC=$?
else
  PNR_PUBLISH_RC=99
fi

echo "PNR_RC=$PNR_RC"
echo "PNR_DIR=$PNR_DIR"
echo "PNR_DECISION=$PNR_DECISION"
echo "PNR_PUBLISH_RC=$PNR_PUBLISH_RC"

echo "===== route-layer intent ====="
grep -E '^(signal_top_layer|promote_signal_top_to_effective_floor|router_command_top_layer|keep_router_top_at_effective_floor)=' \
  "$PNR_DIR/reports/route_layer_intent.rpt" 2>/dev/null

echo "===== route status ====="
grep -E '^(ROUTE_STATUS|INNOVUS_VERIFY_DRC_STATUS|GEOMETRY_DRC_VIOLATIONS|SHORTS|REGULAR_NET_CONNECTIVITY_BAD|SPECIAL_NET_CONNECTIVITY_BAD|SPECIAL_NET_CONNECTIVITY_RAW_BAD|SPECIAL_NET_CONNECTIVITY_NON_RO_FAILURES|UNROUTED_NETS)=' \
  "$PNR_DIR/reports/route_status.rpt" 2>/dev/null

echo "===== TC timing and DRV ====="
cat "$PNR_DIR/reports/extracted_timing_status.rpt" 2>/dev/null
cat "$PNR_DIR/reports/drv_status.rpt" 2>/dev/null

echo "===== two buffered tap pins ====="
cat "$PNR_DIR/reports/tap_pin_def_excerpt.rpt" 2>/dev/null
```

Continue only when `PNR_DECISION=PASS_CONTINUE` and `PNR_PUBLISH_RC=0`.
TC timing and DRV remain separate evidence and do not turn a dirty physical
result into a pass.

### Archived PVS DRC and LVS

The historical `RO_GDS` below is the known real-OA export. Replace it if the
`RO_tune6` OA layout has changed. Never substitute the provisional no-RO top
GDS or a LEF-derived proxy.

```bash
set +e

SOURCE_CKPT=$PNR_DIR/checkpoints/04_route.enc.dat
RO_GDS=/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_211109_falsepath_nfast_risk_235618/drygds_oa_20260702_001608/merge_libs/RO_tune6_from_OA.gds
PVS_RUN_ID=${PNR_RUN}_realro_pvs
PVS_DIR=$MPTDC_INNOVUS_WORK/$PVS_RUN_ID

if [ "$PNR_DECISION" = "PASS_CONTINUE" ] && \
   [ "$PNR_PUBLISH_RC" -eq 0 ] && \
   [ -d "$SOURCE_CKPT" ] && \
   [ -s "$RO_GDS" ]; then
  sha256sum "$RO_GDS"
  MPTDC/scripts/pvs/00_prepare_pvs_inputs_from_checkpoint.sh \
    --checkpoint "$SOURCE_CKPT" \
    --run-id "$PVS_RUN_ID" \
    --ro-gds "$RO_GDS" \
    --strict-attribution \
    --expected-head "$EXPECTED_HEAD"
  PREP_RC=$?
else
  echo "STOP: clean PnR checkpoint or real RO GDS missing"
  PREP_RC=99
fi

PREP_REPORT="$PVS_DIR/reports/pvs_prepared_inputs.rpt"
TAP_REPORT="$PVS_DIR/reports/tap_pin_contract.rpt"
HASH_REPORT="$PVS_DIR/manifests/pvs_input_hashes.rpt"
PREP_STATUS="$(sed -n 's/^PVS_PREP_INPUT_STATUS=//p' "$PREP_REPORT" 2>/dev/null | tail -1)"
TAP_STATUS="$(sed -n 's/^TAP_PIN_CONTRACT_STATUS=//p' "$TAP_REPORT" 2>/dev/null | tail -1)"
TAP_COUNT="$(sed -n 's/^RO_TAP_OBSERVABILITY_PIN_COUNT=//p' "$TAP_REPORT" 2>/dev/null | tail -1)"
STRICT_ATTRIBUTION="$(sed -n 's/^STRICT_ATTRIBUTION=//p' "$HASH_REPORT" 2>/dev/null | tail -1)"
if [ -s "$HASH_REPORT" ]; then
  HASH_MANIFEST_PRESENT=1
else
  HASH_MANIFEST_PRESENT=0
fi

if [ "$PREP_RC" -eq 0 ] && \
   [ "$PREP_STATUS" = "PASS" ] && \
   [ "$TAP_STATUS" = "PASS" ] && \
   [ "$TAP_COUNT" = "2" ] && \
   [ "$STRICT_ATTRIBUTION" = "1" ] && \
   [ "$HASH_MANIFEST_PRESENT" = "1" ]; then
  PREP_DECISION=PASS_CONTINUE
else
  PREP_DECISION=FAIL_STOP
fi

PREP_SNAPSHOT_ID="${PVS_RUN_ID}_01_prepare"
if [ -d "$PVS_DIR" ]; then
  mkdir -p "$PVS_DIR/reports"
  {
    echo "STEP=PVS_PREPARATION"
    echo "PREP_RC=$PREP_RC"
    echo "PVS_PREP_INPUT_STATUS=$PREP_STATUS"
    echo "TAP_PIN_CONTRACT_STATUS=$TAP_STATUS"
    echo "RO_TAP_OBSERVABILITY_PIN_COUNT=$TAP_COUNT"
    echo "STRICT_ATTRIBUTION=$STRICT_ATTRIBUTION"
    echo "HASH_MANIFEST_PRESENT=$HASH_MANIFEST_PRESENT"
    echo "DECISION=$PREP_DECISION"
  } | tee "$PVS_DIR/reports/operator_gate_pvs_prepare.rpt"
  mptdc_publish_snapshot pvs "$PREP_SNAPSHOT_ID" "$PVS_DIR" "PVS_PREPARATION"
  PREP_PUBLISH_RC=$?
else
  PREP_PUBLISH_RC=99
fi

AUDIT_LAUNCHED=0
if [ "$PREP_DECISION" = "PASS_CONTINUE" ] && \
   [ "$PREP_PUBLISH_RC" -eq 0 ]; then
  AUDIT_LAUNCHED=1
  MPTDC/scripts/pvs/01_audit_pvs_templates.sh \
    --result-dir "$PVS_DIR" \
    --expected-head "$EXPECTED_HEAD" \
    2>&1 | tee "$PVS_DIR/logs/operator_template_audit.log"
  AUDIT_RC=${PIPESTATUS[0]}
else
  AUDIT_RC=99
fi

AUDIT_STATUS="$(sed -n 's/^PVS_TEMPLATE_AUDIT_STATUS=//p' "$PVS_DIR/manifests/pvs_template_audit.status" 2>/dev/null | tail -1)"
if [ "$AUDIT_LAUNCHED" -eq 1 ] && \
   [ "$AUDIT_RC" -eq 0 ] && \
   [ "$AUDIT_STATUS" = "PASS" ]; then
  AUDIT_DECISION=PASS_CONTINUE
else
  AUDIT_DECISION=FAIL_STOP
fi

AUDIT_SNAPSHOT_ID="${PVS_RUN_ID}_02_template_audit"
if [ "$AUDIT_LAUNCHED" -eq 1 ]; then
  {
    echo "STEP=PVS_TEMPLATE_AUDIT"
    echo "AUDIT_RC=$AUDIT_RC"
    echo "PVS_TEMPLATE_AUDIT_STATUS=$AUDIT_STATUS"
    echo "DECISION=$AUDIT_DECISION"
  } | tee "$PVS_DIR/reports/operator_gate_pvs_template_audit.rpt"
  mptdc_publish_snapshot pvs "$AUDIT_SNAPSHOT_ID" "$PVS_DIR" "PVS_TEMPLATE_AUDIT"
  AUDIT_PUBLISH_RC=$?
else
  AUDIT_PUBLISH_RC=99
fi

DRC_BASE_LAUNCHED=0
if [ "$AUDIT_DECISION" = "PASS_CONTINUE" ] && \
   [ "$AUDIT_PUBLISH_RC" -eq 0 ]; then
  DRC_BASE_LAUNCHED=1
  MPTDC/scripts/pvs/02_replay_pvs_drc_from_template.sh \
    --prepared-dir "$PVS_DIR" \
    --variant base \
    --expected-head "$EXPECTED_HEAD" \
    2>&1 | tee "$PVS_DIR/logs/operator_drc_base.log"
  DRC_BASE_RC=${PIPESTATUS[0]}
else
  DRC_BASE_RC=99
fi

DRC_BASE_REPORT="$PVS_DIR/reports/pvs_drc_base_status.rpt"
DRC_BASE_STATUS="$(sed -n 's/^STATUS=//p' "$DRC_BASE_REPORT" 2>/dev/null | tail -1)"
DRC_BASE_GATE="$(sed -n 's/^PVS_DRC_STATUS=//p' "$DRC_BASE_REPORT" 2>/dev/null | tail -1)"
DRC_BASE_VARIANT="$(sed -n 's/^PVS_DRC_VARIANT=//p' "$DRC_BASE_REPORT" 2>/dev/null | tail -1)"
DRC_BASE_PRIMARY="$(sed -n 's/^DRC_TOTAL_PRIMARY=//p' "$DRC_BASE_REPORT" 2>/dev/null | tail -1)"
DRC_BASE_EXPANDED="$(sed -n 's/^DRC_TOTAL_EXPANDED=//p' "$DRC_BASE_REPORT" 2>/dev/null | tail -1)"
if [ "$DRC_BASE_LAUNCHED" -eq 1 ] && \
   [ "$DRC_BASE_RC" -eq 0 ] && \
   [ "$DRC_BASE_STATUS" = "PASS" ] && \
   [ "$DRC_BASE_GATE" = "PASS" ] && \
   [ "$DRC_BASE_VARIANT" = "BASE" ] && \
   [ "$DRC_BASE_PRIMARY" = "0" ] && \
   [ "$DRC_BASE_EXPANDED" = "0" ]; then
  DRC_BASE_DECISION=PASS_CONTINUE
else
  DRC_BASE_DECISION=FAIL_STOP
fi

DRC_BASE_SNAPSHOT_ID="${PVS_RUN_ID}_03_drc_base"
if [ "$DRC_BASE_LAUNCHED" -eq 1 ]; then
  {
    echo "STEP=PVS_DRC_BASE"
    echo "DRC_BASE_RC=$DRC_BASE_RC"
    echo "STATUS=$DRC_BASE_STATUS"
    echo "PVS_DRC_STATUS=$DRC_BASE_GATE"
    echo "PVS_DRC_VARIANT=$DRC_BASE_VARIANT"
    echo "DRC_TOTAL_PRIMARY=$DRC_BASE_PRIMARY"
    echo "DRC_TOTAL_EXPANDED=$DRC_BASE_EXPANDED"
    echo "DECISION=$DRC_BASE_DECISION"
  } | tee "$PVS_DIR/reports/operator_gate_pvs_drc_base.rpt"
  mptdc_publish_snapshot pvs "$DRC_BASE_SNAPSHOT_ID" "$PVS_DIR" "PVS_DRC_BASE"
  DRC_BASE_PUBLISH_RC=$?
else
  DRC_BASE_PUBLISH_RC=99
fi

DRC_DENSITY_LAUNCHED=0
if [ "$DRC_BASE_DECISION" = "PASS_CONTINUE" ] && \
   [ "$DRC_BASE_PUBLISH_RC" -eq 0 ]; then
  DRC_DENSITY_LAUNCHED=1
  MPTDC/scripts/pvs/02_replay_pvs_drc_from_template.sh \
    --prepared-dir "$PVS_DIR" \
    --variant density \
    --expected-head "$EXPECTED_HEAD" \
    2>&1 | tee "$PVS_DIR/logs/operator_drc_density.log"
  DRC_DENSITY_RC=${PIPESTATUS[0]}
else
  DRC_DENSITY_RC=99
fi

DRC_DENSITY_REPORT="$PVS_DIR/reports/pvs_drc_density_status.rpt"
DRC_DENSITY_STATUS="$(sed -n 's/^STATUS=//p' "$DRC_DENSITY_REPORT" 2>/dev/null | tail -1)"
DRC_DENSITY_GATE="$(sed -n 's/^PVS_DRC_STATUS=//p' "$DRC_DENSITY_REPORT" 2>/dev/null | tail -1)"
DRC_DENSITY_VARIANT="$(sed -n 's/^PVS_DRC_VARIANT=//p' "$DRC_DENSITY_REPORT" 2>/dev/null | tail -1)"
DRC_DENSITY_PRIMARY="$(sed -n 's/^DRC_TOTAL_PRIMARY=//p' "$DRC_DENSITY_REPORT" 2>/dev/null | tail -1)"
DRC_DENSITY_EXPANDED="$(sed -n 's/^DRC_TOTAL_EXPANDED=//p' "$DRC_DENSITY_REPORT" 2>/dev/null | tail -1)"
if [ "$DRC_DENSITY_LAUNCHED" -eq 1 ] && \
   [ "$DRC_DENSITY_RC" -eq 0 ] && \
   [ "$DRC_DENSITY_STATUS" = "PASS" ] && \
   [ "$DRC_DENSITY_GATE" = "PASS" ] && \
   [ "$DRC_DENSITY_VARIANT" = "DENSITY" ] && \
   [ "$DRC_DENSITY_PRIMARY" = "0" ] && \
   [ "$DRC_DENSITY_EXPANDED" = "0" ]; then
  DRC_DENSITY_DECISION=PASS_CONTINUE
else
  DRC_DENSITY_DECISION=FAIL_STOP
fi

DRC_DENSITY_SNAPSHOT_ID="${PVS_RUN_ID}_04_drc_density"
if [ "$DRC_DENSITY_LAUNCHED" -eq 1 ]; then
  {
    echo "STEP=PVS_DRC_DENSITY"
    echo "DRC_DENSITY_RC=$DRC_DENSITY_RC"
    echo "STATUS=$DRC_DENSITY_STATUS"
    echo "PVS_DRC_STATUS=$DRC_DENSITY_GATE"
    echo "PVS_DRC_VARIANT=$DRC_DENSITY_VARIANT"
    echo "DRC_TOTAL_PRIMARY=$DRC_DENSITY_PRIMARY"
    echo "DRC_TOTAL_EXPANDED=$DRC_DENSITY_EXPANDED"
    echo "DECISION=$DRC_DENSITY_DECISION"
  } | tee "$PVS_DIR/reports/operator_gate_pvs_drc_density.rpt"
  mptdc_publish_snapshot pvs "$DRC_DENSITY_SNAPSHOT_ID" "$PVS_DIR" "PVS_DRC_DENSITY"
  DRC_DENSITY_PUBLISH_RC=$?
else
  DRC_DENSITY_PUBLISH_RC=99
fi

LVS_LAUNCHED=0
if [ "$DRC_DENSITY_DECISION" = "PASS_CONTINUE" ] && \
   [ "$DRC_DENSITY_PUBLISH_RC" -eq 0 ]; then
  LVS_LAUNCHED=1
  MPTDC/scripts/pvs/03_replay_pvs_lvs_from_template.sh \
    --prepared-dir "$PVS_DIR" \
    --expected-head "$EXPECTED_HEAD" \
    2>&1 | tee "$PVS_DIR/logs/operator_lvs.log"
  LVS_RC=${PIPESTATUS[0]}
else
  LVS_RC=99
fi

LVS_REPORT="$PVS_DIR/reports/pvs_lvs_status.rpt"
LVS_STATUS="$(sed -n 's/^STATUS=//p' "$LVS_REPORT" 2>/dev/null | tail -1)"
LVS_GATE="$(sed -n 's/^PVS_LVS_STATUS=//p' "$LVS_REPORT" 2>/dev/null | tail -1)"
LVS_TOOL_RC="$(sed -n 's/^PVS_RC=//p' "$LVS_REPORT" 2>/dev/null | tail -1)"
if [ "$LVS_LAUNCHED" -eq 1 ] && \
   [ "$LVS_RC" -eq 0 ] && \
   [ "$LVS_STATUS" = "PASS" ] && \
   [ "$LVS_GATE" = "MATCH" ] && \
   [ "$LVS_TOOL_RC" = "0" ]; then
  LVS_DECISION=PASS_CONTINUE
else
  LVS_DECISION=FAIL_STOP
fi

LVS_SNAPSHOT_ID="${PVS_RUN_ID}_05_lvs"
if [ "$LVS_LAUNCHED" -eq 1 ]; then
  {
    echo "STEP=PVS_LVS"
    echo "LVS_RC=$LVS_RC"
    echo "STATUS=$LVS_STATUS"
    echo "PVS_LVS_STATUS=$LVS_GATE"
    echo "PVS_RC=$LVS_TOOL_RC"
    echo "DECISION=$LVS_DECISION"
  } | tee "$PVS_DIR/reports/operator_gate_pvs_lvs.rpt"
  mptdc_publish_snapshot pvs "$LVS_SNAPSHOT_ID" "$PVS_DIR" "PVS_LVS"
  LVS_PUBLISH_RC=$?
else
  LVS_PUBLISH_RC=99
fi

echo "PREP_RC=$PREP_RC"
echo "PREP_DECISION=$PREP_DECISION"
echo "PREP_PUBLISH_RC=$PREP_PUBLISH_RC"
echo "AUDIT_RC=$AUDIT_RC"
echo "AUDIT_DECISION=$AUDIT_DECISION"
echo "AUDIT_PUBLISH_RC=$AUDIT_PUBLISH_RC"
echo "DRC_BASE_RC=$DRC_BASE_RC"
echo "DRC_BASE_DECISION=$DRC_BASE_DECISION"
echo "DRC_BASE_PUBLISH_RC=$DRC_BASE_PUBLISH_RC"
echo "DRC_DENSITY_RC=$DRC_DENSITY_RC"
echo "DRC_DENSITY_DECISION=$DRC_DENSITY_DECISION"
echo "DRC_DENSITY_PUBLISH_RC=$DRC_DENSITY_PUBLISH_RC"
echo "LVS_RC=$LVS_RC"
echo "LVS_DECISION=$LVS_DECISION"
echo "LVS_PUBLISH_RC=$LVS_PUBLISH_RC"

cat "$PVS_DIR/reports/tap_pin_contract.rpt" 2>/dev/null
cat "$PVS_DIR/manifests/pvs_input_hashes.rpt" 2>/dev/null
cat "$PVS_DIR/reports/pvs_drc_base_status.rpt" 2>/dev/null
cat "$PVS_DIR/reports/pvs_drc_density_status.rpt" 2>/dev/null
cat "$PVS_DIR/reports/pvs_lvs_status.rpt" 2>/dev/null
```

## What to Send for Review

Do not paste full Innovus or PVS logs into chat. After a step returns, send only
the five lines below, using the values printed by that step:

```text
STEP=PG_PROOF
DECISION=PASS_CONTINUE
EVIDENCE_ID=20260824_mptdc_bufftap0_simplepg_pgproof_123456
EVIDENCE_COMMIT=<commit printed by mptdc_publish_snapshot>
EVIDENCE_PUSH_RC=0
```

Use the matching step name and decision for pre-PnR, physical PnR, preparation,
template audit, base DRC, density DRC, or LVS. `EVIDENCE_PUSH_RC=0` means the
text evidence is on `origin/SPADMIC_test` and can be pulled for detailed review.
The snapshot contains the operator gate, status reports, manifests, small PVS
controls, and diagnostic log tails.

- Continue only when both `DECISION=PASS_CONTINUE` and the matching
  `*_PUBLISH_RC=0` are printed.
- On `DECISION=FAIL_STOP`, let the failed snapshot push complete, send the five
  lines above, and do not launch the next command.
- On a nonzero publish RC, stop and paste the final `EVIDENCE_*` lines because
  the reports are not yet available remotely.
- Never run `git add .`; the helper stages and commits only its one snapshot
  directory and updates `EXPECTED_HEAD` for the next guarded command.

No downstream GDS package is accepted if any gate is missing or nonzero. Even
when all physical-first gates pass, label the result TC-only and not final
tapeout signoff.
