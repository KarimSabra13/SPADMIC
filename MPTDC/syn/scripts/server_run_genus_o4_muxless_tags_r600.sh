#!/usr/bin/env bash
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$SYN_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

BASE_RUN_ID="${1:-$(date +%Y%m%d_%H%M%S)_o4_muxless_tags_r600}"
ENV_FILE="$MPTDC_DIR/analog_handoff/real_ro_tune4_abstract.env"
EXPORT_RUN_ID="${O1_RO_EXPORT_RUN_ID:-20260528_o1_export_ro_tune4_lef}"
REAL_LEF="${O1_RO_LEF_PATH:-$REPO_ROOT/results/osc_pd/$EXPORT_RUN_ID/real_abstract_lef/RO_tune4_real_abstract.lef}"
REAL_LIB="${O1_RO_LIBERTY_PATH:-$SYN_DIR/macros/RO_tune4_real_abstract_shell.lib}"
O4_SDC="${O4_SDC_PATH:-$SYN_DIR/inputs/mptdc_osc_pd_o4.sdc}"
O4_FILELIST="${O4_FILELIST_PATH:-$SYN_DIR/filelist_o4_muxless_tags_r600.f}"
O4_RUN_CLOSURE="${O4_RUN_CLOSURE:-auto}"

case "$BASE_RUN_ID" in
  ""|"/"|".")
    echo "ERROR: unsafe BASE_RUN_ID: '$BASE_RUN_ID'" >&2
    exit 2
    ;;
  *"/"*|".."*)
    echo "ERROR: BASE_RUN_ID must be a simple directory name, got '$BASE_RUN_ID'" >&2
    exit 2
    ;;
esac

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$ENV_FILE"
else
  echo "ERROR: missing O1/O4 env file: $ENV_FILE" >&2
  exit 2
fi

for required in "$REAL_LEF" "$REAL_LIB" "$O4_SDC" "$O4_FILELIST"; do
  if [[ ! -f "$required" ]]; then
    echo "ERROR: missing required O4 input: $required" >&2
    exit 2
  fi
done

if ! command -v genus >/dev/null 2>&1; then
  echo "ERROR: genus not found in PATH. Run this on the lab server." >&2
  exit 127
fi

