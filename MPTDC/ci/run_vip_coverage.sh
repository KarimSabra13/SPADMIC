#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Purpose : Report retirement of the standalone MPTDC VIP coverage regression.
# -----------------------------------------------------------------------------
set -euo pipefail

cat >&2 <<'MSG'
ERROR: the standalone MPTDC VIP coverage regression was retired by the
product-only mptdc_axis_core cleanup.

Use the maintained product checks instead:
  bash MPTDC/ci/run_smoke.sh
  bash MPTDC/ci/run_full_regression.sh
  bash MPTDC/scripts/sim/run_tb.sh tb_axis_core_product_smoke --sim verilator
MSG
exit 2
