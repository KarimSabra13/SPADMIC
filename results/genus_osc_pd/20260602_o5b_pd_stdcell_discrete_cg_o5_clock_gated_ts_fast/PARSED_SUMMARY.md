# Genus Summary: `20260602_o5b_pd_stdcell_discrete_cg_o5_clock_gated_ts_fast`

## Timing Groups

| Group | WNS (ps) | TNS (ps) | Paths |
|---|---:|---:|---:|
| `clk_osc_fast` | -1465.8 | -94864.1 | 80 |
| `clk_osc_fast_tap2` | -1462.9 | -90140.4 | 79 |
| `clk_osc_fast_tap5` | -1450.3 | -91908.8 | 79 |
| `clk_osc_fast_tap1` | -1408.1 | -91146.9 | 79 |
| `clk_osc_fast_tap3` | -1408.1 | -91146.9 | 79 |
| `clk_osc_fast_tap4` | -1408.1 | -91146.9 | 79 |
| `clk_osc_fast_tap6` | -1408.1 | -91146.9 | 79 |
| `clk_osc_fast_tap7` | -1408.1 | -91146.9 | 79 |
| `clk_sys` | -955.9 | -23287.7 | 91 |
| `clk_osc_slow` | -781.9 | -46257.1 | 64 |
| `clk_osc_slow_tap1` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap2` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap3` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap4` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap5` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap6` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap7` | No paths | 0.0 | 0 |

Total TNS: `-916612.6` ps, violating paths: `857`
Max fanout: `537` on `u_core_u_ctx_bank_rc_gclk`

## Detailed Path Coverage

- Parsed detailed paths: `652`
- Detailed paths by group: `{'cg_enable_group_clk_osc_fast_tap5': 8, 'cg_enable_group_clk_osc_fast': 8, 'cg_enable_group_clk_osc_fast_tap1': 8, 'cg_enable_group_clk_osc_fast_tap3': 8, 'cg_enable_group_clk_osc_fast_tap4': 8, 'cg_enable_group_clk_osc_fast_tap6': 8, 'cg_enable_group_clk_osc_fast_tap7': 8, 'cg_enable_group_clk_osc_fast_tap2': 8, 'clk_osc_fast': 73, 'clk_osc_fast_tap2': 18, 'clk_osc_fast_tap5': 14, 'clk_osc_fast_tap7': 18, 'clk_osc_fast_tap6': 18, 'clk_osc_fast_tap4': 17, 'clk_osc_fast_tap3': 17, 'clk_osc_fast_tap1': 17, 'clk_sys': 383, 'cg_enable_group_clk_sys': 13}`
- Detailed paths by bucket: `{'D_oscillator_pd_measurement': 256, 'A_real_clk_sys_setup': 383, 'unclassified': 13}`

## Latch/DRV/Intent

- Latch count: `175`
- DRV totals: `{'max_transition': 165687}`
- Timing-intent counts: `{'unconnected_logic_driven_clocks': 0, 'sequential_data_pins_driven_by_a_clock_signal': 70, 'sequential_clock_pins_without_clock_waveform': 78, 'sequential_clock_pins_with_multiple_clock_waveforms': 0, 'generated_clocks_without_clock_waveform': 0, 'generated_clocks_with_incompatible_options': 0, 'generated_clocks_with_multi-master_clock': 0, 'paths_constrained_with_different_clocks': 0, 'loop-breaking_cells_for_combinational_feedback': 0, 'nets_with_multiple_drivers': 0, 'timing_exceptions_with_no_effect': 10, 'pins_ports_with_conflicting_case_constants': 0, 'inputs_without_clocked_external_delays': 5, 'outputs_without_clocked_external_delays': 0, 'inputs_without_external_driver_transition': 0, 'outputs_without_external_load': 0, 'exceptions_with_invalid_timing_start-_endpoints': 0}`

