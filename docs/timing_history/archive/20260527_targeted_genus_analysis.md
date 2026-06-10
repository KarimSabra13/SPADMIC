# 20260527 Targeted Genus Analysis

Run ID: `20260527_0945_targeted_genus_reports`

Git HEAD run on lab server: `7cc0958f4f0492b9a741f6bc897c4e8b482d5181`

Local analysis HEAD: `62e894bb0f0e39390945bb7a18168ac6ae9a12cb`

Evidence:

- `MPTDC/lab_snapshots/genus_20260527_0945_targeted_genus_reports/timing_summary.rpt`
- `MPTDC/lab_snapshots/genus_20260527_0945_targeted_genus_reports/timing_clk_sys_violations.rpt`
- `MPTDC/lab_snapshots/genus_20260527_0945_targeted_genus_reports/timing_context_bank_hotspots.rpt`
- `MPTDC/lab_snapshots/genus_20260527_0945_targeted_genus_reports/timing_drain_ctrl_hotspots.rpt`
- `MPTDC/lab_snapshots/genus_20260527_0945_targeted_genus_reports/timing_fifo_hotspots.rpt`
- `MPTDC/lab_snapshots/genus_20260527_0945_targeted_genus_reports/report_high_fanout.rpt`
- `MPTDC/lab_snapshots/genus_20260527_0945_targeted_genus_reports/report_design_rules.rpt`
- `MPTDC/lab_snapshots/genus_20260527_0945_targeted_genus_reports/latch_audit.rpt`

## Summary

The targeted Genus run confirms two separate clk_sys timing problems and leaves
the oscillator/PD fabric as the largest signoff blocker.

Overall timing remains dominated by oscillator/PD measurement paths:

| Group | WNS ps | TNS ps | Paths | Classification |
|---|---:|---:|---:|---|
| `clk_osc_fast_tap1` | -3063.5 | -189314.3 | 72 | D: oscillator/PD measurement |
| `clk_osc_fast_tap2` | -3007.6 | -186450.8 | 72 | D: oscillator/PD measurement |
| `clk_osc_fast_tap3` | -2952.1 | -183135.9 | 72 | D: oscillator/PD measurement |
| `clk_osc_fast_tap4` | -2931.7 | -181297.5 | 72 | D: oscillator/PD measurement |
| `clk_osc_fast` | -2695.2 | -201039.0 | 94 | D: oscillator support counter |
| `clk_osc_slow` | -2638.7 | -51575.8 | 22 | D: oscillator support counter |
| `clk_sys` | -1486.0 | -91719.4 | 79 | A: real clk_sys setup |

Total TNS is `-1609481.8 ps` across `699` violating paths.

## Path Classification

The parser found `641` detailed paths in the targeted reports:

- `200` D bucket paths: oscillator/PD measurement.
- `441` A bucket paths: real clk_sys setup.

The worst detailed path remains in the measurement fabric:

- Group: `clk_osc_fast_tap1`
- Slack: `-3064 ps`
- Startpoint: `u_core_u_fast_cnt_bin_q_reg[2]/C`
- Endpoint: `u_core_gen_pd_row[5].gen_pd_col[1].u_pd/nfast_hit_latched_reg[2]/D`

This is not a safe target for backend retiming. It needs the oscillator macro
contract, tap-clock modeling, phase-load review, or a reviewed measurement-fabric
constraint/waiver package. No RTL patch in this iteration touches that fabric.

## clk_sys Root Causes

### Drain record construction cone

`timing_clk_sys_violations.rpt` and `timing_drain_ctrl_hotspots.rpt` show the
worst clk_sys paths ending in `u_core_u_drain_ctrl_pending_wr_data_q_reg`.
Examples:

| Slack ps | Startpoint | Endpoint |
|---:|---|---|
| -1486 | `u_core_u_drain_ctrl_state_q_reg[1]/C` | `u_core_u_drain_ctrl_pending_wr_data_q_reg[hit][nfast][6]/D` |
| -1485 | `u_core_u_drain_ctrl_released_mask_reg[1]/C` | `u_core_u_drain_ctrl_pending_wr_data_q_reg[hit][nfast][5]/D` |
| -1483 | `u_core_u_drain_ctrl_released_mask_reg[1]/C` | `u_core_u_drain_ctrl_pending_wr_data_q_reg[meta][phase0_snap]/D` |

RTL cause: `mptdc_drain_ctrl` pre-pointed the context-bank read address during
IDLE with:

```systemverilog
read_ctx_o = (state_q == ST_D_IDLE) ? selected_ctx : drain_ctx_q;
```

That lets `state_q` and `released_mask` participate in the selected-context
priority decision, then immediately feed the wide snapshot read path and the
META/HIT pending record construction flop. The selected context is already
registered into `drain_ctx_q` on the IDLE-to-META edge, and META is emitted on
the following cycle. The pre-point mux is therefore a timing cost without a
required cycle benefit.

