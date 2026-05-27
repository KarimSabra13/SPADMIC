# SERVER RUN REQUEST

Run ID:

`20260527_1030_h1_drain_pipeline`

Git branch:

`SPADMIC_TOP`

Git commit to run:

Use the exact SHA provided in the assistant final response for this patch. This
request file is committed with the patch it describes, so the self-hash cannot
be embedded in this file without changing the hash.

Purpose:

Validate the focused clk_sys backend timing patch:

- H1/H2: register final hit-count/flags before context publication.
- H4: remove the drain-controller IDLE pre-point context-read mux from the wide
  pending-record construction cone.

Required tool(s):

- [x] Genus
- [ ] Innovus
- [x] Xcelium

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

bash MPTDC/syn/scripts/server_run_genus_mptdc.sh 20260527_1030_h1_drain_pipeline_genus
bash MPTDC/sim/xcelium/server_run_xcelium_mptdc.sh 20260527_1030_h1_drain_pipeline_xcelium
```

Expected output directories:

```text
results/genus/20260527_1030_h1_drain_pipeline_genus/
MPTDC/lab_snapshots/genus_20260527_1030_h1_drain_pipeline_genus/
results/xcelium/20260527_1030_h1_drain_pipeline_xcelium/
```

Expected Genus key files:

- `results/genus/20260527_1030_h1_drain_pipeline_genus/SUMMARY.md`
- `results/genus/20260527_1030_h1_drain_pipeline_genus/PARSED_SUMMARY.md`
- `results/genus/20260527_1030_h1_drain_pipeline_genus/genus_20260527_1030_h1_drain_pipeline_genus.log`
- `results/genus/20260527_1030_h1_drain_pipeline_genus/timing_summary.rpt`
- `results/genus/20260527_1030_h1_drain_pipeline_genus/timing_clk_sys_violations.rpt`
- `results/genus/20260527_1030_h1_drain_pipeline_genus/timing_meas_ctrl_hotspots.rpt`
- `results/genus/20260527_1030_h1_drain_pipeline_genus/timing_context_bank_hotspots.rpt`
- `results/genus/20260527_1030_h1_drain_pipeline_genus/timing_drain_ctrl_hotspots.rpt`
- `results/genus/20260527_1030_h1_drain_pipeline_genus/timing_fifo_hotspots.rpt`
- `results/genus/20260527_1030_h1_drain_pipeline_genus/report_design_rules.rpt`
- `results/genus/20260527_1030_h1_drain_pipeline_genus/report_design_rules_verbose.rpt`
- `results/genus/20260527_1030_h1_drain_pipeline_genus/report_high_fanout.rpt`
- `results/genus/20260527_1030_h1_drain_pipeline_genus/check_timing_intent.rpt`
- `results/genus/20260527_1030_h1_drain_pipeline_genus/latch_audit.rpt`
- `results/genus/20260527_1030_h1_drain_pipeline_genus/cdc_manual_audit.rpt`
- `results/genus/20260527_1030_h1_drain_pipeline_genus/report_clocks.rpt`
- `results/genus/20260527_1030_h1_drain_pipeline_genus/report_clocks_generated.rpt`
- `results/genus/20260527_1030_h1_drain_pipeline_genus/report_constraints.rpt`
- `results/genus/20260527_1030_h1_drain_pipeline_genus/report_qor.rpt`
- `results/genus/20260527_1030_h1_drain_pipeline_genus/report_area.rpt`

Expected Xcelium key files:

- `results/xcelium/20260527_1030_h1_drain_pipeline_xcelium/SUMMARY.md`
- `results/xcelium/20260527_1030_h1_drain_pipeline_xcelium/run_manifest.txt`
- `results/xcelium/20260527_1030_h1_drain_pipeline_xcelium/test_summary.txt`
- `results/xcelium/20260527_1030_h1_drain_pipeline_xcelium/xcelium_20260527_1030_h1_drain_pipeline_xcelium.log`
- `results/xcelium/20260527_1030_h1_drain_pipeline_xcelium/directed/`
- `results/xcelium/20260527_1030_h1_drain_pipeline_xcelium/vip/`
- `results/xcelium/20260527_1030_h1_drain_pipeline_xcelium/failures/`

Files to commit/push after run:

- `results/genus/20260527_1030_h1_drain_pipeline_genus/`
- `MPTDC/lab_snapshots/genus_20260527_1030_h1_drain_pipeline_genus/`
- `results/xcelium/20260527_1030_h1_drain_pipeline_xcelium/`

If a run fails, still commit/push:

- the main Genus and Xcelium logs
- `run_manifest.txt`
- `SUMMARY.md`
- `test_summary.txt` if present
- any partial timing reports copied into the Genus result directory
- any `failures/` tails from Xcelium
- any partial `MPTDC/lab_snapshots/genus_20260527_1030_h1_drain_pipeline_genus/` contents
- the tool version/banner lines from logs, if available

Post-run commit message suggestion:

```text
server-results: 20260527_1030_h1_drain_pipeline Genus Xcelium
```

Do not run Innovus yet unless Genus shows the targeted clk_sys paths improved or
the remaining setup result is clearly physical/DRV dominated. If Genus improves,
the next request will ask for Innovus post-route confirmation.
