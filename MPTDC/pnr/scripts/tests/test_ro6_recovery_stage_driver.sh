#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRIVER="$(cd "$SCRIPT_DIR/.." && pwd)/server_run_mptdc_ro6_recovery_stage.sh"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

REPO="$TMP_ROOT/repo"
WORK="$TMP_ROOT/work"
HANDOFF="$WORK/handoff/genus_typical_pnrcompat/genus_fixture"
PUBLISH_CALLS="$TMP_ROOT/publish.calls"
PNR_LEF="$TMP_ROOT/RO_tune6_marker_access.lef"
PNR_LEF_SUMMARY="$TMP_ROOT/RO_tune6_marker_access.summary.txt"
mkdir -p "$REPO" "$HANDOFF" "$WORK/innovus"
git init -q -b SPADMIC_test "$REPO"
git -C "$REPO" config user.name 'MPTDC recovery test'
git -C "$REPO" config user.email 'mptdc-recovery@example.invalid'

PRE_GATE="$REPO/MPTDC/docs/server_snapshots/genus/genus_fixture_prepnr_20260824_120000/reports/operator_gate_pre_pnr.rpt"
PG_GATE="$REPO/MPTDC/docs/server_snapshots/innovus/pg_prior/reports/operator_gate_pg_proof.rpt"
FAILED_PG_GATE="$REPO/MPTDC/docs/server_snapshots/innovus/pg_failed/reports/operator_gate_pg_proof.rpt"
SOURCE_PNR_ID="pnr_three_marker_source"
SOURCE_PNR_ROOT="$REPO/MPTDC/docs/server_snapshots/innovus/$SOURCE_PNR_ID"
SOURCE_PNR_GATE="$SOURCE_PNR_ROOT/reports/operator_gate_physical_pnr.rpt"
SOURCE_PNR_ROUTE="$SOURCE_PNR_ROOT/reports/route_status.rpt"
SOURCE_PNR_MARKERS="$SOURCE_PNR_ROOT/reports/route_drc_markers.tsv"
mkdir -p \
  "$(dirname "$PRE_GATE")" \
  "$(dirname "$PG_GATE")" \
  "$(dirname "$FAILED_PG_GATE")" \
  "$WORK/innovus/pg_failed/checkpoints/03_cts.enc.dat" \
  "$WORK/innovus/$SOURCE_PNR_ID/checkpoints/04_route_failed.enc.dat" \
  "$SOURCE_PNR_ROOT/reports"
cat > "$PRE_GATE" <<'EOF'
STEP=PRE_PNR
PACKAGE_RC=0
PRE_PNR_RC=0
PRE_PNR_GATE=PASS
DECISION=PASS_CONTINUE
EOF
cat > "$PG_GATE" <<'EOF'
STEP=PG_PROOF
PG_RC=0
POSTPLACE_PRE_ROUTE_SROUTE_STATUS=PASS
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_BAD=1
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_RAW_BAD=1
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_NON_RO_FAILURES=0
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_DANGLING_ONLY_STATUS=DANGLING_ONLY
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_DANGLING_ONLY_REASON=only_impvfc_94_dangling
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_DANGLING_COUNT=34
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_DANGLING_MAX=34
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_DANGLING_FATAL_COUNT=0
POSTPLACE_PRE_ROUTE_SROUTE_DANGLING_ONLY_OVERRIDE=1
POSTPLACE_PRE_ROUTE_PG_DRC_CAPTURE_STATUS=PASS
POSTPLACE_PRE_ROUTE_PG_CROSS_NET_SHORT_STATUS=PASS
POSTPLACE_PRE_ROUTE_PG_CROSS_NET_SHORT_COUNT=0
BLOCK_PG_PIN_STATUS=PASS
BLOCK_PG_PIN_STYLE=ring_aligned_vdd_vss_pair
BLOCK_PG_PIN_REQUESTED_COUNT=2
PG_GATE_MODE=BOUNDED_DANGLING_CONTINUATION
DECISION=PASS_CONTINUE
EOF
cat > "$FAILED_PG_GATE" <<'EOF'
STEP=STRICT_PG_PROOF
PG_RC=1
POSTPLACE_PRE_ROUTE_SROUTE_STATUS=FAIL
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_BAD=1
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_RAW_BAD=1
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_NON_RO_FAILURES=0
DECISION=FAIL_STOP
EOF
cat > "$SOURCE_PNR_GATE" <<'EOF'
STEP=PHYSICAL_PNR
PNR_RC=1
ROUTE_STATUS=FAIL
INNOVUS_VERIFY_DRC_STATUS=FAIL
GEOMETRY_DRC_VIOLATIONS=3
SHORTS=1
REGULAR_NET_CONNECTIVITY_BAD=0
SPECIAL_NET_CONNECTIVITY_BAD=1
SPECIAL_NET_CONNECTIVITY_RAW_BAD=1
SPECIAL_NET_CONNECTIVITY_NON_RO_FAILURES=0
ro_slow_tap0_o_COUNT=1
ro_fast_tap0_o_COUNT=1
RO_TAP_OBSERVABILITY_PIN_COUNT=2
DECISION=FAIL_STOP
EOF
cat > "$SOURCE_PNR_ROUTE" <<'EOF'
ROUTE_STATUS=FAIL
INNOVUS_VERIFY_DRC_STATUS=FAIL
GEOMETRY_DRC_VIOLATIONS=3
SHORTS=1
REGULAR_NET_CONNECTIVITY_BAD=0
SPECIAL_NET_CONNECTIVITY_BAD=1
SPECIAL_NET_CONNECTIVITY_RAW_BAD=1
SPECIAL_NET_CONNECTIVITY_NON_RO_FAILURES=0
ROUTE_GATE_FAILURE_CHECKPOINT_DAT_EXISTS=1
EOF
cat > "$SOURCE_PNR_MARKERS" <<'EOF'
idx	marker_handle	box	layer	type	subType	message
1	0x1	{364.65 328.3 365.03 328.58}	MET1	Geometry	Minimal_Area	Regular Wire of Net u_core_n_57563 Actual: 0.10640000 Required: 0.20200000
2	0x2	{219.94 223.775 219.96 224.505}	MET2	Geometry	Parallel_Run_Length_Spacing	Regular Wire of Net u_core_n_67240 & Special Wire of Net VDD
3	0x3	{219.94 223.775 219.96 224.505}	MET2	Geometry	Parallel_Run_Length_Spacing	Regular Wire of Net u_core_n_67240 & Special Wire of Net VDD
4	0x4	{220.5 179.29 220.76 180.015}	MET2	Geometry	Metal_Short	Regular Wire of Net u_core_n_66687 & Special Wire of Net VSS
5	0x5	{220.5 179.29 220.76 180.015}	MET2	Geometry	Metal_Short	Regular Wire of Net u_core_n_66687 & Special Wire of Net VSS
EOF
git -C "$REPO" add MPTDC
git -C "$REPO" commit -q -m fixtures
HEAD_SHA="$(git -C "$REPO" rev-parse HEAD)"

printf 'MACRO RO_tune6\nEND RO_tune6\n' > "$PNR_LEF"
PNR_LEF_SHA256="$(sha256sum "$PNR_LEF" | awk '{print $1}')"
cat > "$PNR_LEF_SUMMARY" <<EOF
OUTPUT_LEF=$PNR_LEF
OUTPUT_LEF_SHA256=$PNR_LEF_SHA256
REQUIRED_ACCESS_PIN_SET_STATUS=PASS
UNEXPECTED_ACCESS_PIN_COUNT=0
MET2_ACCESS_WINDOW_COUNT=13
MET3_ACCESS_WINDOW_COUNT=13
PNR_LEF_PREP_STATUS=PASS
EOF

