#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Purpose : Run the stable VIP smoke suite through Verilator.
# Usage   : bash ci/run_vip_smoke.sh
# Context : Fast local regression wrapper around scripts/sim/run_vip_test.sh
#           for the maintained VIP test list.
# Author  : Karim Sabra
# -----------------------------------------------------------------------------

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNNER="$ROOT/scripts/sim/run_vip_test.sh"

pass=0
fail=0

run_smoke() {
  local test_name="$1"
  shift

  echo "=== Running VIP smoke: $test_name ==="
  if bash "$RUNNER" "$test_name" --sim verilator "$@" 2>&1 | tail -10; then
    pass=$((pass + 1))
    echo "--- $test_name: PASSED ---"
  else
    fail=$((fail + 1))
    echo "!!! $test_name: FAILED !!!"
  fi
  echo
}

run_smoke smoke_single_conv
run_smoke full_mode_timestamp
run_smoke firsthit_contract
run_smoke backpressure_integrity
run_smoke start_watchdog
run_smoke cal_inject
run_smoke overflow_status
run_smoke long_random
run_smoke multi_conv_rearm_stress
run_smoke global_watchdog_recovery
run_smoke csr_readback_control
run_smoke jitter_robustness --osc-jitter-sigma 8 --osc-jitter-bound 24

echo "VIP smoke results: $pass passed, $fail failed"
[[ $fail -eq 0 ]]
