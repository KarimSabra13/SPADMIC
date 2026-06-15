#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Purpose : Run the fast lint-plus-single-bench smoke flow for MPTDC.
# Usage   : bash ci/run_smoke.sh
# Context : Quick local sanity check built around tb_axis_core_product_smoke and the
#           shared scripts/sim/run_tb.sh runner.
# Author  : Karim Sabra
# -----------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RUNNER="$ROOT/scripts/sim/run_tb.sh"

PASS=0
FAIL=0
TOTAL=0

run_test() {
    local tb="$1"
    TOTAL=$((TOTAL + 1))
    echo "=== [$TOTAL] Running $tb ==="
    if bash "$RUNNER" "$tb" 2>&1 | tail -3; then
        PASS=$((PASS + 1))
    else
        FAIL=$((FAIL + 1))
        echo "!!! FAILED: $tb !!!"
    fi
    echo ""
}

echo "============================================"
echo "  MPTDC v2.7 Smoke Test Suite"
echo "============================================"
echo ""

# Step 1: Lint
echo "=== Lint check ==="
cd "$ROOT"
verilator --lint-only --timing -Wall \
  -Wno-UNUSEDSIGNAL -Wno-UNDRIVEN -Wno-DECLFILENAME -Wno-WIDTHEXPAND \
  -Wno-WIDTHTRUNC -Wno-UNUSEDPARAM -Wno-PINMISSING -Wno-UNUSEDGENVAR \
  -Wno-CASEINCOMPLETE -Wno-LATCH -Wno-REALCVT -Wno-INITIALDLY -Wno-COMBDLY \
  -Wno-PINCONNECTEMPTY -Wno-SYNCASYNCNET -Wno-UNOPTFLAT \
  +define+MPTDC_USE_OSC_MODEL -f rtl/filelist.f --top-module mptdc_axis_core
echo "=== Lint PASSED ==="
echo ""

# Step 2: Product axis integration test
run_test tb_axis_core_product_smoke

# Step 3: Summary
echo "============================================"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
echo "============================================"

if [ "$FAIL" -gt 0 ]; then
    echo "SMOKE FAILED"
    exit 1
fi

echo "SMOKE PASSED"
exit 0
