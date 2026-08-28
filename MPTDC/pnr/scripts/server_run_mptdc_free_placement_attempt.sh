#!/usr/bin/env bash
# Run one immutable MPTDC free-placement Innovus candidate.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CANONICAL_DRIVER="$SCRIPT_DIR/server_run_innovus_mptdc_digital_signoff.sh"
FREE_INIT_TCL="$SCRIPT_DIR/innovus_mptdc_free_placement_trial.tcl"
WORK_ROOT="${MPTDC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
INNOVUS_WORK="${MPTDC_INNOVUS_WORK:-$WORK_ROOT/innovus}"
DEFAULT_HANDOFF="$WORK_ROOT/handoff/genus_typical_pnrcompat/MPTDC_TC_BufferedROTap0Pins_Genus_20260709_155623"

RUN_ID=""
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD:-}"
HANDOFF_DIR="${MPTDC_GENUS_HANDOFF_DIR:-$DEFAULT_HANDOFF}"
UTILIZATION="0.50"
CADENCE_ENV="${MPTDC_CADENCE_ENV:-/eda/cadence/eda_2023-2024}"

usage() {
  cat <<'USAGE'
Usage:
  server_run_mptdc_free_placement_attempt.sh --run-id <id> --expected-head <sha> [options]

Options:
  --run-id <id>          Immutable Innovus result directory name.
  --expected-head <sha>  Required SPADMIC_test commit.
  --handoff-dir <path>   Proven Genus handoff directory.
  --utilization <value>  Exactly 0.50 or 0.45.
  --innovus-work <path>  Innovus result root.
  --cadence-env <path>   Cadence environment script.
  -h, --help             Show this help.

Exit codes: 0=PASS, 20=retryable placement/congestion failure, other=stop.
USAGE
}

report_value() {
  local report="$1"
  local key="$2"
  sed -n "s/^${key}=//p" "$report" 2>/dev/null | tail -1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-id) RUN_ID="${2:?missing --run-id value}"; shift 2 ;;
    --expected-head) EXPECTED_HEAD_VALUE="${2:?missing --expected-head value}"; shift 2 ;;
    --handoff-dir) HANDOFF_DIR="${2:?missing --handoff-dir value}"; shift 2 ;;
    --utilization) UTILIZATION="${2:?missing --utilization value}"; shift 2 ;;
    --innovus-work) INNOVUS_WORK="${2:?missing --innovus-work value}"; shift 2 ;;
    --cadence-env) CADENCE_ENV="${2:?missing --cadence-env value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$RUN_ID" ]] || { echo "ERROR: --run-id is required" >&2; exit 2; }
[[ -n "$EXPECTED_HEAD_VALUE" ]] || { echo "ERROR: --expected-head is required" >&2; exit 2; }
[[ "$UTILIZATION" == 0.50 || "$UTILIZATION" == 0.45 ]] || {
  echo "ERROR: --utilization must be exactly 0.50 or 0.45" >&2
  exit 2
}

RESULT_DIR="$INNOVUS_WORK/$RUN_ID"
REPORT_DIR="$RESULT_DIR/reports"
LOG_DIR="$RESULT_DIR/logs"
DRIVER_LOG="$LOG_DIR/free_placement_attempt.driver.log"
GATE="$REPORT_DIR/operator_gate_mptdc_free_placement_attempt.rpt"

cd "$REPO_ROOT" || exit 2
CURRENT_HEAD="$(git rev-parse HEAD 2>/dev/null)"
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
TRACKED_STATUS="$(git status --short --untracked-files=no 2>/dev/null)"

