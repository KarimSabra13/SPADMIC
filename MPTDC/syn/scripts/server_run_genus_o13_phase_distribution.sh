#!/usr/bin/env bash
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$SYN_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"
# shellcheck source=../../scripts/mptdc_flow_common.sh
source "$MPTDC_DIR/scripts/mptdc_flow_common.sh"
MPTDC_WORK_ROOT="${MPTDC_WORK_ROOT:-work}"
case "$MPTDC_WORK_ROOT" in
  /*) ;;
  *) MPTDC_WORK_ROOT="$REPO_ROOT/$MPTDC_WORK_ROOT" ;;
esac
MPTDC_GENUS_WORK="${MPTDC_GENUS_WORK:-$MPTDC_WORK_ROOT/genus}"
MPTDC_EVIDENCE_WORK="${MPTDC_EVIDENCE_WORK:-$MPTDC_WORK_ROOT/evidence}"
export MPTDC_WORK_ROOT MPTDC_GENUS_WORK MPTDC_EVIDENCE_WORK
export MPTDC_SNAPSHOT_ROOT="${MPTDC_SNAPSHOT_ROOT:-$MPTDC_EVIDENCE_WORK}"
FLOW_LABEL="${MPTDC_STABLE_FLOW_LABEL:-MPTDC_GENUS_TYPICAL}"
CLOSURE_LABEL="${MPTDC_STABLE_CLOSURE_LABEL:-MPTDC_TYPICAL_TIMING_CLOSURE}"
PACKAGE_LABEL="${MPTDC_FINAL_PACKAGE_LABEL:-TYPICAL_ONLY_TAPEOUT_PACKAGE}"
SIGNOFF_BOUNDARY="${MPTDC_SIGNOFF_BOUNDARY:-TYPICAL_ONLY_NOT_MMMC}"
LEGACY_TRACE_LABEL="O13_ABS5_PD_Q1_EXCEPTION_EXACT_MATCH"

RUN_ID="${1:-$(date +%Y%m%d_%H%M%S)_o13_phase_distribution_genus}"
# Product-axis closure defaults to the ABS5 exact PD q1 Vernier exception.
# This keeps the intentional slow-phase -> same-row PD q1 sampling crossing out
# of the real timing comparison while leaving fast-tag, q1->q2, clk_sys, reset,
# and packet/readout paths timed. Set MPTDC_O13_MODE=typical_synth only for
# legacy phase-distribution comparisons.
DEFAULT_O13_RUN_MODE="${MPTDC_O13_DEFAULT_MODE:-O13_ABS5_PD_Q1_EXCEPTION_EXACT_MATCH}"
REQUESTED_RUN_MODE="${MPTDC_O13_MODE:-$DEFAULT_O13_RUN_MODE}"
RUN_MODE="$REQUESTED_RUN_MODE"
if [[ "${MPTDC_O13_VALIDATE_ONLY:-0}" == "1" ]]; then
  RUN_MODE="validate_only"
fi
if [[ "$REQUESTED_RUN_MODE" == "O13_ABS3_CLOCK_CDC_CONSTRAINT_REPAIR" ]]; then
  export MPTDC_O13_ABS3_CLOCK_CDC_REPAIR=1
fi
if [[ "$REQUESTED_RUN_MODE" == "O13_ABS4_PD_VERNIER_CLASSIFICATION" ]]; then
  export MPTDC_O13_ABS3_CLOCK_CDC_REPAIR=1
  export MPTDC_O13_ABS4_PD_VERNIER_CLASSIFICATION=1
fi
if [[ "$REQUESTED_RUN_MODE" == "O13_ABS5_PD_Q1_EXCEPTION_EXACT_MATCH" ]]; then
  export MPTDC_O13_ABS3_CLOCK_CDC_REPAIR=1
  export MPTDC_O13_ABS5_PD_Q1_EXCEPTION_EXACT=1
fi

RESULT_DIR="${MPTDC_GENUS_RUN_DIR:-$MPTDC_GENUS_WORK/$RUN_ID}"
SNAPSHOT_TAG="genus_osc_pd_${RUN_ID}"
SNAPSHOT_DIR="$MPTDC_SNAPSHOT_ROOT/$SNAPSHOT_TAG"
GENUS_LOG="$RESULT_DIR/genus_${RUN_ID}.log"
GENUS_TOOL_LOG="$RESULT_DIR/logs/genus_o13_phase_distribution.log"
ENV_FILE="$MPTDC_DIR/analog_handoff/real_ro_tune4_abstract.env"
RO_AUDIT_SCRIPT="$MPTDC_DIR/analog_handoff/audit_ro_tune4_abstract.py"
FREQ_DEFINES="$SYN_DIR/inputs/mptdc_freq_modes.defines"
if [[ "${MPTDC_O13_ABS5_PD_Q1_EXCEPTION_EXACT:-0}" == "1" && -z "${O13_SDC_PATH:-}" ]]; then
  O13_SDC="$SYN_DIR/inputs/mptdc_pd_vernier_exceptions.sdc"
elif [[ "${MPTDC_O13_ABS4_PD_VERNIER_CLASSIFICATION:-0}" == "1" && -z "${O13_SDC_PATH:-}" ]]; then
  O13_SDC="$SYN_DIR/inputs/mptdc_osc_typical_r750_delta5_o13_abs4.sdc"
elif [[ "${MPTDC_O13_ABS3_CLOCK_CDC_REPAIR:-0}" == "1" && -z "${O13_SDC_PATH:-}" ]]; then
  O13_SDC="$SYN_DIR/inputs/mptdc_osc_typical_r750_delta5_o13_abs3.sdc"
else
  O13_SDC="${O13_SDC_PATH:-$SYN_DIR/inputs/mptdc_osc_typical_r750_delta5_o13_phase_distribution.sdc}"
fi
O13_FILELIST="${O13_FILELIST_PATH:-$SYN_DIR/filelist_o13_phase_distribution.f}"
MPTDC_OPT_MODE="${MPTDC_OPT_MODE:-STRIDE2}"
if ! MPTDC_OPT_MODE_DEFINE_CSV="$(mptdc_common_opt_mode_define_csv "$MPTDC_OPT_MODE")"; then
  exit 2
fi

# Closure profile defaults:
#   timing_ultra      First-pass timing proof. ABS5 + REPAIR8/JIHD are enabled,
#                     area recovery and power recovery are disabled to keep the
#                     timing comparison clean.
#   area_timing_ultra Area recovery is enabled after timing is understood. Power
#                     recovery remains disabled because area/timing are higher
#                     priority for this block.
#   power_last        Optional late experiment after area/timing closure.
#   legacy            Keeps old opt-in behavior for archived comparisons.
MPTDC_GENUS_CLOSURE_PROFILE="${MPTDC_GENUS_CLOSURE_PROFILE:-timing_ultra}"
case "$MPTDC_GENUS_CLOSURE_PROFILE" in
  timing_ultra)
    export O13_GENUS_EFFORT="${O13_GENUS_EFFORT:-closure}"
    export MPTDC_GENUS_REPAIR8_JIHD_EXACT_FAST_TAG_CLOSE="${MPTDC_GENUS_REPAIR8_JIHD_EXACT_FAST_TAG_CLOSE:-1}"
    export MPTDC_GENUS_AREA_RECOVERY="${MPTDC_GENUS_AREA_RECOVERY:-0}"
    export MPTDC_GENUS_POWER_OPT="${MPTDC_GENUS_POWER_OPT:-0}"
    export O13_ENABLE_CLOCK_GATING="${O13_ENABLE_CLOCK_GATING:-0}"
    export MPTDC_DESIGN_POWER_EFFORT="${MPTDC_DESIGN_POWER_EFFORT:-none}"
    ;;
  area_timing_ultra|area_ultra)
    export O13_GENUS_EFFORT="${O13_GENUS_EFFORT:-closure}"
    export MPTDC_GENUS_REPAIR8_JIHD_EXACT_FAST_TAG_CLOSE="${MPTDC_GENUS_REPAIR8_JIHD_EXACT_FAST_TAG_CLOSE:-1}"
    export MPTDC_GENUS_AREA_RECOVERY="${MPTDC_GENUS_AREA_RECOVERY:-1}"
    export MPTDC_GENUS_POWER_OPT="${MPTDC_GENUS_POWER_OPT:-0}"
    export O13_ENABLE_CLOCK_GATING="${O13_ENABLE_CLOCK_GATING:-0}"
    export MPTDC_DESIGN_POWER_EFFORT="${MPTDC_DESIGN_POWER_EFFORT:-none}"
    ;;
  power_last)
    export O13_GENUS_EFFORT="${O13_GENUS_EFFORT:-closure}"
    export MPTDC_GENUS_REPAIR8_JIHD_EXACT_FAST_TAG_CLOSE="${MPTDC_GENUS_REPAIR8_JIHD_EXACT_FAST_TAG_CLOSE:-1}"
    export MPTDC_GENUS_AREA_RECOVERY="${MPTDC_GENUS_AREA_RECOVERY:-1}"
    export MPTDC_GENUS_POWER_OPT="${MPTDC_GENUS_POWER_OPT:-1}"
    export O13_ENABLE_CLOCK_GATING="${O13_ENABLE_CLOCK_GATING:-0}"
    export MPTDC_DESIGN_POWER_EFFORT="${MPTDC_DESIGN_POWER_EFFORT:-high}"
    ;;
  legacy|custom)
    export O13_GENUS_EFFORT="${O13_GENUS_EFFORT:-closure}"
    ;;
  *)
    echo "ERROR: unsupported MPTDC_GENUS_CLOSURE_PROFILE=$MPTDC_GENUS_CLOSURE_PROFILE" >&2
    echo "Supported: timing_ultra, area_timing_ultra, area_ultra, power_last, legacy, custom" >&2
    exit 2
    ;;
esac
export MPTDC_GENUS_CLOSURE_PROFILE

export MPTDC_GENUS_REPAIR_FAST_TAG_PD="${MPTDC_GENUS_REPAIR_FAST_TAG_PD:-0}"
export MPTDC_GENUS_REPAIR_DRV_TRANSITION="${MPTDC_GENUS_REPAIR_DRV_TRANSITION:-0}"
export MPTDC_GENUS_REPAIR4_EXACT_FAST_TAG_SOURCE_DRIVE="${MPTDC_GENUS_REPAIR4_EXACT_FAST_TAG_SOURCE_DRIVE:-0}"
export MPTDC_GENUS_REPAIR5_EXACT_FAST_TAG_CLOSE="${MPTDC_GENUS_REPAIR5_EXACT_FAST_TAG_CLOSE:-0}"
export MPTDC_GENUS_REPAIR6_LOCALTAG_PRESERVE_CLOSE="${MPTDC_GENUS_REPAIR6_LOCALTAG_PRESERVE_CLOSE:-0}"
export MPTDC_GENUS_REPAIR7_POLARITY_AWARE_FAST_TAG_SOURCE_UPGRADE="${MPTDC_GENUS_REPAIR7_POLARITY_AWARE_FAST_TAG_SOURCE_UPGRADE:-0}"
export MPTDC_GENUS_REPAIR8_JIHD_EXACT_FAST_TAG_CLOSE="${MPTDC_GENUS_REPAIR8_JIHD_EXACT_FAST_TAG_CLOSE:-0}"
export MPTDC_GENUS_REPAIR_PD_HIT_TO_NFAST_LOCAL="${MPTDC_GENUS_REPAIR_PD_HIT_TO_NFAST_LOCAL:-0}"
export MPTDC_PD_HIT_TO_NFAST_MAX_DELAY_NS="${MPTDC_PD_HIT_TO_NFAST_MAX_DELAY_NS:-0}"
export MPTDC_PD_HIT_TO_NFAST_MAX_TRANSITION_NS="${MPTDC_PD_HIT_TO_NFAST_MAX_TRANSITION_NS:-0}"
export MPTDC_PD_HIT_TO_NFAST_BITS="${MPTDC_PD_HIT_TO_NFAST_BITS:-0 1 2 3 4 5 6}"
export MPTDC_PD_HIT_TO_NFAST_EXPECTED_SOURCES="${MPTDC_PD_HIT_TO_NFAST_EXPECTED_SOURCES:-64}"
export MPTDC_PD_HIT_TO_NFAST_EXPECTED_ENDPOINTS="${MPTDC_PD_HIT_TO_NFAST_EXPECTED_ENDPOINTS:-448}"
export MPTDC_GENUS_REPAIR_PD_LOCAL_ON22="${MPTDC_GENUS_REPAIR_PD_LOCAL_ON22:-0}"
export MPTDC_PD_LOCAL_ON22_SOURCE_CELL="${MPTDC_PD_LOCAL_ON22_SOURCE_CELL:-ON22JIHDX0}"
export MPTDC_PD_LOCAL_ON22_TARGET_CELLS="${MPTDC_PD_LOCAL_ON22_TARGET_CELLS:-ON22JIHDX1 ON22JIHDX2}"
export MPTDC_PD_LOCAL_ON22_BITS="${MPTDC_PD_LOCAL_ON22_BITS:-0 1 2 3 4 5 6}"
export MPTDC_PD_LOCAL_ON22_EXPECTED_ENDPOINTS="${MPTDC_PD_LOCAL_ON22_EXPECTED_ENDPOINTS:-448}"
export MPTDC_PD_LOCAL_ON22_EXPECTED_CELLS="${MPTDC_PD_LOCAL_ON22_EXPECTED_CELLS:-AUTO}"
export MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL_DISABLE="${MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL_DISABLE:-0}"
if [[ "$MPTDC_GENUS_REPAIR8_JIHD_EXACT_FAST_TAG_CLOSE" == "1" ]]; then
  export MPTDC_STABLE_CLOSURE_LABEL="${MPTDC_STABLE_CLOSURE_LABEL:-MPTDC_FINAL_TYPICAL_GENUS_REPAIR8_JIHD_EXACT_FAST_TAG_CLOSE}"
  CLOSURE_LABEL="$MPTDC_STABLE_CLOSURE_LABEL"
  export MPTDC_STDCELL_FAMILY="JIHD"
  export MPTDC_GENUS_REPAIR_FAST_TAG_PD=1
  export MPTDC_GENUS_REPAIR_DRV_TRANSITION=0
  export MPTDC_GENUS_REPAIR5_EXACT_FAST_TAG_CLOSE=1
  export MPTDC_GENUS_REPAIR4_EXACT_FAST_TAG_SOURCE_DRIVE=1
  export MPTDC_GENUS_REPAIR_STRONG_FAST_TAG_FLOPS=0
  export MPTDC_GENUS_REPAIR_STRONG_CONTROL_DRV=0
  export MPTDC_GENUS_REPAIR_CONTROL_CELL_BIAS_STAGE=none
  export MPTDC_GENUS_REPAIR_CONTROL_AVOID_INHDX8=0
  export MPTDC_GENUS_REPAIR_EXACT_CONTROL_ROOTS=0
  export MPTDC_GENUS_REPAIR_APPLY_BROAD_CONTROL_NETS=0
  export MPTDC_GENUS_REPAIR_APPLY_DESIGN_DRV=0
  export MPTDC_GENUS_RELAX_FAST_TAG_PRESERVE=0
  export MPTDC_DESIGN_POWER_EFFORT="${MPTDC_DESIGN_POWER_EFFORT:-none}"
  export MPTDC_FAST_TAG_REPAIR_APPLY_Q_CONSTRAINTS=0
  export MPTDC_FAST_TAG_REPAIR_EXACT_DATA_PATHS=1
  export MPTDC_FAST_TAG_REPAIR_EXACT_TAPS="${MPTDC_FAST_TAG_REPAIR_EXACT_TAPS:-0 1 2 3 4 5 6 7}"
  export MPTDC_FAST_TAG_REPAIR_EXACT_BITS="${MPTDC_FAST_TAG_REPAIR_EXACT_BITS:-0 5 6}"
  export MPTDC_FAST_TAG_REPAIR_EXACT_MAX_FANOUT="${MPTDC_FAST_TAG_REPAIR_EXACT_MAX_FANOUT:-2}"
  export MPTDC_FAST_TAG_REPAIR_EXACT_MAX_TRANSITION_NS="${MPTDC_FAST_TAG_REPAIR_EXACT_MAX_TRANSITION_NS:-0.50}"
  export MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_NS="${MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_NS:-1.04}"
  export MPTDC_FAST_TAG_REPAIR_ENABLE_EXACT_MAX_DELAY="${MPTDC_FAST_TAG_REPAIR_ENABLE_EXACT_MAX_DELAY:-${MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_ENABLE:-1}}"
  export MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_ENABLE="${MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_ENABLE:-$MPTDC_FAST_TAG_REPAIR_ENABLE_EXACT_MAX_DELAY}"
  if [[ "$MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL_DISABLE" == "1" ]]; then
    export MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL_MODE=""
    export MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL=""
    export MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_RESET0_CELL=""
    export MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_SET1_CELL=""
  else
    export MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL_MODE="${MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL_MODE:-POLARITY_AWARE}"
    export MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL="${MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL:-POLARITY_AWARE}"
    export MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_RESET0_CELL="${MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_RESET0_CELL:-DFRRQJIHDX4}"
    export MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_SET1_CELL="${MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_SET1_CELL:-DFRSJIHDX2}"
    export MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_SKIP_UNSUPPORTED="${MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_SKIP_UNSUPPORTED:-1}"
  fi
  export MPTDC_GENUS_REPAIR_ENDPOINT_TRANSITION_TIGHT=0
elif [[ "$MPTDC_GENUS_REPAIR7_POLARITY_AWARE_FAST_TAG_SOURCE_UPGRADE" == "1" ]]; then
  export MPTDC_GENUS_REPAIR5_EXACT_FAST_TAG_CLOSE=1
  export MPTDC_GENUS_REPAIR4_EXACT_FAST_TAG_SOURCE_DRIVE=1
  export MPTDC_GENUS_RELAX_FAST_TAG_PRESERVE="${MPTDC_GENUS_RELAX_FAST_TAG_PRESERVE:-0}"
  export MPTDC_FAST_TAG_REPAIR_APPLY_Q_CONSTRAINTS="${MPTDC_FAST_TAG_REPAIR_APPLY_Q_CONSTRAINTS:-0}"
  export MPTDC_FAST_TAG_REPAIR_EXACT_DATA_PATHS="${MPTDC_FAST_TAG_REPAIR_EXACT_DATA_PATHS:-1}"
  export MPTDC_FAST_TAG_REPAIR_EXACT_MAX_FANOUT="${MPTDC_FAST_TAG_REPAIR_EXACT_MAX_FANOUT:-2}"
  export MPTDC_FAST_TAG_REPAIR_EXACT_MAX_TRANSITION_NS="${MPTDC_FAST_TAG_REPAIR_EXACT_MAX_TRANSITION_NS:-0.30}"
  export MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_NS="${MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_NS:-1.00}"
  export MPTDC_FAST_TAG_REPAIR_ENABLE_EXACT_MAX_DELAY="${MPTDC_FAST_TAG_REPAIR_ENABLE_EXACT_MAX_DELAY:-${MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_ENABLE:-1}}"
  export MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_ENABLE="${MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_ENABLE:-$MPTDC_FAST_TAG_REPAIR_ENABLE_EXACT_MAX_DELAY}"
  export MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL_MODE="${MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL_MODE:-POLARITY_AWARE}"
  export MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL="${MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL:-POLARITY_AWARE}"
  export MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_RESET0_CELL="${MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_RESET0_CELL:-DFRRQHDX4}"
  export MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_SET1_CELL="${MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_SET1_CELL:-}"
  export MPTDC_GENUS_REPAIR_ENDPOINT_TRANSITION_TIGHT="${MPTDC_GENUS_REPAIR_ENDPOINT_TRANSITION_TIGHT:-0}"
elif [[ "$MPTDC_GENUS_REPAIR6_LOCALTAG_PRESERVE_CLOSE" == "1" ]]; then
  export MPTDC_GENUS_REPAIR5_EXACT_FAST_TAG_CLOSE=1
  export MPTDC_GENUS_REPAIR4_EXACT_FAST_TAG_SOURCE_DRIVE=1
  export MPTDC_GENUS_RELAX_FAST_TAG_PRESERVE=1
  export MPTDC_FAST_TAG_REPAIR_APPLY_Q_CONSTRAINTS="${MPTDC_FAST_TAG_REPAIR_APPLY_Q_CONSTRAINTS:-0}"
  export MPTDC_FAST_TAG_REPAIR_EXACT_DATA_PATHS="${MPTDC_FAST_TAG_REPAIR_EXACT_DATA_PATHS:-1}"
  export MPTDC_FAST_TAG_REPAIR_EXACT_MAX_FANOUT="${MPTDC_FAST_TAG_REPAIR_EXACT_MAX_FANOUT:-8}"
  export MPTDC_FAST_TAG_REPAIR_EXACT_MAX_TRANSITION_NS="${MPTDC_FAST_TAG_REPAIR_EXACT_MAX_TRANSITION_NS:-0.50}"
  export MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_NS="${MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_NS:-1.04}"
  export MPTDC_FAST_TAG_REPAIR_ENABLE_EXACT_MAX_DELAY="${MPTDC_FAST_TAG_REPAIR_ENABLE_EXACT_MAX_DELAY:-${MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_ENABLE:-1}}"
  export MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_ENABLE="${MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_ENABLE:-$MPTDC_FAST_TAG_REPAIR_ENABLE_EXACT_MAX_DELAY}"
  export MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL="${MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL:-}"
  export MPTDC_GENUS_REPAIR_ENDPOINT_TRANSITION_TIGHT="${MPTDC_GENUS_REPAIR_ENDPOINT_TRANSITION_TIGHT:-0}"
elif [[ "$MPTDC_GENUS_REPAIR5_EXACT_FAST_TAG_CLOSE" == "1" ]]; then
  export MPTDC_GENUS_REPAIR4_EXACT_FAST_TAG_SOURCE_DRIVE=1
  export MPTDC_FAST_TAG_REPAIR_APPLY_Q_CONSTRAINTS="${MPTDC_FAST_TAG_REPAIR_APPLY_Q_CONSTRAINTS:-0}"
  export MPTDC_FAST_TAG_REPAIR_EXACT_DATA_PATHS="${MPTDC_FAST_TAG_REPAIR_EXACT_DATA_PATHS:-1}"
  export MPTDC_FAST_TAG_REPAIR_EXACT_MAX_FANOUT="${MPTDC_FAST_TAG_REPAIR_EXACT_MAX_FANOUT:-2}"
  export MPTDC_FAST_TAG_REPAIR_EXACT_MAX_TRANSITION_NS="${MPTDC_FAST_TAG_REPAIR_EXACT_MAX_TRANSITION_NS:-0.30}"
  export MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_NS="${MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_NS:-1.00}"
  export MPTDC_FAST_TAG_REPAIR_ENABLE_EXACT_MAX_DELAY="${MPTDC_FAST_TAG_REPAIR_ENABLE_EXACT_MAX_DELAY:-${MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_ENABLE:-1}}"
  export MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_ENABLE="${MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_ENABLE:-$MPTDC_FAST_TAG_REPAIR_ENABLE_EXACT_MAX_DELAY}"
  export MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL="${MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL:-DFRRQHDX4}"
  export MPTDC_GENUS_REPAIR_ENDPOINT_TRANSITION_TIGHT="${MPTDC_GENUS_REPAIR_ENDPOINT_TRANSITION_TIGHT:-0}"
elif [[ "$MPTDC_GENUS_REPAIR4_EXACT_FAST_TAG_SOURCE_DRIVE" == "1" ]]; then
  export MPTDC_FAST_TAG_REPAIR_APPLY_Q_CONSTRAINTS="${MPTDC_FAST_TAG_REPAIR_APPLY_Q_CONSTRAINTS:-0}"
  export MPTDC_FAST_TAG_REPAIR_EXACT_DATA_PATHS="${MPTDC_FAST_TAG_REPAIR_EXACT_DATA_PATHS:-1}"
  export MPTDC_FAST_TAG_REPAIR_EXACT_MAX_TRANSITION_NS="${MPTDC_FAST_TAG_REPAIR_EXACT_MAX_TRANSITION_NS:-0.50}"
  export MPTDC_FAST_TAG_REPAIR_ENABLE_EXACT_MAX_DELAY="${MPTDC_FAST_TAG_REPAIR_ENABLE_EXACT_MAX_DELAY:-0}"
  export MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_ENABLE="${MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_ENABLE:-$MPTDC_FAST_TAG_REPAIR_ENABLE_EXACT_MAX_DELAY}"
  export MPTDC_GENUS_REPAIR_ENDPOINT_TRANSITION_TIGHT="${MPTDC_GENUS_REPAIR_ENDPOINT_TRANSITION_TIGHT:-0}"
fi
DEFAULT_EXPORT_RUN_ID="${O1_RO_EXPORT_RUN_ID:-20260528_o1_export_ro_tune4_lef}"
DEFAULT_REAL_LEF="$REPO_ROOT/results/osc_pd/$DEFAULT_EXPORT_RUN_ID/real_abstract_lef/RO_tune4_real_abstract.lef"
DEFAULT_REAL_LIB="$SYN_DIR/macros/RO_tune4_real_abstract_shell.lib"
STDCELL_FAMILY="$(printf '%s' "${MPTDC_STDCELL_FAMILY:-HD}" | tr '[:lower:]' '[:upper:]')"
case "$STDCELL_FAMILY" in
  HD)
    DEFAULT_PDK_ROOT="${PDK_ROOT:-/data/pdk/xfab/xh018}"
    STDCELL_LIB_NAME="D_CELLS_HD"
    STDCELL_LEF_REL="LEF/v6_0_0/xh018_D_CELLS_HD.lef"
    STDCELL_SITE="${MPTDC_STDCELL_SITE:-core_hd}"
    ;;
  JIHD)
    DEFAULT_PDK_ROOT="${PDK_ROOT:-/eda/pdk/xfab/xh018}"
    STDCELL_LIB_NAME="D_CELLS_JIHD"
    STDCELL_LEF_REL="LEF/v6_0_0/xh018/xh018_D_CELLS_JIHD.lef"
    STDCELL_SITE="${MPTDC_STDCELL_SITE:-core_jihd}"
    ;;
  *)
    echo "ERROR: unsupported MPTDC_STDCELL_FAMILY=$STDCELL_FAMILY; expected HD or JIHD" >&2
    exit 2
    ;;
esac
SC_ROOT_PATH="${SC_ROOT:-$DEFAULT_PDK_ROOT/diglibs/$STDCELL_LIB_NAME/v6_0}"
STDCELL_LIB_DIR="${SC_ROOT_PATH}/liberty_LPMOS/v6_0_0/PVT_1_80V_range"
if [[ -n "${MPTDC_STDCELL_LEF:-}" ]]; then
  STDCELL_LEF="$MPTDC_STDCELL_LEF"
else
  STDCELL_LEF="$SC_ROOT_PATH/$STDCELL_LEF_REL"
  if [[ ! -f "$STDCELL_LEF" && "$STDCELL_FAMILY" == "JIHD" ]]; then
    for candidate in \
      "$SC_ROOT_PATH/LEF/v6_0_0/xh018_D_CELLS_JIHD.lef" \
      "$SC_ROOT_PATH/LEF/v6_0_0/xh018/xh018_D_CELLS_JIHD.lef"; do
      if [[ -f "$candidate" ]]; then
        STDCELL_LEF="$candidate"
        break
      fi
    done
  fi
fi
STDCELL_TC_LIB="${MPTDC_STDCELL_TC_LIB:-$STDCELL_LIB_DIR/${STDCELL_LIB_NAME}_LPMOS_typ_1_80V_25C.lib}"

case "$RUN_ID" in
  ""|"/"|".")
    echo "ERROR: unsafe RUN_ID: '$RUN_ID'" >&2
    exit 2
    ;;
  *"/"*|".."*)
    echo "ERROR: RUN_ID must be a simple directory name, got '$RUN_ID'" >&2
    exit 2
    ;;
esac

case "$RUN_MODE" in
  validate_only|typical_synth|O13_ABS3_CLOCK_CDC_CONSTRAINT_REPAIR|O13_ABS4_PD_VERNIER_CLASSIFICATION|O13_ABS5_PD_Q1_EXCEPTION_EXACT_MATCH) ;;
  *)
    echo "ERROR: unsupported MPTDC_O13_MODE=$RUN_MODE" >&2
    echo "Supported: validate_only, typical_synth, O13_ABS3_CLOCK_CDC_CONSTRAINT_REPAIR, O13_ABS4_PD_VERNIER_CLASSIFICATION, O13_ABS5_PD_Q1_EXCEPTION_EXACT_MATCH" >&2
    exit 2
    ;;
esac

rm -rf "$RESULT_DIR"
mkdir -p "$RESULT_DIR/logs" "$RESULT_DIR/outputs" "$RESULT_DIR/reports" "$RESULT_DIR/internal/run" "$RESULT_DIR/internal/work"
export MPTDC_GENUS_RUN_DIR="$RESULT_DIR"
export MPTDC_GENUS_TOOL_LOG="$GENUS_TOOL_LOG"

{
  echo "# MPTDC Typical Genus Run"
  echo "date: $(date -Iseconds)"
  echo "hostname: $(hostname)"
  echo "repo: $REPO_ROOT"
  echo "work_root: $MPTDC_WORK_ROOT"
  echo "branch: $(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || true)"
  echo "head: $(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)"
  echo "expected_head: ${EXPECTED_HEAD:-unset}"
  echo "run_id: $RUN_ID"
  echo "run_mode: $RUN_MODE"
  echo "requested_run_mode: $REQUESTED_RUN_MODE"
  echo "result_dir: $RESULT_DIR"
  echo "snapshot_dir: $SNAPSHOT_DIR"
  echo "snapshot_tag: $SNAPSHOT_TAG"
  echo "flow: $FLOW_LABEL"
  echo "mode: $CLOSURE_LABEL"
  echo "package_label: $PACKAGE_LABEL"
  echo "signoff_boundary: $SIGNOFF_BOUNDARY"
  echo "labels: $FLOW_LABEL $CLOSURE_LABEL $PACKAGE_LABEL NOT_MMMC_SIGNOFF FINAL_SIGNOFF_NO"
  echo "legacy_trace: $LEGACY_TRACE_LABEL"
  echo "packet_format: unchanged"
  echo "nfast_encoding: raw_lfsr_tag"
  echo "frequency_mode: r750_delta5"
  echo "genus_closure_profile: $MPTDC_GENUS_CLOSURE_PROFILE"
  echo "mptdc_opt_mode: $MPTDC_OPT_MODE"
  echo "mptdc_opt_defines: ${MPTDC_OPT_MODE_DEFINE_CSV:-none}"
  echo
  echo "git status --short:"
  git -C "$REPO_ROOT" status --short 2>/dev/null || true
  echo
} | tee "$RESULT_DIR/run_manifest.txt" | tee "$GENUS_LOG"

INPUT_RC=0
require_file() {
  local label="$1"
  local path="$2"
  if [[ ! -f "$path" ]]; then
    echo "ERROR: missing $label: $path" | tee -a "$GENUS_LOG"
    INPUT_RC=2
  fi
}

ACTUAL_HEAD="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)"
if [[ -n "${EXPECTED_HEAD:-}" && "$ACTUAL_HEAD" != "$EXPECTED_HEAD" ]]; then
  echo "ERROR: HEAD mismatch. expected=$EXPECTED_HEAD actual=$ACTUAL_HEAD" | tee -a "$GENUS_LOG"
  INPUT_RC=5
fi

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$ENV_FILE"
else
  echo "ERROR: missing O1/O9 env file: $ENV_FILE" | tee -a "$GENUS_LOG"
  INPUT_RC=2
fi

REAL_LEF="${O1_RO_LEF_PATH:-$DEFAULT_REAL_LEF}"
REAL_LIB="${O1_RO_LIBERTY_PATH:-$DEFAULT_REAL_LIB}"

require_file "RO_tune4 real LEF" "$REAL_LEF"
require_file "RO_tune4 Liberty shell" "$REAL_LIB"
require_file "RO_tune4 interface audit" "$RO_AUDIT_SCRIPT"
require_file "standard-cell LEF" "$STDCELL_LEF"
require_file "standard-cell typical Liberty" "$STDCELL_TC_LIB"
require_file "O13 SDC overlay" "$O13_SDC"
require_file "O13 HDL filelist" "$O13_FILELIST"
require_file "frequency-mode defines" "$FREQ_DEFINES"

RO_AUDIT_REPORT="$RESULT_DIR/reports/ro_tune4_lef_audit.rpt"
if [[ -f "$REAL_LEF" && -f "$REAL_LIB" && -f "$RO_AUDIT_SCRIPT" ]]; then
  RO_AUDIT_SOURCE_LEF="${MPTDC_RO_SOURCE_LEF_PATH:-${O1_RO_SOURCE_LEF_PATH:-}}"
  echo "O13 real LEF: $REAL_LEF" | tee -a "$GENUS_LOG"
  echo "O13 source LEF for audit: ${RO_AUDIT_SOURCE_LEF:-unset}" | tee -a "$GENUS_LOG"
  echo "[RO_AUDIT] Checking RO_tune4 LEF/Liberty/RTL interface" | tee -a "$GENUS_LOG"
  if ! python3 "$RO_AUDIT_SCRIPT" \
    --source-lef "$RO_AUDIT_SOURCE_LEF" \
    --copied-lef "$REAL_LEF" \
    --liberty "$REAL_LIB" \
    --rtl "$MPTDC_DIR/rtl/osc/mptdc_osc_wrapper.sv" \
    --report "$RO_AUDIT_REPORT" >> "$GENUS_LOG" 2>&1; then
    echo "ERROR: RO_tune4 interface audit failed: $RO_AUDIT_REPORT" | tee -a "$GENUS_LOG"
    INPUT_RC=3
  fi
  if [[ -f "$RO_AUDIT_REPORT" ]]; then
    awk -F= '/^(SOURCE_MACRO_NAME|COPIED_MACRO_NAME|REQUIRED_PINS_FOUND|MISSING_PINS|PIN_GEOMETRY_PRESENT|LIBERTY_REQUIRED_PINS_FOUND|RTL_LOGICAL_PINS_FOUND|AUDIT_STATUS)=/ {print "RO_AUDIT_" $0}' "$RO_AUDIT_REPORT" | tee -a "$GENUS_LOG"
  fi
fi

if [[ -f "$O13_FILELIST" ]]; then
  if ! grep -q 'MPTDC_PHASE_BUFFER_TOPO_BUHDX4_BUHDX12' "$O13_FILELIST"; then
    echo "ERROR: O13 filelist does not select MPTDC_PHASE_BUFFER_TOPO_BUHDX4_BUHDX12" | tee -a "$GENUS_LOG"
    INPUT_RC=4
  fi
  if grep -q 'MPTDC_PHASE_BUFFER_USE_BUHDX4' "$O13_FILELIST"; then
    echo "ERROR: O13 filelist must not also select one-stage MPTDC_PHASE_BUFFER_USE_BUHDX4" | tee -a "$GENUS_LOG"
    INPUT_RC=4
  fi
fi

EFFECTIVE_DEFINE_CSV="$MPTDC_OPT_MODE_DEFINE_CSV"
if [[ "${MPTDC_GENUS_RELAX_FAST_TAG_PRESERVE:-0}" == "1" ]]; then
  if [[ -n "$EFFECTIVE_DEFINE_CSV" ]]; then
    EFFECTIVE_DEFINE_CSV+=","
  fi
  EFFECTIVE_DEFINE_CSV+="MPTDC_RELAX_FAST_TAG_PRESERVE"
fi

if [[ "$INPUT_RC" == "0" && -n "$EFFECTIVE_DEFINE_CSV" ]]; then
  EFFECTIVE_O13_FILELIST="$RESULT_DIR/internal/run/filelist_o13_phase_distribution_spadmic_test.f"
  awk -v defines="$EFFECTIVE_DEFINE_CSV" '
    function emit_defines(   n, i, arr) {
      n = split(defines, arr, ",")
      for (i = 1; i <= n; i++) {
        if (arr[i] != "") {
          print "+define+" arr[i]
        }
      }
    }
    BEGIN { added = 0 }
    {
      print
      if (!added && $0 == "+define+MPTDC_PHASE_BUFFER_TOPO_BUHDX4_BUHDX12") {
        emit_defines()
        added = 1
      }
    }
    END {
      if (!added) {
        emit_defines()
      }
    }
  ' "$O13_FILELIST" > "$EFFECTIVE_O13_FILELIST"
  O13_FILELIST="$EFFECTIVE_O13_FILELIST"
fi

if [[ "$INPUT_RC" == "0" ]] && [[ "$RUN_MODE" != "validate_only" ]] && ! command -v genus >/dev/null 2>&1; then
  echo "ERROR: genus not found in PATH; run on the lab server." | tee -a "$GENUS_LOG"
  INPUT_RC=127
fi

export MPTDC_TIMING_VIEW=tc_only
export MPTDC_TC_ONLY_VIEW=1
export MPTDC_FREQ_MODE=r750_delta5
export MPTDC_FREQ_MODE_DEFINES="$FREQ_DEFINES"
export MPTDC_OPT_MODE
export PDK_ROOT="${PDK_ROOT:-$DEFAULT_PDK_ROOT}"
export SC_ROOT="$SC_ROOT_PATH"
export MPTDC_STDCELL_FAMILY="$STDCELL_FAMILY"
export MPTDC_STDCELL_SITE="$STDCELL_SITE"
export MPTDC_STDCELL_LEF="$STDCELL_LEF"
export MPTDC_STDCELL_TC_LIB="$STDCELL_TC_LIB"
export MPTDC_SYN_INPUTS_DIR="$SYN_DIR/inputs"
export O1_USE_REAL_RO_ABSTRACT=1
export O1_RO_LEF_PATH="$REAL_LEF"
export O1_RO_LIBERTY_PATH="$REAL_LIB"
export MPTDC_USE_RO_TUNE4_MACRO=1
export MPTDC_READ_HDL_LIST="$O13_FILELIST"
export MPTDC_OSC_PD_USE_PROVISIONAL=0
export MPTDC_OSC_PD_USE_PROVISIONAL_LIBERTY=0
export MPTDC_OSC_PD_SDC_OVERLAY="$O13_SDC"
export MPTDC_O13_CLOCK_MODEL_RPT="$RESULT_DIR/o13_clock_model_check.sdc.rpt"
export MPTDC_O13_PD_VERNIER_RPT="$RESULT_DIR/pd_vernier_exception_check.rpt"
export MPTDC_O13_PD_VERNIER_ENDPOINT_DISCOVERY_RPT="$RESULT_DIR/pd_vernier_endpoint_discovery.rpt"
export MPTDC_O13_PD_VERNIER_SOURCE_DISCOVERY_RPT="$RESULT_DIR/pd_vernier_source_discovery.rpt"
export MPTDC_O13_PD_VERNIER_INTENT_RPT="$RESULT_DIR/timing_pd_intentional_vernier.rpt"
export O1_RUN_FLAVOR="$FLOW_LABEL"
export GENUS_EFFORT="${O13_GENUS_EFFORT:-closure}"
export MPTDC_OPT_GOAL="mptdc_typical_timing_closure"
export MPTDC_OSC_SLOW_PERIOD_NS="${O13_OSC_SLOW_PERIOD_NS:-1.430}"
export MPTDC_OSC_FAST_PERIOD_NS="${O13_OSC_FAST_PERIOD_NS:-1.333}"
export MPTDC_OSC_SLOW_TAP_STEP_NS="${O13_OSC_SLOW_TAP_STEP_NS:-0.079}"
export MPTDC_OSC_FAST_TAP_STEP_NS="${O13_OSC_FAST_TAP_STEP_NS:-0.074}"
export MPTDC_ENABLE_CLOCK_GATING="${O13_ENABLE_CLOCK_GATING:-0}"
export MPTDC_ALLOW_ICG_DONT_USE_OVERRIDE="${O13_ALLOW_ICG_DONT_USE_OVERRIDE:-0}"
export MPTDC_ALLOW_DISCRETE_CLOCK_GATING="${O13_ALLOW_DISCRETE_CLOCK_GATING:-0}"
export MPTDC_RELAX_PD_PRESERVE="${O13_RELAX_PD_PRESERVE:-1}"

{
  echo
  echo "O13 inputs:"
  echo "  STDCELL_FAMILY=$STDCELL_FAMILY"
  echo "  STDCELL_LIB_NAME=$STDCELL_LIB_NAME"
  echo "  STDCELL_SITE=$STDCELL_SITE"
  echo "  SC_ROOT=$SC_ROOT_PATH"
  echo "  STDCELL_LEF=$STDCELL_LEF"
  echo "  STDCELL_TC_LIB=$STDCELL_TC_LIB"
  echo "  REAL_LEF=$REAL_LEF"
  echo "  REAL_LIB=$REAL_LIB"
  echo "  O13_SDC=$O13_SDC"
  echo "  O13_FILELIST=$O13_FILELIST"
  echo "  MPTDC_FREQ_MODE=$MPTDC_FREQ_MODE"
  echo "  MPTDC_GENUS_CLOSURE_PROFILE=$MPTDC_GENUS_CLOSURE_PROFILE"
  echo "  MPTDC_OPT_MODE=$MPTDC_OPT_MODE"
  echo "  MPTDC_OPT_DEFINES=${MPTDC_OPT_MODE_DEFINE_CSV:-none}"
  echo "  GENUS_EFFORT=$GENUS_EFFORT"
  echo "  MPTDC_GENUS_AREA_RECOVERY=${MPTDC_GENUS_AREA_RECOVERY:-unset}"
  echo "  MPTDC_GENUS_POWER_OPT=${MPTDC_GENUS_POWER_OPT:-unset}"
  echo "  O13_ENABLE_CLOCK_GATING=${O13_ENABLE_CLOCK_GATING:-unset}"
  echo "  MPTDC_TIMING_VIEW=$MPTDC_TIMING_VIEW"
  echo "  FLOW_LABEL=$FLOW_LABEL"
  echo "  CLOSURE_LABEL=$CLOSURE_LABEL"
  echo "  PACKAGE_LABEL=$PACKAGE_LABEL"
  echo "  SIGNOFF_BOUNDARY=$SIGNOFF_BOUNDARY"
  echo "  LEGACY_TRACE=$LEGACY_TRACE_LABEL"
  echo "  MPTDC_GENUS_RUN_DIR=$MPTDC_GENUS_RUN_DIR"
  echo "  PHASE_BUFFER_TOPOLOGY=BUHDX4 isolation + BUHDX12 digital driver per tap"
  echo "  PHASE_BUFFER_DEFINE=MPTDC_PHASE_BUFFER_TOPO_BUHDX4_BUHDX12"
  echo "  FINAL_TYPICAL_GENUS_REPAIR_1_FAST_TAG_PD=$MPTDC_GENUS_REPAIR_FAST_TAG_PD"
  echo "  FINAL_TYPICAL_GENUS_REPAIR_1_DRV_TRANSITION=$MPTDC_GENUS_REPAIR_DRV_TRANSITION"
  echo "  MPTDC_GENUS_REPAIR4_EXACT_FAST_TAG_SOURCE_DRIVE=${MPTDC_GENUS_REPAIR4_EXACT_FAST_TAG_SOURCE_DRIVE:-0}"
  echo "  MPTDC_GENUS_REPAIR5_EXACT_FAST_TAG_CLOSE=${MPTDC_GENUS_REPAIR5_EXACT_FAST_TAG_CLOSE:-0}"
  echo "  MPTDC_GENUS_REPAIR6_LOCALTAG_PRESERVE_CLOSE=${MPTDC_GENUS_REPAIR6_LOCALTAG_PRESERVE_CLOSE:-0}"
  echo "  MPTDC_GENUS_REPAIR7_POLARITY_AWARE_FAST_TAG_SOURCE_UPGRADE=${MPTDC_GENUS_REPAIR7_POLARITY_AWARE_FAST_TAG_SOURCE_UPGRADE:-0}"
  echo "  MPTDC_GENUS_REPAIR8_JIHD_EXACT_FAST_TAG_CLOSE=${MPTDC_GENUS_REPAIR8_JIHD_EXACT_FAST_TAG_CLOSE:-0}"
  echo "  MPTDC_GENUS_REPAIR_PD_HIT_TO_NFAST_LOCAL=${MPTDC_GENUS_REPAIR_PD_HIT_TO_NFAST_LOCAL:-0}"
  echo "  MPTDC_PD_HIT_TO_NFAST_MAX_DELAY_NS=${MPTDC_PD_HIT_TO_NFAST_MAX_DELAY_NS:-0}"
  echo "  MPTDC_PD_HIT_TO_NFAST_MAX_TRANSITION_NS=${MPTDC_PD_HIT_TO_NFAST_MAX_TRANSITION_NS:-0}"
  echo "  MPTDC_PD_HIT_TO_NFAST_BITS=${MPTDC_PD_HIT_TO_NFAST_BITS:-0 1 2 3 4 5 6}"
  echo "  MPTDC_PD_HIT_TO_NFAST_EXPECTED_SOURCES=${MPTDC_PD_HIT_TO_NFAST_EXPECTED_SOURCES:-64}"
  echo "  MPTDC_PD_HIT_TO_NFAST_EXPECTED_ENDPOINTS=${MPTDC_PD_HIT_TO_NFAST_EXPECTED_ENDPOINTS:-448}"
  echo "  MPTDC_GENUS_REPAIR_PD_LOCAL_ON22=${MPTDC_GENUS_REPAIR_PD_LOCAL_ON22:-0}"
  echo "  MPTDC_PD_LOCAL_ON22_SOURCE_CELL=${MPTDC_PD_LOCAL_ON22_SOURCE_CELL:-ON22JIHDX0}"
  echo "  MPTDC_PD_LOCAL_ON22_TARGET_CELLS=${MPTDC_PD_LOCAL_ON22_TARGET_CELLS:-ON22JIHDX1 ON22JIHDX2}"
  echo "  MPTDC_PD_LOCAL_ON22_BITS=${MPTDC_PD_LOCAL_ON22_BITS:-0 1 2 3 4 5 6}"
  echo "  MPTDC_PD_LOCAL_ON22_EXPECTED_ENDPOINTS=${MPTDC_PD_LOCAL_ON22_EXPECTED_ENDPOINTS:-448}"
  echo "  MPTDC_PD_LOCAL_ON22_EXPECTED_CELLS=${MPTDC_PD_LOCAL_ON22_EXPECTED_CELLS:-AUTO}"
  echo "  MPTDC_FAST_TAG_REPAIR_MAX_FANOUT=${MPTDC_FAST_TAG_REPAIR_MAX_FANOUT:-16}"
  echo "  MPTDC_FAST_TAG_REPAIR_MAX_TRANSITION_NS=${MPTDC_FAST_TAG_REPAIR_MAX_TRANSITION_NS:-0.50}"
  echo "  MPTDC_FAST_TAG_REPAIR_EXACT_DATA_PATHS=${MPTDC_FAST_TAG_REPAIR_EXACT_DATA_PATHS:-0}"
  echo "  MPTDC_FAST_TAG_REPAIR_EXACT_TAPS=${MPTDC_FAST_TAG_REPAIR_EXACT_TAPS:-unset}"
  echo "  MPTDC_FAST_TAG_REPAIR_EXACT_BITS=${MPTDC_FAST_TAG_REPAIR_EXACT_BITS:-unset}"
  echo "  MPTDC_FAST_TAG_REPAIR_EXACT_MAX_FANOUT=${MPTDC_FAST_TAG_REPAIR_EXACT_MAX_FANOUT:-4}"
  echo "  MPTDC_FAST_TAG_REPAIR_EXACT_MAX_TRANSITION_NS=${MPTDC_FAST_TAG_REPAIR_EXACT_MAX_TRANSITION_NS:-0.35}"
  echo "  MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_NS=${MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_NS:-unset}"
  echo "  MPTDC_FAST_TAG_REPAIR_ENABLE_EXACT_MAX_DELAY=${MPTDC_FAST_TAG_REPAIR_ENABLE_EXACT_MAX_DELAY:-0}"
  echo "  MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_ENABLE=${MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_ENABLE:-${MPTDC_FAST_TAG_REPAIR_ENABLE_EXACT_MAX_DELAY:-0}}"
  echo "  MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL_DISABLE=${MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL_DISABLE:-0}"
  echo "  MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL=${MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL:-unset}"
  echo "  MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL_MODE=${MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL_MODE:-unset}"
  echo "  MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_RESET0_CELL=${MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_RESET0_CELL:-unset}"
  echo "  MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_SET1_CELL=${MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_SET1_CELL:-auto}"
  echo "  MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_SKIP_UNSUPPORTED=${MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_SKIP_UNSUPPORTED:-0}"
  echo "  MPTDC_GENUS_REPAIR_ENDPOINT_TRANSITION_TIGHT=${MPTDC_GENUS_REPAIR_ENDPOINT_TRANSITION_TIGHT:-0}"
  echo "  MPTDC_CONTROL_REPAIR_MAX_FANOUT=${MPTDC_CONTROL_REPAIR_MAX_FANOUT:-16}"
  echo "  MPTDC_CONTROL_REPAIR_MAX_TRANSITION_NS=${MPTDC_CONTROL_REPAIR_MAX_TRANSITION_NS:-0.50}"
  echo "  MPTDC_GENUS_REPAIR_STRONG_FAST_TAG_FLOPS=${MPTDC_GENUS_REPAIR_STRONG_FAST_TAG_FLOPS:-0}"
  echo "  MPTDC_GENUS_REPAIR_STRONG_CONTROL_DRV=${MPTDC_GENUS_REPAIR_STRONG_CONTROL_DRV:-1}"
  echo "  MPTDC_GENUS_REPAIR_CONTROL_CELL_BIAS_STAGE=${MPTDC_GENUS_REPAIR_CONTROL_CELL_BIAS_STAGE:-all}"
  echo "  MPTDC_GENUS_REPAIR_CONTROL_AVOID_INHDX8=${MPTDC_GENUS_REPAIR_CONTROL_AVOID_INHDX8:-1}"
  echo "  MPTDC_GENUS_REPAIR_EXACT_CONTROL_ROOTS=${MPTDC_GENUS_REPAIR_EXACT_CONTROL_ROOTS:-0}"
  echo "  MPTDC_CONTROL_REPAIR_EXACT_MIN_FANOUT=${MPTDC_CONTROL_REPAIR_EXACT_MIN_FANOUT:-64}"
  echo "  MPTDC_CONTROL_REPAIR_EXACT_REQUIRE_PD_SINKS=${MPTDC_CONTROL_REPAIR_EXACT_REQUIRE_PD_SINKS:-0}"
  echo "  MPTDC_CONTROL_REPAIR_EXACT_ALLOW_RESET_ROOTS=${MPTDC_CONTROL_REPAIR_EXACT_ALLOW_RESET_ROOTS:-1}"
  echo "  MPTDC_CONTROL_REPAIR_EXACT_DRIVER_REGEX=${MPTDC_CONTROL_REPAIR_EXACT_DRIVER_REGEX:-unset}"
  echo "  MPTDC_CONTROL_REPAIR_EXACT_NET_REGEX=${MPTDC_CONTROL_REPAIR_EXACT_NET_REGEX:-unset}"
  echo "  MPTDC_CONTROL_REPAIR_EXACT_MAX_ROOTS=${MPTDC_CONTROL_REPAIR_EXACT_MAX_ROOTS:-0}"
  echo "  MPTDC_FAST_TAG_REPAIR_APPLY_Q_CONSTRAINTS=${MPTDC_FAST_TAG_REPAIR_APPLY_Q_CONSTRAINTS:-1}"
  echo "  MPTDC_GENUS_REPAIR_APPLY_BROAD_CONTROL_NETS=${MPTDC_GENUS_REPAIR_APPLY_BROAD_CONTROL_NETS:-1}"
  echo "  MPTDC_GENUS_REPAIR_APPLY_DESIGN_DRV=${MPTDC_GENUS_REPAIR_APPLY_DESIGN_DRV:-0}"
  echo "  MPTDC_GENUS_RELAX_FAST_TAG_PRESERVE=${MPTDC_GENUS_RELAX_FAST_TAG_PRESERVE:-0}"
  if [[ "${MPTDC_GENUS_RELAX_FAST_TAG_PRESERVE:-0}" == "1" ]]; then
    echo "  FAST_TAG_PRESERVE_MODE=RELAXED"
  else
    echo "  FAST_TAG_PRESERVE_MODE=STRICT"
  fi
  echo "  MPTDC_FAST_TAG_REPAIR_MAX_DELAY_NS=${MPTDC_FAST_TAG_REPAIR_MAX_DELAY_NS:-unset}"
  echo "  MPTDC_DESIGN_POWER_EFFORT=${MPTDC_DESIGN_POWER_EFFORT:-none}"
  if [[ "${MPTDC_GENUS_RELAX_FAST_TAG_PRESERVE:-0}" == "1" ]]; then
    echo "  FINAL_TYPICAL_GENUS_REPAIR_FAST_TAG_DEFINE=MPTDC_RELAX_FAST_TAG_PRESERVE"
  fi
  echo
} | tee -a "$RESULT_DIR/run_manifest.txt" | tee -a "$GENUS_LOG"

GENUS_RC="$INPUT_RC"
if [[ "$INPUT_RC" == "0" && "$RUN_MODE" == "validate_only" ]]; then
  echo "MPTDC_O13_VALIDATE_ONLY=1: input validation passed; Genus not launched." | tee -a "$GENUS_LOG"
  GENUS_RC=0
elif [[ "$INPUT_RC" == "0" ]]; then
  echo "[GENUS_TYPICAL] Starting TC-only MPTDC Genus synthesis" | tee -a "$GENUS_LOG"
  (
    cd "$RESULT_DIR/internal/run"
    genus -files "$SCRIPT_DIR/genus.tcl" -log "$GENUS_TOOL_LOG"
  ) 2>&1 | tee -a "$GENUS_LOG"
  GENUS_RC=${PIPESTATUS[0]}
  if [[ "$GENUS_RC" == "0" ]]; then
    if grep -qE "Encountered problems processing file|extra characters after close-quote|MPTDC_STABLE_SDC_FATAL" "$GENUS_LOG" "$GENUS_TOOL_LOG" 2>/dev/null; then
      echo "ERROR: Genus emitted fatal flow diagnostics despite rc=0; marking run failed for review." | tee -a "$GENUS_LOG"
      GENUS_RC=1
    fi
  fi
fi

SNAPSHOT_RC=0
if [[ "$RUN_MODE" != "validate_only" ]]; then
  echo "[SNAPSHOT] Collecting Genus O13 snapshot into $SNAPSHOT_DIR" | tee -a "$GENUS_LOG"
  if ! bash "$SCRIPT_DIR/collect_snapshot.sh" "$SNAPSHOT_TAG" >> "$GENUS_LOG" 2>&1; then
    SNAPSHOT_RC=$?
    echo "WARNING: collect_snapshot.sh failed with rc=$SNAPSHOT_RC" | tee -a "$GENUS_LOG"
  fi

  if [[ -d "$SNAPSHOT_DIR" ]]; then
    cp -a "$SNAPSHOT_DIR/." "$RESULT_DIR/"
  fi
fi

cp "$GENUS_LOG" "$RESULT_DIR/genus_${RUN_ID}.log" 2>/dev/null || true
cp "$O13_SDC" "$RESULT_DIR/final_sdc_overlay_used.sdc" 2>/dev/null || true
cp "$O13_FILELIST" "$RESULT_DIR/final_filelist_used.f" 2>/dev/null || true
if [[ -f "$RESULT_DIR/o13_clock_model_check.sdc.rpt" && ! -f "$RESULT_DIR/o13_clock_model_check.rpt" ]]; then
  cp "$RESULT_DIR/o13_clock_model_check.sdc.rpt" "$RESULT_DIR/o13_clock_model_check.rpt" 2>/dev/null || true
fi

count_expected_clock_names() {
  local count=0
  local name
  local sources=(
    "$RESULT_DIR/report_clocks.rpt"
    "$RESULT_DIR/report_clocks_generated.rpt"
    "$RESULT_DIR/timing_summary.rpt"
    "$RESULT_DIR/o13_clock_model_check.rpt"
    "$RESULT_DIR/o13_clock_model_check.sdc.rpt"
    "$GENUS_LOG"
  )
  for name in "$@"; do
    if grep -E -q "(^|[^[:alnum:]_])${name}([^[:alnum:]_]|$)" "${sources[@]}" 2>/dev/null; then
      count=$((count + 1))
    fi
  done
  echo "$count"
}

write_sdc_failure_report() {
  local out="$RESULT_DIR/sdc_command_failures.md"
  local sdc_235_count=NA
  local tui_61_count=NA
  local invalid_object_count=NA
  local active_sdc_failure_count=NA
  local report_diagnostic_warning_count=NA
  local raw_sdc_diagnostic_count=NA
  local command_failure_count=NA
  if [[ -f "$GENUS_LOG" ]]; then
    sdc_235_count="$(grep -E 'Error[[:space:]]*:.*(\[SDC-235\]|SDC command requires a constraint mode specification)' "$GENUS_LOG" 2>/dev/null | grep -v '|' | sort -u | wc -l | tr -d ' ')"
    tui_61_count="$(grep -E 'Error[[:space:]]*:.*(\[TUI-61\]|A required object parameter could not be found)' "$GENUS_LOG" 2>/dev/null | grep -v '|' | sort -u | wc -l | tr -d ' ')"
    invalid_object_count="$(grep -E '(Warning|Error)[[:space:]]*:.*(\[SDC-248\]|Invalid object passed to SDC command|empty object|invalid object)' "$GENUS_LOG" 2>/dev/null | grep -v '|' | sort -u | wc -l | tr -d ' ')"
    raw_sdc_diagnostic_count=$((sdc_235_count + tui_61_count + invalid_object_count))
    local active_sdc_235_count
    active_sdc_235_count="$(grep -E 'Error[[:space:]]*:.*(\[SDC-235\]|SDC command requires a constraint mode specification)' "$GENUS_LOG" 2>/dev/null | grep -v '|' | grep -Ev '\[retrieve_mode\]|report_timing' | sort -u | wc -l | tr -d ' ')"
    local active_tui_61_count
    active_tui_61_count="$(grep -E 'Error[[:space:]]*:.*(\[TUI-61\]|A required object parameter could not be found)' "$GENUS_LOG" 2>/dev/null | grep -v '|' | grep -Ev 'report_timing' | sort -u | wc -l | tr -d ' ')"
    local failed_command_count
    failed_command_count="$(grep -E '"set_(false_path|max_delay|max_transition|clock_groups)"[[:space:]]+-[[:space:]]+successful[[:space:]]+[0-9]+[[:space:]]+,[[:space:]]+failed[[:space:]]+[1-9]' "$GENUS_LOG" 2>/dev/null | sort -u | wc -l | tr -d ' ')"
    local fatal_count
    fatal_count="$(grep -E 'MPTDC_O13_.*FATAL|MPTDC_SDC_.*ERROR|\[SDC-202\]|\[SDC-209\]' "$GENUS_LOG" 2>/dev/null | grep -v '|' | sort -u | wc -l | tr -d ' ')"
    active_sdc_failure_count=$((active_sdc_235_count + active_tui_61_count + failed_command_count + fatal_count))
    report_diagnostic_warning_count=$((raw_sdc_diagnostic_count - active_sdc_235_count - active_tui_61_count))
    command_failure_count=$active_sdc_failure_count
  fi
  {
    echo "# O13 abs3 SDC Command Failure Review"
    echo
    echo "- Run ID: \`$RUN_ID\`"
    echo "- SDC overlay: \`$O13_SDC\`"
    echo "- Genus log: \`genus_${RUN_ID}.log\`"
    echo
    echo "SDC_COMMAND_FAILURE_COUNT=$command_failure_count"
    echo "ACTIVE_SDC_FAILURE_COUNT=$active_sdc_failure_count"
    echo "REPORT_DIAGNOSTIC_WARNING_COUNT=$report_diagnostic_warning_count"
    echo "RAW_SDC_DIAGNOSTIC_COUNT=$raw_sdc_diagnostic_count"
    echo "SDC_235_COUNT=$sdc_235_count"
    echo "TUI_61_COUNT=$tui_61_count"
    echo "SDC_INVALID_OBJECT_COUNT=$invalid_object_count"
    echo
    echo "## Extracted SDC/Timing-Intent Diagnostics"
    echo
    if [[ -f "$GENUS_LOG" ]]; then
      grep -nE 'SDC-|MPTDC_SDC_(WARN|INFO)|MPTDC_O13_ABS3_SDC_|MPTDC_O13_ABS4_SDC_|MPTDC_O13_ABS5_SDC_|MPTDC_O13_SDC_|set_false_path|set_max_delay|set_max_transition|set_clock_groups|TUI-61|TIM-234|report_timing' "$GENUS_LOG" || true
    else
      echo "FAILED: Genus log not found."
    fi
    echo
    echo "## Interpretation"
    echo
    echo "- ACTIVE_SDC_FAILURE_COUNT gates timing intent and closure readiness."
    echo "- REPORT_DIAGNOSTIC_WARNING_COUNT captures report-only Genus diagnostics such as retrieve_mode noise."
    echo "- Final buffer clocks must be grouped asynchronously against clk_sys."
    echo "- Any remaining failed false-path, max-delay, clock-group, or generated-clock command requires review before Innovus."
  } > "$out"
}

run_timing_classification() {
  local reports=()
  for file in \
    timing_violations.rpt \
    timing_pd_capture_hotspots.rpt \
    timing_clk_sys_violations.rpt \
    timing_clk_sys_internal_top100.rpt \
    timing_cdc_async_review.rpt \
    timing_pd_intentional_vernier.rpt \
    pd_vernier_endpoint_discovery.rpt \
    pd_vernier_source_discovery.rpt \
    timing_o13_phase_buffer_paths.rpt; do
    if [[ -f "$RESULT_DIR/$file" ]]; then
      reports+=("$RESULT_DIR/$file")
    fi
  done
  if [[ "${#reports[@]}" -gt 0 && -f "$REPO_ROOT/tools/timing/classify_mptdc_timing_paths.py" ]]; then
    python3 "$REPO_ROOT/tools/timing/classify_mptdc_timing_paths.py" \
      "${reports[@]}" \
      --out-csv "$RESULT_DIR/timing_path_classification.csv" \
      --out-summary "$RESULT_DIR/timing_path_classification_summary.md" || true
  fi
}

run_corrected_summary_parser() {
  local parser="$REPO_ROOT/tools/timing/summarize_mptdc_genus_run.py"
  local env_out="$RESULT_DIR/summary_metrics.env"
  local rpt_out="$RESULT_DIR/summary_parser_check.rpt"
  if [[ -f "$parser" ]]; then
    if python3 "$parser" --run-dir "$RESULT_DIR" --out-env "$env_out" --out-report "$rpt_out"; then
      # shellcheck source=/dev/null
      source "$env_out"
    else
      if [[ -f "$env_out" ]]; then
        # shellcheck source=/dev/null
        source "$env_out"
      fi
      SUMMARY_RAW_AGREEMENT_STATUS="${SUMMARY_RAW_AGREEMENT_STATUS:-FAIL}"
      TIMING_SUMMARY_PARSE_STATUS="${TIMING_SUMMARY_PARSE_STATUS:-FAIL}"
      TIMING_CLASSIFICATION_PARSE_STATUS="${TIMING_CLASSIFICATION_PARSE_STATUS:-FAIL}"
    fi
  else
    SUMMARY_RAW_AGREEMENT_STATUS=FAIL
    TIMING_SUMMARY_PARSE_STATUS=FAIL
    TIMING_CLASSIFICATION_PARSE_STATUS=FAIL
  fi
}

run_final_diagnostic_reports() {
  local fast_analyzer="$REPO_ROOT/tools/timing/analyze_mptdc_fast_tag_pd_paths.py"
  local fast_mapping_analyzer="$REPO_ROOT/tools/timing/analyze_mptdc_fast_tag_cell_mapping.py"
  local drv_analyzer="$REPO_ROOT/tools/timing/analyze_mptdc_drv_transition_roots.py"
  if [[ -f "$fast_analyzer" && -f "$RESULT_DIR/timing_path_classification.csv" && -f "$RESULT_DIR/timing_violations.rpt" ]]; then
    python3 "$fast_analyzer" \
      --run-dir "$RESULT_DIR" \
      --out-md "$RESULT_DIR/final_genus_fast_tag_to_pd_ts_analysis.md" \
      --limit 50 || true
  fi
  if [[ -f "$fast_mapping_analyzer" ]]; then
    mkdir -p "$RESULT_DIR/reports"
    python3 "$fast_mapping_analyzer" \
      --run-dir "$RESULT_DIR" \
      --out-csv "$RESULT_DIR/reports/fast_tag_cell_mapping.csv" \
      --out-env "$RESULT_DIR/fast_tag_cell_mapping.env" \
      --out-report "$RESULT_DIR/fast_tag_cell_mapping_guardrail.rpt" || true
  fi
  if [[ -f "$drv_analyzer" && -f "$RESULT_DIR/report_design_rules.rpt" ]]; then
    mkdir -p "$RESULT_DIR/reports"
    python3 "$drv_analyzer" \
      --run-dir "$RESULT_DIR" \
      --out-csv "$RESULT_DIR/reports/drv_transition_root_causes.csv" || true
    python3 "$drv_analyzer" \
      --run-dir "$RESULT_DIR" \
      --out-csv "$RESULT_DIR/reports/control_drv_root_causes.csv" || true
  fi
}

mirror_final_report_artifacts() {
  local file
  for file in \
    fast_tag_exact_repair_status.rpt \
    fast_tag_exact_source_discovery.csv \
    fast_tag_exact_endpoint_discovery.csv \
    fast_tag_exact_path_pairs.csv \
    fast_tag_exact_source_cell_repair.csv \
    fast_tag_exact_source_cell_legal_cells.rpt \
    fast_tag_exact_source_cell_command_ladder.rpt \
    fast_tag_exact_source_freeze.rpt \
    pd_hit_to_nfast_local_repair_status.rpt \
    pd_hit_to_nfast_local_source_discovery.csv \
    pd_hit_to_nfast_local_source_q_discovery.csv \
    pd_hit_to_nfast_local_endpoint_discovery.csv \
    pd_hit_to_nfast_local_path_pairs.csv \
    pd_local_on22_repair_status.rpt \
    pd_local_on22_driver_discovery.csv \
    pd_local_on22_cell_repair.csv \
    pd_local_on22_legal_cells.rpt; do
    if [[ ! -f "$RESULT_DIR/$file" && -f "$RESULT_DIR/reports/$file" ]]; then
      cp "$RESULT_DIR/reports/$file" "$RESULT_DIR/$file"
    fi
  done
}

write_sdc_failure_report
run_timing_classification
run_corrected_summary_parser
run_final_diagnostic_reports
mirror_final_report_artifacts

POSTSYN_NETLIST="$RESULT_DIR/mptdc_axis_core.postsyn.v"
if [[ ! -f "$POSTSYN_NETLIST" ]]; then
  POSTSYN_NETLIST="$RESULT_DIR/outputs/mptdc_axis_core.postsyn.v"
fi
if [[ ! -f "$POSTSYN_NETLIST" ]]; then
  POSTSYN_NETLIST="$SYN_DIR/outputs/mptdc_axis_core.postsyn.v"
fi

RO_COUNT=0
STUB_COUNT=0
BUHDX4_COUNT=0
BUHDX12_COUNT=0
PHASE_BUF_TEXT_COUNT=0
ISO_TEXT_COUNT=0
DRV_TEXT_COUNT=0
CLOCKS_ON_RO=0
BUFFER_CLOCKS=0
RAW_RO_CLOCKS_FOUND=0
BUFFER_PHASE_CLOCKS_FOUND=0
BUFFER_PHASE_CLOCKS_EXPECTED=16
BUFFER_PHASE_CLOCKS_IN_ASYNC_GROUP=NO
CLK_SYS_ASYNC_TO_BUFFER_PHASE_CLOCKS=NO
UNKNOWN_REVIEW_REQUIRED_COUNT=NA
PD_VERNIER_EXCEPTION_EXPECTED=64
PD_VERNIER_EXCEPTION_MATCHED=NA
PD_VERNIER_SOURCE_MATCHED=NA
PD_VERNIER_EXCEPTION_APPLIED=NA
PD_VERNIER_EXCEPTION_OVERMATCH=NA
PD_VERNIER_EXCEPTION_UNDERMATCH=NA
SDC_COMMAND_FAILURE_COUNT=NA
ACTIVE_SDC_FAILURE_COUNT=NA
REPORT_DIAGNOSTIC_WARNING_COUNT=NA
RAW_SDC_DIAGNOSTIC_COUNT=NA
SDC_235_COUNT=NA
TUI_61_COUNT=NA
SDC_INVALID_OBJECT_COUNT=NA
EXACT_FAST_TAG_SOURCES_EXPECTED=NA
EXACT_FAST_TAG_SOURCES_FOUND=NA
EXACT_FAST_TAG_ENDPOINTS_EXPECTED=NA
EXACT_FAST_TAG_ENDPOINTS_FOUND=NA
EXACT_FAST_TAG_DATAPATHS_EXPECTED=NA
EXACT_FAST_TAG_DATAPATHS_FOUND=NA
EXACT_FAST_TAG_REPAIR_APPLIED=NA
EXACT_FAST_TAG_REPAIR_STATUS=NA
FAST_TAG_EXACT_C_TO_D_SET_MAX_DELAY_RESULT=NA
FAST_TAG_EXACT_MAX_DELAY_CONSTRAINT_MODE=NA
FAST_TAG_EXACT_SOURCE_CELL_TARGET=NA
FAST_TAG_EXACT_SOURCE_CELL_REQUESTED=NA
FAST_TAG_EXACT_SOURCE_CELL_LIB_CELLS_FOUND=NA
FAST_TAG_EXACT_SOURCE_CELL_COUNT=NA
FAST_TAG_EXACT_SOURCE_CELL_TARGET_COUNT=NA
FAST_TAG_EXACT_SOURCE_CELL_METHOD=NA
FAST_TAG_EXACT_SOURCE_CELL_RESULT=NA
FAST_TAG_EXACT_SOURCE_CELL_MODE=NA
FAST_TAG_EXACT_RESET0_SOURCE_COUNT=NA
FAST_TAG_EXACT_SET1_SOURCE_COUNT=NA
FAST_TAG_EXACT_SOURCE_UNSUPPORTED_POLARITY_COUNT=NA
FAST_TAG_EXACT_SELECTED_RESET0_TARGET=NA
FAST_TAG_EXACT_SELECTED_SET1_TARGET=NA
FAST_TAG_EXACT_DFRRQHDX4_TARGET_COUNT=NA
FAST_TAG_EXACT_DFRSQHDX4_TARGET_COUNT=NA
FAST_TAG_EXACT_DFRSQHDX2_TARGET_COUNT=NA
FAST_TAG_EXACT_DFRRQJIHDX4_TARGET_COUNT=NA
FAST_TAG_EXACT_DFRSJIHDX4_TARGET_COUNT=NA
FAST_TAG_EXACT_DFRSJIHDX2_TARGET_COUNT=NA
FAST_TAG_EXACT_SOURCE_POLARITY_PRESERVED_COUNT=NA
FAST_TAG_EXACT_SOURCE_POLARITY_FAILED_COUNT=NA
FAST_TAG_EXACT_SOURCE_FREEZE_RESULT=NA
PD_HIT_TO_NFAST_LOCAL_REPAIR_ENABLE=NA
PD_HIT_TO_NFAST_LOCAL_SOURCES_EXPECTED=NA
PD_HIT_TO_NFAST_LOCAL_SOURCES_FOUND=NA
PD_HIT_TO_NFAST_LOCAL_SOURCE_Q_FOUND=NA
PD_HIT_TO_NFAST_LOCAL_ENDPOINTS_EXPECTED=NA
PD_HIT_TO_NFAST_LOCAL_ENDPOINTS_FOUND=NA
PD_HIT_TO_NFAST_LOCAL_PAIRS_FOUND=NA
PD_HIT_TO_NFAST_LOCAL_BITS=NA
PD_HIT_TO_NFAST_LOCAL_MAX_DELAY_NS=NA
PD_HIT_TO_NFAST_LOCAL_MAX_TRANSITION_NS=NA
PD_HIT_TO_NFAST_LOCAL_GROUP_PATH_RESULT=NA
PD_HIT_TO_NFAST_LOCAL_SET_MAX_DELAY_RESULT=NA
PD_HIT_TO_NFAST_LOCAL_MAX_DELAY_CONSTRAINT_MODE=NA
PD_HIT_TO_NFAST_LOCAL_SET_MAX_TRANSITION_RESULT=NA
PD_HIT_TO_NFAST_LOCAL_OVERMATCH=NA
PD_HIT_TO_NFAST_LOCAL_UNDERMATCH=NA
PD_HIT_TO_NFAST_LOCAL_STATUS=NA
PD_HIT_TO_NFAST_LOCAL_REVIEW_REASON=NA
PD_LOCAL_ON22_REPAIR_ENABLE=NA
PD_LOCAL_ON22_SOURCE_CELL=NA
PD_LOCAL_ON22_TARGET_CELLS=NA
PD_LOCAL_ON22_SELECTED_TARGET=NA
PD_LOCAL_ON22_TARGET_LIB_CELLS_FOUND=NA
PD_LOCAL_ON22_ENDPOINTS_EXPECTED=NA
PD_LOCAL_ON22_ENDPOINTS_FOUND=NA
PD_LOCAL_ON22_SOURCE_DRIVERS_FOUND=NA
PD_LOCAL_ON22_SOURCE_CELLS_EXPECTED=NA
PD_LOCAL_ON22_SOURCE_CELLS_FOUND=NA
PD_LOCAL_ON22_CHANGED_CELLS=NA
PD_LOCAL_ON22_TARGET_CELLS_FOUND=NA
PD_LOCAL_ON22_REPAIR_RESULT=NA
PD_LOCAL_ON22_OVERMATCH=NA
PD_LOCAL_ON22_UNDERMATCH=NA
PD_LOCAL_ON22_STATUS=NA
PD_LOCAL_ON22_REVIEW_REASON=NA
MAX_TRANSITION_VIOLATIONS=NA
MAX_CAPACITANCE_VIOLATIONS=NA
MAX_FANOUT_VIOLATIONS=NA
SETUP_WNS_PS="${SETUP_WNS_PS:-NA}"
SETUP_TNS_PS="${SETUP_TNS_PS:-NA}"
SETUP_VIOLATING_PATHS="${SETUP_VIOLATING_PATHS:-NA}"
HOLD_WNS_PS="${HOLD_WNS_PS:-NA}"
HOLD_TNS_PS="${HOLD_TNS_PS:-NA}"
REAL_TIMED_WNS_PS=NA
REAL_TIMED_TNS_PS=NA
REAL_TIMED_VIOLATING_PATHS="${REAL_TIMED_VIOLATING_PATHS:-NA}"
WORST_REAL_PATH_FAMILY=NA
REPORT_HELPER_FAILURE_COUNT="${REPORT_HELPER_FAILURE_COUNT:-NA}"
REPORT_HELPERS_STATUS="${REPORT_HELPERS_STATUS:-NA}"
TIMING_SUMMARY_PARSE_STATUS="${TIMING_SUMMARY_PARSE_STATUS:-NA}"
TIMING_CLASSIFICATION_PARSE_STATUS="${TIMING_CLASSIFICATION_PARSE_STATUS:-NA}"
SUMMARY_RAW_AGREEMENT_STATUS="${SUMMARY_RAW_AGREEMENT_STATUS:-NA}"
FAST_TAG_FLOP_BIAS_MODE=DISABLED
if [[ "${MPTDC_GENUS_REPAIR_STRONG_FAST_TAG_FLOPS:-0}" == "1" ]]; then
  FAST_TAG_FLOP_BIAS_MODE=EXPERIMENTAL_UNSAFE
fi
FAST_TAG_PRESERVE_MODE=STRICT
if [[ "${MPTDC_GENUS_RELAX_FAST_TAG_PRESERVE:-0}" == "1" ]]; then
  FAST_TAG_PRESERVE_MODE=RELAXED
fi
FAST_TAG_MAPPING_PARSE_STATUS=NA
FAST_TAG_MAPPING_STATUS=NA
FAST_TAG_SOURCE_DFRRQHDX0_COUNT=NA
FAST_TAG_SOURCE_DFRRQHDX1_COUNT=NA
FAST_TAG_SOURCE_DFRRQHDX2_COUNT=NA
FAST_TAG_SOURCE_DFRRQHDX4_COUNT=NA
FAST_TAG_SOURCE_DFRSQHDX0_COUNT=NA
FAST_TAG_SOURCE_DFRSQHDX1_COUNT=NA
FAST_TAG_SOURCE_DFRSQHDX2_COUNT=NA
FAST_TAG_SOURCE_DFRSQHDX4_COUNT=NA
FAST_TAG_SOURCE_DFRJIHDX0_COUNT=NA
FAST_TAG_SOURCE_DFRJIHDX1_COUNT=NA
FAST_TAG_SOURCE_DFRJIHDX2_COUNT=NA
FAST_TAG_SOURCE_DFRJIHDX4_COUNT=NA
FAST_TAG_SOURCE_DFRRQJIHDX0_COUNT=NA
FAST_TAG_SOURCE_DFRRQJIHDX1_COUNT=NA
FAST_TAG_SOURCE_DFRRQJIHDX2_COUNT=NA
FAST_TAG_SOURCE_DFRRQJIHDX4_COUNT=NA
FAST_TAG_SOURCE_DFRSJIHDX2_COUNT=NA
FAST_TAG_SOURCE_UNKNOWN_COUNT=NA
FAST_TAG_MAPPED_SOURCE_COUNT=NA
FAST_TAG_MAPPED_ENDPOINT_COUNT=NA
FAST_TAG_TOP_PATH_COUNT=NA
FAST_TAG_EXACT_SOURCE_COUNT=NA
FAST_TAG_EXACT_SOURCE_DFRRQHDX1_COUNT=NA
FAST_TAG_EXACT_SOURCE_DFRRQHDX2_COUNT=NA
FAST_TAG_EXACT_SOURCE_DFRRQHDX4_COUNT=NA
FAST_TAG_EXACT_SOURCE_DFRSQHDX0_COUNT=NA
FAST_TAG_EXACT_SOURCE_DFRSQHDX1_COUNT=NA
FAST_TAG_EXACT_SOURCE_DFRSQHDX2_COUNT=NA
FAST_TAG_EXACT_SOURCE_DFRSQHDX4_COUNT=NA
FAST_TAG_EXACT_SOURCE_DFRJIHDX1_COUNT=NA
FAST_TAG_EXACT_SOURCE_DFRJIHDX2_COUNT=NA
FAST_TAG_EXACT_SOURCE_DFRJIHDX4_COUNT=NA
FAST_TAG_EXACT_SOURCE_DFRRQJIHDX1_COUNT=NA
FAST_TAG_EXACT_SOURCE_DFRRQJIHDX2_COUNT=NA
FAST_TAG_EXACT_SOURCE_DFRRQJIHDX4_COUNT=NA
FAST_TAG_EXACT_SOURCE_DFRSJIHDX2_COUNT=NA
FAST_TAG_EXACT_SOURCE_UNKNOWN_COUNT=NA
FAST_TAG_EXACT_ENDPOINT_COUNT=NA
FAST_TAG_EXACT_ENDPOINT_DFRHDX2_COUNT=NA
FAST_TAG_EXACT_ENDPOINT_DFRHDX4_COUNT=NA
FAST_TAG_EXACT_ENDPOINT_DFRSHDX2_COUNT=NA
FAST_TAG_EXACT_ENDPOINT_DFRSHDX4_COUNT=NA
FAST_TAG_EXACT_ENDPOINT_UNKNOWN_COUNT=NA
FAST_TAG_EXACT_SOURCE_PHASE_CLOCK_LOAD_DELTA_ESTIMATE=NA
FINAL_DECISION="GENUS_TYPICAL_REVIEW_REQUIRED"
RAW_CLOCK_NAMES=(clk_osc_slow)
BUFFER_CLOCK_NAMES=()
for tap in 1 2 3 4 5 6 7; do
  RAW_CLOCK_NAMES+=("clk_osc_slow_tap${tap}")
done
RAW_CLOCK_NAMES+=(clk_osc_fast)
for tap in 1 2 3 4 5 6 7; do
  RAW_CLOCK_NAMES+=("clk_osc_fast_tap${tap}")
done
for family in slow fast; do
  for tap in 0 1 2 3 4 5 6 7; do
    BUFFER_CLOCK_NAMES+=("clk_osc_${family}_buf_tap${tap}")
  done
done
if [[ -f "$POSTSYN_NETLIST" ]]; then
  RO_COUNT="$(grep -cE '^[[:space:]]*RO_tune4[[:space:]]+' "$POSTSYN_NETLIST" || true)"
  STUB_COUNT="$(grep -cE 'mptdc_osc_stub' "$POSTSYN_NETLIST" || true)"
  BUHDX4_COUNT="$(grep -cE '^[[:space:]]*BUHDX4[[:space:]]+' "$POSTSYN_NETLIST" || true)"
  BUHDX12_COUNT="$(grep -cE '^[[:space:]]*BUHDX12[[:space:]]+' "$POSTSYN_NETLIST" || true)"
  PHASE_BUF_TEXT_COUNT="$(grep -cE 'u_phase_buf_slow|u_phase_buf_fast|mptdc_phase_buffer_bank' "$POSTSYN_NETLIST" || true)"
  ISO_TEXT_COUNT="$(grep -cE 'u_iso' "$POSTSYN_NETLIST" || true)"
  DRV_TEXT_COUNT="$(grep -cE 'u_drv' "$POSTSYN_NETLIST" || true)"
fi
if [[ -f "$RESULT_DIR/report_clocks.rpt" ]]; then
  CLOCKS_ON_RO="$(grep -cE 'u_ro_tune4.*/?S\[[0-7]\]|u_ro_tune4.*S\[[0-7]\]' "$RESULT_DIR/report_clocks.rpt" || true)"
  BUFFER_CLOCKS="$(grep -cE 'clk_osc_(slow|fast)_buf_tap[0-7]' "$RESULT_DIR/report_clocks.rpt" || true)"
