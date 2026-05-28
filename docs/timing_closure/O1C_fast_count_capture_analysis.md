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
