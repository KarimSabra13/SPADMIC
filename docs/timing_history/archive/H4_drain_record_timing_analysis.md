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

## Server Result After First H4 Patch

Genus run `20260527_1030_h1_drain_pipeline_genus` confirmed that removing the
IDLE pre-point read-address mux helped, but did not close the drain cone.

Before patch:

- `state_q/released_mask -> pending_wr_data_q`: about `-1486 ps`

After first H4 patch:

- `drain_ctx_q -> pending_wr_data_q`: about `-956 ps`
- `drain_ctx_q -> event_seq_q`: about `-947 ps`
- `ns_cnt_q -> pending_wr_data_q`: about `-894 ps`

After H1b, the drain cone became the worst remaining real `clk_sys` setup cone:

| Slack ps | Startpoint | Endpoint |
|---:|---|---|
| -757 | `u_core_u_drain_ctrl_ns_cnt_q_reg[0]/C` | `u_core_u_drain_ctrl_pending_wr_data_q_reg[hit][ns][2]/D` |
| -757 | `u_core_u_drain_ctrl_ns_cnt_q_reg[0]/C` | `u_core_u_drain_ctrl_pending_wr_data_q_reg[hit][nf][2]/D` |
| -757 | `u_core_u_drain_ctrl_drain_ctx_q_reg[0]/C` | `u_core_u_drain_ctrl_pending_wr_data_q_reg[hit][nfast][0]/D` |
| -752 | `u_core_u_drain_ctrl_drain_ctx_q_reg[0]/C` | `u_core_u_drain_ctrl_event_seq_q_reg[0]/D` |

These are still bucket A paths: real `clk_sys` setup paths.

## H4b Patch

The H4b local patch adds a registered `ST_D_EMIT` stage:

```text
IDLE -> META -> EMIT -> SCAN -> EMIT per HIT -> EOC
```

- `ST_D_META` stages the META record into `emit_wr_data_q`.
- `ST_D_SCAN` stages each HIT record into `emit_wr_data_q` and advances the scan
  counters.
- `ST_D_EMIT` transfers the staged record into the existing FIFO skid register
  only when `pending_wr_ready` is true.
- `ST_D_EOC` still waits until pending output is accepted before context
  release and `conv_done`.

Expected timing effect: the path into `pending_wr_data_q` should now launch from
registered `emit_wr_data_q`, not directly from `ns_cnt_q`, `drain_ctx_q`, and
the context-bank read mux. Remaining scan-to-emit paths may still exist, but
they should not also include the pending FIFO accept/load mux.

Functional effect: adds one drain `clk_sys` stage per emitted META/HIT record.
Packet fields, record order, context release ordering, and raw measurement data
are unchanged.

Local Verilator evidence:

- run ID: `20260527_1330_h4b_drain_emit_stage`
- result: PASS 10/10
- evidence:
  `results/local_verilator/20260527_1330_h4b_drain_emit_stage/SUMMARY.md`

Server Genus and Xcelium are required before keeping H4b.
