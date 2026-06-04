# O10.1 Innovus Flow Repair Plan

Status: `O10_1_INNOVUS_FLOW_REPAIR`, `O10_INNOVUS_TYPICAL_FEASIBILITY`, `NOT_MMMC_SIGNOFF`, `NOT_FINAL_SIGNOFF`, `NOT_TAPEOUT_READY`.

## Goal

Repair the first Innovus feasibility flow without changing RTL, Genus, oscillator frequency, packet format, or architecture. O10.1 exists so the next server run is reproducible, report-complete, screenshot-fallback-capable, and honest about failures.

## Repairs

- Use an Innovus-safe R750_delta5 SDC overlay that does not reference Genus-only `design(...)` Tcl variables.
- Keep CTS restricted to `clk_sys`; protect RO phase clocks and never allow generic CCOpt to include them.
- Replace unsafe Tcl bus glob construction with helper-generated patterns.
- Add compatibility alias `mptdc_pnr_sandwich_boxes` for legacy PD placement reports.
- Generate required reports even when a sub-report fails; failed reports must contain an error row or failure text.
- Treat batch screenshots as optional and verified: a PNG must exist and be nonempty, otherwise write explicit GUI fallback instructions.
- Make the shell wrapper exit nonzero if required outputs are missing.

## Acceptance

Required outputs for a report-complete run:

- `reports/SUMMARY.md`
- `manager/MANAGER_SUMMARY.md`
- `reports/phase_net_loads.csv`
- `reports/fast_tag_loads.csv`
- `reports/pd_instance_placement.csv`
- `reports/pd_symmetry_summary.md`
- `reports/timing_post_route.rpt`
- `reports/drv_max_transition.rpt`
- `reports/route_summary.rpt`
- `def/01_floorplan.def`
- `def/02_place.def`
- `def/04_route.def`
- `checkpoints/restore_latest.tcl`

Screenshot acceptance is either at least one nonempty PNG or `screenshots/SCREENSHOT_EXPORT_FAILED.txt` with manual GUI restore instructions.

## Non-goals

- No RTL changes.
- No Genus rerun.
- No architecture redesign.
- No MMMC or signoff claim.
- No blind full rerun before the repaired scripts are committed.
