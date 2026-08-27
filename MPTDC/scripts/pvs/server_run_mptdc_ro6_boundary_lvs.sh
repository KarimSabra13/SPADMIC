#!/usr/bin/env bash
# Re-run only PVS LVS with an explicit RO_tune6 digital-top blackbox boundary.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
REPO_ROOT="${MPTDC_BOUNDARY_LVS_REPO_ROOT:-$DEFAULT_REPO_ROOT}"
PUBLISHER="${MPTDC_BOUNDARY_LVS_PUBLISHER:-$REPO_ROOT/MPTDC/ci/publish_mptdc_server_snapshot.sh}"
LVS_SCRIPT="${MPTDC_BOUNDARY_LVS_REPLAY:-$SCRIPT_DIR/03_replay_pvs_lvs_from_template.sh}"
INNOVUS_WORK="${MPTDC_INNOVUS_WORK:-/sim/ksabra/SPADMIC_work/innovus}"

SOURCE_PVS_RUN_ID=""
PVS_RUN_ID=""
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD:-}"

usage() {
  cat <<'USAGE'
Usage:
  server_run_mptdc_ro6_boundary_lvs.sh --source-pvs-run-id <id> [options]

Options:
  --source-pvs-run-id <id>  Existing published diagnostic PVS run whose exact
                            GDS/source/CDL/HCell tuple will be reused read-only.
  --run-id <id>             New LVS-only result directory name.
  --expected-head <sha>     Require repository HEAD to match this commit.
  --innovus-work <path>     Innovus/PVS result root.
  -h, --help                Show this help.

This mode checks only digital-top connectivity at the RO_tune6 boundary. It
does not prove RO_tune6 internals, does not run DRC, and is never signoff.
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
    --run-id) PVS_RUN_ID="${2:?missing --run-id value}"; shift 2 ;;
    --expected-head) EXPECTED_HEAD_VALUE="${2:?missing --expected-head value}"; shift 2 ;;
    --innovus-work) INNOVUS_WORK="${2:?missing --innovus-work value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$SOURCE_PVS_RUN_ID" ]] || { echo "ERROR: --source-pvs-run-id is required" >&2; usage >&2; exit 2; }
