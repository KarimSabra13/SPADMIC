# SPADMIC Matrix TOP Decision Log

Status: Phase 0 implementation anchor, planning and documentation first.

## Repository Snapshot

- Branch: `SPADMIC_test`
- Commit: `a9ec83afc2ca2923896af014e6bc8e4fae6c4296`
- Last commit: `a9ec83af position: add matrice3 final matrix extraction results`
- Date/time: `2026-06-28T12:44:34+02:00`
- Working tree at Phase 0 start:
  - `?? ParameterDefs.sv`
  - `?? multi_ShiftRegisterChain_cfg_v1.sv`
  - `?? pixel_readout.pdf`

The untracked files are user-owned references. They must not be deleted, reformatted, or added to compile filelists unless explicitly approved.

## Source Priority

1. [FROZEN] User decisions in the matrix-top implementation prompts.
2. Current RTL on `SPADMIC_test`.
3. Active repository documentation on `SPADMIC_test`.
4. Current tests and constraints.
5. Matrix handoff data under `position/docs/matrix_handoffs/20260626_matrice3_final_lef_extract_norm/`.
6. Old reference files `pixel_readout.pdf`, `multi_ShiftRegisterChain_cfg_v1.sv`, `ParameterDefs.sv`.
7. Engineering recommendation, clearly marked as such.

When documentation and RTL disagree, the mismatch is recorded rather than silently resolved.

## Frozen User Decisions

- [FROZEN] Final matrix-facing event names are `R`, `Y`, and `B`.
- [FROZEN] Legacy axis mapping is `X == R`, `Y == Y`, and `Z == B`.
- [FROZEN] Matrix event buses are active-high `R_i[63:0]`, `Y_i[63:0]`, and `B_i[63:0]`.
- [FROZEN] Matrix selective reset buses are active-low `Rz_o[63:0]`, `Yz_o[63:0]`, and `Bz_o[63:0]`.
- [FROZEN] Reset-select inactive value is all ones.
- [FROZEN] Matrix reset is active-low and level-sensitive for v1.
- [FROZEN] Cartesian over-reset is accepted for v1 when several R/Y/B lines are asserted.
- [FROZEN] No reset retry, adaptive pulse width, per-bit reset-clear verification, or sequential per-diode reset in v1.
- [FROZEN] Reset width is a 16-bit `clk_sys` cycle count. `0` disables automatic selective reset. `1` means exactly one full `clk_sys` cycle.
- [FROZEN] Matrix configuration has 44 columns, 32 lines per column, 2 configuration bits per line, and 64 bits per column.
- [FROZEN] Matrix configuration uses `Din/Cin` at the bottom and `Dout/Cout` at the top.
- [FROZEN] Matrix configuration uses a separate PLL-generated `clk_cfg_40m` domain, not a simple divided enable in `clk_sys`.
- [FROZEN] Long matrix configuration operations use CSR command/status. I2C transactions must not be held open during shifting.
- [FROZEN] Acquisition is disabled during matrix configuration unless the matrix designer later proves it safe.
- [FROZEN] `clk_sys` is 160 MHz. `clk_ref_40m` is the MPTDC STOP reference. `clk_cfg_40m` is the separate matrix configuration clock.
- [FROZEN] Digital logic is 1.8 V. Matrix level shifting is contained inside the macro. No new digital power-domain architecture is added.
- [FROZEN] Three independent OR64 START paths are required. They must not be merged, resynchronized into one common START, or intentionally aligned.
- [FROZEN] Normal SPAD operation uses all three TDC axes. Per-axis disable is diagnostic/calibration functionality.
- [FROZEN] Position-only mode disables MPTDC acquisition.
- [FROZEN] Calibration mode blinds the matrix path, disables position and matrix auto reset, and uses selected calibration axes only.
- [FROZEN] Only one physical event is in flight in v1.
- [FROZEN] Event conditions use mode-dependent masks. A fixed `raw_snapshot_valid && start_seen_R && start_seen_Y && start_seen_B && position_packet_ready` condition is forbidden.
- [FROZEN] One 14-bit physical event ID is shared by all expected packets of one accepted physical event.
- [FROZEN] Event ID wraps naturally. Wrap is not a hardware error.
- [FROZEN] Error reporting is CSR-only for v1. A TX error packet is deferred.
- [FROZEN] Final physical TX target is 16 DDR data bits using a custom macro boundary. The current 8-bit DDR TX RTL is obsolete for final silicon.
- [FROZEN] No MPTDC measurement internals may be edited without explicit approval.

