# Final Genus FAST_TAG_TO_PD_TS Repair Plan

Scope: plan only. Do not enable these repairs in
`FINAL_TYPICAL_GENUS_REPAIR_CONTROL_ONLY`.

The remaining setup family is real fast oscillator-domain timing. It is not
CDC, not the intentional PD Vernier crossing, and not a false-path or
multicycle candidate.

## Starting Point

Use the guarded or control-only baseline, not the cellbias run:

- target family: `FAST_TAG_TO_PD_TS`
- reference WNS/TNS: about `-3.5 ps` / `-77 ps`
- reference setup violations: about `42`

The cellbias run is rejected as a setup baseline because broad fast-tag flop
bias produced roughly `-84.7 ps` WNS and `504` setup violations.

## Option A: Exact Fast-Tag Path Sizing

Target only the `FAST_TAG_TO_PD_TS` paths from the guarded/control-only
baseline.

Do not change all fast-tag flops globally. Use top-path evidence and preserve
the O13 phase distribution and PD Vernier exception.

## Option B: Prevent Weak Source Mapping Only

If `DFRRQHDX0` appears on top startpoints, block that specific weak mapping.

Do not block `DFRRQHDX2` globally. The guarded baseline used `DFRRQHDX2` and
was near-clean.

## Option C: Targeted Data-Net Buffering

If timing reports show wire/load dominated nfast tag nets, allow a small buffer
tree on those exact nfast tag bits.

Do not buffer raw RO outputs and do not touch phase clocks.

## Option D: Controlled RTL Duplication

Only consider this if Genus cannot close the path with narrow mapping or data
net repair.

This requires explicit approval because duplicating tag distribution can shift
calibration-sensitive timing semantics.

## Required Evidence Before Enabling

Before any setup repair is enabled, collect:

- `timing_path_classification.csv`
- `final_genus_fast_tag_to_pd_ts_analysis.md`
- `reports/fast_tag_cell_mapping.csv`
- top-path source cell counts
- source load, transition, fanout, and data-path delay by tap/bit

The next setup repair must be compared against the guarded/control-only
baseline, not against the bad cellbias run.

## JIHD Tap0 Micro Repair

Run `final_typical_genus_control_exact_only_jihd_20260610_165235` changes the
residual shape. JIHD keeps DRV clean and reduces setup to:

- WNS/TNS: `-1.4 ps` / `-15.6 ps`
- setup violations: `12`
- family: `FAST_TAG_TO_PD_TS`
- timing group: `clk_osc_fast_buf_tap0`
- source tap: `gen_fast_tag_col[0]`
- source bits: `tag_o_reg[5]`, `tag_o_reg[6]`
- endpoint column: `gen_pd_col[0]`
- endpoint bits: `nfast_hit_latched_reg[5]`, `nfast_hit_latched_reg[6]`

The next enabled repair is therefore narrower than the original options:

```text
MPTDC_FAST_TAG_REPAIR_EXACT_DATA_PATHS=1
MPTDC_FAST_TAG_REPAIR_EXACT_TAPS=0
MPTDC_FAST_TAG_REPAIR_EXACT_BITS="5 6"
MPTDC_FAST_TAG_REPAIR_EXACT_MAX_FANOUT=4
MPTDC_FAST_TAG_REPAIR_EXACT_MAX_TRANSITION_NS=0.35
```

Keep disabled:

- broad fast-tag Q fanout/transition constraints
- broad fast-tag flop bias
- broad control-net repair
- exact control-root repair
- preserve relaxation
- design-wide DRV pressure
- false paths or multicycle constraints on `FAST_TAG_TO_PD_TS`

This repair should be judged only by whether it removes the remaining
tap0 bit5/bit6 setup residue while preserving clean DRV and the existing
O13/RO/PD checks.
