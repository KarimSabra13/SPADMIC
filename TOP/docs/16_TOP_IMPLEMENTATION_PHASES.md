# Matrix TOP Implementation Phases

Status: Phase 0 controlled implementation plan.

## Phase 0 - Documentation And Decision Log

Scope:

- create decision log;
- record frozen decisions and defaults;
- create final plan docs;
- create floorplan, DDR, matrix configuration/reset, CSR, verification, and STA/CDC/PNR plans;
- create Verifier review report.

Files:

- `TOP/docs/DECISIONS_LOG_MATRIX_TOP.md`
- `TOP/docs/11_FINAL_TOP_RESET_CONTROL_PLAN.md`
- `TOP/docs/12_FINAL_CSR_MAP_PROPOSAL.md`
- `TOP/docs/13_MATRIX_CONFIG_AND_RESET_CONTRACT.md`
- `TOP/docs/14_DDR16_TX_MACRO_CONTRACT.md`
- `TOP/docs/15_FLOORPLAN_MATRICE3_INTEGRATION_PLAN.md`
- `TOP/docs/16_TOP_IMPLEMENTATION_PHASES.md`
- `TOP/docs/17_VERIFICATION_PLAN_MATRIX_TOP.md`
- `TOP/docs/18_STA_CDC_PNR_PLAN_MATRIX_TOP.md`
- `TOP/docs/reviews/REVIEW_MATRIX_TOP_PHASE0.md`

Exit criteria:

- Phase 0 docs exist;
- Verifier review report exists;
- all BLOCKER/HIGH documentation findings are fixed, waived, or tracked in the decision log.

## Phase 1 - Standalone RTL Modules And Unit Tests

Scope:

- create standalone TOP-owned modules;
- create directed unit tests;
- do not integrate into final top yet;
- do not modify protected MPTDC internals;
- do not break `spadmic_top_v1`.

RTL files:

- `TOP/rtl/spadmic_matrix_or_tree.sv`
- `TOP/rtl/spadmic_matrix_snapshot_frontend.sv`
- `TOP/rtl/spadmic_matrix_reset_ctrl.sv`
- `TOP/rtl/spadmic_event_coordinator.sv`
- `TOP/rtl/spadmic_ddr16_tx_pairer.sv`
- `TOP/rtl/spadmic_matrix_cfg_ctrl.sv`

Unit tests:

- `TOP/tb/tb_spadmic_matrix_or_tree_unit.sv`
- `TOP/tb/tb_spadmic_matrix_snapshot_frontend_unit.sv`
- `TOP/tb/tb_spadmic_matrix_reset_ctrl_unit.sv`
- `TOP/tb/tb_spadmic_event_coordinator_modes_unit.sv`
- `TOP/tb/tb_spadmic_ddr16_tx_pairer_unit.sv`
- `TOP/tb/tb_spadmic_matrix_cfg_ctrl_unit.sv`

Exit criteria:

- Verifier review report exists at `TOP/docs/reviews/REVIEW_MATRIX_TOP_PHASE1.md`;
- standalone lint/simulation commands run or tool absence is recorded;
- no BLOCKER/HIGH issue remains open without explicit waiver.

## Phase 2 - New Top Shell

Status: implemented and verified in the Phase 2/3 continuation patch.

Scope:

- create `TOP/rtl/spadmic_top_matrix_v1.sv`;
- preserve `TOP/rtl/spadmic_top_v1.sv`;
- expose final/provisional R/Y/B, Rz/Yz/Bz, matrix configuration, `clk_cfg_40m`, and DDR16 macro-boundary ports;
- instantiate standalone blocks at skeleton/integration level.

Implemented files:

- `TOP/rtl/spadmic_top_matrix_v1.sv`
- `TOP/filelist.f`
- `TOP/tb/tb_spadmic_top_matrix_v1_shell_unit.sv`

Implemented behavior:

- new top shell exposes `clk_sys`, `clk_ref_40m`, separate `clk_cfg_40m`, `async_rst_n`, I2C open-drain output-enable, R/Y/B event buses, Rz/Yz/Bz active-low reset-select buses, 44-column matrix config ports, calibration inputs, and DDR16 `DATA_L/DATA_H` style outputs;
- old `TOP/rtl/spadmic_top_v1.sv` remains unmodified;
- MPTDC internals remain unmodified;
- shell instantiates the Phase 1 OR64 trees, raw snapshot frontend, matrix reset controller, matrix config CDC controller, event coordinator, DDR16 pairer, I2C slave/bridge, and Phase 3 CSR endpoint;
- snapshot/event activity qualification is direction-mask-aware. TDC-only uses `active_axis_mask`, position-only/BOTH use all R/Y/B directions, and calibration/disabled use no matrix directions;
- at Phase 2, the shell intentionally held normal event resources not-ready until Phase 4 connected real MPTDC and position packet producers. That limitation is now closed for position-only and TDC-only matrix-top flows.

Exit criteria:

- old top still compiles;
- new shell compiles far enough for structural lint;
- no protected MPTDC internals edited.

Builder test evidence:

- `bash TOP/scripts/sim/run_tb.sh tb_spadmic_top_matrix_v1_shell_unit --sim verilator` passed with 13 pass / 0 fail.
- `bash TOP/scripts/sim/run_tb.sh tb_spadmic_matrix_snapshot_frontend_unit --sim verilator` passed with 19 pass / 0 fail, including masked-direction capture/rearm coverage.
- Verifier report: `TOP/docs/reviews/REVIEW_MATRIX_TOP_PHASE2.md`, final status VERIFIED.

## Phase 3 - CSR And I2C Integration

Status: implemented and verified for the new matrix top shell in the Phase 2/3 continuation patch.

Scope:

- implement 16-bit external CSR map gradually;
- preserve simple I2C behavior;
- integrate matrix configuration command/status;
- implement requested/active mode-safe controls;
- implement W1C faults and saturating counters.

Implemented files:

- `TOP/rtl/spadmic_matrix_top_csr.sv`
- `TOP/rtl/spadmic_pkg.sv`
- `TOP/tb/tb_spadmic_matrix_top_csr_unit.sv`

Implemented behavior:

- Phase 3 uses the current active 12-bit internal CSR width and adds matrix-top addresses in the 0x0xx, 0x5xx, 0x6xx, and 0x7xx regions. The final 16-bit external map remains documented as a later widening step.
- `SPADMIC_CSR_MTOP_CTRL_REQUEST` accepts mode/global/axis/auto-reset writes only when the new matrix top reports safe idle and matrix config is not busy.
- Active mode is committed immediately only on accepted safe-idle writes. Busy or invalid writes reject with a CSR error response, W1C sticky fault, last-error code, and saturating counter.
- Matrix snapshot settle/watchdog and reset-width registers are exposed.
- Matrix config command/status registers expose column, 64-bit write data, command start/op, status, last error, readback, and `matrix_cfg_valid`.
- Command while matrix config is busy is rejected in CSR before the CDC controller receives a second command.
- Matrix config command/parameter writes are also rejected when the top path is not safe/idle due to event, snapshot, reset, transition, or matrix-config activity.
- Rejected command writes do not mutate the visible command-op readback.
- I2C transactions stay short; long matrix config operations run autonomously through command/status.

Exit criteria:

- invalid address behavior documented and tested;
- busy rejects tested;
- reset defaults tested;
- command/status CDC visible through CSR.

Builder test evidence:

- `bash TOP/scripts/sim/run_tb.sh tb_spadmic_matrix_top_csr_unit --sim verilator` passed with 70 pass / 0 fail.
- `bash TOP/scripts/sim/run_tb.sh tb_spadmic_top_matrix_v1_shell_unit --sim verilator` passed with 13 pass / 0 fail and exercises real I2C access to the new CSR endpoint.
- After Verifier fixes, `tb_spadmic_matrix_top_csr_unit` passed with 87 pass / 0 fail.
- Subsequent Phase 6 `bash TOP/ci/run_tapeout_readiness.sh` passed locally with 14 pass, 0 fail, and 4 skipped steps caused by unavailable `xrun` and retired standalone VIP.
- Verifier report: `TOP/docs/reviews/REVIEW_MATRIX_TOP_PHASE3.md`, final status VERIFIED.

## Phase 4 - MPTDC, Position, Event Integration

Status: implemented for the new matrix top shell with documented limitations.

Scope:

- integrate MPTDC wrappers without editing MPTDC internals;
- implement wrapper-local start confirmation where needed;
- split or refactor raw snapshot and position packetization;
- implement event ID, masks, bundle barrier, and one-event-in-flight policy.

Exit criteria:

