#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PVS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_ROOT="$(mktemp -d /tmp/mptdc_ro6_boundary_lvs_driver.XXXXXX)"
trap 'rm -rf "$TMP_ROOT"' EXIT

REPO="$TMP_ROOT/repo"
WORK="$TMP_ROOT/work"
SOURCE_ID=source_pvs_mismatch
SOURCE_BASE="$WORK/$SOURCE_ID"
SOURCE_LVS="$SOURCE_BASE/pvs_lvs/source_lvs_script"
DRIVER="$REPO/MPTDC/scripts/pvs/server_run_mptdc_ro6_boundary_lvs.sh"
REPLAY="$TMP_ROOT/replay_stub.sh"
PUBLISHER="$TMP_ROOT/publisher_stub.sh"

mkdir -p "$REPO/MPTDC/scripts/pvs" "$SOURCE_LVS" "$SOURCE_BASE/outputs" \
  "$SOURCE_BASE/manifests" "$SOURCE_BASE/reports"
cp -p "$PVS_DIR/server_run_mptdc_ro6_boundary_lvs.sh" "$DRIVER"

printf 'merged gds\n' > "$SOURCE_BASE/outputs/mptdc_axis_core_merged_stdcell_ro6.gds"
cat > "$SOURCE_BASE/outputs/mptdc_axis_core_pnr_lvs_with_pg_NO_DCELL_MODULES_RO6_PINFIX_NOATTR_CLEAN.v" <<'EOF'
module mptdc_axis_core; endmodule
module RO_tune6 (VDD, VSS, rstb, code, S);
  inout VDD;
  inout VSS;
  inout rstb;
  inout [7:0] code;
  inout [7:0] S;
endmodule
EOF
printf 'RO_tune6 RO_tune6\n' > "$SOURCE_BASE/outputs/pvs_hcell_ro6.txt"
cat > "$SOURCE_BASE/manifests/pvs_input_hashes.rpt" <<EOF
STRICT_ATTRIBUTION=1
MERGED_GDS_PATH=$SOURCE_BASE/outputs/mptdc_axis_core_merged_stdcell_ro6.gds
MERGED_GDS_SHA256=$(sha256sum "$SOURCE_BASE/outputs/mptdc_axis_core_merged_stdcell_ro6.gds" | awk '{print $1}')
LVS_SOURCE_FILTERED_PATH=$SOURCE_BASE/outputs/mptdc_axis_core_pnr_lvs_with_pg_NO_DCELL_MODULES_RO6_PINFIX_NOATTR_CLEAN.v
LVS_SOURCE_FILTERED_SHA256=$(sha256sum "$SOURCE_BASE/outputs/mptdc_axis_core_pnr_lvs_with_pg_NO_DCELL_MODULES_RO6_PINFIX_NOATTR_CLEAN.v" | awk '{print $1}')
LVS_HCELL_PATH=$SOURCE_BASE/outputs/pvs_hcell_ro6.txt
LVS_HCELL_SHA256=$(sha256sum "$SOURCE_BASE/outputs/pvs_hcell_ro6.txt" | awk '{print $1}')
EOF
cat > "$SOURCE_BASE/reports/pvs_lvs_status.rpt" <<'EOF'
STATUS=FAIL
PVS_LVS_STATUS=MISMATCH
PVS_RC=0
EOF
printf '#!/bin/sh\n' > "$SOURCE_LVS/run.pvs"
cat > "$SOURCE_LVS/source.cls" <<'EOF'
Cells that have been blackboxed              |         0
 (-, RO_tune6())         |        *0 :        2 |        *0 :        2
EOF

cat > "$REPLAY" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
prepared=""
new_run=""
boundary=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --prepared-dir) prepared="$2"; shift 2 ;;
    --new-run-dir) new_run="$2"; shift 2 ;;
    --diagnostic-ro6-boundary-blackbox) boundary=1; shift ;;
    --template-run|--old-base|--old-gds|--old-source|--old-hcell|--expected-head) shift 2 ;;
    *) echo "unexpected replay option: $1" >&2; exit 8 ;;
  esac
