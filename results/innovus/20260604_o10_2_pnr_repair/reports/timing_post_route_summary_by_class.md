# O10.2 Post-Route Timing Summary By Class

REPORT_STATUS=REVIEW_REQUIRED

| Class | Report | Status | WNS ns | Violated path markers | Path markers | Notes |
|---|---|---:|---:|---:|---:|---|
| CORE_INTERNAL | `timing_post_route_core_internal.rpt` | ok | -0.638 | 82 | 100 | register-to-register core timing |
| IO_OUTPUT | `timing_post_route_io_output.rpt` | ok | -1.284 | 11 | 96 | block IO output timing; provisional IO budget, not signoff |
| ASYNC_RESET_RECOVERY | `timing_post_route_reset_recovery.rpt` | ok | -0.638 | 49 | 100 | recovery/removal classified separately from normal setup |
| RO_OSC_DOMAIN | `timing_post_route_ro_osc_domain.rpt` | ok | -0.020 | 2 | 88 | RO/local tag/PD oscillator-domain timing |
| CLK_SYS_INTERNAL | `timing_post_route_clk_sys_internal.rpt` | ok | -1.284 | 13 | 100 | clk_sys internal timing |

Do not let IO output or reset/recovery paths dominate the core closure conclusion.
