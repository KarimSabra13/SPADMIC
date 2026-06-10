# Final Genus Run Matrix

Scope: `SPADMIC_FINAL` final typical Genus closure, typical-only, not MMMC
and not final silicon signoff.

## Compared Runs

| Run | Setup WNS ps | Setup TNS ps | Setup Violations | Worst Family | DRV Transition Violations | Helper Failures | Notes |
|---|---:|---:|---:|---|---:|---:|---|
| `final_typical_genus_repair_1_20260610_134332` | -3.5 | -77.1 | 42 | `FAST_TAG_TO_PD_TS` | 1015 | 1 | Parser fixed; one helper and one DRV root remained. |
| `final_typical_genus_repair_pressure_20260610_141642` | -91.7 | -37024.9 | 512 | `PD_HIT_LATCH_LOCAL_FAST` | 3505 | 1 | Unsafe preserve relaxation and broad pressure active. |
| `final_typical_genus_repair_guarded_20260610_143941` | -3.5 | -77.1 | 42 | `FAST_TAG_TO_PD_TS` | 1015 | 0 | Best timing baseline; helper path clean. |
| `final_typical_genus_repair_cellbias_20260610_145854` | -84.7 | -21196.0 | 504 | `FAST_TAG_TO_PD_TS` | 0 | 0 | DRV fixed, but broad fast-tag flop bias badly regressed timing. |
| `final_typical_genus_control_only_20260610_152702` | -23.0 | -1870.3 | 218 | `FAST_TAG_TO_PD_TS` | 0 | 0 | DRV fixed, but all-stage control-cell bias still perturbed fast timing. |

## Interpretation

The guarded run is the current reference timing baseline. It is not closed, but
it keeps the real problem narrow: roughly `-3.5 ps` WNS on real
`FAST_TAG_TO_PD_TS` paths plus one high-fanout control-net transition root.

The pressure run is rejected because it released too much local PD/nfast fabric
and changed the fast-domain timing shape.

The cellbias run is also rejected as a timing baseline. It proved the control
DRV problem can be cleaned in Genus, but broad fast-tag source-cell avoidance is
unsafe. Avoiding `DFRRQHDX1/2` did not force a better source register; it
allowed weaker or unclassified source mapping in top fast-tag paths and pushed
WNS to about `-85 ps`.

The control-only run is a partial isolation result. It confirms that fast-tag
flop bias is not required to clean DRV, but the control-driver bias is still too
broad when applied before generic mapping.

## Next Decision

Run `FINAL_TYPICAL_GENUS_REPAIR_CONTROL_LATE`.

The late-control experiment keeps the solved O13/RO/PD/report behavior, keeps
fast-tag preserve relaxation disabled, and applies control-cell bias only after
mapping:

- `STRONG_CONTROL_DRV=1`
- `CONTROL_CELL_BIAS_STAGE=post_map_only`
- `CONTROL_AVOID_INHDX8=0`
- `STRONG_FAST_TAG_FLOPS=0`
- `MPTDC_GENUS_RELAX_FAST_TAG_PRESERVE=0`
- `MPTDC_GENUS_REPAIR_APPLY_DESIGN_DRV=0`

Expected useful outcome:

- timing returns near the guarded baseline, around `-3.5 ps` WNS and `-77 ps`
  TNS;
- DRV stays at `0 / 0 / 0`.

If that happens, the control repair is good and the remaining work is a
separate narrow `FAST_TAG_TO_PD_TS` setup repair. If timing remains around
`-20 ps` or worse, the control-driver bias still perturbs fast timing and must
be replaced with an exact-net DRV repair.
