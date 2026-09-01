#!/usr/bin/env bash
# Re-run only PVS LVS with an explicit RO_tune6 digital-top blackbox boundary.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
REPO_ROOT="${MPTDC_BOUNDARY_LVS_REPO_ROOT:-$DEFAULT_REPO_ROOT}"
PUBLISHER="${MPTDC_BOUNDARY_LVS_PUBLISHER:-$REPO_ROOT/MPTDC/ci/publish_mptdc_server_snapshot.sh}"
LVS_SCRIPT="${MPTDC_BOUNDARY_LVS_REPLAY:-$SCRIPT_DIR/03_replay_pvs_lvs_from_template.sh}"
RAW_CLASSIFIER="${MPTDC_BOUNDARY_RAW_CLASSIFIER:-$SCRIPT_DIR/15_classify_ro6_raw_mismatch.py}"
INNOVUS_WORK="${MPTDC_INNOVUS_WORK:-/sim/ksabra/SPADMIC_work/innovus}"
ALLOW_TEST_OVERRIDES="${MPTDC_BOUNDARY_ALLOW_TEST_OVERRIDES:-0}"

SOURCE_PVS_RUN_ID=""
SOURCE_PVS_EVIDENCE_ID=""
STANDALONE_PVS_RUN_ID=""
PVS_RUN_ID=""
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD:-}"
HIERARCHICAL_LVS_SIGNOFF=0
RAW_CLASSIFICATION_TMP=""

cleanup() {
  [[ -z "$RAW_CLASSIFICATION_TMP" ]] || rm -f "$RAW_CLASSIFICATION_TMP"
}
trap cleanup EXIT

usage() {
  cat <<'USAGE'
Usage:
  server_run_mptdc_ro6_boundary_lvs.sh --source-pvs-run-id <id> \
    --standalone-pvs-run-id <id> [options]

Options:
  --source-pvs-run-id <id>  Existing published diagnostic PVS run whose exact
                            GDS/source/CDL/HCell tuple will be reused read-only.
  --source-pvs-evidence-id <id>
                            Tracked source snapshot; defaults to
                            <source-pvs-run-id>_04_lvs.
  --standalone-pvs-run-id <id>
                            Published explicit-MATCH standalone RO_tune6 LVS
                            run using the same RO GDS hash.
  --hierarchical-lvs-signoff
                            Emit the final hierarchical LVS gate only after an
                            exact top RO black-box MATCH, strict raw mismatch
                            attribution, and the same-hash standalone RO MATCH.
  --run-id <id>             New LVS-only result directory name.
  --expected-head <sha>     Require repository HEAD to match this commit.
  --innovus-work <path>     Innovus/PVS result root.
  -h, --help                Show this help.

The default mode remains diagnostic. --hierarchical-lvs-signoff composes the
top boundary proof with the independently matched RO internals. It does not
run DRC and never marks final physical signoff ready.
USAGE
}

report_value() {
  local report="$1"
  local key="$2"
  local value
  value="$(sed -n "s/^${key}=//p" "$report" 2>/dev/null | tail -1)"
  if [[ -n "$value" ]]; then printf '%s\n' "$value"; else printf 'MISSING\n'; fi
}

tracked_report() {
  local report="$1" rel="${1#"$REPO_ROOT"/}"
  git -C "$REPO_ROOT" ls-files --error-unmatch "$rel" >/dev/null 2>&1 && [[ -s "$report" ]]
}

tracked_file() {
  local path="$1" rel="${1#"$REPO_ROOT"/}"
  git -C "$REPO_ROOT" ls-files --error-unmatch "$rel" >/dev/null 2>&1 && [[ -f "$path" ]]
}

