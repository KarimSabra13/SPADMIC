#!/usr/bin/env bash
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$PNR_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

RUN_ID="${1:-20260604_o10_1_innovus_repair}"
RESULT_DIR="$REPO_ROOT/results/innovus/$RUN_ID"
SNAPSHOT_TAG="innovus_o10_1_innovus_repair_${RUN_ID}"
SNAPSHOT_DIR="$MPTDC_DIR/lab_snapshots/$SNAPSHOT_TAG"
LOG_DIR="$RESULT_DIR/logs"
RUN_LOG="$LOG_DIR/innovus_${RUN_ID}.log"

O9_DIR="$REPO_ROOT/results/genus_osc_pd/20260604_o9_final_typical_r750_delta5"
NETLIST="${MPTDC_O10_NETLIST:-$O9_DIR/mptdc_axis_core.postsyn.v}"
POSTSYN_SDC="${MPTDC_O10_POSTSYN_SDC:-$O9_DIR/mptdc_axis_core.postsyn.sdc}"
OVERLAY_SDC="${MPTDC_O10_SDC_OVERLAY:-$MPTDC_DIR/pnr/constraints/mptdc_osc_typical_r750_delta5_innovus.sdc}"
RO_LEF="${O1_RO_LEF_PATH:-$REPO_ROOT/results/osc_pd/20260528_o1_export_ro_tune4_lef/real_abstract_lef/RO_tune4_real_abstract.lef}"
RO_LIB="${O1_RO_LIBERTY_PATH:-$MPTDC_DIR/syn/macros/RO_tune4_real_abstract_shell.lib}"
PDK_ROOT="${PDK_ROOT:-/data/pdk/xfab/xh018}"
SC_ROOT="${SC_ROOT:-$PDK_ROOT/diglibs/D_CELLS_HD/v6_0}"
TECH_LEF="${TECHNOLOGY_LEF:-$PDK_ROOT/cadence/v9_0/techLEF/v9_0_1/xh018_xx41_HD_MET4_METMID.lef}"
STD_LEF="${MPTDC_O10_STDCELL_LEF:-$SC_ROOT/LEF/v6_0_0/xh018_D_CELLS_HD.lef}"
STD_TC_LIB="${MPTDC_O10_STDCELL_TYP_LIB:-$SC_ROOT/liberty_LPMOS/v6_0_0/PVT_1_80V_range/D_CELLS_HD_LPMOS_typ_1_80V_25C.lib}"
POWER_NETS="${MPTDC_O10_POWER_NETS:-VDD VSS}"

mkdir -p "$LOG_DIR" "$RESULT_DIR/manifests" "$RESULT_DIR/reports" "$RESULT_DIR/screenshots" "$RESULT_DIR/manager"

