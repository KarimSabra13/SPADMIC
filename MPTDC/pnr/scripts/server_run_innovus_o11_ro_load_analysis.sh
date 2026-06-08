#!/usr/bin/env bash
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$PNR_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

RUN_ID="${1:-20260608_o11_ro_load_analysis}"
SOURCE_RUN_ID="${MPTDC_O11_SOURCE_RUN_ID:-20260604_o10_2_pnr_repair}"
RUN_MODE="${MPTDC_O11_MODE:-report_only}"
if [[ "${MPTDC_O11_VALIDATE_ONLY:-0}" == "1" ]]; then
  RUN_MODE="validate_only"
fi

RESULT_DIR="$REPO_ROOT/results/innovus/$RUN_ID"
LOG_DIR="$RESULT_DIR/logs"
REPORT_DIR="$RESULT_DIR/reports"
MANIFEST_DIR="$RESULT_DIR/manifests"
RUN_LOG="$LOG_DIR/innovus_${RUN_ID}.log"
SOURCE_RESULT_DIR="$REPO_ROOT/results/innovus/$SOURCE_RUN_ID"
SOURCE_CHECKPOINT_DAT="${MPTDC_O11_SOURCE_CHECKPOINT_DAT:-$SOURCE_RESULT_DIR/checkpoints/04_route.enc.dat}"
SOURCE_RESTORE_TCL="${MPTDC_O11_SOURCE_RESTORE_TCL:-$SOURCE_RESULT_DIR/checkpoints/restore_latest.tcl}"

mkdir -p "$LOG_DIR" "$REPORT_DIR" "$MANIFEST_DIR"

case "$RUN_MODE" in
  validate_only|report_only) ;;
  *)
    echo "ERROR: unsupported MPTDC_O11_MODE=$RUN_MODE" >&2
    echo "Supported: validate_only, report_only" >&2
    exit 2
    ;;
esac

