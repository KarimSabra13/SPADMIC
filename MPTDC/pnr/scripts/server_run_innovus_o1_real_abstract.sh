#!/usr/bin/env bash
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$PNR_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"
SYN_DIR="$MPTDC_DIR/syn"

RUN_ID="${1:-$(date +%Y%m%d_%H%M%S)_o1_real_abstract_innovus}"
SNAPSHOT_TAG="innovus_osc_pd_${RUN_ID}"
RESULT_DIR="$REPO_ROOT/results/osc_pd/$RUN_ID"
SNAPSHOT_DIR="$MPTDC_DIR/lab_snapshots/$SNAPSHOT_TAG"
INNOVUS_LOG="$RESULT_DIR/innovus_${RUN_ID}.log"
ENV_FILE="$MPTDC_DIR/analog_handoff/real_ro_tune4_abstract.env"
EXPORT_RUN_ID="${O1_RO_EXPORT_RUN_ID:-20260528_o1_export_ro_tune4_lef}"
DEFAULT_REAL_LEF="$REPO_ROOT/results/osc_pd/$EXPORT_RUN_ID/real_abstract_lef/RO_tune4_real_abstract.lef"
OVERLAY_SDC="${MPTDC_OSC_PD_SDC_OVERLAY:-$SYN_DIR/inputs/mptdc_osc_pd_physical.sdc}"
RUN_FLAVOR="${O1_RUN_FLAVOR:-O1A_REAL_ABSTRACT_NOMINAL}"
O1_RO_CELL_NAME="${O1_RO_CELL_NAME:-RO_tune4}"

mkdir -p "$RESULT_DIR" "$PNR_DIR/logs"

{
  echo "Run ID: $RUN_ID"
  echo "Snapshot tag: $SNAPSHOT_TAG"
  echo "Flavor: $RUN_FLAVOR"
  echo "Date: $(date -Iseconds)"
  echo "Repository root: $REPO_ROOT"
  echo "Branch: $(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || true)"
  echo "HEAD: $(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)"
  echo
  echo "git status --short:"
  git -C "$REPO_ROOT" status --short 2>/dev/null || true
} | tee "$RESULT_DIR/run_manifest.txt" | tee "$INNOVUS_LOG"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: missing O1 env file: $ENV_FILE" | tee -a "$INNOVUS_LOG"
  INPUT_RC=2
else
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  export O1_RO_LEF_PATH="${O1_RO_LEF_PATH:-$DEFAULT_REAL_LEF}"
  INPUT_RC=0
fi

macro_name=""
if [[ ${INPUT_RC:-0} -eq 0 ]]; then
  if [[ ! -f "$O1_RO_LEF_PATH" ]]; then
    echo "ERROR: missing real RO_tune4 LEF: $O1_RO_LEF_PATH" | tee -a "$INNOVUS_LOG"
    INPUT_RC=2
  else
    macro_name="$(awk '
      /^[[:space:]]*PROPERTYDEFINITIONS[[:space:]]*$/ {inprop=1; next}
      inprop && /^[[:space:]]*END[[:space:]]+PROPERTYDEFINITIONS[[:space:]]*$/ {inprop=0; next}
      inprop {next}
      /^[[:space:]]*MACRO[[:space:]]+[^[:space:];]+[[:space:]]*$/ {print $2; exit}
    ' "$O1_RO_LEF_PATH")"
    echo "O1 real LEF: $O1_RO_LEF_PATH" | tee -a "$INNOVUS_LOG"
    echo "O1 real LEF macro: $macro_name" | tee -a "$INNOVUS_LOG"
    if [[ "$macro_name" != "$O1_RO_CELL_NAME" ]]; then
      echo "ERROR: LEF macro '$macro_name' does not match expected '$O1_RO_CELL_NAME'" | tee -a "$INNOVUS_LOG"
      INPUT_RC=3
    fi
  fi
fi

