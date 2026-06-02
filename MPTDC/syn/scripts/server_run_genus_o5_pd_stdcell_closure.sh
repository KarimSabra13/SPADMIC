#!/usr/bin/env bash
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$SYN_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

BASE_RUN_ID="${1:-$(date +%Y%m%d_%H%M%S)_o5_pd_stdcell_closure}"
ENV_FILE="$MPTDC_DIR/analog_handoff/real_ro_tune4_abstract.env"
EXPORT_RUN_ID="${O1_RO_EXPORT_RUN_ID:-20260528_o1_export_ro_tune4_lef}"
REAL_LEF="${O1_RO_LEF_PATH:-$REPO_ROOT/results/osc_pd/$EXPORT_RUN_ID/real_abstract_lef/RO_tune4_real_abstract.lef}"
REAL_LIB="${O1_RO_LIBERTY_PATH:-$SYN_DIR/macros/RO_tune4_real_abstract_shell.lib}"
O5_SDC="${O5_SDC_PATH:-$SYN_DIR/inputs/mptdc_osc_pd_o5.sdc}"
O5_FILELIST="${O5_FILELIST_PATH:-$SYN_DIR/filelist_o5_pd_stdcell_closure.f}"
O5_RUN_BASE="${O5_RUN_BASE:-0}"
O5_RUN_PVT_AWARE="${O5_RUN_PVT_AWARE:-0}"
O5_RUN_CLOSURE="${O5_RUN_CLOSURE:-auto}"

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
  echo "ERROR: missing O1/O5 env file: $ENV_FILE" >&2
  exit 2
fi

for required in "$REAL_LEF" "$REAL_LIB" "$O5_SDC" "$O5_FILELIST"; do
  if [[ ! -f "$required" ]]; then
    echo "ERROR: missing required O5 input: $required" >&2
    exit 2
  fi
done

if ! command -v genus >/dev/null 2>&1; then
  echo "ERROR: genus not found in PATH. Run this on the lab server." >&2
  exit 127
fi

write_class_summary() {
  local result_dir="$1"
  python3 - "$result_dir" > "$result_dir/o5_class_wns_summary.txt" <<'PY' || true
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
}

