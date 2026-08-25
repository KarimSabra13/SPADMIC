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

The third checkpoint repair,
`20260824_164921_mptdc_bufftap0_local_keepout_repair_v3`, is rejected. It
completed only the first net: after `u_core_n_66687` was deleted and rerouted,
the same MET2/VSS short moved from `{220.50 179.29 220.76 180.015}` to
approximately `{220.50 178.73 220.78 179.455}`. This is a pin-access-constrained
topology, not evidence that a larger keepout will work. Command 7 then stopped
because Innovus correctly created two blockage objects for the requested
`{MET1 MET2}` layers while the helper incorrectly expected one object total.
The reported final 5 DRCs and 3 shorts include the still-active two-layer
blockage and are not five canonical route defects. Do not restore the v3 output
checkpoint and do not rerun or enlarge any of its keepouts.

The published V4 through V7 checkpoint repairs are now retired. They proved
that deleting either conflicting signal via stack immediately opens its regular
net, while local reroute reconstructs the same PG collision. V7 also proved
that `editDelete -regular_wire_with_drc` is not a usable bounded selector in
this form: Innovus emitted `IMPSPR-340` because the command requires both
`-net` and `-status`. These are symptoms of the original placement topology,
not three independent post-route edits worth continuing.

The first fresh-halo run,
`20260825_mptdc_bufftap0_halo10_physical_123744`, stopped during placement
before CTS or routing. Both 10 um blockage commands passed and `checkPlace`
reported a legal placement, but the full-bbox audit found 8 ordinary cells in
the slow halo and 12 in the fast halo. This is consistent with a cell origin
being legal immediately outside a hard blockage while the cell body crosses
its edge. The phase buffers were not the failure: their minimum measured RO
clearance was 17.42 um.

The active recovery is therefore one fresh PnR from the accepted buffered-tap
handoff with a 10 um audited exclusion around each fixed RO macro. The actual
hard placer blockage adds 11.2 um in X, covering the widest standard-cell
buffer used here, and 4.48 um in Y, covering one complete JIHD row. Thus the
placement blockage clearances are 21.2 um in X and 14.48 um in Y while the
acceptance audit remains exactly 10 um. The closest fixed phase buffer remains
2.94 um outside the guarded blockage. No failed placement or V4-V7 repair
checkpoint is reused.
The second guarded-halo run,
`20260825_mptdc_bufftap0_halo10_physical_130313`, proves the placement fix. It
has two valid guarded blockages, zero 10 um halo intrusions, 17.42 um minimum
phase-buffer clearance, zero route shorts, zero regular-connectivity failures,
and exactly the two south MET3 tap0 pins. Its only geometry debt is two MET1
minimum-area markers, on `u_core_n_57960` and `u_core_n_57556`. The special
report contains only 15 point-like VDD/VSS `IMPVFC-94` wire ends and zero non-RO
failures. The run was rejected because the candidate gate still compared this
new guarded topology against the retired pre-halo 12-endpoint fingerprint.

Both generic filler cleanup commands, `ecoRoute -target` and
`ecoRoute -fix_drc`, already completed successfully in that run and the same
two markers remained. Repeating either command or rerunning the full flow is
therefore not the next action. The next run is a fresh-process, read-only
checkpoint probe around the two exact nets. It records their instance terms,
pin geometry, wire paths, via rectangles, and installed edit-command help while
requiring the initial and final physical tuples to remain identical. That
evidence determines the direction of one bounded Wire Editor landing extension
per marker. No repair, export, or PVS command is allowed before this probe is
reviewed.

## Acceptance Order

1. Reuse buffered Genus run
   `MPTDC_TC_BufferedROTap0Pins_Genus_20260709_155623`; do not resynthesize.
2. Reuse accepted PG proof
   `20260824_mptdc_bufftap0_simplepg_pgproof_135116`; do not repeat the sweep.
3. Require the exact audited PnR LEF path, SHA-256, 13 MET2 windows, 13 MET3
   windows, and the complete `S[0:7],rstb` access set.
