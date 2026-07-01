# MPTDC PnR-LEF Free-All Aggressive Final Checkpoint - 2026-07-01

## Purpose

This document records the pre-repair evidence for the best MPTDC TC-only PnR
candidate produced so far:

```text
/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_ro6_pnrlef_freeall_aggr_final_211109
```

The run is not a final signoff result. It is a route-geometry-clean,
regular-connectivity-clean, post-filler candidate that stopped only because the
strict route gate rejected eight VDD/VSS special-net dangling-wire markers.

This file intentionally captures the checkpoint before any later surgical
repair result is interpreted.

## Classification

```text
MPTDC_CLOSURE_SCOPE=TC_ONLY
NOT_MMMC_SIGNOFF=YES
READY_FOR_TAPEOUT=NO
MPTDC_TC_PHYSICAL_SIGNOFF=NO
DIGITAL_PNR_SIGNOFF=PROVISIONAL
ROUTE_STATUS=FAIL
FAILURE_CLASS=PG_SPECIAL_DANGLING_ONLY_AFTER_ROUTE_AND_FILLER
GEOMETRY_DRC_VIOLATIONS=0
SHORTS=0
REGULAR_NET_CONNECTIVITY_BAD=0
SPECIAL_NET_CONNECTIVITY_BAD=1
SPECIAL_NET_BAD_LINES={Net VDD: dangling Wire.} {Net VSS: dangling Wire.} {8 Problem(s) (IMPVFC-94): The net has dangling wire(s).} {Verification Complete : 8 Viols.  0 Wrngs.}
```

Important distinction:

- This is no longer the earlier RO macro-access geometry short problem.
- Innovus route DRC is clean.
- The router transcript and `verify_drc` both report zero DRC and zero shorts.
- Regular signal connectivity is clean.
- The remaining blocker is VDD/VSS special connectivity, specifically eight
  dangling special-wire markers.
- Extraction/STA and final physical-verification package stages did not run
  because the route stage is a hard gate unless dirty-route continuation is
  explicitly enabled.

## Repository And Run Identity

Server-side repository:

```text
repo=/home/validmgr/ksabra/2026_SPAD/SPADMIC
branch=SPADMIC_test
head=fd295f995feb9e59e4b6dd37682db096d555d7ed
EXPECTED_HEAD=fd295f995feb9e59e4b6dd37682db096d555d7ed
```

Run identity:

```text
run_id=20260701_mptdc_ro6_pnrlef_freeall_aggr_final_211109
result_dir=/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_ro6_pnrlef_freeall_aggr_final_211109
mode=full_signoff
date=2026-07-01T21:11:09+02:00
genus_run_id=MPTDC_TC_Closure_Genus_RO6_xx31_20260629_1233
handoff_dir=/sim/ksabra/SPADMIC_work/handoff/genus_typical/MPTDC_TC_Closure_Genus_RO6_xx31_20260629_1233_handoff
```

Checkpoint to preserve:

```text
/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_ro6_pnrlef_freeall_aggr_final_211109/checkpoints/04_route_failed.enc.dat
```

Associated failed-route DEF:

```text
/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_ro6_pnrlef_freeall_aggr_final_211109/def/04_route_failed.def
```

The checkpoint name contains `failed` because the wrapper route gate failed. It
does not mean geometry DRC failed.

## PnR-Only RO LEF Preparation

The final candidate did not use the golden RO LEF directly as the routing
abstract. A PnR-only RO LEF was generated from the prior free-all failed-route
marker audit.

Inputs:

```sh
export SOURCE_LEF=/group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune6.lef
export FAILED_FREEALL_DIR=/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_ro6_cleanlef_freeall_route_timing_pgfix_191721
export PNR_LEF=/sim/ksabra/SPADMIC_work/lef/RO_tune6_pnr_pin_access_from_freeall_failed_191721_v2.lef
```

Command:

```sh
MPTDC/pnr/scripts/server_prepare_ro_tune6_pnr_lef.sh \
  --run "$FAILED_FREEALL_DIR" \
  --source-lef "$SOURCE_LEF" \
  --out-lef "$PNR_LEF"
```

Key preparation output:

```text
RO_PNR_LEF=/sim/ksabra/SPADMIC_work/lef/RO_tune6_pnr_pin_access_from_freeall_failed_191721_v2.lef
ACCESS_WINDOW_COUNT=16
ACCESS_WINDOWS_BY_LAYER MET1 1
ACCESS_WINDOWS_BY_LAYER MET2 12
ACCESS_WINDOWS_BY_LAYER MET3 3
OBS_RECTS_TOUCHED=30
OBS_RECTS_REMOVED=1
```

Access windows by pin:

```text
S[0] 2
S[1] 3
S[2] 1
S[3] 1
S[4] 1
S[5] 1
S[6] 3
S[7] 1
VDD 1
VSS 1
rstb 1
```

No `code[x]` access windows were generated in this PnR LEF because the audit did
not classify the code-net markers as OBS-overlap access blockages that should be
patched blindly. The selected patch set targeted the actual OBS-overlap/no-pin
regions from the failing RO-local geometry evidence.

## Exact Final Candidate Launch

Environment before launch:

```sh
export EXPECTED_HEAD=fd295f995feb9e59e4b6dd37682db096d555d7ed
export SOURCE_LEF=/group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune6.lef
export PNR_LEF=/sim/ksabra/SPADMIC_work/lef/RO_tune6_pnr_pin_access_from_freeall_failed_191721_v2.lef
export FINAL_RUN_ID=20260701_mptdc_ro6_pnrlef_freeall_aggr_final_211109
```

Command:

```sh
MPTDC/pnr/scripts/server_run_mptdc_tc_ro6_cleanlef.sh \
  --stage final_candidate \
  --free-all-internal \
  --aggressive-postroute \
  --source-lef "$SOURCE_LEF" \
  --pnr-lef "$PNR_LEF" \
  --enable-route-recovery \
  --route-repair-commands '{ecoRoute -target} {ecoRoute -fix_drc}' \
  --run-id "$FINAL_RUN_ID" \
  --expected-head "$EXPECTED_HEAD"
```

Wrapper launch echo:

```text
REPO_ROOT=/home/validmgr/ksabra/2026_SPAD/SPADMIC
BRANCH=SPADMIC_test
ACTUAL_HEAD=fd295f995feb9e59e4b6dd37682db096d555d7ed
EXPECTED_HEAD=fd295f995feb9e59e4b6dd37682db096d555d7ed
RUN_ID=20260701_mptdc_ro6_pnrlef_freeall_aggr_final_211109
RUN_DIR=/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_ro6_pnrlef_freeall_aggr_final_211109
STAGE=final_candidate
FINAL_LEF=/group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune6.lef
PNR_LEF=/sim/ksabra/SPADMIC_work/lef/RO_tune6_pnr_pin_access_from_freeall_failed_191721_v2.lef
MPTDC_PG_STRATEGY=conservative_ro_hookup_blockpin_probe
INNOVUS_RO_LEF=/sim/ksabra/SPADMIC_work/lef/RO_tune6_pnr_pin_access_from_freeall_failed_191721_v2.lef
O1_RO_LIBERTY_PATH=/home/validmgr/ksabra/2026_SPAD/SPADMIC/MPTDC/syn/macros/RO_tune6_real_layout_shell.lib
```

