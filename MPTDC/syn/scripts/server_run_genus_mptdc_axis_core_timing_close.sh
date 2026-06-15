#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RUN_ID="${1:-$(date +%Y%m%d_%H%M%S)_axis_core_genus_timing_close}"

# Fast timing-closure run for the product axis:
# - keeps ABS5 q1 exception and REPAIR8/JIHD enabled
# - keeps exact fast-tag grouping/fanout/transition/max-delay constraints
# - disables exact source-cell forcing by default. The JIHD DFRRQJIHDX4
#   source override improves drive but has high C->Q and can dominate both
#   FAST_TAG_TO_PD_TS and LOCAL_FAST_TAG_SELF paths once preserved.
# - uses the full 1.333 ns fast-period budget by default for the exact C-to-D
#   fast-tag timestamp paths.
export MPTDC_GENUS_CLOSURE_PROFILE=timing_ultra
export MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL_DISABLE="${MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL_DISABLE:-1}"
if [[ "$MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL_DISABLE" == "1" ]]; then
  unset MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL
  unset MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL_MODE
  unset MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_RESET0_CELL
  unset MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_SET1_CELL
else
  export MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL="${MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL:-POLARITY_AWARE}"
  export MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL_MODE="${MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL_MODE:-POLARITY_AWARE}"
  export MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_RESET0_CELL="${MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_RESET0_CELL:-DFRRQJIHDX4}"
  export MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_SET1_CELL="${MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_SET1_CELL:-DFRSJIHDX2}"
  export MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_SKIP_UNSUPPORTED="${MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_SKIP_UNSUPPORTED:-1}"
fi
export MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_NS="${MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_NS:-1.333}"

exec "$SCRIPT_DIR/server_run_genus_o13_phase_distribution.sh" "$RUN_ID"
