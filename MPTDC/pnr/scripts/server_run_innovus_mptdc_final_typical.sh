#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$PNR_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

RUN_ID=""
GENUS_HANDOFF_RUN="${MPTDC_GENUS_HANDOFF_RUN:-}"
GENUS_RUN_ID="${MPTDC_GENUS_RUN_ID:-$GENUS_HANDOFF_RUN}"
GENUS_RUN_DIR="${MPTDC_GENUS_RUN_DIR:-}"
HANDOFF_DIR="${MPTDC_GENUS_HANDOFF_DIR:-}"
MODE="${MPTDC_FINAL_TYPICAL_MODE:-validate_only}"
DENSITY_MODE="${MPTDC_FINAL_TYPICAL_DENSITY_MODE:-}"

usage() {
  cat <<'USAGE'
Usage:
  server_run_innovus_mptdc_final_typical.sh <PNR_RUN_ID> [options]

Options:
  --genus-run-id <id>     Required unless MPTDC_GENUS_RUN_ID is set.
  --genus-run-dir <path>  Required unless MPTDC_GENUS_RUN_DIR or run ID is set.
  --handoff-dir <path>    Optional explicit Genus handoff package.
  --mode <mode>           validate_only, place_prepare, report_only, or route_closure.
  --route-closure         Alias for --mode route_closure.
  --density-mode <mode>   PNR_DENSITY_60_DEFAULT, PNR_DENSITY_62_COMPACT, or PNR_DENSITY_65_CEILING.
  --validate-only         Alias for --mode validate_only.
  -h, --help              Show this help.

Default mode is validate_only. Modes that can launch Innovus require:

  MPTDC_FINAL_TYPICAL_APPROVED=1

Environment:
  MPTDC_GENUS_HANDOFF_RUN       Alias for the closed Genus run ID.
  MPTDC_FINAL_TYPICAL_DENSITY_MODE
                                PNR_DENSITY_60_DEFAULT, PNR_DENSITY_62_COMPACT,
                                or PNR_DENSITY_65_CEILING.
  MPTDC_PNR_CORE_UTIL           Explicit core utilization, capped at 0.65.
  MPTDC_PNR_MAX_DENSITY         Innovus local placement density cap. Default: 0.70.
  MPTDC_RUN_POSTROUTE_OPT       Default: 0. Set to 1 only for an explicitly
                                reviewed Innovus optimization experiment.
  MPTDC_PREPARE_GENUS_HANDOFF  Set to 0 to skip stable handoff materialization.
  MPTDC_PHASE_RC_ACCEPT_ASYMMETRY
                                Set to 1 only after owner review accepts the
                                O13 phase-RC asymmetry for this TC-only version.
  MPTDC_PHASE_RC_ACCEPT_REASON  Optional manifest/status reason for that review.

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

select_core_util() {
  local selected="${MPTDC_PNR_CORE_UTIL:-}"
  case "${DENSITY_MODE:-}" in
    "")
      selected="${selected:-0.60}"
      ;;
    PNR_DENSITY_60_DEFAULT|60|0.60)
      selected="0.60"
      ;;
    PNR_DENSITY_62_COMPACT|62|0.62)
      selected="0.62"
      ;;
    PNR_DENSITY_65_CEILING|65|0.65)
      selected="0.65"
      ;;
    *)
      echo "ERROR: unsupported MPTDC_FINAL_TYPICAL_DENSITY_MODE=$DENSITY_MODE" >&2
      echo "Supported: PNR_DENSITY_60_DEFAULT, PNR_DENSITY_62_COMPACT, PNR_DENSITY_65_CEILING" >&2
      return 2
      ;;
  esac
  if ! awk -v v="$selected" 'BEGIN { exit ((v + 0) >= 0.58 && (v + 0) <= 0.65 ? 0 : 1) }'; then
    echo "ERROR: MPTDC_PNR_CORE_UTIL=$selected is outside the approved 0.58..0.65 closure window." >&2
    echo "Do not run 70% core utilization in this flow without a new reviewed PNR policy." >&2
    return 2
  fi
  printf '%s\n' "$selected"
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
    --route-closure)
      MODE="route_closure"
      shift
      ;;
    --density-mode)
      DENSITY_MODE="${2:?missing --density-mode value}"
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