4. Start a fresh full PnR with both RO macros fixed, a 10 um audit halo, and the
   mandatory 11.2 um X / 4.48 um Y placer guard around each macro. Do not
   restore a failed placement or V4-V7 repaired checkpoint.
5. Require two created guarded blockages, 21.2 um X / 14.48 um Y placement
   clearance, zero post-place 10 um audit-halo intrusions, valid instance boxes,
   phase-buffer clearance at least 10 um, and exactly two RO macros.
6. Require zero Innovus geometry DRC, zero shorts, zero regular-net failures,
   zero non-RO special failures, zero unrouted nets, TC setup PASS, TC hold PASS,
   DRV PASS, and successful power-report capture.
7. Require ordinary signal top MET3, router command top METTP, the temporary
   METTP blockage created and removed, and exactly the two south MET3 tap0 pins.
8. Prefer raw-clean special connectivity. Otherwise allow only the exact 15
   audited `HALO10_PNRLEF_15` `IMPVFC-94` VDD/VSS point endpoints, with no
   coordinate, count, net, or problem-class difference, as
   `PVS_CANDIDATE_EXACT_PG_WIRE_ENDS`.
9. Merge the explicitly supplied real-OA `RO_tune6` GDS under strict hashed
   attribution.
10. Require zero base PVS DRC, zero density-enabled PVS DRC, then explicit LVS
    MATCH on the same prepared inputs.
11. The resulting label is `MPTDC_TC_PVS_CLOSED_NOT_MMMC_SIGNOFF`. Full MMMC,
    characterized RO timing, PEX, IR/EM, and final tapeout remain outside scope.

## Step Decisions and Evidence

Every executable step writes an `operator_gate_*.rpt` with
`DECISION=PASS_CONTINUE`, the narrowly scoped physical
`DECISION=PVS_CANDIDATE_CONTINUE`, or `DECISION=FAIL_STOP`. Missing fields are
failures.
Publish the snapshot even when a step fails; the failed reports and diagnostic
log tails are what make remote analysis possible.

| Step | Required to continue | Snapshot kind |
|---|---|---|
| Pre-PnR | package RC 0, pre-PnR RC 0, `PRE_PNR_GATE=PASS` | `genus` |
| PG proof | wrapper RC 0, sroute PASS, PG cross-net shorts 0, non-RO failures 0, and either raw clean or bounded classified `IMPVFC-94` only | `innovus` |
| PnR LEF preparation | preparation PASS, `S[0:7]` plus `rstb` present, MET2/MET3 windows nonzero, unexpected-pin count 0, OBS trims nonzero | bundled into physical `innovus` snapshot |
| Physical PnR | exact handoff/PG proof/LEF, two audited 10 um RO halos with zero intrusions, TC setup/hold and DRV PASS, signal top MET3, router top METTP, temporary blockage removed, zero geometry/short/regular/non-RO/unrouted debt, exactly two south MET3 tap0 pins, and either raw special clean or the exact `HALO10_PNRLEF_15` PVS-candidate fingerprint | `innovus` |
| Route minimum-area probe | exact published 2-minimum-area/0-short guarded-halo source, exact 15-endpoint special profile, fresh single restore, no route edits, identical initial/final tuple, both target nets and their term/wire/via queries captured, exactly two tap0 pins | `innovus` |
| Route geometry probe | exact published 3-DRC/1-short source signature, fresh single restore, no route-edit command, identical initial/final physical tuple, all three target nets and endpoint terms found, nearby PG shapes captured, command help/schema evidence present, exactly two tap0 pins | `innovus` |
| Route geometry repair | retired diagnostic path; V4-V7 outputs are never downstream sources | `innovus` |
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

### 1. Accepted PG Proof (Do Not Rerun)

The required PG input is already published and accepted:

```text
PG_RUN_ID=20260824_mptdc_bufftap0_simplepg_pgproof_135116
DECISION=PASS_CONTINUE
POSTPLACE_PRE_ROUTE_PG_CROSS_NET_SHORT_COUNT=0
BLOCK_PG_PIN_STYLE=ring_aligned_vdd_vss_pair
BLOCK_PG_PIN_REQUESTED_COUNT=2
```

