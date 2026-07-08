#!/usr/bin/env bash
set -euo pipefail

INNOVUS_WORK="${MPTDC_INNOVUS_WORK:-/sim/ksabra/SPADMIC_work/innovus}"
RUN="${1:-}"

if [[ -z "$RUN" ]]; then
  RUN="$(ls -td "$INNOVUS_WORK"/*mptdc_ro6_latestlef_simplepg_* 2>/dev/null | head -1 || true)"
elif [[ "$RUN" != /* ]]; then
  RUN="$INNOVUS_WORK/$RUN"
fi

if [[ -z "$RUN" || ! -d "$RUN" ]]; then
  echo "ERROR: pass a run id or run directory, or create a latestlef simple-PG run first." >&2
  exit 2
fi

echo "RUN=$RUN"

show_file() {
  local path="$1"
  local lines="${2:-220}"
  echo
  echo "===== ${path#$RUN/} ====="
  if [[ -f "$path" ]]; then
    sed -n "1,${lines}p" "$path"
  else
    echo "MISSING"
  fi
}

show_grep() {
  local title="$1"
  local path="$2"
  local pattern="$3"
  echo
  echo "===== $title ====="
  if [[ -f "$path" ]]; then
    grep -nE "$pattern" "$path" || true
  else
    echo "MISSING"
  fi
}

show_file "$RUN/manifests/stage_trace.csv" 120
show_file "$RUN/manifests/run_manifest.txt" 220
show_file "$RUN/reports/digital_pnr_signoff_status.rpt" 220
show_file "$RUN/reports/block_pg_pin_status.rpt" 220
show_file "$RUN/reports/postplace_pre_route_sroute_status.rpt" 280
show_file "$RUN/reports/ro_pg_probe_before_hookup.rpt" 220
show_file "$RUN/reports/ro_pg_probe_after_hookup.rpt" 220
show_file "$RUN/reports/postplace_pre_route_pg_topology_after_sroute_verify_special.rpt" 220
show_file "$RUN/reports/route_status.rpt" 220
show_file "$RUN/reports/filler_status.rpt" 220
show_file "$RUN/reports/postroute_opt_status.rpt" 260
show_file "$RUN/reports/extracted_timing_status.rpt" 220
show_file "$RUN/reports/physical_verification_status.md" 220

show_grep "simple PG manifest knobs" "$RUN/manifests/run_manifest.txt" 'O1_RO_LEF_PATH|block_pg_pin_style|pg_strategy|allow_legacy_pg_topology|postplace_sroute_blockpin|ro_pg_hookup|stop_after_postplace_pre_route_sroute|free_all_internal_placement|fix_ro_macros|pnr_core_util'
show_grep "block PG pins" "$RUN/reports/block_pg_pin_status.rpt" 'BLOCK_PG_PIN_STATUS|BLOCK_PG_PIN_NAME|BLOCK_PG_PIN_NET|BLOCK_PG_PIN_STYLE'
show_grep "post-place sroute gate" "$RUN/reports/postplace_pre_route_sroute_status.rpt" 'POSTPLACE_PRE_ROUTE|SPECIAL_CONNECTIVITY|SROUTE_STATUS|GATE_ACTION|OPEN_PORTS|COMMAND_POSTPLACE'
show_grep "special connectivity detail" "$RUN/reports/postplace_pre_route_pg_topology_after_sroute_verify_special.rpt" 'Problem|unconnected|opens|short|dangling|Verification Complete'
show_grep "final status summary" "$RUN/reports/digital_pnr_signoff_status.rpt" 'PG_CONNECTIVITY_STATUS|ROUTE_STATUS|FILLER_STATUS|EXTRACTION_STATUS|POWER_STATUS|SETUP_STATUS|TC_HOLD_STATUS|DRC_STATUS|LVS_STATUS|READY_FOR_TAPEOUT|MPTDC_TC_PHYSICAL_SIGNOFF'
show_grep "fatal log lines" "$RUN/logs/digital_signoff_wrapper.log" 'ERROR|MPTDC_DIGITAL_SIGNOFF_ERROR|MPTDC_DIGITAL_SIGNOFF_STAGE_FAILED|Summary of all messages'

echo
echo "REPORT_DIR=$RUN/reports"
echo "LOG_DIR=$RUN/logs"
echo "MANIFEST_DIR=$RUN/manifests"
echo "Inspection complete."
