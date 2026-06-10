# Server Run Request: O13 abs4 PD Vernier Classification

Run this only after pulling the commit that contains the abs4 SDC/reporting changes.

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_localtag
git pull --ff-only

EXPECTED_HEAD=<agent_provided_sha>
ACTUAL_HEAD="$(git rev-parse HEAD)"
test "$ACTUAL_HEAD" = "$EXPECTED_HEAD"

git status --short
git log --oneline -5

bash MPTDC/syn/scripts/server_run_genus_o13_abs4_pd_vernier_classification.sh \
  20260609_o13_abs4_pd_vernier_classification
```

After the run:

```bash
RUN=20260609_o13_abs4_pd_vernier_classification

cat results/genus_osc_pd/$RUN/SUMMARY.md
cat results/genus_osc_pd/$RUN/o13_clock_model_check.rpt
cat results/genus_osc_pd/$RUN/pd_vernier_exception_check.rpt
cat results/genus_osc_pd/$RUN/timing_pd_intentional_vernier.rpt
cat results/genus_osc_pd/$RUN/timing_o13_phase_buffer_paths.rpt
cat results/genus_osc_pd/$RUN/timing_path_classification_summary.md
cat results/genus_osc_pd/$RUN/sdc_command_failures.md
```

Preserve evidence:

```bash
mkdir -p results/github_snapshots

tar -czf results/github_snapshots/${RUN}_evidence.tgz \
  results/genus_osc_pd/$RUN

cat > results/github_snapshots/${RUN}_manifest.txt <<EOF
O13 abs4 PD Vernier classification Genus snapshot
RUN_ID=$RUN
FINAL_SIGNOFF=NO
EOF

git add -f \
  results/github_snapshots/${RUN}_evidence.tgz \
  results/github_snapshots/${RUN}_manifest.txt

git commit -m "server-results: O13 abs4 PD Vernier classification snapshot"
git push origin SPADMIC_localtag
```

## Expected Result

- `UNKNOWN_REVIEW_REQUIRED=0`
- `PD_INTENTIONAL_VERNIER=64`
- `PD_VERNIER_EXCEPTION_APPLIED=YES`
- `PD_VERNIER_EXCEPTION_OVERMATCH=NO`
- final buffer clocks still async to `clk_sys`
- `timing_o13_phase_buffer_paths.rpt` shows all 16 O13 chains
- real local fast-domain paths remain in the timing reports
- no unresolved safety-critical SDC command failures

Do not run Innovus until this result is reviewed.