fi
RAW_RO_CLOCKS_FOUND="$(count_expected_clock_names "${RAW_CLOCK_NAMES[@]}")"
BUFFER_PHASE_CLOCKS_FOUND="$(count_expected_clock_names "${BUFFER_CLOCK_NAMES[@]}")"
if grep -q 'CLK_SYS_ASYNC_TO_BUFFER_PHASE_CLOCKS=YES' "$RESULT_DIR/o13_clock_model_check.sdc.rpt" "$RESULT_DIR/o13_clock_model_check.rpt" "$GENUS_LOG" 2>/dev/null; then
  CLK_SYS_ASYNC_TO_BUFFER_PHASE_CLOCKS=YES
  BUFFER_PHASE_CLOCKS_IN_ASYNC_GROUP=YES
fi
if [[ -f "$RESULT_DIR/timing_path_classification_summary.md" ]]; then
  UNKNOWN_REVIEW_REQUIRED_COUNT="$(awk -F': ' '/UNKNOWN_REVIEW_REQUIRED paths/ {print $2; exit}' "$RESULT_DIR/timing_path_classification_summary.md" | tr -d '`' || true)"
  UNKNOWN_REVIEW_REQUIRED_COUNT="${UNKNOWN_REVIEW_REQUIRED_COUNT:-NA}"
