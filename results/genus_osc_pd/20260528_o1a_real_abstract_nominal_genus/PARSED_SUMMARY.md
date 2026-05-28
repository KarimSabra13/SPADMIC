# Genus Summary: `20260528_o1a_real_abstract_nominal_genus`

## Timing Groups

| Group | WNS (ps) | TNS (ps) | Paths |
|---|---:|---:|---:|
| `clk_osc_fast_tap1` | -3163.0 | -193058.8 | 72 |
| `clk_osc_fast_tap2` | -3118.6 | -190798.8 | 72 |
| `clk_osc_fast_tap3` | -3069.2 | -189401.3 | 72 |
| `clk_osc_fast_tap4` | -3018.6 | -185043.3 | 72 |
| `clk_osc_fast_tap5` | -2968.6 | -182545.8 | 72 |
| `clk_osc_fast_tap6` | -2913.0 | -179873.7 | 72 |
| `clk_osc_fast_tap7` | -2868.6 | -176765.7 | 72 |
| `clk_osc_slow` | -2711.6 | -50463.8 | 22 |
| `clk_osc_fast` | -2574.5 | -197983.8 | 94 |
| `clk_sys` | -720.4 | -37235.0 | 77 |
| `clk_osc_slow_tap1` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap2` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap3` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap4` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap5` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap6` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap7` | No paths | 0.0 | 0 |

Total TNS: `-1583170.0` ps, violating paths: `697`
Max fanout: `4910` on `clk_sys`

## Detailed Path Coverage

- Parsed detailed paths: `677`
- Detailed paths by group: `{'clk_osc_fast_tap1': 56, 'clk_osc_fast_tap2': 55, 'clk_osc_fast_tap3': 52, 'clk_osc_fast_tap4': 36, 'clk_osc_fast_tap5': 1, 'clk_sys': 477}`
- Detailed paths by bucket: `{'D_oscillator_pd_measurement': 200, 'A_real_clk_sys_setup': 477}`

## Latch/DRV/Intent

- Latch count: `7`
- DRV totals: `{'max_transition': 256097}`
- Timing-intent counts: `{'unconnected_logic_driven_clocks': 0, 'sequential_data_pins_driven_by_a_clock_signal': 69, 'sequential_clock_pins_without_clock_waveform': 21, 'sequential_clock_pins_with_multiple_clock_waveforms': 0, 'generated_clocks_without_clock_waveform': 0, 'generated_clocks_with_incompatible_options': 0, 'generated_clocks_with_multi-master_clock': 0, 'paths_constrained_with_different_clocks': 0, 'loop-breaking_cells_for_combinational_feedback': 0, 'nets_with_multiple_drivers': 0, 'timing_exceptions_with_no_effect': 14, 'pins_ports_with_conflicting_case_constants': 0, 'inputs_without_clocked_external_delays': 5, 'outputs_without_clocked_external_delays': 0, 'inputs_without_external_driver_transition': 0, 'outputs_without_external_load': 0, 'exceptions_with_invalid_timing_start-_endpoints': 4}`

Intentional latch instances parsed:
- `u_core_u_frontend_active_ctx_q_reg[0]`
- `u_core_u_frontend_ctx_drain_q_reg[0]`
- `u_core_u_frontend_ctx_drain_q_reg[1]`
- `u_core_u_frontend_start_accept_seen_q_reg`
- `u_core_u_frontend_start_latched_q_reg`
- `u_core_u_frontend_start_reject_seen_q_reg`
- `u_core_u_frontend_stop_latched_q_reg`
