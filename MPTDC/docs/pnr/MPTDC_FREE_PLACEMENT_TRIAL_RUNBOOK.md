# MPTDC Isolated Free-Placement PnR Trial

## Purpose

This run is an isolated attempt to rebuild the MPTDC physical implementation
from the proven TC Genus handoff with minimal physical placement constraints.
It does not alter the canonical Innovus profile and does not claim MMMC or
foundry signoff.

The mandatory manager-delivery sequence is:

1. One 4:3, 50% utilization PnR candidate.
2. One 45% utilization retry only if the first failure is placement/congestion.
3. Attributable base PVS DRC on the accepted checkpoint.
4. Full top-level PVS LVS with zero blackboxes.
5. Optional density DRC only when mandatory LVS finishes at least 90 minutes
   before the configured local deadline.

## Fixed Contracts

- Synthesis source: `MPTDC_TC_BufferedROTap0Pins_Genus_20260709_155623`.
- Timing scope: TC-only. No false-path, multicycle, clock, or uncertainty relaxation.
- Floorplan: width/height target 4:3; first utilization 0.50, retry 0.45.
- IO: inputs west, outputs east; deterministic north/south overflow only when needed.
- PD hierarchy: all 64 logical instances are required, but no matrix regions,
  fences, hierarchy boxes, column tags, or phase preplacement are applied.
- RO macros: broad diagonal R0/MX seeds, explicit `placed -> unplaced`
  eligibility transition, concurrent macro-aware placement, in-core/non-overlap
  readback, then fixed before PG construction; 2 um soft placement halos and no
  route blockage.
- RO PG mesh: the installed IC23.1 `addStripe` parser requires the value-taking
  form `-break_stripes_at_block_rings 1`. A bare option is invalid. The archived
  `20260828_mptdc_free_pnr_roblockring_151008_u50` attempt proved both RO block
  rings were created, then stopped at PG construction with `IMPTCM-6` because
  the value was omitted. No earlier archived MPTDC run exercised this option.
- Tie cells: exact 91 proven high targets, inserted before CTS and before fillers,
  maximum fanout 8 and maximum source distance 20 um.
- Fillers: enabled only after routing in the canonical stage, with
  `-add_fillers_with_drc false`; filler insertion cannot bypass signal DRC.
- Optimization: existing logical protection is retained. Innovus may resize and
  buffer through normal placement/CTS/route optimization. No broad logical
  `dontTouch` clearing is performed, and the old matrix-specific fast-tag ECO is
  disabled for this profile.
- Post-route timing: at most two setup passes and two hold passes.
- Antenna: no Innovus or PVS antenna repair. Only `R1M2P1`, `R1M3P1`,
  `R2M2P1`, and `R2M3P1` may be classified as the manager exception.
- LVS mismatch always stops. No blackbox is allowed in the full LVS result.

## Server Launch

Run in the foreground from the server login shell. The block deliberately uses
`set +e` so a failed gate returns control instead of closing the SSH session.

```bash
set +e

REPO=/home/validmgr/ksabra/2026_SPAD/SPADMIC
cd "$REPO"
CD_RC=$?

git checkout SPADMIC_test
CHECKOUT_RC=$?
git pull --ff-only origin SPADMIC_test
SYNC_RC=$?

EXPECTED_HEAD="$(git rev-parse HEAD 2>/dev/null)"
ORIGIN_HEAD="$(git rev-parse origin/SPADMIC_test 2>/dev/null)"
TRACKED_STATUS="$(git status --short --untracked-files=no 2>/dev/null)"

PIPELINE_PRECHECK=FAIL
PIPELINE_RC=99
PIPELINE_RUN="$(date +%Y%m%d)_mptdc_free_pnr_$(date +%H%M%S)"
PIPELINE_LOG="/tmp/${PIPELINE_RUN}.pipeline.log"

if [ "$CD_RC" -eq 0 ] && \
   [ "$CHECKOUT_RC" -eq 0 ] && \
   [ "$SYNC_RC" -eq 0 ] && \
   [ "$EXPECTED_HEAD" = "$ORIGIN_HEAD" ] && \
   [ -z "$TRACKED_STATUS" ]; then
  PIPELINE_PRECHECK=PASS

  export MPTDC_WORK_ROOT=/sim/ksabra/SPADMIC_work
  export MPTDC_INNOVUS_WORK=$MPTDC_WORK_ROOT/innovus

  bash MPTDC/pnr/scripts/server_run_mptdc_free_pnr_pipeline.sh \
    --run-id "$PIPELINE_RUN" \
    --expected-head "$EXPECTED_HEAD" \
    --handoff-dir "$MPTDC_WORK_ROOT/handoff/genus_typical_pnrcompat/MPTDC_TC_BufferedROTap0Pins_Genus_20260709_155623" \
    --ro-gds "$MPTDC_WORK_ROOT/ro6_oa_exports/20260827_mptdc_ro6_vddfix_fresh_export_150040/RO_tune6.gds" \
    --auto-density-deadline 22:00 \
    2>&1 | tee "$PIPELINE_LOG"

  PIPELINE_RC=${PIPESTATUS[0]}
else
  echo "STOP: pipeline checkout precheck failed; no EDA tool launched"
fi
```

