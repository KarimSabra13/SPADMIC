# Matrix TOP Handoff Connectivity - Readable View

This file is generated from `26_MATRIX_TOP_HANDOFF_CONNECTIVITY.csv`.
Use the CSV as the machine-readable source of truth and this Markdown file
for review in a text editor, GitHub, or an email attachment.

Regenerate with:

```bash
python3 TOP/docs/render_matrix_top_handoff_connectivity.py
```

## Quick Index

| Section | Block | Module(s) | Kind(s) | Rows | Main Action |
| --- | --- | --- | --- | ---: | --- |
| 00 - Metadata and Source Context | run_context | - | document | 1 | copy_to_handoff |
| 00 - Metadata and Source Context | active_top | spadmic_top_matrix_v1 | top_wrapper | 1 | instantiate_inside_pad_wrapper |
| 00 - Metadata and Source Context | mptdc_boundary | mptdc_axis_core | macro | 1 | use_axis_core_macro_plus_wrapper |
| 00 - Metadata and Source Context | tdc3_frontend_handoff | spadmic_tdc3_frontend | handoff | 1 | instantiate_glue_netlist |
| 00 - Metadata and Source Context | missing_top_items | - | top_wrapper | 1 | needs_external_macro |
| 01 - Digital Top Core Boundary | spadmic_top_matrix_v1 | spadmic_top_matrix_v1 | top_wrapper | 35 | connect_from_clock_wrapper |
| 02 - Pads, PLL, Clock Wrapper, and Macro Boundary | clock_wrapper | external_clock_mux_divider | top_wrapper | 6 | route_to_pad |
| 02 - Pads, PLL, Clock Wrapper, and Macro Boundary | PLL | PLL | macro | 11 | route_to_macro |
| 03 - Reset Glue | reset_sync | mptdc_reset_sync | glue_rtl | 9 | instantiate |
| 04 - Genus Handoff Blocks | i2c_slave | spadmic_i2c_slave | handoff | 14 | connect_direct |
| 04 - Genus Handoff Blocks | i2c_csr_bridge | spadmic_i2c_csr_bridge | handoff | 20 | connect_direct |
| 04 - Genus Handoff Blocks | matrix_top_csr | spadmic_matrix_top_csr | handoff | 79 | connect_direct |
| 04 - Genus Handoff Blocks | or64_tree | spadmic_matrix_or_tree | handoff | 6 | connect_direct |
| 04 - Genus Handoff Blocks | matrix_reset_ctrl | spadmic_matrix_reset_ctrl | handoff | 14 | connect_direct |
| 04 - Genus Handoff Blocks | event_coordinator | spadmic_event_coordinator | handoff | 30 | connect_direct |
| 04 - Genus Handoff Blocks | tdc3_frontend | spadmic_tdc3_frontend | handoff | 26 | connect_direct |
| 04 - Genus Handoff Blocks | position_snapshot | spadmic_position_snapshot_packetizer | handoff | 20 | connect_direct |
| 04 - Genus Handoff Blocks | event_bundle_tx | spadmic_event_bundle_tx | handoff | 20 | connect_direct |
| 04 - Genus Handoff Blocks | output_fifo | spadmic_output_fifo | handoff | 14 | connect_direct |
| 04 - Genus Handoff Blocks | matrix_cfg_ctrl | spadmic_matrix_cfg_ctrl | handoff | 19 | connect_direct |
| 04 - Genus Handoff Blocks | ddr16_pairer | spadmic_ddr16_tx_pairer | handoff | 13 | connect_direct |
| 05 - Glue RTL Detail | snapshot_frontend | spadmic_matrix_snapshot_frontend | glue_rtl | 19 | instantiate |
| 05 - Glue RTL Detail | tdc_axis_wrapper | spadmic_tdc_axis_wrapper | glue_rtl | 26 | instantiate |
| 06 - MPTDC Macro Black-Box Contract | mptdc_axis_core | mptdc_axis_core | macro | 23 | instantiate_macro |

## 00 - Metadata and Source Context

### run_context (kind: `document`)

| Block | Module | Source / Signal | Target / Location | Action | Notes | Source File |
| --- | --- | --- | --- | --- | --- | --- |
| run_context | - | genus_matrix_handoff_20260703_1102 | /sim/ksabra/SPADMIC_work/handoff/genus | copy_to_handoff | CSV describes connectivity needed in addition to postsyn V and SDC | TOP/docs/26_MATRIX_TOP_HANDOFF_CONNECTIVITY.csv |

### active_top (module: `spadmic_top_matrix_v1`; kind: `top_wrapper`)

| Block | Module | Source / Signal | Target / Location | Action | Notes | Source File |
| --- | --- | --- | --- | --- | --- | --- |
| active_top | spadmic_top_matrix_v1 | TOP/rtl/spadmic_top_matrix_v1.sv | - | instantiate_inside_pad_wrapper | Digital matrix top core is not final pad ring wrapper | TOP/rtl/spadmic_top_matrix_v1.sv |

### mptdc_boundary (module: `mptdc_axis_core`; kind: `macro`)

| Block | Module | Source / Signal | Target / Location | Action | Notes | Source File |
| --- | --- | --- | --- | --- | --- | --- |
| mptdc_boundary | mptdc_axis_core | MPTDC_TC_Closure_Genus_RO6_xx31_20260629_1233 | mptdc_axis_core | use_axis_core_macro_plus_wrapper | Use mptdc_axis_core as physical macro and keep spadmic_tdc_axis_wrapper as required glue | MPTDC/rtl/top/mptdc_axis_core.sv |

### tdc3_frontend_handoff (module: `spadmic_tdc3_frontend`; kind: `handoff`)

| Block | Module | Source / Signal | Target / Location | Action | Notes | Source File |
| --- | --- | --- | --- | --- | --- | --- |
| tdc3_frontend_handoff | spadmic_tdc3_frontend | TOP/syn/scripts/run_genus_tdc3_frontend_handoff.sh | /sim/ksabra/SPADMIC_work/handoff/genus/tdc3_frontend | instantiate_glue_netlist | Synthesized glue around three MPTDC axis macros with black-box mptdc_axis_core | TOP/rtl/spadmic_tdc3_frontend.sv |

### missing_top_items (kind: `top_wrapper`)

| Block | Module | Source / Signal | Target / Location | Action | Notes | Source File |
| --- | --- | --- | --- | --- | --- | --- |
| missing_top_items | - | clock_wrapper PLL matrice3 SLVS BOX_RING pads | top_assembly | needs_external_macro | These are not provided by per block postsyn netlists | TOP/docs/24_MATRIX_TOP_CHIP_WRAPPER_PAD_CONTRACT.md |

## 01 - Digital Top Core Boundary

### spadmic_top_matrix_v1 (module: `spadmic_top_matrix_v1`; kind: `top_wrapper`)

| Port | Dir | Width | Clock | Reset | From | To | Pad/Macro | Action | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| clk_sys | input | 1 | clk_sys | - | clock_wrapper_clk_sys | spadmic_top_matrix_v1.u_digital_core.clk_sys | clock_wrapper | connect_from_clock_wrapper | Main digital clock from PLL or external 160M selection logic |
| clk_ref_40m | input | 1 | clk_ref_40m | - | clock_wrapper_clk_ref_40m | spadmic_top_matrix_v1.u_digital_core.clk_ref_40m | clock_wrapper | connect_from_clock_wrapper | Derived 40M reference for MPTDC stop qualifier |
| clk_cfg_40m | input | 1 | clk_cfg_40m | - | clock_wrapper_clk_cfg_40m | spadmic_top_matrix_v1.u_digital_core.clk_cfg_40m | clock_wrapper | connect_from_clock_wrapper | Derived 40M matrix configuration clock |
| async_rst_n | input | 1 | async | async_rst_n | async_rst_n_pad | spadmic_top_matrix_v1.u_digital_core.async_rst_n | async_rst_n | route_to_pad | Global active low reset pad |
| i2c_rst_i | input | 1 | async | rst_i2c_n | i2c_RST_pad | spadmic_top_matrix_v1.u_digital_core.i2c_rst_i | i2c_RST | route_to_pad | Active high reset for I2C transport only |
| i2c_scl_i | input | 1 | async | rst_i2c_n | i2c_scl_i_pad | i2c_slave.u_i2c_slave.i2c_scl_i | i2c_scl_i | route_to_pad | I2C SCL pad into synchronized slave |
| i2c_sda_i | input | 1 | async | rst_i2c_n | i2c_sda_i_pad | i2c_slave.u_i2c_slave.i2c_sda_i | i2c_sda_i | route_to_pad | I2C SDA input side |
| i2c_sda_oe_o | output | 1 | clk_sys | rst_i2c_n | i2c_sda_oe_o | i2c_pad.u_i2c_sda_pad.oe_i | i2c_sda_oe_o | route_to_pad | Open drain enable drives SDA low when asserted |
| pll_lock_i | input | 1 | clk_sys | rst_sys_n | pll_lock | spadmic_top_matrix_v1.u_digital_core.pll_lock_i | PLL | route_from_macro | CSR visible PLL lock status only |
| pll_fint_sel_o | output | 8 | clk_sys | rst_sys_n | pll_fint_sel_o | PLL.u_pll.SelA_to_SelH_Fint | PLL | route_to_macro | CSR SelA_Fint through SelH_Fint |
| pll_ro_sw_o | output | 5 | clk_sys | rst_sys_n | pll_ro_sw_o | PLL.u_pll.Sw0_to_Sw4_RO | PLL | route_to_macro | Canonical name matches RTL and pad policy |
| pll_sel_pulse_pfd_o | output | 1 | clk_sys | rst_sys_n | pll_sel_pulse_pfd_o | PLL.u_pll.sel_pulsePFD | PLL | route_to_macro | CSR PLL control |
| pll_enable_div_o | output | 1 | clk_sys | rst_sys_n | pll_enable_div_o | PLL.u_pll.Enable_Div | PLL | route_to_macro | CSR divider enable reset default is enabled |
| pll_sel_40m_o | output | 1 | clk_sys | rst_sys_n | pll_sel_40m_o | PLL.u_pll.Sel_40M | PLL | route_to_macro | CSR PLL 40M selection |
| clk_160m_ext_select_o | output | 1 | clk_sys | rst_sys_n | clk_160m_ext_select_o | clock_wrapper.u_clock_wrapper.select_ext_160m | clock_wrapper | add_mux_divider | Select external 160M versus PLL 160M |
| R_i | input | 64 | async | rst_sys_n | R_bus | spadmic_top_matrix_v1.u_digital_core.R_i | matrice3 | route_from_macro | Matrix R event bus not external pad |
| Y_i | input | 64 | async | rst_sys_n | Y_bus | spadmic_top_matrix_v1.u_digital_core.Y_i | matrice3 | route_from_macro | Matrix Y event bus not external pad |
| B_i | input | 64 | async | rst_sys_n | B_bus | spadmic_top_matrix_v1.u_digital_core.B_i | matrice3 | route_from_macro | Matrix B event bus not external pad |
| Rz_o | output | 64 | clk_sys | rst_sys_n | Rz_o | matrice3.u_matrice3.Rz | matrice3 | route_to_macro | Selective matrix reset bus |
| Yz_o | output | 64 | clk_sys | rst_sys_n | Yz_o | matrice3.u_matrice3.Yz | matrice3 | route_to_macro | Selective matrix reset bus |
| Bz_o | output | 64 | clk_sys | rst_sys_n | Bz_o | matrice3.u_matrice3.Bz | matrice3 | route_to_macro | Selective matrix reset bus |
| matrix_din_o | output | 44 | clk_cfg_40m | rst_cfg_n | matrix_din_o | matrice3.u_matrice3.Din | matrice3 | route_to_macro | Matrix column configuration data |
| matrix_cin_o | output | 44 | clk_cfg_40m | rst_cfg_n | matrix_cin_o | matrice3.u_matrice3.Cin | matrice3 | route_to_macro | Matrix column configuration clock or strobe |
| matrix_dout_i | input | 44 | clk_cfg_40m | rst_cfg_n | matrix_dout_i | spadmic_top_matrix_v1.u_digital_core.matrix_dout_i | matrice3 | route_from_macro | Matrix readback data |
| matrix_cout_i | input | 44 | clk_cfg_40m | rst_cfg_n | matrix_cout_i | spadmic_top_matrix_v1.u_digital_core.matrix_cout_i | matrice3 | route_from_macro | Matrix readback strobe or output clock |
| cal_r_start_async_i | input | 1 | async | async_rst_n | cal_r_start_async_i | u_tdc_r.u_tdc_r.cal_start_async_i | cal_r_start_async_i | route_to_pad | External calibration START R axis |
| cal_r_stop_async_i | input | 1 | async | async_rst_n | cal_r_stop_async_i | u_tdc_r.u_tdc_r.cal_stop_async_i | cal_r_stop_async_i | route_to_pad | External calibration STOP R axis |
| cal_y_start_async_i | input | 1 | async | async_rst_n | cal_y_start_async_i | u_tdc_y.u_tdc_y.cal_start_async_i | cal_y_start_async_i | route_to_pad | External calibration START Y axis |
| cal_y_stop_async_i | input | 1 | async | async_rst_n | cal_y_stop_async_i | u_tdc_y.u_tdc_y.cal_stop_async_i | cal_y_stop_async_i | route_to_pad | External calibration STOP Y axis |
| cal_b_start_async_i | input | 1 | async | async_rst_n | cal_b_start_async_i | u_tdc_b.u_tdc_b.cal_start_async_i | cal_b_start_async_i | route_to_pad | External calibration START B axis |
| cal_b_stop_async_i | input | 1 | async | async_rst_n | cal_b_stop_async_i | u_tdc_b.u_tdc_b.cal_stop_async_i | cal_b_stop_async_i | route_to_pad | External calibration STOP B axis |
| ddr_data_l_o | output | 16 | clk_sys | rst_sys_n | ddr_data_l_o | SLVS_DATA.u_slvs_data_0_to_15.data_l_i | DATA[15:0] | route_to_driver | Sixteen north row data SLVS drivers low phase |
| ddr_data_h_o | output | 16 | clk_sys | rst_sys_n | ddr_data_h_o | SLVS_DATA.u_slvs_data_0_to_15.data_h_i | DATA[15:0] | route_to_driver | Sixteen north row data SLVS drivers high phase |
| ddr_pair_valid_o | output | 1 | clk_sys | rst_sys_n | ddr_pair_valid_o | SLVS_VALID.u_slvs_valid.data_i | DATA_VALID | route_to_driver | Dedicated north row valid driver |
| ddr_clk_o | output | 1 | clk_sys | rst_sys_n | ddr_clk_o | SLVS_CLK.u_slvs_clk.data_i | DATA_CLK | route_to_driver | Dedicated forwarded clock driver |

