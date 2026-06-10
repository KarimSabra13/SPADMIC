#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MPTDC_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

# shellcheck source=../../scripts/mptdc_flow_common.sh
source "$MPTDC_DIR/scripts/mptdc_flow_common.sh"

mptdc_common_init_work_roots "$REPO_ROOT"
RUN_ID="${1:-$(date +%Y%m%d_%H%M%S)_mptdc_genus_typical}"
RUN_DIR="$MPTDC_GENUS_WORK/$RUN_ID"

mptdc_common_require_clean_tracked "$REPO_ROOT"
mptdc_common_require_file "Genus delegate" "$SCRIPT_DIR/server_run_genus_o13_abs5_pd_q1_exception_exact.sh"
mptdc_common_require_file "Genus Tcl entrypoint" "$SCRIPT_DIR/genus.tcl"
mptdc_common_require_file "RO_tune4 interface audit" "$MPTDC_DIR/analog_handoff/audit_ro_tune4_abstract.py"
mptdc_common_require_file "phase-distribution filelist" "$MPTDC_DIR/syn/filelist_o13_phase_distribution.f"
mptdc_common_require_file "stable typical SDC" "$MPTDC_DIR/syn/inputs/mptdc_typical_r750_delta5.sdc"
mptdc_common_require_file "stable clock model SDC" "$MPTDC_DIR/syn/inputs/mptdc_clock_model_typical.sdc"
mptdc_common_require_file "stable phase distribution SDC" "$MPTDC_DIR/syn/inputs/mptdc_phase_distribution.sdc"
mptdc_common_require_file "stable PD Vernier exception SDC" "$MPTDC_DIR/syn/inputs/mptdc_pd_vernier_exceptions.sdc"
mptdc_common_require_file "PD Vernier exception SDC" "$MPTDC_DIR/syn/inputs/mptdc_osc_typical_r750_delta5_o13_abs5.sdc"
mptdc_common_require_file "RO_tune4 Liberty shell" "$MPTDC_DIR/syn/macros/RO_tune4_real_abstract_shell.lib"

mkdir -p "$MPTDC_GENUS_WORK"
mptdc_common_print_run_header \
  "MPTDC Genus Typical Timing Closure" \
  "$REPO_ROOT" \
  "$RUN_ID" \
  "$RUN_DIR" \
  "O13_abs5_pd_q1_exception_exact"

MPTDC_STABLE_FLOW_LABEL="${MPTDC_STABLE_FLOW_LABEL:-MPTDC_GENUS_TYPICAL}"
MPTDC_STABLE_CLOSURE_LABEL="${MPTDC_STABLE_CLOSURE_LABEL:-MPTDC_TYPICAL_TIMING_CLOSURE}"
MPTDC_FINAL_PACKAGE_LABEL="${MPTDC_FINAL_PACKAGE_LABEL:-TYPICAL_ONLY_TAPEOUT_PACKAGE}"
MPTDC_SIGNOFF_BOUNDARY="${MPTDC_SIGNOFF_BOUNDARY:-TYPICAL_ONLY_NOT_MMMC}"

echo "Flow: $MPTDC_STABLE_FLOW_LABEL"
echo "Mode: $MPTDC_STABLE_CLOSURE_LABEL"
echo "Package: $MPTDC_FINAL_PACKAGE_LABEL"
echo "Signoff boundary: $MPTDC_SIGNOFF_BOUNDARY"
echo "Phase distribution: BUHDX4 -> BUHDX12"
echo "PD Vernier exception: exact 64 q1 sampler endpoints"
echo "Frequency mode: R750_delta5"

export MPTDC_GENUS_RUN_DIR="$RUN_DIR"
export MPTDC_STABLE_FLOW_LABEL
export MPTDC_STABLE_CLOSURE_LABEL
export MPTDC_FINAL_PACKAGE_LABEL
export MPTDC_SIGNOFF_BOUNDARY
export MPTDC_O13_MODE="O13_ABS5_PD_Q1_EXCEPTION_EXACT_MATCH"
export O13_SDC_PATH="${O13_SDC_PATH:-$MPTDC_DIR/syn/inputs/mptdc_pd_vernier_exceptions.sdc}"

exec "$SCRIPT_DIR/server_run_genus_o13_abs5_pd_q1_exception_exact.sh" "$RUN_ID"
