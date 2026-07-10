#!/usr/bin/env bash
# Phase-A top-coordinate digital assembly. No full-top synthesis or routing.
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
PACKET_PACKAGE="${1:-}"
STRIP_PACKAGE="${2:-}"
RUN_ID="${3:-innovus_digital_assembly_v1_p00_tx_$(date +%Y%m%d_%H%M%S)}"

usage() {
  echo "Usage: $0 <packet-handoff-package> <strip-handoff-package> [run-id]" >&2
}

if [[ -z "$PACKET_PACKAGE" || -z "$STRIP_PACKAGE" ]]; then
  usage
  exit 2
fi

RUN_ROOT="$WORK_ROOT/innovus/$RUN_ID"
GENERATED="$RUN_ROOT/generated"
REPORTS="$RUN_ROOT/reports"
OUTPUTS="$RUN_ROOT/outputs"
CHECKPOINTS="$RUN_ROOT/checkpoints"
LOGS="$RUN_ROOT/logs"
if [[ -e "$RUN_ROOT" ]]; then
  echo "ERROR: immutable run root already exists: $RUN_ROOT" >&2
  exit 2
fi
mkdir -p "$GENERATED" "$REPORTS" "$OUTPUTS" "$CHECKPOINTS" "$LOGS"

manifest_value() {
  python3 - "$1/manifests/package.json" "$2" <<'PY'
import json
import sys
value = json.load(open(sys.argv[1]))
for part in sys.argv[2].split('.'):
    value = value[part]
print(value)
PY
}

PACKET_NAME="$(manifest_value "$PACKET_PACKAGE" name)"
STRIP_NAME="$(manifest_value "$STRIP_PACKAGE" name)"
if [[ "$PACKET_NAME" != "spadmic_tx_packet_core" || "$STRIP_NAME" != "spadmic_tx_ddr_strip" ]]; then
  echo "ERROR: canonical macro gate failed: packet=$PACKET_NAME strip=$STRIP_NAME" >&2
  exit 6
fi
PACKET_LEF="$(find "$PACKET_PACKAGE/lef" -maxdepth 1 -name '*.abstract.lef' -print -quit)"
[[ -n "$PACKET_LEF" ]] || PACKET_LEF="$(find "$PACKET_PACKAGE/lef" -maxdepth 1 -name '*.lef' -print -quit)"
STRIP_LEF="$(find "$STRIP_PACKAGE/lef" -maxdepth 1 -name '*.abstract.lef' -print -quit)"
[[ -n "$STRIP_LEF" ]] || STRIP_LEF="$(find "$STRIP_PACKAGE/lef" -maxdepth 1 -name '*.lef' -print -quit)"
PACKET_GDS="$PACKET_PACKAGE/gds/$PACKET_NAME.gds"
STRIP_GDS="$STRIP_PACKAGE/gds/$STRIP_NAME.gds"
AUDIT_DIR="${SPADMIC_LAYOUT_AUDIT_DIR:-$REPO_ROOT/TOP/docs/layout_audits/SPADMIC2_20260709_072331}"

python3 "$SCRIPT_DIR/audit_innovus_handoff.py" "$PACKET_PACKAGE"
PACKET_AUDIT_RC=$?
python3 "$SCRIPT_DIR/audit_innovus_handoff.py" "$STRIP_PACKAGE"
STRIP_AUDIT_RC=$?
if [[ "$PACKET_AUDIT_RC" -ne 0 || "$STRIP_AUDIT_RC" -ne 0 ]]; then
  echo "ERROR: handoff audit failed: packet=$PACKET_AUDIT_RC strip=$STRIP_AUDIT_RC" >&2
  exit 6
fi

python3 "$SCRIPT_DIR/gen_spadmic_digital_assembly_v1.py" \
  --packet-lef "$PACKET_LEF" --strip-lef "$STRIP_LEF" \
  --layout-audit-dir "$AUDIT_DIR" --out-dir "$GENERATED"
