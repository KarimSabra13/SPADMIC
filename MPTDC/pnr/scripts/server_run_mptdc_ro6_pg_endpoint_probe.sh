#!/usr/bin/env bash
# Publish a read-only Innovus classification of the exact RO6 PG wire ends.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
REPO_ROOT="${MPTDC_PG_PROBE_REPO_ROOT:-$DEFAULT_REPO_ROOT}"
PUBLISHER="${MPTDC_PG_PROBE_PUBLISHER:-$REPO_ROOT/MPTDC/ci/publish_mptdc_server_snapshot.sh}"
PROBE_LAUNCHER="${MPTDC_PG_PROBE_LAUNCHER:-$SCRIPT_DIR/server_repair_mptdc_pg_dangling_checkpoint.sh}"
INNOVUS_WORK="${MPTDC_INNOVUS_WORK:-/sim/ksabra/SPADMIC_work/innovus}"

SOURCE_PNR_RUN_ID=""
BOUNDARY_PVS_RUN_ID=""
RUN_ID=""
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD:-}"

usage() {
  cat <<'USAGE'
Usage:
  server_run_mptdc_ro6_pg_endpoint_probe.sh --source-pnr-run-id <id> \
    --boundary-pvs-run-id <id> [options]

Options:
  --source-pnr-run-id <id>   Immutable Innovus run containing
                             checkpoints/repaired_route.enc.dat.
  --boundary-pvs-run-id <id> Published exact RO6_PG_OPEN_ONLY boundary result.
  --run-id <id>              New read-only endpoint-probe run id.
  --expected-head <sha>      Require repository HEAD to match this commit.
  --innovus-work <path>      Innovus/PVS result root.
  -h, --help                 Show this help.

This stage runs analyze mode only. It makes a safe checkpoint copy, performs
no deletion or PG edit, publishes the 15 endpoint-to-sWire classifications,
and never claims physical or LVS closure.
USAGE
}

report_value() {
  local report="$1"
  local key="$2"
  local value
  value="$(sed -n "s/^${key}=//p" "$report" 2>/dev/null | tail -1)"
  if [[ -n "$value" ]]; then printf '%s\n' "$value"; else printf 'MISSING\n'; fi
}

