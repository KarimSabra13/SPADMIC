# Genus O5 Standard-Cell PD Closure Summary

- Run ID: `20260602_o5_pd_stdcell_closure_o5_clock_gated_ts_fast`
- Git HEAD: `fecd46b0fedfafe596d7e29242e69836b12f6bea`
- Experiment: `clock_gated_timestamp`
- Genus effort: `fast`
- Genus exit code: 0
- Snapshot exit code: 0
- Real LEF: `/home/validmgr/ksabra/2026_SPAD/SPADMIC/results/osc_pd/20260528_o1_export_ro_tune4_lef/real_abstract_lef/RO_tune4_real_abstract.lef`
- RO_tune4 Liberty shell: `/home/validmgr/ksabra/2026_SPAD/SPADMIC/MPTDC/syn/macros/RO_tune4_real_abstract_shell.lib`
- SDC overlay: `/home/validmgr/ksabra/2026_SPAD/SPADMIC/MPTDC/syn/inputs/mptdc_osc_pd_o5.sdc`
- HDL filelist: `/home/validmgr/ksabra/2026_SPAD/SPADMIC/MPTDC/syn/filelist_o5_pd_stdcell_closure.f`
- Clock gating requested: `1`
- ICG dont_use override requested: `1`
- PD preserve relaxed: `1`
- RO_tune4 instance count: 0
- mptdc_osc_stub residue count: 0
- old fast-counter residue count: 0
- old slow-counter residue count: 0
- report_clocks RO_tune4/S match count: 0
- timestamp flop reference count: 0
- resettable timestamp flop reference count: 0
- clock-gating cell netlist count: 0

O5_STATUS=O5_SERVER_REVIEW_REQUIRED
STATUS_LABEL=REAL_PHYSICAL_ABSTRACT_WITH_O5_STDCELL_PD_EXPERIMENT
RAW_LFSR_TAG_SOFTWARE_DECODE=YES
PD_TIMESTAMP_FALSE_PATHED=NO

## WNS/TNS by Class and Family
## Classes
OSC_FAST_REAL: WNS=0.0 TNS=0.0 count=0
OSC_SLOW_REAL: WNS=0.0 TNS=0.0 count=0
CLK_SYS_REAL: WNS=0.0 TNS=0.0 count=0
PD_INTENTIONAL_VERNIER: WNS=0.0 TNS=0.0 count=0
UNKNOWN_REVIEW_REQUIRED: WNS=0.0 TNS=0.0 count=0

## Families
PD_HIT_TO_TS_FREEZE: WNS=0.0 TNS=0.0 count=0
FAST_TAG_TO_PD_TS: WNS=0.0 TNS=0.0 count=0
LOCAL_FAST_TAG_SELF: WNS=0.0 TNS=0.0 count=0
SLOW_JOHNSON_SELF: WNS=0.0 TNS=0.0 count=0
CLK_SYS_DRAIN: WNS=0.0 TNS=0.0 count=0
CLK_SYS_WATCHDOG: WNS=0.0 TNS=0.0 count=0
OTHER: WNS=0.0 TNS=0.0 count=0

## Key Files
- present: `genus_20260602_o5_pd_stdcell_closure_o5_clock_gated_ts_fast.log`
- missing: `mptdc_top_asic.postsyn.v`
- present: `o5_pd_stdcell_check.rpt`
- missing: `report_clocks.rpt`
- missing: `report_clock_groups.rpt`
- missing: `report_exceptions.rpt`
- present: `check_timing_intent.rpt`
- missing: `timing_summary.rpt`
- missing: `timing_violations.rpt`
- missing: `timing_osc_counter_hotspots.rpt`
- missing: `timing_pd_capture_hotspots.rpt`
- missing: `timing_clk_sys_violations.rpt`
- missing: `timing_path_classification.csv`
- missing: `timing_path_classification_summary.md`
- present: `o5_class_wns_summary.txt`
- missing: `latch_audit.rpt`
- missing: `cdc_manual_audit.rpt`
- missing: `report_design_rules.rpt`
- missing: `report_area.rpt`
- missing: `report_qor.rpt`
