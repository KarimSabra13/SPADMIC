# MPTDC v2.0 — Architecture Overview

## System Summary

The MPTDC is a **Vernier Multi-Phase Time-to-Digital Converter** designed for SPAD (Single-Photon Avalanche Diode) matrix readout. It measures the time interval between a START and STOP pulse with ~10 ps LSB resolution.

### Key Specifications

| Parameter | Value |
|-----------|-------|
| Architecture | Vernier multi-phase |
| Ring oscillator taps (NE) | 9 |
| Slow oscillator step | 55 ps |
| Fast oscillator step | 50 ps |
| Vernier step (Δ) | 5 ps |
| LSB (2Δ) | 10 ps |
| K_vernier | 11 |
| PD matrix | 9×9 = 81 cells |
| Measurement window | 32 ns |
| Max hits per conversion | 15 |
| System clock | 160 MHz |
| Output bus | 16-bit, ready/valid |
| Snapshot contexts | 3 (triple-buffer) |
| Calibration | Purely offline |

## Block Diagram

```
                    ┌─────────────────────────────────────────────────┐
                    │              mptdc_top_asic                      │
                    │                                                  │
  rst_n ──────────►│ reset_sync ──► rst_n_internal                    │
                    │                                                  │
  start_spad ─────►│                                                  │
  stop_spad  ─────►│ input_mux ───► start_int ──┐                    │
  cal_start  ─────►│               stop_int ──┐ │                    │
  cal_stop   ─────►│                          │ │                    │
                    │                          ▼ ▼                    │
  csr_* ──────────►│ csr_minimal ─► cfg ─► mptdc_core ──► narrow_*  │
                    │              ◄─ status ──┘                      │
                    └─────────────────────────────────────────────────┘

                    ┌─────────────────────────────────────────────────┐
                    │              mptdc_core                          │
                    │                                                  │
  start/stop ─────►│ async_frontend_v2                                │
                    │   ├── START/STOP latches (async)                │
                    │   ├── Context allocation (3-state FSM per ctx)  │
                    │   └── Oscillator enable control                 │
                    │                                                  │
                    │ osc_wrapper ×2 (slow=55ps, fast=50ps)           │
                    │   └── 9-tap ring oscillators                    │
                    │                                                  │
                    │ pd_cell ×81 (9×9 phase detector matrix)         │
                    │                                                  │
                    │ stop_capture_async (boundary repair)             │
                    │   └── phase0_snap, phase7d_snap                 │
                    │                                                  │
                    │ gray_cnt_sync ×2 (slow/fast counter CDC)        │
                    │                                                  │
                    │ context_bank (3 snapshot slots)                  │
                    │   └── Captures PD matrix + counters on STOP     │
                    │                                                  │
                    │ ctrl_fsm_v2 (IDLE → ACTIVE → DRAIN_WAIT)       │
                    │                                                  │
                    │ writer_scan (PD scan-order, META+HITs)          │
                    │   └── Clocked by osc_fast_ph0                   │
                    │                                                  │
                    │ async_fifo (fast→sys CDC, FIFO_DEPTH=64)        │
                    │                                                  │
                    │ narrow16_tx_v2 (16-bit serializer)              │
                    │   └── Header + Hit words + EOC                  │
                    │                                                  │
                    │ watchdog (per-context + global timeout)          │
                    └─────────────────────────────────────────────────┘
```

## Triple-Buffer Architecture

The key innovation is a **triple-buffer** snapshot architecture with 3 independent contexts:

```
Context State Machine:

  FREE ──(allocate on START)──► CAPTURING ──(STOP detected)──► DRAINING ──(writer done)──► FREE
```

### States
- **FREE**: Context available for next conversion
- **CAPTURING**: Owns the oscillators + PD matrix; accumulating Vernier data
- **DRAINING**: Snapshot taken; writer scans and pushes to FIFO