## Defaults Accepted For V1

- [DEFAULT FOR V1] Matrix configuration bit order is `bit[2*line+0] = cfg0(line)` and `bit[2*line+1] = cfg1(line)`, for `line=0..31`.
- [DEFAULT FOR V1] `Cin` active edge is rising edge.
- [DEFAULT FOR V1] `Din` is prepared while `Cin` is inactive, stable before the rising edge, and held after the rising edge.
- [DEFAULT FOR V1] Exact matrix configuration timing at 40 MHz is not available. Implement a clean `clk_cfg_40m` domain and real `clk_sys <-> clk_cfg_40m` CDC, mark the interface non-signoff until analog handoff provides setup, hold, min high, min low, and Dout/Cout delay.
- [DEFAULT FOR V1] DDR16 provisional contract uses `DATA_L/DATA_H` style data and one valid per pair. V1 should prefer even logical packet lengths or safe padding before the macro.
- [DEFAULT FOR V1] `DATA_L` carries the older logical 16-bit word and `DATA_H` carries the next word until the DDR macro designer confirms exact edge mapping.
- [DEFAULT FOR V1] Bundle order should be deterministic `R`, `Y`, `B`, `POSITION` if simple. Headers remain authoritative.
- [DEFAULT FOR V1] Readback is exposed through CSR/I2C only. No TX readback stream is added in v1.
- [DEFAULT FOR V1] Debug/status should use CSR/I2C. Do not add new top-level debug pins unless required for silicon operation.
- [DEFAULT FOR V1] Matrix snapshot rearm waits for two consecutive synchronized all-zero R/Y/B samples.
- [DEFAULT FOR V1] MPTDC START confirmation should be wrapper-local or TOP-local. Do not modify `mptdc_axis_core` for this unless proven unavoidable.

## Operating Modes

- [FROZEN] Use explicit operating modes unless an implementation review proves a safer existing encoding:
  - `MODE_DISABLED`
  - `MODE_TDC_ONLY`
  - `MODE_POSITION_ONLY`
  - `MODE_BOTH`
  - `MODE_CALIBRATION`
- [FROZEN] Source bit mapping:
  - bit 0: R TDC, legacy X
  - bit 1: Y TDC
  - bit 2: B TDC, legacy Z
  - bit 3: POSITION
- [FROZEN] TDC-only waits for raw snapshot plus required TDC START confirmations, then waits only for R/Y/B TDC packets.
- [FROZEN] Position-only ignores all MPTDC ready/busy/packet state and waits only for position packet flow.
- [FROZEN] BOTH waits for raw snapshot, all three required TDC START confirmations, and all four expected packet sources.
- [FROZEN] Calibration ignores matrix activity and waits only for selected calibration TDC axes.
- [FROZEN] All required masks are latched at event open and cannot change mid-event because of CSR writes.

## Matrix Handoff Facts

- [FROZEN] Macro: `matrice3`
- [FROZEN] Approximate size: `1999.91 um x 1725.54 um`
- [FROZEN] Non-zero LEF origin: `51.395, 65.86`
- [FROZEN] Extracted pins: 565 pins and 567 pin shapes.
- [FROZEN] Obstructions: 1916 obstruction shapes.
- [FROZEN] Floorplan work must use normalized `ll_*` CSV coordinates, not naive raw LEF coordinates.
- [FROZEN] Useful machine-readable file: `position/docs/matrix_handoffs/20260626_matrice3_final_lef_extract_norm/matrice3_pin_coordinates.csv`.

Pin family summary from the CSV:

| Family | Count | Side distribution using `ll_*` |
| --- | ---: | --- |
| R | 64 | 50 TOP, 14 INTERNAL_NEAREST_RIGHT |
| Rz | 64 | 50 TOP, 14 INTERNAL_NEAREST_RIGHT |
| Y | 64 | 64 INTERNAL_NEAREST_RIGHT |
| Yz | 64 | 64 INTERNAL_NEAREST_RIGHT |
| B | 64 | 50 BOTTOM, 14 INTERNAL_NEAREST_RIGHT |
| Bz | 64 | 50 BOTTOM, 14 INTERNAL_NEAREST_RIGHT |
| Din | 44 | 44 BOTTOM |
| Cin | 44 | 44 BOTTOM |
| Dout | 44 | 44 TOP |
| Cout | 44 | 44 TOP |