if [[ "$CURRENT_HEAD" != "$EXPECTED_HEAD_VALUE" ||
      "$CURRENT_BRANCH" != SPADMIC_test ||
      -n "$TRACKED_STATUS" ||
      ! -d "$HANDOFF_DIR" ||
      ! -f "$FREE_INIT_TCL" ||
      ! -f "$CANONICAL_DRIVER" ||
      ! -f "$CADENCE_ENV" ||
      -e "$RESULT_DIR" ]]; then
  echo "STOP: free-placement attempt preflight failed"
  echo "CURRENT_HEAD=$CURRENT_HEAD"
  echo "CURRENT_BRANCH=$CURRENT_BRANCH"
  echo "TRACKED_STATUS=${TRACKED_STATUS:-CLEAN}"
  echo "HANDOFF_DIR=$HANDOFF_DIR"
  echo "RESULT_DIR=$RESULT_DIR"
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

export MPTDC_WORK_ROOT="$WORK_ROOT"
export MPTDC_INNOVUS_WORK="$INNOVUS_WORK"
export MPTDC_INNOVUS_INIT_TCL="$FREE_INIT_TCL"
export MPTDC_GENUS_HANDOFF_DIR="$HANDOFF_DIR"
export MPTDC_PNR_CORE_UTIL="$UTILIZATION"
export MPTDC_PNR_ASPECT_RATIO=1.333333
export MPTDC_PNR_FREE_ALL_INTERNAL_PLACEMENT=1
export MPTDC_PNR_FREE_INTERNAL_PLACEMENT=1
export MPTDC_PD_PHYSICAL_AUDIT_MODE=free_internal
export MPTDC_PNR_PD_TILE_CONSTRAINT_MODE=none
export MPTDC_PNR_PD_TILE_APPLY_HIER_BOX=0
export MPTDC_PNR_PD_TILE_USE_FENCE=0
export MPTDC_PNR_PD_TILE_PREPLACE_LEAVES=0
export MPTDC_PNR_PD_TILE_FIX_LEAVES=0
export MPTDC_PNR_PLACE_FAST_TAGS_BY_COLUMN=0
export MPTDC_PNR_SKIP_PHASE_BUFFER_PREPLACE=1
export MPTDC_PNR_FIX_RO_MACROS=0
export MPTDC_PNR_CREATE_RO_HALOS=0
export MPTDC_PNR_CREATE_RO_ROUTE_BLOCKAGES=0
export MPTDC_DISABLE_ANTENNA_REPAIR=1
export MPTDC_POSTROUTE_SETUP_OPT_PASSES=2
export MPTDC_POSTROUTE_SETUP_OPT_MAX_PASSES=2
export MPTDC_POSTROUTE_HOLD_OPT_PASSES=2
export MPTDC_POSTROUTE_HOLD_OPT_MAX_PASSES=2
export MPTDC_PNR_FAST_TAG_TIMING_FOCUS=0
export MPTDC_PNR_FAST_TAG_TARGETED_ECO=0
export MPTDC_DIGITAL_SIGNOFF_APPROVED=1
export MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY=1
export MPTDC_EXPECTED_HEAD="$EXPECTED_HEAD_VALUE"

mkdir -p "$LOG_DIR" "$REPORT_DIR"
set +e
bash "$CANONICAL_DRIVER" \
  --run-id "$RUN_ID" \
  --expected-head "$EXPECTED_HEAD_VALUE" \
  --handoff-dir "$HANDOFF_DIR" \
  --mode full_signoff \
  2>&1 | tee "$DRIVER_LOG"
PNR_RC=${PIPESTATUS[0]}
set +e

PROFILE_GATE="$REPORT_DIR/operator_gate_mptdc_free_placement_trial.rpt"
PROFILE_STATUS="$(report_value "$PROFILE_GATE" MPTDC_FREE_PLACEMENT_TRIAL_STATUS)"
TC_PNR_CLOSURE="$(report_value "$PROFILE_GATE" MPTDC_TC_PNR_CLOSURE)"
TIE1_STATUS="$(report_value "$PROFILE_GATE" TIE1_INSERTION_STATUS)"
DECISION=FAIL_STOP
FAILURE_CLASS=NON_RETRYABLE
NEXT_STAGE=STOP_AND_REVIEW
ATTEMPT_STATUS=FAIL

