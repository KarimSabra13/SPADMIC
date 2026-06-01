# O3 START Watchdog Migration

## Why Change

O2 Genus reports `start_wdt_cnt_reg[*] -> start_wdt_cnt_reg[*]` as a slow-domain
timing violation. This watchdog is recovery/control logic, not precision
timestamp data, so it should not consume oscillator-domain timing margin.

## O3 Design

The START-only watchdog counter moves to `clk_sys`.

Inputs:

- synchronized `fe_start_latched`
- synchronized `fe_stop_latched`
- `cfg_i.wdt_ctx_timeout`

Behavior:

- while START is latched and STOP is not latched, count `clk_sys` cycles.
- when the threshold is reached, assert `start_timeout_latched`.
- hold `start_timeout_latched` until `meas_fe_clear`.
- feed the held level to `mptdc_async_frontend_v2.start_timeout_async_i`.

This preserves the existing synthetic STOP behavior: the frontend closes the
measurement normally, then the usual snapshot/capture/clear sequence runs.

## Threshold

If `cfg_i.wdt_ctx_timeout` is nonzero, O3 uses it as the sys-clock threshold.
If it is zero, O3 uses a default of 64 sys cycles so START-only conversions do
not hang indefinitely.

## Risk

The timeout is now measured in `clk_sys` cycles rather than slow oscillator
cycles. This is a recovery timeout only, so no Vernier precision or packet
field meaning should change. Xcelium/VIP watchdog scenarios remain required
before signoff.
