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

## Phase 2/3 Continuation Snapshot

- Branch: `SPADMIC_test`
- Base commit before Phase 2/3 edits: `0eb7c84e8b849b930b036f434a6511910c6446bc`
- Base commit message: `0eb7c84e matrix top phase0 phase1 foundation`
- Date/time: `2026-06-28T14:16:27+02:00`
- Working tree at Phase 2/3 start:
  - `?? ParameterDefs.sv`
  - `?? multi_ShiftRegisterChain_cfg_v1.sv`
  - `?? pixel_readout.pdf`

[FROZEN] The root untracked reference files remain user-owned and are not added to the RTL filelists.

## Phase 7 ASIC-Preparation Continuation Snapshot

- Branch: `SPADMIC_test`
- Base commit before Phase 7+ edits: `5cdf489fbfb0a13e1a5ee7f5a253002e023602ac`
- Base commit message: `5cdf489f matrix top phased integration`
- Date/time: `2026-06-28T18:51:27+02:00`
- Working tree at Phase 7+ start:
  - `?? ParameterDefs.sv`
  - `?? multi_ShiftRegisterChain_cfg_v1.sv`
  - `?? pixel_readout.pdf`

[FROZEN] The continuation target is `TOP/rtl/spadmic_top_matrix_v1.sv`, not the legacy `TOP/rtl/spadmic_top_v1.sv`.

[FROZEN] Cadence tools are not available locally in this session. Any Xcelium, Genus, Innovus, CDC/RDC, DRC/LVS, PEX, MMMC, DDR timing, or matrix macro timing result must come from a server run and must not be claimed from local Verilator evidence.

[FROZEN] `clk_cfg_40m` and `clk_ref_40m` are real named 40 MHz logical clocks, but they are not separate external pads in v1. In PLL mode, one PLL 40 MHz output feeds both logical clocks. In external-clock mode, one external 160 MHz pad feeds a divide-by-4 clock that also feeds both logical 40 MHz clocks. The matrix configuration controller must keep its stable-bus handshake until final STA/CDC proves the generated-clock relationship is safe to simplify.

[FROZEN] The matrix-top core has a dedicated active-high I2C pad reset input
`i2c_rst_i` / pad `i2c_RST`. It resets only the I2C transport path and is not a
global digital reset.

[FROZEN] PLL macro control uses CSR-visible digital outputs for SelA_Fint
through SelH_Fint, Sw0_RO through Sw4_RO, sel_pulsePFD, Enable_Div, Sel_40M,
and the 160 MHz source select. PLL lock/status is CSR-visible only. Ibi_KVCO,
Icp, Ref_in_pll_ro, Rst_Div, and Rst_CP are external pad inputs owned by the
future pad-ring/PLL wrapper.

[FROZEN] DDRs2 is the analog/custom north fast-output macro and must not be
synthesized by TOP Genus.

[FROZEN] DDRs2 has 19 lanes total: 16 data, 1 valid, 1 forwarded clock, and 1
spare.

[FROZEN] DDRs2 has no marker lane. The valid lane is a simple FPGA receiver
data-valid indication, not an error flag.

[FROZEN] The DDRs2 spare lane is tied low and unused by the v1 protocol.

[FROZEN] The internal digital TX stream remains 16-bit. The DDRs2 19-lane
macro expansion is handled by `spadmic_ddrs2_adapter`, not by changing
`spadmic_ddr16_tx_pairer`.

[FROZEN] SLVS/receiver GPIO controls are CSR-driven internal top outputs.

[FROZEN] SLVS driver controls: `S_DRV[3:0]`, `EN_VREF_EXT`, `EN_DRV`,
`VREF_ADJ_B`, `EN_VREF_400mV`, and `EN_REF_DRV_B`.

[FROZEN] Receiver controls: `S_RX[3:0]`, `EN_RX`, and `EN_TERM`.

[FROZEN] CSR address: `SPADMIC_CSR_SLVS_GPIO_CTRL = 16'h7010`.

[TBD] Analog polarity/defaults for `VREF_ADJ_B` and `EN_REF_DRV_B` must be
confirmed.

[DEFERRED] I2C pad-wrapper / SDA open-drain physical implementation will be
handled later.

[FROZEN] PAD_VREF_EXT is a real external analog pad. Digital CSR only controls
`EN_VREF_EXT` and the related SLVS/RX GPIO bits.

[FROZEN] TXRX4TDC is an analog/custom black-box macro for tap/receiver
observation or drive. It is not synthesized by TOP Genus.

[FROZEN] `Cout` is the returned `Cin` after matrix propagation/RC effects and must be used for physical matrix configuration readback timing. The existing mirror-readback behavior is not final.

[FROZEN] A real `clk_sys` output FIFO is required between event bundle TX and DDR16 pairer. The physical-planning target depth is 256 logical 16-bit words plus marker metadata, with event admission blocked when free space is below the documented worst-case event reservation.

[FROZEN] Shared TDC configuration is required through matrix-top CSR:
  - programmable `max_hits`, default 15;
  - one shared slow RO code for all three axes;
  - one shared fast RO code for all three axes;
  - optional `fifo_clr` and `soft_reset` pulses;
  - calibration axis mask.

[DEFAULT FOR V1] Exact RO code-to-frequency transfer is not known. Document the approximate 700 MHz RO target from MPTDC evidence but do not invent a code-frequency equation.

[DEFAULT FOR V1] Writing RO code `8'h00` may be used as the clear/default policy if that is the simplest safe implementation.

[FROZEN] Position must support both raw bitmap and cluster packet modes selectable through CSR/I2C. Compact cluster packet mode is optional/deferred unless the existing packet format is needed later.

[IMPLEMENTED] Phase 0 preflight confirmed no local diffs in protected MPTDC internals and no diff in `TOP/rtl/spadmic_top_v1.sv`.

