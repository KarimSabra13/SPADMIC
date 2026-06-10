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
| `final_typical_genus_control_root_20260610_160143` | -14.5 | -238.0 | 42 | `FAST_TAG_TO_PD_TS` | 0 | 0 | DRV fixed and path count restored, but six exact roots still cost about 11 ps WNS versus guarded. |
| `final_typical_genus_control_single_root_20260610_161411` | -14.5 | -238.0 | 42 | `FAST_TAG_TO_PD_TS` | 0 | 0 | Selected only `n_6899`/`g33116/Q`, but broad control-net and fast-tag Q constraints were still active. |
| `final_typical_genus_control_exact_only_20260610_162758` | -14.5 | -238.0 | 42 | `FAST_TAG_TO_PD_TS` | 0 | 0 | Pure single-root constraint confirmed; broad control-net and fast-tag Q constraints were skipped, but timing stayed at the control-root result. |
| `final_typical_genus_control_exact_only_jihd_20260610_165235` | -1.4 | -15.6 | 12 | `FAST_TAG_TO_PD_TS` | 0 | 0 | Best result so far. JIHD fixed DRV without selecting exact control roots; only tap0 bit5/6 fast-tag paths remain. |

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

The control-root run was the first useful DRV-clean result without class-level
cell bias. It selected six roots, including reset and epoch capture controls,
so it was not isolated.

The control-single-root run fixed the root selector: it selected only
`n_6899`, driven by `g33116/Q`, with `64` PD sinks and no reset sinks. However,
the shared repair procedure still applied broad control-net constraints to
`130` nets afterward, and it also applied fast-tag Q fanout/transition
constraints. Therefore this run is not a pure single-root test.

The control-exact-only run was the pure single-root test. It selected only
`n_6899`, skipped broad control-net constraints, and skipped fast-tag Q
fanout/transition constraints:

```text
EXACT_CONTROL_ROOT_NETS=1
EXACT_CONTROL_ROOT_NET=n_6899 fanout=64 driver=g33116/Q pd_sinks=64 reset_sinks=0
FAST_TAG_Q_SET_MAX_FANOUT=SKIPPED_FAST_TAG_Q_CONSTRAINTS_DISABLED
FAST_TAG_Q_SET_MAX_TRANSITION=SKIPPED_FAST_TAG_Q_CONSTRAINTS_DISABLED
CONTROL_REPAIR_NETS=SKIPPED_BROAD_CONTROL_NETS_DISABLED
```

Timing still stayed at `-14.5 ps` WNS / `-238.0 ps` TNS with `42` setup
violations. That means the exact control-root `set_max_*` constraint itself is
enough to perturb the fast-domain mapping, even though it also cleans DRV.

## Next Decision

Run a fresh JIHD-library baseline:

`FINAL_TYPICAL_GENUS_REPAIR_CONTROL_EXACT_ONLY_JIHD`

This is not a continuation from the HD closure numbers. It is a required
standard-cell-library migration experiment using the `D_CELLS_JIHD` 1.8 V
typical Liberty/LEF views. Keep the same O13/RO/PD exception/report behavior
and the same exact-only knobs so the only intended technology change is the
standard-cell sublibrary.

Required JIHD inputs:

- standard-cell family `JIHD`
- standard-cell root `/eda/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0`
- standard-cell LEF
  `/eda/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/LEF/v6_0_0/xh018/xh018_D_CELLS_JIHD.lef`
- typical Liberty
  `/eda/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/liberty_LPMOS/v6_0_0/PVT_1_80V_range/D_CELLS_JIHD_LPMOS_typ_1_80V_25C.lib`

Retained exact-only knobs:

- `STRONG_CONTROL_DRV=0`
- `CONTROL_CELL_BIAS_STAGE=none`
- `MPTDC_GENUS_REPAIR_EXACT_CONTROL_ROOTS=1`
- `MPTDC_CONTROL_REPAIR_EXACT_MIN_FANOUT=64`
- `MPTDC_CONTROL_REPAIR_EXACT_REQUIRE_PD_SINKS=1`
- `MPTDC_CONTROL_REPAIR_EXACT_ALLOW_RESET_ROOTS=0`
- `MPTDC_CONTROL_REPAIR_EXACT_DRIVER_REGEX=(^|/)g33116/Q$`
- `MPTDC_CONTROL_REPAIR_EXACT_MAX_ROOTS=1`
- `MPTDC_GENUS_REPAIR_APPLY_BROAD_CONTROL_NETS=0`
- `MPTDC_FAST_TAG_REPAIR_APPLY_Q_CONSTRAINTS=0`
- `STRONG_FAST_TAG_FLOPS=0`
- `MPTDC_GENUS_RELAX_FAST_TAG_PRESERVE=0`
- `MPTDC_GENUS_REPAIR_APPLY_DESIGN_DRV=0`

First JIHD outcome to evaluate:

- O13/RO/clock/PD exception checks remain unchanged and clean;
- report helpers remain `PASS`;
- SDC command failures remain `0`;
- DRV remains `0 / 0 / 0`;
- setup timing is re-baselined under JIHD, with special attention to
  `FAST_TAG_TO_PD_TS` and fast-tag source-cell mapping.

## JIHD Tap0 Micro Closure

Run `final_typical_genus_control_exact_only_jihd_20260610_165235` is the new
baseline. It preserves the O13/RO/PD exception contract, has clean DRV, and
reduces real setup to a small tap0 residue:

- setup WNS/TNS: `-1.4 ps` / `-15.6 ps`
- setup violating paths: `12`
- worst family: `FAST_TAG_TO_PD_TS`
- affected group: `clk_osc_fast_buf_tap0`
- affected fast-tag bits: `5` and `6`
- affected PD column: `0`
- DRV: `0 / 0 / 0`
- `FAST_TAG_MAPPING_STATUS=PASS`
- `FAST_TAG_SOURCE_UNKNOWN_COUNT=0`

The next run is:

`FINAL_TYPICAL_GENUS_REPAIR_JIHD_TAP0_MICRO`

It keeps JIHD and disables all broad repair pressure. It applies only exact
data-path optimization pressure to:

- source tap: `gen_fast_tag_col[0]`
- source bits: `tag_o_reg[5]`, `tag_o_reg[6]`
- endpoint column: `gen_pd_col[0]`
- endpoint bits: `nfast_hit_latched_reg[5]`, `nfast_hit_latched_reg[6]`

Pass criteria:

- setup WNS `>= 0 ps`
- setup TNS `0 ps`
- setup violating paths `0`
- max transition/cap/fanout `0 / 0 / 0`
- report helpers `PASS`
- SDC failures `0`
- `UNKNOWN_REVIEW_REQUIRED=0`
- `FAST_TAG_MAPPING_STATUS=PASS`

If this passes, the next stage is `MPTDC_FINAL_TYPICAL_INNOVUS_FEASIBILITY`.
