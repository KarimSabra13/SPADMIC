# O10.2 Innovus Typical Feasibility

- Run ID: `20260604_o10_2_pnr_repair`
- Purpose: first industry-style typical P&R feasibility / visualization flow.
- Caveat: `NOT_MMMC_SIGNOFF`, `NOT_FINAL_SIGNOFF`, `NOT_TAPEOUT_READY`.
- Starting Genus status: near-clean, WNS -1.6 ps, 7 residual fast-tag-to-PD paths.
- CTS status: `CTS_SKIPPED_CLEANLY_FOR_FEASIBILITY`
- RO phase clocks excluded from CTS: `no` attempted.

## Floorplan Concept

- Slow RO_tune4 north.
- PD matrix center.
- Fast RO_tune4 south.
- Digital backend right.

## Images
- Automatic screenshots unavailable in batch/nowin mode; see `GUI_SCREENSHOT_INSTRUCTIONS.md`.

These images or restore instructions show a typical-feasibility placement/routing view, not final signoff layout.

## Required Reviews

- Timing: `reports/timing_post_route_summary_by_class.md`.
- DRV: max transition, max cap, and max fanout reports.
- RO phase load: `reports/phase_net_loads.csv`; compare actual caps to analog max allowed load.
- PD matrix: `reports/pd_instance_placement.csv` and `reports/pd_symmetry_summary.md`.
- Screenshots: restore checkpoint using `GUI_SCREENSHOT_INSTRUCTIONS.md` if PNGs are absent.
