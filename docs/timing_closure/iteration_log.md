# MPTDC Timing-Closure Iteration Log

## Iteration ID: 20260527_repo_inventory

Git HEAD: `59c1fefda1e0bba857c01f37c0d99127c9761424`

Branch: `SPADMIC_TOP`

Patch summary: Repository inventory and timing-closure workspace setup.

Files changed:

- `local_file_inventory.txt`
- `docs/timing_closure/00_repo_inventory.md`
- `docs/timing_closure/iteration_log.md`

Tool stage:

- local inventory

Was this actually run by agent locally?

- yes

Was this run by human on lab server?

- no

Evidence location:

- `local_file_inventory.txt`
- `docs/timing_closure/00_repo_inventory.md`

Local Verilator:

- lint pass/fail: not run in this iteration
- smoke pass/fail: not run in this iteration
- important warnings: none yet
- tests run: none yet

Genus:

- run available? no fresh current-HEAD run
- WNS: unknown
- TNS: unknown
- violating paths: unknown
- worst path group: unknown
- worst startpoint: unknown
- worst endpoint: unknown
- design-rule violations: unknown
- latch audit: unknown on current HEAD
- CDC manual audit: unknown on current HEAD

Innovus:

- run available? no fresh current-HEAD run
- preCTS WNS/TNS/path count: unknown
- postCTS WNS/TNS/path count: unknown
- postRoute WNS/TNS/path count: unknown
- hold WNS/TNS/path count: unknown
- max transition violations: unknown
- max cap violations: unknown
- max fanout violations: unknown
- top physical concern: unknown

Xcelium:

- run available? no current-HEAD server run
- tests: none requested yet
- pass/fail: unknown
- failed seeds: unknown

Functional result:

- unknown

Timing result:

- unknown

Linearity/precision risk:

- none

Decision:

- continue

Next action:

- Add local Verilator lint/smoke wrapper under `MPTDC/sim/verilator/`.
- Run local Verilator baseline and save results under `results/local_verilator/<RUN_ID>/`.
- Prepare a Genus server baseline request for current HEAD.

## Iteration ID: 20260527_0845_baseline_local

Git HEAD: `59c1fefda1e0bba857c01f37c0d99127c9761424`

Branch: `SPADMIC_TOP`

Patch summary: Added local timing-closure Verilator infrastructure and focused unit tests for measurement sequencing, held-bus bridge sampling, context storage, and drain ordering.

Files changed:

- `MPTDC/sim/verilator/README.md`
- `MPTDC/sim/verilator/filelist_verilator.f`
- `MPTDC/sim/verilator/run_lint.sh`
- `MPTDC/sim/verilator/run_smoke.sh`
- `MPTDC/tb/unit/tb_meas_ctrl_unit.sv`
- `MPTDC/tb/unit/tb_hit_capture_bridge_unit.sv`
- `MPTDC/tb/unit/tb_drain_ctrl_unit.sv`
- `docs/timing_closure/SERVER_RUN_REQUEST.md`
- `MPTDC/syn/scripts/server_run_genus_mptdc.sh`

Tool stage:

- local Verilator

Was this actually run by agent locally?

- yes

Was this run by human on lab server?

- no

Evidence location:

- `results/local_verilator/20260527_0845_baseline_local/SUMMARY.md`
- `results/local_verilator/20260527_0845_baseline_local/test_summary.txt`
- `results/local_verilator/20260527_0845_baseline_local/lint.log`

Local Verilator:

- lint pass/fail: pass
- smoke pass/fail: pass
- important warnings: lint passed with documented Verilator waivers in `MPTDC/sim/verilator/README.md`
- tests run:
  - `lint`
  - `tb_meas_ctrl_unit`
  - `tb_hit_capture_bridge_unit`
  - `tb_context_bank_unit`
  - `tb_drain_ctrl_unit`
  - `tb_single_conv`
  - `tb_backpressure`
  - VIP `smoke_single_conv`
  - VIP `backpressure_integrity`
  - VIP `vip_maxhits_matrix`

Genus:

- run available? no fresh current-HEAD run
- WNS: unknown
- TNS: unknown
- violating paths: unknown
- worst path group: unknown
- worst startpoint: unknown
- worst endpoint: unknown
- design-rule violations: unknown
- latch audit: unknown on current HEAD
- CDC manual audit: unknown on current HEAD

Innovus:

- run available? no fresh current-HEAD run
- preCTS WNS/TNS/path count: unknown
- postCTS WNS/TNS/path count: unknown
- postRoute WNS/TNS/path count: unknown
- hold WNS/TNS/path count: unknown
- max transition violations: unknown
- max cap violations: unknown
- max fanout violations: unknown
- top physical concern: unknown

Xcelium:

- run available? no current-HEAD server run
- tests: none requested for this no-RTL-change infrastructure step
- pass/fail: unknown
- failed seeds: unknown

Functional result:

- pass for local Verilator scope

Timing result:

- unknown

Linearity/precision risk:

- none

Decision:

- request server run

Next action:

- Human runs `docs/timing_closure/SERVER_RUN_REQUEST.md` Genus command on the lab server.
- After committed server results are available, parse Genus timing/DRV/latch/CDC reports before proposing RTL timing changes.

## Iteration ID: 20260527_0845_current_head_genus_baseline

Git HEAD: `68652ddbf7936e283882e7249c8f0e458fd080fb`

Branch: `SPADMIC_TOP`

Patch summary: Human lab-server Genus baseline on the infrastructure commit.

Files changed:

- `results/genus/20260527_0845_current_head_genus_baseline/`
- `MPTDC/lab_snapshots/genus_20260527_0845_current_head_genus_baseline/`

Tool stage:

- Genus

Was this actually run by agent locally?

- no

Was this run by human on lab server?

- yes

Evidence location:

- `results/genus/20260527_0845_current_head_genus_baseline/SUMMARY.md`
- `results/genus/20260527_0845_current_head_genus_baseline/timing_summary.rpt`
- `results/genus/20260527_0845_current_head_genus_baseline/timing_violations.rpt`
- `results/genus/20260527_0845_current_head_genus_baseline/report_design_rules.rpt`
- `results/genus/20260527_0845_current_head_genus_baseline/latch_audit.rpt`
- `results/genus/20260527_0845_current_head_genus_baseline/cdc_manual_audit.rpt`

Local Verilator:

- lint pass/fail: not run in this server-results iteration
- smoke pass/fail: not run in this server-results iteration
- important warnings: none new
- tests run: none

Genus:

- run available? yes
- WNS: `-3063.5 ps`
- TNS: `-1609481.8 ps`
- violating paths: `699`
- worst path group: `clk_osc_fast_tap1`
- worst startpoint: `u_core_u_fast_cnt_bin_q_reg[2]/C`
- worst endpoint: `u_core_gen_pd_row[5].gen_pd_col[1].u_pd/nfast_hit_latched_reg[2]/D`
- design-rule violations: max_transition total `282226`
- latch audit: `7` latches found; expected count in defines was stale at `6`
- CDC manual audit: PD matrix count matched 64 cells; rejected START latch and held-bus bridge listed

Innovus:

- run available? no
- preCTS WNS/TNS/path count: unknown
- postCTS WNS/TNS/path count: unknown
- postRoute WNS/TNS/path count: unknown
- hold WNS/TNS/path count: unknown
- max transition violations: unknown
- max cap violations: unknown
- max fanout violations: unknown
- top physical concern: unknown

Xcelium:

- run available? no
- tests: none
- pass/fail: unknown
- failed seeds: none

Functional result:

- unknown for Cadence simulation; local Verilator baseline from prior iteration still pass

Timing result:

- failing; worst detailed paths are oscillator/PD measurement fabric, not clk_sys backend

Linearity/precision risk:

- none from analysis only

Decision:

- inspect more

Next action:

- Do not implement H1 yet.
- Fix detailed report generation for clk_sys, meas_ctrl, context_bank, drain/FIFO, high-fanout, and DRV net attribution.

## Iteration ID: 20260527_0945_report_infra_analysis

Git HEAD: `5dca9c0dd5cd5b272f6055115eeea7ef885f3622`

Branch: `SPADMIC_TOP`

Patch summary: Local parser/reporting improvements and baseline analysis documents; no RTL timing behavior change.

Files changed:

- `tools/timing/parse_genus_summary.py`
- `tools/timing/extract_top_paths.py`
- `tools/timing/compare_runs.py`
- `tools/timing/parse_innovus_summary.py`
- `MPTDC/syn/scripts/procedures.tcl`
- `MPTDC/syn/scripts/collect_snapshot.sh`
- `MPTDC/syn/scripts/server_run_genus_mptdc.sh`
- `MPTDC/syn/inputs/mptdc.defines`
- `docs/timing_closure/20260527_genus_baseline_analysis.md`
- `docs/timing_closure/H1_hit_count_analysis.md`
- `docs/timing_closure/H6_constraint_audit.md`
- `docs/timing_closure/sdc_audit.md`
- `docs/timing_closure/cdc_async_waiver_package.md`
- `docs/timing_closure/oscillator_macro_contract.md`
- `docs/timing_closure/SERVER_RUN_REQUEST.md`
- `docs/timing_closure/iteration_log.md`

Tool stage:

- local parser/script validation

Was this actually run by agent locally?

- yes

Was this run by human on lab server?

- no

Evidence location:

- `docs/timing_closure/20260527_genus_baseline_analysis.md`
- local parser output from `python3 tools/timing/parse_genus_summary.py results/genus/20260527_0845_current_head_genus_baseline`

Local Verilator:

- lint pass/fail: not required; no RTL changed
- smoke pass/fail: not required; no RTL changed
- important warnings: none new
- tests run: parser syntax/execution only

Genus:

- run available? prior baseline yes; targeted rerun not yet
- WNS: prior baseline `-3063.5 ps`
- TNS: prior baseline `-1609481.8 ps`
- violating paths: prior baseline `699`
- worst path group: prior baseline `clk_osc_fast_tap1`
- worst startpoint: prior baseline `u_core_u_fast_cnt_bin_q_reg[2]/C`
- worst endpoint: prior baseline `u_core_gen_pd_row[5].gen_pd_col[1].u_pd/nfast_hit_latched_reg[2]/D`
- design-rule violations: prior baseline max_transition total `282226`
- latch audit: expected count updated to `7`, matching observed intentional async frontend latches
- CDC manual audit: no protocol change

Innovus:

- run available? no
- preCTS WNS/TNS/path count: unknown
- postCTS WNS/TNS/path count: unknown
- postRoute WNS/TNS/path count: unknown
- hold WNS/TNS/path count: unknown
- max transition violations: unknown
- max cap violations: unknown
- max fanout violations: unknown
- top physical concern: unknown

Xcelium:

- run available? no
- tests: none
- pass/fail: unknown
- failed seeds: none

Functional result:

- unchanged; no RTL behavior change

Timing result:

- unknown for this patch until targeted Genus rerun is committed

Linearity/precision risk:

- none

Decision:

- request server run

Next action:

- Human runs `docs/timing_closure/SERVER_RUN_REQUEST.md` targeted Genus command after this patch is pushed.
- Parse `timing_clk_sys_violations.rpt`, fixed hotspot reports, `report_high_fanout.rpt`, and `report_design_rules_verbose.rpt`.

## Iteration ID: 20260527_0945_targeted_genus_reports

Git HEAD: `7cc0958f4f0492b9a741f6bc897c4e8b482d5181`

Branch: `SPADMIC_TOP`

Patch summary: Human lab-server Genus targeted-report rerun after report infrastructure.

Files changed:

- `MPTDC/lab_snapshots/genus_20260527_0945_targeted_genus_reports/`

Tool stage:

- Genus

Was this actually run by agent locally?

- no

Was this run by human on lab server?

- yes

Evidence location:

- `MPTDC/lab_snapshots/genus_20260527_0945_targeted_genus_reports/timing_summary.rpt`
- `MPTDC/lab_snapshots/genus_20260527_0945_targeted_genus_reports/timing_clk_sys_violations.rpt`
- `MPTDC/lab_snapshots/genus_20260527_0945_targeted_genus_reports/timing_context_bank_hotspots.rpt`
- `MPTDC/lab_snapshots/genus_20260527_0945_targeted_genus_reports/timing_drain_ctrl_hotspots.rpt`
- `MPTDC/lab_snapshots/genus_20260527_0945_targeted_genus_reports/report_high_fanout.rpt`
- `docs/timing_closure/20260527_targeted_genus_analysis.md`

Local Verilator:

- lint pass/fail: not run in this server-results iteration
- smoke pass/fail: not run in this server-results iteration
- important warnings: none new
- tests run: none

Genus:

- run available? yes
- WNS: `-3063.5 ps`
- TNS: `-1609481.8 ps`
- violating paths: `699`
- worst path group: `clk_osc_fast_tap1`
- worst startpoint: `u_core_u_fast_cnt_bin_q_reg[2]/C`
- worst endpoint: `u_core_gen_pd_row[5].gen_pd_col[1].u_pd/nfast_hit_latched_reg[2]/D`
- design-rule violations: max_transition total `282226`
- latch audit: `7` expected intentional async frontend/event latches
- CDC manual audit: no protocol change; PD matrix count remains 64

Innovus:

- run available? no
- preCTS WNS/TNS/path count: unknown
- postCTS WNS/TNS/path count: unknown
- postRoute WNS/TNS/path count: unknown
- hold WNS/TNS/path count: unknown
- max transition violations: unknown
- max cap violations: unknown
- max fanout violations: unknown
- top physical concern: unknown

Xcelium:

- run available? no
- tests: none
- pass/fail: unknown
- failed seeds: none

Functional result:

- unknown for Cadence simulation; analysis only

Timing result:

- failing; clk_sys details now identify drain record construction and
  row-count/context publication as actionable backend cones

Linearity/precision risk:

- none from analysis only

Decision:

- continue

Next action:

- Implement a focused clk_sys backend patch: remove drain read pre-point mux and
  register hit-count/flags before context publication.
- Run local Verilator lint/smoke.
- Request Genus and Xcelium server validation.

## Iteration ID: 20260527_1030_h1_drain_pipeline

Git HEAD: `62e894bb0f0e39390945bb7a18168ac6ae9a12cb` before local patch commit

Branch: `SPADMIC_TOP`

Patch summary: Focused clk_sys backend timing patch for H1/H2 and H4.

Files changed:

- `MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv`
- `MPTDC/rtl/ctrl/mptdc_drain_ctrl.sv`
- `MPTDC/rtl/pkg/mptdc_pkg.sv`
- `MPTDC/rtl/top/mptdc_core.sv`
- `MPTDC/tb/unit/tb_meas_ctrl_unit.sv`
- `MPTDC/sim/xcelium/server_run_xcelium_mptdc.sh`
- `docs/timing_closure/20260527_targeted_genus_analysis.md`
- `docs/timing_closure/H1_hit_count_analysis.md`
- `docs/timing_closure/H4_drain_record_timing_analysis.md`
- `docs/timing_closure/SERVER_RUN_REQUEST.md`
- `docs/timing_closure/iteration_log.md`
- `results/local_verilator/20260527_1030_h1_drain_pipeline/`

Tool stage:

- local Verilator

Was this actually run by agent locally?

- yes

Was this run by human on lab server?

- no

Evidence location:

- `results/local_verilator/20260527_1030_h1_drain_pipeline/SUMMARY.md`
- `results/local_verilator/20260527_1030_h1_drain_pipeline/test_summary.txt`
- `results/local_verilator/20260527_1030_h1_drain_pipeline/lint.log`

Local Verilator:

- lint pass/fail: pass
- smoke pass/fail: pass
- important warnings: none beyond documented local Verilator waivers
- tests run:
  - `lint`
  - `tb_meas_ctrl_unit`
  - `tb_hit_capture_bridge_unit`
  - `tb_context_bank_unit`
  - `tb_drain_ctrl_unit`
  - `tb_single_conv`
  - `tb_backpressure`
  - VIP `smoke_single_conv`
  - VIP `backpressure_integrity`
  - VIP `vip_maxhits_matrix`

Genus:

- run available? no for this patch
- WNS: unknown for this patch
- TNS: unknown for this patch
- violating paths: unknown for this patch
- worst path group: unknown for this patch
- worst startpoint: unknown for this patch
- worst endpoint: unknown for this patch
- design-rule violations: unknown for this patch
- latch audit: server rerun required
- CDC manual audit: server rerun required

Innovus:

- run available? no
- preCTS WNS/TNS/path count: unknown
- postCTS WNS/TNS/path count: unknown
- postRoute WNS/TNS/path count: unknown
- hold WNS/TNS/path count: unknown
- max transition violations: unknown
- max cap violations: unknown
- max fanout violations: unknown
- top physical concern: unknown

Xcelium:

- run available? no for this patch
- tests: server request prepared
- pass/fail: unknown
- failed seeds: unknown

Functional result:

- pass for local Verilator scope

Timing result:

- unknown until patched Genus run is committed

Linearity/precision risk:

- low to medium

Decision:

- request server run

Next action:

- Human runs `docs/timing_closure/SERVER_RUN_REQUEST.md` on the lab server.
- Compare patched Genus against `20260527_0945_targeted_genus_reports` and
  check whether `pending_wr_data_q` and `ctx_snapshot_q` leave the worst clk_sys
  endpoint set.
- Review Xcelium regression before treating the added CAPTURE cycle as stable.

## Iteration ID: 20260527_1030_h1_drain_pipeline_server

Git HEAD: `65fbfb0f0a39554836a5cd8b4528011b867f09ce`

Branch: `SPADMIC_TOP`

Patch summary: Human lab-server Genus and Xcelium run for the H1/H4 clk_sys
backend patch.

Files changed:

- `results/genus/20260527_1030_h1_drain_pipeline_genus/`
- `MPTDC/lab_snapshots/genus_20260527_1030_h1_drain_pipeline_genus/`
- `results/xcelium/20260527_1030_h1_drain_pipeline_xcelium/`
- `docs/timing_closure/20260527_h1_drain_server_analysis.md`

Tool stage:

- Genus
- Xcelium

Was this actually run by agent locally?

- no

Was this run by human on lab server?

- yes

Evidence location:

- `results/genus/20260527_1030_h1_drain_pipeline_genus/PARSED_SUMMARY.md`
- `results/genus/20260527_1030_h1_drain_pipeline_genus/timing_clk_sys_violations.rpt`
- `results/genus/20260527_1030_h1_drain_pipeline_genus/timing_context_bank_hotspots.rpt`
- `results/genus/20260527_1030_h1_drain_pipeline_genus/timing_drain_ctrl_hotspots.rpt`
- `results/xcelium/20260527_1030_h1_drain_pipeline_xcelium/SUMMARY.md`
- `results/xcelium/20260527_1030_h1_drain_pipeline_xcelium/test_summary.txt`

Local Verilator:

- lint pass/fail: prior local run pass
- smoke pass/fail: prior local run pass
- important warnings: none new
- tests run: none in this server-results iteration

Genus:

- run available? yes
- WNS: `-3045.0 ps`
- TNS: `-1571801.3 ps`
- violating paths: `692`
- worst path group: `clk_osc_fast_tap1`
- worst startpoint: `u_core_u_fast_cnt_bin_q_reg[2]/C`
- worst endpoint: `u_core_gen_pd_row[5].gen_pd_col[1].u_pd/nfast_hit_latched_reg[2]/D`
- design-rule violations: max_transition total `213804`
- latch audit: `7` expected intentional async frontend/event latches
- CDC manual audit: no protocol change; PD matrix count remains 64

Innovus:

- run available? no
- preCTS WNS/TNS/path count: unknown
- postCTS WNS/TNS/path count: unknown
- postRoute WNS/TNS/path count: unknown
- hold WNS/TNS/path count: unknown
- max transition violations: unknown
- max cap violations: unknown
- max fanout violations: unknown
- top physical concern: unknown

Xcelium:

- run available? partial
- tests:
  - directed: `tb_meas_ctrl_unit`, `tb_hit_capture_bridge_unit`,
    `tb_context_bank_unit`, `tb_drain_ctrl_unit`, `tb_single_conv`,
    `tb_backpressure`
  - VIP selected regression attempted
- pass/fail:
  - directed pass
  - VIP did not execute RTL; all jobs failed at runner startup due wrapper output
    path rejected by `MPTDC/scripts/sim/run_vip_test.sh`
- failed seeds: VIP seeds `7000` through `7003` for all selected tests, all same
  infrastructure failure

Functional result:

- directed Xcelium pass; VIP unknown due wrapper bug

Timing result:

- improved for the targeted `clk_sys` group:
  - WNS improved from `-1486.0 ps` to `-968.1 ps`
  - TNS improved from `-91719.4 ps` to `-48974.7 ps`
  - violating paths improved from `79` to `72`
  - max-transition violations improved from `282226` to `213804`

Linearity/precision risk:

- low to medium until VIP rerun completes

Decision:

- continue, but do not stack a new RTL patch until VIP Xcelium rerun is valid

Next action:

- Fix `MPTDC/sim/xcelium/server_run_xcelium_mptdc.sh` so VIP artifacts are
  generated under `MPTDC/results/...`, then copied into top-level `results/...`.
- Request Xcelium rerun only.
- If VIP rerun passes, implement H1b to split final count registration from
  hit-count/flag publication.
