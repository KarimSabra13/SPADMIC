# MPTDC v2.2 — Design Review 1.0

> - **Author:** Karim Sabra
> - **Purpose:** Capture a formal review snapshot of the active MPTDC v2.2 repository before the next phase.
> - **Scope:** Evaluates the checked-out RTL, documentation, benches, and rerun evidence at this checkpoint; it is not a frozen release audit.

## Scope

This review covers the current checked-out repository state in `/home/karim/SPADMIC/MPTDC`.

Note: the worktree was already dirty at the time of review, so this document evaluates the **present RTL/docs/testbench state as checked out**, not a clean tagged release.

## Revalidation note

This document is an important review snapshot, but parts of it were later rechecked
against the live repository and should be read with the following corrections in mind:

- the active top path still bypasses `mptdc_tconv_reco.sv`; `t_raw_ps` is computed inline in `mptdc_narrow16_tx_v2.sv`
- `mptdc_pulse_sync.sv` remains compiled collateral, not an instantiated live-top block
- `hit_idx` and `event_seq` are drain scan-order semantics, not chronological time order
- the repository now contains trial synthesis collateral under `syn/` (`filelist_synth.f`, `inputs/mptdc.sdc`, `scripts/genus.tcl`)
- the strongest remaining measurement-evidence gap was empirical fixed-delay RMS proof; the maintained flow for that is now `scripts/sim/run_fixed_delay_campaign.sh` plus `scripts/analysis/analyze_fixed_delay_campaign.py`

## Review method

The review was done by:

- reading the active documentation in `README.md` and `docs/`
- reading the active compile list in `rtl/filelist.f`
- reading the active RTL under `rtl/pkg`, `rtl/cdc`, `rtl/osc`, `rtl/pd`, `rtl/async`, `rtl/ctrl`, `rtl/readout`, and `rtl/top`
- reading the main integration/unit benches under `tb/`
- rerunning the active regression and unit benches
- analyzing the existing collection outputs in `results/first_hit.csv` and `results/multi_hit.csv`

Commands rerun during this review:

```bash
bash ci/run_full_regression.sh

for tb in \
  tb_input_mux_unit \
  tb_reset_sync_unit \
  tb_watchdog_unit \
  tb_context_bank_unit \
  tb_narrow16_tx_v2_unit
do
  bash scripts/sim/run_tb.sh "$tb"
done
```

Observed baseline during this review:

- lint passed
- integration regression passed `9/9`
- unit benches passed `5/5`

## Executive verdict

### Bottom line

- **Functional RTL checkpoint:** strong and coherent
- **Offline calibration readiness:** **GO**
- **Exploratory front-end synthesis readiness:** **conditional GO with the checked-in trial Genus flow, but still blocked on oscillator-macro ownership and signoff-quality constraints**
- **Standard-cell synthesis / STA / CDC signoff readiness:** **NO-GO**
- **Silicon-ready verdict today:** **not yet silicon-ready**

### What I am confident about

The design is no longer at the "toy RTL" stage. The architecture is coherent, the block partitioning is reasonable, the double-buffer flow is sound, the shutdown sequence is much safer than earlier Vernier-style quick hacks, and the readout/export path is good enough to support real offline calibration work.

### What prevents a silicon-ready call today

The remaining blockers are **not mainly logical RTL collapse**. They are mostly **implementation-signoff blockers**:

- no real oscillator implementation in the live synthesis path
- trial generated-clock / async constraint collateral exists, but it is not yet signoff-complete
- multiple intentional async capture structures that need custom signoff treatment
- no visible DFT/test strategy for a ring-oscillator + async-latch architecture

So the correct checkpoint message is:

> **Yes, the TDC architecture looks functionally real enough to proceed into offline calibration preparation. No, the repository is not yet in a state where I would call it silicon-ready or synthesis-signoff-ready as-is.**

## Architecture deep dive

## End-to-end datapath

The active conversion path is:

