# O9 Characterization Analysis

Date reviewed: 2026-06-04

This review covers the committed O9 R750 delta5 characterization artifacts under
`results/o9_char/20260604_o9_r750_delta5_overnight`.

The committed checkout contains manifests and an external file index. The
detailed characterization metric reports are listed under `/sim/ksabra/Sim/...`
but are not present in this checkout, so this review does not mark the
characterization as fully passed.

## Committed Artifacts

Files committed locally:

- `results/o9_char/20260604_o9_r750_delta5_overnight/EXTERNAL_RESULTS_LOCATION.txt`
- `results/o9_char/20260604_o9_r750_delta5_overnight/overnight_manifest.json`
- `results/o9_char/20260604_o9_r750_delta5_overnight/characterization/characterization_manifest.json`
- `results/o9_char/20260604_o9_r750_delta5_overnight/external_file_index.txt`

External result root recorded by the manifests:

- Results: `/sim/ksabra/Sim/20260604_o9_r750_delta5_overnight/results`
- Scratch: `/sim/ksabra/Sim/20260604_o9_r750_delta5_overnight/scratch`

The `/sim` path is server-local and is not accessible from this checkout.

## Run Configuration

| Item | Value |
|---|---|
| Run ID | `20260604_o9_r750_delta5_overnight` |
| Characterization Git HEAD | `a6583c799cd604c07e5d2e7065f846551fa7abdc` |
| Branch | `SPADMIC_localtag` |
| Simulator | `xcelium` |
| Stages | `char` |
| Status in manifest | `completed` |
| Frequency mode | `r750_delta5` |
| RTL define | `+define+MPTDC_FREQ_R750_DELTA5` |
| `OSC_TS_SLOW_PS` | 79 |
| `OSC_TS_FAST_PS` | 74 |
| `DELTA_STEP` | 5 ps |
| `DELTA_LSB` | 10 ps |
| `K_VERNIER` | 15 |
| NFAST encoding | `raw_lfsr_tag` |
| Tag type | Fibonacci LFSR |
| Decode table hash | `d006ac2ab9ae92ec739a9e08370d09a36a3f20b0383525712b04b0949e5d8bd6` |
| Packet format version | `fixed_raw_features_v2_7` |
| Analysis backend | `streaming` |
| Low-memory analysis | yes |
| Analysis jobs | 2 |
| Analysis chunksize | 200000 |
| Campaign seeds | 64 |
| Requested conversions per seed | 100000 |
| Requested campaign conversions | 6400000 |
| Campaign CSV count | 64 |
| Campaign raw row count | 96000127 |
| Fixed-delay seeds | 8 |
| Fixed-delay points | 10 |
| Fixed-delay conversions per seed/point | 5000 |
| Requested fixed-delay conversions | 400000 |
| Fixed-delay CSV count | 80 |

Top-level command recorded by the manifest:

```sh
MPTDC/scripts/sim/run_vip_overnight.sh --sim xcelium --stages char --jobs 32 --out-dir /sim/ksabra/Sim/20260604_o9_r750_delta5_overnight/results --scratch-root /sim/ksabra/Sim/20260604_o9_r750_delta5_overnight/scratch --freq-mode r750_delta5 --char-seeds 64 --char-n-conv 100000 --char-train-seeds 48 --char-out-mode raw_features --char-nfast-encoding raw_lfsr_tag --fixed-delay-seeds 8 --fixed-delay-n-conv 5000 --analysis-low-memory --analysis-jobs 2 --analysis-chunksize 200000 --log-memory --train-max-rows-per-seed 50000 --calibration-val-max-files 4 --rerun-char
```

## Packet And Protocol Evidence

| Check | Committed evidence | Result |
|---|---|---|
| Packet format version | manifest says `fixed_raw_features_v2_7` | present |
| Production packet unchanged | manifest says `true` | yes, per manifest |
| Word width | manifest says 16 | unchanged |
| Packet layout | `header + 2*hit_count hit words + eoc` | unchanged |
| `nslow` width | 7 | unchanged |
| `nfast` width | 7 | unchanged |
| `ns` width | 4 | unchanged |
| `nf` width | 4 | unchanged |
| Parser pass/fail | detailed report not committed | unavailable |
| Malformed packet count | detailed report not committed | unavailable |
| Missing EOC count | detailed report not committed | unavailable |
| Unexpected word count | detailed report not committed | unavailable |
| HEADER/HIT/EOC order | detailed report not committed | unavailable |
| Context/event/FIFO/drain checks | detailed report not committed | unavailable |

Packet format unchanged: yes, per committed manifest.

The frequency and calibration interpretation changed for O9 R750 delta5, but the
manifest says this is a model/calibration change, not a production packet layout
change. The detailed packet parser report still needs to be committed or
inspected from the server path before calling this a characterization pass.

## Raw Tag And Decode Evidence