{
  echo "# O10.1 Innovus Flow Repair Run"
  echo "date: $(date -Iseconds)"
  echo "repo: $REPO_ROOT"
  echo "branch: $(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || true)"
  echo "head: $(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)"
  echo "expected_head: ${EXPECTED_HEAD:-unset}"
  echo "run_id: $RUN_ID"
  echo "snapshot_tag: $SNAPSHOT_TAG"
  echo "labels: O10_1_INNOVUS_FLOW_REPAIR O10_INNOVUS_TYPICAL_FEASIBILITY NOT_MMMC_SIGNOFF NOT_FINAL_SIGNOFF NOT_TAPEOUT_READY"
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

require_file "O9 netlist" "$NETLIST"
require_file "O9 post-synth SDC" "$POSTSYN_SDC"
require_file "O10.1 Innovus-safe R750 overlay SDC" "$OVERLAY_SDC"
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
export O1_RO_LEF_PATH="$RO_LEF"
export O1_RO_LIBERTY_PATH="$RO_LIB"
export PDK_ROOT="$PDK_ROOT"
export SC_ROOT="$SC_ROOT"
export TECHNOLOGY_LEF="$TECH_LEF"
export MPTDC_PNR_CORE_UTIL="${MPTDC_PNR_CORE_UTIL:-0.60}"
export MPTDC_PNR_MAX_DENSITY="${MPTDC_PNR_MAX_DENSITY:-0.70}"
export MPTDC_PNR_OSC_WIDTH_UM="${MPTDC_PNR_OSC_WIDTH_UM:-176.675}"
export MPTDC_PNR_OSC_HEIGHT_UM="${MPTDC_PNR_OSC_HEIGHT_UM:-67.17}"

INNOVUS_RC=0
if [[ "$INPUT_RC" != "0" ]]; then
  INNOVUS_RC="$INPUT_RC"
elif [[ "${MPTDC_O10_VALIDATE_ONLY:-0}" == "1" ]]; then
  echo "MPTDC_O10_VALIDATE_ONLY=1: input validation passed; Innovus not launched." | tee -a "$RUN_LOG"
  INNOVUS_RC=0
elif ! command -v innovus >/dev/null 2>&1; then
  echo "ERROR: innovus not found in PATH; run this on the lab server." | tee -a "$RUN_LOG"
  INNOVUS_RC=127
else
  (
    cd "$SCRIPT_DIR"
    innovus -nowin -init innovus_o10_1_init.tcl -log "$LOG_DIR/innovus_o10_1.log"
  ) 2>&1 | tee -a "$RUN_LOG"
  INNOVUS_RC=${PIPESTATUS[0]}
fi

REQUIRED_RC=0
MISSING_REQUIRED=()
require_output_nonempty() {
  local label="$1"
  local rel="$2"
  if [[ ! -s "$RESULT_DIR/$rel" ]]; then
    MISSING_REQUIRED+=("$label: $rel")
    REQUIRED_RC=9
  fi
}

if [[ "$INNOVUS_RC" == "0" && "${MPTDC_O10_VALIDATE_ONLY:-0}" != "1" ]]; then
  require_output_nonempty "final report summary" "reports/SUMMARY.md"
  require_output_nonempty "manager summary" "manager/MANAGER_SUMMARY.md"
  require_output_nonempty "phase net loads" "reports/phase_net_loads.csv"
  require_output_nonempty "fast tag loads" "reports/fast_tag_loads.csv"
  require_output_nonempty "PD instance placement" "reports/pd_instance_placement.csv"
  require_output_nonempty "PD symmetry summary" "reports/pd_symmetry_summary.md"
  require_output_nonempty "post-route timing" "reports/timing_post_route.rpt"
  require_output_nonempty "max transition DRV" "reports/drv_max_transition.rpt"
  require_output_nonempty "route summary" "reports/route_summary.rpt"
  require_output_nonempty "floorplan DEF" "def/01_floorplan.def"
  require_output_nonempty "placement DEF" "def/02_place.def"
  require_output_nonempty "route DEF" "def/04_route.def"
  require_output_nonempty "restore script" "checkpoints/restore_latest.tcl"

  screenshot_ok=0
  if find "$RESULT_DIR/screenshots" -maxdepth 1 -name '*.png' -type f -size +0c | grep -q .; then
    screenshot_ok=1
  fi
  if [[ -s "$RESULT_DIR/screenshots/SCREENSHOT_EXPORT_FAILED.txt" ]]; then
    screenshot_ok=1
  fi
  if [[ "$screenshot_ok" != "1" ]]; then
    MISSING_REQUIRED+=("screenshot status: nonempty PNG or SCREENSHOT_EXPORT_FAILED.txt")
    REQUIRED_RC=9
  fi
fi

if [[ "$REQUIRED_RC" != "0" ]]; then
  {
    echo "O10.1 required outputs check failed"
    echo "==================================="
    printf '%s\n' "${MISSING_REQUIRED[@]}"
  } > "$RESULT_DIR/REQUIRED_OUTPUTS_CHECK_FAILED.txt"
  printf 'REQUIRED OUTPUT MISSING: %s\n' "${MISSING_REQUIRED[@]}" | tee -a "$RUN_LOG"
fi

WRAPPER_RC="$INNOVUS_RC"
if [[ "$WRAPPER_RC" == "0" && "$REQUIRED_RC" != "0" ]]; then
  WRAPPER_RC="$REQUIRED_RC"
fi

echo "[SNAPSHOT] Collecting O10.1 snapshot into $SNAPSHOT_DIR" | tee -a "$RUN_LOG"
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
  echo "# O10.1 Innovus Flow Repair Summary"
  echo
  echo "- Run ID: \`$RUN_ID\`"
  echo "- Git HEAD: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)\`"
  echo "- Innovus exit code: $INNOVUS_RC"
  echo "- Required outputs exit code: $REQUIRED_RC"
  echo "- Wrapper exit code: $WRAPPER_RC"
  echo "- Result directory: \`results/innovus/$RUN_ID\`"
  echo "- Snapshot directory: \`MPTDC/lab_snapshots/$SNAPSHOT_TAG\`"
  echo "- Labels: \`O10_1_INNOVUS_FLOW_REPAIR\`, \`O10_INNOVUS_TYPICAL_FEASIBILITY\`, \`NOT_MMMC_SIGNOFF\`, \`NOT_FINAL_SIGNOFF\`, \`NOT_TAPEOUT_READY\`"
  echo
  echo "## Key Outputs"
  for path in \
    reports/SUMMARY.md \
    manager/MANAGER_SUMMARY.md \
    reports/phase_net_loads.csv \
    reports/fast_tag_loads.csv \
    reports/pd_instance_placement.csv \
    reports/pd_symmetry_summary.md \
    reports/timing_post_route.rpt \
    reports/drv_max_transition.rpt \
    reports/route_summary.rpt \
    def/01_floorplan.def \
    def/02_place.def \
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
    echo "## Missing Required Outputs"
    sed 's/^/- /' "$RESULT_DIR/REQUIRED_OUTPUTS_CHECK_FAILED.txt"
  fi
} > "$RESULT_DIR/SUMMARY.md"

cat "$RESULT_DIR/SUMMARY.md"

exit "$WRAPPER_RC"
