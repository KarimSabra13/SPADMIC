# Server Run Request: O4 Muxless Tags and R600 What-If

Run after committing and pushing the O4 patch.

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_localtag
git pull --ff-only

EXPECTED_HEAD=<AGENT_PROVIDED_SHA_AFTER_PUSH>
ACTUAL_HEAD="$(git rev-parse HEAD)"
test "$ACTUAL_HEAD" = "$EXPECTED_HEAD"

git status --short
git log --oneline -5

bash MPTDC/syn/scripts/server_run_genus_o4_muxless_tags_r600.sh 20260602_o4_muxless_tags_r600
```

The wrapper will run:

- `20260602_o4_muxless_tags_r600_o4_nominal_fast`
- `20260602_o4_muxless_tags_r600_o4_r600_fast`
- one optional closure run only if nominal or R600 fast-feasibility is promising

To force no closure run:

```bash
O4_RUN_CLOSURE=0 bash MPTDC/syn/scripts/server_run_genus_o4_muxless_tags_r600.sh 20260602_o4_muxless_tags_r600
```

To force automatic closure behavior, which is the default:

```bash
O4_RUN_CLOSURE=auto bash MPTDC/syn/scripts/server_run_genus_o4_muxless_tags_r600.sh 20260602_o4_muxless_tags_r600
```

## Commit Results

After the run completes:

```bash
git status --short

git add -f \
  results/genus_osc_pd/20260602_o4_muxless_tags_r600_o4_nominal_fast \
  results/genus_osc_pd/20260602_o4_muxless_tags_r600_o4_r600_fast \
  results/genus_osc_pd/20260602_o4_muxless_tags_r600_o4_nominal_closure \
  results/genus_osc_pd/20260602_o4_muxless_tags_r600_o4_r600_closure \
  results/genus_osc_pd/20260602_o4_muxless_tags_r600_SUMMARY.md \
  MPTDC/lab_snapshots/genus_osc_pd_20260602_o4_muxless_tags_r600_o4_nominal_fast \
  MPTDC/lab_snapshots/genus_osc_pd_20260602_o4_muxless_tags_r600_o4_r600_fast \
  MPTDC/lab_snapshots/genus_osc_pd_20260602_o4_muxless_tags_r600_o4_nominal_closure \
  MPTDC/lab_snapshots/genus_osc_pd_20260602_o4_muxless_tags_r600_o4_r600_closure \
  docs/timing_closure/O4_current_spadmic_localtag_review.md \
  docs/timing_closure/O4_muxless_fast_slow_tags.md \
  docs/timing_closure/O4_pd_locked_frequency_strategy.md \
  docs/timing_closure/O4_watchdog_countdown.md \
  docs/timing_closure/O4_r600_whatif_plan.md \
  docs/timing_closure/O4_genus_expectations.md \
  docs/timing_closure/osc_pd_iteration_log.md

git commit -m "server-results: 20260602 O4 muxless tags R600 Genus"
git push
```

If a closure directory was not created, remove that missing path from `git add`.

Do not add PDK audit outputs.
