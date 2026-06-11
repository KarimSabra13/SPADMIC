#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$PNR_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

RUN_ID=""
GENUS_RUN_ID="${MPTDC_GENUS_RUN_ID:-}"
GENUS_RUN_DIR="${MPTDC_GENUS_RUN_DIR:-}"
HANDOFF_DIR="${MPTDC_GENUS_HANDOFF_DIR:-}"
MODE="${MPTDC_FINAL_TYPICAL_MODE:-validate_only}"

usage() {
  cat <<'USAGE'
Usage:
  server_run_innovus_mptdc_final_typical.sh <PNR_RUN_ID> [options]

Options:
  --genus-run-id <id>     Required unless MPTDC_GENUS_RUN_ID is set.
  --genus-run-dir <path>  Required unless MPTDC_GENUS_RUN_DIR or run ID is set.
  --handoff-dir <path>    Optional explicit Genus handoff package.
  --mode <mode>           validate_only, place_prepare, or report_only.
  --validate-only         Alias for --mode validate_only.
  -h, --help              Show this help.

Default mode is validate_only. Modes that can launch Innovus require:

  MPTDC_FINAL_TYPICAL_APPROVED=1

This wrapper is a stable final-typical entrypoint and gate. It does not change
RTL and does not convert the run into MMMC or final silicon signoff.
USAGE
}

