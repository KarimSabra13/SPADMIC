# Fast Count Capture Summary

- Parsed fast-counter to nfast_hit paths: `252`
- Worst slack: `-3051.0 ps`

## By Timing Group

| Group | Paths |
|---|---:|
| `clk_osc_fast_tap1` | 56 |
| `clk_osc_fast_tap2` | 56 |
| `clk_osc_fast_tap3` | 56 |
| `clk_osc_fast` | 52 |
| `clk_osc_fast_tap4` | 32 |

## By Fast Tap / PD Column

| Key | Paths | Worst Slack (ps) |
|---|---:|---:|
| `1` | 56 | -3051.0 |
| `2` | 56 | -2986.0 |
| `3` | 56 | -2944.0 |
| `4` | 32 | -2894.0 |
| `0` | 52 | -2699.0 |

## By Slow Tap / PD Row

| Key | Paths | Worst Slack (ps) |
|---|---:|---:|
| `0` | 33 | -3051.0 |
| `1` | 30 | -3051.0 |
| `2` | 31 | -3051.0 |
| `3` | 32 | -3051.0 |
| `4` | 31 | -3051.0 |
| `5` | 33 | -3051.0 |
| `6` | 30 | -3050.0 |
| `7` | 32 | -3048.0 |

## By Fast Counter Launch Bit

| Key | Paths | Worst Slack (ps) |
|---|---:|---:|
| `4` | 40 | -3051.0 |
| `0` | 40 | -3050.0 |
| `5` | 38 | -3043.0 |
| `1` | 35 | -3036.0 |
| `3` | 36 | -3035.0 |
| `2` | 31 | -3005.0 |
| `6` | 32 | -2977.0 |

## By nfast_hit Capture Bit

| Key | Paths | Worst Slack (ps) |
|---|---:|---:|
| `4` | 40 | -3051.0 |
| `0` | 40 | -3050.0 |
| `5` | 38 | -3043.0 |
| `1` | 35 | -3036.0 |
| `3` | 36 | -3035.0 |
| `2` | 31 | -3005.0 |
| `6` | 32 | -2977.0 |

## Worst 20 Paths

