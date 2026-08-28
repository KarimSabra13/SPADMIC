#!/usr/bin/env bash
# Orchestrate the isolated 50%/45% free-placement trial and mandatory PVS gates.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
ATTEMPT_DRIVER="$SCRIPT_DIR/server_run_mptdc_free_placement_attempt.sh"
PVS_DRIVER="$REPO_ROOT/MPTDC/scripts/pvs/server_run_mptdc_free_trial_pvs.sh"
PUBLISHER="$REPO_ROOT/MPTDC/ci/publish_mptdc_server_snapshot.sh"
WORK_ROOT="${MPTDC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
INNOVUS_WORK="${MPTDC_INNOVUS_WORK:-$WORK_ROOT/innovus}"

BASE_RUN_ID=""
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD:-}"
HANDOFF_DIR="${MPTDC_GENUS_HANDOFF_DIR:-$WORK_ROOT/handoff/genus_typical_pnrcompat/MPTDC_TC_BufferedROTap0Pins_Genus_20260709_155623}"
RO_GDS="${MPTDC_PVS_RO_GDS:-$WORK_ROOT/ro6_oa_exports/20260827_mptdc_ro6_vddfix_fresh_export_150040/RO_tune6.gds}"
AUTO_DENSITY_DEADLINE="22:00"

usage() {
  cat <<'USAGE'
Usage:
  server_run_mptdc_free_pnr_pipeline.sh --run-id <base-id> --expected-head <sha> [options]

Options:
  --run-id <base-id>            Base id; creates _u50, optional _u45, and _pvs runs.
  --expected-head <sha>         Required starting SPADMIC_test commit.
  --handoff-dir <path>          Proven Genus handoff.
  --ro-gds <path>               Fresh repaired RO_tune6 GDS.
  --innovus-work <path>         Innovus/PVS result root.
  --auto-density-deadline HH:MM Run optional density only when mandatory gates
                                 finish at least 90 minutes before this time.
  --no-auto-density             Do not run optional density.
  -h, --help                    Show this help.

Every completed candidate is published before continuation. The second PnR
attempt is allowed only when the 50% gate classifies placement/congestion.
USAGE
}

report_value() {
  local report="$1"
  local key="$2"
  sed -n "s/^${key}=//p" "$report" 2>/dev/null | tail -1
}

publish_snapshot() {
  local kind="$1"
  local id="$2"
  local source_dir="$3"
  local step="$4"
  local log="/tmp/${id}.publish.log"
  local rc
  set +e
  if [[ "$kind" == innovus ]]; then
    MPTDC_SNAPSHOT_INCLUDE_MANAGER_IMAGES=1 \
      bash "$PUBLISHER" "$kind" "$id" "$source_dir" "$step" 2>&1 | tee "$log" >&2
    rc=${PIPESTATUS[0]}
  else
    bash "$PUBLISHER" "$kind" "$id" "$source_dir" "$step" 2>&1 | tee "$log" >&2
    rc=${PIPESTATUS[0]}
  fi
  set +e
  if [[ "$rc" != 0 ]]; then
    return "$rc"
  fi
  report_value "$log" NEXT_EXPECTED_HEAD
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-id) BASE_RUN_ID="${2:?missing --run-id value}"; shift 2 ;;
    --expected-head) EXPECTED_HEAD_VALUE="${2:?missing --expected-head value}"; shift 2 ;;
    --handoff-dir) HANDOFF_DIR="${2:?missing --handoff-dir value}"; shift 2 ;;
    --ro-gds) RO_GDS="${2:?missing --ro-gds value}"; shift 2 ;;
    --innovus-work) INNOVUS_WORK="${2:?missing --innovus-work value}"; shift 2 ;;
    --auto-density-deadline) AUTO_DENSITY_DEADLINE="${2:?missing deadline value}"; shift 2 ;;
    --no-auto-density) AUTO_DENSITY_DEADLINE=""; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$BASE_RUN_ID" ]] || { echo "ERROR: --run-id is required" >&2; exit 2; }
[[ -n "$EXPECTED_HEAD_VALUE" ]] || { echo "ERROR: --expected-head is required" >&2; exit 2; }

cd "$REPO_ROOT" || exit 2
CURRENT_HEAD="$(git rev-parse HEAD 2>/dev/null)"
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
TRACKED_STATUS="$(git status --short --untracked-files=no 2>/dev/null)"
if [[ "$CURRENT_HEAD" != "$EXPECTED_HEAD_VALUE" ||
      "$CURRENT_BRANCH" != SPADMIC_test || -n "$TRACKED_STATUS" ]]; then
  echo "STOP: pipeline git preflight failed"
  echo "CURRENT_HEAD=$CURRENT_HEAD"
  echo "CURRENT_BRANCH=$CURRENT_BRANCH"
  echo "TRACKED_STATUS=${TRACKED_STATUS:-CLEAN}"
  exit 3
fi

ATTEMPT50="${BASE_RUN_ID}_u50"
ATTEMPT45="${BASE_RUN_ID}_u45"
PVS_RUN="${BASE_RUN_ID}_pvs"
SELECTED_PNR_RUN=NONE
ATTEMPT50_RC=99
ATTEMPT45_RC=NOT_RUN
PVS_RC=NOT_RUN
PUBLISH50_RC=99
PUBLISH45_RC=NOT_RUN
PUBLISH_PVS_RC=NOT_RUN
PIPELINE_STATUS=FAIL
DECISION=FAIL_STOP
NEXT_STAGE=STOP_AND_REVIEW

set +e
bash "$ATTEMPT_DRIVER" --run-id "$ATTEMPT50" --expected-head "$EXPECTED_HEAD_VALUE" \
  --handoff-dir "$HANDOFF_DIR" --utilization 0.50 --innovus-work "$INNOVUS_WORK"
