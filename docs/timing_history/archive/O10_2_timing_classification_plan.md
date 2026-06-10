# O10.2 Timing Classification Plan

## Reason

O10.1 post-route WNS was dominated by `acq_data_o[*]` output-delay paths, while the O9 Genus residual issue was `FAST_TAG_TO_PD_TS`. O10.2 separates these concerns so IO/reset artifacts do not hide core or RO-domain timing.

## Classes

- `CORE_INTERNAL`: register-to-register internal timing.
- `IO_OUTPUT`: block output timing, including `acq_data_o`, CSR, and narrow output paths.
- `ASYNC_RESET_RECOVERY`: recovery/removal paths into resettable flops.
- `RO_OSC_DOMAIN`: oscillator-domain local tag, PD, and tap-clock timing.
- `CLK_SYS_INTERNAL`: clk_sys internal timing.
- `RO_PHASE_LOAD`: phase source net capacitance, transition, fanout, and load balance.

## O10.2 Reports

- `reports/timing_post_route_core_internal.rpt`
- `reports/timing_post_route_io_output.rpt`
- `reports/timing_post_route_reset_recovery.rpt`
- `reports/timing_post_route_ro_osc_domain.rpt`
- `reports/timing_post_route_clk_sys_internal.rpt`
- `reports/timing_post_route_summary_by_class.md`

## Interpretation Rule

Do not call the core clean or failing from the aggregate WNS alone. First identify whether the worst path is IO, reset/recovery, RO-domain, clk_sys internal, or real core data timing.
