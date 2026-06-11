# MPTDC Tap Endcap Filler Plan

Status: `TYPICAL_ONLY`, `NOT_MMMC_SIGNOFF`, `NOT_FINAL_SILICON_SIGNOFF`

## Policy

Do not hard-code XH018 tap, endcap, filler, antenna, or tie cell names until
they are confirmed from the actual LEF/Liberty files used by the lab flow.

The stable placeholder config is:

`MPTDC/pnr/config/xh018_cells.tcl`

The discovery helper is:

`MPTDC/pnr/scripts/discover_xh018_physical_cells.sh`

## Required Cell Classes

- well tap or substrate tap cells
- row endcap cells
- filler cells
- decap cells if required by density or local supply stability
- antenna cells if required by routing
- tie-high and tie-low cells if constants must be physically tied

## Stop Condition

If tap/endcap/filler insertion is attempted while `xh018_cells.tcl` is still
marked unconfirmed, the implementation script must stop or run in report-only
mode.
