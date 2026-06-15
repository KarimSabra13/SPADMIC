#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Purpose : Report retirement of the standalone MPTDC VIP harness.
# Usage   : bash scripts/sim/run_vip_test.sh <test_name>
# Context : The product-only cleanup removed the standalone CSR/readout top and
#           its VIP harness. Use the product axis smoke/regression flows instead.
# -----------------------------------------------------------------------------

set -euo pipefail

cat >&2 <<'MSG'
ERROR: the standalone MPTDC VIP harness was retired by the product-only
mptdc_axis_core cleanup.

Use one of the maintained product flows:
  bash MPTDC/ci/run_smoke.sh
  bash MPTDC/ci/run_full_regression.sh
  bash MPTDC/scripts/sim/run_tb.sh tb_axis_core_product_smoke --sim verilator
MSG
exit 2
