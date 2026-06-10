# H6 Constraint Audit

Hypothesis: constraints either hide real timing or overconstrain invalid paths.

Status: active investigation.

Primary evidence is in `docs/timing_closure/sdc_audit.md`.

## Baseline Findings

- `clk_sys` is still normally timed in the Genus summary: WNS `-1486.0 ps`,
  TNS `-91719.4 ps`, `79` violating paths.
- The worst detailed paths are not clk_sys; they are fast oscillator/tap to PD
  capture endpoints.
- `set_clock_groups -asynchronous` separates sys, slow oscillator, and fast
  oscillator groups, but it does not cut paths within the fast tap group. The
  top reported fast tap paths are therefore still timed.
- `check_timing_intent.rpt` reports `10` no-effect exceptions, requiring either
  cleanup or explicit waiver rationale.
- `report_constraints.rpt` failed because this Genus build does not support the
  checked-in `report_constraints` command. The next script revision should use
  supported alternatives where possible and preserve the failure text.

## Constraint Risks To Verify On Server

- Whether CDC max-delay constraints are suppressed by broader exceptions.
- Whether STOP metadata and held-bus CDC bounds are active.
- Whether any false path reaches ordinary clk_sys backend endpoints.
- Whether production shared-readout case analysis trims only local narrow16
  debug/readout logic, not required acquisition-record fields.
- Whether generated/tap clocks represent the intended placeholder oscillator
  contract without pretending final macro signoff.

## Decision

No weakening of clk_sys timing is proposed. The next action is a targeted Genus
run with explicit clk_sys and exception/DRV report collection.
