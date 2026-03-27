# MPTDC VIP — Verification IP Environment

> Class-based, coverage-driven verification environment for the
> Multi-Phase Time-to-Digital Converter (MPTDC).
>
> Author: Karim Sabra

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Class Hierarchy](#2-class-hierarchy)
3. [Transaction Types](#3-transaction-types)
4. [Driver Components](#4-driver-components)
5. [Monitor & Packet Parsing](#5-monitor--packet-parsing)
6. [Scoreboard & Validation](#6-scoreboard--validation)
7. [Coverage Model](#7-coverage-model)
8. [Interface Definitions](#8-interface-definitions)
9. [Test Catalog](#9-test-catalog)
10. [Running Tests](#10-running-tests)
11. [Coverage Reporting with IMC](#11-coverage-reporting-with-imc)
12. [Expected Results](#12-expected-results)
13. [Narrow-Bus Packet Format](#13-narrow-bus-packet-format)

---

## 1. Architecture Overview

The VIP implements a **UVM-lite** transaction-driven environment without
requiring the full UVM library. All classes live in `mptdc_vip_pkg.sv`.

```
Test Factory ──▶ Test (build_sequence) ──▶ Generator (queue txns)
                                                │
                                          ┌─────▼─────┐
                                          │  Mailbox   │
                                          └─────┬─────┘
                                                │
          ┌──────────────────────────────────────▼──────────────────┐
          │                      Driver                             │
          │  Routes by txn.kind:                                    │
          │    TXN_RESET → pulse_drv.hard_reset()                   │
          │    TXN_CFG   → csr_drv.program_cfg()                    │
          │    TXN_BP    → ready_drv.set_mode()                     │
          │    TXN_CONV  → queue for BFM + sample stim_cg           │
          │    TXN_EOT   → drain pending + break loop               │
          │  Also: route accepted conversions → exp_mailbox         │
          └──────────────────────────┬─────────────────────────────┘
                                     │
                               ┌─────▼─────┐
                               │    DUT     │
                               │ mptdc_top  │
                               └─────┬─────┘
                                     │ sampled accepted words
                               ┌─────▼─────┐
                               │  Monitor   │
                               │ Rebuilds   │
                               │ packets    │
                               └─────┬─────┘
                                     │
                               ┌─────▼──────┐
                              │ Scoreboard │
                              │ Validates  │
                              │ + Coverage │
                              └────────────┘
```

**Key design decisions:**

- **Mailbox coupling** — classes never poke the DUT hierarchy directly.
  A module-resident BFM in `mptdc_vip_tb.sv` bridges between the
   class mailbox (`g_bfm_req_mb`) and the DUT interface signals.
- **Acceptance routing** — the driver does not assume every START is
  accepted. A BFM acknowledgment mailbox (`g_bfm_ack_mb`) determines
  whether a conversion should be forwarded to the scoreboard.
- **Sampled monitor bridge** — accepted narrow-bus words are sampled in
  the testbench module and delivered through `g_mon_word_mb`, avoiding
  race-sensitive class sampling under random backpressure.
- **Async/ready decoupling** — the ready driver runs in a parallel
  `fork`; backpressure mode can be changed mid-test, and `BP_RANDOM_50`
  is generated deterministically on the safe clock edge.
- **Coverage gating** — all covergroup code is wrapped in
  `` `ifdef MPTDC_ENABLE_FUNC_COV ``. Smoke runs skip coverage;
  coverage runs pass `+define+MPTDC_ENABLE_FUNC_COV`.

---

## 2. Class Hierarchy

| Class | Role | Key Methods |
|-------|------|-------------|
| `mptdc_base_txn` | Root transaction | `kind`, `label` |
| `mptdc_cfg_txn` | DUT configuration | `pack_mode_reg()` |
| `mptdc_conv_txn` | START/STOP stimulus + expectations | delay, hit range, flag checks |
| `mptdc_reset_txn` | Hard reset | `low_time_ps`, `settle_time_ps` |
| `mptdc_backpressure_txn` | Ready mode switch | `mode` (READY/RANDOM/STALL) |
| `mptdc_eot_txn` | End-of-test signal | breaks driver/monitor loops |
| `mptdc_hit_txn` | Decoded single hit (data class) | nslow, nfast, ns, nf, pd_idx |
| `mptdc_packet_txn` | Complete captured packet | `parse_packet()`, `word_count()` |
| `mptdc_csr_driver` | CSR register access | `write()`, `read()`, `program_cfg()` |
| `mptdc_pulse_driver` | Async pulse injection | `inject_pair()`, `inject_start_only()` |
| `mptdc_ready_driver` | Narrow-bus backpressure | `set_mode()`, `run()` |
| `mptdc_generator` | Transaction queue | `add()`, `run()`, `expected_packet_count()` |
| `mptdc_driver` | Main stimulus orchestrator | consumes txns, routes to BFM |
| `mptdc_output_monitor` | Packet capture | `wait_accept()`, header/EOC detection |
| `mptdc_scoreboard` | Expectation checker | `check_packet()`, error counting |
| `mptdc_coverage` | Functional coverage | `sample_stim()`, `sample_packet()` |
| `mptdc_env` | Top-level environment | `run()` — forks all components |
| `mptdc_base_test` | Test base class | `build_sequence()`, `post_run()` |
| `mptdc_test_factory` | Test dispatcher | `create(name)` → test instance |

---

## 3. Transaction Types

Every transaction extends `mptdc_base_txn` and carries a `kind` enum:

### `mptdc_cfg_txn` (TXN_CFG)
Configures the DUT's operating mode via CSR writes.

| Field | Range | Description |
|-------|-------|-------------|
| `mode_cfg` | 0–1 | 0=MULTI_HIT, 1=FIRST_HIT |
| `input_sel` | 0–1 | 0=SPAD, 1=CAL |
| `out_mode` | 0–2 | 0=RAW_FEATURES, 1=RAW_TIMESTAMP, 2=FULL |
| `max_hits` | 0–15 | Max hits per conversion (0 = reject all) |
| `wdt_ctx_timeout` | 16-bit | Per-context watchdog (clock cycles) |
| `wdt_global_timeout` | 16-bit | Global watchdog (clock cycles) |

### `mptdc_conv_txn` (TXN_CONV)
Represents one conversion stimulus (START/STOP pulse pair or START-only).

| Field | Description |
|-------|-------------|
| `start_stop_delay_ps` | Delay between START and STOP (picoseconds) |
| `pulse_width_ps` | Pulse width (default 1000 ps) |
| `idle_after_ps` | Idle time after this conversion |
| `start_only` | 1 = no STOP pulse (triggers watchdog) |
| `expect_packet` | 1 = scoreboard expects a packet |
| `check_hit_range` | 1 = validate hit count in [min, max] |
| `min_hits`, `max_hits_allowed` | Expected hit count range |
| `check_firsthit_flag` | 1 = verify firsthit closure flag |
| `check_watchdog_flag` | 1 = verify watchdog closure flag |
| `check_conv_id` | 1 = verify conversion ID matches expected |
| `check_full_timestamp` | 1 = verify timestamp LSW in FULL mode |

### `mptdc_backpressure_txn` (TXN_BP)

| Mode | Value | Behavior |
|------|-------|----------|
| `BP_ALWAYS_READY` | 0 | narrow_ready = 1 always |
| `BP_RANDOM_50` | 1 | 50/50 random ready/stall each cycle |
| `BP_ALWAYS_STALL` | 2 | narrow_ready = 0 always |

---

## 4. Driver Components

### CSR Driver (`mptdc_csr_driver`)
Accesses DUT registers via the CSR interface (valid/ready handshake).

- `program_cfg(cfg)` — writes MODE, MAX_HITS, WDT registers
- `arm_only()` — sets CSR_CTRL bit 0 to arm conversion
- `fifo_clear()` — sets CSR_CTRL bit 1
- `soft_reset()` — sets CSR_CTRL bit 2

### Pulse Driver (`mptdc_pulse_driver`)
Injects asynchronous START/STOP pulses on SPAD or CAL inputs.

- `inject_pair(src, delay_ps, width_ps)` — START then STOP after delay
- `inject_start_only(src, width_ps)` — START only (no STOP)
- `hard_reset(low_ps, settle_ps)` — async_rst_n low/high

### Ready Driver (`mptdc_ready_driver`)
Controls narrow-bus backpressure in a background `fork`.

- Runs continuously, checking `stop_request` flag
- Mode can be changed mid-test via `set_mode()`

### Main Driver (`mptdc_driver`)
Consumes transactions from generator mailbox, routes by kind:

1. **TXN_CONV**: queues conversion for the module-resident BFM,
   samples coverage, and later forwards it to the expectation mailbox
   only if the BFM reports it was accepted
2. **TXN_CFG**: updates `current_cfg`, programs CSR
3. **TXN_BP**: switches ready driver mode
4. **TXN_RESET**: triggers hard reset via BFM
5. **TXN_EOT**: sets done flag, breaks loop

---

## 5. Monitor & Packet Parsing

The `mptdc_output_monitor` consumes accepted words from the sampled-word
mailbox populated in `mptdc_vip_tb.sv`:

1. **Wait** for sampled accepted words to appear
2. **Collect** 16-bit words until a complete packet is assembled
3. **Detect** header (bits [15:14] = 2'b10) and EOC (bits [15:14] = 2'b11)
4. **Parse** hits based on `out_mode` from header:
    - **RAW_FEATURES**: 3 words/hit (coarse timing, phase indices, event seq)
    - **RAW_TIMESTAMP**: 2 words/hit (`W0` raw coarse features, `W1` timestamp)
    - **FULL**: 4 words/hit (RAW_FEATURES `W0-W2` plus timestamp `W3`)
5. **Forward** parsed `mptdc_packet_txn` to scoreboard via mailbox

---

## 6. Scoreboard & Validation

The `mptdc_scoreboard` receives:
- **Expected** transactions from driver (via `exp_mb`)
- **Actual** packets from monitor (via `act_mb`)

### Validation checks in `check_packet()`:

| Check | Description |
|-------|-------------|
| Word count | Must equal `2 + hit_count × words_per_hit(out_mode)` |
| Hit array size | Decoded hits must match header hit_count |
| out_mode | Must match configured out_mode |
| Hit count range | If enabled: `min_hits ≤ hit_count ≤ max_hits_allowed` |
| Firsthit flag | If enabled: `flags.closed_by_firsthit == expected` |
| Maxhits flag | If enabled: `flags.closed_by_maxhits == expected` |
| Watchdog flag | If enabled: `flags.closed_by_watchdog == expected` |
| conv_id | If enabled: EOC conv_id matches expected counter |
| pd_idx | Must equal calculated value from (ns, nf) |
| event_seq | Must match hit index within packet |
| Timestamp | If enabled: LSW matches vernier calculation |

A test **passes** when `error_count == 0` at completion.

---

## 7. Coverage Model

Coverage is compiled only when `+define+MPTDC_ENABLE_FUNC_COV` is set.
Two covergroups sample different aspects of the verification space.

### Covergroup 1: `stim_cg` (Stimulus Coverage)

Sampled by the **driver** on every TXN_CONV.

| Coverpoint | Bins | What it covers |
|------------|------|----------------|
| `cp_mode` | `mh` (MULTI_HIT), `fh` (FIRST_HIT) | Operating mode |
| `cp_src` | `spad` (SPAD), `cal` (CAL) | Input source |
| `cp_out` | `raw_features`, `raw_timestamp`, `full` | Output format |
| `cp_bp` | `rdy` (READY), `rnd` (RANDOM_50), `stl` (STALL) | Backpressure |
| `cp_delay` | `very_short` (≤2ns), `short_d` (2–10ns), `medium_d` (10–20ns), `long_d` (>20ns) | START→STOP delay |
| `cp_jitter` | `none` (0ps), `light` (≤5ps), `heavy` (>5ps) | Oscillator jitter |
| `cp_start_only` | `no`, `yes` | START-only conversion |

**Cross coverage:**

| Cross | Dimensions | Total bins |
|-------|------------|-----------|
| `mode_x_out` | MODE × OUT_MODE | 2 × 3 = 6 |
| `mode_x_delay` | MODE × DELAY | 2 × 4 = 8 |
| `bp_x_delay` | BP × DELAY | 3 × 4 = 12 |

### Covergroup 2: `pkt_cg` (Packet Coverage)

Sampled by the **scoreboard** after validating each packet.

| Coverpoint | Bins | What it covers |
|------------|------|----------------|
| `cp_out` | `raw_features`, `raw_timestamp`, `full` | Output format seen |
| `cp_hits` | `zero` (0), `one` (1), `few` (2–4), `several` (5–10), `many` (11–14), `maxed` (15) | Hit count distribution |
| `cp_firsthit` | `off`, `on` | First-hit closure flag |
| `cp_maxhits` | `off`, `on` | Max-hits closure flag |
| `cp_watchdog` | `off`, `on` | Watchdog closure flag |
| `cp_phase0` | `low`, `high` | Slow counter phase snapshot |
| `cp_boundary` | `low`, `high` | Slow boundary increment |
| `cp_words` | auto-binned | Raw packet word count |

**Cross coverage:**

| Cross | Dimensions | Total bins |
|-------|------------|-----------|
| `flags_x_hits` | FIRSTHIT × MAXHITS × WATCHDOG × HITS | 2×2×2×6 = 48 |
| `out_x_boundary` | OUT_MODE × BOUNDARY | 3×2 = 6 |

### How Coverage Flows

```
                    ┌─────────────────────┐
  TXN_CONV created  │ driver.sample_stim()│──▶ stim_cg.sample(...)
                    └─────────────────────┘
                                                      ▲
                                                      │ delay_bin()
                                                      │ jitter_bin()
                                                      │ (bin index helpers)

                    ┌──────────────────────┐
  Packet validated  │ sb.sample_packet()   │──▶ pkt_cg.sample(...)
                    └──────────────────────┘
```

### Coverage Merge Strategy

Each test writes to a shared `-covworkdir` with `-covtest <name>`.
After all tests complete, the coverage database contains per-test
entries that IMC merges automatically when loaded.

---

## 8. Interface Definitions

### `mptdc_csr_if` — CSR Register Bus
```
Signals: csr_valid, csr_write, csr_addr[5:0], csr_wdata[31:0],
         csr_ready, csr_rvalid, csr_rdata[31:0]
Tasks:   reset_bus(), write_reg(addr, data), read_reg(addr, data)
```

### `mptdc_async_io_if` — Async Pulse I/O
```
Signals: async_rst_n, start_spad, stop_spad, cal_start, cal_stop
Tasks:   hard_reset(), inject_pair(), inject_start_only(), reset_pulses()
```

### `mptdc_narrow_if` — 16-bit Output Bus
```
Signals: clk_sys, narrow_ready, narrow_valid, narrow_data[15:0]
Protocol: Simple valid/ready streaming
```

---

## 9. Test Catalog

### Quick Reference

| # | Test Name | Packets | Key Validation | Corner Case |
|---|-----------|---------|----------------|-------------|
| 1 | `smoke_single_conv` | 1 | hit_count ≥ 1 | Basic end-to-end |
| 2 | `full_mode_timestamp` | 1 | Timestamp LSW matches | FULL output mode |
| 3 | `firsthit_contract` | 3 | firsthit_flag = 1 | FIRST_HIT closure |
| 4 | `backpressure_integrity` | 3 | Packets valid despite stalls | FIFO stress |
| 5 | `start_watchdog` | 2 | WDT flag toggles | Context watchdog |
| 6 | `cal_inject` | 1 | Packet from CAL input | Calibration path |
| 7 | `overflow_status` | 2+ | OVF_COUNT check | FIFO overflow |
| 8 | `long_random` | 8 | All timestamps valid | Extended random |
| 9 | `multi_conv_rearm_stress` | 12 | conv_id 0→11 | Rearm + mode switch |
| 10 | `global_watchdog_recovery` | 1–2 | WDT_STATUS.global_trip ≥ 1 | Global watchdog |
| 11 | `jitter_robustness` | 6 | Timestamps under jitter | Clock jitter |

### Detailed Test Descriptions

#### Test 1: `smoke_single_conv`
**Purpose:** Simplest sanity — one config, one conversion, one packet.

**Sequence:**
1. Hard reset (100 µs low, 100 µs settle)
2. Configure: MULTI_HIT, SPAD input, RAW_FEATURES, max_hits=15
3. Backpressure: ALWAYS_READY
4. Inject one conversion: 10 ns START→STOP delay
5. Expect: 1–15 hits, out_mode = RAW_FEATURES

**Why it matters:** If this fails, nothing else will work. Tests the
entire datapath from async pulse capture through packet assembly.

---

#### Test 2: `full_mode_timestamp`
**Purpose:** Validate FULL output mode with timestamp verification.

**Sequence:**
1. Hard reset
2. Configure: MULTI_HIT, OUT_MODE_FULL
3. One conversion: 15 ns delay, timestamp check enabled
4. Expect: 1–15 hits, timestamp LSW matches vernier calculation

**Why it matters:** FULL mode is the most data-rich output format.
Timestamp accuracy is critical for scientific measurements.

---

#### Test 3: `firsthit_contract`
**Purpose:** Verify FIRST_HIT mode closes on first hit arrival.

**Sequence:**
1. Hard reset
2. Configure: MODE_FIRST_HIT, disable context watchdog
3. Three conversions at delays {5, 11, 23} ns
4. Each expects: hit_count ≥ 1, firsthit_flag = 1

**Why it matters:** FIRST_HIT mode is essential for SPAD photon timing
applications where only the first photon arrival matters.

---

#### Test 4: `backpressure_integrity`
**Purpose:** Verify packet integrity under degraded ready signal.

**Sequence:**
1. Hard reset, configure MULTI_HIT
2. RANDOM_50 backpressure → inject one conversion
3. ALWAYS_STALL → inject two conversions (FIFO queues internally)
4. ALWAYS_READY → drain queued packets
5. Verify all packets are structurally valid

**Why it matters:** In a real ASIC, the downstream consumer may stall
the narrow bus. The TDC must buffer and deliver correct packets.

---

#### Test 5: `start_watchdog`
**Purpose:** Trigger and recover from per-context watchdog timeout.

**Sequence:**
1. Configure: max_hits=0, wdt_ctx=100 clocks (~625 ns)
2. Inject START-only (no STOP) → watchdog fires after ~625 ns
3. Expect: watchdog_flag = 1, hit_count = 0
4. Reconfigure: max_hits=15, disable watchdog
5. Normal conversion → expect: watchdog_flag = 0, hits ≥ 1

**Why it matters:** If START fires but STOP never arrives (e.g.,
photon lost), the watchdog prevents the TDC from hanging forever.

---

#### Test 6: `cal_inject`
**Purpose:** Validate the calibration pulse input path.

**Sequence:**
1. Configure: INPUT_CAL (calibration source)
2. Inject one CAL pulse pair: 12 ns delay
3. Expect: 1–15 hits from CAL path

**Why it matters:** The CAL input mux is a separate path used during
offline calibration. Must produce identical packet structure to SPAD.

---

#### Test 7: `overflow_status`
**Purpose:** Exercise FIFO overflow under sustained backpressure.

**Sequence:**
1. Configure: OUT_MODE_FULL, ALWAYS_STALL
2. Inject two rapid conversions (FIFO fills)
3. Inject START-only (overflow attempt)
4. Switch to ALWAYS_READY to drain
5. Post-run: read CSR_OVF_COUNT register

**Why it matters:** FIFO overflow is a critical failure mode. The
OVF_COUNT register lets software detect data loss.

---

#### Test 8: `long_random`
**Purpose:** Extended random stimulus with mixed delays and backpressure.

**Sequence:**
1. Configure: OUT_MODE_FULL, MULTI_HIT, RANDOM_50 backpressure
2. Eight conversions with delays 2–22 ns, 5 µs idle between
3. All require valid timestamps

**Why it matters:** Exercises the widest range of delay bins and
validates TDC linearity under realistic operating conditions.

---

#### Test 9: `multi_conv_rearm_stress`
**Purpose:** Verify conversion ID increments across mode switches.

**Sequence:**
1. Configure: MULTI_HIT, RAW_FEATURES
2. Eight conversions with conv_id check (expect 0–7)
3. Reconfigure: FIRST_HIT, RAW_TIMESTAMP
4. Four more conversions (expect conv_id 8–11)

**Why it matters:** The 14-bit conv_id must increment monotonically
even across reconfiguration. Software uses it to match events.

---

#### Test 10: `global_watchdog_recovery`
**Purpose:** Trigger and recover from global (system-wide) watchdog.

**Sequence:**
1. Configure: max_hits=0, wdt_global=128 clocks (~800 ns)
2. START-only → triggers global watchdog
3. Expect: watchdog_flag = 1, no valid packet
4. Reconfigure: normal operation
5. Post-run: verify CSR_WDT_STATUS.global_trip_cnt ≥ 1

**Why it matters:** The global watchdog is the last-resort recovery
mechanism. It must reset the TDC and report the event.

---

#### Test 11: `jitter_robustness`
**Purpose:** Verify TDC accuracy under oscillator jitter.

**Sequence:**
1. Requires plusargs: `+OSC_JITTER_SIGMA_PS=8 +OSC_JITTER_BOUND_PS=24`
2. Configure: OUT_MODE_FULL
3. Six conversions at delays {4, 8, 11, 17, 24, 31} ns
4. All require valid timestamps with conv_id check

**Why it matters:** Real oscillators have jitter. This test validates
that the Vernier TDC maintains measurement accuracy despite phase noise.

> **Note:** This test is in the smoke suite but NOT in the default
> coverage suite because it requires jitter plusargs.

---

## 10. Running Tests

### Smoke Regression (Verilator — fast, no coverage)

```bash
bash ci/run_vip_smoke.sh
```
Runs all 11 tests. Expected: 11/11 pass in roughly 5–8 minutes.

### Single Test (any simulator)

```bash
# Verilator (fast smoke)
bash scripts/sim/run_vip_test.sh smoke_single_conv --sim verilator

# Xcelium (industry simulator)
bash scripts/sim/run_vip_test.sh smoke_single_conv --sim xrun

# With coverage
bash scripts/sim/run_vip_test.sh smoke_single_conv --sim xrun \
     --func-cov --code-cov
```

### Coverage Regression (Xcelium)

```bash
bash ci/run_vip_coverage.sh --sim xrun --clean
```
Runs 9 tests with functional + code coverage. Results in
`build/vip_coverage_xrun/cov_work/`.

### Broader coverage + stress campaign

```bash
bash ci/run_coverage_campaign.sh --sim xrun --seeds 100 --conv-per-seed 5000 --jobs 32 --clean
```

### With jitter

```bash
bash scripts/sim/run_vip_test.sh jitter_robustness --sim xrun \
     --osc-jitter-sigma 8 --osc-jitter-bound 24
```

---

## 11. Coverage Reporting with IMC

IMC (Integrated Metrics Center) is Cadence's coverage analysis tool.
It does **not** support `-report` as a command-line flag.
Use `-exec` or `-execcmd` with Tcl commands instead.

### Generate Text Reports (batch mode)

Create a Tcl script `gen_cov_report.tcl`:

```tcl
# Load merged coverage database
load_test build/vip_coverage_xrun/cov_work -run *

# Functional coverage summary
report_metrics -out func_summary.txt -detail -kind cover

# Code coverage summary
report_metrics -out code_summary.txt -detail -kind block

exit
```

Run it:

```bash
imc -exec gen_cov_report.tcl -batch -nocopyright 2>&1 | tail -20
```

### Alternative: use `imc -execcmd` inline

```bash
# Functional coverage
imc -execcmd "
  load_test build/vip_coverage_xrun/cov_work -run *
  report_metrics -out func_report.txt -detail -kind cover
  exit
" -batch -nocopyright

# Code coverage
imc -execcmd "
  load_test build/vip_coverage_xrun/cov_work -run *
  report_metrics -out code_report.txt -detail -kind block
  exit
" -batch -nocopyright
```

### Interactive IMC (GUI)

```bash
imc -load build/vip_coverage_xrun/cov_work/scope/test &
```

In the GUI:
1. **Coverage Browser** → see hierarchical code coverage
2. **Functional Coverage** tab → expand covergroups, coverpoints, bins
3. Right-click → **Report** → export to text/HTML

### What to Look For

| Metric | Target | Notes |
|--------|--------|-------|
| **stim_cg** overall | >80% | Some crosses may be sparse |
| **pkt_cg** overall | >70% | flags_x_hits cross has 48 bins, many are rare |
| cp_mode bins | 100% | Both MULTI_HIT and FIRST_HIT must be hit |
| cp_src bins | 100% | Both SPAD and CAL must be hit |
| cp_out bins | 100% | All three output modes must be hit |
| cp_hits bins | ≥80% | `zero` and `maxed` are hardest to hit |
| cp_watchdog bins | 100% | Both on/off must be verified |
| Line coverage | >85% | Uncovered lines indicate untested paths |
| Branch coverage | >75% | Focus on FSM state transitions |
| Toggle coverage | >60% | 100% is rarely achievable; focus on control signals |

### Holes You May See (and Why)

| Hole | Reason | How to Close |
|------|--------|--------------|
| `cp_hits.maxed` (15 hits) | Needs exact max_hits=15 with long delay | `long_random` test with >30 ns delay |
| `cp_hits.zero` (0 hits) | Needs max_hits=0 or very short delay | `start_watchdog` test covers this |
| `cp_jitter.heavy` | Only hit when jitter_robustness runs | Add to coverage suite with plusargs |
| `bp_x_delay` sparse | Not all BP×delay combos exercised | Add targeted test or extend `long_random` |
| `flags_x_hits` sparse | 48-bin cross; many flag combos are rare | Expected — focus on realistic combos |

---

## 12. Expected Results

### Smoke Regression (11 tests)

```
VIP RESULTS: 11 passed, 0 failed out of 11
```

### Coverage Regression (9 tests)

```
VIP coverage results: 9 passed, 0 failed
```

### Per-Test Expected Behavior

| Test | Runtime | Packets | Key Output |
|------|---------|---------|------------|
| smoke_single_conv | <1s | 1 | `[SB] PASS` |
| full_mode_timestamp | <1s | 1 | `[SB] timestamp check PASS` |
| firsthit_contract | <1s | 3 | `[SB] firsthit=1` × 3 |
| backpressure_integrity | ~2s | 3 | Packets valid despite stalls |
| start_watchdog | ~1s | 2 | `watchdog=1` then `watchdog=0` |
| cal_inject | <1s | 1 | Packet from CAL source |
| overflow_status | ~2s | 2+ | `OVF_COUNT` logged |
| long_random | ~5s | 8 | All timestamps verified |
| multi_conv_rearm_stress | ~3s | 12 | conv_id 0→11 |
| global_watchdog_recovery | ~1s | 1–2 | `global_trip_cnt ≥ 1` |
| jitter_robustness | ~3s | 6 | Timestamps valid under jitter |

---

## 13. Narrow-Bus Packet Format

### 16-bit Word Encoding

```
HEADER  [15:14]=10  [13:12]=ctx_id  [11]=phase0_snap
        [10:7]=hit_count  [6:3]=flags  [2:1]=out_mode  [0]=slow_boundary_inc

  flags[3]=reserved  [2]=closed_by_watchdog
  flags[1]=closed_by_maxhits  [0]=closed_by_firsthit

  HIT WORDS (per out_mode):
  RAW_FEATURES (3 words/hit):
    W0: [14:8]=nslow  [7:1]=nfast_hit
    W1: [14:11]=ns  [10:7]=nf  [6:0]=pd_idx
    W2: [14:11]=event_seq  [10:4]=nfast_snap

  RAW_TIMESTAMP (2 words/hit):
    W0: same as RAW_FEATURES W0
    W1: t_raw_lsw[15:0]

  FULL (4 words/hit):
    W0–W2: same as RAW_FEATURES
    W3: t_raw_lsw[15:0]

EOC     [15:14]=11  [13:0]=conv_id (14-bit conversion counter)
```

### Total Packet Size

```
words = 2 + (hit_count × words_per_hit)

  RAW_FEATURES:  2 + 3 × hits
  RAW_TIMESTAMP: 2 + 2 × hits
  FULL:          2 + 4 × hits
```

---

## File Map

```
tb/vip/
├── README.md                  ← this file
├── filelist.f                 ← compile order for VIP sources
├── interfaces/
│   ├── mptdc_csr_if.sv        ← CSR register bus interface
│   ├── mptdc_async_io_if.sv   ← async pulse I/O interface
│   └── mptdc_narrow_if.sv     ← 16-bit output bus interface
└── pkg/
    └── mptdc_vip_pkg.sv       ← all VIP classes

tb/tests/
└── mptdc_vip_tb.sv            ← top-level harness + BFM / sampling bridge

tb/common/
├── mptdc_tb_pkg.sv            ← shared helpers (parsing, CSR tasks)
└── mptdc_raw_monitor.sv       ← raw narrow-bus monitor (directed TBs)

ci/
├── run_vip_smoke.sh           ← smoke regression (11 tests, Verilator)
├── run_vip_coverage.sh        ← coverage regression (9 tests, xrun)
└── run_coverage_campaign.sh   ← merged coverage + stress campaign (xrun)

scripts/sim/
└── run_vip_test.sh            ← single test runner (all simulators)
```
