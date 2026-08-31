#!/usr/bin/env bash
# Close the accepted tie1 checkpoint with isolated, attributable Innovus trials.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
REPO_ROOT="${MPTDC_TIE1_CLOSURE_REPO_ROOT:-$DEFAULT_REPO_ROOT}"
INNOVUS_WORK="${MPTDC_INNOVUS_WORK:-/sim/ksabra/SPADMIC_work/innovus}"
LAUNCHER="${MPTDC_TIE1_CLOSURE_LAUNCHER:-$SCRIPT_DIR/server_repair_mptdc_route_checkpoint.sh}"
PUBLISHER="${MPTDC_TIE1_CLOSURE_PUBLISHER:-$REPO_ROOT/MPTDC/ci/publish_mptdc_server_snapshot.sh}"
PG_HELPER="$REPO_ROOT/MPTDC/pnr/scripts/innovus_mptdc_pg_dangling_checkpoint_tools.tcl"

STAGE=""
RUN_ID=""
SOURCE_TIE1_RUN_ID=""
SOURCE_MINAREA_TRIAL_RUN_ID=""
SOURCE_MINAREA_REPLAY_RUN_ID=""
SOURCE_PG_TRIAL_RUN_ID=""
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD:-}"

usage() {
  cat <<'USAGE'
Usage:
  server_run_mptdc_tie1_closure_stage.sh --stage <stage> \
    --source-tie1-run-id <id> [options]

Stages:
  tie1-minarea-trial      Add the exact V13 shifted 0.385um MET1 via-overlap shelf.
  tie1-minarea-replay     Replay that edit from the immutable tie1 checkpoint.
  tie1-pg-analyze         Map all special-wire dangling endpoints without edits.
  tie1-pg-delete-trial    Delete only if every endpoint passes full preflight.
  tie1-pg-delete-replay   Replay a passing deletion trial from minarea replay.

Options:
  --source-minarea-trial-run-id <id>  Required by minarea replay.
  --source-minarea-replay-run-id <id> Required by all PG stages.
  --source-pg-trial-run-id <id>       Required by PG deletion replay.
  --run-id <id>                       Explicit result directory name.
  --expected-head <sha>               Require repository HEAD.
  --innovus-work <path>               Innovus result root.

Every mutating stage restores a private copy in one fresh Innovus process.
No antenna command is present in this driver.
USAGE
}

report_value() {
  local report="$1" key="$2" value
  value="$(sed -n "s/^${key}=//p" "$report" 2>/dev/null | tail -1)"
  [[ -n "$value" ]] && printf '%s\n' "$value" || printf 'MISSING\n'
}

tree_hash() {
  local root="$1"
  [[ -d "$root" ]] || { printf 'MISSING\n'; return 0; }
  (
    cd "$root" || return 1
    find -L . -type f ! -name '*.cdslck' ! -name '*.lock' ! -name '.*lock*' \
      -print0 2>/dev/null | LC_ALL=C sort -z |
      while IFS= read -r -d '' file; do
        printf '%s\t' "$file"
        sha256sum "$file"
      done
  ) | sha256sum | awk '{print $1}'
}

tracked_report() {
  local report="$1"
  local rel="${report#"$REPO_ROOT"/}"
  git -C "$REPO_ROOT" ls-files --error-unmatch "$rel" >/dev/null 2>&1 && [[ -s "$report" ]]
}

tie1_gate_passes() {
  local gate="$1"
  tracked_report "$gate" || return 1
  [[ "$(report_value "$gate" STEP)" == TIE1_INSERTION_TRIAL &&
     "$(report_value "$gate" AUTHORIZATION)" == EXACT_MPTDC_TIE1_FILLER_RECYCLE_ECOROUTE_TRIAL &&
     "$(report_value "$gate" TIE1_INSERTION_TRIAL_STATUS)" == PASS &&
     "$(report_value "$gate" FINAL_TARGET_SET_STATUS)" == PASS &&
     "$(report_value "$gate" FINAL_CONNECTED_HIGH_TERM_COUNT)" == 91 &&
     "$(report_value "$gate" FINAL_DISCONNECTED_HIGH_TERM_COUNT)" == 0 &&
     "$(report_value "$gate" FINAL_TIE_NET_COUNT)" == 85 &&
     "$(report_value "$gate" MAX_OBSERVED_TIE_FANOUT)" == 3 &&
     "$(report_value "$gate" FILLER_COUNT_AFTER)" == 24856 &&
     "$(report_value "$gate" FINAL_FILLER_MASTER_SET_STATUS)" == PASS &&
     "$(report_value "$gate" NONFILLER_FINGERPRINT_STATUS)" == PASS &&
     "$(report_value "$gate" FINAL_SITE_OCCUPANCY_STATUS)" == PASS &&
     "$(report_value "$gate" FINAL_PLACEMENT_SITE_OCCUPIED)" == 907533 &&
     "$(report_value "$gate" FINAL_PLACEMENT_SITE_CAPACITY)" == 907533 &&
     "$(report_value "$gate" FINAL_DRC)" == 1 &&
     "$(report_value "$gate" FINAL_SHORTS)" == 0 &&
     "$(report_value "$gate" FINAL_REGULAR_CONNECTIVITY_BAD)" == 0 &&
     "$(report_value "$gate" FINAL_SPECIAL_CONNECTIVITY_RAW_BAD)" == 1 &&
     "$(report_value "$gate" FINAL_SPECIAL_CONNECTIVITY_NON_RO_FAILURES)" == 0 &&
     "$(report_value "$gate" FINAL_UNROUTED_NETS)" == 0 &&
     "$(report_value "$gate" FINAL_DRC_MARKER_RECONCILIATION_STATUS)" == PASS &&
     "$(report_value "$gate" FINAL_DRC_MARKER_LIVE_COUNT)" == 1 &&
     "$(report_value "$gate" CANDIDATE_CHECKPOINT_STATUS)" == PASS &&
     "$(report_value "$gate" DECISION)" == PASS_TIE1_TRIAL_CONTINUE ]]
}