## 02 - Pads, PLL, Clock Wrapper, and Macro Boundary

### clock_wrapper (module: `external_clock_mux_divider`; kind: `top_wrapper`)

| Port | Dir | Width | Clock | Reset | From | To | Pad/Macro | Action | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| clk_160m_ext_i | input | 1 | 160m | - | clk_160m_ext_i_pad | clock_wrapper.u_clock_wrapper.clk_160m_ext_i | clk_160m_ext_i | route_to_pad | Only external clock pad in v1 |
| pll_clk_160m_i | input | 1 | 160m | - | pll_clk_160m | clock_wrapper.u_clock_wrapper.pll_clk_160m_i | PLL | route_from_macro | Default clock source after reset |
| select_ext_160m_i | input | 1 | clk_sys | rst_sys_n | clk_160m_ext_select_o | clock_wrapper.u_clock_wrapper.select_ext_160m_i | spadmic_top_matrix_v1 | connect_direct | CSR selects external 160M when asserted |
| clk_sys_o | output | 1 | clk_sys | - | clock_wrapper_clk_sys | spadmic_top_matrix_v1.u_digital_core.clk_sys | clock_wrapper | connect_direct | Distribution point chosen during physical floorplan |
| clk_cfg_40m_o | output | 1 | clk_cfg_40m | - | clock_wrapper_clk_cfg_40m | spadmic_top_matrix_v1.u_digital_core.clk_cfg_40m | clock_wrapper | add_mux_divider | Derived from selected 160M source or PLL 40M |
| clk_ref_40m_o | output | 1 | clk_ref_40m | - | clock_wrapper_clk_ref_40m | spadmic_top_matrix_v1.u_digital_core.clk_ref_40m | clock_wrapper | add_mux_divider | No independent external 40M pad |

### PLL (module: `PLL`; kind: `macro`)

| Port | Dir | Width | Clock | Reset | From | To | Pad/Macro | Action | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| SelA_to_SelH_Fint | input | 8 | analog | macro_reset | pll_fint_sel_o | PLL.u_pll.SelA_to_SelH_Fint | PLL | route_to_macro | CSR controlled PLL bits |
| Sw0_to_Sw4_RO | input | 5 | analog | macro_reset | pll_ro_sw_o | PLL.u_pll.Sw0_to_Sw4_RO | PLL | route_to_macro | CSR controlled RO switches |
| sel_pulsePFD | input | 1 | analog | macro_reset | pll_sel_pulse_pfd_o | PLL.u_pll.sel_pulsePFD | PLL | route_to_macro | CSR controlled PLL bit |
| Enable_Div | input | 1 | analog | macro_reset | pll_enable_div_o | PLL.u_pll.Enable_Div | PLL | route_to_macro | CSR controlled divider enable |
| Sel_40M | input | 1 | analog | macro_reset | pll_sel_40m_o | PLL.u_pll.Sel_40M | PLL | route_to_macro | CSR controlled 40M selection |
| lock_o | output | 1 | clk_sys | macro_reset | pll_lock | spadmic_top_matrix_v1.u_digital_core.pll_lock_i | PLL | route_from_macro | PLL lock is CSR visible only |
| Ibi_KVCO | input | 1 | analog | macro_reset | pll_Ibi_KVCO_i_pad | PLL.u_pll.Ibi_KVCO | pll_Ibi_KVCO_i | route_to_pad | External PLL control pad direct to PLL |
| Icp | input | 1 | analog | macro_reset | pll_Icp_i_pad | PLL.u_pll.Icp | pll_Icp_i | route_to_pad | External PLL control pad direct to PLL |
| Ref_in_pll_ro | input | 1 | analog | macro_reset | pll_Ref_in_pll_ro_i_pad | PLL.u_pll.Ref_in_pll_ro | pll_Ref_in_pll_ro_i | route_to_pad | External PLL reference or RO pad direct to PLL |
| Rst_Div | input | 1 | analog | macro_reset | pll_Rst_Div_i_pad | PLL.u_pll.Rst_Div | pll_Rst_Div_i | route_to_pad | External PLL divider reset |
| Rst_CP | input | 1 | analog | macro_reset | pll_Rst_CP_i_pad | PLL.u_pll.Rst_CP | pll_Rst_CP_i | route_to_pad | External PLL charge pump reset |

## 03 - Reset Glue

### reset_sync (module: `mptdc_reset_sync`; kind: `glue_rtl`)

| Port | Dir | Width | Clock | Reset | From | To | Pad/Macro | Action | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| clk | input | 1 | clk_sys | - | clk_sys | mptdc_reset_sync.u_rst_sys_sync.clk | clock_wrapper | instantiate | Generated rst_sys_n for clk_sys domain |
| async_rst_n | input | 1 | async | async_rst_n | async_rst_n_pad | mptdc_reset_sync.u_rst_sys_sync.async_rst_n | async_rst_n | instantiate | Global reset synchronizer |
| rst_n_o | output | 1 | clk_sys | rst_sys_n | rst_sys_n | all_clk_sys_blocks.all.rst_n | internal | connect_direct | Common active low synchronous reset for clk_sys blocks |
| clk | input | 1 | clk_cfg_40m | - | clk_cfg_40m | mptdc_reset_sync.u_rst_cfg_sync.clk | clock_wrapper | instantiate | Generated rst_cfg_n for matrix cfg clock domain |
| async_rst_n | input | 1 | async | async_rst_n | async_rst_n_pad | mptdc_reset_sync.u_rst_cfg_sync.async_rst_n | async_rst_n | instantiate | Global reset synchronizer |
| rst_n_o | output | 1 | clk_cfg_40m | rst_cfg_n | rst_cfg_n | matrix_cfg_ctrl.u_matrix_cfg.rst_cfg_n | internal | connect_direct | Active low reset for cfg domain |
| clk | input | 1 | clk_sys | - | clk_sys | mptdc_reset_sync.u_rst_i2c_sync.clk | clock_wrapper | instantiate | I2C transport reset sync in clk_sys domain |
| async_rst_n | input | 1 | async | i2c_async_rst_n | i2c_async_rst_n | mptdc_reset_sync.u_rst_i2c_sync.async_rst_n | internal | connect_direct | i2c_async_rst_n equals async_rst_n and not i2c_rst_i |
| rst_n_o | output | 1 | clk_sys | rst_i2c_n | rst_i2c_n | i2c_slave_and_bridge.u_i2c_slave/u_i2c_bridge.rst_n | internal | connect_direct | Only resets I2C transport blocks |

## 04 - Genus Handoff Blocks

### i2c_slave (module: `spadmic_i2c_slave`; kind: `handoff`)

| Port | Dir | Width | Clock | Reset | From | To | Pad/Macro | Action | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| clk_sys | input | 1 | clk_sys | rst_i2c_n | clk_sys | i2c_slave.u_i2c_slave.clk_sys | clock_wrapper | connect_direct | I2C FSM sampled in clk_sys domain |
| rst_n | input | 1 | clk_sys | rst_i2c_n | rst_i2c_n | i2c_slave.u_i2c_slave.rst_n | internal | connect_direct | I2C transport reset only |
| i2c_scl_i | input | 1 | async | rst_i2c_n | i2c_scl_i_pad | i2c_slave.u_i2c_slave.i2c_scl_i | i2c_scl_i | route_to_pad | External SCL pad |
| i2c_sda_i | input | 1 | async | rst_i2c_n | i2c_sda_i_pad | i2c_slave.u_i2c_slave.i2c_sda_i | i2c_sda_i | route_to_pad | External SDA input |
| i2c_sda_oe_o | output | 1 | clk_sys | rst_i2c_n | i2c_sda_oe_o | i2c_pad.u_i2c_sda_pad.oe_i | i2c_sda_oe_o | route_to_pad | Open drain output enable |
| txn_valid_o | output | 1 | clk_sys | rst_i2c_n | i2c_cmd_valid | i2c_csr_bridge.u_i2c_bridge.i2c_cmd_valid_i | internal | connect_direct | I2C transaction request valid |
| txn_write_o | output | 1 | clk_sys | rst_i2c_n | i2c_cmd_write | i2c_csr_bridge.u_i2c_bridge.i2c_cmd_write_i | internal | connect_direct | I2C transaction write flag |
| txn_addr_o | output | SPADMIC_CSR_ADDR_W | clk_sys | rst_i2c_n | i2c_cmd_addr | i2c_csr_bridge.u_i2c_bridge.i2c_cmd_addr_i | internal | connect_direct | CSR address from I2C |
| txn_wdata_o | output | SPADMIC_CSR_DATA_W | clk_sys | rst_i2c_n | i2c_cmd_wdata | i2c_csr_bridge.u_i2c_bridge.i2c_cmd_wdata_i | internal | connect_direct | CSR write data from I2C |
| txn_ready_i | input | 1 | clk_sys | rst_i2c_n | i2c_cmd_ready | i2c_slave.u_i2c_slave.txn_ready_i | internal | connect_direct | Bridge ready to accept transaction |
| txn_rsp_valid_i | input | 1 | clk_sys | rst_i2c_n | i2c_rsp_valid | i2c_slave.u_i2c_slave.txn_rsp_valid_i | internal | connect_direct | Bridge response valid |
| txn_rsp_rdata_i | input | SPADMIC_CSR_DATA_W | clk_sys | rst_i2c_n | i2c_rsp_rdata | i2c_slave.u_i2c_slave.txn_rsp_rdata_i | internal | connect_direct | Bridge read response data |
| txn_rsp_err_i | input | 1 | clk_sys | rst_i2c_n | i2c_rsp_err | i2c_slave.u_i2c_slave.txn_rsp_err_i | internal | connect_direct | Bridge response error |
| txn_rsp_ready_o | output | 1 | clk_sys | rst_i2c_n | i2c_rsp_ready | i2c_csr_bridge.u_i2c_bridge.i2c_rsp_ready_i | internal | connect_direct | I2C ready for response |

### i2c_csr_bridge (module: `spadmic_i2c_csr_bridge`; kind: `handoff`)

