# MPTDC v2.2 — Offline Calibration Plan

> - **Author:** Karim Sabra
> - **Purpose:** Explain how the active design exports raw features for host-side offline calibration.
> - **Scope:** Covers observables, collection flow, calibration phases, and recommended host data handling.

## 1. Philosophy

The active architecture is intentionally built for offline calibration. Silicon exports raw measurement features and optional raw timestamps, while the PC / FPGA side performs all heavy correction, fitting, and PVT adaptation.

That means:

- no on-chip LUT is required for normal operation
- no on-chip regression engine is required
- characterization strategy can evolve after tape-out without changing silicon

## 2. Exported raw information

### 2.1 Per-hit fields

| Field | Width | Meaning |
|-------|-------|---------|
| `nslow` | 7 | STOP-side slow coarse snapshot |
| `nfast_hit` | 7 | per-hit fast coarse count captured by the PD cell |
| `nfast_snap` | 7 | CAPTURE-time fast coarse snapshot |
| `ns` | 4 | slow phase index |
| `nf` | 4 | fast phase index |
| `pd_idx` | 7 | flattened PD index |
| `event_seq` | 4 | drain scan order within the packet |
| `phase0_snap` | 1 | STOP-side boundary snapshot |
| `slow_boundary_inc` | 1 | STOP-side boundary carry |

### 2.2 Optional derived field

If the host selects `RAW_TIMESTAMP` or `FULL` mode, the chip also emits `t_raw_ps`, which is generated using the live Vernier formula helper in `mptdc_pkg::vernier_tconv_ps()`.

Important semantics:

- `event_seq` is **drain / scan order**, not chronological hit order
- `hit_idx` in the CSV/reporting flow is the same kind of scan-order index
- calibration that keys on `hit_idx` is therefore using packet position, not time order

For highest-fidelity debug/calibration work, `FULL` is the richest collection mode.
For deployed-format-fidelity studies, use `RAW_FEATURES`.

## 3. Raw timestamp contract

The on-chip raw timestamp keeps the original Vernier dependency on:

- `Nslow`
- `Nfast`
- `ns`
- `nf`
- `K_VERNIER`
- `DELTA_LSB`

The live helper also applies the current geometry-origin corrections and `slow_boundary_inc` so the raw timestamp is centered for the present RTL semantics.

That makes `t_raw_ps` a useful debug observable, but not a replacement for full offline fitting.

## 4. Recommended collection flow

### 4.1 Bench and mode

Recommended local collection flow:

- bench: `tb/int/tb_campaign_collect.sv` (plusarg-configurable)
- orchestrator: `scripts/sim/run_campaign.sh` (parallel, resume-capable, native `--sim verilator|xrun|xcelium`)
- input source: `CAL`
- hit-depth policy: higher `max_hits` for dense raw data, `max_hits = 1` for minimum-latency fast-close studies
- output mode:
  - `FULL` for classic debug-heavy campaigns
  - `RAW_FEATURES` for deployed-format-fidelity studies

`run_campaign.sh` now exposes the deployed-format and jitter knobs directly:

- `--out-mode full|raw_features`
- `--jitter-sigma <ps>`
- `--jitter-bound <ps>`

When `--out-mode raw_features` is selected, `tb_campaign_collect.sv` still emits the
same 18-column CSV schema by reconstructing `t_raw_ps` from the narrow packet fields.
That keeps the downstream Python calibration flow compatible while matching the real
ASIC serializer contract.

### 4.2 Campaign configuration

The campaign runner enumerates all combinations of:
- **Close behavior:** high-`max_hits` collection points plus compatibility-labelled fast-close points
- **Max hits:** 15, 10, 5
- **Source:** CAL (1), SPAD (0)
- **Jitter:** nominal (σ=0), jitter (σ=8 ps, bound=24 ps)

That gives 24 configurations × 30 seeds each = 720 simulation runs.

```bash
# Full campaign with Verilator (12-core parallel)
bash scripts/sim/run_campaign.sh --sim verilator --jobs 12

# Same runner on a Cadence-equipped machine
bash scripts/sim/run_campaign.sh --sim xrun --jobs 32 --configs multihit_15_cal_nominal

# Deployed-format short campaign
bash scripts/sim/run_campaign.sh --sim verilator --jobs 8 \
  --configs multihit_15_cal_jitter \
  --out-mode raw_features \
  --out-dir results/shortformat_jitter

# Explicit jitter override sweep point
bash scripts/sim/run_campaign.sh --sim verilator --jobs 8 \
  --configs multihit_15_cal_nominal \
  --out-mode raw_features \
  --jitter-sigma 12 --jitter-bound 36 \
  --out-dir results/shortformat_jitter_js12

# Smoke test (1 seed per config, 500 conversions)
bash scripts/sim/run_campaign.sh --sim verilator --smoke
bash scripts/sim/run_campaign.sh --sim xrun --smoke
```

