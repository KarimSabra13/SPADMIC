#!/usr/bin/env bash
# Apply one backup-first, hash-bound RO_tune6 OA VDD pin/label repair.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
REPO_ROOT="${MPTDC_RO6_OA_REPAIR_REPO_ROOT:-$DEFAULT_REPO_ROOT}"
PUBLISHER="${MPTDC_RO6_OA_REPAIR_PUBLISHER:-$REPO_ROOT/MPTDC/ci/publish_mptdc_server_snapshot.sh}"
CONTRACT_CLASSIFIER="${MPTDC_RO6_OA_REPAIR_CONTRACT_CLASSIFIER:-$SCRIPT_DIR/11_classify_ro6_oa_vdd_pin_label_repair.py}"
READBACK_CLASSIFIER="${MPTDC_RO6_OA_REPAIR_READBACK_CLASSIFIER:-$SCRIPT_DIR/10_classify_ro6_oa_vdd_export_probe.py}"
REPAIR_SKILL="${MPTDC_RO6_OA_REPAIR_SKILL:-$SCRIPT_DIR/repair_ro6_oa_vdd_pin_label.il}"
PROBE_SKILL="${MPTDC_RO6_OA_REPAIR_PROBE_SKILL:-$SCRIPT_DIR/probe_ro6_oa_vdd_export_contract.il}"
INNOVUS_WORK="${MPTDC_INNOVUS_WORK:-/sim/ksabra/SPADMIC_work/innovus}"
WORK_ROOT="${MPTDC_WORK_ROOT:-$(dirname "$INNOVUS_WORK")}"

DEFAULT_PROJECT_DIR=/group/validmgr/PROJET/Prj_xh018/ksabra/cds_V0
DEFAULT_OA_ROOT=/group/validmgr/PROJET/Prj_xh018/ksabra/cds/design/RO_tune6
SOURCE_PROBE_RUN_ID=""
REPAIR_RUN_ID=""
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD:-}"
AUTHORIZATION=""
OA_LIBRARY="${MPTDC_RO6_OA_LIBRARY:-Prj_xh018_ksabra}"
OA_CELL="${MPTDC_RO6_OA_CELL:-RO_tune6}"
OA_VIEW="${MPTDC_RO6_OA_VIEW:-layout}"
OA_PROJECT_DIR="${MPTDC_RO6_OA_PROJECT_DIR:-$DEFAULT_PROJECT_DIR}"
OA_LAYOUT_DIR="${MPTDC_RO6_OA_LAYOUT_DIR:-$DEFAULT_OA_ROOT/layout}"
OA_SCHEMATIC_DIR="${MPTDC_RO6_OA_SCHEMATIC_DIR:-$DEFAULT_OA_ROOT/schematic}"
CADENCE_ENV="${MPTDC_CADENCE_ENV:-/eda/cadence/eda_2023-2024}"
CADENCE_ENV_RC=99
CADENCE_ENV_STATUS=NOT_RUN

usage() {
  cat <<'USAGE'
Usage:
  server_apply_mptdc_ro6_oa_vdd_pin_label_repair.sh \
    --source-probe-run-id <id> \
    --authorization EXACT_RO6_VDD_METTP_PIN_LABEL_REPAIR [options]

Options:
  --source-probe-run-id <id>  Exact published read-only OA probe.
  --run-id <id>                New repair evidence directory.
  --authorization <token>     Required exact mutation authorization.
  --expected-head <sha>        Require repository HEAD to match.
  --oa-library <name>          Default: Prj_xh018_ksabra.
  --oa-cell <name>             Default: RO_tune6.
  --oa-view <name>             Default: layout.
  --oa-project-dir <path>      XH018/1131 cds_V0 project directory.
  --oa-layout-dir <path>       Exact OA layout directory.
  --oa-schematic-dir <path>    Exact OA schematic directory.
  --innovus-work <path>        Result root.
  -h, --help                   Show this help.

This transaction copies and verifies the complete OA cell before opening the
layout for append. It attaches one existing METTP:pin rectangle to the existing
VDD terminal and adds one MET3:TEXT VDD label on coincident exported metal. It
creates no metal geometry.
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

oa_metadata_fingerprint() {
  local root="$1"
  find "$root" -type f -printf '%P\t%s\t%T@\n' 2>/dev/null \
    | LC_ALL=C sort \
    | sha256sum \
    | awk '{print $1}'
}

oa_content_fingerprint() {
  local root="$1"
  (
    cd "$root" || return 1
    find . -type f -print0 2>/dev/null \
      | LC_ALL=C sort -z \
      | while IFS= read -r -d '' file; do
          printf '%s\t' "$file"
          sha256sum "$file"
        done
  ) | sha256sum | awk '{print $1}'
}

load_cadence_env() {
  local env_file="$1"
  echo "CADENCE_ENV=$env_file"
  if [[ ! -r "$env_file" ]]; then
    CADENCE_ENV_RC=1
    CADENCE_ENV_STATUS=FAIL_NOT_READABLE
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
  if [[ "$CADENCE_ENV_RC" -eq 0 ]] && command -v virtuoso >/dev/null 2>&1; then
    CADENCE_ENV_STATUS=PASS
  elif [[ "$CADENCE_ENV_RC" -eq 0 ]]; then
    CADENCE_ENV_STATUS=FAIL_VIRTUOSO_MISSING
  else
    CADENCE_ENV_STATUS=FAIL
  fi
  echo "CADENCE_ENV_RC=$CADENCE_ENV_RC"
  echo "CADENCE_ENV_STATUS=$CADENCE_ENV_STATUS"
  [[ "$CADENCE_ENV_STATUS" == PASS ]]
}

check_manifest() {
  local root="$1"
  local manifest="$2"
  (
    cd "$root" || exit 1
    sha256sum -c "$manifest"
  )
}

publish_stage() {
  MPTDC_SNAPSHOT_MAX_TEXT_BYTES=8388608 \
    bash "$PUBLISHER" pvs "$REPAIR_RUN_ID" "$REPAIR_DIR" \
      RO6_OA_VDD_PIN_LABEL_REPAIR
  local rc=$?
  EXPECTED_HEAD_VALUE="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null)"
  return "$rc"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-probe-run-id) SOURCE_PROBE_RUN_ID="${2:?missing value}"; shift 2 ;;
    --run-id) REPAIR_RUN_ID="${2:?missing value}"; shift 2 ;;
    --authorization) AUTHORIZATION="${2:?missing value}"; shift 2 ;;
    --expected-head) EXPECTED_HEAD_VALUE="${2:?missing value}"; shift 2 ;;
    --oa-library) OA_LIBRARY="${2:?missing value}"; shift 2 ;;
    --oa-cell) OA_CELL="${2:?missing value}"; shift 2 ;;
    --oa-view) OA_VIEW="${2:?missing value}"; shift 2 ;;
    --oa-project-dir) OA_PROJECT_DIR="${2:?missing value}"; shift 2 ;;
    --oa-layout-dir) OA_LAYOUT_DIR="${2:?missing value}"; shift 2 ;;
    --oa-schematic-dir) OA_SCHEMATIC_DIR="${2:?missing value}"; shift 2 ;;
    --innovus-work) INNOVUS_WORK="${2:?missing value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$SOURCE_PROBE_RUN_ID" ]] || { echo "ERROR: --source-probe-run-id is required" >&2; exit 2; }
