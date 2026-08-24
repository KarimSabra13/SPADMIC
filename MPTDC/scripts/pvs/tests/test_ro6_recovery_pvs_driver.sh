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
router_command_top_layer=MET3
IO_PIN_PLACEMENT_STATUS=OK
ro_slow_tap0_o_SOUTH_MET3_PLAN_COUNT=1
ro_fast_tap0_o_SOUTH_MET3_PLAN_COUNT=1
ro_slow_tap0_o_COUNT=1
ro_fast_tap0_o_COUNT=1
RO_TAP_OBSERVABILITY_PIN_COUNT=2
DECISION=PASS_CONTINUE
EOF
git -C "$REPO" add MPTDC
git -C "$REPO" commit -q -m fixtures
HEAD_SHA="$(git -C "$REPO" rev-parse HEAD)"

FAKE_PREP="$TMP_ROOT/fake_prep.sh"
cat > "$FAKE_PREP" <<'EOF'
#!/usr/bin/env bash
set -eu
run_id=""; work=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-id) run_id="$2"; shift 2 ;;
    --innovus-work) work="$2"; shift 2 ;;
    *) shift ;;
  esac
done
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
  shift 2
  env \
    MPTDC_RECOVERY_REPO_ROOT="$REPO" \
    MPTDC_RECOVERY_PUBLISHER="$FAKE_PUBLISHER" \
    MPTDC_RECOVERY_PVS_PREP="$FAKE_PREP" \
    MPTDC_RECOVERY_PVS_AUDIT="$FAKE_AUDIT" \
    MPTDC_RECOVERY_PVS_DRC="$FAKE_DRC" \
    MPTDC_RECOVERY_PVS_LVS="$FAKE_LVS" \
    MPTDC_CADENCE_ENV="$TMP_ROOT/no-cadence-env" \
    MPTDC_INNOVUS_WORK="$WORK" \
    PUBLISH_CALLS="$calls" \
    "$@" \
    bash "$DRIVER" --pnr-run-id "$PNR_RUN" --run-id "$pvs_run" \
      --expected-head "$HEAD_SHA" --ro-gds "$RO_GDS"
}

PASS_CALLS="$TMP_ROOT/pass.calls"
run_driver pvs_pass "$PASS_CALLS" > "$TMP_ROOT/pass.stdout"
test "$(wc -l < "$PASS_CALLS")" -eq 5
grep -qx 'DECISION=PASS_CONTINUE' "$WORK/pvs_pass/reports/operator_gate_pvs_lvs.rpt"
grep -qx 'PVS_RECOVERY_STATUS=PASS' "$TMP_ROOT/pass.stdout"

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

echo "MPTDC_RO6_RECOVERY_PVS_DRIVER_TEST=PASS"