FAKE_CADENCE_ENV="$TMP_ROOT/fake_cadence_env.sh"
cat > "$FAKE_CADENCE_ENV" <<'EOF'
: "$MPTDC_CADENCE_FIXTURE_UNSET"
export MPTDC_CADENCE_FIXTURE_LOADED=1
EOF
FAILING_CADENCE_ENV="$TMP_ROOT/failing_cadence_env.sh"
printf 'return 23\n' > "$FAILING_CADENCE_ENV"

FAKE_LAUNCHER="$TMP_ROOT/fake_launcher.sh"
cat > "$FAKE_LAUNCHER" <<'EOF'
#!/usr/bin/env bash
set -eu
test "${MPTDC_CADENCE_FIXTURE_LOADED:-0}" = 1
run_id=""
stage=""
work=""
strict_special_clean=0
dangling_only_max=""
temporary_signal_top_blockage=0
pnr_lef=""
ro_halos=0
allow_candidate=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-id) run_id="$2"; shift 2 ;;
    --stage) stage="$2"; shift 2 ;;
    --innovus-work) work="$2"; shift 2 ;;
    --strict-special-clean) strict_special_clean=1; shift ;;
    --dangling-only-max) dangling_only_max="$2"; shift 2 ;;
    --temporary-signal-top-route-blockage) temporary_signal_top_blockage=1; shift ;;
    --pnr-lef) pnr_lef="$2"; shift 2 ;;
    --ro-halos) ro_halos=1; shift ;;
    --allow-exact-pg-pvs-candidate) allow_candidate=1; shift ;;
    *) shift ;;
  esac
done
test "$strict_special_clean" = 0
test "$dangling_only_max" = "${EXPECTED_DANGLING_ONLY_MAX:-34}"
if [[ "$stage" == full_closure ]]; then
  test "$temporary_signal_top_blockage" = 1
  test "$ro_halos" = 1
fi
run="$work/$run_id"
mkdir -p "$run/reports" "$run/def" "$run/checkpoints/04_route.enc.dat"
if [[ "$stage" == pg_proof ]]; then
  cat > "$run/reports/block_pg_pin_status.rpt" <<'RPT'
BLOCK_PG_PIN_STATUS=PASS
BLOCK_PG_PIN_STYLE=ring_aligned_vdd_vss_pair
BLOCK_PG_PIN_REQUESTED_COUNT=2
RPT
  if [[ "${FAKE_PG_RAW_CLEAN:-0}" == 1 ]]; then
    pg_bad=0
    pg_raw_bad=0
    dangling_status=FAIL
    dangling_reason=no_dangling_evidence
    dangling_count=0
    dangling_override=0
  else
    pg_bad=1
    pg_raw_bad=1
    dangling_status=DANGLING_ONLY
    dangling_reason=only_impvfc_94_dangling
    dangling_count=34
    dangling_override=1
  fi
  cross_short_count="${FAKE_PG_CROSS_SHORT_COUNT:-0}"
  cat > "$run/reports/postplace_pre_route_sroute_status.rpt" <<RPT
POSTPLACE_PRE_ROUTE_SROUTE_STATUS=PASS
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_BAD=$pg_bad
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_RAW_BAD=$pg_raw_bad
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_NON_RO_FAILURES=0
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_DANGLING_ONLY_STATUS=$dangling_status
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_DANGLING_ONLY_REASON=$dangling_reason
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_DANGLING_COUNT=$dangling_count
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_DANGLING_MAX=34
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_DANGLING_FATAL_COUNT=0
POSTPLACE_PRE_ROUTE_SROUTE_DANGLING_ONLY_OVERRIDE=$dangling_override
POSTPLACE_PRE_ROUTE_PG_DRC_CAPTURE_STATUS=PASS
POSTPLACE_PRE_ROUTE_PG_CROSS_NET_SHORT_STATUS=PASS
POSTPLACE_PRE_ROUTE_PG_CROSS_NET_SHORT_COUNT=$cross_short_count
RPT
  exit 0
fi
cat > "$run/reports/postplace_pre_route_sroute_status.rpt" <<RPT
POSTPLACE_PRE_ROUTE_SROUTE_STATUS=PASS
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_DANGLING_ONLY_STATUS=DANGLING_ONLY
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_DANGLING_COUNT=$dangling_only_max
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_DANGLING_MAX=$dangling_only_max
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_DANGLING_FATAL_COUNT=0
POSTPLACE_PRE_ROUTE_PG_CROSS_NET_SHORT_COUNT=0
RPT
cat > "$run/reports/ro_halo_status.rpt" <<'RPT'
RO_PHASE_MIN_CLEARANCE_UM=10.0
RO_HALO_ENABLED=1
SLOW_HALO_STATUS=PASS
FAST_HALO_STATUS=PASS
RO_HALO_COUNT=2
RO_HALO_STATUS=PASS
RPT
halo_intrusions="${FAKE_HALO_INTRUSIONS:-0}"
halo_occupancy_status=PASS
if [[ "$halo_intrusions" != 0 ]]; then halo_occupancy_status=FAIL; fi
cat > "$run/reports/ro_halo_occupancy.rpt" <<RPT
RO_HALO_ENABLED=1
RO_HALO_CLEARANCE_UM=10.0
RO_TUNE6_COUNT=2
RO_HALO_INVALID_INSTANCE_BBOX_COUNT=0
RO_HALO_TOTAL_INTRUSION_COUNT=$halo_intrusions
RO_HALO_OCCUPANCY_STATUS=$halo_occupancy_status
RPT
cat > "$run/reports/ro_phase_overlap_audit.rpt" <<'RPT'
RO_PHASE_MIN_CLEARANCE_REQUIRED_UM=10.0
SLOW_RO_PHASE_PLACEMENT_STATUS=PASS
FAST_RO_PHASE_PLACEMENT_STATUS=PASS
RO_PHASE_MIN_CLEARANCE_UM=17.42
RO_PHASE_PLACEMENT_STATUS=PASS
RPT
shorts=0
tool_rc=0
if [[ "${FAKE_DIRTY_ROUTE:-0}" == 1 ]]; then shorts=1; tool_rc=1; fi
actual_pnr_lef="${pnr_lef:-/fixture/RO_tune6.lef}"
if [[ "${FAKE_PNR_LEF_MISMATCH:-0}" == 1 ]]; then
  actual_pnr_lef="${actual_pnr_lef}.mismatch"
fi
cat > "$run/reports/ro_import_source_gate.rpt" <<RPT
O1_RO_LEF_PATH=$actual_pnr_lef
RPT
route_status=PASS
special_bad=0
special_raw_bad=0
if [[ "$shorts" != 0 ]]; then route_status=FAIL; fi
if [[ "${FAKE_ROUTE_CANDIDATE:-0}" == 1 && "$shorts" == 0 ]]; then
  test "$allow_candidate" = 1
  route_status=PVS_CANDIDATE
  special_bad=1
  special_raw_bad=1