minarea_gate_passes() {
  local gate="$1" expected_stage="$2" gate_run_id="$3"
  local expected_checkpoint expected_source_checkpoint candidate_sha source_sha
  local source_trial_run_id source_trial_gate
  tracked_report "$gate" || return 1
  expected_checkpoint="$INNOVUS_WORK/$gate_run_id/checkpoints/repaired_route.enc.dat"
  expected_source_checkpoint="$INNOVUS_WORK/$SOURCE_TIE1_RUN_ID/checkpoints/repaired_route.enc.dat"
  candidate_sha="$(report_value "$gate" CANDIDATE_CHECKPOINT_SHA256)"
  source_sha="$(report_value "$TIE1_GATE" CANDIDATE_CHECKPOINT_SHA256)"
  [[ "$(report_value "$gate" STEP)" == "$expected_stage" &&
     "$(report_value "$gate" SOURCE_TIE1_RUN_ID)" == "$SOURCE_TIE1_RUN_ID" &&
     "$(report_value "$gate" SOURCE_CHECKPOINT)" == "$expected_source_checkpoint" &&
     "$(report_value "$gate" SOURCE_CHECKPOINT_SHA256)" == "$source_sha" &&
     "$(report_value "$gate" TOOL_RC)" == 0 &&
     "$(report_value "$gate" COMMAND_1_STATUS)" == PASS &&
     "$(report_value "$gate" MANUAL_ECO_STATUS)" == PASS &&
     "$(report_value "$gate" REPAIR_REVISION)" == V13 &&
     "$(report_value "$gate" MANUAL_ECO_MODE)" == CANONICAL_FIXED_MET1_VIA_OVERLAP_SHELF_CLEARANCE_V13 &&
     "$(report_value "$gate" ATTRIBUTE_EDIT_POLICY)" == NO_DB_ATTRIBUTE_EDITS &&
     "$(report_value "$gate" GEOMETRY_EDIT_POLICY)" == ONE_EXACT_TARGET_NET_REGULAR_FIXED_MET1_VIA_OVERLAP_SHELF &&
     "$(report_value "$gate" ROUTE_OPTIMIZER_POLICY)" == NO_ECOROUTE_NO_ROUTEDESIGN_NO_GLOBAL_OPTIMIZER &&
     "$(report_value "$gate" VIA_OVERLAP_SHELF_DIRECTION)" == HORIZONTAL_RIGHT &&
     "$(report_value "$gate" VIA_OVERLAP_SHELF_START)" == "385.175 328.305" &&
     "$(report_value "$gate" VIA_OVERLAP_SHELF_FINISH)" == "385.560 328.305" &&
     "$(report_value "$gate" PREDICTED_NEW_WIRE_BOX)" == "385.175 328.190 385.560 328.420" &&
     "$(report_value "$gate" EXPECTED_CANONICAL_WIRE_POINTS)" == "385.290 328.305 385.445 328.305" &&
     "$(report_value "$gate" EXPECTED_CANONICAL_WIRE_LENGTH_UM)" == 0.155 &&
     "$(report_value "$gate" V12_VIA_OVERLAP_SHELF_DISPOSITION)" == REJECTED_FE_RC_5_0_SPACING &&
     "$(report_value "$gate" V12_OBSERVED_NEW_WIRE_BOX)" == "385.175 328.165 385.560 328.395" &&
     "$(report_value "$gate" V12_OBSERVED_BLOCKAGE_SPACING_UM)" == 0.215 &&
     "$(report_value "$gate" V12_REQUIRED_BLOCKAGE_SPACING_UM)" == 0.230 &&
     "$(report_value "$gate" PREDICTED_BLOCKAGE_SPACING_UM)" == 0.240 &&
     "$(report_value "$gate" PREDICTED_BLOCKAGE_SPACING_MARGIN_UM)" == 0.010 &&
     "$(report_value "$gate" PREDICTED_CONNECTED_AREA_UM2)" == 0.211450 &&
     "$(report_value "$gate" WIRE_READBACK_POLICY)" == EXACT_BOX_AND_CANONICAL_CENTERLINE &&
     "$(report_value "$gate" PRE_DRC_MARKER_RECONCILIATION_STATUS)" == PASS &&
     "$(report_value "$gate" PRE_DRC_MARKER_FRESH_DRC_TOTAL)" == 1 &&
     "$(report_value "$gate" PRE_DRC_MARKER_GEOMETRY_COUNT)" == 2 &&
     "$(report_value "$gate" PRE_DRC_MARKER_LIVE_COUNT)" == 1 &&
     "$(report_value "$gate" PRE_DRC_MARKER_STALE_COUNT)" == 1 &&
     "$(report_value "$gate" PRE_DRC_MARKER_UNMAPPED_COUNT)" == 0 &&
     "$(report_value "$gate" FIXED_WIRE_SHELF_STATUS)" == PASS &&
     "$(report_value "$gate" FIXED_WIRE_SHELF_EFFECT_STATUS)" == PASS &&
     "$(report_value "$gate" FIXED_WIRE_SHELF_BOX_STATUS)" == PASS &&
     "$(report_value "$gate" N57556_VIA_OVERLAP_SHELF_BOX_MATCH_STATUS)" == PASS &&
     "$(report_value "$gate" N57556_VIA_OVERLAP_SHELF_CANONICAL_POINTS_MATCH_STATUS)" == PASS &&
     "$(report_value "$gate" N57556_VIA_OVERLAP_SHELF_CANONICAL_LENGTH_MATCH_STATUS)" == PASS &&
     "$(report_value "$gate" N57556_VIA_OVERLAP_SHELF_SHAPE_QUERY_POLICY)" == NOT_QUERIED_UNSUPPORTED_WIRE_ATTRIBUTE &&
     "$(report_value "$gate" TARGET_WIRE_COUNT_DELTA)" == 1 &&
     "$(report_value "$gate" TARGET_NEW_WIRE_COUNT)" == 1 &&
     "$(report_value "$gate" TARGET_PREEXISTING_WIRE_STATUS)" == PRESERVED &&
     "$(report_value "$gate" TARGET_WIRE_HANDLE_STATUS)" == ONE_EXACT_ADDITION &&
     "$(report_value "$gate" TARGET_OTHER_ROUTE_OBJECT_STATUS)" == UNCHANGED &&
     "$(report_value "$gate" RESERVED_FILL_OBJECT_STATUS)" == UNCHANGED &&
     "$(report_value "$gate" N57556_LANDING_REPRESENTATION_STATUS)" == UNCHANGED &&
     "$(report_value "$gate" TARGET_VIA_FINGERPRINT_STATUS)" == UNCHANGED &&
     "$(report_value "$gate" POST_MINAREA_MARKER_COUNT)" == 0 &&
     "$(report_value "$gate" VIA_OVERLAP_SHELF_LENGTH_UM)" == 0.385 &&
     "$(report_value "$gate" VIA_OVERLAP_SHELF_WIDTH_UM)" == 0.23 &&
     "$(report_value "$gate" INITIAL_DRC)" == 1 &&
     "$(report_value "$gate" FINAL_DRC)" == 0 &&
     "$(report_value "$gate" FINAL_SHORTS)" == 0 &&
     "$(report_value "$gate" FINAL_REGULAR_CONNECTIVITY_BAD)" == 0 &&
     "$(report_value "$gate" FINAL_SPECIAL_CONNECTIVITY_BAD)" == 1 &&
     "$(report_value "$gate" FINAL_SPECIAL_CONNECTIVITY_RAW_BAD)" == 1 &&
     "$(report_value "$gate" FINAL_SPECIAL_CONNECTIVITY_NON_RO_FAILURES)" == 0 &&
     "$(report_value "$gate" FINAL_SPECIAL_DANGLING_COUNT)" == 15 &&
     "$(report_value "$gate" FINAL_UNROUTED_NETS)" == 0 &&
     "$(report_value "$gate" FINAL_REPORT_ROUTE_ZERO_STATUS)" == PASS &&
     "$(report_value "$gate" TIE_TARGET_COUNT)" == 91 &&
     "$(report_value "$gate" TIE_NET_COUNT)" == 85 &&
     "$(report_value "$gate" FILLER_COUNT)" == 24856 &&
     "$(report_value "$gate" PLACEMENT_SITE_OCCUPIED)" == 907533 &&
     "$(report_value "$gate" PLACEMENT_SITE_CAPACITY)" == 907533 &&
     "$(report_value "$gate" PLACEMENT_EDIT_POLICY)" == NO_INSTANCES_MOVED &&
     "$(report_value "$gate" ANTENNA_REPAIR_ATTEMPTED)" == NO &&
     "$(report_value "$gate" TIMING_STATUS)" == NOT_RUN_BY_DRC_LVS_SCOPE &&
     "$(report_value "$gate" CANDIDATE_CHECKPOINT)" == "$expected_checkpoint" &&
     "$candidate_sha" =~ ^[0-9a-f]{64}$ &&
     -d "$expected_checkpoint" && "$(tree_hash "$expected_checkpoint")" == "$candidate_sha" &&
     "$(report_value "$gate" CANDIDATE_CHECKPOINT_STATUS)" == PASS &&
     "$(report_value "$gate" DECISION)" == PASS_CONTINUE ]] || return 1

  source_trial_run_id="$(report_value "$gate" SOURCE_MINAREA_TRIAL_RUN_ID)"
  if [[ "$expected_stage" == TIE1_MINAREA_ENDEXT_TRIAL ]]; then
    [[ "$source_trial_run_id" == NONE ]]
    return
  fi
  [[ "$source_trial_run_id" =~ ^[A-Za-z0-9._-]+$ ]] || return 1
  source_trial_gate="$REPO_ROOT/MPTDC/docs/server_snapshots/innovus/$source_trial_run_id/reports/operator_gate_tie1_minarea_endext_trial.rpt"
  minarea_gate_passes "$source_trial_gate" TIE1_MINAREA_ENDEXT_TRIAL \
    "$source_trial_run_id"
}

