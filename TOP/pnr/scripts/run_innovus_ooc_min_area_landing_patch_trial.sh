#!/usr/bin/env bash
# Run one isolated six-net MET1 landing-extension trial. No design is persisted.
set +e

usage() {
  cat <<'USAGE'
Usage:
  TOP/pnr/scripts/run_innovus_ooc_min_area_landing_patch_trial.sh \
    <source-root> <source-analysis> [trial-id] [top-module] [checkpoint]

The trial restores the final routed checkpoint once, validates the reviewed
six-net geometry contract, adds one bounded MET1 landing extension per net,
and captures independent DRC and connectivity evidence. It does not save,
export, stage immutable PVS inputs, or run PVS.

Set SPADMIC_MIN_AREA_LANDING_TRIAL_REVISION=R2 for the reviewed mixed-length
replay sourced from Step 21, R3 for the mixed-direction replay sourced from
Step 22, or R4 for the mixed-width replay sourced from Step 23. The default R1
contract remains the uniform 0.56 um Step 21 trial sourced from Step 20.
USAGE
}

main() {
  local script_dir source_root analysis run_id top checkpoint_override revision
  local analysis_label policy
  local work_root checkpoint candidate trial_root inferred_top rc analysis_sha

  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source_root="${1:-}"
  analysis="${2:-}"
  run_id="${3:-min_area_landing_patch_trial_$(date +%Y%m%d_%H%M%S)}"
  top="${4:-}"
  checkpoint_override="${5:-}"
  revision="${SPADMIC_MIN_AREA_LANDING_TRIAL_REVISION:-R1}"
  work_root="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"

  case "$revision" in
    R1)
      analysis_label=STEP20_ANALYSIS
      policy=ONE_FRESH_PROCESS_ONE_RESTORE_SIX_BOUNDED_MET1_LANDING_EXTENSIONS
      ;;
    R2)
      analysis_label=STEP21_ANALYSIS
      policy=ONE_FRESH_PROCESS_ONE_RESTORE_SIX_BOUNDED_MIXED_LENGTH_MET1_LANDING_EXTENSIONS
      ;;
    R3)
      analysis_label=STEP22_ANALYSIS
      policy=ONE_FRESH_PROCESS_ONE_RESTORE_SIX_BOUNDED_MIXED_DIRECTION_MET1_LANDING_EXTENSIONS
      ;;
    R4)
      analysis_label=STEP23_ANALYSIS
      policy=ONE_FRESH_PROCESS_ONE_RESTORE_SIX_BOUNDED_MIXED_WIDTH_MET1_LANDING_EXTENSIONS
      ;;
    *)
      echo "ERROR: unsupported landing-patch trial revision: $revision" >&2
      return 2
      ;;
  esac

  if [[ -z "$source_root" || -z "$analysis" ]]; then
    usage >&2
    return 2
  fi
  if [[ ! -d "$source_root" || ! -r "$analysis" ]]; then
    echo "ERROR: source root or source analysis is missing" >&2
    echo "SOURCE_ROOT=$source_root" >&2
    echo "$analysis_label=$analysis" >&2
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

  export SPADMIC_MIN_AREA_LANDING_CHECKPOINT="$checkpoint"
  export SPADMIC_MIN_AREA_LANDING_ROOT="$trial_root"
  export SPADMIC_MIN_AREA_LANDING_TOP="$top"
  export SPADMIC_MIN_AREA_LANDING_SOURCE_ANALYSIS="$analysis"
  export SPADMIC_MIN_AREA_LANDING_TRIAL_REVISION="$revision"

  analysis_sha="$(sha256sum "$analysis" 2>/dev/null | awk '{print $1}')"
  {
    echo "RUN_ID=$run_id"
    echo "SOURCE_ROOT=$source_root"
    echo "SOURCE_CHECKPOINT=$checkpoint"
    echo "$analysis_label=$analysis"
    echo "${analysis_label}_SHA256=${analysis_sha:-MISSING}"
    echo "TOP_MODULE=$top"
    echo "TRIAL_REVISION=$revision"
    echo "TRIAL_ROOT=$trial_root"
    echo "HEAD=$(git -C "$script_dir/../../.." rev-parse HEAD 2>/dev/null)"
    echo "POLICY=$policy"
    echo "DESIGN_MODIFICATION=IN_MEMORY_ONLY"
    echo "SOURCE_CHECKPOINT_WRITE=NOT_RUN"
    echo "SAVE_DESIGN=NOT_RUN"
    echo "EXPORT=NOT_RUN"
    echo "PVS=NOT_RUN"
  } >"$trial_root/context.rpt"

  innovus -nowin \
    -init "$script_dir/run_innovus_ooc_min_area_landing_patch_trial.tcl" \
    -log "$trial_root/logs/innovus.log" \
    </dev/null \
    >"$trial_root/logs/innovus.stdout.log" 2>&1
  rc=$?

  echo "MIN_AREA_LANDING_PATCH_TRIAL_RC=$rc"
  echo "MIN_AREA_LANDING_PATCH_TRIAL_ROOT=$trial_root"
  if [[ -r "$trial_root/reports/min_area_landing_patch_trial_status.rpt" ]]; then
    cat "$trial_root/reports/min_area_landing_patch_trial_status.rpt"
  else
    echo "MISSING=$trial_root/reports/min_area_landing_patch_trial_status.rpt"
    sed -n '1,260p' "$trial_root/logs/innovus.stdout.log" 2>/dev/null
  fi
  return "$rc"
}

main "$@"
