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
- `smoke_position_raw`
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

## 10. Coverage-driven verification roadmap

The next verification milestone is to make the VIP coverage-driven rather than
only pass/fail driven. The intent is to verify each block in isolation first,
then compose the blocks through the top-level VIP.

### 10.1 Staged closure model

| Stage | Scope | Main evidence |
|-------|-------|---------------|
| Leaf directed | one RTL block or small protocol boundary | deterministic unit/stress benches, local assertions, code coverage |
| Subsystem directed | two or three connected active blocks | protocol monitors, scoreboard checks, corner-case tests |
| Top VIP smoke | full `spadmic_top_v1` with physical TX observation | smoke tests for TDC-only, position-only, both-active, reset recovery |
| Top VIP coverage | constrained/randomized feature walks | functional coverage, code coverage, no scoreboard/SVA failures |
| Tapeout gate | curated mix of portable and Xcelium-only tests | reproducible pass/fail matrix plus coverage report |

### 10.2 VIP monitor and transaction upgrades

The TX monitor must understand every legal packet grammar emitted by the current
RTL:

| Item | Required monitor behavior |
|------|---------------------------|
| TDC packet | detect header, hold until EOC, extract source from patched header, extract shared event ID |
| Position cluster packet | detect cluster header, recognize position sub-header, require 12 total words |
| Position raw bitmap packet | detect raw-position header and collect exactly 14 words, because raw payload words can look like header or EOC markers |
| Packet atomicity | report incomplete packet flushes as monitor errors, not silent packets |
| Physical TX | keep DDR byte reconstruction in `spadmic_narrow_tx_if` as the only physical observation boundary |

The monitored packet transaction should carry packet kind (`TDC`,
`POS_CLUSTER`, `POS_RAW`), source ID, event ID, word count, raw word queue, and a
timestamp. That lets the scoreboard and coverage sample the same decoded object.

The SPAD matrix reset output also needs a first-class monitor:

| Item | Required monitor behavior |
|------|---------------------------|
| Manual reset | observe a single-cycle `spad_matrix_rst_o` pulse after `POS_CTRL.manual_reset_req` |
| Event-deferred auto-reset | observe pending-to-pulse only after detector/packetizer/line idle conditions |
| Periodic auto-reset | observe periodic pulses even when position lines are active |
| Pulse quality | flag any pulse wider than one `clk_sys` cycle or any pulse while reset is inactive |

### 10.3 Reference model and scoreboard upgrades

The scoreboard should be the central end-to-end model, not just a packet counter.
It should track:

| Model area | Required state/check |
|------------|----------------------|
| Active global control | requested-to-active mode, axis enables, input source, TDC output mode, max_hits |
| Position CSR state | position mode, gap threshold, minimum span, settle cycles, reset mode, auto-reset period |
| Expected packets | per-source expected packet counts, accepted drops, reset-cleared in-flight expectations |
| Event IDs | per-source monotonic IDs, wrap behavior, no cross-source accidental coupling |
| Position cluster packets | exact 12-word format, masks, summaries, cluster words, overflow semantics |
| Position raw packets | exact 14-word format, X/Y/Z bitmap packing, EOC only at word 13 |
| Reset output | expected manual/deferred/periodic pulse count and one-cycle width |
| Fault/status CSRs | mode rejects, position drops/glitches, correlation overflow, CSR timeout/error visibility |

The position reference model must validate against the stimulus patterns whenever
the VIP can know them. For cases with intentionally unstable line stimulus, it
should classify the expected result as accepted packet, rejected glitch, or
possible race-window observation rather than blindly expecting one packet.

### 10.4 Functional coverage groups

Coverage should be sampled from decoded transactions and observed status, not
from implementation internals unless a coverpoint is explicitly white-box.

#### Stimulus/configuration coverage

| Coverpoint | Important bins |
|------------|----------------|
| export mode | TDC-only, position-only, both-active |
| control path | direct CSR, I2C |
| TDC input source | SPAD, CAL |
| TDC output mode | raw features, raw timestamp, full |
| axis mask | none, single-axis, two-axis, all-axis |
| max_hits | 1, mid values, max legal value |
| position mode | cluster, raw bitmap |
| position filter | min span 1, nominal span, large span; settle 0/1/nominal/max |
| reset mode | manual only, event-deferred, periodic |
| reset period | disabled, short, long |
| stimulus kind | TDC, position, correlated, reset, CSR-only |

Key crosses:

- export mode × position mode
- export mode × reset mode
- TDC output mode × max_hits
- axis mask × input source
- control path × CSR region
- position mode × filter settings
- reset mode × traffic state

#### Packet coverage

| Coverpoint | Important bins |
|------------|----------------|
| packet kind | TDC, position cluster, position raw |
| TDC source | X, Y, Z |
| TDC hit count | zero, one, few, many, max |
| TDC flags | none, fast close, max hit, watchdog/overflow-related flags |
| position cluster masks | every non-empty mask, every multi-cluster mask, overflow asserted/deasserted |
| raw axis masks | X only, Y only, Z only, XY, XZ, YZ, XYZ |
| raw bitmap pattern | single bit, edge bits 0/63, sparse, dense, all-zero rejection, EOC-looking words, header-looking words |
| event ID | low values, adjacent events, wrap boundary |
| packet length | TDC legal lengths, cluster 12, raw 14 |

