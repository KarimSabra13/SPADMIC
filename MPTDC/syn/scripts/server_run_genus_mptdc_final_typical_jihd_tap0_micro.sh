#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RUN_ID="${1:-final_typical_genus_jihd_tap0_micro_$(date +%Y%m%d_%H%M%S)}"

export MPTDC_STABLE_CLOSURE_LABEL="${MPTDC_STABLE_CLOSURE_LABEL:-MPTDC_FINAL_TYPICAL_GENUS_REPAIR_JIHD_TAP0_MICRO}"
export MPTDC_STDCELL_FAMILY=JIHD
export PDK_ROOT="${PDK_ROOT:-/eda/pdk/xfab/xh018}"
export SC_ROOT="${SC_ROOT:-$PDK_ROOT/diglibs/D_CELLS_JIHD/v6_0}"
export MPTDC_STDCELL_SITE="${MPTDC_STDCELL_SITE:-core_jihd}"

if [[ -n "${MPTDC_STDCELL_LEF:-}" && ! -f "$MPTDC_STDCELL_LEF" ]]; then
  echo "WARN: ignoring nonexistent MPTDC_STDCELL_LEF=$MPTDC_STDCELL_LEF"
  unset MPTDC_STDCELL_LEF
fi
if [[ -n "${MPTDC_STDCELL_TC_LIB:-}" && ! -f "$MPTDC_STDCELL_TC_LIB" ]]; then
  echo "WARN: ignoring nonexistent MPTDC_STDCELL_TC_LIB=$MPTDC_STDCELL_TC_LIB"
  unset MPTDC_STDCELL_TC_LIB
fi
if [[ -z "${MPTDC_STDCELL_LEF:-}" ]]; then
  for candidate in \
    "$SC_ROOT/LEF/v6_0_0/xh018/xh018_D_CELLS_JIHD.lef" \
    "$SC_ROOT/LEF/v6_0_0/xh018_D_CELLS_JIHD.lef"; do
    if [[ -f "$candidate" ]]; then
      export MPTDC_STDCELL_LEF="$candidate"
      break
    fi
  done
fi
if [[ -z "${MPTDC_STDCELL_LEF:-}" && -d "$SC_ROOT/LEF/v6_0_0" ]]; then
  found_lef="$(
    find "$SC_ROOT/LEF/v6_0_0" -maxdepth 3 -type f \
      \( -name 'xh018_D_CELLS_JIHD.lef' -o -name '*D_CELLS_JIHD*.lef' \) \
      ! -name '*mprobe*' 2>/dev/null | sort | head -n 1 || true
  )"
  if [[ -n "$found_lef" ]]; then
    export MPTDC_STDCELL_LEF="$found_lef"
  fi
fi
export MPTDC_STDCELL_LEF="${MPTDC_STDCELL_LEF:-$SC_ROOT/LEF/v6_0_0/xh018_D_CELLS_JIHD.lef}"

if [[ -z "${MPTDC_STDCELL_TC_LIB:-}" ]]; then
  export MPTDC_STDCELL_TC_LIB="$SC_ROOT/liberty_LPMOS/v6_0_0/PVT_1_80V_range/D_CELLS_JIHD_LPMOS_typ_1_80V_25C.lib"
fi

export MPTDC_GENUS_REPAIR_FAST_TAG_PD=1
export MPTDC_GENUS_REPAIR_DRV_TRANSITION=0
export MPTDC_GENUS_REPAIR_STRONG_FAST_TAG_FLOPS=0
export MPTDC_GENUS_REPAIR_STRONG_CONTROL_DRV=0
export MPTDC_GENUS_REPAIR_CONTROL_CELL_BIAS_STAGE=none
export MPTDC_GENUS_REPAIR_CONTROL_AVOID_INHDX8=0
export MPTDC_GENUS_REPAIR_EXACT_CONTROL_ROOTS=0
export MPTDC_FAST_TAG_REPAIR_APPLY_Q_CONSTRAINTS=0
export MPTDC_GENUS_REPAIR_APPLY_BROAD_CONTROL_NETS=0
export MPTDC_GENUS_RELAX_FAST_TAG_PRESERVE=0
export MPTDC_GENUS_REPAIR_APPLY_DESIGN_DRV=0
export MPTDC_DESIGN_POWER_EFFORT="${MPTDC_DESIGN_POWER_EFFORT:-none}"

export MPTDC_FAST_TAG_REPAIR_EXACT_DATA_PATHS=1
export MPTDC_FAST_TAG_REPAIR_EXACT_TAPS="${MPTDC_FAST_TAG_REPAIR_EXACT_TAPS:-0}"
export MPTDC_FAST_TAG_REPAIR_EXACT_BITS="${MPTDC_FAST_TAG_REPAIR_EXACT_BITS:-5 6}"
export MPTDC_FAST_TAG_REPAIR_EXACT_MAX_FANOUT="${MPTDC_FAST_TAG_REPAIR_EXACT_MAX_FANOUT:-4}"
export MPTDC_FAST_TAG_REPAIR_EXACT_MAX_TRANSITION_NS="${MPTDC_FAST_TAG_REPAIR_EXACT_MAX_TRANSITION_NS:-0.35}"
export MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_NS="${MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_NS:-}"

echo "# MPTDC Final Typical Genus JIHD Tap0 Micro Repair"
echo "Run mode: $MPTDC_STABLE_CLOSURE_LABEL"
echo "Standard-cell family: $MPTDC_STDCELL_FAMILY"
echo "PDK root: $PDK_ROOT"
echo "Standard-cell root: $SC_ROOT"
echo "Standard-cell site: $MPTDC_STDCELL_SITE"
echo "Standard-cell LEF: $MPTDC_STDCELL_LEF"
echo "Standard-cell TC Liberty: $MPTDC_STDCELL_TC_LIB"
echo "DRV repair shell: $MPTDC_GENUS_REPAIR_DRV_TRANSITION"
echo "Broad fast-tag Q constraints: $MPTDC_FAST_TAG_REPAIR_APPLY_Q_CONSTRAINTS"
echo "Broad control repair: $MPTDC_GENUS_REPAIR_APPLY_BROAD_CONTROL_NETS"
echo "Exact fast-tag data-path repair: $MPTDC_FAST_TAG_REPAIR_EXACT_DATA_PATHS"
echo "Exact fast-tag taps: $MPTDC_FAST_TAG_REPAIR_EXACT_TAPS"
echo "Exact fast-tag bits: $MPTDC_FAST_TAG_REPAIR_EXACT_BITS"
echo "Exact fast-tag max fanout: $MPTDC_FAST_TAG_REPAIR_EXACT_MAX_FANOUT"
echo "Exact fast-tag max transition ns: $MPTDC_FAST_TAG_REPAIR_EXACT_MAX_TRANSITION_NS"
echo "Exact fast-tag optional max-delay ns: ${MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_NS:-unset}"

exec "$SCRIPT_DIR/server_run_genus_mptdc_final_typical_repair.sh" "$RUN_ID"
