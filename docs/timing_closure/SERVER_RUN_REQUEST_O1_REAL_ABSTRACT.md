# SERVER RUN REQUEST - O1 REAL RO_tune4 ABSTRACT

Run ID:
  `20260528_o1_real_abstract`

Git branch:
  `SPADMIC_TOP`

Expected HEAD:
  Use the final pushed SHA reported by the agent for this O1 collateral commit.

Purpose:
  Prove whether the real `SPADMIC/RO_tune4/abstract` OA view exists on the lab server, can be found/exported as LEF, and can be bound by the O1A nominal oscillator/PD Genus/Innovus flow.

Do not run:
  H4b backend-only request yet, unless explicitly instructed.
  O1B R800 before O1A is analyzed.

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

bash MPTDC/pnr/scripts/server_locate_ro_tune4_abstract.sh 20260528_o1_locate_ro_tune4
bash MPTDC/pnr/scripts/server_export_ro_tune4_lef.sh 20260528_o1_export_ro_tune4_lef
bash MPTDC/syn/scripts/server_run_genus_o1_real_abstract.sh 20260528_o1a_real_abstract_nominal_genus
bash MPTDC/pnr/scripts/server_run_innovus_o1_real_abstract.sh 20260528_o1a_real_abstract_nominal_innovus
```

Commit/push:

```bash
git add -f \
  results/osc_pd/20260528_o1_locate_ro_tune4 \
  results/osc_pd/20260528_o1_export_ro_tune4_lef \
  results/genus_osc_pd/20260528_o1a_real_abstract_nominal_genus \
  results/osc_pd/20260528_o1a_real_abstract_nominal_innovus \
  docs/timing_closure/osc_pd_iteration_log.md \
  docs/timing_closure/O1_o0_result_review.md

git commit -m "server-results: 20260528 O1 real RO_tune4 abstract nominal"
git push
```

If any tool fails, still commit/push:

- `SUMMARY.md`
- main log
- partial reports
- locator/export evidence
- LEF macro/pin/OBS summaries if produced

Hard-stop interpretation:

- If the OA path is missing or unreadable, stop and request analog/layout path correction.
- If no LEF exists and automatic export fails, request analog designer LEF export.
- If LEF pins or macro name do not match current netlist, stop for macro-binding fix.
- If the current netlist does not instantiate `RO_tune4`, do not claim O1A real macro binding.