fi
cat > "$run/reports/route_status.rpt" <<RPT
ROUTE_STATUS=$route_status
INNOVUS_VERIFY_DRC_STATUS=$([[ "$shorts" == 0 ]] && echo PASS || echo FAIL)
GEOMETRY_DRC_VIOLATIONS=$shorts
SHORTS=$shorts
REGULAR_NET_CONNECTIVITY_BAD=0
SPECIAL_NET_CONNECTIVITY_BAD=$special_bad
SPECIAL_NET_CONNECTIVITY_RAW_BAD=$special_raw_bad
SPECIAL_NET_CONNECTIVITY_NON_RO_FAILURES=0
UNROUTED_NETS=0
RPT
if [[ "${FAKE_ROUTE_CANDIDATE:-0}" == 1 ]]; then
  altered_x=221.750
  if [[ "${FAKE_ALTER_CANDIDATE_ENDPOINT:-0}" == 1 ]]; then altered_x=221.751; fi
  cat > "$run/reports/route_connectivity_special_detailed.rpt" <<RPT
Net VDD: dangling Wire at ($altered_x, 681.160) ($altered_x, 681.160) on layer: MET3
Net VDD: dangling Wire at (48.000, 681.160) (48.000, 681.160) on layer: MET3
Net VDD: dangling Wire at (221.750, 201.160) (221.750, 201.160) on layer: MET3
Net VDD: dangling Wire at (48.000, 201.160) (48.000, 201.160) on layer: MET3
Net VDD: dangling Wire at (201.160, 233.620) (201.160, 233.620) on layer: METTP
Net VSS: dangling Wire at (221.750, 685.160) (221.750, 685.160) on layer: MET3
Net VSS: dangling Wire at (48.000, 685.160) (48.000, 685.160) on layer: MET3
Net VSS: dangling Wire at (221.750, 205.160) (221.750, 205.160) on layer: MET3
Net VSS: dangling Wire at (48.000, 205.160) (48.000, 205.160) on layer: MET3
Net VSS: dangling Wire at (205.160, 158.320) (205.160, 158.320) on layer: METTP
Net VSS: dangling Wire at (125.160, 721.750) (125.160, 721.750) on layer: METTP
Net VSS: dangling Wire at (125.160, 158.320) (125.160, 158.320) on layer: METTP
    12 Problem(s) (IMPVFC-94): The net has dangling wire(s).
RPT
  cat > "$run/reports/route_pg_pvs_candidate_status.rpt" <<'RPT'
ROUTE_PG_PVS_CANDIDATE_ENABLED=1
ROUTE_PG_PVS_CANDIDATE_EXPECTED_COUNT=12
ROUTE_PG_PVS_CANDIDATE_ACTUAL_COUNT=12
ROUTE_PG_PVS_CANDIDATE_SUMMARY_COUNT=12
ROUTE_PG_PVS_CANDIDATE_OTHER_NET_LINE_COUNT=0
ROUTE_PG_PVS_CANDIDATE_OTHER_PROBLEM_LINE_COUNT=0
ROUTE_PG_PVS_CANDIDATE_EXACT_MATCH=1
ROUTE_PG_PVS_CANDIDATE_STATUS=PASS
RPT
else
  cat > "$run/reports/route_pg_pvs_candidate_status.rpt" <<'RPT'
ROUTE_PG_PVS_CANDIDATE_EXPECTED_COUNT=12
ROUTE_PG_PVS_CANDIDATE_ACTUAL_COUNT=0
ROUTE_PG_PVS_CANDIDATE_SUMMARY_COUNT=0
ROUTE_PG_PVS_CANDIDATE_OTHER_NET_LINE_COUNT=0
ROUTE_PG_PVS_CANDIDATE_OTHER_PROBLEM_LINE_COUNT=0
ROUTE_PG_PVS_CANDIDATE_EXACT_MATCH=0
ROUTE_PG_PVS_CANDIDATE_STATUS=FAIL
RPT
fi
cat > "$run/reports/route_layer_intent.rpt" <<'RPT'
signal_top_layer=MET3
router_command_top_layer=METTP
RPT
printf 'ROUTE_COMMAND_STATUS=PASS\n' > "$run/reports/route_command_status.rpt"
cat > "$run/reports/signal_top_route_blockage_status.rpt" <<'RPT'
SIGNAL_TOP_ROUTE_BLOCKAGE_TEMPORARY=1
SIGNAL_TOP_ROUTE_BLOCKAGE_CREATE_STATUS=PASS
SIGNAL_TOP_ROUTE_BLOCKAGE_REMOVE_STATUS=PASS
SIGNAL_TOP_ROUTE_BLOCKAGE_STATUS=REMOVED
RPT
printf 'REPORT_STATUS=OK\n' > "$run/reports/io_pin_placement_summary.md"
cat > "$run/reports/extracted_timing_status.rpt" <<'RPT'
SETUP_STATUS_TC=PASS
TC_HOLD_STATUS=PASS
RPT
printf 'DRV_STATUS=PASS\n' > "$run/reports/drv_status.rpt"
printf 'POWER_REPORT_CAPTURE_STATUS=PASS\n' > "$run/reports/power_status.rpt"
printf 'EXTRACTION_STATUS=PASS\n' > "$run/reports/digital_pnr_signoff_status.rpt"
cat > "$run/reports/io_pin_placement.csv" <<'CSV'
pin,direction,side,layer,status
"ro_slow_tap0_o",out,SOUTH,MET3,REQUESTED
"ro_fast_tap0_o",out,SOUTH,MET3,REQUESTED
CSV
cat > "$run/def/04_route.def" <<'DEF'
VERSION 5.8 ;
PINS 2 ;
- ro_slow_tap0_o + NET ro_slow_tap0_o + DIRECTION OUTPUT + USE SIGNAL
  + LAYER MET3 ( -200 -200 ) ( 200 200 ) + PLACED ( 1000 0 ) N ;
- ro_fast_tap0_o + NET ro_fast_tap0_o + DIRECTION OUTPUT + USE SIGNAL
  + LAYER MET3 ( -200 -200 ) ( 200 200 ) + PLACED ( 2000 0 ) N ;
END PINS
END DESIGN
DEF
exit "$tool_rc"
EOF
chmod +x "$FAKE_LAUNCHER"

FAKE_SWEEP_LAUNCHER="$TMP_ROOT/fake_sweep_launcher.sh"
cat > "$FAKE_SWEEP_LAUNCHER" <<'EOF'
#!/usr/bin/env bash
set -eu
test "${MPTDC_CADENCE_FIXTURE_LOADED:-0}" = 1
base_run_id=""
work=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-run-id) base_run_id="$2"; shift 2 ;;
    --innovus-work) work="$2"; shift 2 ;;
    *) shift ;;
  esac
done
test -n "$base_run_id"
test -n "$work"

summary_csv="$work/${base_run_id}_summary.csv"
summary_md="$work/${base_run_id}_summary.md"
printf '%s\n' 'candidate,run_id,rc,strict_pg_clean,strict_pg_reasons,drc,shorts,regular_bad,special_bad,special_raw_bad,special_filter_status,special_filtered_ro,special_non_ro,unrouted,route_gate_pass,checkpoint,status_report' > "$summary_csv"
printf '# PG sweep fixture\n' > "$summary_md"