[RISK] Phase 0 preflight limitations and current continuation status:
  - [IMPLEMENTED] CSR address width is now 16-bit for the matrix-top package/I2C path as of the CSR16 continuation; the legacy top decoder remains outside this target.
  - [IMPLEMENTED] Shared TDC max-hits and RO codes now come from matrix-top CSR and are wired to the three wrappers.
  - [IMPLEMENTED] Position path in the new top now supports raw bitmap mode and fixed 8-word cluster mode from frozen snapshots.
  - [IMPLEMENTED] Matrix configuration readback is now returned-`Cout` based in the digital controller. It remains non-signoff until matrix macro timing is available.
  - [IMPLEMENTED] Bundle TX now feeds a real `clk_sys` output FIFO before the DDR16 pairer.
  - [VERIFIED] Full-top BOTH and directed R/Y/B skew campaign tests are now in the maintained local readiness gate as of Phase 7.

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
- [FROZEN] Current top floorplan envelope uses the layout-derived die of about `4293.179 um x 3209.173 um`. Die height is not flexible in the normal flow.
- [FROZEN] The layout description also reports a normalized BOX_RING hint of about `X=3200 um` by `Y=3700 um`. Until a parseable BOX_RING export maps coordinate frames, scripts must record that hint but continue to gate against explicit die-width/die-height arguments rather than silently swapping dimensions.
- [FROZEN] Current pad-ring/core physical planning depth is about `164 um`, replacing the older `120 um` abstract keepout.
- [FROZEN] First MPTDC placeholder arrangement is a vertical stack to the right of the matrix, with R top, Y middle, and B bottom.
- [FROZEN] Required MPTDC planning case uses the full DEF/block boundary `1061.20 um x 801.92 um`, plus `5%` dimensional margin and a provisional `20 um` halo around each MPTDC.
- [FROZEN] MPTDCs should keep the same orientation where possible; no independent mirroring/rotation is allowed unless a real PnR blockage justifies it.
- [FROZEN] If the full-boundary MPTDC stack is tight, reduce the inter-MPTDC gap from `40 um` to `20 um` before considering any die-size risk item.
- [FROZEN] If the vertical MPTDC placeholder stack does not fit, scripts must stop and report. Do not silently switch to a 2+1 fallback.
- [FROZEN] DDR16 is part of the staged per-block flow. The final top uses 16 north-row SLVS data driver instances, one forwarded-clock driver, and one valid driver. Full top assembly still remains deferred until wrapper/pad-ring and macro collateral exist.
- [FROZEN] The top layout source of truth for BOX_RING/pad-ring geometry is the OA cell at `/group/validmgr/PROJET/Prj_xh018/ksabra/cds/design/SPADMIC`.
- [TBD - NEEDS FLOORPLAN] Exact BOX_RING blockage coordinates, final PLL size, and final top-level pad coordinates still need a parseable export or analog/layout handoff.

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
- [IMPLEMENTED] Current matrix-top CSR address storage/decode is 16-bit. The legacy top decoder still has old-top assumptions and remains outside the matrix-top target.
- [IMPLEMENTED] The CSR16 continuation widened matrix-top CSR address storage/decode and I2C pointer handling so the final `0x0000-0x7FFF` map is reachable in the matrix-top target path.
- [OBSOLETE RTL] Legacy `spadmic_correlated_tx` packet-oriented event tagging remains in the old top path. The matrix-top bundle path now patches one physical event ID across all expected packet EOC words.
- [RISK] Position event count width mismatches documentation: RTL uses a small event count while CSR docs describe a wider field.
- [RISK] Current active docs and some CI/test references are stale and must not be treated as tapeout-complete evidence.
- [IMPLEMENTED] `TOP/rtl/spadmic_top_matrix_v1.sv` is now the Phase 2 matrix-top shell. It does not replace or retire `TOP/rtl/spadmic_top_v1.sv`.
- [IMPLEMENTED] The new matrix top exposes `clk_cfg_40m`, R/Y/B matrix event buses, Rz/Yz/Bz reset-select outputs, 44-column Din/Cin/Dout/Cout, calibration inputs, and the DDR16 `DATA_L/DATA_H` style boundary.
- [IMPLEMENTED] The new matrix top instantiates the Phase 1 snapshot, reset, matrix configuration, OR-tree, event coordinator, DDR16 pairer, I2C slave, I2C bridge, and matrix-top CSR endpoint.
- [IMPLEMENTED] Matrix snapshot direction qualification is explicit and mask-aware through `required_direction_mask_i`.
- [IMPLEMENTED] `spadmic_top_matrix_v1` derives the snapshot/event direction mask from active mode:
  - TDC-only uses `active_axis_mask`.
  - Position-only uses `3'b111`.
  - BOTH uses `3'b111`.
  - Disabled and calibration use `3'b000`.
