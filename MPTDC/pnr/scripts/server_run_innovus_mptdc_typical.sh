#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_ID="${1:-$(date +%Y%m%d_%H%M%S)_mptdc_innovus_typical}"
if [[ $# -gt 0 ]]; then
  shift
fi

export MPTDC_STABLE_FLOW_LABEL="MPTDC_INNOVUS_TYPICAL"
exec "$SCRIPT_DIR/server_run_innovus_mptdc_feasibility.sh" "$RUN_ID" "$@"