Intentional latch instances parsed:
- `u_core_RC_CG_HIER_INST2/RC_CGIC_INST`
- `u_core_RC_CG_HIER_INST3/RC_CGIC_INST`
- `u_core_RC_CG_HIER_INST4/RC_CGIC_INST`
- `u_core_RC_CG_HIER_INST5/RC_CGIC_INST`
- `u_core_RC_CG_HIER_INST6/RC_CGIC_INST`
- `u_core_gen_pd_row[0].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[0].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[0].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[0].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[0].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[0].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[0].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[0].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[1].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[1].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[1].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[1].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[1].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[1].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[1].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[1].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[2].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[2].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[2].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[2].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[2].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[2].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[2].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[2].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[3].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[3].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[3].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[3].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[3].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[3].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[3].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[3].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[4].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[4].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[4].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[4].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[4].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[4].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[4].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[4].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[5].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[5].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[5].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[5].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[5].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[5].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[5].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[5].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[6].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[6].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[6].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[6].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[6].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[6].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[6].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[6].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[7].gen_pd_col[0].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[7].gen_pd_col[1].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[7].gen_pd_col[2].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[7].gen_pd_col[3].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[7].gen_pd_col[4].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[7].gen_pd_col[5].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[7].gen_pd_col[6].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_gen_pd_row[7].gen_pd_col[7].u_pd/RC_CG_HIER_INST26/RC_CGIC_INST`
- `u_core_u_ctx_bank_RC_CG_HIER_INST0/RC_CGIC_INST`
- `u_core_u_ctx_bank_RC_CG_HIER_INST1/RC_CGIC_INST`
- `u_core_u_drain_ctrl_RC_CG_HIER_INST10/RC_CGIC_INST`
- `u_core_u_drain_ctrl_RC_CG_HIER_INST11/RC_CGIC_INST`
- `u_core_u_drain_ctrl_RC_CG_HIER_INST12/RC_CGIC_INST`
- `u_core_u_drain_ctrl_RC_CG_HIER_INST13/RC_CGIC_INST`
- `u_core_u_drain_ctrl_RC_CG_HIER_INST14/RC_CGIC_INST`
- `u_core_u_drain_ctrl_RC_CG_HIER_INST15/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST28/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST29/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST30/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST31/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST32/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST33/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST34/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST35/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST36/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST37/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST38/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST39/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST40/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST41/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST42/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST43/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST44/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST45/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST46/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST47/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST48/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST49/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST50/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST51/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST52/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST53/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST54/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST55/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST56/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST57/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST58/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST59/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST60/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST61/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST62/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST63/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST64/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST65/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST66/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST67/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST68/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST69/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST70/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST71/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST72/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST73/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST74/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST75/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST76/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST77/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST78/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST79/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST80/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST81/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST82/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST83/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST84/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST85/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST86/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST87/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST88/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST89/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST90/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST91/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST92/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST93/RC_CGIC_INST`
- `u_core_u_fifo/RC_CG_HIER_INST94/RC_CGIC_INST`
- `u_core_u_hit_capture_bridge/RC_CG_HIER_INST16/RC_CGIC_INST`
- `u_core_u_meas_ctrl/RC_CG_HIER_INST17/RC_CGIC_INST`
- `u_core_u_meas_ctrl/RC_CG_HIER_INST18/RC_CGIC_INST`
- `u_core_u_meas_ctrl/RC_CG_HIER_INST19/RC_CGIC_INST`
- `u_core_u_meas_ctrl/RC_CG_HIER_INST20/RC_CGIC_INST`
- `u_core_u_narrow_tx/RC_CG_HIER_INST21/RC_CGIC_INST`
- `u_core_u_narrow_tx/RC_CG_HIER_INST22/RC_CGIC_INST`
- `u_core_u_narrow_tx/RC_CG_HIER_INST23/RC_CGIC_INST`
- `u_core_u_narrow_tx/RC_CG_HIER_INST24/RC_CGIC_INST`
- `u_core_u_narrow_tx/RC_CG_HIER_INST25/RC_CGIC_INST`
- `u_csr_RC_CG_HIER_INST7/RC_CGIC_INST`
- `u_csr_RC_CG_HIER_INST8/RC_CGIC_INST`
- `u_csr_RC_CG_HIER_INST9/RC_CGIC_INST`
- `u_csr_RC_CG_HIER_INST96/RC_CGIC_INST`
- `u_core_u_frontend_active_ctx_q_reg[0]`
- `u_core_u_frontend_ctx_drain_q_reg[0]`
- `u_core_u_frontend_ctx_drain_q_reg[1]`
- `u_core_u_frontend_start_accept_seen_q_reg`
- `u_core_u_frontend_start_latched_q_reg`
- `u_core_u_frontend_start_reject_seen_q_reg`
- `u_core_u_frontend_stop_latched_q_reg`