| Port | Dir | Width | Clock | Reset | From | To | Pad/Macro | Action | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| clk_sys | input | 1 | clk_sys | rst_i2c_n | clk_sys | i2c_csr_bridge.u_i2c_bridge.clk_sys | clock_wrapper | connect_direct | CSR bridge clock |
| rst_n | input | 1 | clk_sys | rst_i2c_n | rst_i2c_n | i2c_csr_bridge.u_i2c_bridge.rst_n | internal | connect_direct | I2C transport reset |
| i2c_cmd_valid_i | input | 1 | clk_sys | rst_i2c_n | i2c_cmd_valid | i2c_csr_bridge.u_i2c_bridge.i2c_cmd_valid_i | internal | connect_direct | From I2C slave txn_valid_o |
| i2c_cmd_write_i | input | 1 | clk_sys | rst_i2c_n | i2c_cmd_write | i2c_csr_bridge.u_i2c_bridge.i2c_cmd_write_i | internal | connect_direct | From I2C slave txn_write_o |
| i2c_cmd_addr_i | input | SPADMIC_CSR_ADDR_W | clk_sys | rst_i2c_n | i2c_cmd_addr | i2c_csr_bridge.u_i2c_bridge.i2c_cmd_addr_i | internal | connect_direct | From I2C slave txn_addr_o |
| i2c_cmd_wdata_i | input | SPADMIC_CSR_DATA_W | clk_sys | rst_i2c_n | i2c_cmd_wdata | i2c_csr_bridge.u_i2c_bridge.i2c_cmd_wdata_i | internal | connect_direct | From I2C slave txn_wdata_o |
| i2c_cmd_ready_o | output | 1 | clk_sys | rst_i2c_n | i2c_cmd_ready | i2c_slave.u_i2c_slave.txn_ready_i | internal | connect_direct | Ready to I2C slave |
| i2c_rsp_valid_o | output | 1 | clk_sys | rst_i2c_n | i2c_rsp_valid | i2c_slave.u_i2c_slave.txn_rsp_valid_i | internal | connect_direct | Response valid to I2C slave |
| i2c_rsp_rdata_o | output | SPADMIC_CSR_DATA_W | clk_sys | rst_i2c_n | i2c_rsp_rdata | i2c_slave.u_i2c_slave.txn_rsp_rdata_i | internal | connect_direct | Read data to I2C slave |
| i2c_rsp_err_o | output | 1 | clk_sys | rst_i2c_n | i2c_rsp_err | i2c_slave.u_i2c_slave.txn_rsp_err_i | internal | connect_direct | Response error to I2C slave |
| i2c_rsp_ready_i | input | 1 | clk_sys | rst_i2c_n | i2c_rsp_ready | i2c_csr_bridge.u_i2c_bridge.i2c_rsp_ready_i | internal | connect_direct | Response ready from I2C slave |
| csr_req_valid_o | output | 1 | clk_sys | rst_i2c_n | csr_req_valid | matrix_top_csr.u_matrix_top_csr.csr_valid_i | internal | connect_direct | CSR request valid |
| csr_req_write_o | output | 1 | clk_sys | rst_i2c_n | csr_req_write | matrix_top_csr.u_matrix_top_csr.csr_write_i | internal | connect_direct | CSR write flag |
| csr_req_addr_o | output | SPADMIC_CSR_ADDR_W | clk_sys | rst_i2c_n | csr_req_addr | matrix_top_csr.u_matrix_top_csr.csr_addr_i | internal | connect_direct | CSR address |
| csr_req_wdata_o | output | SPADMIC_CSR_DATA_W | clk_sys | rst_i2c_n | csr_req_wdata | matrix_top_csr.u_matrix_top_csr.csr_wdata_i | internal | connect_direct | CSR write data |
| csr_req_ready_i | input | 1 | clk_sys | rst_i2c_n | csr_req_ready | i2c_csr_bridge.u_i2c_bridge.csr_req_ready_i | internal | connect_direct | CSR endpoint ready |
| csr_rsp_valid_i | input | 1 | clk_sys | rst_i2c_n | csr_rsp_valid | i2c_csr_bridge.u_i2c_bridge.csr_rsp_valid_i | internal | connect_direct | CSR response valid |
| csr_rsp_rdata_i | input | SPADMIC_CSR_DATA_W | clk_sys | rst_i2c_n | csr_rsp_rdata | i2c_csr_bridge.u_i2c_bridge.csr_rsp_rdata_i | internal | connect_direct | CSR response data |
| csr_rsp_err_i | input | 1 | clk_sys | rst_i2c_n | csr_rsp_err | i2c_csr_bridge.u_i2c_bridge.csr_rsp_err_i | internal | connect_direct | CSR response error |
| csr_rsp_ready_o | output | 1 | clk_sys | rst_i2c_n | csr_rsp_ready | matrix_top_csr.u_matrix_top_csr.csr_rsp_ready_i | internal | connect_direct | CSR response ready |

### matrix_top_csr (module: `spadmic_matrix_top_csr`; kind: `handoff`)

