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

# Keep the matrix-top physical stack aligned with the current MPTDC product
# boundary. Override only for an explicitly reviewed technology audit.
export MPTDC_XH018_STACK="${MPTDC_XH018_STACK:-xx31}"
export MPTDC_STDCELL_FAMILY="${MPTDC_STDCELL_FAMILY:-JIHD}"
export MPTDC_PNR_ROUTE_LAYER_NAMES="${MPTDC_PNR_ROUTE_LAYER_NAMES:-MET1 MET2 MET3 METTP}"
export MPTDC_PNR_SIGNAL_TOP_LAYER="${MPTDC_PNR_SIGNAL_TOP_LAYER:-MET3}"
export MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER="${MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER:-METTP}"
export MPTDC_PNR_POWER_LAYER="${MPTDC_PNR_POWER_LAYER:-METTP}"
export MPTDC_PNR_PHASE_TOP_LAYER="${MPTDC_PNR_PHASE_TOP_LAYER:-METTP}"

BLOCKS=(
  "matrix_reset_ctrl:spadmic_matrix_reset_ctrl"
  "or64_tree:spadmic_matrix_or_tree"
  "position_snapshot:spadmic_position_snapshot_packetizer"
  "matrix_cfg_ctrl:spadmic_matrix_cfg_ctrl"
  "event_coordinator:spadmic_event_coordinator"
  "event_bundle_tx:spadmic_event_bundle_tx"
  "output_fifo:spadmic_output_fifo_topcfg"
  "matrix_top_csr:spadmic_matrix_top_csr"
  "i2c_csr_bridge:spadmic_i2c_csr_bridge"
  "i2c_slave:spadmic_i2c_slave"
  "ddr16_pairer:spadmic_ddr16_tx_pairer"
  "ddrs2_adapter:spadmic_ddrs2_adapter"
)

SKIPPED_BLOCKS=("spadmic_top_matrix_v1:spadmic_top_matrix_v1")
DDR16_INCLUDED=1

if [[ "${SPADMIC_GENUS_EXCLUDE_DDR16:-0}" == "1" ]]; then
  DDR16_INCLUDED=0
  SKIPPED_BLOCKS+=("ddr16_pairer:spadmic_ddr16_tx_pairer")
  SKIPPED_BLOCKS+=("ddrs2_adapter:spadmic_ddrs2_adapter")
  TMP_BLOCKS=()
  for item in "${BLOCKS[@]}"; do
    if [[ "$item" != "ddr16_pairer:spadmic_ddr16_tx_pairer" && \
          "$item" != "ddrs2_adapter:spadmic_ddrs2_adapter" ]]; then
      TMP_BLOCKS+=("$item")
    fi
  done
  BLOCKS=("${TMP_BLOCKS[@]}")
fi

if [[ "${SPADMIC_GENUS_INCLUDE_FULL_TOP:-0}" == "1" ]]; then
  BLOCKS+=("spadmic_top_matrix_v1:spadmic_top_matrix_v1")
  SKIPPED_BLOCKS=("${SKIPPED_BLOCKS[@]/spadmic_top_matrix_v1:spadmic_top_matrix_v1}")
fi

CUSTOM_BLOCK_LIST=0
if [[ -n "${SPADMIC_GENUS_OOC_BLOCKS:-}" ]]; then
  CUSTOM_BLOCK_LIST=1
  # shellcheck disable=SC2206
  BLOCKS=($SPADMIC_GENUS_OOC_BLOCKS)
  SKIPPED_BLOCKS=("custom_block_list:SPADMIC_GENUS_OOC_BLOCKS")
