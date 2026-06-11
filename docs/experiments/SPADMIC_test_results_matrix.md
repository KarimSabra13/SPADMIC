# SPADMIC_test Results Matrix

Status values: `TODO`, `PASS`, `FAIL`, `REJECT`, `ACCEPT`, `N/A`.

| Mode | Defines enabled | Verilator | Xcelium characterization | Genus | Innovus | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| `BASELINE` | none | Partial; `tb_lossless_pressure` saturated-FIFO envelope fails | TODO | TODO | N/A | Reference |
| `SAFE_TEARDOWN` | `MPTDC_SAFE_TEARDOWN` | Partial; teardown unit passes, baseline saturated-FIFO failure still present | TODO | TODO | TODO | Candidate safety patch |
| `ROW_SKIP` | `MPTDC_SAFE_TEARDOWN`, `MPTDC_DRAIN_ROW_SKIP` | Partial; targeted row-skip coverage passes, baseline saturated-FIFO failure still present | TODO | TODO | TODO | Candidate after Genus |
| `STRIDE2` | `MPTDC_SAFE_TEARDOWN`, `MPTDC_DRAIN_ROW_SKIP`, `MPTDC_DRAIN_SCAN_STRIDE2` | PASS for targeted regression set; `tb_lossless_pressure` saturated-FIFO failure is baseline-reproducible | TODO | TODO | TODO | Candidate |
| `CLEAR_EARLY` | `STRIDE2` plus `MPTDC_PD_CLEAR_EARLY` | TODO | TODO | TODO | TODO | Not default |
| `CAPTURE_CLEAR_EXPERIMENTAL` | Not implemented | N/A | N/A | N/A | N/A | Future only |

## Current Local Notes

- Packet format: unchanged by RTL edits.
- Precision risk: low expected for row-skip and stride-2 because changes occur after snapshot capture.
- Reset/recovery: `SAFE_TEARDOWN` implemented; fast-tag reset cleanup still open.
- `tb_lossless_pressure` fails in `BASELINE`, `SAFE_TEARDOWN`, `ROW_SKIP`, and `STRIDE2` during the full output-stall `saturation_release max_hits=1` envelope. This is recorded as a pre-existing saturated-FIFO stress issue, not an optimization regression.

## STRIDE2 Local Verilator Evidence

Passing tests:

- `tb_async_frontend_teardown_unit`: 10 pass, 0 fail.
- `tb_hit_capture_bridge_unit`: 31 pass, 0 fail.
- `tb_meas_ctrl_unit`: 132 pass, 0 fail.
- `tb_context_bank_unit`: 10 pass, 0 fail.
- `tb_drain_ctrl_unit`: 31 pass, 0 fail.
- `tb_drain_opt_unit`: 276 pass, 0 fail.
- `tb_drain_raw_tag_unit`: 8 pass, 0 fail.
- `tb_narrow16_tx_v2_unit`: 88 pass, 0 fail.
- `tb_fast_epoch_tag_unit`: 521 pass, 0 fail.
- `tb_single_conv`: pass, one 15-hit packet.
- `tb_multi_conv_stress`: pass, 100/100 conversions.
- `tb_backpressure`: pass, scenarios A/B/C.
- `tb_watchdog_recovery`: pass, watchdog packets and recovery.
- `tb_10_events_spacing_sweep`: pass.

Spacing sweep STRIDE2 results:

| STOP-to-next-START spacing | Accepted | Rejected |
| --- | ---: | ---: |
| 40 ns | 3 | 7 |
| 60 ns | 4 | 6 |
| 80 ns | 5 | 5 |
| 100 ns | 6 | 4 |
| 150 ns | 8 | 2 |
| 200 ns | 10 | 0 |
| 300 ns | 10 | 0 |
| 600 ns | 10 | 0 |

STRIDE2 bug fixed during local regression: the first stride-2 implementation could emit an extra HIT when the PD bitmap contained more hits than saturated `hit_count`. The fix prevents queuing the second hit of an adjacent pair once the advertised hit budget is exhausted.
