# O13 Abs5 Report-Failure Review

Status: `ABS5_REPORT_REPAIR_PREPARED`

## Abs4 Problem

Abs4's summary reported `SDC command failure count: 32`, but the detailed log showed the important constraint commands were not the source of those failures:

- `set_clock_groups`: successful 1, failed 0
- `set_false_path`: successful 27, failed 0
- `set_max_delay`: successful 11, failed 0
- `set_max_transition`: successful 1, failed 0

Most remaining errors were report-helper issues, especially `TIM-234` from passing bracketed endpoint names to `report_timing` as strings.

## Abs5 Fix

Abs5 changes report helpers so endpoint names are resolved back to pin/cell objects before calling `report_timing`. This avoids interpreting generated hierarchy brackets as glob syntax and reduces misleading `TIM-234` noise.

Abs5 also adds first-class reports:

- `pd_vernier_endpoint_discovery.rpt`
- `pd_vernier_source_discovery.rpt`
- `pd_vernier_exception_check.rpt`
- `timing_pd_intentional_vernier.rpt`

These reports are independent of whether the intended Vernier paths remain in `timing_violations.rpt` after the exception is applied.

## Required Abs5 Interpretation

`sdc_command_failures.md` should no longer be read as a raw grep count of all report errors. The summary now counts unresolved safety-relevant SDC failures more narrowly:

- fatal O13 SDC messages
- failed nonzero SDC command summaries
- explicit `MPTDC_SDC_*ERROR`
- safety-relevant SDC command failures

Unsupported optional report commands may still be listed for traceability, but they should not be confused with failed clock groups, false paths, max delays, or generated clocks.

## Remaining Review Rules

After the abs5 run:

- If endpoint discovery is not `PASS_64_ENDPOINTS`, do not run Innovus.
- If source discovery is not `PASS_8_SLOW_SOURCES`, do not run Innovus.
- If `PD_VERNIER_EXCEPTION_APPLIED` is not `YES`, do not run Innovus.
- If `UNKNOWN_REVIEW_REQUIRED` is nonzero, do not run Innovus.
- If real local fast-domain timing remains around -300 ps, analyze PD sampler timing before Innovus.
