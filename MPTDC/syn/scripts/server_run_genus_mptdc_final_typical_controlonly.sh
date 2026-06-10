#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RUN_ID="${1:-final_typical_genus_control_only_$(date +%Y%m%d_%H%M%S)}"

export MPTDC_STABLE_CLOSURE_LABEL="${MPTDC_STABLE_CLOSURE_LABEL:-MPTDC_FINAL_TYPICAL_GENUS_REPAIR_CONTROL_ONLY}"
export MPTDC_GENUS_REPAIR_FAST_TAG_PD="${MPTDC_GENUS_REPAIR_FAST_TAG_PD:-1}"
export MPTDC_GENUS_REPAIR_DRV_TRANSITION="${MPTDC_GENUS_REPAIR_DRV_TRANSITION:-1}"
export MPTDC_GENUS_REPAIR_STRONG_FAST_TAG_FLOPS=0
export MPTDC_GENUS_REPAIR_STRONG_CONTROL_DRV=1
export MPTDC_GENUS_RELAX_FAST_TAG_PRESERVE=0
export MPTDC_GENUS_REPAIR_APPLY_DESIGN_DRV=0
export MPTDC_DESIGN_POWER_EFFORT="${MPTDC_DESIGN_POWER_EFFORT:-none}"

echo "# MPTDC Final Typical Genus Control-Only Repair"
echo "Run mode: FINAL_TYPICAL_GENUS_REPAIR_CONTROL_ONLY"
echo "Strong control driver bias: $MPTDC_GENUS_REPAIR_STRONG_CONTROL_DRV"
echo "Strong fast-tag flop bias: $MPTDC_GENUS_REPAIR_STRONG_FAST_TAG_FLOPS"
echo "Relax fast-tag preserve define: $MPTDC_GENUS_RELAX_FAST_TAG_PRESERVE"
echo "Design-wide DRV repair: $MPTDC_GENUS_REPAIR_APPLY_DESIGN_DRV"

exec "$SCRIPT_DIR/server_run_genus_mptdc_final_typical_repair.sh" "$RUN_ID"
