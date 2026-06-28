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

Scope:

- create `TOP/rtl/spadmic_top_matrix_v1.sv`;
- preserve `TOP/rtl/spadmic_top_v1.sv`;
- expose final/provisional R/Y/B, Rz/Yz/Bz, matrix configuration, `clk_cfg_40m`, and DDR16 macro-boundary ports;
- instantiate standalone blocks at skeleton/integration level.

Exit criteria:

- old top still compiles;
- new shell compiles far enough for structural lint;
- no protected MPTDC internals edited.

## Phase 3 - CSR And I2C Integration

Scope:

- implement 16-bit external CSR map gradually;
- preserve simple I2C behavior;
- integrate matrix configuration command/status;
- implement requested/active mode-safe controls;
- implement W1C faults and saturating counters.

Exit criteria:

- invalid address behavior documented and tested;
- busy rejects tested;
- reset defaults tested;
- command/status CDC visible through CSR.

## Phase 4 - MPTDC, Position, Event Integration

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

## Phase 5 - DDR16 Output Integration

Scope:

- connect DDR16 pairer to output path;
- retire current 8-bit DDR TX from final top path;
- keep old `spadmic_top_v1` intact until replacement validation completes.

Exit criteria:

- pairer empty/busy included in safe idle;
- old 8-bit DDR not used by final matrix top;
- even/padded packet policy tested.

## Phase 6 - Full Regression And Physical Preparation

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