fi

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
  echo "MPTDC_XH018_STACK=$MPTDC_XH018_STACK"
  echo "MPTDC_STDCELL_FAMILY=$MPTDC_STDCELL_FAMILY"
  echo "MPTDC_PNR_ROUTE_LAYER_NAMES=$MPTDC_PNR_ROUTE_LAYER_NAMES"
  echo "MPTDC_PNR_SIGNAL_TOP_LAYER=$MPTDC_PNR_SIGNAL_TOP_LAYER"
  echo "MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER=$MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER"
  echo "MPTDC_PNR_POWER_LAYER=$MPTDC_PNR_POWER_LAYER"
  echo "SPADMIC_GENUS_EXCLUDE_DDR16=${SPADMIC_GENUS_EXCLUDE_DDR16:-0}"
  echo "DDR16_INCLUDED=$DDR16_INCLUDED"
  echo "SPADMIC_GENUS_INCLUDE_FULL_TOP=${SPADMIC_GENUS_INCLUDE_FULL_TOP:-0}"
  echo "SPADMIC_GENUS_OOC_BLOCKS=${SPADMIC_GENUS_OOC_BLOCKS:-}"
  echo "CUSTOM_BLOCK_LIST=$CUSTOM_BLOCK_LIST"
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
    echo "- XH018 stack: \`$MPTDC_XH018_STACK\`"
    echo "- Standard-cell family: \`$MPTDC_STDCELL_FAMILY\`"
  echo "- Route layers: \`$MPTDC_PNR_ROUTE_LAYER_NAMES\`"
  echo "- Ordinary signal top layer: \`$MPTDC_PNR_SIGNAL_TOP_LAYER\`"
  echo "- DDR16 included: \`$DDR16_INCLUDED\`"
  echo "- Full matrix top included: \`${SPADMIC_GENUS_INCLUDE_FULL_TOP:-0}\`"
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
resolve_flist "$TOP_ROOT" "$TOP_ROOT/filelist.f" "$RUN_ROOT/filelists/top_abs.raw.f"

# Keep the shared TOP filelist intact for simulation and legacy coverage, but
# filter the matrix-top Genus OOC input set. The old top and obsolete DDR8
# dual-edge RTL are not part of the final matrix-top path; reading them makes
# Genus fail before it reaches the DDR16 matrix-top design.
TOP_GENUS_EXCLUDE_RE='/TOP/rtl/(spadmic_ddr_tx|spadmic_top_v1)\.sv$'
grep -E "$TOP_GENUS_EXCLUDE_RE" "$RUN_ROOT/filelists/top_abs.raw.f" \
  > "$RUN_ROOT/filelists/top_genus_excluded.f" || true
grep -v -E "$TOP_GENUS_EXCLUDE_RE" "$RUN_ROOT/filelists/top_abs.raw.f" \
  > "$RUN_ROOT/filelists/top_abs.f"

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
  echo "- XH018 stack: \`$MPTDC_XH018_STACK\`"
  echo "- Standard-cell family: \`$MPTDC_STDCELL_FAMILY\`"
  echo "- Route layers: \`$MPTDC_PNR_ROUTE_LAYER_NAMES\`"
  echo "- Ordinary signal top layer: \`$MPTDC_PNR_SIGNAL_TOP_LAYER\`"
  echo "- Effective top floor layer: \`$MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER\`"
  echo "- DDR16 included: \`$DDR16_INCLUDED\`"
  echo "- Full matrix top included: \`${SPADMIC_GENUS_INCLUDE_FULL_TOP:-0}\`"
  echo "- Custom block list: \`$CUSTOM_BLOCK_LIST\`"
  echo "- Signoff: non-signoff, typical-only feasibility"
  echo
  echo "## Matrix TOP Genus Filelist"
  echo
  echo "- Raw TOP filelist: \`filelists/top_abs.raw.f\`"
  echo "- Genus TOP filelist: \`filelists/top_abs.f\`"
  echo "- Excluded legacy/obsolete files: \`filelists/top_genus_excluded.f\`"
  if [[ -s "$RUN_ROOT/filelists/top_genus_excluded.f" ]]; then
    echo
    echo "Excluded files:"
    while IFS= read -r excluded_file; do
      echo "- \`$excluded_file\`"
    done < "$RUN_ROOT/filelists/top_genus_excluded.f"
  fi
  echo
  echo "Skipped by default:"
  for skipped in "${SKIPPED_BLOCKS[@]}"; do
    [[ -n "$skipped" ]] || continue
    echo "- \`${skipped%%:*}\` / \`${skipped##*:}\`"
  done
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
