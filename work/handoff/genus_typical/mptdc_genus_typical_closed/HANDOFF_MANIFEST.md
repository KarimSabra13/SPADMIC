# MPTDC Genus Typical Closed Handoff Manifest

HANDOFF_STATUS=GENUS_TYPICAL_CLOSED
RUN_ID=spadmic_test_stride2_genus_repair8_jihd_exact_20260612_130302
READY_FOR_INNOVUS_TYPICAL_CLOSURE=YES
NOT_MMMC_SIGNOFF=YES
NOT_FINAL_SILICON_SIGNOFF=YES
TYPICAL_ONLY_TAPEOUT_PACKAGE=YES
GENUS_WNS_MARGIN_LOW=YES

## Source

- Genus run: `spadmic_test_stride2_genus_repair8_jihd_exact_20260612_130302`
- Branch: `SPADMIC_test`
- Genus Git HEAD: `f46e1390800dc3ef03caa709560f024ba1e75fa5`
- Expected source directory: `work/genus/spadmic_test_stride2_genus_repair8_jihd_exact_20260612_130302`
- Stable handoff directory: `work/handoff/genus_typical/mptdc_genus_typical_closed`
- Populate command:

```bash
bash MPTDC/pnr/scripts/prepare_mptdc_genus_typical_handoff.sh \
  spadmic_test_stride2_genus_repair8_jihd_exact_20260612_130302
```

## Closure Evidence

- Setup WNS ps: `+0.1`
- Setup TNS ps: `0`
- Setup violating path count: `0`
- Real timed WNS ps: `+0.1`
- Real timed TNS ps: `0`
- Real timed violating path count: `0`
- Max transition/capacitance/fanout violations: `0/0/0`
- UNKNOWN_REVIEW_REQUIRED: `0`
- PD Vernier exception: `64/64`, applied `YES`
- O13 raw RO clocks: `16`
- O13 buffered phase clocks: `16`
- clk_sys async to buffered phase clocks: `YES`
- RO_tune4 instances: `2`
- old oscillator stub residue: `0`
- packet format: `unchanged`
- raw_lfsr_tag: `unchanged`
- frequency mode: `r750_delta5`
- optimization mode: `STRIDE2`

## Required Handoff Files

The populate helper links or copies these files from the Genus run when the
source run exists on the server:

- `mptdc_top_asic.postsyn.v`
- `mptdc_top_asic.postsyn.sdc`
- `mptdc_top_asic.postsyn.sdf` if produced
- `final_sdc_overlay_used.sdc`
- `final_filelist_used.f`
- `SUMMARY.md`
- `timing_summary.rpt`
- `timing_violations.rpt`
- `timing_path_classification_summary.md`
- `report_design_rules.rpt`
- `report_clocks.rpt`
- `report_clock_groups.rpt`
- `pd_vernier_exception_check.rpt`
- `o13_clock_model_check.rpt`
- `packet_contract_check.rpt`
- `macro_binding_check.rpt`
- `final_typical_genus_readiness.md`

## Limitations

This package is a Genus typical-only handoff. It is not MMMC signoff and not
final silicon signoff. Innovus P&R, route DRC, antenna, DRC/LVS, extraction,
power integrity, and final physical checks remain pending.
