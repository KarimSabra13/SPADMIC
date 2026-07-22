#!/usr/bin/env bash
# Run one fresh cumulative soft digital-assembly phase in Innovus.

set +e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
PHASE="${1:-MISSING}"
GENUS_ROOT="${2:-MISSING}"
PHASE_CONTRACT_ROOT="${3:-MISSING}"
RUN_ID="${4:-digital_assembly_${PHASE}_$(date +%Y%m%d_%H%M%S)}"

case "$PHASE" in
  p00_tx) TOP_MODULE=spadmic_digital_assembly_v1_p00_tx ;;
  p01_position) TOP_MODULE=spadmic_digital_assembly_v1_p01_position ;;
  p02_event_control) TOP_MODULE=spadmic_digital_assembly_v1_p02_event_control ;;
  p03_matrix_interface) TOP_MODULE=spadmic_digital_assembly_v1_p03_matrix_interface ;;
  *)
    echo "ERROR: unsupported assembly phase: $PHASE" >&2
    exit 2
    ;;
esac

if [ "$GENUS_ROOT" = "MISSING" ] || [ "$PHASE_CONTRACT_ROOT" = "MISSING" ]; then
  echo "Usage: $0 <phase> <accepted-genus-root> <phase-contract-root> [run-id]" >&2
  exit 2
fi

GENUS_ROOT="$(cd "$GENUS_ROOT" 2>/dev/null && pwd -P)"
GENUS_ROOT_RC=$?
PHASE_CONTRACT_ROOT="$(cd "$PHASE_CONTRACT_ROOT" 2>/dev/null && pwd -P)"
PHASE_CONTRACT_ROOT_RC=$?
RUN_ROOT="$WORK_ROOT/innovus/$RUN_ID"
REPORTS="$RUN_ROOT/reports"
OUTPUTS="$RUN_ROOT/outputs"
CHECKPOINTS="$RUN_ROOT/checkpoints"
GENERATED="$RUN_ROOT/generated"
LOGS="$RUN_ROOT/logs"
SOURCE_EVIDENCE="$RUN_ROOT/source_evidence"

GENUS_STATUS="$GENUS_ROOT/digital_assembly_genus_execution_status.rpt"
GENUS_GATE="$GENUS_ROOT/reports/timing/digital_assembly_genus_tc_gate.rpt"
NETLIST="$GENUS_ROOT/outputs/${TOP_MODULE}.postsyn.v"
SDC="$GENUS_ROOT/outputs/${TOP_MODULE}.postsyn.sdc"
CONTRACT_STATUS="$PHASE_CONTRACT_ROOT/assembly_phase_contract_status.rpt"
CONFIG_TCL="$PHASE_CONTRACT_ROOT/assembly_phase_config.tcl"

DEFAULT_STREAM_MAP=/eda/pdk/xfab/xh018/cadence/v10_1/PDK/IC61/v10_1_1/TECH_XH018_HD_1131/pnr_streamout.map
DEFAULT_STDCELL_GDS=/data/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/gds_cdl/v6_0_0/gds/xh018_D_CELLS_JIHD.gds
STREAM_MAP="${SPADMIC_STREAMOUT_MAP_FILE:-$DEFAULT_STREAM_MAP}"
STDCELL_GDS="${SPADMIC_STDCELL_GDS:-$DEFAULT_STDCELL_GDS}"

RUN_OK=1
GENUS_MANIFEST_RC=1
GENUS_STATUS_GATE_RC=1
CONTRACT_MANIFEST_RC=1
CONTRACT_STATUS_GATE_RC=1
INPUT_FILE_GATE_RC=1
INNOVUS_ENV_RC=1
INNOVUS_RC=NOT_RUN
GDS_AUDIT_RC=NOT_RUN
INNOVUS_GATE_RC=NOT_RUN
RUN_MANIFEST_RC=NOT_RUN

if [ "$GENUS_ROOT_RC" != "0" ] || [ "$PHASE_CONTRACT_ROOT_RC" != "0" ]; then
  echo "ERROR: accepted Genus or phase-contract root is missing" >&2
  RUN_OK=0
