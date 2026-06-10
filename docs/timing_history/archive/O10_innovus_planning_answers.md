# O10 Innovus Planning Answers

Date: 2026-06-04

## Human Answers Captured

- Run depth: full feasibility through floorplan, placement, `clk_sys` CTS, route, screenshots, and reports.
- Floorplan policy: sandwich floorplan, about 60% utilization.
- Clock policy: CTS for `clk_sys` only; RO phase nets are not CTS trees.

## Locked Defaults

- Run label: `O10_INNOVUS_TYPICAL_FEASIBILITY`.
- Timing label: `NOT_MMMC_SIGNOFF`, `NOT_FINAL_SIGNOFF`, `NOT_TAPEOUT_READY`.
- Timing input: O9 R750_delta5 typical view.
- Frequency mode: `O9_R750_DELTA5`.
- Packet format: unchanged from O9 manifest.
- Characterization pass label: not claimed until compact metrics are committed and reviewed.

## Operational Defaults

- Proceed through route unless a fatal setup/tool problem occurs.
- Accept the seven O9 residual Genus paths into P&R as `NEAR_CLEAN_PRE_PNR_RESIDUAL`.
- Track those exact start/end pairs in pre-place, post-place, post-CTS, and post-route reports.
- Generate PNG screenshots if Innovus supports automatic export; otherwise generate checkpoint/restore instructions.
