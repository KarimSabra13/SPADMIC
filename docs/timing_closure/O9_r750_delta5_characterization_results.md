# O9 R750 Delta5 Characterization Results

Status: pending server Xcelium run.

This document must be completed only after the O9 R750 delta5 overnight
characterization finishes. O9 remains a typical characterization candidate
until then.

Expected server result root:

```text
/sim/ksabra/Sim/20260604_o9_r750_delta5_overnight/results
```

Expected server scratch root:

```text
/sim/ksabra/Sim/20260604_o9_r750_delta5_overnight/scratch
```

Expected repo evidence stub:

```text
results/o9_char/20260604_o9_r750_delta5_overnight
```

Raw simulation CSVs and xrun work libraries should stay under `/sim/ksabra` to
avoid home-directory quota pressure. Commit only curated manifests, indexes,
summaries, and this completed document unless a specific raw artifact is needed
for review.

Required comparison table:

| Metric | Baseline | O9 R750 delta5 | Delta | Pass/fail |
| --- | ---: | ---: | ---: | --- |
| Packet format unchanged | pending | pending | pending | pending |
| Parser malformed packets | pending | pending | pending | pending |
| Missing EOC | pending | pending | pending | pending |
| Raw tags decodable | pending | pending | pending | pending |
| Calibration completes | pending | pending | pending | pending |
| Fixed-delay RMS | pending | pending | pending | pending |
| P95 error | pending | pending | pending | pending |
| P99 error | pending | pending | pending | pending |
| DNL/INL smoke | pending | pending | pending | pending |
| Boundary-class bias | pending | pending | pending | pending |
| Hit-count distribution | pending | pending | pending | pending |
| Context/drain order | pending | pending | pending | pending |
| Memory report | pending | pending | pending | pending |

If characterization fails, stop and fix functionality or calibration before
running final Genus.
