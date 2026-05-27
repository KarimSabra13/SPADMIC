# Genus Summary: `20260527_1030_h1_drain_pipeline_genus`

## Timing Groups

| Group | WNS (ps) | TNS (ps) | Paths |
|---|---:|---:|---:|
| `clk_osc_fast_tap1` | -3045.0 | -187036.6 | 72 |
| `clk_osc_fast_tap2` | -2995.4 | -184833.8 | 72 |
| `clk_osc_fast_tap3` | -2987.3 | -184325.3 | 72 |
| `clk_osc_fast_tap7` | -2956.7 | -176381.6 | 72 |
| `clk_osc_fast_tap4` | -2895.5 | -179180.2 | 72 |
| `clk_osc_fast_tap6` | -2891.6 | -176286.9 | 72 |
| `clk_osc_fast_tap5` | -2887.7 | -177457.9 | 72 |
| `clk_osc_fast` | -2838.1 | -206013.9 | 94 |
| `clk_osc_slow` | -2764.8 | -51310.4 | 22 |
| `clk_sys` | -968.1 | -48974.7 | 72 |
| `clk_osc_slow_tap1` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap2` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap3` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap4` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap5` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap6` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap7` | No paths | 0.0 | 0 |

Total TNS: `-1571801.3` ps, violating paths: `692`
Max fanout: `4860` on `clk_sys`

## Detailed Path Coverage

- Parsed detailed paths: `634`
- Detailed paths by group: `{'clk_osc_fast_tap1': 56, 'clk_osc_fast_tap2': 56, 'clk_osc_fast_tap3': 56, 'clk_osc_fast_tap7': 16, 'clk_osc_fast_tap4': 12, 'clk_osc_fast_tap6': 4, 'clk_sys': 434}`
- Detailed paths by bucket: `{'D_oscillator_pd_measurement': 200, 'A_real_clk_sys_setup': 434}`

## Latch/DRV/Intent

- Latch count: `7`
- DRV totals: `{'max_transition': 213804}`
- Timing-intent counts: `{'unconnected_logic_driven_clocks': 0, 'sequential_data_pins_driven_by_a_clock_signal': 69, 'sequential_clock_pins_without_clock_waveform': 21, 'sequential_clock_pins_with_multiple_clock_waveforms': 0, 'generated_clocks_without_clock_waveform': 0, 'generated_clocks_with_incompatible_options': 0, 'generated_clocks_with_multi-master_clock': 0, 'paths_constrained_with_different_clocks': 0, 'loop-breaking_cells_for_combinational_feedback': 0, 'nets_with_multiple_drivers': 0, 'timing_exceptions_with_no_effect': 10, 'pins_ports_with_conflicting_case_constants': 0, 'inputs_without_clocked_external_delays': 5, 'outputs_without_clocked_external_delays': 0, 'inputs_without_external_driver_transition': 0, 'outputs_without_external_load': 0, 'exceptions_with_invalid_timing_start-_endpoints': 0}`

Intentional latch instances parsed:
- `u_core_u_frontend_active_ctx_q_reg[0]`
- `u_core_u_frontend_ctx_drain_q_reg[0]`
- `u_core_u_frontend_ctx_drain_q_reg[1]`
- `u_core_u_frontend_start_accept_seen_q_reg`
- `u_core_u_frontend_start_latched_q_reg`
- `u_core_u_frontend_start_reject_seen_q_reg`
- `u_core_u_frontend_stop_latched_q_reg`
