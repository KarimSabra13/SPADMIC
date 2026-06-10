#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MPTDC_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

# shellcheck source=../../scripts/mptdc_flow_common.sh
source "$MPTDC_DIR/scripts/mptdc_flow_common.sh"

mptdc_common_init_work_roots "$REPO_ROOT"
RUN_ID="${1:-$(date +%Y%m%d_%H%M%S)_mptdc_innovus_feasibility}"
RUN_DIR="$MPTDC_INNOVUS_WORK/$RUN_ID"

mptdc_common_require_clean_tracked "$REPO_ROOT"
mptdc_common_require_file "Innovus delegate" "$SCRIPT_DIR/server_run_innovus_o13_phase_distribution.sh"
mptdc_common_require_file "phase-distribution Tcl" "$SCRIPT_DIR/innovus_o13_phase_distribution.tcl"
mptdc_common_require_file "phase-buffer report Tcl" "$SCRIPT_DIR/innovus_o13_phase_buffer_reports.tcl"
mptdc_common_require_file "XLIBD typical config" "$MPTDC_DIR/pnr/config/xlibd_spadmic_typical_cell_values.tcl"

mkdir -p "$MPTDC_INNOVUS_WORK"
mptdc_common_print_run_header \
  "MPTDC Innovus Typical Feasibility" \
  "$REPO_ROOT" \
  "$RUN_ID" \
  "$RUN_DIR" \
  "O13_phase_distribution"

export MPTDC_STABLE_FLOW_LABEL="MPTDC_INNOVUS_FEASIBILITY"
export MPTDC_O13_MODE="${MPTDC_O13_MODE:-report_only}"

exec "$SCRIPT_DIR/server_run_innovus_o13_phase_distribution.sh" "$RUN_ID"
