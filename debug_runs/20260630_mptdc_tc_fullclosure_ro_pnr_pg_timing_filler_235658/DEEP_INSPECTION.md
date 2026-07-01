# Deep Inspection: 20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658

RUN_DIR=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658
CAPTURED_AT=2026-07-01T09:23:36+02:00
GIT_HEAD=07e168dee2e686f8db6c5560f4628ca48d3db808

## Stage Trace
timestamp,stage,status
"2026-06-30 23:57:26 CEST","source_gate","start"
"2026-06-30 23:57:26 CEST","source_gate","done"
"2026-06-30 23:57:26 CEST","import_mmmc","start"
"2026-06-30 23:57:30 CEST","import_mmmc","done"
"2026-06-30 23:57:30 CEST","post_import_gate","start"
"2026-06-30 23:57:30 CEST","post_import_gate","done"
"2026-06-30 23:57:30 CEST","post_import_tc_timing","start"
"2026-06-30 23:57:39 CEST","post_import_tc_timing","done"
"2026-06-30 23:57:39 CEST","floorplan","start"
"2026-06-30 23:57:41 CEST","floorplan","done"
"2026-06-30 23:57:41 CEST","io_placement","start"
"2026-06-30 23:57:41 CEST","io_placement","done"
"2026-06-30 23:57:41 CEST","ro_macro_placement","start"
"2026-06-30 23:57:41 CEST","ro_macro_placement","done"
"2026-06-30 23:57:41 CEST","pg_connectivity","start"
"2026-06-30 23:57:42 CEST","pg_connectivity","done"
"2026-06-30 23:57:42 CEST","pd_matrix_placement","start"
"2026-06-30 23:57:45 CEST","pd_matrix_placement","done"
"2026-06-30 23:57:45 CEST","phase_buffer_placement","start"
"2026-06-30 23:57:48 CEST","phase_buffer_placement","done"
"2026-06-30 23:57:48 CEST","row_infrastructure","start"
"2026-06-30 23:57:48 CEST","row_infrastructure","done"
"2026-06-30 23:57:48 CEST","placement","start"
"2026-07-01 00:01:46 CEST","placement","done"
"2026-07-01 00:01:46 CEST","cts","start"
"2026-07-01 00:10:14 CEST","cts","done"
"2026-07-01 00:10:14 CEST","route","start"
"2026-07-01 00:27:21 CEST","route","fail"

## Run Manifest
# MPTDC Digital Block Signoff Wrapper
Author: Karim Sabra
date: 2026-06-30T23:56:59+02:00
repo: /home/validmgr/ksabra/2026_SPAD/SPADMIC
branch: SPADMIC_test
head: 07e168dee2e686f8db6c5560f4628ca48d3db808
mode: full_signoff
run_id: 20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658
result_dir: /sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658
genus_run_id: MPTDC_TC_Closure_Genus_RO6_xx31_20260629_1233
genus_run_dir: unset
handoff_dir: /sim/ksabra/SPADMIC_work/handoff/genus_typical/MPTDC_TC_Closure_Genus_RO6_xx31_20260629_1233_handoff
row_infra_policy: NO_DEDICATED_CORE_TAP_ENDCAP_PENDING_DRC_LVS
allow_no_core_tap_endcap_policy: 1
closure_scope: TC_ONLY
xh018_stack: xx31
technology_lef: /eda/pdk/xfab/xh018/cadence/v9_0/techLEF/v9_0_1/xh018_xx31_HD_MET3_METMID.lef
captable_bc: /eda/pdk/xfab/xh018/cadence/v9_0/capTbl/v9_0_1/xh018_xx31_MET3_METMID_min.capTbl
captable_tc: /eda/pdk/xfab/xh018/cadence/v9_0/capTbl/v9_0_1/xh018_xx31_MET3_METMID_typ.capTbl
captable_wc: /eda/pdk/xfab/xh018/cadence/v9_0/capTbl/v9_0_1/xh018_xx31_MET3_METMID_max.capTbl
qrc_root: /eda/pdk/xfab/xh018/cadence/v10_1/QRC_pvs/v10_1_1/XH018_1131
route_layers: MET1 MET2 MET3 METTP
signal_top_layer: MET3
effective_top_floor_layer: METTP
ro_handoff_env: /home/validmgr/ksabra/2026_SPAD/SPADMIC/MPTDC/analog_handoff/real_ro_tune6_layout.env
ro_handoff_override_status: preserved:O1_USE_REAL_RO_ABSTRACT O1_RO_CELL_NAME O1_RO_SOURCE_LEF_PATH O1_RO_LEF_PATH O1_RO_LIBERTY_PATH
O1_USE_REAL_RO_ABSTRACT: 1
O1_RO_CELL_NAME: RO_tune6
O1_RO_LEF_PATH: /sim/ksabra/SPADMIC_work/lef/RO_tune6_pnr_pin_access_macro_only_20260630_mptdc_ro_lef_access_patch_real_lef_nofiller_v2_20260630_174804.lef
O1_RO_LEF_MACRO: RO_tune6
MPTDC_PNR_OSC_WIDTH_UM: 168.945
MPTDC_PNR_OSC_HEIGHT_UM: 70.5
O1_RO_LIBERTY_PATH: /home/validmgr/ksabra/2026_SPAD/SPADMIC/MPTDC/syn/macros/RO_tune6_real_layout_shell.lib
pd_tile_constraint_mode: none
pd_tile_apply_hier_box: 0
pd_tile_region_margin_um: 0.0
pd_physical_audit_mode: soft_region
pnr_core_util: 0.55
fix_ro_macros: 0
create_ro_halos: 0
phase_buf_orient: ROW_LEGAL
row_legal_orient_candidates: MX R180 MY R0
ro_phase_min_clearance_um: 10.0
ro_phase_origin_clearance_um: 16.0
ro_phase_preplace_audit: 1
fast_tag_column_side: center
postroute_setup_passes: 10
postroute_setup_max_passes: 10
postroute_setup_plateau_guard: 1
fast_tag_targeted_eco: 1
fast_tag_eco_protect_endpoint_flops: 0
fast_tag_eco_upsize_small_gates: 1
fast_tag_eco_path_driven: 1
fast_tag_eco_path_max_paths: 150
fast_tag_eco_path_max_cells: 160
fast_tag_eco_name_fallback: 0
fast_tag_eco_allow_endpoint_flop_resize: 1
block_pg_pins: 1
block_pg_pin_layer: METTP
block_pg_pin_style: mesh_lr_vdd_vss
block_pg_pin_width_um: 4.0
block_pg_pin_depth_um: 28.0
block_pg_pin_outside_overlap_um: 8.0
block_pg_pin_create_mode: geom
block_pg_pin_editpin_fallback: 0
pg_policy_guard: PASS
allow_legacy_pg_topology: 0
block_pg_stitch_stripes: 0
block_pg_stitch_width_um: 2.0
block_pg_stitch_spacing_um: 2.0
block_pg_stitch_set_distance_um: 5000.0
block_pg_stitch_number_of_sets: 0
final_filler: 1
post_filler_sroute: 1
post_filler_sroute_required_bypass: 0
preplace_pg_sroute: 0
allow_provisional_preplace_pg: 1
postplace_pre_route_sroute: 1
postplace_pre_route_sroute_require_clean: 0
postplace_pre_route_accept_pg_verify_clean: 1
postplace_sroute_candidate_probe: 0
postplace_sroute_blockpin: 0
sroute_padpin_fallback: 0
sroute_mode_experiments: 0
sroute_preserve_existing_routes: 0
sroute_connect_stripe: 1
sroute_via_connect_to_shape: unset
sroute_target_search_distance_um: unset
sroute_core_pin_stop_route: RowEnd
ro_pg_probe: 1
ro_pg_hookup: 1
ro_pg_hookup_required: 1
ro_pg_hookup_search_um: 45.0
ro_pg_hookup_margin_um: 1.0
ro_pg_hookup_spacing_um: 2.0
ro_pg_hookup_set_distance_um: 5000.0
db_display_limit: 50000
route_gate_sroute_recovery: 1
filler_add_fillers_with_drc: 0
require_drc_safe_filler: 1
route_repair_commands: {ecoRoute -target} {ecoRoute -fix_drc}
route_drc_review_continue: 1
route_drc_review_max_violations: 5
route_drc_review_allowed_classes: Mar
labels: MPTDC_TC_PNR_CLOSURE DIGITAL_PNR_SIGNOFF_FLOW TC_ONLY NOT_MMMC_SIGNOFF READY_FOR_TAPEOUT_NO

git status --short --untracked-files=no:
MPTDC_PNR_OSC_WIDTH_UM=168.945
MPTDC_PNR_OSC_HEIGHT_UM=70.5
MPTDC_RO_LEF_SIZE_STATUS=PASS

## Top-Level Signoff Status
# MPTDC Digital PNR Signoff Status
Author: Karim Sabra
STATUS_SCHEMA=PASS_FAIL_EXTERNAL_DEFERRED_PROVISIONAL_ACCEPTED
MPTDC_CLOSURE_SCOPE=TC_ONLY evidence=run_contract
MPTDC_TC_PNR_CLOSURE=DEFERRED evidence=tc_physical_closure_not_complete
NOT_MMMC_SIGNOFF=YES evidence=scope_tc_only
READY_FOR_TAPEOUT=NO evidence=not_mmmc_and_row_drc_lvs_deferred
PRE_PNR_GATE_STATUS=PASS evidence=pre_pnr_gate.rpt
GENUS_HANDOFF_STATUS=PASS evidence=init_design
RO_IMPORT_STATUS=PASS evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_import_integrity_gate.rpt
EFFECTIVE_SDC_STATUS=PASS evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/effective_sdc_audit.rpt
ROW_INFRA_POLICY_STATUS=PROVISIONAL evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/row_infra_insertion.rpt
ROW_INFRA_DRC_LVS_STATUS=DEFERRED evidence=row_drc_lvs_not_run
PHYSICAL_CELL_CONFIG_STATUS=PROVISIONAL evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/row_infra_policy.rpt
PG_CONNECTIVITY_STATUS=FAIL evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_postroute_connectivity_status.rpt
PG_PHYSICAL_STATUS=PROVISIONAL evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_physical_status.rpt
FLOORPLAN_STATUS=PASS evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/floorplan_status.rpt
FLOORPLAN_ASPECT_STATUS=PASS evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/floorplan_status.rpt
IO_STATUS=PASS evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/io_status.rpt
RO_MACRO_STATUS=PASS evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_macro_status.rpt
RO_PHASE_PLACEMENT_STATUS=PASS evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_phase_overlap_audit.rpt
PD_MATRIX_STATUS=REVIEW_REQUIRED evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_physical_matrix_status.rpt
PD_PHYSICAL_MATRIX_STATUS=REVIEW_REQUIRED evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_physical_matrix_status.rpt
PHASE_BUFFER_STATUS=PASS evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_buffer_status.rpt
PLACEMENT_STATUS=PASS evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/placement_status.rpt
CTS_STATUS=PASS evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/cts_policy.rpt
ROUTE_STATUS=FAIL evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_failed.rpt
FILLER_STATUS=PASS evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_status.rpt
EXTRACTION_STATUS=DEFERRED evidence=not_run
POWER_STATUS=DEFERRED evidence=not_run
SETUP_STATUS_TC=PROVISIONAL evidence=timing_tc_post_import.rpt
TC_HOLD_STATUS=DEFERRED evidence=not_run
SETUP_STATUS_WC=DEFERRED evidence=scope_tc_only
HOLD_STATUS_BC=DEFERRED evidence=scope_tc_only
RO_1GHZ_STRESS_STATUS=DEFERRED evidence=scope_tc_only
PHASE_LOAD_STATUS=DEFERRED evidence=not_run
RC_SYMMETRY_STATUS=DEFERRED evidence=not_run
BACKEND_CROSSING_STATUS=DEFERRED evidence=not_run
BACKEND_REGION_STATUS=DEFERRED evidence=not_run
PHASE_TO_PD_GEOMETRY_STATUS=DEFERRED evidence=not_run
EMPTY_SPACE_AUDIT_STATUS=DEFERRED evidence=not_run
DRV_STATUS=DEFERRED evidence=not_run
ANTENNA_STATUS=PROVISIONAL_WITH_LEF_ANTENNA_COMPLETENESS_REVIEW evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/antenna.rpt
DRC_STATUS=DEFERRED evidence=not_run
LVS_STATUS=DEFERRED evidence=not_run
DELIVERABLE_STATUS=DEFERRED evidence=not_run
MPTDC_TC_PHYSICAL_SIGNOFF=NO evidence=physical_verification_not_complete
TC_ONLY_TAPEOUT_EXCEPTION_READY=NO evidence=physical_verification_not_complete
DIGITAL_PNR_SIGNOFF=PROVISIONAL evidence=row_policy_pending_drc_lvs

## Area / Floorplan

### floorplan_status.rpt
FLOORPLAN_STATUS=REVIEW
STDCELL_SITE=core_jihd
TARGET_ASPECT_WIDTH_OVER_HEIGHT=1.333333
INNOVUS_FLOORPLAN_ASPECT_ARG=0.7500001875
CORE_UTILIZATION=0.55
REQUIRED_ASPECT_RATIO=4:3
CORE_BBOX=20.16 20.16 1041.04 781.76
CORE_WIDTH_UM=1020.880
CORE_HEIGHT_UM=761.600
CORE_AREA_UM2=777502.208
CORE_AREA_MM2=0.777502
CORE_ASPECT_WIDTH_OVER_HEIGHT=1.340441
ASPECT_ALLOWED_MIN=1.20
ASPECT_ALLOWED_MAX=1.47
FLOORPLAN_ASPECT_STATUS=PASS
REGION_fast_ro=50.4 120.4 219.345 190.9
REGION_fast_phase_buffers=50.4 211.12 350.4 231.12
REGION_pd_island=50.4 250.88 350.4 550.88
REGION_slow_phase_buffers=50.4 570.64 350.4 590.64
REGION_slow_ro=50.4 610.4 219.345 680.9
REGION_backend_east=390.32 50.16 1011.04 751.76
FLOORPLAN_STATUS=PASS

### area_status.rpt

### utilization.rpt

### placement_status.rpt
PLACEMENT_GATE_LABEL=post_place
PLACEMENT_STATUS=PASS
CHECKPLACE_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/check_place_post_place.rpt
CHECKPLACE_COMMAND_FAILED=0
CHECKPLACE_COMMAND_COMPLETE=1
CHECKPLACE_PARSER_COMPLETE=1
CHECKPLACE_INFERRED_ZERO_FIELDS=overlap region_fence not_of_fence
OVERLAPPING_WITH_OTHER_INSTANCE=0
REGION_FENCE_VIOLATIONS=0
NOT_OF_FENCE_VIOLATIONS=0
UNPLACED_CELLS=0
PLACED_CELLS=14200
FIXED_CELLS=34
DIRTY_PLACEMENT_ROUTE_ALLOWED=0
DIRTY_PLACEMENT_ROUTE_ENV=MPTDC_ALLOW_DIRTY_PLACEMENT_ROUTE

## CTS

### cts_policy.rpt
CTS_PRIMARY_CLOCK=clk_sys
RO_CLOCKS_IN_CTS=0
PHASE_CLOCKS_IN_CTS=0
CTS_BUFFERS=BUJIHDX1 BUJIHDX2 BUJIHDX3 BUJIHDX4 BUJIHDX6 BUJIHDX8 BUJIHDX12
CTS_INVERTERS=INJIHDX0 INJIHDX1 INJIHDX2 INJIHDX3 INJIHDX4 INJIHDX6 INJIHDX8 INJIHDX12
CLOCKDESIGN_FALLBACK=DISALLOWED
CLK_SYS_CTS_CONSTRAINT_CLEANUP_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/cts_clk_sys_constraint_cleanup.rpt
CLK_SYS_ROOT_PRE_CTS_AUDIT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/cts_clk_sys_root_pre_cts_policy.rpt
CLK_SYS_ROOT_PRE_CCOPT_AUDIT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/cts_clk_sys_root_pre_ccopt.rpt
CTS_SPEC_AUDIT_STATUS=PASS
CTS_SPEC_AUDIT_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/cts_clk_sys_spec_audit.rpt
CTS_SPEC_PATH=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/work/clk_sys_cts.spec
CTS_GENERIC_SPEC_PATH=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/work/clk_sys_cts.generic.spec
CTS_SPEC_ACCEPTED_COMMAND=create_ccopt_clock_tree_spec -file /sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/work/clk_sys_cts.generic.spec -views TC_NOMINAL
CTS_SPEC_SOURCE_STATUS=PASS
CTS_SPEC_SOURCE_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/cts_clk_sys_spec_source.rpt
CLK_SYS_ROOT_PRE_CCOPT_SELECTED_SPEC_AUDIT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/cts_clk_sys_root_pre_ccopt_selected_spec.rpt
CTS_SPEC_GATE_STATUS=PASS
CTS_SPEC_GATE_ACTION=strict_clk_sys_spec_accepted
CCOPT_COMMAND=ccopt_design
CCOPT_COMMAND_STATUS=PASS
CLK_SYS_ROOT_POST_CCOPT_AUDIT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/cts_clk_sys_root_post_ccopt.rpt
POST_CTS_SET_ANALYSIS_VIEW_STATUS=PASS
POST_CTS_OPT_STATUS=PASS
CLK_SYS_ROOT_POST_CTS_OPT_AUDIT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/cts_clk_sys_root_post_cts_opt.rpt
CTS_MEASURED_STATUS=PASS
CTS_MEASURED_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/cts_measured_status.rpt
CTS_STATUS=PASS
IMPCCOPT-4255=0
MAX_SKEW_NS_REQUIRED_LE=0.20
MAX_CLOCK_TRANSITION_NS_REQUIRED_LE=0.35
CTS_MEASURED_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/cts_measured_status.rpt

### cts_status.rpt

### clock_tree.rpt

### clock_timing.rpt

### timing_cts.rpt

## PG / SRoute / RO Hookup

### pg_physical_status.rpt
# MPTDC Physical PG Grid Status
POWER_NET=VDD
GROUND_NET=VSS
STDCELL_POWER_PINS=vddi
STDCELL_GROUND_PINS=gndi
RO_POWER_PIN_MAP=VDD->VDD vdd!->VDD VSS->VSS

COMMAND_ADD_RING=addRing -nets {VDD VSS} -type core_rings -follow core -layer {top MET3 bottom MET3 left METTP right METTP} -width {top 2 bottom 2 left 2 right 2} -spacing {top 1 bottom 1 left 1 right 1} -offset {top 2 bottom 2 left 2 right 2}
ADD_RING_STATUS=PASS

COMMAND_ADD_STRIPE_VERTICAL=addStripe -nets {VDD VSS} -layer METTP -direction vertical -width 2 -spacing 2 -set_to_set_distance 80 -start_from left -start_offset 20
ADD_STRIPE_VERTICAL_STATUS=PASS

COMMAND_ADD_STRIPE_HORIZONTAL=addStripe -nets {VDD VSS} -layer MET3 -direction horizontal -width 2 -spacing 2 -set_to_set_distance 80 -start_from bottom -start_offset 20
ADD_STRIPE_HORIZONTAL_STATUS=PASS
PREPLACE_PG_SROUTE_ENABLED=0
PRE_ROUTE_PG_SROUTE_MODE_STATUS=SKIPPED
PRE_ROUTE_PG_SROUTE_MODE_REASON=preplace_pg_sroute_disabled
SROUTE_STATUS=SKIPPED

RING_CREATED=1
VERTICAL_STRAP_CREATED=1
HORIZONTAL_STRAP_CREATED=1
BLOCK_PG_PIN_STATUS=PASS
BLOCK_PG_PIN_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/block_pg_pin_status.rpt
BLOCK_PG_STITCH_STATUS=PASS
BLOCK_PG_STITCH_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/block_pg_stitch_status.rpt
SROUTE_DONE=0
SROUTE_EFFECTIVE_STATUS=SKIPPED
SROUTE_EFFECTIVE_WIRES=0
SROUTE_EFFECTIVE_OPEN_PORTS=0
SROUTE_EFFECTIVE_REASON=preplace_pg_sroute_disabled
SROUTE_PREPLACE_PROGRESS_STATUS=PASS
RO_INSTANCE_COUNT=2
RO_VDD_CONNECTED_COUNT=UNKNOWN
RO_VDD_BANG_CONNECTED_COUNT=UNKNOWN
RO_VSS_CONNECTED_COUNT=UNKNOWN
RO_PG_PIN_QUERY_STATUS=FAIL
SPECIAL_CONNECTIVITY_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_verify_connectivity_special.rpt
SPECIAL_CONNECTIVITY_CAPTURE_STATUS=PASS
SPECIAL_CONNECTIVITY_COMMAND=verifyConnectivity -type special -nets {VDD VSS}
ALL_CONNECTIVITY_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_verify_connectivity_all.rpt
SPECIAL_NET_OPENS=PARSED_FROM_VERIFY_CONNECTIVITY
SPECIAL_NET_SHORTS=PARSED_FROM_VERIFY_CONNECTIVITY
UNCONNECTED_STDCELL_PG_PINS=PARSED_FROM_VERIFY_CONNECTIVITY
UNCONNECTED_RO_PG_PINS=PARSED_FROM_VERIFY_CONNECTIVITY
SPECIAL_CONNECTIVITY_BAD=1
SPECIAL_CONNECTIVITY_BAD_LINES={Net VDD: has an unconnected terminal, has special routes with opens, dangling Wire.} {Net VSS: has an unconnected terminal, has special routes with opens, dangling Wire.} {8 Problem(s) (IMPVFC-96): Terminal(s) are not connected.} {2 Problem(s) (IMPVFC-200): Special Wires: Pieces of the net are not connected together.} {20 Problem(s) (IMPVFC-94): The net has dangling wire(s).} {Verification Complete : 30 Viols.  0 Wrngs.}
ALL_CONNECTIVITY_BAD=1
ALL_CONNECTIVITY_BAD_LINES={Net VDD: has an unconnected terminal, has special routes with opens, dangling Wire.} {Net VSS: has an unconnected terminal, has special routes with opens, dangling Wire.} {8 Problem(s) (IMPVFC-96): Terminal(s) are not connected.} {2 Problem(s) (IMPVFC-200): Special Wires: Pieces of the net are not connected together.} {20 Problem(s) (IMPVFC-94): The net has dangling wire(s).} {Verification Complete : 30 Viols.  0 Wrngs.}
PREPLACE_PRIMITIVE_PG_STATUS=PASS
PG_PHYSICAL_STATUS=PROVISIONAL
PG_PHYSICAL_PROVISIONAL_REASON=pre_place_verify_connectivity_requires_placed_cells; route_stage_rechecks_regular_and_special_connectivity; sroute_open_ports_deferred_to_route_stage; ro_pg_pin_query_deferred_to_route_connectivity_recheck
MPTDC_ALLOW_PROVISIONAL_PREPLACE_PG=1
FINAL_CONNECTIVITY_RECHECK=route_status.rpt

### postplace_pre_route_sroute_status.rpt
# MPTDC Post-placement Pre-route SRoute Status
POSTPLACE_PRE_ROUTE_SROUTE_ENABLED=1
POSTPLACE_PRE_ROUTE_SROUTE_REQUIRE_CLEAN=0
POSTPLACE_PRE_ROUTE_SROUTE_CANDIDATE_PROBE=0
POSTPLACE_PRE_ROUTE_SROUTE_BLOCKPIN=0
POSTPLACE_PRE_ROUTE_SROUTE_CORE_PIN_STOP_ROUTE=RowEnd
POSTPLACE_PRE_ROUTE_PG_OBJECT_DUMP_BEFORE_STITCH=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_stitch.rpt
POSTPLACE_PRE_ROUTE_BLOCK_PG_STITCH_STATUS=PASS
POSTPLACE_PRE_ROUTE_BLOCK_PG_STITCH_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_block_pg_stitch_status.rpt
POSTPLACE_PRE_ROUTE_PG_OBJECT_DUMP_BEFORE=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_sroute.rpt
POSTPLACE_PRE_ROUTE_PG_TOPOLOGY_BEFORE=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_before_sroute.rpt
POSTPLACE_PRE_ROUTE_RO_PG_PROBE_BEFORE=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt
POSTPLACE_PRE_ROUTE_RO_PG_HOOKUP_STATUS=PASS_OR_SKIPPED
POSTPLACE_PRE_ROUTE_RO_PG_HOOKUP_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt
POSTPLACE_PRE_ROUTE_RO_PG_PROBE_AFTER=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt
POSTPLACE_PRE_ROUTE_PG_TOPOLOGY_AFTER_RO_PG_HOOKUP=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_ro_pg_hookup.rpt
POSTPLACE_PRE_ROUTE_SROUTE_MODE_CORE_PIN_STOP_ROUTE_COMMAND=setSrouteMode -corePinStopRoute RowEnd
POSTPLACE_PRE_ROUTE_SROUTE_MODE_CORE_PIN_STOP_ROUTE_STATUS=PASS
POSTPLACE_PRE_ROUTE_SROUTE_MODE_EXPERIMENTS_ENABLED=0
POSTPLACE_PRE_ROUTE_SROUTE_MODE_STATUS=PASS
POSTPLACE_PRE_ROUTE_SROUTE_MODE_REASON=deterministic_core_pin_stop_only
POSTPLACE_PRE_ROUTE_SROUTE_PADPIN_FALLBACK_ENABLED=0

COMMAND_POSTPLACE_PRE_ROUTE_SROUTE=sroute -connect corePin -nets {VDD VSS} -corePinTarget {ring stripe} -allowLayerChange 1
POSTPLACE_PRE_ROUTE_SROUTE_ATTEMPT_1_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/POSTPLACE_PRE_ROUTE_SROUTE_sroute_1.rpt
POSTPLACE_PRE_ROUTE_SROUTE_ATTEMPT_1_COMMAND_STATUS=PASS
POSTPLACE_PRE_ROUTE_SROUTE_ATTEMPT_1_STATUS=REVIEW_REQUIRED
POSTPLACE_PRE_ROUTE_SROUTE_ATTEMPT_1_WIRES=813
POSTPLACE_PRE_ROUTE_SROUTE_ATTEMPT_1_OPEN_PORTS=24
POSTPLACE_PRE_ROUTE_SROUTE_ATTEMPT_1_BLOCK_OPEN_PORTS=0
POSTPLACE_PRE_ROUTE_SROUTE_ATTEMPT_1_CORE_OPEN_PORTS=24
POSTPLACE_PRE_ROUTE_SROUTE_ATTEMPT_1_POWER_BUMP_OPEN_PORTS=0
POSTPLACE_PRE_ROUTE_SROUTE_ATTEMPT_1_REASON=open_ports_nonzero
POSTPLACE_PRE_ROUTE_SROUTE_STATUS=FAIL
POSTPLACE_PRE_ROUTE_PG_OBJECT_DUMP_AFTER=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_after_sroute.rpt
POSTPLACE_PRE_ROUTE_PG_TOPOLOGY_AFTER=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_sroute.rpt
POSTPLACE_PRE_ROUTE_SROUTE_COMMAND_STATUS=FAIL
POSTPLACE_PRE_ROUTE_SROUTE_EFFECTIVE_STATUS=REVIEW_REQUIRED
POSTPLACE_PRE_ROUTE_SROUTE_EFFECTIVE_WIRES=813
POSTPLACE_PRE_ROUTE_SROUTE_EFFECTIVE_OPEN_PORTS=24
POSTPLACE_PRE_ROUTE_SROUTE_EFFECTIVE_BLOCK_OPEN_PORTS=0
POSTPLACE_PRE_ROUTE_SROUTE_EFFECTIVE_CORE_OPEN_PORTS=24
POSTPLACE_PRE_ROUTE_SROUTE_EFFECTIVE_POWER_BUMP_OPEN_PORTS=0
POSTPLACE_PRE_ROUTE_SROUTE_EFFECTIVE_REASON=open_ports_nonzero
POSTPLACE_PRE_ROUTE_SROUTE_EFFECTIVE_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/POSTPLACE_PRE_ROUTE_SROUTE_sroute_1.rpt
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_verify_connectivity_special.rpt
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_CAPTURE_STATUS=PASS
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_COMMAND=verifyConnectivity -type special -nets {VDD VSS}
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_BAD=1
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_BAD_LINES={Net VDD: has an unconnected terminal, has special routes with opens, dangling Wire.} {Net VSS: has an unconnected terminal, has special routes with opens, dangling Wire.} {8 Problem(s) (IMPVFC-96): Terminal(s) are not connected.} {2 Problem(s) (IMPVFC-200): Special Wires: Pieces of the net are not connected together.} {32 Problem(s) (IMPVFC-94): The net has dangling wire(s).} {Verification Complete : 42 Viols.  0 Wrngs.}
POSTPLACE_PRE_ROUTE_SROUTE_STATUS_BEFORE_VERIFY=REVIEW_REQUIRED
POSTPLACE_PRE_ROUTE_SROUTE_VERIFY_CLEAN_OVERRIDE=0
POSTPLACE_PRE_ROUTE_SROUTE_PROGRESS_STATUS=PASS
POSTPLACE_PRE_ROUTE_SROUTE_STATUS=REVIEW_REQUIRED
POSTPLACE_PRE_ROUTE_SROUTE_FINAL_GATE=route_status.rpt
POSTPLACE_PRE_ROUTE_SROUTE_GATE_ACTION=CONTINUE_FOR_ROUTE_GATE

### ro_pg_hookup_status.rpt
# MPTDC RO PG Hookup Status
RO_PG_HOOKUP_ENABLE=1
RO_PG_HOOKUP_REQUIRED=1
RO_PG_HOOKUP_SEARCH_UM=45.0
RO_PG_HOOKUP_MARGIN_UM=1.0
RO_PG_HOOKUP_SPACING_UM=2.0
RO_PG_HOOKUP_SET_DISTANCE_UM=5000.0
RO_PG_PIN_SHAPE_COUNT=28
RO_PG_PIN_SHAPE_SOURCES=lef_orientation_fallback:MX=14 lef_orientation_fallback:R0=14

RO_PG_1_VDD_MET1_INST=u_core_u_osc_fast_u_ro_tune4
RO_PG_1_VDD_MET1_PIN=VDD
RO_PG_1_VDD_MET1_NET=VDD
RO_PG_1_VDD_MET1_PIN_LAYER=MET1
RO_PG_1_VDD_MET1_PIN_BOX=52.43 170.71 57.575 173.945
RO_PG_1_VDD_MET1_TARGET_STATUS=PASS
RO_PG_1_VDD_MET1_TARGET_SHAPE=stripe
RO_PG_1_VDD_MET1_TARGET_LAYER=METTP
RO_PG_1_VDD_MET1_TARGET_DISTANCE_UM=10.270
RO_PG_1_VDD_MET1_TARGET_BOX=40.16 16.16 42.16 785.76
RO_PG_1_VDD_MET1_BRIDGE_DIRECTION=vertical
RO_PG_1_VDD_MET1_BRIDGE_AREA=39.160 15.160 58.575 786.760
RO_PG_1_VDD_MET1_BRIDGE_COORD=55.002
RO_PG_1_VDD_MET1_BRIDGE_WIDTH=0.8

COMMAND_RO_PG_1_VDD_MET1_PIN_LAYER=addStripe -nets VDD -layer MET1 -direction vertical -width 0.8 -spacing 2.0 -set_to_set_distance 5000.0 -start_from left -start_offset 55.002 -number_of_sets 1 -area {39.160 15.160 58.575 786.760}
RO_PG_1_VDD_MET1_PIN_LAYER_STATUS=PASS
RO_PG_1_VDD_MET1_TARGET_BRIDGE_COORD=55.002
RO_PG_1_VDD_MET1_TARGET_BRIDGE_WIDTH=2.0

COMMAND_RO_PG_1_VDD_MET1_TARGET_LAYER=addStripe -nets VDD -layer METTP -direction vertical -width 2.0 -spacing 2.0 -set_to_set_distance 5000.0 -start_from left -start_offset 55.002 -number_of_sets 1 -area {39.160 15.160 58.575 786.760}
RO_PG_1_VDD_MET1_TARGET_LAYER_STATUS=PASS

RO_PG_2_VSS_MET1_INST=u_core_u_osc_fast_u_ro_tune4
RO_PG_2_VSS_MET1_PIN=VSS
RO_PG_2_VSS_MET1_NET=VSS
RO_PG_2_VSS_MET1_PIN_LAYER=MET1
RO_PG_2_VSS_MET1_PIN_BOX=50.405 148.035 52.085 155.7
RO_PG_2_VSS_MET1_TARGET_STATUS=PASS
RO_PG_2_VSS_MET1_TARGET_SHAPE=stripe
RO_PG_2_VSS_MET1_TARGET_LAYER=METTP
RO_PG_2_VSS_MET1_TARGET_DISTANCE_UM=4.245
RO_PG_2_VSS_MET1_TARGET_BOX=44.16 13.16 46.16 788.76
RO_PG_2_VSS_MET1_BRIDGE_DIRECTION=vertical
RO_PG_2_VSS_MET1_BRIDGE_AREA=43.160 12.160 53.085 789.760
RO_PG_2_VSS_MET1_BRIDGE_COORD=51.245
RO_PG_2_VSS_MET1_BRIDGE_WIDTH=0.8

COMMAND_RO_PG_2_VSS_MET1_PIN_LAYER=addStripe -nets VSS -layer MET1 -direction vertical -width 0.8 -spacing 2.0 -set_to_set_distance 5000.0 -start_from left -start_offset 51.245 -number_of_sets 1 -area {43.160 12.160 53.085 789.760}
RO_PG_2_VSS_MET1_PIN_LAYER_STATUS=PASS
RO_PG_2_VSS_MET1_TARGET_BRIDGE_COORD=51.245
RO_PG_2_VSS_MET1_TARGET_BRIDGE_WIDTH=2.0

