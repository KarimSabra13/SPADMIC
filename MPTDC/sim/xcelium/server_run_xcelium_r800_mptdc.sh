#!/usr/bin/env bash
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MPTDC_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

RUN_ID="${1:-$(date +%Y%m%d_%H%M%S)_r800_xcelium}"
RESULT_DIR="$REPO_ROOT/results/xcelium/$RUN_ID"
MAIN_LOG="$RESULT_DIR/xcelium_${RUN_ID}.log"

if [[ "${MPTDC_R800_XCELIUM_ALLOW_NOMINAL_MODEL:-0}" == "1" ]]; then
  export MPTDC_FREQ_MODE="${MPTDC_FREQ_MODE:-r800_period_delta_whatif}"
  exec "$SCRIPT_DIR/server_run_xcelium_mptdc.sh" "$RUN_ID"
fi

mkdir -p "$RESULT_DIR/failures"

{
  echo "# Xcelium R800 Server Run Summary"
  echo
  echo "- Run ID: \`$RUN_ID\`"
  echo "- Git HEAD: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)\`"
  echo "- Result directory: \`results/xcelium/$RUN_ID/\`"
  echo "- Requested mode: \`${MPTDC_FREQ_MODE:-r800_period_delta_whatif}\`"
  echo
  echo "R800_XCELIUM_STATUS=BLOCKED"
  echo "O1B_R800_CALIBRATION_SAFE=NO"
  echo "REASON=No analog-confirmed R800 behavioral model or compile-time tune mode is available in RTL."
  echo
  echo "The STA/PnR R800 scripts are what-if only. Xcelium cannot claim an R800"
  echo "behavioral regression until analog tune constants and a guarded behavioral"
  echo "model/testbench mode are added without changing packet/raw field semantics."
  echo
  echo "To intentionally run the existing nominal behavioral model under this run ID,"
  echo "set MPTDC_R800_XCELIUM_ALLOW_NOMINAL_MODEL=1. That run is not R800 proof."
} > "$RESULT_DIR/SUMMARY.md"

{
  echo "date: $(date -Iseconds)"
  echo "repo: $REPO_ROOT"
  echo "branch: $(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || true)"
  echo "head: $(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)"
  echo "status: BLOCKED"
  echo "reason: missing analog-confirmed R800 behavioral model/tune mode"
} > "$MAIN_LOG"

cp "$RESULT_DIR/SUMMARY.md" "$RESULT_DIR/test_summary.txt"
cat "$RESULT_DIR/SUMMARY.md"
exit 2
