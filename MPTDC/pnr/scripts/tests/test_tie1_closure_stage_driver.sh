#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_SCRIPT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DRIVER="$PNR_SCRIPT_DIR/server_run_mptdc_tie1_closure_stage.sh"
PG_HELPER_SOURCE="$PNR_SCRIPT_DIR/innovus_mptdc_pg_dangling_checkpoint_tools.tcl"
TMP_ROOT="$(mktemp -d /tmp/mptdc_tie1_closure_driver.XXXXXX)"
trap 'rm -rf "$TMP_ROOT"' EXIT

REPO="$TMP_ROOT/repo"
WORK="$TMP_ROOT/work"
TIE1_RUN=tie1_accepted
TIE1_REPORTS="$REPO/MPTDC/docs/server_snapshots/innovus/$TIE1_RUN/reports"
TIE1_CHECKPOINT="$WORK/$TIE1_RUN/checkpoints/repaired_route.enc.dat"
mkdir -p "$TIE1_REPORTS" "$TIE1_CHECKPOINT" "$REPO/MPTDC/pnr/scripts"
cp "$PG_HELPER_SOURCE" "$REPO/MPTDC/pnr/scripts/innovus_mptdc_pg_dangling_checkpoint_tools.tcl"
printf 'accepted tie checkpoint\n' > "$TIE1_CHECKPOINT/design.bin"

tree_hash() {
  local root="$1"
  (
    cd "$root"
    find -L . -type f ! -name '*.cdslck' ! -name '*.lock' ! -name '.*lock*' \
      -print0 | LC_ALL=C sort -z |
      while IFS= read -r -d '' file; do
        printf '%s\t' "$file"
        sha256sum "$file"
      done
  ) | sha256sum | awk '{print $1}'
}

TIE1_SHA="$(tree_hash "$TIE1_CHECKPOINT")"
cat > "$TIE1_REPORTS/operator_gate_tie1_insertion_trial.rpt" <<EOF
STEP=TIE1_INSERTION_TRIAL
AUTHORIZATION=EXACT_MPTDC_TIE1_FILLER_RECYCLE_ECOROUTE_TRIAL
TIE1_INSERTION_TRIAL_STATUS=PASS
FINAL_TARGET_SET_STATUS=PASS
FINAL_CONNECTED_HIGH_TERM_COUNT=91
FINAL_DISCONNECTED_HIGH_TERM_COUNT=0
FINAL_TIE_NET_COUNT=85
MAX_OBSERVED_TIE_FANOUT=3
FILLER_COUNT_AFTER=24856
FINAL_FILLER_MASTER_SET_STATUS=PASS
NONFILLER_FINGERPRINT_STATUS=PASS
FINAL_SITE_OCCUPANCY_STATUS=PASS
FINAL_PLACEMENT_SITE_OCCUPIED=907533
FINAL_PLACEMENT_SITE_CAPACITY=907533
FINAL_DRC=1
FINAL_SHORTS=0
FINAL_REGULAR_CONNECTIVITY_BAD=0
FINAL_SPECIAL_CONNECTIVITY_RAW_BAD=1
FINAL_SPECIAL_CONNECTIVITY_NON_RO_FAILURES=0
FINAL_UNROUTED_NETS=0
FINAL_DRC_MARKER_RECONCILIATION_STATUS=PASS
FINAL_DRC_MARKER_LIVE_COUNT=1
CANDIDATE_CHECKPOINT=$TIE1_CHECKPOINT
CANDIDATE_CHECKPOINT_SHA256=$TIE1_SHA
CANDIDATE_CHECKPOINT_STATUS=PASS
DECISION=PASS_TIE1_TRIAL_CONTINUE
EOF

FAKE_LAUNCHER="$TMP_ROOT/fake_launcher.sh"
cat > "$FAKE_LAUNCHER" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
run_id=""
checkpoint=""
commands=""
work=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-id) run_id="$2"; shift 2 ;;
    --checkpoint) checkpoint="$2"; shift 2 ;;
    --commands-file) commands="$2"; shift 2 ;;
    --innovus-work) work="$2"; shift 2 ;;
    *) shift ;;
  esac
done
test -d "$checkpoint"
test -s "$commands"
run_dir="$work/$run_id"
final_checkpoint="$run_dir/checkpoints/repaired_route.enc.dat"
mkdir -p "$final_checkpoint" "$run_dir/reports"
printf 'candidate %s\n' "$run_id" > "$final_checkpoint/design.bin"
special_report="$run_dir/reports/final_special_connectivity.rpt"

