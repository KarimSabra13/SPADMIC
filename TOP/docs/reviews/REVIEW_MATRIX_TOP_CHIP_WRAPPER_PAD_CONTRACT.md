# Review: Matrix TOP Chip Wrapper And Pad Contract

Status: implementation review for the staged matrix-top wrapper/pad contract.
This is not full-chip signoff, not routed top assembly, and not a final
pad-ring netlist.

## Scope Reviewed

- Active digital core remains `TOP/rtl/spadmic_top_matrix_v1.sv`.
- Added I2C pad reset input `i2c_rst_i`, corresponding to pad `i2c_RST`.
- Added PLL/clock wrapper CSR boundary:
  - `pll_fint_sel_o[7:0]`
  - `pll_ro_sw_o[4:0]`
  - `pll_sel_pulse_pfd_o`
  - `pll_enable_div_o`
  - `pll_sel_40m_o`
  - `clk_160m_ext_select_o`
  - `pll_lock_i` status input
- Added CSR addresses:
  - `SPADMIC_CSR_PLL_CTRL = 16'h0034`
  - `SPADMIC_CSR_PLL_STATUS = 16'h0038`
- Updated staged Genus/Innovus scripts so `ddr16_pairer` is included by
  default as its own block, while full `spadmic_top_matrix_v1` remains excluded
  unless explicitly requested.
- Updated pad policy and floorplan planning documentation for:
  - one external 160 MHz clock pad only;
  - no independent external 40 MHz clock pads;
  - north-row DDR16/SLVS data drivers plus forwarded clock and valid drivers;
  - six calibration pads retained;
  - PLL external pad inputs retained outside the digital core;
  - MPTDC full-boundary planning scenario.

## Design Intent Checks

- `i2c_RST` resets only the I2C transport path:
  - `spadmic_i2c_slave`
  - `spadmic_i2c_csr_bridge`
- `i2c_RST` does not reset the full CSR image, acquisition state, FIFO,
  DDR16 pairer, matrix configuration engine, or MPTDC paths.
- PLL reset default selects the internal PLL 160 MHz source:
  - `clk_160m_ext_select_o = 0`
  - `pll_enable_div_o = 1`
- CSR may switch to external 160 MHz source later through `PLL_CTRL[16]`.
- `PLL_STATUS` is CSR-visible only; no external PLL lock pad is added here.
- Matrix R/Y/B, Rz/Yz/Bz, Din/Cin/Dout/Cout stay internal macro connections.
- MPTDC internals are not modified.

## Local Verification

The following local Verilator checks passed:

```text
bash TOP/scripts/sim/run_tb.sh tb_spadmic_matrix_top_csr_unit --sim verilator
bash TOP/scripts/sim/run_tb.sh tb_spadmic_matrix_top_csr_16b_unit --sim verilator
bash TOP/scripts/sim/run_tb.sh tb_spadmic_i2c_matrix_top_16b_unit --sim verilator
bash TOP/scripts/sim/run_tb.sh tb_spadmic_ddr16_tx_pairer_unit --sim verilator
bash TOP/scripts/sim/run_tb.sh tb_spadmic_top_matrix_v1_shell_unit --sim verilator
bash TOP/scripts/sim/run_tb.sh tb_spadmic_top_output_pressure_unit --sim verilator
bash TOP/scripts/sim/run_tb.sh tb_spadmic_top_output_fifo_pressure_integration_unit --sim verilator
bash TOP/scripts/sim/run_tb.sh tb_spadmic_top_mode_transition_unit --sim verilator
```

Static/script checks passed locally:

```text
bash -n TOP/syn/scripts/run_genus_all_matrix_ooc.sh
bash -n TOP/pnr/scripts/server_run_innovus_matrix_ooc.sh
bash -n TOP/pnr/scripts/server_run_innovus_matrix_top_staged_floorplan.sh
python3 -m py_compile TOP/pnr/scripts/gen_matrix_top_floorplan_plan.py
python3 TOP/pnr/scripts/gen_matrix_top_floorplan_plan.py --out /tmp/spadmic_chip_wrapper_plan_check --run-id local_chip_wrapper_plan_check
git diff --check
```

The local floorplan generator probe reports Scenario B as `PASS` in the active
die envelope while recording the normalized BOX_RING hint separately.

## Residual Risks

- Local machine has no Xcelium, Genus, or Innovus evidence for this patch.
- The final pad-ring wrapper is still future work and must instantiate:
  - the active digital core;
  - PLL macro;
  - matrix macro;
  - SLVS/DDR data, clock, and valid drivers;
  - pads and BOX_RING assembly.
- The layout coordinate-frame difference remains explicit:
  - active generator envelope: `4293.179 um x 3209.173 um`;
  - normalized layout hint: about `X=3200 um`, `Y=3700 um`.
  A parseable BOX_RING export should resolve this before final floorplan freeze.
- The PLL clock mux/divider wrapper RTL is not implemented in this patch; only
  the core CSR/control boundary is exposed and documented.
- Per-block Innovus import/place/preCTS scripts still need a reviewed template
  before physical runs beyond collateral gating.

## Recommendation

Proceed to server-side Xcelium smoke, then Genus OOC by sub-block with DDR16
included by default. Do not launch full-top Genus or full top Innovus until the
pad-ring wrapper and BOX_RING/blockage import are reviewed.
