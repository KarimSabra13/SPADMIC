#!/usr/bin/env bash
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$PNR_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

RUN_ID="${1:-20260608_o12b_phase_buffer_balance}"
SOURCE_RUN_ID="${MPTDC_O12B_SOURCE_RUN_ID:-20260608_o12_phase_buffer_pnr_abs1}"
RUN_MODE="${MPTDC_O12B_MODE:-report_only}"
if [[ "${MPTDC_O12B_VALIDATE_ONLY:-0}" == "1" ]]; then
  RUN_MODE="validate_only"
fi

RESULT_DIR="$REPO_ROOT/results/innovus/$RUN_ID"
LOG_DIR="$RESULT_DIR/logs"
REPORT_DIR="$RESULT_DIR/reports"
MANIFEST_DIR="$RESULT_DIR/manifests"
RUN_LOG="$LOG_DIR/innovus_${RUN_ID}.log"
SOURCE_RESULT_DIR="$REPO_ROOT/results/innovus/$SOURCE_RUN_ID"
SOURCE_CHECKPOINT_DAT="${MPTDC_O12B_SOURCE_CHECKPOINT_DAT:-$SOURCE_RESULT_DIR/checkpoints/04_route.enc.dat}"
SOURCE_RESTORE_TCL="${MPTDC_O12B_SOURCE_RESTORE_TCL:-$SOURCE_RESULT_DIR/checkpoints/restore_latest.tcl}"

mkdir -p "$LOG_DIR" "$REPORT_DIR" "$MANIFEST_DIR"

case "$RUN_MODE" in
  validate_only|report_only) ;;
  *)
    echo "ERROR: unsupported MPTDC_O12B_MODE=$RUN_MODE" >&2
    echo "Supported: validate_only, report_only" >&2
    exit 2
    ;;
esac

{
  echo "# O12B Phase Buffer Balance Wrapper"
  echo "date: $(date -Iseconds)"
  echo "repo: $REPO_ROOT"
  echo "branch: $(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || true)"
  echo "head: $(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)"
  echo "expected_head: ${EXPECTED_HEAD:-unset}"
  echo "run_id: $RUN_ID"
  echo "run_mode: $RUN_MODE"
  echo "source_run_id: $SOURCE_RUN_ID"
  echo "source_checkpoint_dat: $SOURCE_CHECKPOINT_DAT"
  echo "source_restore_tcl: $SOURCE_RESTORE_TCL"
  echo "labels: O12B_PHASE_BUFFER_BALANCE REPORT_ONLY NOT_FINAL_SIGNOFF"
  echo
  echo "git status --short --untracked-files=no:"
  git -C "$REPO_ROOT" status --short --untracked-files=no 2>/dev/null || true
} | tee "$MANIFEST_DIR/run_manifest.txt" | tee "$RUN_LOG"

INPUT_RC=0
require_file() {
  local label="$1"
  local path="$2"
  if [[ ! -f "$path" ]]; then
    echo "ERROR: missing $label: $path" | tee -a "$RUN_LOG"
    INPUT_RC=2
  fi
}

require_path() {
  local label="$1"
  local path="$2"
  if [[ ! -e "$path" ]]; then
    echo "ERROR: missing $label: $path" | tee -a "$RUN_LOG"
    INPUT_RC=2
  fi
}

ACTUAL_HEAD="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)"
if [[ -n "${EXPECTED_HEAD:-}" && "$ACTUAL_HEAD" != "$EXPECTED_HEAD" ]]; then
  echo "ERROR: HEAD mismatch. expected=$EXPECTED_HEAD actual=$ACTUAL_HEAD" | tee -a "$RUN_LOG"
  INPUT_RC=5
fi

require_file "O12B Innovus entry Tcl" "$SCRIPT_DIR/innovus_o12b_phase_buffer_balance.tcl"
require_file "O12B report Tcl" "$SCRIPT_DIR/innovus_o12b_phase_buffer_reports.tcl"
require_file "O12 report Tcl" "$SCRIPT_DIR/innovus_o12_phase_buffer_reports.tcl"
require_file "O11 helper report Tcl" "$SCRIPT_DIR/innovus_o11_ro_load_reports.tcl"
if [[ "$RUN_MODE" != "validate_only" ]]; then
  require_path "O12 route checkpoint data" "$SOURCE_CHECKPOINT_DAT"
  if [[ ! -f "$SOURCE_RESTORE_TCL" ]]; then
    echo "WARN: source restore script not found; direct checkpoint restore will be used if Innovus is available: $SOURCE_RESTORE_TCL" | tee -a "$RUN_LOG"
  fi
fi

