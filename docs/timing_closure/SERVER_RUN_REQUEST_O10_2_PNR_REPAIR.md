# Server Run Request: O10.2 PNR Constraint/Report/CTS Repair

## Prepare

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_localtag
git pull --ff-only
EXPECTED_HEAD=<agent_provided_sha>
ACTUAL_HEAD="$(git rev-parse HEAD)"
test "$ACTUAL_HEAD" = "$EXPECTED_HEAD"
git status --short
git log --oneline -5
```

## Validate Only

```bash
MPTDC_O10_2_MODE=validate_only bash MPTDC/pnr/scripts/server_run_innovus_o10_2_pnr_repair.sh 20260604_o10_2_validate
```

## Full Route Feasibility

```bash
MPTDC_O10_2_MODE=route_feasibility bash MPTDC/pnr/scripts/server_run_innovus_o10_2_pnr_repair.sh 20260604_o10_2_pnr_repair
```

## Optional GUI Screenshot Export

```bash
MPTDC_O10_2_MODE=gui_screenshot bash MPTDC/pnr/scripts/server_run_innovus_o10_2_pnr_repair.sh 20260604_o10_2_pnr_repair
```

## After Server Run

```bash
git status --short
git add -f \
  results/innovus/20260604_o10_2_pnr_repair \
  MPTDC/lab_snapshots/innovus_o10_2_pnr_repair_20260604_o10_2_pnr_repair \
  docs/timing_closure/O10_2_o10_1_deep_review.md \
  docs/timing_closure/O10_2_innovus_sdc_repair.md \
  docs/timing_closure/O10_2_timing_classification_plan.md \
  docs/timing_closure/O10_2_io_timing_assumptions.md \
  docs/timing_closure/O10_2_reset_recovery_policy.md \
  docs/timing_closure/O10_2_ro_phase_load_analysis.md \
  docs/timing_closure/O10_2_expected_outputs.md \
  docs/timing_closure/O10_2_runbook.md \
  docs/timing_closure/SERVER_RUN_REQUEST_O10_2_PNR_REPAIR.md
git commit -m "server-results: O10.2 Innovus PNR repair typical feasibility"
git push
```

Do not call this MMMC signoff, final signoff, or tapeout-ready.