abs_path() {
  local path="$1"
  case "$path" in
    /*) printf '%s\n' "$path" ;;
    *) printf '%s/%s\n' "$REPO_ROOT" "$path" ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --genus-run-id)
      GENUS_RUN_ID="${2:?missing --genus-run-id value}"
      shift 2
      ;;
    --genus-run-dir)
      GENUS_RUN_DIR="$(abs_path "${2:?missing --genus-run-dir value}")"
      shift 2
      ;;
    --handoff-dir)
      HANDOFF_DIR="$(abs_path "${2:?missing --handoff-dir value}")"
      shift 2
      ;;
    --mode)
      MODE="${2:?missing --mode value}"
      shift 2
      ;;
    --validate-only)
      MODE="validate_only"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [[ -z "$RUN_ID" ]]; then
        RUN_ID="$1"
      else
        echo "ERROR: unexpected positional argument: $1" >&2
        usage >&2
        exit 2
      fi
      shift
      ;;
  esac
done

RUN_ID="${RUN_ID:-mptdc_final_typical_$(date +%Y%m%d_%H%M%S)}"

case "$MODE" in
  validate_only|place_prepare|report_only) ;;
  *)
    echo "ERROR: unsupported MPTDC_FINAL_TYPICAL_MODE=$MODE" >&2
    echo "Supported: validate_only, place_prepare, report_only" >&2
    exit 2
    ;;
esac

if [[ -z "$GENUS_RUN_ID" && -z "$GENUS_RUN_DIR" && -z "$HANDOFF_DIR" ]]; then
  echo "ERROR: explicit Genus source is required." >&2
  echo "Set MPTDC_GENUS_RUN_ID, MPTDC_GENUS_RUN_DIR, or pass --genus-run-id/--genus-run-dir." >&2
  exit 2
fi

MPTDC_WORK_ROOT="$(abs_path "${MPTDC_WORK_ROOT:-work}")"
MPTDC_INNOVUS_WORK="$(abs_path "${MPTDC_INNOVUS_WORK:-$MPTDC_WORK_ROOT/innovus}")"
export MPTDC_WORK_ROOT MPTDC_INNOVUS_WORK

RESULT_DIR="$MPTDC_INNOVUS_WORK/$RUN_ID"
LOG_DIR="$RESULT_DIR/logs"
MANIFEST_DIR="$RESULT_DIR/manifests"
mkdir -p "$LOG_DIR" "$MANIFEST_DIR"
RUN_LOG="$LOG_DIR/final_typical_wrapper.log"

GATE_ARGS=()
if [[ -n "$GENUS_RUN_ID" ]]; then
  GATE_ARGS+=(--genus-run-id "$GENUS_RUN_ID")
fi
if [[ -n "$GENUS_RUN_DIR" ]]; then
  GATE_ARGS+=(--genus-run-dir "$GENUS_RUN_DIR")
fi
if [[ -n "$HANDOFF_DIR" ]]; then
  GATE_ARGS+=(--handoff-dir "$HANDOFF_DIR")
fi

{
  echo "# MPTDC Innovus Final Typical Wrapper"
  echo "date: $(date -Iseconds)"
  echo "repo: $REPO_ROOT"
  echo "branch: $(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || true)"
  echo "head: $(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)"
  echo "run_id: $RUN_ID"
  echo "result_dir: $RESULT_DIR"
  echo "mode: $MODE"
  echo "mptdc_opt_mode: ${MPTDC_OPT_MODE:-STRIDE2}"
  echo "genus_run_id: ${GENUS_RUN_ID:-unset}"
  echo "genus_run_dir: ${GENUS_RUN_DIR:-unset}"
  echo "handoff_dir: ${HANDOFF_DIR:-unset}"
  echo "labels: TYPICAL_ONLY NOT_MMMC_SIGNOFF NOT_FINAL_SILICON_SIGNOFF"
  echo
  echo "git status --short --untracked-files=no:"
  git -C "$REPO_ROOT" status --short --untracked-files=no 2>/dev/null || true
} | tee "$MANIFEST_DIR/run_manifest.txt" | tee "$RUN_LOG"

echo "Running pre-PNR gate..." | tee -a "$RUN_LOG"
GATE_OUTPUT="$("$SCRIPT_DIR/check_mptdc_pre_pnr_gate.sh" "${GATE_ARGS[@]}" 2> >(tee -a "$RUN_LOG" >&2))"
echo "$GATE_OUTPUT" | tee -a "$RUN_LOG"
GATE_SOURCE="$(awk -F= '/^PRE_PNR_GATE_SOURCE=/ {print $2; exit}' <<<"$GATE_OUTPUT")"
GATE_STATUS="$(awk -F= '/^PRE_PNR_GATE=/ {print $2; exit}' <<<"$GATE_OUTPUT")"

if [[ "$GATE_STATUS" != "PASS" ]]; then
  echo "ERROR: pre-PNR gate did not pass without override: $GATE_STATUS" | tee -a "$RUN_LOG"
  exit 4
fi

require_file() {
  local label="$1"
  local path="$2"
  if [[ ! -f "$path" ]]; then
    echo "ERROR: missing $label: $path" | tee -a "$RUN_LOG"
    exit 2
  fi
}

for rel in \
  innovus_mptdc_floorplan.tcl \
  innovus_mptdc_backend_regions.tcl \
  innovus_mptdc_phase_buffer_place.tcl \
  innovus_mptdc_pd_matrix_place.tcl \
  innovus_mptdc_power.tcl \
  innovus_mptdc_cts.tcl \
  innovus_mptdc_reports.tcl \
  discover_xh018_physical_cells.sh
do
  require_file "$rel" "$SCRIPT_DIR/$rel"
done
require_file "XH018 physical-cell config" "$PNR_DIR/config/xh018_cells.tcl"
require_file "block IO constraints" "$PNR_DIR/constraints/mptdc_io_block_constraints.sdc"

if command -v tclsh >/dev/null 2>&1; then
  (
    cd "$REPO_ROOT"
    MPTDC_PNR_SOURCE_ONLY=1 tclsh <<'EOF'
source MPTDC/pnr/config/xh018_cells.tcl
source MPTDC/pnr/scripts/innovus_mptdc_floorplan.tcl
source MPTDC/pnr/scripts/innovus_mptdc_backend_regions.tcl
source MPTDC/pnr/scripts/innovus_mptdc_phase_buffer_place.tcl
source MPTDC/pnr/scripts/innovus_mptdc_pd_matrix_place.tcl
source MPTDC/pnr/scripts/innovus_mptdc_power.tcl
source MPTDC/pnr/scripts/innovus_mptdc_cts.tcl
source MPTDC/pnr/scripts/innovus_mptdc_reports.tcl
if {[mptdc_pnr_ro_load_preferred_ff] ne "58.72"} { error "RO preferred load limit changed" }
if {[mptdc_pnr_ro_load_warning_ff] ne "75.59"} { error "RO warning load limit changed" }
if {[mptdc_pnr_core_util_default] ne "0.55"} { error "core utilization default changed" }
if {[mptdc_pnr_cts_primary_clock] ne "clk_sys"} { error "CTS primary clock changed" }
if {[mptdc_xh018_cells_confirmed] ne "0"} { error "XH018 cells should start unconfirmed" }
puts "MPTDC final typical Tcl source validation passed"
EOF
  ) 2>&1 | tee -a "$RUN_LOG"
else
  echo "WARN: tclsh not found; skipping Tcl source validation" | tee -a "$RUN_LOG"
fi

echo "GATE_SOURCE=$GATE_SOURCE" >> "$MANIFEST_DIR/run_manifest.txt"
echo "PRE_PNR_GATE=$GATE_STATUS" >> "$MANIFEST_DIR/run_manifest.txt"

case "$MODE" in
  validate_only)
    echo "MPTDC_FINAL_TYPICAL_MODE=validate_only: gate and source checks passed; Innovus not launched." | tee -a "$RUN_LOG"
    exit 0
    ;;
  place_prepare)
    echo "MPTDC_FINAL_TYPICAL_MODE=place_prepare: Tcl hooks validated; Innovus not launched." | tee -a "$RUN_LOG"
    exit 0
    ;;
  report_only)
    if [[ "${MPTDC_FINAL_TYPICAL_APPROVED:-0}" != "1" ]]; then
      echo "ERROR: report_only can launch Innovus. Set MPTDC_FINAL_TYPICAL_APPROVED=1 after review." | tee -a "$RUN_LOG"
      exit 5
    fi
    export MPTDC_STABLE_FLOW_LABEL="MPTDC_INNOVUS_FINAL_TYPICAL"
    export FINAL_SIGNOFF="NO"
    export MPTDC_O13_MODE="report_only"
    exec "$SCRIPT_DIR/server_run_innovus_o13_phase_distribution.sh" "$RUN_ID"
    ;;
esac
