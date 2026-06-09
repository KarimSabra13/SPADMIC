# O13 abs2 Failure Analysis

Status: `O13_ABS2_CLOCK_CDC_CONSTRAINT_FAILURE`

This is feasibility evidence only. It is not signoff.

## Evidence Source

- Snapshot: `results/github_snapshots/20260608_o13_genus_only_snapshot_abs2_evidence.tgz`
- Run: `20260608_o13_phase_distribution_genus_abs2`
- Server run HEAD: `17854931400b21ca755b013c5b5e79e839330ccc`

## What Worked

- Genus completed with exit code `0`.
- `RO_tune4` instance count was `2`.
- `mptdc_osc_stub` residue count was `0`.
- Packet format and `raw_lfsr_tag` behavior were unchanged.
- O13 two-stage phase-buffer hierarchy was synthesized.
- The Genus log created all 16 final phase clocks:
  - `clk_osc_slow_buf_tap0..7`
  - `clk_osc_fast_buf_tap0..7`

## What Failed

The bad WNS was dominated by impossible synchronous timing between `clk_sys` and the new buffered oscillator clocks:

- `clk_osc_fast_buf_tap* -> clk_sys`
- `clk_sys -> clk_osc_fast_buf_tap*`

Representative abs2 timing:

- `clk_osc_fast_buf_tap* -> clk_sys`: WNS about `-2568 ps`
- `clk_sys -> clk_osc_fast_buf_tap*`: WNS about `-1784 ps`

These are not real single-clock timing paths. They are CDC/constraint integration failures caused by adding final-driver clocks without also adding those clocks to the async relationship against `clk_sys`.

## Report Issues

- `report_clocks.rpt` at the run root showed raw RO clocks but not final buffer clocks.
- `timing_summary.rpt` did show the final buffer clocks.
- The wrapper therefore reported `report_clocks final-driver generated-clock count: 0`, even though the log created 16 final clocks.
- `timing_pd_capture_hotspots.rpt` failed with invalid endpoint path specifications.
- `timing_clk_sys_violations.rpt` said `No paths found` while aggregate timing still had `clk_sys`-group violations from oscillator-to-system CDC paths.
- Several base SDC commands failed from object-handle use in false-path/max-delay helpers.

## Decision

Do not reject O13 from abs2 timing. Do not run Innovus yet. First repair the O13 clock/CDC/report model and rerun Genus as abs3.
