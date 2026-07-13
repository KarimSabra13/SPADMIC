#!/usr/bin/env bash
# Restore one immutable checkpoint in a fresh process and capture PG reports.
set +e

usage() {
  cat <<'USAGE'
Usage:
  TOP/pnr/scripts/run_innovus_ooc_pg_probe.sh <source-root> [probe-id] [top-module] [checkpoint]

The default checkpoint search supports both OOC hardening runs and the older
TX DDR-strip PG-fix runs. If top-module is omitted, TOP_MODULE is read from
reports/ooc_harden_status.rpt, with spadmic_tx_ddr_strip as the legacy default.

Policy: one fresh Innovus process, one restoreDesign, report/query commands
only, and no modification of the source checkpoint or completed run.
USAGE
}

main() {
  local script_dir source_root run_id top checkpoint_override work_root checkpoint
  local probe_root rc candidate inferred_top
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source_root="${1:-}"
  run_id="${2:-pg_connectivity_probe_$(date +%Y%m%d_%H%M%S)}"
  top="${3:-}"
  checkpoint_override="${4:-}"
  work_root="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"

  if [[ -z "$source_root" ]]; then
    usage >&2
    return 2
  fi
  if [[ ! -d "$source_root" ]]; then
    echo "ERROR: source root missing: $source_root" >&2
    return 6
  fi

  if [[ -z "$top" && -r "$source_root/reports/ooc_harden_status.rpt" ]]; then
    inferred_top="$(awk -F= '$1 == "TOP_MODULE" {print substr($0, index($0, "=") + 1)}' "$source_root/reports/ooc_harden_status.rpt" | tail -n 1)"
    top="$inferred_top"
  fi
  top="${top:-spadmic_tx_ddr_strip}"

  checkpoint=""
  if [[ -n "$checkpoint_override" ]]; then
    checkpoint="$checkpoint_override"
  else
    for candidate in \
      "$source_root/checkpoints/05_postroute_export.enc.dat" \
      "$source_root/checkpoints/05_postroute_export.enc" \
      "$source_root/checkpoints/02_pg_verified_export.enc.dat" \
      "$source_root/checkpoints/02_pg_verified_export.enc"
    do
      if [[ -e "$candidate" ]]; then
        checkpoint="$candidate"
        break
      fi
    done
  fi
  if [[ -z "$checkpoint" || ! -e "$checkpoint" ]]; then
    echo "ERROR: supported PG checkpoint missing under $source_root/checkpoints" >&2
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

  export SPADMIC_PG_PROBE_CHECKPOINT="$checkpoint"
  export SPADMIC_PG_PROBE_ROOT="$probe_root"
  export SPADMIC_PG_PROBE_TOP="$top"

  {
    echo "RUN_ID=$run_id"
    echo "SOURCE_ROOT=$source_root"
    echo "SOURCE_CHECKPOINT=$checkpoint"
    echo "TOP_MODULE=$top"
    echo "PROBE_ROOT=$probe_root"
    echo "HEAD=$(git -C "$script_dir/../../.." rev-parse HEAD 2>/dev/null)"
    echo "POLICY=READ_ONLY_RESTORE_AND_REPORT"
    echo "DESIGN_MODIFICATION=NOT_RUN"
  } >"$probe_root/context.rpt"

  innovus -nowin -init "$script_dir/probe_innovus_ooc_pg_connectivity.tcl" \
    -log "$probe_root/logs/innovus.log" \
    >"$probe_root/logs/innovus.stdout.log" 2>&1
  rc=$?

  echo "PG_PROBE_RC=$rc"
  echo "PG_PROBE_ROOT=$probe_root"
  if [[ -r "$probe_root/reports/pg_probe_status.rpt" ]]; then
    cat "$probe_root/reports/pg_probe_status.rpt"
  else
    echo "MISSING=$probe_root/reports/pg_probe_status.rpt"
  fi
  return "$rc"
}

main "$@"
