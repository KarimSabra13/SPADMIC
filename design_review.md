# MPTDC Design Review

## 1. Executive Summary

This review covers the current working-tree state of `MPTDC/` and follows the requested order: architecture and RTL first, then propagation/jitter/raw behavior, then testbench capability, then calibration, then ASIC transfer risk.

Bottom line:

- **Architecture:** The live MPTDC is a coherent Vernier multi-phase TDC built around a `9 x 9` slow/fast phase matrix, `2` hardwired contexts, `15` max hits, and a clean split between an asynchronous/generated-clock measurement side and a `clk_sys` drain/serialization side. The true active hierarchy is `mptdc_top_asic -> mptdc_core -> {frontend, oscillators, PD array, counters, meas_ctrl, context bank, drain, FIFO, serializer, watchdog}`. `mptdc_pulse_sync.sv` and `mptdc_tconv_reco.sv` are compiled collateral, not part of the live top path. **[Directly observed]** Sources: `MPTDC/README.md:7-18, 102-129`; `MPTDC/docs/01_ARCHITECTURE.md:7-19, 35-70`; `MPTDC/rtl/filelist.f`; `MPTDC/rtl/top/mptdc_core.sv:316-441`.

- **Best-single-shot-RMS risk:** The biggest current issue is not an obvious digital logic bug; it is that the repository does **not yet empirically prove** raw one-shot RMS versus delay across `20 ps` to `30 ns`. The maintained collector and analysis scripts can compute aggregate residuals, INL/DNL, boundary-class bias, and phase heatmaps, but they do not provide a maintained fixed-delay repeated-measurement flow that would certify nominal `<15 ps` or jitter-included `<25 ps` one-shot RMS across the full range. **[Directly observed]** Sources: `MPTDC/tb/int/tb_campaign_collect.sv:208-308, 314-423, 428-553`; `MPTDC/scripts/analysis/analyze_campaign.py:128-165, 172-195, 202-247, 275-359`; `MPTDC/scripts/calibration/calibrate_6d_lut.py:441-465, 746-909`.

- **Linearity risk:** The design already acknowledges raw boundary/coherency bias: `slow_boundary_inc`, `phase0_snap`, fixed origin biases, STOP-side slow-count snapshot, and CAPTURE-side `nfast_snap` are all exported specifically to repair raw estimator structure offline. That is good engineering, but it also means the raw estimator is not self-sufficient. Additional linearity risk comes from the MULTI_HIT one-cycle close lag and from the fact that `event_seq` / `hit_idx` are scan-order quantities, not explicitly temporal hit order. **[Directly observed / strongly inferred]** Sources: `MPTDC/rtl/pkg/mptdc_pkg.sv:42-51, 284-313`; `MPTDC/rtl/async/mptdc_stop_capture_async.sv:10-23, 35-44`; `MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv:117-144, 166-240`; `MPTDC/rtl/ctrl/mptdc_drain_ctrl.sv:12-24, 101-150, 182-240`; `MPTDC/scripts/calibration/calibrate_6d_lut.py:3-14, 46-48`.

- **Robustness:** The design is reasonably robust for a research/offline-calibration architecture: there is explicit rejected-START accounting, a double-buffer context bank, a `64`-record FIFO, a per-context synthetic-STOP watchdog path, and a global force-reset watchdog. The remaining robustness limit is overload: only `2` contexts exist, so prolonged output stalls can still exhaust contexts once FIFO-backed draining is blocked. **[Directly observed]** Sources: `MPTDC/rtl/pkg/mptdc_pkg.sv:72-79, 87-90`; `MPTDC/rtl/async/mptdc_async_frontend_v2.sv:11-18, 76-100, 136-171`; `MPTDC/rtl/ctrl/mptdc_watchdog.sv`; `MPTDC/tb/int/tb_backpressure.sv:7-10, 41-57, 90-139`; `MPTDC/tb/int/tb_overflow_count.sv:7-10, 95-122`.

- **Calibration readiness:** The repository is well prepared for **offline** calibration. The maintained flow exports the right raw fields, preserves a stable 18-column CSV schema, and supports a 6D LUT keyed by inferred `(ns,nf)` plus coarse counts and header metadata. However, the strongest calibration claims in the docs are downstream script outputs, not direct bench proofs of raw performance targets. Calibration can remove structured mean error; it cannot remove independent oscillator jitter, source jitter, or model-vs-silicon mismatch. **[Directly observed / strongly inferred]** Sources: `MPTDC/docs/05_OFFLINE_CALIBRATION_PLAN.md:190-227, 239-272`; `MPTDC/tb/int/tb_campaign_collect.sv:269-299`; `MPTDC/scripts/calibration/calibrate_6d_lut.py:37-48, 65-110, 497-559, 773-909`.

- **ASIC transfer:** The synthesis collateral is real enough to show intent, but it is still exploratory. The active synthesis filelist excludes the behavioral oscillator model, uses the oscillator stub, creates virtual oscillator clocks on stub pins, runs only a typical MMMC view, and still contains placeholder PDK/library/physical-cell content. That is consistent with “flow-ready, not signoff-complete,” not with silicon-ready confidence. **[Directly observed]** Sources: `MPTDC/syn/README.md:17-29, 57-104, 167-179`; `MPTDC/syn/filelist_synth.f:26-29`; `MPTDC/syn/inputs/mptdc.sdc:32-45, 53-112`; `MPTDC/syn/inputs/mptdc.mmmc:13-16, 27-35, 47-50, 81-99`; `MPTDC/syn/libraries/libraries.xh018.tcl:25-45, 65-78`; `MPTDC/syn/libraries/libraries.xh018-stdcells.tcl:19-27, 64-80`; `MPTDC/syn/inputs/mptdc.defines:21-23, 45-55, 127-128`.

## 2. Review Objectives and Constraints

This review was performed under the following constraints:

- one final deliverable only: `design_review.md`
- no RTL, TB, script, documentation, or synthesis changes
- no issues/PRs/fixes; recommendations are document-only
- performance focus restricted to `20 ps` to `30 ns`
- ranking priority requested by the user: **single-shot RMS first**, then **linearity**, then **robustness**
- calibration assessed only **after** raw-architecture and raw-measurement reasoning

This document targets the **current working-tree** state of `MPTDC/`, not a frozen clean release.

Evidence labels used below:

- **[Directly observed]** = visible in RTL/TB/scripts/docs cited here
- **[Strongly inferred]** = not literally asserted by the repo, but follows directly from the cited implementation structure
- **[Hypothesis needing validation]** = plausible mechanism that the current repo does not yet empirically close

## 3. Repository Structure and Relevant Files

The repository is organized exactly as a mixed RTL / verification / analysis / synthesis project, and the MPTDC README matches that structure. **[Directly observed]** Sources: `MPTDC/README.md:7-18, 102-129`.

Relevant areas reviewed:

| Area | Key files reviewed | Why it matters |
|---|---|---|
| Top-level docs | `MPTDC/README.md`, `docs/01_ARCHITECTURE.md`, `docs/04_VERIFICATION.md`, `docs/05_OFFLINE_CALIBRATION_PLAN.md`, `docs/06_DEADTIME_ANALYSIS.md`, `docs/07_DESIGN_REVIEW.md`, `docs/08_LAB_RUNBOOK.md`, `docs/09_PROJECT_STATUS.md` | Declared intent, verification scope, calibration flow, and project status |
| Top-level RTL | `rtl/top/mptdc_top_asic.sv`, `rtl/top/mptdc_core.sv`, `rtl/pkg/mptdc_pkg.sv`, `rtl/filelist.f` | Real architecture, compiled hierarchy, timestamp contract |
| Async / PD / control RTL | `rtl/async/*`, `rtl/pd/mptdc_pd_cell.sv`, `rtl/ctrl/*` | Capture path, context handling, measurement close logic, drain sequencing |
| CDC / readout RTL | `rtl/cdc/*`, `rtl/readout/*` | Coarse-count coherency, reset strategy, FIFO, serializer, CSR, reconstruction |
| Oscillator RTL | `rtl/osc/*` | Jitter/startup model vs synthesis abstraction |
| Common TB infra | `tb/common/mptdc_raw_monitor.sv`, `tb/common/mptdc_tb_pkg.sv` | Packet framing and offline data extraction helpers |
| Integration TBs | `tb/int/*.sv` listed by the user | Functional behavior, deadtime, backpressure, CAL path, watchdogs, first-hit, overflow |
| Unit TBs | `tb/unit/*.sv` listed by the user | Leaf contract validation for mux/reset/watchdog/context bank/serializer |
| VIP | `tb/tests/mptdc_vip_tb.sv`, `tb/vip/README.md`, `tb/vip/filelist.f`, `tb/vip/interfaces/`, `tb/vip/pkg/` | Protocol-oriented regression, scoreboarding, coverage model |
| Analysis / calibration | `scripts/analysis/analyze_campaign.py`, `scripts/calibration/calibrate_6d_lut.py` | What metrics the repo actually extracts today |
| Simulation orchestration | `scripts/sim/run_tb.sh`, `run_campaign.sh`, `run_vip_test.sh`, `report_coverage.sh` | Maintained execution paths and simulator/coverage assumptions |
| Synthesis / ASIC | `syn/README.md`, `syn/filelist_synth.f`, `syn/inputs/*`, `syn/libraries/*`, `syn/scripts/*` | What the repo assumes about implementation realism |

## 4. Existing Documentation vs Current Implementation

### 4.1 Areas that are aligned

The high-level architecture documentation is substantially aligned with the live RTL:

- `README.md` and `docs/01_ARCHITECTURE.md` both describe a `9 x 9` Vernier matrix, `2` contexts, `15` max hits, `16`-bit output, simulation-only oscillator model, and synthesis-time oscillator stub. **[Directly observed]** Sources: `MPTDC/README.md:9-18, 29-39`; `MPTDC/docs/01_ARCHITECTURE.md:11-19, 20-34, 35-70`.
- `docs/02_OUTPUT_PROTOCOL.md` matches the live serializer contract, including header bit assignments, `RAW_FEATURES`, `RAW_TIMESTAMP`, and `FULL` formats, and the meaning of `event_seq` and `slow_boundary_inc`. **[Directly observed]** Sources: `MPTDC/docs/02_OUTPUT_PROTOCOL.md:17-37, 50-103, 105-156, 167-193`; `MPTDC/rtl/readout/mptdc_narrow16_tx_v2.sv:109-146`.
- `docs/03_CSR_MAP.md` matches the live CSR block, including `CTRL`, `MODE`, watchdog units, `OVF_COUNT`, and the quasi-static requirement for mode/input/output fields. **[Directly observed]** Sources: `MPTDC/docs/03_CSR_MAP.md:30-45, 48-80, 93-114, 182-193`; `MPTDC/rtl/readout/mptdc_csr_minimal.sv:10-26, 73-138, 149-226`.

### 4.2 Material mismatches or stale sections

1. **`docs/04_VERIFICATION.md` still points at old collection benches.**

   The active verification section lists the current unit/integration benches correctly, but its “collection and characterization benches” section still names `tb_v21_collect`, `tb_data_collect`, and `tb_v21_debug` as maintained collection flows. The current maintained collection path is instead `tb/int/tb_campaign_collect.sv` plus `scripts/sim/run_campaign.sh`, and `docs/05_OFFLINE_CALIBRATION_PLAN.md` already uses that updated path. **[Directly observed]** Sources: `MPTDC/docs/04_VERIFICATION.md:160-184, 186-219`; `MPTDC/docs/05_OFFLINE_CALIBRATION_PLAN.md:60-74`; `MPTDC/tb/int/tb_campaign_collect.sv:428-553`; `MPTDC/scripts/sim/run_campaign.sh:1-22, 225-280`.

2. **`docs/07_DESIGN_REVIEW.md` is directionally right, but partially outdated about implementation collateral.**

   The old review says there is “no real signoff constraint package.” The current repo now does contain an SDC/MMMC/Genus structure under `syn/`, so that statement is no longer literally true. The more accurate current statement is: the repo has a **trial** synthesis package that still stops well short of signoff completeness. **[Directly observed]** Sources: `MPTDC/docs/07_DESIGN_REVIEW.md:349-371`; `MPTDC/syn/README.md:17-29`; `MPTDC/syn/inputs/mptdc.sdc:32-45, 53-112`; `MPTDC/syn/inputs/mptdc.mmmc:13-16, 81-99`.

3. **Calibration claims are stronger than the maintained raw-bench proof structure.**

   `docs/05_OFFLINE_CALIBRATION_PLAN.md` reports historical/expected method comparisons and calibration outcomes, while the maintained benches and scripts are set up to produce those numbers offline. However, the current maintained flow still does not directly produce a fixed-delay one-shot RMS-vs-delay report or a TB-measured `N=1..15` same-delay averaging proof. **[Directly observed]** Sources: `MPTDC/docs/05_OFFLINE_CALIBRATION_PLAN.md:229-237, 269-272`; `MPTDC/scripts/calibration/calibrate_6d_lut.py:441-465, 746-909`; `MPTDC/tb/int/tb_campaign_collect.sv:428-553`.

## 5. Recommended Dependency / Analysis Order

The repository itself suggests a correct dependency order, and that order is also the right order for design review:

1. **`mptdc_pkg.sv`**: defines geometry, widths, states, records, and `vernier_tconv_ps()`; everything else depends on it. **[Directly observed]** Sources: `MPTDC/rtl/pkg/mptdc_pkg.sv:23-120, 284-313`.
2. **`mptdc_input_mux.sv`**: defines where asynchronous START/STOP originate. **[Directly observed]** Sources: `MPTDC/rtl/ctrl/mptdc_input_mux.sv:11-22, 47-51`.
3. **`mptdc_async_frontend_v2.sv`** and **`mptdc_stop_capture_async.sv`**: define ownership of START/STOP, context allocation, oscillator enables, and STOP-side metadata. **[Directly observed]** Sources: `MPTDC/rtl/async/mptdc_async_frontend_v2.sv:11-18, 62-171`; `MPTDC/rtl/async/mptdc_stop_capture_async.sv:10-23, 35-44`.
4. **Oscillator wrapper/model/stub + `mptdc_pd_cell.sv`**: define what is actually being measured. **[Directly observed]** Sources: `MPTDC/rtl/osc/mptdc_osc_wrapper.sv:10-20, 45-70`; `MPTDC/rtl/osc/mptdc_osc_model.sv:10-29, 44-49, 54-91, 117-143`; `MPTDC/rtl/osc/mptdc_osc_stub.sv:10-17, 31-34`; `MPTDC/rtl/pd/mptdc_pd_cell.sv:10-33, 53-99`.
5. **`mptdc_meas_ctrl.sv`**: explains when the measurement stops and what “done” means. **[Directly observed]** Sources: `MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv:70-144, 166-240`.
6. **CDC and context storage**: `mptdc_gray_cnt_sync.sv`, `mptdc_reset_sync.sv`, `mptdc_pulse_sync.sv`, `mptdc_context_bank.sv`, `mptdc_sync_fifo.sv`. **[Directly observed]** Sources: `MPTDC/rtl/cdc/mptdc_gray_cnt_sync.sv:10-42, 84-194`; `MPTDC/rtl/async/mptdc_context_bank.sv:16-24, 64-94`.
7. **Drain and readout**: `mptdc_drain_ctrl.sv`, `mptdc_narrow16_tx_v2.sv`, `mptdc_tconv_reco.sv`, `mptdc_csr_minimal.sv`. **[Directly observed]** Sources: `MPTDC/rtl/ctrl/mptdc_drain_ctrl.sv:12-24, 131-151, 157-252`; `MPTDC/rtl/readout/mptdc_narrow16_tx_v2.sv:11-20, 57-103, 109-146, 157-314`; `MPTDC/rtl/readout/mptdc_csr_minimal.sv:10-26, 83-138, 149-226`.
8. **Top integration**: revisit `mptdc_core.sv` and `mptdc_top_asic.sv` only after understanding the blocks. **[Directly observed]** Sources: `MPTDC/docs/01_ARCHITECTURE.md:35-70, 84-167`; `MPTDC/rtl/top/mptdc_core.sv:316-441`.
9. **Only then** inspect `tb_campaign_collect.sv`, `analyze_campaign.py`, and `calibrate_6d_lut.py` to judge whether the raw design is being observed and characterized well enough. **[Directly observed]** Sources: `MPTDC/tb/int/tb_campaign_collect.sv:208-423, 428-553`; `MPTDC/scripts/analysis/analyze_campaign.py:128-165, 172-247`; `MPTDC/scripts/calibration/calibrate_6d_lut.py:37-110, 497-909`.

## 6. Top-Level MPTDC Architecture

### 6.1 True live hierarchy

The live top is:

```text
mptdc_top_asic
  -> reset_sync(clk_sys domain)
  -> input_mux(async SPAD/CAL select)
  -> csr_minimal
  -> mptdc_core
       -> reset_sync(fast domain)
       -> async_frontend_v2
       -> osc_wrapper(slow)
       -> osc_wrapper(fast)
       -> pd_cell x 81
       -> stop_capture_async
       -> gray_cnt_sync(slow)
       -> gray_cnt_sync(fast)
       -> meas_ctrl
       -> context_bank
       -> drain_ctrl
       -> sync_fifo
       -> narrow16_tx_v2
       -> watchdog
```

`mptdc_pulse_sync.sv` and `mptdc_tconv_reco.sv` are compiled, but not instantiated in the live top path. **[Directly observed]** Sources: `MPTDC/docs/01_ARCHITECTURE.md:35-70`; `MPTDC/rtl/top/mptdc_core.sv:316-441`; `MPTDC/rtl/filelist.f`; `MPTDC/README.md:23-28`.

### 6.2 Measurement pipeline

The live measurement pipeline is:

1. `START` is selected by `mptdc_input_mux` and accepted by `mptdc_async_frontend_v2` only if `conv_arm=1` and a context is free.
2. START sets `start_latched`, allocates `active_ctx`, and enables the slow oscillator.
3. `STOP` sets `stop_latched`, enables the fast oscillator, enables the PD array, triggers the STOP-side boundary capture, and asynchronously snapshots the slow Gray counter.
4. The `81` PD cells sample slow taps on fast taps and latch per-cell hits plus `nfast_hit`.
5. `mptdc_meas_ctrl` closes the conversion on FIRST_HIT, MAX_HITS, or watchdog, then sequences `CAPTURE -> STOP_OSC -> CLEAR`.
6. `mptdc_context_bank` freezes the full measurement image.
7. `mptdc_drain_ctrl` scans the frozen image in `clk_sys`, emits one META record plus HIT records, and releases the context.
8. `mptdc_sync_fifo` buffers those records.
9. `mptdc_narrow16_tx_v2` packetizes them into header/hit/EOC words.

**[Directly observed]** Sources: `MPTDC/rtl/ctrl/mptdc_input_mux.sv:47-51`; `MPTDC/rtl/async/mptdc_async_frontend_v2.sv:97-171`; `MPTDC/rtl/async/mptdc_stop_capture_async.sv:35-44`; `MPTDC/rtl/pd/mptdc_pd_cell.sv:10-33, 76-99`; `MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv:137-240`; `MPTDC/rtl/async/mptdc_context_bank.sv:64-94`; `MPTDC/rtl/ctrl/mptdc_drain_ctrl.sv:157-252`; `MPTDC/rtl/readout/mptdc_narrow16_tx_v2.sv:157-314`.

### 6.3 Domain partitioning

The design intentionally mixes:

- `clk_sys` (`160 MHz`) for CSR, drain, FIFO, serializer, and global watchdog
- `osc_fast_ph0` for measurement control and fast-domain snapshot timing
- `fast_phase[0..8]` as PD-cell sampling clocks
- `slow_phase[0..8]` as PD sampled signals and slow-count source
- asynchronous START/STOP / latch structures