if [[ "$PNR_RC" -eq 0 && "$PROFILE_STATUS" == PASS &&
      "$TC_PNR_CLOSURE" == PASS && "$TIE1_STATUS" == PASS ]]; then
  ATTEMPT_STATUS=PASS
  FAILURE_CLASS=NONE
  DECISION=PASS_CONTINUE
  NEXT_STAGE=PVS_BASE_DRC_THEN_FULL_LVS
elif grep -Eqi 'MPTDC_(PLACEMENT_GATE_FAILED|FLOORPLAN_[A-Z0-9_]*FAILED|FREE_RO_DOES_NOT_FIT_CORE|FREE_TIE_(EFFECT|LEGALIZE|POST_PLACE)_FAILED)|congestion[^[:alnum:]]*(overflow|failed)|placement[^[:alnum:]]*(overflow|failed)' \
     "$DRIVER_LOG" 2>/dev/null; then
  FAILURE_CLASS=PLACEMENT_OR_CONGESTION
  DECISION=RETRY_LOWER_UTILIZATION
  NEXT_STAGE=RETRY_AT_45_PERCENT_IF_FIRST_ATTEMPT
fi

CHECKPOINT="$RESULT_DIR/checkpoints/04_route.enc.dat"
CHECKPOINT_STATUS=FAIL
CHECKPOINT_SHA256=MISSING
if [[ -d "$CHECKPOINT" ]]; then
  CHECKPOINT_STATUS=PASS
  CHECKPOINT_SHA256="$({
    cd "$CHECKPOINT" || exit 1
    find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum
  } | sha256sum | awk '{print $1}')"
fi
if [[ "$ATTEMPT_STATUS" == PASS && "$CHECKPOINT_STATUS" != PASS ]]; then
  ATTEMPT_STATUS=FAIL
  FAILURE_CLASS=OUTPUT_CONTRACT
  DECISION=FAIL_STOP
  NEXT_STAGE=STOP_AND_REVIEW
fi

{
  echo "STEP=MPTDC_FREE_PLACEMENT_ATTEMPT"
  echo "RUN_ID=$RUN_ID"
  echo "PNR_RUN_CLASS=DIAGNOSTIC_FREE_PLACEMENT_TC_ONLY"
  echo "EXPECTED_HEAD=$EXPECTED_HEAD_VALUE"
  echo "CURRENT_HEAD=$CURRENT_HEAD"
  echo "GENUS_HANDOFF_DIR=$HANDOFF_DIR"
  echo "CORE_UTILIZATION=$UTILIZATION"
  echo "CORE_ASPECT_TARGET=4:3"
  echo "PNR_RC=$PNR_RC"
  echo "PROFILE_GATE=$PROFILE_GATE"
  echo "PROFILE_STATUS=${PROFILE_STATUS:-MISSING}"
  echo "MPTDC_TC_PNR_CLOSURE=${TC_PNR_CLOSURE:-MISSING}"
  echo "TIE1_INSERTION_STATUS=${TIE1_STATUS:-MISSING}"
  echo "SOURCE_CHECKPOINT=$CHECKPOINT"
  echo "SOURCE_CHECKPOINT_STATUS=$CHECKPOINT_STATUS"
  echo "SOURCE_CHECKPOINT_SHA256=$CHECKPOINT_SHA256"
  echo "FAILURE_CLASS=$FAILURE_CLASS"
  echo "MPTDC_FREE_PLACEMENT_ATTEMPT_STATUS=$ATTEMPT_STATUS"
  echo "SIGNOFF_ELIGIBLE=NO"
  echo "DECISION=$DECISION"
  echo "NEXT_STAGE=$NEXT_STAGE"
} | tee "$GATE"

if [[ "$ATTEMPT_STATUS" == PASS ]]; then
  exit 0
fi
if [[ "$FAILURE_CLASS" == PLACEMENT_OR_CONGESTION ]]; then
  exit 20
fi
exit 1
