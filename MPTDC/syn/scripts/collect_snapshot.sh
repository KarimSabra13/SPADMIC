#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
syn_dir="$(cd "${script_dir}/.." && pwd)"
mptdc_dir="$(cd "${syn_dir}/.." && pwd)"
repo_root="$(cd "${mptdc_dir}/.." && pwd)"

tag="${1:-genus_$(date +%Y%m%d_%H%M)_qor}"
MPTDC_WORK_ROOT="${MPTDC_WORK_ROOT:-work}"
case "$MPTDC_WORK_ROOT" in
  /*) ;;
  *) MPTDC_WORK_ROOT="${repo_root}/${MPTDC_WORK_ROOT}" ;;
esac
MPTDC_EVIDENCE_WORK="${MPTDC_EVIDENCE_WORK:-${MPTDC_WORK_ROOT}/evidence}"
MPTDC_SNAPSHOT_ROOT="${MPTDC_SNAPSHOT_ROOT:-${MPTDC_EVIDENCE_WORK}}"
snapshot_dir="${MPTDC_SNAPSHOT_ROOT}/${tag}"
genus_run_dir="${MPTDC_GENUS_RUN_DIR:-}"
genus_tool_log="${MPTDC_GENUS_TOOL_LOG:-}"

if [[ -n "${genus_run_dir}" ]]; then
  source_outputs_dir="${genus_run_dir}/outputs"
  source_reports_dir="${genus_run_dir}/reports"
  source_logs_dir="${genus_run_dir}/logs"
else
  source_outputs_dir="${syn_dir}/outputs"
  source_reports_dir="${syn_dir}/reports"
  source_logs_dir="${syn_dir}/logs"
fi
source_synthesis_dir="${source_reports_dir}/synthesis"

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

if [[ -n "${genus_tool_log}" ]]; then
  copy_as_if_present "${genus_tool_log}" "genus_log.rpt"
else
  copy_as_if_present "${source_logs_dir}/genus.log" "genus_log.rpt"
fi

if [[ -d "${source_logs_dir}" ]]; then
  mkdir -p "${snapshot_dir}/logs"
  find "${source_logs_dir}" -maxdepth 1 -type f -exec cp {} "${snapshot_dir}/logs/" \;
fi

if [[ -d "${source_synthesis_dir}" ]]; then
  rm -rf "${snapshot_dir}/synthesis_reports"
  mkdir -p "${snapshot_dir}/synthesis_reports"
  cp -a "${source_synthesis_dir}/." "${snapshot_dir}/synthesis_reports/"
fi

for file in \
  "${source_outputs_dir}/mptdc_axis_core.postsyn.v" \
  "${source_outputs_dir}/mptdc_axis_core.postsyn.sdc" \
  "${source_outputs_dir}/mptdc_axis_core.postsyn.sdf" \
  "${source_synthesis_dir}/post_elaboration/check_design.rpt" \
  "${source_synthesis_dir}/post_elaboration/check_timing_intent.rpt" \
  "${source_synthesis_dir}/post_synthesis/timing_setup.rpt" \
  "${source_synthesis_dir}/post_synthesis/timing_summary.rpt" \
  "${source_synthesis_dir}/post_synthesis/timing_violations.rpt" \
  "${source_synthesis_dir}/post_synthesis/report_area.rpt" \
  "${source_synthesis_dir}/post_synthesis/report_area_hier.rpt" \
  "${source_synthesis_dir}/post_synthesis/report_gates.rpt" \
  "${source_synthesis_dir}/post_synthesis/report_gates_hier.rpt" \
  "${source_synthesis_dir}/post_synthesis/report_helpers_status.rpt" \
  "${source_synthesis_dir}/post_synthesis/report_power.rpt" \
  "${source_synthesis_dir}/post_synthesis/report_power_hier.rpt" \
  "${source_synthesis_dir}/post_synthesis/report_qor.rpt" \
  "${source_synthesis_dir}/post_synthesis/report_design_rules.rpt" \
  "${source_synthesis_dir}/post_synthesis/report_design_rules_verbose.rpt" \
  "${source_synthesis_dir}/post_synthesis/report_high_fanout.rpt" \
  "${source_synthesis_dir}/post_synthesis/report_clocks.rpt" \
  "${source_synthesis_dir}/post_synthesis/report_clocks_generated.rpt" \
  "${source_synthesis_dir}/post_synthesis/report_clock_groups.rpt" \
  "${source_synthesis_dir}/post_synthesis/report_exceptions.rpt" \
  "${source_synthesis_dir}/post_synthesis/report_constraints.rpt" \
  "${source_synthesis_dir}/post_synthesis/check_timing_intent_post_synth.rpt" \
  "${source_synthesis_dir}/post_synthesis/timing_osc_fast_full_clock.rpt" \
  "${source_synthesis_dir}/post_synthesis/timing_clk_sys_full_clock.rpt" \
  "${source_synthesis_dir}/post_synthesis/timing_clk_sys_violations.rpt" \
  "${source_synthesis_dir}/post_synthesis/timing_clk_sys_internal_top100.rpt" \
  "${source_synthesis_dir}/post_synthesis/timing_pd_capture_hotspots.rpt" \
  "${source_synthesis_dir}/post_synthesis/timing_pd_intentional_vernier.rpt" \
  "${source_synthesis_dir}/post_synthesis/pd_vernier_endpoint_discovery.rpt" \
  "${source_synthesis_dir}/post_synthesis/pd_vernier_source_discovery.rpt" \
  "${source_synthesis_dir}/post_synthesis/pd_vernier_exception_check.rpt" \
  "${source_synthesis_dir}/post_synthesis/timing_cdc_async_review.rpt" \
  "${source_synthesis_dir}/post_synthesis/timing_o13_phase_buffer_paths.rpt" \
  "${source_synthesis_dir}/post_synthesis/o13_clock_model_check.rpt" \
  "${source_synthesis_dir}/post_synthesis/timing_osc_counter_hotspots.rpt" \
  "${source_synthesis_dir}/post_synthesis/timing_meas_ctrl_hotspots.rpt" \
  "${source_synthesis_dir}/post_synthesis/timing_context_bank_hotspots.rpt" \
  "${source_synthesis_dir}/post_synthesis/timing_hit_capture_bridge_hotspots.rpt" \
  "${source_synthesis_dir}/post_synthesis/timing_drain_ctrl_hotspots.rpt" \
  "${source_synthesis_dir}/post_synthesis/timing_fifo_hotspots.rpt" \
  "${source_synthesis_dir}/post_synthesis/fast_domain_feasibility_audit.rpt" \
  "${source_synthesis_dir}/post_synthesis/latch_audit.rpt" \
  "${source_synthesis_dir}/post_synthesis/cdc_manual_audit.rpt" \
  "${source_synthesis_dir}/post_synthesis/run_manifest.rpt"; do
  copy_if_present "$file"
done

copy_if_present "${source_reports_dir}/helper_tcl_selftest.rpt"
copy_if_present "${source_reports_dir}/final_typical_genus_repair_1.rpt"
copy_if_present "${source_reports_dir}/fast_tag_exact_source_discovery.csv"
copy_if_present "${source_reports_dir}/fast_tag_exact_endpoint_discovery.csv"
copy_if_present "${source_reports_dir}/fast_tag_exact_path_pairs.csv"
copy_if_present "${source_reports_dir}/fast_tag_exact_source_cell_repair.csv"
copy_if_present "${source_reports_dir}/fast_tag_exact_repair_status.rpt"

{
  echo "Snapshot: ${tag}"
  echo "Created: $(date -Iseconds)"
  echo "Commit:  $(git -C "${mptdc_dir}" rev-parse --short HEAD 2>/dev/null || true)"
  echo ""
  echo "Contents:"
  find "${snapshot_dir}" -maxdepth 3 -type f -printf "  %P\n" | sort
} > "${snapshot_dir}/manifest.txt"

echo "Snapshot written to ${snapshot_dir}"