[[ "$SOURCE_PROBE_RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "ERROR: unsafe source probe id" >&2; exit 2; }
if [[ -z "$REPAIR_RUN_ID" ]]; then
  REPAIR_RUN_ID="$(date +%Y%m%d)_mptdc_ro6_oa_vdd_pin_label_repair_$(date +%H%M%S)"
fi
[[ "$REPAIR_RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "ERROR: unsafe repair run id" >&2; exit 2; }

WORK_ROOT="${MPTDC_WORK_ROOT:-$(dirname "$INNOVUS_WORK")}"

SOURCE_DIR="$INNOVUS_WORK/$SOURCE_PROBE_RUN_ID"
REPAIR_DIR="$INNOVUS_WORK/$REPAIR_RUN_ID"
BACKUP_ROOT="$WORK_ROOT/handoff/oa_backups/RO_tune6/${REPAIR_RUN_ID}_pre_repair"
OA_PROJECT_DIR="$(canonical_path "$OA_PROJECT_DIR")"
OA_LAYOUT_DIR="$(canonical_path "$OA_LAYOUT_DIR")"
OA_SCHEMATIC_DIR="$(canonical_path "$OA_SCHEMATIC_DIR")"
OA_CELL_ROOT="$(canonical_path "$(dirname "$OA_LAYOUT_DIR")")"
BACKUP_CELL_ROOT="$BACKUP_ROOT/oa/$(basename "$OA_CELL_ROOT")"

SOURCE_OPERATOR="$SOURCE_DIR/reports/operator_gate_ro6_oa_vdd_export_probe.rpt"
SOURCE_CLASSIFICATION="$SOURCE_DIR/reports/oa_ro6_vdd_export_classification.rpt"
SOURCE_CELL_SUMMARY="$SOURCE_DIR/reports/oa_ro6_cell_summary.rpt"
SOURCE_TERMINAL_FIGS="$SOURCE_DIR/reports/oa_ro6_terminal_pin_figs.tsv"
SOURCE_LABEL_SHAPES="$SOURCE_DIR/reports/oa_ro6_label_shapes.tsv"
SOURCE_SUPPLY_NETS="$SOURCE_DIR/reports/oa_ro6_supply_nets.tsv"
SOURCE_SUPPLY_SHAPES="$SOURCE_DIR/reports/oa_ro6_supply_top_shapes.tsv"
SOURCE_LAYER_MAP_EXCERPT="$SOURCE_DIR/reports/stream_layer_map_ro6_excerpt.rpt"
SOURCE_MANIFEST="$SOURCE_DIR/manifests/ro6_oa_vdd_export_probe_inputs.rpt"

cd "$REPO_ROOT" || exit 3
ACTUAL_HEAD="$(git rev-parse HEAD 2>/dev/null)"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
ORIGIN_HEAD="$(git rev-parse refs/remotes/origin/SPADMIC_test 2>/dev/null || true)"
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD_VALUE:-${ORIGIN_HEAD:-$ACTUAL_HEAD}}"
TRACKED_STATUS="$(git status --short --untracked-files=no 2>/dev/null)"

EXPECTED_LAYOUT_CONTENT="$(report_value "$SOURCE_MANIFEST" OA_LAYOUT_CONTENT_POST)"
EXPECTED_SCHEMATIC_CONTENT="$(report_value "$SOURCE_MANIFEST" OA_SCHEMATIC_CONTENT_POST)"
SOURCE_GDS="$(report_value "$SOURCE_MANIFEST" SOURCE_GDS)"
SOURCE_CDL="$(report_value "$SOURCE_MANIFEST" SOURCE_CDL)"
EXPECTED_GDS_SHA256="$(report_value "$SOURCE_MANIFEST" SOURCE_GDS_SHA256)"
EXPECTED_CDL_SHA256="$(report_value "$SOURCE_MANIFEST" SOURCE_CDL_SHA256)"
CURRENT_LAYOUT_CONTENT="$(oa_content_fingerprint "$OA_LAYOUT_DIR")"
CURRENT_SCHEMATIC_CONTENT="$(oa_content_fingerprint "$OA_SCHEMATIC_DIR")"
LOCK_COUNT="$(find "$OA_CELL_ROOT" -type f \( -name '*.cdslck' -o -name '*.lock' -o -name '.*lock*' \) 2>/dev/null | wc -l | tr -d ' ')"

echo "SOURCE_PROBE_RUN_ID=$SOURCE_PROBE_RUN_ID"
echo "REPAIR_RUN_ID=$REPAIR_RUN_ID"
echo "REPAIR_DIR=$REPAIR_DIR"
echo "BACKUP_ROOT=$BACKUP_ROOT"
echo "OA_TARGET=$OA_LIBRARY/$OA_CELL/$OA_VIEW"
echo "BRANCH=$BRANCH"
echo "ACTUAL_HEAD=$ACTUAL_HEAD"
echo "ORIGIN_HEAD=${ORIGIN_HEAD:-MISSING}"
echo "EXPECTED_HEAD=$EXPECTED_HEAD_VALUE"
echo "OA_LOCK_FILE_COUNT=$LOCK_COUNT"

PREFLIGHT=PASS
[[ "$AUTHORIZATION" == EXACT_RO6_VDD_METTP_PIN_LABEL_REPAIR ]] || {
  echo "STOP: exact OA mutation authorization token is required"; PREFLIGHT=FAIL;
}
[[ "$BRANCH" == SPADMIC_test ]] || { echo "STOP: branch must be SPADMIC_test"; PREFLIGHT=FAIL; }
[[ "$ACTUAL_HEAD" == "$EXPECTED_HEAD_VALUE" ]] || { echo "STOP: HEAD mismatch"; PREFLIGHT=FAIL; }
[[ -z "$TRACKED_STATUS" ]] || { echo "$TRACKED_STATUS"; echo "STOP: tracked tree is dirty"; PREFLIGHT=FAIL; }
[[ "$OA_LIBRARY" == Prj_xh018_ksabra && "$OA_CELL" == RO_tune6 && "$OA_VIEW" == layout ]] || {
  echo "STOP: OA target is not the reviewed RO_tune6 layout"; PREFLIGHT=FAIL;
}
for path in "$SOURCE_OPERATOR" "$SOURCE_CLASSIFICATION" "$SOURCE_CELL_SUMMARY" \
  "$SOURCE_TERMINAL_FIGS" "$SOURCE_LABEL_SHAPES" "$SOURCE_SUPPLY_NETS" \
  "$SOURCE_SUPPLY_SHAPES" "$SOURCE_LAYER_MAP_EXCERPT" "$SOURCE_MANIFEST" \
  "$CONTRACT_CLASSIFIER" \
  "$READBACK_CLASSIFIER" "$REPAIR_SKILL" "$PROBE_SKILL" "$PUBLISHER"; do
  [[ -s "$path" ]] || { echo "STOP: required file missing or empty: $path"; PREFLIGHT=FAIL; }
done
for path in "$OA_PROJECT_DIR" "$OA_LAYOUT_DIR" "$OA_SCHEMATIC_DIR"; do
  [[ -d "$path" && -r "$path" && -x "$path" ]] || {
    echo "STOP: required OA path missing or unreadable: $path"; PREFLIGHT=FAIL;
  }
done
[[ "$LOCK_COUNT" == 0 ]] || { echo "STOP: close Virtuoso/OA writers before repair"; PREFLIGHT=FAIL; }
[[ ! -e "$REPAIR_DIR" && ! -e "$BACKUP_ROOT" ]] || {
  echo "STOP: repair or backup destination already exists"; PREFLIGHT=FAIL;
}
[[ "$CURRENT_LAYOUT_CONTENT" == "$EXPECTED_LAYOUT_CONTENT" ]] || {
  echo "STOP: OA layout content drifted since the source probe"; PREFLIGHT=FAIL;
}
[[ "$CURRENT_SCHEMATIC_CONTENT" == "$EXPECTED_SCHEMATIC_CONTENT" ]] || {
  echo "STOP: OA schematic content drifted since the source probe"; PREFLIGHT=FAIL;
}
[[ -s "$SOURCE_GDS" && "$(sha256sum "$SOURCE_GDS" | awk '{print $1}')" == "$EXPECTED_GDS_SHA256" ]] || {
  echo "STOP: immutable source GDS hash mismatch"; PREFLIGHT=FAIL;
}
[[ -s "$SOURCE_CDL" && "$(sha256sum "$SOURCE_CDL" | awk '{print $1}')" == "$EXPECTED_CDL_SHA256" ]] || {
  echo "STOP: immutable source CDL hash mismatch"; PREFLIGHT=FAIL;
}
[[ "$(report_value "$SOURCE_OPERATOR" DECISION)" == PASS_REVIEW_EXPORT_CONTRACT ]] || {
  echo "STOP: source probe decision is not review-pass"; PREFLIGHT=FAIL;
}
[[ "$(report_value "$SOURCE_OPERATOR" NEXT_STAGE)" == REVIEW_VDD_SHAPE_FOR_ONE_HASH_GUARDED_PIN_LABEL_REPAIR ]] || {
  echo "STOP: source probe does not request this exact repair"; PREFLIGHT=FAIL;
}
grep -Eq 'MET3[[:space:]]+TEXT[[:space:]]+28[[:space:]]+3' \
  "$SOURCE_LAYER_MAP_EXCERPT" || {
  echo "STOP: source probe does not prove the MET3:TEXT stream mapping"; PREFLIGHT=FAIL;
}

echo "RO6_OA_VDD_PIN_LABEL_REPAIR_PREFLIGHT=$PREFLIGHT"
if [[ "$PREFLIGHT" != PASS ]]; then
  echo "DECISION=FAIL_STOP"
  exit 4
fi

mkdir -p "$REPAIR_DIR/reports" "$REPAIR_DIR/manifests" "$REPAIR_DIR/logs" \
  "$REPAIR_DIR/readback" "$BACKUP_ROOT/oa" "$BACKUP_ROOT/evidence" \
  "$BACKUP_ROOT/manifests"

REPAIR_CONTRACT="$REPAIR_DIR/reports/ro6_oa_vdd_pin_label_repair_contract.rpt"
set +e
python3 "$CONTRACT_CLASSIFIER" \
  --operator-gate "$SOURCE_OPERATOR" \
  --classification "$SOURCE_CLASSIFICATION" \
  --cell-summary "$SOURCE_CELL_SUMMARY" \
  --terminal-figs "$SOURCE_TERMINAL_FIGS" \
  --label-shapes "$SOURCE_LABEL_SHAPES" \
  --supply-nets "$SOURCE_SUPPLY_NETS" \
  --supply-shapes "$SOURCE_SUPPLY_SHAPES" \
  --out "$REPAIR_CONTRACT"
CONTRACT_RC=$?
set +e
CONTRACT_STATUS="$(report_value "$REPAIR_CONTRACT" REPAIR_CONTRACT_STATUS)"
if [[ "$CONTRACT_RC" -ne 0 || "$CONTRACT_STATUS" != PASS ]]; then
  echo "STOP: exact repair contract classification failed"
  echo "DECISION=FAIL_STOP"
  exit 5
fi

cp -a "$OA_CELL_ROOT" "$BACKUP_ROOT/oa/"
BACKUP_COPY_RC=$?
cp -p "$SOURCE_OPERATOR" "$SOURCE_CLASSIFICATION" "$SOURCE_CELL_SUMMARY" \
  "$SOURCE_TERMINAL_FIGS" "$SOURCE_LABEL_SHAPES" "$SOURCE_SUPPLY_NETS" \
  "$SOURCE_SUPPLY_SHAPES" "$SOURCE_LAYER_MAP_EXCERPT" "$SOURCE_MANIFEST" \
  "$REPAIR_CONTRACT" \
  "$BACKUP_ROOT/evidence/"
BACKUP_EVIDENCE_RC=$?
BACKUP_LAYOUT_CONTENT="$(oa_content_fingerprint "$BACKUP_CELL_ROOT/layout")"
BACKUP_SCHEMATIC_CONTENT="$(oa_content_fingerprint "$BACKUP_CELL_ROOT/schematic")"
BACKUP_STATUS=FAIL
if [[ "$BACKUP_COPY_RC" -eq 0 && "$BACKUP_EVIDENCE_RC" -eq 0 && \
      "$BACKUP_LAYOUT_CONTENT" == "$CURRENT_LAYOUT_CONTENT" && \
      "$BACKUP_SCHEMATIC_CONTENT" == "$CURRENT_SCHEMATIC_CONTENT" ]]; then
  BACKUP_STATUS=PASS
fi
{
  echo "STEP=RO6_OA_VDD_PIN_LABEL_REPAIR_BACKUP"
  echo "STATUS=$BACKUP_STATUS"
  echo "SOURCE_OA_CELL_ROOT=$OA_CELL_ROOT"
  echo "BACKUP_OA_CELL_ROOT=$BACKUP_CELL_ROOT"
  echo "SOURCE_LAYOUT_CONTENT_SHA256=$CURRENT_LAYOUT_CONTENT"
  echo "BACKUP_LAYOUT_CONTENT_SHA256=$BACKUP_LAYOUT_CONTENT"
  echo "SOURCE_SCHEMATIC_CONTENT_SHA256=$CURRENT_SCHEMATIC_CONTENT"
  echo "BACKUP_SCHEMATIC_CONTENT_SHA256=$BACKUP_SCHEMATIC_CONTENT"
  echo "OA_MUTATION_EXECUTED=NO"
} > "$BACKUP_ROOT/manifests/backup_status.rpt"
(
  cd "$BACKUP_ROOT" || exit 1
  find . -type f ! -name SHA256SUMS -print0 | LC_ALL=C sort -z \
    | xargs -0 -r sha256sum > manifests/SHA256SUMS
)
BACKUP_MANIFEST_CREATE_RC=$?
check_manifest "$BACKUP_ROOT" "$BACKUP_ROOT/manifests/SHA256SUMS" \
  > "$REPAIR_DIR/logs/backup_manifest_check.log" 2>&1
BACKUP_MANIFEST_CHECK_RC=$?
cp -p "$BACKUP_ROOT/manifests/backup_status.rpt" \
  "$REPAIR_DIR/manifests/immutable_oa_backup_status.rpt"
cp -p "$BACKUP_ROOT/manifests/SHA256SUMS" \
  "$REPAIR_DIR/manifests/immutable_oa_backup_SHA256SUMS"
if [[ "$BACKUP_STATUS" != PASS || "$BACKUP_MANIFEST_CREATE_RC" -ne 0 || \
      "$BACKUP_MANIFEST_CHECK_RC" -ne 0 ]]; then
  echo "STOP: immutable OA backup failed verification"
  echo "DECISION=FAIL_STOP"
  exit 6
fi

OA_LAYOUT_METADATA_PRE="$(oa_metadata_fingerprint "$OA_LAYOUT_DIR")"
OA_LAYOUT_CONTENT_PRE="$(oa_content_fingerprint "$OA_LAYOUT_DIR")"
OA_SCHEMATIC_CONTENT_PRE="$(oa_content_fingerprint "$OA_SCHEMATIC_DIR")"
SOURCE_GDS_SHA256_PRE="$(sha256sum "$SOURCE_GDS" | awk '{print $1}')"
SOURCE_CDL_SHA256_PRE="$(sha256sum "$SOURCE_CDL" | awk '{print $1}')"
PRE_MUTATION_LOCK_COUNT="$(find "$OA_CELL_ROOT" -type f \( -name '*.cdslck' -o -name '*.lock' -o -name '.*lock*' \) 2>/dev/null | wc -l | tr -d ' ')"
PRE_MUTATION_HASH_STATUS=FAIL
if [[ "$OA_LAYOUT_CONTENT_PRE" == "$EXPECTED_LAYOUT_CONTENT" && \
      "$OA_SCHEMATIC_CONTENT_PRE" == "$EXPECTED_SCHEMATIC_CONTENT" && \
      "$PRE_MUTATION_LOCK_COUNT" == 0 ]]; then
  PRE_MUTATION_HASH_STATUS=PASS
fi

VIRTUOSO_REPAIR_RC=99
OA_MUTATION_ATTEMPTED=NO
if [[ "$PRE_MUTATION_HASH_STATUS" == PASS ]] && load_cadence_env "$CADENCE_ENV"; then
  export MPTDC_RO6_OA_REPAIR_LIBRARY="$OA_LIBRARY"
  export MPTDC_RO6_OA_REPAIR_CELL="$OA_CELL"
  export MPTDC_RO6_OA_REPAIR_VIEW="$OA_VIEW"
  export MPTDC_RO6_OA_REPAIR_AUTHORIZATION=EXACT_RO6_VDD_METTP_PIN_LABEL_BACKUP_VERIFIED
  export MPTDC_RO6_OA_REPAIR_REPORT="$REPAIR_DIR/reports/oa_ro6_vdd_pin_label_repair_action.rpt"
  export MPTDC_RO6_OA_REPAIR_STATUS="$REPAIR_DIR/reports/oa_ro6_vdd_pin_label_repair_status.rpt"
  OA_MUTATION_ATTEMPTED=YES
  set +e
  (
    cd "$OA_PROJECT_DIR" || exit 3
    virtuoso -nograph -restore "$REPAIR_SKILL" \
      -log "$REPAIR_DIR/logs/virtuoso_ro6_oa_vdd_repair.log"
  ) 2>&1 | tee "$REPAIR_DIR/logs/virtuoso_ro6_oa_vdd_repair.console.log"
  VIRTUOSO_REPAIR_RC=${PIPESTATUS[0]}
  set +e
fi

OA_REPAIR_STATUS="$(report_value "$REPAIR_DIR/reports/oa_ro6_vdd_pin_label_repair_status.rpt" OA_REPAIR_STATUS)"
OA_REPAIR_ACTION_STATUS="$(report_value "$REPAIR_DIR/reports/oa_ro6_vdd_pin_label_repair_action.rpt" OA_REPAIR_STATUS)"
OA_REPAIR_ACTION_CONTRACT_STATUS=FAIL
if [[ "$OA_REPAIR_ACTION_STATUS" == PASS && \
      "$(report_value "$REPAIR_DIR/reports/oa_ro6_vdd_pin_label_repair_action.rpt" TARGET)" == Prj_xh018_ksabra/RO_tune6/layout && \
      "$(report_value "$REPAIR_DIR/reports/oa_ro6_vdd_pin_label_repair_action.rpt" TARGET_NET)" == VDD && \
      "$(report_value "$REPAIR_DIR/reports/oa_ro6_vdd_pin_label_repair_action.rpt" TARGET_LAYER)" == METTP && \
      "$(report_value "$REPAIR_DIR/reports/oa_ro6_vdd_pin_label_repair_action.rpt" TARGET_PURPOSE)" == pin && \
      "$(report_value "$REPAIR_DIR/reports/oa_ro6_vdd_pin_label_repair_action.rpt" TARGET_BOX)" == -68.700000,-31.950000,-66.670000,-30.115000 && \
      "$(report_value "$REPAIR_DIR/reports/oa_ro6_vdd_pin_label_repair_action.rpt" LABEL_LAYER)" == MET3 && \
      "$(report_value "$REPAIR_DIR/reports/oa_ro6_vdd_pin_label_repair_action.rpt" LABEL_PURPOSE)" == TEXT && \
      "$(report_value "$REPAIR_DIR/reports/oa_ro6_vdd_pin_label_repair_action.rpt" LABEL_TEXT)" == VDD && \
      "$(report_value "$REPAIR_DIR/reports/oa_ro6_vdd_pin_label_repair_action.rpt" PRE_VDD_PIN_COUNT)" == 0 && \
      "$(report_value "$REPAIR_DIR/reports/oa_ro6_vdd_pin_label_repair_action.rpt" POST_VDD_PIN_COUNT)" == 1 && \
      "$(report_value "$REPAIR_DIR/reports/oa_ro6_vdd_pin_label_repair_action.rpt" PRE_VDD_LABEL_COUNT)" == 0 && \
      "$(report_value "$REPAIR_DIR/reports/oa_ro6_vdd_pin_label_repair_action.rpt" POST_VDD_LABEL_COUNT)" == 1 && \
      "$(report_value "$REPAIR_DIR/reports/oa_ro6_vdd_pin_label_repair_action.rpt" CREATED_METAL_SHAPE_COUNT)" == 0 && \
      "$(report_value "$REPAIR_DIR/reports/oa_ro6_vdd_pin_label_repair_action.rpt" DELETED_OBJECT_COUNT)" == 0 && \
      "$(report_value "$REPAIR_DIR/reports/oa_ro6_vdd_pin_label_repair_action.rpt" MOVED_OBJECT_COUNT)" == 0 && \
      "$(report_value "$REPAIR_DIR/reports/oa_ro6_vdd_pin_label_repair_action.rpt" GLOBAL_ALIAS_EDIT_COUNT)" == 0 && \
      "$(report_value "$REPAIR_DIR/reports/oa_ro6_vdd_pin_label_repair_action.rpt" SCHEMATIC_EDIT_COUNT)" == 0 ]]; then
  OA_REPAIR_ACTION_CONTRACT_STATUS=PASS
fi
OA_LAYOUT_METADATA_AFTER_REPAIR="$(oa_metadata_fingerprint "$OA_LAYOUT_DIR")"
OA_LAYOUT_CONTENT_AFTER_REPAIR="$(oa_content_fingerprint "$OA_LAYOUT_DIR")"
OA_SCHEMATIC_CONTENT_AFTER_REPAIR="$(oa_content_fingerprint "$OA_SCHEMATIC_DIR")"

VIRTUOSO_READBACK_RC=99
if [[ "$VIRTUOSO_REPAIR_RC" -eq 0 && "$OA_REPAIR_STATUS" == PASS && \
      "$OA_REPAIR_ACTION_STATUS" == PASS ]]; then
  export MPTDC_RO6_OA_PROBE_ROOT="$REPAIR_DIR/readback"
  export MPTDC_RO6_OA_PROBE_LIBRARY="$OA_LIBRARY"
  export MPTDC_RO6_OA_PROBE_CELL="$OA_CELL"
  export MPTDC_RO6_OA_PROBE_VIEW="$OA_VIEW"
  set +e
  (
    cd "$OA_PROJECT_DIR" || exit 3
    virtuoso -nograph -restore "$PROBE_SKILL" \
      -log "$REPAIR_DIR/logs/virtuoso_ro6_oa_vdd_readback.log"
  ) 2>&1 | tee "$REPAIR_DIR/logs/virtuoso_ro6_oa_vdd_readback.console.log"
  VIRTUOSO_READBACK_RC=${PIPESTATUS[0]}
  set +e
fi

READBACK_PROBE_STATUS="$(report_value "$REPAIR_DIR/readback/oa_ro6_probe_status.rpt" OA_PROBE_STATUS)"
READBACK_CLASSIFIER_RC=99
if [[ "$VIRTUOSO_READBACK_RC" -eq 0 && "$READBACK_PROBE_STATUS" == PASS ]]; then
  set +e
  python3 "$READBACK_CLASSIFIER" \
    --cell-summary "$REPAIR_DIR/readback/oa_ro6_cell_summary.rpt" \
    --terminal-figs "$REPAIR_DIR/readback/oa_ro6_terminal_pin_figs.tsv" \
    --label-shapes "$REPAIR_DIR/readback/oa_ro6_label_shapes.tsv" \
    --supply-nets "$REPAIR_DIR/readback/oa_ro6_supply_nets.tsv" \
    --supply-shapes "$REPAIR_DIR/readback/oa_ro6_supply_top_shapes.tsv" \
    --candidate-shapes "$REPAIR_DIR/readback/oa_ro6_vdd_candidate_shapes.tsv" \
    --out "$REPAIR_DIR/reports/oa_ro6_vdd_pin_label_readback_classification.rpt"
  READBACK_CLASSIFIER_RC=$?
  set +e
fi

READBACK_CLASSIFICATION="$REPAIR_DIR/reports/oa_ro6_vdd_pin_label_readback_classification.rpt"
READBACK_STATUS="$(report_value "$READBACK_CLASSIFICATION" OA_PROBE_CLASSIFICATION_STATUS)"
READBACK_TERMINAL_CONTRACT="$(report_value "$READBACK_CLASSIFICATION" OA_TERMINAL_CONTRACT_STATUS)"
READBACK_DIAGNOSIS="$(report_value "$READBACK_CLASSIFICATION" OA_VDD_EXPORT_DIAGNOSIS)"
READBACK_TERMINAL_COUNT="$(report_value "$READBACK_CLASSIFICATION" OA_TERMINAL_NAME_COUNT)"
READBACK_TERMINAL_NAME_SET="$(report_value "$READBACK_CLASSIFICATION" OA_TERMINAL_NAME_SET)"
READBACK_UNEXPECTED_TERMINAL_SET="$(report_value "$READBACK_CLASSIFICATION" OA_UNEXPECTED_TERMINAL_SET)"
READBACK_ALIAS_STATUS="$(report_value "$READBACK_CLASSIFICATION" OA_EMPTY_GLOBAL_ALIAS_STATUS)"
READBACK_VDD_PIN_COUNT="$(report_value "$READBACK_CLASSIFICATION" OA_VDD_PIN_COUNT)"
READBACK_VDD_PIN_FIG_COUNT="$(report_value "$READBACK_CLASSIFICATION" OA_VDD_PIN_FIG_COUNT)"
READBACK_VDD_PIN_LPP_SET="$(report_value "$READBACK_CLASSIFICATION" OA_VDD_PIN_LPP_SET)"
READBACK_VDD_PIN_BOX_SET="$(report_value "$READBACK_CLASSIFICATION" OA_VDD_PIN_BOX_SET)"
READBACK_VDD_LABEL_COUNT="$(report_value "$READBACK_CLASSIFICATION" OA_VDD_EXPLICIT_LABEL_COUNT)"
READBACK_VDD_LABEL_LPP_SET="$(report_value "$READBACK_CLASSIFICATION" OA_VDD_LABEL_LPP_SET)"
READBACK_VSS_PIN_COUNT="$(report_value "$READBACK_CLASSIFICATION" OA_VSS_PIN_COUNT)"
READBACK_VSS_PIN_FIG_COUNT="$(report_value "$READBACK_CLASSIFICATION" OA_VSS_PIN_FIG_COUNT)"
OA_LAYOUT_CONTENT_POST="$(oa_content_fingerprint "$OA_LAYOUT_DIR")"
OA_SCHEMATIC_CONTENT_POST="$(oa_content_fingerprint "$OA_SCHEMATIC_DIR")"
SOURCE_GDS_SHA256_POST="$(sha256sum "$SOURCE_GDS" | awk '{print $1}')"
SOURCE_CDL_SHA256_POST="$(sha256sum "$SOURCE_CDL" | awk '{print $1}')"
check_manifest "$BACKUP_ROOT" "$BACKUP_ROOT/manifests/SHA256SUMS" \
  > "$REPAIR_DIR/logs/backup_manifest_postcheck.log" 2>&1
BACKUP_MANIFEST_POSTCHECK_RC=$?

OA_MUTATION_SCOPE_STATUS=FAIL
if [[ "$OA_LAYOUT_CONTENT_PRE" != "$OA_LAYOUT_CONTENT_AFTER_REPAIR" && \
      "$OA_LAYOUT_CONTENT_AFTER_REPAIR" == "$OA_LAYOUT_CONTENT_POST" && \
      "$OA_SCHEMATIC_CONTENT_PRE" == "$OA_SCHEMATIC_CONTENT_AFTER_REPAIR" && \
      "$OA_SCHEMATIC_CONTENT_AFTER_REPAIR" == "$OA_SCHEMATIC_CONTENT_POST" && \
      "$SOURCE_GDS_SHA256_PRE" == "$SOURCE_GDS_SHA256_POST" && \
      "$SOURCE_CDL_SHA256_PRE" == "$SOURCE_CDL_SHA256_POST" ]]; then
  OA_MUTATION_SCOPE_STATUS=PASS
fi

DECISION=FAIL_STOP
NEXT_STAGE=STOP_AND_REVIEW_OA_REPAIR_USE_IMMUTABLE_BACKUP
if [[ "$CONTRACT_STATUS" == PASS && "$BACKUP_STATUS" == PASS && \
      "$BACKUP_MANIFEST_POSTCHECK_RC" -eq 0 && \
      "$PRE_MUTATION_HASH_STATUS" == PASS && \
      "$CADENCE_ENV_STATUS" == PASS && "$VIRTUOSO_REPAIR_RC" -eq 0 && \
      "$OA_REPAIR_STATUS" == PASS && "$OA_REPAIR_ACTION_STATUS" == PASS && \
      "$OA_REPAIR_ACTION_CONTRACT_STATUS" == PASS && \
      "$VIRTUOSO_READBACK_RC" -eq 0 && "$READBACK_CLASSIFIER_RC" -eq 0 && \
      "$READBACK_STATUS" == PASS && "$READBACK_TERMINAL_CONTRACT" == PASS && \
      "$READBACK_TERMINAL_COUNT" == 21 && \
      "$READBACK_TERMINAL_NAME_SET" == 'S<0>,S<1>,S<2>,S<3>,S<4>,S<5>,S<6>,S<7>,VDD,VSS,code<0>,code<1>,code<2>,code<3>,code<4>,code<5>,code<6>,code<7>,gnd!,rstb,vdd!' && \
      "$READBACK_UNEXPECTED_TERMINAL_SET" == 'gnd!,vdd!' && \
      "$READBACK_ALIAS_STATUS" == PASS && \
      "$READBACK_VDD_PIN_COUNT" == 1 && "$READBACK_VDD_PIN_FIG_COUNT" == 1 && \
      "$READBACK_VDD_PIN_LPP_SET" == METTP:pin && \
      "$READBACK_VDD_PIN_BOX_SET" == '-68.700000,-31.950000,-66.670000,-30.115000' && \
      "$READBACK_VDD_LABEL_COUNT" == 1 && \
      "$READBACK_VDD_LABEL_LPP_SET" == MET3:TEXT && \
      "$READBACK_VSS_PIN_COUNT" == 2 && "$READBACK_VSS_PIN_FIG_COUNT" == 2 && \
      "$READBACK_DIAGNOSIS" == VDD_PIN_LABEL_CONTRACT_PRESENT && \
      "$OA_MUTATION_SCOPE_STATUS" == PASS ]]; then
  DECISION=PASS_CONTINUE
  NEXT_STAGE=EXPORT_FRESH_RO6_GDS_AND_RERUN_STANDALONE_LVS
fi

{
  echo "STEP=RO6_OA_VDD_PIN_LABEL_REPAIR"
  echo "SOURCE_PROBE_RUN_ID=$SOURCE_PROBE_RUN_ID"
  echo "REPAIR_CONTRACT_STATUS=$CONTRACT_STATUS"
  echo "BACKUP_ROOT=$BACKUP_ROOT"
  echo "BACKUP_STATUS=$BACKUP_STATUS"
  echo "BACKUP_MANIFEST_CHECK_RC=$BACKUP_MANIFEST_CHECK_RC"
  echo "BACKUP_MANIFEST_POSTCHECK_RC=$BACKUP_MANIFEST_POSTCHECK_RC"
  echo "PRE_MUTATION_LOCK_COUNT=$PRE_MUTATION_LOCK_COUNT"
  echo "PRE_MUTATION_HASH_STATUS=$PRE_MUTATION_HASH_STATUS"
  echo "CADENCE_ENV_RC=$CADENCE_ENV_RC"
  echo "CADENCE_ENV_STATUS=$CADENCE_ENV_STATUS"
  echo "OA_MUTATION_ATTEMPTED=$OA_MUTATION_ATTEMPTED"
  echo "VIRTUOSO_REPAIR_RC=$VIRTUOSO_REPAIR_RC"
  echo "OA_REPAIR_STATUS=$OA_REPAIR_STATUS"
  echo "OA_REPAIR_ACTION_STATUS=$OA_REPAIR_ACTION_STATUS"
  echo "OA_REPAIR_ACTION_CONTRACT_STATUS=$OA_REPAIR_ACTION_CONTRACT_STATUS"
  echo "VIRTUOSO_READBACK_RC=$VIRTUOSO_READBACK_RC"
  echo "READBACK_PROBE_STATUS=$READBACK_PROBE_STATUS"
  echo "READBACK_CLASSIFIER_RC=$READBACK_CLASSIFIER_RC"
  echo "READBACK_CLASSIFICATION_STATUS=$READBACK_STATUS"
  echo "READBACK_TERMINAL_CONTRACT_STATUS=$READBACK_TERMINAL_CONTRACT"
  echo "READBACK_TERMINAL_NAME_COUNT=$READBACK_TERMINAL_COUNT"
  echo "READBACK_TERMINAL_NAME_SET=$READBACK_TERMINAL_NAME_SET"
  echo "READBACK_UNEXPECTED_TERMINAL_SET=$READBACK_UNEXPECTED_TERMINAL_SET"
  echo "READBACK_EMPTY_GLOBAL_ALIAS_STATUS=$READBACK_ALIAS_STATUS"
  echo "READBACK_VDD_PIN_COUNT=$READBACK_VDD_PIN_COUNT"
  echo "READBACK_VDD_PIN_FIG_COUNT=$READBACK_VDD_PIN_FIG_COUNT"
  echo "READBACK_VDD_PIN_LPP_SET=$READBACK_VDD_PIN_LPP_SET"
  echo "READBACK_VDD_PIN_BOX_SET=$READBACK_VDD_PIN_BOX_SET"
  echo "READBACK_VDD_EXPLICIT_LABEL_COUNT=$READBACK_VDD_LABEL_COUNT"
  echo "READBACK_VDD_LABEL_LPP_SET=$READBACK_VDD_LABEL_LPP_SET"
  echo "READBACK_VSS_PIN_COUNT=$READBACK_VSS_PIN_COUNT"
  echo "READBACK_VSS_PIN_FIG_COUNT=$READBACK_VSS_PIN_FIG_COUNT"
  echo "READBACK_VDD_EXPORT_DIAGNOSIS=$READBACK_DIAGNOSIS"
  echo "OA_LAYOUT_CONTENT_PRE=$OA_LAYOUT_CONTENT_PRE"
  echo "OA_LAYOUT_CONTENT_POST=$OA_LAYOUT_CONTENT_POST"
  echo "OA_SCHEMATIC_CONTENT_PRE=$OA_SCHEMATIC_CONTENT_PRE"
  echo "OA_SCHEMATIC_CONTENT_POST=$OA_SCHEMATIC_CONTENT_POST"
  echo "SOURCE_GDS_SHA256_PRE=$SOURCE_GDS_SHA256_PRE"
  echo "SOURCE_GDS_SHA256_POST=$SOURCE_GDS_SHA256_POST"
  echo "SOURCE_CDL_SHA256_PRE=$SOURCE_CDL_SHA256_PRE"
  echo "SOURCE_CDL_SHA256_POST=$SOURCE_CDL_SHA256_POST"
  echo "OA_MUTATION_SCOPE_STATUS=$OA_MUTATION_SCOPE_STATUS"
  echo "FRESH_GDS_EXPORT_STATUS=NOT_RUN"
  echo "FRESH_STANDALONE_LVS_STATUS=NOT_RUN"
  echo "SIGNOFF_ELIGIBLE=NO"
  echo "DECISION=$DECISION"
  echo "NEXT_STAGE=$NEXT_STAGE"
} | tee "$REPAIR_DIR/reports/operator_gate_ro6_oa_vdd_pin_label_repair.rpt"

{
  echo "STEP=RO6_OA_VDD_PIN_LABEL_REPAIR_INPUTS"
  echo "SOURCE_PROBE_RUN_ID=$SOURCE_PROBE_RUN_ID"
  echo "SOURCE_PROBE_OPERATOR_SHA256=$(sha256sum "$SOURCE_OPERATOR" | awk '{print $1}')"
  echo "SOURCE_PROBE_CLASSIFICATION_SHA256=$(sha256sum "$SOURCE_CLASSIFICATION" | awk '{print $1}')"
  echo "OA_LIBRARY=$OA_LIBRARY"
  echo "OA_CELL=$OA_CELL"
  echo "OA_VIEW=$OA_VIEW"
  echo "OA_CELL_ROOT=$OA_CELL_ROOT"
  echo "BACKUP_ROOT=$BACKUP_ROOT"
  echo "AUTHORIZATION_TOKEN_SHA256=$(printf '%s' "$AUTHORIZATION" | sha256sum | awk '{print $1}')"
  echo "TARGET_BOX=-68.700000,-31.950000,-66.670000,-30.115000"
  echo "LABEL_ORIGIN=-67.685000,-31.032500"
  echo "METAL_GEOMETRY_CREATION_AUTHORIZED=NO"
  echo "SCHEMATIC_EDIT_AUTHORIZED=NO"
} > "$REPAIR_DIR/manifests/ro6_oa_vdd_pin_label_repair_inputs.rpt"

publish_stage
PUBLISH_RC=$?
if [[ "$PUBLISH_RC" -ne 0 ]]; then
  DECISION=FAIL_STOP
  NEXT_STAGE=REPUBLISH_RO6_OA_VDD_PIN_LABEL_REPAIR_EVIDENCE
fi

echo "RO6_OA_VDD_PIN_LABEL_REPAIR_STATUS=$([[ "$DECISION" == PASS_CONTINUE ]] && echo PASS || echo FAIL)"
echo "REPAIR_RUN_ID=$REPAIR_RUN_ID"
echo "BACKUP_ROOT=$BACKUP_ROOT"
echo "BACKUP_STATUS=$BACKUP_STATUS"
echo "PRE_MUTATION_HASH_STATUS=$PRE_MUTATION_HASH_STATUS"
echo "OA_REPAIR_STATUS=$OA_REPAIR_STATUS"
echo "OA_REPAIR_ACTION_CONTRACT_STATUS=$OA_REPAIR_ACTION_CONTRACT_STATUS"
echo "READBACK_TERMINAL_CONTRACT_STATUS=$READBACK_TERMINAL_CONTRACT"
echo "READBACK_VDD_EXPORT_DIAGNOSIS=$READBACK_DIAGNOSIS"
echo "OA_MUTATION_SCOPE_STATUS=$OA_MUTATION_SCOPE_STATUS"
echo "SIGNOFF_ELIGIBLE=NO"
echo "DECISION=$DECISION"
echo "PUBLISH_RC=$PUBLISH_RC"
echo "NEXT_EXPECTED_HEAD=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null)"
echo "NEXT_STAGE=$NEXT_STAGE"

if [[ "$DECISION" == PASS_CONTINUE && "$PUBLISH_RC" -eq 0 ]]; then
  exit 0
fi
exit 1
