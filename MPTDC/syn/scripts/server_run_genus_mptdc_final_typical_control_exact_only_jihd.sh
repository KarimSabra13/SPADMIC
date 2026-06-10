#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RUN_ID="${1:-final_typical_genus_control_exact_only_jihd_$(date +%Y%m%d_%H%M%S)}"

export MPTDC_STABLE_CLOSURE_LABEL="${MPTDC_STABLE_CLOSURE_LABEL:-MPTDC_FINAL_TYPICAL_GENUS_REPAIR_CONTROL_EXACT_ONLY_JIHD}"
export MPTDC_STDCELL_FAMILY=JIHD
export PDK_ROOT="${PDK_ROOT:-/eda/pdk/xfab/xh018}"
export SC_ROOT="${SC_ROOT:-$PDK_ROOT/diglibs/D_CELLS_JIHD/v6_0}"
export MPTDC_STDCELL_SITE="${MPTDC_STDCELL_SITE:-core_jihd}"
export MPTDC_STDCELL_LEF="${MPTDC_STDCELL_LEF:-$SC_ROOT/LEF/v6_0_0/xh018/xh018_D_CELLS_JIHD.lef}"
export MPTDC_STDCELL_TC_LIB="${MPTDC_STDCELL_TC_LIB:-$SC_ROOT/liberty_LPMOS/v6_0_0/PVT_1_80V_range/D_CELLS_JIHD_LPMOS_typ_1_80V_25C.lib}"

echo "# MPTDC Final Typical Genus Exact Control Root Only Repair - JIHD"
echo "Run mode: FINAL_TYPICAL_GENUS_REPAIR_CONTROL_EXACT_ONLY_JIHD"
echo "Standard-cell family: $MPTDC_STDCELL_FAMILY"
echo "PDK root: $PDK_ROOT"
echo "Standard-cell root: $SC_ROOT"
echo "Standard-cell site: $MPTDC_STDCELL_SITE"
echo "Standard-cell LEF: $MPTDC_STDCELL_LEF"
echo "Standard-cell TC Liberty: $MPTDC_STDCELL_TC_LIB"

exec "$SCRIPT_DIR/server_run_genus_mptdc_final_typical_control_exact_only.sh" "$RUN_ID"
