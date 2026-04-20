# SPADMIC TOP — Verification Strategy

## 1. Scope

This document describes the **active** verification strategy for `spadmic_top_v1`.

It covers:

- the maintained directed/unit benches in `TOP/tb/`
- the modular class-based VIP under `TOP/tb/vip/`
- the current physical-TX observation model after the DDR egress change

It does **not** restate MPTDC leaf verification in full. The preserved TDC kernels
are treated as prerequisite IP with their own documentation under `MPTDC/docs/`.

## 2. Verification goals

The active TOP verification problem is no longer just "does TDC packetize?".
The important system-level checks are now:

1. requested-versus-active control sequencing stays safe
2. TDC-only, position-only, and correlated both-active modes all emit legal traffic
3. position snapshots queue correctly instead of being dropped by simple overlap
4. shared event IDs remain parseable and deterministic off-chip
5. the chip-facing DDR TX pins can be reconstructed back into the logical 16-bit packet stream without ambiguity

## 3. Environment architecture

```text
stimulus
  -> generator
  -> driver
     -> direct CSR or I2C control path
     -> async TDC event drivers
     -> position-line driver
     -> legacy BP compatibility driver

DUT
  -> spadmic_top_v1
  -> chip_tx_clk_o / chip_tx_valid_o / chip_tx_data_o[7:0] DDR

physical TX observation
  -> spadmic_narrow_tx_if
     reconstructs one 16-bit logical word from the DDR byte lane

logical packet observation
  -> spadmic_tx_monitor
  -> scoreboard + reference models
  -> coverage + SVA
```

The key architectural point is that the VIP now observes the **real physical pins**
first, then rebuilds the old logical packet view for packet-oriented checking.

## 4. VIP component map

| Area | File(s) | Current role |
|------|---------|--------------|
| Package | `tb/vip/pkg/spadmic_vip_pkg.sv` | central enum/type/include aggregation |
| Harness | `tb/vip/tb/spadmic_vip_tb.sv` | instantiates DUT, interfaces, reset BFM, direct CSR bridge, and test entry |
| Generator | `tb/vip/agent/spadmic_generator.sv` | builds stimulus transactions per test scenario |
| Orchestrator | `tb/vip/agent/spadmic_driver.sv` | dispatches transactions to the sub-drivers |
| I2C driver | `tb/vip/agent/spadmic_i2c_driver.sv` | chip-realistic bit-level control traffic |
| CSR driver | `tb/vip/agent/spadmic_csr_driver.sv` | fast direct control path for focused regressions |
| Event driver | `tb/vip/agent/spadmic_event_driver.sv` | async SPAD/CAL pulse generation per axis |
| Position driver | `tb/vip/agent/spadmic_pos_driver.sv` | line-pattern and glitch stimulus |
| Reset interface | `tb/vip/interfaces/spadmic_reset_if.sv` | drives real DUT async reset pulses for reset-recovery tests |
| TX adapter interface | `tb/vip/interfaces/spadmic_narrow_tx_if.sv` | converts physical DDR bytes back into logical 16-bit words |
| TX monitor | `tb/vip/monitor/spadmic_tx_monitor.sv` | packet assembly, source extraction, event-ID extraction |
| CSR monitor | `tb/vip/monitor/spadmic_csr_monitor.sv` | request/response visibility for direct-CSR runs |
| Ctrl monitor | `tb/vip/monitor/spadmic_ctrl_monitor.sv` | configuration and mode-transition visibility |
| Scoreboard | `tb/vip/scoreboard/spadmic_scoreboard.sv` | end-to-end packet counting and reference-model checks |
| TDC ref model | `tb/vip/scoreboard/spadmic_tdc_ref_model.sv` | validates TDC packet structure against active output mode |
| Position ref model | `tb/vip/scoreboard/spadmic_pos_ref_model.sv` | validates fixed position packet structure |
| Coverage | `tb/vip/coverage/spadmic_*_cov.sv` | stimulus, packet, control, and fault coverage buckets |
| SVA | `tb/vip/sva/*.sv` | control, readout, mux/correlation-path, and position assertions |

## 5. Physical TX observation model

The physical DUT pins are:

- `chip_tx_clk_o`
- `chip_tx_valid_o`
- `chip_tx_data_o[7:0]`

The VIP does **not** try to score packets directly on raw DDR bytes. Instead:

1. `spadmic_vip_tb` connects the DUT pins into `spadmic_narrow_tx_if`
2. `spadmic_narrow_tx_if` samples the low byte on `posedge phy_clk`
3. it samples the high byte on `negedge phy_clk`
4. it reconstructs one logical word as `{high_byte, low_byte}`
5. `spadmic_tx_monitor` consumes that reconstructed logical stream

This keeps packet-oriented monitors, scoreboards, and helper functions reusable
while still binding the VIP to the real chip-facing interface.

## 6. Active versus legacy verification collateral

Some VIP names still reflect the pre-DDR / pre-correlated design. The important
distinction is:

### Active collateral

- `spadmic_narrow_tx_if` as a **physical-to-logical adapter**
- `spadmic_tx_monitor` extracting shared event IDs from EOC
- exact scoreboarding of TDC-only, position-only, and both-active behavior
- real reset pulses through `spadmic_reset_if` rather than scoreboard-only reset markers
- SVA modules for control, readout, and position behavior

### Retained compatibility collateral

- `spadmic_bp_driver.sv`
- `spadmic_bp_txn.sv`
- `spadmic_bp_stress.sv`

These files still compile and remain useful as regression scaffolding, but they
no longer model a real silicon-facing backpressure contract. The active physical
TX path is source-synchronous and ignores `ready`.

Treat them as compatibility/cleanup candidates, not as proof of real off-chip
flow-control behavior.

## 7. Assertion coverage

The checked-in SVA files are:

| File | Focus |
|------|-------|
| `spadmic_ctrl_sva.sv` | requested/active sequencing and safe control updates |
| `spadmic_readout_sva.sv` | shared TDC readout arbitration invariants |
| `spadmic_mux_sva.sv` | top-level export-path selection and handoff assumptions |
| `spadmic_pos_sva.sv` | position packet ordering and bounded packetization behavior |

`spadmic_sva_bind.sv` only binds the assertion modules that still match the
active top-level structure.

## 8. Maintained regression entrypoints

### VIP smoke

```bash
bash TOP/ci/run_vip_smoke.sh
```

Current smoke suite:

- `smoke_tdc`
- `smoke_position`
- `smoke_switching`

### VIP coverage regression

```bash
bash TOP/ci/run_vip_coverage.sh
```

Current coverage-suite test list comes from `TOP/ci/run_vip_coverage.sh`:

- `smoke_tdc`
- `smoke_position`
- `smoke_switching`
- `tdc_modes`
- `pos_clusters`
- `ctrl_reject`
- `reset_recovery`
- `bp_stress`
- `i2c_end_to_end`
- `long_random`
- `coverage_walk`

### Single test

```bash
bash TOP/scripts/sim/run_vip_test.sh <test_name>
```

### Verilator lint closure

```bash
bash TOP/scripts/sim/run_vip_test.sh <test_name> --sim verilator
```

This path is intentionally **lint-only**. It is useful on machines without
`xrun` to keep the full VIP harness syntax-checked with the real repo filelists.

## 9. Recommended usage

1. use the unit benches in `TOP/tb/` for leaf-level RTL debug
2. use the VIP smoke suite after interface or integration edits
3. use the coverage suite when changing control, packet semantics, or monitors
4. use the Verilator lint path when `xrun` is unavailable but you still need full-harness compile closure
5. when debugging TX issues, inspect both the physical pins and the reconstructed logical words from `spadmic_narrow_tx_if`

## 10. Documentation cross-reference

- [`01_ACTIVE_ARCHITECTURE.md`](01_ACTIVE_ARCHITECTURE.md)
- [`03_CORRELATED_EVENT_EXPORT.md`](03_CORRELATED_EVENT_EXPORT.md)
- [`07_BLOCK_GUIDE.md`](07_BLOCK_GUIDE.md)
- [`08_TX_INTERFACE.md`](08_TX_INTERFACE.md)
- [`09_VIP_GUIDE.md`](09_VIP_GUIDE.md)