run_one() {
  local experiment="$1"
  local effort="$2"
  local run_id="$3"
  local enable_cg="$4"
  local icg_override="$5"
  local relax_pd="$6"
  local slow_period="$7"
  local fast_period="$8"
  local slow_tap="$9"
  local fast_tap="${10}"

  local result_dir="$REPO_ROOT/results/genus_osc_pd/$run_id"
  local snapshot_tag="genus_osc_pd_${run_id}"
  local snapshot_dir="$MPTDC_DIR/lab_snapshots/$snapshot_tag"
  local genus_log="$result_dir/genus_${run_id}.log"

  rm -rf "$result_dir"
  mkdir -p "$result_dir" "$SYN_DIR/logs"

  {
    echo "# O5 Standard-Cell PD Closure Genus Run"
    echo "date: $(date -Iseconds)"
    echo "hostname: $(hostname)"
    echo "repo: $REPO_ROOT"
    echo "branch: $(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || true)"
    echo "head: $(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)"
    echo "experiment: $experiment"
    echo "genus_effort: $effort"
    echo "enable_clock_gating: $enable_cg"
    echo "icg_dont_use_override: $icg_override"
    echo "relax_pd_preserve: $relax_pd"
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
  export MPTDC_READ_HDL_LIST="$O5_FILELIST"
  export MPTDC_OSC_PD_USE_PROVISIONAL=0
  export MPTDC_OSC_PD_USE_PROVISIONAL_LIBERTY=0
  export MPTDC_OSC_PD_SDC_OVERLAY="$O5_SDC"
  export O1_RUN_FLAVOR="O5_STANDARD_CELL_PD_CLOSURE_NO_FREQ_REDUCTION"
  export O5_TIMING_MODE="$experiment"
  export GENUS_EFFORT="$effort"
  export MPTDC_OPT_GOAL="o5_${experiment}_${effort}"
  export MPTDC_ENABLE_CLOCK_GATING="$enable_cg"
  export MPTDC_ALLOW_ICG_DONT_USE_OVERRIDE="$icg_override"
  export MPTDC_CLOCK_GATING_MIN_FLOPS="${MPTDC_CLOCK_GATING_MIN_FLOPS:-2}"
  export MPTDC_RELAX_PD_PRESERVE="$relax_pd"

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
    echo "O5 inputs:"
    echo "  REAL_LEF=$REAL_LEF"
    echo "  REAL_LIB=$REAL_LIB"
    echo "  O5_SDC=$O5_SDC"
    echo "  O5_FILELIST=$O5_FILELIST"
    echo "  GENUS_EFFORT=$GENUS_EFFORT"
    echo "  O5_TIMING_MODE=$O5_TIMING_MODE"
    echo
  } | tee -a "$genus_log"

  echo "[GENUS_O5] Cleaning generated synthesis outputs/reports for a non-stale run" | tee -a "$genus_log"
  rm -rf "$SYN_DIR/reports/synthesis" "$SYN_DIR/outputs"
  mkdir -p "$SYN_DIR/reports" "$SYN_DIR/outputs" "$SYN_DIR/logs"

  echo "[GENUS_O5] Starting O5 flow: experiment=$experiment effort=$effort" | tee -a "$genus_log"
  (
    cd "$SCRIPT_DIR"
    genus -files genus.tcl -log "../logs/genus_o5_${experiment}_${effort}.log"
  ) 2>&1 | tee -a "$genus_log"
  local genus_rc=${PIPESTATUS[0]}

  echo "[SNAPSHOT] Collecting Genus O5 snapshot into $snapshot_dir" | tee -a "$genus_log"
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

  local postsyn_netlist="$result_dir/mptdc_top_asic.postsyn.v"
  if [[ ! -f "$postsyn_netlist" ]]; then
    postsyn_netlist="$SYN_DIR/outputs/mptdc_top_asic.postsyn.v"
  fi

  local check_report="$result_dir/o5_pd_stdcell_check.rpt"
  {
    echo "# O5 Standard-Cell PD Check"
    echo
    echo "post_synth_netlist=$postsyn_netlist"
    echo
    if [[ -f "$postsyn_netlist" ]]; then
      echo "## RO_tune4 instance lines"
      grep -nE '^[[:space:]]*RO_tune4[[:space:]]+' "$postsyn_netlist" || true
      echo
      echo "## O5 tag/epoch references"
      grep -nE 'mptdc_fast_epoch_tag|u_fast_tag|gen_fast_tag_col|mptdc_slow_epoch_johnson|u_slow_epoch|mptdc_stop_epoch_capture_async|u_stop_epoch_capture' "$postsyn_netlist" || true
      echo
      echo "## timestamp flop/reset and clock-gating references"
      grep -nE 'nfast_hit_latched_reg|LGCNHD|LGCPHD|LSGCNHD|LSGCPHD|LSOGCNHD|LSOGCPHD' "$postsyn_netlist" || true
      echo
      echo "## old counter residue"
      grep -nE 'u_fast_cnt|u_slow_cnt|gray_src_cont_q|gray_snap_ff|dst_count_latched|mptdc_osc_stub' "$postsyn_netlist" || true
    else
      echo "ERROR: post-synthesis netlist not found"
    fi
  } > "$check_report"

  local ro_count=0
  local stub_count=0
  local old_fast_counter_residue_count=0
  local old_slow_counter_residue_count=0
  local clocks_on_ro=0
  local icg_netlist_count=0
  local reset_ts_count=0
  local ts_ref_count=0
  if [[ -f "$postsyn_netlist" ]]; then
    ro_count="$(grep -cE '^[[:space:]]*RO_tune4[[:space:]]+' "$postsyn_netlist" || true)"
    stub_count="$(grep -cE 'mptdc_osc_stub' "$postsyn_netlist" || true)"
    old_fast_counter_residue_count="$(grep -cE 'u_fast_cnt|nfast_src_count.*u_pd' "$postsyn_netlist" || true)"
    old_slow_counter_residue_count="$(grep -cE 'u_slow_cnt|gray_src_cont_q|gray_snap_ff|dst_count_latched' "$postsyn_netlist" || true)"
    icg_netlist_count="$(grep -cE 'LGCNHD|LGCPHD|LSGCNHD|LSGCPHD|LSOGCNHD|LSOGCPHD' "$postsyn_netlist" || true)"
    ts_ref_count="$(grep -cE 'nfast_hit_latched_reg' "$postsyn_netlist" || true)"
    reset_ts_count="$(grep -E 'DFR|SDFR' "$postsyn_netlist" | grep -cE 'nfast_hit_latched_reg' || true)"
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
    write_class_summary "$result_dir"
  fi

  local status="O5_SERVER_REVIEW_REQUIRED"
  if [[ "$ro_count" == "2" && "$stub_count" == "0" && "$old_fast_counter_residue_count" == "0" && "$old_slow_counter_residue_count" == "0" ]]; then
    status="O5_NETLIST_CANDIDATE"
  fi

  {
    echo "# Genus O5 Standard-Cell PD Closure Summary"
    echo
    echo "- Run ID: \`$run_id\`"
    echo "- Git HEAD: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)\`"
    echo "- Experiment: \`$experiment\`"
    echo "- Genus effort: \`$effort\`"
    echo "- Genus exit code: $genus_rc"
    echo "- Snapshot exit code: $snapshot_rc"
    echo "- Real LEF: \`$REAL_LEF\`"
    echo "- RO_tune4 Liberty shell: \`$REAL_LIB\`"
    echo "- SDC overlay: \`$O5_SDC\`"
    echo "- HDL filelist: \`$O5_FILELIST\`"
    echo "- Clock gating requested: \`$enable_cg\`"
    echo "- ICG dont_use override requested: \`$icg_override\`"
    echo "- PD preserve relaxed: \`$relax_pd\`"
    echo "- RO_tune4 instance count: $ro_count"
    echo "- mptdc_osc_stub residue count: $stub_count"
    echo "- old fast-counter residue count: $old_fast_counter_residue_count"
    echo "- old slow-counter residue count: $old_slow_counter_residue_count"
    echo "- report_clocks RO_tune4/S match count: $clocks_on_ro"
    echo "- timestamp flop reference count: $ts_ref_count"
    echo "- resettable timestamp flop reference count: $reset_ts_count"
    echo "- clock-gating cell netlist count: $icg_netlist_count"
    echo
    echo "O5_STATUS=$status"
    echo "STATUS_LABEL=REAL_PHYSICAL_ABSTRACT_WITH_O5_STDCELL_PD_EXPERIMENT"
    echo "RAW_LFSR_TAG_SOFTWARE_DECODE=YES"
    echo "PD_TIMESTAMP_FALSE_PATHED=NO"
    echo
    if [[ -f "$result_dir/o5_class_wns_summary.txt" ]]; then
      echo "## WNS/TNS by Class and Family"
      cat "$result_dir/o5_class_wns_summary.txt"
      echo
    fi
    echo "## Key Files"
    for file in \
      "genus_${run_id}.log" \
      mptdc_top_asic.postsyn.v \
      o5_pd_stdcell_check.rpt \
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
      o5_class_wns_summary.txt \
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
  [[ "$status" == "O5_NETLIST_CANDIDATE" ]]
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

declare -a RUN_IDS=()
declare -a RUN_RCS=()
declare -a RUN_PROMISING=()

if [[ "$O5_RUN_BASE" == "1" ]]; then
  BASE_ID="${BASE_RUN_ID}_o5_base_fast"
  run_one "base_o4_reference_rerun" "fast" "$BASE_ID" "0" "0" "0" "-" "-" "-" "-"
  rc=$?
  RUN_IDS+=("$BASE_ID"); RUN_RCS+=("$rc")
  if [[ "$rc" == "0" ]] && is_promising "$REPO_ROOT/results/genus_osc_pd/$BASE_ID" >/dev/null 2>&1; then RUN_PROMISING+=("YES"); else RUN_PROMISING+=("NO"); fi
fi

NORESET_ID="${BASE_RUN_ID}_o5_noreset_ts_fast"
run_one "noreset_timestamp" "fast" "$NORESET_ID" "0" "0" "1" "-" "-" "-" "-"
rc=$?
RUN_IDS+=("$NORESET_ID"); RUN_RCS+=("$rc")
if [[ "$rc" == "0" ]] && is_promising "$REPO_ROOT/results/genus_osc_pd/$NORESET_ID" >/dev/null 2>&1; then RUN_PROMISING+=("YES"); else RUN_PROMISING+=("NO"); fi

CG_ID="${BASE_RUN_ID}_o5_clock_gated_ts_fast"
run_one "clock_gated_timestamp" "fast" "$CG_ID" "1" "1" "1" "-" "-" "-" "-"
rc=$?
RUN_IDS+=("$CG_ID"); RUN_RCS+=("$rc")
if [[ "$rc" == "0" ]] && is_promising "$REPO_ROOT/results/genus_osc_pd/$CG_ID" >/dev/null 2>&1; then RUN_PROMISING+=("YES"); else RUN_PROMISING+=("NO"); fi

if [[ "$O5_RUN_PVT_AWARE" == "1" ]]; then
  if [[ -z "${O5_PVT_SLOW_PERIOD_NS:-}" || -z "${O5_PVT_FAST_PERIOD_NS:-}" || -z "${O5_PVT_SLOW_TAP_STEP_NS:-}" || -z "${O5_PVT_FAST_TAP_STEP_NS:-}" ]]; then
    echo "ERROR: O5_RUN_PVT_AWARE=1 requires O5_PVT_* period/tap env vars" >&2
    exit 2
  fi
  PVT_ID="${BASE_RUN_ID}_o5_clock_gated_ts_pvtaware_fast"
  run_one "clock_gated_timestamp_pvt_aware" "fast" "$PVT_ID" "1" "1" "1" \
    "$O5_PVT_SLOW_PERIOD_NS" "$O5_PVT_FAST_PERIOD_NS" "$O5_PVT_SLOW_TAP_STEP_NS" "$O5_PVT_FAST_TAP_STEP_NS"
  rc=$?
  RUN_IDS+=("$PVT_ID"); RUN_RCS+=("$rc")
  if [[ "$rc" == "0" ]] && is_promising "$REPO_ROOT/results/genus_osc_pd/$PVT_ID" >/dev/null 2>&1; then RUN_PROMISING+=("YES"); else RUN_PROMISING+=("NO"); fi
fi

CLOSURE_ID=""
CLOSURE_RC=0
if [[ "$O5_RUN_CLOSURE" == "1" || "$O5_RUN_CLOSURE" == "auto" ]]; then
  best_index=-1
  for i in "${!RUN_IDS[@]}"; do
    if [[ "${RUN_RCS[$i]}" == "0" && "${RUN_PROMISING[$i]}" == "YES" ]]; then
      best_index="$i"
    fi
  done
  if [[ "$best_index" -ge 0 ]]; then
    case "${RUN_IDS[$best_index]}" in
      *pvtaware*)
        CLOSURE_ID="${BASE_RUN_ID}_o5_clock_gated_ts_pvtaware_closure"
        run_one "clock_gated_timestamp_pvt_aware" "closure" "$CLOSURE_ID" "1" "1" "1" \
          "$O5_PVT_SLOW_PERIOD_NS" "$O5_PVT_FAST_PERIOD_NS" "$O5_PVT_SLOW_TAP_STEP_NS" "$O5_PVT_FAST_TAP_STEP_NS"
        ;;
      *clock_gated*)
        CLOSURE_ID="${BASE_RUN_ID}_o5_clock_gated_ts_closure"
        run_one "clock_gated_timestamp" "closure" "$CLOSURE_ID" "1" "1" "1" "-" "-" "-" "-"
        ;;
      *)
        CLOSURE_ID="${BASE_RUN_ID}_o5_noreset_ts_closure"
        run_one "noreset_timestamp" "closure" "$CLOSURE_ID" "0" "0" "1" "-" "-" "-" "-"
        ;;
    esac
    CLOSURE_RC=$?
  fi
