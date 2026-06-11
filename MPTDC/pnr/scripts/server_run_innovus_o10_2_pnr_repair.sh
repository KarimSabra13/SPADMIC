#!/usr/bin/env bash
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$PNR_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

RUN_ID="${1:-20260604_o10_2_pnr_repair}"
RUN_MODE="${MPTDC_O10_2_MODE:-route_feasibility}"
if [[ "${MPTDC_O10_VALIDATE_ONLY:-0}" == "1" ]]; then
  RUN_MODE="validate_only"
fi

RESULT_DIR="$REPO_ROOT/results/innovus/$RUN_ID"
SNAPSHOT_TAG="innovus_o10_2_pnr_repair_${RUN_ID}"
SNAPSHOT_DIR="$MPTDC_DIR/lab_snapshots/$SNAPSHOT_TAG"
LOG_DIR="$RESULT_DIR/logs"
RUN_LOG="$LOG_DIR/innovus_${RUN_ID}.log"

O9_DIR="$REPO_ROOT/results/genus_osc_pd/20260604_o9_final_typical_r750_delta5"
NETLIST="${MPTDC_O10_NETLIST:-$O9_DIR/mptdc_top_asic.postsyn.v}"
POSTSYN_SDC="${MPTDC_O10_POSTSYN_SDC:-$O9_DIR/mptdc_top_asic.postsyn.sdc}"
OVERLAY_SDC="${MPTDC_O10_SDC_OVERLAY:-$MPTDC_DIR/pnr/constraints/mptdc_osc_typical_r750_delta5_innovus.sdc}"
RO_LEF="${O1_RO_LEF_PATH:-$REPO_ROOT/results/osc_pd/20260528_o1_export_ro_tune4_lef/real_abstract_lef/RO_tune4_real_abstract.lef}"
RO_LIB="${O1_RO_LIBERTY_PATH:-$MPTDC_DIR/syn/macros/RO_tune4_real_abstract_shell.lib}"

