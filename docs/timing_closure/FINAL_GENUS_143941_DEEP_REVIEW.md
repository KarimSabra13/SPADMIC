# Final Genus 143941 Deep Review

Run: `final_typical_genus_repair_guarded_20260610_143941`

HEAD: `dc68ea7df8a40ea5b91f01455d5a5d8eb79ad87a`

This run is the clean baseline after backing out the unsafe pressure mode.  It
is not Innovus-ready, but it proves the remaining blockers are narrow and real.

## What Is Now Fixed

- Genus reaches export and writes netlist, SDC, SDF, and Innovus DB.
- RO_tune4 count is `2`; old oscillator stub count is `0`.
- Raw RO clocks and buffered phase clocks are both `16/16`.
- O13 `BUHDX4 -> BUHDX12` phase-buffer topology is intact.
- PD Vernier exception is solved: `64` q1 endpoints, `8` slow sources,
  applied `YES`, no overmatch, no undermatch.
- `UNKNOWN_REVIEW_REQUIRED` is `0`.
- SDC command failure count is `0`.
- Report helper failure count is `0`.
- Summary parser and raw timing agreement both pass.
- `MPTDC_RELAX_FAST_TAG_PRESERVE` is not active.

## Remaining Setup Timing

The real timing residual is:

- setup WNS: `-3.5 ps`
- setup TNS: `-77.1 ps`
- setup violating paths: `42`
- worst real family: `FAST_TAG_TO_PD_TS`

The path classification remains the same as the earlier fixed-parser baseline.
The detailed rows are dominated by fast-tag source C-to-Q delay:

- launch cells: `DFRRQHDX2`
- endpoint cells: mostly `DFRHDX2`
- worst tag bit: `5`
- source fanout: about `11`
- source transition: about `240-242 ps`
- endpoint setup: about `264-265 ps`

This is not CDC, not the intentional slow-to-fast PD Vernier exception, and not
a false-path candidate.  The next safe Genus lever is exact source-flop drive
bias: prefer `DFRRQHDX4` and avoid `DFRRQHDX1/2` for this repair mode.  Do not
relax fast-tag preserve or release broad PD/nfast capture fabric.

## Remaining DRV

The real DRV residual is:

```csv
net,logical_name,driver_inst,driver_cell,fanout,worst_transition_ps,limit_ps,violation_ps,sink_count,sink_family,proposed_fix
n_6984,PD_detect_enable_or_clear_derived_control,g33116,INHDX8,88,511,500,11,89,PD_DETECT_ENABLE_OR_CLEAR_LOCAL_LOGIC,TARGETED_BUFFER_TREE_OR_STRONGER_INVERTER_DRIVER_LOCAL_MAX_FANOUT_16_OR_32
```

This is one broad high-fanout non-phase control root, not 1015 independent
root causes.  The pressure run that used a design-wide `0.45 ns` transition
target made this worse, so the next repair keeps the real limit at `0.50 ns`
and enables exact strong-control bias: prefer `INHDX12` and avoid
`INHDX0/1/2/3/4/6/8`.

## Wrapper Noise

The console still printed repeated `Invalid list of objects` diagnostics.  This
is report-helper hygiene, not a timing blocker.  The helper now avoids calling
`foreach_in_collection` on already-expanded Tcl lists, which is the pattern
that emits those diagnostics even under `catch`.

The console checklist also claimed `timing_violations.rpt is empty`, which was
stale text.  Pass/fail already comes from parsed raw timing, and the console
text now says the report must have no real setup violations.

Power optimization warnings came from enabling `design_power_effort high`
without an MMMC power view.  The final typical repair wrapper now sets
`MPTDC_DESIGN_POWER_EFFORT=none`; vectorless power reports may still be
generated, but timing/DRV closure is no longer mixed with a power objective in
this single-view repair run.

## Next Run Decision

The next run should pass only if all of these are true:

- setup WNS is `>= 0 ps`;
- setup TNS is `0 ps`;
- setup violating path count is `0`;
- max transition, capacitance, and fanout violations are all `0`;
- report helper failures are `0`;
- SDC command failures are `0`;
- the O13 clock model and PD Vernier exception remain passing.

If timing improves but remains slightly negative, mark it `NEAR_CLEAN`.  If DRV
remains on the same single net, the next narrow step is a controlled buffer-tree
or source duplication strategy; do not re-enable broad pressure.
