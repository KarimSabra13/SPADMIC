# MPTDC Density65 Clean Candidate Review

Status: `PHYSICAL_CANDIDATE_YES`, `TIMING_CLEAN_NO`, `CTS_CLEAN_NO`,
`RESET_RECOVERY_REVIEW_REQUIRED`, `NOT_MMMC_SIGNOFF`,
`NOT_FINAL_SILICON_SIGNOFF`

## Scope

This note reviews the current density65 physical candidate and defines the
evidence expected from the next log-clean rerun at the same physical point.

The current best observed candidate is:

```text
mptdc_final_typical_pnr_density65_clean_20260612_171922
```

The next package of record should be a rerun from `65acb8e5` or later using the
same density65 intent. That rerun is expected to reduce report/log noise only;
it must not change RTL, route intent, density policy, constraints, Liberty load
math, or O13 physical interpretation.

## Attempt History

| Run | HEAD | Density | Postroute opt | O13 | Congestion | Antenna | Timing | Use |
|---|---|---:|---|---|---|---|---|---|
| `mptdc_final_typical_pnr_density62_20260612_162323` | `d4f91735` | 0.62 | off/normal | auto audit failed or was interrupted | clean | 3 violations | core about `-0.923 ns`, clk_sys/IO about `-2.378 ns` | superseded |
| `mptdc_final_typical_pnr_density65_20260612_165445` | `d4f91735` | 0.65 | requested, failed | complete | clean | 0 violations | core about `-0.893 ns`, clk_sys/IO about `-1.618 ns` | useful physical evidence, not clean package |
| `mptdc_final_typical_pnr_density65_clean_20260612_171922` | `abc574a5` | 0.65 | skipped cleanly | complete | clean | 0 violations | core/reset about `-0.903 ns`, clk_sys/IO about `-0.488 ns` | current best physical candidate |
| `mptdc_final_typical_pnr_density65_logclean_*` | `65acb8e5` or later | 0.65 | must stay off | expected complete | expected clean | expected clean | expected similar | next evidence package |

Important unit note: the timing summary column is `WNS ns`. A value such as
`-0.903` means `-0.903 ns`, which is `-903 ps`; it is not `-0.903 ps`.

## Current Best Evidence

The density65 clean candidate has the correct physical shape for the next
closure step:

- Route completed and produced routed DEF, checkpoint, and restore script.
- `REPORT_COMPLETE=YES`.
- O13 report audit completed with required phase reports present.
- Congestion report shows zero overflow and normalized hotspot area `0.00`.
- Antenna report shows `Verification Complete: 0 Violations`.
- Postroute opt was skipped, not failed.
- O13 raw RO source load is fixed and safe: 16 raw rows, 16 matched rows, 16
  fanout-1 rows, no missing raw RO rows.
- O13 topology is matched: `BUHDX4 -> BUHDX12`, 16 of 16 rows.

This is enough to stop density exploration. Density70 is not justified because
the active blocker is not routability or congestion. Density65 already fixes the
density62 antenna issue while keeping congestion clean.

## Current Non-Clean Items

The candidate is not timing closed:

- `CORE_INTERNAL` WNS is about `-0.903 ns`.
- `ASYNC_RESET_RECOVERY` WNS is also about `-0.903 ns`.
- `CLK_SYS_INTERNAL` and IO WNS are about `-0.488 ns`.
- CTS status remains `CTS_SKIPPED_CLEANLY_FOR_FEASIBILITY`.
- The clk_sys CTS spec was accepted as a generic spec file, but the flow could
  not prove it was clk_sys-only, so `ccopt_design` was not run.

The O13 final driver output load is high but must be interpreted correctly:

- Raw RO load is the analog-sensitive source load and is safe.
- The observed large value, up to about `753 fF`, is on the `BUHDX12` final
  driver output into the phase fabric.
- That load is not by itself a raw RO load failure. It remains a phase-quality
  and DRV/transition review item.

## Log-Clean Rerun Intake

For the `65acb8e5` rerun, collect and paste or archive:

- top-level `SUMMARY.md` and route `reports/SUMMARY.md`;
- `manifests/stage_trace.csv`;
- `reports/timing_by_class.md`;
- `reports/timing_true_setup_core.rpt`;
- `reports/timing_true_setup_clk_sys.rpt`;
- `reports/timing_true_setup_ro_domain.rpt`;
- `reports/timing_recovery_removal.rpt`;
- `reports/timing_fast_tag_to_pd_post_route.rpt`;
- `reports/cts_status.rpt`;
- `reports/cts_clock_inventory.rpt` or `cts_clock_inclusion_audit.rpt` if run;
- `reports/congestion.rpt`;
- `reports/antenna.rpt`;
- `reports/route_summary.rpt`;
- O13 `phase_buffer_balance_summary.md`;
- O13 `phase_buffer_topology_summary.md`;
- log grep for `ERROR:`, `IMPOPT-6080`, `IMPTCM-48`, `IMPDBTCL-`, and
  `TCLCMD-917`.

The expected result is materially the same physical evidence with fewer Tcl
probe/report errors. If timing moves materially, treat it as a real rerun
difference and inspect paths before accepting the comparison.

## Classification

| Decision | Status | Reason |
|---|---|---|
| Physical clean candidate | YES | route complete, congestion clean, antenna clean, O13 topology/raw load clean |
| Density/congestion/antenna candidate | YES | density65 fixed antenna without creating congestion |
| Timing clean | NO | negative WNS remains in core/reset and clk_sys/IO classes |
| CTS clean | NO | CTS skipped; clk_sys-only CTS not proven safe |
| Reset/recovery clean | REVIEW_REQUIRED | recovery/removal must be separated from true setup and protocol-reviewed |
| Signoff-ready | NO | CTS/timing/reset are unresolved; typical-only package is not MMMC or final silicon signoff |