initial_drc=0
final_drc=0
final_special=1
final_special_raw=1
final_route_gate=0
final_unrouted=UNKNOWN
dangling=15
if grep -q 'minarea_endext' "$commands"; then
  initial_drc=1
  if grep -q '_trial_v13' "$commands"; then
    manual="$run_dir/reports/tie1_min_area_fixed_wire_endext_trial_v13.rpt"
  else
    manual="$run_dir/reports/tie1_min_area_fixed_wire_endext_replay_v13.rpt"
  fi
  cat > "$manual" <<'RPT'
MANUAL_ECO_STATUS=PASS
REPAIR_REVISION=V13
MANUAL_ECO_MODE=CANONICAL_FIXED_MET1_VIA_OVERLAP_SHELF_CLEARANCE_V13
ATTRIBUTE_EDIT_POLICY=NO_DB_ATTRIBUTE_EDITS
GEOMETRY_EDIT_POLICY=ONE_EXACT_TARGET_NET_REGULAR_FIXED_MET1_VIA_OVERLAP_SHELF
ROUTE_OPTIMIZER_POLICY=NO_ECOROUTE_NO_ROUTEDESIGN_NO_GLOBAL_OPTIMIZER
VIA_OVERLAP_SHELF_DIRECTION=HORIZONTAL_RIGHT
VIA_OVERLAP_SHELF_START=385.175 328.305
VIA_OVERLAP_SHELF_FINISH=385.560 328.305
PREDICTED_NEW_WIRE_BOX=385.175 328.190 385.560 328.420
EXPECTED_CANONICAL_WIRE_POINTS=385.290 328.305 385.445 328.305
EXPECTED_CANONICAL_WIRE_LENGTH_UM=0.155
V12_VIA_OVERLAP_SHELF_DISPOSITION=REJECTED_FE_RC_5_0_SPACING
V12_OBSERVED_NEW_WIRE_BOX=385.175 328.165 385.560 328.395
V12_OBSERVED_BLOCKAGE_SPACING_UM=0.215
V12_REQUIRED_BLOCKAGE_SPACING_UM=0.230
PREDICTED_BLOCKAGE_SPACING_UM=0.240
PREDICTED_BLOCKAGE_SPACING_MARGIN_UM=0.010
PREDICTED_CONNECTED_AREA_UM2=0.211450
WIRE_READBACK_POLICY=EXACT_BOX_AND_CANONICAL_CENTERLINE
PRE_MINAREA_MARKER_RECONCILIATION_STATUS=PASS
PRE_MINAREA_MARKER_FRESH_DRC_TOTAL=1
PRE_MINAREA_MARKER_GEOMETRY_COUNT=2
PRE_MINAREA_MARKER_LIVE_COUNT=1
PRE_MINAREA_MARKER_STALE_COUNT=1
PRE_MINAREA_MARKER_UNMAPPED_COUNT=0
FIXED_WIRE_SHELF_STATUS=PASS
FIXED_WIRE_SHELF_EFFECT_STATUS=PASS
FIXED_WIRE_SHELF_BOX_STATUS=PASS
N57556_VIA_OVERLAP_SHELF_BOX_MATCH_STATUS=PASS
N57556_VIA_OVERLAP_SHELF_CANONICAL_POINTS_MATCH_STATUS=PASS
N57556_VIA_OVERLAP_SHELF_CANONICAL_LENGTH_MATCH_STATUS=PASS
N57556_VIA_OVERLAP_SHELF_SHAPE_QUERY_POLICY=NOT_QUERIED_UNSUPPORTED_WIRE_ATTRIBUTE
TARGET_WIRE_COUNT_DELTA=1
TARGET_NEW_WIRE_COUNT=1
TARGET_PREEXISTING_WIRE_STATUS=PRESERVED
TARGET_WIRE_HANDLE_STATUS=ONE_EXACT_ADDITION
TARGET_OTHER_ROUTE_OBJECT_STATUS=UNCHANGED
RESERVED_FILL_OBJECT_STATUS=UNCHANGED
N57556_LANDING_REPRESENTATION_STATUS=UNCHANGED
TARGET_VIA_FINGERPRINT_STATUS=UNCHANGED
POST_MINAREA_MARKER_COUNT=0
VIA_OVERLAP_SHELF_LENGTH_UM=0.385
VIA_OVERLAP_SHELF_WIDTH_UM=0.23
RPT
else
  pg="$run_dir/reports/pg_dangling_analysis_status.rpt"
  if [[ "${MPTDC_PG_DANGLING_MODE:-}" == analyze ]]; then
    if [[ "${FAKE_PG_ANALYZE_RESULT:-eligible}" == blocked ]]; then
      cat > "$pg" <<'RPT'