## Effective Environment Contract

RO macro and library:

```text
O1_USE_REAL_RO_ABSTRACT=1
O1_RO_CELL_NAME=RO_tune6
O1_RO_LEF_PATH=/sim/ksabra/SPADMIC_work/lef/RO_tune6_pnr_pin_access_from_freeall_failed_191721_v2.lef
O1_RO_LEF_MACRO=RO_tune6
O1_RO_LIBERTY_PATH=/home/validmgr/ksabra/2026_SPAD/SPADMIC/MPTDC/syn/macros/RO_tune6_real_layout_shell.lib
MPTDC_PNR_OSC_WIDTH_UM=168.945
MPTDC_PNR_OSC_HEIGHT_UM=70.5
MPTDC_RO_LEF_SIZE_STATUS=PASS
```

Technology and closure scope:

```text
closure_scope=TC_ONLY
xh018_stack=xx31
technology_lef=/eda/pdk/xfab/xh018/cadence/v9_0/techLEF/v9_0_1/xh018_xx31_HD_MET3_METMID.lef
captable_bc=/eda/pdk/xfab/xh018/cadence/v9_0/capTbl/v9_0_1/xh018_xx31_MET3_METMID_min.capTbl
captable_tc=/eda/pdk/xfab/xh018/cadence/v9_0/capTbl/v9_0_1/xh018_xx31_MET3_METMID_typ.capTbl
captable_wc=/eda/pdk/xfab/xh018/cadence/v9_0/capTbl/v9_0_1/xh018_xx31_MET3_METMID_max.capTbl
qrc_root=/eda/pdk/xfab/xh018/cadence/v10_1/QRC_pvs/v10_1_1/XH018_1131
route_layers=MET1 MET2 MET3 METTP
signal_top_layer=MET3
effective_top_floor_layer=METTP
```

Free internal placement:

```text
pd_tile_constraint_mode=none
pd_tile_apply_hier_box=0
pd_tile_region_margin_um=0.0
pd_physical_audit_mode=free_internal
pnr_core_util=0.55
free_all_internal_placement=1
free_internal_placement=1
skip_phase_buffer_preplace=1
fix_ro_macros=0
create_ro_halos=0
place_fast_tags_by_column=0
fast_tag_column_side=center
```

Phase/RO placement policy:

```text
phase_buf_orient=ROW_LEGAL
row_legal_orient_candidates=MX R180 MY R0
ro_phase_min_clearance_um=10.0
ro_phase_origin_clearance_um=16.0
ro_phase_preplace_audit=1
ro_phase_postplace_audit_fatal=0
```

Aggressive post-route setup/fast-tag ECO:

```text
postroute_setup_passes=10
postroute_setup_max_passes=10
postroute_setup_plateau_guard=0
fast_tag_targeted_eco=1
fast_tag_eco_protect_endpoint_flops=0
fast_tag_eco_upsize_small_gates=1
fast_tag_eco_path_driven=1
fast_tag_eco_path_max_paths=300
fast_tag_eco_path_max_cells=360
fast_tag_eco_name_fallback=1
fast_tag_eco_allow_endpoint_flop_resize=1
MPTDC_POSTROUTE_SETUP_TARGET_SLACK_NS=0.020
MPTDC_POSTROUTE_HOLD_TARGET_SLACK_NS=0.010
```

PG and sroute strategy:

```text
block_pg_pins=1
block_pg_pin_layer=METTP
block_pg_pin_style=mesh_lr_vdd_vss
block_pg_pin_width_um=4.0
block_pg_pin_depth_um=28.0
block_pg_pin_outside_overlap_um=8.0
block_pg_pin_create_mode=geom
block_pg_pin_editpin_fallback=0
pg_policy_guard=PASS
allow_legacy_pg_topology=0
block_pg_stitch_stripes=0
preplace_pg_sroute=0
allow_provisional_preplace_pg=1
postplace_pre_route_sroute=1
postplace_pre_route_sroute_require_clean=1
postplace_pre_route_accept_pg_verify_clean=1
postplace_pre_route_allow_dangling_only=1
postplace_pre_route_dangling_only_max=64
postplace_sroute_candidate_probe=1
postplace_sroute_blockpin=1
sroute_padpin_fallback=0
sroute_mode_experiments=0
sroute_preserve_existing_routes=0
sroute_connect_stripe=1
sroute_core_pin_stop_route=RowEnd
```

RO PG hookup:

```text
ro_pg_probe=1
ro_pg_hookup=1
ro_pg_hookup_required=1
ro_pg_macro_patch=0
allow_ro_derived_pg_dangling=0
ro_pg_hookup_search_um=45.0
ro_pg_hookup_margin_um=1.0
ro_pg_hookup_spacing_um=2.0
ro_pg_hookup_set_distance_um=5000.0
```

Route/filler policy:

```text
route_gate_sroute_recovery=0
route_repair_commands={ecoRoute -target} {ecoRoute -fix_drc}
route_drc_review_continue=0
route_drc_review_max_violations=0
route_drc_review_allowed_classes=Mar
dirty_route_timing_continue=0
final_filler=1
post_filler_sroute=0
post_filler_sroute_required_bypass=0
filler_add_fillers_with_drc=0
require_drc_safe_filler=1
```

The route gate was intentionally strict. `MPTDC_ALLOW_DIRTY_ROUTE_TIMING_CONTINUE`
was not enabled for this run.

## Stage Timeline

From `manifests/stage_trace.csv`:

```text
2026-07-01 21:11:36 CEST source_gate start
2026-07-01 21:11:36 CEST source_gate done
2026-07-01 21:11:36 CEST import_mmmc start
2026-07-01 21:11:41 CEST import_mmmc done
2026-07-01 21:11:41 CEST post_import_gate start
2026-07-01 21:11:41 CEST post_import_gate done
2026-07-01 21:11:41 CEST post_import_tc_timing start
2026-07-01 21:11:50 CEST post_import_tc_timing done
2026-07-01 21:11:50 CEST floorplan start
2026-07-01 21:11:52 CEST floorplan done
2026-07-01 21:11:52 CEST io_placement start
2026-07-01 21:11:52 CEST io_placement done
2026-07-01 21:11:52 CEST ro_macro_placement start
2026-07-01 21:11:52 CEST ro_macro_placement done
2026-07-01 21:11:52 CEST pg_connectivity start
2026-07-01 21:11:52 CEST pg_connectivity done
2026-07-01 21:11:52 CEST pd_matrix_placement start
2026-07-01 21:11:52 CEST pd_matrix_placement done
2026-07-01 21:11:52 CEST phase_buffer_placement start
2026-07-01 21:11:54 CEST phase_buffer_placement done
2026-07-01 21:11:54 CEST row_infrastructure start
2026-07-01 21:11:54 CEST row_infrastructure done
2026-07-01 21:11:54 CEST placement start
2026-07-01 21:15:45 CEST placement done
2026-07-01 21:15:45 CEST cts start
2026-07-01 21:22:12 CEST cts done
2026-07-01 21:22:12 CEST route start
2026-07-01 21:47:25 CEST route fail
```