That partitioning is appropriate for this kind of TDC, but it means the measurement side must be reviewed as an intentional mixed async/generated-clock macro, not as ordinary synchronous RTL. **[Directly observed]** Sources: `MPTDC/docs/01_ARCHITECTURE.md:72-83`; `MPTDC/rtl/top/mptdc_core.sv:316-369`; `MPTDC/rtl/osc/mptdc_osc_wrapper.sv:18-20`; `MPTDC/rtl/pd/mptdc_pd_cell.sv:29-33`.

## 7. Detailed RTL Review by Block

| Block | Role | Timing/precision contribution | Main review point |
|---|---|---|---|
| `rtl/pkg/mptdc_pkg.sv` | Source of truth for geometry, widths, records, timestamp helper | Defines `DELTA_LSB=10 ps`, `K_VERNIER=11`, origin biases, FIFO/context sizing | Strong package; raw timestamp semantics live here, not in docs alone. **[Directly observed]** Sources: `MPTDC/rtl/pkg/mptdc_pkg.sv:23-79, 284-313` |
| `rtl/top/mptdc_top_asic.sv` | Pad-facing wrapper | No measurement itself; sets the boundary above the core | Clean wrapper; keeps complexity inside `mptdc_core`. **[Directly observed]** Sources: `MPTDC/docs/01_ARCHITECTURE.md:37-57` |
| `rtl/top/mptdc_core.sv` | Full integration point | Wires together all precision-relevant surfaces | Design center; the architecture hangs together. **[Directly observed]** Sources: `MPTDC/rtl/top/mptdc_core.sv:316-441` |
| `rtl/async/mptdc_async_frontend_v2.sv` | START/STOP ownership, context allocation, oscillator enables | Defines acceptance/rejection and start/stop asymmetry | Intentional latch-based async frontend; signoff hotspot, not obviously a logic bug. **[Directly observed]** Sources: `MPTDC/rtl/async/mptdc_async_frontend_v2.sv:62-171` |
| `rtl/async/mptdc_stop_capture_async.sv` | STOP-side boundary metadata | Samples phase0 and boundary carry on async STOP edge | Good calibration hook; inherently non-standard async sampling. **[Directly observed]** Sources: `MPTDC/rtl/async/mptdc_stop_capture_async.sv:10-23, 35-44` |
| `rtl/async/mptdc_context_bank.sv` | Frozen per-context image | Stores STOP/CAPTURE metadata and PD bitmap atomically | Good double-buffering choice; bus read relies on static-data CDC assumption. **[Directly observed]** Sources: `MPTDC/rtl/async/mptdc_context_bank.sv:16-24, 64-94` |
| `rtl/ctrl/mptdc_input_mux.sv` | SPAD vs CAL path selection | Determines raw source path without adding latency | Pure async mux is correct for timing fidelity, but `input_sel` must stay stable. **[Directly observed]** Sources: `MPTDC/rtl/ctrl/mptdc_input_mux.sv:11-22, 47-51` |
| `rtl/ctrl/mptdc_meas_ctrl.sv` | Fast-domain close FSM | FIRST_HIT close is immediate; MULTI_HIT close is one-cycle delayed; STOP_OSC protects clear timing | Strong block; one-cycle MULTI_HIT lag is the main local linearity caveat. **[Directly observed]** Sources: `MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv:70-144, 178-240` |
| `rtl/ctrl/mptdc_drain_ctrl.sv` | Sys-domain scanner | Converts frozen context to ordered META/HIT records | Robust drain path; `event_seq` is scan order, not an explicit chronological sort. **[Directly observed]** Sources: `MPTDC/rtl/ctrl/mptdc_drain_ctrl.sv:12-24, 101-150, 182-240` |
| `rtl/ctrl/mptdc_watchdog.sv` | Global inactivity recovery | Prevents system-side lockup | Safety net, not a precision feature. **[Directly observed]** Sources: `MPTDC/tb/unit/tb_watchdog_unit.sv:71-141` |
| `rtl/cdc/mptdc_gray_cnt_sync.sv` | Gray-coded coarse-count transfer and snapshot | Core coarse-count coherency block | Good design with a very important snapshot-preservation invariant. **[Directly observed]** Sources: `MPTDC/rtl/cdc/mptdc_gray_cnt_sync.sv:18-42, 84-194` |
| `rtl/cdc/mptdc_pulse_sync.sv` | Generic toggle synchronizer | Compiled helper for pulse CDC | Fine generic primitive, but not used in the live top path. **[Directly observed]** Sources: `MPTDC/rtl/cdc/mptdc_pulse_sync.sv:10-28, 42-72` |
| `rtl/cdc/mptdc_reset_sync.sv` | Async-assert/sync-deassert reset | Domain-safe reset release | Conventional and well unit-tested. **[Directly observed]** Sources: `MPTDC/tb/unit/tb_reset_sync_unit.sv:7-10, 95-166` |
| `rtl/cdc/mptdc_sync_fifo.sv` | Sys-domain buffer | Decouples drain from serializer | Important robustness buffer; not a raw-timing limiter. **[Directly observed]** Sources: `MPTDC/rtl/top/mptdc_core.sv:403-418`; `MPTDC/rtl/pkg/mptdc_pkg.sv:76-79` |
| `rtl/osc/mptdc_osc_model.sv` | Behavioral multi-phase oscillator | Injects per-half-period jitter and startup offsets | Useful simulation model, not an analog or synthesis model. **[Directly observed]** Sources: `MPTDC/rtl/osc/mptdc_osc_model.sv:10-29, 44-49, 54-91, 117-143` |
| `rtl/osc/mptdc_osc_stub.sv` | Static synthesis placeholder | No real oscillation | Necessary abstraction boundary, but no actual TDC measurement in this mode. **[Directly observed]** Sources: `MPTDC/rtl/osc/mptdc_osc_stub.sv:10-17, 31-34` |
| `rtl/osc/mptdc_osc_wrapper.sv` | Model/stub selector | Defines what simulation and synthesis actually use | Honest abstraction layer. **[Directly observed]** Sources: `MPTDC/rtl/osc/mptdc_osc_wrapper.sv:10-20, 45-70` |
| `rtl/pd/mptdc_pd_cell.sv` | Fine Vernier crossing detector | Latches per-cell hit and `nfast_hit` on falling-edge detection | Core fine-timing primitive; physically sensitive in silicon. **[Directly observed]** Sources: `MPTDC/rtl/pd/mptdc_pd_cell.sv:10-33, 76-99` |
| `rtl/readout/mptdc_tconv_reco.sv` | Standalone reconstruction helper | Compiled reference only | Not used in the live top path. **[Directly observed]** Sources: `MPTDC/docs/01_ARCHITECTURE.md:59-70`; `MPTDC/rtl/top/mptdc_core.sv:421-431` |
| `rtl/readout/mptdc_narrow16_tx_v2.sv` | Packet serializer | Computes `t_raw_ps`, exposes output modes, emits `conv_id` | Critical live timestamp and protocol block. **[Directly observed]** Sources: `MPTDC/rtl/readout/mptdc_narrow16_tx_v2.sv:94-146, 157-314` |
| `rtl/readout/mptdc_csr_minimal.sv` | Software-visible config/status | Controls mode/input/output/watchdogs/arm/reset | Semantically clear, with important watchdog-unit and `conv_arm` behavior. **[Directly observed]** Sources: `MPTDC/rtl/readout/mptdc_csr_minimal.sv:10-26, 83-138, 149-226` |

## 8. Async Front-End and Capture Path Analysis

### 8.1 START/STOP ownership and asymmetry

The live frontend is intentionally asymmetric:

- START allocates a context and starts the **slow** oscillator.
- STOP starts the **fast** oscillator, enables the PD matrix, captures STOP-side phase metadata, and snapshots the slow coarse counter asynchronously.

That asymmetry is fundamental to the architecture. It is not a documentation artifact; it is visible directly in the frontend outputs and in the core instantiations. **[Directly observed]** Sources: `MPTDC/rtl/async/mptdc_async_frontend_v2.sv:163-171`; `MPTDC/rtl/top/mptdc_core.sv:316-333, 353-386`.

### 8.2 Why the async path is intentional

`mptdc_input_mux.sv` is explicitly a pure combinational mux because registering START/STOP would destroy the time relationship being measured. `mptdc_async_frontend_v2.sv` then uses `always_latch` storage for START, STOP, `active_ctx`, and `ctx_drain`. This is deliberate measurement-structure RTL, not an accidental “bad CDC” pattern. **[Directly observed]** Sources: `MPTDC/rtl/ctrl/mptdc_input_mux.sv:11-22`; `MPTDC/rtl/async/mptdc_async_frontend_v2.sv:103-143`.

### 8.3 Local hazards

1. **Raw async input cleanliness matters directly.**

   There is no synchronizer before the measurement latch path, because the purpose of the design is to measure the arrival relationship itself. That means input quality, pulse width, and physical routing quality directly affect the captured boundary. **[Directly observed / strongly inferred]** Sources: `MPTDC/rtl/ctrl/mptdc_input_mux.sv:13-21`; `MPTDC/rtl/async/mptdc_async_frontend_v2.sv:103-120`.

2. **Short-delay measurements are especially startup-sensitive.**

   The slow oscillator begins on START, and the fast oscillator plus PD gating begin only after STOP. The behavioral model includes deterministic per-tap startup offsets (`k * TS_STEP`) and clean enable/reset behavior, but it does not model analog startup amplitude/phase settling. Therefore the very-short-delay end of the requested range is the least well backed by model realism. **[Directly observed / strongly inferred]** Sources: `MPTDC/rtl/osc/mptdc_osc_model.sv:22-29, 117-143`; `MPTDC/rtl/async/mptdc_async_frontend_v2.sv:169-171`.

3. **Boundary ambiguity is explicitly acknowledged by the design.**

   `mptdc_stop_capture_async.sv` exports `phase0_snap` and `slow_boundary_inc`, and the package comment says the boundary carry exists because raw loop indices and live capture semantics are not identical. That is strong evidence that phase-0 boundary behavior is a known raw-design issue which calibration is expected to absorb. **[Directly observed]** Sources: `MPTDC/rtl/async/mptdc_stop_capture_async.sv:15-23, 35-44`; `MPTDC/rtl/pkg/mptdc_pkg.sv:42-51`.

