#!/usr/bin/env bash
# Run one isolated VDD via-stack method in one fresh Innovus process.
set +e

usage() {
  cat <<'USAGE'
Usage:
  TOP/pnr/scripts/run_innovus_ooc_pg_via_trial.sh \
    <source-root> <analysis-report> [mode] [trial-id] [top-module] [checkpoint]

Modes:
  via-only    Add adjacent-layer editPowerVia pairs only.
  patch-stack Add bounded MET2/MET3 VDD patches, then adjacent via pairs.

The trial restores once, modifies only the in-memory copy, and never calls
saveDesign, defOut, streamOut, or any netlist/LEF export command.
USAGE
}

main() {
  local script_dir source_root analysis mode run_id top checkpoint_override
  local work_root checkpoint candidate trial_root rc inferred_top
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source_root="${1:-}"
  analysis="${2:-}"
  mode="${3:-via-only}"
  run_id="${4:-pg_via_trial_${mode}_$(date +%Y%m%d_%H%M%S)}"
  top="${5:-}"
  checkpoint_override="${6:-}"
  work_root="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"

  if [[ -z "$source_root" || -z "$analysis" ]]; then
    usage >&2
    return 2
  fi
  if [[ "$mode" != "via-only" && "$mode" != "patch-stack" ]]; then
    echo "ERROR: unsupported mode: $mode" >&2
    return 2
  fi
  if [[ ! -d "$source_root" || ! -r "$analysis" ]]; then
    echo "ERROR: source root or analysis report missing" >&2
    echo "SOURCE_ROOT=$source_root" >&2
    echo "ANALYSIS_REPORT=$analysis" >&2
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
      "$source_root/checkpoints/05_postroute_export.enc.dat" \
      "$source_root/checkpoints/05_postroute_export.enc"
    do
      if [[ -e "$candidate" ]]; then
        checkpoint="$candidate"
        break
      fi
    done
  fi
  if [[ -z "$checkpoint" || ! -e "$checkpoint" ]]; then
    echo "ERROR: post-route checkpoint missing under $source_root/checkpoints" >&2
    return 6
  fi
  if ! command -v innovus >/dev/null 2>&1; then
    echo "ERROR: innovus missing; source /eda/cadence/eda_2023-2024" >&2
    return 3
  fi

  trial_root="$work_root/diagnostics/$run_id"
  if [[ -e "$trial_root" ]]; then
    echo "ERROR: immutable trial directory exists: $trial_root" >&2
    return 2
  fi
  mkdir -p "$trial_root"/{logs,reports}
  rc=$?
  if [[ "$rc" -ne 0 ]]; then
    echo "ERROR: cannot create trial root: $trial_root" >&2
    return "$rc"
  fi

  export SPADMIC_PG_VIA_TRIAL_CHECKPOINT="$checkpoint"
  export SPADMIC_PG_VIA_TRIAL_ROOT="$trial_root"
  export SPADMIC_PG_VIA_TRIAL_TOP="$top"
  export SPADMIC_PG_VIA_TRIAL_ANALYSIS="$analysis"
  export SPADMIC_PG_VIA_TRIAL_MODE="$mode"

  {
    echo "RUN_ID=$run_id"
    echo "SOURCE_ROOT=$source_root"
    echo "SOURCE_CHECKPOINT=$checkpoint"
    echo "ANALYSIS_REPORT=$analysis"
    echo "ANALYSIS_SHA256=$(sha256sum "$analysis" 2>/dev/null | awk '{print $1}')"
    echo "TOP_MODULE=$top"
    echo "MODE=$mode"
    echo "TRIAL_ROOT=$trial_root"
    echo "HEAD=$(git -C "$script_dir/../../.." rev-parse HEAD 2>/dev/null)"
    echo "POLICY=ONE_FRESH_PROCESS_ONE_RESTORE_IN_MEMORY_TRIAL"
    echo "SOURCE_CHECKPOINT_WRITE=NOT_RUN"
    echo "SAVE_DESIGN=NOT_RUN"
    echo "EXPORT=NOT_RUN"
  } >"$trial_root/context.rpt"

  innovus -nowin -init "$script_dir/run_innovus_ooc_pg_via_trial.tcl" \
    -log "$trial_root/logs/innovus.log" \
    >"$trial_root/logs/innovus.stdout.log" 2>&1
  rc=$?

  echo "PG_VIA_TRIAL_RC=$rc"
  echo "PG_VIA_TRIAL_ROOT=$trial_root"
  if [[ -r "$trial_root/reports/pg_via_trial_status.rpt" ]]; then
    cat "$trial_root/reports/pg_via_trial_status.rpt"
  else
    echo "MISSING=$trial_root/reports/pg_via_trial_status.rpt"
    sed -n '1,200p' "$trial_root/logs/innovus.stdout.log" 2>/dev/null
  fi
  return "$rc"
}

main "$@"
