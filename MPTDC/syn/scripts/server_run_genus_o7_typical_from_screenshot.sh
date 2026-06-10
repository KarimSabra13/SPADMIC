#!/usr/bin/env bash
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$SYN_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

RUN_ID="${1:-$(date +%Y%m%d_%H%M%S)_o7_typical_from_screenshot}"
SNAPSHOT_TAG="genus_osc_pd_${RUN_ID}"
RESULT_DIR="$REPO_ROOT/results/genus_osc_pd/$RUN_ID"
SNAPSHOT_DIR="$MPTDC_DIR/lab_snapshots/$SNAPSHOT_TAG"
GENUS_LOG="$RESULT_DIR/genus_${RUN_ID}.log"
ENV_FILE="$MPTDC_DIR/analog_handoff/real_ro_tune4_abstract.env"
MODEL_FILE="$MPTDC_DIR/analog_handoff/ro_tune4_typical_from_screenshot.yaml"
DEFAULT_EXPORT_RUN_ID="${O1_RO_EXPORT_RUN_ID:-20260528_o1_export_ro_tune4_lef}"
DEFAULT_REAL_LEF="$REPO_ROOT/results/osc_pd/$DEFAULT_EXPORT_RUN_ID/real_abstract_lef/RO_tune4_real_abstract.lef"
DEFAULT_REAL_LIB="$SYN_DIR/macros/RO_tune4_real_abstract_shell.lib"
O7_SDC="${O7_SDC_PATH:-$SYN_DIR/inputs/mptdc_osc_typical_from_screenshot.sdc}"
O7_FILELIST="${O7_FILELIST_PATH:-$SYN_DIR/filelist_o5_pd_stdcell_closure.f}"
O7_GENUS_EFFORT="${O7_GENUS_EFFORT:-fast}"
SC_ROOT_PATH="${SC_ROOT:-/data/pdk/xfab/xh018/diglibs/D_CELLS_HD/v6_0}"
STDCELL_TC_LIB="${SC_ROOT_PATH}/liberty_LPMOS/v6_0_0/PVT_1_80V_range/D_CELLS_HD_LPMOS_typ_1_80V_25C.lib"

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

rm -rf "$RESULT_DIR"
mkdir -p "$RESULT_DIR" "$SYN_DIR/logs"