```text
async START/STOP
  -> mptdc_input_mux
  -> mptdc_async_frontend_v2
  -> slow oscillator start on START
  -> fast oscillator start + PD enable on STOP
  -> PD matrix + slow/fast coarse counters + STOP-side boundary capture
  -> mptdc_meas_ctrl closes measurement
  -> mptdc_context_bank freezes one context
  -> mptdc_drain_ctrl scans frozen hits in clk_sys
  -> mptdc_sync_fifo
  -> mptdc_narrow16_tx_v2
  -> 16-bit output packet stream
```

This is the correct overall architectural split for an offline-calibrated Vernier TDC:

- the **measurement path** stays in the async/generated-clock side
- the **packetization/output path** stays in `clk_sys`
- the **double-buffer context bank** decouples frontend re-arm from serializer drain

That is a good choice.

## Block-by-block RTL review

| Module | Role | Interaction with surrounding blocks | Review |
|---|---|---|---|
| `rtl/pkg/mptdc_pkg.sv` | Source of truth for widths, enums, packet structs, raw timestamp helper | Used by every block; defines the live timestamp contract | Good centralization. The package clearly captures the current live contract. |
| `rtl/top/mptdc_top_asic.sv` | Pad-facing wrapper | Connects reset sync, input mux, CSR, and core | Clean wrapper. Correctly keeps measurement complexity below top. |
| `rtl/ctrl/mptdc_input_mux.sv` | Async source select between SPAD and CAL | Feeds async frontend | Architecturally correct as a pure async mux, but it relies on `input_sel` staying stable during conversion. |
| `rtl/readout/mptdc_csr_minimal.sv` | Quasi-static config + live status | Programs mode, max hits, watchdogs, arm, reset, FIFO clear | Minimal but adequate for this checkpoint. Good persistent `conv_arm`. |
| `rtl/top/mptdc_core.sv` | Full integration point | Wires frontend, oscillators, counters, PD array, drain, FIFO, TX, watchdog | This is the design center. Overall integration is coherent. Most silicon-signoff risk also lives here. |
| `rtl/cdc/mptdc_reset_sync.sv` | Async-assert / sync-deassert reset sync | Used at sys level and fast-domain reset | Standard and solid. |
| `rtl/cdc/mptdc_pulse_sync.sv` | Generic pulse synchronizer | Compiled but not used in live top | No current functional role in the active path. |
| `rtl/cdc/mptdc_gray_cnt_sync.sv` | Source counter + Gray CDC + snapshot export | Slow counter crosses into fast domain; fast counter reused same-domain; snapshot feeds context bank | Thoughtful structure. The async snapshot path is central to correctness, but it is also a signoff hotspot. |
| `rtl/cdc/mptdc_sync_fifo.sv` | Sys-domain FWFT FIFO | Buffers drain records before TX | Simple and appropriate. |
| `rtl/osc/mptdc_osc_wrapper.sv` | Selects model vs stub | Used by both slow and fast oscillator instances | Wrapper itself is fine. Real blocker is what sits behind it in synthesis. |
| `rtl/osc/mptdc_osc_model.sv` | Behavioral timing model | Drives realistic phase timing in simulation | Good for RTL validation. Not a silicon model. |
| `rtl/osc/mptdc_osc_stub.sv` | Static synthesis placeholder | Gives deterministic outputs when model is disabled | Useful only as a placeholder. It is not a signoff-ready implementation path. |
| `rtl/pd/mptdc_pd_cell.sv` | One phase detector cell | Samples one slow tap on one fast tap, latches hit + `nfast` | Correct intentional async sampler style. Needs special STA/CDC treatment in silicon. |
| `rtl/async/mptdc_async_frontend_v2.sv` | START/STOP latch ownership + context allocation | Drives oscillator enables, PD enable, active context, drain flags | Architecturally correct for this class of TDC. Heavy async/latch use is intentional but must be treated as such in implementation. |
| `rtl/async/mptdc_stop_capture_async.sv` | STOP-edge boundary capture | Captures `phase0_snap`, debug probe, and `slow_boundary_inc` | Valuable for calibration, but again a non-standard async capture structure. |
| `rtl/async/mptdc_context_bank.sv` | Double-buffered frozen snapshots | Captured in fast domain, read in sys domain after drain flag sync | Good architectural choice. Read-side bus CDC relies on a static-data assumption that must be explicitly signed off. |
| `rtl/ctrl/mptdc_meas_ctrl.sv` | Fast-domain measurement FSM | Sees PD bitmap, closes measurement, sequences capture/stop/clear | One of the strongest blocks in the repo. The `CAPTURE -> STOP_OSC -> CLEAR` sequence is the right idea. |
| `rtl/ctrl/mptdc_drain_ctrl.sv` | Sys-domain frozen-context scanner | Converts context snapshot to META/HIT records, releases contexts | Clean split from the frontend. `released_mask` is a good detail. |
| `rtl/ctrl/mptdc_watchdog.sv` | Global inactivity watchdog | Forces emergency reset if no conversion completes | Simple and acceptable as a safety net. |
| `rtl/readout/mptdc_narrow16_tx_v2.sv` | 16-bit serializer | Converts FIFO records into RAW_FEATURES / RAW_TIMESTAMP / FULL packets | Packet formatting is coherent and consistent with the package helpers. |
| `rtl/readout/mptdc_tconv_reco.sv` | Standalone raw timestamp helper | Compiled but not used in active top | Fine as reference collateral, not part of active silicon path. |

