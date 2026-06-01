# Genus Summary: `20260528_o1c_macro_binding_genus`

## Timing Groups

| Group | WNS (ps) | TNS (ps) | Paths |
|---|---:|---:|---:|
| `clk_osc_fast_tap2` | -3044.9 | -187711.1 | 72 |
| `clk_osc_fast_tap3` | -3037.9 | -186622.2 | 72 |
| `clk_osc_fast_tap1` | -3024.0 | -185935.2 | 72 |
| `clk_osc_fast_tap4` | -2991.1 | -184581.3 | 72 |
| `clk_osc_fast_tap5` | -2946.9 | -181843.2 | 72 |
| `clk_osc_fast_tap7` | -2942.1 | -179010.7 | 72 |
| `clk_osc_fast_tap6` | -2896.9 | -178943.1 | 72 |
| `clk_osc_fast` | -2742.9 | -201092.8 | 94 |
| `clk_osc_slow` | -2613.1 | -50264.2 | 22 |
| `clk_sys` | -598.9 | -31436.5 | 74 |
| `clk_osc_slow_tap1` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap2` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap3` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap4` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap5` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap6` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap7` | No paths | 0.0 | 0 |

Total TNS: `-1567440.3` ps, violating paths: `694`
Max fanout: `4843` on `clk_sys`

## Detailed Path Coverage

- Parsed detailed paths: `674`
- Detailed paths by group: `{'clk_osc_fast_tap2': 56, 'clk_osc_fast_tap3': 48, 'clk_osc_fast_tap1': 54, 'clk_osc_fast_tap4': 39, 'clk_osc_fast_tap5': 3, 'clk_sys': 474}`
- Detailed paths by bucket: `{'D_oscillator_pd_measurement': 200, 'A_real_clk_sys_setup': 474}`

## Latch/DRV/Intent

- Latch count: `7`
- DRV totals: `{'max_transition': 122579}`
- Timing-intent counts: `{'unconnected_logic_driven_clocks': 0, 'sequential_data_pins_driven_by_a_clock_signal': 70, 'sequential_clock_pins_without_clock_waveform': 21, 'sequential_clock_pins_with_multiple_clock_waveforms': 0, 'generated_clocks_without_clock_waveform': 0, 'generated_clocks_with_incompatible_options': 0, 'generated_clocks_with_multi-master_clock': 0, 'paths_constrained_with_different_clocks': 0, 'loop-breaking_cells_for_combinational_feedback': 0, 'nets_with_multiple_drivers': 0, 'timing_exceptions_with_no_effect': 14, 'pins_ports_with_conflicting_case_constants': 0, 'inputs_without_clocked_external_delays': 5, 'outputs_without_clocked_external_delays': 0, 'inputs_without_external_driver_transition': 0, 'outputs_without_external_load': 0, 'exceptions_with_invalid_timing_start-_endpoints': 4}`

Intentional latch instances parsed:
- `u_core_u_frontend_active_ctx_q_reg[0]`
- `u_core_u_frontend_ctx_drain_q_reg[0]`
- `u_core_u_frontend_ctx_drain_q_reg[1]`
- `u_core_u_frontend_start_accept_seen_q_reg`
- `u_core_u_frontend_start_latched_q_reg`
- `u_core_u_frontend_start_reject_seen_q_reg`
- `u_core_u_frontend_stop_latched_q_reg`