export MPTDC_O12B_RUN_ID="$RUN_ID"
export MPTDC_O12B_RESULT_DIR="$RESULT_DIR"
export MPTDC_O12B_SOURCE_RUN_ID="$SOURCE_RUN_ID"
export MPTDC_O12B_SOURCE_CHECKPOINT_DAT="$SOURCE_CHECKPOINT_DAT"
export MPTDC_O12B_SOURCE_RESTORE_TCL="$SOURCE_RESTORE_TCL"

run_tcl_source_check() {
  if ! command -v tclsh >/dev/null 2>&1; then
    echo "WARN: tclsh not found; skipping Tcl source check" | tee -a "$RUN_LOG"
    return 0
  fi
  (
    cd "$REPO_ROOT"
    MPTDC_O12B_SOURCE_ONLY=1 tclsh <<'EOF'
source MPTDC/pnr/scripts/innovus_o12b_phase_buffer_reports.tcl
source MPTDC/pnr/scripts/innovus_o12b_phase_buffer_balance.tcl
if {[mptdc_o12b_num "1.25"] ne "1.25"} { error "numeric helper failed" }
set qpin [mptdc_o12_pin_candidates fast 4 Q]
if {[lsearch -exact $qpin {u_core_u_phase_buf_fast/gen_phase_buf[4].u_buf/Q}] < 0} { error "missing restored fast Q candidate" }
if {[mptdc_o12b_clock_for slow 7] ne "clk_osc_slow_buf_tap7"} { error "clock helper failed" }
puts "O12B Tcl source/pin-helper check passed"
EOF
  ) 2>&1 | tee -a "$RUN_LOG"
  return "${PIPESTATUS[0]}"
}

if [[ "$INPUT_RC" == "0" ]]; then
  run_tcl_source_check
  TCL_RC=$?
  if [[ "$TCL_RC" != "0" ]]; then
    INPUT_RC=6
  fi
fi

INNOVUS_RC=0
if [[ "$INPUT_RC" != "0" ]]; then
  INNOVUS_RC="$INPUT_RC"
elif [[ "$RUN_MODE" == "validate_only" ]]; then
  echo "MPTDC_O12B_VALIDATE_ONLY=1: input and Tcl validation passed; Innovus not launched." | tee -a "$RUN_LOG"
  INNOVUS_RC=0
elif ! command -v innovus >/dev/null 2>&1; then
  echo "ERROR: innovus not found in PATH; run report_only on the lab server." | tee -a "$RUN_LOG"
  INNOVUS_RC=127
else
  (
    cd "$SCRIPT_DIR"
    innovus -nowin -init innovus_o12b_phase_buffer_balance.tcl -log "$LOG_DIR/innovus_o12b_phase_buffer_balance.log"
  ) 2>&1 | tee -a "$RUN_LOG"
  INNOVUS_RC=${PIPESTATUS[0]}
fi

REQUIRED_RC=0
REPORT_COMPLETE="YES"
INVALID_REQUIRED=()

require_output_nonempty() {
  local label="$1"
  local rel="$2"
  if [[ ! -s "$RESULT_DIR/$rel" ]]; then
    INVALID_REQUIRED+=("$label: missing or empty: $rel")
    REQUIRED_RC=9
    REPORT_COMPLETE="NO"
  fi
}

require_output_no_error_marker() {
  local label="$1"
  local rel="$2"
  require_output_nonempty "$label" "$rel"
  if [[ -s "$RESULT_DIR/$rel" ]] && grep -Eq '(^ERROR,|REPORT_STATUS=FAILED|REPORT_STATUS=INVALID|NO_RAW_SOURCE_PIN_MATCH|NO_BUFFER_OUTPUT_PIN_MATCH|NO_NET_FROM_PIN|MISSING_BUFFER|TOPOLOGY_MISMATCH|EXTRA_BUFFER)' "$RESULT_DIR/$rel"; then
    INVALID_REQUIRED+=("$label: invalid marker found: $rel")
    REQUIRED_RC=9
    REPORT_COMPLETE="NO"
  fi
}