- [IMPLEMENTED] `matrix_activity` is masked with the same direction mask, avoiding an unqualified fixed OR/AND across inactive directions.
- [IMPLEMENTED] The new matrix top now computes `pre_event_resources_ready` from event idle, snapshot/reset/config idle, mode-aware required producer idle/ready state, and output drain state. It no longer holds the grant false after Phase 4/5 integration.
- [IMPLEMENTED] `TOP/rtl/spadmic_matrix_top_csr.sv` is the Phase 3 matrix-top CSR endpoint for the new shell. It responds to every I2C/CSR transaction directly so the I2C bridge never waits forever after writes.
- [IMPLEMENTED] Matrix configuration CSR command/parameter writes are rejected unless the top is path-safe and matrix configuration is not busy.
- [IMPLEMENTED] Matrix configuration command readback remains unchanged after rejected command writes.
- [IMPLEMENTED] Matrix configuration `WRITE_COLUMN_64`, `READ_COLUMN_64`, `GLOBAL_FILL_0`, and `GLOBAL_FILL_1` now wait for the selected/readback column's returned `Cout` strobe and sample the corresponding `Dout` bit through a per-column returned-clock sampler.
- [IMPLEMENTED] Missing returned `Cout` raises `ERR_COUT_TIMEOUT`, clears `readback_valid`, and clears `matrix_cfg_valid`.
- [RISK] Returned-`Cout` capture is a real CDC/RDC boundary. It is functionally modeled and locally Verilator-tested, but not CDC/RDC/signoff-clean until Cadence CDC/RDC and matrix timing handoff are available.
- [IMPLEMENTED] The CSR16 continuation supersedes the earlier incremental 12-bit matrix-top CSR step. Active matrix-top registers now use final 16-bit addresses.
- [RISK] Phase 3 does not yet replace the old `spadmic_csr_decoder` path used by `spadmic_top_v1`. That is intentional to avoid breaking the legacy top while the matrix top is being built.

## Implementation Phases

- [IMPLEMENTED] Phase 0: decision log, final planning docs, floorplan plan, verification/STA/CDC/PNR plan, and Phase 0 review report.
- [IMPLEMENTED] Phase 1: standalone RTL modules and unit tests.
- [IMPLEMENTED] Phase 2: `spadmic_top_matrix_v1.sv` shell.
- [IMPLEMENTED] Phase 3: CSR and I2C integration for the new matrix shell.
- [IMPLEMENTED] Phase 4: MPTDC wrappers, frozen TOP-owned START gating, raw snapshot position packetizer, rejected-event cleanup, and mode-aware event source masks integrated into `spadmic_top_matrix_v1`.
- [IMPLEMENTED] Phase 5: coordinator-owned bundle TX, one physical event ID per expected packet, DDR16 pairer connection, bundle flush/padding, and TX status visibility integrated into `spadmic_top_matrix_v1`.
- [IMPLEMENTED] Phase 6: inserted the required output FIFO and event-admission reservation path between bundle TX and DDR16 pairer. Final Xcelium, STA, CDC signoff, PnR, analog matrix, and DDR macro handoff remain deferred.
- [VERIFIED] Phase 6 output FIFO local gate passed `bash TOP/ci/run_tapeout_readiness.sh` with 17 pass, 0 fail, and 4 expected local skips after the ordered-marker regression was added. Review recorded in `TOP/docs/reviews/REVIEW_MATRIX_TOP_OUTPUT_FIFO.md`.
- [IMPLEMENTED] Phase 7 expands the maintained local Verilator readiness gate with named CSR/I2C16, position raw/cluster, Cout readback, output FIFO pressure, BOTH full, skew-campaign, reset-abort, and mode-transition tests for the matrix top.
- [IMPLEMENTED] The continuation added the explicit `tb_spadmic_matrix_top_csr_16b_unit` artifact name, expanded the R/Y/B skew campaign with required offset classes, and added `tb_spadmic_top_output_fifo_pressure_integration_unit` for real top-level FIFO-pressure coverage.
- [VERIFIED] Builder local Phase 7 gate `bash TOP/ci/run_tapeout_readiness.sh` passed with 33 pass, 0 fail, and 4 expected local skips. The skips are Xcelium TOP smoke, Xcelium directed regression, and retired standalone VIP steps; Xcelium remains a server-only gate.

## Phase 4/5 Implementation Decisions

- [IMPLEMENTED] The protected MPTDC product boundary remains untouched. `mptdc_axis_core`, `mptdc_core`, MPTDC async/ctrl/readout/pd/osc RTL are not edited.
- [IMPLEMENTED] `spadmic_top_matrix_v1` instantiates three existing `spadmic_tdc_axis_wrapper` instances:
  - R axis uses legacy X source bit 0.
  - Y axis uses source bit 1.
  - B axis uses legacy Z source bit 2.