## Floorplan Decisions

- [FROZEN] The `matrice3` macro should be placed on the left side of the chip and roughly centered vertically.
- [FROZEN] The three MPTDC blocks should be placed to the right of `matrice3` and very close to each other.
- [FROZEN] The position block should be partially distributed near matrix pins/lines for registers, AOR, and preprocessing, then grouped toward a main cluster/packet block.
- [FROZEN] Arbiter, FIFO, and TX logic should be placed toward north-east/north because final DDR outputs are on the north side of the chip, not the right side from the simplified diagram.
- [FROZEN] Control/reset/supervision registers should be placed toward the bottom of the matrix.
- [FROZEN] PLL should be placed toward bottom-right.
- [FROZEN] The provided image is conceptual only. Physical planning must use `matrice3_pin_coordinates.csv`, normalized `ll_*` coordinates, and explicit routing corridors for `INTERNAL_NEAREST_RIGHT` pins.
- [TBD - NEEDS FLOORPLAN] Final top-chip die size, exact macro coordinate, halo, pin corridors, power-grid keepouts, and final MPTDC orientation.

## Matrix Reset Assumptions

- [FROZEN] Reset masks are active-high internally:
  - `r_reset_mask_q[63:0]`
  - `y_reset_mask_q[63:0]`
  - `b_reset_mask_q[63:0]`
- [FROZEN] Physical outputs are inverted:
  - `Rz_o = ~r_reset_mask_q`
  - `Yz_o = ~y_reset_mask_q`
  - `Bz_o = ~b_reset_mask_q`
- [FROZEN] On global chip reset, masks clear to zero so physical reset-select outputs immediately go inactive high.
- [FROZEN] Reset mask derives from frozen raw snapshot bits, not clusters.
- [TBD - NEEDS MATRIX DESIGNER] Minimum active-low reset width.
- [TBD - NEEDS MATRIX DESIGNER] Maximum safe active-low reset width.
- [TBD - NEEDS MATRIX DESIGNER] Allowed Rz/Yz/Bz skew and required overlap.
- [TBD - NEEDS MATRIX DESIGNER] Recovery latency after reset release.
- [TBD - NEEDS MATRIX DESIGNER] Whether a separate global matrix reset exists and whether it clears configuration.

## Matrix Configuration Assumptions

- [FROZEN] Required v1 operations:
  - `WRITE_COLUMN_64`
  - `READ_COLUMN_64`
  - `GLOBAL_FILL_0`
  - `GLOBAL_FILL_1`
- [DEFAULT FOR V1] After `WRITE_COLUMN_64`, copy/read back the whole selected 64-bit column through Dout/Cout into CSR-visible readback registers.
- [DEFAULT FOR V1] For global fill, readback reference column 0.
- [FROZEN] The old PDF and old shift-register RTL are concept references only. They are not drop-in RTL for SPADMIC.
- [FROZEN] Do not copy combinational clock gating from `multi_ShiftRegisterChain_cfg_v1.sv`.
- [TBD - NEEDS MATRIX DESIGNER] Exact bit meaning for `cfg0` and `cfg1`.
- [TBD - NEEDS MATRIX DESIGNER] Exact Dout/Cout behavior and timing.
- [TBD - NEEDS MATRIX DESIGNER] Whether several columns may be clocked together for global fill.

## DDR Assumptions

- [FROZEN] Current 8-bit DDR TX in `TOP/rtl/spadmic_ddr_tx.sv` is obsolete for final silicon.
- [FROZEN] Final silicon uses a clean custom DDR macro boundary. Do not implement final DDR behavior with generic dual-edge RTL.
- [DEFAULT FOR V1] Digital logic presents `ddr_data_l_o[15:0]`, `ddr_data_h_o[15:0]`, and `ddr_pair_valid_o`.
- [DEFAULT FOR V1] `ddr_clk_o` is derived from `clk_sys` unless the DDR macro designer later assigns forwarded-clock ownership differently.
- [TBD - NEEDS DDR DESIGNER] Exact macro port list, edge mapping, valid semantics, output enable, reset, duty-cycle tolerance, and output timing.

## MPTDC Boundary

- [FROZEN] Protected MPTDC internals:
  - `MPTDC/rtl/top/mptdc_axis_core.sv`
  - `MPTDC/rtl/top/mptdc_core.sv`
  - `MPTDC/rtl/async/*`
  - `MPTDC/rtl/pd/*`
  - `MPTDC/rtl/osc/*`
  - `MPTDC/rtl/ctrl/*`
  - `MPTDC/rtl/readout/*`
