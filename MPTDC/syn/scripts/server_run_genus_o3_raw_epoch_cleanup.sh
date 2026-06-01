#!/usr/bin/env bash
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$SYN_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

RUN_ID="${1:-$(date +%Y%m%d_%H%M%S)_o3_raw_epoch_cleanup_genus}"
SNAPSHOT_TAG="genus_osc_pd_${RUN_ID}"
RESULT_DIR="$REPO_ROOT/results/genus_osc_pd/$RUN_ID"
SNAPSHOT_DIR="$MPTDC_DIR/lab_snapshots/$SNAPSHOT_TAG"
GENUS_LOG="$RESULT_DIR/genus_${RUN_ID}.log"
ENV_FILE="$MPTDC_DIR/analog_handoff/real_ro_tune4_abstract.env"
EXPORT_RUN_ID="${O1_RO_EXPORT_RUN_ID:-20260528_o1_export_ro_tune4_lef}"
REAL_LEF="${O1_RO_LEF_PATH:-$REPO_ROOT/results/osc_pd/$EXPORT_RUN_ID/real_abstract_lef/RO_tune4_real_abstract.lef}"
REAL_LIB="${O1_RO_LIBERTY_PATH:-$SYN_DIR/macros/RO_tune4_real_abstract_shell.lib}"
O3_SDC="${O3_SDC_PATH:-$SYN_DIR/inputs/mptdc_osc_pd_o3.sdc}"
O3_FILELIST="${O3_FILELIST_PATH:-$SYN_DIR/filelist_o3_raw_epoch_cleanup.f}"

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

# Reusing a run ID during lab iteration is common.  Clean the directory first so
# stale focused reports cannot survive and masquerade as current evidence.
rm -rf "$RESULT_DIR"
mkdir -p "$RESULT_DIR" "$SYN_DIR/logs"

