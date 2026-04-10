#!/usr/bin/env bash
# =============================================================================
# SPADMIC TOP — VIP Coverage Regression
# Runs all VIP tests with functional + code coverage enabled.
# Usage: bash ci/run_vip_coverage.sh
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

COV_WORKDIR="$REPO_ROOT/build/coverage"
mkdir -p "$COV_WORKDIR"

ALL_TESTS=(
  smoke_tdc
  smoke_position
  smoke_switching
  tdc_modes
  pos_clusters
  ctrl_reject
  reset_recovery
  bp_stress
  i2c_end_to_end
  long_random
  coverage_walk
)

echo "═══════════════════════════════════════════════════════"
echo "  SPADMIC TOP — VIP Coverage Regression"
echo "  Tests: ${#ALL_TESTS[@]}"
echo "═══════════════════════════════════════════════════════"

PASS=0
FAIL=0
FAILED_LIST=()

for test in "${ALL_TESTS[@]}"; do
  echo ""
  echo "─── Coverage Run: $test ────────────────────────────"
  if bash "$REPO_ROOT/scripts/sim/run_vip_test.sh" "$test" \
       --func-cov --code-cov \
       --cov-workdir "$COV_WORKDIR" \
       --cov-test-name "$test"; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    FAILED_LIST+=("$test")
  fi
done

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  COVERAGE REGRESSION: $PASS pass, $FAIL fail / ${#ALL_TESTS[@]} total"
if [[ $FAIL -gt 0 ]]; then
  echo "  Failed: ${FAILED_LIST[*]}"
fi
echo "═══════════════════════════════════════════════════════"

# Merge coverage
echo ""
echo "─── Merging coverage ─────────────────────────────────"
bash "$REPO_ROOT/scripts/sim/report_coverage.sh" "$COV_WORKDIR" "$REPO_ROOT/build/coverage_report"

[[ $FAIL -eq 0 ]] && exit 0 || exit 1
