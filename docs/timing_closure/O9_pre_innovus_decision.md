# O9 Pre-Innovus Decision

Date reviewed: 2026-06-04

Decision label:
`NOT_READY_FOR_INNOVUS_YET`,
`NOT_MMMC_SIGNOFF`,
`NOT_FINAL_SILICON_SIGNOFF`.

## Gate Summary

| Gate | Status | Evidence |
|---|---|---|
| Genus timing clean or near-clean | near-clean, not clean | WNS -1.6 ps, TNS -11.2 ps, 7 `OSC_FAST_REAL` paths |
| DRV acceptable or understood | not yet | 1120 max-transition violations, worst 511 ps vs 500 ps |
| `RO_tune4` real LEF available | yes | O9 summary points to real abstract LEF |
| `RO_tune4` Liberty shell available | yes | O9 summary points to structural shell |
| `RO_tune4/S` clocks modeled | yes | 16 clocks in `report_clocks.rpt` |
| R750 delta5 clock periods used | yes | 1.333 ns fast, 1.430 ns slow |
| No stale 0.9/1.0 ns clocks | yes | no stale nominal clocks in final clock report |
| PD matrix hierarchy intact | yes | 64 PD cells in manual CDC audit |
| Packet format unchanged | yes per manifest | `fixed_raw_features_v2_7`, production packet unchanged |
| Characterization passed | not proven in checkout | detailed metric summaries are external only |
| Unknown timing paths | clean | `UNKNOWN_REVIEW_REQUIRED` = 0 |
| Broad false paths hiding measurement logic | no broad evidence found | final SDC overlay says no broad oscillator false paths |
| Final netlist exists | yes | `mptdc_top_asic.postsyn.v` |
| Final SDC exists | yes | `mptdc_top_asic.postsyn.sdc` and overlay |
| Reports complete enough for synthesis review | mostly | exception/clock-group reports have tool limitations |

## Decision Logic

The requested decision logic is:

- If Genus timing is clean and characterization passes: move to Innovus typical
  feasibility.
- If Genus timing is clean but characterization fails: do not move to Innovus.
- If characterization passes but Genus has small violations: decide whether to
  do one more incremental Genus closure before Innovus.
- If both fail: stop and propose root-cause options.

The current committed evidence is in the third/fourth boundary case:

- Genus does not fail architecturally, but it is not clean: 7 residual setup
  paths at WNS -1.6 ps and TNS -11.2 ps.
- Characterization completed structurally per manifest, but the committed
  checkout does not include enough detailed summaries to call it passed.
- DRV is not clean because of 1120 max-transition violations.

Therefore the strict gate is not met yet.

## Blocking Issues Before Innovus Typical

1. Characterization pass evidence is incomplete in the committed checkout.
   The manifest records a completed run, but packet parser, calibration,
   fixed-delay, DNL/INL, boundary-bias, hit-distribution, and memory summaries
   are only listed under `/sim/ksabra/Sim/...`.

2. Final Genus timing is near-clean, not clean. The remaining miss is small and
   localized to `FAST_TAG_TO_PD_TS`, but it is still a real setup violation in
   the final typical view.

3. Design-rule status is not clean. The max-transition violations are small in
   magnitude but numerous. They should be understood before presenting the
   netlist as an Innovus-ready candidate.

4. The final run remains typical-only. It does not cover MMMC, PVT oscillator
   behavior, final RO Liberty timing, extracted parasitics, or place-and-route.

## Recommended Next Step

Do not run Innovus yet.

Recommended order:

1. Commit curated characterization summaries from the server external result
   tree: sweep summary, calibration report, fixed-delay report, memory report,
   and any compact packet/decode reports. Avoid committing giant raw CSVs.

2. Review those summaries to decide whether the O9 characterization truly passes.

3. Decide whether to clear the -1.6 ps residual with one targeted Genus
   incremental run or explicitly carry it as a small synthesis residual for a
   placement-aware experiment. Because the max-transition DRVs are numerous, a
   targeted cleanup run is likely cleaner before Innovus.

4. Move to Innovus typical feasibility only when the characterization pass is
   documented and the residual timing/DRV status is either clean or explicitly
   accepted as a placement-aware risk.

If those conditions are met later, the correct label will be:

`O9_READY_FOR_INNOVUS_TYPICAL_FEASIBILITY`,
`NOT_MMMC_SIGNOFF`,
`NOT_FINAL_SILICON_SIGNOFF`.

The label does not apply yet.