candidates=(
  corepin_ring
  corepin_first_after_row_end
  core_block_ring
  core_block_pad_ring
  core_block_via_closest
  core_block_connect_broken
  core_block_pin_width
  core_block_pin_corners
  core_block_target_80
  core_block_target_250
)
for candidate in "${candidates[@]}"; do
  candidate_run_id="${base_run_id}_${candidate}"
  result_dir="$work/$candidate_run_id"
  status_report="$result_dir/reports/checkpoint_repair_status.rpt"
  checkpoint="$result_dir/checkpoints/repaired_route.enc.dat"
  mkdir -p "$result_dir/reports" "$checkpoint"
  printf 'CHECKPOINT_REPAIR_STATUS=PASS\n' > "$status_report"
  if [[ "${FAKE_SWEEP_PASS:-1}" == 1 && "$candidate" == core_block_connect_broken ]]; then
    printf '%s,%s,0,PASS,PASS,0,0,0,0,0,NONE,0,0,0,1,%s,%s\n' \
      "$candidate" "$candidate_run_id" "$checkpoint" "$status_report" >> "$summary_csv"
  else
    printf '%s,%s,0,FAIL,special_raw_1,0,0,0,1,1,NONE,0,0,0,0,%s,%s\n' \
      "$candidate" "$candidate_run_id" "$checkpoint" "$status_report" >> "$summary_csv"
  fi
done
EOF
chmod +x "$FAKE_SWEEP_LAUNCHER"

FAKE_REPAIR_LAUNCHER="$TMP_ROOT/fake_repair_launcher.sh"
cat > "$FAKE_REPAIR_LAUNCHER" <<'EOF'
#!/usr/bin/env bash
set -eu
run_id=""
checkpoint=""
commands_file=""
work=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-id) run_id="$2"; shift 2 ;;
    --checkpoint) checkpoint="$2"; shift 2 ;;
    --commands-file) commands_file="$2"; shift 2 ;;
    --innovus-work) work="$2"; shift 2 ;;
    *) shift ;;
  esac
done
test -d "$checkpoint"
test -s "$commands_file"
if grep -qx 'mptdc_ckpt_probe_target_geometry {u_core_n_66687 u_core_n_67240 u_core_n_57563}' "$commands_file"; then
  test "$(wc -l < "$commands_file")" -eq 1
  run="$work/$run_id"
  mkdir -p "$run/reports" "$run/def" "$run/checkpoints/repaired_route.enc.dat"
  initial_special="$run/reports/00_initial_verify_connectivity_special.rpt"
  final_special="$run/reports/01_after_command_verify_connectivity_special.rpt"
  for report in "$initial_special" "$final_special"; do
    {
      for idx in $(seq 1 6); do
        echo "Net VDD: dangling Wire at ($idx.000, 1.000) ($idx.000, 1.000) on layer: MET3"
      done
      for idx in $(seq 1 6); do
        echo "Net VSS: dangling Wire at ($idx.000, 2.000) ($idx.000, 2.000) on layer: MET3"
      done
      echo '    12 Problem(s) (IMPVFC-94): The net has dangling wire(s).'
    } > "$report"
  done
  cat > "$run/reports/route_geometry_target_probe.rpt" <<'RPT'
PROBE_MODE=READ_ONLY_NO_ROUTE_EDITS
TARGET_NET_COUNT=3
TARGET_NET_WITH_INSTTERMS_COUNT=3
TARGET_NET_WITH_PIN_GEOMETRY_COUNT=3
TARGET_INSTTERM_COUNT=6
TARGET_INSTTERM_PIN_GEOMETRY_COUNT=6
TARGET_WIRE_COUNT=9
TARGET_VIA_COUNT=2
NEARBY_PG_SHAPE_COUNT=4
HELP_CAPTURE_PASS_COUNT=8
HELP_CAPTURE_STATUS=PASS
SCHEMA_CAPTURE_PASS_COUNT=7
SCHEMA_CAPTURE_STATUS=PASS
PROBE_STATUS=PASS
RPT
  cat > "$run/def/repaired_route.def" <<'DEF'
VERSION 5.8 ;
PINS 2 ;
- ro_slow_tap0_o + NET ro_slow_tap0_o + DIRECTION OUTPUT + USE SIGNAL
  + LAYER MET3 ( -200 -200 ) ( 200 200 ) + PLACED ( 1000 0 ) N ;
- ro_fast_tap0_o + NET ro_fast_tap0_o + DIRECTION OUTPUT + USE SIGNAL
  + LAYER MET3 ( -200 -200 ) ( 200 200 ) + PLACED ( 2000 0 ) N ;
END PINS
END DESIGN
DEF
  cat > "$run/reports/checkpoint_repair_status.rpt" <<RPT
INITIAL_DRC=3
INITIAL_SHORTS=1
INITIAL_REGULAR_CONNECTIVITY_BAD=0
INITIAL_SPECIAL_CONNECTIVITY_BAD=1
INITIAL_SPECIAL_CONNECTIVITY_RAW_BAD=1
INITIAL_SPECIAL_CONNECTIVITY_NON_RO_FAILURES=0
INITIAL_SPECIAL_CONNECTIVITY_REPORT=$initial_special
COMMAND_1_STATUS=PASS
FINAL_DRC=3
FINAL_SHORTS=1
FINAL_REGULAR_CONNECTIVITY_BAD=0
FINAL_SPECIAL_CONNECTIVITY_BAD=1
FINAL_SPECIAL_CONNECTIVITY_RAW_BAD=1
FINAL_SPECIAL_CONNECTIVITY_NON_RO_FAILURES=0
FINAL_SPECIAL_CONNECTIVITY_REPORT=$final_special
FINAL_DEF=$run/def/repaired_route.def
FINAL_CHECKPOINT_DAT_EXISTS=1
CHECKPOINT_REPAIR_STATUS=REVIEW_REQUIRED
RPT
  exit 0
fi
grep -qx 'mptdc_ckpt_manual_three_marker_eco_v7' "$commands_file"
test "$(wc -l < "$commands_file")" -eq 1
! grep -qE 'globalDetailRoute|detailRoute|ecoRoute|routeDesign|createRouteBlk' "$commands_file"

run="$work/$run_id"
mkdir -p "$run/reports" "$run/def" "$run/checkpoints/repaired_route.enc.dat"
initial_special="$run/reports/00_initial_verify_connectivity_special.rpt"
final_special="$run/reports/final_verify_connectivity_special.rpt"
for report in "$initial_special" "$final_special"; do
  {
    for idx in $(seq 1 6); do
      echo "Net VDD: dangling Wire at ($idx.000, 1.000) ($idx.000, 1.000) on layer: MET3"
    done
    for idx in $(seq 1 6); do
      echo "Net VSS: dangling Wire at ($idx.000, 2.000) ($idx.000, 2.000) on layer: MET3"
    done
    echo '    12 Problem(s) (IMPVFC-94): The net has dangling wire(s).'
  } > "$report"
done
cat > "$run/reports/manual_geometry_eco_v7.rpt" <<'RPT'
MANUAL_ECO_MODE=STAGED_BOUNDED_DRC_WIRE_DELETE_AND_MET2_TRUNK_SPLICE
VIA_DELETE_MODE=FULL_GEOMETRY_BOX_AND_EXACT_VIA_CELL
OLD_MET2_LANDING_DELETE_MODE=BOUNDED_REGULAR_WIRE_WITH_DRC
OBSOLETE_MET3_DELETE_MODE=BOUNDED_REGULAR_WIRE_ONLY
VIA_INSERT_MODE=SINGLE_VIA1_ONLY
STAGED_TUPLE_GATES=ENABLED
REMOTE_VIA2_DELETE=u_core_n_66687:VIA2_o@224.84,179.48;u_core_n_67240:VIA2_o@229.32,225.40
REMOTE_MET2_TRUNK_SPLICE=u_core_n_66687:224.84,179.48;u_core_n_67240:229.32,225.40
PG_EDIT_POLICY=NO_PG_SHAPES_MODIFIED
PLACEMENT_EDIT_POLICY=NO_INSTANCES_MOVED
MANUAL_ECO_STATUS=PASS
RPT