Approximate runtime:

```text
start_to_route_gate_failure=36m16s
placement_stage=3m51s
cts_stage=6m27s
route_stage_including_postroute_opt_filler_gate=25m13s
```

## Route Gate Result

From `reports/route_status.rpt`:

```text
ROUTE_STATUS=FAIL
ROUTE_IMPLEMENTATION_STATUS=FAIL
INNOVUS_VERIFY_DRC_STATUS=PASS
FOUNDRY_DRC_STATUS=DEFERRED
GEOMETRY_DRC_VIOLATIONS=0
SHORTS=0
ROUTER_TRANSCRIPT_DRC=0
ROUTER_TRANSCRIPT_SHORTS=0
ROUTER_TRANSCRIPT_STATUS=PASS
ROUTER_TRANSCRIPT_SOURCE=/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_ro6_pnrlef_freeall_aggr_final_211109/reports/route_recovery_ecoRoute_fix_drc.rpt
INNOVUS_VERIFY_DRC_VIOLATIONS_RAW=0
INNOVUS_VERIFY_DRC_SHORTS_RAW=0
REGULAR_NET_CONNECTIVITY_BAD=0
SPECIAL_NET_CONNECTIVITY_BAD=1
SPECIAL_NET_BAD_LINES={Net VDD: dangling Wire.} {Net VSS: dangling Wire.} {8 Problem(s) (IMPVFC-94): The net has dangling wire(s).} {Verification Complete : 8 Viols.  0 Wrngs.}
SPECIAL_NET_CONNECTIVITY_RAW_BAD=1
SPECIAL_NET_CONNECTIVITY_FILTER_STATUS=DISABLED
SPECIAL_NET_CONNECTIVITY_FILTERED_RO_TERMINALS=0
SPECIAL_NET_CONNECTIVITY_NON_RO_FAILURES=0
REGULAR_NET_OPENS=0
SPECIAL_NET_OPENS=NONZERO_OR_UNPARSED
UNROUTED_NETS=UNKNOWN
UNROUTED_NETS_SOURCE=report_route
PARTIAL_ROUTES=REVIEW_REPORT_ROUTE
ANTENNA_STATUS=PROVISIONAL_WITH_LEF_ANTENNA_COMPLETENESS_REVIEW
DIRTY_ROUTE_TIMING_CONTINUE=0
ROUTE_GATE_FAILURE_CHECKPOINT_DAT_EXISTS=1
```

From `reports/route_drc.rpt`:

```text
Verification Complete : 0 Viols.
```

From `reports/route_connectivity_special.rpt`:

```text
*** Checking Net VDD
Net VDD: dangling Wire.
*** Checking Net VSS
Net VSS: dangling Wire.
8 Problem(s) (IMPVFC-94): The net has dangling wire(s).
Verification Complete : 8 Viols.  0 Wrngs.
```

## Route Recovery Result

Route recovery was enabled for standard `ecoRoute` cleanup only. Route-gate
special-net sroute recovery was intentionally disabled by the conservative PG
strategy.

From `reports/route_recovery_status.rpt`:

```text
ROUTE_GATE_RECOVERY_INITIAL_DRC=0
ROUTE_GATE_RECOVERY_INITIAL_SHORTS=0
ROUTE_GATE_RECOVERY_REPAIR_COMMANDS={ecoRoute -target} {ecoRoute -fix_drc}
ROUTE_GATE_SROUTE_RECOVERY=DISABLED_BY_ENV
ROUTE_GATE_RECOVERY_COMMAND=ecoRoute -target
ROUTE_GATE_RECOVERY_ATTEMPT_DRC=0
ROUTE_GATE_RECOVERY_ATTEMPT_SHORTS=0
ROUTE_GATE_RECOVERY_ATTEMPT_STATUS=REVIEW_REQUIRED
ROUTE_GATE_RECOVERY_COMMAND=ecoRoute -fix_drc
ROUTE_GATE_RECOVERY_ATTEMPT_DRC=0
ROUTE_GATE_RECOVERY_ATTEMPT_SHORTS=0
ROUTE_GATE_RECOVERY_ATTEMPT_STATUS=REVIEW_REQUIRED
ROUTE_GATE_RECOVERY_STATUS=REVIEW_REQUIRED
```

Interpretation:

- Recovery had no geometry DRC to fix.
- `ecoRoute -target` and `ecoRoute -fix_drc` preserved DRC zero.
- They did not remove the remaining eight special-net dangling markers.

## Filler Result

Final filler was enabled and inserted.

From `reports/filler_status.rpt`:

```text
FILLER_CELL_FAMILY=FEED*JIHD
FILLER_CANDIDATES=FEED25JIHD FEED15JIHD FEED10JIHD FEED7JIHD FEED5JIHD FEED3JIHD FEED2JIHD FEED1JIHD
FILLER_COUNT_BEFORE=0
FILLER_COUNT=22103
FILLER_DELTA=22103
FILLER_INSERTION_STATUS=PASS
POST_FILLER_ROUTE_PRE_SROUTE_COMMAND=ecoRoute -target
POST_FILLER_ROUTE_POST_SROUTE_COMMANDS={ecoRoute -fix_drc}
POST_FILLER_VERIFY_DRC=0
POST_FILLER_VERIFY_SHORTS=0
POST_FILLER_SPECIAL_CONNECTIVITY_BAD=1
POST_FILLER_SPECIAL_CONNECTIVITY_BAD_LINES={Net VDD: dangling Wire.} {Net VSS: dangling Wire.} {8 Problem(s) (IMPVFC-94): The net has dangling wire(s).} {Verification Complete : 8 Viols.  0 Wrngs.}
POST_FILLER_VERIFY_STATUS=REVIEW_REQUIRED
POST_FILLER_ROUTE_STATUS=REVIEW_REQUIRED
POST_FILLER_CLEANUP_STATUS=REVIEW_REQUIRED
```

Interpretation:

- Filler insertion itself passed.
- Post-filler route cleanup preserved DRC zero.
- The same eight VDD/VSS dangling special-wire markers remained.

## Timing Result At Route Stage

Post-route optimization ran all ten requested setup passes. The final setup miss
was small and stable from pass 4 onward.

From `reports/postroute_opt_status.rpt`:

```text
POSTROUTE_OPT_SETUP_REQUESTED_PASSES=10
POSTROUTE_OPT_SETUP_MAX_PASSES=10
POSTROUTE_OPT_SETUP_TARGET_SLACK_NS=0.020
POSTROUTE_OPT_SETUP_EARLY_STOP=0
POSTROUTE_OPT_SETUP_PLATEAU_GUARD=0
POSTROUTE_OPT_HOLD_REQUESTED_PASSES=2
POSTROUTE_OPT_HOLD_MAX_PASSES=2
POSTROUTE_OPT_HOLD_TARGET_SLACK_NS=0.010
```

