#!/usr/bin/env bash
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$SYN_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

RUN_ID="${1:-$(date +%Y%m%d_%H%M%S)_o1_real_abstract_genus}"
SNAPSHOT_TAG="genus_osc_pd_${RUN_ID}"
RESULT_DIR="$REPO_ROOT/results/genus_osc_pd/$RUN_ID"
SNAPSHOT_DIR="$MPTDC_DIR/lab_snapshots/$SNAPSHOT_TAG"
GENUS_LOG="$RESULT_DIR/genus_${RUN_ID}.log"
ENV_FILE="$MPTDC_DIR/analog_handoff/real_ro_tune4_abstract.env"
EXPORT_RUN_ID="${O1_RO_EXPORT_RUN_ID:-20260528_o1_export_ro_tune4_lef}"
DEFAULT_REAL_LEF="$REPO_ROOT/results/osc_pd/$EXPORT_RUN_ID/real_abstract_lef/RO_tune4_real_abstract.lef"
OVERLAY_SDC="${MPTDC_OSC_PD_SDC_OVERLAY:-$SYN_DIR/inputs/mptdc_osc_pd_physical.sdc}"
RUN_FLAVOR="${O1_RUN_FLAVOR:-O1A_REAL_ABSTRACT_NOMINAL}"
O1_RO_CELL_NAME="${O1_RO_CELL_NAME:-RO_tune4}"

mkdir -p "$RESULT_DIR" "$SYN_DIR/logs"

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
} | tee "$RESULT_DIR/run_manifest.txt" | tee "$GENUS_LOG"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: missing O1 env file: $ENV_FILE" | tee -a "$GENUS_LOG"
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
    echo "ERROR: missing real RO_tune4 LEF: $O1_RO_LEF_PATH" | tee -a "$GENUS_LOG"
    INPUT_RC=2
  else
    macro_name="$(awk '
      /^[[:space:]]*PROPERTYDEFINITIONS[[:space:]]*$/ {inprop=1; next}
      inprop && /^[[:space:]]*END[[:space:]]+PROPERTYDEFINITIONS[[:space:]]*$/ {inprop=0; next}
      inprop {next}
      /^[[:space:]]*MACRO[[:space:]]+[^[:space:];]+[[:space:]]*$/ {print $2; exit}
    ' "$O1_RO_LEF_PATH")"
    echo "O1 real LEF: $O1_RO_LEF_PATH" | tee -a "$GENUS_LOG"
    echo "O1 real LEF macro: $macro_name" | tee -a "$GENUS_LOG"
    if [[ "$macro_name" != "$O1_RO_CELL_NAME" ]]; then
      echo "ERROR: LEF macro '$macro_name' does not match expected '$O1_RO_CELL_NAME'" | tee -a "$GENUS_LOG"
      INPUT_RC=3
    fi
  fi
fi

python3 "$REPO_ROOT/tools/osc/gen_osc_macro_views.py" \
  --template "$REPO_ROOT/tools/osc/oscillator_macro_template.yaml" \
  --out-dir "$SYN_DIR/macros" >> "$GENUS_LOG" 2>&1 || GEN_MACRO_RC=$?
GEN_MACRO_RC="${GEN_MACRO_RC:-0}"

for required in \
  "$OVERLAY_SDC" \
  "$SYN_DIR/macros/mptdc_osc_slow_provisional.lib" \
  "$SYN_DIR/macros/mptdc_osc_fast_provisional.lib"; do
  if [[ ! -f "$required" ]]; then
    echo "ERROR: missing required O1 input: $required" | tee -a "$GENUS_LOG"
    INPUT_RC=2
  fi
done
INPUT_RC="${INPUT_RC:-0}"

export O1_USE_REAL_RO_ABSTRACT=1
export MPTDC_OSC_PD_USE_PROVISIONAL=0
export MPTDC_OSC_PD_USE_PROVISIONAL_LIBERTY=1
export MPTDC_OSC_PD_SDC_OVERLAY="$OVERLAY_SDC"

if [[ "$INPUT_RC" != "0" ]]; then
  GENUS_RC="$INPUT_RC"
elif ! command -v genus >/dev/null 2>&1; then
  {
    echo "ERROR: genus not found in PATH."
    echo "This script must be run on the lab server with Cadence Genus available."
  } | tee -a "$GENUS_LOG"
  GENUS_RC=127
else
  echo "[GENUS_O1] Starting $RUN_FLAVOR flow" | tee -a "$GENUS_LOG"
  (
    cd "$SCRIPT_DIR"
    genus -files genus.tcl -log ../logs/genus_o1_real_abstract.log
  ) 2>&1 | tee -a "$GENUS_LOG"
  GENUS_RC=${PIPESTATUS[0]}
fi

echo "[SNAPSHOT] Collecting Genus O1 snapshot into $SNAPSHOT_DIR" | tee -a "$GENUS_LOG"
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

POSTSYN_NETLIST="$RESULT_DIR/mptdc_top_asic.postsyn.v"
if [[ ! -f "$POSTSYN_NETLIST" ]]; then
  POSTSYN_NETLIST="$SYN_DIR/outputs/mptdc_top_asic.postsyn.v"
fi

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
  echo "# Genus O1 Real RO_tune4 Abstract Summary"
  echo
  echo "- Run ID: \`$RUN_ID\`"
  echo "- Flavor: \`$RUN_FLAVOR\`"
  echo "- Git HEAD: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)\`"
  echo "- Genus exit code: $GENUS_RC"
  echo "- Snapshot exit code: ${SNAPSHOT_RC:-0}"
  echo "- Macro generation exit code: $GEN_MACRO_RC"
  echo "- Real LEF: \`${O1_RO_LEF_PATH:-unset}\`"
  echo "- Real LEF macro: \`${macro_name:-unknown}\`"
  echo "- SDC overlay: \`$OVERLAY_SDC\`"
  echo "- Provisional LEF enabled: no"
  echo "- Provisional Liberty shell enabled: yes"
  echo "- Macro binding status: \`$BINDING_STATUS\`"
  echo "- Result directory: \`results/genus_osc_pd/$RUN_ID/\`"
  echo
  if [[ "$BINDING_STATUS" == BOUND_TO_* ]]; then
    echo "O1A_REAL_ABSTRACT_BINDING=PASS"
    echo "STATUS_LABEL=REAL_PHYSICAL_ABSTRACT_WITH_PROVISIONAL_LIBERTY"
  else
    echo "O1A_REAL_ABSTRACT_BINDING=FAILED"
    echo "O1A_REAL_ABSTRACT_RUN_BLOCKED=YES"
    echo "REASON=post-synthesis netlist does not bind to $O1_RO_CELL_NAME"
    echo "STATUS_LABEL=PROVISIONAL_OR_UNBOUND"
  fi
  echo
  echo "## Key Files"
  for file in \
    "genus_${RUN_ID}.log" \
    timing_summary.rpt \
    timing_violations.rpt \
    report_design_rules.rpt \
    check_timing_intent.rpt \
    report_clocks.rpt \
    report_clock_groups.rpt \
    report_exceptions.rpt \
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
} > "$RESULT_DIR/SUMMARY.md"

cat "$RESULT_DIR/SUMMARY.md"

if [[ $GENUS_RC -ne 0 ]]; then
  exit "$GENUS_RC"
fi
if [[ "${O1_STRICT_REAL_MACRO_BINDING:-1}" == "1" && "$BINDING_STATUS" != BOUND_TO_* ]]; then
  exit 3
fi
if [[ ${SNAPSHOT_RC:-0} -ne 0 ]]; then
  exit "$SNAPSHOT_RC"
fi
exit 0
