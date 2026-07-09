#!/usr/bin/env bash
# =============================================================================
# SPADMIC TOP -- TX egress fixed-leaf assembly Innovus smoke wrapper
# =============================================================================
set -uo pipefail

usage() {
  cat <<'USAGE'
Usage:
  TOP/pnr/scripts/run_innovus_tx_egress_leaf_assembly_smoke.sh <ASSEMBLY_PLAN_ROOT> [RUN_ID]

This is an Innovus import/place smoke test for the fixed-leaf TX egress
assembly plan. It generates a macro-only Verilog top, loads the four leaf LEFs,
places the four leaf instances fixed from the plan Tcl, writes reports, and
stops. It does not route, hook PG, run PVS/LVS/PEX, or claim MMMC/signoff.
USAGE
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  usage >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TOP_ROOT="$(cd "$PNR_ROOT/.." && pwd)"
REPO_ROOT="$(cd "$TOP_ROOT/.." && pwd)"

PLAN_ROOT="$1"
RUN_ID="${2:-innovus_tx_egress_leaf_assembly_smoke_$(date +%Y%m%d_%H%M)}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
RUN_ROOT="$WORK_ROOT/innovus/$RUN_ID"

export MPTDC_XH018_STACK="${MPTDC_XH018_STACK:-xx31}"
export MPTDC_STDCELL_FAMILY="${MPTDC_STDCELL_FAMILY:-JIHD}"
export MPTDC_PNR_ROUTE_LAYER_NAMES="${MPTDC_PNR_ROUTE_LAYER_NAMES:-MET1 MET2 MET3 METTP}"
export MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY="${MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY:-1}"

if [ ! -d "$PLAN_ROOT" ]; then
  echo "ERROR: assembly plan root missing: $PLAN_ROOT" >&2
  exit 2
fi

if [ ! -s "$PLAN_ROOT/tx_egress_leaf_assembly_status.rpt" ]; then
  echo "ERROR: assembly plan status missing: $PLAN_ROOT/tx_egress_leaf_assembly_status.rpt" >&2
  exit 2
fi

if [ ! -s "$PLAN_ROOT/tx_egress_leaf_assembly_place.tcl" ]; then
  echo "ERROR: assembly placement Tcl missing: $PLAN_ROOT/tx_egress_leaf_assembly_place.tcl" >&2
  exit 2
fi

if [ -e "$RUN_ROOT" ]; then
  echo "ERROR: run directory already exists: $RUN_ROOT" >&2
  exit 2
fi

mkdir -p "$RUN_ROOT"/{generated,logs,outputs,reports,checkpoints}

python3 "$SCRIPT_DIR/gen_tx_egress_leaf_assembly_smoke.py" \
  --plan-root "$PLAN_ROOT" \
  --out-dir "$RUN_ROOT/generated"
gen_rc=$?

if [ "$gen_rc" -ne 0 ]; then
  echo "ASSEMBLY_SMOKE_RC=$gen_rc"
  echo "ASSEMBLY_SMOKE_RUN_ID=$RUN_ID"
  echo "ASSEMBLY_SMOKE_ROOT=$RUN_ROOT"
  exit "$gen_rc"
fi

if ! command -v innovus >/dev/null 2>&1; then
  echo "ERROR: innovus command not found; source the Cadence environment first" >&2
  echo "ASSEMBLY_SMOKE_RC=3"
  echo "ASSEMBLY_SMOKE_RUN_ID=$RUN_ID"
  echo "ASSEMBLY_SMOKE_ROOT=$RUN_ROOT"
  exit 3
fi

export SPADMIC_REPO_ROOT="$REPO_ROOT"
export SPADMIC_TXASM_RUN_ROOT="$RUN_ROOT"
export SPADMIC_TXASM_PLAN_ROOT="$PLAN_ROOT"
export SPADMIC_TXASM_NETLIST="$RUN_ROOT/generated/tx_egress_leaf_assembly_smoke.v"
export SPADMIC_TXASM_TOP_MODULE="spadmic_tx_egress_leaf_assembly_smoke"

set +e
innovus -nowin -init "$SCRIPT_DIR/run_innovus_tx_egress_leaf_assembly_smoke.tcl" \
  -log "$RUN_ROOT/logs/innovus.log" \
  > "$RUN_ROOT/logs/innovus.stdout.log" 2>&1
innovus_rc=$?
set -u

if [ ! -s "$RUN_ROOT/reports/tx_egress_leaf_assembly_smoke_status.rpt" ]; then
  {
    echo "RESULT=FAILED_BEFORE_STATUS"
    echo "SIGNOFF_READY=NO"
    echo "ROUTE_STATUS=NOT_RUN"
    echo "PG_CONNECTIVITY_STATUS=DEFERRED_TOP_LEVEL_HOOKUP"
    echo "PVS_STATUS=DEFERRED"
    echo "LVS_STATUS=DEFERRED"
    echo "PEX_STATUS=DEFERRED"
    echo "MMMC_STATUS=DEFERRED"
    echo "FIRST_ERROR_HINT=Inspect $RUN_ROOT/logs/innovus.stdout.log"
  } > "$RUN_ROOT/reports/tx_egress_leaf_assembly_smoke_status.rpt"
fi

{
  echo "# TX Egress Fixed-Leaf Assembly Innovus Smoke"
  echo
  echo "- Run ID: \`$RUN_ID\`"
  echo "- Run root: \`$RUN_ROOT\`"
  echo "- Plan root: \`$PLAN_ROOT\`"
  echo "- Repo head: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)\`"
  echo "- Innovus return code: \`$innovus_rc\`"
  echo
  if [ -s "$RUN_ROOT/reports/tx_egress_leaf_assembly_smoke_status.rpt" ]; then
    echo "## Status"
    echo
    sed 's/^/- `/' "$RUN_ROOT/reports/tx_egress_leaf_assembly_smoke_status.rpt" | sed 's/$/`/'
  else
    echo "## Status"
    echo
    echo "- Missing status report. Inspect logs."
  fi
  echo
  echo "This is a smoke import/place run only. Route, PG hookup, PVS, LVS, PEX, and MMMC are deferred."
} > "$RUN_ROOT/SUMMARY.md"

cat "$RUN_ROOT/SUMMARY.md"

echo "ASSEMBLY_SMOKE_RC=$innovus_rc"
echo "ASSEMBLY_SMOKE_RUN_ID=$RUN_ID"
echo "ASSEMBLY_SMOKE_ROOT=$RUN_ROOT"
if [ -s "$RUN_ROOT/reports/tx_egress_leaf_assembly_smoke_status.rpt" ]; then
  echo "ASSEMBLY_SMOKE_STATUS=$RUN_ROOT/reports/tx_egress_leaf_assembly_smoke_status.rpt"
fi

exit "$innovus_rc"
