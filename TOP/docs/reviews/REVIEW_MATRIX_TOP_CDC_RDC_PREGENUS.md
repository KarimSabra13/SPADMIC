# Review Matrix Top CDC/RDC Pre-Genus

Status: Verifier signed off for source-based pre-Genus review scope. This is
not CDC/RDC tool signoff.

## Metadata

- Branch: `SPADMIC_test`
- Base commit: `446751dc`
- Phase: 9, CDC/RDC/reset pre-Genus review
- Date: `2026-06-28`
- Scope: source-based CDC/RDC classification before Genus OOC and before any
  Cadence CDC/RDC tool run.

## Files Reviewed

- `TOP/rtl/spadmic_top_matrix_v1.sv`
- `TOP/rtl/spadmic_matrix_cfg_ctrl.sv`
- `TOP/rtl/spadmic_matrix_snapshot_frontend.sv`
- `TOP/rtl/spadmic_matrix_reset_ctrl.sv`
- `TOP/rtl/spadmic_ddr16_tx_pairer.sv`
- `I2C/rtl/spadmic_i2c_slave.sv`
- `I2C/rtl/spadmic_i2c_csr_bridge.sv`
- MPTDC wrapper boundary only; protected MPTDC internals were not edited.

## Crossing Table

| Crossing | Source Domain | Destination Domain | Signals | RTL Structure | Expected Constraint / Review | Verification / Test | Risk | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Async matrix event to MPTDC START | Matrix analog async | MPTDC START async frontend | `R_i/Y_i/B_i` through per-axis OR64 to `tdc_start_async_to_core` | `spadmic_top_matrix_v1` keeps three independent start gates; no shared synchronizer before MPTDC | Do not hide under broad false path only. Classify as intentional async timing path, report OR64 datapath delay/slew/skew per axis, preserve per-axis hierarchy/grouping | `tb_spadmic_top_matrix_v1_skew_campaign` verifies all six arrival orders reach later START gates after first axis starts | High physical sensitivity; functional sim does not prove extracted skew | REVIEW REQUIRED |
| Async matrix event to snapshot | Matrix analog async | `clk_sys` | `R_i/Y_i/B_i` | `spadmic_matrix_snapshot_frontend` uses three-stage `ASYNC_REG` arrays before settle/snapshot | CDC tool should recognize synchronizer arrays; preserve/cluster flops; do not time as normal synchronous inputs | Snapshot unit tests and top event/reset tests | Medium metastability risk accepted for prototype; needs CDC waiver/attribute check | STRUCTURED, NOT SIGNED OFF |
| START seen confirmation | START gate async-ish pulse | `clk_sys` | `tdc_start_async_to_core[2:0]` to `tdc_start_seen_q` | Two clk_sys flops then sticky OR while `event_open` | CDC review required because this observes the TOP start gate, not MPTDC internal acceptance; no MPTDC core change | Skew campaign checks sticky start seen behavior indirectly and reset prerequisites | May miss very narrow pulses if pulse width violates clk_sys sampling; current top gates originate from matrix level-held lines, so acceptable under matrix-held-until-reset assumption | STRUCTURED, ASSUMPTION |
| CSR command to matrix config | `clk_sys` | `clk_cfg_40m` | command op, column, wdata, `cmd_req_tgl_sys` | Stable command hold registers plus synchronized request toggle in `spadmic_matrix_cfg_ctrl` | CDC tool should verify stable-bus/toggle protocol; no independent multi-bit bus synchronizers | `tb_spadmic_matrix_cfg_ctrl_unit`, reset-during-cfg test | Low if busy/hold protocol is preserved; must not allow overwrite while busy | STRUCTURED |
| Matrix config return to CSR | `clk_cfg_40m` | `clk_sys` | done toggle, error, last_error, readback, valid | Return-hold registers plus synchronized done toggle; clk_sys samples after toggle | CDC tool should verify return bus is stable until observed; add assertion/waiver if tool cannot infer | Matrix config unit and Cout readback tests | Medium; return bus is multi-bit and depends on hold protocol | STRUCTURED, TOOL REVIEW |
| Cout returned edge to Dout capture | Matrix returned `Cout` edge | local Cout sampler then `clk_cfg_40m` | `matrix_cout_i[43:0]`, `matrix_dout_i[43:0]` | `spadmic_matrix_cout_bit_sampler` captures `Dout` on `posedge Cout` when armed, toggles capture flag; cfg domain synchronizes toggle and data | Treat Cout as returned/generated asynchronous clock or strobe. Needs CDC/RDC tool review, generated-clock/clock-group decision, recovery/removal check on reset, and macro timing handoff | `tb_spadmic_matrix_cfg_cout_readback_unit`, broader config unit timeout tests | High until macro timing is available; data sampled by returned edge can be tool-sensitive | REVIEW REQUIRED |
| I2C pins to control plane | Off-chip I2C async | `clk_sys` | `i2c_scl_i`, `i2c_sda_i` | Existing I2C slave samples pins in `clk_sys` and emits one outstanding CSR transaction | CDC review should classify I2C inputs; no clock stretching; 100 kHz timing | I2C control and matrix-top 16-bit tests | Medium; local tests are functional, not board timing | STRUCTURED, TOOL REVIEW |
| Global async reset to sys | `async_rst_n` | `clk_sys` reset tree | `rst_sys_n` | `mptdc_reset_sync` instantiated in top | RDC recovery/removal review; asynchronous assertion, synchronized release | reset-during-event, shell/unit tests | Low if synchronizer preserved; high fanout implementation needs synthesis handling | STRUCTURED |
| Global async reset to cfg | `async_rst_n` | `clk_cfg_40m` reset tree | `rst_cfg_n` | `mptdc_reset_sync` instantiated in top | RDC review independent from sys reset; no common unsafe deassertion | reset-during-matrix-cfg test | Low if synchronizer preserved | STRUCTURED |
| Global async reset into MPTDC wrappers | `async_rst_n` / `rst_sys_n` policy | MPTDC local domains | wrapper reset/control | Existing wrapper/core boundary retained; MPTDC internals protected | Use existing MPTDC CDC/RDC collateral as source of truth; do not add high-fanout reconstructed reset inside MPTDC | Existing wrapper/top local tests only | Medium; protected handoff remains separate | DEFER TO MPTDC HANDOFF |
| `clk_ref_40m` stop qualifier | `clk_ref_40m` | MPTDC STOP path | per-axis STOP qualifier | Existing `spadmic_ref_stop_qualifier` and wrappers | Treat as separate clock/reference; preserve MPTDC timing assumptions | Existing stop qualifier tests | Medium; final relation to clk_sys is not assumed | STRUCTURED, TOOL REVIEW |
| DDR16 macro boundary | `clk_sys` | future DDR analog macro | `ddr_data_l_o/h_o`, `ddr_pair_valid_o`, `ddr_clk_o` | Single-edge pairer outputs; no dual-edge procedural final logic | Placeholder output constraints only until macro timing; no board timing claim | DDR16 pairer and output FIFO marker tests | Medium; final macro contract still provisional | PLACEHOLDER |
| Reset-select outputs | `clk_sys` | matrix macro async/electrical | `Rz_o/Yz_o/Bz_o` | Registered active-high masks inverted to active-low outputs | Output delay/load/slew placeholders; place final regs/buffers near matrix pins; no bit-clear verification | reset controller tests, reset-during-event test | Medium physical skew/current risk; macro timing TBD | PLACEHOLDER |
| Matrix config physical outputs | `clk_cfg_40m` | matrix macro | `matrix_din_o`, `matrix_cin_o` | Registered cfg-domain outputs; no combinational clock gating | Macro setup/hold/min high/min low/Dout-Cout delay still TBD; classify non-signoff | config controller tests | High until macro handoff | PLACEHOLDER |

