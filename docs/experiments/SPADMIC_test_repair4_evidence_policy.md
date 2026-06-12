# SPADMIC Test Repair4 Evidence Policy

Repair4 is `SPADMIC_TEST_GENUS_REPAIR4_EXACT_FAST_TAG_SOURCE_DRIVE`.

Repair3 is rejected as a closure baseline. It degraded WNS/TNS, introduced max-transition violations, and produced unauditable fast-tag source mapping. Do not use Repair3 for Innovus, evidence packaging, or further broad strong-fast-tag-flop forcing.

## Scope

Repair4 targets only the real same-fast-domain `FAST_TAG_TO_PD_TS` paths:

- source: fast-tag `tag_o_reg` taps `0..7`, bits `0`, `5`, and `6`
- endpoint: PD `nfast_hit_latched_reg` rows `0..7`, columns `0..7`, bits `0`, `5`, and `6`

Do not alter the O13 clock model, PD Vernier exception, raw RO clocks, buffered phase clocks, clk_sys async grouping, packet format, `raw_lfsr_tag`, `r750_delta5`, phase-buffer topology, or STRIDE2 drain logic.

## Required Evidence Fields

Every Repair4 run must report:

- `SDC_235_COUNT`
- `TUI_61_COUNT`
- `EXACT_FAST_TAG_SOURCES_FOUND`
- `EXACT_FAST_TAG_ENDPOINTS_FOUND`
- `EXACT_FAST_TAG_DATAPATHS_FOUND`
- `EXACT_FAST_TAG_REPAIR_APPLIED`
- `EXACT_FAST_TAG_REPAIR_STATUS`

## Pass Conditions Before Optimization Credit

The evidence gate passes only when:

- `SDC_235_COUNT=0`
- `TUI_61_COUNT=0`
- `EXACT_FAST_TAG_SOURCES_FOUND=24`
- `EXACT_FAST_TAG_ENDPOINTS_FOUND=192`
- `EXACT_FAST_TAG_DATAPATHS_FOUND=192`
- `EXACT_FAST_TAG_REPAIR_APPLIED=YES`
- `EXACT_FAST_TAG_REPAIR_STATUS=PASS`

If any exact collection count is zero or mismatched, the run is `REVIEW_REQUIRED`. Partial exact repair must not be applied silently.

## Repair Policy

Allowed:

- exact path grouping for `FAST_TAG_TO_PD_TS`
- exact source-Q fanout and transition pressure
- conservative source-side improvement for taps `0..7`, bits `0`, `5`, and `6`
- optional exact source-to-endpoint max-delay only after object counts are correct

Forbidden by default:

- global strong fast-tag flop bias
- broad reset-flop avoid/force policies
- endpoint forcing to `DFRSHDX*`
- endpoint D-pin transition tightening
- design-wide DRV pressure
- broad fast-tag preserve relaxation
- broad register remap
- false-path or multicycle relaxation of `FAST_TAG_TO_PD_TS`

## Target

Minimum single-view typical closure is setup WNS >= 0 ps with zero DRV violations. Preferred PNR readiness is setup WNS >= +30 ps, clk_sys/drain margin above +25 ps, zero unknown/review path families, and clean evidence parser status.
