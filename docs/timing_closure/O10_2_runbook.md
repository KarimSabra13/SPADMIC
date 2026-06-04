# O10.2 Runbook

## Validate Only

```bash
MPTDC_O10_2_MODE=validate_only bash MPTDC/pnr/scripts/server_run_innovus_o10_2_pnr_repair.sh 202606xx_o10_2_validate
```

Checks inputs and Tcl source/classifier sanity. Innovus is not launched.

## Place Only

```bash
MPTDC_O10_2_MODE=place_only bash MPTDC/pnr/scripts/server_run_innovus_o10_2_pnr_repair.sh 202606xx_o10_2_place
```

Runs init, floorplan, place, checkpoint, and report generation.

## Route Feasibility

```bash
MPTDC_O10_2_MODE=route_feasibility bash MPTDC/pnr/scripts/server_run_innovus_o10_2_pnr_repair.sh 202606xx_o10_2_pnr_repair
```

Runs init, floorplan, place, clk_sys-only CTS policy, route, reports, DEF/checkpoint, manager summary, and required-output validation.

## GUI Screenshot Export

```bash
MPTDC_O10_2_MODE=gui_screenshot bash MPTDC/pnr/scripts/server_run_innovus_o10_2_pnr_repair.sh 202606xx_o10_2_pnr_repair
```

Restores `checkpoints/restore_latest.tcl` in GUI mode and attempts PNG export.

## Caveat

O10.2 is typical feasibility only. It is not MMMC signoff, not final signoff, and not tapeout-ready.
