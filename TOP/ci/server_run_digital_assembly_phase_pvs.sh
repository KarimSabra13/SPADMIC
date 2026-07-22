#!/usr/bin/env bash

###############################################################################
# Execute exactly one attributable PVS action for one assembly phase.
#
# Usage:
#   bash TOP/ci/server_run_digital_assembly_phase_pvs.sh \
#     <expected-head> <phase> <base|density|lvs> <package> \
#     <accepted-pvs-preflight-root> [accepted-prior-pvs-root]
###############################################################################

set +e

REPO="${SPADMIC_REPO:-/home/validmgr/ksabra/2026_SPAD/SPADMIC}"
EXPECTED_HEAD="${1:-MISSING}"
PHASE="${2:-MISSING}"
MODE="${3:-MISSING}"
PACKAGE="${4:-MISSING}"
PREFLIGHT_ROOT="${5:-MISSING}"
PRIOR_ROOT="${6:-NONE}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUTPUT_ROOT="$WORK_ROOT/diagnostics/digital_assembly_pvs_${PHASE}_${MODE}_execution_${TIMESTAMP}"
GATE_REPORT="$OUTPUT_ROOT/digital_assembly_pvs_gate.rpt"

PVS_BIN="${SPADMIC_CADENCE_PVS_BIN:-/eda/cadence/2023-24/RHELx86/PVS_22.22.000/bin/pvs}"
DRC_TEMPLATE="${SPADMIC_ASSEMBLY_PVS_DRC_TEMPLATE:-/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/layoutverification/pvs_drc/spadmic_tx_packet_core}"
DRC_TEMPLATE_GDS="${SPADMIC_ASSEMBLY_PVS_DRC_TEMPLATE_GDS:-$DRC_TEMPLATE/spadmic_tx_packet_core.gds}"
DRC_TEMPLATE_TOP="${SPADMIC_ASSEMBLY_PVS_DRC_TEMPLATE_TOP:-spadmic_tx_packet_core}"
LVS_TEMPLATE="${SPADMIC_ASSEMBLY_PVS_LVS_TEMPLATE:-/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/PvsLVS/spadmic_tx_packet_core_HV}"

RUN_OK=1
CD_RC=NOT_RUN
CHECKOUT_RC=NOT_RUN
PULL_RC=NOT_RUN
ACTUAL_HEAD=UNKNOWN
TRACKED_DIFF_RC=NOT_RUN
STAGED_DIFF_RC=NOT_RUN
SCRIPT_GATE_RC=NOT_RUN
PACKAGE_MANIFEST_RC=NOT_RUN
PACKAGE_AUDIT_RC=NOT_RUN
PREFLIGHT_MANIFEST_RC=NOT_RUN
PREFLIGHT_STATUS_RC=NOT_RUN
PREFLIGHT_IDENTITY_RC=NOT_RUN
PRIOR_MANIFEST_RC=NOT_APPLICABLE
PRIOR_STATUS_RC=NOT_APPLICABLE
TEMPLATE_IDENTITY_RC=NOT_RUN
PVS_WRAPPER_RC=NOT_RUN
WRAPPER_CLASS_RC=NOT_RUN
PVS_EXECUTION_EVIDENCE_RC=NOT_RUN
RUN_MANIFEST_RC=NOT_RUN
EXTERNAL_REFERENCE_RC=NOT_RUN
RULE_ANALYSIS_RC=NOT_APPLICABLE
DENSITY_ANALYSIS_GATE_RC=NOT_APPLICABLE
RUN_CONTROL_AUDIT_RC=NOT_APPLICABLE
VALIDATOR_RC=NOT_RUN
PACKAGE_POSTCHECK_RC=NOT_RUN
PREFLIGHT_POSTCHECK_RC=NOT_RUN
PRIOR_POSTCHECK_RC=NOT_APPLICABLE
DIAGNOSTIC_MANIFEST_RC=NOT_RUN
RUN_DIR=UNKNOWN
ANALYSIS_ROOT=NOT_APPLICABLE
PRIOR_STATUS=NONE

case "$PHASE" in
  p00_tx) TOP_MODULE=spadmic_digital_assembly_v1_p00_tx ;;
  p01_position) TOP_MODULE=spadmic_digital_assembly_v1_p01_position ;;
  p02_event_control) TOP_MODULE=spadmic_digital_assembly_v1_p02_event_control ;;
  p03_matrix_interface) TOP_MODULE=spadmic_digital_assembly_v1_p03_matrix_interface ;;
  *)
    TOP_MODULE=UNKNOWN
    echo "STOP_HERE_DO_NOT_CONTINUE: unsupported assembly phase: $PHASE"
    RUN_OK=0
    ;;