done
[[ "$boundary" == 1 && -n "$prepared" && -n "$new_run" ]]
mkdir -p "$new_run" "$prepared/reports"
printf 'run\n' > "$new_run/run.pvs"
cat > "$prepared/reports/pvs_lvs_status.rpt" <<'RPT'
STATUS=PASS
PVS_LVS_STATUS=MATCH
PVS_RC=0
RPT
cat > "$prepared/reports/pvs_lvs_ro6_boundary_blackbox_status.rpt" <<'RPT'
LVS_BLACKBOX_RULE_STATUS=PASS
LVS_BLACKBOX_APPLICATION_STATUS=PASS
LVS_BLACKBOXED_CELL_COUNT=1
RO6_STANDALONE_LVS_REQUIRED=YES
SIGNOFF_ELIGIBLE=NO
RPT
EOF

cat > "$PUBLISHER" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" > "${MPTDC_TEST_PUBLISH_ARGS:?}"
exit 0
EOF
chmod +x "$REPLAY" "$PUBLISHER"

git init -q -b SPADMIC_test "$REPO"
git -C "$REPO" config user.name 'MPTDC RO6 boundary LVS test'
git -C "$REPO" config user.email 'mptdc-ro6-boundary@example.invalid'
git -C "$REPO" add MPTDC
git -C "$REPO" commit -q -m fixtures
HEAD_SHA="$(git -C "$REPO" rev-parse HEAD)"

RUN_ID=boundary_lvs_pass
MPTDC_BOUNDARY_LVS_REPO_ROOT="$REPO" \
MPTDC_BOUNDARY_LVS_REPLAY="$REPLAY" \
MPTDC_BOUNDARY_LVS_PUBLISHER="$PUBLISHER" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/publish.args" \
bash "$DRIVER" \
  --source-pvs-run-id "$SOURCE_ID" \
  --run-id "$RUN_ID" \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/pass.stdout"

grep -qx 'PVS_BOUNDARY_RECOVERY_STATUS=PASS' "$TMP_ROOT/pass.stdout"
grep -qx 'PVS_LVS=MATCH' "$TMP_ROOT/pass.stdout"
grep -qx 'DECISION=PASS_BOUNDARY_CONTINUE' "$TMP_ROOT/pass.stdout"
grep -qx 'PUBLISH_RC=0' "$TMP_ROOT/pass.stdout"
grep -qx 'NEXT_STAGE=RO6_STANDALONE_LVS_EVIDENCE_AND_MINAREA_REPAIR' "$TMP_ROOT/pass.stdout"
grep -q "pvs $RUN_ID $WORK/$RUN_ID PVS_RO6_BOUNDARY_LVS" "$TMP_ROOT/publish.args"
test -L "$WORK/$RUN_ID/outputs"
grep -qx 'SIGNOFF_ELIGIBLE=NO' "$WORK/$RUN_ID/reports/operator_gate_pvs_ro6_boundary_lvs.rpt"

cat > "$SOURCE_LVS/source.cls" <<'EOF'
Cells that have been blackboxed              |         1
 (-, RO_tune6())         |        *0 :        2 |        *0 :        2
EOF
set +e
MPTDC_BOUNDARY_LVS_REPO_ROOT="$REPO" \
MPTDC_BOUNDARY_LVS_REPLAY="$REPLAY" \
MPTDC_BOUNDARY_LVS_PUBLISHER="$PUBLISHER" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/publish_bad.args" \
bash "$DRIVER" \
  --source-pvs-run-id "$SOURCE_ID" \
  --run-id boundary_lvs_bad_source \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/bad_source.stdout" 2>&1
BAD_SOURCE_RC=$?
set -e
test "$BAD_SOURCE_RC" -ne 0
grep -Fq 'source mismatch is not the expected un-blackboxed RO_tune6 boundary signature' "$TMP_ROOT/bad_source.stdout"
grep -qx 'DECISION=FAIL_STOP' "$TMP_ROOT/bad_source.stdout"

echo "MPTDC_RO6_BOUNDARY_LVS_DRIVER_TEST=PASS"
