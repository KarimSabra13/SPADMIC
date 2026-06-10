# Evidence: 20260604_o9_final_typical_r750_delta5

Status: `HISTORICAL_FULL_GENUS_REFERENCE_NOT_CURRENT_CLOSURE`

Labels:

- `TYPICAL_ONLY_TAPEOUT_PACKAGE`
- `NOT_MMMC_SIGNOFF`
- `FINAL_SIGNOFF=NO`

## Source

- Local evidence path: `results/genus_osc_pd/20260604_o9_final_typical_r750_delta5/`
- Historical HEAD in summary: `e1696b9575febffe0d4a51cf5050c1b72835f2ca`
- Mode: R750_delta5 typical-only Genus

## Key Results

- Genus exit code: `0`
- RO_tune4 instance count: `2`
- mptdc_osc_stub residue count: `0`
- raw RO clocks in `report_clocks.rpt`: `16`
- Timing classification unknowns: `0`
- QoR total: WNS about `-1.6 ps`, TNS about `-11.2 ps`, `7` violating paths
- Timing violations: fast tag to PD `nfast_hit_latched_reg[5]`, about `-2 ps`
- Max capacitance: no violations
- Max fanout: no violations
- Max transition: violation total `1120`

## XLIBD Context

- `BUHDX4` input cap is `10.56 fF`, below the strict `58.72 fF` RO budget.
- `BUHDX12` is the preferred final phase driver among extracted BUHD cells.
- XLIBD does not replace Liberty timing or waive the max-transition report.

## Interpretation

The historical full run is close enough to guide the next run, but it is not a
closure result. The current stable Genus flow must prove the phase-distribution
clock model and exact PD Vernier exception on the cleaned branch.

If a fresh run still shows a small negative fast-domain path, classify the
single worst real family first. Do not waive q1/q2, hit latch, fast tag, slow
Johnson, or clk_sys internal paths broadly.
