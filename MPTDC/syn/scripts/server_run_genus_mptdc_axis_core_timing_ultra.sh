#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RUN_ID="${1:-$(date +%Y%m%d_%H%M%S)_axis_core_genus_timing_ultra}"

# Timing-ultra is the product-axis default:
# - mptdc_axis_core top
# - ABS5 exact PD q1 Vernier exception overlay
# - STRIDE2 opt mode
# - REPAIR8 JIHD exact fast-tag closure
# - area recovery off for a clean timing comparison
# - power recovery and clock gating off
export MPTDC_GENUS_CLOSURE_PROFILE=timing_ultra

exec "$SCRIPT_DIR/server_run_genus_o13_phase_distribution.sh" "$RUN_ID"
