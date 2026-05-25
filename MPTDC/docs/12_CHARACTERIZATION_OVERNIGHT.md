# MPTDC Verilator Overnight Characterization

## Scope

This flow is a standalone MPTDC RTL characterization harness. It intentionally
targets Verilator only in the first implementation and does not include TOP
shared-readout arbitration.

It complements the maintained baseline campaign:

- `scripts/sim/run_characterization_baseline.sh`
- `scripts/sim/run_campaign.sh`
- `scripts/sim/run_fixed_delay_campaign.sh`

The baseline remains the right entry point for nominal broad/fixed-delay
collection and calibration. The overnight flow adds focused stress datasets for
code-density, persistent-arm deadtime, boundary behavior, context pressure, and
standalone output backpressure.

## Quick smoke

Run this before any large campaign:

```bash
bash scripts/sim/run_characterization_overnight.sh \
  --smoke \
  --jobs 2 \
  --seeds 1 \
  --out-dir results/characterization/smoke_verilator \
  --rebuild \
  --analyze
```

Expected outputs:

- `results/characterization/smoke_verilator/stages/<stage>/seed_<N>.csv`
- `results/characterization/smoke_verilator/stages/<stage>/seed_<N>.log`
- `results/characterization/smoke_verilator/characterization_manifest.json`
- `results/characterization/smoke_verilator/analysis/plots/*.png`
- `results/characterization/smoke_verilator/analysis/plots/*.pdf`
- `results/characterization/smoke_verilator/analysis/tables/*.csv`
- `results/characterization/smoke_verilator/analysis/tables/*.md`

All plot and table labels are ASCII-only French text for downstream tool
compatibility.

## Aggressive overnight run

```bash
bash scripts/sim/run_characterization_overnight.sh \
  --overnight \
  --jobs 12 \
  --seeds 24 \
  --code-n-conv 500000 \
  --out-dir results/characterization/overnight_verilator \
  --rebuild \
  --analyze
```

The aggressive preset is intentionally large. Use `--smoke` first, then reduce
`--seeds` or select fewer stages if disk/runtime is constrained.

## Stage selection

Run a subset with a comma-separated list:

```bash
bash scripts/sim/run_characterization_overnight.sh \
  --smoke \
  --stages code_density,deadtime,boundary \
  --jobs 3 \
  --analyze
```

Available stages:

| Stage | Bench | Purpose |
| --- | --- | --- |
| `code_density` | `tb_char_code_density` | Strict mono-hit (`max_hits=1`) randomized asynchronous phase coverage and raw tuple occupancy for INL/DNL. |
| `deadtime` | `tb_char_deadtime_persistent` | Persistent-arm double-pulse deadtime without CSR re-arm in the measured gap. |
| `boundary` | `tb_char_boundary_stress` | STOP offsets around slow phase boundaries and PD-wavefront stress. |
| `context_overflow` | `tb_char_context_overflow` | FIFO stall, context pressure, START rejection, and overflow behavior. |
| `throughput` | `tb_char_throughput_backpressure` | Standalone MPTDC output backpressure and accepted/rejected event trends. |

## Analysis only

```bash
python3 scripts/analysis/analyze_characterization_overnight.py \
  --root results/characterization/overnight_verilator \
  --output-dir results/characterization/overnight_verilator/analysis
```

The analyzer writes PNG+PDF plots and CSV+Markdown tables. It avoids optional
Python dependencies such as `tabulate`. When `code_density` is selected, the
wrapper also runs `scripts/analysis/analyze_tdc_linearity.py`, which separates
observable-code DNL/INL, missing-code reporting, stimulus uniformity, and
transfer-linearity INL instead of integrating all empty scalar bins as physical
codes.

For calibration summaries, the analyzer preserves the maintained
`scripts/calibration/calibrate_6d_lut.py` method: the LUT key is
`(ns_inf, nf_inf, nslow, nfast_hit, stop_phase_disc, phase0_snap, hit_idx)`,
with `ns_inf/nf_inf` recovered from the Vernier algebra. The overnight analyzer
streams the large CSV set, but it does not replace the maintained categorical
calibration model.

## Oracle calibration-key analysis

Before adding any RTL discriminator, run the Oracle analysis on the mono-hit
code-density dataset. The goal is to quantify whether the packet-visible key
already bounds the true-delay ambiguity tightly enough for a post-calibration
`< 1 LSB` target on the useful `20 ps` to `30 ns` range.

```bash
python3 scripts/analysis/analyze_tdc_oracle.py \
  --root /sim/ksabra/mptdc_inl_dnl_mono_hit_v2 \
  --output-dir /sim/ksabra/mptdc_inl_dnl_mono_hit_v2/analysis/oracle \
  --delay-min-ps 20 \
  --delay-max-ps 30000 \
  --lsb-ps 10 \
  --edge-code 121
```

Main outputs:

- `oracle_summary.json`: verdict, selected best key, seed-split coverage, and
  pass/fail reason.
- `tables/oracle_key_summary.csv`: RMSE oracle, P99 absolute oracle, weighted
  key span percentiles, and rows with key span above `1 LSB` and `2 LSB`.
- `tables/worst_keys_<key>.csv`: worst true-delay spans per tested key.
- `plots/oracle_key_summary.pdf`: publication-ready comparison of candidate
  key families.

Interpretation rule:

- If a current packet-visible key passes the strict oracle P99/span gates, the
  remaining `< 1 LSB` work is software calibration: categorical LUT followed by
  monotone inverse transfer correction.
- If all current keys retain significant `> 2 LSB` spans, the data proves that
  a new discriminator or an explicit edge policy is required before the
  specification can be guaranteed.
- If the failing population is limited to the dominant edge code, document and
  isolate that edge population before proposing any packet-format change.

### Startup `nslow=0` root cause and RTL ECO

The strict Oracle result identified a structural startup failure mode: a large
`nslow=0` population can retain true-delay spans close to `1 ns` even when
`stop_phase_disc`, `phase0_snap`, and `slow_boundary_inc` are included in the
packet-visible key.  The root cause is in the STOP-side slow Gray counter, not
in the host LUT:

- the first `slow_phase[0]` edge after measurement clear was consumed by the
  generic `src_en && !src_en_q` clear behavior;
- the asynchronous STOP snapshot captured `gray_src_cont_q`, which encoded the
  previous `bin_q` value;
- therefore several startup coarse intervals were exported as `nslow=0`;
- `stop_phase_disc` is modulo slow-ring phase metadata and cannot recover a
  missing coarse count by itself.

The targeted RTL ECO keeps the legacy synchronizer defaults but configures the
slow STOP-side instance with `CLEAR_ON_ENABLE=0` and `GRAY_ENCODE_NEXT=1`.
This makes the first slow coarse edge count as a real edge and keeps the
registered Gray snapshot aligned with the current counter value.  The key
regression for this behavior is:

```bash
bash scripts/sim/run_tb.sh tb_gray_cnt_sync_unit --sim verilator
```

After this ECO, rerun the Oracle analysis before adding any new packet
discriminator.  Only consume `W1[6:3]` if the post-ECO Oracle still shows a
significant startup/edge span with the corrected `nslow`.

## Methodological limits

- This is RTL characterization with the behavioral oscillator model.
- It can validate packet structure, raw tuple coverage, digital deadtime
  sequencing, context pressure, and output backpressure behavior.
- It cannot prove silicon oscillator jitter, metastability probability, SPAD IRF,
  PVT drift, mismatch, extracted parasitics, or final timing accuracy.
- Keep `DELTA_STEP = 5 ps` and `DELTA_LSB = 10 ps` distinct when interpreting
  results.