### Benefits
- **Minimal deadtime**: Frontend re-arms as soon as CAPTURING→DRAINING transition completes (~2-4 ns async)
- **Pipelined readout**: Writer drains old context while new conversion starts
- **Overflow protection**: If all 3 contexts busy, overflow flag set

### Invariants
1. At most 1 context in CAPTURING (owns the shared oscillators)
2. Multiple contexts can be DRAINING simultaneously
3. Writer round-robins between DRAINING contexts

## Clock Domains

| Domain | Source | Frequency | Modules |
|--------|--------|-----------|---------|
| clk_sys | External pad | 160 MHz | FSM, CSR, narrow TX, watchdog |
| osc_slow_ph[0:8] | Slow ring oscillator | ~1.01 GHz | PD cells (slow side) |
| osc_fast_ph[0:8] | Fast ring oscillator | ~1.11 GHz | PD cells (fast side), writer, context bank |
| async | — | — | Frontend latches, stop_capture, osc enables |

### CDC Crossings
- **gray_cnt_sync**: Slow/fast revolution counters → sys domain
- **pulse_sync**: Start/stop events → sys domain
- **async_fifo**: Writer records (fast) → narrow TX (sys)
- **reset_sync**: External rst_n → rst_n_internal (async assert, sync deassert)

## Conversion Flow

1. **CSR arms** the TDC (conv_arm bit)
2. **START** arrives → frontend allocates a FREE context → oscillators start
3. PD matrix accumulates phase transitions; gray counters track revolutions
4. **STOP** arrives → `capture_done_async` fires → context bank snapshots everything
5. Context transitions to DRAINING; frontend re-arms immediately
6. Writer scans PD cells 0-80, pushes META + HIT records to async FIFO
7. Narrow TX reads FIFO, serializes to 16-bit header + hit words + EOC
8. Host reads via ready/valid handshake

## FSM (3 states)

```
  ST_IDLE ──(arm && start_seen)──► ST_ACTIVE ──(stop_seen)──► ST_DRAIN_WAIT ──(writer_done)──► ST_IDLE
                                         │                                          ▲
                                         └──(early closure: first_hit/max_hits/wdt)─┘
```

## Calibration Strategy

All calibration is **offline** (PC-side):
1. Switch input_mux to CAL mode
2. Inject known delays via cal_start/cal_stop
3. Collect raw features (nslow, nfast, ns, nf, pd_idx, event_seq, phase0_snap)
4. PC applies ridge regression or ML model to compute correction coefficients
5. At runtime: `t_corrected = t_raw + f(features)`

## File Organization

```
rtl/
├── pkg/mptdc_pkg.sv              — Constants, types, helpers
├── top/mptdc_top_asic.sv         — Pad-facing wrapper
├── top/mptdc_core.sv             — Reusable TDC core
├── async/                         — Async-domain modules
│   ├── mptdc_async_frontend_v2.sv
│   ├── mptdc_context_bank.sv
│   ├── mptdc_writer_scan.sv
│   └── mptdc_stop_capture_async.sv
├── cdc/                           — Clock-domain crossing
│   ├── mptdc_async_fifo.sv
│   ├── mptdc_gray_cnt_sync.sv
│   ├── mptdc_pulse_sync.sv
│   └── mptdc_reset_sync.sv
├── osc/                           — Oscillators
│   ├── mptdc_osc_wrapper.sv
│   ├── mptdc_osc_model.sv
│   └── mptdc_osc_stub.sv
├── pd/mptdc_pd_cell.sv           — Phase detector
├── ctrl/                          — Control logic
│   ├── mptdc_ctrl_fsm_v2.sv
│   ├── mptdc_watchdog.sv
│   └── mptdc_input_mux.sv
└── readout/                       — Output chain
    ├── mptdc_narrow16_tx_v2.sv
    ├── mptdc_tconv_reco.sv
    └── mptdc_csr_minimal.sv
```
