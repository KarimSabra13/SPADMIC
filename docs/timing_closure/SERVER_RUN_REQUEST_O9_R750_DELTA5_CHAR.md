# Server Run Request: O9 R750 Delta5 Xcelium Characterization

Run this before O9 final Genus. This proves the R750/R700 delta-preserving mode
at the RTL, packet, raw-tag, analysis, and calibration levels. It is still not
final analog or MMMC signoff.

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_localtag
git pull --ff-only origin SPADMIC_localtag

EXPECTED_HEAD=<agent_provided_sha>
ACTUAL_HEAD="$(git rev-parse HEAD)"
test "$ACTUAL_HEAD" = "$EXPECTED_HEAD"

git status --short
git log --oneline -5

bash MPTDC/scripts/sim/run_vip_overnight.sh \
  --sim xcelium \
  --stages char \
  --jobs 32 \
  --out-dir results/o9_char/20260604_o9_r750_delta5_overnight \
  --freq-mode r750_delta5 \
  --char-seeds 64 \
  --char-n-conv 100000 \
  --char-train-seeds 48 \
  --char-out-mode raw_features \
  --char-nfast-encoding raw_lfsr_tag \
  --fixed-delay-seeds 8 \
  --fixed-delay-n-conv 5000 \
  --analysis-low-memory \
  --analysis-jobs 2 \
  --analysis-chunksize 200000 \
  --log-memory \
  --train-max-rows-per-seed 50000 \
  --calibration-val-max-files 4 \
  --rerun-char
```

After the run, summarize the result in:

```text
docs/timing_closure/O9_r750_delta5_characterization_results.md
```

Then commit and push:

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC

git status --short

git add -f results/o9_char/20260604_o9_r750_delta5_overnight
git add docs/timing_closure/O9_r750_delta5_characterization_results.md
git add docs/timing_closure/osc_pd_iteration_log.md 2>/dev/null || true

git status --short
git commit -m "results: add O9 R750 delta5 characterization"
git push origin SPADMIC_localtag
```

Do not run final Genus if packet parsing, raw-tag decode, calibration, or
fixed-delay validation fails.
