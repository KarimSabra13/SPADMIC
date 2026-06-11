# SPADMIC_test Priority Scan Future Plan

Priority next-hit scan is not implemented in this pass.

## Concept

- Maintain `remaining_hit_mask[63:0]`.
- Use a hierarchical 8x8 priority encoder to find the next hit.
- Emit only actual hits.
- Clear emitted hits from the remaining mask.

## Expected Benefit

For H=15, a future implementation could reduce drain time toward:

- FIND plus EMIT: about 37 cycles, about 231 ns at 160 MHz.
- Direct emit if timing allows: about 22 cycles, about 137.5 ns.

## Risks

- Priority encoder timing on `clk_sys`.
- More muxing near context/drain record construction.
- Backpressure interaction when one HIT per cycle remains the output limit.
- P&R congestion near context bank and drain controller.

## Gate Before Implementation

Only revisit after:

- `SAFE_TEARDOWN`, `ROW_SKIP`, and `STRIDE2` pass local tests.
- Stage 1 and Stage 2 characterization are acceptable.
- Genus typical is clean.
- P&R does not show problematic congestion or DRV around context/drain.