publish_stage() {
  local snapshot_id="$1"
  MPTDC_SNAPSHOT_MAX_TEXT_BYTES=8388608 \
    bash "$PUBLISHER" pvs "$snapshot_id" "$PVS_DIR" PVS_RO6_BOUNDARY_LVS
  local rc=$?
  EXPECTED_HEAD_VALUE="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null)"
  return "$rc"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-pvs-run-id) SOURCE_PVS_RUN_ID="${2:?missing --source-pvs-run-id value}"; shift 2 ;;
    --source-pvs-evidence-id) SOURCE_PVS_EVIDENCE_ID="${2:?missing --source-pvs-evidence-id value}"; shift 2 ;;
    --standalone-pvs-run-id) STANDALONE_PVS_RUN_ID="${2:?missing --standalone-pvs-run-id value}"; shift 2 ;;
    --hierarchical-lvs-signoff) HIERARCHICAL_LVS_SIGNOFF=1; shift ;;
    --run-id) PVS_RUN_ID="${2:?missing --run-id value}"; shift 2 ;;
    --expected-head) EXPECTED_HEAD_VALUE="${2:?missing --expected-head value}"; shift 2 ;;
    --innovus-work) INNOVUS_WORK="${2:?missing --innovus-work value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$SOURCE_PVS_RUN_ID" && -n "$STANDALONE_PVS_RUN_ID" ]] || {
  echo "ERROR: --source-pvs-run-id and --standalone-pvs-run-id are required" >&2
  usage >&2
  exit 2
}
[[ -n "$SOURCE_PVS_EVIDENCE_ID" ]] || SOURCE_PVS_EVIDENCE_ID="${SOURCE_PVS_RUN_ID}_04_lvs"
[[ "$SOURCE_PVS_RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "ERROR: unsafe source PVS run id" >&2; exit 2; }
[[ "$SOURCE_PVS_EVIDENCE_ID" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "ERROR: unsafe source PVS evidence id" >&2; exit 2; }
[[ "$STANDALONE_PVS_RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "ERROR: unsafe standalone PVS run id" >&2; exit 2; }
[[ "$ALLOW_TEST_OVERRIDES" =~ ^[01]$ ]] || { echo "ERROR: invalid test override selector" >&2; exit 2; }
if [[ -z "$PVS_RUN_ID" ]]; then
  PVS_RUN_ID="$(date +%Y%m%d)_mptdc_bufftap0_ro6_boundary_lvs_$(date +%H%M%S)"
fi
[[ "$PVS_RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "ERROR: unsafe PVS run id" >&2; exit 2; }

SOURCE_PVS_DIR="$INNOVUS_WORK/$SOURCE_PVS_RUN_ID"
STANDALONE_PVS_DIR="$INNOVUS_WORK/$STANDALONE_PVS_RUN_ID"
PVS_DIR="$INNOVUS_WORK/$PVS_RUN_ID"
SOURCE_SNAPSHOT="$REPO_ROOT/MPTDC/docs/server_snapshots/pvs/$SOURCE_PVS_EVIDENCE_ID"
STANDALONE_SNAPSHOT="$REPO_ROOT/MPTDC/docs/server_snapshots/pvs/$STANDALONE_PVS_RUN_ID"
SOURCE_GDS="$SOURCE_PVS_DIR/outputs/mptdc_axis_core_merged_stdcell_ro6.gds"
SOURCE_VERILOG="$SOURCE_PVS_DIR/outputs/mptdc_axis_core_pnr_lvs_with_pg_NO_DCELL_MODULES_RO6_PINFIX_NOATTR_CLEAN.v"
SOURCE_HCELL="$SOURCE_PVS_DIR/outputs/pvs_hcell_ro6.txt"
SOURCE_HASH_MANIFEST="$SOURCE_PVS_DIR/manifests/pvs_input_hashes.rpt"
SOURCE_FILTER_REPORT="$SOURCE_PVS_DIR/reports/lvs_source_filter.rpt"
SOURCE_LVS_STATUS_REPORT="$SOURCE_PVS_DIR/reports/pvs_lvs_status.rpt"
SOURCE_LVS_TOOL_STATUS_REPORT="$SOURCE_PVS_DIR/reports/pvs_lvs_tool_status.rpt"
SOURCE_OPERATOR_GATE_REPORT="$SOURCE_PVS_DIR/reports/operator_gate_pvs_lvs.rpt"
STANDALONE_GATE_REPORT="$STANDALONE_PVS_DIR/reports/operator_gate_pvs_ro6_standalone_lvs.rpt"
STANDALONE_MANIFEST="$STANDALONE_PVS_DIR/manifests/ro6_standalone_lvs_inputs.rpt"
SOURCE_HASH_MANIFEST_TRACKED="$SOURCE_SNAPSHOT/manifests/pvs_input_hashes.rpt"
SOURCE_FILTER_REPORT_TRACKED="$SOURCE_SNAPSHOT/reports/lvs_source_filter.rpt"
SOURCE_LVS_STATUS_REPORT_TRACKED="$SOURCE_SNAPSHOT/reports/pvs_lvs_status.rpt"
SOURCE_LVS_TOOL_STATUS_REPORT_TRACKED="$SOURCE_SNAPSHOT/reports/pvs_lvs_tool_status.rpt"
SOURCE_OPERATOR_GATE_REPORT_TRACKED="$SOURCE_SNAPSHOT/reports/operator_gate_pvs_lvs.rpt"
STANDALONE_GATE_REPORT_TRACKED="$STANDALONE_SNAPSHOT/reports/operator_gate_pvs_ro6_standalone_lvs.rpt"
STANDALONE_MANIFEST_TRACKED="$STANDALONE_SNAPSHOT/manifests/ro6_standalone_lvs_inputs.rpt"

cd "$REPO_ROOT" || exit 3
ACTUAL_HEAD="$(git rev-parse HEAD 2>/dev/null)"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
ORIGIN_HEAD="$(git rev-parse refs/remotes/origin/SPADMIC_test 2>/dev/null || true)"
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD_VALUE:-${ORIGIN_HEAD:-$ACTUAL_HEAD}}"
TRACKED_STATUS="$(git status --short --untracked-files=no 2>/dev/null)"

SOURCE_LVS_RUN=""
SOURCE_LVS_RUN_COUNT=0
SOURCE_CLS=""
SOURCE_CLS_COUNT=0
SOURCE_CLS_RUN_RESULT=MISSING
SOURCE_MISMATCHED_MARKER_COUNT=0
SOURCE_MATCHED_MARKER_COUNT=0
if [[ -d "$SOURCE_PVS_DIR/pvs_lvs" ]]; then
  SOURCE_LVS_RUN_COUNT="$(find "$SOURCE_PVS_DIR/pvs_lvs" -mindepth 1 -maxdepth 1 -type d -exec test -s '{}/run.pvs' ';' -print 2>/dev/null | wc -l | tr -d ' ')"
  if [[ "$SOURCE_LVS_RUN_COUNT" == 1 ]]; then
    SOURCE_LVS_RUN="$(find "$SOURCE_PVS_DIR/pvs_lvs" -mindepth 1 -maxdepth 1 -type d -exec test -s '{}/run.pvs' ';' -print -quit 2>/dev/null)"
    SOURCE_CLS_COUNT="$(find "$SOURCE_LVS_RUN" -type f -name '*.cls' 2>/dev/null | wc -l | tr -d ' ')"
    if [[ "$SOURCE_CLS_COUNT" == 1 ]]; then
      SOURCE_CLS="$(find "$SOURCE_LVS_RUN" -type f -name '*.cls' -print -quit)"
      SOURCE_CLS_RUN_RESULT="$(awk -F ':' '/Run Result/ {value=$2; gsub(/[^[:alnum:]_]/, "", value); print toupper(value); exit}' "$SOURCE_CLS")"
      [[ -n "$SOURCE_CLS_RUN_RESULT" ]] || SOURCE_CLS_RUN_RESULT=MISSING
    fi
    SOURCE_MISMATCHED_MARKER_COUNT="$(find "$SOURCE_LVS_RUN" -type f -name mismatched 2>/dev/null | wc -l | tr -d ' ')"
    SOURCE_MATCHED_MARKER_COUNT="$(find "$SOURCE_LVS_RUN" -type f -name matched 2>/dev/null | wc -l | tr -d ' ')"
  fi
fi

SOURCE_LVS_RUN_TRACKED=""
SOURCE_LVS_RUN_TRACKED_COUNT=0
SOURCE_CLS_TRACKED=""
SOURCE_CLS_TRACKED_COUNT=0
if [[ -d "$SOURCE_SNAPSHOT/pvs_lvs" ]]; then
  mapfile -t SOURCE_LVS_RUNS_TRACKED < <(
    find "$SOURCE_SNAPSHOT/pvs_lvs" -mindepth 1 -maxdepth 1 -type d \
      -exec test -s '{}/run.pvs' ';' -exec test -s '{}/pvslvsctl' ';' \
      -exec test -f '{}/.config.rul' ';' -exec test -s '{}/.technology.rul' ';' \
      -print 2>/dev/null
  )
  SOURCE_LVS_RUN_TRACKED_COUNT="${#SOURCE_LVS_RUNS_TRACKED[@]}"
  SOURCE_LVS_RUN_TRACKED="${SOURCE_LVS_RUNS_TRACKED[0]:-}"
fi
if [[ "$SOURCE_LVS_RUN_TRACKED_COUNT" == 1 ]]; then
  mapfile -t SOURCE_CLS_TRACKED_FILES < <(
    find "$SOURCE_LVS_RUN_TRACKED" -type f -name '*.cls' -print 2>/dev/null
  )
  SOURCE_CLS_TRACKED_COUNT="${#SOURCE_CLS_TRACKED_FILES[@]}"
  SOURCE_CLS_TRACKED="${SOURCE_CLS_TRACKED_FILES[0]:-}"
fi

STANDALONE_LVS_RUN_TRACKED=""
STANDALONE_LVS_RUN_TRACKED_COUNT=0
STANDALONE_CLS_TRACKED=""
STANDALONE_CLS_TRACKED_COUNT=0
if [[ -d "$STANDALONE_SNAPSHOT/pvs_lvs" ]]; then
  mapfile -t STANDALONE_LVS_RUNS_TRACKED < <(
    find "$STANDALONE_SNAPSHOT/pvs_lvs" -mindepth 1 -maxdepth 1 -type d \
      -exec test -s '{}/run.pvs' ';' -exec test -s '{}/pvslvsctl' ';' \
      -exec test -f '{}/.config.rul' ';' -exec test -s '{}/.technology.rul' ';' \
      -print 2>/dev/null
  )
  STANDALONE_LVS_RUN_TRACKED_COUNT="${#STANDALONE_LVS_RUNS_TRACKED[@]}"
  STANDALONE_LVS_RUN_TRACKED="${STANDALONE_LVS_RUNS_TRACKED[0]:-}"
fi
if [[ "$STANDALONE_LVS_RUN_TRACKED_COUNT" == 1 ]]; then
  mapfile -t STANDALONE_CLS_TRACKED_FILES < <(
    find "$STANDALONE_LVS_RUN_TRACKED" -type f -name '*.cls' -print 2>/dev/null
  )
  STANDALONE_CLS_TRACKED_COUNT="${#STANDALONE_CLS_TRACKED_FILES[@]}"
  STANDALONE_CLS_TRACKED="${STANDALONE_CLS_TRACKED_FILES[0]:-}"
fi

SOURCE_GATE_LVS_STATUS="$(report_value "$SOURCE_LVS_STATUS_REPORT" PVS_LVS_STATUS)"
SOURCE_PVS_RC="$(report_value "$SOURCE_LVS_TOOL_STATUS_REPORT" PVS_LVS_RC)"
SOURCE_RO_GDS_SHA256="$(report_value "$SOURCE_HASH_MANIFEST" RO_GDS_SHA256)"
SOURCE_CONTRACT_STATUS="$(report_value "$SOURCE_FILTER_REPORT" LVS_SOURCE_CONTRACT_STATUS)"
SOURCE_KIND="$(report_value "$SOURCE_FILTER_REPORT" SOURCE_KIND)"
SOURCE_MODULE_REMOVAL_POLICY="$(report_value "$SOURCE_FILTER_REPORT" MODULE_REMOVAL_POLICY)"
SOURCE_PHYSICAL_ONLY_REMOVAL_POLICY="$(report_value "$SOURCE_FILTER_REPORT" PHYSICAL_ONLY_INSTANCE_REMOVAL_POLICY)"
SOURCE_FILLER_COUNT_EXPECTED="$(report_value "$SOURCE_FILTER_REPORT" PHYSICAL_ONLY_FILLER_INSTANCE_COUNT_EXPECTED)"
SOURCE_FILLER_COUNT_INPUT="$(report_value "$SOURCE_FILTER_REPORT" PHYSICAL_ONLY_FILLER_INSTANCE_COUNT_INPUT)"
SOURCE_FILLER_COUNT_REMOVED="$(report_value "$SOURCE_FILTER_REPORT" PHYSICAL_ONLY_FILLER_INSTANCE_COUNT_REMOVED)"
SOURCE_FILLER_REMOVAL_STATUS="$(report_value "$SOURCE_FILTER_REPORT" PHYSICAL_ONLY_FILLER_REMOVAL_STATUS)"
SOURCE_RO6_PIN_NORMALIZATION="$(report_value "$SOURCE_FILTER_REPORT" RO6_PIN_NORMALIZATION)"
SOURCE_RO6_INSTANCE_COUNT="$(report_value "$SOURCE_FILTER_REPORT" RO_TUNE6_INSTANCE_COUNT)"
SOURCE_RO6_INSTANCE_NAME_STATUS="$(report_value "$SOURCE_FILTER_REPORT" RO_TUNE6_INSTANCE_NAME_STATUS)"
SOURCE_PHYSICAL_TIE_INSTANCE_COUNT="$(report_value "$SOURCE_FILTER_REPORT" PHYSICAL_TIE_INSTANCE_COUNT)"
SOURCE_PHYSICAL_TIE_PRESERVATION_STATUS="$(report_value "$SOURCE_FILTER_REPORT" PHYSICAL_TIE_PRESERVATION_STATUS)"
SOURCE_UNRESOLVED_MASTER_COUNT="$(report_value "$SOURCE_FILTER_REPORT" UNRESOLVED_ACTIVE_MASTER_COUNT)"
STANDALONE_LVS_STATUS="$(report_value "$STANDALONE_GATE_REPORT" PVS_LVS)"
STANDALONE_DECISION="$(report_value "$STANDALONE_GATE_REPORT" DECISION)"
STANDALONE_OA_READ_ONLY_STATUS="$(report_value "$STANDALONE_GATE_REPORT" OA_READ_ONLY_STATUS)"
STANDALONE_CDL_PIN_STATUS="$(report_value "$STANDALONE_GATE_REPORT" RO6_CDL_PIN_CONTRACT_STATUS)"
STANDALONE_SIGNOFF_ELIGIBLE="$(report_value "$STANDALONE_GATE_REPORT" SIGNOFF_ELIGIBLE)"
STANDALONE_RO_GDS_SHA256="$(report_value "$STANDALONE_MANIFEST" RO_GDS_SHA256)"
STANDALONE_RO_CDL_SHA256="$(report_value "$STANDALONE_MANIFEST" RO_CDL_SHA256)"
SOURCE_BLACKBOXED_CELL_COUNT=MISSING
SOURCE_RO6_WRAPPER_MISMATCH_COUNT=0
if [[ -s "$SOURCE_CLS" ]]; then
  SOURCE_BLACKBOXED_CELL_COUNT="$(awk -F '|' '/Cells that have been blackboxed/ {value=$2; gsub(/[[:space:]]/, "", value); print value; exit}' "$SOURCE_CLS")"
  [[ -n "$SOURCE_BLACKBOXED_CELL_COUNT" ]] || SOURCE_BLACKBOXED_CELL_COUNT=MISSING
  SOURCE_RO6_WRAPPER_MISMATCH_COUNT="$(grep -Fc '(-, RO_tune6())' "$SOURCE_CLS" 2>/dev/null || true)"
fi

SOURCE_GDS_EXPECTED_SHA256="$(report_value "$SOURCE_HASH_MANIFEST" MERGED_GDS_SHA256)"
SOURCE_VERILOG_EXPECTED_SHA256="$(report_value "$SOURCE_HASH_MANIFEST" LVS_SOURCE_FILTERED_SHA256)"
SOURCE_HCELL_EXPECTED_SHA256="$(report_value "$SOURCE_HASH_MANIFEST" LVS_HCELL_SHA256)"
STANDALONE_RO_GDS="$(report_value "$STANDALONE_MANIFEST" LOCAL_RO_GDS)"
STANDALONE_RO_CDL="$(report_value "$STANDALONE_MANIFEST" LOCAL_RO_CDL)"

STANDALONE_CLS_RUN_RESULT=MISSING
STANDALONE_BLACKBOXED_CELL_COUNT=MISSING
STANDALONE_RO6_PIN_MATCH_COUNT=0
STANDALONE_CLS_SHA256=MISSING
if [[ -s "$STANDALONE_CLS_TRACKED" ]]; then
  STANDALONE_CLS_RUN_RESULT="$(awk -F ':' '/Run Result/ {value=$2; gsub(/[^[:alnum:]_]/, "", value); print toupper(value); exit}' "$STANDALONE_CLS_TRACKED")"
  STANDALONE_BLACKBOXED_CELL_COUNT="$(awk -F '|' '/Cells that have been blackboxed/ {value=$2; gsub(/[[:space:]]/, "", value); print value; exit}' "$STANDALONE_CLS_TRACKED")"
  STANDALONE_RO6_PIN_MATCH_COUNT="$(grep -Ec '^RO_tune6[[:space:]]*\|[[:space:]]*19[[:space:]]*:[[:space:]]*19[[:space:]]*\|[[:space:]]*19[[:space:]]*:[[:space:]]*19[[:space:]]*\|[[:space:]]*match' "$STANDALONE_CLS_TRACKED" || true)"
  STANDALONE_CLS_SHA256="$(sha256sum "$STANDALONE_CLS_TRACKED" | awk '{print $1}')"
fi

RAW_CLASSIFIER_RC=NOT_RUN
RAW_ATTRIBUTION_STATUS=NOT_RUN
RAW_MISMATCH_ATTRIBUTION=NOT_RUN
RAW_HIERARCHICAL_ELIGIBLE=NOT_RUN
RAW_LAYOUT_ONLY_COUNT=NOT_RUN
RAW_SOURCE_ONLY_COUNT=NOT_RUN
RAW_LAYOUT_CLUSTER_COUNT=NOT_RUN
RAW_CLASSIFIED_CLS_SHA256=MISSING
RAW_CLASSIFIER_SHA256=MISSING
RAW_CLASSIFICATION_SHA256=MISSING
if [[ "$HIERARCHICAL_LVS_SIGNOFF" -eq 1 && -s "$SOURCE_CLS" && -s "$RAW_CLASSIFIER" ]]; then
  RAW_CLASSIFICATION_TMP="$(mktemp /tmp/mptdc_ro6_boundary_raw.XXXXXX.rpt)"
  set +e
  python3 "$RAW_CLASSIFIER" \
    --cls "$SOURCE_CLS" \
    --out "$RAW_CLASSIFICATION_TMP" \
    --expected-ro-instance u_core_u_osc_fast_u_ro_tune4 \
    --expected-ro-instance u_core_u_osc_slow_u_ro_tune4
  RAW_CLASSIFIER_RC=$?
  set +e
  RAW_ATTRIBUTION_STATUS="$(report_value "$RAW_CLASSIFICATION_TMP" STATUS)"
  RAW_MISMATCH_ATTRIBUTION="$(report_value "$RAW_CLASSIFICATION_TMP" MISMATCH_ATTRIBUTION)"
  RAW_HIERARCHICAL_ELIGIBLE="$(report_value "$RAW_CLASSIFICATION_TMP" HIERARCHICAL_COMPOSITION_ELIGIBLE)"
  RAW_LAYOUT_ONLY_COUNT="$(report_value "$RAW_CLASSIFICATION_TMP" LAYOUT_ONLY_INSTANCE_COUNT)"
  RAW_SOURCE_ONLY_COUNT="$(report_value "$RAW_CLASSIFICATION_TMP" SOURCE_ONLY_INSTANCE_COUNT)"
  RAW_LAYOUT_CLUSTER_COUNT="$(report_value "$RAW_CLASSIFICATION_TMP" RO_LAYOUT_CLUSTER_COUNT)"
  RAW_CLASSIFIED_CLS_SHA256="$(report_value "$RAW_CLASSIFICATION_TMP" CLS_SHA256)"
  RAW_CLASSIFIER_SHA256="$(sha256sum "$RAW_CLASSIFIER" | awk '{print $1}')"
  RAW_CLASSIFICATION_SHA256="$(sha256sum "$RAW_CLASSIFICATION_TMP" | awk '{print $1}')"
fi

echo "SOURCE_PVS_RUN_ID=$SOURCE_PVS_RUN_ID"
echo "SOURCE_PVS_EVIDENCE_ID=$SOURCE_PVS_EVIDENCE_ID"
echo "SOURCE_PVS_DIR=$SOURCE_PVS_DIR"
echo "SOURCE_LVS_RUN=$SOURCE_LVS_RUN"
echo "SOURCE_GATE_LVS_STATUS=$SOURCE_GATE_LVS_STATUS"
echo "SOURCE_CLS_RUN_RESULT=$SOURCE_CLS_RUN_RESULT"
echo "SOURCE_PVS_RC=$SOURCE_PVS_RC"
echo "SOURCE_MISMATCHED_MARKER_COUNT=$SOURCE_MISMATCHED_MARKER_COUNT"
echo "SOURCE_MATCHED_MARKER_COUNT=$SOURCE_MATCHED_MARKER_COUNT"
echo "SOURCE_BLACKBOXED_CELL_COUNT=$SOURCE_BLACKBOXED_CELL_COUNT"
echo "SOURCE_RO6_WRAPPER_MISMATCH_COUNT=$SOURCE_RO6_WRAPPER_MISMATCH_COUNT"
echo "SOURCE_CONTRACT_STATUS=$SOURCE_CONTRACT_STATUS"
echo "SOURCE_KIND=$SOURCE_KIND"
echo "SOURCE_RO6_INSTANCE_NAME_STATUS=$SOURCE_RO6_INSTANCE_NAME_STATUS"
echo "SOURCE_PHYSICAL_ONLY_REMOVAL_POLICY=$SOURCE_PHYSICAL_ONLY_REMOVAL_POLICY"
echo "SOURCE_FILLER_COUNT_EXPECTED=$SOURCE_FILLER_COUNT_EXPECTED"
echo "SOURCE_FILLER_COUNT_INPUT=$SOURCE_FILLER_COUNT_INPUT"
echo "SOURCE_FILLER_COUNT_REMOVED=$SOURCE_FILLER_COUNT_REMOVED"
echo "SOURCE_FILLER_REMOVAL_STATUS=$SOURCE_FILLER_REMOVAL_STATUS"
echo "SOURCE_PHYSICAL_TIE_INSTANCE_COUNT=$SOURCE_PHYSICAL_TIE_INSTANCE_COUNT"
echo "SOURCE_PHYSICAL_TIE_PRESERVATION_STATUS=$SOURCE_PHYSICAL_TIE_PRESERVATION_STATUS"
echo "SOURCE_UNRESOLVED_MASTER_COUNT=$SOURCE_UNRESOLVED_MASTER_COUNT"
echo "STANDALONE_PVS_RUN_ID=$STANDALONE_PVS_RUN_ID"
echo "STANDALONE_LVS_STATUS=$STANDALONE_LVS_STATUS"
echo "STANDALONE_OA_READ_ONLY_STATUS=$STANDALONE_OA_READ_ONLY_STATUS"
echo "STANDALONE_CDL_PIN_STATUS=$STANDALONE_CDL_PIN_STATUS"
echo "SOURCE_RO_GDS_SHA256=$SOURCE_RO_GDS_SHA256"
echo "STANDALONE_RO_GDS_SHA256=$STANDALONE_RO_GDS_SHA256"
echo "STANDALONE_RO_CDL_SHA256=$STANDALONE_RO_CDL_SHA256"
echo "HIERARCHICAL_LVS_SIGNOFF=$HIERARCHICAL_LVS_SIGNOFF"
echo "RAW_MISMATCH_ATTRIBUTION=$RAW_MISMATCH_ATTRIBUTION"
echo "RAW_HIERARCHICAL_ELIGIBLE=$RAW_HIERARCHICAL_ELIGIBLE"
echo "PVS_RUN_ID=$PVS_RUN_ID"
echo "PVS_DIR=$PVS_DIR"
echo "BRANCH=$BRANCH"
echo "ACTUAL_HEAD=$ACTUAL_HEAD"
echo "ORIGIN_HEAD=${ORIGIN_HEAD:-MISSING}"
echo "EXPECTED_HEAD=$EXPECTED_HEAD_VALUE"

PREFLIGHT=PASS
[[ "$BRANCH" == SPADMIC_test ]] || { echo "STOP: branch must be SPADMIC_test"; PREFLIGHT=FAIL; }
[[ "$ACTUAL_HEAD" == "$EXPECTED_HEAD_VALUE" ]] || { echo "STOP: HEAD mismatch"; PREFLIGHT=FAIL; }
[[ -z "$TRACKED_STATUS" ]] || { echo "$TRACKED_STATUS"; echo "STOP: tracked working tree is dirty"; PREFLIGHT=FAIL; }
[[ "$SOURCE_LVS_RUN_COUNT" == 1 ]] || { echo "STOP: expected exactly one source LVS run, found $SOURCE_LVS_RUN_COUNT"; PREFLIGHT=FAIL; }
[[ "$SOURCE_CLS_COUNT" == 1 ]] || { echo "STOP: expected exactly one source .cls report, found $SOURCE_CLS_COUNT"; PREFLIGHT=FAIL; }
[[ "$SOURCE_GATE_LVS_STATUS" == MISMATCH || "$SOURCE_GATE_LVS_STATUS" == NOT_PROVEN ]] || {
  echo "STOP: source gate status conflicts with an LVS mismatch candidate"
  PREFLIGHT=FAIL
}
[[ "$SOURCE_CLS_RUN_RESULT" == MISMATCH && "$SOURCE_PVS_RC" == 0 ]] || {
  echo "STOP: source must have raw CLS MISMATCH and tool RC zero"
  PREFLIGHT=FAIL
}
[[ "$SOURCE_MISMATCHED_MARKER_COUNT" -ge 1 && "$SOURCE_MATCHED_MARKER_COUNT" == 0 ]] || {
  echo "STOP: source SVDB does not contain the unique mismatch state"
  PREFLIGHT=FAIL
}
[[ "$SOURCE_BLACKBOXED_CELL_COUNT" == 0 && "$SOURCE_RO6_WRAPPER_MISMATCH_COUNT" -ge 1 ]] || {
  echo "STOP: source mismatch is not the expected un-blackboxed RO_tune6 boundary signature"
  PREFLIGHT=FAIL
}
[[ "$SOURCE_CONTRACT_STATUS" == PASS && \
   "$SOURCE_KIND" == INNOVUS_SAVE_NETLIST_PHYS_INCLUDE_POWER_GROUND && \
   "$SOURCE_MODULE_REMOVAL_POLICY" == EXACT_CANONICAL_CDL_MEMBERSHIP && \
   "$SOURCE_PHYSICAL_ONLY_REMOVAL_POLICY" == EXACT_TRACKED_FILLER_REPORT_MASTER_SET && \
   "$SOURCE_FILLER_COUNT_EXPECTED" =~ ^[0-9]+$ && \
   "$SOURCE_FILLER_COUNT_EXPECTED" -gt 0 && \
   "$SOURCE_FILLER_COUNT_INPUT" == "$SOURCE_FILLER_COUNT_EXPECTED" && \
   "$SOURCE_FILLER_COUNT_REMOVED" == "$SOURCE_FILLER_COUNT_EXPECTED" && \
   "$SOURCE_FILLER_REMOVAL_STATUS" == PASS && \
   "$SOURCE_RO6_PIN_NORMALIZATION" == EXACT_SAME_INDEX_SCALAR_ANGLE_PORTS && \
   "$SOURCE_RO6_INSTANCE_COUNT" == 2 && \
   "$SOURCE_RO6_INSTANCE_NAME_STATUS" == PASS && \
   "$SOURCE_PHYSICAL_TIE_INSTANCE_COUNT" =~ ^[0-9]+$ && \
   "$SOURCE_PHYSICAL_TIE_PRESERVATION_STATUS" == PASS && \
   "$SOURCE_UNRESOLVED_MASTER_COUNT" == 0 ]] || {
  echo "STOP: source is not the attributable physical PG/tie LVS contract"
  PREFLIGHT=FAIL
}
[[ "$STANDALONE_LVS_STATUS" == MATCH && "$STANDALONE_DECISION" == PASS_CONTINUE && \
   "$STANDALONE_OA_READ_ONLY_STATUS" == PASS && "$STANDALONE_CDL_PIN_STATUS" == PASS && \
   "$STANDALONE_SIGNOFF_ELIGIBLE" == NO ]] || {
  echo "STOP: standalone RO_tune6 LVS proof is missing or not an explicit attributable MATCH"
  PREFLIGHT=FAIL
}
[[ "$SOURCE_RO_GDS_SHA256" =~ ^[0-9a-f]{64}$ && \
   "$SOURCE_RO_GDS_SHA256" == "$STANDALONE_RO_GDS_SHA256" ]] || {
  echo "STOP: boundary source and standalone proof do not use the same RO GDS hash"
  PREFLIGHT=FAIL
}
[[ "$STANDALONE_RO_CDL_SHA256" =~ ^[0-9a-f]{64}$ ]] || {
  echo "STOP: standalone proof has no attributable RO CDL hash"
  PREFLIGHT=FAIL
}
for path in "$SOURCE_GDS" "$SOURCE_VERILOG" "$SOURCE_HCELL" "$SOURCE_HASH_MANIFEST" "$SOURCE_FILTER_REPORT" "$PUBLISHER" "$LVS_SCRIPT"; do
  [[ -s "$path" ]] || { echo "STOP: required source or script missing: $path"; PREFLIGHT=FAIL; }
done

SOURCE_CLS_SHA256="$(sha256sum "$SOURCE_CLS" 2>/dev/null | awk '{print $1}')"
SOURCE_GDS_SHA256="$(sha256sum "$SOURCE_GDS" 2>/dev/null | awk '{print $1}')"
SOURCE_VERILOG_SHA256="$(sha256sum "$SOURCE_VERILOG" 2>/dev/null | awk '{print $1}')"
SOURCE_HCELL_SHA256="$(sha256sum "$SOURCE_HCELL" 2>/dev/null | awk '{print $1}')"
STANDALONE_RO_GDS_ACTUAL_SHA256="$(sha256sum "$STANDALONE_RO_GDS" 2>/dev/null | awk '{print $1}')"
STANDALONE_RO_CDL_ACTUAL_SHA256="$(sha256sum "$STANDALONE_RO_CDL" 2>/dev/null | awk '{print $1}')"

if [[ "$HIERARCHICAL_LVS_SIGNOFF" -eq 1 ]]; then
  if [[ "$ALLOW_TEST_OVERRIDES" == 1 && "$REPO_ROOT" != /tmp/* ]]; then
    echo "STOP: hierarchical test overrides are restricted to temporary fixture repositories"
    PREFLIGHT=FAIL
  fi
  if [[ "$ALLOW_TEST_OVERRIDES" != 1 ]]; then
    [[ "$RAW_CLASSIFIER" == "$SCRIPT_DIR/15_classify_ro6_raw_mismatch.py" && \
       "$LVS_SCRIPT" == "$SCRIPT_DIR/03_replay_pvs_lvs_from_template.sh" && \
       "$PUBLISHER" == "$REPO_ROOT/MPTDC/ci/publish_mptdc_server_snapshot.sh" ]] || {
      echo "STOP: hierarchical signoff forbids classifier, replay, or publisher overrides"
      PREFLIGHT=FAIL
    }
    for tool in "$RAW_CLASSIFIER" "$LVS_SCRIPT" "$PUBLISHER"; do
      tracked_report "$tool" || {
        echo "STOP: hierarchical signoff tool is not tracked and nonempty: $tool"
        PREFLIGHT=FAIL
      }
    done
  fi
  for report in "$SOURCE_HASH_MANIFEST_TRACKED" "$SOURCE_FILTER_REPORT_TRACKED" \
                "$SOURCE_LVS_STATUS_REPORT_TRACKED" "$SOURCE_LVS_TOOL_STATUS_REPORT_TRACKED" \
                "$SOURCE_OPERATOR_GATE_REPORT_TRACKED" \
                "$STANDALONE_GATE_REPORT_TRACKED" "$STANDALONE_MANIFEST_TRACKED"; do
    tracked_report "$report" || {
      echo "STOP: immutable tracked hierarchical LVS report missing: $report"
      PREFLIGHT=FAIL
    }
  done
  for pair in \
    "$SOURCE_HASH_MANIFEST:$SOURCE_HASH_MANIFEST_TRACKED" \
    "$SOURCE_FILTER_REPORT:$SOURCE_FILTER_REPORT_TRACKED" \
    "$SOURCE_LVS_STATUS_REPORT:$SOURCE_LVS_STATUS_REPORT_TRACKED" \
    "$SOURCE_LVS_TOOL_STATUS_REPORT:$SOURCE_LVS_TOOL_STATUS_REPORT_TRACKED" \
    "$SOURCE_OPERATOR_GATE_REPORT:$SOURCE_OPERATOR_GATE_REPORT_TRACKED" \
    "$STANDALONE_GATE_REPORT:$STANDALONE_GATE_REPORT_TRACKED" \
    "$STANDALONE_MANIFEST:$STANDALONE_MANIFEST_TRACKED"; do
    live="${pair%%:*}"
    tracked="${pair#*:}"
    cmp -s "$live" "$tracked" || {
      echo "STOP: live hierarchical LVS evidence differs from its tracked snapshot: $live"
      PREFLIGHT=FAIL
    }
  done
  [[ "$SOURCE_LVS_RUN_TRACKED_COUNT" == 1 && "$SOURCE_CLS_TRACKED_COUNT" == 1 ]] || {
    echo "STOP: source snapshot must contain exactly one complete LVS run and CLS"
    PREFLIGHT=FAIL
  }
  [[ "$STANDALONE_LVS_RUN_TRACKED_COUNT" == 1 && "$STANDALONE_CLS_TRACKED_COUNT" == 1 ]] || {
    echo "STOP: standalone snapshot must contain exactly one complete LVS run and CLS"
    PREFLIGHT=FAIL
  }
  for path in "$SOURCE_LVS_RUN_TRACKED/run.pvs" "$SOURCE_LVS_RUN_TRACKED/pvslvsctl" \
              "$SOURCE_LVS_RUN_TRACKED/.technology.rul" "$SOURCE_CLS_TRACKED" \
              "$STANDALONE_LVS_RUN_TRACKED/run.pvs" "$STANDALONE_LVS_RUN_TRACKED/pvslvsctl" \
              "$STANDALONE_LVS_RUN_TRACKED/.technology.rul" "$STANDALONE_CLS_TRACKED"; do
    tracked_report "$path" || {
      echo "STOP: tracked hierarchical LVS member missing: $path"
      PREFLIGHT=FAIL
    }
  done
  tracked_file "$SOURCE_LVS_RUN_TRACKED/.config.rul" || {
    echo "STOP: tracked source LVS .config.rul is missing"
    PREFLIGHT=FAIL
  }
  tracked_file "$STANDALONE_LVS_RUN_TRACKED/.config.rul" || {
    echo "STOP: tracked standalone LVS .config.rul is missing"
    PREFLIGHT=FAIL
  }
  [[ ! -s "$SOURCE_LVS_RUN_TRACKED/.config.rul" && \
     ! -s "$STANDALONE_LVS_RUN_TRACKED/.config.rul" ]] || {
    echo "STOP: tracked hierarchical LVS .config.rul files must be empty"
    PREFLIGHT=FAIL
  }
  cmp -s "$SOURCE_CLS" "$SOURCE_CLS_TRACKED" || {
    echo "STOP: live source CLS differs from its tracked snapshot"
    PREFLIGHT=FAIL
  }
  [[ "$RAW_CLASSIFIER_RC" == 0 && "$RAW_ATTRIBUTION_STATUS" == PASS && \
     "$RAW_MISMATCH_ATTRIBUTION" == EXACT_TWO_RO6_INTERNALS_ONLY && \
     "$RAW_HIERARCHICAL_ELIGIBLE" == YES && "$RAW_LAYOUT_ONLY_COUNT" == 380 && \
     "$RAW_SOURCE_ONLY_COUNT" == 2 && "$RAW_LAYOUT_CLUSTER_COUNT" == 2 && \
     "$RAW_CLASSIFIED_CLS_SHA256" == "$SOURCE_CLS_SHA256" && \
     "$RAW_CLASSIFIER_SHA256" =~ ^[0-9a-f]{64}$ && \
     "$RAW_CLASSIFICATION_SHA256" =~ ^[0-9a-f]{64}$ ]] || {
    echo "STOP: raw mismatch is not exactly attributable to the two RO_tune6 interiors"
    PREFLIGHT=FAIL
  }
  [[ "$STANDALONE_CLS_RUN_RESULT" == MATCH && \
     "$STANDALONE_BLACKBOXED_CELL_COUNT" == 0 && \
     "$STANDALONE_RO6_PIN_MATCH_COUNT" == 1 && \
     "$STANDALONE_CLS_SHA256" =~ ^[0-9a-f]{64}$ ]] || {
    echo "STOP: tracked standalone proof is not an explicit unblackboxed 19:19 MATCH"
    PREFLIGHT=FAIL
  }
  [[ "$SOURCE_GDS_SHA256" == "$SOURCE_GDS_EXPECTED_SHA256" && \
     "$SOURCE_VERILOG_SHA256" == "$SOURCE_VERILOG_EXPECTED_SHA256" && \
     "$SOURCE_HCELL_SHA256" == "$SOURCE_HCELL_EXPECTED_SHA256" && \
     "$STANDALONE_RO_GDS_ACTUAL_SHA256" == "$STANDALONE_RO_GDS_SHA256" && \
     "$STANDALONE_RO_CDL_ACTUAL_SHA256" == "$STANDALONE_RO_CDL_SHA256" && \
     "$SOURCE_RO_GDS_SHA256" == "$STANDALONE_RO_GDS_ACTUAL_SHA256" ]] || {
    echo "STOP: hierarchical LVS live inputs disagree with their exact hashes"
    PREFLIGHT=FAIL
  }
fi
[[ ! -e "$PVS_DIR" ]] || { echo "STOP: result directory already exists: $PVS_DIR"; PREFLIGHT=FAIL; }

echo "PVS_RO6_BOUNDARY_PREFLIGHT=$PREFLIGHT"
if [[ "$PREFLIGHT" != PASS ]]; then
  echo "DECISION=FAIL_STOP"
  exit 4
fi

LVS_TEMPLATE_RUN="$SOURCE_LVS_RUN"
LVS_TEMPLATE_SOURCE=LIVE_DIAGNOSTIC_SOURCE_RUN
if [[ "$HIERARCHICAL_LVS_SIGNOFF" -eq 1 ]]; then
  LVS_TEMPLATE_RUN="$SOURCE_LVS_RUN_TRACKED"
  LVS_TEMPLATE_SOURCE=TRACKED_SOURCE_SNAPSHOT
fi

mkdir -p "$PVS_DIR/manifests" "$PVS_DIR/reports" "$PVS_DIR/logs" "$PVS_DIR/pvs_lvs"
ln -s "$SOURCE_PVS_DIR/outputs" "$PVS_DIR/outputs"
sed "s|$SOURCE_PVS_DIR|$PVS_DIR|g" "$SOURCE_HASH_MANIFEST" \
  > "$PVS_DIR/manifests/pvs_input_hashes.rpt"

if [[ "$HIERARCHICAL_LVS_SIGNOFF" -eq 1 ]]; then
  cp -p "$RAW_CLASSIFICATION_TMP" "$PVS_DIR/reports/pvs_ro6_raw_mismatch_attribution.rpt"
fi
{
  echo "PVS_RUN_CLASS=DIAGNOSTIC_RO6_BOUNDARY_BLACKBOX"
  echo "DIAGNOSTIC_SCOPE=LVS_ONLY_RO6_BOUNDARY"
  echo "SOURCE_PVS_RUN_ID=$SOURCE_PVS_RUN_ID"
  echo "SOURCE_PVS_EVIDENCE_ID=$SOURCE_PVS_EVIDENCE_ID"
  echo "SOURCE_PVS_DIR=$SOURCE_PVS_DIR"
  echo "SOURCE_LVS_RUN=$SOURCE_LVS_RUN"
  echo "LVS_TEMPLATE_RUN=$LVS_TEMPLATE_RUN"
  echo "LVS_TEMPLATE_SOURCE=$LVS_TEMPLATE_SOURCE"
  echo "SOURCE_GATE_LVS_STATUS=$SOURCE_GATE_LVS_STATUS"
  echo "SOURCE_CLS_RUN_RESULT=$SOURCE_CLS_RUN_RESULT"
  echo "SOURCE_PVS_RC=$SOURCE_PVS_RC"
  echo "SOURCE_CLS=$SOURCE_CLS"
  echo "SOURCE_CLS_SHA256=$SOURCE_CLS_SHA256"
  echo "SOURCE_MISMATCHED_MARKER_COUNT=$SOURCE_MISMATCHED_MARKER_COUNT"
  echo "SOURCE_MATCHED_MARKER_COUNT=$SOURCE_MATCHED_MARKER_COUNT"
  echo "SOURCE_BLACKBOXED_CELL_COUNT=$SOURCE_BLACKBOXED_CELL_COUNT"
  echo "SOURCE_RO6_WRAPPER_MISMATCH_COUNT=$SOURCE_RO6_WRAPPER_MISMATCH_COUNT"
  echo "RAW_MISMATCH_ATTRIBUTION=$RAW_MISMATCH_ATTRIBUTION"
  echo "RAW_HIERARCHICAL_ELIGIBLE=$RAW_HIERARCHICAL_ELIGIBLE"
  echo "RAW_CLASSIFIER_SHA256=$RAW_CLASSIFIER_SHA256"
  echo "RAW_CLASSIFICATION_REPORT_SHA256=$RAW_CLASSIFICATION_SHA256"
  echo "STANDALONE_PVS_RUN_ID=$STANDALONE_PVS_RUN_ID"
  echo "STANDALONE_RO_GDS_SHA256=$STANDALONE_RO_GDS_SHA256"
  echo "STANDALONE_RO_CDL_SHA256=$STANDALONE_RO_CDL_SHA256"
  echo "STANDALONE_LVS_STATUS=$STANDALONE_LVS_STATUS"
  echo "SOURCE_CONTRACT_STATUS=$SOURCE_CONTRACT_STATUS"
  echo "SOURCE_KIND=$SOURCE_KIND"
  echo "SOURCE_MODULE_REMOVAL_POLICY=$SOURCE_MODULE_REMOVAL_POLICY"
  echo "SOURCE_PHYSICAL_ONLY_REMOVAL_POLICY=$SOURCE_PHYSICAL_ONLY_REMOVAL_POLICY"
  echo "SOURCE_FILLER_COUNT_EXPECTED=$SOURCE_FILLER_COUNT_EXPECTED"
  echo "SOURCE_FILLER_COUNT_INPUT=$SOURCE_FILLER_COUNT_INPUT"
  echo "SOURCE_FILLER_COUNT_REMOVED=$SOURCE_FILLER_COUNT_REMOVED"
  echo "SOURCE_FILLER_REMOVAL_STATUS=$SOURCE_FILLER_REMOVAL_STATUS"
  echo "SOURCE_RO6_PIN_NORMALIZATION=$SOURCE_RO6_PIN_NORMALIZATION"
  echo "SOURCE_RO6_INSTANCE_COUNT=$SOURCE_RO6_INSTANCE_COUNT"
  echo "SOURCE_RO6_INSTANCE_NAME_STATUS=$SOURCE_RO6_INSTANCE_NAME_STATUS"
  echo "SOURCE_PHYSICAL_TIE_INSTANCE_COUNT=$SOURCE_PHYSICAL_TIE_INSTANCE_COUNT"
  echo "SOURCE_PHYSICAL_TIE_PRESERVATION_STATUS=$SOURCE_PHYSICAL_TIE_PRESERVATION_STATUS"
  echo "SOURCE_UNRESOLVED_MASTER_COUNT=$SOURCE_UNRESOLVED_MASTER_COUNT"
  echo "MERGED_GDS_SHA256=$SOURCE_GDS_SHA256"
  echo "LVS_SOURCE_SHA256=$SOURCE_VERILOG_SHA256"
  echo "LVS_HCELL_SHA256=$SOURCE_HCELL_SHA256"
  echo "BLACKBOX_CELL=RO_tune6"
  echo "RO6_BUS_PIN_NORMALIZATION=EXACT_SAME_INDEX_SCALAR_ANGLE_PORTS"
  echo "VERILOG_GLOBAL_SIGNAL_PORT_POLICY=DO_NOT_PROMOTE"
  echo "RO6_STANDALONE_LVS_REQUIRED=YES"
  echo "HIERARCHICAL_LVS_SIGNOFF_REQUESTED=$HIERARCHICAL_LVS_SIGNOFF"
  echo "DRC_STATUS=NOT_RUN_BY_SCOPE"
  echo "SIGNOFF_ELIGIBLE=NO"
} > "$PVS_DIR/manifests/pvs_ro6_boundary_blackbox_scope.rpt"

NEW_LVS_RUN="$PVS_DIR/pvs_lvs/mptdc_axis_core_ro6_boundary_blackbox_script"
set +e
bash "$LVS_SCRIPT" \
  --prepared-dir "$PVS_DIR" \
  --template-run "$LVS_TEMPLATE_RUN" \
  --old-base "$SOURCE_PVS_DIR" \
  --old-gds "$SOURCE_GDS" \
  --old-source "$SOURCE_VERILOG" \
  --old-hcell "$SOURCE_HCELL" \
  --new-run-dir "$NEW_LVS_RUN" \
  --expected-head "$EXPECTED_HEAD_VALUE" \
  --diagnostic-ro6-boundary-blackbox \
  2>&1 | tee "$PVS_DIR/logs/operator_ro6_boundary_lvs.log"
LVS_RC=${PIPESTATUS[0]}
set +e

LVS_REPORT="$PVS_DIR/reports/pvs_lvs_status.rpt"
BOUNDARY_REPORT="$PVS_DIR/reports/pvs_lvs_ro6_boundary_blackbox_status.rpt"
LVS_STATUS="$(report_value "$LVS_REPORT" STATUS)"
LVS_GATE="$(report_value "$LVS_REPORT" PVS_LVS_STATUS)"
LVS_TOOL_RC="$(report_value "$LVS_REPORT" PVS_RC)"
BLACKBOX_RULE_STATUS="$(report_value "$BOUNDARY_REPORT" LVS_BLACKBOX_RULE_STATUS)"
BLACKBOX_APPLICATION_STATUS="$(report_value "$BOUNDARY_REPORT" LVS_BLACKBOX_APPLICATION_STATUS)"
BLACKBOXED_CELL_COUNT="$(report_value "$BOUNDARY_REPORT" LVS_BLACKBOXED_CELL_COUNT)"
BOUNDARY_CLS_FILE_COUNT="$(report_value "$BOUNDARY_REPORT" LVS_BLACKBOX_CLS_FILE_COUNT)"
BOUNDARY_CLS_FILE="$(report_value "$BOUNDARY_REPORT" LVS_BLACKBOX_CLS_FILE)"
BUS_PIN_MAP_RULE_STATUS="$(report_value "$BOUNDARY_REPORT" LVS_BUS_PIN_MAP_RULE_STATUS)"
BUS_PIN_MAP_EFFECTIVE_VALUE="$(report_value "$BOUNDARY_REPORT" LVS_BUS_PIN_MAP_EFFECTIVE_VALUE)"
GLOBAL_SIGNAL_PORT_RULE_STATUS="$(report_value "$BOUNDARY_REPORT" LVS_GLOBAL_SIGNAL_PORT_RULE_STATUS)"
RO6_CELL_MATCH_STATUS="$(report_value "$BOUNDARY_REPORT" RO6_BLACKBOX_CELL_MATCH_STATUS)"
RO6_INITIAL_PINS="$(report_value "$BOUNDARY_REPORT" RO6_BLACKBOX_INITIAL_PINS)"
RO6_COMPARE_PINS="$(report_value "$BOUNDARY_REPORT" RO6_BLACKBOX_COMPARE_PINS)"
RO6_CELL_STATUS="$(report_value "$BOUNDARY_REPORT" RO6_BLACKBOX_CELL_STATUS)"
RO6_ANGLE_BUS_MISSING_PIN_COUNT="$(report_value "$BOUNDARY_REPORT" RO6_ANGLE_BUS_MISSING_PIN_COUNT)"
RO6_SQUARE_BUS_MISSING_PIN_COUNT="$(report_value "$BOUNDARY_REPORT" RO6_SQUARE_BUS_MISSING_PIN_COUNT)"
TIE1_UNMATCHED_PIN_COUNT="$(report_value "$BOUNDARY_REPORT" TIE1_UNMATCHED_PIN_COUNT)"
TIE1_MISMATCHED_NET_COUNT="$(report_value "$BOUNDARY_REPORT" TIE1_MISMATCHED_NET_COUNT)"
TIE1_MISMATCHED_INSTANCE_CASCADE_COUNT="$(report_value "$BOUNDARY_REPORT" TIE1_MISMATCHED_INSTANCE_CASCADE_COUNT)"
LAYOUT_OPEN_NET_COUNT="$(report_value "$BOUNDARY_REPORT" LAYOUT_OPEN_NET_COUNT)"
SHORTS_OPENS_RECORD_COUNT="$(report_value "$BOUNDARY_REPORT" SHORTS_OPENS_RECORD_COUNT)"
MISMATCHED_NET_RECORD_COUNT="$(report_value "$BOUNDARY_REPORT" MISMATCHED_NET_RECORD_COUNT)"
MISMATCHED_INSTANCE_RECORD_COUNT="$(report_value "$BOUNDARY_REPORT" MISMATCHED_INSTANCE_RECORD_COUNT)"
VDD_OPEN_SECTION_COUNT="$(report_value "$BOUNDARY_REPORT" VDD_OPEN_SECTION_COUNT)"
VSS_OPEN_SECTION_COUNT="$(report_value "$BOUNDARY_REPORT" VSS_OPEN_SECTION_COUNT)"
SIGNOFF_ELIGIBLE="$(report_value "$BOUNDARY_REPORT" SIGNOFF_ELIGIBLE)"
BOUNDARY_CLS_SHA256="$(sha256sum "$BOUNDARY_CLS_FILE" 2>/dev/null | awk '{print $1}')"
BOUNDARY_CLS_PATH_STATUS=FAIL
BOUNDARY_TOP_INITIAL_PINS=MISSING
BOUNDARY_TOP_COMPARE_PINS=MISSING
BOUNDARY_TOP_CELL_STATUS=MISSING
BOUNDARY_TOP_REDUCED_LAYOUT_INSTANCE_COUNT=MISSING
BOUNDARY_TOP_REDUCED_SCHEMATIC_INSTANCE_COUNT=MISSING
if [[ "$BOUNDARY_CLS_FILE_COUNT" == 1 && "$BOUNDARY_CLS_FILE" == "$NEW_LVS_RUN"/* && \
      -s "$BOUNDARY_CLS_FILE" ]]; then
  BOUNDARY_CLS_PATH_STATUS=PASS
  BOUNDARY_TOP_INITIAL_PINS="$(awk -F '|' '$1 ~ /^mptdc_axis_core[[:space:]]*$/ {value=$2; gsub(/[[:space:]]/, "", value); print value; exit}' "$BOUNDARY_CLS_FILE")"
  BOUNDARY_TOP_COMPARE_PINS="$(awk -F '|' '$1 ~ /^mptdc_axis_core[[:space:]]*$/ {value=$3; gsub(/[[:space:]]/, "", value); print value; exit}' "$BOUNDARY_CLS_FILE")"
  BOUNDARY_TOP_CELL_STATUS="$(awk -F '|' '$1 ~ /^mptdc_axis_core[[:space:]]*$/ {value=$4; gsub(/[[:space:]]/, "", value); print tolower(value); exit}' "$BOUNDARY_CLS_FILE")"
  BOUNDARY_TOP_REDUCED_INSTANCE_PAIR="$(awk -F '|' '$1 ~ /^Total[[:space:]]*$/ {value=$4; gsub(/[[:space:],]/, "", value); print value; exit}' "$BOUNDARY_CLS_FILE")"
  if [[ "$BOUNDARY_TOP_REDUCED_INSTANCE_PAIR" =~ ^([0-9]+):([0-9]+)$ ]]; then
    BOUNDARY_TOP_REDUCED_LAYOUT_INSTANCE_COUNT="${BASH_REMATCH[1]}"
    BOUNDARY_TOP_REDUCED_SCHEMATIC_INSTANCE_COUNT="${BASH_REMATCH[2]}"
  fi
  [[ -n "$BOUNDARY_TOP_INITIAL_PINS" ]] || BOUNDARY_TOP_INITIAL_PINS=MISSING
  [[ -n "$BOUNDARY_TOP_COMPARE_PINS" ]] || BOUNDARY_TOP_COMPARE_PINS=MISSING
  [[ -n "$BOUNDARY_TOP_CELL_STATUS" ]] || BOUNDARY_TOP_CELL_STATUS=MISSING
fi
BOUNDARY_RUN_PVS_SHA256="$(sha256sum "$NEW_LVS_RUN/run.pvs" 2>/dev/null | awk '{print $1}')"
BOUNDARY_LVS_CONTROL_SHA256="$(sha256sum "$NEW_LVS_RUN/pvslvsctl" 2>/dev/null | awk '{print $1}')"
BOUNDARY_CONFIG_RUL_SHA256="$(sha256sum "$NEW_LVS_RUN/.config.rul" 2>/dev/null | awk '{print $1}')"
BOUNDARY_TECHNOLOGY_RUL_SHA256="$(sha256sum "$NEW_LVS_RUN/.technology.rul" 2>/dev/null | awk '{print $1}')"
BOUNDARY_LAYOUT_TOP_ARGUMENT_COUNT="$(grep -Ec '^[[:space:]]*-top_cell[[:space:]]+mptdc_axis_core([[:space:]]|\\$)' "$NEW_LVS_RUN/run.pvs" 2>/dev/null || true)"
BOUNDARY_SOURCE_TOP_ARGUMENT_COUNT="$(grep -Ec '^[[:space:]]*-source_top_cell[[:space:]]+mptdc_axis_core([[:space:]]|\\$)' "$NEW_LVS_RUN/run.pvs" 2>/dev/null || true)"

DECISION=FAIL_STOP
NEXT_STAGE=STOP_AND_REVIEW_PUBLISHED_EVIDENCE
BOUNDARY_REMAINDER_CLASS=UNCLASSIFIED
if [[ "$LVS_RC" -eq 0 && "$LVS_STATUS" == PASS && "$LVS_GATE" == MATCH && \
      "$LVS_TOOL_RC" == 0 && "$BLACKBOX_RULE_STATUS" == PASS && \
      "$BLACKBOX_APPLICATION_STATUS" == PASS && "$BLACKBOXED_CELL_COUNT" =~ ^[0-9]+$ && \
      "$BLACKBOXED_CELL_COUNT" -ge 1 && "$BUS_PIN_MAP_RULE_STATUS" == NOT_USED_EXACT_SCALAR_SOURCE && \
      "$GLOBAL_SIGNAL_PORT_RULE_STATUS" == PASS && "$RO6_CELL_MATCH_STATUS" == PASS && \
      "$RO6_ANGLE_BUS_MISSING_PIN_COUNT" == 0 && "$RO6_SQUARE_BUS_MISSING_PIN_COUNT" == 0 && \
      "$TIE1_UNMATCHED_PIN_COUNT" == 0 && "$TIE1_MISMATCHED_NET_COUNT" == 0 && \
      "$TIE1_MISMATCHED_INSTANCE_CASCADE_COUNT" == 0 && \
      "$SIGNOFF_ELIGIBLE" == NO ]]; then
  DECISION=PASS_COMPOSITIONAL_LVS
  NEXT_STAGE=PVS_RO6_MONOLITHIC_FULL_TOP_LVS
  BOUNDARY_REMAINDER_CLASS=NONE_MATCH
elif [[ "$LVS_GATE" == MISMATCH && "$LVS_TOOL_RC" == 0 && \
        "$BOUNDARY_CLS_PATH_STATUS" == PASS && "$BOUNDARY_TOP_INITIAL_PINS" == 59:59 && \
        "$BOUNDARY_TOP_COMPARE_PINS" == 59:59 && "$BOUNDARY_TOP_CELL_STATUS" == mismatch && \
        "$BOUNDARY_TOP_REDUCED_LAYOUT_INSTANCE_COUNT" == 213582 && \
        "$BOUNDARY_TOP_REDUCED_SCHEMATIC_INSTANCE_COUNT" == 213582 && \
        "$BLACKBOX_RULE_STATUS" == PASS && "$BLACKBOX_APPLICATION_STATUS" == PASS && \
        "$BLACKBOXED_CELL_COUNT" == 1 && "$BUS_PIN_MAP_RULE_STATUS" == NOT_USED_EXACT_SCALAR_SOURCE && \
        "$GLOBAL_SIGNAL_PORT_RULE_STATUS" == PASS && "$RO6_CELL_MATCH_STATUS" == PASS && \
        "$RO6_INITIAL_PINS" == 19:19 && "$RO6_COMPARE_PINS" == 19:19 && \
        "$RO6_CELL_STATUS" == match && "$RO6_ANGLE_BUS_MISSING_PIN_COUNT" == 0 && \
        "$RO6_SQUARE_BUS_MISSING_PIN_COUNT" == 0 && "$TIE1_UNMATCHED_PIN_COUNT" == 0 && \
        "$TIE1_MISMATCHED_NET_COUNT" == 0 && "$TIE1_MISMATCHED_INSTANCE_CASCADE_COUNT" == 0 && \
        "$LAYOUT_OPEN_NET_COUNT" == 2 && "$SHORTS_OPENS_RECORD_COUNT" == 1 && \
        "$MISMATCHED_NET_RECORD_COUNT" == 0 && "$MISMATCHED_INSTANCE_RECORD_COUNT" == 0 && \
        "$VDD_OPEN_SECTION_COUNT" == 0 && "$VSS_OPEN_SECTION_COUNT" == 1 ]]; then
  BOUNDARY_REMAINDER_CLASS=RO6_VSS_OPEN_ONLY
  DECISION=PASS_PG_REPAIR_REQUIRED
  NEXT_STAGE=RO6_VSS_VIA_TRIAL
elif [[ "$LVS_GATE" == MISMATCH && "$LVS_TOOL_RC" == 0 && \
        "$BLACKBOX_RULE_STATUS" == PASS && "$BLACKBOX_APPLICATION_STATUS" == PASS && \
        "$BUS_PIN_MAP_RULE_STATUS" == NOT_USED_EXACT_SCALAR_SOURCE && "$GLOBAL_SIGNAL_PORT_RULE_STATUS" == PASS && \
        "$RO6_CELL_MATCH_STATUS" == PASS && "$RO6_ANGLE_BUS_MISSING_PIN_COUNT" == 0 && \
        "$RO6_SQUARE_BUS_MISSING_PIN_COUNT" == 0 && "$TIE1_UNMATCHED_PIN_COUNT" == 0 && \
        "$TIE1_MISMATCHED_NET_COUNT" == 0 && "$TIE1_MISMATCHED_INSTANCE_CASCADE_COUNT" == 0 && \
        "$LAYOUT_OPEN_NET_COUNT" == 4 && "$SHORTS_OPENS_RECORD_COUNT" == 2 && \
        "$MISMATCHED_NET_RECORD_COUNT" == 0 && "$MISMATCHED_INSTANCE_RECORD_COUNT" == 0 && \
        "$VDD_OPEN_SECTION_COUNT" == 1 && "$VSS_OPEN_SECTION_COUNT" == 1 ]]; then
  BOUNDARY_REMAINDER_CLASS=RO6_PG_OPEN_ONLY
  DECISION=PASS_PG_REPAIR_REQUIRED
  NEXT_STAGE=RO6_PG_ENDPOINT_PROBE
elif [[ "$BUS_PIN_MAP_RULE_STATUS" == NOT_USED_EXACT_SCALAR_SOURCE && "$GLOBAL_SIGNAL_PORT_RULE_STATUS" == PASS && \
        "$RO6_CELL_MATCH_STATUS" == PASS ]]; then
  BOUNDARY_REMAINDER_CLASS=TOP_CONNECTIVITY_MISMATCH
fi

{
  echo "STEP=PVS_RO6_BOUNDARY_LVS"
  echo "SOURCE_PVS_RUN_ID=$SOURCE_PVS_RUN_ID"
  echo "SOURCE_PVS_EVIDENCE_ID=$SOURCE_PVS_EVIDENCE_ID"
  echo "STANDALONE_PVS_RUN_ID=$STANDALONE_PVS_RUN_ID"
  echo "PVS_RUN_CLASS=DIAGNOSTIC_RO6_BOUNDARY_BLACKBOX"
  echo "LVS_RC=$LVS_RC"
  echo "STATUS=$LVS_STATUS"
  echo "PVS_LVS_STATUS=$LVS_GATE"
  echo "PVS_RC=$LVS_TOOL_RC"
  echo "LVS_BLACKBOX_RULE_STATUS=$BLACKBOX_RULE_STATUS"
  echo "LVS_BLACKBOX_APPLICATION_STATUS=$BLACKBOX_APPLICATION_STATUS"
  echo "LVS_BLACKBOXED_CELL_COUNT=$BLACKBOXED_CELL_COUNT"
  echo "LVS_BLACKBOX_CLS_FILE_COUNT=$BOUNDARY_CLS_FILE_COUNT"
  echo "LVS_BLACKBOX_CLS_SHA256=$BOUNDARY_CLS_SHA256"
  echo "LVS_BLACKBOX_CLS_PATH_STATUS=$BOUNDARY_CLS_PATH_STATUS"
  echo "TOP_INITIAL_PINS=$BOUNDARY_TOP_INITIAL_PINS"
  echo "TOP_COMPARE_PINS=$BOUNDARY_TOP_COMPARE_PINS"
  echo "TOP_CELL_STATUS=$BOUNDARY_TOP_CELL_STATUS"
  echo "TOP_REDUCED_LAYOUT_INSTANCE_COUNT=$BOUNDARY_TOP_REDUCED_LAYOUT_INSTANCE_COUNT"
  echo "TOP_REDUCED_SCHEMATIC_INSTANCE_COUNT=$BOUNDARY_TOP_REDUCED_SCHEMATIC_INSTANCE_COUNT"
  echo "LAYOUT_TOP_ARGUMENT_COUNT=$BOUNDARY_LAYOUT_TOP_ARGUMENT_COUNT"
  echo "SOURCE_TOP_ARGUMENT_COUNT=$BOUNDARY_SOURCE_TOP_ARGUMENT_COUNT"
  echo "RUN_PVS_SHA256=$BOUNDARY_RUN_PVS_SHA256"
  echo "LVS_CONTROL_SHA256=$BOUNDARY_LVS_CONTROL_SHA256"
  echo "CONFIG_RUL_SHA256=$BOUNDARY_CONFIG_RUL_SHA256"
  echo "TECHNOLOGY_RUL_SHA256=$BOUNDARY_TECHNOLOGY_RUL_SHA256"
  echo "LVS_BUS_PIN_MAP_EFFECTIVE_VALUE=$BUS_PIN_MAP_EFFECTIVE_VALUE"
  echo "LVS_BUS_PIN_MAP_RULE_STATUS=$BUS_PIN_MAP_RULE_STATUS"
  echo "LVS_GLOBAL_SIGNAL_PORT_RULE_STATUS=$GLOBAL_SIGNAL_PORT_RULE_STATUS"
  echo "RO6_BLACKBOX_CELL_MATCH_STATUS=$RO6_CELL_MATCH_STATUS"
  echo "RO6_BLACKBOX_INITIAL_PINS=$RO6_INITIAL_PINS"
  echo "RO6_BLACKBOX_COMPARE_PINS=$RO6_COMPARE_PINS"
  echo "RO6_BLACKBOX_CELL_STATUS=$RO6_CELL_STATUS"
  echo "RO6_ANGLE_BUS_MISSING_PIN_COUNT=$RO6_ANGLE_BUS_MISSING_PIN_COUNT"
  echo "RO6_SQUARE_BUS_MISSING_PIN_COUNT=$RO6_SQUARE_BUS_MISSING_PIN_COUNT"
  echo "TIE1_UNMATCHED_PIN_COUNT=$TIE1_UNMATCHED_PIN_COUNT"
  echo "TIE1_MISMATCHED_NET_COUNT=$TIE1_MISMATCHED_NET_COUNT"
  echo "TIE1_MISMATCHED_INSTANCE_CASCADE_COUNT=$TIE1_MISMATCHED_INSTANCE_CASCADE_COUNT"
  echo "LAYOUT_OPEN_NET_COUNT=$LAYOUT_OPEN_NET_COUNT"
  echo "SHORTS_OPENS_RECORD_COUNT=$SHORTS_OPENS_RECORD_COUNT"
  echo "MISMATCHED_NET_RECORD_COUNT=$MISMATCHED_NET_RECORD_COUNT"
  echo "MISMATCHED_INSTANCE_RECORD_COUNT=$MISMATCHED_INSTANCE_RECORD_COUNT"
  echo "VDD_OPEN_SECTION_COUNT=$VDD_OPEN_SECTION_COUNT"
  echo "VSS_OPEN_SECTION_COUNT=$VSS_OPEN_SECTION_COUNT"
  echo "BOUNDARY_REMAINDER_CLASS=$BOUNDARY_REMAINDER_CLASS"
  echo "RO6_STANDALONE_LVS_REQUIRED=YES"
  echo "DRC_STATUS=NOT_RUN_BY_SCOPE"
  echo "SIGNOFF_ELIGIBLE=$SIGNOFF_ELIGIBLE"
  echo "DECISION=$DECISION"
  echo "NEXT_STAGE=$NEXT_STAGE"
} | tee "$PVS_DIR/reports/operator_gate_pvs_ro6_boundary_lvs.rpt"

if [[ "$BOUNDARY_REMAINDER_CLASS" == NONE_MATCH && "$DECISION" == PASS_COMPOSITIONAL_LVS ]]; then
  {
    echo "STEP=PVS_COMPOSITIONAL_LVS"
    echo "PVS_RUN_CLASS=DIAGNOSTIC_COMPOSITIONAL_NOT_SIGNOFF"
    echo "SOURCE_PVS_RUN_ID=$SOURCE_PVS_RUN_ID"
    echo "SOURCE_PVS_EVIDENCE_ID=$SOURCE_PVS_EVIDENCE_ID"
    echo "BOUNDARY_PVS_RUN_ID=$PVS_RUN_ID"
    echo "STANDALONE_PVS_RUN_ID=$STANDALONE_PVS_RUN_ID"
    echo "RAW_FULL_TOP_LVS_STATUS=MISMATCH_RO_ABSTRACTION_ONLY"
    echo "RAW_FULL_TOP_CLS_SHA256=$SOURCE_CLS_SHA256"
    echo "PVS_TOP_BOUNDARY_LVS=MATCH"
    echo "PVS_RO6_STANDALONE_LVS=MATCH"
    echo "COMPOSITIONAL_LVS_STATUS=PASS"
    echo "MERGED_GDS_SHA256=$SOURCE_GDS_SHA256"
    echo "LVS_SOURCE_SHA256=$SOURCE_VERILOG_SHA256"
    echo "LVS_HCELL_SHA256=$SOURCE_HCELL_SHA256"
    echo "RO_GDS_SHA256=$STANDALONE_RO_GDS_SHA256"
    echo "RO_CDL_SHA256=$STANDALONE_RO_CDL_SHA256"
    echo "TIE1_UNMATCHED_PIN_COUNT=0"
    echo "TIE1_MISMATCHED_NET_COUNT=0"
    echo "ANTENNA_REPAIR_ATTEMPTED=NO"
    echo "SIGNOFF_ELIGIBLE=NO"
    echo "FINAL_SIGNOFF=NO"
    echo "READY_FOR_TAPEOUT=NO"
    echo "DECISION=PASS_MONOLITHIC_LVS_CONTINUE"
    echo "NEXT_STAGE=PVS_RO6_MONOLITHIC_FULL_TOP_LVS"
  } | tee "$PVS_DIR/reports/operator_gate_pvs_compositional_lvs.rpt"
fi

BOUNDARY_DECISION="$DECISION"
BOUNDARY_NEXT_STAGE="$NEXT_STAGE"
HIERARCHICAL_LVS_STATUS=NOT_RUN
HIERARCHICAL_GATE_STATUS=NOT_RUN
HIERARCHICAL_DECISION=NOT_REQUESTED
if [[ "$HIERARCHICAL_LVS_SIGNOFF" -eq 1 ]]; then
  HIERARCHICAL_GATE_STATUS=FAIL
  HIERARCHICAL_LVS_STATUS=NOT_PROVEN
  HIERARCHICAL_DECISION=FAIL_STOP
  if [[ "$BOUNDARY_REMAINDER_CLASS" == NONE_MATCH && \
        "$BOUNDARY_DECISION" == PASS_COMPOSITIONAL_LVS && \
        "$LVS_RC" -eq 0 && "$LVS_STATUS" == PASS && "$LVS_GATE" == MATCH && \
        "$LVS_TOOL_RC" == 0 && "$BOUNDARY_CLS_FILE_COUNT" == 1 && \
        "$BOUNDARY_CLS_PATH_STATUS" == PASS && \
        "$BOUNDARY_CLS_SHA256" =~ ^[0-9a-f]{64}$ && \
        "$BOUNDARY_TOP_INITIAL_PINS" == 59:59 && \
        "$BOUNDARY_TOP_COMPARE_PINS" == 59:59 && \
        "$BOUNDARY_TOP_CELL_STATUS" == match && \
        "$BOUNDARY_TOP_REDUCED_LAYOUT_INSTANCE_COUNT" == 213582 && \
        "$BOUNDARY_TOP_REDUCED_SCHEMATIC_INSTANCE_COUNT" == 213582 && \
        "$BOUNDARY_LAYOUT_TOP_ARGUMENT_COUNT" == 1 && \
        "$BOUNDARY_SOURCE_TOP_ARGUMENT_COUNT" == 1 && \
        "$BOUNDARY_RUN_PVS_SHA256" =~ ^[0-9a-f]{64}$ && \
        "$BOUNDARY_LVS_CONTROL_SHA256" =~ ^[0-9a-f]{64}$ && \
        "$BOUNDARY_CONFIG_RUL_SHA256" =~ ^[0-9a-f]{64}$ && \
        "$BOUNDARY_TECHNOLOGY_RUL_SHA256" =~ ^[0-9a-f]{64}$ && \
        "$BLACKBOX_RULE_STATUS" == PASS && "$BLACKBOX_APPLICATION_STATUS" == PASS && \
        "$BLACKBOXED_CELL_COUNT" == 1 && \
        "$BUS_PIN_MAP_RULE_STATUS" == NOT_USED_EXACT_SCALAR_SOURCE && \
        "$GLOBAL_SIGNAL_PORT_RULE_STATUS" == PASS && \
        "$RO6_CELL_MATCH_STATUS" == PASS && "$RO6_INITIAL_PINS" == 19:19 && \
        "$RO6_COMPARE_PINS" == 19:19 && "$RO6_CELL_STATUS" == match && \
        "$RO6_ANGLE_BUS_MISSING_PIN_COUNT" == 0 && \
        "$RO6_SQUARE_BUS_MISSING_PIN_COUNT" == 0 && \
        "$TIE1_UNMATCHED_PIN_COUNT" == 0 && "$TIE1_MISMATCHED_NET_COUNT" == 0 && \
        "$TIE1_MISMATCHED_INSTANCE_CASCADE_COUNT" == 0 && \
        "$LAYOUT_OPEN_NET_COUNT" == 0 && "$SHORTS_OPENS_RECORD_COUNT" == 0 && \
        "$MISMATCHED_NET_RECORD_COUNT" == 0 && "$MISMATCHED_INSTANCE_RECORD_COUNT" == 0 && \
        "$VDD_OPEN_SECTION_COUNT" == 0 && "$VSS_OPEN_SECTION_COUNT" == 0 && \
        "$RAW_ATTRIBUTION_STATUS" == PASS && \
        "$RAW_MISMATCH_ATTRIBUTION" == EXACT_TWO_RO6_INTERNALS_ONLY && \
        "$RAW_HIERARCHICAL_ELIGIBLE" == YES && "$RAW_LAYOUT_CLUSTER_COUNT" == 2 && \
        "$STANDALONE_CLS_RUN_RESULT" == MATCH && \
        "$STANDALONE_BLACKBOXED_CELL_COUNT" == 0 && \
        "$STANDALONE_RO6_PIN_MATCH_COUNT" == 1 && \
        "$SOURCE_RO_GDS_SHA256" == "$STANDALONE_RO_GDS_SHA256" && \
        "$STANDALONE_RO_GDS_ACTUAL_SHA256" == "$STANDALONE_RO_GDS_SHA256" && \
        "$STANDALONE_RO_CDL_ACTUAL_SHA256" == "$STANDALONE_RO_CDL_SHA256" ]]; then
    HIERARCHICAL_GATE_STATUS=PASS
    HIERARCHICAL_LVS_STATUS=MATCH
    HIERARCHICAL_DECISION=PASS_HIERARCHICAL_LVS
  fi

  {
    echo "STEP=PVS_HIERARCHICAL_LVS"
    echo "PVS_RUN_CLASS=SIGNOFF_HIERARCHICAL_LVS_COMPOSITION"
    echo "LVS_PROOF_METHOD=HIERARCHICAL_TOP_BLACKBOX_PLUS_STANDALONE_RO"
    echo "SOURCE_PVS_RUN_ID=$SOURCE_PVS_RUN_ID"
    echo "SOURCE_PVS_EVIDENCE_ID=$SOURCE_PVS_EVIDENCE_ID"
    echo "BOUNDARY_PVS_RUN_ID=$PVS_RUN_ID"
    echo "STANDALONE_PVS_RUN_ID=$STANDALONE_PVS_RUN_ID"
    echo "RAW_FULL_TOP_LVS_STATUS=MISMATCH_RO_INTERIORS_ONLY"
    echo "RAW_MISMATCH_ATTRIBUTION=$RAW_MISMATCH_ATTRIBUTION"
    echo "RAW_HIERARCHICAL_ELIGIBLE=$RAW_HIERARCHICAL_ELIGIBLE"
    echo "RAW_CLS_SHA256=$SOURCE_CLS_SHA256"
    echo "RAW_CLASSIFIED_CLS_SHA256=$RAW_CLASSIFIED_CLS_SHA256"
    echo "RAW_CLASSIFIER_SHA256=$RAW_CLASSIFIER_SHA256"
    echo "RAW_CLASSIFICATION_REPORT_SHA256=$RAW_CLASSIFICATION_SHA256"
    echo "PVS_TOP_BOUNDARY_LVS=$LVS_GATE"
    echo "BOUNDARY_CLS_SHA256=$BOUNDARY_CLS_SHA256"
    echo "BOUNDARY_CLS_PATH_STATUS=$BOUNDARY_CLS_PATH_STATUS"
    echo "BOUNDARY_TOP_INITIAL_PINS=$BOUNDARY_TOP_INITIAL_PINS"
    echo "BOUNDARY_TOP_COMPARE_PINS=$BOUNDARY_TOP_COMPARE_PINS"
    echo "BOUNDARY_TOP_CELL_STATUS=$BOUNDARY_TOP_CELL_STATUS"
    echo "BOUNDARY_TOP_REDUCED_LAYOUT_INSTANCE_COUNT=$BOUNDARY_TOP_REDUCED_LAYOUT_INSTANCE_COUNT"
    echo "BOUNDARY_TOP_REDUCED_SCHEMATIC_INSTANCE_COUNT=$BOUNDARY_TOP_REDUCED_SCHEMATIC_INSTANCE_COUNT"
    echo "BOUNDARY_LAYOUT_TOP_ARGUMENT_COUNT=$BOUNDARY_LAYOUT_TOP_ARGUMENT_COUNT"
    echo "BOUNDARY_SOURCE_TOP_ARGUMENT_COUNT=$BOUNDARY_SOURCE_TOP_ARGUMENT_COUNT"
    echo "BOUNDARY_RUN_PVS_SHA256=$BOUNDARY_RUN_PVS_SHA256"
    echo "BOUNDARY_LVS_CONTROL_SHA256=$BOUNDARY_LVS_CONTROL_SHA256"
    echo "BOUNDARY_CONFIG_RUL_SHA256=$BOUNDARY_CONFIG_RUL_SHA256"
    echo "BOUNDARY_TECHNOLOGY_RUL_SHA256=$BOUNDARY_TECHNOLOGY_RUL_SHA256"
    echo "BOUNDARY_BLACKBOX_CELL=RO_tune6"
    echo "BOUNDARY_BLACKBOXED_CELL_COUNT=$BLACKBOXED_CELL_COUNT"
    echo "BOUNDARY_RO6_INITIAL_PINS=$RO6_INITIAL_PINS"
    echo "BOUNDARY_RO6_COMPARE_PINS=$RO6_COMPARE_PINS"
    echo "BOUNDARY_REMAINDER_CLASS=$BOUNDARY_REMAINDER_CLASS"
    echo "PVS_RO6_STANDALONE_LVS=$STANDALONE_CLS_RUN_RESULT"
    echo "STANDALONE_CLS_SHA256=$STANDALONE_CLS_SHA256"
    echo "STANDALONE_BLACKBOXED_CELL_COUNT=$STANDALONE_BLACKBOXED_CELL_COUNT"
    echo "STANDALONE_RO6_PIN_MATCH_COUNT=$STANDALONE_RO6_PIN_MATCH_COUNT"
    echo "MERGED_GDS_SHA256=$SOURCE_GDS_SHA256"
    echo "LVS_SOURCE_SHA256=$SOURCE_VERILOG_SHA256"
    echo "LVS_HCELL_SHA256=$SOURCE_HCELL_SHA256"
    echo "RO_GDS_SHA256=$STANDALONE_RO_GDS_SHA256"
    echo "RO_CDL_SHA256=$STANDALONE_RO_CDL_SHA256"
    echo "STATUS=$HIERARCHICAL_GATE_STATUS"
    echo "PVS_HIERARCHICAL_LVS_STATUS=$HIERARCHICAL_LVS_STATUS"
    echo "BLOCK_LVS_CLOSED=$([[ "$HIERARCHICAL_LVS_STATUS" == MATCH ]] && echo YES || echo NO)"
    echo "LVS_SIGNOFF_ELIGIBLE=$([[ "$HIERARCHICAL_LVS_STATUS" == MATCH ]] && echo YES || echo NO)"
    echo "MONOLITHIC_LVS_REQUIRED=NO_BY_SELECTED_METHOD"
    echo "DRC_STATUS=NOT_RUN_BY_SCOPE"
    echo "FINAL_PHYSICAL_SIGNOFF_READY=NO"
    echo "DECISION=$HIERARCHICAL_DECISION"
    echo "NEXT_STAGE=$([[ "$HIERARCHICAL_LVS_STATUS" == MATCH ]] && echo PVS_DENSITY_DRC || echo STOP_AND_REVIEW_PUBLISHED_EVIDENCE)"
  } | tee "$PVS_DIR/reports/operator_gate_pvs_hierarchical_lvs.rpt"

  DECISION="$HIERARCHICAL_DECISION"
  if [[ "$HIERARCHICAL_LVS_STATUS" == MATCH ]]; then
    NEXT_STAGE=PVS_DENSITY_DRC
  else
    NEXT_STAGE=STOP_AND_REVIEW_PUBLISHED_EVIDENCE
  fi
fi

publish_stage "$PVS_RUN_ID"
PUBLISH_RC=$?
if [[ "$PUBLISH_RC" -ne 0 ]]; then
  DECISION=FAIL_STOP
  NEXT_STAGE=REPUBLISH_BOUNDARY_LVS_EVIDENCE
fi

if [[ "$DECISION" == PASS_COMPOSITIONAL_LVS || "$DECISION" == PASS_PG_REPAIR_REQUIRED || \
      "$DECISION" == PASS_HIERARCHICAL_LVS ]]; then
  BOUNDARY_RECOVERY_STATUS=PASS
else
  BOUNDARY_RECOVERY_STATUS=FAIL
fi
echo "PVS_BOUNDARY_RECOVERY_STATUS=$BOUNDARY_RECOVERY_STATUS"
echo "PVS_RUN_ID=$PVS_RUN_ID"
echo "SOURCE_PVS_RUN_ID=$SOURCE_PVS_RUN_ID"
echo "SOURCE_PVS_EVIDENCE_ID=$SOURCE_PVS_EVIDENCE_ID"
echo "STANDALONE_PVS_RUN_ID=$STANDALONE_PVS_RUN_ID"
echo "SOURCE_CONTRACT_STATUS=$SOURCE_CONTRACT_STATUS"
echo "SOURCE_RO6_INSTANCE_NAME_STATUS=$SOURCE_RO6_INSTANCE_NAME_STATUS"
echo "SOURCE_FILLER_REMOVAL_STATUS=$SOURCE_FILLER_REMOVAL_STATUS"
echo "SOURCE_PHYSICAL_TIE_INSTANCE_COUNT=$SOURCE_PHYSICAL_TIE_INSTANCE_COUNT"
echo "TOOL_RC=$LVS_RC"
echo "PVS_LVS=$LVS_GATE"
echo "LVS_BLACKBOX_RULE_STATUS=$BLACKBOX_RULE_STATUS"
echo "LVS_BLACKBOX_APPLICATION_STATUS=$BLACKBOX_APPLICATION_STATUS"
echo "LVS_BLACKBOXED_CELL_COUNT=$BLACKBOXED_CELL_COUNT"
echo "LVS_BLACKBOX_CLS_SHA256=$BOUNDARY_CLS_SHA256"
echo "LVS_BLACKBOX_CLS_PATH_STATUS=$BOUNDARY_CLS_PATH_STATUS"
echo "TOP_INITIAL_PINS=$BOUNDARY_TOP_INITIAL_PINS"
echo "TOP_COMPARE_PINS=$BOUNDARY_TOP_COMPARE_PINS"
echo "TOP_CELL_STATUS=$BOUNDARY_TOP_CELL_STATUS"
echo "LVS_BUS_PIN_MAP_EFFECTIVE_VALUE=$BUS_PIN_MAP_EFFECTIVE_VALUE"
echo "LVS_BUS_PIN_MAP_RULE_STATUS=$BUS_PIN_MAP_RULE_STATUS"
echo "LVS_GLOBAL_SIGNAL_PORT_RULE_STATUS=$GLOBAL_SIGNAL_PORT_RULE_STATUS"
echo "RO6_BLACKBOX_CELL_MATCH_STATUS=$RO6_CELL_MATCH_STATUS"
echo "RO6_BLACKBOX_INITIAL_PINS=$RO6_INITIAL_PINS"
echo "RO6_BLACKBOX_COMPARE_PINS=$RO6_COMPARE_PINS"
echo "RO6_ANGLE_BUS_MISSING_PIN_COUNT=$RO6_ANGLE_BUS_MISSING_PIN_COUNT"
echo "RO6_SQUARE_BUS_MISSING_PIN_COUNT=$RO6_SQUARE_BUS_MISSING_PIN_COUNT"
echo "TIE1_UNMATCHED_PIN_COUNT=$TIE1_UNMATCHED_PIN_COUNT"
echo "TIE1_MISMATCHED_NET_COUNT=$TIE1_MISMATCHED_NET_COUNT"
echo "TIE1_MISMATCHED_INSTANCE_CASCADE_COUNT=$TIE1_MISMATCHED_INSTANCE_CASCADE_COUNT"
echo "LAYOUT_OPEN_NET_COUNT=$LAYOUT_OPEN_NET_COUNT"
echo "SHORTS_OPENS_RECORD_COUNT=$SHORTS_OPENS_RECORD_COUNT"
echo "MISMATCHED_NET_RECORD_COUNT=$MISMATCHED_NET_RECORD_COUNT"
echo "MISMATCHED_INSTANCE_RECORD_COUNT=$MISMATCHED_INSTANCE_RECORD_COUNT"
echo "BOUNDARY_REMAINDER_CLASS=$BOUNDARY_REMAINDER_CLASS"
echo "RO6_STANDALONE_LVS_REQUIRED=YES"
echo "PVS_HIERARCHICAL_LVS_STATUS=$HIERARCHICAL_LVS_STATUS"
echo "LVS_PROOF_METHOD=$([[ "$HIERARCHICAL_LVS_STATUS" == MATCH ]] && echo HIERARCHICAL_TOP_BLACKBOX_PLUS_STANDALONE_RO || echo DIAGNOSTIC_BOUNDARY_ONLY)"
echo "DRC_STATUS=NOT_RUN_BY_SCOPE"
echo "SIGNOFF_ELIGIBLE=NO"
echo "DECISION=$DECISION"
echo "PUBLISH_RC=$PUBLISH_RC"
echo "NEXT_EXPECTED_HEAD=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null)"
echo "NEXT_STAGE=$NEXT_STAGE"

if [[ "$BOUNDARY_RECOVERY_STATUS" == PASS && "$PUBLISH_RC" -eq 0 ]]; then
  exit 0
fi
exit 1
