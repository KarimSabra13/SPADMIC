#!/usr/bin/env bash

###############################################################################
# Hash-bound one-action Innovus execution for a cumulative assembly phase.
#
# Usage:
#   bash TOP/ci/server_run_digital_assembly_phase_innovus.sh \
#     <expected-head> <phase> <accepted-genus-root> <accepted-preflight-root>
###############################################################################

set +e

REPO="${SPADMIC_REPO:-/home/validmgr/ksabra/2026_SPAD/SPADMIC}"
EXPECTED_HEAD="${1:-MISSING}"
PHASE="${2:-MISSING}"
GENUS_ROOT="${3:-MISSING}"
PREFLIGHT_ROOT="${4:-MISSING}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
RUN_ID="digital_assembly_${PHASE}_${TIMESTAMP}"
RUN_ROOT="$WORK_ROOT/innovus/$RUN_ID"
PHASE_CONTRACT_ROOT="$PREFLIGHT_ROOT/phase_contract"

RUN_OK=1
CD_RC=NOT_RUN
CHECKOUT_RC=NOT_RUN
PULL_RC=NOT_RUN
ACTUAL_HEAD=UNKNOWN
TRACKED_DIFF_RC=NOT_RUN
STAGED_DIFF_RC=NOT_RUN
SCRIPT_GATE_RC=NOT_RUN
GENUS_MANIFEST_RC=NOT_RUN
GENUS_STATUS_GATE_RC=NOT_RUN
PREFLIGHT_MANIFEST_RC=NOT_RUN
PREFLIGHT_STATUS_GATE_RC=NOT_RUN
INNOVUS_ENV_RC=NOT_RUN
DRIVER_RC=NOT_RUN
RUN_MANIFEST_RC=NOT_RUN
STATUS_GATE_RC=NOT_RUN

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

if [ "$EXPECTED_HEAD" = "MISSING" ] || [ "$GENUS_ROOT" = "MISSING" ] || [ "$PREFLIGHT_ROOT" = "MISSING" ]; then
  echo "STOP_HERE_DO_NOT_CONTINUE: expected HEAD, phase, Genus root, and preflight root are required"
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
    TOP/pnr/scripts/run_innovus_digital_assembly.sh \
    TOP/pnr/scripts/run_innovus_digital_assembly.tcl \
    TOP/pnr/scripts/validate_innovus_digital_assembly_phase.py \
    TOP/pnr/scripts/audit_innovus_gds_export.py
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

