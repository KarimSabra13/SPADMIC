#!/usr/bin/env bash
# =============================================================================
# SPADMIC matrix-top — staged Innovus OOC collateral gate
# =============================================================================
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  TOP/pnr/scripts/server_run_innovus_matrix_ooc.sh <RUN_ID> <GENUS_RUN_ID>

Optional environment:
  SPADMIC_WORK_ROOT                 Default: /sim/ksabra/SPADMIC_work
  SPADMIC_INNOVUS_EXCLUDE_DDR16     Default: 0
  SPADMIC_INNOVUS_OOC_BLOCKS        Override block list, space-separated.

This wrapper validates per-block Genus OOC collateral and creates per-block
Innovus run directories in connectivity-first order.  It does not yet promote
the blocks to place/route; that requires the next reviewed TOP Innovus import
template.
USAGE
}

if [[ $# -lt 2 || $# -gt 2 ]]; then
  usage >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TOP_ROOT="$(cd "$PNR_ROOT/.." && pwd)"
REPO_ROOT="$(cd "$TOP_ROOT/.." && pwd)"
RUN_ID="$1"
GENUS_RUN_ID="$2"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
RUN_ROOT="$WORK_ROOT/innovus/$RUN_ID"
GENUS_ROOT="$WORK_ROOT/genus/$GENUS_RUN_ID"

export MPTDC_XH018_STACK="${MPTDC_XH018_STACK:-xx31}"
export MPTDC_STDCELL_FAMILY="${MPTDC_STDCELL_FAMILY:-JIHD}"
export MPTDC_PNR_ROUTE_LAYER_NAMES="${MPTDC_PNR_ROUTE_LAYER_NAMES:-MET1 MET2 MET3 METTP}"
export MPTDC_PNR_SIGNAL_TOP_LAYER="${MPTDC_PNR_SIGNAL_TOP_LAYER:-MET3}"
export MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER="${MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER:-METTP}"

DEFAULT_BLOCKS=(
  matrix_reset_ctrl
  or64_tree
  position_snapshot
  matrix_cfg_ctrl
  event_coordinator
  event_bundle_tx
  tx_egress_cluster
  output_fifo
  matrix_top_csr
  i2c_csr_bridge
  i2c_slave
  ddr16_pairer
  ddrs2_adapter
)

DDR16_INCLUDED=1
if [[ "${SPADMIC_INNOVUS_EXCLUDE_DDR16:-0}" == "1" ]]; then
  DDR16_INCLUDED=0
  TMP_BLOCKS=()
  for block in "${DEFAULT_BLOCKS[@]}"; do
    if [[ "$block" != "ddr16_pairer" && "$block" != "ddrs2_adapter" ]]; then
      TMP_BLOCKS+=("$block")
    fi
  done
  DEFAULT_BLOCKS=("${TMP_BLOCKS[@]}")
fi

if [[ -n "${SPADMIC_INNOVUS_OOC_BLOCKS:-}" ]]; then
  # shellcheck disable=SC2206
  BLOCKS=($SPADMIC_INNOVUS_OOC_BLOCKS)
else
  BLOCKS=("${DEFAULT_BLOCKS[@]}")
fi

if [[ -e "$RUN_ROOT" ]]; then
  echo "ERROR: run directory already exists: $RUN_ROOT" >&2
  exit 2
fi
mkdir -p "$RUN_ROOT/logs" "$RUN_ROOT/reports" "$RUN_ROOT/blocks"

{
  echo "RUN_ID=$RUN_ID"
  echo "DATE_UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "REPO_ROOT=$REPO_ROOT"
  echo "RUN_ROOT=$RUN_ROOT"
  echo "GENUS_RUN_ID=$GENUS_RUN_ID"
  echo "GENUS_ROOT=$GENUS_ROOT"
  echo "MPTDC_XH018_STACK=$MPTDC_XH018_STACK"
  echo "MPTDC_STDCELL_FAMILY=$MPTDC_STDCELL_FAMILY"
  echo "MPTDC_PNR_ROUTE_LAYER_NAMES=$MPTDC_PNR_ROUTE_LAYER_NAMES"
  echo "MPTDC_PNR_SIGNAL_TOP_LAYER=$MPTDC_PNR_SIGNAL_TOP_LAYER"
  echo "MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER=$MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER"
  echo "SPADMIC_INNOVUS_EXCLUDE_DDR16=${SPADMIC_INNOVUS_EXCLUDE_DDR16:-0}"
  echo "DDR16_INCLUDED=$DDR16_INCLUDED"
  echo "BRANCH=$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || echo unknown)"
  echo "HEAD=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
  echo "STATUS_SHORT_BEGIN"
  git -C "$REPO_ROOT" status --short 2>/dev/null || true
  echo "STATUS_SHORT_END"
} > "$RUN_ROOT/run_manifest.txt"
git -C "$REPO_ROOT" status --short > "$RUN_ROOT/git_status_short.txt" 2>/dev/null || true

{
  echo "block,netlist,sdc,summary,status,notes"
} > "$RUN_ROOT/reports/ooc_collateral_manifest.csv"

if [[ ! -d "$GENUS_ROOT" ]]; then
  {
    echo "# SPADMIC Matrix TOP Innovus OOC Collateral Gate"
    echo
    echo "- Run ID: \`$RUN_ID\`"
    echo "- Genus run ID: \`$GENUS_RUN_ID\`"
    echo "- Genus root: \`$GENUS_ROOT\`"
    echo "- Result: FAIL"
    echo "- First error: \`Genus run directory not found\`"
  } > "$RUN_ROOT/SUMMARY.md"
  cat "$RUN_ROOT/SUMMARY.md"
  exit 6
fi

missing=0
for block in "${BLOCKS[@]}"; do
  block_dir="$RUN_ROOT/blocks/$block"
  mkdir -p "$block_dir/logs" "$block_dir/reports"
  netlist="$GENUS_ROOT/$block/outputs/$block.postsyn.v"
  sdc="$GENUS_ROOT/$block/outputs/$block.postsyn.sdc"
  summary="$GENUS_ROOT/$block/SUMMARY.md"
  status="READY"
  notes="ready_for_next_import_template"
  if [[ ! -f "$netlist" ]]; then
    status="MISSING"
    notes="missing_netlist"
    missing=$((missing + 1))
  fi
  if [[ ! -f "$sdc" ]]; then
    status="MISSING"
    if [[ "$notes" == "ready_for_next_import_template" ]]; then
      notes="missing_sdc"
    else
      notes="${notes}+missing_sdc"
    fi
    missing=$((missing + 1))
  fi
  if [[ ! -f "$summary" ]]; then
    if [[ "$notes" == "ready_for_next_import_template" ]]; then
      notes="missing_genus_summary"
    else
      notes="${notes}+missing_genus_summary"
    fi
  fi
  printf '%s,%s,%s,%s,%s,%s\n' "$block" "$netlist" "$sdc" "$summary" "$status" "$notes" \
    >> "$RUN_ROOT/reports/ooc_collateral_manifest.csv"
  {
    echo "# Matrix TOP Innovus OOC Block"
    echo
    echo "- Block: \`$block\`"
    echo "- Genus netlist: \`$netlist\`"
    echo "- Genus SDC: \`$sdc\`"
    echo "- Genus summary: \`$summary\`"
    echo "- Collateral status: \`$status\`"
    echo "- Notes: \`$notes\`"
    echo
    echo "This block has not been imported into Innovus by this wrapper."
  } > "$block_dir/SUMMARY.md"
done

{
  echo "# SPADMIC Matrix TOP Innovus OOC Collateral Gate"
  echo
  echo "- Run ID: \`$RUN_ID\`"
  echo "- Run directory: \`$RUN_ROOT\`"
  echo "- Genus run ID: \`$GENUS_RUN_ID\`"
  echo "- Genus root: \`$GENUS_ROOT\`"
  echo "- Branch: \`$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || echo unknown)\`"
  echo "- Commit: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)\`"
  echo "- XH018 stack: \`$MPTDC_XH018_STACK\`"
  echo "- Standard-cell family: \`$MPTDC_STDCELL_FAMILY\`"
  echo "- Route layers: \`$MPTDC_PNR_ROUTE_LAYER_NAMES\`"
  echo "- Ordinary signal top layer: \`$MPTDC_PNR_SIGNAL_TOP_LAYER\`"
  echo "- DDR16 included: \`$DDR16_INCLUDED\`"
  echo "- Signoff: non-signoff OOC collateral gate"
  echo
  echo "## Connectivity-First Blocks"
  echo
  for block in "${BLOCKS[@]}"; do
    echo "- \`$block\`"
  done
  echo
  echo "## Result"
  echo
  if [[ "$missing" -eq 0 ]]; then
    echo "- Result: READY_FOR_NEXT_IMPORT_TEMPLATE"
    echo "- Missing required collateral count: 0"
    echo
    echo "Per-block run directories were created. The next reviewed patch should add"
    echo "the Innovus import/place/preCTS template rather than copying MPTDC-specific"
    echo "RO/PD signoff scripts blindly."
  else
    echo "- Result: FAIL"
    echo "- Missing required collateral count: $missing"
    echo "- See \`reports/ooc_collateral_manifest.csv\`."
  fi
  echo
  echo "This wrapper does not run placement, route, CTS, DRC/LVS, PEX, MMMC, or signoff."
} > "$RUN_ROOT/SUMMARY.md"

cat "$RUN_ROOT/SUMMARY.md"

if [[ "$missing" -eq 0 ]]; then
  exit 4
fi
exit 7