{
  echo "# O11 RO_tune4 Load Analysis Wrapper"
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
  echo "labels: O11_RO_LOAD_ANALYSIS REPORT_ONLY NOT_FINAL_SIGNOFF"
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

require_file "O11 Innovus entry Tcl" "$SCRIPT_DIR/innovus_o11_ro_load_analysis.tcl"
require_file "O11 RO load report Tcl" "$SCRIPT_DIR/innovus_o11_ro_load_reports.tcl"
require_file "O10.2 drv_max_cap report" "$SOURCE_RESULT_DIR/reports/drv_max_cap.rpt"
require_path "O10.2 route checkpoint data" "$SOURCE_CHECKPOINT_DAT"

if [[ ! -f "$SOURCE_RESTORE_TCL" ]]; then
  echo "WARN: source restore script not found; direct checkpoint restore will be used if Innovus is available: $SOURCE_RESTORE_TCL" | tee -a "$RUN_LOG"
fi

export MPTDC_O11_RUN_ID="$RUN_ID"
export MPTDC_O11_RESULT_DIR="$RESULT_DIR"
export MPTDC_O11_SOURCE_RUN_ID="$SOURCE_RUN_ID"
export MPTDC_O11_SOURCE_CHECKPOINT_DAT="$SOURCE_CHECKPOINT_DAT"
export MPTDC_O11_SOURCE_RESTORE_TCL="$SOURCE_RESTORE_TCL"

run_tcl_source_check() {
  if ! command -v tclsh >/dev/null 2>&1; then
    echo "WARN: tclsh not found; skipping Tcl source check" | tee -a "$RUN_LOG"
    return 0
  fi
  (
    cd "$REPO_ROOT"
    MPTDC_O11_SOURCE_ONLY=1 tclsh <<'EOF'
source MPTDC/pnr/scripts/innovus_o11_ro_load_reports.tcl
source MPTDC/pnr/scripts/innovus_o11_ro_load_analysis.tcl
if {[mptdc_o11_budget_label 58.72] ne "OK_STRICT"} { error "strict budget label failed" }
if {[mptdc_o11_budget_label 75.59] ne "OK_CN"} { error "CN budget label failed" }
if {[mptdc_o11_budget_label 150.0] ne "WARN_OVER_CN"} { error "WARN budget label failed" }
if {[mptdc_o11_budget_label 300.0] ne "FAIL_HIGH_LOAD"} { error "FAIL budget label failed" }
if {[mptdc_o11_budget_label 300.01] ne "CRITICAL"} { error "CRITICAL budget label failed" }
set slow [mptdc_o11_pin_candidates slow 0]
set fast [mptdc_o11_pin_candidates fast 7]
if {[lsearch -exact $slow {u_core/u_osc_slow/u_ro_tune4/S[0]}] < 0} { error "missing hierarchical slow pin" }
if {[lsearch -exact $slow {u_core_u_osc_slow_u_ro_tune4/S[0]}] < 0} { error "missing flat slow pin" }
if {[lsearch -exact $fast {u_core/u_osc_fast/u_ro_tune4/S[7]}] < 0} { error "missing hierarchical fast pin" }
if {[lsearch -exact $fast {u_core_u_osc_fast_u_ro_tune4/S[7]}] < 0} { error "missing flat fast pin" }
puts "O11 Tcl source/budget/pin-candidate check passed"
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
  echo "MPTDC_O11_VALIDATE_ONLY=1: input and Tcl validation passed; Innovus not launched." | tee -a "$RUN_LOG"
  INNOVUS_RC=0
elif ! command -v innovus >/dev/null 2>&1; then
  echo "ERROR: innovus not found in PATH; run report_only on the lab server." | tee -a "$RUN_LOG"
  INNOVUS_RC=127
else
  (
    cd "$SCRIPT_DIR"
    innovus -nowin -init innovus_o11_ro_load_analysis.tcl -log "$LOG_DIR/innovus_o11_ro_load_analysis.log"
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
  if [[ -s "$RESULT_DIR/$rel" ]] && grep -Eq '(^ERROR,|REPORT_STATUS=FAILED|REPORT_STATUS=INVALID|NO_SOURCE_PIN_MATCH|NO_NET_FROM_PIN)' "$RESULT_DIR/$rel"; then
    INVALID_REQUIRED+=("$label: invalid marker found: $rel")
    REQUIRED_RC=9
    REPORT_COMPLETE="NO"
  fi
}

validate_required_outputs() {
  require_output_no_error_marker "O11 report summary" "reports/SUMMARY.md"
  require_output_no_error_marker "phase net loads" "reports/phase_net_loads.csv"
  require_output_no_error_marker "phase net load budget summary" "reports/phase_net_load_budget_summary.md"
  require_output_no_error_marker "fast tag loads" "reports/fast_tag_loads.csv"
  require_output_no_error_marker "RO phase sink classification" "reports/ro_phase_sink_classification.csv"
  require_output_no_error_marker "restored max cap report" "reports/drv_max_cap.rpt"

  if [[ -s "$RESULT_DIR/reports/phase_net_loads.csv" ]]; then
    local data_rows
    data_rows="$(awk 'NR>1 {count++} END {print count+0}' "$RESULT_DIR/reports/phase_net_loads.csv")"
    if [[ "$data_rows" -lt 16 ]]; then
      INVALID_REQUIRED+=("phase net loads: expected at least 16 RO source-pin rows, got $data_rows")
      REQUIRED_RC=9
      REPORT_COMPLETE="NO"
    fi
    if ! grep -Eq ',(OK_STRICT|OK_CN|WARN_OVER_CN|FAIL_HIGH_LOAD|CRITICAL),' "$RESULT_DIR/reports/phase_net_loads.csv"; then
      INVALID_REQUIRED+=("phase net loads: no budget-classified rows found")
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
    echo "O11 required outputs/content check failed"
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
  echo "# O11 RO_tune4 Load Analysis Wrapper Summary"
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
  echo "- Labels: \`O11_RO_LOAD_ANALYSIS\`, \`REPORT_ONLY\`, \`NOT_FINAL_SIGNOFF\`"
  echo
  echo "## Key Outputs"
  if [[ "$RUN_MODE" == "validate_only" ]]; then
    echo "- validate_only: report CSVs are not generated because Innovus is not launched."
  else
    for path in \
      reports/SUMMARY.md \
      reports/report_clocks.rpt \
      reports/drv_max_cap.rpt \
      reports/phase_net_loads.csv \
      reports/phase_net_load_budget_summary.md \
      reports/fast_tag_loads.csv \
      reports/ro_phase_sink_classification.csv; do
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