## 9. Oscillator / Phase / Delay Modeling Review

### 9.1 What the repo actually models

The behavioral oscillator model is not an ideal clock. It models:

- half-periods derived from `NE * TS_STEP_PS` (`495 ps` slow, `450 ps` fast)
- per-tap startup offsets `k * TS_STEP_PS`
- optional Gaussian jitter per half-period via `+OSC_JITTER_SIGMA_PS` and `+OSC_JITTER_BOUND_PS`
- a 1 ps delayed `phase0_guard_o` and a 10 ps delayed `phase7d_probe_o`

**[Directly observed]** Sources: `MPTDC/rtl/osc/mptdc_osc_model.sv:44-49, 54-91, 117-143`.

### 9.2 What the repo does **not** model

The repo does **not** model:

- a real analog ring-oscillator macro interface in synthesis
- correlated phase noise, supply pushing, or temperature drift beyond a simple period-jitter abstraction
- tap-to-tap physical mismatch caused by layout/routing
- amplitude/startup analog effects beyond deterministic startup delay
- post-layout parasitics or PVT corner spread in the active measurement model

The synthesis path instead uses a static stub with `phase[0]=1` and all other taps `0`. **[Directly observed]** Sources: `MPTDC/rtl/osc/mptdc_osc_stub.sv:10-17, 31-34`; `MPTDC/syn/filelist_synth.f:26-29`.

### 9.3 Jitter and delay implications

Because the model applies jitter **inside the half-period toggle loop**, raw timing uncertainty should grow with the number of oscillator half-cycles involved in a measurement. In other words, even if the current jitter source is simple, it is still a count-dependent uncertainty source, not a fixed offset. Since `nslow` and `nfast` also enter `vernier_tconv_ps()` directly, longer delays should naturally show more jitter-related spread than very short delays. **[Strongly inferred]** Sources: `MPTDC/rtl/osc/mptdc_osc_model.sv:121-138`; `MPTDC/rtl/pkg/mptdc_pkg.sv:292-299`.

That matters for the user’s targets:

- **sub-15 ps nominal** may be plausible only after removing systematic bias and only where startup/boundary effects are tame
- **sub-25 ps jitter-included** depends heavily on whether count-dependent spread remains small enough at the long-delay end

The current repo does not yet provide a maintained per-delay proof of either statement. **[Directly observed / strongly inferred]** Sources: `MPTDC/scripts/analysis/analyze_campaign.py:152-165, 275-300`; `MPTDC/tb/int/tb_campaign_collect.sv:428-553`.

## 10. CDC / Synchronization / Coherency Review

### 10.1 Strong points

- `mptdc_reset_sync` is conventional async-assert/sync-deassert logic, and the dedicated unit bench verifies 2-stage, 3-stage, reassertion, and clock-stopped behavior. **[Directly observed]** Sources: `MPTDC/tb/unit/tb_reset_sync_unit.sv:7-10, 95-200`.
- `mptdc_gray_cnt_sync` uses Gray encoding and independent 2-FF synchronizer chains for continuous and snapshot channels. **[Directly observed]** Sources: `MPTDC/rtl/cdc/mptdc_gray_cnt_sync.sv:35-42, 140-194`.
- `mptdc_context_bank` clearly states the static-data CDC contract for the read bus. **[Directly observed]** Sources: `MPTDC/rtl/async/mptdc_context_bank.sv:16-24, 80-94`.
- The synthesis SDC recognizes the three async clock groups and preserves synchronizer flops with `set_dont_touch`. **[Directly observed]** Sources: `MPTDC/syn/inputs/mptdc.sdc:47-56, 77-112`.

### 10.2 The key coarse-count invariant

`mptdc_gray_cnt_sync.sv` includes a critical comment: `src_clr` must **not** clear the snapshot register, or quasi-simultaneous START and STOP could destroy the STOP snapshot before Gray CDC propagation completes. That is exactly the kind of subtle coarse-count coherency bug that would silently break raw timing. The comment and implementation are both explicit. **[Directly observed]** Sources: `MPTDC/rtl/cdc/mptdc_gray_cnt_sync.sv:26-34, 84-107, 130-139`.

### 10.3 Residual coherency caveat

The design improves coarse/fine coherency, but it still mixes data from different instants:

- `nslow` is STOP-side
- `nfast_hit` is per-hit crossing-side
- `nfast_snap` is CAPTURE-side
- `phase0_snap` / `slow_boundary_inc` are STOP-side

That is not automatically wrong, but it means the raw digital architecture depends on offline correction to align these frames. The design is therefore calibration-friendly, not calibration-free. **[Directly observed / strongly inferred]** Sources: `MPTDC/rtl/top/mptdc_core.sv:316-386`; `MPTDC/rtl/async/mptdc_context_bank.sv:11-21, 67-77`; `MPTDC/rtl/readout/mptdc_narrow16_tx_v2.sv:60-80, 123-142`.

## 11. Measurement Control and Context Handling Review

### 11.1 Measurement closure semantics

`mptdc_meas_ctrl.sv` closes conversions in three ways:

- FIRST_HIT: immediate OR-reduction of `hit_level_i`
- MULTI_HIT: compare `max_hits_cfg_i` against the **registered** `hit_cnt_q`
- watchdog: compare a fast-domain timeout counter against `wdt_timeout_i`

The FSM sequence is `IDLE -> MEASURE -> CAPTURE -> STOP_OSC -> CLEAR -> IDLE`, and `pd_gate_o` is only high in MEASURE. That is a real improvement over a simpler “clear while clocks are still running” architecture. **[Directly observed]** Sources: `MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv:70-144, 178-240`.

### 11.2 Main local timing caveat: MULTI_HIT lag

The MULTI_HIT close path compares against `hit_cnt_q`, which is sampled from the combinational popcount tree one fast cycle later. That means the close decision is intentionally one-cycle late relative to the true first moment of saturation. In FIRST_HIT mode, this lag does not exist. **[Directly observed]** Sources: `MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv:117-144`.

Why it matters:

- it can allow late hits to enter before close fires
- it changes the raw distribution of `hit_count` and packet contents
- it likely contributes more to **linearity/interpretation** than to pure single-hit RMS

**[Strongly inferred]** Sources: `MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv:117-144, 198-240`; `MPTDC/tb/int/tb_firsthit_mode.sv:68-72`.

### 11.3 Context handling and robustness

The context system is small but thoughtful:

- `N_CTX = 2` hardwires a double buffer
- `start_rejected_o` goes high on a START that cannot be accepted
- `mptdc_drain_ctrl` uses a `released_mask` so a just-released context is not re-selected while the async clear is still propagating
- `OVF_COUNT` counts **rejected STARTs**, not hit saturation

**[Directly observed]** Sources: `MPTDC/rtl/pkg/mptdc_pkg.sv:87-90`; `MPTDC/rtl/async/mptdc_async_frontend_v2.sv:11-18, 76-100`; `MPTDC/rtl/ctrl/mptdc_drain_ctrl.sv:62-96`; `MPTDC/docs/03_CSR_MAP.md:182-193`.

The practical robustness limit is therefore not “any stall breaks the design”; it is “enough stalling will eventually fill FIFO-backed draining and exhaust the two contexts.” **[Strongly inferred]** Sources: `MPTDC/rtl/pkg/mptdc_pkg.sv:76-79, 87-90`; `MPTDC/tb/int/tb_backpressure.sv:7-10, 41-57, 90-139`; `MPTDC/tb/int/tb_overflow_count.sv:59-60, 95-122`.

## 12. Readout / Reconstruction / Output Protocol Review

### 12.1 Live output contract

The serializer emits:

- one header word (`ctx_id`, `phase0_snap`, `hit_count`, `flags`, `out_mode`, `slow_boundary_inc`)
- `2/3/4` words per hit depending on `out_mode`
- one EOC word with the local `14`-bit `conv_id`

The packet structure in `docs/02_OUTPUT_PROTOCOL.md` matches the live RTL. **[Directly observed]** Sources: `MPTDC/docs/02_OUTPUT_PROTOCOL.md:17-37, 50-156, 158-193`; `MPTDC/rtl/readout/mptdc_narrow16_tx_v2.sv:109-146, 264-314`.

### 12.2 The live timestamp path is in the serializer

The active top-level path does **not** instantiate `mptdc_tconv_reco.sv`; instead, `mptdc_narrow16_tx_v2.sv` computes `t_raw_ps` directly from `vernier_tconv_ps()`. That matters for future review and for understanding where the raw timestamp contract actually lives. **[Directly observed]** Sources: `MPTDC/rtl/top/mptdc_core.sv:421-431`; `MPTDC/rtl/readout/mptdc_narrow16_tx_v2.sv:94-103, 132-142`.

### 12.3 Important semantic subtlety: `event_seq` and `hit_idx`

`docs/02_OUTPUT_PROTOCOL.md` explicitly defines `event_seq` as “order in which the drain FSM discovered the hit while scanning the frozen PD bitmap,” and `mptdc_drain_ctrl.sv` confirms that the drain FSM linearly scans `pd_scan_q`, increments `event_seq_q` when a hit is found, and emits hits in that scan order. `tb_campaign_collect.sv` then writes `hit_idx` as packet row order (`hits_found`) and separately logs `event_seq`. **[Directly observed]** Sources: `MPTDC/docs/02_OUTPUT_PROTOCOL.md:89-103`; `MPTDC/rtl/ctrl/mptdc_drain_ctrl.sv:101-124, 143-150, 182-240`; `MPTDC/tb/int/tb_campaign_collect.sv:269-299`.

That means `hit_idx` in the calibration flow is **not guaranteed to mean chronological hit order**. It is output-stream order after bitmap scan. This is a very important distinction because `calibrate_6d_lut.py` uses `hit_idx` as a LUT key dimension. **[Directly observed / strongly inferred]** Sources: `MPTDC/scripts/calibration/calibrate_6d_lut.py:3-14, 46-48`; `MPTDC/rtl/ctrl/mptdc_drain_ctrl.sv:101-124, 233-240`.