esac

case "$MODE" in
  base|lvs) ;;
  density)
    if [ "$PHASE" != "p03_matrix_interface" ]; then
      echo "STOP_HERE_DO_NOT_CONTINUE: density is authorized only for p03_matrix_interface"
      RUN_OK=0
    fi
    ;;
  *)
    echo "STOP_HERE_DO_NOT_CONTINUE: mode must be base, density, or lvs"
    RUN_OK=0
    ;;
esac

check_manifest() {
  local root="$1"
  local manifest="$2"
  if [ ! -r "$manifest" ]; then
    return 1
  fi
  (
    cd "$root"
    local local_cd_rc=$?
    if [ "$local_cd_rc" = "0" ]; then
      sha256sum -c "$manifest"
    else
      false
    fi
  )
}

require_lines() {
  local file="$1"
  shift
  local rc=0
  local line
  for line in "$@"; do
    grep -Fxq -- "$line" "$file" 2>/dev/null
    if [ "$?" != "0" ]; then
      echo "STATUS_LINE_MISSING=$file|$line"
      rc=1
    fi
  done
  return "$rc"
}

kv_field() {
  local file="$1"
  local key="$2"
  sed -n "s/^${key}=//p" "$file" 2>/dev/null | head -n 1
}

verify_template_inventory() {
  local inventory="$1"
  local rc=0
  local kind path expected_bytes expected_sha actual_bytes actual_sha
  if [ ! -s "$inventory" ]; then
    return 1
  fi
  while IFS=$'\t' read -r kind path expected_bytes expected_sha; do
    if [ "$kind" = "kind" ]; then
      continue
    fi
    if [ ! -f "$path" ]; then
      echo "TEMPLATE_FILE_MISSING=$path"
      rc=1
      continue
    fi
    actual_bytes="$(wc -c < "$path")"
    actual_sha="$(sha256sum "$path" | awk '{print $1}')"
    echo "TEMPLATE_FILE=$kind|$path|$actual_bytes|$actual_sha"
    if [ "$actual_bytes" != "$expected_bytes" ] || [ "$actual_sha" != "$expected_sha" ]; then
      echo "TEMPLATE_IDENTITY_MISMATCH=$path"
      rc=1
    fi
  done < "$inventory"
  return "$rc"
}

if [ "$EXPECTED_HEAD" = "MISSING" ] || \
   [ "$PACKAGE" = "MISSING" ] || \
   [ "$PREFLIGHT_ROOT" = "MISSING" ]; then
  echo "STOP_HERE_DO_NOT_CONTINUE: expected HEAD, phase, mode, package, and preflight root are required"
  RUN_OK=0
fi
if [ "$MODE" != "base" ] && [ "$PRIOR_ROOT" = "NONE" ]; then
  echo "STOP_HERE_DO_NOT_CONTINUE: density and LVS require an accepted prior PVS root"
  RUN_OK=0
fi

if [ -d "$REPO/.git" ]; then
  cd "$REPO"
  CD_RC=$?
else
  echo "STOP_HERE_DO_NOT_CONTINUE: repository missing: $REPO"
  CD_RC=1
  RUN_OK=0
fi