The physical driver requires this exact tracked run id. No PG command is needed
unless its preflight later reports that the published snapshot or server
checkpoint is missing.

### Completed PG SRoute Sweep

The isolated sweep is complete and has no winner. Its published decision is
`STRICT_PASS_COUNT=0`; rerunning it would repeat the same topology. The bounded
pre-route continuation in step 1 is not final connectivity acceptance. Step 2
still requires zero geometry DRC, shorts, regular-connectivity debt, non-RO
special-connectivity debt, and unrouted nets. Raw special connectivity must
either be clean or match the exact `HALO10_PNRLEF_15` PVS-candidate
fingerprint.

### 2. Current Command: Staged Normalized Via-Side Repair V2

The read-only probe completed as
`20260825_mptdc_bufftap0_route_minarea_probe_143229`. It proved that the source
checkpoint has exactly two MET1 minimum-area markers, zero shorts, zero regular
connectivity failures, the exact 15 guarded PG endpoints, intact pin/via
geometry, and exactly two tap0 pins. Its published `SPECIAL_SIGNATURE_STATUS`
was a reporting false negative: Innovus writes the count in the summary report
and the 15 exact coordinates in the sibling `_detailed.rpt`. The recovery gate
now evaluates that real report pair.

The V1 repair completed as
`20260825_mptdc_bufftap0_route_minarea_repair_v1_145836`. It was useful and
must not be rerun: `u_core_n_57960` closed, while `u_core_n_57556` improved
from `0.1064/0.202` to `0.1777/0.202`. The final tuple was one DRC, zero
shorts, zero regular-connectivity failures, and zero non-RO special-connectivity
failures. Innovus also canonicalized `VIA1_o` to the legal VIA1-class variant
`VIA1_X_so`; exact post-edit via-name equality was therefore an invalid gate.

This is the only Innovus command to run now. V2 restores the original
guarded-halo checkpoint in one fresh process and first reproduces only these two
MET1 landing stubs:

```text
u_core_n_57960: (363.72,358.12) -> (364.56,358.12), width 0.28
u_core_n_57556: (385.56,328.44) -> (384.72,328.44), width 0.28
```

V2 must then prove the exact intermediate state: one geometry DRC, zero shorts,
zero regular and non-RO special connectivity failures, and the sole geometry
marker `u_core_n_57556` at `0.1777/0.202`. It discovers the actual normalized
fixed MET1 stub endpoint from the Innovus database and adds one `0.56 um`,
`0.28 um`-requested segment eastward from its via-side endpoint. This is the
repository-validated method for a Wire Editor stub that saturates at
`0.1777/0.202`.

The command issues no explicit via add/delete, PG edit, placement edit, route
blockage, or router optimization command. Innovus VIA1-class canonicalization
is allowed and audited. It then extracts RC, runs TC setup/hold and DRV/power
checks, saves a new checkpoint, and publishes the evidence automatically.

