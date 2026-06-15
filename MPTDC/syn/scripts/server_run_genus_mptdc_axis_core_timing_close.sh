#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RUN_ID="${1:-$(date +%Y%m%d_%H%M%S)_axis_core_genus_timing_close}"

# Fast timing-closure run for the product axis:
# - keeps ABS5 q1 exception and REPAIR8/JIHD enabled
# - forces exact fast-tag source flops with JIHD polarity-aware cells
# - uses a 1.31 ns exact C-to-D budget, still tighter than the 1.333 ns fast
#   period but not the older over-aggressive 1.04 ns stress target
export MPTDC_GENUS_CLOSURE_PROFILE=timing_ultra
export MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL=POLARITY_AWARE
export MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL_MODE=POLARITY_AWARE
export MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_RESET0_CELL=DFRRQJIHDX4
export MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_SET1_CELL=DFRSJIHDX2
export MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_SKIP_UNSUPPORTED=1
export MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_NS="${MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_NS:-1.31}"

exec "$SCRIPT_DIR/server_run_genus_o13_phase_distribution.sh" "$RUN_ID"
