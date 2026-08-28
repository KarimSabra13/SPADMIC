#!/usr/bin/env bash
# Run attributable base DRC and full LVS for one accepted free-placement PnR run.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PREP="$SCRIPT_DIR/00_prepare_pvs_inputs_from_checkpoint.sh"
AUDIT="$SCRIPT_DIR/01_audit_pvs_templates.sh"
DRC="$SCRIPT_DIR/02_replay_pvs_drc_from_template.sh"
LVS="$SCRIPT_DIR/03_replay_pvs_lvs_from_template.sh"
CLASSIFIER="$SCRIPT_DIR/07_classify_mptdc_free_trial_drc.py"
WORK_ROOT="${MPTDC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
INNOVUS_WORK="${MPTDC_INNOVUS_WORK:-$WORK_ROOT/innovus}"
DEFAULT_RO_GDS="$WORK_ROOT/ro6_oa_exports/20260827_mptdc_ro6_vddfix_fresh_export_150040/RO_tune6.gds"
DEFAULT_RO_GDS_SHA256="9d6f269541d51db0c30c5e7cc81334d70578ca8723558b32f34f9803469ea36a"

PNR_RUN_ID=""
RUN_ID=""
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD:-}"
RO_GDS="${MPTDC_PVS_RO_GDS:-$DEFAULT_RO_GDS}"
EXPECTED_RO_GDS_SHA256="${MPTDC_EXPECTED_RO_GDS_SHA256:-$DEFAULT_RO_GDS_SHA256}"
CADENCE_ENV="${MPTDC_CADENCE_ENV:-/eda/cadence/eda_2023-2024}"
RUN_DENSITY=0
AUTO_DENSITY_DEADLINE=""
DENSITY_MIN_REMAINING_MINUTES=90

usage() {
  cat <<'USAGE'
Usage:
  server_run_mptdc_free_trial_pvs.sh --pnr-run-id <id> --run-id <id> --expected-head <sha> [options]

Options:
  --pnr-run-id <id>            Accepted free-placement Innovus run or its sole
                               passing attributed routing-ECO run.
  --run-id <id>                New immutable PVS result directory.
  --expected-head <sha>        Required SPADMIC_test commit.
  --ro-gds <path>              Fresh RO_tune6 OA GDS.
  --expected-ro-gds-sha <sha>  Required RO GDS SHA256.
  --innovus-work <path>        Innovus/PVS result root.
  --run-density                Run optional density DRC after mandatory LVS.
  --auto-density-deadline HH:MM
                               Run density only if mandatory LVS finishes at
                               least 90 minutes before this local deadline.
  --cadence-env <path>         Cadence environment script.
  -h, --help                   Show this help.

The driver never repairs antenna violations. CLEAN and the exact four-rule
antenna-only manager exception may proceed to full LVS. Any non-antenna rule
stops for at most one separately reviewed, hash-guarded routing ECO.
USAGE
}

report_value() {
  local report="$1"
  local key="$2"
  sed -n "s/^${key}=//p" "$report" 2>/dev/null | tail -1
}

tree_hash() {
  local root="$1"
  (
    cd "$root" 2>/dev/null || return 1
    find . -type f -print0 2>/dev/null |
      LC_ALL=C sort -z |
      xargs -0 sha256sum
  ) | sha256sum | awk '{print $1}'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pnr-run-id) PNR_RUN_ID="${2:?missing --pnr-run-id value}"; shift 2 ;;
    --run-id) RUN_ID="${2:?missing --run-id value}"; shift 2 ;;
    --expected-head) EXPECTED_HEAD_VALUE="${2:?missing --expected-head value}"; shift 2 ;;
    --ro-gds) RO_GDS="${2:?missing --ro-gds value}"; shift 2 ;;
    --expected-ro-gds-sha) EXPECTED_RO_GDS_SHA256="${2:?missing --expected-ro-gds-sha value}"; shift 2 ;;
    --innovus-work) INNOVUS_WORK="${2:?missing --innovus-work value}"; shift 2 ;;
    --run-density) RUN_DENSITY=1; shift ;;
    --auto-density-deadline) AUTO_DENSITY_DEADLINE="${2:?missing deadline value}"; shift 2 ;;
    --cadence-env) CADENCE_ENV="${2:?missing --cadence-env value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$PNR_RUN_ID" ]] || { echo "ERROR: --pnr-run-id is required" >&2; exit 2; }
