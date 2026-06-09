# Server Run Request: O13 abs3 Clock CDC Repair

Status: `READY_TO_RUN`

Run only Genus. Do not run Innovus or characterization from this request.

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_localtag
git pull --ff-only
git rev-parse HEAD

EXPECTED_HEAD="$(git rev-parse HEAD)" \
bash MPTDC/syn/scripts/server_run_genus_o13_abs3_clock_cdc_repair.sh \
  20260609_o13_abs3_clock_cdc_repair
```

After completion:

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
cat results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/SUMMARY.md
cat results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/o13_clock_model_check.rpt
cat results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/timing_path_classification_summary.md
cat results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/sdc_command_failures.md
```

Snapshot for GitHub:

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
mkdir -p results/github_snapshots
tar -czf results/github_snapshots/20260609_o13_abs3_clock_cdc_repair_evidence.tgz \
  results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/SUMMARY.md \
  results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/o13_phase_distribution_check.rpt \
  results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/o13_clock_model_check.rpt \
  results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/o13_clock_model_check.sdc.rpt \
  results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/report_clocks.rpt \
  results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/report_clocks_generated.rpt \
  results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/report_clock_groups.rpt \
  results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/report_exceptions.rpt \
  results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/check_timing_intent_post_synth.rpt \
  results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/timing_summary.rpt \
  results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/timing_violations.rpt \
  results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/timing_pd_capture_hotspots.rpt \
  results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/timing_clk_sys_violations.rpt \
  results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/timing_cdc_async_review.rpt \
  results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/timing_o13_phase_buffer_paths.rpt \
  results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/timing_path_classification.csv \
  results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/timing_path_classification_summary.md \
  results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/sdc_command_failures.md \
  results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/report_design_rules.rpt \
  results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/report_area.rpt \
  results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/report_qor.rpt \
  results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/genus_20260609_o13_abs3_clock_cdc_repair.log \
  results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/final_sdc_overlay_used.sdc \
  results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/final_filelist_used.f

cat > results/github_snapshots/20260609_o13_abs3_clock_cdc_repair_manifest.txt <<'EOF'
O13 abs3 clock/CDC repair Genus snapshot
RUN_ID=20260609_o13_abs3_clock_cdc_repair
Purpose: verify final buffer phase clocks are grouped async to clk_sys before Innovus
FINAL_SIGNOFF=NO
EOF

git add results/github_snapshots/20260609_o13_abs3_clock_cdc_repair_evidence.tgz \
  results/github_snapshots/20260609_o13_abs3_clock_cdc_repair_manifest.txt
git commit -m "server-results: O13 abs3 clock CDC repair snapshot"
git push origin SPADMIC_localtag
```