## What the architecture gets right

### 1. Shutdown ordering is much safer than older Vernier-style RTL

The key sequence in `mptdc_meas_ctrl.sv` is:

```text
IDLE -> MEASURE -> CAPTURE -> STOP_OSC -> CLEAR -> IDLE
```

This is the right idea.

Why it matters:

- `CAPTURE` freezes the data before teardown
- `STOP_OSC` drops frontend ownership before destructive clear
- `CLEAR` is delayed until after oscillator shutdown intent is established

This is a real silicon-minded improvement, not just an RTL cleanup.

### 2. Double-buffering is used in the right place

`mptdc_context_bank.sv` plus `mptdc_drain_ctrl.sv` correctly decouple:

- **frontend re-arm**
- **packet drain**
- **16-bit serialization**

That means output bandwidth is no longer directly sitting on the immediate deadtime path.

### 3. Offline calibration observability is strong

The design exports the right primitive features:

- `Nslow`
- `Nfast_hit`
- `Nfast_snap`
- `ns`
- `nf`
- `event_seq`
- `phase0_snap`
- `slow_boundary_inc`

For an offline-calibrated TDC, this is exactly what I want to see.

### 4. The MULTI_HIT close path shows timing awareness

`mptdc_meas_ctrl.sv` does not try to close MULTI_HIT with a giant unpipelined 81-bit popcount in the fast domain. The hit-count tree is pipelined and saturating, which is the right direction for a near-GHz measurement domain.

## Timing, clocking, CDC, and reset assessment

## Clocking structure

The live design contains four different timing classes:

1. `clk_sys` (`160 MHz`) for CSR, drain, FIFO, serializer, and global watchdog
2. `osc_fast_ph0` for the fast measurement FSM and fast coarse count
3. `fast_phase[*]` tap clocks for the PD array
4. async event timing from START/STOP and latch/control boundaries

This is **not** a normal single-clock RTL block. It must be implemented and reviewed like a mixed async/generated-clock measurement macro with synchronous readout around it.

## Deadtime path

Architecturally, the deadtime path is reasonable:

- close detect
- capture
- stop oscillators / clear frontend ownership
- async clear
- re-arm

The docs estimate practical frontend deadtime around `4-5 ns`, which is credible from the state sequence.

However:

- the current regression **does not directly prove** the best-case `4-5 ns` number
- `tb/int/tb_deadtime_measure.sv` only sweeps requested gaps from `20 ns` down to `60 ns`
- the bench re-arms via CSR writes, so it includes software/control overhead rather than purely hardware minimum deadtime

So the architecture supports a short deadtime, but the repo still needs a **persistent-arm / best-case hardware deadtime proof bench** before I would market that number as signed-off.

