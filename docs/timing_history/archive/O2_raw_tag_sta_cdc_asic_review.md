# O2 Raw-Tag STA/CDC/ASIC Review

Date: 2026-06-01

## STA Feasibility

- The old conceptual path `u_fast_cnt/bin_q_reg[*] -> nfast_src_count[*] -> u_pd/nfast_hit_latched_reg[*]` is removed from RTL by removing `u_fast_cnt` from the PD capture path.
- Each fast column has one `mptdc_fast_epoch_tag` clocked by that column's `fast_phase[nf]`.
- Each tag generator drives only the 8 PD cells in its column, not all 64 PD cells.
- The fast-domain next-state logic is a 7-bit LFSR shift/XOR, not a binary carry-chain counter.
- The default O2 drain path emits raw tags.  It does not add tag-to-count decode logic to `clk_sys`.
- Packet/readout logic remains ordinary `clk_sys` logic and must continue to close normally.

Expected new fast paths:

```text
tag_q[nf] -> LFSR next-state -> tag_q[nf]
tag_col[nf] -> 8 PD nfast_hit_latched flops in the same fast_phase[nf] domain
```

The next Genus run must prove that the global binary fast-count-to-PD path is gone.

## CDC Feasibility

- A PD cell captures a raw tag generated in the same `fast_phase[nf]` domain.
- The raw tag becomes part of the held measurement image.
- The existing held-bus bridge into `clk_sys` remains the CDC mechanism.
- No new live multi-bit asynchronous CDC path is introduced by O2.
- Tag clear/reset and PD clear/reset must remain ordered by the existing capture-before-clear contract.

Hard stop: if reports show a tag from one fast phase captured by a different fast phase, stop and fix the RTL/constraints.

## ASIC Feasibility

- One local tag generator per fast column is physically placeable near that column.
- Fanout per tag bit is 8 PD cells.
- No asymmetric phase-tap buffering is introduced.
- Removing the global fast count bus should reduce digital load pressure near the phase fabric.
- Raw-tag mode is acceptable for a calibration-oriented TDC only if mode metadata and software decode are unambiguous.

## Hard Stop Conditions

- Raw tag can be zero after startup.
- Tag sequence wraps within a valid conversion window.
- Software decode cannot reconstruct a monotonic fast cycle.
- VIP/calibration cannot distinguish `legacy_binary_nfast` from `raw_lfsr_tag`.
- The held-bus CDC contract is broken.
- Genus still reports the old `u_fast_cnt/bin_q_reg[*] -> u_pd/nfast_hit_latched_reg[*]` path.