```bash
set +e

REPO=/home/validmgr/ksabra/2026_SPAD/SPADMIC
TAG=$(date +%Y%m%d_%H%M%S)
SOURCE_PNR_RUN=20260825_mptdc_bufftap0_halo10_physical_130313
DRIVER_LOG=/tmp/${TAG}_mptdc_route_minarea_repair.driver.log
SYNC_RC=99
REPAIR_DRIVER_RC=99
REPO_READY=0

if [ -d "$REPO/.git" ]; then
  cd "$REPO"
  git checkout SPADMIC_test
  CHECKOUT_RC=$?
  if [ "$CHECKOUT_RC" -eq 0 ]; then
    git pull --ff-only origin SPADMIC_test
    SYNC_RC=$?
  fi
  HEAD_NOW="$(git rev-parse HEAD 2>/dev/null)"
  ORIGIN_HEAD="$(git rev-parse refs/remotes/origin/SPADMIC_test 2>/dev/null)"
  TRACKED_STATUS="$(git status --short --untracked-files=no 2>/dev/null)"
  if [ "$SYNC_RC" -eq 0 ] && [ -n "$HEAD_NOW" ] && \
     [ "$HEAD_NOW" = "$ORIGIN_HEAD" ] && [ -z "$TRACKED_STATUS" ]; then
    REPO_READY=1
  else
    echo "STOP: sync, HEAD, or tracked-tree gate failed"
    [ -n "$TRACKED_STATUS" ] && printf '%s\n' "$TRACKED_STATUS"
  fi
else
  echo "STOP: repository missing: $REPO"
fi

if [ "$REPO_READY" -eq 1 ]; then
  bash MPTDC/pnr/scripts/server_run_mptdc_ro6_recovery_stage.sh \
    --stage route-minarea-repair \
    --source-pnr-run-id "$SOURCE_PNR_RUN" \
    2>&1 | tee "$DRIVER_LOG"
  REPAIR_DRIVER_RC=${PIPESTATUS[0]}
else
  echo "STOP: exact minimum-area repair was not launched"
fi

REPAIR_RUN="$(sed -n 's/^RECOVERY_RUN_ID=//p' "$DRIVER_LOG" 2>/dev/null | tail -1)"
REPAIR_DIR=/sim/ksabra/SPADMIC_work/innovus/$REPAIR_RUN

echo "===== SEND BACK ====="
echo "SYNC_RC=$SYNC_RC"
echo "REPAIR_DRIVER_RC=$REPAIR_DRIVER_RC"
grep -E '^(RECOVERY_STAGE|RECOVERY_RUN_ID|TOOL_RC|DECISION|PUBLISH_RC|MINAREA_REPAIR_GATE_MODE|NEXT_EXPECTED_HEAD|NEXT_STAGE|NEXT_REQUIRED_PNR_RUN_ID)=' \
  "$DRIVER_LOG" 2>/dev/null | tail -20

echo "===== OPERATOR GATE ====="
grep -E '^(COMMAND_[12]_STATUS|MANUAL_ECO_STATUS|MANUAL_(PRE|BASE|POST)_(DRC|SHORTS|REGULAR_CONNECTIVITY_BAD|SPECIAL_CONNECTIVITY_NON_RO_FAILURES)|BASE_(MINAREA_MARKER|CANONICAL_VIA_SIDE)_STATUS|INITIAL_(DRC|SHORTS|REGULAR_CONNECTIVITY_BAD|SPECIAL_CONNECTIVITY_BAD|SPECIAL_CONNECTIVITY_RAW_BAD|SPECIAL_CONNECTIVITY_NON_RO_FAILURES|SPECIAL_DANGLING_COUNT)|FINAL_(DRC|SHORTS|REGULAR_CONNECTIVITY_BAD|SPECIAL_CONNECTIVITY_BAD|SPECIAL_CONNECTIVITY_RAW_BAD|SPECIAL_CONNECTIVITY_NON_RO_FAILURES|SPECIAL_DANGLING_COUNT|CHECKPOINT_DAT_EXISTS)|SPECIAL_SIGNATURE_STATUS|SETUP_STATUS_TC|TC_HOLD_STATUS|DRV_STATUS|POWER_REPORT_CAPTURE_STATUS|TIMING_GATE_STATUS|RO_TAP_OBSERVABILITY_PIN_COUNT|MINAREA_REPAIR_GATE_MODE|DECISION)=' \
  "$REPAIR_DIR/reports/operator_gate_route_min_area_repair.rpt" 2>/dev/null
```

Stop and send back the final lines unless every required line is present:

```text
REPAIR_DRIVER_RC=0
RECOVERY_STAGE=ROUTE_MIN_AREA_REPAIR
TOOL_RC=0
DECISION=PVS_CANDIDATE_CONTINUE
PUBLISH_RC=0
MINAREA_REPAIR_GATE_MODE=PVS_CANDIDATE_EXACT_PG_WIRE_ENDS
NEXT_STAGE=PVS
NEXT_REQUIRED_PNR_RUN_ID=<new repair run id>
```