- [NOT IMPLEMENTED] No MPTDC internals are edited in Phase 0 or Phase 1.
- [DEFERRED] If a future `start_accepted_o` from the MPTDC core is proven necessary, it requires explicit user approval and fresh MPTDC verification/synthesis handoff.

## Known Obsolete Or Incomplete RTL

- [OBSOLETE RTL] `TOP/rtl/spadmic_top_v1.sv` still exposes scalar async SPAD event pins plus separate `x/y/z_lines_i[63:0]`, not final physical R/Y/B matrix ports.
- [OBSOLETE RTL] `TOP/rtl/spadmic_top_v1.sv` exports one active-high `spad_matrix_rst_o`, not final Rz/Yz/Bz active-low buses.
- [OBSOLETE RTL] `TOP/rtl/spadmic_ddr_tx.sv` implements current 8-bit DDR TX and is not the final DDR16 macro boundary.
- [OBSOLETE RTL] Current CSR address storage/decode is 12-bit in active RTL, while the final external map is 16-bit and reserves regions through `0x7xxx`.
- [RISK] Phase 3 must widen CSR address storage/decode and I2C pointer handling before the final `0x0000-0x7FFF` map is reachable.
- [OBSOLETE RTL] Current event ID tagging is packet-oriented in the output path, not one physical event ID shared across the bundle.
- [RISK] Position event count width mismatches documentation: RTL uses a small event count while CSR docs describe a wider field.
- [RISK] Current active docs and some CI/test references are stale and must not be treated as tapeout-complete evidence.

## Implementation Phases

- [IMPLEMENTED] Phase 0: decision log, final planning docs, floorplan plan, verification/STA/CDC/PNR plan, and Phase 0 review report.
- [IMPLEMENTED] Phase 1: standalone RTL modules and unit tests.
- [NOT IMPLEMENTED] Phase 2: `spadmic_top_matrix_v1.sv` shell.
- [NOT IMPLEMENTED] Phase 3: CSR and I2C integration.
- [NOT IMPLEMENTED] Phase 4: MPTDC/position/event integration.
- [NOT IMPLEMENTED] Phase 5: DDR16 and output path integration.
- [NOT IMPLEMENTED] Phase 6: regression, constraints, and cleanup.

## Review Loop Status

- [IMPLEMENTED] Builder Phase 0 documentation created.
- [IMPLEMENTED] Verifier Phase 0 report created at `TOP/docs/reviews/REVIEW_MATRIX_TOP_PHASE0.md`.
- [IMPLEMENTED] Builder response to Phase 0 findings recorded in the review report.
- [VERIFIED] Verifier Phase 0 recheck passed with no remaining findings in scope.
- [IMPLEMENTED] Builder Phase 1 standalone RTL and unit tests created.
- [IMPLEMENTED] Builder Phase 1 Verilator unit suite passed before Verifier review.
- [IMPLEMENTED] Verifier Phase 1 review report created at `TOP/docs/reviews/REVIEW_MATRIX_TOP_PHASE1.md`.
- [IMPLEMENTED] Builder response to Phase 1 findings recorded in the review report.
- [VERIFIED] Verifier Phase 1 recheck passed with no remaining findings in scope.

## Affected Files

Phase 0 documentation files:

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

Phase 1 planned standalone RTL/test files:

- `TOP/rtl/spadmic_matrix_or_tree.sv`
- `TOP/rtl/spadmic_matrix_snapshot_frontend.sv`
- `TOP/rtl/spadmic_matrix_reset_ctrl.sv`
- `TOP/rtl/spadmic_event_coordinator.sv`
- `TOP/rtl/spadmic_ddr16_tx_pairer.sv`
- `TOP/rtl/spadmic_matrix_cfg_ctrl.sv`
- `TOP/tb/tb_spadmic_matrix_or_tree_unit.sv`
- `TOP/tb/tb_spadmic_matrix_snapshot_frontend_unit.sv`
- `TOP/tb/tb_spadmic_matrix_reset_ctrl_unit.sv`
- `TOP/tb/tb_spadmic_event_coordinator_modes_unit.sv`
- `TOP/tb/tb_spadmic_ddr16_tx_pairer_unit.sv`
- `TOP/tb/tb_spadmic_matrix_cfg_ctrl_unit.sv`
