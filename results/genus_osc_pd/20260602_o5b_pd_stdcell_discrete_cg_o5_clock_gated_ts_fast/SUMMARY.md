# Genus O5 Standard-Cell PD Closure Summary

- Run ID: `20260602_o5b_pd_stdcell_discrete_cg_o5_clock_gated_ts_fast`
- Git HEAD: `bb241d4f417bc3ce9d9c129f83e57eb50972329b`
- Experiment: `clock_gated_timestamp_discrete`
- Genus effort: `fast`
- Genus exit code: 0
- Snapshot exit code: 0
- Real LEF: `/home/validmgr/ksabra/2026_SPAD/SPADMIC/results/osc_pd/20260528_o1_export_ro_tune4_lef/real_abstract_lef/RO_tune4_real_abstract.lef`
- RO_tune4 Liberty shell: `/home/validmgr/ksabra/2026_SPAD/SPADMIC/MPTDC/syn/macros/RO_tune4_real_abstract_shell.lib`
- SDC overlay: `/home/validmgr/ksabra/2026_SPAD/SPADMIC/MPTDC/syn/inputs/mptdc_osc_pd_o5.sdc`
- HDL filelist: `/home/validmgr/ksabra/2026_SPAD/SPADMIC/MPTDC/syn/filelist_o5_pd_stdcell_closure.f`
- Clock gating requested: `1`
- ICG dont_use override requested: `1`
- Discrete clock gating requested: `1`
- PD preserve relaxed: `1`
- RO_tune4 instance count: 2
- mptdc_osc_stub residue count: 0
- old fast-counter residue count: 0
- old slow-counter residue count: 0
- report_clocks RO_tune4/S match count: 16
- timestamp flop reference count: 448
- resettable timestamp flop reference count: 448
- clock-gating cell netlist count: 168

O5_STATUS=O5_NETLIST_CANDIDATE
STATUS_LABEL=REAL_PHYSICAL_ABSTRACT_WITH_O5_STDCELL_PD_EXPERIMENT
RAW_LFSR_TAG_SOFTWARE_DECODE=YES
PD_TIMESTAMP_FALSE_PATHED=NO

## WNS/TNS by Class and Family
## Classes
OSC_FAST_REAL: WNS=-1805.0 TNS=-475297.0 count=344
OSC_SLOW_REAL: WNS=0.0 TNS=0.0 count=0
CLK_SYS_REAL: WNS=-956.0 TNS=-26407.0 count=96
PD_INTENTIONAL_VERNIER: WNS=0.0 TNS=0.0 count=0
UNKNOWN_REVIEW_REQUIRED: WNS=0.0 TNS=0.0 count=0

## Families
PD_HIT_TO_TS_FREEZE: WNS=0.0 TNS=0.0 count=0
FAST_TAG_TO_PD_TS: WNS=-1461.0 TNS=-217425.0 count=172
LOCAL_FAST_TAG_SELF: WNS=-1466.0 TNS=-31708.0 count=23
SLOW_JOHNSON_SELF: WNS=0.0 TNS=0.0 count=0
CLK_SYS_DRAIN: WNS=-918.0 TNS=-9448.0 count=12
CLK_SYS_WATCHDOG: WNS=-61.0 TNS=-61.0 count=3
OTHER: WNS=-1805.0 TNS=-243062.0 count=230

## Key Files
- present: `genus_20260602_o5b_pd_stdcell_discrete_cg_o5_clock_gated_ts_fast.log`
- present: `mptdc_top_asic.postsyn.v`
- present: `o5_pd_stdcell_check.rpt`
- present: `report_clocks.rpt`
- present: `report_clock_groups.rpt`
- present: `report_exceptions.rpt`
- present: `check_timing_intent.rpt`
- present: `timing_summary.rpt`
- present: `timing_violations.rpt`
- present: `timing_osc_counter_hotspots.rpt`
- present: `timing_pd_capture_hotspots.rpt`
- present: `timing_clk_sys_violations.rpt`
- present: `timing_path_classification.csv`
- present: `timing_path_classification_summary.md`
- present: `o5_class_wns_summary.txt`
- present: `latch_audit.rpt`
- present: `cdc_manual_audit.rpt`
- present: `report_design_rules.rpt`
- present: `report_area.rpt`
- present: `report_qor.rpt`
