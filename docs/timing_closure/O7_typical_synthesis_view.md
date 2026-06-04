# O7 Typical Synthesis View

O7 is a typical-only feasibility run, not a signoff view.

## Standard-Cell View

The wrapper selects the XFAB D_CELLS_HD typical Liberty:

```text
${SC_ROOT:-/data/pdk/xfab/xh018/diglibs/D_CELLS_HD/v6_0}/liberty_LPMOS/v6_0_0/PVT_1_80V_range/D_CELLS_HD_LPMOS_typ_1_80V_25C.lib
```

The run exports:

```text
MPTDC_TIMING_VIEW=tc_only
MPTDC_TC_ONLY_VIEW=1
```

With those knobs, `MPTDC/syn/inputs/mptdc.mmmc` creates only `tc_view` and uses
that view for both setup and hold.  BC/WC analysis views are not created for
O7.  This avoids the previous pairing of slow standard-cell timing with nominal
oscillator periods.

## Oscillator Macro Binding

O7 keeps the existing real macro binding:

- `O1_USE_REAL_RO_ABSTRACT=1`
- `MPTDC_USE_RO_TUNE4_MACRO=1`
- real LEF from `RO_tune4_real_abstract.lef` or `O1_RO_LEF_PATH`
- structural Liberty shell `MPTDC/syn/macros/RO_tune4_real_abstract_shell.lib`
- clocks attached to `u_core/u_osc_{slow,fast}/u_ro_tune4/S[0:7]`

The shell is not a characterized oscillator Liberty model.  It exists only so
Genus can elaborate and bind the macro pins.

## SDC Overlay

Overlay:

```text
MPTDC/syn/inputs/mptdc_osc_typical_from_screenshot.sdc
```

The wrapper sets:

```text
MPTDC_OSC_SLOW_PERIOD_NS=1.000
MPTDC_OSC_FAST_PERIOD_NS=0.900
MPTDC_OSC_SLOW_TAP_STEP_NS=0.055
MPTDC_OSC_FAST_TAP_STEP_NS=0.050
```

The overlay then replaces oscillator uncertainty with:

```text
setup: 0.010 ns
hold:  0.005 ns
```

No precise clock transition is set from the screenshot cursor slopes.  The slope
markers are local cursor measurements near threshold, not final 10-90 percent
slew characterization.

## Wrapper

Run script:

```text
MPTDC/syn/scripts/server_run_genus_o7_typical_from_screenshot.sh
```

Default filelist:

```text
MPTDC/syn/filelist_o5_pd_stdcell_closure.f
```

This uses the latest standard-cell PD/localtag collateral and changes only the
timing view and screenshot-derived typical overlay.
