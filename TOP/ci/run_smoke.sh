#!/usr/bin/env bash
# =============================================================================
# SPADMIC TOP — Smoke Check (Lint + First Directed Bench)
# Usage: bash ci/run_smoke.sh
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_ROOT="$(cd "$REPO_ROOT/../MPTDC" 2>/dev/null && pwd || echo "$REPO_ROOT/../MPTDC")"

echo "═══════════════════════════════════════════════════════"
echo "  SPADMIC TOP — Smoke Check"
echo "═══════════════════════════════════════════════════════"

PASS=0
FAIL=0

run_step() {
  local name="$1"
  shift
  echo ""
  echo "─── $name ─────────────────────────────────────────"
  if "$@"; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
  fi
}

if command -v verilator >/dev/null 2>&1; then
  SIM=verilator
elif command -v xrun >/dev/null 2>&1; then
  SIM=xrun
else
  echo "ERROR: neither verilator nor xrun is available" >&2
  exit 2
fi

run_step "Generated CSR map drift" bash "$REPO_ROOT/ci/check_csr_map_generated.sh"
run_step "CSR ABI unit ($SIM)" \
  bash "$REPO_ROOT/scripts/sim/run_tb.sh" tb_spadmic_matrix_top_csr_unit --sim "$SIM"
run_step "I2C matrix-top ABI unit ($SIM)" \
  bash "$REPO_ROOT/scripts/sim/run_tb.sh" tb_spadmic_i2c_matrix_top_16b_unit --sim "$SIM"

# ── Summary ────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════════"
echo "  SMOKE RESULT: $PASS pass, $FAIL fail"
echo "═══════════════════════════════════════════════════════"

[[ $FAIL -eq 0 ]] && exit 0 || exit 1
