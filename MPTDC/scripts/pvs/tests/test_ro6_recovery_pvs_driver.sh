#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRIVER="$(cd "$SCRIPT_DIR/.." && pwd)/server_run_mptdc_ro6_recovery_pvs.sh"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

REPO="$TMP_ROOT/repo"
WORK="$TMP_ROOT/work/innovus"
PNR_RUN=physical_fixture
PNR_DIR="$WORK/$PNR_RUN"
RO_GDS="$TMP_ROOT/RO_tune6_from_OA.gds"
mkdir -p "$REPO" "$PNR_DIR/checkpoints/04_route.enc.dat"
printf 'real ro fixture\n' > "$RO_GDS"
git init -q -b SPADMIC_test "$REPO"
git -C "$REPO" config user.name 'MPTDC PVS recovery test'
git -C "$REPO" config user.email 'mptdc-pvs-recovery@example.invalid'

PHYSICAL_GATE="$REPO/MPTDC/docs/server_snapshots/innovus/$PNR_RUN/reports/operator_gate_physical_pnr.rpt"
mkdir -p "$(dirname "$PHYSICAL_GATE")"
cat > "$PHYSICAL_GATE" <<'EOF'
STEP=PHYSICAL_PNR
PNR_RC=0
ROUTE_STATUS=PASS
INNOVUS_VERIFY_DRC_STATUS=PASS
GEOMETRY_DRC_VIOLATIONS=0
SHORTS=0
REGULAR_NET_CONNECTIVITY_BAD=0
SPECIAL_NET_CONNECTIVITY_BAD=0
SPECIAL_NET_CONNECTIVITY_RAW_BAD=0
SPECIAL_NET_CONNECTIVITY_NON_RO_FAILURES=0
UNROUTED_NETS=0
signal_top_layer=MET3
router_command_top_layer=METTP
ROUTE_COMMAND_STATUS=PASS
SIGNAL_TOP_ROUTE_BLOCKAGE_TEMPORARY=1
SIGNAL_TOP_ROUTE_BLOCKAGE_CREATE_STATUS=PASS
SIGNAL_TOP_ROUTE_BLOCKAGE_REMOVE_STATUS=PASS
SIGNAL_TOP_ROUTE_BLOCKAGE_STATUS=REMOVED
PRE_ROUTE_SROUTE_STATUS=PASS
PRE_ROUTE_DANGLING_MAX=35
PRE_ROUTE_DANGLING_FATAL_COUNT=0
PRE_ROUTE_PG_CROSS_NET_SHORT_COUNT=0
PNR_LEF_SUMMARY_BINDING_STATUS=PASS
PNR_LEF_PATH_MATCH_STATUS=PASS
PNR_LEF_EVIDENCE_STATUS=PASS
PNR_LEF_REQUESTED_SHA256=fixture_hash
PNR_LEF_ACTUAL_SHA256=fixture_hash
PNR_LEF_EXPECTED_SHA256=fixture_hash
PNR_LEF_GATE_STATUS=PASS
RO_HALOS_REQUESTED=1
RO_HALO_ENABLED=1
RO_HALO_STATUS=PASS
RO_HALO_COUNT=2
RO_HALO_CLEARANCE_UM=10.0
SLOW_HALO_STATUS=PASS
FAST_HALO_STATUS=PASS
RO_HALO_OCCUPANCY_STATUS=PASS
RO_HALO_TOTAL_INTRUSION_COUNT=0
RO_HALO_INVALID_INSTANCE_BBOX_COUNT=0
RO_HALO_AUDITED_RO_COUNT=2
RO_PHASE_PLACEMENT_STATUS=PASS
RO_PHASE_MIN_CLEARANCE_UM=17.42
EXTRACTION_STATUS=PASS
SETUP_STATUS_TC=PASS
TC_HOLD_STATUS=PASS
DRV_STATUS=PASS
POWER_REPORT_CAPTURE_STATUS=PASS
IO_PIN_PLACEMENT_STATUS=OK
ro_slow_tap0_o_SOUTH_MET3_PLAN_COUNT=1
ro_fast_tap0_o_SOUTH_MET3_PLAN_COUNT=1
ro_slow_tap0_o_COUNT=1
ro_fast_tap0_o_COUNT=1
RO_TAP_OBSERVABILITY_PIN_COUNT=2
COMMON_PHYSICAL_GATE=1
PHYSICAL_GATE_MODE=STRICT_CLEAN
DECISION=PASS_CONTINUE
EOF
git -C "$REPO" add MPTDC
git -C "$REPO" commit -q -m fixtures
HEAD_SHA="$(git -C "$REPO" rev-parse HEAD)"

