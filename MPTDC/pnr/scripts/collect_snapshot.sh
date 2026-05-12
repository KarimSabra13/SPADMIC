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

for file in \
  "${pnr_dir}/logs/innovus_estimate.log" \
  "${pnr_dir}/outputs/mptdc_top_asic.place.enc" \
  "${pnr_dir}/reports/run_manifest.rpt" \
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
  echo ""
  echo "Contents:"
  find "${snapshot_dir}" -maxdepth 2 -type f -printf "  %P\n" | sort
} > "${snapshot_dir}/manifest.txt"

echo "Snapshot written to ${snapshot_dir}"
