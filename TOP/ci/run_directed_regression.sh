#!/usr/bin/env bash
# =============================================================================
# SPADMIC TOP — All Directed Benches Regression
# Usage: bash ci/run_directed_regression.sh
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ -n "${SPADMIC_SIM:-}" ]]; then
  SIM="$SPADMIC_SIM"
elif command -v xrun >/dev/null 2>&1; then
  SIM=xrun
else
  SIM=verilator
fi

BENCHES=(
  tb_spadmic_axis_cluster_scan_unit
  tb_spadmic_arb_modes
  tb_spadmic_arb_stress
  tb_spadmic_ddr_tx_unit
  tb_spadmic_i2c_control_plane_unit
  tb_spadmic_i2c_matrix_top_16b_unit
  tb_spadmic_matrix_snapshot_frontend_unit
  tb_spadmic_position_snapshot_packetizer_unit
  tb_spadmic_event_bundle_tx_unit
  tb_spadmic_tx_src_data_flat_mapping_unit
  tb_spadmic_tx_egress_cluster_unit
  tb_spadmic_tx_egress_core_unit
  tb_spadmic_matrix_top_csr_unit
  tb_spadmic_top_matrix_v1_shell_unit
  tb_spadmic_ref_stop_qualifier_hold_unit
  tb_spadmic_ref_stop_qualifier_unit
  tb_spadmic_stress_cluster_scan
  tb_spadmic_stress_position
  tb_spadmic_stress_stop_qualifier
  tb_spadmic_top_sequencer_unit
)

echo "═══════════════════════════════════════════════════════"
echo "  SPADMIC TOP — Directed Bench Regression"
echo "  Simulator: $SIM"
echo "  Benches: ${#BENCHES[@]}"
echo "═══════════════════════════════════════════════════════"

PASS=0
FAIL=0
FAILED_LIST=()

for tb in "${BENCHES[@]}"; do
  echo ""
  echo "─── Running: $tb ───────────────────────────────────"
  if bash "$REPO_ROOT/scripts/sim/run_tb.sh" "$tb" --sim "$SIM"; then
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
