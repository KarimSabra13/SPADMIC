#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RUN_ID="${1:-$(date +%Y%m%d_%H%M%S)_axis_core_genus_area_ultra}"

# Area-ultra starts from the same timing-safe ABS5/REPAIR8/JIHD setup as
# timing-ultra, then enables Genus area recovery. Power recovery stays off
# because area/timing are the priority for this MPTDC block.
export MPTDC_GENUS_CLOSURE_PROFILE=area_timing_ultra

exec "$SCRIPT_DIR/server_run_genus_o13_phase_distribution.sh" "$RUN_ID"
