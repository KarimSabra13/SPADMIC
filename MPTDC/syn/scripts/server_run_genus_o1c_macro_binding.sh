#!/usr/bin/env bash
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$SYN_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

RUN_ID="${1:-$(date +%Y%m%d_%H%M%S)_o1c_macro_binding_genus}"
SNAPSHOT_TAG="genus_osc_pd_${RUN_ID}"
RESULT_DIR="$REPO_ROOT/results/genus_osc_pd/$RUN_ID"
SNAPSHOT_DIR="$MPTDC_DIR/lab_snapshots/$SNAPSHOT_TAG"
GENUS_LOG="$RESULT_DIR/genus_${RUN_ID}.log"
ENV_FILE="$MPTDC_DIR/analog_handoff/real_ro_tune4_abstract.env"
EXPORT_RUN_ID="${O1_RO_EXPORT_RUN_ID:-20260528_o1_export_ro_tune4_lef}"
REAL_LEF="${O1_RO_LEF_PATH:-$REPO_ROOT/results/osc_pd/$EXPORT_RUN_ID/real_abstract_lef/RO_tune4_real_abstract.lef}"
REAL_LIB="${O1_RO_LIBERTY_PATH:-$SYN_DIR/macros/RO_tune4_real_abstract_shell.lib}"
O1C_SDC="$SYN_DIR/inputs/mptdc_osc_pd_o1c.sdc"
O1C_FILELIST="$SYN_DIR/filelist_o1c_macro_binding.f"

mkdir -p "$RESULT_DIR" "$SYN_DIR/logs"

{
  echo "# O1C RO_tune4 Macro Binding Genus Run"
  echo "date: $(date -Iseconds)"
  echo "hostname: $(hostname)"
  echo "repo: $REPO_ROOT"
  echo "branch: $(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || true)"
  echo "head: $(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)"
  echo
  echo "git status --short:"
  git -C "$REPO_ROOT" status --short 2>/dev/null || true
  echo
} | tee "$RESULT_DIR/run_manifest.txt" | tee "$GENUS_LOG"

INPUT_RC=0
if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: missing O1 env file: $ENV_FILE" | tee -a "$GENUS_LOG"
  INPUT_RC=2
else
  # shellcheck source=/dev/null
  source "$ENV_FILE"
fi

for required in "$REAL_LEF" "$REAL_LIB" "$O1C_SDC" "$O1C_FILELIST"; do
  if [[ ! -f "$required" ]]; then
    echo "ERROR: missing required O1C input: $required" | tee -a "$GENUS_LOG"
    INPUT_RC=2
  fi
done

if [[ -f "$REPO_ROOT/tools/timing/parse_lef_macros.py" && -f "$REAL_LEF" ]]; then
  python3 "$REPO_ROOT/tools/timing/parse_lef_macros.py" "$REAL_LEF" \
    --summary "$RESULT_DIR/real_lef_macro_summary.txt" \
    --pins-csv "$RESULT_DIR/real_lef_pin_summary.csv" >> "$GENUS_LOG" 2>&1 || INPUT_RC=2
fi

export O1_USE_REAL_RO_ABSTRACT=1
export O1_RO_LEF_PATH="$REAL_LEF"
export O1_RO_LIBERTY_PATH="$REAL_LIB"
export MPTDC_USE_RO_TUNE4_MACRO=1
export MPTDC_READ_HDL_LIST="$O1C_FILELIST"
export MPTDC_OSC_PD_USE_PROVISIONAL=0
export MPTDC_OSC_PD_USE_PROVISIONAL_LIBERTY=0
export MPTDC_OSC_PD_SDC_OVERLAY="$O1C_SDC"
export O1_RUN_FLAVOR="O1C_MACRO_BINDING"

{
  echo "O1C inputs:"
  echo "  REAL_LEF=$REAL_LEF"
  echo "  REAL_LIB=$REAL_LIB"
  echo "  O1C_SDC=$O1C_SDC"
  echo "  O1C_FILELIST=$O1C_FILELIST"
  echo
} | tee -a "$GENUS_LOG"

if [[ "$INPUT_RC" != "0" ]]; then
  GENUS_RC="$INPUT_RC"
