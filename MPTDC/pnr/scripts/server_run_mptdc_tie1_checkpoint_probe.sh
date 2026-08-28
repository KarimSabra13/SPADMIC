#!/usr/bin/env bash
# Publish a hash-guarded, read-only tie1 inventory from the Step 5R checkpoint.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
REPO_ROOT="${MPTDC_TIE1_PROBE_REPO_ROOT:-$DEFAULT_REPO_ROOT}"
PUBLISHER="${MPTDC_TIE1_PROBE_PUBLISHER:-$REPO_ROOT/MPTDC/ci/publish_mptdc_server_snapshot.sh}"
PROBE_TCL="${MPTDC_TIE1_PROBE_TCL:-$SCRIPT_DIR/innovus_mptdc_tie1_checkpoint_probe.tcl}"
INNOVUS_BIN="${MPTDC_TIE1_PROBE_INNOVUS_BIN:-innovus}"
INNOVUS_WORK="${MPTDC_INNOVUS_WORK:-/sim/ksabra/SPADMIC_work/innovus}"

BOUNDARY_PVS_RUN_ID=""
RUN_ID=""
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD:-}"

usage() {
  cat <<'USAGE'
Usage:
  server_run_mptdc_tie1_checkpoint_probe.sh --boundary-pvs-run-id <id> [options]

Options:
  --boundary-pvs-run-id <id> Published exact Step 5R TOP_CONNECTIVITY_MISMATCH run.
  --run-id <id>              New read-only Innovus probe run id.
  --expected-head <sha>      Require repository HEAD to match this commit.
  --innovus-work <path>      Innovus/PVS result root.
  -h, --help                 Show this help.

The driver derives the source checkpoint and physical LVS source from the
published boundary manifest. It restores only a private checkpoint copy and
does not insert tie cells, route nets, save a design, or claim LVS closure.
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

checkpoint_content_hash() {
  local checkpoint="$1"
  if [[ -d "$checkpoint" ]]; then
    (
      cd "$checkpoint" 2>/dev/null || return 1
      find -L . -type f \
        ! -name '*.cdslck' ! -name '*.lock' ! -name '.*lock*' \
        -print0 2>/dev/null |
        LC_ALL=C sort -z |
        while IFS= read -r -d '' file; do
          printf '%s\t' "$file"
          sha256sum "$file"
        done
    ) | sha256sum | awk '{print $1}'
  elif [[ -f "$checkpoint" ]]; then
    file_sha256 "$checkpoint"
  else
    printf 'MISSING\n'
  fi
}

require_report_value() {
  local report="$1"
  local key="$2"
  local expected="$3"
  local actual
  actual="$(report_value "$report" "$key")"
  if [[ "$actual" != "$expected" ]]; then
    echo "STOP: boundary gate $key expected '$expected', got '$actual'"
    PREFLIGHT=FAIL
  fi
}

publish_stage() {
  MPTDC_SNAPSHOT_MAX_TEXT_BYTES=8388608 \
    bash "$PUBLISHER" innovus "$RUN_ID" "$RUN_DIR" TIE1_CHECKPOINT_PROBE
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

[[ -n "$BOUNDARY_PVS_RUN_ID" ]] || {
  echo "ERROR: --boundary-pvs-run-id is required" >&2
  usage >&2
  exit 2
}
[[ "$BOUNDARY_PVS_RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]] || {
  echo "ERROR: unsafe boundary run id" >&2
  exit 2
}
if [[ -z "$RUN_ID" ]]; then
  RUN_ID="$(date +%Y%m%d)_mptdc_tie1_checkpoint_probe_$(date +%H%M%S)"
fi
[[ "$RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "ERROR: unsafe probe run id" >&2; exit 2; }

BOUNDARY_DIR="$INNOVUS_WORK/$BOUNDARY_PVS_RUN_ID"
BOUNDARY_GATE="$BOUNDARY_DIR/reports/operator_gate_pvs_ro6_boundary_lvs.rpt"
BOUNDARY_HASH_MANIFEST="$BOUNDARY_DIR/manifests/pvs_input_hashes.rpt"
TRACKED_BOUNDARY_DIR="$REPO_ROOT/MPTDC/docs/server_snapshots/pvs/$BOUNDARY_PVS_RUN_ID"
TRACKED_BOUNDARY_GATE="$TRACKED_BOUNDARY_DIR/reports/operator_gate_pvs_ro6_boundary_lvs.rpt"
TRACKED_BOUNDARY_HASH_MANIFEST="$TRACKED_BOUNDARY_DIR/manifests/pvs_input_hashes.rpt"
RUN_DIR="$INNOVUS_WORK/$RUN_ID"

cd "$REPO_ROOT" || exit 3
ACTUAL_HEAD="$(git rev-parse HEAD 2>/dev/null)"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
ORIGIN_HEAD="$(git rev-parse --verify refs/remotes/origin/SPADMIC_test 2>/dev/null || true)"
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD_VALUE:-${ORIGIN_HEAD:-$ACTUAL_HEAD}}"
TRACKED_STATUS="$(git status --short --untracked-files=no 2>/dev/null)"

SOURCE_PVS_RUN_ID="$(report_value "$BOUNDARY_GATE" SOURCE_PVS_RUN_ID)"
SOURCE_CHECKPOINT="$(report_value "$BOUNDARY_HASH_MANIFEST" SOURCE_CHECKPOINT)"
TOP_CELL="$(report_value "$BOUNDARY_HASH_MANIFEST" TOP_CELL)"
PHYSICAL_SOURCE="$(report_value "$BOUNDARY_HASH_MANIFEST" LVS_SOURCE_PHYSICAL_PG_PATH)"
PHYSICAL_SOURCE_EXPECTED_SHA="$(report_value "$BOUNDARY_HASH_MANIFEST" LVS_SOURCE_PHYSICAL_PG_SHA256)"
SOURCE_FILTER="$INNOVUS_WORK/$SOURCE_PVS_RUN_ID/reports/lvs_source_filter.rpt"
TRACKED_SOURCE_FILTER="$REPO_ROOT/MPTDC/docs/server_snapshots/pvs/${SOURCE_PVS_RUN_ID}_04_lvs/reports/lvs_source_filter.rpt"
SOURCE_FILTER_INPUT="$(report_value "$SOURCE_FILTER" INPUT)"
SOURCE_FILTER_INPUT_SHA="$(report_value "$SOURCE_FILTER" INPUT_SHA256)"

echo "BOUNDARY_PVS_RUN_ID=$BOUNDARY_PVS_RUN_ID"
echo "BOUNDARY_DIR=$BOUNDARY_DIR"
echo "SOURCE_PVS_RUN_ID=$SOURCE_PVS_RUN_ID"
echo "SOURCE_CHECKPOINT=$SOURCE_CHECKPOINT"
echo "PHYSICAL_SOURCE=$PHYSICAL_SOURCE"
echo "RUN_ID=$RUN_ID"
echo "RUN_DIR=$RUN_DIR"
echo "BRANCH=$BRANCH"
echo "ACTUAL_HEAD=$ACTUAL_HEAD"
echo "ORIGIN_HEAD=${ORIGIN_HEAD:-MISSING}"
echo "EXPECTED_HEAD=$EXPECTED_HEAD_VALUE"

PREFLIGHT=PASS
[[ "$BRANCH" == SPADMIC_test ]] || { echo "STOP: branch must be SPADMIC_test"; PREFLIGHT=FAIL; }
[[ "$ACTUAL_HEAD" == "$EXPECTED_HEAD_VALUE" ]] || { echo "STOP: HEAD mismatch"; PREFLIGHT=FAIL; }
if [[ -n "$ORIGIN_HEAD" && "$ACTUAL_HEAD" != "$ORIGIN_HEAD" ]]; then
  echo "STOP: local HEAD does not match origin/SPADMIC_test"
  PREFLIGHT=FAIL
fi
[[ -z "$TRACKED_STATUS" ]] || { echo "$TRACKED_STATUS"; echo "STOP: tracked working tree is dirty"; PREFLIGHT=FAIL; }
[[ -s "$BOUNDARY_GATE" && -s "$BOUNDARY_HASH_MANIFEST" ]] || {
  echo "STOP: live boundary gate or hash manifest is missing"
  PREFLIGHT=FAIL
}
[[ -s "$TRACKED_BOUNDARY_GATE" && -s "$TRACKED_BOUNDARY_HASH_MANIFEST" ]] || {
  echo "STOP: tracked boundary snapshot is missing"
  PREFLIGHT=FAIL
}
if [[ -s "$BOUNDARY_GATE" && -s "$TRACKED_BOUNDARY_GATE" ]]; then
  cmp -s "$BOUNDARY_GATE" "$TRACKED_BOUNDARY_GATE" || {
    echo "STOP: live boundary gate differs from its published snapshot"
    PREFLIGHT=FAIL
  }
fi
if [[ -s "$BOUNDARY_HASH_MANIFEST" && -s "$TRACKED_BOUNDARY_HASH_MANIFEST" ]]; then
  cmp -s "$BOUNDARY_HASH_MANIFEST" "$TRACKED_BOUNDARY_HASH_MANIFEST" || {
    echo "STOP: live boundary hashes differ from the published snapshot"
    PREFLIGHT=FAIL
  }
fi

require_report_value "$BOUNDARY_GATE" PVS_RUN_CLASS DIAGNOSTIC_RO6_BOUNDARY_BLACKBOX
require_report_value "$BOUNDARY_GATE" LVS_RC 8
require_report_value "$BOUNDARY_GATE" STATUS FAIL
require_report_value "$BOUNDARY_GATE" PVS_LVS_STATUS MISMATCH
require_report_value "$BOUNDARY_GATE" PVS_RC 0
require_report_value "$BOUNDARY_GATE" LVS_BLACKBOX_RULE_STATUS PASS
require_report_value "$BOUNDARY_GATE" LVS_BLACKBOX_APPLICATION_STATUS PASS
require_report_value "$BOUNDARY_GATE" LVS_BLACKBOXED_CELL_COUNT 1
require_report_value "$BOUNDARY_GATE" LVS_BUS_PIN_MAP_EFFECTIVE_VALUE NO
require_report_value "$BOUNDARY_GATE" LVS_BUS_PIN_MAP_RULE_STATUS NOT_USED_EXACT_SCALAR_SOURCE
require_report_value "$BOUNDARY_GATE" LVS_GLOBAL_SIGNAL_PORT_RULE_STATUS PASS
require_report_value "$BOUNDARY_GATE" RO6_BLACKBOX_CELL_MATCH_STATUS PASS
require_report_value "$BOUNDARY_GATE" RO6_ANGLE_BUS_MISSING_PIN_COUNT 0
require_report_value "$BOUNDARY_GATE" RO6_SQUARE_BUS_MISSING_PIN_COUNT 0
require_report_value "$BOUNDARY_GATE" TIE1_UNMATCHED_PIN_COUNT 0
require_report_value "$BOUNDARY_GATE" TIE1_MISMATCHED_NET_COUNT 1
require_report_value "$BOUNDARY_GATE" TIE1_MISMATCHED_INSTANCE_CASCADE_COUNT 334
require_report_value "$BOUNDARY_GATE" LAYOUT_OPEN_NET_COUNT 2
require_report_value "$BOUNDARY_GATE" SHORTS_OPENS_RECORD_COUNT 1
require_report_value "$BOUNDARY_GATE" MISMATCHED_NET_RECORD_COUNT 91
require_report_value "$BOUNDARY_GATE" MISMATCHED_INSTANCE_RECORD_COUNT 334
require_report_value "$BOUNDARY_GATE" VDD_OPEN_SECTION_COUNT 0
require_report_value "$BOUNDARY_GATE" VSS_OPEN_SECTION_COUNT 1
require_report_value "$BOUNDARY_GATE" BOUNDARY_REMAINDER_CLASS TOP_CONNECTIVITY_MISMATCH
require_report_value "$BOUNDARY_GATE" RO6_STANDALONE_LVS_REQUIRED YES
require_report_value "$BOUNDARY_GATE" SIGNOFF_ELIGIBLE NO
require_report_value "$BOUNDARY_GATE" DECISION FAIL_STOP

[[ "$SOURCE_PVS_RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]] || {
  echo "STOP: unsafe or missing source PVS run id"
  PREFLIGHT=FAIL
}
[[ "$TOP_CELL" == mptdc_axis_core ]] || { echo "STOP: unexpected top cell: $TOP_CELL"; PREFLIGHT=FAIL; }
case "$SOURCE_CHECKPOINT" in
  "$INNOVUS_WORK"/*/checkpoints/repaired_route.enc.dat) ;;
  *) echo "STOP: source checkpoint is outside the expected immutable lineage"; PREFLIGHT=FAIL ;;
esac
case "$PHYSICAL_SOURCE" in
  "$BOUNDARY_DIR"/outputs/mptdc_axis_core_pnr_lvs_phys_with_pg.v) ;;
  *) echo "STOP: physical LVS source is not the boundary-run output"; PREFLIGHT=FAIL ;;
esac
[[ -e "$SOURCE_CHECKPOINT" ]] || { echo "STOP: source checkpoint is missing"; PREFLIGHT=FAIL; }
[[ -s "$PHYSICAL_SOURCE" ]] || { echo "STOP: boundary physical LVS source is missing"; PREFLIGHT=FAIL; }
[[ -s "$SOURCE_FILTER" && -s "$TRACKED_SOURCE_FILTER" ]] || {
  echo "STOP: physical source contract or its tracked snapshot is missing"
  PREFLIGHT=FAIL
}
if [[ -s "$SOURCE_FILTER" && -s "$TRACKED_SOURCE_FILTER" ]]; then
  cmp -s "$SOURCE_FILTER" "$TRACKED_SOURCE_FILTER" || {
    echo "STOP: live physical source contract differs from its published snapshot"
    PREFLIGHT=FAIL
  }
fi
[[ -s "$PROBE_TCL" && -s "$PUBLISHER" ]] || { echo "STOP: probe Tcl or publisher missing"; PREFLIGHT=FAIL; }
[[ ! -e "$RUN_DIR" ]] || { echo "STOP: result directory already exists: $RUN_DIR"; PREFLIGHT=FAIL; }

require_report_value "$SOURCE_FILTER" LVS_SOURCE_CONTRACT_STATUS PASS
require_report_value "$SOURCE_FILTER" SOURCE_KIND INNOVUS_SAVE_NETLIST_PHYS_INCLUDE_POWER_GROUND
require_report_value "$SOURCE_FILTER" PHYSICAL_ONLY_FILLER_REMOVAL_STATUS PASS
require_report_value "$SOURCE_FILTER" RO_TUNE6_INSTANCE_NAME_STATUS PASS
require_report_value "$SOURCE_FILTER" PHYSICAL_TIE_MASTER_COUNT 0
require_report_value "$SOURCE_FILTER" PHYSICAL_TIE_INSTANCE_COUNT 0
require_report_value "$SOURCE_FILTER" PHYSICAL_TIE_PRESERVATION_STATUS PASS
require_report_value "$SOURCE_FILTER" UNRESOLVED_ACTIVE_MASTER_COUNT 0

PHYSICAL_SOURCE_ACTUAL_SHA="$(file_sha256 "$PHYSICAL_SOURCE")"
SOURCE_FILTER_INPUT_ACTUAL_SHA="$(file_sha256 "$SOURCE_FILTER_INPUT")"
[[ "$PHYSICAL_SOURCE_EXPECTED_SHA" != MISSING && \
   "$PHYSICAL_SOURCE_ACTUAL_SHA" == "$PHYSICAL_SOURCE_EXPECTED_SHA" ]] || {
  echo "STOP: boundary physical source hash mismatch"
  PREFLIGHT=FAIL
}
[[ "$SOURCE_FILTER_INPUT_SHA" == "$PHYSICAL_SOURCE_EXPECTED_SHA" && \
   "$SOURCE_FILTER_INPUT_ACTUAL_SHA" == "$PHYSICAL_SOURCE_EXPECTED_SHA" ]] || {
  echo "STOP: physical source contract is not hash-identical to the boundary source"
  PREFLIGHT=FAIL
}

RESTORE_COMMAND_COUNT="$({ sed '/^[[:space:]]*#/d' "$PROBE_TCL" 2>/dev/null | \
  grep -Ec '(^|[[:space:]{])restoreDesign[[:space:]]' || true; } | tail -1)"
MUTATION_COMMAND_COUNT="$({ sed '/^[[:space:]]*#/d' "$PROBE_TCL" 2>/dev/null | \
  grep -Eic '^[[:space:]]*(saveDesign|saveNetlist|defOut|streamOut|routeDesign|globalDetailRoute|ecoRoute|sroute|addTieHiLo|setTieHiLoMode|addInst|createInst|deleteInst|placeInstance|connectGlobalNet|editAddRoute|editDelete|dbDeleteObj|delete_obj|createNet|deleteNet|addStripe|addRing|saveIoFile)([[:space:]]|$)' || true; } | tail -1)"
[[ "$RESTORE_COMMAND_COUNT" == 1 ]] || { echo "STOP: probe must contain exactly one restoreDesign"; PREFLIGHT=FAIL; }
[[ "$MUTATION_COMMAND_COUNT" == 0 ]] || { echo "STOP: mutation command found in read-only probe Tcl"; PREFLIGHT=FAIL; }

CADENCE_ENV_RC=0
if [[ "$INNOVUS_BIN" == innovus && -f /eda/cadence/eda_2023-2024 ]]; then
  # shellcheck disable=SC1091
  source /eda/cadence/eda_2023-2024 2>/dev/null
  CADENCE_ENV_RC=$?
fi
if [[ "$INNOVUS_BIN" == */* ]]; then
  [[ -x "$INNOVUS_BIN" ]] || { echo "STOP: Innovus executable is unavailable: $INNOVUS_BIN"; PREFLIGHT=FAIL; }
else
  command -v "$INNOVUS_BIN" >/dev/null 2>&1 || {
    echo "STOP: Innovus executable is unavailable: $INNOVUS_BIN"
    PREFLIGHT=FAIL
  }
fi
[[ "$CADENCE_ENV_RC" -eq 0 ]] || { echo "STOP: Cadence environment failed"; PREFLIGHT=FAIL; }
CADENCE_ENV_STATUS=$([[ "$CADENCE_ENV_RC" -eq 0 ]] && echo PASS || echo FAIL)

echo "TIE1_CHECKPOINT_PROBE_PREFLIGHT=$PREFLIGHT"
echo "RESTORE_COMMAND_COUNT=$RESTORE_COMMAND_COUNT"
echo "MUTATION_COMMAND_COUNT=$MUTATION_COMMAND_COUNT"
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

SOURCE_CHECKPOINT_SHA_PRE="$(checkpoint_content_hash "$SOURCE_CHECKPOINT")"
cp -aL "$SOURCE_CHECKPOINT" "$SAFE_CHECKPOINT"
SAFE_COPY_RC=$?
SAFE_CHECKPOINT_SHA_PRE="$(checkpoint_content_hash "$SAFE_CHECKPOINT")"
BOUNDARY_GATE_SHA_PRE="$(file_sha256 "$BOUNDARY_GATE")"
BOUNDARY_MANIFEST_SHA_PRE="$(file_sha256 "$BOUNDARY_HASH_MANIFEST")"
SOURCE_FILTER_SHA_PRE="$(file_sha256 "$SOURCE_FILTER")"
PHYSICAL_SOURCE_SHA_PRE="$(file_sha256 "$PHYSICAL_SOURCE")"
SOURCE_FILTER_INPUT_SHA_PRE="$(file_sha256 "$SOURCE_FILTER_INPUT")"

cp -p "$BOUNDARY_GATE" "$MANIFEST_DIR/source_boundary_operator_gate.rpt"
cp -p "$BOUNDARY_HASH_MANIFEST" "$MANIFEST_DIR/source_boundary_input_hashes.rpt"
cp -p "$SOURCE_FILTER" "$MANIFEST_DIR/source_physical_lvs_contract.rpt"

{
  echo "STEP=TIE1_CHECKPOINT_PROBE_INPUTS"
  echo "DATE=$(date -Iseconds)"
  echo "REPO_ROOT=$REPO_ROOT"
  echo "BRANCH=$BRANCH"
  echo "HEAD=$ACTUAL_HEAD"
  echo "ORIGIN_HEAD=${ORIGIN_HEAD:-MISSING}"
  echo "BOUNDARY_PVS_RUN_ID=$BOUNDARY_PVS_RUN_ID"
  echo "SOURCE_PVS_RUN_ID=$SOURCE_PVS_RUN_ID"
  echo "SOURCE_CHECKPOINT=$SOURCE_CHECKPOINT"
  echo "SAFE_CHECKPOINT=$SAFE_CHECKPOINT"
  echo "PHYSICAL_SOURCE=$PHYSICAL_SOURCE"
  echo "SOURCE_FILTER_INPUT=$SOURCE_FILTER_INPUT"
  echo "SOURCE_CHECKPOINT_SHA256_PRE=$SOURCE_CHECKPOINT_SHA_PRE"
  echo "SAFE_CHECKPOINT_SHA256_PRE=$SAFE_CHECKPOINT_SHA_PRE"
  echo "PHYSICAL_SOURCE_SHA256_PRE=$PHYSICAL_SOURCE_SHA_PRE"
  echo "SOURCE_FILTER_INPUT_SHA256_PRE=$SOURCE_FILTER_INPUT_SHA_PRE"
  echo "BOUNDARY_GATE_SHA256_PRE=$BOUNDARY_GATE_SHA_PRE"
  echo "BOUNDARY_MANIFEST_SHA256_PRE=$BOUNDARY_MANIFEST_SHA_PRE"
  echo "SOURCE_FILTER_SHA256_PRE=$SOURCE_FILTER_SHA_PRE"
  echo "PROBE_TCL=$PROBE_TCL"
  echo "PROBE_TCL_SHA256=$(file_sha256 "$PROBE_TCL")"
  echo "RESTORE_COMMAND_COUNT=$RESTORE_COMMAND_COUNT"
  echo "MUTATION_COMMAND_COUNT=$MUTATION_COMMAND_COUNT"
  echo "SAFE_COPY_RC=$SAFE_COPY_RC"
  echo "CADENCE_ENV_RC=$CADENCE_ENV_RC"
  echo "CADENCE_ENV_STATUS=$CADENCE_ENV_STATUS"
} > "$MANIFEST_DIR/tie1_checkpoint_probe_inputs.rpt"

{
  echo "# Read-only physical LVS source excerpt"
  echo "# Pattern: tie1 or configured physical tie masters"
  grep -nE 'tie1|LOGIC(0|1)(LV)?JIHD' "$PHYSICAL_SOURCE" 2>/dev/null | head -400 || true
} > "$REPORT_DIR/physical_lvs_source_tie1_excerpt.rpt"
TIE1_SOURCE_TOKEN_COUNT="$(grep -Eow 'tie1' "$PHYSICAL_SOURCE" 2>/dev/null | wc -l | tr -d ' ')"
TIE_MASTER_SOURCE_TOKEN_COUNT="$(grep -Eow 'LOGIC(0|1)(LV)?JIHD' "$PHYSICAL_SOURCE" 2>/dev/null | wc -l | tr -d ' ')"

export MPTDC_TIE1_PROBE_CKPT="$SAFE_CHECKPOINT"
export MPTDC_TIE1_PROBE_OUTDIR="$RUN_DIR"
export MPTDC_TIE1_PROBE_TOP="$TOP_CELL"
export MPTDC_TIE1_PROBE_MASTERS="LOGIC1DJIHD LOGIC1LVJIHD LOGIC0DJIHD LOGIC0LVJIHD"

set +e
"$INNOVUS_BIN" -nowin -init "$PROBE_TCL" \
  -log "$LOG_DIR/innovus_tie1_checkpoint_probe.log" \
  2>&1 | tee "$LOG_DIR/innovus_tie1_checkpoint_probe.console.log"
INNOVUS_RC=${PIPESTATUS[0]}
set +e

SOURCE_CHECKPOINT_SHA_POST="$(checkpoint_content_hash "$SOURCE_CHECKPOINT")"
SAFE_CHECKPOINT_SHA_POST="$(checkpoint_content_hash "$SAFE_CHECKPOINT")"
BOUNDARY_GATE_SHA_POST="$(file_sha256 "$BOUNDARY_GATE")"
BOUNDARY_MANIFEST_SHA_POST="$(file_sha256 "$BOUNDARY_HASH_MANIFEST")"
SOURCE_FILTER_SHA_POST="$(file_sha256 "$SOURCE_FILTER")"
PHYSICAL_SOURCE_SHA_POST="$(file_sha256 "$PHYSICAL_SOURCE")"
SOURCE_FILTER_INPUT_SHA_POST="$(file_sha256 "$SOURCE_FILTER_INPUT")"

SOURCE_CHECKPOINT_HASH_STATUS=FAIL
SAFE_COPY_MATCH_STATUS=FAIL
SAFE_CHECKPOINT_HASH_STATUS=FAIL
BOUNDARY_EVIDENCE_HASH_STATUS=FAIL
PHYSICAL_SOURCE_HASH_STATUS=FAIL
[[ "$SOURCE_CHECKPOINT_SHA_PRE" != MISSING && \
   "$SOURCE_CHECKPOINT_SHA_PRE" == "$SOURCE_CHECKPOINT_SHA_POST" ]] && SOURCE_CHECKPOINT_HASH_STATUS=PASS
[[ "$SAFE_COPY_RC" -eq 0 && "$SOURCE_CHECKPOINT_SHA_PRE" != MISSING && \
   "$SOURCE_CHECKPOINT_SHA_PRE" == "$SAFE_CHECKPOINT_SHA_PRE" ]] && SAFE_COPY_MATCH_STATUS=PASS
[[ "$SAFE_COPY_RC" -eq 0 && "$SAFE_CHECKPOINT_SHA_PRE" != MISSING && \
   "$SAFE_CHECKPOINT_SHA_PRE" == "$SAFE_CHECKPOINT_SHA_POST" ]] && SAFE_CHECKPOINT_HASH_STATUS=PASS
[[ "$BOUNDARY_GATE_SHA_PRE" == "$BOUNDARY_GATE_SHA_POST" && \
   "$BOUNDARY_MANIFEST_SHA_PRE" == "$BOUNDARY_MANIFEST_SHA_POST" && \
   "$SOURCE_FILTER_SHA_PRE" == "$SOURCE_FILTER_SHA_POST" ]] && BOUNDARY_EVIDENCE_HASH_STATUS=PASS
[[ "$PHYSICAL_SOURCE_SHA_PRE" == "$PHYSICAL_SOURCE_SHA_POST" && \
   "$SOURCE_FILTER_INPUT_SHA_PRE" == "$SOURCE_FILTER_INPUT_SHA_POST" && \
   "$PHYSICAL_SOURCE_SHA_POST" == "$PHYSICAL_SOURCE_EXPECTED_SHA" && \
   "$SOURCE_FILTER_INPUT_SHA_POST" == "$PHYSICAL_SOURCE_EXPECTED_SHA" ]] && PHYSICAL_SOURCE_HASH_STATUS=PASS

PROBE_REPORT="$REPORT_DIR/tie1_checkpoint_probe_status.rpt"
PROBE_STATUS="$(report_value "$PROBE_REPORT" PROBE_STATUS)"
RESTORE_STATUS="$(report_value "$PROBE_REPORT" RESTORE_STATUS)"
CORE_QUERY_STATUS="$(report_value "$PROBE_REPORT" CORE_QUERY_STATUS)"
CORE_QUERY_ERROR_COUNT="$(report_value "$PROBE_REPORT" CORE_QUERY_ERROR_COUNT)"
QUERY_ERROR_COUNT="$(report_value "$PROBE_REPORT" QUERY_ERROR_COUNT)"
FLAGGED_DETAIL_QUERY_ERROR_COUNT="$(report_value "$PROBE_REPORT" FLAGGED_DETAIL_QUERY_ERROR_COUNT)"
TIE1_NET_COUNT="$(report_value "$PROBE_REPORT" TIE1_NET_COUNT)"
TIE1_INST_TERM_COUNT="$(report_value "$PROBE_REPORT" TIE1_INST_TERM_COUNT)"
TIE1_REGULAR_WIRE_COUNT="$(report_value "$PROBE_REPORT" TIE1_REGULAR_WIRE_COUNT)"
TIE1_SPECIAL_WIRE_COUNT="$(report_value "$PROBE_REPORT" TIE1_SPECIAL_WIRE_COUNT)"
TIE1_VIA_COUNT="$(report_value "$PROBE_REPORT" TIE1_VIA_COUNT)"
TIE_AVAILABLE_MASTER_COUNT="$(report_value "$PROBE_REPORT" TIE_AVAILABLE_MASTER_COUNT)"
PHYSICAL_TIE_MASTER_COUNT="$(report_value "$PROBE_REPORT" PHYSICAL_TIE_MASTER_COUNT)"
PHYSICAL_TIE_INSTANCE_COUNT="$(report_value "$PROBE_REPORT" PHYSICAL_TIE_INSTANCE_COUNT)"
FLAGGED_TIE_HIGH_TERM_COUNT="$(report_value "$PROBE_REPORT" FLAGGED_TIE_HIGH_TERM_COUNT)"
FLAGGED_TIE_LOW_TERM_COUNT="$(report_value "$PROBE_REPORT" FLAGGED_TIE_LOW_TERM_COUNT)"
DESIGN_OBJECT_COUNT_STATUS="$(report_value "$PROBE_REPORT" DESIGN_OBJECT_COUNT_STATUS)"
DESIGN_MUTATION_COUNT="$(report_value "$PROBE_REPORT" DESIGN_MUTATION_COUNT)"

READ_ONLY_STATUS=FAIL
if [[ "$SOURCE_CHECKPOINT_HASH_STATUS" == PASS && \
      "$SAFE_COPY_MATCH_STATUS" == PASS && \
      "$SAFE_CHECKPOINT_HASH_STATUS" == PASS && \
      "$BOUNDARY_EVIDENCE_HASH_STATUS" == PASS && \
      "$PHYSICAL_SOURCE_HASH_STATUS" == PASS && \
      "$RESTORE_COMMAND_COUNT" == 1 && "$MUTATION_COMMAND_COUNT" == 0 && \
      "$DESIGN_OBJECT_COUNT_STATUS" == PASS && "$DESIGN_MUTATION_COUNT" == 0 ]]; then
  READ_ONLY_STATUS=PASS
fi

DECISION=FAIL_STOP
NEXT_STAGE=STOP_AND_REVIEW_PUBLISHED_EVIDENCE
if [[ "$INNOVUS_RC" -eq 0 && "$PROBE_STATUS" == PASS && \
      "$RESTORE_STATUS" == PASS && "$CORE_QUERY_STATUS" == PASS && \
      "$CORE_QUERY_ERROR_COUNT" == 0 && "$READ_ONLY_STATUS" == PASS ]]; then
  DECISION=PASS_REVIEW_TIE1_EVIDENCE
  NEXT_STAGE=REVIEW_TIE1_EVIDENCE_BEFORE_HASH_GUARDED_TRIAL
fi

{
  echo "STEP=TIE1_CHECKPOINT_PROBE"
  echo "BOUNDARY_PVS_RUN_ID=$BOUNDARY_PVS_RUN_ID"
  echo "SOURCE_PVS_RUN_ID=$SOURCE_PVS_RUN_ID"
  echo "SOURCE_CHECKPOINT=$SOURCE_CHECKPOINT"
  echo "SAFE_CHECKPOINT=$SAFE_CHECKPOINT"
  echo "SAFE_COPY_RC=$SAFE_COPY_RC"
  echo "CADENCE_ENV_RC=$CADENCE_ENV_RC"
  echo "CADENCE_ENV_STATUS=$CADENCE_ENV_STATUS"
  echo "INNOVUS_RC=$INNOVUS_RC"
  echo "PROBE_STATUS=$PROBE_STATUS"
  echo "RESTORE_STATUS=$RESTORE_STATUS"
  echo "CORE_QUERY_STATUS=$CORE_QUERY_STATUS"
  echo "CORE_QUERY_ERROR_COUNT=$CORE_QUERY_ERROR_COUNT"
  echo "QUERY_ERROR_COUNT=$QUERY_ERROR_COUNT"
  echo "FLAGGED_DETAIL_QUERY_ERROR_COUNT=$FLAGGED_DETAIL_QUERY_ERROR_COUNT"
  echo "TIE1_SOURCE_TOKEN_COUNT=$TIE1_SOURCE_TOKEN_COUNT"
  echo "TIE_MASTER_SOURCE_TOKEN_COUNT=$TIE_MASTER_SOURCE_TOKEN_COUNT"
  echo "TIE1_NET_COUNT=$TIE1_NET_COUNT"
  echo "TIE1_INST_TERM_COUNT=$TIE1_INST_TERM_COUNT"
  echo "TIE1_REGULAR_WIRE_COUNT=$TIE1_REGULAR_WIRE_COUNT"
  echo "TIE1_SPECIAL_WIRE_COUNT=$TIE1_SPECIAL_WIRE_COUNT"
  echo "TIE1_VIA_COUNT=$TIE1_VIA_COUNT"
  echo "TIE_AVAILABLE_MASTER_COUNT=$TIE_AVAILABLE_MASTER_COUNT"
  echo "PHYSICAL_TIE_MASTER_COUNT=$PHYSICAL_TIE_MASTER_COUNT"
  echo "PHYSICAL_TIE_INSTANCE_COUNT=$PHYSICAL_TIE_INSTANCE_COUNT"
  echo "FLAGGED_TIE_HIGH_TERM_COUNT=$FLAGGED_TIE_HIGH_TERM_COUNT"
  echo "FLAGGED_TIE_LOW_TERM_COUNT=$FLAGGED_TIE_LOW_TERM_COUNT"
  echo "SOURCE_CHECKPOINT_HASH_STATUS=$SOURCE_CHECKPOINT_HASH_STATUS"
  echo "SAFE_COPY_MATCH_STATUS=$SAFE_COPY_MATCH_STATUS"
  echo "SAFE_CHECKPOINT_HASH_STATUS=$SAFE_CHECKPOINT_HASH_STATUS"
  echo "BOUNDARY_EVIDENCE_HASH_STATUS=$BOUNDARY_EVIDENCE_HASH_STATUS"
  echo "PHYSICAL_SOURCE_HASH_STATUS=$PHYSICAL_SOURCE_HASH_STATUS"
  echo "RESTORE_COMMAND_COUNT=$RESTORE_COMMAND_COUNT"
  echo "MUTATION_COMMAND_COUNT=$MUTATION_COMMAND_COUNT"
  echo "DESIGN_OBJECT_COUNT_STATUS=$DESIGN_OBJECT_COUNT_STATUS"
  echo "DESIGN_MUTATION_COUNT=$DESIGN_MUTATION_COUNT"
  echo "READ_ONLY_STATUS=$READ_ONLY_STATUS"
  echo "SIGNOFF_ELIGIBLE=NO"
  echo "DECISION=$DECISION"
  echo "NEXT_STAGE=$NEXT_STAGE"
} | tee "$REPORT_DIR/operator_gate_tie1_checkpoint_probe.rpt"

publish_stage
PUBLISH_RC=$?
if [[ "$PUBLISH_RC" -ne 0 ]]; then
  DECISION=FAIL_STOP
  NEXT_STAGE=REPUBLISH_TIE1_CHECKPOINT_PROBE_EVIDENCE
fi

echo "TIE1_CHECKPOINT_PROBE_STATUS=$([[ "$DECISION" == PASS_REVIEW_TIE1_EVIDENCE ]] && echo PASS || echo FAIL)"
echo "PROBE_RUN_ID=$RUN_ID"
echo "BOUNDARY_PVS_RUN_ID=$BOUNDARY_PVS_RUN_ID"
echo "SOURCE_PVS_RUN_ID=$SOURCE_PVS_RUN_ID"
echo "INNOVUS_RC=$INNOVUS_RC"
echo "TIE1_NET_COUNT=$TIE1_NET_COUNT"
echo "TIE1_INST_TERM_COUNT=$TIE1_INST_TERM_COUNT"
echo "PHYSICAL_TIE_INSTANCE_COUNT=$PHYSICAL_TIE_INSTANCE_COUNT"
echo "READ_ONLY_STATUS=$READ_ONLY_STATUS"
echo "SIGNOFF_ELIGIBLE=NO"
echo "DECISION=$DECISION"
echo "PUBLISH_RC=$PUBLISH_RC"
echo "NEXT_EXPECTED_HEAD=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null)"
echo "NEXT_STAGE=$NEXT_STAGE"

if [[ "$DECISION" == PASS_REVIEW_TIE1_EVIDENCE && "$PUBLISH_RC" -eq 0 ]]; then
  exit 0
fi
exit 1