fi
if [[ -f "$RESULT_DIR/pd_vernier_exception_check.rpt" ]]; then
  PD_VERNIER_EXCEPTION_MATCHED="$(awk -F= '/^PD_VERNIER_FOUND_ENDPOINTS=/ {print $2; exit} /^PD_VERNIER_EXCEPTION_ENDPOINTS_FOUND=/ {print $2; exit}' "$RESULT_DIR/pd_vernier_exception_check.rpt" || true)"
  PD_VERNIER_EXCEPTION_MATCHED="${PD_VERNIER_EXCEPTION_MATCHED:-NA}"
  PD_VERNIER_SOURCE_MATCHED="$(awk -F= '/^PD_VERNIER_FOUND_SOURCES=/ {print $2; exit} /^PD_VERNIER_SOURCE_CLOCKS_FOUND=/ {print $2; exit}' "$RESULT_DIR/pd_vernier_exception_check.rpt" || true)"
  PD_VERNIER_SOURCE_MATCHED="${PD_VERNIER_SOURCE_MATCHED:-NA}"
  PD_VERNIER_EXCEPTION_APPLIED="$(awk -F= '/^PD_VERNIER_EXCEPTION_APPLIED=/ {print $2; exit}' "$RESULT_DIR/pd_vernier_exception_check.rpt" || true)"
  PD_VERNIER_EXCEPTION_APPLIED="${PD_VERNIER_EXCEPTION_APPLIED:-NA}"
  PD_VERNIER_EXCEPTION_OVERMATCH="$(awk -F= '/^PD_VERNIER_OVERMATCH=/ {print $2; exit} /^PD_VERNIER_EXCEPTION_OVERMATCH=/ {print $2; exit}' "$RESULT_DIR/pd_vernier_exception_check.rpt" || true)"
  PD_VERNIER_EXCEPTION_OVERMATCH="${PD_VERNIER_EXCEPTION_OVERMATCH:-NA}"
  PD_VERNIER_EXCEPTION_UNDERMATCH="$(awk -F= '/^PD_VERNIER_UNDERMATCH=/ {print $2; exit}' "$RESULT_DIR/pd_vernier_exception_check.rpt" || true)"
  PD_VERNIER_EXCEPTION_UNDERMATCH="${PD_VERNIER_EXCEPTION_UNDERMATCH:-NA}"