if [ "$RUN_OK" = "1" ]; then
  git checkout SPADMIC_test
  CHECKOUT_RC=$?
  if [ "$CHECKOUT_RC" = "0" ]; then
    git pull --ff-only origin SPADMIC_test
    PULL_RC=$?
  fi
  ACTUAL_HEAD="$(git rev-parse HEAD 2>/dev/null)"
  git diff --quiet
  TRACKED_DIFF_RC=$?
  git diff --cached --quiet
  STAGED_DIFF_RC=$?
  SCRIPT_GATE_RC=0
  for file in \
    TOP/pnr/scripts/run_pvs_drc_handoff.sh \
    TOP/pnr/scripts/run_pvs_lvs_handoff.sh \
    TOP/pnr/scripts/validate_digital_assembly_pvs_phase.py \
    TOP/pnr/scripts/analyze_pvs_drc_run.py \
    TOP/pnr/scripts/audit_pvs_lvs_run_control.py
  do
    if [ ! -s "$file" ]; then
      echo "MISSING_OR_EMPTY=$file"
      SCRIPT_GATE_RC=1
    fi
  done
  echo "CHECKOUT_RC=$CHECKOUT_RC"
  echo "PULL_RC=$PULL_RC"
  echo "EXPECTED_HEAD=$EXPECTED_HEAD"
  echo "ACTUAL_HEAD=$ACTUAL_HEAD"
  echo "TRACKED_DIFF_RC=$TRACKED_DIFF_RC"
  echo "STAGED_DIFF_RC=$STAGED_DIFF_RC"
  echo "SCRIPT_GATE_RC=$SCRIPT_GATE_RC"
  git status --short --branch --untracked-files=no
  if [ "$CHECKOUT_RC" != "0" ] || \
     [ "$PULL_RC" != "0" ] || \
     [ "$ACTUAL_HEAD" != "$EXPECTED_HEAD" ] || \
     [ "$TRACKED_DIFF_RC" != "0" ] || \
     [ "$STAGED_DIFF_RC" != "0" ] || \
     [ "$SCRIPT_GATE_RC" != "0" ]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: checkout is not attributable"
    RUN_OK=0
  fi
fi

if [ "$RUN_OK" = "1" ]; then
  if [ -d "$PACKAGE" ] && [ -d "$PREFLIGHT_ROOT" ]; then
    PACKAGE="$(cd "$PACKAGE" && pwd -P)"
    PREFLIGHT_ROOT="$(cd "$PREFLIGHT_ROOT" && pwd -P)"
  else
    echo "STOP_HERE_DO_NOT_CONTINUE: package or preflight root missing"
    RUN_OK=0
  fi
  if [ "$MODE" != "base" ]; then
    if [ -d "$PRIOR_ROOT" ]; then
      PRIOR_ROOT="$(cd "$PRIOR_ROOT" && pwd -P)"
    else
      echo "STOP_HERE_DO_NOT_CONTINUE: prior PVS root missing: $PRIOR_ROOT"
      RUN_OK=0
    fi
  fi
fi

if [ "$RUN_OK" = "1" ]; then
  mkdir -p "$OUTPUT_ROOT/logs" "$OUTPUT_ROOT/run_evidence" "$OUTPUT_ROOT/source_preflight"
  if [ "$MODE" != "base" ]; then
    mkdir -p "$OUTPUT_ROOT/source_prior"
  fi
  if [ "$?" != "0" ]; then
    RUN_OK=0
  fi
fi