### 12.4 CSR/readout semantics that matter for measurement

- `MODE` fields (`mode_cfg`, `input_sel`, `out_mode`) are intended to stay quasi-static during measurement. **[Directly observed]** Sources: `MPTDC/docs/03_CSR_MAP.md:70-80`; `MPTDC/rtl/ctrl/mptdc_input_mux.sv:18-21`; `MPTDC/rtl/readout/mptdc_csr_minimal.sv:113-117`.
- `WDT_CTX` is consumed in the **fast** measurement domain; `WDT_GLOBAL` is consumed in `clk_sys`. **[Directly observed]** Sources: `MPTDC/docs/03_CSR_MAP.md:93-114`; `MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv:145-157`; `MPTDC/tb/unit/tb_watchdog_unit.sv:71-141`.
- `CTRL` writes rewrite `conv_arm`, so `fifo_clr` or `soft_rst` also de-arm unless software re-arms afterward. **[Directly observed]** Sources: `MPTDC/docs/03_CSR_MAP.md:48-69`; `MPTDC/rtl/readout/mptdc_csr_minimal.sv:105-137`.

## 13. Propagation Delay and Timing Sensitivity Analysis

### 13.1 End-to-end sensitivity map

| Path | Sensitive mechanism | Primary impact |
|---|---|---|
| `input_mux -> async_frontend` | raw async pulse routing, mux select stability | single-shot RMS / robustness |
| `START -> slow oscillator enable` | slow-osc startup timing | short-delay RMS / offset |
| `STOP -> fast oscillator enable + stop_capture + slow Gray snapshot` | STOP-edge alignment across multiple capture structures | linearity / raw offset |
| `slow_phase[*] / fast_phase[*] -> PD cells` | tap delay mismatch, boundary crossing, per-cell detection timing | single-shot RMS / linearity |
| `PD hit map -> meas_ctrl close` | FIRST_HIT immediate vs MULTI_HIT one-cycle lag | linearity / hit statistics |
| `CAPTURE -> context_bank -> drain` | static-data CDC assumption | robustness / signoff realism |
| `drain scan -> serializer` | scan-order hit emission, not chronological sort | calibration stability / interpretation |

**[Directly observed / strongly inferred]** Sources: `MPTDC/rtl/ctrl/mptdc_input_mux.sv:11-22, 47-51`; `MPTDC/rtl/async/mptdc_async_frontend_v2.sv:97-171`; `MPTDC/rtl/async/mptdc_stop_capture_async.sv:35-44`; `MPTDC/rtl/pd/mptdc_pd_cell.sv:10-33, 76-99`; `MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv:117-144, 178-240`; `MPTDC/rtl/async/mptdc_context_bank.sv:16-24, 80-94`; `MPTDC/rtl/ctrl/mptdc_drain_ctrl.sv:12-24, 182-240`.

### 13.2 Mechanisms most likely to hurt precision and linearity

1. **Oscillator startup and accumulated jitter**: most important for raw precision, especially because the repo uses ring-oscillator-style references, not locked clocks. **[Strongly inferred]** Sources: `MPTDC/rtl/osc/mptdc_osc_model.sv:15-18, 22-29, 121-138`.
2. **Boundary handling around slow phase 0**: explicitly important enough that the design exports `slow_boundary_inc`. **[Directly observed]** Sources: `MPTDC/rtl/async/mptdc_stop_capture_async.sv:15-23, 35-44`; `MPTDC/rtl/pkg/mptdc_pkg.sv:42-51, 292-299`.
3. **Coarse/fine temporal mismatch**: `nslow`, `nfast_hit`, `nfast_snap`, and header metadata come from different capture instants. **[Directly observed / strongly inferred]** Sources: `MPTDC/rtl/top/mptdc_core.sv:316-386`; `MPTDC/rtl/async/mptdc_context_bank.sv:11-21, 67-77`.
4. **MULTI_HIT one-cycle lag**: changes when the measurement actually stops and therefore what hits are included. **[Directly observed]** Sources: `MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv:117-144`.
5. **Hit ordering semantics**: the output stream is deterministic, but it is not obviously temporal. **[Directly observed]** Sources: `MPTDC/rtl/ctrl/mptdc_drain_ctrl.sv:101-124, 233-240`; `MPTDC/docs/02_OUTPUT_PROTOCOL.md:98-103`.

## 14. Raw Pre-Calibration Precision and Offset Analysis

### 14.1 What raw data is captured today

The maintained collector writes one stable 18-column CSV row per hit:

`conv_id, hit_idx, Tref_ps, nslow, nfast_hit, nfast_snap, ns, nf, pd_idx, event_seq, phase0_snap, slow_boundary_inc, hit_count, flags, ctx_id, t_raw_ps, mode, max_hits`

`RAW_FEATURES` mode reconstructs `t_raw_ps` in the testbench so the schema stays identical to `FULL` mode. **[Directly observed]** Sources: `MPTDC/tb/int/tb_campaign_collect.sv:269-299, 314-423`; `MPTDC/docs/05_OFFLINE_CALIBRATION_PLAN.md:252-258`.

This is a strong raw observability basis. It exposes:

- coarse counts (`nslow`, `nfast_hit`, `nfast_snap`)
- fine indices (`ns`, `nf`, `pd_idx`)
- boundary metadata (`phase0_snap`, `slow_boundary_inc`)
- packet/control context (`hit_count`, `flags`, `ctx_id`, `mode`, `max_hits`)

### 14.2 What the maintained analysis script actually computes

`analyze_campaign.py` currently computes or plots:

- `offset_ps = Tref_ps - t_raw_ps`
- aggregate mean/std/min/max/median/RMSE
- Python-vs-RTL Vernier cross-check
- DNL/INL from `t_raw_ps`
- boundary-class analysis and pairwise t-tests
- `ns x nf` mean/std heatmaps
- residual-vs-`Tref_ps` and raw linearity scatter
- residual histograms and hit-count distributions
- flag distributions

**[Directly observed]** Sources: `MPTDC/scripts/analysis/analyze_campaign.py:128-165, 172-247, 255-263, 275-359, 457-512`.

### 14.3 What is missing for a deeper raw-precision diagnosis

The repo does **not** currently ship a maintained analysis that directly reports:

- one-shot RMS **vs exact input delay**
- jitter-included RMS **vs exact input delay**
- error **vs `nslow`**
- error **vs `nfast_hit`**
- error **vs `t_raw_ps`** by region rather than only overall scatter
- outlier-tail analysis by delay region
- a dedicated code-density campaign bench
- same-delay repeated-measurement averaging curves measured in TB

The collector data is rich enough that some of these can be derived offline, but they are not currently first-class outputs. **[Directly observed]** Sources: `MPTDC/tb/int/tb_campaign_collect.sv:428-553`; `MPTDC/scripts/analysis/analyze_campaign.py:275-359, 457-512`.

### 14.4 Pre-calibration bottleneck ranking

1. **Boundary/coherency structure** (`slow_boundary_inc`, origin biases, phase-class effects). **[Directly observed]** Sources: `MPTDC/rtl/pkg/mptdc_pkg.sv:42-51, 292-299`; `MPTDC/scripts/analysis/analyze_campaign.py:202-247`.
2. **Count-dependent jitter growth** from the oscillator model. **[Strongly inferred]** Sources: `MPTDC/rtl/osc/mptdc_osc_model.sv:121-138`; `MPTDC/rtl/pkg/mptdc_pkg.sv:292-299`.
3. **Short-delay startup sensitivity**. **[Strongly inferred]** Sources: `MPTDC/rtl/osc/mptdc_osc_model.sv:22-29, 117-143`; `MPTDC/rtl/async/mptdc_async_frontend_v2.sv:169-171`.
4. **MULTI_HIT close lag and hit ordering semantics**. **[Directly observed / strongly inferred]** Sources: `MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv:117-144`; `MPTDC/rtl/ctrl/mptdc_drain_ctrl.sv:182-240`; `MPTDC/scripts/calibration/calibrate_6d_lut.py:13-14, 46-48`.

## 15. Jitter Accumulation Analysis vs Delay / Counter Value

### 15.1 Why long delays should degrade naturally

The behavioral oscillator model perturbs each half-period independently inside the oscillation loop. A longer measurement implies more slow and fast cycles, so more opportunities for jitter to accumulate into the raw phase/coarse relationship. The timestamp equation then multiplies those coarse/fine indices into the final `t_raw_ps`. **[Directly observed / strongly inferred]** Sources: `MPTDC/rtl/osc/mptdc_osc_model.sv:121-138`; `MPTDC/rtl/pkg/mptdc_pkg.sv:292-299`.

A useful mental model is:

`raw_error = boundary_bias + startup_bias + coarse_count_error + fine_phase_error + random_jitter`

where the random-jitter term grows with count. This is a **strong inference**, not a literal repo formula. **[Strongly inferred]** Sources: `MPTDC/rtl/osc/mptdc_osc_model.sv:15-18, 121-138`; `MPTDC/rtl/pkg/mptdc_pkg.sv:284-313`.

### 15.2 Why short delays are different

At the short end of the range (`20 ps` upward), the key risk is not accumulated jitter; it is whether the architecture is observing a stable phase relationship immediately after START/STOP-driven oscillator enable. The model does include deterministic startup phasing, but it is much less realistic there than for midrange steady toggling. **[Strongly inferred]** Sources: `MPTDC/rtl/osc/mptdc_osc_model.sv:22-29, 117-143`; `MPTDC/rtl/async/mptdc_async_frontend_v2.sv:169-171`.

### 15.3 Implication for the current calibration flow

`calibrate_6d_lut.py` includes `nslow`, `nfast_hit`, and `phase0_snap` in its key. That is exactly what one would expect if the dominant residual error is not a global constant but a count- and boundary-dependent structure. Calibration can remove **mean** bias per bin; it cannot remove independent random jitter within a bin. **[Directly observed / strongly inferred]** Sources: `MPTDC/scripts/calibration/calibrate_6d_lut.py:37-48, 98-110`; `MPTDC/rtl/pkg/mptdc_pkg.sv:292-299`.