COMMAND_RO_PG_2_VSS_MET1_TARGET_LAYER=addStripe -nets VSS -layer METTP -direction vertical -width 2.0 -spacing 2.0 -set_to_set_distance 5000.0 -start_from left -start_offset 51.245 -number_of_sets 1 -area {43.160 12.160 53.085 789.760}
RO_PG_2_VSS_MET1_TARGET_LAYER_STATUS=PASS

RO_PG_3_vdd__MET2_INST=u_core_u_osc_fast_u_ro_tune4
RO_PG_3_vdd__MET2_PIN=vdd!
RO_PG_3_vdd__MET2_NET=VDD
RO_PG_3_vdd__MET2_PIN_LAYER=MET2
RO_PG_3_vdd__MET2_PIN_BOX=144.88 161.845 146.88 175.64
RO_PG_3_vdd__MET2_TARGET_STATUS=PASS
RO_PG_3_vdd__MET2_TARGET_SHAPE=stripe
RO_PG_3_vdd__MET2_TARGET_LAYER=MET3
RO_PG_3_vdd__MET2_TARGET_DISTANCE_UM=24.520
RO_PG_3_vdd__MET2_TARGET_BOX=16.16 200.16 1045.04 202.16
RO_PG_3_vdd__MET2_BRIDGE_DIRECTION=horizontal
RO_PG_3_vdd__MET2_BRIDGE_AREA=15.160 160.845 1046.040 203.160
RO_PG_3_vdd__MET2_BRIDGE_COORD=168.743
RO_PG_3_vdd__MET2_BRIDGE_WIDTH=0.8

COMMAND_RO_PG_3_vdd__MET2_PIN_LAYER=addStripe -nets VDD -layer MET2 -direction horizontal -width 0.8 -spacing 2.0 -set_to_set_distance 5000.0 -start_from bottom -start_offset 168.743 -number_of_sets 1 -area {15.160 160.845 1046.040 203.160}
RO_PG_3_vdd__MET2_PIN_LAYER_STATUS=PASS
RO_PG_3_vdd__MET2_TARGET_BRIDGE_COORD=168.743
RO_PG_3_vdd__MET2_TARGET_BRIDGE_WIDTH=2.0

COMMAND_RO_PG_3_vdd__MET2_TARGET_LAYER=addStripe -nets VDD -layer MET3 -direction horizontal -width 2.0 -spacing 2.0 -set_to_set_distance 5000.0 -start_from bottom -start_offset 168.743 -number_of_sets 1 -area {15.160 160.845 1046.040 203.160}
RO_PG_3_vdd__MET2_TARGET_LAYER_STATUS=PASS

RO_PG_4_vdd__MET2_INST=u_core_u_osc_fast_u_ro_tune4
RO_PG_4_vdd__MET2_PIN=vdd!
RO_PG_4_vdd__MET2_NET=VDD
RO_PG_4_vdd__MET2_PIN_LAYER=MET2
RO_PG_4_vdd__MET2_PIN_BOX=140.13 162.4 146.88 163.2
RO_PG_4_vdd__MET2_TARGET_STATUS=PASS
RO_PG_4_vdd__MET2_TARGET_SHAPE=stripe
RO_PG_4_vdd__MET2_TARGET_LAYER=METTP
RO_PG_4_vdd__MET2_TARGET_DISTANCE_UM=35.056
RO_PG_4_vdd__MET2_TARGET_BOX=120.16 193.3 122.16 608.0
RO_PG_4_vdd__MET2_BRIDGE_DIRECTION=vertical
RO_PG_4_vdd__MET2_BRIDGE_AREA=119.160 161.400 147.880 609.000
RO_PG_4_vdd__MET2_BRIDGE_COORD=143.505
RO_PG_4_vdd__MET2_BRIDGE_WIDTH=0.8

COMMAND_RO_PG_4_vdd__MET2_PIN_LAYER=addStripe -nets VDD -layer MET2 -direction vertical -width 0.8 -spacing 2.0 -set_to_set_distance 5000.0 -start_from left -start_offset 143.505 -number_of_sets 1 -area {119.160 161.400 147.880 609.000}
RO_PG_4_vdd__MET2_PIN_LAYER_STATUS=PASS
RO_PG_4_vdd__MET2_TARGET_BRIDGE_COORD=143.505
RO_PG_4_vdd__MET2_TARGET_BRIDGE_WIDTH=2.0

COMMAND_RO_PG_4_vdd__MET2_TARGET_LAYER=addStripe -nets VDD -layer METTP -direction vertical -width 2.0 -spacing 2.0 -set_to_set_distance 5000.0 -start_from left -start_offset 143.505 -number_of_sets 1 -area {119.160 161.400 147.880 609.000}
RO_PG_4_vdd__MET2_TARGET_LAYER_STATUS=PASS

RO_PG_5_vdd__MET2_INST=u_core_u_osc_fast_u_ro_tune4
RO_PG_5_vdd__MET2_PIN=vdd!
RO_PG_5_vdd__MET2_NET=VDD
RO_PG_5_vdd__MET2_PIN_LAYER=MET2
RO_PG_5_vdd__MET2_PIN_BOX=140.13 156.565 140.93 163.2
RO_PG_5_vdd__MET2_TARGET_STATUS=PASS
RO_PG_5_vdd__MET2_TARGET_SHAPE=stripe
RO_PG_5_vdd__MET2_TARGET_LAYER=METTP
RO_PG_5_vdd__MET2_TARGET_DISTANCE_UM=35.056
RO_PG_5_vdd__MET2_TARGET_BOX=120.16 193.3 122.16 608.0
RO_PG_5_vdd__MET2_BRIDGE_DIRECTION=vertical
RO_PG_5_vdd__MET2_BRIDGE_AREA=119.160 155.565 141.930 609.000
RO_PG_5_vdd__MET2_BRIDGE_COORD=140.530
RO_PG_5_vdd__MET2_BRIDGE_WIDTH=0.8

COMMAND_RO_PG_5_vdd__MET2_PIN_LAYER=addStripe -nets VDD -layer MET2 -direction vertical -width 0.8 -spacing 2.0 -set_to_set_distance 5000.0 -start_from left -start_offset 140.530 -number_of_sets 1 -area {119.160 155.565 141.930 609.000}
RO_PG_5_vdd__MET2_PIN_LAYER_STATUS=PASS
RO_PG_5_vdd__MET2_TARGET_BRIDGE_COORD=140.530
RO_PG_5_vdd__MET2_TARGET_BRIDGE_WIDTH=2.0

COMMAND_RO_PG_5_vdd__MET2_TARGET_LAYER=addStripe -nets VDD -layer METTP -direction vertical -width 2.0 -spacing 2.0 -set_to_set_distance 5000.0 -start_from left -start_offset 140.530 -number_of_sets 1 -area {119.160 155.565 141.930 609.000}
RO_PG_5_vdd__MET2_TARGET_LAYER_STATUS=PASS

RO_PG_6_vdd__MET2_INST=u_core_u_osc_fast_u_ro_tune4
RO_PG_6_vdd__MET2_PIN=vdd!
RO_PG_6_vdd__MET2_NET=VDD
RO_PG_6_vdd__MET2_PIN_LAYER=MET2
RO_PG_6_vdd__MET2_PIN_BOX=111.6 174.175 113.6 183.345
RO_PG_6_vdd__MET2_TARGET_STATUS=PASS
RO_PG_6_vdd__MET2_TARGET_SHAPE=stripe
RO_PG_6_vdd__MET2_TARGET_LAYER=METTP
RO_PG_6_vdd__MET2_TARGET_DISTANCE_UM=11.922
RO_PG_6_vdd__MET2_TARGET_BOX=120.16 193.3 122.16 608.0
RO_PG_6_vdd__MET2_BRIDGE_DIRECTION=vertical
RO_PG_6_vdd__MET2_BRIDGE_AREA=110.600 173.175 123.160 609.000
RO_PG_6_vdd__MET2_BRIDGE_COORD=112.600
RO_PG_6_vdd__MET2_BRIDGE_WIDTH=0.8

COMMAND_RO_PG_6_vdd__MET2_PIN_LAYER=addStripe -nets VDD -layer MET2 -direction vertical -width 0.8 -spacing 2.0 -set_to_set_distance 5000.0 -start_from left -start_offset 112.600 -number_of_sets 1 -area {110.600 173.175 123.160 609.000}
RO_PG_6_vdd__MET2_PIN_LAYER_STATUS=PASS
RO_PG_6_vdd__MET2_TARGET_BRIDGE_COORD=112.600
RO_PG_6_vdd__MET2_TARGET_BRIDGE_WIDTH=2.0

COMMAND_RO_PG_6_vdd__MET2_TARGET_LAYER=addStripe -nets VDD -layer METTP -direction vertical -width 2.0 -spacing 2.0 -set_to_set_distance 5000.0 -start_from left -start_offset 112.600 -number_of_sets 1 -area {110.600 173.175 123.160 609.000}
RO_PG_6_vdd__MET2_TARGET_LAYER_STATUS=PASS

RO_PG_7_vdd__MET1_INST=u_core_u_osc_fast_u_ro_tune4
RO_PG_7_vdd__MET1_PIN=vdd!
RO_PG_7_vdd__MET1_NET=VDD
RO_PG_7_vdd__MET1_PIN_LAYER=MET1
RO_PG_7_vdd__MET1_PIN_BOX=144.905 164.17 148.595 166.17
RO_PG_7_vdd__MET1_TARGET_STATUS=PASS
RO_PG_7_vdd__MET1_TARGET_SHAPE=stripe
RO_PG_7_vdd__MET1_TARGET_LAYER=MET3
RO_PG_7_vdd__MET1_TARGET_DISTANCE_UM=33.990
RO_PG_7_vdd__MET1_TARGET_BOX=16.16 200.16 1045.04 202.16
RO_PG_7_vdd__MET1_BRIDGE_DIRECTION=horizontal
RO_PG_7_vdd__MET1_BRIDGE_AREA=15.160 163.170 1046.040 203.160
RO_PG_7_vdd__MET1_BRIDGE_COORD=165.170
RO_PG_7_vdd__MET1_BRIDGE_WIDTH=0.8

COMMAND_RO_PG_7_vdd__MET1_PIN_LAYER=addStripe -nets VDD -layer MET1 -direction horizontal -width 0.8 -spacing 2.0 -set_to_set_distance 5000.0 -start_from bottom -start_offset 165.170 -number_of_sets 1 -area {15.160 163.170 1046.040 203.160}
RO_PG_7_vdd__MET1_PIN_LAYER_STATUS=PASS
RO_PG_7_vdd__MET1_TARGET_BRIDGE_COORD=165.170
RO_PG_7_vdd__MET1_TARGET_BRIDGE_WIDTH=2.0

COMMAND_RO_PG_7_vdd__MET1_TARGET_LAYER=addStripe -nets VDD -layer MET3 -direction horizontal -width 2.0 -spacing 2.0 -set_to_set_distance 5000.0 -start_from bottom -start_offset 165.170 -number_of_sets 1 -area {15.160 163.170 1046.040 203.160}
RO_PG_7_vdd__MET1_TARGET_LAYER_STATUS=PASS

RO_PG_8_vdd__MET1_INST=u_core_u_osc_fast_u_ro_tune4
RO_PG_8_vdd__MET1_PIN=vdd!
RO_PG_8_vdd__MET1_NET=VDD
RO_PG_8_vdd__MET1_PIN_LAYER=MET1
RO_PG_8_vdd__MET1_PIN_BOX=111.495 173.595 147.295 175.595
RO_PG_8_vdd__MET1_TARGET_STATUS=PASS
RO_PG_8_vdd__MET1_TARGET_SHAPE=stripe
RO_PG_8_vdd__MET1_TARGET_LAYER=METTP
RO_PG_8_vdd__MET1_TARGET_DISTANCE_UM=17.705
RO_PG_8_vdd__MET1_TARGET_BOX=120.16 193.3 122.16 608.0
RO_PG_8_vdd__MET1_BRIDGE_DIRECTION=vertical
RO_PG_8_vdd__MET1_BRIDGE_AREA=110.495 172.595 148.295 609.000
RO_PG_8_vdd__MET1_BRIDGE_COORD=129.395
RO_PG_8_vdd__MET1_BRIDGE_WIDTH=0.8

COMMAND_RO_PG_8_vdd__MET1_PIN_LAYER=addStripe -nets VDD -layer MET1 -direction vertical -width 0.8 -spacing 2.0 -set_to_set_distance 5000.0 -start_from left -start_offset 129.395 -number_of_sets 1 -area {110.495 172.595 148.295 609.000}
RO_PG_8_vdd__MET1_PIN_LAYER_STATUS=PASS
RO_PG_8_vdd__MET1_TARGET_BRIDGE_COORD=129.395
RO_PG_8_vdd__MET1_TARGET_BRIDGE_WIDTH=2.0

COMMAND_RO_PG_8_vdd__MET1_TARGET_LAYER=addStripe -nets VDD -layer METTP -direction vertical -width 2.0 -spacing 2.0 -set_to_set_distance 5000.0 -start_from left -start_offset 129.395 -number_of_sets 1 -area {110.495 172.595 148.295 609.000}
RO_PG_8_vdd__MET1_TARGET_LAYER_STATUS=PASS

RO_PG_9_vdd__MET1_INST=u_core_u_osc_fast_u_ro_tune4
RO_PG_9_vdd__MET1_PIN=vdd!
RO_PG_9_vdd__MET1_NET=VDD
RO_PG_9_vdd__MET1_PIN_LAYER=MET1
RO_PG_9_vdd__MET1_PIN_BOX=111.48 181.545 124.045 183.185
RO_PG_9_vdd__MET1_TARGET_STATUS=PASS
RO_PG_9_vdd__MET1_TARGET_SHAPE=stripe
RO_PG_9_vdd__MET1_TARGET_LAYER=METTP
RO_PG_9_vdd__MET1_TARGET_DISTANCE_UM=10.115
RO_PG_9_vdd__MET1_TARGET_BOX=120.16 193.3 122.16 608.0
RO_PG_9_vdd__MET1_BRIDGE_DIRECTION=vertical
RO_PG_9_vdd__MET1_BRIDGE_AREA=110.480 180.545 125.045 609.000
RO_PG_9_vdd__MET1_BRIDGE_COORD=117.763
RO_PG_9_vdd__MET1_BRIDGE_WIDTH=0.8

COMMAND_RO_PG_9_vdd__MET1_PIN_LAYER=addStripe -nets VDD -layer MET1 -direction vertical -width 0.8 -spacing 2.0 -set_to_set_distance 5000.0 -start_from left -start_offset 117.763 -number_of_sets 1 -area {110.480 180.545 125.045 609.000}
RO_PG_9_vdd__MET1_PIN_LAYER_STATUS=PASS
RO_PG_9_vdd__MET1_TARGET_BRIDGE_COORD=117.763
RO_PG_9_vdd__MET1_TARGET_BRIDGE_WIDTH=2.0

COMMAND_RO_PG_9_vdd__MET1_TARGET_LAYER=addStripe -nets VDD -layer METTP -direction vertical -width 2.0 -spacing 2.0 -set_to_set_distance 5000.0 -start_from left -start_offset 117.763 -number_of_sets 1 -area {110.480 180.545 125.045 609.000}
RO_PG_9_vdd__MET1_TARGET_LAYER_STATUS=PASS

RO_PG_10_vdd__MET2_INST=u_core_u_osc_fast_u_ro_tune4
RO_PG_10_vdd__MET2_PIN=vdd!
RO_PG_10_vdd__MET2_NET=VDD
RO_PG_10_vdd__MET2_PIN_LAYER=MET2
RO_PG_10_vdd__MET2_PIN_BOX=176.8 161.845 178.8 174.87
RO_PG_10_vdd__MET2_TARGET_STATUS=PASS
RO_PG_10_vdd__MET2_TARGET_SHAPE=stripe
RO_PG_10_vdd__MET2_TARGET_LAYER=MET3
RO_PG_10_vdd__MET2_TARGET_DISTANCE_UM=25.290
RO_PG_10_vdd__MET2_TARGET_BOX=16.16 200.16 1045.04 202.16
RO_PG_10_vdd__MET2_BRIDGE_DIRECTION=horizontal
RO_PG_10_vdd__MET2_BRIDGE_AREA=15.160 160.845 1046.040 203.160
RO_PG_10_vdd__MET2_BRIDGE_COORD=168.358
RO_PG_10_vdd__MET2_BRIDGE_WIDTH=0.8

COMMAND_RO_PG_10_vdd__MET2_PIN_LAYER=addStripe -nets VDD -layer MET2 -direction horizontal -width 0.8 -spacing 2.0 -set_to_set_distance 5000.0 -start_from bottom -start_offset 168.358 -number_of_sets 1 -area {15.160 160.845 1046.040 203.160}
RO_PG_10_vdd__MET2_PIN_LAYER_STATUS=PASS
RO_PG_10_vdd__MET2_TARGET_BRIDGE_COORD=168.358
RO_PG_10_vdd__MET2_TARGET_BRIDGE_WIDTH=2.0

COMMAND_RO_PG_10_vdd__MET2_TARGET_LAYER=addStripe -nets VDD -layer MET3 -direction horizontal -width 2.0 -spacing 2.0 -set_to_set_distance 5000.0 -start_from bottom -start_offset 168.358 -number_of_sets 1 -area {15.160 160.845 1046.040 203.160}
RO_PG_10_vdd__MET2_TARGET_LAYER_STATUS=PASS

RO_PG_11_vdd__MET1_INST=u_core_u_osc_fast_u_ro_tune4
RO_PG_11_vdd__MET1_PIN=vdd!
RO_PG_11_vdd__MET1_NET=VDD
RO_PG_11_vdd__MET1_PIN_LAYER=MET1
RO_PG_11_vdd__MET1_PIN_BOX=137.975 180.4 199.87 180.74
RO_PG_11_vdd__MET1_TARGET_STATUS=PASS
RO_PG_11_vdd__MET1_TARGET_SHAPE=stripe
RO_PG_11_vdd__MET1_TARGET_LAYER=METTP
RO_PG_11_vdd__MET1_TARGET_DISTANCE_UM=12.563
RO_PG_11_vdd__MET1_TARGET_BOX=200.16 193.3 202.16 608.0
RO_PG_11_vdd__MET1_BRIDGE_DIRECTION=vertical
RO_PG_11_vdd__MET1_BRIDGE_AREA=136.975 179.400 203.160 609.000
RO_PG_11_vdd__MET1_BRIDGE_COORD=168.923
RO_PG_11_vdd__MET1_BRIDGE_WIDTH=0.8

COMMAND_RO_PG_11_vdd__MET1_PIN_LAYER=addStripe -nets VDD -layer MET1 -direction vertical -width 0.8 -spacing 2.0 -set_to_set_distance 5000.0 -start_from left -start_offset 168.923 -number_of_sets 1 -area {136.975 179.400 203.160 609.000}
RO_PG_11_vdd__MET1_PIN_LAYER_STATUS=PASS
RO_PG_11_vdd__MET1_TARGET_BRIDGE_COORD=168.923
RO_PG_11_vdd__MET1_TARGET_BRIDGE_WIDTH=2.0

COMMAND_RO_PG_11_vdd__MET1_TARGET_LAYER=addStripe -nets VDD -layer METTP -direction vertical -width 2.0 -spacing 2.0 -set_to_set_distance 5000.0 -start_from left -start_offset 168.923 -number_of_sets 1 -area {136.975 179.400 203.160 609.000}
RO_PG_11_vdd__MET1_TARGET_LAYER_STATUS=PASS

RO_PG_12_vdd__MET1_INST=u_core_u_osc_fast_u_ro_tune4
RO_PG_12_vdd__MET1_PIN=vdd!
RO_PG_12_vdd__MET1_NET=VDD
RO_PG_12_vdd__MET1_PIN_LAYER=MET1
RO_PG_12_vdd__MET1_PIN_BOX=176.38 172.735 197.18 174.735
RO_PG_12_vdd__MET1_TARGET_STATUS=PASS
RO_PG_12_vdd__MET1_TARGET_SHAPE=stripe
RO_PG_12_vdd__MET1_TARGET_LAYER=METTP
RO_PG_12_vdd__MET1_TARGET_DISTANCE_UM=18.803
RO_PG_12_vdd__MET1_TARGET_BOX=200.16 193.3 202.16 608.0
RO_PG_12_vdd__MET1_BRIDGE_DIRECTION=vertical
RO_PG_12_vdd__MET1_BRIDGE_AREA=175.380 171.735 203.160 609.000
RO_PG_12_vdd__MET1_BRIDGE_COORD=186.780
RO_PG_12_vdd__MET1_BRIDGE_WIDTH=0.8

COMMAND_RO_PG_12_vdd__MET1_PIN_LAYER=addStripe -nets VDD -layer MET1 -direction vertical -width 0.8 -spacing 2.0 -set_to_set_distance 5000.0 -start_from left -start_offset 186.780 -number_of_sets 1 -area {175.380 171.735 203.160 609.000}
RO_PG_12_vdd__MET1_PIN_LAYER_STATUS=PASS
RO_PG_12_vdd__MET1_TARGET_BRIDGE_COORD=186.780
RO_PG_12_vdd__MET1_TARGET_BRIDGE_WIDTH=2.0

COMMAND_RO_PG_12_vdd__MET1_TARGET_LAYER=addStripe -nets VDD -layer METTP -direction vertical -width 2.0 -spacing 2.0 -set_to_set_distance 5000.0 -start_from left -start_offset 186.780 -number_of_sets 1 -area {175.380 171.735 203.160 609.000}
RO_PG_12_vdd__MET1_TARGET_LAYER_STATUS=PASS

RO_PG_13_vdd__MET1_INST=u_core_u_osc_fast_u_ro_tune4
RO_PG_13_vdd__MET1_PIN=vdd!
RO_PG_13_vdd__MET1_NET=VDD
RO_PG_13_vdd__MET1_PIN_LAYER=MET1
RO_PG_13_vdd__MET1_PIN_BOX=189.255 172.735 191.255 181.65
RO_PG_13_vdd__MET1_TARGET_STATUS=PASS
RO_PG_13_vdd__MET1_TARGET_SHAPE=stripe
RO_PG_13_vdd__MET1_TARGET_LAYER=METTP
RO_PG_13_vdd__MET1_TARGET_DISTANCE_UM=14.664
RO_PG_13_vdd__MET1_TARGET_BOX=200.16 193.3 202.16 608.0
RO_PG_13_vdd__MET1_BRIDGE_DIRECTION=vertical
RO_PG_13_vdd__MET1_BRIDGE_AREA=188.255 171.735 203.160 609.000
RO_PG_13_vdd__MET1_BRIDGE_COORD=190.255
RO_PG_13_vdd__MET1_BRIDGE_WIDTH=0.8

COMMAND_RO_PG_13_vdd__MET1_PIN_LAYER=addStripe -nets VDD -layer MET1 -direction vertical -width 0.8 -spacing 2.0 -set_to_set_distance 5000.0 -start_from left -start_offset 190.255 -number_of_sets 1 -area {188.255 171.735 203.160 609.000}
RO_PG_13_vdd__MET1_PIN_LAYER_STATUS=PASS
RO_PG_13_vdd__MET1_TARGET_BRIDGE_COORD=190.255
RO_PG_13_vdd__MET1_TARGET_BRIDGE_WIDTH=2.0

COMMAND_RO_PG_13_vdd__MET1_TARGET_LAYER=addStripe -nets VDD -layer METTP -direction vertical -width 2.0 -spacing 2.0 -set_to_set_distance 5000.0 -start_from left -start_offset 190.255 -number_of_sets 1 -area {188.255 171.735 203.160 609.000}
RO_PG_13_vdd__MET1_TARGET_LAYER_STATUS=PASS

RO_PG_14_vdd__MET1_INST=u_core_u_osc_fast_u_ro_tune4
RO_PG_14_vdd__MET1_PIN=vdd!
RO_PG_14_vdd__MET1_NET=VDD
RO_PG_14_vdd__MET1_PIN_LAYER=MET1
RO_PG_14_vdd__MET1_PIN_BOX=174.985 164.17 178.675 166.17
RO_PG_14_vdd__MET1_TARGET_STATUS=PASS
RO_PG_14_vdd__MET1_TARGET_SHAPE=stripe
RO_PG_14_vdd__MET1_TARGET_LAYER=MET3
RO_PG_14_vdd__MET1_TARGET_DISTANCE_UM=33.990
RO_PG_14_vdd__MET1_TARGET_BOX=16.16 200.16 1045.04 202.16
RO_PG_14_vdd__MET1_BRIDGE_DIRECTION=horizontal
RO_PG_14_vdd__MET1_BRIDGE_AREA=15.160 163.170 1046.040 203.160
RO_PG_14_vdd__MET1_BRIDGE_COORD=165.170
RO_PG_14_vdd__MET1_BRIDGE_WIDTH=0.8

COMMAND_RO_PG_14_vdd__MET1_PIN_LAYER=addStripe -nets VDD -layer MET1 -direction horizontal -width 0.8 -spacing 2.0 -set_to_set_distance 5000.0 -start_from bottom -start_offset 165.170 -number_of_sets 1 -area {15.160 163.170 1046.040 203.160}
RO_PG_14_vdd__MET1_PIN_LAYER_STATUS=PASS
RO_PG_14_vdd__MET1_TARGET_BRIDGE_COORD=165.170
RO_PG_14_vdd__MET1_TARGET_BRIDGE_WIDTH=2.0

COMMAND_RO_PG_14_vdd__MET1_TARGET_LAYER=addStripe -nets VDD -layer MET3 -direction horizontal -width 2.0 -spacing 2.0 -set_to_set_distance 5000.0 -start_from bottom -start_offset 165.170 -number_of_sets 1 -area {15.160 163.170 1046.040 203.160}
RO_PG_14_vdd__MET1_TARGET_LAYER_STATUS=PASS

RO_PG_15_VDD_MET1_INST=u_core_u_osc_slow_u_ro_tune4
RO_PG_15_VDD_MET1_PIN=VDD
RO_PG_15_VDD_MET1_NET=VDD
RO_PG_15_VDD_MET1_PIN_LAYER=MET1
RO_PG_15_VDD_MET1_PIN_BOX=52.43 627.355 57.575 630.59
RO_PG_15_VDD_MET1_TARGET_STATUS=PASS
RO_PG_15_VDD_MET1_TARGET_SHAPE=stripe
RO_PG_15_VDD_MET1_TARGET_LAYER=METTP
RO_PG_15_VDD_MET1_TARGET_DISTANCE_UM=10.270
RO_PG_15_VDD_MET1_TARGET_BOX=40.16 16.16 42.16 785.76
RO_PG_15_VDD_MET1_BRIDGE_DIRECTION=vertical
RO_PG_15_VDD_MET1_BRIDGE_AREA=39.160 15.160 58.575 786.760
RO_PG_15_VDD_MET1_BRIDGE_COORD=55.002
RO_PG_15_VDD_MET1_BRIDGE_WIDTH=0.8

COMMAND_RO_PG_15_VDD_MET1_PIN_LAYER=addStripe -nets VDD -layer MET1 -direction vertical -width 0.8 -spacing 2.0 -set_to_set_distance 5000.0 -start_from left -start_offset 55.002 -number_of_sets 1 -area {39.160 15.160 58.575 786.760}
RO_PG_15_VDD_MET1_PIN_LAYER_STATUS=PASS
RO_PG_15_VDD_MET1_TARGET_BRIDGE_COORD=55.002
RO_PG_15_VDD_MET1_TARGET_BRIDGE_WIDTH=2.0

COMMAND_RO_PG_15_VDD_MET1_TARGET_LAYER=addStripe -nets VDD -layer METTP -direction vertical -width 2.0 -spacing 2.0 -set_to_set_distance 5000.0 -start_from left -start_offset 55.002 -number_of_sets 1 -area {39.160 15.160 58.575 786.760}
RO_PG_15_VDD_MET1_TARGET_LAYER_STATUS=PASS

RO_PG_16_VSS_MET1_INST=u_core_u_osc_slow_u_ro_tune4
RO_PG_16_VSS_MET1_PIN=VSS
RO_PG_16_VSS_MET1_NET=VSS
RO_PG_16_VSS_MET1_PIN_LAYER=MET1
RO_PG_16_VSS_MET1_PIN_BOX=50.405 645.6 52.085 653.265
RO_PG_16_VSS_MET1_TARGET_STATUS=PASS
RO_PG_16_VSS_MET1_TARGET_SHAPE=stripe
RO_PG_16_VSS_MET1_TARGET_LAYER=METTP
RO_PG_16_VSS_MET1_TARGET_DISTANCE_UM=4.245
RO_PG_16_VSS_MET1_TARGET_BOX=44.16 13.16 46.16 788.76
RO_PG_16_VSS_MET1_BRIDGE_DIRECTION=vertical
RO_PG_16_VSS_MET1_BRIDGE_AREA=43.160 12.160 53.085 789.760
RO_PG_16_VSS_MET1_BRIDGE_COORD=51.245
RO_PG_16_VSS_MET1_BRIDGE_WIDTH=0.8

COMMAND_RO_PG_16_VSS_MET1_PIN_LAYER=addStripe -nets VSS -layer MET1 -direction vertical -width 0.8 -spacing 2.0 -set_to_set_distance 5000.0 -start_from left -start_offset 51.245 -number_of_sets 1 -area {43.160 12.160 53.085 789.760}
RO_PG_16_VSS_MET1_PIN_LAYER_STATUS=PASS
RO_PG_16_VSS_MET1_TARGET_BRIDGE_COORD=51.245
RO_PG_16_VSS_MET1_TARGET_BRIDGE_WIDTH=2.0

COMMAND_RO_PG_16_VSS_MET1_TARGET_LAYER=addStripe -nets VSS -layer METTP -direction vertical -width 2.0 -spacing 2.0 -set_to_set_distance 5000.0 -start_from left -start_offset 51.245 -number_of_sets 1 -area {43.160 12.160 53.085 789.760}
RO_PG_16_VSS_MET1_TARGET_LAYER_STATUS=PASS

RO_PG_17_vdd__MET2_INST=u_core_u_osc_slow_u_ro_tune4
RO_PG_17_vdd__MET2_PIN=vdd!
RO_PG_17_vdd__MET2_NET=VDD
RO_PG_17_vdd__MET2_PIN_LAYER=MET2
RO_PG_17_vdd__MET2_PIN_BOX=144.88 625.66 146.88 639.455
RO_PG_17_vdd__MET2_TARGET_STATUS=PASS
RO_PG_17_vdd__MET2_TARGET_SHAPE=stripe
RO_PG_17_vdd__MET2_TARGET_LAYER=MET3
RO_PG_17_vdd__MET2_TARGET_DISTANCE_UM=23.500
RO_PG_17_vdd__MET2_TARGET_BOX=16.16 600.16 1045.04 602.16
RO_PG_17_vdd__MET2_BRIDGE_DIRECTION=horizontal
RO_PG_17_vdd__MET2_BRIDGE_AREA=15.160 599.160 1046.040 640.455
RO_PG_17_vdd__MET2_BRIDGE_COORD=632.557
RO_PG_17_vdd__MET2_BRIDGE_WIDTH=0.8

COMMAND_RO_PG_17_vdd__MET2_PIN_LAYER=addStripe -nets VDD -layer MET2 -direction horizontal -width 0.8 -spacing 2.0 -set_to_set_distance 5000.0 -start_from bottom -start_offset 632.557 -number_of_sets 1 -area {15.160 599.160 1046.040 640.455}
RO_PG_17_vdd__MET2_PIN_LAYER_STATUS=PASS
RO_PG_17_vdd__MET2_TARGET_BRIDGE_COORD=632.557
RO_PG_17_vdd__MET2_TARGET_BRIDGE_WIDTH=2.0

COMMAND_RO_PG_17_vdd__MET2_TARGET_LAYER=addStripe -nets VDD -layer MET3 -direction horizontal -width 2.0 -spacing 2.0 -set_to_set_distance 5000.0 -start_from bottom -start_offset 632.557 -number_of_sets 1 -area {15.160 599.160 1046.040 640.455}
RO_PG_17_vdd__MET2_TARGET_LAYER_STATUS=PASS

RO_PG_18_vdd__MET2_INST=u_core_u_osc_slow_u_ro_tune4
RO_PG_18_vdd__MET2_PIN=vdd!
RO_PG_18_vdd__MET2_NET=VDD
RO_PG_18_vdd__MET2_PIN_LAYER=MET2
RO_PG_18_vdd__MET2_PIN_BOX=140.13 638.1 146.88 638.9
RO_PG_18_vdd__MET2_TARGET_STATUS=PASS
RO_PG_18_vdd__MET2_TARGET_SHAPE=stripe
RO_PG_18_vdd__MET2_TARGET_LAYER=METTP
RO_PG_18_vdd__MET2_TARGET_DISTANCE_UM=35.056
RO_PG_18_vdd__MET2_TARGET_BOX=120.16 193.3 122.16 608.0
RO_PG_18_vdd__MET2_BRIDGE_DIRECTION=vertical
RO_PG_18_vdd__MET2_BRIDGE_AREA=119.160 192.300 147.880 639.900
RO_PG_18_vdd__MET2_BRIDGE_COORD=143.505
RO_PG_18_vdd__MET2_BRIDGE_WIDTH=0.8

COMMAND_RO_PG_18_vdd__MET2_PIN_LAYER=addStripe -nets VDD -layer MET2 -direction vertical -width 0.8 -spacing 2.0 -set_to_set_distance 5000.0 -start_from left -start_offset 143.505 -number_of_sets 1 -area {119.160 192.300 147.880 639.900}
RO_PG_18_vdd__MET2_PIN_LAYER_STATUS=PASS
RO_PG_18_vdd__MET2_TARGET_BRIDGE_COORD=143.505
RO_PG_18_vdd__MET2_TARGET_BRIDGE_WIDTH=2.0

