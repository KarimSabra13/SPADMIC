# MPTDC Physical Verification Plan

Status: `TYPICAL_ONLY`, `NOT_MMMC_SIGNOFF`, `NOT_FINAL_SILICON_SIGNOFF`

## Prototype Checks

- route DRC report from Innovus
- connectivity check for shorts and opens
- antenna report if supported by the available deck
- density/fill readiness report
- macro obstruction and pin-access report
- supply connectivity audit

## Signoff Checks Still Required

- foundry-authorized DRC deck
- foundry-authorized LVS deck
- extraction deck and RC corner policy
- antenna signoff policy
- density and slotting rules
- final fill insertion and verification
- EM/IR signoff

## Tool Choice

Pegasus versus Assura remains an open decision. Do not label the prototype as
physical signoff until the runset choice and deck versions are recorded.