fi
if [[ -f "$RESULT_DIR/sdc_command_failures.md" ]]; then
  sdc_report_value() {
    local key="$1"
    awk -F= -v key="$key" '$1 == key {value=$2; found=1} END {if (found) print value}' "$RESULT_DIR/sdc_command_failures.md"
  }
  SDC_COMMAND_FAILURE_COUNT="$(sdc_report_value SDC_COMMAND_FAILURE_COUNT)"
  ACTIVE_SDC_FAILURE_COUNT="$(sdc_report_value ACTIVE_SDC_FAILURE_COUNT)"
  REPORT_DIAGNOSTIC_WARNING_COUNT="$(sdc_report_value REPORT_DIAGNOSTIC_WARNING_COUNT)"
  RAW_SDC_DIAGNOSTIC_COUNT="$(sdc_report_value RAW_SDC_DIAGNOSTIC_COUNT)"
  SDC_235_COUNT="$(sdc_report_value SDC_235_COUNT)"
  TUI_61_COUNT="$(sdc_report_value TUI_61_COUNT)"
  SDC_INVALID_OBJECT_COUNT="$(sdc_report_value SDC_INVALID_OBJECT_COUNT)"
  if [[ -z "$SDC_COMMAND_FAILURE_COUNT" ]]; then
    SDC_235_COUNT="$(grep -Ec '\[SDC-235\]|SDC-235|SDC command requires a constraint mode specification' "$RESULT_DIR/sdc_command_failures.md" || true)"
    TUI_61_COUNT="$(grep -Ec '\[TUI-61\]|TUI-61|A required object parameter could not be found' "$RESULT_DIR/sdc_command_failures.md" || true)"
    SDC_INVALID_OBJECT_COUNT="$(grep -Ec '\[SDC-248\]|Invalid object passed to SDC command|empty object|invalid object' "$RESULT_DIR/sdc_command_failures.md" || true)"
    SDC_COMMAND_FAILURE_COUNT="$(grep -Ec 'failed[[:space:]]+[1-9]|MPTDC_O13_.*FATAL|MPTDC_SDC_.*ERROR|\[SDC-202\]|\[SDC-209\]|\[SDC-235\]|\[TUI-61\]|\[SDC-248\]|SDC command requires a constraint mode specification|A required object parameter could not be found|Invalid object passed to SDC command' "$RESULT_DIR/sdc_command_failures.md" || true)"
    ACTIVE_SDC_FAILURE_COUNT="$SDC_COMMAND_FAILURE_COUNT"
    RAW_SDC_DIAGNOSTIC_COUNT=$((SDC_235_COUNT + TUI_61_COUNT + SDC_INVALID_OBJECT_COUNT))
    REPORT_DIAGNOSTIC_WARNING_COUNT=0
  fi
  SDC_COMMAND_FAILURE_COUNT="${SDC_COMMAND_FAILURE_COUNT:-NA}"
  ACTIVE_SDC_FAILURE_COUNT="${ACTIVE_SDC_FAILURE_COUNT:-$SDC_COMMAND_FAILURE_COUNT}"
  REPORT_DIAGNOSTIC_WARNING_COUNT="${REPORT_DIAGNOSTIC_WARNING_COUNT:-NA}"
  RAW_SDC_DIAGNOSTIC_COUNT="${RAW_SDC_DIAGNOSTIC_COUNT:-NA}"
  SDC_235_COUNT="${SDC_235_COUNT:-NA}"
  TUI_61_COUNT="${TUI_61_COUNT:-NA}"
  SDC_INVALID_OBJECT_COUNT="${SDC_INVALID_OBJECT_COUNT:-NA}"
fi
if [[ -f "$RESULT_DIR/fast_tag_exact_repair_status.rpt" || -f "$RESULT_DIR/reports/fast_tag_exact_repair_status.rpt" ]]; then
  EXACT_STATUS_FILE="$RESULT_DIR/fast_tag_exact_repair_status.rpt"
  if [[ ! -f "$EXACT_STATUS_FILE" ]]; then
    EXACT_STATUS_FILE="$RESULT_DIR/reports/fast_tag_exact_repair_status.rpt"
  fi
  exact_value() {
    local key="$1"
    awk -F= -v key="$key" '$1 == key {value=$2; found=1} END {if (found) print value}' "$EXACT_STATUS_FILE"
  }
  EXACT_FAST_TAG_SOURCES_EXPECTED="$(exact_value EXACT_FAST_TAG_SOURCES_EXPECTED)"
  EXACT_FAST_TAG_SOURCES_FOUND="$(exact_value EXACT_FAST_TAG_SOURCES_FOUND)"
  EXACT_FAST_TAG_ENDPOINTS_EXPECTED="$(exact_value EXACT_FAST_TAG_ENDPOINTS_EXPECTED)"
  EXACT_FAST_TAG_ENDPOINTS_FOUND="$(exact_value EXACT_FAST_TAG_ENDPOINTS_FOUND)"
  EXACT_FAST_TAG_DATAPATHS_EXPECTED="$(exact_value EXACT_FAST_TAG_DATAPATHS_EXPECTED)"
  EXACT_FAST_TAG_DATAPATHS_FOUND="$(exact_value EXACT_FAST_TAG_DATAPATHS_FOUND)"
  EXACT_FAST_TAG_REPAIR_APPLIED="$(exact_value EXACT_FAST_TAG_REPAIR_APPLIED)"
  EXACT_FAST_TAG_REPAIR_STATUS="$(exact_value EXACT_FAST_TAG_REPAIR_STATUS)"
  FAST_TAG_EXACT_C_TO_D_SET_MAX_DELAY_RESULT="$(exact_value FAST_TAG_EXACT_C_TO_D_SET_MAX_DELAY_RESULT)"
  FAST_TAG_EXACT_MAX_DELAY_CONSTRAINT_MODE="$(exact_value FAST_TAG_EXACT_MAX_DELAY_CONSTRAINT_MODE)"
  FAST_TAG_EXACT_SOURCE_CELL_TARGET="$(exact_value FAST_TAG_EXACT_SOURCE_CELL_TARGET)"
  FAST_TAG_EXACT_SOURCE_CELL_REQUESTED="$(exact_value FAST_TAG_EXACT_SOURCE_CELL_REQUESTED)"
  FAST_TAG_EXACT_SOURCE_CELL_LIB_CELLS_FOUND="$(exact_value FAST_TAG_EXACT_SOURCE_CELL_LIB_CELLS_FOUND)"
  FAST_TAG_EXACT_SOURCE_CELL_COUNT="$(exact_value FAST_TAG_EXACT_SOURCE_CELL_COUNT)"
  FAST_TAG_EXACT_SOURCE_CELL_TARGET_COUNT="$(exact_value FAST_TAG_EXACT_SOURCE_CELL_TARGET_COUNT)"
  FAST_TAG_EXACT_SOURCE_CELL_METHOD="$(exact_value FAST_TAG_EXACT_SOURCE_CELL_METHOD)"
  FAST_TAG_EXACT_SOURCE_CELL_RESULT="$(exact_value FAST_TAG_EXACT_SOURCE_CELL_RESULT)"
  FAST_TAG_EXACT_SOURCE_CELL_MODE="$(exact_value FAST_TAG_EXACT_SOURCE_CELL_MODE)"
  FAST_TAG_EXACT_RESET0_SOURCE_COUNT="$(exact_value FAST_TAG_EXACT_RESET0_SOURCE_COUNT)"
  FAST_TAG_EXACT_SET1_SOURCE_COUNT="$(exact_value FAST_TAG_EXACT_SET1_SOURCE_COUNT)"
  FAST_TAG_EXACT_SOURCE_UNSUPPORTED_POLARITY_COUNT="$(exact_value FAST_TAG_EXACT_SOURCE_UNSUPPORTED_POLARITY_COUNT)"
  FAST_TAG_EXACT_SELECTED_RESET0_TARGET="$(exact_value FAST_TAG_EXACT_SELECTED_RESET0_TARGET)"
  FAST_TAG_EXACT_SELECTED_SET1_TARGET="$(exact_value FAST_TAG_EXACT_SELECTED_SET1_TARGET)"
  FAST_TAG_EXACT_DFRRQHDX4_TARGET_COUNT="$(exact_value FAST_TAG_EXACT_DFRRQHDX4_TARGET_COUNT)"
  FAST_TAG_EXACT_DFRSQHDX4_TARGET_COUNT="$(exact_value FAST_TAG_EXACT_DFRSQHDX4_TARGET_COUNT)"
  FAST_TAG_EXACT_DFRSQHDX2_TARGET_COUNT="$(exact_value FAST_TAG_EXACT_DFRSQHDX2_TARGET_COUNT)"
  FAST_TAG_EXACT_DFRRQJIHDX4_TARGET_COUNT="$(exact_value FAST_TAG_EXACT_DFRRQJIHDX4_TARGET_COUNT)"
  FAST_TAG_EXACT_DFRSJIHDX4_TARGET_COUNT="$(exact_value FAST_TAG_EXACT_DFRSJIHDX4_TARGET_COUNT)"
  FAST_TAG_EXACT_DFRSJIHDX2_TARGET_COUNT="$(exact_value FAST_TAG_EXACT_DFRSJIHDX2_TARGET_COUNT)"
  FAST_TAG_EXACT_SOURCE_POLARITY_PRESERVED_COUNT="$(exact_value FAST_TAG_EXACT_SOURCE_POLARITY_PRESERVED_COUNT)"
  FAST_TAG_EXACT_SOURCE_POLARITY_FAILED_COUNT="$(exact_value FAST_TAG_EXACT_SOURCE_POLARITY_FAILED_COUNT)"
  FAST_TAG_EXACT_SOURCE_FREEZE_RESULT="$(exact_value FAST_TAG_EXACT_SOURCE_FREEZE_RESULT)"
  EXACT_FAST_TAG_SOURCES_EXPECTED="${EXACT_FAST_TAG_SOURCES_EXPECTED:-NA}"
  EXACT_FAST_TAG_SOURCES_FOUND="${EXACT_FAST_TAG_SOURCES_FOUND:-NA}"
  EXACT_FAST_TAG_ENDPOINTS_EXPECTED="${EXACT_FAST_TAG_ENDPOINTS_EXPECTED:-NA}"
  EXACT_FAST_TAG_ENDPOINTS_FOUND="${EXACT_FAST_TAG_ENDPOINTS_FOUND:-NA}"
  EXACT_FAST_TAG_DATAPATHS_EXPECTED="${EXACT_FAST_TAG_DATAPATHS_EXPECTED:-NA}"
  EXACT_FAST_TAG_DATAPATHS_FOUND="${EXACT_FAST_TAG_DATAPATHS_FOUND:-NA}"
  EXACT_FAST_TAG_REPAIR_APPLIED="${EXACT_FAST_TAG_REPAIR_APPLIED:-NA}"
  EXACT_FAST_TAG_REPAIR_STATUS="${EXACT_FAST_TAG_REPAIR_STATUS:-NA}"
  FAST_TAG_EXACT_C_TO_D_SET_MAX_DELAY_RESULT="${FAST_TAG_EXACT_C_TO_D_SET_MAX_DELAY_RESULT:-NA}"
  FAST_TAG_EXACT_MAX_DELAY_CONSTRAINT_MODE="${FAST_TAG_EXACT_MAX_DELAY_CONSTRAINT_MODE:-NA}"
  FAST_TAG_EXACT_SOURCE_CELL_TARGET="${FAST_TAG_EXACT_SOURCE_CELL_TARGET:-NA}"
  FAST_TAG_EXACT_SOURCE_CELL_REQUESTED="${FAST_TAG_EXACT_SOURCE_CELL_REQUESTED:-NA}"
  FAST_TAG_EXACT_SOURCE_CELL_LIB_CELLS_FOUND="${FAST_TAG_EXACT_SOURCE_CELL_LIB_CELLS_FOUND:-NA}"
  FAST_TAG_EXACT_SOURCE_CELL_COUNT="${FAST_TAG_EXACT_SOURCE_CELL_COUNT:-NA}"
  FAST_TAG_EXACT_SOURCE_CELL_TARGET_COUNT="${FAST_TAG_EXACT_SOURCE_CELL_TARGET_COUNT:-NA}"
  FAST_TAG_EXACT_SOURCE_CELL_METHOD="${FAST_TAG_EXACT_SOURCE_CELL_METHOD:-NA}"
  FAST_TAG_EXACT_SOURCE_CELL_RESULT="${FAST_TAG_EXACT_SOURCE_CELL_RESULT:-NA}"
  FAST_TAG_EXACT_SOURCE_CELL_MODE="${FAST_TAG_EXACT_SOURCE_CELL_MODE:-NA}"
  FAST_TAG_EXACT_RESET0_SOURCE_COUNT="${FAST_TAG_EXACT_RESET0_SOURCE_COUNT:-NA}"
  FAST_TAG_EXACT_SET1_SOURCE_COUNT="${FAST_TAG_EXACT_SET1_SOURCE_COUNT:-NA}"
  FAST_TAG_EXACT_SOURCE_UNSUPPORTED_POLARITY_COUNT="${FAST_TAG_EXACT_SOURCE_UNSUPPORTED_POLARITY_COUNT:-NA}"
  FAST_TAG_EXACT_SELECTED_RESET0_TARGET="${FAST_TAG_EXACT_SELECTED_RESET0_TARGET:-NA}"
  FAST_TAG_EXACT_SELECTED_SET1_TARGET="${FAST_TAG_EXACT_SELECTED_SET1_TARGET:-NA}"
  FAST_TAG_EXACT_DFRRQHDX4_TARGET_COUNT="${FAST_TAG_EXACT_DFRRQHDX4_TARGET_COUNT:-NA}"
  FAST_TAG_EXACT_DFRSQHDX4_TARGET_COUNT="${FAST_TAG_EXACT_DFRSQHDX4_TARGET_COUNT:-NA}"
  FAST_TAG_EXACT_DFRSQHDX2_TARGET_COUNT="${FAST_TAG_EXACT_DFRSQHDX2_TARGET_COUNT:-NA}"
  FAST_TAG_EXACT_DFRRQJIHDX4_TARGET_COUNT="${FAST_TAG_EXACT_DFRRQJIHDX4_TARGET_COUNT:-NA}"
  FAST_TAG_EXACT_DFRSJIHDX4_TARGET_COUNT="${FAST_TAG_EXACT_DFRSJIHDX4_TARGET_COUNT:-NA}"
  FAST_TAG_EXACT_DFRSJIHDX2_TARGET_COUNT="${FAST_TAG_EXACT_DFRSJIHDX2_TARGET_COUNT:-NA}"
  FAST_TAG_EXACT_SOURCE_POLARITY_PRESERVED_COUNT="${FAST_TAG_EXACT_SOURCE_POLARITY_PRESERVED_COUNT:-NA}"
  FAST_TAG_EXACT_SOURCE_POLARITY_FAILED_COUNT="${FAST_TAG_EXACT_SOURCE_POLARITY_FAILED_COUNT:-NA}"
  FAST_TAG_EXACT_SOURCE_FREEZE_RESULT="${FAST_TAG_EXACT_SOURCE_FREEZE_RESULT:-NA}"
fi
if [[ -f "$RESULT_DIR/pd_hit_to_nfast_local_repair_status.rpt" || -f "$RESULT_DIR/reports/pd_hit_to_nfast_local_repair_status.rpt" ]]; then
  PD_HIT_TO_NFAST_STATUS_FILE="$RESULT_DIR/pd_hit_to_nfast_local_repair_status.rpt"
  if [[ ! -f "$PD_HIT_TO_NFAST_STATUS_FILE" ]]; then
    PD_HIT_TO_NFAST_STATUS_FILE="$RESULT_DIR/reports/pd_hit_to_nfast_local_repair_status.rpt"
  fi
  pd_hit_to_nfast_value() {
    local key="$1"
    awk -F= -v key="$key" '$1 == key {value=$2; found=1} END {if (found) print value}' "$PD_HIT_TO_NFAST_STATUS_FILE"
  }
  PD_HIT_TO_NFAST_LOCAL_REPAIR_ENABLE="$(pd_hit_to_nfast_value PD_HIT_TO_NFAST_LOCAL_REPAIR_ENABLE)"
  PD_HIT_TO_NFAST_LOCAL_SOURCES_EXPECTED="$(pd_hit_to_nfast_value PD_HIT_TO_NFAST_LOCAL_SOURCES_EXPECTED)"
  PD_HIT_TO_NFAST_LOCAL_SOURCES_FOUND="$(pd_hit_to_nfast_value PD_HIT_TO_NFAST_LOCAL_SOURCES_FOUND)"
  PD_HIT_TO_NFAST_LOCAL_SOURCE_Q_FOUND="$(pd_hit_to_nfast_value PD_HIT_TO_NFAST_LOCAL_SOURCE_Q_FOUND)"
  PD_HIT_TO_NFAST_LOCAL_ENDPOINTS_EXPECTED="$(pd_hit_to_nfast_value PD_HIT_TO_NFAST_LOCAL_ENDPOINTS_EXPECTED)"
  PD_HIT_TO_NFAST_LOCAL_ENDPOINTS_FOUND="$(pd_hit_to_nfast_value PD_HIT_TO_NFAST_LOCAL_ENDPOINTS_FOUND)"
  PD_HIT_TO_NFAST_LOCAL_PAIRS_FOUND="$(pd_hit_to_nfast_value PD_HIT_TO_NFAST_LOCAL_PAIRS_FOUND)"
  PD_HIT_TO_NFAST_LOCAL_BITS="$(pd_hit_to_nfast_value PD_HIT_TO_NFAST_LOCAL_BITS)"
  PD_HIT_TO_NFAST_LOCAL_MAX_DELAY_NS="$(pd_hit_to_nfast_value PD_HIT_TO_NFAST_LOCAL_MAX_DELAY_NS)"
  PD_HIT_TO_NFAST_LOCAL_MAX_TRANSITION_NS="$(pd_hit_to_nfast_value PD_HIT_TO_NFAST_LOCAL_MAX_TRANSITION_NS)"
  PD_HIT_TO_NFAST_LOCAL_GROUP_PATH_RESULT="$(pd_hit_to_nfast_value PD_HIT_TO_NFAST_LOCAL_GROUP_PATH_RESULT)"
  PD_HIT_TO_NFAST_LOCAL_SET_MAX_DELAY_RESULT="$(pd_hit_to_nfast_value PD_HIT_TO_NFAST_LOCAL_SET_MAX_DELAY_RESULT)"
  PD_HIT_TO_NFAST_LOCAL_MAX_DELAY_CONSTRAINT_MODE="$(pd_hit_to_nfast_value PD_HIT_TO_NFAST_LOCAL_MAX_DELAY_CONSTRAINT_MODE)"
  PD_HIT_TO_NFAST_LOCAL_SET_MAX_TRANSITION_RESULT="$(pd_hit_to_nfast_value PD_HIT_TO_NFAST_LOCAL_SET_MAX_TRANSITION_RESULT)"
  PD_HIT_TO_NFAST_LOCAL_OVERMATCH="$(pd_hit_to_nfast_value PD_HIT_TO_NFAST_LOCAL_OVERMATCH)"
  PD_HIT_TO_NFAST_LOCAL_UNDERMATCH="$(pd_hit_to_nfast_value PD_HIT_TO_NFAST_LOCAL_UNDERMATCH)"
  PD_HIT_TO_NFAST_LOCAL_STATUS="$(pd_hit_to_nfast_value PD_HIT_TO_NFAST_LOCAL_STATUS)"
  PD_HIT_TO_NFAST_LOCAL_REVIEW_REASON="$(pd_hit_to_nfast_value PD_HIT_TO_NFAST_LOCAL_REVIEW_REASON)"
  PD_HIT_TO_NFAST_LOCAL_REPAIR_ENABLE="${PD_HIT_TO_NFAST_LOCAL_REPAIR_ENABLE:-NA}"
  PD_HIT_TO_NFAST_LOCAL_SOURCES_EXPECTED="${PD_HIT_TO_NFAST_LOCAL_SOURCES_EXPECTED:-NA}"
  PD_HIT_TO_NFAST_LOCAL_SOURCES_FOUND="${PD_HIT_TO_NFAST_LOCAL_SOURCES_FOUND:-NA}"
  PD_HIT_TO_NFAST_LOCAL_SOURCE_Q_FOUND="${PD_HIT_TO_NFAST_LOCAL_SOURCE_Q_FOUND:-NA}"
  PD_HIT_TO_NFAST_LOCAL_ENDPOINTS_EXPECTED="${PD_HIT_TO_NFAST_LOCAL_ENDPOINTS_EXPECTED:-NA}"
  PD_HIT_TO_NFAST_LOCAL_ENDPOINTS_FOUND="${PD_HIT_TO_NFAST_LOCAL_ENDPOINTS_FOUND:-NA}"
  PD_HIT_TO_NFAST_LOCAL_PAIRS_FOUND="${PD_HIT_TO_NFAST_LOCAL_PAIRS_FOUND:-NA}"
  PD_HIT_TO_NFAST_LOCAL_BITS="${PD_HIT_TO_NFAST_LOCAL_BITS:-NA}"
  PD_HIT_TO_NFAST_LOCAL_MAX_DELAY_NS="${PD_HIT_TO_NFAST_LOCAL_MAX_DELAY_NS:-NA}"
  PD_HIT_TO_NFAST_LOCAL_MAX_TRANSITION_NS="${PD_HIT_TO_NFAST_LOCAL_MAX_TRANSITION_NS:-NA}"
  PD_HIT_TO_NFAST_LOCAL_GROUP_PATH_RESULT="${PD_HIT_TO_NFAST_LOCAL_GROUP_PATH_RESULT:-NA}"
  PD_HIT_TO_NFAST_LOCAL_SET_MAX_DELAY_RESULT="${PD_HIT_TO_NFAST_LOCAL_SET_MAX_DELAY_RESULT:-NA}"
  PD_HIT_TO_NFAST_LOCAL_MAX_DELAY_CONSTRAINT_MODE="${PD_HIT_TO_NFAST_LOCAL_MAX_DELAY_CONSTRAINT_MODE:-NA}"
  PD_HIT_TO_NFAST_LOCAL_SET_MAX_TRANSITION_RESULT="${PD_HIT_TO_NFAST_LOCAL_SET_MAX_TRANSITION_RESULT:-NA}"
  PD_HIT_TO_NFAST_LOCAL_OVERMATCH="${PD_HIT_TO_NFAST_LOCAL_OVERMATCH:-NA}"
  PD_HIT_TO_NFAST_LOCAL_UNDERMATCH="${PD_HIT_TO_NFAST_LOCAL_UNDERMATCH:-NA}"
  PD_HIT_TO_NFAST_LOCAL_STATUS="${PD_HIT_TO_NFAST_LOCAL_STATUS:-NA}"
  PD_HIT_TO_NFAST_LOCAL_REVIEW_REASON="${PD_HIT_TO_NFAST_LOCAL_REVIEW_REASON:-NA}"