PREFLIGHT_STATUS="$PREFLIGHT_ROOT/digital_assembly_pvs_preflight_status.rpt"
GDS="$PACKAGE/gds/$TOP_MODULE.gds"
SOURCE="$PACKAGE/netlist/$TOP_MODULE.lvs.pg.v"
CDL="$PACKAGE/pdk/xh018_D_CELLS_JIHD.cdl"
if [ "$RUN_OK" = "1" ]; then
  check_manifest "$PACKAGE" "$PACKAGE/manifests/SHA256SUMS" \
    > "$OUTPUT_ROOT/logs/package_manifest.log" 2>&1
  PACKAGE_MANIFEST_RC=$?
  python3 TOP/pnr/scripts/audit_innovus_handoff.py "$PACKAGE" \
    > "$OUTPUT_ROOT/logs/package_audit.log" 2>&1
  PACKAGE_AUDIT_RC=$?
  check_manifest "$PREFLIGHT_ROOT" "$PREFLIGHT_ROOT/SHA256SUMS" \
    > "$OUTPUT_ROOT/logs/preflight_manifest.log" 2>&1
  PREFLIGHT_MANIFEST_RC=$?
  GDS_SHA="$(sha256sum "$GDS" 2>/dev/null | awk '{print $1}')"
  require_lines "$PREFLIGHT_STATUS" \
    'STATUS=PASS' \
    "EXPECTED_HEAD=$EXPECTED_HEAD" \
    "ACTUAL_HEAD=$EXPECTED_HEAD" \
    "PHASE=$PHASE" \
    "TOP_MODULE=$TOP_MODULE" \
    "SOURCE_TOP=$TOP_MODULE" \
    "LAYOUT_TOP=$TOP_MODULE" \
    "PACKAGE=$PACKAGE" \
    "GDS_SHA256=$GDS_SHA" \
    'PVS_EXECUTED=NO'
  PREFLIGHT_STATUS_RC=$?
  PREFLIGHT_PACKAGE_SHA="$(kv_field "$PREFLIGHT_STATUS" PACKAGE_MANIFEST_SHA256)"
  CURRENT_PACKAGE_SHA="$(sha256sum "$PACKAGE/manifests/package.json" 2>/dev/null | awk '{print $1}')"
  if [ -n "$PREFLIGHT_PACKAGE_SHA" ] && [ "$PREFLIGHT_PACKAGE_SHA" = "$CURRENT_PACKAGE_SHA" ]; then
    PREFLIGHT_IDENTITY_RC=0
  else
    PREFLIGHT_IDENTITY_RC=1
  fi
  verify_template_inventory "$PREFLIGHT_ROOT/template_files.pre.tsv" \
    > "$OUTPUT_ROOT/logs/template_identity.log" 2>&1
  TEMPLATE_IDENTITY_RC=$?
  echo "PACKAGE_MANIFEST_RC=$PACKAGE_MANIFEST_RC"
  echo "PACKAGE_AUDIT_RC=$PACKAGE_AUDIT_RC"
  echo "PREFLIGHT_MANIFEST_RC=$PREFLIGHT_MANIFEST_RC"
  echo "PREFLIGHT_STATUS_RC=$PREFLIGHT_STATUS_RC"
  echo "PREFLIGHT_IDENTITY_RC=$PREFLIGHT_IDENTITY_RC"
  echo "TEMPLATE_IDENTITY_RC=$TEMPLATE_IDENTITY_RC"
  if [ "$PACKAGE_MANIFEST_RC" != "0" ] || \
     [ "$PACKAGE_AUDIT_RC" != "0" ] || \
     [ "$PREFLIGHT_MANIFEST_RC" != "0" ] || \
     [ "$PREFLIGHT_STATUS_RC" != "0" ] || \
     [ "$PREFLIGHT_IDENTITY_RC" != "0" ] || \
     [ "$TEMPLATE_IDENTITY_RC" != "0" ]; then
    RUN_OK=0
  fi
fi

if [ "$RUN_OK" = "1" ] && [ "$MODE" != "base" ]; then
  PRIOR_STATUS="$PRIOR_ROOT/digital_assembly_pvs_gate.rpt"
  check_manifest "$PRIOR_ROOT" "$PRIOR_ROOT/SHA256SUMS" \
    > "$OUTPUT_ROOT/logs/prior_manifest.log" 2>&1
  PRIOR_MANIFEST_RC=$?
  if [ "$MODE" = "density" ]; then
    require_lines "$PRIOR_STATUS" \
      'STATUS=PASS' \
      "PHASE=$PHASE" \
      'MODE=BASE' \
      "TOP_MODULE=$TOP_MODULE" \
      "PACKAGE=$PACKAGE" \
      "GDS_SHA256=$GDS_SHA" \
      'PVS_BASE_DRC_STATUS=PASS'
    PRIOR_STATUS_RC=$?
  elif [ "$PHASE" = "p03_matrix_interface" ]; then
    require_lines "$PRIOR_STATUS" \
      'STATUS=PASS' \
      "PHASE=$PHASE" \
      'MODE=DENSITY' \
      "TOP_MODULE=$TOP_MODULE" \
      "PACKAGE=$PACKAGE" \
      "GDS_SHA256=$GDS_SHA" \
      'PVS_BASE_DRC_STATUS=PASS'
    PRIOR_STATUS_RC=$?
    PRIOR_DENSITY_STATUS="$(kv_field "$PRIOR_STATUS" PVS_DENSITY_DRC_STATUS)"
    case "$PRIOR_DENSITY_STATUS" in
      PASS|CLASSIFIED_RULE_DEBT) ;;
      *) PRIOR_STATUS_RC=1 ;;
    esac
  else
    require_lines "$PRIOR_STATUS" \
      'STATUS=PASS' \
      "PHASE=$PHASE" \
      'MODE=BASE' \
      "TOP_MODULE=$TOP_MODULE" \
      "PACKAGE=$PACKAGE" \
      "GDS_SHA256=$GDS_SHA" \
      'PVS_BASE_DRC_STATUS=PASS'
    PRIOR_STATUS_RC=$?
  fi
  echo "PRIOR_MANIFEST_RC=$PRIOR_MANIFEST_RC"
  echo "PRIOR_STATUS_RC=$PRIOR_STATUS_RC"
  if [ "$PRIOR_MANIFEST_RC" != "0" ] || [ "$PRIOR_STATUS_RC" != "0" ]; then
    RUN_OK=0
  fi
