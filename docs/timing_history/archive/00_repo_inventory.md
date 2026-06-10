# MPTDC Timing-Closure Repository Inventory

Inventory date: 2026-05-27

## Git State

- Branch: `SPADMIC_TOP`
- HEAD: `59c1fefda1e0bba857c01f37c0d99127c9761424`
- Short HEAD: `59c1fef`
- Recent commits:
  - `59c1fef Add final MPTDC v2.7 boundary-fix report artifacts`
  - `fbd8ef2 Restore boundary bit in MPTDC v2.7 packet`
  - `a2e164f Fix MPTDC output protocol`
  - `be57bd0 Optimize MPTDC observable ablation`
  - `e82dca4 Update MPTDC report and LUT ablation`
  - `abc1a20 Add final MPTDC characterization report assets`
  - `1a2f966 Finalize MPTDC cleanup and report flow`
  - `09305ae Fix MPTDC boundary stress TB hierarchy`
  - `1f17485 Fix MPTDC slow counter startup snapshot`
  - `fbae683 Add MPTDC oracle analysis flow`

The required file inventory was generated at repository root:

- `local_file_inventory.txt`

The worktree already contained unrelated report and figure changes under
`Rapport_5PSM_KS/`. Those files are outside this timing-closure work package
and were not modified by this inventory pass.

## Key RTL Files

- `MPTDC/rtl/filelist.f`
- `MPTDC/rtl/pkg/mptdc_pkg.sv`
- `MPTDC/rtl/top/mptdc_top_asic.sv`
- `MPTDC/rtl/top/mptdc_core.sv`
- `MPTDC/rtl/async/mptdc_async_frontend_v2.sv`
- `MPTDC/rtl/async/mptdc_stop_capture_async.sv`
- `MPTDC/rtl/async/mptdc_hit_capture_bridge.sv`
- `MPTDC/rtl/async/mptdc_context_bank.sv`
- `MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv`
- `MPTDC/rtl/ctrl/mptdc_drain_ctrl.sv`
- `MPTDC/rtl/ctrl/mptdc_watchdog.sv`
- `MPTDC/rtl/ctrl/mptdc_input_mux.sv`
- `MPTDC/rtl/cdc/mptdc_reset_sync.sv`
- `MPTDC/rtl/cdc/mptdc_pulse_sync.sv`
- `MPTDC/rtl/cdc/mptdc_gray_cnt_sync.sv`
- `MPTDC/rtl/cdc/mptdc_sync_fifo.sv`
- `MPTDC/rtl/osc/mptdc_osc_model.sv`
- `MPTDC/rtl/osc/mptdc_osc_stub.sv`
- `MPTDC/rtl/osc/mptdc_osc_wrapper.sv`
- `MPTDC/rtl/pd/mptdc_pd_cell.sv`
- `MPTDC/rtl/readout/mptdc_tconv_reco.sv`
- `MPTDC/rtl/readout/mptdc_narrow16_tx_v2.sv`
- `MPTDC/rtl/readout/mptdc_csr_minimal.sv`

## Key Simulation Files

- `MPTDC/scripts/sim/run_tb.sh`
- `MPTDC/scripts/sim/run_vip_test.sh`
- `MPTDC/ci/run_smoke.sh`
- `MPTDC/ci/run_vip_smoke.sh`
- `MPTDC/ci/run_full_regression.sh`
- `MPTDC/ci/run_vip_xcelium_regression.sh`
- `MPTDC/tb/common/mptdc_tb_pkg.sv`
- `MPTDC/tb/common/mptdc_char_tb_pkg.sv`
- `MPTDC/tb/common/mptdc_raw_monitor.sv`
- `MPTDC/tb/unit/tb_context_bank_unit.sv`
- `MPTDC/tb/unit/tb_gray_cnt_sync_unit.sv`
- `MPTDC/tb/unit/tb_input_mux_unit.sv`
- `MPTDC/tb/unit/tb_narrow16_tx_v2_unit.sv`
- `MPTDC/tb/unit/tb_reset_sync_unit.sv`
- `MPTDC/tb/unit/tb_watchdog_unit.sv`
- `MPTDC/tb/int/tb_single_conv.sv`
- `MPTDC/tb/int/tb_backpressure.sv`
- `MPTDC/tb/int/tb_multi_conv_stress.sv`
- `MPTDC/tb/int/tb_overflow_count.sv`
- `MPTDC/tb/int/tb_watchdog_recovery.sv`
- `MPTDC/tb/tests/mptdc_vip_tb.sv`
- `MPTDC/tb/vip/filelist.f`
- `MPTDC/tb/vip/pkg/mptdc_vip_pkg.sv`

