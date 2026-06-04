#######################################################
#                                                     
#  Innovus Command Logging File                     
#  Created on Thu Jun  4 14:37:34 2026                
#                                                     
#######################################################

#@(#)CDS: Innovus v22.33-s094_1 (64bit) 08/25/2023 16:48 (Linux 3.10.0-693.el7.x86_64)
#@(#)CDS: NanoRoute 22.33-s094_1 NR230808-0153/22_13-UB (database version 18.20.615_1) {superthreading v2.20}
#@(#)CDS: AAE 22.13-s029 (64bit) 08/25/2023 (Linux 3.10.0-693.el7.x86_64)
#@(#)CDS: CTE 22.13-s030_1 () Aug 22 2023 02:51:11 ( )
#@(#)CDS: SYNTECH 22.13-s015_1 () Aug 20 2023 22:21:55 ( )
#@(#)CDS: CPE v22.13-s082
#@(#)CDS: IQuantus/TQuantus 21.2.2-s211 (64bit) Tue Jun 20 22:12:10 PDT 2023 (Linux 3.10.0-693.el7.x86_64)

set_global _enable_mmmc_by_default_flow      $CTE::mmmc_default
suppressMessage ENCEXT-2799
getVersion
getVersion
getVersion
set init_top_cell mptdc_top_asic
set init_verilog /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/genus_osc_pd/20260604_o9_final_typical_r750_delta5/mptdc_top_asic.postsyn.v
set init_lef_file {/data/pdk/xfab/xh018/cadence/v9_0/techLEF/v9_0_1/xh018_xx41_HD_MET4_METMID.lef /data/pdk/xfab/xh018/diglibs/D_CELLS_HD/v6_0/LEF/v6_0_0/xh018_D_CELLS_HD.lef /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/osc_pd/20260528_o1_export_ro_tune4_lef/real_abstract_lef/RO_tune4_real_abstract.lef}
set init_mmmc_file /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/work/o10_typical_only.mmmc
set init_pwr_net VDD
set init_gnd_net VSS
init_design
globalNetConnect VDD -type pgpin -pin vdd -inst *
globalNetConnect VSS -type pgpin -pin gnd -inst *
globalNetConnect VDD -type pgpin -pin VDD -inst *
globalNetConnect VDD -type pgpin -pin vdd! -inst *
globalNetConnect VSS -type pgpin -pin VSS -inst *
report_timing -max_paths 100 > "/home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/reports/timing_pre_place.rpt"
reportNetStat -fanout 50 > /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/reports/high_fanout_summary_pre_place.rpt
reportFanoutViolation > /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/reports/high_fanout_summary_pre_place.rpt
report_constraint -all_violators > /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/reports/drv_pre_place.rpt
floorPlan -site core_hd -r 1.15 0.60 35.0 35.0 35.0 35.0
placeInstance u_core_u_osc_slow_u_ro_tune4 372.4 691.6 R0 -fixed
placeInstance u_core_u_osc_fast_u_ro_tune4 372.4 283.92 MX -fixed
createInstGroup mptdc_o10_pd_matrix
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[0].gen_pd_col[0].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[0].gen_pd_col[1].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[0].gen_pd_col[2].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[0].gen_pd_col[3].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[0].gen_pd_col[4].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[0].gen_pd_col[5].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[0].gen_pd_col[6].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[0].gen_pd_col[7].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[1].gen_pd_col[0].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[1].gen_pd_col[1].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[1].gen_pd_col[2].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[1].gen_pd_col[3].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[1].gen_pd_col[4].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[1].gen_pd_col[5].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[1].gen_pd_col[6].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[1].gen_pd_col[7].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[2].gen_pd_col[0].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[2].gen_pd_col[1].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[2].gen_pd_col[2].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[2].gen_pd_col[3].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[2].gen_pd_col[4].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[2].gen_pd_col[5].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[2].gen_pd_col[6].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[2].gen_pd_col[7].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[3].gen_pd_col[0].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[3].gen_pd_col[1].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[3].gen_pd_col[2].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[3].gen_pd_col[3].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[3].gen_pd_col[4].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[3].gen_pd_col[5].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[3].gen_pd_col[6].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[3].gen_pd_col[7].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[4].gen_pd_col[0].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[4].gen_pd_col[1].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[4].gen_pd_col[2].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[4].gen_pd_col[3].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[4].gen_pd_col[4].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[4].gen_pd_col[5].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[4].gen_pd_col[6].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[4].gen_pd_col[7].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[5].gen_pd_col[0].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[5].gen_pd_col[1].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[5].gen_pd_col[2].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[5].gen_pd_col[3].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[5].gen_pd_col[4].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[5].gen_pd_col[5].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[5].gen_pd_col[6].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[5].gen_pd_col[7].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[6].gen_pd_col[0].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[6].gen_pd_col[1].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[6].gen_pd_col[2].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[6].gen_pd_col[3].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[6].gen_pd_col[4].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[6].gen_pd_col[5].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[6].gen_pd_col[6].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[6].gen_pd_col[7].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[7].gen_pd_col[0].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[7].gen_pd_col[1].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[7].gen_pd_col[2].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[7].gen_pd_col[3].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[7].gen_pd_col[4].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[7].gen_pd_col[5].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[7].gen_pd_col[6].u_pd}
addInstToInstGroup mptdc_o10_pd_matrix {u_core_gen_pd_row[7].gen_pd_col[7].u_pd}
createRegion mptdc_o10_pd_matrix 310.8 371.28 610.4 671.44
setNanoRouteMode -routeBottomRoutingLayer 1
setNanoRouteMode -routeTopRoutingLayer 3
setPlaceMode -place_global_max_density 0.70
defOut -floorplan -netlist /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/def/01_floorplan.def
saveDesign /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/checkpoints/01_floorplan.enc
dumpToGIF /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/screenshots/01_floorplan_overview.png
dumpToGIF /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/screenshots/02_macros_pd_matrix.png
getPlaceMode -place_hierarchical_flow -quiet
report_message -start_cmd
getRouteMode -maxRouteLayer -quiet
getRouteMode -user -maxRouteLayer
getPlaceMode -place_global_place_io_pins -quiet
getPlaceMode -user -maxRouteLayer
getPlaceMode -quiet -adaptiveFlowMode
getPlaceMode -timingDriven -quiet
getPlaceMode -adaptive -quiet
getPlaceMode -relaxSoftBlockageMode -quiet
getPlaceMode -user -relaxSoftBlockageMode
getPlaceMode -ignoreScan -quiet
getPlaceMode -user -ignoreScan
getPlaceMode -repairPlace -quiet
getPlaceMode -user -repairPlace
getPlaceMode -inPlaceOptMode -quiet
getPlaceMode -quiet -bypassFlowEffortHighChecking
getDesignMode -quiet -siPrevention
getPlaceMode -quiet -place_global_exp_enable_3d
getPlaceMode -exp_slack_driven -quiet
um::push_snapshot_stack
getDesignMode -quiet -flowEffort
getDesignMode -highSpeedCore -quiet
getPlaceMode -quiet -adaptive
set spgFlowInInitialPlace 1
getPlaceMode -sdpAlignment -quiet
getPlaceMode -softGuide -quiet
getPlaceMode -useSdpGroup -quiet
getPlaceMode -sdpAlignment -quiet
getPlaceMode -enableDbSaveAreaPadding -quiet
getPlaceMode -quiet -wireLenOptEffort
getPlaceMode -sdpPlace -quiet
getPlaceMode -exp_slack_driven -quiet
getPlaceMode -sdpPlace -quiet
getPlaceMode -groupHighLevelClkGate -quiet
setvar spgRptErrorForScanConnection 0
getPlaceMode -place_global_exp_allow_missing_scan_chain -quiet
getPlaceMode -place_check_library -quiet
getPlaceMode -trimView -quiet
getPlaceMode -expTrimOptBeforeTDGP -quiet
getPlaceMode -quiet -useNonTimingDeleteBufferTree
getPlaceMode -congEffort -quiet
getPlaceMode -relaxSoftBlockageMode -quiet
getPlaceMode -user -relaxSoftBlockageMode
getPlaceMode -ignoreScan -quiet
getPlaceMode -user -ignoreScan
getPlaceMode -repairPlace -quiet
getPlaceMode -user -repairPlace
getPlaceMode -congEffort -quiet
getPlaceMode -fp -quiet
getPlaceMode -timingDriven -quiet
getPlaceMode -user -timingDriven
getPlaceMode -fastFp -quiet
getPlaceMode -clusterMode -quiet
get_proto_model -type_match {flex_module flex_instgroup} -committed -name -tcl
getPlaceMode -inPlaceOptMode -quiet
getPlaceMode -quiet -bypassFlowEffortHighChecking
getPlaceMode -ultraCongEffortFlow -quiet
getPlaceMode -forceTiming -quiet
getPlaceMode -fp -quiet
getPlaceMode -fastfp -quiet
getPlaceMode -timingDriven -quiet
getPlaceMode -fp -quiet
getPlaceMode -fastfp -quiet
getPlaceMode -powerDriven -quiet
getExtractRCMode -quiet -engine
getAnalysisMode -quiet -clkSrcPath
getAnalysisMode -quiet -clockPropagation
getAnalysisMode -quiet -cppr
setExtractRCMode -engine preRoute
setAnalysisMode -clkSrcPath false -clockPropagation forcedIdeal
getPlaceMode -exp_slack_driven -quiet
isAnalysisModeSetup
getPlaceMode -quiet -place_global_exp_solve_unbalance_path
getPlaceMode -quiet -NMPsuppressInfo
getPlaceMode -quiet -place_global_exp_wns_focus_v2
getPlaceMode -quiet -place_incr_exp_isolation_flow
getPlaceMode -wl_budget_mode -quiet
setPlaceMode -reset -place_global_exp_balance_buffer_chain
getPlaceMode -wl_budget_mode -quiet
setPlaceMode -reset -place_global_exp_balance_pipeline
getPlaceMode -place_global_exp_balance_buffer_chain -quiet
getPlaceMode -place_global_exp_balance_pipeline -quiet
getPlaceMode -tdgpMemFlow -quiet
getPlaceMode -user -resetCombineRFLevel
getPlaceMode -quiet -resetCombineRFLevel
setPlaceMode -resetCombineRFLevel 1000
setvar spgSpeedupBuildVSM 1
getPlaceMode -tdgpResetCteTG -quiet
getPlaceMode -macroPlaceMode -quiet
getPlaceMode -place_global_replace_QP -quiet
getPlaceMode -macroPlaceMode -quiet
getPlaceMode -enableDistPlace -quiet
getPlaceMode -exp_slack_driven -quiet
getPlaceMode -place_global_ignore_spare -quiet
getPlaceMode -quiet -expNewFastMode
setPlaceMode -expHiddenFastMode 1
setPlaceMode -reset -ignoreScan
getPlaceMode -quiet -place_global_exp_auto_finish_floorplan
colorizeGeometry
getPlaceMode -quiet -IOSlackAdjust
getPlaceMode -tdgpCteZeroDelayModeDelBuf -quiet
set_global timing_enable_zero_delay_analysis_mode true
getPlaceMode -quiet -useNonTimingDeleteBufferTree
getPlaceMode -quiet -prePlaceOptSimplifyNetlist
getPlaceMode -quiet -enablePrePlaceOptimizations
getPlaceMode -quiet -prePlaceOptDecloneInv
deleteBufferTree -decloneInv
getPlaceMode -tdgpCteZeroDelayModeDelBuf -quiet
set_global timing_enable_zero_delay_analysis_mode false
getAnalysisMode -quiet -honorClockDomains
getPlaceMode -honorUserPathGroup -quiet
getAnalysisMode -quiet -honorClockDomains
set delaycal_use_default_delay_limit 101
set delaycal_default_net_delay 0
set delaycal_default_net_load 0
set delaycal_default_net_load_ignore_for_ilm 0
set delaycal_input_transition_delay 1ps
getAnalysisMode -clkSrcPath -quiet
getAnalysisMode -clockPropagation -quiet
getAnalysisMode -checkType -quiet
buildTimingGraph
getDelayCalMode -ignoreNetLoad -quiet
getDelayCalMode -ignoreNetLoad -quiet
setDelayCalMode -ignoreNetLoad true -quiet
get_global timing_enable_path_group_priority
get_global timing_constraint_enable_group_path_resetting
set_global timing_enable_path_group_priority false
set_global timing_constraint_enable_group_path_resetting false
getOptMode -allowPreCTSClkSrcPaths -quiet
set_global _is_ipo_interactive_path_groups 1
group_path -name in2reg_tmp.3844666 -from {0x2cd 0x2d0} -to 0x2d3 -ignore_source_of_trigger_arc
getOptMode -allowPreCTSClkSrcPaths -quiet
set_global _is_ipo_interactive_path_groups 1
group_path -name in2out_tmp.3844666 -from {0x2d6 0x2d9} -to 0x2dc -ignore_source_of_trigger_arc
set_global _is_ipo_interactive_path_groups 1
group_path -name reg2reg_tmp.3844666 -from 0x2de -to 0x2df
set_global _is_ipo_interactive_path_groups 1
group_path -name reg2out_tmp.3844666 -from 0x2e2 -to 0x2e3
setPathGroupOptions reg2reg_tmp.3844666 -effortLevel high
isAnalysisModeSetup
getAnalysisMode -analysisType -quiet
isAnalysisModeSetup
all_setup_analysis_views
all_hold_analysis_views
get_analysis_view $view -delay_corner
get_delay_corner $dcCorner -power_domain_list
get_delay_corner $dcCorner -library_set
get_library_set $libSetName -si
get_delay_corner $dcCorner -late_library_set
get_delay_corner $dcCorner -early_library_set
reset_path_group -name reg2out_tmp.3844666
set_global _is_ipo_interactive_path_groups 0
reset_path_group -name in2reg_tmp.3844666
set_global _is_ipo_interactive_path_groups 0
reset_path_group -name in2out_tmp.3844666
set_global _is_ipo_interactive_path_groups 0
reset_path_group -name reg2reg_tmp.3844666
set_global _is_ipo_interactive_path_groups 0
setDelayCalMode -ignoreNetLoad false
set delaycal_use_default_delay_limit 1000
set delaycal_default_net_delay 1000ps
set delaycal_input_transition_delay 0ps
set delaycal_default_net_load 0.5pf
set delaycal_default_net_load_ignore_for_ilm 0
all_setup_analysis_views
getPlaceMode -place_global_exp_ignore_low_effort_path_groups -quiet
getPlaceMode -exp_slack_driven -quiet
getAnalysisMode -quiet -honorClockDomains
getPlaceMode -quiet -expSkipGP
getPlaceMode -quiet -place_global_exp_inverter_rewiring
getPlaceMode -ignoreUnproperPowerInit -quiet
getPlaceMode -quiet -expSkipGP
setDelayCalMode -engine feDc
createBasicPathGroups -quiet
psp::embedded_egr_init_
psp::embedded_egr_term_
psp::embedded_egr_init_
psp::embedded_egr_term_
psp::embedded_egr_init_
psp::embedded_egr_term_
reset_path_group
set_global _is_ipo_interactive_path_groups 0
scanReorder
setDelayCalMode -engine aae
all_setup_analysis_views
getPlaceMode -exp_slack_driven -quiet
set_global timing_enable_path_group_priority $gpsPrivate::optSave_ctePGPriority
set_global timing_constraint_enable_group_path_resetting $gpsPrivate::optSave_ctePGResetting
getPlaceMode -quiet -tdgpAdjustNetWeightBySlack
get_ccopt_clock_trees *
getPlaceMode -exp_insert_guidance_clock_tree -quiet
getPlaceMode -exp_cluster_based_high_fanout_buffering -quiet
getPlaceMode -quiet -place_global_exp_heterogeneous_3d_placement
getPlaceMode -place_global_exp_incr_skp_preserve_mode_v2 -quiet
getPlaceMode -quiet -place_global_exp_netlist_balance_flow
getPlaceMode -quiet -timingEffort
getPlaceMode -quiet -place_detail_refinePlace_v3
getPlaceMode -quiet -place_detail_refinePlace_v2
getAnalysisMode -quiet -honorClockDomains
getPlaceMode -honorUserPathGroup -quiet
getAnalysisMode -quiet -honorClockDomains
set delaycal_use_default_delay_limit 101
set delaycal_default_net_delay 0
set delaycal_default_net_load 0
set delaycal_default_net_load_ignore_for_ilm 0
getAnalysisMode -clkSrcPath -quiet
getAnalysisMode -clockPropagation -quiet
getAnalysisMode -checkType -quiet
buildTimingGraph
getDelayCalMode -ignoreNetLoad -quiet
getDelayCalMode -ignoreNetLoad -quiet
setDelayCalMode -ignoreNetLoad true -quiet
get_global timing_enable_path_group_priority
get_global timing_constraint_enable_group_path_resetting
set_global timing_enable_path_group_priority false
set_global timing_constraint_enable_group_path_resetting false
getOptMode -allowPreCTSClkSrcPaths -quiet
set_global _is_ipo_interactive_path_groups 1
group_path -name in2reg_tmp.3844666 -from {0x2ec 0x2ef} -to 0x2f2 -ignore_source_of_trigger_arc
getOptMode -allowPreCTSClkSrcPaths -quiet
set_global _is_ipo_interactive_path_groups 1
group_path -name in2out_tmp.3844666 -from {0x2f5 0x2f8} -to 0x2fb -ignore_source_of_trigger_arc
set_global _is_ipo_interactive_path_groups 1
group_path -name reg2reg_tmp.3844666 -from 0x2fd -to 0x2fe
set_global _is_ipo_interactive_path_groups 1
group_path -name reg2out_tmp.3844666 -from 0x301 -to 0x302
setPathGroupOptions reg2reg_tmp.3844666 -effortLevel high
reset_path_group -name reg2out_tmp.3844666
set_global _is_ipo_interactive_path_groups 0
reset_path_group -name in2reg_tmp.3844666
set_global _is_ipo_interactive_path_groups 0
reset_path_group -name in2out_tmp.3844666
set_global _is_ipo_interactive_path_groups 0
reset_path_group -name reg2reg_tmp.3844666
set_global _is_ipo_interactive_path_groups 0
setDelayCalMode -ignoreNetLoad false
set delaycal_use_default_delay_limit 1000
set delaycal_default_net_delay 1000ps
set delaycal_default_net_load 0.5pf
set delaycal_default_net_load_ignore_for_ilm 0
all_setup_analysis_views
getPlaceMode -place_global_exp_ignore_low_effort_path_groups -quiet
getPlaceMode -exp_slack_driven -quiet
getPlaceMode -quiet -cong_repair_commit_clock_net_route_attr
getPlaceMode -enableDbSaveAreaPadding -quiet
getPlaceMode -quiet -wireLenOptEffort
setPlaceMode -reset -improveWithPsp
getPlaceMode -quiet -debugGlobalPlace
getPlaceMode -congRepair -quiet
getPlaceMode -fp -quiet
getPlaceMode -user -rplaceIncrNPClkGateAwareMode
getPlaceMode -user -congRepairMaxIter
getPlaceMode -quiet -congRepairPDClkGateMode4
setPlaceMode -rplaceIncrNPClkGateAwareMode 4
getPlaceMode -quiet -expCongRepairPDOneLoop
setPlaceMode -congRepairMaxIter 1
getPlaceMode -quickCTS -quiet
get_proto_model -type_match {flex_module flex_instgroup} -committed -name -tcl
getPlaceMode -congRepairForceTrialRoute -quiet
getPlaceMode -user -congRepairForceTrialRoute
setPlaceMode -congRepairForceTrialRoute true
::goMC::is_advanced_metrics_collection_running
congRepair
::goMC::is_advanced_metrics_collection_running
::goMC::is_advanced_metrics_collection_running
::goMC::is_advanced_metrics_collection_running
setPlaceMode -reset -congRepairForceTrialRoute
getPlaceMode -quiet -congRepairPDClkGateMode4
setPlaceMode -reset -rplaceIncrNPClkGateAwareMode
setPlaceMode -reset -congRepairMaxIter
getPlaceMode -congRepairCleanupPadding -quiet
getPlaceMode -quiet -wireLenOptEffort
all_setup_analysis_views
getPlaceMode -exp_slack_driven -quiet
set_global timing_enable_path_group_priority $gpsPrivate::optSave_ctePGPriority
set_global timing_constraint_enable_group_path_resetting $gpsPrivate::optSave_ctePGResetting
getPlaceMode -place_global_exp_incr_skp_preserve_mode_v2 -quiet
getPlaceMode -quiet -place_global_exp_netlist_balance_flow
getPlaceMode -quiet -timingEffort
getPlaceMode -tdgpDumpStageTiming -quiet
getPlaceMode -quiet -tdgpAdjustNetWeightBySlack
getPlaceMode -trimView -quiet
getOptMode -quiet -viewOptPolishing
getOptMode -quiet -fastViewOpt
spInternalUse deleteViewOptManager
spInternalUse tdgp clearSkpData
setAnalysisMode -clkSrcPath true -clockPropagation sdcControl
getPlaceMode -exp_slack_driven -quiet
setExtractRCMode -engine preRoute
setPlaceMode -reset -relaxSoftBlockageMode
setPlaceMode -reset -ignoreScan
setPlaceMode -reset -repairPlace
getPlaceMode -quiet -NMPsuppressInfo
setvar spgSpeedupBuildVSM 0
getPlaceMode -macroPlaceMode -quiet
getPlaceMode -place_global_replace_QP -quiet
getPlaceMode -macroPlaceMode -quiet
getPlaceMode -exp_slack_driven -quiet
getPlaceMode -place_global_ignore_spare -quiet
getPlaceMode -tdgpMemFlow -quiet
setPlaceMode -reset -resetCombineRFLevel
getPlaceMode -quiet -place_global_exp_solve_unbalance_path
setPlaceMode -reset -expHiddenFastMode
getPlaceMode -tcg2Pass -quiet
getPlaceMode -quiet -wireLenOptEffort
getPlaceMode -fp -quiet
getPlaceMode -fastfp -quiet
getPlaceMode -doRPlace -quiet
getPlaceMode -RTCPlaceDesignFlow -quiet
getPlaceMode -quickCTS -quiet
set spgFlowInInitialPlace 0
getPlaceMode -user -maxRouteLayer
spInternalUse TDGP resetIgnoreNetLoad
getPlaceMode -place_global_exp_balance_pipeline -quiet
getDesignMode -quiet -flowEffort
report_message -end_cmd
um::create_snapshot -name final -auto min
um::pop_snapshot_stack
um::create_snapshot -name place_design
getPlaceMode -exp_slack_driven -quiet
optDesign -preCTS
report_timing -max_paths 100 > "/home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/reports/timing_post_place.rpt"
reportNetStat -fanout 50 > /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/reports/high_fanout_summary_post_place.rpt
reportFanoutViolation > /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/reports/high_fanout_summary_post_place.rpt
report_constraint -all_violators > /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/reports/drv_post_place.rpt
defOut /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/def/02_place.def
saveDesign /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/checkpoints/02_place.enc
dumpToGIF /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/screenshots/03_placed_design.png
set_ccopt_property target_skew 0.15
create_ccopt_clock_tree_spec -file /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/work/clk_sys_cts.spec -clock_tree clk_sys
create_ccopt_clock_tree_spec -file /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/work/clk_sys_cts.spec -clock_trees clk_sys
create_ccopt_clock_tree_spec -file /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/work/clk_sys_cts.spec
ccopt_design
clockDesign
optDesign -postCTS
report_timing -max_paths 100 > "/home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/reports/timing_post_cts.rpt"
reportNetStat -fanout 50 > /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/reports/high_fanout_summary_post_cts.rpt
reportFanoutViolation > /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/reports/high_fanout_summary_post_cts.rpt
report_constraint -all_violators > /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/reports/drv_post_cts.rpt
report_timing -check_type hold -max_paths 100 > "/home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/reports/hold_post_cts.rpt"
timeDesign -postCTS -hold > /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/reports/hold_post_cts.rpt
defOut /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/def/03_cts.def
saveDesign /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/checkpoints/03_cts.enc
dumpToGIF /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/screenshots/04_clk_sys_cts.png
routeDesign
optDesign -postRoute
report_timing -max_paths 100 > "/home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/reports/timing_post_route.rpt"
reportNetStat -fanout 50 > /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/reports/high_fanout_summary_post_route.rpt
reportFanoutViolation > /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/reports/high_fanout_summary_post_route.rpt
report_constraint -all_violators > /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/reports/drv_post_route.rpt
report_timing -check_type hold -max_paths 100 > "/home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/reports/hold_post_route.rpt"
timeDesign -postRoute -hold > /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/reports/hold_post_route.rpt
defOut /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/def/04_route.def
saveDesign /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/checkpoints/04_route.enc
dumpToGIF /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/screenshots/05_routed_design.png
dumpToGIF /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/screenshots/06_congestion.png
dumpToGIF /home/validmgr/ksabra/2026_SPAD/SPADMIC/results/innovus/20260604_o10_typical_feasibility/screenshots/08_final_manager_view.png
set enc_check_rename_command_name 1