fi

if [ "$RUN_OK" = "1" ]; then
  RUN_ID="digital_assembly_${PHASE}_${MODE}_${TIMESTAMP}"
  if [ "$MODE" = "lvs" ]; then
    RUN_DIR="$PACKAGE/pvs/lvs/$RUN_ID"
  else
    RUN_DIR="$PACKAGE/pvs/drc/$RUN_ID"
  fi
  if [ -e "$RUN_DIR" ]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: fresh run directory already exists: $RUN_DIR"
    RUN_OK=0
  fi
fi

if [ "$RUN_OK" = "1" ] && [ "$MODE" != "lvs" ]; then
  echo "MANUAL_REVIEW_DECISION=AUTHORIZE_ONE_FOREGROUND_${MODE^^}_PVS_DRC"
  EXPECTED_HEAD="$EXPECTED_HEAD" SPADMIC_CADENCE_PVS_BIN="$PVS_BIN" \
    bash TOP/pnr/scripts/run_pvs_drc_handoff.sh \
      --package "$PACKAGE" \
      --template "$DRC_TEMPLATE" \
      --template-gds "$DRC_TEMPLATE_GDS" \
      --template-top "$DRC_TEMPLATE_TOP" \
      --variant "$MODE" \
      --run-id "$RUN_ID" \
      --allow-cross-block-control-scaffold \
      > "$OUTPUT_ROOT/logs/pvs.console.log" 2>&1
  PVS_WRAPPER_RC=$?
fi

if [ "$RUN_OK" = "1" ] && [ "$MODE" = "lvs" ]; then
  LVS_AUDIT="$PREFLIGHT_ROOT/lvs_template_scaffold_audit.rpt"
  LVS_TEMPLATE_GDS="$(kv_field "$LVS_AUDIT" TEMPLATE_GDS)"
  LVS_TEMPLATE_SOURCE="$(kv_field "$LVS_AUDIT" TEMPLATE_SOURCE)"
  LVS_TEMPLATE_LAYOUT_TOP="$(kv_field "$LVS_AUDIT" TEMPLATE_LAYOUT_TOP)"
  LVS_TEMPLATE_SOURCE_TOP="$(kv_field "$LVS_AUDIT" TEMPLATE_SOURCE_TOP)"
  LVS_TEMPLATE_CDL="$(kv_field "$LVS_AUDIT" TEMPLATE_EXECUTABLE_CDL)"
  LVS_ARGS=(
    --package "$PACKAGE"
    --template "$LVS_TEMPLATE"
    --template-gds "$LVS_TEMPLATE_GDS"
    --template-source "$LVS_TEMPLATE_SOURCE"
    --template-layout-top "$LVS_TEMPLATE_LAYOUT_TOP"
    --template-source-top "$LVS_TEMPLATE_SOURCE_TOP"
    --run-id "$RUN_ID"
    --allow-cross-block-control-scaffold
  )
  if [ "$LVS_TEMPLATE_CDL" != "NONE" ] && [ -n "$LVS_TEMPLATE_CDL" ]; then
    LVS_ARGS+=(--template-cdl "$LVS_TEMPLATE_CDL")
  fi
  echo "MANUAL_REVIEW_DECISION=AUTHORIZE_ONE_FOREGROUND_EXACT_GDS_PVS_LVS"
  EXPECTED_HEAD="$EXPECTED_HEAD" SPADMIC_CADENCE_PVS_BIN="$PVS_BIN" \
    bash TOP/pnr/scripts/run_pvs_lvs_handoff.sh "${LVS_ARGS[@]}" \
      > "$OUTPUT_ROOT/logs/pvs.console.log" 2>&1
  PVS_WRAPPER_RC=$?
fi

if [ "$RUN_OK" = "1" ]; then
if [ -f "$RUN_DIR/pvs.stdout.log" ]; then
  PVS_EXECUTION_EVIDENCE_RC=0
else
  PVS_EXECUTION_EVIDENCE_RC=1
fi

RAW_STATUS="$RUN_DIR/pvs_drc_status.rpt"
if [ "$MODE" = "lvs" ]; then
  RAW_STATUS="$RUN_DIR/pvs_lvs_status.rpt"