## Key Synthesis Files

- `MPTDC/syn/README.md`
- `MPTDC/syn/filelist_synth.f`
- `MPTDC/syn/inputs/mptdc.defines`
- `MPTDC/syn/inputs/mptdc.mmmc`
- `MPTDC/syn/inputs/mptdc.sdc`
- `MPTDC/syn/libraries/libraries.xh018.tcl`
- `MPTDC/syn/libraries/libraries.xh018-stdcells.tcl`
- `MPTDC/syn/macros/mptdc_osc_blackbox.lef`
- `MPTDC/syn/macros/mptdc_osc_blackbox.lib`
- `MPTDC/syn/scripts/genus.tcl`
- `MPTDC/syn/scripts/procedures.tcl`
- `MPTDC/syn/scripts/settings.tcl`
- `MPTDC/syn/scripts/collect_snapshot.sh`

## Key PnR Files

- `MPTDC/pnr/README.md`
- `MPTDC/pnr/inputs/mptdc_innovus.mmmc`
- `MPTDC/pnr/inputs/mptdc_pnr_config.tcl`
- `MPTDC/pnr/scripts/innovus_estimate.tcl`
- `MPTDC/pnr/scripts/collect_snapshot.sh`

## Known Result Directories

- `MPTDC/lab_snapshots/`
  - Genus snapshots from 2026-04-21 through 2026-05-19.
  - Innovus snapshots from 2026-05-12 through 2026-05-19.
- `MPTDC/results/`
  - Calibration, characterization, campaign, VIP, and fixed-delay results.
- `results/characterization/`
  - Top-level characterization result copies.
- `MPTDC/artifacts/overnight/`
  - Overnight VIP artifacts.
- `MPTDC/build/`
  - Existing Verilator build trees.

Old Genus/Innovus reports are treated only as hints. Current HEAD still needs a
fresh lab-server baseline before timing conclusions.

## Local Tool Availability

- Verilator: available
- Verilator path: `/usr/local/bin/verilator`
- Verilator version: `Verilator 5.040 2025-08-30 rev v5.040-50-g0a9d9db5a`
- Genus: missing locally
- Innovus: missing locally
- Xcelium/xrun: missing locally

## Local Dependency Notes

- Cadence tools are server-only for this workflow. Genus, Innovus, and Xcelium
  must be run by the human on the lab server and committed back as reports.
- The local Verilator flow is valid for syntax, lint, and directed digital
  smoke checks only. It is not timing signoff, CDC signoff, analog oscillator
  signoff, or Vernier linearity proof.
- The synthesis flow depends on the lab-server XFAB XH018 PDK defaults in
  `MPTDC/syn/README.md` and `MPTDC/syn/inputs/mptdc.defines`.

## Existing Flow Summary

- RTL compile list: `MPTDC/rtl/filelist.f`
- Genus compile list: `MPTDC/syn/filelist_synth.f`
- Local unit/integration runner: `MPTDC/scripts/sim/run_tb.sh`
- Local VIP runner: `MPTDC/scripts/sim/run_vip_test.sh`
- Existing fast local smoke: `MPTDC/ci/run_smoke.sh`
- Existing VIP Verilator smoke: `MPTDC/ci/run_vip_smoke.sh`
- Existing Xcelium regression manager: `MPTDC/ci/run_vip_xcelium_regression.sh`
- Existing Genus snapshot collector: `MPTDC/syn/scripts/collect_snapshot.sh`
- Existing Innovus estimate flow: `MPTDC/pnr/scripts/innovus_estimate.tcl`
- Existing Innovus snapshot collector: `MPTDC/pnr/scripts/collect_snapshot.sh`

