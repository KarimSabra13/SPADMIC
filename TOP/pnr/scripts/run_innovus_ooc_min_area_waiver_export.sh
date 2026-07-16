#!/usr/bin/env bash
# Export the exact four-marker packet-core state for provisional PVS DRC/LVS.
set +e

usage() {
  cat <<'USAGE'
Usage:
  TOP/pnr/scripts/run_innovus_ooc_min_area_waiver_export.sh \
    <source-block-root> <step27-analysis> [run-id] [top-module] [checkpoint]

This is a deliberate schedule exception, not DRC closure. The script restores
the original routed checkpoint once, replays the six validated base landing
edits, requires the exact four known MET1 minimum-area markers with zero
regular/special connectivity violations, records a narrow temporary waiver,
and exports mapped/merged GDS plus the power-ground netlist.

The waiver applies only to the four Innovus markers. It does not waive PVS DRC,
does not infer LVS MATCH, and does not authorize final signoff or promotion.
USAGE
}

report_value() {
  local report="$1"
  local key="$2"
  if [[ ! -r "$report" ]]; then
    printf '%s\n' MISSING
    return
  fi
  awk -F= -v key="$key" \
    '$1 == key {value = substr($0, index($0, "=") + 1)} END {print value}' \
    "$report"
}

main() {
  local script_dir repo_root source_root step27_analysis run_id top checkpoint
  local work_root run_root block_root stream_map stdcell_gds analysis_sha
  local innovus_rc gds_audit_rc final_rc gate_status gate_result
  local status_report waiver_report audit_report gate_report
  local output_base checkpoint_candidate

  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  repo_root="$(cd "$script_dir/../../.." && pwd)"
  source_root="${1:-}"
  step27_analysis="${2:-}"
  run_id="${3:-innovus_tx_packet_min_area_waiver_export_$(date +%Y%m%d_%H%M%S)}"
  top="${4:-spadmic_tx_packet_core}"
  checkpoint="${5:-}"
  work_root="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
  stream_map="${SPADMIC_STREAMOUT_MAP_FILE:-/eda/pdk/xfab/xh018/cadence/v10_1/PDK/IC61/v10_1_1/TECH_XH018_HD_1131/pnr_streamout.map}"
  stdcell_gds="${SPADMIC_STDCELL_GDS:-/data/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/gds_cdl/v6_0_0/gds/xh018_D_CELLS_JIHD.gds}"

  if [[ -z "$source_root" || -z "$step27_analysis" ]]; then
    usage >&2
    return 2
  fi
  if [[ "$top" != "spadmic_tx_packet_core" ]]; then
    echo "ERROR: provisional waiver export is approved only for spadmic_tx_packet_core" >&2
    return 6
  fi
  if [[ ! -d "$source_root" || ! -s "$step27_analysis" ]]; then
    echo "ERROR: source block root or Step 27 analysis is missing" >&2
    echo "SOURCE_BLOCK_ROOT=$source_root" >&2
    echo "STEP27_ANALYSIS=$step27_analysis" >&2
    return 6
  fi

  if [[ -z "$checkpoint" ]]; then
    for checkpoint_candidate in \
      "$source_root/checkpoints/05_postroute_export.enc.dat" \
      "$source_root/checkpoints/05_postroute_export.enc"
    do
      if [[ -e "$checkpoint_candidate" ]]; then
        checkpoint="$checkpoint_candidate"
        break
      fi
    done
  fi
  if [[ -z "$checkpoint" || ! -e "$checkpoint" ]]; then
    echo "ERROR: source routed checkpoint is missing" >&2
    return 6
  fi
  if [[ ! -s "$stream_map" || ! -s "$stdcell_gds" ]]; then
    echo "ERROR: stream map or required JIHD merge GDS is missing" >&2
    echo "STREAM_MAP=$stream_map" >&2
    echo "STDCELL_GDS=$stdcell_gds" >&2
    return 6
  fi
  if ! command -v innovus >/dev/null 2>&1; then
    echo "ERROR: innovus missing; source /eda/cadence/eda_2023-2024" >&2
    return 3
  fi

  run_root="$work_root/innovus/$run_id"
  block_root="$run_root/blocks/tx_packet_core"
  if [[ -e "$run_root" ]]; then
    echo "ERROR: immutable waiver export run already exists: $run_root" >&2
    return 2
  fi
  mkdir -p "$block_root"/{checkpoints,logs,outputs,reports}
  if [[ "$?" -ne 0 ]]; then
    echo "ERROR: cannot create waiver export root: $block_root" >&2
    return 6
  fi

  export SPADMIC_MIN_AREA_WAIVER_CHECKPOINT="$checkpoint"
  export SPADMIC_MIN_AREA_WAIVER_ROOT="$block_root"
  export SPADMIC_MIN_AREA_WAIVER_TOP="$top"
  export SPADMIC_MIN_AREA_WAIVER_STEP27_ANALYSIS="$step27_analysis"
  export SPADMIC_MIN_AREA_WAIVER_STREAM_MAP="$stream_map"
  export SPADMIC_MIN_AREA_WAIVER_STDCELL_GDS="$stdcell_gds"

  analysis_sha="$(sha256sum "$step27_analysis" 2>/dev/null | awk '{print $1}')"
  {
    echo "LABEL=SPADMIC_TX_PACKET_MIN_AREA_WAIVER_EXPORT_CONTEXT"
    echo "RUN_ID=$run_id"
    echo "SOURCE_BLOCK_ROOT=$source_root"
    echo "SOURCE_CHECKPOINT=$checkpoint"
    echo "STEP27_ANALYSIS=$step27_analysis"
    echo "STEP27_ANALYSIS_SHA256=${analysis_sha:-MISSING}"
    echo "TOP_MODULE=$top"
    echo "BLOCK_ROOT=$block_root"
    echo "HEAD=$(git -C "$repo_root" rev-parse HEAD 2>/dev/null)"
    echo "POLICY=ONE_FRESH_PROCESS_ONE_RESTORE_EXACT_SIX_BASE_EDITS_EXACT_FOUR_MARKER_WAIVER_EXPORT"
    echo "WAIVER_SCOPE=EXACT_FOUR_INNOVUS_MET1_MIN_AREA_ONLY"
    echo "PVS_DRC_WAIVER=NO"
    echo "LVS_DIAGNOSTIC_ONLY=YES"
    echo "FINAL_SIGNOFF_READY=NO"
  } >"$block_root/context.rpt"

  innovus -nowin \
    -init "$script_dir/run_innovus_ooc_min_area_waiver_export.tcl" \
    -log "$block_root/logs/innovus.log" \
    </dev/null \
    >"$block_root/logs/innovus.stdout.log" 2>&1
  innovus_rc=$?

  status_report="$block_root/reports/min_area_waiver_export_status.rpt"
  waiver_report="$block_root/reports/temporary_drc_waiver.rpt"
  audit_report="$block_root/reports/gds_export_audit.rpt"
  gate_report="$block_root/reports/canonical_tx_lvs_waiver_gate.rpt"
  output_base="$block_root/outputs/$top"
  gds_audit_rc=NOT_RUN

  if [[ "$innovus_rc" -eq 0 && -s "${output_base}.gds" ]]; then
    python3 "$script_dir/audit_innovus_gds_export.py" \
      --gds "${output_base}.gds" \
      --log "$block_root/logs/innovus.log" \
      --stream-map "$stream_map" \
      --required-merge "$stdcell_gds" \
      --status "$audit_report"
    gds_audit_rc=$?
  fi

  gate_status=FAIL
  gate_result=PROVISIONAL_WAIVER_EXPORT_NOT_ACCEPTED
  final_rc=8
  if [[ "$innovus_rc" -eq 0 \
      && "$gds_audit_rc" == "0" \
      && "$(report_value "$status_report" STATUS)" == "PASS" \
      && "$(report_value "$status_report" RESULT)" == "EXACT_FOUR_MARKER_WAIVER_STATE_EXPORTED_FOR_PROVISIONAL_PVS" \
      && "$(report_value "$status_report" FINAL_DRC_VIOLATION_COUNT)" == "4" \
      && "$(report_value "$status_report" FINAL_MIN_AREA_NETS)" == "n_9677 n_9693 n_9696 n_9697" \
      && "$(report_value "$status_report" FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT)" == "0" \
      && "$(report_value "$status_report" FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT)" == "0" \
      && "$(report_value "$waiver_report" STATUS)" == "PASS" \
      && "$(report_value "$waiver_report" WAIVER_MARKER_COUNT)" == "4" \
      && "$(report_value "$waiver_report" PVS_DRC_WAIVER)" == "NO" \
      && "$(report_value "$audit_report" STATUS)" == "PASS" \
      && -s "${output_base}.routed.pg.v" \
      && -s "${output_base}.abstract.lef" \
      && -s "${output_base}.def" ]]; then
    gate_status=PASS
    gate_result=READY_FOR_PROVISIONAL_PVS_DRC_LVS
    final_rc=0
  fi

  {
    echo "LABEL=SPADMIC_TX_PACKET_PROVISIONAL_PVS_WAIVER_GATE"
    echo "STATUS=$gate_status"
    echo "RESULT=$gate_result"
    echo "MACRO=$top"
    echo "BLOCK=tx_packet_core"
    echo "BLOCK_ROOT=$block_root"
    echo "SOURCE_CHECKPOINT=$checkpoint"
    echo "SOURCE_STEP27_ANALYSIS=$step27_analysis"
    echo "SOURCE_STEP27_ANALYSIS_SHA256=${analysis_sha:-MISSING}"
    echo "REPORT_DRIVER_HEAD=$(git -C "$repo_root" rev-parse HEAD 2>/dev/null)"
    echo "INNOVUS_RC=$innovus_rc"
    echo "GDS_AUDIT_RC=$gds_audit_rc"
    echo "WAIVER_SCOPE=EXACT_FOUR_INNOVUS_MET1_MIN_AREA_ONLY"
    echo "WAIVER_MARKER_COUNT=4"
    echo "WAIVER_NETS=n_9677 n_9693 n_9696 n_9697"
    echo "PVS_DRC_WAIVER=NO"
    echo "LVS_DIAGNOSTIC_ONLY=YES"
    echo "MANUAL_FIX_REQUIRED=YES"
    echo "BLOCK_PROMOTION_AUTHORIZED=NO"
    echo "FINAL_SIGNOFF_READY=NO"
    echo "GDS=${output_base}.gds"
    echo "NETLIST_PG=${output_base}.routed.pg.v"
    echo "LEF=${output_base}.abstract.lef"
    echo "DEF=${output_base}.def"
  } >"$gate_report"

  echo "MIN_AREA_WAIVER_EXPORT_INNOVUS_RC=$innovus_rc"
  echo "MIN_AREA_WAIVER_EXPORT_GDS_AUDIT_RC=$gds_audit_rc"
  echo "MIN_AREA_WAIVER_EXPORT_RC=$final_rc"
  echo "MIN_AREA_WAIVER_EXPORT_ROOT=$block_root"
  cat "$gate_report"
  if [[ -r "$status_report" ]]; then
    cat "$status_report"
  else
    echo "MISSING=$status_report"
    sed -n '1,320p' "$block_root/logs/innovus.stdout.log" 2>/dev/null
  fi
  return "$final_rc"
}

main "$@"
