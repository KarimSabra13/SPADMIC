# SPADMIC_test Optimization Plan

Branch: `SPADMIC_test`

Base: `SPADMIC_FINAL`

Purpose: controlled convergence branch for small MPTDC throughput optimizations, reset/clear hardening, Genus closure, characterization, and P&R preparation. This branch is not a tapeout signoff branch.

## Invariants

- Packet format remains unchanged.
- RO_tune4 macro wrapper and interface remain unchanged.
- Vernier measurement principle remains unchanged.
- O13 phase distribution topology remains BUHDX4 isolation into BUHDX12 final driver.
- `raw_lfsr_tag` semantics remain unchanged.
- `R750_delta5` mode remains unchanged.
- Fast/slow oscillator sampling paths are not modified.
- CTS remains for `clk_sys` only. RO and buffered phase clocks are excluded from CTS.

## Implemented First-Pass Changes

1. `SAFE_TEARDOWN`
   - Adds `frontend_teardown_busy_i` to the async frontend.
   - Blocks START acceptance while frontend clear, PD clear, or watchdog reset teardown is active.
   - Prevents `ready` from reporting ready while the measurement FSM is not idle or teardown is active.

2. `ROW_SKIP`
   - Adds optional `row_nonzero[7:0]` snapshot metadata.
   - Drain controller skips an empty PD row in one `clk_sys` cycle.
   - Does not change acquisition record or packet format.

3. `STRIDE2`
   - Drain controller inspects two adjacent cells per scan cycle.
   - Emits at most one HIT record per cycle.
   - Stores a second adjacent hit in a local pending register.
   - Does not change acquisition record or packet format.

4. `CLEAR_EARLY`
   - Adds optional early PD clear assertion in CAPTURE and CLEAR.
   - Not selected as default.

## Not Implemented In This Pass

- `CAPTURE_CLEAR_EXPERIMENTAL`.
- Priority next-hit scan.
- Fast-tag reset cleanup that removes `rst_fast_n` from all fast tags.

## Default Candidate Mode

Default candidate for first full server flow: `STRIDE2`.

This enables:

- `MPTDC_SAFE_TEARDOWN`
- `MPTDC_DRAIN_ROW_SKIP`
- `MPTDC_DRAIN_SCAN_STRIDE2`

## Execution Order

1. Local Verilator unit and integration smoke.
2. Stage 1 Xcelium characterization for `BASELINE` and `STRIDE2`.
3. Genus typical for `STRIDE2`.
4. Stage 2 characterization if Genus is clean.
5. Innovus typical P&R only after Genus and Stage 2 are acceptable.
6. Accept, reject, or reduce to `SAFE_TEARDOWN` or `ROW_SKIP`.