FAKE_CADENCE_ENV="$TMP_ROOT/fake_cadence_env.sh"
cat > "$FAKE_CADENCE_ENV" <<'EOF'
: "$MPTDC_CADENCE_FIXTURE_UNSET"
export MPTDC_CADENCE_FIXTURE_LOADED=1
EOF
FAILING_CADENCE_ENV="$TMP_ROOT/failing_cadence_env.sh"
printf 'return 23\n' > "$FAILING_CADENCE_ENV"

FAKE_PREP="$TMP_ROOT/fake_prep.sh"
cat > "$FAKE_PREP" <<'EOF'
#!/usr/bin/env bash
set -eu
test "${MPTDC_CADENCE_FIXTURE_LOADED:-0}" = 1
run_id=""; work=""; checkpoint=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-id) run_id="$2"; shift 2 ;;
    --innovus-work) work="$2"; shift 2 ;;
    --checkpoint) checkpoint="$2"; shift 2 ;;
    *) shift ;;
  esac
done
test -d "$checkpoint"
if [[ -n "${EXPECTED_PREP_CHECKPOINT:-}" ]]; then
  test "$checkpoint" = "$EXPECTED_PREP_CHECKPOINT"
fi
dir="$work/$run_id"
mkdir -p "$dir/reports" "$dir/manifests" "$dir/logs"
printf 'PVS_PREP_INPUT_STATUS=PASS\n' > "$dir/reports/pvs_prepared_inputs.rpt"
printf 'TAP_PIN_CONTRACT_STATUS=PASS\nRO_TAP_OBSERVABILITY_PIN_COUNT=2\n' > "$dir/reports/tap_pin_contract.rpt"
printf 'STRICT_ATTRIBUTION=1\nMERGED_GDS_SHA256=fixture\n' > "$dir/manifests/pvs_input_hashes.rpt"
EOF

FAKE_AUDIT="$TMP_ROOT/fake_audit.sh"
cat > "$FAKE_AUDIT" <<'EOF'
#!/usr/bin/env bash
set -eu
dir=""
while [[ $# -gt 0 ]]; do
  case "$1" in --result-dir) dir="$2"; shift 2 ;; *) shift ;; esac
done
printf 'PVS_TEMPLATE_AUDIT_STATUS=PASS\n' > "$dir/manifests/pvs_template_audit.status"
EOF

FAKE_DRC="$TMP_ROOT/fake_drc.sh"
cat > "$FAKE_DRC" <<'EOF'
#!/usr/bin/env bash
set -eu
dir=""; variant=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --prepared-dir) dir="$2"; shift 2 ;;
    --variant) variant="$2"; shift 2 ;;
    *) shift ;;
  esac
done
status=PASS; total=0; rc=0
if [[ "${FAKE_DRC_FAIL_VARIANT:-}" == "$variant" ]]; then status=FAIL; total=1; rc=8; fi
cat > "$dir/reports/pvs_drc_${variant}_status.rpt" <<RPT
STATUS=$status
PVS_DRC_STATUS=$status
PVS_DRC_VARIANT=${variant^^}
DRC_TOTAL_PRIMARY=$total
DRC_TOTAL_EXPANDED=$total
RPT
exit "$rc"
EOF

FAKE_LVS="$TMP_ROOT/fake_lvs.sh"
cat > "$FAKE_LVS" <<'EOF'
#!/usr/bin/env bash
set -eu
dir=""
while [[ $# -gt 0 ]]; do
  case "$1" in --prepared-dir) dir="$2"; shift 2 ;; *) shift ;; esac
done
printf 'STATUS=PASS\nPVS_LVS_STATUS=MATCH\nPVS_RC=0\n' > "$dir/reports/pvs_lvs_status.rpt"
EOF