fi
if [ "$MODE" = "base" ]; then
  [ "$PVS_WRAPPER_RC" = "0" ]
  WRAPPER_CLASS_RC=$?
elif [ "$MODE" = "density" ]; then
  RAW_DRC_STATUS="$(kv_field "$RAW_STATUS" PVS_DRC_STATUS)"
  if { [ "$PVS_WRAPPER_RC" = "0" ] && [ "$RAW_DRC_STATUS" = "PASS" ]; } || \
     { [ "$PVS_WRAPPER_RC" = "8" ] && [ "$RAW_DRC_STATUS" = "FAIL" ]; }; then
    WRAPPER_CLASS_RC=0
  else
    WRAPPER_CLASS_RC=1
  fi
else
  [ "$PVS_WRAPPER_RC" = "0" ]
  WRAPPER_CLASS_RC=$?
fi

if [ -r "$RUN_DIR/SHA256SUMS" ]; then
  check_manifest "$RUN_DIR" "$RUN_DIR/SHA256SUMS" \
    > "$OUTPUT_ROOT/logs/run_manifest.log" 2>&1
  RUN_MANIFEST_RC=$?
else
  RUN_MANIFEST_RC=1
fi

PREFLIGHT_VARIANT="$MODE"
if [ "$MODE" = "lvs" ]; then
  PREFLIGHT_VARIANT=lvs
fi
cmp -s "$PREFLIGHT_ROOT/dry_runs/$PREFLIGHT_VARIANT/external_references.rpt" \
  "$RUN_DIR/external_references.rpt"
EXTERNAL_REFERENCE_RC=$?

if [ "$MODE" = "density" ] && [ "$(kv_field "$RAW_STATUS" PVS_DRC_STATUS)" = "FAIL" ]; then
  ANALYSIS_ROOT="$OUTPUT_ROOT/rule_analysis"
  DRC_TOTAL_PRIMARY="$(kv_field "$RAW_STATUS" DRC_TOTAL_PRIMARY)"
  DRC_TOTAL_EXPANDED="$(kv_field "$RAW_STATUS" DRC_TOTAL_EXPANDED)"
  python3 TOP/pnr/scripts/analyze_pvs_drc_run.py \
    --run-dir "$RUN_DIR" \
    --output-dir "$ANALYSIS_ROOT" \
    --expected-primary "$DRC_TOTAL_PRIMARY" \
    --expected-expanded "$DRC_TOTAL_EXPANDED" \
    --expected-variant density \
    > "$OUTPUT_ROOT/logs/rule_analysis.log" 2>&1
  RULE_ANALYSIS_RC=$?
fi

if [ "$MODE" = "density" ]; then
  RAW_DRC_STATUS="$(kv_field "$RAW_STATUS" PVS_DRC_STATUS)"
  if [ "$RAW_DRC_STATUS" = "FAIL" ] && [ "$RULE_ANALYSIS_RC" = "0" ]; then
    DENSITY_ANALYSIS_GATE_RC=0
  elif [ "$RAW_DRC_STATUS" = "PASS" ] && \
       [ "$RULE_ANALYSIS_RC" = "NOT_APPLICABLE" ]; then
    DENSITY_ANALYSIS_GATE_RC=0
  else
    DENSITY_ANALYSIS_GATE_RC=1
  fi
fi

if [ "$MODE" = "lvs" ]; then
  python3 TOP/pnr/scripts/audit_pvs_lvs_run_control.py \
    --control "$RUN_DIR/pvslvsctl" \
    --expected-gds "$GDS" \
    --expected-source "$SOURCE" \
    --expected-cdl "$CDL" \
    --expected-svdb "$RUN_DIR/svdb" \
    > "$OUTPUT_ROOT/run_control_audit.rpt" 2>&1
  RUN_CONTROL_AUDIT_RC=$?
fi

VALIDATOR_ARGS=(
  --phase "$PHASE"
  --mode "$MODE"
  --package "$PACKAGE"
  --run-dir "$RUN_DIR"
  --status "$OUTPUT_ROOT/digital_assembly_pvs_gate.rpt"
  --expected-head "$EXPECTED_HEAD"
  --actual-head "$ACTUAL_HEAD"
)
if [ "$MODE" != "base" ]; then
  VALIDATOR_ARGS+=(--prior-status "$PRIOR_STATUS")