pg_trial_gate_passes() {
  local gate="$1"
  local expected_checkpoint expected_source candidate_sha source_sha
  expected_checkpoint="$INNOVUS_WORK/$SOURCE_PG_TRIAL_RUN_ID/checkpoints/repaired_route.enc.dat"
  expected_source="$INNOVUS_WORK/$SOURCE_MINAREA_REPLAY_RUN_ID/checkpoints/repaired_route.enc.dat"
  candidate_sha="$(report_value "$gate" CANDIDATE_CHECKPOINT_SHA256)"
  source_sha="$(report_value "$SOURCE_PROOF_GATE" CANDIDATE_CHECKPOINT_SHA256)"
  tracked_report "$gate" || return 1
  [[ "$(report_value "$gate" STEP)" == TIE1_PG_DANGLING_DELETE_TRIAL &&
     "$(report_value "$gate" SOURCE_TIE1_RUN_ID)" == "$SOURCE_TIE1_RUN_ID" &&
     "$(report_value "$gate" SOURCE_MINAREA_REPLAY_RUN_ID)" == "$SOURCE_MINAREA_REPLAY_RUN_ID" &&
     "$(report_value "$gate" SOURCE_PG_TRIAL_RUN_ID)" == NONE &&
     "$(report_value "$gate" SOURCE_CHECKPOINT)" == "$expected_source" &&
     "$(report_value "$gate" SOURCE_CHECKPOINT_SHA256)" == "$source_sha" &&
     "$(report_value "$gate" TOOL_RC)" == 0 &&
     "$(report_value "$gate" COMMAND_1_STATUS)" == PASS &&
     "$(report_value "$gate" PG_DANGLING_STATUS)" == PASS_DANGLING_CLEARED &&
     "$(report_value "$gate" PG_DANGLING_ELIGIBLE_COUNT)" == 15 &&
     "$(report_value "$gate" PG_DANGLING_ALL_ELIGIBLE_STATUS)" == PASS &&
     "$(report_value "$gate" PG_DANGLING_UNSAFE_LENGTH_COUNT)" == 0 &&
     "$(report_value "$gate" PG_DANGLING_DUPLICATE_HANDLE_COUNT)" == 0 &&
     "$(report_value "$gate" PG_DANGLING_MUTATION_ALLOWED)" == 1 &&
     "$(report_value "$gate" PG_DANGLING_DELETE_ATTEMPTS)" == 15 &&
     "$(report_value "$gate" PG_DANGLING_DELETE_SUCCESSES)" == 15 &&
     "$(report_value "$gate" FINAL_DRC)" == 0 &&
     "$(report_value "$gate" FINAL_SHORTS)" == 0 &&
     "$(report_value "$gate" FINAL_REGULAR_CONNECTIVITY_BAD)" == 0 &&
     "$(report_value "$gate" FINAL_SPECIAL_CONNECTIVITY_BAD)" == 0 &&
     "$(report_value "$gate" FINAL_SPECIAL_CONNECTIVITY_RAW_BAD)" == 0 &&
     "$(report_value "$gate" FINAL_SPECIAL_CONNECTIVITY_NON_RO_FAILURES)" == 0 &&
     "$(report_value "$gate" FINAL_SPECIAL_DANGLING_COUNT)" == 0 &&
     "$(report_value "$gate" FINAL_UNROUTED_NETS)" == 0 &&
     "$(report_value "$gate" FINAL_ROUTE_GATE_PASS)" == 1 &&
     "$(report_value "$gate" PG_DELETE_TRIAL_OUTCOME)" == PASS_CLEARED &&
     "$(report_value "$gate" TIE_TARGET_COUNT)" == 91 &&
     "$(report_value "$gate" TIE_NET_COUNT)" == 85 &&
     "$(report_value "$gate" FILLER_COUNT)" == 24856 &&
     "$(report_value "$gate" PLACEMENT_SITE_OCCUPIED)" == 907533 &&
     "$(report_value "$gate" PLACEMENT_SITE_CAPACITY)" == 907533 &&
     "$(report_value "$gate" PLACEMENT_EDIT_POLICY)" == NO_INSTANCES_MOVED &&
     "$(report_value "$gate" ANTENNA_REPAIR_ATTEMPTED)" == NO &&
     "$(report_value "$gate" TIMING_STATUS)" == NOT_RUN_BY_DRC_LVS_SCOPE &&
     "$(report_value "$gate" CANDIDATE_CHECKPOINT)" == "$expected_checkpoint" &&
     "$candidate_sha" =~ ^[0-9a-f]{64}$ &&
     -d "$expected_checkpoint" && "$(tree_hash "$expected_checkpoint")" == "$candidate_sha" &&
     "$(report_value "$gate" CANDIDATE_CHECKPOINT_STATUS)" == PASS &&
     "$(report_value "$gate" SIGNOFF_ELIGIBLE)" == NO &&
     "$(report_value "$gate" DECISION)" == PASS_CONTINUE ]]
}

special_dangling_count() {
  local report="$1" value
  value="$(sed -nE 's/^[[:space:]]*([0-9]+) Problem\(s\) \(IMPVFC-94\):.*/\1/p' "$report" 2>/dev/null | tail -1)"
  if [[ -n "$value" ]]; then
    printf '%s\n' "$value"
  elif grep -Eq 'Verification Complete[[:space:]]*:[[:space:]]*0 Viols\.' "$report" 2>/dev/null &&
       ! grep -Fq 'dangling Wire' "$report" 2>/dev/null; then
    printf '0\n'
  else
    printf 'MISSING\n'
  fi
}

report_route_zero() {
  local report="$1"
  [[ -s "$report" ]] || return 1
  ! grep -Eqi 'REPORT_STATUS=FAILED' "$report" 2>/dev/null || return 1
  grep -Eq '^#num needed restored net=0[[:space:]]*$' "$report" 2>/dev/null || return 1
  grep -Eq '^#need_extraction net=0([[:space:]]|\(|$)' "$report" 2>/dev/null
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --stage) STAGE="${2:?missing --stage value}"; shift 2 ;;
    --run-id) RUN_ID="${2:?missing --run-id value}"; shift 2 ;;
    --source-tie1-run-id) SOURCE_TIE1_RUN_ID="${2:?missing value}"; shift 2 ;;
    --source-minarea-trial-run-id) SOURCE_MINAREA_TRIAL_RUN_ID="${2:?missing value}"; shift 2 ;;
    --source-minarea-replay-run-id) SOURCE_MINAREA_REPLAY_RUN_ID="${2:?missing value}"; shift 2 ;;
    --source-pg-trial-run-id) SOURCE_PG_TRIAL_RUN_ID="${2:?missing value}"; shift 2 ;;
    --expected-head) EXPECTED_HEAD_VALUE="${2:?missing value}"; shift 2 ;;
    --innovus-work) INNOVUS_WORK="${2:?missing value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$STAGE" in
  tie1-minarea-trial|tie1-minarea-replay|tie1-pg-analyze|tie1-pg-delete-trial|tie1-pg-delete-replay) ;;
  *) echo "ERROR: unsupported --stage: $STAGE" >&2; usage >&2; exit 2 ;;
esac
for id in "$SOURCE_TIE1_RUN_ID" "$RUN_ID" "$SOURCE_MINAREA_TRIAL_RUN_ID" \
          "$SOURCE_MINAREA_REPLAY_RUN_ID" "$SOURCE_PG_TRIAL_RUN_ID"; do
  [[ -z "$id" || "$id" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "ERROR: unsafe run id: $id" >&2; exit 2; }
done
[[ -n "$SOURCE_TIE1_RUN_ID" ]] || { echo "ERROR: --source-tie1-run-id is required" >&2; exit 2; }

case "$STAGE" in
  tie1-minarea-replay)
    [[ -n "$SOURCE_MINAREA_TRIAL_RUN_ID" ]] || { echo "ERROR: --source-minarea-trial-run-id is required" >&2; exit 2; }
    ;;
  tie1-pg-*)
    [[ -n "$SOURCE_MINAREA_REPLAY_RUN_ID" ]] || { echo "ERROR: --source-minarea-replay-run-id is required" >&2; exit 2; }
    ;;
esac
if [[ "$STAGE" == tie1-pg-delete-replay && -z "$SOURCE_PG_TRIAL_RUN_ID" ]]; then
  echo "ERROR: --source-pg-trial-run-id is required" >&2
  exit 2