The operator gate must additionally show `COMMAND_1_STATUS=PASS`,
`COMMAND_2_STATUS=PASS`, `MANUAL_ECO_STATUS=PASS`, initial `DRC=2` and
`SHORTS=0`, `MANUAL_BASE_DRC=1`, `MANUAL_BASE_SHORTS=0`,
`MANUAL_BASE_REGULAR_CONNECTIVITY_BAD=0`,
`MANUAL_BASE_SPECIAL_CONNECTIVITY_NON_RO_FAILURES=0`,
`BASE_MINAREA_MARKER_STATUS=PASS`,
`BASE_CANONICAL_VIA_SIDE_STATUS=PASS`, final `DRC=0` and `SHORTS=0`, zero
regular and non-RO special connectivity failures, unchanged
`SPECIAL_DANGLING_COUNT=15`,
`SPECIAL_SIGNATURE_STATUS=PASS`, `TIMING_GATE_STATUS=PASS`, and
`RO_TAP_OBSERVABILITY_PIN_COUNT=2`. `FINAL_SPECIAL_CONNECTIVITY_BAD=1` is
expected only for those exact 15 guarded PG wire ends; this is a PVS candidate,
not an Innovus special-connectivity-clean result. Any other result stops. Do
not run PVS until this step has been reviewed. When `PUBLISH_RC=0`, the detailed
reports are already on `origin/SPADMIC_test`; send only the two displayed
sections.

### Archived Physical and Repair History (Do Not Run)

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
tails. Its failed-route checkpoint was the source for the retired V4-V7
diagnostics below; it is not the source for the current fresh-halo run.

#### 2B. Completed Read-Only Route Geometry Probe

Do not rerun the old probe. Its published run is
`20260824_171645_mptdc_bufftap0_route_geometry_probe` at commit
`708ac835cbb0682c6e7cc0e78b27b61c6afbc118`. The Innovus process returned zero
and preserved the source tuple exactly: DRC 3, shorts 1, regular connectivity
0, RO-only special connectivity 12, and exactly two tap observability pins.

The operator probe gate failed because the original query followed
`instTerm.term`; the captured Innovus schema identifies the library terminal as
`instTerm.cellTerm`. The probe helper now uses that schema. This diagnostic
query error did not alter the checkpoint and does not require another probe
before the bounded repair because the published wire, via, marker, and nearby
PG geometry already identifies all three edits:

- `u_core_n_66687`: the VIA1/VIA2 stack at `(220.64,179.48)` intersects the VSS
  MET2 trunk. Remove that local stack and its bounded MET2 landing, insert one
  VIA1 at `(221.20,178.92)`, and bridge on MET2 to the existing routed MET2
  trunk at `(224.84,179.48)`. Remove the superseded MET3 branch and its remote
  `VIA2_o` so they cannot become dangling route objects.
- `u_core_n_67240`: the VIA1/VIA2 stack at `(219.80,224.14)` has only 0.02 um
  clearance from the VDD MET2 trunk, where 0.28 um is required. Remove that
  local stack and its bounded MET2 landing, insert one VIA1 at
  `(221.20,223.58)`, and bridge on MET2 to the existing routed MET2 trunk at
  `(229.32,225.40)`. Remove the superseded four-segment MET3 branch and its
  remote `VIA2_o`.
- `u_core_n_57563`: extend the MET1 landing from `(364.84,328.44)` to
  `(365.40,328.44)` at width 0.28 um to satisfy minimum area.

No PG shape, cell placement, broad router command, route blockage, waiver, or
prior v1/v2/v3 repaired checkpoint is part of this repair.

#### 2C. Retired Staged Bounded DRC-Wire Repair V7

V4 completed as a verified no-op. Innovus accepted the point-sized
`editDelete` command, but retained both vias because the `-area` box did not
fully contain their routed geometry. The V4 pre/post tuples remained
`DRC=3`, `SHORTS=1`, regular connectivity zero, and special non-RO failures
zero; no replacement wire, PG edit, or placement edit ran.

