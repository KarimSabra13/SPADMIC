# MPTDC Timing Closure History

Author: Karim Sabra

This document preserves the useful lessons from the historical timing closure
iterations.  It is the user-facing timing history.  Detailed old experiment
documents live under `docs/timing_history/archive/`.

Current active flow location:

- Genus: `MPTDC/syn/scripts/server_run_genus_mptdc_typical.sh`
- Innovus: `MPTDC/pnr/scripts/server_run_innovus_mptdc_feasibility.sh`
- Stable synthesis constraints: `MPTDC/syn/inputs/mptdc_*.sdc`
- Stable PnR constraints: `MPTDC/pnr/constraints/mptdc_*.sdc`
- Generated outputs: `work/`

## O1 / O1C: RO_tune4 Macro Binding

- Problem: the digital flow needed to stop synthesizing against an oscillator
  stub and bind to the real `RO_tune4` abstract.
- Implemented change: added real abstract LEF/Liberty handoff paths and checks
  for two `RO_tune4` instances.
- Result: synthesis could distinguish real macro binding from stale stub-based
  output.
- Current status: active lesson.  The final active flow still requires
  `RO_tune4` macro abstracts and validates binding before timing work.
- Final flow location: `MPTDC/syn/macros/`, `MPTDC/analog_handoff/`, stable
  Genus wrapper.

## O2 / O3: Counter Removal And Local Epochs

- Problem: the global fast counter structure was not the right timing shape for
  the oscillator/PD fabric.
- Implemented change: removed the global fast counter, introduced local fast
  `raw_lfsr_tag`, and kept a slow Johnson epoch.
- Result: packet-visible timing context remained available without a global
  high-speed counter.
- Current status: active architecture.
- Final flow location: `MPTDC/rtl/pd/mptdc_fast_epoch_tag.sv`,
  `MPTDC/rtl/pd/mptdc_slow_epoch_johnson.sv`, fixed packet readout.

## O4 / O5: Muxless Tags And Rejected Clock-Gating Direction

- Problem: tag and PD timing needed simplification without hiding real local
  fast-domain paths.
- Implemented change: kept muxless tag direction and explored clock-gating or
  gating-like options.
- Result: direct clock-gating was not accepted as the closure direction because
  it risked changing measurement semantics and did not provide a clean signoff
  path.
- Current status: muxless tag direction active; clock-gating experiment
  rejected for the active flow.
- Final flow location: current RTL plus stable typical constraints.

## O7 / O8: Typical Screenshot-Based Clock Model

- Problem: the flow needed a single typical timing model before analog data and
  full MMMC signoff existed.
- Implemented change: added a screenshot-derived typical oscillator timing view.
- Result: created a practical feasibility path, but still not MMMC and not
  final signoff.
- Current status: historical stepping stone.
- Final flow location: stable typical SDC aliases and active R750_delta5 mode.

## O9: R750_delta5 Mode

- Problem: the previous timing constants did not match the desired Vernier
  delta target.
- Implemented change: added R750_delta5 timing constants with 79 ps slow taps,
  74 ps fast taps, 5 ps Vernier delta, and 10 ps delta LSB.
- Result: Genus reached a near-clean typical state, with small residual
  fast-tag-to-PD timing and DRV work remaining.  Characterization manifests
  proved the campaign shape, but detailed metrics were not fully committed.
- Current status: active frequency mode, not final signoff.
- Final flow location: stable wrappers set `MPTDC_FREQ_MODE=r750_delta5` by
  default where relevant.

## O10 / O11: Innovus Feasibility And RO Load Problem

- Problem: initial routed feasibility exposed excessive direct RO output load.
- Implemented change: added Innovus repair/report wrappers, then source-pin
  load analysis against analog budgets.
- Result: the load problem was real.  Reported RO loads such as fast tap loads
  around 0.57 pF to 0.72 pF were many times above the 58.72 fF strict budget
  and 75.59 fF CN-style estimate.  Existing CSVs with `NO_NET_MATCH` were not
  accepted as evidence.
- Current status: active lesson.  RO raw-load protection remains required.
- Final flow location: stable Innovus feasibility wrapper and evidence index.

## O12: Phase Isolation

- Problem: direct RO-to-digital phase fabric loading was physically too heavy.
- Implemented change: inserted a matched phase-isolation buffer bank so each
  `RO_tune4/S[n]` directly drives one local buffer input.
- Result: the phase fabric moved toward a physically meaningful topology while
  keeping PD matrix, fast tags, slow epoch, packet format, and calibration
  semantics unchanged.
- Current status: active lesson.
- Final flow location: `MPTDC/rtl/osc/mptdc_phase_buffer_bank.sv` and stable PnR
  phase-distribution constraints.

## O13: Phase Distribution, Clock/CDC, And PD Vernier Repair

- Problem: the phase-distribution topology needed a stable clock model and a
  narrow exception for the intentional PD Vernier sampler.
- Implemented change: used `BUHDX4 -> BUHDX12` phase distribution, created raw
  and buffered phase clock models, repaired clock/CDC grouping, classified PD
  paths, and count-checked the intentional slow-to-fast PD sampler exception.
- Result: the current evidence reports 16 raw clocks, 16 buffered clocks, the
  expected async grouping against `clk_sys`, 64 PD Vernier endpoints, 8 slow
  buffered sources, and exact exception application without overmatch or
  undermatch.  Remaining timing is real local fast-domain timing, not the
  intentional Vernier crossing.
- Current status: active equivalent flow, exposed through stable wrapper names.
- Final flow location: stable Genus and Innovus wrappers, stable SDC aliases,
  and active architecture docs.

## Current Policy

- Active user-facing commands use stable names only.
- Historical names remain in this document, archive docs, and compatibility
  labels where needed for traceability.
- Generated raw artifacts are not source.  Preserve compact summaries and keep
  new run output under `work/`.
- No history entry here is a final tapeout signoff claim.
