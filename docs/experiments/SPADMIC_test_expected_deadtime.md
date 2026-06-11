# SPADMIC_test Expected Deadtime

Clock: `clk_sys = 160 MHz`, period `6.25 ns`.

## Measurement Fabric

Baseline measurement FSM:

`IDLE -> MEASURE -> SNAPSHOT -> COUNT -> EVAL -> CAPTURE -> CLEAR -> IDLE`

Approximate fabric deadtime:

`D_START_TO_STOP + 9 clk_sys cycles`

If STOP is qualified by 40 MHz reference:

- `D_START_TO_STOP` about 25 ns.
- Fabric deadtime about 81.25 ns.
- Fabric max rate about 12.3 MHz.

This is not the main current lossless bottleneck.

## Baseline Drain Estimate

Worst case drain for up to 64 PD cells:

- CDC visible: about 2 cycles.
- IDLE select: about 1 cycle.
- META: about 1 cycle.
- EMIT META: about 1 cycle.
- SCAN 64 cells: about 64 cycles.
- EMIT 15 HIT records: about 15 cycles.
- Scan done: about 1 cycle.
- EOC release: about 1 cycle.

Total about 86 cycles, 537.5 ns, about 1.86 MHz lossless worst case.

## ROW_SKIP Estimate

One hit in the last row:

- 7 empty row skips.
- 8 cell scans in non-empty row.

Drain is roughly 23 cycles, 143.75 ns, about 6.96 MHz.

Worst-case dense rows see limited gain.

## STRIDE2 Estimate

Worst-case 15 hits:

- Scan work is roughly halved.
- One HIT record per cycle remains the output limit.

Expected worst case about 54 cycles, 337.5 ns, about 2.96 MHz.
