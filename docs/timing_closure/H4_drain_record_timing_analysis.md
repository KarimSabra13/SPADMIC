# H4 Drain Record Timing Analysis

Hypothesis: a normal clk_sys drain-control cone is driving the worst backend
setup paths.

Status: confirmed by `20260527_0945_targeted_genus_reports`.

## Evidence

Relevant reports:

- `MPTDC/lab_snapshots/genus_20260527_0945_targeted_genus_reports/timing_clk_sys_violations.rpt`
- `MPTDC/lab_snapshots/genus_20260527_0945_targeted_genus_reports/timing_drain_ctrl_hotspots.rpt`

Worst clk_sys paths:

| Slack ps | Startpoint | Endpoint |
|---:|---|---|
| -1486 | `u_core_u_drain_ctrl_state_q_reg[1]/C` | `u_core_u_drain_ctrl_pending_wr_data_q_reg[hit][nfast][6]/D` |
| -1486 | `u_core_u_drain_ctrl_state_q_reg[1]/C` | `u_core_u_drain_ctrl_pending_wr_data_q_reg[hit][nfast][2]/D` |
| -1485 | `u_core_u_drain_ctrl_released_mask_reg[1]/C` | `u_core_u_drain_ctrl_pending_wr_data_q_reg[hit][nfast][5]/D` |
| -1483 | `u_core_u_drain_ctrl_released_mask_reg[1]/C` | `u_core_u_drain_ctrl_pending_wr_data_q_reg[meta][phase0_snap]/D` |

These are A bucket paths: real clk_sys setup paths. They must close at 6.25 ns.

## RTL Cause

`mptdc_drain_ctrl` used an IDLE pre-point mux on the context read address:

```systemverilog
read_ctx_o = (state_q == ST_D_IDLE) ? selected_ctx : drain_ctx_q;
```

`selected_ctx` depends on the valid/free/released state of the context bank. That
makes the path include state/released-mask priority selection, context read
muxing, snapshot-field selection, META/HIT record assembly, and the
`pending_wr_data_q` capture flop.

The mux is not needed for correctness. The FSM already registers the selected
context into `drain_ctx_q` at IDLE-to-META. The META record is constructed and
offered from `pending_wr_data_q` on the following cycle, giving the context bank
read data a full cycle to settle through the registered context index.

## Patch

Change the read address to:

```systemverilog
read_ctx_o = drain_ctx_q;
```

This removes `state_q` and `released_mask` from the launch side of the wide
record-construction cone.

## Verification

Local Verilator run:

- Run ID: `20260527_1030_h1_drain_pipeline`
- Result: PASS 10/10
- Evidence: `results/local_verilator/20260527_1030_h1_drain_pipeline/SUMMARY.md`

Covered locally:

- drain controller unit smoke
- backpressure integration smoke
- VIP backpressure integrity
- no record loss/reordering in the local Verilator scope

## Risk

Linearity/precision risk: low.

The patch is purely clk_sys backend readout sequencing. It does not touch:

- PD cells
- oscillator wrappers or phase taps
- START/STOP event relation
- STOP metadata capture
- held-bus snapshot bridge
- raw calibration fields
- packet field meanings

Functional risk remains nonzero because the context read address no longer
pre-points in IDLE. The directed and VIP Verilator tests passed, but the next
server request includes Xcelium regression before treating this patch as stable.

## Server Decision

Request Genus on the patched commit. The patch is useful only if the next report
shows improvement or removal of `u_core_u_drain_ctrl_pending_wr_data_q_reg` from
the worst clk_sys endpoint set.
