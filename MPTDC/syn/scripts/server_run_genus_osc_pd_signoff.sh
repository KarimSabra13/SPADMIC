#!/usr/bin/env bash
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$SYN_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

RUN_ID="${1:-$(date +%Y%m%d_%H%M%S)_osc_pd_genus}"
SNAPSHOT_TAG="genus_osc_pd_${RUN_ID}"
RESULT_DIR="$REPO_ROOT/results/genus_osc_pd/$RUN_ID"
SNAPSHOT_DIR="$MPTDC_DIR/lab_snapshots/$SNAPSHOT_TAG"
GENUS_LOG="$RESULT_DIR/genus_${RUN_ID}.log"
OVERLAY_SDC="$SYN_DIR/inputs/mptdc_osc_pd_physical.sdc"

mkdir -p "$RESULT_DIR" "$SYN_DIR/logs"

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
  --out-dir "$SYN_DIR/macros" >> "$GENUS_LOG" 2>&1 || GEN_MACRO_RC=$?
GEN_MACRO_RC="${GEN_MACRO_RC:-0}"

for required in \
  "$OVERLAY_SDC" \
  "$SYN_DIR/macros/mptdc_osc_slow_provisional.lef" \
  "$SYN_DIR/macros/mptdc_osc_fast_provisional.lef" \
  "$SYN_DIR/macros/mptdc_osc_slow_provisional.lib" \
  "$SYN_DIR/macros/mptdc_osc_fast_provisional.lib"; do
  if [[ ! -f "$required" ]]; then
    echo "ERROR: missing required O0 input: $required" | tee -a "$GENUS_LOG"
    MISSING_INPUT=1
  fi
done
MISSING_INPUT="${MISSING_INPUT:-0}"

export MPTDC_OSC_PD_USE_PROVISIONAL=1
export MPTDC_OSC_PD_SDC_OVERLAY="$OVERLAY_SDC"

if [[ "$MISSING_INPUT" != "0" ]]; then
  GENUS_RC=2
elif ! command -v genus >/dev/null 2>&1; then
  {
    echo "ERROR: genus not found in PATH."
    echo "This script must be run on the lab server with Cadence Genus available."
  } | tee -a "$GENUS_LOG"
  GENUS_RC=127
else
  echo "[GENUS_O0] Starting oscillator/PD provisional synthesis/signoff flow" | tee -a "$GENUS_LOG"
  (
    cd "$SCRIPT_DIR"
    genus -files genus.tcl -log ../logs/genus_osc_pd.log
  ) 2>&1 | tee -a "$GENUS_LOG"
  GENUS_RC=${PIPESTATUS[0]}
fi

echo "[SNAPSHOT] Collecting Genus O0 snapshot into $SNAPSHOT_DIR" | tee -a "$GENUS_LOG"
if bash "$SCRIPT_DIR/collect_snapshot.sh" "$SNAPSHOT_TAG" >> "$GENUS_LOG" 2>&1; then
  SNAPSHOT_RC=0
else
  SNAPSHOT_RC=$?
  echo "WARNING: collect_snapshot.sh failed with rc=$SNAPSHOT_RC" | tee -a "$GENUS_LOG"
fi

if [[ -d "$SNAPSHOT_DIR" ]]; then
  cp -a "$SNAPSHOT_DIR/." "$RESULT_DIR/"
fi
cp "$GENUS_LOG" "$RESULT_DIR/genus_${RUN_ID}.log" 2>/dev/null || true

if command -v python3 >/dev/null 2>&1; then
  if [[ -f "$REPO_ROOT/tools/timing/parse_genus_summary.py" ]]; then
    python3 "$REPO_ROOT/tools/timing/parse_genus_summary.py" "$RESULT_DIR" \
      > "$RESULT_DIR/PARSED_SUMMARY.md" 2>/dev/null || true
  fi
  if [[ -f "$REPO_ROOT/tools/timing/classify_mptdc_timing_paths.py" ]]; then
    reports=()
    for rpt in \
      timing_violations.rpt \
      timing_osc_fast_full_clock.rpt \
      timing_pd_capture_hotspots.rpt \
      timing_osc_counter_hotspots.rpt \
      timing_clk_sys_violations.rpt; do
      [[ -f "$RESULT_DIR/$rpt" ]] && reports+=("$RESULT_DIR/$rpt")
    done
    if [[ ${#reports[@]} -gt 0 ]]; then
      python3 "$REPO_ROOT/tools/timing/classify_mptdc_timing_paths.py" "${reports[@]}" \
        --out-csv "$RESULT_DIR/timing_path_classification.csv" \
        --out-summary "$RESULT_DIR/timing_path_classification_summary.md" || true
    fi
  fi
fi

{
  echo "# Genus O0 Oscillator/PD Server Run Summary"
  echo
  echo "- Run ID: \`$RUN_ID\`"
  echo "- Git HEAD: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)\`"
  echo "- Genus exit code: $GENUS_RC"
  echo "- Snapshot exit code: ${SNAPSHOT_RC:-0}"
  echo "- Macro generation exit code: $GEN_MACRO_RC"
  echo "- SDC overlay: \`$OVERLAY_SDC\`"
  echo "- Provisional macro views enabled: yes"
  echo "- Result directory: \`results/genus_osc_pd/$RUN_ID/\`"
  echo
  echo "## Key Files"
  echo
  for file in \
    "genus_${RUN_ID}.log" \
    timing_summary.rpt \
    timing_violations.rpt \
    timing_pd_capture_hotspots.rpt \
    timing_osc_counter_hotspots.rpt \
    timing_osc_fast_full_clock.rpt \
    timing_clk_sys_violations.rpt \
    report_design_rules.rpt \
    check_timing_intent.rpt \
    report_clocks.rpt \
    report_clock_groups.rpt \
    report_exceptions.rpt \
    report_constraints.rpt \
    latch_audit.rpt \
    cdc_manual_audit.rpt \
    PARSED_SUMMARY.md \
    timing_path_classification.csv \
    timing_path_classification_summary.md; do
    if [[ -f "$RESULT_DIR/$file" ]]; then
      echo "- present: \`$file\`"
    else
      echo "- missing: \`$file\`"
    fi
  done
  echo
  echo "## Status"
  echo
  echo "PROVISIONAL PHYSICAL/TIMING MODEL ONLY - not oscillator/PD signoff."
} > "$RESULT_DIR/SUMMARY.md"

cat "$RESULT_DIR/SUMMARY.md"

if [[ $GENUS_RC -ne 0 ]]; then
  exit "$GENUS_RC"
fi
if [[ ${SNAPSHOT_RC:-0} -ne 0 ]]; then
  exit "$SNAPSHOT_RC"
fi
exit 0
