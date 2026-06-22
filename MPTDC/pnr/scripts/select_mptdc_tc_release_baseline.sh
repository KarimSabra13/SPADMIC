#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$PNR_DIR/../.." && pwd)"

INNOVUS_ROOT="${MPTDC_INNOVUS_WORK:-/sim/ksabra/SPADMIC_work/innovus}"
OUT="${1:-$REPO_ROOT/reports/current_tc_release_baseline.rpt}"

status_value() {
  local file="$1"
  local key="$2"
  [[ -f "$file" ]] || return 0
  awk -F= -v key="$key" '
    $1 == key {
      split($2, a, /[[:space:]]+/)
      print a[1]
      exit
    }
  ' "$file"
}

manifest_head() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  awk '
    /^head:[[:space:]]*/ {print $2; exit}
    /^GIT_HEAD=/ {sub(/^GIT_HEAD=/, ""); print; exit}
  ' "$file"
}

run_complete_status() {
  local run_dir="$1"
  local status="$run_dir/reports/digital_pnr_signoff_status.rpt"
  local trace="$run_dir/manifests/stage_trace.csv"
  if [[ ! -f "$status" || ! -f "$trace" ]]; then
    echo "FAIL"
    return
  fi
  if grep -qi ',"[^"]*","fail"' "$trace"; then
    echo "FAIL"
    return
  fi
  if [[ "$(status_value "$status" MPTDC_TC_PNR_CLOSURE)" == "PASS" ]]; then
    echo "PASS"
  else
    echo "FAIL"
  fi
}

reject_reason() {
  local run_dir="$1"
  local reports="$run_dir/reports"
  local manifests="$run_dir/manifests"
  local checkpoint="$run_dir/checkpoints/04_route.enc.dat"
  local required=(
    "$manifests/run_manifest.txt"
    "$manifests/stage_trace.csv"
    "$reports/digital_pnr_signoff_status.rpt"
    "$reports/route_status.rpt"
    "$reports/route_recovery_status.rpt"
    "$reports/filler_status.rpt"
    "$reports/extracted_timing_status.rpt"
    "$reports/timing_tc_nominal.rpt"
    "$reports/timing_tc_hold.rpt"
    "$reports/cts_measured_status.rpt"
    "$reports/phase_rc_symmetry_status.rpt"
    "$reports/pd_physical_matrix_status.rpt"
    "$reports/pg_physical_status.rpt"
    "$checkpoint"
  )
  local file
  for file in "${required[@]}"; do
    if [[ ! -e "$file" ]]; then
      echo "missing:${file#$run_dir/}"
      return
    fi
  done

  local signoff="$reports/digital_pnr_signoff_status.rpt"
  local route="$reports/route_status.rpt"
  local filler="$reports/filler_status.rpt"
  local timing="$reports/extracted_timing_status.rpt"

  [[ "$(status_value "$signoff" MPTDC_TC_PNR_CLOSURE)" == "PASS" ]] || { echo "tc_pnr_not_pass"; return; }
  [[ "$(status_value "$route" ROUTE_STATUS)" == "PASS" ]] || { echo "route_not_pass"; return; }
  [[ "$(status_value "$filler" FILLER_INSERTION_STATUS)" == "PASS" ]] || { echo "filler_insert_not_pass"; return; }
  [[ "$(status_value "$signoff" FILLER_STATUS)" == "PASS" ]] || { echo "filler_status_not_pass"; return; }
  [[ "$(status_value "$signoff" EXTRACTION_STATUS)" == "PASS" ]] || { echo "extraction_not_pass"; return; }
  [[ "$(status_value "$timing" SETUP_STATUS_TC)" == "PASS" ]] || { echo "setup_not_pass"; return; }
  [[ "$(status_value "$timing" TC_HOLD_STATUS)" == "PASS" ]] || { echo "hold_not_pass"; return; }
  [[ "$(status_value "$signoff" DRV_STATUS)" == "PASS" ]] || { echo "drv_not_pass"; return; }
  [[ "$(run_complete_status "$run_dir")" == "PASS" ]] || { echo "incomplete_or_failed_trace"; return; }

  echo ""
}

if [[ ! -d "$INNOVUS_ROOT" ]]; then
  echo "ERROR: Innovus root not found: $INNOVUS_ROOT" >&2
  exit 2
fi

selected=""
selected_reason=""
while IFS= read -r entry; do
  run_dir="${entry#* }"
  reason="$(reject_reason "$run_dir")"
  if [[ -z "$reason" ]]; then
    selected="$run_dir"
    break
  fi
  if [[ -z "$selected_reason" ]]; then
    selected_reason="$(basename "$run_dir"):$reason"
  fi
done < <(find "$INNOVUS_ROOT" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' | sort -nr)

if [[ -z "$selected" ]]; then
  echo "ERROR: no complete TC release baseline found under $INNOVUS_ROOT" >&2
  if [[ -n "$selected_reason" ]]; then
    echo "LATEST_REJECTION=$selected_reason" >&2
  fi
  exit 1
fi

run_id="$(basename "$selected")"
reports="$selected/reports"
manifests="$selected/manifests"
checkpoint="$selected/checkpoints/04_route.enc.dat"
signoff="$reports/digital_pnr_signoff_status.rpt"
route="$reports/route_status.rpt"
filler="$reports/filler_status.rpt"
timing="$reports/extracted_timing_status.rpt"
cts="$reports/cts_measured_status.rpt"
phase="$reports/phase_rc_symmetry_status.rpt"

mkdir -p "$(dirname "$OUT")"
{
  echo "# MPTDC Current TC Release Baseline"
  echo "BASELINE_RUN_ID=$run_id"
  echo "BASELINE_RUN_DIR=$selected"
  echo "BASELINE_GIT_HEAD=$(manifest_head "$manifests/run_manifest.txt")"
  echo "BASELINE_CHECKPOINT=$checkpoint"
  echo "BASELINE_ROUTE_STATUS=$(status_value "$route" ROUTE_STATUS)"
  echo "BASELINE_FILLER_STATUS=$(status_value "$signoff" FILLER_STATUS)"
  echo "BASELINE_EXTRACTION_STATUS=$(status_value "$signoff" EXTRACTION_STATUS)"
  echo "BASELINE_SETUP_STATUS_TC=$(status_value "$timing" SETUP_STATUS_TC)"
  echo "BASELINE_HOLD_STATUS_TC=$(status_value "$timing" TC_HOLD_STATUS)"
  echo "BASELINE_DRV_STATUS=$(status_value "$signoff" DRV_STATUS)"
  echo "BASELINE_CTS_STATUS=$(status_value "$signoff" CTS_STATUS)"
  echo "BASELINE_CTS_MEASURED_STATUS=$(status_value "$cts" CTS_MEASURED_STATUS)"
  echo "BASELINE_RC_SYMMETRY_STATUS=$(status_value "$phase" RC_SYMMETRY_STATUS)"
  echo "BASELINE_DRC_STATUS=$(status_value "$signoff" DRC_STATUS)"
  echo "BASELINE_LVS_STATUS=$(status_value "$signoff" LVS_STATUS)"
  echo "BASELINE_COMPLETE_LOG_STATUS=$(run_complete_status "$selected")"
  echo "BASELINE_ROUTE_REPORT=$route"
  echo "BASELINE_FILLER_REPORT=$filler"
  echo "BASELINE_TIMING_STATUS_REPORT=$timing"
  echo "BASELINE_CTS_REPORT=$cts"
  echo "BASELINE_PHASE_RC_REPORT=$phase"
} > "$OUT"

cat "$OUT"
