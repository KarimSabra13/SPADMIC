# O1C3 Fast Count Root Cause

## RTL Path

The failing path is not a synchronized or decoded clk_sys value.  It is a live binary source counter in the oscillator fabric.

- Source RTL: `MPTDC/rtl/cdc/mptdc_gray_cnt_sync.sv`
  - `bin_q` is the source-domain binary counter.
  - `src_count = bin_q`.
  - With the fast counter instance, `src_clk = osc_fast_ph0 = fast_phase[0]`.
- Integration RTL: `MPTDC/rtl/top/mptdc_core.sv`
  - `u_fast_cnt.src_count(nfast_src_count)`.
  - Every PD cell receives `.nfast_count(nfast_src_count)`.
- PD RTL: `MPTDC/rtl/pd/mptdc_pd_cell.sv`
  - On a detected slow falling edge, `nfast_hit_latched <= nfast_count`.
  - The capture clock is each cell's `fast_phase[nf]`.

Therefore the conceptual path is:

```text
RO_tune4 fast S[0]
  -> u_fast_cnt/bin_q_reg[*]
  -> nfast_src_count[*] live binary bus
  -> 64 PD cells
  -> nfast_hit_latched_reg[*] clocked by fast_phase[nf]
```

## Current Clock Windows

The O1C2 SDC uses:

- fast period: `0.9 ns`
- fast tap step: `0.050 ns`
- oscillator setup uncertainty: `0.050 ns`

If the design asks for same-cycle current-count capture from `fast_phase[0]` to `fast_phase[nf]`, the nominal tap windows are:

| Endpoint tap | Launch/capture relation | Nominal edge separation |
|---|---|---:|
| nf=0 | S[0] to S[0] next same phase | 900 ps |
| nf=1 | S[0] to S[1] same cycle | 50 ps |
| nf=2 | S[0] to S[2] same cycle | 100 ps |
| nf=3 | S[0] to S[3] same cycle | 150 ps |
| nf=4 | S[0] to S[4] same cycle | 200 ps |
| nf=5 | S[0] to S[5] same cycle | 250 ps |
| nf=6 | S[0] to S[6] same cycle | 300 ps |
| nf=7 | S[0] to S[7] same cycle | 350 ps |

The latest focused report uses the same window model.  Example from `timing_fast_count_to_nfast_hit.rpt`:

```text
Path 1: clk_osc_fast -> clk_osc_fast_tap1
Capture Clock Edge: 50 ps
Setup: 640 ps
Uncertainty: 50 ps
Required Time: -640 ps
Data Path: 2411 ps
Slack: -3051 ps
```

This is not a close physical margin.  The required time is already negative after setup and uncertainty before accounting for the counter CQ, bus buffering, muxing, or PD-cell logic.

## Evidence From O1C2

- `fast_count_capture_summary.md`
  - fast counter to `nfast_hit` paths parsed: `252`
  - worst slack: `-3051 ps`
  - worst class: `clk_osc_fast_tap1`
  - worst endpoint example: `gen_pd_col[1].u_pd/nfast_hit_latched_reg[4]/D`
- `timing_osc_fast_full_clock.rpt`
  - internal fast counter path `bin_q_reg[2] -> bin_q_reg[5]`: data path `2865 ps`, slack `-2706 ps` at 0.9 ns.
  - This means the ordinary binary counter itself is not feasible as synthesized XH018 standard-cell logic at the modeled fast oscillator frequency.
- `report_high_fanout.rpt`
  - `u_core_fast_phase[0]` fanout `111`.
  - `u_core_fast_phase[1:7]` fanout `80`.
  - `u_core_fast_phase[0]` has extra load from the fast counter.
- `mptdc_pkg.sv`
  - Existing reconstruction comments already describe per-hit `nfast` as one fast count behind the historical loop index via `VERNIER_NFAST_ORIGIN_BIAS = 1`.
  - That supports a previous/stable-count interpretation, but the RTL and constraints do not physically guarantee a stable previous-count bus at every fast tap.

Line references used:

- `results/genus_osc_pd/20260601_o1c2_fast_count_audit_genus/fast_count_capture_summary.md:3-24`
- `results/genus_osc_pd/20260601_o1c2_fast_count_audit_genus/fast_count_capture_summary.md:63-84`
- `results/genus_osc_pd/20260601_o1c2_fast_count_audit_genus/timing_fast_count_to_nfast_hit.rpt:11-30`
- `results/genus_osc_pd/20260601_o1c2_fast_count_audit_genus/timing_osc_fast_full_clock.rpt:11-30`
- `MPTDC/rtl/cdc/mptdc_gray_cnt_sync.sv:67-94`
- `MPTDC/rtl/cdc/mptdc_gray_cnt_sync.sv:103-120`
- `MPTDC/rtl/top/mptdc_core.sv:459-477`
- `MPTDC/rtl/pd/mptdc_pd_cell.sv:83-96`
- `MPTDC/rtl/pkg/mptdc_pkg.sv:52-61`

## Root Cause

The fastest failing class is not merely bad placement or high fanout.  It is a conceptual mismatch between:

1. A live binary counter launched on `fast_phase[0]`.
2. Capture flops clocked by `fast_phase[nf]`, including 50 ps and 100 ps phase windows.
3. Ordinary standard-cell timing in XH018 at the slow PVT corner.
4. A large fanout phase0/load and nfast bus distribution.

Even if the design intends previous-count semantics, the current RTL presents a live same-cycle binary bus.  Genus therefore correctly times the current launch edge into each tap endpoint and reports impossible windows.

## R800 Feasibility Check

R800 is not automatically helpful.  The what-if fast period proposed for R800 is `1.150 ns`, but O1C2 reports setup values around `640-692 ps` and CQ values around `1000-1270 ps` for ordinary flops.  That can still exceed the entire period before routing and counter logic.

R800 should not be run until:

- `RO_tune4` binding remains clean.
- Analog provides the R800 slow/fast tune-code pair and tap delta.
- The fast-domain path being targeted is proven to benefit from the increased period/tap spacing.

## Candidate Fix Directions

### Candidate A: stable fast-cycle tag

Define `nfast_hit` as a stable tag with an explicit count offset.  The tag must be guaranteed stable before any PD capture tap samples it.  This is the cleanest RTL direction if the calibration model already tolerates the one-count offset.

Open issue: generating such a tag inside ordinary standard-cell fast logic may still not close at 0.9 ns unless the tag is produced by a hardened/custom macro or by a much slower/safer phase relation.

### Candidate B: explicit previous-count convention

Document and constrain `nfast_hit` as the previous stable fast count.  This is consistent with the existing `VERNIER_NFAST_ORIGIN_BIAS = 1` comment, but it must be implemented so the current S[0] launch cannot disturb tap captures.

Acceptable only with:

- formal RTL expression of the previous/stable tag
- hold checks proving the next count cannot arrive before tap capture
- calibration documentation for the exact offset
- Xcelium server regression

### Candidate C: Gray tag capture

Gray coding reduces multi-bit coherency hazards but does not fix the impossible 50 ps window by itself.  It can be combined with a stable tag, but it is not sufficient alone.

### Candidate D: local replicated tag/registers

This helps only if the main issue is net fanout.  O1C2 shows the internal fast counter and PD flops themselves are also too slow, so replication alone is unlikely to close.

### Candidate E: hardened measurement macros

Treat the PD cell, fast counter, and maybe slow counter as custom measurement fabric with real Liberty/LEF or explicit waiver package.  This is probably required if the product must keep near-1 GHz oscillator-domain state.

This does not mean broad false paths.  It requires:

- real macro views or approved Liberty shells for measurement flops/latches
- intentional Vernier waiver for q1 slow sampling
- real timing for internal macro paths that are digital
- phase tap load/RC matching reports
- calibration evidence

## Decision

Do not patch `nfast_src_count` architecture casually.  The next major patch should be selected explicitly:

1. If the analog/mixed-signal design can provide hardened PD/counter views, pursue macro/waiver collateral first.
2. If not, choose an RTL stable-tag/previous-count redesign and accept a documented calibration offset.
3. Do not run Innovus or R800 before this decision.
