#!/usr/bin/env bash
# Diagnose the exact standalone RO6 VDD pin-export mismatch without editing OA.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
REPO_ROOT="${MPTDC_RO6_OA_PROBE_REPO_ROOT:-$DEFAULT_REPO_ROOT}"
PUBLISHER="${MPTDC_RO6_OA_PROBE_PUBLISHER:-$REPO_ROOT/MPTDC/ci/publish_mptdc_server_snapshot.sh}"
MISMATCH_CLASSIFIER="${MPTDC_RO6_VDD_MISMATCH_CLASSIFIER:-$SCRIPT_DIR/09_classify_ro6_vdd_pin_mismatch.py}"
OA_CLASSIFIER="${MPTDC_RO6_OA_PROBE_CLASSIFIER:-$SCRIPT_DIR/10_classify_ro6_oa_vdd_export_probe.py}"
PROBE_SKILL="${MPTDC_RO6_OA_PROBE_SKILL:-$SCRIPT_DIR/probe_ro6_oa_vdd_export_contract.il}"
INNOVUS_WORK="${MPTDC_INNOVUS_WORK:-/sim/ksabra/SPADMIC_work/innovus}"

DEFAULT_PROJECT_DIR=/group/validmgr/PROJET/Prj_xh018/ksabra/cds_V0
DEFAULT_OA_ROOT=/group/validmgr/PROJET/Prj_xh018/ksabra/cds/design/RO_tune6
DEFAULT_MAP_ROOT="$DEFAULT_PROJECT_DIR/.xkit/setup/xh018/cadence/PDK/TECH_XH018_1131"

SOURCE_RUN_ID=""
PROBE_RUN_ID=""
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD:-}"
OA_LIBRARY="${MPTDC_RO6_OA_LIBRARY:-Prj_xh018_ksabra}"
OA_CELL="${MPTDC_RO6_OA_CELL:-RO_tune6}"
OA_VIEW="${MPTDC_RO6_OA_VIEW:-layout}"
OA_PROJECT_DIR="${MPTDC_RO6_OA_PROJECT_DIR:-$DEFAULT_PROJECT_DIR}"
OA_LAYOUT_DIR="${MPTDC_RO6_OA_LAYOUT_DIR:-$DEFAULT_OA_ROOT/layout}"
OA_SCHEMATIC_DIR="${MPTDC_RO6_OA_SCHEMATIC_DIR:-$DEFAULT_OA_ROOT/schematic}"
STREAM_LAYER_MAP="${MPTDC_RO6_STREAM_LAYER_MAP:-$DEFAULT_MAP_ROOT/strmInOut.layertable}"
STREAM_OBJECT_MAP="${MPTDC_RO6_STREAM_OBJECT_MAP:-$DEFAULT_MAP_ROOT/strmOutObjects.map}"
XSTREAM_LOG="${MPTDC_RO6_XSTREAM_LOG:-$DEFAULT_PROJECT_DIR/xstreamOut.log}"
CADENCE_ENV="${MPTDC_CADENCE_ENV:-/eda/cadence/eda_2023-2024}"
CADENCE_ENV_RC=99
CADENCE_ENV_STATUS=NOT_RUN

