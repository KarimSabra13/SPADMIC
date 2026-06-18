# SPADMIC TOP — VIP Guide

Author: Karim Sabra

## Scope

This guide explains the current modular VIP under `TOP/tb/vip/`.

It focuses on:

- what each VIP area owns
- how the physical TX pins are observed after the DDR change
- which collateral is active versus compatibility-only

## 1. Directory map

| Directory | Role |
|-----------|------|
| `agent/` | generator and drivers |
| `coverage/` | functional coverage classes |
| `env/` | environment assembly, base test, test factory |
| `interfaces/` | virtual interfaces for DUT connectivity |
| `monitor/` | packet, CSR, and control observation |
| `pkg/` | shared package that includes all class files |
| `scoreboard/` | reference models and end-to-end checking |
| `sva/` | assertion modules and bind file |
| `tb/` | top-level harness |
| `tests/` | named test classes |
| `txn/` | transaction types |

## 2. Transaction model

The VIP package defines the main transaction kinds as:

- `TXN_CTRL`
- `TXN_TDC_EVENT`
- `TXN_POS_EVENT`
- `TXN_CORRELATED_EVENT`
- `TXN_RESET`
- `TXN_BP`
- `TXN_EOT`
- `TXN_MON_PKT`

That split keeps the stimulus plane separate from the observed packet plane.

## 3. Stimulus path

### Generator

`agent/spadmic_generator.sv` creates test-specific sequences of control writes,
events, position activity, resets, and end-of-test markers.

### Driver layer

`agent/spadmic_driver.sv` is the orchestrator. It routes each transaction to the
appropriate sub-driver:

- `spadmic_i2c_driver`
- `spadmic_csr_driver`
- `spadmic_event_driver`
- `spadmic_pos_driver`
- `spadmic_bp_driver`

It also owns the active-config mirror used for coverage sampling and now drives a
real reset pulse through `interfaces/spadmic_reset_if.sv` when it receives
`TXN_RESET`.

### Two control-entry modes

The VIP supports two control paths:

1. **I2C mode** for chip-realistic end-to-end control-plane tests
2. **direct CSR mode** for fast targeted regressions

The harness implements direct CSR mode with `force` on the DUT-internal local CSR
channel. That is intentional: it keeps the control-plane tests fast without
rewriting the top-level integration.

## 4. TX observation path

The TX path is the most important change in the current VIP.

### 4.1 Physical pins

The DUT exports:

- `chip_tx_clk_o`
- `chip_tx_valid_o`
- `chip_tx_data_o[7:0]`

### 4.2 Adapter interface

`interfaces/spadmic_narrow_tx_if.sv` is no longer a raw DUT ready/valid bus.
Instead, it is an **adapter**:

1. captures the low byte on `posedge phy_clk`
2. captures the high byte on `negedge phy_clk`
3. reconstructs one logical 16-bit word
4. exposes that word to packet-oriented monitors as `valid/data`

The retained `ready` field only exists so older collateral still compiles.

### 4.3 Packet monitor

`monitor/spadmic_tx_monitor.sv` consumes the reconstructed logical words and:

- detects packet headers and EOC
- extracts TDC source from the patched header and treats cluster/raw position headers as implicit position source
- distinguishes `TDC`, 8-word position-cluster, and fixed 14-word position-raw packets
- extracts the shared event ID from EOC
- emits one `spadmic_mon_pkt_txn` per complete packet

That packet transaction is what the scoreboard consumes.

## 5. Scoreboard and reference models

| Block | Role |
|-------|------|
| `spadmic_scoreboard.sv` | packet counting, pass/fail accounting, active-config tracking |
| `spadmic_tdc_ref_model.sv` | validates TDC packet structure |
| `spadmic_pos_ref_model.sv` | validates cluster and raw position packet structure, including 6-bit cluster coordinate packing |
| `spadmic_spad_reset_monitor.sv` | observes `spad_matrix_rst_o` pulse count and width |

The scoreboard keeps separate expected/received counts for TDC and position
packets, exact per-source accounting, and per-source event-ID monotonicity.
It updates its expectations from control transactions and reset transactions, so
it is not just a passive packet checker; it is the central execution-state model
for the VIP.

For the new position characterization features, the scoreboard also tracks:

- position mode (`cluster` versus `raw bitmap`)
- position reset mode and auto-reset period
- expected raw position payloads from the driven X/Y/Z line patterns
- expected 64-line cluster bounds from the driven X/Y/Z line patterns
- minimum expected SPAD reset pulse count and one-cycle pulse-width quality

The VIP should remain the existing lightweight SystemVerilog class-based
environment rather than migrating to UVM. The intended evolution is stronger
transaction constraints, deeper monitors, more exact scoreboards, and functional
coverage sampled from decoded transactions. Normal random sequences should be
legal and coherent by default; FIFO-full, event-ID wrap, reset-during-packet, and
intentionally mismatched TDC/position behavior belong in named stress/fault
tests.