V5 proved that the geometry-bounded via deletion works: both old
`u_core_n_66687` vias were removed. It then inserted one `VIA1_o`, but the
coincident `editAddVia` intended for VIA2 returned success without creating a
second via. The helper stopped immediately, so `u_core_n_67240` and
`u_core_n_57563` were not edited. That generated checkpoint is rejected and is
not a source for V6 or V7.

V6 proved that the exact VIA1/VIA2 stack deletion works. It then stopped before
its old-MET2-landing delete because `net.wires` returned zero bounded rows. The
post-command evidence retained the same three geometry markers but reported one
open regular net. This is an Innovus object-ownership mismatch, not another
coordinate error: `verify_drc` still owned the MET2 violation marker, while the
generic `net.wires` collection could not enumerate its regular-wire shape. The
V6 checkpoint is rejected and is not a source for V7.

V7 restores the original source and uses Innovus's documented
`editDelete -regular_wire_with_drc` selector, bounded simultaneously by the
exact net, MET2 layer, and marker box. It does not use a `net.wires`
precondition for those two DRC-owned landings. After each stack deletion,
DRC-wire deletion, and net reconstruction, a fresh DRC and connectivity snapshot
must match an exact tuple before the next action runs. This makes any unexpected
selector scope immediately fatal instead of allowing a partially understood ECO
to continue.

The reconstruction still inserts exactly one new VIA1 per affected net, splices
it on MET2 into the existing remote MET2 trunk, and removes the superseded
remote VIA2 and bounded MET3 branch. The one-track-lower MET1 escape avoids the
DFRQJIHDX1 blockage exposed by V5. The third edit remains the bounded MET1
minimum-area patch on `u_core_n_57563`.

Do not run this block. It is retained only to reproduce the V7 evidence trail.
It restores the original
`20260824_154115_mptdc_bufftap0_pnrlef35_physical` failed-route checkpoint in a
fresh Innovus process. The driver verifies the tracked five-row marker signature
before launch, applies only the three edits listed above, reruns DRC and both
connectivity checks, saves a new checkpoint, and publishes all bounded evidence
to `origin/SPADMIC_test` even when the gate fails.