fi
if [ "$ANALYSIS_ROOT" != "NOT_APPLICABLE" ]; then
  VALIDATOR_ARGS+=(--analysis-root "$ANALYSIS_ROOT")
fi
python3 TOP/pnr/scripts/validate_digital_assembly_pvs_phase.py "${VALIDATOR_ARGS[@]}" \
  > "$OUTPUT_ROOT/logs/validator.log" 2>&1
VALIDATOR_RC=$?

if [ -d "$RUN_DIR" ]; then
  cp -a "$RUN_DIR/." "$OUTPUT_ROOT/run_evidence/"
fi
cp -p "$PREFLIGHT_STATUS" "$OUTPUT_ROOT/source_preflight/" 2>/dev/null
cp -p "$PREFLIGHT_ROOT/template_files.pre.tsv" "$OUTPUT_ROOT/source_preflight/" 2>/dev/null
if [ "$MODE" != "base" ]; then
  cp -p "$PRIOR_STATUS" "$OUTPUT_ROOT/source_prior/" 2>/dev/null
fi

check_manifest "$PACKAGE" "$PACKAGE/manifests/SHA256SUMS" \
  > "$OUTPUT_ROOT/logs/package_postcheck.log" 2>&1
PACKAGE_POSTCHECK_RC=$?
check_manifest "$PREFLIGHT_ROOT" "$PREFLIGHT_ROOT/SHA256SUMS" \
  > "$OUTPUT_ROOT/logs/preflight_postcheck.log" 2>&1
PREFLIGHT_POSTCHECK_RC=$?
if [ "$MODE" != "base" ]; then
  check_manifest "$PRIOR_ROOT" "$PRIOR_ROOT/SHA256SUMS" \
    > "$OUTPUT_ROOT/logs/prior_postcheck.log" 2>&1
  PRIOR_POSTCHECK_RC=$?
fi
verify_template_inventory "$PREFLIGHT_ROOT/template_files.pre.tsv" \
  > "$OUTPUT_ROOT/logs/template_postcheck.log" 2>&1
TEMPLATE_POSTCHECK_RC=$?
fi

if [ -d "$OUTPUT_ROOT" ]; then
if [ -r "$GATE_REPORT" ]; then
  {
    echo "SOURCE_PVS_PREFLIGHT_ROOT=$PREFLIGHT_ROOT"
    echo "SOURCE_PVS_PREFLIGHT_STATUS_SHA256=$(sha256sum "$PREFLIGHT_STATUS" | awk '{print $1}')"
    echo "SOURCE_PRIOR_PVS_ROOT=$PRIOR_ROOT"
    if [ "$MODE" != "base" ]; then
      echo "SOURCE_PRIOR_PVS_STATUS_SHA256=$(sha256sum "$PRIOR_STATUS" | awk '{print $1}')"
    else
      echo "SOURCE_PRIOR_PVS_STATUS_SHA256=NOT_APPLICABLE"
    fi
    echo "PVS_WRAPPER_RC=$PVS_WRAPPER_RC"
    echo "WRAPPER_CLASS_RC=$WRAPPER_CLASS_RC"
    echo "PVS_EXECUTION_EVIDENCE_RC=$PVS_EXECUTION_EVIDENCE_RC"
    echo "RUN_MANIFEST_RC=$RUN_MANIFEST_RC"
    echo "EXTERNAL_REFERENCE_RC=$EXTERNAL_REFERENCE_RC"
    echo "RULE_ANALYSIS_RC=$RULE_ANALYSIS_RC"
    echo "DENSITY_ANALYSIS_GATE_RC=$DENSITY_ANALYSIS_GATE_RC"
    echo "RUN_CONTROL_AUDIT_RC=$RUN_CONTROL_AUDIT_RC"
    echo "PACKAGE_POSTCHECK_RC=$PACKAGE_POSTCHECK_RC"
    echo "PREFLIGHT_POSTCHECK_RC=$PREFLIGHT_POSTCHECK_RC"
    echo "PRIOR_POSTCHECK_RC=$PRIOR_POSTCHECK_RC"
    echo "TEMPLATE_POSTCHECK_RC=$TEMPLATE_POSTCHECK_RC"
  } >> "$GATE_REPORT"
