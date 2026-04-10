# SPADMIC TOP — Verification Strategy

## 1. Overview

This document describes the verification strategy for `spadmic_top_v1`, the chip-level integration shell of the SPADMIC ASIC. The strategy targets **95% functional coverage** and **90% code coverage** using a modular UVM-lite environment running on Cadence Xcelium.

## 2. Verification Philosophy

- **Coverage-driven, constrained-random** as the primary methodology
- **Directed smoke tests** as bring-up gates before random phases
- **Hybrid stimulus**: I2C for chip-realistic tests + direct CSR for fast regressions
- **Separated files by responsibility** (unlike the monolithic MPTDC VIP)
- **Inherited MPTDC evidence**: TDC kernel verification runs as prerequisite, not duplicated

## 3. Environment Architecture

```
┌───────────────────────────────────────────────────────────┐
│ spadmic_vip_tb (harness)                                  │
│  ┌────────────┐  ┌────────────┐  ┌──────────────────┐    │
│  │ Generator   │→│ Driver     │→│ DUT              │    │
│  │             │  │ (CSR/I2C)  │  │ spadmic_top_v1   │    │
│  │             │  │ (Event)    │  │                  │    │
│  │             │  │ (Position) │  │                  │    │
│  │             │  │ (BP)       │  │                  │    │
│  └────────────┘  └────────────┘  └────────┬─────────┘    │
│                                           │               │
│  ┌────────────┐  ┌────────────┐  ┌────────▼─────────┐    │
│  │ Scoreboard │←│ Monitors   │←│ TX / CSR / Ctrl   │    │
│  │ + RefModel │  │            │  │ Interfaces        │    │
│  └────────────┘  └────────────┘  └──────────────────┘    │
│                                                           │
│  ┌──────────────────────────────────────────────┐         │
│  │ Coverage: stim + pkt + ctrl + fault          │         │
│  │ SVA:      ctrl + readout + mux + position    │         │
│  └──────────────────────────────────────────────┘         │
└───────────────────────────────────────────────────────────┘
```

## 4. Component Responsibilities

| Component | File(s) | Role |
|-----------|---------|------|
| **Generator** | `agent/spadmic_generator.sv` | Builds transaction sequences from test scenarios |
| **Orchestrating Driver** | `agent/spadmic_driver.sv` | Consumes txns, dispatches to sub-drivers |
| **I2C Driver** | `agent/spadmic_i2c_driver.sv` | Bit-level I2C BFM for chip-realistic stimulus |
| **CSR Driver** | `agent/spadmic_csr_driver.sv` | Direct CSR req/rsp for fast regressions |
| **Event Driver** | `agent/spadmic_event_driver.sv` | Async SPAD/CAL event injection per axis |
| **Position Driver** | `agent/spadmic_pos_driver.sv` | Position line pattern + glitch injection |
| **BP Driver** | `agent/spadmic_bp_driver.sv` | Backpressure mode control on chip_tx_ready |
| **TX Monitor** | `monitor/spadmic_tx_monitor.sv` | Captures and decodes chip_tx packets |
| **CSR Monitor** | `monitor/spadmic_csr_monitor.sv` | Watches CSR read/write/error events |
| **Ctrl Monitor** | `monitor/spadmic_ctrl_monitor.sv` | Tracks control-plane state transitions |
| **Scoreboard** | `scoreboard/spadmic_scoreboard.sv` | End-to-end packet checking + counters |
| **TDC Ref Model** | `scoreboard/spadmic_tdc_ref_model.sv` | Predicts TDC packet structure |
| **POS Ref Model** | `scoreboard/spadmic_pos_ref_model.sv` | Software cluster-scan reference |
| **Coverage** | `coverage/spadmic_*_cov.sv` | 4 covergroup classes (stim, pkt, ctrl, fault) |
| **SVA** | `sva/spadmic_*_sva.sv` | 4 assertion modules + bind file |
| **Environment** | `env/spadmic_env.sv` | Assembles all components |
| **Base Test** | `env/spadmic_base_test.sv` | Standard test lifecycle |
| **Test Factory** | `env/spadmic_test_factory.sv` | Test name → class mapping |

## 5. Constraint Model

### Illegal configurations (constrained out):
- `gap_threshold < 5` or `min_cluster_span < 5`
- `max_hits ∉ {1, 5, 10, 15}`
- `out_mode == 2'd3` (reserved)
- `start_stop_delay > 32ns`
- `axis_enable != 3'b111` (lab always runs all 3)

### Legal cross-coverage targets:
- `out_mode × max_hits` (3×4 = 12 bins)
- `tx_sel × out_mode` (2×3 = 6 bins)
- `bp_mode × delay_bin` (3×4 = 12 bins)
- `source × hit_count` (3×6 = 18 bins)

## 6. SVA Assertion Catalog

| ID | Assertion | Module |
|----|-----------|--------|
| P1 | cfg_accept only in IDLE+path_idle | `spadmic_ctrl_sva` |
| P2 | global_enable=0 during DRAIN | `spadmic_ctrl_sva` |
| P3 | transition_busy clears only in IDLE | `spadmic_ctrl_sva` |
| P4 | mode_reject_count monotonic | `spadmic_ctrl_sva` |
| P5 | One acq_ready grant at a time | `spadmic_readout_sva` |
| P6 | Packet source stable while busy | `spadmic_readout_sva` |
| P7 | Busy de-asserts on EOC | `spadmic_readout_sva` |
| P8 | Grant requires valid | `spadmic_readout_sva` |
| P9 | tx_sel changes only when paths idle | `spadmic_mux_sva` |
| P10 | Position ready gated during TDC | `spadmic_mux_sva` |
| P11 | TDC ready gated during position | `spadmic_mux_sva` |
| P12 | Valid routing matches tx_sel | `spadmic_mux_sva` |
| P13 | Position word_idx bounded | `spadmic_pos_sva` |
| P14 | EOC at word position 11 | `spadmic_pos_sva` |
| P15 | Header at word position 0 | `spadmic_pos_sva` |

## 7. Coverage Targets

| Category | Target | Metric |
|----------|--------|--------|
| Functional coverage | 95% | All 4 covergroups combined |
| Code coverage | 90% | Line + branch + toggle + FSM |
| SVA assertions | 0 failures | All 15 assertions pass |
| Directed benches | 13/13 pass | Legacy unit/stress benches |
| VIP tests | 12/12 pass | All test classes pass |

## 8. Reuse Strategy

- **MPTDC VIP patterns**: mailbox/BFM, coverage gating, test factory
- **MPTDC packet helpers**: shared `is_tdc_header`, `is_tdc_eoc`, etc.
- **MPTDC coverage runners**: script structure mirrors `ci/run_vip_coverage.sh`
- **MPTDC calibration**: inherited as prerequisite evidence, not re-verified at TOP