```bash
set +e

REPO=/home/validmgr/ksabra/2026_SPAD/SPADMIC
SOURCE_PNR_RUN=20260824_154115_mptdc_bufftap0_pnrlef35_physical
TAG=$(date +%Y%m%d_%H%M%S)
REPAIR_RUN=${TAG}_mptdc_bufftap0_manual_geometry_repair_v7
REPAIR_DIR=/sim/ksabra/SPADMIC_work/innovus/$REPAIR_RUN
DRIVER_LOG=/tmp/${REPAIR_RUN}.driver.log

SYNC_RC=99
REPAIR_DRIVER_RC=99
REPO_READY=0
HEAD_NOW=UNKNOWN
ORIGIN_HEAD=UNKNOWN
TRACKED_STATUS=UNKNOWN

if [ -d "$REPO/.git" ]; then
  cd "$REPO"
  git checkout SPADMIC_test
  git pull --ff-only origin SPADMIC_test
  SYNC_RC=$?
  HEAD_NOW="$(git rev-parse HEAD 2>/dev/null)"
  ORIGIN_HEAD="$(git rev-parse refs/remotes/origin/SPADMIC_test 2>/dev/null)"
  TRACKED_STATUS="$(git status --short --untracked-files=no 2>/dev/null)"
  if [ "$SYNC_RC" -eq 0 ] && [ -n "$HEAD_NOW" ] && \
     [ "$HEAD_NOW" = "$ORIGIN_HEAD" ] && [ -z "$TRACKED_STATUS" ]; then
    REPO_READY=1
  else
    echo "STOP: sync, HEAD, or tracked-tree gate failed"
    [ -n "$TRACKED_STATUS" ] && printf '%s\n' "$TRACKED_STATUS"
  fi
else
  echo "STOP: repository missing: $REPO"
fi

EXPECTED_HEAD="$HEAD_NOW"

if [ "$REPO_READY" -eq 1 ]; then
  bash MPTDC/pnr/scripts/server_run_mptdc_ro6_recovery_stage.sh \
    --stage route-geometry-repair \
    --run-id "$REPAIR_RUN" \
    --source-pnr-run-id "$SOURCE_PNR_RUN" \
    --expected-head "$EXPECTED_HEAD" \
    2>&1 | tee "$DRIVER_LOG"
  REPAIR_DRIVER_RC=${PIPESTATUS[0]}
else
  echo "STOP: V7 repair was not launched"
fi

echo "===== SEND BACK ====="
echo "SYNC_RC=$SYNC_RC"
echo "SOURCE_PNR_RUN=$SOURCE_PNR_RUN"
echo "REPAIR_RUN=$REPAIR_RUN"
echo "REPAIR_DRIVER_RC=$REPAIR_DRIVER_RC"
echo "FINAL_HEAD=$(git rev-parse HEAD 2>/dev/null)"
grep -E '^(RECOVERY_STAGE|RECOVERY_RUN_ID|TOOL_RC|DECISION|PUBLISH_RC|NEXT_EXPECTED_HEAD|NEXT_STAGE|NEXT_REQUIRED_REPAIR_RUN_ID|NEXT_REQUIRED_PNR_RUN_ID)=' \
  "$DRIVER_LOG" 2>/dev/null | tail -20
grep -E '^(STEP|REPAIR_RC|MANUAL_ECO_STATUS|INITIAL_DRC|INITIAL_SHORTS|INITIAL_REGULAR_CONNECTIVITY_BAD|INITIAL_SPECIAL_CONNECTIVITY_NON_RO_FAILURES|FINAL_DRC|FINAL_SHORTS|FINAL_REGULAR_CONNECTIVITY_BAD|FINAL_SPECIAL_CONNECTIVITY_NON_RO_FAILURES|FINAL_CHECKPOINT_DAT_EXISTS|RO_TAP_OBSERVABILITY_PIN_COUNT|GEOMETRY_REPAIR_GATE_MODE|DECISION)=' \
  "$REPAIR_DIR/reports/operator_gate_route_geometry_repair.rpt" 2>/dev/null
grep -E '^(MANUAL_ECO_MODE|VIA_DELETE_MODE|OLD_MET2_LANDING_DELETE_MODE|OBSOLETE_MET3_DELETE_MODE|VIA_INSERT_MODE|STAGED_TUPLE_GATES|REMOTE_VIA2_DELETE|REMOTE_MET2_TRUNK_SPLICE|N(66687|67240)_(STACK_DELETED_(DRC|SHORTS|REGULAR_CONNECTIVITY_BAD)|DRC_WIRE_DELETED_(DRC|SHORTS|REGULAR_CONNECTIVITY_BAD)|RECONNECTED_(DRC|SHORTS|REGULAR_CONNECTIVITY_BAD)|OLD_STACK_POST_DELETE_VIA_COUNT|NEW_VIA1_(VIA1_COUNT|VIA2_COUNT)|REMOTE_VIA2_(POST_DELETE_VIA_COUNT|POST_VIA_NAMES)|OBSOLETE_MET3_(DELETE_STATUS|POST_DELETE_WIRE_COUNT))|POST_DRC|POST_SHORTS|POST_REGULAR_CONNECTIVITY_BAD|POST_SPECIAL_CONNECTIVITY_NON_RO_FAILURES|MANUAL_ECO_STATUS|MANUAL_ECO_ERROR)=' \
  "$REPAIR_DIR/reports/manual_geometry_eco_v7.rpt" 2>/dev/null
```

The published V7 result is `DECISION=FAIL_STOP`. After the first via-stack
deletion, regular connectivity became bad, as expected. The next command was
rejected with `IMPSPR-340`: `-regular_wire_with_drc` requires both `-net` and
`-status`. No valid reconstructed route was produced. This confirms the
checkpoint-edit path is retired; do not reinterpret `TOOL_RC=0` from the outer
wrapper as repair success and do not use its generated checkpoint downstream.