final_drc=0
final_shorts=0
final_status=PASS_GEOMETRY_REVIEW_CONNECTIVITY
if [[ "${FAKE_REPAIR_DIRTY:-0}" == 1 ]]; then
  final_drc=1
  final_status=REVIEW_REQUIRED
fi
cat > "$run/def/repaired_route.def" <<'DEF'
VERSION 5.8 ;
PINS 2 ;
- ro_slow_tap0_o + NET ro_slow_tap0_o + DIRECTION OUTPUT + USE SIGNAL
  + LAYER MET3 ( -200 -200 ) ( 200 200 ) + PLACED ( 1000 0 ) N ;
- ro_fast_tap0_o + NET ro_fast_tap0_o + DIRECTION OUTPUT + USE SIGNAL
  + LAYER MET3 ( -200 -200 ) ( 200 200 ) + PLACED ( 2000 0 ) N ;
END PINS
END DESIGN
DEF
cat > "$run/reports/checkpoint_repair_status.rpt" <<RPT
INITIAL_DRC=3
INITIAL_SHORTS=1
INITIAL_REGULAR_CONNECTIVITY_BAD=0
INITIAL_SPECIAL_CONNECTIVITY_BAD=1
INITIAL_SPECIAL_CONNECTIVITY_RAW_BAD=1
INITIAL_SPECIAL_CONNECTIVITY_NON_RO_FAILURES=0
INITIAL_SPECIAL_CONNECTIVITY_REPORT=$initial_special
FINAL_DRC=$final_drc
FINAL_SHORTS=$final_shorts
FINAL_REGULAR_CONNECTIVITY_BAD=0
FINAL_SPECIAL_CONNECTIVITY_BAD=1
FINAL_SPECIAL_CONNECTIVITY_RAW_BAD=1
FINAL_SPECIAL_CONNECTIVITY_NON_RO_FAILURES=0
FINAL_UNROUTED_NETS=0
FINAL_ROUTE_GATE_PASS=0
FINAL_SPECIAL_CONNECTIVITY_REPORT=$final_special
FINAL_DEF=$run/def/repaired_route.def
FINAL_CHECKPOINT_DAT_EXISTS=1
CHECKPOINT_REPAIR_STATUS=$final_status
RPT
exit 0
EOF
chmod +x "$FAKE_REPAIR_LAUNCHER"

FAKE_PUBLISHER="$TMP_ROOT/fake_publisher.sh"
cat > "$FAKE_PUBLISHER" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$PUBLISH_CALLS"
echo 'EVIDENCE_PUSH_RC=0'
exit 0
EOF
chmod +x "$FAKE_PUBLISHER"
export PUBLISH_CALLS

COMMON_ENV=(
  MPTDC_RECOVERY_REPO_ROOT="$REPO"
  MPTDC_RECOVERY_LAUNCHER="$FAKE_LAUNCHER"
  MPTDC_RECOVERY_SWEEP_LAUNCHER="$FAKE_SWEEP_LAUNCHER"
  MPTDC_RECOVERY_REPAIR_LAUNCHER="$FAKE_REPAIR_LAUNCHER"
  MPTDC_RECOVERY_PUBLISHER="$FAKE_PUBLISHER"
  MPTDC_CADENCE_ENV="$FAKE_CADENCE_ENV"
  MPTDC_WORK_ROOT="$WORK"
  MPTDC_INNOVUS_WORK="$WORK/innovus"
  MPTDC_RECOVERY_EXPECTED_HALO_GENUS_RUN_ID=genus_fixture
  MPTDC_RECOVERY_EXPECTED_HALO_PG_RUN_ID=pg_prior
  MPTDC_RECOVERY_EXPECTED_HALO_PNR_LEF="$PNR_LEF"
  MPTDC_RECOVERY_EXPECTED_HALO_PNR_LEF_SHA256="$PNR_LEF_SHA256"
)

env "${COMMON_ENV[@]}" bash "$DRIVER" \
  --stage pg-proof --run-id pg_fixture --expected-head "$HEAD_SHA" \
  --genus-run-id genus_fixture --handoff-dir "$HANDOFF" \
  > "$TMP_ROOT/pg.stdout"
grep -qx 'CADENCE_ENV_STATUS=PASS' "$TMP_ROOT/pg.stdout"
grep -qx 'DECISION=PASS_CONTINUE' "$WORK/innovus/pg_fixture/reports/operator_gate_pg_proof.rpt"
grep -qx 'PG_GATE_MODE=BOUNDED_DANGLING_CONTINUATION' "$WORK/innovus/pg_fixture/reports/operator_gate_pg_proof.rpt"
grep -q 'innovus pg_fixture .* PG_PROOF' "$PUBLISH_CALLS"

env "${COMMON_ENV[@]}" FAKE_PG_RAW_CLEAN=1 bash "$DRIVER" \
  --stage pg-proof --run-id pg_raw_fixture --expected-head "$HEAD_SHA" \
  --genus-run-id genus_fixture --handoff-dir "$HANDOFF" \
  > "$TMP_ROOT/pg_raw.stdout"
grep -qx 'DECISION=PASS_CONTINUE' "$WORK/innovus/pg_raw_fixture/reports/operator_gate_pg_proof.rpt"
grep -qx 'PG_GATE_MODE=RAW_CLEAN' "$WORK/innovus/pg_raw_fixture/reports/operator_gate_pg_proof.rpt"

set +e
env "${COMMON_ENV[@]}" FAKE_PG_CROSS_SHORT_COUNT=1 bash "$DRIVER" \
  --stage pg-proof --run-id pg_cross_short --expected-head "$HEAD_SHA" \
  --genus-run-id genus_fixture --handoff-dir "$HANDOFF" \
  > "$TMP_ROOT/pg_cross_short.stdout"
PG_CROSS_SHORT_RC=$?
set -e
test "$PG_CROSS_SHORT_RC" -ne 0
grep -qx 'POSTPLACE_PRE_ROUTE_PG_CROSS_NET_SHORT_COUNT=1' "$WORK/innovus/pg_cross_short/reports/operator_gate_pg_proof.rpt"
grep -qx 'DECISION=FAIL_STOP' "$WORK/innovus/pg_cross_short/reports/operator_gate_pg_proof.rpt"

set +e
env "${COMMON_ENV[@]}" MPTDC_CADENCE_ENV="$FAILING_CADENCE_ENV" bash "$DRIVER" \
  --stage pg-proof --run-id pg_env_fail --expected-head "$HEAD_SHA" \
  --genus-run-id genus_fixture --handoff-dir "$HANDOFF" \
  > "$TMP_ROOT/pg_env_fail.stdout"
ENV_FAIL_RC=$?
set -e
test "$ENV_FAIL_RC" -eq 5
grep -qx 'CADENCE_ENV_RC=23' "$TMP_ROOT/pg_env_fail.stdout"
grep -qx 'CADENCE_ENV_STATUS=FAIL' "$TMP_ROOT/pg_env_fail.stdout"
grep -qx 'DECISION=FAIL_STOP' "$TMP_ROOT/pg_env_fail.stdout"
test ! -e "$WORK/innovus/pg_env_fail"

env "${COMMON_ENV[@]}" bash "$DRIVER" \
  --stage pg-sweep --run-id sweep_fixture --source-pg-run-id pg_failed \
  --expected-head "$HEAD_SHA" \
  > "$TMP_ROOT/sweep.stdout"
