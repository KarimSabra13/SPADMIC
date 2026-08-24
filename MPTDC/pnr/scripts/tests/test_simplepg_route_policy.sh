#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAUNCHER="$(cd "$SCRIPT_DIR/.." && pwd)/server_run_mptdc_ro6_latestlef_simplepg.sh"
SIGNOFF_WRAPPER="$(cd "$SCRIPT_DIR/.." && pwd)/server_run_innovus_mptdc_digital_signoff.sh"

require_line() {
  local expected="$1"
  grep -Fqx "$expected" "$LAUNCHER" || {
    echo "ERROR: missing simple-PG route-policy line: $expected" >&2
    exit 1
  }
}

require_line 'export MPTDC_PNR_SIGNAL_TOP_LAYER=MET3'
require_line 'export MPTDC_PNR_PROMOTE_SIGNAL_TOP_TO_EFFECTIVE_FLOOR=0'
require_line 'export MPTDC_PNR_KEEP_ROUTER_TOP_AT_EFFECTIVE_FLOOR_FOR_EXISTING_ROUTES="$KEEP_ROUTER_TOP_AT_FLOOR_VALUE"'
require_line 'export MPTDC_PNR_PHASE_METTP_EXCEPTION=0'
require_line 'export MPTDC_PNR_PHASE_TOP_LAYER=MET3'
require_line 'export MPTDC_PNR_PHASE_TOP_LAYER_IDX=3'
require_line 'export MPTDC_PNR_ALLOW_SPECIAL_ROUTE_ABOVE_SIGNAL_TOP=1'
require_line 'export MPTDC_SIGNAL_TOP_ROUTE_BLOCKAGE_TEMPORARY="$SIGNAL_TOP_ROUTE_BLOCKAGE_TEMPORARY_VALUE"'
require_line 'export MPTDC_BLOCK_PG_PIN_STYLE=ring_aligned_vdd_vss_pair'
require_line 'export MPTDC_ALLOW_LEGACY_PG_TOPOLOGY=0'

grep -Fqx '    mesh_lr_vdd_vss|ring_aligned_vdd_vss_pair) ;;' "$SIGNOFF_WRAPPER" || {
  echo "ERROR: shared PG policy guard does not accept the ring-aligned style" >&2
  exit 1
}

if grep -Fq 'simple_vdd_vss_pair)' "$SIGNOFF_WRAPPER"; then
  echo "ERROR: shared PG policy guard accepts the unsafe broad simple pair style" >&2
  exit 1
fi

if grep -Fqx 'export MPTDC_PNR_KEEP_ROUTER_TOP_AT_EFFECTIVE_FLOOR_FOR_EXISTING_ROUTES=1' "$LAUNCHER"; then
  echo "ERROR: ordinary routing is still promoted to METTP" >&2
  exit 1
fi

if grep -Fqx 'export MPTDC_BLOCK_PG_PIN_STYLE=simple_vdd_vss_pair' "$LAUNCHER"; then
  echo "ERROR: unsafe broad simple VDD/VSS pin rectangles are still enabled" >&2
  exit 1
fi

HELP="$($LAUNCHER --help)"
grep -Fq -- '--local-phase-preplace' <<< "$HELP"
grep -Fq -- '--physical-first' <<< "$HELP"
grep -Fq -- '--temporary-signal-top-route-blockage' <<< "$HELP"

tclsh "$SCRIPT_DIR/test_block_pg_pin_geometry.tcl"
tclsh "$SCRIPT_DIR/test_signal_top_route_blockage_lifecycle.tcl"

echo "MPTDC_SIMPLEPG_ROUTE_POLICY_TEST=PASS"