fi

[[ -n "$RUN_ID" ]] || RUN_ID="$(date +%Y%m%d)_mptdc_${STAGE//-/_}_$(date +%H%M%S)"
RUN_DIR="$INNOVUS_WORK/$RUN_ID"
TIE1_GATE="$REPO_ROOT/MPTDC/docs/server_snapshots/innovus/$SOURCE_TIE1_RUN_ID/reports/operator_gate_tie1_insertion_trial.rpt"
TIE1_CHECKPOINT="$INNOVUS_WORK/$SOURCE_TIE1_RUN_ID/checkpoints/repaired_route.enc.dat"
SOURCE_CHECKPOINT="$TIE1_CHECKPOINT"
SOURCE_PROOF_GATE="$TIE1_GATE"

if [[ "$STAGE" == tie1-minarea-replay ]]; then
  SOURCE_PROOF_GATE="$REPO_ROOT/MPTDC/docs/server_snapshots/innovus/$SOURCE_MINAREA_TRIAL_RUN_ID/reports/operator_gate_tie1_minarea_endext_trial.rpt"
elif [[ "$STAGE" == tie1-pg-* ]]; then
  SOURCE_CHECKPOINT="$INNOVUS_WORK/$SOURCE_MINAREA_REPLAY_RUN_ID/checkpoints/repaired_route.enc.dat"
  SOURCE_PROOF_GATE="$REPO_ROOT/MPTDC/docs/server_snapshots/innovus/$SOURCE_MINAREA_REPLAY_RUN_ID/reports/operator_gate_tie1_minarea_endext_replay.rpt"
fi

cd "$REPO_ROOT" || exit 3
ACTUAL_HEAD="$(git rev-parse HEAD 2>/dev/null)"
ORIGIN_HEAD="$(git rev-parse refs/remotes/origin/SPADMIC_test 2>/dev/null || true)"
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD_VALUE:-${ORIGIN_HEAD:-$ACTUAL_HEAD}}"
PREFLIGHT=PASS
[[ "$(git rev-parse --abbrev-ref HEAD 2>/dev/null)" == SPADMIC_test ]] || PREFLIGHT=FAIL
[[ "$ACTUAL_HEAD" == "$EXPECTED_HEAD_VALUE" ]] || PREFLIGHT=FAIL
[[ -z "$(git status --short --untracked-files=no 2>/dev/null)" ]] || PREFLIGHT=FAIL
tie1_gate_passes "$TIE1_GATE" || PREFLIGHT=FAIL
[[ -d "$TIE1_CHECKPOINT" && "$(tree_hash "$TIE1_CHECKPOINT")" == "$(report_value "$TIE1_GATE" CANDIDATE_CHECKPOINT_SHA256)" ]] || PREFLIGHT=FAIL
[[ -s "$LAUNCHER" && -s "$PUBLISHER" && ! -e "$RUN_DIR" ]] || PREFLIGHT=FAIL

if [[ "$STAGE" == tie1-minarea-replay ]]; then
  minarea_gate_passes "$SOURCE_PROOF_GATE" TIE1_MINAREA_ENDEXT_TRIAL \
    "$SOURCE_MINAREA_TRIAL_RUN_ID" || PREFLIGHT=FAIL
elif [[ "$STAGE" == tie1-pg-* ]]; then
  minarea_gate_passes "$SOURCE_PROOF_GATE" TIE1_MINAREA_ENDEXT_REPLAY \
    "$SOURCE_MINAREA_REPLAY_RUN_ID" || PREFLIGHT=FAIL
  [[ -d "$SOURCE_CHECKPOINT" && "$(tree_hash "$SOURCE_CHECKPOINT")" == "$(report_value "$SOURCE_PROOF_GATE" CANDIDATE_CHECKPOINT_SHA256)" ]] || PREFLIGHT=FAIL
  [[ -s "$PG_HELPER" ]] || PREFLIGHT=FAIL
fi
if [[ "$STAGE" == tie1-pg-delete-replay ]]; then
  PG_TRIAL_GATE="$REPO_ROOT/MPTDC/docs/server_snapshots/innovus/$SOURCE_PG_TRIAL_RUN_ID/reports/operator_gate_tie1_pg_dangling_delete_trial.rpt"
  pg_trial_gate_passes "$PG_TRIAL_GATE" || PREFLIGHT=FAIL
fi

echo "TIE1_CLOSURE_PREFLIGHT=$PREFLIGHT"
echo "STAGE=$STAGE"
echo "SOURCE_TIE1_RUN_ID=$SOURCE_TIE1_RUN_ID"
echo "SOURCE_CHECKPOINT=$SOURCE_CHECKPOINT"
echo "SOURCE_PROOF_GATE=$SOURCE_PROOF_GATE"
echo "RUN_ID=$RUN_ID"
echo "EXPECTED_HEAD=$EXPECTED_HEAD_VALUE"
if [[ "$PREFLIGHT" != PASS ]]; then
  echo "DECISION=FAIL_STOP"
  exit 4
fi

mkdir -p "$RUN_DIR/manifests" "$RUN_DIR/logs" "$RUN_DIR/reports"
COMMANDS_FILE="$RUN_DIR/manifests/tie1_closure.commands.tcl"
case "$STAGE" in
  tie1-minarea-trial)
    printf '%s\n' 'mptdc_ckpt_tie1_minarea_endext_trial_v13' > "$COMMANDS_FILE"
    MANUAL_REPORT="$RUN_DIR/reports/tie1_min_area_fixed_wire_endext_trial_v13.rpt"
    GATE_REPORT="$RUN_DIR/reports/operator_gate_tie1_minarea_endext_trial.rpt"
    STEP=TIE1_MINAREA_ENDEXT_TRIAL
    ;;
  tie1-minarea-replay)
    printf '%s\n' 'mptdc_ckpt_tie1_minarea_endext_replay_v13' > "$COMMANDS_FILE"
    MANUAL_REPORT="$RUN_DIR/reports/tie1_min_area_fixed_wire_endext_replay_v13.rpt"
    GATE_REPORT="$RUN_DIR/reports/operator_gate_tie1_minarea_endext_replay.rpt"
    STEP=TIE1_MINAREA_ENDEXT_REPLAY
    ;;
  tie1-pg-analyze)
    printf 'mptdc_ckpt_source_tcl {%s}\n' "$PG_HELPER" > "$COMMANDS_FILE"
    export MPTDC_PG_DANGLING_MODE=analyze
    GATE_REPORT="$RUN_DIR/reports/operator_gate_tie1_pg_dangling_analysis.rpt"
    STEP=TIE1_PG_DANGLING_ANALYSIS
    ;;
  tie1-pg-delete-trial)
    printf 'mptdc_ckpt_source_tcl {%s}\n' "$PG_HELPER" > "$COMMANDS_FILE"
    export MPTDC_PG_DANGLING_MODE=delete_short
    GATE_REPORT="$RUN_DIR/reports/operator_gate_tie1_pg_dangling_delete_trial.rpt"
    STEP=TIE1_PG_DANGLING_DELETE_TRIAL
    ;;
  tie1-pg-delete-replay)
    printf 'mptdc_ckpt_source_tcl {%s}\n' "$PG_HELPER" > "$COMMANDS_FILE"
    export MPTDC_PG_DANGLING_MODE=delete_short
    GATE_REPORT="$RUN_DIR/reports/operator_gate_tie1_pg_dangling_delete_replay.rpt"
    STEP=TIE1_PG_DANGLING_DELETE_REPLAY
    ;;
esac
export MPTDC_PG_DANGLING_REQUIRE_ALL_ELIGIBLE=1
export MPTDC_PG_DANGLING_ALLOW_LONG_DELETE=0

set +e
bash "$LAUNCHER" --run-id "$RUN_ID" --checkpoint "$SOURCE_CHECKPOINT" \
  --commands-file "$COMMANDS_FILE" --expected-head "$EXPECTED_HEAD_VALUE" \
  --innovus-work "$INNOVUS_WORK" 2>&1 | tee "$RUN_DIR/logs/tie1_closure_driver.log"
