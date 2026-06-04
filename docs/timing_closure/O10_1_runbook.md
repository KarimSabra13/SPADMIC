# O10.1 Runbook

## Local Checks

These checks do not run Innovus:

```bash
git checkout SPADMIC_localtag
git pull --ff-only
git status --short
git rev-parse HEAD

bash -n MPTDC/pnr/scripts/server_run_innovus_o10_1_repair.sh
tclsh <<'EOF'
set ::env(MPTDC_O10_SOURCE_ONLY) 1
source MPTDC/pnr/scripts/innovus_o10_1_init.tcl
source MPTDC/pnr/scripts/innovus_o10_1_screenshots.tcl
source MPTDC/pnr/scripts/innovus_o10_1_cts.tcl
source MPTDC/pnr/scripts/innovus_o10_1_reports.tcl
source MPTDC/pnr/scripts/innovus_o10_1_phase_net_reports.tcl
puts ok
EOF
```

## Server Validate Only

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_localtag
git pull --ff-only
EXPECTED_HEAD=<agent_provided_sha>
ACTUAL_HEAD="$(git rev-parse HEAD)"
test "$ACTUAL_HEAD" = "$EXPECTED_HEAD"
MPTDC_O10_VALIDATE_ONLY=1 bash MPTDC/pnr/scripts/server_run_innovus_o10_1_repair.sh 202606xx_o10_1_validate
```

## Server Full Feasibility

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

## After Server Run

Commit compact, curated results only:

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