| Port | Dir | Width | Clock | Reset | From | To | Pad/Macro | Action | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| clk_sys | input | 1 | clk_sys | rst_sys_n | clk_sys | matrix_top_csr.u_matrix_top_csr.clk_sys | clock_wrapper | connect_direct | Main CSR endpoint clock |
| rst_n | input | 1 | clk_sys | rst_sys_n | rst_sys_n | matrix_top_csr.u_matrix_top_csr.rst_n | internal | connect_direct | Global clk_sys reset |
| csr_valid_i | input | 1 | clk_sys | rst_sys_n | csr_req_valid | matrix_top_csr.u_matrix_top_csr.csr_valid_i | internal | connect_direct | From I2C CSR bridge |
| csr_write_i | input | 1 | clk_sys | rst_sys_n | csr_req_write | matrix_top_csr.u_matrix_top_csr.csr_write_i | internal | connect_direct | From I2C CSR bridge |
| csr_addr_i | input | SPADMIC_CSR_ADDR_W | clk_sys | rst_sys_n | csr_req_addr | matrix_top_csr.u_matrix_top_csr.csr_addr_i | internal | connect_direct | From I2C CSR bridge |
| csr_wdata_i | input | SPADMIC_CSR_DATA_W | clk_sys | rst_sys_n | csr_req_wdata | matrix_top_csr.u_matrix_top_csr.csr_wdata_i | internal | connect_direct | From I2C CSR bridge |
| csr_ready_o | output | 1 | clk_sys | rst_sys_n | csr_req_ready | i2c_csr_bridge.u_i2c_bridge.csr_req_ready_i | internal | connect_direct | Ready to CSR bridge |
| csr_rvalid_o | output | 1 | clk_sys | rst_sys_n | csr_rsp_valid | i2c_csr_bridge.u_i2c_bridge.csr_rsp_valid_i | internal | connect_direct | Response valid to CSR bridge |
| csr_rdata_o | output | SPADMIC_CSR_DATA_W | clk_sys | rst_sys_n | csr_rsp_rdata | i2c_csr_bridge.u_i2c_bridge.csr_rsp_rdata_i | internal | connect_direct | Response data to CSR bridge |
| csr_err_o | output | 1 | clk_sys | rst_sys_n | csr_rsp_err | i2c_csr_bridge.u_i2c_bridge.csr_rsp_err_i | internal | connect_direct | Response error to CSR bridge |
| safe_idle_i | input | 1 | clk_sys | rst_sys_n | safe_idle | matrix_top_csr.u_matrix_top_csr.safe_idle_i | internal | connect_direct | Composite safe idle from top glue |
| transition_busy_i | input | 1 | clk_sys | rst_sys_n | 1'b0 | matrix_top_csr.u_matrix_top_csr.transition_busy_i | internal | tie_constant | No separate transition sequencer in active top |
| event_busy_i | input | 1 | clk_sys | rst_sys_n | event_busy | matrix_top_csr.u_matrix_top_csr.event_busy_i | internal | connect_direct | Event coordinator busy status |
| event_id_i | input | 14 | clk_sys | rst_sys_n | event_id | matrix_top_csr.u_matrix_top_csr.event_id_i | internal | connect_direct | Current event ID |
| required_packet_mask_i | input | 4 | clk_sys | rst_sys_n | required_packet_mask | matrix_top_csr.u_matrix_top_csr.required_packet_mask_i | internal | connect_direct | Current required packet mask |
| completed_packet_mask_i | input | 4 | clk_sys | rst_sys_n | completed_packet_status_mask | matrix_top_csr.u_matrix_top_csr.completed_packet_mask_i | internal | connect_direct | Pending or completed packet status |
| required_reset_ack_mask_i | input | 4 | clk_sys | rst_sys_n | required_reset_ack_mask | matrix_top_csr.u_matrix_top_csr.required_reset_ack_mask_i | internal | connect_direct | Reset or start acknowledgement mask |
| observed_reset_ack_mask_i | input | 4 | clk_sys | rst_sys_n | observed_reset_ack_mask | matrix_top_csr.u_matrix_top_csr.observed_reset_ack_mask_i | internal | connect_direct | Observed reset or start acknowledgements |
| event_rejected_not_ready_i | input | 1 | clk_sys | rst_sys_n | event_rejected_not_ready | matrix_top_csr.u_matrix_top_csr.event_rejected_not_ready_i | internal | connect_direct | Event rejected status |
| snapshot_valid_i | input | 1 | clk_sys | rst_sys_n | snapshot_valid | matrix_top_csr.u_matrix_top_csr.snapshot_valid_i | internal | connect_direct | Snapshot status from frontend |
| snapshot_busy_i | input | 1 | clk_sys | rst_sys_n | snapshot_busy | matrix_top_csr.u_matrix_top_csr.snapshot_busy_i | internal | connect_direct | Snapshot frontend busy |
| snapshot_timeout_i | input | 1 | clk_sys | rst_sys_n | snapshot_timeout | matrix_top_csr.u_matrix_top_csr.snapshot_timeout_i | internal | connect_direct | Snapshot timeout status |
| snapshot_overlap_i | input | 1 | clk_sys | rst_sys_n | snapshot_overlap | matrix_top_csr.u_matrix_top_csr.snapshot_overlap_i | internal | connect_direct | Snapshot overlap status |
| snapshot_reject_i | input | 1 | clk_sys | rst_sys_n | snapshot_reject | matrix_top_csr.u_matrix_top_csr.snapshot_reject_i | internal | connect_direct | Snapshot rejected status |
| snapshot_rearm_ready_i | input | 1 | clk_sys | rst_sys_n | snapshot_rearm_ready | matrix_top_csr.u_matrix_top_csr.snapshot_rearm_ready_i | internal | connect_direct | Snapshot ready for next event |
| snapshot_R_i | input | 64 | clk_sys | rst_sys_n | snapshot_R | matrix_top_csr.u_matrix_top_csr.snapshot_R_i | internal | connect_direct | Captured matrix R snapshot |
| snapshot_Y_i | input | 64 | clk_sys | rst_sys_n | snapshot_Y | matrix_top_csr.u_matrix_top_csr.snapshot_Y_i | internal | connect_direct | Captured matrix Y snapshot |
| snapshot_B_i | input | 64 | clk_sys | rst_sys_n | snapshot_B | matrix_top_csr.u_matrix_top_csr.snapshot_B_i | internal | connect_direct | Captured matrix B snapshot |
| reset_busy_i | input | 1 | clk_sys | rst_sys_n | reset_busy | matrix_top_csr.u_matrix_top_csr.reset_busy_i | internal | connect_direct | Matrix reset busy |
| reset_done_i | input | 1 | clk_sys | rst_sys_n | reset_done | matrix_top_csr.u_matrix_top_csr.reset_done_i | internal | connect_direct | Matrix reset done pulse |
| reset_disabled_i | input | 1 | clk_sys | rst_sys_n | reset_disabled | matrix_top_csr.u_matrix_top_csr.reset_disabled_i | internal | connect_direct | Auto reset disabled status |
| matrix_cfg_busy_i | input | 1 | clk_sys | rst_sys_n | matrix_cfg_busy | matrix_top_csr.u_matrix_top_csr.matrix_cfg_busy_i | internal | connect_direct | Matrix config busy |
| matrix_cfg_done_i | input | 1 | clk_sys | rst_sys_n | matrix_cfg_done | matrix_top_csr.u_matrix_top_csr.matrix_cfg_done_i | internal | connect_direct | Matrix config done |
| matrix_cfg_error_i | input | 1 | clk_sys | rst_sys_n | matrix_cfg_error | matrix_top_csr.u_matrix_top_csr.matrix_cfg_error_i | internal | connect_direct | Matrix config error |
| matrix_cfg_last_error_i | input | 4 | clk_sys | rst_sys_n | matrix_cfg_last_error | matrix_top_csr.u_matrix_top_csr.matrix_cfg_last_error_i | internal | connect_direct | Matrix config last error code |
| matrix_cfg_rdata_i | input | 64 | clk_sys | rst_sys_n | matrix_cfg_rdata | matrix_top_csr.u_matrix_top_csr.matrix_cfg_rdata_i | internal | connect_direct | Matrix config readback data |
| matrix_cfg_readback_valid_i | input | 1 | clk_sys | rst_sys_n | matrix_cfg_readback_valid | matrix_top_csr.u_matrix_top_csr.matrix_cfg_readback_valid_i | internal | connect_direct | Matrix config readback valid |
| matrix_cfg_valid_i | input | 1 | clk_sys | rst_sys_n | matrix_cfg_valid | matrix_top_csr.u_matrix_top_csr.matrix_cfg_valid_i | internal | connect_direct | Matrix config output valid |
| ddr_empty_i | input | 1 | clk_sys | rst_sys_n | ddr_empty | matrix_top_csr.u_matrix_top_csr.ddr_empty_i | internal | connect_direct | DDR pairer empty |
| ddr_busy_i | input | 1 | clk_sys | rst_sys_n | ddr_busy | matrix_top_csr.u_matrix_top_csr.ddr_busy_i | internal | connect_direct | DDR pairer busy |
| ddr_pair_valid_i | input | 1 | clk_sys | rst_sys_n | ddr_pair_valid_o | matrix_top_csr.u_matrix_top_csr.ddr_pair_valid_i | internal | connect_direct | DDR pair valid output mirrored into CSR |
| ddr_padded_i | input | 1 | clk_sys | rst_sys_n | ddr_padded | matrix_top_csr.u_matrix_top_csr.ddr_padded_i | internal | connect_direct | DDR padded flush status |
| output_fifo_level_i | input | SPADMIC_OUTPUT_FIFO_LEVEL_W | clk_sys | rst_sys_n | output_fifo_level | matrix_top_csr.u_matrix_top_csr.output_fifo_level_i | internal | connect_direct | FIFO level status |
| output_fifo_free_words_i | input | SPADMIC_OUTPUT_FIFO_LEVEL_W | clk_sys | rst_sys_n | output_fifo_free_words | matrix_top_csr.u_matrix_top_csr.output_fifo_free_words_i | internal | connect_direct | FIFO free words status |
| output_fifo_empty_i | input | 1 | clk_sys | rst_sys_n | output_fifo_empty | matrix_top_csr.u_matrix_top_csr.output_fifo_empty_i | internal | connect_direct | FIFO empty status |
| output_fifo_full_i | input | 1 | clk_sys | rst_sys_n | output_fifo_full | matrix_top_csr.u_matrix_top_csr.output_fifo_full_i | internal | connect_direct | FIFO full status |
| output_fifo_almost_full_i | input | 1 | clk_sys | rst_sys_n | output_fifo_almost_full | matrix_top_csr.u_matrix_top_csr.output_fifo_almost_full_i | internal | connect_direct | FIFO almost full status |
| output_fifo_overflow_i | input | 1 | clk_sys | rst_sys_n | output_fifo_overflow | matrix_top_csr.u_matrix_top_csr.output_fifo_overflow_i | internal | connect_direct | FIFO overflow status |
| bundle_missing_source_i | input | 1 | clk_sys | rst_sys_n | bundle_missing_source_error | matrix_top_csr.u_matrix_top_csr.bundle_missing_source_i | internal | connect_direct | Bundle TX missing source error |
| position_packet_drop_i | input | 1 | clk_sys | rst_sys_n | pos_packet_drop | matrix_top_csr.u_matrix_top_csr.position_packet_drop_i | internal | connect_direct | Position packet drop status |
| pll_lock_i | input | 1 | clk_sys | rst_sys_n | pll_lock_i | matrix_top_csr.u_matrix_top_csr.pll_lock_i | PLL | route_from_macro | PLL lock status |
| global_enable_o | output | 1 | clk_sys | rst_sys_n | global_enable | event_coordinator_and_tdc.fanout.global_enable_i | internal | connect_direct | Global enable fanout |
| requested_mode_o | output | spadmic_operating_mode_e | clk_sys | rst_sys_n | requested_mode | top_status.unused_phase2_inputs.requested_mode | internal | connect_direct | Requested mode consumed only for status glue in active top |
| active_mode_o | output | spadmic_operating_mode_e | clk_sys | rst_sys_n | active_mode | event_coordinator.fanout.active_mode_i | internal | connect_direct | Active operating mode |
| requested_axis_mask_o | output | 3 | clk_sys | rst_sys_n | requested_axis_mask | top_status.unused_phase2_inputs.requested_axis_mask | internal | connect_direct | Requested axis mask consumed only for status glue in active top |
| active_axis_mask_o | output | 3 | clk_sys | rst_sys_n | active_axis_mask | event_coordinator_and_tdc.fanout.active_axis_mask_i | internal | connect_direct | Active axis enable mask R Y B map to bits 0 1 2 |
| auto_reset_enable_o | output | 1 | clk_sys | rst_sys_n | auto_reset_enable | event_coordinator_and_reset.fanout.auto_reset_enable_i | internal | connect_direct | Enables matrix reset controller |
| settle_cycles_o | output | 16 | clk_sys | rst_sys_n | settle_cycles | snapshot_frontend.u_snapshot.settle_cycles_i | internal | connect_direct | Snapshot settle cycles |
| watchdog_cycles_o | output | 16 | clk_sys | rst_sys_n | watchdog_cycles | snapshot_frontend.u_snapshot.watchdog_cycles_i | internal | connect_direct | Snapshot watchdog cycles |
| reset_width_o | output | 16 | clk_sys | rst_sys_n | reset_width | matrix_reset_ctrl.u_matrix_reset.reset_width_i | internal | connect_direct | Matrix reset pulse width |
| snapshot_clear_o | output | 1 | clk_sys | rst_sys_n | snapshot_clear_csr | snapshot_frontend.u_snapshot.clear_i | internal | connect_direct | CSR snapshot clear ORed with reset_done |
| tdc_max_hits_o | output | MAX_HITS_W | clk_sys | rst_sys_n | shared_tdc_max_hits | tdc_axis_wrappers.u_tdc_r/u_tdc_y/u_tdc_b.max_hits_i | internal | connect_direct | Shared MPTDC max hits |
| tdc_ro_slow_code_o | output | 8 | clk_sys | rst_sys_n | shared_tdc_ro_slow_code | tdc_axis_wrappers.u_tdc_r/u_tdc_y/u_tdc_b.ro_slow_code_i | internal | connect_direct | Shared MPTDC slow RO code |
| tdc_ro_fast_code_o | output | 8 | clk_sys | rst_sys_n | shared_tdc_ro_fast_code | tdc_axis_wrappers.u_tdc_r/u_tdc_y/u_tdc_b.ro_fast_code_i | internal | connect_direct | Shared MPTDC fast RO code |
| tdc_soft_reset_o | output | 1 | clk_sys | rst_sys_n | shared_tdc_soft_reset | tdc_axis_wrappers.u_tdc_r/u_tdc_y/u_tdc_b.soft_reset_i | internal | connect_direct | Shared MPTDC soft reset |
| tdc_fifo_clr_o | output | 1 | clk_sys | rst_sys_n | shared_tdc_fifo_clr | tdc_axis_wrappers.u_tdc_r/u_tdc_y/u_tdc_b.fifo_clr_i | internal | connect_direct | Shared MPTDC FIFO clear |
| calib_axis_mask_o | output | 3 | clk_sys | rst_sys_n | calib_axis_mask | top_status.unused_phase2_inputs.calib_axis_mask | internal | connect_direct | Calibration axis mask status glue currently consumes it |
| position_mode_o | output | spadmic_pos_mode_e | clk_sys | rst_sys_n | position_mode | position_snapshot.u_pos_packetizer.mode_i | internal | connect_direct | Position packet mode |
| pll_fint_sel_o | output | 8 | clk_sys | rst_sys_n | pll_fint_sel_o | PLL.u_pll.SelA_to_SelH_Fint | PLL | route_to_macro | PLL CSR outputs |
| pll_ro_sw_o | output | 5 | clk_sys | rst_sys_n | pll_ro_sw_o | PLL.u_pll.Sw0_to_Sw4_RO | PLL | route_to_macro | Canonical PLL RO switch output name |
| pll_sel_pulse_pfd_o | output | 1 | clk_sys | rst_sys_n | pll_sel_pulse_pfd_o | PLL.u_pll.sel_pulsePFD | PLL | route_to_macro | PLL CSR output |
| pll_enable_div_o | output | 1 | clk_sys | rst_sys_n | pll_enable_div_o | PLL.u_pll.Enable_Div | PLL | route_to_macro | PLL CSR output |
| pll_sel_40m_o | output | 1 | clk_sys | rst_sys_n | pll_sel_40m_o | PLL.u_pll.Sel_40M | PLL | route_to_macro | PLL CSR output |
| clk_160m_ext_select_o | output | 1 | clk_sys | rst_sys_n | clk_160m_ext_select_o | clock_wrapper.u_clock_wrapper.select_ext_160m_i | clock_wrapper | add_mux_divider | Clock source select to wrapper |
| matrix_cfg_cmd_start_o | output | 1 | clk_sys | rst_sys_n | matrix_cfg_cmd_start | matrix_cfg_ctrl.u_matrix_cfg.cmd_start_i | internal | connect_direct | Matrix config command start |
| matrix_cfg_cmd_op_o | output | 3 | clk_sys | rst_sys_n | matrix_cfg_cmd_op | matrix_cfg_ctrl.u_matrix_cfg.cmd_op_i | internal | connect_direct | Matrix config operation |
| matrix_cfg_col_idx_o | output | 6 | clk_sys | rst_sys_n | matrix_cfg_col_idx | matrix_cfg_ctrl.u_matrix_cfg.col_idx_i | internal | connect_direct | Matrix config column index |
| matrix_cfg_wdata_o | output | 64 | clk_sys | rst_sys_n | matrix_cfg_wdata | matrix_cfg_ctrl.u_matrix_cfg.wdata_i | internal | connect_direct | Matrix config write data |
| cfg_accept_o | output | 1 | clk_sys | rst_sys_n | cfg_accept | top_status.unused_phase2_inputs.cfg_accept_o | internal | connect_direct | Command accept consumed by status glue in active top |

### or64_tree (module: `spadmic_matrix_or_tree`; kind: `handoff`)

| Port | Dir | Width | Clock | Reset | From | To | Pad/Macro | Action | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| lines_i | input | 64 | async | rst_sys_n | R_i | or64_tree.u_or_r.lines_i | matrice3 | connect_direct | R axis matrix event bus |
| event_o | output | 1 | combinational | rst_sys_n | r_matrix_event | top_glue.matrix_activity.axis_event | internal | connect_direct | R event detect |
| lines_i | input | 64 | async | rst_sys_n | Y_i | or64_tree.u_or_y.lines_i | matrice3 | connect_direct | Y axis matrix event bus |
| event_o | output | 1 | combinational | rst_sys_n | y_matrix_event | top_glue.matrix_activity.axis_event | internal | connect_direct | Y event detect |
| lines_i | input | 64 | async | rst_sys_n | B_i | or64_tree.u_or_b.lines_i | matrice3 | connect_direct | B axis matrix event bus |
| event_o | output | 1 | combinational | rst_sys_n | b_matrix_event | top_glue.matrix_activity.axis_event | internal | connect_direct | B event detect |

### matrix_reset_ctrl (module: `spadmic_matrix_reset_ctrl`; kind: `handoff`)