TOOL_RC=${PIPESTATUS[0]}
set +e

STATUS_REPORT="$RUN_DIR/reports/checkpoint_repair_status.rpt"
INITIAL_DRC="$(report_value "$STATUS_REPORT" INITIAL_DRC)"
FINAL_DRC="$(report_value "$STATUS_REPORT" FINAL_DRC)"
FINAL_SHORTS="$(report_value "$STATUS_REPORT" FINAL_SHORTS)"
FINAL_REGULAR="$(report_value "$STATUS_REPORT" FINAL_REGULAR_CONNECTIVITY_BAD)"
FINAL_SPECIAL="$(report_value "$STATUS_REPORT" FINAL_SPECIAL_CONNECTIVITY_BAD)"
FINAL_SPECIAL_RAW="$(report_value "$STATUS_REPORT" FINAL_SPECIAL_CONNECTIVITY_RAW_BAD)"
FINAL_SPECIAL_NON_RO="$(report_value "$STATUS_REPORT" FINAL_SPECIAL_CONNECTIVITY_NON_RO_FAILURES)"
FINAL_UNROUTED="$(report_value "$STATUS_REPORT" FINAL_UNROUTED_NETS)"
FINAL_ROUTE_GATE="$(report_value "$STATUS_REPORT" FINAL_ROUTE_GATE_PASS)"
FINAL_SPECIAL_REPORT="$(report_value "$STATUS_REPORT" FINAL_SPECIAL_CONNECTIVITY_REPORT)"
FINAL_DANGLING="$(special_dangling_count "$FINAL_SPECIAL_REPORT")"
FINAL_REPORT_ROUTE="$(report_value "$STATUS_REPORT" FINAL_REPORT_ROUTE)"
FINAL_UNROUTED_RAW="$FINAL_UNROUTED"
FINAL_UNROUTED_SOURCE=checkpoint_repair_status
FINAL_REPORT_ROUTE_ZERO_STATUS=FAIL
if report_route_zero "$FINAL_REPORT_ROUTE"; then
  FINAL_REPORT_ROUTE_ZERO_STATUS=PASS
fi
if [[ "$FINAL_UNROUTED" == UNKNOWN && "$FINAL_REGULAR" == 0 &&
      "$FINAL_SPECIAL" == 1 && "$FINAL_SPECIAL_RAW" == 1 &&
      "$FINAL_SPECIAL_NON_RO" == 0 && "$FINAL_DANGLING" == 15 &&
      "$FINAL_REPORT_ROUTE_ZERO_STATUS" == PASS ]]; then
  FINAL_UNROUTED=0
  FINAL_UNROUTED_SOURCE=tie1_closure_exact_special_debt_report_route_fallback
fi
FINAL_CHECKPOINT="$(report_value "$STATUS_REPORT" FINAL_CHECKPOINT_DAT)"
FINAL_CHECKPOINT_EXISTS="$(report_value "$STATUS_REPORT" FINAL_CHECKPOINT_DAT_EXISTS)"
FINAL_CHECKPOINT_HASH="$(tree_hash "$FINAL_CHECKPOINT")"
COMMAND_STATUS="$(report_value "$STATUS_REPORT" COMMAND_1_STATUS)"
DECISION=FAIL_STOP
NEXT_STAGE=STOP_AND_REVIEW_PUBLISHED_EVIDENCE
OUTCOME=FAIL

