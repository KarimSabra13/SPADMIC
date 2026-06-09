# Timing Path Classification Summary

- Parsed paths: 600
- UNKNOWN_REVIEW_REQUIRED paths: 64

## WNS/TNS By Class

| Classification | Paths | WNS ps | TNS ps |
|---|---:|---:|---:|
| `UNKNOWN_REVIEW_REQUIRED` | 64 | -422.0 | -26199.0 |
| `OSC_FAST_REAL` | 336 | -320.0 | -27067.0 |
| `CLK_SYS_REAL` | 200 | 1.0 | 0.0 |

## WNS/TNS By Family

| Family | Paths | WNS ps | TNS ps |
|---|---:|---:|---:|
| `PHASE_BUFFER_CHAIN` | 64 | -422.0 | -26199.0 |
| `OTHER` | 140 | -320.0 | -24228.0 |
| `LOCAL_FAST_TAG_SELF` | 6 | -50.0 | -271.0 |
| `FAST_TAG_TO_PD_TS` | 186 | -40.0 | -2436.0 |
| `PD_HIT_TO_TS_FREEZE` | 4 | -37.0 | -132.0 |
| `CLK_SYS_OTHER` | 124 | 1.0 | 0.0 |
| `CLK_SYS_WATCHDOG` | 16 | 52.0 | 0.0 |
| `CLK_SYS_DRAIN` | 60 | 61.0 | 0.0 |

## Top Unknown Paths