Setup progression:

```text
pass 1: WNS=-0.032 ns TNS=-0.190 ns
pass 2: WNS=-0.024 ns TNS=-0.098 ns
pass 3: WNS=-0.020 ns TNS=-0.091 ns
pass 4: WNS=-0.014 ns TNS=-0.074 ns
pass 5: WNS=-0.014 ns TNS=-0.074 ns
pass 6: WNS=-0.014 ns TNS=-0.074 ns
pass 7: WNS=-0.014 ns TNS=-0.074 ns
pass 8: WNS=-0.014 ns TNS=-0.074 ns
pass 9: WNS=-0.014 ns TNS=-0.074 ns
pass 10: WNS=-0.014 ns TNS=-0.074 ns
```

Final timing status:

```text
POSTROUTE_OPT_SETUP_FINAL_WNS_NS=-0.014
POSTROUTE_OPT_SETUP_FINAL_TNS_NS=-0.074
POSTROUTE_OPT_SETUP_CLOSURE_STATUS=FAIL
POSTROUTE_OPT_FAST_TAG_FINAL_TIMING_STATUS=PASS
POSTROUTE_OPT_hold_PASS_1_STATUS=PASS
POSTROUTE_OPT_hold_PASS_2_STATUS=PASS
POSTROUTE_OPT_hold_STATUS=PASS
POSTROUTE_OPT_drv_STATUS=PASS
```

Interpretation:

- Setup is not closed, but the remaining miss is only 14 ps WNS and 74 ps TNS.
- Hold passed for both requested passes.
- DRV passed.
- The timing evidence is post-route, but the flow did not continue into the
  later `extraction_sta` wrapper stage because the route gate failed first.

## PG Connectivity Evolution

Pre-route/post-place sroute:

```text
POSTPLACE_PRE_ROUTE_SROUTE_ENABLED=1
POSTPLACE_PRE_ROUTE_SROUTE_EFFECTIVE_WIRES=851
POSTPLACE_PRE_ROUTE_SROUTE_EFFECTIVE_OPEN_PORTS=16
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_BAD=1
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_DANGLING_COUNT=25
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_DANGLING_ONLY_STATUS=DANGLING_ONLY
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_DANGLING_MAX=64
POSTPLACE_PRE_ROUTE_SROUTE_DANGLING_ONLY_OVERRIDE=1
POSTPLACE_PRE_ROUTE_SROUTE_PROGRESS_STATUS=PASS
POSTPLACE_PRE_ROUTE_SROUTE_STATUS=PASS
```

Post-route/final route gate:

```text
PG_CONNECTIVITY_STATUS=FAIL
PG_CONNECTIVITY_STAGE=POST_ROUTE_SPECIAL_NET_VERIFY
SPECIAL_CONNECTIVITY_BAD=1
SPECIAL_CONNECTIVITY_BAD_LINES={Net VDD: dangling Wire.} {Net VSS: dangling Wire.} {8 Problem(s) (IMPVFC-94): The net has dangling wire(s).} {Verification Complete : 8 Viols.  0 Wrngs.}
REGULAR_CONNECTIVITY_BAD=0
```

Interpretation:

- Pre-route special dangling count was 25 and accepted under the explicit
  dangling-only progress override.
- After routing and filler cleanup, this reduced to 8.
- The remaining eight markers are the only route gate blocker.

## Remaining Special-Net Markers

From route DRC marker class output:

```text
1  {221.745 681.16 221.745 681.16} MET3  Connectivity ConnectivityAntenna Net VDD
2  {48.0 681.16 48.0 681.16}       MET3  Connectivity ConnectivityAntenna Net VDD
3  {221.745 121.16 221.745 121.16} MET3  Connectivity ConnectivityAntenna Net VDD
4  {48.0 121.16 48.0 121.16}       MET3  Connectivity ConnectivityAntenna Net VDD
5  {201.16 118.0 201.16 118.0}     METTP Connectivity ConnectivityAntenna Net VDD
6  {121.16 118.0 121.16 118.0}     METTP Connectivity ConnectivityAntenna Net VDD
7  {221.745 125.16 221.745 125.16} MET3  Connectivity ConnectivityAntenna Net VSS
8  {48.0 125.16 48.0 125.16}       MET3  Connectivity ConnectivityAntenna Net VSS
```

These are connectivity markers, not geometry DRC markers. The saved checkpoint
reported zero geometry markers and zero antenna markers at save time.

## Reports To Preserve

Primary checkpoint evidence:

```text
manifests/run_manifest.txt
manifests/stage_trace.csv
reports/route_status.rpt
reports/route_drc.rpt
reports/route_connectivity_regular.rpt
reports/route_connectivity_special.rpt
reports/pg_postroute_connectivity_status.rpt
reports/route_recovery_status.rpt
reports/filler_status.rpt
reports/postroute_opt_status.rpt
reports/fast_tag_to_pd_timing_postroute_opt_final.rpt
reports/fast_tag_to_pd_timing_diagnosis.rpt
reports/route_drc_markers.tsv
reports/route_gate_failure_drc_markers.tsv
def/04_route_failed.def
checkpoints/04_route_failed.enc.dat
```

## Post-Run Inspection Replay

After the SSH session closed, the first inspection attempt failed because the
shell had lost `FINAL_RUN_ID`. The correct replay environment was:

```sh
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
source .venv/bin/activate 2>/dev/null || true

export EXPECTED_HEAD=fd295f995feb9e59e4b6dd37682db096d555d7ed
test "$(git rev-parse HEAD)" = "$EXPECTED_HEAD"

export FINAL_RUN_ID=20260701_mptdc_ro6_pnrlef_freeall_aggr_final_211109
export FINAL_DIR=/sim/ksabra/SPADMIC_work/innovus/$FINAL_RUN_ID
test -d "$FINAL_DIR"
```

Inspection command:

```sh
MPTDC/pnr/scripts/server_inspect_mptdc_tc_fullclosure.sh "$FINAL_DIR"
```

Focused route/timing checks:

```sh
grep -nE 'ROUTE_STATUS=|INNOVUS_VERIFY_DRC_STATUS=|GEOMETRY_DRC_VIOLATIONS=|SHORTS=|REGULAR_NET_CONNECTIVITY_BAD=|SPECIAL_NET_CONNECTIVITY_BAD=|SPECIAL_NET_BAD_LINES=|UNROUTED_NETS=|ROUTE_DRC_CLASS_COUNTS=|ROUTE_GATE_FAILURE_CHECKPOINT_DAT=' \
  "$FINAL_DIR/reports/route_status.rpt"

grep -nE 'Verification Complete|Violation Summary|Short|MetSpc|Mar|Totals|process antenna' \
  "$FINAL_DIR/reports/route_drc.rpt" | tail -80

grep -nE 'Net VDD|Net VSS|Problem\(s\)|Verification Complete|dangling|unconnected|opens|short' \
  "$FINAL_DIR/reports/route_connectivity_special.rpt" | head -160

grep -nE 'POSTROUTE_OPT_SETUP_FINAL_WNS_NS|POSTROUTE_OPT_SETUP_FINAL_TNS_NS|POSTROUTE_OPT_SETUP_CLOSURE_STATUS|POSTROUTE_OPT_HOLD|POSTROUTE_OPT_drv_STATUS' \
  "$FINAL_DIR/reports/postroute_opt_status.rpt" 2>/dev/null || true
```

