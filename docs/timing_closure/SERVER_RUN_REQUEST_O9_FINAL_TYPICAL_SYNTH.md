# Server Run Request: O9 Final Typical R750 Delta5 Genus

Run this only after the O9 R750 delta5 Xcelium characterization passes.

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_localtag
git pull --ff-only origin SPADMIC_localtag

EXPECTED_HEAD=<agent_provided_sha>
ACTUAL_HEAD="$(git rev-parse HEAD)"
test "$ACTUAL_HEAD" = "$EXPECTED_HEAD"

git status --short
git log --oneline -5

bash MPTDC/syn/scripts/server_run_genus_o9_final_typical_r750_delta5.sh 20260604_o9_final_typical_r750_delta5
```

The script uses:

- `freq_mode=r750_delta5`
- `+define+MPTDC_FREQ_R750_DELTA5`
- `nfast_encoding=raw_lfsr_tag`
- typical 1.8 V / 25 C standard-cell Liberty
- RO_tune4 real LEF
- RO_tune4 Liberty shell
- `MPTDC/syn/inputs/mptdc_osc_typical_r750_delta5.sdc`
- no MMMC
- Genus closure effort

After the server run:

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC

git status --short

git add -f results/genus_osc_pd/20260604_o9_final_typical_r750_delta5
if [ -d MPTDC/lab_snapshots/genus_osc_pd_20260604_o9_final_typical_r750_delta5 ]; then
  git add -f MPTDC/lab_snapshots/genus_osc_pd_20260604_o9_final_typical_r750_delta5
fi
git add docs/timing_closure/O9_r750_delta5_characterization_results.md
git add docs/timing_closure/osc_pd_iteration_log.md 2>/dev/null || true

git status --short
git commit -m "server-results: O9 final typical R750 delta5 Genus"
git push origin SPADMIC_localtag
```
