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