POSTSYN_NETLIST="$SYN_DIR/outputs/mptdc_top_asic.postsyn.v"
BINDING_STATUS="UNKNOWN"
if [[ -f "$POSTSYN_NETLIST" ]]; then
  if grep -q "$O1_RO_CELL_NAME" "$POSTSYN_NETLIST"; then
    BINDING_STATUS="BOUND_TO_${O1_RO_CELL_NAME}"
  elif grep -q "mptdc_osc_stub" "$POSTSYN_NETLIST"; then
    BINDING_STATUS="NOT_BOUND_STILL_MPTDC_OSC_STUB"
  else
    BINDING_STATUS="NOT_BOUND_NO_${O1_RO_CELL_NAME}_FOUND"
  fi
else
  BINDING_STATUS="NO_POSTSYN_NETLIST"
fi

python3 "$REPO_ROOT/tools/osc/gen_osc_macro_views.py" \
  --template "$REPO_ROOT/tools/osc/oscillator_macro_template.yaml" \
  --out-dir "$SYN_DIR/macros" >> "$INNOVUS_LOG" 2>&1 || GEN_MACRO_RC=$?
GEN_MACRO_RC="${GEN_MACRO_RC:-0}"

for required in \
  "$SYN_DIR/outputs/mptdc_top_asic.postsyn.v" \
  "$SYN_DIR/outputs/mptdc_top_asic.postsyn.sdc" \
  "$OVERLAY_SDC" \
  "$SYN_DIR/macros/mptdc_osc_slow_provisional.lib" \
  "$SYN_DIR/macros/mptdc_osc_fast_provisional.lib"; do
  if [[ ! -f "$required" ]]; then
    echo "ERROR: missing required O1 input: $required" | tee -a "$INNOVUS_LOG"
    INPUT_RC=2
  fi
done
INPUT_RC="${INPUT_RC:-0}"

export O1_USE_REAL_RO_ABSTRACT=1
export MPTDC_OSC_PD_USE_PROVISIONAL=0
export MPTDC_OSC_PD_USE_PROVISIONAL_LIBERTY=1
export MPTDC_OSC_PD_SDC_OVERLAY="$OVERLAY_SDC"
export MPTDC_OSC_PD_ENABLE=1
export MPTDC_OSC_PD_RESULT_DIR="$RESULT_DIR"
export MPTDC_PNR_DO_DETAIL_ROUTE="${MPTDC_PNR_DO_DETAIL_ROUTE:-1}"

if [[ "$INPUT_RC" != "0" ]]; then
  INNOVUS_RC="$INPUT_RC"
elif [[ "${O1_STRICT_REAL_MACRO_BINDING:-1}" == "1" && "$BINDING_STATUS" != BOUND_TO_* ]]; then
  echo "ERROR: current postsyn netlist does not bind to $O1_RO_CELL_NAME; refusing unbound O1A Innovus run" | tee -a "$INNOVUS_LOG"
  INNOVUS_RC=3
elif ! command -v innovus >/dev/null 2>&1; then
  {
    echo "ERROR: innovus not found in PATH."
    echo "This script must be run on the lab server with Cadence Innovus available."
  } | tee -a "$INNOVUS_LOG"
  INNOVUS_RC=127
else
  echo "[INNOVUS_O1] Starting $RUN_FLAVOR flow" | tee -a "$INNOVUS_LOG"
  (
    cd "$SCRIPT_DIR"
    innovus -nowin -init innovus_estimate.tcl -log ../logs/innovus_o1_real_abstract.log
  ) 2>&1 | tee -a "$INNOVUS_LOG"
  INNOVUS_RC=${PIPESTATUS[0]}
fi

echo "[SNAPSHOT] Collecting Innovus O1 snapshot into $SNAPSHOT_DIR" | tee -a "$INNOVUS_LOG"
if bash "$SCRIPT_DIR/collect_snapshot.sh" "$SNAPSHOT_TAG" >> "$INNOVUS_LOG" 2>&1; then
  SNAPSHOT_RC=0
else
  SNAPSHOT_RC=$?
  echo "WARNING: collect_snapshot.sh failed with rc=$SNAPSHOT_RC" | tee -a "$INNOVUS_LOG"