usage() {
  cat <<'USAGE'
Usage:
  server_probe_mptdc_ro6_oa_vdd_export_contract.sh \
    --source-standalone-run-id <id> [options]

Options:
  --source-standalone-run-id <id>  Exact published RO6 standalone mismatch.
  --run-id <id>                    New read-only probe result directory.
  --oa-library <name>              Default: Prj_xh018_ksabra.
  --oa-cell <name>                 Default: RO_tune6.
  --oa-view <name>                 Default: layout.
  --oa-project-dir <path>          XH018/1131 cds_V0 project directory.
  --oa-layout-dir <path>           OA layout view directory to fingerprint.
  --oa-schematic-dir <path>        OA schematic view directory to fingerprint.
  --stream-layer-map <path>        Exact XStream layer map used by export.
  --stream-object-map <path>       Exact XStream object map used by export.
  --xstream-log <path>             Exact XStream log for the source GDS.
  --expected-head <sha>            Require repository HEAD to match.
  --innovus-work <path>            PVS/probe result root.
  -h, --help                       Show this help.

This stage opens OA with mode "r", writes only to a new /sim result directory,
does not launch PVS, and publishes bounded text evidence. A passing probe is
diagnostic only and never authorizes an OA edit by itself.
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

capture_map_excerpt() {
  local source="$1"
  local destination="$2"
  local label="$3"
  local matches
  matches="$(grep -nEi 'MET1|MET2|MET3|METTP|pin|label|text|terminal' "$source" || true)"
  {
    echo "SOURCE=$source"
    echo "SOURCE_SHA256=$(sha256sum "$source" | awk '{print $1}')"
    echo "FILTER=$label"
    printf '%s\n' "$matches"
  } > "$destination"
  [[ -n "$matches" ]]
}

correlate_ignored_lpps() {
  local lpp_csv="$1"
  local prefix="$2"
  local report="$3"
  local count=0
  local lpp

  if [[ "$lpp_csv" != NONE && "$lpp_csv" != MISSING ]]; then
    while IFS= read -r lpp; do
      [[ -n "$lpp" ]] || continue
      if grep -Fq "layer-purpose pair '$lpp' are ignored" "$XSTREAM_LOG"; then
        echo "${prefix}_LPP=$lpp|IGNORED" >> "$report"
        count=$((count + 1))
      else
        echo "${prefix}_LPP=$lpp|NOT_REPORTED_IGNORED" >> "$report"
      fi
    done < <(printf '%s\n' "$lpp_csv" | tr ',' '\n')
  fi
  printf '%s\n' "$count"
}

publish_stage() {
  MPTDC_SNAPSHOT_MAX_TEXT_BYTES=8388608 \
    bash "$PUBLISHER" pvs "$PROBE_RUN_ID" "$PROBE_DIR" RO6_OA_VDD_EXPORT_PROBE
  local rc=$?
  EXPECTED_HEAD_VALUE="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null)"
  return "$rc"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-standalone-run-id) SOURCE_RUN_ID="${2:?missing value}"; shift 2 ;;
    --run-id) PROBE_RUN_ID="${2:?missing value}"; shift 2 ;;
    --oa-library) OA_LIBRARY="${2:?missing value}"; shift 2 ;;
    --oa-cell) OA_CELL="${2:?missing value}"; shift 2 ;;
    --oa-view) OA_VIEW="${2:?missing value}"; shift 2 ;;
    --oa-project-dir) OA_PROJECT_DIR="${2:?missing value}"; shift 2 ;;
    --oa-layout-dir) OA_LAYOUT_DIR="${2:?missing value}"; shift 2 ;;
    --oa-schematic-dir) OA_SCHEMATIC_DIR="${2:?missing value}"; shift 2 ;;
    --stream-layer-map) STREAM_LAYER_MAP="${2:?missing value}"; shift 2 ;;
    --stream-object-map) STREAM_OBJECT_MAP="${2:?missing value}"; shift 2 ;;
    --xstream-log) XSTREAM_LOG="${2:?missing value}"; shift 2 ;;
    --expected-head) EXPECTED_HEAD_VALUE="${2:?missing value}"; shift 2 ;;
    --innovus-work) INNOVUS_WORK="${2:?missing value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$SOURCE_RUN_ID" ]] || { echo "ERROR: --source-standalone-run-id is required" >&2; exit 2; }
