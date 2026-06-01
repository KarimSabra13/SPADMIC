# O3 Current RTL vs Latest Genus Sanity Check

Date: 2026-06-01

Branch inspected: `SPADMIC_localtag`

Baseline HEAD before O3 edits: `1e3fb188303e2755de403ac5c3571b27bc2feca8`

Latest Genus evidence used:

- `results/genus_osc_pd/20260601_o2_raw_tag_genus/`
- `results/genus_osc_pd/20260601_o1c2_fast_count_audit_genus/`

## Sanity Results

| Question | Answer | Evidence |
| --- | --- | --- |
| Is O2 raw fast tag present in RTL? | yes | `mptdc_core.sv` instantiates `gen_fast_tag_col[nf].u_fast_tag` and feeds `fast_tag_col[nf]` to PD cells. |
| Is the old global `u_fast_cnt -> 64 PD cells` path gone? | yes in current RTL and O2 netlist | No `u_fast_cnt` instance remains in `mptdc_core.sv`; O2 post-synth netlist contains local tags and no `u_fast_cnt`. |
| Is `pd_gate` held through `ST_M_SNAPSHOT`? | yes | `mptdc_meas_ctrl.sv` drives `pd_gate_o` high in `IDLE`, `MEASURE`, and `SNAPSHOT`. |
| Is `mptdc_pd_cell` still gating `slow_phase` externally? | no | `mptdc_core.sv` passes raw `slow_phase[ns]`; `detect_en_i` carries `pd_enable_gated`. |
| Is `u_slow_cnt` still `mptdc_gray_cnt_sync` before O3? | yes | O2 RTL still instantiated `mptdc_gray_cnt_sync u_slow_cnt`. |
| Is slow Gray-to-binary decode still happening in fast domain before O3? | yes | `mptdc_gray_cnt_sync` decoded Gray into `dst_count_latched` on `osc_fast_ph0`. |
| Is `start_wdt_cnt` still a binary counter in slow domain before O3? | yes | O2 RTL had `always_ff @(posedge slow_phase[0]) start_wdt_cnt <= start_wdt_cnt + 1`. |
| Is H4b `ST_D_EMIT` already in `mptdc_drain_ctrl`? | yes | Drain FSM contains `ST_D_EMIT`, `emit_wr_data_q`, and `pending_wr_data_q`. |
| Are latest Genus results consistent with current O2 RTL? | yes, except stale focused files | Actual O2 `timing_violations.rpt` shows slow counter/watchdog, slow decode, PD capture, and clk_sys drain families. Stale fast-count focused reports must be ignored. |

## Conclusion

The O3 patch is being applied to the correct baseline: O2 raw fast tags are
present and the old global fast counter path is already removed. The remaining
Genus blockers map directly to current RTL structures:

- `u_slow_cnt` binary/Gray logic.
- slow Gray decode registered in the fast domain.
- slow-domain binary START watchdog.
- PD-cell edge-detect control feeding the tag capture D path.
- residual `clk_sys` drain timing.

This justifies one coherent O3 measurement-fabric cleanup before another Genus
run.