| Port | Dir | Width | Clock | Reset | From | To | Pad/Macro | Action | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| clk_sys | input | 1 | clk_sys | rst_sys_n | clk_sys | matrix_reset_ctrl.u_matrix_reset.clk_sys | clock_wrapper | connect_direct | Matrix reset controller clock |
| rst_n | input | 1 | clk_sys | rst_sys_n | rst_sys_n | matrix_reset_ctrl.u_matrix_reset.rst_n | internal | connect_direct | Global system reset |
| enable_i | input | 1 | clk_sys | rst_sys_n | auto_reset_enable | matrix_reset_ctrl.u_matrix_reset.enable_i | internal | connect_direct | CSR auto reset enable |
| start_i | input | 1 | clk_sys | rst_sys_n | reset_start | matrix_reset_ctrl.u_matrix_reset.start_i | internal | connect_direct | From event coordinator |
| reset_width_i | input | 16 | clk_sys | rst_sys_n | reset_width | matrix_reset_ctrl.u_matrix_reset.reset_width_i | internal | connect_direct | CSR reset pulse width |
| snapshot_R_i | input | 64 | clk_sys | rst_sys_n | snapshot_R | matrix_reset_ctrl.u_matrix_reset.snapshot_R_i | internal | connect_direct | Snapshot R mask for selective reset |
| snapshot_Y_i | input | 64 | clk_sys | rst_sys_n | snapshot_Y | matrix_reset_ctrl.u_matrix_reset.snapshot_Y_i | internal | connect_direct | Snapshot Y mask for selective reset |
| snapshot_B_i | input | 64 | clk_sys | rst_sys_n | snapshot_B | matrix_reset_ctrl.u_matrix_reset.snapshot_B_i | internal | connect_direct | Snapshot B mask for selective reset |
| Rz_o | output | 64 | clk_sys | rst_sys_n | Rz_o | matrice3.u_matrice3.Rz | matrice3 | route_to_macro | Selective reset output to matrix |
| Yz_o | output | 64 | clk_sys | rst_sys_n | Yz_o | matrice3.u_matrice3.Yz | matrice3 | route_to_macro | Selective reset output to matrix |
| Bz_o | output | 64 | clk_sys | rst_sys_n | Bz_o | matrice3.u_matrice3.Bz | matrice3 | route_to_macro | Selective reset output to matrix |
| busy_o | output | 1 | clk_sys | rst_sys_n | reset_busy | matrix_top_csr.u_matrix_top_csr.reset_busy_i | internal | connect_direct | Also feeds readiness and safe idle |
| done_o | output | 1 | clk_sys | rst_sys_n | reset_done | event_coordinator.u_event_coordinator.reset_done_i | internal | connect_direct | Also clears snapshot and feeds CSR |
| disabled_o | output | 1 | clk_sys | rst_sys_n | reset_disabled | matrix_top_csr.u_matrix_top_csr.reset_disabled_i | internal | connect_direct | Auto reset disabled status |

### event_coordinator (module: `spadmic_event_coordinator`; kind: `handoff`)

| Port | Dir | Width | Clock | Reset | From | To | Pad/Macro | Action | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| clk_sys | input | 1 | clk_sys | rst_sys_n | clk_sys | event_coordinator.u_event_coordinator.clk_sys | clock_wrapper | connect_direct | Event FSM clock |
| rst_n | input | 1 | clk_sys | rst_sys_n | rst_sys_n | event_coordinator.u_event_coordinator.rst_n | internal | connect_direct | Event FSM reset |
| active_mode_i | input | spadmic_operating_mode_e | clk_sys | rst_sys_n | active_mode | event_coordinator.u_event_coordinator.active_mode_i | internal | connect_direct | CSR active operating mode |
| global_enable_i | input | 1 | clk_sys | rst_sys_n | global_enable | event_coordinator.u_event_coordinator.global_enable_i | internal | connect_direct | CSR global enable |
| active_axis_mask_i | input | 3 | clk_sys | rst_sys_n | active_axis_mask | event_coordinator.u_event_coordinator.active_axis_mask_i | internal | connect_direct | R Y B map to bits 0 1 2 |
| matrix_activity_i | input | 1 | clk_sys | rst_sys_n | matrix_activity | event_coordinator.u_event_coordinator.matrix_activity_i | internal | connect_direct | OR tree events gated by mode and cfg busy |
| cal_activity_i | input | 1 | clk_sys | rst_sys_n | cal_activity | event_coordinator.u_event_coordinator.cal_activity_i | cal_*_async_i | connect_direct | Calibration start pads gated by mode and axis mask |
| pre_event_resources_ready_i | input | 1 | clk_sys | rst_sys_n | pre_event_resources_ready | event_coordinator.u_event_coordinator.pre_event_resources_ready_i | internal | connect_direct | Composite readiness from top glue |
| raw_snapshot_required_i | input | 1 | clk_sys | rst_sys_n | 1'b1 | event_coordinator.u_event_coordinator.raw_snapshot_required_i | internal | tie_constant | Active top always requires raw snapshot |
| auto_reset_enable_i | input | 1 | clk_sys | rst_sys_n | auto_reset_enable | event_coordinator.u_event_coordinator.auto_reset_enable_i | internal | connect_direct | CSR auto reset enable |
| snapshot_valid_i | input | 1 | clk_sys | rst_sys_n | snapshot_valid | event_coordinator.u_event_coordinator.snapshot_valid_i | internal | connect_direct | Snapshot frontend valid |
| position_snapshot_captured_i | input | 1 | clk_sys | rst_sys_n | pos_snapshot_captured_seen_q_or_pos_snapshot_captured | event_coordinator.u_event_coordinator.position_snapshot_captured_i | internal | connect_direct | Position snapshot captured latch or pulse |
| tdc_start_seen_i | input | 3 | clk_sys | rst_sys_n | tdc_start_seen_q | event_coordinator.u_event_coordinator.tdc_start_seen_i | internal | connect_direct | Synchronized TDC start seen mask |
| packet_pending_mask_i | input | 4 | clk_sys | rst_sys_n | packet_pending_mask | event_coordinator.u_event_coordinator.packet_pending_mask_i | internal | connect_direct | Bits 0..2 TDC and bit 3 position |
| reset_done_i | input | 1 | clk_sys | rst_sys_n | reset_done | event_coordinator.u_event_coordinator.reset_done_i | internal | connect_direct | From matrix reset controller |
| bundle_done_i | input | 1 | clk_sys | rst_sys_n | bundle_done | event_coordinator.u_event_coordinator.bundle_done_i | internal | connect_direct | From event bundle TX |
| rearm_ready_i | input | 1 | clk_sys | rst_sys_n | snapshot_rearm_ready | event_coordinator.u_event_coordinator.rearm_ready_i | internal | connect_direct | From snapshot frontend |
| event_open_o | output | 1 | clk_sys | rst_sys_n | event_open | top_glue.fanout.event_open | internal | connect_direct | Drives packet start and TDC seen reset |
| event_id_o | output | 14 | clk_sys | rst_sys_n | event_id | position_and_bundle.fanout.event_id_i | internal | connect_direct | Event ID to packets and CSR |
| event_id_valid_o | output | 1 | clk_sys | rst_sys_n | event_id_valid | top_glue.pos_packet_start.event_id_valid | internal | connect_direct | Qualifies position packet start |
| required_packet_mask_o | output | 4 | clk_sys | rst_sys_n | required_packet_mask | bundle_tx.u_bundle_tx.required_packet_mask_i | internal | connect_direct | Also drives position start and CSR |
| required_tdc_mask_o | output | 3 | clk_sys | rst_sys_n | required_tdc_mask | top_glue.tdc_start_gate.required_tdc_mask | internal | connect_direct | TDC required axis mask |
| required_reset_ack_mask_o | output | 4 | clk_sys | rst_sys_n | required_reset_ack_mask | matrix_top_csr.u_matrix_top_csr.required_reset_ack_mask_i | internal | connect_direct | CSR status mask |
| observed_reset_ack_mask_o | output | 4 | clk_sys | rst_sys_n | observed_reset_ack_mask | matrix_top_csr.u_matrix_top_csr.observed_reset_ack_mask_i | internal | connect_direct | CSR status mask |
| reset_start_o | output | 1 | clk_sys | rst_sys_n | reset_start | matrix_reset_ctrl.u_matrix_reset.start_i | internal | connect_direct | Starts matrix selective reset |
| bundle_start_o | output | 1 | clk_sys | rst_sys_n | bundle_start | event_bundle_tx.u_bundle_tx.bundle_start_i | internal | connect_direct | Starts packet bundle TX |
| accept_enable_o | output | 1 | clk_sys | rst_sys_n | event_accept_enable | top_status.unused_phase2_inputs.event_accept_enable | internal | connect_direct | Consumed only by status glue in active top |
| rejected_not_ready_o | output | 1 | clk_sys | rst_sys_n | event_rejected_not_ready | matrix_top_csr.u_matrix_top_csr.event_rejected_not_ready_i | internal | connect_direct | CSR event reject status |
| busy_o | output | 1 | clk_sys | rst_sys_n | event_busy | matrix_top_csr.u_matrix_top_csr.event_busy_i | internal | connect_direct | Also feeds safe idle |
| idle_o | output | 1 | clk_sys | rst_sys_n | event_idle | top_glue.readiness.event_idle | internal | connect_direct | Used in pre_event_resources_ready and safe_idle |

### tdc3_frontend (module: `spadmic_tdc3_frontend`; kind: `handoff`)

| Port | Dir | Width | Clock | Reset | From | To | Pad/Macro | Action | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| clk_sys | input | 1 | clk_sys | async_rst_n | clk_sys | tdc3_frontend.u_tdc3_frontend.clk_sys | clock_wrapper | connect_direct | System clock for wrapper glue and MPTDC macro clocks |
| clk_ref_40m | input | 1 | clk_ref_40m | async_rst_n | clk_ref_40m | tdc3_frontend.u_tdc3_frontend.clk_ref_40m | clock_wrapper | connect_direct | Reference clock used only by per-axis stop qualifiers |
| async_rst_n | input | 1 | async | async_rst_n | async_rst_n | tdc3_frontend.u_tdc3_frontend.async_rst_n | async_rst_n | connect_direct | Global active low reset reaches wrapper glue and MPTDC macros |
| global_enable_i | input | 1 | clk_sys | async_rst_n | global_enable_and_mode_has_tdc | tdc3_frontend.u_tdc3_frontend.global_enable_i | internal | connect_direct | Shared TDC path enable from CSR and mode decode |
| axis_enable_i | input | 3 | clk_sys | async_rst_n | tdc_axis_enable | tdc3_frontend.u_tdc3_frontend.axis_enable_i | internal | connect_direct | Axis order is R index 0 Y index 1 B index 2 |
| spad_event_async_i | input | 3 | async | async_rst_n | tdc_start_async_to_core | tdc3_frontend.u_tdc3_frontend.spad_event_async_i | internal | connect_direct | Per-axis matrix event from OR or event gate |
| cal_start_async_i | input | 3 | async | async_rst_n | cal_r_y_b_start_async_i | tdc3_frontend.u_tdc3_frontend.cal_start_async_i | cal_r_y_b_start_async_i | route_to_pad | External calibration START inputs R Y B |
| cal_stop_async_i | input | 3 | async | async_rst_n | cal_r_y_b_stop_async_i | tdc3_frontend.u_tdc3_frontend.cal_stop_async_i | cal_r_y_b_stop_async_i | route_to_pad | External calibration STOP inputs R Y B |
| input_sel_i | input | input_sel_e | clk_sys | async_rst_n | tdc_input_sel | tdc3_frontend.u_tdc3_frontend.input_sel_i | internal | connect_direct | Shared SPAD versus calibration selection into all three wrappers |
| conv_arm_i | input | 3 | clk_sys | async_rst_n | tdc_conv_arm | tdc3_frontend.u_tdc3_frontend.conv_arm_i | internal | connect_direct | Per-axis conversion arm R Y B |
| fifo_clr_i | input | 1 | clk_sys | async_rst_n | shared_tdc_fifo_clr | tdc3_frontend.u_tdc3_frontend.fifo_clr_i | internal | connect_direct | Shared clear forwarded to all three MPTDC axis macros |
| soft_reset_i | input | 1 | clk_sys | async_rst_n | shared_tdc_soft_reset | tdc3_frontend.u_tdc3_frontend.soft_reset_i | internal | connect_direct | Shared soft reset forwarded to all three MPTDC axis macros |
| max_hits_i | input | MAX_HITS_W | clk_sys | async_rst_n | shared_tdc_max_hits | tdc3_frontend.u_tdc3_frontend.max_hits_i | internal | connect_direct | Shared MPTDC hit limit from CSR |
| ro_slow_code_i | input | 8 | clk_sys | async_rst_n | shared_tdc_ro_slow_code | tdc3_frontend.u_tdc3_frontend.ro_slow_code_i | internal | connect_direct | Shared slow oscillator code from CSR |
| ro_fast_code_i | input | 8 | clk_sys | async_rst_n | shared_tdc_ro_fast_code | tdc3_frontend.u_tdc3_frontend.ro_fast_code_i | internal | connect_direct | Shared fast oscillator code from CSR |
| pkt_valid_o | output | 3 | clk_sys | async_rst_n | tdc_pkt_valid | event_bundle_tx.u_bundle_tx.src_valid_i[0..2] | internal | connect_direct | TDC R Y B packet valid streams |
| pkt_ready_i | input | 3 | clk_sys | async_rst_n | tdc_pkt_ready | tdc3_frontend.u_tdc3_frontend.pkt_ready_i | internal | connect_direct | Backpressure from event_bundle_tx source ready |
| pkt_data_o | output | 3*NARROW_W | clk_sys | async_rst_n | tdc_pkt_data | event_bundle_tx.u_bundle_tx.src_data_i[0..2] | internal | connect_direct | Flattened data slices R 0 Y 1 B 2 |
| pkt_sop_o | output | 3 | clk_sys | async_rst_n | tdc_pkt_sop | event_bundle_tx.u_bundle_tx.src_sop_i[0..2] | internal | connect_direct | TDC packet start markers |
| pkt_eop_o | output | 3 | clk_sys | async_rst_n | tdc_pkt_eop | event_bundle_tx.u_bundle_tx.src_eop_i[0..2] | internal | connect_direct | TDC packet end markers |
| packet_active_o | output | 3 | clk_sys | async_rst_n | tdc_packet_active | matrix_top_csr.u_matrix_top_csr.tdc_packet_active_i | internal | connect_direct | Per-axis active status to CSR or top glue |
| packet_pending_o | output | 3 | clk_sys | async_rst_n | tdc_packet_pending | event_coordinator.u_event_coordinator.packet_pending_mask_i[0..2] | internal | connect_direct | Per-axis pending status for event completion |
| ready_o | output | 3 | clk_sys | async_rst_n | tdc_ready | matrix_top_csr.u_matrix_top_csr.tdc_ready_i | internal | connect_direct | Per-axis ready status |
| busy_o | output | 3 | clk_sys | async_rst_n | tdc_busy | matrix_top_csr.u_matrix_top_csr.tdc_busy_i | internal | connect_direct | Per-axis busy status and safe idle input |
| fifo_full_o | output | 3 | clk_sys | async_rst_n | tdc_fifo_full | matrix_top_csr.u_matrix_top_csr.tdc_fifo_full_i | internal | connect_direct | Per-axis MPTDC FIFO full status |
| stop_armed_o | output | 3 | clk_ref_40m | async_rst_n | tdc_stop_armed | matrix_top_csr.u_matrix_top_csr.tdc_stop_armed_i | internal | connect_direct | Stop qualifier armed status from each axis wrapper |

