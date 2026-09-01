#!/usr/bin/env bash
# Build one attributable V13 checkpoint candidate with two exact VSS via stacks.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
REPO_ROOT="${MPTDC_RO6_VSS_VIA_REPO_ROOT:-$DEFAULT_REPO_ROOT}"
INNOVUS_WORK="${MPTDC_INNOVUS_WORK:-/sim/ksabra/SPADMIC_work/innovus}"
LAUNCHER="${MPTDC_RO6_VSS_VIA_LAUNCHER:-$SCRIPT_DIR/server_repair_mptdc_route_checkpoint.sh}"
PUBLISHER="${MPTDC_RO6_VSS_VIA_PUBLISHER:-$REPO_ROOT/MPTDC/ci/publish_mptdc_server_snapshot.sh}"
COMMANDS_FILE="$REPO_ROOT/MPTDC/pnr/scripts/commands/mptdc_ro6_vss_via_trial.tcl"
HELPER="$REPO_ROOT/MPTDC/pnr/scripts/innovus_mptdc_ro6_vss_via_checkpoint_tools.tcl"
EXPECTED_SOURCE_PNR_RUN_ID=20260831_175532_mptdc_tie1_minarea_clearance_v13_replay
SOURCE_GATE_NAME=operator_gate_tie1_minarea_endext_replay.rpt
AUTHORIZATION=EXACT_V13_TWO_RO6_VSS_MET1_METTP_VIA_STACKS_V1

BOUNDARY_PVS_RUN_ID=""
RUN_ID=""
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD:-}"

usage() {
  cat <<'USAGE'
Usage:
  server_run_mptdc_ro6_vss_via_trial.sh --boundary-pvs-run-id <id> [options]

Options:
  --boundary-pvs-run-id <id>  Published boundary LVS with exactly two VSS opens.
  --run-id <id>               Fresh Innovus trial run id.
  --expected-head <sha>       Require repository HEAD and origin/SPADMIC_test.
  --innovus-work <path>       Innovus/PVS result root.
  -h, --help                  Show this help.

The source checkpoint is read from the immutable boundary PVS hash manifest.
The stage inserts only the two authorized VSS MET1-to-METTP via stacks. It does
not run PVS and cannot claim LVS or final physical signoff.
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

tracked_file() {
  local path="$1" rel="${1#"$REPO_ROOT"/}"
  git -C "$REPO_ROOT" ls-files --error-unmatch "$rel" >/dev/null 2>&1 && [[ -s "$path" ]]
}

publish_stage() {
  MPTDC_SNAPSHOT_MAX_TEXT_BYTES=8388608 \
    bash "$PUBLISHER" innovus "$RUN_ID" "$RUN_DIR" RO6_VSS_VIA_TRIAL
  local rc=$?
  EXPECTED_HEAD_VALUE="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null)"
  return "$rc"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --boundary-pvs-run-id) BOUNDARY_PVS_RUN_ID="${2:?missing --boundary-pvs-run-id value}"; shift 2 ;;
    --run-id) RUN_ID="${2:?missing --run-id value}"; shift 2 ;;
    --expected-head) EXPECTED_HEAD_VALUE="${2:?missing --expected-head value}"; shift 2 ;;
    --innovus-work) INNOVUS_WORK="${2:?missing --innovus-work value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$BOUNDARY_PVS_RUN_ID" ]] || { echo "ERROR: --boundary-pvs-run-id is required" >&2; exit 2; }
