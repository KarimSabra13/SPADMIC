#!/usr/bin/env bash
# Run a bounded iterative MET1 minimum-area repair in one fresh Innovus process.
set +e

usage() {
  cat <<'USAGE'
Usage:
  TOP/pnr/scripts/run_innovus_ooc_min_area_second_pass_trial.sh \
    <source-root> <step17-analysis> [trial-id] [top-module] [checkpoint]

The trial restores the final routed checkpoint once, modifies only the
in-memory copy, runs at most three repair iterations, and never calls a save or
export command.
USAGE
}

main() {
  local script_dir source_root analysis run_id top checkpoint_override
  local work_root checkpoint candidate trial_root inferred_top rc analysis_sha

  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source_root="${1:-}"
  analysis="${2:-}"
  run_id="${3:-min_area_second_pass_trial_$(date +%Y%m%d_%H%M%S)}"
  top="${4:-}"
  checkpoint_override="${5:-}"
  work_root="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"

  if [[ -z "$source_root" || -z "$analysis" ]]; then
    usage >&2
    return 2
  fi
  if [[ ! -d "$source_root" || ! -r "$analysis" ]]; then
    echo "ERROR: source root or Step 17 analysis is missing" >&2
    echo "SOURCE_ROOT=$source_root" >&2
    echo "STEP17_ANALYSIS=$analysis" >&2
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
    echo "ERROR: final routed checkpoint is missing under $source_root/checkpoints" >&2
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

  export SPADMIC_MIN_AREA_TRIAL_CHECKPOINT="$checkpoint"
  export SPADMIC_MIN_AREA_TRIAL_ROOT="$trial_root"
  export SPADMIC_MIN_AREA_TRIAL_TOP="$top"
  export SPADMIC_MIN_AREA_TRIAL_ANALYSIS="$analysis"
  export SPADMIC_MIN_AREA_TRIAL_ITERATION_LIMIT=3

  analysis_sha="$(sha256sum "$analysis" 2>/dev/null | awk '{print $1}')"
  {
    echo "RUN_ID=$run_id"
    echo "SOURCE_ROOT=$source_root"
    echo "SOURCE_CHECKPOINT=$checkpoint"
    echo "STEP17_ANALYSIS=$analysis"
    echo "STEP17_ANALYSIS_SHA256=${analysis_sha:-MISSING}"
    echo "TOP_MODULE=$top"
    echo "ITERATION_LIMIT=3"
    echo "TRIAL_ROOT=$trial_root"
    echo "HEAD=$(git -C "$script_dir/../../.." rev-parse HEAD 2>/dev/null)"
    echo "POLICY=ONE_FRESH_PROCESS_ONE_RESTORE_IN_MEMORY_TRIAL"
    echo "SOURCE_CHECKPOINT_WRITE=NOT_RUN"
    echo "SAVE_DESIGN=NOT_RUN"
    echo "EXPORT=NOT_RUN"
  } >"$trial_root/context.rpt"

  innovus -nowin \
    -init "$script_dir/run_innovus_ooc_min_area_second_pass_trial.tcl" \
    -log "$trial_root/logs/innovus.log" \
    </dev/null \
    >"$trial_root/logs/innovus.stdout.log" 2>&1
  rc=$?

  echo "MIN_AREA_SECOND_PASS_TRIAL_RC=$rc"
  echo "MIN_AREA_SECOND_PASS_TRIAL_ROOT=$trial_root"
  if [[ -r "$trial_root/reports/min_area_second_pass_trial_status.rpt" ]]; then
    cat "$trial_root/reports/min_area_second_pass_trial_status.rpt"
  else
    echo "MISSING=$trial_root/reports/min_area_second_pass_trial_status.rpt"
    sed -n '1,240p' "$trial_root/logs/innovus.stdout.log" 2>/dev/null
  fi
  return "$rc"
}

main "$@"