validate_required_outputs() {
  require_output_no_error_marker "O12B report summary" "reports/SUMMARY.md"
  require_output_no_error_marker "raw RO pin loads" "reports/ro_phase_raw_pin_loads.csv"
  require_output_no_error_marker "phase buffer output loads" "reports/phase_buffer_output_loads.csv"
  require_output_no_error_marker "phase buffer balance summary" "reports/phase_buffer_balance_summary.md"
  require_output_no_error_marker "phase buffer topology" "reports/phase_buffer_topology.csv"
  require_output_nonempty "phase buffer topology summary" "reports/phase_buffer_topology_summary.md"
  require_output_nonempty "phase buffer placement" "reports/phase_buffer_placement.csv"
  require_output_nonempty "phase buffer placement summary" "reports/phase_buffer_placement_summary.md"
  require_output_nonempty "phase buffer delay estimate" "reports/phase_buffer_delay_estimate.csv"
  require_output_nonempty "phase buffer route summary" "reports/phase_buffer_route_summary.csv"
  require_output_nonempty "RO phase sink classification" "reports/ro_phase_sink_classification.csv"
  require_output_nonempty "restored max cap report" "reports/drv_max_cap.rpt"
  require_output_nonempty "restored max transition report" "reports/drv_max_transition.rpt"
  require_output_nonempty "RO-domain timing" "reports/timing_post_route_ro_osc_domain.rpt"
  require_output_nonempty "timing summary by class" "reports/timing_post_route_summary_by_class.md"

  if [[ -s "$RESULT_DIR/reports/ro_phase_raw_pin_loads.csv" ]]; then
    local raw_rows raw_fanout_bad raw_critical
    raw_rows="$(awk 'NR>1 {count++} END {print count+0}' "$RESULT_DIR/reports/ro_phase_raw_pin_loads.csv")"
    raw_fanout_bad="$(awk -F, 'NR>1 && $6 != 1 {bad++} END {print bad+0}' "$RESULT_DIR/reports/ro_phase_raw_pin_loads.csv")"
    raw_critical="$(grep -c ',CRITICAL,' "$RESULT_DIR/reports/ro_phase_raw_pin_loads.csv" || true)"
    if [[ "$raw_rows" -lt 16 || "$raw_fanout_bad" -ne 0 || "$raw_critical" -ne 0 ]]; then
      INVALID_REQUIRED+=("raw RO pin loads: expected 16 fanout-1 non-critical rows; rows=$raw_rows fanout_bad=$raw_fanout_bad critical=$raw_critical")
      REQUIRED_RC=9
      REPORT_COMPLETE="NO"
    fi
  fi

  if [[ -s "$RESULT_DIR/reports/phase_buffer_output_loads.csv" ]]; then
    local out_rows out_numeric
    out_rows="$(awk 'NR>1 {count++} END {print count+0}' "$RESULT_DIR/reports/phase_buffer_output_loads.csv")"
    out_numeric="$(awk -F, 'NR>1 && $11 != "" {count++} END {print count+0}' "$RESULT_DIR/reports/phase_buffer_output_loads.csv")"
    if [[ "$out_rows" -lt 16 ]]; then
      INVALID_REQUIRED+=("phase buffer output loads: expected at least 16 rows, got $out_rows")
      REQUIRED_RC=9
      REPORT_COMPLETE="NO"
    fi
    if [[ "$out_numeric" -ne 16 ]]; then
      INVALID_REQUIRED+=("phase buffer output loads: expected 16 numeric total_cap_pf rows, got $out_numeric")
      REQUIRED_RC=9
      REPORT_COMPLETE="NO"
    fi
  fi

  if [[ -s "$RESULT_DIR/reports/phase_buffer_balance_summary.md" ]] && grep -q 'BUFFER_OUTPUT_LOAD_QUANTIFIED=NO' "$RESULT_DIR/reports/phase_buffer_balance_summary.md"; then
    INVALID_REQUIRED+=("phase buffer balance summary: BUFFER_OUTPUT_LOAD_QUANTIFIED=NO")
    REQUIRED_RC=9
    REPORT_COMPLETE="NO"
  fi

  if [[ -s "$RESULT_DIR/reports/phase_buffer_topology.csv" ]]; then
    local topo_ok
    topo_ok="$(awk -F, 'NR>1 && ($7 == "TOPOLOGY_MATCH" || $7 == "TOPOLOGY_SHAPE_MATCHED") {ok++} END {print ok+0}' "$RESULT_DIR/reports/phase_buffer_topology.csv")"
    if [[ "$topo_ok" -ne 16 ]]; then
      INVALID_REQUIRED+=("phase buffer topology: expected 16 TOPOLOGY_SHAPE_MATCHED rows, got $topo_ok")
      REQUIRED_RC=9
      REPORT_COMPLETE="NO"
    fi
  fi
}

if [[ "$RUN_MODE" == "report_only" ]]; then
  validate_required_outputs
fi

CRASH_STAGE="not_applicable"
INNOVUS_EXIT_CLASS="CLEAN_OR_NON_139"
if [[ -s "$RESULT_DIR/manifests/current_stage.txt" ]]; then
  CRASH_STAGE="$(tr '\n' ';' < "$RESULT_DIR/manifests/current_stage.txt")"
