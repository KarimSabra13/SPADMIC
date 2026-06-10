# O6 Characterization Gate Plan

Date: 2026-06-02

Branch: `SPADMIC_localtag`

Reviewed HEAD: `1506b050db1f0a86c5c7b912b3364f885fcaff29`

## Purpose

Before another Genus run, the best current implementation must pass a
functionality and characterization gate. Timing closure is not useful if the
architecture breaks packet format, raw-feature compatibility, reconstruction,
linearity, calibration, context drain, or readout behavior.

## Modes

Mode A:

```text
name = O6A_best_current_raw_lfsr_tag
nfast_encoding = raw_lfsr_tag
packet = fixed_raw_features_v2_7
rtl = current SPADMIC_localtag implementation
```

Mode B:

```text
name = O6C_shift_mostly_galois_tag_candidate
nfast_encoding = raw_galois_tag
packet = fixed_raw_features_v2_7
rtl = selectable C1 RTL experiment, enabled by +define+MPTDC_FAST_TAG_GALOIS
```

Do not label default Fibonacci-LFSR RTL data as `raw_galois_tag`. The
characterization wrapper must compile with `+define+MPTDC_FAST_TAG_GALOIS` when
`--char-nfast-encoding raw_galois_tag` is requested, and the manifest must
record `rtl_tag_define_or_parameter`.

## Stage 0: Local Regression

Recommended command:

```bash
bash MPTDC/sim/verilator/run_smoke.sh 20260602_o6_stage0_current_raw_lfsr_tag
MPTDC_FAST_TAG_ENCODING=raw_galois_tag \
  bash MPTDC/sim/verilator/run_smoke.sh 20260602_o6_stage0_raw_galois_tag
```

Required checks:

- fast epoch tag unit
- slow Johnson unit
- PD tag/freeze unit
- PD gate false-hit unit
- drain raw-tag unit
- drain controller unit
- hit capture bridge unit
- integration smoke
- VIP smoke subset

## Stage 1: Xcelium Packet/Functional Smoke

Current implementation command:

```bash
bash MPTDC/scripts/sim/run_vip_overnight.sh \
  --sim xcelium \
  --stages char \
  --jobs 8 \
  --out-dir results/o6_char/20260602_o6a_stage1_current_raw_lfsr_tag \
  --char-seeds 4 \
  --char-n-conv 5000 \
  --char-train-seeds 2 \
  --char-out-mode raw_features \
  --char-nfast-encoding raw_lfsr_tag \
  --fixed-delay-seeds 2 \
  --fixed-delay-n-conv 1000 \
  --analysis-low-memory \
  --analysis-jobs 1 \
  --analysis-chunksize 100000 \
  --log-memory \
  --train-max-rows-per-seed 50000 \
  --calibration-val-max-files 1 \
  --rerun-char
```

Pass criteria:

- packet parser completes
- no malformed packets
- no missing EOC
- raw tag decode invalid count is zero or explained
- calibration smoke completes
- fixed-delay smoke completes
- manifest records `raw_lfsr_tag`, packet format version, branch, HEAD, and
  decode table hash

## Stage 2: Medium Characterization Gate

Current implementation command:

```bash
bash MPTDC/scripts/sim/run_vip_overnight.sh \
  --sim xcelium \
  --stages char \
  --jobs 16 \
  --out-dir results/o6_char/20260602_o6a_stage2_current_raw_lfsr_tag \
  --char-seeds 8 \
  --char-n-conv 50000 \
  --char-train-seeds 6 \
  --char-out-mode raw_features \
  --char-nfast-encoding raw_lfsr_tag \
  --fixed-delay-seeds 4 \
  --fixed-delay-n-conv 5000 \
  --analysis-low-memory \
  --analysis-jobs 2 \
  --analysis-chunksize 200000 \
  --log-memory \
  --train-max-rows-per-seed 100000 \
  --calibration-val-max-files 2 \
  --rerun-char
```

Pass criteria:

- Stage 1 pass criteria remain true
- reconstructed delay is monotonic over the sampled range
- fixed-delay RMS does not regress unexpectedly versus the last raw-LFSR
  baseline
- DNL/INL/code-density smoke is plausible
- hit-count distribution is plausible
- boundary classes and `stop_phase_disc` distributions remain plausible
- memory remains bounded by streaming analysis

## Stage 3: Overnight Characterization

Run only after Stage 1 and Stage 2 pass:

```bash
bash MPTDC/scripts/sim/run_vip_overnight.sh \
  --sim xcelium \
  --stages all \
  --jobs 32 \
  --out-dir results/o6_char/20260602_o6a_stage3_current_raw_lfsr_tag_overnight \
  --vip-seed-start 30000 \
  --vip-seeds 32 \
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
  --train-max-rows-per-seed 200000 \
  --calibration-val-max-files 2 \
  --rerun-vip \
  --rerun-char
```

## Genus Block

Do not request another Genus run until the characterization gate passes. If
Stage 1 or Stage 2 fails, fix functionality/calibration first.