Key crosses:

- packet kind × export mode
- packet kind × event ID range
- raw bitmap pattern × axis mask
- cluster overflow × multi-cluster mask
- TDC source × hit count × output mode

#### Control/status/fault coverage

| Coverpoint | Important bins |
|------------|----------------|
| sequencer state | idle, drain/transition, reset |
| cfg_accept | accepted while idle, rejected while non-idle |
| path idle contributors | TDC busy, TDC pending, position busy, position pending |
| CSR region | global, TDC X/Y/Z, position, invalid |
| CSR errors | invalid region, downstream timeout, pointerless read NACK, reset during I2C |
| position faults | glitch reject, queue drop, overflow clusters |
| reset during traffic | reset during TDC packet, position packet, raw packet, I2C transaction |
| correlation faults | event-ID wrap, post-arbiter FIFO pressure |

### 10.5 Block-by-block corner-case matrix

| Block | Directed corner cases before top VIP |
|-------|--------------------------------------|
| I2C/CSR | invalid region, pointerless read, repeated START, reset during address/data/read phase, downstream timeout, rejected non-idle control writes |
| Top sequencer | requested image changes while busy, drain-to-commit, disable during in-flight packet, reset during transition, active/requested readback |
| Ref STOP qualifier | short/long async event, held-high event, reset while armed, ref-clock edge alignment, disabled-axis event suppression |
| TDC shared readout | zero-hit packets, all axes pending, fairness, stalls at serializer boundary, max-hit packet length, reset mid-packet |
| Correlated TX | packet atomicity, TDC/position alternation, event-ID wrap, raw payload header/EOC-looking words, output FIFO pressure |
| DDR TX | low/high byte ordering, valid timing, reset during word, idle byte behavior, forwarded-clock phase assumptions |
| Position cluster | gap threshold sweep, min-span 1, edge line 0/63 clusters, two clusters, more-than-two overflow, queue-full drop, glitch reject |
| Position raw/reset | 14-word raw packet, all axes and edge bits, raw payload marker collisions, manual reset, period 0 disabled, deferred reset waits, periodic reset fires under activity |

### 10.6 Xcelium coverage workflow

Use the existing test runner knobs as the foundation:

```bash
bash TOP/scripts/sim/run_vip_test.sh <test> --func-cov --code-cov --seed <N>
bash TOP/ci/run_vip_coverage.sh
```

Coverage closure should archive:

1. the command line, seed, and test name for each run,
2. scoreboard summary,
3. assertion failure summary,
4. merged functional/code coverage report,
5. known waivers with links to the RTL/doc rationale.

Do not treat a high aggregate coverage percentage as sufficient by itself. Any
zero-hit bin in the raw/reset/control/fault covergroups must be reviewed because
those bins represent silicon-debug-critical behavior.

The raw/reset VIP closure added two focused top-level tests to the Xcelium
coverage suite:

| Test | Purpose |
|------|---------|
| `smoke_position_raw` | drives raw X/Y/Z bitmaps with header/EOC-looking payload words and checks the fixed 14-word raw packet through the physical TX monitor |
| `spad_reset_modes` | observes manual, periodic, and event-deferred `spad_matrix_rst_o` pulses and checks one-cycle pulse width |

### 10.7 Immediate implementation slices

1. **Raw packet VIP closure — implemented**: update TX monitor, monitored packet transaction,
   position reference model, scoreboard, packet coverage, and add a raw-position
   VIP smoke test.
2. **SPAD reset VIP closure — implemented**: add reset-output interface/monitor/transaction,
   scoreboard expected reset model, reset coverage, and directed tests for manual,
   event-deferred, and periodic modes.
3. **Control/fault closure**: extend CSR/status monitors and coverage so rejected
   mode writes, timeout paths, sticky faults, and clear behavior are checked
   against expectations.
4. **Block stress closure**: add missing directed benches or extend existing ones
   for STOP qualifier, shared readout, correlated TX FIFO pressure, DDR reset, and
   position glitch/queue/reset interactions.
5. **Coverage campaign closure**: run the VIP suite with multiple fixed seeds,
   merge coverage, review zero bins, then add targeted tests only for real holes.

## 11. Documentation cross-reference

- [`01_ACTIVE_ARCHITECTURE.md`](01_ACTIVE_ARCHITECTURE.md)
- [`03_CORRELATED_EVENT_EXPORT.md`](03_CORRELATED_EVENT_EXPORT.md)
- [`07_BLOCK_GUIDE.md`](07_BLOCK_GUIDE.md)
- [`08_TX_INTERFACE.md`](08_TX_INTERFACE.md)
- [`09_VIP_GUIDE.md`](09_VIP_GUIDE.md)
