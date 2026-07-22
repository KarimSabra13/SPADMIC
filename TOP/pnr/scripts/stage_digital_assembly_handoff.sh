#!/usr/bin/env bash
# Stage one exact-top cumulative assembly Innovus result for PVS.

set +e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PHASE="${1:-MISSING}"
ASSEMBLY_RUN_ROOT="${2:-MISSING}"
VERSION="${3:-assembly_${PHASE}_$(date +%Y%m%d_%H%M%S)}"
HANDOFF_ROOT="${SPADMIC_INNOVUS_HANDOFF_ROOT:-${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}/handoff/innovus}"

case "$PHASE" in
  p00_tx) PHASE_TOP=spadmic_digital_assembly_v1_p00_tx ;;
  p01_position) PHASE_TOP=spadmic_digital_assembly_v1_p01_position ;;
  p02_event_control) PHASE_TOP=spadmic_digital_assembly_v1_p02_event_control ;;
  p03_matrix_interface) PHASE_TOP=spadmic_digital_assembly_v1_p03_matrix_interface ;;
  *)
    echo "Usage: $0 <p00_tx|p01_position|p02_event_control|p03_matrix_interface> <accepted-Innovus-run-root> [version]" >&2
    exit 2
    ;;
esac

if [ "$ASSEMBLY_RUN_ROOT" = "MISSING" ] || [ ! -d "$ASSEMBLY_RUN_ROOT" ]; then
  echo "ERROR: accepted assembly Innovus run root is required" >&2
  exit 2
fi
ASSEMBLY_RUN_ROOT="$(cd "$ASSEMBLY_RUN_ROOT" && pwd -P)"

SOURCE="$ASSEMBLY_RUN_ROOT/outputs/${PHASE_TOP}.pg.v"
DEF="$ASSEMBLY_RUN_ROOT/outputs/${PHASE_TOP}.def"
LEF="$ASSEMBLY_RUN_ROOT/outputs/${PHASE_TOP}.lef"
GDS="$ASSEMBLY_RUN_ROOT/outputs/${PHASE_TOP}.gds"
EXECUTION_STATUS="$ASSEMBLY_RUN_ROOT/digital_assembly_innovus_execution_status.rpt"
INNOVUS_GATE="$ASSEMBLY_RUN_ROOT/reports/digital_assembly_innovus_gate.rpt"
GDS_AUDIT="$ASSEMBLY_RUN_ROOT/reports/gds_export_audit.rpt"

RUN_MANIFEST_RC=1
STATUS_GATE_RC=0
if [ -r "$ASSEMBLY_RUN_ROOT/SHA256SUMS" ]; then
  (
    cd "$ASSEMBLY_RUN_ROOT"
    local_cd_rc=$?
    if [ "$local_cd_rc" = "0" ]; then
      sha256sum -c SHA256SUMS
    else
      false
    fi
  )
  RUN_MANIFEST_RC=$?
fi

for file in "$SOURCE" "$DEF" "$LEF" "$GDS" "$EXECUTION_STATUS" "$INNOVUS_GATE" "$GDS_AUDIT"; do
  if [ ! -s "$file" ]; then
    echo "MISSING_OR_EMPTY=$file"
    STATUS_GATE_RC=1
  fi
done
for spec in \
  "$EXECUTION_STATUS|STATUS=PASS" \
  "$EXECUTION_STATUS|PHASE=$PHASE" \
  "$EXECUTION_STATUS|TOP_MODULE=$PHASE_TOP" \
  "$EXECUTION_STATUS|INNOVUS_GATE_RC=0" \
  "$EXECUTION_STATUS|GDS_AUDIT_RC=0" \
  "$INNOVUS_GATE|STATUS=PASS" \
  "$INNOVUS_GATE|RESULT=INNOVUS_HANDOFF_READY" \
  "$INNOVUS_GATE|PHASE=$PHASE" \
  "$INNOVUS_GATE|TOP_MODULE=$PHASE_TOP" \
  "$INNOVUS_GATE|SOURCE_TOP=$PHASE_TOP" \
  "$INNOVUS_GATE|LAYOUT_TOP=$PHASE_TOP" \
  "$INNOVUS_GATE|HARD_MACRO_COUNT=0" \
  "$INNOVUS_GATE|CHILD_GDS_MERGE_COUNT=0" \
  "$INNOVUS_GATE|TC_SETUP_STATUS=PASS" \
  "$INNOVUS_GATE|TC_HOLD_STATUS=PASS" \
  "$INNOVUS_GATE|INNOVUS_DRC_STATUS=PASS" \
  "$INNOVUS_GATE|REGULAR_CONNECTIVITY_STATUS=PASS" \
  "$INNOVUS_GATE|PG_CONNECTIVITY_STATUS=PASS" \
  "$GDS_AUDIT|STATUS=PASS"
do
  report="${spec%%|*}"
  line="${spec#*|}"
  grep -Fxq -- "$line" "$report" 2>/dev/null
  if [ "$?" != "0" ]; then
    echo "STATUS_LINE_MISSING=$report|$line"
    STATUS_GATE_RC=1
  fi
done

if [ "$RUN_MANIFEST_RC" != "0" ] || [ "$STATUS_GATE_RC" != "0" ]; then
  echo "ASSEMBLY_STAGE_RC=8"
  echo "STOP_HERE_DO_NOT_CREATE_HANDOFF_OR_START_PVS"
  exit 8
fi

ARGS=(
  --kind assembly
  --name "$PHASE_TOP"
  --version "$VERSION"
  --source-root "$ASSEMBLY_RUN_ROOT"
  --gds "$GDS"
  --layout-top "$PHASE_TOP"
  --netlist "$SOURCE"
  --source-top "$PHASE_TOP"
  --lef "$LEF"
  --def-file "$DEF"
  --handoff-root "$HANDOFF_ROOT"
  --repo-root "$REPO_ROOT"
  --qualification-profile digital_assembly_tc
)
for report in "$ASSEMBLY_RUN_ROOT"/reports/*.rpt; do
  if [ -s "$report" ]; then
    ARGS+=(--report "$report")
  fi
done
for log in "$ASSEMBLY_RUN_ROOT/logs/innovus.log" "$ASSEMBLY_RUN_ROOT/logs/innovus.stdout.log"; do
  if [ -s "$log" ]; then
    ARGS+=(--log "$log")
  fi
done

python3 "$SCRIPT_DIR/stage_innovus_handoff.py" "${ARGS[@]}"
STAGE_RC=$?
PACKAGE="$HANDOFF_ROOT/assemblies/$PHASE_TOP/$VERSION"
AUDIT_RC=NOT_RUN
if [ "$STAGE_RC" = "0" ]; then
  python3 "$SCRIPT_DIR/audit_innovus_handoff.py" "$PACKAGE"
  AUDIT_RC=$?
fi
echo "RUN_MANIFEST_RC=$RUN_MANIFEST_RC"
echo "STATUS_GATE_RC=$STATUS_GATE_RC"
echo "ASSEMBLY_STAGE_RC=$STAGE_RC"
echo "ASSEMBLY_AUDIT_RC=$AUDIT_RC"
echo "ASSEMBLY_PACKAGE=$PACKAGE"
if [ "$STAGE_RC" = "0" ] && [ "$AUDIT_RC" = "0" ]; then
  exit 0
fi
exit 8
