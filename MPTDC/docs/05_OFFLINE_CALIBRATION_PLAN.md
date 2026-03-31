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
| `nfast` | 7 | per-hit fast coarse count captured by the PD cell |
| `nfast_snap` | 7 | CAPTURE-time fast coarse snapshot |
| `ns` | 4 | slow phase index |
| `nf` | 4 | fast phase index |
| `pd_idx` | 7 | flattened PD index |
| `event_seq` | 4 | scan order within the packet |
| `phase0_snap` | 1 | STOP-side boundary snapshot |
| `slow_boundary_inc` | 1 | STOP-side boundary carry |

### 2.2 Optional derived field

If the host selects `RAW_TIMESTAMP` or `FULL` mode, the chip also emits `t_raw_ps`, which is generated using the live Vernier formula helper in `mptdc_pkg::vernier_tconv_ps()`.

For highest-fidelity calibration work, `RAW_FEATURES` is still the recommended mode because it preserves all primitive fields.

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
- mode: `MULTI_HIT` for dense raw data, `FIRST_HIT` for earliest-close behavior
- output mode: `FULL` (all raw features + raw timestamp)

### 4.2 Campaign configuration

The campaign runner enumerates all combinations of:
- **Mode:** MULTI_HIT (0), FIRST_HIT (1)
- **Max hits:** 15, 10, 5
- **Source:** CAL (1), SPAD (0)
- **Jitter:** nominal (σ=0), jitter (σ=8 ps, bound=24 ps)

That gives 24 configurations × 30 seeds each = 720 simulation runs.

```bash
# Full campaign with Verilator (12-core parallel)
bash scripts/sim/run_campaign.sh --sim verilator --jobs 12

# Same runner on a Cadence-equipped machine
bash scripts/sim/run_campaign.sh --sim xrun --jobs 32 --configs multihit_15_cal_nominal

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

### 5.4 Validated results

Training: 24 seeds × 50,000 conversions × 15 hits/conv = 16.8M core samples.

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
- **Core filter:** nslow > 0 (removes 6.5% boundary-ambiguous hits)

### 5.5 Averaging performance

Averaging N independent measurements of the same delay:

| N | RMSE (ps) | vs N=1 |
|---|-----------|--------|
| 1 | 18.95 | — |
| 2 | 13.39 | −29% |
| 4 | 9.49 | −50% |
| 10 | 6.03 | −68% |
| 100 | 1.90 | −90% |
| 1000 | 0.60 | −97% |

The residual follows 1/√N perfectly — no residual systematic structure.

### 5.6 Running calibration

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

Collection schema (18 columns, FULL mode):

```csv
conv_id,hit_idx,Tref_ps,nslow,nfast_hit,nfast_snap,ns,nf,pd_idx,event_seq,phase0_snap,slow_boundary_inc,hit_count,flags,ctx_id,t_raw_ps,mode,max_hits
```

## 9. Why this architecture is calibration-friendly

1. It exports both coarse counts and phase indices.
2. It tags boundary condition information explicitly.
3. It preserves multi-hit information instead of collapsing everything to one scalar.
4. It allows recalibration without changing silicon.
5. It separates measurement hardware from correction policy.
6. The Vernier algebra allows full field recovery even in the most compact output mode.

## 10. Practical recommendation

For serious silicon characterization, prefer storing the raw feature vectors in FULL mode and recomputing any derived timestamp offline. The 6D LUT achieves 18.89 ps single-shot RMSE and sub-1 ps with 1000-point averaging, making it suitable for high-precision SPAD timing experiments.