FAKE_PUBLISHER="$TMP_ROOT/fake_publisher.sh"
cat > "$FAKE_PUBLISHER" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$PUBLISH_CALLS"
echo 'EVIDENCE_PUSH_RC=0'
EOF
chmod +x "$FAKE_PREP" "$FAKE_AUDIT" "$FAKE_DRC" "$FAKE_LVS" "$FAKE_PUBLISHER"

run_driver() {
  local pvs_run="$1"
  local calls="$2"
  local pnr_run="$PNR_RUN"
  shift 2
  if [[ "${1:-}" == --test-pnr-run ]]; then
    pnr_run="$2"
    shift 2
  fi
  env \
    MPTDC_RECOVERY_REPO_ROOT="$REPO" \
    MPTDC_RECOVERY_PUBLISHER="$FAKE_PUBLISHER" \
    MPTDC_RECOVERY_PVS_PREP="$FAKE_PREP" \
    MPTDC_RECOVERY_PVS_AUDIT="$FAKE_AUDIT" \
    MPTDC_RECOVERY_PVS_DRC="$FAKE_DRC" \
    MPTDC_RECOVERY_PVS_LVS="$FAKE_LVS" \
    MPTDC_CADENCE_ENV="$FAKE_CADENCE_ENV" \
    MPTDC_INNOVUS_WORK="$WORK" \
    PUBLISH_CALLS="$calls" \
    "$@" \
    bash "$DRIVER" --pnr-run-id "$pnr_run" --run-id "$pvs_run" \
      --expected-head "$HEAD_SHA" --ro-gds "$RO_GDS"
}

write_exact_pg_wire_end_report() {
  local report="$1"
  cat > "$report" <<'EOF'
Net VDD: dangling Wire at (221.750, 681.160) (221.750, 681.160) on layer: MET3
Net VDD: dangling Wire at (48.000, 681.160) (48.000, 681.160) on layer: MET3
Net VDD: dangling Wire at (221.750, 201.160) (221.750, 201.160) on layer: MET3
Net VDD: dangling Wire at (48.000, 201.160) (48.000, 201.160) on layer: MET3
Net VDD: dangling Wire at (121.160, 233.620) (121.160, 233.620) on layer: METTP
Net VDD: dangling Wire at (121.160, 648.320) (121.160, 648.320) on layer: METTP
Net VSS: dangling Wire at (221.750, 685.160) (221.750, 685.160) on layer: MET3
Net VSS: dangling Wire at (48.000, 685.160) (48.000, 685.160) on layer: MET3
Net VSS: dangling Wire at (221.750, 205.160) (221.750, 205.160) on layer: MET3
Net VSS: dangling Wire at (48.000, 205.160) (48.000, 205.160) on layer: MET3
Net VSS: dangling Wire at (205.160, 158.320) (205.160, 158.320) on layer: METTP
Net VSS: dangling Wire at (125.160, 721.750) (125.160, 721.750) on layer: METTP
Net VSS: dangling Wire at (125.160, 648.320) (125.160, 648.320) on layer: METTP
Net VSS: dangling Wire at (125.160, 233.620) (125.160, 233.620) on layer: METTP
Net VSS: dangling Wire at (125.160, 158.320) (125.160, 158.320) on layer: METTP
    15 Problem(s) (IMPVFC-94): The net has dangling wire(s).
EOF
}

PASS_CALLS="$TMP_ROOT/pass.calls"
run_driver pvs_pass "$PASS_CALLS" > "$TMP_ROOT/pass.stdout"
grep -qx 'CADENCE_ENV_STATUS=PASS' "$TMP_ROOT/pass.stdout"
test "$(wc -l < "$PASS_CALLS")" -eq 5
grep -qx 'DECISION=PASS_CONTINUE' "$WORK/pvs_pass/reports/operator_gate_pvs_lvs.rpt"
grep -qx 'PVS_RECOVERY_STATUS=PASS' "$TMP_ROOT/pass.stdout"
grep -qx 'MPTDC_TC_PVS_CLOSED=YES' "$TMP_ROOT/pass.stdout"
grep -qx 'FINAL_DECISION=MPTDC_TC_PVS_CLOSED_NOT_MMMC_SIGNOFF' "$TMP_ROOT/pass.stdout"
grep -qx 'NOT_MMMC_SIGNOFF=YES' "$TMP_ROOT/pass.stdout"
grep -qx 'FINAL_SIGNOFF=NO' "$TMP_ROOT/pass.stdout"

