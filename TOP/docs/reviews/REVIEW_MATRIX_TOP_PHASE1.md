# Review: Matrix TOP Phase 1

Status: Phase 1 signed off by Verifier.

## Repository Snapshot

- Branch: `SPADMIC_test`
- Commit reviewed: `a9ec83afc2ca2923896af014e6bc8e4fae6c4296`
- Last commit: `a9ec83af position: add matrice3 final matrix extraction results`
- Working tree context:
  - user-owned untracked references remain: `ParameterDefs.sv`, `multi_ShiftRegisterChain_cfg_v1.sv`, `pixel_readout.pdf`
  - Phase 0/1 docs, RTL, tests, and filelist changes are uncommitted.

## Phase Reviewed

Phase 1 - standalone RTL modules and unit tests.

## Files Reviewed

RTL and filelist:

- `TOP/filelist.f`
- `TOP/rtl/spadmic_pkg.sv`
- `TOP/rtl/spadmic_matrix_or_tree.sv`
- `TOP/rtl/spadmic_matrix_snapshot_frontend.sv`
- `TOP/rtl/spadmic_matrix_reset_ctrl.sv`
- `TOP/rtl/spadmic_event_coordinator.sv`
- `TOP/rtl/spadmic_ddr16_tx_pairer.sv`
- `TOP/rtl/spadmic_matrix_cfg_ctrl.sv`

Tests:

- `TOP/tb/tb_spadmic_matrix_or_tree_unit.sv`
- `TOP/tb/tb_spadmic_matrix_snapshot_frontend_unit.sv`
- `TOP/tb/tb_spadmic_matrix_reset_ctrl_unit.sv`
- `TOP/tb/tb_spadmic_event_coordinator_modes_unit.sv`
- `TOP/tb/tb_spadmic_ddr16_tx_pairer_unit.sv`
- `TOP/tb/tb_spadmic_matrix_cfg_ctrl_unit.sv`

## Specification Points Checked

- No protected MPTDC internals were edited.
- `TOP/rtl/spadmic_top_v1.sv` was not modified.
- Operating modes use explicit enum values.
- Event coordinator uses mode-dependent masks and no fixed all-source AND.
- TDC-only excludes position packet dependencies.
- Position-only excludes MPTDC dependencies.
- Calibration ignores matrix activity.
- Required masks and grant are frozen after event open.
- Matrix reset controller drives inactive-high physical outputs under reset and implements exact width semantics.
- Snapshot frontend uses synchronized control/reset path and does not affect MPTDC START timing.
- DDR16 pairer uses single-edge RTL and no dual-edge final TX behavior.
- Matrix configuration controller uses `clk_sys` and separate `clk_cfg_40m` with stable-bus/toggle CDC.
- Filelist additions are additive and do not remove the old TOP path.

## Tests Run

All with Verilator 5.040 through `TOP/scripts/sim/run_tb.sh --sim verilator`:

- `tb_spadmic_matrix_or_tree_unit`: PASS, 66 pass / 0 fail
- `tb_spadmic_matrix_snapshot_frontend_unit`: PASS, 14 pass / 0 fail
- `tb_spadmic_matrix_reset_ctrl_unit`: PASS, 15 pass / 0 fail
- `tb_spadmic_event_coordinator_modes_unit`: PASS, 18 pass / 0 fail
- `tb_spadmic_ddr16_tx_pairer_unit`: PASS, 14 pass / 0 fail
- `tb_spadmic_matrix_cfg_ctrl_unit`: PASS, 32 pass / 0 fail after Builder fixes
- `tb_spadmic_top_sequencer_unit`: PASS, 30 pass / 0 fail
- `git diff --check`: PASS

Verifier also reported full-top `spadmic_top_v1` Verilator lint passed with return code 0 before Builder fixes.

## Findings

### P1-001 - Matrix Config Immediate Rejects Left Stale Valid/Readback

- Severity: MEDIUM
- Status: FIXED
- Issue: immediate reject paths for busy, invalid op, and invalid column set `done/error/last_error` but left old readback and valid status visible after a previous successful command.
- Affected files:
  - `TOP/rtl/spadmic_matrix_cfg_ctrl.sv`
  - `TOP/tb/tb_spadmic_matrix_cfg_ctrl_unit.sv`
- Builder response:
  - immediate rejects now clear `readback_valid_o`;
  - immediate rejects clear `rdata_o`;
  - immediate rejects conservatively clear `matrix_cfg_valid_o`, forcing software to re-verify after an illegal matrix-config command;
  - accepted commands also clear `matrix_cfg_valid_o` until the command completes successfully;
  - the unit test now checks exact `ERR_BUSY` and `ERR_INVALID_COL` values and stale-valid cleanup.
- Fix status: FIXED.

### P1-002 - Config-Domain Reset Alone Could Leave Sys Busy Stuck

- Severity: MEDIUM
- Status: FIXED
- Issue: `rst_cfg_n` cleared config-domain state but did not notify the `clk_sys` side, so `busy_o` could remain set if only the config domain reset/aborted.
- Affected files:
  - `TOP/rtl/spadmic_matrix_cfg_ctrl.sv`
  - `TOP/tb/tb_spadmic_matrix_cfg_ctrl_unit.sv`
- Builder response:
  - `rst_cfg_n` is synchronized into `clk_sys`;
  - when a config-domain reset is observed during a busy command, the sys side clears `busy_o`, reports `done_o/error_o`, sets `last_error_o=ERR_CFG_RESET`, clears readback, and clears `matrix_cfg_valid_o`;
  - request toggle and command-hold registers are realigned to avoid replay after config reset;
  - the unit test now asserts `rst_cfg_n` without `rst_sys_n` and checks abort status.
- Fix status: FIXED.

### P1-003 - Phase 1 Review Artifact Missing

- Severity: NOTE
- Status: FIXED
- Issue: Phase 1 review was pending in the decision log and no review report existed.
- Builder response: this report was created. Decision log update will record recheck result after Verifier recheck.
- Fix status: FIXED.

## CDC/Reset/STA/PnR Risks

- Matrix configuration CDC is suitable for Phase 1 RTL simulation but remains non-signoff until matrix timing is available.
- The `clk_cfg_40m` reset-abort feedback uses a synchronized reset-status observation; integration must ensure reset pulses are wide enough to be seen by `clk_sys`.
- OR64 physical balancing still requires synthesis/PnR constraint work in a later phase.
- Reset-output register placement near Rz/Yz/Bz pins is not addressed by standalone RTL.
- DDR16 macro contract remains provisional until macro handoff.

## Required Fixes Before Phase 2

None remaining after Builder fixes and Verifier recheck.

## Builder Response Summary

- Fixed matrix config immediate-reject status cleanup.
- Added config-domain reset abort feedback into `clk_sys`.
- Added unit coverage for exact reject codes, stale readback cleanup, cfg-valid cleanup, and cfg-reset-only abort.
- Reran all Phase 1 unit benches and existing `tb_spadmic_top_sequencer_unit`; all pass.

## Signoff

- Verifier initial review: completed.
- Builder fixes: completed.
- Verifier recheck: PASS, no remaining findings in the requested recheck scope.