`spadmic_generator` now uses a constrained `spadmic_random_scenario` object for
random phase selection. The default random policy is legal/coherent: TDC phases
run only in TDC-capable modes, position phases run only in position-capable
modes, and correlated phases force both-active export before driving a coherent
TDC-axis plus position event family. Phase weights and legal-only behavior are
controlled by:

```bash
--random-legal-only 0|1
--rand-w-tdc N --rand-w-pos N --rand-w-switch N --rand-w-bp N --rand-w-corr N
```

A repo-level Python packet decoder is planned as an independent off-chip
reference checker. It should parse dumped or captured logical TX words and
cross-check the SV monitor's packet kind, source, length, event ID, and payload
classification.

## 6. Coverage and assertions

### Coverage classes

The maintained coverage classes are:

- `spadmic_stim_cov`
- `spadmic_pkt_cov`
- `spadmic_ctrl_cov`
- `spadmic_fault_cov`
- `spadmic_reset_cov`

### Assertions

The maintained SVA files are:

- `spadmic_ctrl_sva`

It checks integration-level control invariants rather than re-proving the
internals of each `mptdc_axis_core` measurement kernel.

### 6.3 Current high-priority VIP status

The VIP now has first-class monitor/scoreboard coverage for the newest raw
position and SPAD reset features. Remaining work is focused on deeper
control/fault closure and campaign coverage:

| Area | Status |
|------|--------|
| Raw position packets | implemented in packet transaction, TX monitor, position reference model, scoreboard, packet coverage, and `smoke_position_raw` |
| SPAD matrix reset output | implemented in reset observation interface, monitor, reset transaction, scoreboard pulse checks, reset coverage, and `spad_reset_modes` |
| Position CSR state | scoreboard tracks position mode, reset mode, auto-reset period, and core filter fields from raw CSR writes |
| Fault/status closure | still needs deeper status/fault clear checks and CSR timeout/invalid-region coverage in VIP |
| Coverage closure | `run_vip_coverage.sh` includes raw/reset tests; Xcelium coverage reports still need lab execution and bin-level review |

Mandatory/non-waivable VIP coverage areas are reset, CDC-boundary assumptions as
observed through synchronized behavior, CSR faults, packet grammar, event IDs,
FIFO pressure, overflow/drop behavior, and mode transitions. Other bins can be
waived only with documented spec rationale.

## 7. Test library

Current named tests under `tests/`:

- `smoke_tdc`
- `smoke_position`
- `smoke_position_raw`
- `smoke_switching`
- `tdc_modes`
- `pos_clusters`
- `ctrl_reject`
- `reset_recovery`
- `spad_reset_modes`
- `bp_stress`
- `i2c_end_to_end`
- `long_random`
- `coverage_walk`
- `stress_random`

Not every test is used by every wrapper script. The active CI wrappers should be
treated as the source of truth for which suites are run together.

## 8. Active versus legacy semantics

### Active semantics

- correlated event IDs are part of observed packets
- both-active mode is a first-class scenario
- physical DDR pins are the real observation boundary

### Legacy compatibility semantics

- `bp_stress` and `spadmic_bp_driver` remain named around "backpressure"
- the `ready` field still exists in `spadmic_narrow_tx_if`

Those compatibility hooks do **not** mean the silicon-facing interface still
supports true backpressure. They exist to keep older collateral compiling while
the VIP is progressively cleaned up.

## 9. Tool flows

### Xcelium execution

```bash
bash TOP/scripts/sim/run_vip_test.sh <test_name>
```

### Verilator compile closure

```bash
bash TOP/scripts/sim/run_vip_test.sh <test_name> --sim verilator
```

The Verilator mode is a whole-harness lint compile, not a replacement for the
full `xrun` execution flow. It exists so the VIP can still be syntax-closed on
machines where `xrun` is unavailable.

## 10. Recommended debug flow

When a VIP failure appears:

1. check whether the mismatch is at the physical-pin layer or the reconstructed logical-word layer
2. inspect `spadmic_narrow_tx_if.sv` if byte order or valid timing looks wrong
3. inspect `spadmic_tx_monitor.sv` if packet boundaries or event IDs look wrong
4. inspect `spadmic_scoreboard.sv` if expectations look stale or mode-dependent
5. inspect the relevant test class in `tests/`

## 11. Cross-reference

- [`03_VERIFICATION_STRATEGY.md`](03_VERIFICATION_STRATEGY.md)
- [`08_TX_INTERFACE.md`](08_TX_INTERFACE.md)
- [`03_CORRELATED_EVENT_EXPORT.md`](03_CORRELATED_EVENT_EXPORT.md)
