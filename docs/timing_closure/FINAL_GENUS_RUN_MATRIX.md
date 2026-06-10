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
| `final_typical_genus_control_late_20260610_154404` | -20.4 | -5782.7 | 378 | `FAST_TAG_TO_PD_TS` | 0 | 0 | DRV fixed, but late control-cell bias still perturbed fast timing. |

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

The control-only and control-late runs are partial isolation results. They
confirm that fast-tag flop bias is not required to clean DRV, but control-driver
cell-class bias is still too broad even when delayed until post-map.

## Next Decision

Run `FINAL_TYPICAL_GENUS_REPAIR_CONTROL_ROOT`.

The exact-root experiment keeps the solved O13/RO/PD/report behavior, keeps
fast-tag preserve relaxation disabled, and disables broad control-cell bias.
It only adds high-fanout PD-control root selection before `syn_opt`:

- `STRONG_CONTROL_DRV=0`
- `CONTROL_CELL_BIAS_STAGE=none`
- `MPTDC_GENUS_REPAIR_EXACT_CONTROL_ROOTS=1`
- `MPTDC_CONTROL_REPAIR_EXACT_MIN_FANOUT=64`
- `STRONG_FAST_TAG_FLOPS=0`
- `MPTDC_GENUS_RELAX_FAST_TAG_PRESERVE=0`
- `MPTDC_GENUS_REPAIR_APPLY_DESIGN_DRV=0`

Expected useful outcome:

- timing returns near the guarded baseline, around `-3.5 ps` WNS and `-77 ps`
  TNS;
- DRV stays at `0 / 0 / 0`.

If that happens, the root-only control repair is good and the remaining work is
a separate narrow `FAST_TAG_TO_PD_TS` setup repair. If timing returns to the
guarded baseline but DRV returns, the exact-root selector is missing the real
root and the repair must be driven from `control_drv_root_causes.csv`.