if [[ "${MPTDC_PHASE_RC_PARSE_ONLY:-0}" =~ ^(1|yes|true|on)$ ]]; then
  if [[ -z "${MPTDC_SIGNOFF_RESULT_DIR:-}" && -n "${ROUTE_CSV:-}" ]]; then
    route_reports_dir="$(cd "$(dirname "$ROUTE_CSV")" && pwd)"
    export MPTDC_SIGNOFF_RESULT_DIR="$(cd "$route_reports_dir/.." && pwd)"
  fi
  : "${MPTDC_SIGNOFF_RESULT_DIR:=$(abs_path "${MPTDC_WORK_ROOT:-work}/innovus/${RUN_ID}")}"
  export MPTDC_SIGNOFF_RESULT_DIR MPTDC_PHASE_RC_PARSE_ONLY
  if command -v tclsh >/dev/null 2>&1; then
    exec tclsh "$SCRIPT_DIR/innovus_mptdc_digital_signoff.tcl"
  fi
  exec innovus -nowin -init "$SCRIPT_DIR/innovus_mptdc_digital_signoff.tcl"
fi

case "$MODE" in
  validate_only|place_prepare|report_only|route_closure) ;;
  *)
    echo "ERROR: unsupported MPTDC_FINAL_TYPICAL_MODE=$MODE" >&2
    echo "Supported: validate_only, place_prepare, report_only, route_closure" >&2
    exit 2
    ;;
esac

MPTDC_PNR_CORE_UTIL="$(select_core_util)"
MPTDC_PNR_MAX_DENSITY="${MPTDC_PNR_MAX_DENSITY:-0.70}"
export MPTDC_PNR_CORE_UTIL MPTDC_PNR_MAX_DENSITY

if [[ -z "$GENUS_RUN_ID" && -z "$GENUS_RUN_DIR" && -z "$HANDOFF_DIR" ]]; then
  echo "ERROR: explicit Genus source is required." >&2
  echo "Set MPTDC_GENUS_HANDOFF_RUN, MPTDC_GENUS_RUN_ID, MPTDC_GENUS_RUN_DIR, or pass --genus-run-id/--genus-run-dir." >&2
  exit 2
fi

MPTDC_WORK_ROOT="$(abs_path "${MPTDC_WORK_ROOT:-work}")"
MPTDC_INNOVUS_WORK="$(abs_path "${MPTDC_INNOVUS_WORK:-$MPTDC_WORK_ROOT/innovus}")"
export MPTDC_WORK_ROOT MPTDC_INNOVUS_WORK
if [[ -n "$GENUS_HANDOFF_RUN" && -z "$HANDOFF_DIR" ]]; then
  HANDOFF_DIR="$MPTDC_WORK_ROOT/handoff/genus_typical/mptdc_genus_typical_closed"
fi

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
  echo "genus_handoff_run: ${GENUS_HANDOFF_RUN:-unset}"
  echo "genus_run_dir: ${GENUS_RUN_DIR:-unset}"
  echo "handoff_dir: ${HANDOFF_DIR:-unset}"
  echo "pnr_density_mode: ${DENSITY_MODE:-explicit_or_default}"
  echo "pnr_core_util: $MPTDC_PNR_CORE_UTIL"
  echo "pnr_max_density: $MPTDC_PNR_MAX_DENSITY"
  echo "pnr_core_util_allowed: 0.58..0.62 first-pass; 0.65 ceiling"
  echo "io_load_class: ${MPTDC_PNR_IO_LOAD_CLASS:-medium}"
  echo "run_clk_sys_cts: ${MPTDC_RUN_CLK_SYS_CTS:-1}"
  echo "run_postroute_opt: ${MPTDC_RUN_POSTROUTE_OPT:-0}"
  echo "place_pd_grid: ${MPTDC_PNR_PLACE_PD_GRID:-1}"
  echo "place_phase_buffers: ${MPTDC_PNR_PLACE_PHASE_BUFFERS:-1}"
  echo "place_fast_tags_by_column: ${MPTDC_PNR_PLACE_FAST_TAGS_BY_COLUMN:-1}"
  echo "physical_effort_enable: ${MPTDC_PNR_PHYSICAL_EFFORT_ENABLE:-1}"
  echo "physical_effort_mode: ${MPTDC_PNR_PHYSICAL_EFFORT_MODE:-closure}"
  echo "pnr_library: ${MPTDC_PNR_LIBRARY:-JIHD}"
  echo "phase_rc_accept_asymmetry: ${MPTDC_PHASE_RC_ACCEPT_ASYMMETRY:-0}"
  echo "phase_rc_accept_reason: ${MPTDC_PHASE_RC_ACCEPT_REASON:-unset}"
  echo "labels: TYPICAL_ONLY NOT_MMMC_SIGNOFF NOT_FINAL_SILICON_SIGNOFF"
  echo
  echo "git status --short --untracked-files=no:"
  git -C "$REPO_ROOT" status --short --untracked-files=no 2>/dev/null || true
} | tee "$MANIFEST_DIR/run_manifest.txt" | tee "$RUN_LOG"