fi

copy_if_present() {
  local src="$1"
  local dst="$2"
  if [[ -f "$src" ]]; then
    cp "$src" "$dst"
  elif [[ ! -f "$dst" ]]; then
    {
      echo "$dst"
      echo "MISSING: source report was not produced: $src"
    } > "$dst"
  fi
}

copy_if_present "$PNR_DIR/reports/run_manifest.rpt" "$RESULT_DIR/placement_summary.rpt"
copy_if_present "$PNR_DIR/reports/prects/extra_report_congestion.rpt" "$RESULT_DIR/congestion.rpt"
copy_if_present "$PNR_DIR/reports/prects/extra_report_clocks.rpt" "$RESULT_DIR/clock_report.rpt"
copy_if_present "$PNR_DIR/reports/prects/extra_report_net_fanout.rpt" "$RESULT_DIR/drv_max_fanout.rpt"
copy_if_present "$PNR_DIR/reports/prects/extra_report_constraint.rpt" "$RESULT_DIR/drv_max_transition.rpt"
copy_if_present "$PNR_DIR/reports/prects/extra_report_constraint.rpt" "$RESULT_DIR/drv_max_cap.rpt"
copy_if_present "$PNR_DIR/reports/prects/extra_report_timing_100.rpt" "$RESULT_DIR/timing_preCTS.rpt"
copy_if_present "$PNR_DIR/reports/prects/extra_report_timing_full_clock.rpt" "$RESULT_DIR/top100_setup_paths.rpt"
copy_if_present "$PNR_DIR/reports/prects/extra_report_timing_100.rpt" "$RESULT_DIR/timing_postCTS.rpt"
copy_if_present "$PNR_DIR/reports/postroute/mptdc_top_asic_postRoute.summary" "$RESULT_DIR/timing_postRoute.rpt"
copy_if_present "$PNR_DIR/reports/postroute/mptdc_top_asic_postRoute.hold.summary" "$RESULT_DIR/top100_hold_paths.rpt"
copy_if_present "$PNR_DIR/reports/run_status.rpt" "$RESULT_DIR/route_summary.rpt"
copy_if_present "$PNR_DIR/reports/prects/extra_report_clocks.rpt" "$RESULT_DIR/report_clocks.rpt"
copy_if_present "$PNR_DIR/reports/prects/extra_report_constraint.rpt" "$RESULT_DIR/report_exceptions.rpt"
copy_if_present "$PNR_DIR/reports/prects/extra_report_constraint.rpt" "$RESULT_DIR/report_clock_groups.rpt"
cp "$INNOVUS_LOG" "$RESULT_DIR/innovus_${RUN_ID}.log" 2>/dev/null || true