publish_stage() {
  MPTDC_SNAPSHOT_MAX_TEXT_BYTES=8388608 \
    bash "$PUBLISHER" innovus "$RUN_ID" "$RUN_DIR" RO6_PG_ENDPOINT_PROBE
  local rc=$?
  EXPECTED_HEAD_VALUE="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null)"
  return "$rc"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-pnr-run-id) SOURCE_PNR_RUN_ID="${2:?missing --source-pnr-run-id value}"; shift 2 ;;
    --boundary-pvs-run-id) BOUNDARY_PVS_RUN_ID="${2:?missing --boundary-pvs-run-id value}"; shift 2 ;;
    --run-id) RUN_ID="${2:?missing --run-id value}"; shift 2 ;;
    --expected-head) EXPECTED_HEAD_VALUE="${2:?missing --expected-head value}"; shift 2 ;;
    --innovus-work) INNOVUS_WORK="${2:?missing --innovus-work value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$SOURCE_PNR_RUN_ID" && -n "$BOUNDARY_PVS_RUN_ID" ]] || {
  echo "ERROR: --source-pnr-run-id and --boundary-pvs-run-id are required" >&2
  usage >&2
  exit 2
}
for id in "$SOURCE_PNR_RUN_ID" "$BOUNDARY_PVS_RUN_ID"; do
  [[ "$id" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "ERROR: unsafe run id: $id" >&2; exit 2; }
done
if [[ -z "$RUN_ID" ]]; then
  RUN_ID="$(date +%Y%m%d)_mptdc_ro6_pg_endpoint_probe_$(date +%H%M%S)"
fi
[[ "$RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "ERROR: unsafe probe run id" >&2; exit 2; }

SOURCE_PNR_DIR="$INNOVUS_WORK/$SOURCE_PNR_RUN_ID"
SOURCE_CHECKPOINT="$SOURCE_PNR_DIR/checkpoints/repaired_route.enc.dat"
BOUNDARY_DIR="$INNOVUS_WORK/$BOUNDARY_PVS_RUN_ID"
BOUNDARY_GATE="$BOUNDARY_DIR/reports/operator_gate_pvs_ro6_boundary_lvs.rpt"
RUN_DIR="$INNOVUS_WORK/$RUN_ID"

cd "$REPO_ROOT" || exit 3
ACTUAL_HEAD="$(git rev-parse HEAD 2>/dev/null)"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
ORIGIN_HEAD="$(git rev-parse refs/remotes/origin/SPADMIC_test 2>/dev/null || true)"
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD_VALUE:-${ORIGIN_HEAD:-$ACTUAL_HEAD}}"
TRACKED_STATUS="$(git status --short --untracked-files=no 2>/dev/null)"

BOUNDARY_DECISION="$(report_value "$BOUNDARY_GATE" DECISION)"
BOUNDARY_CLASS="$(report_value "$BOUNDARY_GATE" BOUNDARY_REMAINDER_CLASS)"
BOUNDARY_LVS="$(report_value "$BOUNDARY_GATE" PVS_LVS_STATUS)"
BOUNDARY_OPEN_COUNT="$(report_value "$BOUNDARY_GATE" LAYOUT_OPEN_NET_COUNT)"
BOUNDARY_MN_COUNT="$(report_value "$BOUNDARY_GATE" MISMATCHED_NET_RECORD_COUNT)"
BOUNDARY_MI_COUNT="$(report_value "$BOUNDARY_GATE" MISMATCHED_INSTANCE_RECORD_COUNT)"

echo "SOURCE_PNR_RUN_ID=$SOURCE_PNR_RUN_ID"
echo "SOURCE_CHECKPOINT=$SOURCE_CHECKPOINT"
echo "BOUNDARY_PVS_RUN_ID=$BOUNDARY_PVS_RUN_ID"
echo "BOUNDARY_DECISION=$BOUNDARY_DECISION"
echo "BOUNDARY_REMAINDER_CLASS=$BOUNDARY_CLASS"
echo "RUN_ID=$RUN_ID"
echo "RUN_DIR=$RUN_DIR"
echo "BRANCH=$BRANCH"
echo "ACTUAL_HEAD=$ACTUAL_HEAD"
echo "EXPECTED_HEAD=$EXPECTED_HEAD_VALUE"

PREFLIGHT=PASS
[[ "$BRANCH" == SPADMIC_test ]] || { echo "STOP: branch must be SPADMIC_test"; PREFLIGHT=FAIL; }
[[ "$ACTUAL_HEAD" == "$EXPECTED_HEAD_VALUE" ]] || { echo "STOP: HEAD mismatch"; PREFLIGHT=FAIL; }
[[ -z "$TRACKED_STATUS" ]] || { echo "$TRACKED_STATUS"; echo "STOP: tracked working tree is dirty"; PREFLIGHT=FAIL; }
[[ -e "$SOURCE_CHECKPOINT" ]] || { echo "STOP: source checkpoint missing: $SOURCE_CHECKPOINT"; PREFLIGHT=FAIL; }
[[ -s "$BOUNDARY_GATE" ]] || { echo "STOP: boundary operator gate missing: $BOUNDARY_GATE"; PREFLIGHT=FAIL; }
[[ -x "$PROBE_LAUNCHER" && -s "$PUBLISHER" ]] || { echo "STOP: probe launcher or publisher missing"; PREFLIGHT=FAIL; }
[[ ! -e "$RUN_DIR" ]] || { echo "STOP: result directory already exists: $RUN_DIR"; PREFLIGHT=FAIL; }
[[ "$BOUNDARY_DECISION" == PASS_PG_REPAIR_REQUIRED && "$BOUNDARY_CLASS" == RO6_PG_OPEN_ONLY && \
   "$BOUNDARY_LVS" == MISMATCH && "$BOUNDARY_OPEN_COUNT" == 4 && \
   "$BOUNDARY_MN_COUNT" == 0 && "$BOUNDARY_MI_COUNT" == 0 ]] || {
  echo "STOP: boundary evidence is not the exact four-open RO6 PG-only class"
  PREFLIGHT=FAIL
}

echo "RO6_PG_ENDPOINT_PROBE_PREFLIGHT=$PREFLIGHT"
if [[ "$PREFLIGHT" != PASS ]]; then
  echo "DECISION=FAIL_STOP"
  exit 4
fi

if [[ -f /eda/cadence/eda_2023-2024 ]]; then
  # shellcheck disable=SC1091
  source /eda/cadence/eda_2023-2024 2>/dev/null || true
fi

set +e
bash "$PROBE_LAUNCHER" \
  --checkpoint "$SOURCE_CHECKPOINT" \
  --run-id "$RUN_ID" \
  --mode analyze \
  --expected-head "$EXPECTED_HEAD_VALUE" \
  --innovus-work "$INNOVUS_WORK" \
  2>&1 | tee "/tmp/${RUN_ID}.pg_endpoint_probe.log"
PROBE_RC=${PIPESTATUS[0]}
set +e

ANALYSIS_REPORT="$RUN_DIR/reports/pg_dangling_analysis_status.rpt"
CHECKPOINT_REPORT="$RUN_DIR/reports/checkpoint_repair_status.rpt"
MODE="$(report_value "$ANALYSIS_REPORT" PG_DANGLING_MODE)"
ANALYSIS_STATUS="$(report_value "$ANALYSIS_REPORT" PG_DANGLING_STATUS)"
MARKER_COUNT="$(report_value "$ANALYSIS_REPORT" MARKER_COUNT)"
FINAL_MARKER_COUNT="$(report_value "$ANALYSIS_REPORT" FINAL_DANGLING_MARKER_COUNT)"
DELETE_ATTEMPTS="$(report_value "$ANALYSIS_REPORT" PG_DANGLING_DELETE_ATTEMPTS)"
DELETE_SUCCESSES="$(report_value "$ANALYSIS_REPORT" PG_DANGLING_DELETE_SUCCESSES)"
BLOCKED_COUNT="$(report_value "$ANALYSIS_REPORT" PG_DANGLING_BLOCKED_COUNT)"
AMBIGUOUS_COUNT="$(report_value "$ANALYSIS_REPORT" PG_DANGLING_AMBIGUOUS_COUNT)"
MISSING_COUNT="$(report_value "$ANALYSIS_REPORT" PG_DANGLING_MISSING_EXACT_COUNT)"
INITIAL_DRC="$(report_value "$CHECKPOINT_REPORT" INITIAL_DRC)"
FINAL_DRC="$(report_value "$CHECKPOINT_REPORT" FINAL_DRC)"
INITIAL_SHORTS="$(report_value "$CHECKPOINT_REPORT" INITIAL_SHORTS)"
FINAL_SHORTS="$(report_value "$CHECKPOINT_REPORT" FINAL_SHORTS)"
INITIAL_REGULAR="$(report_value "$CHECKPOINT_REPORT" INITIAL_REGULAR_CONNECTIVITY_BAD)"
FINAL_REGULAR="$(report_value "$CHECKPOINT_REPORT" FINAL_REGULAR_CONNECTIVITY_BAD)"

DECISION=FAIL_STOP
NEXT_STAGE=STOP_AND_REVIEW_PUBLISHED_EVIDENCE
if [[ "$PROBE_RC" -eq 0 && "$MODE" == analyze && "$ANALYSIS_STATUS" == ANALYSIS_ONLY && \
      "$MARKER_COUNT" == 15 && "$FINAL_MARKER_COUNT" == 15 && \
      "$DELETE_ATTEMPTS" == 0 && "$DELETE_SUCCESSES" == 0 && \
      "$BLOCKED_COUNT" == 15 && "$AMBIGUOUS_COUNT" == 0 && "$MISSING_COUNT" == 0 && \
      "$INITIAL_DRC" == 1 && "$FINAL_DRC" == 1 && \
      "$INITIAL_SHORTS" == 0 && "$FINAL_SHORTS" == 0 && \
      "$INITIAL_REGULAR" == 0 && "$FINAL_REGULAR" == 0 ]]; then
  DECISION=PASS_REVIEW_ENDPOINTS
  NEXT_STAGE=DESIGN_EXACT_RO6_PG_PATCH_FROM_PUBLISHED_PROBE
fi

{
  echo "STEP=RO6_PG_ENDPOINT_PROBE"
  echo "SOURCE_PNR_RUN_ID=$SOURCE_PNR_RUN_ID"
  echo "SOURCE_CHECKPOINT=$SOURCE_CHECKPOINT"
  echo "BOUNDARY_PVS_RUN_ID=$BOUNDARY_PVS_RUN_ID"
  echo "PROBE_RC=$PROBE_RC"
  echo "PG_DANGLING_MODE=$MODE"
  echo "PG_DANGLING_STATUS=$ANALYSIS_STATUS"
  echo "MARKER_COUNT=$MARKER_COUNT"
  echo "FINAL_DANGLING_MARKER_COUNT=$FINAL_MARKER_COUNT"
  echo "PG_DANGLING_DELETE_ATTEMPTS=$DELETE_ATTEMPTS"
  echo "PG_DANGLING_DELETE_SUCCESSES=$DELETE_SUCCESSES"
  echo "PG_DANGLING_BLOCKED_COUNT=$BLOCKED_COUNT"
  echo "PG_DANGLING_AMBIGUOUS_COUNT=$AMBIGUOUS_COUNT"
  echo "PG_DANGLING_MISSING_EXACT_COUNT=$MISSING_COUNT"
  echo "INITIAL_DRC=$INITIAL_DRC"
  echo "FINAL_DRC=$FINAL_DRC"
  echo "INITIAL_SHORTS=$INITIAL_SHORTS"
  echo "FINAL_SHORTS=$FINAL_SHORTS"
  echo "INITIAL_REGULAR_CONNECTIVITY_BAD=$INITIAL_REGULAR"
  echo "FINAL_REGULAR_CONNECTIVITY_BAD=$FINAL_REGULAR"
  echo "PG_EDIT_COUNT=0"
  echo "SIGNOFF_ELIGIBLE=NO"
  echo "DECISION=$DECISION"
  echo "NEXT_STAGE=$NEXT_STAGE"
} | tee "$RUN_DIR/reports/operator_gate_ro6_pg_endpoint_probe.rpt"

publish_stage
PUBLISH_RC=$?
if [[ "$PUBLISH_RC" -ne 0 ]]; then
  DECISION=FAIL_STOP
  NEXT_STAGE=REPUBLISH_RO6_PG_ENDPOINT_PROBE_EVIDENCE
fi

echo "RO6_PG_ENDPOINT_PROBE_STATUS=$([[ "$DECISION" == PASS_REVIEW_ENDPOINTS ]] && echo PASS || echo FAIL)"
echo "RECOVERY_RUN_ID=$RUN_ID"
echo "SOURCE_PNR_RUN_ID=$SOURCE_PNR_RUN_ID"
echo "BOUNDARY_PVS_RUN_ID=$BOUNDARY_PVS_RUN_ID"
echo "PROBE_RC=$PROBE_RC"
echo "MARKER_COUNT=$MARKER_COUNT"
echo "AMBIGUOUS_COUNT=$AMBIGUOUS_COUNT"
echo "MISSING_EXACT_COUNT=$MISSING_COUNT"
echo "DECISION=$DECISION"
echo "PUBLISH_RC=$PUBLISH_RC"
echo "NEXT_EXPECTED_HEAD=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null)"
echo "NEXT_STAGE=$NEXT_STAGE"

if [[ "$DECISION" == PASS_REVIEW_ENDPOINTS && "$PUBLISH_RC" -eq 0 ]]; then
  exit 0
fi
exit 1
