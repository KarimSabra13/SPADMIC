#!/usr/bin/env bash
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$PNR_DIR/.." && pwd)"
SYN_DIR="$MPTDC_DIR/syn"

export O1_RUN_FLAVOR=O1B_R800_WHATIF
export MPTDC_FREQ_MODE="${MPTDC_FREQ_MODE:-r800_period_delta_whatif}"
export MPTDC_FREQ_MODE_DEFINES="$SYN_DIR/inputs/mptdc_freq_modes.defines"
export MPTDC_OSC_PD_SDC_OVERLAY="$SYN_DIR/inputs/mptdc_osc_pd_r800.sdc"

exec "$SCRIPT_DIR/server_run_innovus_o1_real_abstract.sh" "$@"
