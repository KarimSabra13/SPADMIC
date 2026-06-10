# O1 Review of O0 Oscillator/PD Results

Review date: 2026-05-28

Current branch: `SPADMIC_TOP`
Current checkout HEAD after pull: `523dcb9dfd1d1b7a085b76a9c6b6d95d2582831b`

O0 server result inputs:

- Genus: `results/genus_osc_pd/20260527_1500_o0_osc_pd_signoff_genus/`
- Innovus: `results/osc_pd/20260527_1500_o0_osc_pd_signoff_innovus/`
- Genus lab snapshot: `MPTDC/lab_snapshots/genus_osc_pd_20260527_1500_o0_osc_pd_signoff_genus/`
- Innovus lab snapshot: `MPTDC/lab_snapshots/innovus_osc_pd_20260527_1500_o0_osc_pd_signoff_innovus/`

## Executive Status

O0 is useful as a provisional report-collection baseline, but it is not oscillator/PD signoff.

Main reasons:

- The oscillator physical view was provisional, not the real `SPADMIC/RO_tune4/abstract`.
- The RTL/netlist still implements the oscillator as `mptdc_osc_stub` logic, not as a hard `RO_tune4` macro.
- Genus timing is dominated by real-looking fast-domain `fast counter -> nfast_hit` paths, but those paths are timed through the synthesis stub and provisional clock model.
- Innovus did not produce post-route setup or hold summaries in the collected result directory.
- Phase-route RC/load and tap-load reports are empty or missing, so PD physical matching is not yet reviewable.

Decision from O0: proceed to O1A real abstract binding before spending effort on R800 conclusions or claiming any oscillator/PD closure.

## O0 Genus Summary

Run:

- Run ID: `20260527_1500_o0_osc_pd_signoff_genus`
- Tool exit: 0
- Git HEAD run by server: `4ae98ad2c22e85b646270bc673fff7cd206d2dbd`
- Status in summary: `PROVISIONAL PHYSICAL/TIMING MODEL ONLY`

Timing groups from `PARSED_SUMMARY.md` / `timing_summary.rpt`:

| Group | WNS (ps) | TNS (ps) | Violating Paths |
|---|---:|---:|---:|
| `clk_osc_fast_tap1` | -3163.0 | -193058.8 | 72 |
| `clk_osc_fast_tap2` | -3118.6 | -190798.8 | 72 |
| `clk_osc_fast_tap3` | -3069.2 | -189401.3 | 72 |
| `clk_osc_fast_tap4` | -3018.6 | -185043.3 | 72 |
| `clk_osc_fast_tap5` | -2968.6 | -182545.8 | 72 |
| `clk_osc_fast_tap6` | -2913.0 | -179873.7 | 72 |
| `clk_osc_fast_tap7` | -2868.6 | -176765.7 | 72 |
| `clk_osc_slow` | -2711.6 | -50463.8 | 22 |
| `clk_osc_fast` | -2574.5 | -197983.8 | 94 |
| `clk_sys` | -720.4 | -37235.0 | 77 |

Total:

- Total TNS: `-1583170.0 ps`
- Total violating paths: `697`
- Genus max-transition DRV total: `256097`
- Latch audit: 7 expected async frontend latches
- Timing-intent items include 69 sequential data pins driven by clock signals and 21 sequential clock pins without a clock waveform. These are consistent with the unfinished oscillator/PD timing model and must be revisited after real macro binding.

## O0 Path Classification

Classifier summary:

- Parsed paths: 371
- `UNKNOWN_REVIEW_REQUIRED`: 0

| Class | Paths | Meaning |
|---|---:|---|
| `OSC_FAST_REAL` | 280 | Dominated by fast counter and `nfast_hit` capture paths. These are real timing candidates unless later proven to be invalid by a better macro/clock model. |
| `CLK_SYS_REAL` | 77 | Backend `clk_sys` paths still require normal closure at 6.25 ns. H4b is paused and has not been checked by server timing. |
| `OSC_SLOW_REAL` | 14 | Slow-domain paths exist and remain unresolved. |

Top Genus paths are `u_core_u_fast_cnt/bin_q_reg[*]` to `u_core_gen_pd_row[*].gen_pd_col[*].u_pd/nfast_hit_latched_reg[*]`, ending on `clk_osc_fast_tap1..7` groups. This directly confirms the O0/O1 need to audit fast-counter placement, routing, load, and generated-clock relation.