PG_DANGLING_STATUS=ANALYSIS_ONLY
PG_DANGLING_ELIGIBLE_COUNT=14
PG_DANGLING_ALL_ELIGIBLE_STATUS=FAIL
PG_DANGLING_UNSAFE_LENGTH_COUNT=1
PG_DANGLING_DUPLICATE_HANDLE_COUNT=0
PG_DANGLING_MUTATION_ALLOWED=0
PG_DANGLING_DELETE_ATTEMPTS=0
PG_DANGLING_DELETE_SUCCESSES=0
RPT
    else
      cat > "$pg" <<'RPT'
PG_DANGLING_STATUS=ANALYSIS_ONLY
PG_DANGLING_ELIGIBLE_COUNT=15
PG_DANGLING_ALL_ELIGIBLE_STATUS=PASS
PG_DANGLING_UNSAFE_LENGTH_COUNT=0
PG_DANGLING_DUPLICATE_HANDLE_COUNT=0
PG_DANGLING_MUTATION_ALLOWED=0
PG_DANGLING_DELETE_ATTEMPTS=0
PG_DANGLING_DELETE_SUCCESSES=0
RPT
    fi
  elif [[ "${FAKE_PG_RESULT:-blocked}" == cleared ]]; then
    dangling=0
    final_special=0
    final_special_raw=0
    final_route_gate=1
    final_unrouted=0
    cat > "$pg" <<'RPT'
PG_DANGLING_STATUS=PASS_DANGLING_CLEARED
PG_DANGLING_ELIGIBLE_COUNT=15
PG_DANGLING_ALL_ELIGIBLE_STATUS=PASS
PG_DANGLING_UNSAFE_LENGTH_COUNT=0
PG_DANGLING_DUPLICATE_HANDLE_COUNT=0
PG_DANGLING_MUTATION_ALLOWED=1
PG_DANGLING_DELETE_ATTEMPTS=15
PG_DANGLING_DELETE_SUCCESSES=15
RPT
  else
    cat > "$pg" <<'RPT'
PG_DANGLING_STATUS=REVIEW_REQUIRED_PREFLIGHT_BLOCKED
PG_DANGLING_ELIGIBLE_COUNT=14
PG_DANGLING_ALL_ELIGIBLE_STATUS=FAIL
PG_DANGLING_UNSAFE_LENGTH_COUNT=1
PG_DANGLING_DUPLICATE_HANDLE_COUNT=0
PG_DANGLING_MUTATION_ALLOWED=0
PG_DANGLING_DELETE_ATTEMPTS=0
PG_DANGLING_DELETE_SUCCESSES=0
RPT
  fi
fi
if [[ "$dangling" == 15 ]]; then
  printf '    15 Problem(s) (IMPVFC-94): The net has dangling wire(s).\n' > "$special_report"
else
  printf 'Verification Complete : 0 Viols. 0 Wrngs.\n' > "$special_report"
fi
route_report="$run_dir/reports/final_report_route.rpt"
cat > "$route_report" <<'RPT'
#num needed restored net=0
#need_extraction net=0 (total=16414)
RPT
cat > "$run_dir/reports/checkpoint_repair_status.rpt" <<RPT
INITIAL_DRC=$initial_drc
FINAL_DRC=$final_drc
FINAL_SHORTS=0
FINAL_REGULAR_CONNECTIVITY_BAD=0
FINAL_SPECIAL_CONNECTIVITY_BAD=$final_special
FINAL_SPECIAL_CONNECTIVITY_RAW_BAD=$final_special_raw
FINAL_SPECIAL_CONNECTIVITY_NON_RO_FAILURES=0
FINAL_UNROUTED_NETS=$final_unrouted
FINAL_ROUTE_GATE_PASS=$final_route_gate
FINAL_SPECIAL_CONNECTIVITY_REPORT=$special_report
FINAL_REPORT_ROUTE=$route_report
FINAL_CHECKPOINT_DAT=$final_checkpoint
FINAL_CHECKPOINT_DAT_EXISTS=1
COMMAND_1_STATUS=PASS
RPT
exit 0
EOF

