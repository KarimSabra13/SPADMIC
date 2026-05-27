# 20260527 H1/H4 Server Analysis

Run IDs:

- Genus: `20260527_1030_h1_drain_pipeline_genus`
- Xcelium: `20260527_1030_h1_drain_pipeline_xcelium`

RTL commit run on lab server: `65fbfb0f0a39554836a5cd8b4528011b867f09ce`

Server-results commit: `10e46dca0e98f9bf98962d7f54fa824daba6a0ca`

## Genus Result

The focused clk_sys backend patch improved the target clock group but did not
close it.

| Metric | Before `20260527_0945_targeted_genus_reports` | After `20260527_1030_h1_drain_pipeline_genus` | Delta |
|---|---:|---:|---:|
| `clk_sys` WNS | -1486.0 ps | -968.1 ps | +517.9 ps |
| `clk_sys` TNS | -91719.4 ps | -48974.7 ps | +42744.7 ps |
| `clk_sys` violating paths | 79 | 72 | -7 |
| Max-transition violations | 282226 | 213804 | -68422 |

Overall timing remains dominated by oscillator/PD fabric:

| Group | WNS ps | TNS ps | Paths |
|---|---:|---:|---:|
| `clk_osc_fast_tap1` | -3045.0 | -187036.6 | 72 |
| `clk_osc_fast_tap2` | -2995.4 | -184833.8 | 72 |
| `clk_osc_fast_tap3` | -2987.3 | -184325.3 | 72 |
| `clk_osc_fast` | -2838.1 | -206013.9 | 94 |
| `clk_osc_slow` | -2764.8 | -51310.4 | 22 |
| `clk_sys` | -968.1 | -48974.7 | 72 |

This confirms the patch helped real backend timing, but it does not address the
dominant oscillator/PD signoff problem.

## H1 Status

The original row-count to context-bank endpoint was removed from the violating
context-bank hotspot list.

Before patch:

- `row_cnt_q -> ctx_snapshot_q[flags]`: about `-1484 ps`
- `row_cnt_q -> ctx_snapshot_q[hit_count]`: about `-1479 ps`

After patch:

- worst context-bank hotspot slack is positive: `+2 ps`

Remaining H1 issue:

- `row_cnt_q -> meas_ctrl_flags_q[closed_by_fast_maxhit]`: `-968 ps`
- `row_cnt_q -> meas_ctrl_hit_count_q[*]`: about `-960 ps`

Interpretation: registering `hit_count_q/flags_q` before context publication
fixed the context-bank write endpoint, but the final row-count sum and flag
calculation still exceed one 6.25 ns cycle. A next H1b patch should likely split
final count registration from flag/hit-count publication:

```text
SNAPSHOT -> COUNT_TOTAL -> EVAL_FLAGS -> CAPTURE -> CLEAR
```

This should use the already-retained `ST_M_EVAL` enum value or an equivalent
local state, with `total_hits_q` registered before saturation and flag compares.
Do not implement H1b until the Xcelium VIP rerun is clean or shows only an
unrelated environment issue.

## H4 Status

The old worst drain paths from `state_q` and `released_mask` to
`pending_wr_data_q` are no longer the top drain paths.

Before patch:

- `state_q/released_mask -> pending_wr_data_q`: about `-1486 ps`

After patch:

- `drain_ctx_q -> pending_wr_data_q`: about `-956 ps`
- `drain_ctx_q -> event_seq_q`: about `-947 ps`
- `ns_cnt_q -> pending_wr_data_q`: about `-894 ps`

Interpretation: removing the IDLE pre-point mux cut the previous selection cone,
but the remaining drain path is now the registered context read address through
the context read mux plus META/HIT record construction. A next H4b patch should
consider a prefetch/snapshot register in the drain controller or context-bank
read side, but that changes readout latency and should be kept behind the H1b
and Xcelium evidence gate.

## Xcelium Result

Directed Xcelium tests passed:

- `tb_meas_ctrl_unit`
- `tb_hit_capture_bridge_unit`
- `tb_context_bank_unit`
- `tb_drain_ctrl_unit`
- `tb_single_conv`
- `tb_backpressure`

VIP regression did not actually exercise RTL. All 20 VIP jobs failed at runner
startup with:

```text
Error: VIP artifacts must stay inside the repository or /sim/ksabra:
/home/validmgr/ksabra/2026_SPAD/SPADMIC/results/xcelium/20260527_1030_h1_drain_pipeline_xcelium/vip/cov_work
```

Root cause: `MPTDC/scripts/sim/run_vip_test.sh` treats `MPTDC/` as its
repository root and allows VIP artifacts only under that directory or
`/sim/ksabra`. The Xcelium server wrapper placed VIP output under top-level
`results/xcelium/...`, which the VIP runner rejected.

Fix: update `MPTDC/sim/xcelium/server_run_xcelium_mptdc.sh` so the VIP manager
runs under `MPTDC/results/xcelium/<RUN_ID>/vip` and then copies the VIP logs into
top-level `results/xcelium/<RUN_ID>/vip` for the normal commit workflow.

## Decision

Keep the RTL patch for now because Genus shows a real clk_sys improvement and
directed Xcelium passed. Do not declare the patch stable until VIP Xcelium rerun
passes or produces a real RTL failure.

Next action:

- Commit the Xcelium wrapper fix.
- Request Xcelium rerun only.
- If VIP passes, implement H1b as the next RTL timing patch.