{
  echo "# O7 Typical RO Screenshot Model Genus Run"
  echo "date: $(date -Iseconds)"
  echo "hostname: $(hostname)"
  echo "repo: $REPO_ROOT"
  echo "branch: $(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || true)"
  echo "head: $(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)"
  echo "run_id: $RUN_ID"
  echo "snapshot_tag: $SNAPSHOT_TAG"
  echo "flavor: O7_TYPICAL_FROM_SCREENSHOT_FEASIBILITY_ONLY"
  echo "signoff_status: PROVISIONAL_FROM_SCREENSHOT_NOT_FOR_SIGNOFF"
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
  echo "ERROR: missing O1/O7 env file: $ENV_FILE" | tee -a "$GENUS_LOG"
  INPUT_RC=2
fi

REAL_LEF="${O1_RO_LEF_PATH:-$DEFAULT_REAL_LEF}"
REAL_LIB="${O1_RO_LIBERTY_PATH:-$DEFAULT_REAL_LIB}"

for required in "$REAL_LEF" "$REAL_LIB" "$O7_SDC" "$O7_FILELIST" "$MODEL_FILE"; do
  if [[ ! -f "$required" ]]; then
    echo "ERROR: missing required O7 input: $required" | tee -a "$GENUS_LOG"
    INPUT_RC=2
  fi
done

MACRO_NAME="unknown"
if [[ "$INPUT_RC" == "0" ]]; then
  MACRO_NAME="$(awk '
    /^[[:space:]]*PROPERTYDEFINITIONS[[:space:]]*$/ {inprop=1; next}
    inprop && /^[[:space:]]*END[[:space:]]+PROPERTYDEFINITIONS[[:space:]]*$/ {inprop=0; next}
    inprop {next}
    /^[[:space:]]*MACRO[[:space:]]+[^[:space:];]+[[:space:]]*$/ {print $2; exit}
  ' "$REAL_LEF")"
  echo "O7 real LEF: $REAL_LEF" | tee -a "$GENUS_LOG"
  echo "O7 real LEF macro: $MACRO_NAME" | tee -a "$GENUS_LOG"
  if [[ "$MACRO_NAME" != "RO_tune4" ]]; then
    echo "ERROR: LEF macro '$MACRO_NAME' does not match expected RO_tune4" | tee -a "$GENUS_LOG"
    INPUT_RC=3
  fi
fi

if [[ "$INPUT_RC" == "0" ]] && ! command -v genus >/dev/null 2>&1; then
  {
    echo "ERROR: genus not found in PATH."
    echo "This script must be run on the lab server with Cadence Genus available."
  } | tee -a "$GENUS_LOG"
  INPUT_RC=127
fi

export MPTDC_TIMING_VIEW=tc_only
export MPTDC_TC_ONLY_VIEW=1
export O1_USE_REAL_RO_ABSTRACT=1
export O1_RO_LEF_PATH="$REAL_LEF"
export O1_RO_LIBERTY_PATH="$REAL_LIB"
export MPTDC_USE_RO_TUNE4_MACRO=1
export MPTDC_READ_HDL_LIST="$O7_FILELIST"
export MPTDC_OSC_PD_USE_PROVISIONAL=0
export MPTDC_OSC_PD_USE_PROVISIONAL_LIBERTY=0
export MPTDC_OSC_PD_SDC_OVERLAY="$O7_SDC"
export O1_RUN_FLAVOR="O7_TYPICAL_FROM_SCREENSHOT_FEASIBILITY_ONLY"
export O7_TIMING_MODE="typical_from_screenshot"
export GENUS_EFFORT="$O7_GENUS_EFFORT"
export MPTDC_OPT_GOAL="o7_typical_from_screenshot_${O7_GENUS_EFFORT}"
export MPTDC_OSC_SLOW_PERIOD_NS="${O7_OSC_SLOW_PERIOD_NS:-1.000}"
export MPTDC_OSC_FAST_PERIOD_NS="${O7_OSC_FAST_PERIOD_NS:-0.900}"
export MPTDC_OSC_SLOW_TAP_STEP_NS="${O7_OSC_SLOW_TAP_STEP_NS:-0.055}"
export MPTDC_OSC_FAST_TAP_STEP_NS="${O7_OSC_FAST_TAP_STEP_NS:-0.050}"
export MPTDC_ENABLE_CLOCK_GATING="${O7_ENABLE_CLOCK_GATING:-0}"
export MPTDC_ALLOW_ICG_DONT_USE_OVERRIDE="${O7_ALLOW_ICG_DONT_USE_OVERRIDE:-0}"
export MPTDC_ALLOW_DISCRETE_CLOCK_GATING="${O7_ALLOW_DISCRETE_CLOCK_GATING:-0}"
export MPTDC_RELAX_PD_PRESERVE="${O7_RELAX_PD_PRESERVE:-1}"

{
  echo
  echo "O7 inputs:"
  echo "  MODEL_FILE=$MODEL_FILE"
  echo "  SOURCE_WARNING=screenshots appear labeled RO_tune3; digital macro is RO_tune4; equivalence not confirmed"
  echo "  STDCELL_TC_LIB=$STDCELL_TC_LIB"
  echo "  REAL_LEF=$REAL_LEF"
  echo "  REAL_LIB=$REAL_LIB"
  echo "  O7_SDC=$O7_SDC"
  echo "  O7_FILELIST=$O7_FILELIST"
  echo "  GENUS_EFFORT=$GENUS_EFFORT"
  echo "  MPTDC_TIMING_VIEW=$MPTDC_TIMING_VIEW"
  echo "  MPTDC_OSC_SLOW_PERIOD_NS=$MPTDC_OSC_SLOW_PERIOD_NS"
  echo "  MPTDC_OSC_FAST_PERIOD_NS=$MPTDC_OSC_FAST_PERIOD_NS"
  echo "  MPTDC_OSC_SLOW_TAP_STEP_NS=$MPTDC_OSC_SLOW_TAP_STEP_NS"
  echo "  MPTDC_OSC_FAST_TAP_STEP_NS=$MPTDC_OSC_FAST_TAP_STEP_NS"
  echo "  RO_JITTER_RMS_PS=0.614"
  echo "  RO_SETUP_UNCERTAINTY_PS=10.0"
  echo "  RO_HOLD_UNCERTAINTY_PS=5.0"
  echo "  RO_STARTUP_RSTB_TO_S5_PS=367.907"
  echo "  RO_THRESHOLD_V=0.9"
  echo "  RO_VDD_TYP_V=1.8"
  echo
} | tee -a "$RESULT_DIR/run_manifest.txt" | tee -a "$GENUS_LOG"

GENUS_RC="$INPUT_RC"
if [[ "$INPUT_RC" == "0" ]]; then
  echo "[GENUS_O7] Cleaning generated synthesis outputs/reports for a non-stale run" | tee -a "$GENUS_LOG"
  rm -rf "$SYN_DIR/reports/synthesis" "$SYN_DIR/outputs"
  mkdir -p "$SYN_DIR/reports" "$SYN_DIR/outputs" "$SYN_DIR/logs"

  echo "[GENUS_O7] Starting TC-only screenshot feasibility flow" | tee -a "$GENUS_LOG"
  (
    cd "$SCRIPT_DIR"
    genus -files genus.tcl -log "../logs/genus_o7_typical_from_screenshot.log"
  ) 2>&1 | tee -a "$GENUS_LOG"
  GENUS_RC=${PIPESTATUS[0]}
fi

echo "[SNAPSHOT] Collecting Genus O7 snapshot into $SNAPSHOT_DIR" | tee -a "$GENUS_LOG"
SNAPSHOT_RC=0
if ! bash "$SCRIPT_DIR/collect_snapshot.sh" "$SNAPSHOT_TAG" >> "$GENUS_LOG" 2>&1; then
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

CHECK_REPORT="$RESULT_DIR/o7_typical_from_screenshot_check.rpt"
{
  echo "# O7 Typical From Screenshot Check"
  echo
  echo "post_synth_netlist=$POSTSYN_NETLIST"
  echo
  if [[ -f "$POSTSYN_NETLIST" ]]; then
    echo "## RO_tune4 instance lines"
    grep -nE '^[[:space:]]*RO_tune4[[:space:]]+' "$POSTSYN_NETLIST" || true
    echo
    echo "## old oscillator/counter residue"
    grep -nE 'u_fast_cnt|u_slow_cnt|gray_src_cont_q|gray_snap_ff|dst_count_latched|mptdc_osc_stub' "$POSTSYN_NETLIST" || true
  else
    echo "ERROR: post-synthesis netlist not found"
  fi
} > "$CHECK_REPORT"

RO_COUNT=0
STUB_COUNT=0
OLD_FAST_COUNTER_RESIDUE_COUNT=0
OLD_SLOW_COUNTER_RESIDUE_COUNT=0
CLOCKS_ON_RO=0
DRV_COUNT="unknown"
if [[ -f "$POSTSYN_NETLIST" ]]; then
  RO_COUNT="$(grep -cE '^[[:space:]]*RO_tune4[[:space:]]+' "$POSTSYN_NETLIST" || true)"
  STUB_COUNT="$(grep -cE 'mptdc_osc_stub' "$POSTSYN_NETLIST" || true)"
  OLD_FAST_COUNTER_RESIDUE_COUNT="$(grep -cE 'u_fast_cnt|nfast_src_count.*u_pd' "$POSTSYN_NETLIST" || true)"
  OLD_SLOW_COUNTER_RESIDUE_COUNT="$(grep -cE 'u_slow_cnt|gray_src_cont_q|gray_snap_ff|dst_count_latched' "$POSTSYN_NETLIST" || true)"
fi
if [[ -f "$RESULT_DIR/report_clocks.rpt" ]]; then
  CLOCKS_ON_RO="$(grep -cE 'u_ro_tune4.*/?S\[[0-7]\]|u_ro_tune4.*S\[[0-7]\]' "$RESULT_DIR/report_clocks.rpt" || true)"
fi
if [[ -f "$RESULT_DIR/report_design_rules.rpt" ]]; then
  DRV_COUNT="$(grep -ciE 'violation|violated|max_transition|max transition' "$RESULT_DIR/report_design_rules.rpt" || true)"
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
  python3 - "$RESULT_DIR" > "$RESULT_DIR/o7_class_wns_summary.txt" <<'PY' || true
import csv
import math
import sys
from pathlib import Path

run_dir = Path(sys.argv[1])
csv_path = run_dir / "timing_path_classification.csv"
classes = {}
families = {}

def add(table, key, slack):
    data = table.setdefault(key, {"count": 0, "wns": slack, "tns": 0.0})
    data["count"] += 1
    data["wns"] = min(data["wns"], slack)
    if slack < 0:
        data["tns"] += slack

if csv_path.exists():
    with csv_path.open(newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            cls = row.get("classification") or row.get("class") or "UNKNOWN_REVIEW_REQUIRED"
            try:
                slack = float(row.get("slack_ps", "nan"))
            except ValueError:
                slack = math.nan
            if math.isnan(slack):
                continue
            add(classes, cls, slack)
            sp = row.get("startpoint", "")
            ep = row.get("endpoint", "")
            if "u_pd/hit_latched_reg" in sp and "u_pd/nfast_hit_latched_reg" in ep:
                fam = "PD_HIT_TO_TS_FREEZE"
            elif "u_fast_tag" in sp and "u_fast_tag" in ep:
                fam = "LOCAL_FAST_TAG_SELF"
            elif "u_fast_tag" in sp and "u_pd/nfast_hit_latched_reg" in ep:
                fam = "FAST_TAG_TO_PD_TS"
            elif "u_slow_epoch" in sp and "u_slow_epoch" in ep:
                fam = "SLOW_JOHNSON_SELF"
            elif "u_drain_ctrl" in sp or "u_drain_ctrl" in ep:
                fam = "CLK_SYS_DRAIN"
            elif "start_wdt" in sp or "start_timeout" in sp or "start_wdt" in ep or "start_timeout" in ep:
                fam = "CLK_SYS_WATCHDOG"
            else:
                fam = "OTHER"
            add(families, fam, slack)

print("## Classes")
for cls in ["OSC_FAST_REAL", "OSC_SLOW_REAL", "CLK_SYS_REAL", "PD_INTENTIONAL_VERNIER", "UNKNOWN_REVIEW_REQUIRED"]:
    data = classes.get(cls, {"count": 0, "wns": 0.0, "tns": 0.0})
    print(f"{cls}: WNS={data['wns']:.1f} TNS={data['tns']:.1f} count={data['count']}")

print("")
print("## Families")
for fam in ["PD_HIT_TO_TS_FREEZE", "FAST_TAG_TO_PD_TS", "LOCAL_FAST_TAG_SELF", "SLOW_JOHNSON_SELF", "CLK_SYS_DRAIN", "CLK_SYS_WATCHDOG", "OTHER"]:
    data = families.get(fam, {"count": 0, "wns": 0.0, "tns": 0.0})
    print(f"{fam}: WNS={data['wns']:.1f} TNS={data['tns']:.1f} count={data['count']}")
PY
fi

STATUS="O7_SERVER_REVIEW_REQUIRED"
if [[ "$RO_COUNT" == "2" && "$STUB_COUNT" == "0" && "$OLD_FAST_COUNTER_RESIDUE_COUNT" == "0" && "$OLD_SLOW_COUNTER_RESIDUE_COUNT" == "0" ]]; then
  STATUS="O7_NETLIST_CANDIDATE"
fi

{
  echo "# Genus O7 Typical From Screenshot Summary"
  echo
  echo "- Run ID: \`$RUN_ID\`"
  echo "- Git HEAD: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)\`"
  echo "- Flavor: \`O7_TYPICAL_FROM_SCREENSHOT_FEASIBILITY_ONLY\`"
  echo "- Genus exit code: $GENUS_RC"
  echo "- Snapshot exit code: $SNAPSHOT_RC"
  echo "- Source warning: screenshots appear labeled RO_tune3; digital macro is RO_tune4; equivalence not confirmed"
  echo "- Signoff status: \`PROVISIONAL_FROM_SCREENSHOT_NOT_FOR_SIGNOFF\`"
  echo "- Standard-cell Liberty: \`$STDCELL_TC_LIB\`"
  echo "- TC-only view: yes"
  echo "- MMMC BC/WC views created: no"
  echo "- Real LEF: \`$REAL_LEF\`"
  echo "- Real LEF macro: \`$MACRO_NAME\`"
  echo "- RO_tune4 Liberty shell: \`$REAL_LIB\`"
  echo "- SDC overlay: \`$O7_SDC\`"
  echo "- HDL filelist: \`$O7_FILELIST\`"
  echo "- Slow period ns: \`$MPTDC_OSC_SLOW_PERIOD_NS\`"
  echo "- Fast period ns: \`$MPTDC_OSC_FAST_PERIOD_NS\`"
  echo "- Slow tap step ns: \`$MPTDC_OSC_SLOW_TAP_STEP_NS\`"
  echo "- Fast tap step ns: \`$MPTDC_OSC_FAST_TAP_STEP_NS\`"
  echo "- Jitter RMS ps: \`0.614\`"
  echo "- Setup uncertainty ps: \`10.0\`"
  echo "- Hold uncertainty ps: \`5.0\`"
  echo "- Startup rstb-to-S5 ps: \`367.907\`"
  echo "- RO_tune4 instance count: $RO_COUNT"
  echo "- mptdc_osc_stub residue count: $STUB_COUNT"
  echo "- old fast-counter residue count: $OLD_FAST_COUNTER_RESIDUE_COUNT"
  echo "- old slow-counter residue count: $OLD_SLOW_COUNTER_RESIDUE_COUNT"
  echo "- report_clocks RO_tune4/S match count: $CLOCKS_ON_RO"
  echo "- DRV rough report-design-rules match count: $DRV_COUNT"
  echo
  echo "O7_STATUS=$STATUS"
  echo "STATUS_LABEL=FEASIBILITY_ONLY_TYPICAL_RO_SCREENSHOT_MODEL"
  echo "FINAL_SIGNOFF=NO"
  echo
  if [[ -f "$RESULT_DIR/o7_class_wns_summary.txt" ]]; then
    echo "## WNS/TNS by Class and Family"
    cat "$RESULT_DIR/o7_class_wns_summary.txt"
    echo
  fi
  echo "## Key Files"
  for file in \
    "genus_${RUN_ID}.log" \
    mptdc_top_asic.postsyn.v \
    o7_typical_from_screenshot_check.rpt \
    run_manifest.txt \
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
    o7_class_wns_summary.txt \
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

if [[ "$GENUS_RC" != "0" ]]; then
  exit "$GENUS_RC"
fi
if [[ "$SNAPSHOT_RC" != "0" ]]; then
  exit "$SNAPSHOT_RC"
fi
[[ "$STATUS" == "O7_NETLIST_CANDIDATE" ]]