FAKE_PUBLISHER="$TMP_ROOT/fake_publisher.sh"
cat > "$FAKE_PUBLISHER" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
kind="$1"
run_id="$2"
source_dir="$3"
step="$4"
test "$kind" = innovus
snapshot="$FAKE_REPO/MPTDC/docs/server_snapshots/innovus/$run_id"
mkdir -p "$snapshot"
cp -R "$source_dir/reports" "$snapshot/reports"
cp -R "$source_dir/manifests" "$snapshot/manifests"
printf '%s\t%s\n' "$run_id" "$step" >> "$FAKE_PUBLISH_CALLS"
git -C "$FAKE_REPO" add MPTDC
git -C "$FAKE_REPO" commit -q -m "publish-$run_id"
EOF
chmod +x "$FAKE_LAUNCHER" "$FAKE_PUBLISHER"

git init -q -b SPADMIC_test "$REPO"
git -C "$REPO" config user.name 'MPTDC tie1 closure test'
git -C "$REPO" config user.email 'mptdc-tie1-closure@example.invalid'
git -C "$REPO" add MPTDC
git -C "$REPO" commit -q -m fixtures

run_stage() {
  local stage="$1" run_id="$2"
  shift 2
  local head arg
  local extra_env=()
  local driver_args=()
  for arg in "$@"; do
    if [[ "$arg" == *=* ]]; then
      extra_env+=("$arg")
    else
      driver_args+=("$arg")
    fi
  done
  head="$(git -C "$REPO" rev-parse HEAD)"
  env MPTDC_TIE1_CLOSURE_REPO_ROOT="$REPO" \
    MPTDC_TIE1_CLOSURE_LAUNCHER="$FAKE_LAUNCHER" \
    MPTDC_TIE1_CLOSURE_PUBLISHER="$FAKE_PUBLISHER" \
    MPTDC_INNOVUS_WORK="$WORK" FAKE_REPO="$REPO" \
    FAKE_PUBLISH_CALLS="$TMP_ROOT/publish.calls" "${extra_env[@]}" \
    bash "$DRIVER" --stage "$stage" --run-id "$run_id" \
      --source-tie1-run-id "$TIE1_RUN" --expected-head "$head" \
      "${driver_args[@]}"
}

TRIAL_RUN=minarea_trial
run_stage tie1-minarea-trial "$TRIAL_RUN" > "$TMP_ROOT/minarea_trial.stdout"
grep -qx 'DECISION=PASS_CONTINUE' "$TMP_ROOT/minarea_trial.stdout"
grep -qx 'NEXT_STAGE=TIE1_MINAREA_ENDEXT_REPLAY' "$TMP_ROOT/minarea_trial.stdout"
grep -qx 'ANTENNA_REPAIR_ATTEMPTED=NO' \
  "$WORK/$TRIAL_RUN/reports/operator_gate_tie1_minarea_endext_trial.rpt"
grep -qx 'REPAIR_REVISION=V13' \
  "$WORK/$TRIAL_RUN/reports/operator_gate_tie1_minarea_endext_trial.rpt"
grep -qx 'MANUAL_ECO_MODE=CANONICAL_FIXED_MET1_VIA_OVERLAP_SHELF_CLEARANCE_V13' \
  "$WORK/$TRIAL_RUN/reports/operator_gate_tie1_minarea_endext_trial.rpt"
grep -qx 'VIA_OVERLAP_SHELF_DIRECTION=HORIZONTAL_RIGHT' \
  "$WORK/$TRIAL_RUN/reports/operator_gate_tie1_minarea_endext_trial.rpt"
grep -qx 'VIA_OVERLAP_SHELF_START=385.175 328.305' \
  "$WORK/$TRIAL_RUN/reports/operator_gate_tie1_minarea_endext_trial.rpt"
grep -qx 'VIA_OVERLAP_SHELF_FINISH=385.560 328.305' \
  "$WORK/$TRIAL_RUN/reports/operator_gate_tie1_minarea_endext_trial.rpt"
grep -qx 'PREDICTED_NEW_WIRE_BOX=385.175 328.190 385.560 328.420' \
  "$WORK/$TRIAL_RUN/reports/operator_gate_tie1_minarea_endext_trial.rpt"
grep -qx 'N57556_VIA_OVERLAP_SHELF_BOX_MATCH_STATUS=PASS' \
  "$WORK/$TRIAL_RUN/reports/operator_gate_tie1_minarea_endext_trial.rpt"