## Reset-Domain Findings

- `rst_sys_n` and `rst_cfg_n` are separately synchronized from `async_rst_n`.
- Matrix reset-select outputs are forced inactive high by clearing active-high
  masks under reset.
- Matrix configuration outputs are cleared in `rst_cfg_n`; reset abort clears
  readback and `matrix_cfg_valid`.
- The current review does not replace a recovery/removal report from a real
  RDC tool.

## STA / Constraint Intent

- `clk_sys`: 6.25 ns.
- `clk_cfg_40m`: 25 ns, separate from `clk_sys` until the final PLL relationship
  and constraints prove otherwise.
- `clk_ref_40m`: 25 ns, separate stop-qualifier reference for MPTDC wrapper
  paths.
- `Cout` must be classified explicitly as returned strobe/clock before Genus or
  CDC signoff. Do not silently treat it as ordinary data.
- R/Y/B START tree paths require datapath-delay/slew/skew reports and physical
  grouping, not only broad false paths.
- DDR16 and matrix macro I/O constraints are placeholders until macro handoff.

## Required Follow-Up Before Genus Signoff Claims

1. Run a real CDC/RDC tool on the new matrix-top hierarchy.
2. Review every CDC waiver against the table above.
3. Confirm `ASYNC_REG` preservation on snapshot synchronizers and reset
   synchronizers.
4. Classify `Cout` formally with the matrix macro designer and STA owner.
5. Add generated-clock or asynchronous-clock constraints only after the PLL and
   macro timing contracts are known.
6. Produce START-tree path reports after synthesis/PnR with no broad blanket
   false-path hiding.

## Verifier Status

Verifier found no BLOCKER, HIGH, MEDIUM, or LOW findings. The review covers the
required crossing list, keeps `clk_cfg_40m` separate from `clk_sys`, flags the
returned `Cout` sampler as high-risk/tool-review required, and does not claim
CDC/RDC or STA signoff.