ENV_FAIL_CALLS="$TMP_ROOT/env_fail.calls"
set +e
run_driver pvs_env_fail "$ENV_FAIL_CALLS" \
  MPTDC_CADENCE_ENV="$FAILING_CADENCE_ENV" > "$TMP_ROOT/env_fail.stdout"
ENV_FAIL_RC=$?
set -e
test "$ENV_FAIL_RC" -eq 5
grep -qx 'CADENCE_ENV_RC=23' "$TMP_ROOT/env_fail.stdout"
grep -qx 'CADENCE_ENV_STATUS=FAIL' "$TMP_ROOT/env_fail.stdout"
grep -qx 'DECISION=FAIL_STOP' "$TMP_ROOT/env_fail.stdout"
test ! -e "$WORK/pvs_env_fail"
test ! -e "$ENV_FAIL_CALLS"

FAIL_CALLS="$TMP_ROOT/fail.calls"
set +e
run_driver pvs_fail "$FAIL_CALLS" FAKE_DRC_FAIL_VARIANT=base > "$TMP_ROOT/fail.stdout"
FAIL_RC=$?
set -e
test "$FAIL_RC" -ne 0
test "$(wc -l < "$FAIL_CALLS")" -eq 3
grep -qx 'DECISION=FAIL_STOP' "$WORK/pvs_fail/reports/operator_gate_pvs_drc_base.rpt"
test ! -e "$WORK/pvs_fail/reports/operator_gate_pvs_drc_density.rpt"
test ! -e "$WORK/pvs_fail/reports/operator_gate_pvs_lvs.rpt"

sed -i \
  -e 's/^ROUTE_STATUS=PASS$/ROUTE_STATUS=PVS_CANDIDATE/' \
  -e 's/^SPECIAL_NET_CONNECTIVITY_BAD=0$/SPECIAL_NET_CONNECTIVITY_BAD=1/' \
  -e 's/^SPECIAL_NET_CONNECTIVITY_RAW_BAD=0$/SPECIAL_NET_CONNECTIVITY_RAW_BAD=1/' \
  -e 's/^PHYSICAL_GATE_MODE=STRICT_CLEAN$/PHYSICAL_GATE_MODE=PVS_CANDIDATE_EXACT_PG_WIRE_ENDS/' \
  -e 's/^DECISION=PASS_CONTINUE$/DECISION=PVS_CANDIDATE_CONTINUE/' \
  "$PHYSICAL_GATE"
