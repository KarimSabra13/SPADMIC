# MPTDC v2.0 — Verification Guide

## Test Infrastructure

### TB Package (`tb/common/mptdc_tb_pkg.sv`)
Common utilities shared by all testbenches:
- **Packet parsing**: `is_header()`, `is_eoc()`, `header_hit_count()`, `header_ctx_id()`, `eoc_conv_id()`
- **Hit extraction**: `parse_hit_features()` — decodes 3-word hit into nslow/nfast/ns/nf/pd_idx/event_seq
- **CSR access**: `tb_csr_write()`, `tb_csr_read()` — tasks for CSR bus operations
- **Stimulus**: `inject_pulse_pair()` — generates START/STOP with configurable delay
- **Collection**: `collect_packet()` — waits for header, collects all words through EOC

### Monitor (`tb/common/mptdc_raw_monitor.sv`)
Passive observer on the 16-bit output bus. Logs all packets, validates structure, provides summary statistics.

### Simulation Runner (`scripts/sim/run_tb.sh`)
Universal TB runner supporting Verilator (default), Xcelium, and VCS:
```bash
# Run single TB
bash scripts/sim/run_tb.sh tb_single_conv

# With VCD tracing
bash scripts/sim/run_tb.sh tb_single_conv --trace
```

## Test Suite

### Integration Tests (`tb/int/`)

| Test | Description | Key Checks |
|------|-------------|------------|
| `tb_single_conv` | Single START→STOP conversion | Packet structure, hit count, data validity |
| `tb_multi_conv_stress` | 100+ back-to-back conversions | No data loss, correct conv_ids, sustained operation |
| `tb_deadtime_measure` | Measure re-arm latency | Deadtime < 15ns target |
| `tb_cal_inject` | Calibration input path sweep | CAL mux routing, nslow/nfast monotonicity |
| `tb_backpressure` | Stall output consumer | Data integrity under backpressure, FIFO buffering |
| `tb_watchdog_recovery` | Trigger watchdog timeouts | Clean recovery, correct flags |

## CI Scripts

### Smoke Test (`ci/run_smoke.sh`)
Quick validation: lint + tb_single_conv. ~5 seconds.

```bash
bash ci/run_smoke.sh
```

### Full Regression (`ci/run_full_regression.sh`)
All integration TBs. ~30-60 seconds.

```bash
bash ci/run_full_regression.sh
```

## Adding a New Test

1. Create `tb/int/tb_your_test.sv`
2. Import `mptdc_pkg` and `mptdc_tb_pkg`
3. Instantiate `mptdc_top_asic` as DUT
4. Use TB package utilities for CSR access and packet collection
5. Print `[TB] ===== TEST PASSED =====` on success
6. Add to `ci/run_full_regression.sh` test list
7. Run: `bash scripts/sim/run_tb.sh tb_your_test`

## Key Verification Considerations

### Clock Domain Crossings
- All CDC paths use proven structures (gray counters, pulse sync, async FIFO)
- CDC timing verified by functional simulation with realistic oscillator models
- For formal CDC verification, use Synopsys SpyGlass or similar

### Async Domain
- Frontend uses async latches — Verilator models these as combinational
- Ring oscillator model (`mptdc_osc_model`) provides cycle-accurate behavior
- Real silicon may have different oscillator characteristics — calibration handles this

### Coverage Goals
1. All FSM states visited
2. All 3 context IDs used
3. All output modes exercised
4. Backpressure at every pipeline stage
5. Watchdog trip + recovery
6. Boundary conditions (0 hits, 15 hits, zero delay, max delay)
