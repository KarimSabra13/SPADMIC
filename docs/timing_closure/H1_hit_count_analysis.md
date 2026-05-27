# H1 Hit-Count Analysis

Hypothesis: the 64-bit hit-count reduction is a main clk_sys setup killer.

Status: confirmed as one of the two dominant real clk_sys setup cones in the
targeted Genus run. It is not the top overall timing problem; the top overall
problem remains oscillator/PD measurement timing.

## RTL Review

Before the H1 patch, `MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv` contained a partially
staged hit-count implementation:

- `SNAPSHOT`: samples the held measurement image in `mptdc_hit_capture_bridge`
  and registers eight independent row counts in `row_cnt_q`.
- `COUNT`: sums registered row counts through a balanced tree, computes
  `hit_count_o` and close flags, and asserts `capture_en_o`.
- `CLEAR`: asserts `pd_clear_o` after the snapshot/context capture cycle.

Previous sequence:

```text
IDLE -> MEASURE -> SNAPSHOT -> COUNT -> CLEAR -> IDLE
```

The capture-before-clear invariant is preserved in this RTL:

- `snapshot_en_o` is asserted in `SNAPSHOT`.
- `capture_en_o` and `fe_clear_o` were asserted in `COUNT`.
- `pd_clear_o` is asserted in `CLEAR`.

## Targeted Genus Evidence

`timing_context_bank_hotspots.rpt` from
`MPTDC/lab_snapshots/genus_20260527_0945_targeted_genus_reports/` shows direct
row-count to context-bank violations:

| Slack ps | Startpoint | Endpoint |
|---:|---|---|
| -1484 | `u_core_u_meas_ctrl_row_cnt_q_reg[4][1]/C` | `u_core_u_ctx_bank_ctx_snapshot_q_reg[1][flags][closed_by_fast_maxhit]/D` |
| -1479 | `u_core_u_meas_ctrl_row_cnt_q_reg[4][1]/C` | `u_core_u_ctx_bank_ctx_snapshot_q_reg[0][hit_count][3]/D` |
| -1477 | `u_core_u_meas_ctrl_row_cnt_q_reg[0][2]/C` | `u_core_u_ctx_bank_ctx_snapshot_q_reg[0][hit_count][1]/D` |
| -1459 | `u_core_u_meas_ctrl_row_cnt_q_reg[7][1]/C` | `u_core_u_ctx_bank_ctx_snapshot_q_reg[0][hit_count][2]/D` |

These are A bucket paths: real clk_sys setup paths.

## Root Cause

The old `COUNT` cycle combined:

- final row-count summation from `row_cnt_q`
- max-hit saturation compare
- close-flag generation
- context-bank capture of raw snapshot plus metadata
- frontend clear pulse generation

This puts the context bank write flop at the end of the final row-count/flag
logic cone.

## Patch

The applied patch changes the backend sequence to:

```text
IDLE -> MEASURE -> SNAPSHOT -> COUNT -> CAPTURE -> CLEAR -> IDLE
```

- `SNAPSHOT`: samples the held measurement image and registers row counts.
- `COUNT`: registers final `hit_count_q` and `flags_q`.
- `CAPTURE`: asserts `capture_en_o` and `fe_clear_o`; context bank captures
  registered count/flags.
- `CLEAR`: asserts `pd_clear_o` after snapshot/context protection.

This is intentionally a smaller change than splitting into separate `COUNT_ROW`,
`COUNT_SUM`, and `COMMIT` enum states because row counts were already registered
in `SNAPSHOT`. The missing register boundary was between final sum/flags and
context publication.

## Local Verilator Evidence

Run ID: `20260527_1030_h1_drain_pipeline`

Result: PASS 10/10

Evidence:

- `results/local_verilator/20260527_1030_h1_drain_pipeline/SUMMARY.md`

Relevant tests:

- `tb_meas_ctrl_unit`
- `tb_context_bank_unit`
- `tb_drain_ctrl_unit`
- `tb_single_conv`
- `tb_backpressure`
- VIP `smoke_single_conv`
- VIP `backpressure_integrity`
- VIP `vip_maxhits_matrix`

## Decision

Keep the H1 patch for the next server iteration only if Genus confirms that the
row-count to context-bank path is removed or materially improved.

Because the FSM sequencing changed by one clk_sys cycle after the held snapshot,
server Xcelium regression is required before considering the patch stable.

Rollback trigger for future H1 patch:

- packet fields change
- raw snapshot fields change
- source clear can happen before snapshot/context protection
- context is visible before complete metadata is internally consistent
- hit_count differs from popcount/saturation semantics
- Verilator or server Xcelium sequencing regression fails
