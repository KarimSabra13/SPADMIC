#!/usr/bin/env bash
# =============================================================================
# SPADMIC TOP — Active Matrix-Top Functional Coverage
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOP_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COV_ROOT="$TOP_ROOT/build/coverage/functional"

if ! command -v xrun >/dev/null 2>&1; then
  echo "ERROR: xrun is required to execute SystemVerilog functional coverage" >&2
  exit 2
fi

bash "$TOP_ROOT/ci/check_csr_map_generated.sh"

TESTS=(coverage_walk ctrl_reject spad_reset_modes stress_random)
for test_name in "${TESTS[@]}"; do
  bash "$TOP_ROOT/scripts/sim/run_vip_test.sh" "$test_name" \
    --sim xrun \
    --func-cov \
    --cov-workdir "$COV_ROOT" \
    --cov-test-name "$test_name"
done

echo "VIP_FUNCTIONAL_COVERAGE_STATUS=PASS"
echo "CODE_COVERAGE_TARGET=NONE"