if command -v python3 >/dev/null 2>&1; then
  if [[ -f "$RESULT_DIR/pd_instance_placement.csv" ]]; then
    python3 "$REPO_ROOT/tools/timing/analyze_pd_instance_symmetry.py" \
      "$RESULT_DIR/pd_instance_placement.csv" \
      --out "$RESULT_DIR/pd_instance_symmetry_summary.md" || true
  fi
  if [[ -f "$RESULT_DIR/phase_net_rc.csv" ]]; then
    python3 "$REPO_ROOT/tools/timing/analyze_pd_phase_routes.py" \
      "$RESULT_DIR/phase_net_rc.csv" \
      --out "$RESULT_DIR/phase_net_balance_summary.md" \
      --slow-heatmap "$RESULT_DIR/phase_net_balance_heatmap_slow.csv" \
      --fast-heatmap "$RESULT_DIR/phase_net_balance_heatmap_fast.csv" || true
  fi
  if [[ -f "$RESULT_DIR/tap_loads.csv" ]]; then
    python3 "$REPO_ROOT/tools/timing/analyze_osc_tap_loads.py" \
      "$RESULT_DIR/tap_loads.csv" \
      --nfast-csv "$RESULT_DIR/nfast_count_bus_rc.csv" \
      --out "$RESULT_DIR/tap_load_balance_summary.md" || true
    cp "$RESULT_DIR/tap_load_balance_summary.md" "$RESULT_DIR/nfast_count_bus_summary.md" 2>/dev/null || true
  fi
  reports=()
  for rpt in timing_preCTS.rpt timing_postCTS.rpt timing_postRoute.rpt top100_setup_paths.rpt top100_hold_paths.rpt; do
    [[ -f "$RESULT_DIR/$rpt" ]] && reports+=("$RESULT_DIR/$rpt")
  done
  if [[ ${#reports[@]} -gt 0 ]]; then
    python3 "$REPO_ROOT/tools/timing/classify_mptdc_timing_paths.py" "${reports[@]}" \
      --out-csv "$RESULT_DIR/timing_path_classification.csv" \
      --out-summary "$RESULT_DIR/timing_path_classification_summary.md" || true
  fi
fi

{
  echo "# Innovus O1 Real RO_tune4 Abstract Summary"
  echo
  echo "- Run ID: \`$RUN_ID\`"
  echo "- Flavor: \`$RUN_FLAVOR\`"
  echo "- Git HEAD: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)\`"
  echo "- Innovus exit code: $INNOVUS_RC"
  echo "- Snapshot exit code: ${SNAPSHOT_RC:-0}"
  echo "- Macro generation exit code: $GEN_MACRO_RC"
  echo "- Real LEF: \`${O1_RO_LEF_PATH:-unset}\`"
  echo "- Real LEF macro: \`${macro_name:-unknown}\`"
  echo "- SDC overlay: \`$OVERLAY_SDC\`"
  echo "- Provisional LEF enabled: no"
  echo "- Provisional Liberty shell enabled: yes"
  echo "- Macro binding status: \`$BINDING_STATUS\`"
  echo "- Result directory: \`results/osc_pd/$RUN_ID/\`"
  echo
  if [[ "$BINDING_STATUS" == BOUND_TO_* && $INNOVUS_RC -eq 0 ]]; then
    echo "O1A_REAL_ABSTRACT_BINDING=PASS"
    echo "STATUS_LABEL=REAL_PHYSICAL_ABSTRACT_WITH_PROVISIONAL_LIBERTY"
  else
    echo "O1A_REAL_ABSTRACT_BINDING=FAILED"
    echo "O1A_REAL_ABSTRACT_RUN_BLOCKED=YES"
    echo "REASON=real macro is not bound or Innovus failed"
    echo "STATUS_LABEL=PROVISIONAL_OR_UNBOUND"
  fi
  echo
  echo "## Key Files"
  for file in \
    "innovus_${RUN_ID}.log" \
    floorplan_summary.rpt \
    macro_placement.rpt \
    pd_instance_placement.csv \
    pd_instance_symmetry_summary.md \
    phase_net_rc.csv \
    phase_net_balance_summary.md \
    tap_loads.csv \
    tap_load_balance_summary.md \
    nfast_count_bus_rc.csv \
    nfast_count_bus_summary.md \
    timing_preCTS.rpt \
    timing_postCTS.rpt \
    timing_postRoute.rpt \
    top100_hold_paths.rpt \
    timing_path_classification.csv \
    timing_path_classification_summary.md \
    drv_max_transition.rpt \
    drv_max_cap.rpt \
    drv_max_fanout.rpt \
    clock_report.rpt \
    report_clocks.rpt \
    report_clock_groups.rpt \
    report_exceptions.rpt \
    congestion.rpt \
    route_summary.rpt \
    placement_summary.rpt; do
    if [[ -f "$RESULT_DIR/$file" ]]; then
      echo "- present: \`$file\`"
    else
      echo "- missing: \`$file\`"
    fi
  done
} > "$RESULT_DIR/SUMMARY.md"

cat "$RESULT_DIR/SUMMARY.md"

if [[ $INNOVUS_RC -ne 0 ]]; then
  exit "$INNOVUS_RC"
fi
if [[ ${SNAPSHOT_RC:-0} -ne 0 ]]; then
  exit "$SNAPSHOT_RC"
fi
exit 0
