#!/usr/bin/env bash
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MPTDC_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"
MPTDC_WORK_ROOT="${MPTDC_WORK_ROOT:-work}"
case "$MPTDC_WORK_ROOT" in
  /*) ;;
  *) MPTDC_WORK_ROOT="$REPO_ROOT/$MPTDC_WORK_ROOT" ;;
esac
MPTDC_XCELIUM_WORK="${MPTDC_XCELIUM_WORK:-$MPTDC_WORK_ROOT/xcelium}"
MPTDC_XCELIUM_SCRATCH="${MPTDC_XCELIUM_SCRATCH:-$MPTDC_WORK_ROOT/scratch/xcelium}"

RUN_ID="${1:-$(date +%Y%m%d_%H%M%S)_mptdc_xcelium}"
RESULT_DIR="$MPTDC_XCELIUM_WORK/$RUN_ID"
MAIN_LOG="$RESULT_DIR/xcelium_${RUN_ID}.log"
VIP_WORK_DIR="$MPTDC_XCELIUM_SCRATCH/$RUN_ID/vip"
VIP_PUBLISH_DIR="$RESULT_DIR/vip"

DIRECTED_TESTS=(
  tb_axis_core_product_smoke
)

VIP_TESTS=(
)

if [[ -e "$RESULT_DIR" || -e "$VIP_WORK_DIR" ]]; then
  echo "ERROR: result directory already exists for RUN_ID: $RUN_ID" >&2
  echo "Top-level result: $RESULT_DIR" >&2
  echo "MPTDC VIP work:   $VIP_WORK_DIR" >&2
  echo "Use a unique RUN_ID or archive the old server result first." >&2
  exit 2
fi

mkdir -p "$RESULT_DIR"/{directed,failures} "$VIP_WORK_DIR"

{
  echo "Run ID: $RUN_ID"
  echo "Date: $(date -Iseconds)"
  echo "Repository root: $REPO_ROOT"
  echo "MPTDC root: $MPTDC_DIR"
  echo "Branch: $(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || true)"
  echo "HEAD: $(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)"
  echo
  echo "git status --short:"
  git -C "$REPO_ROOT" status --short 2>/dev/null || true
  echo
  echo "xrun:"
  command -v xrun || true
  xrun -version 2>/dev/null | head -20 || true
} | tee "$RESULT_DIR/run_manifest.txt" | tee "$MAIN_LOG"

if ! command -v xrun >/dev/null 2>&1; then
  echo "ERROR: xrun not found in PATH. Run this script on the lab server." | tee -a "$MAIN_LOG"
  exit 127
fi

PASS_COUNT=0
FAIL_COUNT=0
: > "$RESULT_DIR/test_summary.txt"

run_directed() {
  local tb_name="$1"
  local log="$RESULT_DIR/directed/${tb_name}.log"

  echo "[XCELIUM][DIRECTED] $tb_name" | tee -a "$MAIN_LOG"
  if bash "$MPTDC_DIR/scripts/sim/run_tb.sh" "$tb_name" --sim xcelium > "$log" 2>&1; then
    echo "PASS directed $tb_name" | tee -a "$RESULT_DIR/test_summary.txt" | tee -a "$MAIN_LOG"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "FAIL directed $tb_name" | tee -a "$RESULT_DIR/test_summary.txt" | tee -a "$MAIN_LOG"
    tail -200 "$log" > "$RESULT_DIR/failures/${tb_name}.tail.log" || true
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

for tb_name in "${DIRECTED_TESTS[@]}"; do
  run_directed "$tb_name"
done

if (( ${#VIP_TESTS[@]} > 0 )); then
  VIP_RC=0
  echo "[XCELIUM][VIP] ${VIP_TESTS[*]}" | tee -a "$MAIN_LOG"
  bash "$MPTDC_DIR/ci/run_vip_xcelium_regression.sh" \
    --jobs "${XCELIUM_JOBS:-4}" \
    --seed-start "${XCELIUM_SEED_START:-7000}" \
    --seeds "${XCELIUM_SEEDS:-4}" \
    --out-dir "$VIP_WORK_DIR" \
    "${VIP_TESTS[@]}" \
    >> "$MAIN_LOG" 2>&1 || VIP_RC=$?

  mkdir -p "$VIP_PUBLISH_DIR"
  cp -a "$VIP_WORK_DIR/." "$VIP_PUBLISH_DIR/" 2>/dev/null || true

  if [[ $VIP_RC -eq 0 ]]; then
    echo "PASS vip_regression selected_tests" | tee -a "$RESULT_DIR/test_summary.txt" | tee -a "$MAIN_LOG"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "FAIL vip_regression selected_tests rc=$VIP_RC" | tee -a "$RESULT_DIR/test_summary.txt" | tee -a "$MAIN_LOG"
    if [[ -f "$VIP_WORK_DIR/failures.txt" ]]; then
      cp "$VIP_WORK_DIR/failures.txt" "$RESULT_DIR/failures/vip_failures.txt" || true
    fi
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
else
  echo "SKIP vip_regression retired_standalone_mptdc_vip" | tee -a "$RESULT_DIR/test_summary.txt" | tee -a "$MAIN_LOG"
fi

{
  echo "# Xcelium Server Run Summary"
  echo
  echo "- Run ID: \`$RUN_ID\`"
  echo "- Git HEAD: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)\`"
  echo "- Result directory: \`$RESULT_DIR/\`"
  echo "- VIP work directory: \`$VIP_WORK_DIR/\`"
  echo "- Directed tests: ${DIRECTED_TESTS[*]}"
  echo "- VIP tests: ${VIP_TESTS[*]}"
  echo "- VIP seeds: ${XCELIUM_SEEDS:-4} from ${XCELIUM_SEED_START:-7000}"
  echo "- Pass count: $PASS_COUNT"
  echo "- Fail count: $FAIL_COUNT"
  echo
  echo "## Files"
  echo
  echo "- \`xcelium_${RUN_ID}.log\`"
  echo "- \`run_manifest.txt\`"
  echo "- \`test_summary.txt\`"
  echo "- \`directed/\`"
  echo "- \`vip/\`"
  echo "- \`failures/\`"
} > "$RESULT_DIR/SUMMARY.md"

cat "$RESULT_DIR/SUMMARY.md"

if [[ $FAIL_COUNT -ne 0 ]]; then
  exit 1
fi
exit 0