fi

{
  echo "# O5 Standard-Cell PD Closure Master Summary"
  echo
  echo "- Base run ID: \`$BASE_RUN_ID\`"
  echo "- Git HEAD: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)\`"
  echo
  echo "## FAST_FEASIBILITY Runs"
  for i in "${!RUN_IDS[@]}"; do
    echo "- \`${RUN_IDS[$i]}\`: rc=${RUN_RCS[$i]}, promising=${RUN_PROMISING[$i]}"
  done
  if [[ -n "$CLOSURE_ID" ]]; then
    echo "- Closure run: \`$CLOSURE_ID\`, rc=$CLOSURE_RC"
  else
    echo "- Closure run: not launched"
  fi
  echo
  echo "## Decision"
  if [[ -n "$CLOSURE_ID" ]]; then
    echo "Decision: at least one O5 fast-feasibility mode crossed the configured threshold; review the closure run before considering Innovus."
  else
    echo "Decision: no O5 fast-feasibility mode crossed the configured threshold; do not spend closure-effort license time without reviewing root cause."
  fi
} > "$MASTER_SUMMARY"

cat "$MASTER_SUMMARY"

for rc in "${RUN_RCS[@]}"; do
  if [[ "$rc" != "0" ]]; then
    exit "$rc"
  fi
done
if [[ -n "$CLOSURE_ID" && "$CLOSURE_RC" != "0" ]]; then
  exit "$CLOSURE_RC"
fi
exit 0
