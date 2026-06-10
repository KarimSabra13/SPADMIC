# O10.1 Review of O10 Failure Modes

Input run:

- `results/innovus/20260604_o10_typical_feasibility`
- Run HEAD: `7a74526f20d357e1d34eaa086386be837c369bde`
- Result commit reviewed at HEAD: `49e79c4ea57fd2cee160a61ed5115aed6dc1a93a`

## What O10 Did Achieve

- Innovus initialized the O9 post-synthesis netlist and real `RO_tune4` LEF.
- Slow and fast `RO_tune4` instances were found and physically placed.
- 64/64 PD cells were found for the PD matrix.
- Floorplan, placement, CTS stage attempt, route, DEFs, and checkpoints were produced.
- Route produced a physically useful first checkpoint.

## Why O10 Was Incomplete

- `reports/SUMMARY.md` and `manager/MANAGER_SUMMARY.md` were missing because the Tcl reporting flow aborted before final reporting.
- Screenshot status falsely reported success. Innovus warned `dumpToGIF` cannot run in `-nowin`, and no PNG files were created.
- Phase-net reporting used unsafe Tcl strings such as `*${family}_phase\\[$i\\]*`; Tcl interpreted `[` as command substitution and failed with `invalid command name "0\\"`.
- Legacy PD reporting expected `mptdc_pnr_sandwich_boxes`, while O10 defined only `mptdc_o10_boxes`.
- The O9 SDC overlay referenced Genus-side `design(...)` variables and aborted under Innovus with `CTE-27`.
- CTS intended `clk_sys` only, but the fallback generated a generic CCOpt spec that included RO clocks. CCOpt failed, so O10 did not have a valid clk_sys-only CTS result.
- The wrapper wrote missing outputs in top-level `SUMMARY.md` but still exited with the Innovus return code only.

## Timing Caveat

O10 post-route timing is not timing-decision quality. The top post-route path was an external output delay path on `acq_data_o`, and reset recovery paths also appeared. These do not directly answer whether the O9 residual `FAST_TAG_TO_PD_TS` paths improved or worsened in placement.

## Repair Direction

O10.1 repairs the flow and reruns the same physical feasibility intent. It is not an architecture change and must still be reviewed as typical-only feasibility.
