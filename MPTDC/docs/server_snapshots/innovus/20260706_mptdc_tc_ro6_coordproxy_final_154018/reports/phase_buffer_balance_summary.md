# O13 Phase Distribution Balance Summary

REPORT_STATUS=REVIEW_REQUIRED

- Source run: `unknown`
- Strict analog D-load budget: `58.72 fF`.
- CN/clock-like estimate: `75.59 fF`.
- Expected topology: `RO_tune4/S[n] -> BUJIHDX4 -> BUJIHDX12 -> phase fabric`.
- XLIBD reference: `ro_phase_raw_pin_loads_xlibd.csv`, `phase_buffer_output_loads_xlibd.csv`, `fast_tag_loads_xlibd.csv`, `phase_net_loads_xlibd_enhanced.csv`, `phase_net_load_budget_summary.md`, `phase_buffer_xlibd_interpretation.md`.
- RAW_RO_LOAD_FIXED=YES
- FINAL_DRIVER_OUTPUT_LOAD_QUANTIFIED=YES
- TOPOLOGY_MATCHED=YES
- PLACEMENT_QUANTIFIED=NO
- TIMING_DECISION_QUALITY=NO
- Raw RO rows: 16.
- Matched raw RO rows: 16.
- Missing raw RO rows: 0.
- Raw fanout-1 rows: 16.
- Raw rows with numeric DB cap: 16.
- Final driver output rows: 16.
- Matched final driver output rows: 16.
- Missing final driver output rows: 0.
- Final driver output rows with numeric DB cap: 16.
- Max measured raw RO source load: `29.00 fF` at `slow S[7] u_core_u_osc_slow_u_ro_tune4/S[7]`.
- Max measured final driver output load: `779.00 fF` at `fast tap[0] u_core_u_phase_buf_fast/gen_phase_buf[0].u_drv/Q`.
- Max measured final driver output transition: `UNKNOWN`.

## Raw RO Budget Labels

| Label | Row count |
|---|---:|
| OK_STRICT | 16 |
| OK_CN | 0 |
| WARN_OVER_CN | 0 |
| FAIL_HIGH_LOAD | 0 |
| CRITICAL | 0 |
| UNKNOWN | 0 |

## Final Driver Output Labels

| Label | Row count |
|---|---:|
| OK_STRICT | 0 |
| OK_CN | 0 |
| WARN_OVER_CN | 1 |
| FAIL_HIGH_LOAD | 6 |
| CRITICAL | 9 |
| UNKNOWN | 0 |

This is O13 feasibility/debug evidence only. It does not waive timing, phase matching, characterization, power, or signoff.