[[ -n "$RUN_ID" ]] || { echo "ERROR: --run-id is required" >&2; exit 2; }
[[ -n "$EXPECTED_HEAD_VALUE" ]] || { echo "ERROR: --expected-head is required" >&2; exit 2; }

PNR_DIR="$INNOVUS_WORK/$PNR_RUN_ID"
FREE_PNR_GATE="$PNR_DIR/reports/operator_gate_mptdc_free_placement_attempt.rpt"
ECO_PNR_GATE="$PNR_DIR/reports/operator_gate_mptdc_free_trial_pvs_eco.rpt"
PNR_GATE=MISSING
PNR_GATE_KIND=MISSING
PNR_GATE_STATUS=FAIL
PVS_ECO_ATTEMPT_COUNT=MISSING
CHECKPOINT=MISSING

if [[ -s "$FREE_PNR_GATE" ]]; then
  PNR_GATE="$FREE_PNR_GATE"
  PNR_GATE_KIND=FREE_PLACEMENT
  PVS_ECO_ATTEMPT_COUNT=0
  CHECKPOINT="$(report_value "$PNR_GATE" SOURCE_CHECKPOINT)"
  if [[ "$(report_value "$PNR_GATE" MPTDC_FREE_PLACEMENT_ATTEMPT_STATUS)" == PASS &&
        "$(report_value "$PNR_GATE" MPTDC_TC_PNR_CLOSURE)" == PASS &&
        "$(report_value "$PNR_GATE" TIE1_INSERTION_STATUS)" == PASS ]]; then
    PNR_GATE_STATUS=PASS
  fi
elif [[ -s "$ECO_PNR_GATE" ]]; then
  PNR_GATE="$ECO_PNR_GATE"
  PNR_GATE_KIND=ONE_ATTRIBUTED_PVS_ROUTING_ECO
  PVS_ECO_ATTEMPT_COUNT="$(report_value "$PNR_GATE" PVS_ECO_ATTEMPT_COUNT)"
  CHECKPOINT="$(report_value "$PNR_GATE" SOURCE_CHECKPOINT)"
  if [[ "$(report_value "$PNR_GATE" MPTDC_FREE_TRIAL_PVS_ECO_STATUS)" == PASS &&
        "$(report_value "$PNR_GATE" MPTDC_TC_PNR_CLOSURE)" == PASS &&
        "$(report_value "$PNR_GATE" TIE1_INSERTION_STATUS)" == PASS &&
        "$PVS_ECO_ATTEMPT_COUNT" == 1 ]]; then
    PNR_GATE_STATUS=PASS
  fi
fi

FILLER_REPORT="$PNR_DIR/reports/filler_status.rpt"
ROW_INFRA_REPORT="$PNR_DIR/reports/row_infra_insertion.rpt"
PVS_DIR="$INNOVUS_WORK/$RUN_ID"
DRIVER_LOG="/tmp/${RUN_ID}.driver.log"

cd "$REPO_ROOT" || exit 2
CURRENT_HEAD="$(git rev-parse HEAD 2>/dev/null)"
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
TRACKED_STATUS="$(git status --short --untracked-files=no 2>/dev/null)"
RO_GDS_SHA256="$(sha256sum "$RO_GDS" 2>/dev/null | awk '{print $1}')"
EXPECTED_CHECKPOINT_SHA256="$(report_value "$PNR_GATE" SOURCE_CHECKPOINT_SHA256)"
CHECKPOINT_SHA256_PRE="$(tree_hash "$CHECKPOINT" 2>/dev/null)"

if [[ "$CURRENT_HEAD" != "$EXPECTED_HEAD_VALUE" ||
      "$CURRENT_BRANCH" != SPADMIC_test ||
      -n "$TRACKED_STATUS" ||
      "$PNR_GATE_STATUS" != PASS ||
      ! "$PVS_ECO_ATTEMPT_COUNT" =~ ^[01]$ ||
      ! -d "$CHECKPOINT" ||
      ! "$EXPECTED_CHECKPOINT_SHA256" =~ ^[0-9a-f]{64}$ ||
      "$CHECKPOINT_SHA256_PRE" != "$EXPECTED_CHECKPOINT_SHA256" ||
      ! -s "$FILLER_REPORT" ||
      ! -s "$ROW_INFRA_REPORT" ||
      "$RO_GDS_SHA256" != "$EXPECTED_RO_GDS_SHA256" ||
      ! -f "$CADENCE_ENV" ||
      -e "$PVS_DIR" ]]; then
  echo "STOP: free-placement PVS preflight failed"
  echo "CURRENT_HEAD=$CURRENT_HEAD"
  echo "CURRENT_BRANCH=$CURRENT_BRANCH"
  echo "TRACKED_STATUS=${TRACKED_STATUS:-CLEAN}"
  echo "PNR_GATE=$PNR_GATE"
  echo "PNR_GATE_KIND=$PNR_GATE_KIND"
  echo "PNR_GATE_STATUS=$PNR_GATE_STATUS"
  echo "PVS_ECO_ATTEMPT_COUNT=$PVS_ECO_ATTEMPT_COUNT"
  echo "CHECKPOINT=$CHECKPOINT"
  echo "CHECKPOINT_SHA256_PRE=${CHECKPOINT_SHA256_PRE:-MISSING}"
  echo "EXPECTED_CHECKPOINT_SHA256=${EXPECTED_CHECKPOINT_SHA256:-MISSING}"
  echo "RO_GDS_SHA256=${RO_GDS_SHA256:-MISSING}"
  exit 3
