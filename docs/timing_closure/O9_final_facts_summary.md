# O9 Final Facts Summary

## 1. Configuration

| Item | Value |
|---|---|
| Branch | `SPADMIC_localtag` |
| Current HEAD | `1ee8e7101a7f263998b63cc736dfa38018e4e4ba` |
| Frequency mode | `O9_R750_DELTA5` / `r750_delta5` |
| `OSC_TS_SLOW_PS` | 79 |
| `OSC_TS_FAST_PS` | 74 |
| `DELTA_STEP` | 5 ps |
| `DELTA_LSB` | 10 ps |
| `K_VERNIER` | 15 |
| Slow period/frequency | 1.430 ns / about 699.3 MHz |
| Fast period/frequency | 1.333 ns / about 750.2 MHz |
| NFAST encoding | `raw_lfsr_tag` |
| Packet format | `fixed_raw_features_v2_7`, unchanged per manifest |
| Genus mode | final typical R750 delta5, effort `closure`, no MMMC |
| Characterization mode | Xcelium `char`, low-memory streaming analysis |
| Analog status | screenshot-derived typical model; analog tune codes still required |

## 2. Genus Result

| Item | Value |
|---|---:|
| Clean/violating | violating, but near-clean |
| WNS | -1.6 ps |
| TNS | -11.2 ps |
| Violating path count | 7 |
| Failing class | `OSC_FAST_REAL` |
| Failing family | `FAST_TAG_TO_PD_TS` |
| `OSC_SLOW_REAL` | clean, WNS 448.8 ps |
| `CLK_SYS_REAL` | clean, WNS 13.0 ps |
| `UNKNOWN_REVIEW_REQUIRED` | 0 |
| Max transition violations | 1120 |
| Max capacitance violations | 0 |
| Max fanout violations | 0 |
| Cell area | 495908.241 |
| Net area | 241729.647 |
| Total area | 737637.888 |
| Total power estimate | 154445317.988 nW |
| Genus peak memory | 2293.04 |
| RO_tune4 binding | valid, 2 instances |
| RO_tune4/S clock count | 16 |
| Old oscillator stubs | 0 |
| Old fast-counter residue | 0 |
| Old slow-counter residue | 0 |

Main remaining Genus risks:

- Seven real setup violations remain in the fast-tag-to-PD timestamp path.
- Max-transition DRVs remain numerous.
- Exception and clock-group reports have tool-command limitations.
- CDC/latch checks are manual audit evidence, not formal CDC signoff.

Current Genus label:
`O9_TYPICAL_GENUS_NEAR_CLEAN_RESIDUAL_FAST_TAG`,
`NOT_MMMC_SIGNOFF`,
`NOT_FINAL_SILICON_SIGNOFF`.

## 3. Characterization Result

| Item | Value |
|---|---|
| Run ID | `20260604_o9_r750_delta5_overnight` |
| Characterization HEAD | `a6583c799cd604c07e5d2e7065f846551fa7abdc` |
| Manifest status | completed |
| Campaign seeds | 64 |
| Requested campaign conversions | 6400000 |
| Campaign raw row count | 96000127 |
| Fixed-delay CSV count | 80 |
| Requested fixed-delay conversions | 400000 |
| Packet | unchanged per manifest |
| Calibration | stage enabled and manifest completed |
| Precision | detailed metrics not committed |
| Linearity | detailed DNL/INL summary not committed |
| Fixed-delay RMS | not committed |
| Raw tag | `raw_lfsr_tag`, decode hash recorded |
| Memory | low-memory streaming selected; peak not committed |

The committed characterization evidence is sufficient to prove the run
configuration and completed manifest state. It is not sufficient to prove packet
parser pass, zero malformed packets, zero missing EOC, raw-tag decode quality,
calibration RMS, fixed-delay RMS, p95/p99 error, DNL/INL smoke, boundary bias,
or memory peak.

Current characterization label:
`O9_CHARACTERIZATION_COMPLETED_MANIFEST_ONLY`,
`NOT_MMMC_SIGNOFF`,
`NOT_FINAL_SILICON_SIGNOFF`.

## 4. What Changed From Previous Architecture

- Old global oscillator counter structure remains removed.
- Old fast-counter residue count is 0.
- Old slow-counter residue count is 0.
- Local fast tags are used.
- Slow Johnson epoch structure remains.
- `raw_lfsr_tag` remains the active NFAST encoding.
- Packet format remains fixed at `fixed_raw_features_v2_7`.
- O9 adds the R750 delta5 frequency mode with 74 ps fast taps and 79 ps slow
  taps.
- The Vernier delta remains 5 ps and `DELTA_LSB` remains 10 ps.

## 5. What Is Still Provisional

- Typical-only Genus, no MMMC.
- No Innovus placement/routing/CTS yet.
- Oscillator data is still screenshot-derived and provisional.
- `RO_tune3` versus `RO_tune4` equivalence remains unconfirmed.
- `RO_tune4` Liberty is still a shell, not a real timing Liberty.
- Analog tune code for R750/R700 still needs confirmation.
- Characterization detailed summaries are not committed locally.
- This is not final silicon signoff and not tapeout signoff.

## 6. Next Recommendation

Do not run Innovus yet from the committed evidence currently in this checkout.

The next practical step is to commit/review the compact characterization summary
reports from the server external results tree, then either clear or explicitly
waive the -1.6 ps Genus residual and max-transition DRVs. After that, if the
characterization metrics pass and the residual synthesis risk is resolved or
accepted, move to Innovus typical feasibility.

Current overall label:
`O9_NEAR_READY_PENDING_CHAR_SUMMARIES_AND_SMALL_GENUS_DRV_REVIEW`,
`NOT_MMMC_SIGNOFF`,
`NOT_FINAL_SILICON_SIGNOFF`.

