#!/usr/bin/env bash
# =============================================================================
# SPADMIC TOP — Active Matrix-Top VIP Smoke
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOP_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

bash "$TOP_ROOT/ci/check_csr_map_generated.sh"

if command -v xrun >/dev/null 2>&1; then
  TESTS=(
    smoke_tdc
    smoke_position
    smoke_position_raw
    smoke_switching
    spad_reset_modes
    i2c_end_to_end
  )
  for test_name in "${TESTS[@]}"; do
    bash "$TOP_ROOT/scripts/sim/run_vip_test.sh" "$test_name" --sim xrun
  done
elif command -v verilator >/dev/null 2>&1; then
  bash "$TOP_ROOT/scripts/sim/run_vip_test.sh" smoke_tdc --sim verilator
  echo "VIP_SMOKE_STATUS=PASS_LINT_ONLY_XRUN_REQUIRED_FOR_BEHAVIOR"
else
  echo "ERROR: neither xrun nor verilator is available" >&2
  exit 2
fi
