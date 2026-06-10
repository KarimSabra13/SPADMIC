#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_ID="${1:-$(date +%Y%m%d_%H%M%S)_mptdc_genus_timing_closure}"
if [[ $# -gt 0 ]]; then
  shift
fi

export MPTDC_STABLE_FLOW_LABEL="MPTDC_GENUS_TIMING_CLOSURE"
exec "$SCRIPT_DIR/server_run_genus_mptdc_typical.sh" "$RUN_ID" "$@"
