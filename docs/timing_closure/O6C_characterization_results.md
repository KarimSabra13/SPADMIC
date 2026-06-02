# O6C Characterization Results

Date: 2026-06-02

Status: not run

## Summary

Solution C characterization has not started. The C1 Galois/shift-mostly
software decode mode and decode table artifacts are prepared, but matching RTL
has not been enabled.

Do not proceed to Genus for Solution C until this file is populated with Stage 1
and Stage 2 results.

## Comparison Table

| Metric | Baseline raw_lfsr_tag | Solution C raw_galois_tag | Delta | Pass/Fail |
|---|---:|---:|---:|---|
| packet parse pass | TBD | TBD | TBD | TBD |
| malformed packets | TBD | TBD | TBD | TBD |
| missing EOC | TBD | TBD | TBD | TBD |
| hit count mean/std | TBD | TBD | TBD | TBD |
| no-hit rate | TBD | TBD | TBD | TBD |
| max-hit/overflow rate | TBD | TBD | TBD | TBD |
| tag decode unknown count | TBD | TBD | TBD | TBD |
| tag wrap/ambiguity count | TBD | TBD | TBD | TBD |
| delay reconstruction mean error | TBD | TBD | TBD | TBD |
| fixed-delay RMS | TBD | TBD | TBD | TBD |
| p95/p99 absolute error | TBD | TBD | TBD | TBD |
| DNL/INL smoke | TBD | TBD | TBD | TBD |
| boundary-class bias | TBD | TBD | TBD | TBD |
| phase0/slow_boundary distributions | TBD | TBD | TBD | TBD |
| runtime | TBD | TBD | TBD | TBD |
| memory peak | TBD | TBD | TBD | TBD |

## Required Evidence Paths

Baseline:

```text
results/o6_char/20260602_o6a_stage1_current_raw_lfsr_tag
results/o6_char/20260602_o6a_stage2_current_raw_lfsr_tag
```

Solution C:

```text
results/o6_char/20260602_o6c_stage1_raw_galois_tag
results/o6_char/20260602_o6c_stage2_raw_galois_tag
```