grep -qx 'CADENCE_ENV_STATUS=PASS' "$TMP_ROOT/sweep.stdout"
grep -qx 'CANDIDATE_COUNT=10' "$WORK/innovus/sweep_fixture/reports/operator_gate_pg_sroute_sweep.rpt"
grep -qx 'STRICT_PASS_COUNT=1' "$WORK/innovus/sweep_fixture/reports/operator_gate_pg_sroute_sweep.rpt"
grep -qx 'STRICT_PASS_CANDIDATES=core_block_connect_broken' "$WORK/innovus/sweep_fixture/reports/operator_gate_pg_sroute_sweep.rpt"
grep -qx 'DECISION=PASS_CONTINUE' "$WORK/innovus/sweep_fixture/reports/operator_gate_pg_sroute_sweep.rpt"
test -s "$WORK/innovus/sweep_fixture/reports/candidates/core_block_connect_broken/checkpoint_repair_status.rpt"
grep -q 'innovus sweep_fixture .* PG_SROUTE_SWEEP' "$PUBLISH_CALLS"
grep -qx 'NEXT_STAGE=REVIEW_AND_REPLAY_PG_CANDIDATE' "$TMP_ROOT/sweep.stdout"

set +e
env "${COMMON_ENV[@]}" FAKE_SWEEP_PASS=0 bash "$DRIVER" \
  --stage pg-sweep --run-id sweep_no_pass --source-pg-run-id pg_failed \
  --expected-head "$HEAD_SHA" \
  > "$TMP_ROOT/sweep_no_pass.stdout"
SWEEP_NO_PASS_RC=$?
set -e
test "$SWEEP_NO_PASS_RC" -ne 0
grep -qx 'STRICT_PASS_COUNT=0' "$WORK/innovus/sweep_no_pass/reports/operator_gate_pg_sroute_sweep.rpt"
grep -qx 'DECISION=FAIL_STOP' "$WORK/innovus/sweep_no_pass/reports/operator_gate_pg_sroute_sweep.rpt"
grep -q 'innovus sweep_no_pass .* PG_SROUTE_SWEEP' "$PUBLISH_CALLS"
grep -qx 'NEXT_STAGE=STOP_AND_REVIEW_PUBLISHED_EVIDENCE' "$TMP_ROOT/sweep_no_pass.stdout"

env "${COMMON_ENV[@]}" EXPECTED_DANGLING_ONLY_MAX=35 bash "$DRIVER" \
  --stage physical-pnr --run-id route_pnr_lef_35 --pg-run-id pg_prior \
  --pnr-lef "$PNR_LEF" --pre-route-dangling-max 35 --ro-halos \
  --expected-head "$HEAD_SHA" --genus-run-id genus_fixture --handoff-dir "$HANDOFF" \
  > "$TMP_ROOT/route_pnr_lef_35.stdout"
grep -qx 'DECISION=PASS_CONTINUE' "$WORK/innovus/route_pnr_lef_35/reports/operator_gate_physical_pnr.rpt"
grep -qx 'PHYSICAL_GATE_MODE=STRICT_CLEAN' "$WORK/innovus/route_pnr_lef_35/reports/operator_gate_physical_pnr.rpt"
grep -qx 'PRE_ROUTE_DANGLING_MODE=PNR_LEF_ONE_MARKER_CONTINUATION' "$WORK/innovus/route_pnr_lef_35/reports/operator_gate_physical_pnr.rpt"
grep -qx 'PRE_ROUTE_DANGLING_COUNT=35' "$WORK/innovus/route_pnr_lef_35/reports/operator_gate_physical_pnr.rpt"
grep -qx 'PRE_ROUTE_DANGLING_MAX=35' "$WORK/innovus/route_pnr_lef_35/reports/operator_gate_physical_pnr.rpt"
grep -qx 'RO_HALO_STATUS=PASS' "$WORK/innovus/route_pnr_lef_35/reports/operator_gate_physical_pnr.rpt"
grep -qx 'RO_HALO_OCCUPANCY_STATUS=PASS' "$WORK/innovus/route_pnr_lef_35/reports/operator_gate_physical_pnr.rpt"
grep -qx 'SETUP_STATUS_TC=PASS' "$WORK/innovus/route_pnr_lef_35/reports/operator_gate_physical_pnr.rpt"
grep -qx 'TC_HOLD_STATUS=PASS' "$WORK/innovus/route_pnr_lef_35/reports/operator_gate_physical_pnr.rpt"
grep -qx 'DRV_STATUS=PASS' "$WORK/innovus/route_pnr_lef_35/reports/operator_gate_physical_pnr.rpt"
grep -qx 'RO_TAP_OBSERVABILITY_PIN_COUNT=2' "$WORK/innovus/route_pnr_lef_35/reports/tap_pin_def_excerpt.rpt"
grep -qx 'NEXT_STAGE=PVS' "$TMP_ROOT/route_pnr_lef_35.stdout"
test -s "$WORK/innovus/route_pnr_lef_35/outputs/RO_tune6_pnr_lef_used.txt"
test -s "$WORK/innovus/route_pnr_lef_35/outputs/RO_tune6_pnr_lef_summary.txt"

env "${COMMON_ENV[@]}" EXPECTED_DANGLING_ONLY_MAX=35 FAKE_ROUTE_CANDIDATE=1 \
  bash "$DRIVER" \
  --stage physical-pnr --run-id route_exact_candidate --pg-run-id pg_prior \
  --pnr-lef "$PNR_LEF" --pre-route-dangling-max 35 --ro-halos \
  --allow-exact-pg-pvs-candidate \
  --expected-head "$HEAD_SHA" --genus-run-id genus_fixture --handoff-dir "$HANDOFF" \
  > "$TMP_ROOT/route_exact_candidate.stdout"
grep -qx 'ROUTE_STATUS=PVS_CANDIDATE' "$WORK/innovus/route_exact_candidate/reports/operator_gate_physical_pnr.rpt"
grep -qx 'PHYSICAL_GATE_MODE=PVS_CANDIDATE_EXACT_PG_WIRE_ENDS' "$WORK/innovus/route_exact_candidate/reports/operator_gate_physical_pnr.rpt"
grep -qx 'DECISION=PVS_CANDIDATE_CONTINUE' "$WORK/innovus/route_exact_candidate/reports/operator_gate_physical_pnr.rpt"
grep -qx 'NEXT_STAGE=PVS' "$TMP_ROOT/route_exact_candidate.stdout"

set +e
env "${COMMON_ENV[@]}" EXPECTED_DANGLING_ONLY_MAX=35 FAKE_ROUTE_CANDIDATE=1 \
  FAKE_ALTER_CANDIDATE_ENDPOINT=1 bash "$DRIVER" \
  --stage physical-pnr --run-id route_altered_candidate --pg-run-id pg_prior \
  --pnr-lef "$PNR_LEF" --pre-route-dangling-max 35 --ro-halos \
  --allow-exact-pg-pvs-candidate \
  --expected-head "$HEAD_SHA" --genus-run-id genus_fixture --handoff-dir "$HANDOFF" \
  > "$TMP_ROOT/route_altered_candidate.stdout"
ALTERED_CANDIDATE_RC=$?
set -e
test "$ALTERED_CANDIDATE_RC" -ne 0
grep -qx 'DECISION=FAIL_STOP' "$WORK/innovus/route_altered_candidate/reports/operator_gate_physical_pnr.rpt"

