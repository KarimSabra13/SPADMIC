# MPTDC Routing Plan

Status: `TYPICAL_ONLY`, `NOT_MMMC_SIGNOFF`, `NOT_FINAL_SILICON_SIGNOFF`

## Goals

- Keep raw RO output routes short and low-load.
- Keep phase-buffer output routes balanced enough for calibration review.
- Reserve top metal primarily for power unless a documented local phase-routing
  exception is enabled.
- Produce route evidence, not a final signoff claim.

## Policy

- Use global signal routing on lower metal by default.
- Allow a localized PD/phase exception only when it is recorded in the run
  manifest.
- Audit raw RO output capacitance directly from connected pins and nets.
- Audit phase-buffer output loads per tap.
- Report route mismatch per slow and fast tap.
- Do not treat a clean wrapper summary as evidence unless the underlying route,
  DRV, timing, and load reports agree.

## RO Load Limits

- Preferred strict limit: `58.72 fF`
- Warning limit: `75.59 fF`
- Liberty max-cap relaxation is not an accepted fix.

## Stop Conditions

- any raw RO output load above `75.59 fF`
- missing direct pin-to-net evidence for RO load rows
- route shorts/opens in the phase fabric
- unreviewed antenna violations on RO or phase nets