The pipeline publishes each completed PnR attempt, including bounded manager
GIF/PNG images when capture succeeds, and the PVS attempt. Each
publish advances `SPADMIC_test`; the controller carries the returned
`NEXT_EXPECTED_HEAD` into the following stage.

## Send Back

Run this in the same shell immediately after the pipeline:

```bash
set +e

echo "===== SEND BACK MPTDC FREE PNR ====="
echo "PIPELINE_PRECHECK=$PIPELINE_PRECHECK"
echo "PIPELINE_RUN=$PIPELINE_RUN"
echo "PIPELINE_RC=$PIPELINE_RC"
echo "PIPELINE_LOG=$PIPELINE_LOG"

grep -E '^(BASE_RUN_ID|ATTEMPT50|ATTEMPT50_RC|PUBLISH50_RC|ATTEMPT45|ATTEMPT45_RC|PUBLISH45_RC|SELECTED_PNR_RUN|PVS_RUN|PVS_RC|PUBLISH_PVS_RC|MPTDC_FREE_PNR_PIPELINE_STATUS|SIGNOFF_ELIGIBLE|DECISION|NEXT_STAGE|NEXT_EXPECTED_HEAD)=' \
  "$PIPELINE_LOG" 2>/dev/null | tail -40

SELECTED_PNR_RUN="$(sed -n 's/^SELECTED_PNR_RUN=//p' "$PIPELINE_LOG" 2>/dev/null | tail -1)"
PVS_RUN="$(sed -n 's/^PVS_RUN=//p' "$PIPELINE_LOG" 2>/dev/null | tail -1)"
PNR_DIR="/sim/ksabra/SPADMIC_work/innovus/$SELECTED_PNR_RUN"
PVS_DIR="/sim/ksabra/SPADMIC_work/innovus/$PVS_RUN"

echo "===== PNR OPERATOR GATE ====="
cat "$PNR_DIR/reports/operator_gate_mptdc_free_placement_attempt.rpt" 2>/dev/null

echo "===== FREE PROFILE GATE ====="
cat "$PNR_DIR/reports/operator_gate_mptdc_free_placement_trial.rpt" 2>/dev/null

echo "===== RO CONCURRENT PLACEMENT GATE ====="
cat "$PNR_DIR/reports/free_ro_seed_status.rpt" 2>/dev/null
cat "$PNR_DIR/reports/free_macro_aware_placement.rpt" 2>/dev/null

echo "===== TIE GATE ====="
cat "$PNR_DIR/reports/tie1_routed_status.rpt" 2>/dev/null

echo "===== PVS OPERATOR GATE ====="
cat "$PVS_DIR/reports/operator_gate_mptdc_free_trial_pvs.rpt" 2>/dev/null

echo "===== BASE DRC CLASSIFICATION ====="
cat "$PVS_DIR/reports/pvs_free_trial_drc_classification.rpt" 2>/dev/null
cat "$PVS_DIR/reports/pvs_drc_base_nonzero_rules.tsv" 2>/dev/null

echo "===== LVS GATE ====="
cat "$PVS_DIR/reports/pvs_lvs_status.rpt" 2>/dev/null

echo "===== MANAGER IMAGES ====="
find "$PNR_DIR/manager" -maxdepth 1 -type f -printf '%f\t%s bytes\n' 2>/dev/null | LC_ALL=C sort
cat "$PNR_DIR/reports/manager_floorplan_image_status.rpt" 2>/dev/null
cat "$PNR_DIR/reports/manager_route_congestion_image_status.rpt" 2>/dev/null

echo "FINAL_HEAD=$(git rev-parse HEAD 2>/dev/null)"
echo "ORIGIN_HEAD=$(git rev-parse origin/SPADMIC_test 2>/dev/null)"
TRACKED_STATUS_FINAL="$(git status --short --untracked-files=no 2>/dev/null)"
echo "TRACKED_STATUS_FINAL=${TRACKED_STATUS_FINAL:-CLEAN}"
```