fi
if [[ "$INNOVUS_RC" == "139" ]]; then
  if [[ "$REQUIRED_RC" == "0" ]]; then
    INNOVUS_EXIT_CLASS="POST_REPORT_TOOL_EXIT_139"
  else
    INNOVUS_EXIT_CLASS="INNOVUS_EXIT_139_BEFORE_REQUIRED_OUTPUTS"
  fi
  {
    echo "INNOVUS_EXIT_139"
    echo "exit_class=$INNOVUS_EXIT_CLASS"
    echo "last_stage=$CRASH_STAGE"
    echo "required_outputs_exit_code=$REQUIRED_RC"
  } > "$RESULT_DIR/manifests/innovus_exit_classification.txt"
elif [[ "$INNOVUS_RC" != "0" ]]; then
  if [[ "$REQUIRED_RC" == "0" ]]; then
    INNOVUS_EXIT_CLASS="POST_REPORT_TOOL_EXIT_${INNOVUS_RC}"
  else
    INNOVUS_EXIT_CLASS="INNOVUS_EXIT_${INNOVUS_RC}_BEFORE_REQUIRED_OUTPUTS"
  fi
  {
    echo "INNOVUS_EXIT_NONZERO"
    echo "exit_code=$INNOVUS_RC"
    echo "exit_class=$INNOVUS_EXIT_CLASS"
    echo "last_stage=$CRASH_STAGE"
    echo "required_outputs_exit_code=$REQUIRED_RC"
  } > "$RESULT_DIR/manifests/innovus_exit_classification.txt"
fi

if [[ "$REQUIRED_RC" != "0" ]]; then
  {
    echo "O12B required outputs/content check failed"
    echo "=========================================="
    printf '%s\n' "${INVALID_REQUIRED[@]}"
  } > "$RESULT_DIR/REQUIRED_OUTPUTS_CHECK_FAILED.txt"
  printf 'REQUIRED OUTPUT INVALID: %s\n' "${INVALID_REQUIRED[@]}" | tee -a "$RUN_LOG"
fi

WRAPPER_RC="$INNOVUS_RC"
if [[ "$WRAPPER_RC" == "0" && "$REQUIRED_RC" != "0" ]]; then
  WRAPPER_RC="$REQUIRED_RC"
fi

{
  echo "# O12B Phase Buffer Balance Wrapper Summary"
  echo
  echo "- Run ID: \`$RUN_ID\`"
  echo "- Run mode: \`$RUN_MODE\`"
  echo "- Source run ID: \`$SOURCE_RUN_ID\`"
  echo "- Git HEAD: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)\`"
  echo "- Innovus exit code: $INNOVUS_RC"
  echo "- Innovus exit class: \`$INNOVUS_EXIT_CLASS\`"
  echo "- Last recorded Innovus stage: \`$CRASH_STAGE\`"
  echo "- Required outputs exit code: $REQUIRED_RC"
  echo "- Wrapper exit code: $WRAPPER_RC"
  echo "- REPORT_COMPLETE: \`$REPORT_COMPLETE\`"
  echo "- Result directory: \`results/innovus/$RUN_ID\`"
  echo "- Labels: \`O12B_PHASE_BUFFER_BALANCE\`, \`REPORT_ONLY\`, \`NOT_FINAL_SIGNOFF\`"
  echo
  echo "## Key Outputs"
  if [[ "$RUN_MODE" == "validate_only" ]]; then
    echo "- validate_only: report CSVs are not generated because Innovus is not launched."
  else
    for path in \
      reports/SUMMARY.md \
      reports/report_clocks.rpt \
      reports/drv_max_cap.rpt \
      reports/drv_max_transition.rpt \
      reports/ro_phase_raw_pin_loads.csv \
      reports/phase_buffer_output_loads.csv \
      reports/phase_buffer_balance_summary.md \
      reports/phase_buffer_topology.csv \
      reports/phase_buffer_topology_summary.md \
      reports/phase_buffer_placement.csv \
      reports/phase_buffer_placement_summary.md \
      reports/phase_buffer_delay_estimate.csv \
      reports/phase_buffer_route_summary.csv \
      reports/ro_phase_sink_classification.csv \
      reports/timing_post_route_ro_osc_domain.rpt \
      reports/timing_post_route_summary_by_class.md; do
      if [[ -s "$RESULT_DIR/$path" ]]; then
        echo "- present: \`$path\`"
      else
        echo "- missing: \`$path\`"
      fi
    done
  fi
  if [[ -s "$RESULT_DIR/REQUIRED_OUTPUTS_CHECK_FAILED.txt" ]]; then
    echo
    echo "## Invalid Required Outputs"
    sed 's/^/- /' "$RESULT_DIR/REQUIRED_OUTPUTS_CHECK_FAILED.txt"
  fi
} > "$RESULT_DIR/SUMMARY.md"

cat "$RESULT_DIR/SUMMARY.md"
exit "$WRAPPER_RC"
