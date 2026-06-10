# Server Run Request: O10.1 Innovus Flow Repair

Purpose: rerun the first Innovus typical feasibility flow after repairing reporting, screenshots, SDC import, Tcl bus patterns, and CTS policy.

Labels:

- `O10_1_INNOVUS_FLOW_REPAIR`
- `O10_INNOVUS_TYPICAL_FEASIBILITY`
- `NOT_MMMC_SIGNOFF`
- `NOT_FINAL_SIGNOFF`
- `NOT_TAPEOUT_READY`

## Validate Only

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_localtag
git pull --ff-only
EXPECTED_HEAD=<agent_provided_sha>
ACTUAL_HEAD="$(git rev-parse HEAD)"
test "$ACTUAL_HEAD" = "$EXPECTED_HEAD"
git status --short
git log --oneline -5
MPTDC_O10_VALIDATE_ONLY=1 bash MPTDC/pnr/scripts/server_run_innovus_o10_1_repair.sh 202606xx_o10_1_validate
```

## Full Run

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_localtag
git pull --ff-only
EXPECTED_HEAD=<agent_provided_sha>
ACTUAL_HEAD="$(git rev-parse HEAD)"
test "$ACTUAL_HEAD" = "$EXPECTED_HEAD"
git status --short
git log --oneline -5
bash MPTDC/pnr/scripts/server_run_innovus_o10_1_repair.sh 202606xx_o10_1_innovus_repair
```

Expected result:

- `results/innovus/202606xx_o10_1_innovus_repair`
- `MPTDC/lab_snapshots/innovus_o10_1_innovus_repair_202606xx_o10_1_innovus_repair`

If automatic screenshots are unavailable, open the route checkpoint manually:

```bash
innovus -gui -init results/innovus/202606xx_o10_1_innovus_repair/checkpoints/restore_latest.tcl
```

## Commit Results

```bash
git add -f \
  results/innovus/202606xx_o10_1_innovus_repair \
  MPTDC/lab_snapshots/innovus_o10_1_innovus_repair_202606xx_o10_1_innovus_repair \
  docs/timing_closure/O10_1_innovus_flow_repair_plan.md \
  docs/timing_closure/O10_1_o10_failure_analysis.md \
  docs/timing_closure/O10_1_pre_run_assumptions.md \
  docs/timing_closure/O10_1_innovus_results_review.md \
  docs/timing_closure/osc_pd_iteration_log.md
git commit -m "server-results: O10.1 Innovus flow repair typical feasibility"
git push
```
