# O13 abs3 Clock CDC Constraint Repair Plan

Status: `PREPARED_FOR_SERVER_RUN`

Goal: keep the O13 BUHDX4-to-BUHDX12 topology, repair the clock/CDC model, and make Genus timing reports interpretable before Innovus.

## Scope

- No RTL changes.
- No packet format change.
- No frequency change.
- No `raw_lfsr_tag` change.
- No characterization.
- No Innovus until abs3 Genus is reviewed.

## Fixes

1. Add `mptdc_osc_typical_r750_delta5_o13_abs3.sdc`.
2. Create or verify all 16 final BUHDX12 output clocks.
3. Add final buffer clocks to the oscillator clock collection.
4. Re-apply `set_clock_groups -asynchronous` between `clk_sys` and all raw/final oscillator clocks.
5. Preserve raw RO clocks for analog load reporting.
6. Keep raw and final oscillator clocks in the same oscillator group so phase-buffer propagation stays visible.
7. Fix wrapper clock counting by searching exact clock names across all relevant reports and logs.
8. Add abs3-only reports for CDC review, phase-buffer clock paths, and clock-model checks.
9. Repair base SDC helpers that passed object handles into SDC commands.

## Expected Abs3 Outcome

The impossible `clk_sys <-> clk_osc_*_buf_tap*` setup paths should disappear from ordinary setup violations. Any remaining timing must classify as real oscillator-domain timing, real `clk_sys` timing, intentional Vernier measurement behavior, held-bus CDC, reset/recovery, or `UNKNOWN_REVIEW_REQUIRED`.

If `UNKNOWN_REVIEW_REQUIRED > 0`, do not proceed to Innovus.
