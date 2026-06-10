# SERVER RUN REQUEST - O1B R800 WHAT-IF

Run ID:
  `20260528_o1b_real_abstract_r800`

Git branch:
  `SPADMIC_TOP`

Expected HEAD:
  Use the final pushed SHA reported by the agent for this O1 collateral commit, or a later SHA after O1A analysis if the request is revised.

Purpose:
  Run a separated R800 oscillator timing what-if using the real RO_tune4 abstract flow. This must be compared against O1A real abstract nominal, not directly against O0.

Precondition:
  Do not run O1B until O1A locator/export/macro-binding status has been reviewed. If O1A does not bind the real macro, O1B cannot be considered physically meaningful.

Commands:

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_TOP
git pull --ff-only
EXPECTED_HEAD=<agent_provided_sha>
ACTUAL_HEAD="$(git rev-parse HEAD)"
test "$ACTUAL_HEAD" = "$EXPECTED_HEAD"
git status --short
git log --oneline -5

bash MPTDC/syn/scripts/server_run_genus_o1b_r800.sh 20260528_o1b_real_abstract_r800_genus
bash MPTDC/pnr/scripts/server_run_innovus_o1b_r800.sh 20260528_o1b_real_abstract_r800_innovus
bash MPTDC/sim/xcelium/server_run_xcelium_r800_mptdc.sh 20260528_o1b_real_abstract_r800_xcelium
```

Commit/push:

```bash
git add -f \
  results/genus_osc_pd/20260528_o1b_real_abstract_r800_genus \
  results/osc_pd/20260528_o1b_real_abstract_r800_innovus \
  results/xcelium/20260528_o1b_real_abstract_r800_xcelium \
  MPTDC/results/xcelium/20260528_o1b_real_abstract_r800_xcelium \
  docs/timing_closure/osc_pd_iteration_log.md

git commit -m "server-results: 20260528 O1B real abstract R800"
git push
```

Current R800 status:

`r800_period_delta_whatif` is STA/PnR only. It is not calibration-safe until analog confirms slow/fast tune-code pair, extracted tap steps, load, slew, jitter, startup, and 5 ps Vernier delta preservation.
