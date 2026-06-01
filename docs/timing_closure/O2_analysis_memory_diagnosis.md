# O2 Analysis Memory Diagnosis

Date: 2026-06-01
Branch: SPADMIC_localtag

## Trigger

The O2 raw-tag overnight characterization reached the post-simulation analysis
stage. Xcelium/VIP simulation was not the bottleneck. The Python analysis stage
spawned many `analyze_campaign.py` processes with very large RSS.

Campaign scale:

- 64 seeds
- 100000 conversions per seed
- about 1500001 CSV rows per seed
- about 96000127 total data rows
- `--jobs 32` was appropriate for Xcelium simulation, but unsafe for Python
  analysis if each worker loads campaign CSVs into DataFrames.

## Root Cause

`MPTDC/scripts/analysis/analyze_campaign.py` used a legacy full-load path:

```python
frames = []
for p in paths:
    df = pd.read_csv(p)
    frames.append(df)
return pd.concat(frames, ignore_index=True)
```

The full campaign is therefore resident as:

- one DataFrame per seed
- one additional concatenated DataFrame
- extra copies for raw-tag decode, residual computation, grouping, profiles,
  raw tuple histograms, and plotting

This is not memory-safe for approximately 96M rows. A conservative per-row
estimate with default pandas int64/float64/object overhead is hundreds of bytes
per row once intermediate columns and indexing are included. That puts the
working set well above tens of GiB for a single process, and much worse if
multiple analysis workers execute the same pattern.

## Secondary Risks

`MPTDC/scripts/sim/run_characterization_baseline.sh` and
`MPTDC/scripts/sim/run_vip_overnight.sh` used one `--jobs` knob for simulation
parallelism. That allows the same high parallelism intended for Xcelium to leak
into post-processing behavior.

`MPTDC/scripts/calibration/calibrate_6d_lut.py` already accumulates LUT bins
incrementally in its chunk-load training path, but it still read one seed at a
time as a full DataFrame and validation could load multiple held-out seed files.
For large O2 sweeps this needs explicit row/file bounds.

## Fix Plan Implemented

1. Add a streaming backend to `analyze_campaign.py`.
2. Read CSVs in chunks with `usecols` and narrow dtypes.
3. Compute metrics with online accumulators instead of storing rows.
4. Keep raw-tag decode in software, but apply it per chunk.
5. Add separate analysis controls:
   - `--analysis-jobs`
   - `--analysis-chunksize`
   - `--analysis-low-memory`
   - `--analysis-backend streaming|legacy`
   - `--log-memory`
   - `--max-rows-per-file` for debug
6. Add `--skip-campaign` so existing simulation CSVs can be reused without
   relaunching Xcelium.
7. Bound calibration training/validation with:
   - `--train-max-rows-per-seed`
   - `--calibration-val-max-files`

## Streaming Output Differences

Streaming mode keeps existing high-level output names where practical:

- `summary_report.txt`
- `summary_report.json`
- `delay_profile_*.csv`
- `delay_regions_*.csv`
- `nslow_profile_*.csv`
- `nfast_hit_profile_*.csv`
- `hit_idx_profile_*.csv`
- `stop_phase_disc_profile_*.csv`
- `t_raw_profile_*.csv`
- `phase_count_heatmap_*.csv`
- `raw_tuple_histogram_*.csv`

Streaming mode also writes:

- `streaming_config.json`
- `analysis_memory_report.txt`
- `chunked_metrics_summary.csv`

Intentional differences:

- raw scatter plots are skipped in streaming mode
- pairwise boundary-class t-tests are skipped in streaming mode
- P90/P99 absolute-error values are histogram approximations

These differences avoid retaining raw residual arrays for tens of millions of
rows.

## Immediate Rerun Policy

Do not rerun Xcelium. Reuse the completed CSV campaign and rerun only the
analysis/calibration stages with low-memory options.
