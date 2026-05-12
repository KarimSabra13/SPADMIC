#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pnr_dir="$(cd "${script_dir}/.." && pwd)"
mptdc_dir="$(cd "${pnr_dir}/.." && pwd)"

tag="${1:-innovus_$(date +%Y%m%d_%H%M)_estimate}"
snapshot_dir="${mptdc_dir}/lab_snapshots/${tag}"

mkdir -p "${snapshot_dir}"

copy_if_present() {
  local src="$1"
  local dst="${snapshot_dir}/$(basename "$src")"
  if [[ -f "$src" ]]; then
    cp "$src" "$dst"
  fi
}

copy_as_if_present() {
  local src="$1"
  local dst="$2"
  if [[ -f "$src" ]]; then
    cp "$src" "${snapshot_dir}/${dst}"
  fi
}

latest_innovus_log=""
if [[ -d "${pnr_dir}/logs" ]]; then
  latest_innovus_log="$(
    find "${pnr_dir}/logs" -maxdepth 1 -type f -name 'innovus_estimate.log*' \
      -printf '%T@ %p\n' 2>/dev/null | sort -nr | awk 'NR==1 {$1=""; sub(/^ /, ""); print}'
  )"
fi

log_copy_note="Innovus log copied: none"
if [[ -n "${latest_innovus_log}" && -f "${latest_innovus_log}" ]]; then
  if [[ -f "${pnr_dir}/reports/run_status.rpt" && "${latest_innovus_log}" -ot "${pnr_dir}/reports/run_status.rpt" ]]; then
    log_copy_note="WARNING: newest Innovus log ($(basename "${latest_innovus_log}")) is older than run_status.rpt; not copying stale log."
  else
    copy_as_if_present "${latest_innovus_log}" "innovus_estimate_log.rpt"
    log_copy_note="Innovus log copied: $(basename "${latest_innovus_log}")"
  fi
else
  log_copy_note="WARNING: no Innovus log matching pnr/logs/innovus_estimate.log* was found."
fi

for file in \
  "${pnr_dir}/outputs/mptdc_top_asic.place.enc" \
  "${pnr_dir}/reports/run_status.rpt" \
  "${pnr_dir}/reports/run_manifest.rpt" \
  "${pnr_dir}/reports/pd_matrix_symmetry.rpt" \
  "${pnr_dir}/reports/report_area_place.rpt" \
  "${pnr_dir}/reports/report_gate_count_place.rpt" \
  "${pnr_dir}/reports/report_power_place.rpt"; do
  copy_if_present "$file"
done

if [[ -d "${pnr_dir}/reports/prects" ]]; then
  mkdir -p "${snapshot_dir}/prects"
  find "${pnr_dir}/reports/prects" -maxdepth 1 -type f -exec cp {} "${snapshot_dir}/prects/" \;
fi

if [[ -d "${pnr_dir}/reports/postroute" ]]; then
  mkdir -p "${snapshot_dir}/postroute"
  find "${pnr_dir}/reports/postroute" -maxdepth 1 -type f -exec cp {} "${snapshot_dir}/postroute/" \;
fi

{
  echo "Snapshot: ${tag}"
  echo "Created: $(date -Iseconds)"
  echo "Commit:  $(git -C "${mptdc_dir}" rev-parse --short HEAD 2>/dev/null || true)"
  if [[ -f "${pnr_dir}/reports/run_status.rpt" ]]; then
    echo "Run status: $(grep '^Status:' "${pnr_dir}/reports/run_status.rpt" | head -1 | cut -d: -f2- | xargs)"
  else
    echo "Run status: missing run_status.rpt"
  fi
  echo "${log_copy_note}"
  echo ""
  echo "Contents:"
  find "${snapshot_dir}" -maxdepth 2 -type f -printf "  %P\n" | sort
} > "${snapshot_dir}/manifest.txt"

echo "Snapshot written to ${snapshot_dir}"