#### 2D. Completed PnR-LEF Generation Reference

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

The current fresh-halo physical driver continues only with the common gates
below:

```text
CADENCE_ENV_STATUS=PASS
PNR_DRIVER_RC=0
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
RO_HALO_STATUS=PASS
RO_HALO_COUNT=2
RO_HALO_CLEARANCE_UM>=10.0
RO_HALO_PLACER_GUARD_X_UM>=11.2
RO_HALO_PLACER_GUARD_Y_UM>=4.48
RO_HALO_PLACEMENT_CLEARANCE_X_UM>=21.2
RO_HALO_PLACEMENT_CLEARANCE_Y_UM>=14.48
RO_HALO_OCCUPANCY_STATUS=PASS
RO_HALO_TOTAL_INTRUSION_COUNT=0
RO_HALO_INVALID_INSTANCE_BBOX_COUNT=0
RO_PHASE_PLACEMENT_STATUS=PASS
RO_PHASE_MIN_CLEARANCE_UM>=10.0
INNOVUS_VERIFY_DRC_STATUS=PASS
GEOMETRY_DRC_VIOLATIONS=0
SHORTS=0
REGULAR_NET_CONNECTIVITY_BAD=0
SPECIAL_NET_CONNECTIVITY_NON_RO_FAILURES=0
UNROUTED_NETS=0
EXTRACTION_STATUS=PASS
SETUP_STATUS_TC=PASS
TC_HOLD_STATUS=PASS
DRV_STATUS=PASS
POWER_REPORT_CAPTURE_STATUS=PASS
RO_TAP_OBSERVABILITY_PIN_COUNT=2
NEXT_STAGE=PVS
NEXT_REQUIRED_PNR_RUN_ID=<new physical PnR run id>
```

In addition, either `PHYSICAL_GATE_MODE=STRICT_CLEAN` with
`DECISION=PASS_CONTINUE`, or
`PHYSICAL_GATE_MODE=PVS_CANDIDATE_EXACT_PG_WIRE_ENDS` with
`DECISION=PVS_CANDIDATE_CONTINUE` and exact `HALO10_PNRLEF_15` fingerprint PASS
is required. The driver copies the exact generated LEF and summary into the
bounded evidence snapshot. Do not run PVS after any other decision.

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
MPTDC_TC_PVS_CLOSED=YES
FINAL_DECISION=MPTDC_TC_PVS_CLOSED_NOT_MMMC_SIGNOFF
NOT_MMMC_SIGNOFF=YES
FINAL_SIGNOFF=NO
READY_FOR_TAPEOUT=NO
DECISION=PASS_CONTINUE
PUBLISH_RC=0
```

### What to Send After Each Command

Do not paste full Innovus or PVS logs into chat. Send only:

```text
STEP=<PHYSICAL_PNR or PVS>
RUN_ID=<NEXT_REQUIRED_*_RUN_ID or PVS_RUN_ID>
DRIVER_RC=<printed driver RC>
DECISION=<printed decision>
PUBLISH_RC=<printed publish RC, when present>
HEAD=<printed repository HEAD>
```

For `PHYSICAL_PNR`, also send `PHYSICAL_GATE_MODE`. No full Innovus or PVS log
needs to be pasted when `PUBLISH_RC=0`.

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

- Continue only when the current short driver prints either
  `DECISION=PASS_CONTINUE` or `DECISION=PVS_CANDIDATE_CONTINUE`, together with
  `PUBLISH_RC=0` and the explicit next stage.
- On `DECISION=FAIL_STOP`, let the failed snapshot push complete, send the five
  lines above, and do not launch the next command.
- On a nonzero publish RC, stop and paste the final `EVIDENCE_*` lines because
  the reports are not yet available remotely.
- Never run `git add .`; the helper stages and commits only its one snapshot
  directory and updates `EXPECTED_HEAD` for the next guarded command.

No downstream GDS package is accepted if any gate is missing or nonzero. Even
when all physical-first gates pass, label the result TC-only and not final
tapeout signoff.