| Check | Committed evidence | Result |
|---|---|---|
| NFAST encoding | `raw_lfsr_tag` | present |
| Decode mode | software | present |
| LFSR width | 7 | present |
| Tag width | 7 | present |
| LFSR seed | 1 | present |
| Tag columns | 8 | present |
| Column-offset version | `o2_initial_zero_offsets` | present |
| Decode table hash | `d006ac2ab9ae92ec739a9e08370d09a36a3f20b0383525712b04b0949e5d8bd6` | present |
| Unknown tag count | detailed report not committed | unavailable |
| Wrap ambiguity count | detailed report not committed | unavailable |
| NF-dependent decode/offset status | detailed report not committed | unavailable |

## Calibration And Precision Evidence

| Check | Committed evidence | Result |
|---|---|---|
| Calibration stage | manifest says `calibrate: true` | ran |
| Calibration model | `6d_lut_v2_7` | present |
| Training seeds | 48 | present |
| Training row cap | 50000 rows per seed | present |
| Validation file cap | 4 | present |
| Calibration completed | status `completed` in manifest | completed structurally |
| Mean error | detailed report not committed | unavailable |
| RMS error | detailed report not committed | unavailable |
| Fixed-delay RMS | detailed report not committed | unavailable |
| p95 absolute error | detailed report not committed | unavailable |
| p99 absolute error | detailed report not committed | unavailable |
| DNL/INL smoke | detailed report not committed | unavailable |
| Monotonicity | detailed report not committed | unavailable |
| Boundary-class bias | detailed report not committed | unavailable |
| Phase/bin coverage | detailed report not committed | unavailable |
| Hit-count distribution | detailed report not committed | unavailable |
| No-hit/max-hit rates | detailed report not committed | unavailable |
| Timeout/rejected events | detailed report not committed | unavailable |
| Memory peak | `analysis_memory_report.txt` listed externally only | unavailable |

The external file index lists the right reports to answer these questions:

- `analysis/sweep/summary_report.json`
- `analysis/sweep/summary_report.txt`
- `analysis/sweep/analysis_memory_report.txt`
- `analysis/sweep/chunked_metrics_summary.csv`
- `analysis/calibration/calibration_report.json`
- `analysis/calibration/calibration_report.txt`
- `analysis/calibration/val_reconstruction_errors_pre_post.csv`
- `analysis/calibration/plots/lut_inl_dnl.png`
- `fixed_delay/analysis/fixed_delay_report.json`
- `fixed_delay/analysis/fixed_delay_report.txt`
- `fixed_delay/analysis/fixed_delay_summary.csv`

Those files are not committed locally, so the quantitative precision result is
blocked from this checkout.

## Baseline Comparison

No committed numeric baseline summary was found in the O9 result tree. The
comparison below separates manifest-level facts from unavailable metric
summaries.

| Metric | Baseline | O9 R750 delta5 | Delta | Pass/Fail | Comment |
|---|---:|---:|---:|---|---|
| Packet parse pass | not found | not committed | n/a | blocked | Need parser report |
| Malformed packets | not found | not committed | n/a | blocked | Need packet parse report |
| Missing EOC | not found | not committed | n/a | blocked | Need packet parse report |
| Total requested campaign conversions | not found | 6400000 | n/a | evidence only | Manifest request |
| Campaign raw row count | not found | 96000127 | n/a | evidence only | Raw feature rows, not direct conversion count |
| Valid conversions | not found | not committed | n/a | blocked | Need analysis summary |
| Hit count mean/std | not found | not committed | n/a | blocked | Need analysis summary |
| No-hit rate | not found | not committed | n/a | blocked | Need analysis summary |
| Max-hit rate | not found | not committed | n/a | blocked | Need analysis summary |
| Raw tag unknown count | not found | not committed | n/a | blocked | Need decode report |
| Calibration RMS | not found | not committed | n/a | blocked | Need calibration report |
| Fixed-delay RMS | not found | not committed | n/a | blocked | Need fixed-delay report |
| p95/p99 error | not found | not committed | n/a | blocked | Need calibration/fixed-delay reports |
| DNL/INL smoke | not found | external plot listed | n/a | blocked | Need summary or image review |
| Boundary-class bias | not found | not committed | n/a | blocked | Need analysis summary |
| Runtime | not found | not committed | n/a | blocked | Need logs or summary |
| Memory peak | not found | external report listed | n/a | blocked | Need memory report |

## Characterization Conclusion

Do not label this `O9_CHARACTERIZATION_PASS` from the committed checkout alone.

The committed manifests prove that the O9 R750 delta5 characterization was run
to a completed state with the correct frequency mode, raw LFSR tag encoding,
packet format manifest, external scratch/result routing, and low-memory
streaming analysis settings. They do not include the detailed packet parser,
calibration, fixed-delay, DNL/INL, boundary-bias, hit distribution, or memory
metrics needed to prove:

- malformed packets = 0,
- missing EOC = 0,
- all raw tags decodable,
- no wrap ambiguity,
- calibration quality preserved,
- fixed-delay RMS acceptable,
- p95/p99 acceptable,
- DNL/INL smoke acceptable,
- context/drain/readout behavior clean.

Current characterization label:
`O9_CHARACTERIZATION_COMPLETED_MANIFEST_ONLY`,
`NOT_MMMC_SIGNOFF`,
`NOT_FINAL_SILICON_SIGNOFF`.