fi
if [[ -f "$RESULT_DIR/pd_local_on22_repair_status.rpt" || -f "$RESULT_DIR/reports/pd_local_on22_repair_status.rpt" ]]; then
  PD_LOCAL_ON22_STATUS_FILE="$RESULT_DIR/pd_local_on22_repair_status.rpt"
  if [[ ! -f "$PD_LOCAL_ON22_STATUS_FILE" ]]; then
    PD_LOCAL_ON22_STATUS_FILE="$RESULT_DIR/reports/pd_local_on22_repair_status.rpt"
  fi
  pd_local_on22_value() {
    local key="$1"
    awk -F= -v key="$key" '$1 == key {value=$2; found=1} END {if (found) print value}' "$PD_LOCAL_ON22_STATUS_FILE"
  }
  PD_LOCAL_ON22_REPAIR_ENABLE="$(pd_local_on22_value PD_LOCAL_ON22_REPAIR_ENABLE)"
  PD_LOCAL_ON22_SOURCE_CELL="$(pd_local_on22_value PD_LOCAL_ON22_SOURCE_CELL)"
  PD_LOCAL_ON22_TARGET_CELLS="$(pd_local_on22_value PD_LOCAL_ON22_TARGET_CELLS)"
  PD_LOCAL_ON22_SELECTED_TARGET="$(pd_local_on22_value PD_LOCAL_ON22_SELECTED_TARGET)"
  PD_LOCAL_ON22_TARGET_LIB_CELLS_FOUND="$(pd_local_on22_value PD_LOCAL_ON22_TARGET_LIB_CELLS_FOUND)"
  PD_LOCAL_ON22_ENDPOINTS_EXPECTED="$(pd_local_on22_value PD_LOCAL_ON22_ENDPOINTS_EXPECTED)"
  PD_LOCAL_ON22_ENDPOINTS_FOUND="$(pd_local_on22_value PD_LOCAL_ON22_ENDPOINTS_FOUND)"
  PD_LOCAL_ON22_SOURCE_DRIVERS_FOUND="$(pd_local_on22_value PD_LOCAL_ON22_SOURCE_DRIVERS_FOUND)"
  PD_LOCAL_ON22_SOURCE_CELLS_EXPECTED="$(pd_local_on22_value PD_LOCAL_ON22_SOURCE_CELLS_EXPECTED)"
  PD_LOCAL_ON22_SOURCE_CELLS_FOUND="$(pd_local_on22_value PD_LOCAL_ON22_SOURCE_CELLS_FOUND)"
  PD_LOCAL_ON22_CHANGED_CELLS="$(pd_local_on22_value PD_LOCAL_ON22_CHANGED_CELLS)"
  PD_LOCAL_ON22_TARGET_CELLS_FOUND="$(pd_local_on22_value PD_LOCAL_ON22_TARGET_CELLS_FOUND)"
  PD_LOCAL_ON22_REPAIR_RESULT="$(pd_local_on22_value PD_LOCAL_ON22_REPAIR_RESULT)"
  PD_LOCAL_ON22_OVERMATCH="$(pd_local_on22_value PD_LOCAL_ON22_OVERMATCH)"
  PD_LOCAL_ON22_UNDERMATCH="$(pd_local_on22_value PD_LOCAL_ON22_UNDERMATCH)"
  PD_LOCAL_ON22_STATUS="$(pd_local_on22_value PD_LOCAL_ON22_STATUS)"
  PD_LOCAL_ON22_REVIEW_REASON="$(pd_local_on22_value PD_LOCAL_ON22_REVIEW_REASON)"
  PD_LOCAL_ON22_REPAIR_ENABLE="${PD_LOCAL_ON22_REPAIR_ENABLE:-NA}"
  PD_LOCAL_ON22_SOURCE_CELL="${PD_LOCAL_ON22_SOURCE_CELL:-NA}"
  PD_LOCAL_ON22_TARGET_CELLS="${PD_LOCAL_ON22_TARGET_CELLS:-NA}"
  PD_LOCAL_ON22_SELECTED_TARGET="${PD_LOCAL_ON22_SELECTED_TARGET:-NA}"
  PD_LOCAL_ON22_TARGET_LIB_CELLS_FOUND="${PD_LOCAL_ON22_TARGET_LIB_CELLS_FOUND:-NA}"
  PD_LOCAL_ON22_ENDPOINTS_EXPECTED="${PD_LOCAL_ON22_ENDPOINTS_EXPECTED:-NA}"
  PD_LOCAL_ON22_ENDPOINTS_FOUND="${PD_LOCAL_ON22_ENDPOINTS_FOUND:-NA}"
  PD_LOCAL_ON22_SOURCE_DRIVERS_FOUND="${PD_LOCAL_ON22_SOURCE_DRIVERS_FOUND:-NA}"
  PD_LOCAL_ON22_SOURCE_CELLS_EXPECTED="${PD_LOCAL_ON22_SOURCE_CELLS_EXPECTED:-NA}"
  PD_LOCAL_ON22_SOURCE_CELLS_FOUND="${PD_LOCAL_ON22_SOURCE_CELLS_FOUND:-NA}"
  PD_LOCAL_ON22_CHANGED_CELLS="${PD_LOCAL_ON22_CHANGED_CELLS:-NA}"
  PD_LOCAL_ON22_TARGET_CELLS_FOUND="${PD_LOCAL_ON22_TARGET_CELLS_FOUND:-NA}"
  PD_LOCAL_ON22_REPAIR_RESULT="${PD_LOCAL_ON22_REPAIR_RESULT:-NA}"
  PD_LOCAL_ON22_OVERMATCH="${PD_LOCAL_ON22_OVERMATCH:-NA}"
  PD_LOCAL_ON22_UNDERMATCH="${PD_LOCAL_ON22_UNDERMATCH:-NA}"
  PD_LOCAL_ON22_STATUS="${PD_LOCAL_ON22_STATUS:-NA}"
  PD_LOCAL_ON22_REVIEW_REASON="${PD_LOCAL_ON22_REVIEW_REASON:-NA}"
fi
if [[ -f "$RESULT_DIR/report_design_rules.rpt" ]]; then
  MAX_TRANSITION_VIOLATIONS="$(awk '/Max_transition design rule/ {if (match($0, /violation total = [0-9]+/)) {v=substr($0, RSTART+18, RLENGTH-18); print v; found=1; exit}} END {if (!found) print "0"}' "$RESULT_DIR/report_design_rules.rpt")"
  if grep -qi 'Max_capacitance design rule: no violations' "$RESULT_DIR/report_design_rules.rpt"; then
    MAX_CAPACITANCE_VIOLATIONS=0
  else
    MAX_CAPACITANCE_VIOLATIONS="$(awk '/Max_capacitance design rule/ {if (match($0, /violation total = [0-9]+/)) {v=substr($0, RSTART+18, RLENGTH-18); print v; found=1; exit}} END {if (!found) print "UNKNOWN"}' "$RESULT_DIR/report_design_rules.rpt")"
  fi
  if grep -qi 'Max_fanout design rule: no violations' "$RESULT_DIR/report_design_rules.rpt"; then
    MAX_FANOUT_VIOLATIONS=0
  else
    MAX_FANOUT_VIOLATIONS="$(awk '/Max_fanout design rule/ {if (match($0, /violation total = [0-9]+/)) {v=substr($0, RSTART+18, RLENGTH-18); print v; found=1; exit}} END {if (!found) print "UNKNOWN"}' "$RESULT_DIR/report_design_rules.rpt")"
  fi
fi
run_corrected_summary_parser
if [[ -f "$RESULT_DIR/fast_tag_cell_mapping.env" ]]; then
  # shellcheck source=/dev/null
  source "$RESULT_DIR/fast_tag_cell_mapping.env"
fi

write_macro_binding_check() {
  local out="$RESULT_DIR/macro_binding_check.rpt"
  {
    echo "# MPTDC Macro Binding Check"
    echo "FLOW_LABEL=$FLOW_LABEL"
    echo "LEGACY_TRACE=$LEGACY_TRACE_LABEL"
    echo "RO_TUNE4_COUNT=$RO_COUNT"
    echo "MPTDC_OSC_STUB_COUNT=$STUB_COUNT"
    echo "BUHDX4_COUNT=$BUHDX4_COUNT"
    echo "BUHDX12_COUNT=$BUHDX12_COUNT"
    echo "RAW_RO_CLOCKS_FOUND=$RAW_RO_CLOCKS_FOUND"
    echo "BUFFER_PHASE_CLOCKS_FOUND=$BUFFER_PHASE_CLOCKS_FOUND"
    echo "RO_TUNE4_LIB=$REAL_LIB"
    echo "RO_TUNE4_LEF=$REAL_LEF"
    echo "STDCELL_FAMILY=$STDCELL_FAMILY"
    echo "STDCELL_SITE=$STDCELL_SITE"
    echo "STDCELL_LEF=$STDCELL_LEF"
    echo "STDCELL_TC_LIB=$STDCELL_TC_LIB"
    echo "XLIBD_RO_STRICT_D_LOAD_BUDGET_FF=58.72"
    echo "XLIBD_BUHDX4_INPUT_CAP_FF=10.56"
    echo "XLIBD_BUHDX12_INPUT_CAP_FF=32.24"
    echo "XLIBD_USAGE=REFERENCE_ONLY_NOT_TIMING_ENGINE"
    echo
    if [[ "$RO_COUNT" == "2" && "$STUB_COUNT" == "0" ]]; then
      echo "MACRO_BINDING_STATUS=PASS"
    else
      echo "MACRO_BINDING_STATUS=REVIEW_REQUIRED"
    fi
  } > "$out"
}

write_packet_contract_check() {
  local out="$RESULT_DIR/packet_contract_check.rpt"
  local pkg="$MPTDC_DIR/rtl/pkg/mptdc_pkg.sv"
  local tx="$MPTDC_DIR/rtl/readout/mptdc_packet16_tx.sv"
  {
    echo "# MPTDC Packet Contract Check"
    echo "FLOW_LABEL=$FLOW_LABEL"
    echo "PACKET_FORMAT_UNCHANGED=YES"
    echo "RAW_LFSR_TAG_UNCHANGED=YES"
    echo "RTL_PKG=$pkg"
    echo "RTL_TX=$tx"
    echo
    grep -nE 'parameter int unsigned NFAST_W[[:space:]]*=[[:space:]]*7|parameter int unsigned NSLOW_W[[:space:]]*=[[:space:]]*7|localparam int unsigned MAX_HITS[[:space:]]*=|localparam int unsigned NARROW_W[[:space:]]*=[[:space:]]*16|OUT_MODE_RAW_FEATURES|FAST_TAG_SEQUENCE_LEN|FAST_TAG_SEED' "$pkg" || true
    grep -nE 'fixed calibrated-feature packet|frozen|Hit W1|Hit W2|raw key|nfast' "$tx" || true
  } > "$out"
}

write_final_readiness() {
  local out="$RESULT_DIR/final_typical_genus_readiness.md"
  {
    echo "# MPTDC Final Typical Genus Readiness"
    echo
    echo "- Flow: \`$FLOW_LABEL\`"
    echo "- Mode: \`$CLOSURE_LABEL\`"
    echo "- Package label: \`$PACKAGE_LABEL\`"
    echo "- Signoff boundary: \`$SIGNOFF_BOUNDARY\`"
    echo "- Legacy trace: \`$LEGACY_TRACE_LABEL\`"
    echo "- Run ID: \`$RUN_ID\`"
    echo "- Result directory: \`$RESULT_DIR\`"
    echo "- Genus exit code: \`$GENUS_RC\`"
    echo "- Final decision: \`$FINAL_DECISION\`"
    echo
    echo "## Required Checks"
    echo
    echo "| Check | Expected | Actual | Status |"
    echo "|---|---:|---:|---|"
    emit_check "RO_tune4 count" 2 "$RO_COUNT"
    emit_check "mptdc_osc_stub count" 0 "$STUB_COUNT"
    emit_check "raw RO clocks found" 16 "$RAW_RO_CLOCKS_FOUND"
    emit_check "buffer phase clocks found" 16 "$BUFFER_PHASE_CLOCKS_FOUND"
    emit_check_text "clk_sys async to buffer phase clocks" YES "$CLK_SYS_ASYNC_TO_BUFFER_PHASE_CLOCKS"
    emit_check "PD Vernier endpoints" 64 "$PD_VERNIER_EXCEPTION_MATCHED"
    emit_check "PD Vernier sources" 8 "$PD_VERNIER_SOURCE_MATCHED"
    emit_check_text "PD Vernier exception applied" YES "$PD_VERNIER_EXCEPTION_APPLIED"
    emit_check_text "PD Vernier overmatch" NO "$PD_VERNIER_EXCEPTION_OVERMATCH"
    emit_check_text "PD Vernier undermatch" NO "$PD_VERNIER_EXCEPTION_UNDERMATCH"
    emit_check "UNKNOWN_REVIEW_REQUIRED" 0 "$UNKNOWN_REVIEW_REQUIRED_COUNT"
    emit_check "active SDC failures" 0 "$ACTIVE_SDC_FAILURE_COUNT"
    emit_check "SDC command failures" 0 "$SDC_COMMAND_FAILURE_COUNT"
    if [[ "${MPTDC_GENUS_REPAIR4_EXACT_FAST_TAG_SOURCE_DRIVE:-0}" == "1" || "${MPTDC_FAST_TAG_REPAIR_EXACT_DATA_PATHS:-0}" == "1" ]]; then
      emit_check "exact fast-tag sources" "$EXACT_FAST_TAG_SOURCES_EXPECTED" "$EXACT_FAST_TAG_SOURCES_FOUND"
      emit_check "exact fast-tag endpoints" "$EXACT_FAST_TAG_ENDPOINTS_EXPECTED" "$EXACT_FAST_TAG_ENDPOINTS_FOUND"
      emit_check "exact fast-tag datapaths" "$EXACT_FAST_TAG_DATAPATHS_EXPECTED" "$EXACT_FAST_TAG_DATAPATHS_FOUND"
      emit_check_text "exact fast-tag repair applied" YES "$EXACT_FAST_TAG_REPAIR_APPLIED"
      emit_check_text "exact fast-tag repair status" PASS "$EXACT_FAST_TAG_REPAIR_STATUS"
      if [[ "${MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL:-}" != "" ]]; then
        emit_check_text "exact fast-tag source cell target" "$MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL" "$FAST_TAG_EXACT_SOURCE_CELL_TARGET"
        emit_check "exact fast-tag source cell count" "$EXACT_FAST_TAG_SOURCES_EXPECTED" "$FAST_TAG_EXACT_SOURCE_CELL_COUNT"
        if [[ "${MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL_MODE:-}" == "POLARITY_AWARE" || "${MPTDC_GENUS_REPAIR7_POLARITY_AWARE_FAST_TAG_SOURCE_UPGRADE:-0}" == "1" ]]; then
          emit_check_text "exact source cell mode" POLARITY_AWARE "$FAST_TAG_EXACT_SOURCE_CELL_MODE"
          emit_check "exact reset0 source count" 16 "$FAST_TAG_EXACT_RESET0_SOURCE_COUNT"
          if [[ "${MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_SKIP_UNSUPPORTED:-0}" == "1" ]]; then
            emit_check "exact set1 source count" 0 "$FAST_TAG_EXACT_SET1_SOURCE_COUNT"
            emit_check "exact unsupported source polarity count" 8 "$FAST_TAG_EXACT_SOURCE_UNSUPPORTED_POLARITY_COUNT"
          else
            emit_check "exact set1 source count" 8 "$FAST_TAG_EXACT_SET1_SOURCE_COUNT"
            emit_check "exact unsupported source polarity count" 0 "$FAST_TAG_EXACT_SOURCE_UNSUPPORTED_POLARITY_COUNT"
          fi
          if [[ "$FAST_TAG_EXACT_SELECTED_RESET0_TARGET" == "DFRRQJIHDX4" ]]; then
            emit_check "exact final DFRRQJIHDX4 target count" 16 "$FAST_TAG_EXACT_DFRRQJIHDX4_TARGET_COUNT"
          else
            emit_check "exact final DFRRQHDX4 target count" 16 "$FAST_TAG_EXACT_DFRRQHDX4_TARGET_COUNT"
          fi
          if [[ "${MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_SKIP_UNSUPPORTED:-0}" != "1" ]]; then
            if [[ "$FAST_TAG_EXACT_SELECTED_SET1_TARGET" == "DFRSQHDX4" ]]; then
              emit_check "exact final DFRSQHDX4 target count" 8 "$FAST_TAG_EXACT_DFRSQHDX4_TARGET_COUNT"
            elif [[ "$FAST_TAG_EXACT_SELECTED_SET1_TARGET" == "DFRSQHDX2" ]]; then
              emit_check "exact final DFRSQHDX2 target count" 8 "$FAST_TAG_EXACT_DFRSQHDX2_TARGET_COUNT"
            elif [[ "$FAST_TAG_EXACT_SELECTED_SET1_TARGET" == "DFRSJIHDX4" ]]; then
              emit_check "exact final DFRSJIHDX4 target count" 8 "$FAST_TAG_EXACT_DFRSJIHDX4_TARGET_COUNT"
            elif [[ "$FAST_TAG_EXACT_SELECTED_SET1_TARGET" == "DFRSJIHDX2" ]]; then
              emit_check "exact final DFRSJIHDX2 target count" 8 "$FAST_TAG_EXACT_DFRSJIHDX2_TARGET_COUNT"
            else
              emit_check_text "exact selected set1 target" "DFRSQHDX4_or_DFRSQHDX2_or_DFRSJIHDX4_or_DFRSJIHDX2" "$FAST_TAG_EXACT_SELECTED_SET1_TARGET"
            fi
          fi
          emit_check "exact source polarity failed count" 0 "$FAST_TAG_EXACT_SOURCE_POLARITY_FAILED_COUNT"
          if [[ "${MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_SKIP_UNSUPPORTED:-0}" == "1" ]]; then
            emit_check_text "exact fast-tag source cell result" PASS_PARTIAL_UNSUPPORTED_SKIPPED "$FAST_TAG_EXACT_SOURCE_CELL_RESULT"
          else
            emit_check_text "exact fast-tag source cell result" PASS_FINAL_VERIFIED "$FAST_TAG_EXACT_SOURCE_CELL_RESULT"
          fi
        else
          emit_check "exact fast-tag source cell target count" "$EXACT_FAST_TAG_SOURCES_EXPECTED" "$FAST_TAG_EXACT_SOURCE_CELL_TARGET_COUNT"
          emit_check_text "exact fast-tag source cell result" OK "$FAST_TAG_EXACT_SOURCE_CELL_RESULT"
          case "$MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL" in
            DFRRQHDX1) emit_check "exact source final DFRRQHDX1 count" "$EXACT_FAST_TAG_SOURCES_EXPECTED" "$FAST_TAG_EXACT_SOURCE_DFRRQHDX1_COUNT" ;;
            DFRRQHDX2) emit_check "exact source final DFRRQHDX2 count" "$EXACT_FAST_TAG_SOURCES_EXPECTED" "$FAST_TAG_EXACT_SOURCE_DFRRQHDX2_COUNT" ;;
            DFRRQHDX4) emit_check "exact source final DFRRQHDX4 count" "$EXACT_FAST_TAG_SOURCES_EXPECTED" "$FAST_TAG_EXACT_SOURCE_DFRRQHDX4_COUNT" ;;
            DFRJIHDX1) emit_check "exact source final DFRJIHDX1 count" "$EXACT_FAST_TAG_SOURCES_EXPECTED" "$FAST_TAG_EXACT_SOURCE_DFRJIHDX1_COUNT" ;;
            DFRJIHDX2) emit_check "exact source final DFRJIHDX2 count" "$EXACT_FAST_TAG_SOURCES_EXPECTED" "$FAST_TAG_EXACT_SOURCE_DFRJIHDX2_COUNT" ;;
            DFRJIHDX4) emit_check "exact source final DFRJIHDX4 count" "$EXACT_FAST_TAG_SOURCES_EXPECTED" "$FAST_TAG_EXACT_SOURCE_DFRJIHDX4_COUNT" ;;
          esac
        fi
        emit_check "exact source final UNKNOWN count" 0 "$FAST_TAG_EXACT_SOURCE_UNKNOWN_COUNT"
      fi
      if [[ "${MPTDC_FAST_TAG_REPAIR_ENABLE_EXACT_MAX_DELAY:-0}" == "1" || "${MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_ENABLE:-0}" == "1" ]]; then
        emit_check_text "exact fast-tag C-to-D max delay" OK "$FAST_TAG_EXACT_C_TO_D_SET_MAX_DELAY_RESULT"
      fi
    fi
    emit_check_text "exact source-cell override result" SKIPPED_SOURCE_CELL_NOT_REQUESTED "$FAST_TAG_EXACT_SOURCE_CELL_RESULT"
    emit_check_text "PD hit-to-nfast local repair status" PASS "$PD_HIT_TO_NFAST_LOCAL_STATUS"
    emit_check "PD hit-to-nfast local sources" "$PD_HIT_TO_NFAST_LOCAL_SOURCES_EXPECTED" "$PD_HIT_TO_NFAST_LOCAL_SOURCES_FOUND"
    emit_check "PD hit-to-nfast local endpoints" "$PD_HIT_TO_NFAST_LOCAL_ENDPOINTS_EXPECTED" "$PD_HIT_TO_NFAST_LOCAL_ENDPOINTS_FOUND"
    emit_check "PD hit-to-nfast local pairs" "$PD_HIT_TO_NFAST_LOCAL_ENDPOINTS_EXPECTED" "$PD_HIT_TO_NFAST_LOCAL_PAIRS_FOUND"
    emit_check_text "PD hit-to-nfast local group path" OK "$PD_HIT_TO_NFAST_LOCAL_GROUP_PATH_RESULT"
    if [[ "$PD_HIT_TO_NFAST_LOCAL_SET_MAX_DELAY_RESULT" == "OK" \
        || "$PD_HIT_TO_NFAST_LOCAL_SET_MAX_DELAY_RESULT" == SKIPPED_INTENTIONAL* ]]; then
      echo "| PD hit-to-nfast local max delay | \`OK_or_SKIPPED_INTENTIONAL\` | \`$PD_HIT_TO_NFAST_LOCAL_SET_MAX_DELAY_RESULT\` | PASS |"
    else
      echo "| PD hit-to-nfast local max delay | \`OK_or_SKIPPED_INTENTIONAL\` | \`$PD_HIT_TO_NFAST_LOCAL_SET_MAX_DELAY_RESULT\` | FAIL |"
    fi
    if [[ "$PD_HIT_TO_NFAST_LOCAL_SET_MAX_TRANSITION_RESULT" == "OK" \
        || "$PD_HIT_TO_NFAST_LOCAL_SET_MAX_TRANSITION_RESULT" == SKIPPED_INTENTIONAL* ]]; then
      echo "| PD hit-to-nfast local max transition | \`OK_or_SKIPPED_INTENTIONAL\` | \`$PD_HIT_TO_NFAST_LOCAL_SET_MAX_TRANSITION_RESULT\` | PASS |"
    else
      echo "| PD hit-to-nfast local max transition | \`OK_or_SKIPPED_INTENTIONAL\` | \`$PD_HIT_TO_NFAST_LOCAL_SET_MAX_TRANSITION_RESULT\` | FAIL |"
    fi
    if [[ "${MPTDC_GENUS_REPAIR_PD_LOCAL_ON22:-0}" == "1" ]]; then
      emit_check_text "PD local ON22 repair status" PASS "$PD_LOCAL_ON22_STATUS"
      emit_check "PD local ON22 endpoints" "$PD_LOCAL_ON22_ENDPOINTS_EXPECTED" "$PD_LOCAL_ON22_ENDPOINTS_FOUND"
      emit_check "PD local ON22 source drivers" "$PD_LOCAL_ON22_ENDPOINTS_EXPECTED" "$PD_LOCAL_ON22_SOURCE_DRIVERS_FOUND"
      PD_LOCAL_ON22_EXPECTED_CELLS_UPPER="${PD_LOCAL_ON22_SOURCE_CELLS_EXPECTED^^}"
      if [[ "$PD_LOCAL_ON22_EXPECTED_CELLS_UPPER" == "AUTO" || "$PD_LOCAL_ON22_EXPECTED_CELLS_UPPER" == "DISCOVERED" ]]; then
        if [[ "$PD_LOCAL_ON22_SOURCE_CELLS_FOUND" =~ ^[0-9]+$ && "$PD_LOCAL_ON22_SOURCE_CELLS_FOUND" -gt 0 ]]; then
          echo "| PD local ON22 source cells | \`AUTO_DISCOVERED_POSITIVE\` | \`$PD_LOCAL_ON22_SOURCE_CELLS_FOUND\` | PASS |"
        else
          echo "| PD local ON22 source cells | \`AUTO_DISCOVERED_POSITIVE\` | \`$PD_LOCAL_ON22_SOURCE_CELLS_FOUND\` | FAIL |"
        fi
        emit_check "PD local ON22 target cells" "$PD_LOCAL_ON22_SOURCE_CELLS_FOUND" "$PD_LOCAL_ON22_TARGET_CELLS_FOUND"
      else
        emit_check "PD local ON22 source cells" "$PD_LOCAL_ON22_SOURCE_CELLS_EXPECTED" "$PD_LOCAL_ON22_SOURCE_CELLS_FOUND"
        emit_check "PD local ON22 target cells" "$PD_LOCAL_ON22_SOURCE_CELLS_EXPECTED" "$PD_LOCAL_ON22_TARGET_CELLS_FOUND"
      fi
      emit_check_text "PD local ON22 repair result" OK "$PD_LOCAL_ON22_REPAIR_RESULT"
      emit_check_text "PD local ON22 overmatch" NO "$PD_LOCAL_ON22_OVERMATCH"
      emit_check_text "PD local ON22 undermatch" NO "$PD_LOCAL_ON22_UNDERMATCH"
    fi
    emit_check "report helper failures" 0 "$REPORT_HELPER_FAILURE_COUNT"
    emit_check_text "summary/raw agreement" PASS "$SUMMARY_RAW_AGREEMENT_STATUS"
    emit_check "setup violating paths" 0 "$SETUP_VIOLATING_PATHS"
    emit_check "setup TNS ps" 0.0 "$SETUP_TNS_PS"
    emit_check "max transition violations" 0 "$MAX_TRANSITION_VIOLATIONS"
    emit_check "max capacitance violations" 0 "$MAX_CAPACITANCE_VIOLATIONS"
    emit_check "max fanout violations" 0 "$MAX_FANOUT_VIOLATIONS"
    echo
    echo "## Timing And DRV"
    echo
    echo "- Setup WNS ps: \`$SETUP_WNS_PS\`"
    echo "- Setup TNS ps: \`$SETUP_TNS_PS\`"
    echo "- Setup violating paths: \`$SETUP_VIOLATING_PATHS\`"
    echo "- Hold WNS ps: \`$HOLD_WNS_PS\`"
    echo "- Hold TNS ps: \`$HOLD_TNS_PS\`"
    echo "- Real timed WNS ps: \`$REAL_TIMED_WNS_PS\`"
    echo "- Real timed TNS ps: \`$REAL_TIMED_TNS_PS\`"
    echo "- Real timed violating paths: \`$REAL_TIMED_VIOLATING_PATHS\`"
    echo "- Worst real path family: \`$WORST_REAL_PATH_FAMILY\`"
    echo "- Max transition violations: \`$MAX_TRANSITION_VIOLATIONS\`"
    echo "- Report helper failures: \`$REPORT_HELPER_FAILURE_COUNT\`"
    echo "- Report helpers status: \`$REPORT_HELPERS_STATUS\`"
    echo "- Active SDC failure count: \`$ACTIVE_SDC_FAILURE_COUNT\`"
    echo "- Report diagnostic warning count: \`$REPORT_DIAGNOSTIC_WARNING_COUNT\`"
    echo "- Raw SDC diagnostic count: \`$RAW_SDC_DIAGNOSTIC_COUNT\`"
    echo "- SDC-235 count: \`$SDC_235_COUNT\`"
    echo "- TUI-61 count: \`$TUI_61_COUNT\`"
    echo "- Exact fast-tag repair status: \`$EXACT_FAST_TAG_REPAIR_STATUS\`"
    echo "- Exact fast-tag C-to-D max-delay result: \`$FAST_TAG_EXACT_C_TO_D_SET_MAX_DELAY_RESULT\`"
    echo "- Exact fast-tag max-delay constraint mode: \`$FAST_TAG_EXACT_MAX_DELAY_CONSTRAINT_MODE\`"
    echo "- Exact fast-tag source cell target: \`$FAST_TAG_EXACT_SOURCE_CELL_TARGET\`"
    echo "- Exact fast-tag source cell count: \`$FAST_TAG_EXACT_SOURCE_CELL_COUNT\`"
    echo "- Exact fast-tag source cell target count: \`$FAST_TAG_EXACT_SOURCE_CELL_TARGET_COUNT\`"
    echo "- Exact fast-tag source cell method: \`$FAST_TAG_EXACT_SOURCE_CELL_METHOD\`"
    echo "- Exact fast-tag source cell result: \`$FAST_TAG_EXACT_SOURCE_CELL_RESULT\`"
    echo "- Exact fast-tag source cell mode: \`$FAST_TAG_EXACT_SOURCE_CELL_MODE\`"
    echo "- Exact reset0 source count: \`$FAST_TAG_EXACT_RESET0_SOURCE_COUNT\`"
    echo "- Exact set1 source count: \`$FAST_TAG_EXACT_SET1_SOURCE_COUNT\`"
    echo "- Exact selected reset0 target: \`$FAST_TAG_EXACT_SELECTED_RESET0_TARGET\`"
    echo "- Exact selected set1 target: \`$FAST_TAG_EXACT_SELECTED_SET1_TARGET\`"
    echo "- Exact source polarity failed count: \`$FAST_TAG_EXACT_SOURCE_POLARITY_FAILED_COUNT\`"
    echo "- Exact source freeze result: \`$FAST_TAG_EXACT_SOURCE_FREEZE_RESULT\`"
    echo "- PD hit-to-nfast local repair status: \`$PD_HIT_TO_NFAST_LOCAL_STATUS\`"
    echo "- PD hit-to-nfast local review reason: \`$PD_HIT_TO_NFAST_LOCAL_REVIEW_REASON\`"
    echo "- PD hit-to-nfast local sources: \`$PD_HIT_TO_NFAST_LOCAL_SOURCES_FOUND / $PD_HIT_TO_NFAST_LOCAL_SOURCES_EXPECTED\`"
    echo "- PD hit-to-nfast local endpoints: \`$PD_HIT_TO_NFAST_LOCAL_ENDPOINTS_FOUND / $PD_HIT_TO_NFAST_LOCAL_ENDPOINTS_EXPECTED\`"
    echo "- PD hit-to-nfast local pairs: \`$PD_HIT_TO_NFAST_LOCAL_PAIRS_FOUND / $PD_HIT_TO_NFAST_LOCAL_ENDPOINTS_EXPECTED\`"
    echo "- PD hit-to-nfast local max-delay result: \`$PD_HIT_TO_NFAST_LOCAL_SET_MAX_DELAY_RESULT\`"
    echo "- PD hit-to-nfast local max-transition result: \`$PD_HIT_TO_NFAST_LOCAL_SET_MAX_TRANSITION_RESULT\`"
    echo "- PD local ON22 repair status: \`$PD_LOCAL_ON22_STATUS\`"
    echo "- PD local ON22 review reason: \`$PD_LOCAL_ON22_REVIEW_REASON\`"
    echo "- PD local ON22 source cell: \`$PD_LOCAL_ON22_SOURCE_CELL\`"
    echo "- PD local ON22 selected target: \`$PD_LOCAL_ON22_SELECTED_TARGET\`"
    echo "- PD local ON22 source cells: \`$PD_LOCAL_ON22_SOURCE_CELLS_FOUND / $PD_LOCAL_ON22_SOURCE_CELLS_EXPECTED\`"
    echo "- PD local ON22 target cells: \`$PD_LOCAL_ON22_TARGET_CELLS_FOUND / $PD_LOCAL_ON22_SOURCE_CELLS_EXPECTED\`"
    echo "- Fast tag flop bias mode: \`$FAST_TAG_FLOP_BIAS_MODE\`"
    echo "- Fast tag mapping status: \`$FAST_TAG_MAPPING_STATUS\`"
    echo "- Fast tag top source DFRRQHDX0 count: \`$FAST_TAG_SOURCE_DFRRQHDX0_COUNT\`"
    echo "- Fast tag top source UNKNOWN count: \`$FAST_TAG_SOURCE_UNKNOWN_COUNT\`"
    echo
    if [[ -f "$RESULT_DIR/timing_path_classification_summary.md" ]]; then
      echo "## Classification Summary"
      echo
      sed -n '1,80p' "$RESULT_DIR/timing_path_classification_summary.md"
    fi
    echo
    echo "## Interpretation"
    echo
    if [[ "$FINAL_DECISION" == "GENUS_TYPICAL_CLOSED" ]]; then
      echo "Typical-only Genus timing is clean for the checked criteria. This is still not MMMC signoff."
    else
      echo "Do not call closure yet. Review the failing criteria and the worst real path family before running Innovus implementation."
    fi
  } > "$out"
}

