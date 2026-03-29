#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Purpose : Run the active top-level lint pass and full integration regression
#           suite for MPTDC sanity checks.
# Usage   : bash ci/run_full_regression.sh
# Context : Local/CI helper that delegates each integration bench to
#           scripts/sim/run_tb.sh.
# Author  : Karim Sabra
# -----------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RUNNER="$ROOT/scripts/sim/run_tb.sh"

PASS=0
FAIL=0
TOTAL=0
FAILED_LIST=""

run_test() {
    local tb="$1"
    TOTAL=$((TOTAL + 1))
    echo "=== [$TOTAL] Running $tb ==="
    if bash "$RUNNER" "$tb" 2>&1 | tail -5; then
        PASS=$((PASS + 1))
        echo "--- $tb: PASSED ---"
    else
        FAIL=$((FAIL + 1))
        FAILED_LIST="$FAILED_LIST $tb"
        echo "!!! $tb: FAILED !!!"
    fi
    echo ""
}

echo "============================================"
echo "  MPTDC v2.2 Full Regression Suite"
echo "============================================"
echo ""

# Lint
echo "=== Lint check ==="
cd "$ROOT"
verilator --lint-only --timing -Wall \
  -Wno-UNUSEDSIGNAL -Wno-UNDRIVEN -Wno-DECLFILENAME -Wno-WIDTHEXPAND \
  -Wno-WIDTHTRUNC -Wno-UNUSEDPARAM -Wno-PINMISSING -Wno-UNUSEDGENVAR \
  -Wno-CASEINCOMPLETE -Wno-LATCH -Wno-REALCVT -Wno-INITIALDLY -Wno-COMBDLY \
  -Wno-PINCONNECTEMPTY -Wno-SYNCASYNCNET -Wno-UNOPTFLAT \
  +define+MPTDC_USE_OSC_MODEL -f rtl/filelist.f --top-module mptdc_top_asic
echo "=== Lint PASSED ==="
echo ""

# Integration tests
INTEGRATION_TBS=(
    tb_single_conv
    tb_multi_conv_stress
    tb_deadtime_measure
    tb_cal_inject
    tb_backpressure
    tb_watchdog_recovery
    tb_start_wdt
    tb_overflow_count
    tb_firsthit_mode
)

for tb in "${INTEGRATION_TBS[@]}"; do
    if [ -f "$ROOT/tb/int/${tb}.sv" ]; then
        run_test "$tb"
    else
        echo "=== SKIP $tb (not found) ==="
        echo ""
    fi
done

# Summary
echo "============================================"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
if [ -n "$FAILED_LIST" ]; then
    echo "  Failed:$FAILED_LIST"
fi
echo "============================================"

if [ "$FAIL" -gt 0 ]; then
    echo "REGRESSION FAILED"
    exit 1
fi

echo "REGRESSION PASSED"
exit 0