## CDC and async structure review

### The good

- reset synchronizers are conventional and clean
- Gray-coded counter transport is the correct strategy for coarse-count transfer
- the context drain flag uses a 2-FF sync before system-domain drain
- the context-bank read bus is only consumed after the corresponding frozen context is expected to be static

### The risky / non-standard

These are intentional, but they are **not** ordinary STA/CDC cases:

- `mptdc_async_frontend_v2.sv` uses latch-based async ownership/control
- `mptdc_stop_capture_async.sv` uses `STOP` as an async capture edge
- `mptdc_gray_cnt_sync.sv` uses async snapshot capture for the slow Gray counter
- `mptdc_pd_cell.sv` uses phase taps as local clocks
- PD clear and counter clear are released relative to oscillator phases, not to a single global synchronous clock

This is the main reason I cannot call the design silicon-ready today.

## Verification evidence from this review

## Rerun results

### Active regression

`bash ci/run_full_regression.sh`

Observed result during this review:

- lint passed
- `tb_single_conv` passed
- `tb_multi_conv_stress` passed
- `tb_deadtime_measure` passed
- `tb_cal_inject` passed
- `tb_backpressure` passed
- `tb_watchdog_recovery` passed
- `tb_start_wdt` passed
- `tb_overflow_count` passed
- `tb_firsthit_mode` passed

### Unit benches rerun

All rerun unit benches passed:

- `tb_input_mux_unit`
- `tb_reset_sync_unit`
- `tb_watchdog_unit`
- `tb_context_bank_unit`
- `tb_narrow16_tx_v2_unit`

## Collection-result evidence

Existing result files analyzed:

- `results/first_hit.csv`
- `results/multi_hit.csv`

### `first_hit.csv`

- conversions observed: `1000`
- total exported hits: `6661`
- hits per conversion: `1` to `15`
- mean hits per conversion: `6.66`
- zero-hit conversions observed in the CSV set: `0`
- raw offset stats (`Tref_ps - Tconv_ps`):
  - mean: `-19.69 ps`
  - median: `-164 ps`
  - stdev: `498.05 ps`
  - min/max: `-1570 ps / +1119 ps`

Hit-count distribution from the reviewed CSV:

- exactly `1` hit: `139` conversions
- exactly `15` hits: `18` conversions

This is extremely important:

> **FIRST_HIT currently behaves like early-close mode, not strict one-hit-only mode.**

That is not necessarily a design bug, but it must be treated as the actual contract.

### `multi_hit.csv`

- conversions observed: `1000`
- total exported hits: `15000`
- hits per conversion: always `15`
- raw offset stats (`Tref_ps - Tconv_ps`):
  - mean: `+13.53 ps`
  - median: `-108.5 ps`
  - stdev: `485.77 ps`
  - min/max: `-1909 ps / +1119 ps`

### Boundary-class behavior

The existing CSVs clearly show boundary-class structure:

- `phase0_snap=0, slow_boundary_inc=0` and `phase0_snap=1, slow_boundary_inc=0` do **not** share the same average raw offset
- the means differ by a few hundred picoseconds depending on class

Interpretation:

- the raw observables are coherent enough for fitting
- the raw timestamp is **not** something I would deploy uncalibrated
- the exported boundary metadata is doing useful work and justifies the offline-calibration direction

## Severity-ranked findings

Severity legend used in this document:

- **CRITICAL** = blocker for synthesis/signoff or major contract mismatch
- **HIGH** = serious robustness/implementation concern; should be addressed before calling the block industry-grade
- **MID** = meaningful risk/gap, but not an immediate blocker to offline-calibration work
- **LOW** = cleanup, contract clarification, or review-quality issue

### [CRITICAL] No real oscillator implementation exists in the active synthesis path

Evidence:

- `README.md` explicitly says the active synthesis path uses `mptdc_osc_stub`
- `rtl/osc/mptdc_osc_stub.sv` is a static placeholder, not a measurement oscillator
- `rtl/osc/mptdc_osc_wrapper.sv` selects that stub when the behavioral model is not compiled

