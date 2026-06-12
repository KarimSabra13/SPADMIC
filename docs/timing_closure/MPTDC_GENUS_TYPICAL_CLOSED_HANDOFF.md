# MPTDC Genus Typical Closed Handoff

Status: `GENUS_TYPICAL_CLOSED`, `TYPICAL_ONLY_TAPEOUT_PACKAGE`,
`READY_FOR_INNOVUS_TYPICAL_CLOSURE`, `NOT_MMMC_SIGNOFF`,
`NOT_FINAL_SILICON_SIGNOFF`

## Closed Genus Run

- Run ID: `spadmic_test_stride2_genus_repair8_jihd_exact_20260612_130302`
- Branch: `SPADMIC_test`
- Genus Git HEAD: `f46e1390800dc3ef03caa709560f024ba1e75fa5`
- Mode: `MPTDC_FINAL_TYPICAL_GENUS_REPAIR8_JIHD_EXACT_FAST_TAG_CLOSE`
- Frequency mode: `r750_delta5`
- Optimization mode: `STRIDE2`
- Standard-cell family: `JIHD`
- O13 topology: `RO_tune4/S[n] -> BUHDX4 -> BUHDX12 -> phase fabric`
- Packet format: unchanged
- raw_lfsr_tag: unchanged
- Genus closure label: `GENUS_TYPICAL_CLOSED`

## Closure Evidence

| Metric | Value |
|---|---:|
| Setup WNS | `+0.1 ps` |
| Setup TNS | `0 ps` |
| Setup violating paths | `0` |
| Real timed WNS | `+0.1 ps` |
| Real timed TNS | `0 ps` |
| Real timed violating paths | `0` |
| Max transition violations | `0` |
| Max capacitance violations | `0` |
| Max fanout violations | `0` |
| UNKNOWN_REVIEW_REQUIRED | `0` |

## Clock And Intent Checks

- PD Vernier exception: `64/64` paths matched, applied `YES`.
- O13 raw RO clocks: `16`.
- O13 buffered phase clocks: `16`.
- `clk_sys` async to buffered phase clocks: `YES`.
- RO_tune4 instances: `2`.
- old oscillator stub residue: `0`.
- Report helpers: `PASS`.
- Summary/raw agreement: `PASS`.
- Active SDC failures: `0`.

The stale `report_clocks final-driver generated-clock count = 0` field is not
the P&R readiness source of truth. For this closure handoff,
`BUFFER_PHASE_CLOCKS_FOUND=16`, `BUFFER_PHASE_CLOCKS_EXPECTED=16`, and
`CLK_SYS_ASYNC_TO_BUFFER_PHASE_CLOCKS=YES` are the authoritative clock-model
checks.

## Handoff Package

Stable location:

```text
work/handoff/genus_typical/mptdc_genus_typical_closed/
```

Populate it on the server from the closed Genus run:

```bash
bash MPTDC/pnr/scripts/prepare_mptdc_genus_typical_handoff.sh \
  spadmic_test_stride2_genus_repair8_jihd_exact_20260612_130302
```

The handoff manifest must include:

```text
HANDOFF_STATUS=GENUS_TYPICAL_CLOSED
RUN_ID=spadmic_test_stride2_genus_repair8_jihd_exact_20260612_130302
READY_FOR_INNOVUS_TYPICAL_CLOSURE=YES
NOT_MMMC_SIGNOFF=YES
NOT_FINAL_SILICON_SIGNOFF=YES
```

## P&R Caution

The final Genus margin is only about `+0.1 ps`. That is positive STA, but it is
effectively zero physical margin. Innovus must preserve the former critical
`FAST_TAG_TO_PD_TS` family physically:

- place fast-tag generators near their corresponding PD columns;
- keep exact tag bits `0`, `5`, and `6` routes short and local;
- keep the PD matrix compact and regular;
- keep phase buffer drivers close to the PD island;
- keep clk_sys/backend routes east of the phase/PD island when possible;
- do not run CTS on raw RO or buffered phase clocks;
- do not resize or replace the 16 `BUHDX4`/`BUHDX12` root phase drivers without review.

## Limitations

This is Genus typical closure only. It is not MMMC signoff, not final silicon
signoff, and not tapeout-ready until Innovus P&R, route DRC, antenna, DRC/LVS,
extraction, power integrity, and final physical checks are clean.