if [[ -n "$GENUS_HANDOFF_RUN" && "${MPTDC_PREPARE_GENUS_HANDOFF:-1}" == "1" ]]; then
  echo "Preparing stable Genus handoff package..." | tee -a "$RUN_LOG"
  MPTDC_WORK_ROOT="$MPTDC_WORK_ROOT" \
  MPTDC_GENUS_HANDOFF_DIR="$HANDOFF_DIR" \
    "$SCRIPT_DIR/prepare_mptdc_genus_typical_handoff.sh" "$GENUS_HANDOFF_RUN" \
    2> >(tee -a "$RUN_LOG" >&2) | tee -a "$RUN_LOG"
fi

echo "Running pre-PNR gate..." | tee -a "$RUN_LOG"
GATE_OUTPUT="$("$SCRIPT_DIR/check_mptdc_pre_pnr_gate.sh" "${GATE_ARGS[@]}" 2> >(tee -a "$RUN_LOG" >&2))"
echo "$GATE_OUTPUT" | tee -a "$RUN_LOG"
GATE_SOURCE="$(awk -F= '/^PRE_PNR_GATE_SOURCE=/ {print $2; exit}' <<<"$GATE_OUTPUT")"
GATE_STATUS="$(awk -F= '/^PRE_PNR_GATE=/ {print $2; exit}' <<<"$GATE_OUTPUT")"
GENUS_WNS_MARGIN_LOW="$(awk -F= '/^GENUS_WNS_MARGIN_LOW=/ {print $2; exit}' <<<"$GATE_OUTPUT")"

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
  innovus_mptdc_physical_effort.tcl \
  innovus_mptdc_backend_regions.tcl \
  innovus_mptdc_phase_buffer_place.tcl \
  innovus_mptdc_pd_matrix_place.tcl \
  innovus_mptdc_power.tcl \
  innovus_mptdc_cts.tcl \
  innovus_mptdc_route.tcl \
  innovus_mptdc_postroute_opt.tcl \
  innovus_mptdc_reports.tcl \
  innovus_o10_io_pins.tcl \
  innovus_o10_power_grid.tcl \
  audit_def_io_pins.sh \
  audit_def_power_grid.sh \
  prepare_mptdc_genus_typical_handoff.sh \
  discover_xh018_physical_cells.sh \
  server_run_innovus_o10_2_pnr_repair.sh \
  server_run_innovus_o13_phase_distribution.sh
do
  require_file "$rel" "$SCRIPT_DIR/$rel"
done
require_file "XH018 physical-cell config" "$PNR_DIR/config/xh018_cells.tcl"
require_file "O13 phase-distribution Innovus SDC" "$PNR_DIR/constraints/mptdc_osc_typical_r750_delta5_o13_phase_distribution_innovus.sdc"
require_file "block IO constraints" "$PNR_DIR/constraints/mptdc_io_block_constraints.sdc"

find_source_file() {
  local root="$1"
  local rel="$2"
  local alt
  for alt in \
    "$root/$rel" \
    "$root/outputs/$rel" \
    "$root/outputs/post_synth/$rel" \
    "$root/05_outputs/$rel" \
    "$root/reports/$rel"; do
    if [[ -f "$alt" ]]; then
      printf '%s\n' "$alt"
      return 0
    fi
  done
  return 1
}

write_route_overlay() {
  local path="$RESULT_DIR/work/final_typical_route_overlay.sdc"
  local phase_overlay="${MPTDC_FINAL_TYPICAL_INNOVUS_SDC_OVERLAY:-$PNR_DIR/constraints/mptdc_osc_typical_r750_delta5_o13_phase_distribution_innovus.sdc}"
  local io_overlay="$PNR_DIR/constraints/mptdc_io_block_constraints.sdc"
  require_file "route phase overlay" "$phase_overlay"
  require_file "route IO overlay" "$io_overlay"
  mkdir -p "$(dirname "$path")"
  {
    echo "# Generated by server_run_innovus_mptdc_final_typical.sh"
    echo "# TYPICAL_ONLY NOT_MMMC_SIGNOFF NOT_FINAL_SILICON_SIGNOFF"
    printf 'source {%s}\n' "$phase_overlay"
    printf 'source {%s}\n' "$io_overlay"
  } > "$path"
  printf '%s\n' "$path"
}

