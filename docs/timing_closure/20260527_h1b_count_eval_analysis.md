# 20260527 H1b Count/Eval Split Analysis

## Purpose

The H1/H4 server run improved `clk_sys` timing but left the measurement
controller count/evaluate cone as one of the worst real backend setup paths.
This patch tests the next narrow hypothesis:

H1b: splitting final hit-total registration from hit-count/flag publication will
remove the remaining `row_cnt_q -> meas_ctrl_hit_count_q/flags_q` cone from the
top `clk_sys` path set.

## Evidence Before Patch

Genus run: `results/genus/20260527_1030_h1_drain_pipeline_genus/`

Targeted result compared with `20260527_0945_targeted_genus_reports`:

| Metric | Before | After H1/H4 | Delta |
|---|---:|---:|---:|
| `clk_sys` WNS | -1486.0 ps | -968.1 ps | +517.9 ps |
| `clk_sys` TNS | -91719.4 ps | -48974.7 ps | +42744.7 ps |
| `clk_sys` violating paths | 79 | 72 | -7 |

Remaining H1 endpoints from
`results/genus/20260527_1030_h1_drain_pipeline_genus/timing_clk_sys_violations.rpt`:

| Slack ps | Path |
|---:|---|
| -968 | `row_cnt_q[1][1] -> flags_q.closed_by_fast_maxhit` |
| -960 | `row_cnt_q[0][1] -> hit_count_q[2]` |
| -960 | `row_cnt_q[0][1] -> hit_count_q[0]` |
| -960 | `row_cnt_q[0][1] -> hit_count_q[1]` |
| -913 | `row_cnt_q[1][1] -> flags_q.closed_by_watchdog` |

These are bucket A paths: real `clk_sys` setup paths. They are not async,
held-bus CDC, oscillator tap, or constraint-artifact paths.

## Patch

`mptdc_meas_ctrl` now uses:

```text
IDLE -> MEASURE -> SNAPSHOT -> COUNT -> EVAL -> CAPTURE -> CLEAR -> IDLE
```

The new register boundary is:

- `COUNT`: `total_hits_q <= total_cnt_comb`
- `EVAL`: `hit_count_q <= eval_hit_count_comb`; `flags_q <= eval_flags_comb`

The evaluate logic now consumes `total_hits_q`, not the direct row-count sum.
This cuts the one-cycle path from row-count registers through final sum,
saturation compare, flag logic, and metadata publication.

## Protocol Check

Capture-before-clear remains intact:

- `snapshot_en_o` in `SNAPSHOT`
- no capture or frontend clear in `COUNT` or `EVAL`
- `capture_en_o` and `fe_clear_o` in `CAPTURE`
- `pd_clear_o` in `CLEAR`

The source image remains held for one additional `clk_sys` cycle before context
publication and clear. That changes backend latency only; it should not alter
TDC precision or Vernier linearity because the raw measurement image has already
been frozen and sampled before the added stage.

## Local Evidence

Run ID: `20260527_1200_h1b_count_eval_split`

Evidence:

- `results/local_verilator/20260527_1200_h1b_count_eval_split/SUMMARY.md`
- `results/local_verilator/20260527_1200_h1b_count_eval_split/test_summary.txt`
- `results/local_verilator/20260527_1200_h1b_count_eval_split/lint.log`

Result: PASS 10/10

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

- prove whether `row_cnt_q -> meas_ctrl_hit_count_q/flags_q` leaves the worst
  `clk_sys` path set
- compare `clk_sys` WNS/TNS/path count against
  `20260527_1030_h1_drain_pipeline_genus`
- confirm latch audit remains the expected 7 intentional async/event latches
- confirm max-transition violations do not materially regress

Xcelium:

- prove the extra backend latency is accepted by directed and VIP regressions
- confirm packet/acq records remain latency-insensitive equivalent
- confirm backpressure and two-context behavior remain intact

Innovus:

- defer until Genus confirms a meaningful backend timing improvement or until
  physical effects need to be separated from logic depth.

## Risk

Functional risk: low to medium. The FSM adds one `clk_sys` cycle before
metadata publication and context capture.

Linearity/precision risk: low. No PD cells, oscillator wrappers, phase taps,
STOP capture, raw exported calibration fields, or packet meanings are changed.

Rollback if:

- `hit_count` differs from bitmap saturation semantics
- flags differ for equivalent held images
- clear can occur before snapshot/context protection
- context becomes visible before complete metadata is registered
- Xcelium directed or VIP regression fails
- Genus shows the targeted path did not improve and a new worse `clk_sys` path
  is introduced by this patch
