# Genus Summary: `20260602_o4_muxless_tags_r600_o4_r600_closure`

## Timing Groups

| Group | WNS (ps) | TNS (ps) | Paths |
|---|---:|---:|---:|
| `clk_osc_fast` | -1316.4 | -95892.2 | 88 |
| `clk_osc_fast_tap3` | -1316.4 | -96332.9 | 87 |
| `clk_osc_fast_tap5` | -1316.4 | -96498.2 | 87 |
| `clk_osc_fast_tap6` | -1316.4 | -96338.8 | 87 |
| `clk_osc_fast_tap7` | -1316.4 | -96637.6 | 87 |
| `clk_osc_fast_tap1` | -1316.3 | -96199.8 | 87 |
| `clk_osc_fast_tap2` | -1316.3 | -96019.7 | 87 |
| `clk_osc_fast_tap4` | -1316.3 | -96589.5 | 87 |
| `clk_sys` | -764.6 | -44257.1 | 179 |
| `clk_osc_slow` | -114.9 | -3551.3 | 64 |
| `clk_osc_slow_tap1` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap2` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap3` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap4` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap5` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap6` | No paths | 0.0 | 0 |
| `clk_osc_slow_tap7` | No paths | 0.0 | 0 |

Total TNS: `-818317.1` ps, violating paths: `940`
Max fanout: `4859` on `clk_sys`

## Detailed Path Coverage

- Parsed detailed paths: `805`
- Detailed paths by group: `{'clk_osc_fast_tap6': 31, 'clk_osc_fast_tap3': 10, 'clk_osc_fast_tap7': 22, 'clk_osc_fast_tap5': 38, 'clk_osc_fast': 92, 'clk_osc_fast_tap4': 13, 'clk_osc_fast_tap1': 31, 'clk_osc_fast_tap2': 19, 'clk_sys': 549}`
- Detailed paths by bucket: `{'D_oscillator_pd_measurement': 256, 'A_real_clk_sys_setup': 549}`

## Latch/DRV/Intent

- Latch count: `7`
- DRV totals: `{'max_transition': 253004}`
- Timing-intent counts: `{'unconnected_logic_driven_clocks': 0, 'sequential_data_pins_driven_by_a_clock_signal': 70, 'sequential_clock_pins_without_clock_waveform': 78, 'sequential_clock_pins_with_multiple_clock_waveforms': 0, 'generated_clocks_without_clock_waveform': 0, 'generated_clocks_with_incompatible_options': 0, 'generated_clocks_with_multi-master_clock': 0, 'paths_constrained_with_different_clocks': 0, 'loop-breaking_cells_for_combinational_feedback': 0, 'nets_with_multiple_drivers': 0, 'timing_exceptions_with_no_effect': 10, 'pins_ports_with_conflicting_case_constants': 0, 'inputs_without_clocked_external_delays': 5, 'outputs_without_clocked_external_delays': 0, 'inputs_without_external_driver_transition': 0, 'outputs_without_external_load': 0, 'exceptions_with_invalid_timing_start-_endpoints': 0}`

Intentional latch instances parsed:
- `u_core_u_frontend_active_ctx_q_reg[0]`
- `u_core_u_frontend_ctx_drain_q_reg[0]`
- `u_core_u_frontend_ctx_drain_q_reg[1]`
- `u_core_u_frontend_start_accept_seen_q_reg`
- `u_core_u_frontend_start_latched_q_reg`
- `u_core_u_frontend_start_reject_seen_q_reg`
- `u_core_u_frontend_stop_latched_q_reg`
