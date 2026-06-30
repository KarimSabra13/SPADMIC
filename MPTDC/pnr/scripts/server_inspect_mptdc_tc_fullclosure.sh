#!/usr/bin/env bash
set -euo pipefail

RUN="${1:-}"
if [[ -z "$RUN" ]]; then
  RUN="$(ls -td /sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_* 2>/dev/null | head -1 || true)"
fi

if [[ -z "$RUN" || ! -d "$RUN" ]]; then
  echo "ERROR: pass an Innovus run directory or create a matching full-closure run first." >&2
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
show_file "$RUN/reports/pre_pnr_gate.rpt" 220
show_file "$RUN/reports/digital_pnr_signoff_status.rpt" 220
show_file "$RUN/reports/pg_physical_status.rpt" 220
show_file "$RUN/reports/postplace_pre_route_sroute_status.rpt" 260
show_file "$RUN/reports/ro_pg_hookup_status.rpt" 220
show_file "$RUN/reports/pg_postroute_connectivity_status.rpt" 180
show_file "$RUN/reports/route_status.rpt" 220
show_file "$RUN/reports/route_recovery_status.rpt" 220
show_file "$RUN/reports/route_drc.rpt" 140
show_file "$RUN/reports/filler_status.rpt" 220
show_file "$RUN/reports/postroute_opt_status.rpt" 260
show_file "$RUN/reports/extracted_timing_status.rpt" 220
show_file "$RUN/reports/phase_rc_symmetry_status.rpt" 220
show_file "$RUN/reports/physical_verification_status.md" 220

show_grep "route DRC marker classes" "$RUN/reports/route_drc_markers.tsv" "Geometry|Connectivity|Short|Minimal_Area|MetSpc|UnConnectedPin"
show_grep "timing summary lines" "$RUN/reports/digital_pnr_signoff_status.rpt" "MPTDC_TC_PNR_CLOSURE|SETUP_STATUS_TC|TC_HOLD_STATUS|PG_CONNECTIVITY_STATUS|ROUTE_STATUS|DRC_STATUS|READY_FOR_TAPEOUT|NOT_MMMC"

echo
echo "Inspection complete."
