#!/usr/bin/env bash
# Run one disposable, hash-guarded tie-high insertion candidate from Step 6R.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
REPO_ROOT="${MPTDC_TIE1_TRIAL_REPO_ROOT:-$DEFAULT_REPO_ROOT}"
PUBLISHER="${MPTDC_TIE1_TRIAL_PUBLISHER:-$REPO_ROOT/MPTDC/ci/publish_mptdc_server_snapshot.sh}"
TRIAL_TCL="${MPTDC_TIE1_TRIAL_TCL:-$SCRIPT_DIR/innovus_mptdc_tie1_insertion_trial.tcl}"
INNOVUS_BIN="${MPTDC_TIE1_TRIAL_INNOVUS_BIN:-innovus}"
INNOVUS_WORK="${MPTDC_INNOVUS_WORK:-/sim/ksabra/SPADMIC_work/innovus}"
CADENCE_ENV="${MPTDC_CADENCE_ENV:-/eda/cadence/eda_2023-2024}"

PROBE_RUN_ID=""
RUN_ID=""
AUTHORIZATION=""
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD:-}"
MAX_FANOUT=8
MAX_DISTANCE=20
EXPECTED_HIGH_TERMS=91
EXPECTED_LOW_TERMS=0
EXPECTED_FILLERS=24797
EXPECTED_DRC=1
HIGH_MASTER=LOGIC1DJIHD
LOW_MASTER=LOGIC0DJIHD
FILLER_MASTERS="FEED25JIHD FEED15JIHD FEED10JIHD FEED7JIHD FEED5JIHD FEED3JIHD FEED2JIHD FEED1JIHD"
TIE_HIGH_CANDIDATES="LOGIC1DJIHD LOGIC1LVJIHD"
TIE_LOW_CANDIDATES="LOGIC0DJIHD LOGIC0LVJIHD"

usage() {
  cat <<'USAGE'
Usage:
  server_run_mptdc_tie1_insertion_trial.sh --probe-run-id <id> \
    --authorization EXACT_MPTDC_TIE1_HIGH_TRIAL [options]

Options:
  --probe-run-id <id>       Published Step 6R read-only tie1 probe.
  --authorization <token>   Must be EXACT_MPTDC_TIE1_HIGH_TRIAL.
  --run-id <id>             New disposable Innovus trial run id.
  --expected-head <sha>     Require repository HEAD to match this commit.
  --innovus-work <path>     Innovus/PVS result root.
  -h, --help                Show this help.

The trial restores a private copy of the immutable checkpoint, uses only the
normal-Vt LOGIC1DJIHD/LOGIC0DJIHD pair, bounds fanout to 8 and distance to
20 um, and routes only the newly created tie nets. It saves a candidate
checkpoint only when all 91 high sinks are connected and placement, base DRC,
short, regular-connectivity, and existing special-connectivity debt do not
worsen. The result is diagnostic and never signoff eligible.
USAGE
}

report_value() {
  local report="$1"
  local key="$2"
  local value
  value="$(sed -n "s/^${key}=//p" "$report" 2>/dev/null | tail -1)"
  if [[ -n "$value" ]]; then printf '%s\n' "$value"; else printf 'MISSING\n'; fi
}

file_sha256() {
  sha256sum "$1" 2>/dev/null | awk '{print $1}'
}

tree_content_hash() {
  local root="$1"
  if [[ -d "$root" ]]; then
    (
      cd "$root" 2>/dev/null || return 1
      find -L . -type f \
        ! -name '*.cdslck' ! -name '*.lock' ! -name '.*lock*' \
        -print0 2>/dev/null |
        LC_ALL=C sort -z |
        while IFS= read -r -d '' file; do
          printf '%s\t' "$file"
          sha256sum "$file"
        done
    ) | sha256sum | awk '{print $1}'
  elif [[ -f "$root" ]]; then
    file_sha256 "$root"
  else
    printf 'MISSING\n'
  fi
}

load_cadence_env() {
  local env_file="$1"

  echo "CADENCE_ENV=$env_file"
  if [[ ! -r "$env_file" ]]; then
    CADENCE_ENV_RC=1
    CADENCE_ENV_STATUS=FAIL_NOT_READABLE
    echo "CADENCE_ENV_RC=$CADENCE_ENV_RC"
    echo "CADENCE_ENV_STATUS=$CADENCE_ENV_STATUS"
    return 1
  fi

  set +u
  set +e
  # shellcheck disable=SC1090
  source "$env_file" >/dev/null 2>&1
  CADENCE_ENV_RC=$?
  set +e
  set -u
  set -o pipefail

  if [[ "$CADENCE_ENV_RC" -eq 0 ]]; then
    CADENCE_ENV_STATUS=PASS
  else
    CADENCE_ENV_STATUS=FAIL
  fi
  echo "CADENCE_ENV_RC=$CADENCE_ENV_RC"
  echo "CADENCE_ENV_STATUS=$CADENCE_ENV_STATUS"
  [[ "$CADENCE_ENV_STATUS" == PASS ]]
}

require_report_value() {
  local report="$1"
  local key="$2"
  local expected="$3"
  local actual
  actual="$(report_value "$report" "$key")"
  if [[ "$actual" != "$expected" ]]; then
    echo "STOP: $key expected '$expected', got '$actual' in $report"
    PREFLIGHT=FAIL
  fi
}

publish_stage() {
  MPTDC_SNAPSHOT_MAX_TEXT_BYTES=8388608 \
    bash "$PUBLISHER" innovus "$RUN_ID" "$RUN_DIR" TIE1_INSERTION_TRIAL
  local rc=$?
  EXPECTED_HEAD_VALUE="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null)"
  return "$rc"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --probe-run-id) PROBE_RUN_ID="${2:?missing --probe-run-id value}"; shift 2 ;;
    --authorization) AUTHORIZATION="${2:?missing --authorization value}"; shift 2 ;;
    --run-id) RUN_ID="${2:?missing --run-id value}"; shift 2 ;;
    --expected-head) EXPECTED_HEAD_VALUE="${2:?missing --expected-head value}"; shift 2 ;;
    --innovus-work) INNOVUS_WORK="${2:?missing --innovus-work value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$PROBE_RUN_ID" ]] || { echo "ERROR: --probe-run-id is required" >&2; usage >&2; exit 2; }