elif ! command -v genus >/dev/null 2>&1; then
  echo "ERROR: genus not found in PATH. Run this on the lab server." | tee -a "$GENUS_LOG"
  GENUS_RC=127
else
  echo "[GENUS_O1C] Cleaning generated synthesis outputs/reports for a non-stale run" | tee -a "$GENUS_LOG"
  rm -rf "$SYN_DIR/reports/synthesis" "$SYN_DIR/outputs"
  mkdir -p "$SYN_DIR/reports" "$SYN_DIR/outputs" "$SYN_DIR/logs"

  echo "[GENUS_O1C] Starting O1C macro-binding flow" | tee -a "$GENUS_LOG"
  (
    cd "$SCRIPT_DIR"
    genus -files genus.tcl -log ../logs/genus_o1c_macro_binding.log
  ) 2>&1 | tee -a "$GENUS_LOG"
  GENUS_RC=${PIPESTATUS[0]}
fi

echo "[SNAPSHOT] Collecting Genus O1C snapshot into $SNAPSHOT_DIR" | tee -a "$GENUS_LOG"
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

for file in report_clock_groups.rpt report_exceptions.rpt; do
  if [[ -f "$RESULT_DIR/synthesis_reports/post_synthesis/$file" && ! -f "$RESULT_DIR/$file" ]]; then
    cp "$RESULT_DIR/synthesis_reports/post_synthesis/$file" "$RESULT_DIR/$file"
  fi
done

POSTSYN_NETLIST="$RESULT_DIR/mptdc_top_asic.postsyn.v"
if [[ ! -f "$POSTSYN_NETLIST" ]]; then
  POSTSYN_NETLIST="$SYN_DIR/outputs/mptdc_top_asic.postsyn.v"
fi

MACRO_REPORT="$RESULT_DIR/macro_binding_check.rpt"
RO_COUNT=0
STUB_COUNT=0
RSTB_RESET_LIKE_COUNT=0
CLOCKS_ON_RO=0

{
  echo "# O1C Macro Binding Check"
  echo
  echo "post_synth_netlist=$POSTSYN_NETLIST"
  echo
  if [[ -f "$POSTSYN_NETLIST" ]]; then
    echo "## RO_tune4 instance lines"
    grep -nE '^[[:space:]]*RO_tune4[[:space:]]+' "$POSTSYN_NETLIST" || true
    echo
    echo "## Oscillator stub residue"
    grep -nE 'mptdc_osc_stub' "$POSTSYN_NETLIST" || true
    echo
    echo "## RO_tune4 instance blocks"
    awk '/^[[:space:]]*RO_tune4[[:space:]]+/{show=1} show{print} show && /\);/{show=0}' "$POSTSYN_NETLIST" || true
  else
    echo "ERROR: post-synthesis netlist not found"
  fi
} > "$MACRO_REPORT"

if [[ -f "$POSTSYN_NETLIST" ]]; then
  RO_COUNT="$(grep -cE '^[[:space:]]*RO_tune4[[:space:]]+' "$POSTSYN_NETLIST" || true)"
  STUB_COUNT="$(grep -cE 'mptdc_osc_stub' "$POSTSYN_NETLIST" || true)"
  RSTB_RESET_LIKE_COUNT="$(awk '/^[[:space:]]*RO_tune4[[:space:]]+/{show=1} show{print} show && /\);/{show=0}' "$POSTSYN_NETLIST" | grep -ciE '\.rstb[[:space:]]*\([^)]*(rst|reset|async_rst)' || true)"
fi

