# O10.1 Innovus Typical Feasibility

- Run ID: `20260604_o10_1_innovus_repair`
- Purpose: first repaired Innovus typical feasibility / visualization flow.
- Caveat: `NOT_MMMC_SIGNOFF`, `NOT_FINAL_SIGNOFF`, `NOT_TAPEOUT_READY`.
- Starting Genus status: near-clean, WNS -1.6 ps, 7 residual fast-tag-to-PD paths.
- CTS status: `CTS_SKIPPED_FOR_FIRST_FEASIBILITY`

## Floorplan Concept

- Slow RO_tune4 north.
- PD matrix center.
- Fast RO_tune4 south.
- Digital backend right.

## Images
- Automatic screenshots unavailable in batch/nowin mode; see `GUI_SCREENSHOT_INSTRUCTIONS.md`.

These images or restore instructions show the first typical-feasibility placement/routing view, not final signoff layout.

## Required Reviews

- Timing: review core, IO, and RO-domain reports separately.
- DRV: review max transition/cap/fanout reports.
- Phase nets: review phase-net and fast-tag load CSVs.
- PD matrix: review 64-cell placement/symmetry summary.
