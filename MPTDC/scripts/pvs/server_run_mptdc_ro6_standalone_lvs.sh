#!/usr/bin/env bash
# Prove a freshly exported RO_tune6 GDS/CDL pair with standalone PVS LVS.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
REPO_ROOT="${MPTDC_RO6_STANDALONE_REPO_ROOT:-$DEFAULT_REPO_ROOT}"
PUBLISHER="${MPTDC_RO6_STANDALONE_PUBLISHER:-$REPO_ROOT/MPTDC/ci/publish_mptdc_server_snapshot.sh}"
PREP_HELPER="${MPTDC_RO6_STANDALONE_PREP:-$SCRIPT_DIR/07_prepare_ro6_standalone_lvs.py}"
GATE_HELPER="${MPTDC_RO6_STANDALONE_GATE:-$SCRIPT_DIR/08_gate_ro6_standalone_lvs.py}"
INNOVUS_WORK="${MPTDC_INNOVUS_WORK:-/sim/ksabra/SPADMIC_work/innovus}"
DEFAULT_OA_ROOT="/group/validmgr/PROJET/Prj_xh018/ksabra/cds/design/RO_tune6"

SOURCE_PVS_RUN_ID=""
PVS_RUN_ID=""
RO_GDS=""
RO_CDL=""
OA_LAYOUT_DIR="${MPTDC_RO6_OA_LAYOUT_DIR:-$DEFAULT_OA_ROOT/layout}"
OA_SCHEMATIC_DIR="${MPTDC_RO6_OA_SCHEMATIC_DIR:-$DEFAULT_OA_ROOT/schematic}"
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD:-}"
MAX_EXPORT_AGE_SECONDS="${MPTDC_RO6_MAX_EXPORT_AGE_SECONDS:-86400}"

usage() {
  cat <<'USAGE'
Usage:
  server_run_mptdc_ro6_standalone_lvs.sh --source-pvs-run-id <id> \
    --ro-gds <fresh.gds> --ro-cdl <fresh.cdl> [options]

Options:
  --source-pvs-run-id <id>  Existing attributable PVS run used only as the
                            XH018 PVS control/technology template.
  --ro-gds <path>            Fresh run-local export of RO_tune6 layout.
  --ro-cdl <path>            Fresh run-local export of RO_tune6 schematic.
  --run-id <id>              New standalone result directory name.
  --oa-layout-dir <path>     Read-only OA layout view to fingerprint.
  --oa-schematic-dir <path>  Read-only OA schematic view to fingerprint.
  --max-export-age-seconds <n>
                            Reject older GDS/CDL exports. Default: 86400.
  --expected-head <sha>      Require repository HEAD to match this commit.
  --innovus-work <path>      Innovus/PVS result root.
  -h, --help                 Show this help.

The supplied GDS/CDL must be outside both OA view directories. This driver
copies them into an immutable run directory, never writes OA, requires one
explicit report-level MATCH, publishes evidence, and remains non-signoff.
USAGE
}

report_value() {
  local report="$1"
  local key="$2"
  local value
  value="$(sed -n "s/^${key}=//p" "$report" 2>/dev/null | tail -1)"
  if [[ -n "$value" ]]; then printf '%s\n' "$value"; else printf 'MISSING\n'; fi
}

canonical_path() {
  realpath -m "$1"
}

path_is_below() {
  local candidate root
  candidate="$(canonical_path "$1")"
  root="$(canonical_path "$2")"
  [[ "$candidate" == "$root" || "$candidate" == "$root/"* ]]
}

oa_fingerprint() {
  local root="$1"
  find "$root" -type f -printf '%P\t%s\t%T@\n' 2>/dev/null \
    | LC_ALL=C sort \
    | sha256sum \
    | awk '{print $1}'
}

artifact_age_seconds() {
  local modified now
  modified="$(stat -c %Y "$1" 2>/dev/null)" || return 1
  now="$(date +%s)"
  printf '%s\n' "$((now - modified))"
}