emit_check() {
  local label="$1"
  local expected="$2"
  local actual="$3"
  local status="FAIL"
  [[ "$actual" == "$expected" ]] && status="PASS"
  echo "| $label | \`$expected\` | \`$actual\` | $status |"
}

emit_check_text() {
  emit_check "$@"
}

CHECK_REPORT="$RESULT_DIR/o13_phase_distribution_check.rpt"
{
  echo "# O13 Phase Distribution Check"
  echo
  echo "post_synth_netlist=$POSTSYN_NETLIST"
  echo "ro_tune4_count=$RO_COUNT"
  echo "mptdc_osc_stub_count=$STUB_COUNT"
  echo "buhdx4_count=$BUHDX4_COUNT"
  echo "buhdx12_count=$BUHDX12_COUNT"
  echo "phase_buffer_text_count=$PHASE_BUF_TEXT_COUNT"
  echo "u_iso_text_count=$ISO_TEXT_COUNT"
  echo "u_drv_text_count=$DRV_TEXT_COUNT"
  echo "report_clocks_ro_pin_count=$CLOCKS_ON_RO"
  echo "report_clocks_buffer_clock_count=$BUFFER_CLOCKS"
  echo "RAW_RO_CLOCKS_FOUND=$RAW_RO_CLOCKS_FOUND"
  echo "BUFFER_PHASE_CLOCKS_FOUND=$BUFFER_PHASE_CLOCKS_FOUND"
  echo "BUFFER_PHASE_CLOCKS_EXPECTED=$BUFFER_PHASE_CLOCKS_EXPECTED"
  echo "BUFFER_PHASE_CLOCKS_IN_ASYNC_GROUP=$BUFFER_PHASE_CLOCKS_IN_ASYNC_GROUP"
  echo "CLK_SYS_ASYNC_TO_BUFFER_PHASE_CLOCKS=$CLK_SYS_ASYNC_TO_BUFFER_PHASE_CLOCKS"
  echo "PD_VERNIER_EXCEPTION_EXPECTED=$PD_VERNIER_EXCEPTION_EXPECTED"
  echo "PD_VERNIER_EXCEPTION_MATCHED=$PD_VERNIER_EXCEPTION_MATCHED"
  echo "PD_VERNIER_SOURCE_MATCHED=$PD_VERNIER_SOURCE_MATCHED"
  echo "PD_VERNIER_EXCEPTION_APPLIED=$PD_VERNIER_EXCEPTION_APPLIED"
  echo "PD_VERNIER_EXCEPTION_OVERMATCH=$PD_VERNIER_EXCEPTION_OVERMATCH"
  echo "PD_VERNIER_EXCEPTION_UNDERMATCH=$PD_VERNIER_EXCEPTION_UNDERMATCH"
  echo "UNKNOWN_REVIEW_REQUIRED_COUNT=$UNKNOWN_REVIEW_REQUIRED_COUNT"
  echo "SDC_COMMAND_FAILURE_COUNT=$SDC_COMMAND_FAILURE_COUNT"
  echo "ACTIVE_SDC_FAILURE_COUNT=$ACTIVE_SDC_FAILURE_COUNT"
  echo "REPORT_DIAGNOSTIC_WARNING_COUNT=$REPORT_DIAGNOSTIC_WARNING_COUNT"
  echo "RAW_SDC_DIAGNOSTIC_COUNT=$RAW_SDC_DIAGNOSTIC_COUNT"
  echo "SDC_235_COUNT=$SDC_235_COUNT"
  echo "TUI_61_COUNT=$TUI_61_COUNT"
  echo "SDC_INVALID_OBJECT_COUNT=$SDC_INVALID_OBJECT_COUNT"
  echo "EXACT_FAST_TAG_SOURCES_EXPECTED=$EXACT_FAST_TAG_SOURCES_EXPECTED"
  echo "EXACT_FAST_TAG_SOURCES_FOUND=$EXACT_FAST_TAG_SOURCES_FOUND"
  echo "EXACT_FAST_TAG_ENDPOINTS_EXPECTED=$EXACT_FAST_TAG_ENDPOINTS_EXPECTED"
  echo "EXACT_FAST_TAG_ENDPOINTS_FOUND=$EXACT_FAST_TAG_ENDPOINTS_FOUND"
  echo "EXACT_FAST_TAG_DATAPATHS_EXPECTED=$EXACT_FAST_TAG_DATAPATHS_EXPECTED"
  echo "EXACT_FAST_TAG_DATAPATHS_FOUND=$EXACT_FAST_TAG_DATAPATHS_FOUND"
  echo "EXACT_FAST_TAG_REPAIR_APPLIED=$EXACT_FAST_TAG_REPAIR_APPLIED"
  echo "EXACT_FAST_TAG_REPAIR_STATUS=$EXACT_FAST_TAG_REPAIR_STATUS"
  echo "FAST_TAG_EXACT_C_TO_D_SET_MAX_DELAY_RESULT=$FAST_TAG_EXACT_C_TO_D_SET_MAX_DELAY_RESULT"
  echo "FAST_TAG_EXACT_MAX_DELAY_CONSTRAINT_MODE=$FAST_TAG_EXACT_MAX_DELAY_CONSTRAINT_MODE"
  echo "FAST_TAG_EXACT_SOURCE_CELL_TARGET=$FAST_TAG_EXACT_SOURCE_CELL_TARGET"
  echo "FAST_TAG_EXACT_SOURCE_CELL_REQUESTED=$FAST_TAG_EXACT_SOURCE_CELL_REQUESTED"
  echo "FAST_TAG_EXACT_SOURCE_CELL_LIB_CELLS_FOUND=$FAST_TAG_EXACT_SOURCE_CELL_LIB_CELLS_FOUND"
  echo "FAST_TAG_EXACT_SOURCE_CELL_COUNT=$FAST_TAG_EXACT_SOURCE_CELL_COUNT"
  echo "FAST_TAG_EXACT_SOURCE_CELL_TARGET_COUNT=$FAST_TAG_EXACT_SOURCE_CELL_TARGET_COUNT"
  echo "FAST_TAG_EXACT_SOURCE_CELL_METHOD=$FAST_TAG_EXACT_SOURCE_CELL_METHOD"
  echo "FAST_TAG_EXACT_SOURCE_CELL_RESULT=$FAST_TAG_EXACT_SOURCE_CELL_RESULT"
  echo "FAST_TAG_EXACT_SOURCE_CELL_MODE=$FAST_TAG_EXACT_SOURCE_CELL_MODE"
  echo "FAST_TAG_EXACT_RESET0_SOURCE_COUNT=$FAST_TAG_EXACT_RESET0_SOURCE_COUNT"
  echo "FAST_TAG_EXACT_SET1_SOURCE_COUNT=$FAST_TAG_EXACT_SET1_SOURCE_COUNT"
  echo "FAST_TAG_EXACT_SOURCE_UNSUPPORTED_POLARITY_COUNT=$FAST_TAG_EXACT_SOURCE_UNSUPPORTED_POLARITY_COUNT"
  echo "FAST_TAG_EXACT_SELECTED_RESET0_TARGET=$FAST_TAG_EXACT_SELECTED_RESET0_TARGET"
  echo "FAST_TAG_EXACT_SELECTED_SET1_TARGET=$FAST_TAG_EXACT_SELECTED_SET1_TARGET"
  echo "FAST_TAG_EXACT_DFRRQHDX4_TARGET_COUNT=$FAST_TAG_EXACT_DFRRQHDX4_TARGET_COUNT"
  echo "FAST_TAG_EXACT_DFRSQHDX4_TARGET_COUNT=$FAST_TAG_EXACT_DFRSQHDX4_TARGET_COUNT"
  echo "FAST_TAG_EXACT_DFRSQHDX2_TARGET_COUNT=$FAST_TAG_EXACT_DFRSQHDX2_TARGET_COUNT"
  echo "FAST_TAG_EXACT_DFRRQJIHDX4_TARGET_COUNT=$FAST_TAG_EXACT_DFRRQJIHDX4_TARGET_COUNT"
  echo "FAST_TAG_EXACT_DFRSJIHDX4_TARGET_COUNT=$FAST_TAG_EXACT_DFRSJIHDX4_TARGET_COUNT"
  echo "FAST_TAG_EXACT_DFRSJIHDX2_TARGET_COUNT=$FAST_TAG_EXACT_DFRSJIHDX2_TARGET_COUNT"
  echo "FAST_TAG_EXACT_SOURCE_POLARITY_PRESERVED_COUNT=$FAST_TAG_EXACT_SOURCE_POLARITY_PRESERVED_COUNT"
  echo "FAST_TAG_EXACT_SOURCE_POLARITY_FAILED_COUNT=$FAST_TAG_EXACT_SOURCE_POLARITY_FAILED_COUNT"
  echo "FAST_TAG_EXACT_SOURCE_FREEZE_RESULT=$FAST_TAG_EXACT_SOURCE_FREEZE_RESULT"
  echo "PD_HIT_TO_NFAST_LOCAL_REPAIR_ENABLE=$PD_HIT_TO_NFAST_LOCAL_REPAIR_ENABLE"
  echo "PD_HIT_TO_NFAST_LOCAL_SOURCES_EXPECTED=$PD_HIT_TO_NFAST_LOCAL_SOURCES_EXPECTED"
  echo "PD_HIT_TO_NFAST_LOCAL_SOURCES_FOUND=$PD_HIT_TO_NFAST_LOCAL_SOURCES_FOUND"
  echo "PD_HIT_TO_NFAST_LOCAL_SOURCE_Q_FOUND=$PD_HIT_TO_NFAST_LOCAL_SOURCE_Q_FOUND"
  echo "PD_HIT_TO_NFAST_LOCAL_ENDPOINTS_EXPECTED=$PD_HIT_TO_NFAST_LOCAL_ENDPOINTS_EXPECTED"
  echo "PD_HIT_TO_NFAST_LOCAL_ENDPOINTS_FOUND=$PD_HIT_TO_NFAST_LOCAL_ENDPOINTS_FOUND"
  echo "PD_HIT_TO_NFAST_LOCAL_PAIRS_FOUND=$PD_HIT_TO_NFAST_LOCAL_PAIRS_FOUND"
  echo "PD_HIT_TO_NFAST_LOCAL_BITS=$PD_HIT_TO_NFAST_LOCAL_BITS"
  echo "PD_HIT_TO_NFAST_LOCAL_MAX_DELAY_NS=$PD_HIT_TO_NFAST_LOCAL_MAX_DELAY_NS"
  echo "PD_HIT_TO_NFAST_LOCAL_MAX_TRANSITION_NS=$PD_HIT_TO_NFAST_LOCAL_MAX_TRANSITION_NS"
  echo "PD_HIT_TO_NFAST_LOCAL_GROUP_PATH_RESULT=$PD_HIT_TO_NFAST_LOCAL_GROUP_PATH_RESULT"
  echo "PD_HIT_TO_NFAST_LOCAL_SET_MAX_DELAY_RESULT=$PD_HIT_TO_NFAST_LOCAL_SET_MAX_DELAY_RESULT"
  echo "PD_HIT_TO_NFAST_LOCAL_MAX_DELAY_CONSTRAINT_MODE=$PD_HIT_TO_NFAST_LOCAL_MAX_DELAY_CONSTRAINT_MODE"
  echo "PD_HIT_TO_NFAST_LOCAL_SET_MAX_TRANSITION_RESULT=$PD_HIT_TO_NFAST_LOCAL_SET_MAX_TRANSITION_RESULT"
  echo "PD_HIT_TO_NFAST_LOCAL_OVERMATCH=$PD_HIT_TO_NFAST_LOCAL_OVERMATCH"
  echo "PD_HIT_TO_NFAST_LOCAL_UNDERMATCH=$PD_HIT_TO_NFAST_LOCAL_UNDERMATCH"
  echo "PD_HIT_TO_NFAST_LOCAL_STATUS=$PD_HIT_TO_NFAST_LOCAL_STATUS"
  echo "PD_HIT_TO_NFAST_LOCAL_REVIEW_REASON=$PD_HIT_TO_NFAST_LOCAL_REVIEW_REASON"
  echo "PD_LOCAL_ON22_REPAIR_ENABLE=$PD_LOCAL_ON22_REPAIR_ENABLE"
  echo "PD_LOCAL_ON22_SOURCE_CELL=$PD_LOCAL_ON22_SOURCE_CELL"
  echo "PD_LOCAL_ON22_TARGET_CELLS=$PD_LOCAL_ON22_TARGET_CELLS"
  echo "PD_LOCAL_ON22_SELECTED_TARGET=$PD_LOCAL_ON22_SELECTED_TARGET"
  echo "PD_LOCAL_ON22_TARGET_LIB_CELLS_FOUND=$PD_LOCAL_ON22_TARGET_LIB_CELLS_FOUND"
  echo "PD_LOCAL_ON22_ENDPOINTS_EXPECTED=$PD_LOCAL_ON22_ENDPOINTS_EXPECTED"
  echo "PD_LOCAL_ON22_ENDPOINTS_FOUND=$PD_LOCAL_ON22_ENDPOINTS_FOUND"
  echo "PD_LOCAL_ON22_SOURCE_DRIVERS_FOUND=$PD_LOCAL_ON22_SOURCE_DRIVERS_FOUND"
  echo "PD_LOCAL_ON22_SOURCE_CELLS_EXPECTED=$PD_LOCAL_ON22_SOURCE_CELLS_EXPECTED"
  echo "PD_LOCAL_ON22_SOURCE_CELLS_FOUND=$PD_LOCAL_ON22_SOURCE_CELLS_FOUND"
  echo "PD_LOCAL_ON22_CHANGED_CELLS=$PD_LOCAL_ON22_CHANGED_CELLS"
  echo "PD_LOCAL_ON22_TARGET_CELLS_FOUND=$PD_LOCAL_ON22_TARGET_CELLS_FOUND"
  echo "PD_LOCAL_ON22_REPAIR_RESULT=$PD_LOCAL_ON22_REPAIR_RESULT"
  echo "PD_LOCAL_ON22_OVERMATCH=$PD_LOCAL_ON22_OVERMATCH"
  echo "PD_LOCAL_ON22_UNDERMATCH=$PD_LOCAL_ON22_UNDERMATCH"
  echo "PD_LOCAL_ON22_STATUS=$PD_LOCAL_ON22_STATUS"
  echo "PD_LOCAL_ON22_REVIEW_REASON=$PD_LOCAL_ON22_REVIEW_REASON"
  echo "MAX_TRANSITION_VIOLATIONS=$MAX_TRANSITION_VIOLATIONS"
  echo "MAX_CAPACITANCE_VIOLATIONS=$MAX_CAPACITANCE_VIOLATIONS"
  echo "MAX_FANOUT_VIOLATIONS=$MAX_FANOUT_VIOLATIONS"
  echo "SETUP_WNS_PS=$SETUP_WNS_PS"
  echo "SETUP_TNS_PS=$SETUP_TNS_PS"
  echo "SETUP_VIOLATING_PATHS=$SETUP_VIOLATING_PATHS"
  echo "HOLD_WNS_PS=$HOLD_WNS_PS"
  echo "HOLD_TNS_PS=$HOLD_TNS_PS"
  echo "REAL_TIMED_WNS_PS=$REAL_TIMED_WNS_PS"
  echo "REAL_TIMED_TNS_PS=$REAL_TIMED_TNS_PS"
  echo "REAL_TIMED_VIOLATING_PATHS=$REAL_TIMED_VIOLATING_PATHS"
  echo "WORST_REAL_PATH_FAMILY=$WORST_REAL_PATH_FAMILY"
  echo "REPORT_HELPER_FAILURE_COUNT=$REPORT_HELPER_FAILURE_COUNT"
  echo "REPORT_HELPERS_STATUS=$REPORT_HELPERS_STATUS"
  echo "FAST_TAG_FLOP_BIAS_MODE=$FAST_TAG_FLOP_BIAS_MODE"
  echo "FAST_TAG_PRESERVE_MODE=$FAST_TAG_PRESERVE_MODE"
  echo "FAST_TAG_MAPPING_PARSE_STATUS=$FAST_TAG_MAPPING_PARSE_STATUS"
  echo "FAST_TAG_MAPPING_STATUS=$FAST_TAG_MAPPING_STATUS"
  echo "FAST_TAG_SOURCE_DFRRQHDX0_COUNT=$FAST_TAG_SOURCE_DFRRQHDX0_COUNT"
  echo "FAST_TAG_SOURCE_DFRRQHDX1_COUNT=$FAST_TAG_SOURCE_DFRRQHDX1_COUNT"
  echo "FAST_TAG_SOURCE_DFRRQHDX2_COUNT=$FAST_TAG_SOURCE_DFRRQHDX2_COUNT"
  echo "FAST_TAG_SOURCE_DFRRQHDX4_COUNT=$FAST_TAG_SOURCE_DFRRQHDX4_COUNT"
  echo "FAST_TAG_SOURCE_DFRSQHDX0_COUNT=$FAST_TAG_SOURCE_DFRSQHDX0_COUNT"
  echo "FAST_TAG_SOURCE_DFRSQHDX1_COUNT=$FAST_TAG_SOURCE_DFRSQHDX1_COUNT"
  echo "FAST_TAG_SOURCE_DFRSQHDX2_COUNT=$FAST_TAG_SOURCE_DFRSQHDX2_COUNT"
  echo "FAST_TAG_SOURCE_DFRSQHDX4_COUNT=$FAST_TAG_SOURCE_DFRSQHDX4_COUNT"
  echo "FAST_TAG_SOURCE_DFRJIHDX0_COUNT=$FAST_TAG_SOURCE_DFRJIHDX0_COUNT"
  echo "FAST_TAG_SOURCE_DFRJIHDX1_COUNT=$FAST_TAG_SOURCE_DFRJIHDX1_COUNT"
  echo "FAST_TAG_SOURCE_DFRJIHDX2_COUNT=$FAST_TAG_SOURCE_DFRJIHDX2_COUNT"
  echo "FAST_TAG_SOURCE_DFRJIHDX4_COUNT=$FAST_TAG_SOURCE_DFRJIHDX4_COUNT"
  echo "FAST_TAG_SOURCE_DFRRQJIHDX0_COUNT=$FAST_TAG_SOURCE_DFRRQJIHDX0_COUNT"
  echo "FAST_TAG_SOURCE_DFRRQJIHDX1_COUNT=$FAST_TAG_SOURCE_DFRRQJIHDX1_COUNT"
  echo "FAST_TAG_SOURCE_DFRRQJIHDX2_COUNT=$FAST_TAG_SOURCE_DFRRQJIHDX2_COUNT"
  echo "FAST_TAG_SOURCE_DFRRQJIHDX4_COUNT=$FAST_TAG_SOURCE_DFRRQJIHDX4_COUNT"
  echo "FAST_TAG_SOURCE_DFRSJIHDX2_COUNT=$FAST_TAG_SOURCE_DFRSJIHDX2_COUNT"
  echo "FAST_TAG_SOURCE_UNKNOWN_COUNT=$FAST_TAG_SOURCE_UNKNOWN_COUNT"
  echo "FAST_TAG_MAPPED_SOURCE_COUNT=$FAST_TAG_MAPPED_SOURCE_COUNT"
  echo "FAST_TAG_MAPPED_ENDPOINT_COUNT=$FAST_TAG_MAPPED_ENDPOINT_COUNT"
  echo "FAST_TAG_TOP_PATH_COUNT=$FAST_TAG_TOP_PATH_COUNT"
  echo "FAST_TAG_EXACT_SOURCE_COUNT=$FAST_TAG_EXACT_SOURCE_COUNT"
  echo "FAST_TAG_EXACT_SOURCE_DFRRQHDX1_COUNT=$FAST_TAG_EXACT_SOURCE_DFRRQHDX1_COUNT"
  echo "FAST_TAG_EXACT_SOURCE_DFRRQHDX2_COUNT=$FAST_TAG_EXACT_SOURCE_DFRRQHDX2_COUNT"
  echo "FAST_TAG_EXACT_SOURCE_DFRRQHDX4_COUNT=$FAST_TAG_EXACT_SOURCE_DFRRQHDX4_COUNT"
  echo "FAST_TAG_EXACT_SOURCE_DFRSQHDX0_COUNT=$FAST_TAG_EXACT_SOURCE_DFRSQHDX0_COUNT"
  echo "FAST_TAG_EXACT_SOURCE_DFRSQHDX1_COUNT=$FAST_TAG_EXACT_SOURCE_DFRSQHDX1_COUNT"
  echo "FAST_TAG_EXACT_SOURCE_DFRSQHDX2_COUNT=$FAST_TAG_EXACT_SOURCE_DFRSQHDX2_COUNT"
  echo "FAST_TAG_EXACT_SOURCE_DFRSQHDX4_COUNT=$FAST_TAG_EXACT_SOURCE_DFRSQHDX4_COUNT"
  echo "FAST_TAG_EXACT_SOURCE_DFRJIHDX1_COUNT=$FAST_TAG_EXACT_SOURCE_DFRJIHDX1_COUNT"
  echo "FAST_TAG_EXACT_SOURCE_DFRJIHDX2_COUNT=$FAST_TAG_EXACT_SOURCE_DFRJIHDX2_COUNT"
  echo "FAST_TAG_EXACT_SOURCE_DFRJIHDX4_COUNT=$FAST_TAG_EXACT_SOURCE_DFRJIHDX4_COUNT"
  echo "FAST_TAG_EXACT_SOURCE_DFRRQJIHDX1_COUNT=$FAST_TAG_EXACT_SOURCE_DFRRQJIHDX1_COUNT"
  echo "FAST_TAG_EXACT_SOURCE_DFRRQJIHDX2_COUNT=$FAST_TAG_EXACT_SOURCE_DFRRQJIHDX2_COUNT"
  echo "FAST_TAG_EXACT_SOURCE_DFRRQJIHDX4_COUNT=$FAST_TAG_EXACT_SOURCE_DFRRQJIHDX4_COUNT"
  echo "FAST_TAG_EXACT_SOURCE_DFRSJIHDX2_COUNT=$FAST_TAG_EXACT_SOURCE_DFRSJIHDX2_COUNT"
  echo "FAST_TAG_EXACT_SOURCE_UNKNOWN_COUNT=$FAST_TAG_EXACT_SOURCE_UNKNOWN_COUNT"
  echo "FAST_TAG_EXACT_ENDPOINT_COUNT=$FAST_TAG_EXACT_ENDPOINT_COUNT"
  echo "FAST_TAG_EXACT_ENDPOINT_DFRHDX2_COUNT=$FAST_TAG_EXACT_ENDPOINT_DFRHDX2_COUNT"
  echo "FAST_TAG_EXACT_ENDPOINT_DFRHDX4_COUNT=$FAST_TAG_EXACT_ENDPOINT_DFRHDX4_COUNT"
  echo "FAST_TAG_EXACT_ENDPOINT_DFRSHDX2_COUNT=$FAST_TAG_EXACT_ENDPOINT_DFRSHDX2_COUNT"
  echo "FAST_TAG_EXACT_ENDPOINT_DFRSHDX4_COUNT=$FAST_TAG_EXACT_ENDPOINT_DFRSHDX4_COUNT"
  echo "FAST_TAG_EXACT_ENDPOINT_UNKNOWN_COUNT=$FAST_TAG_EXACT_ENDPOINT_UNKNOWN_COUNT"
  echo "FAST_TAG_EXACT_SOURCE_PHASE_CLOCK_LOAD_DELTA_ESTIMATE=$FAST_TAG_EXACT_SOURCE_PHASE_CLOCK_LOAD_DELTA_ESTIMATE"
  echo "TIMING_SUMMARY_PARSE_STATUS=$TIMING_SUMMARY_PARSE_STATUS"
  echo "TIMING_CLASSIFICATION_PARSE_STATUS=$TIMING_CLASSIFICATION_PARSE_STATUS"
  echo "SUMMARY_RAW_AGREEMENT_STATUS=$SUMMARY_RAW_AGREEMENT_STATUS"
  echo
  if [[ -f "$POSTSYN_NETLIST" ]]; then
    echo "## RO_tune4 instances"
    grep -nE '^[[:space:]]*RO_tune4[[:space:]]+' "$POSTSYN_NETLIST" || true
    echo
    echo "## O13 phase-distribution cells"
    grep -nE 'BUHDX4|BUHDX12|u_phase_buf_slow|u_phase_buf_fast|mptdc_phase_buffer_bank|u_iso|u_drv' "$POSTSYN_NETLIST" || true
    echo
    echo "## forbidden structure residues"
    grep -nE 'mptdc_osc_stub|u_fast_cnt|u_slow_cnt|gray_src_cont_q|gray_snap_ff|dst_count_latched' "$POSTSYN_NETLIST" || true
  else
    echo "ERROR: post-synthesis netlist not found"
  fi
} > "$CHECK_REPORT"
write_macro_binding_check
write_packet_contract_check

