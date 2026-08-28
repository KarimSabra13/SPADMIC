#!/usr/bin/env bash
# Run the sole authorized, hash-guarded routing ECO for a free-placement PVS result.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
REPAIR_DRIVER="${MPTDC_FREE_ECO_REPAIR_DRIVER:-$SCRIPT_DIR/server_repair_mptdc_route_checkpoint.sh}"
VALIDATOR="$SCRIPT_DIR/validate_mptdc_free_pvs_eco_commands.py"
WORK_ROOT="${MPTDC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
INNOVUS_WORK="${MPTDC_INNOVUS_WORK:-$WORK_ROOT/innovus}"
CADENCE_ENV="${MPTDC_CADENCE_ENV:-/eda/cadence/eda_2023-2024}"

SOURCE_PNR_RUN_ID=""
SOURCE_PVS_RUN_ID=""
RUN_ID=""
COMMANDS_FILE=""
EXPECTED_COMMANDS_SHA256=""
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD:-}"
AUTHORIZATION=""

usage() {
  cat <<'USAGE'
Usage:
  server_run_mptdc_free_trial_pvs_eco.sh \
    --source-pnr-run-id <id> --source-pvs-run-id <id> --run-id <id> \
    --commands-file <tracked-file> --expected-commands-sha <sha256> \
    --authorization EXACT_MPTDC_FREE_TRIAL_ONE_PVS_ROUTING_ECO \
    --expected-head <sha> [options]

Options:
  --source-pnr-run-id <id>    Accepted free-placement PnR run.
  --source-pvs-run-id <id>    Its attributable NON_ANTENNA_DRC PVS run.
  --run-id <id>               New immutable Innovus ECO result directory.
  --commands-file <path>      Tracked file containing exactly one allowed
                              selected-net route helper command.
  --expected-commands-sha     Exact SHA256 of the reviewed command file.
  --authorization <token>     Exact token shown above.
  --expected-head <sha>       Required SPADMIC_test commit.
  --innovus-work <path>       Innovus/PVS result root.
  --cadence-env <path>        Cadence environment script.
  -h, --help                  Show this help.

The driver appends geometry/connectivity assertion and TC extraction/STA
commands. It does not permit placement, cell, floorplan, PG, CTS, timing
constraint, or arbitrary Tcl commands. A second PVS ECO is never accepted.
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

evidence_hash() {
  local file
  for file in "$@"; do
    [[ -s "$file" ]] || return 1
  done
  {
    for file in "$@"; do
      printf '%s\t' "$file"
      sha256sum "$file"
    done
  } | sha256sum | awk '{print $1}'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-pnr-run-id) SOURCE_PNR_RUN_ID="${2:?missing value}"; shift 2 ;;
    --source-pvs-run-id) SOURCE_PVS_RUN_ID="${2:?missing value}"; shift 2 ;;
    --run-id) RUN_ID="${2:?missing value}"; shift 2 ;;
    --commands-file) COMMANDS_FILE="${2:?missing value}"; shift 2 ;;
    --expected-commands-sha) EXPECTED_COMMANDS_SHA256="${2:?missing value}"; shift 2 ;;
    --authorization) AUTHORIZATION="${2:?missing value}"; shift 2 ;;
    --expected-head) EXPECTED_HEAD_VALUE="${2:?missing value}"; shift 2 ;;
    --innovus-work) INNOVUS_WORK="${2:?missing value}"; shift 2 ;;
    --cadence-env) CADENCE_ENV="${2:?missing value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$SOURCE_PNR_RUN_ID" ]] || { echo "ERROR: --source-pnr-run-id is required" >&2; exit 2; }
