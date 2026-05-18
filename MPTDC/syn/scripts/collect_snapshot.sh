#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
syn_dir="$(cd "${script_dir}/.." && pwd)"
mptdc_dir="$(cd "${syn_dir}/.." && pwd)"

tag="${1:-genus_$(date +%Y%m%d_%H%M)_qor}"
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

copy_as_if_present "${syn_dir}/logs/genus.log" "genus_log.rpt"

if [[ -d "${syn_dir}/logs" ]]; then
  mkdir -p "${snapshot_dir}/logs"
  find "${syn_dir}/logs" -maxdepth 1 -type f -exec cp {} "${snapshot_dir}/logs/" \;
fi

if [[ -d "${syn_dir}/reports/synthesis" ]]; then
  rm -rf "${snapshot_dir}/synthesis_reports"
  mkdir -p "${snapshot_dir}/synthesis_reports"
  cp -a "${syn_dir}/reports/synthesis/." "${snapshot_dir}/synthesis_reports/"
fi

for file in \
  "${syn_dir}/outputs/mptdc_top_asic.postsyn.v" \
  "${syn_dir}/outputs/mptdc_top_asic.postsyn.sdc" \
  "${syn_dir}/outputs/mptdc_top_asic.postsyn.sdf" \
  "${syn_dir}/reports/synthesis/post_elaboration/check_design.rpt" \
  "${syn_dir}/reports/synthesis/post_elaboration/check_timing_intent.rpt" \
  "${syn_dir}/reports/synthesis/post_synthesis/timing_setup.rpt" \
  "${syn_dir}/reports/synthesis/post_synthesis/timing_summary.rpt" \
  "${syn_dir}/reports/synthesis/post_synthesis/timing_violations.rpt" \
  "${syn_dir}/reports/synthesis/post_synthesis/report_area.rpt" \
  "${syn_dir}/reports/synthesis/post_synthesis/report_area_hier.rpt" \
  "${syn_dir}/reports/synthesis/post_synthesis/report_gates.rpt" \
  "${syn_dir}/reports/synthesis/post_synthesis/report_gates_hier.rpt" \
  "${syn_dir}/reports/synthesis/post_synthesis/report_power.rpt" \
  "${syn_dir}/reports/synthesis/post_synthesis/report_power_hier.rpt" \
  "${syn_dir}/reports/synthesis/post_synthesis/report_qor.rpt" \
  "${syn_dir}/reports/synthesis/post_synthesis/report_design_rules.rpt" \
  "${syn_dir}/reports/synthesis/post_synthesis/report_clocks.rpt" \
  "${syn_dir}/reports/synthesis/post_synthesis/report_clocks_generated.rpt" \
  "${syn_dir}/reports/synthesis/post_synthesis/report_constraints.rpt" \
  "${syn_dir}/reports/synthesis/post_synthesis/check_timing_intent_post_synth.rpt" \
  "${syn_dir}/reports/synthesis/post_synthesis/timing_osc_fast_full_clock.rpt" \
  "${syn_dir}/reports/synthesis/post_synthesis/timing_meas_ctrl_hotspots.rpt" \
  "${syn_dir}/reports/synthesis/post_synthesis/timing_context_bank_hotspots.rpt" \
  "${syn_dir}/reports/synthesis/post_synthesis/fast_domain_feasibility_audit.rpt" \
  "${syn_dir}/reports/synthesis/post_synthesis/latch_audit.rpt" \
  "${syn_dir}/reports/synthesis/post_synthesis/cdc_manual_audit.rpt" \
  "${syn_dir}/reports/synthesis/post_synthesis/run_manifest.rpt"; do
  copy_if_present "$file"
done

{
  echo "Snapshot: ${tag}"
  echo "Created: $(date -Iseconds)"
  echo "Commit:  $(git -C "${mptdc_dir}" rev-parse --short HEAD 2>/dev/null || true)"
  echo ""
  echo "Contents:"
  find "${snapshot_dir}" -maxdepth 3 -type f -printf "  %P\n" | sort
} > "${snapshot_dir}/manifest.txt"

echo "Snapshot written to ${snapshot_dir}"
