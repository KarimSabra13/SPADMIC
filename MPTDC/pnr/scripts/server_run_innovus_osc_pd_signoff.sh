#!/usr/bin/env bash
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$PNR_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"
SYN_DIR="$MPTDC_DIR/syn"

RUN_ID="${1:-$(date +%Y%m%d_%H%M%S)_osc_pd_innovus}"
SNAPSHOT_TAG="innovus_osc_pd_${RUN_ID}"
RESULT_DIR="$REPO_ROOT/results/osc_pd/$RUN_ID"
SNAPSHOT_DIR="$MPTDC_DIR/lab_snapshots/$SNAPSHOT_TAG"
INNOVUS_LOG="$RESULT_DIR/innovus_${RUN_ID}.log"
OVERLAY_SDC="$SYN_DIR/inputs/mptdc_osc_pd_physical.sdc"

mkdir -p "$RESULT_DIR" "$PNR_DIR/logs"

{
  echo "Run ID: $RUN_ID"
  echo "Snapshot tag: $SNAPSHOT_TAG"
  echo "Date: $(date -Iseconds)"
  echo "Repository root: $REPO_ROOT"
  echo "Branch: $(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || true)"
  echo "HEAD: $(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)"
  echo
  echo "git status --short:"
  git -C "$REPO_ROOT" status --short 2>/dev/null || true
} | tee "$RESULT_DIR/run_manifest.txt"

python3 "$REPO_ROOT/tools/osc/gen_osc_macro_views.py" \
  --template "$REPO_ROOT/tools/osc/oscillator_macro_template.yaml" \
  --out-dir "$SYN_DIR/macros" >> "$INNOVUS_LOG" 2>&1 || GEN_MACRO_RC=$?
GEN_MACRO_RC="${GEN_MACRO_RC:-0}"

for required in \
  "$SYN_DIR/outputs/mptdc_axis_core.postsyn.v" \
  "$SYN_DIR/outputs/mptdc_axis_core.postsyn.sdc" \
  "$OVERLAY_SDC" \
  "$SYN_DIR/macros/mptdc_osc_slow_provisional.lef" \
  "$SYN_DIR/macros/mptdc_osc_fast_provisional.lef" \
  "$SYN_DIR/macros/mptdc_osc_slow_provisional.lib" \
  "$SYN_DIR/macros/mptdc_osc_fast_provisional.lib"; do
  if [[ ! -f "$required" ]]; then
    echo "ERROR: missing required O0 input: $required" | tee -a "$INNOVUS_LOG"
    MISSING_INPUT=1
  fi
done
MISSING_INPUT="${MISSING_INPUT:-0}"

export MPTDC_OSC_PD_USE_PROVISIONAL=1
export MPTDC_OSC_PD_SDC_OVERLAY="$OVERLAY_SDC"
export MPTDC_OSC_PD_ENABLE=1
export MPTDC_OSC_PD_RESULT_DIR="$RESULT_DIR"
export MPTDC_PNR_DO_DETAIL_ROUTE="${MPTDC_PNR_DO_DETAIL_ROUTE:-1}"

if [[ "$MISSING_INPUT" != "0" ]]; then
  INNOVUS_RC=2
elif ! command -v innovus >/dev/null 2>&1; then
  {
    echo "ERROR: innovus not found in PATH."
    echo "This script must be run on the lab server with Cadence Innovus available."
  } | tee -a "$INNOVUS_LOG"
  INNOVUS_RC=127
else
  echo "[INNOVUS_O0] Starting oscillator/PD provisional physical signoff flow" | tee -a "$INNOVUS_LOG"
  (
    cd "$SCRIPT_DIR"
    innovus -nowin -init innovus_estimate.tcl -log ../logs/innovus_osc_pd.log
  ) 2>&1 | tee -a "$INNOVUS_LOG"
  INNOVUS_RC=${PIPESTATUS[0]}
fi

echo "[SNAPSHOT] Collecting Innovus O0 snapshot into $SNAPSHOT_DIR" | tee -a "$INNOVUS_LOG"
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
copy_if_present "$PNR_DIR/reports/postroute/mptdc_axis_core_postRoute.summary" "$RESULT_DIR/timing_postRoute.rpt"
copy_if_present "$PNR_DIR/reports/postroute/mptdc_axis_core_postRoute.hold.summary" "$RESULT_DIR/top100_hold_paths.rpt"
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
  echo "# Innovus O0 Oscillator/PD Server Run Summary"
  echo
  echo "- Run ID: \`$RUN_ID\`"
  echo "- Git HEAD: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)\`"
  echo "- Innovus exit code: $INNOVUS_RC"
  echo "- Snapshot exit code: ${SNAPSHOT_RC:-0}"
  echo "- Macro generation exit code: $GEN_MACRO_RC"
  echo "- Detail route requested: ${MPTDC_PNR_DO_DETAIL_ROUTE:-1}"
  echo "- Result directory: \`results/osc_pd/$RUN_ID/\`"
  echo
  echo "## Key Files"
  echo
  for file in \
    "innovus_${RUN_ID}.log" \
    floorplan_summary.rpt \
    macro_placement.rpt \
    pd_instance_placement.csv \
    pd_instance_symmetry_summary.md \
    phase_net_rc.csv \
    phase_net_balance_summary.md \
    phase_net_balance_heatmap_slow.csv \
    phase_net_balance_heatmap_fast.csv \
    tap_loads.csv \
    tap_load_balance_summary.md \
    nfast_count_bus_rc.csv \
    nfast_count_bus_summary.md \
    timing_preCTS.rpt \
    timing_postCTS.rpt \
    timing_postRoute.rpt \
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
  echo
  echo "## Status"
  echo
  echo "PROVISIONAL PHYSICAL CLOSURE ONLY - not oscillator/PD signoff."
} > "$RESULT_DIR/SUMMARY.md"

cat "$RESULT_DIR/SUMMARY.md"

if [[ $INNOVUS_RC -ne 0 ]]; then
  exit "$INNOVUS_RC"
fi
if [[ ${SNAPSHOT_RC:-0} -ne 0 ]]; then
  exit "$SNAPSHOT_RC"
fi
exit 0
