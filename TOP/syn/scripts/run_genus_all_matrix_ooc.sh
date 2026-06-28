#!/usr/bin/env bash
# =============================================================================
# SPADMIC matrix-top — server Genus OOC runner
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOP_SYN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TOP_ROOT="$(cd "$TOP_SYN_DIR/.." && pwd)"
REPO_ROOT="$(cd "$TOP_ROOT/.." && pwd)"
MPTDC_ROOT="$REPO_ROOT/MPTDC"
RUN_ID="${1:-matrix_top_genus_$(date +%Y%m%d_%H%M%S)}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
RUN_ROOT="$WORK_ROOT/genus/$RUN_ID"
COMMON_SDC="$TOP_SYN_DIR/constraints/matrix_top_ooc_common.sdc"

BLOCKS=(
  "position_snapshot:spadmic_position_snapshot_packetizer"
  "output_fifo:spadmic_output_fifo"
  "event_bundle_tx:spadmic_event_bundle_tx"
  "or64_tree:spadmic_matrix_or_tree"
  "matrix_reset_ctrl:spadmic_matrix_reset_ctrl"
  "matrix_cfg_ctrl:spadmic_matrix_cfg_ctrl"
  "ddr16_pairer:spadmic_ddr16_tx_pairer"
  "event_coordinator:spadmic_event_coordinator"
  "matrix_top_csr:spadmic_matrix_top_csr"
  "i2c_csr_bridge:spadmic_i2c_csr_bridge"
  "i2c_slave:spadmic_i2c_slave"
  "spadmic_top_matrix_v1:spadmic_top_matrix_v1"
)

if [[ -e "$RUN_ROOT" ]]; then
  echo "ERROR: run directory already exists: $RUN_ROOT" >&2
  exit 2
fi

mkdir -p "$RUN_ROOT/filelists" "$RUN_ROOT/logs"

{
  echo "RUN_ID=$RUN_ID"
  echo "DATE_UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "REPO_ROOT=$REPO_ROOT"
  echo "TOP_ROOT=$TOP_ROOT"
  echo "MPTDC_ROOT=$MPTDC_ROOT"
  echo "RUN_ROOT=$RUN_ROOT"
  echo "BRANCH=$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || echo unknown)"
  echo "HEAD=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
  echo "STATUS_SHORT_BEGIN"
  git -C "$REPO_ROOT" status --short 2>/dev/null || true
  echo "STATUS_SHORT_END"
} > "$RUN_ROOT/run_manifest.txt"
git -C "$REPO_ROOT" status --short > "$RUN_ROOT/git_status_short.txt" 2>/dev/null || true

if ! command -v genus >/dev/null 2>&1; then
  {
    echo "# SPADMIC Matrix TOP Genus OOC Run"
    echo
    echo "- Run ID: \`$RUN_ID\`"
    echo "- Run directory: \`$RUN_ROOT\`"
    echo "- Branch: \`$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || echo unknown)\`"
    echo "- Commit: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)\`"
    echo "- Result: FAIL"
    echo "- First error: \`genus not found in PATH\`"
    echo
    echo "Source \`/eda/cadence/eda_2023-2024\` on the server before running this script."
    echo
    echo "This is not a synthesis result and does not claim Genus execution."
  } | tee "$RUN_ROOT/SUMMARY.md"
  exit 3
fi

source "$TOP_ROOT/scripts/sim/resolve_flist.sh"
resolve_flist "$MPTDC_ROOT" "$MPTDC_ROOT/rtl/filelist.f" "$RUN_ROOT/filelists/mptdc_abs.f"
resolve_flist "$TOP_ROOT" "$TOP_ROOT/filelist.f" "$RUN_ROOT/filelists/top_abs.f"

PASS=0
FAIL=0
FAILED=()

{
  echo "# SPADMIC Matrix TOP Genus OOC Run"
  echo
  echo "- Run ID: \`$RUN_ID\`"
  echo "- Run directory: \`$RUN_ROOT\`"
  echo "- Branch: \`$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || echo unknown)\`"
  echo "- Commit: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)\`"
  echo "- Signoff: non-signoff, typical-only feasibility"
  echo
  echo "## Blocks"
  echo
  echo "| Block | Top module | Result |"
  echo "| --- | --- | --- |"
} > "$RUN_ROOT/SUMMARY.md"

for item in "${BLOCKS[@]}"; do
  block="${item%%:*}"
  top="${item##*:}"
  block_dir="$RUN_ROOT/$block"
  mkdir -p "$block_dir/logs"
  log="$block_dir/logs/genus.log"
  echo "=== Genus OOC: $block ($top) ==="
  set +e
  SPADMIC_REPO_ROOT="$REPO_ROOT" \
  SPADMIC_TOP_ROOT="$TOP_ROOT" \
  SPADMIC_MPTDC_ROOT="$MPTDC_ROOT" \
  GENUS_RUN_DIR="$block_dir" \
  GENUS_TOP_MODULE="$top" \
  GENUS_BLOCK_NAME="$block" \
  GENUS_MPTDC_FILELIST="$RUN_ROOT/filelists/mptdc_abs.f" \
  GENUS_TOP_FILELIST="$RUN_ROOT/filelists/top_abs.f" \
  GENUS_COMMON_SDC="$COMMON_SDC" \
    genus -files "$SCRIPT_DIR/run_genus_matrix_block.tcl" -log "$log" > "$block_dir/logs/genus.stdout.log" 2>&1
  rc=$?
  set -e
  if [[ "$rc" -eq 0 ]]; then
    PASS=$((PASS + 1))
    echo "| \`$block\` | \`$top\` | PASS |" >> "$RUN_ROOT/SUMMARY.md"
  else
    FAIL=$((FAIL + 1))
    FAILED+=("$block")
    tail -80 "$block_dir/logs/genus.stdout.log" > "$block_dir/logs/failure.tail" || true
    echo "| \`$block\` | \`$top\` | FAIL rc=$rc, see \`$block/logs/failure.tail\` |" >> "$RUN_ROOT/SUMMARY.md"
  fi
done

{
  echo
  echo "## Final Result"
  echo
  echo "- PASS: $PASS"
  echo "- FAIL: $FAIL"
  if [[ "$FAIL" -gt 0 ]]; then
    echo "- Failed blocks: ${FAILED[*]}"
  fi
  echo
  echo "This run is not final timing closure, not MMMC, and not signoff."
} >> "$RUN_ROOT/SUMMARY.md"

cat "$RUN_ROOT/SUMMARY.md"

if [[ "$FAIL" -eq 0 ]]; then
  exit 0
fi
exit 1
