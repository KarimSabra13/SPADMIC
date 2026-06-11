# SPADMIC_test Characterization Plan

Characterize at least:

- `BASELINE` reference from `SPADMIC_FINAL`.
- `STRIDE2` candidate from `SPADMIC_test`.

## Stage 1 Smoke

```bash
RUN=spadmic_test_stride2_char_stage1_$(date +%Y%m%d_%H%M%S)

bash MPTDC/scripts/sim/run_vip_overnight.sh \
  --sim xcelium \
  --stages char \
  --jobs 8 \
  --out-dir work/characterization/$RUN \
  --freq-mode r750_delta5 \
  --mptdc-opt-mode STRIDE2 \
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
  --rerun-char
```

## Stage 2 Medium

Use 8 or 16 seeds, 20000 to 50000 conversions, 4 fixed-delay seeds, and 2000 to 5000 fixed-delay conversions.

## Stage 3 Overnight

Use 64 seeds, 100000 conversions, 8 fixed-delay seeds, and 5000 fixed-delay conversions.

## Metrics

- Packet parse.
- Malformed packets.
- Missing EOC.
- Valid conversion count.
- Hit count distribution.
- No-hit rate.
- Max-hit rate.
- Raw tag decode unknown count.
- Calibration RMS.
- Fixed-delay RMS.
- p95 and p99 error.
- DNL/INL smoke.
- Boundary bias.
- Lossless event rate.
- Burst behavior.
- Memory peak.

## Acceptance

Packet format unchanged, calibration completes, raw tag decode has no new issue, precision is not degraded beyond baseline tolerance, and lossless rate improves as predicted.
