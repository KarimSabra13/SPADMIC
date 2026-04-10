#!/usr/bin/env bash
# =============================================================================
# SPADMIC TOP — All Directed Benches Regression
# Usage: bash ci/run_directed_regression.sh
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

BENCHES=(
  tb_spadmic_axis_cluster_scan_unit
  tb_spadmic_i2c_control_plane_unit
  tb_spadmic_ref_stop_qualifier_hold_unit
  tb_spadmic_ref_stop_qualifier_unit
  tb_spadmic_shared_tx_mux_unit
  tb_spadmic_stress_arbiter
  tb_spadmic_stress_cluster_scan
  tb_spadmic_stress_csr
  tb_spadmic_stress_position
  tb_spadmic_stress_stop_qualifier
  tb_spadmic_tdc_arbiter3_unit
  tb_spadmic_tdc_shared_readout_unit
  tb_spadmic_top_sequencer_unit
)

echo "═══════════════════════════════════════════════════════"
echo "  SPADMIC TOP — Directed Bench Regression"
echo "  Benches: ${#BENCHES[@]}"
echo "═══════════════════════════════════════════════════════"

PASS=0
FAIL=0
FAILED_LIST=()

for tb in "${BENCHES[@]}"; do
  echo ""
  echo "─── Running: $tb ───────────────────────────────────"
  if bash "$REPO_ROOT/scripts/sim/run_tb.sh" "$tb" --sim xrun; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    FAILED_LIST+=("$tb")
  fi
done

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  DIRECTED REGRESSION: $PASS pass, $FAIL fail / ${#BENCHES[@]} total"
if [[ $FAIL -gt 0 ]]; then
  echo "  Failed: ${FAILED_LIST[*]}"
fi
echo "═══════════════════════════════════════════════════════"

[[ $FAIL -eq 0 ]] && exit 0 || exit 1
