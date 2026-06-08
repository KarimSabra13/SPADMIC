#!/usr/bin/env bash
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$PNR_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

RUN_ID="${1:-20260608_o12_phase_buffer_analysis}"
SOURCE_RUN_ID="${MPTDC_O12_SOURCE_RUN_ID:-20260608_o12_phase_buffer_pnr}"
RUN_MODE="${MPTDC_O12_MODE:-report_only}"
if [[ "${MPTDC_O12_VALIDATE_ONLY:-0}" == "1" ]]; then
  RUN_MODE="validate_only"
fi

RESULT_DIR="$REPO_ROOT/results/innovus/$RUN_ID"
LOG_DIR="$RESULT_DIR/logs"
REPORT_DIR="$RESULT_DIR/reports"
MANIFEST_DIR="$RESULT_DIR/manifests"
RUN_LOG="$LOG_DIR/innovus_${RUN_ID}.log"
SOURCE_RESULT_DIR="$REPO_ROOT/results/innovus/$SOURCE_RUN_ID"
SOURCE_CHECKPOINT_DAT="${MPTDC_O12_SOURCE_CHECKPOINT_DAT:-$SOURCE_RESULT_DIR/checkpoints/04_route.enc.dat}"
SOURCE_RESTORE_TCL="${MPTDC_O12_SOURCE_RESTORE_TCL:-$SOURCE_RESULT_DIR/checkpoints/restore_latest.tcl}"

mkdir -p "$LOG_DIR" "$REPORT_DIR" "$MANIFEST_DIR"

case "$RUN_MODE" in
  validate_only|report_only) ;;
  *)
    echo "ERROR: unsupported MPTDC_O12_MODE=$RUN_MODE" >&2
    echo "Supported: validate_only, report_only" >&2
    exit 2
    ;;
esac