- TDC-only does not wait for position;
- Position-only does not wait for TDC;
- BOTH waits only for active required sources;
- Calibration ignores matrix;
- directed skew orders tested.

Implemented files:

- `TOP/rtl/spadmic_top_matrix_v1.sv`
- `TOP/rtl/spadmic_event_coordinator.sv`
- `TOP/rtl/spadmic_position_snapshot_packetizer.sv`
- `TOP/rtl/spadmic_event_bundle_tx.sv`
- `TOP/rtl/spadmic_matrix_top_csr.sv`
- `TOP/tb/tb_spadmic_event_coordinator_modes_unit.sv`
- `TOP/tb/tb_spadmic_position_snapshot_packetizer_unit.sv`
- `TOP/tb/tb_spadmic_event_bundle_tx_unit.sv`
- `TOP/tb/tb_spadmic_top_matrix_v1_shell_unit.sv`

Implemented behavior:

- TOP-owned frozen START gate before the existing MPTDC wrappers.
- TOP-local synchronized `tdc_start_seen` for reset prerequisites.
- Cleanup-only flow for not-ready rejected matrix events.
- Raw snapshot position packetizer independent from legacy position detector/reset logic.
- Deterministic bundle TX with coordinator-owned event ID patched into all expected EOC words.
- Normal TDC-only/BOTH CSR mode writes require all three axes; calibration allows diagnostic partial masks.

Builder test evidence:

- `tb_spadmic_event_coordinator_modes_unit`: 22 pass / 0 fail.
- `tb_spadmic_position_snapshot_packetizer_unit`: 10 pass / 0 fail.
- `tb_spadmic_event_bundle_tx_unit`: 14 pass / 0 fail.
- `tb_spadmic_top_matrix_v1_shell_unit`: 23 pass / 0 fail, including position-only matrix event through reset/raw packet/DDR16 drain, mode-aware safe-idle with inactive TDC busy, and TDC-only matrix event through real MPTDC wrappers, selective reset, deterministic R/Y/B bundle, DDR16 output, and final drain.

Verifier-driven fixes applied in Phase 4/5:

- `safe_idle` is mode-aware and no longer blocks CSR/config acceptance on inactive TDC or position paths.
- `stop_armed_o` is not used as a pre-event grant input because it changes in response to START and can corrupt the frozen-grant behavior.
- R/Y/B TOP START gates are one-shot per axis after `tdc_start_seen`, preventing repeated conversions from held matrix lines.

## Phase 5 - DDR16 Output Integration

Status: implemented for the new matrix top shell.

Scope:

- connect DDR16 pairer to output path;
- retire current 8-bit DDR TX from final top path;
- keep old `spadmic_top_v1` intact until replacement validation completes.

Exit criteria:

- pairer empty/busy included in safe idle;
- old 8-bit DDR not used by final matrix top;
- even/padded packet policy tested.

Implemented behavior:

- The final matrix top no longer ties the DDR16 pairer idle.
- Bundle words drive `ddr_data_l_o/ddr_data_h_o` through `spadmic_ddr16_tx_pairer`.
- `spadmic_event_bundle_tx.flush_o` is asserted at bundle end so odd final words are padded on `DATA_H`.
- `safe_idle` includes bundle TX and DDR16 pairer empty/busy state.
- The old 8-bit `spadmic_ddr_tx` remains only for `spadmic_top_v1`.

## Phase 6 - Full Regression And Physical Preparation

Status: implemented for local maintained Verilator readiness; final physical signoff remains deferred.

Scope:

- run available directed regressions/lint;
- update SDC placeholders;
- update filelists;
- update stale docs and CI references;
- produce final limitation list.

Exit criteria:

- all maintained tests either pass or failures are documented;
- typical-only signoff limitation recorded;
- no claim of final MMMC, PEX, DRC/LVS, board timing, final DDR, or final matrix timing closure.

Builder/Verifier evidence:

- `bash TOP/ci/run_tapeout_readiness.sh`: PASS, 14 pass / 0 fail / 4 skipped.
- Verilator lint now runs both `spadmic_top_v1` and `spadmic_top_matrix_v1`.
- Skipped steps are `xrun`-dependent Xcelium flows unavailable on this host and retired standalone VIP suites.
- Legacy `spadmic_top_v1` remains intact; the old 8-bit DDR module remains only on the legacy path.
- Protected MPTDC internals remain unmodified.