fi
if [ -e "$RUN_ROOT" ]; then
  echo "ERROR: immutable Innovus run root already exists: $RUN_ROOT" >&2
  RUN_OK=0
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
  require_lines "$GENUS_STATUS" \
    'STATUS=PASS' \
    "PHASE=$PHASE" \
    "TOP_MODULE=$TOP_MODULE" \
    "SOURCE_TOP=$TOP_MODULE" \
    "LAYOUT_TOP=$TOP_MODULE" \
    'IMPLEMENTATION=CUMULATIVE_SOFT_LOGIC' \
    'HARD_MACRO_COUNT=0' \
    'TYPICAL_CLOSED=YES' \
    'INNOVUS_EXECUTED=NO' \
    'PVS_EXECUTED=NO'
  GENUS_STATUS_GATE_RC=$?
  require_lines "$GENUS_GATE" \
    'STATUS=PASS' \
    'RESULT=INNOVUS_HANDOFF_READY' \
    "PHASE=$PHASE" \
    "TOP_MODULE=$TOP_MODULE" \
    'BOUNDARY_STATUS=PASS' \
    'SETUP_STATUS=PASS' \
    'HOLD_STATUS=PASS' \
    'TYPICAL_CLOSED=YES' \
    'INNOVUS_HANDOFF_READY=YES'
  if [ "$?" != "0" ]; then
    GENUS_STATUS_GATE_RC=1
  fi

  check_manifest "$PHASE_CONTRACT_ROOT"
  CONTRACT_MANIFEST_RC=$?
  require_lines "$CONTRACT_STATUS" \
    'STATUS=PASS' \
    "PHASE=$PHASE" \
    "SOURCE_TOP=$TOP_MODULE" \
    "LAYOUT_TOP=$TOP_MODULE" \
    'IMPLEMENTATION=CUMULATIVE_SOFT_LOGIC' \
    'HARD_MACRO_COUNT=0' \
    'CHILD_GDS_MERGE_COUNT=0' \
    'SIGNAL_ROUTE_LAYERS=MET1-MET3' \
    'METTP_POLICY=PG_AND_BOUNDED_PIN_ACCESS_ONLY'
  CONTRACT_STATUS_GATE_RC=$?

  INPUT_FILE_GATE_RC=0
  for file in "$NETLIST" "$SDC" "$CONFIG_TCL" "$STREAM_MAP" "$STDCELL_GDS"; do
    if [ ! -s "$file" ]; then
      echo "MISSING_OR_EMPTY=$file"
      INPUT_FILE_GATE_RC=1
    fi
  done
  if [ "$GENUS_MANIFEST_RC" != "0" ] || \
     [ "$GENUS_STATUS_GATE_RC" != "0" ] || \
     [ "$CONTRACT_MANIFEST_RC" != "0" ] || \
     [ "$CONTRACT_STATUS_GATE_RC" != "0" ] || \
     [ "$INPUT_FILE_GATE_RC" != "0" ]; then
    RUN_OK=0
  fi
fi

if [ "$RUN_OK" = "1" ]; then
  mkdir -p "$REPORTS" "$OUTPUTS" "$CHECKPOINTS" "$GENERATED" "$LOGS" "$SOURCE_EVIDENCE/genus" "$SOURCE_EVIDENCE/phase_contract"
  if [ "$?" != "0" ]; then
    RUN_OK=0
  fi
fi