### pg_postroute_connectivity_status.rpt
# MPTDC Post-route PG Connectivity Status
PG_CONNECTIVITY_STATUS=FAIL
PG_CONNECTIVITY_STAGE=POST_ROUTE_SPECIAL_NET_VERIFY
SPECIAL_CONNECTIVITY_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_connectivity_special.rpt
SPECIAL_CONNECTIVITY_BAD=1
SPECIAL_CONNECTIVITY_BAD_LINES={Net VDD: has an unconnected terminal, has special routes with opens, dangling Wire.} {Net VSS: has an unconnected terminal, has special routes with opens, dangling Wire.} {6 Problem(s) (IMPVFC-96): Terminal(s) are not connected.} {2 Problem(s) (IMPVFC-200): Special Wires: Pieces of the net are not connected together.} {8 Problem(s) (IMPVFC-94): The net has dangling wire(s).} {Verification Complete : 16 Viols.  0 Wrngs.}
REGULAR_CONNECTIVITY_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_connectivity_regular.rpt
REGULAR_CONNECTIVITY_BAD=0
REGULAR_CONNECTIVITY_BAD_LINES=
PG_GATE_NOTE=regular_net_connectivity_is_reported_for_route_gate_only

## Route / DRC / Connectivity

### route_status.rpt
ROUTE_STATUS=FAIL
ROUTE_IMPLEMENTATION_STATUS=FAIL
INNOVUS_VERIFY_DRC_STATUS=FAIL
FOUNDRY_DRC_STATUS=DEFERRED
GEOMETRY_DRC_VIOLATIONS=9
SHORTS=4
ROUTER_TRANSCRIPT_DRC=9
ROUTER_TRANSCRIPT_SHORTS=6
ROUTER_TRANSCRIPT_STATUS=FAIL
ROUTER_TRANSCRIPT_SOURCE=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_ecoRoute_fix_drc.rpt
INNOVUS_VERIFY_DRC_VIOLATIONS_RAW=9
INNOVUS_VERIFY_DRC_SHORTS_RAW=4
REGULAR_NET_CONNECTIVITY_BAD=0
REGULAR_NET_BAD_LINES=
SPECIAL_NET_CONNECTIVITY_BAD=1
SPECIAL_NET_BAD_LINES={Net VDD: has an unconnected terminal, has special routes with opens, dangling Wire.} {Net VSS: has an unconnected terminal, has special routes with opens, dangling Wire.} {6 Problem(s) (IMPVFC-96): Terminal(s) are not connected.} {2 Problem(s) (IMPVFC-200): Special Wires: Pieces of the net are not connected together.} {8 Problem(s) (IMPVFC-94): The net has dangling wire(s).} {Verification Complete : 16 Viols.  0 Wrngs.}
REGULAR_NET_OPENS=0
SPECIAL_NET_OPENS=NONZERO_OR_UNPARSED
UNROUTED_NETS=UNKNOWN
UNROUTED_NETS_SOURCE=report_route
PARTIAL_ROUTES=REVIEW_REPORT_ROUTE
ANTENNA_STATUS=PROVISIONAL_WITH_LEF_ANTENNA_COMPLETENESS_REVIEW
ROUTE_DRC_REVIEW_CONTINUE_STATUS=DISABLED
ROUTE_DRC_REVIEW_CONTINUE_ENV=MPTDC_ALLOW_ROUTE_DRC_REVIEW_CONTINUE
ROUTE_DRC_REVIEW_MAX_VIOLATIONS=5
ROUTE_DRC_REVIEW_ALLOWED_CLASSES=Mar
ROUTE_DRC_REVIEW_CLASS_STATUS=FAIL
ROUTE_DRC_REVIEW_CLASS_REASON=disallowed_classes:Short=4,MetSpc=1
ROUTE_DRC_REVIEW_CLASS_COUNTS=Short=4 Mar=4 MetSpc=1
ROUTE_DRC_CLASS_COUNTS=Short 4 Mar 4 MetSpc 1
DRC_MARKER_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc_markers.tsv
ROUTE_GATE_FAILURE_MARKER_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_gate_failure_drc_markers.tsv
ROUTE_GATE_FAILURE_DEF=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/def/04_route_failed.def
ROUTE_GATE_FAILURE_CHECKPOINT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/checkpoints/04_route_failed.enc
ROUTE_GATE_FAILURE_CHECKPOINT_DAT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/checkpoints/04_route_failed.enc.dat
ROUTE_GATE_FAILURE_DEF_SAVE_STATUS=PASS
ROUTE_GATE_FAILURE_CHECKPOINT_SAVE_STATUS=PASS
ROUTE_GATE_FAILURE_CHECKPOINT_SAVE_ERROR=0
ROUTE_GATE_FAILURE_CHECKPOINT_DAT_EXISTS=1

### route_failed.rpt
STAGE=route
STATUS=FAIL
ERROR=MPTDC_ROUTE_GATE_FAILED: report=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt

MPTDC_ROUTE_GATE_FAILED: report=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt
    while executing
"error "MPTDC_ROUTE_GATE_FAILED: report=$rpt""
    (procedure "mptdc_signoff_write_route_gate_status" line 121)
    invoked from within
"mptdc_signoff_write_route_gate_status $rpt $drc_data $regular_bad $special_bad $unrouted $antenna_status"
    (procedure "mptdc_signoff_route_design" line 99)
    invoked from within
"mptdc_signoff_route_design"
    ("uplevel" body line 2)
    invoked from within
"uplevel 1 $body"

### route_recovery_status.rpt
# MPTDC Route Gate Recovery
ROUTE_GATE_RECOVERY_INITIAL_DRC=12
ROUTE_GATE_RECOVERY_INITIAL_SHORTS=7
ROUTE_GATE_RECOVERY_REPAIR_COMMANDS={ecoRoute -target} {ecoRoute -fix_drc}
ROUTE_GATE_SROUTE_RECOVERY=ENABLED
ROUTE_GATE_SROUTE_RECOVERY_INITIAL_SPECIAL_BAD_LINES={Net VDD: has an unconnected terminal, has special routes with opens, dangling Wire.} {Net VSS: has an unconnected terminal, has special routes with opens, dangling Wire.} {6 Problem(s) (IMPVFC-96): Terminal(s) are not connected.} {2 Problem(s) (IMPVFC-200): Special Wires: Pieces of the net are not connected together.} {8 Problem(s) (IMPVFC-94): The net has dangling wire(s).} {Verification Complete : 16 Viols.  0 Wrngs.}
ROUTE_GATE_SROUTE_MODE_CORE_PIN_STOP_ROUTE_COMMAND=setSrouteMode -corePinStopRoute RowEnd
ROUTE_GATE_SROUTE_MODE_CORE_PIN_STOP_ROUTE_STATUS=PASS
ROUTE_GATE_SROUTE_MODE_EXPERIMENTS_ENABLED=0
ROUTE_GATE_SROUTE_MODE_STATUS=PASS
ROUTE_GATE_SROUTE_MODE_REASON=deterministic_core_pin_stop_only
ROUTE_GATE_SROUTE_PADPIN_FALLBACK_ENABLED=0

COMMAND_ROUTE_GATE_SROUTE=sroute -connect {corePin blockPin} -nets {VDD VSS} -blockPin all -blockPinTarget {ring stripe} -corePinTarget {ring stripe} -allowLayerChange 1
ROUTE_GATE_SROUTE_ATTEMPT_1_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ROUTE_GATE_SROUTE_sroute_1.rpt
ROUTE_GATE_SROUTE_ATTEMPT_1_COMMAND_STATUS=PASS
ROUTE_GATE_SROUTE_ATTEMPT_1_STATUS=REVIEW_REQUIRED
ROUTE_GATE_SROUTE_ATTEMPT_1_WIRES=4
ROUTE_GATE_SROUTE_ATTEMPT_1_OPEN_PORTS=48
ROUTE_GATE_SROUTE_ATTEMPT_1_BLOCK_OPEN_PORTS=24
ROUTE_GATE_SROUTE_ATTEMPT_1_CORE_OPEN_PORTS=24
ROUTE_GATE_SROUTE_ATTEMPT_1_POWER_BUMP_OPEN_PORTS=0
ROUTE_GATE_SROUTE_ATTEMPT_1_REASON=open_ports_nonzero
ROUTE_GATE_SROUTE_STATUS=FAIL
ROUTE_GATE_SROUTE_RECOVERY_COMMAND_STATUS=FAIL
ROUTE_GATE_RECOVERY_COMMAND=ecoRoute -target
ROUTE_GATE_RECOVERY_COMMAND_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_ecoRoute_target.rpt
ROUTE_GATE_RECOVERY_ATTEMPT_ROUTER_DRC=13
ROUTE_GATE_RECOVERY_ATTEMPT_ROUTER_SHORTS=7
ROUTE_GATE_RECOVERY_ATTEMPT_VERIFY_DRC=12
ROUTE_GATE_RECOVERY_ATTEMPT_VERIFY_SHORTS=7
ROUTE_GATE_RECOVERY_ATTEMPT_DRC=12
ROUTE_GATE_RECOVERY_ATTEMPT_SHORTS=7
ROUTE_GATE_RECOVERY_ATTEMPT_MARKER_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_ecoRoute_target_markers.tsv
ROUTE_GATE_RECOVERY_ATTEMPT_STATUS=REVIEW_REQUIRED
ROUTE_GATE_RECOVERY_COMMAND=ecoRoute -fix_drc
ROUTE_GATE_RECOVERY_COMMAND_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_ecoRoute_fix_drc.rpt
ROUTE_GATE_RECOVERY_ATTEMPT_ROUTER_DRC=9
ROUTE_GATE_RECOVERY_ATTEMPT_ROUTER_SHORTS=6
ROUTE_GATE_RECOVERY_ATTEMPT_VERIFY_DRC=9
ROUTE_GATE_RECOVERY_ATTEMPT_VERIFY_SHORTS=4
ROUTE_GATE_RECOVERY_ATTEMPT_DRC=9
ROUTE_GATE_RECOVERY_ATTEMPT_SHORTS=4
ROUTE_GATE_RECOVERY_ATTEMPT_MARKER_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_ecoRoute_fix_drc_markers.tsv
ROUTE_GATE_RECOVERY_ATTEMPT_STATUS=REVIEW_REQUIRED
ROUTE_GATE_RECOVERY_STATUS=REVIEW_REQUIRED

### route_drc.rpt
#-check_same_via_cell true               # bool, default=false, user setting
 *** Starting Verify DRC (MEM: 3178.2) ***

  VERIFY DRC ...... Starting Verification
  VERIFY DRC ...... Initializing
  VERIFY DRC ...... Deleting Existing Violations
  VERIFY DRC ...... Creating Sub-Areas
  VERIFY DRC ...... Using new threading
  VERIFY DRC ...... Sub-Area: {0.000 0.000 213.440 202.400} 1 of 20
  VERIFY DRC ...... Sub-Area : 1 complete 4 Viols.
  VERIFY DRC ...... Sub-Area: {213.440 0.000 426.880 202.400} 2 of 20
  VERIFY DRC ...... Sub-Area : 2 complete 0 Viols.
  VERIFY DRC ...... Sub-Area: {426.880 0.000 640.320 202.400} 3 of 20
  VERIFY DRC ...... Sub-Area : 3 complete 0 Viols.
  VERIFY DRC ...... Sub-Area: {640.320 0.000 853.760 202.400} 4 of 20
  VERIFY DRC ...... Sub-Area : 4 complete 0 Viols.
  VERIFY DRC ...... Sub-Area: {853.760 0.000 1061.200 202.400} 5 of 20
  VERIFY DRC ...... Sub-Area : 5 complete 0 Viols.
  VERIFY DRC ...... Sub-Area: {0.000 202.400 213.440 404.800} 6 of 20
  VERIFY DRC ...... Sub-Area : 6 complete 0 Viols.
  VERIFY DRC ...... Sub-Area: {213.440 202.400 426.880 404.800} 7 of 20
  VERIFY DRC ...... Sub-Area : 7 complete 0 Viols.
  VERIFY DRC ...... Sub-Area: {426.880 202.400 640.320 404.800} 8 of 20
  VERIFY DRC ...... Sub-Area : 8 complete 0 Viols.
  VERIFY DRC ...... Sub-Area: {640.320 202.400 853.760 404.800} 9 of 20
  VERIFY DRC ...... Sub-Area : 9 complete 0 Viols.
  VERIFY DRC ...... Sub-Area: {853.760 202.400 1061.200 404.800} 10 of 20
  VERIFY DRC ...... Sub-Area : 10 complete 0 Viols.
  VERIFY DRC ...... Sub-Area: {0.000 404.800 213.440 607.200} 11 of 20
  VERIFY DRC ...... Sub-Area : 11 complete 0 Viols.
  VERIFY DRC ...... Sub-Area: {213.440 404.800 426.880 607.200} 12 of 20
  VERIFY DRC ...... Sub-Area : 12 complete 3 Viols.
  VERIFY DRC ...... Sub-Area: {426.880 404.800 640.320 607.200} 13 of 20
  VERIFY DRC ...... Sub-Area : 13 complete 1 Viols.
  VERIFY DRC ...... Sub-Area: {640.320 404.800 853.760 607.200} 14 of 20
  VERIFY DRC ...... Sub-Area : 14 complete 0 Viols.
  VERIFY DRC ...... Sub-Area: {853.760 404.800 1061.200 607.200} 15 of 20
  VERIFY DRC ...... Sub-Area : 15 complete 0 Viols.
  VERIFY DRC ...... Sub-Area: {0.000 607.200 213.440 801.920} 16 of 20
  VERIFY DRC ...... Sub-Area : 16 complete 1 Viols.
  VERIFY DRC ...... Sub-Area: {213.440 607.200 426.880 801.920} 17 of 20
  VERIFY DRC ...... Sub-Area : 17 complete 0 Viols.
  VERIFY DRC ...... Sub-Area: {426.880 607.200 640.320 801.920} 18 of 20
  VERIFY DRC ...... Sub-Area : 18 complete 0 Viols.
  VERIFY DRC ...... Sub-Area: {640.320 607.200 853.760 801.920} 19 of 20
  VERIFY DRC ...... Sub-Area : 19 complete 0 Viols.
  VERIFY DRC ...... Sub-Area: {853.760 607.200 1061.200 801.920} 20 of 20
  VERIFY DRC ...... Sub-Area : 20 complete 0 Viols.

  Verification Complete : 9 Viols.

 Violation Summary By Layer and Type:

	          Short      Mar   MetSpc   Totals
	MET1          4        4        1        9
	Totals        4        4        1        9

 *** End Verify DRC (CPU TIME: 0:00:06.6  ELAPSED TIME: 0:00:07.0  MEM: 256.1M) ***


### postroute_verify_connectivity_special.rpt

### postroute_verify_connectivity_all.rpt

## Timing / Extraction / Power

### timing_tc_post_import.rpt
*** timeDesign #1 [begin] : totSession cpu/real = 0:00:27.2/0:00:27.5 (1.0), mem = 1882.2M
Set Using Default Delay Limit as 101.
**WARN: (IMPDC-1629):	The default delay limit was set to 101. This is less than the default of 1000 and may result in inaccurate delay calculation for nets with a fanout higher than the setting.  If needed, the default delay limit may be adjusted by running the command 'set delaycal_use_default_delay_limit'.
Setting High Fanout Nets ( > 100 ) as ideal temporarily for -prePlace option
Set Default Net Delay as 0 ps.
Set Default Net Load as 0 pF. 
Set Default Input Pin Transition as 1 ps.
INFO: setAnalysisMode clkSrcPath true -> false
INFO: setAnalysisMode clockPropagation sdcControl -> forcedIdeal
Starting delay calculation for Setup views
AAE_INFO: opIsDesignInPostRouteState() is 0
AAE DB initialization (MEM=2024.78 CPU=0:00:00.0 REAL=0:00:00.0) 
#################################################################################
# Design Stage: PreRoute
# Design Name: mptdc_axis_core
# Design Mode: 180nm
# Analysis Mode: MMMC Non-OCV 
# Parasitics Mode: No SPEF/RCDB 
# Signoff Settings: SI Off 
#################################################################################
Using master clock 'clk_osc_fast_tap2' for generated clock 'clk_osc_fast_buf_tap2' in view 'TC_NOMINAL'
Using master clock 'clk_osc_fast_tap6' for generated clock 'clk_osc_fast_buf_tap6' in view 'TC_NOMINAL'
Using master clock 'clk_osc_fast_tap3' for generated clock 'clk_osc_fast_buf_tap3' in view 'TC_NOMINAL'
Using master clock 'clk_osc_fast_tap7' for generated clock 'clk_osc_fast_buf_tap7' in view 'TC_NOMINAL'
Using master clock 'clk_osc_fast_tap1' for generated clock 'clk_osc_fast_buf_tap1' in view 'TC_NOMINAL'
Using master clock 'clk_osc_fast_tap4' for generated clock 'clk_osc_fast_buf_tap4' in view 'TC_NOMINAL'
Using master clock 'clk_osc_fast_tap5' for generated clock 'clk_osc_fast_buf_tap5' in view 'TC_NOMINAL'
Using master clock 'clk_osc_slow_tap4' for generated clock 'clk_osc_slow_buf_tap4' in view 'TC_NOMINAL'
Using master clock 'clk_osc_slow_tap2' for generated clock 'clk_osc_slow_buf_tap2' in view 'TC_NOMINAL'
Using master clock 'clk_osc_slow_tap5' for generated clock 'clk_osc_slow_buf_tap5' in view 'TC_NOMINAL'
Using master clock 'clk_osc_slow_tap6' for generated clock 'clk_osc_slow_buf_tap6' in view 'TC_NOMINAL'
Using master clock 'clk_osc_slow_tap7' for generated clock 'clk_osc_slow_buf_tap7' in view 'TC_NOMINAL'
Using master clock 'clk_osc_fast' for generated clock 'clk_osc_fast_buf_tap0' in view 'TC_NOMINAL'
Using master clock 'clk_osc_slow_tap3' for generated clock 'clk_osc_slow_buf_tap3' in view 'TC_NOMINAL'
Using master clock 'clk_osc_slow_tap1' for generated clock 'clk_osc_slow_buf_tap1' in view 'TC_NOMINAL'
Using master clock 'clk_osc_slow' for generated clock 'clk_osc_slow_buf_tap0' in view 'TC_NOMINAL'
Calculate delays in Single mode...
Start delay calculation (fullDC) (1 T). (MEM=2045.04)
siFlow : Timing analysis mode is single, using late cdB files
Total number of fetched objects 15138
AAE_INFO: Total number of nets for which stage creation was skipped for all views 0
End delay calculation. (MEM=2194.66 CPU=0:00:01.8 REAL=0:00:02.0)
End delay calculation (fullDC). (MEM=2194.66 CPU=0:00:02.3 REAL=0:00:03.0)
*** Done Building Timing Graph (cpu=0:00:03.7 real=0:00:05.0 totSessionCpu=0:00:31.8 mem=2186.7M)

------------------------------------------------------------------
          timeDesign Summary
------------------------------------------------------------------

Setup views included:
 TC_NOMINAL 

+--------------------+---------+---------+---------+
|     Setup mode     |   all   | reg2reg | default |
+--------------------+---------+---------+---------+
|           WNS (ns):|  0.025  |  0.025  |  1.730  |
|           TNS (ns):|  0.000  |  0.000  |  0.000  |
|    Violating Paths:|    0    |    0    |    0    |
|          All Paths:|  4886   |  4862   |  2192   |
+--------------------+---------+---------+---------+

Density: 69.982%
------------------------------------------------------------------
Set Using Default Delay Limit as 1000.
Resetting back High Fanout Nets as non-ideal
Set Default Net Delay as 1000 ps.
Set Default Input Pin Transition as 0.1 ps.
Set Default Net Load as 0.5 pF. 
Reported timing to dir ./timingReports
Total CPU time: 4.97 sec
Total Real time: 6.0 sec
Total Memory Usage: 2100.144531 Mbytes

### postroute_opt_status.rpt
# MPTDC Optional Post-Route Optimization Status
POSTROUTE_OPT_TIMING_POLICY_STATUS=PASS
POSTROUTE_OPT_TIMING_POLICY_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/extraction_sta_policy.rpt
POSTROUTE_OPT_ANALYSIS_TYPE=onChipVariation
POSTROUTE_OPT_CPPR=both
POSTROUTE_OPT_TC_CLOSURE_MODE=ENABLED
POSTROUTE_OPT_SETUP_REQUESTED_PASSES=10
POSTROUTE_OPT_SETUP_HARD_CAP=10
POSTROUTE_OPT_SETUP_HARD_CAP_APPLIED=0
POSTROUTE_OPT_SETUP_MAX_PASSES=10
POSTROUTE_OPT_SETUP_PASSES=10
POSTROUTE_OPT_SETUP_TARGET_SLACK_NS=0.200
POSTROUTE_OPT_SETUP_EARLY_STOP=0
POSTROUTE_OPT_SETUP_PLATEAU_GUARD=1
POSTROUTE_OPT_SETUP_STALL_LIMIT=3
POSTROUTE_OPT_SETUP_MIN_IMPROVEMENT_NS=0.002
POSTROUTE_OPT_HOLD_REQUESTED_PASSES=3
POSTROUTE_OPT_HOLD_MAX_PASSES=3
POSTROUTE_OPT_HOLD_PASSES=3
POSTROUTE_OPT_HOLD_TARGET_SLACK_NS=0.050
POSTROUTE_OPT_FAST_TAG_TIMING_FOCUS_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_timing_focus.rpt
POSTROUTE_OPT_FAST_TAG_TARGETED_ECO_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt
POSTROUTE_OPT_SETUP_PASS=1
POSTROUTE_OPT_setup_PASS_1_STATUS=PASS
POSTROUTE_OPT_setup_PASS_1_TIMING_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_setup_pass_1_timing.rpt
POSTROUTE_OPT_setup_PASS_1_WNS_NS=-0.019
POSTROUTE_OPT_setup_PASS_1_TNS_NS=-0.131
POSTROUTE_OPT_setup_PASS_1_TIMING_STATUS=PASS
POSTROUTE_OPT_setup_PASS_1_STALL_COUNT=0
POSTROUTE_OPT_SETUP_PASS=2
POSTROUTE_OPT_setup_PASS_2_STATUS=PASS
POSTROUTE_OPT_setup_PASS_2_TIMING_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_setup_pass_2_timing.rpt
POSTROUTE_OPT_setup_PASS_2_WNS_NS=-0.020
POSTROUTE_OPT_setup_PASS_2_TNS_NS=-0.125
POSTROUTE_OPT_setup_PASS_2_TIMING_STATUS=PASS
POSTROUTE_OPT_setup_PASS_2_STALL_COUNT=1
POSTROUTE_OPT_SETUP_PASS=3
POSTROUTE_OPT_setup_PASS_3_STATUS=PASS
POSTROUTE_OPT_setup_PASS_3_TIMING_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_setup_pass_3_timing.rpt
POSTROUTE_OPT_setup_PASS_3_WNS_NS=-0.020
POSTROUTE_OPT_setup_PASS_3_TNS_NS=-0.125
POSTROUTE_OPT_setup_PASS_3_TIMING_STATUS=PASS
POSTROUTE_OPT_setup_PASS_3_STALL_COUNT=2
POSTROUTE_OPT_SETUP_PASS=4
POSTROUTE_OPT_setup_PASS_4_STATUS=PASS
POSTROUTE_OPT_setup_PASS_4_TIMING_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_setup_pass_4_timing.rpt
POSTROUTE_OPT_setup_PASS_4_WNS_NS=-0.020
POSTROUTE_OPT_setup_PASS_4_TNS_NS=-0.125
POSTROUTE_OPT_setup_PASS_4_TIMING_STATUS=PASS
POSTROUTE_OPT_setup_PASS_4_STALL_COUNT=3
POSTROUTE_OPT_SETUP_STOP_AFTER_PASS=4
POSTROUTE_OPT_SETUP_STOP_REASON=setup_wns_plateau
POSTROUTE_OPT_setup_STATUS=PASS
POSTROUTE_OPT_SETUP_STOP_AFTER_PASS=4
POSTROUTE_OPT_SETUP_STOP_REASON=setup_wns_plateau
POSTROUTE_OPT_SETUP_FINAL_WNS_NS=-0.020
POSTROUTE_OPT_SETUP_FINAL_TNS_NS=-0.125
POSTROUTE_OPT_SETUP_CLOSURE_STATUS=FAIL
POSTROUTE_OPT_FAST_TAG_FINAL_TIMING_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_postroute_opt_final.rpt
POSTROUTE_OPT_FAST_TAG_FINAL_TIMING_STATUS=PASS
POSTROUTE_OPT_FAST_TAG_TIMING_DIAGNOSIS_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_diagnosis.rpt
POSTROUTE_OPT_HOLD_PASS=1
POSTROUTE_OPT_hold_PASS_1_STATUS=PASS
POSTROUTE_OPT_HOLD_PASS=2
POSTROUTE_OPT_hold_PASS_2_STATUS=PASS
POSTROUTE_OPT_HOLD_PASS=3
POSTROUTE_OPT_hold_PASS_3_STATUS=PASS
POSTROUTE_OPT_hold_STATUS=PASS
POSTROUTE_OPT_drv_STATUS=PASS

### extracted_timing_status.rpt

### power_status.rpt

### drv_status.rpt

## Final Physical Verification

### physical_verification_status.md

### filler_status.rpt
# MPTDC Final Filler Status
FILLER_CELL_FAMILY=FEED*JIHD
FILLER_CANDIDATES=FEED25JIHD FEED15JIHD FEED10JIHD FEED7JIHD FEED5JIHD FEED3JIHD FEED2JIHD FEED1JIHD
FILLER_COUNT_BEFORE=0
FILLER_MODE_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_mode_status.rpt
FILLER_MODE_STATUS=PASS_OR_REVIEW
FILLER_COUNT=21875
FILLER_DELTA=21875
FILLER_INSERTION_STATUS=PASS
FILLER_PG_CONNECTED=RECHECKED_BY_GLOBALNETCONNECT_AND_ROUTE_CONNECTIVITY
POST_FILLER_ROUTE_CLEANUP=REQUIRED_AFTER_POSTROUTE_FILLER
POST_FILLER_ROUTE_CLEANUP_POLICY=bounded_incremental_eco_then_pg_then_drc
POST_FILLER_ROUTE_REPAIR_COMMANDS={ecoRoute -target} {ecoRoute -fix_drc}
POST_FILLER_ROUTE_PRE_SROUTE_COMMAND=ecoRoute -target
POST_FILLER_ROUTE_POST_SROUTE_COMMANDS={ecoRoute -fix_drc}
POST_FILLER_ROUTE_COMMAND_PHASE=POST_FILLER_PRE_SROUTE
POST_FILLER_ROUTE_COMMAND=ecoRoute -target
POST_FILLER_ROUTE_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/POST_FILLER_PRE_SROUTE_ecoRoute_target.rpt
POST_FILLER_ROUTE_POST_FILLER_PRE_SROUTE_COMMAND_STATUS=PASS
POST_FILLER_ROUTE_POST_FILLER_PRE_SROUTE_ROUTER_DRC=5
POST_FILLER_ROUTE_POST_FILLER_PRE_SROUTE_ROUTER_SHORTS=2
POST_FILLER_ROUTE_POST_FILLER_PRE_SROUTE_MARKER_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/POST_FILLER_PRE_SROUTE_ecoRoute_target_markers.tsv
POST_FILLER_SROUTE_MODE_CORE_PIN_STOP_ROUTE_COMMAND=setSrouteMode -corePinStopRoute RowEnd
POST_FILLER_SROUTE_MODE_CORE_PIN_STOP_ROUTE_STATUS=PASS
POST_FILLER_SROUTE_MODE_EXPERIMENTS_ENABLED=0
POST_FILLER_SROUTE_MODE_STATUS=PASS
POST_FILLER_SROUTE_MODE_REASON=deterministic_core_pin_stop_only
POST_FILLER_SROUTE_PADPIN_FALLBACK_ENABLED=0

COMMAND_POST_FILLER_SROUTE=sroute -connect {corePin blockPin} -nets {VDD VSS} -blockPin all -blockPinTarget {ring stripe} -corePinTarget {ring stripe} -allowLayerChange 1
POST_FILLER_SROUTE_ATTEMPT_1_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/POST_FILLER_SROUTE_sroute_1.rpt
POST_FILLER_SROUTE_ATTEMPT_1_COMMAND_STATUS=PASS
POST_FILLER_SROUTE_ATTEMPT_1_STATUS=REVIEW_REQUIRED
POST_FILLER_SROUTE_ATTEMPT_1_WIRES=4
POST_FILLER_SROUTE_ATTEMPT_1_OPEN_PORTS=48
POST_FILLER_SROUTE_ATTEMPT_1_BLOCK_OPEN_PORTS=24
POST_FILLER_SROUTE_ATTEMPT_1_CORE_OPEN_PORTS=24
POST_FILLER_SROUTE_ATTEMPT_1_POWER_BUMP_OPEN_PORTS=0
POST_FILLER_SROUTE_ATTEMPT_1_REASON=open_ports_nonzero
POST_FILLER_SROUTE_STATUS=FAIL
POST_FILLER_SROUTE_REASON=all_sroute_command_variants_failed
POST_FILLER_ROUTE_COMMAND_PHASE=POST_FILLER_POST_SROUTE
POST_FILLER_ROUTE_COMMAND=ecoRoute -fix_drc
POST_FILLER_ROUTE_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/POST_FILLER_POST_SROUTE_ecoRoute_fix_drc.rpt
POST_FILLER_ROUTE_POST_FILLER_POST_SROUTE_COMMAND_STATUS=PASS
POST_FILLER_ROUTE_POST_FILLER_POST_SROUTE_ROUTER_DRC=3
POST_FILLER_ROUTE_POST_FILLER_POST_SROUTE_ROUTER_SHORTS=2
POST_FILLER_ROUTE_POST_FILLER_POST_SROUTE_MARKER_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/POST_FILLER_POST_SROUTE_ecoRoute_fix_drc_markers.tsv
POST_FILLER_VERIFY_DRC_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt
POST_FILLER_VERIFY_DRC_MARKER_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc_markers.tsv
POST_FILLER_VERIFY_DRC_CAPTURE_STATUS=PASS
POST_FILLER_VERIFY_DRC=12
POST_FILLER_VERIFY_SHORTS=7
POST_FILLER_SPECIAL_CONNECTIVITY_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_connectivity_special.rpt
POST_FILLER_SPECIAL_CONNECTIVITY_CAPTURE_STATUS=PASS
POST_FILLER_SPECIAL_CONNECTIVITY_COMMAND=verifyConnectivity -type special -nets {VDD VSS}
POST_FILLER_SPECIAL_CONNECTIVITY_BAD=1
POST_FILLER_SPECIAL_CONNECTIVITY_BAD_LINES={Net VDD: has an unconnected terminal, has special routes with opens, dangling Wire.} {Net VSS: has an unconnected terminal, has special routes with opens, dangling Wire.} {6 Problem(s) (IMPVFC-96): Terminal(s) are not connected.} {2 Problem(s) (IMPVFC-200): Special Wires: Pieces of the net are not connected together.} {8 Problem(s) (IMPVFC-94): The net has dangling wire(s).} {Verification Complete : 16 Viols.  0 Wrngs.}
POST_FILLER_ALL_CONNECTIVITY_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_connectivity_all.rpt
POST_FILLER_ALL_CONNECTIVITY_CAPTURE_STATUS=PASS
POST_FILLER_ALL_CONNECTIVITY_BAD=1
POST_FILLER_ALL_CONNECTIVITY_BAD_LINES={Net VDD: has an unconnected terminal, has special routes with opens, dangling Wire.} {Net VSS: has an unconnected terminal, has special routes with opens, dangling Wire.} {6 Problem(s) (IMPVFC-96): Terminal(s) are not connected.} {2 Problem(s) (IMPVFC-200): Special Wires: Pieces of the net are not connected together.} {8 Problem(s) (IMPVFC-94): The net has dangling wire(s).} {Verification Complete : 16 Viols.  0 Wrngs.}
POST_FILLER_VERIFY_STATUS=REVIEW_REQUIRED
POST_FILLER_ROUTE_STATUS=REVIEW_REQUIRED
INCREMENTAL_ROUTE_STATUS=REVIEW_REQUIRED
POST_FILLER_CLEANUP_STATUS=REVIEW_REQUIRED
POST_FILLER_GATE_NOTE=route_status_rpt_remains_the_hard_short_open_gate

### antenna_status.rpt

### phase_rc_symmetry_status.rpt

### backend_crossing_status.rpt

### backend_region_status.rpt

### phase_to_pd_geometry_status.rpt

### empty_space_audit_status.rpt