write_final_closure_summary() {
  local o10_rc="$1"
  local o13_rc="$2"
  local o13_run_id="$3"
  local o13_result_dir="$4"
  local route_overlay="$5"
  local report_complete="NO"
  if [[ "$o10_rc" == "0" && "$o13_rc" == "0" ]]; then
    report_complete="YES"
  fi
  {
    echo "# MPTDC Final Typical PNR Closure Summary"
    echo
    echo "- Run ID: \`$RUN_ID\`"
    echo "- Mode: \`$MODE\`"
    echo "- Git HEAD: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)\`"
    echo "- Genus source: \`${GATE_SOURCE:-unknown}\`"
    echo "- Core utilization: \`$MPTDC_PNR_CORE_UTIL\`"
    echo "- Placement max density: \`$MPTDC_PNR_MAX_DENSITY\`"
    echo "- Route overlay: \`$route_overlay\`"
    echo "- O10 route wrapper exit code: $o10_rc"
    echo "- O13 report audit run: \`$o13_run_id\`"
    echo "- O13 report audit exit code: $o13_rc"
    echo "- REPORT_COMPLETE: \`$report_complete\`"
    echo "- Result directory: \`$RESULT_DIR\`"
    echo "- Labels: \`TYPICAL_ONLY\`, \`NOT_MMMC_SIGNOFF\`, \`NOT_FINAL_SILICON_SIGNOFF\`"
    echo
    echo "## Key Route Outputs"
    for rel in \
      reports/SUMMARY.md \
      reports/timing_post_route.rpt \
      reports/timing_post_route_summary_by_class.md \
      reports/timing_post_route_clk_sys_internal.rpt \
      reports/timing_post_route_ro_osc_domain.rpt \
      reports/drv_max_transition.rpt \
      reports/drv_max_cap.rpt \
      reports/drv_max_fanout.rpt \
      reports/io_pin_placement_summary.md \
      reports/io_pin_def_audit.rpt \
      reports/power_intent.rpt \
      reports/power_grid_status.rpt \
      reports/power_def_audit.rpt \
      reports/cts_status.rpt \
      reports/congestion.rpt \
      reports/route_summary.rpt \
      reports/antenna.rpt \
      def/04_route.def \
      checkpoints/04_route.enc.dat \
      checkpoints/restore_latest.tcl; do
      if [[ -s "$RESULT_DIR/$rel" || -e "$RESULT_DIR/$rel" ]]; then
        echo "- present: \`$rel\`"
      else
        echo "- missing: \`$rel\`"
      fi
    done
    echo
    echo "## O13 Audit Outputs"
    if [[ -n "$o13_result_dir" && -d "$o13_result_dir" ]]; then
      for rel in \
        SUMMARY.md \
        reports/phase_buffer_balance_summary.md \
        reports/phase_buffer_topology_summary.md \
        reports/phase_buffer_output_loads.csv \
        reports/ro_phase_raw_pin_loads.csv \
        reports/timing_post_route_summary_by_class.md; do
        if [[ -s "$o13_result_dir/$rel" ]]; then
          echo "- present: \`$o13_run_id/$rel\`"
        else
          echo "- missing: \`$o13_run_id/$rel\`"
        fi
      done
    else
      echo "- skipped: O13 audit was not run"
    fi
    echo
    echo "This is a typical-only block PNR closure package. It is not MMMC signoff and not final silicon signoff."
  } > "$RESULT_DIR/SUMMARY.md"
  cp "$RESULT_DIR/SUMMARY.md" "$RESULT_DIR/FINAL_TYPICAL_CLOSURE_SUMMARY.md"
}