if [ "$RUN_OK" = "1" ]; then
  cp -p "$GENUS_STATUS" "$GENUS_GATE" "$GENUS_ROOT/SHA256SUMS" "$SOURCE_EVIDENCE/genus/"
  cp -p "$CONTRACT_STATUS" "$CONFIG_TCL" "$PHASE_CONTRACT_ROOT/SHA256SUMS" "$SOURCE_EVIDENCE/phase_contract/"
  cp -p "$PHASE_CONTRACT_ROOT/fixed_obstacles.tsv" \
    "$PHASE_CONTRACT_ROOT/soft_group_guides.tsv" \
    "$PHASE_CONTRACT_ROOT/pg_overlap_anchors.tsv" \
    "$PHASE_CONTRACT_ROOT/matrix_proxy_pin_plan.tsv" \
    "$SOURCE_EVIDENCE/phase_contract/"
  {
    echo "LABEL=SPADMIC_DIGITAL_ASSEMBLY_INNOVUS_INPUT_MANIFEST"
    echo "PHASE=$PHASE"
    echo "TOP_MODULE=$TOP_MODULE"
    echo "GENUS_ROOT=$GENUS_ROOT"
    echo "PHASE_CONTRACT_ROOT=$PHASE_CONTRACT_ROOT"
    echo "NETLIST=$NETLIST"
    echo "NETLIST_SHA256=$(sha256sum "$NETLIST" | awk '{print $1}')"
    echo "SDC=$SDC"
    echo "SDC_SHA256=$(sha256sum "$SDC" | awk '{print $1}')"
    echo "CONFIG_TCL=$CONFIG_TCL"
    echo "CONFIG_TCL_SHA256=$(sha256sum "$CONFIG_TCL" | awk '{print $1}')"
    echo "STREAM_MAP=$STREAM_MAP"
    echo "STREAM_MAP_SHA256=$(sha256sum "$STREAM_MAP" | awk '{print $1}')"
    echo "STDCELL_GDS=$STDCELL_GDS"
    echo "STDCELL_GDS_SHA256=$(sha256sum "$STDCELL_GDS" | awk '{print $1}')"
    echo "HARD_MACRO_LEF_COUNT=0"
    echo "CHILD_GDS_MERGE_COUNT=0"
  } > "$RUN_ROOT/run_manifest.rpt"
fi

if [ "$RUN_OK" = "1" ]; then
  command -v innovus >/dev/null 2>&1
  INNOVUS_ENV_RC=$?
  if [ "$INNOVUS_ENV_RC" != "0" ]; then
    echo "ERROR: innovus missing; source /eda/cadence/eda_2023-2024" >&2
    RUN_OK=0
  fi
fi

if [ "$RUN_OK" = "1" ]; then
  export MPTDC_XH018_STACK="${MPTDC_XH018_STACK:-xx31}"
  export MPTDC_STDCELL_FAMILY="${MPTDC_STDCELL_FAMILY:-JIHD}"
  export MPTDC_PNR_ROUTE_LAYER_NAMES="${MPTDC_PNR_ROUTE_LAYER_NAMES:-MET1 MET2 MET3 METTP}"
  export MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY="${MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY:-1}"
  export SPADMIC_REPO_ROOT="$REPO_ROOT"
  export SPADMIC_DA_PHASE="$PHASE"
  export SPADMIC_DA_TOP_MODULE="$TOP_MODULE"
  export SPADMIC_DA_RUN_ROOT="$RUN_ROOT"
  export SPADMIC_DA_GENUS_ROOT="$GENUS_ROOT"
  export SPADMIC_DA_PHASE_CONTRACT_ROOT="$PHASE_CONTRACT_ROOT"
  export SPADMIC_DA_CONFIG_TCL="$CONFIG_TCL"
  export SPADMIC_DA_NETLIST="$NETLIST"
  export SPADMIC_DA_SDC="$SDC"
  export SPADMIC_STREAMOUT_MAP_FILE="$STREAM_MAP"
  export SPADMIC_STDCELL_GDS="$STDCELL_GDS"

  innovus -nowin -init "$SCRIPT_DIR/run_innovus_digital_assembly.tcl" \
    -log "$LOGS/innovus.log" \
    </dev/null \
    > "$LOGS/innovus.stdout.log" 2>&1
  INNOVUS_RC=$?
  echo "INNOVUS_RC=$INNOVUS_RC"
fi

GDS="$OUTPUTS/${TOP_MODULE}.gds"
if [ -s "$GDS" ] && [ -s "$LOGS/innovus.log" ]; then
  python3 "$SCRIPT_DIR/audit_innovus_gds_export.py" \
    --gds "$GDS" \
    --log "$LOGS/innovus.log" \
    --stream-map "$STREAM_MAP" \
    --required-merge "$STDCELL_GDS" \
    --status "$REPORTS/gds_export_audit.rpt" \
    > "$LOGS/gds_export_audit.log" 2>&1
  GDS_AUDIT_RC=$?
