# O10.1 Expected Outputs

Expected run root:

- `results/innovus/<RUN_ID>/`

Expected snapshot:

- `MPTDC/lab_snapshots/innovus_o10_1_innovus_repair_<RUN_ID>/`

## Required Output Groups

Reports:

- `reports/SUMMARY.md`
- `reports/timing_pre_place.rpt`
- `reports/timing_post_place.rpt`
- `reports/timing_post_cts.rpt`
- `reports/timing_post_route.rpt`
- `reports/timing_post_route_core_only.rpt`
- `reports/timing_post_route_io_paths.rpt`
- `reports/drv_max_transition.rpt`
- `reports/drv_max_cap.rpt`
- `reports/drv_max_fanout.rpt`
- `reports/route_summary.rpt`
- `reports/congestion.rpt`
- `reports/phase_net_loads.csv`
- `reports/fast_tag_loads.csv`
- `reports/pd_instance_placement.csv`
- `reports/pd_symmetry_summary.md`
- `reports/cts_status.rpt`
- `reports/cts_ro_clock_guard.rpt`
- `reports/checkpoint_status.rpt`

Manager:

- `manager/MANAGER_SUMMARY.md`
- `manager/GUI_SCREENSHOT_INSTRUCTIONS.md` if automatic screenshots fail.

Snapshots:

- `def/01_floorplan.def`
- `def/02_place.def`
- `def/03_cts.def`
- `def/04_route.def`
- `checkpoints/restore_latest.tcl`
- `checkpoints/restore_place.tcl`
- `checkpoints/restore_route.tcl`

Screenshot condition:

- one or more nonempty PNG files, or
- `screenshots/SCREENSHOT_EXPORT_FAILED.txt`.

## Failure Policy

Missing required outputs cause:

- `REQUIRED_OUTPUTS_CHECK_FAILED.txt`
- nonzero wrapper exit code
- missing-output list in the top-level `SUMMARY.md`.
