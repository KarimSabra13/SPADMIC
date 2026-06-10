#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MPTDC_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

# shellcheck source=../mptdc_flow_common.sh
source "$MPTDC_DIR/scripts/mptdc_flow_common.sh"

mptdc_common_init_work_roots "$REPO_ROOT"
RUN_ID="${1:-$(date +%Y%m%d_%H%M%S)_mptdc_verilator_smoke}"
RUN_DIR="$MPTDC_VERILATOR_WORK/$RUN_ID"

mptdc_common_require_clean_tracked "$REPO_ROOT"
mptdc_common_require_file "Verilator smoke delegate" "$MPTDC_DIR/sim/verilator/run_smoke.sh"
mptdc_common_require_file "Verilator filelist" "$MPTDC_DIR/sim/verilator/filelist_verilator.f"

mkdir -p "$MPTDC_VERILATOR_WORK"
mptdc_common_print_run_header \
  "MPTDC Verilator Smoke" \
  "$REPO_ROOT" \
  "$RUN_ID" \
  "$RUN_DIR" \
  "local_verilator_smoke"

export MPTDC_STABLE_FLOW_LABEL="MPTDC_VERILATOR_SMOKE"
export MPTDC_FREQ_MODE="${MPTDC_FREQ_MODE:-r750_delta5}"
exec "$MPTDC_DIR/sim/verilator/run_smoke.sh" "$RUN_ID"
