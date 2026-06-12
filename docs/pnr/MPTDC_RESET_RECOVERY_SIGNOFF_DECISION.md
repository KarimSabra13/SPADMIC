# MPTDC Reset Recovery Signoff Decision

Status: `RESET_RECOVERY_REVIEW_REQUIRED`, `NO_GLOBAL_WAIVER`,
`NOT_SIGNOFF_READY`

## Purpose

This note defines how reset and clear recovery/removal paths are decided for the
density65 routed candidate. The current routed evidence shows reset/recovery WNS
near the same value as the headline core WNS, about `-0.903 ns`, so reset
checks must be separated from true setup before any closure claim.

Do not globally waive recovery/removal. Only exact protocol exceptions or RTL
fixes are allowed.

## Known Reset/Clear Structure

### Top-Level Reset

`mptdc_top_asic` receives `async_rst_n`. Local reset leaves are generated through
`mptdc_reset_sync` instances:

- `rst_input_mux_n`;
- `rst_csr_n`;
- `rst_core_n`.

The synchronizer contract is asynchronous assertion and synchronous deassertion
to its local clock.

### Core Reset Leaves

Inside `mptdc_core`, additional reset leaves are generated:

- `rst_sys_status_n`;
- `rst_sys_drain_n`;
- `rst_sys_fifo_n`;
- `rst_sys_tx_n`;
- `rst_sys_wdt_n`;
- `rst_fast_n`.

The `rst_fast_n` leaf is synchronized to `osc_fast_ph0`, while local fast-tag
generators are clocked by `fast_phase[nf]` per column. That is a review item:
release synchronous to one fast phase is not automatically synchronous to every
buffered fast tap.

### Measurement Clear

`meas_pd_clear` clears:

- `mptdc_fast_epoch_tag` through `clear_window`;
- `mptdc_slow_epoch_johnson` through `clear_window`;
- PD cell `q1/q2/hit_latched` through `clear_window`;
- stop-capture and other measurement-window state.

The RTL comments state that `clear_window` is safe because it is asserted when
oscillators are being reset or idle. The signoff decision still requires routed
timing evidence and protocol proof that release cannot race active oscillator
edges.

### Fast-Tag Timestamp Flops

In `mptdc_pd_cell`, `nfast_hit_latched` intentionally has no reset or clear and
tracks `nfast_tag_i` until a hit freezes it. This is not itself a reset recovery
failure, but it means reset/clear policy must prove that stale no-hit timestamp
state cannot be observed as valid hit data.

## Current Evidence Gap

The SPADMIC_test teardown hardening added `MPTDC_SAFE_TEARDOWN` behavior:

- START acceptance is blocked while teardown is busy.
- `frontend_teardown_busy` includes `meas_fe_clear`, `meas_pd_clear`, and
  watchdog-forced reset.

However, the recorded hardening note says fast-tag reset cleanup is not
implemented in that first pass and marks the status as
`RESET_RECOVERY_NOT_SIGNOFF_READY`. Therefore recovery/removal cannot be
considered closed from RTL intent alone.

## Required Path Review

For every negative recovery/removal path in `timing_recovery_removal.rpt`, fill:

| Signal | Affected registers | Clock domain | Release protocol | Release synchronous? | Oscillators stopped? | Exception justified? | RTL fix needed? |
|---|---|---|---|---|---|---|---|
| `async_rst_n` / local leaf | TBD | TBD | TBD | TBD | TBD | TBD | TBD |
| `meas_pd_clear` | TBD | fast/slow phase | TBD | TBD | TBD | TBD | TBD |
| `clear_window` | TBD | fast/slow phase | TBD | TBD | TBD | TBD | TBD |
| `rst_fast_n` | TBD | fast phase taps | TBD | TBD | TBD | TBD | TBD |

## Allowed Conclusions

### A. RESET_RECOVERY_CLEAN

Use only if there are no recovery/removal violations in the explicit
`timing_recovery_removal.rpt` report.

### B. RESET_RECOVERY_EXACT_PROTOCOL_EXCEPTIONS_APPLIED

Use only if every remaining violation has a written exact exception with proof:

- affected reset/clear signal;
- affected registers;
- exact clock domain;
- assertion and release protocol;
- proof oscillators are stopped or no capture edge can occur;
- proof no stale hit/timestamp can become packet-visible;
- exact SDC exception pattern, not a global false path.

### C. RESET_RECOVERY_RTL_FIX_REQUIRED

Use if a reset/clear release can occur while the receiving oscillator/domain may
produce active edges, or if the release is synchronized to the wrong phase for
the receiving register set.

### D. RESET_RECOVERY_REVIEW_REQUIRED

Use while the routed path evidence is incomplete or the release protocol has
not been proven.

## Current Decision

For the density65 clean candidate, the current decision is:

```text
RESET_RECOVERY_REVIEW_REQUIRED
```

Reason:

- routed recovery/removal WNS is negative;
- the failure appears to align with the headline `-0.903 ns` symptom;
- exact path names and check types still need classification from the new
  explicit reports;
- prior teardown hardening explicitly left fast-tag reset cleanup unresolved.

This blocks near-signoff/tapeout-ready wording until the result becomes A or B.
