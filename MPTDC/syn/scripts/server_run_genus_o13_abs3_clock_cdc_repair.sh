#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

export MPTDC_O13_MODE=O13_ABS3_CLOCK_CDC_CONSTRAINT_REPAIR
export MPTDC_O13_ABS3_CLOCK_CDC_REPAIR=1
export O13_SDC_PATH="${O13_SDC_PATH:-$SYN_DIR/inputs/mptdc_osc_typical_r750_delta5_o13_abs3.sdc}"

exec bash "$SCRIPT_DIR/server_run_genus_o13_phase_distribution.sh" "$@"
