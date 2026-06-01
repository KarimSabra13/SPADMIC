# SERVER RUN REQUEST - O2 RAW TAG ANALYSIS RERUN

Run ID:
  `20260601_o2_raw_tag_analysis_streaming_rerun`

Git branch:
  `SPADMIC_localtag`

Purpose:
  Reuse the completed O2 raw-tag Xcelium campaign CSVs and rerun only the
  Python analysis/calibration stages with bounded-memory streaming. Do not
  rerun Xcelium.

## Emergency Stop If Old Analysis Is Still Running

First confirm that only Python analysis is running, not Xcelium:

```bash
pgrep -af "MPTDC/scripts/analysis/analyze_campaign.py"
```

If the listed processes are only the old analysis stage, stop them:

```bash
pkill -u "$USER" -f "MPTDC/scripts/analysis/analyze_campaign.py"
```

Do not delete campaign CSVs.

## Commands

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_localtag
git pull --ff-only

git status --short
git rev-parse HEAD
git log --oneline -5

bash MPTDC/scripts/sim/run_characterization_baseline.sh \
  --sim xcelium \
  --jobs 32 \
  --seeds 64 \
  --n-conv 100000 \
  --config multihit_15_cal_nominal \
  --out-mode raw_features \
  --nfast-encoding raw_lfsr_tag \
  --out-dir MPTDC/results/o2_raw_tag/20260601_o2_raw_tag_overnight_charac/characterization \
  --skip-campaign \
  --analyze \
  --calibrate \
  --train-seeds 48 \
  --analysis-low-memory \
  --analysis-jobs 2 \
  --analysis-chunksize 200000 \
  --log-memory \
  --train-max-rows-per-seed 200000 \
  --calibration-val-max-files 2
```

This expects the completed campaign CSVs under:

```text
MPTDC/results/o2_raw_tag/20260601_o2_raw_tag_overnight_charac/characterization/campaign/
```

## Expected Outputs

```text
MPTDC/results/o2_raw_tag/20260601_o2_raw_tag_overnight_charac/characterization/
  characterization_manifest.json
  analysis/sweep/summary_report.txt
  analysis/sweep/summary_report.json
  analysis/sweep/streaming_config.json
  analysis/sweep/analysis_memory_report.txt
  analysis/sweep/chunked_metrics_summary.csv
  analysis/sweep/*_profile_*.csv
  analysis/sweep/raw_tuple_histogram_*.csv
  analysis/calibration/lut_6d.csv
  analysis/calibration/val_reconstruction_errors_pre_post.csv
  analysis/calibration/*.json
  analysis/calibration/*.md
```

## Commit/Push

```bash
git add -f \
  MPTDC/results/o2_raw_tag/20260601_o2_raw_tag_overnight_charac/characterization/characterization_manifest.json \
  MPTDC/results/o2_raw_tag/20260601_o2_raw_tag_overnight_charac/characterization/analysis/sweep \
  MPTDC/results/o2_raw_tag/20260601_o2_raw_tag_overnight_charac/characterization/analysis/calibration

git commit -m "server-results: 20260601 O2 raw tag streaming analysis rerun"
git push
```

If the rerun fails, still commit/push:

- `characterization_manifest.json`
- `analysis/sweep/analysis_memory_report.txt` if present
- the terminal log or copied failure log
- any partial `summary_report.txt` or calibration report
