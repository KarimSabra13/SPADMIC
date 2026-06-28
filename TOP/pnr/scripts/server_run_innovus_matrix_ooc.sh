#!/usr/bin/env bash
# =============================================================================
# SPADMIC matrix-top — server Innovus OOC placeholder wrapper
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TOP_ROOT="$(cd "$PNR_ROOT/.." && pwd)"
REPO_ROOT="$(cd "$TOP_ROOT/.." && pwd)"
RUN_ID="${1:-matrix_top_innovus_ooc_$(date +%Y%m%d_%H%M%S)}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
RUN_ROOT="$WORK_ROOT/innovus/$RUN_ID"

BLOCKS=(or64_tree matrix_reset_ctrl matrix_cfg_ctrl output_fifo_bundle position_path control_csr)

if [[ -e "$RUN_ROOT" ]]; then
  echo "ERROR: run directory already exists: $RUN_ROOT" >&2
  exit 2
fi
mkdir -p "$RUN_ROOT"

{
  echo "# SPADMIC Matrix TOP Innovus OOC Plan Run"
  echo
  echo "- Run ID: \`$RUN_ID\`"
  echo "- Run directory: \`$RUN_ROOT\`"
  echo "- Branch: \`$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || echo unknown)\`"
  echo "- Commit: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)\`"
  echo "- Status: planning wrapper only"
  echo
  echo "## Blocks"
  for block in "${BLOCKS[@]}"; do
    echo "- \`$block\`"
  done
} > "$RUN_ROOT/SUMMARY.md"

if ! command -v innovus >/dev/null 2>&1; then
  {
    echo
    echo "## Result"
    echo
    echo "- Result: FAIL"
    echo "- First error: \`innovus not found in PATH\`"
    echo "- No OOC Innovus execution was performed."
  } >> "$RUN_ROOT/SUMMARY.md"
  cat "$RUN_ROOT/SUMMARY.md"
  exit 3
fi

{
  echo
  echo "## Result"
  echo
  echo "- Result: DEFERRED"
  echo "- Innovus is available, but block-specific DEF/netlist/MMMC handoff must be supplied by the Genus and top floorplan runs before automated OOC place/route is meaningful."
  echo "- This wrapper intentionally does not fabricate a pass."
} >> "$RUN_ROOT/SUMMARY.md"

cat "$RUN_ROOT/SUMMARY.md"
exit 4