PLAN_RC=$?
if [[ "$PLAN_RC" -ne 0 ]]; then
  {
    echo "LABEL=SPADMIC_DIGITAL_ASSEMBLY_V1"
    echo "STATUS=BLOCKED"
    echo "RESULT=GEOMETRY_PREFLIGHT_FAILED"
    echo "PLAN_STATUS=$GENERATED/assembly_plan_status.rpt"
    echo "GEOMETRY_CONFLICTS=$GENERATED/assembly_geometry_conflicts.csv"
    echo "INNOVUS_STARTED=NO"
    echo "SIGNOFF_READY=NO"
  } | tee "$REPORTS/digital_assembly_status.rpt"
  exit 12
fi

STREAM_MAP="${SPADMIC_STREAMOUT_MAP_FILE:-/eda/pdk/xfab/xh018/cadence/v10_1/PDK/IC61/v10_1_1/TECH_XH018_HD_1131/pnr_streamout.map}"
for file in "$PACKET_LEF" "$STRIP_LEF" "$PACKET_GDS" "$STRIP_GDS" "$STREAM_MAP"; do
  if [[ ! -s "$file" ]]; then
    echo "ERROR: required assembly input missing: $file" >&2
    exit 6
  fi
done

{
  echo "RUN_ID=$RUN_ID"
  echo "REPO_ROOT=$REPO_ROOT"
  echo "BRANCH=$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null)"
  echo "HEAD=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null)"
  echo "PACKET_PACKAGE=$PACKET_PACKAGE"
  echo "STRIP_PACKAGE=$STRIP_PACKAGE"
  echo "PACKET_LEF=$PACKET_LEF"
  echo "STRIP_LEF=$STRIP_LEF"
  echo "PACKET_GDS=$PACKET_GDS"
  echo "STRIP_GDS=$STRIP_GDS"
  echo "STREAM_MAP=$STREAM_MAP"
  echo "AUDIT_DIR=$AUDIT_DIR"
} >"$RUN_ROOT/run_manifest.rpt"

if ! command -v innovus >/dev/null 2>&1; then
  echo "ERROR: innovus missing; source /eda/cadence/eda_2023-2024" >&2
  exit 3
fi

export SPADMIC_REPO_ROOT="$REPO_ROOT"
export SPADMIC_DA_RUN_ROOT="$RUN_ROOT"
export SPADMIC_DA_CONFIG_TCL="$GENERATED/assembly_config.tcl"
export SPADMIC_DA_NETLIST="$GENERATED/spadmic_digital_assembly_v1_p00_tx.v"
export SPADMIC_DA_SDC="$GENERATED/assembly_no_timing.sdc"
export SPADMIC_DA_PACKET_LEF="$PACKET_LEF"
export SPADMIC_DA_STRIP_LEF="$STRIP_LEF"
export SPADMIC_DA_PACKET_GDS="$PACKET_GDS"
export SPADMIC_DA_STRIP_GDS="$STRIP_GDS"
export SPADMIC_STREAMOUT_MAP_FILE="$STREAM_MAP"
export MPTDC_XH018_STACK="${MPTDC_XH018_STACK:-xx31}"
export MPTDC_STDCELL_FAMILY="${MPTDC_STDCELL_FAMILY:-JIHD}"
export MPTDC_PNR_ROUTE_LAYER_NAMES="${MPTDC_PNR_ROUTE_LAYER_NAMES:-MET1 MET2 MET3 METTP}"
export MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY="${MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY:-1}"

innovus -nowin -init "$SCRIPT_DIR/run_innovus_digital_assembly.tcl" \
  -log "$LOGS/innovus.log" >"$LOGS/innovus.stdout.log" 2>&1
INNOVUS_RC=$?
echo "INNOVUS_RC=$INNOVUS_RC"
cat "$REPORTS/digital_assembly_status.rpt" 2>/dev/null || echo "MISSING STATUS"
exit "$INNOVUS_RC"
