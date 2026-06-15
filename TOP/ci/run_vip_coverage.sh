#!/usr/bin/env bash
# =============================================================================
# SPADMIC TOP — Retired VIP Coverage Entry Point
# =============================================================================
set -euo pipefail

cat >&2 <<'MSG'
ERROR: the standalone TOP VIP coverage suite was retired by the product-only
mptdc_axis_core cleanup.

Use the maintained product checks instead:
  bash TOP/ci/run_tapeout_readiness.sh
  bash TOP/scripts/sim/run_tb.sh tb_spadmic_arb_modes --sim verilator
  bash TOP/scripts/sim/run_tb.sh tb_spadmic_arb_stress --sim verilator
MSG
exit 2