run_route_closure() {
  if [[ "${MPTDC_FINAL_TYPICAL_APPROVED:-0}" != "1" ]]; then
    echo "ERROR: route_closure launches Innovus. Set MPTDC_FINAL_TYPICAL_APPROVED=1 after review." | tee -a "$RUN_LOG"
    exit 5
  fi
  if [[ -z "${GATE_SOURCE:-}" || ! -d "$GATE_SOURCE" ]]; then
    echo "ERROR: pre-PNR gate source directory is unavailable: ${GATE_SOURCE:-unset}" | tee -a "$RUN_LOG"
    exit 4
  fi

  local netlist postsyn_sdc route_overlay o10_rc o13_rc o13_run_id o13_result_dir
  if ! netlist="$(find_source_file "$GATE_SOURCE" mptdc_axis_core.postsyn.v)"; then
    echo "ERROR: missing routed netlist in gate source: $GATE_SOURCE" | tee -a "$RUN_LOG"
    exit 2
  fi
  if ! postsyn_sdc="$(find_source_file "$GATE_SOURCE" mptdc_axis_core.postsyn.sdc)"; then
    echo "ERROR: missing routed SDC in gate source: $GATE_SOURCE" | tee -a "$RUN_LOG"
    exit 2
  fi
  route_overlay="$(write_route_overlay)"
  echo "Using closure netlist: $netlist" | tee -a "$RUN_LOG"
  echo "Using closure SDC: $postsyn_sdc" | tee -a "$RUN_LOG"
  echo "Using generated route overlay: $route_overlay" | tee -a "$RUN_LOG"

  set +e
  MPTDC_INNOVUS_WORK="$MPTDC_INNOVUS_WORK" \
  MPTDC_O10_RESULT_DIR="$RESULT_DIR" \
  MPTDC_O10_2_MODE=route_feasibility \
  MPTDC_O10_NETLIST="$netlist" \
  MPTDC_O10_POSTSYN_SDC="$postsyn_sdc" \
  MPTDC_O10_SDC_OVERLAY="$route_overlay" \
  MPTDC_O10_RUN_CLK_SYS_CTS="${MPTDC_RUN_CLK_SYS_CTS:-1}" \
  MPTDC_O10_RUN_POSTROUTE_OPT="${MPTDC_RUN_POSTROUTE_OPT:-0}" \
  MPTDC_STDCELL_FAMILY="${MPTDC_STDCELL_FAMILY:-${MPTDC_PNR_LIBRARY:-JIHD}}" \
  MPTDC_PNR_CORE_UTIL="$MPTDC_PNR_CORE_UTIL" \
  MPTDC_PNR_MAX_DENSITY="$MPTDC_PNR_MAX_DENSITY" \
  MPTDC_PNR_PHYSICAL_EFFORT_ENABLE="${MPTDC_PNR_PHYSICAL_EFFORT_ENABLE:-1}" \
  MPTDC_PNR_PHYSICAL_EFFORT_MODE="${MPTDC_PNR_PHYSICAL_EFFORT_MODE:-closure}" \
  MPTDC_PNR_IO_LOAD_CLASS="${MPTDC_PNR_IO_LOAD_CLASS:-medium}" \
  EXPECTED_HEAD="${EXPECTED_HEAD:-$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)}" \
    "$SCRIPT_DIR/server_run_innovus_o10_2_pnr_repair.sh" "$RUN_ID" \
    2> >(tee -a "$RUN_LOG" >&2) | tee -a "$RUN_LOG"
  o10_rc=${PIPESTATUS[0]}
  set -e

  o13_rc=0
  o13_run_id="${RUN_ID}_o13_phase_report"
  o13_result_dir="$MPTDC_INNOVUS_WORK/$o13_run_id"
  if [[ "$o10_rc" == "0" && "${MPTDC_FINAL_TYPICAL_RUN_O13_AUDIT:-1}" == "1" ]]; then
    set +e
    MPTDC_INNOVUS_WORK="$MPTDC_INNOVUS_WORK" \
    MPTDC_O13_MODE=report_only \
    MPTDC_O13_SOURCE_RUN_ID="$RUN_ID" \
    MPTDC_O13_SOURCE_RESULT_DIR="$RESULT_DIR" \
    MPTDC_O13_SOURCE_CHECKPOINT_DAT="$RESULT_DIR/checkpoints/04_route.enc.dat" \
    MPTDC_O13_SOURCE_RESTORE_TCL="$RESULT_DIR/checkpoints/restore_latest.tcl" \
    MPTDC_PNR_IO_LOAD_CLASS="${MPTDC_PNR_IO_LOAD_CLASS:-medium}" \
    EXPECTED_HEAD="${EXPECTED_HEAD:-$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)}" \
      "$SCRIPT_DIR/server_run_innovus_o13_phase_distribution.sh" "$o13_run_id" \
      2> >(tee -a "$RUN_LOG" >&2) | tee -a "$RUN_LOG"
    o13_rc=${PIPESTATUS[0]}
    set -e
  elif [[ "${MPTDC_FINAL_TYPICAL_RUN_O13_AUDIT:-1}" != "1" ]]; then
    o13_rc=0
    o13_run_id="SKIPPED_BY_MPTDC_FINAL_TYPICAL_RUN_O13_AUDIT"
    o13_result_dir=""
  else
    o13_rc=98
    echo "Skipping O13 audit because O10 route wrapper failed with rc=$o10_rc" | tee -a "$RUN_LOG"
  fi

  write_final_closure_summary "$o10_rc" "$o13_rc" "$o13_run_id" "$o13_result_dir" "$route_overlay"
  cat "$RESULT_DIR/SUMMARY.md"

  if [[ "$o10_rc" != "0" ]]; then
    exit "$o10_rc"
  fi
  if [[ "$o13_rc" != "0" ]]; then
    exit "$o13_rc"
  fi
}