{
  echo "# O12 Phase Buffer Load Analysis Wrapper"
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
  echo "labels: O12_PHASE_ISOLATION_BUFFER_EXPERIMENT REPORT_ONLY NOT_FINAL_SIGNOFF"
  echo
  echo "git status --short:"
  git -C "$REPO_ROOT" status --short 2>/dev/null || true
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

require_file "O12 Innovus entry Tcl" "$SCRIPT_DIR/innovus_o12_phase_buffer_analysis.tcl"
require_file "O12 phase-buffer report Tcl" "$SCRIPT_DIR/innovus_o12_phase_buffer_reports.tcl"
require_file "O11 helper report Tcl" "$SCRIPT_DIR/innovus_o11_ro_load_reports.tcl"
if [[ "$RUN_MODE" != "validate_only" ]]; then
  require_path "O12 route checkpoint data" "$SOURCE_CHECKPOINT_DAT"
  if [[ ! -f "$SOURCE_RESTORE_TCL" ]]; then
    echo "WARN: source restore script not found; direct checkpoint restore will be used if Innovus is available: $SOURCE_RESTORE_TCL" | tee -a "$RUN_LOG"
  fi
fi

export MPTDC_O12_RUN_ID="$RUN_ID"
export MPTDC_O12_RESULT_DIR="$RESULT_DIR"
export MPTDC_O12_SOURCE_RUN_ID="$SOURCE_RUN_ID"
export MPTDC_O12_SOURCE_CHECKPOINT_DAT="$SOURCE_CHECKPOINT_DAT"
export MPTDC_O12_SOURCE_RESTORE_TCL="$SOURCE_RESTORE_TCL"

run_tcl_source_check() {
  if ! command -v tclsh >/dev/null 2>&1; then
    echo "WARN: tclsh not found; skipping Tcl source check" | tee -a "$RUN_LOG"
    return 0
  fi
  (
    cd "$REPO_ROOT"
    MPTDC_O12_SOURCE_ONLY=1 tclsh <<'EOF'
source MPTDC/pnr/scripts/innovus_o12_phase_buffer_reports.tcl
source MPTDC/pnr/scripts/innovus_o12_phase_buffer_analysis.tcl
if {[mptdc_o12_budget_label_from_source "" 50.00 1] ne "OK_STRICT"} { error "raw no-violation budget bound failed" }
set raw [mptdc_o12_pin_candidates fast 7 raw]
set qpin [mptdc_o12_pin_candidates slow 0 Q]
if {[lsearch -exact $raw {u_core/u_osc_fast/u_ro_tune4/S[7]}] < 0} { error "missing raw fast candidate" }
if {[lsearch -exact $qpin {u_core/u_phase_buf_slow/gen_phase_buf[0]/u_buf/Q}] < 0} { error "missing buffer Q candidate" }
puts "O12 Tcl source/budget/pin-candidate check passed"
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
  echo "MPTDC_O12_VALIDATE_ONLY=1: input and Tcl validation passed; Innovus not launched." | tee -a "$RUN_LOG"
  INNOVUS_RC=0
elif ! command -v innovus >/dev/null 2>&1; then
  echo "ERROR: innovus not found in PATH; run report_only on the lab server." | tee -a "$RUN_LOG"
  INNOVUS_RC=127
else
  (
    cd "$SCRIPT_DIR"
    innovus -nowin -init innovus_o12_phase_buffer_analysis.tcl -log "$LOG_DIR/innovus_o12_phase_buffer_analysis.log"
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
  if [[ -s "$RESULT_DIR/$rel" ]] && grep -Eq '(^ERROR,|REPORT_STATUS=FAILED|REPORT_STATUS=INVALID|NO_RAW_SOURCE_PIN_MATCH|NO_BUFFER_OUTPUT_PIN_MATCH|NO_NET_FROM_PIN)' "$RESULT_DIR/$rel"; then
    INVALID_REQUIRED+=("$label: invalid marker found: $rel")
    REQUIRED_RC=9
    REPORT_COMPLETE="NO"
  fi
}

validate_required_outputs() {
  require_output_no_error_marker "O12 report summary" "reports/SUMMARY.md"
  require_output_no_error_marker "raw RO pin loads" "reports/ro_phase_raw_pin_loads.csv"
  require_output_no_error_marker "phase buffer output loads" "reports/phase_buffer_output_loads.csv"
  require_output_no_error_marker "phase buffer balance summary" "reports/phase_buffer_balance_summary.md"
  require_output_no_error_marker "phase net budget summary" "reports/phase_net_load_budget_summary.md"
  require_output_no_error_marker "restored max cap report" "reports/drv_max_cap.rpt"

  if [[ -s "$RESULT_DIR/reports/ro_phase_raw_pin_loads.csv" ]]; then
    local raw_rows
    raw_rows="$(awk 'NR>1 {count++} END {print count+0}' "$RESULT_DIR/reports/ro_phase_raw_pin_loads.csv")"
    if [[ "$raw_rows" -lt 16 ]]; then
      INVALID_REQUIRED+=("raw RO pin loads: expected at least 16 rows, got $raw_rows")
      REQUIRED_RC=9
      REPORT_COMPLETE="NO"
    fi
    if grep -Eq ',CRITICAL,' "$RESULT_DIR/reports/ro_phase_raw_pin_loads.csv"; then
      INVALID_REQUIRED+=("raw RO pin loads: CRITICAL rows remain after phase isolation")
      REQUIRED_RC=9
      REPORT_COMPLETE="NO"
    fi
  fi

  if [[ -s "$RESULT_DIR/reports/phase_buffer_output_loads.csv" ]]; then
    local out_rows
    out_rows="$(awk 'NR>1 {count++} END {print count+0}' "$RESULT_DIR/reports/phase_buffer_output_loads.csv")"
    if [[ "$out_rows" -lt 16 ]]; then
      INVALID_REQUIRED+=("phase buffer output loads: expected at least 16 rows, got $out_rows")
      REQUIRED_RC=9
      REPORT_COMPLETE="NO"
    fi
  fi
}

if [[ "$INNOVUS_RC" == "0" && "$RUN_MODE" == "report_only" ]]; then
  validate_required_outputs
fi

if [[ "$REQUIRED_RC" != "0" ]]; then
  {
    echo "O12 required outputs/content check failed"
    echo "========================================="
    printf '%s\n' "${INVALID_REQUIRED[@]}"
  } > "$RESULT_DIR/REQUIRED_OUTPUTS_CHECK_FAILED.txt"
  printf 'REQUIRED OUTPUT INVALID: %s\n' "${INVALID_REQUIRED[@]}" | tee -a "$RUN_LOG"
fi

WRAPPER_RC="$INNOVUS_RC"
if [[ "$WRAPPER_RC" == "0" && "$REQUIRED_RC" != "0" ]]; then
  WRAPPER_RC="$REQUIRED_RC"
fi

{
  echo "# O12 Phase Buffer Load Analysis Wrapper Summary"
  echo
  echo "- Run ID: \`$RUN_ID\`"
  echo "- Run mode: \`$RUN_MODE\`"
  echo "- Source run ID: \`$SOURCE_RUN_ID\`"
  echo "- Git HEAD: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)\`"
  echo "- Innovus exit code: $INNOVUS_RC"
  echo "- Required outputs exit code: $REQUIRED_RC"
  echo "- Wrapper exit code: $WRAPPER_RC"
  echo "- REPORT_COMPLETE: \`$REPORT_COMPLETE\`"
  echo "- Result directory: \`results/innovus/$RUN_ID\`"
  echo "- Labels: \`O12_PHASE_ISOLATION_BUFFER_EXPERIMENT\`, \`REPORT_ONLY\`, \`NOT_FINAL_SIGNOFF\`"
  echo
  echo "## Key Outputs"
  if [[ "$RUN_MODE" == "validate_only" ]]; then
    echo "- validate_only: report CSVs are not generated because Innovus is not launched."
  else
    for path in \
      reports/SUMMARY.md \
      reports/report_clocks.rpt \
      reports/drv_max_cap.rpt \
      reports/ro_phase_raw_pin_loads.csv \
      reports/phase_buffer_output_loads.csv \
      reports/phase_buffer_balance_summary.md \
      reports/phase_net_load_budget_summary.md; do
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