- [IMPLEMENTED] Skew-safe normal START gating is TOP-owned and placed before `spad_event_async_i`. The first accepted event uses stable pre-event resources while later arrivals in the same event use the frozen `event_open/required_tdc_mask` context.
- [IMPLEMENTED] The TOP START gate is one-shot per axis during one physical event. Once the TOP-local synchronized `tdc_start_seen_q[axis]` bit is set, that axis gate is closed until the event ends. This preserves the first R/Y/B arrival edge and prevents repeated MPTDC conversions from matrix lines that remain asserted until selective reset.
- [IMPLEMENTED] `stop_armed_o` from `spadmic_ref_stop_qualifier` is not used as a pre-event resource grant input. Phase 6 top-level TDC-only simulation showed that it asserts in response to START, so using it in the live pre-grant can falsely turn an accepted event into a cleanup-only rejection. It remains a status signal only until a stable wrapper-local `start_accepted`/`stop_available` contract is defined.
- [IMPLEMENTED] `tdc_start_seen_q[2:0]` is derived locally in the top from the gated START levels through `clk_sys` synchronization. This is used only for reset prerequisites and CSR status; it is not a chip pin.
- [IMPLEMENTED] Rejected matrix events now open a bounded cleanup path in `spadmic_event_coordinator`: no normal event ID is allocated, no packet bundle is emitted, but raw snapshot is allowed to trigger selective reset and rearm.
- [IMPLEMENTED] `spadmic_position_snapshot_packetizer` emits a 14-word raw position packet or fixed 8-word cluster packet from the protected matrix snapshot. This makes TDC-only independent of position packetization and gives position-only/BOTH a snapshot consumer without re-detecting async matrix lines.
- [IMPLEMENTED] The packetizer asserts `snapshot_captured_o` after copying the frozen bitmap into private registers. In position-producing modes, `spadmic_event_coordinator` uses this copy confirmation before asserting selective reset, while position-only event ID allocation still occurs from raw snapshot validity.
- [IMPLEMENTED] Noncompact cluster position headers now encode `multi_cluster_mask` in bits `[2:0]`, matching the compact-header multi-mask location. The position VIP reference parser was updated to treat those bits as valid for all cluster headers.
- [DEFAULT FOR V1] Cluster mode uses the existing two-cluster-per-axis scanner with top-local defaults `gap_threshold=2` and `min_cluster_span=1`. Compact cluster packets and a 16-entry position queue remain deferred because the matrix top currently allows one physical event in flight.
- [IMPLEMENTED] `spadmic_event_bundle_tx` is a TOP-owned final bundle path. It waits for `bundle_start`, drains only the latched required source mask, patches all EOC words with the coordinator-owned 14-bit event ID, and uses deterministic source order `R, Y, B, POSITION`.
- [IMPLEMENTED] The legacy `spadmic_correlated_tx` remains unchanged for `spadmic_top_v1`; it is not used by `spadmic_top_matrix_v1` because it increments event IDs per packet and has no bundle barrier.
- [IMPLEMENTED] DDR16 pairer input is now driven from `spadmic_output_fifo`. `spadmic_event_bundle_tx` pushes logical words into the FIFO and its `flush_o` is converted into an ordered FIFO marker so odd final words are padded at the correct bundle boundary before later event words can be paired.
- [IMPLEMENTED] `safe_idle` for the matrix top is mode-aware. It includes event coordinator, snapshot, reset, matrix configuration, active-mode TDC packet state, active-mode position packet state, bundle TX, output FIFO empty state, pending FIFO flush marker state, and DDR16 pairer state. Inactive TDC or position blocks do not block CSR/config acceptance.
- [IMPLEMENTED] Pre-event resource grant now includes output FIFO free-space reservation. `SPADMIC_OUTPUT_FIFO_DEPTH=256`, `SPADMIC_MAX_EVENT_BUNDLE_WORDS=128`, and `SPADMIC_OUTPUT_FIFO_RESERVE_ENTRIES=129` are the implemented physical-planning defaults.
- [IMPLEMENTED] Output FIFO entries are 17 bits in the top integration: 16 logical data bits plus one ordered flush-marker bit. CSR level/free-space status counts FIFO entries, including any pending flush marker.
- [IMPLEMENTED] Normal TDC-only and BOTH mode CSR writes require axis mask `3'b111`. Partial axis masks remain allowed only in calibration mode.
- [IMPLEMENTED] Shared TDC `max_hits` and RO code CSR ownership is now exposed by the matrix-top CSR and wired to all three wrappers.
- [IMPLEMENTED] The matrix-top package/I2C/CSR path now uses the final 16-bit address width. The old top decoder remains outside this target.
- [VERIFIED] TDC-only packet generation through real MPTDC wrappers is covered in the matrix top shell test. BOTH-mode packet generation and the directed R/Y/B skew campaign are covered by the Phase 7 local-regression tests and readiness gate.

## CSR16 And Shared TDC Continuation Decisions

- [IMPLEMENTED] The matrix-top CSR address width is now 16 bits through `SPADMIC_CSR_ADDR_W=16` in `TOP/rtl/spadmic_pkg.sv`.
- [IMPLEMENTED] `I2C/rtl/spadmic_i2c_slave.sv` now preserves the complete 16-bit external pointer high byte. High-region addresses such as `0x7100` are not truncated to a 12-bit alias.
- [IMPLEMENTED] `TOP/rtl/spadmic_matrix_top_csr.sv` decodes the active matrix-top register subset at final 16-bit addresses:
  - `0x0000-0x0030` for ID/version/mode/fault/shared TDC/calibration controls.
  - `0x4000` for the position mode request placeholder.
  - `0x5000-0x5024` for event/snapshot/reset status and snapshots.
  - `0x6000-0x601C` for matrix configuration command/status/data.
  - `0x7000-0x7008` for TX/output status and implemented FIFO status/watermarks.
- [IMPLEMENTED] Unsupported 16-bit addresses return the CSR bad-address error path instead of silently aliasing to implemented low addresses.
- [IMPLEMENTED] Shared `max_hits`, shared slow RO code, shared fast RO code, shared soft-reset pulse, and shared FIFO-clear pulse are exposed by matrix-top CSR and wired to all three `spadmic_tdc_axis_wrapper` instances in `TOP/rtl/spadmic_top_matrix_v1.sv`.
- [DEFAULT FOR V1] `max_hits` resets to 15 and remains programmable through CSR/I2C.
- [DEFAULT FOR V1] Shared RO code `8'h00` is the reset/default clear value. The exact code-frequency transfer function remains unknown; no exact 700 MHz code mapping is claimed.
- [IMPLEMENTED] `CALIB_AXIS_MASK` owns partial-axis selection for calibration mode. Normal `TDC_ONLY` and `BOTH` mode requests still require all three axes.
- [IMPLEMENTED] `POSITION_MODE` is CSR-visible, safe-idle protected, and connected to `spadmic_position_snapshot_packetizer` as raw/cluster select in the matrix-top path.
- [RISK] `TOP/rtl/spadmic_csr_decoder.sv` remains a legacy decoder with old-top assumptions. This is accepted because `TOP/rtl/spadmic_top_v1.sv` is protected and not the matrix-top target.
- [IMPLEMENTED] `OUTPUT_FIFO_STATUS` and `OUTPUT_FIFO_WATERMARKS` report the required 256-entry output FIFO level/free-space/pressure state and reservation constants.
- [IMPLEMENTED] Output FIFO overflow is visible as sticky `MTOP_FAULT[4]`, `TX_STATUS[9]`, and an incrementing saturating counter in `TX_STATUS[31:16]`. `MTOP_FAULT[4]` is W1C.

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
- [IMPLEMENTED] Builder Phase 2 matrix top shell created at `TOP/rtl/spadmic_top_matrix_v1.sv`.
- [IMPLEMENTED] Builder Phase 3 matrix-top CSR/I2C endpoint created at `TOP/rtl/spadmic_matrix_top_csr.sv`.
- [IMPLEMENTED] Builder Phase 2/3 tests created:
  - `TOP/tb/tb_spadmic_matrix_top_csr_unit.sv`
  - `TOP/tb/tb_spadmic_top_matrix_v1_shell_unit.sv`
