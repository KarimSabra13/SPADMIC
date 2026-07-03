#!/usr/bin/env bash
# =============================================================================
# SPADMIC matrix-top — Genus handoff for three-axis MPTDC frontend glue
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOP_SYN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TOP_ROOT="$(cd "$TOP_SYN_DIR/.." && pwd)"
REPO_ROOT="$(cd "$TOP_ROOT/.." && pwd)"
MPTDC_ROOT="$REPO_ROOT/MPTDC"
RUN_ID="${1:-tdc3_frontend_handoff_$(date +%Y%m%d_%H%M%S)}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
RUN_ROOT="$WORK_ROOT/genus/$RUN_ID"
HANDOFF_ROOT="${SPADMIC_TDC3_HANDOFF_ROOT:-$WORK_ROOT/handoff/genus/tdc3_frontend}"
COMMON_SDC="$TOP_SYN_DIR/constraints/matrix_top_ooc_common.sdc"
BLOCK_NAME="tdc3_frontend"
TOP_MODULE="spadmic_tdc3_frontend"

# Keep the matrix-top physical stack aligned with the current MPTDC product
# boundary. Override only for an explicitly reviewed technology audit.
export MPTDC_XH018_STACK="${MPTDC_XH018_STACK:-xx31}"
export MPTDC_STDCELL_FAMILY="${MPTDC_STDCELL_FAMILY:-JIHD}"
export MPTDC_PNR_ROUTE_LAYER_NAMES="${MPTDC_PNR_ROUTE_LAYER_NAMES:-MET1 MET2 MET3 METTP}"
export MPTDC_PNR_SIGNAL_TOP_LAYER="${MPTDC_PNR_SIGNAL_TOP_LAYER:-MET3}"
export MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER="${MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER:-METTP}"
export MPTDC_PNR_POWER_LAYER="${MPTDC_PNR_POWER_LAYER:-METTP}"
export MPTDC_PNR_PHASE_TOP_LAYER="${MPTDC_PNR_PHASE_TOP_LAYER:-METTP}"

if [[ -e "$RUN_ROOT" ]]; then
  echo "ERROR: run directory already exists: $RUN_ROOT" >&2
  exit 2
fi

if [[ -e "$HANDOFF_ROOT/$BLOCK_NAME.postsyn.v" || -e "$HANDOFF_ROOT/$BLOCK_NAME.postsyn.sdc" ]]; then
  if [[ "${SPADMIC_TDC3_HANDOFF_OVERWRITE:-0}" != "1" ]]; then
    echo "ERROR: handoff files already exist under: $HANDOFF_ROOT" >&2
    echo "Set SPADMIC_TDC3_HANDOFF_OVERWRITE=1 only after reviewing the old files." >&2
    exit 3
  fi
fi

mkdir -p "$RUN_ROOT/filelists" "$RUN_ROOT/logs"

{
  echo "RUN_ID=$RUN_ID"
  echo "DATE_UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "REPO_ROOT=$REPO_ROOT"
  echo "TOP_ROOT=$TOP_ROOT"
  echo "MPTDC_ROOT=$MPTDC_ROOT"
  echo "RUN_ROOT=$RUN_ROOT"
  echo "HANDOFF_ROOT=$HANDOFF_ROOT"
  echo "BLOCK_NAME=$BLOCK_NAME"
  echo "TOP_MODULE=$TOP_MODULE"
  echo "MPTDC_CORE_MODE=BLACK_BOX_ONLY"
  echo "MPTDC_XH018_STACK=$MPTDC_XH018_STACK"
  echo "MPTDC_STDCELL_FAMILY=$MPTDC_STDCELL_FAMILY"
  echo "MPTDC_PNR_ROUTE_LAYER_NAMES=$MPTDC_PNR_ROUTE_LAYER_NAMES"
  echo "MPTDC_PNR_SIGNAL_TOP_LAYER=$MPTDC_PNR_SIGNAL_TOP_LAYER"
  echo "MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER=$MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER"
  echo "MPTDC_PNR_POWER_LAYER=$MPTDC_PNR_POWER_LAYER"
  echo "BRANCH=$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || echo unknown)"
  echo "HEAD=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
  echo "STATUS_SHORT_BEGIN"
  git -C "$REPO_ROOT" status --short 2>/dev/null || true
  echo "STATUS_SHORT_END"
} > "$RUN_ROOT/run_manifest.txt"
git -C "$REPO_ROOT" status --short > "$RUN_ROOT/git_status_short.txt" 2>/dev/null || true

MPTDC_BB_FILELIST="$RUN_ROOT/filelists/mptdc_blackbox_abs.f"
TOP_GLUE_FILELIST="$RUN_ROOT/filelists/tdc3_frontend_abs.f"

{
  echo "$MPTDC_ROOT/rtl/pkg/mptdc_pkg.sv"
  echo "$TOP_SYN_DIR/blackboxes/mptdc_axis_core_blackbox.sv"
} > "$MPTDC_BB_FILELIST"

{
  echo "$TOP_ROOT/rtl/spadmic_ref_stop_qualifier.sv"
  echo "$TOP_ROOT/rtl/spadmic_tdc_axis_wrapper.sv"
  echo "$TOP_ROOT/rtl/spadmic_tdc3_frontend.sv"
} > "$TOP_GLUE_FILELIST"

while IFS= read -r file; do
  if [[ ! -f "$file" ]]; then
    echo "ERROR: missing source file in generated filelist: $file" >&2
    exit 4
  fi
done < "$MPTDC_BB_FILELIST"

