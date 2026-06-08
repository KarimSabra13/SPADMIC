# O12B Clock Model After Phase Buffers

Status: `O12B_PHASE_BUFFER_BALANCE_AND_CLEAN_PNR`

This is a typical feasibility clock-model note, not MMMC signoff.

## Two Clock Boundaries

O12 creates two review points:

| Boundary | Use |
|---|---|
| raw `RO_tune4/S[n]` | analog load and source waveform check |
| BUHDX4 `Q` output | digital PD/tag/epoch timing source |

For analog load, the raw RO pins matter.  For digital STA, the buffered phase
nets matter because those nets clock the downstream fabric after O12 insertion.

## Expected SDC Behavior

The O12 overlays should:

- keep raw clocks on `RO_tune4/S[0:7]`;
- create generated clocks at phase-buffer `Q` outputs;
- use divide-by-1 generated clocks through BUHDX4;
- make buffer insertion delay visible in timing;
- avoid broad false paths through the phase buffers;
- avoid CTS on raw RO clocks and buffered phase clocks;
- allow only `clk_sys` to use normal CTS policy.

## O12B Checks

O12B must answer:

- Are all raw clocks present?
- Are all 16 generated buffer-output clocks present?
- Does `report_clocks.rpt` show the buffer-output clocks?
- Does `timing_post_route_ro_osc_domain.rpt` use buffered oscillator-domain
  timing paths?
- Are phase buffers treated as fixed data/clock-source buffers, not CTS targets?

If the tool cannot prove generated-clock propagation, document the actual timing
behavior and keep `TIMING_DECISION_QUALITY=NO`.