### 4.3 Silicon lab flow

1. Select `CAL` input mode.
2. Drive external reference START/STOP pulses.
3. Sweep delay across the full intended range (20 ps – 30 ns).
4. Repeat at enough repetitions per point to build distributions.
5. Log temperature, supply, lot, and die metadata with the raw CSV.

## 5. Proven calibration method: 6D mean-correction LUT

### 5.1 Method summary

After evaluating multiple calibration approaches (GPR, spline, MLP, multi-dimensional LUTs), the **6D mean-correction look-up table** was selected as the production method. It provides the best combination of precision, simplicity, and deployability.

### 5.2 LUT key

| Field | Source | Description |
|-------|--------|-------------|
| `ns_inf` | Inferred from `t_raw_ps` | Slow Vernier phase index (0–8) |
| `nf_inf` | Inferred from `t_raw_ps` | Fast Vernier phase index (0–8) |
| `nslow` | Word 0 | Slow oscillator coarse count |
| `nfast_hit` | Word 0 | Fast oscillator hit count |
| `phase0_snap` | Header | Oscillator alignment at conversion start |
| `hit_idx` | Implicit | Sequential hit position within conversion (0-based) |

**ns/nf recovery formula (for compact mode):**
```
diff = t_raw_ps / 10 - (nslow + 2 + sbi - 1) × 99 - nfast × 9 - 25
```
This `diff` value maps uniquely to all 81 `(ns, nf)` combinations — zero ambiguity.

### 5.3 Output mode compatibility

| Field | Mode 0 (RAW_FEATURES) | Mode 1 (RAW_TIMESTAMP) | Mode 2 (FULL) |
|-------|-----------------------|------------------------|---------------|
| nslow | W0 | W0 | W0 |
| nfast_hit | W0 | W0 | W0 |
| ns_inf | W1 (direct) | Inferred | W1 (direct) |
| nf_inf | W1 (direct) | Inferred | W1 (direct) |
| phase0_snap | Header | Header | Header |
| hit_idx | Implicit | Implicit | Implicit |

**All 6D LUT key fields are available in ALL three output modes.**

### 5.4 Validated nominal baseline (core subset only)

Training: 24 seeds × 50,000 conversions × 15 hits/conv = 16.8M **core-subset**
samples.

| Metric | Pre-Calibration | Post-Calibration | Improvement |
|--------|-----------------|------------------|-------------|
| **RMSE** | 425.8 ps | **18.89 ps** | **95.6%** |
| MAE | 350.8 ps | 14.6 ps | 95.8% |
| \|err\| P50 | 303.0 ps | 11.6 ps | 96.2% |
| \|err\| P90 | 637.0 ps | 32.9 ps | 94.8% |
| \|err\| P99 | 1057.0 ps | 45.0 ps | 95.7% |

- **LUT bins:** 16,014
- **Coverage:** 100% on 21M fresh validation points (seeds 100–129)
- **Held-out vs fresh:** 18.88 ps vs 18.89 ps (no overfitting)
- **Published scope:** `nslow > 0` core subset only (removes ~6.5% boundary-ambiguous hits)

This result is the maintained **nominal** reference point. It does **not** by itself
prove the jitter-limited deployed `RAW_FEATURES` case, and it is not the maintained
same-delay repeated-measurement proof.

### 5.5 Averaging performance (analysis-side resampling)

Averaging N independent measurements of the same delay:

| N | RMSE (ps) | vs N=1 |
|---|-----------|--------|
| 1 | 18.95 | — |
| 2 | 13.39 | −29% |
| 4 | 9.49 | −50% |
| 10 | 6.03 | −68% |
| 100 | 1.90 | −90% |
| 1000 | 0.60 | −97% |

The residual follows 1/√N well on the nominal calibrated error pool. This table comes
from **analysis-side resampling**, not from a dedicated fixed-delay repeated-measurement
testbench campaign.

### 5.6 Fixed-delay empirical characterization

Use the maintained fixed-delay flow when you want same-delay one-shot RMS and real
same-delay averaging curves from measured conversions:

```bash
bash scripts/sim/run_fixed_delay_campaign.sh \
  --sim verilator \
  --configs multihit_15_cal_nominal \
  --delay-list "20,50,100,200,500,1000,2000,5000,10000,30000" \
  --seeds 6 \
  --n-conv 2000 \
  --out-dir results/fixed_delay_campaign \
  --analyze
```

Main outputs:

- `results/fixed_delay_campaign/analysis/fixed_delay_summary.csv`
- `results/fixed_delay_campaign/analysis/fixed_delay_averaging.csv`
- `results/fixed_delay_campaign/analysis/fixed_delay_report.txt`

These reports use actual fixed-delay populations and distinguish:

- row-level error
- `first_hit_scan` conversion estimator
- `conv_mean` conversion estimator

### 5.7 Running calibration

```bash
python3 scripts/calibration/calibrate_6d_lut.py \
  --train-dir results/campaign/multihit_15_cal_nominal \
  --fresh-dir results/campaign_validation/multihit_15_cal_nominal \
  --out-dir   results/calibration_final
```

Outputs:
- `lut_6d.csv` — the saved LUT (16K bins)
- `calibration_report.txt` — human-readable report
- `calibration_report.json` — machine-readable metrics
- `plots/` — 19 diagnostic plots (histograms, scatter, Q-Q, INL/DNL, averaging curves)

### 5.8 Short-format observability study

For jitter-limited narrow-packet studies, use:

```bash
python3 scripts/calibration/analyze_shortformat_models.py \
  --nominal-train-dir results/shortformat_local/nominal_train/multihit_15_cal_nominal_raw_features \
  --jitter-train-dir  results/shortformat_local/jitter_train/multihit_15_cal_jitter_raw_features \
  --val-dir           results/shortformat_local/jitter_val/multihit_15_cal_jitter_raw_features \
  --fresh-dir         results/shortformat_local/jitter_fresh/multihit_15_cal_jitter_raw_features \
  --out-dir           results/shortformat_local/analysis
```

This tool reports:

- exact-LUT performance for multiple narrow-field keys
- oracle per-key floors, which estimate the best possible single-shot RMSE for a
  deterministic model that only sees the deployed `RAW_FEATURES` fields
- matched-bin coverage versus richer key fragmentation
- a full-coverage hierarchical fallback result for deployment-oriented comparisons
- delay-bucketed practical and oracle RMSE tables/plots aligned to the maintained
  fixed-delay reference grid (`20 ps .. 30 ns`)
- incremental oracle-gain tables/plots that separate:
  - `current_6d -> boundary_aug`
  - `boundary_aug -> short_core` (the true incremental value of `nfast_snap`)
  - `short_core -> all_visible`
- focused `nfast_snap` coherence outputs (`nfast_snap_split_summary.csv`) that show how
  often a `boundary_aug` bin actually splits into multiple `nfast_snap` states

If the oracle floor itself stays above the target, more LUT tuning will not close the
gap; the narrow observable set is the dominant limiter under the current jitter model.

Use this broad-corpus flow as the **headline deployment-proof view** because it
evaluates a continuous jittered delay population. A separate fixed-delay helper,
`scripts/calibration/analyze_fixed_delay_shortformat.py`, is useful for pointwise
characterization of selected delays, but isolated zero-RMSE fixed-delay points do not
override the continuous broad-corpus oracle floor.

Current local conclusion at the `sigma=6 ps`, `bound=24 ps` anchor:

- `nfast_snap` is **coherent enough to help**, but only modestly in the broad
  deployment-proof view:
  - core-only broad corpus: about `+8.5 ps` oracle gain over `boundary_aug`
  - all-rows broad corpus: about `+6.2 ps` oracle gain over `boundary_aug`
- `slow_boundary_inc` adds almost no extra oracle information on top of `current_6d`
  in the current local datasets
- `all_visible` adds no measurable oracle gain over `short_core`

So `nfast_snap` is not the whole problem: it helps, but it does **not** close the much
larger deployed short-format observability gap by itself.

## 6. Methods evaluated and rejected

| Method | RMSE (ps) | Notes |
|--------|-----------|-------|
| Baseline (raw) | 425.8 | No calibration |
| 1D spline (per phase class) | 441.1 | Too few features, poor boundary handling |
| GPR (Gaussian Process Regression) | 216.2 | O(n³) — memory-prohibitive for production |
| MLP (256-128-64 neural network) | 135.1 | Good but opaque; LUT is better and simpler |
| **6D LUT (selected)** | **18.89** | Best precision, fully transparent, trivial to deploy |

## 7. Runtime correction strategy

At runtime:

1. Receive packet stream over the 16-bit bus.
2. Decode raw fields per the output protocol.
3. Recover `(ns_inf, nf_inf)` from `t_raw_ps` if in compact mode.
4. Look up the 6D key in the pre-computed LUT.
5. Apply: `t_calibrated = t_raw_ps + LUT_correction`.
6. Flag hits with `nslow = 0` as low-confidence (boundary ambiguity).

This can be done in software, firmware, or an external FPGA.

## 8. Recommended CSV schema

Collection schema (19 columns, FULL mode — v2.3):

```csv
conv_id,hit_idx,Tref_ps,nslow,nfast_hit,nfast_snap,nfast_stop,ns,nf,pd_idx,event_seq,phase0_snap,slow_boundary_inc,hit_count,flags,ctx_id,t_raw_ps,mode,max_hits
```

**Note:** `nfast_stop` is a reserved field (always 0 in the current architecture
where the fast oscillator starts at STOP time).  The calibration scripts handle
both 18-column (legacy) and 19-column (v2.3) formats transparently.

## 9. Enhanced calibration methods (v2.3)

Beyond the proven 6D LUT, the following methods are now maintained and evaluated:

| Method | Nominal RMSE | Jitter RMSE | Notes |
|--------|-------------|------------|-------|
| 6D LUT (mean) | 18.99 ps | 53.64 ps | Baseline |
| 6D LUT (median) | 20.01 ps | 54.21 ps | Marginally worse |
| 6D LUT (trimmed mean 10%) | 19.06 ps | 53.67 ps | No significant gain |
| GradientBoosted regression | **18.56 ps** | **48.24 ps** | Best single-shot under jitter |
| Polynomial (deg 3) | 70.85 ps | 95.20 ps | Insufficient nonlinearity capture |
| Temporal re-keyed LUT | 25.54 ps | 63.15 ps | Lower coverage (88–94%) |

**GBR feature importances (jitter):** `nf=0.41, ns=0.28, phase0_snap=0.25,
nfast_hit=0.06, hit_idx<0.01, nfast_snap<0.01, nslow≈0`.

### Quality-gated multi-hit averaging

Calibrated timestamps can be averaged per-conversion using three strategies:

| Strategy | Description |
|----------|-------------|
| Uniform | Simple arithmetic mean of all per-hit timestamps |
| Weighted | Inverse-variance weighting (proxy: `nfast_hit` level) |
| Trimmed | Remove highest/lowest 10% of per-hit timestamps, then mean |

Results (15 hits max):

| Hits | Nominal Weighted | Nominal Trimmed | Jitter Trimmed |
|------|-----------------|----------------|---------------|
| 1 | 21.46 ps | 21.46 ps | 55.32 ps |
| 5 | 7.82 ps | 7.61 ps | 24.54 ps |
| 10 | 5.90 ps | 5.82 ps | 21.16 ps |
| 15 | **5.19 ps** | **5.29 ps** | **19.75 ps** |

### Maintained enhanced calibration scripts

```bash
# Fine phase grid analysis
python3 scripts/calibration/analyze_fine_grid.py -o results/fine_grid_analysis.pdf

# Multi-method comparison
python3 scripts/calibration/calibrate_enhanced.py \
  --input "results/campaign/<dataset>/seed_*.csv" \
  --out-dir results/calibration_enhanced
```

## 10. Why this architecture is calibration-friendly

1. It exports both coarse counts and phase indices.
2. It tags boundary condition information explicitly.
3. It preserves multi-hit information instead of collapsing everything to one scalar.
4. It allows recalibration without changing silicon.
5. It separates measurement hardware from correction policy.
6. The Vernier algebra allows full field recovery even in the most compact output mode.
7. The sub-header infrastructure (v2.3) provides per-conversion metadata extensibility.

## 11. Practical recommendation

For serious silicon characterization, collect in `FULL` when you need maximum debug
richness and in `RAW_FEATURES` when you need deployment-faithful observability.

**Maintained performance baselines:**

| Metric | Nominal | Jitter (σ=6 ps) |
|--------|---------|-----------------|
| Single-shot RMSE (6D LUT) | 18.99 ps | 53.64 ps |
| Single-shot RMSE (GBR) | 18.56 ps | 48.24 ps |
| 15-hit averaged RMSE (trimmed) | 5.29 ps | 19.75 ps |
| 15-hit averaged RMSE (weighted) | 5.19 ps | — |

Use the fixed-delay flow for empirical repeated-measurement proof and the
short-format observability study for jitter-limited deployment realism.
