# O6C Characterization Results

Date: 2026-06-02

Status: RTL implemented, characterization not run

## Summary

Solution C characterization has not started. The C1 Galois/shift-mostly decode
mode, decode table artifacts, and selectable RTL fast-tag mode are prepared.
The production packet format is unchanged: HIT W0[7:1] still carries the
existing 7-bit `nfast` field, with interpretation selected by manifest
`nfast_encoding`.

Do not proceed to Genus for Solution C until this file is populated with Stage 1
and Stage 2 results.

## RTL/Manifest Contract

```text
raw_lfsr_tag:
  RTL selector = default TAG_ENCODING_SEL=TAG_ENC_LFSR_FIBONACCI

raw_galois_tag:
  RTL selector = +define+MPTDC_FAST_TAG_GALOIS
```

Every O6C characterization manifest must include `nfast_encoding`,
`fast_tag_encoding`, `rtl_tag_define_or_parameter`, and decode-table hash.

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