### position_snapshot (module: `spadmic_position_snapshot_packetizer`; kind: `handoff`)

| Port | Dir | Width | Clock | Reset | From | To | Pad/Macro | Action | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| clk_sys | input | 1 | clk_sys | rst_sys_n | clk_sys | position_snapshot.u_pos_packetizer.clk_sys | clock_wrapper | connect_direct | Position packetizer clock |
| rst_n | input | 1 | clk_sys | rst_sys_n | rst_sys_n | position_snapshot.u_pos_packetizer.rst_n | internal | connect_direct | Position packetizer reset |
| start_i | input | 1 | clk_sys | rst_sys_n | pos_packet_start | position_snapshot.u_pos_packetizer.start_i | internal | connect_direct | Event open and ID valid and snapshot valid gate |
| mode_i | input | spadmic_pos_mode_e | clk_sys | rst_sys_n | position_mode | position_snapshot.u_pos_packetizer.mode_i | internal | connect_direct | CSR position mode |
| event_id_i | input | 14 | clk_sys | rst_sys_n | event_id | position_snapshot.u_pos_packetizer.event_id_i | internal | connect_direct | Current event ID |
| snapshot_R_i | input | 64 | clk_sys | rst_sys_n | snapshot_R | position_snapshot.u_pos_packetizer.snapshot_R_i | internal | connect_direct | Captured R snapshot |
| snapshot_Y_i | input | 64 | clk_sys | rst_sys_n | snapshot_Y | position_snapshot.u_pos_packetizer.snapshot_Y_i | internal | connect_direct | Captured Y snapshot |
| snapshot_B_i | input | 64 | clk_sys | rst_sys_n | snapshot_B | position_snapshot.u_pos_packetizer.snapshot_B_i | internal | connect_direct | Captured B snapshot |
| gap_threshold_i | input | SPADMIC_LINE_COUNT_W | clk_sys | rst_sys_n | position_gap_threshold | position_snapshot.u_pos_packetizer.gap_threshold_i | internal | tie_constant | Active top sets threshold to 2 |
| min_cluster_span_i | input | SPADMIC_LINE_COUNT_W | clk_sys | rst_sys_n | position_min_cluster_span | position_snapshot.u_pos_packetizer.min_cluster_span_i | internal | tie_constant | Active top sets span to 1 |
| pkt_valid_o | output | 1 | clk_sys | rst_sys_n | pos_pkt_valid | event_bundle_tx.u_bundle_tx.src_valid_i[3] | internal | connect_direct | Position source valid to bundle TX |
| pkt_ready_i | input | 1 | clk_sys | rst_sys_n | pos_pkt_ready | position_snapshot.u_pos_packetizer.pkt_ready_i | internal | connect_direct | From bundle source ready bit 3 |
| pkt_data_o | output | NARROW_W | clk_sys | rst_sys_n | pos_pkt_data | event_bundle_tx.u_bundle_tx.src_data_i[3] | internal | connect_direct | Position packet word |
| pkt_sop_o | output | 1 | clk_sys | rst_sys_n | pos_pkt_sop | event_bundle_tx.u_bundle_tx.src_sop_i[3] | internal | connect_direct | Position packet SOP |
| pkt_eop_o | output | 1 | clk_sys | rst_sys_n | pos_pkt_eop | event_bundle_tx.u_bundle_tx.src_eop_i[3] | internal | connect_direct | Position packet EOP |
| packet_pending_o | output | 1 | clk_sys | rst_sys_n | pos_packet_pending | event_coordinator.u_event_coordinator.packet_pending_mask_i[3] | internal | connect_direct | Position packet pending status |
| busy_o | output | 1 | clk_sys | rst_sys_n | pos_packet_busy | top_glue.readiness.pos_packet_busy | internal | connect_direct | Position path busy status |
| snapshot_captured_o | output | 1 | clk_sys | rst_sys_n | pos_snapshot_captured | event_coordinator.u_event_coordinator.position_snapshot_captured_i | internal | connect_direct | Latched in top while event open |
| done_o | output | 1 | clk_sys | rst_sys_n | pos_packet_done | top_status.unused_phase2_inputs.pos_packet_done | internal | connect_direct | Consumed by status glue in active top |
| drop_o | output | 1 | clk_sys | rst_sys_n | pos_packet_drop | matrix_top_csr.u_matrix_top_csr.position_packet_drop_i | internal | connect_direct | CSR status and top status glue |

### event_bundle_tx (module: `spadmic_event_bundle_tx`; kind: `handoff`)

| Port | Dir | Width | Clock | Reset | From | To | Pad/Macro | Action | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| clk_sys | input | 1 | clk_sys | rst_sys_n | clk_sys | event_bundle_tx.u_bundle_tx.clk_sys | clock_wrapper | connect_direct | Bundle TX clock |
| rst_n | input | 1 | clk_sys | rst_sys_n | rst_sys_n | event_bundle_tx.u_bundle_tx.rst_n | internal | connect_direct | Bundle TX reset |
| bundle_start_i | input | 1 | clk_sys | rst_sys_n | bundle_start | event_bundle_tx.u_bundle_tx.bundle_start_i | internal | connect_direct | From event coordinator |
| required_packet_mask_i | input | 4 | clk_sys | rst_sys_n | required_packet_mask | event_bundle_tx.u_bundle_tx.required_packet_mask_i | internal | connect_direct | From event coordinator |
| source_pending_mask_i | input | 4 | clk_sys | rst_sys_n | packet_pending_mask | event_bundle_tx.u_bundle_tx.source_pending_mask_i | internal | connect_direct | TDC pending bits plus position pending |
| event_id_i | input | 14 | clk_sys | rst_sys_n | event_id | event_bundle_tx.u_bundle_tx.event_id_i | internal | connect_direct | Current event ID |
| src_valid_i | input | 4 | clk_sys | rst_sys_n | src_valid[0..3] | event_bundle_tx.u_bundle_tx.src_valid_i | internal | connect_direct | Bits 0 R 1 Y 2 B 3 position |
| src_ready_o | output | 4 | clk_sys | rst_sys_n | src_ready[0..3] | tdc_and_position_sources.fanout.pkt_ready_i | internal | connect_direct | Backpressure to packet sources |
| src_data_i | input | NARROW_W x SPADMIC_SRC_COUNT | clk_sys | rst_sys_n | src_data[0..3] | event_bundle_tx.u_bundle_tx.src_data_i | internal | connect_direct | Packet data from TDC R Y B and position |
| src_sop_i | input | 4 | clk_sys | rst_sys_n | src_sop[0..3] | event_bundle_tx.u_bundle_tx.src_sop_i | internal | connect_direct | Packet SOP flags |
| src_eop_i | input | 4 | clk_sys | rst_sys_n | src_eop[0..3] | event_bundle_tx.u_bundle_tx.src_eop_i | internal | connect_direct | Packet EOP flags |
| word_valid_o | output | 1 | clk_sys | rst_sys_n | bundle_word_valid | output_fifo.u_output_fifo.push_valid_i | internal | connect_direct | Output word valid before flush marker mux |
| word_ready_i | input | 1 | clk_sys | rst_sys_n | bundle_word_ready | event_bundle_tx.u_bundle_tx.word_ready_i | internal | connect_direct | FIFO push ready and no pending flush |
| word_data_o | output | NARROW_W | clk_sys | rst_sys_n | bundle_word_data | output_fifo.u_output_fifo.push_data_i[NARROW_W-1:0] | internal | connect_direct | Output word data before flush marker mux |
| flush_o | output | 1 | clk_sys | rst_sys_n | bundle_flush | output_fifo.u_output_fifo.push_data_i[NARROW_W] | internal | connect_direct | Converted into FIFO flush marker |
| completed_packet_mask_o | output | 4 | clk_sys | rst_sys_n | bundle_completed_packet_mask | matrix_top_csr.u_matrix_top_csr.completed_packet_mask_i | internal | connect_direct | CSR packet completion status |
| done_o | output | 1 | clk_sys | rst_sys_n | bundle_done | event_coordinator.u_event_coordinator.bundle_done_i | internal | connect_direct | Event coordinator bundle done |
| busy_o | output | 1 | clk_sys | rst_sys_n | bundle_busy | top_status.unused_phase2_inputs.bundle_busy | internal | connect_direct | Bundle busy status |
| idle_o | output | 1 | clk_sys | rst_sys_n | bundle_idle | top_glue.readiness.bundle_idle | internal | connect_direct | Output path idle computation |
| missing_source_error_o | output | 1 | clk_sys | rst_sys_n | bundle_missing_source_error | matrix_top_csr.u_matrix_top_csr.bundle_missing_source_i | internal | connect_direct | CSR error status |

### output_fifo (module: `spadmic_output_fifo`; kind: `handoff`)

| Port | Dir | Width | Clock | Reset | From | To | Pad/Macro | Action | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| clk_sys | input | 1 | clk_sys | rst_sys_n | clk_sys | output_fifo.u_output_fifo.clk_sys | clock_wrapper | connect_direct | FIFO clock |
| rst_n | input | 1 | clk_sys | rst_sys_n | rst_sys_n | output_fifo.u_output_fifo.rst_n | internal | connect_direct | FIFO reset |
| push_valid_i | input | 1 | clk_sys | rst_sys_n | output_fifo_push_valid | output_fifo.u_output_fifo.push_valid_i | internal | connect_direct | bundle_word_valid OR pending flush marker |
| push_data_i | input | NARROW_W+1 | clk_sys | rst_sys_n | output_fifo_push_data | output_fifo.u_output_fifo.push_data_i | internal | connect_direct | MSB marks flush and lower bits are data |
| push_ready_o | output | 1 | clk_sys | rst_sys_n | output_fifo_push_ready | event_bundle_tx.u_bundle_tx.word_ready_i | internal | connect_direct | Backpressure to bundle TX |
| pop_valid_o | output | 1 | clk_sys | rst_sys_n | output_fifo_pop_valid | ddr16_pairer.u_ddr16_pairer.word_valid_i | internal | connect_direct | Qualified by pop fire in top glue |
| pop_ready_i | input | 1 | clk_sys | rst_sys_n | output_fifo_pop_ready | output_fifo.u_output_fifo.pop_ready_i | internal | connect_direct | DDR ready or auto consume flush marker |
| pop_data_o | output | NARROW_W+1 | clk_sys | rst_sys_n | output_fifo_pop_data | ddr16_pairer.u_ddr16_pairer.word_data_i | internal | connect_direct | MSB is flush marker and lower bits feed DDR pairer |
| level_o | output | SPADMIC_OUTPUT_FIFO_LEVEL_W | clk_sys | rst_sys_n | output_fifo_level | matrix_top_csr.u_matrix_top_csr.output_fifo_level_i | internal | connect_direct | FIFO level CSR status |
| free_words_o | output | SPADMIC_OUTPUT_FIFO_LEVEL_W | clk_sys | rst_sys_n | output_fifo_free_words | matrix_top_csr.u_matrix_top_csr.output_fifo_free_words_i | internal | connect_direct | FIFO free words status and readiness |
| empty_o | output | 1 | clk_sys | rst_sys_n | output_fifo_empty | matrix_top_csr.u_matrix_top_csr.output_fifo_empty_i | internal | connect_direct | FIFO empty status |
| full_o | output | 1 | clk_sys | rst_sys_n | output_fifo_full | matrix_top_csr.u_matrix_top_csr.output_fifo_full_i | internal | connect_direct | FIFO full status |
| almost_full_o | output | 1 | clk_sys | rst_sys_n | output_fifo_almost_full | matrix_top_csr.u_matrix_top_csr.output_fifo_almost_full_i | internal | connect_direct | FIFO almost full status |
| overflow_o | output | 1 | clk_sys | rst_sys_n | output_fifo_overflow | matrix_top_csr.u_matrix_top_csr.output_fifo_overflow_i | internal | connect_direct | FIFO overflow status |