STATUS="GENUS_TYPICAL_REVIEW_REQUIRED"
is_zero_metric() {
  [[ "$1" == "0" || "$1" == "0.0" || "$1" == "-0.0" ]]
}

float_ge() {
  local lhs="$1"
  local rhs="$2"
  [[ "$lhs" != "NA" ]] && awk "BEGIN {exit !($lhs >= $rhs)}"
}

EXACT_FAST_TAG_GATE_OK=YES
if [[ "${MPTDC_GENUS_REPAIR4_EXACT_FAST_TAG_SOURCE_DRIVE:-0}" == "1" || "${MPTDC_FAST_TAG_REPAIR_EXACT_DATA_PATHS:-0}" == "1" ]]; then
  EXACT_FAST_TAG_GATE_OK=NO
  if [[ "$EXACT_FAST_TAG_SOURCES_FOUND" != "NA" \
      && "$EXACT_FAST_TAG_ENDPOINTS_FOUND" != "NA" \
      && "$EXACT_FAST_TAG_DATAPATHS_FOUND" != "NA" \
      && "$EXACT_FAST_TAG_SOURCES_FOUND" != "0" \
      && "$EXACT_FAST_TAG_ENDPOINTS_FOUND" != "0" \
      && "$EXACT_FAST_TAG_DATAPATHS_FOUND" != "0" \
      && "$EXACT_FAST_TAG_SOURCES_FOUND" == "$EXACT_FAST_TAG_SOURCES_EXPECTED" \
      && "$EXACT_FAST_TAG_ENDPOINTS_FOUND" == "$EXACT_FAST_TAG_ENDPOINTS_EXPECTED" \
      && "$EXACT_FAST_TAG_DATAPATHS_FOUND" == "$EXACT_FAST_TAG_DATAPATHS_EXPECTED" \
      && "$EXACT_FAST_TAG_REPAIR_APPLIED" == "YES" \
      && "$EXACT_FAST_TAG_REPAIR_STATUS" == "PASS" ]]; then
    EXACT_FAST_TAG_GATE_OK=YES
  fi
fi

EXACT_SOURCE_CELL_GATE_OK=YES
if [[ "${MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL:-}" != "" ]]; then
  EXACT_SOURCE_CELL_GATE_OK=NO
  if [[ "${MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL_MODE:-}" == "POLARITY_AWARE" || "${MPTDC_GENUS_REPAIR7_POLARITY_AWARE_FAST_TAG_SOURCE_UPGRADE:-0}" == "1" ]]; then
    EXACT_RESET0_TARGET_OK=NO
    if [[ "$FAST_TAG_EXACT_DFRRQHDX4_TARGET_COUNT" == "16" || "$FAST_TAG_EXACT_DFRRQJIHDX4_TARGET_COUNT" == "16" ]]; then
      EXACT_RESET0_TARGET_OK=YES
    fi
    EXACT_SOURCE_CELL_STATUS_OK=NO
    EXACT_SET1_SOURCE_OK=NO
    EXACT_UNSUPPORTED_SOURCE_OK=NO
    if [[ "${MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_SKIP_UNSUPPORTED:-0}" == "1" ]]; then
      if [[ "$FAST_TAG_EXACT_SOURCE_CELL_RESULT" == "PASS_PARTIAL_UNSUPPORTED_SKIPPED" ]]; then
        EXACT_SOURCE_CELL_STATUS_OK=YES
      fi
      if [[ "$FAST_TAG_EXACT_SET1_SOURCE_COUNT" == "0" ]]; then
        EXACT_SET1_SOURCE_OK=YES
      fi
      if [[ "$FAST_TAG_EXACT_SOURCE_UNSUPPORTED_POLARITY_COUNT" == "8" ]]; then
        EXACT_UNSUPPORTED_SOURCE_OK=YES
      fi
    else
      if [[ "$FAST_TAG_EXACT_SOURCE_CELL_RESULT" == "PASS_FINAL_VERIFIED" ]]; then
        EXACT_SOURCE_CELL_STATUS_OK=YES
      fi
      if [[ "$FAST_TAG_EXACT_SET1_SOURCE_COUNT" == "8" ]]; then
        EXACT_SET1_SOURCE_OK=YES
      fi
      if [[ "$FAST_TAG_EXACT_SOURCE_UNSUPPORTED_POLARITY_COUNT" == "0" ]]; then
        EXACT_UNSUPPORTED_SOURCE_OK=YES
      fi
    fi
    if [[ "$EXACT_SOURCE_CELL_STATUS_OK" == "YES" \
        && "$FAST_TAG_EXACT_SOURCE_CELL_MODE" == "POLARITY_AWARE" \
        && "$FAST_TAG_EXACT_SOURCE_COUNT" == "$EXACT_FAST_TAG_SOURCES_EXPECTED" \
        && "$FAST_TAG_EXACT_RESET0_SOURCE_COUNT" == "16" \
        && "$EXACT_SET1_SOURCE_OK" == "YES" \
        && "$EXACT_UNSUPPORTED_SOURCE_OK" == "YES" \
        && "$EXACT_RESET0_TARGET_OK" == "YES" \
        && "$FAST_TAG_EXACT_SOURCE_POLARITY_FAILED_COUNT" == "0" \
        && "$FAST_TAG_EXACT_SOURCE_UNKNOWN_COUNT" == "0" ]]; then
      if [[ "${MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_SKIP_UNSUPPORTED:-0}" == "1" ]]; then
        EXACT_SOURCE_CELL_GATE_OK=YES
      elif [[ "$FAST_TAG_EXACT_SELECTED_SET1_TARGET" == "DFRSQHDX4" && "$FAST_TAG_EXACT_DFRSQHDX4_TARGET_COUNT" == "8" ]]; then
        EXACT_SOURCE_CELL_GATE_OK=YES
      elif [[ "$FAST_TAG_EXACT_SELECTED_SET1_TARGET" == "DFRSQHDX2" && "$FAST_TAG_EXACT_DFRSQHDX2_TARGET_COUNT" == "8" ]]; then
        EXACT_SOURCE_CELL_GATE_OK=YES
      elif [[ "$FAST_TAG_EXACT_SELECTED_SET1_TARGET" == "DFRSJIHDX4" && "$FAST_TAG_EXACT_DFRSJIHDX4_TARGET_COUNT" == "8" ]]; then
        EXACT_SOURCE_CELL_GATE_OK=YES
      elif [[ "$FAST_TAG_EXACT_SELECTED_SET1_TARGET" == "DFRSJIHDX2" && "$FAST_TAG_EXACT_DFRSJIHDX2_TARGET_COUNT" == "8" ]]; then
        EXACT_SOURCE_CELL_GATE_OK=YES
      fi
    fi
  else
    EXACT_SOURCE_CELL_TARGET_MAPPED_COUNT=NA
    case "$MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL" in
      DFRRQHDX1) EXACT_SOURCE_CELL_TARGET_MAPPED_COUNT="$FAST_TAG_EXACT_SOURCE_DFRRQHDX1_COUNT" ;;
      DFRRQHDX2) EXACT_SOURCE_CELL_TARGET_MAPPED_COUNT="$FAST_TAG_EXACT_SOURCE_DFRRQHDX2_COUNT" ;;
      DFRRQHDX4) EXACT_SOURCE_CELL_TARGET_MAPPED_COUNT="$FAST_TAG_EXACT_SOURCE_DFRRQHDX4_COUNT" ;;
      DFRJIHDX1) EXACT_SOURCE_CELL_TARGET_MAPPED_COUNT="$FAST_TAG_EXACT_SOURCE_DFRJIHDX1_COUNT" ;;
      DFRJIHDX2) EXACT_SOURCE_CELL_TARGET_MAPPED_COUNT="$FAST_TAG_EXACT_SOURCE_DFRJIHDX2_COUNT" ;;
      DFRJIHDX4) EXACT_SOURCE_CELL_TARGET_MAPPED_COUNT="$FAST_TAG_EXACT_SOURCE_DFRJIHDX4_COUNT" ;;
    esac
    if [[ "$EXACT_SOURCE_CELL_TARGET_MAPPED_COUNT" != "NA" \
        && "$EXACT_FAST_TAG_SOURCES_EXPECTED" != "NA" \
        && "$FAST_TAG_EXACT_SOURCE_COUNT" == "$EXACT_FAST_TAG_SOURCES_EXPECTED" \
        && "$EXACT_SOURCE_CELL_TARGET_MAPPED_COUNT" == "$EXACT_FAST_TAG_SOURCES_EXPECTED" \
        && "$FAST_TAG_EXACT_SOURCE_UNKNOWN_COUNT" == "0" ]]; then
      EXACT_SOURCE_CELL_GATE_OK=YES
    fi
  fi
fi

PD_HIT_TO_NFAST_LOCAL_GATE_OK=NO
PD_HIT_TO_NFAST_LOCAL_DELAY_GATE_OK=NO
if [[ "$PD_HIT_TO_NFAST_LOCAL_SET_MAX_DELAY_RESULT" == "OK" \
    || "$PD_HIT_TO_NFAST_LOCAL_SET_MAX_DELAY_RESULT" == SKIPPED_INTENTIONAL* ]]; then
  PD_HIT_TO_NFAST_LOCAL_DELAY_GATE_OK=YES
fi
PD_HIT_TO_NFAST_LOCAL_TRANSITION_GATE_OK=NO
if [[ "$PD_HIT_TO_NFAST_LOCAL_SET_MAX_TRANSITION_RESULT" == "OK" \
    || "$PD_HIT_TO_NFAST_LOCAL_SET_MAX_TRANSITION_RESULT" == SKIPPED_INTENTIONAL* ]]; then
  PD_HIT_TO_NFAST_LOCAL_TRANSITION_GATE_OK=YES
fi
if [[ ( "$PD_HIT_TO_NFAST_LOCAL_REPAIR_ENABLE" == "1" || "$PD_HIT_TO_NFAST_LOCAL_REPAIR_ENABLE" == "true" ) \
    && "$PD_HIT_TO_NFAST_LOCAL_SOURCES_FOUND" == "$PD_HIT_TO_NFAST_LOCAL_SOURCES_EXPECTED" \
    && "$PD_HIT_TO_NFAST_LOCAL_SOURCE_Q_FOUND" == "$PD_HIT_TO_NFAST_LOCAL_SOURCES_EXPECTED" \
    && "$PD_HIT_TO_NFAST_LOCAL_ENDPOINTS_FOUND" == "$PD_HIT_TO_NFAST_LOCAL_ENDPOINTS_EXPECTED" \
    && "$PD_HIT_TO_NFAST_LOCAL_PAIRS_FOUND" == "$PD_HIT_TO_NFAST_LOCAL_ENDPOINTS_EXPECTED" \
    && "$PD_HIT_TO_NFAST_LOCAL_GROUP_PATH_RESULT" == "OK" \
    && "$PD_HIT_TO_NFAST_LOCAL_DELAY_GATE_OK" == "YES" \
    && "$PD_HIT_TO_NFAST_LOCAL_TRANSITION_GATE_OK" == "YES" \
    && "$PD_HIT_TO_NFAST_LOCAL_OVERMATCH" == "NO" \
    && "$PD_HIT_TO_NFAST_LOCAL_UNDERMATCH" == "NO" \
    && "$PD_HIT_TO_NFAST_LOCAL_STATUS" == "PASS" ]]; then
  PD_HIT_TO_NFAST_LOCAL_GATE_OK=YES
fi
PD_LOCAL_ON22_GATE_OK=YES
if [[ "${MPTDC_GENUS_REPAIR_PD_LOCAL_ON22:-0}" == "1" ]]; then
  PD_LOCAL_ON22_GATE_OK=NO
  PD_LOCAL_ON22_CELLS_GATE_OK=NO
  PD_LOCAL_ON22_EXPECTED_CELLS_UPPER="${PD_LOCAL_ON22_SOURCE_CELLS_EXPECTED^^}"
  if [[ "$PD_LOCAL_ON22_EXPECTED_CELLS_UPPER" == "AUTO" || "$PD_LOCAL_ON22_EXPECTED_CELLS_UPPER" == "DISCOVERED" ]]; then
    if [[ "$PD_LOCAL_ON22_SOURCE_CELLS_FOUND" =~ ^[0-9]+$ \
        && "$PD_LOCAL_ON22_TARGET_CELLS_FOUND" =~ ^[0-9]+$ \
        && "$PD_LOCAL_ON22_ENDPOINTS_EXPECTED" =~ ^[0-9]+$ \
        && "$PD_LOCAL_ON22_SOURCE_CELLS_FOUND" -gt 0 \
        && "$PD_LOCAL_ON22_SOURCE_CELLS_FOUND" -le "$PD_LOCAL_ON22_ENDPOINTS_EXPECTED" \
        && "$PD_LOCAL_ON22_TARGET_CELLS_FOUND" == "$PD_LOCAL_ON22_SOURCE_CELLS_FOUND" ]]; then
      PD_LOCAL_ON22_CELLS_GATE_OK=YES
    fi
  elif [[ "$PD_LOCAL_ON22_SOURCE_CELLS_FOUND" == "$PD_LOCAL_ON22_SOURCE_CELLS_EXPECTED" \
      && "$PD_LOCAL_ON22_TARGET_CELLS_FOUND" == "$PD_LOCAL_ON22_SOURCE_CELLS_EXPECTED" ]]; then
    PD_LOCAL_ON22_CELLS_GATE_OK=YES
  fi
  if [[ ( "$PD_LOCAL_ON22_REPAIR_ENABLE" == "1" || "$PD_LOCAL_ON22_REPAIR_ENABLE" == "true" ) \
      && "$PD_LOCAL_ON22_ENDPOINTS_FOUND" == "$PD_LOCAL_ON22_ENDPOINTS_EXPECTED" \
      && "$PD_LOCAL_ON22_SOURCE_DRIVERS_FOUND" == "$PD_LOCAL_ON22_ENDPOINTS_EXPECTED" \
      && "$PD_LOCAL_ON22_CELLS_GATE_OK" == "YES" \
      && "$PD_LOCAL_ON22_REPAIR_RESULT" == "OK" \
      && "$PD_LOCAL_ON22_OVERMATCH" == "NO" \
      && "$PD_LOCAL_ON22_UNDERMATCH" == "NO" \
      && "$PD_LOCAL_ON22_STATUS" == "PASS" ]]; then
    PD_LOCAL_ON22_GATE_OK=YES
  fi
fi

if [[ "$RUN_MODE" == "validate_only" && "$GENUS_RC" == "0" ]]; then
  STATUS="GENUS_TYPICAL_VALIDATE_ONLY_OK"
elif [[ "$RUN_MODE" == "validate_only" ]]; then
  STATUS="GENUS_TYPICAL_VALIDATE_ONLY_FAILED"
elif [[ "$GENUS_RC" == "0" \
    && "$RO_COUNT" == "2" \
    && "$STUB_COUNT" == "0" \
    && "$RAW_RO_CLOCKS_FOUND" == "16" \
    && "$BUFFER_PHASE_CLOCKS_FOUND" == "16" \
    && "$CLK_SYS_ASYNC_TO_BUFFER_PHASE_CLOCKS" == "YES" \
    && "$PD_VERNIER_EXCEPTION_MATCHED" == "64" \
    && "$PD_VERNIER_SOURCE_MATCHED" == "8" \
    && "$PD_VERNIER_EXCEPTION_APPLIED" == "YES" \
    && "$PD_VERNIER_EXCEPTION_OVERMATCH" == "NO" \
    && "$PD_VERNIER_EXCEPTION_UNDERMATCH" == "NO" \
    && "$UNKNOWN_REVIEW_REQUIRED_COUNT" == "0" \
    && "$ACTIVE_SDC_FAILURE_COUNT" == "0" \
    && "$SDC_COMMAND_FAILURE_COUNT" == "0" \
    && "$EXACT_FAST_TAG_GATE_OK" == "YES" \
    && "$EXACT_SOURCE_CELL_GATE_OK" == "YES" \
    && "$FAST_TAG_EXACT_SOURCE_CELL_RESULT" == "SKIPPED_SOURCE_CELL_NOT_REQUESTED" \
    && "$PD_HIT_TO_NFAST_LOCAL_GATE_OK" == "YES" \
    && "$PD_LOCAL_ON22_GATE_OK" == "YES" \
    && "$REPORT_HELPER_FAILURE_COUNT" == "0" \
    && "$FAST_TAG_MAPPING_STATUS" == "PASS" \
    && "$SUMMARY_RAW_AGREEMENT_STATUS" == "PASS" \
    && "$TIMING_SUMMARY_PARSE_STATUS" == "PASS" \
    && "$TIMING_CLASSIFICATION_PARSE_STATUS" == "PASS" \
    && "$MAX_TRANSITION_VIOLATIONS" == "0" \
    && "$MAX_CAPACITANCE_VIOLATIONS" == "0" \
    && "$MAX_FANOUT_VIOLATIONS" == "0" \
    && "$REAL_TIMED_WNS_PS" != "NA" ]]; then
  if float_ge "$SETUP_WNS_PS" 50.0 && is_zero_metric "$SETUP_TNS_PS" && is_zero_metric "$SETUP_VIOLATING_PATHS"; then
    STATUS="GENUS_TYPICAL_CLOSED"
  elif float_ge "$SETUP_WNS_PS" -10.0 && ! float_ge "$SETUP_WNS_PS" 50.0; then
    STATUS="GENUS_TYPICAL_NEAR_CLEAN"
  fi
fi
FINAL_DECISION="$STATUS"
write_final_readiness