repo_abs_path() {
  local path="$1"
  case "$path" in
    ""|/*) printf '%s\n' "$path" ;;
    *) printf '%s/%s\n' "$REPO_ROOT" "$path" ;;
  esac
}

NETLIST="$(repo_abs_path "$NETLIST")"
POSTSYN_SDC="$(repo_abs_path "$POSTSYN_SDC")"
OVERLAY_SDC="$(repo_abs_path "$OVERLAY_SDC")"
RO_LEF="$(repo_abs_path "$RO_LEF")"
RO_LIB="$(repo_abs_path "$RO_LIB")"

PDK_ROOT="${PDK_ROOT:-/data/pdk/xfab/xh018}"
TECH_LEF="${TECHNOLOGY_LEF:-$PDK_ROOT/cadence/v9_0/techLEF/v9_0_1/xh018_xx41_HD_MET4_METMID.lef}"
STDCELL_FAMILY="${MPTDC_STDCELL_FAMILY:-}"
if [[ -z "$STDCELL_FAMILY" && -f "$NETLIST" ]]; then
  if grep -q 'JIHD' "$NETLIST"; then
    STDCELL_FAMILY="JIHD"
  fi
fi
STDCELL_FAMILY="${STDCELL_FAMILY:-HD}"
STDCELL_FAMILY="${STDCELL_FAMILY^^}"
case "$STDCELL_FAMILY" in
  JIHD)
    SC_ROOT="${SC_ROOT:-$PDK_ROOT/diglibs/D_CELLS_JIHD/v6_0}"
    STDCELL_SITE="${MPTDC_O10_STDCELL_SITE:-${MPTDC_STDCELL_SITE:-core_jihd}}"
    STD_LEF_DEFAULT="$SC_ROOT/LEF/v6_0_0/xh018_D_CELLS_JIHD.lef"
    for candidate in \
      "$SC_ROOT/LEF/v6_0_0/xh018/xh018_D_CELLS_JIHD.lef" \
      "$SC_ROOT/LEF/v6_0_0/xh018_D_CELLS_JIHD.lef"
    do
      if [[ -f "$candidate" ]]; then
        STD_LEF_DEFAULT="$candidate"
        break
      fi
    done
    STD_TC_LIB_DEFAULT="$SC_ROOT/liberty_LPMOS/v6_0_0/PVT_1_80V_range/D_CELLS_JIHD_LPMOS_typ_1_80V_25C.lib"
    ;;
  HD)
    SC_ROOT="${SC_ROOT:-$PDK_ROOT/diglibs/D_CELLS_HD/v6_0}"
    STDCELL_SITE="${MPTDC_O10_STDCELL_SITE:-${MPTDC_STDCELL_SITE:-core_hd}}"
    STD_LEF_DEFAULT="$SC_ROOT/LEF/v6_0_0/xh018_D_CELLS_HD.lef"
    STD_TC_LIB_DEFAULT="$SC_ROOT/liberty_LPMOS/v6_0_0/PVT_1_80V_range/D_CELLS_HD_LPMOS_typ_1_80V_25C.lib"
    ;;
  *)
    echo "ERROR: unsupported MPTDC_STDCELL_FAMILY=$STDCELL_FAMILY; expected HD or JIHD" >&2
    exit 2
    ;;
esac
STD_LEF="${MPTDC_O10_STDCELL_LEF:-${MPTDC_STDCELL_LEF:-$STD_LEF_DEFAULT}}"
STD_TC_LIB="${MPTDC_O10_STDCELL_TYP_LIB:-${MPTDC_STDCELL_TC_LIB:-$STD_TC_LIB_DEFAULT}}"
POWER_NETS="${MPTDC_O10_POWER_NETS:-VDD VSS}"

mkdir -p "$LOG_DIR" "$RESULT_DIR/manifests" "$RESULT_DIR/reports" "$RESULT_DIR/screenshots" "$RESULT_DIR/manager"

case "$RUN_MODE" in
  validate_only|place_only|route_feasibility|gui_screenshot) ;;
  *)
    echo "ERROR: unsupported MPTDC_O10_2_MODE=$RUN_MODE" >&2
    echo "Supported: validate_only, place_only, route_feasibility, gui_screenshot" >&2
    exit 2
    ;;
esac

{
  echo "# O10.2 Innovus PNR Constraint/Report/CTS Repair Run"
  echo "date: $(date -Iseconds)"
  echo "repo: $REPO_ROOT"
  echo "branch: $(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || true)"
  echo "head: $(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)"
  echo "expected_head: ${EXPECTED_HEAD:-unset}"
  echo "run_id: $RUN_ID"
  echo "run_mode: $RUN_MODE"
  echo "snapshot_tag: $SNAPSHOT_TAG"
  echo "labels: O10_2_PNR_CONSTRAINT_REPORT_CTS_REPAIR O10_INNOVUS_TYPICAL_FEASIBILITY NOT_MMMC_SIGNOFF NOT_FINAL_SIGNOFF NOT_TAPEOUT_READY"
  echo
  echo "git status --short:"
  git -C "$REPO_ROOT" status --short 2>/dev/null || true
  echo
  echo "inputs:"
  echo "  netlist: $NETLIST"
  echo "  postsyn_sdc: $POSTSYN_SDC"
  echo "  overlay_sdc: $OVERLAY_SDC"
  echo "  ro_lef: $RO_LEF"
  echo "  ro_lib: $RO_LIB"
  echo "  tech_lef: $TECH_LEF"
  echo "  stdcell_family: $STDCELL_FAMILY"
  echo "  stdcell_site: $STDCELL_SITE"
  echo "  stdcell_lef: $STD_LEF"
  echo "  stdcell_typ_lib: $STD_TC_LIB"
  echo "  power_nets: $POWER_NETS"
  echo "  screenshot_mode: ${MPTDC_O10_SCREENSHOT_MODE:-batch}"
} | tee "$RESULT_DIR/manifests/run_manifest.txt" | tee "$RUN_LOG"

INPUT_RC=0
require_file() {
  local label="$1"
  local path="$2"
  if [[ ! -f "$path" ]]; then
    echo "ERROR: missing $label: $path" | tee -a "$RUN_LOG"
    INPUT_RC=2
  fi
}

ACTUAL_HEAD="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)"
if [[ -n "${EXPECTED_HEAD:-}" && "$ACTUAL_HEAD" != "$EXPECTED_HEAD" ]]; then
  echo "ERROR: HEAD mismatch. expected=$EXPECTED_HEAD actual=$ACTUAL_HEAD" | tee -a "$RUN_LOG"
  INPUT_RC=5
fi

require_file "post-synthesis netlist" "$NETLIST"
require_file "post-synthesis SDC" "$POSTSYN_SDC"
require_file "O10.2 Innovus-safe overlay SDC" "$OVERLAY_SDC"
require_file "RO_tune4 real LEF" "$RO_LEF"
require_file "RO_tune4 Liberty shell" "$RO_LIB"
require_file "technology LEF" "$TECH_LEF"
require_file "standard-cell LEF" "$STD_LEF"
require_file "standard-cell typical Liberty" "$STD_TC_LIB"

if [[ -f "$RO_LEF" ]]; then
  macro_name="$(awk '
    /^[[:space:]]*PROPERTYDEFINITIONS[[:space:]]*$/ {inprop=1; next}
    inprop && /^[[:space:]]*END[[:space:]]+PROPERTYDEFINITIONS[[:space:]]*$/ {inprop=0; next}
    inprop {next}
    /^[[:space:]]*MACRO[[:space:]]+[^[:space:];]+[[:space:]]*$/ {print $2; exit}
  ' "$RO_LEF")"
  echo "RO LEF macro: ${macro_name:-unknown}" | tee -a "$RUN_LOG"
  if [[ "${macro_name:-}" != "RO_tune4" ]]; then
    echo "ERROR: RO LEF macro is not RO_tune4" | tee -a "$RUN_LOG"
    INPUT_RC=3
  fi
  ro_size_w="$(awk '/^[[:space:]]*SIZE[[:space:]]+/ {print $2; exit}' "$RO_LEF")"
  ro_size_h="$(awk '/^[[:space:]]*SIZE[[:space:]]+/ {print $4; exit}' "$RO_LEF")"
  ro_origin_x="$(awk '/^[[:space:]]*ORIGIN[[:space:]]+/ {print $2; exit}' "$RO_LEF")"
  ro_origin_y="$(awk '/^[[:space:]]*ORIGIN[[:space:]]+/ {print $3; exit}' "$RO_LEF")"
  echo "RO LEF size: ${ro_size_w:-unknown} x ${ro_size_h:-unknown} um" | tee -a "$RUN_LOG"
  echo "RO LEF origin: ${ro_origin_x:-0} ${ro_origin_y:-0} um" | tee -a "$RUN_LOG"
fi

if [[ -f "$NETLIST" ]]; then
  ro_count="$(grep -c 'RO_tune4' "$NETLIST" || true)"
  stub_count="$(grep -c 'mptdc_osc_stub' "$NETLIST" || true)"
  echo "RO_tune4 netlist reference count: $ro_count" | tee -a "$RUN_LOG"
  echo "mptdc_osc_stub residue count: $stub_count" | tee -a "$RUN_LOG"
  if [[ "$ro_count" -lt 2 || "$stub_count" -ne 0 ]]; then
    echo "ERROR: netlist does not look like O9 real RO_tune4 binding" | tee -a "$RUN_LOG"
    INPUT_RC=4
  fi
fi

export MPTDC_O10_RUN_ID="$RUN_ID"
export MPTDC_O10_RESULT_DIR="$RESULT_DIR"
export MPTDC_O10_NETLIST="$NETLIST"
export MPTDC_O10_POSTSYN_SDC="$POSTSYN_SDC"
export MPTDC_O10_SDC_OVERLAY="$OVERLAY_SDC"
export MPTDC_O10_SCREENSHOT_MODE="${MPTDC_O10_SCREENSHOT_MODE:-batch}"
export MPTDC_O10_2_MODE="$RUN_MODE"
export O1_RO_LEF_PATH="$RO_LEF"
export O1_RO_LIBERTY_PATH="$RO_LIB"
export PDK_ROOT="$PDK_ROOT"
export SC_ROOT="$SC_ROOT"
export TECHNOLOGY_LEF="$TECH_LEF"
export MPTDC_STDCELL_FAMILY="$STDCELL_FAMILY"
export MPTDC_O10_STDCELL_LEF="$STD_LEF"
export MPTDC_O10_STDCELL_TYP_LIB="$STD_TC_LIB"
export MPTDC_O10_STDCELL_SITE="$STDCELL_SITE"
export MPTDC_PNR_CORE_UTIL="${MPTDC_PNR_CORE_UTIL:-0.60}"
export MPTDC_PNR_MAX_DENSITY="${MPTDC_PNR_MAX_DENSITY:-0.70}"
export MPTDC_PNR_OSC_WIDTH_UM="${MPTDC_PNR_OSC_WIDTH_UM:-${ro_size_w:-176.675}}"
export MPTDC_PNR_OSC_HEIGHT_UM="${MPTDC_PNR_OSC_HEIGHT_UM:-${ro_size_h:-67.17}}"
export MPTDC_PNR_OSC_ORIGIN_X_UM="${MPTDC_PNR_OSC_ORIGIN_X_UM:-${ro_origin_x:-0}}"
export MPTDC_PNR_OSC_ORIGIN_Y_UM="${MPTDC_PNR_OSC_ORIGIN_Y_UM:-${ro_origin_y:-0}}"

if [[ "$RUN_MODE" == "place_only" ]]; then
  export MPTDC_O10_STOP_AFTER="place"
fi

run_tcl_source_check() {
  if ! command -v tclsh >/dev/null 2>&1; then
    echo "WARN: tclsh not found; skipping Tcl source check" | tee -a "$RUN_LOG"
    return 0
  fi
  (
    cd "$REPO_ROOT"
    MPTDC_O10_SOURCE_ONLY=1 tclsh <<'EOF'
source MPTDC/pnr/scripts/innovus_o10_2_init.tcl
source MPTDC/pnr/scripts/innovus_o10_2_screenshots.tcl
source MPTDC/pnr/scripts/innovus_o10_2_reports.tcl
source MPTDC/pnr/scripts/innovus_o10_2_cts.tcl
source MPTDC/pnr/scripts/innovus_o10_2_phase_net_reports.tcl
source MPTDC/pnr/scripts/report_pd_instance_symmetry.tcl
set p1 [mptdc_o10_classify_phase_net_name {u_core/slow_phase[0]}]
set p2 [mptdc_o10_classify_fast_tag_net_name {u_core/gen_fast_tag_col[3].u_fast_tag/tag_o[5]}]
if {[lindex $p1 0] ne "slow" || [lindex $p1 1] ne "0"} { error "phase-name classifier failed: $p1" }
if {[lindex $p2 0] ne "3" || [lindex $p2 1] ne "5"} { error "fast-tag classifier failed: $p2" }
puts "O10.2 Tcl source/classifier check passed"
EOF
  ) 2>&1 | tee -a "$RUN_LOG"
  return "${PIPESTATUS[0]}"
}

TCL_SOURCE_RC=0
if [[ "$INPUT_RC" == "0" ]]; then
  run_tcl_source_check
  TCL_SOURCE_RC=$?
  if [[ "$TCL_SOURCE_RC" != "0" ]]; then
    INPUT_RC=6
  fi
fi

INNOVUS_RC=0
if [[ "$INPUT_RC" != "0" ]]; then
  INNOVUS_RC="$INPUT_RC"
elif [[ "$RUN_MODE" == "validate_only" ]]; then
  echo "MPTDC_O10_2_MODE=validate_only: input and Tcl validation passed; Innovus not launched." | tee -a "$RUN_LOG"
  INNOVUS_RC=0
elif ! command -v innovus >/dev/null 2>&1; then
  echo "ERROR: innovus not found in PATH; run this on the lab server." | tee -a "$RUN_LOG"
  INNOVUS_RC=127
elif [[ "$RUN_MODE" == "gui_screenshot" ]]; then
  (
    cd "$SCRIPT_DIR"
    innovus -gui -init innovus_o10_2_gui_screenshot_export.tcl -log "$LOG_DIR/innovus_o10_2_gui.log"
  ) 2>&1 | tee -a "$RUN_LOG"
  INNOVUS_RC=${PIPESTATUS[0]}
else
  (
    cd "$SCRIPT_DIR"
    innovus -nowin -init innovus_o10_2_init.tcl -log "$LOG_DIR/innovus_o10_2.log"
  ) 2>&1 | tee -a "$RUN_LOG"
  INNOVUS_RC=${PIPESTATUS[0]}
fi

REQUIRED_RC=0
REPORT_COMPLETE="YES"
INVALID_REQUIRED=()
require_output_nonempty() {
  local label="$1"
  local rel="$2"
  if [[ ! -s "$RESULT_DIR/$rel" ]]; then
    INVALID_REQUIRED+=("$label: missing or empty: $rel")
    REQUIRED_RC=9
    REPORT_COMPLETE="NO"
  fi
}

require_output_no_error_marker() {
  local label="$1"
  local rel="$2"
  require_output_nonempty "$label" "$rel"
  if [[ -s "$RESULT_DIR/$rel" ]] && grep -Eq '(^ERROR,|^FAILED:|REPORT_STATUS=FAILED|REPORT_STATUS=INVALID|FAILED$|ERROR$)' "$RESULT_DIR/$rel"; then
    INVALID_REQUIRED+=("$label: invalid marker found: $rel")
    REQUIRED_RC=9
    REPORT_COMPLETE="NO"
  fi
}

validate_required_outputs() {
  local full_route="$1"
  require_output_no_error_marker "final report summary" "reports/SUMMARY.md"
  require_output_no_error_marker "manager summary" "manager/MANAGER_SUMMARY.md"
  require_output_no_error_marker "clock report" "reports/report_clocks.rpt"
  require_output_no_error_marker "phase net loads" "reports/phase_net_loads.csv"
  require_output_no_error_marker "phase net balance summary" "reports/phase_net_balance_summary.md"
  require_output_no_error_marker "fast tag loads" "reports/fast_tag_loads.csv"
  require_output_no_error_marker "fast tag balance summary" "reports/fast_tag_load_balance_summary.md"
  require_output_no_error_marker "PD instance placement" "reports/pd_instance_placement.csv"
  require_output_no_error_marker "PD symmetry summary" "reports/pd_symmetry_summary.md"
  require_output_no_error_marker "CTS status" "reports/cts_status.rpt"
  require_output_no_error_marker "max transition DRV" "reports/drv_max_transition.rpt"
  require_output_no_error_marker "max cap DRV" "reports/drv_max_cap.rpt"
  require_output_no_error_marker "max fanout DRV" "reports/drv_max_fanout.rpt"
  require_output_no_error_marker "timing class summary" "reports/timing_post_route_summary_by_class.md"
  require_output_no_error_marker "core internal timing" "reports/timing_post_route_core_internal.rpt"
  require_output_no_error_marker "IO output timing" "reports/timing_post_route_io_output.rpt"
  require_output_no_error_marker "reset recovery timing" "reports/timing_post_route_reset_recovery.rpt"
  require_output_no_error_marker "RO oscillator-domain timing" "reports/timing_post_route_ro_osc_domain.rpt"
  require_output_no_error_marker "clk_sys internal timing" "reports/timing_post_route_clk_sys_internal.rpt"
  require_output_no_error_marker "reset recovery summary" "reports/reset_recovery_summary.md"
  require_output_nonempty "restore script" "checkpoints/restore_latest.tcl"

  if [[ "$full_route" == "1" ]]; then
    require_output_nonempty "post-route timing" "reports/timing_post_route.rpt"
    require_output_no_error_marker "congestion" "reports/congestion.rpt"
    require_output_no_error_marker "route summary" "reports/route_summary.rpt"
    require_output_nonempty "route DEF" "def/04_route.def"
  else
    require_output_nonempty "placement DEF" "def/02_place.def"
  fi

  screenshot_ok=0
  if find "$RESULT_DIR/screenshots" -maxdepth 1 -name '*.png' -type f -size +0c | grep -q .; then
    screenshot_ok=1
  fi
  if [[ -s "$RESULT_DIR/screenshots/SCREENSHOT_EXPORT_FAILED.txt" && -s "$RESULT_DIR/manager/GUI_SCREENSHOT_INSTRUCTIONS.md" ]]; then
    screenshot_ok=1
  fi
  if [[ "$screenshot_ok" != "1" ]]; then
    INVALID_REQUIRED+=("screenshot status: need nonempty PNG or SCREENSHOT_EXPORT_FAILED.txt plus GUI instructions")
    REQUIRED_RC=9
    REPORT_COMPLETE="NO"
  fi
}

if [[ "$INNOVUS_RC" == "0" || "$INNOVUS_RC" == "139" ]]; then
  case "$RUN_MODE" in
    route_feasibility) validate_required_outputs 1 ;;
    place_only) validate_required_outputs 0 ;;
    gui_screenshot)
      if ! find "$RESULT_DIR/screenshots" -maxdepth 1 -name '*.png' -type f -size +0c | grep -q .; then
        INVALID_REQUIRED+=("gui screenshots: no nonempty PNG exported")
        REQUIRED_RC=9
        REPORT_COMPLETE="NO"
      fi
      ;;
    validate_only) ;;
  esac
fi

CRASH_STAGE="not_applicable"
INNOVUS_EXIT_CLASS="CLEAN_OR_NON_139"
if [[ -s "$RESULT_DIR/manifests/current_stage.txt" ]]; then
  CRASH_STAGE="$(tr '\n' ';' < "$RESULT_DIR/manifests/current_stage.txt")"
fi
if [[ "$INNOVUS_RC" == "139" ]]; then
  if [[ "$REQUIRED_RC" == "0" ]]; then
    INNOVUS_EXIT_CLASS="POST_REPORT_TOOL_EXIT_139"
  else
    INNOVUS_EXIT_CLASS="INNOVUS_EXIT_139_BEFORE_REQUIRED_OUTPUTS"
  fi
  {
    echo "INNOVUS_EXIT_139"
    echo "exit_class=$INNOVUS_EXIT_CLASS"
    echo "last_stage=$CRASH_STAGE"
    echo "required_outputs_exit_code=$REQUIRED_RC"
  } > "$RESULT_DIR/manifests/innovus_exit_classification.txt"
fi

if [[ "$REQUIRED_RC" != "0" ]]; then
  {
    echo "O10.2 required outputs/content check failed"
    echo "=========================================="
    printf '%s\n' "${INVALID_REQUIRED[@]}"
  } > "$RESULT_DIR/REQUIRED_OUTPUTS_CHECK_FAILED.txt"
  printf 'REQUIRED OUTPUT INVALID: %s\n' "${INVALID_REQUIRED[@]}" | tee -a "$RUN_LOG"
fi

WRAPPER_RC="$INNOVUS_RC"
if [[ "$WRAPPER_RC" == "0" && "$REQUIRED_RC" != "0" ]]; then
  WRAPPER_RC="$REQUIRED_RC"
fi

echo "[SNAPSHOT] Collecting O10.2 snapshot into $SNAPSHOT_DIR" | tee -a "$RUN_LOG"
mkdir -p "$SNAPSHOT_DIR"
if [[ -d "$RESULT_DIR" ]]; then
  cp -a "$RESULT_DIR"/manifests "$SNAPSHOT_DIR/" 2>/dev/null || true
  cp -a "$RESULT_DIR"/reports "$SNAPSHOT_DIR/" 2>/dev/null || true
  cp -a "$RESULT_DIR"/screenshots "$SNAPSHOT_DIR/" 2>/dev/null || true
  cp -a "$RESULT_DIR"/manager "$SNAPSHOT_DIR/" 2>/dev/null || true
  mkdir -p "$SNAPSHOT_DIR/logs"
  cp "$RUN_LOG" "$SNAPSHOT_DIR/logs/" 2>/dev/null || true
fi

{
  echo "# O10.2 Innovus PNR Constraint/Report/CTS Repair Summary"
  echo
  echo "- Run ID: \`$RUN_ID\`"
  echo "- Run mode: \`$RUN_MODE\`"
  echo "- Git HEAD: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)\`"
  echo "- Innovus exit code: $INNOVUS_RC"
  echo "- Innovus exit class: \`$INNOVUS_EXIT_CLASS\`"
  echo "- Last recorded Innovus stage: \`$CRASH_STAGE\`"
  echo "- Required outputs exit code: $REQUIRED_RC"
  echo "- Wrapper exit code: $WRAPPER_RC"
  echo "- REPORT_COMPLETE: \`$REPORT_COMPLETE\`"
  echo "- Result directory: \`results/innovus/$RUN_ID\`"
  echo "- Snapshot directory: \`MPTDC/lab_snapshots/$SNAPSHOT_TAG\`"
  echo "- Labels: \`O10_2_PNR_CONSTRAINT_REPORT_CTS_REPAIR\`, \`O10_INNOVUS_TYPICAL_FEASIBILITY\`, \`NOT_MMMC_SIGNOFF\`, \`NOT_FINAL_SIGNOFF\`, \`NOT_TAPEOUT_READY\`"
  echo
  echo "## Key Outputs"
  for path in \
    reports/SUMMARY.md \
    manager/MANAGER_SUMMARY.md \
    manager/GUI_SCREENSHOT_INSTRUCTIONS.md \
    reports/report_clocks.rpt \
    reports/timing_post_route.rpt \
    reports/timing_post_route_summary_by_class.md \
    reports/timing_post_route_core_internal.rpt \
    reports/timing_post_route_io_output.rpt \
    reports/timing_post_route_reset_recovery.rpt \
    reports/timing_post_route_ro_osc_domain.rpt \
    reports/timing_post_route_clk_sys_internal.rpt \
    reports/reset_recovery_summary.md \
    reports/drv_max_transition.rpt \
    reports/drv_max_cap.rpt \
    reports/drv_max_fanout.rpt \
    reports/phase_net_loads.csv \
    reports/phase_net_balance_summary.md \
    reports/fast_tag_loads.csv \
    reports/fast_tag_load_balance_summary.md \
    reports/pd_instance_placement.csv \
    reports/pd_symmetry_summary.md \
    reports/cts_status.rpt \
    reports/congestion.rpt \
    reports/route_summary.rpt \
    def/04_route.def \
    checkpoints/restore_latest.tcl \
    screenshots/SCREENSHOT_EXPORT_FAILED.txt; do
    if [[ -s "$RESULT_DIR/$path" ]]; then
      echo "- present: \`$path\`"
    else
      echo "- missing: \`$path\`"
    fi
  done
  png_count="$(find "$RESULT_DIR/screenshots" -maxdepth 1 -name '*.png' -type f -size +0c 2>/dev/null | wc -l | tr -d ' ')"
  echo "- screenshot PNG count: $png_count"
  if [[ -s "$RESULT_DIR/REQUIRED_OUTPUTS_CHECK_FAILED.txt" ]]; then
    echo
    echo "## Invalid Required Outputs"
    sed 's/^/- /' "$RESULT_DIR/REQUIRED_OUTPUTS_CHECK_FAILED.txt"
  fi
} > "$RESULT_DIR/SUMMARY.md"

cat "$RESULT_DIR/SUMMARY.md"

exit "$WRAPPER_RC"