### matrix_cfg_ctrl (module: `spadmic_matrix_cfg_ctrl`; kind: `handoff`)

| Port | Dir | Width | Clock | Reset | From | To | Pad/Macro | Action | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| clk_sys | input | 1 | clk_sys | rst_sys_n | clk_sys | matrix_cfg_ctrl.u_matrix_cfg.clk_sys | clock_wrapper | connect_direct | Matrix config command clock |
| clk_cfg_40m | input | 1 | clk_cfg_40m | rst_cfg_n | clk_cfg_40m | matrix_cfg_ctrl.u_matrix_cfg.clk_cfg_40m | clock_wrapper | connect_direct | Matrix serial config clock domain |
| rst_sys_n | input | 1 | clk_sys | rst_sys_n | rst_sys_n | matrix_cfg_ctrl.u_matrix_cfg.rst_sys_n | internal | connect_direct | System domain reset |
| rst_cfg_n | input | 1 | clk_cfg_40m | rst_cfg_n | rst_cfg_n | matrix_cfg_ctrl.u_matrix_cfg.rst_cfg_n | internal | connect_direct | Config domain reset |
| cmd_start_i | input | 1 | clk_sys | rst_sys_n | matrix_cfg_cmd_start | matrix_cfg_ctrl.u_matrix_cfg.cmd_start_i | internal | connect_direct | From CSR matrix config command |
| cmd_op_i | input | 3 | clk_sys | rst_sys_n | matrix_cfg_cmd_op | matrix_cfg_ctrl.u_matrix_cfg.cmd_op_i | internal | connect_direct | From CSR |
| col_idx_i | input | 6 | clk_sys | rst_sys_n | matrix_cfg_col_idx | matrix_cfg_ctrl.u_matrix_cfg.col_idx_i | internal | connect_direct | From CSR |
| wdata_i | input | 64 | clk_sys | rst_sys_n | matrix_cfg_wdata | matrix_cfg_ctrl.u_matrix_cfg.wdata_i | internal | connect_direct | From CSR |
| busy_o | output | 1 | clk_sys | rst_sys_n | matrix_cfg_busy | matrix_top_csr.u_matrix_top_csr.matrix_cfg_busy_i | internal | connect_direct | Also blocks events and safe idle |
| done_o | output | 1 | clk_sys | rst_sys_n | matrix_cfg_done | matrix_top_csr.u_matrix_top_csr.matrix_cfg_done_i | internal | connect_direct | CSR status |
| error_o | output | 1 | clk_sys | rst_sys_n | matrix_cfg_error | matrix_top_csr.u_matrix_top_csr.matrix_cfg_error_i | internal | connect_direct | CSR status |
| last_error_o | output | 4 | clk_sys | rst_sys_n | matrix_cfg_last_error | matrix_top_csr.u_matrix_top_csr.matrix_cfg_last_error_i | internal | connect_direct | CSR status code |
| rdata_o | output | 64 | clk_sys | rst_sys_n | matrix_cfg_rdata | matrix_top_csr.u_matrix_top_csr.matrix_cfg_rdata_i | internal | connect_direct | Matrix readback data to CSR |
| readback_valid_o | output | 1 | clk_sys | rst_sys_n | matrix_cfg_readback_valid | matrix_top_csr.u_matrix_top_csr.matrix_cfg_readback_valid_i | internal | connect_direct | Matrix readback valid to CSR |
| matrix_cfg_valid_o | output | 1 | clk_cfg_40m | rst_cfg_n | matrix_cfg_valid | matrix_top_csr.u_matrix_top_csr.matrix_cfg_valid_i | internal | connect_direct | Matrix cfg valid status |
| matrix_din_o | output | 44 | clk_cfg_40m | rst_cfg_n | matrix_din_o | matrice3.u_matrice3.Din | matrice3 | route_to_macro | Configuration data to matrix macro |
| matrix_cin_o | output | 44 | clk_cfg_40m | rst_cfg_n | matrix_cin_o | matrice3.u_matrice3.Cin | matrice3 | route_to_macro | Configuration strobe to matrix macro |
| matrix_dout_i | input | 44 | clk_cfg_40m | rst_cfg_n | matrix_dout_i | matrix_cfg_ctrl.u_matrix_cfg.matrix_dout_i | matrice3 | route_from_macro | Readback data from matrix macro |
| matrix_cout_i | input | 44 | clk_cfg_40m | rst_cfg_n | matrix_cout_i | matrix_cfg_ctrl.u_matrix_cfg.matrix_cout_i | matrice3 | route_from_macro | Readback strobe from matrix macro |

### ddr16_pairer (module: `spadmic_ddr16_tx_pairer`; kind: `handoff`)

| Port | Dir | Width | Clock | Reset | From | To | Pad/Macro | Action | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| clk_sys | input | 1 | clk_sys | rst_sys_n | clk_sys | ddr16_pairer.u_ddr16_pairer.clk_sys | clock_wrapper | connect_direct | DDR16 pairer clock |
| rst_n | input | 1 | clk_sys | rst_sys_n | rst_sys_n | ddr16_pairer.u_ddr16_pairer.rst_n | internal | connect_direct | DDR16 pairer reset |
| word_valid_i | input | 1 | clk_sys | rst_sys_n | ddr_word_valid | ddr16_pairer.u_ddr16_pairer.word_valid_i | internal | connect_direct | FIFO pop fire and not flush marker |
| word_data_i | input | NARROW_W | clk_sys | rst_sys_n | ddr_word_data | ddr16_pairer.u_ddr16_pairer.word_data_i | internal | connect_direct | FIFO pop data lower bits |
| flush_i | input | 1 | clk_sys | rst_sys_n | ddr_flush | ddr16_pairer.u_ddr16_pairer.flush_i | internal | connect_direct | FIFO flush marker |
| word_ready_o | output | 1 | clk_sys | rst_sys_n | ddr_word_ready | output_fifo.u_output_fifo.pop_ready_i | internal | connect_direct | Backpressure to FIFO pop path |
| ddr_data_l_o | output | 16 | clk_sys | rst_sys_n | ddr_data_l_o | SLVS_DATA.u_slvs_data_0_to_15.data_l_i | DATA[15:0] | route_to_driver | Low phase bits to SLVS data drivers |
| ddr_data_h_o | output | 16 | clk_sys | rst_sys_n | ddr_data_h_o | SLVS_DATA.u_slvs_data_0_to_15.data_h_i | DATA[15:0] | route_to_driver | High phase bits to SLVS data drivers |
| ddr_pair_valid_o | output | 1 | clk_sys | rst_sys_n | ddr_pair_valid_o | SLVS_VALID.u_slvs_valid.data_i | DATA_VALID | route_to_driver | Valid driver in north row |
| ddr_padded_o | output | 1 | clk_sys | rst_sys_n | ddr_padded | matrix_top_csr.u_matrix_top_csr.ddr_padded_i | internal | connect_direct | CSR status for padded final pair |
| ddr_clk_o | output | 1 | clk_sys | rst_sys_n | ddr_clk_o | SLVS_CLK.u_slvs_clk.data_i | DATA_CLK | route_to_driver | Forwarded clock driver in north row |
| busy_o | output | 1 | clk_sys | rst_sys_n | ddr_busy | matrix_top_csr.u_matrix_top_csr.ddr_busy_i | internal | connect_direct | CSR status and safe idle |
| empty_o | output | 1 | clk_sys | rst_sys_n | ddr_empty | matrix_top_csr.u_matrix_top_csr.ddr_empty_i | internal | connect_direct | CSR status and output path idle |

## 05 - Glue RTL Detail

### snapshot_frontend (module: `spadmic_matrix_snapshot_frontend`; kind: `glue_rtl`)

| Port | Dir | Width | Clock | Reset | From | To | Pad/Macro | Action | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| clk_sys | input | 1 | clk_sys | rst_sys_n | clk_sys | snapshot_frontend.u_snapshot.clk_sys | clock_wrapper | instantiate | Required glue not separate handoff folder |
| rst_n | input | 1 | clk_sys | rst_sys_n | rst_sys_n | snapshot_frontend.u_snapshot.rst_n | internal | instantiate | Required glue not separate handoff folder |
| enable_i | input | 1 | clk_sys | rst_sys_n | matrix_event_allowed | snapshot_frontend.u_snapshot.enable_i | internal | connect_direct | Global enable and mode and cfg busy gate |
| clear_i | input | 1 | clk_sys | rst_sys_n | reset_or_csr_snapshot_clear | snapshot_frontend.u_snapshot.clear_i | internal | connect_direct | OR of reset_done and CSR snapshot clear |
| required_direction_mask_i | input | 3 | clk_sys | rst_sys_n | snapshot_required_direction_mask | snapshot_frontend.u_snapshot.required_direction_mask_i | internal | connect_direct | Depends on active mode and axis mask |
| R_i | input | 64 | async | rst_sys_n | R_i | snapshot_frontend.u_snapshot.R_i | matrice3 | connect_direct | Matrix R lines |
| Y_i | input | 64 | async | rst_sys_n | Y_i | snapshot_frontend.u_snapshot.Y_i | matrice3 | connect_direct | Matrix Y lines |
| B_i | input | 64 | async | rst_sys_n | B_i | snapshot_frontend.u_snapshot.B_i | matrice3 | connect_direct | Matrix B lines |
| settle_cycles_i | input | 16 | clk_sys | rst_sys_n | settle_cycles | snapshot_frontend.u_snapshot.settle_cycles_i | internal | connect_direct | From CSR |
| watchdog_cycles_i | input | 16 | clk_sys | rst_sys_n | watchdog_cycles | snapshot_frontend.u_snapshot.watchdog_cycles_i | internal | connect_direct | From CSR |
| snapshot_valid_o | output | 1 | clk_sys | rst_sys_n | snapshot_valid | event_coordinator.u_event_coordinator.snapshot_valid_i | internal | connect_direct | Also feeds CSR and packetizer |
| snapshot_R_o | output | 64 | clk_sys | rst_sys_n | snapshot_R | matrix_reset_and_position.fanout.snapshot_R_i | internal | connect_direct | Feeds reset ctrl position packetizer and CSR |
| snapshot_Y_o | output | 64 | clk_sys | rst_sys_n | snapshot_Y | matrix_reset_and_position.fanout.snapshot_Y_i | internal | connect_direct | Feeds reset ctrl position packetizer and CSR |
| snapshot_B_o | output | 64 | clk_sys | rst_sys_n | snapshot_B | matrix_reset_and_position.fanout.snapshot_B_i | internal | connect_direct | Feeds reset ctrl position packetizer and CSR |
| busy_o | output | 1 | clk_sys | rst_sys_n | snapshot_busy | top_status.fanout.snapshot_busy_i | internal | connect_direct | Feeds CSR event readiness and safe idle |
| timeout_o | output | 1 | clk_sys | rst_sys_n | snapshot_timeout | matrix_top_csr.u_matrix_top_csr.snapshot_timeout_i | internal | connect_direct | Snapshot timeout |
| overlap_o | output | 1 | clk_sys | rst_sys_n | snapshot_overlap | matrix_top_csr.u_matrix_top_csr.snapshot_overlap_i | internal | connect_direct | Snapshot overlap |
| reject_o | output | 1 | clk_sys | rst_sys_n | snapshot_reject | matrix_top_csr.u_matrix_top_csr.snapshot_reject_i | internal | connect_direct | Snapshot reject |
| rearm_ready_o | output | 1 | clk_sys | rst_sys_n | snapshot_rearm_ready | event_coordinator.u_event_coordinator.rearm_ready_i | internal | connect_direct | Also feeds CSR and readiness |