- /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/timing_violations.rpt path 1: slack=-422 ps, group=clk_osc_fast_buf_tap6, start=`(F) u_core_u_phase_buf_slow/gen_phase_buf[0].u_drv/Q`, end=`(F) u_core_gen_pd_row[0].gen_pd_col[6].u_pd/q1_reg/D`
- /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/timing_violations.rpt path 2: slack=-421 ps, group=clk_osc_fast_buf_tap6, start=`(F) u_core_u_phase_buf_slow/gen_phase_buf[5].u_drv/Q`, end=`(F) u_core_gen_pd_row[5].gen_pd_col[6].u_pd/q1_reg/D`
- /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/timing_violations.rpt path 3: slack=-421 ps, group=clk_osc_fast_buf_tap6, start=`(F) u_core_u_phase_buf_slow/gen_phase_buf[3].u_drv/Q`, end=`(F) u_core_gen_pd_row[3].gen_pd_col[6].u_pd/q1_reg/D`
- /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/timing_violations.rpt path 4: slack=-421 ps, group=clk_osc_fast_buf_tap6, start=`(F) u_core_u_phase_buf_slow/gen_phase_buf[4].u_drv/Q`, end=`(F) u_core_gen_pd_row[4].gen_pd_col[6].u_pd/q1_reg/D`
- /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/timing_violations.rpt path 5: slack=-421 ps, group=clk_osc_fast_buf_tap7, start=`(F) u_core_u_phase_buf_slow/gen_phase_buf[7].u_drv/Q`, end=`(F) u_core_gen_pd_row[7].gen_pd_col[7].u_pd/q1_reg/D`
- /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/timing_violations.rpt path 6: slack=-420 ps, group=clk_osc_fast_buf_tap6, start=`(F) u_core_u_phase_buf_slow/gen_phase_buf[7].u_drv/Q`, end=`(F) u_core_gen_pd_row[7].gen_pd_col[6].u_pd/q1_reg/D`
- /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/timing_violations.rpt path 7: slack=-420 ps, group=clk_osc_fast_buf_tap6, start=`(F) u_core_u_phase_buf_slow/gen_phase_buf[6].u_drv/Q`, end=`(F) u_core_gen_pd_row[6].gen_pd_col[6].u_pd/q1_reg/D`
- /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/timing_violations.rpt path 8: slack=-420 ps, group=clk_osc_fast_buf_tap7, start=`(F) u_core_u_phase_buf_slow/gen_phase_buf[4].u_drv/Q`, end=`(F) u_core_gen_pd_row[4].gen_pd_col[7].u_pd/q1_reg/D`
- /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/timing_violations.rpt path 9: slack=-419 ps, group=clk_osc_fast_buf_tap7, start=`(F) u_core_u_phase_buf_slow/gen_phase_buf[1].u_drv/Q`, end=`(F) u_core_gen_pd_row[1].gen_pd_col[7].u_pd/q1_reg/D`
- /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/timing_violations.rpt path 10: slack=-413 ps, group=clk_osc_fast_buf_tap6, start=`(F) u_core_u_phase_buf_slow/gen_phase_buf[1].u_drv/Q`, end=`(F) u_core_gen_pd_row[1].gen_pd_col[6].u_pd/q1_reg/D`
- /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/timing_violations.rpt path 11: slack=-413 ps, group=clk_osc_fast_buf_tap6, start=`(F) u_core_u_phase_buf_slow/gen_phase_buf[2].u_drv/Q`, end=`(F) u_core_gen_pd_row[2].gen_pd_col[6].u_pd/q1_reg/D`
- /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/timing_violations.rpt path 12: slack=-411 ps, group=clk_osc_fast_buf_tap2, start=`(F) u_core_u_phase_buf_slow/gen_phase_buf[7].u_drv/Q`, end=`(F) u_core_gen_pd_row[7].gen_pd_col[2].u_pd/q1_reg/D`
- /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/timing_violations.rpt path 13: slack=-411 ps, group=clk_osc_fast_buf_tap7, start=`(F) u_core_u_phase_buf_slow/gen_phase_buf[6].u_drv/Q`, end=`(F) u_core_gen_pd_row[6].gen_pd_col[7].u_pd/q1_reg/D`
- /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/timing_violations.rpt path 14: slack=-411 ps, group=clk_osc_fast_buf_tap2, start=`(F) u_core_u_phase_buf_slow/gen_phase_buf[6].u_drv/Q`, end=`(F) u_core_gen_pd_row[6].gen_pd_col[2].u_pd/q1_reg/D`
- /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/timing_violations.rpt path 15: slack=-411 ps, group=clk_osc_fast_buf_tap2, start=`(F) u_core_u_phase_buf_slow/gen_phase_buf[5].u_drv/Q`, end=`(F) u_core_gen_pd_row[5].gen_pd_col[2].u_pd/q1_reg/D`
- /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/timing_violations.rpt path 16: slack=-411 ps, group=clk_osc_fast_buf_tap2, start=`(F) u_core_u_phase_buf_slow/gen_phase_buf[4].u_drv/Q`, end=`(F) u_core_gen_pd_row[4].gen_pd_col[2].u_pd/q1_reg/D`
- /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/timing_violations.rpt path 17: slack=-411 ps, group=clk_osc_fast_buf_tap7, start=`(F) u_core_u_phase_buf_slow/gen_phase_buf[3].u_drv/Q`, end=`(F) u_core_gen_pd_row[3].gen_pd_col[7].u_pd/q1_reg/D`
- /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/timing_violations.rpt path 18: slack=-411 ps, group=clk_osc_fast_buf_tap2, start=`(F) u_core_u_phase_buf_slow/gen_phase_buf[1].u_drv/Q`, end=`(F) u_core_gen_pd_row[1].gen_pd_col[2].u_pd/q1_reg/D`
- /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/timing_violations.rpt path 19: slack=-411 ps, group=clk_osc_fast_buf_tap4, start=`(F) u_core_u_phase_buf_slow/gen_phase_buf[7].u_drv/Q`, end=`(F) u_core_gen_pd_row[7].gen_pd_col[4].u_pd/q1_reg/D`
- /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/genus_osc_pd/20260609_o13_abs3_clock_cdc_repair/timing_violations.rpt path 20: slack=-411 ps, group=clk_osc_fast_buf_tap1, start=`(F) u_core_u_phase_buf_slow/gen_phase_buf[7].u_drv/Q`, end=`(F) u_core_gen_pd_row[7].gen_pd_col[1].u_pd/q1_reg/D`