grep -qx 'N57556_VIA_OVERLAP_SHELF_CANONICAL_POINTS_MATCH_STATUS=PASS' \
  "$WORK/$TRIAL_RUN/reports/operator_gate_tie1_minarea_endext_trial.rpt"
grep -qx 'N57556_VIA_OVERLAP_SHELF_CANONICAL_LENGTH_MATCH_STATUS=PASS' \
  "$WORK/$TRIAL_RUN/reports/operator_gate_tie1_minarea_endext_trial.rpt"
grep -qx 'PREDICTED_BLOCKAGE_SPACING_MARGIN_UM=0.010' \
  "$WORK/$TRIAL_RUN/reports/operator_gate_tie1_minarea_endext_trial.rpt"
grep -qx 'PREDICTED_CONNECTED_AREA_UM2=0.211450' \
  "$WORK/$TRIAL_RUN/reports/operator_gate_tie1_minarea_endext_trial.rpt"
grep -qx 'PRE_DRC_MARKER_GEOMETRY_COUNT=2' \
  "$WORK/$TRIAL_RUN/reports/operator_gate_tie1_minarea_endext_trial.rpt"
grep -qx 'PRE_DRC_MARKER_LIVE_COUNT=1' \
  "$WORK/$TRIAL_RUN/reports/operator_gate_tie1_minarea_endext_trial.rpt"
grep -qx 'PRE_DRC_MARKER_STALE_COUNT=1' \
  "$WORK/$TRIAL_RUN/reports/operator_gate_tie1_minarea_endext_trial.rpt"
grep -qx 'FINAL_UNROUTED_NETS_RAW=UNKNOWN' \
  "$WORK/$TRIAL_RUN/reports/operator_gate_tie1_minarea_endext_trial.rpt"
grep -qx 'FINAL_UNROUTED_NETS_SOURCE=tie1_closure_exact_special_debt_report_route_fallback' \
  "$WORK/$TRIAL_RUN/reports/operator_gate_tie1_minarea_endext_trial.rpt"
grep -qx 'TARGET_WIRE_HANDLE_STATUS=ONE_EXACT_ADDITION' \
  "$WORK/$TRIAL_RUN/reports/operator_gate_tie1_minarea_endext_trial.rpt"
grep -qx 'mptdc_ckpt_tie1_minarea_endext_trial_v13' \
  "$WORK/$TRIAL_RUN/manifests/tie1_closure.commands.tcl"

REPLAY_RUN=minarea_replay
run_stage tie1-minarea-replay "$REPLAY_RUN" \
  --source-minarea-trial-run-id "$TRIAL_RUN" \
  > "$TMP_ROOT/minarea_replay.stdout"
grep -qx 'DECISION=PASS_CONTINUE' "$TMP_ROOT/minarea_replay.stdout"
grep -qx 'NEXT_STAGE=TIE1_PG_DANGLING_ANALYSIS' "$TMP_ROOT/minarea_replay.stdout"

ANALYZE_RUN=pg_analyze
run_stage tie1-pg-analyze "$ANALYZE_RUN" \
  --source-minarea-replay-run-id "$REPLAY_RUN" \
  > "$TMP_ROOT/pg_analyze.stdout"
grep -qx 'PG_DELETE_TRIAL_OUTCOME=ANALYSIS_ALL_ELIGIBLE' \
  "$WORK/$ANALYZE_RUN/reports/operator_gate_tie1_pg_dangling_analysis.rpt"
grep -qx 'NEXT_STAGE=TIE1_PG_DANGLING_DELETE_TRIAL' "$TMP_ROOT/pg_analyze.stdout"

ANALYZE_BLOCKED_RUN=pg_analyze_blocked
run_stage tie1-pg-analyze "$ANALYZE_BLOCKED_RUN" \
  --source-minarea-replay-run-id "$REPLAY_RUN" FAKE_PG_ANALYZE_RESULT=blocked \
  > "$TMP_ROOT/pg_analyze_blocked.stdout"
grep -qx 'DECISION=PASS_ANALYSIS_KEEP_MINAREA_CANDIDATE' \
  "$TMP_ROOT/pg_analyze_blocked.stdout"
grep -qx 'PG_DELETE_TRIAL_OUTCOME=ANALYSIS_PREFLIGHT_BLOCKED_NO_MUTATION' \
  "$WORK/$ANALYZE_BLOCKED_RUN/reports/operator_gate_tie1_pg_dangling_analysis.rpt"
grep -qx 'PG_DANGLING_DELETE_ATTEMPTS=0' \
  "$WORK/$ANALYZE_BLOCKED_RUN/reports/operator_gate_tie1_pg_dangling_analysis.rpt"
