#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_ROOT="$(mktemp -d /tmp/mptdc_ro6_pg_endpoint_probe.XXXXXX)"
trap 'rm -rf "$TMP_ROOT"' EXIT

REPO="$TMP_ROOT/repo"
WORK="$TMP_ROOT/work"
SOURCE_ID=source_v6r
BOUNDARY_ID=boundary_pg_only
DRIVER="$REPO/MPTDC/pnr/scripts/server_run_mptdc_ro6_pg_endpoint_probe.sh"
LAUNCHER="$TMP_ROOT/probe_launcher_stub.sh"
PUBLISHER="$TMP_ROOT/publisher_stub.sh"

mkdir -p "$REPO/MPTDC/pnr/scripts" \
  "$WORK/$SOURCE_ID/checkpoints/repaired_route.enc.dat" \
  "$WORK/$BOUNDARY_ID/reports"
cp -p "$PNR_DIR/server_run_mptdc_ro6_pg_endpoint_probe.sh" "$DRIVER"
printf 'checkpoint fixture\n' > "$WORK/$SOURCE_ID/checkpoints/repaired_route.enc.dat/design.bin"
cat > "$WORK/$BOUNDARY_ID/reports/operator_gate_pvs_ro6_boundary_lvs.rpt" <<'EOF'
PVS_LVS_STATUS=MISMATCH
LAYOUT_OPEN_NET_COUNT=4
MISMATCHED_NET_RECORD_COUNT=0
MISMATCHED_INSTANCE_RECORD_COUNT=0
BOUNDARY_REMAINDER_CLASS=RO6_PG_OPEN_ONLY
DECISION=PASS_PG_REPAIR_REQUIRED
EOF

cat > "$LAUNCHER" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
run_id=""
work=""
mode=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-id) run_id="$2"; shift 2 ;;
    --innovus-work) work="$2"; shift 2 ;;
    --mode) mode="$2"; shift 2 ;;
    --checkpoint|--expected-head) shift 2 ;;
    *) echo "unexpected option: $1" >&2; exit 8 ;;
  esac
done
[[ "$mode" == analyze ]]
mkdir -p "$work/$run_id/reports"
ambiguous="${MPTDC_TEST_PROBE_AMBIGUOUS:-0}"
blocked=$((15 - ambiguous))
cat > "$work/$run_id/reports/pg_dangling_analysis_status.rpt" <<RPT
PG_DANGLING_MODE=analyze
MARKER_COUNT=15
PG_DANGLING_DELETE_ATTEMPTS=0
PG_DANGLING_DELETE_SUCCESSES=0
PG_DANGLING_BLOCKED_COUNT=$blocked
PG_DANGLING_AMBIGUOUS_COUNT=$ambiguous
PG_DANGLING_MISSING_EXACT_COUNT=0
FINAL_DANGLING_MARKER_COUNT=15
PG_DANGLING_STATUS=ANALYSIS_ONLY
RPT
cat > "$work/$run_id/reports/checkpoint_repair_status.rpt" <<'RPT'
INITIAL_DRC=1
INITIAL_SHORTS=0
INITIAL_REGULAR_CONNECTIVITY_BAD=0
FINAL_DRC=1
FINAL_SHORTS=0
FINAL_REGULAR_CONNECTIVITY_BAD=0
RPT
exit 0
EOF

cat > "$PUBLISHER" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" > "${MPTDC_TEST_PUBLISH_ARGS:?}"
exit 0
EOF
chmod +x "$LAUNCHER" "$PUBLISHER"

git init -q -b SPADMIC_test "$REPO"
git -C "$REPO" config user.name 'MPTDC RO6 PG probe test'
git -C "$REPO" config user.email 'mptdc-ro6-pg-probe@example.invalid'
git -C "$REPO" add MPTDC
git -C "$REPO" commit -q -m fixtures
HEAD_SHA="$(git -C "$REPO" rev-parse HEAD)"

RUN_ID=pg_endpoint_probe_pass
MPTDC_PG_PROBE_REPO_ROOT="$REPO" \
MPTDC_PG_PROBE_LAUNCHER="$LAUNCHER" \
MPTDC_PG_PROBE_PUBLISHER="$PUBLISHER" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/publish.args" \
bash "$DRIVER" \
  --source-pnr-run-id "$SOURCE_ID" \
  --boundary-pvs-run-id "$BOUNDARY_ID" \
  --run-id "$RUN_ID" \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/pass.stdout"

grep -qx 'RO6_PG_ENDPOINT_PROBE_STATUS=PASS' "$TMP_ROOT/pass.stdout"
grep -qx 'MARKER_COUNT=15' "$TMP_ROOT/pass.stdout"
grep -qx 'AMBIGUOUS_COUNT=0' "$TMP_ROOT/pass.stdout"
grep -qx 'MISSING_EXACT_COUNT=0' "$TMP_ROOT/pass.stdout"
grep -qx 'DECISION=PASS_REVIEW_ENDPOINTS' "$TMP_ROOT/pass.stdout"
grep -qx 'NEXT_STAGE=DESIGN_EXACT_RO6_PG_PATCH_FROM_PUBLISHED_PROBE' "$TMP_ROOT/pass.stdout"
grep -q "innovus $RUN_ID $WORK/$RUN_ID RO6_PG_ENDPOINT_PROBE" "$TMP_ROOT/publish.args"
grep -qx 'PG_EDIT_COUNT=0' "$WORK/$RUN_ID/reports/operator_gate_ro6_pg_endpoint_probe.rpt"

set +e
MPTDC_TEST_PROBE_AMBIGUOUS=1 \
MPTDC_PG_PROBE_REPO_ROOT="$REPO" \
MPTDC_PG_PROBE_LAUNCHER="$LAUNCHER" \
MPTDC_PG_PROBE_PUBLISHER="$PUBLISHER" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/ambiguous.publish.args" \
bash "$DRIVER" \
  --source-pnr-run-id "$SOURCE_ID" \
  --boundary-pvs-run-id "$BOUNDARY_ID" \
  --run-id pg_endpoint_probe_ambiguous \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/ambiguous.stdout" 2>&1
AMBIGUOUS_RC=$?
set -e
test "$AMBIGUOUS_RC" -ne 0
grep -qx 'AMBIGUOUS_COUNT=1' "$TMP_ROOT/ambiguous.stdout"
grep -qx 'DECISION=FAIL_STOP' "$TMP_ROOT/ambiguous.stdout"

echo "MPTDC_RO6_PG_ENDPOINT_PROBE_DRIVER_TEST=PASS"