Why this matters:

- the checked-in top is fine for RTL compile structure
- it is **not** a meaningful silicon measurement implementation
- generated-clock timing, startup, phase ordering, and reset behavior are still abstract at the physical boundary

My judgment:

This alone is enough to block a silicon-ready or synthesis-signoff-ready verdict.

Recommended enhancement:

- replace the stub with the intended oscillator macro/custom implementation, or black-box the oscillator outputs explicitly for front-end synthesis
- define the physical ownership of `fast_phase[*]`, `slow_phase[*]`, and `osc_fast_ph0`

### [CRITICAL] The checked-in constraint package is only trial-grade, not a signoff-complete implementation package

Evidence:

- `syn/inputs/mptdc.sdc` now exists and defines virtual oscillator clocks on the stub phase pins
- `syn/filelist_synth.f` and `syn/scripts/genus.tcl` provide a real exploratory synthesis entrypoint
- the flow is still limited to the stubbed oscillator path and a non-signoff constraint scope

Why this matters:

This design needs explicit treatment for:

- `slow_phase[*]`
- `fast_phase[*]`
- `osc_fast_ph0`
- async STOP-edge capture
- static-data context-bank crossing
- latch-based async frontend intent

Without that, any synthesis/STA/CDC result is incomplete at best and misleading at worst.

Recommended enhancement:

- extend the trial collateral into a signoff-oriented package: full MMMC views, async exceptions, static-data CDC signoff notes, and explicit methodology waivers where appropriate

### [HIGH] The design intentionally uses custom async measurement structures that standard digital flow will not sign off automatically

Evidence:

- `rtl/async/mptdc_async_frontend_v2.sv`
- `rtl/async/mptdc_stop_capture_async.sv`
- `rtl/cdc/mptdc_gray_cnt_sync.sv` async snapshot path
- `rtl/pd/mptdc_pd_cell.sv`

Why this matters:

These blocks are **not bad RTL**. They are the nature of the architecture. But they require:

- dedicated CDC review
- recovery/removal review
- generated-clock review
- likely custom DFT strategy
- explicit implementation intent communicated to synthesis/STA tools

Recommended enhancement:

- write a short implementation-methodology note for PD cells, STOP capture, frontend latches, and static-data CDC assumptions
- do not send this into a generic “just synthesize it” flow without that note

### [HIGH] `FIRST_HIT` must be treated as early-close mode, not as guaranteed one-hit mode

Evidence:

- `tb/int/tb_firsthit_mode.sv` already comments that extra hits can still accumulate
- reviewed `results/first_hit.csv` shows only `139/1000` conversions with exactly one hit
- the same reviewed CSV shows a mean of `6.66` hits per conversion and up to `15` hits in FIRST_HIT mode

Why this matters:

If downstream firmware, calibration tooling, or documentation assumes “FIRST_HIT == exactly one hit”, it will be wrong.

My judgment:

This is not a reason to stop calibration work. It **is** a contract issue that should be made explicit before handoff.

Recommended enhancement:

- document FIRST_HIT as “close-on-first-detection, possibly multiple exported hits”
- if a strict single-hit mode is required later, it will need additional hard gating or post-close hit suppression

### [HIGH] No visible DFT / test-mode strategy exists yet for an async-latch + ring-oscillator architecture

Evidence:

- no scan/test collateral was found in the repo
- architecture contains oscillator-generated clocks, async capture, and latch-based control

Why this matters:

A normal scan insertion flow will not automatically handle this architecture cleanly. Even if the functional RTL is correct, silicon-readiness for an ASIC requires an explicit test strategy.

Recommended enhancement:

- define scan boundaries, oscillator test mode, async-latch controllability/observability strategy, and safe disable/isolation behavior

### [HIGH] Async clear/release around the PD path is architecturally mitigated but not yet formally proven

Evidence:

- `rtl/ctrl/mptdc_meas_ctrl.sv` intentionally sequences `CAPTURE -> STOP_OSC -> CLEAR`
- `rtl/pd/mptdc_pd_cell.sv` still uses asynchronous clear on flops clocked by `fast_phase[*]`
- `rtl/cdc/mptdc_gray_cnt_sync.sv` also uses async clear around oscillator-driven state

Why this matters:

The architecture reduces the risk by stopping the slow-side activity before destructive clear, and by keeping the PD gate low outside MEASURE. That is good. But the **fast** oscillator side is still a real timed structure, so recovery/removal behavior and “clear while local phase clocks are alive” still need explicit signoff proof.

Recommended enhancement:

- run a formal or timed review specifically on STOP_OSC/CLEAR behavior
- document why the next conversion cannot be contaminated by a clear/deassert coincidence on `fast_phase[*]`
- include this case explicitly in implementation-stage signoff

### [MID] The marketed `4-5 ns` deadtime is architecturally plausible but not yet bench-proven in the best-case operating mode

Evidence:

- `docs/06_DEADTIME_ANALYSIS.md` argues for `4-5 ns` nominal frontend deadtime
- `tb/int/tb_deadtime_measure.sv` only sweeps requested gaps from `20 ns` upward and includes CSR re-arm overhead

Why this matters:

The architecture likely can be fast, but the regression does not yet prove the “headline” best-case deadtime under persistent `conv_arm` and aggressive back-to-back operation.

Recommended enhancement:

- add a dedicated persistent-arm bench that holds `conv_arm=1`
- sweep START-to-START gaps below `10 ns`
- separate frontend deadtime from software/CSR re-arm latency

### [MID] Overflow-count observability is weaker than the rest of the design

Evidence:

- `rtl/top/mptdc_core.sv` synchronizes `fe_start_rejected` into `clk_sys` using a simple two-flop edge detector
- `tb/int/tb_overflow_count.sv` explicitly allows the test to “pass” even if `ovf_count` does not increment

Why this matters:

`fe_start_rejected` is an async pulse-like signal. If it is narrower than one `clk_sys` cycle, it can be missed. This does not invalidate the TDC datapath, but it weakens one important diagnostic/status observable.

Recommended enhancement:

- convert rejected-start accounting to a more robust event-transfer method if overflow statistics matter in silicon
- at minimum, harden the bench so it proves the mechanism deterministically

### [MID] Several custom blocks are only validated by integration, not isolated stress/unit benches

Examples:

- `mptdc_meas_ctrl`
- `mptdc_drain_ctrl`
- `mptdc_gray_cnt_sync`
- `mptdc_pd_cell`
- `mptdc_stop_capture_async`
- `mptdc_async_frontend_v2`
- `mptdc_sync_fifo`
- `mptdc_csr_minimal`

Why this matters:

The integration story is good, but for industry-grade closure I would still want isolated edge-case benches around the custom primitives and control hotspots.

Recommended enhancement:

- add focused benches around Gray snapshot correctness, PD-cell hit latching, meas-FSM sequencing, drain-FSM ordering, and rejected-start accounting

### [MID] The offline-calibration flow is strong, but the silicon-characterization telemetry plan is still thin

Evidence:

- `docs/05_OFFLINE_CALIBRATION_PLAN.md` correctly describes raw-feature collection and PVT characterization
- the current repo does not show a clear die-ID / wafer-location / on-chip telemetry export strategy tied to the collection path

Why this matters:

For one-die bring-up this is not a blocker. For a serious silicon campaign, calibration quality improves a lot when raw data can be grouped by die, temperature, and supply context without manual bookkeeping.

Recommended enhancement:

- define how temperature, supply, die identity, and lab setup metadata will be captured alongside the exported raw features
- if needed, reserve CSR/status hooks or the host-side schema now so the silicon campaign is easier later

### [MID] Control-plane assumptions are enforced by usage convention, not by hard interlocks

Examples:

- `input_sel`
- mode changes
- `conv_arm`

Why this matters:

The architecture assumes control fields remain quasi-static during conversion. That is reasonable, but the protection is mostly procedural rather than enforced in hardware.

