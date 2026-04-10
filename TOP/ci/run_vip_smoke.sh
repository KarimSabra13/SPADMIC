#!/usr/bin/env bash
# =============================================================================
# SPADMIC TOP — VIP Smoke Suite
# Runs the 3 smoke tests (TDC, Position, Switching) without coverage.
# Usage: bash ci/run_vip_smoke.sh
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SMOKE_TESTS=(
  smoke_tdc
  smoke_position
  smoke_switching
)

echo "═══════════════════════════════════════════════════════"
echo "  SPADMIC TOP — VIP Smoke Suite"
echo "═══════════════════════════════════════════════════════"

PASS=0
FAIL=0

for test in "${SMOKE_TESTS[@]}"; do
  echo ""
  echo "─── VIP Smoke: $test ───────────────────────────────"
  if bash "$REPO_ROOT/scripts/sim/run_vip_test.sh" "$test"; then
    ((PASS++))
  else
    ((FAIL++))
  fi
done

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  VIP SMOKE: $PASS pass, $FAIL fail / ${#SMOKE_TESTS[@]} total"
echo "═══════════════════════════════════════════════════════"

[[ $FAIL -eq 0 ]] && exit 0 || exit 1
