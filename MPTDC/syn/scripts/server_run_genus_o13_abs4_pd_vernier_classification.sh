#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export MPTDC_O13_MODE=O13_ABS4_PD_VERNIER_CLASSIFICATION
export MPTDC_O13_ABS3_CLOCK_CDC_REPAIR=1
export MPTDC_O13_ABS4_PD_VERNIER_CLASSIFICATION=1

exec "$SCRIPT_DIR/server_run_genus_o13_phase_distribution.sh" "$@"