{
  echo "# O3 Raw Epoch / PD Capture Cleanup Genus Run"
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
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$ENV_FILE"
else
  echo "ERROR: missing O1/O3 env file: $ENV_FILE" | tee -a "$GENUS_LOG"
  INPUT_RC=2
fi

for required in "$REAL_LEF" "$REAL_LIB" "$O3_SDC" "$O3_FILELIST"; do
  if [[ ! -f "$required" ]]; then
    echo "ERROR: missing required O3 input: $required" | tee -a "$GENUS_LOG"
    INPUT_RC=2
  fi
done

export O1_USE_REAL_RO_ABSTRACT=1
export O1_RO_LEF_PATH="$REAL_LEF"
export O1_RO_LIBERTY_PATH="$REAL_LIB"
export MPTDC_USE_RO_TUNE4_MACRO=1
export MPTDC_READ_HDL_LIST="$O3_FILELIST"
export MPTDC_OSC_PD_USE_PROVISIONAL=0
export MPTDC_OSC_PD_USE_PROVISIONAL_LIBERTY=0
export MPTDC_OSC_PD_SDC_OVERLAY="$O3_SDC"
export O1_RUN_FLAVOR="O3_RAW_EPOCH_AND_PD_CAPTURE_CLEANUP"

{
  echo "O3 inputs:"
  echo "  REAL_LEF=$REAL_LEF"
  echo "  REAL_LIB=$REAL_LIB"
  echo "  O3_SDC=$O3_SDC"
  echo "  O3_FILELIST=$O3_FILELIST"
  echo
} | tee -a "$GENUS_LOG"

if [[ "$INPUT_RC" != "0" ]]; then
  GENUS_RC="$INPUT_RC"
elif ! command -v genus >/dev/null 2>&1; then
  echo "ERROR: genus not found in PATH. Run this on the lab server." | tee -a "$GENUS_LOG"
  GENUS_RC=127
else
  echo "[GENUS_O3] Cleaning generated synthesis outputs/reports for a non-stale run" | tee -a "$GENUS_LOG"
  rm -rf "$SYN_DIR/reports/synthesis" "$SYN_DIR/outputs"
  mkdir -p "$SYN_DIR/reports" "$SYN_DIR/outputs" "$SYN_DIR/logs"

  echo "[GENUS_O3] Starting O3 raw-epoch cleanup flow" | tee -a "$GENUS_LOG"
  (
    cd "$SCRIPT_DIR"
    genus -files genus.tcl -log ../logs/genus_o3_raw_epoch_cleanup.log
  ) 2>&1 | tee -a "$GENUS_LOG"
  GENUS_RC=${PIPESTATUS[0]}
fi

echo "[SNAPSHOT] Collecting Genus O3 snapshot into $SNAPSHOT_DIR" | tee -a "$GENUS_LOG"
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

for file in \
  report_clock_groups.rpt \
  report_exceptions.rpt \
  timing_osc_counter_hotspots.rpt \
  timing_pd_capture_hotspots.rpt \
  timing_clk_sys_violations.rpt \
  timing_fast_count_to_nfast_hit.rpt; do
  if [[ -f "$RESULT_DIR/synthesis_reports/post_synthesis/$file" && ! -f "$RESULT_DIR/$file" ]]; then
    cp "$RESULT_DIR/synthesis_reports/post_synthesis/$file" "$RESULT_DIR/$file"
  fi
done

POSTSYN_NETLIST="$RESULT_DIR/mptdc_top_asic.postsyn.v"
if [[ ! -f "$POSTSYN_NETLIST" ]]; then
  POSTSYN_NETLIST="$SYN_DIR/outputs/mptdc_top_asic.postsyn.v"
fi

CHECK_REPORT="$RESULT_DIR/o3_raw_epoch_cleanup_check.rpt"
RO_COUNT=0
STUB_COUNT=0
FAST_TAG_REF_COUNT=0
OLD_FAST_COUNTER_RESIDUE_COUNT=0
SLOW_EPOCH_REF_COUNT=0
STOP_EPOCH_REF_COUNT=0
OLD_SLOW_COUNTER_RESIDUE_COUNT=0
OLD_FAST_COUNT_TO_PD_TEXT_COUNT=0
OLD_SLOW_COUNTER_TEXT_COUNT=0
PD_Q_TO_NFAST_TEXT_COUNT=0
CLOCKS_ON_RO=0

{
  echo "# O3 Raw Epoch / PD Capture Cleanup Check"
  echo
  echo "post_synth_netlist=$POSTSYN_NETLIST"
  echo
  if [[ -f "$POSTSYN_NETLIST" ]]; then
    echo "## RO_tune4 instance lines"
    grep -nE '^[[:space:]]*RO_tune4[[:space:]]+' "$POSTSYN_NETLIST" || true
    echo
    echo "## O3 slow epoch references"
    grep -nE 'mptdc_slow_epoch_johnson|u_slow_epoch|mptdc_stop_epoch_capture_async|u_stop_epoch_capture' "$POSTSYN_NETLIST" || true
    echo
    echo "## O2 fast tag references"
    grep -nE 'mptdc_fast_epoch_tag|u_fast_tag|gen_fast_tag_col' "$POSTSYN_NETLIST" || true
    echo
    echo "## old counter residue"
    grep -nE 'u_fast_cnt|u_slow_cnt|gray_src_cont_q|gray_snap_ff|dst_count_latched|mptdc_osc_stub' "$POSTSYN_NETLIST" || true
  else
    echo "ERROR: post-synthesis netlist not found"
  fi
} > "$CHECK_REPORT"

if [[ -f "$POSTSYN_NETLIST" ]]; then
  RO_COUNT="$(grep -cE '^[[:space:]]*RO_tune4[[:space:]]+' "$POSTSYN_NETLIST" || true)"
  STUB_COUNT="$(grep -cE 'mptdc_osc_stub' "$POSTSYN_NETLIST" || true)"
  FAST_TAG_REF_COUNT="$(grep -cE 'mptdc_fast_epoch_tag|u_fast_tag|gen_fast_tag_col' "$POSTSYN_NETLIST" || true)"
  OLD_FAST_COUNTER_RESIDUE_COUNT="$(grep -cE 'u_fast_cnt|nfast_src_count.*u_pd' "$POSTSYN_NETLIST" || true)"
  SLOW_EPOCH_REF_COUNT="$(grep -cE 'mptdc_slow_epoch_johnson|u_slow_epoch' "$POSTSYN_NETLIST" || true)"
  STOP_EPOCH_REF_COUNT="$(grep -cE 'mptdc_stop_epoch_capture_async|u_stop_epoch_capture' "$POSTSYN_NETLIST" || true)"
  OLD_SLOW_COUNTER_RESIDUE_COUNT="$(grep -cE 'u_slow_cnt|gray_src_cont_q|gray_snap_ff|dst_count_latched' "$POSTSYN_NETLIST" || true)"
fi

if [[ -f "$RESULT_DIR/report_clocks.rpt" ]]; then
  CLOCKS_ON_RO="$(grep -cE 'u_ro_tune4.*/?S\[[0-7]\]|u_ro_tune4.*S\[[0-7]\]' "$RESULT_DIR/report_clocks.rpt" || true)"
fi

if [[ -f "$RESULT_DIR/timing_violations.rpt" ]]; then
  OLD_FAST_COUNT_TO_PD_TEXT_COUNT="$(grep -cE 'u_fast_cnt|bin_q_reg.*nfast_hit_latched|nfast_src_count.*nfast_hit_latched' "$RESULT_DIR/timing_violations.rpt" || true)"
  OLD_SLOW_COUNTER_TEXT_COUNT="$(grep -cE 'u_slow_cnt|gray_src_cont_q|dst_count_latched|gray_snap_ff' "$RESULT_DIR/timing_violations.rpt" || true)"
  PD_Q_TO_NFAST_TEXT_COUNT="$(grep -cE 'u_pd/(q1|q2|hit_latched)_reg.*nfast_hit_latched' "$RESULT_DIR/timing_violations.rpt" || true)"
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
  fi
fi

O3_STATUS="O3_SERVER_REVIEW_REQUIRED"
if [[ "$RO_COUNT" == "2" && "$STUB_COUNT" == "0" && "$OLD_FAST_COUNTER_RESIDUE_COUNT" == "0" && "$OLD_SLOW_COUNTER_RESIDUE_COUNT" == "0" ]]; then
  O3_STATUS="O3_RAW_EPOCH_NETLIST_CANDIDATE"
fi

{
  echo "# Genus O3 Raw Epoch / PD Capture Cleanup Summary"
  echo
  echo "- Run ID: \`$RUN_ID\`"
  echo "- Git HEAD: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)\`"
  echo "- Genus exit code: $GENUS_RC"
  echo "- Snapshot exit code: ${SNAPSHOT_RC:-0}"
  echo "- Real LEF: \`$REAL_LEF\`"
  echo "- RO_tune4 Liberty shell: \`$REAL_LIB\`"
  echo "- SDC overlay: \`$O3_SDC\`"
  echo "- HDL filelist: \`$O3_FILELIST\`"
  echo "- RO_tune4 instance count: $RO_COUNT"
  echo "- mptdc_osc_stub residue count: $STUB_COUNT"
  echo "- fast-tag netlist reference count: $FAST_TAG_REF_COUNT"
  echo "- old fast-counter residue count: $OLD_FAST_COUNTER_RESIDUE_COUNT"
  echo "- slow Johnson epoch reference count: $SLOW_EPOCH_REF_COUNT"
  echo "- STOP epoch capture reference count: $STOP_EPOCH_REF_COUNT"
  echo "- old slow-counter residue count: $OLD_SLOW_COUNTER_RESIDUE_COUNT"
  echo "- old fast-count-to-PD timing text count: $OLD_FAST_COUNT_TO_PD_TEXT_COUNT"
  echo "- old slow-counter timing text count: $OLD_SLOW_COUNTER_TEXT_COUNT"
  echo "- PD q/hit_latched to nfast timing text count: $PD_Q_TO_NFAST_TEXT_COUNT"
  echo "- report_clocks RO_tune4/S match count: $CLOCKS_ON_RO"
  echo
  echo "O3_RAW_EPOCH_STATUS=$O3_STATUS"
  echo "STATUS_LABEL=REAL_PHYSICAL_ABSTRACT_WITH_RAW_FAST_TAG_AND_SLOW_JOHNSON_EPOCH"
  echo "INNOVUS_BLOCKED_UNTIL_O3_GENUS_REVIEW=YES"
  echo "R800_BLOCKED_UNTIL_O3_AND_ANALOG_TUNE_DATA=YES"
  echo
  echo "## Key Files"
  for file in \
    "genus_${RUN_ID}.log" \
    mptdc_top_asic.postsyn.v \
    o3_raw_epoch_cleanup_check.rpt \
    report_clocks.rpt \
    report_clock_groups.rpt \
    report_exceptions.rpt \
    check_timing_intent.rpt \
    timing_summary.rpt \
    timing_violations.rpt \
    timing_osc_counter_hotspots.rpt \
    timing_pd_capture_hotspots.rpt \
    timing_clk_sys_violations.rpt \
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
if [[ "$O3_STATUS" != "O3_RAW_EPOCH_NETLIST_CANDIDATE" ]]; then
  exit 4
fi
exit 0
