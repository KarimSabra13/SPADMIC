# MPTDC Timing Closure Status

Author: Karim Sabra

Current status: typical-only timing-closure development.  This is not MMMC and
not final tapeout signoff.

## Active Direction

The active direction is:

- Use the real `RO_tune4` macro abstract for slow and fast oscillators.
- Use R750_delta5 timing constants for the current typical closure target.
- Preserve BUHDX4 to BUHDX12 phase distribution.
- Keep RO raw loads auditable.
- Model buffered phase clocks at the final phase-driver outputs.
- Preserve the intentional PD Vernier slow-to-fast sampling relation with a
  narrow, count-checked exception.
- Keep packet format and calibration semantics unchanged.

## Open Closure Items

- Fresh typical Genus run through the stable wrapper.
- Fresh Innovus feasibility run through the stable wrapper.
- Review of RO raw-load and phase-buffer output-load reports.
- Xcelium smoke after cleanup.
- Characterization rerun after final physical topology.
- Final MMMC and signoff-quality checks.

## Evidence Location

Historical timing evidence is summarized under `docs/timing_history/`.  Raw
generated results are not source files and should not remain tracked in git.

## Signoff Label

Use this label for current results:

```text
TYPICAL_ONLY_NOT_MMMC_NOT_FINAL_SIGNOFF
```
