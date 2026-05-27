# SERVER RUN REQUEST

Run ID:

`20260527_0845_current_head_genus_baseline`

Git branch:

`SPADMIC_TOP`

Git commit to run:

`2972a0e7e50c0040ab0301e11508ff8ab9b71b97`

Purpose:

Fresh current-HEAD Genus baseline before any RTL timing patch. This run is
needed to classify current setup/DRV/latch/CDC evidence and decide whether H1
hit-count/context timing is still dominant.

Required tool(s):

- [x] Genus
- [ ] Innovus
- [ ] Xcelium

Before running:

```bash
cd /home/karim/SPADMIC
git status --short
git rev-parse HEAD
git log --oneline -5
```

Expected clean condition:

- `HEAD` must equal `2972a0e7e50c0040ab0301e11508ff8ab9b71b97`.
- Working tree should be clean except allowed local server environment files.

Commands:

```bash
cd /home/karim/SPADMIC
git checkout SPADMIC_TOP
git pull --ff-only
git status --short
git rev-parse HEAD
git log --oneline -5
bash MPTDC/syn/scripts/server_run_genus_mptdc.sh 20260527_0845_current_head_genus_baseline
```

Expected output directory:

```text
results/genus/20260527_0845_current_head_genus_baseline/
MPTDC/lab_snapshots/genus_20260527_0845_current_head_genus_baseline/
```

Expected key files:

- `results/genus/20260527_0845_current_head_genus_baseline/SUMMARY.md`
- `results/genus/20260527_0845_current_head_genus_baseline/genus_20260527_0845_current_head_genus_baseline.log`
- `results/genus/20260527_0845_current_head_genus_baseline/timing_violations.rpt`
- `results/genus/20260527_0845_current_head_genus_baseline/timing_summary.rpt`
- `results/genus/20260527_0845_current_head_genus_baseline/report_design_rules.rpt`
- `results/genus/20260527_0845_current_head_genus_baseline/check_timing_intent.rpt`
- `results/genus/20260527_0845_current_head_genus_baseline/latch_audit.rpt`
- `results/genus/20260527_0845_current_head_genus_baseline/cdc_manual_audit.rpt`
- `results/genus/20260527_0845_current_head_genus_baseline/timing_meas_ctrl_hotspots.rpt`
- `results/genus/20260527_0845_current_head_genus_baseline/timing_context_bank_hotspots.rpt`
- `results/genus/20260527_0845_current_head_genus_baseline/timing_drain_ctrl_hotspots.rpt`
- `results/genus/20260527_0845_current_head_genus_baseline/timing_fifo_hotspots.rpt`
- `results/genus/20260527_0845_current_head_genus_baseline/report_clocks.rpt`
- `results/genus/20260527_0845_current_head_genus_baseline/report_clocks_generated.rpt`
- `results/genus/20260527_0845_current_head_genus_baseline/report_constraints.rpt`
- `results/genus/20260527_0845_current_head_genus_baseline/report_qor.rpt`
- `results/genus/20260527_0845_current_head_genus_baseline/report_area.rpt`

Files to commit/push after run:

- `results/genus/20260527_0845_current_head_genus_baseline/`
- `MPTDC/lab_snapshots/genus_20260527_0845_current_head_genus_baseline/`

If run fails, still commit/push:

- `results/genus/20260527_0845_current_head_genus_baseline/genus_20260527_0845_current_head_genus_baseline.log`
- `results/genus/20260527_0845_current_head_genus_baseline/run_manifest.txt`
- `results/genus/20260527_0845_current_head_genus_baseline/SUMMARY.md`
- any partial reports copied into the result directory
- any partial `MPTDC/lab_snapshots/genus_20260527_0845_current_head_genus_baseline/` contents
- the tool version/banner lines from the Genus log, if available

Post-run commit message suggestion:

```text
server-results: 20260527_0845_current_head_genus_baseline Genus baseline
```