fi

set +u
# shellcheck disable=SC1090
source "$CADENCE_ENV"
CADENCE_ENV_RC=$?
set -u
if [[ "$CADENCE_ENV_RC" -ne 0 ]]; then
  echo "STOP: Cadence environment failed with rc=$CADENCE_ENV_RC"
  exit 4
fi

PREP_RC=99
AUDIT_RC=99
BASE_DRC_RC=99
CLASSIFIER_RC=99
LVS_RC=99
DENSITY_DRC_RC=99
PVS_LVS=NOT_RUN
LVS_CLS_FILE_COUNT=0
LVS_CLS_FILE=MISSING
BLACKBOXED_CELL_COUNT=MISSING
BASE_DRC_CLASS=NOT_RUN
DENSITY_DRC_STATUS=NOT_RUN_BY_SCOPE
DECISION=FAIL_STOP
NEXT_STAGE=STOP_AND_REVIEW

set +e
bash "$PREP" \
  --checkpoint "$CHECKPOINT" \
  --run-id "$RUN_ID" \
  --innovus-work "$INNOVUS_WORK" \
  --expected-head "$EXPECTED_HEAD_VALUE" \
  --ro-gds "$RO_GDS" \
  --filler-report "$FILLER_REPORT" \
  --row-infra-report "$ROW_INFRA_REPORT" \
  --strict-attribution \
  2>&1 | tee "$DRIVER_LOG"
PREP_RC=${PIPESTATUS[0]}
set +e

if [[ "$PREP_RC" -eq 0 ]]; then
  set +e
  bash "$AUDIT" --result-dir "$PVS_DIR" --expected-head "$EXPECTED_HEAD_VALUE" \
    2>&1 | tee -a "$DRIVER_LOG"
  AUDIT_RC=${PIPESTATUS[0]}
  set +e
fi

if [[ "$PREP_RC" -eq 0 && "$AUDIT_RC" -eq 0 ]]; then
  set +e
  bash "$DRC" --prepared-dir "$PVS_DIR" --variant base \
    --expected-head "$EXPECTED_HEAD_VALUE" 2>&1 | tee -a "$DRIVER_LOG"
  BASE_DRC_RC=${PIPESTATUS[0]}
  set +e
fi

BASE_STATUS="$PVS_DIR/reports/pvs_drc_base_status.rpt"
BASE_RULES="$PVS_DIR/reports/pvs_drc_base_nonzero_rules.tsv"
CLASSIFICATION="$PVS_DIR/reports/pvs_free_trial_drc_classification.rpt"
MANAGER_SCOPE="$PVS_DIR/manifests/pvs_free_trial_manager_scope.rpt"
if [[ -s "$BASE_STATUS" && -s "$BASE_RULES" &&
      "$(report_value "$BASE_STATUS" PVS_RC)" == 0 ]]; then
  set +e
  python3 "$CLASSIFIER" --status-report "$BASE_STATUS" --rule-report "$BASE_RULES" \
    --out "$CLASSIFICATION" --scope-out "$MANAGER_SCOPE" \
    2>&1 | tee -a "$DRIVER_LOG"
  CLASSIFIER_RC=${PIPESTATUS[0]}
  set +e
  BASE_DRC_CLASS="$(report_value "$CLASSIFICATION" PVS_BASE_DRC_CLASS)"
fi