[[ "$SOURCE_PVS_RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "ERROR: unsafe source PVS run id" >&2; exit 2; }
if [[ -z "$PVS_RUN_ID" ]]; then
  PVS_RUN_ID="$(date +%Y%m%d)_mptdc_bufftap0_ro6_boundary_lvs_$(date +%H%M%S)"
fi
[[ "$PVS_RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "ERROR: unsafe PVS run id" >&2; exit 2; }

SOURCE_PVS_DIR="$INNOVUS_WORK/$SOURCE_PVS_RUN_ID"
PVS_DIR="$INNOVUS_WORK/$PVS_RUN_ID"
SOURCE_GDS="$SOURCE_PVS_DIR/outputs/mptdc_axis_core_merged_stdcell_ro6.gds"
SOURCE_VERILOG="$SOURCE_PVS_DIR/outputs/mptdc_axis_core_pnr_lvs_with_pg_NO_DCELL_MODULES_RO6_PINFIX_NOATTR_CLEAN.v"
SOURCE_HCELL="$SOURCE_PVS_DIR/outputs/pvs_hcell_ro6.txt"
SOURCE_HASH_MANIFEST="$SOURCE_PVS_DIR/manifests/pvs_input_hashes.rpt"
SOURCE_LVS_STATUS_REPORT="$SOURCE_PVS_DIR/reports/pvs_lvs_status.rpt"
SOURCE_LVS_TOOL_STATUS_REPORT="$SOURCE_PVS_DIR/reports/pvs_lvs_tool_status.rpt"

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

SOURCE_GATE_LVS_STATUS="$(report_value "$SOURCE_LVS_STATUS_REPORT" PVS_LVS_STATUS)"
SOURCE_PVS_RC="$(report_value "$SOURCE_LVS_TOOL_STATUS_REPORT" PVS_LVS_RC)"
SOURCE_BLACKBOXED_CELL_COUNT=MISSING
SOURCE_RO6_WRAPPER_MISMATCH_COUNT=0
if [[ -s "$SOURCE_CLS" ]]; then
  SOURCE_BLACKBOXED_CELL_COUNT="$(awk -F '|' '/Cells that have been blackboxed/ {value=$2; gsub(/[[:space:]]/, "", value); print value; exit}' "$SOURCE_CLS")"
  [[ -n "$SOURCE_BLACKBOXED_CELL_COUNT" ]] || SOURCE_BLACKBOXED_CELL_COUNT=MISSING
  SOURCE_RO6_WRAPPER_MISMATCH_COUNT="$(grep -Fc '(-, RO_tune6())' "$SOURCE_CLS" 2>/dev/null || true)"
fi

echo "SOURCE_PVS_RUN_ID=$SOURCE_PVS_RUN_ID"
echo "SOURCE_PVS_DIR=$SOURCE_PVS_DIR"
echo "SOURCE_LVS_RUN=$SOURCE_LVS_RUN"
echo "SOURCE_GATE_LVS_STATUS=$SOURCE_GATE_LVS_STATUS"
echo "SOURCE_CLS_RUN_RESULT=$SOURCE_CLS_RUN_RESULT"
echo "SOURCE_PVS_RC=$SOURCE_PVS_RC"
echo "SOURCE_MISMATCHED_MARKER_COUNT=$SOURCE_MISMATCHED_MARKER_COUNT"
echo "SOURCE_MATCHED_MARKER_COUNT=$SOURCE_MATCHED_MARKER_COUNT"
echo "SOURCE_BLACKBOXED_CELL_COUNT=$SOURCE_BLACKBOXED_CELL_COUNT"
echo "SOURCE_RO6_WRAPPER_MISMATCH_COUNT=$SOURCE_RO6_WRAPPER_MISMATCH_COUNT"
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
for path in "$SOURCE_GDS" "$SOURCE_VERILOG" "$SOURCE_HCELL" "$SOURCE_HASH_MANIFEST" "$PUBLISHER" "$LVS_SCRIPT"; do
  [[ -s "$path" ]] || { echo "STOP: required source or script missing: $path"; PREFLIGHT=FAIL; }
done
[[ ! -e "$PVS_DIR" ]] || { echo "STOP: result directory already exists: $PVS_DIR"; PREFLIGHT=FAIL; }

echo "PVS_RO6_BOUNDARY_PREFLIGHT=$PREFLIGHT"
if [[ "$PREFLIGHT" != PASS ]]; then
  echo "DECISION=FAIL_STOP"
  exit 4
fi

mkdir -p "$PVS_DIR/manifests" "$PVS_DIR/reports" "$PVS_DIR/logs" "$PVS_DIR/pvs_lvs"
ln -s "$SOURCE_PVS_DIR/outputs" "$PVS_DIR/outputs"
sed "s|$SOURCE_PVS_DIR|$PVS_DIR|g" "$SOURCE_HASH_MANIFEST" \
  > "$PVS_DIR/manifests/pvs_input_hashes.rpt"

SOURCE_CLS_SHA256="$(sha256sum "$SOURCE_CLS" | awk '{print $1}')"
SOURCE_GDS_SHA256="$(sha256sum "$SOURCE_GDS" | awk '{print $1}')"
SOURCE_VERILOG_SHA256="$(sha256sum "$SOURCE_VERILOG" | awk '{print $1}')"
SOURCE_HCELL_SHA256="$(sha256sum "$SOURCE_HCELL" | awk '{print $1}')"
{
  echo "PVS_RUN_CLASS=DIAGNOSTIC_RO6_BOUNDARY_BLACKBOX"
  echo "DIAGNOSTIC_SCOPE=LVS_ONLY_RO6_BOUNDARY"
  echo "SOURCE_PVS_RUN_ID=$SOURCE_PVS_RUN_ID"
  echo "SOURCE_PVS_DIR=$SOURCE_PVS_DIR"
  echo "SOURCE_LVS_RUN=$SOURCE_LVS_RUN"
  echo "SOURCE_GATE_LVS_STATUS=$SOURCE_GATE_LVS_STATUS"
  echo "SOURCE_CLS_RUN_RESULT=$SOURCE_CLS_RUN_RESULT"
  echo "SOURCE_PVS_RC=$SOURCE_PVS_RC"
  echo "SOURCE_CLS=$SOURCE_CLS"
  echo "SOURCE_CLS_SHA256=$SOURCE_CLS_SHA256"
  echo "SOURCE_MISMATCHED_MARKER_COUNT=$SOURCE_MISMATCHED_MARKER_COUNT"
  echo "SOURCE_MATCHED_MARKER_COUNT=$SOURCE_MATCHED_MARKER_COUNT"
  echo "SOURCE_BLACKBOXED_CELL_COUNT=$SOURCE_BLACKBOXED_CELL_COUNT"
  echo "SOURCE_RO6_WRAPPER_MISMATCH_COUNT=$SOURCE_RO6_WRAPPER_MISMATCH_COUNT"
  echo "MERGED_GDS_SHA256=$SOURCE_GDS_SHA256"
  echo "LVS_SOURCE_SHA256=$SOURCE_VERILOG_SHA256"
  echo "LVS_HCELL_SHA256=$SOURCE_HCELL_SHA256"
  echo "BLACKBOX_CELL=RO_tune6"
  echo "RO6_BUS_PIN_NORMALIZATION=LVS_VERILOG_BUS_MAP_BY_POSITION"
  echo "VERILOG_GLOBAL_SIGNAL_PORT_POLICY=DO_NOT_PROMOTE"
  echo "RO6_STANDALONE_LVS_REQUIRED=YES"
  echo "DRC_STATUS=NOT_RUN_BY_SCOPE"
  echo "SIGNOFF_ELIGIBLE=NO"
} > "$PVS_DIR/manifests/pvs_ro6_boundary_blackbox_scope.rpt"

NEW_LVS_RUN="$PVS_DIR/pvs_lvs/mptdc_axis_core_ro6_boundary_blackbox_script"
set +e
bash "$LVS_SCRIPT" \
  --prepared-dir "$PVS_DIR" \
  --template-run "$SOURCE_LVS_RUN" \
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
BUS_PIN_MAP_RULE_STATUS="$(report_value "$BOUNDARY_REPORT" LVS_BUS_PIN_MAP_RULE_STATUS)"
GLOBAL_SIGNAL_PORT_RULE_STATUS="$(report_value "$BOUNDARY_REPORT" LVS_GLOBAL_SIGNAL_PORT_RULE_STATUS)"
RO6_CELL_MATCH_STATUS="$(report_value "$BOUNDARY_REPORT" RO6_BLACKBOX_CELL_MATCH_STATUS)"
RO6_ANGLE_BUS_MISSING_PIN_COUNT="$(report_value "$BOUNDARY_REPORT" RO6_ANGLE_BUS_MISSING_PIN_COUNT)"
RO6_SQUARE_BUS_MISSING_PIN_COUNT="$(report_value "$BOUNDARY_REPORT" RO6_SQUARE_BUS_MISSING_PIN_COUNT)"
TIE1_UNMATCHED_PIN_COUNT="$(report_value "$BOUNDARY_REPORT" TIE1_UNMATCHED_PIN_COUNT)"
LAYOUT_OPEN_NET_COUNT="$(report_value "$BOUNDARY_REPORT" LAYOUT_OPEN_NET_COUNT)"
SHORTS_OPENS_RECORD_COUNT="$(report_value "$BOUNDARY_REPORT" SHORTS_OPENS_RECORD_COUNT)"
MISMATCHED_NET_RECORD_COUNT="$(report_value "$BOUNDARY_REPORT" MISMATCHED_NET_RECORD_COUNT)"
MISMATCHED_INSTANCE_RECORD_COUNT="$(report_value "$BOUNDARY_REPORT" MISMATCHED_INSTANCE_RECORD_COUNT)"
VDD_OPEN_SECTION_COUNT="$(report_value "$BOUNDARY_REPORT" VDD_OPEN_SECTION_COUNT)"
VSS_OPEN_SECTION_COUNT="$(report_value "$BOUNDARY_REPORT" VSS_OPEN_SECTION_COUNT)"
SIGNOFF_ELIGIBLE="$(report_value "$BOUNDARY_REPORT" SIGNOFF_ELIGIBLE)"

DECISION=FAIL_STOP
NEXT_STAGE=STOP_AND_REVIEW_PUBLISHED_EVIDENCE
BOUNDARY_REMAINDER_CLASS=UNCLASSIFIED
if [[ "$LVS_RC" -eq 0 && "$LVS_STATUS" == PASS && "$LVS_GATE" == MATCH && \
      "$LVS_TOOL_RC" == 0 && "$BLACKBOX_RULE_STATUS" == PASS && \
      "$BLACKBOX_APPLICATION_STATUS" == PASS && "$BLACKBOXED_CELL_COUNT" =~ ^[0-9]+$ && \
      "$BLACKBOXED_CELL_COUNT" -ge 1 && "$BUS_PIN_MAP_RULE_STATUS" == PASS && \
      "$GLOBAL_SIGNAL_PORT_RULE_STATUS" == PASS && "$RO6_CELL_MATCH_STATUS" == PASS && \
      "$SIGNOFF_ELIGIBLE" == NO ]]; then
  DECISION=PASS_BOUNDARY_CONTINUE
  NEXT_STAGE=RO6_STANDALONE_LVS_EVIDENCE_AND_MINAREA_REPAIR
  BOUNDARY_REMAINDER_CLASS=NONE_MATCH
elif [[ "$LVS_GATE" == MISMATCH && "$LVS_TOOL_RC" == 0 && \
        "$BLACKBOX_RULE_STATUS" == PASS && "$BLACKBOX_APPLICATION_STATUS" == PASS && \
        "$BUS_PIN_MAP_RULE_STATUS" == PASS && "$GLOBAL_SIGNAL_PORT_RULE_STATUS" == PASS && \
        "$RO6_CELL_MATCH_STATUS" == PASS && "$RO6_ANGLE_BUS_MISSING_PIN_COUNT" == 0 && \
        "$RO6_SQUARE_BUS_MISSING_PIN_COUNT" == 0 && "$TIE1_UNMATCHED_PIN_COUNT" == 0 && \
        "$LAYOUT_OPEN_NET_COUNT" == 4 && "$SHORTS_OPENS_RECORD_COUNT" == 2 && \
        "$MISMATCHED_NET_RECORD_COUNT" == 0 && "$MISMATCHED_INSTANCE_RECORD_COUNT" == 0 && \
        "$VDD_OPEN_SECTION_COUNT" == 1 && "$VSS_OPEN_SECTION_COUNT" == 1 ]]; then
  BOUNDARY_REMAINDER_CLASS=RO6_PG_OPEN_ONLY
  NEXT_STAGE=RO6_MANUAL_PG_PATCH_BEFORE_BOUNDARY_LVS
elif [[ "$BUS_PIN_MAP_RULE_STATUS" == PASS && "$GLOBAL_SIGNAL_PORT_RULE_STATUS" == PASS && \
        "$RO6_CELL_MATCH_STATUS" == PASS ]]; then
  BOUNDARY_REMAINDER_CLASS=TOP_CONNECTIVITY_MISMATCH
fi

{
  echo "STEP=PVS_RO6_BOUNDARY_LVS"
  echo "SOURCE_PVS_RUN_ID=$SOURCE_PVS_RUN_ID"
  echo "PVS_RUN_CLASS=DIAGNOSTIC_RO6_BOUNDARY_BLACKBOX"
  echo "LVS_RC=$LVS_RC"
  echo "STATUS=$LVS_STATUS"
  echo "PVS_LVS_STATUS=$LVS_GATE"
  echo "PVS_RC=$LVS_TOOL_RC"
  echo "LVS_BLACKBOX_RULE_STATUS=$BLACKBOX_RULE_STATUS"
  echo "LVS_BLACKBOX_APPLICATION_STATUS=$BLACKBOX_APPLICATION_STATUS"
  echo "LVS_BLACKBOXED_CELL_COUNT=$BLACKBOXED_CELL_COUNT"
  echo "LVS_BUS_PIN_MAP_RULE_STATUS=$BUS_PIN_MAP_RULE_STATUS"
  echo "LVS_GLOBAL_SIGNAL_PORT_RULE_STATUS=$GLOBAL_SIGNAL_PORT_RULE_STATUS"
  echo "RO6_BLACKBOX_CELL_MATCH_STATUS=$RO6_CELL_MATCH_STATUS"
  echo "RO6_ANGLE_BUS_MISSING_PIN_COUNT=$RO6_ANGLE_BUS_MISSING_PIN_COUNT"
  echo "RO6_SQUARE_BUS_MISSING_PIN_COUNT=$RO6_SQUARE_BUS_MISSING_PIN_COUNT"
  echo "TIE1_UNMATCHED_PIN_COUNT=$TIE1_UNMATCHED_PIN_COUNT"
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

publish_stage "$PVS_RUN_ID"
PUBLISH_RC=$?
if [[ "$PUBLISH_RC" -ne 0 ]]; then
  DECISION=FAIL_STOP
  NEXT_STAGE=REPUBLISH_BOUNDARY_LVS_EVIDENCE
fi

echo "PVS_BOUNDARY_RECOVERY_STATUS=$([[ "$DECISION" == PASS_BOUNDARY_CONTINUE ]] && echo PASS || echo FAIL)"
echo "PVS_RUN_ID=$PVS_RUN_ID"
echo "SOURCE_PVS_RUN_ID=$SOURCE_PVS_RUN_ID"
echo "TOOL_RC=$LVS_RC"
echo "PVS_LVS=$LVS_GATE"
echo "LVS_BLACKBOX_RULE_STATUS=$BLACKBOX_RULE_STATUS"
echo "LVS_BLACKBOX_APPLICATION_STATUS=$BLACKBOX_APPLICATION_STATUS"
echo "LVS_BLACKBOXED_CELL_COUNT=$BLACKBOXED_CELL_COUNT"
echo "LVS_BUS_PIN_MAP_RULE_STATUS=$BUS_PIN_MAP_RULE_STATUS"
echo "LVS_GLOBAL_SIGNAL_PORT_RULE_STATUS=$GLOBAL_SIGNAL_PORT_RULE_STATUS"
echo "RO6_BLACKBOX_CELL_MATCH_STATUS=$RO6_CELL_MATCH_STATUS"
echo "RO6_ANGLE_BUS_MISSING_PIN_COUNT=$RO6_ANGLE_BUS_MISSING_PIN_COUNT"
echo "RO6_SQUARE_BUS_MISSING_PIN_COUNT=$RO6_SQUARE_BUS_MISSING_PIN_COUNT"
echo "TIE1_UNMATCHED_PIN_COUNT=$TIE1_UNMATCHED_PIN_COUNT"
echo "LAYOUT_OPEN_NET_COUNT=$LAYOUT_OPEN_NET_COUNT"
echo "SHORTS_OPENS_RECORD_COUNT=$SHORTS_OPENS_RECORD_COUNT"
echo "MISMATCHED_NET_RECORD_COUNT=$MISMATCHED_NET_RECORD_COUNT"
echo "MISMATCHED_INSTANCE_RECORD_COUNT=$MISMATCHED_INSTANCE_RECORD_COUNT"
echo "BOUNDARY_REMAINDER_CLASS=$BOUNDARY_REMAINDER_CLASS"
echo "RO6_STANDALONE_LVS_REQUIRED=YES"
echo "DRC_STATUS=NOT_RUN_BY_SCOPE"
echo "SIGNOFF_ELIGIBLE=NO"
echo "DECISION=$DECISION"
echo "PUBLISH_RC=$PUBLISH_RC"
echo "NEXT_EXPECTED_HEAD=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null)"
echo "NEXT_STAGE=$NEXT_STAGE"

if [[ "$DECISION" == PASS_BOUNDARY_CONTINUE && "$PUBLISH_RC" -eq 0 ]]; then
  exit 0
fi
exit 1
