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

## O12B Wrapper Fix

The O10.2 route wrapper now writes:

- `manifests/stage_trace.csv`
- `manifests/current_stage.txt`
- `manifests/innovus_exit_classification.txt` when Innovus exits `139`

The wrapper now validates required reports even when Innovus returns `139`.

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