cat >> "$PHYSICAL_GATE" <<'EOF'
ALLOW_EXACT_PG_PVS_CANDIDATE=1
ROUTE_PG_PVS_CANDIDATE_STATUS=PASS
ROUTE_PG_PVS_CANDIDATE_EXACT_MATCH=1
EOF
cat > "$(dirname "$PHYSICAL_GATE")/route_pg_pvs_candidate_status.rpt" <<'EOF'
ROUTE_PG_PVS_CANDIDATE_PROFILE=HALO10_PNRLEF_15
ROUTE_PG_PVS_CANDIDATE_EXPECTED_COUNT=15
ROUTE_PG_PVS_CANDIDATE_ACTUAL_COUNT=15
ROUTE_PG_PVS_CANDIDATE_SUMMARY_COUNT=15
ROUTE_PG_PVS_CANDIDATE_EXACT_MATCH=1
ROUTE_PG_PVS_CANDIDATE_OTHER_NET_LINE_COUNT=0
ROUTE_PG_PVS_CANDIDATE_OTHER_PROBLEM_LINE_COUNT=0
ROUTE_PG_PVS_CANDIDATE_STATUS=PASS
EOF
cat > "$(dirname "$PHYSICAL_GATE")/route_connectivity_special_detailed.rpt" <<'EOF'
Net VDD: dangling Wire at (221.750, 681.160) (221.750, 681.160) on layer: MET3
Net VDD: dangling Wire at (48.000, 681.160) (48.000, 681.160) on layer: MET3
Net VDD: dangling Wire at (221.750, 201.160) (221.750, 201.160) on layer: MET3
Net VDD: dangling Wire at (48.000, 201.160) (48.000, 201.160) on layer: MET3
Net VDD: dangling Wire at (121.160, 233.620) (121.160, 233.620) on layer: METTP
Net VDD: dangling Wire at (121.160, 648.320) (121.160, 648.320) on layer: METTP
Net VSS: dangling Wire at (221.750, 685.160) (221.750, 685.160) on layer: MET3
Net VSS: dangling Wire at (48.000, 685.160) (48.000, 685.160) on layer: MET3
Net VSS: dangling Wire at (221.750, 205.160) (221.750, 205.160) on layer: MET3
Net VSS: dangling Wire at (48.000, 205.160) (48.000, 205.160) on layer: MET3
Net VSS: dangling Wire at (205.160, 158.320) (205.160, 158.320) on layer: METTP
Net VSS: dangling Wire at (125.160, 721.750) (125.160, 721.750) on layer: METTP
Net VSS: dangling Wire at (125.160, 648.320) (125.160, 648.320) on layer: METTP
Net VSS: dangling Wire at (125.160, 233.620) (125.160, 233.620) on layer: METTP
Net VSS: dangling Wire at (125.160, 158.320) (125.160, 158.320) on layer: METTP
    15 Problem(s) (IMPVFC-94): The net has dangling wire(s).
EOF
git -C "$REPO" add MPTDC
git -C "$REPO" commit -q -m candidate-fixtures
HEAD_SHA="$(git -C "$REPO" rev-parse HEAD)"

CANDIDATE_CALLS="$TMP_ROOT/candidate.calls"
run_driver pvs_candidate "$CANDIDATE_CALLS" > "$TMP_ROOT/candidate.stdout"
grep -qx 'PVS_RECOVERY_STATUS=PASS' "$TMP_ROOT/candidate.stdout"
grep -qx 'MPTDC_TC_PVS_CLOSED=YES' "$TMP_ROOT/candidate.stdout"
test "$(wc -l < "$CANDIDATE_CALLS")" -eq 5

sed -i 's/(221.750, 681.160)/(221.751, 681.160)/g' \
  "$(dirname "$PHYSICAL_GATE")/route_connectivity_special_detailed.rpt"
git -C "$REPO" add MPTDC
git -C "$REPO" commit -q -m altered-candidate-fixture
HEAD_SHA="$(git -C "$REPO" rev-parse HEAD)"
ALTERED_CALLS="$TMP_ROOT/altered.calls"
set +e
run_driver pvs_altered_candidate "$ALTERED_CALLS" > "$TMP_ROOT/altered.stdout"
ALTERED_RC=$?
set -e
test "$ALTERED_RC" -eq 4
grep -qx 'PVS_RECOVERY_PREFLIGHT=FAIL' "$TMP_ROOT/altered.stdout"
grep -qx 'DECISION=FAIL_STOP' "$TMP_ROOT/altered.stdout"
test ! -e "$WORK/pvs_altered_candidate"
test ! -e "$ALTERED_CALLS"

MINAREA_SOURCE_RUN=minarea_source_fixture
MINAREA_TRIAL_RUN=minarea_patch_trial_fixture
MINAREA_REPLAY_RUN=minarea_replay_fixture
MINAREA_SOURCE_REPORTS="$REPO/MPTDC/docs/server_snapshots/innovus/$MINAREA_SOURCE_RUN/reports"
MINAREA_TRIAL_REPORTS="$REPO/MPTDC/docs/server_snapshots/innovus/$MINAREA_TRIAL_RUN/reports"
MINAREA_REPLAY_REPORTS="$REPO/MPTDC/docs/server_snapshots/innovus/$MINAREA_REPLAY_RUN/reports"
MINAREA_REPLAY_CKPT="$WORK/$MINAREA_REPLAY_RUN/checkpoints/repaired_route.enc.dat"
mkdir -p "$MINAREA_SOURCE_REPORTS" "$MINAREA_TRIAL_REPORTS" \
  "$MINAREA_REPLAY_REPORTS" "$MINAREA_REPLAY_CKPT"