Recommended enhancement:

- document the software contract very clearly
- if firmware misuse is a real risk, consider latching mode/input selection per conversion in a future revision

### [LOW] Review collateral still contains stale wording and softened checks

Examples observed during review:

- `tb/int/tb_deadtime_measure.sv` still mentions “triple-buffer” and an old assertion note
- some comments in benches still reference earlier semantics/units
- `tb/int/tb_overflow_count.sv` is closer to a smoke test than a proof test

Why this matters:

This does not break the RTL, but it lowers checkpoint clarity and can confuse future reviews.

Recommended enhancement:

- clean up stale comments and make non-deterministic benches either deterministic or explicitly informational

### [LOW] Minor code-quality observations

Examples:

- `active_ctx_q` in `mptdc_async_frontend_v2.sv` updates on START even when `conv_arm_i` is low; this looks low-impact but not perfectly tight
- `phase7d_snap` exists mainly as a diagnostic helper and is not part of the live exported datapath

These are not current blockers.

## Readiness decisions

## 1. Can you move to offline calibration now?

### Yes — GO

Reason:

- the raw feature set is rich enough
- the packet path is functioning
- the architecture clearly exports the calibration-relevant observables
- existing CSVs already show meaningful boundary-class structure
- regression evidence says the end-to-end pipe is alive and stable enough for offline model building

Important caveat:

- treat `t_raw_ps` as a debug/baseline observable
- keep the primitive fields and fit offline from those fields
- treat FIRST_HIT as early-close, not strict one-hit

## 2. Can you move to synthesis now?

### Not as a signoff-quality step — NO

If “synthesis” means **real ASIC implementation handoff**, my answer is **no**.

If “synthesis” means **early front-end exploration only**, then my answer is:

### Conditional yes, but only after these prerequisites

1. replace or black-box the oscillator path properly
2. author generated-clock and async exception constraints
3. define the CDC/signoff methodology for the intentional async blocks
4. define at least the outline of the DFT/test strategy

Without those steps, a synthesis run would not answer the real silicon question.

## 3. Does the TDC “actually work” at this checkpoint?

### My answer: yes at the RTL-architecture level, but not yet proven at the silicon-implementation level

More precisely:

- **Yes**: the active RTL behaves like a real TDC architecture in simulation with the behavioral oscillator model
- **Yes**: the measurement, snapshot, drain, and packet path are coherent
- **Yes**: the design is already useful for offline calibration work
- **No**: the repo alone does not yet prove that the async/generated-clock implementation is ready for standard ASIC signoff

## Recommended next steps before calling this industry-grade

1. **Freeze the contract**
   - explicitly document FIRST_HIT semantics
   - explicitly document allowed control-plane behavior during conversion

2. **Create implementation collateral**
   - generated clocks
   - async/CDC exceptions
   - static-data CDC signoff note
   - oscillator integration note

3. **Replace the oscillator placeholder path**
   - real macro, black box, or implementation wrapper with clear signoff ownership

4. **Strengthen verification exactly where the architecture is special**
   - Gray snapshot bench
   - PD-cell bench
   - meas-FSM bench
   - persistent-arm deadtime bench
   - deterministic overflow-event accounting bench
   - jitter/PVT sensitivity experiments on the oscillator model

5. **Tighten the silicon-characterization plan**
   - define die / temperature / supply telemetry handling
   - make sure the host-side data schema can carry that metadata cleanly

6. **Define DFT/test strategy**
   - especially for oscillators, latch-based control, and async capture

## Final review statement

This is a **serious RTL checkpoint**, not a dead-end prototype.

My recommended program decision is:

- **Proceed into offline calibration preparation now**
- **Do not declare silicon readiness yet**
- **Do not rely on a plain synthesis pass as proof**
- **Treat oscillator integration + CDC/STA methodology as the next true gate**

If I had to summarize in one sentence:

> The current MPTDC RTL is functionally credible and calibration-ready, but the remaining risk is concentrated in implementation/signoff methodology, not in the high-level architecture.