set +e
env "${COMMON_ENV[@]}" EXPECTED_DANGLING_ONLY_MAX=35 FAKE_HALO_INTRUSIONS=1 \
  bash "$DRIVER" \
  --stage physical-pnr --run-id route_halo_intrusion --pg-run-id pg_prior \
  --pnr-lef "$PNR_LEF" --pre-route-dangling-max 35 --ro-halos \
  --expected-head "$HEAD_SHA" --genus-run-id genus_fixture --handoff-dir "$HANDOFF" \
  > "$TMP_ROOT/route_halo_intrusion.stdout"
HALO_INTRUSION_RC=$?
set -e
test "$HALO_INTRUSION_RC" -ne 0
grep -qx 'RO_HALO_TOTAL_INTRUSION_COUNT=1' "$WORK/innovus/route_halo_intrusion/reports/operator_gate_physical_pnr.rpt"
grep -qx 'DECISION=FAIL_STOP' "$WORK/innovus/route_halo_intrusion/reports/operator_gate_physical_pnr.rpt"

set +e
env "${COMMON_ENV[@]}" bash "$DRIVER" \
  --stage physical-pnr --run-id route_without_halos --pg-run-id pg_prior \
  --pnr-lef "$PNR_LEF" --pre-route-dangling-max 35 \
  --expected-head "$HEAD_SHA" --genus-run-id genus_fixture --handoff-dir "$HANDOFF" \
  > "$TMP_ROOT/route_without_halos.stdout"
ROUTE_WITHOUT_HALOS_RC=$?
set -e
test "$ROUTE_WITHOUT_HALOS_RC" -eq 4
grep -qx 'STOP: physical-pnr requires --ro-halos' "$TMP_ROOT/route_without_halos.stdout"

set +e
env "${COMMON_ENV[@]}" bash "$DRIVER" \
  --stage physical-pnr --run-id route_35_without_pnr_lef --pg-run-id pg_prior \
  --pre-route-dangling-max 35 --ro-halos \
  --expected-head "$HEAD_SHA" --genus-run-id genus_fixture --handoff-dir "$HANDOFF" \
  > "$TMP_ROOT/route_35_without_pnr_lef.stdout"
ROUTE_35_WITHOUT_LEF_RC=$?
set -e
test "$ROUTE_35_WITHOUT_LEF_RC" -eq 4
grep -qx 'STOP: dangling bound 35 requires the audited 13+13 marker-derived PnR LEF' "$TMP_ROOT/route_35_without_pnr_lef.stdout"
grep -qx 'RECOVERY_PREFLIGHT=FAIL' "$TMP_ROOT/route_35_without_pnr_lef.stdout"

set +e
env "${COMMON_ENV[@]}" bash "$DRIVER" \
  --stage physical-pnr --run-id route_invalid_bound --pg-run-id pg_prior \
  --pnr-lef "$PNR_LEF" --pre-route-dangling-max 36 --ro-halos \
  --expected-head "$HEAD_SHA" --genus-run-id genus_fixture --handoff-dir "$HANDOFF" \
  > "$TMP_ROOT/route_invalid_bound.stdout"
ROUTE_INVALID_BOUND_RC=$?
set -e
test "$ROUTE_INVALID_BOUND_RC" -eq 4
grep -qx 'STOP: --pre-route-dangling-max must be 34 or 35' "$TMP_ROOT/route_invalid_bound.stdout"
grep -qx 'RECOVERY_PREFLIGHT=FAIL' "$TMP_ROOT/route_invalid_bound.stdout"

set +e
env "${COMMON_ENV[@]}" EXPECTED_DANGLING_ONLY_MAX=35 FAKE_PNR_LEF_MISMATCH=1 bash "$DRIVER" \
  --stage physical-pnr --run-id route_lef_mismatch --pg-run-id pg_prior \
  --pnr-lef "$PNR_LEF" --pre-route-dangling-max 35 --ro-halos \
  --expected-head "$HEAD_SHA" --genus-run-id genus_fixture --handoff-dir "$HANDOFF" \
  > "$TMP_ROOT/route_lef_mismatch.stdout"
LEF_MISMATCH_RC=$?
set -e
test "$LEF_MISMATCH_RC" -ne 0
grep -qx 'PNR_LEF_PATH_MATCH_STATUS=FAIL' "$WORK/innovus/route_lef_mismatch/reports/operator_gate_physical_pnr.rpt"
grep -qx 'PNR_LEF_GATE_STATUS=FAIL' "$WORK/innovus/route_lef_mismatch/reports/operator_gate_physical_pnr.rpt"
grep -qx 'DECISION=FAIL_STOP' "$WORK/innovus/route_lef_mismatch/reports/operator_gate_physical_pnr.rpt"

set +e
env "${COMMON_ENV[@]}" EXPECTED_DANGLING_ONLY_MAX=35 FAKE_DIRTY_ROUTE=1 bash "$DRIVER" \
  --stage physical-pnr --run-id route_dirty --pg-run-id pg_prior \
  --pnr-lef "$PNR_LEF" --pre-route-dangling-max 35 --ro-halos \
  --expected-head "$HEAD_SHA" --genus-run-id genus_fixture --handoff-dir "$HANDOFF" \
  > "$TMP_ROOT/route_dirty.stdout"
DIRTY_RC=$?
set -e
test "$DIRTY_RC" -ne 0
grep -qx 'DECISION=FAIL_STOP' "$WORK/innovus/route_dirty/reports/operator_gate_physical_pnr.rpt"
grep -q 'innovus route_dirty .* PHYSICAL_PNR' "$PUBLISH_CALLS"

env "${COMMON_ENV[@]}" bash "$DRIVER" \
  --stage route-geometry-probe --run-id geometry_probe \
  --source-pnr-run-id "$SOURCE_PNR_ID" --expected-head "$HEAD_SHA" \
  > "$TMP_ROOT/geometry_probe.stdout"
grep -qx 'CADENCE_ENV_STATUS=PASS' "$TMP_ROOT/geometry_probe.stdout"
grep -qx 'INITIAL_DRC=3' "$WORK/innovus/geometry_probe/reports/operator_gate_route_geometry_probe.rpt"
grep -qx 'FINAL_DRC=3' "$WORK/innovus/geometry_probe/reports/operator_gate_route_geometry_probe.rpt"
grep -qx 'FINAL_SHORTS=1' "$WORK/innovus/geometry_probe/reports/operator_gate_route_geometry_probe.rpt"
grep -qx 'PROBE_STATUS=PASS' "$WORK/innovus/geometry_probe/reports/operator_gate_route_geometry_probe.rpt"
grep -qx 'TARGET_NET_COUNT=3' "$WORK/innovus/geometry_probe/reports/operator_gate_route_geometry_probe.rpt"
grep -qx 'TARGET_NET_WITH_INSTTERMS_COUNT=3' "$WORK/innovus/geometry_probe/reports/operator_gate_route_geometry_probe.rpt"
grep -qx 'TARGET_NET_WITH_PIN_GEOMETRY_COUNT=3' "$WORK/innovus/geometry_probe/reports/operator_gate_route_geometry_probe.rpt"
grep -qx 'HELP_CAPTURE_STATUS=PASS' "$WORK/innovus/geometry_probe/reports/operator_gate_route_geometry_probe.rpt"
grep -qx 'SCHEMA_CAPTURE_STATUS=PASS' "$WORK/innovus/geometry_probe/reports/operator_gate_route_geometry_probe.rpt"
grep -qx 'PROBE_GATE_MODE=READ_ONLY_BASELINE_PRESERVED' "$WORK/innovus/geometry_probe/reports/operator_gate_route_geometry_probe.rpt"
grep -qx 'DECISION=PASS_CONTINUE' "$WORK/innovus/geometry_probe/reports/operator_gate_route_geometry_probe.rpt"
grep -q 'innovus geometry_probe .* ROUTE_GEOMETRY_PROBE' "$PUBLISH_CALLS"
grep -qx 'NEXT_STAGE=REVIEW_ROUTE_GEOMETRY_PROBE' "$TMP_ROOT/geometry_probe.stdout"
grep -qx 'NEXT_REQUIRED_PROBE_RUN_ID=geometry_probe' "$TMP_ROOT/geometry_probe.stdout"