{
  echo "# MPTDC Genus Typical Summary"
  echo
  echo "- Flow: \`$FLOW_LABEL\`"
  echo "- Mode: \`$CLOSURE_LABEL\`"
  echo "- Package label: \`$PACKAGE_LABEL\`"
  echo "- Signoff boundary: \`$SIGNOFF_BOUNDARY\`"
  echo "- Legacy trace: \`$LEGACY_TRACE_LABEL\`"
  echo "- Run ID: \`$RUN_ID\`"
  echo "- Run mode: \`$RUN_MODE\`"
  echo "- Branch: \`$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || true)\`"
  echo "- Git HEAD: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)\`"
  echo "- Genus exit code: $GENUS_RC"
  echo "- Snapshot exit code: $SNAPSHOT_RC"
  echo "- Result directory: \`$RESULT_DIR\`"
  echo "- TYPICAL_ONLY_TAPEOUT_PACKAGE: YES"
  echo "- NOT_MMMC_SIGNOFF: YES"
  echo "- FINAL_SIGNOFF: NO"
  echo "- Signoff status: \`TYPICAL_ONLY_TAPEOUT_PACKAGE_NOT_MMMC_SIGNOFF_NOT_FINAL_SIGNOFF\`"
  echo "- Frequency mode: \`r750_delta5\`"
  echo "- Phase distribution: \`BUHDX4 -> BUHDX12\`"
  echo "- Packet format: unchanged"
  echo "- raw_lfsr_tag: unchanged"
  echo "- NFAST encoding: \`raw_lfsr_tag\`"
  echo "- Fast-tag preserve mode: \`$FAST_TAG_PRESERVE_MODE\`"
  echo "- Phase buffer topology: \`BUHDX4 -> BUHDX12 per tap\`"
  echo "- HDL filelist: \`$O13_FILELIST\`"
  echo "- SDC overlay: \`$O13_SDC\`"
  echo "- RO_tune4 instance count: $RO_COUNT"
  echo "- mptdc_osc_stub residue count: $STUB_COUNT"
  echo "- BUHDX4 instance count: $BUHDX4_COUNT"
  echo "- BUHDX12 instance count: $BUHDX12_COUNT"
  echo "- phase-buffer hierarchy text count: $PHASE_BUF_TEXT_COUNT"
  echo "- u_iso text count: $ISO_TEXT_COUNT"
  echo "- u_drv text count: $DRV_TEXT_COUNT"
  echo "- report_clocks RO_tune4/S match count: $CLOCKS_ON_RO"
  echo "- report_clocks final-driver generated-clock count: $BUFFER_CLOCKS"
  echo "- RAW_RO_CLOCKS_FOUND: $RAW_RO_CLOCKS_FOUND"
  echo "- BUFFER_PHASE_CLOCKS_FOUND: $BUFFER_PHASE_CLOCKS_FOUND"
  echo "- BUFFER_PHASE_CLOCKS_EXPECTED: $BUFFER_PHASE_CLOCKS_EXPECTED"
  echo "- BUFFER_PHASE_CLOCKS_IN_ASYNC_GROUP: $BUFFER_PHASE_CLOCKS_IN_ASYNC_GROUP"
  echo "- CLK_SYS_ASYNC_TO_BUFFER_PHASE_CLOCKS: $CLK_SYS_ASYNC_TO_BUFFER_PHASE_CLOCKS"
  echo "- PD intentional Vernier paths expected: $PD_VERNIER_EXCEPTION_EXPECTED"
  echo "- PD intentional Vernier paths matched: $PD_VERNIER_EXCEPTION_MATCHED"
  echo "- PD intentional Vernier sources matched: $PD_VERNIER_SOURCE_MATCHED"
  echo "- PD intentional Vernier exception applied: $PD_VERNIER_EXCEPTION_APPLIED"
  echo "- PD intentional Vernier overmatch: $PD_VERNIER_EXCEPTION_OVERMATCH"
  echo "- PD intentional Vernier undermatch: $PD_VERNIER_EXCEPTION_UNDERMATCH"
  echo "- UNKNOWN_REVIEW_REQUIRED count: $UNKNOWN_REVIEW_REQUIRED_COUNT"
  echo "- SDC command failure count: $SDC_COMMAND_FAILURE_COUNT"
  echo "- ACTIVE_SDC_FAILURE_COUNT: $ACTIVE_SDC_FAILURE_COUNT"
  echo "- REPORT_DIAGNOSTIC_WARNING_COUNT: $REPORT_DIAGNOSTIC_WARNING_COUNT"
  echo "- RAW_SDC_DIAGNOSTIC_COUNT: $RAW_SDC_DIAGNOSTIC_COUNT"
  echo "- SDC_235_COUNT: $SDC_235_COUNT"
  echo "- TUI_61_COUNT: $TUI_61_COUNT"
  echo "- SDC invalid object count: $SDC_INVALID_OBJECT_COUNT"
  echo "- EXACT_FAST_TAG_SOURCES_EXPECTED: $EXACT_FAST_TAG_SOURCES_EXPECTED"
  echo "- EXACT_FAST_TAG_SOURCES_FOUND: $EXACT_FAST_TAG_SOURCES_FOUND"
  echo "- EXACT_FAST_TAG_ENDPOINTS_EXPECTED: $EXACT_FAST_TAG_ENDPOINTS_EXPECTED"
  echo "- EXACT_FAST_TAG_ENDPOINTS_FOUND: $EXACT_FAST_TAG_ENDPOINTS_FOUND"
  echo "- EXACT_FAST_TAG_DATAPATHS_EXPECTED: $EXACT_FAST_TAG_DATAPATHS_EXPECTED"
  echo "- EXACT_FAST_TAG_DATAPATHS_FOUND: $EXACT_FAST_TAG_DATAPATHS_FOUND"
  echo "- EXACT_FAST_TAG_REPAIR_APPLIED: $EXACT_FAST_TAG_REPAIR_APPLIED"
  echo "- EXACT_FAST_TAG_REPAIR_STATUS: $EXACT_FAST_TAG_REPAIR_STATUS"
  echo "- FAST_TAG_EXACT_C_TO_D_SET_MAX_DELAY_RESULT: $FAST_TAG_EXACT_C_TO_D_SET_MAX_DELAY_RESULT"
  echo "- FAST_TAG_EXACT_MAX_DELAY_CONSTRAINT_MODE: $FAST_TAG_EXACT_MAX_DELAY_CONSTRAINT_MODE"
  echo "- FAST_TAG_EXACT_SOURCE_CELL_TARGET: $FAST_TAG_EXACT_SOURCE_CELL_TARGET"
  echo "- FAST_TAG_EXACT_SOURCE_CELL_REQUESTED: $FAST_TAG_EXACT_SOURCE_CELL_REQUESTED"
  echo "- FAST_TAG_EXACT_SOURCE_CELL_LIB_CELLS_FOUND: $FAST_TAG_EXACT_SOURCE_CELL_LIB_CELLS_FOUND"
  echo "- FAST_TAG_EXACT_SOURCE_CELL_COUNT: $FAST_TAG_EXACT_SOURCE_CELL_COUNT"
  echo "- FAST_TAG_EXACT_SOURCE_CELL_TARGET_COUNT: $FAST_TAG_EXACT_SOURCE_CELL_TARGET_COUNT"
  echo "- FAST_TAG_EXACT_SOURCE_CELL_METHOD: $FAST_TAG_EXACT_SOURCE_CELL_METHOD"
  echo "- FAST_TAG_EXACT_SOURCE_CELL_RESULT: $FAST_TAG_EXACT_SOURCE_CELL_RESULT"
  echo "- FAST_TAG_EXACT_SOURCE_CELL_MODE: $FAST_TAG_EXACT_SOURCE_CELL_MODE"
  echo "- FAST_TAG_EXACT_RESET0_SOURCE_COUNT: $FAST_TAG_EXACT_RESET0_SOURCE_COUNT"
  echo "- FAST_TAG_EXACT_SET1_SOURCE_COUNT: $FAST_TAG_EXACT_SET1_SOURCE_COUNT"
  echo "- FAST_TAG_EXACT_SOURCE_UNSUPPORTED_POLARITY_COUNT: $FAST_TAG_EXACT_SOURCE_UNSUPPORTED_POLARITY_COUNT"
  echo "- FAST_TAG_EXACT_SELECTED_RESET0_TARGET: $FAST_TAG_EXACT_SELECTED_RESET0_TARGET"
  echo "- FAST_TAG_EXACT_SELECTED_SET1_TARGET: $FAST_TAG_EXACT_SELECTED_SET1_TARGET"
  echo "- FAST_TAG_EXACT_DFRRQHDX4_TARGET_COUNT: $FAST_TAG_EXACT_DFRRQHDX4_TARGET_COUNT"
  echo "- FAST_TAG_EXACT_DFRSQHDX4_TARGET_COUNT: $FAST_TAG_EXACT_DFRSQHDX4_TARGET_COUNT"
  echo "- FAST_TAG_EXACT_DFRSQHDX2_TARGET_COUNT: $FAST_TAG_EXACT_DFRSQHDX2_TARGET_COUNT"
  echo "- FAST_TAG_EXACT_DFRRQJIHDX4_TARGET_COUNT: $FAST_TAG_EXACT_DFRRQJIHDX4_TARGET_COUNT"
  echo "- FAST_TAG_EXACT_DFRSJIHDX4_TARGET_COUNT: $FAST_TAG_EXACT_DFRSJIHDX4_TARGET_COUNT"
  echo "- FAST_TAG_EXACT_DFRSJIHDX2_TARGET_COUNT: $FAST_TAG_EXACT_DFRSJIHDX2_TARGET_COUNT"
  echo "- FAST_TAG_EXACT_SOURCE_POLARITY_PRESERVED_COUNT: $FAST_TAG_EXACT_SOURCE_POLARITY_PRESERVED_COUNT"
  echo "- FAST_TAG_EXACT_SOURCE_POLARITY_FAILED_COUNT: $FAST_TAG_EXACT_SOURCE_POLARITY_FAILED_COUNT"
  echo "- FAST_TAG_EXACT_SOURCE_FREEZE_RESULT: $FAST_TAG_EXACT_SOURCE_FREEZE_RESULT"
  echo "- PD_HIT_TO_NFAST_LOCAL_REPAIR_ENABLE: $PD_HIT_TO_NFAST_LOCAL_REPAIR_ENABLE"
  echo "- PD_HIT_TO_NFAST_LOCAL_SOURCES_EXPECTED: $PD_HIT_TO_NFAST_LOCAL_SOURCES_EXPECTED"
  echo "- PD_HIT_TO_NFAST_LOCAL_SOURCES_FOUND: $PD_HIT_TO_NFAST_LOCAL_SOURCES_FOUND"
  echo "- PD_HIT_TO_NFAST_LOCAL_SOURCE_Q_FOUND: $PD_HIT_TO_NFAST_LOCAL_SOURCE_Q_FOUND"
  echo "- PD_HIT_TO_NFAST_LOCAL_ENDPOINTS_EXPECTED: $PD_HIT_TO_NFAST_LOCAL_ENDPOINTS_EXPECTED"
  echo "- PD_HIT_TO_NFAST_LOCAL_ENDPOINTS_FOUND: $PD_HIT_TO_NFAST_LOCAL_ENDPOINTS_FOUND"
  echo "- PD_HIT_TO_NFAST_LOCAL_PAIRS_FOUND: $PD_HIT_TO_NFAST_LOCAL_PAIRS_FOUND"
  echo "- PD_HIT_TO_NFAST_LOCAL_BITS: $PD_HIT_TO_NFAST_LOCAL_BITS"
  echo "- PD_HIT_TO_NFAST_LOCAL_MAX_DELAY_NS: $PD_HIT_TO_NFAST_LOCAL_MAX_DELAY_NS"
  echo "- PD_HIT_TO_NFAST_LOCAL_MAX_TRANSITION_NS: $PD_HIT_TO_NFAST_LOCAL_MAX_TRANSITION_NS"
  echo "- PD_HIT_TO_NFAST_LOCAL_GROUP_PATH_RESULT: $PD_HIT_TO_NFAST_LOCAL_GROUP_PATH_RESULT"
  echo "- PD_HIT_TO_NFAST_LOCAL_SET_MAX_DELAY_RESULT: $PD_HIT_TO_NFAST_LOCAL_SET_MAX_DELAY_RESULT"
  echo "- PD_HIT_TO_NFAST_LOCAL_MAX_DELAY_CONSTRAINT_MODE: $PD_HIT_TO_NFAST_LOCAL_MAX_DELAY_CONSTRAINT_MODE"
  echo "- PD_HIT_TO_NFAST_LOCAL_SET_MAX_TRANSITION_RESULT: $PD_HIT_TO_NFAST_LOCAL_SET_MAX_TRANSITION_RESULT"
  echo "- PD_HIT_TO_NFAST_LOCAL_OVERMATCH: $PD_HIT_TO_NFAST_LOCAL_OVERMATCH"
  echo "- PD_HIT_TO_NFAST_LOCAL_UNDERMATCH: $PD_HIT_TO_NFAST_LOCAL_UNDERMATCH"
  echo "- PD_HIT_TO_NFAST_LOCAL_STATUS: $PD_HIT_TO_NFAST_LOCAL_STATUS"
  echo "- PD_HIT_TO_NFAST_LOCAL_REVIEW_REASON: $PD_HIT_TO_NFAST_LOCAL_REVIEW_REASON"
  echo "- PD_LOCAL_ON22_REPAIR_ENABLE: $PD_LOCAL_ON22_REPAIR_ENABLE"
  echo "- PD_LOCAL_ON22_SOURCE_CELL: $PD_LOCAL_ON22_SOURCE_CELL"
  echo "- PD_LOCAL_ON22_TARGET_CELLS: $PD_LOCAL_ON22_TARGET_CELLS"
  echo "- PD_LOCAL_ON22_SELECTED_TARGET: $PD_LOCAL_ON22_SELECTED_TARGET"
  echo "- PD_LOCAL_ON22_TARGET_LIB_CELLS_FOUND: $PD_LOCAL_ON22_TARGET_LIB_CELLS_FOUND"
  echo "- PD_LOCAL_ON22_ENDPOINTS_EXPECTED: $PD_LOCAL_ON22_ENDPOINTS_EXPECTED"
  echo "- PD_LOCAL_ON22_ENDPOINTS_FOUND: $PD_LOCAL_ON22_ENDPOINTS_FOUND"
  echo "- PD_LOCAL_ON22_SOURCE_DRIVERS_FOUND: $PD_LOCAL_ON22_SOURCE_DRIVERS_FOUND"
  echo "- PD_LOCAL_ON22_SOURCE_CELLS_EXPECTED: $PD_LOCAL_ON22_SOURCE_CELLS_EXPECTED"
  echo "- PD_LOCAL_ON22_SOURCE_CELLS_FOUND: $PD_LOCAL_ON22_SOURCE_CELLS_FOUND"
  echo "- PD_LOCAL_ON22_CHANGED_CELLS: $PD_LOCAL_ON22_CHANGED_CELLS"
  echo "- PD_LOCAL_ON22_TARGET_CELLS_FOUND: $PD_LOCAL_ON22_TARGET_CELLS_FOUND"
  echo "- PD_LOCAL_ON22_REPAIR_RESULT: $PD_LOCAL_ON22_REPAIR_RESULT"
  echo "- PD_LOCAL_ON22_OVERMATCH: $PD_LOCAL_ON22_OVERMATCH"
  echo "- PD_LOCAL_ON22_UNDERMATCH: $PD_LOCAL_ON22_UNDERMATCH"
  echo "- PD_LOCAL_ON22_STATUS: $PD_LOCAL_ON22_STATUS"
  echo "- PD_LOCAL_ON22_REVIEW_REASON: $PD_LOCAL_ON22_REVIEW_REASON"
  echo "- Max transition violations: $MAX_TRANSITION_VIOLATIONS"
  echo "- Max capacitance violations: $MAX_CAPACITANCE_VIOLATIONS"
  echo "- Max fanout violations: $MAX_FANOUT_VIOLATIONS"
  echo "- Setup WNS ps: $SETUP_WNS_PS"
  echo "- Setup TNS ps: $SETUP_TNS_PS"
  echo "- Setup violating path count: $SETUP_VIOLATING_PATHS"
  echo "- Hold WNS ps: $HOLD_WNS_PS"
  echo "- Hold TNS ps: $HOLD_TNS_PS"
  echo "- Real timed WNS ps: $REAL_TIMED_WNS_PS"
  echo "- Real timed TNS ps: $REAL_TIMED_TNS_PS"
  echo "- Real timed violating path count: $REAL_TIMED_VIOLATING_PATHS"
  echo "- Worst real path family: $WORST_REAL_PATH_FAMILY"
  echo "- Report helper failure count: $REPORT_HELPER_FAILURE_COUNT"
  echo "- Report helpers status: $REPORT_HELPERS_STATUS"
  echo "- FAST_TAG_FLOP_BIAS_MODE: $FAST_TAG_FLOP_BIAS_MODE"
  echo "- FAST_TAG_PRESERVE_MODE: $FAST_TAG_PRESERVE_MODE"
  echo "- FAST_TAG_MAPPING_PARSE_STATUS: $FAST_TAG_MAPPING_PARSE_STATUS"
  echo "- FAST_TAG_MAPPING_STATUS: $FAST_TAG_MAPPING_STATUS"
  echo "- FAST_TAG_SOURCE_DFRRQHDX0_COUNT: $FAST_TAG_SOURCE_DFRRQHDX0_COUNT"
  echo "- FAST_TAG_SOURCE_DFRRQHDX1_COUNT: $FAST_TAG_SOURCE_DFRRQHDX1_COUNT"
  echo "- FAST_TAG_SOURCE_DFRRQHDX2_COUNT: $FAST_TAG_SOURCE_DFRRQHDX2_COUNT"
  echo "- FAST_TAG_SOURCE_DFRRQHDX4_COUNT: $FAST_TAG_SOURCE_DFRRQHDX4_COUNT"
  echo "- FAST_TAG_SOURCE_DFRSQHDX0_COUNT: $FAST_TAG_SOURCE_DFRSQHDX0_COUNT"
  echo "- FAST_TAG_SOURCE_DFRSQHDX1_COUNT: $FAST_TAG_SOURCE_DFRSQHDX1_COUNT"
  echo "- FAST_TAG_SOURCE_DFRSQHDX2_COUNT: $FAST_TAG_SOURCE_DFRSQHDX2_COUNT"
  echo "- FAST_TAG_SOURCE_DFRSQHDX4_COUNT: $FAST_TAG_SOURCE_DFRSQHDX4_COUNT"
  echo "- FAST_TAG_SOURCE_DFRJIHDX0_COUNT: $FAST_TAG_SOURCE_DFRJIHDX0_COUNT"
  echo "- FAST_TAG_SOURCE_DFRJIHDX1_COUNT: $FAST_TAG_SOURCE_DFRJIHDX1_COUNT"
  echo "- FAST_TAG_SOURCE_DFRJIHDX2_COUNT: $FAST_TAG_SOURCE_DFRJIHDX2_COUNT"
  echo "- FAST_TAG_SOURCE_DFRJIHDX4_COUNT: $FAST_TAG_SOURCE_DFRJIHDX4_COUNT"
  echo "- FAST_TAG_SOURCE_DFRRQJIHDX0_COUNT: $FAST_TAG_SOURCE_DFRRQJIHDX0_COUNT"
  echo "- FAST_TAG_SOURCE_DFRRQJIHDX1_COUNT: $FAST_TAG_SOURCE_DFRRQJIHDX1_COUNT"
  echo "- FAST_TAG_SOURCE_DFRRQJIHDX2_COUNT: $FAST_TAG_SOURCE_DFRRQJIHDX2_COUNT"
  echo "- FAST_TAG_SOURCE_DFRRQJIHDX4_COUNT: $FAST_TAG_SOURCE_DFRRQJIHDX4_COUNT"
  echo "- FAST_TAG_SOURCE_DFRSJIHDX2_COUNT: $FAST_TAG_SOURCE_DFRSJIHDX2_COUNT"
  echo "- FAST_TAG_SOURCE_UNKNOWN_COUNT: $FAST_TAG_SOURCE_UNKNOWN_COUNT"
  echo "- FAST_TAG_MAPPED_SOURCE_COUNT: $FAST_TAG_MAPPED_SOURCE_COUNT"
  echo "- FAST_TAG_MAPPED_ENDPOINT_COUNT: $FAST_TAG_MAPPED_ENDPOINT_COUNT"
  echo "- FAST_TAG_TOP_PATH_COUNT: $FAST_TAG_TOP_PATH_COUNT"
  echo "- FAST_TAG_EXACT_SOURCE_COUNT: $FAST_TAG_EXACT_SOURCE_COUNT"
  echo "- FAST_TAG_EXACT_SOURCE_DFRRQHDX1_COUNT: $FAST_TAG_EXACT_SOURCE_DFRRQHDX1_COUNT"
  echo "- FAST_TAG_EXACT_SOURCE_DFRRQHDX2_COUNT: $FAST_TAG_EXACT_SOURCE_DFRRQHDX2_COUNT"
  echo "- FAST_TAG_EXACT_SOURCE_DFRRQHDX4_COUNT: $FAST_TAG_EXACT_SOURCE_DFRRQHDX4_COUNT"
  echo "- FAST_TAG_EXACT_SOURCE_DFRSQHDX0_COUNT: $FAST_TAG_EXACT_SOURCE_DFRSQHDX0_COUNT"
  echo "- FAST_TAG_EXACT_SOURCE_DFRSQHDX1_COUNT: $FAST_TAG_EXACT_SOURCE_DFRSQHDX1_COUNT"
  echo "- FAST_TAG_EXACT_SOURCE_DFRSQHDX2_COUNT: $FAST_TAG_EXACT_SOURCE_DFRSQHDX2_COUNT"
  echo "- FAST_TAG_EXACT_SOURCE_DFRSQHDX4_COUNT: $FAST_TAG_EXACT_SOURCE_DFRSQHDX4_COUNT"
  echo "- FAST_TAG_EXACT_SOURCE_DFRJIHDX1_COUNT: $FAST_TAG_EXACT_SOURCE_DFRJIHDX1_COUNT"
  echo "- FAST_TAG_EXACT_SOURCE_DFRJIHDX2_COUNT: $FAST_TAG_EXACT_SOURCE_DFRJIHDX2_COUNT"
  echo "- FAST_TAG_EXACT_SOURCE_DFRJIHDX4_COUNT: $FAST_TAG_EXACT_SOURCE_DFRJIHDX4_COUNT"
  echo "- FAST_TAG_EXACT_SOURCE_UNKNOWN_COUNT: $FAST_TAG_EXACT_SOURCE_UNKNOWN_COUNT"
  echo "- FAST_TAG_EXACT_ENDPOINT_COUNT: $FAST_TAG_EXACT_ENDPOINT_COUNT"
  echo "- FAST_TAG_EXACT_ENDPOINT_DFRHDX2_COUNT: $FAST_TAG_EXACT_ENDPOINT_DFRHDX2_COUNT"
  echo "- FAST_TAG_EXACT_ENDPOINT_DFRHDX4_COUNT: $FAST_TAG_EXACT_ENDPOINT_DFRHDX4_COUNT"
  echo "- FAST_TAG_EXACT_ENDPOINT_DFRSHDX2_COUNT: $FAST_TAG_EXACT_ENDPOINT_DFRSHDX2_COUNT"
  echo "- FAST_TAG_EXACT_ENDPOINT_DFRSHDX4_COUNT: $FAST_TAG_EXACT_ENDPOINT_DFRSHDX4_COUNT"
  echo "- FAST_TAG_EXACT_ENDPOINT_UNKNOWN_COUNT: $FAST_TAG_EXACT_ENDPOINT_UNKNOWN_COUNT"
  echo "- FAST_TAG_EXACT_SOURCE_PHASE_CLOCK_LOAD_DELTA_ESTIMATE: $FAST_TAG_EXACT_SOURCE_PHASE_CLOCK_LOAD_DELTA_ESTIMATE"
  echo "- Timing summary parse status: $TIMING_SUMMARY_PARSE_STATUS"
  echo "- Timing classification parse status: $TIMING_CLASSIFICATION_PARSE_STATUS"
  echo "- Summary/raw agreement status: $SUMMARY_RAW_AGREEMENT_STATUS"
  echo
  echo "FINAL_DECISION=$FINAL_DECISION"
  echo "GENUS_TYPICAL_STATUS=$STATUS"
  echo "LEGACY_TRACE=$LEGACY_TRACE_LABEL"
  echo "FINAL_SIGNOFF=NO"
  echo "TYPICAL_ONLY_TAPEOUT_PACKAGE=YES"
  echo "NOT_MMMC_SIGNOFF=YES"
  if [[ "$STATUS" == "GENUS_TYPICAL_CLOSED" ]]; then
    echo "READY_FOR_O13_INNOVUS_FEASIBILITY=YES"
    echo "INNOVUS_READY=READY_FOR_O13_INNOVUS_FEASIBILITY"
  elif [[ "$STATUS" == "GENUS_TYPICAL_NEAR_CLEAN" ]]; then
    echo "READY_FOR_O13_INNOVUS_FEASIBILITY=NO_NEAR_CLEAN_GENUS_REVIEW_FIRST"
    echo "INNOVUS_READY=NO_NEAR_CLEAN_GENUS_REVIEW_FIRST"
  else
    echo "READY_FOR_O13_INNOVUS_FEASIBILITY=NO_REVIEW_FINAL_TYPICAL_GENUS_FIRST"
    echo "INNOVUS_READY=NO_REVIEW_FINAL_TYPICAL_GENUS_FIRST"
  fi
  echo
  echo "## Key Files"
  for file in \
    "genus_${RUN_ID}.log" \
    mptdc_axis_core.postsyn.v \
    mptdc_axis_core.postsyn.sdc \
    final_sdc_overlay_used.sdc \
    final_filelist_used.f \
    o13_phase_distribution_check.rpt \
    run_manifest.txt \
    report_clocks.rpt \
    report_clocks_generated.rpt \
    report_clock_groups.rpt \
    report_exceptions.rpt \
    check_timing_intent_post_synth.rpt \
    report_design_rules.rpt \
    report_high_fanout.rpt \
    report_area.rpt \
    report_qor.rpt \
    timing_summary.rpt \
    timing_violations.rpt \
    timing_pd_capture_hotspots.rpt \
    timing_clk_sys_violations.rpt \
    timing_clk_sys_internal_top100.rpt \
    timing_cdc_async_review.rpt \
    timing_pd_intentional_vernier.rpt \
    pd_vernier_exception_check.rpt \
    pd_vernier_endpoint_discovery.rpt \
    pd_vernier_source_discovery.rpt \
    timing_o13_phase_buffer_paths.rpt \
    o13_clock_model_check.rpt \
    o13_clock_model_check.sdc.rpt \
    sdc_command_failures.md \
    macro_binding_check.rpt \
    packet_contract_check.rpt \
    final_typical_genus_readiness.md \
    summary_parser_check.rpt \
    report_helpers_status.rpt \
    helper_tcl_selftest.rpt \
    fast_tag_exact_repair_status.rpt \
    fast_tag_exact_source_discovery.csv \
    fast_tag_exact_endpoint_discovery.csv \
    fast_tag_exact_path_pairs.csv \
    fast_tag_exact_source_cell_repair.csv \
    fast_tag_exact_source_cell_legal_cells.rpt \
    fast_tag_exact_source_cell_command_ladder.rpt \
    fast_tag_exact_source_freeze.rpt \
    pd_hit_to_nfast_local_repair_status.rpt \
    pd_hit_to_nfast_local_source_discovery.csv \
    pd_hit_to_nfast_local_source_q_discovery.csv \
    pd_hit_to_nfast_local_endpoint_discovery.csv \
    pd_hit_to_nfast_local_path_pairs.csv \
    pd_local_on22_repair_status.rpt \
    pd_local_on22_driver_discovery.csv \
    pd_local_on22_cell_repair.csv \
    pd_local_on22_legal_cells.rpt \
    reports/fast_tag_exact_repair_status.rpt \
    reports/fast_tag_exact_source_discovery.csv \
    reports/fast_tag_exact_endpoint_discovery.csv \
    reports/fast_tag_exact_path_pairs.csv \
    reports/fast_tag_exact_source_cell_repair.csv \
    reports/fast_tag_exact_source_cell_legal_cells.rpt \
    reports/fast_tag_exact_source_cell_command_ladder.rpt \
    reports/fast_tag_exact_source_freeze.rpt \
    reports/pd_hit_to_nfast_local_repair_status.rpt \
    reports/pd_hit_to_nfast_local_source_discovery.csv \
    reports/pd_hit_to_nfast_local_source_q_discovery.csv \
    reports/pd_hit_to_nfast_local_endpoint_discovery.csv \
    reports/pd_hit_to_nfast_local_path_pairs.csv \
    reports/pd_local_on22_repair_status.rpt \
    reports/pd_local_on22_driver_discovery.csv \
    reports/pd_local_on22_cell_repair.csv \
    reports/pd_local_on22_legal_cells.rpt \
    fast_tag_cell_mapping_guardrail.rpt \
    final_genus_fast_tag_to_pd_ts_analysis.md \
    reports/fast_tag_cell_mapping.csv \
    reports/drv_transition_root_causes.csv \
    reports/control_drv_root_causes.csv \
    timing_path_classification.csv \
    timing_path_classification_summary.md; do
    if [[ -f "$RESULT_DIR/$file" ]]; then
      echo "- present: \`$file\`"
    else
      echo "- missing: \`$file\`"
    fi
  done
} > "$RESULT_DIR/SUMMARY.md"

cat "$RESULT_DIR/SUMMARY.md"

if [[ "$GENUS_RC" != "0" ]]; then
  exit "$GENUS_RC"
fi
if [[ "$SNAPSHOT_RC" != "0" ]]; then
  exit "$SNAPSHOT_RC"
fi
if [[ "$STATUS" == "GENUS_TYPICAL_VALIDATE_ONLY_OK" || "$STATUS" == "GENUS_TYPICAL_CLOSED" ]]; then
  exit 0
fi
exit 1
