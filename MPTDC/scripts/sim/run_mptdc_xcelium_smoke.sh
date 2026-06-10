#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MPTDC_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

# shellcheck source=../mptdc_flow_common.sh
source "$MPTDC_DIR/scripts/mptdc_flow_common.sh"

mptdc_common_init_work_roots "$REPO_ROOT"
RUN_ID="${1:-$(date +%Y%m%d_%H%M%S)_mptdc_xcelium_smoke}"
RUN_DIR="$MPTDC_XCELIUM_WORK/$RUN_ID"

mptdc_common_require_clean_tracked "$REPO_ROOT"
mptdc_common_require_file "Xcelium smoke delegate" "$MPTDC_DIR/sim/xcelium/server_run_xcelium_mptdc.sh"

mkdir -p "$MPTDC_XCELIUM_WORK"
mptdc_common_print_run_header \
  "MPTDC Xcelium Smoke" \
  "$REPO_ROOT" \
  "$RUN_ID" \
  "$RUN_DIR" \
  "server_xcelium_mptdc"

export MPTDC_STABLE_FLOW_LABEL="MPTDC_XCELIUM_SMOKE"
export MPTDC_FREQ_MODE="${MPTDC_FREQ_MODE:-r750_delta5}"
exec "$MPTDC_DIR/sim/xcelium/server_run_xcelium_mptdc.sh" "$RUN_ID"