### tdc_axis_wrapper (module: `spadmic_tdc_axis_wrapper`; kind: `glue_rtl`)

| Port | Dir | Width | Clock | Reset | From | To | Pad/Macro | Action | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| clk_sys | input | 1 | clk_sys | async_rst_n | clk_sys | tdc_axis_wrapper.u_tdc_r/u_tdc_y/u_tdc_b.clk_sys | clock_wrapper | instantiate | Three wrappers around MPTDC axis cores |
| clk_ref_40m | input | 1 | clk_ref_40m | async_rst_n | clk_ref_40m | tdc_axis_wrapper.u_tdc_r/u_tdc_y/u_tdc_b.clk_ref_40m | clock_wrapper | instantiate | Used by stop qualifier before mptdc_axis_core |
| async_rst_n | input | 1 | async | async_rst_n | async_rst_n | tdc_axis_wrapper.u_tdc_r/u_tdc_y/u_tdc_b.async_rst_n | async_rst_n | instantiate | MPTDC keeps original async reset |
| global_enable_i | input | 1 | clk_sys | async_rst_n | global_enable_and_mode_has_tdc | tdc_axis_wrapper.u_tdc_r/u_tdc_y/u_tdc_b.global_enable_i | internal | connect_direct | Top passes global_enable and mode_has_tdc |
| axis_enable_i | input | 1 | clk_sys | async_rst_n | tdc_axis_enable[0..2] | tdc_axis_wrapper.u_tdc_r/u_tdc_y/u_tdc_b.axis_enable_i | internal | connect_direct | R Y B map to indices 0 1 2 |
| spad_event_async_i | input | 1 | async | async_rst_n | tdc_start_async_to_core[0..2] | tdc_axis_wrapper.u_tdc_r/u_tdc_y/u_tdc_b.spad_event_async_i | matrice3 | connect_direct | Gated from R Y B matrix OR event per axis |
| cal_start_async_i | input | 1 | async | async_rst_n | cal_r_y_b_start_async_i | tdc_axis_wrapper.u_tdc_r/u_tdc_y/u_tdc_b.cal_start_async_i | cal_*_start_async_i | route_to_pad | Per axis calibration START pad |
| cal_stop_async_i | input | 1 | async | async_rst_n | cal_r_y_b_stop_async_i | tdc_axis_wrapper.u_tdc_r/u_tdc_y/u_tdc_b.cal_stop_async_i | cal_*_stop_async_i | route_to_pad | Per axis calibration STOP pad |
| input_sel_i | input | input_sel_e | clk_sys | async_rst_n | tdc_input_sel | tdc_axis_wrapper.u_tdc_r/u_tdc_y/u_tdc_b.input_sel_i | internal | connect_direct | INPUT_CAL in calibration mode else INPUT_SPAD |
| conv_arm_i | input | 1 | clk_sys | async_rst_n | tdc_conv_arm[0..2] | tdc_axis_wrapper.u_tdc_r/u_tdc_y/u_tdc_b.conv_arm_i | internal | connect_direct | Same as per axis enable |
| fifo_clr_i | input | 1 | clk_sys | async_rst_n | shared_tdc_fifo_clr | tdc_axis_wrapper.u_tdc_r/u_tdc_y/u_tdc_b.fifo_clr_i | internal | connect_direct | Shared CSR FIFO clear |
| soft_reset_i | input | 1 | clk_sys | async_rst_n | shared_tdc_soft_reset | tdc_axis_wrapper.u_tdc_r/u_tdc_y/u_tdc_b.soft_reset_i | internal | connect_direct | Shared CSR soft reset |
| max_hits_i | input | MAX_HITS_W | clk_sys | async_rst_n | shared_tdc_max_hits | tdc_axis_wrapper.u_tdc_r/u_tdc_y/u_tdc_b.max_hits_i | internal | connect_direct | Shared max hits |
| ro_slow_code_i | input | 8 | clk_sys | async_rst_n | shared_tdc_ro_slow_code | tdc_axis_wrapper.u_tdc_r/u_tdc_y/u_tdc_b.ro_slow_code_i | internal | connect_direct | Shared slow RO code |
| ro_fast_code_i | input | 8 | clk_sys | async_rst_n | shared_tdc_ro_fast_code | tdc_axis_wrapper.u_tdc_r/u_tdc_y/u_tdc_b.ro_fast_code_i | internal | connect_direct | Shared fast RO code |
| pkt_valid_o | output | 1 | clk_sys | async_rst_n | tdc_pkt_valid[0..2] | event_bundle_tx.u_bundle_tx.src_valid_i[0..2] | internal | connect_direct | TDC packet valid to bundle TX |
| pkt_ready_i | input | 1 | clk_sys | async_rst_n | tdc_pkt_ready[0..2] | tdc_axis_wrapper.u_tdc_r/u_tdc_y/u_tdc_b.pkt_ready_i | internal | connect_direct | From bundle source ready |
| pkt_data_o | output | NARROW_W | clk_sys | async_rst_n | tdc_pkt_data[0..2] | event_bundle_tx.u_bundle_tx.src_data_i[0..2] | internal | connect_direct | TDC packet word |
| pkt_sop_o | output | 1 | clk_sys | async_rst_n | tdc_pkt_sop[0..2] | event_bundle_tx.u_bundle_tx.src_sop_i[0..2] | internal | connect_direct | TDC packet SOP |
| pkt_eop_o | output | 1 | clk_sys | async_rst_n | tdc_pkt_eop[0..2] | event_bundle_tx.u_bundle_tx.src_eop_i[0..2] | internal | connect_direct | TDC packet EOP |
| packet_active_o | output | 1 | clk_sys | async_rst_n | tdc_packet_active[0..2] | top_glue.readiness.tdc_packet_active | internal | connect_direct | TDC active status |
| packet_pending_o | output | 1 | clk_sys | async_rst_n | tdc_packet_pending[0..2] | event_coordinator.u_event_coordinator.packet_pending_mask_i[0..2] | internal | connect_direct | TDC packet pending status |
| ready_o | output | 1 | clk_sys | async_rst_n | tdc_ready[0..2] | top_glue.readiness.tdc_ready | internal | connect_direct | TDC resource ready status |
| busy_o | output | 1 | clk_sys | async_rst_n | tdc_busy[0..2] | top_glue.readiness.tdc_busy | internal | connect_direct | TDC busy status |
| fifo_full_o | output | 1 | clk_sys | async_rst_n | tdc_fifo_full[0..2] | top_glue.readiness.tdc_fifo_full | internal | connect_direct | TDC FIFO full status |
| stop_armed_o | output | 1 | clk_ref_40m | async_rst_n | tdc_stop_armed[0..2] | top_glue.unused_or_future_status.tdc_stop_armed | internal | connect_direct | Stop qualifier armed status |

## 06 - MPTDC Macro Black-Box Contract

### mptdc_axis_core (module: `mptdc_axis_core`; kind: `macro`)

| Port | Dir | Width | Clock | Reset | From | To | Pad/Macro | Action | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| clk_sys | input | 1 | clk_sys | async_rst_n | clk_sys | mptdc_axis_core.axis_core_instances.clk_sys | clock_wrapper | instantiate_macro | Physical macro clock input |
| async_rst_n | input | 1 | async | async_rst_n | async_rst_n | mptdc_axis_core.axis_core_instances.async_rst_n | async_rst_n | instantiate_macro | Original async reset reaches MPTDC core |
| start_spad_async_i | input | 1 | async | async_rst_n | start_async_gated | mptdc_axis_core.axis_core_instances.start_spad_async_i | internal | connect_direct | Generated inside tdc wrapper from matrix event and enables |
| stop_spad_async_i | input | 1 | clk_ref_40m | async_rst_n | stop_async_qualified | mptdc_axis_core.axis_core_instances.stop_spad_async_i | internal | connect_direct | Generated by spadmic_ref_stop_qualifier |
| cal_start_async_i | input | 1 | async | async_rst_n | cal_start_async_gated | mptdc_axis_core.axis_core_instances.cal_start_async_i | cal_*_start_async_i | connect_direct | Wrapper gates external calibration start |
| cal_stop_async_i | input | 1 | async | async_rst_n | cal_stop_async_gated | mptdc_axis_core.axis_core_instances.cal_stop_async_i | cal_*_stop_async_i | connect_direct | Wrapper gates external calibration stop |
| input_sel_i | input | input_sel_e | clk_sys | async_rst_n | tdc_input_sel | mptdc_axis_core.axis_core_instances.input_sel_i | internal | connect_direct | Calibration mode selects calibration path |
| conv_arm_i | input | 1 | clk_sys | async_rst_n | tdc_conv_arm[0..2] | mptdc_axis_core.axis_core_instances.conv_arm_i | internal | connect_direct | Per axis conversion arm |
| fifo_clr_i | input | 1 | clk_sys | async_rst_n | shared_tdc_fifo_clr | mptdc_axis_core.axis_core_instances.fifo_clr_i | internal | connect_direct | Shared FIFO clear |
| soft_reset_i | input | 1 | clk_sys | async_rst_n | shared_tdc_soft_reset | mptdc_axis_core.axis_core_instances.soft_reset_i | internal | connect_direct | Shared soft reset |
| max_hits_i | input | MAX_HITS_W | clk_sys | async_rst_n | shared_tdc_max_hits | mptdc_axis_core.axis_core_instances.max_hits_i | internal | connect_direct | Shared max hits |
| ro_slow_code_i | input | 8 | clk_sys | async_rst_n | shared_tdc_ro_slow_code | mptdc_axis_core.axis_core_instances.ro_slow_code_i | internal | connect_direct | Shared slow RO code |
| ro_fast_code_i | input | 8 | clk_sys | async_rst_n | shared_tdc_ro_fast_code | mptdc_axis_core.axis_core_instances.ro_fast_code_i | internal | connect_direct | Shared fast RO code |
| pkt_valid_o | output | 1 | clk_sys | async_rst_n | pkt_valid_o | tdc_axis_wrapper.u_tdc_r/u_tdc_y/u_tdc_b.pkt_valid_o | internal | connect_direct | Packet stream to wrapper then bundle |
| pkt_ready_i | input | 1 | clk_sys | async_rst_n | pkt_ready_i | mptdc_axis_core.axis_core_instances.pkt_ready_i | internal | connect_direct | Backpressure from bundle through wrapper |
| pkt_data_o | output | NARROW_W | clk_sys | async_rst_n | pkt_data_o | tdc_axis_wrapper.u_tdc_r/u_tdc_y/u_tdc_b.pkt_data_o | internal | connect_direct | Packet stream data |
| pkt_sop_o | output | 1 | clk_sys | async_rst_n | pkt_sop_o | tdc_axis_wrapper.u_tdc_r/u_tdc_y/u_tdc_b.pkt_sop_o | internal | connect_direct | Packet start of packet |
| pkt_eop_o | output | 1 | clk_sys | async_rst_n | pkt_eop_o | tdc_axis_wrapper.u_tdc_r/u_tdc_y/u_tdc_b.pkt_eop_o | internal | connect_direct | Packet end of packet |
| packet_active_o | output | 1 | clk_sys | async_rst_n | packet_active_o | tdc_axis_wrapper.u_tdc_r/u_tdc_y/u_tdc_b.packet_active_o | internal | connect_direct | Status through wrapper |
| packet_pending_o | output | 1 | clk_sys | async_rst_n | packet_pending_o | tdc_axis_wrapper.u_tdc_r/u_tdc_y/u_tdc_b.packet_pending_o | internal | connect_direct | Status through wrapper |
| ready_o | output | 1 | clk_sys | async_rst_n | ready_o | tdc_axis_wrapper.u_tdc_r/u_tdc_y/u_tdc_b.ready_o | internal | connect_direct | Status through wrapper |
| busy_o | output | 1 | clk_sys | async_rst_n | busy_o | tdc_axis_wrapper.u_tdc_r/u_tdc_y/u_tdc_b.busy_o | internal | connect_direct | Status through wrapper |
| fifo_full_o | output | 1 | clk_sys | async_rst_n | fifo_full_o | tdc_axis_wrapper.u_tdc_r/u_tdc_y/u_tdc_b.fifo_full_o | internal | connect_direct | Status through wrapper |
