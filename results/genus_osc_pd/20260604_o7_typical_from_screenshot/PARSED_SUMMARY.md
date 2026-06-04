# Genus Summary: `20260604_o7_typical_from_screenshot`

## Timing Groups

| Group | WNS (ps) | TNS (ps) | Paths |
|---|---:|---:|---:|
| `clk_osc_fast_tap5` | -424.5 | -31081.4 | 87 |
| `clk_osc_fast_tap1` | -424.1 | -30799.7 | 87 |
| `clk_osc_fast_tap2` | -424.1 | -30799.7 | 87 |
| `clk_osc_fast_tap3` | -424.1 | -30799.7 | 87 |
| `clk_osc_fast_tap4` | -424.1 | -30875.3 | 87 |
| `clk_osc_fast_tap6` | -424.1 | -30799.7 | 87 |
| `clk_osc_fast_tap7` | -424.1 | -30799.7 | 87 |
| `clk_sys` | 2.3 | 0.0 | 0 |
| `clk_osc_slow` | 18.8 | 0.0 | 0 |
| `clk_osc_slow_tap1` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap2` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap3` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap4` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap5` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap6` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap7` | No paths | 0.0 | 0 |

Total TNS: `-247033.3` ps, violating paths: `696`
Max fanout: `4859` on `clk_sys`

## Detailed Path Coverage

- Parsed detailed paths: `556`
- Detailed paths by group: `{'clk_osc_fast_tap5': 44, 'clk_osc_fast_tap7': 17, 'clk_osc_fast_tap6': 17, 'clk_osc_fast_tap4': 17, 'clk_osc_fast_tap3': 16, 'clk_osc_fast_tap2': 16, 'clk_osc_fast_tap1': 16, 'clk_osc_fast': 113, 'clk_sys': 300}`
- Detailed paths by bucket: `{'D_oscillator_pd_measurement': 256, 'A_real_clk_sys_setup': 300}`

## Latch/DRV/Intent

- Latch count: `7`
- DRV totals: `{'max_transition': 5748}`
- Timing-intent counts: `{'unconnected_logic_driven_clocks': 0, 'sequential_data_pins_driven_by_a_clock_signal': 70, 'sequential_clock_pins_without_clock_waveform': 78, 'sequential_clock_pins_with_multiple_clock_waveforms': 0, 'generated_clocks_without_clock_waveform': 0, 'generated_clocks_with_incompatible_options': 0, 'generated_clocks_with_multi-master_clock': 0, 'paths_constrained_with_different_clocks': 0, 'loop-breaking_cells_for_combinational_feedback': 0, 'nets_with_multiple_drivers': 0, 'timing_exceptions_with_no_effect': 10, 'pins_ports_with_conflicting_case_constants': 0, 'inputs_without_clocked_external_delays': 5, 'outputs_without_clocked_external_delays': 0, 'inputs_without_external_driver_transition': 0, 'outputs_without_external_load': 0, 'exceptions_with_invalid_timing_start-_endpoints': 0}`

Intentional latch instances parsed:
- `u_core_u_frontend_active_ctx_q_reg[0]`
- `u_core_u_frontend_ctx_drain_q_reg[0]`
- `u_core_u_frontend_ctx_drain_q_reg[1]`
- `u_core_u_frontend_start_accept_seen_q_reg`
- `u_core_u_frontend_start_latched_q_reg`
- `u_core_u_frontend_start_reject_seen_q_reg`
- `u_core_u_frontend_stop_latched_q_reg`
