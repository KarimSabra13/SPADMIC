#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MPTDC_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

# shellcheck source=../mptdc_flow_common.sh
source "$MPTDC_DIR/scripts/mptdc_flow_common.sh"

mptdc_common_init_work_roots "$REPO_ROOT"
RUN_ID="${1:-$(date +%Y%m%d_%H%M%S)_mptdc_characterization}"
if [[ $# -gt 0 ]]; then
  shift
fi
RUN_DIR="$MPTDC_CHARACTERIZATION_WORK/$RUN_ID"

mptdc_common_require_clean_tracked "$REPO_ROOT"
mptdc_common_require_file "characterization delegate" "$MPTDC_DIR/scripts/sim/run_vip_overnight.sh"

mkdir -p "$MPTDC_CHARACTERIZATION_WORK"
mptdc_common_print_run_header \
  "MPTDC Characterization" \
  "$REPO_ROOT" \
  "$RUN_ID" \
  "$RUN_DIR" \
  "vip_overnight_characterization"

export MPTDC_STABLE_FLOW_LABEL="MPTDC_CHARACTERIZATION"
export MPTDC_FREQ_MODE="${MPTDC_FREQ_MODE:-r750_delta5}"
exec "$MPTDC_DIR/scripts/sim/run_vip_overnight.sh" \
  --freq-mode "$MPTDC_FREQ_MODE" \
  --out-dir "$RUN_DIR" \
  "$@"
