#!/usr/bin/env bash
# Author: Karim Sabra
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$SYN_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"
PROFILE="$SCRIPT_DIR/profiles/genus_axis_core_typical_closed.sh"
BACKEND="$SCRIPT_DIR/server_run_genus_o13_phase_distribution.sh"

# shellcheck source=../../scripts/mptdc_flow_common.sh
source "$MPTDC_DIR/scripts/mptdc_flow_common.sh"
mptdc_common_require_file "canonical Genus profile" "$PROFILE"
# shellcheck source=profiles/genus_axis_core_typical_closed.sh
source "$PROFILE"

if [[ $# -gt 1 ]]; then
  echo "Usage: $0 [run_id]" >&2
  echo "The canonical handoff flow accepts no timing-policy command arguments or environment overrides." >&2
  exit 2
fi

mptdc_common_init_work_roots "$REPO_ROOT"
RUN_ID="${1:-${MPTDC_GENUS_RUN_ID:-MPTDC_TC_Closure_Genus}}"
RUN_DIR="$MPTDC_GENUS_WORK/$RUN_ID"

case "$RUN_ID" in
  ""|"/"|"."|*"/"*|*".."*)
    echo "ERROR: RUN_ID must be a simple directory name, got '$RUN_ID'." >&2
    exit 2
    ;;
esac

mptdc_common_require_clean_tracked "$REPO_ROOT"
mptdc_common_require_file "Genus backend" "$BACKEND"
mptdc_common_require_file "Genus Tcl entrypoint" "$SCRIPT_DIR/genus.tcl"
mptdc_common_require_file "RO_tune6 interface audit" "$MPTDC_DIR/analog_handoff/audit_ro_tune6_layout.py"
mptdc_common_require_file "RO_tune6 handoff environment" "$MPTDC_DIR/analog_handoff/real_ro_tune6_layout.env"
mptdc_common_require_file "canonical axis-core filelist" "$SYN_DIR/filelist_axis_core_typical_closed.f"
mptdc_common_require_file "canonical typical-closure SDC" "$SYN_DIR/inputs/mptdc_axis_core_typical_closed.sdc"
mptdc_common_require_file "RO_tune6 Liberty shell" "$SYN_DIR/macros/RO_tune6_real_layout_shell.lib"

# Apply the fixed policy before creating output directories. This fails closed
# if a legacy experiment variable is inherited from the calling shell.
mptdc_genus_axis_core_typical_closed_apply "$SYN_DIR"

EXPECTED_HEAD="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)"
if [[ -z "$EXPECTED_HEAD" ]]; then
  echo "ERROR: could not resolve repository HEAD for Genus guard." >&2
  exit 2
fi
export EXPECTED_HEAD

mkdir -p "$MPTDC_GENUS_WORK"
export MPTDC_GENUS_RUN_DIR="$RUN_DIR"

mptdc_common_print_run_header \
  "MPTDC Genus Axis-Core Typical Closure" \
  "$REPO_ROOT" \
  "$RUN_ID" \
  "$RUN_DIR" \
  "O13 backend retained internally; ABS5 exact Vernier exception + JIHD repair8 + guarded local ON22 X1"

mptdc_genus_axis_core_typical_closed_print
echo "EXPECTED_HEAD=$EXPECTED_HEAD"
echo "INNOVUS_INTENT=FEASIBILITY_INPUT_ONLY"
echo "EXPECTED_FINAL_DECISION=GENUS_TYPICAL_CLOSED"

exec bash "$BACKEND" "$RUN_ID"