## Why The Session Closed

Innovus exited with code 1 because the wrapper route stage raised:

```text
MPTDC_DIGITAL_SIGNOFF_STAGE_FAILED: stage=route error=MPTDC_ROUTE_GATE_FAILED
```

The SSH session then closed after the foreground Innovus process terminated. The
run artifacts were preserved. The later failed inspection attempt was only due
to the shell losing `FINAL_RUN_ID`, causing:

```text
FINAL_DIR=/sim/ksabra/SPADMIC_work/innovus/
```

instead of:

```text
FINAL_DIR=/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_ro6_pnrlef_freeall_aggr_final_211109
```

## Pre-Repair Decision

The preferred immediate action is not another full clean run. The current
checkpoint is already the best route-state artifact:

```text
DRC=0
SHORTS=0
REGULAR_CONNECTIVITY=clean
FILLER=inserted
HOLD=pass
DRV=pass
SETUP_WNS=-14 ps
SPECIAL_PG_DANGLING=8 markers
```

The most targeted next probe is to restore `04_route_failed.enc.dat`, remove the
eight reported dangling special-wire endpoints by bounded area, run
`ecoRoute -target` and `ecoRoute -fix_drc`, then recheck:

```text
verify_drc
verifyConnectivity -type regular
verifyConnectivity -type special -nets {VDD VSS}
mptdc_ckpt_assert_geometry_regular_clean
```

If the repair produces:

```text
FINAL_DRC=0
FINAL_SHORTS=0
FINAL_REGULAR_CONNECTIVITY_BAD=0
FINAL_SPECIAL_CONNECTIVITY_BAD=0
FINAL_ROUTE_GATE_PASS=1
```

then the repaired checkpoint should become the next handoff base:

```text
<repair_run>/checkpoints/repaired_route.enc.dat
```

If it remains:

```text
FINAL_DRC=0
FINAL_SHORTS=0
FINAL_SPECIAL_CONNECTIVITY_BAD=1
```

then this checkpoint is still a strong dirty timing/handoff candidate, but not a
route-clean signoff candidate. The fastest wrapper-level fallback is to rerun
the same `final_candidate` policy with:

```text
MPTDC_ALLOW_DIRTY_ROUTE_TIMING_CONTINUE=1
```

That would preserve `ROUTE_STATUS=FAIL` while allowing extraction/STA and later
report package stages to run. It must not be labeled as clean route signoff.

## Checkpoint Repair Probe

The following probe was issued after the checkpoint review. Its purpose was to
test whether the eight remaining VDD/VSS dangling special-wire endpoints could
be surgically removed without disturbing the clean route geometry.

Repair source:

```sh
export FINAL_RUN_ID=20260701_mptdc_ro6_pnrlef_freeall_aggr_final_211109
export FINAL_DIR=/sim/ksabra/SPADMIC_work/innovus/$FINAL_RUN_ID
export BEST_CKPT="$FINAL_DIR/checkpoints/04_route_failed.enc.dat"
```

Repair run setup:

```sh
export EXPECTED_HEAD=fd295f995feb9e59e4b6dd37682db096d555d7ed
export FIX_RUN_ID=20260701_mptdc_route0_pg8_dangling_prune_$(date +%H%M%S)
export FIX_CMDS=/tmp/${FIX_RUN_ID}.commands.tcl
export MPTDC_CHECKPOINT_REPAIR_KEEP_GOING=1
```

Repair Tcl command file:

```tcl
catch {editDelete -net VDD -layer MET3  -area {220.245 679.660 223.245 682.660} -type Special}
catch {editDelete -net VDD -layer MET3  -area {46.500 679.660 49.500 682.660} -type Special}
catch {editDelete -net VDD -layer MET3  -area {220.245 119.660 223.245 122.660} -type Special}
catch {editDelete -net VDD -layer MET3  -area {46.500 119.660 49.500 122.660} -type Special}
catch {editDelete -net VDD -layer METTP -area {199.660 116.500 202.660 119.500} -type Special}
catch {editDelete -net VDD -layer METTP -area {119.660 116.500 122.660 119.500} -type Special}
catch {editDelete -net VSS -layer MET3  -area {220.245 123.660 223.245 126.660} -type Special}
catch {editDelete -net VSS -layer MET3  -area {46.500 123.660 49.500 126.660} -type Special}

ecoRoute -target
ecoRoute -fix_drc

verify_drc
verifyConnectivity -type regular
verifyConnectivity -type special -nets {VDD VSS}

mptdc_ckpt_assert_geometry_regular_clean
```

Repair wrapper command:

```sh
set +e
MPTDC/pnr/scripts/server_repair_mptdc_route_checkpoint.sh \
  --run-id "$FIX_RUN_ID" \
  --checkpoint "$BEST_CKPT" \
  --commands-file "$FIX_CMDS" \
  --expected-head "$EXPECTED_HEAD"
FIX_RC=$?
set -e

export FIX_DIR=/sim/ksabra/SPADMIC_work/innovus/$FIX_RUN_ID
echo "FIX_RC=$FIX_RC"
echo "FIX_DIR=$FIX_DIR"

grep -nE 'FINAL_DRC=|FINAL_SHORTS=|FINAL_REGULAR_CONNECTIVITY_BAD=|FINAL_SPECIAL_CONNECTIVITY_BAD=|FINAL_ROUTE_GATE_PASS|CHECKPOINT_REPAIR_STATUS|FINAL_CHECKPOINT_DAT=' \
  "$FIX_DIR/reports/checkpoint_repair_status.rpt"
```

Repair success criteria:

```text
FINAL_DRC=0
FINAL_SHORTS=0
FINAL_REGULAR_CONNECTIVITY_BAD=0
FINAL_SPECIAL_CONNECTIVITY_BAD=0
FINAL_ROUTE_GATE_PASS=1
```

### Repair Result

Repair run:

```text
run_id=20260701_mptdc_route0_pg8_dangling_prune_215928
result_dir=/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_route0_pg8_dangling_prune_215928
date=2026-07-01T21:59:56+02:00
source_checkpoint=/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_ro6_pnrlef_freeall_aggr_final_211109/checkpoints/04_route_failed.enc.dat
commands_file=/tmp/20260701_mptdc_route0_pg8_dangling_prune_215928.commands.tcl
innovus_rc=0
```

Key restore/save evidence:

```text
Loading design 'mptdc_axis_core' saved by Innovus 22.33-s094_1 on Wed Jul 1 21:47:25 2026
Loading Drc markers ... 8 markers are loaded ... 0 geometry drc markers ... 0 antenna drc markers
MPTDC_CKPT_ASSERT_GEOMETRY_REGULAR_DRC=0
MPTDC_CKPT_ASSERT_GEOMETRY_REGULAR_SHORTS=0
MPTDC_CKPT_ASSERT_GEOMETRY_REGULAR_BAD=0
MPTDC_CKPT_ASSERT_GEOMETRY_REGULAR_SPECIAL_BAD=1
Generated self-contained design repaired_route.enc.dat
Saving Drc markers ... 8 markers are saved ... 0 geometry drc markers ... 0 antenna drc markers
```

