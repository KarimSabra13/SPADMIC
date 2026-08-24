#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAUNCHER="$(cd "$SCRIPT_DIR/.." && pwd)/server_run_mptdc_ro6_latestlef_simplepg.sh"

require_line() {
  local expected="$1"
  grep -Fqx "$expected" "$LAUNCHER" || {
    echo "ERROR: missing simple-PG route-policy line: $expected" >&2
    exit 1
  }
}

require_line 'export MPTDC_PNR_SIGNAL_TOP_LAYER=MET3'
require_line 'export MPTDC_PNR_PROMOTE_SIGNAL_TOP_TO_EFFECTIVE_FLOOR=0'
require_line 'export MPTDC_PNR_KEEP_ROUTER_TOP_AT_EFFECTIVE_FLOOR_FOR_EXISTING_ROUTES=0'
require_line 'export MPTDC_PNR_PHASE_METTP_EXCEPTION=0'
require_line 'export MPTDC_PNR_PHASE_TOP_LAYER=MET3'
require_line 'export MPTDC_PNR_PHASE_TOP_LAYER_IDX=3'
require_line 'export MPTDC_PNR_ALLOW_SPECIAL_ROUTE_ABOVE_SIGNAL_TOP=1'

if grep -Fqx 'export MPTDC_PNR_KEEP_ROUTER_TOP_AT_EFFECTIVE_FLOOR_FOR_EXISTING_ROUTES=1' "$LAUNCHER"; then
  echo "ERROR: ordinary routing is still promoted to METTP" >&2
  exit 1
fi

HELP="$($LAUNCHER --help)"
grep -Fq -- '--local-phase-preplace' <<< "$HELP"
grep -Fq -- '--physical-first' <<< "$HELP"

echo "MPTDC_SIMPLEPG_ROUTE_POLICY_TEST=PASS"