- [IMPLEMENTED] Builder added mask-aware snapshot coverage to `TOP/tb/tb_spadmic_matrix_snapshot_frontend_unit.sv`.
- [IMPLEMENTED] Builder Phase 2/3 Verilator tests passed before Verifier review.
- [IMPLEMENTED] Verifier Phase 2 review report created at `TOP/docs/reviews/REVIEW_MATRIX_TOP_PHASE2.md`.
- [IMPLEMENTED] Verifier Phase 3 review report created at `TOP/docs/reviews/REVIEW_MATRIX_TOP_PHASE3.md`.
- [VERIFIED] Verifier Phase 2/3 rechecks passed with no remaining BLOCKER, HIGH, MEDIUM, or LOW findings in scope.
- [VERIFIED] Earlier Phase 2/3 local `bash TOP/ci/run_tapeout_readiness.sh` passed with 14 pass, 0 fail, and 4 skipped steps caused by missing `xrun` and retired standalone VIP. The current Phase 7+ gate is recorded below as 33 pass, 0 fail, and 4 expected local skips.
- [IMPLEMENTED] Phase 4 MPTDC, position packet, and final bundle integration are implemented for the new matrix top shell with limitations recorded in `TOP/docs/reviews/REVIEW_MATRIX_TOP_PHASE4.md`.
- [IMPLEMENTED] Phase 5 DDR16 output integration is implemented for the new matrix top shell with limitations recorded in `TOP/docs/reviews/REVIEW_MATRIX_TOP_PHASE5.md`.
- [VERIFIED] Phase 6 local readiness/review closure is recorded in `TOP/docs/reviews/REVIEW_MATRIX_TOP_OUTPUT_FIFO.md`.
- [IMPLEMENTED] Phase 7 local regression expansion is recorded in `TOP/docs/reviews/REVIEW_MATRIX_TOP_LOCAL_REGRESSION.md`.
- [VERIFIED] Builder Phase 7 readiness run passed locally with 33 pass, 0 fail, and 4 expected skips after the continuation fixes.
- [IMPLEMENTED] Verifier continuation findings are recorded in `TOP/docs/reviews/REVIEW_MATRIX_TOP_LOCAL_REGRESSION.md`: missing CSR16 artifact name, narrow skew offsets, and mostly white-box FIFO pressure coverage were fixed before commit.
- [VERIFIED] Verifier continuation recheck approved commit/push for the local open-source scope with no remaining technical BLOCKER, HIGH, MEDIUM, or LOW findings. This is not Xcelium, CDC/RDC, STA, Genus, Innovus, DDR macro, or matrix macro signoff.
- [IMPLEMENTED] Phase 8 server Xcelium run script is prepared at `TOP/ci/server_run_matrix_top_xcelium.sh`. It writes generated results under `/sim/ksabra/SPADMIC_work/xcelium/<RUN_ID>` and fails if `xrun` is missing. Local Codex did not run Xcelium.
- [VERIFIED] Phase 8 Verifier recheck passed after Builder fixed the server `SUMMARY.md` reporting mismatch. No BLOCKER, HIGH, MEDIUM, or LOW findings remain for server-script preparation.
- [IMPLEMENTED] Phase 9 pre-Genus CDC/RDC source review is recorded in `TOP/docs/reviews/REVIEW_MATRIX_TOP_CDC_RDC_PREGENUS.md`. This is a source-based classification only and not CDC/RDC tool signoff.
- [VERIFIED] Phase 9 Verifier recheck found no BLOCKER, HIGH, MEDIUM, or LOW findings for the source-based CDC/RDC/reset review. CDC/RDC tool signoff remains not run.
- [IMPLEMENTED] Phase 10 Genus OOC server infrastructure is prepared under `TOP/syn/`. It is typical-only, writes generated results under `/sim/ksabra/SPADMIC_work/genus/<RUN_ID>/`, and does not claim local Genus execution.
- [VERIFIED] Phase 10 Verifier recheck passed after Builder fixed fatal `check_design`, report redirection, and warning classification issues. Actual Genus execution remains a server gate.
- [IMPLEMENTED] Phase 11 Innovus/floorplan planning infrastructure is prepared under `TOP/pnr/`. The CSV generator uses normalized `ll_*` coordinates and generated server artifacts are kept under `/sim/ksabra/SPADMIC_work/innovus/<RUN_ID>/`.
- [VERIFIED] Phase 11 Verifier recheck passed after Builder fixed the OOC output-root convention. Innovus execution and physical closure remain server gates.
- [IMPLEMENTED] Stack-alignment continuation: TOP server Genus/Innovus wrappers now default to the MPTDC-aligned physical stack: `MPTDC_XH018_STACK=xx31`, `MPTDC_STDCELL_FAMILY=JIHD`, route layers `MET1 MET2 MET3 METTP`, ordinary signal top `MET3`, and `METTP` reserved as the effective top/PG/reviewed-exception layer.
- [IMPLEMENTED] `TOP/syn/scripts/run_genus_matrix_block.tcl` fails early if the sourced matrix-top Genus libraries do not resolve to `xx31/JIHD`.
- [IMPLEMENTED] `TOP/ci/collect_matrix_top_server_snapshot.sh` creates lightweight tracked evidence snapshots under `TOP/docs/server_snapshots/` for server-side Xcelium, Genus, and Innovus runs. Raw tool databases, raw logs, waves, SPEF/SDF, netlists, and tarballs remain excluded.
- [VERIFIED] Stack-alignment policy and snapshot loop are reviewed in `TOP/docs/reviews/REVIEW_MATRIX_TOP_STACK_ALIGNMENT.md`.
- [FAILED REVIEW] Server Xcelium run `xcelium_matrix_top_20260630_0943` at commit `fe8f68712e5e6a3f990c996c3daf2b957613a889` produced 27 pass, 4 fail, 0 missing. The failures were captured in `TOP/docs/server_snapshots/xcelium/xcelium_matrix_top_20260630_0943/`.
- [IMPLEMENTED] Builder fixed Xcelium testbench portability issues from that snapshot: explicit 64-bit timeout delays for long test watchdogs and removal of an extra initial driver on `saw_reset_error`.
- [VERIFIED] Verifier analysis is recorded in `TOP/docs/reviews/REVIEW_MATRIX_TOP_XCELIUM_xcelium_matrix_top_20260630_0943.md`. Local Verilator recheck passed for the four failing tests and full local readiness passed with 33 pass, 0 fail, and 4 expected local skips. A new server Xcelium rerun remains required.
- [VERIFIED] Server Xcelium rerun `xcelium_matrix_top_rerun_20260630_0952` passed all required tests with `XRUN_RC=0`; snapshot committed by the server as `95845a3e`.
- [FAILED REVIEW] First server Genus OOC attempt `genus_matrix_ooc_20260630_0953` failed in the first block because the matrix-top OOC flow read `TOP/rtl/spadmic_ddr_tx.sv`, the obsolete 8-bit dual-edge DDR RTL. Genus rejects the `posedge clk_sys or negedge clk_sys` procedural model. This is a Genus input-selection issue, not a protected MPTDC issue.
- [IMPLEMENTED] Builder updated `TOP/syn/scripts/run_genus_all_matrix_ooc.sh` to generate a Genus-only matrix-top filelist that excludes `TOP/rtl/spadmic_ddr_tx.sv` and `TOP/rtl/spadmic_top_v1.sv` while leaving the shared simulation filelist unchanged.
- [VERIFIED] Server Genus OOC rerun `genus_matrix_ooc_rerun_20260630_1009` passed all 12 configured blocks with `GENUS_RC=0`; snapshot committed by the server as `90004bef`. This is accepted as typical-only OOC feasibility, not final timing closure or MMMC signoff.
- [FAILED REVIEW] Genus rerun review found that the snapshot did not include enough targeted evidence to prove intended async clock groups and had a noisy warning classifier that counted script/library text as design warnings.
- [IMPLEMENTED] Builder tightened `TOP/syn/constraints/matrix_top_ooc_common.sdc`, `TOP/syn/scripts/run_genus_matrix_block.tcl`, and `TOP/ci/collect_matrix_top_server_snapshot.sh` so the next Genus run captures inter-clock timing reports, curated messages, generated-SDC clock-group excerpts, and less noisy warning classifications.
- [VERIFIED] Server Innovus floorplan seed `innovus_matrix_top_fp_20260630_1107` completed with `INNOVUS_RC=0`; snapshot committed by the server as `d6f30ddb`. This validates CSV/LEF planning-seed command compatibility only. No placement, routing, CTS, PG, DRC/LVS, extraction, timing closure, or signoff was run.
- [RISK] The Innovus pin-family review still has one `UNKNOWN` matrix pin on the left side. This must be resolved before final top-chip floorplan constraints and pad-level integration.
- [VERIFIED] Server Genus evidence run `genus_matrix_ooc_evidence_20260630_1117` passed all 12 configured blocks with `GENUS_RC=0`; snapshot committed by the server as `49cf7f35`. This confirms the matrix-top OOC flow remains green after the evidence-capture changes.
- [FAILED REVIEW] Genus evidence run `genus_matrix_ooc_evidence_20260630_1117` still captured a `TUI-204` message because `report_exceptions` is not supported in this Genus build. Builder removed that report command after review.
- [IMPLEMENTED] Builder added explicit `report_timing -unconstrained` inter-clock reports and generated-SDC clock-group excerpts for the next Genus evidence snapshot.
- [IMPLEMENTED] Builder refined Genus warning classification again so headings such as `No unresolved references` and `Max_transition design rule: no violations` are not counted as findings.
- [VERIFIED] Server Innovus floorplan seed `innovus_matrix_top_fp_evidence_20260630_1214` completed with `INNOVUS_RC=0`; snapshot committed by the server as `3603455e`. This ties the seed evidence to the latest pushed branch state.
- [VERIFIED] The one previously `UNKNOWN` matrix pin is `VTUNE`, marked `INOUT/ANALOG/LEFT` in the CSV at normalized coordinate approximately `(1.93, 61.725)`. It is analog-owned and must be handled as a keepout/ownership item, not as a missing R/Y/B/Rz/Yz/Bz/Din/Cin/Dout/Cout digital pin.
- [RISK] Next Innovus milestone must be a real design import/floorplan feasibility run. Current Innovus runs are seed-only and do not prove placement, route, CTS, PG, extraction, DRC/LVS, or timing.
- [VERIFIED] Server Genus clean run `genus_matrix_ooc_clean_20260630_1222` passed all 12 configured OOC blocks with `GENUS_RC=0` at run commit `50e488e7044f9a991c0605601bd1f1f1110d4760`; snapshot committed as `94c8b014`. This is accepted as typical-only OOC feasibility, not signoff.
- [FAILED REVIEW] The same clean Genus snapshot still contains one `TUI-204` tool error per block and false-positive `undriven` classifications caused by evidence-flow commands, not by RTL failure. Review is recorded in `TOP/docs/reviews/REVIEW_MATRIX_TOP_GENUS_OOC_genus_matrix_ooc_clean_20260630_1222.md`.
- [IMPLEMENTED] Builder updated `TOP/syn/scripts/run_genus_matrix_block.tcl` to avoid unsupported Genus 22.13 report/SDF options, generate `report_area_hierarchy.rpt` using the compatible default `report_area` format, move `report_messages` after output collateral generation, and suppress `No undriven ...` false positives.
- [IMPLEMENTED] Builder updated `TOP/ci/collect_matrix_top_server_snapshot.sh` so future snapshots include `report_area_hierarchy.rpt` and distinguish source-run branch/commit from snapshot-collection branch/commit.
- [NOT IMPLEMENTED] A final clean Genus evidence snapshot after these script fixes still needs to be run on the server.
- [IMPLEMENTED] Builder added staged matrix-top Innovus planning infrastructure:
  - `TOP/pnr/inputs/matrix_top_pad_policy_template.csv`
  - `TOP/pnr/scripts/gen_matrix_top_floorplan_plan.py`
  - `TOP/pnr/scripts/server_run_innovus_matrix_top_staged_floorplan.sh`
  - `TOP/pnr/templates/matrix_top_staged_floorplan.tcl`
  - updated `TOP/pnr/scripts/server_run_innovus_matrix_ooc.sh`
