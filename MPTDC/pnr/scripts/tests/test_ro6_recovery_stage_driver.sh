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
mkdir -p "$REPO" "$HANDOFF" "$WORK/innovus"
git init -q -b SPADMIC_test "$REPO"
git -C "$REPO" config user.name 'MPTDC recovery test'
git -C "$REPO" config user.email 'mptdc-recovery@example.invalid'

PRE_GATE="$REPO/MPTDC/docs/server_snapshots/genus/genus_fixture_prepnr_20260824_120000/reports/operator_gate_pre_pnr.rpt"
PG_GATE="$REPO/MPTDC/docs/server_snapshots/innovus/pg_prior/reports/operator_gate_pg_proof.rpt"
FAILED_PG_GATE="$REPO/MPTDC/docs/server_snapshots/innovus/pg_failed/reports/operator_gate_pg_proof.rpt"
mkdir -p \
  "$(dirname "$PRE_GATE")" \
  "$(dirname "$PG_GATE")" \
  "$(dirname "$FAILED_PG_GATE")" \
  "$WORK/innovus/pg_failed/checkpoints/03_cts.enc.dat"
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
while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-id) run_id="$2"; shift 2 ;;
    --stage) stage="$2"; shift 2 ;;
    --innovus-work) work="$2"; shift 2 ;;
    --strict-special-clean) strict_special_clean=1; shift ;;
    --dangling-only-max) dangling_only_max="$2"; shift 2 ;;
    *) shift ;;
  esac
done
test "$strict_special_clean" = 0
test "$dangling_only_max" = 34
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
shorts=0
tool_rc=0
if [[ "${FAKE_DIRTY_ROUTE:-0}" == 1 ]]; then shorts=1; tool_rc=1; fi
cat > "$run/reports/route_status.rpt" <<RPT
ROUTE_STATUS=$([[ "$shorts" == 0 ]] && echo PASS || echo FAIL)
INNOVUS_VERIFY_DRC_STATUS=$([[ "$shorts" == 0 ]] && echo PASS || echo FAIL)
GEOMETRY_DRC_VIOLATIONS=$shorts
SHORTS=$shorts
REGULAR_NET_CONNECTIVITY_BAD=0
SPECIAL_NET_CONNECTIVITY_BAD=0
SPECIAL_NET_CONNECTIVITY_RAW_BAD=0
SPECIAL_NET_CONNECTIVITY_NON_RO_FAILURES=0
UNROUTED_NETS=0
RPT
printf 'router_command_top_layer=MET3\n' > "$run/reports/route_layer_intent.rpt"
printf 'REPORT_STATUS=OK\n' > "$run/reports/io_pin_placement_summary.md"
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
  MPTDC_RECOVERY_PUBLISHER="$FAKE_PUBLISHER"
  MPTDC_CADENCE_ENV="$FAKE_CADENCE_ENV"
  MPTDC_WORK_ROOT="$WORK"
  MPTDC_INNOVUS_WORK="$WORK/innovus"
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

env "${COMMON_ENV[@]}" bash "$DRIVER" \
  --stage physical-pnr --run-id route_fixture --pg-run-id pg_prior \
  --expected-head "$HEAD_SHA" --genus-run-id genus_fixture --handoff-dir "$HANDOFF" \
  > "$TMP_ROOT/route.stdout"
grep -qx 'DECISION=PASS_CONTINUE' "$WORK/innovus/route_fixture/reports/operator_gate_physical_pnr.rpt"
grep -qx 'RO_TAP_OBSERVABILITY_PIN_COUNT=2' "$WORK/innovus/route_fixture/reports/tap_pin_def_excerpt.rpt"

set +e
env "${COMMON_ENV[@]}" FAKE_DIRTY_ROUTE=1 bash "$DRIVER" \
  --stage physical-pnr --run-id route_dirty --pg-run-id pg_prior \
  --expected-head "$HEAD_SHA" --genus-run-id genus_fixture --handoff-dir "$HANDOFF" \
  > "$TMP_ROOT/route_dirty.stdout"
DIRTY_RC=$?
set -e
test "$DIRTY_RC" -ne 0
grep -qx 'DECISION=FAIL_STOP' "$WORK/innovus/route_dirty/reports/operator_gate_physical_pnr.rpt"
grep -q 'innovus route_dirty .* PHYSICAL_PNR' "$PUBLISH_CALLS"

echo "MPTDC_RO6_RECOVERY_STAGE_DRIVER_TEST=PASS"