## Sole Non-Antenna PVS ECO

Do not run this section unless the first PVS gate reports all three values:

```text
BASE_DRC_CLASS=NON_ANTENNA_DRC
PVS_ECO_ATTEMPT_COUNT=0
DECISION=FAIL_STOP_ONE_ATTRIBUTED_ROUTING_ECO_ELIGIBLE
```

Review the exact PVS markers and identify every attributable routed net. The
reviewed command file must contain exactly one command and may use only one of
these helpers:

```tcl
mptdc_ckpt_route_selected_nets {net_a net_b}
mptdc_ckpt_route_selected_nets_route_design {net_a net_b}
mptdc_ckpt_route_selected_nets_detail_only {net_a net_b}
mptdc_ckpt_route_selected_nets_legacy {net_a net_b}
```

Create and commit the reviewed command before launching Innovus. Replace the
example net set; the precheck rejects an untracked file, a changed hash, more
than one command, arbitrary Tcl, or a second ECO.

```bash
set +e

cd /home/validmgr/ksabra/2026_SPAD/SPADMIC

SOURCE_PNR_RUN="$SELECTED_PNR_RUN"
SOURCE_PVS_RUN="$PVS_RUN"
ECO_NETS='REPLACE_WITH_EXACT_PVS_ATTRIBUTED_NETS'
ECO_COMMAND_REL="MPTDC/pnr/eco_commands/${SOURCE_PVS_RUN}_selected_nets.tcl"
ECO_COMMAND_FILE="$PWD/$ECO_COMMAND_REL"
ECO_COMMAND_PREP_STATUS=FAIL

if [ "$ECO_NETS" != REPLACE_WITH_EXACT_PVS_ATTRIBUTED_NETS ] && \
   [ -n "$ECO_NETS" ]; then
  mkdir -p "$(dirname "$ECO_COMMAND_FILE")"
  printf 'mptdc_ckpt_route_selected_nets {%s}\n' "$ECO_NETS" > "$ECO_COMMAND_FILE"
  git add "$ECO_COMMAND_REL"
  git commit -m "pnr: bind reviewed MPTDC free-trial PVS ECO nets"
  ECO_COMMAND_COMMIT_RC=$?
  git push origin SPADMIC_test
  ECO_COMMAND_PUSH_RC=$?
  ECO_COMMAND_PREP_STATUS=PASS
else
  echo "STOP: replace ECO_NETS with the exact PVS-attributed routed nets"
fi

EXPECTED_HEAD="$(git rev-parse HEAD 2>/dev/null)"
ORIGIN_HEAD="$(git rev-parse origin/SPADMIC_test 2>/dev/null)"
TRACKED_STATUS="$(git status --short --untracked-files=no 2>/dev/null)"
ECO_COMMAND_SHA256="$(sha256sum "$ECO_COMMAND_FILE" 2>/dev/null | awk '{print $1}')"
ECO_RUN="$(date +%Y%m%d)_mptdc_free_pvs_route_eco_$(date +%H%M%S)"
ECO_DIR="/sim/ksabra/SPADMIC_work/innovus/$ECO_RUN"
ECO_LOG="/tmp/${ECO_RUN}.driver.log"
ECO_RC=99

if [ "$ECO_COMMAND_PREP_STATUS" = PASS ] && \
   [ "$ECO_COMMAND_COMMIT_RC" -eq 0 ] && \
   [ "$ECO_COMMAND_PUSH_RC" -eq 0 ] && \
   [ "$EXPECTED_HEAD" = "$ORIGIN_HEAD" ] && \
   [ -z "$TRACKED_STATUS" ]; then
  source /eda/cadence/eda_2023-2024

  bash MPTDC/pnr/scripts/server_run_mptdc_free_trial_pvs_eco.sh \
    --source-pnr-run-id "$SOURCE_PNR_RUN" \
    --source-pvs-run-id "$SOURCE_PVS_RUN" \
    --run-id "$ECO_RUN" \
    --commands-file "$ECO_COMMAND_FILE" \
    --expected-commands-sha "$ECO_COMMAND_SHA256" \
    --authorization EXACT_MPTDC_FREE_TRIAL_ONE_PVS_ROUTING_ECO \
    --expected-head "$EXPECTED_HEAD" \
    2>&1 | tee "$ECO_LOG"
  ECO_RC=${PIPESTATUS[0]}
else
  echo "STOP: reviewed ECO command commit precheck failed"
fi
```

Only a passing ECO gate may be published and replayed through base DRC plus full
LVS. This is a new PVS run over the ECO checkpoint, not reuse of prior results.

