#!/usr/bin/env bash
# Attribute TX packet-core DRC/connectivity before any post-filler PG restitch.
set +e

usage() {
  cat <<'USAGE'
Usage:
  TOP/pnr/scripts/run_innovus_ooc_postfiller_stage_probe.sh \
    <source-block-root> [probe-id] [top-module] [checkpoint]

The probe restores the source run's post-CTS checkpoint once, records DRC and
connectivity, inserts the source run's canonical filler cells in memory, and
records the same evidence again before any post-filler sroute. It never saves,
exports, stages, or modifies the source checkpoint.
USAGE
}

main() {
  local script_dir source_root run_id top checkpoint_override work_root
  local checkpoint probe_root rc candidate inferred_top source_run_root source_run_head
  local filler_cells filler_command filler_mode_report filler_report

  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source_root="${1:-}"
  run_id="${2:-postfiller_stage_probe_$(date +%Y%m%d_%H%M%S)}"
  top="${3:-}"
  checkpoint_override="${4:-}"
  work_root="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
  filler_cells="FEED25JIHD FEED15JIHD FEED10JIHD FEED7JIHD FEED5JIHD FEED3JIHD FEED2JIHD FEED1JIHD"
  filler_command="addFiller -cell {$filler_cells} -prefix FILL"

  if [[ -z "$source_root" ]]; then
    usage >&2
    return 2
  fi
  if [[ ! -d "$source_root" ]]; then
    echo "ERROR: source block root missing: $source_root" >&2
    return 6
  fi

  filler_mode_report="$source_root/reports/FILLER_MODE.rpt"
  filler_report="$source_root/reports/ADD_FILLER.rpt"
  if [[ ! -r "$filler_mode_report" || ! -r "$filler_report" ]]; then
    echo "ERROR: source filler reports are missing" >&2
    echo "FILLER_MODE_REPORT=$filler_mode_report" >&2
    echo "ADD_FILLER_REPORT=$filler_report" >&2
    return 6
  fi
  if [[ "$(awk -F= '$1 == "STATUS" {value=$2} END {print value}' "$filler_mode_report")" != "PASS" ]] \
      || ! grep -Fq "REQUESTED_ADD_FILLERS_WITH_DRC=false" "$filler_mode_report"; then
    echo "ERROR: source run did not use the reviewed DRC-safe filler mode" >&2
    return 6
  fi
  if [[ "$(awk -F= '$1 == "STATUS" {value=$2} END {print value}' "$filler_report")" != "PASS" ]] \
      || ! grep -Fq "COMMAND=$filler_command" "$filler_report"; then
    echo "ERROR: source run did not use the canonical prefixed filler command" >&2
    echo "EXPECTED_COMMAND=$filler_command" >&2
    return 6
  fi

  if [[ -z "$top" && -r "$source_root/reports/ooc_harden_status.rpt" ]]; then
    inferred_top="$(awk -F= '$1 == "TOP_MODULE" {print substr($0, index($0, "=") + 1)}' "$source_root/reports/ooc_harden_status.rpt" | tail -n 1)"
    top="$inferred_top"
  fi
  top="${top:-spadmic_tx_packet_core}"

  checkpoint=""
  if [[ -n "$checkpoint_override" ]]; then
    checkpoint="$checkpoint_override"
  else
    for candidate in \
      "$source_root/checkpoints/03_cts.enc.dat" \
      "$source_root/checkpoints/03_cts.enc"
    do
      if [[ -e "$candidate" ]]; then
        checkpoint="$candidate"
        break
      fi
    done
  fi
  if [[ -z "$checkpoint" || ! -e "$checkpoint" ]]; then
    echo "ERROR: post-CTS checkpoint missing under $source_root/checkpoints" >&2
    return 6
  fi
  if ! command -v innovus >/dev/null 2>&1; then
    echo "ERROR: innovus missing; source /eda/cadence/eda_2023-2024" >&2
    return 3
  fi

  probe_root="$work_root/diagnostics/$run_id"
  if [[ -e "$probe_root" ]]; then
    echo "ERROR: immutable probe directory exists: $probe_root" >&2
    return 2
  fi
  mkdir -p "$probe_root"/{logs,reports}
  rc=$?
  if [[ "$rc" -ne 0 ]]; then
    echo "ERROR: cannot create probe root: $probe_root" >&2
    return "$rc"
  fi

  source_run_root="$(dirname "$(dirname "$source_root")")"
  source_run_head="$(awk -F= '$1 == "HEAD" {value=$2} END {print value}' "$source_run_root/run_manifest.txt" 2>/dev/null)"

  export SPADMIC_POSTFILLER_PROBE_CHECKPOINT="$checkpoint"
  export SPADMIC_POSTFILLER_PROBE_ROOT="$probe_root"
  export SPADMIC_POSTFILLER_PROBE_TOP="$top"
  export SPADMIC_POSTFILLER_PROBE_FILLER_CELLS="$filler_cells"

  {
    echo "RUN_ID=$run_id"
    echo "SOURCE_ROOT=$source_root"
    echo "SOURCE_RUN_ROOT=$source_run_root"
    echo "SOURCE_RUN_HEAD=${source_run_head:-UNKNOWN}"
    echo "SOURCE_CHECKPOINT=$checkpoint"
    echo "SOURCE_FILLER_MODE_REPORT=$filler_mode_report"
    echo "SOURCE_FILLER_MODE_REPORT_SHA256=$(sha256sum "$filler_mode_report" 2>/dev/null | awk '{print $1}')"
    echo "SOURCE_ADD_FILLER_REPORT=$filler_report"
    echo "SOURCE_ADD_FILLER_REPORT_SHA256=$(sha256sum "$filler_report" 2>/dev/null | awk '{print $1}')"
    echo "TOP_MODULE=$top"
    echo "FILLER_CELLS=$filler_cells"
    echo "FILLER_COMMAND=$filler_command"
    echo "PROBE_ROOT=$probe_root"
    echo "REPORT_DRIVER_HEAD=$(git -C "$script_dir/../../.." rev-parse HEAD 2>/dev/null)"
    echo "POLICY=ONE_FRESH_PROCESS_ONE_RESTORE_POST_CTS_FILLER_STAGE_ATTRIBUTION"
    echo "DESIGN_MODIFICATION=IN_MEMORY_FILLER_ONLY"
    echo "POST_FILLER_SROUTE=NOT_RUN"
    echo "SOURCE_CHECKPOINT_WRITE=NOT_RUN"
    echo "SAVE_DESIGN=NOT_RUN"
    echo "EXPORT=NOT_RUN"
    echo "PVS=NOT_RUN"
  } >"$probe_root/context.rpt"

  innovus -nowin -init "$script_dir/run_innovus_ooc_postfiller_stage_probe.tcl" \
    -log "$probe_root/logs/innovus.log" \
    </dev/null \
    >"$probe_root/logs/innovus.stdout.log" 2>&1
  rc=$?

  echo "POSTFILLER_STAGE_PROBE_RC=$rc"
  echo "POSTFILLER_STAGE_PROBE_ROOT=$probe_root"
  if [[ -r "$probe_root/reports/postfiller_stage_probe_status.rpt" ]]; then
    cat "$probe_root/reports/postfiller_stage_probe_status.rpt"
  else
    echo "MISSING=$probe_root/reports/postfiller_stage_probe_status.rpt"
    sed -n '1,240p' "$probe_root/logs/innovus.stdout.log" 2>/dev/null
  fi
  return "$rc"
}

main "$@"