cat > "$MINAREA_SOURCE_REPORTS/operator_gate_physical_pnr.rpt" <<'EOF'
STEP=PHYSICAL_PNR
PNR_RC=1
ROUTE_STATUS=FAIL
INNOVUS_VERIFY_DRC_STATUS=FAIL
GEOMETRY_DRC_VIOLATIONS=2
SHORTS=0
REGULAR_NET_CONNECTIVITY_BAD=0
SPECIAL_NET_CONNECTIVITY_BAD=1
SPECIAL_NET_CONNECTIVITY_RAW_BAD=1
SPECIAL_NET_CONNECTIVITY_NON_RO_FAILURES=0
RO_HALO_STATUS=PASS
RO_HALO_OCCUPANCY_STATUS=PASS
RO_HALO_TOTAL_INTRUSION_COUNT=0
ro_slow_tap0_o_COUNT=1
ro_fast_tap0_o_COUNT=1
RO_TAP_OBSERVABILITY_PIN_COUNT=2
DECISION=FAIL_STOP
EOF
cat > "$MINAREA_SOURCE_REPORTS/route_status.rpt" <<'EOF'
ROUTE_STATUS=FAIL
INNOVUS_VERIFY_DRC_STATUS=FAIL
GEOMETRY_DRC_VIOLATIONS=2
SHORTS=0
REGULAR_NET_CONNECTIVITY_BAD=0
SPECIAL_NET_CONNECTIVITY_BAD=1
SPECIAL_NET_CONNECTIVITY_RAW_BAD=1
SPECIAL_NET_CONNECTIVITY_NON_RO_FAILURES=0
ROUTE_GATE_FAILURE_CHECKPOINT_DAT_EXISTS=1
EOF
{
  printf 'idx\tmarker_handle\tbox\tlayer\ttype\tsubType\tmessage\n'
  printf '1\tm1\t{363.53 357.98 363.91 358.26}\tMET1\tGeometry\tMinimal_Area\tRegular Wire of Net u_core_n_57960 Actual: 0.10640000 Required: 0.20200000\n'
  printf '2\tm2\t{385.37 328.3 385.75 328.58}\tMET1\tGeometry\tMinimal_Area\tRegular Wire of Net u_core_n_57556 Actual: 0.10640000 Required: 0.20200000\n'
} > "$MINAREA_SOURCE_REPORTS/route_drc_markers.tsv"
write_exact_pg_wire_end_report "$MINAREA_SOURCE_REPORTS/route_connectivity_special_detailed.rpt"

cat > "$MINAREA_TRIAL_REPORTS/operator_gate_route_min_area_patch_trial.rpt" <<EOF
STEP=ROUTE_MIN_AREA_PATCH_TRIAL
SOURCE_PNR_RUN_ID=$MINAREA_SOURCE_RUN
SOURCE_PATCH_TRIAL_RUN_ID=NONE
REPAIR_RC=0
PATCH_STAGE_MODE=trial
REPAIR_METHOD=PROVEN_TWO_STUB_BASE_THEN_EXACT_MET1_PATCH_WIRE_V6
COMMAND_1_STATUS=PASS
COMMAND_2_STATUS=MISSING
MANUAL_ECO_STATUS=PASS
MANUAL_PRE_DRC=2
MANUAL_BASE_DRC=1
BASE_MINAREA_MARKER_STATUS=PASS
PATCH_EDIT_HELP_STATUS=PASS
PATCH_WIRE_SCHEMA_STATUS=PASS
PATCH_WIRE_STATUS=PASS
PATCH_WIRE_COUNT_DELTA=1
PATCH_WIRE_LAYER=MET1
PATCH_WIRE_WIDTH=0.23
PATCH_WIRE_DB_STATUS=fixed
PATCH_WIRE_BOX_STATUS=PASS
PATCH_UNRELATED_OBJECT_STATUS=PASS
POST_PATCH_MINAREA_MARKER_COUNT=0
FINAL_DRC=0
FINAL_SHORTS=0
FINAL_REGULAR_CONNECTIVITY_BAD=0
FINAL_SPECIAL_CONNECTIVITY_NON_RO_FAILURES=0
FINAL_SPECIAL_DANGLING_COUNT=15
FINAL_UNROUTED_NETS=0
FINAL_REPORT_ROUTE_ZERO_STATUS=PASS
FINAL_CHECKPOINT_DAT_EXISTS=1
SPECIAL_SIGNATURE_STATUS=PASS
TIMING_GATE_STATUS=NOT_RUN_PROOF_ONLY
RO_TAP_OBSERVABILITY_PIN_COUNT=2
PATCH_TRIAL_GATE_MODE=PASS_EXACT_PG_FINGERPRINT
DECISION=PASS_REPLAY
EOF
write_exact_pg_wire_end_report \
  "$MINAREA_TRIAL_REPORTS/01_after_command_verify_connectivity_special_detailed.rpt"