[[ -n "$SOURCE_PVS_RUN_ID" ]] || { echo "ERROR: --source-pvs-run-id is required" >&2; exit 2; }
[[ -n "$RUN_ID" ]] || { echo "ERROR: --run-id is required" >&2; exit 2; }
[[ -n "$COMMANDS_FILE" ]] || { echo "ERROR: --commands-file is required" >&2; exit 2; }
[[ -n "$EXPECTED_COMMANDS_SHA256" ]] || { echo "ERROR: --expected-commands-sha is required" >&2; exit 2; }
[[ -n "$EXPECTED_HEAD_VALUE" ]] || { echo "ERROR: --expected-head is required" >&2; exit 2; }
[[ "$AUTHORIZATION" == EXACT_MPTDC_FREE_TRIAL_ONE_PVS_ROUTING_ECO ]] || {
  echo "ERROR: exact routing ECO authorization is required" >&2
  exit 2
}

cd "$REPO_ROOT" || exit 2
CURRENT_HEAD="$(git rev-parse HEAD 2>/dev/null)"
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
TRACKED_STATUS="$(git status --short --untracked-files=no 2>/dev/null)"

if [[ -f "$COMMANDS_FILE" ]]; then
  COMMANDS_FILE="$(readlink -f "$COMMANDS_FILE" 2>/dev/null)"
