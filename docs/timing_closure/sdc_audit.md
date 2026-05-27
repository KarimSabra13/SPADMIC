# MPTDC SDC Audit

Audit date: 2026-05-27

Scope:

- `MPTDC/syn/inputs/mptdc.sdc`
- `MPTDC/syn/inputs/mptdc.defines`
- `results/genus/20260527_0845_current_head_genus_baseline/report_clocks.rpt`
- `results/genus/20260527_0845_current_head_genus_baseline/check_timing_intent.rpt`

## Clock Definitions

Primary clock:

- `clk_sys`: `6.25 ns`, 160 MHz, uncertainty `0.3 ns`.

Oscillator placeholder clocks:

- `clk_osc_slow`: `1.0 ns`, tap step `0.055 ns`.
- `clk_osc_slow_tap1..7`: same period with phase-shifted waveform.
- `clk_osc_fast`: `0.9 ns`, tap step `0.050 ns`.
- `clk_osc_fast_tap1..7`: same period with phase-shifted waveform.

These oscillator clocks are still placeholder constraints until real oscillator
Liberty/LEF and tap timing contracts exist.

## Clock Groups

The SDC applies:

```tcl
set_clock_groups -asynchronous \
    -group [get_clocks $design(CLK_NAME)] \
    -group [get_clocks $design(OSC_SLOW_CLOCKS)] \
    -group [get_clocks $design(OSC_FAST_CLOCKS)]
```

This separates sys, slow-osc, and fast-osc groups. It does not cut timing inside
the fast tap group or inside the slow tap group. The worst baseline violations
are fast-clock/tap-group paths, so they are not hidden by this clock grouping.

## False Paths

Explicit false-path areas:

- async START/STOP/calibration inputs
- async reset input
- PD conversion clear pins
- Gray-counter async clear pins
- START watchdog async clear pins
- STOP metadata async capture data pins

These are plausible exception classes, but each must stay tied to a CDC/async
waiver entry. They must not hide ordinary clk_sys backend paths.

## Max Delay

Current max-delay areas:

- oscillator clocks to clk_sys, bounded to one `clk_sys` period
- clk_sys to fast oscillator clocks, bounded to one fast period
- STOP metadata static bus into clk_sys snapshot flops, bounded to one
  `clk_sys` period

Risk to check with server reports:

- Whether broad clock-group exceptions override any intended CDC max-delay.
- Whether Genus reports these exceptions as no-effect or suppressed.

The baseline `check_timing_intent.rpt` reports `10` no-effect timing exceptions,
including slow tap clocks and SDC line 260 entries. The next report run must make
exception reporting more explicit.

## Case Analysis

Production mode is enabled by default:

- `shared_readout_en_i = 1`
- `narrow_ready_i = 0`

This matches shared-acquisition readout mode. Standalone/local narrow16 timing
needs a separate mode if standalone packet-output support must be signed off.

## IO Delay/Load

Macro-mode assumptions:

- input delay: `0.5 ns`
- output delay: `0.5 ns`
- output load: `0.01 pF`
- input transition: `0.1 ns`

Async START/STOP/calibration/reset inputs are intentionally excluded from
clocked external delay and are false-pathed from the input port.

## Design Rules

Current design-rule constraints:

- max fanout: `20`
- max transition: `0.5 ns`
- reset max fanout: `32`
- reset max transition: `0.35 ns`

Baseline Genus reports `282226` max-transition violations. The current DRV
report does not provide enough source-net attribution, so the report scripts now
need verbose DRV and high-fanout net reports.

## Preservation

Protected structures:

- reset synchronizer flops
- Gray synchronizer flops
- pulse synchronizer flops
- context drain sync flops
- rejected START pending/sync structures
- STOP capture registers
- PD cells / PD matrix hierarchy

Risk:

- The log still shows attempts to preserve partially unmapped reset-sync and
  PD-cell modules, which Genus rejects noisily. This is a reporting hygiene issue
  and should be cleaned after confirming the leaf instances remain protected.

Ordinary clk_sys backend logic should not be globally preserved:

- `mptdc_meas_ctrl`
- `mptdc_context_bank`
- `mptdc_drain_ctrl`
- FIFO/readout logic

## Current Conclusion

The SDC is not currently hiding the reported clk_sys WNS in the summary, but the
report set is insufficient to classify those clk_sys paths. The immediate fix is
better reporting, not weaker exceptions.
