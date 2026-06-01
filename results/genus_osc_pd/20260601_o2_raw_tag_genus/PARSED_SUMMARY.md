# Genus Summary: `20260601_o2_raw_tag_genus`

## Timing Groups

| Group | WNS (ps) | TNS (ps) | Paths |
|---|---:|---:|---:|
| `clk_osc_slow` | -2813.8 | -50635.5 | 22 |
| `clk_osc_fast` | -2582.3 | -208414.3 | 102 |
| `clk_osc_fast_tap1` | -2334.8 | -184090.7 | 87 |
| `clk_osc_fast_tap2` | -2334.8 | -182775.3 | 87 |
| `clk_osc_fast_tap3` | -2334.8 | -185127.3 | 87 |
| `clk_osc_fast_tap4` | -2334.8 | -185193.5 | 87 |
| `clk_osc_fast_tap5` | -2334.8 | -184570.2 | 87 |
| `clk_osc_fast_tap7` | -2334.8 | -184570.4 | 87 |
| `clk_osc_fast_tap6` | -2293.2 | -179180.6 | 87 |
| `clk_sys` | -642.2 | -35632.7 | 64 |
| `clk_osc_slow_tap1` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap2` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap3` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap4` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap5` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap6` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap7` | No paths | 0.0 | 0 |

Total TNS: `-1580190.5` ps, violating paths: `797`
Max fanout: `4843` on `clk_sys`

## Detailed Path Coverage

- Parsed detailed paths: `964`
- Detailed paths by group: `{'clk_osc_slow': 11, 'clk_osc_fast': 61, 'clk_osc_fast_tap7': 26, 'clk_osc_fast_tap5': 68, 'clk_osc_fast_tap4': 85, 'clk_osc_fast_tap3': 85, 'clk_osc_fast_tap1': 75, 'clk_osc_fast_tap2': 62, 'clk_osc_fast_tap6': 27, 'clk_sys': 464}`
- Detailed paths by bucket: `{'D_oscillator_pd_measurement': 500, 'A_real_clk_sys_setup': 464}`

## Latch/DRV/Intent

- Latch count: `7`
- DRV totals: `{'max_transition': 218008}`
- Timing-intent counts: `{'unconnected_logic_driven_clocks': 0, 'sequential_data_pins_driven_by_a_clock_signal': 70, 'sequential_clock_pins_without_clock_waveform': 21, 'sequential_clock_pins_with_multiple_clock_waveforms': 0, 'generated_clocks_without_clock_waveform': 0, 'generated_clocks_with_incompatible_options': 0, 'generated_clocks_with_multi-master_clock': 0, 'paths_constrained_with_different_clocks': 0, 'loop-breaking_cells_for_combinational_feedback': 0, 'nets_with_multiple_drivers': 0, 'timing_exceptions_with_no_effect': 10, 'pins_ports_with_conflicting_case_constants': 0, 'inputs_without_clocked_external_delays': 5, 'outputs_without_clocked_external_delays': 0, 'inputs_without_external_driver_transition': 0, 'outputs_without_external_load': 0, 'exceptions_with_invalid_timing_start-_endpoints': 0}`

Intentional latch instances parsed:
- `u_core_u_frontend_active_ctx_q_reg[0]`
- `u_core_u_frontend_ctx_drain_q_reg[0]`
- `u_core_u_frontend_ctx_drain_q_reg[1]`
- `u_core_u_frontend_start_accept_seen_q_reg`
- `u_core_u_frontend_start_latched_q_reg`
- `u_core_u_frontend_start_reject_seen_q_reg`
- `u_core_u_frontend_stop_latched_q_reg`