publish_stage() {
  MPTDC_SNAPSHOT_MAX_TEXT_BYTES=8388608 \
    bash "$PUBLISHER" pvs "$PVS_RUN_ID" "$PVS_DIR" PVS_RO6_STANDALONE_LVS
  local rc=$?
  EXPECTED_HEAD_VALUE="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null)"
  return "$rc"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-pvs-run-id) SOURCE_PVS_RUN_ID="${2:?missing --source-pvs-run-id value}"; shift 2 ;;
    --ro-gds) RO_GDS="${2:?missing --ro-gds value}"; shift 2 ;;
    --ro-cdl) RO_CDL="${2:?missing --ro-cdl value}"; shift 2 ;;
    --run-id) PVS_RUN_ID="${2:?missing --run-id value}"; shift 2 ;;
    --oa-layout-dir) OA_LAYOUT_DIR="${2:?missing --oa-layout-dir value}"; shift 2 ;;
    --oa-schematic-dir) OA_SCHEMATIC_DIR="${2:?missing --oa-schematic-dir value}"; shift 2 ;;
    --max-export-age-seconds) MAX_EXPORT_AGE_SECONDS="${2:?missing --max-export-age-seconds value}"; shift 2 ;;
    --expected-head) EXPECTED_HEAD_VALUE="${2:?missing --expected-head value}"; shift 2 ;;
    --innovus-work) INNOVUS_WORK="${2:?missing --innovus-work value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$SOURCE_PVS_RUN_ID" && -n "$RO_GDS" && -n "$RO_CDL" ]] || {
  echo "ERROR: --source-pvs-run-id, --ro-gds, and --ro-cdl are required" >&2
  usage >&2
  exit 2
}
[[ "$SOURCE_PVS_RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "ERROR: unsafe source PVS run id" >&2; exit 2; }
if [[ -z "$PVS_RUN_ID" ]]; then
  PVS_RUN_ID="$(date +%Y%m%d)_mptdc_ro6_standalone_lvs_$(date +%H%M%S)"
fi
[[ "$PVS_RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "ERROR: unsafe PVS run id" >&2; exit 2; }
[[ "$MAX_EXPORT_AGE_SECONDS" =~ ^[0-9]+$ && "$MAX_EXPORT_AGE_SECONDS" -gt 0 ]] || {
  echo "ERROR: --max-export-age-seconds must be a positive integer" >&2
  exit 2
}

SOURCE_PVS_DIR="$INNOVUS_WORK/$SOURCE_PVS_RUN_ID"
PVS_DIR="$INNOVUS_WORK/$PVS_RUN_ID"
RO_GDS="$(canonical_path "$RO_GDS")"
RO_CDL="$(canonical_path "$RO_CDL")"
OA_LAYOUT_DIR="$(canonical_path "$OA_LAYOUT_DIR")"
OA_SCHEMATIC_DIR="$(canonical_path "$OA_SCHEMATIC_DIR")"

cd "$REPO_ROOT" || exit 3
ACTUAL_HEAD="$(git rev-parse HEAD 2>/dev/null)"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
ORIGIN_HEAD="$(git rev-parse refs/remotes/origin/SPADMIC_test 2>/dev/null || true)"
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD_VALUE:-${ORIGIN_HEAD:-$ACTUAL_HEAD}}"
TRACKED_STATUS="$(git status --short --untracked-files=no 2>/dev/null)"

SOURCE_LVS_RUN=""
SOURCE_LVS_RUN_COUNT=0
if [[ -d "$SOURCE_PVS_DIR/pvs_lvs" ]]; then
  SOURCE_LVS_RUN_COUNT="$(find "$SOURCE_PVS_DIR/pvs_lvs" -mindepth 1 -maxdepth 1 -type d -exec test -f '{}/run.pvs' ';' -exec test -f '{}/pvslvsctl' ';' -print 2>/dev/null | wc -l | tr -d ' ')"
  if [[ "$SOURCE_LVS_RUN_COUNT" == 1 ]]; then
    SOURCE_LVS_RUN="$(find "$SOURCE_PVS_DIR/pvs_lvs" -mindepth 1 -maxdepth 1 -type d -exec test -f '{}/run.pvs' ';' -exec test -f '{}/pvslvsctl' ';' -print -quit 2>/dev/null)"
  fi
fi

GDS_AGE=MISSING
CDL_AGE=MISSING
[[ -s "$RO_GDS" ]] && GDS_AGE="$(artifact_age_seconds "$RO_GDS" || echo MISSING)"
[[ -s "$RO_CDL" ]] && CDL_AGE="$(artifact_age_seconds "$RO_CDL" || echo MISSING)"

echo "SOURCE_PVS_RUN_ID=$SOURCE_PVS_RUN_ID"
echo "SOURCE_LVS_RUN=$SOURCE_LVS_RUN"
echo "PVS_RUN_ID=$PVS_RUN_ID"
echo "PVS_DIR=$PVS_DIR"
echo "RO_GDS=$RO_GDS"
echo "RO_CDL=$RO_CDL"
echo "RO_GDS_AGE_SECONDS=$GDS_AGE"
echo "RO_CDL_AGE_SECONDS=$CDL_AGE"
echo "OA_LAYOUT_DIR=$OA_LAYOUT_DIR"
echo "OA_SCHEMATIC_DIR=$OA_SCHEMATIC_DIR"
echo "BRANCH=$BRANCH"
echo "ACTUAL_HEAD=$ACTUAL_HEAD"
echo "ORIGIN_HEAD=${ORIGIN_HEAD:-MISSING}"
echo "EXPECTED_HEAD=$EXPECTED_HEAD_VALUE"

PREFLIGHT=PASS
[[ "$BRANCH" == SPADMIC_test ]] || { echo "STOP: branch must be SPADMIC_test"; PREFLIGHT=FAIL; }
[[ "$ACTUAL_HEAD" == "$EXPECTED_HEAD_VALUE" ]] || { echo "STOP: HEAD mismatch"; PREFLIGHT=FAIL; }
[[ -z "$TRACKED_STATUS" ]] || { echo "$TRACKED_STATUS"; echo "STOP: tracked working tree is dirty"; PREFLIGHT=FAIL; }
[[ "$SOURCE_LVS_RUN_COUNT" == 1 ]] || { echo "STOP: expected one source LVS template, found $SOURCE_LVS_RUN_COUNT"; PREFLIGHT=FAIL; }
for path in "$RO_GDS" "$RO_CDL" "$PREP_HELPER" "$GATE_HELPER" "$PUBLISHER"; do
  [[ -s "$path" ]] || { echo "STOP: required file missing or empty: $path"; PREFLIGHT=FAIL; }
done
for path in "$OA_LAYOUT_DIR" "$OA_SCHEMATIC_DIR"; do
  [[ -d "$path" && -r "$path" && -x "$path" ]] || {
    echo "STOP: OA view directory missing or unreadable: $path"
    PREFLIGHT=FAIL
  }
done
if path_is_below "$RO_GDS" "$OA_LAYOUT_DIR" || path_is_below "$RO_GDS" "$OA_SCHEMATIC_DIR" || \
   path_is_below "$RO_CDL" "$OA_LAYOUT_DIR" || path_is_below "$RO_CDL" "$OA_SCHEMATIC_DIR"; then
  echo "STOP: exported artifacts must be outside the read-only OA views"
  PREFLIGHT=FAIL
fi
[[ "$GDS_AGE" =~ ^-?[0-9]+$ && "$GDS_AGE" -ge 0 && "$GDS_AGE" -le "$MAX_EXPORT_AGE_SECONDS" ]] || {
  echo "STOP: RO GDS is stale or has an invalid timestamp"; PREFLIGHT=FAIL;
}
[[ "$CDL_AGE" =~ ^-?[0-9]+$ && "$CDL_AGE" -ge 0 && "$CDL_AGE" -le "$MAX_EXPORT_AGE_SECONDS" ]] || {
  echo "STOP: RO CDL is stale or has an invalid timestamp"; PREFLIGHT=FAIL;
}
[[ ! -e "$PVS_DIR" ]] || { echo "STOP: result directory already exists: $PVS_DIR"; PREFLIGHT=FAIL; }

echo "PVS_RO6_STANDALONE_PREFLIGHT=$PREFLIGHT"
if [[ "$PREFLIGHT" != PASS ]]; then
  echo "DECISION=FAIL_STOP"
  exit 4
fi

OA_LAYOUT_HASH_PRE="$(oa_fingerprint "$OA_LAYOUT_DIR")"
OA_SCHEMATIC_HASH_PRE="$(oa_fingerprint "$OA_SCHEMATIC_DIR")"
mkdir -p "$PVS_DIR/inputs" "$PVS_DIR/manifests" "$PVS_DIR/reports" "$PVS_DIR/logs" "$PVS_DIR/pvs_lvs"
LOCAL_RO_GDS="$PVS_DIR/inputs/RO_tune6.fresh.gds"
LOCAL_RO_CDL="$PVS_DIR/inputs/RO_tune6.fresh.cdl"
cp -p "$RO_GDS" "$LOCAL_RO_GDS"
cp -p "$RO_CDL" "$LOCAL_RO_CDL"

GDS_SHA256="$(sha256sum "$LOCAL_RO_GDS" | awk '{print $1}')"
CDL_SHA256="$(sha256sum "$LOCAL_RO_CDL" | awk '{print $1}')"
ORIGINAL_GDS_SHA256="$(sha256sum "$RO_GDS" | awk '{print $1}')"
ORIGINAL_CDL_SHA256="$(sha256sum "$RO_CDL" | awk '{print $1}')"
COPY_STATUS=FAIL
if [[ "$GDS_SHA256" == "$ORIGINAL_GDS_SHA256" && "$CDL_SHA256" == "$ORIGINAL_CDL_SHA256" ]]; then
  COPY_STATUS=PASS
fi

STANDALONE_RUN="$PVS_DIR/pvs_lvs/RO_tune6_standalone_script"
set +e
python3 "$PREP_HELPER" \
  --template-run "$SOURCE_LVS_RUN" \
  --run-dir "$STANDALONE_RUN" \
  --ro-gds "$LOCAL_RO_GDS" \
  --ro-cdl "$LOCAL_RO_CDL" \
  2>&1 | tee "$PVS_DIR/logs/prepare_ro6_standalone_lvs.log"
PREP_RC=${PIPESTATUS[0]}
set +e

PVS_RC=99
if [[ "$PREP_RC" -eq 0 && "$COPY_STATUS" == PASS ]]; then
  if [[ -f /eda/cadence/eda_2023-2024 ]]; then
    # shellcheck disable=SC1091
    source /eda/cadence/eda_2023-2024 2>/dev/null || true
  fi
  set +e
  (
    cd "$STANDALONE_RUN" || exit 3
    bash ./run.pvs
  ) 2>&1 | tee "$PVS_DIR/logs/pvs_ro6_standalone_lvs.log"
  PVS_RC=${PIPESTATUS[0]}
  set +e
fi

OA_LAYOUT_HASH_POST="$(oa_fingerprint "$OA_LAYOUT_DIR")"
OA_SCHEMATIC_HASH_POST="$(oa_fingerprint "$OA_SCHEMATIC_DIR")"
OA_READ_ONLY_STATUS=FAIL
if [[ "$OA_LAYOUT_HASH_PRE" == "$OA_LAYOUT_HASH_POST" && \
      "$OA_SCHEMATIC_HASH_PRE" == "$OA_SCHEMATIC_HASH_POST" ]]; then
  OA_READ_ONLY_STATUS=PASS
fi

GATE_REPORT="$PVS_DIR/reports/pvs_ro6_standalone_lvs_status.rpt"
set +e
python3 "$GATE_HELPER" \
  --run-dir "$STANDALONE_RUN" \
  --pvs-rc "$PVS_RC" \
  --out "$GATE_REPORT"
GATE_RC=$?
set +e

PREP_STATUS="$(report_value "$PVS_DIR/logs/prepare_ro6_standalone_lvs.log" RO6_STANDALONE_PREP_STATUS)"
CDL_PIN_STATUS="$(report_value "$PVS_DIR/logs/prepare_ro6_standalone_lvs.log" RO6_CDL_PIN_CONTRACT_STATUS)"
LVS_STATUS="$(report_value "$GATE_REPORT" PVS_LVS_STATUS)"
CLS_RUN_RESULT="$(report_value "$GATE_REPORT" CLS_RUN_RESULT)"
BLACKBOXED_COUNT="$(report_value "$GATE_REPORT" BLACKBOXED_CELL_COUNT)"

DECISION=FAIL_STOP
NEXT_STAGE=STOP_AND_REVIEW_PUBLISHED_EVIDENCE
if [[ "$PREP_RC" -eq 0 && "$PREP_STATUS" == PASS && "$CDL_PIN_STATUS" == PASS && \
      "$COPY_STATUS" == PASS && "$OA_READ_ONLY_STATUS" == PASS && \
      "$GATE_RC" -eq 0 && "$LVS_STATUS" == MATCH && "$CLS_RUN_RESULT" == MATCH && \
      "$BLACKBOXED_COUNT" == 0 ]]; then
  DECISION=PASS_CONTINUE
  NEXT_STAGE=DIAGNOSTIC_PHYSICAL_PVS_WITH_FRESH_RO_GDS
fi

{
  echo "PVS_RUN_CLASS=DIAGNOSTIC_RO6_STANDALONE_LVS"
  echo "SOURCE_PVS_RUN_ID=$SOURCE_PVS_RUN_ID"
  echo "SOURCE_LVS_RUN=$SOURCE_LVS_RUN"
  echo "ORIGINAL_RO_GDS=$RO_GDS"
  echo "ORIGINAL_RO_CDL=$RO_CDL"
  echo "LOCAL_RO_GDS=$LOCAL_RO_GDS"
  echo "LOCAL_RO_CDL=$LOCAL_RO_CDL"
  echo "RO_GDS_SHA256=$GDS_SHA256"
  echo "RO_CDL_SHA256=$CDL_SHA256"
  echo "RO_GDS_AGE_SECONDS=$GDS_AGE"
  echo "RO_CDL_AGE_SECONDS=$CDL_AGE"
  echo "MAX_EXPORT_AGE_SECONDS=$MAX_EXPORT_AGE_SECONDS"
  echo "OA_LAYOUT_DIR=$OA_LAYOUT_DIR"
  echo "OA_SCHEMATIC_DIR=$OA_SCHEMATIC_DIR"
  echo "OA_LAYOUT_HASH_PRE=$OA_LAYOUT_HASH_PRE"
  echo "OA_LAYOUT_HASH_POST=$OA_LAYOUT_HASH_POST"
  echo "OA_SCHEMATIC_HASH_PRE=$OA_SCHEMATIC_HASH_PRE"
  echo "OA_SCHEMATIC_HASH_POST=$OA_SCHEMATIC_HASH_POST"
  echo "SIGNOFF_ELIGIBLE=NO"
} > "$PVS_DIR/manifests/ro6_standalone_lvs_inputs.rpt"

{
  echo "STEP=PVS_RO6_STANDALONE_LVS"
  echo "PVS_RUN_CLASS=DIAGNOSTIC_RO6_STANDALONE_LVS"
  echo "PREP_RC=$PREP_RC"
  echo "PREP_STATUS=$PREP_STATUS"
  echo "RO6_CDL_PIN_CONTRACT_STATUS=$CDL_PIN_STATUS"
  echo "INPUT_COPY_STATUS=$COPY_STATUS"
  echo "OA_READ_ONLY_STATUS=$OA_READ_ONLY_STATUS"
  echo "PVS_RC=$PVS_RC"
  echo "GATE_RC=$GATE_RC"
  echo "PVS_LVS=$LVS_STATUS"
  echo "CLS_RUN_RESULT=$CLS_RUN_RESULT"
  echo "BLACKBOXED_CELL_COUNT=$BLACKBOXED_COUNT"
  echo "SIGNOFF_ELIGIBLE=NO"
  echo "DECISION=$DECISION"
  echo "NEXT_STAGE=$NEXT_STAGE"
} | tee "$PVS_DIR/reports/operator_gate_pvs_ro6_standalone_lvs.rpt"

publish_stage
PUBLISH_RC=$?
if [[ "$PUBLISH_RC" -ne 0 ]]; then
  DECISION=FAIL_STOP
  NEXT_STAGE=REPUBLISH_RO6_STANDALONE_LVS_EVIDENCE
fi

echo "PVS_RO6_STANDALONE_RECOVERY_STATUS=$([[ "$DECISION" == PASS_CONTINUE ]] && echo PASS || echo FAIL)"
echo "PVS_RUN_ID=$PVS_RUN_ID"
echo "SOURCE_PVS_RUN_ID=$SOURCE_PVS_RUN_ID"
echo "PVS_LVS=$LVS_STATUS"
echo "OA_READ_ONLY_STATUS=$OA_READ_ONLY_STATUS"
echo "RO6_CDL_PIN_CONTRACT_STATUS=$CDL_PIN_STATUS"
echo "SIGNOFF_ELIGIBLE=NO"
echo "DECISION=$DECISION"
echo "PUBLISH_RC=$PUBLISH_RC"
echo "NEXT_EXPECTED_HEAD=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null)"
echo "NEXT_STAGE=$NEXT_STAGE"

if [[ "$DECISION" == PASS_CONTINUE && "$PUBLISH_RC" -eq 0 ]]; then
  exit 0
fi
exit 1
