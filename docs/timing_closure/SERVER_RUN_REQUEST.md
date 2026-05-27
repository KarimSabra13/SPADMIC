# SERVER RUN REQUEST

Run ID:

`20260527_0945_targeted_genus_reports`

Git branch:

`SPADMIC_TOP`

Git commit to run:

Use the exact SHA provided in the assistant final response for this patch. This
request file is committed with the patch it describes, so the self-hash cannot
be embedded in this file without changing the hash.

Purpose:

Rerun Genus after report-infrastructure and latch-audit cleanup only. This is
not an RTL timing patch. The goal is to extract actionable clk_sys, hotspot,
high-fanout, and DRV evidence before choosing H1/H3/H4.

Required tool(s):

- [x] Genus
- [ ] Innovus
- [ ] Xcelium

Before running:

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git status --short
git rev-parse HEAD
git log --oneline -5
```

Expected clean condition:

- `HEAD` must equal the exact SHA provided in the assistant final response for
  this patch.
- Working tree should be clean, except allowed local server environment files.

Commands:

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_TOP
git pull --ff-only
EXPECTED_HEAD=<SHA_FROM_ASSISTANT_FINAL_RESPONSE>
ACTUAL_HEAD="$(git rev-parse HEAD)"
test "$ACTUAL_HEAD" = "$EXPECTED_HEAD"
git status --short
git log --oneline -5
bash MPTDC/syn/scripts/server_run_genus_mptdc.sh 20260527_0945_targeted_genus_reports
```

Expected output directory:

```text
results/genus/20260527_0945_targeted_genus_reports/
MPTDC/lab_snapshots/genus_20260527_0945_targeted_genus_reports/
```

Expected key files:

- `results/genus/20260527_0945_targeted_genus_reports/SUMMARY.md`
- `results/genus/20260527_0945_targeted_genus_reports/PARSED_SUMMARY.md`
- `results/genus/20260527_0945_targeted_genus_reports/genus_20260527_0945_targeted_genus_reports.log`
- `results/genus/20260527_0945_targeted_genus_reports/timing_summary.rpt`
- `results/genus/20260527_0945_targeted_genus_reports/timing_violations.rpt`
- `results/genus/20260527_0945_targeted_genus_reports/timing_clk_sys_full_clock.rpt`
- `results/genus/20260527_0945_targeted_genus_reports/timing_clk_sys_violations.rpt`
- `results/genus/20260527_0945_targeted_genus_reports/timing_meas_ctrl_hotspots.rpt`
- `results/genus/20260527_0945_targeted_genus_reports/timing_context_bank_hotspots.rpt`
- `results/genus/20260527_0945_targeted_genus_reports/timing_hit_capture_bridge_hotspots.rpt`
- `results/genus/20260527_0945_targeted_genus_reports/timing_drain_ctrl_hotspots.rpt`
- `results/genus/20260527_0945_targeted_genus_reports/timing_fifo_hotspots.rpt`
- `results/genus/20260527_0945_targeted_genus_reports/report_design_rules.rpt`
- `results/genus/20260527_0945_targeted_genus_reports/report_design_rules_verbose.rpt`
- `results/genus/20260527_0945_targeted_genus_reports/report_high_fanout.rpt`
- `results/genus/20260527_0945_targeted_genus_reports/check_timing_intent.rpt`
- `results/genus/20260527_0945_targeted_genus_reports/latch_audit.rpt`
- `results/genus/20260527_0945_targeted_genus_reports/cdc_manual_audit.rpt`
- `results/genus/20260527_0945_targeted_genus_reports/report_clocks.rpt`
- `results/genus/20260527_0945_targeted_genus_reports/report_clocks_generated.rpt`
- `results/genus/20260527_0945_targeted_genus_reports/report_qor.rpt`
- `results/genus/20260527_0945_targeted_genus_reports/report_area.rpt`

Files to commit/push after run:

- `results/genus/20260527_0945_targeted_genus_reports/`
- `MPTDC/lab_snapshots/genus_20260527_0945_targeted_genus_reports/`

If run fails, still commit/push:

- `results/genus/20260527_0945_targeted_genus_reports/genus_20260527_0945_targeted_genus_reports.log`
- `results/genus/20260527_0945_targeted_genus_reports/run_manifest.txt`
- `results/genus/20260527_0945_targeted_genus_reports/SUMMARY.md`
- any partial reports copied into the result directory
- any partial `MPTDC/lab_snapshots/genus_20260527_0945_targeted_genus_reports/` contents
- the tool version/banner lines from the Genus log, if available

Post-run commit message suggestion:

```text
server-results: 20260527_0945_targeted_genus_reports Genus targeted reports
```
