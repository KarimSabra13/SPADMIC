# O10.2 Expected Outputs

## Required For Report-Complete Route Feasibility

- `reports/SUMMARY.md`
- `manager/MANAGER_SUMMARY.md`
- `manager/GUI_SCREENSHOT_INSTRUCTIONS.md`
- `reports/report_clocks.rpt`
- `reports/timing_post_route.rpt`
- `reports/timing_post_route_summary_by_class.md`
- `reports/timing_post_route_core_internal.rpt`
- `reports/timing_post_route_io_output.rpt`
- `reports/timing_post_route_reset_recovery.rpt`
- `reports/timing_post_route_ro_osc_domain.rpt`
- `reports/timing_post_route_clk_sys_internal.rpt`
- `reports/reset_recovery_summary.md`
- `reports/drv_max_transition.rpt`
- `reports/drv_max_cap.rpt`
- `reports/drv_max_fanout.rpt`
- `reports/phase_net_loads.csv`
- `reports/phase_net_balance_summary.md`
- `reports/fast_tag_loads.csv`
- `reports/fast_tag_load_balance_summary.md`
- `reports/pd_instance_placement.csv`
- `reports/pd_symmetry_summary.md`
- `reports/cts_status.rpt`
- `reports/congestion.rpt`
- `reports/route_summary.rpt`
- `checkpoints/restore_latest.tcl`
- `def/04_route.def`

## Screenshot Condition

Either nonempty PNG files exist, or both files exist:

- `screenshots/SCREENSHOT_EXPORT_FAILED.txt`
- `manager/GUI_SCREENSHOT_INSTRUCTIONS.md`

## Validation Rule

Files with `ERROR`, `FAILED`, or `REPORT_STATUS=INVALID` markers do not count as valid required outputs. The wrapper must exit nonzero if required outputs are missing or invalid.