[[ "$SOURCE_RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "ERROR: unsafe source run id" >&2; exit 2; }
if [[ -z "$PROBE_RUN_ID" ]]; then
  PROBE_RUN_ID="$(date +%Y%m%d)_mptdc_ro6_oa_vdd_export_probe_$(date +%H%M%S)"
fi
[[ "$PROBE_RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "ERROR: unsafe probe run id" >&2; exit 2; }

SOURCE_DIR="$INNOVUS_WORK/$SOURCE_RUN_ID"
PROBE_DIR="$INNOVUS_WORK/$PROBE_RUN_ID"
OA_PROJECT_DIR="$(canonical_path "$OA_PROJECT_DIR")"
OA_LAYOUT_DIR="$(canonical_path "$OA_LAYOUT_DIR")"
OA_SCHEMATIC_DIR="$(canonical_path "$OA_SCHEMATIC_DIR")"
STREAM_LAYER_MAP="$(canonical_path "$STREAM_LAYER_MAP")"
STREAM_OBJECT_MAP="$(canonical_path "$STREAM_OBJECT_MAP")"
XSTREAM_LOG="$(canonical_path "$XSTREAM_LOG")"

cd "$REPO_ROOT" || exit 3
ACTUAL_HEAD="$(git rev-parse HEAD 2>/dev/null)"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
ORIGIN_HEAD="$(git rev-parse refs/remotes/origin/SPADMIC_test 2>/dev/null || true)"
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD_VALUE:-${ORIGIN_HEAD:-$ACTUAL_HEAD}}"
TRACKED_STATUS="$(git status --short --untracked-files=no 2>/dev/null)"

SOURCE_OPERATOR="$SOURCE_DIR/reports/operator_gate_pvs_ro6_standalone_lvs.rpt"
SOURCE_MANIFEST="$SOURCE_DIR/manifests/ro6_standalone_lvs_inputs.rpt"
SOURCE_CLS_COUNT="$(find "$SOURCE_DIR/pvs_lvs" -type f -name '*.cls' 2>/dev/null | wc -l | tr -d ' ')"
SOURCE_CLS=""
if [[ "$SOURCE_CLS_COUNT" == 1 ]]; then
  SOURCE_CLS="$(find "$SOURCE_DIR/pvs_lvs" -type f -name '*.cls' -print -quit 2>/dev/null)"
fi

ORIGINAL_RO_GDS="$(report_value "$SOURCE_MANIFEST" ORIGINAL_RO_GDS)"
ORIGINAL_RO_CDL="$(report_value "$SOURCE_MANIFEST" ORIGINAL_RO_CDL)"
EXPECTED_GDS_SHA256="$(report_value "$SOURCE_MANIFEST" RO_GDS_SHA256)"
EXPECTED_CDL_SHA256="$(report_value "$SOURCE_MANIFEST" RO_CDL_SHA256)"
SOURCE_OA_LAYOUT_DIR="$(report_value "$SOURCE_MANIFEST" OA_LAYOUT_DIR)"
SOURCE_OA_SCHEMATIC_DIR="$(report_value "$SOURCE_MANIFEST" OA_SCHEMATIC_DIR)"

SOURCE_GDS_HASH_STATUS=FAIL
SOURCE_CDL_HASH_STATUS=FAIL
[[ -s "$ORIGINAL_RO_GDS" ]] && \
  [[ "$(sha256sum "$ORIGINAL_RO_GDS" | awk '{print $1}')" == "$EXPECTED_GDS_SHA256" ]] && \
  SOURCE_GDS_HASH_STATUS=PASS
[[ -s "$ORIGINAL_RO_CDL" ]] && \
  [[ "$(sha256sum "$ORIGINAL_RO_CDL" | awk '{print $1}')" == "$EXPECTED_CDL_SHA256" ]] && \
  SOURCE_CDL_HASH_STATUS=PASS

SOURCE_LINEAGE_STATUS=FAIL
if [[ "$SOURCE_OA_LAYOUT_DIR" == "$OA_LAYOUT_DIR" && \
      "$SOURCE_OA_SCHEMATIC_DIR" == "$OA_SCHEMATIC_DIR" ]]; then
  SOURCE_LINEAGE_STATUS=PASS
fi

XSTREAM_LOG_BINDING_STATUS=FAIL
XSTREAM_LOG_COMPLETION_STATUS=FAIL
XSTREAM_TRANSLATION_ZERO_ERROR_STATUS=FAIL
XSTREAM_WRAPPER_COMPLETION_STATUS=MISSING_OPTIONAL
if [[ -s "$XSTREAM_LOG" ]] && grep -Fq "$ORIGINAL_RO_GDS" "$XSTREAM_LOG"; then
  XSTREAM_LOG_BINDING_STATUS=PASS
fi
if [[ -s "$XSTREAM_LOG" ]] && \
   grep -Eq "XSTRM-234.*Translation completed\\..*['\"]?0['\"]?[[:space:]]+error\\(s\\)" \
     "$XSTREAM_LOG"; then
  XSTREAM_TRANSLATION_ZERO_ERROR_STATUS=PASS
  XSTREAM_LOG_COMPLETION_STATUS=PASS
fi
if [[ -s "$XSTREAM_LOG" ]] && grep -Fq 'strmout completed.' "$XSTREAM_LOG"; then
  XSTREAM_WRAPPER_COMPLETION_STATUS=PASS
fi

echo "SOURCE_STANDALONE_RUN_ID=$SOURCE_RUN_ID"
echo "SOURCE_CLS=$SOURCE_CLS"
echo "SOURCE_GDS=$ORIGINAL_RO_GDS"
echo "SOURCE_GDS_HASH_STATUS=$SOURCE_GDS_HASH_STATUS"
echo "SOURCE_CDL=$ORIGINAL_RO_CDL"
echo "SOURCE_CDL_HASH_STATUS=$SOURCE_CDL_HASH_STATUS"
echo "SOURCE_LINEAGE_STATUS=$SOURCE_LINEAGE_STATUS"
echo "PROBE_RUN_ID=$PROBE_RUN_ID"
echo "PROBE_DIR=$PROBE_DIR"
echo "OA_LIBRARY=$OA_LIBRARY"
echo "OA_CELL=$OA_CELL"
echo "OA_VIEW=$OA_VIEW"
echo "OA_PROJECT_DIR=$OA_PROJECT_DIR"
echo "STREAM_LAYER_MAP=$STREAM_LAYER_MAP"
echo "STREAM_OBJECT_MAP=$STREAM_OBJECT_MAP"
echo "XSTREAM_LOG=$XSTREAM_LOG"
echo "XSTREAM_LOG_BINDING_STATUS=$XSTREAM_LOG_BINDING_STATUS"
echo "XSTREAM_LOG_COMPLETION_STATUS=$XSTREAM_LOG_COMPLETION_STATUS"
echo "XSTREAM_TRANSLATION_ZERO_ERROR_STATUS=$XSTREAM_TRANSLATION_ZERO_ERROR_STATUS"
echo "XSTREAM_WRAPPER_COMPLETION_STATUS=$XSTREAM_WRAPPER_COMPLETION_STATUS"
echo "BRANCH=$BRANCH"
echo "ACTUAL_HEAD=$ACTUAL_HEAD"
echo "ORIGIN_HEAD=${ORIGIN_HEAD:-MISSING}"
echo "EXPECTED_HEAD=$EXPECTED_HEAD_VALUE"

PREFLIGHT=PASS
[[ "$BRANCH" == SPADMIC_test ]] || { echo "STOP: branch must be SPADMIC_test"; PREFLIGHT=FAIL; }
[[ "$ACTUAL_HEAD" == "$EXPECTED_HEAD_VALUE" ]] || { echo "STOP: HEAD mismatch"; PREFLIGHT=FAIL; }
[[ -z "$TRACKED_STATUS" ]] || { echo "$TRACKED_STATUS"; echo "STOP: tracked tree is dirty"; PREFLIGHT=FAIL; }
[[ "$SOURCE_CLS_COUNT" == 1 ]] || { echo "STOP: expected one source CLS, found $SOURCE_CLS_COUNT"; PREFLIGHT=FAIL; }
for path in "$SOURCE_OPERATOR" "$SOURCE_MANIFEST" "$SOURCE_CLS" \
  "$MISMATCH_CLASSIFIER" "$OA_CLASSIFIER" "$PROBE_SKILL" "$PUBLISHER" \
  "$STREAM_LAYER_MAP" "$STREAM_OBJECT_MAP" "$XSTREAM_LOG"; do
  [[ -s "$path" ]] || { echo "STOP: required file missing or empty: $path"; PREFLIGHT=FAIL; }
done
for path in "$OA_PROJECT_DIR" "$OA_LAYOUT_DIR" "$OA_SCHEMATIC_DIR"; do
  [[ -d "$path" && -r "$path" && -x "$path" ]] || {
    echo "STOP: required directory missing or unreadable: $path"; PREFLIGHT=FAIL;
  }
done
[[ -r "$CADENCE_ENV" ]] || { echo "STOP: Cadence environment is unreadable"; PREFLIGHT=FAIL; }
[[ "$SOURCE_GDS_HASH_STATUS" == PASS ]] || { echo "STOP: source GDS hash mismatch"; PREFLIGHT=FAIL; }
[[ "$SOURCE_CDL_HASH_STATUS" == PASS ]] || { echo "STOP: source CDL hash mismatch"; PREFLIGHT=FAIL; }
[[ "$SOURCE_LINEAGE_STATUS" == PASS ]] || { echo "STOP: OA lineage differs from source run"; PREFLIGHT=FAIL; }
[[ "$XSTREAM_LOG_BINDING_STATUS" == PASS ]] || { echo "STOP: XStream log is not bound to source GDS"; PREFLIGHT=FAIL; }
[[ "$XSTREAM_LOG_COMPLETION_STATUS" == PASS ]] || { echo "STOP: XStream log lacks zero-error completion"; PREFLIGHT=FAIL; }
[[ ! -e "$PROBE_DIR" ]] || { echo "STOP: probe directory already exists"; PREFLIGHT=FAIL; }
[[ "$(report_value "$SOURCE_OPERATOR" PVS_RC)" == 0 ]] || { echo "STOP: source PVS_RC is not zero"; PREFLIGHT=FAIL; }
[[ "$(report_value "$SOURCE_OPERATOR" PVS_LVS)" == NOT_PROVEN ]] || { echo "STOP: source is not the expected mismatch"; PREFLIGHT=FAIL; }
[[ "$(report_value "$SOURCE_OPERATOR" CLS_RUN_RESULT)" == MISMATCH ]] || { echo "STOP: source CLS result is not MISMATCH"; PREFLIGHT=FAIL; }
[[ "$(report_value "$SOURCE_OPERATOR" BLACKBOXED_CELL_COUNT)" == 0 ]] || { echo "STOP: source contains blackboxes"; PREFLIGHT=FAIL; }
[[ "$(report_value "$SOURCE_OPERATOR" OA_READ_ONLY_STATUS)" == PASS ]] || { echo "STOP: source OA read-only gate failed"; PREFLIGHT=FAIL; }
[[ "$(report_value "$SOURCE_OPERATOR" RO6_CDL_PIN_CONTRACT_STATUS)" == PASS ]] || { echo "STOP: source CDL pin contract failed"; PREFLIGHT=FAIL; }

echo "RO6_OA_VDD_EXPORT_PROBE_PREFLIGHT=$PREFLIGHT"
if [[ "$PREFLIGHT" != PASS ]]; then
  echo "DECISION=FAIL_STOP"
  exit 4
fi

SOURCE_GDS_SHA256_PRE="$(sha256sum "$ORIGINAL_RO_GDS" | awk '{print $1}')"
SOURCE_CDL_SHA256_PRE="$(sha256sum "$ORIGINAL_RO_CDL" | awk '{print $1}')"
STREAM_LAYER_MAP_SHA256_PRE="$(sha256sum "$STREAM_LAYER_MAP" | awk '{print $1}')"
STREAM_OBJECT_MAP_SHA256_PRE="$(sha256sum "$STREAM_OBJECT_MAP" | awk '{print $1}')"
XSTREAM_LOG_SHA256_PRE="$(sha256sum "$XSTREAM_LOG" | awk '{print $1}')"

mkdir -p "$PROBE_DIR/reports" "$PROBE_DIR/manifests" "$PROBE_DIR/logs"
MISMATCH_REPORT="$PROBE_DIR/reports/source_ro6_vdd_only_mismatch.rpt"
set +e
python3 "$MISMATCH_CLASSIFIER" --cls "$SOURCE_CLS" --out "$MISMATCH_REPORT"
MISMATCH_CLASSIFIER_RC=$?
set +e
MISMATCH_STATUS="$(report_value "$MISMATCH_REPORT" RO6_STANDALONE_MISMATCH_CLASSIFICATION)"

LAYER_MAP_CAPTURE_STATUS=FAIL
OBJECT_MAP_CAPTURE_STATUS=FAIL
capture_map_excerpt "$STREAM_LAYER_MAP" \
  "$PROBE_DIR/reports/stream_layer_map_ro6_excerpt.rpt" \
  XH018_1131_RO6_RELEVANT_LPPS && LAYER_MAP_CAPTURE_STATUS=PASS
capture_map_excerpt "$STREAM_OBJECT_MAP" \
  "$PROBE_DIR/reports/stream_object_map_ro6_excerpt.rpt" \
  XH018_1131_RO6_RELEVANT_OBJECTS && OBJECT_MAP_CAPTURE_STATUS=PASS

{
  echo "SOURCE=$XSTREAM_LOG"
  echo "SOURCE_SHA256=$(sha256sum "$XSTREAM_LOG" | awk '{print $1}')"
  echo "EXPECTED_GDS=$ORIGINAL_RO_GDS"
  echo "XSTREAM_LOG_BINDING_STATUS=$XSTREAM_LOG_BINDING_STATUS"
  echo "XSTREAM_LOG_COMPLETION_STATUS=$XSTREAM_LOG_COMPLETION_STATUS"
  echo "XSTREAM_TRANSLATION_ZERO_ERROR_STATUS=$XSTREAM_TRANSLATION_ZERO_ERROR_STATUS"
  echo "XSTREAM_WRAPPER_COMPLETION_STATUS=$XSTREAM_WRAPPER_COMPLETION_STATUS"
  grep -nE 'strmFile|topCell|Library:|Cell:|layerMap|objectMap|XSTRM-35|Translation completed|strmout completed' \
    "$XSTREAM_LOG" || true
} > "$PROBE_DIR/reports/xstream_ro6_export_excerpt.rpt"

OA_LAYOUT_METADATA_PRE="$(oa_metadata_fingerprint "$OA_LAYOUT_DIR")"
OA_LAYOUT_CONTENT_PRE="$(oa_content_fingerprint "$OA_LAYOUT_DIR")"
OA_SCHEMATIC_METADATA_PRE="$(oa_metadata_fingerprint "$OA_SCHEMATIC_DIR")"
OA_SCHEMATIC_CONTENT_PRE="$(oa_content_fingerprint "$OA_SCHEMATIC_DIR")"

VIRTUOSO_RC=99
if [[ "$MISMATCH_CLASSIFIER_RC" -eq 0 && "$MISMATCH_STATUS" == PASS ]] && \
   load_cadence_env "$CADENCE_ENV"; then
  export MPTDC_RO6_OA_PROBE_ROOT="$PROBE_DIR/reports"
  export MPTDC_RO6_OA_PROBE_LIBRARY="$OA_LIBRARY"
  export MPTDC_RO6_OA_PROBE_CELL="$OA_CELL"
  export MPTDC_RO6_OA_PROBE_VIEW="$OA_VIEW"
  set +e
  (
    cd "$OA_PROJECT_DIR" || exit 3
    virtuoso -nograph -restore "$PROBE_SKILL" \
      -log "$PROBE_DIR/logs/virtuoso_ro6_oa_vdd_probe.log"
  ) 2>&1 | tee "$PROBE_DIR/logs/virtuoso_ro6_oa_vdd_probe.console.log"
  VIRTUOSO_RC=${PIPESTATUS[0]}
  set +e
fi

OA_LAYOUT_METADATA_POST="$(oa_metadata_fingerprint "$OA_LAYOUT_DIR")"
OA_LAYOUT_CONTENT_POST="$(oa_content_fingerprint "$OA_LAYOUT_DIR")"
OA_SCHEMATIC_METADATA_POST="$(oa_metadata_fingerprint "$OA_SCHEMATIC_DIR")"
OA_SCHEMATIC_CONTENT_POST="$(oa_content_fingerprint "$OA_SCHEMATIC_DIR")"
OA_READ_ONLY_STATUS=FAIL
if [[ "$OA_LAYOUT_METADATA_PRE" == "$OA_LAYOUT_METADATA_POST" && \
      "$OA_LAYOUT_CONTENT_PRE" == "$OA_LAYOUT_CONTENT_POST" && \
      "$OA_SCHEMATIC_METADATA_PRE" == "$OA_SCHEMATIC_METADATA_POST" && \
      "$OA_SCHEMATIC_CONTENT_PRE" == "$OA_SCHEMATIC_CONTENT_POST" ]]; then
  OA_READ_ONLY_STATUS=PASS
fi

SOURCE_GDS_SHA256_POST="$(sha256sum "$ORIGINAL_RO_GDS" | awk '{print $1}')"
SOURCE_CDL_SHA256_POST="$(sha256sum "$ORIGINAL_RO_CDL" | awk '{print $1}')"
STREAM_LAYER_MAP_SHA256_POST="$(sha256sum "$STREAM_LAYER_MAP" | awk '{print $1}')"
STREAM_OBJECT_MAP_SHA256_POST="$(sha256sum "$STREAM_OBJECT_MAP" | awk '{print $1}')"
XSTREAM_LOG_SHA256_POST="$(sha256sum "$XSTREAM_LOG" | awk '{print $1}')"
SOURCE_EXPORT_READ_ONLY_STATUS=FAIL
STREAM_COLLATERAL_READ_ONLY_STATUS=FAIL
if [[ "$SOURCE_GDS_SHA256_PRE" == "$SOURCE_GDS_SHA256_POST" && \
      "$SOURCE_CDL_SHA256_PRE" == "$SOURCE_CDL_SHA256_POST" ]]; then
  SOURCE_EXPORT_READ_ONLY_STATUS=PASS
fi
if [[ "$STREAM_LAYER_MAP_SHA256_PRE" == "$STREAM_LAYER_MAP_SHA256_POST" && \
      "$STREAM_OBJECT_MAP_SHA256_PRE" == "$STREAM_OBJECT_MAP_SHA256_POST" && \
      "$XSTREAM_LOG_SHA256_PRE" == "$XSTREAM_LOG_SHA256_POST" ]]; then
  STREAM_COLLATERAL_READ_ONLY_STATUS=PASS
fi

OA_PROBE_STATUS="$(report_value "$PROBE_DIR/reports/oa_ro6_probe_status.rpt" OA_PROBE_STATUS)"
OA_CLASSIFICATION_REPORT="$PROBE_DIR/reports/oa_ro6_vdd_export_classification.rpt"
OA_CLASSIFIER_RC=99
if [[ "$VIRTUOSO_RC" -eq 0 && "$OA_PROBE_STATUS" == PASS ]]; then
  set +e
  python3 "$OA_CLASSIFIER" \
    --cell-summary "$PROBE_DIR/reports/oa_ro6_cell_summary.rpt" \
    --terminal-figs "$PROBE_DIR/reports/oa_ro6_terminal_pin_figs.tsv" \
    --label-shapes "$PROBE_DIR/reports/oa_ro6_label_shapes.tsv" \
    --supply-nets "$PROBE_DIR/reports/oa_ro6_supply_nets.tsv" \
    --supply-shapes "$PROBE_DIR/reports/oa_ro6_supply_top_shapes.tsv" \
    --candidate-shapes "$PROBE_DIR/reports/oa_ro6_vdd_candidate_shapes.tsv" \
    --out "$OA_CLASSIFICATION_REPORT"
  OA_CLASSIFIER_RC=$?
  set +e
fi

OA_CLASSIFICATION_STATUS="$(report_value "$OA_CLASSIFICATION_REPORT" OA_PROBE_CLASSIFICATION_STATUS)"
OA_VDD_DIAGNOSIS="$(report_value "$OA_CLASSIFICATION_REPORT" OA_VDD_EXPORT_DIAGNOSIS)"
OA_REVIEW_ACTION="$(report_value "$OA_CLASSIFICATION_REPORT" OA_VDD_EXPORT_REVIEW_ACTION)"
OA_TERMINAL_CONTRACT_STATUS="$(report_value "$OA_CLASSIFICATION_REPORT" OA_TERMINAL_CONTRACT_STATUS)"
OA_VDD_NET_SHAPE_COUNT="$(report_value "$OA_CLASSIFICATION_REPORT" OA_VDD_NET_ASSOCIATED_SHAPE_COUNT)"
OA_VDD_GOLDEN_OVERLAP_COUNT="$(report_value "$OA_CLASSIFICATION_REPORT" OA_GOLDEN_VDD_PIN_OVERLAP_VDD_SHAPE_COUNT)"
VDD_PIN_LPPS="$(report_value "$OA_CLASSIFICATION_REPORT" OA_VDD_PIN_LPP_SET)"
VDD_LABEL_LPPS="$(report_value "$OA_CLASSIFICATION_REPORT" OA_VDD_LABEL_LPP_SET)"

LPP_CORRELATION_REPORT="$PROBE_DIR/reports/xstream_vdd_lpp_correlation.rpt"
{
  echo "SOURCE_XSTREAM_LOG=$XSTREAM_LOG"
  echo "VDD_PIN_LPP_SET=$VDD_PIN_LPPS"
  echo "VDD_LABEL_LPP_SET=$VDD_LABEL_LPPS"
} > "$LPP_CORRELATION_REPORT"
VDD_PIN_IGNORED_LPP_COUNT="$(correlate_ignored_lpps "$VDD_PIN_LPPS" VDD_PIN "$LPP_CORRELATION_REPORT")"
VDD_LABEL_IGNORED_LPP_COUNT="$(correlate_ignored_lpps "$VDD_LABEL_LPPS" VDD_LABEL "$LPP_CORRELATION_REPORT")"
{
  echo "VDD_PIN_IGNORED_LPP_COUNT=$VDD_PIN_IGNORED_LPP_COUNT"
  echo "VDD_LABEL_IGNORED_LPP_COUNT=$VDD_LABEL_IGNORED_LPP_COUNT"
} >> "$LPP_CORRELATION_REPORT"

{
  echo "STEP=RO6_OA_VDD_EXPORT_PROBE"
  echo "SOURCE_STANDALONE_RUN_ID=$SOURCE_RUN_ID"
  echo "SOURCE_CLS=$SOURCE_CLS"
  echo "SOURCE_GDS=$ORIGINAL_RO_GDS"
  echo "SOURCE_GDS_SHA256=$EXPECTED_GDS_SHA256"
  echo "SOURCE_CDL=$ORIGINAL_RO_CDL"
  echo "SOURCE_CDL_SHA256=$EXPECTED_CDL_SHA256"
  echo "OA_LIBRARY=$OA_LIBRARY"
  echo "OA_CELL=$OA_CELL"
  echo "OA_VIEW=$OA_VIEW"
  echo "OA_PROJECT_DIR=$OA_PROJECT_DIR"
  echo "OA_LAYOUT_DIR=$OA_LAYOUT_DIR"
  echo "OA_SCHEMATIC_DIR=$OA_SCHEMATIC_DIR"
  echo "OA_LAYOUT_METADATA_PRE=$OA_LAYOUT_METADATA_PRE"
  echo "OA_LAYOUT_METADATA_POST=$OA_LAYOUT_METADATA_POST"
  echo "OA_LAYOUT_CONTENT_PRE=$OA_LAYOUT_CONTENT_PRE"
  echo "OA_LAYOUT_CONTENT_POST=$OA_LAYOUT_CONTENT_POST"
  echo "OA_SCHEMATIC_METADATA_PRE=$OA_SCHEMATIC_METADATA_PRE"
  echo "OA_SCHEMATIC_METADATA_POST=$OA_SCHEMATIC_METADATA_POST"
  echo "OA_SCHEMATIC_CONTENT_PRE=$OA_SCHEMATIC_CONTENT_PRE"
  echo "OA_SCHEMATIC_CONTENT_POST=$OA_SCHEMATIC_CONTENT_POST"
  echo "STREAM_LAYER_MAP=$STREAM_LAYER_MAP"
  echo "STREAM_LAYER_MAP_SHA256_PRE=$STREAM_LAYER_MAP_SHA256_PRE"
  echo "STREAM_LAYER_MAP_SHA256_POST=$STREAM_LAYER_MAP_SHA256_POST"
  echo "STREAM_OBJECT_MAP=$STREAM_OBJECT_MAP"
  echo "STREAM_OBJECT_MAP_SHA256_PRE=$STREAM_OBJECT_MAP_SHA256_PRE"
  echo "STREAM_OBJECT_MAP_SHA256_POST=$STREAM_OBJECT_MAP_SHA256_POST"
  echo "XSTREAM_LOG=$XSTREAM_LOG"
  echo "XSTREAM_LOG_SHA256_PRE=$XSTREAM_LOG_SHA256_PRE"
  echo "XSTREAM_LOG_SHA256_POST=$XSTREAM_LOG_SHA256_POST"
  echo "SOURCE_EXPORT_READ_ONLY_STATUS=$SOURCE_EXPORT_READ_ONLY_STATUS"
  echo "STREAM_COLLATERAL_READ_ONLY_STATUS=$STREAM_COLLATERAL_READ_ONLY_STATUS"
  echo "SIGNOFF_ELIGIBLE=NO"
} > "$PROBE_DIR/manifests/ro6_oa_vdd_export_probe_inputs.rpt"

DECISION=FAIL_STOP
NEXT_STAGE=STOP_AND_REVIEW_PUBLISHED_EVIDENCE
if [[ "$MISMATCH_CLASSIFIER_RC" -eq 0 && "$MISMATCH_STATUS" == PASS && \
      "$CADENCE_ENV_STATUS" == PASS && "$VIRTUOSO_RC" -eq 0 && \
      "$OA_PROBE_STATUS" == PASS && "$OA_CLASSIFIER_RC" -eq 0 && \
      "$OA_CLASSIFICATION_STATUS" == PASS && "$OA_READ_ONLY_STATUS" == PASS && \
      "$SOURCE_EXPORT_READ_ONLY_STATUS" == PASS && \
      "$STREAM_COLLATERAL_READ_ONLY_STATUS" == PASS && \
      "$SOURCE_GDS_HASH_STATUS" == PASS && "$SOURCE_CDL_HASH_STATUS" == PASS && \
      "$SOURCE_LINEAGE_STATUS" == PASS && \
      "$XSTREAM_LOG_BINDING_STATUS" == PASS && \
      "$XSTREAM_LOG_COMPLETION_STATUS" == PASS && \
      "$XSTREAM_TRANSLATION_ZERO_ERROR_STATUS" == PASS && \
      "$LAYER_MAP_CAPTURE_STATUS" == PASS && "$OBJECT_MAP_CAPTURE_STATUS" == PASS ]]; then
  DECISION=PASS_REVIEW_EXPORT_CONTRACT
  NEXT_STAGE="$OA_REVIEW_ACTION"
fi

{
  echo "STEP=RO6_OA_VDD_EXPORT_PROBE"
  echo "SOURCE_STANDALONE_RUN_ID=$SOURCE_RUN_ID"
  echo "SOURCE_MISMATCH_CLASSIFIER_RC=$MISMATCH_CLASSIFIER_RC"
  echo "SOURCE_MISMATCH_CLASSIFICATION=$MISMATCH_STATUS"
  echo "SOURCE_GDS_HASH_STATUS=$SOURCE_GDS_HASH_STATUS"
  echo "SOURCE_CDL_HASH_STATUS=$SOURCE_CDL_HASH_STATUS"
  echo "SOURCE_LINEAGE_STATUS=$SOURCE_LINEAGE_STATUS"
  echo "XSTREAM_LOG_BINDING_STATUS=$XSTREAM_LOG_BINDING_STATUS"
  echo "XSTREAM_LOG_COMPLETION_STATUS=$XSTREAM_LOG_COMPLETION_STATUS"
  echo "XSTREAM_TRANSLATION_ZERO_ERROR_STATUS=$XSTREAM_TRANSLATION_ZERO_ERROR_STATUS"
  echo "XSTREAM_WRAPPER_COMPLETION_STATUS=$XSTREAM_WRAPPER_COMPLETION_STATUS"
  echo "LAYER_MAP_CAPTURE_STATUS=$LAYER_MAP_CAPTURE_STATUS"
  echo "OBJECT_MAP_CAPTURE_STATUS=$OBJECT_MAP_CAPTURE_STATUS"
  echo "CADENCE_ENV_RC=$CADENCE_ENV_RC"
  echo "CADENCE_ENV_STATUS=$CADENCE_ENV_STATUS"
  echo "VIRTUOSO_RC=$VIRTUOSO_RC"
  echo "OA_PROBE_STATUS=$OA_PROBE_STATUS"
  echo "OA_CLASSIFIER_RC=$OA_CLASSIFIER_RC"
  echo "OA_PROBE_CLASSIFICATION_STATUS=$OA_CLASSIFICATION_STATUS"
  echo "OA_READ_ONLY_STATUS=$OA_READ_ONLY_STATUS"
  echo "SOURCE_EXPORT_READ_ONLY_STATUS=$SOURCE_EXPORT_READ_ONLY_STATUS"
  echo "STREAM_COLLATERAL_READ_ONLY_STATUS=$STREAM_COLLATERAL_READ_ONLY_STATUS"
  echo "OA_VDD_EXPORT_DIAGNOSIS=$OA_VDD_DIAGNOSIS"
  echo "OA_TERMINAL_CONTRACT_STATUS=$OA_TERMINAL_CONTRACT_STATUS"
  echo "OA_VDD_NET_ASSOCIATED_SHAPE_COUNT=$OA_VDD_NET_SHAPE_COUNT"
  echo "OA_GOLDEN_VDD_PIN_OVERLAP_VDD_SHAPE_COUNT=$OA_VDD_GOLDEN_OVERLAP_COUNT"
  echo "OA_VDD_PIN_IGNORED_LPP_COUNT=$VDD_PIN_IGNORED_LPP_COUNT"
  echo "OA_VDD_LABEL_IGNORED_LPP_COUNT=$VDD_LABEL_IGNORED_LPP_COUNT"
  echo "SIGNOFF_ELIGIBLE=NO"
  echo "DECISION=$DECISION"
  echo "NEXT_STAGE=$NEXT_STAGE"
} | tee "$PROBE_DIR/reports/operator_gate_ro6_oa_vdd_export_probe.rpt"

publish_stage
PUBLISH_RC=$?
if [[ "$PUBLISH_RC" -ne 0 ]]; then
  DECISION=FAIL_STOP
  NEXT_STAGE=REPUBLISH_RO6_OA_VDD_EXPORT_PROBE_EVIDENCE
fi

echo "RO6_OA_VDD_EXPORT_PROBE_STATUS=$([[ "$DECISION" == PASS_REVIEW_EXPORT_CONTRACT ]] && echo PASS || echo FAIL)"
echo "PROBE_RUN_ID=$PROBE_RUN_ID"
echo "SOURCE_STANDALONE_RUN_ID=$SOURCE_RUN_ID"
echo "SOURCE_MISMATCH_CLASSIFICATION=$MISMATCH_STATUS"
echo "OA_PROBE_CLASSIFICATION_STATUS=$OA_CLASSIFICATION_STATUS"
echo "OA_READ_ONLY_STATUS=$OA_READ_ONLY_STATUS"
echo "XSTREAM_TRANSLATION_ZERO_ERROR_STATUS=$XSTREAM_TRANSLATION_ZERO_ERROR_STATUS"
echo "XSTREAM_WRAPPER_COMPLETION_STATUS=$XSTREAM_WRAPPER_COMPLETION_STATUS"
echo "SOURCE_EXPORT_READ_ONLY_STATUS=$SOURCE_EXPORT_READ_ONLY_STATUS"
echo "STREAM_COLLATERAL_READ_ONLY_STATUS=$STREAM_COLLATERAL_READ_ONLY_STATUS"
echo "OA_VDD_EXPORT_DIAGNOSIS=$OA_VDD_DIAGNOSIS"
echo "OA_TERMINAL_CONTRACT_STATUS=$OA_TERMINAL_CONTRACT_STATUS"
echo "OA_VDD_NET_ASSOCIATED_SHAPE_COUNT=$OA_VDD_NET_SHAPE_COUNT"
echo "OA_GOLDEN_VDD_PIN_OVERLAP_VDD_SHAPE_COUNT=$OA_VDD_GOLDEN_OVERLAP_COUNT"
echo "OA_VDD_PIN_IGNORED_LPP_COUNT=$VDD_PIN_IGNORED_LPP_COUNT"
echo "OA_VDD_LABEL_IGNORED_LPP_COUNT=$VDD_LABEL_IGNORED_LPP_COUNT"
echo "SIGNOFF_ELIGIBLE=NO"
echo "DECISION=$DECISION"
echo "PUBLISH_RC=$PUBLISH_RC"
echo "NEXT_EXPECTED_HEAD=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null)"
echo "NEXT_STAGE=$NEXT_STAGE"

if [[ "$DECISION" == PASS_REVIEW_EXPORT_CONTRACT && "$PUBLISH_RC" -eq 0 ]]; then
  exit 0
fi
exit 1