check_manifest() {
  local root="$1"
  if [ ! -r "$root/SHA256SUMS" ]; then
    return 1
  fi
  (
    cd "$root"
    local local_cd_rc=$?
    if [ "$local_cd_rc" = "0" ]; then
      sha256sum -c SHA256SUMS
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

if [ "$RUN_OK" = "1" ]; then
  check_manifest "$GENUS_ROOT"
  GENUS_MANIFEST_RC=$?
  require_lines "$GENUS_ROOT/digital_assembly_genus_execution_status.rpt" \
    'STATUS=PASS' \
    "EXPECTED_HEAD=$EXPECTED_HEAD" \
    "ACTUAL_HEAD=$EXPECTED_HEAD" \
    "PHASE=$PHASE" \
    "TOP_MODULE=$TOP_MODULE" \
    'TYPICAL_CLOSED=YES' \
    'INNOVUS_EXECUTED=NO'
  GENUS_STATUS_GATE_RC=$?

  check_manifest "$PREFLIGHT_ROOT"
  PREFLIGHT_MANIFEST_RC=$?
  require_lines "$PREFLIGHT_ROOT/digital_assembly_phase_preflight_status.rpt" \
    'STATUS=PASS' \
    "EXPECTED_HEAD=$EXPECTED_HEAD" \
    "ACTUAL_HEAD=$EXPECTED_HEAD" \
    "PHASE=$PHASE" \
    "TOP_MODULE=$TOP_MODULE" \
    'VERILATOR_RC=0' \
    'BOUNDARY_RC=0' \
    'GENUS_EXECUTED=NO' \
    'INNOVUS_EXECUTED=NO'
  PREFLIGHT_STATUS_GATE_RC=$?
  echo "GENUS_MANIFEST_RC=$GENUS_MANIFEST_RC"
  echo "GENUS_STATUS_GATE_RC=$GENUS_STATUS_GATE_RC"
  echo "PREFLIGHT_MANIFEST_RC=$PREFLIGHT_MANIFEST_RC"
  echo "PREFLIGHT_STATUS_GATE_RC=$PREFLIGHT_STATUS_GATE_RC"
  if [ "$GENUS_MANIFEST_RC" != "0" ] || \
     [ "$GENUS_STATUS_GATE_RC" != "0" ] || \
     [ "$PREFLIGHT_MANIFEST_RC" != "0" ] || \
     [ "$PREFLIGHT_STATUS_GATE_RC" != "0" ]; then
    RUN_OK=0
  fi
fi

if [ "$RUN_OK" = "1" ]; then
  command -v innovus >/dev/null 2>&1
  INNOVUS_ENV_RC=$?
  if [ "$INNOVUS_ENV_RC" != "0" ]; then
    echo "STOP_HERE_DO_NOT_START_INNOVUS: Cadence Innovus is not in PATH"
    RUN_OK=0
  fi
fi

if [ "$RUN_OK" = "1" ]; then
  bash TOP/pnr/scripts/run_innovus_digital_assembly.sh \
    "$PHASE" \
    "$GENUS_ROOT" \
    "$PHASE_CONTRACT_ROOT" \
    "$RUN_ID"
  DRIVER_RC=$?
fi

STATUS_REPORT="$RUN_ROOT/digital_assembly_innovus_execution_status.rpt"
GATE_REPORT="$RUN_ROOT/reports/digital_assembly_innovus_gate.rpt"
if [ "$DRIVER_RC" != "NOT_RUN" ]; then
  if [ -d "$RUN_ROOT" ]; then
    if [ -r "$RUN_ROOT/SHA256SUMS" ]; then
      check_manifest "$RUN_ROOT"
      RUN_MANIFEST_RC=$?
    else
      RUN_MANIFEST_RC=1
    fi
    require_lines "$STATUS_REPORT" \
      'STATUS=PASS' \
      "PHASE=$PHASE" \
      "TOP_MODULE=$TOP_MODULE" \
      'IMPLEMENTATION=CUMULATIVE_SOFT_LOGIC' \
      'HARD_MACRO_COUNT=0' \
      'CHILD_GDS_MERGE_COUNT=0' \
      'GDS_AUDIT_RC=0' \
      'INNOVUS_GATE_RC=0' \
      'PVS_EXECUTED=NO'
    STATUS_GATE_RC=$?
    require_lines "$GATE_REPORT" \
      'STATUS=PASS' \
      'RESULT=INNOVUS_HANDOFF_READY' \
      "PHASE=$PHASE" \
      "TOP_MODULE=$TOP_MODULE" \
      'HARD_MACRO_COUNT=0' \
      'CHILD_GDS_MERGE_COUNT=0' \
      'FLOORPLAN_GEOMETRY_STATUS=PASS' \
      'TC_SETUP_STATUS=PASS' \
      'TC_HOLD_STATUS=PASS' \
      'POSTROUTE_DESIGN_RULE_STATUS=PASS' \
      'INNOVUS_DRC_STATUS=PASS' \
      'REGULAR_CONNECTIVITY_STATUS=PASS' \
      'PG_CONNECTIVITY_STATUS=PASS' \
      'GDS_EXPORT_AUDIT_STATUS=PASS'
    if [ "$?" != "0" ]; then
      STATUS_GATE_RC=1
    fi
  else
    echo "MISSING_RUN_ROOT=$RUN_ROOT"
    RUN_MANIFEST_RC=1
    STATUS_GATE_RC=1
  fi
fi

echo "INNOVUS_ENV_RC=$INNOVUS_ENV_RC"
echo "DRIVER_RC=$DRIVER_RC"
echo "RUN_ROOT=$RUN_ROOT"
echo "RUN_MANIFEST_RC=$RUN_MANIFEST_RC"
echo "STATUS_GATE_RC=$STATUS_GATE_RC"
cat "$GATE_REPORT" 2>/dev/null

if [ "$DRIVER_RC" = "0" ] && [ "$RUN_MANIFEST_RC" = "0" ] && [ "$STATUS_GATE_RC" = "0" ]; then
  echo "DIGITAL_ASSEMBLY_PHASE_INNOVUS_TRANSACTION_STATUS=PASS"
  echo "RETURN_OUTPUT_FOR_PHASE_INNOVUS_REVIEW"
  echo "DO_NOT_STAGE_HANDOFF_OR_START_PVS_UNTIL_REVIEWED"
  true
else
  echo "DIGITAL_ASSEMBLY_PHASE_INNOVUS_TRANSACTION_STATUS=FAIL"
  echo "STOP_HERE_DO_NOT_STAGE_HANDOFF_OR_START_PVS"
  false
fi
