# Genus Summary: `20260602_o5_pd_stdcell_closure_o5_noreset_ts_fast`

## Timing Groups

| Group | WNS (ps) | TNS (ps) | Paths |
|---|---:|---:|---:|
| `clk_osc_fast_tap3` | -1785.8 | -142420.4 | 87 |
| `clk_osc_fast_tap4` | -1785.8 | -142404.6 | 87 |
| `clk_osc_fast_tap5` | -1785.8 | -142412.8 | 87 |
| `clk_osc_fast_tap6` | -1785.8 | -142484.2 | 87 |
| `clk_osc_fast_tap1` | -1777.0 | -142038.6 | 87 |
| `clk_osc_fast_tap2` | -1777.0 | -142093.6 | 87 |
| `clk_osc_fast_tap7` | -1777.0 | -142110.0 | 87 |
| `clk_osc_fast` | -1754.1 | -142008.9 | 88 |
| `clk_sys` | -1129.6 | -68194.6 | 110 |
| `clk_osc_slow` | -781.9 | -46794.4 | 64 |
| `clk_osc_slow_tap1` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap2` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap3` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap4` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap5` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap6` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap7` | No paths | 0.0 | 0 |

Total TNS: `-1252962.1` ps, violating paths: `871`
Max fanout: `4859` on `clk_sys`

## Detailed Path Coverage

- Parsed detailed paths: `656`
- Detailed paths by group: `{'clk_osc_fast_tap6': 29, 'clk_osc_fast_tap5': 27, 'clk_osc_fast_tap4': 21, 'clk_osc_fast_tap3': 27, 'clk_osc_fast_tap7': 32, 'clk_osc_fast_tap2': 32, 'clk_osc_fast_tap1': 32, 'clk_osc_fast': 56, 'clk_sys': 400}`
- Detailed paths by bucket: `{'D_oscillator_pd_measurement': 256, 'A_real_clk_sys_setup': 400}`

## Latch/DRV/Intent

- Latch count: `7`
- DRV totals: `{'max_transition': 414681}`
- Timing-intent counts: `{'unconnected_logic_driven_clocks': 0, 'sequential_data_pins_driven_by_a_clock_signal': 70, 'sequential_clock_pins_without_clock_waveform': 78, 'sequential_clock_pins_with_multiple_clock_waveforms': 0, 'generated_clocks_without_clock_waveform': 0, 'generated_clocks_with_incompatible_options': 0, 'generated_clocks_with_multi-master_clock': 0, 'paths_constrained_with_different_clocks': 0, 'loop-breaking_cells_for_combinational_feedback': 0, 'nets_with_multiple_drivers': 0, 'timing_exceptions_with_no_effect': 10, 'pins_ports_with_conflicting_case_constants': 0, 'inputs_without_clocked_external_delays': 5, 'outputs_without_clocked_external_delays': 0, 'inputs_without_external_driver_transition': 0, 'outputs_without_external_load': 0, 'exceptions_with_invalid_timing_start-_endpoints': 0}`

Intentional latch instances parsed:
- `u_core_u_frontend_active_ctx_q_reg[0]`
- `u_core_u_frontend_ctx_drain_q_reg[0]`
- `u_core_u_frontend_ctx_drain_q_reg[1]`
- `u_core_u_frontend_start_accept_seen_q_reg`
- `u_core_u_frontend_start_latched_q_reg`
- `u_core_u_frontend_start_reject_seen_q_reg`
- `u_core_u_frontend_stop_latched_q_reg`
