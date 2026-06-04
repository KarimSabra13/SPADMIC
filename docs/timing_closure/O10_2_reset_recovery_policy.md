# O10.2 Reset And Recovery Policy

## Current Observation

O10.1 core-only timing showed reset/recovery checks into oscillator-domain fast tag registers. These are not the same as normal setup paths and must be classified separately.

## Reset Classes To Review

- `async_rst_n`: global asynchronous reset.
- clk_sys reset leaves and synchronizers.
- oscillator-domain reset/clear controls.
- PD `clear_window` behavior.
- fast tag `clear_window` behavior.
- slow Johnson reset/clear behavior.
- RO `rstb` start/stop control.

## O10.2 Policy

- Generate `reports/timing_post_route_reset_recovery.rpt`.
- Generate `reports/reset_recovery_summary.md`.
- Do not broadly false-path reset/recovery checks.
- If a reset release is protocol-safe because oscillators are idle and restart later, document that waiver explicitly before changing constraints.

## Required Evidence For Any Future Waiver

- Assertion and deassertion timing relative to each clock domain.
- Proof that affected oscillators are stopped or safely held during release.
- Proof that data capture cannot occur during unsafe recovery/removal windows.

O10.2 reports the issue; it does not waive it.