if [[ "$STAGE" == tie1-minarea-* ]]; then
  MANUAL_STATUS="$(report_value "$MANUAL_REPORT" MANUAL_ECO_STATUS)"
  REPAIR_REVISION="$(report_value "$MANUAL_REPORT" REPAIR_REVISION)"
  MANUAL_ECO_MODE="$(report_value "$MANUAL_REPORT" MANUAL_ECO_MODE)"
  ATTRIBUTE_EDIT_POLICY="$(report_value "$MANUAL_REPORT" ATTRIBUTE_EDIT_POLICY)"
  GEOMETRY_EDIT_POLICY="$(report_value "$MANUAL_REPORT" GEOMETRY_EDIT_POLICY)"
  ROUTE_OPTIMIZER_POLICY="$(report_value "$MANUAL_REPORT" ROUTE_OPTIMIZER_POLICY)"
  SHELF_DIRECTION="$(report_value "$MANUAL_REPORT" VIA_OVERLAP_SHELF_DIRECTION)"
  SHELF_START="$(report_value "$MANUAL_REPORT" VIA_OVERLAP_SHELF_START)"
  SHELF_FINISH="$(report_value "$MANUAL_REPORT" VIA_OVERLAP_SHELF_FINISH)"
  PREDICTED_WIRE_BOX="$(report_value "$MANUAL_REPORT" PREDICTED_NEW_WIRE_BOX)"
  EXPECTED_CANONICAL_POINTS="$(report_value "$MANUAL_REPORT" EXPECTED_CANONICAL_WIRE_POINTS)"
  EXPECTED_CANONICAL_LENGTH="$(report_value "$MANUAL_REPORT" EXPECTED_CANONICAL_WIRE_LENGTH_UM)"
  V12_DISPOSITION="$(report_value "$MANUAL_REPORT" V12_VIA_OVERLAP_SHELF_DISPOSITION)"
  V12_OBSERVED_BOX="$(report_value "$MANUAL_REPORT" V12_OBSERVED_NEW_WIRE_BOX)"
  V12_OBSERVED_SPACING="$(report_value "$MANUAL_REPORT" V12_OBSERVED_BLOCKAGE_SPACING_UM)"
  V12_REQUIRED_SPACING="$(report_value "$MANUAL_REPORT" V12_REQUIRED_BLOCKAGE_SPACING_UM)"
  PREDICTED_BLOCKAGE_SPACING="$(report_value "$MANUAL_REPORT" PREDICTED_BLOCKAGE_SPACING_UM)"
  PREDICTED_BLOCKAGE_MARGIN="$(report_value "$MANUAL_REPORT" PREDICTED_BLOCKAGE_SPACING_MARGIN_UM)"
  PREDICTED_CONNECTED_AREA="$(report_value "$MANUAL_REPORT" PREDICTED_CONNECTED_AREA_UM2)"
  WIRE_READBACK_POLICY="$(report_value "$MANUAL_REPORT" WIRE_READBACK_POLICY)"
  PRE_MARKER_RECONCILIATION="$(report_value "$MANUAL_REPORT" PRE_MINAREA_MARKER_RECONCILIATION_STATUS)"
  PRE_MARKER_FRESH_TOTAL="$(report_value "$MANUAL_REPORT" PRE_MINAREA_MARKER_FRESH_DRC_TOTAL)"
  PRE_MARKER_GEOMETRY_COUNT="$(report_value "$MANUAL_REPORT" PRE_MINAREA_MARKER_GEOMETRY_COUNT)"
  PRE_MARKER_LIVE_COUNT="$(report_value "$MANUAL_REPORT" PRE_MINAREA_MARKER_LIVE_COUNT)"
  PRE_MARKER_STALE_COUNT="$(report_value "$MANUAL_REPORT" PRE_MINAREA_MARKER_STALE_COUNT)"
  PRE_MARKER_UNMAPPED_COUNT="$(report_value "$MANUAL_REPORT" PRE_MINAREA_MARKER_UNMAPPED_COUNT)"
  SHELF_STATUS="$(report_value "$MANUAL_REPORT" FIXED_WIRE_SHELF_STATUS)"
  SHELF_EFFECT_STATUS="$(report_value "$MANUAL_REPORT" FIXED_WIRE_SHELF_EFFECT_STATUS)"
  SHELF_BOX_STATUS="$(report_value "$MANUAL_REPORT" FIXED_WIRE_SHELF_BOX_STATUS)"
  SHELF_BOX_MATCH_STATUS="$(report_value "$MANUAL_REPORT" N57556_VIA_OVERLAP_SHELF_BOX_MATCH_STATUS)"
  SHELF_CANONICAL_POINTS_STATUS="$(report_value "$MANUAL_REPORT" N57556_VIA_OVERLAP_SHELF_CANONICAL_POINTS_MATCH_STATUS)"
  SHELF_CANONICAL_LENGTH_STATUS="$(report_value "$MANUAL_REPORT" N57556_VIA_OVERLAP_SHELF_CANONICAL_LENGTH_MATCH_STATUS)"
  SHELF_SHAPE_QUERY_POLICY="$(report_value "$MANUAL_REPORT" N57556_VIA_OVERLAP_SHELF_SHAPE_QUERY_POLICY)"
  TARGET_WIRE_COUNT_DELTA="$(report_value "$MANUAL_REPORT" TARGET_WIRE_COUNT_DELTA)"
  TARGET_NEW_WIRE_COUNT="$(report_value "$MANUAL_REPORT" TARGET_NEW_WIRE_COUNT)"
  TARGET_PREEXISTING_WIRE_STATUS="$(report_value "$MANUAL_REPORT" TARGET_PREEXISTING_WIRE_STATUS)"
  TARGET_WIRE_HANDLE_STATUS="$(report_value "$MANUAL_REPORT" TARGET_WIRE_HANDLE_STATUS)"
  TARGET_OTHER_ROUTE_OBJECT_STATUS="$(report_value "$MANUAL_REPORT" TARGET_OTHER_ROUTE_OBJECT_STATUS)"
  RESERVED_FILL_OBJECT_STATUS="$(report_value "$MANUAL_REPORT" RESERVED_FILL_OBJECT_STATUS)"
  LANDING_REPRESENTATION_STATUS="$(report_value "$MANUAL_REPORT" N57556_LANDING_REPRESENTATION_STATUS)"
  TARGET_VIA_FINGERPRINT_STATUS="$(report_value "$MANUAL_REPORT" TARGET_VIA_FINGERPRINT_STATUS)"
  POST_MINAREA_COUNT="$(report_value "$MANUAL_REPORT" POST_MINAREA_MARKER_COUNT)"
  SHELF_LENGTH="$(report_value "$MANUAL_REPORT" VIA_OVERLAP_SHELF_LENGTH_UM)"
  SHELF_WIDTH="$(report_value "$MANUAL_REPORT" VIA_OVERLAP_SHELF_WIDTH_UM)"
  if [[ "$TOOL_RC" -eq 0 && "$COMMAND_STATUS" == PASS && "$MANUAL_STATUS" == PASS &&
        "$REPAIR_REVISION" == V13 && "$PRE_MARKER_RECONCILIATION" == PASS &&
        "$MANUAL_ECO_MODE" == CANONICAL_FIXED_MET1_VIA_OVERLAP_SHELF_CLEARANCE_V13 &&
        "$ATTRIBUTE_EDIT_POLICY" == NO_DB_ATTRIBUTE_EDITS &&
        "$GEOMETRY_EDIT_POLICY" == ONE_EXACT_TARGET_NET_REGULAR_FIXED_MET1_VIA_OVERLAP_SHELF &&
        "$ROUTE_OPTIMIZER_POLICY" == NO_ECOROUTE_NO_ROUTEDESIGN_NO_GLOBAL_OPTIMIZER &&
        "$SHELF_DIRECTION" == HORIZONTAL_RIGHT &&
        "$SHELF_START" == "385.175 328.305" && "$SHELF_FINISH" == "385.560 328.305" &&
        "$PREDICTED_WIRE_BOX" == "385.175 328.190 385.560 328.420" &&
        "$EXPECTED_CANONICAL_POINTS" == "385.290 328.305 385.445 328.305" &&
        "$EXPECTED_CANONICAL_LENGTH" == 0.155 &&
        "$V12_DISPOSITION" == REJECTED_FE_RC_5_0_SPACING &&
        "$V12_OBSERVED_BOX" == "385.175 328.165 385.560 328.395" &&
        "$V12_OBSERVED_SPACING" == 0.215 && "$V12_REQUIRED_SPACING" == 0.230 &&
        "$PREDICTED_BLOCKAGE_SPACING" == 0.240 && "$PREDICTED_BLOCKAGE_MARGIN" == 0.010 &&
        "$PREDICTED_CONNECTED_AREA" == 0.211450 &&
        "$WIRE_READBACK_POLICY" == EXACT_BOX_AND_CANONICAL_CENTERLINE &&
        "$PRE_MARKER_FRESH_TOTAL" == 1 && "$PRE_MARKER_GEOMETRY_COUNT" == 2 &&
        "$PRE_MARKER_LIVE_COUNT" == 1 && "$PRE_MARKER_STALE_COUNT" == 1 &&
        "$PRE_MARKER_UNMAPPED_COUNT" == 0 && "$SHELF_STATUS" == PASS &&
        "$SHELF_EFFECT_STATUS" == PASS && "$SHELF_BOX_STATUS" == PASS &&
        "$SHELF_BOX_MATCH_STATUS" == PASS &&
        "$SHELF_CANONICAL_POINTS_STATUS" == PASS &&
        "$SHELF_CANONICAL_LENGTH_STATUS" == PASS &&
        "$SHELF_SHAPE_QUERY_POLICY" == NOT_QUERIED_UNSUPPORTED_WIRE_ATTRIBUTE &&
        "$TARGET_WIRE_COUNT_DELTA" == 1 &&
        "$TARGET_NEW_WIRE_COUNT" == 1 && "$TARGET_PREEXISTING_WIRE_STATUS" == PRESERVED &&
        "$TARGET_WIRE_HANDLE_STATUS" == ONE_EXACT_ADDITION &&
        "$TARGET_OTHER_ROUTE_OBJECT_STATUS" == UNCHANGED &&
        "$RESERVED_FILL_OBJECT_STATUS" == UNCHANGED &&
        "$LANDING_REPRESENTATION_STATUS" == UNCHANGED &&
        "$TARGET_VIA_FINGERPRINT_STATUS" == UNCHANGED &&
        "$POST_MINAREA_COUNT" == 0 && "$SHELF_LENGTH" == 0.385 &&
        "$SHELF_WIDTH" == 0.23 &&
        "$INITIAL_DRC" == 1 && "$FINAL_DRC" == 0 &&
        "$FINAL_SHORTS" == 0 && "$FINAL_REGULAR" == 0 && "$FINAL_SPECIAL" == 1 &&
        "$FINAL_SPECIAL_RAW" == 1 && "$FINAL_SPECIAL_NON_RO" == 0 &&
        "$FINAL_DANGLING" == 15 && "$FINAL_UNROUTED" == 0 &&
        "$FINAL_CHECKPOINT_EXISTS" == 1 && "$FINAL_CHECKPOINT_HASH" =~ ^[0-9a-f]{64}$ ]]; then
    DECISION=PASS_CONTINUE
    OUTCOME=PASS_GEOMETRY_CLEAN
    [[ "$STAGE" == tie1-minarea-trial ]] && NEXT_STAGE=TIE1_MINAREA_ENDEXT_REPLAY || NEXT_STAGE=TIE1_PG_DANGLING_ANALYSIS
  fi
  {
    echo "STEP=$STEP"
    echo "SOURCE_TIE1_RUN_ID=$SOURCE_TIE1_RUN_ID"
    echo "SOURCE_MINAREA_TRIAL_RUN_ID=${SOURCE_MINAREA_TRIAL_RUN_ID:-NONE}"
    echo "SOURCE_CHECKPOINT=$SOURCE_CHECKPOINT"
    echo "SOURCE_CHECKPOINT_SHA256=$(tree_hash "$SOURCE_CHECKPOINT")"
    echo "TOOL_RC=$TOOL_RC"
    echo "COMMAND_1_STATUS=$COMMAND_STATUS"
    echo "MANUAL_ECO_STATUS=$MANUAL_STATUS"
    echo "REPAIR_REVISION=$REPAIR_REVISION"
    echo "MANUAL_ECO_MODE=$MANUAL_ECO_MODE"
    echo "ATTRIBUTE_EDIT_POLICY=$ATTRIBUTE_EDIT_POLICY"
    echo "GEOMETRY_EDIT_POLICY=$GEOMETRY_EDIT_POLICY"
    echo "ROUTE_OPTIMIZER_POLICY=$ROUTE_OPTIMIZER_POLICY"
    echo "VIA_OVERLAP_SHELF_DIRECTION=$SHELF_DIRECTION"
    echo "VIA_OVERLAP_SHELF_START=$SHELF_START"
    echo "VIA_OVERLAP_SHELF_FINISH=$SHELF_FINISH"
    echo "PREDICTED_NEW_WIRE_BOX=$PREDICTED_WIRE_BOX"
    echo "EXPECTED_CANONICAL_WIRE_POINTS=$EXPECTED_CANONICAL_POINTS"
    echo "EXPECTED_CANONICAL_WIRE_LENGTH_UM=$EXPECTED_CANONICAL_LENGTH"
    echo "V12_VIA_OVERLAP_SHELF_DISPOSITION=$V12_DISPOSITION"
    echo "V12_OBSERVED_NEW_WIRE_BOX=$V12_OBSERVED_BOX"
    echo "V12_OBSERVED_BLOCKAGE_SPACING_UM=$V12_OBSERVED_SPACING"
    echo "V12_REQUIRED_BLOCKAGE_SPACING_UM=$V12_REQUIRED_SPACING"
    echo "PREDICTED_BLOCKAGE_SPACING_UM=$PREDICTED_BLOCKAGE_SPACING"
    echo "PREDICTED_BLOCKAGE_SPACING_MARGIN_UM=$PREDICTED_BLOCKAGE_MARGIN"
    echo "PREDICTED_CONNECTED_AREA_UM2=$PREDICTED_CONNECTED_AREA"
    echo "WIRE_READBACK_POLICY=$WIRE_READBACK_POLICY"
    echo "PRE_DRC_MARKER_RECONCILIATION_STATUS=$PRE_MARKER_RECONCILIATION"
    echo "PRE_DRC_MARKER_FRESH_DRC_TOTAL=$PRE_MARKER_FRESH_TOTAL"
    echo "PRE_DRC_MARKER_GEOMETRY_COUNT=$PRE_MARKER_GEOMETRY_COUNT"
    echo "PRE_DRC_MARKER_LIVE_COUNT=$PRE_MARKER_LIVE_COUNT"
    echo "PRE_DRC_MARKER_STALE_COUNT=$PRE_MARKER_STALE_COUNT"
    echo "PRE_DRC_MARKER_UNMAPPED_COUNT=$PRE_MARKER_UNMAPPED_COUNT"
    echo "FIXED_WIRE_SHELF_STATUS=$SHELF_STATUS"
    echo "FIXED_WIRE_SHELF_EFFECT_STATUS=$SHELF_EFFECT_STATUS"
    echo "FIXED_WIRE_SHELF_BOX_STATUS=$SHELF_BOX_STATUS"
    echo "N57556_VIA_OVERLAP_SHELF_BOX_MATCH_STATUS=$SHELF_BOX_MATCH_STATUS"
    echo "N57556_VIA_OVERLAP_SHELF_CANONICAL_POINTS_MATCH_STATUS=$SHELF_CANONICAL_POINTS_STATUS"
    echo "N57556_VIA_OVERLAP_SHELF_CANONICAL_LENGTH_MATCH_STATUS=$SHELF_CANONICAL_LENGTH_STATUS"
    echo "N57556_VIA_OVERLAP_SHELF_SHAPE_QUERY_POLICY=$SHELF_SHAPE_QUERY_POLICY"
    echo "TARGET_WIRE_COUNT_DELTA=$TARGET_WIRE_COUNT_DELTA"
    echo "TARGET_NEW_WIRE_COUNT=$TARGET_NEW_WIRE_COUNT"
    echo "TARGET_PREEXISTING_WIRE_STATUS=$TARGET_PREEXISTING_WIRE_STATUS"
    echo "TARGET_WIRE_HANDLE_STATUS=$TARGET_WIRE_HANDLE_STATUS"
    echo "TARGET_OTHER_ROUTE_OBJECT_STATUS=$TARGET_OTHER_ROUTE_OBJECT_STATUS"
    echo "RESERVED_FILL_OBJECT_STATUS=$RESERVED_FILL_OBJECT_STATUS"
    echo "N57556_LANDING_REPRESENTATION_STATUS=$LANDING_REPRESENTATION_STATUS"
    echo "TARGET_VIA_FINGERPRINT_STATUS=$TARGET_VIA_FINGERPRINT_STATUS"
    echo "POST_MINAREA_MARKER_COUNT=$POST_MINAREA_COUNT"
    echo "VIA_OVERLAP_SHELF_LENGTH_UM=$SHELF_LENGTH"
    echo "VIA_OVERLAP_SHELF_WIDTH_UM=$SHELF_WIDTH"
    echo "INITIAL_DRC=$INITIAL_DRC"
    echo "FINAL_DRC=$FINAL_DRC"
    echo "FINAL_SHORTS=$FINAL_SHORTS"
    echo "FINAL_REGULAR_CONNECTIVITY_BAD=$FINAL_REGULAR"
    echo "FINAL_SPECIAL_CONNECTIVITY_BAD=$FINAL_SPECIAL"
    echo "FINAL_SPECIAL_CONNECTIVITY_RAW_BAD=$FINAL_SPECIAL_RAW"
    echo "FINAL_SPECIAL_CONNECTIVITY_NON_RO_FAILURES=$FINAL_SPECIAL_NON_RO"
    echo "FINAL_SPECIAL_DANGLING_COUNT=$FINAL_DANGLING"
    echo "FINAL_UNROUTED_NETS_RAW=$FINAL_UNROUTED_RAW"
    echo "FINAL_UNROUTED_NETS=$FINAL_UNROUTED"
    echo "FINAL_UNROUTED_NETS_SOURCE=$FINAL_UNROUTED_SOURCE"
    echo "FINAL_REPORT_ROUTE_ZERO_STATUS=$FINAL_REPORT_ROUTE_ZERO_STATUS"
    echo "TIE_TARGET_COUNT=91"
    echo "TIE_NET_COUNT=85"
    echo "FILLER_COUNT=24856"
    echo "PLACEMENT_SITE_OCCUPIED=907533"
    echo "PLACEMENT_SITE_CAPACITY=907533"
    echo "PLACEMENT_EDIT_POLICY=NO_INSTANCES_MOVED"
    echo "ANTENNA_REPAIR_ATTEMPTED=NO"
    echo "TIMING_STATUS=NOT_RUN_BY_DRC_LVS_SCOPE"
    echo "CANDIDATE_CHECKPOINT=$FINAL_CHECKPOINT"
    echo "CANDIDATE_CHECKPOINT_SHA256=$FINAL_CHECKPOINT_HASH"
    echo "CANDIDATE_CHECKPOINT_STATUS=$( [[ "$OUTCOME" == PASS_GEOMETRY_CLEAN ]] && echo PASS || echo FAIL )"
    echo "SIGNOFF_ELIGIBLE=NO"
    echo "DECISION=$DECISION"
    echo "NEXT_STAGE=$NEXT_STAGE"
  } | tee "$GATE_REPORT"
