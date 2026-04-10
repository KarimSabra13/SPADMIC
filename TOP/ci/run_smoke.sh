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

# ── Step 1: Xcelium compile check ──────────────────────────────
echo ""
echo "─── Step 1: Compile check ────────────────────────────"
BUILD_DIR="$REPO_ROOT/build/smoke_compile"
mkdir -p "$BUILD_DIR"

xrun -64 -sv -compile \
  -timescale 1ps/1ps \
  -nowarn DLCVAR \
  +define+MPTDC_USE_OSC_MODEL \
  -f "$MPTDC_ROOT/rtl/filelist.f" \
  -f "$REPO_ROOT/filelist.f" \
  -xmlibdirname "$BUILD_DIR/xcelium.d" \
  2>&1 | tee "$BUILD_DIR/compile.log"

if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
  echo "  ✓ Compile PASS"
  PASS=$((PASS + 1))
else
  echo "  ✗ Compile FAIL"
  FAIL=$((FAIL + 1))
fi

# ── Step 2: First directed bench ───────────────────────────────
echo ""
echo "─── Step 2: Directed bench (stress_csr) ──────────────"
if bash "$REPO_ROOT/scripts/sim/run_tb.sh" tb_spadmic_stress_csr --sim xrun; then
  PASS=$((PASS + 1))
else
  FAIL=$((FAIL + 1))
fi

# ── Summary ────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════════"
echo "  SMOKE RESULT: $PASS pass, $FAIL fail"
echo "═══════════════════════════════════════════════════════"

[[ $FAIL -eq 0 ]] && exit 0 || exit 1