while IFS= read -r file; do
  if [[ ! -f "$file" ]]; then
    echo "ERROR: missing source file in generated filelist: $file" >&2
    exit 4
  fi
done < "$TOP_GLUE_FILELIST"

if ! command -v genus >/dev/null 2>&1; then
  {
    echo "# SPADMIC TDC3 Frontend Genus Handoff"
    echo
    echo "- Run ID: \`$RUN_ID\`"
    echo "- Run directory: \`$RUN_ROOT\`"
    echo "- Handoff directory: \`$HANDOFF_ROOT\`"
    echo "- Block: \`$BLOCK_NAME\`"
    echo "- Top module: \`$TOP_MODULE\`"
    echo "- MPTDC core mode: \`BLACK_BOX_ONLY\`"
    echo "- Result: FAIL"
    echo "- First error: \`genus not found in PATH\`"
    echo
    echo "Source \`/eda/cadence/eda_2023-2024\` on the server before running this script."
  } | tee "$RUN_ROOT/SUMMARY.md"
  exit 5
fi

block_dir="$RUN_ROOT/$BLOCK_NAME"
mkdir -p "$block_dir/logs"
log="$block_dir/logs/genus.log"

echo "=== Genus OOC handoff: $BLOCK_NAME ($TOP_MODULE) ==="
set +e
SPADMIC_REPO_ROOT="$REPO_ROOT" \
SPADMIC_TOP_ROOT="$TOP_ROOT" \
SPADMIC_MPTDC_ROOT="$MPTDC_ROOT" \
GENUS_RUN_DIR="$block_dir" \
GENUS_TOP_MODULE="$TOP_MODULE" \
GENUS_BLOCK_NAME="$BLOCK_NAME" \
GENUS_MPTDC_FILELIST="$MPTDC_BB_FILELIST" \
GENUS_TOP_FILELIST="$TOP_GLUE_FILELIST" \
GENUS_COMMON_SDC="$COMMON_SDC" \
  genus -files "$SCRIPT_DIR/run_genus_matrix_block.tcl" -log "$log" > "$block_dir/logs/genus.stdout.log" 2>&1
rc=$?
set -e

if [[ "$rc" -ne 0 ]]; then
  tail -120 "$block_dir/logs/genus.stdout.log" > "$block_dir/logs/failure.tail" || true
  {
    echo "# SPADMIC TDC3 Frontend Genus Handoff"
    echo
    echo "- Run ID: \`$RUN_ID\`"
    echo "- Run directory: \`$RUN_ROOT\`"
    echo "- Handoff directory: \`$HANDOFF_ROOT\`"
    echo "- Block: \`$BLOCK_NAME\`"
    echo "- Top module: \`$TOP_MODULE\`"
    echo "- MPTDC core mode: \`BLACK_BOX_ONLY\`"
    echo "- Result: FAIL"
    echo "- Genus exit code: \`$rc\`"
    echo "- Failure tail: \`$BLOCK_NAME/logs/failure.tail\`"
    echo
    echo "No handoff files were copied."
  } | tee "$RUN_ROOT/SUMMARY.md"
  exit "$rc"
fi

mkdir -p "$HANDOFF_ROOT"
cp "$block_dir/outputs/$BLOCK_NAME.postsyn.v" "$HANDOFF_ROOT/$BLOCK_NAME.postsyn.v"
cp "$block_dir/outputs/$BLOCK_NAME.postsyn.sdc" "$HANDOFF_ROOT/$BLOCK_NAME.postsyn.sdc"

{
  echo "RUN_ID=$RUN_ID"
  echo "GENUS_ROOT=$RUN_ROOT"
  echo "BLOCK_RUN_ROOT=$block_dir"
  echo "HANDOFF_ROOT=$HANDOFF_ROOT"
  echo "BLOCK_NAME=$BLOCK_NAME"
  echo "TOP_MODULE=$TOP_MODULE"
  echo "MPTDC_CORE_MODE=BLACK_BOX_ONLY"
  echo "MPTDC_AXIS_CORE_EXTERNAL_NETLIST_REQUIRED=1"
  echo "MPTDC_AXIS_CORE_NOTE=Use the separately handed off mptdc_axis_core physical macro/netlist; this handoff only contains SPADMIC glue around three axes."
  echo "HEAD=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
  echo "DATE_UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} > "$HANDOFF_ROOT/HANDOFF_MANIFEST.txt"

{
  echo "# SPADMIC TDC3 Frontend Genus Handoff"
  echo
  echo "- Run ID: \`$RUN_ID\`"
  echo "- Run directory: \`$RUN_ROOT\`"
  echo "- Handoff directory: \`$HANDOFF_ROOT\`"
  echo "- Block: \`$BLOCK_NAME\`"
  echo "- Top module: \`$TOP_MODULE\`"
  echo "- MPTDC core mode: \`BLACK_BOX_ONLY\`"
  echo "- Result: PASS"
  echo
  echo "## Handoff Files"
  echo
  echo "- \`$HANDOFF_ROOT/$BLOCK_NAME.postsyn.v\`"
  echo "- \`$HANDOFF_ROOT/$BLOCK_NAME.postsyn.sdc\`"
  echo "- \`$HANDOFF_ROOT/HANDOFF_MANIFEST.txt\`"
  echo
  echo "This run does not synthesize or implement MPTDC internals. The final top must"
  echo "link three external \`mptdc_axis_core\` macro/netlist instances."
  echo
  echo "This is not final timing closure, not MMMC, and not signoff."
} | tee "$RUN_ROOT/SUMMARY.md"

exit 0