grep -qx 'NEXT_STAGE=PVS_BASE_DRC_AND_RAW_LVS' "$TMP_ROOT/pg_analyze_blocked.stdout"

BLOCKED_RUN=pg_delete_blocked
run_stage tie1-pg-delete-trial "$BLOCKED_RUN" \
  --source-minarea-replay-run-id "$REPLAY_RUN" \
  > "$TMP_ROOT/pg_delete_blocked.stdout"
grep -qx 'DECISION=PASS_ANALYSIS_KEEP_MINAREA_CANDIDATE' \
  "$TMP_ROOT/pg_delete_blocked.stdout"
grep -qx 'PG_DANGLING_MUTATION_ALLOWED=0' \
  "$WORK/$BLOCKED_RUN/reports/operator_gate_tie1_pg_dangling_delete_trial.rpt"
grep -qx 'PG_DANGLING_DELETE_ATTEMPTS=0' \
  "$WORK/$BLOCKED_RUN/reports/operator_gate_tie1_pg_dangling_delete_trial.rpt"
grep -qx 'CANDIDATE_CHECKPOINT_STATUS=NOT_SELECTED' \
  "$WORK/$BLOCKED_RUN/reports/operator_gate_tie1_pg_dangling_delete_trial.rpt"

CLEARED_TRIAL_RUN=pg_delete_trial
run_stage tie1-pg-delete-trial "$CLEARED_TRIAL_RUN" \
  --source-minarea-replay-run-id "$REPLAY_RUN" FAKE_PG_RESULT=cleared \
  > "$TMP_ROOT/pg_delete_trial.stdout"
grep -qx 'PG_DELETE_TRIAL_OUTCOME=PASS_CLEARED' \
  "$WORK/$CLEARED_TRIAL_RUN/reports/operator_gate_tie1_pg_dangling_delete_trial.rpt"
grep -qx 'FINAL_SPECIAL_DANGLING_COUNT=0' \
  "$WORK/$CLEARED_TRIAL_RUN/reports/operator_gate_tie1_pg_dangling_delete_trial.rpt"
grep -qx 'NEXT_STAGE=TIE1_PG_DANGLING_DELETE_REPLAY' "$TMP_ROOT/pg_delete_trial.stdout"

CLEARED_REPLAY_RUN=pg_delete_replay
run_stage tie1-pg-delete-replay "$CLEARED_REPLAY_RUN" \
  --source-minarea-replay-run-id "$REPLAY_RUN" \
  --source-pg-trial-run-id "$CLEARED_TRIAL_RUN" FAKE_PG_RESULT=cleared \
  > "$TMP_ROOT/pg_delete_replay.stdout"
grep -qx 'DECISION=PASS_CONTINUE' "$TMP_ROOT/pg_delete_replay.stdout"
grep -qx 'NEXT_STAGE=PVS_BASE_DRC_AND_RAW_LVS' "$TMP_ROOT/pg_delete_replay.stdout"
grep -qx 'ANTENNA_REPAIR_ATTEMPTED=NO' \
  "$WORK/$CLEARED_REPLAY_RUN/reports/operator_gate_tie1_pg_dangling_delete_replay.rpt"

sed -i 's/^FINAL_DRC=0$/FINAL_DRC=1/' \
  "$REPO/MPTDC/docs/server_snapshots/innovus/$TRIAL_RUN/reports/operator_gate_tie1_minarea_endext_trial.rpt"
git -C "$REPO" add MPTDC
git -C "$REPO" commit -q -m broken-minarea-trial-ancestry
BROKEN_CALLS_BEFORE="$(wc -l < "$TMP_ROOT/publish.calls")"
set +e
run_stage tie1-pg-analyze pg_broken_ancestry \
  --source-minarea-replay-run-id "$REPLAY_RUN" \
  > "$TMP_ROOT/pg_broken_ancestry.stdout"
BROKEN_RC=$?
set -e
test "$BROKEN_RC" -eq 4
grep -qx 'TIE1_CLOSURE_PREFLIGHT=FAIL' "$TMP_ROOT/pg_broken_ancestry.stdout"
test "$(wc -l < "$TMP_ROOT/publish.calls")" -eq "$BROKEN_CALLS_BEFORE"

test "$(wc -l < "$TMP_ROOT/publish.calls")" -eq 7
echo 'MPTDC_TIE1_CLOSURE_STAGE_DRIVER_TEST=PASS'