Patch applied: make `read_ctx_o` depend only on registered `drain_ctx_q`.

Expected timing effect: remove `state_q`/`released_mask` from the launch side of
the wide pending-record construction path.

Functional risk: low. Drain ordering and packet fields are unchanged; only the
context-bank read address no longer pre-points during IDLE.

### Hit-count and context-publication cone

`timing_context_bank_hotspots.rpt` confirms H1/H2 as a real clk_sys problem:

| Slack ps | Startpoint | Endpoint |
|---:|---|---|
| -1484 | `u_core_u_meas_ctrl_row_cnt_q_reg[4][1]/C` | `u_core_u_ctx_bank_ctx_snapshot_q_reg[1][flags][closed_by_fast_maxhit]/D` |
| -1479 | `u_core_u_meas_ctrl_row_cnt_q_reg[4][1]/C` | `u_core_u_ctx_bank_ctx_snapshot_q_reg[0][hit_count][3]/D` |
| -1459 | `u_core_u_meas_ctrl_row_cnt_q_reg[7][1]/C` | `u_core_u_ctx_bank_ctx_snapshot_q_reg[0][hit_count][2]/D` |

RTL cause: the existing COUNT cycle did the final row-count sum, max-hit/flag
evaluation, context capture, and frontend clear pulse in one clk_sys cycle.

Patch applied:

```text
IDLE -> MEASURE -> SNAPSHOT -> COUNT -> CAPTURE -> CLEAR -> IDLE
```

- `SNAPSHOT`: samples the held source image and registers row counts.
- `COUNT`: registers final `hit_count_q` and `flags_q`.
- `CAPTURE`: commits context metadata and clears frontend ownership using the
  registered count/flags.
- `CLEAR`: clears the PD/source fabric after context protection.

Expected timing effect: break the `row_cnt_q -> context_bank` path so the context
bank captures registered `hit_count_q` and `flags_q`.

Functional risk: low to medium. Packet fields, raw snapshot fields, and hit
bitmap semantics are unchanged, but conversion close latency increases by one
clk_sys cycle. Xcelium server regression is required before calling this stable.

## DRV and Fanout

`report_design_rules.rpt` still shows severe max-transition violations:

- Max-transition total: `282226`

`report_high_fanout.rpt` top items:

- `clk_sys`: fanout `4853`
- `u_core_fast_phase[0]`: fanout `191`
- `u_core_fast_phase[1]`: fanout `161`
- `u_core_fast_phase[2]`: fanout `161`
- `u_core_fast_phase[3]`: fanout `160`
- `rst_core_n`: fanout `96`
- `u_core_meas_pd_clear`: fanout `64`

These do not justify broad false paths or random buffering. The actionable split
is:

- clocks and oscillator taps need CTS/macro/phase-load treatment, not backend
  RTL retiming;
- ordinary clk_sys controls such as reset leaves and PD clear may need local
  replication or PnR buffering after the next synthesis result shows whether the
  current backend patch exposes them as top remaining issues.

## Latch and Timing Intent

Latch audit remains the expected `7` intentional frontend/event latches:

- `u_core_u_frontend_active_ctx_q_reg[0]`
- `u_core_u_frontend_ctx_drain_q_reg[0]`
- `u_core_u_frontend_ctx_drain_q_reg[1]`
- `u_core_u_frontend_start_accept_seen_q_reg`
- `u_core_u_frontend_start_latched_q_reg`
- `u_core_u_frontend_start_reject_seen_q_reg`
- `u_core_u_frontend_stop_latched_q_reg`

Timing-intent warnings remain concentrated in known async/event structures:

- `69` sequential data pins driven by clock signal: PD clock-as-data and STOP
  metadata event-capture structures.
- `21` sequential clock pins without waveform: async latches/event capture pins.
- `10` timing exceptions with no effect.
- `5` async/reset inputs without clocked external delays.

These require waiver/constraint cleanup, not broad relaxation of real clk_sys
paths.

## Decision

Proceed with a focused clk_sys backend patch:

1. Remove the drain controller IDLE pre-point context-read mux.
2. Publish context metadata one cycle after the final hit-count/flag sum.

Do not change PD cells, oscillator wrappers, phase taps, STOP capture, raw
calibration fields, or packet field meanings.

Next required evidence:

- Genus rerun on the patch to see whether `pending_wr_data_q` and
  `ctx_snapshot_q` endpoints improve or disappear from top clk_sys paths.
- Xcelium server regression because measurement-controller sequencing changed.
- Innovus only after Genus shows the targeted clk_sys improvement or exposes a
  physical/DRV-dominated backend problem.
