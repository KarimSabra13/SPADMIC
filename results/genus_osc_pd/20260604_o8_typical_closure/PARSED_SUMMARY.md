# Genus Summary: `20260604_o8_typical_closure`

## Timing Groups

| Group | WNS (ps) | TNS (ps) | Paths |
|---|---:|---:|---:|
| `clk_osc_fast_tap6` | -394.5 | -29715.8 | 87 |
| `clk_osc_fast_tap3` | -390.9 | -29385.9 | 87 |
| `clk_osc_fast_tap4` | -390.9 | -29384.9 | 87 |
| `clk_osc_fast_tap5` | -390.9 | -29386.7 | 87 |
| `clk_osc_fast_tap1` | -390.8 | -29486.3 | 87 |
| `clk_osc_fast_tap2` | -390.8 | -29486.1 | 87 |
| `clk_osc_fast_tap7` | -390.8 | -29487.5 | 87 |
| `clk_sys` | 2.1 | 0.0 | 0 |
| `clk_osc_slow` | 18.8 | 0.0 | 0 |
| `clk_osc_slow_tap1` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap2` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap3` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap4` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap5` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap6` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap7` | No paths | 0.0 | 0 |

Total TNS: `-237193.8` ps, violating paths: `696`
Max fanout: `4859` on `clk_sys`

## Detailed Path Coverage

- Parsed detailed paths: `705`
- Detailed paths by group: `{'clk_osc_fast': 104, 'clk_osc_fast_tap6': 46, 'clk_osc_fast_tap5': 16, 'clk_osc_fast_tap4': 16, 'clk_osc_fast_tap3': 16, 'clk_osc_fast_tap7': 20, 'clk_osc_fast_tap2': 20, 'clk_osc_fast_tap1': 18, 'clk_sys': 449}`
- Detailed paths by bucket: `{'D_oscillator_pd_measurement': 256, 'A_real_clk_sys_setup': 449}`

## Latch/DRV/Intent

- Latch count: `7`
- DRV totals: `{'max_transition': 23}`
- Timing-intent counts: `{'unconnected_logic_driven_clocks': 0, 'sequential_data_pins_driven_by_a_clock_signal': 70, 'sequential_clock_pins_without_clock_waveform': 78, 'sequential_clock_pins_with_multiple_clock_waveforms': 0, 'generated_clocks_without_clock_waveform': 0, 'generated_clocks_with_incompatible_options': 0, 'generated_clocks_with_multi-master_clock': 0, 'paths_constrained_with_different_clocks': 0, 'loop-breaking_cells_for_combinational_feedback': 0, 'nets_with_multiple_drivers': 0, 'timing_exceptions_with_no_effect': 10, 'pins_ports_with_conflicting_case_constants': 0, 'inputs_without_clocked_external_delays': 5, 'outputs_without_clocked_external_delays': 0, 'inputs_without_external_driver_transition': 0, 'outputs_without_external_load': 0, 'exceptions_with_invalid_timing_start-_endpoints': 0}`

Intentional latch instances parsed:
- `u_core_u_frontend_active_ctx_q_reg[0]`
- `u_core_u_frontend_ctx_drain_q_reg[0]`
- `u_core_u_frontend_ctx_drain_q_reg[1]`
- `u_core_u_frontend_start_accept_seen_q_reg`
- `u_core_u_frontend_start_latched_q_reg`
- `u_core_u_frontend_start_reject_seen_q_reg`
- `u_core_u_frontend_stop_latched_q_reg`
