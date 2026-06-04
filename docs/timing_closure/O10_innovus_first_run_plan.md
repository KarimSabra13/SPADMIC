# O10 Innovus First Run Plan

## Objective

Run a first Innovus typical feasibility pass on the O9 R750_delta5 netlist to understand physical placement, congestion, route feasibility, phase-net balance, DRV, and manager-visible layout screenshots.

This is not final timing signoff, not MMMC signoff, and not tapeout readiness.

## Flow

1. Verify checkout, branch, expected HEAD, and clean-enough status.
2. Verify O9 netlist, post-synth SDC, O9 overlay SDC, typical Liberty, standard-cell LEF, tech LEF, RO_tune4 real LEF, and RO_tune4 Liberty shell.
3. Initialize Innovus in typical-only mode.
4. Create fresh sandwich floorplan:
   - slow RO north,
   - PD matrix center,
   - fast RO south,
   - backend digital island right.
5. Place or strongly guide RO macros and PD matrix.
6. Run placement and post-place optimization.
7. Run CTS for `clk_sys` only.
8. Route feasibility.
9. Generate timing, hold, DRV, congestion, clock, power, phase-net, fast-tag-load, and PD symmetry reports.
10. Generate screenshots and DEF/checkpoint snapshots after each major stage.
11. Generate manager summary.

## Expected Output Directory

`results/innovus/20260604_o10_typical_feasibility/`

Subdirectories:

- `logs/`
- `reports/`
- `screenshots/`
- `checkpoints/`
- `def/`
- `manager/`
- `manifests/`

## Screenshot Targets

- `screenshots/01_floorplan_overview.png`
- `screenshots/02_macros_pd_matrix.png`
- `screenshots/03_placed_design.png`
- `screenshots/04_clk_sys_cts.png`
- `screenshots/05_routed_design.png`
- `screenshots/06_congestion.png`
- `screenshots/07_phase_nets_highlight.png`
- `screenshots/08_final_manager_view.png`

If automatic screenshots fail, write `screenshots/SCREENSHOT_EXPORT_FAILED.txt` and save restore instructions.

## Required Reports

- `reports/timing_pre_place.rpt`
- `reports/timing_post_place.rpt`
- `reports/timing_post_cts.rpt`
- `reports/timing_post_route.rpt`
- `reports/hold_post_cts.rpt`
- `reports/hold_post_route.rpt`
- `reports/drv_max_transition.rpt`
- `reports/drv_max_cap.rpt`
- `reports/drv_max_fanout.rpt`
- `reports/congestion.rpt`
- `reports/route_summary.rpt`
- `reports/clock_tree_summary.rpt`
- `reports/power_summary.rpt`
- `reports/phase_net_loads.csv`
- `reports/phase_net_balance_summary.md`
- `reports/pd_instance_placement.csv`
- `reports/pd_symmetry_summary.md`
- `reports/fast_tag_loads.csv`
- `reports/high_fanout_summary.rpt`
- `reports/residual_path_tracking.csv`

## Pass Criteria For First Feasibility

- Innovus completes through route, or preserves useful partial outputs on failure.
- RO_tune4 macros are loaded and discoverable.
- PD cell count remains 64.
- `clk_sys` CTS completes or reports a specific tool/cell-library blocker.
- RO phase nets are not converted into CTS trees.
- The seven residual Genus paths are tracked.
- Screenshots or restore instructions are produced.

## Non-Goals

- Do not run MMMC.
- Do not run final extraction/signoff.
- Do not claim characterization pass from O9 manifests alone.
- Do not change RTL or packet format.
- Do not insert arbitrary buffers/dummy loads on RO phase nets.