fi
COMMANDS_REL=MISSING
COMMANDS_TRACKED_STATUS=FAIL
case "$COMMANDS_FILE" in
  "$REPO_ROOT"/*)
    COMMANDS_REL="${COMMANDS_FILE#"$REPO_ROOT"/}"
    if git ls-files --error-unmatch "$COMMANDS_REL" >/dev/null 2>&1; then
      COMMANDS_TRACKED_STATUS=PASS
    fi
    ;;
esac

SOURCE_PNR_DIR="$INNOVUS_WORK/$SOURCE_PNR_RUN_ID"
SOURCE_PVS_DIR="$INNOVUS_WORK/$SOURCE_PVS_RUN_ID"
SOURCE_PNR_GATE="$SOURCE_PNR_DIR/reports/operator_gate_mptdc_free_placement_attempt.rpt"
SOURCE_PVS_GATE="$SOURCE_PVS_DIR/reports/operator_gate_mptdc_free_trial_pvs.rpt"
SOURCE_CLASSIFICATION="$SOURCE_PVS_DIR/reports/pvs_free_trial_drc_classification.rpt"
SOURCE_BASE_STATUS="$SOURCE_PVS_DIR/reports/pvs_drc_base_status.rpt"
SOURCE_BASE_RULES="$SOURCE_PVS_DIR/reports/pvs_drc_base_nonzero_rules.tsv"
SOURCE_BASE_SCAN="$SOURCE_PVS_DIR/reports/pvs_drc_base_result_scan.txt"
SOURCE_FILLER_REPORT="$SOURCE_PNR_DIR/reports/filler_status.rpt"
SOURCE_ROW_REPORT="$SOURCE_PNR_DIR/reports/row_infra_insertion.rpt"
SOURCE_CHECKPOINT="$(report_value "$SOURCE_PNR_GATE" SOURCE_CHECKPOINT)"
EXPECTED_SOURCE_CHECKPOINT_SHA256="$(report_value "$SOURCE_PNR_GATE" SOURCE_CHECKPOINT_SHA256)"
PVS_SOURCE_CHECKPOINT="$(report_value "$SOURCE_PVS_GATE" SOURCE_CHECKPOINT)"
RESULT_DIR="$INNOVUS_WORK/$RUN_ID"
REPORT_DIR="$RESULT_DIR/reports"
MANIFEST_DIR="$RESULT_DIR/manifests"
DRIVER_LOG="/tmp/${RUN_ID}.driver.log"

SOURCE_CHECKPOINT_SHA256_PRE="$(tree_hash "$SOURCE_CHECKPOINT" 2>/dev/null)"
SOURCE_PNR_EVIDENCE_SHA256_PRE="$(evidence_hash "$SOURCE_PNR_GATE" "$SOURCE_FILLER_REPORT" "$SOURCE_ROW_REPORT" 2>/dev/null)"
SOURCE_PVS_EVIDENCE_SHA256_PRE="$(evidence_hash "$SOURCE_PVS_GATE" "$SOURCE_CLASSIFICATION" "$SOURCE_BASE_STATUS" "$SOURCE_BASE_RULES" "$SOURCE_BASE_SCAN" 2>/dev/null)"

PREFLIGHT_STATUS=FAIL
if [[ "$CURRENT_HEAD" == "$EXPECTED_HEAD_VALUE" &&
      "$CURRENT_BRANCH" == SPADMIC_test &&
      -z "$TRACKED_STATUS" &&
      "$COMMANDS_TRACKED_STATUS" == PASS &&
      "$EXPECTED_COMMANDS_SHA256" =~ ^[0-9a-f]{64}$ &&
      "$(report_value "$SOURCE_PNR_GATE" MPTDC_FREE_PLACEMENT_ATTEMPT_STATUS)" == PASS &&
      "$(report_value "$SOURCE_PNR_GATE" MPTDC_TC_PNR_CLOSURE)" == PASS &&
      "$(report_value "$SOURCE_PNR_GATE" TIE1_INSERTION_STATUS)" == PASS &&
      "$(report_value "$SOURCE_PVS_GATE" PNR_RUN_ID)" == "$SOURCE_PNR_RUN_ID" &&
      "$(report_value "$SOURCE_PVS_GATE" BASE_DRC_CLASS)" == NON_ANTENNA_DRC &&
      "$(report_value "$SOURCE_PVS_GATE" PVS_ECO_ATTEMPT_COUNT)" == 0 &&
      "$(report_value "$SOURCE_PVS_GATE" SOURCE_INPUT_READ_ONLY_STATUS)" == PASS &&
      "$(report_value "$SOURCE_PVS_GATE" CHECKPOINT_SHA256_PRE)" == "$EXPECTED_SOURCE_CHECKPOINT_SHA256" &&
      "$(report_value "$SOURCE_PVS_GATE" CHECKPOINT_SHA256_POST)" == "$EXPECTED_SOURCE_CHECKPOINT_SHA256" &&
      "$(report_value "$SOURCE_PVS_GATE" DECISION)" == FAIL_STOP_ONE_ATTRIBUTED_ROUTING_ECO_ELIGIBLE &&
      "$(report_value "$SOURCE_CLASSIFICATION" CLASSIFICATION_STATUS)" == PASS &&
      "$(report_value "$SOURCE_CLASSIFICATION" PVS_BASE_DRC_CLASS)" == NON_ANTENNA_DRC &&
      "$(report_value "$SOURCE_CLASSIFICATION" NON_ANTENNA_RULE_COUNT)" =~ ^[1-9][0-9]*$ &&
      "$PVS_SOURCE_CHECKPOINT" == "$SOURCE_CHECKPOINT" &&
      -d "$SOURCE_CHECKPOINT" &&
      "$SOURCE_CHECKPOINT_SHA256_PRE" == "$EXPECTED_SOURCE_CHECKPOINT_SHA256" &&
      -n "$SOURCE_PNR_EVIDENCE_SHA256_PRE" &&
      -n "$SOURCE_PVS_EVIDENCE_SHA256_PRE" &&
      -x "$REPAIR_DRIVER" &&
      -x "$VALIDATOR" &&
      -f "$CADENCE_ENV" &&
      ! -e "$RESULT_DIR" ]]; then
  PREFLIGHT_STATUS=PASS
fi

if [[ "$PREFLIGHT_STATUS" != PASS ]]; then
  echo "STOP: one-PVS-ECO preflight failed; no Innovus process launched"
  echo "CURRENT_HEAD=$CURRENT_HEAD"
  echo "CURRENT_BRANCH=$CURRENT_BRANCH"
  echo "TRACKED_STATUS=${TRACKED_STATUS:-CLEAN}"
  echo "COMMANDS_FILE=$COMMANDS_FILE"
  echo "COMMANDS_TRACKED_STATUS=$COMMANDS_TRACKED_STATUS"
  echo "SOURCE_CHECKPOINT=$SOURCE_CHECKPOINT"
  echo "SOURCE_CHECKPOINT_SHA256_PRE=${SOURCE_CHECKPOINT_SHA256_PRE:-MISSING}"
  echo "EXPECTED_SOURCE_CHECKPOINT_SHA256=${EXPECTED_SOURCE_CHECKPOINT_SHA256:-MISSING}"
  exit 3
fi

mkdir -p "$REPORT_DIR" "$MANIFEST_DIR"
NORMALIZED_COMMANDS="$MANIFEST_DIR/reviewed_route_command.normalized.tcl"
EFFECTIVE_COMMANDS="$MANIFEST_DIR/reviewed_route_command.with_gates.tcl"
COMMAND_REPORT="$REPORT_DIR/pvs_eco_command_contract.rpt"

set +e
python3 "$VALIDATOR" \
  --commands-file "$COMMANDS_FILE" \
  --expected-sha256 "$EXPECTED_COMMANDS_SHA256" \
  --normalized-out "$NORMALIZED_COMMANDS" \
  --report "$COMMAND_REPORT" \
  2>&1 | tee "$DRIVER_LOG"
COMMAND_VALIDATION_RC=${PIPESTATUS[0]}
set +e

if [[ "$COMMAND_VALIDATION_RC" -ne 0 ]]; then
  echo "STOP: reviewed routing ECO command contract failed"
  exit 4
fi

cp -p "$NORMALIZED_COMMANDS" "$EFFECTIVE_COMMANDS"
printf '%s\n' \
  'mptdc_ckpt_assert_geometry_regular_clean' \
  'mptdc_signoff_extract_and_sta' >> "$EFFECTIVE_COMMANDS"

set +u
# shellcheck disable=SC1090
source "$CADENCE_ENV"
CADENCE_ENV_RC=$?
set -u
if [[ "$CADENCE_ENV_RC" -ne 0 ]]; then
  echo "STOP: Cadence environment failed with rc=$CADENCE_ENV_RC"
  exit 5
fi

export MPTDC_CHECKPOINT_REPAIR_KEEP_GOING=0
set +e
bash "$REPAIR_DRIVER" \
  --run-id "$RUN_ID" \
  --checkpoint "$SOURCE_CHECKPOINT" \
  --commands-file "$EFFECTIVE_COMMANDS" \
  --expected-head "$EXPECTED_HEAD_VALUE" \
  --innovus-work "$INNOVUS_WORK" \
  2>&1 | tee -a "$DRIVER_LOG"
REPAIR_DRIVER_RC=${PIPESTATUS[0]}
set +e

REPAIR_STATUS_REPORT="$REPORT_DIR/checkpoint_repair_status.rpt"
TIMING_REPORT="$REPORT_DIR/extracted_timing_status.rpt"
DRV_REPORT="$REPORT_DIR/drv_status.rpt"
FINAL_CHECKPOINT="$(report_value "$REPAIR_STATUS_REPORT" FINAL_CHECKPOINT_DAT)"
FINAL_CHECKPOINT_SHA256=MISSING
if [[ -d "$FINAL_CHECKPOINT" ]]; then
  FINAL_CHECKPOINT_SHA256="$(tree_hash "$FINAL_CHECKPOINT")"
fi

FILLER_COPY_RC=99
ROW_COPY_RC=99
if [[ -d "$RESULT_DIR" ]]; then
  cp -p "$SOURCE_FILLER_REPORT" "$REPORT_DIR/filler_status.rpt"
  FILLER_COPY_RC=$?
  cp -p "$SOURCE_ROW_REPORT" "$REPORT_DIR/row_infra_insertion.rpt"
  ROW_COPY_RC=$?
  for report in tie1_insertion_status.rpt tie1_routed_status.rpt tie1_inserted_net_inventory.tsv; do
    if [[ -s "$SOURCE_PNR_DIR/reports/$report" ]]; then
      cp -p "$SOURCE_PNR_DIR/reports/$report" "$REPORT_DIR/$report"
    fi
  done
fi

SOURCE_CHECKPOINT_SHA256_POST="$(tree_hash "$SOURCE_CHECKPOINT" 2>/dev/null)"
SOURCE_PNR_EVIDENCE_SHA256_POST="$(evidence_hash "$SOURCE_PNR_GATE" "$SOURCE_FILLER_REPORT" "$SOURCE_ROW_REPORT" 2>/dev/null)"
SOURCE_PVS_EVIDENCE_SHA256_POST="$(evidence_hash "$SOURCE_PVS_GATE" "$SOURCE_CLASSIFICATION" "$SOURCE_BASE_STATUS" "$SOURCE_BASE_RULES" "$SOURCE_BASE_SCAN" 2>/dev/null)"
SOURCE_READ_ONLY_STATUS=FAIL
if [[ "$SOURCE_CHECKPOINT_SHA256_PRE" == "$SOURCE_CHECKPOINT_SHA256_POST" &&
      "$SOURCE_PNR_EVIDENCE_SHA256_PRE" == "$SOURCE_PNR_EVIDENCE_SHA256_POST" &&
      "$SOURCE_PVS_EVIDENCE_SHA256_PRE" == "$SOURCE_PVS_EVIDENCE_SHA256_POST" ]]; then
  SOURCE_READ_ONLY_STATUS=PASS
fi

ECO_STATUS=FAIL
DECISION=FAIL_STOP
NEXT_STAGE=STOP_AND_REVIEW
if [[ "$REPAIR_DRIVER_RC" -eq 0 &&
      "$(report_value "$REPAIR_STATUS_REPORT" CHECKPOINT_REPAIR_STATUS)" == PASS_ROUTE_GATE &&
      "$(report_value "$REPAIR_STATUS_REPORT" FINAL_ROUTE_GATE_PASS)" == 1 &&
      "$(report_value "$REPAIR_STATUS_REPORT" FINAL_DRC)" == 0 &&
      "$(report_value "$REPAIR_STATUS_REPORT" FINAL_SHORTS)" == 0 &&
      "$(report_value "$REPAIR_STATUS_REPORT" FINAL_REGULAR_CONNECTIVITY_BAD)" == 0 &&
      "$(report_value "$REPAIR_STATUS_REPORT" FINAL_SPECIAL_CONNECTIVITY_BAD)" == 0 &&
      "$(report_value "$REPAIR_STATUS_REPORT" FINAL_UNROUTED_NETS)" == 0 &&
      "$(report_value "$TIMING_REPORT" SETUP_STATUS_TC)" == PASS &&
      "$(report_value "$TIMING_REPORT" TC_HOLD_STATUS)" == PASS &&
      "$(report_value "$DRV_REPORT" DRV_STATUS)" == PASS &&
      "$FILLER_COPY_RC" -eq 0 && "$ROW_COPY_RC" -eq 0 &&
      "$SOURCE_READ_ONLY_STATUS" == PASS &&
      -d "$FINAL_CHECKPOINT" && "$FINAL_CHECKPOINT_SHA256" != MISSING ]]; then
  ECO_STATUS=PASS
  DECISION=PASS_CONTINUE
  NEXT_STAGE=RERUN_BASE_DRC_AND_FULL_LVS_ON_ECO_CHECKPOINT
fi

GATE="$REPORT_DIR/operator_gate_mptdc_free_trial_pvs_eco.rpt"
{
  echo "STEP=MPTDC_FREE_TRIAL_ONE_PVS_ROUTING_ECO"
  echo "SOURCE_PNR_RUN_ID=$SOURCE_PNR_RUN_ID"
  echo "SOURCE_PVS_RUN_ID=$SOURCE_PVS_RUN_ID"
  echo "ECO_RUN_ID=$RUN_ID"
  echo "AUTHORIZATION=$AUTHORIZATION"
  echo "PVS_ECO_ATTEMPT_COUNT=1"
  echo "PVS_ECO_MAX_ATTEMPTS=1"
  echo "COMMANDS_FILE=$COMMANDS_FILE"
  echo "COMMANDS_FILE_REL=$COMMANDS_REL"
  echo "COMMANDS_FILE_SHA256=$EXPECTED_COMMANDS_SHA256"
  echo "COMMANDS_TRACKED_STATUS=$COMMANDS_TRACKED_STATUS"
  echo "COMMAND_CONTRACT_STATUS=$(report_value "$COMMAND_REPORT" COMMAND_CONTRACT_STATUS)"
  echo "TARGET_NET_COUNT=$(report_value "$COMMAND_REPORT" TARGET_NET_COUNT)"
  echo "TARGET_NET_SET=$(report_value "$COMMAND_REPORT" TARGET_NET_SET)"
  echo "SOURCE_CHECKPOINT_ORIGINAL=$SOURCE_CHECKPOINT"
  echo "SOURCE_CHECKPOINT_ORIGINAL_SHA256=$SOURCE_CHECKPOINT_SHA256_PRE"
  echo "SOURCE_CHECKPOINT=$FINAL_CHECKPOINT"
  echo "SOURCE_CHECKPOINT_SHA256=$FINAL_CHECKPOINT_SHA256"
  echo "REPAIR_DRIVER_RC=$REPAIR_DRIVER_RC"
  echo "CHECKPOINT_REPAIR_STATUS=$(report_value "$REPAIR_STATUS_REPORT" CHECKPOINT_REPAIR_STATUS)"
  echo "FINAL_ROUTE_GATE_PASS=$(report_value "$REPAIR_STATUS_REPORT" FINAL_ROUTE_GATE_PASS)"
  echo "FINAL_DRC=$(report_value "$REPAIR_STATUS_REPORT" FINAL_DRC)"
  echo "FINAL_SHORTS=$(report_value "$REPAIR_STATUS_REPORT" FINAL_SHORTS)"
  echo "FINAL_REGULAR_CONNECTIVITY_BAD=$(report_value "$REPAIR_STATUS_REPORT" FINAL_REGULAR_CONNECTIVITY_BAD)"
  echo "FINAL_SPECIAL_CONNECTIVITY_BAD=$(report_value "$REPAIR_STATUS_REPORT" FINAL_SPECIAL_CONNECTIVITY_BAD)"
  echo "FINAL_UNROUTED_NETS=$(report_value "$REPAIR_STATUS_REPORT" FINAL_UNROUTED_NETS)"
  echo "SETUP_STATUS_TC=$(report_value "$TIMING_REPORT" SETUP_STATUS_TC)"
  echo "TC_HOLD_STATUS=$(report_value "$TIMING_REPORT" TC_HOLD_STATUS)"
  echo "DRV_STATUS=$(report_value "$DRV_REPORT" DRV_STATUS)"
  echo "MPTDC_TC_PNR_CLOSURE=$([[ "$ECO_STATUS" == PASS ]] && echo PASS || echo FAIL)"
  echo "TIE1_INSERTION_STATUS=$(report_value "$SOURCE_PNR_GATE" TIE1_INSERTION_STATUS)"
  echo "TIE1_REVALIDATION_STATUS=INHERITED_UNDER_EXACT_ROUTE_ONLY_COMMAND_CONTRACT"
  echo "SOURCE_CHECKPOINT_READ_ONLY_STATUS=$SOURCE_READ_ONLY_STATUS"
  echo "SOURCE_PNR_EVIDENCE_SHA256_PRE=$SOURCE_PNR_EVIDENCE_SHA256_PRE"
  echo "SOURCE_PNR_EVIDENCE_SHA256_POST=$SOURCE_PNR_EVIDENCE_SHA256_POST"
  echo "SOURCE_PVS_EVIDENCE_SHA256_PRE=$SOURCE_PVS_EVIDENCE_SHA256_PRE"
  echo "SOURCE_PVS_EVIDENCE_SHA256_POST=$SOURCE_PVS_EVIDENCE_SHA256_POST"
  echo "FILLER_COPY_RC=$FILLER_COPY_RC"
  echo "ROW_COPY_RC=$ROW_COPY_RC"
  echo "MPTDC_FREE_TRIAL_PVS_ECO_STATUS=$ECO_STATUS"
  echo "SIGNOFF_ELIGIBLE=NO"
  echo "DECISION=$DECISION"
  echo "NEXT_STAGE=$NEXT_STAGE"
} | tee "$GATE"

[[ "$ECO_STATUS" == PASS ]]