## 16. Performance Behavior Across 20 ps to 30 ns

### 16.1 What is covered today

The maintained collection flow defaults to `20 ps` minimum and `30000 ps` maximum in both the testbench and the campaign runner. The configuration sweep is broad: `mode x max_hits x input source x jitter` = `24` configurations. **[Directly observed]** Sources: `MPTDC/tb/int/tb_campaign_collect.sv:433-434`; `MPTDC/scripts/sim/run_campaign.sh:9-18, 225-256`.

### 16.2 Confidence by delay region

- **`20 ps` to sub-ns:** covered by the campaign range, but not by a dedicated repeated fixed-delay bench. Confidence is weakest here because startup/boundary sensitivity dominates and the current analysis is mostly aggregate. **[Directly observed / strongly inferred]** Sources: `MPTDC/tb/int/tb_campaign_collect.sv:428-553`; `MPTDC/rtl/osc/mptdc_osc_model.sv:22-29, 117-143`.
- **~`1 ns` to `10 ns`:** best covered by directed benches and general campaigns. Many benches inject delays in this regime (`tb_single_conv`, `tb_firsthit_mode`, `tb_cal_inject`, `jitter_robustness`). **[Directly observed]** Sources: `MPTDC/tb/int/tb_single_conv.sv:113-126`; `MPTDC/tb/int/tb_firsthit_mode.sv:79-88`; `MPTDC/tb/int/tb_cal_inject.sv:103-171`; `MPTDC/tb/vip/README.md:533-546`.
- **`10 ns` to `30 ns`:** still covered in the campaign range and CAL-path sweep, but the repo does not isolate long-delay jitter growth cleanly in a maintained report. **[Directly observed]** Sources: `MPTDC/tb/int/tb_cal_inject.sv:103-171`; `MPTDC/scripts/sim/run_campaign.sh:9-18, 225-280`; `MPTDC/scripts/analysis/analyze_campaign.py:275-300`.

### 16.3 Main performance takeaway over the requested range

The repository does cover the entire requested **range** in its collection flow, but it does not cover the entire requested **confidence question**. Range coverage exists; high-confidence per-region raw precision proof does not. **[Directly observed]**
## 17. Testbench and Campaign Methodology Review

### 17.1 Common infrastructure

- `mptdc_tb_pkg.sv` provides exact packet parsing helpers and collection tasks used by directed benches and the VIP environment. **[Directly observed]** Sources: `MPTDC/tb/common/mptdc_tb_pkg.sv:29-107, 176-214`.
- `mptdc_raw_monitor.sv` is a passive packet monitor that validates header/EOC framing and hit-count-based expected word counts without driving ready. **[Directly observed]** Sources: `MPTDC/tb/common/mptdc_raw_monitor.sv:7-10, 43-115`.

### 17.2 Integration benches: what they really prove

- `tb_single_conv.sv`: one basic end-to-end RAW_FEATURES packet, header/EOC present, expected word count. **[Directly observed]** Sources: `MPTDC/tb/int/tb_single_conv.sv:7-10, 91-177`.
- `tb_multi_conv_stress.sv`: repeated arm/start/stop/readout sequence with monotonic `conv_id` checking. **[Directly observed]** Sources: `MPTDC/tb/int/tb_multi_conv_stress.sv:7-10, 98-120`.
- `tb_backpressure.sv`: packet integrity under random/full stalls, using passive collection. **[Directly observed]** Sources: `MPTDC/tb/int/tb_backpressure.sv:7-10, 41-57, 90-139, 193-229`.
- `tb_deadtime_measure.sv`: re-arm + gap sweep from `60 ns` down to `20 ns`, measuring practical passing gap including re-arm overhead. It does **not** directly prove the nominal `4-5 ns` hardware-only frontend number cited in the deadtime document. **[Directly observed]** Sources: `MPTDC/tb/int/tb_deadtime_measure.sv:84-88, 159-249`; `MPTDC/docs/06_DEADTIME_ANALYSIS.md`.
- `tb_cal_inject.sv`: CAL-input path sanity across integer-ns delays from `1 ns` to `30 ns`; good path check, not a full calibration-characterization bench. **[Directly observed]** Sources: `MPTDC/tb/int/tb_cal_inject.sv:7-10, 97-171`.
- `tb_firsthit_mode.sv`: explicitly documents that FIRST_HIT is **early close**, not guaranteed single-hit output; the PD matrix can still accumulate hits through the CAPTURE cycle. **[Directly observed]** Sources: `MPTDC/tb/int/tb_firsthit_mode.sv:68-72, 96-115`.
- `tb_overflow_count.sv`: validates the rejected-START/`OVF_COUNT` mechanism, but also explicitly accepts the case where overflow does not occur because contexts freed too quickly. **[Directly observed]** Sources: `MPTDC/tb/int/tb_overflow_count.sv:95-122`.
- `tb_start_wdt.sv` and `tb_watchdog_recovery.sv`: verify START-only watchdog-forced packet closure and clean post-watchdog recovery. **[Directly observed]** Sources: `MPTDC/tb/int/tb_start_wdt.sv:66-140`; `MPTDC/tb/int/tb_watchdog_recovery.sv:117-220`.

### 17.3 Unit benches

The unit benches are useful and appropriately scoped:

- `tb_input_mux_unit.sv`: pass-through/isolation and mode-switching behavior of the pure async mux. **[Directly observed]** Sources: `MPTDC/tb/unit/tb_input_mux_unit.sv:7-10, 86-180`.
- `tb_reset_sync_unit.sv`: async assert/sync deassert semantics and clock-stopped behavior. **[Directly observed]** Sources: `MPTDC/tb/unit/tb_reset_sync_unit.sv:7-10, 95-200`.
- `tb_watchdog_unit.sv`: global timeout, disable, reset, and trip-count saturation. **[Directly observed]** Sources: `MPTDC/tb/unit/tb_watchdog_unit.sv:7-10, 71-141`.
- `tb_context_bank_unit.sv`: snapshot integrity, independent contexts, overwrite behavior, boundary-bit retention. **[Directly observed]** Sources: `MPTDC/tb/unit/tb_context_bank_unit.sv:7-10, 71-126, 161-220`.
- `tb_narrow16_tx_v2_unit.sv`: packet formatting and timestamp-word generation across output modes. **[Directly observed]** Sources: `MPTDC/tb/unit/tb_narrow16_tx_v2_unit.sv:7-10, 65-101, 170-240`.

### 17.4 VIP methodology

The VIP is class-based, mailbox-driven, and intentionally checks **packet semantics**, not analog precision trends:

- the top harness bridges interfaces to DUT wires and uses a module BFM for reset/CSR/conversion execution
- the scoreboard validates word counts, hit counts, flags, output mode, `conv_id`, `pd_idx`, and FULL-mode timestamp consistency
- coverage is gated by `MPTDC_ENABLE_FUNC_COV`
- covergroups span mode, source, output mode, backpressure, delay bins, jitter bins, flags, boundary bit, and hit-count ranges

**[Directly observed]** Sources: `MPTDC/tb/tests/mptdc_vip_tb.sv:41-58, 98-113, 115-220`; `MPTDC/tb/vip/pkg/mptdc_vip_pkg.sv:528-645, 813-915, 956-1015`; `MPTDC/tb/vip/README.md:74-85, 101-108, 236-306, 332-546`.

This is the correct separation of concerns: VIP is for contract closure, not for RMS certification. **[Directly observed]** Sources: `MPTDC/tb/vip/pkg/mptdc_vip_pkg.sv:956-958`.

### 17.5 Runners and coverage scripts

- `run_tb.sh` is the primary filelist-driven runner for `tb/unit` and `tb/int`, always compiling the oscillator model and common TB files. **[Directly observed]** Sources: `MPTDC/scripts/sim/run_tb.sh:3-8, 66-78, 92-188`.
- `run_vip_test.sh` supports Verilator/Xrun/VCS, rejects coverage under Verilator, and isolates Xcelium worklibs per seed/test when needed. **[Directly observed]** Sources: `MPTDC/scripts/sim/run_vip_test.sh:3-10, 141-160, 176-243`.
- `run_campaign.sh` is the maintained raw-data campaign orchestrator; it supports `verilator|xrun|xcelium`, `full|raw_features`, jitter overrides, resume, and unique Xcelium work directories. **[Directly observed]** Sources: `MPTDC/scripts/sim/run_campaign.sh:3-22, 31-49, 225-280, 313-430`.
- `report_coverage.sh` explicitly merges per-`covtest` Cadence coverage buckets before IMC reporting. **[Directly observed]** Sources: `MPTDC/scripts/sim/report_coverage.sh:3-9, 88-131`.

## 18. Empirical Measurement Readiness for RMS and Averaging Targets

### 18.1 Nominal one-shot RMS `< 15 ps`

**Assessment: not directly proven by the maintained repo flow.**

What exists:

- broad campaign collection over `20 ps .. 30 ns`
- aggregate RMSE computation in `analyze_campaign.py`
- optional nominal vs jitter campaign configurations

What is missing:

- a maintained same-delay repeated-measurement methodology that directly outputs one-shot RMS as a function of delay
- a maintained report tying that curve to the full `20 ps .. 30 ns` range

**[Directly observed]** Sources: `MPTDC/tb/int/tb_campaign_collect.sv:428-553`; `MPTDC/scripts/analysis/analyze_campaign.py:152-165, 275-300`.

### 18.2 Jitter-included one-shot RMS `< 25 ps`

**Assessment: also not directly proven.**

The repo can inject oscillator jitter (`sigma=8 ps`, bound `24 ps`) both in campaign collection and in VIP jitter scenarios, but the maintained analysis flow still reports overall residual statistics rather than matched per-delay one-shot RMS curves under jitter. **[Directly observed]** Sources: `MPTDC/scripts/sim/run_campaign.sh:227-256`; `MPTDC/tb/vip/README.md:533-546`; `MPTDC/rtl/osc/mptdc_osc_model.sv:15-18, 68-75, 126-135`; `MPTDC/scripts/analysis/analyze_campaign.py:152-165`.