Final checkpoint repair status:

```text
FINAL_DRC=0
FINAL_SHORTS=0
FINAL_REGULAR_CONNECTIVITY_BAD=0
FINAL_SPECIAL_CONNECTIVITY_BAD=1
FINAL_ROUTE_GATE_PASS=0
CHECKPOINT_REPAIR_STATUS=PASS_GEOMETRY_REVIEW_CONNECTIVITY
```

Repair output checkpoint:

```text
/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_route0_pg8_dangling_prune_215928/checkpoints/repaired_route.enc.dat
```

Interpretation:

- The bounded special-wire delete/reroute probe did not clear the eight VDD/VSS
  dangling markers.
- The probe did preserve `DRC=0`, `SHORTS=0`, and regular connectivity clean.
- The saved repair checkpoint is not a route-gate-clean handoff checkpoint
  because `FINAL_SPECIAL_CONNECTIVITY_BAD=1`.
- The repair result strengthens the case that the remaining issue is not random
  router geometry noise; it is a persistent special-PG topology artifact from
  the current conservative block-pin/RO-hookup strategy.

### Post-Repair Decision

Do not spend time on additional blind local `editDelete` or `ecoRoute` attempts
against the same eight markers unless a manual layout review identifies the
exact intended PG topology change. The fast path is now:

1. Preserve the original final-candidate checkpoint and the repair checkpoint as
   evidence.
2. Treat the eight special dangling markers as a documented PG-special waiver or
   manual-fix-later item.
3. Continue to extraction/STA/report packaging using dirty-route continuation
   so the timing/filler/power/report state can be captured from this otherwise
   geometry-clean route.

The waiver wording should be narrow:

```text
WAIVE_FOR_TC_HANDOFF_ONLY:
8 VDD/VSS special-net dangling-wire markers, IMPVFC-94 only.
No Innovus geometry DRC.
No shorts.
No regular-net connectivity failures.
Filler inserted and post-filler verify_drc remains zero.
Manual PG-special cleanup required before any route-clean/final signoff claim.
```

This waiver must not be used to claim:

```text
ROUTE_STATUS=PASS
PG_CONNECTIVITY_STATUS=PASS
READY_FOR_TAPEOUT=YES
MPTDC_TC_PHYSICAL_SIGNOFF=YES
```

It may be used to justify continuing a TC-only dirty route timing package:

```text
MPTDC_ALLOW_DIRTY_ROUTE_TIMING_CONTINUE=1
```

## Restored Checkpoint Extraction And STA

After preserving the original `211109` route-failure checkpoint and the first
bounded PG dangling-wire prune probe, the checkpoint was restored again only to
extract timing and write the post-route report package. This was not a new full
PnR run. It was a checkpoint analysis run from the same geometry-clean route
database.

Restored analysis run:

```text
run_id=20260701_mptdc_211109_ckpt_extract_sta_224348
result_dir=/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_211109_ckpt_extract_sta_224348
source_checkpoint=/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_ro6_pnrlef_freeall_aggr_final_211109/checkpoints/04_route_failed.enc.dat
repo=/home/validmgr/ksabra/2026_SPAD/SPADMIC
branch=SPADMIC_test
baseline_head=fd295f995feb9e59e4b6dd37682db096d555d7ed
innovus_rc=0
```

The restore wrapper used the checkpoint-repair harness in keep-going mode, with
the original route-failed checkpoint as `--checkpoint`. The important environment
and command contract was:

```sh
export EXPECTED_HEAD=fd295f995feb9e59e4b6dd37682db096d555d7ed
export FINAL_RUN_ID=20260701_mptdc_ro6_pnrlef_freeall_aggr_final_211109
export FINAL_DIR=/sim/ksabra/SPADMIC_work/innovus/$FINAL_RUN_ID
export BEST_CKPT="$FINAL_DIR/checkpoints/04_route_failed.enc.dat"
export STA_RUN_ID=20260701_mptdc_211109_ckpt_extract_sta_224348
export STA_CMDS=/tmp/${STA_RUN_ID}.commands.tcl
export MPTDC_CHECKPOINT_REPAIR_KEEP_GOING=1

MPTDC/pnr/scripts/server_repair_mptdc_route_checkpoint.sh \
  --run-id "$STA_RUN_ID" \
  --checkpoint "$BEST_CKPT" \
  --commands-file "$STA_CMDS" \
  --expected-head "$EXPECTED_HEAD"
```

The commands file restored the checkpoint, ran the MPTDC signoff extraction and
TC timing helpers, wrote the phase/backend diagnostic reports, then saved a
self-contained `repaired_route.enc.dat` copy for traceability. The key point is
that extraction/STA was run on the preserved 211109 route database, not on the
later rejected dirty-route rerun.

Checkpoint integrity after restore:

```text
FINAL_DRC=0
FINAL_SHORTS=0
FINAL_REGULAR_CONNECTIVITY_BAD=0
FINAL_SPECIAL_CONNECTIVITY_BAD=1
CHECKPOINT_REPAIR_STATUS=PASS_GEOMETRY_REVIEW_CONNECTIVITY
```

Extracted TC timing:

```text
SETUP_STATUS_TC=FAIL
TC_HOLD_STATUS=PASS

setup WNS=-0.014 ns
setup TNS=-0.074 ns
setup violating paths=11

hold WNS=+0.026 ns
hold TNS=0.000 ns
hold violating paths=0
```

Digital status package from this restored analysis:

```text
MPTDC_TC_PNR_CLOSURE=DEFERRED evidence=implementation_gate_not_complete
PG_CONNECTIVITY_STATUS=FAIL evidence=special_pg_dangling_only_restored_211109
ROUTE_STATUS=FAIL evidence=geometry_clean_regular_clean_special_pg_dangling_only
FILLER_STATUS=PASS evidence=restored_211109_filler_inserted_postfiller_drc0
EXTRACTION_STATUS=PASS evidence=extraction_rc.rpt
POWER_STATUS=PROVISIONAL evidence=power_status.rpt
SETUP_STATUS_TC=FAIL evidence=timing_tc_nominal.rpt
TC_HOLD_STATUS=PASS evidence=timing_tc_hold.rpt
DRV_STATUS=PASS evidence=drv_status.rpt
READY_FOR_TAPEOUT=NO evidence=row_and_mmmc_deferred
DIGITAL_PNR_SIGNOFF=PROVISIONAL evidence=row_and_block_drc_lvs_deferred_implementation_gate_not_complete
```

Engineering interpretation:

- The restored checkpoint is clean for Innovus geometry DRC, shorts, and regular
  net connectivity.
- The route gate still cannot be called clean because VDD/VSS special-net
  dangling wires remain.