[[ "$PROBE_RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "ERROR: unsafe probe run id" >&2; exit 2; }
[[ "$AUTHORIZATION" == EXACT_MPTDC_TIE1_HIGH_TRIAL ]] || {
  echo "ERROR: exact private-copy trial authorization is required" >&2
  exit 2
}
if [[ -z "$RUN_ID" ]]; then
  RUN_ID="$(date +%Y%m%d)_mptdc_tie1_insertion_trial_$(date +%H%M%S)"
fi
[[ "$RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "ERROR: unsafe trial run id" >&2; exit 2; }

PROBE_DIR="$INNOVUS_WORK/$PROBE_RUN_ID"
TRACKED_PROBE_DIR="$REPO_ROOT/MPTDC/docs/server_snapshots/innovus/$PROBE_RUN_ID"
PROBE_GATE="$PROBE_DIR/reports/operator_gate_tie1_checkpoint_probe.rpt"
PROBE_STATUS_REPORT="$PROBE_DIR/reports/tie1_checkpoint_probe_status.rpt"
PROBE_MASTER_REPORT="$PROBE_DIR/reports/tie1_candidate_master_inventory.tsv"
PROBE_FLAGGED_REPORT="$PROBE_DIR/reports/tie_flagged_term_inventory.tsv"
PROBE_COMMAND_REPORT="$PROBE_DIR/reports/tie_command_availability.rpt"
PROBE_MANIFEST="$PROBE_DIR/manifests/tie1_checkpoint_probe_inputs.rpt"
PROBE_SOURCE_CONTRACT="$PROBE_DIR/manifests/source_physical_lvs_contract.rpt"
RUN_DIR="$INNOVUS_WORK/$RUN_ID"

cd "$REPO_ROOT" || exit 3
ACTUAL_HEAD="$(git rev-parse HEAD 2>/dev/null)"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
ORIGIN_HEAD="$(git rev-parse --verify refs/remotes/origin/SPADMIC_test 2>/dev/null || true)"
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD_VALUE:-${ORIGIN_HEAD:-$ACTUAL_HEAD}}"
TRACKED_STATUS="$(git status --short --untracked-files=no 2>/dev/null)"

SOURCE_CHECKPOINT="$(report_value "$PROBE_GATE" SOURCE_CHECKPOINT)"
SOURCE_CHECKPOINT_EXPECTED_SHA="$(report_value "$PROBE_MANIFEST" SOURCE_CHECKPOINT_SHA256_PRE)"
BOUNDARY_PVS_RUN_ID="$(report_value "$PROBE_GATE" BOUNDARY_PVS_RUN_ID)"
SOURCE_PVS_RUN_ID="$(report_value "$PROBE_GATE" SOURCE_PVS_RUN_ID)"
SOURCE_PNR_RUN_ID="$(basename "$(dirname "$(dirname "$SOURCE_CHECKPOINT")")")"
SOURCE_FILLER_REPORTED="$(report_value "$PROBE_SOURCE_CONTRACT" FILLER_REPORT)"
SOURCE_FILLER_EXPECTED_SHA="$(report_value "$PROBE_SOURCE_CONTRACT" FILLER_REPORT_SHA256)"
SOURCE_ROW_REPORTED="$(report_value "$PROBE_SOURCE_CONTRACT" ROW_INFRA_REPORT)"
SOURCE_ROW_EXPECTED_SHA="$(report_value "$PROBE_SOURCE_CONTRACT" ROW_INFRA_REPORT_SHA256)"
SOURCE_FILLER_REPO_REL="${SOURCE_FILLER_REPORTED#*/MPTDC/}"
SOURCE_ROW_REPO_REL="${SOURCE_ROW_REPORTED#*/MPTDC/}"
SOURCE_FILLER_TRACKED="$REPO_ROOT/MPTDC/$SOURCE_FILLER_REPO_REL"
SOURCE_ROW_TRACKED="$REPO_ROOT/MPTDC/$SOURCE_ROW_REPO_REL"

echo "PROBE_RUN_ID=$PROBE_RUN_ID"
echo "PROBE_DIR=$PROBE_DIR"
echo "BOUNDARY_PVS_RUN_ID=$BOUNDARY_PVS_RUN_ID"
echo "SOURCE_PVS_RUN_ID=$SOURCE_PVS_RUN_ID"
echo "SOURCE_PNR_RUN_ID=$SOURCE_PNR_RUN_ID"
echo "SOURCE_CHECKPOINT=$SOURCE_CHECKPOINT"
echo "RUN_ID=$RUN_ID"
echo "RUN_DIR=$RUN_DIR"
echo "BRANCH=$BRANCH"
echo "ACTUAL_HEAD=$ACTUAL_HEAD"
echo "ORIGIN_HEAD=${ORIGIN_HEAD:-MISSING}"
echo "EXPECTED_HEAD=$EXPECTED_HEAD_VALUE"
echo "AUTHORIZATION=$AUTHORIZATION"

PREFLIGHT=PASS
[[ "$BRANCH" == SPADMIC_test ]] || { echo "STOP: branch must be SPADMIC_test"; PREFLIGHT=FAIL; }
[[ "$ACTUAL_HEAD" == "$EXPECTED_HEAD_VALUE" ]] || { echo "STOP: HEAD mismatch"; PREFLIGHT=FAIL; }
if [[ -n "$ORIGIN_HEAD" && "$ACTUAL_HEAD" != "$ORIGIN_HEAD" ]]; then
  echo "STOP: local HEAD does not match origin/SPADMIC_test"
  PREFLIGHT=FAIL
fi
[[ -z "$TRACKED_STATUS" ]] || { echo "$TRACKED_STATUS"; echo "STOP: tracked working tree is dirty"; PREFLIGHT=FAIL; }
[[ ! -e "$RUN_DIR" ]] || { echo "STOP: result directory already exists: $RUN_DIR"; PREFLIGHT=FAIL; }
[[ -s "$TRIAL_TCL" && -s "$PUBLISHER" ]] || { echo "STOP: trial Tcl or publisher missing"; PREFLIGHT=FAIL; }

for rel in \
  reports/operator_gate_tie1_checkpoint_probe.rpt \
  reports/tie1_checkpoint_probe_status.rpt \
  reports/tie1_candidate_master_inventory.tsv \
  reports/tie_flagged_term_inventory.tsv \
  reports/tie_command_availability.rpt \
  manifests/tie1_checkpoint_probe_inputs.rpt \
  manifests/source_physical_lvs_contract.rpt; do
  live="$PROBE_DIR/$rel"
  tracked="$TRACKED_PROBE_DIR/$rel"
  if [[ ! -s "$live" || ! -s "$tracked" ]]; then
    echo "STOP: live or tracked Step 6R artifact missing: $rel"
    PREFLIGHT=FAIL
  elif ! cmp -s "$live" "$tracked"; then
    echo "STOP: live Step 6R artifact differs from published evidence: $rel"
    PREFLIGHT=FAIL
  fi
done

require_report_value "$PROBE_GATE" STEP TIE1_CHECKPOINT_PROBE
require_report_value "$PROBE_GATE" CADENCE_ENV_STATUS PASS
require_report_value "$PROBE_GATE" INNOVUS_RC 0
require_report_value "$PROBE_GATE" PROBE_STATUS PASS
require_report_value "$PROBE_GATE" RESTORE_STATUS PASS
require_report_value "$PROBE_GATE" CORE_QUERY_STATUS PASS
require_report_value "$PROBE_GATE" CORE_QUERY_ERROR_COUNT 0
require_report_value "$PROBE_GATE" TIE1_SOURCE_TOKEN_COUNT 0
require_report_value "$PROBE_GATE" TIE_MASTER_SOURCE_TOKEN_COUNT 0
require_report_value "$PROBE_GATE" TIE1_NET_COUNT 0
require_report_value "$PROBE_GATE" TIE1_INST_TERM_COUNT 0
require_report_value "$PROBE_GATE" TIE1_REGULAR_WIRE_COUNT 0
require_report_value "$PROBE_GATE" TIE1_SPECIAL_WIRE_COUNT 0
require_report_value "$PROBE_GATE" TIE1_VIA_COUNT 0
require_report_value "$PROBE_GATE" TIE_AVAILABLE_MASTER_COUNT 4
require_report_value "$PROBE_GATE" PHYSICAL_TIE_MASTER_COUNT 0
require_report_value "$PROBE_GATE" PHYSICAL_TIE_INSTANCE_COUNT 0
require_report_value "$PROBE_GATE" FLAGGED_TIE_HIGH_TERM_COUNT 91
require_report_value "$PROBE_GATE" FLAGGED_TIE_LOW_TERM_COUNT 0
require_report_value "$PROBE_GATE" SOURCE_CHECKPOINT_HASH_STATUS PASS
require_report_value "$PROBE_GATE" SAFE_COPY_MATCH_STATUS PASS
require_report_value "$PROBE_GATE" SAFE_CHECKPOINT_HASH_STATUS PASS
require_report_value "$PROBE_GATE" BOUNDARY_EVIDENCE_HASH_STATUS PASS
require_report_value "$PROBE_GATE" PHYSICAL_SOURCE_HASH_STATUS PASS
require_report_value "$PROBE_GATE" DESIGN_MUTATION_COUNT 0
require_report_value "$PROBE_GATE" READ_ONLY_STATUS PASS
require_report_value "$PROBE_GATE" SIGNOFF_ELIGIBLE NO
require_report_value "$PROBE_GATE" DECISION PASS_REVIEW_TIE1_EVIDENCE
require_report_value "$PROBE_GATE" NEXT_STAGE REVIEW_TIE1_EVIDENCE_BEFORE_HASH_GUARDED_TRIAL

FLAGGED_ROW_COUNT="$(awk -F '\t' 'NR > 1 {n++} END {print n+0}' "$PROBE_FLAGGED_REPORT" 2>/dev/null)"
FLAGGED_BAD_ROW_COUNT="$(awk -F '\t' 'NR > 1 && ($1 != "HIGH" || $6 != "0x0") {n++} END {print n+0}' "$PROBE_FLAGGED_REPORT" 2>/dev/null)"
[[ "$FLAGGED_ROW_COUNT" == 91 && "$FLAGGED_BAD_ROW_COUNT" == 0 ]] || {
  echo "STOP: Step 6R flagged-terminal table is not exactly 91 disconnected high sinks"
  PREFLIGHT=FAIL
}

for row in \
  $'LOGIC1DJIHD\tHIGH\t1\t0\tPASS\tPASS' \
  $'LOGIC1LVJIHD\tHIGH\t1\t0\tPASS\tPASS' \
  $'LOGIC0DJIHD\tLOW\t1\t0\tPASS\tPASS' \
  $'LOGIC0LVJIHD\tLOW\t1\t0\tPASS\tPASS'; do
  grep -Fqx "$row" "$PROBE_MASTER_REPORT" || {
    echo "STOP: reviewed tie-master inventory row missing: $row"
    PREFLIGHT=FAIL
  }
done
[[ "$(awk 'END {print NR+0}' "$PROBE_MASTER_REPORT" 2>/dev/null)" == 5 ]] || {
  echo "STOP: unexpected extra rows in tie-master inventory"
  PREFLIGHT=FAIL
}
require_report_value "$PROBE_COMMAND_REPORT" addTieHiLo_STATUS AVAILABLE
require_report_value "$PROBE_COMMAND_REPORT" setTieHiLoMode_STATUS AVAILABLE
require_report_value "$PROBE_SOURCE_CONTRACT" LVS_SOURCE_CONTRACT_STATUS PASS
require_report_value "$PROBE_SOURCE_CONTRACT" PHYSICAL_ONLY_INSTANCE_REMOVAL_POLICY EXACT_TRACKED_FILLER_REPORT_MASTER_SET
require_report_value "$PROBE_SOURCE_CONTRACT" PHYSICAL_ONLY_FILLER_MASTER_COUNT 8
require_report_value "$PROBE_SOURCE_CONTRACT" PHYSICAL_ONLY_FILLER_MASTER_SET "${FILLER_MASTERS// /,}"
require_report_value "$PROBE_SOURCE_CONTRACT" PHYSICAL_ONLY_FILLER_INSTANCE_COUNT_EXPECTED 24797
require_report_value "$PROBE_SOURCE_CONTRACT" PHYSICAL_ONLY_FILLER_INSTANCE_COUNT_INPUT 24797
require_report_value "$PROBE_SOURCE_CONTRACT" PHYSICAL_ONLY_FILLER_INSTANCE_COUNT_REMOVED 24797
require_report_value "$PROBE_SOURCE_CONTRACT" PHYSICAL_ONLY_FILLER_REMOVAL_STATUS PASS
require_report_value "$PROBE_SOURCE_CONTRACT" PHYSICAL_TIE_CANDIDATE_COUNT 4
require_report_value "$PROBE_SOURCE_CONTRACT" PHYSICAL_TIE_CANDIDATE_SET "${TIE_HIGH_CANDIDATES// /,},${TIE_LOW_CANDIDATES// /,}"
require_report_value "$PROBE_SOURCE_CONTRACT" PHYSICAL_TIE_MASTER_COUNT 0
require_report_value "$PROBE_SOURCE_CONTRACT" PHYSICAL_TIE_INSTANCE_COUNT 0
require_report_value "$PROBE_SOURCE_CONTRACT" PHYSICAL_TIE_PRESERVATION_STATUS PASS

case "$SOURCE_CHECKPOINT" in
  "$INNOVUS_WORK"/*/checkpoints/repaired_route.enc.dat) ;;
  *) echo "STOP: source checkpoint is outside the expected immutable lineage"; PREFLIGHT=FAIL ;;
esac
[[ -d "$SOURCE_CHECKPOINT" ]] || { echo "STOP: source checkpoint missing"; PREFLIGHT=FAIL; }
SOURCE_CHECKPOINT_ACTUAL_SHA="$(tree_content_hash "$SOURCE_CHECKPOINT")"
[[ "$SOURCE_CHECKPOINT_EXPECTED_SHA" != MISSING && \
   "$SOURCE_CHECKPOINT_ACTUAL_SHA" == "$SOURCE_CHECKPOINT_EXPECTED_SHA" ]] || {
  echo "STOP: immutable source checkpoint hash differs from Step 6R"
  PREFLIGHT=FAIL
}

case "$SOURCE_FILLER_REPORTED" in
  */MPTDC/docs/server_snapshots/innovus/*/reports/filler_status.rpt) ;;
  *) echo "STOP: source filler report path is outside tracked evidence"; PREFLIGHT=FAIL ;;
esac
case "$SOURCE_ROW_REPORTED" in
  */MPTDC/docs/server_snapshots/innovus/*/reports/row_infra_insertion.rpt) ;;
  *) echo "STOP: source row-infrastructure report path is outside tracked evidence"; PREFLIGHT=FAIL ;;
esac
SOURCE_FILLER_ACTUAL_SHA="$(file_sha256 "$SOURCE_FILLER_TRACKED")"
SOURCE_ROW_ACTUAL_SHA="$(file_sha256 "$SOURCE_ROW_TRACKED")"
[[ -s "$SOURCE_FILLER_TRACKED" && \
   "$SOURCE_FILLER_ACTUAL_SHA" == "$SOURCE_FILLER_EXPECTED_SHA" ]] || {
  echo "STOP: tracked filler report is missing or differs from the published source contract"
  PREFLIGHT=FAIL
}
[[ -s "$SOURCE_ROW_TRACKED" && \
   "$SOURCE_ROW_ACTUAL_SHA" == "$SOURCE_ROW_EXPECTED_SHA" ]] || {
  echo "STOP: tracked row-infrastructure report is missing or differs from the published source contract"
  PREFLIGHT=FAIL
}
require_report_value "$SOURCE_FILLER_TRACKED" FILLER_INSERTION_STATUS PASS
require_report_value "$SOURCE_FILLER_TRACKED" FILLER_CANDIDATES "$FILLER_MASTERS"
require_report_value "$SOURCE_FILLER_TRACKED" FILLER_COUNT 24797
require_report_value "$SOURCE_ROW_TRACKED" FILLER_CANDIDATES "$FILLER_MASTERS"
require_report_value "$SOURCE_ROW_TRACKED" TIE_HIGH_CANDIDATES "$TIE_HIGH_CANDIDATES"
require_report_value "$SOURCE_ROW_TRACKED" TIE_LOW_CANDIDATES "$TIE_LOW_CANDIDATES"

RESTORE_COMMAND_COUNT="$({ grep -Ec '(^|[[:space:]{}])restoreDesign[[:space:]]+\$checkpoint([[:space:]{}]|$)' "$TRIAL_TCL" || true; } | tail -1)"
SET_MODE_COMMAND_COUNT="$({ grep -Ec '^[[:space:]]*setTieHiLoMode[[:space:]]+-cell[[:space:]]' "$TRIAL_TCL" || true; } | tail -1)"
ADD_TIE_COMMAND_COUNT="$({ grep -Ec '^[[:space:]]*addTieHiLo[[:space:]]+-cell[[:space:]]' "$TRIAL_TCL" || true; } | tail -1)"
SAVE_COMMAND_COUNT="$({ grep -Ec '(^|[[:space:]{}])saveDesign[[:space:]]+\$final_checkpoint([[:space:]{}]|$)' "$TRIAL_TCL" || true; } | tail -1)"
SELECTED_ROUTE_CALL_COUNT="$({ grep -Ec '^[[:space:]]*mptdc_ckpt_route_selected_nets_route_design[[:space:]]' "$TRIAL_TCL" || true; } | tail -1)"
FORBIDDEN_MUTATION_COUNT="$({ grep -Eiv '^[[:space:]]*#' "$TRIAL_TCL" | grep -Eic '(^|[[:space:]{}])(deleteFiller|deleteInst|deleteNet|globalDetailRoute|ecoRoute|sroute|refinePlace|placeDesign|optDesign|editDelete|dbDeleteObj)([[:space:]{}]|$)' || true; } | tail -1)"
[[ "$RESTORE_COMMAND_COUNT" == 1 ]] || { echo "STOP: trial must restore exactly once"; PREFLIGHT=FAIL; }
[[ "$SET_MODE_COMMAND_COUNT" == 1 ]] || { echo "STOP: trial must set tie mode exactly once"; PREFLIGHT=FAIL; }
[[ "$ADD_TIE_COMMAND_COUNT" == 1 ]] || { echo "STOP: trial must invoke addTieHiLo exactly once"; PREFLIGHT=FAIL; }
[[ "$SAVE_COMMAND_COUNT" == 1 ]] || { echo "STOP: trial must contain one pass-gated saveDesign"; PREFLIGHT=FAIL; }
[[ "$SELECTED_ROUTE_CALL_COUNT" == 1 ]] || { echo "STOP: trial must use one selected-net route helper"; PREFLIGHT=FAIL; }
[[ "$FORBIDDEN_MUTATION_COUNT" == 0 ]] || { echo "STOP: broad or destructive mutation found in trial Tcl"; PREFLIGHT=FAIL; }

CADENCE_ENV_RC=99
CADENCE_ENV_STATUS=NOT_RUN_PREFLIGHT_FAIL
if [[ "$PREFLIGHT" == PASS ]]; then
  CADENCE_ENV_RC=0
  CADENCE_ENV_STATUS=SKIPPED_CUSTOM_INNOVUS
  if [[ "$INNOVUS_BIN" == innovus || -n "${MPTDC_CADENCE_ENV+x}" ]]; then
    if ! load_cadence_env "$CADENCE_ENV"; then
      echo "STOP: Cadence environment failed"
      PREFLIGHT=FAIL
    fi
  else
    echo "CADENCE_ENV=$CADENCE_ENV"
    echo "CADENCE_ENV_RC=$CADENCE_ENV_RC"
    echo "CADENCE_ENV_STATUS=$CADENCE_ENV_STATUS"
  fi
  if [[ "$INNOVUS_BIN" == */* ]]; then
    [[ -x "$INNOVUS_BIN" ]] || { echo "STOP: Innovus executable unavailable: $INNOVUS_BIN"; PREFLIGHT=FAIL; }
  else
    command -v "$INNOVUS_BIN" >/dev/null 2>&1 || {
      echo "STOP: Innovus executable unavailable: $INNOVUS_BIN"
      PREFLIGHT=FAIL
    }
  fi
fi

echo "TIE1_INSERTION_TRIAL_PREFLIGHT=$PREFLIGHT"
echo "RESTORE_COMMAND_COUNT=$RESTORE_COMMAND_COUNT"
echo "SET_MODE_COMMAND_COUNT=$SET_MODE_COMMAND_COUNT"
echo "ADD_TIE_COMMAND_COUNT=$ADD_TIE_COMMAND_COUNT"
echo "SAVE_COMMAND_COUNT=$SAVE_COMMAND_COUNT"
echo "SELECTED_ROUTE_CALL_COUNT=$SELECTED_ROUTE_CALL_COUNT"
echo "FORBIDDEN_MUTATION_COUNT=$FORBIDDEN_MUTATION_COUNT"
if [[ "$PREFLIGHT" != PASS ]]; then
  echo "DECISION=FAIL_STOP"
  exit 4
fi

SAFE_SOURCE_DIR="$RUN_DIR/source_checkpoint_safe"
SAFE_CHECKPOINT="$SAFE_SOURCE_DIR/$(basename "$SOURCE_CHECKPOINT")"
REPORT_DIR="$RUN_DIR/reports"
MANIFEST_DIR="$RUN_DIR/manifests"
LOG_DIR="$RUN_DIR/logs"
mkdir -p "$SAFE_SOURCE_DIR" "$REPORT_DIR" "$MANIFEST_DIR" "$LOG_DIR"

SOURCE_CHECKPOINT_SHA_PRE="$(tree_content_hash "$SOURCE_CHECKPOINT")"
cp -aL "$SOURCE_CHECKPOINT" "$SAFE_CHECKPOINT"
SAFE_COPY_RC=$?
SAFE_CHECKPOINT_SHA_PRE="$(tree_content_hash "$SAFE_CHECKPOINT")"
PROBE_EVIDENCE_SHA_PRE="$(tree_content_hash "$PROBE_DIR")"
TRACKED_PROBE_EVIDENCE_SHA_PRE="$(tree_content_hash "$TRACKED_PROBE_DIR")"
TRIAL_TCL_SHA_PRE="$(file_sha256 "$TRIAL_TCL")"

cp -p "$PROBE_GATE" "$MANIFEST_DIR/source_probe_operator_gate.rpt"
cp -p "$PROBE_MANIFEST" "$MANIFEST_DIR/source_probe_inputs.rpt"
cp -p "$PROBE_MASTER_REPORT" "$MANIFEST_DIR/source_probe_tie_master_inventory.tsv"
cp -p "$PROBE_FLAGGED_REPORT" "$MANIFEST_DIR/source_probe_flagged_term_inventory.tsv"
cp -p "$PROBE_SOURCE_CONTRACT" "$MANIFEST_DIR/source_physical_lvs_contract.rpt"
cp -p "$SOURCE_FILLER_TRACKED" "$MANIFEST_DIR/source_filler_status.rpt"
cp -p "$SOURCE_ROW_TRACKED" "$REPORT_DIR/row_infra_insertion.rpt"

{
  echo "STEP=TIE1_INSERTION_TRIAL_INPUTS"
  echo "DATE=$(date -Iseconds)"
  echo "REPO_ROOT=$REPO_ROOT"
  echo "BRANCH=$BRANCH"
  echo "HEAD=$ACTUAL_HEAD"
  echo "ORIGIN_HEAD=${ORIGIN_HEAD:-MISSING}"
  echo "AUTHORIZATION=$AUTHORIZATION"
  echo "PROBE_RUN_ID=$PROBE_RUN_ID"
  echo "BOUNDARY_PVS_RUN_ID=$BOUNDARY_PVS_RUN_ID"
  echo "SOURCE_PVS_RUN_ID=$SOURCE_PVS_RUN_ID"
  echo "SOURCE_PNR_RUN_ID=$SOURCE_PNR_RUN_ID"
  echo "SOURCE_CHECKPOINT=$SOURCE_CHECKPOINT"
  echo "SAFE_CHECKPOINT=$SAFE_CHECKPOINT"
  echo "SOURCE_CHECKPOINT_SHA256_PRE=$SOURCE_CHECKPOINT_SHA_PRE"
  echo "SAFE_CHECKPOINT_SHA256_PRE=$SAFE_CHECKPOINT_SHA_PRE"
  echo "PROBE_EVIDENCE_SHA256_PRE=$PROBE_EVIDENCE_SHA_PRE"
  echo "TRACKED_PROBE_EVIDENCE_SHA256_PRE=$TRACKED_PROBE_EVIDENCE_SHA_PRE"
  echo "TRIAL_TCL=$TRIAL_TCL"
  echo "TRIAL_TCL_SHA256_PRE=$TRIAL_TCL_SHA_PRE"
  echo "SOURCE_PHYSICAL_LVS_CONTRACT=$PROBE_SOURCE_CONTRACT"
  echo "SOURCE_PHYSICAL_LVS_CONTRACT_SHA256=$(file_sha256 "$PROBE_SOURCE_CONTRACT")"
  echo "SOURCE_FILLER_REPORT=$SOURCE_FILLER_TRACKED"
  echo "SOURCE_FILLER_REPORT_SHA256=$SOURCE_FILLER_ACTUAL_SHA"
  echo "SOURCE_ROW_INFRA_REPORT=$SOURCE_ROW_TRACKED"
  echo "SOURCE_ROW_INFRA_REPORT_SHA256=$SOURCE_ROW_ACTUAL_SHA"
  echo "HIGH_MASTER=$HIGH_MASTER"
  echo "LOW_MASTER=$LOW_MASTER"
  echo "MAX_FANOUT=$MAX_FANOUT"
  echo "MAX_DISTANCE_UM=$MAX_DISTANCE"
  echo "EXPECTED_HIGH_TERMS=$EXPECTED_HIGH_TERMS"
  echo "EXPECTED_LOW_TERMS=$EXPECTED_LOW_TERMS"
  echo "EXPECTED_FILLERS=$EXPECTED_FILLERS"
  echo "EXPECTED_BASE_DRC=$EXPECTED_DRC"
  echo "RESTORE_COMMAND_COUNT=$RESTORE_COMMAND_COUNT"
  echo "SET_MODE_COMMAND_COUNT=$SET_MODE_COMMAND_COUNT"
  echo "ADD_TIE_COMMAND_COUNT=$ADD_TIE_COMMAND_COUNT"
  echo "SAVE_COMMAND_COUNT=$SAVE_COMMAND_COUNT"
  echo "SELECTED_ROUTE_CALL_COUNT=$SELECTED_ROUTE_CALL_COUNT"
  echo "FORBIDDEN_MUTATION_COUNT=$FORBIDDEN_MUTATION_COUNT"
  echo "SAFE_COPY_RC=$SAFE_COPY_RC"
  echo "CADENCE_ENV_RC=$CADENCE_ENV_RC"
  echo "CADENCE_ENV_STATUS=$CADENCE_ENV_STATUS"
} > "$MANIFEST_DIR/tie1_insertion_trial_inputs.rpt"

export MPTDC_TIE1_TRIAL_CKPT="$SAFE_CHECKPOINT"
export MPTDC_TIE1_TRIAL_OUTDIR="$RUN_DIR"
export MPTDC_TIE1_TRIAL_REPO_ROOT="$REPO_ROOT"
export MPTDC_TIE1_TRIAL_TOP=mptdc_axis_core
export MPTDC_TIE1_TRIAL_HIGH_MASTER="$HIGH_MASTER"
export MPTDC_TIE1_TRIAL_LOW_MASTER="$LOW_MASTER"
export MPTDC_TIE1_TRIAL_MAX_FANOUT="$MAX_FANOUT"
export MPTDC_TIE1_TRIAL_MAX_DISTANCE="$MAX_DISTANCE"
export MPTDC_TIE1_TRIAL_EXPECTED_HIGH_TERMS="$EXPECTED_HIGH_TERMS"
export MPTDC_TIE1_TRIAL_EXPECTED_LOW_TERMS="$EXPECTED_LOW_TERMS"
export MPTDC_TIE1_TRIAL_EXPECTED_FILLERS="$EXPECTED_FILLERS"
export MPTDC_TIE1_TRIAL_EXPECTED_DRC="$EXPECTED_DRC"
export MPTDC_TIE1_TRIAL_FILLER_MASTERS="$FILLER_MASTERS"

set +e
"$INNOVUS_BIN" -nowin -init "$TRIAL_TCL" \
  -log "$LOG_DIR/innovus_tie1_insertion_trial.log" \
  2>&1 | tee "$LOG_DIR/innovus_tie1_insertion_trial.console.log"
INNOVUS_RC=${PIPESTATUS[0]}
set +e

SOURCE_CHECKPOINT_SHA_POST="$(tree_content_hash "$SOURCE_CHECKPOINT")"
SAFE_CHECKPOINT_SHA_POST="$(tree_content_hash "$SAFE_CHECKPOINT")"
PROBE_EVIDENCE_SHA_POST="$(tree_content_hash "$PROBE_DIR")"
TRACKED_PROBE_EVIDENCE_SHA_POST="$(tree_content_hash "$TRACKED_PROBE_DIR")"
TRIAL_TCL_SHA_POST="$(file_sha256 "$TRIAL_TCL")"
CANDIDATE_CHECKPOINT="$RUN_DIR/checkpoints/repaired_route.enc.dat"
CANDIDATE_CHECKPOINT_SHA="$(tree_content_hash "$CANDIDATE_CHECKPOINT")"

SOURCE_CHECKPOINT_HASH_STATUS=FAIL
SAFE_COPY_MATCH_STATUS=FAIL
SAFE_INPUT_READ_ONLY_STATUS=FAIL
PROBE_EVIDENCE_READ_ONLY_STATUS=FAIL
TRIAL_TCL_READ_ONLY_STATUS=FAIL
CANDIDATE_CHECKPOINT_STATUS=FAIL
[[ "$SOURCE_CHECKPOINT_SHA_PRE" != MISSING && \
   "$SOURCE_CHECKPOINT_SHA_PRE" == "$SOURCE_CHECKPOINT_SHA_POST" ]] && SOURCE_CHECKPOINT_HASH_STATUS=PASS
[[ "$SAFE_COPY_RC" -eq 0 && "$SOURCE_CHECKPOINT_SHA_PRE" != MISSING && \
   "$SOURCE_CHECKPOINT_SHA_PRE" == "$SAFE_CHECKPOINT_SHA_PRE" ]] && SAFE_COPY_MATCH_STATUS=PASS
[[ "$SAFE_CHECKPOINT_SHA_PRE" != MISSING && \
   "$SAFE_CHECKPOINT_SHA_PRE" == "$SAFE_CHECKPOINT_SHA_POST" ]] && SAFE_INPUT_READ_ONLY_STATUS=PASS
[[ "$PROBE_EVIDENCE_SHA_PRE" != MISSING && \
   "$PROBE_EVIDENCE_SHA_PRE" == "$PROBE_EVIDENCE_SHA_POST" && \
   "$TRACKED_PROBE_EVIDENCE_SHA_PRE" == "$TRACKED_PROBE_EVIDENCE_SHA_POST" ]] && PROBE_EVIDENCE_READ_ONLY_STATUS=PASS
[[ "$TRIAL_TCL_SHA_PRE" != MISSING && "$TRIAL_TCL_SHA_PRE" == "$TRIAL_TCL_SHA_POST" ]] && TRIAL_TCL_READ_ONLY_STATUS=PASS
[[ -d "$CANDIDATE_CHECKPOINT" && "$CANDIDATE_CHECKPOINT_SHA" != MISSING ]] && CANDIDATE_CHECKPOINT_STATUS=PASS

TRIAL_REPORT="$REPORT_DIR/tie1_insertion_trial_status.rpt"
FILLER_REPORT="$REPORT_DIR/filler_status.rpt"
TRIAL_STATUS="$(report_value "$TRIAL_REPORT" TIE1_INSERTION_TRIAL_STATUS)"
COMMAND_PRECHECK="$(report_value "$TRIAL_REPORT" COMMAND_PRECHECK)"
SET_TIE_MODE_STATUS="$(report_value "$TRIAL_REPORT" SET_TIE_MODE_STATUS)"
ADD_TIE_STATUS="$(report_value "$TRIAL_REPORT" ADD_TIE_STATUS)"
SELECTED_ROUTE_STATUS="$(report_value "$TRIAL_REPORT" SELECTED_ROUTE_STATUS)"
BASELINE_PLACEMENT_STATUS="$(report_value "$TRIAL_REPORT" BASELINE_PLACEMENT_STATUS)"
FINAL_PLACEMENT_STATUS="$(report_value "$TRIAL_REPORT" FINAL_PLACEMENT_STATUS)"
FINAL_CONNECTED_HIGH_TERM_COUNT="$(report_value "$TRIAL_REPORT" FINAL_CONNECTED_HIGH_TERM_COUNT)"
FINAL_DISCONNECTED_HIGH_TERM_COUNT="$(report_value "$TRIAL_REPORT" FINAL_DISCONNECTED_HIGH_TERM_COUNT)"
FINAL_FLAGGED_LOW_TERM_COUNT="$(report_value "$TRIAL_REPORT" FINAL_FLAGGED_LOW_TERM_COUNT)"
FINAL_TIE_NET_COUNT="$(report_value "$TRIAL_REPORT" FINAL_TIE_NET_COUNT)"
TIE_NET_SOURCE_CONTRACT_STATUS="$(report_value "$TRIAL_REPORT" TIE_NET_SOURCE_CONTRACT_STATUS)"
TIE_NET_ROUTE_STATUS="$(report_value "$TRIAL_REPORT" TIE_NET_ROUTE_STATUS)"
TIE_FANOUT_STATUS="$(report_value "$TRIAL_REPORT" TIE_FANOUT_STATUS)"
MAX_OBSERVED_TIE_FANOUT="$(report_value "$TRIAL_REPORT" MAX_OBSERVED_TIE_FANOUT)"
TIE_HIGH_INSTANCE_DELTA="$(report_value "$TRIAL_REPORT" TIE_HIGH_INSTANCE_DELTA)"
TARGET_HIGH_INSTANCE_DELTA="$(report_value "$TRIAL_REPORT" TARGET_HIGH_INSTANCE_DELTA)"
ALTERNATE_TIE_MASTER_DELTA="$(report_value "$TRIAL_REPORT" ALTERNATE_TIE_MASTER_DELTA)"
TIE_LOW_INSTANCE_DELTA="$(report_value "$TRIAL_REPORT" TIE_LOW_INSTANCE_DELTA)"
FILLER_COUNT_AFTER="$(report_value "$TRIAL_REPORT" FILLER_COUNT_AFTER)"
UNEXPLAINED_INSTANCE_DELTA="$(report_value "$TRIAL_REPORT" UNEXPLAINED_INSTANCE_DELTA)"
PHYSICAL_DEBT_PRESERVATION_STATUS="$(report_value "$TRIAL_REPORT" PHYSICAL_DEBT_PRESERVATION_STATUS)"
BASELINE_DRC="$(report_value "$TRIAL_REPORT" BASELINE_DRC)"
BASELINE_SHORTS="$(report_value "$TRIAL_REPORT" BASELINE_SHORTS)"
BASELINE_REGULAR_BAD="$(report_value "$TRIAL_REPORT" BASELINE_REGULAR_CONNECTIVITY_BAD)"
BASELINE_SPECIAL_BAD="$(report_value "$TRIAL_REPORT" BASELINE_SPECIAL_CONNECTIVITY_BAD)"
BASELINE_UNROUTED="$(report_value "$TRIAL_REPORT" BASELINE_UNROUTED_NETS)"
BASELINE_ROUTE_REPORT_ZERO_STATUS="$(report_value "$TRIAL_REPORT" BASELINE_REPORT_ROUTE_ZERO_STATUS)"
BASELINE_MARKER_SIGNATURE_COUNT="$(report_value "$TRIAL_REPORT" BASELINE_DRC_MARKER_SIGNATURE_COUNT)"
BASELINE_MARKER_SIGNATURE="$(report_value "$TRIAL_REPORT" BASELINE_DRC_MARKER_SIGNATURE)"
FINAL_DRC="$(report_value "$TRIAL_REPORT" FINAL_DRC)"
FINAL_SHORTS="$(report_value "$TRIAL_REPORT" FINAL_SHORTS)"
FINAL_REGULAR_BAD="$(report_value "$TRIAL_REPORT" FINAL_REGULAR_CONNECTIVITY_BAD)"
FINAL_SPECIAL_BAD="$(report_value "$TRIAL_REPORT" FINAL_SPECIAL_CONNECTIVITY_BAD)"
FINAL_SPECIAL_RAW="$(report_value "$TRIAL_REPORT" FINAL_SPECIAL_CONNECTIVITY_RAW_BAD)"
FINAL_SPECIAL_NON_RO="$(report_value "$TRIAL_REPORT" FINAL_SPECIAL_CONNECTIVITY_NON_RO_FAILURES)"
FINAL_UNROUTED="$(report_value "$TRIAL_REPORT" FINAL_UNROUTED_NETS)"
FINAL_ROUTE_REPORT_ZERO_STATUS="$(report_value "$TRIAL_REPORT" FINAL_REPORT_ROUTE_ZERO_STATUS)"
FINAL_MARKER_SIGNATURE_COUNT="$(report_value "$TRIAL_REPORT" FINAL_DRC_MARKER_SIGNATURE_COUNT)"
FINAL_MARKER_SIGNATURE="$(report_value "$TRIAL_REPORT" FINAL_DRC_MARKER_SIGNATURE)"
CHECKPOINT_SAVE_STATUS="$(report_value "$TRIAL_REPORT" CHECKPOINT_SAVE_STATUS)"
CORE_QUERY_ERROR_COUNT="$(report_value "$TRIAL_REPORT" CORE_QUERY_ERROR_COUNT)"
FILLER_INSERTION_STATUS="$(report_value "$FILLER_REPORT" FILLER_INSERTION_STATUS)"

NUMERIC_GATE_STATUS=PASS
for value in \
  "$FINAL_TIE_NET_COUNT" \
  "$MAX_OBSERVED_TIE_FANOUT" \
  "$TIE_HIGH_INSTANCE_DELTA" \
  "$TARGET_HIGH_INSTANCE_DELTA" \
  "$FILLER_COUNT_AFTER"; do
  [[ "$value" =~ ^[1-9][0-9]*$ ]] || NUMERIC_GATE_STATUS=FAIL
done
if [[ "$NUMERIC_GATE_STATUS" == PASS ]]; then
  (( MAX_OBSERVED_TIE_FANOUT <= MAX_FANOUT )) || NUMERIC_GATE_STATUS=FAIL
  (( TIE_HIGH_INSTANCE_DELTA <= EXPECTED_HIGH_TERMS )) || NUMERIC_GATE_STATUS=FAIL
  (( FILLER_COUNT_AFTER <= EXPECTED_FILLERS )) || NUMERIC_GATE_STATUS=FAIL
fi
DRC_MARKER_SIGNATURE_MATCH_STATUS=FAIL
if [[ "$BASELINE_MARKER_SIGNATURE_COUNT" == 1 && \
      "$FINAL_MARKER_SIGNATURE_COUNT" == 1 && \
      "$BASELINE_MARKER_SIGNATURE" != MISSING && \
      "$BASELINE_MARKER_SIGNATURE" == "$FINAL_MARKER_SIGNATURE" ]]; then
  DRC_MARKER_SIGNATURE_MATCH_STATUS=PASS
fi

DECISION=FAIL_STOP
NEXT_STAGE=STOP_AND_REVIEW_PUBLISHED_EVIDENCE
if [[ "$INNOVUS_RC" -eq 0 && "$TRIAL_STATUS" == PASS && \
      "$COMMAND_PRECHECK" == PASS && "$SET_TIE_MODE_STATUS" == PASS && \
      "$ADD_TIE_STATUS" == PASS && "$SELECTED_ROUTE_STATUS" == PASS && \
      "$BASELINE_PLACEMENT_STATUS" == PASS && "$FINAL_PLACEMENT_STATUS" == PASS && \
      "$FINAL_CONNECTED_HIGH_TERM_COUNT" == 91 && "$FINAL_DISCONNECTED_HIGH_TERM_COUNT" == 0 && \
      "$FINAL_FLAGGED_LOW_TERM_COUNT" == 0 && "$NUMERIC_GATE_STATUS" == PASS && \
      "$TIE_NET_SOURCE_CONTRACT_STATUS" == PASS && "$TIE_NET_ROUTE_STATUS" == PASS && \
      "$TIE_FANOUT_STATUS" == PASS && "$TIE_HIGH_INSTANCE_DELTA" == "$TARGET_HIGH_INSTANCE_DELTA" && \
      "$TARGET_HIGH_INSTANCE_DELTA" == "$FINAL_TIE_NET_COUNT" && \
      "$ALTERNATE_TIE_MASTER_DELTA" == 0 && "$TIE_LOW_INSTANCE_DELTA" == 0 && \
      "$UNEXPLAINED_INSTANCE_DELTA" == 0 && \
      "$PHYSICAL_DEBT_PRESERVATION_STATUS" == PASS && \
      "$BASELINE_DRC" == 1 && "$BASELINE_SHORTS" == 0 && "$BASELINE_REGULAR_BAD" == 0 && \
      "$BASELINE_SPECIAL_BAD" == 1 && "$BASELINE_UNROUTED" == 0 && \
      "$BASELINE_ROUTE_REPORT_ZERO_STATUS" == PASS && "$BASELINE_MARKER_SIGNATURE_COUNT" == 1 && \
      "$FINAL_DRC" == 1 && "$FINAL_SHORTS" == 0 && "$FINAL_REGULAR_BAD" == 0 && \
      "$FINAL_SPECIAL_BAD" == 1 && "$FINAL_SPECIAL_RAW" == 1 && "$FINAL_SPECIAL_NON_RO" == 0 && \
      "$FINAL_UNROUTED" == 0 && "$FINAL_ROUTE_REPORT_ZERO_STATUS" == PASS && \
      "$FINAL_MARKER_SIGNATURE_COUNT" == 1 && \
      "$DRC_MARKER_SIGNATURE_MATCH_STATUS" == PASS && \
      "$CHECKPOINT_SAVE_STATUS" == PASS && "$CORE_QUERY_ERROR_COUNT" == 0 && \
      "$FILLER_INSERTION_STATUS" == PASS && "$SOURCE_CHECKPOINT_HASH_STATUS" == PASS && \
      "$SAFE_COPY_MATCH_STATUS" == PASS && "$SAFE_INPUT_READ_ONLY_STATUS" == PASS && \
      "$PROBE_EVIDENCE_READ_ONLY_STATUS" == PASS && "$TRIAL_TCL_READ_ONLY_STATUS" == PASS && \
      "$CANDIDATE_CHECKPOINT_STATUS" == PASS ]]; then
  DECISION=PASS_TIE1_TRIAL_CONTINUE
  NEXT_STAGE=DIAGNOSTIC_PHYSICAL_PVS_FROM_TIE1_TRIAL
fi

{
  echo "STEP=TIE1_INSERTION_TRIAL"
  echo "PROBE_RUN_ID=$PROBE_RUN_ID"
  echo "BOUNDARY_PVS_RUN_ID=$BOUNDARY_PVS_RUN_ID"
  echo "SOURCE_PVS_RUN_ID=$SOURCE_PVS_RUN_ID"
  echo "SOURCE_PNR_RUN_ID=$SOURCE_PNR_RUN_ID"
  echo "SOURCE_CHECKPOINT=$SOURCE_CHECKPOINT"
  echo "SAFE_CHECKPOINT=$SAFE_CHECKPOINT"
  echo "CANDIDATE_CHECKPOINT=$CANDIDATE_CHECKPOINT"
  echo "CANDIDATE_CHECKPOINT_SHA256=$CANDIDATE_CHECKPOINT_SHA"
  echo "AUTHORIZATION=$AUTHORIZATION"
  echo "HIGH_MASTER=$HIGH_MASTER"
  echo "LOW_MASTER=$LOW_MASTER"
  echo "MAX_FANOUT=$MAX_FANOUT"
  echo "MAX_DISTANCE_UM=$MAX_DISTANCE"
  echo "INNOVUS_RC=$INNOVUS_RC"
  echo "TIE1_INSERTION_TRIAL_STATUS=$TRIAL_STATUS"
  echo "SET_TIE_MODE_STATUS=$SET_TIE_MODE_STATUS"
  echo "ADD_TIE_STATUS=$ADD_TIE_STATUS"
  echo "SELECTED_ROUTE_STATUS=$SELECTED_ROUTE_STATUS"
  echo "BASELINE_PLACEMENT_STATUS=$BASELINE_PLACEMENT_STATUS"
  echo "FINAL_PLACEMENT_STATUS=$FINAL_PLACEMENT_STATUS"
  echo "FINAL_CONNECTED_HIGH_TERM_COUNT=$FINAL_CONNECTED_HIGH_TERM_COUNT"
  echo "FINAL_DISCONNECTED_HIGH_TERM_COUNT=$FINAL_DISCONNECTED_HIGH_TERM_COUNT"
  echo "FINAL_FLAGGED_LOW_TERM_COUNT=$FINAL_FLAGGED_LOW_TERM_COUNT"
  echo "FINAL_TIE_NET_COUNT=$FINAL_TIE_NET_COUNT"
  echo "TIE_NET_SOURCE_CONTRACT_STATUS=$TIE_NET_SOURCE_CONTRACT_STATUS"
  echo "TIE_NET_ROUTE_STATUS=$TIE_NET_ROUTE_STATUS"
  echo "TIE_FANOUT_STATUS=$TIE_FANOUT_STATUS"
  echo "MAX_OBSERVED_TIE_FANOUT=$MAX_OBSERVED_TIE_FANOUT"
  echo "NUMERIC_GATE_STATUS=$NUMERIC_GATE_STATUS"
  echo "TIE_HIGH_INSTANCE_DELTA=$TIE_HIGH_INSTANCE_DELTA"
  echo "TARGET_HIGH_INSTANCE_DELTA=$TARGET_HIGH_INSTANCE_DELTA"
  echo "ALTERNATE_TIE_MASTER_DELTA=$ALTERNATE_TIE_MASTER_DELTA"
  echo "TIE_LOW_INSTANCE_DELTA=$TIE_LOW_INSTANCE_DELTA"
  echo "FILLER_COUNT_AFTER=$FILLER_COUNT_AFTER"
  echo "UNEXPLAINED_INSTANCE_DELTA=$UNEXPLAINED_INSTANCE_DELTA"
  echo "PHYSICAL_DEBT_PRESERVATION_STATUS=$PHYSICAL_DEBT_PRESERVATION_STATUS"
  echo "BASELINE_DRC=$BASELINE_DRC"
  echo "BASELINE_SHORTS=$BASELINE_SHORTS"
  echo "BASELINE_REGULAR_CONNECTIVITY_BAD=$BASELINE_REGULAR_BAD"
  echo "BASELINE_SPECIAL_CONNECTIVITY_BAD=$BASELINE_SPECIAL_BAD"
  echo "BASELINE_UNROUTED_NETS=$BASELINE_UNROUTED"
  echo "BASELINE_REPORT_ROUTE_ZERO_STATUS=$BASELINE_ROUTE_REPORT_ZERO_STATUS"
  echo "BASELINE_DRC_MARKER_SIGNATURE_COUNT=$BASELINE_MARKER_SIGNATURE_COUNT"
  echo "FINAL_DRC=$FINAL_DRC"
  echo "FINAL_SHORTS=$FINAL_SHORTS"
  echo "FINAL_REGULAR_CONNECTIVITY_BAD=$FINAL_REGULAR_BAD"
  echo "FINAL_SPECIAL_CONNECTIVITY_BAD=$FINAL_SPECIAL_BAD"
  echo "FINAL_SPECIAL_CONNECTIVITY_RAW_BAD=$FINAL_SPECIAL_RAW"
  echo "FINAL_SPECIAL_CONNECTIVITY_NON_RO_FAILURES=$FINAL_SPECIAL_NON_RO"
  echo "FINAL_UNROUTED_NETS=$FINAL_UNROUTED"
  echo "FINAL_REPORT_ROUTE_ZERO_STATUS=$FINAL_ROUTE_REPORT_ZERO_STATUS"
  echo "FINAL_DRC_MARKER_SIGNATURE_COUNT=$FINAL_MARKER_SIGNATURE_COUNT"
  echo "DRC_MARKER_SIGNATURE_MATCH_STATUS=$DRC_MARKER_SIGNATURE_MATCH_STATUS"
  echo "CHECKPOINT_SAVE_STATUS=$CHECKPOINT_SAVE_STATUS"
  echo "SOURCE_CHECKPOINT_HASH_STATUS=$SOURCE_CHECKPOINT_HASH_STATUS"
  echo "SAFE_COPY_MATCH_STATUS=$SAFE_COPY_MATCH_STATUS"
  echo "SAFE_INPUT_READ_ONLY_STATUS=$SAFE_INPUT_READ_ONLY_STATUS"
  echo "PROBE_EVIDENCE_READ_ONLY_STATUS=$PROBE_EVIDENCE_READ_ONLY_STATUS"
  echo "TRIAL_TCL_READ_ONLY_STATUS=$TRIAL_TCL_READ_ONLY_STATUS"
  echo "CANDIDATE_CHECKPOINT_STATUS=$CANDIDATE_CHECKPOINT_STATUS"
  echo "TIMING_STATUS=NOT_RUN_BY_DIAGNOSTIC_TRIAL_SCOPE"
  echo "FOUNDRY_DRC_STATUS=NOT_RUN"
  echo "LVS_STATUS=NOT_RUN"
  echo "SIGNOFF_ELIGIBLE=NO"
  echo "DECISION=$DECISION"
  echo "NEXT_STAGE=$NEXT_STAGE"
} | tee "$REPORT_DIR/operator_gate_tie1_insertion_trial.rpt"

publish_stage
PUBLISH_RC=$?
if [[ "$PUBLISH_RC" -ne 0 ]]; then
  DECISION=FAIL_STOP
  NEXT_STAGE=REPUBLISH_TIE1_INSERTION_TRIAL_EVIDENCE
fi

echo "TIE1_INSERTION_TRIAL_RECOVERY_STATUS=$([[ "$DECISION" == PASS_TIE1_TRIAL_CONTINUE ]] && echo PASS || echo FAIL)"
echo "TRIAL_RUN_ID=$RUN_ID"
echo "PROBE_RUN_ID=$PROBE_RUN_ID"
echo "INNOVUS_RC=$INNOVUS_RC"
echo "TIE1_INSERTION_TRIAL_STATUS=$TRIAL_STATUS"
echo "FINAL_CONNECTED_HIGH_TERM_COUNT=$FINAL_CONNECTED_HIGH_TERM_COUNT"
echo "FINAL_TIE_NET_COUNT=$FINAL_TIE_NET_COUNT"
echo "TIE_HIGH_INSTANCE_DELTA=$TIE_HIGH_INSTANCE_DELTA"
echo "TARGET_HIGH_INSTANCE_DELTA=$TARGET_HIGH_INSTANCE_DELTA"
echo "ALTERNATE_TIE_MASTER_DELTA=$ALTERNATE_TIE_MASTER_DELTA"
echo "FINAL_DRC=$FINAL_DRC"
echo "FINAL_SHORTS=$FINAL_SHORTS"
echo "FINAL_UNROUTED_NETS=$FINAL_UNROUTED"
echo "FINAL_REPORT_ROUTE_ZERO_STATUS=$FINAL_ROUTE_REPORT_ZERO_STATUS"
echo "FINAL_DRC_MARKER_SIGNATURE_COUNT=$FINAL_MARKER_SIGNATURE_COUNT"
echo "DRC_MARKER_SIGNATURE_MATCH_STATUS=$DRC_MARKER_SIGNATURE_MATCH_STATUS"
echo "SOURCE_CHECKPOINT_HASH_STATUS=$SOURCE_CHECKPOINT_HASH_STATUS"
echo "CANDIDATE_CHECKPOINT_STATUS=$CANDIDATE_CHECKPOINT_STATUS"
echo "SIGNOFF_ELIGIBLE=NO"
echo "DECISION=$DECISION"
echo "PUBLISH_RC=$PUBLISH_RC"
echo "NEXT_EXPECTED_HEAD=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null)"
echo "NEXT_STAGE=$NEXT_STAGE"

if [[ "$DECISION" == PASS_TIE1_TRIAL_CONTINUE && "$PUBLISH_RC" -eq 0 ]]; then
  exit 0
fi
exit 1