if command -v tclsh >/dev/null 2>&1; then
  (
    cd "$REPO_ROOT"
    MPTDC_PNR_SOURCE_ONLY=1 tclsh <<'EOF'
source MPTDC/pnr/config/xh018_cells.tcl
source MPTDC/pnr/scripts/innovus_mptdc_floorplan.tcl
source MPTDC/pnr/scripts/innovus_mptdc_physical_effort.tcl
source MPTDC/pnr/scripts/innovus_mptdc_backend_regions.tcl
source MPTDC/pnr/scripts/innovus_mptdc_phase_buffer_place.tcl
source MPTDC/pnr/scripts/innovus_mptdc_pd_matrix_place.tcl
source MPTDC/pnr/scripts/innovus_mptdc_power.tcl
source MPTDC/pnr/scripts/innovus_mptdc_cts.tcl
source MPTDC/pnr/scripts/innovus_mptdc_route.tcl
source MPTDC/pnr/scripts/innovus_mptdc_postroute_opt.tcl
source MPTDC/pnr/scripts/innovus_mptdc_reports.tcl
source MPTDC/pnr/scripts/innovus_o10_io_pins.tcl
source MPTDC/pnr/scripts/innovus_o10_power_grid.tcl
if {[mptdc_pnr_ro_load_preferred_ff] ne "58.72"} { error "RO preferred load limit changed" }
if {[mptdc_pnr_ro_load_warning_ff] ne "75.59"} { error "RO warning load limit changed" }
if {[mptdc_pnr_core_util_default] ne "0.60"} { error "core utilization default changed" }
if {[mptdc_pnr_core_util_max_first_run] ne "0.65"} { error "core utilization max changed" }
if {[mptdc_pnr_cts_primary_clock] ne "clk_sys"} { error "CTS primary clock changed" }
if {[mptdc_pnr_route_signal_top_layer] ne "MET4"} { error "signal top route layer changed" }
if {[dict get [mptdc_pnr_route_effective_top_layer [mptdc_pnr_route_signal_top_layer]] top] ne "METTP"} { error "effective route top floor changed" }
if {[mptdc_pnr_postroute_opt_enabled] ne "0"} { error "postroute optimization default changed" }
if {[lsearch -exact [mptdc_pnr_required_reports] fast_tag_to_pd_route_lengths.csv] < 0} { error "missing fast-tag route-length report requirement" }
if {[lsearch -exact [mptdc_pnr_required_reports] cts_clock_inclusion_audit.rpt] < 0} { error "missing CTS audit report requirement" }
if {[lsearch -exact [mptdc_pnr_required_reports] physical_verification_status.md] < 0} { error "missing physical verification report requirement" }
if {[mptdc_xh018_cells_confirmed] ne "0"} { error "XH018 cells should start unconfirmed" }
puts "MPTDC final typical Tcl source validation passed"
EOF
  ) 2>&1 | tee -a "$RUN_LOG"
else
  echo "WARN: tclsh not found; skipping Tcl source validation" | tee -a "$RUN_LOG"
fi

echo "GATE_SOURCE=$GATE_SOURCE" >> "$MANIFEST_DIR/run_manifest.txt"
echo "PRE_PNR_GATE=$GATE_STATUS" >> "$MANIFEST_DIR/run_manifest.txt"
echo "GENUS_WNS_MARGIN_LOW=${GENUS_WNS_MARGIN_LOW:-UNKNOWN}" >> "$MANIFEST_DIR/run_manifest.txt"

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
  route_closure)
    run_route_closure
    ;;
esac
