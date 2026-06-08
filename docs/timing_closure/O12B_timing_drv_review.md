# O12B Timing And DRV Review

Status: `O12B_PHASE_BUFFER_BALANCE_AND_CLEAN_PNR`

This is a feasibility/debug review, not signoff.

## Required Reports

O12B requires:

- `reports/drv_max_cap.rpt`
- `reports/drv_max_transition.rpt`
- `reports/drv_max_fanout.rpt`
- `reports/timing_post_route_ro_osc_domain.rpt`
- `reports/timing_post_route_clk_sys_internal.rpt`
- `reports/timing_post_route_io_output.rpt`
- `reports/timing_post_route_reset_recovery.rpt`
- `reports/timing_post_route_summary_by_class.md`

## Review Classes

Timing must stay classified by role:

- `RO_OSC_DOMAIN`
- `FAST_TAG_TO_PD_TS`
- `PD_HIT_TO_TS_FREEZE`
- `LOCAL_FAST_TAG_SELF`
- `CLK_SYS_INTERNAL`
- `IO_OUTPUT`
- `ASYNC_RESET_RECOVERY`

Do not let provisional IO or reset recovery dominate the phase-buffer decision.

## Decision Rules

If raw RO max-cap is fixed but BUHDX4 output transition is poor:

- keep O12 phase isolation;
- evaluate stronger identical single-stage buffers such as `BUHDX6` or `BUHDX8`;
- do not relax the RO shell to hide load.

If timing worsens only through common buffer insertion delay:

- keep the delay visible;
- assess whether calibration can absorb it.

If tap-to-tap mismatch is large:

- prepare O12C placement constraints before changing RTL.

If phase-buffer power, mismatch, or analog review rejects the approach:

- only then evaluate RTL load reduction.
