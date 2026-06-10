# 20260527 H4b Drain Emit Stage Analysis

## Purpose

After H1b, the worst real `clk_sys` backend setup paths moved into the drain
controller record-construction path. H4b tests one focused hypothesis:

H4b: adding a registered emit stage between scan/context data and the FIFO
pending-record register will reduce the
`ns_cnt_q/drain_ctx_q -> pending_wr_data_q` cone.

## Evidence Before Patch

Reference Genus run:
`results/genus/20260527_1200_h1b_count_eval_split_genus/`

`clk_sys` status:

- WNS: `-756.8 ps`
- TNS: `-37763.3 ps`
- violating paths: `62`

Top drain paths:

| Slack ps | Startpoint | Endpoint |
|---:|---|---|
| -757 | `u_core_u_drain_ctrl_ns_cnt_q_reg[0]/C` | `u_core_u_drain_ctrl_pending_wr_data_q_reg[hit][ns][2]/D` |
| -757 | `u_core_u_drain_ctrl_ns_cnt_q_reg[0]/C` | `u_core_u_drain_ctrl_pending_wr_data_q_reg[hit][nf][2]/D` |
| -757 | `u_core_u_drain_ctrl_drain_ctx_q_reg[0]/C` | `u_core_u_drain_ctrl_pending_wr_data_q_reg[hit][nfast][0]/D` |
| -752 | `u_core_u_drain_ctrl_drain_ctx_q_reg[0]/C` | `u_core_u_drain_ctrl_event_seq_q_reg[0]/D` |

These are bucket A paths: real `clk_sys` setup paths. They are not CDC,
oscillator/PD, async clear, or constraint-artifact paths.

## Patch

`mptdc_drain_ctrl` now stages records before loading the FIFO skid register:

```text
IDLE -> META -> EMIT -> SCAN -> EMIT per HIT -> EOC
```

Implementation:

- added `ST_D_EMIT`
- added `emit_wr_data_q`
- `ST_D_META` stages `meta_rec`
- `ST_D_SCAN` stages `hit_rec` and advances the scan counters
- `ST_D_EMIT` transfers `emit_wr_data_q` into `pending_wr_data_q` when the
  existing pending FIFO skid stage is ready
- `ST_D_EOC` still waits for pending output acceptance before context release

## Expected Timing Effect

Before H4b, one cycle contained:

```text
scan counters / drain context / context read
  -> META/HIT record construction
  -> pending FIFO skid load mux
  -> pending_wr_data_q
```

After H4b, the target path should split into:

```text
scan counters / context read -> emit_wr_data_q
emit_wr_data_q -> pending_wr_data_q
```

The second path should be short because it launches from a registered record.
The first path may still need attention, but it no longer also includes the
pending FIFO accept/load mux.

## Functional Protocol

Allowed change:

- extra `clk_sys` drain latency per emitted META/HIT record

Not changed:

- record order: META, HITs in scan order, EOC/release
- packet/acq field meanings
- raw snapshot fields
- hit bitmap or hit count
- context release after final accepted output record
- capture-before-clear ordering
- Vernier/PD/oscillator fabric

## Local Evidence

Run ID: `20260527_1330_h4b_drain_emit_stage`

Result: PASS 10/10

Evidence:

- `results/local_verilator/20260527_1330_h4b_drain_emit_stage/SUMMARY.md`
- `results/local_verilator/20260527_1330_h4b_drain_emit_stage/test_summary.txt`
- `results/local_verilator/20260527_1330_h4b_drain_emit_stage/lint.log`

Tests:

- lint
- `tb_meas_ctrl_unit`
- `tb_hit_capture_bridge_unit`
- `tb_context_bank_unit`
- `tb_drain_ctrl_unit`
- `tb_single_conv`
- `tb_backpressure`
- VIP `smoke_single_conv`
- VIP `backpressure_integrity`
- VIP `vip_maxhits_matrix`

## Server Evidence Required

Genus:

- compare against `20260527_1200_h1b_count_eval_split_genus`
- prove whether `pending_wr_data_q` leaves the worst `clk_sys` endpoint set
- record `clk_sys` WNS/TNS/path-count delta
- confirm max-transition violations do not regress materially
- confirm latch audit remains expected

Xcelium:

- validate added readout latency against directed tests and selected VIP
  regression
- confirm backpressure and multi-conversion behavior remain intact

Innovus:

- defer until Genus confirms meaningful improvement.

## Risk

Functional risk: low to medium. The change affects readout latency and
backpressure behavior, but not record content.

Linearity/precision risk: low. The patch is entirely in the `clk_sys` drain
backend after context capture. It does not touch PD cells, oscillator wrappers,
phase taps, STOP metadata capture, raw calibration fields, or packet meanings.