## Report Status Key Lines
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:2:POSTROUTE_OPT_TIMING_POLICY_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:7:POSTROUTE_OPT_SETUP_REQUESTED_PASSES=10
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:10:POSTROUTE_OPT_SETUP_MAX_PASSES=10
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:11:POSTROUTE_OPT_SETUP_PASSES=10
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:17:POSTROUTE_OPT_HOLD_REQUESTED_PASSES=3
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:18:POSTROUTE_OPT_HOLD_MAX_PASSES=3
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:19:POSTROUTE_OPT_HOLD_PASSES=3
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:23:POSTROUTE_OPT_SETUP_PASS=1
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:24:POSTROUTE_OPT_setup_PASS_1_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:25:POSTROUTE_OPT_setup_PASS_1_TIMING_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_setup_pass_1_timing.rpt
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:26:POSTROUTE_OPT_setup_PASS_1_WNS_NS=-0.019
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:27:POSTROUTE_OPT_setup_PASS_1_TNS_NS=-0.131
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:28:POSTROUTE_OPT_setup_PASS_1_TIMING_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:29:POSTROUTE_OPT_setup_PASS_1_STALL_COUNT=0
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:30:POSTROUTE_OPT_SETUP_PASS=2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:31:POSTROUTE_OPT_setup_PASS_2_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:32:POSTROUTE_OPT_setup_PASS_2_TIMING_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_setup_pass_2_timing.rpt
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:33:POSTROUTE_OPT_setup_PASS_2_WNS_NS=-0.020
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:34:POSTROUTE_OPT_setup_PASS_2_TNS_NS=-0.125
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:35:POSTROUTE_OPT_setup_PASS_2_TIMING_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:36:POSTROUTE_OPT_setup_PASS_2_STALL_COUNT=1
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:37:POSTROUTE_OPT_SETUP_PASS=3
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:38:POSTROUTE_OPT_setup_PASS_3_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:39:POSTROUTE_OPT_setup_PASS_3_TIMING_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_setup_pass_3_timing.rpt
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:40:POSTROUTE_OPT_setup_PASS_3_WNS_NS=-0.020
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:41:POSTROUTE_OPT_setup_PASS_3_TNS_NS=-0.125
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:42:POSTROUTE_OPT_setup_PASS_3_TIMING_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:43:POSTROUTE_OPT_setup_PASS_3_STALL_COUNT=2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:44:POSTROUTE_OPT_SETUP_PASS=4
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:45:POSTROUTE_OPT_setup_PASS_4_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:46:POSTROUTE_OPT_setup_PASS_4_TIMING_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_setup_pass_4_timing.rpt
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:47:POSTROUTE_OPT_setup_PASS_4_WNS_NS=-0.020
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:48:POSTROUTE_OPT_setup_PASS_4_TNS_NS=-0.125
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:49:POSTROUTE_OPT_setup_PASS_4_TIMING_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:50:POSTROUTE_OPT_setup_PASS_4_STALL_COUNT=3
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:51:POSTROUTE_OPT_SETUP_STOP_AFTER_PASS=4
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:53:POSTROUTE_OPT_setup_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:54:POSTROUTE_OPT_SETUP_STOP_AFTER_PASS=4
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:56:POSTROUTE_OPT_SETUP_FINAL_WNS_NS=-0.020
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:57:POSTROUTE_OPT_SETUP_FINAL_TNS_NS=-0.125
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:58:POSTROUTE_OPT_SETUP_CLOSURE_STATUS=FAIL
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:60:POSTROUTE_OPT_FAST_TAG_FINAL_TIMING_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:62:POSTROUTE_OPT_HOLD_PASS=1
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:63:POSTROUTE_OPT_hold_PASS_1_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:64:POSTROUTE_OPT_HOLD_PASS=2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:65:POSTROUTE_OPT_hold_PASS_2_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:66:POSTROUTE_OPT_HOLD_PASS=3
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:67:POSTROUTE_OPT_hold_PASS_3_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:68:POSTROUTE_OPT_hold_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_status.rpt:69:POSTROUTE_OPT_drv_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:16:RO_PG_1_VDD_MET1_TARGET_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:27:RO_PG_1_VDD_MET1_PIN_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:32:RO_PG_1_VDD_MET1_TARGET_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:39:RO_PG_2_VSS_MET1_TARGET_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:50:RO_PG_2_VSS_MET1_PIN_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:55:RO_PG_2_VSS_MET1_TARGET_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:62:RO_PG_3_vdd__MET2_TARGET_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:73:RO_PG_3_vdd__MET2_PIN_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:78:RO_PG_3_vdd__MET2_TARGET_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:85:RO_PG_4_vdd__MET2_TARGET_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:96:RO_PG_4_vdd__MET2_PIN_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:101:RO_PG_4_vdd__MET2_TARGET_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:108:RO_PG_5_vdd__MET2_TARGET_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:119:RO_PG_5_vdd__MET2_PIN_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:124:RO_PG_5_vdd__MET2_TARGET_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:131:RO_PG_6_vdd__MET2_TARGET_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:142:RO_PG_6_vdd__MET2_PIN_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:147:RO_PG_6_vdd__MET2_TARGET_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:154:RO_PG_7_vdd__MET1_TARGET_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:165:RO_PG_7_vdd__MET1_PIN_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:170:RO_PG_7_vdd__MET1_TARGET_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:177:RO_PG_8_vdd__MET1_TARGET_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:188:RO_PG_8_vdd__MET1_PIN_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:193:RO_PG_8_vdd__MET1_TARGET_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:200:RO_PG_9_vdd__MET1_TARGET_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:211:RO_PG_9_vdd__MET1_PIN_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:216:RO_PG_9_vdd__MET1_TARGET_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:223:RO_PG_10_vdd__MET2_TARGET_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:234:RO_PG_10_vdd__MET2_PIN_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:239:RO_PG_10_vdd__MET2_TARGET_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:246:RO_PG_11_vdd__MET1_TARGET_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:257:RO_PG_11_vdd__MET1_PIN_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:262:RO_PG_11_vdd__MET1_TARGET_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:269:RO_PG_12_vdd__MET1_TARGET_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:280:RO_PG_12_vdd__MET1_PIN_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:285:RO_PG_12_vdd__MET1_TARGET_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:292:RO_PG_13_vdd__MET1_TARGET_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:303:RO_PG_13_vdd__MET1_PIN_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:308:RO_PG_13_vdd__MET1_TARGET_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:315:RO_PG_14_vdd__MET1_TARGET_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:326:RO_PG_14_vdd__MET1_PIN_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:331:RO_PG_14_vdd__MET1_TARGET_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:338:RO_PG_15_VDD_MET1_TARGET_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:349:RO_PG_15_VDD_MET1_PIN_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:354:RO_PG_15_VDD_MET1_TARGET_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:361:RO_PG_16_VSS_MET1_TARGET_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:372:RO_PG_16_VSS_MET1_PIN_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:377:RO_PG_16_VSS_MET1_TARGET_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:384:RO_PG_17_vdd__MET2_TARGET_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:395:RO_PG_17_vdd__MET2_PIN_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:400:RO_PG_17_vdd__MET2_TARGET_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:407:RO_PG_18_vdd__MET2_TARGET_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:418:RO_PG_18_vdd__MET2_PIN_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:423:RO_PG_18_vdd__MET2_TARGET_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:430:RO_PG_19_vdd__MET2_TARGET_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:441:RO_PG_19_vdd__MET2_PIN_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:446:RO_PG_19_vdd__MET2_TARGET_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:453:RO_PG_20_vdd__MET2_TARGET_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:464:RO_PG_20_vdd__MET2_PIN_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:469:RO_PG_20_vdd__MET2_TARGET_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:476:RO_PG_21_vdd__MET1_TARGET_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:487:RO_PG_21_vdd__MET1_PIN_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:492:RO_PG_21_vdd__MET1_TARGET_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:499:RO_PG_22_vdd__MET1_TARGET_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:510:RO_PG_22_vdd__MET1_PIN_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:515:RO_PG_22_vdd__MET1_TARGET_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:522:RO_PG_23_vdd__MET1_TARGET_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:533:RO_PG_23_vdd__MET1_PIN_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:538:RO_PG_23_vdd__MET1_TARGET_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:545:RO_PG_24_vdd__MET2_TARGET_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:556:RO_PG_24_vdd__MET2_PIN_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:561:RO_PG_24_vdd__MET2_TARGET_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:568:RO_PG_25_vdd__MET1_TARGET_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:579:RO_PG_25_vdd__MET1_PIN_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:584:RO_PG_25_vdd__MET1_TARGET_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:591:RO_PG_26_vdd__MET1_TARGET_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:602:RO_PG_26_vdd__MET1_PIN_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:607:RO_PG_26_vdd__MET1_TARGET_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:614:RO_PG_27_vdd__MET1_TARGET_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:625:RO_PG_27_vdd__MET1_PIN_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:630:RO_PG_27_vdd__MET1_TARGET_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:637:RO_PG_28_vdd__MET1_TARGET_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:648:RO_PG_28_vdd__MET1_PIN_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:653:RO_PG_28_vdd__MET1_TARGET_LAYER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_hookup_status.rpt:657:RO_PG_HOOKUP_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_before_sroute_marker_schema.rpt:2:marker: DRC Marker
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_before_sroute_marker_schema.rpt:19:message: string, DRC marker message
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_before_sroute_marker_schema.rpt:20:messageId: int, DRC marker message ID
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_before_sroute_marker_schema.rpt:21:objType: enum(antennaData antennaModel bndry bump bumpGrid bumpTerm bus busGuide busSinkGroup cellDensity densityShape fPlan foreign gCellGridDef group guiLine guiPoly guiRect guiText hInst hInstTerm hNet hTerm head inst instTerm io layer layerRule layerShape libCell marker net netGroup pBlkg pWire pd pgInstTerm pin pinGroup pinGuide pinShape pkgComponent pkgObject prop ptn ptnCell ptnPinBlkg rBlkg resistor resizeBlkg routeType row rule sViaInst sWire sdp shape shapeVia site stackViaRule term text topCell trackDef vCell vWire via viaInst viaRuleGenerate whatIfVia whatIfWire wire), Object type: DRC Marker
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_before_sroute_marker_schema.rpt:22:objects: objList(bump inst instTerm net term), The objects which caused the DRC. The list may be empty, and is currently limited to at most 2 objects.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_sroute.rpt:4:SCHEMA_marker_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_sroute.rpt:6:SCHEMA_sWire_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_sroute.rpt:8:SCHEMA_term_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_sroute.rpt:10:SCHEMA_pin_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_sroute.rpt:12:SCHEMA_pinShape_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_sroute.rpt:16:TOP_NAME_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_sroute.rpt:22:CORE_BOX_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_sroute.rpt:28:PG_TERM_NAMES_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_sroute.rpt:34:PG_TERM_NETS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_sroute.rpt:40:PG_TERM_LAYERS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_sroute.rpt:46:VDD_PGTERM_NAMES_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_sroute.rpt:52:VSS_PGTERM_NAMES_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_sroute.rpt:58:VDD_SWIRE_COUNT_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_sroute.rpt:64:VSS_SWIRE_COUNT_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_sroute.rpt:622:VERIFY_SPECIAL_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_layer_limits.rpt:3:ROUTE_LAYER_LIMIT_STATUS=APPLIED
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_rc_parser_selftest.rpt:3:PHASE_RC_PARSER_SELFTEST_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_rc_parser_selftest.rpt:7:PHASE_RC_PARSER_SELFTEST_PARSE_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_rc_parser_selftest.rpt:8:PHASE_RC_PARSER_SELFTEST_RC_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:3:STATUS_SCHEMA=PASS_FAIL_EXTERNAL_DEFERRED_PROVISIONAL_ACCEPTED
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:5:MPTDC_TC_PNR_CLOSURE=DEFERRED evidence=tc_physical_closure_not_complete
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:8:PRE_PNR_GATE_STATUS=PASS evidence=pre_pnr_gate.rpt
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:9:GENUS_HANDOFF_STATUS=PASS evidence=init_design
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:10:RO_IMPORT_STATUS=PASS evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_import_integrity_gate.rpt
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:11:EFFECTIVE_SDC_STATUS=PASS evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/effective_sdc_audit.rpt
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:12:ROW_INFRA_POLICY_STATUS=PROVISIONAL evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/row_infra_insertion.rpt
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:13:ROW_INFRA_DRC_LVS_STATUS=DEFERRED evidence=row_drc_lvs_not_run
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:14:PHYSICAL_CELL_CONFIG_STATUS=PROVISIONAL evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/row_infra_policy.rpt
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:15:PG_CONNECTIVITY_STATUS=FAIL evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_postroute_connectivity_status.rpt
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:16:PG_PHYSICAL_STATUS=PROVISIONAL evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_physical_status.rpt
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:17:FLOORPLAN_STATUS=PASS evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/floorplan_status.rpt
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:18:FLOORPLAN_ASPECT_STATUS=PASS evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/floorplan_status.rpt
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:19:IO_STATUS=PASS evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/io_status.rpt
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:20:RO_MACRO_STATUS=PASS evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_macro_status.rpt
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:21:RO_PHASE_PLACEMENT_STATUS=PASS evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_phase_overlap_audit.rpt
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:22:PD_MATRIX_STATUS=REVIEW_REQUIRED evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_physical_matrix_status.rpt
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:23:PD_PHYSICAL_MATRIX_STATUS=REVIEW_REQUIRED evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_physical_matrix_status.rpt
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:24:PHASE_BUFFER_STATUS=PASS evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_buffer_status.rpt
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:25:PLACEMENT_STATUS=PASS evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/placement_status.rpt
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:26:CTS_STATUS=PASS evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/cts_policy.rpt
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:27:ROUTE_STATUS=FAIL evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_failed.rpt
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:28:FILLER_STATUS=PASS evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_status.rpt
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:29:EXTRACTION_STATUS=DEFERRED evidence=not_run
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:30:POWER_STATUS=DEFERRED evidence=not_run
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:31:SETUP_STATUS_TC=PROVISIONAL evidence=timing_tc_post_import.rpt
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:32:TC_HOLD_STATUS=DEFERRED evidence=not_run
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:33:SETUP_STATUS_WC=DEFERRED evidence=scope_tc_only
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:34:HOLD_STATUS_BC=DEFERRED evidence=scope_tc_only
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:35:RO_1GHZ_STRESS_STATUS=DEFERRED evidence=scope_tc_only
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:36:PHASE_LOAD_STATUS=DEFERRED evidence=not_run
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:37:RC_SYMMETRY_STATUS=DEFERRED evidence=not_run
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:38:BACKEND_CROSSING_STATUS=DEFERRED evidence=not_run
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:39:BACKEND_REGION_STATUS=DEFERRED evidence=not_run
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:40:PHASE_TO_PD_GEOMETRY_STATUS=DEFERRED evidence=not_run
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:41:EMPTY_SPACE_AUDIT_STATUS=DEFERRED evidence=not_run
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:42:DRV_STATUS=DEFERRED evidence=not_run
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:43:ANTENNA_STATUS=PROVISIONAL_WITH_LEF_ANTENNA_COMPLETENESS_REVIEW evidence=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/antenna.rpt
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:44:DRC_STATUS=DEFERRED evidence=not_run
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:45:LVS_STATUS=DEFERRED evidence=not_run
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:46:DELIVERABLE_STATUS=DEFERRED evidence=not_run
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/digital_pnr_signoff_status.rpt:49:DIGITAL_PNR_SIGNOFF=PROVISIONAL evidence=row_policy_pending_drc_lvs
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/block_pg_pin_status.rpt:27:BLOCK_PG_PIN_VDD_LEFT_CREATE_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/block_pg_pin_status.rpt:29:BLOCK_PG_PIN_VDD_LEFT_VERIFY_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/block_pg_pin_status.rpt:42:BLOCK_PG_PIN_VSS_LEFT_CREATE_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/block_pg_pin_status.rpt:44:BLOCK_PG_PIN_VSS_LEFT_VERIFY_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/block_pg_pin_status.rpt:57:BLOCK_PG_PIN_VDD_RIGHT_CREATE_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/block_pg_pin_status.rpt:59:BLOCK_PG_PIN_VDD_RIGHT_VERIFY_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/block_pg_pin_status.rpt:72:BLOCK_PG_PIN_VSS_RIGHT_CREATE_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/block_pg_pin_status.rpt:74:BLOCK_PG_PIN_VSS_RIGHT_VERIFY_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/block_pg_pin_status.rpt:77:BLOCK_PG_PIN_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/block_pg_stitch_status.rpt:3:BLOCK_PG_STITCH_STATUS=SKIPPED
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/innovus_fatal_message_audit.rpt:1:INNOVUS_FATAL_MESSAGE_AUDIT=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_rc_parser_selftest_fixture.csv:2:slow,0,raw_slow_0,100.0,0.020,iso_slow_0,101.0,0.024,buf_slow_0,102.0,0.030,0.012,0.018,10.0,PASS,selftest
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_rc_parser_selftest_fixture.csv:3:slow,1,raw_slow_1,101.0,0.020,iso_slow_1,102.0,0.024,buf_slow_1,103.0,0.030,0.012,0.018,10.0,PASS,selftest
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_rc_parser_selftest_fixture.csv:4:slow,2,raw_slow_2,102.0,0.020,iso_slow_2,103.0,0.024,buf_slow_2,104.0,0.030,0.012,0.018,10.0,PASS,selftest
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_rc_parser_selftest_fixture.csv:5:slow,3,raw_slow_3,103.0,0.020,iso_slow_3,104.0,0.024,buf_slow_3,105.0,0.030,0.012,0.018,10.0,PASS,selftest
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_rc_parser_selftest_fixture.csv:6:slow,4,raw_slow_4,104.0,0.020,iso_slow_4,105.0,0.024,buf_slow_4,106.0,0.030,0.012,0.018,10.0,PASS,selftest
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_rc_parser_selftest_fixture.csv:7:slow,5,raw_slow_5,105.0,0.020,iso_slow_5,106.0,0.024,buf_slow_5,107.0,0.030,0.012,0.018,10.0,PASS,selftest
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_rc_parser_selftest_fixture.csv:8:slow,6,raw_slow_6,106.0,0.020,iso_slow_6,107.0,0.024,buf_slow_6,108.0,0.030,0.012,0.018,10.0,PASS,selftest
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_rc_parser_selftest_fixture.csv:9:slow,7,raw_slow_7,107.0,0.020,iso_slow_7,108.0,0.024,buf_slow_7,109.0,0.030,0.012,0.018,10.0,PASS,selftest
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_rc_parser_selftest_fixture.csv:10:fast,0,raw_fast_0,100.0,0.020,iso_fast_0,101.0,0.024,buf_fast_0,102.0,0.030,0.012,0.018,10.0,PASS,selftest
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_rc_parser_selftest_fixture.csv:11:fast,1,raw_fast_1,101.0,0.020,iso_fast_1,102.0,0.024,buf_fast_1,103.0,0.030,0.012,0.018,10.0,PASS,selftest
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_rc_parser_selftest_fixture.csv:12:fast,2,raw_fast_2,102.0,0.020,iso_fast_2,103.0,0.024,buf_fast_2,104.0,0.030,0.012,0.018,10.0,PASS,selftest
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_rc_parser_selftest_fixture.csv:13:fast,3,raw_fast_3,103.0,0.020,iso_fast_3,104.0,0.024,buf_fast_3,105.0,0.030,0.012,0.018,10.0,PASS,selftest
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_rc_parser_selftest_fixture.csv:14:fast,4,raw_fast_4,104.0,0.020,iso_fast_4,105.0,0.024,buf_fast_4,106.0,0.030,0.012,0.018,10.0,PASS,selftest
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_rc_parser_selftest_fixture.csv:15:fast,5,raw_fast_5,105.0,0.020,iso_fast_5,106.0,0.024,buf_fast_5,107.0,0.030,0.012,0.018,10.0,PASS,selftest
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_rc_parser_selftest_fixture.csv:16:fast,6,raw_fast_6,106.0,0.020,iso_fast_6,107.0,0.024,buf_fast_6,108.0,0.030,0.012,0.018,10.0,PASS,selftest
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_rc_parser_selftest_fixture.csv:17:fast,7,raw_fast_7,107.0,0.020,iso_fast_7,108.0,0.024,buf_fast_7,109.0,0.030,0.012,0.018,10.0,PASS,selftest
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_diagnosis.rpt:5:POSTROUTE_OPT_SETUP_WNS_NS=-0.020
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_diagnosis.rpt:6:POSTROUTE_OPT_SETUP_CLOSURE_STATUS=FAIL
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_diagnosis.rpt:14:FAST_TAG_TIMING_DIAGNOSIS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_after_sroute.rpt:6:PG_TERM_NAMES_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_after_sroute.rpt:13:PG_TERM_COUNT_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_after_sroute.rpt:20:VDD_PG_TERM_HANDLES_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_after_sroute.rpt:27:VDD_PG_TERM_NAMES_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_after_sroute.rpt:34:VDD_PG_TERM_NETS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_after_sroute.rpt:41:VDD_PG_TERM_LAYERS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_after_sroute.rpt:48:VSS_PG_TERM_HANDLES_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_after_sroute.rpt:55:VSS_PG_TERM_NAMES_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_after_sroute.rpt:62:VSS_PG_TERM_NETS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_after_sroute.rpt:69:VSS_PG_TERM_LAYERS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_after_sroute.rpt:76:TERM_NAMES_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_after_sroute.rpt:83:VDD_NET_HANDLES_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_after_sroute.rpt:90:VDD_SWIRE_COUNT_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_after_sroute.rpt:97:VDD_SWIRE_LAYERS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_after_sroute.rpt:104:VDD_SWIRE_STATUS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_after_sroute.rpt:111:VSS_NET_HANDLES_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_after_sroute.rpt:118:VSS_SWIRE_COUNT_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_after_sroute.rpt:125:VSS_SWIRE_LAYERS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_after_sroute.rpt:132:VSS_SWIRE_STATUS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_after_sroute.rpt:139:GET_PORTS_VDD_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_after_sroute.rpt:146:GET_PORTS_VSS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc_markers_schema.rpt:2:marker: DRC Marker
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc_markers_schema.rpt:19:message: string, DRC marker message
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc_markers_schema.rpt:20:messageId: int, DRC marker message ID
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc_markers_schema.rpt:21:objType: enum(antennaData antennaModel bndry bump bumpGrid bumpTerm bus busGuide busSinkGroup cellDensity densityShape fPlan foreign gCellGridDef group guiLine guiPoly guiRect guiText hInst hInstTerm hNet hTerm head inst instTerm io layer layerRule layerShape libCell marker net netGroup pBlkg pWire pd pgInstTerm pin pinGroup pinGuide pinShape pkgComponent pkgObject prop ptn ptnCell ptnPinBlkg rBlkg resistor resizeBlkg routeType row rule sViaInst sWire sdp shape shapeVia site stackViaRule term text topCell trackDef vCell vWire via viaInst viaRuleGenerate whatIfVia whatIfWire wire), Object type: DRC Marker
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc_markers_schema.rpt:22:objects: objList(bump inst instTerm net term), The objects which caused the DRC. The list may be empty, and is currently limited to at most 2 objects.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:51:9	SPECIAL_OPEN	1007.44 691.35 1011.36 693.145	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:52:10	SPECIAL_OPEN	1027.04 691.175 1039.92 693.24	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:53:11	SPECIAL_OPEN	1013.04 691.08 1024.24 693.72	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:54:12	SPECIAL_OPEN	986.72 691.08 1004.08 693.72	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:55:13	SPECIAL_OPEN	947.52 681.64 983.92 684.76	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:56:14	SPECIAL_OPEN	1015.28 726.44 1024.8 729.56	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:57:15	SPECIAL_OPEN	1008.0 717.96 1031.52 720.12	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:58:16	SPECIAL_OPEN	973.84 726.44 1013.04 729.56	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:59:17	SPECIAL_OPEN	957.04 709.0 968.24 711.64	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:60:18	SPECIAL_OPEN	953.68 727.015 958.16 728.985	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:61:19	SPECIAL_OPEN	971.6 709.0 987.84 711.16	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:62:20	SPECIAL_OPEN	972.16 735.4 1016.96 738.52	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:63:21	SPECIAL_OPEN	976.64 717.48 986.72 720.6	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:64:22	SPECIAL_OPEN	963.76 744.36 1000.16 747.48	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:65:23	SPECIAL_OPEN	952.0 735.975 958.16 738.52	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:66:24	SPECIAL_OPEN	947.52 727.015 952.0 728.71	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:67:25	SPECIAL_OPEN	946.96 736.25 951.44 737.945	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:68:26	SPECIAL_OPEN	834.4 762.605 848.4 765.4	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:85:43	SPECIAL_OPEN	838.88 753.84 852.88 755.865	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:86:44	SPECIAL_OPEN	912.8 735.4 917.28 737.945	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:87:45	SPECIAL_OPEN	874.72 735.4 902.16 738.52	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:88:46	SPECIAL_OPEN	848.4 735.4 868.0 738.04	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:89:47	SPECIAL_OPEN	859.6 744.36 882.56 747.0	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:90:48	SPECIAL_OPEN	902.72 736.25 909.44 737.945	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:91:49	SPECIAL_OPEN	871.36 717.96 882.0 720.6	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:92:50	SPECIAL_OPEN	830.48 717.48 870.24 720.6	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:93:51	SPECIAL_OPEN	901.04 682.12 911.68 684.185	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:94:52	SPECIAL_OPEN	864.64 682.12 899.92 684.76	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:95:53	SPECIAL_OPEN	858.48 690.6 870.24 693.24	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:96:54	SPECIAL_OPEN	824.32 681.64 862.96 684.76	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:103:61	SPECIAL_OPEN	847.28 726.44 862.96 729.56	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:104:62	SPECIAL_OPEN	905.52 727.015 909.44 728.985	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:105:63	SPECIAL_OPEN	863.52 726.92 879.76 728.985	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:106:64	SPECIAL_OPEN	884.24 690.6 944.16 693.72	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:107:65	SPECIAL_OPEN	914.48 682.12 946.4 684.28	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:108:66	SPECIAL_OPEN	924.0 672.68 982.8 675.8	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:109:67	SPECIAL_OPEN	911.12 726.44 946.96 729.56	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:110:68	SPECIAL_OPEN	910.56 744.84 933.52 747.48	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:111:69	SPECIAL_OPEN	921.2 708.52 955.92 711.16	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:127:85	SPECIAL_OPEN	717.92 682.39 722.4 684.185	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:128:86	SPECIAL_OPEN	697.2 672.68 720.72 675.32	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:129:87	SPECIAL_OPEN	722.4 673.255 727.44 675.225	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:130:88	SPECIAL_OPEN	672.56 717.48 715.12 720.12	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:131:89	SPECIAL_OPEN	673.68 744.935 678.16 747.48	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:132:90	SPECIAL_OPEN	777.28 744.36 794.08 747.0	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:133:91	SPECIAL_OPEN	776.72 735.975 784.56 737.945	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:152:110	SPECIAL_OPEN	533.12 672.18 576.24 675.475	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:153:111	SPECIAL_OPEN	587.44 753.84 622.72 756.115	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:154:112	SPECIAL_OPEN	589.68 762.8 603.68 765.075	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:155:113	SPECIAL_OPEN	566.72 716.76 589.68 720.08	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:156:114	SPECIAL_OPEN	542.64 762.8 557.2 764.88	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:157:115	SPECIAL_OPEN	580.16 735.725 619.36 738.195	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:158:116	SPECIAL_OPEN	586.32 726.46 603.12 729.04	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:159:117	SPECIAL_OPEN	648.48 726.44 667.52 729.56	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:160:118	SPECIAL_OPEN	750.96 717.48 829.36 720.6	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:181:139	SPECIAL_OPEN	958.16 566.01 961.52 567.705	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:182:140	SPECIAL_OPEN	968.24 565.16 991.2 568.28	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:183:141	SPECIAL_OPEN	923.44 565.64 951.44 568.28	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:184:142	SPECIAL_OPEN	951.44 628.36 962.08 631.0	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:185:143	SPECIAL_OPEN	802.48 565.16 818.72 567.8	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:201:159	SPECIAL_OPEN	971.6 421.8 1020.88 424.92	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:202:160	SPECIAL_OPEN	972.16 430.76 1030.4 433.88	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:203:161	SPECIAL_OPEN	964.88 422.375 969.92 424.92	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:204:162	SPECIAL_OPEN	974.96 404.455 985.6 406.52	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:205:163	SPECIAL_OPEN	937.44 484.52 1014.72 487.64	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:206:164	SPECIAL_OPEN	936.88 431.335 943.04 433.88	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:214:172	SPECIAL_OPEN	819.84 476.13 826.0 478.11	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:215:173	SPECIAL_OPEN	802.48 529.32 814.24 531.96	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:216:174	SPECIAL_OPEN	854.56 475.56 868.0 478.68	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:217:175	SPECIAL_OPEN	814.8 529.32 852.88 532.44	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:218:176	SPECIAL_OPEN	882.0 493.48 890.4 496.6	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:219:177	SPECIAL_OPEN	881.44 476.04 894.88 478.68	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:220:178	SPECIAL_OPEN	830.48 484.52 847.28 487.16	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:221:179	SPECIAL_OPEN	879.2 448.68 892.64 451.32	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:222:180	SPECIAL_OPEN	893.76 404.36 917.84 407.0	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:223:181	SPECIAL_OPEN	901.04 413.32 912.8 415.96	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:230:188	SPECIAL_OPEN	870.24 430.76 906.64 433.88	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:231:189	SPECIAL_OPEN	823.2 404.46 827.68 406.25	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:246:204	SPECIAL_OPEN	814.8 422.55 820.4 424.34	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:247:205	SPECIAL_OPEN	805.28 413.41 842.24 415.5	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:248:206	SPECIAL_OPEN	832.16 448.68 844.48 451.32	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:250:208	SPECIAL_OPEN	832.72 421.8 879.2 424.92	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:251:209	SPECIAL_OPEN	846.72 449.255 871.36 451.32	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:252:210	SPECIAL_OPEN	844.48 457.64 873.6 460.28	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:253:211	SPECIAL_OPEN	897.12 466.6 907.2 469.145	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:254:212	SPECIAL_OPEN	916.72 422.28 930.16 424.92	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:255:213	SPECIAL_OPEN	928.48 494.055 934.08 496.6	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:256:214	SPECIAL_OPEN	915.04 413.515 930.72 415.96	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:257:215	SPECIAL_OPEN	919.52 502.44 944.16 505.08	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:266:224	SPECIAL_OPEN	692.72 565.735 697.76 568.28	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:267:225	SPECIAL_OPEN	696.08 556.68 720.72 559.32	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:268:226	SPECIAL_OPEN	721.84 556.68 734.16 559.32	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:269:227	SPECIAL_OPEN	768.88 556.68 780.08 559.32	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:270:228	SPECIAL_OPEN	596.4 547.26 618.24 549.88	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:271:229	SPECIAL_OPEN	568.96 538.28 636.72 541.38	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:272:230	SPECIAL_OPEN	545.44 628.34 598.64 630.675	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:273:231	SPECIAL_OPEN	546.0 654.78 556.64 657.4	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:274:232	SPECIAL_OPEN	561.12 619.4 572.32 621.47	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:275:233	SPECIAL_OPEN	557.2 609.98 576.24 612.6	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:276:234	SPECIAL_OPEN	584.08 601.57 597.52 603.545	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:292:250	SPECIAL_OPEN	553.28 547.72 587.44 549.88	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:293:251	SPECIAL_OPEN	575.12 646.705 579.04 648.46	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:294:252	SPECIAL_OPEN	647.92 556.2 652.96 558.745	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:295:253	SPECIAL_OPEN	663.04 556.2 695.52 559.32	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:296:254	SPECIAL_OPEN	748.16 520.36 753.2 522.905	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:297:255	SPECIAL_OPEN	761.04 520.935 766.64 523.48	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:298:256	SPECIAL_OPEN	767.76 520.36 795.2 523.48	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:299:257	SPECIAL_OPEN	720.72 529.32 793.52 531.96	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:307:265	SPECIAL_OPEN	736.96 449.16 747.6 451.14	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:308:266	SPECIAL_OPEN	712.88 458.12 742.0 460.76	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:325:283	SPECIAL_OPEN	707.84 403.88 729.12 406.52	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:344:302	SPECIAL_OPEN	585.2 511.97 594.72 514.0	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:345:303	SPECIAL_OPEN	536.48 502.46 612.08 505.56	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:346:304	SPECIAL_OPEN	589.68 529.34 614.88 532.44	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:347:305	SPECIAL_OPEN	583.52 520.9 608.16 523.0	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:348:306	SPECIAL_OPEN	658.0 467.18 672.56 469.215	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:349:307	SPECIAL_OPEN	621.04 520.36 708.96 523.48	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:350:308	SPECIAL_OPEN	647.36 511.4 730.24 514.52	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:351:309	SPECIAL_OPEN	794.64 529.895 800.24 531.865	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:352:310	SPECIAL_OPEN	713.44 565.16 801.92 568.28	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:353:311	SPECIAL_OPEN	791.84 556.68 829.92 559.32	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:355:313	SPECIAL_OPEN	685.44 664.2 696.08 666.265	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:356:314	SPECIAL_OPEN	696.64 664.2 754.88 666.84	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:373:331	SPECIAL_OPEN	479.92 753.84 494.48 756.115	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:374:332	SPECIAL_OPEN	464.24 762.605 507.92 765.075	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:375:333	SPECIAL_OPEN	403.2 744.685 418.32 746.96	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:376:334	SPECIAL_OPEN	482.16 744.94 497.28 746.96	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:377:335	SPECIAL_OPEN	510.16 771.76 524.16 774.035	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:378:336	SPECIAL_OPEN	491.12 681.66 501.76 684.28	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:379:337	SPECIAL_OPEN	507.36 699.58 525.84 702.2	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:380:338	SPECIAL_OPEN	464.8 699.58 495.04 702.2	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:381:339	SPECIAL_OPEN	431.76 699.58 454.16 702.66	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:382:340	SPECIAL_OPEN	419.44 682.12 446.32 684.74	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:383:341	SPECIAL_OPEN	467.6 682.12 478.24 684.74	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:384:342	SPECIAL_OPEN	403.2 672.7 427.28 675.8	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:385:343	SPECIAL_OPEN	465.36 691.08 488.88 694.26	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:386:344	SPECIAL_OPEN	501.2 690.06 509.6 693.7	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:387:345	SPECIAL_OPEN	443.52 690.6 460.32 693.24	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:388:346	SPECIAL_OPEN	510.16 690.06 515.76 693.14	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:392:350	SPECIAL_OPEN	425.04 708.845 510.16 711.315	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:393:351	SPECIAL_OPEN	403.76 717.5 473.2 720.275	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:394:352	SPECIAL_OPEN	479.92 682.12 490.56 684.74	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:395:353	SPECIAL_OPEN	446.88 682.12 458.08 684.28	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:396:354	SPECIAL_OPEN	414.96 726.765 428.96 729.04	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:397:355	SPECIAL_OPEN	387.52 700.31 392.0 702.1	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:408:366	SPECIAL_OPEN	393.12 682.22 396.48 683.91	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:409:367	SPECIAL_OPEN	370.16 700.02 378.56 702.1	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:410:368	SPECIAL_OPEN	358.4 682.12 370.16 684.28	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:411:369	SPECIAL_OPEN	299.04 672.68 365.12 675.8	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:412:370	SPECIAL_OPEN	330.4 699.56 369.6 702.66	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:413:371	SPECIAL_OPEN	352.24 691.08 362.88 693.72	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:414:372	SPECIAL_OPEN	329.84 717.48 395.92 720.12	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:415:373	SPECIAL_OPEN	352.24 735.88 362.88 738.04	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:416:374	SPECIAL_OPEN	276.64 708.52 365.12 711.64	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:417:375	SPECIAL_OPEN	303.52 726.92 340.48 729.54	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:418:376	SPECIAL_OPEN	339.92 690.62 350.56 693.24	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:419:377	SPECIAL_OPEN	326.48 681.64 346.08 684.28	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:420:378	SPECIAL_OPEN	372.96 709.095 395.36 711.64	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:421:379	SPECIAL_OPEN	393.12 699.58 429.52 702.2	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:422:380	SPECIAL_OPEN	386.4 726.46 412.72 729.235	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:423:381	SPECIAL_OPEN	397.04 682.12 418.88 684.76	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:424:382	SPECIAL_OPEN	394.8 690.62 428.96 693.72	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:425:383	SPECIAL_OPEN	389.76 753.645 417.76 756.115	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:429:387	SPECIAL_OPEN	246.96 673.26 267.12 675.23	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:430:388	SPECIAL_OPEN	441.28 628.36 458.08 630.98	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:431:389	SPECIAL_OPEN	489.44 627.9 522.48 630.52	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:432:390	SPECIAL_OPEN	465.92 628.36 487.76 630.98	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:433:391	SPECIAL_OPEN	479.36 636.86 498.4 639.96	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:434:392	SPECIAL_OPEN	418.88 610.44 429.52 612.5	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:435:393	SPECIAL_OPEN	505.12 655.34 508.48 657.42	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:436:394	SPECIAL_OPEN	449.68 655.24 487.76 657.86	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:437:395	SPECIAL_OPEN	489.44 646.28 516.88 648.34	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:438:396	SPECIAL_OPEN	433.44 636.86 465.92 639.48	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:446:404	SPECIAL_OPEN	416.64 628.41 435.68 631.17	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:447:405	SPECIAL_OPEN	421.68 601.02 453.6 604.25	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:448:406	SPECIAL_OPEN	409.36 601.02 420.0 603.64	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:449:407	SPECIAL_OPEN	488.32 619.4 515.2 621.56	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:450:408	SPECIAL_OPEN	467.04 636.84 478.24 639.48	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:451:409	SPECIAL_OPEN	416.64 565.18 428.96 567.8	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:452:410	SPECIAL_OPEN	417.2 592.52 431.2 594.68	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:453:411	SPECIAL_OPEN	429.52 565.18 460.88 568.26	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:454:412	SPECIAL_OPEN	445.2 592.06 455.84 594.68	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:455:413	SPECIAL_OPEN	410.48 547.72 459.2 550.49	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:456:414	SPECIAL_OPEN	438.48 538.15 457.52 540.825	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:461:419	SPECIAL_OPEN	462.0 565.69 481.6 567.75	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:462:420	SPECIAL_OPEN	427.28 574.6 456.96 577.22	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:463:421	SPECIAL_OPEN	431.76 592.06 444.64 594.68	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:464:422	SPECIAL_OPEN	414.96 583.56 431.2 586.18	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:465:423	SPECIAL_OPEN	390.32 664.3 393.68 665.99	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:466:424	SPECIAL_OPEN	374.08 664.295 381.36 666.075	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:479:437	SPECIAL_OPEN	363.44 627.9 386.4 630.52	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:480:438	SPECIAL_OPEN	287.84 654.76 337.12 657.88	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:481:439	SPECIAL_OPEN	351.68 645.82 374.64 648.92	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:482:440	SPECIAL_OPEN	338.8 636.86 374.64 639.48	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:483:441	SPECIAL_OPEN	350.0 654.78 373.52 657.88	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:484:442	SPECIAL_OPEN	374.08 655.24 385.28 657.3	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:485:443	SPECIAL_OPEN	338.24 654.76 349.44 657.4	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:486:444	SPECIAL_OPEN	325.92 646.28 339.92 648.9	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:487:445	SPECIAL_OPEN	389.76 538.28 427.28 541.38	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:488:446	SPECIAL_OPEN	381.92 636.84 424.48 639.94	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:489:447	SPECIAL_OPEN	375.76 645.82 488.32 648.92	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:490:448	SPECIAL_OPEN	386.96 627.9 414.96 630.52	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:491:449	SPECIAL_OPEN	386.4 654.76 420.56 657.88	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:512:470	SPECIAL_OPEN	453.04 511.88 465.36 513.95	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:513:471	SPECIAL_OPEN	474.88 511.23 488.88 514.65	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:514:472	SPECIAL_OPEN	463.68 529.34 481.04 531.87	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:515:473	SPECIAL_OPEN	467.6 502.92 484.96 504.985	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:516:474	SPECIAL_OPEN	475.44 493.5 485.52 496.025	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:593:551	RO_PG_UNCONNECTED_PIN	176.8 626.43 178.8 639.455	MET2	Connectivity	UnConnectedPin	Net VDD Pin: u_core_u_osc_slow_u_ro_tune4/vdd!; Direction: INOUT; Use: POWER;
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:594:552	RO_PG_UNCONNECTED_PIN	144.88 625.66 146.88 639.455	MET2	Connectivity	UnConnectedPin	Net VDD Pin: u_core_u_osc_slow_u_ro_tune4/vdd!; Direction: INOUT; Use: POWER;
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:606:564	RO_PG_UNCONNECTED_PIN	52.43 627.355 57.575 630.59	MET1	Connectivity	UnConnectedPin	Net VDD Pin: u_core_u_osc_slow_u_ro_tune4/VDD; Direction: INOUT; Use: POWER;
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:623:581	SPECIAL_OPEN	394.24 663.72 456.96 666.82	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:624:582	SPECIAL_OPEN	331.52 663.72 349.44 666.82	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:625:583	SPECIAL_OPEN	458.08 664.2 474.32 666.82	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:626:584	SPECIAL_OPEN	315.28 664.2 325.92 666.84	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:627:585	SPECIAL_OPEN	351.68 663.72 369.6 666.36	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:628:586	SPECIAL_OPEN	474.88 664.2 485.52 666.82	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:630:588	SPECIAL_OPEN	499.52 511.88 542.08 514.02	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:631:589	SPECIAL_OPEN	519.68 636.84 551.6 639.94	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:632:590	SPECIAL_OPEN	514.08 672.14 530.88 675.8	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:633:591	SPECIAL_OPEN	509.6 654.78 544.88 657.4	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:634:592	SPECIAL_OPEN	517.44 645.82 556.64 648.44	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:635:593	SPECIAL_OPEN	523.04 627.9 544.88 630.52	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:636:594	SPECIAL_OPEN	516.32 619.4 542.64 621.56	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:637:595	SPECIAL_OPEN	516.32 663.74 550.48 666.82	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:638:596	SPECIAL_OPEN	503.44 681.66 535.36 684.74	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:639:597	SPECIAL_OPEN	528.64 700.04 542.64 702.16	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:640:598	SPECIAL_OPEN	528.08 690.62 548.8 693.24	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:641:599	SPECIAL_OPEN	510.72 762.8 540.96 764.88	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:642:600	SPECIAL_OPEN	525.28 771.76 539.84 774.035	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:643:601	SPECIAL_OPEN	530.32 708.845 573.44 711.16	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:644:602	SPECIAL_OPEN	518.56 520.38 553.28 523.0	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:655:613	SPECIAL_OPEN	952.56 359.08 1009.68 362.2	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:656:614	SPECIAL_OPEN	967.12 350.12 1002.4 353.24	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:657:615	SPECIAL_OPEN	961.52 350.695 965.44 352.39	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:658:616	SPECIAL_OPEN	930.16 394.92 940.8 397.56	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:659:617	SPECIAL_OPEN	952.0 386.44 969.36 389.08	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:660:618	SPECIAL_OPEN	971.6 377.0 976.08 379.545	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:661:619	SPECIAL_OPEN	965.44 377.575 969.36 379.27	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:662:620	SPECIAL_OPEN	986.16 377.0 991.2 379.545	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:663:621	SPECIAL_OPEN	977.76 377.575 982.24 380.12	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:664:622	SPECIAL_OPEN	972.16 385.96 1019.2 389.08	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:665:623	SPECIAL_OPEN	857.36 359.08 887.6 362.2	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:666:624	SPECIAL_OPEN	851.76 350.695 856.24 352.665	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:667:625	SPECIAL_OPEN	857.92 350.6 874.72 353.24	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:668:626	SPECIAL_OPEN	805.28 386.535 809.76 389.08	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:669:627	SPECIAL_OPEN	911.12 377.0 916.16 379.545	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:670:628	SPECIAL_OPEN	803.04 395.4 823.76 397.56	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:671:629	SPECIAL_OPEN	828.8 395.4 846.72 397.56	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:678:636	SPECIAL_OPEN	848.4 394.92 901.04 397.56	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:679:637	SPECIAL_OPEN	896.56 377.48 907.2 380.12	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:680:638	SPECIAL_OPEN	906.08 386.44 923.44 389.08	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:681:639	SPECIAL_OPEN	812.56 305.89 824.32 308.42	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:699:657	SPECIAL_OPEN	923.44 377.575 929.04 379.545	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:700:658	SPECIAL_OPEN	948.08 170.92 981.12 174.04	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:701:659	SPECIAL_OPEN	949.2 188.84 964.32 191.48	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:713:671	SPECIAL_OPEN	931.84 234.215 936.88 236.76	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:714:672	SPECIAL_OPEN	955.92 234.12 986.72 236.76	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:715:673	SPECIAL_OPEN	949.76 234.215 954.8 236.76	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:716:674	SPECIAL_OPEN	919.52 171.495 924.0 174.04	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:717:675	SPECIAL_OPEN	823.2 144.06 829.36 147.16	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:718:676	SPECIAL_OPEN	870.24 153.48 885.92 155.64	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:719:677	SPECIAL_OPEN	834.4 161.96 868.0 165.08	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:720:678	SPECIAL_OPEN	872.48 180.455 883.12 182.52	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:721:679	SPECIAL_OPEN	837.2 170.92 904.96 174.04	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:722:680	SPECIAL_OPEN	871.92 188.84 921.76 191.96	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:730:688	SPECIAL_OPEN	803.6 161.96 833.28 165.08	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:731:689	SPECIAL_OPEN	864.08 216.295 874.72 218.36	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:732:690	SPECIAL_OPEN	875.28 215.72 904.4 218.84	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:733:691	SPECIAL_OPEN	877.52 233.64 909.44 236.76	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:734:692	SPECIAL_OPEN	798.56 224.68 848.4 227.8	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:735:693	SPECIAL_OPEN	853.44 198.28 876.4 200.92	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:736:694	SPECIAL_OPEN	799.12 206.76 887.6 209.88	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:737:695	SPECIAL_OPEN	908.32 180.36 933.52 183.0	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:738:696	SPECIAL_OPEN	922.88 188.84 948.64 191.96	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:739:697	SPECIAL_OPEN	927.36 171.495 934.64 173.275	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:740:698	SPECIAL_OPEN	918.96 234.12 929.6 236.76	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:741:699	SPECIAL_OPEN	735.28 305.32 773.36 308.44	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:742:700	SPECIAL_OPEN	750.96 377.0 790.16 379.64	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:743:701	SPECIAL_OPEN	782.32 279.1 790.16 281.54	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:744:702	SPECIAL_OPEN	777.28 297.125 783.44 298.905	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:745:703	SPECIAL_OPEN	758.8 287.88 771.12 290.52	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:746:704	SPECIAL_OPEN	756.0 296.935 760.48 299.48	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:747:705	SPECIAL_OPEN	728.0 278.44 778.96 281.56	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:756:714	SPECIAL_OPEN	694.96 305.895 698.88 307.865	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:757:715	SPECIAL_OPEN	694.4 314.28 759.92 317.4	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:758:716	SPECIAL_OPEN	702.24 305.895 715.68 307.865	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:759:717	SPECIAL_OPEN	669.76 278.44 676.48 280.985	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:760:718	SPECIAL_OPEN	673.68 368.615 678.16 370.31	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:761:719	SPECIAL_OPEN	680.4 368.04 716.24 371.16	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:762:720	SPECIAL_OPEN	722.96 359.56 735.84 362.2	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:778:736	SPECIAL_OPEN	650.16 296.36 663.04 299.0	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:779:737	SPECIAL_OPEN	623.84 368.52 637.84 371.16	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:780:738	SPECIAL_OPEN	663.04 377.0 677.04 379.64	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:781:739	SPECIAL_OPEN	642.88 269.48 671.44 272.12	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:782:740	SPECIAL_OPEN	659.12 368.04 671.44 370.68	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:783:741	SPECIAL_OPEN	640.64 359.08 678.72 362.2	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:795:753	SPECIAL_OPEN	767.76 144.04 790.72 147.16	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:796:754	SPECIAL_OPEN	684.88 233.64 754.32 236.76	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:797:755	SPECIAL_OPEN	678.72 234.215 683.2 236.76	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:798:756	SPECIAL_OPEN	733.04 153.0 768.32 155.64	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:799:757	SPECIAL_OPEN	681.52 161.96 729.12 165.08	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:800:758	SPECIAL_OPEN	677.04 153.575 680.96 155.37	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:801:759	SPECIAL_OPEN	669.76 189.32 698.88 191.96	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:802:760	SPECIAL_OPEN	711.76 179.88 740.88 183.0	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:823:781	SPECIAL_OPEN	644.56 260.52 656.32 263.16	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:824:782	SPECIAL_OPEN	659.12 234.12 677.04 236.76	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:825:783	SPECIAL_OPEN	663.04 153.0 674.8 155.64	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:826:784	SPECIAL_OPEN	646.8 179.88 667.52 182.52	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:828:786	SPECIAL_OPEN	789.6 216.2 812.56 218.84	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:829:787	SPECIAL_OPEN	790.16 368.52 813.12 371.16	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:830:788	SPECIAL_OPEN	795.2 153.02 801.36 156.1	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:853:811	SPECIAL_OPEN	867.44 108.68 890.96 111.32	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:854:812	SPECIAL_OPEN	698.32 117.18 704.48 119.62	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:855:813	SPECIAL_OPEN	756.0 135.655 767.2 137.72	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:911:869	SPECIAL_OPEN	449.12 162.08 474.88 164.755	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:981:939	SPECIAL_OPEN	113.12 395.04 197.12 397.715	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:982:940	SPECIAL_OPEN	40.32 368.04 127.68 371.14	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:991:949	RO_PG_UNCONNECTED_PIN	144.88 161.845 146.88 175.64	MET2	Connectivity	UnConnectedPin	Net VDD Pin: u_core_u_osc_fast_u_ro_tune4/vdd!; Direction: INOUT; Use: POWER;
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:992:950	RO_PG_UNCONNECTED_PIN	176.8 161.845 178.8 174.87	MET2	Connectivity	UnConnectedPin	Net VDD Pin: u_core_u_osc_fast_u_ro_tune4/vdd!; Direction: INOUT; Use: POWER;
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:1011:969	RO_PG_UNCONNECTED_PIN	52.43 170.71 57.575 173.945	MET1	Connectivity	UnConnectedPin	Net VDD Pin: u_core_u_osc_fast_u_ro_tune4/VDD; Direction: INOUT; Use: POWER;
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:1042:1000	SPECIAL_OPEN	16.16 16.16 1045.04 785.76	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:1044:RO_PG_MARKER_RO_UNCONNECTED_COUNT=6
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:1046:RO_PG_MARKER_SPECIAL_OPEN_COUNT=316
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_before_hookup.rpt:1048:RO_PG_PROBE_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_failed.rpt:2:STATUS=FAIL
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_failed.rpt:3:ERROR=MPTDC_ROUTE_GATE_FAILED: report=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_failed.rpt:5:MPTDC_ROUTE_GATE_FAILED: report=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_failed.rpt:7:"error "MPTDC_ROUTE_GATE_FAILED: report=$rpt""
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/cts_clk_sys_spec_source.rpt:6:SOURCE_SELECTED_SPEC_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/cts_clk_sys_spec_source.rpt:11:CTS_SPEC_SOURCE_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_ro_pg_hookup.rpt:4:SCHEMA_marker_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_ro_pg_hookup.rpt:6:SCHEMA_sWire_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_ro_pg_hookup.rpt:8:SCHEMA_term_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_ro_pg_hookup.rpt:10:SCHEMA_pin_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_ro_pg_hookup.rpt:12:SCHEMA_pinShape_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_ro_pg_hookup.rpt:16:TOP_NAME_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_ro_pg_hookup.rpt:22:CORE_BOX_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_ro_pg_hookup.rpt:28:PG_TERM_NAMES_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_ro_pg_hookup.rpt:34:PG_TERM_NETS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_ro_pg_hookup.rpt:40:PG_TERM_LAYERS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_ro_pg_hookup.rpt:46:VDD_PGTERM_NAMES_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_ro_pg_hookup.rpt:52:VSS_PGTERM_NAMES_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_ro_pg_hookup.rpt:58:VDD_SWIRE_COUNT_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_ro_pg_hookup.rpt:64:VSS_SWIRE_COUNT_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_ro_pg_hookup.rpt:141:VERIFY_SPECIAL_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/POST_FILLER_POST_SROUTE_ecoRoute_fix_drc_markers_schema.rpt:2:marker: DRC Marker
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/POST_FILLER_POST_SROUTE_ecoRoute_fix_drc_markers_schema.rpt:19:message: string, DRC marker message
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/POST_FILLER_POST_SROUTE_ecoRoute_fix_drc_markers_schema.rpt:20:messageId: int, DRC marker message ID
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/POST_FILLER_POST_SROUTE_ecoRoute_fix_drc_markers_schema.rpt:21:objType: enum(antennaData antennaModel bndry bump bumpGrid bumpTerm bus busGuide busSinkGroup cellDensity densityShape fPlan foreign gCellGridDef group guiLine guiPoly guiRect guiText hInst hInstTerm hNet hTerm head inst instTerm io layer layerRule layerShape libCell marker net netGroup pBlkg pWire pd pgInstTerm pin pinGroup pinGuide pinShape pkgComponent pkgObject prop ptn ptnCell ptnPinBlkg rBlkg resistor resizeBlkg routeType row rule sViaInst sWire sdp shape shapeVia site stackViaRule term text topCell trackDef vCell vWire via viaInst viaRuleGenerate whatIfVia whatIfWire wire), Object type: DRC Marker
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/POST_FILLER_POST_SROUTE_ecoRoute_fix_drc_markers_schema.rpt:22:objects: objList(bump inst instTerm net term), The objects which caused the DRC. The list may be empty, and is currently limited to at most 2 objects.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_status.rpt:2:ROUTE_GATE_RECOVERY_INITIAL_DRC=12
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_status.rpt:3:ROUTE_GATE_RECOVERY_INITIAL_SHORTS=7
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_status.rpt:8:ROUTE_GATE_SROUTE_MODE_CORE_PIN_STOP_ROUTE_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_status.rpt:10:ROUTE_GATE_SROUTE_MODE_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_status.rpt:16:ROUTE_GATE_SROUTE_ATTEMPT_1_COMMAND_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_status.rpt:17:ROUTE_GATE_SROUTE_ATTEMPT_1_STATUS=REVIEW_REQUIRED
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_status.rpt:19:ROUTE_GATE_SROUTE_ATTEMPT_1_OPEN_PORTS=48
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_status.rpt:20:ROUTE_GATE_SROUTE_ATTEMPT_1_BLOCK_OPEN_PORTS=24
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_status.rpt:21:ROUTE_GATE_SROUTE_ATTEMPT_1_CORE_OPEN_PORTS=24
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_status.rpt:22:ROUTE_GATE_SROUTE_ATTEMPT_1_POWER_BUMP_OPEN_PORTS=0
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_status.rpt:24:ROUTE_GATE_SROUTE_STATUS=FAIL
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_status.rpt:25:ROUTE_GATE_SROUTE_RECOVERY_COMMAND_STATUS=FAIL
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_status.rpt:28:ROUTE_GATE_RECOVERY_ATTEMPT_ROUTER_DRC=13
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_status.rpt:29:ROUTE_GATE_RECOVERY_ATTEMPT_ROUTER_SHORTS=7
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_status.rpt:30:ROUTE_GATE_RECOVERY_ATTEMPT_VERIFY_DRC=12
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_status.rpt:31:ROUTE_GATE_RECOVERY_ATTEMPT_VERIFY_SHORTS=7
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_status.rpt:32:ROUTE_GATE_RECOVERY_ATTEMPT_DRC=12
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_status.rpt:33:ROUTE_GATE_RECOVERY_ATTEMPT_SHORTS=7
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_status.rpt:35:ROUTE_GATE_RECOVERY_ATTEMPT_STATUS=REVIEW_REQUIRED
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_status.rpt:38:ROUTE_GATE_RECOVERY_ATTEMPT_ROUTER_DRC=9
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_status.rpt:39:ROUTE_GATE_RECOVERY_ATTEMPT_ROUTER_SHORTS=6
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_status.rpt:40:ROUTE_GATE_RECOVERY_ATTEMPT_VERIFY_DRC=9
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_status.rpt:41:ROUTE_GATE_RECOVERY_ATTEMPT_VERIFY_SHORTS=4
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_status.rpt:42:ROUTE_GATE_RECOVERY_ATTEMPT_DRC=9
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_status.rpt:43:ROUTE_GATE_RECOVERY_ATTEMPT_SHORTS=4
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_status.rpt:45:ROUTE_GATE_RECOVERY_ATTEMPT_STATUS=REVIEW_REQUIRED
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_status.rpt:46:ROUTE_GATE_RECOVERY_STATUS=REVIEW_REQUIRED
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:8:Path 1: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:40:Path 2: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:72:Path 3: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:104:Path 4: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:136:Path 5: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:168:Path 6: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:200:Path 7: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:232:Path 8: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:264:Path 9: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:296:Path 10: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:328:Path 11: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:360:Path 12: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:392:Path 13: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:424:Path 14: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:456:Path 15: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:488:Path 16: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:520:Path 17: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:552:Path 18: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:584:Path 19: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:616:Path 20: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:648:Path 21: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:680:Path 22: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:712:Path 23: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:744:Path 24: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:776:Path 25: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:808:Path 26: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:840:Path 27: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:872:Path 28: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:904:Path 29: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:936:Path 30: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:968:Path 31: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:1000:Path 32: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:1032:Path 33: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:1064:Path 34: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:1096:Path 35: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:1128:Path 36: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:1160:Path 37: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:1192:Path 38: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:1224:Path 39: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:1256:Path 40: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:1288:Path 41: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:1320:Path 42: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:1352:Path 43: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:1384:Path 44: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:1416:Path 45: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:1448:Path 46: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:1480:Path 47: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:1512:Path 48: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:1544:Path 49: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:1576:Path 50: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:1609:Path 51: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:1642:Path 52: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:1675:Path 53: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:1708:Path 54: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:1741:Path 55: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:1774:Path 56: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:1807:Path 57: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:1840:Path 58: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:1873:Path 59: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:1906:Path 60: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:1939:Path 61: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:1972:Path 62: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:2005:Path 63: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:2038:Path 64: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:2071:Path 65: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:2104:Path 66: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:2137:Path 67: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:2170:Path 68: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:2203:Path 69: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:2236:Path 70: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:2269:Path 71: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:2302:Path 72: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:2335:Path 73: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:2368:Path 74: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:2401:Path 75: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:2434:Path 76: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:2467:Path 77: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:2500:Path 78: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:2533:Path 79: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:2566:Path 80: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:2599:Path 81: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:2632:Path 82: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:2665:Path 83: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:2698:Path 84: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:2731:Path 85: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:2764:Path 86: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:2797:Path 87: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:2830:Path 88: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:2863:Path 89: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:2896:Path 90: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:2929:Path 91: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:2962:Path 92: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:2995:Path 93: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:3028:Path 94: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:3061:Path 95: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:3094:Path 96: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:3127:Path 97: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:3160:Path 98: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:3193:Path 99: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts_top100.rpt:3226:Path 100: VIOLATED Setup Check with Pin u_core_u_hit_capture_bridge_snapshot_q_
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_setup_pass_1_timing.rpt:71:|           WNS (ns):| -0.019  | -0.019  |   N/A   |
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_setup_pass_1_timing.rpt:72:|           TNS (ns):| -0.131  | -0.131  |   N/A   |
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_halo_status.rpt:4:RO_HALO_STATUS=SKIPPED
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/POST_FILLER_PRE_SROUTE_ecoRoute_target_markers_schema.rpt:2:marker: DRC Marker
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/POST_FILLER_PRE_SROUTE_ecoRoute_target_markers_schema.rpt:19:message: string, DRC marker message
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/POST_FILLER_PRE_SROUTE_ecoRoute_target_markers_schema.rpt:20:messageId: int, DRC marker message ID
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/POST_FILLER_PRE_SROUTE_ecoRoute_target_markers_schema.rpt:21:objType: enum(antennaData antennaModel bndry bump bumpGrid bumpTerm bus busGuide busSinkGroup cellDensity densityShape fPlan foreign gCellGridDef group guiLine guiPoly guiRect guiText hInst hInstTerm hNet hTerm head inst instTerm io layer layerRule layerShape libCell marker net netGroup pBlkg pWire pd pgInstTerm pin pinGroup pinGuide pinShape pkgComponent pkgObject prop ptn ptnCell ptnPinBlkg rBlkg resistor resizeBlkg routeType row rule sViaInst sWire sdp shape shapeVia site stackViaRule term text topCell trackDef vCell vWire via viaInst viaRuleGenerate whatIfVia whatIfWire wire), Object type: DRC Marker
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/POST_FILLER_PRE_SROUTE_ecoRoute_target_markers_schema.rpt:22:objects: objList(bump inst instTerm net term), The objects which caused the DRC. The list may be empty, and is currently limited to at most 2 objects.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_connectivity_commands.rpt:5:STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_connectivity_commands.rpt:7:STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_connectivity_commands.rpt:9:STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_connectivity_commands.rpt:11:STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_connectivity_commands.rpt:13:STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_connectivity_commands.rpt:15:STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_connectivity_commands.rpt:17:STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_connectivity_commands.rpt:19:STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_connectivity_commands.rpt:22:UNCONNECTED_STDCELL_PG_PINS=DEFER_TO_POSTROUTE_CONNECTIVITY_GATE
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_connectivity_commands.rpt:23:UNCONNECTED_RO_PG_PINS=DEFER_TO_POSTROUTE_CONNECTIVITY_GATE
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_connectivity_commands.rpt:24:PG_OPENS=DEFER_TO_POSTROUTE_CONNECTIVITY_GATE
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_connectivity_commands.rpt:25:PG_SHORTS=DEFER_TO_POSTROUTE_CONNECTIVITY_GATE
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_import_source_gate.rpt:7:MPTDC_RO_LEF_SIZE_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/source_check.rpt:1:MPTDC_DIGITAL_SIGNOFF_SOURCE_CHECK=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/source_check.rpt:3:MPTDC_TC_PNR_CLOSURE=DEFERRED
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/source_check.rpt:4:SETUP_STATUS_WC=DEFERRED evidence=scope_tc_only
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/source_check.rpt:5:HOLD_STATUS_BC=DEFERRED evidence=scope_tc_only
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/source_check.rpt:6:RO_1GHZ_STRESS_STATUS=DEFERRED evidence=scope_tc_only
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/source_check.rpt:7:RO_IMPORT_SOURCE_GATE=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/source_check.rpt:8:ROW_INFRA_POLICY=NO_DEDICATED_CORE_TAP_ENDCAP_PENDING_DRC_LVS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/source_check.rpt:9:ROW_INFRA_STATUS=PROVISIONAL
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/source_check.rpt:12:DIGITAL_PNR_SIGNOFF=PROVISIONAL
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/source_check.rpt:15:PROVISIONAL_ROW_CLASSES=tap endcap_left endcap_right
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/effective_sdc_audit.rpt:15:TCLCMD_917_CLASSIFICATION=SEE_INNOVUS_LOG_AND_SDC_COMMAND_FAILURES
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pre_pnr_gate.rpt:1:PRE_PNR_GATE=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pre_pnr_gate.rpt:4:GENUS_WNS_MARGIN_LOW=YES
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_buffer_status.rpt:1:SLOW_ISO_COUNT expected=8 actual=8 status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_buffer_status.rpt:2:SLOW_DRIVER_COUNT expected=8 actual=8 status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_buffer_status.rpt:3:FAST_ISO_COUNT expected=8 actual=8 status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_buffer_status.rpt:4:FAST_DRIVER_COUNT expected=8 actual=8 status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_buffer_status.rpt:12:PHASE_BUFFER_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_post_import.rpt:56:|           WNS (ns):|  0.025  |  0.025  |  1.730  |
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_post_import.rpt:57:|           TNS (ns):|  0.000  |  0.000  |  0.000  |
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_buffer_placement_constraints.rpt:3:status=REVIEW_REQUIRED
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:2: *** Starting Verify DRC (MEM: 3178.2) ***
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:4:  VERIFY DRC ...... Starting Verification
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:5:  VERIFY DRC ...... Initializing
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:6:  VERIFY DRC ...... Deleting Existing Violations
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:7:  VERIFY DRC ...... Creating Sub-Areas
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:8:  VERIFY DRC ...... Using new threading
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:9:  VERIFY DRC ...... Sub-Area: {0.000 0.000 213.440 202.400} 1 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:10:  VERIFY DRC ...... Sub-Area : 1 complete 4 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:11:  VERIFY DRC ...... Sub-Area: {213.440 0.000 426.880 202.400} 2 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:12:  VERIFY DRC ...... Sub-Area : 2 complete 0 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:13:  VERIFY DRC ...... Sub-Area: {426.880 0.000 640.320 202.400} 3 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:14:  VERIFY DRC ...... Sub-Area : 3 complete 0 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:15:  VERIFY DRC ...... Sub-Area: {640.320 0.000 853.760 202.400} 4 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:16:  VERIFY DRC ...... Sub-Area : 4 complete 0 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:17:  VERIFY DRC ...... Sub-Area: {853.760 0.000 1061.200 202.400} 5 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:18:  VERIFY DRC ...... Sub-Area : 5 complete 0 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:19:  VERIFY DRC ...... Sub-Area: {0.000 202.400 213.440 404.800} 6 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:20:  VERIFY DRC ...... Sub-Area : 6 complete 0 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:21:  VERIFY DRC ...... Sub-Area: {213.440 202.400 426.880 404.800} 7 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:22:  VERIFY DRC ...... Sub-Area : 7 complete 0 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:23:  VERIFY DRC ...... Sub-Area: {426.880 202.400 640.320 404.800} 8 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:24:  VERIFY DRC ...... Sub-Area : 8 complete 0 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:25:  VERIFY DRC ...... Sub-Area: {640.320 202.400 853.760 404.800} 9 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:26:  VERIFY DRC ...... Sub-Area : 9 complete 0 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:27:  VERIFY DRC ...... Sub-Area: {853.760 202.400 1061.200 404.800} 10 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:28:  VERIFY DRC ...... Sub-Area : 10 complete 0 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:29:  VERIFY DRC ...... Sub-Area: {0.000 404.800 213.440 607.200} 11 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:30:  VERIFY DRC ...... Sub-Area : 11 complete 0 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:31:  VERIFY DRC ...... Sub-Area: {213.440 404.800 426.880 607.200} 12 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:32:  VERIFY DRC ...... Sub-Area : 12 complete 3 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:33:  VERIFY DRC ...... Sub-Area: {426.880 404.800 640.320 607.200} 13 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:34:  VERIFY DRC ...... Sub-Area : 13 complete 1 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:35:  VERIFY DRC ...... Sub-Area: {640.320 404.800 853.760 607.200} 14 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:36:  VERIFY DRC ...... Sub-Area : 14 complete 0 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:37:  VERIFY DRC ...... Sub-Area: {853.760 404.800 1061.200 607.200} 15 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:38:  VERIFY DRC ...... Sub-Area : 15 complete 0 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:39:  VERIFY DRC ...... Sub-Area: {0.000 607.200 213.440 801.920} 16 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:40:  VERIFY DRC ...... Sub-Area : 16 complete 1 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:41:  VERIFY DRC ...... Sub-Area: {213.440 607.200 426.880 801.920} 17 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:42:  VERIFY DRC ...... Sub-Area : 17 complete 0 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:43:  VERIFY DRC ...... Sub-Area: {426.880 607.200 640.320 801.920} 18 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:44:  VERIFY DRC ...... Sub-Area : 18 complete 0 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:45:  VERIFY DRC ...... Sub-Area: {640.320 607.200 853.760 801.920} 19 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:46:  VERIFY DRC ...... Sub-Area : 19 complete 0 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:47:  VERIFY DRC ...... Sub-Area: {853.760 607.200 1061.200 801.920} 20 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:48:  VERIFY DRC ...... Sub-Area : 20 complete 0 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc.rpt:58: *** End Verify DRC (CPU TIME: 0:00:06.6  ELAPSED TIME: 0:00:07.0  MEM: 256.1M) ***
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_connectivity_gate.rpt:1:UNCONNECTED_STDCELL_PG_PINS=REVIEW_AFTER_INNOVUS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_connectivity_gate.rpt:2:UNCONNECTED_RO_PG_PINS=REVIEW_AFTER_INNOVUS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_connectivity_gate.rpt:3:PG_SHORTS=REVIEW_AFTER_INNOVUS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_connectivity_gate.rpt:4:PG_OPENS=REVIEW_AFTER_INNOVUS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_physical_matrix_status.rpt:18:PD_MATRIX_ESSENTIAL_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_physical_matrix_status.rpt:19:PD_MATRIX_REGULARITY=FAIL
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_physical_matrix_status.rpt:20:PD_PHYSICAL_MATRIX_GATE_STATUS=REVIEW_REQUIRED
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_physical_matrix_status.rpt:21:PD_PHYSICAL_MATRIX_STATUS=REVIEW_REQUIRED
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_physical_status.rpt:9:ADD_RING_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_physical_status.rpt:12:ADD_STRIPE_VERTICAL_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_physical_status.rpt:15:ADD_STRIPE_HORIZONTAL_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_physical_status.rpt:17:PRE_ROUTE_PG_SROUTE_MODE_STATUS=SKIPPED
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_physical_status.rpt:19:SROUTE_STATUS=SKIPPED
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_physical_status.rpt:24:BLOCK_PG_PIN_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_physical_status.rpt:26:BLOCK_PG_STITCH_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_physical_status.rpt:29:SROUTE_EFFECTIVE_STATUS=SKIPPED
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_physical_status.rpt:31:SROUTE_EFFECTIVE_OPEN_PORTS=0
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_physical_status.rpt:33:SROUTE_PREPLACE_PROGRESS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_physical_status.rpt:38:RO_PG_PIN_QUERY_STATUS=FAIL
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_physical_status.rpt:40:SPECIAL_CONNECTIVITY_CAPTURE_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_physical_status.rpt:43:SPECIAL_NET_OPENS=PARSED_FROM_VERIFY_CONNECTIVITY
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_physical_status.rpt:44:SPECIAL_NET_SHORTS=PARSED_FROM_VERIFY_CONNECTIVITY
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_physical_status.rpt:45:UNCONNECTED_STDCELL_PG_PINS=PARSED_FROM_VERIFY_CONNECTIVITY
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_physical_status.rpt:46:UNCONNECTED_RO_PG_PINS=PARSED_FROM_VERIFY_CONNECTIVITY
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_physical_status.rpt:51:PREPLACE_PRIMITIVE_PG_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_physical_status.rpt:52:PG_PHYSICAL_STATUS=PROVISIONAL
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_physical_status.rpt:53:PG_PHYSICAL_PROVISIONAL_REASON=pre_place_verify_connectivity_requires_placed_cells; route_stage_rechecks_regular_and_special_connectivity; sroute_open_ports_deferred_to_route_stage; ro_pg_pin_query_deferred_to_route_connectivity_recheck
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_physical_status.rpt:54:MPTDC_ALLOW_PROVISIONAL_PREPLACE_PG=1
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_sroute_marker_schema.rpt:2:marker: DRC Marker
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_sroute_marker_schema.rpt:19:message: string, DRC marker message
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_sroute_marker_schema.rpt:20:messageId: int, DRC marker message ID
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_sroute_marker_schema.rpt:21:objType: enum(antennaData antennaModel bndry bump bumpGrid bumpTerm bus busGuide busSinkGroup cellDensity densityShape fPlan foreign gCellGridDef group guiLine guiPoly guiRect guiText hInst hInstTerm hNet hTerm head inst instTerm io layer layerRule layerShape libCell marker net netGroup pBlkg pWire pd pgInstTerm pin pinGroup pinGuide pinShape pkgComponent pkgObject prop ptn ptnCell ptnPinBlkg rBlkg resistor resizeBlkg routeType row rule sViaInst sWire sdp shape shapeVia site stackViaRule term text topCell trackDef vCell vWire via viaInst viaRuleGenerate whatIfVia whatIfWire wire), Object type: DRC Marker
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_sroute_marker_schema.rpt:22:objects: objList(bump inst instTerm net term), The objects which caused the DRC. The list may be empty, and is currently limited to at most 2 objects.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_macro_status.rpt:13:RO_MACRO_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_macro_status.rpt:15:RO_PHASE_PLACEMENT_STATUS=PROVISIONAL_UNTIL_PHASE_BUFFER_AUDIT
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_gate_failure_drc_markers_schema.rpt:2:marker: DRC Marker
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_gate_failure_drc_markers_schema.rpt:19:message: string, DRC marker message
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_gate_failure_drc_markers_schema.rpt:20:messageId: int, DRC marker message ID
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_gate_failure_drc_markers_schema.rpt:21:objType: enum(antennaData antennaModel bndry bump bumpGrid bumpTerm bus busGuide busSinkGroup cellDensity densityShape fPlan foreign gCellGridDef group guiLine guiPoly guiRect guiText hInst hInstTerm hNet hTerm head inst instTerm io layer layerRule layerShape libCell marker net netGroup pBlkg pWire pd pgInstTerm pin pinGroup pinGuide pinShape pkgComponent pkgObject prop ptn ptnCell ptnPinBlkg rBlkg resistor resizeBlkg routeType row rule sViaInst sWire sdp shape shapeVia site stackViaRule term text topCell trackDef vCell vWire via viaInst viaRuleGenerate whatIfVia whatIfWire wire), Object type: DRC Marker
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_gate_failure_drc_markers_schema.rpt:22:objects: objList(bump inst instTerm net term), The objects which caused the DRC. The list may be empty, and is currently limited to at most 2 objects.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt:1:ROUTE_STATUS=FAIL
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt:2:ROUTE_IMPLEMENTATION_STATUS=FAIL
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt:3:INNOVUS_VERIFY_DRC_STATUS=FAIL
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt:4:FOUNDRY_DRC_STATUS=DEFERRED
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt:5:GEOMETRY_DRC_VIOLATIONS=9
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt:6:SHORTS=4
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt:7:ROUTER_TRANSCRIPT_DRC=9
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt:8:ROUTER_TRANSCRIPT_SHORTS=6
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt:9:ROUTER_TRANSCRIPT_STATUS=FAIL
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt:11:INNOVUS_VERIFY_DRC_VIOLATIONS_RAW=9
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt:12:INNOVUS_VERIFY_DRC_SHORTS_RAW=4
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt:17:REGULAR_NET_OPENS=0
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt:18:SPECIAL_NET_OPENS=NONZERO_OR_UNPARSED
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt:22:ANTENNA_STATUS=PROVISIONAL_WITH_LEF_ANTENNA_COMPLETENESS_REVIEW
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt:23:ROUTE_DRC_REVIEW_CONTINUE_STATUS=DISABLED
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt:24:ROUTE_DRC_REVIEW_CONTINUE_ENV=MPTDC_ALLOW_ROUTE_DRC_REVIEW_CONTINUE
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt:25:ROUTE_DRC_REVIEW_MAX_VIOLATIONS=5
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt:26:ROUTE_DRC_REVIEW_ALLOWED_CLASSES=Mar
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt:27:ROUTE_DRC_REVIEW_CLASS_STATUS=FAIL
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt:28:ROUTE_DRC_REVIEW_CLASS_REASON=disallowed_classes:Short=4,MetSpc=1
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt:29:ROUTE_DRC_REVIEW_CLASS_COUNTS=Short=4 Mar=4 MetSpc=1
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt:30:ROUTE_DRC_CLASS_COUNTS=Short 4 Mar 4 MetSpc 1
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt:31:DRC_MARKER_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc_markers.tsv
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt:32:ROUTE_GATE_FAILURE_MARKER_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_gate_failure_drc_markers.tsv
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt:33:ROUTE_GATE_FAILURE_DEF=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/def/04_route_failed.def
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt:34:ROUTE_GATE_FAILURE_CHECKPOINT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/checkpoints/04_route_failed.enc
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt:35:ROUTE_GATE_FAILURE_CHECKPOINT_DAT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/checkpoints/04_route_failed.enc.dat
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt:36:ROUTE_GATE_FAILURE_DEF_SAVE_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt:37:ROUTE_GATE_FAILURE_CHECKPOINT_SAVE_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt:38:ROUTE_GATE_FAILURE_CHECKPOINT_SAVE_ERROR=0
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_status.rpt:39:ROUTE_GATE_FAILURE_CHECKPOINT_DAT_EXISTS=1
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/row_infra_policy.rpt:1:ROW_INFRA_POLICY=NO_DEDICATED_CORE_TAP_ENDCAP_PENDING_DRC_LVS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/row_infra_policy.rpt:2:ROW_INFRA_STATUS=PROVISIONAL
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/row_infra_policy.rpt:5:DIGITAL_PNR_SIGNOFF=PROVISIONAL
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/row_infra_policy.rpt:7:TAP_POLICY=NO_DEDICATED_MASTER_PENDING_DRC_LVS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/row_infra_policy.rpt:8:ENDCAP_LEFT_POLICY=NO_DEDICATED_MASTER_PENDING_DRC_LVS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/row_infra_policy.rpt:9:ENDCAP_RIGHT_POLICY=NO_DEDICATED_MASTER_PENDING_DRC_LVS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/row_infra_policy.rpt:10:PROVISIONAL_CLASSES=tap endcap_left endcap_right
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/row_infra_policy.rpt:18:EVIDENCE_PACKAGE_STATUS=EXTERNAL_SERVER_AUDIT_REQUIRED
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_before_sroute.rpt:4:SCHEMA_marker_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_before_sroute.rpt:6:SCHEMA_sWire_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_before_sroute.rpt:8:SCHEMA_term_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_before_sroute.rpt:10:SCHEMA_pin_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_before_sroute.rpt:12:SCHEMA_pinShape_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_before_sroute.rpt:16:TOP_NAME_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_before_sroute.rpt:22:CORE_BOX_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_before_sroute.rpt:28:PG_TERM_NAMES_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_before_sroute.rpt:34:PG_TERM_NETS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_before_sroute.rpt:40:PG_TERM_LAYERS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_before_sroute.rpt:46:VDD_PGTERM_NAMES_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_before_sroute.rpt:52:VSS_PGTERM_NAMES_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_before_sroute.rpt:58:VDD_SWIRE_COUNT_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_before_sroute.rpt:64:VSS_SWIRE_COUNT_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_before_sroute.rpt:141:VERIFY_SPECIAL_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/io_pin_placement_summary.md:3:REPORT_STATUS=OK
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:8:Path 1: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:64:Path 2: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:124:Path 3: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:180:Path 4: VIOLATED Setup Check with Pin u_core_gen_pd_row[2].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:236:Path 5: VIOLATED Setup Check with Pin u_core_gen_pd_row[3].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:292:Path 6: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:350:Path 7: VIOLATED Setup Check with Pin u_core_gen_pd_row[2].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:406:Path 8: VIOLATED Setup Check with Pin u_core_gen_pd_row[4].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:462:Path 9: VIOLATED Setup Check with Pin u_core_gen_pd_row[0].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:518:Path 10: VIOLATED Setup Check with Pin u_core_gen_pd_row[0].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:574:Path 11: VIOLATED Setup Check with Pin u_core_gen_pd_row[6].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:630:Path 12: VIOLATED Setup Check with Pin u_core_gen_pd_row[7].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:686:Path 13: VIOLATED Setup Check with Pin u_core_gen_pd_row[3].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:742:Path 14: VIOLATED Setup Check with Pin u_core_gen_pd_row[3].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:800:Path 15: VIOLATED Setup Check with Pin u_core_gen_pd_row[0].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:858:Path 16: VIOLATED Setup Check with Pin u_core_gen_pd_row[5].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:914:Path 17: VIOLATED Setup Check with Pin u_core_gen_pd_row[2].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:972:Path 18: VIOLATED Setup Check with Pin u_core_gen_pd_row[4].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:1028:Path 19: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:1084:Path 20: VIOLATED Setup Check with Pin u_core_gen_pd_row[6].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:1140:Path 21: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:1196:Path 22: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[1].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:1256:Path 23: VIOLATED Setup Check with Pin u_core_gen_pd_row[0].gen_pd_col[1].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:1316:Path 24: VIOLATED Setup Check with Pin u_core_gen_pd_row[5].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:1372:Path 25: VIOLATED Setup Check with Pin u_core_gen_pd_row[0].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:1428:Path 26: VIOLATED Setup Check with Pin u_core_gen_pd_row[7].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:1484:Path 27: VIOLATED Setup Check with Pin u_core_gen_pd_row[2].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:1540:Path 28: VIOLATED Setup Check with Pin u_core_gen_pd_row[3].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:1596:Path 29: VIOLATED Setup Check with Pin u_core_gen_pd_row[4].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:1652:Path 30: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[2].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:1710:Path 31: VIOLATED Setup Check with Pin u_core_gen_pd_row[3].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:1768:Path 32: VIOLATED Setup Check with Pin u_core_gen_pd_row[2].gen_pd_col[6].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:1824:Path 33: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[2].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:1882:Path 34: VIOLATED Setup Check with Pin u_core_gen_pd_row[3].gen_pd_col[0].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:1940:Path 35: VIOLATED Setup Check with Pin u_core_gen_pd_row[5].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:1996:Path 36: VIOLATED Setup Check with Pin u_core_gen_pd_row[0].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:2052:Path 37: VIOLATED Setup Check with Pin u_core_gen_pd_row[2].gen_pd_col[7].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:2110:Path 38: VIOLATED Setup Check with Pin u_core_gen_pd_row[7].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:2168:Path 39: VIOLATED Setup Check with Pin u_core_gen_pd_row[0].gen_pd_col[1].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:2226:Path 40: VIOLATED Setup Check with Pin u_core_gen_pd_row[0].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:2284:Path 41: VIOLATED Setup Check with Pin u_core_gen_pd_row[2].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:2340:Path 42: VIOLATED Setup Check with Pin u_core_gen_pd_row[3].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:2396:Path 43: VIOLATED Setup Check with Pin u_core_gen_pd_row[2].gen_pd_col[5].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:2452:Path 44: VIOLATED Setup Check with Pin u_core_gen_pd_row[6].gen_pd_col[5].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:2508:Path 45: VIOLATED Setup Check with Pin u_core_gen_pd_row[5].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:2566:Path 46: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[1].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:2624:Path 47: VIOLATED Setup Check with Pin u_core_gen_pd_row[4].gen_pd_col[3].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:2682:Path 48: VIOLATED Setup Check with Pin u_core_gen_pd_row[7].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:2738:Path 49: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:2796:Path 50: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[6].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:2852:Path 51: VIOLATED Setup Check with Pin u_core_gen_pd_row[2].gen_pd_col[2].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:2910:Path 52: VIOLATED Setup Check with Pin u_core_gen_pd_row[2].gen_pd_col[2].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:2970:Path 53: VIOLATED Setup Check with Pin u_core_gen_pd_row[4].gen_pd_col[0].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:3028:Path 54: VIOLATED Setup Check with Pin u_core_gen_pd_row[6].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:3084:Path 55: VIOLATED Setup Check with Pin u_core_gen_pd_row[0].gen_pd_col[2].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:3142:Path 56: VIOLATED Setup Check with Pin u_core_gen_pd_row[4].gen_pd_col[5].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:3200:Path 57: VIOLATED Setup Check with Pin u_core_gen_pd_row[0].gen_pd_col[0].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:3256:Path 58: VIOLATED Setup Check with Pin u_core_gen_pd_row[6].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:3314:Path 59: VIOLATED Setup Check with Pin u_core_gen_pd_row[6].gen_pd_col[5].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:3372:Path 60: VIOLATED Setup Check with Pin u_core_gen_pd_row[0].gen_pd_col[2].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:3432:Path 61: VIOLATED Setup Check with Pin u_core_gen_pd_row[4].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:3490:Path 62: VIOLATED Setup Check with Pin u_core_gen_pd_row[0].gen_pd_col[1].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:3552:Path 63: VIOLATED Setup Check with Pin u_core_gen_pd_row[6].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:3608:Path 64: VIOLATED Setup Check with Pin u_core_gen_pd_row[2].gen_pd_col[5].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:3666:Path 65: VIOLATED Setup Check with Pin u_core_gen_pd_row[7].gen_pd_col[5].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:3722:Path 66: VIOLATED Setup Check with Pin u_core_gen_pd_row[5].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:3778:Path 67: VIOLATED Setup Check with Pin u_core_gen_pd_row[2].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:3836:Path 68: VIOLATED Setup Check with Pin u_core_gen_pd_row[4].gen_pd_col[0].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:3894:Path 69: VIOLATED Setup Check with Pin u_core_gen_pd_row[0].gen_pd_col[0].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:3952:Path 70: VIOLATED Setup Check with Pin u_core_gen_pd_row[3].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:4010:Path 71: VIOLATED Setup Check with Pin u_core_gen_pd_row[4].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:4066:Path 72: VIOLATED Setup Check with Pin u_core_gen_pd_row[5].gen_pd_col[5].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:4122:Path 73: VIOLATED Setup Check with Pin u_core_gen_pd_row[4].gen_pd_col[1].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:4182:Path 74: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[5].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:4238:Path 75: VIOLATED Setup Check with Pin u_core_gen_pd_row[3].gen_pd_col[2].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:4294:Path 76: VIOLATED Setup Check with Pin u_core_gen_pd_row[4].gen_pd_col[5].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:4350:Path 77: VIOLATED Setup Check with Pin u_core_gen_pd_row[7].gen_pd_col[5].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:4408:Path 78: VIOLATED Setup Check with Pin u_core_gen_pd_row[0].gen_pd_col[3].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:4466:Path 79: VIOLATED Setup Check with Pin u_core_gen_pd_row[0].gen_pd_col[6].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:4522:Path 80: VIOLATED Setup Check with Pin u_core_gen_pd_row[3].gen_pd_col[0].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:4578:Path 81: VIOLATED Setup Check with Pin u_core_gen_pd_row[4].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:4636:Path 82: VIOLATED Setup Check with Pin u_core_gen_pd_row[2].gen_pd_col[6].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:4692:Path 83: VIOLATED Setup Check with Pin u_core_gen_pd_row[2].gen_pd_col[0].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:4750:Path 84: VIOLATED Setup Check with Pin u_core_gen_pd_row[7].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:4806:Path 85: VIOLATED Setup Check with Pin u_core_gen_pd_row[3].gen_pd_col[5].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:4864:Path 86: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[3].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:4922:Path 87: VIOLATED Setup Check with Pin u_core_gen_pd_row[5].gen_pd_col[1].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:4984:Path 88: VIOLATED Setup Check with Pin u_core_gen_pd_row[4].gen_pd_col[0].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:5042:Path 89: VIOLATED Setup Check with Pin u_core_gen_pd_row[2].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:5100:Path 90: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[0].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:5158:Path 91: VIOLATED Setup Check with Pin u_core_gen_pd_row[7].gen_pd_col[6].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_targeted_eco_input.rpt:5216:Path 92: VIOLATED Setup Check with Pin u_core_gen_pd_row[3].gen_pd_col[0].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/cts_measured_status.rpt:1:CTS_MEASURED_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/cts_measured_status.rpt:17:CTS_MAX_FANOUT_VIOLATIONS=0
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/cts_measured_status.rpt:18:CTS_MAX_FANOUT_VIOLATIONS_REQUIRED=0
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_sroute.rpt:6:PG_TERM_NAMES_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_sroute.rpt:13:PG_TERM_COUNT_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_sroute.rpt:20:VDD_PG_TERM_HANDLES_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_sroute.rpt:27:VDD_PG_TERM_NAMES_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_sroute.rpt:34:VDD_PG_TERM_NETS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_sroute.rpt:41:VDD_PG_TERM_LAYERS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_sroute.rpt:48:VSS_PG_TERM_HANDLES_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_sroute.rpt:55:VSS_PG_TERM_NAMES_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_sroute.rpt:62:VSS_PG_TERM_NETS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_sroute.rpt:69:VSS_PG_TERM_LAYERS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_sroute.rpt:76:TERM_NAMES_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_sroute.rpt:83:VDD_NET_HANDLES_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_sroute.rpt:90:VDD_SWIRE_COUNT_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_sroute.rpt:97:VDD_SWIRE_LAYERS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_sroute.rpt:104:VDD_SWIRE_STATUS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_sroute.rpt:111:VSS_NET_HANDLES_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_sroute.rpt:118:VSS_SWIRE_COUNT_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_sroute.rpt:125:VSS_SWIRE_LAYERS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_sroute.rpt:132:VSS_SWIRE_STATUS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_sroute.rpt:139:GET_PORTS_VDD_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_sroute.rpt:146:GET_PORTS_VSS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/POST_FILLER_PRE_SROUTE_ecoRoute_target.rpt:118:# ECO: 92.86% of the total area was rechecked for DRC, and 0.00% required routing.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/POST_FILLER_PRE_SROUTE_ecoRoute_target.rpt:184:#Total number of DRC violations = 5
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/placement_pre_route_status.rpt:2:PLACEMENT_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/placement_pre_route_status.rpt:4:CHECKPLACE_COMMAND_FAILED=0
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/placement_pre_route_status.rpt:9:REGION_FENCE_VIOLATIONS=0
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/placement_pre_route_status.rpt:10:NOT_OF_FENCE_VIOLATIONS=0
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/extraction_sta_policy.rpt:5:SET_ANALYSIS_VIEW_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/extraction_sta_policy.rpt:6:SET_ANALYSIS_MODE_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_stitch.rpt:6:PG_TERM_NAMES_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_stitch.rpt:13:PG_TERM_COUNT_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_stitch.rpt:20:VDD_PG_TERM_HANDLES_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_stitch.rpt:27:VDD_PG_TERM_NAMES_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_stitch.rpt:34:VDD_PG_TERM_NETS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_stitch.rpt:41:VDD_PG_TERM_LAYERS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_stitch.rpt:48:VSS_PG_TERM_HANDLES_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_stitch.rpt:55:VSS_PG_TERM_NAMES_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_stitch.rpt:62:VSS_PG_TERM_NETS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_stitch.rpt:69:VSS_PG_TERM_LAYERS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_stitch.rpt:76:TERM_NAMES_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_stitch.rpt:83:VDD_NET_HANDLES_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_stitch.rpt:90:VDD_SWIRE_COUNT_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_stitch.rpt:97:VDD_SWIRE_LAYERS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_stitch.rpt:104:VDD_SWIRE_STATUS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_stitch.rpt:111:VSS_NET_HANDLES_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_stitch.rpt:118:VSS_SWIRE_COUNT_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_stitch.rpt:125:VSS_SWIRE_LAYERS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_stitch.rpt:132:VSS_SWIRE_STATUS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_stitch.rpt:139:GET_PORTS_VDD_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_objects_before_stitch.rpt:146:GET_PORTS_VSS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_phase_overlap_audit.rpt:9:CHECKPLACE_OVERLAP_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_phase_overlap_audit.rpt:82:SLOW_RO_PHASE_PLACEMENT_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_phase_overlap_audit.rpt:155:FAST_RO_PHASE_PLACEMENT_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_phase_overlap_audit.rpt:160:RO_PHASE_PLACEMENT_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_ecoRoute_fix_drc_markers_schema.rpt:2:marker: DRC Marker
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_ecoRoute_fix_drc_markers_schema.rpt:19:message: string, DRC marker message
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_ecoRoute_fix_drc_markers_schema.rpt:20:messageId: int, DRC marker message ID
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_ecoRoute_fix_drc_markers_schema.rpt:21:objType: enum(antennaData antennaModel bndry bump bumpGrid bumpTerm bus busGuide busSinkGroup cellDensity densityShape fPlan foreign gCellGridDef group guiLine guiPoly guiRect guiText hInst hInstTerm hNet hTerm head inst instTerm io layer layerRule layerShape libCell marker net netGroup pBlkg pWire pd pgInstTerm pin pinGroup pinGuide pinShape pkgComponent pkgObject prop ptn ptnCell ptnPinBlkg rBlkg resistor resizeBlkg routeType row rule sViaInst sWire sdp shape shapeVia site stackViaRule term text topCell trackDef vCell vWire via viaInst viaRuleGenerate whatIfVia whatIfWire wire), Object type: DRC Marker
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_ecoRoute_fix_drc_markers_schema.rpt:22:objects: objList(bump inst instTerm net term), The objects which caused the DRC. The list may be empty, and is currently limited to at most 2 objects.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc_markers_schema.rpt:2:marker: DRC Marker
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc_markers_schema.rpt:19:message: string, DRC marker message
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc_markers_schema.rpt:20:messageId: int, DRC marker message ID
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc_markers_schema.rpt:21:objType: enum(antennaData antennaModel bndry bump bumpGrid bumpTerm bus busGuide busSinkGroup cellDensity densityShape fPlan foreign gCellGridDef group guiLine guiPoly guiRect guiText hInst hInstTerm hNet hTerm head inst instTerm io layer layerRule layerShape libCell marker net netGroup pBlkg pWire pd pgInstTerm pin pinGroup pinGuide pinShape pkgComponent pkgObject prop ptn ptnCell ptnPinBlkg rBlkg resistor resizeBlkg routeType row rule sViaInst sWire sdp shape shapeVia site stackViaRule term text topCell trackDef vCell vWire via viaInst viaRuleGenerate whatIfVia whatIfWire wire), Object type: DRC Marker
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_drc_markers_schema.rpt:22:objects: objList(bump inst instTerm net term), The objects which caused the DRC. The list may be empty, and is currently limited to at most 2 objects.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/POST_FILLER_POST_SROUTE_ecoRoute_fix_drc.rpt:227:#Total number of DRC violations = 3
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:8:Path 1: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:64:Path 2: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:124:Path 3: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:180:Path 4: VIOLATED Setup Check with Pin u_core_gen_pd_row[2].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:236:Path 5: VIOLATED Setup Check with Pin u_core_gen_pd_row[3].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:292:Path 6: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:350:Path 7: VIOLATED Setup Check with Pin u_core_gen_pd_row[2].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:406:Path 8: VIOLATED Setup Check with Pin u_core_gen_pd_row[4].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:462:Path 9: VIOLATED Setup Check with Pin u_core_gen_pd_row[0].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:518:Path 10: VIOLATED Setup Check with Pin u_core_gen_pd_row[0].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:574:Path 11: VIOLATED Setup Check with Pin u_core_gen_pd_row[6].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:630:Path 12: VIOLATED Setup Check with Pin u_core_gen_pd_row[7].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:686:Path 13: VIOLATED Setup Check with Pin u_core_gen_pd_row[3].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:742:Path 14: VIOLATED Setup Check with Pin u_core_gen_pd_row[3].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:800:Path 15: VIOLATED Setup Check with Pin u_core_gen_pd_row[0].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:858:Path 16: VIOLATED Setup Check with Pin u_core_gen_pd_row[5].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:914:Path 17: VIOLATED Setup Check with Pin u_core_gen_pd_row[2].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:972:Path 18: VIOLATED Setup Check with Pin u_core_gen_pd_row[4].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:1028:Path 19: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:1084:Path 20: VIOLATED Setup Check with Pin u_core_gen_pd_row[6].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:1140:Path 21: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:1196:Path 22: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[1].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:1256:Path 23: VIOLATED Setup Check with Pin u_core_gen_pd_row[0].gen_pd_col[1].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:1316:Path 24: VIOLATED Setup Check with Pin u_core_gen_pd_row[5].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:1372:Path 25: VIOLATED Setup Check with Pin u_core_gen_pd_row[0].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:1428:Path 26: VIOLATED Setup Check with Pin u_core_gen_pd_row[7].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:1484:Path 27: VIOLATED Setup Check with Pin u_core_gen_pd_row[2].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:1540:Path 28: VIOLATED Setup Check with Pin u_core_gen_pd_row[3].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:1596:Path 29: VIOLATED Setup Check with Pin u_core_gen_pd_row[4].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:1652:Path 30: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[2].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:1710:Path 31: VIOLATED Setup Check with Pin u_core_gen_pd_row[3].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:1768:Path 32: VIOLATED Setup Check with Pin u_core_gen_pd_row[2].gen_pd_col[6].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:1824:Path 33: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[2].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:1882:Path 34: VIOLATED Setup Check with Pin u_core_gen_pd_row[3].gen_pd_col[0].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:1940:Path 35: VIOLATED Setup Check with Pin u_core_gen_pd_row[5].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:1996:Path 36: VIOLATED Setup Check with Pin u_core_gen_pd_row[0].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:2052:Path 37: VIOLATED Setup Check with Pin u_core_gen_pd_row[2].gen_pd_col[7].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:2110:Path 38: VIOLATED Setup Check with Pin u_core_gen_pd_row[7].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:2168:Path 39: VIOLATED Setup Check with Pin u_core_gen_pd_row[0].gen_pd_col[1].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:2226:Path 40: VIOLATED Setup Check with Pin u_core_gen_pd_row[0].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:2284:Path 41: VIOLATED Setup Check with Pin u_core_gen_pd_row[2].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:2340:Path 42: VIOLATED Setup Check with Pin u_core_gen_pd_row[3].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:2396:Path 43: VIOLATED Setup Check with Pin u_core_gen_pd_row[2].gen_pd_col[5].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:2452:Path 44: VIOLATED Setup Check with Pin u_core_gen_pd_row[6].gen_pd_col[5].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:2508:Path 45: VIOLATED Setup Check with Pin u_core_gen_pd_row[5].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:2566:Path 46: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[1].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:2624:Path 47: VIOLATED Setup Check with Pin u_core_gen_pd_row[4].gen_pd_col[3].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:2682:Path 48: VIOLATED Setup Check with Pin u_core_gen_pd_row[7].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:2738:Path 49: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:2796:Path 50: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[6].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:2852:Path 51: VIOLATED Setup Check with Pin u_core_gen_pd_row[2].gen_pd_col[2].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:2910:Path 52: VIOLATED Setup Check with Pin u_core_gen_pd_row[2].gen_pd_col[2].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:2970:Path 53: VIOLATED Setup Check with Pin u_core_gen_pd_row[4].gen_pd_col[0].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:3028:Path 54: VIOLATED Setup Check with Pin u_core_gen_pd_row[6].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:3084:Path 55: VIOLATED Setup Check with Pin u_core_gen_pd_row[0].gen_pd_col[2].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:3142:Path 56: VIOLATED Setup Check with Pin u_core_gen_pd_row[4].gen_pd_col[5].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:3200:Path 57: VIOLATED Setup Check with Pin u_core_gen_pd_row[0].gen_pd_col[0].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:3256:Path 58: VIOLATED Setup Check with Pin u_core_gen_pd_row[6].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:3314:Path 59: VIOLATED Setup Check with Pin u_core_gen_pd_row[6].gen_pd_col[5].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:3372:Path 60: VIOLATED Setup Check with Pin u_core_gen_pd_row[0].gen_pd_col[2].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:3432:Path 61: VIOLATED Setup Check with Pin u_core_gen_pd_row[4].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:3490:Path 62: VIOLATED Setup Check with Pin u_core_gen_pd_row[0].gen_pd_col[1].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:3552:Path 63: VIOLATED Setup Check with Pin u_core_gen_pd_row[6].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:3608:Path 64: VIOLATED Setup Check with Pin u_core_gen_pd_row[2].gen_pd_col[5].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:3666:Path 65: VIOLATED Setup Check with Pin u_core_gen_pd_row[7].gen_pd_col[5].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:3722:Path 66: VIOLATED Setup Check with Pin u_core_gen_pd_row[5].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:3778:Path 67: VIOLATED Setup Check with Pin u_core_gen_pd_row[2].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:3836:Path 68: VIOLATED Setup Check with Pin u_core_gen_pd_row[4].gen_pd_col[0].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:3894:Path 69: VIOLATED Setup Check with Pin u_core_gen_pd_row[0].gen_pd_col[0].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:3952:Path 70: VIOLATED Setup Check with Pin u_core_gen_pd_row[3].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:4010:Path 71: VIOLATED Setup Check with Pin u_core_gen_pd_row[4].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:4066:Path 72: VIOLATED Setup Check with Pin u_core_gen_pd_row[5].gen_pd_col[5].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:4122:Path 73: VIOLATED Setup Check with Pin u_core_gen_pd_row[4].gen_pd_col[1].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:4182:Path 74: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[5].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:4238:Path 75: VIOLATED Setup Check with Pin u_core_gen_pd_row[3].gen_pd_col[2].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:4294:Path 76: VIOLATED Setup Check with Pin u_core_gen_pd_row[4].gen_pd_col[5].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:4350:Path 77: VIOLATED Setup Check with Pin u_core_gen_pd_row[7].gen_pd_col[5].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:4408:Path 78: VIOLATED Setup Check with Pin u_core_gen_pd_row[0].gen_pd_col[3].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:4466:Path 79: VIOLATED Setup Check with Pin u_core_gen_pd_row[0].gen_pd_col[6].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:4522:Path 80: VIOLATED Setup Check with Pin u_core_gen_pd_row[3].gen_pd_col[0].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:4578:Path 81: VIOLATED Setup Check with Pin u_core_gen_pd_row[4].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:4636:Path 82: VIOLATED Setup Check with Pin u_core_gen_pd_row[2].gen_pd_col[6].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:4692:Path 83: VIOLATED Setup Check with Pin u_core_gen_pd_row[2].gen_pd_col[0].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:4750:Path 84: VIOLATED Setup Check with Pin u_core_gen_pd_row[7].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:4806:Path 85: VIOLATED Setup Check with Pin u_core_gen_pd_row[3].gen_pd_col[5].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:4864:Path 86: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[3].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:4922:Path 87: VIOLATED Setup Check with Pin u_core_gen_pd_row[5].gen_pd_col[1].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:4984:Path 88: VIOLATED Setup Check with Pin u_core_gen_pd_row[4].gen_pd_col[0].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:5042:Path 89: VIOLATED Setup Check with Pin u_core_gen_pd_row[2].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:5100:Path 90: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[0].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:5158:Path 91: VIOLATED Setup Check with Pin u_core_gen_pd_row[7].gen_pd_col[6].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_focus.rpt:5216:Path 92: VIOLATED Setup Check with Pin u_core_gen_pd_row[3].gen_pd_col[0].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:51:9	SPECIAL_OPEN	1007.44 691.35 1011.36 693.145	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:52:10	SPECIAL_OPEN	1027.04 691.175 1039.92 693.24	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:53:11	SPECIAL_OPEN	1013.04 691.08 1024.24 693.72	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:54:12	SPECIAL_OPEN	986.72 691.08 1004.08 693.72	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:55:13	SPECIAL_OPEN	947.52 681.64 983.92 684.76	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:56:14	SPECIAL_OPEN	1015.28 726.44 1024.8 729.56	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:57:15	SPECIAL_OPEN	1008.0 717.96 1031.52 720.12	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:58:16	SPECIAL_OPEN	973.84 726.44 1013.04 729.56	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:59:17	SPECIAL_OPEN	957.04 709.0 968.24 711.64	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:60:18	SPECIAL_OPEN	953.68 727.015 958.16 728.985	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:61:19	SPECIAL_OPEN	971.6 709.0 987.84 711.16	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:62:20	SPECIAL_OPEN	972.16 735.4 1016.96 738.52	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:63:21	SPECIAL_OPEN	976.64 717.48 986.72 720.6	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:64:22	SPECIAL_OPEN	963.76 744.36 1000.16 747.48	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:65:23	SPECIAL_OPEN	952.0 735.975 958.16 738.52	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:66:24	SPECIAL_OPEN	947.52 727.015 952.0 728.71	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:67:25	SPECIAL_OPEN	946.96 736.25 951.44 737.945	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:68:26	SPECIAL_OPEN	834.4 762.605 848.4 765.4	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:85:43	SPECIAL_OPEN	838.88 753.84 852.88 755.865	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:86:44	SPECIAL_OPEN	912.8 735.4 917.28 737.945	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:87:45	SPECIAL_OPEN	874.72 735.4 902.16 738.52	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:88:46	SPECIAL_OPEN	848.4 735.4 868.0 738.04	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:89:47	SPECIAL_OPEN	859.6 744.36 882.56 747.0	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:90:48	SPECIAL_OPEN	902.72 736.25 909.44 737.945	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:91:49	SPECIAL_OPEN	871.36 717.96 882.0 720.6	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:92:50	SPECIAL_OPEN	830.48 717.48 870.24 720.6	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:93:51	SPECIAL_OPEN	901.04 682.12 911.68 684.185	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:94:52	SPECIAL_OPEN	864.64 682.12 899.92 684.76	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:95:53	SPECIAL_OPEN	858.48 690.6 870.24 693.24	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:96:54	SPECIAL_OPEN	824.32 681.64 862.96 684.76	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:103:61	SPECIAL_OPEN	847.28 726.44 862.96 729.56	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:104:62	SPECIAL_OPEN	905.52 727.015 909.44 728.985	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:105:63	SPECIAL_OPEN	863.52 726.92 879.76 728.985	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:106:64	SPECIAL_OPEN	884.24 690.6 944.16 693.72	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:107:65	SPECIAL_OPEN	914.48 682.12 946.4 684.28	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:108:66	SPECIAL_OPEN	924.0 672.68 982.8 675.8	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:109:67	SPECIAL_OPEN	911.12 726.44 946.96 729.56	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:110:68	SPECIAL_OPEN	910.56 744.84 933.52 747.48	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:111:69	SPECIAL_OPEN	921.2 708.52 955.92 711.16	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:127:85	SPECIAL_OPEN	717.92 682.39 722.4 684.185	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:128:86	SPECIAL_OPEN	697.2 672.68 720.72 675.32	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:129:87	SPECIAL_OPEN	722.4 673.255 727.44 675.225	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:130:88	SPECIAL_OPEN	672.56 717.48 715.12 720.12	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:131:89	SPECIAL_OPEN	673.68 744.935 678.16 747.48	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:132:90	SPECIAL_OPEN	777.28 744.36 794.08 747.0	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:133:91	SPECIAL_OPEN	776.72 735.975 784.56 737.945	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:152:110	SPECIAL_OPEN	533.12 672.18 576.24 675.475	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:153:111	SPECIAL_OPEN	587.44 753.84 622.72 756.115	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:154:112	SPECIAL_OPEN	589.68 762.8 603.68 765.075	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:155:113	SPECIAL_OPEN	566.72 716.76 589.68 720.08	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:156:114	SPECIAL_OPEN	542.64 762.8 557.2 764.88	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:157:115	SPECIAL_OPEN	580.16 735.725 619.36 738.195	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:158:116	SPECIAL_OPEN	586.32 726.46 603.12 729.04	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:159:117	SPECIAL_OPEN	648.48 726.44 667.52 729.56	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:160:118	SPECIAL_OPEN	750.96 717.48 829.36 720.6	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:181:139	SPECIAL_OPEN	958.16 566.01 961.52 567.705	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:182:140	SPECIAL_OPEN	968.24 565.16 991.2 568.28	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:183:141	SPECIAL_OPEN	923.44 565.64 951.44 568.28	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:184:142	SPECIAL_OPEN	951.44 628.36 962.08 631.0	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:185:143	SPECIAL_OPEN	802.48 565.16 818.72 567.8	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:201:159	SPECIAL_OPEN	971.6 421.8 1020.88 424.92	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:202:160	SPECIAL_OPEN	972.16 430.76 1030.4 433.88	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:203:161	SPECIAL_OPEN	964.88 422.375 969.92 424.92	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:204:162	SPECIAL_OPEN	974.96 404.455 985.6 406.52	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:205:163	SPECIAL_OPEN	937.44 484.52 1014.72 487.64	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:206:164	SPECIAL_OPEN	936.88 431.335 943.04 433.88	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:214:172	SPECIAL_OPEN	819.84 476.13 826.0 478.11	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:215:173	SPECIAL_OPEN	802.48 529.32 814.24 531.96	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:216:174	SPECIAL_OPEN	854.56 475.56 868.0 478.68	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:217:175	SPECIAL_OPEN	814.8 529.32 852.88 532.44	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:218:176	SPECIAL_OPEN	882.0 493.48 890.4 496.6	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:219:177	SPECIAL_OPEN	881.44 476.04 894.88 478.68	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:220:178	SPECIAL_OPEN	830.48 484.52 847.28 487.16	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:221:179	SPECIAL_OPEN	879.2 448.68 892.64 451.32	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:222:180	SPECIAL_OPEN	893.76 404.36 917.84 407.0	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:223:181	SPECIAL_OPEN	901.04 413.32 912.8 415.96	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:230:188	SPECIAL_OPEN	870.24 430.76 906.64 433.88	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:231:189	SPECIAL_OPEN	823.2 404.46 827.68 406.25	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:246:204	SPECIAL_OPEN	814.8 422.55 820.4 424.34	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:247:205	SPECIAL_OPEN	805.28 413.41 842.24 415.5	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:248:206	SPECIAL_OPEN	832.16 448.68 844.48 451.32	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:250:208	SPECIAL_OPEN	832.72 421.8 879.2 424.92	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:251:209	SPECIAL_OPEN	846.72 449.255 871.36 451.32	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:252:210	SPECIAL_OPEN	844.48 457.64 873.6 460.28	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:253:211	SPECIAL_OPEN	897.12 466.6 907.2 469.145	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:254:212	SPECIAL_OPEN	916.72 422.28 930.16 424.92	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:255:213	SPECIAL_OPEN	928.48 494.055 934.08 496.6	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:256:214	SPECIAL_OPEN	915.04 413.515 930.72 415.96	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:257:215	SPECIAL_OPEN	919.52 502.44 944.16 505.08	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:266:224	SPECIAL_OPEN	692.72 565.735 697.76 568.28	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:267:225	SPECIAL_OPEN	696.08 556.68 720.72 559.32	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:268:226	SPECIAL_OPEN	721.84 556.68 734.16 559.32	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:269:227	SPECIAL_OPEN	768.88 556.68 780.08 559.32	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:270:228	SPECIAL_OPEN	596.4 547.26 618.24 549.88	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:271:229	SPECIAL_OPEN	568.96 538.28 636.72 541.38	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:272:230	SPECIAL_OPEN	545.44 628.34 598.64 630.675	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:273:231	SPECIAL_OPEN	546.0 654.78 556.64 657.4	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:274:232	SPECIAL_OPEN	561.12 619.4 572.32 621.47	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:275:233	SPECIAL_OPEN	557.2 609.98 576.24 612.6	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:276:234	SPECIAL_OPEN	584.08 601.57 597.52 603.545	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:292:250	SPECIAL_OPEN	553.28 547.72 587.44 549.88	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:293:251	SPECIAL_OPEN	575.12 646.705 579.04 648.46	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:294:252	SPECIAL_OPEN	647.92 556.2 652.96 558.745	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:295:253	SPECIAL_OPEN	663.04 556.2 695.52 559.32	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:296:254	SPECIAL_OPEN	748.16 520.36 753.2 522.905	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:297:255	SPECIAL_OPEN	761.04 520.935 766.64 523.48	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:298:256	SPECIAL_OPEN	767.76 520.36 795.2 523.48	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:299:257	SPECIAL_OPEN	720.72 529.32 793.52 531.96	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:307:265	SPECIAL_OPEN	736.96 449.16 747.6 451.14	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:308:266	SPECIAL_OPEN	712.88 458.12 742.0 460.76	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:325:283	SPECIAL_OPEN	707.84 403.88 729.12 406.52	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:344:302	SPECIAL_OPEN	585.2 511.97 594.72 514.0	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:345:303	SPECIAL_OPEN	536.48 502.46 612.08 505.56	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:346:304	SPECIAL_OPEN	589.68 529.34 614.88 532.44	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:347:305	SPECIAL_OPEN	583.52 520.9 608.16 523.0	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:348:306	SPECIAL_OPEN	658.0 467.18 672.56 469.215	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:349:307	SPECIAL_OPEN	621.04 520.36 708.96 523.48	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:350:308	SPECIAL_OPEN	647.36 511.4 730.24 514.52	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:351:309	SPECIAL_OPEN	794.64 529.895 800.24 531.865	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:352:310	SPECIAL_OPEN	713.44 565.16 801.92 568.28	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:353:311	SPECIAL_OPEN	791.84 556.68 829.92 559.32	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:355:313	SPECIAL_OPEN	685.44 664.2 696.08 666.265	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:356:314	SPECIAL_OPEN	696.64 664.2 754.88 666.84	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:373:331	SPECIAL_OPEN	479.92 753.84 494.48 756.115	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:374:332	SPECIAL_OPEN	464.24 762.605 507.92 765.075	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:375:333	SPECIAL_OPEN	403.2 744.685 418.32 746.96	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:376:334	SPECIAL_OPEN	482.16 744.94 497.28 746.96	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:377:335	SPECIAL_OPEN	510.16 771.76 524.16 774.035	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:378:336	SPECIAL_OPEN	491.12 681.66 501.76 684.28	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:379:337	SPECIAL_OPEN	507.36 699.58 525.84 702.2	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:380:338	SPECIAL_OPEN	464.8 699.58 495.04 702.2	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:381:339	SPECIAL_OPEN	431.76 699.58 454.16 702.66	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:382:340	SPECIAL_OPEN	419.44 682.12 446.32 684.74	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:383:341	SPECIAL_OPEN	467.6 682.12 478.24 684.74	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:384:342	SPECIAL_OPEN	403.2 672.7 427.28 675.8	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:385:343	SPECIAL_OPEN	465.36 691.08 488.88 694.26	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:386:344	SPECIAL_OPEN	501.2 690.06 509.6 693.7	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:387:345	SPECIAL_OPEN	443.52 690.6 460.32 693.24	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:388:346	SPECIAL_OPEN	510.16 690.06 515.76 693.14	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:392:350	SPECIAL_OPEN	425.04 708.845 510.16 711.315	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:393:351	SPECIAL_OPEN	403.76 717.5 473.2 720.275	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:394:352	SPECIAL_OPEN	479.92 682.12 490.56 684.74	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:395:353	SPECIAL_OPEN	446.88 682.12 458.08 684.28	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:396:354	SPECIAL_OPEN	414.96 726.765 428.96 729.04	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:397:355	SPECIAL_OPEN	387.52 700.31 392.0 702.1	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:408:366	SPECIAL_OPEN	393.12 682.22 396.48 683.91	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:409:367	SPECIAL_OPEN	370.16 700.02 378.56 702.1	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:410:368	SPECIAL_OPEN	358.4 682.12 370.16 684.28	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:411:369	SPECIAL_OPEN	299.04 672.68 365.12 675.8	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:412:370	SPECIAL_OPEN	330.4 699.56 369.6 702.66	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:413:371	SPECIAL_OPEN	352.24 691.08 362.88 693.72	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:414:372	SPECIAL_OPEN	329.84 717.48 395.92 720.12	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:415:373	SPECIAL_OPEN	352.24 735.88 362.88 738.04	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:416:374	SPECIAL_OPEN	276.64 708.52 365.12 711.64	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:417:375	SPECIAL_OPEN	303.52 726.92 340.48 729.54	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:418:376	SPECIAL_OPEN	339.92 690.62 350.56 693.24	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:419:377	SPECIAL_OPEN	326.48 681.64 346.08 684.28	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:420:378	SPECIAL_OPEN	372.96 709.095 395.36 711.64	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:421:379	SPECIAL_OPEN	393.12 699.58 429.52 702.2	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:422:380	SPECIAL_OPEN	386.4 726.46 412.72 729.235	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:423:381	SPECIAL_OPEN	397.04 682.12 418.88 684.76	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:424:382	SPECIAL_OPEN	394.8 690.62 428.96 693.72	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:425:383	SPECIAL_OPEN	389.76 753.645 417.76 756.115	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:429:387	SPECIAL_OPEN	246.96 673.26 267.12 675.23	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:430:388	SPECIAL_OPEN	441.28 628.36 458.08 630.98	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:431:389	SPECIAL_OPEN	489.44 627.9 522.48 630.52	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:432:390	SPECIAL_OPEN	465.92 628.36 487.76 630.98	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:433:391	SPECIAL_OPEN	479.36 636.86 498.4 639.96	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:434:392	SPECIAL_OPEN	418.88 610.44 429.52 612.5	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:435:393	SPECIAL_OPEN	505.12 655.34 508.48 657.42	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:436:394	SPECIAL_OPEN	449.68 655.24 487.76 657.86	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:437:395	SPECIAL_OPEN	489.44 646.28 516.88 648.34	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:438:396	SPECIAL_OPEN	433.44 636.86 465.92 639.48	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:446:404	SPECIAL_OPEN	416.64 628.41 435.68 631.17	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:447:405	SPECIAL_OPEN	421.68 601.02 453.6 604.25	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:448:406	SPECIAL_OPEN	409.36 601.02 420.0 603.64	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:449:407	SPECIAL_OPEN	488.32 619.4 515.2 621.56	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:450:408	SPECIAL_OPEN	467.04 636.84 478.24 639.48	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:451:409	SPECIAL_OPEN	416.64 565.18 428.96 567.8	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:452:410	SPECIAL_OPEN	417.2 592.52 431.2 594.68	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:453:411	SPECIAL_OPEN	429.52 565.18 460.88 568.26	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:454:412	SPECIAL_OPEN	445.2 592.06 455.84 594.68	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:455:413	SPECIAL_OPEN	410.48 547.72 459.2 550.49	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:456:414	SPECIAL_OPEN	438.48 538.15 457.52 540.825	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:461:419	SPECIAL_OPEN	462.0 565.69 481.6 567.75	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:462:420	SPECIAL_OPEN	427.28 574.6 456.96 577.22	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:463:421	SPECIAL_OPEN	431.76 592.06 444.64 594.68	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:464:422	SPECIAL_OPEN	414.96 583.56 431.2 586.18	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:465:423	SPECIAL_OPEN	390.32 664.3 393.68 665.99	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:466:424	SPECIAL_OPEN	374.08 664.295 381.36 666.075	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:479:437	SPECIAL_OPEN	363.44 627.9 386.4 630.52	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:480:438	SPECIAL_OPEN	287.84 654.76 337.12 657.88	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:481:439	SPECIAL_OPEN	351.68 645.82 374.64 648.92	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:482:440	SPECIAL_OPEN	338.8 636.86 374.64 639.48	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:483:441	SPECIAL_OPEN	350.0 654.78 373.52 657.88	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:484:442	SPECIAL_OPEN	374.08 655.24 385.28 657.3	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:485:443	SPECIAL_OPEN	338.24 654.76 349.44 657.4	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:486:444	SPECIAL_OPEN	325.92 646.28 339.92 648.9	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:487:445	SPECIAL_OPEN	389.76 538.28 427.28 541.38	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:488:446	SPECIAL_OPEN	381.92 636.84 424.48 639.94	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:489:447	SPECIAL_OPEN	375.76 645.82 488.32 648.92	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:490:448	SPECIAL_OPEN	386.96 627.9 414.96 630.52	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:491:449	SPECIAL_OPEN	386.4 654.76 420.56 657.88	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:512:470	SPECIAL_OPEN	453.04 511.88 465.36 513.95	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:513:471	SPECIAL_OPEN	474.88 511.23 488.88 514.65	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:514:472	SPECIAL_OPEN	463.68 529.34 481.04 531.87	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:515:473	SPECIAL_OPEN	467.6 502.92 484.96 504.985	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:516:474	SPECIAL_OPEN	475.44 493.5 485.52 496.025	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:593:551	RO_PG_UNCONNECTED_PIN	176.8 626.43 178.8 639.455	MET2	Connectivity	UnConnectedPin	Net VDD Pin: u_core_u_osc_slow_u_ro_tune4/vdd!; Direction: INOUT; Use: POWER;
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:594:552	RO_PG_UNCONNECTED_PIN	144.88 625.66 146.88 639.455	MET2	Connectivity	UnConnectedPin	Net VDD Pin: u_core_u_osc_slow_u_ro_tune4/vdd!; Direction: INOUT; Use: POWER;
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:606:564	RO_PG_UNCONNECTED_PIN	52.43 627.355 57.575 630.59	MET1	Connectivity	UnConnectedPin	Net VDD Pin: u_core_u_osc_slow_u_ro_tune4/VDD; Direction: INOUT; Use: POWER;
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:623:581	SPECIAL_OPEN	394.24 663.72 456.96 666.82	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:624:582	SPECIAL_OPEN	331.52 663.72 349.44 666.82	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:625:583	SPECIAL_OPEN	458.08 664.2 474.32 666.82	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:626:584	SPECIAL_OPEN	315.28 664.2 325.92 666.84	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:627:585	SPECIAL_OPEN	351.68 663.72 369.6 666.36	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:628:586	SPECIAL_OPEN	474.88 664.2 485.52 666.82	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:630:588	SPECIAL_OPEN	499.52 511.88 542.08 514.02	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:631:589	SPECIAL_OPEN	519.68 636.84 551.6 639.94	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:632:590	SPECIAL_OPEN	514.08 672.14 530.88 675.8	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:633:591	SPECIAL_OPEN	509.6 654.78 544.88 657.4	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:634:592	SPECIAL_OPEN	517.44 645.82 556.64 648.44	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:635:593	SPECIAL_OPEN	523.04 627.9 544.88 630.52	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:636:594	SPECIAL_OPEN	516.32 619.4 542.64 621.56	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:637:595	SPECIAL_OPEN	516.32 663.74 550.48 666.82	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:638:596	SPECIAL_OPEN	503.44 681.66 535.36 684.74	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:639:597	SPECIAL_OPEN	528.64 700.04 542.64 702.16	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:640:598	SPECIAL_OPEN	528.08 690.62 548.8 693.24	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:641:599	SPECIAL_OPEN	510.72 762.8 540.96 764.88	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:642:600	SPECIAL_OPEN	525.28 771.76 539.84 774.035	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:643:601	SPECIAL_OPEN	530.32 708.845 573.44 711.16	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:644:602	SPECIAL_OPEN	518.56 520.38 553.28 523.0	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:655:613	SPECIAL_OPEN	952.56 359.08 1009.68 362.2	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:656:614	SPECIAL_OPEN	967.12 350.12 1002.4 353.24	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:657:615	SPECIAL_OPEN	961.52 350.695 965.44 352.39	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:658:616	SPECIAL_OPEN	930.16 394.92 940.8 397.56	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:659:617	SPECIAL_OPEN	952.0 386.44 969.36 389.08	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:660:618	SPECIAL_OPEN	971.6 377.0 976.08 379.545	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:661:619	SPECIAL_OPEN	965.44 377.575 969.36 379.27	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:662:620	SPECIAL_OPEN	986.16 377.0 991.2 379.545	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:663:621	SPECIAL_OPEN	977.76 377.575 982.24 380.12	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:664:622	SPECIAL_OPEN	972.16 385.96 1019.2 389.08	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:665:623	SPECIAL_OPEN	857.36 359.08 887.6 362.2	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:666:624	SPECIAL_OPEN	851.76 350.695 856.24 352.665	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:667:625	SPECIAL_OPEN	857.92 350.6 874.72 353.24	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:668:626	SPECIAL_OPEN	805.28 386.535 809.76 389.08	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:669:627	SPECIAL_OPEN	911.12 377.0 916.16 379.545	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:670:628	SPECIAL_OPEN	803.04 395.4 823.76 397.56	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:671:629	SPECIAL_OPEN	828.8 395.4 846.72 397.56	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:678:636	SPECIAL_OPEN	848.4 394.92 901.04 397.56	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:679:637	SPECIAL_OPEN	896.56 377.48 907.2 380.12	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:680:638	SPECIAL_OPEN	906.08 386.44 923.44 389.08	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:681:639	SPECIAL_OPEN	812.56 305.89 824.32 308.42	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:699:657	SPECIAL_OPEN	923.44 377.575 929.04 379.545	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:700:658	SPECIAL_OPEN	948.08 170.92 981.12 174.04	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:701:659	SPECIAL_OPEN	949.2 188.84 964.32 191.48	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:713:671	SPECIAL_OPEN	931.84 234.215 936.88 236.76	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:714:672	SPECIAL_OPEN	955.92 234.12 986.72 236.76	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:715:673	SPECIAL_OPEN	949.76 234.215 954.8 236.76	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:716:674	SPECIAL_OPEN	919.52 171.495 924.0 174.04	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:717:675	SPECIAL_OPEN	823.2 144.06 829.36 147.16	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:718:676	SPECIAL_OPEN	870.24 153.48 885.92 155.64	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:719:677	SPECIAL_OPEN	834.4 161.96 868.0 165.08	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:720:678	SPECIAL_OPEN	872.48 180.455 883.12 182.52	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:721:679	SPECIAL_OPEN	837.2 170.92 904.96 174.04	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:722:680	SPECIAL_OPEN	871.92 188.84 921.76 191.96	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:730:688	SPECIAL_OPEN	803.6 161.96 833.28 165.08	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:731:689	SPECIAL_OPEN	864.08 216.295 874.72 218.36	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:732:690	SPECIAL_OPEN	875.28 215.72 904.4 218.84	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:733:691	SPECIAL_OPEN	877.52 233.64 909.44 236.76	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:734:692	SPECIAL_OPEN	798.56 224.68 848.4 227.8	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:735:693	SPECIAL_OPEN	853.44 198.28 876.4 200.92	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:736:694	SPECIAL_OPEN	799.12 206.76 887.6 209.88	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:737:695	SPECIAL_OPEN	908.32 180.36 933.52 183.0	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:738:696	SPECIAL_OPEN	922.88 188.84 948.64 191.96	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:739:697	SPECIAL_OPEN	927.36 171.495 934.64 173.275	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:740:698	SPECIAL_OPEN	918.96 234.12 929.6 236.76	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:741:699	SPECIAL_OPEN	735.28 305.32 773.36 308.44	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:742:700	SPECIAL_OPEN	750.96 377.0 790.16 379.64	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:743:701	SPECIAL_OPEN	782.32 279.1 790.16 281.54	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:744:702	SPECIAL_OPEN	777.28 297.125 783.44 298.905	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:745:703	SPECIAL_OPEN	758.8 287.88 771.12 290.52	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:746:704	SPECIAL_OPEN	756.0 296.935 760.48 299.48	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:747:705	SPECIAL_OPEN	728.0 278.44 778.96 281.56	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:756:714	SPECIAL_OPEN	694.96 305.895 698.88 307.865	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:757:715	SPECIAL_OPEN	694.4 314.28 759.92 317.4	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:758:716	SPECIAL_OPEN	702.24 305.895 715.68 307.865	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:759:717	SPECIAL_OPEN	669.76 278.44 676.48 280.985	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:760:718	SPECIAL_OPEN	673.68 368.615 678.16 370.31	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:761:719	SPECIAL_OPEN	680.4 368.04 716.24 371.16	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:762:720	SPECIAL_OPEN	722.96 359.56 735.84 362.2	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:778:736	SPECIAL_OPEN	650.16 296.36 663.04 299.0	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:779:737	SPECIAL_OPEN	623.84 368.52 637.84 371.16	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:780:738	SPECIAL_OPEN	663.04 377.0 677.04 379.64	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:781:739	SPECIAL_OPEN	642.88 269.48 671.44 272.12	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:782:740	SPECIAL_OPEN	659.12 368.04 671.44 370.68	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:783:741	SPECIAL_OPEN	640.64 359.08 678.72 362.2	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:795:753	SPECIAL_OPEN	767.76 144.04 790.72 147.16	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:796:754	SPECIAL_OPEN	684.88 233.64 754.32 236.76	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:797:755	SPECIAL_OPEN	678.72 234.215 683.2 236.76	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:798:756	SPECIAL_OPEN	733.04 153.0 768.32 155.64	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:799:757	SPECIAL_OPEN	681.52 161.96 729.12 165.08	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:800:758	SPECIAL_OPEN	677.04 153.575 680.96 155.37	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:801:759	SPECIAL_OPEN	669.76 189.32 698.88 191.96	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:802:760	SPECIAL_OPEN	711.76 179.88 740.88 183.0	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:823:781	SPECIAL_OPEN	644.56 260.52 656.32 263.16	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:824:782	SPECIAL_OPEN	659.12 234.12 677.04 236.76	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:825:783	SPECIAL_OPEN	663.04 153.0 674.8 155.64	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:826:784	SPECIAL_OPEN	646.8 179.88 667.52 182.52	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:828:786	SPECIAL_OPEN	789.6 216.2 812.56 218.84	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:829:787	SPECIAL_OPEN	790.16 368.52 813.12 371.16	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:830:788	SPECIAL_OPEN	795.2 153.02 801.36 156.1	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:853:811	SPECIAL_OPEN	867.44 108.68 890.96 111.32	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:854:812	SPECIAL_OPEN	698.32 117.18 704.48 119.62	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:855:813	SPECIAL_OPEN	756.0 135.655 767.2 137.72	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:911:869	SPECIAL_OPEN	449.12 162.08 474.88 164.755	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:981:939	SPECIAL_OPEN	113.12 395.04 197.12 397.715	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:982:940	SPECIAL_OPEN	40.32 368.04 127.68 371.14	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:991:949	RO_PG_UNCONNECTED_PIN	144.88 161.845 146.88 175.64	MET2	Connectivity	UnConnectedPin	Net VDD Pin: u_core_u_osc_fast_u_ro_tune4/vdd!; Direction: INOUT; Use: POWER;
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:992:950	RO_PG_UNCONNECTED_PIN	176.8 161.845 178.8 174.87	MET2	Connectivity	UnConnectedPin	Net VDD Pin: u_core_u_osc_fast_u_ro_tune4/vdd!; Direction: INOUT; Use: POWER;
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:1011:969	RO_PG_UNCONNECTED_PIN	52.43 170.71 57.575 173.945	MET1	Connectivity	UnConnectedPin	Net VDD Pin: u_core_u_osc_fast_u_ro_tune4/VDD; Direction: INOUT; Use: POWER;
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:1042:1000	SPECIAL_OPEN	16.16 16.16 1045.04 785.76	POLY1	Connectivity	Open	Net VDD
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:1044:RO_PG_MARKER_RO_UNCONNECTED_COUNT=6
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:1046:RO_PG_MARKER_SPECIAL_OPEN_COUNT=316
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_pg_probe_after_hookup.rpt:1048:RO_PG_PROBE_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_postroute_opt_final.rpt:8:Path 1: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_postroute_opt_final.rpt:64:Path 2: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_postroute_opt_final.rpt:122:Path 3: VIOLATED Setup Check with Pin u_core_gen_pd_row[0].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_postroute_opt_final.rpt:178:Path 4: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_postroute_opt_final.rpt:236:Path 5: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_postroute_opt_final.rpt:296:Path 6: VIOLATED Setup Check with Pin u_core_gen_pd_row[1].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_postroute_opt_final.rpt:356:Path 7: VIOLATED Setup Check with Pin u_core_gen_pd_row[2].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_postroute_opt_final.rpt:416:Path 8: VIOLATED Setup Check with Pin u_core_gen_pd_row[3].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_postroute_opt_final.rpt:476:Path 9: VIOLATED Setup Check with Pin u_core_gen_pd_row[2].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_postroute_opt_final.rpt:534:Path 10: VIOLATED Setup Check with Pin u_core_gen_pd_row[5].gen_pd_col[7].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_postroute_opt_final.rpt:590:Path 11: VIOLATED Setup Check with Pin u_core_gen_pd_row[3].gen_pd_col[4].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_postroute_opt_final.rpt:648:Path 12: VIOLATED Setup Check with Pin u_core_gen_pd_row[4].gen_pd_col[1].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_to_pd_timing_postroute_opt_final.rpt:708:Path 13: VIOLATED Setup Check with Pin u_core_gen_pd_row[6].gen_pd_col[1].u_pd/
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_status.rpt:4:PD_GRID_PLACEMENT_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_status.rpt:7:PD_GRID_TILE_REGION_FAILURES=0
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_status.rpt:13:PD_GRID_LEAF_PREPLACEMENT_FAILURES=0
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_status.rpt:15:FAST_TAG_COLUMN_PLACEMENT_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_status.rpt:19:FAST_TAG_COLUMN_FAILURES=0
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_status.rpt:21:PD_MATRIX_STATUS=PROVISIONAL
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/placement_status.rpt:2:PLACEMENT_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/placement_status.rpt:4:CHECKPLACE_COMMAND_FAILED=0
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/placement_status.rpt:9:REGION_FENCE_VIOLATIONS=0
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/placement_status.rpt:10:NOT_OF_FENCE_VIOLATIONS=0
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/floorplan_status.rpt:1:FLOORPLAN_STATUS=REVIEW
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/floorplan_status.rpt:15:FLOORPLAN_ASPECT_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/floorplan_status.rpt:22:FLOORPLAN_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/cts_policy.rpt:10:CTS_SPEC_AUDIT_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/cts_policy.rpt:15:CTS_SPEC_SOURCE_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/cts_policy.rpt:18:CTS_SPEC_GATE_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/cts_policy.rpt:21:CCOPT_COMMAND_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/cts_policy.rpt:23:POST_CTS_SET_ANALYSIS_VIEW_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/cts_policy.rpt:24:POST_CTS_OPT_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/cts_policy.rpt:26:CTS_MEASURED_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/cts_policy.rpt:28:CTS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_ro_pg_hookup_marker_schema.rpt:2:marker: DRC Marker
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_ro_pg_hookup_marker_schema.rpt:19:message: string, DRC marker message
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_ro_pg_hookup_marker_schema.rpt:20:messageId: int, DRC marker message ID
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_ro_pg_hookup_marker_schema.rpt:21:objType: enum(antennaData antennaModel bndry bump bumpGrid bumpTerm bus busGuide busSinkGroup cellDensity densityShape fPlan foreign gCellGridDef group guiLine guiPoly guiRect guiText hInst hInstTerm hNet hTerm head inst instTerm io layer layerRule layerShape libCell marker net netGroup pBlkg pWire pd pgInstTerm pin pinGroup pinGuide pinShape pkgComponent pkgObject prop ptn ptnCell ptnPinBlkg rBlkg resistor resizeBlkg routeType row rule sViaInst sWire sdp shape shapeVia site stackViaRule term text topCell trackDef vCell vWire via viaInst viaRuleGenerate whatIfVia whatIfWire wire), Object type: DRC Marker
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_pg_topology_after_ro_pg_hookup_marker_schema.rpt:22:objects: objList(bump inst instTerm net term), The objects which caused the DRC. The list may be empty, and is currently limited to at most 2 objects.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_layer_audit.rpt:7:LAYER_VALUE label={requested_signal_bottom_layer} value={MET1} status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_layer_audit.rpt:8:LAYER_VALUE label={requested_signal_top_layer} value={MET3} status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_layer_audit.rpt:9:LAYER_VALUE label={effective_global_top_layer} value={METTP} status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_layer_audit.rpt:10:EXISTING_LAYER_QUERY_STATUS=PASS command={dbGet top.nets.wires.layer.name} values_seen=126370
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_layer_audit.rpt:11:EXISTING_LAYER_QUERY_STATUS=PASS command={dbGet top.nets.sWires.layer.name} values_seen=16409
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_layer_audit.rpt:12:EXISTING_LAYER_QUERY_STATUS=PASS command={dbGet top.nets.wires.layer.num} values_seen=126370
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_layer_audit.rpt:13:EXISTING_LAYER_QUERY_STATUS=PASS command={dbGet top.nets.sWires.layer.num} values_seen=16409
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_layer_audit.rpt:14:EXISTING_LAYER_QUERY_STATUS=SKIPPED command={dbGet top.nets.shapes.layer.name} error={0x0}
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_layer_audit.rpt:15:EXISTING_LAYER_QUERY_STATUS=SKIPPED command={get_db wires .layer.name} error={}
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_layer_audit.rpt:18:OBJECT_AUDIT_STATUS=PASS object_type=nets object_count=16346
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_layer_audit.rpt:20:OBJECT_AUDIT_STATUS=PASS object_type=timing_nets object_count=1
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_layer_audit.rpt:22:OBJECT_AUDIT_STATUS=PASS object_type=route_types object_count=2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_layer_audit.rpt:24:ROUTE_LAYER_AUDIT_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts.rpt:16:|           WNS (ns):| -0.469  | -0.469  |  0.235  |
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_tc_pre_cts.rpt:17:|           TNS (ns):| -24.580 | -24.580 |  0.000  |
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_post_cts.rpt:16:|           WNS (ns):| -0.008  | -0.008  |  0.565  |
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/timing_post_cts.rpt:17:|           TNS (ns):| -0.024  | -0.024  |  0.000  |
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_setup_pass_4_timing.rpt:20:|           WNS (ns):| -0.020  | -0.020  |   N/A   |
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_setup_pass_4_timing.rpt:21:|           TNS (ns):| -0.125  | -0.125  |   N/A   |
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_sroute_status.rpt:8:POSTPLACE_PRE_ROUTE_BLOCK_PG_STITCH_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_sroute_status.rpt:13:POSTPLACE_PRE_ROUTE_RO_PG_HOOKUP_STATUS=PASS_OR_SKIPPED
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_sroute_status.rpt:18:POSTPLACE_PRE_ROUTE_SROUTE_MODE_CORE_PIN_STOP_ROUTE_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_sroute_status.rpt:20:POSTPLACE_PRE_ROUTE_SROUTE_MODE_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_sroute_status.rpt:26:POSTPLACE_PRE_ROUTE_SROUTE_ATTEMPT_1_COMMAND_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_sroute_status.rpt:27:POSTPLACE_PRE_ROUTE_SROUTE_ATTEMPT_1_STATUS=REVIEW_REQUIRED
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_sroute_status.rpt:29:POSTPLACE_PRE_ROUTE_SROUTE_ATTEMPT_1_OPEN_PORTS=24
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_sroute_status.rpt:30:POSTPLACE_PRE_ROUTE_SROUTE_ATTEMPT_1_BLOCK_OPEN_PORTS=0
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_sroute_status.rpt:31:POSTPLACE_PRE_ROUTE_SROUTE_ATTEMPT_1_CORE_OPEN_PORTS=24
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_sroute_status.rpt:32:POSTPLACE_PRE_ROUTE_SROUTE_ATTEMPT_1_POWER_BUMP_OPEN_PORTS=0
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_sroute_status.rpt:34:POSTPLACE_PRE_ROUTE_SROUTE_STATUS=FAIL
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_sroute_status.rpt:37:POSTPLACE_PRE_ROUTE_SROUTE_COMMAND_STATUS=FAIL
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_sroute_status.rpt:38:POSTPLACE_PRE_ROUTE_SROUTE_EFFECTIVE_STATUS=REVIEW_REQUIRED
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_sroute_status.rpt:40:POSTPLACE_PRE_ROUTE_SROUTE_EFFECTIVE_OPEN_PORTS=24
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_sroute_status.rpt:41:POSTPLACE_PRE_ROUTE_SROUTE_EFFECTIVE_BLOCK_OPEN_PORTS=0
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_sroute_status.rpt:42:POSTPLACE_PRE_ROUTE_SROUTE_EFFECTIVE_CORE_OPEN_PORTS=24
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_sroute_status.rpt:43:POSTPLACE_PRE_ROUTE_SROUTE_EFFECTIVE_POWER_BUMP_OPEN_PORTS=0
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_sroute_status.rpt:47:POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_CAPTURE_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_sroute_status.rpt:51:POSTPLACE_PRE_ROUTE_SROUTE_STATUS_BEFORE_VERIFY=REVIEW_REQUIRED
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_sroute_status.rpt:53:POSTPLACE_PRE_ROUTE_SROUTE_PROGRESS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_sroute_status.rpt:54:POSTPLACE_PRE_ROUTE_SROUTE_STATUS=REVIEW_REQUIRED
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_ecoRoute_target.rpt:175:#Total number of DRC violations = 13
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_mode_status.rpt:2:MPTDC_FILLER_ADD_FILLERS_WITH_DRC=0
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_mode_status.rpt:3:MPTDC_REQUIRE_DRC_SAFE_FILLER=1
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_mode_status.rpt:4:REQUESTED_ADD_FILLERS_WITH_DRC=false
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_mode_status.rpt:6:FILLER_MODE_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_command_status.rpt:3:ROUTE_COMMAND_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_setup_pass_3_timing.rpt:20:|           WNS (ns):| -0.020  | -0.020  |   N/A   |
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_setup_pass_3_timing.rpt:21:|           TNS (ns):| -0.125  | -0.125  |   N/A   |
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/row_infra_insertion.rpt:1:ROW_INFRA_POLICY=NO_DEDICATED_CORE_TAP_ENDCAP_PENDING_DRC_LVS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/row_infra_insertion.rpt:2:TAP_INSERTION=SKIPPED_NO_DEDICATED_MASTER_PENDING_DRC_LVS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/row_infra_insertion.rpt:3:ENDCAP_INSERTION=SKIPPED_NO_DEDICATED_MASTER_PENDING_DRC_LVS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/row_infra_insertion.rpt:8:FILLER_INSERTION_STATUS=DEFERRED_AFTER_ROUTE_FINAL_ECO
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_ecoRoute_fix_drc.rpt:227:#Total number of DRC violations = 9
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:22:FAST_TAG_ECO_PATH_TIMING_REPORT_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:597:FAST_TAG_ECO_PATH_DRIVEN_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:666:FAST_TAG_ECO_UPSIZE_ATTEMPT=FE_OFC1778_u_core_fast_tag_col_4__2 target=INJIHDX4 status=PASS command=ecoChangeCell -inst FE_OFC1778_u_core_fast_tag_col_4__2 -cell INJIHDX4
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:667:FAST_TAG_ECO_UPSIZE_ATTEMPT=FE_OFC1840_u_core_fast_tag_col_4__3 target=INJIHDX4 status=PASS command=ecoChangeCell -inst FE_OFC1840_u_core_fast_tag_col_4__3 -cell INJIHDX4
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:668:FAST_TAG_ECO_UPSIZE_ATTEMPT=FE_OFC1841_u_core_fast_tag_col_4__4 target=INJIHDX4 status=PASS command=ecoChangeCell -inst FE_OFC1841_u_core_fast_tag_col_4__4 -cell INJIHDX4
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:669:FAST_TAG_ECO_UPSIZE_ATTEMPT=FE_OFC1859_u_core_fast_tag_col_5__4 target=INJIHDX3 status=PASS command=ecoChangeCell -inst FE_OFC1859_u_core_fast_tag_col_5__4 -cell INJIHDX3
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:670:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[4].u_fast_tag_tag_o_reg[2] target=DFRRQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[4].u_fast_tag_tag_o_reg[2]} -cell DFRRQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:671:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[4].u_fast_tag_tag_o_reg[3] target=DFRRQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[4].u_fast_tag_tag_o_reg[3]} -cell DFRRQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:672:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[4].u_fast_tag_tag_o_reg[5] target=DFRRQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[4].u_fast_tag_tag_o_reg[5]} -cell DFRRQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:673:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[4].u_fast_tag_tag_o_reg[4] target=DFRRQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[4].u_fast_tag_tag_o_reg[4]} -cell DFRRQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:674:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[4].u_fast_tag_tag_o_reg[1] target=DFRRQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[4].u_fast_tag_tag_o_reg[1]} -cell DFRRQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:675:FAST_TAG_ECO_UPSIZE_ATTEMPT=FE_OFC1861_u_core_fast_tag_col_6__3 target=INJIHDX2 status=PASS command=ecoChangeCell -inst FE_OFC1861_u_core_fast_tag_col_6__3 -cell INJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:676:FAST_TAG_ECO_UPSIZE_ATTEMPT=FE_OFC1789_u_core_fast_tag_col_6__4 target=INJIHDX2 status=PASS command=ecoChangeCell -inst FE_OFC1789_u_core_fast_tag_col_6__4 -cell INJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:677:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[4].u_fast_tag_tag_o_reg[0] target=DFRSQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[4].u_fast_tag_tag_o_reg[0]} -cell DFRSQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:678:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[4].u_fast_tag_tag_o_reg[6] target=DFRRQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[4].u_fast_tag_tag_o_reg[6]} -cell DFRRQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:679:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[5].u_fast_tag_tag_o_reg[4] target=DFRRQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[5].u_fast_tag_tag_o_reg[4]} -cell DFRRQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:680:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[5].u_fast_tag_tag_o_reg[5] target=DFRRQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[5].u_fast_tag_tag_o_reg[5]} -cell DFRRQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:681:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[1].u_fast_tag_tag_o_reg[5] target=DFRRQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[1].u_fast_tag_tag_o_reg[5]} -cell DFRRQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:682:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[6].u_fast_tag_tag_o_reg[5] target=DFRRQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[6].u_fast_tag_tag_o_reg[5]} -cell DFRRQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:683:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[6].u_fast_tag_tag_o_reg[4] target=DFRRQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[6].u_fast_tag_tag_o_reg[4]} -cell DFRRQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:684:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[0].u_fast_tag_tag_o_reg[0] target=DFRSQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[0].u_fast_tag_tag_o_reg[0]} -cell DFRSQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:685:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[0].u_fast_tag_tag_o_reg[4] target=DFRRQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[0].u_fast_tag_tag_o_reg[4]} -cell DFRRQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:686:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[1].u_fast_tag_tag_o_reg[6] target=DFRRQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[1].u_fast_tag_tag_o_reg[6]} -cell DFRRQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:687:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[6].u_fast_tag_tag_o_reg[3] target=DFRRQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[6].u_fast_tag_tag_o_reg[3]} -cell DFRRQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:688:FAST_TAG_ECO_UPSIZE_ATTEMPT=FE_OFC1437_u_core_fast_tag_col_0__2 target=BUJIHDX4 status=PASS command=ecoChangeCell -inst FE_OFC1437_u_core_fast_tag_col_0__2 -cell BUJIHDX4
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:689:FAST_TAG_ECO_UPSIZE_ATTEMPT=FE_OFC1813_u_core_fast_tag_col_7__0 target=INJIHDX2 status=PASS command=ecoChangeCell -inst FE_OFC1813_u_core_fast_tag_col_7__0 -cell INJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:690:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[3].u_fast_tag_tag_o_reg[5] target=DFRRQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[3].u_fast_tag_tag_o_reg[5]} -cell DFRRQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:691:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[1].u_fast_tag_tag_o_reg[0] target=DFRSQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[1].u_fast_tag_tag_o_reg[0]} -cell DFRSQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:692:FAST_TAG_ECO_UPSIZE_ATTEMPT=FE_OCPC1486_u_core_fast_tag_col_0__3 target=INJIHDX4 status=PASS command=ecoChangeCell -inst FE_OCPC1486_u_core_fast_tag_col_0__3 -cell INJIHDX4
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:693:FAST_TAG_ECO_UPSIZE_ATTEMPT=FE_OCPC1488_u_core_fast_tag_col_0__3 target=BUJIHDX4 status=PASS command=ecoChangeCell -inst FE_OCPC1488_u_core_fast_tag_col_0__3 -cell BUJIHDX4
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:694:FAST_TAG_ECO_UPSIZE_ATTEMPT=FE_OFC1884_u_core_fast_tag_col_2__4 target=INJIHDX4 status=PASS command=ecoChangeCell -inst FE_OFC1884_u_core_fast_tag_col_2__4 -cell INJIHDX4
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:695:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[3].u_fast_tag_tag_o_reg[6] target=DFRRQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[3].u_fast_tag_tag_o_reg[6]} -cell DFRRQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:696:FAST_TAG_ECO_UPSIZE_ATTEMPT=FE_OFC1001_u_core_fast_tag_col_1__3 target=INJIHDX4 status=PASS command=ecoChangeCell -inst FE_OFC1001_u_core_fast_tag_col_1__3 -cell INJIHDX4
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:697:FAST_TAG_ECO_UPSIZE_ATTEMPT=FE_OFC1860_u_core_fast_tag_col_6__2 target=INJIHDX3 status=PASS command=ecoChangeCell -inst FE_OFC1860_u_core_fast_tag_col_6__2 -cell INJIHDX3
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:698:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[2].u_fast_tag_tag_o_reg[5] target=DFRRQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[2].u_fast_tag_tag_o_reg[5]} -cell DFRRQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:699:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[2].u_fast_tag_tag_o_reg[1] target=DFRRQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[2].u_fast_tag_tag_o_reg[1]} -cell DFRRQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:700:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[0].u_fast_tag_tag_o_reg[2] target=DFRRQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[0].u_fast_tag_tag_o_reg[2]} -cell DFRRQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:701:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[7].u_fast_tag_tag_o_reg[0] target=DFRSQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[7].u_fast_tag_tag_o_reg[0]} -cell DFRSQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:702:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[0].u_fast_tag_tag_o_reg[5] target=DFRRQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[0].u_fast_tag_tag_o_reg[5]} -cell DFRRQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:703:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[5].u_fast_tag_tag_o_reg[6] target=DFRRQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[5].u_fast_tag_tag_o_reg[6]} -cell DFRRQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:704:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[1].u_fast_tag_tag_o_reg[2] target=DFRRQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[1].u_fast_tag_tag_o_reg[2]} -cell DFRRQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:705:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[0].u_fast_tag_tag_o_reg[3] target=DFRRQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[0].u_fast_tag_tag_o_reg[3]} -cell DFRRQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:706:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[2].u_fast_tag_tag_o_reg[4] target=DFRRQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[2].u_fast_tag_tag_o_reg[4]} -cell DFRRQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:707:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[1].u_fast_tag_tag_o_reg[3] target=DFRRQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[1].u_fast_tag_tag_o_reg[3]} -cell DFRRQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:708:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[6].u_fast_tag_tag_o_reg[2] target=DFRRQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[6].u_fast_tag_tag_o_reg[2]} -cell DFRRQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:709:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[1].u_fast_tag_tag_o_reg[1] target=DFRRQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[1].u_fast_tag_tag_o_reg[1]} -cell DFRRQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:710:FAST_TAG_ECO_UPSIZE_ATTEMPT=FE_OFC1814_u_core_fast_tag_col_7__0 target=INJIHDX3 status=PASS command=ecoChangeCell -inst FE_OFC1814_u_core_fast_tag_col_7__0 -cell INJIHDX3
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:711:FAST_TAG_ECO_UPSIZE_ATTEMPT=FE_OFC1788_u_core_fast_tag_col_6__4 target=INJIHDX2 status=PASS command=ecoChangeCell -inst FE_OFC1788_u_core_fast_tag_col_6__4 -cell INJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:712:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[0].u_fast_tag_tag_o_reg[6] target=DFRRQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[0].u_fast_tag_tag_o_reg[6]} -cell DFRRQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:713:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[2].u_fast_tag_tag_o_reg[6] target=DFRRQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[2].u_fast_tag_tag_o_reg[6]} -cell DFRRQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:714:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[7].u_fast_tag_tag_o_reg[6] target=DFRRQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[7].u_fast_tag_tag_o_reg[6]} -cell DFRRQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:715:FAST_TAG_ECO_UPSIZE_ATTEMPT=u_core_gen_fast_tag_col[6].u_fast_tag_tag_o_reg[6] target=DFRRQJIHDX2 status=PASS command=ecoChangeCell -inst {u_core_gen_fast_tag_col[6].u_fast_tag_tag_o_reg[6]} -cell DFRRQJIHDX2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_targeted_eco.rpt:719:FAST_TAG_TARGETED_ECO_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/cts_clk_sys_constraint_cleanup.rpt:8:INTERACTIVE_CONSTRAINT_MODE_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/cts_clk_sys_constraint_cleanup.rpt:12:CLK_SYS_CTS_CLEANUP_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/cts_clk_sys_constraint_cleanup.rpt:14:CLK_SYS_CTS_FANOUT_PROPERTY_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/cts_clk_sys_constraint_cleanup.rpt:16:CLK_SYS_CTS_FANOUT_PROPERTY_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_status.rpt:6:FILLER_MODE_STATUS=PASS_OR_REVIEW
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_status.rpt:9:FILLER_INSERTION_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_status.rpt:19:POST_FILLER_ROUTE_POST_FILLER_PRE_SROUTE_COMMAND_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_status.rpt:20:POST_FILLER_ROUTE_POST_FILLER_PRE_SROUTE_ROUTER_DRC=5
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_status.rpt:21:POST_FILLER_ROUTE_POST_FILLER_PRE_SROUTE_ROUTER_SHORTS=2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_status.rpt:24:POST_FILLER_SROUTE_MODE_CORE_PIN_STOP_ROUTE_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_status.rpt:26:POST_FILLER_SROUTE_MODE_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_status.rpt:32:POST_FILLER_SROUTE_ATTEMPT_1_COMMAND_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_status.rpt:33:POST_FILLER_SROUTE_ATTEMPT_1_STATUS=REVIEW_REQUIRED
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_status.rpt:35:POST_FILLER_SROUTE_ATTEMPT_1_OPEN_PORTS=48
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_status.rpt:36:POST_FILLER_SROUTE_ATTEMPT_1_BLOCK_OPEN_PORTS=24
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_status.rpt:37:POST_FILLER_SROUTE_ATTEMPT_1_CORE_OPEN_PORTS=24
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_status.rpt:38:POST_FILLER_SROUTE_ATTEMPT_1_POWER_BUMP_OPEN_PORTS=0
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_status.rpt:40:POST_FILLER_SROUTE_STATUS=FAIL
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_status.rpt:45:POST_FILLER_ROUTE_POST_FILLER_POST_SROUTE_COMMAND_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_status.rpt:46:POST_FILLER_ROUTE_POST_FILLER_POST_SROUTE_ROUTER_DRC=3
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_status.rpt:47:POST_FILLER_ROUTE_POST_FILLER_POST_SROUTE_ROUTER_SHORTS=2
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_status.rpt:49:POST_FILLER_VERIFY_DRC_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_status.rpt:50:POST_FILLER_VERIFY_DRC_MARKER_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc_markers.tsv
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_status.rpt:51:POST_FILLER_VERIFY_DRC_CAPTURE_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_status.rpt:52:POST_FILLER_VERIFY_DRC=12
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_status.rpt:53:POST_FILLER_VERIFY_SHORTS=7
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_status.rpt:55:POST_FILLER_SPECIAL_CONNECTIVITY_CAPTURE_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_status.rpt:60:POST_FILLER_ALL_CONNECTIVITY_CAPTURE_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_status.rpt:63:POST_FILLER_VERIFY_STATUS=REVIEW_REQUIRED
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_status.rpt:64:POST_FILLER_ROUTE_STATUS=REVIEW_REQUIRED
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_status.rpt:65:INCREMENTAL_ROUTE_STATUS=REVIEW_REQUIRED
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/filler_status.rpt:66:POST_FILLER_CLEANUP_STATUS=REVIEW_REQUIRED
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:2: *** Starting Verify DRC (MEM: 3145.3) ***
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:4:  VERIFY DRC ...... Starting Verification
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:5:  VERIFY DRC ...... Initializing
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:6:  VERIFY DRC ...... Deleting Existing Violations
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:7:  VERIFY DRC ...... Creating Sub-Areas
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:8:  VERIFY DRC ...... Using new threading
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:9:  VERIFY DRC ...... Sub-Area: {0.000 0.000 213.440 202.400} 1 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:10:  VERIFY DRC ...... Sub-Area : 1 complete 5 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:11:  VERIFY DRC ...... Sub-Area: {213.440 0.000 426.880 202.400} 2 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:12:  VERIFY DRC ...... Sub-Area : 2 complete 0 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:13:  VERIFY DRC ...... Sub-Area: {426.880 0.000 640.320 202.400} 3 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:14:  VERIFY DRC ...... Sub-Area : 3 complete 0 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:15:  VERIFY DRC ...... Sub-Area: {640.320 0.000 853.760 202.400} 4 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:16:  VERIFY DRC ...... Sub-Area : 4 complete 0 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:17:  VERIFY DRC ...... Sub-Area: {853.760 0.000 1061.200 202.400} 5 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:18:  VERIFY DRC ...... Sub-Area : 5 complete 0 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:19:  VERIFY DRC ...... Sub-Area: {0.000 202.400 213.440 404.800} 6 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:20:  VERIFY DRC ...... Sub-Area : 6 complete 0 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:21:  VERIFY DRC ...... Sub-Area: {213.440 202.400 426.880 404.800} 7 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:22:  VERIFY DRC ...... Sub-Area : 7 complete 0 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:23:  VERIFY DRC ...... Sub-Area: {426.880 202.400 640.320 404.800} 8 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:24:  VERIFY DRC ...... Sub-Area : 8 complete 0 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:25:  VERIFY DRC ...... Sub-Area: {640.320 202.400 853.760 404.800} 9 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:26:  VERIFY DRC ...... Sub-Area : 9 complete 0 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:27:  VERIFY DRC ...... Sub-Area: {853.760 202.400 1061.200 404.800} 10 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:28:  VERIFY DRC ...... Sub-Area : 10 complete 0 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:29:  VERIFY DRC ...... Sub-Area: {0.000 404.800 213.440 607.200} 11 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:30:  VERIFY DRC ...... Sub-Area : 11 complete 1 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:31:  VERIFY DRC ...... Sub-Area: {213.440 404.800 426.880 607.200} 12 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:32:  VERIFY DRC ...... Sub-Area : 12 complete 3 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:33:  VERIFY DRC ...... Sub-Area: {426.880 404.800 640.320 607.200} 13 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:34:  VERIFY DRC ...... Sub-Area : 13 complete 1 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:35:  VERIFY DRC ...... Sub-Area: {640.320 404.800 853.760 607.200} 14 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:36:  VERIFY DRC ...... Sub-Area : 14 complete 0 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:37:  VERIFY DRC ...... Sub-Area: {853.760 404.800 1061.200 607.200} 15 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:38:  VERIFY DRC ...... Sub-Area : 15 complete 0 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:39:  VERIFY DRC ...... Sub-Area: {0.000 607.200 213.440 801.920} 16 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:40:  VERIFY DRC ...... Sub-Area : 16 complete 2 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:41:  VERIFY DRC ...... Sub-Area: {213.440 607.200 426.880 801.920} 17 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:42:  VERIFY DRC ...... Sub-Area : 17 complete 0 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:43:  VERIFY DRC ...... Sub-Area: {426.880 607.200 640.320 801.920} 18 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:44:  VERIFY DRC ...... Sub-Area : 18 complete 0 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:45:  VERIFY DRC ...... Sub-Area: {640.320 607.200 853.760 801.920} 19 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:46:  VERIFY DRC ...... Sub-Area : 19 complete 0 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:47:  VERIFY DRC ...... Sub-Area: {853.760 607.200 1061.200 801.920} 20 of 20
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:48:  VERIFY DRC ...... Sub-Area : 20 complete 0 Viols.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/post_filler_verify_drc.rpt:59: *** End Verify DRC (CPU TIME: 0:00:06.6  ELAPSED TIME: 0:00:07.0  MEM: 264.1M) ***
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_column_placement.rpt:81:FAST_TAG_COLUMN_FAILURES=0
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_column_placement.rpt:82:FAST_TAG_COLUMN_PLACEMENT_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pg_postroute_connectivity_status.rpt:2:PG_CONNECTIVITY_STATUS=FAIL
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_timing_focus.rpt:11:GROUP_PATH_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_timing_focus.rpt:12:SOURCE_CRITICAL_RANGE_STATUS=SKIPPED
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_timing_focus.rpt:14:SOURCE_MAX_TRANSITION_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_timing_focus.rpt:15:FAST_TAG_TIMING_REPORT_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/fast_tag_timing_focus.rpt:16:FAST_TAG_TIMING_FOCUS_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_ecoRoute_target_markers_schema.rpt:2:marker: DRC Marker
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_ecoRoute_target_markers_schema.rpt:19:message: string, DRC marker message
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_ecoRoute_target_markers_schema.rpt:20:messageId: int, DRC marker message ID
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_ecoRoute_target_markers_schema.rpt:21:objType: enum(antennaData antennaModel bndry bump bumpGrid bumpTerm bus busGuide busSinkGroup cellDensity densityShape fPlan foreign gCellGridDef group guiLine guiPoly guiRect guiText hInst hInstTerm hNet hTerm head inst instTerm io layer layerRule layerShape libCell marker net netGroup pBlkg pWire pd pgInstTerm pin pinGroup pinGuide pinShape pkgComponent pkgObject prop ptn ptnCell ptnPinBlkg rBlkg resistor resizeBlkg routeType row rule sViaInst sWire sdp shape shapeVia site stackViaRule term text topCell trackDef vCell vWire via viaInst viaRuleGenerate whatIfVia whatIfWire wire), Object type: DRC Marker
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/route_recovery_ecoRoute_target_markers_schema.rpt:22:objects: objList(bump inst instTerm net term), The objects which caused the DRC. The list may be empty, and is currently limited to at most 2 objects.
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_rc_parser_selftest_status.rpt:8:PARSE_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_rc_parser_selftest_status.rpt:20:RC_SYMMETRY_FAILURE_CLASSIFICATION=PARSER_FALSE_FAILURE
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_rc_parser_selftest_status.rpt:27:PHASE_RC_PARSE_ORIGINAL_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_rc_parser_selftest_status.rpt:28:PHASE_LOAD_ORIGINAL_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_rc_parser_selftest_status.rpt:29:RC_SYMMETRY_ORIGINAL_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_rc_parser_selftest_status.rpt:30:RC_SYMMETRY_ORIGINAL_CLASSIFICATION=PARSER_FALSE_FAILURE
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_rc_parser_selftest_status.rpt:175:PHASE_LOAD_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/phase_rc_parser_selftest_status.rpt:176:RC_SYMMETRY_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postplace_pre_route_block_pg_stitch_status.rpt:3:POSTPLACE_PRE_ROUTE_BLOCK_PG_STITCH_STATUS=SKIPPED
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/io_status.rpt:1:IO_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:16:  tile_region group=mptdc_pd_tile_0_0 member_count=34 box=50.4 250.88 87.92 288.4 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:25:  tile_region group=mptdc_pd_tile_0_1 member_count=33 box=50.4 288.4 87.92 325.92 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:34:  tile_region group=mptdc_pd_tile_0_2 member_count=33 box=50.4 325.92 87.92 363.44 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:43:  tile_region group=mptdc_pd_tile_0_3 member_count=32 box=50.4 363.44 87.92 400.96 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:52:  tile_region group=mptdc_pd_tile_0_4 member_count=39 box=50.4 400.96 87.92 438.48 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:61:  tile_region group=mptdc_pd_tile_0_5 member_count=32 box=50.4 438.48 87.92 476.0 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:70:  tile_region group=mptdc_pd_tile_0_6 member_count=39 box=50.4 476.0 87.92 513.52 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:79:  tile_region group=mptdc_pd_tile_0_7 member_count=32 box=50.4 513.52 87.92 551.04 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:88:  tile_region group=mptdc_pd_tile_1_0 member_count=32 box=87.92 250.88 125.44 288.4 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:97:  tile_region group=mptdc_pd_tile_1_1 member_count=39 box=87.92 288.4 125.44 325.92 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:106:  tile_region group=mptdc_pd_tile_1_2 member_count=33 box=87.92 325.92 125.44 363.44 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:115:  tile_region group=mptdc_pd_tile_1_3 member_count=32 box=87.92 363.44 125.44 400.96 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:124:  tile_region group=mptdc_pd_tile_1_4 member_count=33 box=87.92 400.96 125.44 438.48 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:133:  tile_region group=mptdc_pd_tile_1_5 member_count=32 box=87.92 438.48 125.44 476.0 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:142:  tile_region group=mptdc_pd_tile_1_6 member_count=32 box=87.92 476.0 125.44 513.52 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:151:  tile_region group=mptdc_pd_tile_1_7 member_count=39 box=87.92 513.52 125.44 551.04 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:160:  tile_region group=mptdc_pd_tile_2_0 member_count=34 box=125.44 250.88 162.96 288.4 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:169:  tile_region group=mptdc_pd_tile_2_1 member_count=33 box=125.44 288.4 162.96 325.92 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:178:  tile_region group=mptdc_pd_tile_2_2 member_count=33 box=125.44 325.92 162.96 363.44 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:187:  tile_region group=mptdc_pd_tile_2_3 member_count=32 box=125.44 363.44 162.96 400.96 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:196:  tile_region group=mptdc_pd_tile_2_4 member_count=39 box=125.44 400.96 162.96 438.48 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:205:  tile_region group=mptdc_pd_tile_2_5 member_count=32 box=125.44 438.48 162.96 476.0 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:214:  tile_region group=mptdc_pd_tile_2_6 member_count=39 box=125.44 476.0 162.96 513.52 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:223:  tile_region group=mptdc_pd_tile_2_7 member_count=32 box=125.44 513.52 162.96 551.04 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:232:  tile_region group=mptdc_pd_tile_3_0 member_count=34 box=162.96 250.88 200.48 288.4 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:241:  tile_region group=mptdc_pd_tile_3_1 member_count=33 box=162.96 288.4 200.48 325.92 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:250:  tile_region group=mptdc_pd_tile_3_2 member_count=33 box=162.96 325.92 200.48 363.44 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:259:  tile_region group=mptdc_pd_tile_3_3 member_count=32 box=162.96 363.44 200.48 400.96 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:268:  tile_region group=mptdc_pd_tile_3_4 member_count=39 box=162.96 400.96 200.48 438.48 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:277:  tile_region group=mptdc_pd_tile_3_5 member_count=32 box=162.96 438.48 200.48 476.0 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:286:  tile_region group=mptdc_pd_tile_3_6 member_count=39 box=162.96 476.0 200.48 513.52 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:295:  tile_region group=mptdc_pd_tile_3_7 member_count=32 box=162.96 513.52 200.48 551.04 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:304:  tile_region group=mptdc_pd_tile_4_0 member_count=39 box=200.48 250.88 238.0 288.4 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:313:  tile_region group=mptdc_pd_tile_4_1 member_count=39 box=200.48 288.4 238.0 325.92 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:322:  tile_region group=mptdc_pd_tile_4_2 member_count=33 box=200.48 325.92 238.0 363.44 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:331:  tile_region group=mptdc_pd_tile_4_3 member_count=32 box=200.48 363.44 238.0 400.96 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:340:  tile_region group=mptdc_pd_tile_4_4 member_count=39 box=200.48 400.96 238.0 438.48 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:349:  tile_region group=mptdc_pd_tile_4_5 member_count=39 box=200.48 438.48 238.0 476.0 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:358:  tile_region group=mptdc_pd_tile_4_6 member_count=33 box=200.48 476.0 238.0 513.52 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:367:  tile_region group=mptdc_pd_tile_4_7 member_count=32 box=200.48 513.52 238.0 551.04 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:376:  tile_region group=mptdc_pd_tile_5_0 member_count=39 box=238.0 250.88 275.52 288.4 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:385:  tile_region group=mptdc_pd_tile_5_1 member_count=32 box=238.0 288.4 275.52 325.92 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:394:  tile_region group=mptdc_pd_tile_5_2 member_count=33 box=238.0 325.92 275.52 363.44 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:403:  tile_region group=mptdc_pd_tile_5_3 member_count=32 box=238.0 363.44 275.52 400.96 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:412:  tile_region group=mptdc_pd_tile_5_4 member_count=39 box=238.0 400.96 275.52 438.48 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:421:  tile_region group=mptdc_pd_tile_5_5 member_count=32 box=238.0 438.48 275.52 476.0 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:430:  tile_region group=mptdc_pd_tile_5_6 member_count=33 box=238.0 476.0 275.52 513.52 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:439:  tile_region group=mptdc_pd_tile_5_7 member_count=32 box=238.0 513.52 275.52 551.04 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:448:  tile_region group=mptdc_pd_tile_6_0 member_count=39 box=275.52 250.88 313.04 288.4 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:457:  tile_region group=mptdc_pd_tile_6_1 member_count=32 box=275.52 288.4 313.04 325.92 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:466:  tile_region group=mptdc_pd_tile_6_2 member_count=33 box=275.52 325.92 313.04 363.44 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:475:  tile_region group=mptdc_pd_tile_6_3 member_count=32 box=275.52 363.44 313.04 400.96 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:484:  tile_region group=mptdc_pd_tile_6_4 member_count=39 box=275.52 400.96 313.04 438.48 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:493:  tile_region group=mptdc_pd_tile_6_5 member_count=32 box=275.52 438.48 313.04 476.0 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:502:  tile_region group=mptdc_pd_tile_6_6 member_count=33 box=275.52 476.0 313.04 513.52 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:511:  tile_region group=mptdc_pd_tile_6_7 member_count=32 box=275.52 513.52 313.04 551.04 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:520:  tile_region group=mptdc_pd_tile_7_0 member_count=32 box=313.04 250.88 350.56 288.4 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:529:  tile_region group=mptdc_pd_tile_7_1 member_count=39 box=313.04 288.4 350.56 325.92 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:538:  tile_region group=mptdc_pd_tile_7_2 member_count=33 box=313.04 325.92 350.56 363.44 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:547:  tile_region group=mptdc_pd_tile_7_3 member_count=32 box=313.04 363.44 350.56 400.96 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:556:  tile_region group=mptdc_pd_tile_7_4 member_count=33 box=313.04 400.96 350.56 438.48 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:565:  tile_region group=mptdc_pd_tile_7_5 member_count=32 box=313.04 438.48 350.56 476.0 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:574:  tile_region group=mptdc_pd_tile_7_6 member_count=32 box=313.04 476.0 350.56 513.52 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/pd_matrix_floorplan.rpt:583:  tile_region group=mptdc_pd_tile_7_7 member_count=39 box=313.04 513.52 350.56 551.04 constraint=MEMBERS_ONLY status=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_phase_overlap_pre_place_audit.rpt:9:CHECKPLACE_OVERLAP_STATUS=REVIEW_REQUIRED
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_phase_overlap_pre_place_audit.rpt:82:SLOW_RO_PHASE_PLACEMENT_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_phase_overlap_pre_place_audit.rpt:155:FAST_RO_PHASE_PLACEMENT_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/ro_phase_overlap_pre_place_audit.rpt:160:RO_PHASE_PLACEMENT_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_setup_pass_2_timing.rpt:20:|           WNS (ns):| -0.020  | -0.020  |   N/A   |
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/postroute_opt_setup_pass_2_timing.rpt:21:|           TNS (ns):| -0.125  | -0.125  |   N/A   |
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/cts_clk_sys_spec_audit.rpt:11:SPEC_COMMAND_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/cts_clk_sys_spec_audit.rpt:21:CTS_SPEC_AUDIT_STATUS=PASS
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/hold_post_cts.rpt:34:|           WNS (ns):| -0.104  |  0.101  | -0.104  |
/sim/ksabra/SPADMIC_work/innovus/20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_235658/reports/hold_post_cts.rpt:35:|           TNS (ns):| -0.930  |  0.000  | -0.930  |