No top detailed O0 paths were classified as `PD_INTENTIONAL_VERN`. That does not mean Vernier sampling is signed off; it means the collected top reports were dominated by fast-counter and clk_sys paths. Intentional slow-to-fast PD sampling still needs waiver plus physical matching evidence.

## O0 Innovus Summary

Run:

- Run ID: `20260527_1500_o0_osc_pd_signoff_innovus`
- Tool exit: 0
- Git HEAD run by server: `4ae98ad2c22e85b646270bc673fff7cd206d2dbd`
- Status in summary: `PROVISIONAL PHYSICAL CLOSURE ONLY`

Collected timing:

- `timing_preCTS.rpt`: present. Worst shown setup slack is `-56.757 ns`, path group `clk_sys`, from `u_core_u_drain_ctrl_drain_ctx_q_reg[0]/Q` to `u_core_u_drain_ctrl_emit_wr_data_q_reg[hit][nfast][3]/D`.
- `timing_postCTS.rpt`: present but copied from the same preCTS `extra_report_timing_100.rpt` source according to the O0 wrapper, so it is not independent postCTS evidence.
- `timing_postRoute.rpt`: missing; file records that `/MPTDC/pnr/reports/postroute/mptdc_top_asic_postRoute.summary` was not produced.
- `top100_hold_paths.rpt`: missing; file records that `/MPTDC/pnr/reports/postroute/mptdc_top_asic_postRoute.hold.summary` was not produced.

The very large Innovus preCTS `clk_sys` slack appears unrelated to oscillator/PD macro binding. It is consistent with the still-paused H4b drain-record staging issue and should not be mixed with O1 oscillator conclusions.

Innovus DRV/report status:

- `drv_max_fanout.rpt`: one max-fanout load violation on `clk_sys`; report marks it as a clock-net violation, not a real data fanout issue.
- `drv_max_transition.rpt` and `drv_max_cap.rpt`: both were copied from `extra_report_constraint.rpt`, so they are not clean transition/cap-only evidence.
- Post-route route/hold evidence is unavailable.

## PD Symmetry and Phase RC Status

PD instance symmetry:

- `pd_instance_symmetry_summary.md`: `PASS`
- Rows parsed: 64
- Missing logical cells: 0
- Duplicate logical coordinates: 0
- Orientation: 64 `r0`

Caveat: the CSV has blank actual `x_um/y_um/width/height/master` fields and `master` is reported as `unknown`. The floorplan script used `setObjFPlanBox` reservations after `placeInstance` was skipped, so this proves logical coverage and intended grid coordinates, not final hard placement.

Phase/tap physical reports:

- `phase_net_rc.csv`: header only, 0 data rows.
- `phase_net_balance_summary.md`: `PROVISIONAL_REVIEW_REQUIRED`; no slow/fast tap rows parsed.
- `tap_loads.csv`: missing.
- `tap_load_balance_summary.md`: missing.
- `nfast_count_bus_rc.csv`: missing.
- `nfast_count_bus_summary.md`: missing.

This is the largest physical-signoff gap. O1 must improve real macro binding and report extraction before phase load, phase0 extra-load, tap RC mismatch, or `nfast_src_count` bus skew can be judged.

## Provisional Macro Binding Status

The O0 flow used provisional macro LEF/lib shells, but the actual RTL/netlist oscillator instances were still synthesis stubs:

- RTL wrapper: `mptdc_osc_wrapper`
- Synthesis child: `mptdc_osc_stub`
- Genus area report masters:
  - slow: `mptdc_osc_stub_NE8`
  - fast: `mptdc_osc_stub_NE8_1252`
- O0 floorplan summary found:
  - slow hierarchy: `u_core_u_osc_slow_u_stub`
  - fast hierarchy: `u_core_u_osc_fast_u_stub`
- O0 macro placement summary explicitly says hard macro binding is not active.

Therefore, real abstract binding is the correct next step. O1A must prove:

1. the OA abstract path exists and is readable on the lab server;
2. a LEF can be found or exported from it;
3. the LEF macro name and pins can be reconciled with the netlist master and pins;
4. Genus/Innovus actually load and bind the real physical macro view, rather than merely keeping it in the LEF search list.

## O1 Consequence

O1A should run before O1B. Frequency derating without real physical macro/pin evidence would mix two variables and would not explain whether the O0 problems are caused by placeholder geometry, wrong binding, physical routing, or actual fast-domain frequency pressure.

O1B R800 remains a what-if only until the analog designer confirms tune-code pairs and extracted tap delays that preserve the 5 ps Vernier tap delta.