if [[ "$CLASSIFIER_RC" -eq 0 &&
      ( "$BASE_DRC_CLASS" == CLEAN || "$BASE_DRC_CLASS" == ANTENNA_ONLY_MANAGER_EXCEPTION ) ]]; then
  set +e
  bash "$LVS" --prepared-dir "$PVS_DIR" --expected-head "$EXPECTED_HEAD_VALUE" \
    --diagnostic-free-manager-scope 2>&1 | tee -a "$DRIVER_LOG"
  LVS_RC=${PIPESTATUS[0]}
  set +e
  PVS_LVS="$(report_value "$PVS_DIR/reports/pvs_lvs_status.rpt" PVS_LVS_STATUS)"
  LVS_CLS_FILE_COUNT="$(find "$PVS_DIR/pvs_lvs" -type f -name '*.cls' 2>/dev/null | wc -l | tr -d ' ')"
  if [[ "$LVS_CLS_FILE_COUNT" == 1 ]]; then
    LVS_CLS_FILE="$(find "$PVS_DIR/pvs_lvs" -type f -name '*.cls' -print 2>/dev/null | sed -n '1p')"
    BLACKBOXED_CELL_COUNT="$(awk -F '|' '/Cells that have been blackboxed/ {gsub(/[[:space:]]/, "", $2); print $2}' "$LVS_CLS_FILE" | tail -1)"
  fi
  if [[ "$LVS_RC" -eq 0 && ( "$LVS_CLS_FILE_COUNT" != 1 || "$BLACKBOXED_CELL_COUNT" != 0 ) ]]; then
    LVS_RC=8
    PVS_LVS=NOT_PROVEN
  fi
fi

if [[ "$LVS_RC" -eq 0 && "$PVS_LVS" == MATCH && -n "$AUTO_DENSITY_DEADLINE" ]]; then
  DEADLINE_EPOCH="$(date -d "$(date +%F) $AUTO_DENSITY_DEADLINE" +%s 2>/dev/null || echo 0)"
  NOW_EPOCH="$(date +%s)"
  if [[ "$DEADLINE_EPOCH" -gt 0 &&
        $((DEADLINE_EPOCH - NOW_EPOCH)) -ge $((DENSITY_MIN_REMAINING_MINUTES * 60)) ]]; then
    RUN_DENSITY=1
  fi
fi

if [[ "$CLASSIFIER_RC" -eq 0 && "$LVS_RC" -eq 0 && "$PVS_LVS" == MATCH && "$RUN_DENSITY" -eq 1 ]]; then
  set +e
  bash "$DRC" --prepared-dir "$PVS_DIR" --variant density \
    --expected-head "$EXPECTED_HEAD_VALUE" 2>&1 | tee -a "$DRIVER_LOG"
  DENSITY_DRC_RC=${PIPESTATUS[0]}
  set +e
  DENSITY_DRC_STATUS="$(report_value "$PVS_DIR/reports/pvs_drc_density_status.rpt" PVS_DRC_STATUS)"
fi

CHECKPOINT_SHA256_POST="$(tree_hash "$CHECKPOINT" 2>/dev/null)"
RO_GDS_SHA256_POST="$(sha256sum "$RO_GDS" 2>/dev/null | awk '{print $1}')"
SOURCE_INPUT_READ_ONLY_STATUS=FAIL
if [[ "$CHECKPOINT_SHA256_PRE" == "$CHECKPOINT_SHA256_POST" &&
      "$RO_GDS_SHA256" == "$RO_GDS_SHA256_POST" ]]; then
  SOURCE_INPUT_READ_ONLY_STATUS=PASS
fi

PVS_STATUS=FAIL
if [[ "$CLASSIFIER_RC" -eq 0 && "$LVS_RC" -eq 0 && "$PVS_LVS" == MATCH &&
      "$SOURCE_INPUT_READ_ONLY_STATUS" == PASS ]]; then
  PVS_STATUS=PASS
  DECISION=PASS_MANAGER_DELIVERY
  NEXT_STAGE=PACKAGE_MANAGER_EVIDENCE
  if [[ "$RUN_DENSITY" -eq 1 && "$DENSITY_DRC_STATUS" != PASS ]]; then
    DECISION=PASS_MANAGER_DELIVERY_WITH_DENSITY_DEBT_DISCLOSED
    NEXT_STAGE=PACKAGE_MANAGER_EVIDENCE_AND_REVIEW_OPTIONAL_DENSITY
  fi
