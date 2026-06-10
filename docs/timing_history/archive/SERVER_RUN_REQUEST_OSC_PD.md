# SERVER RUN REQUEST - OSC/PD SIGNOFF

Run ID:

```text
20260527_1500_o0_osc_pd_signoff
```

Git branch:

```text
SPADMIC_TOP
```

Expected HEAD:

```text
Use the exact SHA reported by the agent after the O0 infrastructure commit.
The request file cannot self-contain its final commit SHA without changing that
SHA; the command block below still checks the exact SHA before running.
```

Purpose:

Provisional oscillator/PD macro-view, floorplan, phase-route/load, and
timing-path classification run.

Do not run:

Do not run the H4b backend-only request yet unless explicitly instructed.

## Commands

Replace `<EXPECTED_SHA_FROM_AGENT_FINAL>` with the exact SHA from the final
agent response for this work package.

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_TOP
git pull --ff-only
EXPECTED_HEAD=<EXPECTED_SHA_FROM_AGENT_FINAL>
ACTUAL_HEAD="$(git rev-parse HEAD)"
test "$ACTUAL_HEAD" = "$EXPECTED_HEAD"
git status --short
git log --oneline -5

bash MPTDC/syn/scripts/server_run_genus_osc_pd_signoff.sh 20260527_1500_o0_osc_pd_signoff_genus
bash MPTDC/pnr/scripts/server_run_innovus_osc_pd_signoff.sh 20260527_1500_o0_osc_pd_signoff_innovus
```

## Expected Output Directories

```text
results/genus_osc_pd/20260527_1500_o0_osc_pd_signoff_genus/
results/osc_pd/20260527_1500_o0_osc_pd_signoff_innovus/
MPTDC/lab_snapshots/genus_osc_pd_20260527_1500_o0_osc_pd_signoff_genus/
MPTDC/lab_snapshots/innovus_osc_pd_20260527_1500_o0_osc_pd_signoff_innovus/
```

## Files To Commit/Push

```bash
git add -f \
  results/genus_osc_pd/20260527_1500_o0_osc_pd_signoff_genus \
  results/osc_pd/20260527_1500_o0_osc_pd_signoff_innovus \
  MPTDC/lab_snapshots/genus_osc_pd_20260527_1500_o0_osc_pd_signoff_genus \
  MPTDC/lab_snapshots/innovus_osc_pd_20260527_1500_o0_osc_pd_signoff_innovus \
  docs/timing_closure/osc_pd_iteration_log.md

git commit -m "server-results: 20260527_1500_o0_osc_pd_signoff Genus Innovus"
git push
```

If a tool fails, still commit/push:

- main log
- partial reports
- `SUMMARY.md`
- tool version/banner if available
- any O0 CSVs produced before failure

Post-run commit message suggestion:

```text
server-results: 20260527_1500_o0_osc_pd_signoff Genus Innovus
```