ATTEMPT50_RC=$?
set +e

if [[ -d "$INNOVUS_WORK/$ATTEMPT50" ]]; then
  set +e
  NEXT_HEAD="$(publish_snapshot innovus "$ATTEMPT50" "$INNOVUS_WORK/$ATTEMPT50" MPTDC_FREE_PLACEMENT_ATTEMPT)"
  PUBLISH50_RC=$?
  set +e
  if [[ "$PUBLISH50_RC" != 0 || -z "$NEXT_HEAD" ]]; then
    echo "STOP: 50% attempt evidence publish failed"
    exit 4
  fi
  EXPECTED_HEAD_VALUE="$NEXT_HEAD"
fi

if [[ "$ATTEMPT50_RC" == 0 ]]; then
  SELECTED_PNR_RUN="$ATTEMPT50"
elif [[ "$ATTEMPT50_RC" == 20 ]]; then
  set +e
  bash "$ATTEMPT_DRIVER" --run-id "$ATTEMPT45" --expected-head "$EXPECTED_HEAD_VALUE" \
    --handoff-dir "$HANDOFF_DIR" --utilization 0.45 --innovus-work "$INNOVUS_WORK"
  ATTEMPT45_RC=$?
  set +e
  if [[ -d "$INNOVUS_WORK/$ATTEMPT45" ]]; then
    set +e
    NEXT_HEAD="$(publish_snapshot innovus "$ATTEMPT45" "$INNOVUS_WORK/$ATTEMPT45" MPTDC_FREE_PLACEMENT_RETRY)"
    PUBLISH45_RC=$?
    set +e
    if [[ "$PUBLISH45_RC" != 0 || -z "$NEXT_HEAD" ]]; then
      echo "STOP: 45% retry evidence publish failed"
      exit 4
    fi
    EXPECTED_HEAD_VALUE="$NEXT_HEAD"
  fi
  if [[ "$ATTEMPT45_RC" == 0 ]]; then
    SELECTED_PNR_RUN="$ATTEMPT45"
  fi
fi

if [[ "$SELECTED_PNR_RUN" != NONE ]]; then
  PVS_ARGS=(
    --pnr-run-id "$SELECTED_PNR_RUN"
    --run-id "$PVS_RUN"
    --expected-head "$EXPECTED_HEAD_VALUE"
    --ro-gds "$RO_GDS"
    --innovus-work "$INNOVUS_WORK"
  )
  if [[ -n "$AUTO_DENSITY_DEADLINE" ]]; then
    PVS_ARGS+=(--auto-density-deadline "$AUTO_DENSITY_DEADLINE")
  fi
  set +e
  bash "$PVS_DRIVER" "${PVS_ARGS[@]}"
  PVS_RC=$?
  set +e
  if [[ -d "$INNOVUS_WORK/$PVS_RUN" ]]; then
    set +e
    NEXT_HEAD="$(publish_snapshot pvs "$PVS_RUN" "$INNOVUS_WORK/$PVS_RUN" MPTDC_FREE_TRIAL_PVS)"
    PUBLISH_PVS_RC=$?
    set +e
    if [[ "$PUBLISH_PVS_RC" != 0 || -z "$NEXT_HEAD" ]]; then
      echo "STOP: PVS evidence publish failed"
      exit 4
    fi
    EXPECTED_HEAD_VALUE="$NEXT_HEAD"
  fi
fi

PVS_GATE="$INNOVUS_WORK/$PVS_RUN/reports/operator_gate_mptdc_free_trial_pvs.rpt"
if [[ "$PVS_RC" == 0 &&
      "$(report_value "$PVS_GATE" MPTDC_FREE_TRIAL_PVS_STATUS)" == PASS &&
      "$(report_value "$PVS_GATE" PVS_LVS)" == MATCH ]]; then
  PIPELINE_STATUS=PASS
  DECISION=PASS_MANAGER_DELIVERY
  NEXT_STAGE=PACKAGE_MANAGER_EVIDENCE
elif [[ "$(report_value "$PVS_GATE" BASE_DRC_CLASS)" == NON_ANTENNA_DRC ]]; then
  DECISION=FAIL_STOP_ONE_ATTRIBUTED_ROUTING_ECO_ELIGIBLE
  NEXT_STAGE=REVIEW_EXACT_PVS_MARKERS_THEN_RUN_ONE_HASH_GUARDED_ROUTING_ECO
fi

FINAL_HEAD="$(git rev-parse HEAD 2>/dev/null)"
echo "===== MPTDC FREE PNR PIPELINE RESULT ====="
echo "BASE_RUN_ID=$BASE_RUN_ID"
echo "ATTEMPT50=$ATTEMPT50"
echo "ATTEMPT50_RC=$ATTEMPT50_RC"
echo "PUBLISH50_RC=$PUBLISH50_RC"
echo "ATTEMPT45=$ATTEMPT45"
echo "ATTEMPT45_RC=$ATTEMPT45_RC"
echo "PUBLISH45_RC=$PUBLISH45_RC"
echo "SELECTED_PNR_RUN=$SELECTED_PNR_RUN"
echo "PVS_RUN=$PVS_RUN"
echo "PVS_RC=$PVS_RC"
echo "PUBLISH_PVS_RC=$PUBLISH_PVS_RC"
echo "MPTDC_FREE_PNR_PIPELINE_STATUS=$PIPELINE_STATUS"
echo "SIGNOFF_ELIGIBLE=NO"
echo "DECISION=$DECISION"
echo "NEXT_STAGE=$NEXT_STAGE"
echo "NEXT_EXPECTED_HEAD=$FINAL_HEAD"

[[ "$PIPELINE_STATUS" == PASS ]]
