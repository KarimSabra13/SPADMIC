# Genus Summary: `20260601_o1c2_fast_count_audit_genus`

## Timing Groups

| Group | WNS (ps) | TNS (ps) | Paths |
|---|---:|---:|---:|
| `clk_osc_fast_tap1` | -3051.4 | -188293.2 | 72 |
| `clk_osc_fast_tap2` | -2986.2 | -185116.5 | 72 |
| `clk_osc_fast_tap3` | -2943.9 | -182208.7 | 72 |
| `clk_osc_fast_tap4` | -2894.4 | -179322.7 | 72 |
| `clk_osc_fast_tap5` | -2851.3 | -175772.4 | 72 |
| `clk_osc_fast_tap6` | -2801.3 | -172984.4 | 72 |
| `clk_osc_fast_tap7` | -2749.9 | -170312.6 | 72 |
| `clk_osc_fast` | -2706.1 | -203839.5 | 94 |
| `clk_osc_slow` | -2590.6 | -50648.4 | 22 |
| `clk_sys` | -824.6 | -41995.3 | 60 |
| `clk_osc_slow_tap1` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap2` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap3` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap4` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap5` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap6` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap7` | No paths | 0.0 | 0 |

Total TNS: `-1550493.7` ps, violating paths: `680`
Max fanout: `4843` on `clk_sys`

## Detailed Path Coverage

- Parsed detailed paths: `660`
- Detailed paths by group: `{'clk_osc_fast_tap1': 56, 'clk_osc_fast_tap2': 56, 'clk_osc_fast_tap3': 56, 'clk_osc_fast_tap4': 32, 'clk_sys': 460}`
- Detailed paths by bucket: `{'D_oscillator_pd_measurement': 200, 'A_real_clk_sys_setup': 460}`

## Latch/DRV/Intent

- Latch count: `7`
- DRV totals: `{'max_transition': 248862}`
- Timing-intent counts: `{'unconnected_logic_driven_clocks': 0, 'sequential_data_pins_driven_by_a_clock_signal': 70, 'sequential_clock_pins_without_clock_waveform': 21, 'sequential_clock_pins_with_multiple_clock_waveforms': 0, 'generated_clocks_without_clock_waveform': 0, 'generated_clocks_with_incompatible_options': 0, 'generated_clocks_with_multi-master_clock': 0, 'paths_constrained_with_different_clocks': 0, 'loop-breaking_cells_for_combinational_feedback': 0, 'nets_with_multiple_drivers': 0, 'timing_exceptions_with_no_effect': 10, 'pins_ports_with_conflicting_case_constants': 0, 'inputs_without_clocked_external_delays': 5, 'outputs_without_clocked_external_delays': 0, 'inputs_without_external_driver_transition': 0, 'outputs_without_external_load': 0, 'exceptions_with_invalid_timing_start-_endpoints': 0}`

Intentional latch instances parsed:
- `u_core_u_frontend_active_ctx_q_reg[0]`
- `u_core_u_frontend_ctx_drain_q_reg[0]`
- `u_core_u_frontend_ctx_drain_q_reg[1]`
- `u_core_u_frontend_start_accept_seen_q_reg`
- `u_core_u_frontend_start_latched_q_reg`
- `u_core_u_frontend_start_reject_seen_q_reg`
- `u_core_u_frontend_stop_latched_q_reg`