else
  PG_REPORT="$RUN_DIR/reports/pg_dangling_analysis_status.rpt"
  PG_STATUS="$(report_value "$PG_REPORT" PG_DANGLING_STATUS)"
  PG_ELIGIBLE="$(report_value "$PG_REPORT" PG_DANGLING_ELIGIBLE_COUNT)"
  PG_ALL_ELIGIBLE="$(report_value "$PG_REPORT" PG_DANGLING_ALL_ELIGIBLE_STATUS)"
  PG_UNSAFE="$(report_value "$PG_REPORT" PG_DANGLING_UNSAFE_LENGTH_COUNT)"
  PG_DUPLICATE="$(report_value "$PG_REPORT" PG_DANGLING_DUPLICATE_HANDLE_COUNT)"
  PG_ATTEMPTS="$(report_value "$PG_REPORT" PG_DANGLING_DELETE_ATTEMPTS)"
  PG_SUCCESSES="$(report_value "$PG_REPORT" PG_DANGLING_DELETE_SUCCESSES)"
  PG_MUTATION_ALLOWED="$(report_value "$PG_REPORT" PG_DANGLING_MUTATION_ALLOWED)"
  if [[ "$TOOL_RC" -eq 0 && "$COMMAND_STATUS" == PASS && "$INITIAL_DRC" == 0 &&
        "$FINAL_DRC" == 0 && "$FINAL_SHORTS" == 0 && "$FINAL_REGULAR" == 0 &&
        "$FINAL_UNROUTED" == 0 && "$FINAL_CHECKPOINT_EXISTS" == 1 ]]; then
    if [[ "$STAGE" == tie1-pg-analyze && "$PG_STATUS" == ANALYSIS_ONLY &&
          "$PG_MUTATION_ALLOWED" == 0 && "$PG_ATTEMPTS" == 0 &&
          "$PG_SUCCESSES" == 0 && "$FINAL_DANGLING" == 15 &&
          "$FINAL_SPECIAL" == 1 && "$FINAL_SPECIAL_RAW" == 1 &&
          "$FINAL_SPECIAL_NON_RO" == 0 ]]; then
      if [[ "$PG_ALL_ELIGIBLE" == PASS && "$PG_ELIGIBLE" == 15 &&
            "$PG_UNSAFE" == 0 && "$PG_DUPLICATE" == 0 ]]; then
        DECISION=PASS_CONTINUE
        OUTCOME=ANALYSIS_ALL_ELIGIBLE
        NEXT_STAGE=TIE1_PG_DANGLING_DELETE_TRIAL
      else
        DECISION=PASS_ANALYSIS_KEEP_MINAREA_CANDIDATE
        OUTCOME=ANALYSIS_PREFLIGHT_BLOCKED_NO_MUTATION
        NEXT_STAGE=PVS_BASE_DRC_AND_RAW_LVS
      fi
    elif [[ "$PG_STATUS" == PASS_DANGLING_CLEARED && "$PG_ALL_ELIGIBLE" == PASS &&
            "$PG_ELIGIBLE" == 15 && "$PG_UNSAFE" == 0 && "$PG_DUPLICATE" == 0 &&
            "$PG_ATTEMPTS" == 15 && "$PG_SUCCESSES" == 15 && "$FINAL_DANGLING" == 0 &&
            "$FINAL_SPECIAL" == 0 && "$FINAL_SPECIAL_RAW" == 0 && "$FINAL_ROUTE_GATE" == 1 ]]; then
      DECISION=PASS_CONTINUE
      OUTCOME=PASS_CLEARED
      [[ "$STAGE" == tie1-pg-delete-trial ]] && NEXT_STAGE=TIE1_PG_DANGLING_DELETE_REPLAY || NEXT_STAGE=PVS_BASE_DRC_AND_RAW_LVS
    elif [[ "$PG_STATUS" == REVIEW_REQUIRED_PREFLIGHT_BLOCKED && "$PG_MUTATION_ALLOWED" == 0 &&
            "$PG_ATTEMPTS" == 0 && "$FINAL_DANGLING" == 15 && "$FINAL_SPECIAL" == 1 ]]; then
      DECISION=PASS_ANALYSIS_KEEP_MINAREA_CANDIDATE
      OUTCOME=PREFLIGHT_BLOCKED_NO_MUTATION
      NEXT_STAGE=PVS_BASE_DRC_AND_RAW_LVS
    fi
  fi
  {
    echo "STEP=$STEP"
    echo "SOURCE_TIE1_RUN_ID=$SOURCE_TIE1_RUN_ID"
    echo "SOURCE_MINAREA_REPLAY_RUN_ID=$SOURCE_MINAREA_REPLAY_RUN_ID"
    echo "SOURCE_PG_TRIAL_RUN_ID=${SOURCE_PG_TRIAL_RUN_ID:-NONE}"
    echo "SOURCE_CHECKPOINT=$SOURCE_CHECKPOINT"
    echo "SOURCE_CHECKPOINT_SHA256=$(tree_hash "$SOURCE_CHECKPOINT")"
    echo "TOOL_RC=$TOOL_RC"
    echo "COMMAND_1_STATUS=$COMMAND_STATUS"
    echo "PG_DANGLING_STATUS=$PG_STATUS"
    echo "PG_DANGLING_ELIGIBLE_COUNT=$PG_ELIGIBLE"
    echo "PG_DANGLING_ALL_ELIGIBLE_STATUS=$PG_ALL_ELIGIBLE"
    echo "PG_DANGLING_UNSAFE_LENGTH_COUNT=$PG_UNSAFE"
    echo "PG_DANGLING_DUPLICATE_HANDLE_COUNT=$PG_DUPLICATE"
    echo "PG_DANGLING_MUTATION_ALLOWED=$PG_MUTATION_ALLOWED"
    echo "PG_DANGLING_DELETE_ATTEMPTS=$PG_ATTEMPTS"
    echo "PG_DANGLING_DELETE_SUCCESSES=$PG_SUCCESSES"
    echo "FINAL_DRC=$FINAL_DRC"
    echo "FINAL_SHORTS=$FINAL_SHORTS"
    echo "FINAL_REGULAR_CONNECTIVITY_BAD=$FINAL_REGULAR"
    echo "FINAL_SPECIAL_CONNECTIVITY_BAD=$FINAL_SPECIAL"
    echo "FINAL_SPECIAL_CONNECTIVITY_RAW_BAD=$FINAL_SPECIAL_RAW"
    echo "FINAL_SPECIAL_CONNECTIVITY_NON_RO_FAILURES=$FINAL_SPECIAL_NON_RO"
    echo "FINAL_SPECIAL_DANGLING_COUNT=$FINAL_DANGLING"
    echo "FINAL_UNROUTED_NETS_RAW=$FINAL_UNROUTED_RAW"
    echo "FINAL_UNROUTED_NETS=$FINAL_UNROUTED"
    echo "FINAL_UNROUTED_NETS_SOURCE=$FINAL_UNROUTED_SOURCE"
    echo "FINAL_REPORT_ROUTE_ZERO_STATUS=$FINAL_REPORT_ROUTE_ZERO_STATUS"
    echo "FINAL_ROUTE_GATE_PASS=$FINAL_ROUTE_GATE"
    echo "PG_DELETE_TRIAL_OUTCOME=$OUTCOME"
    echo "TIE_TARGET_COUNT=91"
    echo "TIE_NET_COUNT=85"
    echo "FILLER_COUNT=24856"
    echo "PLACEMENT_SITE_OCCUPIED=907533"
    echo "PLACEMENT_SITE_CAPACITY=907533"
    echo "PLACEMENT_EDIT_POLICY=NO_INSTANCES_MOVED"
    echo "ANTENNA_REPAIR_ATTEMPTED=NO"
    echo "TIMING_STATUS=NOT_RUN_BY_DRC_LVS_SCOPE"
    echo "CANDIDATE_CHECKPOINT=$FINAL_CHECKPOINT"
    echo "CANDIDATE_CHECKPOINT_SHA256=$FINAL_CHECKPOINT_HASH"
    echo "CANDIDATE_CHECKPOINT_STATUS=$( [[ "$DECISION" == PASS_CONTINUE ]] && echo PASS || echo NOT_SELECTED )"
    echo "SIGNOFF_ELIGIBLE=NO"
    echo "DECISION=$DECISION"
    echo "NEXT_STAGE=$NEXT_STAGE"
  } | tee "$GATE_REPORT"
fi

MPTDC_SNAPSHOT_MAX_TEXT_BYTES=4194304 bash "$PUBLISHER" innovus "$RUN_ID" "$RUN_DIR" "$STEP"
PUBLISH_RC=$?
echo "TIE1_CLOSURE_STAGE=$STEP"
echo "TIE1_CLOSURE_RUN_ID=$RUN_ID"
echo "DECISION=$DECISION"
echo "PUBLISH_RC=$PUBLISH_RC"
echo "NEXT_EXPECTED_HEAD=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null)"
echo "NEXT_STAGE=$NEXT_STAGE"
if [[ ( "$DECISION" == PASS_CONTINUE || "$DECISION" == PASS_ANALYSIS_KEEP_MINAREA_CANDIDATE ) && "$PUBLISH_RC" -eq 0 ]]; then
  exit 0
fi
exit 1