- [VERIFIED] Local Verifier smoke confirms the locked first geometry reports `STATUS=FAIL` with `MPTDC_VERTICAL_STACK_EXCEEDS_CORE_HEIGHT`, about `109 um` height excess, and about `0.839 mm^2` maximum MPTDC placeholder area per axis if the vertical stack must fit with current die/core assumptions.
- [RISK] The staged Innovus OOC wrapper validates Genus collateral and creates per-block run directories but does not yet run real Innovus import/place/preCTS. This is intentional until the clean Genus evidence and top geometry gates are resolved.
- [VERIFIED] Server Genus staged run `genus_matrix_ooc_staged_20260630_1516` passed all 12 configured OOC blocks with `GENUS_RC=0` at source commit `195b6d1bf87c16042294c8e3d411b50d989f541a`. This remains typical-only OOC feasibility, not MMMC or final timing signoff.
- [HISTORICAL] Server staged floorplan run `innovus_matrix_top_staged_fp_20260630_1628` correctly stopped before Innovus with `FP_RC=5`, `STATUS=FAIL`, and `MPTDC_VERTICAL_STACK_EXCEEDS_CORE_HEIGHT`. The old default 1.0 mm2, 4:3-aspect three-axis MPTDC vertical stack was 109.038 um too tall for the obsolete 3800 um x 2700 um abstract die with 120 um pad/core keepout.
- [SUPERSEDED] The earlier 1.0 mm2, aspect-ratio-1.8 candidate is no longer the active planning case. It is replaced by the full-boundary Scenario B reservation in the real top envelope.
- [VERIFIED] Server OOC collateral gate `innovus_matrix_ooc_gate_20260630_1628` returned `OOC_RC=4`, `READY_FOR_NEXT_IMPORT_TEMPLATE`, with all 10 connectivity-first block netlists and SDCs present. At that time DDR16 was excluded by default; this is now superseded by the updated north SLVS/DDR16 contract.
- [IMPLEMENTED] Builder fixed a warning-classifier false positive where the `Multidriven Port(s)/Pin(s)` report heading was counted as an undriven/multidriven finding even when detailed Genus text said no such issue.
- [FROZEN] New TOP Genus/Innovus OOC runs include `ddr16_pairer` and `ddrs2_adapter` by default because the north DDRs2 macro boundary is part of the staged top contract. The TX path is scheduled last because it is lower priority than reset/OR64/snapshot/config/event/FIFO/CSR/I2C physical readiness. Full `spadmic_top_matrix_v1` remains excluded by default; DDR16/DDRs2 may be excluded only for narrow debug reruns.
- [FROZEN] Clock mux reset default selects PLL 160 MHz. PLL lock/status is CSR-only for v1; there is no external lock pin.
- [FROZEN] Matrix-side physical implementation proceeds block by block, not by full-top Genus/Innovus. Matrix, MPTDC protected internals, DDRs2, TXRX4TDC, PLL, pad ring, PTAT, and analog macros remain black boxes. The first OOC hardening target is `spadmic_matrix_reset_ctrl`; matrix-adjacent OR/snapshot/boundary flops remain soft or region-guided until real congestion or routing evidence says otherwise.
- [IMPLEMENTED] Builder added `TOP/docs/26_MATRIX_SIDE_SUBBLOCK_PNR_PLAN.md`, `TOP/docs/27_MATRIX_INTERFACE_PIN_GUIDE_PLAN.md`, `TOP/docs/28_SUBBLOCK_ABSTRACT_HANDOFF_PLAN.md`, single-block Genus/Innovus OOC wrappers, and initial per-block OOC filelist/SDC manifests.
- [VERIFIED] Server step-1 block run for `matrix_reset_ctrl` used commit `017de251a41765f188ccf179554ff03c2abe0195`. Xcelium `tb_spadmic_matrix_reset_ctrl_unit` passed with `15 pass / 0 fail`; Genus run `genus_ooc_matrix_reset_ctrl_20260708_1424` passed one block with `tool_error=0`, `unresolved=0`, `inferred_latch=0`, total area `27971.248 um^2`, and worst shown relaxed setup slack `+2494 ps`; Innovus OOC gate `innovus_ooc_matrix_reset_ctrl_20260708_1426` reported `READY_FOR_NEXT_IMPORT_TEMPLATE` with `PNR_RC=0`. This remains non-signoff OOC collateral, not routed Innovus implementation.
- [VERIFIED] Server step-2 block run for `matrix_cfg_ctrl` used commit `017de251a41765f188ccf179554ff03c2abe0195`. Xcelium `tb_spadmic_matrix_cfg_ctrl_unit` and `tb_spadmic_matrix_cfg_cout_readback_unit` passed with `TB_CFG_RC=0` and `TB_COUT_RC=0`; Genus run `genus_ooc_matrix_cfg_ctrl_20260708_1432` passed one block with `tool_error=0`, `unresolved=0`, `inferred_latch=0`, total area `105053.740 um^2`, and worst shown relaxed setup slack `+3490 ps`; Innovus OOC gate `innovus_ooc_matrix_cfg_ctrl_20260708_1436` reported `READY_FOR_NEXT_IMPORT_TEMPLATE` with `PNR_RC=0`. The `no_clock_waveform count=89` warning is accepted only as a documented OOC/CDC item for the `matrix_cout_i[43:0]` pulse-capture samplers; this is not CDC signoff, final STA signoff, or routed Innovus implementation.
- [VERIFIED] Server step-3 block run for `position_snapshot` used commit `017de251a41765f188ccf179554ff03c2abe0195`. Xcelium `tb_spadmic_position_snapshot_packetizer_unit`, `tb_spadmic_position_snapshot_cluster_unit`, and `tb_spadmic_position_modes_unit` passed with `TB_POS_PKT_RC=0`, `TB_POS_CLUSTER_RC=0`, and `TB_POS_MODES_RC=0`; Genus run `genus_ooc_position_snapshot_20260708_1441` passed one block with `tool_error=0`, `unresolved=0`, `inferred_latch=0`, `no_clock_waveform=0`, total area `287769.971 um^2`, and worst shown relaxed setup slack `+7 ps`; Innovus OOC gate `innovus_ooc_position_snapshot_20260708_1455` reported `READY_FOR_NEXT_IMPORT_TEMPLATE` with `PNR_RC=0`. This is accepted as non-signoff OOC collateral, but the cluster-scan critical path is a timing risk before hardening or final physical readiness.
- [VERIFIED] Server step-4 block run for `event_coordinator` used commit `017de251a41765f188ccf179554ff03c2abe0195`. Xcelium `tb_spadmic_event_coordinator_modes_unit` passed with `24 pass / 0 fail` and `TB_EVT_RC=0`; Genus run `genus_ooc_event_coordinator_20260708_1506` passed one block with `tool_error=0`, `unresolved=0`, `inferred_latch=0`, `no_clock_waveform=0`, total area `7429.939 um^2`, and worst shown relaxed setup slack `+1969 ps`; Innovus OOC gate `innovus_ooc_event_coordinator_20260708_1510` reported `READY_FOR_NEXT_IMPORT_TEMPLATE` with `PNR_RC=0`. This remains non-signoff OOC collateral, not routed Innovus implementation.
- [VERIFIED] Server step-5 block run for `event_bundle_tx` used commit `017de251a41765f188ccf179554ff03c2abe0195`. Xcelium `tb_spadmic_event_bundle_tx_unit` passed with `14 pass / 0 fail` and `TB_BUNDLE_RC=0`; Genus run `genus_ooc_event_bundle_tx_20260708_1529` passed one block with `tool_error=0`, `unresolved=0`, `inferred_latch=0`, `no_clock_waveform=0`, total area `6277.819 um^2`, and worst shown relaxed setup slack `+2799 ps`; Innovus OOC gate `innovus_ooc_event_bundle_tx_20260708_1531` reported `READY_FOR_NEXT_IMPORT_TEMPLATE` with `PNR_RC=0`. This remains non-signoff OOC collateral, not routed Innovus implementation.
- [IMPLEMENTED] The `output_fifo` OOC target now uses `spadmic_output_fifo_topcfg`, a wrapper around `spadmic_output_fifo`, to match the matrix-top physical configuration: 17-bit entries, 256-entry depth, 129-entry reservation, and `SPADMIC_OUTPUT_FIFO_LEVEL_W` status width. Raw `spadmic_output_fifo` defaults are not the valid matrix-top OOC handoff.
- [VERIFIED] Server step-6 block run for `output_fifo` used commit `eccd432b9801f8781c16ef5fa7494eded08ff77c` for Xcelium/Genus and commit `412e14a65cccef1b3a44d41074e21c099df3d133` for the follow-up OOC collateral gate. Xcelium `tb_spadmic_output_fifo_unit` and `tb_spadmic_output_fifo_ddr_marker_unit` passed with `TB_FIFO_RC=0` and `TB_FIFO_MARKER_RC=0`; Genus run `genus_ooc_output_fifo_20260709_0653` passed one block with top module `spadmic_output_fifo_topcfg`, `tool_error=0`, `unresolved=0`, `inferred_latch=0`, `no_clock_waveform=0`, total area `459392.568 um^2`, and worst shown relaxed setup slack `+542 ps`; Innovus OOC gate `innovus_ooc_output_fifo_20260709_0700` reported `READY_FOR_NEXT_IMPORT_TEMPLATE` with `PNR_RC=0`. This remains non-signoff OOC collateral, not routed Innovus implementation.

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

Phase 2/3 RTL files:

- `TOP/rtl/spadmic_matrix_top_csr.sv`
- `TOP/rtl/spadmic_top_matrix_v1.sv`
- `TOP/rtl/spadmic_pkg.sv`
- `TOP/filelist.f`

Phase 2/3 tests:

- `TOP/tb/tb_spadmic_matrix_top_csr_unit.sv`
- `TOP/tb/tb_spadmic_top_matrix_v1_shell_unit.sv`

Phase 2/3 review reports:

- `TOP/docs/reviews/REVIEW_MATRIX_TOP_PHASE2.md`
- `TOP/docs/reviews/REVIEW_MATRIX_TOP_PHASE3.md`

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