if [[ -f "$RESULT_DIR/report_clocks.rpt" ]]; then
  CLOCKS_ON_RO="$(grep -cE 'u_ro_tune4.*/?S\[[0-7]\]|u_ro_tune4.*S\[[0-7]\]' "$RESULT_DIR/report_clocks.rpt" || true)"
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
      timing_fast_count_to_nfast_hit.rpt \
      timing_clk_sys_violations.rpt; do
      [[ -f "$RESULT_DIR/$rpt" ]] && reports+=("$RESULT_DIR/$rpt")
    done
    if [[ ${#reports[@]} -gt 0 ]]; then
      python3 "$REPO_ROOT/tools/timing/classify_mptdc_timing_paths.py" "${reports[@]}" \
        --out-csv "$RESULT_DIR/timing_path_classification.csv" \
        --out-summary "$RESULT_DIR/timing_path_classification_summary.md" || true
    fi
    if [[ -f "$RESULT_DIR/timing_path_classification.csv" && -f "$REPO_ROOT/tools/timing/analyze_fast_count_capture.py" ]]; then
      python3 "$REPO_ROOT/tools/timing/analyze_fast_count_capture.py" "$RESULT_DIR" || true
    fi
  fi
fi

O1C_STATUS="O1C_BINDING_FAILED"
if [[ "$RO_COUNT" == "2" && "$STUB_COUNT" == "0" ]]; then
  if [[ "$CLOCKS_ON_RO" -ge 8 && "$RSTB_RESET_LIKE_COUNT" == "0" ]]; then
    O1C_STATUS="O1C_ARCH_VALID_BINDING_CANDIDATE"
  else
    O1C_STATUS="O1C_BINDING_ONLY_NOT_FUNCTIONAL"
  fi
fi

O1C_SDC_WARN_COUNT="$(grep -c 'MPTDC_O1C_SDC_WARN' "$GENUS_LOG" 2>/dev/null || true)"
TCL_INVALID_COMMAND_COUNT="$(grep -c 'invalid command name' "$GENUS_LOG" 2>/dev/null || true)"
O1C_SDC_CLEAN_STATUS="PASS"
if [[ "$O1C_SDC_WARN_COUNT" != "0" || "$TCL_INVALID_COMMAND_COUNT" != "0" ]]; then
  O1C_SDC_CLEAN_STATUS="REVIEW_REQUIRED"
fi

{
  echo "# Genus O1C RO_tune4 Macro Binding Summary"
  echo
  echo "- Run ID: \`$RUN_ID\`"
  echo "- Git HEAD: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)\`"
  echo "- Genus exit code: $GENUS_RC"
  echo "- Snapshot exit code: ${SNAPSHOT_RC:-0}"
  echo "- Real LEF: \`$REAL_LEF\`"
  echo "- RO_tune4 Liberty shell: \`$REAL_LIB\`"
  echo "- SDC overlay: \`$O1C_SDC\`"
  echo "- HDL filelist: \`$O1C_FILELIST\`"
  echo "- RO_tune4 instance count: $RO_COUNT"
  echo "- mptdc_osc_stub residue count: $STUB_COUNT"
  echo "- rstb reset-like connection count: $RSTB_RESET_LIKE_COUNT"
  echo "- report_clocks RO_tune4/S match count: $CLOCKS_ON_RO"
  echo "- O1C SDC warning count: $O1C_SDC_WARN_COUNT"
  echo "- Tcl invalid-command count: $TCL_INVALID_COMMAND_COUNT"
  echo
  echo "O1C_BINDING_STATUS=$O1C_STATUS"
  echo "O1C_SDC_CLEAN_STATUS=$O1C_SDC_CLEAN_STATUS"
  echo "STATUS_LABEL=REAL_PHYSICAL_ABSTRACT_WITH_LIBERTY_SHELL"
  echo "INNOVUS_BLOCKED_UNTIL_O1C_REVIEW=YES"
  echo "R800_BLOCKED_UNTIL_O1C_AND_ANALOG_TUNE_DATA=YES"
  echo
  echo "## Key Files"
  for file in \
    "genus_${RUN_ID}.log" \
    mptdc_top_asic.postsyn.v \
    macro_binding_check.rpt \
    report_clocks.rpt \
    report_clock_groups.rpt \
    report_exceptions.rpt \
    check_timing_intent.rpt \
    timing_summary.rpt \
    timing_violations.rpt \
    timing_fast_count_to_nfast_hit.rpt \
    fast_count_capture_endpoint_audit.rpt \
    fast_count_capture_paths.csv \
    fast_count_capture_summary.md \
    timing_path_classification.csv \
    timing_path_classification_summary.md \
    latch_audit.rpt \
    cdc_manual_audit.rpt \
    report_design_rules.rpt \
    report_area.rpt \
    report_qor.rpt; do
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
if [[ ${SNAPSHOT_RC:-0} -ne 0 ]]; then
  exit "$SNAPSHOT_RC"
fi
if [[ "$O1C_STATUS" == "O1C_BINDING_FAILED" ]]; then
  exit 3
fi
exit 0
