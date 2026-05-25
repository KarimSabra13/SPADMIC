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
`(ns_inf, nf_inf, nslow, nfast_hit, phase0_snap, hit_idx)`, with `ns_inf/nf_inf`
recovered from the Vernier algebra. The overnight analyzer streams the large CSV
set, but it does not replace the 6D+hit_idx calibration model.

## Methodological limits

- This is RTL characterization with the behavioral oscillator model.
- It can validate packet structure, raw tuple coverage, digital deadtime
  sequencing, context pressure, and output backpressure behavior.
- It cannot prove silicon oscillator jitter, metastability probability, SPAD IRF,
  PVT drift, mismatch, extracted parasitics, or final timing accuracy.
- Keep `DELTA_STEP = 5 ps` and `DELTA_LSB = 10 ps` distinct when interpreting
  results.
