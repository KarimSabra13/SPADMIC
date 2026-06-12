# SPADMIC Test Repair8 JIHD Exact Fast-Tag Close

Repair8 is the follow-up to `spadmic_test_stride2_genus_repair7_polarity_source_20260612_124021`.

Repair7 successfully applied the polarity-aware exact source-cell upgrade:

- `DFRRQHDX1 -> DFRRQHDX4`: 16 exact source registers
- `DFRSQHDX1 -> DFRSQHDX4`: 8 exact source registers
- final source-cell result: `PASS_FINAL_VERIFIED`
- exact source polarity failed count: 0
- fast-tag mapping status: `PASS`
- active SDC failure count: 0

The timing result did not materially improve:

- setup WNS: `-20.8 ps`
- setup TNS: `-2119.1 ps`
- setup violations: `122`
- worst family: `FAST_TAG_TO_PD_TS`

That result rules out weak HD source-cell mapping as the primary remaining limiter. The next experiment pivots to the localtag closure direction that previously closed this path family: JIHD standard cells plus exact datapath pressure.

## Repair8 Mode

`MPTDC_GENUS_REPAIR8_JIHD_EXACT_FAST_TAG_CLOSE=1`

Defaults:

- `MPTDC_STDCELL_FAMILY=JIHD`
- `MPTDC_GENUS_REPAIR_FAST_TAG_PD=1`
- `MPTDC_GENUS_REPAIR_DRV_TRANSITION=0`
- `MPTDC_GENUS_REPAIR_STRONG_FAST_TAG_FLOPS=0`
- `MPTDC_GENUS_REPAIR_STRONG_CONTROL_DRV=0`
- `MPTDC_GENUS_REPAIR_APPLY_BROAD_CONTROL_NETS=0`
- `MPTDC_GENUS_REPAIR_APPLY_DESIGN_DRV=0`
- `MPTDC_GENUS_RELAX_FAST_TAG_PRESERVE=0`
- `MPTDC_DESIGN_POWER_EFFORT=none`
- exact taps: `0 1 2 3 4 5 6 7`
- exact bits: `0 5 6`
- exact max fanout: `2`
- exact max transition: `0.50 ns`
- exact C-to-D max delay: `1.04 ns`
- exact source-cell forcing: disabled
- endpoint transition tightening: disabled

Repair8 keeps the FAST_TAG_TO_PD_TS paths timed. It does not false-path, multicycle, or classify them as Vernier paths.

## Pass Criteria

- Genus exit code: 0
- setup WNS: `>= 0 ps`
- setup TNS: `0`
- setup violations: `0`
- max transition/cap/fanout violations: `0/0/0`
- `UNKNOWN_REVIEW_REQUIRED`: 0
- PD Vernier exception: 64/64 applied
- O13 raw clocks: 16
- O13 buffered clocks: 16
- `clk_sys` async grouping: OK
- report helpers: PASS
- summary/raw agreement: PASS
- active SDC failures: 0
- packet/raw tag/frequency/phase topology unchanged

