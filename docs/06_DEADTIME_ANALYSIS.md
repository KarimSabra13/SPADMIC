# MPTDC v2.0 — Deadtime Analysis

## Definition

**Deadtime** = time from STOP rising edge of conversion N to the earliest moment START can successfully trigger conversion N+1.

## v1 Architecture Deadtime

The previous single-context design had sequential processing:

```
STOP → FSM closure → writer serialization → writer_done CDC → ready
       └── ~6ns ──┘  └── 14.4ns (15 hits) ──────────────┘  └── 6.25ns ──┘
```

**Total deadtime: ~91 ns (multi-hit, 15 hits)**

### v1 Bottleneck Breakdown
| Stage | Duration | Notes |
|-------|----------|-------|
| FSM closure + snapshot | ~6 ns | CDC delays |
| Writer serialization | ~14.4 ns | 81 cells × ~178 ps/cell |
| Writer_done CDC | ~6.25 ns | sys clock synchronization |
| Frontend re-arm | ~2 ns | Async latch clear |
| **Total** | **~29 ns** | (theoretical, ~91ns measured with overhead) |

## v2 Triple-Buffer Architecture

```
STOP → snapshot to context bank → context→DRAINING → frontend re-armed
  └── 1 fast cycle (~0.9ns) ──────┘  └── async ──────┘  └── <1ns ──┘

Meanwhile (in parallel, no impact on deadtime):
  writer scans context → async FIFO → narrow TX → 16-bit output
```

### Key Insight
The frontend re-arms **immediately** after snapshot — it doesn't wait for the writer. The writer works on the DRAINING context independently.

### Expected Deadtime Contributions

| Stage | Duration | Notes |
|-------|----------|-------|
| Capture pulse (fast domain) | ~0.9 ns | 1 osc_fast cycle |
| Context state transition | ~0.5 ns | Async latch |
| PD clear (delayed 1 fast cycle) | ~0.9 ns | pd_clear_fast_r |
| Frontend osc_en update | ~0.5 ns | Combinational |
| **Theoretical minimum** | **~2-4 ns** | |

### Practical Limitations

1. **CSR arm latency**: conv_arm must propagate through CSR → FSM (sys clock domain). This adds ~2 sys clock cycles = 12.5 ns. However, if the FSM auto-re-arms (no CSR involvement), this is eliminated.

2. **Context availability**: If all 3 contexts are busy (1 capturing + 2 draining), the frontend is masked. With FIFO_DEPTH=64 and max 16 records per conversion, this shouldn't happen unless the output consumer is severely backpressured.

3. **Oscillator startup**: The oscillators must restart for the new conversion. Ring oscillator startup is nearly instantaneous (~1 ring delay = 9 × 55ps = 495ps).

### Measured Deadtime (Simulation)

From `tb_single_conv` results:
- STOP at ~370 ns
- Frontend re-armed at ~372 ns (2 ns later, dominated by fast clock edge alignment)
- Next START can trigger at ~372 ns

**Measured deadtime: ~2-4 ns** (limited by fast clock edge alignment)

**With CSR re-arm: ~15-20 ns** (dominated by sys clock CDC for conv_arm)

## Comparison

| Metric | v1 | v2 |
|--------|-----|-----|
| Deadtime (multi-hit, 15 hits) | ~91 ns | ~2-4 ns (async) |
| Deadtime (with CSR re-arm) | ~91 ns | ~15-20 ns |
| Improvement | — | **~6-45×** |

## Recommendations for Minimum Deadtime

1. **Auto-re-arm mode**: Add a CSR bit to auto-arm after each conversion, bypassing CSR write latency
2. **Persistent arm**: Keep conv_arm high continuously for maximum throughput
3. **Monitor overflow counter**: If ovf_count increases, reduce event rate or check backpressure
