# SPADMIC_test Teardown And Reset Hardening

## Selected Patch

The explicit frontend port option was selected.

`mptdc_async_frontend_v2` now has:

`frontend_teardown_busy_i`

In `MPTDC_SAFE_TEARDOWN`, START acceptance requires this input to be low. START rejection treats it as a blocking reason.

`mptdc_core` drives:

`frontend_teardown_busy = meas_fe_clear | meas_pd_clear | wdt_force_reset`

## Ready Semantics

In `MPTDC_SAFE_TEARDOWN`, `status_o.ready` is high only when:

- `conv_arm_i` is high.
- No frontend context is full.
- No START is latched.
- Measurement FSM state is `ST_M_IDLE`.
- Teardown busy is low.

## Fast-Tag Reset Decision

Fast-tag reset cleanup is not implemented in this first pass.

Current status: `RESET_RECOVERY_NOT_SIGNOFF_READY`.

The recommended future cleanup is to use clear-window initialization only and remove multi-phase use of a reset synchronized to `fast_phase[0]`. That must prove:

- First conversion after reset works.
- Fast tags return to `FAST_TAG_SEED`.
- No stale hits leak into a new context.

## Required Tests

- `tb_async_frontend_teardown_unit`
  - START during teardown is rejected.
  - START after teardown release is accepted.
  - START during PD-clear teardown is rejected.

- Integration and characterization must additionally prove:
  - Clear release occurs before re-arm.
  - First conversion after reset works.
  - Packet format is unchanged.
  - No stale hit appears from a previous context.