[[ "$BOUNDARY_PVS_RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "ERROR: unsafe boundary run id" >&2; exit 2; }
if [[ -z "$RUN_ID" ]]; then
  RUN_ID="$(date +%Y%m%d_%H%M%S)_mptdc_v13_ro6_vss_via_trial"
fi
[[ "$RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "ERROR: unsafe trial run id" >&2; exit 2; }

BOUNDARY_DIR="$INNOVUS_WORK/$BOUNDARY_PVS_RUN_ID"
BOUNDARY_GATE="$BOUNDARY_DIR/reports/operator_gate_pvs_ro6_boundary_lvs.rpt"
BOUNDARY_MANIFEST="$BOUNDARY_DIR/manifests/pvs_input_hashes.rpt"
BOUNDARY_SNAPSHOT="$REPO_ROOT/MPTDC/docs/server_snapshots/pvs/$BOUNDARY_PVS_RUN_ID"
TRACKED_BOUNDARY_GATE="$BOUNDARY_SNAPSHOT/reports/operator_gate_pvs_ro6_boundary_lvs.rpt"
TRACKED_BOUNDARY_MANIFEST="$BOUNDARY_SNAPSHOT/manifests/pvs_input_hashes.rpt"
RUN_DIR="$INNOVUS_WORK/$RUN_ID"

cd "$REPO_ROOT" || exit 3
ACTUAL_HEAD="$(git rev-parse HEAD 2>/dev/null)"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
ORIGIN_HEAD="$(git rev-parse refs/remotes/origin/SPADMIC_test 2>/dev/null || true)"
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD_VALUE:-${ORIGIN_HEAD:-$ACTUAL_HEAD}}"
TRACKED_STATUS="$(git status --short --untracked-files=no 2>/dev/null)"

SOURCE_CHECKPOINT="$(report_value "$BOUNDARY_MANIFEST" SOURCE_CHECKPOINT)"
SOURCE_PNR_DIR="$(dirname "$(dirname "$SOURCE_CHECKPOINT")")"
SOURCE_PNR_RUN_ID="$(basename "$SOURCE_PNR_DIR")"
SOURCE_GATE="$SOURCE_PNR_DIR/reports/$SOURCE_GATE_NAME"
TRACKED_SOURCE_GATE="$REPO_ROOT/MPTDC/docs/server_snapshots/innovus/$SOURCE_PNR_RUN_ID/reports/$SOURCE_GATE_NAME"
SOURCE_CHECKPOINT_EXPECTED_SHA="$(report_value "$TRACKED_SOURCE_GATE" CANDIDATE_CHECKPOINT_SHA256)"
SOURCE_CHECKPOINT_ACTUAL_SHA="$(tree_hash "$SOURCE_CHECKPOINT")"

BOUNDARY_CLASS="$(report_value "$BOUNDARY_GATE" BOUNDARY_REMAINDER_CLASS)"
BOUNDARY_DECISION="$(report_value "$BOUNDARY_GATE" DECISION)"
BOUNDARY_CLASS_STATUS=FAIL
if [[ "$BOUNDARY_CLASS" == TOP_CONNECTIVITY_MISMATCH && "$BOUNDARY_DECISION" == FAIL_STOP ]]; then
  BOUNDARY_CLASS_STATUS=PASS_LEGACY_EXACT_COUNTS
elif [[ "$BOUNDARY_CLASS" == RO6_VSS_OPEN_ONLY && "$BOUNDARY_DECISION" == PASS_PG_REPAIR_REQUIRED ]]; then
  BOUNDARY_CLASS_STATUS=PASS_EXACT_CLASS
fi

echo "BOUNDARY_PVS_RUN_ID=$BOUNDARY_PVS_RUN_ID"
echo "SOURCE_PNR_RUN_ID=$SOURCE_PNR_RUN_ID"
echo "SOURCE_CHECKPOINT=$SOURCE_CHECKPOINT"
echo "RUN_ID=$RUN_ID"
echo "RUN_DIR=$RUN_DIR"
echo "BRANCH=$BRANCH"
echo "ACTUAL_HEAD=$ACTUAL_HEAD"
echo "ORIGIN_HEAD=${ORIGIN_HEAD:-MISSING}"
echo "EXPECTED_HEAD=$EXPECTED_HEAD_VALUE"
echo "BOUNDARY_REMAINDER_CLASS=$BOUNDARY_CLASS"
echo "BOUNDARY_CLASS_STATUS=$BOUNDARY_CLASS_STATUS"

PREFLIGHT=PASS
[[ "$BRANCH" == SPADMIC_test ]] || { echo "STOP: branch must be SPADMIC_test"; PREFLIGHT=FAIL; }
[[ "$ACTUAL_HEAD" == "$EXPECTED_HEAD_VALUE" ]] || { echo "STOP: HEAD mismatch"; PREFLIGHT=FAIL; }
[[ -n "$ORIGIN_HEAD" && "$ORIGIN_HEAD" == "$ACTUAL_HEAD" ]] || { echo "STOP: origin/SPADMIC_test mismatch"; PREFLIGHT=FAIL; }
[[ -z "$TRACKED_STATUS" ]] || { echo "$TRACKED_STATUS"; echo "STOP: tracked working tree is dirty"; PREFLIGHT=FAIL; }
[[ ! -e "$RUN_DIR" ]] || { echo "STOP: result directory already exists: $RUN_DIR"; PREFLIGHT=FAIL; }
[[ -x "$LAUNCHER" && -s "$PUBLISHER" && -s "$COMMANDS_FILE" && -s "$HELPER" ]] || {
  echo "STOP: launcher, publisher, command file, or helper missing"; PREFLIGHT=FAIL;
}
tracked_file "$COMMANDS_FILE" || { echo "STOP: command file is not tracked"; PREFLIGHT=FAIL; }
tracked_file "$HELPER" || { echo "STOP: via helper is not tracked"; PREFLIGHT=FAIL; }
tracked_file "$TRACKED_BOUNDARY_GATE" || { echo "STOP: tracked boundary gate missing"; PREFLIGHT=FAIL; }
tracked_file "$TRACKED_BOUNDARY_MANIFEST" || { echo "STOP: tracked boundary manifest missing"; PREFLIGHT=FAIL; }
tracked_file "$TRACKED_SOURCE_GATE" || { echo "STOP: tracked V13 source gate missing"; PREFLIGHT=FAIL; }
[[ -s "$BOUNDARY_GATE" && -s "$BOUNDARY_MANIFEST" && -s "$SOURCE_GATE" ]] || {
  echo "STOP: live boundary or source evidence missing"; PREFLIGHT=FAIL;
}
cmp -s "$BOUNDARY_GATE" "$TRACKED_BOUNDARY_GATE" || { echo "STOP: live boundary gate differs from snapshot"; PREFLIGHT=FAIL; }
cmp -s "$BOUNDARY_MANIFEST" "$TRACKED_BOUNDARY_MANIFEST" || { echo "STOP: live boundary manifest differs from snapshot"; PREFLIGHT=FAIL; }
cmp -s "$SOURCE_GATE" "$TRACKED_SOURCE_GATE" || { echo "STOP: live V13 source gate differs from snapshot"; PREFLIGHT=FAIL; }
[[ "$SOURCE_PNR_RUN_ID" == "$EXPECTED_SOURCE_PNR_RUN_ID" &&
   "$SOURCE_CHECKPOINT" == "$INNOVUS_WORK/$EXPECTED_SOURCE_PNR_RUN_ID/checkpoints/repaired_route.enc.dat" ]] || {
  echo "STOP: boundary manifest does not name the accepted V13 checkpoint"; PREFLIGHT=FAIL;
}
[[ -d "$SOURCE_CHECKPOINT" && "$SOURCE_CHECKPOINT_EXPECTED_SHA" =~ ^[0-9a-f]{64}$ &&
   "$SOURCE_CHECKPOINT_ACTUAL_SHA" == "$SOURCE_CHECKPOINT_EXPECTED_SHA" ]] || {
  echo "STOP: accepted V13 checkpoint hash mismatch"; PREFLIGHT=FAIL;
}
[[ "$(report_value "$TRACKED_SOURCE_GATE" STEP)" == TIE1_MINAREA_ENDEXT_REPLAY &&
   "$(report_value "$TRACKED_SOURCE_GATE" REPAIR_REVISION)" == V13 &&
   "$(report_value "$TRACKED_SOURCE_GATE" FINAL_DRC)" == 0 &&
   "$(report_value "$TRACKED_SOURCE_GATE" FINAL_SHORTS)" == 0 &&
   "$(report_value "$TRACKED_SOURCE_GATE" FINAL_REGULAR_CONNECTIVITY_BAD)" == 0 &&
   "$(report_value "$TRACKED_SOURCE_GATE" FINAL_SPECIAL_CONNECTIVITY_RAW_BAD)" == 1 &&
   "$(report_value "$TRACKED_SOURCE_GATE" FINAL_SPECIAL_DANGLING_COUNT)" == 15 &&
   "$(report_value "$TRACKED_SOURCE_GATE" CANDIDATE_CHECKPOINT_STATUS)" == PASS &&
   "$(report_value "$TRACKED_SOURCE_GATE" DECISION)" == PASS_CONTINUE ]] || {
  echo "STOP: V13 source gate contract failed"; PREFLIGHT=FAIL;
}
[[ "$BOUNDARY_CLASS_STATUS" == PASS_* &&
   "$(report_value "$BOUNDARY_GATE" STATUS)" == FAIL &&
   "$(report_value "$BOUNDARY_GATE" PVS_LVS_STATUS)" == MISMATCH &&
   "$(report_value "$BOUNDARY_GATE" PVS_RC)" == 0 &&
   "$(report_value "$BOUNDARY_GATE" LVS_BLACKBOX_RULE_STATUS)" == PASS &&
   "$(report_value "$BOUNDARY_GATE" LVS_BLACKBOX_APPLICATION_STATUS)" == PASS &&
   "$(report_value "$BOUNDARY_GATE" LVS_BLACKBOXED_CELL_COUNT)" == 1 &&
   "$(report_value "$BOUNDARY_GATE" LVS_BLACKBOX_CLS_PATH_STATUS)" == PASS &&
   "$(report_value "$BOUNDARY_GATE" TOP_INITIAL_PINS)" == 59:59 &&
   "$(report_value "$BOUNDARY_GATE" TOP_COMPARE_PINS)" == 59:59 &&
   "$(report_value "$BOUNDARY_GATE" TOP_CELL_STATUS)" == mismatch &&
   "$(report_value "$BOUNDARY_GATE" LVS_BUS_PIN_MAP_RULE_STATUS)" == NOT_USED_EXACT_SCALAR_SOURCE &&
   "$(report_value "$BOUNDARY_GATE" LVS_GLOBAL_SIGNAL_PORT_RULE_STATUS)" == PASS &&
   "$(report_value "$BOUNDARY_GATE" RO6_BLACKBOX_CELL_MATCH_STATUS)" == PASS &&
   "$(report_value "$BOUNDARY_GATE" RO6_BLACKBOX_INITIAL_PINS)" == 19:19 &&
   "$(report_value "$BOUNDARY_GATE" RO6_BLACKBOX_COMPARE_PINS)" == 19:19 &&
   "$(report_value "$BOUNDARY_GATE" RO6_BLACKBOX_CELL_STATUS)" == match &&
   "$(report_value "$BOUNDARY_GATE" RO6_ANGLE_BUS_MISSING_PIN_COUNT)" == 0 &&
   "$(report_value "$BOUNDARY_GATE" RO6_SQUARE_BUS_MISSING_PIN_COUNT)" == 0 &&
   "$(report_value "$BOUNDARY_GATE" TIE1_UNMATCHED_PIN_COUNT)" == 0 &&
   "$(report_value "$BOUNDARY_GATE" TIE1_MISMATCHED_NET_COUNT)" == 0 &&
   "$(report_value "$BOUNDARY_GATE" TIE1_MISMATCHED_INSTANCE_CASCADE_COUNT)" == 0 &&
   "$(report_value "$BOUNDARY_GATE" LAYOUT_OPEN_NET_COUNT)" == 2 &&
   "$(report_value "$BOUNDARY_GATE" SHORTS_OPENS_RECORD_COUNT)" == 1 &&
   "$(report_value "$BOUNDARY_GATE" MISMATCHED_NET_RECORD_COUNT)" == 0 &&
   "$(report_value "$BOUNDARY_GATE" MISMATCHED_INSTANCE_RECORD_COUNT)" == 0 &&
   "$(report_value "$BOUNDARY_GATE" VDD_OPEN_SECTION_COUNT)" == 0 &&
   "$(report_value "$BOUNDARY_GATE" VSS_OPEN_SECTION_COUNT)" == 1 ]] || {
  echo "STOP: boundary evidence is not the exact two-VSS-open signature"; PREFLIGHT=FAIL;
}

echo "RO6_VSS_VIA_TRIAL_PREFLIGHT=$PREFLIGHT"
if [[ "$PREFLIGHT" != PASS ]]; then
  echo "DECISION=FAIL_STOP"
  echo "NEXT_STAGE=STOP_AND_REVIEW_PUBLISHED_EVIDENCE"
  exit 4
fi

if [[ -f /eda/cadence/eda_2023-2024 ]]; then
  # shellcheck disable=SC1091
  source /eda/cadence/eda_2023-2024 2>/dev/null || true
fi

export MPTDC_RO6_VSS_VIA_AUTHORIZATION="$AUTHORIZATION"
set +e
bash "$LAUNCHER" \
  --checkpoint "$SOURCE_CHECKPOINT" \
  --run-id "$RUN_ID" \
  --commands-file "$COMMANDS_FILE" \
  --expected-head "$EXPECTED_HEAD_VALUE" \
  --innovus-work "$INNOVUS_WORK" \
  2>&1 | tee "/tmp/${RUN_ID}.ro6_vss_via_trial.log"
TOOL_RC=${PIPESTATUS[0]}
set +e

HELPER_REPORT="$RUN_DIR/reports/ro6_vss_via_repair_status.rpt"
CHECKPOINT_REPORT="$RUN_DIR/reports/checkpoint_repair_status.rpt"
FINAL_CHECKPOINT="$RUN_DIR/checkpoints/repaired_route.enc.dat"
GATE_REPORT="$RUN_DIR/reports/operator_gate_ro6_vss_via_trial.rpt"

AUTH_STATUS="$(report_value "$HELPER_REPORT" AUTHORIZATION_STATUS)"
PREFLIGHT_STATUS="$(report_value "$HELPER_REPORT" PREFLIGHT_STATUS)"
GEOMETRY_STATUS="$(report_value "$HELPER_REPORT" GEOMETRY_CONTRACT_STATUS)"
RESOLVED_SITES="$(report_value "$HELPER_REPORT" RESOLVED_SITE_COUNT)"
VIA_ATTEMPTS="$(report_value "$HELPER_REPORT" VIA_ATTEMPTS)"
VIA_SUCCESSES="$(report_value "$HELPER_REPORT" VIA_SUCCESSES)"
VDD_SWIRE_STATUS="$(report_value "$HELPER_REPORT" VDD_SWIRE_FINGERPRINT_STATUS)"
VSS_SWIRE_STATUS="$(report_value "$HELPER_REPORT" VSS_SWIRE_FINGERPRINT_STATUS)"
VDD_VIA_STATUS="$(report_value "$HELPER_REPORT" VDD_VIA_FINGERPRINT_STATUS)"
VSS_VIA_ADDED="$(report_value "$HELPER_REPORT" VSS_VIA_ADDED_COUNT)"
VSS_VIA_REMOVED="$(report_value "$HELPER_REPORT" VSS_VIA_REMOVED_COUNT)"
NORTH_EFFECT="$(report_value "$HELPER_REPORT" SITE_1_VIA_EFFECT_STATUS)"
SOUTH_EFFECT="$(report_value "$HELPER_REPORT" SITE_2_VIA_EFFECT_STATUS)"
NORTH_NEW_VIAS="$(report_value "$HELPER_REPORT" SITE_1_NEW_LOCAL_VIA_COUNT)"
SOUTH_NEW_VIAS="$(report_value "$HELPER_REPORT" SITE_2_NEW_LOCAL_VIA_COUNT)"
HELPER_STATUS="$(report_value "$HELPER_REPORT" RO6_VSS_VIA_REPAIR_STATUS)"

COMMAND_STATUS="$(report_value "$CHECKPOINT_REPORT" COMMAND_1_STATUS)"
INITIAL_DRC="$(report_value "$CHECKPOINT_REPORT" INITIAL_DRC)"
FINAL_DRC="$(report_value "$CHECKPOINT_REPORT" FINAL_DRC)"
INITIAL_SHORTS="$(report_value "$CHECKPOINT_REPORT" INITIAL_SHORTS)"
FINAL_SHORTS="$(report_value "$CHECKPOINT_REPORT" FINAL_SHORTS)"
INITIAL_REGULAR="$(report_value "$CHECKPOINT_REPORT" INITIAL_REGULAR_CONNECTIVITY_BAD)"
FINAL_REGULAR="$(report_value "$CHECKPOINT_REPORT" FINAL_REGULAR_CONNECTIVITY_BAD)"
INITIAL_SPECIAL_RAW="$(report_value "$CHECKPOINT_REPORT" INITIAL_SPECIAL_CONNECTIVITY_RAW_BAD)"
FINAL_SPECIAL_RAW="$(report_value "$CHECKPOINT_REPORT" FINAL_SPECIAL_CONNECTIVITY_RAW_BAD)"
INITIAL_SPECIAL_NON_RO="$(report_value "$CHECKPOINT_REPORT" INITIAL_SPECIAL_CONNECTIVITY_NON_RO_FAILURES)"
FINAL_SPECIAL_NON_RO="$(report_value "$CHECKPOINT_REPORT" FINAL_SPECIAL_CONNECTIVITY_NON_RO_FAILURES)"
CHECKPOINT_STATUS="$(report_value "$CHECKPOINT_REPORT" CHECKPOINT_REPAIR_STATUS)"
FINAL_CHECKPOINT_EXISTS="$(report_value "$CHECKPOINT_REPORT" FINAL_CHECKPOINT_DAT_EXISTS)"
FINAL_CHECKPOINT_SHA="$(tree_hash "$FINAL_CHECKPOINT")"

DECISION=FAIL_STOP
NEXT_STAGE=STOP_AND_REVIEW_PUBLISHED_EVIDENCE
if [[ "$TOOL_RC" -eq 0 && "$AUTH_STATUS" == PASS && "$PREFLIGHT_STATUS" == PASS &&
      "$GEOMETRY_STATUS" == PASS && "$RESOLVED_SITES" == 2 &&
      "$VIA_ATTEMPTS" == 2 && "$VIA_SUCCESSES" == 2 &&
      "$VDD_SWIRE_STATUS" == UNCHANGED && "$VSS_SWIRE_STATUS" == UNCHANGED &&
      "$VDD_VIA_STATUS" == UNCHANGED && "$VSS_VIA_ADDED" =~ ^[0-9]+$ &&
      "$VSS_VIA_ADDED" -ge 2 && "$VSS_VIA_REMOVED" == 0 &&
      "$NORTH_EFFECT" == PASS && "$SOUTH_EFFECT" == PASS &&
      "$NORTH_NEW_VIAS" =~ ^[1-9][0-9]*$ && "$SOUTH_NEW_VIAS" =~ ^[1-9][0-9]*$ &&
      "$HELPER_STATUS" == PASS_PVS_CANDIDATE && "$COMMAND_STATUS" == PASS &&
      "$INITIAL_DRC" == 0 && "$FINAL_DRC" == 0 &&
      "$INITIAL_SHORTS" == 0 && "$FINAL_SHORTS" == 0 &&
      "$INITIAL_REGULAR" == 0 && "$FINAL_REGULAR" == 0 &&
      "$INITIAL_SPECIAL_RAW" == 1 && "$FINAL_SPECIAL_RAW" == 1 &&
      "$INITIAL_SPECIAL_NON_RO" == 0 && "$FINAL_SPECIAL_NON_RO" == 0 &&
      "$CHECKPOINT_STATUS" == PASS_GEOMETRY_REVIEW_CONNECTIVITY &&
      "$FINAL_CHECKPOINT_EXISTS" == 1 && -d "$FINAL_CHECKPOINT" &&
      "$FINAL_CHECKPOINT_SHA" =~ ^[0-9a-f]{64}$ ]]; then
  DECISION=PASS_PVS_CANDIDATE
  NEXT_STAGE=PVS_RO6_VSS_VIA_CANDIDATE
fi

if [[ -d "$RUN_DIR" ]]; then
  mkdir -p "$RUN_DIR/reports" "$RUN_DIR/manifests"
  {
    echo "# MPTDC RO6 VSS Via Trial Inputs"
    echo "BOUNDARY_PVS_RUN_ID=$BOUNDARY_PVS_RUN_ID"
    echo "BOUNDARY_GATE_SHA256=$(sha256sum "$BOUNDARY_GATE" 2>/dev/null | awk '{print $1}')"
    echo "BOUNDARY_MANIFEST_SHA256=$(sha256sum "$BOUNDARY_MANIFEST" 2>/dev/null | awk '{print $1}')"
    echo "SOURCE_PNR_RUN_ID=$SOURCE_PNR_RUN_ID"
    echo "SOURCE_GATE_SHA256=$(sha256sum "$SOURCE_GATE" 2>/dev/null | awk '{print $1}')"
    echo "SOURCE_CHECKPOINT=$SOURCE_CHECKPOINT"
    echo "SOURCE_CHECKPOINT_SHA256=$SOURCE_CHECKPOINT_ACTUAL_SHA"
    echo "AUTHORIZATION=$AUTHORIZATION"
    echo "COMMANDS_FILE=$COMMANDS_FILE"
    echo "COMMANDS_FILE_SHA256=$(sha256sum "$COMMANDS_FILE" 2>/dev/null | awk '{print $1}')"
    echo "HELPER=$HELPER"
    echo "HELPER_SHA256=$(sha256sum "$HELPER" 2>/dev/null | awk '{print $1}')"
  } > "$RUN_DIR/manifests/ro6_vss_via_trial_inputs.rpt"
  {
    echo "STEP=RO6_VSS_VIA_TRIAL"
    echo "BOUNDARY_PVS_RUN_ID=$BOUNDARY_PVS_RUN_ID"
    echo "BOUNDARY_REMAINDER_CLASS=$BOUNDARY_CLASS"
    echo "BOUNDARY_CLASS_STATUS=$BOUNDARY_CLASS_STATUS"
    echo "SOURCE_PNR_RUN_ID=$SOURCE_PNR_RUN_ID"
    echo "SOURCE_CHECKPOINT=$SOURCE_CHECKPOINT"
    echo "SOURCE_CHECKPOINT_SHA256=$SOURCE_CHECKPOINT_ACTUAL_SHA"
    echo "TOOL_RC=$TOOL_RC"
    echo "AUTHORIZATION=$AUTHORIZATION"
    echo "AUTHORIZATION_STATUS=$AUTH_STATUS"
    echo "HELPER_PREFLIGHT_STATUS=$PREFLIGHT_STATUS"
    echo "GEOMETRY_CONTRACT_STATUS=$GEOMETRY_STATUS"
    echo "RESOLVED_SITE_COUNT=$RESOLVED_SITES"
    echo "VIA_ATTEMPTS=$VIA_ATTEMPTS"
    echo "VIA_SUCCESSES=$VIA_SUCCESSES"
    echo "VDD_SWIRE_FINGERPRINT_STATUS=$VDD_SWIRE_STATUS"
    echo "VSS_SWIRE_FINGERPRINT_STATUS=$VSS_SWIRE_STATUS"
    echo "VDD_VIA_FINGERPRINT_STATUS=$VDD_VIA_STATUS"
    echo "VSS_VIA_ADDED_COUNT=$VSS_VIA_ADDED"
    echo "VSS_VIA_REMOVED_COUNT=$VSS_VIA_REMOVED"
    echo "NORTH_NEW_LOCAL_VIA_COUNT=$NORTH_NEW_VIAS"
    echo "SOUTH_NEW_LOCAL_VIA_COUNT=$SOUTH_NEW_VIAS"
    echo "NORTH_VIA_EFFECT_STATUS=$NORTH_EFFECT"
    echo "SOUTH_VIA_EFFECT_STATUS=$SOUTH_EFFECT"
    echo "HELPER_STATUS=$HELPER_STATUS"
    echo "COMMAND_1_STATUS=$COMMAND_STATUS"
    echo "INITIAL_DRC=$INITIAL_DRC"
    echo "FINAL_DRC=$FINAL_DRC"
    echo "INITIAL_SHORTS=$INITIAL_SHORTS"
    echo "FINAL_SHORTS=$FINAL_SHORTS"
    echo "INITIAL_REGULAR_CONNECTIVITY_BAD=$INITIAL_REGULAR"
    echo "FINAL_REGULAR_CONNECTIVITY_BAD=$FINAL_REGULAR"
    echo "INITIAL_SPECIAL_CONNECTIVITY_RAW_BAD=$INITIAL_SPECIAL_RAW"
    echo "FINAL_SPECIAL_CONNECTIVITY_RAW_BAD=$FINAL_SPECIAL_RAW"
    echo "INITIAL_SPECIAL_CONNECTIVITY_NON_RO_FAILURES=$INITIAL_SPECIAL_NON_RO"
    echo "FINAL_SPECIAL_CONNECTIVITY_NON_RO_FAILURES=$FINAL_SPECIAL_NON_RO"
    echo "CHECKPOINT_REPAIR_STATUS=$CHECKPOINT_STATUS"
    echo "CANDIDATE_CHECKPOINT=$FINAL_CHECKPOINT"
    echo "CANDIDATE_CHECKPOINT_SHA256=$FINAL_CHECKPOINT_SHA"
    echo "CANDIDATE_CHECKPOINT_STATUS=$([[ "$DECISION" == PASS_PVS_CANDIDATE ]] && echo PASS || echo FAIL)"
    echo "PVS_LVS_STATUS=NOT_RUN_BY_SCOPE"
    echo "PVS_DRC_STATUS=NOT_RUN_BY_SCOPE"
    echo "ANTENNA_REPAIR_ATTEMPTED=NO"
    echo "SIGNOFF_ELIGIBLE=NO"
    echo "FINAL_PHYSICAL_SIGNOFF_READY=NO"
    echo "DECISION=$DECISION"
    echo "NEXT_STAGE=$NEXT_STAGE"
  } | tee "$GATE_REPORT"
fi

PUBLISH_RC=NOT_RUN
if [[ -d "$RUN_DIR" ]]; then
  publish_stage
  PUBLISH_RC=$?
  if [[ "$PUBLISH_RC" -ne 0 ]]; then
    DECISION=FAIL_STOP
    NEXT_STAGE=REPUBLISH_RO6_VSS_VIA_TRIAL_EVIDENCE
  fi
fi

echo "RO6_VSS_VIA_TRIAL_STATUS=$([[ "$DECISION" == PASS_PVS_CANDIDATE ]] && echo PASS || echo FAIL)"
echo "PVS_RUN_CLASS=INNOVUS_VIA_CANDIDATE_ONLY"
echo "RUN_ID=$RUN_ID"
echo "BOUNDARY_PVS_RUN_ID=$BOUNDARY_PVS_RUN_ID"
echo "SOURCE_PNR_RUN_ID=$SOURCE_PNR_RUN_ID"
echo "TOOL_RC=$TOOL_RC"
echo "VIA_ATTEMPTS=$VIA_ATTEMPTS"
echo "VIA_SUCCESSES=$VIA_SUCCESSES"
echo "FINAL_DRC=$FINAL_DRC"
echo "FINAL_SHORTS=$FINAL_SHORTS"
echo "FINAL_REGULAR_CONNECTIVITY_BAD=$FINAL_REGULAR"
echo "FINAL_SPECIAL_CONNECTIVITY_RAW_BAD=$FINAL_SPECIAL_RAW"
echo "CANDIDATE_CHECKPOINT=$FINAL_CHECKPOINT"
echo "CANDIDATE_CHECKPOINT_SHA256=$FINAL_CHECKPOINT_SHA"
echo "PVS_LVS_STATUS=NOT_RUN_BY_SCOPE"
echo "SIGNOFF_ELIGIBLE=NO"
echo "DECISION=$DECISION"
echo "PUBLISH_RC=$PUBLISH_RC"
echo "NEXT_EXPECTED_HEAD=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null)"
echo "NEXT_STAGE=$NEXT_STAGE"

if [[ "$DECISION" == PASS_PVS_CANDIDATE && "$PUBLISH_RC" -eq 0 ]]; then
  exit 0
fi
exit 1