- slack `-3051 ps`, group `clk_osc_fast_tap1`, nf `1`, ns `3`, bit `4`: `(R) u_core_u_fast_cnt_bin_q_reg[4]/C` -> `(F) u_core_gen_pd_row[3].gen_pd_col[1].u_pd/nfast_hit_latched_reg[4]/D`
- slack `-3051 ps`, group `clk_osc_fast_tap1`, nf `1`, ns `0`, bit `4`: `(R) u_core_u_fast_cnt_bin_q_reg[4]/C` -> `(F) u_core_gen_pd_row[0].gen_pd_col[1].u_pd/nfast_hit_latched_reg[4]/D`
- slack `-3051 ps`, group `clk_osc_fast_tap1`, nf `1`, ns `5`, bit `4`: `(R) u_core_u_fast_cnt_bin_q_reg[4]/C` -> `(F) u_core_gen_pd_row[5].gen_pd_col[1].u_pd/nfast_hit_latched_reg[4]/D`
- slack `-3051 ps`, group `clk_osc_fast_tap1`, nf `1`, ns `4`, bit `4`: `(R) u_core_u_fast_cnt_bin_q_reg[4]/C` -> `(F) u_core_gen_pd_row[4].gen_pd_col[1].u_pd/nfast_hit_latched_reg[4]/D`
- slack `-3051 ps`, group `clk_osc_fast_tap1`, nf `1`, ns `2`, bit `4`: `(R) u_core_u_fast_cnt_bin_q_reg[4]/C` -> `(F) u_core_gen_pd_row[2].gen_pd_col[1].u_pd/nfast_hit_latched_reg[4]/D`
- slack `-3051 ps`, group `clk_osc_fast_tap1`, nf `1`, ns `1`, bit `4`: `(R) u_core_u_fast_cnt_bin_q_reg[4]/C` -> `(F) u_core_gen_pd_row[1].gen_pd_col[1].u_pd/nfast_hit_latched_reg[4]/D`
- slack `-3050 ps`, group `clk_osc_fast_tap1`, nf `1`, ns `6`, bit `0`: `(R) u_core_u_fast_cnt_bin_q_reg[0]/C` -> `(F) u_core_gen_pd_row[6].gen_pd_col[1].u_pd/nfast_hit_latched_reg[0]/D`
- slack `-3048 ps`, group `clk_osc_fast_tap1`, nf `1`, ns `7`, bit `4`: `(R) u_core_u_fast_cnt_bin_q_reg[4]/C` -> `(F) u_core_gen_pd_row[7].gen_pd_col[1].u_pd/nfast_hit_latched_reg[4]/D`
- slack `-3048 ps`, group `clk_osc_fast_tap1`, nf `1`, ns `3`, bit `0`: `(R) u_core_u_fast_cnt_bin_q_reg[0]/C` -> `(F) u_core_gen_pd_row[3].gen_pd_col[1].u_pd/nfast_hit_latched_reg[0]/D`
- slack `-3043 ps`, group `clk_osc_fast_tap1`, nf `1`, ns `3`, bit `5`: `(R) u_core_u_fast_cnt_bin_q_reg[5]/C` -> `(F) u_core_gen_pd_row[3].gen_pd_col[1].u_pd/nfast_hit_latched_reg[5]/D`
- slack `-3043 ps`, group `clk_osc_fast_tap1`, nf `1`, ns `2`, bit `5`: `(R) u_core_u_fast_cnt_bin_q_reg[5]/C` -> `(F) u_core_gen_pd_row[2].gen_pd_col[1].u_pd/nfast_hit_latched_reg[5]/D`
- slack `-3043 ps`, group `clk_osc_fast_tap1`, nf `1`, ns `0`, bit `5`: `(R) u_core_u_fast_cnt_bin_q_reg[5]/C` -> `(F) u_core_gen_pd_row[0].gen_pd_col[1].u_pd/nfast_hit_latched_reg[5]/D`
- slack `-3043 ps`, group `clk_osc_fast_tap1`, nf `1`, ns `6`, bit `4`: `(R) u_core_u_fast_cnt_bin_q_reg[4]/C` -> `(F) u_core_gen_pd_row[6].gen_pd_col[1].u_pd/nfast_hit_latched_reg[4]/D`
- slack `-3036 ps`, group `clk_osc_fast_tap1`, nf `1`, ns `2`, bit `1`: `(R) u_core_u_fast_cnt_bin_q_reg[1]/C` -> `(F) u_core_gen_pd_row[2].gen_pd_col[1].u_pd/nfast_hit_latched_reg[1]/D`
- slack `-3036 ps`, group `clk_osc_fast_tap1`, nf `1`, ns `0`, bit `1`: `(R) u_core_u_fast_cnt_bin_q_reg[1]/C` -> `(F) u_core_gen_pd_row[0].gen_pd_col[1].u_pd/nfast_hit_latched_reg[1]/D`
- slack `-3035 ps`, group `clk_osc_fast_tap1`, nf `1`, ns `7`, bit `3`: `(R) u_core_u_fast_cnt_bin_q_reg[3]/C` -> `(F) u_core_gen_pd_row[7].gen_pd_col[1].u_pd/nfast_hit_latched_reg[3]/D`
- slack `-3035 ps`, group `clk_osc_fast_tap1`, nf `1`, ns `6`, bit `3`: `(R) u_core_u_fast_cnt_bin_q_reg[3]/C` -> `(F) u_core_gen_pd_row[6].gen_pd_col[1].u_pd/nfast_hit_latched_reg[3]/D`
- slack `-3034 ps`, group `clk_osc_fast_tap1`, nf `1`, ns `7`, bit `5`: `(R) u_core_u_fast_cnt_bin_q_reg[5]/C` -> `(F) u_core_gen_pd_row[7].gen_pd_col[1].u_pd/nfast_hit_latched_reg[5]/D`
- slack `-3034 ps`, group `clk_osc_fast_tap1`, nf `1`, ns `5`, bit `5`: `(R) u_core_u_fast_cnt_bin_q_reg[5]/C` -> `(F) u_core_gen_pd_row[5].gen_pd_col[1].u_pd/nfast_hit_latched_reg[5]/D`
- slack `-3034 ps`, group `clk_osc_fast_tap1`, nf `1`, ns `2`, bit `0`: `(R) u_core_u_fast_cnt_bin_q_reg[0]/C` -> `(F) u_core_gen_pd_row[2].gen_pd_col[1].u_pd/nfast_hit_latched_reg[0]/D`