```bash
set +e

ECO_PUBLISH_RC=99
ECO_PVS_RC=99
ECO_PVS_PUBLISH_RC=99

if [ "$ECO_RC" -eq 0 ] && \
   [ "$(sed -n 's/^MPTDC_FREE_TRIAL_PVS_ECO_STATUS=//p' "$ECO_DIR/reports/operator_gate_mptdc_free_trial_pvs_eco.rpt" | tail -1)" = PASS ]; then
  bash MPTDC/ci/publish_mptdc_server_snapshot.sh \
    innovus "$ECO_RUN" "$ECO_DIR" MPTDC_FREE_TRIAL_ONE_PVS_ROUTING_ECO
  ECO_PUBLISH_RC=$?
  EXPECTED_HEAD="$(git rev-parse HEAD 2>/dev/null)"

  ECO_PVS_RUN="${ECO_RUN}_pvs"
  ECO_PVS_DIR="/sim/ksabra/SPADMIC_work/innovus/$ECO_PVS_RUN"
  ECO_PVS_LOG="/tmp/${ECO_PVS_RUN}.driver.log"

  if [ "$ECO_PUBLISH_RC" -eq 0 ]; then
    bash MPTDC/scripts/pvs/server_run_mptdc_free_trial_pvs.sh \
      --pnr-run-id "$ECO_RUN" \
      --run-id "$ECO_PVS_RUN" \
      --expected-head "$EXPECTED_HEAD" \
      --ro-gds /sim/ksabra/SPADMIC_work/ro6_oa_exports/20260827_mptdc_ro6_vddfix_fresh_export_150040/RO_tune6.gds \
      --auto-density-deadline 22:00 \
      2>&1 | tee "$ECO_PVS_LOG"
    ECO_PVS_RC=${PIPESTATUS[0]}

    bash MPTDC/ci/publish_mptdc_server_snapshot.sh \
      pvs "$ECO_PVS_RUN" "$ECO_PVS_DIR" MPTDC_FREE_TRIAL_PVS_AFTER_ONE_ECO
    ECO_PVS_PUBLISH_RC=$?
  fi
else
  echo "STOP: routing ECO gate failed; PVS replay is not authorized"
fi

echo "===== SEND BACK MPTDC FREE PVS ECO ====="
echo "SOURCE_PNR_RUN=$SOURCE_PNR_RUN"
echo "SOURCE_PVS_RUN=$SOURCE_PVS_RUN"
echo "ECO_COMMAND_FILE=$ECO_COMMAND_FILE"
echo "ECO_COMMAND_SHA256=$ECO_COMMAND_SHA256"
echo "ECO_RUN=$ECO_RUN"
echo "ECO_RC=$ECO_RC"
echo "ECO_PUBLISH_RC=$ECO_PUBLISH_RC"
echo "ECO_PVS_RUN=${ECO_PVS_RUN:-NOT_RUN}"
echo "ECO_PVS_RC=$ECO_PVS_RC"
echo "ECO_PVS_PUBLISH_RC=$ECO_PVS_PUBLISH_RC"
cat "$ECO_DIR/reports/operator_gate_mptdc_free_trial_pvs_eco.rpt" 2>/dev/null
cat "${ECO_PVS_DIR:-/nonexistent}/reports/operator_gate_mptdc_free_trial_pvs.rpt" 2>/dev/null
echo "FINAL_HEAD=$(git rev-parse HEAD 2>/dev/null)"
```

## Stop Rules

- A non-placement/congestion 50% failure does not authorize the 45% retry.
- A failed 45% retry ends the PnR experiment.
- Any tie target missing, duplicated, disconnected, unrouted, or above fanout 8 stops.
- Any TC setup, hold, DRV, placement, PG, CTS, route, or checkpoint gate failure stops.
- Any base DRC rule outside the exact four antenna IDs stops before LVS.
- A non-antenna result reserves one routing-ECO attempt, but does not authorize
  geometry edits until its exact PVS marker inventory and source checkpoint hash
  are reviewed. Send back the DRC classification and rule TSV first.
- Any LVS result other than explicit `MATCH`, any blackbox, or any tool/evidence
  ambiguity stops. Process return code zero alone is not acceptance.

`MANAGER_DELIVERY_READY=YES` means the mandatory TC PnR, attributable base DRC
classification, and full LVS gates passed for this trial. `SIGNOFF_ELIGIBLE`
remains `NO` for TC-only scope, deferred density, an antenna exception, or
optional density debt. Optional density results are disclosed but do not
retroactively invalidate the already-completed mandatory manager package.