env "${COMMON_ENV[@]}" bash "$DRIVER" \
  --stage route-geometry-repair --run-id geometry_repair_clean \
  --source-pnr-run-id "$SOURCE_PNR_ID" --expected-head "$HEAD_SHA" \
  > "$TMP_ROOT/geometry_repair_clean.stdout"
grep -qx 'CADENCE_ENV_STATUS=PASS' "$TMP_ROOT/geometry_repair_clean.stdout"
grep -qx 'INITIAL_DRC=3' "$WORK/innovus/geometry_repair_clean/reports/operator_gate_route_geometry_repair.rpt"
grep -qx 'MANUAL_ECO_STATUS=PASS' "$WORK/innovus/geometry_repair_clean/reports/operator_gate_route_geometry_repair.rpt"
grep -qx 'REPAIR_METHOD=STAGED_BOUNDED_DRC_WIRE_DELETE_AND_MET2_TRUNK_SPLICE_V7' "$WORK/innovus/geometry_repair_clean/reports/operator_gate_route_geometry_repair.rpt"
grep -qx 'VIA_DELETE_MODE=FULL_GEOMETRY_BOX_AND_EXACT_VIA_CELL' "$WORK/innovus/geometry_repair_clean/reports/operator_gate_route_geometry_repair.rpt"
grep -qx 'OLD_MET2_LANDING_DELETE_MODE=BOUNDED_REGULAR_WIRE_WITH_DRC' "$WORK/innovus/geometry_repair_clean/reports/operator_gate_route_geometry_repair.rpt"
grep -qx 'OBSOLETE_MET3_DELETE_MODE=BOUNDED_REGULAR_WIRE_ONLY' "$WORK/innovus/geometry_repair_clean/reports/operator_gate_route_geometry_repair.rpt"
grep -qx 'VIA_INSERT_MODE=SINGLE_VIA1_ONLY' "$WORK/innovus/geometry_repair_clean/reports/operator_gate_route_geometry_repair.rpt"
grep -qx 'STAGED_TUPLE_GATES=ENABLED' "$WORK/innovus/geometry_repair_clean/reports/operator_gate_route_geometry_repair.rpt"
grep -Fqx 'REPAIR_VIA_ESCAPE_POLICY=u_core_n_66687:220.64,179.48->221.20,178.92;u_core_n_67240:219.80,224.14->221.20,223.58' "$WORK/innovus/geometry_repair_clean/reports/operator_gate_route_geometry_repair.rpt"
grep -Fqx 'REPAIR_MET2_REMOTE_BRIDGE_POLICY=u_core_n_66687:221.20,178.92->224.84,179.48;u_core_n_67240:221.20,223.58->229.32,225.40' "$WORK/innovus/geometry_repair_clean/reports/operator_gate_route_geometry_repair.rpt"
grep -Fqx 'REMOTE_VIA2_DELETE=u_core_n_66687:VIA2_o@224.84,179.48;u_core_n_67240:VIA2_o@229.32,225.40' "$WORK/innovus/geometry_repair_clean/reports/operator_gate_route_geometry_repair.rpt"
grep -Fqx 'REMOTE_MET2_TRUNK_SPLICE=u_core_n_66687:224.84,179.48;u_core_n_67240:229.32,225.40' "$WORK/innovus/geometry_repair_clean/reports/operator_gate_route_geometry_repair.rpt"
grep -Fqx 'REPAIR_MIN_AREA_PATCH_POLICY=u_core_n_57563:MET1:364.84,328.44->365.40,328.44:width=0.28' "$WORK/innovus/geometry_repair_clean/reports/operator_gate_route_geometry_repair.rpt"
grep -qx 'PG_EDIT_POLICY=NO_PG_SHAPES_MODIFIED' "$WORK/innovus/geometry_repair_clean/reports/operator_gate_route_geometry_repair.rpt"
grep -qx 'PLACEMENT_EDIT_POLICY=NO_INSTANCES_MOVED' "$WORK/innovus/geometry_repair_clean/reports/operator_gate_route_geometry_repair.rpt"
grep -qx 'FINAL_DRC=0' "$WORK/innovus/geometry_repair_clean/reports/operator_gate_route_geometry_repair.rpt"
grep -qx 'FINAL_SHORTS=0' "$WORK/innovus/geometry_repair_clean/reports/operator_gate_route_geometry_repair.rpt"
grep -qx 'FINAL_REGULAR_CONNECTIVITY_BAD=0' "$WORK/innovus/geometry_repair_clean/reports/operator_gate_route_geometry_repair.rpt"
grep -qx 'FINAL_SPECIAL_DANGLING_COUNT=12' "$WORK/innovus/geometry_repair_clean/reports/operator_gate_route_geometry_repair.rpt"
grep -qx 'GEOMETRY_REPAIR_GATE_MODE=GEOMETRY_REGULAR_CLEAN_PG_DANGLING_REVIEW' "$WORK/innovus/geometry_repair_clean/reports/operator_gate_route_geometry_repair.rpt"
grep -qx 'DECISION=PASS_CONTINUE' "$WORK/innovus/geometry_repair_clean/reports/operator_gate_route_geometry_repair.rpt"
grep -q 'innovus geometry_repair_clean .* ROUTE_GEOMETRY_REPAIR' "$PUBLISH_CALLS"
grep -qx 'NEXT_STAGE=PG_DANGLING_REPAIR_REVIEW' "$TMP_ROOT/geometry_repair_clean.stdout"
grep -qx 'NEXT_REQUIRED_REPAIR_RUN_ID=geometry_repair_clean' "$TMP_ROOT/geometry_repair_clean.stdout"

set +e
env "${COMMON_ENV[@]}" FAKE_REPAIR_DIRTY=1 bash "$DRIVER" \
  --stage route-geometry-repair --run-id geometry_repair_dirty \
  --source-pnr-run-id "$SOURCE_PNR_ID" --expected-head "$HEAD_SHA" \
  > "$TMP_ROOT/geometry_repair_dirty.stdout"
GEOMETRY_REPAIR_DIRTY_RC=$?
set -e
test "$GEOMETRY_REPAIR_DIRTY_RC" -ne 0
grep -qx 'FINAL_DRC=1' "$WORK/innovus/geometry_repair_dirty/reports/operator_gate_route_geometry_repair.rpt"
grep -qx 'GEOMETRY_REPAIR_GATE_MODE=FAIL' "$WORK/innovus/geometry_repair_dirty/reports/operator_gate_route_geometry_repair.rpt"
grep -qx 'DECISION=FAIL_STOP' "$WORK/innovus/geometry_repair_dirty/reports/operator_gate_route_geometry_repair.rpt"
grep -q 'innovus geometry_repair_dirty .* ROUTE_GEOMETRY_REPAIR' "$PUBLISH_CALLS"
grep -qx 'NEXT_STAGE=STOP_AND_REVIEW_PUBLISHED_EVIDENCE' "$TMP_ROOT/geometry_repair_dirty.stdout"

echo "MPTDC_RO6_RECOVERY_STAGE_DRIVER_TEST=PASS"