### 18.3 Averaged RMS for `N = 1..15`

**Assessment: current repo provides an offline resampling study, not a TB-measured same-delay averaging proof.**

`calibrate_6d_lut.py` has a clear `run_averaging_study()` function, but it draws calibrated errors from the empirical error distribution and averages them offline. That is useful for estimator exploration, but it is not the same as repeatedly measuring the **same delay point** in the TB for each `N`. **[Directly observed]** Sources: `MPTDC/scripts/calibration/calibrate_6d_lut.py:441-465, 746-909`.

Likewise, `max_hits = 15` and multi-hit packets are **not** the same as “average 15 independent conversions at the same delay.” Multi-hit within one conversion shares the same measurement window and closure logic. **[Directly observed / strongly inferred]** Sources: `MPTDC/rtl/pkg/mptdc_pkg.sv:72-79`; `MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv:137-144`; `MPTDC/tb/int/tb_campaign_collect.sv:428-553`.

## 19. Current Calibration Pipeline Review

### 19.1 Primary maintained flow

The current documented primary flow is:

1. collect campaign CSVs with `tb_campaign_collect.sv` / `run_campaign.sh`
2. load CSVs in `calibrate_6d_lut.py`
3. infer `(ns_inf, nf_inf)` from `t_raw_ps` if needed
4. build mean-correction LUT keyed by `(ns_inf, nf_inf, nslow, nfast_hit, phase0_snap, hit_idx)`
5. apply LUT and report pre/post metrics and plots

**[Directly observed]** Sources: `MPTDC/docs/05_OFFLINE_CALIBRATION_PLAN.md:190-227, 239-272`; `MPTDC/scripts/calibration/calibrate_6d_lut.py:37-48, 65-110, 497-559, 773-909`.

### 19.2 Current calibration limitations

1. **Core filtering excludes a slice of raw operating space.**

   The calibrator filters to `nslow > 0`, and the text report itself describes this as removing boundary-ambiguous hits. So the strongest published calibration metrics do not represent all raw hits equally. **[Directly observed]** Sources: `MPTDC/scripts/calibration/calibrate_6d_lut.py:77-95, 511-518, 795-800`.

2. **Calibration corrects mean structure, not random jitter.**

   The LUT stores mean correction, within-bin std, and population; it does not implement a dynamic jitter estimator. **[Directly observed]** Sources: `MPTDC/scripts/calibration/calibrate_6d_lut.py:98-110, 533-541`.

3. **`hit_idx` semantics are subtle.**

   The LUT assumes `hit_idx` is a meaningful correction dimension, but in the hardware path it is packet emission order after bitmap scan, not an explicitly time-sorted hit order. That may still be useful, but it is a calibration assumption that deserves explicit documentation. **[Directly observed / strongly inferred]** Sources: `MPTDC/scripts/calibration/calibrate_6d_lut.py:13-14, 46-48`; `MPTDC/rtl/ctrl/mptdc_drain_ctrl.sv:101-124, 233-240`; `MPTDC/tb/int/tb_campaign_collect.sv:280-299`.

4. **Maintained runner/output-mode mismatch.**

   `calibrate_6d_lut.py` is written to support all three output modes conceptually, but the maintained `run_campaign.sh` front-end currently exposes only `full|raw_features`, not `raw_timestamp`. That does not break the current flow, but it means RAW_TIMESTAMP deployability is more of a mathematical compatibility claim than a maintained campaign path today. **[Directly observed]** Sources: `MPTDC/scripts/sim/run_campaign.sh:15-18, 42-43`; `MPTDC/scripts/calibration/calibrate_6d_lut.py:786-790`; `MPTDC/docs/02_OUTPUT_PROTOCOL.md:105-156`.

### 19.3 Additional analysis-side scripts in the current tree

The current working tree also contains:

- `scripts/calibration/analyze_shortformat_models.py`, which compares exact-LUT performance, oracle floors, and hierarchical fallback models for restricted visible-key sets under jitter **[Directly observed]** Sources: `MPTDC/docs/05_OFFLINE_CALIBRATION_PLAN.md:205-227`; `MPTDC/scripts/calibration/analyze_shortformat_models.py:1-11, 64-72, 139-177, 200-260`.
- `scripts/calibration/calibrate_mvue.py`, which explores covariance-aware intra-/inter-conversion weighting and quality gating. This is analysis-side exploration, not the documented primary calibration path. **[Directly observed]** Sources: `MPTDC/scripts/calibration/calibrate_mvue.py:1-18, 107-149, 203-251`.

These are useful extensions, but they do not replace the lack of direct TB-measured fixed-delay RMS and averaging proof.

## 20. Future ASIC Periodic Recalibration Readiness

### 20.1 What is already in place

The architecture is fundamentally friendly to **off-chip periodic recalibration**:

- the top-level mux already supports switching between SPAD and CAL async inputs
- the serializer can export raw feature fields or a compact timestamp
- the CSR block can switch mode/input/output and keep `conv_arm` asserted for sustained operation
- the correction policy is already off-chip by design

**[Directly observed]** Sources: `MPTDC/rtl/ctrl/mptdc_input_mux.sv:7-22, 47-51`; `MPTDC/docs/03_CSR_MAP.md:70-80, 195-216`; `MPTDC/docs/05_OFFLINE_CALIBRATION_PLAN.md:239-272`.

### 20.2 What is **not** yet demonstrated

The repo does not yet demonstrate:

- a dedicated two-external-tap ASIC calibration protocol or scheduling policy
- coexistence rules between live SPAD traffic and periodic CAL injections
- streaming/incremental recalibration in firmware/FPGA rather than batch CSV analysis
- long-term drift tracking under realistic silicon oscillator behavior

**[Directly observed / hypothesis needing validation]** Sources: `MPTDC/tb/int/tb_cal_inject.sv:7-10, 97-171`; `MPTDC/docs/08_LAB_RUNBOOK.md:385-420`; `MPTDC/docs/09_PROJECT_STATUS.md:197-220`.

### 20.3 Readiness conclusion

The architecture is **ASIC periodic-recalibration-compatible in principle**, because it keeps the calibration policy off-chip and preserves the right observables. It is **not yet deployment-proven**, because the current repo demonstrates offline batch recalibration much more strongly than in-field periodic recalibration. **[Strongly inferred]** Sources: `MPTDC/docs/05_OFFLINE_CALIBRATION_PLAN.md:239-272`; `MPTDC/rtl/ctrl/mptdc_input_mux.sv:11-22`; `MPTDC/docs/08_LAB_RUNBOOK.md:385-420`.

## 21. Compact Output Format and Calibration Implications

### 21.1 Mode trade-offs

- **`RAW_FEATURES`**: best characterization/calibration mode; exposes `ns`, `nf`, `pd_idx`, `event_seq`, `nfast_snap` directly. **[Directly observed]** Sources: `MPTDC/docs/02_OUTPUT_PROTOCOL.md:50-103`; `MPTDC/rtl/readout/mptdc_narrow16_tx_v2.sv:123-142`.
- **`RAW_TIMESTAMP`**: compact, but hides raw phase indices and scan metadata; current 6D LUT remains mathematically compatible because `(ns,nf)` can be inferred from `t_raw_ps`, but richer future models may not be. **[Directly observed / strongly inferred]** Sources: `MPTDC/docs/02_OUTPUT_PROTOCOL.md:105-135`; `MPTDC/scripts/calibration/calibrate_6d_lut.py:65-74, 786-790`; `MPTDC/scripts/calibration/analyze_shortformat_models.py:64-70`.
- **`FULL`**: best debug-correlation mode; largest bandwidth. **[Directly observed]** Sources: `MPTDC/docs/02_OUTPUT_PROTOCOL.md:136-156`; `MPTDC/rtl/readout/mptdc_narrow16_tx_v2.sv:136-146`.

### 21.2 Current important limitation

Although the math supports RAW_TIMESTAMP, the maintained campaign runner and collector are centered on `raw_features` and `full`. So the repo is stronger on **observability-rich lab characterization** than on demonstrating a compact deployed mode end to end. **[Directly observed]** Sources: `MPTDC/scripts/sim/run_campaign.sh:15-18, 42-43`; `MPTDC/tb/int/tb_campaign_collect.sv:208-423`.

### 21.3 Range implication of the 16-bit timestamp field

For the requested `20 ps .. 30 ns` range, the `16`-bit `t_raw_ps[15:0]` field is sufficient because `30000 ps < 65535 ps`. That is fine for the requested review range, but it is a hard format limit if the design is ever asked to export substantially beyond about `65.5 ns` without additional coding. **[Directly observed / strongly inferred]** Sources: `MPTDC/docs/02_OUTPUT_PROTOCOL.md:121-123, 152-154`; `MPTDC/tb/int/tb_campaign_collect.sv:433-434`.

## 22. Synthesis / ASIC Realism Notes

### 22.1 What the current synthesis collateral proves

The repo now clearly proves that the designer has thought about synthesis intent:

- dedicated synthesis filelist
- SDC for primary/virtual clocks, async inputs, resets, and CDC max delay
- MMMC file with a live typical view and placeholders for BC/WC
- Genus entry flow and synthesis README

**[Directly observed]** Sources: `MPTDC/syn/README.md:17-29, 123-180, 233-260`; `MPTDC/syn/filelist_synth.f:1-52`; `MPTDC/syn/inputs/mptdc.sdc:14-142`; `MPTDC/syn/inputs/mptdc.mmmc:17-99`.

### 22.2 Why it is still exploratory, not signoff-complete

1. **Oscillator path is still abstracted away.**

   Synthesis excludes `mptdc_osc_model.sv` and uses `mptdc_osc_stub.sv`; virtual oscillator clocks are created on stub pins. This checks digital timing structure, but not real macro behavior. **[Directly observed]** Sources: `MPTDC/syn/filelist_synth.f:26-29`; `MPTDC/syn/inputs/mptdc.sdc:32-45`; `MPTDC/rtl/osc/mptdc_osc_stub.sv:15-17`.

