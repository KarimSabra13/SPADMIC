# Genus O7 Typical From Screenshot Summary

- Run ID: `20260604_o7_typical_from_screenshot`
- Git HEAD: `d38b2c96dcdddbdef3678cab85ae15609046fb3d`
- Flavor: `O7_TYPICAL_FROM_SCREENSHOT_FEASIBILITY_ONLY`
- Genus exit code: 0
- Snapshot exit code: 0
- Source warning: screenshots appear labeled RO_tune3; digital macro is RO_tune4; equivalence not confirmed
- Signoff status: `PROVISIONAL_FROM_SCREENSHOT_NOT_FOR_SIGNOFF`
- Standard-cell Liberty: `/data/pdk/xfab/xh018/diglibs/D_CELLS_HD/v6_0/liberty_LPMOS/v6_0_0/PVT_1_80V_range/D_CELLS_HD_LPMOS_typ_1_80V_25C.lib`
- TC-only view: yes
- MMMC BC/WC views created: no
- Real LEF: `/home/validmgr/ksabra/2026_SPAD/SPADMIC/results/osc_pd/20260528_o1_export_ro_tune4_lef/real_abstract_lef/RO_tune4_real_abstract.lef`
- Real LEF macro: `RO_tune4`
- RO_tune4 Liberty shell: `/home/validmgr/ksabra/2026_SPAD/SPADMIC/MPTDC/syn/macros/RO_tune4_real_abstract_shell.lib`
- SDC overlay: `/home/validmgr/ksabra/2026_SPAD/SPADMIC/MPTDC/syn/inputs/mptdc_osc_typical_from_screenshot.sdc`
- HDL filelist: `/home/validmgr/ksabra/2026_SPAD/SPADMIC/MPTDC/syn/filelist_o5_pd_stdcell_closure.f`
- Slow period ns: `1.000`
- Fast period ns: `0.900`
- Slow tap step ns: `0.055`
- Fast tap step ns: `0.050`
- Jitter RMS ps: `0.614`
- Setup uncertainty ps: `10.0`
- Hold uncertainty ps: `5.0`
- Startup rstb-to-S5 ps: `367.907`
- RO_tune4 instance count: 2
- mptdc_osc_stub residue count: 0
- old fast-counter residue count: 0
- old slow-counter residue count: 0
- report_clocks RO_tune4/S match count: 16
- DRV rough report-design-rules match count: 65

O7_STATUS=O7_NETLIST_CANDIDATE
STATUS_LABEL=FEASIBILITY_ONLY_TYPICAL_RO_SCREENSHOT_MODEL
FINAL_SIGNOFF=NO

## WNS/TNS by Class and Family
## Classes
OSC_FAST_REAL: WNS=-424.0 TNS=-137826.0 count=344
OSC_SLOW_REAL: WNS=0.0 TNS=0.0 count=0
CLK_SYS_REAL: WNS=0.0 TNS=0.0 count=0
PD_INTENTIONAL_VERNIER: WNS=0.0 TNS=0.0 count=0
UNKNOWN_REVIEW_REQUIRED: WNS=0.0 TNS=0.0 count=0

## Families
PD_HIT_TO_TS_FREEZE: WNS=-422.0 TNS=-25377.0 count=62
FAST_TAG_TO_PD_TS: WNS=-424.0 TNS=-104155.0 count=249
LOCAL_FAST_TAG_SELF: WNS=-416.0 TNS=-1503.0 count=8
SLOW_JOHNSON_SELF: WNS=0.0 TNS=0.0 count=0
CLK_SYS_DRAIN: WNS=0.0 TNS=0.0 count=0
CLK_SYS_WATCHDOG: WNS=0.0 TNS=0.0 count=0
OTHER: WNS=-334.0 TNS=-6791.0 count=25

## Key Files
- present: `genus_20260604_o7_typical_from_screenshot.log`
- present: `mptdc_top_asic.postsyn.v`
- present: `o7_typical_from_screenshot_check.rpt`
- present: `run_manifest.txt`
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
- present: `o7_class_wns_summary.txt`
- present: `latch_audit.rpt`
- present: `cdc_manual_audit.rpt`
- present: `report_design_rules.rpt`
- present: `report_area.rpt`
- present: `report_qor.rpt`