else
  if [ "$RUN_OK" != "1" ]; then
    FAILURE_REASON=preconditions_failed_before_pvs_execution
    PVS_EXECUTED_VALUE=NO
  elif [ "$PVS_EXECUTION_EVIDENCE_RC" = "0" ]; then
    FAILURE_REASON=validator_status_missing
    PVS_EXECUTED_VALUE=YES
  else
    FAILURE_REASON=no_classifiable_pvs_execution_evidence
    PVS_EXECUTED_VALUE=UNKNOWN
  fi
  {
    echo "LABEL=SPADMIC_DIGITAL_ASSEMBLY_PVS_GATE"
    echo "STATUS=FAIL"
    echo "RESULT=NO_CLASSIFIABLE_PVS_EVIDENCE"
    echo "EXPECTED_HEAD=$EXPECTED_HEAD"
    echo "ACTUAL_HEAD=$ACTUAL_HEAD"
    echo "PHASE=$PHASE"
    echo "MODE=${MODE^^}"
    echo "TOP_MODULE=$TOP_MODULE"
    echo "PACKAGE=$PACKAGE"
    echo "RUN_DIR=$RUN_DIR"
    echo "ERROR_COUNT=1"
    echo "ERROR=$FAILURE_REASON"
    echo "PVS_EXECUTED=$PVS_EXECUTED_VALUE"
    echo "OA_INSERTION_AUTHORIZED=NO"
    echo "SIGNOFF_READY=NO"
    echo "NEXT_GATE=STOP_AND_REVIEW_PVS_EVIDENCE"
  } > "$GATE_REPORT"
fi

(
  cd "$OUTPUT_ROOT"
  local_cd_rc=$?
  if [ "$local_cd_rc" = "0" ]; then
    find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS
  else
    false
  fi
)
DIAGNOSTIC_MANIFEST_RC=$?
fi

echo "OUTPUT_ROOT=$OUTPUT_ROOT"
echo "RUN_DIR=$RUN_DIR"
echo "PVS_WRAPPER_RC=$PVS_WRAPPER_RC"
echo "WRAPPER_CLASS_RC=$WRAPPER_CLASS_RC"
echo "PVS_EXECUTION_EVIDENCE_RC=$PVS_EXECUTION_EVIDENCE_RC"
echo "RUN_MANIFEST_RC=$RUN_MANIFEST_RC"
echo "EXTERNAL_REFERENCE_RC=$EXTERNAL_REFERENCE_RC"
echo "DENSITY_ANALYSIS_GATE_RC=$DENSITY_ANALYSIS_GATE_RC"
echo "VALIDATOR_RC=$VALIDATOR_RC"
echo "DIAGNOSTIC_MANIFEST_RC=$DIAGNOSTIC_MANIFEST_RC"
cat "$GATE_REPORT" 2>/dev/null

if [ "$RUN_OK" = "1" ] && \
   [ "$WRAPPER_CLASS_RC" = "0" ] && \
   [ "$PVS_EXECUTION_EVIDENCE_RC" = "0" ] && \
   [ "$RUN_MANIFEST_RC" = "0" ] && \
   [ "$EXTERNAL_REFERENCE_RC" = "0" ] && \
   [ "$VALIDATOR_RC" = "0" ] && \
   { [ "$MODE" != "lvs" ] || [ "$RUN_CONTROL_AUDIT_RC" = "0" ]; } && \
   { [ "$MODE" != "density" ] || [ "$DENSITY_ANALYSIS_GATE_RC" = "0" ]; } && \
   [ "$PACKAGE_POSTCHECK_RC" = "0" ] && \
   [ "$PREFLIGHT_POSTCHECK_RC" = "0" ] && \
   { [ "$MODE" = "base" ] || [ "$PRIOR_POSTCHECK_RC" = "0" ]; } && \
   [ "$TEMPLATE_POSTCHECK_RC" = "0" ] && \
   [ "$DIAGNOSTIC_MANIFEST_RC" = "0" ]; then
  echo "DIGITAL_ASSEMBLY_PHASE_PVS_${MODE^^}_TRANSACTION_STATUS=PASS"
  echo "RETURN_OUTPUT_FOR_PHASE_PVS_REVIEW"
  echo "DO_NOT_START_NEXT_PVS_MODE_UNTIL_REVIEWED"
  true
else
  echo "DIGITAL_ASSEMBLY_PHASE_PVS_${MODE^^}_TRANSACTION_STATUS=FAIL"
  echo "STOP_HERE_DO_NOT_RERUN_PVS_OR_START_NEXT_MODE"
  false
fi