2. **Only typical-corner analysis is active.**

   `mptdc.mmmc` keeps BC/WC as commented templates and sets both setup and hold to `tc_view`. **[Directly observed]** Sources: `MPTDC/syn/inputs/mptdc.mmmc:13-16, 27-35, 47-50, 81-99`.

3. **Library/physical collateral still contains placeholders.**

   `libraries.xh018.tcl` uses a dummy PDK root and blank physical cell names; `libraries.xh018-stdcells.tcl` leaves clock-cell families blank. **[Directly observed]** Sources: `MPTDC/syn/libraries/libraries.xh018.tcl:25-45, 65-78`; `MPTDC/syn/libraries/libraries.xh018-stdcells.tcl:19-27, 74-80`.

4. **The design explicitly has no scan strategy at this level.**

   `mptdc.defines` sets `HAS_SCAN = no`. For a latch-heavy async measurement macro, that is an open DFT/signoff topic, not a fatal flaw, but it is definitely not “finished.” **[Directly observed]** Sources: `MPTDC/syn/inputs/mptdc.defines:21-23`.

5. **View-selection metadata is not fully converged.**

   `mptdc.defines` names `wc_view`/`bc_view` as selected setup/hold views, but `mptdc.mmmc` only activates `tc_view`. That suggests the trial flow and eventual signoff intent are not fully reconciled yet. **[Directly observed]** Sources: `MPTDC/syn/inputs/mptdc.defines:124-128`; `MPTDC/syn/inputs/mptdc.mmmc:89-99`.

## 23. Ranked Findings by Impact

### 23.1 Highest impact on single-shot RMS

1. **Missing maintained fixed-delay repeated-measurement proof across `20 ps .. 30 ns`**. The repo can collect the data, but it does not currently ship the exact empirical proof asked for. **[Directly observed]**
2. **Oscillator realism gap between behavioral model and ASIC implementation path**. This is the biggest transfer risk from simulation precision to silicon precision. **[Directly observed]**
3. **Count-dependent jitter accumulation likely increases with delay**. The current model structure makes this very likely, but the maintained analysis does not isolate it by delay or count. **[Strongly inferred]**
4. **Boundary/coherency correction is fundamental, not optional**. The raw design already exports explicit correction hooks because raw estimator bias exists. **[Directly observed]**

### 23.2 Highest impact on linearity

1. **MULTI_HIT one-cycle close lag**. **[Directly observed]**
2. **Phase-0 boundary handling / `slow_boundary_inc` dependency**. **[Directly observed]**
3. **Scan-order-based `hit_idx` in calibration**. **[Directly observed / strongly inferred]**
4. **Potential count-dependent drift without explicit error-vs-count reporting**. **[Strongly inferred]**

### 23.3 Highest impact on robustness

1. **Only two contexts under sustained stall/full-FIFO conditions**. **[Directly observed]**
2. **START rejection is cleanly counted, but overflow tests are mechanism-oriented rather than worst-case guaranteed**. **[Directly observed]**
3. **Global/per-context watchdogs improve recovery, but they are safety nets, not precision tools**. **[Directly observed]**

## 24. Recommendations (Documented Only, No Code Changes)

1. **Separate raw-performance certification from calibration success claims.** Publish pre-cal raw metrics and post-cal metrics side by side for the same datasets, and explicitly disclose filters like `nslow > 0`. **[Recommendation]**
2. **Create a maintained fixed-delay characterization report** over `20 ps .. 30 ns` with repeated measurements per delay point, for both nominal and jittered oscillator settings. **[Recommendation]**
3. **Add count-dependent plots** (`error vs nslow`, `error vs nfast_hit`, `error vs t_raw_ps`) to make long-delay degradation mechanisms visible. **[Recommendation]**
4. **Document `hit_idx` semantics explicitly** in the calibration docs: it is packet/scan order, not necessarily time order. **[Recommendation]**
5. **For periodic ASIC recalibration, define an operating protocol**: CAL injection cadence, interaction with live SPAD traffic, required output mode, and host-side update cadence. **[Recommendation]**
6. **Carry `RAW_FEATURES` or `FULL` through serious characterization runs**, even if deployed operation later uses a compact mode. **[Recommendation]**
7. **Promote synthesis collateral from trial to signoff ownership** before any silicon-ready claim: real oscillator macro model/black box, real BC/WC/QRC setup, physical-cell names, and explicit CDC/async-latch signoff methodology. **[Recommendation]**
8. **Treat `docs/04_VERIFICATION.md` collection-bench section as stale** until it is updated to the live `tb_campaign_collect` flow. **[Recommendation]**

## 25. Open Questions / Missing Evidence / Uncertainties

1. Is `hit_idx` intentionally meant as a stable correction key even though it is scan order rather than time order? **[Open question]**
2. How closely will the eventual oscillator macro reproduce the behavioral model’s startup, jitter spectrum, and tap matching? **[Open question]**
3. How much of the raw operating space is being excluded by the `nslow > 0` filter in real campaigns across all configs, not only the nominal calibration case? **[Open question]**
4. Is `RAW_TIMESTAMP` intended to be a maintained deployed calibration mode, given that the maintained campaign runner currently does not expose it directly? **[Open question]**
5. Are the selected setup/hold analysis-view variables in `mptdc.defines` consumed anywhere downstream, or are they simply stale relative to `mptdc.mmmc`? **[Open question]**
6. What physical matching/placement strategy will be used for the oscillator taps and PD matrix in silicon? **[Open question]**
7. What DFT/test approach is intended for the async-latch/ring-oscillator macro, given `HAS_SCAN = no`? **[Open question]**

## 26. Suggested Next Validation Steps

1. Use the existing maintained campaign flow to regenerate nominal and jittered RAW_FEATURES datasets over `20 ps .. 30 ns`.
2. From those datasets, produce **per-delay** mean error, RMSE, and high-percentile absolute-error curves, not only aggregate summaries.
3. Add explicit **error vs count** views (`nslow`, `nfast_hit`) to confirm or refute the expected count-dependent jitter growth.
4. Re-run the same analysis after calibration and show which parts of the residual are removed (mean bias) and which remain (random jitter / tails).
5. For averaging targets, run a **same-delay repeated-measurement** study rather than relying only on offline resampling of the global error pool.
6. Compare Verilator and Xrun RAW_FEATURES outputs on matched smoke campaigns to confirm simulator-consistent raw features before trusting cross-simulator calibration reuse. Sources: `MPTDC/docs/04_VERIFICATION.md:548-574`.
7. Close the documentation gap by aligning the verification guide with the maintained collector and runner paths.
8. Before any silicon-ready statement, replace the oscillator stub assumption with a real macro ownership plan and run the existing Genus flow with real library/QRC content and explicit CDC/async-latch review.

---

### Final review conclusion

The MPTDC repository contains a **real and technically coherent Vernier TDC architecture**, not a toy prototype. Its strongest qualities are architectural partitioning, raw observability, explicit boundary metadata, and a maintained verification/campaign/calibration workflow. Its weakest point, relative to the user’s priority order, is **not raw functionality** but **raw empirical precision proof** across the full `20 ps .. 30 ns` range under realistic ring-oscillator uncertainty.

That leads to the most accurate overall call:

- **Architecture and RTL correctness:** credible and thoughtfully structured
- **Raw precision confidence before calibration:** partially supported, not fully closed
- **Calibration pipeline:** strong and well instrumented, but downstream of raw limitations
- **Future ASIC periodic recalibration:** architecturally plausible, operationally under-specified
- **ASIC realism/signoff readiness:** clearly not there yet

No code changes were made as part of this review.

---

## Addendum — v2.3 Enhancement Results

*Added after implementation of the precision enhancement plan.*

### What was implemented

1. **Sub-header packet word (RTL v2.3):** Added a sub-header word
   (`[15:13]=3'b101`) after the header carrying `nfast_stop[12:6]`.
   In the current architecture the fast oscillator starts at STOP time,
   so `nfast_stop` is always 0 — the field is reserved for future use.
   All 13 Verilator testbenches pass with the v2.3 packet format.

2. **Fine phase grid analysis:** The Vernier grid `ns×11 − nf×10` has
   81 achievable values out of 169 (47.9% coverage), with worst gaps
   of 100 ps at diagonal boundaries.  Worst DNL = +3.76 LSB,
   worst INL = ±9.05 LSB.

3. **Enhanced calibration scripts:** 8-method comparison including
   LUT variants, polynomial regression, GradientBoosted regression,
   temporal re-keying, and quality-gated multi-hit averaging.

### Key calibration results

| Condition | Method | Single-Shot RMSE | 15-Hit Averaged RMSE |
|-----------|--------|-----------------|---------------------|
| Nominal | 6D LUT (mean) | 18.99 ps | 5.29 ps (trimmed) |
| Nominal | GBR | **18.56 ps** | **5.19 ps** (weighted) |
| Jitter σ=6 ps | 6D LUT (mean) | 53.64 ps | 19.75 ps (trimmed) |
| Jitter σ=6 ps | GBR | **48.24 ps** | — |

### Review recommendations — status update

| Original recommendation | Status |
|------------------------|--------|
| Empirical per-delay RMS proof | Partially addressed: maintained calibration scripts now report per-method RMSE; fixed-delay repeated-measurement TB still needed |
| Enhanced calibration beyond LUT | **Done**: GBR, polynomial, temporal re-key, quality-gated averaging implemented |
| Multi-hit averaging study | **Done**: trimmed/weighted/uniform comparison shows 5.19 ps at 15 hits (nominal) |
| Fine-grid gap characterization | **Done**: analyze_fine_grid.py with PDF output |
| `hit_idx` semantics documentation | **Done**: calibration scripts document scan-order vs temporal-order distinction |
| nfast_stop observable | **Investigated and resolved**: fast osc starts at STOP → field is always 0; kept as reserved |
| Same-delay repeated-measurement TB | Still needed for silicon-grade proof |
| ASIC synthesis realism | Still at flow-ready, not signoff-complete |
