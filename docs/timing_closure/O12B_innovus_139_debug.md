# O12B Innovus 139 Debug

Status: `O12B_PHASE_BUFFER_BALANCE_AND_CLEAN_PNR`

This is a feasibility/debug note, not signoff.

## Known Failure

The O12 PNR feasibility run `20260608_o12_phase_buffer_pnr_abs1` produced a
usable `04_route.enc.dat` checkpoint but the wrapper reported Innovus exit code
`139`.

Current interpretation:

- The checkpoint was useful enough for `20260608_o12_phase_buffer_analysis_abs2`
  to restore it and complete report-only RC/timing/load analysis.
- The original PNR wrapper did not record enough stage breadcrumbs to classify
  whether the `139` occurred during route, report generation, screenshot export,
  checkpoint save, or Innovus exit/cleanup.
- Therefore the PNR run must stay non-clean until O12B or a rerun proves the
  crash stage.

## O12B abs1 Failure

The first O12B report-only run, `20260608_o12b_phase_buffer_balance_abs1`, also
returned Innovus exit code `139`, but this crash is now isolated to the O12B
reporting helper rather than route optimization:

- restore, RC extraction, DRV reporting, and initial timing reporting completed;
- the last useful log section was O12B detailed phase-buffer report generation;
- Innovus printed repeated `IMPDBTCL-248`, `IMPDBTCL-206`, and
  `IMPDBTCL-210` errors for unsupported net attributes such as
  `total_capacitance`, `total_cap`, `capacitance`, `load_capacitance`,
  `wire_capacitance`, `pin_capacitance`, and `transition`;
- the stack trace entered `dbProcessWalkListGet` / `dbtcliGetCmd`;
- the reported tool message was `Crashed in AAE on net Unknown net`;
- required O12B files such as `phase_buffer_output_loads.csv`,
  `phase_buffer_topology.csv`, and `phase_buffer_placement.csv` were missing.

Classification for abs1:

- `INNOVUS_RUN_CLEAN=NO`
- `INNOVUS_EXIT_139_BEFORE_REQUIRED_OUTPUTS`
- crash stage: `phase_buffer_reports`

The root cause is unsafe speculative DB attribute probing in the new O12B
reporter.  The fix is to query supported attributes first, remove the `dbGet`
fallback for unknown net attributes, and write attribute/debug reports for the
next exact numeric-cap query.

## O12B abs2 Failure

The second O12B report-only run, `20260608_o12b_phase_buffer_balance_abs2`, did
not segfault.  Innovus exited `1` after O12B Tcl reported:

```text
MPTDC_O12B_ERROR: phase-buffer balance report generation failed:
extra characters after close-quote
```

The stage breadcrumb was:

```text
stage=phase_buffer_reports
status=failed
```

Partial CSVs were written, but required summaries were missing, including
`reports/SUMMARY.md`, `phase_buffer_balance_summary.md`,
`phase_buffer_placement_summary.md`, and
`timing_post_route_summary_by_class.md`.

Classification for abs2:

- `INNOVUS_RUN_CLEAN=NO`
- `INNOVUS_EXIT_1_BEFORE_REQUIRED_OUTPUTS`
- crash stage: `phase_buffer_reports`

The follow-up fix makes Tcl-list handling robust for Innovus object strings,
makes attribute/debug probe failures nonfatal, records full Tcl `errorInfo`, and
validates required reports for any nonzero report-only Innovus exit.

## O12B Wrapper Fix

The O12B wrapper now writes:

- `manifests/stage_trace.csv`
- `manifests/current_stage.txt`
- `manifests/innovus_exit_classification.txt` when Innovus exits `139`

The wrapper now validates required reports even when Innovus returns `139`.
It also requires all 16 `phase_buffer_output_loads.csv` rows to contain numeric
`total_cap_pf` before declaring the run report-complete.

Exit classification:

- `POST_REPORT_TOOL_EXIT_139`: all required outputs exist and pass validation,
  but Innovus returned `139` after useful reports/checkpoints were written.
- `INNOVUS_EXIT_139_BEFORE_REQUIRED_OUTPUTS`: required reports are missing or
  invalid, so the run is not usable for decision quality.

## Debug Procedure

For a future O12/O12B rerun:

```bash
RUN=20260608_o12_phase_buffer_pnr_abs1
sed -n '1,220p' results/innovus/$RUN/SUMMARY.md
cat results/innovus/$RUN/manifests/current_stage.txt
sed -n '1,220p' results/innovus/$RUN/manifests/stage_trace.csv
cat results/innovus/$RUN/manifests/innovus_exit_classification.txt
tail -120 results/innovus/$RUN/logs/innovus_o10_2.log
tail -120 results/innovus/$RUN/logs/innovus_${RUN}.log
```

Classify the last active stage as one of:

- `init`
- `floorplan`
- `place`
- `cts`
- `route.routeDesign`
- `route.optDesign_postRoute`
- `route.reports`
- `route.defOut`
- `route.saveDesign`
- `route.screenshot_*`
- `final_reports`
- `checkpoint`
- `exit_cleanup`

## Decision Rule

If the crash is post-report and all required outputs are validated, O12B may use
the run as feasibility evidence but must still label it `NOT_FINAL_SIGNOFF`.

If the crash occurs before required reports or checkpoints are available, the
run is invalid for O12B timing and placement decisions.