- TC extraction and STA are usable as an engineering timing package, but they do
  not override the route/PG gate.
- Hold and DRV are not the current blockers.
- The residual setup miss is small, systematic, and on the `nfast_hit_latched`
  capture paths.

## Top 11 Setup Path Classification

The extracted `timing_tc_nominal_top100.rpt` was reduced into
`setup_top11_classification.tsv` and `setup_top11_full_blocks.rpt`. The top 11
violating setup paths are:

```text
1   clk_osc_fast_buf_tap1  u_core_gen_fast_tag_col[1].u_fast_tag_tag_o_reg[0]/Q   -> u_core_gen_pd_row[7].gen_pd_col[1].u_pd/nfast_hit_latched_reg[0]/D
2   clk_osc_fast_buf_tap0  u_core_gen_fast_tag_col[0].u_fast_tag_tag_o_reg[4]/Q   -> u_core_gen_pd_row[7].gen_pd_col[0].u_pd/nfast_hit_latched_reg[4]/D
3   clk_osc_fast_buf_tap0  u_core_gen_fast_tag_col[0].u_fast_tag_tag_o_reg[4]/Q   -> u_core_gen_pd_row[6].gen_pd_col[0].u_pd/nfast_hit_latched_reg[4]/D
4   clk_osc_fast_buf_tap4  u_core_gen_pd_row[3].gen_pd_col[4].u_pd/hit_latched_reg/Q -> u_core_gen_pd_row[3].gen_pd_col[4].u_pd/nfast_hit_latched_reg[3]/D
5   clk_osc_fast_buf_tap4  u_core_gen_pd_row[3].gen_pd_col[4].u_pd/hit_latched_reg/Q -> u_core_gen_pd_row[3].gen_pd_col[4].u_pd/nfast_hit_latched_reg[5]/D
6   clk_osc_fast_buf_tap2  u_core_gen_pd_row[7].gen_pd_col[2].u_pd/hit_latched_reg/Q -> u_core_gen_pd_row[7].gen_pd_col[2].u_pd/nfast_hit_latched_reg[0]/D
7   clk_osc_fast_buf_tap1  u_core_gen_fast_tag_col[1].u_fast_tag_tag_o_reg[0]/Q   -> u_core_gen_pd_row[6].gen_pd_col[1].u_pd/nfast_hit_latched_reg[0]/D
8   clk_osc_fast_buf_tap2  u_core_gen_pd_row[1].gen_pd_col[2].u_pd/hit_latched_reg/Q -> u_core_gen_pd_row[1].gen_pd_col[2].u_pd/nfast_hit_latched_reg[6]/D
9   clk_osc_fast_buf_tap5  u_core_gen_fast_tag_col[5].u_fast_tag_tag_o_reg[0]/Q   -> u_core_gen_pd_row[7].gen_pd_col[5].u_pd/nfast_hit_latched_reg[0]/D
10  clk_osc_fast_buf_tap5  u_core_gen_fast_tag_col[5].u_fast_tag_tag_o_reg[0]/Q   -> u_core_gen_pd_row[6].gen_pd_col[5].u_pd/nfast_hit_latched_reg[0]/D
11  clk_osc_fast_buf_tap1  u_core_gen_fast_tag_col[1].u_fast_tag_tag_o_reg[0]/Q   -> u_core_gen_pd_row[1].gen_pd_col[1].u_pd/nfast_hit_latched_reg[0]/D
```

Path group distribution:

```text
clk_osc_fast_buf_tap0: 2 paths
clk_osc_fast_buf_tap1: 3 paths
clk_osc_fast_buf_tap2: 2 paths
clk_osc_fast_buf_tap4: 2 paths
clk_osc_fast_buf_tap5: 2 paths
```

Source classification:

```text
fast_tag_tag_o_reg launch paths: 7 / 11
local hit_latched_reg launch paths: 4 / 11
nfast_hit_latched_reg capture endpoints: 11 / 11
```

Engineering comment:

- This is not one isolated endpoint, one single bad row, or one router accident.
- The miss is spread across multiple fast oscillator tap groups.
- All failing endpoints are `nfast_hit_latched_reg[*]/D`.
- The failures are centered on the fast-tag to PD/nfast-hit capture interface.
- The remaining margin is only 14 ps WNS and 74 ps TNS, so a very small ECO can
  close it if the change does not disturb hold, DRC, or PG/route geometry.

## Rejected Dirty-Route Debug Run

A later debug run must not be treated as the best checkpoint:

```text
run_id=20260701_mptdc_ro6_pnrlef_freeall_aggr_dirtyroute_220957
result_dir=/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_ro6_pnrlef_freeall_aggr_dirtyroute_220957
head=0f9e5a577b24a88c36a7cb6e1478012541a9d7dd
```

This run intentionally differed from the preserved final candidate:

```text
free_all_internal_placement=0
free_internal_placement=0
skip_phase_buffer_preplace=0
fix_ro_macros=1
pd_physical_audit_mode=soft_region
final_filler=0
postroute_setup_passes=4
postroute_setup_max_passes=4
postroute_opt_status=SKIPPED
```

It routed faster, but it created a real geometry short:

```text
GEOMETRY_DRC_VIOLATIONS=1
SHORTS=1
REGULAR_NET_CONNECTIVITY_BAD=0
SPECIAL_NET_CONNECTIVITY_BAD=1
ROUTE_DRC_REVIEW_CLASS_REASON=disallowed_classes:Short=1
```

Marker evidence:

```text
MET2 Geometry Metal_Short
Regular Wire of Net u_core_gen_pd_row[5].gen_pd_col[4].u_pd/n_29
Special Wire of Net VDD
bbox={220.5000 130.0100 220.7600 130.7350}
```

Engineering comment:

- The dirty-route run is useful as negative evidence only.
- It proves that allowing a different placement/routing recipe can turn the
  problem from "special-PG dangling only" into a real signal-to-VDD short.
- It must not replace the `211109` checkpoint for ECO work.
- All next timing ECO probes must restore from the original `211109`
  checkpoint, not from the dirty-route checkpoint.

## One-By-One ECO Policy

The checkpoint now has three separate unresolved issues:

```text
1. PG special-net dangling markers: 8 VDD/VSS IMPVFC-94 markers.
2. TC setup margin: WNS=-0.014 ns, TNS=-0.074 ns, 11 paths.
3. Final physical signoff: DRC/LVS/foundry verification deferred.
```

The next engineering step is a strictly bounded timing ECO sequence. The
purpose is to learn whether a very small Innovus-only data-path resize can close
the 14 ps setup miss without damaging the clean route geometry.

Mandatory ECO baseline:

```text
baseline_checkpoint=/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_ro6_pnrlef_freeall_aggr_final_211109/checkpoints/04_route_failed.enc.dat
baseline_geometry_drc=0
baseline_shorts=0
baseline_regular_connectivity_bad=0
baseline_special_connectivity_bad=1
baseline_setup_wns=-0.014 ns
baseline_setup_tns=-0.074 ns
baseline_hold_wns=+0.026 ns
baseline_hold_tns=0.000 ns
```

