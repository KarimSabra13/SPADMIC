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
mkdir -p "$(dirname "$PRE_GATE")" "$(dirname "$PG_GATE")"
cat > "$PRE_GATE" <<'EOF'
STEP=PRE_PNR
PACKAGE_RC=0
PRE_PNR_RC=0
PRE_PNR_GATE=PASS
DECISION=PASS_CONTINUE
EOF
cat > "$PG_GATE" <<'EOF'
STEP=STRICT_PG_PROOF
PG_RC=0
POSTPLACE_PRE_ROUTE_SROUTE_STATUS=PASS
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_BAD=0
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_RAW_BAD=0
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_NON_RO_FAILURES=0
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

FAKE_LAUNCHER="$TMP_ROOT/fake_launcher.sh"
cat > "$FAKE_LAUNCHER" <<'EOF'
#!/usr/bin/env bash
set -eu
test "${MPTDC_CADENCE_FIXTURE_LOADED:-0}" = 1
run_id=""
stage=""
work=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-id) run_id="$2"; shift 2 ;;
    --stage) stage="$2"; shift 2 ;;
    --innovus-work) work="$2"; shift 2 ;;
    *) shift ;;
  esac
done
run="$work/$run_id"
mkdir -p "$run/reports" "$run/def" "$run/checkpoints/04_route.enc.dat"
if [[ "$stage" == pg_proof ]]; then
  cat > "$run/reports/postplace_pre_route_sroute_status.rpt" <<'RPT'
POSTPLACE_PRE_ROUTE_SROUTE_STATUS=PASS
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_BAD=0
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_RAW_BAD=0
POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_NON_RO_FAILURES=0
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
grep -q 'innovus pg_fixture .* STRICT_PG_PROOF' "$PUBLISH_CALLS"

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