cat > "$MINAREA_REPLAY_REPORTS/operator_gate_route_min_area_repair.rpt" <<EOF
STEP=ROUTE_MIN_AREA_REPAIR
SOURCE_PNR_RUN_ID=$MINAREA_SOURCE_RUN
SOURCE_PATCH_TRIAL_RUN_ID=$MINAREA_TRIAL_RUN
REPAIR_RC=0
PATCH_STAGE_MODE=replay
REPAIR_METHOD=PROVEN_TWO_STUB_BASE_THEN_EXACT_MET1_PATCH_WIRE_V6
COMMAND_1_STATUS=PASS
COMMAND_2_STATUS=PASS
MANUAL_ECO_STATUS=PASS
MANUAL_PRE_DRC=2
MANUAL_BASE_DRC=1
BASE_MINAREA_MARKER_STATUS=PASS
PATCH_EDIT_HELP_STATUS=PASS
PATCH_WIRE_SCHEMA_STATUS=PASS
PATCH_WIRE_STATUS=PASS
PATCH_WIRE_COUNT_DELTA=1
PATCH_WIRE_LAYER=MET1
PATCH_WIRE_WIDTH=0.23
PATCH_WIRE_DB_STATUS=fixed
PATCH_WIRE_BOX_STATUS=PASS
PATCH_UNRELATED_OBJECT_STATUS=PASS
POST_PATCH_MINAREA_MARKER_COUNT=0
FINAL_DRC=0
FINAL_SHORTS=0
FINAL_REGULAR_CONNECTIVITY_BAD=0
FINAL_SPECIAL_CONNECTIVITY_BAD=1
FINAL_SPECIAL_CONNECTIVITY_RAW_BAD=1
FINAL_SPECIAL_CONNECTIVITY_NON_RO_FAILURES=0
FINAL_SPECIAL_DANGLING_COUNT=15
FINAL_UNROUTED_NETS=0
FINAL_REPORT_ROUTE_ZERO_STATUS=PASS
FINAL_ROUTE_GATE_PASS=0
CHECKPOINT_REPAIR_STATUS=PASS_GEOMETRY_REVIEW_CONNECTIVITY
FINAL_CHECKPOINT_DAT_EXISTS=1
SPECIAL_SIGNATURE_STATUS=PASS
SETUP_STATUS_TC=PASS
TC_HOLD_STATUS=PASS
DRV_STATUS=PASS
POWER_REPORT_CAPTURE_STATUS=PASS
TIMING_GATE_STATUS=PASS
ro_slow_tap0_o_COUNT=1
ro_fast_tap0_o_COUNT=1
RO_TAP_OBSERVABILITY_PIN_COUNT=2
MINAREA_REPAIR_GATE_MODE=PVS_CANDIDATE_EXACT_PG_WIRE_ENDS
DECISION=PVS_CANDIDATE_CONTINUE
EOF
write_exact_pg_wire_end_report \
  "$MINAREA_REPLAY_REPORTS/02_after_command_verify_connectivity_special_detailed.rpt"

git -C "$REPO" add MPTDC
git -C "$REPO" commit -q -m minarea-replay-fixtures
HEAD_SHA="$(git -C "$REPO" rev-parse HEAD)"

