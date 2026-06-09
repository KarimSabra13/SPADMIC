# O13 abs3 Clock Report Audit

Status: `IMPLEMENTED`

The abs2 wrapper counted final buffer clocks only in `report_clocks.rpt`, but the run-root `report_clocks.rpt` did not include the final generated clocks while `timing_summary.rpt` and the Genus log did.

Abs3 counts exact expected clock names across:

- `report_clocks.rpt`
- `report_clocks_generated.rpt`
- `timing_summary.rpt`
- `o13_clock_model_check.rpt`
- `o13_clock_model_check.sdc.rpt`
- Genus log

The summary now reports:

- `RAW_RO_CLOCKS_FOUND`
- `BUFFER_PHASE_CLOCKS_FOUND`
- `BUFFER_PHASE_CLOCKS_EXPECTED=16`
- `BUFFER_PHASE_CLOCKS_IN_ASYNC_GROUP`
- `CLK_SYS_ASYNC_TO_BUFFER_PHASE_CLOCKS`

If `BUFFER_PHASE_CLOCKS_FOUND != 16`, the run is not interpretable.
