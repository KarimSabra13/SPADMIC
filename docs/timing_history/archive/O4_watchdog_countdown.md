# O4 START Watchdog Countdown

O3 moved the START-only timeout from `slow_phase[0]` into `clk_sys`. That removed a slow-domain binary counter, but the O3 implementation still used:

- programmable limit selection
- `limit - 1`
- wide `>=` compare
- increment

O4 changes this to a countdown:

1. On a newly observed START-without-STOP window, load `timeout - 1`.
2. While START is held and STOP is not observed:
   - if the counter is zero, assert `start_timeout_latched`
   - otherwise decrement by one
3. Hold `start_timeout_latched` until `meas_fe_clear`.
4. Clear on reset or measurement clear.

This keeps the same recovery function but reduces the update cone to zero-detect/decrement. The synthetic STOP remains a held level into `mptdc_async_frontend_v2`, not a narrow pulse.

Functional requirements retained:

- `cfg_i.wdt_ctx_timeout == 0` uses the default timeout.
- real STOP before timeout prevents a watchdog close.
- timeout flag behavior remains through `mptdc_meas_ctrl`.
- normal START/STOP conversions are not affected.