REPLAY_CALLS="$TMP_ROOT/replay.calls"
run_driver pvs_replay "$REPLAY_CALLS" --test-pnr-run "$MINAREA_REPLAY_RUN" \
  EXPECTED_PREP_CHECKPOINT="$MINAREA_REPLAY_CKPT" > "$TMP_ROOT/replay.stdout"
grep -qx 'PNR_CANDIDATE_KIND=MINAREA_V6_CANONICAL_REPLAY' "$TMP_ROOT/replay.stdout"
grep -qx 'CANDIDATE_GATE_STATUS=PASS' "$TMP_ROOT/replay.stdout"
grep -Fxqx "SOURCE_CKPT=$MINAREA_REPLAY_CKPT" "$TMP_ROOT/replay.stdout"
grep -qx 'PVS_RECOVERY_STATUS=PASS' "$TMP_ROOT/replay.stdout"
grep -qx 'MPTDC_TC_PVS_CLOSED=YES' "$TMP_ROOT/replay.stdout"
grep -qx 'PNR_CANDIDATE_KIND=MINAREA_V6_CANONICAL_REPLAY' \
  "$WORK/pvs_replay/reports/operator_gate_pvs_prepare.rpt"
grep -Fxqx "SOURCE_CHECKPOINT=$MINAREA_REPLAY_CKPT" \
  "$WORK/pvs_replay/reports/operator_gate_pvs_prepare.rpt"
test "$(wc -l < "$REPLAY_CALLS")" -eq 5

mv "$MINAREA_REPLAY_CKPT" "${MINAREA_REPLAY_CKPT}.saved"
MISSING_CKPT_CALLS="$TMP_ROOT/missing_replay_checkpoint.calls"
set +e
run_driver pvs_missing_replay_checkpoint "$MISSING_CKPT_CALLS" \
  --test-pnr-run "$MINAREA_REPLAY_RUN" > "$TMP_ROOT/missing_replay_checkpoint.stdout"
MISSING_CKPT_RC=$?
set -e
mv "${MINAREA_REPLAY_CKPT}.saved" "$MINAREA_REPLAY_CKPT"
test "$MISSING_CKPT_RC" -eq 4
grep -Fqx "STOP: accepted route checkpoint missing: $MINAREA_REPLAY_CKPT" \
  "$TMP_ROOT/missing_replay_checkpoint.stdout"
grep -qx 'DECISION=FAIL_STOP' "$TMP_ROOT/missing_replay_checkpoint.stdout"
test ! -e "$MISSING_CKPT_CALLS"

sed -i "s/^SOURCE_PATCH_TRIAL_RUN_ID=$MINAREA_TRIAL_RUN$/SOURCE_PATCH_TRIAL_RUN_ID=untracked_trial/" \
  "$MINAREA_REPLAY_REPORTS/operator_gate_route_min_area_repair.rpt"
git -C "$REPO" add MPTDC
git -C "$REPO" commit -q -m broken-minarea-replay-ancestry
HEAD_SHA="$(git -C "$REPO" rev-parse HEAD)"
BROKEN_ANCESTRY_CALLS="$TMP_ROOT/broken_ancestry.calls"
set +e
run_driver pvs_broken_ancestry "$BROKEN_ANCESTRY_CALLS" \
  --test-pnr-run "$MINAREA_REPLAY_RUN" > "$TMP_ROOT/broken_ancestry.stdout"
BROKEN_ANCESTRY_RC=$?
set -e
test "$BROKEN_ANCESTRY_RC" -eq 4
grep -qx 'CANDIDATE_GATE_STATUS=FAIL' "$TMP_ROOT/broken_ancestry.stdout"
grep -qx 'PVS_RECOVERY_PREFLIGHT=FAIL' "$TMP_ROOT/broken_ancestry.stdout"
grep -qx 'DECISION=FAIL_STOP' "$TMP_ROOT/broken_ancestry.stdout"
test ! -e "$BROKEN_ANCESTRY_CALLS"

echo "MPTDC_RO6_RECOVERY_PVS_DRIVER_TEST=PASS"
