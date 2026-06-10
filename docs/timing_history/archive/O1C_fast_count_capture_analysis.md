# O1C Fast Count Capture Analysis

Date: 2026-05-28

## Observed O1A Problem

O1A top timing classes show the dominant oscillator/PD issue is:

```text
fast counter -> nfast_src_count -> PD nfast_hit_latched
```

Representative path:

```text
u_core_u_fast_cnt/bin_q_reg[0]/C
  -> u_core_gen_pd_row[6].gen_pd_col[1].u_pd/nfast_hit_latched_reg[0]/D
```

The destination clock groups are `clk_osc_fast_tap1` through
`clk_osc_fast_tap7`, with worst WNS around `-3163 ps` in O1A.

## Launch/Capture Interpretation

The fast coarse counter is launched from the fast oscillator phase0 clock.  Each
PD cell captures the current fast count on its own fast tap clock while also
performing the Vernier slow-vs-fast phase sampling.

This is not the same class as intentional slow_phase sampled by fast_phase.
The binary count bus into `nfast_hit` is a real high-speed digital timing path
unless the architecture proves the count is stable at every destination tap.

## Current Risk

The current design distributes a multi-bit binary count from the fast counter to
64 PD cells.  The count changes on phase0 and is captured by other fast taps.
For tap1, the available phase window can be close to one fast tap spacing, not a
full oscillator period.  With nominal O1 timing, that is about `50 ps` before
uncertainty, skew, cell delay, and route delay.  That is not enough for a normal
binary-count bus unless there is a specific protocol reason that the sampled
value is allowed to be previous-cycle or phase-shifted.

## What O1C Must Clarify

After real `RO_tune4` binding, Genus reports must classify these paths again:

- phase0 fast counter launch to tap1/tap2/tapN PD count capture
- whether any endpoint is unconstrained or accidentally cut
- whether O1C clocks attach to real macro pins
- whether the WNS remains dominated by the same path class

## Candidate Fix Directions To Evaluate Later

Do not patch these in O1C.  They need evidence after binding.

1. Physical placement/routing:
   place the fast counter close to the fast macro/PD matrix and route the count
   bus with controlled topology.

2. Symmetric local replication:
   replicate count bus registers or buffers per row/phase only if all bits and
   destinations are handled symmetrically and calibration semantics remain
   unchanged.

3. Previous-count capture:
   acceptable only if the reconstruction/calibration model explicitly expects
   the previous fast count for the affected phase windows.

4. Gray count:
   safer for multi-bit phase crossing, but it changes `nfast_hit` semantics and
   requires explicit calibration and packet-field review before any RTL patch.

5. R800 frequency/tap derate:
   can help only if the real failing path has more useful phase window at the
   derated tap spacing.  It is not meaningful before O1C binding and analog tune
   data.

## Current Decision

O1C only fixes macro binding.  The fast-count capture architecture remains under
review and must not be hidden by broad false paths.

## O1C Genus Result Review

Reviewed run:

```text
results/genus_osc_pd/20260528_o1c_macro_binding_genus
```

After real `RO_tune4` macro binding, the same path class remains dominant.  This
means the O1A problem was not only a stub-binding artifact.

Top O1C timing groups:

| Group | WNS (ps) | Paths |
|---|---:|---:|
| `clk_osc_fast_tap2` | -3044.9 | 72 |
| `clk_osc_fast_tap3` | -3037.9 | 72 |
| `clk_osc_fast_tap1` | -3024.0 | 72 |
| `clk_osc_fast` | -2742.9 | 94 |

Local parsing of the committed O1C reports found `248` fast-counter to
`nfast_hit` paths in the classified timing CSV.  The worst reported examples
are all from `u_core_u_fast_cnt/bin_q_reg[*]` to
`gen_pd_col[2]` or `gen_pd_col[3]` `nfast_hit_latched_reg[*]` endpoints.

This strongly suggests a real architecture/timing question:

- If `nfast_hit` must capture the same-cycle binary fast count at each tap,
  nominal closure is unlikely with ordinary standard-cell logic.
- If `nfast_hit` is allowed to capture a previous stable fast count, the SDC
  needs a precise architectural exception or multicycle-style model, not a
  broad false path.
- If the count value must be multi-bit coherent across phase taps, binary count
  capture is fragile; Gray or phase-local count capture is safer but changes
  calibration assumptions and requires explicit approval.

## O1C2 Report Plan

The next Genus run should generate a focused report:

```text
timing_fast_count_to_nfast_hit.rpt
fast_count_capture_endpoint_audit.rpt
fast_count_capture_paths.csv
fast_count_capture_summary.md
```

The summary must bucket violations by:

- fast tap / PD column `nf`;
- slow tap / PD row `ns`;
- fast counter launch bit;
- `nfast_hit` capture bit;
- start and end clock names.

No RTL fast-counter architecture change is made in O1C2.