elif [[ "$BASE_DRC_CLASS" == NON_ANTENNA_DRC && "$PVS_ECO_ATTEMPT_COUNT" == 0 &&
        "$SOURCE_INPUT_READ_ONLY_STATUS" == PASS ]]; then
  DECISION=FAIL_STOP_ONE_ATTRIBUTED_ROUTING_ECO_ELIGIBLE
  NEXT_STAGE=REVIEW_EXACT_PVS_MARKERS_THEN_RUN_ONE_HASH_GUARDED_ROUTING_ECO
elif [[ "$BASE_DRC_CLASS" == NON_ANTENNA_DRC && "$PVS_ECO_ATTEMPT_COUNT" == 1 &&
        "$SOURCE_INPUT_READ_ONLY_STATUS" == PASS ]]; then
  DECISION=FAIL_STOP_PVS_ECO_LIMIT_REACHED
  NEXT_STAGE=STOP_AND_REVIEW_NO_SECOND_ROUTING_ECO_AUTHORIZED
fi

GATE="$PVS_DIR/reports/operator_gate_mptdc_free_trial_pvs.rpt"
{
  echo "STEP=MPTDC_FREE_TRIAL_PVS"
  echo "PNR_RUN_ID=$PNR_RUN_ID"
  echo "PNR_GATE=$PNR_GATE"
  echo "PNR_GATE_KIND=$PNR_GATE_KIND"
  echo "PNR_GATE_STATUS=$PNR_GATE_STATUS"
  echo "PVS_RUN_ID=$RUN_ID"
  echo "PVS_RUN_CLASS=DIAGNOSTIC_FREE_PLACEMENT_MANAGER_SCOPE"
  echo "SOURCE_CHECKPOINT=$CHECKPOINT"
  echo "EXPECTED_CHECKPOINT_SHA256=$EXPECTED_CHECKPOINT_SHA256"
  echo "CHECKPOINT_SHA256_PRE=$CHECKPOINT_SHA256_PRE"
  echo "CHECKPOINT_SHA256_POST=$CHECKPOINT_SHA256_POST"
  echo "RO_GDS=$RO_GDS"
  echo "RO_GDS_SHA256=$RO_GDS_SHA256"
  echo "RO_GDS_SHA256_POST=$RO_GDS_SHA256_POST"
  echo "SOURCE_INPUT_READ_ONLY_STATUS=$SOURCE_INPUT_READ_ONLY_STATUS"
  echo "CADENCE_ENV_RC=$CADENCE_ENV_RC"
  echo "PREP_RC=$PREP_RC"
  echo "AUDIT_RC=$AUDIT_RC"
  echo "BASE_DRC_RC=$BASE_DRC_RC"
  echo "BASE_DRC_CLASS=$BASE_DRC_CLASS"
  echo "ANTENNA_REPAIR_ATTEMPTED=NO"
  echo "MANAGER_ANTENNA_EXCEPTION=$([[ "$BASE_DRC_CLASS" == ANTENNA_ONLY_MANAGER_EXCEPTION ]] && echo YES || echo NOT_NEEDED)"
  echo "PVS_ECO_ATTEMPT_COUNT=$PVS_ECO_ATTEMPT_COUNT"
  echo "PVS_ECO_MAX_ATTEMPTS=1"
  echo "LVS_RC=$LVS_RC"
  echo "PVS_LVS=$PVS_LVS"
  echo "LVS_CLS_FILE_COUNT=$LVS_CLS_FILE_COUNT"
  echo "LVS_CLS_FILE=$LVS_CLS_FILE"
  echo "BLACKBOXED_CELL_COUNT=$BLACKBOXED_CELL_COUNT"
  echo "DENSITY_REQUESTED=$RUN_DENSITY"
  echo "AUTO_DENSITY_DEADLINE=${AUTO_DENSITY_DEADLINE:-NONE}"
  echo "DENSITY_MIN_REMAINING_MINUTES=$DENSITY_MIN_REMAINING_MINUTES"
  echo "DENSITY_DRC_RC=$DENSITY_DRC_RC"
  echo "DENSITY_DRC_STATUS=$DENSITY_DRC_STATUS"
  echo "MPTDC_FREE_TRIAL_PVS_STATUS=$PVS_STATUS"
  echo "MANAGER_DELIVERY_READY=$([[ "$PVS_STATUS" == PASS ]] && echo YES || echo NO)"
  echo "SIGNOFF_ELIGIBLE=NO"
  echo "DECISION=$DECISION"
  echo "NEXT_STAGE=$NEXT_STAGE"
} | tee "$GATE"

[[ "$PVS_STATUS" == PASS ]]
