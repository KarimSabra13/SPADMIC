#!/usr/bin/env bash
# =============================================================================
# SPADMIC TOP -- Innovus route/DRC for TX egress connected fixed-leaf assembly
# =============================================================================
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  TOP/pnr/scripts/run_innovus_tx_egress_connected_assembly_route.sh <CONNECTED_ASSEMBLY_ROOT> <GENUS_RUN_ID> [RUN_ID]

This imports the Genus glue netlist for spadmic_tx_egress_leaf_assembly,
loads the four fixed TX leaf LEFs, applies the validated fixed-leaf placement,
places top pins provisionally, places/routes the glue, and runs Innovus DRC.

It is a routed typical-only assembly feasibility gate. PG hookup, PVS, LVS, PEX,
MMMC, and foundry signoff remain deferred.
USAGE
}

if [[ $# -lt 2 || $# -gt 3 ]]; then
  usage >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TOP_ROOT="$(cd "$PNR_ROOT/.." && pwd)"
REPO_ROOT="$(cd "$TOP_ROOT/.." && pwd)"

CONNECTED_ROOT="$1"
GENUS_RUN_ID="$2"
RUN_ID="${3:-innovus_tx_egress_connected_assembly_route_$(date +%Y%m%d_%H%M)}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
GENUS_ROOT="$WORK_ROOT/genus/$GENUS_RUN_ID"
GENUS_BLOCK_ROOT="$GENUS_ROOT/tx_egress_connected_assembly"
RUN_ROOT="$WORK_ROOT/innovus/$RUN_ID"

TOP_MODULE="spadmic_tx_egress_leaf_assembly"
NETLIST="$GENUS_BLOCK_ROOT/outputs/tx_egress_connected_assembly.postsyn.v"
SDC="$GENUS_BLOCK_ROOT/outputs/tx_egress_connected_assembly.postsyn.sdc"
CONNECTED_STATUS="$CONNECTED_ROOT/tx_egress_leaf_connected_assembly_status.rpt"
GENUS_STATUS="$GENUS_ROOT/tx_egress_connected_assembly_genus_status.rpt"

export MPTDC_XH018_STACK="${MPTDC_XH018_STACK:-xx31}"
export MPTDC_STDCELL_FAMILY="${MPTDC_STDCELL_FAMILY:-JIHD}"
export MPTDC_PNR_ROUTE_LAYER_NAMES="${MPTDC_PNR_ROUTE_LAYER_NAMES:-MET1 MET2 MET3 METTP}"
export MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY="${MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY:-1}"

fail_summary() {
  local rc="$1"
  local reason="$2"
  mkdir -p "$RUN_ROOT/reports"
  {
    echo "# TX Egress Connected Assembly Innovus Route"
    echo
    echo "- Run ID: \`$RUN_ID\`"
    echo "- Run root: \`$RUN_ROOT\`"
    echo "- Connected root: \`$CONNECTED_ROOT\`"
    echo "- Genus run ID: \`$GENUS_RUN_ID\`"
    echo "- Result: \`FAIL\`"
    echo "- First error: \`$reason\`"
    echo
    echo "This wrapper did not claim signoff."
  } > "$RUN_ROOT/SUMMARY.md"
  cat "$RUN_ROOT/SUMMARY.md"
  echo "TX_CONNECTED_ROUTE_RC=$rc"
  echo "TX_CONNECTED_ROUTE_RUN_ID=$RUN_ID"
  echo "TX_CONNECTED_ROUTE_ROOT=$RUN_ROOT"
  exit "$rc"
}

[[ -d "$CONNECTED_ROOT" ]] || fail_summary 2 "connected assembly root missing: $CONNECTED_ROOT"
[[ -s "$CONNECTED_STATUS" ]] || fail_summary 2 "connected assembly status missing: $CONNECTED_STATUS"
grep -qx 'STATUS=PASS' "$CONNECTED_STATUS" || fail_summary 2 "connected assembly status is not PASS"
[[ -d "$GENUS_ROOT" ]] || fail_summary 2 "Genus root missing: $GENUS_ROOT"
[[ -s "$GENUS_STATUS" ]] || fail_summary 2 "Genus status missing: $GENUS_STATUS"
grep -qx 'STATUS=PASS' "$GENUS_STATUS" || fail_summary 2 "Genus status is not PASS"
[[ -s "$NETLIST" ]] || fail_summary 2 "Genus netlist missing: $NETLIST"
[[ -s "$SDC" ]] || fail_summary 2 "Genus SDC missing: $SDC"
[[ ! -e "$RUN_ROOT" ]] || fail_summary 2 "run directory already exists: $RUN_ROOT"

mkdir -p "$RUN_ROOT"/{logs,reports,outputs,checkpoints,generated}

if ! command -v innovus >/dev/null 2>&1; then
  fail_summary 3 "innovus not found in PATH; source /eda/cadence/eda_2023-2024"
fi

{
  echo "RUN_ID=$RUN_ID"
  echo "DATE_UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "REPO_ROOT=$REPO_ROOT"
  echo "TOP_ROOT=$TOP_ROOT"
  echo "RUN_ROOT=$RUN_ROOT"
  echo "CONNECTED_ROOT=$CONNECTED_ROOT"
  echo "GENUS_RUN_ID=$GENUS_RUN_ID"
  echo "GENUS_ROOT=$GENUS_ROOT"
  echo "TOP_MODULE=$TOP_MODULE"
  echo "NETLIST=$NETLIST"
  echo "SDC=$SDC"
  echo "MPTDC_XH018_STACK=$MPTDC_XH018_STACK"
  echo "MPTDC_STDCELL_FAMILY=$MPTDC_STDCELL_FAMILY"
  echo "MPTDC_PNR_ROUTE_LAYER_NAMES=$MPTDC_PNR_ROUTE_LAYER_NAMES"
  echo "BRANCH=$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || echo unknown)"
  echo "HEAD=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
  echo "STATUS_SHORT_BEGIN"
  git -C "$REPO_ROOT" status --short 2>/dev/null || true
  echo "STATUS_SHORT_END"
} > "$RUN_ROOT/run_manifest.txt"
git -C "$REPO_ROOT" status --short > "$RUN_ROOT/git_status_short.txt" 2>/dev/null || true

export SPADMIC_REPO_ROOT="$REPO_ROOT"
export SPADMIC_TXASM_ROUTE_RUN_ROOT="$RUN_ROOT"
export SPADMIC_TXASM_CONNECTED_ROOT="$CONNECTED_ROOT"
export SPADMIC_TXASM_GENUS_ROOT="$GENUS_ROOT"
export SPADMIC_TXASM_NETLIST="$NETLIST"
export SPADMIC_TXASM_SDC="$SDC"
export SPADMIC_TXASM_TOP_MODULE="$TOP_MODULE"

set +e
innovus -nowin -init "$SCRIPT_DIR/run_innovus_tx_egress_connected_assembly_route.tcl" \
  -log "$RUN_ROOT/logs/innovus.log" \
  > "$RUN_ROOT/logs/innovus.stdout.log" 2>&1
innovus_rc=$?
set -e

status_rpt="$RUN_ROOT/reports/tx_egress_connected_assembly_route_status.rpt"
if [[ ! -s "$status_rpt" ]]; then
  {
    echo "LABEL=TX_EGRESS_CONNECTED_ASSEMBLY_ROUTE"
    echo "STATUS=FAIL"
    echo "RESULT=FAILED_BEFORE_STATUS"
    echo "SIGNOFF_READY=NO"
    echo "FIRST_ERROR_HINT=Inspect $RUN_ROOT/logs/innovus.stdout.log"
  } > "$status_rpt"
fi

route_result="$(awk -F= '$1=="RESULT"{print $2}' "$status_rpt" | tail -1)"
route_status="$(awk -F= '$1=="STATUS"{print $2}' "$status_rpt" | tail -1)"

{
  echo "# TX Egress Connected Assembly Innovus Route"
  echo
  echo "- Run ID: \`$RUN_ID\`"
  echo "- Run root: \`$RUN_ROOT\`"
  echo "- Connected root: \`$CONNECTED_ROOT\`"
  echo "- Genus run ID: \`$GENUS_RUN_ID\`"
  echo "- Repo head: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)\`"
  echo "- Innovus return code: \`$innovus_rc\`"
  echo "- Status: \`${route_status:-UNKNOWN}\`"
  echo "- Result: \`${route_result:-UNKNOWN}\`"
  echo "- Status report: \`$status_rpt\`"
  echo
  echo "This is a routed typical-only TX assembly feasibility gate. PG hookup, PVS,"
  echo "LVS, PEX, MMMC, and foundry signoff remain deferred."
} > "$RUN_ROOT/SUMMARY.md"

cat "$RUN_ROOT/SUMMARY.md"
echo "TX_CONNECTED_ROUTE_RC=$innovus_rc"
echo "TX_CONNECTED_ROUTE_RUN_ID=$RUN_ID"
echo "TX_CONNECTED_ROUTE_ROOT=$RUN_ROOT"
echo "TX_CONNECTED_ROUTE_STATUS=$status_rpt"

exit "$innovus_rc"