run_one() {
  local timing_mode="$1"
  local effort="$2"
  local run_id="$3"
  local slow_period="$4"
  local fast_period="$5"
  local slow_tap="$6"
  local fast_tap="$7"

  local result_dir="$REPO_ROOT/results/genus_osc_pd/$run_id"
  local snapshot_tag="genus_osc_pd_${run_id}"
  local snapshot_dir="$MPTDC_DIR/lab_snapshots/$snapshot_tag"
  local genus_log="$result_dir/genus_${run_id}.log"

  rm -rf "$result_dir"
  mkdir -p "$result_dir" "$SYN_DIR/logs"

  {
    echo "# O4 Muxless Tags / R600 Genus Run"
    echo "date: $(date -Iseconds)"
    echo "hostname: $(hostname)"
    echo "repo: $REPO_ROOT"
    echo "branch: $(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || true)"
    echo "head: $(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)"
    echo "timing_mode: $timing_mode"
    echo "genus_effort: $effort"
    echo "slow_period_ns: $slow_period"
    echo "fast_period_ns: $fast_period"
    echo "slow_tap_step_ns: $slow_tap"
    echo "fast_tap_step_ns: $fast_tap"
    echo
    echo "git status --short:"
    git -C "$REPO_ROOT" status --short 2>/dev/null || true
    echo
  } | tee "$result_dir/run_manifest.txt" | tee "$genus_log"

  export O1_USE_REAL_RO_ABSTRACT=1
  export O1_RO_LEF_PATH="$REAL_LEF"
  export O1_RO_LIBERTY_PATH="$REAL_LIB"
  export MPTDC_USE_RO_TUNE4_MACRO=1
  export MPTDC_READ_HDL_LIST="$O4_FILELIST"
  export MPTDC_OSC_PD_USE_PROVISIONAL=0
  export MPTDC_OSC_PD_USE_PROVISIONAL_LIBERTY=0
  export MPTDC_OSC_PD_SDC_OVERLAY="$O4_SDC"
  export O1_RUN_FLAVOR="O4_MUXLESS_TAGS_AND_R600_PD_LOCKED"
  export O4_TIMING_MODE="$timing_mode"
  export GENUS_EFFORT="$effort"
  export MPTDC_OPT_GOAL="o4_${timing_mode}_${effort}"

  if [[ "$slow_period" != "-" ]]; then
    export MPTDC_OSC_SLOW_PERIOD_NS="$slow_period"
    export MPTDC_OSC_FAST_PERIOD_NS="$fast_period"
    export MPTDC_OSC_SLOW_TAP_STEP_NS="$slow_tap"
    export MPTDC_OSC_FAST_TAP_STEP_NS="$fast_tap"
  else
    unset MPTDC_OSC_SLOW_PERIOD_NS
    unset MPTDC_OSC_FAST_PERIOD_NS
    unset MPTDC_OSC_SLOW_TAP_STEP_NS
    unset MPTDC_OSC_FAST_TAP_STEP_NS
  fi

  {
    echo "O4 inputs:"
    echo "  REAL_LEF=$REAL_LEF"
    echo "  REAL_LIB=$REAL_LIB"
    echo "  O4_SDC=$O4_SDC"
    echo "  O4_FILELIST=$O4_FILELIST"
    echo "  GENUS_EFFORT=$GENUS_EFFORT"
    echo "  O4_TIMING_MODE=$O4_TIMING_MODE"
    echo
  } | tee -a "$genus_log"

  echo "[GENUS_O4] Cleaning generated synthesis outputs/reports for a non-stale run" | tee -a "$genus_log"
  rm -rf "$SYN_DIR/reports/synthesis" "$SYN_DIR/outputs"
  mkdir -p "$SYN_DIR/reports" "$SYN_DIR/outputs" "$SYN_DIR/logs"

  echo "[GENUS_O4] Starting O4 flow: timing=$timing_mode effort=$effort" | tee -a "$genus_log"
  (
    cd "$SCRIPT_DIR"
    genus -files genus.tcl -log "../logs/genus_o4_${timing_mode}_${effort}.log"
  ) 2>&1 | tee -a "$genus_log"
  local genus_rc=${PIPESTATUS[0]}

  echo "[SNAPSHOT] Collecting Genus O4 snapshot into $snapshot_dir" | tee -a "$genus_log"
  local snapshot_rc=0
  if ! bash "$SCRIPT_DIR/collect_snapshot.sh" "$snapshot_tag" >> "$genus_log" 2>&1; then
    snapshot_rc=$?
    echo "WARNING: collect_snapshot.sh failed with rc=$snapshot_rc" | tee -a "$genus_log"
  fi

  if [[ -d "$snapshot_dir" ]]; then
    cp -a "$snapshot_dir/." "$result_dir/"
  fi
  cp "$genus_log" "$result_dir/genus_${run_id}.log" 2>/dev/null || true

  for file in \
    report_clock_groups.rpt \
    report_exceptions.rpt \
    timing_osc_counter_hotspots.rpt \
    timing_pd_capture_hotspots.rpt \
    timing_clk_sys_violations.rpt \
    timing_fast_count_to_nfast_hit.rpt; do
    if [[ -f "$result_dir/synthesis_reports/post_synthesis/$file" && ! -f "$result_dir/$file" ]]; then
      cp "$result_dir/synthesis_reports/post_synthesis/$file" "$result_dir/$file"
    fi
  done

  local postsyn_netlist="$result_dir/mptdc_axis_core.postsyn.v"
  if [[ ! -f "$postsyn_netlist" ]]; then
    postsyn_netlist="$SYN_DIR/outputs/mptdc_axis_core.postsyn.v"
  fi

  local check_report="$result_dir/o4_muxless_tags_r600_check.rpt"
  {
    echo "# O4 Muxless Tags / R600 Check"
    echo
    echo "post_synth_netlist=$postsyn_netlist"
    echo
    if [[ -f "$postsyn_netlist" ]]; then
      echo "## RO_tune4 instance lines"
      grep -nE '^[[:space:]]*RO_tune4[[:space:]]+' "$postsyn_netlist" || true
      echo
      echo "## O4 tag/epoch references"
      grep -nE 'mptdc_fast_epoch_tag|u_fast_tag|gen_fast_tag_col|mptdc_slow_epoch_johnson|u_slow_epoch|mptdc_stop_epoch_capture_async|u_stop_epoch_capture' "$postsyn_netlist" || true
      echo
      echo "## old counter residue"
      grep -nE 'u_fast_cnt|u_slow_cnt|gray_src_cont_q|gray_snap_ff|dst_count_latched|mptdc_osc_stub' "$postsyn_netlist" || true
    else
      echo "ERROR: post-synthesis netlist not found"
    fi
  } > "$check_report"

  local ro_count=0
  local stub_count=0
  local fast_tag_ref_count=0
  local old_fast_counter_residue_count=0
  local slow_epoch_ref_count=0
  local old_slow_counter_residue_count=0
  local clocks_on_ro=0
  if [[ -f "$postsyn_netlist" ]]; then
    ro_count="$(grep -cE '^[[:space:]]*RO_tune4[[:space:]]+' "$postsyn_netlist" || true)"
    stub_count="$(grep -cE 'mptdc_osc_stub' "$postsyn_netlist" || true)"
    fast_tag_ref_count="$(grep -cE 'mptdc_fast_epoch_tag|u_fast_tag|gen_fast_tag_col' "$postsyn_netlist" || true)"
    old_fast_counter_residue_count="$(grep -cE 'u_fast_cnt|nfast_src_count.*u_pd' "$postsyn_netlist" || true)"
    slow_epoch_ref_count="$(grep -cE 'mptdc_slow_epoch_johnson|u_slow_epoch' "$postsyn_netlist" || true)"
    old_slow_counter_residue_count="$(grep -cE 'u_slow_cnt|gray_src_cont_q|gray_snap_ff|dst_count_latched' "$postsyn_netlist" || true)"
  fi
  if [[ -f "$result_dir/report_clocks.rpt" ]]; then
    clocks_on_ro="$(grep -cE 'u_ro_tune4.*/?S\[[0-7]\]|u_ro_tune4.*S\[[0-7]\]' "$result_dir/report_clocks.rpt" || true)"
  fi

  if command -v python3 >/dev/null 2>&1; then
    if [[ -f "$REPO_ROOT/tools/timing/parse_genus_summary.py" ]]; then
      python3 "$REPO_ROOT/tools/timing/parse_genus_summary.py" "$result_dir" \
        > "$result_dir/PARSED_SUMMARY.md" 2>/dev/null || true
    fi
    if [[ -f "$REPO_ROOT/tools/timing/classify_mptdc_timing_paths.py" ]]; then
      local reports=()
      for rpt in \
        timing_violations.rpt \
        timing_osc_fast_full_clock.rpt \
        timing_pd_capture_hotspots.rpt \
        timing_osc_counter_hotspots.rpt \
        timing_fast_count_to_nfast_hit.rpt \
        timing_clk_sys_violations.rpt; do
        [[ -f "$result_dir/$rpt" ]] && reports+=("$result_dir/$rpt")
      done
      if [[ ${#reports[@]} -gt 0 ]]; then
        python3 "$REPO_ROOT/tools/timing/classify_mptdc_timing_paths.py" "${reports[@]}" \
          --out-csv "$result_dir/timing_path_classification.csv" \
          --out-summary "$result_dir/timing_path_classification_summary.md" || true
      fi
    fi
    python3 - "$result_dir" > "$result_dir/o4_class_wns_summary.txt" <<'PY' || true
import csv
import math
import sys
from pathlib import Path

run_dir = Path(sys.argv[1])
csv_path = run_dir / "timing_path_classification.csv"
classes = {}
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
            data = classes.setdefault(cls, {"count": 0, "wns": slack, "tns": 0.0})
            data["count"] += 1
            data["wns"] = min(data["wns"], slack)
            if slack < 0:
                data["tns"] += slack
for cls in ["OSC_FAST_REAL", "OSC_SLOW_REAL", "CLK_SYS_REAL", "PD_INTENTIONAL_VERNIER", "UNKNOWN_REVIEW_REQUIRED"]:
    data = classes.get(cls, {"count": 0, "wns": 0.0, "tns": 0.0})
    print(f"{cls}: WNS={data['wns']:.1f} TNS={data['tns']:.1f} count={data['count']}")
PY
  fi

  local status="O4_SERVER_REVIEW_REQUIRED"
  if [[ "$ro_count" == "2" && "$stub_count" == "0" && "$old_fast_counter_residue_count" == "0" && "$old_slow_counter_residue_count" == "0" ]]; then
    status="O4_NETLIST_CANDIDATE"
  fi

  {
    echo "# Genus O4 Muxless Tags / R600 Summary"
    echo
    echo "- Run ID: \`$run_id\`"
    echo "- Git HEAD: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)\`"
    echo "- Timing mode: \`$timing_mode\`"
    echo "- Genus effort: \`$effort\`"
    echo "- Genus exit code: $genus_rc"
    echo "- Snapshot exit code: $snapshot_rc"
    echo "- Real LEF: \`$REAL_LEF\`"
    echo "- RO_tune4 Liberty shell: \`$REAL_LIB\`"
    echo "- SDC overlay: \`$O4_SDC\`"
    echo "- HDL filelist: \`$O4_FILELIST\`"
    echo "- slow period ns: \`$slow_period\`"
    echo "- fast period ns: \`$fast_period\`"
    echo "- slow tap step ns: \`$slow_tap\`"
    echo "- fast tap step ns: \`$fast_tap\`"
    echo "- RO_tune4 instance count: $ro_count"
    echo "- mptdc_osc_stub residue count: $stub_count"
    echo "- fast-tag netlist reference count: $fast_tag_ref_count"
    echo "- old fast-counter residue count: $old_fast_counter_residue_count"
    echo "- slow Johnson epoch reference count: $slow_epoch_ref_count"
    echo "- old slow-counter residue count: $old_slow_counter_residue_count"
    echo "- report_clocks RO_tune4/S match count: $clocks_on_ro"
    echo
    echo "O4_STATUS=$status"
    echo "STATUS_LABEL=REAL_PHYSICAL_ABSTRACT_WITH_MUXLESS_RAW_TAGS"
    echo "PD_BEHAVIOR_LOCKED=YES"
    echo "RAW_LFSR_TAG_SOFTWARE_DECODE=YES"
    echo "R600_ANALOG_CONFIRMED=NO"
    echo
    if [[ -f "$result_dir/o4_class_wns_summary.txt" ]]; then
      echo "## WNS/TNS by Class"
      cat "$result_dir/o4_class_wns_summary.txt"
      echo
    fi
    echo "## Key Files"
    for file in \
      "genus_${run_id}.log" \
      mptdc_axis_core.postsyn.v \
      o4_muxless_tags_r600_check.rpt \
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
      o4_class_wns_summary.txt \
      latch_audit.rpt \
      cdc_manual_audit.rpt \
      report_design_rules.rpt \
      report_area.rpt \
      report_qor.rpt; do
      if [[ -f "$result_dir/$file" ]]; then
        echo "- present: \`$file\`"
      else
        echo "- missing: \`$file\`"
      fi
    done
  } > "$result_dir/SUMMARY.md"

  cat "$result_dir/SUMMARY.md"
  if [[ $genus_rc -ne 0 ]]; then
    return "$genus_rc"
  fi
  if [[ $snapshot_rc -ne 0 ]]; then
    return "$snapshot_rc"
  fi
  [[ "$status" == "O4_NETLIST_CANDIDATE" ]]
}

is_promising() {
  local run_dir="$1"
  [[ -f "$run_dir/timing_path_classification.csv" ]] || return 1
  python3 - "$run_dir/timing_path_classification.csv" <<'PY'
import csv
import math
import sys
from collections import defaultdict

wns = defaultdict(lambda: 0.0)
seen = set()
with open(sys.argv[1], newline="", encoding="utf-8") as f:
    for row in csv.DictReader(f):
        cls = row.get("classification") or row.get("class") or ""
        try:
            slack = float(row.get("slack_ps", "nan"))
        except ValueError:
            continue
        if math.isnan(slack):
            continue
        if cls not in seen:
            wns[cls] = slack
            seen.add(cls)
        else:
            wns[cls] = min(wns[cls], slack)
osc_fast = wns.get("OSC_FAST_REAL", 0.0)
worst = min(wns.values()) if wns else 0.0
clk_sys = wns.get("CLK_SYS_REAL", 0.0)
promising = (osc_fast > -700.0) or (worst > -700.0) or (clk_sys == worst and osc_fast > -1000.0)
print("PROMISING=YES" if promising else "PROMISING=NO")
sys.exit(0 if promising else 1)
PY
}

MASTER_SUMMARY="$REPO_ROOT/results/genus_osc_pd/${BASE_RUN_ID}_SUMMARY.md"
mkdir -p "$(dirname "$MASTER_SUMMARY")"

NOMINAL_FAST_ID="${BASE_RUN_ID}_o4_nominal_fast"
R600_FAST_ID="${BASE_RUN_ID}_o4_r600_fast"

run_one "nominal" "fast" "$NOMINAL_FAST_ID" "-" "-" "-" "-"
NOMINAL_RC=$?

run_one "r600_whatif" "fast" "$R600_FAST_ID" "1.667" "1.567" "0.1041875" "0.0979375"
R600_RC=$?

NOMINAL_PROMISING="NO"
R600_PROMISING="NO"
if [[ "$NOMINAL_RC" == "0" ]] && is_promising "$REPO_ROOT/results/genus_osc_pd/$NOMINAL_FAST_ID" >/dev/null 2>&1; then
  NOMINAL_PROMISING="YES"
fi
if [[ "$R600_RC" == "0" ]] && is_promising "$REPO_ROOT/results/genus_osc_pd/$R600_FAST_ID" >/dev/null 2>&1; then
  R600_PROMISING="YES"
fi

CLOSURE_ID=""
CLOSURE_RC=0
if [[ "$O4_RUN_CLOSURE" == "1" || "$O4_RUN_CLOSURE" == "auto" ]]; then
  if [[ "$R600_PROMISING" == "YES" ]]; then
    CLOSURE_ID="${BASE_RUN_ID}_o4_r600_closure"
    run_one "r600_whatif" "closure" "$CLOSURE_ID" "1.667" "1.567" "0.1041875" "0.0979375"
    CLOSURE_RC=$?
  elif [[ "$NOMINAL_PROMISING" == "YES" ]]; then
    CLOSURE_ID="${BASE_RUN_ID}_o4_nominal_closure"
    run_one "nominal" "closure" "$CLOSURE_ID" "-" "-" "-" "-"
    CLOSURE_RC=$?
  fi
fi

{
  echo "# O4 Muxless Tags / R600 Master Summary"
  echo
  echo "- Base run ID: \`$BASE_RUN_ID\`"
  echo "- Git HEAD: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)\`"
  echo "- Nominal FAST_FEASIBILITY: \`$NOMINAL_FAST_ID\`, rc=$NOMINAL_RC, promising=$NOMINAL_PROMISING"
  echo "- R600 FAST_FEASIBILITY: \`$R600_FAST_ID\`, rc=$R600_RC, promising=$R600_PROMISING"
  if [[ -n "$CLOSURE_ID" ]]; then
    echo "- Closure run: \`$CLOSURE_ID\`, rc=$CLOSURE_RC"
  else
    echo "- Closure run: not launched"
  fi
  echo
  echo "## Decision"
  if [[ "$R600_PROMISING" == "YES" ]]; then
    echo "Decision: R600 what-if is promising enough for closure review, but remains NOT calibration-safe until analog confirms tune codes, tap delays, Vernier delta, slew, jitter, startup, and load."
  elif [[ "$NOMINAL_PROMISING" == "YES" ]]; then
    echo "Decision: nominal fast-feasibility is promising enough for closure review."
  else
    echo "Decision: fast-feasibility did not reach the configured closure threshold; do not spend closure-effort license time on this RTL/frequency without review."
  fi
} > "$MASTER_SUMMARY"

cat "$MASTER_SUMMARY"

if [[ "$NOMINAL_RC" != "0" ]]; then
  exit "$NOMINAL_RC"
fi
if [[ "$R600_RC" != "0" ]]; then
  exit "$R600_RC"
fi
if [[ -n "$CLOSURE_ID" && "$CLOSURE_RC" != "0" ]]; then
  exit "$CLOSURE_RC"
fi
exit 0
