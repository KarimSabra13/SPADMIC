SERVER RUN REQUEST - O3 RAW EPOCH / PD CAPTURE CLEANUP GENUS

Run ID:
  20260601_o3_raw_epoch_cleanup_genus

Git branch:
  SPADMIC_localtag

Expected HEAD:
  <fill after committing/pushing O3>

Purpose:
  Run one Genus iteration after the coherent O3 measurement-fabric cleanup:
  slow Johnson epoch, no fast-domain slow decode, clk_sys START watchdog, and
  PD shadow tag capture.

Do not run:
  Innovus, R800, or H4b yet.

Commands:

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_localtag
git pull --ff-only

EXPECTED_HEAD=<AGENT_PROVIDED_SHA>
ACTUAL_HEAD="$(git rev-parse HEAD)"
test "$ACTUAL_HEAD" = "$EXPECTED_HEAD"

git status --short
git log --oneline -5

bash MPTDC/syn/scripts/server_run_genus_o3_raw_epoch_cleanup.sh 20260601_o3_raw_epoch_cleanup_genus
```

Commit/push after the run:

```bash
git add -f \
  results/genus_osc_pd/20260601_o3_raw_epoch_cleanup_genus \
  MPTDC/lab_snapshots/genus_osc_pd_20260601_o3_raw_epoch_cleanup_genus \
  docs/timing_closure/osc_pd_iteration_log.md

git commit -m "server-results: 20260601 O3 raw epoch cleanup Genus"
git push
```

If Genus fails, still commit/push:

- `results/genus_osc_pd/20260601_o3_raw_epoch_cleanup_genus/`
- `MPTDC/lab_snapshots/genus_osc_pd_20260601_o3_raw_epoch_cleanup_genus/` if created
- main Genus log
- partial reports
- `SUMMARY.md`

Conclusion needed from this run:

- Did old slow counter/watchdog paths disappear?
- Did fast-domain slow decode disappear?
- Did PD q1/q2 to nfast capture improve?
- Is `clk_sys` now the dominant remaining class?
- Are remaining oscillator paths local and physically meaningful?
