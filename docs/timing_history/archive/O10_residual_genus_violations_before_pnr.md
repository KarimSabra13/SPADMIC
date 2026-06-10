# O10 Residual Genus Violations Before PnR

Source run: `results/genus_osc_pd/20260604_o9_final_typical_r750_delta5`

## Summary

Label: `NEAR_CLEAN_PRE_PNR_RESIDUAL`

- WNS: -1.6 ps.
- TNS: -11.2 ps.
- Violating paths: 7.
- Timing class: `OSC_FAST_REAL`.
- Path family: residual `FAST_TAG_TO_PD_TS`.
- Stale path evidence: none; `UNKNOWN_REVIEW_REQUIRED = 0`, old oscillator stubs = 0, old fast/slow counter residue = 0.
- Constraint artifact evidence: none obvious. Paths are real local setup paths in `clk_osc_fast`.

Interpretation: do not spend another Genus iteration solely on these -1.6 ps paths before the first Innovus run. Track them in P&R because placement/parasitics may improve or worsen them.

## Exact Paths

Common launch point:

- Startpoint: `(R) u_core_gen_fast_tag_col[0].u_fast_tag_tag_o_reg[5]/C`
- Launch clock: `clk_osc_fast`

Common timing:

- Capture edge: 1333 ps.
- Setup: 268 ps.
- Uncertainty: 10 ps.
- Required time: 1055 ps.
- Data path: 1056 ps.
- Reported slack: -2 ps rounded; summary WNS is -1.6 ps.

| Path | Endpoint | Row | Column | Slack | Family |
|---:|---|---:|---:|---:|---|
| 1 | `(F) u_core_gen_pd_row[7].gen_pd_col[0].u_pd/nfast_hit_latched_reg[5]/D` | 7 | 0 | -2 ps | FAST_TAG_TO_PD_TS |
| 2 | `(F) u_core_gen_pd_row[6].gen_pd_col[0].u_pd/nfast_hit_latched_reg[5]/D` | 6 | 0 | -2 ps | FAST_TAG_TO_PD_TS |
| 3 | `(F) u_core_gen_pd_row[5].gen_pd_col[0].u_pd/nfast_hit_latched_reg[5]/D` | 5 | 0 | -2 ps | FAST_TAG_TO_PD_TS |
| 4 | `(F) u_core_gen_pd_row[4].gen_pd_col[0].u_pd/nfast_hit_latched_reg[5]/D` | 4 | 0 | -2 ps | FAST_TAG_TO_PD_TS |
| 5 | `(F) u_core_gen_pd_row[2].gen_pd_col[0].u_pd/nfast_hit_latched_reg[5]/D` | 2 | 0 | -2 ps | FAST_TAG_TO_PD_TS |
| 6 | `(F) u_core_gen_pd_row[1].gen_pd_col[0].u_pd/nfast_hit_latched_reg[5]/D` | 1 | 0 | -2 ps | FAST_TAG_TO_PD_TS |
| 7 | `(F) u_core_gen_pd_row[0].gen_pd_col[0].u_pd/nfast_hit_latched_reg[5]/D` | 0 | 0 | -2 ps | FAST_TAG_TO_PD_TS |

Missing row: row 3 is not in the violating set.

## Delay Structure

Representative timing points:

- Launch flop: `DFRRQHDX1`, C->Q delay 653 ps, load 49.3 fF, transition 216 ps.
- Shared buffer: `BUHDX8`, delay 229 ps, fanout 9, load 118.0 fF, transition 81 ps.
- PD local inverter: `INHDX2`, delay 72 ps, load 13.4 fF, transition 64 ps.
- PD local gate: `ON22HDX1`, delay 102 ps, load 9.3 fF, transition 119 ps.

Approximate path delay split from report:

- C->Q/cell arc dominated launch portion: 653 ps.
- Shared buffer delay: 229 ps.
- PD-local logic delay: 174 ps.
- Estimated net delay is embedded in Genus global/interconnect arc delays and should be remeasured after placement/route.

## Physical Interpretation

- All violations are in PD column 0.
- All violations use fast tag bit 5.
- Violations are spread across most PD rows in column 0, so row-to-column routing and local tag-to-PD placement are important.
- P&R may improve these if fast tag column 0 logic is placed close to column 0 PD cells and high-load buffering is better physically optimized.
- P&R may worsen these if the PD matrix or tag logic is scattered, if phase/tag routing detours, or if CTS/route congestion increases local cell delay/transition.

## O10 Tracking Requirement

O10 must emit `reports/residual_path_tracking.csv` with one row per exact path and columns:

`stage,startpoint,endpoint,expected_family,matched,status,slack_ps,notes`

Stages:

- `pre_place`
- `post_place`
- `post_cts`
- `post_route`