Do not ECO from:

```text
/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_ro6_pnrlef_freeall_aggr_dirtyroute_220957
```

ECO acceptance gates after each single candidate:

```text
FINAL_DRC=0
FINAL_SHORTS=0
FINAL_REGULAR_CONNECTIVITY_BAD=0
SETUP_STATUS_TC improves or closes
TC_HOLD_STATUS=PASS
DRV_STATUS=PASS
```

The known special-PG dangling state may remain during this timing probe:

```text
FINAL_SPECIAL_CONNECTIVITY_BAD=1
```

but it must be described as:

```text
special_pg_dangling_only_still_pending_manual_pg_cleanup
```

Immediate rejection criteria:

```text
FINAL_DRC>0
FINAL_SHORTS>0
FINAL_REGULAR_CONNECTIVITY_BAD=1
TC_HOLD_STATUS=FAIL
DRV_STATUS=FAIL
setup WNS/TNS degrades materially
```

The first ECO should be diagnostic and minimal:

```text
MPTDC_PNR_FAST_TAG_TARGETED_ECO=1
MPTDC_PNR_FAST_TAG_ECO_MAX_UPSIZE_CELLS=1
MPTDC_PNR_FAST_TAG_ECO_PATH_DRIVEN=1
MPTDC_PNR_FAST_TAG_ECO_PATH_MAX_PATHS=11
MPTDC_PNR_FAST_TAG_ECO_PATH_MAX_CELLS=64
MPTDC_PNR_FAST_TAG_ECO_NAME_FALLBACK=0
MPTDC_PNR_FAST_TAG_ECO_PROTECT_ENDPOINT_FLOPS=1
MPTDC_PNR_FAST_TAG_ECO_ALLOW_ENDPOINT_FLOP_RESIZE=0
MPTDC_PNR_FAST_TAG_ECO_UPSIZE_SMALL_GATES=1
MPTDC_PNR_FAST_TAG_ECO_ALLOW_ON22_X2=1
```

Rationale:

- `MAX_UPSIZE_CELLS=1` makes the first run a one-cell experiment.
- `PATH_MAX_PATHS=11` focuses the search on the complete known failing set.
- `NAME_FALLBACK=0` prevents broad name-pattern ECO from touching cells outside
  the path-driven set.
- `PROTECT_ENDPOINT_FLOPS=1` avoids changing the capture flops on the first
  probe; this reduces hold and sequential-cell risk.
- If the first one-cell run is clean but insufficient, the next candidates can
  increase `MAX_UPSIZE_CELLS` to 2 and then 4, still restoring from the original
  checkpoint each time.

Do not mix timing ECO with PG-special cleanup in the same run. PG cleanup remains
a separate task because the current route geometry is clean and the dirty-route
experiment showed that recipe changes can introduce real shorts.

## First One-Cell Fast-Tag ECO Probe

The first one-cell timing ECO probe was run from the preserved `211109`
checkpoint after this document was pushed. The run used the documented
single-cell policy:

```text
run_id=20260701_mptdc_211109_eco_fasttag_1cell_230007
result_dir=/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_211109_eco_fasttag_1cell_230007
source_checkpoint=/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_ro6_pnrlef_freeall_aggr_final_211109/checkpoints/04_route_failed.enc.dat
head=5a4df2c0e7a79340ecea78107a5abc27c6b7f731
```

Important shell note:

```text
ECO_RC=130
```

This exit code was not an Innovus ECO failure. The checkpoint repair script
finished its report and save steps, then Innovus stayed at its interactive prompt.
The next shell commands were typed into Innovus until the session was interrupted
with Ctrl-C. The reports from this run are valid because the following evidence
was written before interruption:

```text
MPTDC_ECO_FOCUS_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_211109_eco_fasttag_1cell_230007/reports/fast_tag_timing_focus.rpt
MPTDC_ECO_APPLY_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_211109_eco_fasttag_1cell_230007/reports/fast_tag_targeted_eco.rpt
MPTDC_ECO_STATUS_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_211109_eco_fasttag_1cell_230007/reports/digital_pnr_signoff_status.rpt
MPTDC_CHECKPOINT_REPAIR_STATUS_REPORT=/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_211109_eco_fasttag_1cell_230007/reports/checkpoint_repair_status.rpt
Generated self-contained design repaired_route.enc.dat
```

The wrapper has since been patched to call `exit 0` after writing
`checkpoint_repair_status.rpt`, so future checkpoint-repair probes should return
to the shell normally.

One-cell ECO action:

```text
FAST_TAG_ECO_PATH_ALLOWED_CELL_COUNT=7
FAST_TAG_ECO_UPSIZE_ATTEMPT=FE_PSBC1565_u_core_fast_tag_col_0__4 target=INJIHDX4 status=PASS command=ecoChangeCell -inst FE_PSBC1565_u_core_fast_tag_col_0__4 -cell INJIHDX4
FAST_TAG_ECO_UPSIZE_SUCCESSES=1
FAST_TAG_TARGETED_ECO_STATUS=PASS
```

Physical result after the ECO:

```text
FINAL_DRC=0
FINAL_SHORTS=0
FINAL_REGULAR_CONNECTIVITY_BAD=0
FINAL_SPECIAL_CONNECTIVITY_BAD=1
CHECKPOINT_REPAIR_STATUS=PASS_GEOMETRY_REVIEW_CONNECTIVITY
PG_CONNECTIVITY_STATUS=FAIL evidence=special_pg_dangling_only_after_single_cell_eco
ROUTE_STATUS=FAIL evidence=geometry_clean_regular_clean_special_pg_dangling_only_after_single_cell_eco
EXTRACTION_STATUS=PASS evidence=extraction_rc.rpt
TC_HOLD_STATUS=PASS evidence=timing_tc_hold.rpt
DRV_STATUS=PASS evidence=drv_status.rpt
```

Timing result after the ECO:

```text
baseline setup WNS=-0.014 ns, TNS=-0.074 ns, violating paths=11
one-cell setup WNS=-0.018 ns, TNS=-0.089 ns, violating paths=12
hold WNS=+0.026 ns, TNS=0.000 ns, violating paths=0
```

Engineering decision:

```text
ECO_RESULT=REJECT_FOR_TIMING
REJECTED_CELL=FE_PSBC1565_u_core_fast_tag_col_0__4
REJECTED_RESIZE=INJIHDX3_TO_INJIHDX4
REASON=setup_degraded_and_violating_path_count_increased
```

This run is physically clean enough to keep as evidence, but it must not be used
as the next ECO baseline. The next timing probe must restore the original
`211109` checkpoint again and try a different single candidate. Do not simply
rerun the automated ECO with `MAX_UPSIZE_CELLS=2`, because that would reapply the
rejected first resize and contaminate the result.

Next one-by-one ECO rule:

```text
restore original 211109 checkpoint
read candidate list from the 1-cell report
exclude FE_PSBC1565_u_core_fast_tag_col_0__4
apply exactly one remaining candidate
reroute only as needed
rerun geometry, regular connectivity, extraction, setup, hold, and DRV checks
```
