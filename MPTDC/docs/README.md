# MPTDC Documentation Map

Author: Karim Sabra

Active documents describe the current product boundary. Legacy planning notes,
numbered drafts, and old O-stage narrative documents were removed from the
active documentation tree. Generated results may still exist under `results/`
or external work directories, but they are evidence, not owner-facing guidance.

## Active documents

| Topic | Document |
| --- | --- |
| Handoff entry | [`../HANDOFF.md`](../HANDOFF.md) |
| Architecture | [`architecture/MPTDC_ARCHITECTURE.md`](architecture/MPTDC_ARCHITECTURE.md) |
| Verification | [`verification/MPTDC_VERIFICATION.md`](verification/MPTDC_VERIFICATION.md) |
| Synthesis flow | [`synthesis/MPTDC_SYNTHESIS_FLOW.md`](synthesis/MPTDC_SYNTHESIS_FLOW.md) |
| Genus profile rationale | [`synthesis/GENUS_AXIS_CORE_TYPICAL_CLOSED_PROFILE.md`](synthesis/GENUS_AXIS_CORE_TYPICAL_CLOSED_PROFILE.md) |
| Timing status | [`timing_closure/MPTDC_TIMING_CLOSURE_STATUS.md`](timing_closure/MPTDC_TIMING_CLOSURE_STATUS.md) |
| PnR flow | [`pnr/MPTDC_PNR_FLOW.md`](pnr/MPTDC_PNR_FLOW.md) |
| TC-only PnR baseline | [`pnr/MPTDC_TC_CLOSURE_20260625_BASELINE.md`](pnr/MPTDC_TC_CLOSURE_20260625_BASELINE.md) |
| Calibration | [`calibration/MPTDC_CALIBRATION_FLOW.md`](calibration/MPTDC_CALIBRATION_FLOW.md) |
| Signoff limits | [`signoff_notes/MPTDC_SIGNOFF_LIMITATIONS.md`](signoff_notes/MPTDC_SIGNOFF_LIMITATIONS.md) |

## Documentation rules

- Use functional names such as “axis-core typical closure,” not sequence labels
  such as `O13`, `ABS5`, or `REPAIR8`, in active titles and commands.
- Keep historical names where they are required to correlate old reports.
- State the exact design top, timing view, source commit, run ID, result, and
  signoff boundary for every closure claim.
- Do not copy raw tool reports into active documentation. Summarize the decision
  and point to the external/generated evidence location.
- When an active document changes, update `../HANDOFF.md` if the owner-facing
  command, source of truth, or readiness state changed.

## Removed material

The removed documents were consolidated into the active architecture,
verification, synthesis, timing, PnR, calibration, and signoff-limit documents
above. If an old report is needed for forensic comparison, use the commit
history or the generated run directory named in the active timing-status page.
Do not reintroduce parallel narrative documents for the same owner decision.