fi

python3 "$SCRIPT_DIR/validate_innovus_digital_assembly_phase.py" \
  --phase "$PHASE" \
  --run-root "$RUN_ROOT" \
  --genus-root "$GENUS_ROOT" \
  --phase-contract-root "$PHASE_CONTRACT_ROOT" \
  --gds-audit "$REPORTS/gds_export_audit.rpt" \
  --status "$REPORTS/digital_assembly_innovus_gate.rpt" \
  > "$LOGS/innovus_gate.log" 2>&1
INNOVUS_GATE_RC=$?

if [ "$INNOVUS_RC" = "0" ] && [ "$GDS_AUDIT_RC" = "0" ] && [ "$INNOVUS_GATE_RC" = "0" ]; then
  WRAPPER_STATUS=PASS
  WRAPPER_RESULT=PHASE_INNOVUS_ACCEPTED_FOR_IMMUTABLE_HANDOFF
  NEXT_GATE=REVIEW_INNOVUS_THEN_STAGE_EXACT_PHASE_HANDOFF
else
  WRAPPER_STATUS=FAIL
  WRAPPER_RESULT=PHASE_INNOVUS_REVIEW_REQUIRED
  NEXT_GATE=STOP_AND_REVIEW_PHASE_INNOVUS
fi

if [ -d "$RUN_ROOT" ]; then
  {
    echo "LABEL=SPADMIC_DIGITAL_ASSEMBLY_INNOVUS_EXECUTION"
    echo "STATUS=$WRAPPER_STATUS"
    echo "RESULT=$WRAPPER_RESULT"
    echo "PHASE=$PHASE"
    echo "TOP_MODULE=$TOP_MODULE"
    echo "SOURCE_TOP=$TOP_MODULE"
    echo "LAYOUT_TOP=$TOP_MODULE"
    echo "IMPLEMENTATION=CUMULATIVE_SOFT_LOGIC"
    echo "GENUS_ROOT=$GENUS_ROOT"
    echo "PHASE_CONTRACT_ROOT=$PHASE_CONTRACT_ROOT"
    echo "GENUS_MANIFEST_RC=$GENUS_MANIFEST_RC"
    echo "GENUS_STATUS_GATE_RC=$GENUS_STATUS_GATE_RC"
    echo "CONTRACT_MANIFEST_RC=$CONTRACT_MANIFEST_RC"
    echo "CONTRACT_STATUS_GATE_RC=$CONTRACT_STATUS_GATE_RC"
    echo "INPUT_FILE_GATE_RC=$INPUT_FILE_GATE_RC"
    echo "INNOVUS_ENV_RC=$INNOVUS_ENV_RC"
    echo "INNOVUS_RC=$INNOVUS_RC"
    echo "GDS_AUDIT_RC=$GDS_AUDIT_RC"
    echo "INNOVUS_GATE_RC=$INNOVUS_GATE_RC"
    echo "HARD_MACRO_COUNT=0"
    echo "CHILD_GDS_MERGE_COUNT=0"
    echo "PVS_EXECUTED=NO"
    echo "SIGNOFF_READY=NO"
    echo "NEXT_GATE=$NEXT_GATE"
  } > "$RUN_ROOT/digital_assembly_innovus_execution_status.rpt"
  (
    cd "$RUN_ROOT"
    local_cd_rc=$?
    if [ "$local_cd_rc" = "0" ]; then
      find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS
    else
      false
    fi
  )
  RUN_MANIFEST_RC=$?
fi

echo "RUN_ROOT=$RUN_ROOT"
echo "RUN_MANIFEST_RC=$RUN_MANIFEST_RC"
cat "$REPORTS/digital_assembly_innovus_gate.rpt" 2>/dev/null
cat "$RUN_ROOT/digital_assembly_innovus_execution_status.rpt" 2>/dev/null

if [ "$WRAPPER_STATUS" = "PASS" ] && [ "$RUN_MANIFEST_RC" = "0" ]; then
  exit 0
fi
exit 8
